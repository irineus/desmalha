import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/painel/repositorio_painel.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BancoLocal banco;
  late RepositorioPainelDrift repo;

  setUp(() async {
    banco = BancoLocal(NativeDatabase.memory());
    repo = RepositorioPainelDrift(banco);
    await banco.customStatement(
      "INSERT INTO contas_bancarias (id, apelido, criado_em) VALUES ('c', 'C', 0)",
    );
  });
  tearDown(() => banco.close());

  var seq = 0;
  Future<String> transacao(String data, int centavos) async {
    final id = 't${seq++}';
    await banco.customStatement(
      'INSERT INTO transacoes (id, conta_id, data, valor_centavos, '
      "descricao_raw, criado_em) VALUES (?, 'c', ?, ?, 'x', 0)",
      [id, data, centavos],
    );
    return id;
  }

  Future<void> lancamento(
    String competencia,
    int centavos,
    String classificacao, {
    String? transacaoId,
  }) => banco.customStatement(
    'INSERT INTO lancamentos (id, transacao_id, competencia, '
    'data_recebimento, valor_centavos, classificacao, comprovante_titular, '
    'criado_em, atualizado_em, confirmada_em) VALUES (?, ?, ?, ?, ?, ?, ?, '
    '0, 0, 0)',
    [
      'l${seq++}',
      transacaoId,
      competencia,
      '$competencia-10',
      centavos,
      classificacao,
      // Reembolso só existe com o titular do comprovante; no do cliente é
      // neutro — fora da receita.
      if (classificacao == 'reembolso') 'cliente' else null,
    ],
  );

  test('vazio: nenhum mês', () async {
    expect(await repo.dadosDoAno(2026), isEmpty);
  });

  test(
    'receita só dos tributáveis; contagem de todos os classificados',
    () async {
      await lancamento('2026-08', 45000, 'rendimentoPf');
      await lancamento('2026-08', 30000, 'rendimentoPf');
      await lancamento('2026-08', 99900, 'pessoal');
      await lancamento('2026-08', 12000, 'reembolso');
      final d = (await repo.dadosDoAno(2026))['2026-08']!;
      expect(d.receitaTributavelCentavos, 75000);
      expect(d.lancamentosClassificados, 4);
      expect(d.recebimentosAClassificar, 0);
    },
  );

  test(
    'a classificar: crédito importado sem lançamento; débito não conta',
    () async {
      final classificada = await transacao('2026-08-03', 45000);
      await transacao('2026-08-04', 30000); // crédito sem lançamento
      await transacao('2026-08-05', 20000); // crédito sem lançamento
      await transacao('2026-08-06', -8990); // débito: não é recebimento
      await lancamento(
        '2026-08',
        45000,
        'rendimentoPf',
        transacaoId: classificada,
      );
      final d = (await repo.dadosDoAno(2026))['2026-08']!;
      expect(d.recebimentosAClassificar, 2);
      expect(
        d.receitaTributavelCentavos,
        45000,
        reason: 'crédito não classificado nunca vira receita',
      );
    },
  );

  test('mês só com pendentes aparece com zero classificados', () async {
    await transacao('2026-07-01', 10000);
    final d = (await repo.dadosDoAno(2026))['2026-07']!;
    expect((d.lancamentosClassificados, d.recebimentosAClassificar), (0, 1));
  });

  test('deduções do mês: livro-caixa pelo dedutível, INSS só o principal '
      '(P6), dependente o mês inteiro (P7)', () async {
    await lancamento('2026-03', 600000, 'rendimentoPf');
    await banco.customStatement(
      'INSERT INTO despesas_livro_caixa (id, rubrica_codigo, competencia, '
      'data_pagamento, valor_centavos, valor_dedutivel_centavos, criado_em) '
      "VALUES ('d1', 'iptu-residencia', '2026-03', '2026-03-10', 240000, "
      "48000, 0), ('d2', 'material-consumo', '2026-03', '2026-03-11', 5000, "
      "5000, 0)",
    );
    await banco.customStatement(
      'INSERT INTO pagamentos_inss (id, competencia, valor_centavos, '
      "acrescimos_centavos, criado_em) VALUES ('i1', '2026-03', 32000, 1200, 0)",
    );
    await banco.customStatement(
      'INSERT INTO pagamentos_inss (id, competencia, situacao, valor_centavos, '
      "criado_em) VALUES ('i2', '2026-04', 'naoPago', 0, 0)",
    );
    await banco.customStatement(
      'INSERT INTO dependentes (id, nome, vigencia_inicio, criado_em) VALUES '
      "('f1', 'A', '2020-01-01', 0), ('f2', 'B', '2026-03-20', 0)",
    );
    await lancamento('2026-02', 100000, 'rendimentoPf');
    await lancamento('2026-04', 100000, 'rendimentoPf');

    final ano = await repo.dadosDoAno(2026);
    final marco = ano['2026-03']!;
    expect(
      (
        marco.despesasDedutiveisCentavos,
        marco.inssDedutivelCentavos,
        marco.dependentes,
      ),
      (53000, 32000, 2),
    );
    expect(ano['2026-02']!.dependentes, 1, reason: 'o segundo entrou em março');
    expect(ano['2026-04']!.inssDedutivelCentavos, 0, reason: '"não paguei"');
  });

  test('mês só com despesa entra (carrega o saldo negativo)', () async {
    await banco.customStatement(
      'INSERT INTO despesas_livro_caixa (id, rubrica_codigo, competencia, '
      'data_pagamento, valor_centavos, valor_dedutivel_centavos, criado_em) '
      "VALUES ('d1', 'material-consumo', '2026-05', '2026-05-10', 5000, 5000, 0)",
    );
    expect((await repo.dadosDoAno(2026))['2026-05']!.despesasDedutiveisCentavos,
        5000);
  });

  test('outro ano fica de fora', () async {
    await lancamento('2025-12', 45000, 'rendimentoPf');
    await transacao('2027-01-02', 10000);
    expect(await repo.dadosDoAno(2026), isEmpty);
  });
}
