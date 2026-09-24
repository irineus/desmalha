/// Tela de DARF NO APARELHO: do Mês ("Ver o DARF") à guia sem código de
/// barras, e o PDF entregue ao compartilhamento REAL do sistema (o roteiro
/// de captura fotografa a folha de compartilhar e manda BACK por adb).
///
///   fvm flutter test integration_test/darf_no_aparelho_test.dart
///
/// Com `--dart-define=CAPTURA=true`, pausa em cada tela.
library;

import 'package:desmalha_app/onboarding/repositorio_onboarding.dart';
import 'package:desmalha_app/painel/tela_darf.dart';
import 'package:desmalha_app/painel/tela_mes.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/lembretes/notificacoes_falsas.dart';
import '../test/servicos_falsos.dart';

const _captura = bool.fromEnvironment('CAPTURA');

Future<void> _marcar(WidgetTester tester, String tela) async {
  await tester.pumpAndSettle();
  if (!_captura) return;
  // ignore: avoid_print
  print('CAPTURA:$tela');
  await Future<void>.delayed(const Duration(seconds: 8));
}

Future<void> _esperar(WidgetTester tester, Finder alvo) async {
  for (var i = 0; i < 300 && alvo.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DARF do mês no aparelho', (tester) async {
    final repo = RepositorioOnboardingMemoria()
      ..perfil = const PerfilDoApp(
        nome: 'Ana Souza',
        cpf: '52998224725',
        onboardingCompleto: true,
      );
    final servicos = servicosFalsos(
      onboarding: controladorOnboardingFalso(repositorio: repo),
      painel: PainelFalso({
        '2026-08': const DadosDoMes(
          receitaTributavelCentavos: 1000000,
          lancamentosClassificados: 4,
        ),
      }),
      catalogo: catalogoDoBundle,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: Scaffold(
          body: TelaMes(
            servicos: servicos,
            relogio: () => DateTime(2026, 9, 24, 10),
          ),
        ),
      ),
    );
    await _esperar(tester, find.byKey(const Key('botao_ver_darf')));
    await _marcar(tester, 'mes-com-darf');
    await tester.tap(find.byKey(const Key('botao_ver_darf')));
    await _esperar(tester, find.byKey(const Key('darf_sem_codigo')));
    await _marcar(tester, 'darf-guia');
    expect(find.text('0190'), findsOneWidget);
    expect(find.text('30/09/2026'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('botao_pdf')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await _marcar(tester, 'darf-acoes');

    if (_captura) {
      // O PDF vai ao compartilhamento real do sistema (share_plus).
      await tester.tap(find.byKey(const Key('botao_pdf')));
      await tester.pump(const Duration(seconds: 3));
      // ignore: avoid_print
      print('CAPTURA:compartilhar-sistema');
      await Future<void>.delayed(const Duration(seconds: 10));
      await tester.pumpAndSettle();
    }
    // A guia continua na tela depois do compartilhamento.
    expect(find.byKey(const Key('aviso_ecac_darf')), findsOneWidget);
    expect(find.byType(TelaDarf), findsOneWidget);
  });
}
