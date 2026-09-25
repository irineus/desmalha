/// Motor de apuração mensal do carnê-leão.
///
/// Implementa a especificação fechada com o contador (rodada 3, ago/2026):
/// dois cenários por mês (deduções reais × desconto simplificado), aplica-se
/// o mais vantajoso; redutor da Lei 15.270/2025 sobre o imposto (nunca sobre
/// a base); saldo negativo do livro-caixa encadeado dentro do ano-calendário;
/// DARF mínimo de R$ 10,00 (Lei 9.430/1996, art. 68) com acumulação entre
/// competências.
///
/// Roda em Dart puro, no dispositivo, offline — não é serviço de backend.
/// Dinheiro em `int` de centavos; intermediários em micro-centavos exatos;
/// o ajuste à segunda casa acontece uma única vez, no imposto final.
library;

import 'tabela_irpf.dart';

/// Valor mínimo de DARF (Lei 9.430/1996, art. 68): abaixo de R$ 10,00 a guia
/// não é emitida e o imposto acumula para o mês seguinte.
const int darfMinimoCentavos = 1000;

/// Como o imposto final do mês é ajustado à segunda casa decimal.
///
/// A posição do contador é truncamento (padrão sistêmico da rede
/// arrecadadora), pendente de contraprova empírica no Carnê-Leão Web —
/// por isso o modo é configurável (spec, seção 7).
enum ModoAjusteFinal {
  /// Descarta o que passa da segunda casa (R$ 124,568 → R$ 124,56). Padrão.
  truncar,

  /// Arredondamento comercial (half-up) na segunda casa.
  arredondarHalfUp,
}

/// Qual cenário venceu o mês — informação de valor para o usuário,
/// persistida na apuração.
enum CenarioVencedor {
  /// Cenário A: livro-caixa + INSS + dependentes.
  deducoesReais,

  /// Cenário B: desconto simplificado. Também vence em empate exato,
  /// porque preserva o saldo negativo do livro-caixa para os meses
  /// seguintes — mesmo imposto hoje, mais dedução amanhã.
  descontoSimplificado,
}

/// Situação da guia no mês.
enum StatusDarf {
  /// Total a recolher ≥ R$ 10,00 — DARF emitido.
  emitido,

  /// Total positivo abaixo de R$ 10,00 — não emite; acumula para o
  /// mês seguinte, sem multa nem juros.
  acumulaParaProximoMes,

  /// Resíduo abaixo de R$ 10,00 em dezembro — não transporta para janeiro;
  /// é absorvido na DIRPF do ano seguinte (spec, seção 5).
  residuoParaDirpf,

  /// Nada a recolher no mês (base isenta ou imposto zerado pelo redutor).
  semImposto,
}

/// Um lançamento dedutível do livro-caixa, já classificado.
///
/// Existe para aplicar a trava de home office POR LANÇAMENTO (nunca sobre o
/// total): o usuário precisa ver o valor efetivamente deduzido de cada conta.
class DespesaLivroCaixa {
  const DespesaLivroCaixa({
    required this.valorCentavos,
    this.sujeitaTravaHomeOffice = false,
    this.dedutivel = true,
  });

  final int valorCentavos;

  /// `false` para rubrica vedada: o gasto é registrado, mas deduz zero.
  final bool dedutivel;

  /// `true` para rubricas de manutenção da residência usadas como espaço
  /// profissional (aluguel, condomínio, luz, água, internet) — só 20% do
  /// valor é dedutível.
  final bool sujeitaTravaHomeOffice;

  /// Valor que entra no livro-caixa, com a trava aplicada.
  int get dedutivelCentavos {
    if (!dedutivel) return 0;
    return sujeitaTravaHomeOffice
        ? valorCentavos * travaHomeOfficePontosBase ~/ 10000
        : valorCentavos;
  }
}

/// Fração dedutível das rubricas de manutenção da residência: 20%.
const int travaHomeOfficePontosBase = 2000;

