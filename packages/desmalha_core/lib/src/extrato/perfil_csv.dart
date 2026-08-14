/// Perfil de importação CSV por banco.
///
/// As particularidades de cada banco (delimitador, formato de data, encoding,
/// mapeamento de colunas) NÃO são compiladas no app: vivem em perfis
/// versionados servidos pelo endpoint de conteúdo (ADR local-first), com
/// cache local. Corrigir o parser de um banco é publicar um perfil novo,
/// sem release nem review de loja. Esta classe é o schema desses perfis.
library;

import 'valor_monetario.dart';

/// Descreve como ler o CSV de um banco específico.
class PerfilCsv {
  const PerfilCsv({
    required this.id,
    required this.banco,
    required this.delimitador,
    required this.formatoData,
    required this.formatoValor,
    required this.colunaData,
    required this.colunaValor,
    required this.colunaDescricao,
    this.encoding,
    this.linhasCabecalho = 1,
    this.colunaIdExterno,
    this.colunaTipo,
    this.marcadorDebito,
    this.descricoesIgnoradas = const [],
  });

  /// Identificador estável do perfil no catálogo versionado,
  /// ex.: `nubank-conta-csv-v1`.
  final String id;

  /// Nome do banco para exibição, ex.: `Nubank`.
  final String banco;

  /// Separador de campos — exatamente um caractere (`,` ou `;`).
  final String delimitador;

  /// Charset do arquivo (`utf-8`, `latin-1`, `cp1252`); `null` autodetecta.
  final String? encoding;

  /// Quantidade de linhas iniciais a descartar (cabeçalhos e preâmbulos).
  final int linhasCabecalho;

  /// Formato da coluna de data, com os tokens de `parseDataCivil`
  /// (ex.: `dd/MM/yyyy`).
  final String formatoData;

  /// Convenção de separadores da coluna de valor.
  final FormatoValor formatoValor;

  /// Índices (0-based) das colunas no arquivo.
  final int colunaData;
  final int colunaValor;
  final int colunaDescricao;

  /// Coluna com identificador único do lançamento, quando o banco fornece.
  final int? colunaIdExterno;

  /// Coluna que indica débito/crédito quando o valor vem sem sinal.
  final int? colunaTipo;

  /// Conteúdo de [colunaTipo] que marca débito (comparação sem
  /// caixa/espaços), ex.: `D`. Presença exigida quando [colunaTipo] existe.
  final String? marcadorDebito;

  /// Descrições que identificam linhas informativas a descartar em silêncio
  /// (ex.: `Saldo Anterior`, `S A L D O` nos CSVs do Banco do Brasil).
  /// Comparação sem caixa e sem espaços nas pontas.
  final List<String> descricoesIgnoradas;

  /// Constrói um perfil a partir do JSON do catálogo versionado.
  ///
  /// Lança [FormatException] descrevendo o campo problemático — um perfil
  /// malformado no catálogo precisa falhar alto, nunca importar errado.
  factory PerfilCsv.fromJson(Map<String, Object?> json) {
    String texto(String campo) {
      final valor = json[campo];
      if (valor is! String || valor.isEmpty) {
        throw FormatException('perfil CSV: campo "$campo" ausente ou vazio');
      }
      return valor;
    }

    int inteiro(String campo) {
      final valor = json[campo];
      if (valor is! int || valor < 0) {
        throw FormatException(
          'perfil CSV: campo "$campo" precisa ser inteiro não negativo',
        );
      }
      return valor;
    }

    int? inteiroOpcional(String campo) {
      final valor = json[campo];
      if (valor == null) return null;
      if (valor is! int || valor < 0) {
        throw FormatException(
          'perfil CSV: campo "$campo" precisa ser inteiro não negativo',
        );
      }
      return valor;
    }

    final delimitador = texto('delimitador');
    if (delimitador.length != 1) {
      throw const FormatException(
        'perfil CSV: "delimitador" precisa ter exatamente um caractere',
      );
    }

    final formatoValorNome = texto('formatoValor');
    final formatoValor = FormatoValor.values
        .where((f) => f.name == formatoValorNome)
        .firstOrNull;
    if (formatoValor == null) {
      throw FormatException(
        'perfil CSV: "formatoValor" desconhecido: "$formatoValorNome" '
        '(aceitos: ${FormatoValor.values.map((f) => f.name).join(', ')})',
      );
    }

    final colunaTipo = inteiroOpcional('colunaTipo');
    final marcadorDebito = json['marcadorDebito'];
    if (colunaTipo != null && marcadorDebito is! String) {
      throw const FormatException(
        'perfil CSV: "colunaTipo" exige "marcadorDebito"',
      );
    }

    final ignoradasBruto = json['descricoesIgnoradas'];
    final descricoesIgnoradas = switch (ignoradasBruto) {
      null => const <String>[],
      List<Object?> lista => [
          for (final item in lista)
            if (item is String)
              item
            else
              throw const FormatException(
                'perfil CSV: "descricoesIgnoradas" só aceita strings',
              ),
        ],
      _ => throw const FormatException(
          'perfil CSV: "descricoesIgnoradas" precisa ser lista',
        ),
    };

    final encoding = json['encoding'];
    if (encoding != null && encoding is! String) {
      throw const FormatException(
        'perfil CSV: "encoding" precisa ser string',
      );
    }

    final linhasCabecalho = json['linhasCabecalho'];

    return PerfilCsv(
      id: texto('id'),
      banco: texto('banco'),
      delimitador: delimitador,
      encoding: encoding as String?,
      linhasCabecalho: linhasCabecalho == null ? 1 : inteiro('linhasCabecalho'),
      formatoData: texto('formatoData'),
      formatoValor: formatoValor,
      colunaData: inteiro('colunaData'),
      colunaValor: inteiro('colunaValor'),
      colunaDescricao: inteiro('colunaDescricao'),
      colunaIdExterno: inteiroOpcional('colunaIdExterno'),
      colunaTipo: colunaTipo,
      marcadorDebito: marcadorDebito as String?,
      descricoesIgnoradas: descricoesIgnoradas,
    );
  }

  /// Serializa o perfil de volta ao JSON do catálogo (campos `null` omitidos).
  Map<String, Object?> toJson() => {
        'id': id,
        'banco': banco,
        'delimitador': delimitador,
        if (encoding != null) 'encoding': encoding,
        'linhasCabecalho': linhasCabecalho,
        'formatoData': formatoData,
        'formatoValor': formatoValor.name,
        'colunaData': colunaData,
        'colunaValor': colunaValor,
        'colunaDescricao': colunaDescricao,
        if (colunaIdExterno != null) 'colunaIdExterno': colunaIdExterno,
        if (colunaTipo != null) 'colunaTipo': colunaTipo,
        if (marcadorDebito != null) 'marcadorDebito': marcadorDebito,
        if (descricoesIgnoradas.isNotEmpty)
          'descricoesIgnoradas': descricoesIgnoradas,
      };
}
