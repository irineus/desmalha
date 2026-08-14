import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

/// Tabela de referência dos testes: a progressiva mensal vigente em 2026,
/// com o redutor da Lei 15.270/2025.
TabelaIrpf tabela2026({RedutorLei15270? redutor}) => TabelaIrpf(
      id: 'irpf-mensal-2026-01',
      vigenciaInicio: '2026-01',
      valorDependenteCentavos: 18959,
      descontoSimplificadoCentavos: 60720,
      faixas: const [
        FaixaIrpf(
          limiteSuperiorCentavos: 242880,
          aliquotaPontosBase: 0,
          parcelaDeduzirCentavos: 0,
        ),
        FaixaIrpf(
          limiteSuperiorCentavos: 282665,
          aliquotaPontosBase: 750,
          parcelaDeduzirCentavos: 18216,
        ),
        FaixaIrpf(
          limiteSuperiorCentavos: 375105,
          aliquotaPontosBase: 1500,
          parcelaDeduzirCentavos: 39416,
        ),
        FaixaIrpf(
          limiteSuperiorCentavos: 466468,
          aliquotaPontosBase: 2250,
          parcelaDeduzirCentavos: 67549,
        ),
        FaixaIrpf(
          limiteSuperiorCentavos: null,
          aliquotaPontosBase: 2750,
          parcelaDeduzirCentavos: 90873,
        ),
      ],
      redutor: redutor,
    );

