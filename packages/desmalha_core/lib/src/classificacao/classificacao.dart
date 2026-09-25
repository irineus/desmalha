/// Do lançamento classificado à entrada do motor — a regra fiscal da
/// classificação, em Dart puro.
///
/// O banco guarda O QUE o usuário respondeu (classificação, titular do
/// comprovante, essencialidade); o que isso SIGNIFICA para o imposto do mês
/// mora aqui, e o app só aplica. Regras:
///
/// - rendimento de PF: receita tributável;
/// - recebido de PJ sem IRRF (rodada 4, P1): FORA da base mensal — fica
///   registrado para a seção própria do relatório anual;
/// - pessoal: fora de tudo;
/// - reembolso e repasse (rodadas 2b e 4, P2): a árvore de
///   [classificarRepasse]. No CPF do cliente, neutro. No CPF do
///   profissional, receita; e a despesa só entra se o custo for essencial à
///   atividade — lançada no mês em que o profissional PAGOU o custo (P3),
///   como despesa do livro-caixa com a rubrica `custo-repassado-essencial`.
library;

import '../carne_leao/apuracao.dart';
import '../carne_leao/estados_persistidos.dart';
import '../carne_leao/repasse.dart';
import '../catalogo/profissao.dart';
import '../dinheiro.dart';

/// Rubrica do catálogo em que entra a despesa de um reembolso/repasse
/// essencial com o comprovante no CPF do profissional.
const String rubricaCustoRepassadoEssencial = 'custo-repassado-essencial';

/// O que um lançamento classificado faz na apuração.
class EfeitoFiscal {
  const EfeitoFiscal({
    required this.entraNaReceita,
    required this.geraDespesa,
    required this.rendimentoDePj,
  });

  /// Soma na receita bruta tributável do mês do recebimento.
  final bool entraNaReceita;

  /// Pede uma despesa do livro-caixa (no mês do pagamento do custo).
  final bool geraDespesa;

  /// Vai para a seção de rendimentos de PJ do relatório anual (P1).
  final bool rendimentoDePj;

  static const nenhum = EfeitoFiscal(
    entraNaReceita: false,
    geraDespesa: false,
    rendimentoDePj: false,
  );
}

/// O efeito de [classificacao] com as respostas que ela exige.
///
/// Reembolso e repasse sem [titular] lançam [ArgumentError]: sem saber em
/// nome de quem está o comprovante, não há tributação a decidir — e decidir
/// pelo usuário é o que a regra proíbe. No CPF do profissional,
/// [custoEssencial] também é obrigatório (ver [classificarRepasse]).
EfeitoFiscal efeitoDoLancamento(
  ClassificacaoLancamento classificacao, {
  TitularComprovante? titular,
  bool? custoEssencial,
}) {
  switch (classificacao) {
    case ClassificacaoLancamento.rendimentoPf:
      return const EfeitoFiscal(
        entraNaReceita: true,
        geraDespesa: false,
        rendimentoDePj: false,
      );
    case ClassificacaoLancamento.recebidoPj:
      return const EfeitoFiscal(
        entraNaReceita: false,
        geraDespesa: false,
        rendimentoDePj: true,
      );
    case ClassificacaoLancamento.pessoal:
      return EfeitoFiscal.nenhum;
    case ClassificacaoLancamento.reembolso:
    case ClassificacaoLancamento.repasse:
      if (titular == null) {
        throw ArgumentError(
          '${classificacao.name} exige em nome de quem está o comprovante',
        );
      }
      return switch (classificarRepasse(
        comprovanteNoCpfDoCliente: titular == TitularComprovante.cliente,
        custoEssencialAoServico: custoEssencial,
      )) {
        TratamentoRepasse.transitoNeutro => EfeitoFiscal.nenhum,
        TratamentoRepasse.receitaComDespesa => const EfeitoFiscal(
            entraNaReceita: true,
            geraDespesa: true,
            rendimentoDePj: false,
          ),
        TratamentoRepasse.somenteReceita => const EfeitoFiscal(
            entraNaReceita: true,
            geraDespesa: false,
            rendimentoDePj: false,
          ),
      };
  }
}

/// Um lançamento como a agregação precisa dele.
class LancamentoClassificado {
  const LancamentoClassificado({
    required this.valorCentavos,
    required this.classificacao,
    this.titular,
    this.custoEssencial,
  });

  final int valorCentavos;
  final ClassificacaoLancamento classificacao;
  final TitularComprovante? titular;
  final bool? custoEssencial;

  EfeitoFiscal get efeito => efeitoDoLancamento(
        classificacao,
        titular: titular,
        custoEssencial: custoEssencial,
      );
}

/// Os números de uma competência, a partir do que foi classificado nela.
class TotaisDoMes {
  const TotaisDoMes({
    required this.receitaTributavelCentavos,
    required this.rendimentosPjCentavos,
    required this.despesasDedutiveisCentavos,
  });

  final int receitaTributavelCentavos;

  /// Fora da base mensal (P1); vai ao relatório anual.
  final int rendimentosPjCentavos;

