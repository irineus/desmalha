import 'package:desmalha_app/auth/porta_auth.dart';
import 'package:desmalha_app/auth/servico_auth.dart';
import 'package:desmalha_app/lembretes/controlador_lembretes.dart';
import 'package:desmalha_app/navegacao/abas.dart';
import 'package:desmalha_app/tema/componentes.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/porta_auth_falsa.dart';
import '../servicos_falsos.dart';
import 'notificacoes_falsas.dart';

Future<void> _montar(WidgetTester tester, ControladorLembretes c) async {
  final servico = ServicoAutenticacao(
    PortaAuthFalsa(
      usuarioInicial: const UsuarioAutenticado(
        id: 'uid',
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
}

Finder _noItem(Finder f) => find.descendant(
  of: find.byKey(const Key('item_lembrete_darf')),
  matching: f,
);

void main() {
  testWidgets('em dia: próximo vencimento, sem selo', (tester) async {
    await _montar(tester, controladorLembretesFalso());
    expect(
      _noItem(
        find.textContaining(
          'Próximo: quarta, 30/09 (competência '
          'agosto/2026)',
        ),
      ),
      findsOneWidget,
    );
    expect(
      _noItem(find.textContaining('falta o calendário de feriados de 2027')),
      findsOneWidget,
    );
    expect(_noItem(find.byType(Selo)), findsNothing);
  });

  testWidgets('sem permissão: desligado, em vermelho, e o toque pede', (
    tester,
  ) async {
    final porta = NotificacoesFalsas(permitido: false);
    final c = controladorLembretesFalso(porta: porta);
    await _montar(tester, c);
    expect(_noItem(find.text('desligado')), findsOneWidget);
    expect(_noItem(find.textContaining('não autorizou')), findsOneWidget);

    await tester.tap(find.byKey(const Key('item_lembrete_darf')));
    await tester.runAsync(() async {
      while (c.permitidas == false) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();
    expect(porta.pedidosDePermissao, 1);
    expect(_noItem(find.text('desligado')), findsNothing);
    expect(_noItem(find.textContaining('Próximo:')), findsOneWidget);
  });

  testWidgets('permissão negada: explica onde liberar', (tester) async {
    final c = controladorLembretesFalso(
      porta: NotificacoesFalsas(permitido: false, concedeAoPedir: false),
    );
    await _montar(tester, c);
    await tester.tap(find.byKey(const Key('item_lembrete_darf')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Configurações > Apps > Desmalha > Notificações'),
      findsOneWidget,
    );
  });

  testWidgets('sem calendário do ano: falha visível, nunca data adivinhada', (
    tester,
  ) async {
    await _montar(
      tester,
      controladorLembretesFalso(agora: DateTime(2027, 1, 5, 10)),
    );
    expect(_noItem(find.text('sem calendário')), findsOneWidget);
    expect(
      _noItem(
        find.textContaining(
          'calendário de feriados de 2027 ainda não '
          'foi publicado',
        ),
      ),
      findsOneWidget,
    );
    expect(_noItem(find.textContaining('Próximo:')), findsNothing);
  });
}
