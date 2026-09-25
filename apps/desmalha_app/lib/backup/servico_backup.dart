/// A ordem do backup, isolada da rede e do banco (testável com portas
/// falsas) — especificação da seção 6 da revisão local-first:
///
/// 1. selar com a chave-mestra e o cabeçalho do código CONFIRMADO (sem ele,
///    não há backup — falha visível);
/// 2. upload em `<uid>/<seq>.dsmb`, seq monotônica, NUNCA sobrescrevendo;
/// 3. conferir que o objeto está lá, do tamanho enviado (2xx não é prova);
/// 4. registrar em `backups_metadados`;
/// 5. prune: manter os 3 mais recentes; apagar primeiro os OBJETOS, depois
///    os registros; varrer blob órfão de um registro que falhou antes.
///
/// A restauração baixa o mais recente, confere o sha256 do ciphertext, abre
/// com a mestra (AEAD) e valida o payload (hash, contagens, versão) — três
/// camadas de integridade — antes de entregar qualquer documento.
library;

import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:desmalha_core/desmalha_core.dart';

import 'chaves_backup.dart';
import 'porta_armazenamento_backup.dart';

/// Fonte e destino dos documentos lógicos do banco local.
abstract interface class FonteDocumentosBackup {
  Future<int> versaoDoSchemaLocal();
  Future<List<DocumentoBackup>> exportar();
  Future<void> importar(List<DocumentoBackup> documentos);
}

class ResultadoBackup {
  const ResultadoBackup({
    required this.seq,
    required this.tamanhoBytes,
    required this.sha256,
    required this.hashConteudo,
    required this.removidos,
  });
  final int seq;

  /// `hash_conteudo` dos documentos deste backup — o "nada mudou" do
  /// próximo automático compara com ele.
  final String hashConteudo;
  final int tamanhoBytes;
  final String sha256;

  /// Caminhos apagados pelo prune (antigos além dos 3 e órfãos).
  final List<String> removidos;
}

/// O backup não foi feito — e o motivo vai para a tela.
class FalhaBackup implements Exception {
  const FalhaBackup(this.mensagem);
  final String mensagem;
  @override
  String toString() => 'FalhaBackup: $mensagem';
}

/// Os backups do servidor foram feitos com outra chave (aparelho novo que
/// começou do zero): o backup não liga até a pessoa restaurar com o código
/// antigo ou confirmar o descarte (decisão 10 do owner).
class FalhaBackupsAntigos extends FalhaBackup {
  const FalhaBackupsAntigos()
      : super(
          'Seus backups na nuvem foram feitos com outro código de '
          'recuperação. O backup fica desligado até você restaurar com '
          'aquele código ou confirmar que quer descartá-los.',
        );
}

class ServicoBackup {
  ServicoBackup({
    required this.porta,
    required this.chaves,
    required this.fonte,
    required this.usuarioId,
    required this.appVersao,
    String? plataforma,
    DateTime Function()? relogio,
    this.manter = 3,
  }) : plataforma = plataforma ?? (Platform.isIOS ? 'ios' : 'android'),
       _relogio = relogio ?? DateTime.now;

  final PortaArmazenamentoBackup porta;
  final ChavesBackup chaves;
  final FonteDocumentosBackup fonte;

  /// Titular da sessão (`auth.uid()`), ou `null` sem sessão.
  final String? Function() usuarioId;
  final String appVersao;
  final String plataforma;
  final DateTime Function() _relogio;
  final int manter;

  static String caminhoDe(String usuarioId, int seq) =>
      '$usuarioId/${seq.toString().padLeft(6, '0')}.dsmb';

  /// A seq de um caminho `<uid>/<seq>.dsmb`, ou `null` se não é desse jeito.
  static int? seqDoCaminho(String caminho) {
    final m = RegExp(r'/(\d+)\.dsmb$').firstMatch(caminho);
    return m == null ? null : int.parse(m.group(1)!);
  }

