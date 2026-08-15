-- Desmalha — base do backend mínimo: schema privado de conformidade.
--
-- Card: "Autenticação e gestão de contas de usuário" (Fase 4).
-- Fonte do schema: "Resultado: Revisar modelagem de dados para local-first
-- (ago/2026)", seção 5 — DDL do backend mínimo.
--
-- Princípio de corte do backend: se um campo não é necessário para COBRAR,
-- PROVAR CONSENTIMENTO ou ENTREGAR CATÁLOGO, ele não existe aqui. Nenhum dado
-- fiscal do usuário chega a este banco.

create extension if not exists pgcrypto with schema extensions;

create schema if not exists conformidade;

comment on schema conformidade is
  'Rotinas privadas de identidade e conformidade (pseudonimização, encerramento '
  'de conta, expurgo). Nenhum papel de cliente (anon/authenticated) recebe acesso: '
  'tudo aqui roda por service_role ou por função SECURITY DEFINER exposta em public.';

revoke all on schema conformidade from public;
grant usage on schema conformidade to postgres, service_role;

-- ─── Sinalizador de manutenção ──────────────────────────────────────────────
-- aceites_termos é imutável por trigger. As rotinas de expurgo precisam apagar
-- linhas expiradas; em vez de abrir uma exceção por papel (que valeria para
-- qualquer conexão service_role, inclusive a do dashboard), a permissão é dada
-- por transação, via set_config local, e só dentro das funções de expurgo.
create or replace function conformidade.em_manutencao()
returns boolean
language sql
stable
set search_path = ''
as $$
  select coalesce(current_setting('desmalha.manutencao_conformidade', true), 'off') = 'on';
$$;

comment on function conformidade.em_manutencao() is
  'Verdadeiro apenas dentro de uma transação que declarou manutenção de '
  'conformidade. Único caminho pelo qual um aceite de termos pode ser apagado.';

-- ─── Pseudonimização do titular ─────────────────────────────────────────────
-- O identificador pseudonimizado do aceite é HMAC-SHA256 do e-mail com uma chave
-- de servidor. A chave mora no Vault — cifrada com material que NÃO está dentro
-- do banco — justamente para que um dump do Postgres não permita reverter o hash
-- por força bruta sobre a lista de e-mails conhecidos. Ela nunca entra no
-- repositório nem em sessão de nuvem.
create or replace function conformidade.chave_hmac_aceites()
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_chave text;
begin
  select decrypted_secret
    into v_chave
    from vault.decrypted_secrets
   where name = 'desmalha_aceites_hmac_key';

  if v_chave is null or length(v_chave) < 32 then
    raise exception
      'segredo "desmalha_aceites_hmac_key" ausente ou curto demais no Vault do projeto';
  end if;

  return v_chave;
end;
$$;

comment on function conformidade.chave_hmac_aceites() is
  'Lê a chave de pseudonimização do Vault. ATENÇÃO: trocar essa chave torna todos '
  'os titular_hash já gravados incomparáveis com os novos — o registro de aceite '
  'deixa de provar a quem pertence. Ela é rotacionável apenas junto com um '
  'recálculo de toda a tabela, o que exige os e-mails originais.';

create or replace function conformidade.titular_hash(p_email text)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if p_email is null or btrim(p_email) = '' then
    raise exception 'e-mail vazio: não há como derivar o identificador pseudonimizado';
  end if;

  return encode(
    extensions.hmac(lower(btrim(p_email)), conformidade.chave_hmac_aceites(), 'sha256'),
    'hex');
end;
$$;

comment on function conformidade.titular_hash(text) is
  'Identificador pseudonimizado e estável do titular. Sobrevive à exclusão da '
  'conta, que é o que permite ao registro de aceite continuar provando o que '
  'precisa provar depois que o perfil deixa de existir.';

-- ─── Manutenção de atualizado_em ────────────────────────────────────────────
create or replace function conformidade.tocar_atualizado_em()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.atualizado_em := now();
  return new;
end;
$$;
