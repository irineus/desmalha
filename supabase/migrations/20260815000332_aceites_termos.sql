-- Desmalha — registro de aceite de termos (autoritativo; o local é espelho).
--
-- Card: "Autenticação e gestão de contas de usuário" (Fase 4).
--
-- 🔴 CORREÇÃO DO DDL APROVADO. A modelagem de ago/2026 trazia, ao mesmo tempo,
-- `perfis.excluido_em` (soft delete com expurgo) e
-- `aceites_termos.usuario_id → perfis(id) ON DELETE RESTRICT`.
-- As duas coisas não coexistem: o expurgo falha na FK e a conta NUNCA é de fato
-- excluída — o que colide com o art. 18, VI da LGPD e com a exigência de
-- exclusão de conta do Google Play.
--
-- Caminho definido no card de PP/Termos e implementado aqui: desacoplar o aceite
-- do perfil. O vínculo forte passa a ser `titular_hash` (HMAC do e-mail com chave
-- de servidor, fora do banco) e `usuario_id` vira ON DELETE SET NULL. O registro
-- sobrevive à exclusão e continua provando o que precisa provar; o perfil pode
-- ser eliminado de fato.
--
-- Retenção: 5 anos APÓS O ENCERRAMENTO DA RELAÇÃO — não indefinida.
-- Base declarada na PP v0.2, seção 9 (art. 7º, VI — exercício regular de
-- direitos). O prazo não é só texto: `relacao_encerrada_em` existe para que o
-- expurgo possa contá-lo, e a rotina está em 20260814210300.

create table public.aceites_termos (
    id                   bigserial   primary key,
    usuario_id           uuid        references public.perfis (id) on delete set null,
    titular_hash         text        not null,
    documento            text        not null
                         check (documento in ('termos_uso', 'politica_privacidade')),
    -- Convenção de versão dos documentos legais: 'YYYY-MM-vN' (PP/Termos v0.2).
    -- Não é allowlist — o catálogo de documentos publicados ainda não existe —,
    -- mas impede que um cliente grave aceite de uma versão sintaticamente absurda.
    versao               text        not null check (versao ~ '^\d{4}-\d{2}-v\d+$'),
    aceito_em            timestamptz not null default now(),
    ip                   inet,
    user_agent           text,
    relacao_encerrada_em timestamptz,
    unique (usuario_id, documento, versao)
);

comment on table public.aceites_termos is
  'Prova de consentimento. Existe para defender o operador, por isso é a única '
  'coisa fiscal-adjacente que fica no servidor: registro guardado só no aparelho '
  'é registro que o usuário apaga desinstalando o app.';
comment on column public.aceites_termos.usuario_id is
  'Desvinculado (NULL) quando o perfil é expurgado. Nunca RESTRICT: era o que '
  'tornava a exclusão de conta impossível.';
comment on column public.aceites_termos.titular_hash is
  'Identificador pseudonimizado e estável do titular. É o que mantém o registro '
  'útil depois que usuario_id vira NULL.';
comment on column public.aceites_termos.relacao_encerrada_em is
  'Marco inicial da retenção de 5 anos. NULL enquanto a relação está viva.';

create index idx_aceites_titular on public.aceites_termos (titular_hash);

create index idx_aceites_expurgo
    on public.aceites_termos (relacao_encerrada_em)
 where relacao_encerrada_em is not null;

