import 'package:desmalha_core/catalogo_arquivos.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

void main() {
  // O catálogo real: tabela do IRPF desde 2026-01, feriados só de 2026.
  final catalogo = Catalogo.fromItens(itensDoCatalogoNoRepositorio('.'));

  DadosDoMes classificado(int receita, {int n = 1, int aClassificar = 0}) =>
      DadosDoMes(
        receitaTributavelCentavos: receita,
        lancamentosClassificados: n,
        recebimentosAClassificar: aClassificar,
      );

  /// O motor direto, sobre os mesmos meses — a referência. O motor é o que
  /// fecha os cenários oficiais; o painel não pode divergir dele.
  ApuracaoMensal motor(Map<String, int> receitas, String competencia) =>
      apurarSequencia(
        entradas: [
          for (final e in receitas.entries)
            EntradaApuracao(competencia: e.key, receitaBrutaCentavos: e.value),
        ],
        tabelaPara: catalogo.tabelaVigentePara,
      ).firstWhere((a) => a.competencia == competencia);

  group('sem lançamento classificado não há imposto', () {
    test('mês vazio: sem dados, mesmo com outros meses apurados', () {
      final p = montarPainelMensal(
        competencia: '2026-09',
        dadosDoAno: {'2026-08': classificado(1000000)},
        catalogo: catalogo,
      );
      expect(p, isA<PainelSemDados>());
    });

    test('recebimentos importados e nenhum classificado: a classificar', () {
      final p = montarPainelMensal(
        competencia: '2026-08',
        dadosDoAno: {'2026-08': const DadosDoMes(recebimentosAClassificar: 7)},
        catalogo: catalogo,
      );
      expect(p, isA<PainelAClassificar>());
      expect((p as PainelAClassificar).recebimentosAClassificar, 7);
    });

    test('recebimento a classificar NÃO entra na receita', () {
      final sem =
          montarPainelMensal(
                competencia: '2026-08',
                dadosDoAno: {'2026-08': classificado(1000000)},
                catalogo: catalogo,
              )
              as PainelApurado;
      final com =
          montarPainelMensal(
                competencia: '2026-08',
                dadosDoAno: {
                  '2026-08': classificado(1000000, aClassificar: 12),
                },
                catalogo: catalogo,
              )
              as PainelApurado;
      expect(
        com.apuracao.impostoDevidoCentavos,
        sem.apuracao.impostoDevidoCentavos,
      );
      expect(com.apuracao.receitaBrutaCentavos, 1000000);
      expect(com.recebimentosAClassificar, 12);
    });

    test('tudo classificado como pessoal: apurado, sem imposto', () {
      final p =
          montarPainelMensal(
                competencia: '2026-08',
                dadosDoAno: {'2026-08': classificado(0, n: 3)},
                catalogo: catalogo,
              )
              as PainelApurado;
      expect(p.apuracao.statusDarf, StatusDarf.semImposto);
      expect(p.apuracao.valorDarfCentavos, 0);
    });
  });

  group('o resultado é o do motor', () {
    test('mês isolado', () {
      final p =
          montarPainelMensal(
                competencia: '2026-08',
                dadosDoAno: {'2026-08': classificado(1000000)},
                catalogo: catalogo,
              )
              as PainelApurado;
      final ref = motor({'2026-08': 1000000}, '2026-08');
      expect(p.apuracao.impostoDevidoCentavos, ref.impostoDevidoCentavos);
      expect(p.apuracao.valorDarfCentavos, ref.valorDarfCentavos);
      expect(p.apuracao.statusDarf, StatusDarf.emitido);
      expect(p.apuracao.valorDarfCentavos, greaterThan(0));
    });

    test('encadeado desde janeiro; mês vazio no meio não muda nada', () {
      // Varre receitas até achar uma que só acumule (abaixo do DARF
      // mínimo) — o valor depende da tabela publicada, não se fixa aqui.
      final pequena = [for (var r = 500000; r <= 900000; r += 100) r]
          .firstWhere(
            (r) =>
                motor({'2026-03': r}, '2026-03').statusDarf ==
                StatusDarf.acumulaParaProximoMes,
          );
      final dados = {
        '2026-03': classificado(pequena),
        '2026-05': classificado(1000000),
      };
      final p =
          montarPainelMensal(
                competencia: '2026-05',
                dadosDoAno: dados,
                catalogo: catalogo,
              )
              as PainelApurado;
      // Referência com o mês vazio (abril) DENTRO da sequência: igual.
      final ref = motor({
        '2026-03': pequena,
        '2026-04': 0,
        '2026-05': 1000000,
      }, '2026-05');
      expect(p.apuracao.impostoAcumuladoAnteriorCentavos, greaterThan(0));
      expect(
        p.apuracao.impostoAcumuladoAnteriorCentavos,
        ref.impostoAcumuladoAnteriorCentavos,
      );
      expect(p.apuracao.valorDarfCentavos, ref.valorDarfCentavos);
      expect(
        [for (final m in p.evolucao) m.apuracao == null],
        [true, true, false, true, false],
      );
    });

    test('mês SÓ com despesa entra na cadeia: o saldo negativo passa ao '
        'seguinte', () {
      final p = montarPainelMensal(
        competencia: '2026-05',
        dadosDoAno: {
          '2026-04': const DadosDoMes(despesasDedutiveisCentavos: 300000),
          '2026-05': const DadosDoMes(
            receitaTributavelCentavos: 1000000,
            lancamentosClassificados: 1,
          ),
        },
        catalogo: catalogo,
      ) as PainelApurado;
      final ref = apurarSequencia(
        entradas: [
          EntradaApuracao(
              competencia: '2026-04',
              receitaBrutaCentavos: 0,
              despesasDedutiveisCentavos: 300000),
          EntradaApuracao(competencia: '2026-05', receitaBrutaCentavos: 1000000),
        ],
        tabelaPara: catalogo.tabelaVigentePara,
      ).last;
      expect(p.apuracao.saldoNegativoAnteriorCentavos, 300000);
      expect(p.apuracao.impostoDevidoCentavos, ref.impostoDevidoCentavos);
    });

    test('INSS e dependentes do mês entram no cálculo (cenário 2)', () {
      final p = montarPainelMensal(
        competencia: '2026-01',
        dadosDoAno: {
          '2026-01': const DadosDoMes(
            receitaTributavelCentavos: 800000,
            lancamentosClassificados: 1,
            despesasDedutiveisCentavos: 300000,
            inssDedutivelCentavos: 20000,
            dependentes: 2,
          ),
        },
        catalogo: catalogo,
      ) as PainelApurado;
      // Cenário 2 oficial: R$ 319,19.
      expect(p.apuracao.impostoDevidoCentavos, 31919);
    });

    test('meses de outro ano não entram (e não precisariam de tabela)', () {
      final p = montarPainelMensal(
        competencia: '2026-08',
        dadosDoAno: {
          '2025-12': classificado(99999999),
          '2026-08': classificado(1000000),
        },
        catalogo: catalogo,
      );
      expect(p, isA<PainelApurado>());
      expect((p as PainelApurado).apuracao.impostoAcumuladoAnteriorCentavos, 0);
    });

    test('guia paga zera o acumulado: o mês seguinte não recobra o que ela '
        'cobriu', () {
      // Março pago; a correção o deixa em R$ 5,36 (abaixo do mínimo).
      final dados = {
        '2026-03': classificado(501500),
        '2026-04': classificado(503500),
      };
      final semGuia = montarPainelMensal(
        competencia: '2026-04',
        dadosDoAno: dados,
        catalogo: catalogo,
      ) as PainelApurado;
      final comGuia = montarPainelMensal(
        competencia: '2026-04',
        dadosDoAno: dados,
        catalogo: catalogo,
        periodosQuitados: {'2026-03'},
      ) as PainelApurado;
      expect(semGuia.apuracao.totalParaDarfCentavos, 1789);
      expect(comGuia.apuracao.totalParaDarfCentavos, 1253);
    });

    test('período quitado entra no encadeamento mesmo sem dado', () {
      final p = montarPainelMensal(
        competencia: '2026-04',
        dadosDoAno: {'2026-04': classificado(503500)},
        catalogo: catalogo,
        periodosQuitados: {'2026-03'},
      ) as PainelApurado;
      expect(p.evolucao.firstWhere((m) => m.competencia == '2026-03').apuracao,
          isNotNull);
    });
  });

  group('falha visível', () {
    test('sem tabela do IRPF publicada para o mês', () {
      final p = montarPainelMensal(
        competencia: '2025-06',
        dadosDoAno: {'2025-06': classificado(1000000)},
        catalogo: catalogo,
      );
      expect(p, isA<PainelSemTabela>());
    });

    test('vencimento: do catálogo; sem feriados do ano, nulo com motivo', () {
      final ago =
          montarPainelMensal(
                competencia: '2026-08',
                dadosDoAno: {'2026-08': classificado(1000000)},
                catalogo: catalogo,
              )
              as PainelApurado;
      expect(ago.vencimento, '2026-09-30');
      final dez =
          montarPainelMensal(
                competencia: '2026-12',
                dadosDoAno: {'2026-12': classificado(1000000)},
                catalogo: catalogo,
              )
              as PainelApurado;
      expect(dez.vencimento, isNull);
      expect(dez.motivoSemVencimento, contains('2027'));
    });
  });
}
