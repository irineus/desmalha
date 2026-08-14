/// Código de barras do padrão FEBRABAN de arrecadação (44 dígitos) e a
/// linha digitável correspondente (48 dígitos).
///
/// Este arquivo implementa APENAS o padrão FEBRABAN, que é público e fechado:
/// composição dos 44 dígitos, dígito verificador geral (módulo 10 ou 11
/// conforme o identificador de valor) e os quatro blocos da linha digitável,
/// cada um com seu DV de módulo 10.
///
/// O que NÃO está aqui, de propósito: como a Receita Federal preenche o campo
/// livre de 25 dígitos do DARF. Esse layout é da RFB, não da FEBRABAN, e não
/// pode ser adivinhado — ver [LayoutCodigoBarrasDarf] em `layout_darf.dart`,
/// que o trata como dado versionado servido pelo catálogo.
///
/// Dinheiro em `int` de centavos, sempre. O valor entra no código de barras
/// como 11 dígitos de centavos — nunca passa por `double`.
library;

/// Identificador de valor (posição 3 do código de barras).
///
/// Determina duas coisas ao mesmo tempo: se o campo de 11 dígitos carrega
/// valor efetivo em reais ou quantidade de moeda de referência, e qual módulo
/// calcula o dígito verificador geral.
enum IdentificadorValor {
  /// Valor efetivo em reais, DV geral por módulo 10.
  valorEfetivoModulo10('6'),

  /// Quantidade de moeda de referência, DV geral por módulo 10.
  valorReferenciaModulo10('7'),

  /// Valor efetivo em reais, DV geral por módulo 11.
  valorEfetivoModulo11('8'),

  /// Quantidade de moeda de referência, DV geral por módulo 11.
  valorReferenciaModulo11('9');

  const IdentificadorValor(this.digito);

  /// O dígito como aparece na posição 3 do código de barras.
  final String digito;

  /// `true` quando o DV geral é calculado por módulo 11.
  bool get usaModulo11 =>
      this == IdentificadorValor.valorEfetivoModulo11 ||
      this == IdentificadorValor.valorReferenciaModulo11;

  /// Resolve pelo dígito da posição 3; lança [FormatException] se inválido.
  static IdentificadorValor doDigito(String digito) {
    for (final valor in IdentificadorValor.values) {
      if (valor.digito == digito) return valor;
    }
    throw FormatException(
      'identificador de valor inválido: "$digito" (esperado 6, 7, 8 ou 9)',
    );
  }
}

/// Primeiro dígito do código de barras de arrecadação: identifica o produto.
const String _produtoArrecadacao = '8';

/// Maior valor representável nos 11 dígitos de centavos do código de barras.
const int valorMaximoCodigoBarrasCentavos = 99999999999;

/// Um código de barras de arrecadação já montado e validado.
///
/// Imutável: construir é validar. Se existe uma instância, os 44 dígitos são
/// numéricos, começam por `8` e o DV geral confere.
class CodigoBarrasArrecadacao {
  const CodigoBarrasArrecadacao._(this.digitos);

  /// Os 44 dígitos, sem separadores.
  final String digitos;

  /// Monta o código de barras a partir das partes.
  ///
  /// [segmento] é o dígito da posição 2 (1 a 9, ver tabela FEBRABAN);
  /// [identificacaoOrgao] tem exatamente 4 dígitos e [campoLivre]
  /// exatamente 25 — a composição do campo livre é responsabilidade de quem
  /// chama, porque depende do órgão arrecadador.
  ///
  /// O DV geral (posição 4) é calculado aqui e não é parâmetro: passá-lo de
  /// fora só criaria a chance de gravar um código inconsistente.
  factory CodigoBarrasArrecadacao.montar({
    required int segmento,
    required IdentificadorValor identificadorValor,
    required int valorCentavos,
    required String identificacaoOrgao,
    required String campoLivre,
  }) {
    if (segmento < 1 || segmento > 9) {
      throw ArgumentError.value(
        segmento,
        'segmento',
        'esperado 1 a 9 (tabela de segmentos FEBRABAN)',
      );
    }
    if (valorCentavos < 0) {
      throw ArgumentError.value(
        valorCentavos,
        'valorCentavos',
        'valor do código de barras não pode ser negativo',
      );
    }
    if (valorCentavos > valorMaximoCodigoBarrasCentavos) {
      throw ArgumentError.value(
        valorCentavos,
        'valorCentavos',
        'excede os 11 dígitos do campo de valor',
      );
    }
    _exigirDigitos(identificacaoOrgao, 4, 'identificacaoOrgao');
    _exigirDigitos(campoLivre, 25, 'campoLivre');

    final semDv = '$_produtoArrecadacao$segmento'
        '${identificadorValor.digito}'
        '${valorCentavos.toString().padLeft(11, '0')}'
        '$identificacaoOrgao$campoLivre';
    final dv = identificadorValor.usaModulo11
        ? dvModulo11Arrecadacao(semDv)
        : dvModulo10Arrecadacao(semDv);

    return CodigoBarrasArrecadacao._(
      '${semDv.substring(0, 3)}$dv${semDv.substring(3)}',
    );
  }

