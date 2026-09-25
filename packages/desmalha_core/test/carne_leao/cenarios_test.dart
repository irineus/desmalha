import 'dart:convert';
import 'dart:io';

import 'package:desmalha_core/catalogo_arquivos.dart';
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

  // Despesa com "rubrica" é resolvida pelo catálogo REAL do repositório:
  // a trava de 20% e a vedação vêm da rubrica publicada, não da fixture.
  final catalogo = Catalogo.fromItens(itensDoCatalogoNoRepositorio('.'));

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
        for (final m in meses)
          _entrada(m! as Map<String, Object?>, catalogo),
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

EntradaApuracao _entrada(Map<String, Object?> mes, Catalogo catalogo) {
  var despesas = 0;
  final lancamentos = mes['despesas'];
  if (lancamentos != null) {
    for (final d in lancamentos as List<Object?>) {
      final lancamento = d! as Map<String, Object?>;
      final valor = lancamento['valorCentavos']! as int;
      final idRubrica = lancamento['rubrica'] as String?;
      if (idRubrica != null) {
        final rubrica = catalogo.rubricaPorId(idRubrica);
        if (rubrica == null) {
          throw ArgumentError('rubrica "$idRubrica" não está no catálogo');
        }
        despesas += rubrica.despesa(valor).dedutivelCentavos;
        continue;
      }
      despesas += DespesaLivroCaixa(
        valorCentavos: valor,
        sujeitaTravaHomeOffice:
            (lancamento['travaHomeOffice'] as bool?) ?? false,
      ).dedutivelCentavos;
    }
  }
  // Lançamentos classificados: a receita sai da regra da classificação do
  // core (totaisDoMes), não de um número pronto na fixture.
  var receita = (mes['receitaCentavos'] as int?) ?? 0;
  final classificados = mes['lancamentos'] as List<Object?>?;
  if (classificados != null) {
    receita += totaisDoMes(lancamentos: [
      for (final l in classificados.cast<Map<String, Object?>>())
        LancamentoClassificado(
          valorCentavos: l['valorCentavos']! as int,
          classificacao: ClassificacaoLancamento.values
              .byName(l['classificacao']! as String),
          titular: switch (l['titular'] as String?) {
            null => null,
            final t => TitularComprovante.values.byName(t),
          },
          custoEssencial: l['essencial'] as bool?,
        ),
    ]).receitaTributavelCentavos;
  }
  return EntradaApuracao(
    competencia: mes['competencia']! as String,
    receitaBrutaCentavos: receita,
    despesasDedutiveisCentavos: despesas,
    inssPagoCentavos: (mes['inssPagoCentavos'] as int?) ?? 0,
    numeroDependentes: (mes['dependentes'] as int?) ?? 0,
    irrfRetidoPjCentavos: (mes['irrfPjCentavos'] as int?) ?? 0,
  );
}

Object? _campo(ApuracaoMensal apuracao, String nome) => switch (nome) {
      'versaoTabelaId' => apuracao.versaoTabelaId,
      'receitaBrutaCentavos' => apuracao.receitaBrutaCentavos,
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
      'baseCalculoCentavos' => apuracao.baseCalculoCentavos,
      'aliquotaPontosBase' => apuracao.aliquotaPontosBase,
      'parcelaDeduzirCentavos' => apuracao.parcelaDeduzirCentavos,
      'impostoApuradoCentavos' => apuracao.impostoApuradoCentavos,
      'saldoNegativoUtilizadoCentavos' =>
        apuracao.saldoNegativoUtilizadoCentavos,
      _ => throw ArgumentError('campo desconhecido na fixture: "$nome"'),
    };
