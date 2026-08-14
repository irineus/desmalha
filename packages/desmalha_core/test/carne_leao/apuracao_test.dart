import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

import 'tabela_irpf_test.dart' show tabela2026;

void main() {
  final tabela = tabela2026(
    redutor: const RedutorLei15270(
      tetoCentavos: 31289,
      limiteIsencaoCentavos: 500000,
      limiteTransicaoCentavos: 735000,
      coefACentavos: 97862,
      coefBMilionesimos: 133145,
    ),
  );

  group('trava de home office por lançamento', () {
    test('rubrica de residência deduz 20%, truncando o centavo', () {
      const despesa = DespesaLivroCaixa(
        valorCentavos: 100000,
        sujeitaTravaHomeOffice: true,
      );
      expect(despesa.dedutivelCentavos, 20000);
      // 99,99 → 20% = 19,998 → trunca para 19,99.
      const quebrada = DespesaLivroCaixa(
        valorCentavos: 9999,
        sujeitaTravaHomeOffice: true,
      );
      expect(quebrada.dedutivelCentavos, 1999);
    });

    test('despesa comum deduz integral', () {
      const despesa = DespesaLivroCaixa(valorCentavos: 12345);
      expect(despesa.dedutivelCentavos, 12345);
    });
  });

  group('empate exato entre cenários', () {
    test('vence o simplificado, preservando o saldo do livro-caixa', () {
      // Receita maior que as despesas do mês, mas saldo anterior grande:
      // o cenário A consumiria parte do saldo para os mesmos R$ 0,00 de
      // imposto; o B preserva os R$ 200,00 integrais.
      final apuracao = apurarMes(
        entrada: EntradaApuracao(
          competencia: '2026-05',
          receitaBrutaCentavos: 10000,
          despesasDedutiveisCentavos: 5000,
        ),
        tabela: tabela,
        saldoNegativoAnteriorCentavos: 20000,
      );
      expect(apuracao.cenarioVencedor, CenarioVencedor.descontoSimplificado);
      expect(apuracao.impostoDevidoCentavos, 0);
      expect(apuracao.saldoNegativoNovoCentavos, 20000);
    });
  });

  group('modo de ajuste final (contraprova pendente — spec, seção 7)', () {
    // Receita R$ 5.555,55: imposto final exato de R$ 213,13995475.
    final entrada = EntradaApuracao(
      competencia: '2026-01',
      receitaBrutaCentavos: 555555,
    );

    test('truncar (padrão) descarta a terceira casa', () {
      final apuracao = apurarMes(entrada: entrada, tabela: tabela);
      expect(apuracao.impostoDevidoCentavos, 21313);
    });

    test('arredondarHalfUp sobe a segunda casa', () {
      final apuracao = apurarMes(
        entrada: entrada,
        tabela: tabela,
        modoAjuste: ModoAjusteFinal.arredondarHalfUp,
      );
      expect(apuracao.impostoDevidoCentavos, 21314);
    });
  });

  group('validação de entrada', () {
    test('competência malformada é rejeitada', () {
      expect(
        () => EntradaApuracao(competencia: '2026/01', receitaBrutaCentavos: 0),
        throwsArgumentError,
      );
      expect(
        () => EntradaApuracao(competencia: '2026-13', receitaBrutaCentavos: 0),
        throwsArgumentError,
      );
    });

    test('valores negativos são rejeitados', () {
      expect(
        () => EntradaApuracao(
          competencia: '2026-01',
          receitaBrutaCentavos: -1,
        ),
        throwsArgumentError,
      );
    });

    test('tabela fora de vigência é rejeitada', () {
      expect(
        () => apurarMes(
          entrada: EntradaApuracao(
            competencia: '2025-12',
            receitaBrutaCentavos: 100000,
          ),
          tabela: tabela,
        ),
        throwsArgumentError,
      );
    });
  });

  group('apurarSequencia', () {
    test('competências fora de ordem falham alto', () {
      expect(
        () => apurarSequencia(
          entradas: [
            EntradaApuracao(
              competencia: '2026-02',
              receitaBrutaCentavos: 0,
            ),
            EntradaApuracao(
              competencia: '2026-01',
              receitaBrutaCentavos: 0,
            ),
          ],
          tabelaPara: (_) => tabela,
        ),
        throwsArgumentError,
      );
    });

    test('competência repetida falha alto', () {
      expect(
        () => apurarSequencia(
          entradas: [
            EntradaApuracao(
              competencia: '2026-01',
              receitaBrutaCentavos: 0,
            ),
            EntradaApuracao(
              competencia: '2026-01',
              receitaBrutaCentavos: 0,
            ),
          ],
          tabelaPara: (_) => tabela,
        ),
        throwsArgumentError,
      );
    });

    test('meses não precisam ser contíguos dentro do ano', () {
      // Usuário sem receita em fevereiro simplesmente não tem apuração.
      final apuracoes = apurarSequencia(
        entradas: [
          EntradaApuracao(
            competencia: '2026-01',
            receitaBrutaCentavos: 300000,
            despesasDedutiveisCentavos: 400000,
          ),
          EntradaApuracao(
            competencia: '2026-03',
            receitaBrutaCentavos: 300000,
          ),
        ],
        tabelaPara: (_) => tabela,
      );
      expect(apuracoes[1].saldoNegativoAnteriorCentavos, 100000);
    });
  });
}
