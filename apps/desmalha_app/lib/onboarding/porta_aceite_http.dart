/// [PortaAceite] contra o RPC `registrar_aceite`, pelo gateway.
///
/// `POST {gateway}/rest/v1/rpc/registrar_aceite`, corpo
/// `{"p_documento": ..., "p_versao": ...}`, `Authorization: Bearer <token
/// da sessão>` — o servidor exige `authenticated` — e `apikey` com a chave
/// do TENANT. A função devolve o id do aceite (bigint): só 200 com um número
/// no corpo conta como registrado.
///
/// `HttpClient` cru, sem o SDK, como as outras portas HTTP. Este arquivo
/// está na lista de `no_supabase_outside_adapters_test`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'porta_aceite.dart';

class PortaAceiteHttp implements PortaAceite {
  PortaAceiteHttp({
    required this.url,
    required this.chavePublicavel,
    required this.tokenDaSessao,
    this.limite = const Duration(seconds: 20),
  });

  final String url;
  final String chavePublicavel;
  final String? Function() tokenDaSessao;
  final Duration limite;

  static const _semConfirmacao =
      'Não foi possível registrar o aceite agora. Confira a conexão e tente '
      'de novo.';

  @override
  Future<void> registrar({
    required String documento,
    required String versao,
  }) async {
    final token = tokenDaSessao();
    if (token == null || token.isEmpty) {
      throw const FalhaAceite('Sua sessão terminou. Entre de novo.');
    }
    final cliente = HttpClient();
    try {
      final requisicao = await cliente
          .postUrl(Uri.parse('$url/rest/v1/rpc/registrar_aceite'))
          .timeout(limite);
      requisicao.headers
        ..set('apikey', chavePublicavel)
        ..set('Authorization', 'Bearer $token')
        ..contentType = ContentType.json;
      requisicao.write(
        jsonEncode({'p_documento': documento, 'p_versao': versao}),
      );
      final resposta = await requisicao.close().timeout(limite);
      final corpo = await resposta
          .transform(utf8.decoder)
          .join()
          .timeout(limite);
      Object? dado;
      try {
        dado = jsonDecode(corpo);
      } on FormatException {
        dado = null;
      }
      if (resposta.statusCode == 200 && dado is int) return;
      // P0002: a versão não está publicada (allowlist). É o servidor
      // defendendo o registro — nunca contornar.
      if (dado is Map && dado['code'] == 'P0002') {
        throw FalhaAceite(
          'Esta versão do documento não está publicada. Atualize o app e '
          'tente de novo.',
          causa: 'HTTP ${resposta.statusCode} P0002',
        );
      }
      throw FalhaAceite(_semConfirmacao, causa: 'HTTP ${resposta.statusCode}');
    } on FalhaAceite {
      rethrow;
    } on TimeoutException catch (e) {
      throw FalhaAceite(_semConfirmacao, causa: '$e');
    } on IOException catch (e) {
      throw FalhaAceite(_semConfirmacao, causa: '$e');
    } finally {
      cliente.close(force: true);
    }
  }
}
