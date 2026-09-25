/// [PortaSuporte] em HTTP cru, pelo gateway, com o token da sessão —
/// Storage API (`/storage/v1`) e PostgREST (`/rest/v1`), como a porta do
/// backup. Este arquivo está na lista de `no_supabase_outside_adapters_test`
/// como porta própria.
///
/// O bucket só aceita INSERT na pasta do titular e não deixa ler de volta;
/// o upload manda `x-upsert: false`. O prazo de 30 dias quem carimba é o
/// servidor — o cliente só informa caminho, banco e motivo.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'porta_suporte.dart';

class PortaSuporteHttp implements PortaSuporte {
  PortaSuporteHttp({
    required this.url,
    required this.chavePublicavel,
    required this.tokenDaSessao,
    this.limite = const Duration(seconds: 60),
  });

  final String url;
  final String chavePublicavel;
  final String? Function() tokenDaSessao;
  final Duration limite;

  static const _balde = 'suporte-extratos';

  Future<({int status, List<int> corpo})> _pedir(
    String metodo,
    String caminho, {
    Object? json,
    List<int>? binario,
    Map<String, String> cabecalhos = const {},
  }) async {
    final token = tokenDaSessao();
    if (token == null || token.isEmpty) {
      throw const FalhaEnvioSuporte('Entre na sua conta para enviar.');
    }
    final cliente = HttpClient();
    try {
      final req = await cliente
          .openUrl(metodo, Uri.parse('$url$caminho'))
          .timeout(limite);
      req.headers
        ..set('apikey', chavePublicavel)
        ..set('Authorization', 'Bearer $token');
      cabecalhos.forEach(req.headers.set);
      if (json != null) {
        req.headers.contentType = ContentType.json;
        req.add(utf8.encode(jsonEncode(json)));
      } else if (binario != null) {
        req.headers.contentType = ContentType('application', 'octet-stream');
        req.add(binario);
      }
      final resp = await req.close().timeout(limite);
      final corpo = await resp
          .fold<List<int>>(<int>[], (a, b) => a..addAll(b))
          .timeout(limite);
      return (status: resp.statusCode, corpo: corpo);
    } on FalhaEnvioSuporte {
      rethrow;
    } on TimeoutException {
      throw const FalhaEnvioSuporte('O servidor não respondeu a tempo.');
    } on Exception catch (e) {
      throw FalhaEnvioSuporte('Sem conexão com o servidor ($e).');
    } finally {
      cliente.close(force: true);
    }
  }

  @override
  Future<EnvioRegistrado> enviar({
    required String path,
    required Uint8List bytes,
    required String motivo,
    String? bancoInformado,
  }) async {
    final up = await _pedir(
      'POST',
      '/storage/v1/object/$_balde/$path',
      binario: bytes,
      cabecalhos: const {'x-upsert': 'false'},
    );
    if (up.status != 200 && up.status != 201) {
      throw FalhaEnvioSuporte('O envio do arquivo falhou (HTTP ${up.status}).');
    }
    final reg = await _pedir(
      'POST',
      '/rest/v1/envios_suporte?select=path,expira_em',
      json: {
        'path': path,
        'motivo': motivo,
        'banco_informado': ?bancoInformado,
      },
      cabecalhos: const {'Prefer': 'return=representation'},
    );
    if (reg.status != 201) {
      throw FalhaEnvioSuporte(
        'O arquivo subiu, mas o registro do envio falhou (HTTP ${reg.status}). '
        'Ele será apagado em até 30 dias mesmo assim.',
      );
    }
    final linhas = jsonDecode(utf8.decode(reg.corpo));
    if (linhas is! List || linhas.isEmpty) {
      throw const FalhaEnvioSuporte('Resposta inesperada do servidor.');
    }
    final linha = linhas.first as Map<String, Object?>;
    return EnvioRegistrado(
      path: linha['path']! as String,
      expiraEm: DateTime.parse(linha['expira_em']! as String),
    );
  }
}
