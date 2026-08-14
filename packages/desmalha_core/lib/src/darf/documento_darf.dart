/// O documento DARF do carnê-leão (código de receita 0190).
///
/// Monta a guia a partir de uma [ApuracaoMensal] já calculada pelo motor:
/// período de apuração, vencimento, contribuinte, valor e — quando existir
/// layout conferido no catálogo — o código de barras de arrecadação.
///
/// Uma guia NÃO tem relação 1:1 com uma competência. Pela regra do valor
/// mínimo (Lei 9.430/1996, art. 68), o imposto abaixo de R$ 10,00 acumula e é
/// pago junto com o de um mês posterior; o período de apuração da guia é o do
/// ÚLTIMO mês, e os meses absorvidos ficam registrados em
/// [DocumentoDarf.competenciasAbrangidas] para o usuário conseguir explicar a
/// guia depois.
///
/// Multa e juros de mora não são calculados aqui, por decisão de projeto: o
/// app apura o valor original e direciona ao SicalcWeb quando a guia está
/// vencida — não há base de Selic embarcada.
library;

import '../carne_leao/apuracao.dart';
import '../carne_leao/darf.dart';
import 'codigo_barras_arrecadacao.dart';
import 'layout_darf.dart';

/// Quem paga a guia.
class Contribuinte {
  Contribuinte({
    required String cpf,
    required this.nome,
    this.telefone,
  }) : cpf = cpf.replaceAll(RegExp(r'\D'), '') {
    if (!cpfValido(this.cpf)) {
      throw ArgumentError.value(cpf, 'cpf', 'CPF inválido');
    }
    if (nome.trim().isEmpty) {
      throw ArgumentError.value(nome, 'nome', 'nome não pode ser vazio');
    }
  }

  /// CPF só com dígitos.
  final String cpf;

  final String nome;

  final String? telefone;

  /// CPF no formato `000.000.000-00`, para impressão na guia.
  String get cpfFormatado => '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}'
      '.${cpf.substring(6, 9)}-${cpf.substring(9)}';
}

/// Valida CPF pelos dois dígitos verificadores (módulo 11).
///
/// Rejeita os onze repetidos (`111...`), que passam no cálculo mas não são
/// CPF de ninguém.
bool cpfValido(String cpf) {
  if (cpf.length != 11) return false;
  for (var i = 0; i < 11; i++) {
    final codigo = cpf.codeUnitAt(i);
    if (codigo < 0x30 || codigo > 0x39) return false;
  }
  if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;

  for (var digito = 0; digito < 2; digito++) {
    final ate = 9 + digito;
    var soma = 0;
    for (var i = 0; i < ate; i++) {
      soma += (cpf.codeUnitAt(i) - 0x30) * (ate + 1 - i);
    }
    final resto = soma * 10 % 11;
    final esperado = resto == 10 ? 0 : resto;
    if (esperado != cpf.codeUnitAt(ate) - 0x30) return false;
  }
  return true;
}

/// Uma guia DARF pronta para exibir, imprimir ou pagar.
class DocumentoDarf {
  const DocumentoDarf({
    required this.codigoReceita,
    required this.competencia,
    required this.periodoApuracao,
    required this.dataVencimento,
    required this.contribuinte,
    required this.valorPrincipalCentavos,
    required this.competenciasAbrangidas,
    this.codigoBarras,
    this.numeroReferencia,
  });

  /// Sempre `0190` para o carnê-leão.
  final String codigoReceita;

  /// Competência da guia, `'YYYY-MM'` — a última quando há acumulação.
  final String competencia;

  /// Período de apuração impresso na guia: último dia do mês da [competencia],
  /// como data civil `'YYYY-MM-DD'`.
  final String periodoApuracao;

  /// Vencimento: último dia útil do mês seguinte, `'YYYY-MM-DD'`.
  final String dataVencimento;

  final Contribuinte contribuinte;

  /// Valor principal em centavos — o total da guia.
  final int valorPrincipalCentavos;

  /// Multa de mora. Sempre zero: guia vencida vai para o SicalcWeb.
  int get multaCentavos => 0;

  /// Juros de mora. Sempre zero, mesmo motivo da multa.
  int get jurosCentavos => 0;

  /// Total a recolher em centavos.
  int get valorTotalCentavos =>
      valorPrincipalCentavos + multaCentavos + jurosCentavos;

  /// Competências que esta guia quita, em ordem cronológica. Tem mais de um
  /// elemento quando meses anteriores ficaram abaixo do DARF mínimo.
  final List<String> competenciasAbrangidas;

