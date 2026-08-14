/// Layout do código de barras do DARF — dado versionado, nunca hardcoded.
///
/// O padrão FEBRABAN (ver `codigo_barras_arrecadacao.dart`) define a moldura
/// dos 44 dígitos, mas deixa 25 deles como "campo livre de utilização da
/// empresa/órgão". Como a Receita Federal preenche esses 25 dígitos no DARF é
/// especificação DA RFB, e não é derivável do padrão.
///
/// Por isso este arquivo não contém nenhum layout concreto: contém o SCHEMA
/// de um layout, servido pelo catálogo versionado da API junto com a tabela do
/// IRPF, os feriados bancários e os perfis de parser. A regra é a mesma dos
/// perfis de banco — corrigir um layout é publicar conteúdo novo, sem release.
///
/// ⚠️ Decisão de projeto: enquanto o catálogo não servir um layout **conferido
/// contra um DARF real emitido pelo Sicalc/e-CAC**, o app emite o DARF SEM
/// código de barras, direcionando ao pagamento pelo e-CAC. Um código de barras
/// adivinhado é pior do que código de barras nenhum: ele é lido pelo banco e
/// paga a coisa errada, em silêncio. Mesmo raciocínio do `PRAGMA
/// cipher_version` — falhar visivelmente em vez de funcionar errado.
library;

import 'codigo_barras_arrecadacao.dart';

/// De onde sai o conteúdo de um trecho do campo livre.
enum FonteCampoLivre {
  /// Preenchido com [CampoLivreDarf.constante] (dígitos fixos do layout).
  constante,

  /// Código de receita do DARF, ex.: `0190`.
  codigoReceita,

  /// CPF do contribuinte, só dígitos.
  cpfContribuinte,

  /// Competência apurada como `AAAAMM`.
  competenciaAaaamm,

  /// Data de vencimento como `AAAAMMDD`.
  vencimentoAaaammdd,

  /// Número de referência do documento atribuído pelo emissor.
  numeroReferencia,

  /// Valor total da guia em centavos.
  valorCentavos;

  /// Nome estável usado no JSON do catálogo.
  String get chave => switch (this) {
        FonteCampoLivre.constante => 'constante',
        FonteCampoLivre.codigoReceita => 'codigo_receita',
        FonteCampoLivre.cpfContribuinte => 'cpf_contribuinte',
        FonteCampoLivre.competenciaAaaamm => 'competencia_aaaamm',
        FonteCampoLivre.vencimentoAaaammdd => 'vencimento_aaaammdd',
        FonteCampoLivre.numeroReferencia => 'numero_referencia',
        FonteCampoLivre.valorCentavos => 'valor_centavos',
      };

  /// Resolve pela chave do JSON; lança [FormatException] se desconhecida.
  static FonteCampoLivre daChave(String chave) {
    for (final fonte in FonteCampoLivre.values) {
      if (fonte.chave == chave) return fonte;
    }
    throw FormatException('layout de DARF: fonte desconhecida "$chave"');
  }
}

/// Um trecho do campo livre: de onde vem e quantos dígitos ocupa.
class CampoLivreDarf {
  const CampoLivreDarf({
    required this.fonte,
    required this.tamanho,
    this.constante,
  });

  final FonteCampoLivre fonte;

  /// Quantidade de dígitos que este trecho ocupa no campo livre.
  final int tamanho;

  /// Dígitos fixos, obrigatórios quando [fonte] é [FonteCampoLivre.constante].
  final String? constante;

  /// Lê um trecho do JSON do catálogo.
  factory CampoLivreDarf.fromJson(Map<String, Object?> json) {
    final fonte = FonteCampoLivre.daChave(json['fonte'] as String? ?? '');
    final tamanho = json['tamanho'];
    if (tamanho is! int || tamanho < 1 || tamanho > 25) {
      throw FormatException(
        'layout de DARF: "tamanho" deve ser inteiro de 1 a 25, '
        'recebido "$tamanho"',
      );
    }
    final constante = json['constante'] as String?;
    if (fonte == FonteCampoLivre.constante) {
      if (constante == null || constante.length != tamanho) {
        throw FormatException(
          'layout de DARF: trecho constante exige "constante" com '
          '$tamanho dígitos',
        );
      }
      if (!_soDigitos(constante)) {
        throw FormatException(
          'layout de DARF: "constante" deve conter apenas dígitos, '
          'recebido "$constante"',
        );
      }
    }
    return CampoLivreDarf(
      fonte: fonte,
      tamanho: tamanho,
      constante: constante,
    );
  }

  Map<String, Object?> toJson() => {
        'fonte': fonte.chave,
        'tamanho': tamanho,
        if (constante != null) 'constante': constante,
      };
}

/// Layout completo do código de barras do DARF, como vem do catálogo.
class LayoutCodigoBarrasDarf {
  LayoutCodigoBarrasDarf({
    required this.id,
    required this.segmento,
    required this.identificadorValor,
    required this.identificacaoOrgao,
    required this.campoLivre,
    required this.origem,
    required this.conferidoContraDocumentoReal,
  }) {
    final soma = campoLivre.fold<int>(0, (total, campo) => total + campo.tamanho);
    if (soma != 25) {
      throw ArgumentError.value(
        soma,
        'campoLivre',
        'os trechos devem somar exatamente 25 dígitos',
      );
    }
  }

