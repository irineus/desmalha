import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/onboarding/repositorio_onboarding.dart';
import 'package:desmalha_app/painel/repositorio_fechamento.dart';
import 'package:desmalha_app/painel/tela_mes.dart';
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
  late RepositorioFechamento fechamento;
  late PainelFalso painel;
  late ServicosDoApp servicos;

  DadosDoMes classificado(int receita, {int aClassificar = 0}) => DadosDoMes(
        receitaTributavelCentavos: receita,
        lancamentosClassificados: 1,
        recebimentosAClassificar: aClassificar,
      );

  setUp(() {
    banco = BancoLocal(NativeDatabase.memory());
    fechamento = RepositorioFechamento(banco);
    painel = PainelFalso();
    final perfil = RepositorioOnboardingMemoria()
      ..perfil = const PerfilDoApp(
        nome: 'Ana Souza',
        cpf: '52998224725',
        onboardingCompleto: true,
      );
    servicos = servicosFalsos(
      painel: painel,
      fechamento: fechamento,
      catalogo: () async => catalogo,
      onboarding: controladorOnboardingFalso(repositorio: perfil),
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
        home: Scaffold(
          body: TelaMes(servicos: servicos, relogio: () => hoje),
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

  String textoDe(WidgetTester tester, String k) {
    final t = tester.widget<Text>(
      find.descendant(of: chave(k), matching: find.byType(Text)).first,
    );
    return t.data ?? t.textSpan!.toPlainText();
  }

  testWidgets('marcar pago fecha o mês; a correção depois mostra o '
      'complementar de P8 e grava a versão nova', (tester) async {
    painel.dados['2026-08'] = classificado(600000);
    await montar(tester, DateTime(2026, 9, 24, 10));

    await tocar(tester, chave('botao_ver_darf'));
    await tocar(tester, chave('botao_marcar_pago'));
    await tocar(tester, chave('confirmar_pagamento'));

    expect(find.text('mês fechado'), findsOneWidget);
    expect(textoDe(tester, 'valor_pago'), 'R\$ 394,54');
    expect(chave('correcao_pendente'), findsNothing);

    // Um Pix de R$ 1.000,00 de agosto era de cliente.
    painel.dados['2026-08'] = classificado(700000);
    servicos.dadosAlterados.value++;
    await assentar(tester);

    expect(chave('correcao_pendente'), findsOneWidget);
    expect(
      find.textContaining('Falta pagar R\$ 408,14 de agosto/2026',
          findRichText: true, skipOffstage: false),
      findsOneWidget,
    );

    await tocar(tester, chave('botao_registrar_correcao'));
    expect(chave('correcao_pendente'), findsNothing);
    final versoes = await tester.runAsync(() => banco
        .customSelect(
            'SELECT versao, status FROM apuracoes_mensais ORDER BY versao')
        .get());
    expect(versoes!.map((l) => (l.read<int>('versao'), l.read<String>('status'))),
        [(1, 'substituida'), (2, 'fechada')]);
  });

  testWidgets('recalculado menor: só sinaliza pago a maior (P9)',
      (tester) async {
    painel.dados['2026-08'] = classificado(700000);
    await montar(tester, DateTime(2026, 9, 24, 10));
    await tocar(tester, chave('botao_ver_darf'));
    await tocar(tester, chave('botao_marcar_pago'));
    await tocar(tester, chave('confirmar_pagamento'));

    painel.dados['2026-08'] = classificado(600000);
    servicos.dadosAlterados.value++;
    await assentar(tester);
    expect(tester.widget<Text>(chave('acerto_pago_a_maior')).data,
        startsWith('Pago a maior: R\$ 408,14.'));

    // O DARF pago mostra a data e o histórico de pagamentos do ano.
    await tocar(tester, chave('botao_ver_darf'));
    expect(chave('darf_pago_em'), findsOneWidget);
    expect(chave('historico_pagamentos'), findsOneWidget);
    expect(chave('botao_marcar_pago'), findsNothing);
  });

  testWidgets('recebimento a classificar impede marcar pago', (tester) async {
    painel.dados['2026-08'] = classificado(600000, aClassificar: 2);
    await montar(tester, DateTime(2026, 9, 24, 10));
    await tocar(tester, chave('botao_ver_darf'));
    await tocar(tester, chave('botao_marcar_pago'));

    expect(find.textContaining('Faltam classificar 2 recebimentos'),
        findsOneWidget);
    expect(chave('confirmar_pagamento'), findsNothing);
    final n = await tester.runAsync(
        () => banco.customSelect('SELECT COUNT(*) AS n FROM darfs').getSingle());
    expect(n!.read<int>('n'), 0);
  });

  testWidgets('mês isento fecha pelo botão "Fechar mês"', (tester) async {
    painel.dados['2026-07'] = classificado(400000);
    await montar(tester, DateTime(2026, 8, 15, 10));
    expect(chave('mes_isento'), findsOneWidget);

    await tocar(tester, chave('botao_fechar_mes'));
    expect(find.text('mês fechado'), findsOneWidget);
    expect(chave('botao_fechar_mes'), findsNothing);
  });
}
