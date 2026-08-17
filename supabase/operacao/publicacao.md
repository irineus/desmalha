# Publicação do backend

Tudo que o backend precisa para existir num projeto Supabase é aplicado pelo
workflow [`.github/workflows/supabase.yml`](../../.github/workflows/supabase.yml).
Não há passo manual recorrente.

| Etapa | O quê | Como |
|---|---|---|
| 1 | Suítes do backend | `tool/testar_edge.sh` + `tool/testar_supabase.sh --descartavel` num Postgres limpo |
| 2 | Schema | `supabase db push` |
| 3 | Bootstrap do projeto | `psql -f supabase/pos_deploy/*.sql` (Vault + agendamento do expurgo) |
| 4 | Configuração de Auth | `supabase config push` |
| 5 | Edge functions | `supabase functions deploy excluir-conta` |
| 6 | Conferência | lê de volta a chave, os jobs de cron e a lista de funções |

A etapa 1 é portão: `publicar` depende de `verificar`. Publicar migration não
verificada seria automatizar o erro em vez do trabalho. E a suíte SQL **reprova
de verdade** — ela levanta exceção quando qualquer asserção falha, e também
quando o total cai abaixo do esperado, para que uma suíte que não executou nada
não passe por vacuidade.

**Quando roda:** push no `main` que toque em `supabase/**` publica no **dev**.
Produção é disparo explícito: **Actions → Supabase → Run workflow → `PROD`**.
Nada publica em produção por acidente de push.

Pull request roda só a etapa 1.

## Configuração de uma vez (é o único trabalho manual)

Credencial não entra em repositório — regra permanente 1 do `CLAUDE.md` — então
esta parte é sua. Em **Settings → Secrets and variables → Actions**, no
repositório:

| Nome | Aba | Valor |
|---|---|---|
| `SUPABASE_ACCESS_TOKEN` | Secrets | token pessoal, em supabase.com/dashboard/account/tokens |
| `SUPABASE_DB_PASSWORD_DEV` | Secrets | senha do banco do `desmalha-dev` |
| `SUPABASE_DB_URL_DEV` | Secrets | string de conexão do **Session pooler** — ver o aviso abaixo |
| `SUPABASE_PROJECT_REF_DEV` | Variables *(ou Secrets)* | `caqxssmxeiuutfguxdzj` |
| `SUPABASE_SITE_URL_DEV` | Variables *(ou Secrets)* | `https://caqxssmxeiuutfguxdzj.supabase.co` |
| `RESEND_API_KEY_DEV` | Secrets | API key do Resend (`re_...`) |
| `SMTP_ADMIN_EMAIL_DEV` | Variables *(ou Secrets)* | remetente verificado no seu Resend |

`SUPABASE_ACCESS_TOKEN`, as duas de banco e a `RESEND_API_KEY_*` **têm de ser
secrets**: são credenciais. As outras funcionam nas duas abas — o workflow lê
`vars` e cai para `secrets` se não achar. `Variables` é preferível só porque o
valor sai legível no log, o que ajuda a depurar.

### 🔴 O SMTP não é opcional

Descoberto na primeira publicação real: o Supabase **recusa personalizar
template de e-mail em projeto free que usa o provedor embutido**. E o template
padrão manda um **link**, sem `{{ .Token }}` — enquanto a tela do app pede **8
dígitos**.

Ou seja: sem SMTP próprio, ninguém consegue entrar no app. Não é degradação de
entrega, é login impossível. É por isso que `RESEND_API_KEY_*` está na lista de
obrigatórios, e o workflow para se ela faltar.

**No Resend:** o usuário SMTP é literalmente `resend` e a senha é a API key —
por isso só a key precisa ser cadastrada. O `SMTP_ADMIN_EMAIL_*` é o remetente,
e depende do que a sua conta tem verificado. Sem domínio próprio
(`desmalha.com.br` segue pendente em "De marca"), o remetente disponível é o de
teste do Resend, que **entrega apenas para o e-mail dono da conta** — suficiente
para a conferência do dev, insuficiente para o beta. Verificar um domínio é
pré-requisito do beta fechado, não deste card.

Para produção, os mesmos com sufixo `_PROD` (o `SUPABASE_ACCESS_TOKEN` é um só,
sem sufixo — ele é da sua conta, não do projeto).

⚠️ **Por que sufixo e não Environment do GitHub:** no plano **Free**, repositório
privado **não pode configurar Environments**, e este repositório é privado.
Sufixo funciona em qualquer plano. Com GitHub Pro/Team dá para migrar e ganhar
aprovação obrigatória antes de produção; por ora, o que segura produção é ela só
existir por disparo manual.

O workflow confere os cinco **antes** de começar a publicar e falha nomeando o
que faltou — melhor do que quebrar no meio, com uma mensagem do CLI sobre
credencial ausente.

### 🔴 A string de conexão tem de ser a do *Session pooler*

No botão **Connect** do dashboard aparecem três strings. A que serve aqui é a de
**Session pooler**, porta **5432**, host `aws-<região>.pooler.supabase.com`:

```
postgresql://postgres.<ref>:<senha>@aws-<regiao>.pooler.supabase.com:5432/postgres
```

Não é preferência. A **conexão direta** (`db.<ref>.supabase.co`) é **IPv6** no
plano free, e a documentação do Supabase lista o **GitHub Actions entre as
plataformas que só falam IPv4** — de lá, a conexão direta simplesmente não
resolve. O *Transaction pooler* (porta 6543) também não serve: ele não suporta
*prepared statements*, e migrations usam.

