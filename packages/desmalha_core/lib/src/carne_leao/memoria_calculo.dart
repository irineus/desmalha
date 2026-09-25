/// Memória de cálculo do mês (wireframe M10): a linha de apuração na ordem
/// exata do cálculo, com os MESMOS valores que o motor devolveu para a aba
/// Mês (decisão 8 do owner, 25/09/2026). Nenhum valor aqui é recalculado
/// por outra via — os termos saem de [ApuracaoMensal] e da entrada que a
/// produziu.
///
/// A conta tem de fechar "com o dedo": cada subtotal é a soma das linhas
/// acima dele. Por isso o redutor exibido é o apurado menos o devido — o
/// motor ajusta à segunda casa uma única vez, no imposto final (spec,
/// seção 7), e o redutor isolado, ajustado à parte, poderia diferir de um
/// centavo da diferença que a pessoa vê. O imposto devido é sempre o do
/// motor.
library;

import 'apuracao.dart';
import 'tabela_irpf.dart';

/// O que cada linha da memória representa, na ordem do cálculo.
enum TermoDaMemoria {
  /// Receita tributável do mês (recebido de PF).
  receita,

  /// − livro-caixa do mês (dedutível, com trava de 20% e vedações).
  livroCaixa,

  /// − saldo negativo de meses anteriores consumido neste mês.
  saldoNegativoAnterior,

  /// − INSS pago no mês (só o principal).
  inss,

  /// − dedução por dependentes (quantidade × valor da tabela).
  dependentes,

  /// − desconto simplificado (quando ele venceu).
  descontoSimplificado,

  /// = base de cálculo (nunca negativa).
  base,

  /// base × alíquota da faixa.
  impostoPelaAliquota,

  /// − parcela a deduzir da faixa.
  parcelaDeduzir,

  /// = imposto apurado.
  impostoApurado,

  /// − redução da Lei 15.270/2025.
  redutor,

  /// = imposto do mês.
  impostoDevido,

  /// + imposto de meses anteriores abaixo do DARF mínimo.
  acumuladoAnterior,

  /// = total a recolher no mês.
  totalParaDarf,
}

class LinhaDaMemoria {
  const LinhaDaMemoria(this.termo, this.valorCentavos, {this.quantidade});

  final TermoDaMemoria termo;

  /// Sempre positivo; o sinal é do termo (dedução subtrai).
  final int valorCentavos;

  /// Dependentes: quantos contaram no mês.
  final int? quantidade;
}

class MemoriaDeCalculo {
  const MemoriaDeCalculo({
    required this.competencia,
    required this.cenario,
    required this.linhas,
    required this.aliquotaPontosBase,
    required this.impostoDeducoesReaisCentavos,
    required this.impostoSimplificadoCentavos,
    required this.baseLimitadaAZero,
  });

  final String competencia;

  /// O cenário que venceu — as linhas são as dele.
  final CenarioVencedor cenario;
  final List<LinhaDaMemoria> linhas;
  final int aliquotaPontosBase;

  /// Comparativo: o imposto de cada cenário antes do redutor, como o motor
  /// os apurou (ambos ficam gravados na apuração).
  final int impostoDeducoesReaisCentavos;
  final int impostoSimplificadoCentavos;

  /// As deduções passaram da receita: a base parou em zero e o excedente
  /// de INSS e dependentes não transporta (só o livro-caixa transporta).
  final bool baseLimitadaAZero;

  int valorDe(TermoDaMemoria termo) =>
      linhas.firstWhere((l) => l.termo == termo).valorCentavos;

  /// O redutor exibido — o mesmo que a aba Mês mostra.
  int get redutorCentavos {
    for (final l in linhas) {
      if (l.termo == TermoDaMemoria.redutor) return l.valorCentavos;
    }
    return 0;
  }
}

/// O redutor que a pessoa vê: apurado − devido (ver o cabeçalho). Único
/// ponto de verdade para a aba Mês e para o M10.
int redutorExibidoCentavos(ApuracaoMensal a) =>
    a.impostoApuradoCentavos - a.impostoDevidoCentavos;

/// Monta a memória de cálculo de [apuracao], apurada a partir de
/// [entrada] com a [tabela] vigente.
MemoriaDeCalculo memoriaDeCalculo({
  required ApuracaoMensal apuracao,
  required EntradaApuracao entrada,
  required TabelaIrpf tabela,
}) {
  final a = apuracao;
  if (a.competencia != entrada.competencia) {
    throw ArgumentError(
      'apuração de ${a.competencia} com entrada de ${entrada.competencia}',
    );
  }
  final simplificado = a.cenarioVencedor == CenarioVencedor.descontoSimplificado;
  final deducoes = <LinhaDaMemoria>[
    if (simplificado)
      LinhaDaMemoria(
        TermoDaMemoria.descontoSimplificado,
        tabela.descontoSimplificadoCentavos,
      )
    else ...[
      if (entrada.despesasDedutiveisCentavos > 0)
        LinhaDaMemoria(
          TermoDaMemoria.livroCaixa,
          entrada.despesasDedutiveisCentavos,
        ),
      if (a.saldoNegativoUtilizadoCentavos > 0)
        LinhaDaMemoria(
          TermoDaMemoria.saldoNegativoAnterior,
          a.saldoNegativoUtilizadoCentavos,
        ),
      if (entrada.inssPagoCentavos > 0)
        LinhaDaMemoria(TermoDaMemoria.inss, entrada.inssPagoCentavos),
      if (entrada.numeroDependentes > 0)
        LinhaDaMemoria(
          TermoDaMemoria.dependentes,
          entrada.numeroDependentes * tabela.valorDependenteCentavos,
          quantidade: entrada.numeroDependentes,
        ),
    ],
  ];
  var liquido = a.receitaBrutaCentavos;
  for (final d in deducoes) {
    liquido -= d.valorCentavos;
  }

  return MemoriaDeCalculo(
    competencia: a.competencia,
    cenario: a.cenarioVencedor,
    aliquotaPontosBase: a.aliquotaPontosBase,
    impostoDeducoesReaisCentavos: a.impostoCenarioACentavos,
    impostoSimplificadoCentavos: a.impostoCenarioBCentavos,
    baseLimitadaAZero: liquido < 0,
    linhas: [
      LinhaDaMemoria(TermoDaMemoria.receita, a.receitaBrutaCentavos),
      ...deducoes,
      LinhaDaMemoria(TermoDaMemoria.base, a.baseCalculoCentavos),
      if (a.aliquotaPontosBase > 0) ...[
        LinhaDaMemoria(
          TermoDaMemoria.impostoPelaAliquota,
          a.baseCalculoCentavos * a.aliquotaPontosBase ~/ 10000,
        ),
        LinhaDaMemoria(
          TermoDaMemoria.parcelaDeduzir,
          a.parcelaDeduzirCentavos,
        ),
      ],
      LinhaDaMemoria(TermoDaMemoria.impostoApurado, a.impostoApuradoCentavos),
      if (redutorExibidoCentavos(a) > 0)
        LinhaDaMemoria(TermoDaMemoria.redutor, redutorExibidoCentavos(a)),
      LinhaDaMemoria(TermoDaMemoria.impostoDevido, a.impostoDevidoCentavos),
      if (a.impostoAcumuladoAnteriorCentavos > 0) ...[
        LinhaDaMemoria(
          TermoDaMemoria.acumuladoAnterior,
          a.impostoAcumuladoAnteriorCentavos,
        ),
        LinhaDaMemoria(
          TermoDaMemoria.totalParaDarf,
          a.totalParaDarfCentavos,
        ),
      ],
    ],
  );
}
