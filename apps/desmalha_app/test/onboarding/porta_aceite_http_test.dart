@TestOn('vm')
library;

// Arquivo SEM testWidgets de propósito: o binding de widget substitui o
// HttpClient por um que devolve 400 a tudo, e estes testes precisam de um
// servidor de verdade no loopback para provar o contrato da rota.

import 'dart:convert';
import 'dart:io';

import 'package:desmalha_app/onboarding/porta_aceite.dart';
import 'package:desmalha_app/onboarding/porta_aceite_http.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PortaAceiteHttp — o contrato do RPC registrar_aceite', () {
    late HttpServer servidor;
    late List<Map<String, Object?>> recebidas;
    var status = 200;
    var resposta = '42';

    setUp(() async {
      recebidas = [];
      status = 200;
      resposta = '42';
      servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      servidor.listen((r) async {
        recebidas.add({
          'metodo': r.method,
          'caminho': r.uri.path,
          'apikey': r.headers.value('apikey'),
          'autorizacao': r.headers.value('authorization'),
          'corpo': jsonDecode(await utf8.decoder.bind(r).join()),
        });
        r.response
          ..statusCode = status
          ..write(resposta);
        await r.response.close();
      });
    });

    tearDown(() => servidor.close(force: true));

    PortaAceiteHttp porta({String? token = 'token-da-sessao'}) =>
        PortaAceiteHttp(
          url: 'http://127.0.0.1:${servidor.port}',
          chavePublicavel: 'chave-do-tenant',
          tokenDaSessao: () => token,
        );

    test('POST /rest/v1/rpc/registrar_aceite com documento e versão', () async {
      await porta().registrar(documento: 'termos_uso', versao: '2026-09-v1');
      expect(recebidas.single, {
        'metodo': 'POST',
        'caminho': '/rest/v1/rpc/registrar_aceite',
        'apikey': 'chave-do-tenant',
        'autorizacao': 'Bearer token-da-sessao',
        'corpo': {'p_documento': 'termos_uso', 'p_versao': '2026-09-v1'},
      });
    });

    test('versão fora da allowlist (P0002): falha dizendo isso', () async {
      status = 404;
      resposta = '{"code":"P0002","message":"versão não publicada"}';
      await expectLater(
        porta().registrar(documento: 'termos_uso', versao: '2020-01-v1'),
        throwsA(
          isA<FalhaAceite>().having(
            (f) => f.mensagem,
            'mensagem',
            contains('não está publicada'),
          ),
        ),
      );
    });

    test('200 sem o id do aceite no corpo não é confirmação', () async {
      resposta = '<html>proxy</html>';
      await expectLater(
        porta().registrar(documento: 'termos_uso', versao: '2026-09-v1'),
        throwsA(isA<FalhaAceite>()),
      );
    });

    test('sem sessão: não chama o servidor', () async {
      await expectLater(
        porta(
          token: null,
        ).registrar(documento: 'termos_uso', versao: '2026-09-v1'),
        throwsA(isA<FalhaAceite>()),
      );
      expect(recebidas, isEmpty);
    });

    test('servidor fora do ar: FalhaAceite, não exceção crua', () async {
      final url = 'http://127.0.0.1:${servidor.port}';
      await servidor.close(force: true);
      await expectLater(
        PortaAceiteHttp(
          url: url,
          chavePublicavel: 'k',
          tokenDaSessao: () => 't',
        ).registrar(documento: 'termos_uso', versao: '2026-09-v1'),
        throwsA(isA<FalhaAceite>()),
      );
    });
  });
}
