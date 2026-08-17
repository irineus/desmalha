/// Abertura do banco local com a cifra conferida — nunca presumida.
///
/// A armadilha conhecida (registrada na modelagem local-first e no card
/// deste código) é o app linkar o SQLite comum e abrir o banco SEM CIFRA,
/// silenciosamente: tudo funciona, e o claim "nem nós conseguimos ver seus
/// dados" vira mentira que ninguém percebe. Por isso a abertura executa
/// `PRAGMA cipher_version` e **falha ruidosamente** se a resposta vier
/// vazia — resposta vazia é exatamente o que o SQLite sem SQLCipher devolve
/// para esse pragma. Mesma postura da guia que sai sem código de barras:
/// na dúvida, falhar visível.
///
/// O SQLCipher entra pelo build hook do `package:sqlite3` declarado no
/// `pubspec.yaml` (`hooks: → source: sqlcipher`). Remover aquela seção
/// devolveria o SQLite sem cifra — e é este arquivo que pega.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';

import 'banco.dart';
import 'chave_banco.dart';

/// Nome do arquivo do banco no diretório de documentos do app.
const nomeArquivoBanco = 'desmalha.db';

/// O banco abriu sem SQLCipher: o arquivo estaria em claro no aparelho.
///
/// Isto nunca é recuperável em tempo de execução — é erro de build (o hook
/// do sqlite3 não aplicou o SQLCipher) e o app não pode seguir gravando
/// dado fiscal em claro como se nada fosse.
class BancoSemCifraException implements Exception {
  const BancoSemCifraException();

  @override
  String toString() =>
      'BancoSemCifraException: PRAGMA cipher_version veio vazio — o binário '
      'do SQLite embarcado não tem SQLCipher. O banco NÃO será aberto sem '
      'cifra. Confira a seção `hooks:` do pubspec.yaml do app.';
}

/// Confere que a conexão está cifrando de verdade.
///
/// Chamada a cada abertura de conexão, o que inclui o boot do app
/// (`main.dart` força a primeira abertura antes do `runApp`).
void conferirCifraAtiva(CommonDatabase db) {
  final linhas = db.select('PRAGMA cipher_version;');
  final versao = linhas.isEmpty
      ? ''
      : (linhas.first.values.first?.toString() ?? '').trim();
  if (versao.isEmpty) {
    throw const BancoSemCifraException();
  }
}

/// Aplica a chave e confere a cifra — a ordem importa: `PRAGMA key` precisa
/// ser a PRIMEIRA instrução da conexão, antes de qualquer toque no arquivo.
///
/// A chave vai no formato raw (`x'…64 hex…'`): são 32 bytes já aleatórios
/// vindos do Keystore/Keychain, então o KDF do SQLCipher sobre passphrase
/// não acrescentaria nada além de latência de abertura.
///
/// Com chave errada (ou arquivo que não é um banco SQLCipher), o primeiro
/// SELECT falha com NOTADB — também ruidoso, também o comportamento certo:
/// adivinhar chave ou recriar o arquivo apagaria o livro-caixa do usuário.
void prepararCifra(CommonDatabase db, String chaveHex) {
  db.execute('PRAGMA key = "x\'$chaveHex\'";');
  conferirCifraAtiva(db);
  // Chave conferida contra o arquivo: com chave errada isto lança NOTADB.
  db.select('SELECT count(*) FROM sqlite_master;');
}

/// Executor do banco do app: arquivo em documentos, chave do cofre do
/// aparelho, cifra conferida a cada abertura.
QueryExecutor abrirConexaoCifrada({ChaveBanco? chave}) {
  return LazyDatabase(() async {
    final documentos = await getApplicationDocumentsDirectory();
    final arquivo = File(p.join(documentos.path, nomeArquivoBanco));
    final chaveHex = await (chave ?? ChaveBanco()).obterOuCriarHex();
    // ⚠️ iOS: falta marcar o arquivo com isExcludedFromBackup (equivalente ao
    // allowBackup=false do Android) — exige canal de plataforma e entra com o
    // card de backup E2E / iOS em simulador. Registrado no board.
    return NativeDatabase.createInBackground(
      arquivo,
      setup: (db) => prepararCifra(db, chaveHex),
    );
  });
}

BancoLocal? _bancoDoApp;

/// Instância única do banco do app. Construir é barato e síncrono; a
/// abertura de verdade (e com ela a conferência de cifra) acontece na
/// primeira consulta — que o boot dispara de propósito em [abrirBancoNoBoot].
BancoLocal bancoDoApp() => _bancoDoApp ??= BancoLocal(abrirConexaoCifrada());

/// Força a primeira abertura do banco durante o boot do app.
///
/// É isto que faz da conferência de cifra um teste de BOOT: se o binário
/// vier sem SQLCipher, o app cai aqui, antes do `runApp`, com
/// [BancoSemCifraException] — nunca meses depois, com anos de dado fiscal
/// gravados em claro.
Future<void> abrirBancoNoBoot() async {
  await bancoDoApp().customSelect('SELECT 1').get();
}
