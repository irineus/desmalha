/// O que o aparelho sabe do próprio backup — tabela `backup_estado` (uma
/// linha, id = 1).
///
/// Semântica das colunas (fixada aqui, set/2026): `ultima_seq`,
/// `ultimo_hash`, `ultimo_em`, `tamanho_bytes` e `formato_versao` descrevem o
/// ÚLTIMO BACKUP BEM-SUCEDIDO; `resultado` e `erro_detalhe`, a ÚLTIMA
/// TENTATIVA. Uma falha não apaga a lembrança do último sucesso — é dela que
/// sai o aviso "7 dias sem backup".
library;

import '../dados/banco.dart';

class EstadoBackup {
  const EstadoBackup({
    this.ultimaSeq,
    this.ultimoHashConteudo,
    this.ultimoSucessoEm,
    this.tamanhoBytes,
    this.resultado,
    this.erroDetalhe,
  });

  final int? ultimaSeq;

  /// `hash_conteudo` dos documentos do último backup bem-sucedido: igual ao
  /// atual = nada mudou, backup automático não roda.
  final String? ultimoHashConteudo;
  final DateTime? ultimoSucessoEm;
  final int? tamanhoBytes;

  /// `ok`, `falha` ou `pendente` — da última tentativa.
  final String? resultado;
  final String? erroDetalhe;

  static const vazio = EstadoBackup();
}

/// Onde o estado mora. Interface para os testes de widget usarem memória.
abstract interface class RepositorioEstadoBackup {
  Future<EstadoBackup> ler();
  Future<void> registrarSucesso({
    required int seq,
    required String hashConteudo,
    required DateTime em,
    required int tamanhoBytes,
    required int formatoVersao,
  });
  Future<void> registrarFalha(String detalhe);
}

class RepositorioEstadoBackupDrift implements RepositorioEstadoBackup {
  RepositorioEstadoBackupDrift(this.banco);
  final BancoLocal banco;

  @override
  Future<EstadoBackup> ler() async {
    final linha = await (banco.select(
      banco.backupEstado,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    if (linha == null) return EstadoBackup.vazio;
    return EstadoBackup(
      ultimaSeq: linha.ultimaSeq,
      ultimoHashConteudo: linha.ultimoHash,
      ultimoSucessoEm: linha.ultimoEm == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(linha.ultimoEm!, isUtc: true),
      tamanhoBytes: linha.tamanhoBytes,
      resultado: linha.resultado,
      erroDetalhe: linha.erroDetalhe,
    );
  }

  @override
  Future<void> registrarSucesso({
    required int seq,
    required String hashConteudo,
    required DateTime em,
    required int tamanhoBytes,
    required int formatoVersao,
  }) => banco.customStatement(
    'INSERT INTO backup_estado (id, ultima_seq, ultimo_hash, ultimo_em, '
    "formato_versao, tamanho_bytes, resultado, erro_detalhe) VALUES (1, ?, ?, ?, ?, ?, 'ok', NULL) "
    'ON CONFLICT(id) DO UPDATE SET ultima_seq = excluded.ultima_seq, '
    'ultimo_hash = excluded.ultimo_hash, ultimo_em = excluded.ultimo_em, '
    'formato_versao = excluded.formato_versao, '
    'tamanho_bytes = excluded.tamanho_bytes, resultado = excluded.resultado, '
    'erro_detalhe = NULL',
    [
      seq,
      hashConteudo,
      em.toUtc().millisecondsSinceEpoch,
      formatoVersao,
      tamanhoBytes,
    ],
  );

  @override
  Future<void> registrarFalha(String detalhe) => banco.customStatement(
    "INSERT INTO backup_estado (id, resultado, erro_detalhe) VALUES (1, 'falha', ?) "
    "ON CONFLICT(id) DO UPDATE SET resultado = 'falha', "
    'erro_detalhe = excluded.erro_detalhe',
    [detalhe],
  );
}

/// Para testes e para a tela antes do banco abrir.
class RepositorioEstadoBackupMemoria implements RepositorioEstadoBackup {
  EstadoBackup estado = EstadoBackup.vazio;

  @override
  Future<EstadoBackup> ler() async => estado;

  @override
  Future<void> registrarSucesso({
    required int seq,
    required String hashConteudo,
    required DateTime em,
    required int tamanhoBytes,
    required int formatoVersao,
  }) async => estado = EstadoBackup(
    ultimaSeq: seq,
    ultimoHashConteudo: hashConteudo,
    ultimoSucessoEm: em.toUtc(),
    tamanhoBytes: tamanhoBytes,
    resultado: 'ok',
  );

  @override
  Future<void> registrarFalha(String detalhe) async => estado = EstadoBackup(
    ultimaSeq: estado.ultimaSeq,
    ultimoHashConteudo: estado.ultimoHashConteudo,
    ultimoSucessoEm: estado.ultimoSucessoEm,
    tamanhoBytes: estado.tamanhoBytes,
    resultado: 'falha',
    erroDetalhe: detalhe,
  );
}
