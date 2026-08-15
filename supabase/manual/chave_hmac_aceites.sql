-- Desmalha — chave de pseudonimização dos aceites (passo MANUAL, por projeto).
--
-- Rodar UMA VEZ por projeto, ANTES do primeiro aceite de termos:
--   psql "$SUPABASE_DB_URL" -f supabase/manual/chave_hmac_aceites.sql
--
-- Não é migration porque o valor é segredo: migration fica versionada no
-- repositório, e a regra permanente 1 do CLAUDE.md proíbe segredo em repo. A
-- chave é sorteada DENTRO do banco (gen_random_bytes) e guardada no Vault, de
-- modo que o valor nunca passa por uma sessão, por um log ou por um commit.
--
-- 🔴 NÃO ROTACIONAR sem plano. Trocar a chave torna todos os `titular_hash` já
-- gravados incomparáveis com os novos: o registro de aceite deixa de provar a
-- quem pertence, que é a única razão de ele existir. Recalcular exigiria os
-- e-mails originais dos titulares — que, para contas já expurgadas, não existem
-- mais em lugar nenhum.

do $$
begin
  if not exists (select 1 from vault.secrets where name = 'desmalha_aceites_hmac_key') then
    perform vault.create_secret(
      encode(extensions.gen_random_bytes(32), 'hex'),
      'desmalha_aceites_hmac_key',
      'Chave HMAC de pseudonimizacao dos aceites de termos. NAO rotacionar sem '
      'recalcular titular_hash de toda a tabela.');
    raise notice 'chave desmalha_aceites_hmac_key criada';
  else
    raise notice 'chave desmalha_aceites_hmac_key já existe — nada a fazer';
  end if;
end $$;

-- Conferência (mostra o tamanho, nunca o valor):
select name, length(decrypted_secret) as tam_chave
  from vault.decrypted_secrets
 where name = 'desmalha_aceites_hmac_key';
