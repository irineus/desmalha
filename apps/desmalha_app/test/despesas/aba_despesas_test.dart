import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/despesas/aba_despesas.dart';
import 'package:desmalha_app/despesas/repositorio_despesas.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lembretes/notificacoes_falsas.dart';
import '../servicos_falsos.dart';

void main() {
  late BancoLocal banco;
  late RepositorioDespesas despesas;

  setUp(() {
    banco = BancoLocal(NativeDatabase.memory());
    despesas =
        RepositorioDespesas(banco, catalogo: () async => catalogoDoSeed());
  });
  tearDown(() => banco.close());

  Future<void> assentar(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    // Duas vezes: a rota que sai (pop depois da escrita) termina a animação.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> sql(WidgetTester tester, String s) =>
      tester.runAsync(() => banco.customStatement(s)).then((_) {});

  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: Scaffold(
          body: AbaDespesas(
            servicos: servicosFalsos(
              despesas: despesas,
              catalogo: () async => catalogoDoSeed(),
            ),
            hoje: () => DateTime(2026, 8, 15),
          ),
        ),
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

  testWidgets('M9: IPTU da casa mostra "deduz 20%" antes de salvar e entra '
      'no livro-caixa do mês', (tester) async {
    await montar(tester);
    expect(find.textContaining('Nenhuma despesa em agosto/2026'),
        findsOneWidget);

    await tocar(tester, find.text('Adicionar despesa'));
    await tocar(tester, chave('rubrica_iptu-residencia'));
    await tester.enterText(chave('valor_despesa'), '2.400,00');
    await tester.pump();
    expect(find.text('Deduz 20%: R\$ 480,00', skipOffstage: false),
        findsOneWidget);
    await tocar(tester, chave('botao_salvar_despesa'));

    expect(find.text('IPTU da casa (atende em casa)'), findsOneWidget);
    expect(find.text('20% da casa'), findsOneWidget);
    expect(find.text('deduz R\$ 480,00'), findsOneWidget);
    expect(
      tester.widget<Text>(find.descendant(
          of: chave('despesas_total_dedutivel'), matching: find.byType(Text))).data,
      'R\$ 480,00',
    );
  });

  testWidgets('M9: cartão pede a data da COMPRA e avisa que a fatura não conta',
      (tester) async {
    await montar(tester);
    await tocar(tester, find.text('Adicionar despesa'));
    await tocar(tester, chave('forma_cartaoCredito'));
    expect(chave('nota_cartao'), findsOneWidget);
    expect(find.textContaining('Data da compra', skipOffstage: false),
        findsOneWidget);
  });

  testWidgets('M9: linha exclusiva mostra o que guardar e exige a declaração',
      (tester) async {
    await montar(tester);
    await tocar(tester, find.text('Adicionar despesa'));
    await tocar(tester, chave('rubrica_linha-exclusiva-atividade'));
    expect(find.textContaining('cartão de visita', skipOffstage: false),
        findsOneWidget);
    await tester.enterText(chave('valor_despesa'), '60,00');
    await tocar(tester, chave('botao_salvar_despesa'));
    expect(find.text('Confirme que a linha é só da atividade.',
        skipOffstage: false), findsOneWidget);

    await tocar(tester, chave('declaracao_exclusividade'));
    await tocar(tester, chave('botao_salvar_despesa'));
    expect(find.text('Linha ou chip exclusivo da atividade'), findsOneWidget);
  });

  testWidgets('débito do extrato vira despesa; o recorrente vem com a proposta '
      'declarada e desfazer', (tester) async {
    await sql(tester,
        "INSERT INTO contas_bancarias (id, apelido, criado_em) VALUES ('c', 'C', 0)");
    for (final (id, data) in [('d7', '2026-07-05'), ('d8', '2026-08-05')]) {
      await sql(tester,
          'INSERT INTO transacoes (id, conta_id, data, valor_centavos, '
          "descricao_raw, criado_em) VALUES ('$id', 'c', '$data', -150000, "
          "'PAGTO ALUGUEL IMOB CENTRO', 0)");
    }
    await montar(tester);
    expect(find.text('Débitos do extrato', skipOffstage: false), findsOneWidget);

    await tocar(tester, chave('debito_d8'));
    await tocar(tester, chave('rubrica_aluguel-espaco-profissional'));
    await tocar(tester, chave('botao_salvar_despesa'));

    expect(find.text('Lançar o outro como Aluguel do consultório ou escritório '
        '(R\$ 1.500,00)'), findsOneWidget);
    await tocar(tester, chave('botao_aceitar_proposta_despesa'));
    expect(find.text('1 despesa lançada.'), findsOneWidget);
    expect(find.text('Débitos do extrato', skipOffstage: false), findsNothing);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.widgetWithText(SnackBarAction, 'Desfazer').last);
    await assentar(tester);
    final julho = await tester.runAsync(() => despesas.despesasDoMes('2026-07'));
    expect(julho, isEmpty, reason: 'desfazer tira o que a proposta lançou');
  });

  testWidgets('INSS: guia com atraso mostra que os acréscimos não deduzem; '
      '"não paguei" fica gravado e pode mudar', (tester) async {
    await montar(tester);
    await tocar(tester, chave('botao_inss_pago'));
    await tester.enterText(chave('inss_principal'), '320,00');
    await tester.enterText(chave('inss_acrescimos'), '12,00');
    await tocar(tester, chave('confirmar_inss'));

    expect(find.text('acréscimos de R\$ 12,00 não deduzem', skipOffstage: false),
        findsOneWidget);
    expect(chave('botao_inss_nao_pago'), findsNothing,
        reason: 'com guia paga, "não paguei" some');
    final guia =
        (await tester.runAsync(() => despesas.inssDoMes('2026-08')))!.single;
    expect((guia.principalCentavos, guia.acrescimosCentavos), (32000, 1200));

    await tocar(tester, chave('inss_${guia.id}'));
    await tocar(tester, chave('confirmar_excluir_inss'));
    await tocar(tester, chave('botao_inss_nao_pago'));
    expect(chave('inss_nao_pago'), findsOneWidget);
    await tocar(tester, chave('inss_mudar_resposta'));
    expect(chave('botao_inss_nao_pago'), findsOneWidget);
  });

  testWidgets('dependente: entra desde o mês aberto e conta nele', (tester) async {
    await montar(tester);
    expect(find.text('Nenhum dependente em agosto/2026.', skipOffstage: false),
        findsOneWidget);
    await tocar(tester, chave('botao_novo_dependente'));
    expect(find.text('Dependente desde 01/08/2026'), findsOneWidget);
    await tester.enterText(chave('dependente_nome'), 'Bia');
    await tester.pump();
    await tocar(tester, chave('confirmar_dependente'));

    expect(find.text('1 dependente em agosto/2026.', skipOffstage: false),
        findsOneWidget);
    expect(find.text('desde 01/08/2026', skipOffstage: false), findsOneWidget);
    await tocar(tester, chave('despesas_mes_anterior'));
    expect(find.text('Nenhum dependente em julho/2026.', skipOffstage: false),
        findsOneWidget);
  });
}
