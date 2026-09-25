/// As chaves do backup no aparelho: a chave-mestra e o cabeçalho que a
/// embrulha com o código de recuperação.
///
/// - **Chave-mestra** (32 bytes): gerada uma vez, no cofre do sistema
///   (Keystore/Keychain), nunca transmitida. Cifra o conteúdo de todo backup.
///   Mesma regra da chave do banco: NUNCA regenerada em silêncio — mestra
///   nova tornaria ilegíveis todos os backups já enviados.
/// - **Cabeçalho de chave** (108 bytes do `.dsmb`): a mestra embrulhada pela
///   KEK do código de recuperação. Só existe DEPOIS que a pessoa confirmou o
///   código. Sem ele o backup não liga — falha visível, não backup que
///   ninguém conseguiria abrir em outro aparelho.
///
/// - **Vínculo**: a impressão da mestra cujos backups estão no servidor.
///   Aparelho novo que começou do zero tem mestra própria, e os backups
///   antigos não abrem com ela: o backup automático fica desligado até a
///   pessoa restaurar com o código antigo ou confirmar que descarta os
///   antigos (decisão 10 do owner).
///
/// - **Verificador de grupos**: SHA-256 salgado de cada grupo do código,
///   para o lembrete de 90 dias conferir 2 grupos sem o código guardado.
///   Fica só no cofre, onde a própria chave-mestra já mora: quem lê o cofre
///   não ganha nada com ele. Nunca vai para o backup.
///
/// O código em si NUNCA é guardado: é mostrado uma vez e esquecido. Guardá-lo
/// no aparelho não protegeria contra a perda do aparelho, que é exatamente o
/// caso para o qual ele existe.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:desmalha_core/desmalha_core.dart';

import '../dados/chave_banco.dart';

/// Falha das chaves do backup. Nada é regravado em cima de valor estranho.
class ChavesBackupException implements Exception {
  const ChavesBackupException(this.mensagem);
  final String mensagem;
  @override
  String toString() => 'ChavesBackupException: $mensagem';
}

/// O que o backup precisa para selar: a mestra e o cabeçalho que é dela.
class ChavesParaSelar {
  const ChavesParaSelar(this.chaveMestra, this.cabecalho);
  final Uint8List chaveMestra;
  final CabecalhoChave cabecalho;
}

class ChavesBackup {
  ChavesBackup({CofreSeguro? cofre, Random? aleatorio})
    : _cofre = cofre ?? const CofreSeguroDoSistema(),
      _aleatorio = aleatorio ?? Random.secure();

  static const campoMestra = 'desmalha_backup_chave_mestra_v1';
  static const campoCabecalho = 'desmalha_backup_cabecalho_chave_v1';
  static const campoImpressao = 'desmalha_backup_impressao_mestra_v1';
  static const campoVinculo = 'desmalha_backup_vinculo_v1';
  static const campoGrupos = 'desmalha_codigo_grupos_v1';
  static const campoConferidoEm = 'desmalha_codigo_conferido_em_v1';

  static final _hex64 = RegExp(r'^[0-9a-f]{64}$');

  final CofreSeguro _cofre;
  final Random _aleatorio;

  /// A chave-mestra: lida do cofre ou criada (uma vez) e conferida.
  /// Apaga mestra, cabeçalho e impressão deste aparelho — só quando os
  /// dados locais de OUTRA conta são apagados (card "Dados locais pertencem
  /// à conta que os criou"). Confere que sumiram: uma mestra que sobrevive
  /// selaria os backups da conta nova com a chave da conta antiga.
  Future<void> esquecer() async {
    for (final campo in [
      campoMestra,
      campoCabecalho,
      campoImpressao,
      campoVinculo,
      campoGrupos,
      campoConferidoEm,
    ]) {
      await _cofre.apagar(campo);
      if (await _cofre.ler(campo) != null) {
        throw ChavesBackupException('o cofre do sistema não apagou "$campo"');
      }
    }
  }

  Future<Uint8List> obterOuCriarChaveMestra() async {
    final existente = await _cofre.ler(campoMestra);
    if (existente != null) {
      if (!_hex64.hasMatch(existente)) {
        throw const ChavesBackupException(
          'o cofre do sistema devolveu uma chave-mestra de backup em formato '
          'inválido. Nada foi regravado — uma mestra nova deixaria os '
          'backups já enviados ilegíveis.',
        );
      }
      return _deHex(existente);
    }
    final nova = List<int>.generate(32, (_) => _aleatorio.nextInt(256));
    final hex = _paraHex(nova);
    await _cofre.gravar(campoMestra, hex);
    if (await _cofre.ler(campoMestra) != hex) {
      throw const ChavesBackupException(
        'o cofre do sistema não confirmou a gravação da chave-mestra de '
        'backup. Nenhum backup será feito com uma chave que pode sumir.',
      );
    }
    return Uint8List.fromList(nova);
  }

