/// O que o backup precisa do servidor: o bucket `backups` e a tabela
/// `backups_metadados`, ambos restritos por RLS ao próprio titular.
///
/// Porta separada da auth pelo mesmo motivo da exclusão de conta: o SDK de
/// auth entra no app por um arquivo só. A implementação é HTTP cru pelo
/// gateway (`porta_armazenamento_backup_http.dart`).
library;

import 'dart:typed_data';

/// Um backup registrado no servidor.
class MetadadoBackup {
  const MetadadoBackup({
    required this.seq,
    required this.path,
    required this.tamanhoBytes,
    required this.sha256,
    required this.formatoVersao,
  });

  final int seq;
  final String path;
  final int tamanhoBytes;

  /// SHA-256 (hex) do CIPHERTEXT — pega corrupção em trânsito/armazenamento.
  final String sha256;
  final int formatoVersao;
}

/// Um objeto no prefixo do titular no bucket.
class ObjetoArmazenado {
  const ObjetoArmazenado(this.path, this.tamanhoBytes);
  final String path;
  final int? tamanhoBytes;
}

/// O servidor recusou ou não confirmou uma operação do backup.
class FalhaArmazenamentoBackup implements Exception {
  const FalhaArmazenamentoBackup(this.mensagem, {this.conflito = false});
  final String mensagem;

  /// O objeto/seq já existe — outro aparelho chegou antes. Nunca sobrescrever.
  final bool conflito;

  @override
  String toString() => 'FalhaArmazenamentoBackup: $mensagem';
}

abstract interface class PortaArmazenamentoBackup {
  /// Os metadados do titular, da seq mais alta para a mais baixa.
  Future<List<MetadadoBackup>> listarMetadados();

  /// Os objetos no prefixo `<uid>/` do bucket.
  Future<List<ObjetoArmazenado>> listarObjetos(String usuarioId);

  /// Envia SEM sobrescrever: caminho existente é [FalhaArmazenamentoBackup]
  /// com `conflito: true`.
  Future<void> enviar(String path, Uint8List bytes);

  Future<Uint8List> baixar(String path);

  Future<void> removerObjetos(List<String> paths);

  Future<void> registrarMetadado({
    required int seq,
    required String path,
    required int tamanhoBytes,
    required String sha256,
    required int formatoVersao,
    required String appVersao,
    required String plataforma,
  });

  Future<void> removerMetadados(List<int> seqs);
}