  /// Identificador estável no catálogo, ex.: `darf-0190-v1`.
  final String id;

  /// Segmento FEBRABAN (posição 2 do código de barras).
  final int segmento;

  final IdentificadorValor identificadorValor;

  /// Identificação do órgão arrecadador no banco (4 dígitos).
  final String identificacaoOrgao;

  /// Composição dos 25 dígitos do campo livre, na ordem.
  final List<CampoLivreDarf> campoLivre;

  /// Documento oficial que fundamenta o layout — sem origem rastreável um
  /// layout não deve ser publicado no catálogo.
  final String origem;

  /// `true` somente depois de conferido dígito a dígito contra um DARF real
  /// emitido pelo Sicalc/e-CAC.
  ///
  /// [montarCodigoBarras] recusa layouts com `false`: é a trava que impede um
  /// layout provisório de virar guia de pagamento sem que alguém tenha
  /// olhado um documento verdadeiro.
  final bool conferidoContraDocumentoReal;

  factory LayoutCodigoBarrasDarf.fromJson(Map<String, Object?> json) {
    final trechos = json['campo_livre'];
    if (trechos is! List || trechos.isEmpty) {
      throw const FormatException(
        'layout de DARF: "campo_livre" ausente ou vazio',
      );
    }
    return LayoutCodigoBarrasDarf(
      id: _texto(json, 'id'),
      segmento: json['segmento'] as int? ??
          (throw const FormatException('layout de DARF: "segmento" ausente')),
      identificadorValor:
          IdentificadorValor.doDigito(_texto(json, 'identificador_valor')),
      identificacaoOrgao: _texto(json, 'identificacao_orgao'),
      campoLivre: [
        for (final trecho in trechos)
          CampoLivreDarf.fromJson(trecho as Map<String, Object?>),
      ],
      origem: _texto(json, 'origem'),
      conferidoContraDocumentoReal:
          json['conferido_contra_documento_real'] as bool? ?? false,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'segmento': segmento,
        'identificador_valor': identificadorValor.digito,
        'identificacao_orgao': identificacaoOrgao,
        'campo_livre': [for (final campo in campoLivre) campo.toJson()],
        'origem': origem,
        'conferido_contra_documento_real': conferidoContraDocumentoReal,
      };

  /// Monta o código de barras da guia segundo este layout.
  ///
  /// Lança [StateError] se o layout ainda não foi conferido contra um DARF
  /// real — quem chama deve tratar isso emitindo a guia sem código de barras,
  /// não capturando e seguindo em frente.
  CodigoBarrasArrecadacao montarCodigoBarras({
    required String codigoReceita,
    required String cpfContribuinte,
    required String competencia,
    required String dataVencimento,
    required int valorCentavos,
    String numeroReferencia = '',
  }) {
    if (!conferidoContraDocumentoReal) {
      throw StateError(
        'layout de DARF "$id" não foi conferido contra um documento real — '
        'emitir guia com código de barras não verificado paga a receita '
        'errada em silêncio. Emita o DARF sem código de barras.',
      );
    }

    final buffer = StringBuffer();
    for (final campo in campoLivre) {
      final bruto = switch (campo.fonte) {
        FonteCampoLivre.constante => campo.constante!,
        FonteCampoLivre.codigoReceita => codigoReceita,
        FonteCampoLivre.cpfContribuinte => _soNumeros(cpfContribuinte),
        FonteCampoLivre.competenciaAaaamm => competencia.replaceAll('-', ''),
        FonteCampoLivre.vencimentoAaaammdd =>
          dataVencimento.replaceAll('-', ''),
        FonteCampoLivre.numeroReferencia => _soNumeros(numeroReferencia),
        FonteCampoLivre.valorCentavos => valorCentavos.toString(),
      };
      buffer.write(_ajustar(bruto, campo));
    }

    return CodigoBarrasArrecadacao.montar(
      segmento: segmento,
      identificadorValor: identificadorValor,
      valorCentavos: valorCentavos,
      identificacaoOrgao: identificacaoOrgao,
      campoLivre: buffer.toString(),
    );
  }

  /// Encaixa [bruto] no tamanho do trecho: completa com zeros à esquerda e
  /// recusa o que não couber — truncar em silêncio produziria um CPF ou um
  /// valor mutilado dentro de uma guia de pagamento.
  static String _ajustar(String bruto, CampoLivreDarf campo) {
    if (bruto.length > campo.tamanho) {
      throw ArgumentError(
        'campo livre do DARF: "${campo.fonte.chave}" tem ${bruto.length} '
        'dígitos e não cabe em ${campo.tamanho}',
      );
    }
    return bruto.padLeft(campo.tamanho, '0');
  }
}

String _texto(Map<String, Object?> json, String campo) {
  final valor = json[campo];
  if (valor is! String || valor.isEmpty) {
    throw FormatException('layout de DARF: campo "$campo" ausente ou vazio');
  }
  return valor;
}

String _soNumeros(String valor) => valor.replaceAll(RegExp(r'\D'), '');

bool _soDigitos(String valor) {
  if (valor.isEmpty) return false;
  for (var i = 0; i < valor.length; i++) {
    final codigo = valor.codeUnitAt(i);
    if (codigo < 0x30 || codigo > 0x39) return false;
  }
  return true;
}
