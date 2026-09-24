-- Allowlist de versões de documento legal no aceite.
--
-- Card: "Allowlist de versões de documento legal no aceite" (Fase 4).
--
-- PROBLEMA: `aceites_termos.versao` só tinha CHECK de FORMATO. O cliente
-- podia chamar registrar_aceite('termos_uso', '2020-01-v1') e gravar aceite
-- de uma versão que nunca existiu. O registro de aceite existe para DEFENDER
-- O OPERADOR; um registro que aceita versão inventada prova menos do que
-- parece — o titular poderia alegar que nunca viu o texto real. Titular,
-- IP e user agent já eram derivados no servidor; a versão era o último campo
-- que o cliente ainda ditava.
--
-- DESENHO:
--   • `public.documentos_legais` é a allowlist: (documento, versão,
--     publicado_em, url, sha256_texto). É ELA que a FK do aceite referencia.
--   • A publicação é a MESMA do resto do conteúdo versionado: um arquivo em
--     packages/desmalha_core/catalogo/documento_legal/<id>.json, publicado em
--     `catalogo_itens` pelo workflow (tool/publicar_catalogo.ts). O app lê o
--     documento pelo catálogo; o gatilho abaixo materializa cada item na
--     allowlist. Um caminho de publicação só, e nenhum passo manual novo.
--   • Publicado é para sempre. Mudar o texto é publicar uma versão NOVA: o
--     hash gravado num aceite antigo precisa continuar apontando para o texto
--     que a pessoa leu. Alterar ou remover documento publicado é recusado —
--     tanto na allowlist quanto no item do catálogo, para que o publicador
--     falhe alto em vez de divergir em silêncio.
--   • O aceite passa a carregar `sha256_texto`, preenchido pelo SERVIDOR a
--     partir da allowlist, e a FK composta (documento, versão, hash) garante
--     que o hash gravado é o do texto publicado daquela versão.

-- ─── Allowlist ──────────────────────────────────────────────────────────────
create table public.documentos_legais (
    documento    text        not null
                 check (documento in ('termos_uso', 'politica_privacidade')),
    -- Mesma convenção de `aceites_termos.versao` (PP/Termos v0.2).
    versao       text        not null check (versao ~ '^\d{4}-\d{2}-v\d+$'),
    publicado_em date        not null,
    url          text        not null check (url ~ '^https://.+'),
    -- SHA-256 dos bytes exatos servidos em `url`, hexadecimal minúsculo.
    sha256_texto text        not null check (sha256_texto ~ '^[0-9a-f]{64}$'),
    registrado_em timestamptz not null default now(),
    primary key (documento, versao),
    -- Alvo da FK composta do aceite: amarra o hash à versão.
    unique (documento, versao, sha256_texto)
);

comment on table public.documentos_legais is
  'Versões publicadas dos documentos legais — a allowlist do registro de '
  'aceite. Materializada a partir de catalogo_itens (tipo documento_legal); '
  'imutável: texto novo é versão nova.';
comment on column public.documentos_legais.sha256_texto is
  'SHA-256 (hex minúsculo) dos bytes exatos servidos em url. É o que o '
  'aceite referencia como prova do texto aceito.';

create or replace function conformidade.documentos_legais_imutaveis()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- Sem exceção de manutenção, ao contrário do aceite: não existe rotina que
  -- precise apagar documento publicado. Um aceite de 5 anos atrás precisa
  -- continuar apontando para o texto que foi lido.
  raise exception
    'documento legal publicado é imutável: texto novo exige versão nova';
end;
$$;

create trigger trg_documentos_legais_imutaveis
    before update or delete on public.documentos_legais
    for each row execute function conformidade.documentos_legais_imutaveis();

-- Leitura pública, como o catálogo: o app mostra o documento antes do login.
alter table public.documentos_legais enable row level security;

create policy documentos_legais_leitura on public.documentos_legais
  for select to anon, authenticated using (true);

grant select on public.documentos_legais to anon, authenticated;
revoke insert, update, delete, truncate, references, trigger
  on public.documentos_legais from anon, authenticated;

-- ─── Catálogo → allowlist ───────────────────────────────────────────────────
-- SECURITY DEFINER porque quem escreve no catálogo é o CI (service_role) e a
-- allowlist não concede escrita a ninguém além do dono.
create or replace function conformidade.catalogo_documento_legal()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_doc    text;
  v_versao text;
begin
  if tg_op = 'INSERT' then
    if new.tipo <> 'documento_legal' then
      return new;
    end if;

    v_doc    := new.conteudo ->> 'documento';
    v_versao := new.conteudo ->> 'versao';

    -- O id do item é derivado, não escolhido (mesma regra do desmalha_core):
    -- dois itens para a mesma versão seriam dois textos disputando um aceite.
    if new.id is distinct from replace(v_doc, '_', '-') || '-' || v_versao then
      raise exception
        'documento_legal/%: o id precisa ser documento-com-hífen + versão (%)',
        new.id, replace(coalesce(v_doc, '?'), '_', '-') || '-' || coalesce(v_versao, '?');
    end if;

    -- Campo ausente vira NULL e o NOT NULL da allowlist recusa; formato
    -- errado cai nos CHECKs. Nada aqui é validado duas vezes à toa.
    insert into public.documentos_legais
        (documento, versao, publicado_em, url, sha256_texto)
    values
        (v_doc, v_versao,
         (new.conteudo ->> 'publicado_em')::date,
         new.conteudo ->> 'url',
         new.conteudo ->> 'sha256_texto');
    return new;
  end if;

  -- UPDATE ou DELETE. `old` existe nos dois.
  if old.tipo = 'documento_legal'
     or (tg_op = 'UPDATE' and new.tipo = 'documento_legal') then
    raise exception
      'documento_legal/%: documento publicado não muda nem sai do catálogo — '
      'texto novo exige versão nova', old.id;
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