O sintoma de errar é um timeout de conexão no passo de migrations, que não diz
nada sobre IPv6 — daí este aviso estar aqui e não na sua memória.

## O endereço que vai para o Google Play

🔴 **AINDA NÃO EXISTE UM ENDEREÇO UTILIZÁVEL.** Leia a seção abaixo antes de
declarar qualquer coisa no Play Console.

### O gateway do Supabase não deixa a página renderizar

Medido em 17/ago/2026 contra a função já publicada no `desmalha-dev`. Um `GET`
em `https://<ref>.supabase.co/functions/v1/excluir-conta` devolve **HTTP 200**
com o HTML correto no corpo — e estes cabeçalhos:

```
Content-Type: text/plain
Content-Security-Policy: default-src 'none'; sandbox
x-content-type-options: nosniff
```

A função devolve `text/html; charset=utf-8`. **O gateway reescreve para
`text/plain` e injeta uma CSP de sandbox.** Com `nosniff` junto, o navegador não
tem como reinterpretar: quem abrir o link vê o **código-fonte** da página, não a
página. E mesmo que renderizasse, `default-src 'none'; sandbox` bloquearia o
script que faz o formulário funcionar.

Não está documentado, mas o comportamento é consistente com uma proteção
anti-phishing deliberada: servir HTML arbitrário de dentro de `*.supabase.co`
transformaria o domínio deles em hospedagem de página falsa. Repare que só o
HTML é afetado — as rotas `POST` seguem devolvendo
`application/json; charset=utf-8` normalmente, e o fluxo de exclusão em si está
inteiro e funcionando.

### O que isso muda

O **back-end da exclusão está pronto e publicado**. O que falta é um lugar de
onde servir a página, e ele não pode ser o `supabase.co`. Dois caminhos:

1. **Hospedar o HTML estático em outro lugar** (Cloudflare Pages, GitHub Pages,
   Netlify — todos com faixa gratuita) e deixá-lo chamar a função por `POST`. O
   CORS da função já é `*`, então funciona sem mudança no servidor. Não depende
   de domínio próprio: um endereço do próprio serviço já serve, e depois aponta
   para `desmalha.com.br`. **É o caminho barato e o recomendado.**
2. **Domínio próprio apontando para a função**, via *custom domain* do Supabase
   — que é add-on **pago**, e ainda assim precisa ser confirmado se a reescrita
   de `text/html` também vale para domínio próprio.

Enquanto isso não existir, **não declare a URL no Play Console**: um link que
mostra código-fonte é pior do que um campo em branco na revisão.

⚠️ O Google Play exige **dois** caminhos de exclusão de quem deixa criar conta
pelo app: este link e um botão **dentro do app**. O botão ainda não existe — é
card próprio no board.

⚠️ Quando `desmalha.com.br` for registrado (pendência "De marca"), vale trocar
por um endereço do domínio próprio: um link de `supabase.co` na ficha da loja
não parece do fornecedor. A URL declarada no Play Console pode ser atualizada
sem nova revisão.

## Publicar à mão, se precisar

O workflow é a forma normal. Se for necessário publicar de uma máquina:

```bash
supabase db push --db-url "$SUPABASE_DB_URL"
for f in supabase/pos_deploy/*.sql; do psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f "$f"; done
supabase link --project-ref <ref> && supabase config push
supabase functions deploy excluir-conta --project-ref <ref>
```

A ordem importa: a edge function chama `encerrar_conta_do_usuario`, e publicá-la
antes das migrations deixaria a exclusão falhando no passo 2 — depois de os
arquivos do usuário já terem sido apagados.

## `verify_jwt = false` na função de exclusão

Declarado em [`config.toml`](../config.toml). **Sem isso a página não abre**: com
a verificação ligada, o gateway responde 401 antes de a função rodar, e o link
que vai para a ficha da loja vira uma página de erro.

A contrapartida está assumida dentro da função: toda rota dela é pública, e cada
uma prova por si de quem é a conta — código enviado ao e-mail no caminho web,
token de sessão validado contra o servidor de auth no caminho do app.

## Conferência da exclusão de conta

O que os testes não cobrem — e por isso este roteiro existe — é que a Storage
API, o PostgREST e a Auth Admin API se comportem como os adaptadores supõem.
Isso só o projeto de verdade responde. Precisa de uma conta descartável: **ela é
destruída no passo 5**.

1. abrir o endereço acima no navegador — a página tem de carregar sem pedir
   login (se vier 401, o `verify_jwt` não pegou);
2. pedir código para um e-mail **que não tem conta** — a resposta tem de ser a
   mesma de sempre, e **nenhuma conta pode nascer**; conferir em `auth.users`
   que não apareceu linha nova;
3. entrar no app com uma conta descartável e mandar um arquivo qualquer para o
   bucket `backups`, para que o passo 2 do fluxo tenha o que verificar;
4. na página, pedir o código para essa conta e digitar um código errado — tem de
   recusar sem apagar nada;
5. digitar o código certo — a página confirma a exclusão. Conferir, no banco:
   - `storage.objects` sem nenhuma linha no prefixo do usuário;
   - `public.perfis.excluido_em` preenchido;
   - `auth.users.banned_until` no futuro;
6. tentar entrar de novo com o mesmo e-mail no app — tem de recusar (a conta
   está banida até o expurgo dos 30 dias apagá-la de vez).

O passo 2 é o que mais importa repetir a cada mudança: `shouldCreateUser: false`
é a única coisa que impede a página de exclusão de virar uma página de cadastro.
