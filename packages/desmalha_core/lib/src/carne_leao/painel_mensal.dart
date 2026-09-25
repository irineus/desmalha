/// O que o dashboard do mês mostra — decidido aqui, em Dart puro, a partir
/// do que o motor ([apurarSequencia]) calcula sobre lançamentos
/// CLASSIFICADOS.
///
/// Regra do produto (decisão travada, 24/09/2026): sem lançamento
/// classificado no mês, NÃO há imposto na tela — há estado vazio honesto.
/// Mês sem dado nunca vira "isento": isenção é resultado de cálculo sobre
/// o que o usuário classificou, não ausência de informação.
///
/// Recebimento ainda não classificado não entra na receita (seria imposto
/// sobre receita não classificada); ele aparece como PENDÊNCIA ao lado do
/// resultado — pendência sinaliza, não bloqueia (wireframes, decisão 6).
library;

import '../catalogo/catalogo.dart';
import 'apuracao.dart';

/// O que a camada local sabe de uma competência.
class DadosDoMes {
  const DadosDoMes({
    this.receitaTributavelCentavos = 0,
    this.lancamentosClassificados = 0,
    this.recebimentosAClassificar = 0,
    this.despesasDedutiveisCentavos = 0,
    this.inssDedutivelCentavos = 0,
    this.dependentes = 0,
  });

  /// Σ lançamentos classificados como tributáveis (regime de caixa).
  final int receitaTributavelCentavos;

  /// Livro-caixa do mês, com a trava de 20% e as vedações aplicadas.
  final int despesasDedutiveisCentavos;

  /// INSS do mês — só o principal ([inssDedutivelDoMes], rodada 4 P6).
  final int inssDedutivelCentavos;

  /// Dependentes que contam no mês ([dependentesNoMes], rodada 4 P7).
  final int dependentes;

  /// Quantos lançamentos do mês têm classificação — qualquer uma.
  final int lancamentosClassificados;

  /// Créditos importados do mês ainda sem classificação.
  final int recebimentosAClassificar;
}

/// Um mês da evolução do ano: `null` quando não há o que apurar.
typedef MesDaEvolucao = ({String competencia, ApuracaoMensal? apuracao});

sealed class PainelMensal {
  const PainelMensal(this.competencia);

  final String competencia;
}

/// Nada importado nem classificado no mês.
class PainelSemDados extends PainelMensal {
  const PainelSemDados(super.competencia);
}

/// Há recebimentos importados, nenhum classificado: nada a calcular ainda.
class PainelAClassificar extends PainelMensal {
  const PainelAClassificar(super.competencia, this.recebimentosAClassificar);

  final int recebimentosAClassificar;
}

/// O catálogo não tem a tabela do IRPF de algum mês necessário: falha
/// visível, nunca cálculo com tabela de outro período.
class PainelSemTabela extends PainelMensal {
  const PainelSemTabela(super.competencia, this.motivo);

  final String motivo;
}

class PainelApurado extends PainelMensal {
  const PainelApurado(
    super.competencia, {
    required this.apuracao,
    required this.recebimentosAClassificar,
    required this.vencimento,
    required this.motivoSemVencimento,
    required this.evolucao,
  });

  /// O resultado do motor para o mês, encadeado desde janeiro.
  final ApuracaoMensal apuracao;

  /// Pendência ao lado do resultado: o imposto mostrado não os inclui.
  final int recebimentosAClassificar;

  /// Vencimento do DARF (`'YYYY-MM-DD'`), ou `null` com
  /// [motivoSemVencimento] quando o catálogo não cobre os feriados do ano.
  final String? vencimento;
  final String? motivoSemVencimento;

  /// Janeiro até o mês, na ordem.
  final List<MesDaEvolucao> evolucao;
}

/// A entrada do motor para a [competencia], a partir do que a camada local
/// sabe dela — a mesma que o painel, o fechamento e a memória de cálculo
/// usam.
EntradaApuracao entradaDoPainel(String competencia, DadosDoMes? dados) =>
    EntradaApuracao(
      competencia: competencia,
      receitaBrutaCentavos: dados?.receitaTributavelCentavos ?? 0,
      despesasDedutiveisCentavos: dados?.despesasDedutiveisCentavos ?? 0,
      inssPagoCentavos: dados?.inssDedutivelCentavos ?? 0,
      numeroDependentes: dados?.dependentes ?? 0,
    );

