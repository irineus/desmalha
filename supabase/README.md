# Backend mínimo do Desmalha (Supabase)

Schema do servidor: **identidade, prova de consentimento, assinatura e catálogo**.
Nenhum dado fiscal do usuário chega aqui — transações, livro-caixa, apurações,
DARFs e CPF de pagadores vivem no dispositivo, em SQLite/Drift cifrado com
SQLCipher. Ver `CLAUDE.md` na raiz e a página "Desmalha — Decisões vigentes".

Fonte do schema: **"Resultado: Revisar modelagem de dados para local-first
(ago/2026)", seção 5**, com uma correção deliberada (abaixo).

## O que existe hoje

| Migration | Conteúdo |
|---|---|
| `20260811204627_criar_buckets_backup_e_suporte` | buckets `backups` e `suporte-extratos` |
| `20260815000253_conformidade_base` | schema privado `conformidade`, HMAC do titular, sinalizador de manutenção |
| `20260815000309_perfis` | `public.perfis` + RLS + criação automática do perfil no cadastro |
| `20260815000332_aceites_termos` | `public.aceites_termos` + imutabilidade + `registrar_aceite` |
| `20260815000352_exclusao_e_expurgo` | encerramento de conta e as duas rotinas de expurgo |
| `20260815000359_trava_sem_senha` | trava de servidor contra conta com senha |
| `20260817010000_rpc_encerrar_conta` | porta em `public` pela qual a edge function alcança o encerramento |

| Edge function | Conteúdo |
|---|---|
| `excluir-conta` | fluxo de exclusão + página pública exigida pelo Google Play |

| Pós-deploy | Conteúdo |
|---|---|
| `10_chave_hmac_aceites` | sorteia a chave de pseudonimização no Vault, se ainda não houver |
| `20_agendamento_expurgo` | habilita `pg_cron` e agenda as duas rotinas de expurgo |

O pós-deploy roda **automaticamente** a cada publicação, depois das migrations.
Não é migration porque depende da plataforma (Vault, `pg_cron`), e as migrations
precisam continuar aplicáveis num Postgres pelado — é isso que
`tool/testar_supabase.sh` verifica.

Ainda **não** existem: `assinaturas`, `eventos_pagamento`, `backups_metadados`,
`envios_suporte` e as sete tabelas do catálogo versionado. São escopo de outros
cards (assinaturas na Fase 6; catálogo no card "Conteúdo versionado por API";
metadados de backup no card de backup E2E).

## A correção do `ON DELETE RESTRICT`

O DDL aprovado trazia, ao mesmo tempo, `perfis.excluido_em` (soft delete com
expurgo) e `aceites_termos.usuario_id → perfis(id) ON DELETE RESTRICT`. As duas
coisas não coexistem: o expurgo falha na FK e a conta **nunca** é de fato
excluída — colidindo com o art. 18, VI da LGPD e com a exigência de exclusão de
conta do Google Play.

O que foi implementado, conforme o caminho definido no card de PP/Termos:

- `usuario_id` vira **`ON DELETE SET NULL`**;
- o vínculo forte passa a ser **`titular_hash`** — HMAC-SHA256 do e-mail com uma
  chave de servidor guardada no Vault, fora do alcance de um dump do Postgres;
- `relacao_encerrada_em` marca o início da retenção, para que os **5 anos** da PP
  v0.2 (art. 7º, VI) sejam um prazo executado por rotina, e não uma frase.

O teste 22 da suíte é a prova: depois do expurgo do perfil, o aceite continua
existindo, desvinculado, e ainda é reconhecível pelo `titular_hash`.

## Três prazos, deliberadamente diferentes

| O quê | Prazo | Onde |
|---|---|---|
| Blobs de backup e arquivos de suporte | **imediato**, sem carência | edge function, via Storage API |
| Perfil e usuário de auth | 30 dias (reversão de engano) | `conformidade.expurgar_contas_encerradas()` |
| Registro de aceite | 5 anos após o encerramento | `conformidade.expurgar_aceites_expirados()` |

## Fluxo de exclusão de conta

Não existe RPC de cliente para excluir a conta, de propósito. O pedido — no app
ou pelo **link web** exigido pelo Google Play — passa por uma edge function com
`service_role`, **nesta ordem**:

1. apagar os objetos do usuário nos buckets **pela Storage API**;
2. `select conformidade.encerrar_conta('<uuid>')`;
3. banir/invalidar a sessão do usuário na Auth Admin API.

O passo 1 não pode ser feito em SQL: o próprio Supabase bloqueia `DELETE` direto
em `storage.objects` (`storage.protect_delete`), porque apagar a linha não remove
o arquivo — deixaria o blob vivo com o registro limpo, a pior combinação
possível. É justamente por isso que `encerrar_conta` **verifica** que não sobrou
nenhum objeto no prefixo do usuário e **recusa encerrar** enquanto sobrar: se as
linhas sumiram, a API foi mesmo chamada. Mesma postura da guia de DARF que sai
sem código de barras — falhar visível em vez de registrar como feito o que não
foi feito.

A edge function está em
[`functions/excluir-conta`](functions/excluir-conta/index.ts), com a ordem dos
três passos isolada em `functions/_compartilhado/exclusao.ts` e coberta por
teste — inclusive a regra que importa: **um passo que falha interrompe os
seguintes**. Banir um usuário cujo backup continua no bucket produziria conta
inacessível com dado retido, exatamente o que a PP v0.2 promete não produzir.

