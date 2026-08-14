/// Escritor de PDF mínimo, em Dart puro e sem dependências.
///
/// Cobre exatamente o que um documento de arrecadação precisa: texto nas duas
/// fontes base (Helvetica e Helvetica-Bold, que todo leitor de PDF tem),
/// retângulos preenchidos ou traçados e linhas. Nada de imagens, transparência
/// ou fontes embutidas.
///
/// Por que escrever em vez de usar um pacote: o `desmalha_core` é Dart puro e
/// hoje não tem nenhuma dependência de runtime. Uma guia de imposto é um
/// formulário de texto e retângulos — o custo de trazer uma árvore de
/// dependências (e o risco de ela crescer para dentro de um pacote que
/// manipula dado fiscal) não se justifica para isso.
///
/// A saída é determinística: mesmo conteúdo, mesmos bytes. Não há dicionário
/// `/Info` nem `/CreationDate` de propósito — data de geração dentro do
/// arquivo tornaria o PDF impossível de testar por comparação e vazaria
/// horário de uso do app para dentro de um documento que o usuário
/// compartilha com terceiros.
library;

import 'dart:convert';
import 'dart:typed_data';

/// Alinhamento horizontal do texto em relação à coordenada `x`.
enum AlinhamentoTexto {
  /// `x` é a borda esquerda do texto.
  esquerda,

  /// `x` é o centro do texto.
  centro,

  /// `x` é a borda direita do texto.
  direita,
}

/// Uma página em construção.
///
/// O sistema de coordenadas é o do PDF: origem no canto INFERIOR esquerdo,
/// `y` crescendo para cima, unidade em pontos (1/72 de polegada).
class PaginaPdf {
  PaginaPdf._({required this.largura, required this.altura});

  /// Largura da página em pontos.
  final double largura;

  /// Altura da página em pontos.
  final double altura;

  final StringBuffer _conteudo = StringBuffer();

  /// Escreve [texto] com a base da linha em [y].
  void texto(
    String texto, {
    required double x,
    required double y,
    double tamanho = 9,
    bool negrito = false,
    AlinhamentoTexto alinhamento = AlinhamentoTexto.esquerda,
    double cinza = 0,
  }) {
    if (texto.isEmpty) return;
    final deslocamento = switch (alinhamento) {
      AlinhamentoTexto.esquerda => 0.0,
      AlinhamentoTexto.centro => -larguraTexto(texto, tamanho, negrito) / 2,
      AlinhamentoTexto.direita => -larguraTexto(texto, tamanho, negrito),
    };
    _conteudo
      ..write('BT ')
      ..write(_numero(cinza))
      ..write(' g /')
      ..write(negrito ? 'F2' : 'F1')
      ..write(' ')
      ..write(_numero(tamanho))
      ..write(' Tf ')
      ..write(_numero(x + deslocamento))
      ..write(' ')
      ..write(_numero(y))
      ..write(' Td (')
      ..write(_escapar(texto))
      ..write(') Tj ET\n');
  }

  /// Retângulo com canto inferior esquerdo em ([x], [y]).
  ///
  /// Preenchido quando [preenchido] é `true`; traçado caso contrário.
  void retangulo({
    required double x,
    required double y,
    required double largura,
    required double altura,
    bool preenchido = true,
    double cinza = 0,
    double espessura = 0.5,
  }) {
    _conteudo
      ..write(_numero(cinza))
      ..write(preenchido ? ' g ' : ' G ')
      ..write(_numero(espessura))
      ..write(' w ')
      ..write(_numero(x))
      ..write(' ')
      ..write(_numero(y))
      ..write(' ')
      ..write(_numero(largura))
      ..write(' ')
      ..write(_numero(altura))
      ..write(preenchido ? ' re f\n' : ' re S\n');
  }

  /// Segmento de reta de ([x1], [y1]) a ([x2], [y2]).
  void linha({
    required double x1,
    required double y1,
    required double x2,
    required double y2,
    double espessura = 0.5,
    double cinza = 0,
  }) {
    _conteudo
      ..write(_numero(cinza))
      ..write(' G ')
      ..write(_numero(espessura))
      ..write(' w ')
      ..write(_numero(x1))
      ..write(' ')
      ..write(_numero(y1))
      ..write(' m ')
      ..write(_numero(x2))
      ..write(' ')
      ..write(_numero(y2))
      ..write(' l S\n');
  }
}

