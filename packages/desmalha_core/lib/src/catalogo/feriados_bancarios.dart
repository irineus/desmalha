/// Feriados bancários nacionais — conteúdo versionado, nunca hardcoded.
///
/// A lista serve ao cálculo do vencimento do DARF (`vencimentoDarf`): o
/// último dia útil do mês seguinte à competência, ANTECIPANDO em dia sem
/// expediente bancário. O que conta como "sem expediente" vem da FEBRABAN,
/// não de feriado civil: 15/11 num domingo continua na lista (inofensivo), e
/// 31/12 entra MESMO SEM SER FERIADO — a FEBRABAN não abre as agências no
/// último dia do ano e orienta expressamente que tributos com vencimento
/// nessa data sejam antecipados.
///
/// Cada registro cobre UM ano-calendário, e a cobertura é explícita de
/// propósito: pedir feriados de um ano que o catálogo não cobre é erro
/// ruidoso (`StateError` em `Catalogo.feriadosDoAno`), nunca um conjunto
/// vazio que deixaria `vencimentoDarf` calcular 31/12 como dia útil em
/// silêncio. Mesma postura da guia sem código de barras.
library;

/// Uma versão anual da tabela de feriados bancários do catálogo.
class FeriadosBancarios {
  FeriadosBancarios({
    required this.id,
    required this.ano,
    required this.datas,
    required this.fonte,
  }) {
    if (datas.isEmpty) {
      throw const FormatException(
        'feriados bancários: "datas" não pode ser vazia — ano sem feriado '
        'bancário não existe no Brasil',
      );
    }
    final prefixo = '$ano-';
    String? anterior;
    for (final data in datas) {
      if (!_ehDataCivilValida(data)) {
        throw FormatException(
          'feriados bancários: data "$data" não é uma data civil '
          "'YYYY-MM-DD' válida",
        );
      }
      if (!data.startsWith(prefixo)) {
        throw FormatException(
          'feriados bancários: data "$data" está fora do ano $ano declarado',
        );
      }
      if (anterior != null && data.compareTo(anterior) <= 0) {
        throw FormatException(
          'feriados bancários: datas precisam ser estritamente crescentes — '
          '"$data" vem depois de "$anterior"',
        );
      }
      anterior = data;
    }
  }

  /// Identificador estável no catálogo, ex.: `feriados-bancarios-2026`.
  final String id;

  /// Ano-calendário coberto por este registro.
  final int ano;

  /// Datas civis `'YYYY-MM-DD'` sem expediente bancário, em ordem
  /// estritamente crescente, todas dentro de [ano].
  final List<String> datas;

  /// Origem rastreável da lista (ex.: comunicado da FEBRABAN). Registro sem
  /// origem é inútil três meses depois — mesma regra das Decisões vigentes.
  final String fonte;

  factory FeriadosBancarios.fromJson(Map<String, Object?> json) {
    String texto(String campo) {
      final valor = json[campo];
      if (valor is! String || valor.isEmpty) {
        throw FormatException(
          'feriados bancários: campo "$campo" ausente ou vazio',
        );
      }
      return valor;
    }

    final ano = json['ano'];
    if (ano is! int || ano < 2026 || ano > 2100) {
      throw const FormatException(
        'feriados bancários: "ano" precisa ser inteiro entre 2026 e 2100',
      );
    }

    final datasBruto = json['datas'];
    if (datasBruto is! List<Object?>) {
      throw const FormatException(
        'feriados bancários: "datas" precisa ser lista de strings',
      );
    }
    final datas = [
      for (final item in datasBruto)
        if (item is String)
          item
        else
          throw const FormatException(
            'feriados bancários: cada data precisa ser string',
          ),
    ];

    return FeriadosBancarios(
      id: texto('id'),
      ano: ano,
      datas: datas,
      fonte: texto('fonte'),
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'ano': ano,
        'fonte': fonte,
        'datas': datas,
      };
}

/// `true` para `'YYYY-MM-DD'` que existe no calendário (rejeita 2026-02-30).
bool _ehDataCivilValida(String data) {
  final re = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
  final m = re.firstMatch(data);
  if (m == null) return false;
  final ano = int.parse(m.group(1)!);
  final mes = int.parse(m.group(2)!);
  final dia = int.parse(m.group(3)!);
  if (mes < 1 || mes > 12 || dia < 1) return false;
  final ultimoDia = DateTime.utc(ano, mes + 1, 0).day;
  return dia <= ultimoDia;
}
