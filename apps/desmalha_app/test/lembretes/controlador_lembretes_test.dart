import 'package:desmalha_app/lembretes/controlador_lembretes.dart';
import 'package:flutter_test/flutter_test.dart';

import 'notificacoes_falsas.dart';

void main() {
  group('ControladorLembretes.sincronizar', () {
    test(
      '24/09/2026 10h: agosto a novembro, 3 dias antes e no dia, às 9h',
      () async {
        final porta = NotificacoesFalsas();
        final c = controladorLembretesFalso(
          porta: porta,
          catalogo: catalogoDoSeed(),
        );
        await c.sincronizar();

        expect(c.erro, isNull);
        expect(porta.avisos.keys.toList()..sort(), [
          2026080, 2026081, //
          2026090, 2026091,
          2026100, 2026101,
          2026110, 2026111,
        ]);
        expect(porta.avisos[2026080]!.instante, DateTime(2026, 9, 27, 9));
        expect(porta.avisos[2026081]!.instante, DateTime(2026, 9, 30, 9));
        // Nov/2026 vence 30/12 (31/12 não abre agência) — vem do catálogo.
        expect(porta.avisos[2026111]!.instante, DateTime(2026, 12, 30, 9));
        expect(c.agendados.first.vencimento, '2026-09-30');
        expect(c.falhaDeCalendario!.anoDoVencimento, 2027);
      },
    );

    test('texto fala da data e do código, nunca de valor', () async {
      final porta = NotificacoesFalsas();
      await controladorLembretesFalso(
        porta: porta,
        catalogo: catalogoDoSeed(),
      ).sincronizar();

      expect(
        porta.avisos[2026080]!.titulo,
        'Carnê-leão: o DARF vence em 3 dias',
      );
      expect(
        porta.avisos[2026080]!.corpo,
        'Competência agosto/2026: quarta, 30/09, é o vencimento (código '
        '0190). Abra o Desmalha para conferir se há imposto a pagar.',
      );
      expect(porta.avisos[2026081]!.titulo, 'Carnê-leão: o DARF vence hoje');
      expect(
        porta.avisos[2026081]!.corpo,
        'Competência agosto/2026: hoje, quarta, 30/09, é o último dia '
        '(código 0190). Abra o Desmalha para conferir se há imposto a pagar.',
      );
      for (final aviso in porta.avisos.values) {
        expect(aviso.corpo, isNot(contains(r'R$')));
      }
    });

    test('aviso cujo instante já passou não é agendado', () async {
      final porta = NotificacoesFalsas();
      final c = controladorLembretesFalso(
        porta: porta,
        catalogo: catalogoDoSeed(),
        agora: DateTime(2026, 9, 30, 10), // depois das 9h do vencimento
      );
      await c.sincronizar();
      expect(porta.avisos.containsKey(2026081), isFalse);
      expect(c.agendados.first.vencimento, '2026-10-30');
    });

    test('às 8h do vencimento o aviso do dia ainda entra', () async {
      final porta = NotificacoesFalsas();
      await controladorLembretesFalso(
        porta: porta,
        catalogo: catalogoDoSeed(),
        agora: DateTime(2026, 9, 30, 8),
      ).sincronizar();
      expect(porta.avisos[2026081]!.instante, DateTime(2026, 9, 30, 9));
    });

    test(
      'reagendar substitui: tira aviso velho do DARF, preserva os outros',
      () async {
        final porta = NotificacoesFalsas();
        final velho = (
          instante: DateTime(2026, 8, 31, 9),
          titulo: 'x',
          corpo: 'x',
        );
        porta.avisos[2026071] = velho; // competência já vencida
        porta.avisos[42] = velho; // não é lembrete do DARF
        final c = controladorLembretesFalso(
          porta: porta,
          catalogo: catalogoDoSeed(),
        );
        await c.sincronizar();
        await c.sincronizar();
        expect(porta.avisos.containsKey(2026071), isFalse);
        expect(porta.avisos.containsKey(42), isTrue);
        expect(porta.avisos.keys.where(ehIdDeLembreteDarf), hasLength(8));
      },
    );

    test('sem permissão ainda agenda (vale se o usuário liberar depois), e '
        'diz que está desligado', () async {
      final porta = NotificacoesFalsas(permitido: false);
      final c = controladorLembretesFalso(
        porta: porta,
        catalogo: catalogoDoSeed(),
      );
      await c.sincronizar();
      expect(c.permitidas, isFalse);
      expect(porta.avisos, hasLength(8));
    });

    test('permitir() pede ao sistema e ressincroniza', () async {
      final porta = NotificacoesFalsas(permitido: false);
      final c = controladorLembretesFalso(
        porta: porta,
        catalogo: catalogoDoSeed(),
      );
      await c.sincronizar();
      expect(await c.permitir(), isTrue);
      expect(porta.pedidosDePermissao, 1);
      expect(c.permitidas, isTrue);
    });

    test('permissão negada: permitir() devolve false', () async {
      final porta = NotificacoesFalsas(permitido: false, concedeAoPedir: false);
      final c = controladorLembretesFalso(
        porta: porta,
        catalogo: catalogoDoSeed(),
      );
      expect(await c.permitir(), isFalse);
      expect(c.permitidas, isFalse);
    });

    test('calendário esgotado: nada agendado, falha com o ano', () async {
      final porta = NotificacoesFalsas();
      final c = controladorLembretesFalso(
        porta: porta,
        catalogo: catalogoDoSeed(),
        agora: DateTime(2027, 1, 5, 10),
      );
      await c.sincronizar();
      expect(porta.avisos, isEmpty);
      expect(c.agendados, isEmpty);
      expect(c.falhaDeCalendario!.anoDoVencimento, 2027);
      expect(c.erro, isNull);
    });

    test('catálogo ilegível vira erro visível, não exceção', () async {
      final c = ControladorLembretes(
        porta: NotificacoesFalsas(),
        carregarCatalogo: () async => throw const FormatException('seed'),
        relogio: () => DateTime(2026, 9, 24, 10),
      );
      await c.sincronizar();
      expect(c.carregado, isTrue);
      expect(c.erro, contains('Não foi possível agendar'));
    });
  });

  group('formatação', () {
    test('competência e data por extenso', () {
      expect(competenciaPorExtenso('2026-03'), 'março/2026');
      expect(competenciaPorExtenso('2025-12'), 'dezembro/2025');
      expect(dataCurta('2026-10-30'), 'sexta, 30/10');
      expect(dataCurta('2026-11-30'), 'segunda, 30/11');
    });
  });
}
