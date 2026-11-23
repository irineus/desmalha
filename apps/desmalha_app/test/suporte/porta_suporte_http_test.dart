@TestOn('vm')
library;

// Sem testWidgets de propósito: o binding de widget troca o HttpClient.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:desmalha_app/suporte/porta_suporte.dart';
import 'package:desmalha_app/suporte/porta_suporte_http.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer servidor;
  late List<Map<String, Object?>> recebidas;
  late List<(int, String)> respostas;

  setUp(() async {
    recebidas = [];
    respostas = [];
    servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    servidor.listen((r) async {
      final corpo = await r.fold<List<int>>(<int>[], (a, b) => a..addAll(b));
      recebidas.add({
        'metodo': r.method,
        'caminho': r.uri.toString(),
        'autorizacao': r.headers.value('authorization'),
        'upsert': r.headers.value('x-upsert'),
        'prefer': r.headers.value('prefer'),
        'corpo': corpo,
      });
      final (status, texto) = respostas.removeAt(0);
      r.response
        ..statusCode = status
        ..write(texto);
      await r.response.close();
    });
  });

  tearDown(() => servidor.close(force: true));

  PortaSuporteHttp porta() => PortaSuporteHttp(
        url: 'http://127.0.0.1:${servidor.port}',
        chavePublicavel: 'chave',
        tokenDaSessao: () => 'token',
      );

  test('sobe no bucket suporte-extratos sem sobrescrever e registra o envio; '
      'o prazo vem do servidor', () async {
    respostas = [
      (200, '{"Key":"suporte-extratos/uid/x.ofx"}'),
      (201, '[{"path":"uid/x.ofx","expira_em":"2026-10-25T10:00:00+00:00"}]'),
    ];
    final r = await porta().enviar(
      path: 'uid/x.ofx',
      bytes: Uint8List.fromList([7, 8, 9]),
      motivo: 'não lido',
      bancoInformado: 'Banco X',
    );
    expect(r.expiraEm, DateTime.utc(2026, 10, 25, 10));

    final upload = recebidas[0];
    expect(upload['caminho'], '/storage/v1/object/suporte-extratos/uid/x.ofx');
    expect(upload['upsert'], 'false');
    expect(upload['autorizacao'], 'Bearer token');
    expect(upload['corpo'], [7, 8, 9]);

    final registro = recebidas[1];
    expect(registro['caminho'], '/rest/v1/envios_suporte?select=path,expira_em');
    expect(registro['prefer'], 'return=representation');
    expect(
      jsonDecode(utf8.decode(registro['corpo']! as List<int>)),
      {'path': 'uid/x.ofx', 'motivo': 'não lido', 'banco_informado': 'Banco X'},
      reason: 'o cliente não manda prazo nem instante: o servidor carimba',
    );
  });

  test('upload recusado não registra nada', () async {
    respostas = [(400, '{"statusCode":"409"}')];
    await expectLater(
      porta().enviar(path: 'uid/x.ofx', bytes: Uint8List(2), motivo: 'm'),
      throwsA(isA<FalhaEnvioSuporte>()),
    );
    expect(recebidas, hasLength(1));
  });
}
