@TestOn('vm')
library;

// `no_supabase_outside_adapters_test` — o segundo portão de fonte do
// contrato do Fulcrum (docs/testing.md §7). **A lista de permissão É a
// definição da porta**: só os arquivos listados falam o protocolo do
// Supabase, seja importando o SDK, seja montando a rota REST à mão. Encolher
// a lista é progresso e dispensa justificativa; crescê-la exige uma no PR,
// porque cada entrada nova é mais um arquivo a reescrever no dia em que o
// destino mudar (Fase 05 do Fulcrum).
//
// O Fulcrum mediu "Desmalha 1" pelo import do SDK; a lista verdadeira é 2,
// porque `porta_catalogo_rest.dart` faz GET cru no PostgREST sem importar
// nada — e é exatamente o arquivo que um portão só de import não enxergaria.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../auth/trava_sem_senha_test.dart' show semComentarios;

/// A porta. Mudou? Justifique no PR.
const _permitidos = {
  'lib/auth/porta_auth_supabase.dart', // SDK: auth por código de e-mail
  'lib/catalogo/porta_catalogo_rest.dart', // REST cru: GET do catálogo
};

/// O que conta como "falar Supabase" em CÓDIGO (comentários descartados;
/// strings preservadas, porque uma rota montada à mão vive numa string).
final _sinais = <String, RegExp>{
  'import do SDK': RegExp(r'''import\s+['"]package:(supabase|supabase_flutter|gotrue|postgrest|storage_client|functions_client|realtime_client)/'''),
  'rota REST do Supabase': RegExp(r'/(rest|auth|storage|functions|realtime)/v1'),
  'cliente global do SDK': RegExp(r'\bSupabase\.(instance|initialize)\b'),
};

String _relativo(File f) => f.path.replaceAll(r'\', '/');

void main() {
  final arquivos = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('a varredura enxerga lib/ e as duas portas existem', () {
    final nomes = arquivos.map(_relativo).toSet();
    expect(nomes.length, greaterThan(10));
    expect(nomes, containsAll(_permitidos),
        reason: 'porta removida: tire-a da lista (encolher é progresso)');
  });

  test('só a porta fala Supabase', () {
    final violacoes = <String>[];
    for (final arquivo in arquivos) {
      final caminho = _relativo(arquivo);
      if (_permitidos.contains(caminho)) continue;
      final codigo = semComentarios(arquivo.readAsStringSync());
      for (final sinal in _sinais.entries) {
        if (sinal.value.hasMatch(codigo)) {
          violacoes.add('$caminho: ${sinal.key}');
        }
      }
    }
    expect(violacoes, isEmpty,
        reason: 'fora da porta: mova para um adaptador ou justifique a '
            'entrada nova na lista no PR');
  });

  test('a lista não tem gordura: cada porta fala mesmo Supabase', () {
    for (final caminho in _permitidos) {
      final codigo = semComentarios(File(caminho).readAsStringSync());
      expect(_sinais.values.any((r) => r.hasMatch(codigo)), isTrue,
          reason: '$caminho não fala mais Supabase — encolha a lista');
    }
  });
}
