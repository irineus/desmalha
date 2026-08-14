# desmalha_core

Núcleo fiscal do Desmalha em Dart puro (sem Flutter): parser de extratos
OFX/CSV, motor de cálculo do carnê-leão e regras fiscais. Testável com
`dart test`, sem emulador.

Convenções invioláveis (ver `CLAUDE.md` na raiz do monorepo): dinheiro em
`int` de centavos, percentuais fiscais em pontos-base, datas civis como
`'YYYY-MM-DD'` — **nunca `double` em valor fiscal**.

## CLI de validação local de extratos

O parser precisa ser validado contra extratos reais **sem que o dado
sensível saia da máquina do usuário** (nem repositório, nem sessão de
nuvem, nem servidor — ADR local-first). Para isso existe o
`validar_extrato`: ele apenas **lê** o arquivo e imprime **só agregados**;
nada é gravado nem transmitido.

De dentro de `packages/desmalha_core` (Windows, PowerShell ou cmd):

```
cd packages\desmalha_core
fvm dart pub get
fvm dart run desmalha_core:validar_extrato C:\caminho\extrato.ofx
fvm dart run desmalha_core:validar_extrato C:\caminho\extrato.csv --perfil perfis\nubank-conta-csv-v1.json
```

O relatório traz: nº de transações, período coberto, soma de créditos e
débitos em centavos (confira contra o app do banco), encoding detectado,
banco/conta (mascarada)/moeda e a lista completa de avisos com linha.
Código de saída: `0` validado sem avisos, `1` com avisos, `2` erro.

**Critério de validação:** soma batendo com o app do banco e zero avisos
inesperados. O relatório é seguro para colar de volta na sessão de
planejamento — só os avisos podem citar trechos do arquivo; revise-os
antes.

### Perfis CSV

Arquivo OFX se autodescreve; CSV exige um perfil do banco
(`--perfil <arquivo.json>`). Perfis de referência em [`perfis/`](perfis/):
Nubank, Banco Inter e Banco do Brasil. Para um banco novo, copie um perfil
e ajuste delimitador, encoding, formato de data/valor e mapa de colunas —
esse JSON é o mesmo schema do futuro catálogo versionado servido pela API.

### Modo `--anonimizar`

```
fvm dart run desmalha_core:validar_extrato extrato.csv --perfil perfil.json --anonimizar
```

Gera `extrato.anonimizado.csv` (ou `--saida <arquivo>`): nomes e CPFs
fictícios, contas e identificadores trocados, valores perturbados em até
±15% — **preservando a estrutura** (delimitadores, formato de data,
encoding e BOM, aspas, quebras de linha, linhas de saldo). É o insumo
seguro para virar fixture de regressão no repositório e perfil de banco
novo. A anonimização é heurística e determinística: **revise o arquivo
gerado antes de compartilhar**.

## Layout

```
lib/desmalha_core.dart   # API usada pelo app (parsers, modelos, regras)
lib/validacao.dart       # ferramentas do CLI — o app NÃO importa isto
bin/validar_extrato.dart # o executável do CLI
perfis/                  # perfis CSV de referência (JSON)
test/                    # dart test — fixtures sempre sintéticas/anonimizadas
```

⚠ Extrato real é dado sensível: **nunca** commitar, colar em sessão de
nuvem ou anexar em card — só a versão anonimizada e revisada.
