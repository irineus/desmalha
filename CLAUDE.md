# CLAUDE.md — Contexto do projeto para o Claude Code

## O que é o Desmalha
App mobile (Android + iOS) de **controle fiscal (carnê-leão)** para autônomos brasileiros
PF que recebem via Pix: importa extrato OFX/CSV, classifica Pix por remetente, calcula o
imposto mensal, gera DARF (código 0190) e prepara os consolidados para o e-CAC.

- **Arquitetura local-first:** todo dado fiscal vive no dispositivo, em SQLite/Drift
  cifrado com SQLCipher; o motor de cálculo é Dart puro rodando no aparelho. O servidor
  (Supabase) só cuida de identidade/assinatura, catálogo fiscal versionado só-leitura e
  blobs de backup cifrados ponta-a-ponta. Claim de privacidade do produto:
  **"nem nós conseguimos ver seus dados"** — nenhuma feature pode quebrá-lo.
- **Lançamento Android-primeiro.** iOS fica compilável e testado em simulador via CI
  (Codemagic), mas sem conta Apple até o app gerar R$ 500 na Play Store.
- O planejamento vive FORA deste repo: projeto no Claude.ai + board no Notion
  (database "App Carnê-Leão — Roadmap de Construção"). As sessões do Claude Code são
  **execução no repositório**. Use a skill `/proxima-tarefa` para consultar/atualizar o
  board (requer o conector Notion MCP habilitado na sessão).

## Decisões travadas (não reabrir, não "melhorar")
| Decisão | Valor |
|---|---|
| Flutter | **3.44.7 (stable)**, pinado via **FVM** (`.fvmrc` na raiz) |
| `applicationId` Android | **`com.desmalha.app`** |
| `minSdk` | **26** (Android 8.0) — exigido por SQLCipher, Keystore de hardware e custo do Argon2id |
| Estrutura | Monorepo: `apps/desmalha_app` (Flutter) + `packages/desmalha_core` (Dart puro) |
| CI/CD | **Codemagic** (runner macOS gratuito, 500 min/mês) — máquina de dev é Windows, sem Xcode local |
| Backend | Supabase (identidade/assinatura, catálogo só-leitura, backups E2E) |
| JDK | 17 |

## Convenções de tipos (fiscais) — invioláveis
- Dinheiro: **`INTEGER` de centavos**, sempre.
- Percentuais fiscais: **pontos-base** (`int`).
- Data civil: TEXT `'YYYY-MM-DD'`. Competência: `'YYYY-MM'`. Instante: epoch ms UTC.
- **Nenhum tipo de ponto flutuante para valores fiscais, em lugar nenhum, nunca.**
  `double` em código fiscal é motivo de refatoração imediata.

## Mapa de pastas
```
.fvmrc                     # pin do Flutter (3.44.7) — só o .fvmrc é versionado, .fvm/ não
codemagic.yaml             # CI: android-verify (push) + ios-simulator-nightly (cron/manual)
tool/setup_env.sh          # bootstrap idempotente de ambiente Linux (JDK, FVM, Android SDK)
apps/desmalha_app/         # o app Flutter (só orquestra e apresenta)
packages/desmalha_core/    # Dart puro: motor de cálculo, parser OFX, regras fiscais
.claude/skills/proxima-tarefa/  # skill de board do Notion
```
O `desmalha_core` existe para que motor de cálculo, parser OFX e regras fiscais sejam
Dart puro, testáveis com `dart test` sem emulador — a Fase 4 inteira acontece lá. O
motor de cálculo será validado contra 10 cenários oficiais table-driven em JSON
(especificação no Notion; entra na Fase 4).

## Ambiente & comandos
Sessão Linux efêmera nasce pronta com:
```
bash tool/setup_env.sh          # instala JDK 17, FVM, Flutter 3.44.7, Android SDK
source tool/env                 # exporta ANDROID_HOME etc. (gerado pelo script)
```
Build e testes (sempre via FVM):
```
cd apps/desmalha_app && fvm flutter analyze && fvm flutter test
cd packages/desmalha_core && dart test        # usa o Dart do SDK pinado (fvm dart test)
cd apps/desmalha_app && fvm flutter build apk --debug
```
Restrições de rede conhecidas em sessões de nuvem: se um download essencial falhar
(ex.: `dl.google.com` para o Android SDK), **pare e reporte exatamente qual domínio foi
bloqueado** — não contorne com mirrors não oficiais. O SDK Flutter pode ser obtido por
tarball oficial de `storage.googleapis.com` quando o clone git do FVM não for possível.

## Regras permanentes
1. **Segredos nunca entram no repositório nem em sessão de nuvem**: keystore, senhas,
   chaves de API, service accounts. Assinatura de release = Play App Signing + variáveis
   cifradas do Codemagic, configuradas pelo usuário na interface.
2. **Nenhum float para dinheiro ou percentual fiscal.** Centavos em `int`, pontos-base em
   `int`. Teste que encontrar `double` em código fiscal é motivo de refatoração imediata.
3. Toda lógica fiscal vai em `desmalha_core`, com testes. O app (`desmalha_app`) só
   orquestra e apresenta.
4. Versão do Flutter só muda por decisão explícita do usuário, registrada no board —
   nunca "de carona" num setup.
5. O board de tarefas e as decisões de arquitetura vivem no Notion e no projeto do
   Claude.ai. Ao final de cada sessão, **resuma o que foi feito e o que ficou pendente em
   um bloco final claro**, para o usuário levar de volta ao projeto de planejamento e
   fechar o card.
6. **Um escopo por sessão.** Se descobrir trabalho novo no meio do caminho, anote no
   resumo final como "candidato a card" em vez de executar.
