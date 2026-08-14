import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

/// Cenário 15 da spec: vencimento em sábado, domingo e feriado bancário,
/// sempre ANTECIPANDO para o dia útil anterior.
void main() {
  group('vencimentoDarf', () {
    test('último dia útil simples, sem feriado', () {
      // Competência jan/2026 vence em fev/2026: 28/02 é sábado → 27 (sexta).
      expect(vencimentoDarf('2026-01', const {}), '2026-02-27');
    });

    test('fim de semana: mês terminando no domingo antecipa para sexta', () {
      // Competência abr/2026 vence em mai/2026: 31/05 domingo, 30 sábado.
      expect(vencimentoDarf('2026-04', const {}), '2026-05-29');
    });

    test('feriado bancário no último dia útil antecipa mais um dia', () {
      // 29/05/2026 é sexta; declarado feriado, cai para quinta 28/05.
      expect(
        vencimentoDarf('2026-04', const {'2026-05-29'}),
        '2026-05-28',
      );
    });

    test('cadeia de feriados e fim de semana antecipa em sequência', () {
      // Dez/2025: 31/12 (quarta) e 30/12 (terça) feriados → 29 (segunda).
      expect(
        vencimentoDarf('2025-11', const {'2025-12-31', '2025-12-30'}),
        '2025-12-29',
      );
    });

    test('virada de ano: competência de dezembro vence em janeiro', () {
      // 31/01/2027 é domingo, 30 sábado → 29 (sexta).
      expect(vencimentoDarf('2026-12', const {}), '2027-01-29');
    });

    test('mês inteiro feriado denuncia tabela inconsistente', () {
      final fevereiroInteiro = {
        for (var dia = 1; dia <= 28; dia++)
          '2026-02-${dia.toString().padLeft(2, '0')}',
      };
      expect(
        () => vencimentoDarf('2026-01', fevereiroInteiro),
        throwsStateError,
      );
    });
  });

  group('funções de calendário', () {
    test('competenciaSeguinte avança mês e vira ano', () {
      expect(competenciaSeguinte('2026-01'), '2026-02');
      expect(competenciaSeguinte('2026-12'), '2027-01');
    });

    test('ultimoDiaDoMes respeita fevereiro e bissexto', () {
      expect(ultimoDiaDoMes('2026-02'), '2026-02-28');
      expect(ultimoDiaDoMes('2028-02'), '2028-02-29');
      expect(ultimoDiaDoMes('2026-04'), '2026-04-30');
      expect(ultimoDiaDoMes('2026-07'), '2026-07-31');
    });

    test('diaAnterior cruza mês e ano', () {
      expect(diaAnterior('2026-03-01'), '2026-02-28');
      expect(diaAnterior('2026-01-01'), '2025-12-31');
    });
  });

  test('código de receita do carnê-leão é 0190', () {
    expect(codigoReceitaCarneLeao, '0190');
  });
}
