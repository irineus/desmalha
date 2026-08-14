/// Detecção de formato e de charset para o CLI de validação local.
///
/// A decodificação em si é a mesma do app ([decodificarExtrato]); aqui só
/// se acrescenta o diagnóstico de QUAL charset foi usado, porque o relatório
/// do CLI precisa informá-lo ao usuário.
library;

import 'dart:convert';

import '../extrato/decodificacao.dart';

/// Formato aparente do arquivo, decidido antes do parse.
enum FormatoDetectado { ofx, csv }

/// Texto decodificado junto do charset efetivamente usado.
class TextoDecodificado {
  const TextoDecodificado({
    required this.texto,
    required this.encoding,
    required this.comBom,
  });

  final String texto;

  /// Nome canônico do charset usado: `utf-8`, `windows-1252` ou `latin-1`.
  final String encoding;

  /// O arquivo começava com BOM UTF-8 (preservado na anonimização).
  final bool comBom;
}

/// Decodifica [bytes] reportando o charset usado.
///
/// Com [encoding] explícito, usa-o. Sem, aplica a mesma autodetecção de
/// [decodificarExtrato]: BOM → UTF-8; senão UTF-8 estrito; senão
/// Windows-1252.
TextoDecodificado decodificarComDiagnostico(
  List<int> bytes, {
  String? encoding,
}) {
  final comBom = bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF;

  if (encoding != null) {
    final nome = encoding.toLowerCase().replaceAll('_', '-');
    final canonico = switch (nome) {
      'utf-8' || 'utf8' => 'utf-8',
      'latin-1' || 'latin1' || 'iso-8859-1' => 'latin-1',
      'cp1252' || 'windows-1252' => 'windows-1252',
      _ => throw ArgumentError.value(
          encoding, 'encoding', 'charset não suportado'),
    };
    return TextoDecodificado(
      texto: decodificarExtrato(bytes, encoding: canonico),
      encoding: canonico,
      comBom: comBom,
    );
  }

  final dados = comBom ? bytes.sublist(3) : bytes;
  try {
    return TextoDecodificado(
      texto: utf8.decode(dados),
      encoding: 'utf-8',
      comBom: comBom,
    );
  } on FormatException {
    return TextoDecodificado(
      texto: decodificarExtrato(bytes, encoding: 'windows-1252'),
      encoding: 'windows-1252',
      comBom: comBom,
    );
  }
}

/// Decide entre OFX e CSV pelo conteúdo; a extensão do arquivo desempata.
FormatoDetectado detectarFormato(String texto, {String? nomeArquivo}) {
  if (RegExp('<OFX>', caseSensitive: false).hasMatch(texto) ||
      texto.contains('OFXHEADER')) {
    return FormatoDetectado.ofx;
  }
  if (nomeArquivo != null && nomeArquivo.toLowerCase().endsWith('.ofx')) {
    return FormatoDetectado.ofx;
  }
  return FormatoDetectado.csv;
}
