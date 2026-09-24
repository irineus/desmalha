import 'dart:math';

import 'package:desmalha_app/backup/chaves_backup.dart';
import 'package:desmalha_app/backup/tela_backup.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../servicos_falsos.dart';

/// Chaves com "código confirmado" controlado, sem Argon2id no teste de tela.
class _ChavesFixas extends ChavesBackup {
  _ChavesFixas(this.confirmado)
    : super(cofre: CofreEmMemoria(), aleatorio: Random(1));
  final bool confirmado;
  @override
  Future<bool> codigoConfirmado() async => confirmado;
}

Future<void> _montar(WidgetTester tester, Widget tela) async {
  await tester.pumpWidget(MaterialApp(theme: temaDesmalha(), home: tela));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sem código: DESLIGADO escrito, botão de backup inativo', (
    tester,
  ) async {
    final c = controladorBackupFalso(chaves: _ChavesFixas(false));
    await _montar(tester, TelaBackup(controlador: c));
    expect(find.byKey(const Key('aviso_backup_desligado')), findsOneWidget);
    expect(find.text('desligado'), findsOneWidget);
    final botao = tester.widget<FilledButton>(
      find.byKey(const Key('botao_backup_agora')),
    );
    expect(botao.onPressed, isNull);
    expect(find.text('Confirmar o código de recuperação'), findsOneWidget);
  });

  testWidgets('com código e nunca feito: desatualizado e botão ativo', (
    tester,
  ) async {
    final c = controladorBackupFalso(chaves: _ChavesFixas(true));
    await _montar(tester, TelaBackup(controlador: c));
    expect(find.text('desatualizado'), findsOneWidget);
    expect(find.text('nunca'), findsOneWidget);
    final botao = tester.widget<FilledButton>(
      find.byKey(const Key('botao_backup_agora')),
    );
    expect(botao.onPressed, isNotNull);
  });

  testWidgets('aviso no Mês: aparece desligado; some quando em dia', (
    tester,
  ) async {
    final desligado = controladorBackupFalso(chaves: _ChavesFixas(false));
    await desligado.recarregar();
    await _montar(tester, Scaffold(body: AvisoBackup(controlador: desligado)));
    expect(find.byKey(const Key('aviso_backup_mes')), findsOneWidget);
    expect(find.textContaining('Backup desligado'), findsOneWidget);
  });
}
