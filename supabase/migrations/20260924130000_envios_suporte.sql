-- Envio voluntário de extrato ao suporte — o registro e a retenção de 30 dias.
--
-- Card: "Rotina de expurgo dos 30 dias de envios_suporte" (Fase 4).
--
-- O envio ao suporte é a EXCEÇÃO ÚNICA ao claim "nem nós conseguimos ver seus
-- dados": o único momento em que um extrato bruto, com dado de terceiros (CPF
-- de pagadores), sai do aparelho. O consentimento foi dado para 30 dias (PP
-- v0.2). Passado o prazo, guardar o arquivo é tratamento sem base legal — e
-- no dado mais sensível que o servidor chega a ver. Até aqui o prazo existia
-- só no texto da PP e no comentário das policies do bucket: o mesmo defeito
-- de classe do aceite de 5 anos, corrigido em 15/ago/2026.
--
-- DDL: "Resultado: Revisar modelagem de dados para local-first", seção 5, com
-- três endurecimentos (abaixo). O bucket `suporte-extratos` é write-only para
-- o cliente; esta tabela é a única forma de o suporte descobrir que existe
-- arquivo para olhar — e de a rotina saber o que apagar.
--
-- COMO O PRAZO É EXECUTADO: o Supabase proíbe DELETE direto em
-- storage.objects (storage.protect_delete), então apagar a linha não apaga o
-- arquivo. Quem apaga é a edge function `expurgar-suporte`, pela Storage API,
-- agendada no pós-deploy (pg_cron + pg_net). E quem diz que apagou é o BANCO,
-- não a função: `confirmar_expurgo_envios_suporte` só carimba `excluido_em`
-- quando a linha do objeto sumiu de storage.objects — a mesma prova que
-- `conformidade.encerrar_conta` usa. Resposta 2xx da Storage API diz que o
-- pedido foi aceito, não que o arquivo sumiu.

create table public.envios_suporte (
    id               uuid        primary key default extensions.gen_random_uuid(),
    usuario_id       uuid        not null default auth.uid()
                     references public.perfis (id) on delete cascade,
    path             text        not null unique,
    banco_informado  text,
    motivo           text        not null check (length(btrim(motivo)) > 0),
    consentimento_em timestamptz not null default now(),
    expira_em        timestamptz not null,
    excluido_em      timestamptz,
    criado_em        timestamptz not null default now(),

    -- Endurecimento 1: o prazo é o da PP v0.2, e não um valor que o
    -- registro carrega à parte. Um expira_em mais longo seria retenção além
    -- do consentido escrita pelo próprio registro que devia limitá-la.
    constraint envios_prazo_30_dias
        check (expira_em = consentimento_em + interval '30 days'),

    -- Endurecimento 2: o arquivo está na pasta do próprio titular — é a
    -- convenção do bucket (<auth.uid()>/<arquivo>) e é o que permite a
    -- `encerrar_conta` achar o arquivo pelo prefixo.
    constraint envios_path_na_pasta_do_titular
        check (split_part(path, '/', 1) = usuario_id::text
               and length(path) > length(usuario_id::text) + 1),

    constraint envios_excluido_depois_do_envio
        check (excluido_em is null or excluido_em >= consentimento_em)
);

comment on table public.envios_suporte is
  'Registro do envio voluntário de extrato ao suporte (exceção única ao claim '
  'de privacidade). Retenção de 30 dias executada pela edge function '
  'expurgar-suporte; excluido_em só é carimbado com prova de que o objeto '
  'saiu do bucket.';
comment on column public.envios_suporte.excluido_em is
  'Carimbado por confirmar_expurgo_envios_suporte SÓ depois de o objeto sumir '
  'de storage.objects. NULL com expira_em no passado = retenção vencida.';

create index idx_envios_suporte_vencimento
    on public.envios_suporte (expira_em)
 where excluido_em is null;

-- ─── Endurecimento 3: o cliente não dita o próprio prazo ────────────────────
-- Quem chama como cliente tem o instante do consentimento carimbado pelo
-- servidor. Só service_role (o suporte, o CI, a suíte) informa um instante.
create or replace function conformidade.envios_suporte_carimbar()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_user in ('anon', 'authenticated') then
    new.consentimento_em := now();
    new.excluido_em := null;
  end if;
  new.expira_em := new.consentimento_em + interval '30 days';
  return new;
end;
$$;

