import 'dart:math';

import 'package:desmalha_app/backup/chaves_backup.dart';
import 'package:desmalha_app/backup/servico_backup.dart';
import 'package:desmalha_app/backup/tela_backup.dart';
import 'package:desmalha_app/backup/tela_restaurar.dart';
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

  testWidgets('backups antigos de outro código: descartar só depois da '
      'marcação; dá para restaurar se achar o código', (tester) async {
    final c = controladorBackupFalso(chaves: _ChavesFixas(true))
      ..backupsAntigos = true;
    await _montar(tester, TelaBackup(controlador: c));
    expect(find.byKey(const Key('painel_backups_antigos')), findsOneWidget);
    FilledButton descartar() => tester.widget<FilledButton>(
          find.byKey(const Key('botao_descartar_antigos')),
        );
    expect(descartar().onPressed, isNull, reason: 'sem a marcação, não');

    await tester.ensureVisible(find.byKey(const Key('marcar_descarte')));
    await tester.tap(find.byKey(const Key('marcar_descarte')));
    await tester.pumpAndSettle();
    expect(descartar().onPressed, isNotNull);

    await tester.ensureVisible(find.byKey(const Key('botao_restaurar_backup')));
    await tester.tap(find.byKey(const Key('botao_restaurar_backup')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aviso_substitui_dados')), findsOneWidget);
  });

  testWidgets('restaurar: código errado mostra o erro e fica na tela; '
      'certo devolve true', (tester) async {
    bool? resultado;
    final digitados = <String>[];
    await _montar(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              resultado = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => TelaRestaurar(
                    restaurar: (codigo) async {
                      digitados.add(codigo);
                      if (digitados.length == 1) {
                        throw const FalhaBackup(
                          'Esse código não abre o seu backup.',
                        );
                      }
                    },
                  ),
                ),
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('campo_codigo_restauracao')),
      'ERRADO',
    );
    await tester.tap(find.byKey(const Key('botao_restaurar')));
    await tester.pumpAndSettle();
    expect(find.text('Esse código não abre o seu backup.'), findsOneWidget);
    expect(resultado, isNull);

    await tester.tap(find.byKey(const Key('botao_restaurar')));
    await tester.pumpAndSettle();
    expect(resultado, isTrue);
    expect(digitados, ['ERRADO', 'ERRADO']);
  });
}
