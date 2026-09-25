import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/dados/repositorio_importacao.dart';
import 'package:desmalha_app/importacao/controlador_importacao.dart';
import 'package:desmalha_app/classificacao/aba_lancamentos.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lembretes/notificacoes_falsas.dart';
import '../servicos_falsos.dart';
import 'extratos_falsos.dart';

void main() {
  late BancoLocal banco;
  late RepositorioImportacao repo;
  late SeletorFalso seletor;

  setUp(() {
    banco = BancoLocal(NativeDatabase.memory());
    repo = RepositorioImportacao(banco);
    seletor = SeletorFalso();
  });
  tearDown(() => banco.close());

  /// Drift roda IO de verdade: cada passo que toca o banco anda fora do
  /// relógio falso do teste.
  Future<void> assentar(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Future<void> tocar(WidgetTester tester, String chave) async {
    final alvo = find.byKey(Key(chave));
    await tester.ensureVisible(alvo);
    await tester.tap(alvo);
    await assentar(tester);
  }

  Future<void> montarAba(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: Scaffold(
          body: AbaLancamentos(
            servicos: servicosFalsos(
              importacao: repo,
              seletorDeArquivo: seletor,
              catalogo: () async => catalogoDoSeed(),
            ),
          ),
        ),
      ),
    );
    await assentar(tester);
  }

  Future<int> gravadas() async =>
      (await banco
              .customSelect('SELECT count(*) AS n FROM transacoes')
              .getSingle())
          .read<int>('n');

  testWidgets('aba vazia → importar → prévia → confirmar → aba com a '
      'importação', (tester) async {
    await montarAba(tester);
    expect(find.byKey(const Key('lancamentos_vazio')), findsOneWidget);

    await tester.tap(find.text('Importar extrato'));
    await assentar(tester);
    seletor.proximo = ofxSintetico([pixAna, pixBruno, mercado]);
    await tocar(tester, 'botao_escolher_arquivo');

    expect(find.text('3 novos'), findsOneWidget);
    expect(find.text('R\$ 750,00'), findsOneWidget); // entradas
    expect(find.text('-R\$ 89,90'), findsOneWidget); // saídas
    expect(await tester.runAsync(gravadas), 0, reason: 'prévia não grava');

    await tocar(tester, 'botao_confirmar_importacao');
    expect(find.byKey(const Key('resumo_importacao')), findsOneWidget);
    expect(find.text('3 lançamentos gravados.'), findsOneWidget);
    expect(await tester.runAsync(gravadas), 3);

    await tocar(tester, 'botao_importacao_ok');
    expect(find.text('extrato.ofx'), findsOneWidget);
    expect(find.textContaining('03/08/2026 a 05/08/2026'), findsOneWidget);
  });

  testWidgets('possível duplicata: botão travado até decidir cada uma', (
    tester,
  ) async {
    // Base: o Pix da Ana já importado, pela própria tela.
    await montarAba(tester);
    await tester.tap(find.text('Importar extrato'));
    await assentar(tester);
    seletor.proximo = ofxSintetico([pixAna], nome: 'a.ofx');
    await tocar(tester, 'botao_escolher_arquivo');
    await tocar(tester, 'botao_confirmar_importacao');
    await tocar(tester, 'botao_importacao_ok');

    await tocar(tester, 'botao_importar_outro');
    seletor.proximo = ofxSintetico([
      (
        data: '2026-08-03',
        centavos: 45000,
        fitid: 'OUTRO',
        memo: 'PIX RECEBIDO ANA',
      ),
      pixBruno,
    ], nome: 'b.ofx');
    await tocar(tester, 'botao_escolher_arquivo');

    expect(find.byKey(const Key('possivel_0')), findsOneWidget);
    expect(find.text('Já existe:'), findsOneWidget);
    expect(find.byKey(const Key('falta_decidir')), findsOneWidget);
    final botao = find.byKey(const Key('botao_confirmar_importacao'));
    expect(tester.widget<FilledButton>(botao).onPressed, isNull);

    await tester.ensureVisible(find.text('Descartar'));
    await tester.tap(find.text('Descartar'));
    await assentar(tester);
    expect(find.byKey(const Key('falta_decidir')), findsNothing);
    expect(tester.widget<FilledButton>(botao).onPressed, isNotNull);

    await tocar(tester, 'botao_confirmar_importacao');
    expect(find.text('1 lançamento gravado.'), findsOneWidget);
    expect(find.text('1 descartado por você.'), findsOneWidget);
    expect(await tester.runAsync(gravadas), 2);
  });

  testWidgets('mesmo arquivo de novo: aviso, sem prévia', (tester) async {
    await montarAba(tester);
    await tester.tap(find.text('Importar extrato'));
    await assentar(tester);
    seletor.proximo = ofxSintetico([pixAna]);
    await tocar(tester, 'botao_escolher_arquivo');
    await tocar(tester, 'botao_confirmar_importacao');
    await tocar(tester, 'botao_importacao_ok');

    await tocar(tester, 'botao_importar_outro');
    seletor.proximo = ofxSintetico([pixAna]);
    await tocar(tester, 'botao_escolher_arquivo');
    expect(find.byKey(const Key('aviso_ja_importado')), findsOneWidget);
    expect(find.byKey(const Key('botao_confirmar_importacao')), findsNothing);
  });

  testWidgets('CSV: escolhe o banco e chega à prévia', (tester) async {
    await montarAba(tester);
    await tester.tap(find.text('Importar extrato'));
    await assentar(tester);
    seletor.proximo = csvNubankSintetico();
    await tocar(tester, 'botao_escolher_arquivo');
    expect(
      find.text('Este arquivo é CSV. De qual banco ele veio?'),
      findsOneWidget,
    );
    await tocar(tester, 'perfil_nubank-conta-csv-v1');
    expect(find.text('2 novos'), findsOneWidget);
  });

  testWidgets('valores grandes cabem em tela de celular estreita', (
    tester,
  ) async {
    // Achado no emulador: "Entradas R\$ 402.632,56  Saídas -R\$ 7.372,48"
    // numa linha só estourava a largura.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3; // 360 dp de largura
    addTearDown(tester.view.reset);
    await montarAba(tester);
    await tester.tap(find.text('Importar extrato'));
    await assentar(tester);
    seletor.proximo = ofxSintetico([
      (data: '2026-08-03', centavos: 40263256, fitid: 'G1', memo: 'PIX A'),
      (data: '2026-08-04', centavos: -737248, fitid: 'G2', memo: 'SAIDA B'),
    ]);
    await tocar(tester, 'botao_escolher_arquivo');
    expect(find.text('R\$ 402.632,56'), findsOneWidget);
    expect(find.text('-R\$ 7.372,48'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('arquivo ilegível: motivo na tela', (tester) async {
    await montarAba(tester);
    await tester.tap(find.text('Importar extrato'));
    await assentar(tester);
    seletor.proximo = ArquivoSelecionado(
      nome: 'cortado.ofx',
      bytes: ofxSintetico([pixAna]).bytes.sublist(0, 10),
    );
    await tocar(tester, 'botao_escolher_arquivo');
    expect(find.byKey(const Key('erro_importacao')), findsOneWidget);
    expect(find.textContaining('<OFX> ausente'), findsOneWidget);
  });
}
