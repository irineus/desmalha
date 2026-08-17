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

-- Conferência:
--   select jobid, jobname, schedule, active from cron.job order by jobname;
--   select jobid, status, return_message, start_time
--     from cron.job_run_details order by start_time desc limit 20;