-- ─── Imutabilidade ──────────────────────────────────────────────────────────
-- O conteúdo do aceite (documento, versão, instante, origem) nunca muda. As duas
-- únicas mutações admitidas são as do encerramento da relação, e ambas só andam
-- num sentido. Apagar exige a rotina de expurgo (sinalizador de manutenção).
create or replace function conformidade.aceites_imutaveis()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'DELETE' then
    if conformidade.em_manutencao() then
      return old;
    end if;
    raise exception
      'aceite de termos é imutável: exclusão só pela rotina de expurgo';
  end if;

  if new.id           is distinct from old.id
  or new.titular_hash is distinct from old.titular_hash
  or new.documento    is distinct from old.documento
  or new.versao       is distinct from old.versao
  or new.aceito_em    is distinct from old.aceito_em
  or new.ip           is distinct from old.ip
  or new.user_agent   is distinct from old.user_agent then
    raise exception
      'aceite de termos é imutável: o conteúdo do registro não pode mudar';
  end if;

  -- usuario_id só pode ser desvinculado (a FK faz isso no expurgo do perfil).
  if new.usuario_id is distinct from old.usuario_id
     and not (old.usuario_id is not null and new.usuario_id is null) then
    raise exception
      'aceite de termos é imutável: usuario_id só pode ser desvinculado';
  end if;

  -- relacao_encerrada_em só pode ser carimbado uma vez, de NULL para um instante.
  if new.relacao_encerrada_em is distinct from old.relacao_encerrada_em
     and not (old.relacao_encerrada_em is null and new.relacao_encerrada_em is not null) then
    raise exception
      'aceite de termos é imutável: o encerramento não pode ser alterado nem desfeito';
  end if;

  return new;
end;
$$;

create trigger trg_aceites_imutaveis
    before update or delete on public.aceites_termos
    for each row execute function conformidade.aceites_imutaveis();

-- ─── Registro do aceite ─────────────────────────────────────────────────────
-- O cliente não tem INSERT direto: se tivesse, poderia gravar um titular_hash
-- qualquer e a prova de consentimento passaria a valer o que o cliente disser.
--
-- Pelo mesmo motivo, `ip` e `user_agent` NÃO são parâmetros: um registro que
-- existe para servir de prova não pode ter suas circunstâncias ditadas por quem
-- ele deveria vincular. Ambos saem dos cabeçalhos da requisição, preenchidos
-- pelo PostgREST. Só `documento` e `versao` vêm do cliente — são o que ele de
-- fato escolhe ao tocar em "aceito".
create or replace function public.registrar_aceite(
    p_documento text,
    p_versao    text)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid      uuid := (select auth.uid());
  v_email    text;
  v_id       bigint;
  v_headers  jsonb;
  v_ip       inet;
  v_ua       text;
begin
  if v_uid is null then
    raise exception 'não autenticado';
  end if;

  select email into v_email from auth.users where id = v_uid;

  v_headers := coalesce(nullif(current_setting('request.headers', true), ''), '{}')::jsonb;

  -- x-forwarded-for pode vir como cadeia "cliente, proxy1, proxy2".
  begin
    v_ip := nullif(btrim(split_part(coalesce(v_headers ->> 'x-forwarded-for', ''), ',', 1)), '')::inet;
  exception when others then
    v_ip := null;
  end;

  v_ua := left(nullif(btrim(coalesce(v_headers ->> 'user-agent', '')), ''), 500);

  insert into public.aceites_termos
      (usuario_id, titular_hash, documento, versao, ip, user_agent)
  values
      (v_uid, conformidade.titular_hash(v_email), p_documento, p_versao, v_ip, v_ua)
  on conflict (usuario_id, documento, versao) do nothing
  returning id into v_id;

  -- Reaceitar a mesma versão é no-op idempotente, não erro.
  if v_id is null then
    select id into v_id
      from public.aceites_termos
     where usuario_id = v_uid
       and documento = p_documento
       and versao = p_versao;
  end if;

  return v_id;
end;
$$;

comment on function public.registrar_aceite(text, text) is
  'Único caminho de gravação de aceite. Idempotente por (usuário, documento, '
  'versão). É SECURITY DEFINER de propósito: o titular_hash, o IP e o user agent '
  'são derivados no servidor justamente para não serem forjáveis pelo cliente.';

-- ─── RLS ────────────────────────────────────────────────────────────────────
alter table public.aceites_termos enable row level security;

revoke all on public.aceites_termos from anon, authenticated;
revoke all on sequence public.aceites_termos_id_seq from anon, authenticated;

grant select on public.aceites_termos to authenticated;

create policy aceites_select_proprio on public.aceites_termos
    for select to authenticated
    using (usuario_id = (select auth.uid()));

revoke all on function public.registrar_aceite(text, text) from public, anon;
grant execute on function public.registrar_aceite(text, text) to authenticated;
