/// [PortaArmazenamentoBackup] em HTTP cru, pelo gateway, com o token da
/// sessão — Storage API (`/storage/v1`) e PostgREST (`/rest/v1`).
///
/// Sem o SDK pelo mesmo motivo do catálogo e da exclusão: o SDK de auth
/// entra no app por um arquivo só. Este arquivo está na lista de
/// `no_supabase_outside_adapters_test` como porta própria.
///
/// O upload manda `x-upsert: false` e o bucket não tem mais policy de
/// UPDATE (migration `*_backups_metadados.sql`): sobrescrever é recusado
/// pelos dois lados.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'porta_armazenamento_backup.dart';

class PortaArmazenamentoBackupHttp implements PortaArmazenamentoBackup {
  PortaArmazenamentoBackupHttp({
    required this.url,
    required this.chavePublicavel,
    required this.tokenDaSessao,
    this.limite = const Duration(seconds: 60),
  });

  final String url;
  final String chavePublicavel;
  final String? Function() tokenDaSessao;
  final Duration limite;

  static const _balde = 'backups';

  Future<({int status, List<int> corpo})> _pedir(
    String metodo,
    String caminho, {
    Object? json,
    List<int>? binario,
    Map<String, String> cabecalhos = const {},
  }) async {
    final token = tokenDaSessao();
    if (token == null || token.isEmpty) {
      throw const FalhaArmazenamentoBackup('sem sessão');
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
    } on FalhaArmazenamentoBackup {
      rethrow;
    } on TimeoutException {
      throw const FalhaArmazenamentoBackup('o servidor não respondeu a tempo');
    } on Exception catch (e) {
      throw FalhaArmazenamentoBackup('sem conexão com o servidor ($e)');
    } finally {
      cliente.close(force: true);
    }
  }

  static Never _falha(String oque, ({int status, List<int> corpo}) r) {
    final texto = utf8.decode(r.corpo, allowMalformed: true);
    // O Storage devolve 400 com "statusCode":"409" para objeto existente.
    final conflito = r.status == 409 ||
        texto.contains('"409"') ||
        texto.contains('Duplicate') ||
        texto.contains('already exists') ||
        texto.contains('23505');
    throw FalhaArmazenamentoBackup(
      '$oque: HTTP ${r.status}',
      conflito: conflito,
    );
  }

  static List<Object?> _lista(List<int> corpo) {
    final v = jsonDecode(utf8.decode(corpo));
    if (v is! List) throw const FalhaArmazenamentoBackup('resposta inesperada');
    return v;
  }

  @override
  Future<List<MetadadoBackup>> listarMetadados() async {
    final r = await _pedir(
      'GET',
      '/rest/v1/backups_metadados'
          '?select=seq,path,tamanho_bytes,sha256,formato_versao&order=seq.desc',
    );
    if (r.status != 200) _falha('listar backups', r);
    return [
      for (final o in _lista(r.corpo).cast<Map<String, Object?>>())
        MetadadoBackup(
          seq: o['seq']! as int,
          path: o['path']! as String,
          tamanhoBytes: o['tamanho_bytes']! as int,
          sha256: o['sha256']! as String,
          formatoVersao: o['formato_versao']! as int,
        ),
    ];
  }

  @override
  Future<List<ObjetoArmazenado>> listarObjetos(String usuarioId) async {
    final r = await _pedir(
      'POST',
      '/storage/v1/object/list/$_balde',
      json: {'prefix': usuarioId, 'limit': 1000, 'offset': 0},
    );
    if (r.status != 200) _falha('listar arquivos', r);
    return [
      for (final o in _lista(r.corpo).cast<Map<String, Object?>>())
        if (o['id'] != null) // pasta vem sem id
          ObjetoArmazenado(
            '$usuarioId/${o['name']}',
            ((o['metadata'] as Map<String, Object?>?)?['size']) as int?,
          ),
    ];
  }

  @override
  Future<void> enviar(String path, Uint8List bytes) async {
    final r = await _pedir(
      'POST',
      '/storage/v1/object/$_balde/$path',
      binario: bytes,
      cabecalhos: const {'x-upsert': 'false'},
    );
    if (r.status != 200) _falha('enviar backup', r);
  }

  @override
  Future<Uint8List> baixar(String path) async {
    final r = await _pedir('GET', '/storage/v1/object/authenticated/$_balde/$path');
    if (r.status != 200) _falha('baixar backup', r);
    return Uint8List.fromList(r.corpo);
  }

  @override
  Future<void> removerObjetos(List<String> paths) async {
    if (paths.isEmpty) return;
    final r = await _pedir(
      'DELETE',
      '/storage/v1/object/$_balde',
      json: {'prefixes': paths},
    );
    if (r.status != 200) _falha('apagar backups antigos', r);
  }

  @override
  Future<void> registrarMetadado({
    required int seq,
    required String path,
    required int tamanhoBytes,
    required String sha256,
    required int formatoVersao,
    required String appVersao,
    required String plataforma,
  }) async {
    final r = await _pedir(
      'POST',
      '/rest/v1/backups_metadados',
      json: {
        'seq': seq,
        'path': path,
        'tamanho_bytes': tamanhoBytes,
        'sha256': sha256,
        'formato_versao': formatoVersao,
        'app_versao': appVersao,
        'plataforma': plataforma,
      },
      cabecalhos: const {'Prefer': 'return=minimal'},
    );
    if (r.status != 201 && r.status != 204) _falha('registrar backup', r);
  }

  @override
  Future<void> removerMetadados(List<int> seqs) async {
    if (seqs.isEmpty) return;
    final r = await _pedir(
      'DELETE',
      '/rest/v1/backups_metadados?seq=in.(${seqs.join(',')})',
    );
    if (r.status != 204 && r.status != 200) _falha('apagar registros antigos', r);
  }
}
