/// Documento legal publicado — a allowlist do registro de aceite.
///
/// O servidor só grava aceite de uma versão que exista aqui
/// (`public.registrar_aceite`, migration `*_documentos_legais.sql`), e o
/// aceite passa a carregar o [sha256Texto] do texto aceito. Sem isso o
/// cliente podia registrar aceite de `'2020-01-v1'` — uma versão que nunca
/// existiu —, e um registro que existe para DEFENDER o operador provaria
/// menos do que parece: o titular poderia alegar que nunca viu o texto real.
///
/// O item chega ao app pelo catálogo versionado, como o resto do conteúdo
/// que muda sem release. Publicado é para sempre: mudar o texto é publicar
/// uma versão NOVA — o banco recusa alterar ou remover um documento já
/// publicado, porque o hash de um aceite antigo precisa continuar apontando
/// para o texto que a pessoa leu.
library;

/// Os documentos que o registro de aceite conhece. Espelha o CHECK de
/// `aceites_termos.documento` e o de `aceites_termos_local` no app.
abstract final class TipoDocumentoLegal {
  static const termosUso = 'termos_uso';
  static const politicaPrivacidade = 'politica_privacidade';

  static const todos = {termosUso, politicaPrivacidade};
}

/// Uma versão publicada de um documento legal.
class DocumentoLegal {
  DocumentoLegal({
    required this.id,
    required this.documento,
    required this.versao,
    required this.publicadoEm,
    required this.url,
    required this.sha256Texto,
    required this.fonte,
  }) {
    if (!TipoDocumentoLegal.todos.contains(documento)) {
      throw FormatException(
        'documento legal: "$documento" não é um dos documentos conhecidos '
        '${TipoDocumentoLegal.todos.toList()}',
      );
    }
    if (!_reVersao.hasMatch(versao)) {
      throw FormatException(
        "documento legal: versão \"$versao\" fora da convenção 'YYYY-MM-vN'",
      );
    }
    final esperado = idDe(documento, versao);
    if (id != esperado) {
      // Um item por (documento, versão): o id é derivado, não escolhido.
      // Dois arquivos para a mesma versão com ids diferentes seriam dois
      // textos disputando o mesmo aceite.
      throw FormatException(
        'documento legal: id "$id" deveria ser "$esperado" '
        '(documento com hífen + versão)',
      );
    }
    if (!_ehDataCivilValida(publicadoEm)) {
      throw FormatException(
        "documento legal: publicado_em \"$publicadoEm\" não é data civil "
        "'YYYY-MM-DD' válida",
      );
    }
    if (!url.startsWith('https://') || url.length <= 'https://'.length) {
      throw FormatException(
        'documento legal: url "$url" precisa ser https — é o endereço que o '
        'titular abre para ler o texto que aceita',
      );
    }
    if (!_reSha256.hasMatch(sha256Texto)) {
      throw FormatException(
        'documento legal: sha256_texto "$sha256Texto" precisa ser 64 dígitos '
        'hexadecimais minúsculos',
      );
    }
  }

  static final _reVersao = RegExp(r'^\d{4}-\d{2}-v\d+$');
  static final _reSha256 = RegExp(r'^[0-9a-f]{64}$');

  /// O id do item no catálogo para ([documento], [versao]):
  /// `termos_uso` + `2026-09-v1` → `termos-uso-2026-09-v1`.
  static String idDe(String documento, String versao) =>
      '${documento.replaceAll('_', '-')}-$versao';

  /// Identificador estável no catálogo — ver [idDe].
  final String id;

  /// Um de [TipoDocumentoLegal.todos].
  final String documento;

  /// Versão na convenção `'YYYY-MM-vN'` da PP/Termos v0.2.
  final String versao;

  /// Data civil `'YYYY-MM-DD'` da publicação.
  final String publicadoEm;

  /// Endereço público onde o texto desta versão é servido.
  final String url;

  /// SHA-256, em hexadecimal minúsculo, dos bytes exatos servidos em [url].
  /// É o que o aceite referencia: o app pode baixar o texto e conferir que
  /// é este o texto que está mostrando.
  final String sha256Texto;

  /// Origem rastreável da publicação (card, aprovação, revisão).
  final String fonte;

  factory DocumentoLegal.fromJson(Map<String, Object?> json) {
    String texto(String campo) {
      final valor = json[campo];
      if (valor is! String || valor.isEmpty) {
        throw FormatException(
          'documento legal: campo "$campo" ausente ou vazio',
        );
      }
      return valor;
    }

    return DocumentoLegal(
      id: texto('id'),
      documento: texto('documento'),
      versao: texto('versao'),
      publicadoEm: texto('publicado_em'),
      url: texto('url'),
      sha256Texto: texto('sha256_texto'),
      fonte: texto('fonte'),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'documento': documento,
    'versao': versao,
    'publicado_em': publicadoEm,
    'url': url,
    'sha256_texto': sha256Texto,
    'fonte': fonte,
  };
}

/// `true` para `'YYYY-MM-DD'` que existe no calendário.
bool _ehDataCivilValida(String data) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(data);
  if (m == null) return false;
  final ano = int.parse(m.group(1)!);
  final mes = int.parse(m.group(2)!);
  final dia = int.parse(m.group(3)!);
  if (mes < 1 || mes > 12 || dia < 1) return false;
  return dia <= DateTime.utc(ano, mes + 1, 0).day;
}