  /// `null` quando não há layout conferido no catálogo — a guia sai sem
  /// código de barras e o pagamento é direcionado ao e-CAC.
  final CodigoBarrasArrecadacao? codigoBarras;

  /// Número de referência do documento, quando o emissor atribui um.
  final String? numeroReferencia;

  /// `true` se a guia já venceu em [dataCivilHoje] (`'YYYY-MM-DD'`).
  ///
  /// Guia vencida não deve ser paga pelo valor desta apuração: o recolhimento
  /// exige multa e juros, calculados no SicalcWeb.
  bool venceuAte(String dataCivilHoje) =>
      dataCivilHoje.compareTo(dataVencimento) > 0;

  /// Monta a guia de uma apuração cujo status seja [StatusDarf.emitido].
  ///
  /// [feriadosBancarios] vem da tabela versionada do catálogo. [layout] é
  /// opcional: sem ele — ou com ele ainda não conferido contra um DARF real —
  /// a guia sai sem código de barras, que é o comportamento correto e seguro.
  ///
  /// Lança [ArgumentError] se a apuração não gera guia; o chamador deve
  /// consultar [ApuracaoMensal.statusDarf] antes.
  factory DocumentoDarf.daApuracao({
    required ApuracaoMensal apuracao,
    required Contribuinte contribuinte,
    required Set<String> feriadosBancarios,
    LayoutCodigoBarrasDarf? layout,
    List<String> competenciasAbrangidas = const [],
    String? numeroReferencia,
  }) {
    if (apuracao.statusDarf != StatusDarf.emitido) {
      throw ArgumentError.value(
        apuracao.statusDarf,
        'apuracao.statusDarf',
        'a competência ${apuracao.competencia} não gera guia',
      );
    }

    final competencia = apuracao.competencia;
    final vencimento = vencimentoDarf(competencia, feriadosBancarios);
    final valor = apuracao.valorDarfCentavos;

    CodigoBarrasArrecadacao? codigoBarras;
    if (layout != null && layout.conferidoContraDocumentoReal) {
      codigoBarras = layout.montarCodigoBarras(
        codigoReceita: codigoReceitaCarneLeao,
        cpfContribuinte: contribuinte.cpf,
        competencia: competencia,
        dataVencimento: vencimento,
        valorCentavos: valor,
        numeroReferencia: numeroReferencia ?? '',
      );
    }

    final abrangidas = competenciasAbrangidas.contains(competencia)
        ? List<String>.unmodifiable(competenciasAbrangidas)
        : List<String>.unmodifiable([...competenciasAbrangidas, competencia]);

    return DocumentoDarf(
      codigoReceita: codigoReceitaCarneLeao,
      competencia: competencia,
      periodoApuracao: ultimoDiaDoMes(competencia),
      dataVencimento: vencimento,
      contribuinte: contribuinte,
      valorPrincipalCentavos: valor,
      competenciasAbrangidas: abrangidas,
      codigoBarras: codigoBarras,
      numeroReferencia: numeroReferencia,
    );
  }
}

/// Gera as guias de uma sequência de apurações, resolvendo o N:1 do DARF
/// mínimo: cada competência retida entra em [DocumentoDarf.competenciasAbrangidas]
/// da primeira guia efetivamente emitida depois dela.
///
/// Competências com resíduo levado à DIRPF ou sem imposto não geram guia nem
/// são absorvidas por guia nenhuma.
List<DocumentoDarf> darfsDaSequencia({
  required List<ApuracaoMensal> apuracoes,
  required Contribuinte contribuinte,
  required Set<String> feriadosBancarios,
  LayoutCodigoBarrasDarf? layout,
}) {
  final guias = <DocumentoDarf>[];
  final retidas = <String>[];

  for (final apuracao in apuracoes) {
    switch (apuracao.statusDarf) {
      case StatusDarf.acumulaParaProximoMes:
        retidas.add(apuracao.competencia);
      case StatusDarf.emitido:
        guias.add(
          DocumentoDarf.daApuracao(
            apuracao: apuracao,
            contribuinte: contribuinte,
            feriadosBancarios: feriadosBancarios,
            layout: layout,
            competenciasAbrangidas: [...retidas, apuracao.competencia],
          ),
        );
        retidas.clear();
      case StatusDarf.residuoParaDirpf:
      case StatusDarf.semImposto:
        retidas.clear();
    }
  }
  return guias;
}
