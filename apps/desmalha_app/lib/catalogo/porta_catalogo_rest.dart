/// Implementação da [PortaCatalogoRemota] contra o PostgREST do Supabase.
///
/// De propósito NÃO usa o SDK `supabase_flutter`: a trava anti-senha mantém
/// o SDK de auth entrando no app por um arquivo só
/// (`auth/porta_auth_supabase.dart`, conferido por teste), e o catálogo não
/// precisa de nada além de um GET anônimo — a tabela `catalogo_itens` é
/// legível por `anon` via RLS, antes de qualquer login. Um `HttpClient` cru
/// mantém a superfície auditável do SDK onde ela está.
library;

import 'dart:convert';
import 'dart:io';

import 'porta_catalogo.dart';

class PortaCatalogoRest implements PortaCatalogoRemota {
  PortaCatalogoRest({required this.url, required this.chavePublicavel});

  /// URL do gateway, ex.: `https://api-dev.desmalha.app` — nunca
  /// `*.supabase.co` (ver `configuracao_supabase.dart`).
  final String url;

  /// Chave publicável (pública por construção; quem protege é o RLS).
  final String chavePublicavel;

  @override
  Future<List<Map<String, Object?>>> buscarItens() async {
    final endereco = Uri.parse(
      '$url/rest/v1/catalogo_itens?select=tipo,id,conteudo&order=tipo,id',
    );
    final cliente = HttpClient();
    try {
      final requisicao = await cliente.getUrl(endereco);
      requisicao.headers.set('apikey', chavePublicavel);
      requisicao.headers.set('Authorization', 'Bearer $chavePublicavel');
      requisicao.headers.set('Accept', 'application/json');
      final resposta = await requisicao.close();
      final corpo = await resposta.transform(utf8.decoder).join();
      if (resposta.statusCode != 200) {
        throw ExcecaoCatalogoRemoto(
          'servidor de catálogo respondeu ${resposta.statusCode}',
        );
      }
      final dado = jsonDecode(corpo);
      if (dado is! List) {
        throw ExcecaoCatalogoRemoto('resposta do catálogo não é uma lista');
      }
      return [
        for (final item in dado)
          if (item is Map<String, Object?>)
            item
          else
            throw ExcecaoCatalogoRemoto(
              'item do catálogo não é um objeto',
            ),
      ];
    } on ExcecaoCatalogoRemoto {
      rethrow;
    } on Exception catch (erro) {
      throw ExcecaoCatalogoRemoto('falha ao buscar o catálogo: $erro');
    } finally {
      cliente.close(force: true);
    }
  }
}
