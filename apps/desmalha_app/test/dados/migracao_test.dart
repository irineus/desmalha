/// Migração do banco local, provada a partir de um arquivo da versão
/// anterior de verdade (snapshots em `drift_schemas/`, helpers gerados em
/// `test/dados/generated/`).
///
/// Cada passo vN→vN+1 tem dois testes: o esquema resultante bate com o de
/// um banco criado do zero na versão nova (nada de "migrou, mas ficou
/// diferente"), e os DADOS da versão anterior chegam como a regra manda.
library;

import 'package:desmalha_app/dados/banco.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v1 → v2: o esquema migrado é idêntico ao criado do zero', () async {
    final conexao = await verifier.startAt(1);
    final banco = BancoLocal(conexao);
    addTearDown(banco.close);
    await verifier.migrateAndValidate(banco, 2);
  });

  group('v1 → v2: dados', () {
    late BancoLocal banco;

    setUp(() async {
      final v1 = await verifier.schemaAt(1);
      final sql = v1.rawDatabase.execute;
      // Um banco v1 com um exemplar de cada caso que a migração trata.
      sql("INSERT INTO cat_profissoes VALUES ('psicologia','Psicologia',1,'CRP',0,1)");
      sql('INSERT INTO perfil (id, nome, cpf, profissao_codigo, criado_em, '
          "atualizado_em) VALUES (1, 'Pessoa', '000', 'psicologia', 1, 1)");
      sql("INSERT INTO contas_bancarias (id, apelido, criado_em) "
          "VALUES ('c1', 'Conta', 1)");
      for (final (id, valor) in [('t1', 45000), ('t2', 30000), ('t3', 12000)]) {
        sql('INSERT INTO transacoes (id, conta_id, data, valor_centavos, '
            "descricao_raw, criado_em) VALUES ('$id', 'c1', '2026-08-10', "
            "$valor, 'PIX RECEBIDO', 1)");
      }
      sql('INSERT INTO remetentes (id, nome, classificacao_padrao, criado_em) '
          "VALUES ('r1', '  Maria Souza ', 'tributavel', 1)");
      sql('INSERT INTO remetentes (id, nome, cpf, classificacao_padrao, '
          "criado_em) VALUES ('r2', 'Joao', '111', 'reembolso', 1)");
      sql("INSERT INTO cat_tabelas_irpf VALUES (7, '2026-01', NULL, 'lei', 18959)");
      sql('INSERT INTO apuracoes_mensais (id, competencia, receita_bruta_centavos, '
          'despesas_livro_caixa_centavos, inss_centavos, qtde_dependentes, '
          'deducao_dependentes_centavos, desconto_simplificado_centavos, '
          'imposto_cenario_real_centavos, imposto_cenario_simplificado_centavos, '
          'cenario_aplicado, base_calculo_centavos, aliquota_bp, '
          'parcela_deduzir_centavos, imposto_apurado_centavos, '
          'imposto_devido_centavos, imposto_diferido_anterior_centavos, '
          'tabela_irpf_id, catalogo_versoes_snapshot, parametros_snapshot, '
          "motor_versao, app_versao, calculada_em) VALUES ('ap-08', '2026-08', "
          "75000, 0, 0, 0, 0, 60720, 0, 0, 'real', 75000, 0, 0, 0, 700, 400, 7, "
          "'{}', '{}', '1', '1', 1)");
      sql('INSERT INTO lancamentos (id, transacao_id, competencia, '
          'data_recebimento, valor_centavos, classificacao, remetente_id, '
          'cpf_pagador, origem_classificacao, criado_em, atualizado_em) VALUES '
          "('l1', 't1', '2026-08', '2026-08-10', 45000, 'tributavel', 'r1', "
          "NULL, 'sugestao_aceita', 1, 5)");
      sql('INSERT INTO lancamentos (id, transacao_id, competencia, '
          'data_recebimento, valor_centavos, classificacao, cpf_pagador, '
          'criado_em, atualizado_em) VALUES '
          "('l2', 't2', '2026-08', '2026-08-10', 30000, 'pessoal', '222', 1, 6)");
      sql('INSERT INTO lancamentos (id, transacao_id, competencia, '
          'data_recebimento, valor_centavos, classificacao, criado_em, '
          "atualizado_em) VALUES ('l3', 't3', '2026-08', '2026-08-10', 12000, "
          "'repasse_terceiros', 1, 7)");
      sql('INSERT INTO historico_classificacao (lancamento_id, de, para, criado_em) '
          "VALUES ('l1', NULL, 'tributavel', 1)");
      sql('INSERT INTO historico_classificacao (lancamento_id, de, para, criado_em) '
          "VALUES ('l3', NULL, 'repasse_terceiros', 1)");
      sql("INSERT INTO cat_rubricas (codigo, nome, dedutivel) "
          "VALUES ('aluguel', 'Aluguel', 1)");
      sql('INSERT INTO despesas_livro_caixa (id, rubrica_codigo, competencia, '
          'data_pagamento, valor_centavos, valor_dedutivel_centavos, criado_em) '
          "VALUES ('d1', 'aluguel', '2026-08', '2026-08-05', 100000, 100000, 1)");
      sql('INSERT INTO pagamentos_inss (id, competencia, valor_centavos, '
          "criado_em) VALUES ('i1', '2026-08', 32000, 1)");
      sql('INSERT INTO darfs (id, apuracao_id, competencia, valor_centavos, '
          "vencimento, status, criado_em) VALUES ('g1', 'ap-08', '2026-08', "
          "1100, '2026-09-30', 'vencido', 1)");

      banco = BancoLocal(v1.newConnection());
      await verifier.migrateAndValidate(banco, 2);
    });

    tearDown(() => banco.close());

    Future<Map<String, Object?>> linha(String sql) async =>
        (await banco.customSelect(sql).getSingle()).data;

    Future<int> contar(String tabela) async =>
        (await banco.customSelect('SELECT COUNT(*) AS n FROM $tabela')
                .getSingle())
            .read<int>('n');

    test('classificação e origem passam aos nomes do motor', () async {
      final l1 = await linha("SELECT * FROM lancamentos WHERE id = 'l1'");
      expect(l1['classificacao'], 'rendimentoPf');
      expect(l1['origem_classificacao'], 'sugestaoAceita');
      expect(l1['confirmada_em'], 5, reason: 'toque da v1 = confirmado');
      expect(l1['status_documento_pagador'], 'naoExigido');
      final l2 = await linha("SELECT * FROM lancamentos WHERE id = 'l2'");
      expect(l2['classificacao'], 'pessoal');
      expect(l2['status_documento_pagador'], 'informado');
      final h = await linha(
          "SELECT para FROM historico_classificacao WHERE lancamento_id = 'l1'");
      expect(h['para'], 'rendimentoPf');
    });

    test('repasse da v1 (sem titular do comprovante) volta à fila, auditado',
        () async {
      expect(await contar("lancamentos WHERE id = 'l3'"), 0);
      expect(await contar("historico_classificacao WHERE lancamento_id = 'l3'"),
          0);
      expect(await contar("transacoes WHERE id = 't3'"), 1,
          reason: 'o fato bancário fica: só a interpretação sai');
      final a = await linha(
          "SELECT * FROM auditoria WHERE entidade_id = 'l3'");
      expect(a['acao'], 'excluir');
      expect(a['detalhe'] as String, contains('migracao_v2_reclassificar'));
      expect(a['detalhe'] as String, contains('repasse_terceiros'));
    });

    test('remetente ganha chave de nome; regra só onde não falta resposta',
        () async {
      final r1 = await linha("SELECT * FROM remetentes WHERE id = 'r1'");
      expect(r1['chave_nome'], 'MARIA SOUZA');
      expect(r1['regra_classificacao'], 'rendimentoPf');
      expect(r1['regra_confirmada_em'], isNull);
      final r2 = await linha("SELECT * FROM remetentes WHERE id = 'r2'");
      expect(r2['regra_classificacao'], isNull,
          reason: 'reembolso exige titular do comprovante e essencialidade');
    });

    test('apuração: cenário, tabela e destino do DARF mínimo', () async {
      final ap = await linha("SELECT * FROM apuracoes_mensais WHERE id = 'ap-08'");
      expect(ap['cenario_aplicado'], 'deducoesReais');
      expect(ap['tabela_irpf_id'], '7');
      expect(ap['total_para_darf_centavos'], 1100);
      expect(ap['status_darf'], 'emitido', reason: '700 + 400 ≥ R\$ 10,00');
    });

    test('guia: status novo e ligação N:1 em darf_competencias', () async {
      final g = await linha("SELECT * FROM darfs WHERE id = 'g1'");
      expect(g['status'], 'gerada', reason: 'vencida não é estado gravado');
      expect(g.containsKey('apuracao_id'), isFalse);
      final ligacao = await linha('SELECT * FROM darf_competencias');
      expect(ligacao, {
        'darf_id': 'g1',
        'competencia': '2026-08',
        'apuracao_id': 'ap-08',
      });
    });

    test('despesa e INSS da v1 seguem, com os campos novos no padrão',
        () async {
      final d = await linha("SELECT * FROM despesas_livro_caixa WHERE id = 'd1'");
      expect(d['rubrica_codigo'], 'aluguel');
      expect(d['forma_pagamento'], 'outra');
      final i = await linha("SELECT * FROM pagamentos_inss WHERE id = 'i1'");
      expect(i['situacao'], 'pago');
      expect(i['acrescimos_centavos'], 0);
    });

    test('as tabelas cat_* saíram do banco', () async {
      final cat = await banco
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table' "
              "AND name LIKE 'cat\\_%' ESCAPE '\\'")
          .get();
      expect(cat, isEmpty);
      final p = await linha('SELECT profissao_codigo FROM perfil');
      expect(p['profissao_codigo'], 'psicologia');
    });
  });
}
