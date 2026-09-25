import 'dart:convert';
import 'dart:io';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

/// Runner table-driven de `cenarios/cenarios_relatorio_anual.json`: as
/// regras do relatório anual (P1, P10–P12 da rodada 4; P13 e P15 da
/// rodada 5), cada uma com seu caso.
void main() {
  final tabelas = [
    for (final t in (jsonDecode(
      File('cenarios/cenarios_carne_leao.json').readAsStringSync(),
    ) as Map<String, Object?>)['tabelas']! as List<Object?>)
      TabelaIrpf.fromJson(t! as Map<String, Object?>),
  ];
  final casos = (jsonDecode(
    File('cenarios/cenarios_relatorio_anual.json').readAsStringSync(),
  ) as Map<String, Object?>)['casos']! as List<Object?>;

  for (final bruto in casos) {
    final caso = bruto! as Map<String, Object?>;
    test(caso['descricao'], () {
      final meses = (caso['meses']! as Map<String, Object?>).map(
        (c, v) {
          final m = v! as Map<String, Object?>;
          return MapEntry(
            c,
            DadosDoMes(
              receitaTributavelCentavos: (m['receitaCentavos'] as int?) ?? 0,
              despesasDedutiveisCentavos: (m['despesasCentavos'] as int?) ?? 0,
              inssDedutivelCentavos: (m['inssCentavos'] as int?) ?? 0,
              dependentes: (m['dependentes'] as int?) ?? 0,
              lancamentosClassificados: 1,
            ),
          );
        },
      );
      final r = montarRelatorioAnual(
        ano: caso['ano']! as int,
        dadosDoAno: meses,
        guiasPagas: [
          for (final g in ((caso['guiasPagas'] as List<Object?>?) ?? [])
              .cast<Map<String, Object?>>())
            GuiaPagaDoRelatorio(
              periodo: g['periodo']! as String,
              principalCentavos: g['principalCentavos']! as int,
            ),
        ],
        recebimentosPj: [
          for (final p in ((caso['recebimentosPj'] as List<Object?>?) ?? [])
              .cast<Map<String, Object?>>())
            RecebimentoPj(
              cnpj: p['cnpj'] as String?,
              nome: p['nome'] as String?,
              valorCentavos: p['valorCentavos']! as int,
            ),
        ],
        tabelaPara: (c) => tabelaVigente(tabelas, c),
      );

      expect(r.meses.map((m) => m.competencia), [
        for (var m = 1; m <= 12; m++)
          '${caso['ano']}-${m.toString().padLeft(2, '0')}',
      ]);

      final esperado = caso['esperado']! as Map<String, Object?>;
      final porMes = {for (final m in r.meses) m.competencia: m};
      for (final e in ((esperado['meses'] as Map<String, Object?>?) ?? {})
          .entries) {
        final linha = porMes[e.key]!;
        for (final campo in (e.value! as Map<String, Object?>).entries) {
          expect(
            switch (campo.key) {
              'receitasCentavos' => linha.receitasCentavos,
              'livroCaixaCentavos' => linha.livroCaixaCentavos,
              'inssCentavos' => linha.inssCentavos,
              'dependentes' => linha.dependentes,
              'deducaoDependentesCentavos' => linha.deducaoDependentesCentavos,
              'impostoPagoCentavos' => linha.impostoPagoCentavos,
              _ => throw ArgumentError('campo desconhecido: ${campo.key}'),
            },
            campo.value,
            reason: '${e.key}, ${campo.key}',
          );
        }
      }
      for (final t in ((esperado['totais'] as Map<String, Object?>?) ?? {})
          .entries) {
        expect(
          switch (t.key) {
            'receitasCentavos' => r.totalReceitasCentavos,
            'livroCaixaCentavos' => r.totalLivroCaixaCentavos,
            'inssCentavos' => r.totalInssCentavos,
            'dependentesCentavos' => r.totalDependentesCentavos,
            'impostoPagoCentavos' => r.totalImpostoPagoCentavos,
            'pjCentavos' => r.totalPjCentavos,
            _ => throw ArgumentError('total desconhecido: ${t.key}'),
          },
          t.value,
          reason: 'total ${t.key}',
        );
      }
      if (esperado['fontesPj'] case final List<Object?> fontes) {
        expect(
          [
            for (final f in r.fontesPj)
              {'cnpj': f.cnpj, 'nome': f.nome, 'totalCentavos': f.totalCentavos},
          ],
          fontes,
        );
      }
      if (esperado['vazio'] case final bool vazio) {
        expect(r.vazio, vazio);
      }
    });
  }

  test('guia com principal não positivo é recusada', () {
    expect(
      () => montarRelatorioAnual(
        ano: 2026,
        dadosDoAno: const {},
        guiasPagas: const [
          GuiaPagaDoRelatorio(periodo: '2026-01', principalCentavos: 0),
        ],
        recebimentosPj: const [],
        tabelaPara: (c) => tabelaVigente(tabelas, c),
      ),
      throwsArgumentError,
    );
  });

  test('o PDF sai com as colunas e a seção de PJ, e é determinístico', () {
    final r = montarRelatorioAnual(
      ano: 2026,
      dadosDoAno: const {
        '2026-03': DadosDoMes(
          receitaTributavelCentavos: 700000,
          lancamentosClassificados: 1,
        ),
      },
      guiasPagas: const [
        GuiaPagaDoRelatorio(periodo: '2026-03', principalCentavos: 80268),
      ],
      recebimentosPj: const [
        RecebimentoPj(
          cnpj: '11222333000181',
          nome: 'Clinica',
          valorCentavos: 200000,
        ),
      ],
      tabelaPara: (c) => tabelaVigente(tabelas, c),
    );
    final a = gerarPdfRelatorioAnual(r, aviso: 'Outras rendas.');
    final b = gerarPdfRelatorioAnual(r, aviso: 'Outras rendas.');
    expect(a, b);
    final texto = latin1.decode(a);
    for (final trecho in [
      'Relat',
      '7.000,00',
      '802,68',
      '11.222.333/0001-81',
      'Outras rendas.',
      'Preparado pelo app Desmalha',
    ]) {
      expect(texto, contains(trecho), reason: trecho);
    }
  });

  test('CNPJ formatado', () {
    expect(cnpjFormatado('11222333000181'), '11.222.333/0001-81');
    expect(cnpjFormatado('123'), '123');
  });
}
