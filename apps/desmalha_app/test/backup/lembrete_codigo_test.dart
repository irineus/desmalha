import 'dart:math';

import 'package:desmalha_app/backup/chaves_backup.dart';
import 'package:desmalha_app/backup/lembrete_codigo.dart';
import 'package:desmalha_app/backup/politica_backup.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../servicos_falsos.dart';

void main() {
  final codigo = gerarCodigoRecuperacao(Random(21));
  final grupos = codigo.split('-');
  late CofreEmMemoria cofre;
  late ChavesBackup chaves;
  final confirmadoEm = DateTime(2026, 6, 1);

  // Uma derivação Argon2id real, reaproveitada (a do confirmar).
  setUpAll(() async {
    cofre = CofreEmMemoria();
    chaves = ChavesBackup(cofre: cofre, aleatorio: Random(3));
    await chaves.confirmarCodigo(codigo, agora: confirmadoEm);
  });

  group('regra dos 90 dias', () {
    test('devido só com código confirmado e 90 dias desde a conferência', () {
      bool devido(DateTime? em, {bool confirmado = true}) =>
          lembreteDoCodigoDevido(
            agora: DateTime(2026, 8, 30),
            codigoConfirmado: confirmado,
            conferidoEm: em,
          );
      expect(devido(DateTime(2026, 6, 1)), isTrue, reason: '90 dias');
      expect(devido(DateTime(2026, 6, 2)), isFalse, reason: '89 dias');
      expect(devido(null), isFalse, reason: 'sem data não lembra');
      expect(devido(DateTime(2026, 1, 1), confirmado: false), isFalse);
    });
  });

  group('verificador de grupos', () {
    test('confirmar grava o verificador e a data; confere com a mesma '
        'tolerância do código', () async {
      expect(await chaves.codigoConferidoEm(), confirmadoEm);
      expect(
        await chaves.conferirGrupos({
          1: grupos[1].toLowerCase(),
          3: ' ${grupos[3]} ',
        }),
        isTrue,
      );
      expect(await chaves.conferirGrupos({1: grupos[2], 3: grupos[3]}), isFalse);
      expect(await chaves.conferirGrupos({1: 'XX'}), isFalse);
      expect(await cofre.ler(ChavesBackup.campoGrupos), isNot(contains(grupos[1])),
          reason: 'o grupo nunca vai em claro para o cofre');
    });

    test('aparelho sem verificador (confirmou antes da regra): confere pelo '
        'código inteiro, que grava o verificador', () async {
      await cofre.apagar(ChavesBackup.campoGrupos);
      expect(await chaves.conferirGrupos({0: grupos[0]}), isNull);
      expect(
        await chaves.conferirCodigoCompleto(
          gerarCodigoRecuperacao(Random(99)),
          DateTime(2026, 9, 1),
        ),
        isFalse,
      );
      expect(
        await chaves.conferirCodigoCompleto(codigo, DateTime(2026, 9, 1)),
        isTrue,
      );
      expect(await chaves.conferirGrupos({0: grupos[0]}), isTrue);
      expect(await chaves.codigoConferidoEm(), DateTime(2026, 9, 1));
    });
  });

  group('cartão no Mês', () {
    Future<void> montar(WidgetTester tester, DateTime agora) async {
      final c = controladorBackupFalso(chaves: chaves, relogio: () => agora);
      await tester.runAsync(c.recarregar);
      await tester.pumpWidget(
        MaterialApp(
          theme: temaDesmalha(),
          home: Scaffold(
            body: LembreteCodigo(controlador: c, aleatorio: Random(4)),
          ),
        ),
      );
      await tester.pump();
    }

    Future<void> assentar(WidgetTester tester) async {
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
    }

    setUp(() async {
      await chaves.registrarConferencia(confirmadoEm);
    });

    testWidgets('antes de 90 dias não aparece', (tester) async {
      await montar(tester, DateTime(2026, 8, 1));
      expect(find.byKey(const Key('lembrete_codigo')), findsNothing);
    });

    testWidgets('devido: grupo errado mostra o erro; certos conferem e o '
        'cartão some', (tester) async {
      await montar(tester, DateTime(2026, 9, 5));
      expect(find.byKey(const Key('lembrete_codigo')), findsOneWidget);

      await tester.tap(find.byKey(const Key('botao_conferir_codigo')));
      await tester.pumpAndSettle();
      final pedidos = sortearGruposParaConfirmar(Random(4));
      await tester.enterText(find.byKey(const Key('campo_grupo_0')), 'ZZZZZ');
      await tester.enterText(
          find.byKey(const Key('campo_grupo_1')), grupos[pedidos[1]]);
      await tester.tap(find.byKey(const Key('confirmar_conferencia')));
      await assentar(tester);
      expect(find.byKey(const Key('erro_conferencia')), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('campo_grupo_0')), grupos[pedidos[0]]);
      await tester.tap(find.byKey(const Key('confirmar_conferencia')));
      await assentar(tester);
      expect(find.byKey(const Key('lembrete_codigo')), findsNothing);
      expect(await tester.runAsync(chaves.codigoConferidoEm),
          DateTime(2026, 9, 5));
    });

    testWidgets('"Agora não" some e volta só 90 dias depois', (tester) async {
      await montar(tester, DateTime(2026, 9, 5));
      await tester.tap(find.byKey(const Key('botao_adiar_lembrete')));
      await assentar(tester);
      expect(find.byKey(const Key('lembrete_codigo')), findsNothing);
      expect(await tester.runAsync(chaves.codigoConferidoEm),
          DateTime(2026, 9, 5));
    });
  });
}
