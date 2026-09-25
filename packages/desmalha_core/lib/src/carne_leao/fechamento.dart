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
/// - o que a rodada 4 não cobre é FALHA VISÍVEL, nunca número adivinhado
///   (rodada 5, 25/09/2026): mês de uma guia de vários meses que passa a
///   ter guia própria (P13), diferença a maior abaixo de R$ 10,00 (P14) e
///   correção depois de entregue a declaração do ano (P15).
library;

import 'apuracao.dart';

/// Texto único da falha visível enquanto o contador não responde.
const String textoCalculoPendente =
    'Cálculo pendente: aguardando confirmação do contador';

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

/// Caso que a rodada 4 não cobre: [textoCalculoPendente], sem valor.
class AcertoPendente extends AcertoDaGuia {
  const AcertoPendente(super.guia, {required this.pergunta});

  /// A pergunta da rodada 5 que decide o caso (`'P13'`, `'P14'`).
  final String pergunta;
}

/// Compara a [guia] paga com o ano recalculado ([recalculadas], por
/// competência, apurado com o período da guia em `periodosQuitados`).
///
/// O devido da guia é o total a recolher recalculado no período dela —
/// o próprio mês mais o que acumulou até ele. Se um mês que a guia
/// absorveu passou a ter guia própria, o agrupamento mudou: P13.
AcertoDaGuia acertoDaGuia(
  GuiaPaga guia,
  Map<String, ApuracaoMensal> recalculadas,
) {
  for (final c in guia.competencias.take(guia.competencias.length - 1)) {
    if (recalculadas[c]?.statusDarf == StatusDarf.emitido) {
      return AcertoPendente(guia, pergunta: 'P13');
    }
  }
  final devido = recalculadas[guia.periodo]?.totalParaDarfCentavos ?? 0;
  final diferenca = devido - guia.principalPagoCentavos;
  if (diferenca == 0) return AcertoEmDia(guia);
  if (diferenca < 0) {
    return AcertoPagoAMaior(guia, diferencaCentavos: -diferenca);
  }
  if (diferenca < darfMinimoCentavos) {
    return AcertoPendente(guia, pergunta: 'P14');
  }
  return AcertoComplementar(
    guia,
    competencia: guia.periodo,
    diferencaCentavos: diferenca,
  );
}

/// P15 (rodada 5): corrigir uma guia de ano-calendário anterior pode mexer
/// na declaração já entregue — o app mostra [textoCalculoPendente] para a
/// declaração, além do acerto da guia.
bool acertoTocaDeclaracaoEntregue(AcertoDaGuia acerto, String hoje) =>
    acerto is! AcertoEmDia &&
    acerto.guia.periodo.substring(0, 4).compareTo(hoje.substring(0, 4)) < 0;
