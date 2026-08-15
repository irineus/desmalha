-- Desmalha — trava de servidor contra autenticação por senha.
--
-- Card: "Autenticação e gestão de contas de usuário" (Fase 4).
--
-- A decisão é OTP por e-mail, SEM SENHA: a senha da conta não pode ser o que
-- protege o backup, porque quem a esquece perderia o livro-caixa. Conta =
-- identidade + assinatura; backup = chave do dispositivo + código de recuperação.
--
-- O Supabase não tem toggle para desativar login por senha — senha e OTP vivem
-- no mesmo provedor de e-mail. A garantia primária é do código do app, que nunca
-- chama a API com senha. Esta trava é a segunda camada: se um cadastro com senha
-- escapar (SDK novo, script de admin, chamada manual à Auth Admin API), ele falha
-- ALTO, no banco, em vez de criar em silêncio uma conta cuja senha vira o elo
-- fraco do backup.
--
-- Para desligar em uma emergência de autenticação:
--   alter table auth.users disable trigger trg_auth_users_sem_senha;

create or replace function conformidade.recusar_senha()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.encrypted_password is not null and new.encrypted_password <> '' then
    raise exception
      'conta com senha não é permitida: o Desmalha autentica só por OTP de e-mail'
      using hint = 'Remova a senha da chamada de cadastro/login no cliente.';
  end if;
  return new;
end;
$$;

create trigger trg_auth_users_sem_senha
    before insert or update of encrypted_password on auth.users
    for each row execute function conformidade.recusar_senha();
