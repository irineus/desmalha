-- Buckets do backend minimo do Desmalha.
-- Convencao de caminho: <auth.uid()>/<arquivo>. A primeira pasta e sempre o id do usuario.
--
-- NOTA (recuperada em 15/ago/2026, card "Autenticação e gestão de contas"):
-- esta migration foi aplicada no desmalha-dev pelo card "Provisionar backend"
-- mas nunca chegou ao repositório. Sem ela versionada, `supabase db push` num
-- projeto novo não criaria os buckets — e conformidade.encerrar_conta, que
-- verifica 'backups' e 'suporte-extratos', não teria o que verificar. Texto
-- restaurado de supabase_migrations.schema_migrations, sem alteração.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('backups', 'backups', false, 52428800, array['application/octet-stream']),
  ('suporte-extratos', 'suporte-extratos', false, 10485760, null)
on conflict (id) do nothing;

-- ---------------------------------------------------------------
-- BACKUPS: blob cifrado ponta a ponta. O operador nao consegue ler.
-- O usuario le e escreve apenas dentro da propria pasta.
-- ---------------------------------------------------------------

create policy "backup_leitura_propria"
on storage.objects for select
to authenticated
using (
  bucket_id = 'backups'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy "backup_escrita_propria"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'backups'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy "backup_atualizacao_propria"
on storage.objects for update
to authenticated
using (
  bucket_id = 'backups'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy "backup_exclusao_propria"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'backups'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

-- ---------------------------------------------------------------
-- SUPORTE-EXTRATOS: caixa de entrada unidirecional.
-- O usuario envia sob consentimento explicito e nao le de volta.
-- Retencao de 30 dias, executada por rotina de limpeza.
-- ---------------------------------------------------------------

create policy "suporte_envio_proprio"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'suporte-extratos'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
