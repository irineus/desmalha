import 'package:desmalha_core/desmalha_core.dart';

const _hash =
    '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08';

Map<String, Object?> _item(String documento, String versao) {
  final conteudo = {
    'id': DocumentoLegal.idDe(documento, versao),
    'documento': documento,
    'versao': versao,
    'publicado_em': '2026-09-24',
    'url': 'https://desmalha.app/legal/$documento/$versao',
    'sha256_texto': _hash,
    'fonte': 'teste',
  };
  return {
    'tipo': TipoCatalogo.documentoLegal,
    'id': conteudo['id'],
    'conteudo': conteudo,
  };
}

/// Catálogo só com documentos legais publicados (versão `null` = ausente).
Catalogo catalogoComDocumentos({String? termos, String? politica}) =>
    Catalogo.fromItens([
      if (termos != null) _item(TipoDocumentoLegal.termosUso, termos),
      if (politica != null)
        _item(TipoDocumentoLegal.politicaPrivacidade, politica),
    ]);
