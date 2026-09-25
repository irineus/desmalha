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

/// M5 (detalhe), M6 (reembolso/repasse) e M7 (remetentes), com banco real.
void main() {
  late BancoLocal banco;
  late RepositorioClassificacao classificacao;

  setUp(() {
    banco = BancoLocal(NativeDatabase.memory());
    classificacao = RepositorioClassificacao(
      banco,
      catalogo: () async => catalogoDoSeed(),
    );
  });
  tearDown(() => banco.close());

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

  Future<List<Map<String, Object?>>> linhas(WidgetTester tester, String s) async =>
      [
        for (final r in (await tester.runAsync(
          () => banco.customSelect(s).get(),
        ))!)
          r.data,
      ];

  Future<void> extrato(WidgetTester tester, {String? profissao}) async {
    await sql(tester,
        "INSERT INTO contas_bancarias (id, apelido, criado_em) VALUES ('c', 'C', 0)");
    await sql(tester,
        'INSERT INTO importacoes (id, conta_id, formato, nome_arquivo, '
        "hash_arquivo, status, criado_em) VALUES ('i', 'c', 'ofx', 'ago.ofx', "
        "'h', 'confirmada', 0)");
    if (profissao != null) {
      await sql(tester,
          'INSERT INTO perfil (id, nome, cpf, profissao_codigo, criado_em, '
          "atualizado_em) VALUES (1, 'P', '0', '$profissao', 0, 0)");
    }
    for (final (id, data, valor, desc) in [
      ('t1', '2026-08-03', 45000, 'PIX RECEBIDO MARIA SOUZA'),
      ('t2', '2026-08-10', 45000, 'PIX RECEBIDO MARIA SOUZA'),
      ('t4', '2026-08-20', 30000, 'PIX RECEBIDO JOAO LIMA'),
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

  Finder chave(String k) => find.byKey(Key(k), skipOffstage: false);

  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    await tester.ensureVisible(alvo);
    await tester.pump();
    await tester.tap(alvo);
    await assentar(tester);
  }

  group('M6 — reembolso ou repasse', () {
    testWidgets('no meu CPF e essencial: receita + despesa no mês em que '
        'paguei o custo', (tester) async {
      await extrato(tester);
      await montar(tester);
      await tocar(tester, chave('fila_t4'));
      await tocar(tester, chave('escolher_reembolso_repasse'));

      await tocar(tester, chave('tipo_ClassificacaoLancamento.repasse'));
      await tocar(tester, chave('titular_TitularComprovante.profissional'));
      expect(chave('botao_salvar_repasse'), findsNothing,
          reason: 'sem a essencialidade, não há o que salvar');
      await tocar(tester, chave('essencial_true'));
      expect(
        find.textContaining('livro-caixa de 08/2026', skipOffstage: false),
        findsOneWidget,
      );
      await tocar(tester, chave('botao_salvar_repasse'));

      final l = (await linhas(tester,
              "SELECT * FROM lancamentos WHERE transacao_id = 't4'"))
          .single;
      expect((l['classificacao'], l['comprovante_titular'], l['custo_essencial']),
          ('repasse', 'profissional', 1));
      final d = (await linhas(tester, 'SELECT * FROM despesas_livro_caixa')).single;
      expect(d['competencia'], '2026-08');
      expect(d['valor_centavos'], 30000);
      expect(find.text('A classificar 2'), findsOneWidget);
    });

    testWidgets('no CPF do cliente: neutro, sem despesa', (tester) async {
      await extrato(tester);
      await montar(tester);
      await tocar(tester, chave('fila_t4'));
      await tocar(tester, chave('escolher_reembolso_repasse'));
      await tocar(tester, chave('tipo_ClassificacaoLancamento.reembolso'));
      await tocar(tester, chave('titular_TitularComprovante.cliente'));
      expect(find.textContaining('fica fora do imposto', skipOffstage: false),
          findsOneWidget);
      await tocar(tester, chave('botao_salvar_repasse'));
      expect(await linhas(tester, 'SELECT * FROM despesas_livro_caixa'),
          isEmpty);
      final l = (await linhas(tester, 'SELECT * FROM lancamentos')).single;
      expect(l['classificacao'], 'reembolso');
    });
  });

  group('M5 — detalhe', () {
    testWidgets('psicóloga: CPF inválido é recusado; válido tira da "Falta '
        'CPF"; o atendido pode ser outra pessoa', (tester) async {
      await extrato(tester, profissao: 'psicologo');
      await montar(tester);
      await tocar(tester, chave('fila_t4'));
      await tocar(tester, chave('escolher_rendimentoPf'));
      expect(find.text('Falta CPF 1'), findsOneWidget);

      await tocar(tester, chave('aba_falta_cpf'));
      final item = find.byWidgetPredicate(
        (w) =>
            w is ListTile &&
            (w.key as ValueKey<String>?)?.value.startsWith('lancamento_') ==
                true,
        skipOffstage: false,
      );
      await tocar(tester, item.first);
      expect(
        find.textContaining('Falta o CPF de quem pagou.', findRichText: true),
        findsOneWidget,
      );

      await tester.enterText(chave('campo_documento'), '529.982.247-24');
      await tocar(tester, chave('botao_salvar_detalhe'));
      expect(find.text('CPF ou CNPJ inválido — confira os dígitos.'),
          findsOneWidget);

      await tester.enterText(chave('campo_documento'), '529.982.247-25');
      await tocar(tester, chave('outro_beneficiario'));
      await tester.enterText(chave('campo_nome_beneficiario'), 'Filho');
      await tester.enterText(chave('campo_cpf_beneficiario'), '111.444.777-35');
      await tocar(tester, chave('botao_salvar_detalhe'));

      final l = (await linhas(tester, 'SELECT * FROM lancamentos')).single;
      expect(l['status_documento_pagador'], 'informado');
      expect(l['cpf_pagador'], '52998224725');
      expect(l['cpf_beneficiario'], '11144477735');
      expect(find.text('Falta CPF 0'), findsOneWidget);
    });

    testWidgets('"Informar depois" mantém o recebimento no cálculo e na '
        '"Falta CPF"', (tester) async {
      await extrato(tester, profissao: 'psicologo');
      await montar(tester);
      await tocar(tester, chave('fila_t4'));
      await tocar(tester, chave('escolher_rendimentoPf'));
      await tocar(tester, chave('aba_prontos'));
      final item = find.byWidgetPredicate(
        (w) =>
            w is ListTile &&
            (w.key as ValueKey<String>?)?.value.startsWith('lancamento_') ==
                true,
        skipOffstage: false,
      );
      await tocar(tester, item.first);
      await tocar(tester, chave('botao_informar_depois'));
      final l = (await linhas(tester, 'SELECT * FROM lancamentos')).single;
      expect((l['classificacao'], l['status_documento_pagador']),
          ('rendimentoPf', 'pendente'));
    });
  });

  testWidgets('M7 — regra confirmada aparece e pode deixar de ser aplicada',
      (tester) async {
    await extrato(tester);
    await montar(tester);
    await tocar(tester, chave('fila_t1'));
    await tocar(tester, chave('escolher_rendimentoPf'));
    await tocar(tester, chave('botao_aceitar_proposta'));

    await tocar(tester, chave('botao_remetentes'));
    expect(find.text('regra: cliente'), findsOneWidget);
    expect(find.text('sem regra'), findsNothing);

    await tocar(
      tester,
      find.byWidgetPredicate(
        (w) =>
            w is TextButton &&
            (w.key as ValueKey<String>?)?.value.startsWith('esquecer_') == true,
      ),
    );
    await tocar(tester, chave('confirmar_esquecer'));
    expect(find.text('sem regra'), findsOneWidget);
    final r = (await linhas(tester, 'SELECT * FROM remetentes')).single;
    expect(r['regra_confirmada_em'], isNull);
  });
}
