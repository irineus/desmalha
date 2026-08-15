@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A trava anti-senha, verificada no código-fonte.
///
/// A decisão do projeto é OTP por e-mail, **sem senha**: a senha da conta não
/// pode ser o que protege o backup, porque quem a esquece perderia o
/// livro-caixa de cinco anos. O Supabase **não tem toggle** para desativar
/// login por senha — senha e código vivem no mesmo provedor de e-mail —, então
/// a garantia primária é a de que o app nunca chama a API com senha.
///
/// Um teste de comportamento não consegue provar isso: ele só cobre o caminho
/// que ele mesmo exercita. O que precisa ser verdade é uma propriedade do
/// código inteiro — "em lugar nenhum de `lib/` existe uma chamada de senha" —,
/// e isso se verifica lendo `lib/`. Por isso este teste varre o fonte.
///
/// A segunda camada da trava está no banco
/// (`supabase/migrations/20260815000359_trava_sem_senha.sql`): um cadastro com
/// senha que escape do cliente falha alto, em vez de criar em silêncio uma
/// conta cuja senha vira o elo fraco do backup.
void main() {
  final arquivosLib = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('a varredura enxerga o código do app', () {
    // Sem esta âncora, um erro de caminho faria todos os testes abaixo
    // passarem por vacuidade — o pior resultado possível para uma trava.
    expect(arquivosLib, isNotEmpty);
    expect(
      arquivosLib.map((f) => f.path),
      contains(endsWith('porta_auth_supabase.dart')),
    );
  });

  group('nenhuma autenticação por senha em lib/', () {
    // Cada entrada é um caminho de senha do SDK ou do endpoint REST.
    const proibidos = <String>[
      'password',
      'signUp',
      'resetPasswordForEmail',
      'signInWithPassword',
    ];

    for (final arquivo in arquivosLib) {
      test(arquivo.path, () {
        final codigo = semComentarios(arquivo.readAsStringSync());
        for (final proibido in proibidos) {
          expect(
            codigo.toLowerCase(),
            isNot(contains(proibido.toLowerCase())),
            reason:
                '${arquivo.path} menciona "$proibido" em código. O Desmalha '
                'autentica só por código de e-mail; a senha da conta não pode '
                'existir, porque ela viraria o elo fraco do backup.',
          );
        }
      });
    }
  });

  group('nenhum login social em lib/', () {
    // Login social traria a exigência de Sign in with Apple na submissão à
    // App Store e um terceiro no caminho da identidade — decisão do card.
    const proibidos = <String>[
      'signInWithOAuth',
      'signInWithIdToken',
      'signInWithSSO',
      'signInWithWeb3',
      'OAuthProvider',
      'linkIdentity',
    ];

    for (final arquivo in arquivosLib) {
      test(arquivo.path, () {
        final codigo = semComentarios(arquivo.readAsStringSync()).toLowerCase();
        for (final proibido in proibidos) {
          expect(
            codigo,
            isNot(contains(proibido.toLowerCase())),
            reason:
                '${arquivo.path} menciona "$proibido" em código. Sem login '
                'social: o e-mail é a conta.',
          );
        }
      });
    }
  });

  test('o SDK de auth entra no app por um arquivo só', () {
    // O que mantém a auditoria acima barata: a superfície é um arquivo. Se o
    // SDK passar a ser importado em outro lugar, esta trava precisa ser
    // reavaliada de propósito, e não por descuido.
    const permitidos = {'lib/auth/porta_auth_supabase.dart'};

    final importam = arquivosLib
        .where(
          (f) => f.readAsStringSync().contains(
            "import 'package:supabase_flutter/",
          ),
        )
        .map((f) => f.path.replaceAll(r'\', '/'))
        .toSet();

    expect(importam, permitidos);
  });

  group('a varredura sabe separar comentário de código', () {
    // Um extrator quebrado deixaria a trava passando por engano — é ele que
    // decide o que a varredura chega a enxergar.
    const senha = 'pass' 'word';

    test('descarta comentário de linha', () {
      expect(semComentarios('// nunca use $senha\nvar x = 1;'), isNot(contains(senha)));
    });

    test('descarta comentário de documentação', () {
      expect(semComentarios('/// proibido: $senha\nvar x = 1;'), isNot(contains(senha)));
    });

    test('descarta comentário de bloco, inclusive aninhado', () {
      expect(
        semComentarios('/* fora /* dentro $senha */ ainda fora */ var x = 1;'),
        isNot(contains(senha)),
      );
    });

    test('preserva o conteúdo de string', () {
      expect(semComentarios("var b = {'$senha': v};"), contains(senha));
      expect(semComentarios('var b = {"$senha": v};'), contains(senha));
      expect(semComentarios("var b = '''$senha''';"), contains(senha));
    });

    test('uma URL em string não engole o resto da linha', () {
      // Sem consciência de string, o "//" de "https://" viraria comentário e
      // esconderia o que vem depois — um falso negativo silencioso.
      expect(
        semComentarios("var u = 'https://exemplo.com'; var b = {'$senha': v};"),
        contains(senha),
      );
    });

    test('preserva o código depois do comentário', () {
      expect(semComentarios('// nota\nvar x = 1;'), contains('var x = 1;'));
    });
  });
}

/// Devolve o código sem comentários, preservando o conteúdo das strings.
///
/// Comentário não é chamada: um `///` que explica por que a senha é proibida
/// não pode reprovar a trava. String, ao contrário, é preservada de propósito
/// — um corpo de requisição REST montado à mão com `'password'` seria
/// exatamente o caminho que este teste existe para pegar.
String semComentarios(String fonte) {
  final saida = StringBuffer();
  var i = 0;
  while (i < fonte.length) {
    final c = fonte[i];
    final proximo = i + 1 < fonte.length ? fonte[i + 1] : '';

    if (c == '/' && proximo == '/') {
      while (i < fonte.length && fonte[i] != '\n') {
        i++;
      }
      continue;
    }
    if (c == '/' && proximo == '*') {
      // Comentário de bloco em Dart aninha.
      var profundidade = 1;
      i += 2;
      while (i < fonte.length && profundidade > 0) {
        if (fonte[i] == '/' && i + 1 < fonte.length && fonte[i + 1] == '*') {
          profundidade++;
          i += 2;
        } else if (fonte[i] == '*' &&
            i + 1 < fonte.length &&
            fonte[i + 1] == '/') {
          profundidade--;
          i += 2;
        } else {
          i++;
        }
      }
      continue;
    }
    if (c == "'" || c == '"') {
      final cru = saida.isNotEmpty && saida.toString().endsWith('r');
      final triplo = fonte.startsWith(c * 3, i);
      final fechamento = triplo ? c * 3 : c;
      saida.write(fechamento);
      i += fechamento.length;
      while (i < fonte.length) {
        if (!cru && fonte[i] == r'\') {
          saida.write(fonte[i]);
          i++;
          if (i < fonte.length) {
            saida.write(fonte[i]);
            i++;
          }
          continue;
        }
        if (fonte.startsWith(fechamento, i)) {
          saida.write(fechamento);
          i += fechamento.length;
          break;
        }
        // Uma string de aspas simples não atravessa a quebra de linha; parar
        // aqui evita que uma aspa solta engula o resto do arquivo.
        if (!triplo && fonte[i] == '\n') break;
        saida.write(fonte[i]);
        i++;
      }
      continue;
    }
    saida.write(c);
    i++;
  }
  return saida.toString();
}
