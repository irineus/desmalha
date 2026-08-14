/// Relatório agregado de um extrato importado, para o CLI de validação.
///
/// O relatório carrega SÓ agregados e metadados — nunca o conteúdo das
/// transações. É o que o usuário pode colar de volta na sessão de
/// planejamento sem expor dado sensível. Exceção consciente: os avisos do
/// parser citam trechos da linha problemática (é o que permite depurar);
/// o CLI avisa o usuário de revisá-los antes de compartilhar.
library;

import '../extrato/transacao_importada.dart';
import 'formatacao.dart';

/// Agregados de um [ExtratoImportado] + diagnóstico de decodificação.
class RelatorioExtrato {
  const RelatorioExtrato({
    required this.formato,
    required this.encoding,
    required this.totalTransacoes,
    required this.quantidadeCreditos,
    required this.somaCreditosCentavos,
    required this.quantidadeDebitos,
    required this.somaDebitosCentavos,
    required this.comIdExterno,
    required this.avisos,
    this.banco,
    this.contaMascarada,
    this.moeda,
    this.dataInicial,
    this.dataFinal,
  });

  /// Constrói o relatório a partir do resultado do parser.
  factory RelatorioExtrato.doExtrato(
    ExtratoImportado extrato, {
    required String encoding,
  }) {
    var quantidadeCreditos = 0;
    var somaCreditos = 0;
    var quantidadeDebitos = 0;
    var somaDebitos = 0;
    var comIdExterno = 0;
    String? dataInicial;
    String? dataFinal;

    for (final transacao in extrato.transacoes) {
      if (transacao.valorCentavos >= 0) {
        quantidadeCreditos++;
        somaCreditos += transacao.valorCentavos;
      } else {
        quantidadeDebitos++;
        somaDebitos += transacao.valorCentavos;
      }
      if (transacao.idExterno != null) comIdExterno++;
      // Data civil ISO ordena lexicograficamente.
      if (dataInicial == null || transacao.data.compareTo(dataInicial) < 0) {
        dataInicial = transacao.data;
      }
      if (dataFinal == null || transacao.data.compareTo(dataFinal) > 0) {
        dataFinal = transacao.data;
      }
    }

    return RelatorioExtrato(
      formato: extrato.formato,
      encoding: encoding,
      totalTransacoes: extrato.transacoes.length,
      quantidadeCreditos: quantidadeCreditos,
      somaCreditosCentavos: somaCreditos,
      quantidadeDebitos: quantidadeDebitos,
      somaDebitosCentavos: somaDebitos,
      comIdExterno: comIdExterno,
      avisos: extrato.avisos,
      banco: extrato.banco,
      contaMascarada: mascararConta(extrato.conta),
      moeda: extrato.moeda,
      dataInicial: dataInicial,
      dataFinal: dataFinal,
    );
  }

  final FormatoExtrato formato;
  final String encoding;
  final int totalTransacoes;
  final int quantidadeCreditos;

  /// Soma dos créditos em centavos (≥ 0).
  final int somaCreditosCentavos;
  final int quantidadeDebitos;

  /// Soma dos débitos em centavos (≤ 0, como vieram do parser).
  final int somaDebitosCentavos;
  final int comIdExterno;
  final List<AvisoImportacao> avisos;
  final String? banco;

  /// Conta com só os últimos dígitos visíveis — o relatório pode ser colado
  /// em sessão de planejamento sem expor o número completo.
  final String? contaMascarada;
  final String? moeda;
  final String? dataInicial;
  final String? dataFinal;

  int get liquidoCentavos => somaCreditosCentavos + somaDebitosCentavos;
  int get semIdExterno => totalTransacoes - comIdExterno;

  /// Relatório em texto para o terminal.
  String render() {
    final linhas = <String>[
      'Formato:            ${formato.name.toUpperCase()}',
      'Encoding detectado: $encoding',
      if (banco != null) 'Banco:              $banco',
      if (contaMascarada != null) 'Conta:              $contaMascarada',
      if (moeda != null) 'Moeda:              $moeda',
      '',
      'Transações:         $totalTransacoes '
          '($comIdExterno com id externo, $semIdExterno sem)',
      if (dataInicial != null)
        'Período:            $dataInicial a $dataFinal',
      'Créditos:           $quantidadeCreditos lançamento(s), '
          '${formatarCentavos(somaCreditosCentavos)} '
          '($somaCreditosCentavos centavos)',
      'Débitos:            $quantidadeDebitos lançamento(s), '
          '${formatarCentavos(somaDebitosCentavos)} '
          '($somaDebitosCentavos centavos)',
      'Líquido:            ${formatarCentavos(liquidoCentavos)} '
          '($liquidoCentavos centavos)',
      '',
    ];

    if (avisos.isEmpty) {
      linhas.add('Avisos:             nenhum ✓');
    } else {
      linhas.add('Avisos (${avisos.length}) — podem citar trechos do '
          'arquivo; revise antes de compartilhar:');
      for (final aviso in avisos) {
        final prefixo = aviso.linha == null ? '' : 'linha ${aviso.linha}: ';
        linhas.add('  • $prefixo${aviso.mensagem}');
      }
    }

    return linhas.join('\n');
  }
}

/// Mascara o número da conta, mantendo só os 3 últimos caracteres.
String? mascararConta(String? conta) {
  if (conta == null || conta.isEmpty) return conta;
  if (conta.length <= 3) return '•' * conta.length;
  return '${'•' * (conta.length - 3)}${conta.substring(conta.length - 3)}';
}
