/// O caminho da exclusão de conta NO APARELHO, com a porta de exclusão
/// falsa: Ajustes > Sua conta > Excluir minha conta, a confirmação e a
/// falha honesta. A exclusão de verdade, contra o desmalha-dev e com caixa de
/// e-mail real, é o roteiro de conferência do APK final.
///
///   fvm flutter test integration_test/exclusao_no_aparelho_test.dart
///
/// Com `--dart-define=CAPTURA=true`, pausa em cada tela (ver
/// `casca_no_aparelho_test.dart`).
library;

import 'package:desmalha_app/auth/estado_auth.dart';
import 'package:desmalha_app/auth/porta_auth.dart';
import 'package:desmalha_app/auth/portal_auth.dart';
import 'package:desmalha_app/auth/servico_auth.dart';
import 'package:desmalha_app/conta/porta_exclusao_conta.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/auth/porta_auth_falsa.dart';
import '../test/conta/porta_exclusao_falsa.dart';
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

  testWidgets('excluir a conta: explica, confirma e não mente na falha', (
    tester,
  ) async {
    final porta = PortaAuthFalsa(
      usuarioInicial: const UsuarioAutenticado(
        id: 'uid-vitrine',
        email: 'pessoa@exemplo.com',
      ),
    );
    final servico = ServicoAutenticacao(porta);
    final exclusao = PortaExclusaoFalsa()
      ..falhaProgramada = const FalhaExclusaoConta(
        'Não foi possível concluir a exclusão agora. Nada foi dado como '
        'excluído. Tente de novo em alguns minutos.',
      );

    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: PortalAuth(
          servico: servico,
          servicos: servicosFalsos(exclusao: exclusao),
        ),
      ),
    );
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sua conta'));
    await _marcar(tester, 'sua-conta');

    await tester.ensureVisible(find.byKey(const Key('botao_excluir_conta')));
    await tester.tap(find.byKey(const Key('botao_excluir_conta')));
    await _marcar(tester, 'exclusao');

    await tester.ensureVisible(find.byKey(const Key('confirmo_exclusao')));
    await tester.tap(find.byKey(const Key('confirmo_exclusao')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('botao_confirmar_exclusao')),
    );
    await tester.tap(find.byKey(const Key('botao_confirmar_exclusao')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('erro_exclusao')));
    await _marcar(tester, 'falha');

    expect(find.byKey(const Key('erro_exclusao')), findsOneWidget);
    expect(servico.estado, isA<Autenticado>());

    await servico.descartar();
    await porta.fechar();
  });
}
