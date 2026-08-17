# Edge functions — publicação e conferência

Passos que não são migration: dependem do CLI do Supabase e da configuração do
projeto. Precisam ser repetidos em cada projeto — hoje o `desmalha-dev`, depois
o `desmalha-prod`.

## `excluir-conta`

Implementa o fluxo de exclusão de conta descrito no
[README do backend](../README.md#fluxo-de-exclusão-de-conta): apagar os
arquivos pela Storage API → `encerrar_conta` → banir a conta.

Duas portas de entrada, um só caminho de exclusão:

| Quem chama | Como | Como prova de quem é a conta |
|---|---|---|
| App | `POST` `{"acao":"excluir"}` com `Authorization: Bearer <token da sessão>` | o token é validado contra o servidor de auth |
| Web | `GET` abre a página; `POST` `{"acao":"enviar-codigo"}` e depois `{"acao":"confirmar"}` | código de 8 dígitos enviado ao e-mail da conta |

### Publicar

```bash
supabase link --project-ref <ref>
supabase functions deploy excluir-conta
```

O `supabase/config.toml` já declara `verify_jwt = false` para esta função. Em
CLI antigo que ignore essa chave, o mesmo efeito sai da linha de comando:

```bash
supabase functions deploy excluir-conta --no-verify-jwt
```

⚠️ **Sem isso a página não abre.** Com a verificação ligada, o gateway responde
401 antes de a função rodar, e o link que vai para a ficha do Google Play vira
uma página de erro. A falha é visível — mas só para quem abrir o link.

Nenhum segredo precisa ser configurado: `SUPABASE_URL` e as chaves pública e
secreta são injetadas pela plataforma. A função lê os nomes novos
(`SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_SECRET_KEY`) e os antigos
(`SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`), nessa ordem.

### Pré-requisito no banco

A função chama `public.encerrar_conta_do_usuario`, criada pela migration
`20260817010000_rpc_encerrar_conta.sql`. Publicar a função num projeto onde as
migrations não foram aplicadas produz erro no passo 2 — depois de os arquivos já
terem sido apagados. Aplique as migrations primeiro.

### O endereço que vai para o Google Play

```
https://<ref>.supabase.co/functions/v1/excluir-conta
```

É esse endereço que entra no campo de **URL de exclusão de conta** do Play
Console (Política → Segurança de dados). Ele é público e não exige o app
instalado, que é o ponto da exigência.

⚠️ Quando `desmalha.com.br` for registrado (pendência "De marca", na página de
Decisões vigentes), vale trocar por um endereço do domínio próprio apontando
para cá — um link de `supabase.co` na ficha da loja não parece do fornecedor, e
a URL declarada no Play Console pode ser atualizada sem nova revisão.

### Conferência ponta a ponta

Roteiro para rodar contra o `desmalha-dev`, com caixa de e-mail real. Precisa de
uma conta descartável: **ela é destruída no passo 5**.

1. abrir o endereço acima no navegador — a página tem de carregar sem pedir
   login (se vier 401, o `verify_jwt` ficou ligado);
2. pedir código para um e-mail **que não tem conta** — a resposta tem de ser a
   mesma de sempre, e **nenhuma conta pode nascer**; conferir em
   `auth.users` que não apareceu linha nova;
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

## Testes

```bash
./tool/testar_edge.sh
```

Cobrem a ordem obrigatória dos três passos, a interrupção em cada falha, a
paginação e a recursão da varredura de arquivos, e o conteúdo obrigatório da
página (os três prazos da PP v0.2, o aviso de que o dado do aparelho não é
apagado por aqui, e a ausência de recurso externo).

O que os testes **não** cobrem, e por isso o roteiro de conferência acima
existe: que a Storage API, o PostgREST e a Auth Admin API se comportem como os
adaptadores supõem. Isso só o projeto de verdade responde.
