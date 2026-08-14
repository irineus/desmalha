import 'dart:convert';
import 'dart:io';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

/// Runner table-driven dos cenários de `cenarios/cenarios_carne_leao.json`
/// (spec "Especificar regras de cálculo do carnê-leão", seção 9).
///
/// As fixtures são JSON para serem reutilizáveis fora do Dart — inclusive na
/// conferência manual contra o Carnê-Leão Web dos cenários `oficial: true`
/// (critério de aceite nº 1 do MVP, Fase 7). Cada mês declara em `esperado`
/// apenas os campos relevantes ao cenário; só esses são conferidos.
void main() {
  final raiz = jsonDecode(
    File('cenarios/cenarios_carne_leao.json').readAsStringSync(),
  ) as Map<String, Object?>;

  final tabelas = [
    for (final t in raiz['tabelas']! as List<Object?>)
      TabelaIrpf.fromJson(t! as Map<String, Object?>),
  ];

  for (final cenarioBruto in raiz['cenarios']! as List<Object?>) {
    final cenario = cenarioBruto! as Map<String, Object?>;
    final numero = cenario['numero'];
    final descricao = cenario['descricao'];

    test('cenário $numero: $descricao', () {
      final meses = cenario['meses']! as List<Object?>;
      final entradas = [
        for (final m in meses) _entrada(m! as Map<String, Object?>),
      ];

      final apuracoes = apurarSequencia(
        entradas: entradas,
        tabelaPara: (competencia) => tabelaVigente(tabelas, competencia),
      );

      for (var i = 0; i < meses.length; i++) {
        final mes = meses[i]! as Map<String, Object?>;
        final esperado = mes['esperado']! as Map<String, Object?>;
        final atual = apuracoes[i];
        for (final entry in esperado.entries) {
          expect(
            _campo(atual, entry.key),
            entry.value,
            reason: 'competência ${atual.competencia}, campo ${entry.key}',
          );
        }
      }
    });
  }
}

EntradaApuracao _entrada(Map<String, Object?> mes) {
  var despesas = 0;
  final lancamentos = mes['despesas'];
  if (lancamentos != null) {
    for (final d in lancamentos as List<Object?>) {
      final lancamento = d! as Map<String, Object?>;
      despesas += DespesaLivroCaixa(
        valorCentavos: lancamento['valorCentavos']! as int,
        sujeitaTravaHomeOffice:
            (lancamento['travaHomeOffice'] as bool?) ?? false,
      ).dedutivelCentavos;
    }
  }
  return EntradaApuracao(
    competencia: mes['competencia']! as String,
    receitaBrutaCentavos: mes['receitaCentavos']! as int,
    despesasDedutiveisCentavos: despesas,
    inssPagoCentavos: (mes['inssPagoCentavos'] as int?) ?? 0,
    numeroDependentes: (mes['dependentes'] as int?) ?? 0,
    irrfRetidoPjCentavos: (mes['irrfPjCentavos'] as int?) ?? 0,
  );
}

Object? _campo(ApuracaoMensal apuracao, String nome) => switch (nome) {
      'versaoTabelaId' => apuracao.versaoTabelaId,
      'cenarioVencedor' => apuracao.cenarioVencedor.name,
      'baseCenarioACentavos' => apuracao.baseCenarioACentavos,
      'impostoCenarioACentavos' => apuracao.impostoCenarioACentavos,
      'baseCenarioBCentavos' => apuracao.baseCenarioBCentavos,
      'impostoCenarioBCentavos' => apuracao.impostoCenarioBCentavos,
      'reducaoRedutorCentavos' => apuracao.reducaoRedutorCentavos,
      'impostoDevidoCentavos' => apuracao.impostoDevidoCentavos,
      'saldoNegativoAnteriorCentavos' =>
        apuracao.saldoNegativoAnteriorCentavos,
      'saldoNegativoNovoCentavos' => apuracao.saldoNegativoNovoCentavos,
      'impostoAcumuladoAnteriorCentavos' =>
        apuracao.impostoAcumuladoAnteriorCentavos,
      'totalParaDarfCentavos' => apuracao.totalParaDarfCentavos,
      'statusDarf' => apuracao.statusDarf.name,
      'valorDarfCentavos' => apuracao.valorDarfCentavos,
      'impostoAcumuladoNovoCentavos' =>
        apuracao.impostoAcumuladoNovoCentavos,
      'irrfRetidoPjCentavos' => apuracao.irrfRetidoPjCentavos,
      _ => throw ArgumentError('campo desconhecido na fixture: "$nome"'),
    };
