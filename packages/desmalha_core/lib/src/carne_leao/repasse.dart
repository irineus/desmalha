/// Árvore de decisão de repasse de terceiros e custas, definida pelo
/// contador (rodada 3, ago/2026) para a interface de classificação.
///
/// O repasse exige um segundo passo de UX — não é classificação automática
/// de "receita + despesa", porque a dedutibilidade depende da necessidade
/// profissional do custo.
library;

/// Destino fiscal de um valor recebido a título de repasse/custa.
enum TratamentoRepasse {
  /// Comprovante no CPF do cliente: trânsito puro. Não soma na receita e
  /// não entra no livro-caixa — operação neutra.
  transitoNeutro,

  /// Comprovante no CPF do profissional e custo essencial ao serviço:
  /// entra como receita bruta tributável E como despesa do livro-caixa
  /// (neutraliza na base).
  receitaComDespesa,

  /// Comprovante no CPF do profissional e custo NÃO essencial: permanece
  /// só como receita, e será tributado.
  somenteReceita,
}

/// Resolve a árvore de decisão do repasse.
///
/// [custoEssencialAoServico] é a resposta à segunda pergunta da interface
/// ("Esse custo é essencial para a realização do seu serviço?"). É
/// obrigatória quando o comprovante está no CPF do profissional — passar
/// `null` nesse caso lança [ArgumentError], porque decidir sozinho pelo
/// usuário violaria a regra de que nada recorrente é lançado sem
/// confirmação.
TratamentoRepasse classificarRepasse({
  required bool comprovanteNoCpfDoCliente,
  bool? custoEssencialAoServico,
}) {
  if (comprovanteNoCpfDoCliente) return TratamentoRepasse.transitoNeutro;
  if (custoEssencialAoServico == null) {
    throw ArgumentError(
      'comprovante no CPF do profissional exige a resposta sobre '
      'essencialidade do custo',
    );
  }
  return custoEssencialAoServico
      ? TratamentoRepasse.receitaComDespesa
      : TratamentoRepasse.somenteReceita;
}
