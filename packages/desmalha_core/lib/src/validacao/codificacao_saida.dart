/// Codificação do arquivo anonimizado de volta aos bytes de origem.
///
/// A cópia anonimizada precisa sair no MESMO charset do arquivo original
/// (inclusive BOM), porque o charset faz parte da estrutura que a fixture
/// de regressão deve preservar.
library;

import 'dart:convert';

/// Codifica [texto] no [encoding] canônico (`utf-8`, `latin-1`,
/// `windows-1252`), prefixando BOM quando [comBom].
///
/// Caracteres impossíveis no charset de destino lançam [ArgumentError] —
/// só aconteceria por defeito do anonimizador, que substitui texto sempre
/// por ASCII.
List<int> codificarSaida(String texto, String encoding, {bool comBom = false}) {
  final bytes = switch (encoding) {
    'utf-8' => utf8.encode(texto),
    'latin-1' => latin1.encode(texto),
    'windows-1252' => _codificarCp1252(texto),
    _ => throw ArgumentError.value(encoding, 'encoding', 'charset não suportado'),
  };
  if (!comBom) return bytes;
  return [0xEF, 0xBB, 0xBF, ...bytes];
}

List<int> _codificarCp1252(String texto) {
  final bytes = <int>[];
  for (final ponto in texto.runes) {
    if (ponto <= 0x7F || (ponto >= 0xA0 && ponto <= 0xFF)) {
      bytes.add(ponto);
    } else {
      final byteAlto = _cp1252Reverso[ponto];
      if (byteAlto == null) {
        throw ArgumentError(
          'caractere U+${ponto.toRadixString(16).toUpperCase()} não existe '
          'em windows-1252',
        );
      }
      bytes.add(byteAlto);
    }
  }
  return bytes;
}

/// Inverso da faixa 0x80–0x9F usada em `decodificacao.dart` (a tabela lá é
/// privada de propósito; o app só decodifica, nunca codifica).
const Map<int, int> _cp1252Reverso = {
  0x20AC: 0x80, 0x0081: 0x81, 0x201A: 0x82, 0x0192: 0x83,
  0x201E: 0x84, 0x2026: 0x85, 0x2020: 0x86, 0x2021: 0x87,
  0x02C6: 0x88, 0x2030: 0x89, 0x0160: 0x8A, 0x2039: 0x8B,
  0x0152: 0x8C, 0x008D: 0x8D, 0x017D: 0x8E, 0x008F: 0x8F,
  0x0090: 0x90, 0x2018: 0x91, 0x2019: 0x92, 0x201C: 0x93,
  0x201D: 0x94, 0x2022: 0x95, 0x2013: 0x96, 0x2014: 0x97,
  0x02DC: 0x98, 0x2122: 0x99, 0x0161: 0x9A, 0x203A: 0x9B,
  0x0153: 0x9C, 0x009D: 0x9D, 0x017E: 0x9E, 0x0178: 0x9F,
};
