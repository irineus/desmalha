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

  test('outro ano fica de fora', () async {
    await lancamento('2025-12', 45000, 'rendimentoPf');
    await transacao('2027-01-02', 10000);
    expect(await repo.dadosDoAno(2026), isEmpty);
  });
}
