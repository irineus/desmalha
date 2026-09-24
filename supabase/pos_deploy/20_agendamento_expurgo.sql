-- Desmalha — agendamento das rotinas de expurgo.
--
-- ⚙️ PÓS-DEPLOY, rodado pelo CI a cada publicação (.github/workflows/supabase.yml),
-- depois das migrations. Era passo manual, e não devia ser: **prazo de retenção
-- que depende de alguém lembrar de rodar um script não é prazo, é intenção.**
-- Sem estes dois jobs, os prazos da PP v0.2 existem só no texto — perfis
-- excluídos ficam para sempre em soft delete e o aceite é retido
-- indefinidamente, exatamente o que a política recusou.
--
-- Não é migration porque depende de `pg_cron`, que a plataforma oferece e um
-- Postgres pelado não tem. As migrations precisam continuar aplicáveis numa base
-- limpa sem nuvem (`tool/testar_supabase.sh`). Corrigida de passagem a outra
-- metade da justificativa antiga: habilitar pg_cron **não** exige a interface do
-- Supabase — `create extension` basta, e é o que a própria documentação deles
-- mostra.
--
-- Idempotente: `cron.schedule` faz upsert pelo nome do job, então reexecutar
-- reafirma o agendamento em vez de duplicá-lo.

create extension if not exists pg_cron;

-- 03:10 UTC (00:10 em Brasília) — fora do horário de uso do app.
select cron.schedule(
    'desmalha-expurgar-contas-encerradas',
    '10 3 * * *',
    $job$ select conformidade.expurgar_contas_encerradas(); $job$);

-- Semanal: a granularidade de 5 anos não pede varredura diária.
select cron.schedule(
    'desmalha-expurgar-aceites-expirados',
    '40 3 * * 0',
    $job$ select conformidade.expurgar_aceites_expirados(); $job$);

-- Diário: os 30 dias de envios_suporte (card "Rotina de expurgo dos 30 dias
-- de envios_suporte"). O arquivo só sai do bucket pela Storage API, então o
-- job não apaga nada em SQL: chama a edge function `expurgar-suporte` pelo
-- pg_net. Ela apaga, e o banco só carimba `excluido_em` quando a linha do
-- objeto some de storage.objects. Falha fica em net._http_response (status
-- 500) e no log da função — e o passo "Conferir o que ficou de pé" do
-- workflow reprova se houver envio vencido há mais de 2 dias sem exclusão.
--
-- `projeto_url` vem do workflow (psql -v projeto_url=https://<ref>.supabase.co):
-- dev e prod usam o mesmo arquivo. Rodar sem a variável é erro de sintaxe no
-- psql, de propósito — agendar para uma URL vazia seria um prazo que nunca
-- executa sem ninguém perceber.
create extension if not exists pg_net;

select cron.schedule(
    'desmalha-expurgar-envios-suporte',
    '25 3 * * *',
    format(
      $job$ select net.http_post(
              url := %L,
              body := '{}'::jsonb,
              headers := '{"content-type": "application/json"}'::jsonb,
              timeout_milliseconds := 60000); $job$,
      :'projeto_url' || '/functions/v1/expurgar-suporte'));

-- Conferência:
--   select jobid, jobname, schedule, active from cron.job order by jobname;
--   select jobid, status, return_message, start_time
--     from cron.job_run_details order by start_time desc limit 20;
--   select id, status_code, content, created
--     from net._http_response order by created desc limit 5;   -- guarda ~6 h
