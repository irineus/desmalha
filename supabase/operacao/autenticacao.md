# Autenticação — o que é código e o que ainda é gente

## Deixou de ser passo manual

Tudo que antes era um roteiro de cliques em Authentication → Providers → Email
agora está em [`supabase/config.toml`](../config.toml) e é aplicado por
`supabase config push` a cada publicação ([workflow](../../.github/workflows/supabase.yml)):

| Antes, na interface | Agora, no `config.toml` |
|---|---|
| Email OTP Length = 8 | `auth.email.otp_length` |
| Email OTP Expiration = 600 | `auth.email.otp_expiry` |
| Confirm email | `auth.email.enable_confirmations` |
| Secure email change | `auth.email.double_confirm_changes` |
| Templates com `{{ .Token }}` | `auth.email.template.*` + [`supabase/templates/`](../templates/) |
| Todos os provedores sociais desabilitados | `auth.external.*.enabled = false` |

O motivo de trazer isso para o repositório não é conforto: passo manual repetido
à mão em dois projetos **diverge sem ninguém perceber**, e dev e prod passariam a
autenticar de formas diferentes.

⚠️ `config push` é **sobrescrita**, não fusão: o que não está declarado no
`config.toml` volta ao padrão do CLI no projeto remoto. Ao mexer lá, declare o
que quer manter.

## O que o cliente espelha

`apps/desmalha_app/lib/auth/porta_auth.dart` repete dois destes valores
(`tamanhoCodigoOtp`, `validadeCodigoOtp`). Divergir não corrompe nada em
silêncio: o usuário simplesmente não entra, e a tela diz que o código tem 8
dígitos enquanto o e-mail traz outra coisa. Falha visível, como a guia de DARF
sem código de barras — mas ainda assim, mude os dois.

## Não existe toggle para desativar senha

Senha e código vivem no mesmo provedor de e-mail, e o Supabase não separa os
dois. Por isso a proibição de senha é garantida em outras duas camadas:

- **no app** — o SDK de auth entra por um arquivo só, e
  `test/auth/trava_sem_senha_test.dart` varre `lib/` a cada execução recusando
  qualquer menção a API de senha ou de provedor social;
- **no banco** — o gatilho `trg_auth_users_sem_senha`
  (`20260815000359_trava_sem_senha.sql`) recusa `auth.users` com
  `encrypted_password` não vazio.

## Limites de envio

O plano free usa o servidor de e-mail embutido, com limite baixo e **sem
garantia de entrega** — serve para desenvolvimento, não para usuário real. Antes
do beta fechado é preciso configurar SMTP próprio e revisar os *rate limits*.

Isso é candidato a card no board, e é urgente pelo motivo óbvio: o e-mail é a
**única** porta de entrada do app. Se ele não chega, ninguém entra.

O cliente já segura reenvios dentro de 60 segundos (`intervaloReenvioOtp`), para
não gastar cota nem levar o usuário a um erro que a tela podia evitar.

## 🔴 Ligar o SMTP é passo de uma vez, no painel — e o CI não faz por você

Sem SMTP próprio, o Supabase **ignora os templates personalizados** e manda o
padrão em inglês, com link em vez dos 8 dígitos que a tela pede. Ou seja:
ninguém entra no app.

Ligue uma vez por projeto, em **Authentication → Emails → SMTP Settings →
Enable custom SMTP**:

| Campo | Valor |
|---|---|
| Sender email | o remetente verificado no Resend |
| Sender name | `Desmalha` |
| Host | `smtp.resend.com` |
| Port | `587` |
| Username | `resend` |
| Password | a API key do Resend (`re_...`) |

⚠️ **O workflow deliberadamente NÃO liga isso.** Ele já tentou, por `PATCH` nos
campos `smtp_*` da Management API, e o efeito foi o oposto: em 17/ago/2026, às
04:39 um e-mail saiu pelo Resend e às 04:42, depois de o workflow rodar, o
toggle estava desligado. **Escrever os sete valores derruba a habilitação** — que
é um estado que a API não expõe (a especificação OpenAPI oficial não tem campo
para ela).

O que o workflow faz hoje é **conferir**: lê a configuração do projeto e reprova
se o host não bater ou a senha estiver vazia, com a instrução de onde ligar. A
garantia de que dev e prod não divergem continua; o que saiu foi a escrita, que
era o que quebrava.

## O que ainda precisa de gente

Uma coisa só, e não dá para automatizar honestamente: **receber o e-mail**.

Nenhum teste prova que a mensagem sai do Supabase, atravessa a internet e chega
numa caixa real — e é justamente isso que o servidor de e-mail embutido do plano
free não garante. O roteiro abaixo é o que fecha essa lacuna. Vale rodar uma vez
por projeto e de novo sempre que o SMTP mudar.

1. `fvm flutter run --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_PUBLISHABLE_KEY=…`
2. pedir código para um e-mail seu — deve chegar um código de **8 dígitos**;
3. entrar; conferir em `public.perfis` que a linha nasceu sozinha (trigger
   `trg_auth_users_criar_perfil`);
4. pedir troca de e-mail para um segundo endereço — devem chegar **dois**
   e-mails, um em cada caixa;
5. confirmar só um lado: a conta **não** pode mudar. Confirmar o outro: aí sim.

O passo 5 é o que mais importa: ele prova que a troca de e-mail não se completa
com uma confirmação só, que é o que impede uma sessão esquecida aberta de levar
a conta embora.
