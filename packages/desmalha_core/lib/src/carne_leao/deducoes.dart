/// As deduções do mês, a partir do que a pessoa registrou — regras da
/// rodada 4 do contador (25/09/2026):
///
/// - (P5, 4b) despesa no cartão de crédito entra na DATA DA COMPRA, inclusive
///   na virada do ano; a data da fatura não entra no cálculo. Nas demais
///   formas, na data do pagamento (regime de caixa).
/// - (P6) INSS pago com atraso deduz SÓ o principal; multa e juros ficam de
///   fora. "Não paguei" deduz zero, e mês sem resposta também (fica como
///   pendência — decisão 7 do owner).
/// - (P7) dependente conta o MÊS INTEIRO em que existiu em qualquer dia, na
///   entrada e na saída.
library;

import 'apuracao.dart';
import 'estados_persistidos.dart';

/// A competência (`'YYYY-MM'`) em que uma despesa entra no livro-caixa.
///
/// Para [FormaPagamentoDespesa.cartaoCredito], [dataPagamento] é a data da
/// COMPRA (uso do cartão) — a fatura não entra no cálculo (P5). Para as
/// demais, a data em que o dinheiro saiu.
String competenciaDaDespesa({
  required FormaPagamentoDespesa forma,
  required String dataPagamento,
}) {
  if (dataPagamento.length != 10) {
    throw ArgumentError.value(dataPagamento, 'dataPagamento', "'YYYY-MM-DD'");
  }
  return dataPagamento.substring(0, 7);
}

/// Uma resposta à pergunta "Você pagou INSS em `<mês>`?".
class PagamentoInssDoMes {
  const PagamentoInssDoMes.pago({
    required this.principalCentavos,
    this.acrescimosCentavos = 0,
  }) : situacao = SituacaoInss.pago;

  const PagamentoInssDoMes.naoPago()
      : situacao = SituacaoInss.naoPago,
        principalCentavos = 0,
        acrescimosCentavos = 0;

  final SituacaoInss situacao;
  final int principalCentavos;

  /// Multa e juros de guia paga em atraso — registrados, nunca deduzidos.
  final int acrescimosCentavos;
}

/// O INSS dedutível do mês: a soma dos PRINCIPAIS pagos (P6).
int inssDedutivelDoMes(Iterable<PagamentoInssDoMes> pagamentos) {
  var total = 0;
  for (final p in pagamentos) {
    if (p.situacao == SituacaoInss.pago) total += p.principalCentavos;
  }
  return total;
}

/// Um dependente com a vigência que a pessoa informou.
class VigenciaDependente {
  const VigenciaDependente({required this.inicio, this.fim});

  /// Data civil `'YYYY-MM-DD'` em que passou a ser dependente.
  final String inicio;

  /// Última data como dependente, ou `null` se continua.
  final String? fim;
}

/// Quantos dependentes contam na [competencia]: quem existiu em QUALQUER
/// dia do mês conta o mês inteiro (P7).
int dependentesNoMes(
  Iterable<VigenciaDependente> dependentes,
  String competencia,
) {
  var n = 0;
  for (final d in dependentes) {
    final entrou = d.inicio.substring(0, 7);
    final saiu = d.fim?.substring(0, 7);
    if (entrou.compareTo(competencia) <= 0 &&
        (saiu == null || saiu.compareTo(competencia) >= 0)) {
      n++;
    }
  }
  return n;
}

/// Monta a entrada do motor de uma competência a partir do que foi
/// registrado nela: a receita tributável (da classificação), as despesas
/// que caem no mês (já roteadas por [competenciaDaDespesa]), o INSS e os
/// dependentes.
EntradaApuracao entradaDoMes({
  required String competencia,
  required int receitaTributavelCentavos,
  Iterable<DespesaLivroCaixa> despesas = const [],
  Iterable<PagamentoInssDoMes> inss = const [],
  Iterable<VigenciaDependente> dependentes = const [],
}) {
  var dedutivel = 0;
  for (final d in despesas) {
    dedutivel += d.dedutivelCentavos;
  }
  return EntradaApuracao(
    competencia: competencia,
    receitaBrutaCentavos: receitaTributavelCentavos,
    despesasDedutiveisCentavos: dedutivel,
    inssPagoCentavos: inssDedutivelDoMes(inss),
    numeroDependentes: dependentesNoMes(dependentes, competencia),
  );
}
