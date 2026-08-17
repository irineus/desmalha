/// Gera o seed do catálogo embarcado no app.
///
///   fvm dart run desmalha_core:gerar_seed_catalogo [--conferir]
///
/// O app precisa calcular OFFLINE desde o primeiro boot — antes de qualquer
/// rede existe o seed: um snapshot do catálogo do repositório, embarcado como
/// asset em `apps/desmalha_app/assets/catalogo/seed.json`. Este script o
/// (re)gera; com `--conferir` apenas compara e sai com código 1 se divergir.
///
/// Arquivo gerado que se commita apodrece calado — mesmo raciocínio do
/// `site/index.html`. Quem segura a porta é o teste
/// `apps/desmalha_app/test/catalogo/seed_catalogo_test.dart`, que refaz a
/// comparação a cada `flutter test`; este script é a conveniência de
/// regenerar quando o teste reprovar.
library;

import 'dart:convert';
import 'dart:io';

import 'package:desmalha_core/catalogo_arquivos.dart';
import 'package:desmalha_core/desmalha_core.dart';

void main(List<String> args) {
  final raizCore = _localizarRaizDoCore();
  final destino = File(
    '$raizCore/../../apps/desmalha_app/assets/catalogo/seed.json',
  );

  final itens = itensDoCatalogoNoRepositorio(raizCore);
  // Passar pelo Catalogo valida cada item contra o schema do seu tipo:
  // seed malformado reprova aqui, não no primeiro boot de um usuário.
  final snapshot = Catalogo.fromItens(itens).toJson();
  final texto =
      '${const JsonEncoder.withIndent('  ').convert(snapshot)}\n';

  if (args.contains('--conferir')) {
    final atual = destino.existsSync() ? destino.readAsStringSync() : null;
    if (atual != texto) {
      stderr.writeln(
        'seed do catálogo desatualizado em ${destino.path} — '
        'rode: fvm dart run desmalha_core:gerar_seed_catalogo',
      );
      exit(1);
    }
    stdout.writeln('seed do catálogo confere.');
    return;
  }

  destino.parent.createSync(recursive: true);
  destino.writeAsStringSync(texto);
  stdout.writeln('seed gerado em ${destino.path} (${itens.length} itens).');
}

/// Sobe do diretório atual até achar a raiz do pacote `desmalha_core` (quem
/// tem `catalogo/` e `perfis/`), para o comando funcionar tanto da raiz do
/// monorepo quanto de dentro do pacote.
String _localizarRaizDoCore() {
  var dir = Directory.current;
  while (true) {
    final candidatos = [
      dir.path,
      '${dir.path}/packages/desmalha_core',
    ];
    for (final c in candidatos) {
      if (Directory('$c/catalogo').existsSync() &&
          Directory('$c/perfis').existsSync() &&
          File('$c/pubspec.yaml').existsSync()) {
        return c;
      }
    }
    final pai = dir.parent;
    if (pai.path == dir.path) {
      throw StateError(
        'raiz do desmalha_core não encontrada subindo de '
        '${Directory.current.path}',
      );
    }
    dir = pai;
  }
}
