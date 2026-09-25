import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/despesas/repositorio_despesas.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lembretes/notificacoes_falsas.dart';

void main() {
  late BancoLocal banco;
  late RepositorioDespesas repo;

  setUp(() async {
    banco = BancoLocal(NativeDatabase.memory());
    repo = RepositorioDespesas(banco, catalogo: () async => catalogoDoSeed());
    await banco.customStatement(
      "INSERT INTO contas_bancarias (id, apelido, criado_em) VALUES ('c', 'C', 0)",
    );
  });
  tearDown(() => banco.close());

  Future<void> transacao(String id, String data, int centavos, String desc) =>
      banco.customStatement(
        'INSERT INTO transacoes (id, conta_id, data, valor_centavos, '
        "descricao_raw, criado_em) VALUES (?, 'c', ?, ?, ?, 0)",
        [id, data, centavos, desc],
      );

  Future<Map<String, Object?>> despesa(String id) async => (await banco
          .customSelect('SELECT * FROM despesas_livro_caixa WHERE id = ?',
              variables: [Variable.withString(id)])
          .getSingle())
      .data;

  test('IPTU da casa: deduz 20% pela rubrica (rodada 4, P4)', () async {
    final id = await repo.registrar(
      rubricaId: 'iptu-residencia',
      valorCentavos: 240000,
      dataPagamento: '2026-08-10',
    );
    final d = await despesa(id);
    expect((d['valor_dedutivel_centavos'], d['home_office'], d['competencia']),
        (48000, 1, '2026-08'));
  });

  test('cartão de crédito: competência da data da compra (P5)', () async {
    final id = await repo.registrar(
      rubricaId: 'material-consumo',
      valorCentavos: 30000,
      dataPagamento: '2026-12-20',
      forma: FormaPagamentoDespesa.cartaoCredito,
    );
    final d = await despesa(id);
    expect((d['competencia'], d['forma_pagamento']), ('2026-12', 'cartaoCredito'));
  });

  test('linha exclusiva: sem declaração é recusada; com ela deduz 100% (4b)',
      () async {
    await expectLater(
      repo.registrar(
        rubricaId: 'linha-exclusiva-atividade',
        valorCentavos: 6000,
        dataPagamento: '2026-08-05',
      ),
      throwsArgumentError,
    );
    final id = await repo.registrar(
      rubricaId: 'linha-exclusiva-atividade',
      valorCentavos: 6000,
      dataPagamento: '2026-08-05',
      declarouExclusividade: true,
    );
    final d = await despesa(id);
    expect(d['valor_dedutivel_centavos'], 6000);
    expect(d['exclusividade_declarada_em'], isNotNull);
  });

  test('vedada: registra o gasto e deduz zero; rubrica inexistente é recusada',
      () async {
    final id = await repo.registrar(
      rubricaId: 'equipamento-duravel',
      valorCentavos: 300000,
      dataPagamento: '2026-08-05',
    );
    expect((await despesa(id))['valor_dedutivel_centavos'], 0);
    await expectLater(
      repo.registrar(
          rubricaId: 'nao-existe', valorCentavos: 1, dataPagamento: '2026-08-05'),
      throwsArgumentError,
    );
  });

  test('débito do extrato vira despesa com valor e data da transação; '
      'crédito não', () async {
    await transacao('d1', '2026-08-05', -150000, 'PAGTO ALUGUEL IMOB CENTRO');
    await transacao('c1', '2026-08-06', 45000, 'PIX RECEBIDO ANA');
    expect((await repo.debitosDoMes('2026-08')).map((d) => d.transacaoId),
        ['d1']);
    final id = await repo.registrar(
      rubricaId: 'aluguel-espaco-profissional',
      transacaoId: 'd1',
    );
    final d = await despesa(id);
    expect((d['valor_centavos'], d['data_pagamento'], d['forma_pagamento']),
        (150000, '2026-08-05', 'extrato'));
    expect(await repo.debitosDoMes('2026-08'), isEmpty);
    await expectLater(
      repo.registrar(rubricaId: 'material-consumo', transacaoId: 'c1'),
      throwsArgumentError,
    );
  });

  test('débito recorrente: proposta declara quantidade e valor; só aplica o '
      'declarado', () async {
    await transacao('d7', '2026-07-05', -150000, 'PAGTO ALUGUEL IMOB CENTRO');
    await transacao('d8', '2026-08-05', -150000, 'PAGTO ALUGUEL IMOB CENTRO');
    await transacao('d9', '2026-09-05', -150000, 'PAGTO ALUGUEL IMOB CENTRO');
    await transacao('x1', '2026-08-06', -9000, 'COMPRA MERCADO');
    await repo.registrar(rubricaId: 'aluguel-espaco-profissional', transacaoId: 'd8');

    final p = (await repo.propostaPara('d8', 'aluguel-espaco-profissional'))!;
    expect(p.rotulo,
        'Lançar os outros 2 como Aluguel do consultório ou escritório (R\$ 3.000,00)');
    final ids = await repo.aceitarProposta(p);
    expect(ids, hasLength(2));
    expect(await repo.despesasDoMes('2026-07'), hasLength(1));
    expect(await repo.debitosDoMes('2026-08'), hasLength(1),
        reason: 'o mercado não entrou');

    for (final id in ids) {
      await repo.excluir(id);
    }
    expect(await repo.despesasDoMes('2026-07'), isEmpty);
  });

  test('linha exclusiva não vira proposta em lote (a declaração é por item)',
      () async {
    await transacao('t1', '2026-08-05', -6000, 'DEB AUT OPERADORA TEL');
    await transacao('t2', '2026-09-05', -6000, 'DEB AUT OPERADORA TEL');
    await repo.registrar(
      rubricaId: 'linha-exclusiva-atividade',
      transacaoId: 't1',
      declarouExclusividade: true,
    );
    expect(await repo.propostaPara('t1', 'linha-exclusiva-atividade'), isNull);
  });

  test('despesa de repasse não se exclui por aqui', () async {
    await transacao('t1', '2026-08-05', 45000, 'PIX RECEBIDO ANA');
    await banco.customStatement(
      'INSERT INTO lancamentos (id, transacao_id, competencia, data_recebimento, '
      'valor_centavos, classificacao, comprovante_titular, custo_essencial, '
      "criado_em, atualizado_em, confirmada_em) VALUES ('l', 't1', '2026-08', "
      "'2026-08-05', 45000, 'repasse', 'profissional', 1, 0, 0, 0)",
    );
    await banco.customStatement(
      'INSERT INTO despesas_livro_caixa (id, rubrica_codigo, competencia, '
      'data_pagamento, valor_centavos, valor_dedutivel_centavos, '
      "lancamento_origem_id, criado_em) VALUES ('r', 'custo-repassado-essencial', "
      "'2026-08', '2026-08-01', 45000, 45000, 'l', 0)",
    );
    await expectLater(repo.excluir('r'), throwsStateError);
    final lista = await repo.despesasDoMes('2026-08');
    expect(lista.single.deRepasse, isTrue);
  });

  test('INSS: guia paga guarda principal e acréscimos separados (P6); '
      '"não paguei" é resposta e cede à guia', () async {
    await repo.registrarInssNaoPago('2026-08');
    expect((await repo.inssDoMes('2026-08')).single.situacao,
        SituacaoInss.naoPago);

    await repo.registrarInssPago(
        competencia: '2026-08', principalCentavos: 32000, acrescimosCentavos: 1200);
    final agosto = await repo.inssDoMes('2026-08');
    expect(
      agosto.map((i) => (i.situacao, i.principalCentavos, i.acrescimosCentavos)),
      [(SituacaoInss.pago, 32000, 1200)],
      reason: 'a guia substitui o "não paguei"',
    );
    await expectLater(
        repo.registrarInssNaoPago('2026-08'), throwsStateError);
    await expectLater(
      repo.registrarInssPago(competencia: '2026-08', principalCentavos: 0),
      throwsArgumentError,
    );

    await repo.excluirInss(agosto.single.id);
    expect(await repo.inssDoMes('2026-08'), isEmpty);
  });

  test('dependente: cadastra, encerra e valida a vigência', () async {
    final id = await repo.adicionarDependente(nome: ' Bia ', inicio: '2026-03-20');
    await repo.encerrarDependente(id, '2026-11-02');
    final d = (await repo.dependentes()).single;
    expect((d.nome, d.inicio, d.fim), ('Bia', '2026-03-20', '2026-11-02'));

    await expectLater(repo.encerrarDependente(id, '2026-03-01'),
        throwsArgumentError);
    await expectLater(repo.adicionarDependente(nome: ' ', inicio: '2026-03-20'),
        throwsArgumentError);
    await expectLater(repo.adicionarDependente(nome: 'X', inicio: '20/03/2026'),
        throwsArgumentError);

    await repo.excluirDependente(id);
    expect(await repo.dependentes(), isEmpty);
  });
}
