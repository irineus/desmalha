/// O que o dashboard lê do banco local: por competência, a receita dos
/// lançamentos CLASSIFICADOS, quantos lançamentos têm classificação, quantos
/// créditos importados ainda não têm, e as deduções do mês — livro-caixa,
/// INSS e dependentes.
///
/// A decisão do que mostrar é do `desmalha_core` (`montarPainelMensal`);
/// aqui só se agrega.
library;

import 'package:desmalha_core/desmalha_core.dart';
import 'package:drift/drift.dart' show Variable;

import '../dados/banco.dart';

abstract interface class RepositorioPainel {
  /// Os meses de [ano] que têm algum dado, por competência `'YYYY-MM'`.
  Future<Map<String, DadosDoMes>> dadosDoAno(int ano);
}

class RepositorioPainelDrift implements RepositorioPainel {
  RepositorioPainelDrift(this.banco);
  final BancoLocal banco;

  @override
  Future<Map<String, DadosDoMes>> dadosDoAno(int ano) async {
    final de = '$ano-01';
    final ate = '$ano-12';
    // Linha a linha: o que cada classificação faz na receita é regra do
    // core (totaisDoMes — P1: PJ fora; P2: reembolso/repasse pela árvore),
    // não um CASE em SQL.
    final classificados = await banco
        .customSelect(
          'SELECT competencia, valor_centavos, classificacao, '
          'comprovante_titular, custo_essencial '
          'FROM lancamentos WHERE competencia BETWEEN ? AND ?',
          variables: [Variable.withString(de), Variable.withString(ate)],
        )
        .get();
    // Crédito importado sem lançamento = recebimento a classificar. O mês
    // é o da data do extrato (regime de caixa).
    final pendentes = await banco
        .customSelect(
          'SELECT substr(t.data, 1, 7) AS competencia, COUNT(*) AS n '
          'FROM transacoes t LEFT JOIN lancamentos l ON l.transacao_id = t.id '
          'WHERE t.valor_centavos > 0 AND l.id IS NULL '
          'AND substr(t.data, 1, 7) BETWEEN ? AND ? '
          'GROUP BY substr(t.data, 1, 7)',
          variables: [Variable.withString(de), Variable.withString(ate)],
        )
        .get();

    final porMes = <String, List<LancamentoClassificado>>{};
    for (final l in classificados) {
      (porMes[l.read<String>('competencia')] ??= []).add(
        LancamentoClassificado(
          valorCentavos: l.read<int>('valor_centavos'),
          classificacao:
              ClassificacaoLancamento.values.byName(l.read<String>('classificacao')),
          titular: switch (l.readNullable<String>('comprovante_titular')) {
            null => null,
            final t => TitularComprovante.values.byName(t),
          },
          custoEssencial: switch (l.readNullable<int>('custo_essencial')) {
            null => null,
            final e => e == 1,
          },
        ),
      );
    }
    final receita = <String, int>{
      for (final e in porMes.entries)
        e.key: totaisDoMes(lancamentos: e.value).receitaTributavelCentavos,
    };
    final nClassificados = {
      for (final e in porMes.entries) e.key: e.value.length,
    };
    final nPendentes = <String, int>{};
    for (final l in pendentes) {
      nPendentes[l.read<String>('competencia')] = l.read<int>('n');
    }

    // Livro-caixa: o dedutível já gravado pela rubrica (trava de 20% e
    // vedação decididas pelo core no registro).
    final despesas = <String, int>{
      for (final l in await banco.customSelect(
        'SELECT competencia, SUM(valor_dedutivel_centavos) AS total '
        'FROM despesas_livro_caixa WHERE competencia BETWEEN ? AND ? '
        'GROUP BY competencia',
        variables: [Variable.withString(de), Variable.withString(ate)],
      ).get())
        l.read<String>('competencia'): l.read<int>('total'),
    };

    // INSS: as respostas do mês; o que deduz (só o principal, "não paguei"
    // = zero) é do core — rodada 4, P6.
    final guias = <String, List<PagamentoInssDoMes>>{};
    for (final l in await banco.customSelect(
      'SELECT competencia, situacao, valor_centavos, acrescimos_centavos '
      'FROM pagamentos_inss WHERE competencia BETWEEN ? AND ?',
      variables: [Variable.withString(de), Variable.withString(ate)],
    ).get()) {
      (guias[l.read<String>('competencia')] ??= []).add(
        l.read<String>('situacao') == SituacaoInss.naoPago.name
            ? const PagamentoInssDoMes.naoPago()
            : PagamentoInssDoMes.pago(
                principalCentavos: l.read<int>('valor_centavos'),
                acrescimosCentavos: l.read<int>('acrescimos_centavos'),
              ),
      );
    }

    // Dependentes: o mês inteiro de quem existiu em algum dia — P7.
    final vigencias = [
      for (final d in await banco.select(banco.dependentes).get())
        VigenciaDependente(inicio: d.vigenciaInicio, fim: d.vigenciaFim),
    ];

    return {
      for (final c in {
        ...nClassificados.keys,
        ...nPendentes.keys,
        ...despesas.keys,
      })
        c: DadosDoMes(
          receitaTributavelCentavos: receita[c] ?? 0,
          lancamentosClassificados: nClassificados[c] ?? 0,
          recebimentosAClassificar: nPendentes[c] ?? 0,
          despesasDedutiveisCentavos: despesas[c] ?? 0,
          inssDedutivelCentavos: inssDedutivelDoMes(guias[c] ?? const []),
          dependentes: dependentesNoMes(vigencias, c),
        ),
    };
  }
}