  /// Livro-caixa com a trava de 20% e as vedações já aplicadas.
  final int despesasDedutiveisCentavos;
}

/// Soma os lançamentos RECEBIDOS e as despesas PAGAS na competência.
///
/// A despesa de um reembolso/repasse essencial não nasce aqui: ela é uma
/// despesa do livro-caixa com a data do pagamento do custo (P3), e chega
/// em [despesas] da competência em que foi paga — que pode não ser a do
/// recebimento.
TotaisDoMes totaisDoMes({
  required Iterable<LancamentoClassificado> lancamentos,
  Iterable<DespesaLivroCaixa> despesas = const [],
}) {
  var receita = 0;
  var pj = 0;
  for (final l in lancamentos) {
    final efeito = l.efeito;
    if (efeito.entraNaReceita) receita += l.valorCentavos;
    if (efeito.rendimentoDePj) pj += l.valorCentavos;
  }
  var dedutivel = 0;
  for (final d in despesas) {
    dedutivel += d.dedutivelCentavos;
  }
  return TotaisDoMes(
    receitaTributavelCentavos: receita,
    rendimentosPjCentavos: pj,
    despesasDedutiveisCentavos: dedutivel,
  );
}

/// A situação do documento do pagador de um lançamento.
///
/// Rodada 2/2b: profissão regulamentada exige o CPF de quem pagou (saúde,
/// também o do beneficiário — que por padrão é o próprio pagador). Sem ele
/// o lançamento continua tributável e é gravado: fica PENDENTE, nunca
/// dispensado. Recebido de PJ pede o CNPJ, que vai ao relatório anual.
StatusDocumentoPagador statusDocumento({
  required ClassificacaoLancamento classificacao,
  required EfeitoFiscal efeito,
  required Profissao? profissao,
  required bool temDocumento,
}) {
  if (temDocumento) return StatusDocumentoPagador.informado;
  if (classificacao == ClassificacaoLancamento.recebidoPj) {
    return StatusDocumentoPagador.pendente;
  }
  if (efeito.entraNaReceita && (profissao?.regulamentada ?? false)) {
    return StatusDocumentoPagador.pendente;
  }
  return StatusDocumentoPagador.naoExigido;
}

// ── Proposta por remetente (decisão 4 do owner) ────────────────────────

/// Um lançamento ainda sem classificação.
typedef PendenteDoRemetente = ({String id, int valorCentavos});

/// "Marcar os outros 2 como cliente (R$ 900,00)": o que a proposta faria,
/// declarado antes do toque. Nada é aplicado sem ele, e o app guarda o que
/// mudou para o desfazer.
class PropostaDeRegra {
  const PropostaDeRegra({
    required this.classificacao,
    required this.ids,
    required this.totalCentavos,
  });

  final ClassificacaoLancamento classificacao;
  final List<String> ids;
  final int totalCentavos;

  int get quantidade => ids.length;

  String get rotulo {
    final alvo = quantidade == 1 ? 'o outro' : 'os outros $quantidade';
    return 'Marcar $alvo como ${rotuloDaClassificacao(classificacao)} '
        '(${centavosParaExibicao(totalCentavos)})';
  }
}

/// Como a classificação aparece para o usuário.
String rotuloDaClassificacao(ClassificacaoLancamento c) => switch (c) {
      ClassificacaoLancamento.rendimentoPf => 'cliente',
      ClassificacaoLancamento.recebidoPj => 'recebido de empresa',
      ClassificacaoLancamento.pessoal => 'pessoal',
      ClassificacaoLancamento.reembolso => 'reembolso',
      ClassificacaoLancamento.repasse => 'repasse',
    };

/// A proposta que nasce da 1ª classificação de um remetente, para os
/// [pendentes] do mesmo remetente — ou `null` se não há o que propor.
///
/// Reembolso e repasse não viram proposta: as respostas (comprovante,
/// essencialidade) são de cada recebimento, não do remetente.
PropostaDeRegra? propostaParaRemetente({
  required ClassificacaoLancamento classificada,
  required Iterable<PendenteDoRemetente> pendentes,
}) {
  if (classificada == ClassificacaoLancamento.reembolso ||
      classificada == ClassificacaoLancamento.repasse) {
    return null;
  }
  final lista = pendentes.toList();
  if (lista.isEmpty) return null;
  var total = 0;
  for (final p in lista) {
    total += p.valorCentavos;
  }
  return PropostaDeRegra(
    classificacao: classificada,
    ids: [for (final p in lista) p.id],
    totalCentavos: total,
  );
}

/// A classificação que uma regra CONFIRMADA dá a um lançamento novo do
/// remetente — ou `null` se não há regra confirmada. O lançamento nasce
/// `regraRemetente` e sem `confirmada_em`: aparece na fila como "proposto
/// pela regra" até o toque.
ClassificacaoLancamento? classificacaoPelaRegra({
  required ClassificacaoLancamento? regra,
  required bool regraConfirmada,
}) {
  if (!regraConfirmada || regra == null) return null;
  if (regra == ClassificacaoLancamento.reembolso ||
      regra == ClassificacaoLancamento.repasse) {
    return null;
  }
  return regra;
}