/// O ano encadeado de janeiro até [ate] (`'YYYY-MM'`), por competência —
/// o mesmo cálculo que o painel mostra, para quem precisa do ano inteiro
/// (fechamento, acerto de guia paga).
///
/// Entram os meses com lançamento classificado, os com despesa (o excesso
/// do livro-caixa vira saldo negativo) e os [periodosQuitados]. Lança
/// [StateError] se falta a tabela do IRPF de algum deles.
Map<String, ApuracaoMensal> apurarAno({
  required String ate,
  required Map<String, DadosDoMes> dadosDoAno,
  required Catalogo catalogo,
  Set<String> periodosQuitados = const {},
}) {
  final ano = ate.substring(0, 4);
  final comDados = [
    for (var m = 1; m <= int.parse(ate.substring(5, 7)); m++)
      if ('$ano-${m.toString().padLeft(2, '0')}' case final c
          when (dadosDoAno[c]?.lancamentosClassificados ?? 0) > 0 ||
              (dadosDoAno[c]?.despesasDedutiveisCentavos ?? 0) > 0 ||
              periodosQuitados.contains(c))
        c,
  ];
  return {
    for (final a in apurarSequencia(
      entradas: [for (final c in comDados) entradaDoPainel(c, dadosDoAno[c])],
      tabelaPara: catalogo.tabelaVigentePara,
      periodosQuitados: periodosQuitados,
    ))
      a.competencia: a,
  };
}

/// Monta o painel da [competencia] (`'YYYY-MM'`).
///
/// [dadosDoAno] traz os meses do MESMO ano-calendário (as chaves fora dele
/// são ignoradas): o motor encadeia saldo negativo e imposto acumulado de
/// janeiro em diante e zera na virada do ano.
///
/// Mês sem lançamento classificado e sem despesa fica fora do encadeamento —
/// apurá-lo não mudaria nem o saldo nem o acumulado. Mês SÓ com despesa
/// entra: o excesso do livro-caixa vira saldo negativo para os seguintes.
/// (INSS e dependentes sozinhos não transportam nada.)
///
/// [periodosQuitados]: períodos de guias já pagas — entram no encadeamento
/// e zeram o acumulado depois deles (ver [apurarSequencia]).
PainelMensal montarPainelMensal({
  required String competencia,
  required Map<String, DadosDoMes> dadosDoAno,
  required Catalogo catalogo,
  Set<String> periodosQuitados = const {},
}) {
  final ano = competencia.substring(0, 4);
  final doMes = dadosDoAno[competencia] ?? const DadosDoMes();
  if (doMes.lancamentosClassificados == 0) {
    return doMes.recebimentosAClassificar > 0
        ? PainelAClassificar(competencia, doMes.recebimentosAClassificar)
        : PainelSemDados(competencia);
  }

  final meses = [
    for (var m = 1; m <= int.parse(competencia.substring(5, 7)); m++)
      '$ano-${m.toString().padLeft(2, '0')}',
  ];

  final Map<String, ApuracaoMensal> porCompetencia;
  try {
    porCompetencia = apurarAno(
      ate: competencia,
      dadosDoAno: dadosDoAno,
      catalogo: catalogo,
      periodosQuitados: periodosQuitados,
    );
  } on StateError catch (e) {
    return PainelSemTabela(competencia, e.message);
  }

  String? vencimento;
  String? motivo;
  try {
    vencimento = catalogo.vencimentoDarfDe(competencia);
  } on StateError catch (e) {
    motivo = e.message;
  }

  return PainelApurado(
    competencia,
    apuracao: porCompetencia[competencia]!,
    recebimentosAClassificar: doMes.recebimentosAClassificar,
    vencimento: vencimento,
    motivoSemVencimento: motivo,
    evolucao: [
      for (final c in meses) (competencia: c, apuracao: porCompetencia[c]),
    ],
  );
}
