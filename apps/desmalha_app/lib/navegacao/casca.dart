/// A casca do app: as cinco abas fixas dos wireframes (ago/2026).
///
/// Mês · Lançamentos · Despesas · Ano · Ajustes — nesta ordem, e a primeira
/// é a casa: "home é o mês, não a caixa de entrada" (decisão de estrutura nº
/// 1 dos wireframes). A barra não muda de tamanho nem de ordem conforme o
/// estado: aba que some ou troca de lugar é aba que a pessoa de pouca
/// familiaridade com o celular deixa de achar.
library;

import 'package:flutter/material.dart';

/// As abas, na ordem da barra.
enum AbaDoApp {
  mes('Mês', Icons.calendar_today_outlined, Icons.calendar_today),
  lancamentos('Lançamentos', Icons.swap_vert, Icons.swap_vert),
  despesas('Despesas', Icons.receipt_long_outlined, Icons.receipt_long),
  ano('Ano', Icons.date_range_outlined, Icons.date_range),
  ajustes('Ajustes', Icons.tune_outlined, Icons.tune);

  const AbaDoApp(this.rotulo, this.icone, this.iconeAtivo);

  /// Sentence case, como tudo no app.
  final String rotulo;
  final IconData icone;
  final IconData iconeAtivo;
}

/// Scaffold com a barra de abas. O conteúdo de cada aba vem de [construir],
/// para que o porteiro (e os testes) decidam o que mora em cada uma.
class CascaDoApp extends StatefulWidget {
  const CascaDoApp({super.key, required this.construir, this.inicial});

  final Widget Function(AbaDoApp aba) construir;

  /// Aba aberta no início; `null` = [AbaDoApp.mes], a casa.
  final AbaDoApp? inicial;

  @override
  State<CascaDoApp> createState() => _CascaDoAppState();
}

class _CascaDoAppState extends State<CascaDoApp> {
  late AbaDoApp _atual = widget.inicial ?? AbaDoApp.mes;

  // Cada aba é construída uma vez e mantida viva: trocar de aba não perde
  // rolagem nem formulário a meio caminho.
  late final List<Widget> _paginas = [
    for (final aba in AbaDoApp.values)
      KeyedSubtree(key: ValueKey(aba), child: widget.construir(aba)),
  ];

  @override
  Widget build(BuildContext context) => PopScope(
    // "Voltar" fora da casa volta para o Mês antes de fechar o app.
    canPop: _atual == AbaDoApp.mes,
    onPopInvokedWithResult: (saiu, _) {
      if (!saiu) setState(() => _atual = AbaDoApp.mes);
    },
    child: Scaffold(
      body: IndexedStack(index: _atual.index, children: _paginas),
      bottomNavigationBar: DecoratedBox(
        // O filete de topo da barra (`border-top: 1px solid var(--linha)`).
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _atual.index,
          onDestinationSelected: (i) =>
              setState(() => _atual = AbaDoApp.values[i]),
          destinations: [
            for (final aba in AbaDoApp.values)
              NavigationDestination(
                icon: Icon(aba.icone),
                selectedIcon: Icon(aba.iconeAtivo),
                label: aba.rotulo,
              ),
          ],
        ),
      ),
    ),
  );
}
