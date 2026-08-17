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
encoding e BOM, aspas, quebras de linha, agrupamento de milhar, linhas de
saldo). É o insumo seguro para virar fixture de regressão no repositório e
perfil de banco novo. A anonimização é heurística e determinística:
**revise o arquivo gerado antes de compartilhar**.

### Banco que ainda não tem perfil

```
fvm dart run desmalha_core:validar_extrato extrato.csv --anonimizar
```

Sem `--perfil`, o CSV só é aceito para anonimizar — sem perfil não há como
ler as colunas, e o relatório não sai. O que sai é a cópia anonimizada mais
a **estrutura inferida** (encoding, delimitador, nº de colunas, nº de
lançamentos), que é o insumo para escrever o perfil que falta.

Não empreste o perfil de outro banco para anonimizar: com as colunas
trocadas, a descrição cai no tratamento conservador, que remove CPF e
dígitos longos mas **não remove nomes** — o extrato real vazaria nomes de
clientes para dentro da fixture.

Sem perfil, a data é a única estrutura reconhecível, e é ela que decide o
tratamento de cada linha:

- **linha com data** (lançamento) — data preservada, valor perturbado, todo
  o resto tratado como texto livre (CPFs, dígitos longos e nomes);
- **linha sem data** (cabeçalho, preâmbulo, rodapé) — tratamento
  conservador, para que os rótulos de coluna cheguem legíveis a quem vai
  escrever o perfil. ⚠️ Conservador **não remove nomes**: preâmbulo com nome
  do titular sobrevive de propósito. O CLI informa quantas linhas caíram
  nesse tratamento — **revise-as à mão**.

## Motor de apuração do carnê-leão

Implementa a especificação fechada com o contador (rodada 3, ago/2026):

- **Dois cenários por mês** — deduções reais (livro-caixa + INSS +
  dependentes) × desconto simplificado — aplicando o mais vantajoso e
  gravando ambos na apuração.
- **Redutor da Lei 15.270/2025** sobre o imposto (nunca sobre a base),
  com gatilho no rendimento bruto do mês e piso zero.
- **Saldo negativo do livro-caixa** encadeado no ano-calendário
  (sobrevive aos meses em que o simplificado vence; zera em 31/12).
- **DARF mínimo de R$ 10,00** com acumulação entre competências (uma guia
  pode cobrir vários meses); resíduo de dezembro vai para a DIRPF.
- **Vencimento do DARF** no último dia útil do mês seguinte, antecipando
  fim de semana e feriado bancário (tabela de feriados versionada).
- Tabela do IRPF **versionada por competência** (`TabelaIrpf.fromJson`,
  mesmo schema do futuro catálogo servido pela API) — nunca hardcoded.

Aritmética inteira exata: centavos em `int`, alíquotas em pontos-base,
intermediários em micro-centavos; o ajuste à segunda casa acontece uma
única vez, no imposto final (truncamento por padrão, modo configurável
enquanto a contraprova empírica no Carnê-Leão Web não sai).

Os cenários de aceitação são table-driven em
`cenarios/cenarios_carne_leao.json`; os marcados `oficial: true` fecham
contra o Carnê-Leão Web na Fase 7.

## Geração do DARF (código de receita 0190)

`DocumentoDarf.daApuracao` monta a guia a partir de uma `ApuracaoMensal`:
período de apuração, vencimento, contribuinte e valor. `darfsDaSequencia`
resolve o N:1 do DARF mínimo — a guia registra em
`competenciasAbrangidas` os meses que ficaram abaixo de R$ 10,00 e foram
absorvidos por ela. `gerarPdfDarf` produz o PDF (o compartilhamento
nativo é da tela de DARF, na Fase 5).

**Código de barras.** O padrão FEBRABAN de arrecadação está implementado
por inteiro e testado — 44 dígitos, DV geral por módulo 10 ou 11 conforme
o identificador de valor, linha digitável de 48 dígitos e simbologia ITF.
O que **não** está aqui é como a Receita Federal preenche os 25 dígitos do
campo livre: isso é especificação da RFB, chega pelo catálogo versionado
como `LayoutCodigoBarrasDarf` e só é usado quando o campo
`conferido_contra_documento_real` for verdadeiro.

⚠ Enquanto não houver layout conferido contra um DARF real emitido pelo
Sicalc/e-CAC, a guia sai **sem** código de barras e direciona ao e-CAC.
Um código de barras adivinhado não falha: ele é lido pelo banco e paga a
receita errada em silêncio. Mesma postura do `PRAGMA cipher_version`.

## Layout

```
lib/desmalha_core.dart   # API usada pelo app (parsers, modelos, regras)
lib/validacao.dart       # ferramentas do CLI — o app NÃO importa isto
bin/validar_extrato.dart # o executável do CLI
perfis/                  # perfis CSV de referência (JSON)
cenarios/                # cenários table-driven do motor de cálculo (JSON)
test/                    # dart test — fixtures sempre sintéticas/anonimizadas
```

⚠ Extrato real é dado sensível: **nunca** commitar, colar em sessão de
nuvem ou anexar em card — só a versão anonimizada e revisada.
