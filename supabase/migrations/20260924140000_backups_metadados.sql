-- Metadados dos backups cifrados + a trava de "nunca sobrescrever".
--
-- Card: "Backup cifrado ponta a ponta" (Fase 4), PR 3/4.
--
-- O Supabase Storage NÃO versiona objetos: sobrescrever o blob com conteúdo
-- corrompido destrói o backup do usuário. Daí a regra da especificação
-- (seção 6 da revisão local-first): caminho `<auth.uid()>/<seq>.dsmb` com
-- `seq` monotônico, ordem upload → insert aqui → prune, as 3 últimas
-- versões guardadas, NUNCA sobrescrever.
--
-- Nada aqui é legível para o operador: tamanho e hash de um blob opaco. Ainda
-- assim é dado pessoal (vinculado ao titular), declarado na PP v0.2.

create table public.backups_metadados (
    id              bigserial   primary key,
    usuario_id      uuid        not null default auth.uid()
                    references public.perfis (id) on delete cascade,
    seq             bigint      not null check (seq > 0),
    path            text        not null,
    tamanho_bytes   bigint      not null check (tamanho_bytes > 132),
    sha256          text        not null check (sha256 ~ '^[0-9a-f]{64}$'),
    formato_versao  int         not null check (formato_versao > 0),
    app_versao      text        not null,
    plataforma      text        not null check (plataforma in ('android', 'ios')),
    criado_em       timestamptz not null default now(),

    -- Dois aparelhos do mesmo usuário subindo a mesma seq: o segundo FALHA
    -- em vez de sobrescrever em silêncio (a trava custa uma linha).
    unique (usuario_id, seq),

    -- O caminho é função da seq e do titular, não escolha do cliente: é o
    -- que permite ao prune e a `encerrar_conta` acharem tudo pelo prefixo.
    constraint backups_path_canonico
        check (path = usuario_id::text || '/' || lpad(seq::text, 6, '0') || '.dsmb')
);

comment on table public.backups_metadados is
  'Um registro por blob .dsmb enviado (opaco: tamanho e sha256 do '
  'ciphertext). O app guarda os 3 mais recentes; o blob nunca é sobrescrito.';

create index idx_backups_metadados_usuario_seq
    on public.backups_metadados (usuario_id, seq desc);

-- O registro não muda depois de feito: ou existe, ou foi apagado pelo prune.
create or replace function conformidade.backups_metadados_imutaveis()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'metadado de backup é imutável: um backup novo é uma seq nova';
end;
$$;

create trigger trg_backups_metadados_imutaveis
    before update on public.backups_metadados
    for each row execute function conformidade.backups_metadados_imutaveis();

-- ─── RLS: o dono lê, registra e apaga (prune) os próprios ───────────────────
alter table public.backups_metadados enable row level security;

revoke all on public.backups_metadados from anon, authenticated;
grant select, delete on public.backups_metadados to authenticated;
grant insert (seq, path, tamanho_bytes, sha256, formato_versao, app_versao, plataforma)
    on public.backups_metadados to authenticated;
grant usage on sequence public.backups_metadados_id_seq to authenticated;
grant select, insert, update, delete on public.backups_metadados to service_role;

create policy backups_metadados_select_proprio on public.backups_metadados
    for select to authenticated using (usuario_id = (select auth.uid()));

create policy backups_metadados_insert_proprio on public.backups_metadados
    for insert to authenticated with check (usuario_id = (select auth.uid()));

create policy backups_metadados_delete_proprio on public.backups_metadados
    for delete to authenticated using (usuario_id = (select auth.uid()));

-- ─── Nunca sobrescrever o blob ──────────────────────────────────────────────
-- A policy de UPDATE no bucket `backups` (criada com os buckets, ago/2026)
-- é o que permite o upsert de um objeto existente. Sem ela, reenviar para um
-- caminho que já existe é recusado pelo Storage — a regra "nunca
-- sobrescrever" passa a ser do servidor, não só da boa conduta do app.
drop policy if exists "backup_atualizacao_propria" on storage.objects;
