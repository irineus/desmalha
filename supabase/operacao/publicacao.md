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

Os três primeiros **têm de ser secrets**: são credenciais. Os dois últimos
funcionam nas duas abas — o workflow lê `vars` e cai para `secrets` se não achar.
`Variables` é preferível só porque o valor sai legível no log, o que ajuda a
depurar; como secret, sai mascarado.

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

```
https://<ref>.supabase.co/functions/v1/excluir-conta
```

É o que entra no campo de **URL de exclusão de conta** do Play Console
(Política → Segurança de dados). É público e não exige o app instalado, que é o
ponto da exigência.

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
