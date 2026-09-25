import 'dart:convert';
import 'dart:io';

import 'package:desmalha_app/classificacao/repositorio_classificacao.dart';
import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/painel/repositorio_painel.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalogo = Catalogo.fromJson(
    jsonDecode(File('assets/catalogo/seed.json').readAsStringSync())
        as Map<String, Object?>,
  );

  late BancoLocal banco;
  late RepositorioClassificacao repo;
  var relogio = 1000;

  setUp(() async {
    banco = BancoLocal(NativeDatabase.memory());
    repo = RepositorioClassificacao(
      banco,
      catalogo: () async => catalogo,
      agoraEpochMs: () => relogio++,
    );
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

  Future<void> perfilComProfissao(String profissao) => banco.customStatement(
        'INSERT INTO perfil (id, nome, cpf, profissao_codigo, criado_em, '
        "atualizado_em) VALUES (1, 'P', '0', ?, 0, 0)",
        [profissao],
      );

  Future<Map<String, Object?>> lancamentoDe(String transacaoId) async =>
      (await banco
              .customSelect('SELECT * FROM lancamentos WHERE transacao_id = ?',
                  variables: [Variable.withString(transacaoId)])
              .getSingle())
          .data;

  Future<int> contar(String sql) async =>
      (await banco.customSelect('SELECT COUNT(*) AS n FROM $sql').getSingle())
          .read<int>('n');

  group('classificar e propor por remetente', () {
    setUp(() async {
      await transacao('t1', '2026-08-03', 45000, 'PIX RECEBIDO MARIA SOUZA');
      await transacao('t2', '2026-08-10', 45000, 'PIX-MARIA SOUZA');
      await transacao('t3', '2026-08-17', 45000, 'Pix recebido Maria Souza');
      await transacao('t4', '2026-08-20', 30000, 'PIX RECEBIDO JOAO');
    });

    test('1ª classificação grava o lançamento e propõe os outros do remetente',
        () async {
      final r = await repo.classificar(
        't1',
        const RespostasClassificacao(
            classificacao: ClassificacaoLancamento.rendimentoPf),
      );
      final l = await lancamentoDe('t1');
      expect(l['classificacao'], 'rendimentoPf');
      expect(l['origem_classificacao'], 'manual');
      expect(l['confirmada_em'], isNotNull);
      expect(l['nome_pagador'], 'MARIA SOUZA');
      expect(await contar("historico_classificacao WHERE para = 'rendimentoPf'"),
          1);
      expect(r.proposta!.rotulo,
          'Marcar os outros 2 como cliente (R\$ 900,00)');
      expect(r.proposta!.ids, ['t2', 't3']);
    });

    test('aceitar aplica só o declarado, confirma a regra; desfazer volta tudo',
        () async {
      final r = await repo.classificar(
        't1',
        const RespostasClassificacao(
            classificacao: ClassificacaoLancamento.rendimentoPf),
      );
      final aceita = await repo.aceitarProposta(r.proposta!, r.remetenteId!);
      expect((await lancamentoDe('t2'))['origem_classificacao'],
          'sugestaoAceita');
      expect((await lancamentoDe('t3'))['origem_classificacao'],
          'sugestaoAceita');
      expect(await contar("lancamentos WHERE transacao_id = 't4'"), 0,
          reason: 'outro remetente não entra na proposta');
      final rem = (await banco.select(banco.remetentes).getSingle());
      expect(rem.regraClassificacao, 'rendimentoPf');
      expect(rem.regraConfirmadaEm, isNotNull);

      await repo.desfazer(aceita);
      expect(await contar("lancamentos WHERE transacao_id IN ('t2','t3')"), 0);
      expect(await contar("lancamentos WHERE transacao_id = 't1'"), 1,
          reason: 'desfazer a proposta não desfaz a classificação que a gerou');
      final depois = await banco.select(banco.remetentes).getSingle();
      expect(depois.regraClassificacao, isNull);
      expect(depois.regraConfirmadaEm, isNull);
    });

    test('regra confirmada: crédito NOVO nasce "proposto pela regra" até o toque',
        () async {
      final r = await repo.classificar(
        't1',
        const RespostasClassificacao(
            classificacao: ClassificacaoLancamento.rendimentoPf),
      );
      await repo.aceitarProposta(r.proposta!, r.remetenteId!);
      await transacao('t5', '2026-09-02', 45000, 'PIX RECEBIDO MARIA SOUZA');

      expect(await repo.aplicarRegrasAosNovos(), 1);
      final l = await lancamentoDe('t5');
      expect(l['origem_classificacao'], 'regraRemetente');
      expect(l['confirmada_em'], isNull);

      final fila = await repo.fila();
      final item = fila.singleWhere((i) => i.transacaoId == 't5');
      expect(item.propostoPelaRegra, ClassificacaoLancamento.rendimentoPf);

      await repo.confirmar(item.lancamentoId!);
      expect((await lancamentoDe('t5'))['confirmada_em'], isNotNull);
      expect((await repo.fila()).any((i) => i.transacaoId == 't5'), isFalse);
    });

    test('regra gravada mas NÃO confirmada (ex.: remetente migrado da v1) '
        'não se aplica', () async {
      await banco.customStatement(
        'INSERT INTO remetentes (id, nome, chave_nome, regra_classificacao, '
        "criado_em) VALUES ('r', 'Maria', 'MARIA SOUZA', 'rendimentoPf', 0)",
      );
      expect(await repo.aplicarRegrasAosNovos(), 0);
      expect(await contar('lancamentos'), 0);
    });

    test('sem regra confirmada, nada é aplicado sozinho', () async {
      await repo.classificar(
        't1',
        const RespostasClassificacao(
            classificacao: ClassificacaoLancamento.rendimentoPf),
      );
      expect(await repo.aplicarRegrasAosNovos(), 0);
      expect(await contar("lancamentos WHERE transacao_id = 't2'"), 0);
    });
  });

  group('reembolso e repasse (P2, P3)', () {
    setUp(() => transacao('t1', '2026-03-15', 100000, 'PIX RECEBIDO ANA LIMA'));

    test('sem as respostas, nada é gravado', () async {
      await expectLater(
        repo.classificar('t1', const RespostasClassificacao(
            classificacao: ClassificacaoLancamento.repasse)),
        throwsArgumentError,
      );
      await expectLater(
        repo.classificar('t1', const RespostasClassificacao(
            classificacao: ClassificacaoLancamento.repasse,
            titular: TitularComprovante.profissional,
            custoEssencial: true)),
        throwsArgumentError,
        reason: 'essencial sem a data do pagamento do custo',
      );
      expect(await contar('lancamentos'), 0);
      expect(await contar('despesas_livro_caixa'), 0);
    });

    test('essencial: despesa no mês do PAGAMENTO do custo, ligada ao '
        'lançamento; reclassificar a tira', () async {
      final r = await repo.classificar(
        't1',
        const RespostasClassificacao(
          classificacao: ClassificacaoLancamento.repasse,
          titular: TitularComprovante.profissional,
          custoEssencial: true,
          dataPagamentoCusto: '2026-02-20',
          valorCustoCentavos: 80000,
        ),
      );
      final d = (await banco.select(banco.despesasLivroCaixa).getSingle());
      expect(d.competencia, '2026-02');
      expect(d.dataPagamento, '2026-02-20');
      expect(d.rubricaCodigo, rubricaCustoRepassadoEssencial);
      expect(d.valorDedutivelCentavos, 80000);
      expect(d.lancamentoOrigemId, r.lancamentoId);
      final l = await lancamentoDe('t1');
      expect((l['comprovante_titular'], l['custo_essencial']),
          ('profissional', 1));

      await repo.classificar('t1', const RespostasClassificacao(
          classificacao: ClassificacaoLancamento.pessoal));
      expect(await contar('despesas_livro_caixa'), 0);
      expect(await contar('historico_classificacao'), 2);
    });

    test('NF no CPF do cliente: neutro, sem despesa', () async {
      await repo.classificar('t1', const RespostasClassificacao(
          classificacao: ClassificacaoLancamento.reembolso,
          titular: TitularComprovante.cliente));
      expect(await contar('despesas_livro_caixa'), 0);
      expect((await lancamentoDe('t1'))['custo_essencial'], isNull);
    });
  });

  group('documento do pagador (decisão 3, rodada 2b)', () {
    test('profissão de saúde sem CPF: pendente; com CPF: informado e remetente '
        'pelo CPF; homônimo sem CPF fica separado', () async {
      await perfilComProfissao('psicologo');
      await transacao('t1', '2026-08-03', 20000, 'PIX RECEBIDO MARIA SOUZA');
      await transacao('t2', '2026-08-10', 20000, 'PIX RECEBIDO MARIA SOUZA');
      await transacao('t3', '2026-08-12', 20000, 'PIX RECEBIDO M SOUZA');

      await repo.classificar('t1', const RespostasClassificacao(
          classificacao: ClassificacaoLancamento.rendimentoPf));
      expect((await lancamentoDe('t1'))['status_documento_pagador'], 'pendente');

      await repo.classificar('t2', const RespostasClassificacao(
        classificacao: ClassificacaoLancamento.rendimentoPf,
        documentoPagador: '529.982.247-25',
        cpfBeneficiario: '111.444.777-35',
        nomeBeneficiario: 'Filho',
      ));
      final l2 = await lancamentoDe('t2');
      expect(l2['status_documento_pagador'], 'informado');
      expect(l2['cpf_pagador'], '52998224725');
      expect(l2['cpf_beneficiario'], '11144477735');

      // Outra grafia, mesmo CPF: une no mesmo remetente.
      await repo.classificar('t3', const RespostasClassificacao(
        classificacao: ClassificacaoLancamento.rendimentoPf,
        documentoPagador: '52998224725',
      ));
      final l3 = await lancamentoDe('t3');
      expect(l3['remetente_id'], l2['remetente_id']);
      // O homônimo sem CPF (t1) continua no remetente de nome.
      expect((await lancamentoDe('t1'))['remetente_id'],
          isNot(l2['remetente_id']));
      expect(await contar('remetentes'), 2);
    });

    test('profissão não regulamentada: CPF não exigido, e beneficiário não '
        'é gravado', () async {
      await perfilComProfissao('fotografo');
      await transacao('t1', '2026-08-03', 20000, 'PIX RECEBIDO ANA');
      await repo.classificar('t1', const RespostasClassificacao(
        classificacao: ClassificacaoLancamento.rendimentoPf,
        cpfBeneficiario: '111.444.777-35',
      ));
      final l = await lancamentoDe('t1');
      expect(l['status_documento_pagador'], 'naoExigido');
      expect(l['cpf_beneficiario'], isNull);
    });

    test('CPF inválido é recusado antes de gravar', () async {
      await transacao('t1', '2026-08-03', 20000, 'PIX RECEBIDO ANA');
      await expectLater(
        repo.classificar('t1', const RespostasClassificacao(
            classificacao: ClassificacaoLancamento.rendimentoPf,
            documentoPagador: '529.982.247-24')),
        throwsArgumentError,
      );
      expect(await contar('lancamentos'), 0);
    });

    test('débito não é recebimento', () async {
      await transacao('t1', '2026-08-03', -20000, 'PAGTO ALUGUEL');
      await expectLater(
        repo.classificar('t1', const RespostasClassificacao(
            classificacao: ClassificacaoLancamento.pessoal)),
        throwsArgumentError,
      );
    });
  });

  test('aba Mês: PJ fora da receita (P1) pela regra do core', () async {
    await transacao('t1', '2026-04-05', 600000, 'PIX RECEBIDO ANA');
    await transacao('t2', '2026-04-06', 200000, 'TED RECEBIDA EMPRESA X');
    await repo.classificar('t1', const RespostasClassificacao(
        classificacao: ClassificacaoLancamento.rendimentoPf));
    await repo.classificar('t2', const RespostasClassificacao(
      classificacao: ClassificacaoLancamento.recebidoPj,
      documentoPagador: '11.222.333/0001-81',
    ));
    final l2 = await lancamentoDe('t2');
    expect((l2['cnpj_pagador'], l2['status_documento_pagador']),
        ('11222333000181', 'informado'));

    final mes = (await RepositorioPainelDrift(banco).dadosDoAno(2026))['2026-04']!;
    expect(mes.receitaTributavelCentavos, 600000);
    expect(mes.lancamentosClassificados, 2);
  });
}
