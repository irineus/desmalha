/// Renderização do DARF em PDF.
///
/// O par desta função na Fase 5 é a tela de DARF, que faz o compartilhamento
/// nativo: aqui só se produzem os bytes. O público do app resolve isso hoje
/// com print de tela; um PDF é o que o contador consegue arquivar.
///
/// O documento se identifica como guia PREPARADA PELO APP, não como emissão
/// oficial da Receita Federal. Isso não é excesso de cautela: o posicionamento
/// do produto é controle gerencial e preparação para o e-CAC, e um papel que
/// se passa por documento oficial da RFB seria uma promessa de conformidade
/// que o app não faz.
library;

import 'dart:typed_data';

import '../dinheiro.dart';
import 'documento_darf.dart';
import 'itf.dart';
import 'pdf_minimo.dart';

/// Margem lateral da página, em pontos.
const double _margem = 42;

/// Gera o PDF de uma página com a guia [documento].
///
/// [observacao] entra no rodapé, para o app acrescentar contexto (ex.: aviso
/// de guia vencida direcionando ao SicalcWeb).
Uint8List gerarPdfDarf(DocumentoDarf documento, {String? observacao}) {
  final pdf = DocumentoPdf();
  final pagina = pdf.novaPagina();
  final larguraUtil = pagina.largura - _margem * 2;
  var y = pagina.altura - 56;

  pagina.texto(
    'DARF',
    x: _margem,
    y: y,
    tamanho: 20,
    negrito: true,
  );
  pagina.texto(
    'Documento de Arrecadação de Receitas Federais',
    x: _margem + 62,
    y: y + 1,
    tamanho: 10.5,
  );
  y -= 15;
  pagina.texto(
    'Carnê-leão — imposto de renda de pessoa física',
    x: _margem,
    y: y,
    tamanho: 9,
    cinza: 0.35,
  );

  y -= 12;
  pagina.linha(
    x1: _margem,
    y1: y,
    x2: _margem + larguraUtil,
    y2: y,
    espessura: 1,
  );

  // --- Campos da guia, na numeração do formulário ---
  y -= 8;
  const alturaCampo = 34.0;
  final meia = larguraUtil / 2;
  final terco = larguraUtil / 3;

  y -= alturaCampo;
  _campo(
    pagina,
    numero: '01',
    rotulo: 'Nome',
    valor: documento.contribuinte.nome,
    x: _margem,
    y: y,
    largura: documento.contribuinte.telefone == null ? larguraUtil : meia,
    altura: alturaCampo,
  );
  if (documento.contribuinte.telefone != null) {
    _campo(
      pagina,
      numero: '',
      rotulo: 'Telefone',
      valor: documento.contribuinte.telefone!,
      x: _margem + meia,
      y: y,
      largura: meia,
      altura: alturaCampo,
    );
  }

  y -= alturaCampo;
  _campo(
    pagina,
    numero: '02',
    rotulo: 'Período de apuração',
    valor: _dataBr(documento.periodoApuracao),
    x: _margem,
    y: y,
    largura: terco,
    altura: alturaCampo,
  );
  _campo(
    pagina,
    numero: '03',
    rotulo: 'Número do CPF',
    valor: documento.contribuinte.cpfFormatado,
    x: _margem + terco,
    y: y,
    largura: terco,
    altura: alturaCampo,
  );
  _campo(
    pagina,
    numero: '04',
    rotulo: 'Código da receita',
    valor: documento.codigoReceita,
    x: _margem + terco * 2,
    y: y,
    largura: terco,
    altura: alturaCampo,
    destaque: true,
  );

  y -= alturaCampo;
  _campo(
    pagina,
    numero: '05',
    rotulo: 'Número de referência',
    valor: documento.numeroReferencia ?? '—',
    x: _margem,
    y: y,
    largura: meia,
    altura: alturaCampo,
  );
  _campo(
    pagina,
    numero: '06',
    rotulo: 'Data de vencimento',
    valor: _dataBr(documento.dataVencimento),
    x: _margem + meia,
    y: y,
    largura: meia,
    altura: alturaCampo,
    destaque: true,
  );

  const valores = [
    ('07', 'Valor do principal'),
    ('08', 'Valor da multa'),
    ('09', 'Juros / encargos'),
  ];
  final montantes = [
    documento.valorPrincipalCentavos,
    documento.multaCentavos,
    documento.jurosCentavos,
  ];
  y -= alturaCampo;
  for (var i = 0; i < valores.length; i++) {
    _campo(
      pagina,
      numero: valores[i].$1,
      rotulo: valores[i].$2,
      valor: centavosParaExibicao(montantes[i]),
      x: _margem + terco * i,
      y: y,
      largura: terco,
      altura: alturaCampo,
      alinhamentoValor: AlinhamentoTexto.direita,
    );
  }

  y -= alturaCampo + 4;
  _campo(
    pagina,
    numero: '10',
    rotulo: 'Valor total a recolher',
    valor: centavosParaExibicao(documento.valorTotalCentavos),
    x: _margem,
    y: y,
    largura: larguraUtil,
    altura: alturaCampo + 4,
    alinhamentoValor: AlinhamentoTexto.direita,
    destaque: true,
    tamanhoValor: 15,
  );

  // --- Pagamento ---
  y -= 34;
  final codigoBarras = documento.codigoBarras;
  if (codigoBarras != null) {
    pagina.texto(
      'Pagamento',
      x: _margem,
      y: y,
      tamanho: 9,
      negrito: true,
      cinza: 0.35,
    );
    y -= 44;
    _desenharCodigoBarras(
      pagina,
      digitos: codigoBarras.digitos,
      x: _margem,
      y: y,
      larguraDisponivel: larguraUtil,
      altura: 40,
    );
    y -= 16;
    pagina.texto(
      codigoBarras.linhaDigitavelFormatada,
      x: _margem + larguraUtil / 2,
      y: y,
      tamanho: 10,
      negrito: true,
      alinhamento: AlinhamentoTexto.centro,
    );
  } else {
    y -= 6;
    final alturaAviso = 58.0;
    pagina.retangulo(
      x: _margem,
      y: y - alturaAviso + 12,
      largura: larguraUtil,
      altura: alturaAviso,
      preenchido: false,
      cinza: 0.55,
    );
    pagina.texto(
      'Guia sem código de barras',
      x: _margem + 10,
      y: y,
      tamanho: 9.5,
      negrito: true,
    );
    y -= 14;
    for (final linha in const [
      'Pague informando os dados acima no e-CAC ou no aplicativo do seu banco,',
      'em "Pagamento de tributos federais". Confira o código da receita (0190)',
      'e o período de apuração antes de confirmar.',
    ]) {
      pagina.texto(linha, x: _margem + 10, y: y, tamanho: 8.5, cinza: 0.2);
      y -= 11;
    }
    y -= 6;
  }

  // --- Rodapé ---
  y -= 30;
  pagina.linha(
    x1: _margem,
    y1: y,
    x2: _margem + larguraUtil,
    y2: y,
    espessura: 0.5,
    cinza: 0.6,
  );
  y -= 14;

  if (documento.competenciasAbrangidas.length > 1) {
    final meses =
        documento.competenciasAbrangidas.map(_competenciaBr).join(', ');
    pagina.texto(
      'Esta guia quita as competências $meses. Os meses anteriores ficaram '
      'abaixo do valor mínimo de DARF',
      x: _margem,
      y: y,
      tamanho: 8,
      cinza: 0.25,
    );
    y -= 10;
    pagina.texto(
      'e foram somados ao mês de referência, sem multa nem juros '
      '(Lei 9.430/1996, art. 68).',
      x: _margem,
      y: y,
      tamanho: 8,
      cinza: 0.25,
    );
    y -= 14;
  }

  if (observacao != null && observacao.isNotEmpty) {
    pagina.texto(observacao, x: _margem, y: y, tamanho: 8, negrito: true);
    y -= 14;
  }

  pagina.texto(
    'Documento preparado pelo Desmalha a partir dos lançamentos do seu '
    'livro-caixa. Não é emissão oficial da Receita Federal:',
    x: _margem,
    y: y,
    tamanho: 7.5,
    cinza: 0.45,
  );
  y -= 9.5;
  pagina.texto(
    'confira os valores antes de pagar e mantenha os comprovantes por 5 anos '
    'a partir do exercício seguinte.',
    x: _margem,
    y: y,
    tamanho: 7.5,
    cinza: 0.45,
  );

  return pdf.bytes();
}

