/// Relatório anual para a declaração de IRPF: a ficha de rendimentos
/// recebidos de pessoa física, mês a mês, em cinco colunas — receitas,
/// livro-caixa, INSS, dependentes e imposto pago (rodada 1) — mais a seção
/// de rendimentos recebidos de pessoa jurídica sem IRRF (rodada 4, P1).
///
/// É uma VISÃO, não uma tabela gravada (decisão 9 do owner, 25/09/2026):
/// sai do que a camada local já sabe, a cada vez que é aberto.
///
/// Regras do contador:
/// - livro-caixa e INSS com o valor REAL escriturado, mesmo no mês em que
///   o desconto simplificado venceu (P12);
/// - imposto pago só com DARF marcado como pago, só o principal — multa e
///   juros não são imposto (P11);
/// - guia de vários meses: o valor inteiro no período dela (o último mês),
///   os anteriores com R$ 0,00 (P10);
/// - a coluna soma todas as guias pagas da competência — a original e o
///   complementar, ou o DARF próprio de um mês que saiu de guia N:1
///   (rodada 5, P13 e P15).
library;

import '../carne_leao/painel_mensal.dart';
import '../carne_leao/tabela_irpf.dart';

/// Uma guia paga, como o relatório a enxerga.
class GuiaPagaDoRelatorio {
  const GuiaPagaDoRelatorio({
    required this.periodo,
    required this.principalCentavos,
  });

  /// Período de apuração impresso na guia (`'YYYY-MM'`).
  final String periodo;

  /// Só o principal (P11).
  final int principalCentavos;
}

/// Um recebimento de pessoa jurídica sem IRRF (P1): fora da base mensal,
/// vai para a declaração anual com CNPJ e nome ou razão social.
class RecebimentoPj {
  const RecebimentoPj({
    required this.cnpj,
    required this.nome,
    required this.valorCentavos,
  });

  /// Só dígitos; `null` quando a pessoa ainda não informou.
  final String? cnpj;
  final String? nome;
  final int valorCentavos;
}

class LinhaDoRelatorio {
  const LinhaDoRelatorio({
    required this.competencia,
    required this.receitasCentavos,
    required this.livroCaixaCentavos,
    required this.inssCentavos,
    required this.dependentes,
    required this.deducaoDependentesCentavos,
    required this.impostoPagoCentavos,
  });

  final String competencia;
  final int receitasCentavos;
  final int livroCaixaCentavos;
  final int inssCentavos;
  final int dependentes;
  final int deducaoDependentesCentavos;
  final int impostoPagoCentavos;
}

/// Uma fonte pagadora PJ, somada no ano.
class FontePj {
  const FontePj({
    required this.cnpj,
    required this.nome,
    required this.totalCentavos,
  });

  final String? cnpj;
  final String? nome;
  final int totalCentavos;
}

class RelatorioAnual {
  const RelatorioAnual({
    required this.ano,
    required this.meses,
    required this.fontesPj,
  });

  final int ano;

  /// Janeiro a dezembro, sempre os doze.
  final List<LinhaDoRelatorio> meses;

  /// Recebido de PJ sem IRRF, por fonte, do maior para o menor.
  final List<FontePj> fontesPj;

  int _soma(int Function(LinhaDoRelatorio) campo) {
    var total = 0;
    for (final m in meses) {
      total += campo(m);
    }
    return total;
  }

  int get totalReceitasCentavos => _soma((m) => m.receitasCentavos);
  int get totalLivroCaixaCentavos => _soma((m) => m.livroCaixaCentavos);
  int get totalInssCentavos => _soma((m) => m.inssCentavos);
  int get totalDependentesCentavos =>
      _soma((m) => m.deducaoDependentesCentavos);
  int get totalImpostoPagoCentavos => _soma((m) => m.impostoPagoCentavos);

  int get totalPjCentavos {
    var total = 0;
    for (final f in fontesPj) {
      total += f.totalCentavos;
    }
    return total;
  }

  /// Nada no ano: nem receita, nem dedução, nem guia, nem PJ.
  bool get vazio =>
      totalReceitasCentavos == 0 &&
      totalLivroCaixaCentavos == 0 &&
      totalInssCentavos == 0 &&
      totalDependentesCentavos == 0 &&
      totalImpostoPagoCentavos == 0 &&
      fontesPj.isEmpty;
}

/// Monta o relatório do [ano] a partir do que a camada local sabe de cada
/// mês ([dadosDoAno], as mesmas chaves do painel), das guias pagas cujo
/// período cai no ano e dos recebimentos de PJ do ano.
///
/// A dedução por dependentes usa o valor da tabela vigente no mês
/// ([tabelaPara]); mês sem dependente não consulta a tabela.
RelatorioAnual montarRelatorioAnual({
  required int ano,
  required Map<String, DadosDoMes> dadosDoAno,
  required List<GuiaPagaDoRelatorio> guiasPagas,
  required List<RecebimentoPj> recebimentosPj,
  required TabelaIrpf Function(String competencia) tabelaPara,
}) {
  final pagoPorPeriodo = <String, int>{};
  for (final g in guiasPagas) {
    if (g.principalCentavos <= 0) {
      throw ArgumentError('guia paga com principal não positivo');
    }
    pagoPorPeriodo[g.periodo] =
        (pagoPorPeriodo[g.periodo] ?? 0) + g.principalCentavos;
  }

  final meses = [
    for (var m = 1; m <= 12; m++)
      if ('$ano-${m.toString().padLeft(2, '0')}' case final c)
        _linha(c, dadosDoAno[c], pagoPorPeriodo[c] ?? 0, tabelaPara),
  ];

  // P1: a chave da fonte é o CNPJ; sem CNPJ, o nome; sem nenhum dos dois,
  // uma fonte "não identificada" (o valor entra, a pendência fica visível).
  final porFonte = <String, (String?, String?, int)>{};
  for (final r in recebimentosPj) {
    final chave = r.cnpj ?? (r.nome == null ? '' : 'nome:${r.nome}');
    final (cnpj, nome, total) = porFonte[chave] ?? (r.cnpj, r.nome, 0);
    porFonte[chave] = (cnpj, nome ?? r.nome, total + r.valorCentavos);
  }
  final fontes = [
    for (final (cnpj, nome, total) in porFonte.values)
      FontePj(cnpj: cnpj, nome: nome, totalCentavos: total),
  ]..sort((a, b) => b.totalCentavos.compareTo(a.totalCentavos));

  return RelatorioAnual(ano: ano, meses: meses, fontesPj: fontes);
}

LinhaDoRelatorio _linha(
  String competencia,
  DadosDoMes? dados,
  int impostoPago,
  TabelaIrpf Function(String competencia) tabelaPara,
) {
  final dependentes = dados?.dependentes ?? 0;
  return LinhaDoRelatorio(
    competencia: competencia,
    receitasCentavos: dados?.receitaTributavelCentavos ?? 0,
    livroCaixaCentavos: dados?.despesasDedutiveisCentavos ?? 0,
    inssCentavos: dados?.inssDedutivelCentavos ?? 0,
    dependentes: dependentes,
    deducaoDependentesCentavos: dependentes == 0
        ? 0
        : dependentes * tabelaPara(competencia).valorDependenteCentavos,
    impostoPagoCentavos: impostoPago,
  );
}
