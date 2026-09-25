/// Os valores que o banco local grava em colunas de estado.
///
/// Regra (cadeia 2, decisão 6 do owner, 25/09/2026): **os enums do banco são
/// os do motor.** Cada CHECK de `esquema.drift` lista exatamente os `.name`
/// de um enum daqui — ou de [CenarioVencedor] e [StatusDarf], do motor —, e
/// um teste do app lê o `.drift` e reprova qualquer divergência. É a mesma
/// grafia dos cenários table-driven (`"cenarioVencedor": "deducoesReais"`):
/// uma string só do JSON de teste até a coluna.
///
/// Renomear um valor daqui é migração de banco, não refactor.
library;

/// O que um crédito do extrato É, fiscalmente.
enum ClassificacaoLancamento {
  /// Rendimento de trabalho recebido de pessoa física — entra na base
  /// mensal do carnê-leão.
  rendimentoPf,

  /// Recebido de pessoa jurídica sem IRRF (rodada 4, P1): FORA da base
  /// mensal; vai para o relatório anual, com CNPJ e nome, numa seção
  /// própria.
  recebidoPj,

  /// Dinheiro que não é rendimento (transferência entre contas próprias,
  /// presente, devolução pessoal).
  pessoal,

  /// Reembolso de gasto feito para o cliente. Comprovante no CPF do cliente
  /// → neutro; no CPF do profissional → receita, e a despesa só entra se for
  /// essencial à atividade (rodada 4, P2 — a mesma árvore do repasse).
  reembolso,

  /// Repasse de terceiros/custas: mesma árvore de [reembolso]
  /// (`classificarRepasse`), com a despesa no mês do PAGAMENTO (P3).
  repasse,
}

/// Em nome de quem está o comprovante de um reembolso ou repasse.
enum TitularComprovante { cliente, profissional }

/// Situação do CPF (ou CNPJ) do pagador num lançamento.
///
/// Falta de CPF não impede lançar nem fechar o mês: é pendência documental
/// (rodada 2b), nunca dispensa de tributação.
enum StatusDocumentoPagador {
  /// Documento gravado no lançamento.
  informado,

  /// A profissão exige e ainda não há documento.
  pendente,

  /// A profissão não exige CPF do pagador.
  naoExigido,
}

/// Quem classificou (decisão 4 do owner).
enum OrigemClassificacao {
  /// Toque do usuário no próprio lançamento.
  manual,

  /// O usuário aceitou a proposta por remetente para estes lançamentos.
  sugestaoAceita,

  /// Aplicado a um lançamento NOVO de remetente com regra confirmada; ainda
  /// aparece na fila como "proposto pela regra" até o toque.
  regraRemetente,
}

/// Resposta do mês à pergunta "Você pagou INSS em `<mês>`?" (M1).
enum SituacaoInss {
  pago,

  /// "Não paguei", gravado explicitamente — diferente de não ter respondido.
  naoPago,
}

/// Como uma despesa do livro-caixa foi paga. A competência sai da data do
/// PAGAMENTO; no cartão de crédito, da data da COMPRA (rodada 4b, P5).
enum FormaPagamentoDespesa { extrato, dinheiro, cartaoCredito, outra }

/// Ciclo de vida de uma apuração gravada.
enum StatusApuracao {
  rascunho,
  fechada,

  /// Reaberta: a versão seguinte a substitui (decisão 7 do owner).
  substituida,
}

/// Ciclo de vida da guia. "Vencida" não é estado gravado: é a data de
/// vencimento contra o relógio.
enum StatusGuiaDarf { gerada, paga, cancelada }
