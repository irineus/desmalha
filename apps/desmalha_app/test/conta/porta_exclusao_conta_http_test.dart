@TestOn('vm')
library;

// Arquivo SEM testWidgets de propósito: o binding de widget substitui o
// HttpClient por um que devolve 400 a tudo, e estes testes precisam de um
// servidor de verdade no loopback para provar o contrato da rota.

import 'dart:convert';
import 'dart:io';

import 'package:desmalha_app/conta/porta_exclusao_conta.dart';
import 'package:desmalha_app/conta/porta_exclusao_conta_http.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PortaExclusaoContaHttp — o contrato da rota do app', () {
    late HttpServer servidor;
    late List<Map<String, Object?>> recebidas;
    var status = 200;
    var resposta = '{"ok":true,"mensagem":"Conta excluída."}';

    setUp(() async {
      recebidas = [];
      status = 200;
      resposta = '{"ok":true,"mensagem":"Conta excluída."}';
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

    PortaExclusaoContaHttp porta({String? token = 'token-da-sessao'}) =>
        PortaExclusaoContaHttp(
          url: 'http://127.0.0.1:${servidor.port}',
          chavePublicavel: 'chave-do-tenant',
          tokenDaSessao: () => token,
        );

    test(
      'POST /functions/v1/excluir-conta, chave do tenant, token da sessão',
      () async {
        await porta().excluirContaDaSessao();
        expect(recebidas.single, {
          'metodo': 'POST',
          'caminho': '/functions/v1/excluir-conta',
          'apikey': 'chave-do-tenant',
          'autorizacao': 'Bearer token-da-sessao',
          'corpo': {'acao': 'excluir'},
        });
      },
    );

    test('erro do servidor vira falha com a mensagem dele', () async {
      status = 500;
      resposta = '{"ok":false,"mensagem":"Não foi possível concluir."}';
      await expectLater(
        porta().excluirContaDaSessao(),
        throwsA(
          isA<FalhaExclusaoConta>().having(
            (f) => f.mensagem,
            'mensagem',
            'Não foi possível concluir.',
          ),
        ),
      );
    });

    test('200 sem "ok": true NÃO é confirmação', () async {
      resposta = '<html>proxy</html>';
      await expectLater(
        porta().excluirContaDaSessao(),
        throwsA(isA<FalhaExclusaoConta>()),
      );
    });

    test('sem sessão, nem chama o servidor', () async {
      await expectLater(
        porta(token: null).excluirContaDaSessao(),
        throwsA(isA<FalhaExclusaoConta>()),
      );
      expect(recebidas, isEmpty);
    });

    test('servidor fora do ar vira falha, não exclusão', () async {
      final fora = PortaExclusaoContaHttp(
        url: 'http://127.0.0.1:1',
        chavePublicavel: 'x',
        tokenDaSessao: () => 't',
      );
      await expectLater(
        fora.excluirContaDaSessao(),
        throwsA(isA<FalhaExclusaoConta>()),
      );
    });
  });
}
