-- Desmalha — testes do schema de identidade e conformidade.
--
-- Card: "Autenticação e gestão de contas de usuário" (Fase 4).
--
-- Roda inteiro dentro de uma transação que termina em ROLLBACK: nenhum usuário
-- de teste, aceite ou objeto sobrevive à execução. Pode ser rodado contra o
-- desmalha-dev sem sujar o banco.
--
--   psql "$SUPABASE_DB_URL" -f supabase/tests/conformidade_identidade.sql
--
-- Não usa pgTAP de propósito: a extensão teria de ser instalada no projeto, e um
-- arcabouço de teste não precisa existir em produção para o teste rodar.

begin;

create temp table _res (
    ordem   serial,
    nome    text,
    ok      boolean,
    detalhe text
) on commit drop;

create function pg_temp.reg(p_nome text, p_ok boolean, p_detalhe text default '')
returns void language sql as $$
  insert into _res (nome, ok, detalhe) values (p_nome, p_ok, p_detalhe);
$$;

do $bloco$
declare
  u1 constant uuid := '11111111-1111-4111-8111-111111111111';
  u2 constant uuid := '22222222-2222-4222-8222-222222222222';
  u3 constant uuid := '33333333-3333-4333-8333-333333333333';
  u4 constant uuid := '44444444-4444-4444-8444-444444444444';
  u5 constant uuid := '55555555-5555-4555-8555-555555555555';
  u6 constant uuid := '66666666-6666-4666-8666-666666666666';
  v_id       bigint;
  v_id2      bigint;
  v_n        integer;
  v_txt      text;
  v_bool     boolean;
