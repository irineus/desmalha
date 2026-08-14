/// Modelos do resultado da importação de extrato bancário (OFX/CSV).
///
/// A importação nunca persiste nada: ela produz um [ExtratoImportado] que o
/// app apresenta como prévia. Problemas em lançamentos individuais viram
/// [AvisoImportacao] (o lançamento é pulado); só um arquivo irreconhecível
/// derruba a importação inteira com [ExtratoInvalidoException].
library;

/// Formato de origem de um extrato importado.
enum FormatoExtrato { ofx, csv }

/// Uma transação lida de um extrato, ainda não classificada nem persistida.
class TransacaoImportada {
  const TransacaoImportada({
    required this.data,
    required this.valorCentavos,
    required this.descricao,
    this.idExterno,
  });

  /// Data civil do lançamento, no formato `'YYYY-MM-DD'`.
  final String data;

  /// Valor em centavos: crédito positivo, débito negativo.
  final int valorCentavos;

  /// Descrição bruta vinda do extrato (MEMO/NAME no OFX, coluna no CSV).
  final String descricao;

  /// Identificador do lançamento no banco (FITID no OFX), quando existir.
  /// É a base da deduplicação entre importações repetidas do mesmo período.
  final String? idExterno;

  @override
  bool operator ==(Object other) =>
      other is TransacaoImportada &&
      other.data == data &&
      other.valorCentavos == valorCentavos &&
      other.descricao == descricao &&
      other.idExterno == idExterno;

  @override
  int get hashCode => Object.hash(data, valorCentavos, descricao, idExterno);

  @override
  String toString() =>
      'TransacaoImportada($data, $valorCentavos, "$descricao"'
      '${idExterno == null ? '' : ', id: $idExterno'})';
}

/// Problema não fatal encontrado durante a importação.
///
/// O lançamento que o causou é descartado, mas o restante do extrato segue —
/// o usuário vê o aviso na prévia e decide se importa mesmo assim.
class AvisoImportacao {
  const AvisoImportacao({required this.mensagem, this.linha});

  /// Linha (1-based) do arquivo de origem, quando fizer sentido (CSV).
  /// No OFX, a posição vem embutida na mensagem (ordinal da transação).
  final int? linha;

  final String mensagem;

  @override
  bool operator ==(Object other) =>
      other is AvisoImportacao &&
      other.linha == linha &&
      other.mensagem == mensagem;

  @override
  int get hashCode => Object.hash(linha, mensagem);

  @override
  String toString() =>
      'AvisoImportacao(${linha == null ? '' : 'linha $linha: '}$mensagem)';
}

/// Resultado completo de uma importação: transações válidas + avisos.
class ExtratoImportado {
  const ExtratoImportado({
    required this.formato,
    required this.transacoes,
    this.avisos = const [],
    this.banco,
    this.conta,
    this.moeda,
  });

  final FormatoExtrato formato;
  final List<TransacaoImportada> transacoes;
  final List<AvisoImportacao> avisos;

  /// Identificação do banco: ORG/BANKID no OFX, nome do perfil no CSV.
  final String? banco;

  /// Número da conta como veio no arquivo (ACCTID no OFX). Mascarar é
  /// responsabilidade da camada de apresentação.
  final String? conta;

  /// Moeda declarada no arquivo (CURDEF no OFX), ex.: `BRL`.
  final String? moeda;
}

/// O arquivo não é um extrato reconhecível no formato esperado.
class ExtratoInvalidoException implements Exception {
  const ExtratoInvalidoException(this.mensagem);

  final String mensagem;

  @override
  String toString() => 'ExtratoInvalidoException: $mensagem';
}