create trigger trg_catalogo_documento_legal_ins
    after insert on public.catalogo_itens
    for each row execute function conformidade.catalogo_documento_legal();

create trigger trg_catalogo_documento_legal_mut
    before update or delete on public.catalogo_itens
    for each row execute function conformidade.catalogo_documento_legal();

-- ─── O aceite referencia o texto aceito ─────────────────────────────────────
-- Até aqui o app nunca chamou registrar_aceite (a camada de aceite no app
-- entra com as telas de onboarding), então não há aceite antigo sem hash.
-- Se houver, a migration PARA em vez de inventar a que texto ele se refere.
do $$
begin
  if exists (select 1 from public.aceites_termos) then
    raise exception
      'aceites_termos tem registros anteriores à allowlist; eles não podem '
      'ganhar sha256_texto por suposição — decida o destino deles antes de '
      'aplicar esta migration';
  end if;
end;
$$;

alter table public.aceites_termos
    add column sha256_texto text not null,
    add constraint aceites_documento_publicado
        foreign key (documento, versao, sha256_texto)
        references public.documentos_legais (documento, versao, sha256_texto);

comment on column public.aceites_termos.sha256_texto is
  'Hash do texto aceito, copiado pelo servidor da allowlist. A FK composta '
  'garante que é o hash publicado daquela versão.';

-- A imutabilidade do aceite passa a cobrir o hash.
create or replace function conformidade.aceites_imutaveis()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'DELETE' then
    if conformidade.em_manutencao() then
      return old;
    end if;
    raise exception
      'aceite de termos é imutável: exclusão só pela rotina de expurgo';
  end if;

  if new.id           is distinct from old.id
  or new.titular_hash is distinct from old.titular_hash
  or new.documento    is distinct from old.documento
  or new.versao       is distinct from old.versao
  or new.sha256_texto is distinct from old.sha256_texto
  or new.aceito_em    is distinct from old.aceito_em
  or new.ip           is distinct from old.ip
  or new.user_agent   is distinct from old.user_agent then
    raise exception
      'aceite de termos é imutável: o conteúdo do registro não pode mudar';
  end if;

  if new.usuario_id is distinct from old.usuario_id
     and not (old.usuario_id is not null and new.usuario_id is null) then
    raise exception
      'aceite de termos é imutável: usuario_id só pode ser desvinculado';
  end if;

  if new.relacao_encerrada_em is distinct from old.relacao_encerrada_em
     and not (old.relacao_encerrada_em is null and new.relacao_encerrada_em is not null) then
    raise exception
      'aceite de termos é imutável: o encerramento não pode ser alterado nem desfeito';
  end if;

  return new;
end;
$$;

-- ─── registrar_aceite recusa versão não publicada ───────────────────────────
-- Mesma assinatura: o app não muda. O que muda é que `p_versao` deixa de ser
-- a palavra do cliente e passa a ser uma CHAVE na allowlist.
create or replace function public.registrar_aceite(
    p_documento text,
    p_versao    text)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid      uuid := (select auth.uid());
  v_email    text;
  v_sha      text;
  v_id       bigint;
  v_headers  jsonb;
  v_ip       inet;
  v_ua       text;
begin
  if v_uid is null then
    raise exception 'não autenticado';
  end if;

  select sha256_texto into v_sha
    from public.documentos_legais
   where documento = p_documento
     and versao = p_versao;

  if v_sha is null then
    -- Falha visível, com código próprio para o app distinguir de erro de
    -- rede: aceite de versão não publicada não é gravado "por enquanto".
    raise exception 'versão % de % não está publicada', p_versao, p_documento
      using errcode = 'P0002',
            hint = 'o app precisa mostrar e enviar uma versão servida pelo catálogo';
  end if;

  select email into v_email from auth.users where id = v_uid;

  v_headers := coalesce(nullif(current_setting('request.headers', true), ''), '{}')::jsonb;

  begin
    v_ip := nullif(btrim(split_part(coalesce(v_headers ->> 'x-forwarded-for', ''), ',', 1)), '')::inet;
  exception when others then
    v_ip := null;
  end;

  v_ua := left(nullif(btrim(coalesce(v_headers ->> 'user-agent', '')), ''), 500);

  insert into public.aceites_termos
      (usuario_id, titular_hash, documento, versao, sha256_texto, ip, user_agent)
  values
      (v_uid, conformidade.titular_hash(v_email), p_documento, p_versao, v_sha,
       v_ip, v_ua)
  on conflict (usuario_id, documento, versao) do nothing
  returning id into v_id;

  if v_id is null then
    select id into v_id
      from public.aceites_termos
     where usuario_id = v_uid
       and documento = p_documento
       and versao = p_versao;
  end if;

  return v_id;
end;
$$;

comment on function public.registrar_aceite(text, text) is
  'Único caminho de gravação de aceite. Recusa versão fora da allowlist '
  '(documentos_legais) e grava o hash do texto publicado. Idempotente por '
  '(usuário, documento, versão). SECURITY DEFINER: titular_hash, hash do '
  'texto, IP e user agent são derivados no servidor.';

-- `create or replace` preserva os privilégios; reafirmados por clareza.
revoke all on function public.registrar_aceite(text, text) from public, anon;
grant execute on function public.registrar_aceite(text, text) to authenticated;
