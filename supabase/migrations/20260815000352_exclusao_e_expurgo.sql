-- Desmalha — encerramento de conta e rotinas de expurgo.
--
-- Card: "Autenticação e gestão de contas de usuário" (Fase 4).
--
-- Três prazos distintos, deliberadamente:
--   • blobs de backup e arquivos de suporte — apagados IMEDIATAMENTE, sem
--     carência (PP v0.2, seção 9);
--   • perfil e usuário de auth — expurgados após 30 dias (carência de engano);
--   • registro de aceite — desvinculado na hora, apagado 5 anos após o
--     encerramento da relação (PP v0.2, seção 9; art. 7º, VI).

-- ─── Rede de segurança: perfil apagado por qualquer caminho ─────────────────
-- Se um perfil for removido fora do fluxo previsto (exclusão do usuário de auth
-- pelo dashboard, por exemplo), a retenção do aceite ainda precisa ter um marco
-- inicial — senão o expurgo de 5 anos nunca dispara e a retenção vira indefinida,
-- exatamente o que a PP v0.2 recusou.
create or replace function conformidade.encerrar_aceites_do_perfil()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.aceites_termos
     set relacao_encerrada_em = now()
   where usuario_id = old.id
     and relacao_encerrada_em is null;
  return old;
end;
$$;

create trigger trg_perfis_encerrar_aceites
    before delete on public.perfis
    for each row execute function conformidade.encerrar_aceites_do_perfil();

-- ─── Encerramento da conta ──────────────────────────────────────────────────
-- Não existe RPC de cliente para isto. O pedido de exclusão — no app ou pelo
-- link web exigido pelo Google Play — passa por uma edge function com
-- service_role, que precisa, NESTA ORDEM:
--   1. apagar os objetos do usuário nos buckets pela Storage API;
--   2. chamar esta função;
--   3. banir/invalidar a sessão do usuário na Auth Admin API.
--
-- O passo 1 não pode ser feito em SQL: apagar linhas de storage.objects não
-- remove o arquivo no backend de objetos — deixaria o blob vivo com o registro
-- limpo, que é a pior combinação possível. Por isso esta função VERIFICA que os
-- objetos sumiram e recusa encerrar a conta enquanto houver qualquer um. Guia
-- sem código de barras, mesma postura: falhar visível em vez de registrar como
-- feito o que não foi feito.
create or replace function conformidade.encerrar_conta(p_usuario uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_pendentes bigint;
begin
  if p_usuario is null then
    raise exception 'usuário não informado';
  end if;

  if not exists (select 1 from public.perfis where id = p_usuario) then
    raise exception 'perfil % não existe', p_usuario;
  end if;

  select count(*)
    into v_pendentes
    from storage.objects
   where bucket_id in ('backups', 'suporte-extratos')
     and (storage.foldername(name))[1] = p_usuario::text;

  if v_pendentes > 0 then
    raise exception
      'ainda há % objeto(s) do usuário % em backups/suporte-extratos; '
      'apague-os pela Storage API ANTES de encerrar a conta',
      v_pendentes, p_usuario;
  end if;

  update public.perfis
     set excluido_em = coalesce(excluido_em, now())
   where id = p_usuario;

  update public.aceites_termos
     set relacao_encerrada_em = now()
   where usuario_id = p_usuario
     and relacao_encerrada_em is null;
end;
$$;

comment on function conformidade.encerrar_conta(uuid) is
  'Passo 2 do fluxo de exclusão de conta. Recusa executar enquanto houver blob '
  'do usuário nos buckets — os arquivos são apagados antes, sem carência.';

-- ─── Expurgo do perfil após a carência ──────────────────────────────────────
-- Apaga o usuário de auth; perfis cai por CASCADE e os aceites são desvinculados
-- pela FK ON DELETE SET NULL — o caminho que o ON DELETE RESTRICT bloqueava.
create or replace function conformidade.expurgar_contas_encerradas(
    p_carencia interval default '30 days')
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ids uuid[];
  v_n   integer;
begin
  select array_agg(id)
    into v_ids
    from public.perfis
   where excluido_em is not null
     and excluido_em < now() - p_carencia;

  if v_ids is null then
    return 0;
  end if;

  delete from auth.users where id = any (v_ids);
  get diagnostics v_n = row_count;

  return v_n;
end;
$$;

comment on function conformidade.expurgar_contas_encerradas(interval) is
  'Expurgo definitivo do perfil e do usuário de auth após a carência.';

-- ─── Expurgo do aceite após a retenção ──────────────────────────────────────
create or replace function conformidade.expurgar_aceites_expirados(
    p_retencao interval default '5 years')
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_n        integer;
  v_anterior text := coalesce(
                       current_setting('desmalha.manutencao_conformidade', true), 'off');
begin
  perform set_config('desmalha.manutencao_conformidade', 'on', true);

  delete from public.aceites_termos
   where relacao_encerrada_em is not null
     and relacao_encerrada_em < now() - p_retencao;
  get diagnostics v_n = row_count;

  -- set_config(is_local => true) vale pela TRANSAÇÃO, não pela função. Sem
  -- restaurar o valor aqui, o resto da transação seguiria podendo apagar
  -- aceites livremente — a imutabilidade ficaria destrancada por carona.
  perform set_config('desmalha.manutencao_conformidade', v_anterior, true);

  return v_n;
end;
$$;

comment on function conformidade.expurgar_aceites_expirados(interval) is
  'Implementa o prazo de 5 anos da PP v0.2. Sem esta rotina agendada, o prazo '
  'seria só texto e a retenção, na prática, indefinida.';

revoke all on function conformidade.encerrar_conta(uuid) from public;
revoke all on function conformidade.expurgar_contas_encerradas(interval) from public;
revoke all on function conformidade.expurgar_aceites_expirados(interval) from public;
grant execute on function conformidade.encerrar_conta(uuid) to service_role;
grant execute on function conformidade.expurgar_contas_encerradas(interval) to service_role;
grant execute on function conformidade.expurgar_aceites_expirados(interval) to service_role;
