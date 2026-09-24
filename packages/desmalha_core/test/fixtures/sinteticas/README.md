# Fixtures SINTÉTICAS de extrato OFX

> **Rótulo, antes de tudo:** estes arquivos foram GERADOS por
> [`gerador.dart`](gerador.dart), a partir do mesmo entendimento de OFX que o
> parser tem. Eles **não são extrato de banco nenhum.**

## O que elas provam

- Que o parser (`parseOfx` + `decodificarExtrato`) e o gerador **concordam**
  sobre cada eixo que o gerador varia: OFX 1.x SGML × 2.x XML; UTF-8, UTF-8
  com BOM, Latin-1 e Windows-1252 (inclusive cabeçalho que declara um charset
  e entrega outro); CRLF × LF; FITID em todos, em parte e em nenhum
  lançamento; DTPOSTED curto, com hora e com fuso; vírgula × ponto decimal;
  arquivo com e sem `<ORG>`; períodos de 1 a 92 dias; arquivo sem
  lançamentos; três Pix legítimos idênticos no mesmo dia.
- Que nenhuma regressão do parser quebra esse entendimento sem um teste
  vermelho.

## O que elas NÃO provam

- **Cobertura de banco real.** Um arquivo gerado a partir do entendimento do
  parser só demonstra que os dois concordam entre si. Os bancos daqui são
  fictícios de propósito (`SINTETICO-*`, BANKID `9xx`): nome de banco real
  nesta pasta seria afirmar uma cobertura que não existe.
- Nada sobre o que um banco real faz e o gerador não imagina: MEMO truncado em
  largura fixa com data colada, FITID que muda a cada exportação, tags fora de
  ordem, SGML malformado. Isso só entra com fixture de estrutura verdadeira.

## Por que existe um gerador, e não arquivos soltos

Em 16/ago/2026 o CLI de validação rodou contra 13 extratos: 12 sintéticos e 1
real (Itaú). Os 12 passaram com zero avisos, e isso não provava nada. Eles
foram desmascarados pela **uniformidade**: a conta de doze "bancos" terminava
em `678`, e todos eram UTF-8, com FITID em 100% e cerca de 30 dias. Esses
arquivos nunca chegaram ao repositório.

Este conjunto varia cada um desses eixos **de propósito**, e o teste
[`fixtures_sinteticas_test.dart`](../../extrato/fixtures_sinteticas_test.dart)
reprova se a variedade cair: contas repetindo o final, uma codificação
sumindo, todos os períodos perto de 30 dias, FITID só num dos três regimes.

## Regras

- **Não edite um `.ofx` à mão.** O teste compara byte a byte o disco com a
  saída do gerador. Arquivo editado deixa de ser do gerador e perde o rótulo.
  Para mudar, altere `especificacoes` em `gerador.dart` e regenere (a partir
  de `packages/desmalha_core`):

  ```
  fvm dart run test/fixtures/sinteticas/gerador.dart
  ```

- **Nenhum extrato real entra nesta pasta.** O teste reprova qualquer
  `.ofx`/`.csv` aqui que o gerador não produza. Fixture derivada de extrato
  real (ex.: a anonimização do Itaú, em revisão pelo dono do projeto) vai
  para um diretório próprio, com o seu próprio README dizendo de onde veio e
  o que foi anonimizado.
- O `.gitattributes` desta pasta marca os `.ofx` como binários: CRLF, BOM e
  codificação são o que se testa, e o `autocrlf` do Windows os reescreveria.
- `manifesto.json` resume o eixo de cada arquivo e também é gerado.
