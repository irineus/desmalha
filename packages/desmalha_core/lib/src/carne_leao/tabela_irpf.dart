/// Tabela progressiva do IRPF e parâmetros fiscais versionados.
///
/// A tabela NUNCA é hardcoded no app: vive no catálogo versionado servido
/// pela API (ADR local-first), com cache offline. Esta classe é o schema
/// desses registros. A seleção é sempre POR COMPETÊNCIA — a versão aplicada
/// é a vigente no mês apurado, nunca a vigente na data do cálculo — e o
/// `id` da versão é gravado em cada apuração, para auditoria.
///
/// Convenções invioláveis: dinheiro em `int` de centavos, alíquotas em
/// pontos-base (`int`), coeficiente do redutor em milionésimos (`int`).
/// Nenhum `double` em lugar nenhum.
library;

/// Uma faixa da tabela progressiva mensal.
class FaixaIrpf {
  const FaixaIrpf({
    required this.limiteSuperiorCentavos,
    required this.aliquotaPontosBase,
    required this.parcelaDeduzirCentavos,
  });

  /// Teto da faixa em centavos, inclusivo. `null` na última faixa (sem teto).
  final int? limiteSuperiorCentavos;

  /// Alíquota em pontos-base (27,5% = 2750).
  final int aliquotaPontosBase;

  /// Parcela a deduzir em centavos.
  final int parcelaDeduzirCentavos;

  factory FaixaIrpf.fromJson(Map<String, Object?> json) {
    final limite = json['limiteSuperiorCentavos'];
    if (limite != null && (limite is! int || limite <= 0)) {
      throw const FormatException(
        'faixa IRPF: "limiteSuperiorCentavos" precisa ser inteiro positivo '
        'ou null (última faixa)',
      );
    }
    final aliquota = json['aliquotaPontosBase'];
    if (aliquota is! int || aliquota < 0 || aliquota > 10000) {
      throw const FormatException(
        'faixa IRPF: "aliquotaPontosBase" precisa ser inteiro entre 0 e 10000',
      );
    }
    final parcela = json['parcelaDeduzirCentavos'];
    if (parcela is! int || parcela < 0) {
      throw const FormatException(
        'faixa IRPF: "parcelaDeduzirCentavos" precisa ser inteiro não negativo',
      );
    }
    return FaixaIrpf(
      limiteSuperiorCentavos: limite as int?,
      aliquotaPontosBase: aliquota,
      parcelaDeduzirCentavos: parcela,
    );
  }

  Map<String, Object?> toJson() => {
        'limiteSuperiorCentavos': limiteSuperiorCentavos,
        'aliquotaPontosBase': aliquotaPontosBase,
        'parcelaDeduzirCentavos': parcelaDeduzirCentavos,
      };
}

/// Parâmetros do redutor da Lei 15.270/2025, conforme a orientação oficial
/// da RFB de 11/12/2025.
///
/// O redutor incide sobre o IMPOSTO devido (nunca sobre a base) e o gatilho
/// é o rendimento bruto do mês, antes de qualquer dedução:
/// - até [limiteIsencaoCentavos]: redução de até [tetoCentavos], limitada ao
///   imposto apurado;
/// - até [limiteTransicaoCentavos]: redução parcial
///   `coefA − coefB × rendimento_bruto`;
/// - acima: sem redutor.
class RedutorLei15270 {
  const RedutorLei15270({
    required this.tetoCentavos,
    required this.limiteIsencaoCentavos,
    required this.limiteTransicaoCentavos,
    required this.coefACentavos,
    required this.coefBMilionesimos,
  });

  final int tetoCentavos;
  final int limiteIsencaoCentavos;
  final int limiteTransicaoCentavos;

  /// Termo fixo da fórmula de transição, em centavos (978,62 → 97862).
  final int coefACentavos;

  /// Coeficiente da fórmula de transição, em milionésimos
  /// (0,133145 → 133145). Multiplicado por centavos produz
  /// micro-centavos exatos — aritmética inteira do início ao fim.
  final int coefBMilionesimos;

