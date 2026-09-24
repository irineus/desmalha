/// Do arquivo escolhido pelo usuário ao [ExtratoImportado]: decide o
/// formato, decodifica e chama o parser certo. Tudo no aparelho — o arquivo
/// não sai dele.
///
/// O formato vem do CONTEÚDO, não só da extensão: banco que exporta OFX com
/// extensão `.txt` (ou CSV com `.ofx`) existe, e a extensão sozinha mandaria
/// o arquivo para o parser errado. Extensão e conteúdo divergindo não é
/// erro — o conteúdo manda.
library;

import 'csv_parser.dart';
import 'decodificacao.dart';
import 'ofx_parser.dart';
import 'perfil_csv.dart';
import 'transacao_importada.dart';

/// Formato do arquivo pelos primeiros bytes: OFX tem cabeçalho SGML
/// (`OFXHEADER:`) ou a raiz `<OFX>`/`<?OFX` (XML). O resto é tratado como
/// CSV, que precisa de um perfil de banco para ser lido.
FormatoExtrato detectarFormatoExtrato(List<int> bytes) {
  final inicio = decodificarExtrato(
    bytes.length > 4096 ? bytes.sublist(0, 4096) : bytes,
  ).toUpperCase();
  if (inicio.contains('OFXHEADER') ||
      inicio.contains('<OFX>') ||
      inicio.contains('<?OFX')) {
    return FormatoExtrato.ofx;
  }
  return FormatoExtrato.csv;
}

/// Lê o arquivo inteiro. CSV exige [perfil] (o banco que exportou); OFX o
/// dispensa. Arquivo ilegível sobe [ExtratoInvalidoException].
ExtratoImportado lerArquivoDeExtrato(List<int> bytes, {PerfilCsv? perfil}) {
  if (bytes.isEmpty) {
    throw const ExtratoInvalidoException('arquivo vazio');
  }
  switch (detectarFormatoExtrato(bytes)) {
    case FormatoExtrato.ofx:
      return parseOfx(decodificarExtrato(bytes));
    case FormatoExtrato.csv:
      if (perfil == null) {
        throw ArgumentError.notNull('perfil');
      }
      return parseCsv(
        decodificarExtrato(bytes, encoding: perfil.encoding),
        perfil,
      );
  }
}

/// Primeira e última data civil do extrato, ou `null` sem lançamentos.
(String, String)? periodoDoExtrato(ExtratoImportado extrato) {
  if (extrato.transacoes.isEmpty) return null;
  var inicio = extrato.transacoes.first.data;
  var fim = inicio;
  for (final t in extrato.transacoes) {
    if (t.data.compareTo(inicio) < 0) inicio = t.data;
    if (t.data.compareTo(fim) > 0) fim = t.data;
  }
  return (inicio, fim);
}
