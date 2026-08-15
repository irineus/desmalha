-- Desmalha — perfis (identidade mínima no servidor).
--
-- Card: "Autenticação e gestão de contas de usuário" (Fase 4).
--
-- O CPF do usuário NÃO existe aqui: o DARF é gerado no aparelho e o servidor
-- nunca precisou dele. `nome_exibicao` serve só para e-mail transacional.

create table public.perfis (
    id             uuid primary key references auth.users (id) on delete cascade,
    nome_exibicao  text,
    coorte         text        not null default 'fundador' check (btrim(coorte) <> ''),
    criado_em      timestamptz not null default now(),
    atualizado_em  timestamptz not null default now(),
    excluido_em    timestamptz
);

comment on table public.perfis is
  'Identidade do assinante. Soft delete via excluido_em, com expurgo definitivo '
  'após a carência (conformidade.expurgar_contas_encerradas).';
comment on column public.perfis.coorte is
  'Define o preço e a garantia de 12 meses do lote fundador. O default fixo em '
  '"fundador" vale enquanto só existe um lote; a atribuição por lote é escopo do '
  'card de assinaturas (Fase 6), que também precisa de product ID por coorte.';
comment on column public.perfis.excluido_em is
  'Marcado no pedido de exclusão. A partir daí a conta não é mais legível pelo '
  'cliente (RLS) e os blobs de backup já foram apagados — a carência aqui serve '
  'para reversão de engano, não para reter dado do usuário.';

create index idx_perfis_expurgo
    on public.perfis (excluido_em)
 where excluido_em is not null;

create trigger trg_perfis_atualizado_em
    before update on public.perfis
    for each row execute function conformidade.tocar_atualizado_em();

-- ─── Criação automática do perfil no cadastro ───────────────────────────────
-- O cliente não tem INSERT em perfis: a linha nasce junto com o usuário de auth.
create or replace function conformidade.criar_perfil_novo_usuario()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.perfis (id)
  values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger trg_auth_users_criar_perfil
    after insert on auth.users
    for each row execute function conformidade.criar_perfil_novo_usuario();

-- ─── RLS ────────────────────────────────────────────────────────────────────
alter table public.perfis enable row level security;

revoke all on public.perfis from anon, authenticated;

-- Sem INSERT e sem DELETE para o cliente: o perfil nasce por trigger e morre
-- pelo fluxo de encerramento, que precisa apagar os blobs antes.
grant select on public.perfis to authenticated;
grant update (nome_exibicao) on public.perfis to authenticated;

create policy perfis_select_proprio on public.perfis
    for select to authenticated
    using (id = (select auth.uid()) and excluido_em is null);

create policy perfis_update_proprio on public.perfis
    for update to authenticated
    using (id = (select auth.uid()) and excluido_em is null)
    with check (id = (select auth.uid()) and excluido_em is null);