  /// Redução em MICRO-centavos (1 centavo = 1.000.000 micro-centavos) para
  /// o [rendimentoBrutoCentavos] do mês, ainda sem o teto do imposto
  /// apurado (o piso zero do imposto é aplicado pelo motor).
  int reducaoMicroCentavos(int rendimentoBrutoCentavos) {
    if (rendimentoBrutoCentavos <= limiteIsencaoCentavos) {
      return tetoCentavos * _microPorCentavo;
    }
    if (rendimentoBrutoCentavos <= limiteTransicaoCentavos) {
      final bruto = coefACentavos * _microPorCentavo -
          coefBMilionesimos * rendimentoBrutoCentavos;
      return bruto < 0 ? 0 : bruto;
    }
    return 0;
  }

  factory RedutorLei15270.fromJson(Map<String, Object?> json) {
    int inteiro(String campo) {
      final valor = json[campo];
      if (valor is! int || valor < 0) {
        throw FormatException(
          'redutor: campo "$campo" precisa ser inteiro não negativo',
        );
      }
      return valor;
    }

    return RedutorLei15270(
      tetoCentavos: inteiro('tetoCentavos'),
      limiteIsencaoCentavos: inteiro('limiteIsencaoCentavos'),
      limiteTransicaoCentavos: inteiro('limiteTransicaoCentavos'),
      coefACentavos: inteiro('coefACentavos'),
      coefBMilionesimos: inteiro('coefBMilionesimos'),
    );
  }

  Map<String, Object?> toJson() => {
        'tetoCentavos': tetoCentavos,
        'limiteIsencaoCentavos': limiteIsencaoCentavos,
        'limiteTransicaoCentavos': limiteTransicaoCentavos,
        'coefACentavos': coefACentavos,
        'coefBMilionesimos': coefBMilionesimos,
      };
}

/// Uma versão da tabela do IRPF, com vigência por competência.
class TabelaIrpf {
  TabelaIrpf({
    required this.id,
    required this.vigenciaInicio,
    this.vigenciaFim,
    required this.valorDependenteCentavos,
    required this.descontoSimplificadoCentavos,
    required this.faixas,
    this.redutor,
  }) {
    if (faixas.isEmpty) {
      throw const FormatException('tabela IRPF: precisa de ao menos uma faixa');
    }
    if (faixas.last.limiteSuperiorCentavos != null) {
      throw const FormatException(
        'tabela IRPF: a última faixa precisa ter limite superior null',
      );
    }
    for (var i = 0; i < faixas.length - 1; i++) {
      final atual = faixas[i].limiteSuperiorCentavos;
      final proximo = faixas[i + 1].limiteSuperiorCentavos;
      if (atual == null || (proximo != null && proximo <= atual)) {
        throw const FormatException(
          'tabela IRPF: faixas precisam ter limites crescentes e só a '
          'última pode ser aberta',
        );
      }
    }
  }

  /// Identificador estável da versão no catálogo, ex.: `irpf-mensal-2026-01`.
  /// Gravado em cada apuração junto ao resultado.
  final String id;

  /// Primeira competência de vigência, `'YYYY-MM'` (inclusivo).
  final String vigenciaInicio;

  /// Última competência de vigência, `'YYYY-MM'` (inclusivo);
  /// `null` = vigente até segunda ordem.
  final String? vigenciaFim;

  /// Dedução mensal por dependente, em centavos.
  final int valorDependenteCentavos;

  /// Desconto simplificado mensal (cenário B), em centavos.
  final int descontoSimplificadoCentavos;

  /// Faixas em ordem crescente; a última é aberta (limite `null`).
  final List<FaixaIrpf> faixas;

  /// Redutor vigente, ou `null` quando não há redutor (competências
  /// anteriores à Lei 15.270/2025).
  final RedutorLei15270? redutor;

  /// `true` se esta versão vige na [competencia] (`'YYYY-MM'`).
  ///
  /// Comparação lexicográfica — o formato `'YYYY-MM'` ordena como data.
  bool vigePara(String competencia) =>
      vigenciaInicio.compareTo(competencia) <= 0 &&
      (vigenciaFim == null || competencia.compareTo(vigenciaFim!) <= 0);

  /// Faixa aplicável à [baseCentavos].
  FaixaIrpf faixaPara(int baseCentavos) => faixas.firstWhere(
        (f) =>
            f.limiteSuperiorCentavos == null ||
            baseCentavos <= f.limiteSuperiorCentavos!,
      );

