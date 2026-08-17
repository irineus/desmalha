-- Desmalha — chave de pseudonimização dos aceites.
--
-- ⚙️ PÓS-DEPLOY, rodado pelo CI a cada publicação (.github/workflows/supabase.yml),
-- depois das migrations. Não é passo manual: era, e um passo manual esquecido
-- faz `registrar_aceite` falhar no primeiro aceite de termos do projeto.
--
-- Não é migration porque depende do **Vault**, que existe na plataforma Supabase
-- e não num Postgres pelado. As migrations precisam continuar aplicáveis numa
-- base limpa sem nuvem — é o que `tool/testar_supabase.sh` verifica, e é o que
-- responde "as migrations do repositório reproduzem o schema sozinhas?".
-- (O valor NÃO é o motivo: a chave é sorteada DENTRO do banco por
-- gen_random_bytes, e nunca passa por uma sessão, por um log ou por um commit.)
--
-- Idempotente: rodar de novo não troca a chave.
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
