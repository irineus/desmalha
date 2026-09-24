/// Plano dos lembretes locais de vencimento do DARF do carnê-leão.
///
/// O app agenda notificações LOCAIS (decisão vigente: push server-side saiu
/// do caminho crítico do MVP). Este módulo só decide QUAIS datas — o
/// vencimento de cada competência vem de `Catalogo.vencimentoDarfDe`, com a
/// tabela versionada de feriados bancários, nunca de uma conta local.
///
/// O lembrete fala da DATA, não do valor: ele não afirma que há imposto a
/// pagar (o mês pode não ter receita classificada, ou ficar abaixo do mínimo
/// do DARF e acumular). Por isso é planejado para toda competência, sem ler
/// o livro-caixa.
///
/// Ano sem feriados publicados no catálogo NÃO vira data adivinhada: o plano
/// para ali e diz qual ano faltou ([PlanoLembretesDarf.falhaDeCalendario]) —
/// a mesma postura da guia que sai sem código de barras.
library;

import '../catalogo/catalogo.dart';
import 'darf.dart';

/// Quantos dias corridos antes do vencimento sai o primeiro aviso.
const int diasDeAntecedenciaDoLembrete = 3;

/// Quantas competências à frente o app agenda de uma vez. O app reagenda a
/// cada abertura; o horizonte cobre quem passa meses sem abrir.
const int competenciasNoHorizonteDoLembrete = 6;

/// Um aviso a agendar.
class LembreteVencimento {
  const LembreteVencimento({
    required this.competencia,
    required this.vencimento,
    required this.dataDoAviso,
    required this.noDia,
  });

  /// Competência `'YYYY-MM'` a que o DARF se refere.
  final String competencia;

  /// Data civil `'YYYY-MM-DD'` de vencimento (último dia útil do mês
  /// seguinte, antecipando em fim de semana e feriado bancário).
  final String vencimento;

  /// Data civil `'YYYY-MM-DD'` em que o aviso aparece.
  final String dataDoAviso;

  /// `true` no aviso do próprio dia; `false` no de antecedência.
  final bool noDia;

  @override
  bool operator ==(Object other) =>
      other is LembreteVencimento &&
      other.competencia == competencia &&
      other.vencimento == vencimento &&
      other.dataDoAviso == dataDoAviso &&
      other.noDia == noDia;

  @override
  int get hashCode => Object.hash(competencia, vencimento, dataDoAviso, noDia);

  @override
  String toString() =>
      'LembreteVencimento($competencia vence $vencimento, aviso $dataDoAviso'
      '${noDia ? ' (no dia)' : ''})';
}

/// O que agendar e, se o calendário acabou, onde acabou.
class PlanoLembretesDarf {
  const PlanoLembretesDarf({required this.lembretes, this.falhaDeCalendario});

  /// Avisos com [LembreteVencimento.dataDoAviso] em `hoje` ou depois, em
  /// ordem cronológica.
  final List<LembreteVencimento> lembretes;

  /// Motivo pelo qual o plano parou antes do horizonte — o catálogo não
  /// cobre o ano do próximo vencimento. `null` quando o horizonte fechou.
  final FalhaDeCalendario? falhaDeCalendario;

  /// Próximo vencimento com lembrete agendado, se houver.
  String? get proximoVencimento =>
      lembretes.isEmpty ? null : lembretes.first.vencimento;
}

/// O plano parou: o vencimento da [competencia] não pôde ser calculado.
class FalhaDeCalendario {
  const FalhaDeCalendario({required this.competencia, required this.motivo});

  final String competencia;

  /// Mensagem do [StateError] do catálogo (ex.: "sem feriados para 2027").
  final String motivo;

  /// Ano do vencimento que ficou sem calendário.
  int get anoDoVencimento =>
      int.parse(competenciaSeguinte(competencia).substring(0, 4));
}

/// Planeja os lembretes a partir de [hoje] (`'YYYY-MM-DD'`).
///
/// Começa na competência anterior à de hoje (o DARF dela vence neste mês) e
/// segue até [competencias] vencimentos ainda não passados. Cada vencimento
/// gera dois avisos: [diasDeAntecedencia] dias corridos antes e no dia —
/// menos os que já ficaram para trás.
PlanoLembretesDarf planejarLembretesDarf({
  required Catalogo catalogo,
  required String hoje,
  int competencias = competenciasNoHorizonteDoLembrete,
  int diasDeAntecedencia = diasDeAntecedenciaDoLembrete,
}) {
  var competencia = _competenciaAnterior(hoje.substring(0, 7));
  final lembretes = <LembreteVencimento>[];
  var vencimentosNoPlano = 0;
  while (vencimentosNoPlano < competencias) {
    final String vencimento;
    try {
      vencimento = catalogo.vencimentoDarfDe(competencia);
    } on StateError catch (e) {
      return PlanoLembretesDarf(
        lembretes: List.unmodifiable(lembretes),
        falhaDeCalendario: FalhaDeCalendario(
          competencia: competencia,
          motivo: e.message,
        ),
      );
    }
    if (vencimento.compareTo(hoje) >= 0) {
      vencimentosNoPlano++;
      final antecedencia = _diasAntes(vencimento, diasDeAntecedencia);
      for (final (data, noDia) in [(antecedencia, false), (vencimento, true)]) {
        if (data.compareTo(hoje) >= 0) {
          lembretes.add(
            LembreteVencimento(
              competencia: competencia,
              vencimento: vencimento,
              dataDoAviso: data,
              noDia: noDia,
            ),
          );
        }
      }
    }
    competencia = competenciaSeguinte(competencia);
  }
  return PlanoLembretesDarf(lembretes: List.unmodifiable(lembretes));
}

String _competenciaAnterior(String competencia) {
  final ano = int.parse(competencia.substring(0, 4));
  final mes = int.parse(competencia.substring(5, 7));
  final anoAnterior = mes == 1 ? ano - 1 : ano;
  final mesAnterior = mes == 1 ? 12 : mes - 1;
  return '$anoAnterior-${mesAnterior.toString().padLeft(2, '0')}';
}

String _diasAntes(String data, int dias) {
  var resultado = data;
  for (var i = 0; i < dias; i++) {
    resultado = diaAnterior(resultado);
  }
  return resultado;
}
