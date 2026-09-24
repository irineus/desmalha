import 'package:desmalha_app/auth/porta_auth.dart';
import 'package:desmalha_app/auth/portal_auth.dart';
import 'package:desmalha_app/auth/servico_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'porta_auth_falsa.dart';

/// Texto do widget de uma chave — evita casar por acaso com o mesmo endereço
/// escrito em outro canto da tela.
String _textoDaChave(WidgetTester tester, String chave) =>
    tester.widget<Text>(find.byKey(Key(chave))).data!;

void main() {
  late PortaAuthFalsa porta;
  late ServicoAutenticacao servico;

  setUp(() {
    porta = PortaAuthFalsa();
    servico = ServicoAutenticacao(porta);
  });

  tearDown(() async {
    await servico.descartar();
    await porta.fechar();
  });

  Future<void> montar(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(home: PortalAuth(servico: servico)),
  );

  /// Entra na conta pelo caminho do usuário: e-mail, código, e então
  /// Ajustes > Sua conta — é lá que a conta mora desde que o app tem abas.
  Future<void> entrarPelaTela(
    WidgetTester tester, {
    String email = 'pessoa@exemplo.com',
  }) async {
    await tester.enterText(find.byKey(const Key('campo_email')), email);
    await tester.tap(find.byKey(const Key('botao_enviar_codigo')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('campo_codigo')), '12345678');
    await tester.tap(find.byKey(const Key('botao_confirmar_codigo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sua conta'));
    await tester.pumpAndSettle();
  }

  testWidgets('a tela de entrada não oferece senha nem provedor social', (
    tester,
  ) async {
    await montar(tester);

    expect(find.byKey(const Key('campo_email')), findsOneWidget);
    // Um único campo, e ele não esconde o que se digita: campo mascarado na
    // tela de entrada só existiria para uma coisa.
    final campos = tester.widgetList<TextField>(find.byType(TextField));
    expect(campos, hasLength(1));
    expect(campos.every((c) => !c.obscureText), isTrue);

    for (final proibido in ['Google', 'Apple', 'Facebook', 'Continuar com']) {
      expect(find.textContaining(proibido), findsNothing);
    }
  });

  testWidgets('pedir o código leva à tela de digitação', (tester) async {
    await montar(tester);

    await tester.enterText(
      find.byKey(const Key('campo_email')),
      'pessoa@exemplo.com',
    );
    await tester.tap(find.byKey(const Key('botao_enviar_codigo')));
    await tester.pumpAndSettle();

    expect(porta.chamadas, ['enviarCodigo']);
    expect(find.byKey(const Key('campo_codigo')), findsOneWidget);
    expect(find.textContaining('pessoa@exemplo.com'), findsOneWidget);
    expect(find.textContaining('$tamanhoCodigoOtp dígitos'), findsOneWidget);
  });

  testWidgets('e-mail inválido mostra o motivo e não chama o servidor', (
    tester,
  ) async {
    await montar(tester);

    await tester.enterText(find.byKey(const Key('campo_email')), 'nao-e-email');
    await tester.tap(find.byKey(const Key('botao_enviar_codigo')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('erro_auth')), findsOneWidget);
    expect(porta.chamadas, isEmpty);
    expect(find.byKey(const Key('campo_codigo')), findsNothing);
  });

  testWidgets('entrar com o código abre o app no Mês', (tester) async {
    await montar(tester);

    await tester.enterText(
      find.byKey(const Key('campo_email')),
      'pessoa@exemplo.com',
    );
    await tester.tap(find.byKey(const Key('botao_enviar_codigo')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('campo_codigo')), '12345678');
    await tester.tap(find.byKey(const Key('botao_confirmar_codigo')));
    await tester.pumpAndSettle();

    // Home é o mês, não a caixa de entrada nem a conta.
    expect(find.text('Seu mês'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sua conta'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('email_da_conta')), findsOneWidget);
    expect(find.text('pessoa@exemplo.com'), findsOneWidget);
  });

  testWidgets('a troca de e-mail só se conclui com as duas confirmações', (
    tester,
  ) async {
    await montar(tester);
    await entrarPelaTela(tester);

    await tester.enterText(
      find.byKey(const Key('campo_novo_email')),
      'novo@exemplo.com',
    );
    await tester.tap(find.byKey(const Key('botao_solicitar_troca')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('campo_codigo_atual')), findsOneWidget);
    expect(find.byKey(const Key('campo_codigo_novo')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('campo_codigo_atual')),
      '11111111',
    );
    await tester.tap(find.byKey(const Key('botao_confirmar_atual')));
    await tester.pumpAndSettle();

    // Um lado confirmado não muda a conta.
    expect(_textoDaChave(tester, 'email_da_conta'), 'pessoa@exemplo.com');
    expect(find.byKey(const Key('campo_codigo_novo')), findsOneWidget);

    porta.recargaProgramada = () =>
        const UsuarioAutenticado(id: 'uid-teste', email: 'novo@exemplo.com');
    await tester.enterText(
      find.byKey(const Key('campo_codigo_novo')),
      '22222222',
    );
    await tester.tap(find.byKey(const Key('botao_confirmar_novo')));
    await tester.pumpAndSettle();

    expect(_textoDaChave(tester, 'email_da_conta'), 'novo@exemplo.com');
    expect(find.byKey(const Key('aviso_conta')), findsOneWidget);
  });

  testWidgets('sair devolve à tela de entrada', (tester) async {
    await montar(tester);
    await entrarPelaTela(tester);

    expect(find.byKey(const Key('email_da_conta')), findsOneWidget);

    await tester.tap(find.byKey(const Key('botao_sair')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('campo_email')), findsOneWidget);
    expect(porta.chamadas, contains('sair'));
  });
}
