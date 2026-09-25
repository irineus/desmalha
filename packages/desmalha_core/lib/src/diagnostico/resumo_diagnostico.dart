/// O resumo de diagnóstico que a pessoa manda ao suporte (decisão 11 do
/// owner): com o dado só no aparelho, é a única forma de o suporte olhar um
/// cálculo — e ele tem de sair SEM dado pessoal.
///
/// Leva só números, estados e versões: a apuração do mês (valores e
/// cenários), as versões do motor, do catálogo e do app, as contagens por
/// classificação e por pendência. Nenhum nome, CPF, CNPJ, descrição de
/// extrato ou texto livre — a montagem só aceita valores desse tipo, e o
/// teste percorre o JSON conferindo cada folha.
library;

import 'dart:convert';

import '../carne_leao/apuracao.dart';
import '../carne_leao/painel_mensal.dart';
import '../carne_leao/estados_persistidos.dart';

/// Pendências do mês, em contagens.
class PendenciasDoMes {
  const PendenciasDoMes({
    required this.recebimentosAClassificar,
    required this.documentosPendentes,
    required this.inssRespondido,
  });

  final int recebimentosAClassificar;

  /// Lançamentos com CPF/CNPJ do pagador pendente.
  final int documentosPendentes;

  /// O mês tem resposta de INSS ("paguei" ou "não paguei").
  final bool inssRespondido;
}

class ResumoDiagnostico {
  const ResumoDiagnostico._(this._json);

  final Map<String, Object?> _json;

  Map<String, Object?> toJson() => _json;

  /// O texto que a pessoa vê e compartilha.
  String get texto => const JsonEncoder.withIndent('  ').convert(_json);
}

/// Monta o resumo da [competencia] a partir do [painel] do mês e das
/// contagens. [versaoCatalogo] é o id da tabela do IRPF (ou outra versão
/// do catálogo) — um identificador técnico, nunca dado da pessoa.
ResumoDiagnostico montarResumoDiagnostico({
  required String competencia,
  required PainelMensal painel,
  required Map<ClassificacaoLancamento, int> contagemPorClassificacao,
  required PendenciasDoMes pendencias,
  required bool mesFechado,
  required String versaoApp,
  String? versaoCatalogo,
}) {
  if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(competencia)) {
    throw ArgumentError('competência fora do formato YYYY-MM');
  }
  return ResumoDiagnostico._({
    'formato': 1,
    'competencia': competencia,
    'versoes': {
      'motor': versaoDoMotor,
      'app': versaoApp,
      'catalogo': ?versaoCatalogo,
    },
    'estadoDoMes': switch (painel) {
      PainelSemDados() => 'semDados',
      PainelAClassificar() => 'aClassificar',
      PainelSemTabela() => 'semTabela',
      PainelApurado() => 'apurado',
    },
    'mesFechado': mesFechado,
    'lancamentosPorClassificacao': {
      for (final c in ClassificacaoLancamento.values)
        c.name: contagemPorClassificacao[c] ?? 0,
    },
    'pendencias': {
      'recebimentosAClassificar': pendencias.recebimentosAClassificar,
      'documentosPendentes': pendencias.documentosPendentes,
      'inssRespondido': pendencias.inssRespondido,
    },
    if (painel case PainelApurado(:final apuracao)) 'apuracao': _apuracao(apuracao),
  });
}

Map<String, Object?> _apuracao(ApuracaoMensal a) => {
      'tabelaIrpf': a.versaoTabelaId,
      'receitaBrutaCentavos': a.receitaBrutaCentavos,
      'cenarioVencedor': a.cenarioVencedor.name,
      'baseCenarioACentavos': a.baseCenarioACentavos,
      'impostoCenarioACentavos': a.impostoCenarioACentavos,
      'baseCenarioBCentavos': a.baseCenarioBCentavos,
      'impostoCenarioBCentavos': a.impostoCenarioBCentavos,
      'baseCalculoCentavos': a.baseCalculoCentavos,
      'aliquotaPontosBase': a.aliquotaPontosBase,
      'parcelaDeduzirCentavos': a.parcelaDeduzirCentavos,
      'impostoApuradoCentavos': a.impostoApuradoCentavos,
      'reducaoRedutorCentavos': a.reducaoRedutorCentavos,
      'impostoDevidoCentavos': a.impostoDevidoCentavos,
      'saldoNegativoAnteriorCentavos': a.saldoNegativoAnteriorCentavos,
      'saldoNegativoUtilizadoCentavos': a.saldoNegativoUtilizadoCentavos,
      'saldoNegativoNovoCentavos': a.saldoNegativoNovoCentavos,
      'impostoAcumuladoAnteriorCentavos': a.impostoAcumuladoAnteriorCentavos,
      'totalParaDarfCentavos': a.totalParaDarfCentavos,
      'statusDarf': a.statusDarf.name,
      'valorDarfCentavos': a.valorDarfCentavos,
    };