void main() {
  final tabela = tabela2026();

  group('seleção de faixa no centavo dos limites (cenário 17 da spec)', () {
    // Um centavo abaixo/acima de cada limite cai na faixa certa e o imposto
    // não dá salto: no limite as fórmulas das faixas vizinhas praticamente
    // coincidem (a parcela a deduzir existe para isso).
    const limites = [242880, 282665, 375105, 466468];

    for (final limite in limites) {
      test('limite $limite: centavo abaixo, exato e acima', () {
        final faixaDoLimite = tabela.faixaPara(limite);
        expect(tabela.faixaPara(limite - 1), same(faixaDoLimite));

        final faixaSeguinte = tabela.faixaPara(limite + 1);
        expect(faixaSeguinte, isNot(same(faixaDoLimite)));

        // As parcelas a deduzir oficiais deixam resíduos de fração de
        // centavo nos limites (até negativos, como em 466468 → 466469);
        // o que não pode haver é salto de um centavo inteiro.
        final impostoNoLimite =
            tabela.impostoProgressivoMicroCentavos(limite);
        final impostoAcima =
            tabela.impostoProgressivoMicroCentavos(limite + 1);
        expect((impostoAcima - impostoNoLimite).abs(),
            lessThan(microCentavosPorCentavo));
      });
    }

    test('base zero e topo da primeira faixa são isentos', () {
      expect(tabela.impostoProgressivoMicroCentavos(0), 0);
      expect(tabela.impostoProgressivoMicroCentavos(242880), 0);
    });

    test('parcela a deduzir nunca deixa imposto negativo', () {
      // Um centavo dentro da faixa de 7,5%: alíquota × base < parcela.
      expect(tabela.impostoProgressivoMicroCentavos(242881),
          greaterThanOrEqualTo(0));
    });
  });

  group('redutor da Lei 15.270/2025', () {
    const redutor = RedutorLei15270(
      tetoCentavos: 31289,
      limiteIsencaoCentavos: 500000,
      limiteTransicaoCentavos: 735000,
      coefACentavos: 97862,
      coefBMilionesimos: 133145,
    );

    test('até o limite de isenção vale o teto', () {
      expect(redutor.reducaoMicroCentavos(500000),
          31289 * microCentavosPorCentavo);
      expect(redutor.reducaoMicroCentavos(1),
          31289 * microCentavosPorCentavo);
    });

    test('faixa de transição: exemplo oficial de R\$ 6.000 → R\$ 179,75', () {
      expect(redutor.reducaoMicroCentavos(600000),
          17975 * microCentavosPorCentavo);
    });

    test('fórmula da transição nunca fica negativa dentro da faixa', () {
      // No teto da transição a fórmula chega perto de zero, mas não cruza.
      final noTeto = redutor.reducaoMicroCentavos(735000);
      expect(noTeto, greaterThanOrEqualTo(0));
      expect(noTeto, lessThan(microCentavosPorCentavo));
    });

    test('acima da transição não há redutor', () {
      expect(redutor.reducaoMicroCentavos(735001), 0);
    });
  });

  group('vigência por competência', () {
    final v2025 = TabelaIrpf(
      id: 'irpf-mensal-2025-05',
      vigenciaInicio: '2025-05',
      vigenciaFim: '2025-12',
      valorDependenteCentavos: 18959,
      descontoSimplificadoCentavos: 60720,
      faixas: tabela.faixas,
    );

    test('seleciona a versão vigente no mês apurado', () {
      expect(tabelaVigente([v2025, tabela], '2025-07').id, v2025.id);
      expect(tabelaVigente([v2025, tabela], '2026-03').id, tabela.id);
      expect(tabelaVigente([v2025, tabela], '2027-01').id, tabela.id);
    });

    test('competência sem versão vigente falha alto', () {
      expect(() => tabelaVigente([v2025], '2026-01'), throwsStateError);
    });

    test('duas versões vigentes no mesmo mês falham alto', () {
      final sobreposta = TabelaIrpf(
        id: 'irpf-duplicada',
        vigenciaInicio: '2026-01',
        valorDependenteCentavos: 18959,
        descontoSimplificadoCentavos: 60720,
        faixas: tabela.faixas,
      );
      expect(
        () => tabelaVigente([tabela, sobreposta], '2026-05'),
        throwsStateError,
      );
    });
  });

  group('validação estrutural', () {
    test('última faixa precisa ser aberta', () {
      expect(
        () => TabelaIrpf(
          id: 'x',
          vigenciaInicio: '2026-01',
          valorDependenteCentavos: 0,
          descontoSimplificadoCentavos: 0,
          faixas: const [
            FaixaIrpf(
              limiteSuperiorCentavos: 100,
              aliquotaPontosBase: 0,
              parcelaDeduzirCentavos: 0,
            ),
          ],
        ),
        throwsFormatException,
      );
    });

    test('limites precisam ser crescentes', () {
      expect(
        () => TabelaIrpf(
          id: 'x',
          vigenciaInicio: '2026-01',
          valorDependenteCentavos: 0,
          descontoSimplificadoCentavos: 0,
          faixas: const [
            FaixaIrpf(
              limiteSuperiorCentavos: 200,
              aliquotaPontosBase: 0,
              parcelaDeduzirCentavos: 0,
            ),
            FaixaIrpf(
              limiteSuperiorCentavos: 100,
              aliquotaPontosBase: 750,
              parcelaDeduzirCentavos: 0,
            ),
            FaixaIrpf(
              limiteSuperiorCentavos: null,
              aliquotaPontosBase: 1500,
              parcelaDeduzirCentavos: 0,
            ),
          ],
        ),
        throwsFormatException,
      );
    });
  });

  group('JSON do catálogo versionado', () {
    test('round-trip fromJson/toJson preserva a tabela', () {
      final original = tabela2026(
        redutor: const RedutorLei15270(
          tetoCentavos: 31289,
          limiteIsencaoCentavos: 500000,
          limiteTransicaoCentavos: 735000,
          coefACentavos: 97862,
          coefBMilionesimos: 133145,
        ),
      );
      final reconstruida = TabelaIrpf.fromJson(original.toJson());
      expect(reconstruida.toJson(), original.toJson());
    });

    test('campo obrigatório ausente falha alto com o nome do campo', () {
      expect(
        () => TabelaIrpf.fromJson(const {
          'id': 'x',
          'valorDependenteCentavos': 0,
          'descontoSimplificadoCentavos': 0,
          'faixas': [
            {
              'limiteSuperiorCentavos': null,
              'aliquotaPontosBase': 0,
              'parcelaDeduzirCentavos': 0,
            },
          ],
        }),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('vigenciaInicio'),
        )),
      );
    });

    test('faixa malformada falha alto', () {
      expect(
        () => FaixaIrpf.fromJson(const {'aliquotaPontosBase': 750}),
        throwsFormatException,
      );
    });
  });
}