O passo 2 não é chamado direto: `conformidade` é um schema privado e o PostgREST
não o enxerga. A função chama `public.encerrar_conta_do_usuario`, uma porta
estreita executável só por `service_role` — a alternativa seria expor o schema
`conformidade` inteiro na API, entregando junto as rotinas de expurgo e a
leitura da chave de pseudonimização.

A mesma função serve a **página pública** de exclusão exigida pelo Google Play
de quem deixa criar conta no app: quem trocou de celular ou já desinstalou
precisa conseguir excluir a conta assim mesmo. A página prova a posse do e-mail
com o mesmo código de 8 dígitos do login. Publicação, endereço e roteiro de
conferência em [`operacao/publicacao.md`](operacao/publicacao.md).

⚠️ Falta do card: o botão **dentro do app**. O Google Play exige os dois
caminhos — no app e na web — de quem permite criar conta pelo app.

## Autenticação sem senha

A decisão é OTP por e-mail, sem senha, e o Supabase não tem toggle para
desativar login por senha. A garantia primária é do código do app. A trava em
`20260815000359` é a segunda camada: um cadastro com senha que escape falha alto,
no banco, em vez de criar em silêncio uma conta cuja senha vira o elo fraco do
backup.

A garantia primária existe desde ago/2026 em `apps/desmalha_app/lib/auth/`: o
SDK de auth entra no app por **um arquivo só** (`porta_auth_supabase.dart`), e
`test/auth/trava_sem_senha_test.dart` varre `lib/` a cada execução recusando
qualquer menção a API de senha ou de provedor social — mais o próprio
isolamento do SDK, para que a auditoria continue cabendo em um arquivo.

Código de 8 dígitos, validade de 600s, *secure email change* e os templates com
`{{ .Token }}` **não são mais passos de painel**: estão em
[`config.toml`](config.toml) e são aplicados por `supabase config push`. Ver
[`operacao/autenticacao.md`](operacao/autenticacao.md).

Para desligar numa emergência de autenticação:

```sql
alter table auth.users disable trigger trg_auth_users_sem_senha;
```

## Publicação automática

Não há passo manual recorrente. O workflow
[`.github/workflows/supabase.yml`](../.github/workflows/supabase.yml) verifica e
publica: suítes → migrations → pós-deploy → configuração de Auth → edge
functions → conferência do que ficou de pé.

Push no `main` publica no **dev**; produção é disparo explícito. O único trabalho
seu é registrar as credenciais do projeto uma vez, em Settings → Environments —
a tabela está em [`operacao/publicacao.md`](operacao/publicacao.md), com o
roteiro de publicação à mão para o caso de precisar.

A ordem das etapas importa: a edge function chama `encerrar_conta_do_usuario`, e
publicá-la antes das migrations deixaria a exclusão falhando no passo 2 — depois
de os arquivos do usuário já terem sido apagados.

## Testes

```bash
./tool/testar_supabase.sh                 # Postgres local descartável, sem nuvem
SUPABASE_DB_URL='postgresql://…' ./tool/testar_supabase.sh --remoto
./tool/testar_supabase.sh --descartavel 'postgresql://…'   # modo do CI: ESCREVE
./tool/testar_edge.sh                     # edge functions (Deno), sem nuvem
```

As três primeiras rodam a mesma suíte; mudam só em quem sobe o banco. O CI usa
`--descartavel` contra um *service container*, e o nome avisa o que importa: esse
modo **escreve** (aplica shims e migrations), então apontá-lo para um banco com
dados reais não é teste, é acidente.

O modo local sobe um Postgres do zero, aplica `supabase/tests/shims_locais.sql`
(arremedos mínimos de `auth`, `vault` e `storage`), aplica **todas** as migrations
numa base limpa e roda a suíte. É o que responde "as migrations do repositório
reproduzem o schema sozinhas?" — pergunta que aplicar migration por migration na
nuvem não responde, porque lá o estado já existe.

36 asserções, tudo dentro de uma transação que termina em `ROLLBACK` — pode
rodar contra o `desmalha-dev` sem deixar resíduo. Cobrem: criação automática do
perfil, as duas travas de senha, derivação e estabilidade do `titular_hash`,
idempotência do aceite, imutabilidade (conteúdo e exclusão), RLS por papel,
recusa de encerramento com blob pendente, o expurgo em cascata, a sobrevivência
do aceite desvinculado e — as cinco últimas — que a porta em `public` delega o
encerramento, herda a recusa com blob pendente e **não** é executável por `anon`
nem por `authenticated`.

Não usa pgTAP de propósito: a extensão teria de ser instalada no projeto, e um
arcabouço de teste não precisa existir em produção para o teste rodar.

⚠️ A suíte **reprova de verdade**: ao final, levanta exceção se qualquer asserção
falhou e também se o total ficou abaixo do esperado. Sem isso ela imprimiria
"FALHOU" e sairia com código 0 — o que basta para uma pessoa lendo a tela e não
basta para um portão de CI. Portão que não reprova é pior do que portão nenhum:
dá a sensação de cobertura sem a cobertura.

## Aviso do linter aceito conscientemente

`authenticated_security_definer_function_executable` em `public.registrar_aceite`
é **intencional**. A função precisa ser `SECURITY DEFINER` e chamável pelo
usuário autenticado justamente para que `titular_hash`, `ip` e `user_agent`
sejam derivados no servidor. Se o cliente tivesse `INSERT` direto na tabela,
poderia gravar um hash qualquer e a prova de consentimento passaria a valer o que
o cliente disser. Único aviso do linter no projeto.
