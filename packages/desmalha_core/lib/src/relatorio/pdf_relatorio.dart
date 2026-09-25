/// O relatório anual em PDF, gerado no aparelho e compartilhado pelo
/// sistema, como o do DARF (decisão 9 do owner).
///
/// Como a guia, o documento se identifica como PREPARADO PELO APP a partir
/// do que a pessoa registrou — é o papel que ela leva para a declaração ou
/// para o contador, não um documento da Receita Federal.
library;

import 'dart:typed_data';

import '../darf/pdf_minimo.dart';
import '../dinheiro.dart';
import 'relatorio_anual.dart';

const double _margem = 42;
const List<String> _meses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', //
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

/// Valor sem o prefixo "R$", para as colunas.
String _valor(int centavos) =>
    centavosParaExibicao(centavos).replaceFirst('R\$ ', '');

/// CNPJ `12345678000190` → `12.345.678/0001-90`.
String cnpjFormatado(String digitos) => digitos.length != 14
    ? digitos
    : '${digitos.substring(0, 2)}.${digitos.substring(2, 5)}.'
        '${digitos.substring(5, 8)}/${digitos.substring(8, 12)}-'
        '${digitos.substring(12)}';

/// Gera o PDF do [relatorio]. [aviso] entra antes do rodapé — o texto sobre
/// outras fontes de renda, que o app mantém fora do core.
Uint8List gerarPdfRelatorioAnual(RelatorioAnual relatorio, {String? aviso}) {
  final pdf = DocumentoPdf();
  final pagina = pdf.novaPagina();
  final direita = pagina.largura - _margem;
  var y = pagina.altura - 56;

  pagina.texto(
    'Relatório anual do carnê-leão — ${relatorio.ano}',
    x: _margem,
    y: y,
    tamanho: 16,
    negrito: true,
  );
  y -= 14;
  pagina.texto(
    'Rendimentos recebidos de pessoa física, mês a mês, para a declaração '
    'de ajuste anual. Valores em R\$.',
    x: _margem,
    y: y,
    tamanho: 8.5,
    cinza: 0.35,
  );

  // Colunas: mês + cinco valores alinhados à direita.
  const larguraMes = 88.0;
  final larguraValor = (direita - _margem - larguraMes) / 5;
  double colunaX(int i) => _margem + larguraMes + larguraValor * (i + 1) - 4;
  const titulos = [
    'Receitas',
    'Livro-caixa',
    'INSS',
    'Dependentes',
    'Imposto pago',
  ];

  y -= 26;
  pagina.texto('Mês', x: _margem, y: y, tamanho: 8.5, negrito: true);
  for (var i = 0; i < titulos.length; i++) {
    pagina.texto(
      titulos[i],
      x: colunaX(i),
      y: y,
      tamanho: 8.5,
      negrito: true,
      alinhamento: AlinhamentoTexto.direita,
    );
  }
  y -= 6;
  pagina.linha(x1: _margem, y1: y, x2: direita, y2: y);

  void linhaDeValores(String rotulo, List<int> valores, {bool negrito = false}) {
    y -= 15;
    pagina.texto(rotulo, x: _margem, y: y, tamanho: 9, negrito: negrito);
    for (var i = 0; i < valores.length; i++) {
      pagina.texto(
        _valor(valores[i]),
        x: colunaX(i),
        y: y,
        tamanho: 9,
        negrito: negrito,
        alinhamento: AlinhamentoTexto.direita,
      );
    }
  }

  for (final m in relatorio.meses) {
    linhaDeValores(_meses[int.parse(m.competencia.substring(5, 7)) - 1], [
      m.receitasCentavos,
      m.livroCaixaCentavos,
      m.inssCentavos,
      m.deducaoDependentesCentavos,
      m.impostoPagoCentavos,
    ]);
  }
  y -= 6;
  pagina.linha(x1: _margem, y1: y, x2: direita, y2: y, espessura: 1);
  linhaDeValores(
    'Total',
    [
      relatorio.totalReceitasCentavos,
      relatorio.totalLivroCaixaCentavos,
      relatorio.totalInssCentavos,
      relatorio.totalDependentesCentavos,
      relatorio.totalImpostoPagoCentavos,
    ],
    negrito: true,
  );

  y -= 30;
  pagina.texto(
    'Rendimentos recebidos de pessoa jurídica (sem IRRF)',
    x: _margem,
    y: y,
    tamanho: 10.5,
    negrito: true,
  );
  if (relatorio.fontesPj.isEmpty) {
    y -= 14;
    pagina.texto('Nenhum no ano.', x: _margem, y: y, tamanho: 9);
  } else {
    for (final f in relatorio.fontesPj) {
      y -= 14;
      pagina.texto(
        '${f.nome ?? 'Fonte sem nome'}'
        '${f.cnpj == null ? ' · CNPJ não informado' : ' · CNPJ ${cnpjFormatado(f.cnpj!)}'}',
        x: _margem,
        y: y,
        tamanho: 9,
      );
      pagina.texto(
        _valor(f.totalCentavos),
        x: direita - 4,
        y: y,
        tamanho: 9,
        alinhamento: AlinhamentoTexto.direita,
      );
    }
  }

  if (aviso != null) {
    y -= 26;
    for (final trecho in _quebrar(aviso, 110)) {
      pagina.texto(trecho, x: _margem, y: y, tamanho: 8.5, cinza: 0.2);
      y -= 11;
    }
  }

  pagina.texto(
    'Preparado pelo app Desmalha a partir do que você registrou. Não é '
    'documento da Receita Federal.',
    x: _margem,
    y: 40,
    tamanho: 7.5,
    cinza: 0.45,
  );
  return pdf.bytes();
}

/// Quebra [texto] em linhas de até [largura] caracteres, nas palavras.
List<String> _quebrar(String texto, int largura) {
  final linhas = <String>[];
  var atual = StringBuffer();
  for (final palavra in texto.split(' ')) {
    if (atual.isNotEmpty && atual.length + 1 + palavra.length > largura) {
      linhas.add(atual.toString());
      atual = StringBuffer();
    }
    if (atual.isNotEmpty) atual.write(' ');
    atual.write(palavra);
  }
  if (atual.isNotEmpty) linhas.add(atual.toString());
  return linhas;
}
