import 'package:desmalha_app/navegacao/casca.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Uma aba com contador — para provar que trocar de aba não perde estado.
class _AbaContadora extends StatefulWidget {
  const _AbaContadora(this.nome);
  final String nome;
  @override
  State<_AbaContadora> createState() => _AbaContadoraState();
}

class _AbaContadoraState extends State<_AbaContadora> {
  int _n = 0;
  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      onPressed: () => setState(() => _n++),
      child: Text('${widget.nome}: $_n'),
    ),
  );
}

Future<void> _montar(WidgetTester tester) => tester.pumpWidget(
  MaterialApp(
    theme: temaDesmalha(),
    home: CascaDoApp(construir: (aba) => _AbaContadora(aba.name)),
  ),
);

void main() {
  testWidgets('cinco abas fixas, na ordem dos wireframes', (tester) async {
    await _montar(tester);
    final barra = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(
      [for (final d in barra.destinations) (d as NavigationDestination).label],
      ['Mês', 'Lançamentos', 'Despesas', 'Ano', 'Ajustes'],
    );
  });

  testWidgets('abre no Mês — home é o mês', (tester) async {
    await _montar(tester);
    expect(find.text('mes: 0'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });

  testWidgets('trocar de aba não perde o estado da anterior', (tester) async {
    await _montar(tester);
    await tester.tap(find.text('mes: 0'));
    await tester.pump();
    await tester.tap(find.text('Ano'));
    await tester.pumpAndSettle();
    expect(find.text('ano: 0'), findsOneWidget);
    await tester.tap(find.text('Mês'));
    await tester.pumpAndSettle();
    expect(find.text('mes: 1'), findsOneWidget);
  });

  testWidgets('voltar fora do Mês volta para o Mês', (tester) async {
    await _montar(tester);
    await tester.tap(find.text('Despesas'));
    await tester.pumpAndSettle();
    expect(find.text('despesas: 0'), findsOneWidget);

    final voltou = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(voltou, isTrue, reason: 'o voltar foi consumido, o app não fechou');
    expect(find.text('mes: 0'), findsOneWidget);
  });

  testWidgets('área de toque de cada aba tem ao menos 48px', (tester) async {
    await _montar(tester);
    for (final rotulo in ['Mês', 'Lançamentos', 'Despesas', 'Ano', 'Ajustes']) {
      final destino = find.ancestor(
        of: find.text(rotulo),
        matching: find.byType(NavigationDestination),
      );
      final tamanho = tester.getSize(destino);
      expect(tamanho.height, greaterThanOrEqualTo(48), reason: rotulo);
      expect(tamanho.width, greaterThanOrEqualTo(48), reason: rotulo);
    }
  });
}
