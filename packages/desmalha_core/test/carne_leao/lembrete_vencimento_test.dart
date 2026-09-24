import 'package:desmalha_core/catalogo_arquivos.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

void main() {
  // O catálogo real do repositório: hoje ele publica feriados só de 2026 —
  // exatamente o caso em que o plano precisa parar em vez de adivinhar.
  final catalogo = Catalogo.fromItens(itensDoCatalogoNoRepositorio('.'));

  List<(String, String, bool)> resumo(PlanoLembretesDarf plano) => [
    for (final l in plano.lembretes) (l.competencia, l.dataDoAviso, l.noDia),
  ];

  group('planejarLembretesDarf', () {
    test('24/09/2026: agosto a novembro, e para no calendário de 2027', () {
      final plano = planejarLembretesDarf(
        catalogo: catalogo,
        hoje: '2026-09-24',
      );
      expect(resumo(plano), [
        ('2026-08', '2026-09-27', false),
        ('2026-08', '2026-09-30', true),
        ('2026-09', '2026-10-27', false),
        ('2026-09', '2026-10-30', true),
        ('2026-10', '2026-11-27', false),
        ('2026-10', '2026-11-30', true),
        // Nov/2026 vence em 30/12: 31/12 não abre agência (FEBRABAN).
        ('2026-11', '2026-12-27', false),
        ('2026-11', '2026-12-30', true),
      ]);
      expect(plano.proximoVencimento, '2026-09-30');
      // Dez/2026 vence em jan/2027, que o catálogo ainda não cobre: nenhum
      // aviso com data adivinhada, e a falha diz o ano.
      final falha = plano.falhaDeCalendario!;
      expect(falha.competencia, '2026-12');
      expect(falha.anoDoVencimento, 2027);
      expect(falha.motivo, contains('2027'));
      expect(
        plano.lembretes.where((l) => l.vencimento.startsWith('2027')),
        isEmpty,
      );
    });

    test('o vencimento vem do catálogo, nunca de conta local', () {
      final plano = planejarLembretesDarf(
        catalogo: catalogo,
        hoje: '2026-09-24',
      );
      for (final l in plano.lembretes) {
        expect(l.vencimento, catalogo.vencimentoDarfDe(l.competencia));
      }
    });

    test('aviso de antecedência já passado sai; o do dia fica', () {
      final plano = planejarLembretesDarf(
        catalogo: catalogo,
        hoje: '2026-09-29',
        competencias: 1,
      );
      expect(resumo(plano), [('2026-08', '2026-09-30', true)]);
    });

    test('no próprio dia do vencimento, o aviso do dia ainda entra', () {
      final plano = planejarLembretesDarf(
        catalogo: catalogo,
        hoje: '2026-09-30',
        competencias: 1,
      );
      expect(resumo(plano), [('2026-08', '2026-09-30', true)]);
    });

    test('vencimento do mês já passado: começa na competência corrente', () {
      final plano = planejarLembretesDarf(
        catalogo: catalogo,
        hoje: '2026-10-01',
        competencias: 1,
      );
      expect(resumo(plano), [
        ('2026-09', '2026-10-27', false),
        ('2026-09', '2026-10-30', true),
      ]);
      expect(plano.falhaDeCalendario, isNull);
    });

    test('janeiro: a competência de dezembro do ano anterior', () {
      final plano = planejarLembretesDarf(
        catalogo: catalogo,
        hoje: '2026-01-10',
        competencias: 1,
      );
      expect(resumo(plano), [
        ('2025-12', '2026-01-27', false),
        ('2025-12', '2026-01-30', true),
      ]);
    });

    test('horizonte fechado dentro do calendário: sem falha', () {
      final plano = planejarLembretesDarf(
        catalogo: catalogo,
        hoje: '2026-09-24',
        competencias: 2,
      );
      expect(plano.lembretes, hasLength(4));
      expect(plano.falhaDeCalendario, isNull);
    });

    test('calendário já esgotado: plano vazio com a falha, sem lançar', () {
      final plano = planejarLembretesDarf(
        catalogo: catalogo,
        hoje: '2027-01-05',
      );
      expect(plano.lembretes, isEmpty);
      expect(plano.proximoVencimento, isNull);
      expect(plano.falhaDeCalendario!.competencia, '2026-12');
    });

    test('antecedência configurável cruza o limite do mês', () {
      final plano = planejarLembretesDarf(
        catalogo: catalogo,
        hoje: '2026-10-01',
        competencias: 2,
        diasDeAntecedencia: 30,
      );
      // Set/2026 vence 30/10 → aviso 30/09, já passado; out/2026 vence
      // 30/11 → aviso 31/10.
      expect(resumo(plano), [
        ('2026-09', '2026-10-30', true),
        ('2026-10', '2026-10-31', false),
        ('2026-10', '2026-11-30', true),
      ]);
    });
  });
}
