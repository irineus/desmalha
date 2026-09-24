import 'dart:typed_data';

import 'package:desmalha_app/backup/porta_armazenamento_backup.dart';

/// O bucket e a tabela, em memória, com as regras do servidor real: não
/// sobrescreve, seq única, e dá para simular o servidor que "aceita" e perde.
class ArmazenamentoFalso implements PortaArmazenamentoBackup {
  final Map<String, Uint8List> objetos = {};
  final Map<int, MetadadoBackup> metadados = {};
  final List<String> chamadas = [];

  /// O próximo `enviar` responde OK sem guardar (2xx ≠ arquivo lá).
  bool engolirProximoEnvio = false;

  /// O próximo `registrarMetadado` falha (deixa um blob órfão).
  bool falharProximoRegistro = false;

  /// Outro aparelho ocupa o caminho entre a listagem e o envio.
  bool outroAparelhoOcupaOProximoCaminho = false;

  @override
  Future<List<MetadadoBackup>> listarMetadados() async {
    chamadas.add('listarMetadados');
    return metadados.values.toList()..sort((a, b) => b.seq.compareTo(a.seq));
  }

  @override
  Future<List<ObjetoArmazenado>> listarObjetos(String usuarioId) async {
    chamadas.add('listarObjetos');
    return [
      for (final e in objetos.entries)
        if (e.key.startsWith('$usuarioId/'))
          ObjetoArmazenado(e.key, e.value.length),
    ];
  }

  @override
  Future<void> enviar(String path, Uint8List bytes) async {
    chamadas.add('enviar $path');
    if (outroAparelhoOcupaOProximoCaminho) {
      outroAparelhoOcupaOProximoCaminho = false;
      objetos[path] = Uint8List.fromList([1, 2, 3]);
    }
    if (objetos.containsKey(path)) {
      throw const FalhaArmazenamentoBackup('existe', conflito: true);
    }
    if (engolirProximoEnvio) {
      engolirProximoEnvio = false;
      return;
    }
    objetos[path] = bytes;
  }

  @override
  Future<Uint8List> baixar(String path) async {
    chamadas.add('baixar $path');
    final b = objetos[path];
    if (b == null) throw const FalhaArmazenamentoBackup('não existe');
    return b;
  }

  @override
  Future<void> removerObjetos(List<String> paths) async {
    chamadas.add('removerObjetos ${paths.join(',')}');
    for (final p in paths) {
      objetos.remove(p);
    }
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
    chamadas.add('registrarMetadado $seq');
    if (falharProximoRegistro) {
      falharProximoRegistro = false;
      throw const FalhaArmazenamentoBackup('registro falhou');
    }
    if (metadados.containsKey(seq)) {
      throw const FalhaArmazenamentoBackup('seq', conflito: true);
    }
    metadados[seq] = MetadadoBackup(
      seq: seq,
      path: path,
      tamanhoBytes: tamanhoBytes,
      sha256: sha256,
      formatoVersao: formatoVersao,
    );
  }

  @override
  Future<void> removerMetadados(List<int> seqs) async {
    chamadas.add('removerMetadados ${seqs.join(',')}');
    for (final s in seqs) {
      metadados.remove(s);
    }
  }
}