create trigger trg_envios_suporte_carimbar
    before insert on public.envios_suporte
    for each row execute function conformidade.envios_suporte_carimbar();

-- O registro não muda. A única mutação é o carimbo de exclusão, uma vez, de
-- NULL para um instante. DELETE fica livre para o CASCADE do expurgo do
-- perfil — o cliente não tem privilégio de DELETE.
create or replace function conformidade.envios_suporte_imutaveis()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.id               is distinct from old.id
  or new.usuario_id       is distinct from old.usuario_id
  or new.path             is distinct from old.path
  or new.banco_informado  is distinct from old.banco_informado
  or new.motivo           is distinct from old.motivo
  or new.consentimento_em is distinct from old.consentimento_em
  or new.expira_em        is distinct from old.expira_em
  or new.criado_em        is distinct from old.criado_em then
    raise exception
      'envio ao suporte é imutável: só a exclusão do arquivo é registrada';
  end if;

  if new.excluido_em is distinct from old.excluido_em
     and not (old.excluido_em is null and new.excluido_em is not null) then
    raise exception
      'envio ao suporte: a exclusão do arquivo não pode ser alterada nem desfeita';
  end if;

  return new;
end;
$$;

create trigger trg_envios_suporte_imutaveis
    before update on public.envios_suporte
    for each row execute function conformidade.envios_suporte_imutaveis();

-- ─── RLS: o cliente registra e lê os próprios envios ────────────────────────
alter table public.envios_suporte enable row level security;

revoke all on public.envios_suporte from anon, authenticated;

-- Por coluna: o cliente escolhe o arquivo, o banco e o motivo — nada mais.
grant insert (path, banco_informado, motivo) on public.envios_suporte to authenticated;
grant select on public.envios_suporte to authenticated;

create policy envios_suporte_insert_proprio on public.envios_suporte
    for insert to authenticated
    with check (usuario_id = (select auth.uid()));

create policy envios_suporte_select_proprio on public.envios_suporte
    for select to authenticated
    using (usuario_id = (select auth.uid()));

-- ─── As duas portas da rotina de expurgo (só service_role) ──────────────────
-- SECURITY INVOKER, como encerrar_conta_do_usuario: se um grant for afrouxado
-- por engano, a função falha em vez de virar contorno com privilégio de dono.

create or replace function public.envios_suporte_vencidos()
returns table (id uuid, path text)
language sql
stable
security invoker
set search_path = ''
as $$
  select e.id, e.path
    from public.envios_suporte e
   where e.excluido_em is null
     and e.expira_em <= now()
   order by e.expira_em, e.id;
$$;

comment on function public.envios_suporte_vencidos() is
  'Envios cuja retenção de 30 dias venceu e ainda não têm exclusão '
  'confirmada. Lido pela edge function expurgar-suporte.';

create or replace function public.confirmar_expurgo_envios_suporte()
returns integer
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_n integer;
begin
  -- A prova é a AUSÊNCIA da linha em storage.objects: o Supabase não deixa
  -- apagá-la por SQL, então linha que sumiu é arquivo que a Storage API
  -- apagou. Envio vencido cujo objeto segue lá fica sem carimbo — e segue
  -- aparecendo em envios_suporte_vencidos() até sumir de fato.
  update public.envios_suporte e
     set excluido_em = now()
   where e.excluido_em is null
     and e.expira_em <= now()
     and not exists (
           select 1
             from storage.objects o
            where o.bucket_id = 'suporte-extratos'
              and o.name = e.path);
  get diagnostics v_n = row_count;
  return v_n;
end;
$$;

comment on function public.confirmar_expurgo_envios_suporte() is
  'Carimba excluido_em nos envios vencidos cujo objeto já não está no bucket '
  'suporte-extratos. Devolve quantos carimbou. Não apaga nada: quem apaga é '
  'a Storage API; isto só registra o que o banco consegue provar.';

revoke all on function public.envios_suporte_vencidos() from public, anon, authenticated;
revoke all on function public.confirmar_expurgo_envios_suporte() from public, anon, authenticated;
grant execute on function public.envios_suporte_vencidos() to service_role;
grant execute on function public.confirmar_expurgo_envios_suporte() to service_role;

-- A tabela nova precisa estar ao alcance de service_role num Postgres cru
-- (no Supabase os default privileges já dão); declarado para os dois mundos
-- ficarem iguais e prováveis por teste.
grant select, insert, update, delete on public.envios_suporte to service_role;
