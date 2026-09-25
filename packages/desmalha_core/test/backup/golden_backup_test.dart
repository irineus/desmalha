// Golden files do backup: cada versão histórica do formato continua
// restaurando. Ver test/fixtures/backup/gerador_golden.dart.

import 'dart:convert';
import 'dart:io';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

import '../fixtures/backup/gerador_golden.dart';

void main() {
  final versoes = Directory('test/fixtures/backup')
      .listSync()
      .whereType<Directory>()
      .where((d) => d.uri.pathSegments.any((s) => s.startsWith('formato_v')))
      .toList();

  test('existe golden para CADA versão do formato até a atual', () {
    for (var v = 1; v <= formatoBackupAtual; v++) {
      expect(
        File('test/fixtures/backup/formato_v$v/golden.dsmb').existsSync(),
        isTrue,
        reason: 'formato $v sem golden: o app novo não prova que lê o velho',
      );
    }
    expect(versoes, isNotEmpty);
  });

  test('formato anterior ao atual tem o que o app ATUAL deve ler dele', () {
    // O golden.dsmb e o esperado.json de um formato velho são históricos:
    // não mudam. O que muda a cada formato novo é o resultado da cadeia de
    // migrações — escrito à mão em esperado_atual.json, para que a migração
    // seja provada contra valores, não contra ela mesma.
    for (var v = 1; v < formatoBackupAtual; v++) {
      expect(
        File('test/fixtures/backup/formato_v$v/esperado_atual.json')
            .existsSync(),
        isTrue,
        reason: 'formato $v sem esperado_atual.json',
      );
    }
  });

  for (final dir in versoes) {
    final nome = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
    group(nome, () {
      final blob = File('${dir.path}/golden.dsmb').readAsBytesSync();
      final atual = File('${dir.path}/esperado_atual.json');
      final esperado = jsonDecode(
        (atual.existsSync() ? atual : File('${dir.path}/esperado.json'))
            .readAsStringSync(),
      ) as List<Object?>;

      test('restaura pela chave-mestra (mesma plataforma)', () async {
        final conteudo = await abrirDsmbComChaveMestra(blob, chaveMestraGolden);
        final lido = await lerPayload(conteudo);
        expect(lido.documentos.map((d) => d.toJson()).toList(), esperado);
      });

      test('restaura pelo código de recuperação (outra plataforma)', () async {
        final r = await abrirDsmbComCodigo(blob, codigoGolden);
        expect(r.chaveMestra, chaveMestraGolden);
        final lido = await lerPayload(r.conteudo);
        expect(lido.documentos.map((d) => d.toJson()).toList(), esperado);
      });
    });
  }

  test('round-trip completo: exportar → selar → abrir → ler', () async {
    final documentos = [
      for (final d in (jsonDecode(File(
        'test/fixtures/backup/formato_v$formatoBackupAtual/esperado.json',
      ).readAsStringSync()) as List<Object?>).cast<Map<String, Object?>>())
        DocumentoBackup(d['t']! as String, d['d']! as Map<String, Object?>),
    ];
    final cabecalho = await embrulharChaveMestra(
      chaveMestra: chaveMestraGolden,
      codigo: codigoGolden,
    );
    final dsmb = await selarDsmb(
      cabecalho: cabecalho,
      chaveMestra: chaveMestraGolden,
      conteudo: await serializarPayload(
        documentos: documentos,
        appVersao: '1.0.0',
        schemaLocalVersao: formatoBackupAtual,
        geradoEm: DateTime.utc(2026, 9, 24),
        seq: 2,
        plataforma: 'ios',
      ),
    );
    final lido = await lerPayload(
      await abrirDsmbComChaveMestra(dsmb, chaveMestraGolden),
    );
    expect(lido.documentos.map((d) => d.toJson()).toList(),
        documentos.map((d) => d.toJson()).toList());
    expect(lido.manifesto.plataforma, 'ios');
  });
}
