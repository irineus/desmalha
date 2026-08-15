# Configuração de autenticação no painel do Supabase

Passos que **não são migration** porque não existem em SQL: vivem na
configuração do projeto (Authentication → Sign In / Providers → Email) e nos
templates de e-mail. Precisam ser repetidos em cada projeto — hoje o
`desmalha-dev`, depois o `desmalha-prod`.

O cliente Flutter (`apps/desmalha_app/lib/auth/`) **espelha** estes valores em
`porta_auth.dart` (`tamanhoCodigoOtp`, `validadeCodigoOtp`). Divergir não
corrompe nada em silêncio: o usuário simplesmente não consegue entrar, e a
tela diz que o código tem 8 dígitos enquanto o e-mail traz 6. Falha visível,
como a guia de DARF sem código de barras.

## 1. Provedor de e-mail

| Opção | Valor | Por quê |
|---|---|---|
| Email provider | **habilitado** | é o único caminho de entrada |
| Confirm email | **habilitado** | sem confirmação, o e-mail deixaria de provar posse da caixa — e o e-mail **é** a conta |
| Secure email change | **habilitado** | é o que dispara código para o endereço ATUAL **e** para o NOVO; sem isso, uma sessão esquecida aberta bastaria para levar a conta embora |
| Email OTP Expiration | **600** (segundos) | espelhado em `validadeCodigoOtp` |
| Email OTP Length | **8** | espelhado em `tamanhoCodigoOtp` |

⚠️ **Não existe toggle para desativar login por senha** — senha e código vivem
no mesmo provedor de e-mail. É por isso que a proibição de senha é garantida em
duas outras camadas: o código do app (uma porta única, verificada por
`test/auth/trava_sem_senha_test.dart`) e o gatilho
`trg_auth_users_sem_senha` no banco.

## 2. Nenhum provedor social

Todos os provedores OAuth/SSO ficam **desabilitados**. Não é preferência de
estilo: login social traria a exigência de *Sign in with Apple* na submissão à
App Store e colocaria um terceiro no caminho da identidade. O teste do app
recusa qualquer chamada de provedor social em `lib/`.

## 3. Templates de e-mail

Por padrão os templates mandam um **link**, e o app precisa de um **código**.
Em Authentication → Emails, cada template abaixo tem de conter `{{ .Token }}`:

| Template | Quando é usado |
|---|---|
| **Confirm signup** | primeiro acesso de um e-mail que ainda não tem conta |
| **Magic Link** | acessos seguintes (a conta já existe) |
| **Change Email Address** | os dois lados da troca de e-mail |

Sem `{{ .Token }}` o usuário recebe só um link e não tem o que digitar na tela.

Sugestão de corpo, em português (o texto completo entra no card de conteúdo):

```
Seu código de acesso ao Desmalha é {{ .Token }}.
Ele vale por 10 minutos. Se não foi você que pediu, ignore este e-mail.
```

## 4. Limites de envio

O plano free do Supabase usa o servidor de e-mail embutido, com limite baixo e
sem garantia de entrega — serve para desenvolvimento, não para usuário real.
Antes do beta fechado, configurar **SMTP próprio** (Authentication → SMTP
Settings) e revisar os *rate limits*. Isso não é escopo deste card; está
anotado como candidato a card no fechamento.

O cliente já segura reenvios dentro de 60 segundos (`intervaloReenvioOtp`)
para não gastar cota nem levar o usuário a um erro que a tela podia evitar.

## 5. Conferência

Depois de configurar, o ciclo que prova que está tudo de pé:

1. `fvm flutter run --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_PUBLISHABLE_KEY=…`
2. pedir código para um e-mail seu — deve chegar um código de **8 dígitos**;
3. entrar; conferir em `public.perfis` que a linha nasceu sozinha (trigger
   `trg_auth_users_criar_perfil`);
4. pedir troca de e-mail para um segundo endereço — devem chegar **dois**
   e-mails, um em cada caixa;
5. confirmar só um lado: a conta **não** pode mudar. Confirmar o outro: aí sim.
