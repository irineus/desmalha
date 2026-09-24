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

-- ok NULL é FALHA. Uma comparação com valor ausente (v_txt = 'x' com v_txt
-- nulo) dá NULL, e "not ok" também é NULL: sem o coalesce, a asserção aparecia
-- como FALHOU na tabela e NÃO contava no portão do fim — descoberto na prova
-- negativa da allowlist (24/09/2026), com dois FALHOU e o total dizendo 1.
create function pg_temp.reg(p_nome text, p_ok boolean, p_detalhe text default '')
returns void language sql as $$
  insert into _res (nome, ok, detalhe) values (p_nome, coalesce(p_ok, false), p_detalhe);
$$;

do $bloco$
declare
  u1 constant uuid := '11111111-1111-4111-8111-111111111111';
  u2 constant uuid := '22222222-2222-4222-8222-222222222222';
  u3 constant uuid := '33333333-3333-4333-8333-333333333333';
  u4 constant uuid := '44444444-4444-4444-8444-444444444444';
  u5 constant uuid := '55555555-5555-4555-8555-555555555555';
  u6 constant uuid := '66666666-6666-4666-8666-666666666666';
  u7 constant uuid := '77777777-7777-4777-8777-777777777777';
  u8 constant uuid := '88888888-8888-4888-8888-888888888888';
  u9 constant uuid := '99999999-9999-4999-8999-999999999999';
  ua constant uuid := 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  ub constant uuid := 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  v_uuid     uuid;
  v_ts       timestamptz;
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
  -- A trava NEUTRALIZA em vez de recusar: a escrita passa e a senha não fica.
  -- Recusar bloqueava o cadastro por OTP, porque o GoTrue grava um bcrypt
  -- aleatório ao criar conta sem senha — indistinguível de senha real. O que
  -- estas asserções verificam é a propriedade que importa: **não existe senha
  -- utilizável em auth.users**.
  insert into auth.users (id, email, encrypted_password)
  values (u4, 'com.senha@exemplo.com',
          extensions.crypt('senha-de-verdade', extensions.gen_salt('bf')));

  select encrypted_password is null into v_bool from auth.users where id = u4;
  perform pg_temp.reg('03 INSERT com senha grava a conta SEM senha',
                      coalesce(v_bool, false));

  update auth.users
     set encrypted_password = extensions.crypt('outra-senha', extensions.gen_salt('bf'))
   where id = u1;

  select encrypted_password is null into v_bool from auth.users where id = u1;
  perform pg_temp.reg('04 UPDATE definindo senha não deixa senha',
                      coalesce(v_bool, false));

  ----------------------------------------------------------------------------
  -- 3. Registro de aceite
  --
  -- Desde a allowlist, só se aceita versão PUBLICADA. A suíte publica as suas
  -- pelo caminho real — um item documento_legal no catálogo, que o gatilho
  -- materializa em documentos_legais — com versões de 1900, que nenhum
  -- documento verdadeiro vai ter: no modo --remoto a suíte roda contra o
  -- desmalha-dev, e uma versão real conflitaria na chave primária. O
  -- rollback final leva tudo embora.
  ----------------------------------------------------------------------------
  insert into public.catalogo_itens (tipo, id, conteudo) values
    ('documento_legal', 'termos-uso-1900-01-v1',
     jsonb_build_object('id', 'termos-uso-1900-01-v1',
       'documento', 'termos_uso', 'versao', '1900-01-v1',
       'publicado_em', '1900-01-01', 'url', 'https://exemplo.invalid/termos',
       'sha256_texto', repeat('a', 64), 'fonte', 'suíte')),
    ('documento_legal', 'politica-privacidade-1900-01-v1',
     jsonb_build_object('id', 'politica-privacidade-1900-01-v1',
       'documento', 'politica_privacidade', 'versao', '1900-01-v1',
       'publicado_em', '1900-01-01', 'url', 'https://exemplo.invalid/pp',
       'sha256_texto', repeat('b', 64), 'fonte', 'suíte'));

  perform set_config('request.jwt.claims',
                     json_build_object('sub', u1, 'role', 'authenticated')::text, true);

  v_id := public.registrar_aceite('termos_uso', '1900-01-v1');
  perform pg_temp.reg('05 registrar_aceite grava o aceite', v_id is not null);

  -- O hash é derivado do e-mail no servidor, normalizado (minúsculas, sem espaço).
  select titular_hash into v_txt from public.aceites_termos where id = v_id;
  perform pg_temp.reg(
    '06 titular_hash é HMAC do e-mail normalizado',
    v_txt = conformidade.titular_hash('titular.um@exemplo.com'));

  perform pg_temp.reg('07 titular_hash não é o e-mail em claro',
                      v_txt not ilike '%exemplo.com%' and length(v_txt) = 64, v_txt);

  v_id2 := public.registrar_aceite('termos_uso', '1900-01-v1');
  select count(*) into v_n from public.aceites_termos
   where usuario_id = u1 and documento = 'termos_uso' and versao = '1900-01-v1';
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
       values (%L, %L, %L, %L)', u2, 'hash-forjado', 'termos_uso', '1900-01-v1');
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
  v_id := public.registrar_aceite('politica_privacidade', '1900-01-v1');

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

  -- 29b–29k: a allowlist. O formato certo não basta — a versão precisa ter
  -- sido PUBLICADA, e o aceite carrega o hash do texto publicado.
  begin
    perform public.registrar_aceite('termos_uso', '1900-02-v1');
    perform pg_temp.reg('29b versão no formato mas NÃO publicada é recusada',
                        false, 'gravou aceite de versão que nunca existiu');
  exception when others then
    perform pg_temp.reg('29b versão no formato mas NÃO publicada é recusada',
                        sqlstate = 'P0002' and sqlerrm like '%não está publicada%',
                        sqlstate || ' ' || sqlerrm);
  end;

  -- v_id é o aceite da política registrado pelo u3 no bloco 9.
  select sha256_texto into v_txt from public.aceites_termos where id = v_id;
  perform pg_temp.reg('29c o aceite grava o hash do texto publicado',
                      v_txt = repeat('b', 64), coalesce(v_txt, '(nulo)'));

  select count(*) into v_n from public.documentos_legais
   where versao = '1900-01-v1'
     and url like 'https://exemplo.invalid/%';
  perform pg_temp.reg('29d o item do catálogo materializa a allowlist',
                      v_n = 2, v_n::text);

  begin
    update public.catalogo_itens
       set conteudo = jsonb_set(conteudo, '{sha256_texto}', to_jsonb(repeat('c', 64)))
     where tipo = 'documento_legal' and id = 'termos-uso-1900-01-v1';
    perform pg_temp.reg('29e trocar o texto de versão publicada é recusado',
                        false, 'o catálogo aceitou texto novo na mesma versão');
  exception when others then
    perform pg_temp.reg('29e trocar o texto de versão publicada é recusado',
                        sqlerrm like '%versão nova%', sqlerrm);
  end;

  begin
    delete from public.catalogo_itens
     where tipo = 'documento_legal' and id = 'termos-uso-1900-01-v1';
    perform pg_temp.reg('29f despublicar documento do catálogo é recusado',
                        false, 'o documento saiu do catálogo');
  exception when others then
    perform pg_temp.reg('29f despublicar documento do catálogo é recusado',
                        sqlerrm like '%versão nova%', sqlerrm);
  end;

  begin
    update public.documentos_legais set url = 'https://exemplo.invalid/outra'
     where documento = 'termos_uso' and versao = '1900-01-v1';
    perform pg_temp.reg('29g alterar a allowlist direto é recusado', false,
                        'o update passou');
  exception when others then
    perform pg_temp.reg('29g alterar a allowlist direto é recusado',
                        sqlerrm like '%imutável%', sqlerrm);
  end;

  begin
    insert into public.catalogo_itens (tipo, id, conteudo) values
      ('documento_legal', 'termos-uso-escolhido',
       jsonb_build_object('id', 'termos-uso-escolhido',
         'documento', 'termos_uso', 'versao', '1900-03-v1',
         'publicado_em', '1900-03-01', 'url', 'https://exemplo.invalid/t3',
         'sha256_texto', repeat('d', 64), 'fonte', 'suíte'));
    perform pg_temp.reg('29h id fora da derivação documento+versão é recusado',
                        false, 'o insert passou');
  exception when others then
    perform pg_temp.reg('29h id fora da derivação documento+versão é recusado',
                        sqlerrm like '%documento-com-hífen%', sqlerrm);
  end;

  execute 'set local role anon';
  select count(*) into v_n from public.documentos_legais where versao = '1900-01-v1';
  execute 'reset role';
  perform pg_temp.reg('29i anon lê a allowlist sem login', v_n = 2, v_n::text);

  begin
    execute 'set local role authenticated';
    execute $sql$insert into public.documentos_legais
      (documento, versao, publicado_em, url, sha256_texto)
      values ('termos_uso', '1900-04-v1', '1900-04-01',
              'https://exemplo.invalid/forjado', repeat('e', 64))$sql$;
    execute 'reset role';
    perform pg_temp.reg('29j cliente NÃO publica documento', false,
                        'o insert passou — o cliente escolheria o que aceitou');
  exception when others then
    execute 'reset role';
    perform pg_temp.reg('29j cliente NÃO publica documento', true, sqlerrm);
  end;

  -- A FK composta, provada por quem passa por cima de registrar_aceite: nem
  -- o dono do banco grava aceite com hash que não é o daquela versão.
  begin
    insert into public.aceites_termos
        (usuario_id, titular_hash, documento, versao, sha256_texto)
    values (u3, 'hash-qualquer', 'termos_uso', '1900-01-v1', repeat('f', 64));
    perform pg_temp.reg('29k hash divergente do publicado é recusado pela FK',
                        false, 'o insert passou');
  exception when foreign_key_violation then
    perform pg_temp.reg('29k hash divergente do publicado é recusado pela FK',
                        true);
  end;

  -- ip e user_agent saem dos cabeçalhos da requisição, não de parâmetro: o
  -- registro existe para ser prova, e prova ditada pelo titular não é prova.
  perform set_config('request.headers',
    '{"x-forwarded-for":"203.0.113.9, 70.41.3.18","user-agent":"Desmalha/1.0 (Android)"}',
    true);
  v_id := public.registrar_aceite('termos_uso', '1900-01-v1');

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

  ----------------------------------------------------------------------------
  -- 12. A trava anti-senha não pode bloquear o cadastro por OTP
  --
  -- As asserções 03 e 04 inserem em auth.users como o TESTE faz. O GoTrue faz
  -- diferente: ao criar conta sem senha ele grava um marcador em
  -- encrypted_password, e a primeira versão da trava recusava esse marcador —
  -- derrubando o único caminho de entrada do app. Descoberto só na primeira
  -- tentativa de login com e-mail real, em 17/ago/2026.
  ----------------------------------------------------------------------------
  -- Reproduz o que o GoTrue faz de verdade num cadastro por OTP: bcrypt de um
  -- valor aleatório. A primeira versão da trava recusava exatamente isto, e por
  -- isso ninguém conseguia criar conta.
  begin
    insert into auth.users (id, email, encrypted_password)
    values (u7, 'cadastro.otp@exemplo.com',
            extensions.crypt(extensions.gen_random_uuid()::text,
                             extensions.gen_salt('bf')));
    perform pg_temp.reg('37 cadastro no formato do GoTrue NÃO é bloqueado', true);
  exception when others then
    perform pg_temp.reg('37 cadastro no formato do GoTrue NÃO é bloqueado', false,
                        sqlerrm);
  end;

  select encrypted_password is null into v_bool from auth.users where id = u7;
  perform pg_temp.reg('38 e a conta nasce sem senha', coalesce(v_bool, false));

  -- A âncora que importa: a propriedade vale para a tabela INTEIRA, e não só
  -- para as linhas que estas asserções tocaram. Se um caminho de escrita
  -- escapar da trava um dia, é aqui que aparece.
  select count(*) into v_n from auth.users
   where encrypted_password is not null and encrypted_password <> '';
  perform pg_temp.reg('39 nenhuma linha de auth.users tem senha utilizável',
                      v_n = 0, v_n::text);

  ----------------------------------------------------------------------------
  -- 13. Catálogo versionado — leitura pública, escrita só pelo CI
  --
  -- O catálogo é conteúdo fiscal público (tabela do IRPF, feriados, perfis
  -- de banco): anon lê ANTES de qualquer login. Escrita de cliente não
  -- existe — quem publica é o workflow, como service_role. As duas negativas
  -- são provadas tentando, não só olhando privilégio.
  ----------------------------------------------------------------------------
  -- Id que não existe no catálogo publicado: no modo --remoto a suíte roda
  -- contra o desmalha-dev COM conteúdo real, e um id de verdade conflitaria
  -- na chave primária. O rollback final leva a linha embora.
  insert into public.catalogo_itens (tipo, id, conteudo) values
    ('feriados_bancarios', 'suite-feriados-teste',
     '{"id": "suite-feriados-teste", "ano": 2026, "fonte": "suíte",
       "datas": ["2026-12-31"]}');

  execute 'set local role anon';
  select count(*) into v_n from public.catalogo_itens
   where tipo = 'feriados_bancarios' and id = 'suite-feriados-teste';
  execute 'reset role';
  perform pg_temp.reg('40 anon lê o catálogo sem login', v_n = 1, v_n::text);

  execute 'set local role authenticated';
  select count(*) into v_n from public.catalogo_itens
   where tipo = 'feriados_bancarios' and id = 'suite-feriados-teste';
  execute 'reset role';
  perform pg_temp.reg('41 authenticated lê o catálogo', v_n = 1, v_n::text);

  begin
    execute 'set local role anon';
    execute $sql$insert into public.catalogo_itens (tipo, id, conteudo)
      values ('perfil_csv', 'perfil-forjado',
              '{"id": "perfil-forjado"}')$sql$;
    execute 'reset role';
    perform pg_temp.reg('42 anon NÃO publica no catálogo', false,
                        'o insert passou — qualquer visitante editaria a '
                        'tabela do imposto de todo mundo');
  exception when others then
    execute 'reset role';
    perform pg_temp.reg('42 anon NÃO publica no catálogo', true, sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute $sql$update public.catalogo_itens
      set conteudo = jsonb_set(conteudo, '{ano}', '1900')$sql$;
    execute 'reset role';
    perform pg_temp.reg('43 authenticated NÃO altera o catálogo', false,
                        'o update passou');
  exception when others then
    execute 'reset role';
    perform pg_temp.reg('43 authenticated NÃO altera o catálogo', true, sqlerrm);
  end;

  begin
    insert into public.catalogo_itens (tipo, id, conteudo)
    values ('Tipo Errado', 'x', '{"id": "x"}');
    perform pg_temp.reg('44 tipo fora do formato é recusado', false,
                        'o insert passou');
  exception when check_violation then
    perform pg_temp.reg('44 tipo fora do formato é recusado', true);
  end;

  begin
    -- Id inexistente no catálogo publicado, pelo mesmo motivo da linha da
    -- asserção 40: no --remoto um id real cairia na chave primária
    -- (unique_violation) antes de chegar ao check que se quer provar.
    insert into public.catalogo_itens (tipo, id, conteudo)
    values ('tabela_irpf', 'suite-irpf-teste', '{"id": "outro-id"}');
    perform pg_temp.reg('45 conteúdo com id divergente da linha é recusado',
                        false, 'o insert passou — o catálogo mentiria sobre '
                        'o que serve');
  exception when check_violation then
    perform pg_temp.reg('45 conteúdo com id divergente da linha é recusado',
                        true);
  end;
  ----------------------------------------------------------------------------
  -- 14. Envio ao suporte — retenção de 30 dias executada, não só escrita
  --
  -- O cliente registra o envio e não dita o prazo; o banco só carimba a
  -- exclusão quando o objeto sumiu de storage.objects (a mesma prova de
  -- encerrar_conta). Quem apaga o arquivo é a Storage API, pela edge function
  -- expurgar-suporte — aqui se prova a metade que é do banco.
  ----------------------------------------------------------------------------
  insert into auth.users (id, email) values (u8, 'titular.oito@exemplo.com');
  insert into auth.users (id, email) values (u9, 'titular.nove@exemplo.com');

  perform set_config('request.jwt.claims',
                     json_build_object('sub', u8, 'role', 'authenticated')::text, true);

  execute 'set local role authenticated';
  execute format(
    'insert into public.envios_suporte (path, banco_informado, motivo)
     values (%L, %L, %L)', u8 || '/extrato-itau.ofx', 'Itaú', 'parser falhou');
  execute 'reset role';

  select usuario_id, expira_em - consentimento_em, consentimento_em
    into v_uuid, v_txt, v_ts
    from public.envios_suporte where path = u8 || '/extrato-itau.ofx';
  perform pg_temp.reg('46 cliente registra o próprio envio, com 30 dias de prazo',
                      v_uuid = u8 and v_txt = '30 days'
                      and v_ts between now() - interval '1 minute' and now(),
                      format('usuario=%s prazo=%s', v_uuid, v_txt));

  begin
    execute 'set local role authenticated';
    execute format(
      'insert into public.envios_suporte (path, motivo, expira_em, consentimento_em)
       values (%L, %L, now() + interval %L, now() + interval %L)',
      u8 || '/outro.csv', 'x', '10 years', '10 years');
    execute 'reset role';
    perform pg_temp.reg('47 cliente NÃO dita o próprio prazo de retenção', false,
                        'o insert passou com expira_em do cliente');
  exception when others then
    execute 'reset role';
    perform pg_temp.reg('47 cliente NÃO dita o próprio prazo de retenção', true,
                        sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute format(
      'insert into public.envios_suporte (path, motivo) values (%L, %L)',
      u9 || '/alheio.ofx', 'x');
    execute 'reset role';
    perform pg_temp.reg('48 arquivo fora da própria pasta é recusado', false,
                        'o insert passou');
  exception when others then
    execute 'reset role';
    perform pg_temp.reg('48 arquivo fora da própria pasta é recusado', true, sqlerrm);
  end;

  -- Envios de outro titular, montados como o suporte/CI faria (service_role
  -- informa o instante). Um vencido sem objeto, um vencido com objeto no
  -- bucket, um no prazo sem objeto.
  insert into public.envios_suporte (usuario_id, path, motivo, consentimento_em)
  values (u9, u9 || '/vencido-sem-objeto.ofx', 'x', now() - interval '31 days'),
         (u9, u9 || '/vencido-com-objeto.ofx', 'x', now() - interval '31 days'),
         (u9, u9 || '/no-prazo.ofx',           'x', now() - interval '29 days');
  insert into storage.objects (bucket_id, name)
  values ('suporte-extratos', u9 || '/vencido-com-objeto.ofx');

  execute 'set local role authenticated';
  select count(*) into v_n from public.envios_suporte;
  execute 'reset role';
  perform pg_temp.reg('49 cliente só enxerga os próprios envios', v_n = 1, v_n::text);

  begin
    execute 'set local role authenticated';
    execute format(
      'update public.envios_suporte set excluido_em = now() where usuario_id = %L', u8);
    execute 'reset role';
    perform pg_temp.reg('50 cliente NÃO carimba a exclusão do próprio arquivo',
                        false, 'o update passou — o registro diria que apagou');
  exception when others then
    execute 'reset role';
    perform pg_temp.reg('50 cliente NÃO carimba a exclusão do próprio arquivo',
                        true, sqlerrm);
  end;

  perform pg_temp.reg(
    '51 anon e authenticated NÃO executam as portas do expurgo',
    not has_function_privilege('anon', 'public.confirmar_expurgo_envios_suporte()', 'execute')
    and not has_function_privilege('authenticated', 'public.confirmar_expurgo_envios_suporte()', 'execute')
    and not has_function_privilege('anon', 'public.envios_suporte_vencidos()', 'execute')
    and not has_function_privilege('authenticated', 'public.envios_suporte_vencidos()', 'execute'));

  perform pg_temp.reg(
    '52 service_role executa as portas do expurgo',
    has_function_privilege('service_role', 'public.confirmar_expurgo_envios_suporte()', 'execute')
    and has_function_privilege('service_role', 'public.envios_suporte_vencidos()', 'execute'));

  select string_agg(split_part(path, '/', 2), ',' order by path) into v_txt
    from public.envios_suporte_vencidos() where path like u9 || '/%';
  perform pg_temp.reg('53 vencidos lista só o que passou dos 30 dias',
                      v_txt = 'vencido-com-objeto.ofx,vencido-sem-objeto.ofx',
                      coalesce(v_txt, '(nada)'));

  v_n := public.confirmar_expurgo_envios_suporte();
  perform pg_temp.reg('54 confirmar carimba só o vencido cujo objeto sumiu',
                      v_n = 1, v_n::text);

  select excluido_em is null into v_bool
    from public.envios_suporte where path = u9 || '/vencido-com-objeto.ofx';
  perform pg_temp.reg(
    '55 objeto ainda no bucket NÃO ganha carimbo de excluído', v_bool,
    'o banco registrou como apagado um arquivo que segue no bucket');

  select excluido_em is null into v_bool
    from public.envios_suporte where path = u9 || '/no-prazo.ofx';
  perform pg_temp.reg('56 envio no prazo não é tocado', v_bool);

  select count(*) into v_n from public.envios_suporte_vencidos()
   where path like u9 || '/%';
  perform pg_temp.reg('57 o pendente segue na lista até sumir de fato',
                      v_n = 1, v_n::text);

  begin
    update public.envios_suporte set excluido_em = null
     where path = u9 || '/vencido-sem-objeto.ofx';
    perform pg_temp.reg('58 a exclusão registrada não pode ser desfeita', false,
                        'o update passou');
  exception when others then
    perform pg_temp.reg('58 a exclusão registrada não pode ser desfeita',
                        sqlerrm like '%não pode ser alterada%', sqlerrm);
  end;

  begin
    update public.envios_suporte set expira_em = expira_em + interval '1 year'
     where path = u9 || '/no-prazo.ofx';
    perform pg_temp.reg('59 o prazo de um envio não pode ser esticado', false,
                        'o update passou');
  exception when others then
    perform pg_temp.reg('59 o prazo de um envio não pode ser esticado',
                        sqlerrm like '%imutável%', sqlerrm);
  end;
  ----------------------------------------------------------------------------
  -- 15. Metadados do backup — seq monotônica, caminho canônico, sem
  --     sobrescrever (card "Backup cifrado ponta a ponta", PR 3/4)
  ----------------------------------------------------------------------------
  insert into auth.users (id, email) values (ua, 'titular.a@exemplo.com');
  insert into auth.users (id, email) values (ub, 'titular.b@exemplo.com');
  perform set_config('request.jwt.claims',
                     json_build_object('sub', ua, 'role', 'authenticated')::text, true);

  execute 'set local role authenticated';
  execute format(
    'insert into public.backups_metadados
       (seq, path, tamanho_bytes, sha256, formato_versao, app_versao, plataforma)
     values (1, %L, 1000, %L, 1, %L, %L)',
    ua || '/000001.dsmb', repeat('a', 64), '1.0.0', 'android');
  execute 'reset role';
  select count(*) into v_n from public.backups_metadados where usuario_id = ua;
  perform pg_temp.reg('60 dono registra o próprio backup', v_n = 1, v_n::text);

  begin
    execute 'set local role authenticated';
    execute format(
      'insert into public.backups_metadados
         (seq, path, tamanho_bytes, sha256, formato_versao, app_versao, plataforma)
       values (1, %L, 1000, %L, 1, %L, %L)',
      ua || '/000001.dsmb', repeat('b', 64), '1.0.0', 'ios');
    execute 'reset role';
    perform pg_temp.reg('61 a mesma seq duas vezes é recusada (outro aparelho)',
                        false, 'o insert passou — sobrescrita silenciosa');
  exception when unique_violation then
    execute 'reset role';
    perform pg_temp.reg('61 a mesma seq duas vezes é recusada (outro aparelho)', true);
  end;

  begin
    execute 'set local role authenticated';
    execute format(
      'insert into public.backups_metadados
         (seq, path, tamanho_bytes, sha256, formato_versao, app_versao, plataforma)
       values (2, %L, 1000, %L, 1, %L, %L)',
      ua || '/qualquer-nome.dsmb', repeat('c', 64), '1.0.0', 'android');
    execute 'reset role';
    perform pg_temp.reg('62 caminho fora do canônico <uid>/<seq>.dsmb é recusado',
                        false, 'o insert passou');
  exception when check_violation then
    execute 'reset role';
    perform pg_temp.reg('62 caminho fora do canônico <uid>/<seq>.dsmb é recusado', true);
  end;

  begin
    execute 'set local role authenticated';
    execute format(
      'insert into public.backups_metadados
         (seq, path, tamanho_bytes, sha256, formato_versao, app_versao, plataforma)
       values (3, %L, 1000, %L, 1, %L, %L)',
      ub || '/000003.dsmb', repeat('d', 64), '1.0.0', 'android');
    execute 'reset role';
    perform pg_temp.reg('63 cliente não registra backup em nome de outro', false,
                        'o insert passou');
  exception when others then
    execute 'reset role';
    perform pg_temp.reg('63 cliente não registra backup em nome de outro', true, sqlerrm);
  end;

  begin
    update public.backups_metadados set sha256 = repeat('e', 64) where usuario_id = ua;
    perform pg_temp.reg('64 metadado de backup é imutável', false, 'o update passou');
  exception when others then
    perform pg_temp.reg('64 metadado de backup é imutável',
                        sqlerrm like '%imutável%', sqlerrm);
  end;

  execute 'set local role authenticated';
  execute 'delete from public.backups_metadados where seq = 1';
  get diagnostics v_n = row_count;
  execute 'reset role';
  perform pg_temp.reg('65 dono apaga o próprio metadado (prune)', v_n = 1, v_n::text);

  perform pg_temp.reg(
    '66 o bucket backups não tem mais policy de UPDATE (nunca sobrescrever)',
    not exists (select 1 from pg_policies
                 where schemaname = 'storage' and tablename = 'objects'
                   and policyname = 'backup_atualizacao_propria'));
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

-- Sem este bloco, a suíte IMPRIME "FALHOU" e o psql ainda sai com código 0 — o
-- que basta para uma pessoa lendo a tela e não basta para nada mais. Um portão
-- de CI que não reprova é pior do que portão nenhum: dá a sensação de cobertura
-- sem a cobertura. A âncora do total pega o caso oposto, o de uma suíte que não
-- executou nada e passaria por vacuidade.
do $bloco$
declare
  v_falhou integer;
  v_total  integer;
begin
  select count(*) filter (where not ok), count(*) into v_falhou, v_total from _res;

  if v_total < 76 then
    raise exception 'a suíte registrou só % asserções; esperado ao menos 76', v_total;
  end if;
  if v_falhou > 0 then
    raise exception '% de % asserções falharam (ver a coluna detalhe acima)',
                    v_falhou, v_total;
  end if;
end;
$bloco$;

rollback;
