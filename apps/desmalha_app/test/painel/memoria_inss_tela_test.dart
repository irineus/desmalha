import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/despesas/repositorio_despesas.dart';
import 'package:desmalha_app/painel/repositorio_fechamento.dart';
import 'package:desmalha_app/painel/tela_mes.dart';
import 'package:desmalha_app/painel/tela_memoria.dart';
import 'package:desmalha_app/servicos_do_app.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lembretes/notificacoes_falsas.dart';
import '../servicos_falsos.dart';

void main() {
  final catalogo = catalogoDoSeed();
  late BancoLocal banco;
  late RepositorioDespesas despesas;
  late PainelFalso painel;
  late ServicosDoApp servicos;

  setUp(() {
    banco = BancoLocal(NativeDatabase.memory());
    despesas = RepositorioDespesas(banco, catalogo: () async => catalogo);
    painel = PainelFalso();
    servicos = servicosFalsos(
      painel: painel,
      despesas: despesas,
      fechamento: RepositorioFechamento(banco),
      catalogo: () async => catalogo,
    );
  });
  tearDown(() => banco.close());

  Future<void> assentar(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> montar(WidgetTester tester, DateTime hoje) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: Scaffold(body: TelaMes(servicos: servicos, relogio: () => hoje)),
      ),
    );
    await assentar(tester);
  }

  Finder chave(String k) => find.byKey(Key(k), skipOffstage: false);

  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    await tester.ensureVisible(alvo);
    await tester.pump();
    await tester.tap(alvo);
    await assentar(tester);
  }

  String valorEm(WidgetTester tester, String k) => tester
      .widget<Text>(find
          .descendant(of: chave(k), matching: find.textContaining('R\$'))
          .last)
      .data!;

  test('percentual em pontos-base', () {
    expect(
      [2750, 2250, 750, 1500, 0].map(percentualDe),
      ['27,5%', '22,5%', '7,5%', '15%', '0%'],
    );
  });

  testWidgets('M10: cenário 2 na ordem do cálculo, com o mesmo imposto da '
      'aba Mês e o comparativo com o simplificado', (tester) async {
    // Cenário 2: R$ 8.000 − livro-caixa R$ 3.000 − INSS R$ 200 − 2
    // dependentes → base R$ 4.420,82 → 22,5% − R$ 675,49 = R$ 319,19.
    painel.dados['2026-01'] = const DadosDoMes(
      receitaTributavelCentavos: 800000,
      lancamentosClassificados: 1,
      despesasDedutiveisCentavos: 300000,
      inssDedutivelCentavos: 20000,
      dependentes: 2,
    );
    await montar(tester, DateTime(2026, 2, 10, 10));
    final daAbaMes = valorEm(tester, 'imposto_devido');

    await tocar(tester, chave('botao_memoria'));
    expect(find.text('2 dependentes'), findsOneWidget);
    expect(find.text('Alíquota 22,5%'), findsOneWidget);
    expect(valorEm(tester, 'memoria_base'), 'R\$ 4.420,82');
    expect(valorEm(tester, 'memoria_dependentes'), 'R\$ 379,18');
    expect(valorEm(tester, 'memoria_impostoPelaAliquota'), 'R\$ 994,68');
    expect(valorEm(tester, 'memoria_parcelaDeduzir'), 'R\$ 675,49');
    expect(valorEm(tester, 'memoria_impostoDevido'), 'R\$ 319,19');
    expect(valorEm(tester, 'memoria_impostoDevido'), daAbaMes,
        reason: 'M10 e aba Mês mostram o mesmo imposto');
    expect(
      tester.widget<Text>(chave('memoria_comparativo')).data,
      contains('Pelo desconto simplificado seria R\$ 1.124,29'),
    );
  });

  testWidgets('M1: "Não paguei" fica gravado e a pergunta some',
      (tester) async {
    painel.dados['2026-08'] = const DadosDoMes(
      receitaTributavelCentavos: 600000,
      lancamentosClassificados: 1,
    );
    await montar(tester, DateTime(2026, 9, 24, 10));
    expect(find.text('Você pagou INSS em agosto?'), findsOneWidget);

    await tocar(tester, chave('m1_nao_paguei'));
    expect(chave('pergunta_inss'), findsNothing);
    final r = await tester.runAsync(() => despesas.inssDoMes('2026-08'));
    expect(r!.single.situacao, SituacaoInss.naoPago);
  });

  testWidgets('M1: "Paguei" vem com a guia anterior de referência e grava '
      'principal e acréscimos separados', (tester) async {
    await tester.runAsync(() => despesas.registrarInssPago(
          competencia: '2026-07',
          principalCentavos: 32000,
        ));
    painel.dados['2026-08'] = const DadosDoMes(
      receitaTributavelCentavos: 600000,
      lancamentosClassificados: 1,
    );
    await montar(tester, DateTime(2026, 9, 24, 10));
    expect(
      tester.widget<Text>(chave('pergunta_inss_referencia')).data,
      'Referência: R\$ 320,00. Só entra na dedução se saiu no mês.',
    );

    await tocar(tester, chave('m1_paguei'));
    await tester.enterText(chave('inss_acrescimos'), '12,00');
    await tocar(tester, chave('confirmar_inss'));
    expect(chave('pergunta_inss'), findsNothing);
    final g = (await tester.runAsync(() => despesas.inssDoMes('2026-08')))!
        .single;
    expect((g.principalCentavos, g.acrescimosCentavos), (32000, 1200));
  });
}
