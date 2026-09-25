import 'package:desmalha_app/classificacao/aba_lancamentos.dart';
import 'package:desmalha_app/classificacao/repositorio_classificacao.dart';
import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/dados/repositorio_importacao.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lembretes/notificacoes_falsas.dart';
import '../servicos_falsos.dart';

void main() {
  late BancoLocal banco;
  late RepositorioClassificacao classificacao;

  setUp(() async {
    banco = BancoLocal(NativeDatabase.memory());
    classificacao = RepositorioClassificacao(
      banco,
      catalogo: () async => catalogoDoSeed(),
    );
  });
  tearDown(() => banco.close());

  /// Drift roda IO de verdade: cada passo que toca o banco anda fora do
  /// relógio falso do teste.
  Future<void> assentar(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> sql(WidgetTester tester, String s) =>
      tester.runAsync(() => banco.customStatement(s)).then((_) {});

  /// Um extrato importado: 3 Pix da Maria, 1 do João e um débito.
  Future<void> extrato(WidgetTester tester) async {
    await sql(tester,
        "INSERT INTO contas_bancarias (id, apelido, criado_em) VALUES ('c', 'C', 0)");
    await sql(tester,
        'INSERT INTO importacoes (id, conta_id, formato, nome_arquivo, '
        "hash_arquivo, status, criado_em) VALUES ('i', 'c', 'ofx', 'ago.ofx', "
        "'h', 'confirmada', 0)");
    for (final (id, data, valor, desc) in [
      ('t1', '2026-08-03', 45000, 'PIX RECEBIDO MARIA SOUZA'),
      ('t2', '2026-08-10', 45000, 'PIX RECEBIDO MARIA SOUZA'),
      ('t3', '2026-08-17', 45000, 'PIX RECEBIDO MARIA SOUZA'),
      ('t4', '2026-08-20', 30000, 'PIX RECEBIDO JOAO LIMA'),
      ('t5', '2026-08-21', -12000, 'PAGTO ALUGUEL SALA'),
    ]) {
      await sql(tester,
          'INSERT INTO transacoes (id, conta_id, importacao_id, data, '
          "valor_centavos, descricao_raw, criado_em) VALUES ('$id', 'c', 'i', "
          "'$data', $valor, '$desc', 0)");
    }
  }

  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: Scaffold(
          body: AbaLancamentos(
            servicos: servicosFalsos(
              importacao: RepositorioImportacao(banco),
              classificacao: classificacao,
              catalogo: () async => catalogoDoSeed(),
            ),
          ),
        ),
      ),
    );
    await assentar(tester);
  }

  /// A lista rola (o toque num item de baixo leva o topo para fora da
  /// viewport): o alvo é procurado também fora da área visível.
  Finder chave(String k) => find.byKey(Key(k), skipOffstage: false);

  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    await tester.ensureVisible(alvo);
    await tester.pump();
    await tester.tap(alvo);
    await assentar(tester);
  }

  /// O "Desfazer" da SnackBar: espera a entrada terminar e toca.
  Future<void> desfazer(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.widgetWithText(SnackBarAction, 'Desfazer').last);
    await assentar(tester);
  }

  testWidgets('M3: classificar um, aceitar a proposta declarada e desfazer',
      (tester) async {
    await extrato(tester);
    await montar(tester);

    expect(find.text('A classificar 4'), findsOneWidget,
        reason: 'débito não é recebimento a classificar');
    expect(find.text('ago.ofx', skipOffstage: false), findsOneWidget);

    await tocar(tester, find.byKey(const Key('fila_t1')));
    await tocar(tester, find.byKey(const Key('escolher_rendimentoPf')));
    expect(find.text('Marcado como cliente.'), findsOneWidget);

    // A proposta declara quantidade e valor antes do toque.
    expect(chave('banner_proposta'), findsOneWidget);
    expect(
      find.text('Marcar os outros 2 como cliente (R\$ 900,00)',
          skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('A classificar 3'), findsOneWidget);

    await tocar(tester, chave('botao_aceitar_proposta'));
    expect(find.text('2 recebimentos marcados como cliente.'), findsOneWidget);
    expect(find.text('A classificar 1'), findsOneWidget);

    await desfazer(tester);
    expect(find.text('A classificar 3'), findsOneWidget,
        reason: 'desfazer devolve os 2 da proposta à fila');
  });

  testWidgets('M3: "Agora não" some com a proposta sem marcar nada',
      (tester) async {
    await extrato(tester);
    await montar(tester);
    await tocar(tester, find.byKey(const Key('fila_t1')));
    await tocar(tester, find.byKey(const Key('escolher_rendimentoPf')));
    await tocar(tester, chave('botao_recusar_proposta'));
    expect(chave('banner_proposta'), findsNothing);
    expect(find.text('A classificar 3'), findsOneWidget);
  });

  testWidgets('Falta CPF: profissão regulamentada — classificado E pendente, '
      'os dois selos no mesmo item', (tester) async {
    await extrato(tester);
    await sql(tester,
        'INSERT INTO perfil (id, nome, cpf, profissao_codigo, criado_em, '
        "atualizado_em) VALUES (1, 'P', '0', 'psicologo', 0, 0)");
    await montar(tester);
    await tocar(tester, find.byKey(const Key('fila_t4')));
    await tocar(tester, find.byKey(const Key('escolher_rendimentoPf')));

    expect(find.text('Falta CPF 1'), findsOneWidget);
    await tocar(tester, find.byKey(const Key('aba_falta_cpf')));
    expect(
      find.textContaining('Um recebimento sem CPF do pagador.',
          findRichText: true),
      findsOneWidget,
    );
    expect(find.text('cliente'), findsOneWidget);
    expect(find.text('falta CPF'), findsOneWidget);
  });

  testWidgets('M4: um a um — pular, classificar, desfazer volta ao mesmo card',
      (tester) async {
    await extrato(tester);
    await montar(tester);
    await tocar(tester, find.byKey(const Key('botao_classificar_um_a_um')));
    expect(find.text('1 de 4'), findsOneWidget);

    await tocar(tester, find.byKey(const Key('fila_pular')));
    expect(find.text('2 de 4'), findsOneWidget);

    await tocar(tester, find.byKey(const Key('fila_pessoal')));
    expect(find.text('3 de 4'), findsOneWidget);
    expect(find.text('Marcado como pessoal.'), findsOneWidget);

    await desfazer(tester);
    expect(find.text('2 de 4'), findsOneWidget);

    // Gesto: para a direita = cliente.
    await tester.drag(find.byKey(const ValueKey('cartao_t3')),
        const Offset(500, 0));
    // Dismissible: o gesto termina, a animação de saída e a de encolher
    // correm, e só então o onDismissed classifica.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await assentar(tester);
    expect(find.text('Marcado como cliente.'), findsOneWidget);
    expect(find.text('3 de 4'), findsOneWidget);
  });

  testWidgets('regra confirmada: "proposto pela regra" até o toque',
      (tester) async {
    await extrato(tester);
    await sql(tester,
        'INSERT INTO remetentes (id, nome, chave_nome, regra_classificacao, '
        "regra_confirmada_em, criado_em) VALUES ('r', 'Maria', 'MARIA SOUZA', "
        "'rendimentoPf', 1, 0)");
    await tester.runAsync(classificacao.aplicarRegrasAosNovos);
    await montar(tester);

    expect(find.text('proposto pela regra: cliente'), findsNWidgets(3));
    await tocar(tester, chave('confirmar_regra_t1'));
    expect(find.text('proposto pela regra: cliente'), findsNWidgets(2));
    expect(find.text('A classificar 3'), findsOneWidget);
  });
}
