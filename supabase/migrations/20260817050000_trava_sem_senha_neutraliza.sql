-- Desmalha — a trava anti-senha passa a NEUTRALIZAR em vez de recusar.
--
-- Card: "Autenticação e gestão de contas de usuário" (Fase 4).
--
-- POR QUE MUDOU, DEPOIS DE DUAS TENTATIVAS
--
-- A primeira versão recusava qualquer `encrypted_password` não vazio, e isso
-- bloqueava o cadastro por OTP — nenhuma conta podia ser criada.
--
-- A segunda tentou deixar passar só o marcador de "sem senha", supondo que
-- fosse o hash da string vazia. Não é. A mensagem auto-diagnóstica que ela
-- carregava respondeu na primeira execução:
--
--   Valor recusado: 60 caracteres, começando em "$2a$10$"
--
-- e `crypt('', valor) <> valor`. O GoTrue grava um **bcrypt de algo aleatório**
-- ao criar conta sem senha. Isso é indistinguível de uma senha real olhando o
-- hash — que é a propriedade que o bcrypt existe para ter. Não há inspeção
-- possível: a segunda abordagem estava condenada de saída.
--
-- O QUE ESTE ARQUIVO FAZ
--
-- Inverte a postura. A regra sempre foi **nenhuma senha pode servir para
-- entrar**, e recusar a escrita era só um meio de chegar lá — um meio que, além
-- de não funcionar, dependia de adivinhar o formato do que o provedor grava.
-- Agora o banco **apaga** o campo: qualquer valor que chegue vira null.
--
-- A garantia fica mais forte, não mais fraca. Antes: "escrita com senha é
-- recusada, se eu souber reconhecê-la". Agora: **não existe senha em
-- `auth.users`, ponto** — e quem tentar entrar por senha não encontra o que
-- verificar. É uma propriedade do estado do banco, não do caminho de escrita.
--
-- A visibilidade não se perde: cada descarte emite `warning`, que vai para os
-- logs do projeto. O que se perde é a falha alta — e ela custava o app inteiro.
--
-- A garantia primária segue sendo do cliente: `apps/desmalha_app/lib/auth/`, com
-- a varredura de fonte em `test/auth/trava_sem_senha_test.dart`. Esta é a rede.

create or replace function conformidade.recusar_senha()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.encrypted_password is not null and new.encrypted_password <> '' then
    -- Não dá para saber se veio de um cadastro por OTP (marcador aleatório do
    -- GoTrue) ou de uma senha de verdade — bcrypt não deixa. Nos dois casos o
    -- destino é o mesmo, e é justamente por isso que apagar funciona onde
    -- inspecionar não funcionava.
    raise warning
      'senha descartada em auth.users (id %): o Desmalha autentica só por '
      'código de e-mail. Se isto veio do cliente, há chamada com senha no app.',
      new.id;
    new.encrypted_password := null;
  end if;
  return new;
end;
$$;

comment on function conformidade.recusar_senha() is
  'Garante que auth.users nunca guarde senha utilizável: qualquer valor gravado '
  'em encrypted_password é apagado, com warning no log. Não recusa a escrita — '
  'recusar bloqueava o cadastro por OTP, único caminho de entrada do app.';
