-- Desmalha — a trava anti-senha parou de bloquear o cadastro por OTP.
--
-- Card: "Autenticação e gestão de contas de usuário" (Fase 4).
--
-- 🔴 A VERSÃO ANTERIOR IMPEDIA QUALQUER CADASTRO. Descoberto em 17/ago/2026, na
-- primeira tentativa de login com e-mail real contra o `desmalha-dev`:
--
--   POST /auth/v1/otp  →  HTTP 500
--   {"code":"P0001","message":"conta com senha não é permitida: ..."}
--
-- e `auth.users` com zero linhas. A trava que existe para impedir que a senha
-- vire o elo fraco do backup estava impedindo o único caminho de entrada do app.
-- Nenhuma das 36 asserções pegou isso: todas inserem em `auth.users`
-- diretamente, como o teste faz, e nunca como o GoTrue faz. Foi preciso um
-- cadastro de verdade.
--
-- O QUE MUDA
--
-- A regra que se queria nunca foi "o campo tem de estar vazio" — era **nenhuma
-- senha pode servir para entrar**. São coisas diferentes, e a diferença é
-- exatamente o marcador que o GoTrue grava ao criar usuário sem senha.
--
-- Agora: null e string vazia passam, como antes; um hash da STRING VAZIA passa e
-- é normalizado para null — não existe senha que o produza, porque o próprio
-- Supabase recusa senha vazia na API, então ele não abre porta nenhuma; e
-- qualquer outro valor continua sendo recusado alto.
--
-- ⚠️ A mensagem de recusa agora carrega o TAMANHO e o PREFIXO do valor. Se isto
-- disparar de novo num cadastro legítimo, é porque a versão do GoTrue passou a
-- gravar um marcador diferente destes — e o erro já diz qual, em vez de exigir
-- outra rodada de adivinhação. O prefixo de um hash bcrypt revela o algoritmo,
-- não a senha.

create or replace function conformidade.recusar_senha()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_senha    text := new.encrypted_password;
  v_eh_vazia boolean := false;
begin
  if v_senha is null or v_senha = '' then
    return new;
  end if;

  -- `crypt` levanta erro quando o valor não é um hash com salt reconhecível;
  -- nesse caso não é marcador de "sem senha", e cai no raise abaixo.
  begin
    v_eh_vazia := extensions.crypt('', v_senha) = v_senha;
  exception when others then
    v_eh_vazia := false;
  end;

  if v_eh_vazia then
    new.encrypted_password := null;
    return new;
  end if;

  raise exception
    'conta com senha não é permitida: o Desmalha autentica só por OTP de e-mail'
    using hint = format(
      'Remova a senha da chamada de cadastro/login no cliente. Valor recusado: '
      '%s caracteres, começando em "%s". Se isto apareceu num cadastro legítimo '
      'por OTP, o GoTrue passou a gravar outro marcador — ajuste '
      'conformidade.recusar_senha, e não o cliente.',
      length(v_senha), left(v_senha, 7));
end;
$$;

comment on function conformidade.recusar_senha() is
  'Segunda camada da decisão "sem senha". Recusa senha utilizável; deixa passar '
  'os marcadores de "nenhuma senha" que o GoTrue grava ao criar conta por OTP, '
  'porque bloqueá-los bloqueia o único caminho de entrada do app.';
