/// [PortaExclusaoConta] contra a edge function `excluir-conta`, pelo gateway.
///
/// Rota do app do contrato da função (`supabase/functions/excluir-conta`):
/// `POST {gateway}/functions/v1/excluir-conta`, corpo `{"acao":"excluir"}`,
/// `Authorization: Bearer <token da sessão>` — a sessão já prova de quem é a
/// conta. `apikey` leva a chave do TENANT, que o gateway troca pela do
/// destino.
///
/// `HttpClient` cru, sem o SDK: pelo mesmo motivo do catálogo REST — o SDK
/// entra no app por um arquivo só. Este arquivo está na lista de
/// `no_supabase_outside_adapters_test` como porta própria.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'porta_exclusao_conta.dart';

class PortaExclusaoContaHttp implements PortaExclusaoConta {
  PortaExclusaoContaHttp({
    required this.url,
    required this.chavePublicavel,
    required this.tokenDaSessao,
    this.limite = const Duration(seconds: 60),
  });

  /// URL do gateway (ver `configuracao_supabase.dart`).
  final String url;

  /// Chave pública do tenant.
  final String chavePublicavel;

  /// Token de acesso da sessão em curso, ou `null` sem sessão.
  final String? Function() tokenDaSessao;

  /// A exclusão apaga arquivos e percorre pastas no servidor: mais lenta que
  /// uma leitura, mas finita.
  final Duration limite;

  static const _semConfirmacao =
      'Não foi possível confirmar a exclusão agora. Nada foi dado como '
      'excluído. Tente de novo em alguns minutos.';

  @override
  Future<void> excluirContaDaSessao() async {
    final token = tokenDaSessao();
    if (token == null || token.isEmpty) {
      throw const FalhaExclusaoConta('Sua sessão terminou. Entre de novo.');
    }
    final cliente = HttpClient();
    try {
      final requisicao = await cliente
          .postUrl(Uri.parse('$url/functions/v1/excluir-conta'))
          .timeout(limite);
      requisicao.headers
        ..set('apikey', chavePublicavel)
        ..set('Authorization', 'Bearer $token')
        ..contentType = ContentType.json;
      requisicao.write(jsonEncode({'acao': 'excluir'}));
      final resposta = await requisicao.close().timeout(limite);
      final corpo = await resposta
          .transform(utf8.decoder)
          .join()
          .timeout(limite);
      Map<String, Object?>? dado;
      try {
        final decodificado = jsonDecode(corpo);
        if (decodificado is Map<String, Object?>) dado = decodificado;
      } on FormatException {
        dado = null;
      }
      // Excluída só com as DUAS confirmações: 200 e `ok: true`. Um 200 sem o
      // corpo esperado (gateway, proxy, página de erro) não é confirmação.
      if (resposta.statusCode == 200 && dado?['ok'] == true) return;
      final mensagem = dado?['mensagem'];
      throw FalhaExclusaoConta(
        mensagem is String && mensagem.isNotEmpty ? mensagem : _semConfirmacao,
        causa: 'HTTP ${resposta.statusCode}',
      );
    } on FalhaExclusaoConta {
      rethrow;
    } on TimeoutException catch (erro) {
      throw FalhaExclusaoConta(_semConfirmacao, causa: erro);
    } on Exception catch (erro) {
      throw FalhaExclusaoConta(
        'Não foi possível falar com o servidor. Verifique sua conexão. '
        'Nada foi dado como excluído.',
        causa: erro,
      );
    } finally {
      cliente.close(force: true);
    }
  }
}
