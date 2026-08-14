# Desmalha

Controle fiscal (carnê-leão) para autônomos brasileiros que recebem via Pix: importa
extrato OFX/CSV, classifica os Pix por remetente, calcula o imposto mensal, gera DARF
(código 0190) e prepara os consolidados para o e-CAC.

**Local-first**: todo dado fiscal vive no dispositivo (SQLite/Drift + SQLCipher); o
servidor só vê identidade, catálogo fiscal só-leitura e backups cifrados ponta-a-ponta.

## Estrutura

```
apps/desmalha_app/        # app Flutter (Android + iOS)
packages/desmalha_core/   # Dart puro: motor de cálculo, parser OFX, regras fiscais
tool/setup_env.sh         # bootstrap de ambiente Linux (JDK 17, FVM, Flutter, Android SDK)
codemagic.yaml            # CI/CD (Codemagic)
```

## Reconstruir o ambiente

```bash
bash tool/setup_env.sh   # idempotente; termina com `fvm flutter doctor`
source tool/env          # ANDROID_HOME / PATH para a sessão atual
```

Flutter **3.44.7** pinado via [FVM](https://fvm.app) (`.fvmrc`). JDK 17.

## Verificação rápida

```bash
cd packages/desmalha_core && dart test
cd apps/desmalha_app && fvm flutter analyze && fvm flutter test
cd apps/desmalha_app && fvm flutter build apk --debug
```

Contexto completo do projeto para sessões de agente: [`CLAUDE.md`](CLAUDE.md).
