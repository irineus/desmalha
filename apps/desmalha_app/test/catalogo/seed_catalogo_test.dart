import 'dart:convert';

import 'package:desmalha_core/catalogo_arquivos.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:desmalha_app/catalogo/repositorio_catalogo.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// O seed é arquivo GERADO e commitado (`desmalha_core:gerar_seed_catalogo`).
/// Arquivo gerado que se commita apodrece calado — alguém edita o catálogo
/// do repositório, esquece de regenerar, e o app embarca conteúdo velho sem
/// nenhum sinal. Este teste é o sinal, no mesmo papel do `--conferir` do
/// `gerar_pagina.ts` para o site.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('o seed embarcado existe, é declarado no pubspec e carrega', () async {
    // rootBundle prova a declaração em pubspec.yaml: asset fora da lista
    // nem chega ao bundle — e o app iniciaria sem catálogo nenhum.
    final texto = await rootBundle.loadString(assetSeedCatalogo);
    final catalogo =
        Catalogo.fromJson(jsonDecode(texto) as Map<String, Object?>);
    expect(catalogo.tabelasIrpf, isNotEmpty);
    expect(catalogo.feriadosPorAno, isNotEmpty);
    expect(catalogo.perfisCsv, isNotEmpty);
  });

  test('o seed embarcado bate com o catálogo do repositório', () async {
    final embarcado = jsonDecode(await rootBundle.loadString(assetSeedCatalogo));

    final itens =
        itensDoCatalogoNoRepositorio('../../packages/desmalha_core');
    final esperado = Catalogo.fromItens(itens).toJson();

    expect(
      jsonEncode(embarcado),
      jsonEncode(esperado),
      reason: 'seed desatualizado — rode: '
          'fvm dart run desmalha_core:gerar_seed_catalogo',
    );
  });
}
