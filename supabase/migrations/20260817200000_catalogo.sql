-- Catálogo versionado só-leitura (card "Conteúdo versionado por API").
--
-- O ADR local-first tirou o dado fiscal do servidor; o que fica é o conteúdo
-- que muda sem release do app: tabela do IRPF, feriados bancários, perfis de
-- parser por banco e o layout do código de barras do DARF. Corrigir o parser
-- de um banco passa a ser publicar uma linha nova aqui — horas, não semanas
-- de release + review de loja.
--
-- A FONTE DA VERDADE é o repositório (packages/desmalha_core/catalogo/ e
-- perfis/); esta tabela é o meio de entrega. Quem escreve é o passo
-- "Catálogo" do workflow .github/workflows/supabase.yml, como service_role,
-- sincronizando repo → banco e conferindo de volta. Cliente nenhum escreve:
-- não há policy de escrita, e os privilégios são revogados abaixo por
-- clareza — o Supabase concede ALL por default privileges no schema public,
-- e "bloqueado só porque nenhuma policy existe" é uma proteção que um
-- `create policy` distraído desfaz.

create table public.catalogo_itens (
    tipo         text not null,
    id           text not null,
    conteudo     jsonb not null,
    publicado_em timestamptz not null default now(),
    primary key (tipo, id),

    -- Nomes estáveis, minúsculos, sem surpresa de encoding — são chave de
    -- cache no app e nome de diretório no repositório.
    constraint catalogo_tipo_formato check (tipo ~ '^[a-z][a-z0-9_]*$'),
    constraint catalogo_id_formato   check (id   ~ '^[a-z0-9][a-z0-9-]*$'),

    constraint catalogo_conteudo_objeto check (jsonb_typeof(conteudo) = 'object'),

    -- O id da linha é a chave de publicação; o id DENTRO do conteúdo é o que
    -- o app grava nas apurações (ex.: versaoTabelaId). Divergência seria um
    -- catálogo que mente sobre o que serve — recusada aqui, não só no app.
    constraint catalogo_id_coerente check (conteudo->>'id' = id)
);

comment on table public.catalogo_itens is
  'Conteúdo versionado só-leitura servido ao app (tabela IRPF, feriados '
  'bancários, perfis de parser, layout de DARF). Fonte da verdade no '
  'repositório; escrita só pelo CI como service_role.';

alter table public.catalogo_itens enable row level security;

-- Conteúdo público por natureza (tabela de imposto, feriados, formato de
-- CSV de banco) — nada de usuário mora aqui. `anon` lê porque o app precisa
-- do catálogo ANTES de qualquer login: a tela de importação funciona sem
-- conta.
create policy catalogo_leitura on public.catalogo_itens
  for select to anon, authenticated using (true);

-- Explícito em vez de herdado: no Supabase real os default privileges dariam
-- INSERT/UPDATE/DELETE a anon/authenticated (o RLS é que bloqueia); num
-- Postgres cru não dariam nem SELECT. Grant e revoke declarados deixam o
-- resultado idêntico nos dois mundos — e provável por teste.
grant select on public.catalogo_itens to anon, authenticated;
revoke insert, update, delete, truncate, references, trigger
  on public.catalogo_itens from anon, authenticated;
