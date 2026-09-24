/// O código de recuperação NO APARELHO, com Argon2id de verdade (64 MiB):
/// Ajustes mostra "pendente", a pessoa gera, anota, confirma dois grupos, e
/// Ajustes passa a mostrar "confirmado". O cofre é em memória — o
/// Keystore real da chave-mestra segue o mesmo adaptador da chave do banco,
/// provado em `cifra_no_aparelho_test.dart`.
///
///   fvm flutter test integration_test/codigo_recuperacao_no_aparelho_test.dart
///
/// Com `--dart-define=CAPTURA=true`, pausa em cada tela.
library;

import 'dart:math';

import 'package:desmalha_app/auth/estado_auth.dart';
import 'package:desmalha_app/auth/porta_auth.dart';
import 'package:desmalha_app/auth/portal_auth.dart';
import 'package:desmalha_app/auth/servico_auth.dart';
import 'package:desmalha_app/backup/chaves_backup.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/auth/porta_auth_falsa.dart';
import '../test/servicos_falsos.dart';

const _captura = bool.fromEnvironment('CAPTURA');

Future<void> _marcar(WidgetTester tester, String tela) async {
  await tester.pumpAndSettle();
  if (!_captura) return;
  // ignore: avoid_print
  print('CAPTURA:$tela');
  await Future<void>.delayed(const Duration(seconds: 8));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('gerar, anotar, confirmar — com a derivação real', (
    tester,
  ) async {
    final porta = PortaAuthFalsa(
      usuarioInicial: const UsuarioAutenticado(
        id: 'uid-vitrine',
        email: 'pessoa@exemplo.com',
      ),
    );
    final servico = ServicoAutenticacao(porta);
    final chaves = ChavesBackup(cofre: CofreEmMemoria(), aleatorio: Random());

    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: PortalAuth(
          servico: servico,
          servicos: servicosFalsos(chavesBackup: chaves),
        ),
      ),
    );
    await tester.tap(find.text('Ajustes'));
    await _marcar(tester, 'ajustes-pendente');
    expect(find.textContaining('backup automático está desligado'),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('item_codigo_recuperacao')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao_gerar_codigo')));
    await _marcar(tester, 'codigo-mostrado');
    final codigo = normalizarCodigoRecuperacao(
      tester
          .widget<SelectableText>(find.byKey(const Key('codigo_recuperacao')))
          .data!,
    )!;

    await tester.tap(find.byKey(const Key('botao_ja_anotei')));
    await tester.pumpAndSettle();
    final partes = codigo.split('-');
    for (var i = 0; i < 2; i++) {
      final rotulo = tester
          .widget<TextField>(find.byKey(Key('campo_grupo_$i')))
          .decoration!
          .labelText!;
      final grupo = int.parse(rotulo.substring(0, 1)) - 1;
      await tester.enterText(find.byKey(Key('campo_grupo_$i')), partes[grupo]);
    }
    await _marcar(tester, 'confirmacao');

    final relogio = Stopwatch()..start();
    await tester.tap(
      find.byKey(const Key('botao_confirmar_codigo_recuperacao')),
    );
    // A derivação roda de verdade: espera o "pronto" aparecer.
    for (var i = 0; i < 200 && find.text('código confirmado').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // ignore: avoid_print
    print('CONFIRMACAO_MS: ${relogio.elapsedMilliseconds}');
    await _marcar(tester, 'pronto');
    expect(find.text('código confirmado'), findsOneWidget);
    expect(await chaves.codigoConfirmado(), isTrue);

    await tester.tap(find.byKey(const Key('botao_concluir_codigo')));
    await _marcar(tester, 'ajustes-confirmado');
    expect(find.textContaining('Confirmado. Abre seus backups'), findsOneWidget);

    await servico.descartar();
    await porta.fechar();
  });
}
