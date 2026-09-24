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

  static final _hex64 = RegExp(r'^[0-9a-f]{64}$');

  final CofreSeguro _cofre;
  final Random _aleatorio;

  /// A chave-mestra: lida do cofre ou criada (uma vez) e conferida.
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
  Future<void> confirmarCodigo(String codigoCanonico) async {
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
