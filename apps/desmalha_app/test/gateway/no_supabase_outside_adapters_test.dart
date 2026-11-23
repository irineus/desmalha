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
  // +1 (24/09/2026, card "Botão de exclusão de conta dentro do app"): POST na
  // edge function excluir-conta. Porta própria, e não método da PortaAuth,
  // para a superfície do SDK de auth continuar mínima (trava anti-senha).
  'lib/conta/porta_exclusao_conta_http.dart',
  // +1 (24/09/2026, card "Backup cifrado ponta a ponta", PR 3/4): Storage e
  // PostgREST do backup, com o token da sessão. Porta própria pelo mesmo
  // motivo da exclusão.
  'lib/backup/porta_armazenamento_backup_http.dart',
  // +1 (25/09/2026, Cadeia 2 item 10, "Envio opcional de extrato ao
  // suporte"): upload ao bucket suporte-extratos e registro em
  // envios_suporte, com o token da sessão. Porta própria pelo mesmo motivo
  // da exclusão.
  'lib/suporte/porta_suporte_http.dart',
  // +1 (24/09/2026, card "Telas de onboarding e login"): RPC
  // registrar_aceite com o token da sessão. Porta própria pelo mesmo motivo
  // da exclusão — o aceite não é método da PortaAuth.
  'lib/onboarding/porta_aceite_http.dart',
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