  /// Grava o verificador dos grupos de [codigoCanonico] e marca a
  /// conferência em [agora] — ao confirmar, ao restaurar e ao conferir o
  /// código completo.
  Future<void> registrarVerificador(
    String codigoCanonico,
    DateTime agora,
  ) async {
    final sal = List<int>.generate(16, (_) => _aleatorio.nextInt(256));
    final grupos = codigoCanonico.split('-');
    final json = jsonEncode({
      'sal': base64.encode(sal),
      'grupos': [for (final g in grupos) await _hashGrupo(sal, g)],
    });
    await _cofre.gravar(campoGrupos, json);
    await registrarConferencia(agora);
  }

  /// A última conferência (ou dispensa) do lembrete, ou `null`.
  Future<DateTime?> codigoConferidoEm() async {
    final v = await _cofre.ler(campoConferidoEm);
    final ms = v == null ? null : int.tryParse(v);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Conferiu, dispensou ("agora não") ou ganhou a data inicial: o
  /// lembrete volta 90 dias depois de [agora].
  Future<void> registrarConferencia(DateTime agora) =>
      _cofre.gravar(campoConferidoEm, '${agora.millisecondsSinceEpoch}');

  /// Confere os grupos digitados ([grupos]: índice 0..4 → texto). `null`
  /// quando o aparelho não tem verificador (código confirmado antes desta
  /// regra) — aí a conferência é pelo código completo.
  Future<bool?> conferirGrupos(Map<int, String> grupos) async {
    final json = await _cofre.ler(campoGrupos);
    if (json == null) return null;
    final dados = jsonDecode(json) as Map<String, Object?>;
    final sal = base64.decode(dados['sal']! as String);
    final esperados = (dados['grupos']! as List<Object?>).cast<String>();
    for (final e in grupos.entries) {
      final normal = normalizarGrupoRecuperacao(e.value);
      if (normal == null ||
          e.key < 0 ||
          e.key >= esperados.length ||
          await _hashGrupo(sal, normal) != esperados[e.key]) {
        return false;
      }
    }
    return true;
  }

  /// Conferência pelo código INTEIRO — para quem confirmou antes do
  /// verificador de grupos existir. Abre o cabeçalho com ele (Argon2id) e
  /// compara com a mestra; se confere, grava o verificador.
  Future<bool> conferirCodigoCompleto(String codigo, DateTime agora) async {
    final canonico = normalizarCodigoRecuperacao(codigo);
    if (canonico == null) return false;
    final paraSelar = await chavesParaSelar();
    final Uint8List aberta;
    try {
      aberta = await paraSelar.cabecalho.chaveMestraPeloCodigo(canonico);
    } on ChaveDeBackupIncorretaException {
      return false;
    }
    if (await impressaoDaChaveMestra(aberta) !=
        await impressaoDaChaveMestra(paraSelar.chaveMestra)) {
      return false;
    }
    await registrarVerificador(canonico, agora);
    return true;
  }

  static Future<String> _hashGrupo(List<int> sal, String grupo) =>
      sha256Hex([...sal, ...utf8.encode(grupo)]);

  /// `true` quando há código de recuperação CONFIRMADO para a mestra atual.
  Future<bool> codigoConfirmado() async {
    try {
      await chavesParaSelar();
      return true;
    } on ChavesBackupException {
      return false;
    }
  }

  /// Chamado depois que a pessoa redigitou os grupos sorteados: embrulha a
  /// mestra com o [codigoCanonico] (Argon2id — alguns segundos, em primeiro
  /// plano) e guarda o cabeçalho, conferindo a gravação.
  Future<void> confirmarCodigo(
    String codigoCanonico, {
    DateTime? agora,
  }) async {
    if (normalizarCodigoRecuperacao(codigoCanonico) != codigoCanonico) {
      throw ArgumentError('código fora do formato canônico');
    }
    final mestra = await obterOuCriarChaveMestra();
    final cabecalho = await embrulharChaveMestra(
      chaveMestra: mestra,
      codigo: codigoCanonico,
      aleatorio: _aleatorio,
    );
    final cabecalhoB64 = base64.encode(cabecalho.bytes);
    final impressao = await impressaoDaChaveMestra(mestra);
    await _cofre.gravar(campoCabecalho, cabecalhoB64);
    await _cofre.gravar(campoImpressao, impressao);
    if (await _cofre.ler(campoCabecalho) != cabecalhoB64 ||
        await _cofre.ler(campoImpressao) != impressao) {
      throw const ChavesBackupException(
        'o cofre do sistema não confirmou a gravação do código de '
        'recuperação. Confirme o código de novo.',
      );
    }
    await registrarVerificador(codigoCanonico, agora ?? DateTime.now());
  }

  /// Os backups do servidor foram feitos com a mestra deste aparelho (ou a
  /// pessoa confirmou descartar os que não foram).
  Future<bool> vinculadoAosBackups() async {
    final vinculo = await _cofre.ler(campoVinculo);
    return vinculo != null && vinculo == await _cofre.ler(campoImpressao);
  }

  /// Marca a mestra atual como a dos backups do servidor — depois de
  /// conferir que o último abre com ela, de restaurar com o código, ou da
  /// confirmação de descarte.
  Future<void> vincularAosBackups() async {
    final impressao = await _cofre.ler(campoImpressao);
    if (impressao == null) {
      throw const ChavesBackupException(
        'código de recuperação ainda não confirmado — nada a vincular',
      );
    }
    await _cofre.gravar(campoVinculo, impressao);
    if (await _cofre.ler(campoVinculo) != impressao) {
      throw const ChavesBackupException(
        'o cofre do sistema não confirmou a gravação do vínculo do backup',
      );
    }
  }

  /// Aparelho novo restaurando com o código: guarda a [chaveMestra] aberta
  /// pelo código e o [cabecalho] do backup (que já a embrulha com aquele
  /// código), no lugar da mestra local — que não selou nada, porque o
  /// backup não liga sem vínculo.
  ///
  /// Recusa trocar uma mestra já vinculada aos backups por outra: isso
  /// deixaria os backups do servidor sem chave neste aparelho.
  Future<void> adotarChaveMestra(
    Uint8List chaveMestra,
    CabecalhoChave cabecalho,
  ) async {
    final nova = await impressaoDaChaveMestra(chaveMestra);
    if (await vinculadoAosBackups() &&
        await _cofre.ler(campoImpressao) != nova) {
      throw const ChavesBackupException(
        'este aparelho já está vinculado a outros backups; nada foi trocado',
      );
    }
    final hex = _paraHex(chaveMestra);
    final cabecalhoB64 = base64.encode(cabecalho.bytes);
    await _cofre.gravar(campoMestra, hex);
    await _cofre.gravar(campoCabecalho, cabecalhoB64);
    await _cofre.gravar(campoImpressao, nova);
    if (await _cofre.ler(campoMestra) != hex ||
        await _cofre.ler(campoCabecalho) != cabecalhoB64 ||
        await _cofre.ler(campoImpressao) != nova) {
      throw const ChavesBackupException(
        'o cofre do sistema não confirmou a gravação da chave restaurada',
      );
    }
  }

  /// A mestra e o cabeçalho, conferidos um contra o outro.
  ///
  /// Lança [ChavesBackupException] se não há código confirmado, ou se o
  /// cabeçalho guardado foi feito para OUTRA mestra — um backup selado assim
  /// abriria neste aparelho e nunca pelo código, que é justamente o caminho
  /// que importa quando o aparelho se perde.
  Future<ChavesParaSelar> chavesParaSelar() async {
    final cabecalhoB64 = await _cofre.ler(campoCabecalho);
    final impressao = await _cofre.ler(campoImpressao);
    if (cabecalhoB64 == null || impressao == null) {
      throw const ChavesBackupException(
        'código de recuperação ainda não confirmado — o backup automático '
        'fica desligado até isso',
      );
    }
    final mestra = await obterOuCriarChaveMestra();
    if (await impressaoDaChaveMestra(mestra) != impressao) {
      throw const ChavesBackupException(
        'o código de recuperação confirmado não corresponde à chave de backup '
        'deste aparelho. Confirme um código novo.',
      );
    }
    try {
      return ChavesParaSelar(
        mestra,
        CabecalhoChave.deBytes(base64.decode(cabecalhoB64)),
      );
    } on FormatException {
      throw const ChavesBackupException('cabeçalho de chave ilegível no cofre');
    } on BackupInvalidoException catch (e) {
      throw ChavesBackupException('cabeçalho de chave inválido: ${e.mensagem}');
    }
  }

  static String _paraHex(List<int> b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

  static Uint8List _deHex(String hex) => Uint8List.fromList([
    for (var i = 0; i < hex.length; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ]);
}
