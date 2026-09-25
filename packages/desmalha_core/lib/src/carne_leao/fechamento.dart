/// Fechamento do mês e acerto de guia já paga — decidido aqui, em Dart
/// puro; o app só grava e mostra.
///
/// Regras (decisão 7 do owner, 25/09/2026; rodada 4 do contador):
/// - o mês NÃO fecha com recebimento a classificar nem com caso pendente de
///   uma rodada do contador; falta de CPF e INSS sem resposta não impedem;
/// - reabrir um mês pago compara o recalculado com o pago, por guia:
///   maior → DARF complementar da competência original pelo SicalcWeb, sem
///   somar a outro mês (P8); menor → só sinaliza, o acerto é na declaração
///   anual, nunca abate de guia futura (P9);
/// - rodada 5 (25/09/2026): mês de uma guia de vários meses que passa a
///   ter guia própria é acertado POR COMPETÊNCIA — ele deve o valor
///   integral em DARF em atraso, e o que tinha pago na guia posterior vira
///   pagamento a maior dela (P13); diferença a maior abaixo de R$ 10,00
///   não gera guia, o acerto é na declaração anual (P14); correção depois
///   de entregue a declaração do ano pede a retificadora, nos dois
///   sentidos (P15).
library;

import 'apuracao.dart';

/// Por que o mês ainda não pode ser fechado. Vazio = pode fechar.
List<String> motivosQueImpedemFechar({required int recebimentosAClassificar}) =>
    [
      if (recebimentosAClassificar == 1)
        'Falta classificar 1 recebimento do mês.'
      else if (recebimentosAClassificar > 1)
        'Faltam classificar $recebimentosAClassificar recebimentos do mês.',
    ];

/// Uma guia paga: o período de apuração é a ÚLTIMA competência (DARF N:1,
/// P10), e o principal é a soma do que foi pago para esse período — a guia
/// original e eventuais complementares.
class GuiaPaga {
  GuiaPaga({
    required List<String> competencias,
    required this.principalPagoCentavos,
  }) : competencias = [...competencias]..sort() {
    if (this.competencias.isEmpty) {
      throw ArgumentError('guia paga sem competência');
    }
    if (principalPagoCentavos <= 0) {
      throw ArgumentError('principal pago precisa ser positivo');
    }
  }

  final List<String> competencias;
  final int principalPagoCentavos;

  String get periodo => competencias.last;
}

sealed class AcertoDaGuia {
  const AcertoDaGuia(this.guia);

  final GuiaPaga guia;
}

/// O recalculado bate com o pago.
class AcertoEmDia extends AcertoDaGuia {
  const AcertoEmDia(super.guia);
}

/// P8: falta pagar [diferencaCentavos] de principal, em DARF complementar
/// da [competencia] original, gerado no SicalcWeb com multa e juros.
class AcertoComplementar extends AcertoDaGuia {
  const AcertoComplementar(
    super.guia, {
    required this.competencia,
    required this.diferencaCentavos,
  });

  final String competencia;
  final int diferencaCentavos;
}

/// P9: pago a maior — só sinaliza; o acerto é na declaração anual.
class AcertoPagoAMaior extends AcertoDaGuia {
  const AcertoPagoAMaior(super.guia, {required this.diferencaCentavos});

  final int diferencaCentavos;
}

/// P14 (rodada 5): falta pagar [diferencaCentavos], mas abaixo do DARF
/// mínimo não sai guia — a lei e o SicalcWeb vedam. O valor é cobrado,
/// com as correções, na declaração anual; somá-lo a guia futura omitiria
/// multa e juros.
class AcertoAbaixoDoMinimo extends AcertoDaGuia {
  const AcertoAbaixoDoMinimo(super.guia, {required this.diferencaCentavos});

  final int diferencaCentavos;
}

/// Uma competência que a guia absorvia e agora tem DARF próprio (P13).
typedef GuiaEmAtraso = ({String competencia, int valorCentavos});

/// P13 (rodada 5): o agrupamento da guia mudou. Cada mês de [emAtraso]
/// deve o valor integral recalculado em DARF próprio, em atraso, pelo
/// SicalcWeb; o período da guia é acertado por [doPeriodo] — em geral,
/// pago a maior do que o mês reaberto tinha "pegado carona".
class AcertoReagrupado extends AcertoDaGuia {
  const AcertoReagrupado(
    super.guia, {
    required this.emAtraso,
    required this.doPeriodo,
  });

  final List<GuiaEmAtraso> emAtraso;

  /// Nunca outro [AcertoReagrupado].
  final AcertoDaGuia doPeriodo;
}

/// Compara a [guia] paga com o ano recalculado ([recalculadas], por
/// competência, apurado com os períodos das guias pagas em
/// `periodosQuitados`).
///
/// O devido do período é o total a recolher recalculado nele — o próprio
/// mês mais o que acumulou até ele. Um mês que a guia absorvia e agora
/// emite DARF próprio vai para [AcertoReagrupado.emAtraso], a menos que
/// já tenha guia paga com período nele ([periodosPagos]).
AcertoDaGuia acertoDaGuia(
  GuiaPaga guia,
  Map<String, ApuracaoMensal> recalculadas, {
  Set<String> periodosPagos = const {},
}) {
  final doPeriodo = _acertoDoPeriodo(guia, recalculadas);
  final emAtraso = <GuiaEmAtraso>[
    for (final c in guia.competencias.take(guia.competencias.length - 1))
      if (recalculadas[c] case final a?
          when a.statusDarf == StatusDarf.emitido &&
              !periodosPagos.contains(c))
        (competencia: c, valorCentavos: a.valorDarfCentavos),
  ];
  return emAtraso.isEmpty
      ? doPeriodo
      : AcertoReagrupado(guia, emAtraso: emAtraso, doPeriodo: doPeriodo);
}

AcertoDaGuia _acertoDoPeriodo(
  GuiaPaga guia,
  Map<String, ApuracaoMensal> recalculadas,
) {
  final devido = recalculadas[guia.periodo]?.totalParaDarfCentavos ?? 0;
  final diferenca = devido - guia.principalPagoCentavos;
  if (diferenca == 0) return AcertoEmDia(guia);
  if (diferenca < 0) {
    return AcertoPagoAMaior(guia, diferencaCentavos: -diferenca);
  }
  if (diferenca < darfMinimoCentavos) {
    return AcertoAbaixoDoMinimo(guia, diferencaCentavos: diferenca);
  }
  return AcertoComplementar(
    guia,
    competencia: guia.periodo,
    diferencaCentavos: diferenca,
  );
}

/// P15 (rodada 5): acerto de uma guia de ano-calendário anterior — se a
/// declaração daquele ano já foi entregue, a correção exige a retificadora,
/// nos dois sentidos (é ela que regulariza o ano e permite reaver
/// pagamento a maior).
bool acertoPedeRetificadora(AcertoDaGuia acerto, String hoje) =>
    acerto is! AcertoEmDia &&
    acerto.guia.periodo.substring(0, 4).compareTo(hoje.substring(0, 4)) < 0;