begin
  ----------------------------------------------------------------------------
  -- 1. O perfil nasce junto com o usuário de auth
  ----------------------------------------------------------------------------
  insert into auth.users (id, email) values (u1, 'Titular.UM@Exemplo.com');

  perform pg_temp.reg(
    '01 cadastro cria perfil automaticamente',
    exists (select 1 from public.perfis where id = u1));

  select coorte into v_txt from public.perfis where id = u1;
  perform pg_temp.reg('02 perfil nasce na coorte fundador', v_txt = 'fundador', v_txt);

  ----------------------------------------------------------------------------
  -- 2. Trava de servidor contra senha
  ----------------------------------------------------------------------------
  begin
    insert into auth.users (id, email, encrypted_password)
    values (u4, 'com.senha@exemplo.com', '$2a$10$abcdefghijklmnopqrstuv');
    perform pg_temp.reg('03 INSERT com senha é recusado', false,
                        'o insert passou — a trava não pegou');
  exception when others then
    perform pg_temp.reg('03 INSERT com senha é recusado',
                        sqlerrm like '%conta com senha%', sqlerrm);
  end;

  begin
    update auth.users set encrypted_password = '$2a$10$abcdefghijklmnopqrstuv'
     where id = u1;
    perform pg_temp.reg('04 UPDATE definindo senha é recusado', false,
                        'o update passou — a trava não pegou');
  exception when others then
    perform pg_temp.reg('04 UPDATE definindo senha é recusado',
                        sqlerrm like '%conta com senha%', sqlerrm);
  end;

  ----------------------------------------------------------------------------
  -- 3. Registro de aceite
  ----------------------------------------------------------------------------
  perform set_config('request.jwt.claims',
                     json_build_object('sub', u1, 'role', 'authenticated')::text, true);

  v_id := public.registrar_aceite('termos_uso', '2026-09-v1');
  perform pg_temp.reg('05 registrar_aceite grava o aceite', v_id is not null);

  -- O hash é derivado do e-mail no servidor, normalizado (minúsculas, sem espaço).
  select titular_hash into v_txt from public.aceites_termos where id = v_id;
  perform pg_temp.reg(
    '06 titular_hash é HMAC do e-mail normalizado',
    v_txt = conformidade.titular_hash('titular.um@exemplo.com'));

  perform pg_temp.reg('07 titular_hash não é o e-mail em claro',
                      v_txt not ilike '%exemplo.com%' and length(v_txt) = 64, v_txt);

  v_id2 := public.registrar_aceite('termos_uso', '2026-09-v1');
  select count(*) into v_n from public.aceites_termos
   where usuario_id = u1 and documento = 'termos_uso' and versao = '2026-09-v1';
  perform pg_temp.reg('08 reaceitar a mesma versão é idempotente',
                      v_id2 = v_id and v_n = 1, format('id=%s n=%s', v_id2, v_n));

  ----------------------------------------------------------------------------
  -- 4. Imutabilidade do aceite
  ----------------------------------------------------------------------------
  begin
    update public.aceites_termos set versao = '2026-10-v2' where id = v_id;
    perform pg_temp.reg('09 alterar conteúdo do aceite é recusado', false,
                        'o update passou');
  exception when others then
    perform pg_temp.reg('09 alterar conteúdo do aceite é recusado',
                        sqlerrm like '%imutável%', sqlerrm);
  end;

  begin
    delete from public.aceites_termos where id = v_id;
    perform pg_temp.reg('10 apagar aceite fora do expurgo é recusado', false,
                        'o delete passou');
  exception when others then
    perform pg_temp.reg('10 apagar aceite fora do expurgo é recusado',
                        sqlerrm like '%imutável%', sqlerrm);
  end;

  ----------------------------------------------------------------------------
  -- 5. RLS — o que o cliente autenticado enxerga e pode escrever
  ----------------------------------------------------------------------------
  insert into auth.users (id, email) values (u2, 'titular.dois@exemplo.com');

  perform set_config('request.jwt.claims',
                     json_build_object('sub', u2, 'role', 'authenticated')::text, true);

  execute 'set local role authenticated';
  select count(*) into v_n from public.perfis;
  execute 'reset role';
  perform pg_temp.reg('11 cliente só enxerga o próprio perfil', v_n = 1, v_n::text);

  execute 'set local role authenticated';
  select count(*) into v_n from public.aceites_termos;
  execute 'reset role';
  perform pg_temp.reg('12 cliente não enxerga aceite alheio', v_n = 0, v_n::text);

  begin
    execute 'set local role authenticated';
    execute format(
      'insert into public.aceites_termos (usuario_id, titular_hash, documento, versao)
       values (%L, %L, %L, %L)', u2, 'hash-forjado', 'termos_uso', '2026-09-v1');
    execute 'reset role';
    perform pg_temp.reg('13 cliente não insere aceite direto', false,
                        'o insert passou — titular_hash poderia ser forjado');
  exception when others then
    execute 'reset role';
    perform pg_temp.reg('13 cliente não insere aceite direto', true, sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute format('update public.perfis set coorte = %L where id = %L', 'vitalicio', u2);
    execute 'reset role';
    perform pg_temp.reg('14 cliente não altera a própria coorte', false,
                        'o update passou — o preço seria escolhido pelo cliente');
  exception when others then
    execute 'reset role';
    perform pg_temp.reg('14 cliente não altera a própria coorte', true, sqlerrm);
  end;

  execute 'set local role authenticated';
  update public.perfis set nome_exibicao = 'Dois' where id = u2;
  get diagnostics v_n = row_count;
  execute 'reset role';
  perform pg_temp.reg('15 cliente altera o próprio nome de exibição', v_n = 1, v_n::text);

  ----------------------------------------------------------------------------
  -- 6. Encerramento: os blobs vão antes, e o banco recusa fingir que foram
  --
  -- O blob pendente é montado no u2, não no u1, porque o próprio Supabase
  -- proíbe DELETE direto em storage.objects (storage.protect_delete) — linhas
  -- só saem de lá pela Storage API. É justamente essa proibição que torna a
  -- verificação de conformidade.encerrar_conta uma prova, e não uma promessa:
  -- se não há linha no prefixo do usuário, o arquivo foi mesmo apagado.
  ----------------------------------------------------------------------------
  insert into storage.objects (bucket_id, name) values ('backups', u2 || '/000001.dsmb');

  begin
    perform conformidade.encerrar_conta(u2);
    perform pg_temp.reg('16 encerrar conta com blob pendente é recusado', false,
                        'encerrou com o backup ainda no bucket');
  exception when others then
    perform pg_temp.reg('16 encerrar conta com blob pendente é recusado',
                        sqlerrm like '%apague-os pela Storage API%', sqlerrm);
  end;

  -- O u1 nunca teve blob: é o caminho feliz.
  perform conformidade.encerrar_conta(u1);

  select excluido_em is not null into v_bool from public.perfis where id = u1;
  perform pg_temp.reg('17 encerramento marca excluido_em', v_bool);

  select relacao_encerrada_em is not null into v_bool
    from public.aceites_termos where id = v_id;
  perform pg_temp.reg('18 encerramento inicia a contagem da retenção', v_bool);

  ----------------------------------------------------------------------------
  -- 7. Expurgo do perfil — o teste que prova a correção do ON DELETE RESTRICT
  ----------------------------------------------------------------------------
  update public.perfis set excluido_em = now() - interval '31 days' where id = u1;

  v_n := conformidade.expurgar_contas_encerradas();
  perform pg_temp.reg('19 expurgo remove a conta após a carência', v_n = 1, v_n::text);

  perform pg_temp.reg('20 perfil deixou de existir',
                      not exists (select 1 from public.perfis where id = u1));
  perform pg_temp.reg('21 usuário de auth deixou de existir',
                      not exists (select 1 from auth.users where id = u1));

  -- O ponto todo da correção: o aceite sobrevive, desvinculado, e ainda sabe de
  -- quem é pelo titular_hash. Com ON DELETE RESTRICT, o passo 19 teria falhado.
  select count(*) into v_n from public.aceites_termos
   where id = v_id and usuario_id is null
     and titular_hash = conformidade.titular_hash('titular.um@exemplo.com');
  perform pg_temp.reg('22 aceite sobrevive desvinculado e ainda identifica o titular',
                      v_n = 1, v_n::text);

  ----------------------------------------------------------------------------
  -- 8. Expurgo do aceite — retenção de 5 anos, não indefinida
  ----------------------------------------------------------------------------
  v_n := conformidade.expurgar_aceites_expirados();
  perform pg_temp.reg('23 aceite recente NÃO é expurgado', v_n = 0, v_n::text);
  perform pg_temp.reg('24 aceite recente segue no banco',
                      exists (select 1 from public.aceites_termos where id = v_id));

  -- Retenção negativa simula "já passaram os 5 anos" sem violar a imutabilidade
  -- de relacao_encerrada_em.
  v_n := conformidade.expurgar_aceites_expirados(interval '-1 second');
  perform pg_temp.reg('25 aceite vencido é expurgado', v_n = 1, v_n::text);
  perform pg_temp.reg('26 aceite vencido saiu do banco',
                      not exists (select 1 from public.aceites_termos where id = v_id));

  ----------------------------------------------------------------------------
  -- 9. O sinalizador de manutenção não vaza para fora do expurgo
  --
  -- set_config(is_local => true) vale pela TRANSAÇÃO, não pela função. A primeira
  -- versão desta migration não restaurava o valor, e o teste 28 pegava isso: uma
  -- transação que rodasse o expurgo saía com aceites_termos destrancada.
  ----------------------------------------------------------------------------
  perform pg_temp.reg('27 manutenção não fica ligada após o expurgo',
                      conformidade.em_manutencao() = false);

  insert into auth.users (id, email) values (u3, 'titular.tres@exemplo.com');
  perform set_config('request.jwt.claims',
                     json_build_object('sub', u3, 'role', 'authenticated')::text, true);
  v_id := public.registrar_aceite('politica_privacidade', '2026-09-v1');

  begin
    delete from public.aceites_termos where id = v_id;
    perform pg_temp.reg('28 aceite segue imutável depois de um expurgo', false,
                        'delete passou — o sinalizador vazou do expurgo');
  exception when others then
    perform pg_temp.reg('28 aceite segue imutável depois de um expurgo',
                        sqlerrm like '%imutável%', sqlerrm);
  end;

  ----------------------------------------------------------------------------
  -- 10. Versão do documento e circunstâncias do aceite
  ----------------------------------------------------------------------------
  begin
    perform public.registrar_aceite('termos_uso', 'sei-la-qual');
    perform pg_temp.reg('29 versão fora da convenção é recusada', false,
                        'gravou aceite de versão inventada');
  exception when others then
    perform pg_temp.reg('29 versão fora da convenção é recusada', true, sqlerrm);
  end;

  -- ip e user_agent saem dos cabeçalhos da requisição, não de parâmetro: o
  -- registro existe para ser prova, e prova ditada pelo titular não é prova.
  perform set_config('request.headers',
    '{"x-forwarded-for":"203.0.113.9, 70.41.3.18","user-agent":"Desmalha/1.0 (Android)"}',
    true);
  v_id := public.registrar_aceite('termos_uso', '2026-09-v1');

  -- host() porque inet::text traz a máscara ('203.0.113.9/32').
  select host(ip) into v_txt from public.aceites_termos where id = v_id;
  perform pg_temp.reg('30 ip vem do primeiro salto do x-forwarded-for',
                      v_txt = '203.0.113.9', coalesce(v_txt, '(nulo)'));

  select user_agent into v_txt from public.aceites_termos where id = v_id;
  perform pg_temp.reg('31 user_agent vem do cabeçalho',
                      v_txt = 'Desmalha/1.0 (Android)', v_txt);

  ----------------------------------------------------------------------------
  -- 11. A porta em public que a edge function de exclusão usa
  --
  -- O PostgREST não enxerga o schema conformidade. Sem esta função, o passo 2
  -- do fluxo de exclusão seria inalcançável pela edge function — e a saída
  -- fácil (expor o schema conformidade inteiro na API) entregaria junto as
  -- rotinas de expurgo e a leitura da chave de pseudonimização.
  ----------------------------------------------------------------------------
  perform pg_temp.reg(
    '32 anon NÃO executa o encerramento',
    not has_function_privilege(
      'anon', 'public.encerrar_conta_do_usuario(uuid)', 'execute'));

  perform pg_temp.reg(
    '33 authenticated NÃO executa o encerramento',
    not has_function_privilege(
      'authenticated', 'public.encerrar_conta_do_usuario(uuid)', 'execute'));

  -- Sem este, os dois de cima passariam por uma função que ninguém executa.
  perform pg_temp.reg(
    '34 service_role executa o encerramento',
    has_function_privilege(
      'service_role', 'public.encerrar_conta_do_usuario(uuid)', 'execute'));

  -- Mesma divisão do bloco 6: o usuário com blob pendente não é o mesmo do
  -- caminho feliz, porque a linha de storage.objects não sai daqui.
  insert into auth.users (id, email) values (u5, 'titular.cinco@exemplo.com');
  insert into storage.objects (bucket_id, name) values ('backups', u5 || '/000001.dsmb');

  begin
    perform public.encerrar_conta_do_usuario(u5);
    perform pg_temp.reg('35 a porta herda a recusa com blob pendente', false,
                        'encerrou com o backup ainda no bucket');
  exception when others then
    perform pg_temp.reg('35 a porta herda a recusa com blob pendente',
                        sqlerrm like '%apague-os pela Storage API%', sqlerrm);
  end;

  insert into auth.users (id, email) values (u6, 'titular.seis@exemplo.com');
  perform public.encerrar_conta_do_usuario(u6);
  select excluido_em is not null into v_bool from public.perfis where id = u6;
  perform pg_temp.reg('36 a porta delega o encerramento de fato', v_bool);
end;
$bloco$;

select ordem,
       case when ok then 'PASSOU' else 'FALHOU' end as resultado,
       nome,
       case when ok then '' else detalhe end as detalhe
  from _res
 order by ordem;

select count(*) filter (where ok)        as passou,
       count(*) filter (where not ok)    as falhou,
       count(*)                          as total
  from _res;

rollback;
