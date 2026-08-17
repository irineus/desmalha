/// Chave do SQLCipher: gerada no aparelho, guardada no cofre do sistema
/// (Keystore no Android, Keychain no iOS), nunca transmitida.
///
/// Esta é a chave do ARQUIVO local. O envelope de backup `.dsmb` tem o seu
/// próprio esquema de duas camadas (chave-mestra + KEK do código de
/// recuperação), especificado na modelagem e implementado no card de backup
/// E2E — não confundir as duas coisas.
library;

import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Porta estreita para o cofre do sistema — mesmo padrão do `PortaAuth`:
/// o plugin entra no app por um adaptador só, e o resto do código (e os
/// testes) enxergam apenas isto.
abstract interface class CofreSeguro {
  Future<String?> ler(String campo);
  Future<void> gravar(String campo, String valor);
}

/// Adaptador do `flutter_secure_storage`: Keystore no Android, Keychain no
/// iOS. Ajustes finos (acessibilidade do Keychain, Block Store) pertencem ao
/// card de backup E2E, junto com a chave-mestra do `.dsmb`.
class CofreSeguroDoSistema implements CofreSeguro {
  const CofreSeguroDoSistema([this._plugin = const FlutterSecureStorage()]);

  final FlutterSecureStorage _plugin;

  @override
  Future<String?> ler(String campo) => _plugin.read(key: campo);

  @override
  Future<void> gravar(String campo, String valor) =>
      _plugin.write(key: campo, value: valor);
}

/// O cofre devolveu um valor que não é uma chave válida, ou não confirmou
/// a gravação. Regenerar em silêncio NUNCA é resposta: uma chave nova
/// tornaria o banco existente ilegível para sempre — o livro-caixa de até
/// 5 anos que o usuário é obrigado a guardar. Falhar visível e preservar o
/// arquivo é o único comportamento aceitável.
class ChaveBancoException implements Exception {
  const ChaveBancoException(this.mensagem);

  final String mensagem;

  @override
  String toString() => 'ChaveBancoException: $mensagem';
}

/// Gera (uma vez) e devolve a chave do banco em hexadecimal (32 bytes).
class ChaveBanco {
  ChaveBanco({CofreSeguro? cofre, Random? aleatorio})
      : _cofre = cofre ?? const CofreSeguroDoSistema(),
        _aleatorio = aleatorio ?? Random.secure();

  /// Versão no nome do campo: se um dia o formato da chave mudar, a leitura
  /// do formato antigo continua encontrável em vez de "sumir".
  static const campoCofre = 'desmalha_chave_sqlcipher_v1';

  static final _formatoValido = RegExp(r'^[0-9a-f]{64}$');

  final CofreSeguro _cofre;
  final Random _aleatorio;

  Future<String> obterOuCriarHex() async {
    final existente = await _cofre.ler(campoCofre);
    if (existente != null) {
      if (!_formatoValido.hasMatch(existente)) {
        // Não incluir o valor na mensagem: pode ser uma chave parcial.
        throw const ChaveBancoException(
          'o cofre do sistema devolveu um valor que não tem o formato de '
          'chave (64 hex). Nada foi regravado — regenerar apagaria o acesso '
          'ao banco existente.',
        );
      }
      return existente;
    }

    final nova = _gerarHex();
    await _cofre.gravar(campoCofre, nova);
    // Escrever sem erro não é prova de que ficou gravado (lição registrada
    // no board: 2xx diz que o pedido foi aceito, não que o estado mudou).
    // Antes de cifrar QUALQUER dado com esta chave, reler e comparar.
    final relida = await _cofre.ler(campoCofre);
    if (relida != nova) {
      throw const ChaveBancoException(
        'o cofre do sistema não confirmou a gravação da chave nova. O banco '
        'não será criado com uma chave que pode não existir no próximo boot.',
      );
    }
    return nova;
  }

  String _gerarHex() {
    final bytes = List<int>.generate(32, (_) => _aleatorio.nextInt(256));
    final hex = StringBuffer();
    for (final byte in bytes) {
      hex.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return hex.toString();
  }
}
