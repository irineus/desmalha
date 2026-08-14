import 'dart:convert';
import 'dart:io';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

/// Os JSONs em `perfis/` são os perfis de referência que o usuário passa ao
/// CLI (`--perfil`) e o embrião do catálogo versionado servido pela API.
/// Este teste garante que continuam carregáveis por [PerfilCsv.fromJson].
void main() {
  group('perfis de referência em perfis/', () {
    final arquivos = Directory('perfis')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();

    test('existem os três perfis iniciais', () {
      final nomes = arquivos.map((f) => f.uri.pathSegments.last).toSet();
      expect(
        nomes,
        containsAll({
          'nubank-conta-csv-v1.json',
          'inter-conta-csv-v1.json',
          'bb-conta-csv-v1.json',
        }),
      );
    });

    for (final arquivo in Directory('perfis')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))) {
      test('${arquivo.uri.pathSegments.last} carrega e o id bate com o nome',
          () {
        final json =
            jsonDecode(arquivo.readAsStringSync()) as Map<String, Object?>;
        final perfil = PerfilCsv.fromJson(json);
        expect('${perfil.id}.json', arquivo.uri.pathSegments.last);
        // Round-trip: o que o catálogo servir tem de voltar idêntico.
        expect(PerfilCsv.fromJson(perfil.toJson()).toJson(), perfil.toJson());
      });
    }
  });
}