/// Desenha um campo do formulário: caixa, número, rótulo e valor.
void _campo(
  PaginaPdf pagina, {
  required String numero,
  required String rotulo,
  required String valor,
  required double x,
  required double y,
  required double largura,
  required double altura,
  AlinhamentoTexto alinhamentoValor = AlinhamentoTexto.esquerda,
  bool destaque = false,
  double tamanhoValor = 11,
}) {
  pagina.retangulo(
    x: x,
    y: y,
    largura: largura,
    altura: altura,
    preenchido: false,
    cinza: 0.55,
  );
  final cabecalho = numero.isEmpty ? rotulo : '$numero  $rotulo';
  pagina.texto(
    cabecalho,
    x: x + 6,
    y: y + altura - 11,
    tamanho: 6.8,
    cinza: 0.4,
  );

  final xValor = switch (alinhamentoValor) {
    AlinhamentoTexto.esquerda => x + 6,
    AlinhamentoTexto.centro => x + largura / 2,
    AlinhamentoTexto.direita => x + largura - 6,
  };
  pagina.texto(
    valor,
    x: xValor,
    y: y + 8,
    tamanho: tamanhoValor,
    negrito: destaque,
    alinhamento: alinhamentoValor,
  );
}

/// Desenha o código de barras ITF ocupando [larguraDisponivel].
void _desenharCodigoBarras(
  PaginaPdf pagina, {
  required String digitos,
  required double x,
  required double y,
  required double larguraDisponivel,
  required double altura,
}) {
  final elementos = codificarItf(digitos);
  final modulos = larguraEmModulos(elementos);
  final larguraModulo = larguraDisponivel / modulos;

  var cursor = x;
  for (final elemento in elementos) {
    final largura = elemento.modulos * larguraModulo;
    if (elemento.ehBarra) {
      pagina.retangulo(
        x: cursor,
        y: y,
        largura: largura,
        altura: altura,
      );
    }
    cursor += largura;
  }
}

/// `'2026-03-31'` → `'31/03/2026'`.
String _dataBr(String dataCivil) =>
    '${dataCivil.substring(8)}/${dataCivil.substring(5, 7)}'
    '/${dataCivil.substring(0, 4)}';

/// `'2026-03'` → `'03/2026'`.
String _competenciaBr(String competencia) =>
    '${competencia.substring(5)}/${competencia.substring(0, 4)}';
