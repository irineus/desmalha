/// O que o dashboard lê do banco local: por competência, a receita dos
/// lançamentos CLASSIFICADOS como tributáveis, quantos lançamentos têm
/// classificação e quantos créditos importados ainda não têm.
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
    final classificados = await banco
        .customSelect(
          'SELECT competencia, '
          'SUM(CASE WHEN classificacao = ? THEN valor_centavos '
          'ELSE 0 END) AS receita, COUNT(*) AS n '
          'FROM lancamentos WHERE competencia BETWEEN ? AND ? '
          'GROUP BY competencia',
          variables: [
            Variable.withString(ClassificacaoLancamento.rendimentoPf.name),
            Variable.withString(de),
            Variable.withString(ate),
          ],
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

    final receita = <String, int>{};
    final nClassificados = <String, int>{};
    final nPendentes = <String, int>{};
    for (final l in classificados) {
      final c = l.read<String>('competencia');
      receita[c] = l.read<int>('receita');
      nClassificados[c] = l.read<int>('n');
    }
    for (final l in pendentes) {
      nPendentes[l.read<String>('competencia')] = l.read<int>('n');
    }
    return {
      for (final c in {...nClassificados.keys, ...nPendentes.keys})
        c: DadosDoMes(
          receitaTributavelCentavos: receita[c] ?? 0,
          lancamentosClassificados: nClassificados[c] ?? 0,
          recebimentosAClassificar: nPendentes[c] ?? 0,
        ),
    };
  }
}
