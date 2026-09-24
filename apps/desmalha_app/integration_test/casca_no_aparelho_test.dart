/// A casca com o sistema visual, NO APARELHO — onde a fonte embarcada, a
/// barra de abas e a área de toque de verdade aparecem (o host de teste
/// desenha com uma fonte de teste, não com as do app).
///
///   fvm flutter test integration_test/casca_no_aparelho_test.dart
///
/// Com `--dart-define=CAPTURA=true`, o teste pausa em cada tela e imprime
/// `CAPTURA:<tela>` no log, para a captura de tela por `adb exec-out
/// screencap` — é assim que as provas visuais dos cards de UI são tiradas.
library;

import 'package:desmalha_app/auth/porta_auth.dart';
import 'package:desmalha_app/auth/servico_auth.dart';
import 'package:desmalha_app/navegacao/abas.dart';
import 'package:desmalha_app/navegacao/casca.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:desmalha_app/tema/tipografia.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/auth/porta_auth_falsa.dart';

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

  testWidgets('as cinco abas no aparelho, com as fontes do app', (
    tester,
  ) async {
    // As três famílias carregam do binário, não da rede.
    for (final a in [
      'assets/fonts/Fraunces.ttf',
      'assets/fonts/Karla.ttf',
      'assets/fonts/IBMPlexMono-Regular.ttf',
    ]) {
      expect((await rootBundle.load(a)).lengthInBytes, greaterThan(50000));
    }

    final porta = PortaAuthFalsa(
      usuarioInicial: const UsuarioAutenticado(
        id: 'uid-vitrine',
        email: 'pessoa@exemplo.com',
      ),
    );
    final servico = ServicoAutenticacao(porta);

    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: CascaDoApp(construir: (aba) => conteudoDaAba(aba, servico)),
      ),
    );
    await _marcar(tester, 'mes');
    expect(find.text('Seu mês'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Seu mês')).style?.fontFamily ??
          Theme.of(tester.element(find.text('Seu mês')))
              .textTheme
              .headlineMedium!
              .fontFamily,
      FamiliasDesmalha.fraunces,
    );

    await tester.tap(find.text('Ajustes'));
    await _marcar(tester, 'ajustes');
    expect(find.text('Sua conta'), findsOneWidget);

    await tester.tap(find.text('Lançamentos'));
    await _marcar(tester, 'lancamentos');

    await servico.descartar();
    await porta.fechar();
  });
}
