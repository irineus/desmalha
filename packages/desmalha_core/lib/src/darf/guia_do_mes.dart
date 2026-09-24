/// A guia DARF de um mês do dashboard, montada pelo que já existe:
/// o painel (motor sobre lançamentos classificados) + [darfsDaSequencia]
/// (que resolve as competências absorvidas pelo DARF mínimo).
///
/// Travas — cada uma é falha VISÍVEL, nunca guia adivinhada:
/// - só competência com DARF emitido gera guia;
/// - sem o vencimento calculado pelo catálogo (feriados do ano publicados),
///   não há guia: montar com um conjunto de feriados incompleto daria uma
///   data possivelmente errada em silêncio;
/// - sem nome e CPF do contribuinte, não há guia.
///
/// Código de barras só com layout CONFERIDO contra DARF real no catálogo, e
/// só se houver exatamente um — dois candidatos seria escolher às cegas. Sem
/// ele a guia sai sem código, e o pagamento vai pelo e-CAC (postura vigente).
library;

import '../carne_leao/apuracao.dart';
import '../carne_leao/painel_mensal.dart';
import '../catalogo/catalogo.dart';
import 'documento_darf.dart';
import 'layout_darf.dart';

enum MotivoSemGuia {
  /// O mês não gera DARF (sem imposto, acumula, resíduo para a DIRPF).
  naoEmitida,

  /// O catálogo não cobre os feriados do ano do vencimento.
  semCalendario,

  /// Nome e CPF do contribuinte ainda não foram informados.
  semContribuinte,
}

sealed class ResultadoGuia {
  const ResultadoGuia();
}

class GuiaPronta extends ResultadoGuia {
  const GuiaPronta(this.documento);

  final DocumentoDarf documento;
}

class SemGuia extends ResultadoGuia {
  const SemGuia(this.motivo);

  final MotivoSemGuia motivo;
}

ResultadoGuia guiaDoMes({
  required PainelApurado painel,
  required Contribuinte? contribuinte,
  required Catalogo catalogo,
}) {
  if (painel.apuracao.statusDarf != StatusDarf.emitido) {
    return const SemGuia(MotivoSemGuia.naoEmitida);
  }
  final vencimento = painel.vencimento;
  if (vencimento == null) return const SemGuia(MotivoSemGuia.semCalendario);
  if (contribuinte == null) {
    return const SemGuia(MotivoSemGuia.semContribuinte);
  }

  final anoCompetencia = int.parse(painel.competencia.substring(0, 4));
  final anoVencimento = int.parse(vencimento.substring(0, 4));
  // Os dois anos estão no catálogo: o vencimento do painel saiu dele.
  final feriados = {
    ...catalogo.feriadosDoAno(anoCompetencia),
    ...catalogo.feriadosDoAno(anoVencimento),
  };

  final conferidos = [
    for (final l in catalogo.layoutsDarf)
      if (l.conferidoContraDocumentoReal) l,
  ];
  final LayoutCodigoBarrasDarf? layout = conferidos.length == 1
      ? conferidos.single
      : null;

  final guias = darfsDaSequencia(
    apuracoes: [
      for (final m in painel.evolucao)
        if (m.apuracao != null) m.apuracao!,
    ],
    contribuinte: contribuinte,
    feriadosBancarios: feriados,
    layout: layout,
  );
  final guia = guias.singleWhere((g) => g.competencia == painel.competencia);
  if (guia.dataVencimento != vencimento) {
    throw StateError(
      'vencimento da guia (${guia.dataVencimento}) diverge do painel '
      '($vencimento) — catálogo inconsistente',
    );
  }
  return GuiaPronta(guia);
}
