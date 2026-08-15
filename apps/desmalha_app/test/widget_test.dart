import 'package:desmalha_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sem configuração de servidor, o app diz isso na tela', (
    tester,
  ) async {
    // Testes e CI rodam sem as variáveis do Supabase de propósito. O que o app
    // NÃO pode fazer é abrir um login que só falharia na rede.
    await tester.pumpWidget(const DesmalhaApp(servico: null));

    expect(find.text('Build sem configuração de servidor'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