/// Entradas de uma competência, já agregadas pela camada de classificação.
class EntradaApuracao {
  EntradaApuracao({
    required this.competencia,
    required this.receitaBrutaCentavos,
    this.despesasDedutiveisCentavos = 0,
    this.inssPagoCentavos = 0,
    this.numeroDependentes = 0,
    this.irrfRetidoPjCentavos = 0,
  }) {
    if (!_competenciaValida(competencia)) {
      throw ArgumentError.value(
        competencia,
        'competencia',
        'esperado formato "YYYY-MM"',
      );
    }
    if (receitaBrutaCentavos < 0 ||
        despesasDedutiveisCentavos < 0 ||
        inssPagoCentavos < 0 ||
        numeroDependentes < 0 ||
        irrfRetidoPjCentavos < 0) {
      throw ArgumentError('valores da apuração não podem ser negativos');
    }
  }

  /// Mês apurado, `'YYYY-MM'`.
  final String competencia;

  /// Σ lançamentos RENDIMENTO_TRIBUTAVEL_PF do mês (regime de caixa).
  /// É também o gatilho do redutor da Lei 15.270/2025.
  final int receitaBrutaCentavos;

  /// Σ livro-caixa dedutível do mês, com a trava de home office já aplicada
  /// por lançamento (ver [DespesaLivroCaixa.dedutivelCentavos]).
  final int despesasDedutiveisCentavos;

  /// INSS de contribuinte individual efetivamente pago no mês, por guia
  /// própria (GPS/DARF), regime de caixa. INSS descontado em folha CLT não
  /// entra — dedução em duplicidade.
  final int inssPagoCentavos;

  final int numeroDependentes;

  /// IRRF retido por PJ no mês. Registrado para o relatório anual;
  /// NUNCA compensa no cálculo mensal — universos separados até a DIRPF.
  final int irrfRetidoPjCentavos;
}

/// Resultado imutável da apuração de uma competência.
class ApuracaoMensal {
  const ApuracaoMensal({
    required this.competencia,
    required this.versaoTabelaId,
    required this.receitaBrutaCentavos,
    required this.baseCenarioACentavos,
    required this.impostoCenarioACentavos,
    required this.baseCenarioBCentavos,
    required this.impostoCenarioBCentavos,
    required this.cenarioVencedor,
    required this.reducaoRedutorCentavos,
    required this.impostoDevidoCentavos,
    required this.saldoNegativoAnteriorCentavos,
    required this.saldoNegativoNovoCentavos,
    required this.impostoAcumuladoAnteriorCentavos,
    required this.totalParaDarfCentavos,
    required this.statusDarf,
    required this.valorDarfCentavos,
    required this.impostoAcumuladoNovoCentavos,
    required this.irrfRetidoPjCentavos,
    required this.baseCalculoCentavos,
    required this.aliquotaPontosBase,
    required this.parcelaDeduzirCentavos,
    required this.impostoApuradoCentavos,
    required this.saldoNegativoUtilizadoCentavos,
  });

  final String competencia;

  /// [TabelaIrpf.id] usada — auditoria e histórico imutável mesmo após
  /// mudança de lei.
  final String versaoTabelaId;

  final int receitaBrutaCentavos;

  /// Cenário A (deduções reais) e B (desconto simplificado), ambos gravados.
  /// Os impostos exibidos aqui passam pelo mesmo ajuste final do devido;
  /// a comparação entre cenários é feita em micro-centavos exatos.
  final int baseCenarioACentavos;
  final int impostoCenarioACentavos;
  final int baseCenarioBCentavos;
  final int impostoCenarioBCentavos;
  final CenarioVencedor cenarioVencedor;

  /// Redução da Lei 15.270/2025 efetivamente abatida do imposto vencedor
  /// (já limitada ao imposto apurado — piso zero).
  final int reducaoRedutorCentavos;

  /// Imposto devido da competência, após redutor e ajuste final.
  final int impostoDevidoCentavos;

  /// Encadeamento anual do excesso de despesas do livro-caixa.
  final int saldoNegativoAnteriorCentavos;
  final int saldoNegativoNovoCentavos;