  /// Faz o backup. Com [pularSeConteudoFor] igual ao hash atual dos
  /// documentos, não faz nada e devolve `null` — antes de qualquer rede.
  Future<ResultadoBackup?> fazerBackup({String? pularSeConteudoFor}) async {
    final uid = usuarioId();
    if (uid == null) {
      throw const FalhaBackup('Entre na sua conta para fazer backup.');
    }

    final ChavesParaSelar paraSelar;
    try {
      paraSelar = await chaves.chavesParaSelar();
    } on ChavesBackupException catch (e) {
      throw FalhaBackup(e.mensagem);
    }
    await _conferirVinculo(paraSelar.chaveMestra);

    // A próxima seq olha registros E objetos: um upload cujo registro falhou
    // deixa um blob órfão, e calcular só pelos registros reapontaria para o
    // caminho ocupado — o backup ficaria preso em "conflito" para sempre.
    final documentos = await fonte.exportar();
    final hashConteudo = await hashDoConteudo(documentos);
    if (pularSeConteudoFor != null && hashConteudo == pularSeConteudoFor) {
      return null;
    }

    final existentes = await porta.listarMetadados();
    final objetosAntes = await porta.listarObjetos(uid);
    final seqsUsadas = [
      for (final m in existentes) m.seq,
      for (final o in objetosAntes) ?seqDoCaminho(o.path),
    ];
    final seq = seqsUsadas.isEmpty
        ? 1
        : seqsUsadas.reduce((a, b) => a > b ? a : b) + 1;
    final path = caminhoDe(uid, seq);

    final payload = await serializarPayload(
      documentos: documentos,
      appVersao: appVersao,
      schemaLocalVersao: await fonte.versaoDoSchemaLocal(),
      geradoEm: _relogio(),
      seq: seq,
      plataforma: plataforma,
    );
    final dsmb = await selarDsmb(
      cabecalho: paraSelar.cabecalho,
      chaveMestra: paraSelar.chaveMestra,
      conteudo: payload,
    );
    final sha = await _sha256(dsmb);

    try {
      await porta.enviar(path, dsmb);
    } on FalhaArmazenamentoBackup catch (e) {
      throw FalhaBackup(
        e.conflito
            ? 'Outro aparelho fez um backup ao mesmo tempo. Tente de novo.'
            : 'O envio do backup falhou: ${e.mensagem}',
      );
    }

    // 2xx diz que o pedido foi aceito, não que o arquivo está lá inteiro.
    final objetos = await porta.listarObjetos(uid);
    final enviado = objetos.where((o) => o.path == path).firstOrNull;
    if (enviado == null ||
        (enviado.tamanhoBytes != null && enviado.tamanhoBytes != dsmb.length)) {
      throw const FalhaBackup(
        'O servidor aceitou o envio, mas o arquivo não aparece com o tamanho '
        'enviado. O backup NÃO foi dado como feito.',
      );
    }

    await porta.registrarMetadado(
      seq: seq,
      path: path,
      tamanhoBytes: dsmb.length,
      sha256: sha,
      formatoVersao: formatoBackupAtual,
      appVersao: appVersao,
      plataforma: plataforma,
    );

    final removidos = await _prune(uid, objetos);
    return ResultadoBackup(
      seq: seq,
      tamanhoBytes: dsmb.length,
      sha256: sha,
      hashConteudo: hashConteudo,
      removidos: removidos,
    );
  }

  /// Mantém os [manter] mais recentes. Objeto antes de registro: registro
  /// sem objeto se refaz no próximo prune; objeto sem registro, também —
  /// mas o contrário (registro apagado com blob vivo) esconderia dado.
  Future<List<String>> _prune(
    String uid,
    List<ObjetoArmazenado> objetos,
  ) async {
    final metas = await porta.listarMetadados()
      ..sort((a, b) => b.seq.compareTo(a.seq));
    final mantidos = metas.take(manter).toList();
    final antigos = metas.skip(manter).toList();
    final caminhosMantidos = {for (final m in mantidos) m.path};
    final aApagar = {
      for (final m in antigos) m.path,
      // Órfão: blob sem registro (o registro falhou depois do upload).
      for (final o in objetos)
        if (!caminhosMantidos.contains(o.path) &&
            !metas.any((m) => m.path == o.path))
          o.path,
    }.toList()..sort();
    if (aApagar.isEmpty) return const [];
    await porta.removerObjetos(aApagar);
    if (antigos.isNotEmpty) {
      await porta.removerMetadados([for (final m in antigos) m.seq]);
    }
    return aApagar;
  }

