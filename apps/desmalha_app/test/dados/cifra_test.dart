/// A propriedade central da persistência local: o banco NUNCA abre sem
/// cifra em silêncio.
///
/// O primeiro teste é a âncora do build inteiro: ele passa porque a seção
/// `hooks:` do pubspec.yaml troca o SQLite embarcado pelo SQLCipher — e a
/// troca vale para o host dos testes. Se alguém remover aquela seção, o
/// binário volta a ser SQLite comum, `PRAGMA cipher_version` volta vazio e
/// esta suíte inteira reprova. É o teste de boot do card rodando a cada
/// `flutter test`, não só no aparelho.
library;

import 'dart:io';

import 'package:desmalha_app/dados/conexao_cifrada.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('a suíte roda com SQLCipher de verdade (hook do pubspec aplicado)', () {
    final db = sqlite3.openInMemory();
    addTearDown(db.close);

    final versao = db.select('PRAGMA cipher_version;');
    expect(
      versao,
      isNotEmpty,
      reason: 'cipher_version vazio = o binário dos testes é SQLite sem '
          'SQLCipher. Confira a seção `hooks:` do pubspec.yaml.',
    );
    expect(() => conferirCifraAtiva(db), returnsNormally);
  });

  test('SQLite sem cifra é reprovado: pragma devolve zero linhas', () {
    // Zero linhas é exatamente o que o SQLite comum devolve para um pragma
    // que ele não conhece — o cenário real da armadilha.
    final semCifra = _SqliteSemCifra(ResultSet([], null, []));
    expect(
      () => conferirCifraAtiva(semCifra),
      throwsA(isA<BancoSemCifraException>()),
    );
  });

  test('SQLite sem cifra é reprovado: pragma devolve valor em branco', () {
    final emBranco =
        _SqliteSemCifra(ResultSet(['cipher_version'], null, [<Object?>['']]));
    expect(
      () => conferirCifraAtiva(emBranco),
      throwsA(isA<BancoSemCifraException>()),
    );
  });

  group('arquivo cifrado de verdade', () {
    late Directory dir;
    late String caminho;
    const chave =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'; // 64 hex = 32 bytes
    const chaveErrada =
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

    setUp(() {
      dir = Directory.systemTemp.createTempSync('desmalha_cifra');
      caminho = p.join(dir.path, 'cifra.db');
      final db = sqlite3.open(caminho);
      prepararCifra(db, chave);
      db.execute('CREATE TABLE t (x TEXT NOT NULL);');
      db.execute("INSERT INTO t VALUES ('livro-caixa');");
      db.close();
    });

    tearDown(() => dir.deleteSync(recursive: true));

    test('o arquivo em repouso NÃO é um SQLite legível', () {
      // Todo arquivo SQLite em claro começa com este cabeçalho fixo. Se ele
      // aparecer aqui, o dado fiscal está em claro no aparelho e o claim
      // "nem nós conseguimos ver seus dados" é falso.
      final cabecalho = File(caminho).readAsBytesSync().take(15).toList();
      expect(String.fromCharCodes(cabecalho), isNot('SQLite format 3'));
    });

    test('chave errada falha ruidosamente em vez de abrir vazio', () {
      final db = sqlite3.open(caminho);
      addTearDown(db.close);
      expect(
        () => prepararCifra(db, chaveErrada),
        throwsA(isA<SqliteException>()),
      );
    });

    test('chave certa reabre e lê o que foi gravado', () {
      final db = sqlite3.open(caminho);
      addTearDown(db.close);
      prepararCifra(db, chave);
      final linhas = db.select('SELECT x FROM t;');
      expect(linhas.single['x'], 'livro-caixa');
    });
  });
}

/// Dublê da única superfície que [conferirCifraAtiva] toca: `select`.
/// Qualquer outro uso é bug do próprio teste e estoura.
class _SqliteSemCifra implements CommonDatabase {
  _SqliteSemCifra(this._resposta);

  final ResultSet _resposta;

  @override
  ResultSet select(String sql, [List<Object?> parameters = const []]) =>
      _resposta;

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('só select() faz parte deste dublê');
}
