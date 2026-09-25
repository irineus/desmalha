import 'dart:typed_data';

import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/painel/repositorio_fechamento.dart';
import 'package:desmalha_app/relatorio/aba_ano.dart';
import 'package:desmalha_app/relatorio/repositorio_relatorio.dart';
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
  late PainelFalso painel;
  late RepositorioFechamento fechamento;
  late ServicosDoApp servicos;
  late List<(Uint8List, String, String)> compartilhados;

  setUp(() {
    banco = BancoLocal(NativeDatabase.memory());
    painel = PainelFalso();
    fechamento = RepositorioFechamento(banco);
    compartilhados = [];
    servicos = servicosFalsos(
      painel: painel,
      fechamento: fechamento,
      relatorio: RepositorioRelatorio(
        banco,
        painel: painel,
        fechamento: fechamento,
      ),
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
  }

  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: Scaffold(
          body: AbaAno(
            servicos: servicos,
            hoje: () => DateTime(2026, 9, 25),
            compartilhar: (b, n, t) async => compartilhados.add((b, n, t)),
          ),
        ),
      ),
    );
    await assentar(tester);
  }

  Finder chave(String k) => find.byKey(Key(k), skipOffstage: false);

  String valor(WidgetTester tester, String k) => tester
      .widget<Text>(find.descendant(of: chave(k), matching: find.byType(Text)))
      .data!;

  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    await tester.ensureVisible(alvo);
    await tester.pump();
    await tester.tap(alvo);
    await assentar(tester);
  }

  testWidgets('o ano mês a mês: receita, imposto pago só com DARF pago, '
      'PJ à parte, aviso e PDF', (tester) async {
    const agosto = DadosDoMes(
      receitaTributavelCentavos: 600000,
      lancamentosClassificados: 1,
    );
    painel.dados['2026-08'] = agosto;
    painel.dados['2026-07'] = const DadosDoMes(
      receitaTributavelCentavos: 600000,
      lancamentosClassificados: 1,
    );
    final apuradas = apurarAno(
      ate: '2026-08',
      dadosDoAno: painel.dados,
      catalogo: catalogo,
    );
    await tester.runAsync(() async {
      await fechamento.marcarPago(
        periodo: '2026-08',
        competencias: ['2026-08'],
        meses: {
          '2026-08': MesApurado(
            apuracao: apuradas['2026-08']!,
            dados: agosto,
            tabela: catalogo.tabelaVigentePara('2026-08'),
          ),
        },
        principalCentavos: 39454,
        acrescimosCentavos: 756,
        vencimento: '2026-09-30',
        pagoEm: '2026-09-20',
      );
      await banco.customStatement(
        'INSERT INTO lancamentos (id, competencia, data_recebimento, '
        'valor_centavos, classificacao, cnpj_pagador, nome_pagador, '
        'criado_em, atualizado_em, confirmada_em) VALUES (?, ?, ?, ?, ?, ?, '
        '?, 0, 0, 0)',
        [
          'pj1',
          '2026-08',
          '2026-08-12',
          200000,
          'recebidoPj',
          '11222333000181',
          'Clínica Bem Estar Ltda',
        ],
      );
    });

    await montar(tester);
    expect(valor(tester, 'total_receitas'), 'R\$ 12.000,00',
        reason: 'o PJ fica fora das receitas de PF (P1)');
    expect(valor(tester, 'total_imposto_pago'), 'R\$ 394,54',
        reason: 'só agosto foi pago; só o principal (P11)');
    expect(find.text('CNPJ 11.222.333/0001-81', skipOffstage: false),
        findsOneWidget);
    expect(chave('aviso_outras_rendas'), findsOneWidget);

    await tocar(tester, chave('mes_2026-07'));
    expect(valor(tester, '2026-07_imposto_pago'), 'R\$ 0,00',
        reason: 'julho sem DARF pago');

    await tocar(tester, chave('botao_pdf_ano'));
    expect(compartilhados.single.$2, 'relatorio-carne-leao-2026.pdf');
    expect(compartilhados.single.$3, 'application/pdf');
  });

  testWidgets('ano sem nada é estado vazio; não navega para o futuro',
      (tester) async {
    await montar(tester);
    expect(chave('ano_vazio'), findsOneWidget);
    final seguinte = tester.widget<IconButton>(chave('ano_seguinte'));
    expect(seguinte.onPressed, isNull);

    await tocar(tester, chave('ano_anterior'));
    expect(find.text('2025'), findsOneWidget);
  });
}