  /// Mecânica do DARF mínimo: imposto de competências anteriores retido por
  /// não atingir R$ 10,00 ([impostoAcumuladoAnteriorCentavos]), o total do
  /// mês ([totalParaDarfCentavos] = devido + acumulado) e o que segue retido
  /// ([impostoAcumuladoNovoCentavos]). Uma guia pode cobrir várias
  /// competências — a apuração não tem relação 1:1 com o DARF.
  final int impostoAcumuladoAnteriorCentavos;
  final int totalParaDarfCentavos;
  final StatusDarf statusDarf;

  /// Valor da guia quando [statusDarf] é `emitido`; zero nos demais casos.
  final int valorDarfCentavos;
  final int impostoAcumuladoNovoCentavos;

  /// Informativo para o relatório anual — não participa do cálculo.
  final int irrfRetidoPjCentavos;

  // --- Linha de apuração do cenário vencedor ---
  // Derivados que a apuração gravada e a memória de cálculo mostram. Saem
  // daqui, e não da camada que persiste ou apresenta, para que a tela e o
  // banco nunca recalculem regra fiscal por conta própria.

  /// Base de cálculo do cenário vencedor (A ou B).
  final int baseCalculoCentavos;

  /// Alíquota da faixa em que [baseCalculoCentavos] cai (27,5% = 2750).
  final int aliquotaPontosBase;

  /// Parcela a deduzir da mesma faixa.
  final int parcelaDeduzirCentavos;

  /// Imposto do cenário vencedor ANTES do redutor da Lei 15.270/2025, com o
  /// mesmo ajuste final do devido.
  final int impostoApuradoCentavos;

  /// Quanto do [saldoNegativoAnteriorCentavos] foi consumido neste mês. Só
  /// as deduções reais consomem saldo: no desconto simplificado é zero, e o
  /// saldo anterior segue inteiro para os meses seguintes.
  final int saldoNegativoUtilizadoCentavos;
}