  /// Lê 44 dígitos já prontos, conferindo o DV geral.
  ///
  /// Lança [FormatException] se o comprimento, o produto ou o DV não baterem.
  /// É o caminho de leitura de um código gravado ou digitado — nunca confie
  /// num código de barras só porque tem 44 dígitos.
  factory CodigoBarrasArrecadacao.parse(String digitos) {
    final limpo = digitos.replaceAll(RegExp(r'[\s.-]'), '');
    if (limpo.length != 44 || !_soDigitos(limpo)) {
      throw FormatException(
        'código de barras de arrecadação: esperados 44 dígitos, '
        'recebidos ${limpo.length}',
      );
    }
    if (limpo[0] != _produtoArrecadacao) {
      throw FormatException(
        'código de barras de arrecadação deve começar por '
        '$_produtoArrecadacao, recebido "${limpo[0]}"',
      );
    }
    final identificador = IdentificadorValor.doDigito(limpo[2]);
    final semDv = '${limpo.substring(0, 3)}${limpo.substring(4)}';
    final esperado = identificador.usaModulo11
        ? dvModulo11Arrecadacao(semDv)
        : dvModulo10Arrecadacao(semDv);
    if (limpo[3] != esperado) {
      throw FormatException(
        'dígito verificador geral inválido: esperado $esperado, '
        'encontrado ${limpo[3]}',
      );
    }
    return CodigoBarrasArrecadacao._(limpo);
  }

  /// Segmento (posição 2).
  int get segmento => int.parse(digitos[1]);

  /// Identificador de valor (posição 3).
  IdentificadorValor get identificadorValor =>
      IdentificadorValor.doDigito(digitos[2]);

  /// Dígito verificador geral (posição 4).
  String get dvGeral => digitos[3];

  /// Valor em centavos (posições 5 a 15).
  int get valorCentavos => int.parse(digitos.substring(4, 15));

  /// Identificação da empresa/órgão no banco (posições 16 a 19).
  String get identificacaoOrgao => digitos.substring(15, 19);

  /// Campo livre do órgão arrecadador (posições 20 a 44).
  String get campoLivre => digitos.substring(19);

  /// Linha digitável: 48 dígitos, sem separadores.
  ///
  /// Os 44 dígitos são quebrados em quatro blocos de 11 e cada bloco recebe
  /// seu próprio DV de módulo 10 ao final — por isso 48 e não 44.
  String get linhaDigitavel {
    final buffer = StringBuffer();
    for (var i = 0; i < 4; i++) {
      final bloco = digitos.substring(i * 11, (i + 1) * 11);
      buffer
        ..write(bloco)
        ..write(dvModulo10Arrecadacao(bloco));
    }
    return buffer.toString();
  }

  /// Linha digitável agrupada para leitura humana, no padrão dos comprovantes:
  /// quatro campos de 12 dígitos separados por espaço, com um ponto após o
  /// 11º dígito de cada campo (`00000000000-0 ...`).
  String get linhaDigitavelFormatada {
    final crua = linhaDigitavel;
    final campos = <String>[];
    for (var i = 0; i < 4; i++) {
      final campo = crua.substring(i * 12, (i + 1) * 12);
      campos.add('${campo.substring(0, 11)}-${campo[11]}');
    }
    return campos.join(' ');
  }

  @override
  String toString() => digitos;

  @override
  bool operator ==(Object other) =>
      other is CodigoBarrasArrecadacao && other.digitos == digitos;

  @override
  int get hashCode => digitos.hashCode;
}

/// DV de módulo 10 do padrão de arrecadação.
///
/// Pesos 2 e 1 alternados da direita para a esquerda; produto maior que 9 tem
/// os algarismos somados (18 → 1+8); DV = 10 − (soma mod 10), com 10 → 0.
String dvModulo10Arrecadacao(String digitos) {
  _exigirSomenteDigitos(digitos, 'dvModulo10Arrecadacao');
  var soma = 0;
  var peso = 2;
  for (var i = digitos.length - 1; i >= 0; i--) {
    final produto = (digitos.codeUnitAt(i) - 0x30) * peso;
    soma += produto > 9 ? produto - 9 : produto;
    peso = peso == 2 ? 1 : 2;
  }
  final dv = (10 - soma % 10) % 10;
  return dv.toString();
}

/// DV de módulo 11 do padrão de arrecadação.
///
/// Pesos de 2 a 9 ciclando da direita para a esquerda; resto = soma mod 11;
/// DV = 11 − resto, com os dois casos de borda do padrão: resto 0 ou 1 → DV 0,
/// resto 10 → DV 1.
String dvModulo11Arrecadacao(String digitos) {
  _exigirSomenteDigitos(digitos, 'dvModulo11Arrecadacao');
  var soma = 0;
  var peso = 2;
  for (var i = digitos.length - 1; i >= 0; i--) {
    soma += (digitos.codeUnitAt(i) - 0x30) * peso;
    peso = peso == 9 ? 2 : peso + 1;
  }
  final resto = soma % 11;
  if (resto == 0 || resto == 1) return '0';
  if (resto == 10) return '1';
  return (11 - resto).toString();
}

void _exigirDigitos(String valor, int tamanho, String campo) {
  if (valor.length != tamanho || !_soDigitos(valor)) {
    throw ArgumentError.value(
      valor,
      campo,
      'esperados exatamente $tamanho dígitos numéricos',
    );
  }
}

void _exigirSomenteDigitos(String valor, String origem) {
  if (valor.isEmpty || !_soDigitos(valor)) {
    throw ArgumentError.value(valor, origem, 'esperados apenas dígitos');
  }
}

bool _soDigitos(String valor) {
  for (var i = 0; i < valor.length; i++) {
    final codigo = valor.codeUnitAt(i);
    if (codigo < 0x30 || codigo > 0x39) return false;
  }
  return true;
}
