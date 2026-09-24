@TestOn('vm')
library;

// `gateway_url_test` — um dos três portões de fonte que o contrato do Fulcrum
// (docs/tenant-onboarding.md §4, docs/testing.md §7) põe sob a guarda de cada
// app: a configuração do Desmalha NUNCA aponta para `*.supabase.co`. O app
// nasceu atrás do gateway; um build direto no Supabase furaria a troca de
// chave do tenant e amarraria o binário a um destino.

import 'dart:io';

import 'package:desmalha_app/auth/configuracao_supabase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('motivoUrlRecusada — a regra aplicada em runtime', () {
    test('o gateway de produção e o de dev são aceitos', () {
      expect(motivoUrlRecusada('https://api.desmalha.app'), isNull);
      expect(motivoUrlRecusada('https://api-dev.desmalha.app'), isNull);
    });

    test('direto no Supabase é recusado, com o motivo', () {
      for (final url in [
        'https://caqxssmxeiuutfguxdzj.supabase.co',
        'https://deqmqiyxfbvlhardtjni.supabase.co/',
        'https://QUALQUER.SUPABASE.CO',
        'https://projeto.supabase.in',
      ]) {
        expect(motivoUrlRecusada(url), contains('gateway'), reason: url);
      }
    });

    test('sem https, vazio ou não-endereço também é recusado', () {
      expect(motivoUrlRecusada('http://api-dev.desmalha.app'), isNotNull);
      expect(motivoUrlRecusada(''), isNotNull);
      expect(motivoUrlRecusada('api-dev.desmalha.app'), isNotNull);
    });

    test('sem dart-define (testes e CI), o build se declara sem configuração',
        () {
      expect(supabaseConfigurado, isFalse);
      expect(problemaDeConfiguracao, isNotNull);
    });
  });

  group('nenhum arquivo do app ou do CI configura o Supabase direto', () {
    // O que o runtime recusa, o repositório também não pode sugerir: um
    // exemplo de comando com `SUPABASE_URL=https://<ref>.supabase.co` num
    // comentário é o próximo build de alguém.
    final raizRepo = Directory('../..');
    final alvos = [
      ...Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')),
      File('../../codemagic.yaml'),
      File('../../CLAUDE.md'),
      File('../../README.md'),
      File('../../docs/ambiente-windows.md'),
    ];

    test('a varredura enxerga os arquivos', () {
      expect(raizRepo.existsSync(), isTrue);
      expect(alvos.where((f) => f.existsSync()), hasLength(alvos.length));
      expect(alvos.length, greaterThan(10));
    });

    for (final arquivo in alvos) {
      test(arquivo.path, () {
        final texto = arquivo.readAsStringSync();
        expect(
          RegExp(r'[a-z0-9<>-]+\.supabase\.co', caseSensitive: false)
              .hasMatch(texto),
          isFalse,
          reason: '${arquivo.path} cita um host *.supabase.co: o app fala '
              'só com api(-dev).desmalha.app',
        );
      });
    }
  });
}