/// Documento PDF de uma ou mais páginas.
class DocumentoPdf {
  final List<PaginaPdf> _paginas = [];

  /// Cria uma página. O default é A4 retrato.
  PaginaPdf novaPagina({double largura = 595.28, double altura = 841.89}) {
    final pagina = PaginaPdf._(largura: largura, altura: altura);
    _paginas.add(pagina);
    return pagina;
  }

  /// Serializa o documento.
  ///
  /// Lança [StateError] se não houver nenhuma página — um PDF sem páginas não
  /// abre em leitor nenhum.
  Uint8List bytes() {
    if (_paginas.isEmpty) {
      throw StateError('documento PDF sem páginas');
    }

    // Objetos: 1 catálogo, 2 árvore de páginas, 3 e 4 as fontes, e a partir
    // de 5 cada página com seu stream de conteúdo (dois objetos por página).
    const objetoCatalogo = 1;
    const objetoPaginas = 2;
    const objetoFonteNormal = 3;
    const objetoFonteNegrito = 4;
    const primeiroObjetoPagina = 5;

    final corpo = <String>[];
    final idsPaginas = <int>[];
    for (var i = 0; i < _paginas.length; i++) {
      idsPaginas.add(primeiroObjetoPagina + i * 2);
    }

    corpo.add(
      '<< /Type /Catalog /Pages $objetoPaginas 0 R >>',
    );
    corpo.add(
      '<< /Type /Pages /Kids [${idsPaginas.map((id) => '$id 0 R').join(' ')}] '
      '/Count ${_paginas.length} >>',
    );
    corpo.add(
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica '
      '/Encoding /WinAnsiEncoding >>',
    );
    corpo.add(
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold '
      '/Encoding /WinAnsiEncoding >>',
    );

    for (var i = 0; i < _paginas.length; i++) {
      final pagina = _paginas[i];
      final idConteudo = idsPaginas[i] + 1;
      corpo.add(
        '<< /Type /Page /Parent $objetoPaginas 0 R '
        '/MediaBox [0 0 ${_numero(pagina.largura)} ${_numero(pagina.altura)}] '
        '/Resources << /Font << /F1 $objetoFonteNormal 0 R '
        '/F2 $objetoFonteNegrito 0 R >> >> '
        '/Contents $idConteudo 0 R >>',
      );
      corpo.add(_stream(pagina._conteudo.toString()));
    }

    final saida = BytesBuilder();
    saida.add(latin1.encode('%PDF-1.4\n'));
    // Comentário binário: marca o arquivo como não-texto para ferramentas de
    // transporte que poderiam converter fins de linha.
    saida.add(<int>[0x25, 0xC3, 0xA4, 0xC3, 0xBC, 0x0A]);

    final offsets = <int>[];
    for (var i = 0; i < corpo.length; i++) {
      offsets.add(saida.length);
      saida.add(latin1.encode('${i + 1} 0 obj\n${corpo[i]}\nendobj\n'));
    }

    final inicioXref = saida.length;
    final total = corpo.length + 1;
    final xref = StringBuffer('xref\n0 $total\n0000000000 65535 f \n');
    for (final offset in offsets) {
      xref.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
    }
    saida.add(latin1.encode(xref.toString()));
    saida.add(
      latin1.encode(
        'trailer\n<< /Size $total /Root $objetoCatalogo 0 R >>\n'
        'startxref\n$inicioXref\n%%EOF\n',
      ),
    );

    return saida.toBytes();
  }

  static String _stream(String conteudo) {
    final bytes = latin1.encode(conteudo).length;
    return '<< /Length $bytes >>\nstream\n${conteudo}endstream';
  }
}

/// Largura de [texto] em pontos, na fonte e no [tamanho] dados.
///
/// Usa as métricas oficiais das fontes base do PDF (unidades de 1/1000 do
/// tamanho), o que permite centralizar e alinhar à direita com precisão.
double larguraTexto(String texto, double tamanho, bool negrito) {
  final metricas = negrito ? _larguraHelveticaBold : _larguraHelvetica;
  var milesimos = 0;
  for (var i = 0; i < texto.length; i++) {
    final codigo = texto.codeUnitAt(i);
    milesimos += codigo >= 32 && codigo <= 126
        ? metricas[codigo - 32]
        : _larguraPadraoAcentuado;
  }
  return milesimos * tamanho / 1000;
}

