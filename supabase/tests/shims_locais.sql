-- Desmalha — arremedos mínimos do ambiente Supabase, só para validar as
-- migrations num Postgres cru (CI ou máquina local, sem projeto Supabase).
--
-- NÃO faz parte do schema: nunca rodar contra um projeto Supabase real, onde
-- todos estes objetos já existem de verdade. Serve para responder "as migrations
-- do repositório aplicam sozinhas, sem erro de sintaxe?" sem depender da nuvem.
--
--   psql -f supabase/tests/shims_locais.sql -f supabase/migrations/<cada uma>.sql

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin;
  end if;
end $$;

create schema if not exists auth;

create table if not exists auth.users (
    id                 uuid primary key,
    email              text,
    encrypted_password text,
    is_sso_user        boolean not null default false,
    is_anonymous       boolean not null default false
);

create or replace function auth.uid()
returns uuid language sql stable as $$
  select (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')::uuid;
$$;

create schema if not exists vault;

create table if not exists vault.secrets (
    id               uuid primary key default extensions.gen_random_uuid(),
    name             text unique,
    secret           text,
    description      text
);

create or replace view vault.decrypted_secrets as
  select id, name, description, secret as decrypted_secret from vault.secrets;

create schema if not exists storage;

create table if not exists storage.buckets (
    id                 text primary key,
    name               text,
    public             boolean,
    file_size_limit    bigint,
    allowed_mime_types text[]
);

create table if not exists storage.objects (
    id        uuid primary key default extensions.gen_random_uuid(),
    bucket_id text,
    name      text
);

alter table storage.objects enable row level security;

create or replace function storage.foldername(name text)
returns text[] language sql immutable as $$
  select (string_to_array(name, '/'))[1:array_length(string_to_array(name, '/'), 1) - 1];
$$;