/// Apura uma competência isolada.
///
/// [saldoNegativoAnteriorCentavos] e [impostoAcumuladoAnteriorCentavos] são
/// o estado herdado do mês anterior DO MESMO ANO — na virada do ano os dois
/// zeram, por regras distintas (spec, seções 3 e 5); use [apurarSequencia]
/// para o encadeamento correto.
ApuracaoMensal apurarMes({
  required EntradaApuracao entrada,
  required TabelaIrpf tabela,
  int saldoNegativoAnteriorCentavos = 0,
  int impostoAcumuladoAnteriorCentavos = 0,
  ModoAjusteFinal modoAjuste = ModoAjusteFinal.truncar,
}) {
  if (!tabela.vigePara(entrada.competencia)) {
    throw ArgumentError(
      'tabela ${tabela.id} não vige para ${entrada.competencia}',
    );
  }
  if (saldoNegativoAnteriorCentavos < 0 ||
      impostoAcumuladoAnteriorCentavos < 0) {
    throw ArgumentError('estado herdado não pode ser negativo');
  }

  final receita = entrada.receitaBrutaCentavos;

  // --- Cenário A: deduções reais ---
  // subtotal = receita − despesas − saldo negativo anterior. Se ficar
  // negativo, vira o novo saldo e a base é zero. Só o excesso de despesas
  // do livro-caixa transporta: INSS e dependentes que sobrarem no mês se
  // perdem — não geram crédito.
  final subtotal = receita -
      entrada.despesasDedutiveisCentavos -
      saldoNegativoAnteriorCentavos;
  final int baseA;
  final int saldoNegativoSeAVencer;
  if (subtotal < 0) {
    baseA = 0;
    saldoNegativoSeAVencer = -subtotal;
  } else {
    saldoNegativoSeAVencer = 0;
    final deducoes = entrada.inssPagoCentavos +
        entrada.numeroDependentes * tabela.valorDependenteCentavos;
    final aposDeducoes = subtotal - deducoes;
    baseA = aposDeducoes < 0 ? 0 : aposDeducoes;
  }
  final impostoAMicro = tabela.impostoProgressivoMicroCentavos(baseA);

  // --- Cenário B: desconto simplificado ---
  // O saldo do livro-caixa não é consumido aqui: o anterior sobrevive e o
  // excesso de despesas do próprio mês continua correndo (nunca foi
  // deduzido em lugar nenhum).
  //
  // Transporta APENAS o excesso sobre a receita, e não as despesas do mês
  // inteiro (confirmado com o contador em ago/2026). Ter escolhido o
  // desconto simplificado para apurar a base não desvincula a despesa da
  // receita que já a absorveu; estocar despesa coberta pela receita do mês
  // seria dedução dupla — simplificado agora, despesa real depois.
  final aposSimplificado = receita - tabela.descontoSimplificadoCentavos;
  final baseB = aposSimplificado < 0 ? 0 : aposSimplificado;
  final impostoBMicro = tabela.impostoProgressivoMicroCentavos(baseB);
  final excessoDespesasMes = entrada.despesasDedutiveisCentavos - receita;
  final saldoNegativoSeBVencer = saldoNegativoAnteriorCentavos +
      (excessoDespesasMes > 0 ? excessoDespesasMes : 0);

  // --- Vencedor e redutor ---
  // Menor imposto vence; empate exato vai para o simplificado, que preserva
  // o saldo do livro-caixa (mais vantajoso adiante). O redutor da Lei
  // 15.270/2025 é abatido do imposto vencedor, com piso zero.
  final vencedorEhB = impostoBMicro <= impostoAMicro;
  final impostoVencedorMicro = vencedorEhB ? impostoBMicro : impostoAMicro;
  final reducaoMicro = tabela.redutor?.reducaoMicroCentavos(receita) ?? 0;
  final reducaoAplicadaMicro =
      reducaoMicro > impostoVencedorMicro ? impostoVencedorMicro : reducaoMicro;
  final devidoMicro = impostoVencedorMicro - reducaoAplicadaMicro;
  final impostoDevido = _ajustarParaCentavos(devidoMicro, modoAjuste);

  // --- Linha de apuração do vencedor ---
  final baseVencedora = vencedorEhB ? baseB : baseA;
  final faixaVencedora = tabela.faixaPara(baseVencedora);
  // Deduções reais consomem o saldo anterior até o que a receita líquida
  // de despesas do mês comporta; o resto dele segue como saldo novo.
  final receitaLiquidaDespesas = receita - entrada.despesasDedutiveisCentavos;
  final int saldoUtilizado;
  if (vencedorEhB || receitaLiquidaDespesas <= 0) {
    saldoUtilizado = 0;
  } else {
    saldoUtilizado = receitaLiquidaDespesas < saldoNegativoAnteriorCentavos
        ? receitaLiquidaDespesas
        : saldoNegativoAnteriorCentavos;
  }

  // --- DARF mínimo (Lei 9.430/1996, art. 68) ---
  final totalParaDarf = impostoDevido + impostoAcumuladoAnteriorCentavos;
  final ehDezembro = entrada.competencia.endsWith('-12');
  final StatusDarf statusDarf;
  final int valorDarf;
  final int acumuladoNovo;
  if (totalParaDarf == 0) {
    statusDarf = StatusDarf.semImposto;
    valorDarf = 0;
    acumuladoNovo = 0;
  } else if (totalParaDarf >= darfMinimoCentavos) {
    statusDarf = StatusDarf.emitido;
    valorDarf = totalParaDarf;
    acumuladoNovo = 0;
  } else if (ehDezembro) {
    statusDarf = StatusDarf.residuoParaDirpf;
    valorDarf = 0;
    acumuladoNovo = 0;
  } else {
    statusDarf = StatusDarf.acumulaParaProximoMes;
    valorDarf = 0;
    acumuladoNovo = totalParaDarf;
  }

  return ApuracaoMensal(
    competencia: entrada.competencia,
    versaoTabelaId: tabela.id,
    receitaBrutaCentavos: receita,
    baseCenarioACentavos: baseA,
    impostoCenarioACentavos: _ajustarParaCentavos(impostoAMicro, modoAjuste),
    baseCenarioBCentavos: baseB,
    impostoCenarioBCentavos: _ajustarParaCentavos(impostoBMicro, modoAjuste),
    cenarioVencedor: vencedorEhB
        ? CenarioVencedor.descontoSimplificado
        : CenarioVencedor.deducoesReais,
    reducaoRedutorCentavos:
        _ajustarParaCentavos(reducaoAplicadaMicro, modoAjuste),
    impostoDevidoCentavos: impostoDevido,
    saldoNegativoAnteriorCentavos: saldoNegativoAnteriorCentavos,
    saldoNegativoNovoCentavos:
        vencedorEhB ? saldoNegativoSeBVencer : saldoNegativoSeAVencer,
    impostoAcumuladoAnteriorCentavos: impostoAcumuladoAnteriorCentavos,
    totalParaDarfCentavos: totalParaDarf,
    statusDarf: statusDarf,
    valorDarfCentavos: valorDarf,
    impostoAcumuladoNovoCentavos: acumuladoNovo,
    irrfRetidoPjCentavos: entrada.irrfRetidoPjCentavos,
    baseCalculoCentavos: baseVencedora,
    aliquotaPontosBase: faixaVencedora.aliquotaPontosBase,
    parcelaDeduzirCentavos: faixaVencedora.parcelaDeduzirCentavos,
    impostoApuradoCentavos:
        _ajustarParaCentavos(impostoVencedorMicro, modoAjuste),
    saldoNegativoUtilizadoCentavos: saldoUtilizado,
  );
}

