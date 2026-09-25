/// Reúne o que o relatório anual lê do aparelho — os dados de cada mês
/// (os mesmos do painel), as guias pagas e os recebimentos de PJ — e deixa
/// o core montar a visão (`montarRelatorioAnual`). Nada é gravado: o
/// relatório é uma visão (decisão 9 do owner).
library;

import 'package:desmalha_core/desmalha_core.dart';
import 'package:drift/drift.dart' show Variable;

import '../dados/banco.dart';
import '../painel/repositorio_fechamento.dart';
import '../painel/repositorio_painel.dart';

class RepositorioRelatorio {
  RepositorioRelatorio(
    this._banco, {
    required RepositorioPainel painel,
    required RepositorioFechamento fechamento,
    // Parâmetro nomeado não pode começar com underscore.
    // ignore: prefer_initializing_formals
  })  : _painel = painel,
        // ignore: prefer_initializing_formals
        _fechamento = fechamento;

  final BancoLocal _banco;
  final RepositorioPainel _painel;
  final RepositorioFechamento _fechamento;

  /// Recebido de PJ no [ano] (pela data do recebimento), com o CNPJ e o
  /// nome guardados no lançamento (P1).
  Future<List<RecebimentoPj>> recebimentosPj(int ano) async => [
        for (final l in await _banco.customSelect(
          'SELECT cnpj_pagador, nome_pagador, valor_centavos FROM lancamentos '
          "WHERE classificacao = 'recebidoPj' "
          'AND substr(data_recebimento, 1, 4) = ? '
          'ORDER BY data_recebimento, id',
          variables: [Variable.withString('$ano')],
        ).get())
          RecebimentoPj(
            cnpj: l.read<String?>('cnpj_pagador'),
            nome: l.read<String?>('nome_pagador'),
            valorCentavos: l.read<int>('valor_centavos'),
          ),
      ];

  /// O relatório do [ano], montado pelo core.
  Future<RelatorioAnual> relatorio(int ano, Catalogo catalogo) async {
    final pagamentos = await _fechamento.pagamentos(ano);
    return montarRelatorioAnual(
      ano: ano,
      dadosDoAno: await _painel.dadosDoAno(ano),
      guiasPagas: [
        for (final p in pagamentos)
          GuiaPagaDoRelatorio(
            periodo: p.periodo,
            principalCentavos: p.principalCentavos,
          ),
      ],
      recebimentosPj: await recebimentosPj(ano),
      tabelaPara: catalogo.tabelaVigentePara,
    );
  }
}
