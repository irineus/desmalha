-- Desmalha — agendamento das rotinas de expurgo (passo MANUAL, por projeto).
--
-- Não é migration de propósito: `pg_cron` precisa ser habilitado na interface do
-- Supabase (Database → Extensions) antes de existir, e o agendamento é
-- configuração de ambiente — dev e prod podem legitimamente divergir.
--
-- Rodar UMA VEZ por projeto, depois de habilitar pg_cron:
--   psql "$SUPABASE_DB_URL" -f supabase/manual/agendamento_expurgo.sql
--
-- Sem estes dois jobs, os prazos da PP v0.2 existem só no texto: perfis
-- excluídos ficariam para sempre em soft delete e o aceite seria retido
-- indefinidamente — exatamente o que a política recusou.

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