/// Apura uma sequência de competências em ordem cronológica, encadeando o
/// saldo negativo do livro-caixa e o imposto acumulado do DARF mínimo.
///
/// Na virada do ano-calendário os dois estados zeram, por regras distintas:
/// o saldo do livro-caixa tem escopo ano-calendário (zera em 31/12) e o
/// resíduo de DARF abaixo de R$ 10,00 não transporta para janeiro — é
/// absorvido na DIRPF.
///
/// [tabelaPara] resolve a versão da tabela vigente em cada competência
/// (ver [tabelaVigente]).
List<ApuracaoMensal> apurarSequencia({
  required List<EntradaApuracao> entradas,
  required TabelaIrpf Function(String competencia) tabelaPara,
  ModoAjusteFinal modoAjuste = ModoAjusteFinal.truncar,
}) {
  final resultados = <ApuracaoMensal>[];
  var saldoNegativo = 0;
  var impostoAcumulado = 0;
  String? competenciaAnterior;

  for (final entrada in entradas) {
    if (competenciaAnterior != null &&
        entrada.competencia.compareTo(competenciaAnterior) <= 0) {
      throw ArgumentError(
        'competências fora de ordem: ${entrada.competencia} após '
        '$competenciaAnterior',
      );
    }
    if (competenciaAnterior != null &&
        _ano(entrada.competencia) != _ano(competenciaAnterior)) {
      saldoNegativo = 0;
      impostoAcumulado = 0;
    }

    final apuracao = apurarMes(
      entrada: entrada,
      tabela: tabelaPara(entrada.competencia),
      saldoNegativoAnteriorCentavos: saldoNegativo,
      impostoAcumuladoAnteriorCentavos: impostoAcumulado,
      modoAjuste: modoAjuste,
    );
    resultados.add(apuracao);
    saldoNegativo = apuracao.saldoNegativoNovoCentavos;
    impostoAcumulado = apuracao.impostoAcumuladoNovoCentavos;
    competenciaAnterior = entrada.competencia;
  }
  return resultados;
}

int _ajustarParaCentavos(int microCentavos, ModoAjusteFinal modo) =>
    switch (modo) {
      ModoAjusteFinal.truncar => microCentavos ~/ microCentavosPorCentavo,
      ModoAjusteFinal.arredondarHalfUp =>
        (microCentavos + microCentavosPorCentavo ~/ 2) ~/
            microCentavosPorCentavo,
    };

String _ano(String competencia) => competencia.substring(0, 4);

bool _competenciaValida(String competencia) {
  if (competencia.length != 7 || competencia[4] != '-') return false;
  final ano = int.tryParse(competencia.substring(0, 4));
  final mes = int.tryParse(competencia.substring(5, 7));
  return ano != null && mes != null && mes >= 1 && mes <= 12;
}
