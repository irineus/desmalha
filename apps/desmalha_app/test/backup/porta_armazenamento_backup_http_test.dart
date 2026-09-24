@TestOn('vm')
library;

// Sem testWidgets de propósito: o binding de widget troca o HttpClient.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:desmalha_app/backup/porta_armazenamento_backup.dart';
import 'package:desmalha_app/backup/porta_armazenamento_backup_http.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer servidor;
  late List<Map<String, Object?>> recebidas;
  late int status;
  late String resposta;

  setUp(() async {
    recebidas = [];
    status = 200;
    resposta = '[]';
    servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    servidor.listen((r) async {
      final corpo = await r.fold<List<int>>(<int>[], (a, b) => a..addAll(b));
      recebidas.add({
        'metodo': r.method,
        'caminho': r.uri.toString(),
        'apikey': r.headers.value('apikey'),
        'autorizacao': r.headers.value('authorization'),
        'upsert': r.headers.value('x-upsert'),
        'prefer': r.headers.value('prefer'),
        'corpo': corpo,
      });
      r.response
        ..statusCode = status
        ..write(resposta);
      await r.response.close();
    });
  });

  tearDown(() => servidor.close(force: true));

  PortaArmazenamentoBackupHttp porta() => PortaArmazenamentoBackupHttp(
    url: 'http://127.0.0.1:${servidor.port}',
    chavePublicavel: 'chave-do-tenant',
    tokenDaSessao: () => 'token-da-sessao',
  );

  test('upload: POST no bucket backups, x-upsert false, chave e sessão',
      () async {
    await porta().enviar('uid/000001.dsmb', Uint8List.fromList([1, 2, 3]));
    final r = recebidas.single;
    expect(r['metodo'], 'POST');
    expect(r['caminho'], '/storage/v1/object/backups/uid/000001.dsmb');
    expect(r['upsert'], 'false');
    expect(r['apikey'], 'chave-do-tenant');
    expect(r['autorizacao'], 'Bearer token-da-sessao');
    expect(r['corpo'], [1, 2, 3]);
  });

  test('objeto existente (400 com statusCode 409) vira CONFLITO', () async {
    status = 400;
    resposta = '{"statusCode":"409","error":"Duplicate","message":"exists"}';
    await expectLater(
      porta().enviar('uid/000001.dsmb', Uint8List(4)),
      throwsA(isA<FalhaArmazenamentoBackup>()
          .having((f) => f.conflito, 'conflito', isTrue)),
    );
  });

  test('listar objetos: prefixo do titular, tamanho, pastas de fora', () async {
    resposta = jsonEncode([
      {'name': '000001.dsmb', 'id': 'a', 'metadata': {'size': 962}},
      {'name': 'subpasta', 'id': null, 'metadata': null},
    ]);
    final objetos = await porta().listarObjetos('uid');
    expect(recebidas.single['caminho'], '/storage/v1/object/list/backups');
    expect(jsonDecode(utf8.decode(recebidas.single['corpo']! as List<int>)),
        {'prefix': 'uid', 'limit': 1000, 'offset': 0});
    expect(objetos.single.path, 'uid/000001.dsmb');
    expect(objetos.single.tamanhoBytes, 962);
  });

  test('registrar metadado: POST no PostgREST com os campos do cliente',
      () async {
    status = 201;
    resposta = '';
    await porta().registrarMetadado(
      seq: 7,
      path: 'uid/000007.dsmb',
      tamanhoBytes: 962,
      sha256: 'a' * 64,
      formatoVersao: 1,
      appVersao: '1.0.0',
      plataforma: 'android',
    );
    final r = recebidas.single;
    expect(r['caminho'], '/rest/v1/backups_metadados');
    expect(r['prefer'], 'return=minimal');
    final corpo = jsonDecode(utf8.decode(r['corpo']! as List<int>)) as Map;
    expect(corpo.keys, containsAll(['seq', 'path', 'sha256', 'plataforma']));
    expect(corpo.containsKey('usuario_id'), isFalse,
        reason: 'o titular vem do servidor (auth.uid()), não do cliente');
  });

  test('prune: DELETE dos objetos por prefixes e dos registros por seq',
      () async {
    await porta().removerObjetos(['uid/000001.dsmb', 'uid/000002.dsmb']);
    status = 204;
    resposta = '';
    await porta().removerMetadados([1, 2]);
    expect(recebidas[0]['metodo'], 'DELETE');
    expect(jsonDecode(utf8.decode(recebidas[0]['corpo']! as List<int>)),
        {'prefixes': ['uid/000001.dsmb', 'uid/000002.dsmb']});
    expect(recebidas[1]['caminho'], '/rest/v1/backups_metadados?seq=in.(1,2)');
  });

  test('download pela rota autenticada', () async {
    resposta = 'blob';
    final bytes = await porta().baixar('uid/000001.dsmb');
    expect(recebidas.single['caminho'],
        '/storage/v1/object/authenticated/backups/uid/000001.dsmb');
    expect(utf8.decode(bytes), 'blob');
  });

  test('sem sessão, nem chama o servidor', () async {
    final semSessao = PortaArmazenamentoBackupHttp(
      url: 'http://127.0.0.1:${servidor.port}',
      chavePublicavel: 'x',
      tokenDaSessao: () => null,
    );
    await expectLater(
      semSessao.listarMetadados(),
      throwsA(isA<FalhaArmazenamentoBackup>()),
    );
    expect(recebidas, isEmpty);
  });
}
