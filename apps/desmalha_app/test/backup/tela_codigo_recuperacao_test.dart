import 'dart:math';

import 'package:desmalha_app/backup/chaves_backup.dart';
import 'package:desmalha_app/backup/tela_codigo_recuperacao.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../servicos_falsos.dart';

/// Chaves que registram a confirmação sem rodar o Argon2id de 64 MiB — a
/// derivação real é coberta em chaves_backup_test e no aparelho.
class _ChavesRegistradoras extends ChavesBackup {
  _ChavesRegistradoras() : super(cofre: CofreEmMemoria(), aleatorio: Random(1));
  final confirmados = <String>[];
  @override
  Future<bool> codigoConfirmado() async => confirmados.isNotEmpty;
  @override
  Future<void> confirmarCodigo(String codigoCanonico, {DateTime? agora}) async =>
      confirmados.add(codigoCanonico);
}

void main() {
  late _ChavesRegistradoras chaves;

  setUp(() => chaves = _ChavesRegistradoras());

  Future<String> ateOCodigo(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: TelaCodigoRecuperacao(chaves: chaves, aleatorio: Random(42)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao_gerar_codigo')));
    await tester.pumpAndSettle();
    final mostrado = tester
        .widget<SelectableText>(find.byKey(const Key('codigo_recuperacao')))
        .data!;
    return normalizarCodigoRecuperacao(mostrado)!;
  }

  List<int> gruposPedidos(WidgetTester tester) => [
    for (var i = 0; i < 2; i++)
      int.parse(
            RegExp(r'^(\d)º')
                .firstMatch(
                  tester
                      .widget<TextField>(find.byKey(Key('campo_grupo_$i')))
                      .decoration!
                      .labelText!,
                )!
                .group(1)!,
          ) -
          1,
  ];

  testWidgets('mostra o código, pede dois grupos e confirma o CANÔNICO', (
    tester,
  ) async {
    final codigo = await ateOCodigo(tester);
    await tester.tap(find.byKey(const Key('botao_ja_anotei')));
    await tester.pumpAndSettle();

    // O código some da tela na confirmação: não dá para copiar dele.
    expect(find.byKey(const Key('codigo_recuperacao')), findsNothing);

    final grupos = gruposPedidos(tester);
    final partes = codigo.split('-');
    // Digitado com a tolerância da mão: minúsculas, O no lugar de 0.
    for (var i = 0; i < 2; i++) {
      await tester.enterText(
        find.byKey(Key('campo_grupo_$i')),
        partes[grupos[i]].toLowerCase().replaceAll('0', 'o'),
      );
    }
    await tester.tap(
      find.byKey(const Key('botao_confirmar_codigo_recuperacao')),
    );
    await tester.pumpAndSettle();

    expect(chaves.confirmados, [codigo]);
    expect(find.text('código confirmado'), findsOneWidget);
  });

  testWidgets('grupo errado não confirma nada e diz o que fazer', (
    tester,
  ) async {
    await ateOCodigo(tester);
    await tester.tap(find.byKey(const Key('botao_ja_anotei')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('campo_grupo_0')), 'ZZZZZ');
    await tester.enterText(find.byKey(const Key('campo_grupo_1')), 'ZZZZZ');
    await tester.tap(
      find.byKey(const Key('botao_confirmar_codigo_recuperacao')),
    );
    await tester.pumpAndSettle();

    expect(chaves.confirmados, isEmpty);
    expect(find.byKey(const Key('erro_codigo')), findsOneWidget);
  });

  testWidgets('"perdi a anotação" gera OUTRO código — o primeiro não volta', (
    tester,
  ) async {
    final primeiro = await ateOCodigo(tester);
    await tester.tap(find.byKey(const Key('botao_ja_anotei')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao_gerar_outro')));
    await tester.pumpAndSettle();
    final segundo = normalizarCodigoRecuperacao(
      tester
          .widget<SelectableText>(find.byKey(const Key('codigo_recuperacao')))
          .data!,
    )!;
    expect(segundo, isNot(primeiro));
  });

  testWidgets('com código já confirmado, avisa o que gerar outro significa', (
    tester,
  ) async {
    chaves.confirmados.add('JA-EXISTE');
    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: TelaCodigoRecuperacao(chaves: chaves),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('já tem um código confirmado'), findsOneWidget);
    expect(find.textContaining('os já enviados continuam'), findsOneWidget);
  });
}
