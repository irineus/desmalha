/// Gera o GOLDEN FILE de uma versão do formato de backup — UMA VEZ.
///
/// Regra 5 da especificação do backup: um blob-fixture de cada versão
/// histórica fica versionado, e o teste restaura cada um e compara com o
/// estado esperado. É a prova de que o app novo continua lendo o que o app
/// velho gravou — o análogo dos cenários table-driven do motor.
///
/// Por isso este gerador **recusa sobrescrever**: o golden de uma versão é um
/// artefato histórico. Regerar com o código de hoje provaria que o código de
/// hoje lê o que o código de hoje escreve, que é o round-trip, não o golden.
///
///   fvm dart run test/fixtures/backup/gerador_golden.dart
///
/// A chave-mestra e o código daqui são DE TESTE, públicos por construção.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:desmalha_core/desmalha_core.dart';

import '../../backup/amostra_backup.dart';

/// Chave-mestra de teste: 0x00, 0x01, … 0x1f.
final chaveMestraGolden = List<int>.generate(32, (i) => i);

/// Código de recuperação de teste.
const codigoGolden = 'GOLDEN-FORMATO-V1-TESTE';

Future<void> main() async {
  final dir = Directory('test/fixtures/backup/formato_v$formatoBackupAtual');
  final blob = File('${dir.path}/golden.dsmb');
  final esperado = File('${dir.path}/esperado.json');
  if (blob.existsSync() || esperado.existsSync()) {
    stderr.writeln(
      'golden do formato $formatoBackupAtual já existe e é histórico: não '
      'sobrescrevo. Formato novo = novo diretório formato_vN.',
    );
    exit(1);
  }
  dir.createSync(recursive: true);

  final payload = await serializarPayload(
    documentos: amostraBackup,
    appVersao: '1.0.0',
    schemaLocalVersao: 1,
    geradoEm: DateTime.utc(2026, 9, 24),
    seq: 1,
    plataforma: 'android',
  );
  final cabecalho = await embrulharChaveMestra(
    chaveMestra: chaveMestraGolden,
    codigo: codigoGolden,
    aleatorio: Random(20260924),
  );
  final dsmb = await selarDsmb(
    cabecalho: cabecalho,
    chaveMestra: chaveMestraGolden,
    conteudo: payload,
    aleatorio: Random(20260924),
  );
  blob.writeAsBytesSync(dsmb);
  esperado.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert([
      for (final d in amostraBackup) d.toJson(),
    ])}\n',
  );
  stdout.writeln('golden do formato $formatoBackupAtual: ${dsmb.length} bytes');
}