/// Largura assumida para acentuados e demais caracteres fora do ASCII
/// imprimível. Em Helvetica, as vogais acentuadas têm a largura da vogal base.
const int _larguraPadraoAcentuado = 556;

/// Métricas oficiais de Helvetica para os códigos 32 a 126.
const List<int> _larguraHelvetica = [
  278, 278, 355, 556, 556, 889, 667, 191, 333, 333, 389, 584, 278, 333, 278,
  278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584,
  584, 556, 1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556,
  833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278,
  278, 278, 469, 556, 333, 556, 556, 500, 556, 556, 278, 556, 556, 222, 222,
  500, 222, 833, 556, 556, 556, 556, 333, 500, 278, 556, 500, 722, 500, 500,
  500, 334, 260, 334, 584,
];

/// Métricas oficiais de Helvetica-Bold para os códigos 32 a 126.
const List<int> _larguraHelveticaBold = [
  278, 333, 474, 556, 556, 889, 722, 238, 333, 333, 389, 584, 278, 333, 278,
  278, 556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 333, 333, 584, 584,
  584, 611, 975, 722, 722, 722, 722, 667, 611, 778, 722, 278, 556, 722, 611,
  833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 333,
  278, 333, 584, 556, 333, 556, 611, 556, 611, 556, 333, 611, 611, 278, 278,
  556, 278, 889, 611, 611, 611, 611, 389, 556, 333, 611, 556, 778, 556, 556,
  500, 389, 280, 389, 584,
];

/// Formata um número para o conteúdo do PDF: até duas casas, sem zeros à
/// direita inúteis e sem notação científica.
String _numero(double valor) {
  final arredondado = (valor * 100).round() / 100;
  if (arredondado == arredondado.roundToDouble()) {
    return arredondado.toInt().toString();
  }
  return arredondado.toStringAsFixed(2);
}

/// Pontuação tipográfica que o Unicode põe acima de 0xFF mas o WinAnsi tem
/// na faixa 0x80–0x9F. Sem esta tabela, o travessão dos textos do app sai
/// como `?` no documento impresso.
const Map<int, int> _winAnsiAcima255 = {
  0x20AC: 0x80, // €
  0x201A: 0x82, // ‚
  0x0192: 0x83, // ƒ
  0x201E: 0x84, // „
  0x2026: 0x85, // …
  0x2020: 0x86, // †
  0x2021: 0x87, // ‡
  0x02C6: 0x88, // ˆ
  0x2030: 0x89, // ‰
  0x0160: 0x8A, // Š
  0x2039: 0x8B, // ‹
  0x0152: 0x8C, // Œ
  0x017D: 0x8E, // Ž
  0x2018: 0x91, // '
  0x2019: 0x92, // '
  0x201C: 0x93, // "
  0x201D: 0x94, // "
  0x2022: 0x95, // •
  0x2013: 0x96, // –
  0x2014: 0x97, // —
  0x02DC: 0x98, // ˜
  0x2122: 0x99, // ™
  0x0161: 0x9A, // š
  0x203A: 0x9B, // ›
  0x0153: 0x9C, // œ
  0x017E: 0x9E, // ž
  0x0178: 0x9F, // Ÿ
};

/// Escapa e transcodifica para WinAnsi. Caracteres fora do repertório viram
/// `?` — melhor uma interrogação visível do que um PDF que não abre.
String _escapar(String texto) {
  final buffer = StringBuffer();
  for (var i = 0; i < texto.length; i++) {
    final codigo = texto.codeUnitAt(i);
    switch (codigo) {
      case 0x28:
        buffer.write(r'\(');
      case 0x29:
        buffer.write(r'\)');
      case 0x5C:
        buffer.write(r'\\');
      default:
        final winAnsi = _winAnsiAcima255[codigo];
        if (winAnsi != null) {
          buffer.writeCharCode(winAnsi);
        } else {
          buffer.write(codigo <= 0xFF ? texto[i] : '?');
        }
    }
  }
  return buffer.toString();
}
