/// Lembrete do DARF NO APARELHO, com o plugin real de notificações:
///
/// - sem permissão: Ajustes diz "desligado", e os avisos ficam agendados
///   mesmo assim (valem se o usuário liberar depois);
/// - com permissão: os ids agendados no Android batem com o plano do core
///   para a data do aparelho, e um aviso de prova agendado para daqui a
///   poucos segundos APARECE (mesmo caminho `zonedSchedule` em UTC).
///
/// A permissão é do sistema e o teste não toca no diálogo; o roteiro a
/// ajusta por adb antes de cada rodada:
///
///   adb shell pm revoke com.desmalha.app android.permission.POST_NOTIFICATIONS
///   adb shell pm grant  com.desmalha.app android.permission.POST_NOTIFICATIONS
///   fvm flutter test integration_test/lembrete_no_aparelho_test.dart
///
/// Com `--dart-define=CAPTURA=true`, pausa em cada tela.
library;

import 'dart:convert';

import 'package:desmalha_app/auth/porta_auth.dart';
import 'package:desmalha_app/auth/servico_auth.dart';
import 'package:desmalha_app/catalogo/repositorio_catalogo.dart';
import 'package:desmalha_app/lembretes/controlador_lembretes.dart';
import 'package:desmalha_app/lembretes/porta_notificacoes_locais.dart';
import 'package:desmalha_app/navegacao/abas.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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

Future<Catalogo> _seed() async => Catalogo.fromJson(
  jsonDecode(await rootBundle.loadString(assetSeedCatalogo))
      as Map<String, Object?>,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('lembrete do DARF com o plugin real', (tester) async {
    final porta = PortaNotificacoesLocais();
    final c = ControladorLembretes(porta: porta, carregarCatalogo: _seed);
    final servico = ServicoAutenticacao(
      PortaAuthFalsa(
        usuarioInicial: const UsuarioAutenticado(
          id: 'uid-vitrine',
          email: 'pessoa@exemplo.com',
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: Scaffold(
          body: TelaAjustes(
            servico: servico,
            servicos: servicosFalsos(lembretes: c),
          ),
        ),
      ),
    );
    await tester.runAsync(c.sincronizar);
    await tester.pumpAndSettle();
    expect(c.erro, isNull);

    // Os ids agendados no Android = o plano do core para hoje no aparelho.
    final agora = DateTime.now();
    final plano = planejarLembretesDarf(
      catalogo: await tester.runAsync(_seed) as Catalogo,
      hoje:
          '${agora.year}-${agora.month.toString().padLeft(2, '0')}-'
          '${agora.day.toString().padLeft(2, '0')}',
    );
    final esperados = {
      for (final l in plano.lembretes)
        if (instanteDoAviso(l).isAfter(agora.add(const Duration(minutes: 1))))
          idDoLembrete(l),
    };
    final noAndroid = (await tester.runAsync(porta.agendadas))!
        .where(ehIdDeLembreteDarf)
        .toSet();
    // ignore: avoid_print
    print('LEMBRETES_AGENDADOS:${noAndroid.toList()..sort()}');
    expect(esperados, isNotEmpty);
    expect(noAndroid, esperados);

    final item = find.byKey(const Key('item_lembrete_darf'));
    if (!c.permitidas) {
      await _marcar(tester, 'lembrete-desligado');
      expect(
        find.descendant(of: item, matching: find.text('desligado')),
        findsOneWidget,
      );
      return;
    }

    await _marcar(tester, 'lembrete-em-dia');
    expect(
      find.descendant(of: item, matching: find.textContaining('Próximo:')),
      findsOneWidget,
    );

    // Aviso de prova: o mesmo `agendar` dos lembretes, para daqui a 5 s.
    final prova = plano.lembretes.first;
    await tester.runAsync(
      () => porta.agendar(
        id: 1,
        instante: DateTime.now().add(const Duration(seconds: 5)),
        titulo: tituloDoLembrete(prova),
        corpo: corpoDoLembrete(prova),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 70)),
    );
    await _marcar(tester, 'notificacao');
  });
}