  /// Imposto pela tabela progressiva em MICRO-centavos, com piso zero:
  /// `max(0, base × alíquota − parcela_a_deduzir)`.
  ///
  /// Micro-centavos preservam a exatidão exigida pela spec — nenhum valor
  /// intermediário é arredondado; o ajuste à segunda casa acontece uma única
  /// vez, no imposto final do mês.
  int impostoProgressivoMicroCentavos(int baseCentavos) {
    final faixa = faixaPara(baseCentavos);
    final bruto = baseCentavos * faixa.aliquotaPontosBase * 100 -
        faixa.parcelaDeduzirCentavos * _microPorCentavo;
    return bruto < 0 ? 0 : bruto;
  }

  /// Constrói uma versão a partir do JSON do catálogo versionado.
  ///
  /// Lança [FormatException] descrevendo o campo problemático — tabela
  /// malformada no catálogo precisa falhar alto, nunca calcular errado.
  factory TabelaIrpf.fromJson(Map<String, Object?> json) {
    String texto(String campo) {
      final valor = json[campo];
      if (valor is! String || valor.isEmpty) {
        throw FormatException('tabela IRPF: campo "$campo" ausente ou vazio');
      }
      return valor;
    }

    int inteiro(String campo) {
      final valor = json[campo];
      if (valor is! int || valor < 0) {
        throw FormatException(
          'tabela IRPF: campo "$campo" precisa ser inteiro não negativo',
        );
      }
      return valor;
    }

    final vigenciaFim = json['vigenciaFim'];
    if (vigenciaFim != null && vigenciaFim is! String) {
      throw const FormatException(
        'tabela IRPF: "vigenciaFim" precisa ser string "YYYY-MM" ou null',
      );
    }

    final faixasBruto = json['faixas'];
    if (faixasBruto is! List<Object?> || faixasBruto.isEmpty) {
      throw const FormatException(
        'tabela IRPF: "faixas" precisa ser lista não vazia',
      );
    }
    final faixas = [
      for (final item in faixasBruto)
        if (item is Map<String, Object?>)
          FaixaIrpf.fromJson(item)
        else
          throw const FormatException(
            'tabela IRPF: cada faixa precisa ser um objeto',
          ),
    ];

    final redutorBruto = json['redutor'];
    RedutorLei15270? redutor;
    if (redutorBruto != null) {
      if (redutorBruto is! Map<String, Object?>) {
        throw const FormatException(
          'tabela IRPF: "redutor" precisa ser objeto ou null',
        );
      }
      redutor = RedutorLei15270.fromJson(redutorBruto);
    }

    return TabelaIrpf(
      id: texto('id'),
      vigenciaInicio: texto('vigenciaInicio'),
      vigenciaFim: vigenciaFim as String?,
      valorDependenteCentavos: inteiro('valorDependenteCentavos'),
      descontoSimplificadoCentavos: inteiro('descontoSimplificadoCentavos'),
      faixas: faixas,
      redutor: redutor,
    );
  }

  /// Serializa de volta ao JSON do catálogo.
  Map<String, Object?> toJson() => {
        'id': id,
        'vigenciaInicio': vigenciaInicio,
        'vigenciaFim': vigenciaFim,
        'valorDependenteCentavos': valorDependenteCentavos,
        'descontoSimplificadoCentavos': descontoSimplificadoCentavos,
        'faixas': [for (final f in faixas) f.toJson()],
        if (redutor != null) 'redutor': redutor!.toJson(),
      };
}

/// Seleciona nas [versoes] a vigente para a [competencia] (`'YYYY-MM'`).
///
/// Lança [StateError] se nenhuma ou mais de uma versão vige no mês — o
/// catálogo garante exclusão de vigências no servidor, mas o motor não
/// pode calcular em cima de catálogo inconsistente.
TabelaIrpf tabelaVigente(Iterable<TabelaIrpf> versoes, String competencia) {
  final vigentes = versoes.where((v) => v.vigePara(competencia)).toList();
  if (vigentes.isEmpty) {
    throw StateError('nenhuma tabela IRPF vigente para $competencia');
  }
  if (vigentes.length > 1) {
    throw StateError(
      'mais de uma tabela IRPF vigente para $competencia: '
      '${vigentes.map((v) => v.id).join(', ')}',
    );
  }
  return vigentes.single;
}

/// 1 centavo = 1.000.000 micro-centavos — escala interna do motor para
/// manter exatos os produtos alíquota × base e coeficiente × rendimento.
const int microCentavosPorCentavo = 1000000;

const int _microPorCentavo = microCentavosPorCentavo;