  /// Antes do primeiro backup de uma mestra: se o servidor tem backups, o
  /// mais recente precisa abrir com ela — senão são de outro código, e
  /// sobrescrevê-los em silêncio (o prune guarda só 3) apagaria o que só o
  /// código antigo abre.
  Future<void> _conferirVinculo(List<int> chaveMestra) async {
    if (await chaves.vinculadoAosBackups()) return;
    final metas = await porta.listarMetadados();
    if (metas.isNotEmpty) {
      final bytes = await _baixarUltimo(metas);
      try {
        await abrirDsmbComChaveMestra(bytes, chaveMestra);
      } on ChaveDeBackupIncorretaException {
        throw const FalhaBackupsAntigos();
      }
    }
    await chaves.vincularAosBackups();
  }

  /// "Descartar os backups antigos, que ninguém mais consegue abrir":
  /// liga o backup com a chave deste aparelho. Os antigos saem pelo prune.
  Future<void> descartarBackupsAntigos() async {
    try {
      await chaves.vincularAosBackups();
    } on ChavesBackupException catch (e) {
      throw FalhaBackup(e.mensagem);
    }
  }

  /// Aparelho novo: abre o backup mais recente com o [codigo] de
  /// recuperação, valida, SUBSTITUI o banco local e passa a usar a chave
  /// daquele backup — os próximos seguem abrindo com o mesmo código, em
  /// Android ou iOS. Código errado não toca em nada.
  Future<ConteudoBackup> restaurarComCodigo(String codigo) async {
    final canonico = normalizarCodigoRecuperacao(codigo);
    if (canonico == null) {
      throw const FalhaBackup(
        'Esse código não tem o formato de um código de recuperação. '
        'Confira os grupos.',
      );
    }
    final bytes = await _baixarUltimo(await porta.listarMetadados());
    final ({Uint8List conteudo, Uint8List chaveMestra}) aberto;
    final ConteudoBackup conteudo;
    try {
      aberto = await abrirDsmbComCodigo(bytes, canonico);
      conteudo = await lerPayload(aberto.conteudo);
    } on ChaveDeBackupIncorretaException {
      throw const FalhaBackup(
        'Esse código não abre o seu backup. Confira os grupos e tente de '
        'novo. Nada foi alterado.',
      );
    } on BackupDeVersaoFuturaException catch (e) {
      throw FalhaBackup(e.mensagem);
    } on BackupInvalidoException catch (e) {
      throw FalhaBackup('Backup inválido: ${e.mensagem}');
    }
    await fonte.importar(conteudo.documentos);
    try {
      await chaves.adotarChaveMestra(
        aberto.chaveMestra,
        CabecalhoChave.deBytes(bytes),
      );
      await chaves.vincularAosBackups();
    } on ChavesBackupException catch (e) {
      throw FalhaBackup(e.mensagem);
    }
    return conteudo;
  }

  Future<Uint8List> _baixarUltimo(List<MetadadoBackup> metas) async {
    if (metas.isEmpty) throw const FalhaBackup('Nenhum backup no servidor.');
    final ultimo = metas.reduce((a, b) => a.seq > b.seq ? a : b);
    final bytes = await porta.baixar(ultimo.path);
    if (await _sha256(bytes) != ultimo.sha256) {
      throw const FalhaBackup(
        'O arquivo baixado não confere com o registrado: backup corrompido no '
        'caminho. Nada foi restaurado.',
      );
    }
    return bytes;
  }

  /// Baixa e valida o backup mais recente. Não toca no banco: devolve o
  /// conteúdo para quem decide restaurar.
  Future<ConteudoBackup> baixarMaisRecente() async {
    final bytes = await _baixarUltimo(await porta.listarMetadados());
    final paraSelar = await chaves.chavesParaSelar();
    try {
      return await lerPayload(
        await abrirDsmbComChaveMestra(bytes, paraSelar.chaveMestra),
      );
    } on ChaveDeBackupIncorretaException catch (e) {
      throw FalhaBackup(e.mensagem);
    } on BackupDeVersaoFuturaException catch (e) {
      throw FalhaBackup(e.mensagem);
    } on BackupInvalidoException catch (e) {
      throw FalhaBackup('Backup inválido: ${e.mensagem}');
    }
  }

  /// Restaura o mais recente no banco local (substitui o conteúdo).
  Future<ConteudoBackup> restaurarMaisRecente() async {
    final conteudo = await baixarMaisRecente();
    await fonte.importar(conteudo.documentos);
    return conteudo;
  }

  static Future<String> _sha256(List<int> bytes) => sha256Hex(bytes);
}
