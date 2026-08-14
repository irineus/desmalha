/// Decodificação de bytes de arquivos de extrato para `String`.
///
/// Bancos brasileiros emitem OFX/CSV em UTF-8, ISO-8859-1 (Latin-1) ou
/// Windows-1252 — muitas vezes declarando um e usando outro. A detecção
/// automática tenta UTF-8 estrito e cai para Windows-1252 (superconjunto
/// prático do Latin-1 nos arquivos reais).
library;

import 'dart:convert';

/// Decodifica os bytes de um extrato para texto.
///
/// [encoding] força um charset (`utf-8`, `latin-1`/`iso-8859-1`,
/// `cp1252`/`windows-1252`); `null` autodetecta: BOM UTF-8 → UTF-8;
/// senão tenta UTF-8 estrito e, se inválido, decodifica como Windows-1252.
String decodificarExtrato(List<int> bytes, {String? encoding}) {
  var dados = bytes;
  final temBom = dados.length >= 3 &&
      dados[0] == 0xEF &&
      dados[1] == 0xBB &&
      dados[2] == 0xBF;
  if (temBom) {
    dados = dados.sublist(3);
  }

  final nome = encoding?.toLowerCase().replaceAll('_', '-');
  switch (nome) {
    case null:
      if (temBom) return utf8.decode(dados);
      try {
        return utf8.decode(dados);
      } on FormatException {
        return _decodificarCp1252(dados);
      }
    case 'utf-8' || 'utf8':
      return utf8.decode(dados);
    case 'latin-1' || 'latin1' || 'iso-8859-1':
      return latin1.decode(dados);
    case 'cp1252' || 'windows-1252':
      return _decodificarCp1252(dados);
    default:
      throw ArgumentError.value(encoding, 'encoding', 'charset não suportado');
  }
}

/// Windows-1252: igual ao Latin-1, exceto a faixa 0x80–0x9F, que mapeia
/// para caracteres imprimíveis (€, “, ”, –, — etc.).
String _decodificarCp1252(List<int> bytes) {
  final buffer = StringBuffer();
  for (final byte in bytes) {
    if (byte >= 0x80 && byte <= 0x9F) {
      buffer.writeCharCode(_cp1252Altos[byte - 0x80]);
    } else {
      buffer.writeCharCode(byte);
    }
  }
  return buffer.toString();
}

/// Mapeamento da faixa 0x80–0x9F do Windows-1252 para pontos de código
/// Unicode. Posições sem caractere definido na tabela oficial preservam o
/// próprio byte, como fazem os navegadores.
const List<int> _cp1252Altos = [
  0x20AC, 0x0081, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, //
  0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0x008D, 0x017D, 0x008F, //
  0x0090, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014, //
  0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x009D, 0x017E, 0x0178, //
];
