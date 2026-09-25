import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/painel/repositorio_fechamento.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lembretes/notificacoes_falsas.dart';

void main() {
  late BancoLocal banco;
  late RepositorioFechamento repo;
  final catalogo = catalogoDoSeed();

  setUp(() {
    banco = BancoLocal(NativeDatabase.memory());
    repo = RepositorioFechamento(banco, agoraEpochMs: () => 1000);
  });
  tearDown(() => banco.close());

  DadosDoMes receita(int centavos) =>
      DadosDoMes(receitaTributavelCentavos: centavos, lancamentosClassificados: 1);

  Map<String, MesApurado> ano(
    Map<String, DadosDoMes> dados, {
    Set<String> quitados = const {},
  }) {
    final apuradas = apurarAno(
      ate: '2026-12',
      dadosDoAno: dados,
      catalogo: catalogo,
      periodosQuitados: quitados,
    );
    return {
      for (final a in apuradas.values)
        a.competencia: MesApurado(
          apuracao: a,
          dados: dados[a.competencia] ?? const DadosDoMes(),
          tabela: catalogo.tabelaVigentePara(a.competencia),
        ),
    };
  }

  Future<List<Map<String, Object?>>> apuracoes() async => [
        for (final l in await banco
            .customSelect(
              'SELECT competencia, versao, status, imposto_devido_centavos, '
              'total_para_darf_centavos, motor_versao FROM apuracoes_mensais '
              'ORDER BY competencia, versao',
            )
            .get())
          l.data,
      ];

  test('marcar pago uma guia de vários meses fecha todos, e o pagamento '
      'guarda as competências (N:1, P10)', () async {
    // Janeiro R$ 5,36 acumula; fevereiro soma R$ 17,89.
    final dados = {'2026-01': receita(501500), '2026-02': receita(503500)};
    await repo.marcarPago(
      periodo: '2026-02',
      competencias: ['2026-01', '2026-02'],
      meses: ano(dados),
      principalCentavos: 1789,
      vencimento: '2026-03-31',
      pagoEm: '2026-03-20',
    );
    expect(
      (await apuracoes()).map((a) => (a['competencia'], a['status'], a['versao'])),
      [('2026-01', 'fechada', 1), ('2026-02', 'fechada', 1)],
    );
    expect((await apuracoes()).first['motor_versao'], versaoDoMotor);
    final p = (await repo.pagamentos(2026)).single;
    expect(p.competencias, ['2026-01', '2026-02']);
    expect(
      (p.periodo, p.principalCentavos, p.pagoEm),
      ('2026-02', 1789, '2026-03-20'),
    );
    expect((await repo.fechadas(2026)).keys, ['2026-01', '2026-02']);
  });

  test('complementar soma ao principal da guia do período (P8)', () async {
    final dados = {'2026-03': receita(600000)};
    await repo.marcarPago(
      periodo: '2026-03',
      competencias: ['2026-03'],
      meses: ano(dados),
      principalCentavos: 39454,
      vencimento: '2026-04-30',
      pagoEm: '2026-04-20',
    );
    await repo.registrarComplementar(
      periodo: '2026-03',
      principalCentavos: 40814,
      acrescimosCentavos: 1500,
      vencimento: '2026-04-30',
      pagoEm: '2026-06-02',
    );
    final guia = (await repo.guiasPagas(2026)).single;
    expect((guia.periodo, guia.principalPagoCentavos), ('2026-03', 80268));
    final pagamentos = await repo.pagamentos(2026);
    expect(pagamentos.map((p) => (p.pagoEm, p.acrescimosCentavos)),
        [('2026-06-02', 1500), ('2026-04-20', 0)]);
    await expectLater(
      repo.registrarComplementar(
        periodo: '2026-05',
        principalCentavos: 100,
        vencimento: '2026-06-30',
        pagoEm: '2026-06-02',
      ),
      throwsStateError,
    );
  });

  test('correção: versão +1, a anterior vira substituida e a guia aponta '
      'para a nova', () async {
    await repo.marcarPago(
      periodo: '2026-03',
      competencias: ['2026-03'],
      meses: ano({'2026-03': receita(600000)}),
      principalCentavos: 39454,
      vencimento: '2026-04-30',
      pagoEm: '2026-04-20',
    );
    final mesmo = ano({'2026-03': receita(600000)}, quitados: {'2026-03'});
    expect(await repo.registrarCorrecao(mesmo), isEmpty,
        reason: 'nada mudou, nada regravado');

    final corrigido =
        ano({'2026-03': receita(700000)}, quitados: {'2026-03'});
    expect(await repo.registrarCorrecao(corrigido), ['2026-03']);
    expect(
      (await apuracoes()).map((a) =>
          (a['versao'], a['status'], a['imposto_devido_centavos'])),
      [(1, 'substituida', 39454), (2, 'fechada', 80268)],
    );
    final ligada = await banco.customSelect(
      'SELECT a.versao FROM darf_competencias dc '
      'JOIN apuracoes_mensais a ON a.id = dc.apuracao_id',
    ).getSingle();
    expect(ligada.read<int>('versao'), 2);
  });

  test('fechar mês sem guia: só isento ou resíduo de dezembro', () async {
    final meses = ano({
      '2026-04': receita(400000), // isento
      '2026-05': receita(600000), // tem DARF
    });
    await repo.fecharSemGuia(meses['2026-04']!);
    expect((await repo.fechadas(2026)).keys, ['2026-04']);
    await expectLater(repo.fecharSemGuia(meses['2026-05']!), throwsStateError);
  });

  test('pagamento sem o recálculo de uma competência é recusado', () async {
    await expectLater(
      repo.marcarPago(
        periodo: '2026-02',
        competencias: ['2026-01', '2026-02'],
        meses: ano({'2026-02': receita(600000)}),
        principalCentavos: 100,
        vencimento: '2026-03-31',
        pagoEm: '2026-03-20',
      ),
      throwsArgumentError,
    );
    final n = await banco
        .customSelect('SELECT COUNT(*) AS n FROM darfs',
            variables: const <Variable>[])
        .getSingle();
    expect(n.read<int>('n'), 0, reason: 'nada gravado pela metade');
  });
}
