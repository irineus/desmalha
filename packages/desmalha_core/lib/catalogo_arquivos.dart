/// Leitura do manifesto do catálogo A PARTIR DOS ARQUIVOS do repositório.
///
/// NÃO faz parte da API do app (usa `dart:io` e caminhos de repositório):
/// serve aos testes, ao gerador do seed embarcado
/// (`bin/gerar_seed_catalogo.dart`) e a qualquer ferramenta local — mesmo
/// papel do `validacao.dart` para o CLI de extratos.
///
/// A convenção é a do publicador (`tool/publicar_catalogo.ts`):
///
///     catalogo/<tipo>/<id>.json      # o nome do arquivo É o id do item
///     perfis/<id>.json               # tipo perfil_csv
///
/// Os dois implementam a mesma varredura em linguagens diferentes; ambos são
/// exercitados contra os MESMOS arquivos reais pelos seus testes, então uma
/// divergência de convenção aparece como diferença de manifesto, não como
/// erro silencioso.
library;

import 'dart:convert';
import 'dart:io';

/// Monta os itens `(tipo, id, conteudo)` do catálogo a partir da raiz do
/// pacote `desmalha_core` (o diretório que contém `catalogo/` e `perfis/`).
///
/// A ordem é determinística (tipos e arquivos em ordem lexicográfica) para
/// que o seed gerado não mude de forma sem mudar de conteúdo.
List<Map<String, Object?>> itensDoCatalogoNoRepositorio(String raizCore) {
  final itens = <Map<String, Object?>>[];

  void lerDiretorio(Directory dir, String tipo) {
    final arquivos = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final arquivo in arquivos) {
      final nome = arquivo.uri.pathSegments.last;
      final id = nome.substring(0, nome.length - '.json'.length);
      final conteudo =
          jsonDecode(arquivo.readAsStringSync()) as Map<String, Object?>;
      itens.add({'tipo': tipo, 'id': id, 'conteudo': conteudo});
    }
  }

  final base = Directory('$raizCore/catalogo');
  final tipos = base
      .listSync()
      .whereType<Directory>()
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final sub in tipos) {
    final tipo = sub.uri.pathSegments.where((s) => s.isNotEmpty).last;
    lerDiretorio(sub, tipo);
  }

  lerDiretorio(Directory('$raizCore/perfis'), 'perfil_csv');

  if (itens.isEmpty) {
    throw StateError('nenhum item de catálogo encontrado em $raizCore');
  }
  return itens;
}
