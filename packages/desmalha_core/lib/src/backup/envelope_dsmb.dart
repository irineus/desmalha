/// Envelope `.dsmb` do backup cifrado ponta a ponta — o formato em bytes.
///
/// Especificação: "Resultado: Revisar modelagem de dados para local-first"
/// (ago/2026), seção 6. Layout, todos os inteiros little-endian:
///
/// ```text
/// offset  bytes  campo
/// 0       4      magic "DSMB"
/// 4       1      versao_envelope = 1
/// 5       1      suite = 1  (XChaCha20-Poly1305 + Argon2id)
/// 6       2      reservado (zero)
/// 8       16     salt_kdf
/// 24      4      argon2_m_kib
/// 28      4      argon2_t
/// 32      1      argon2_p
/// 33      3      reservado (zero)
/// 36      24     nonce_wrap
/// 60      48     chave_mestra_wrapped   (32 bytes + tag 16)
/// 108     24     nonce_conteudo
/// 132     N      ciphertext = gzip(NDJSON) + tag 16
/// ```
///
/// **Duas camadas de chave.** A chave-mestra (32 bytes aleatórios, gerada no
/// aparelho, guardada no Keystore/Keychain) cifra o conteúdo. O código de
/// recuperação deriva, por Argon2id, uma KEK que só EMBRULHA a mestra. Por
/// isso os bytes 0..108 — o [CabecalhoChave] — são gerados uma vez, quando o
/// código é confirmado, e reaproveitados em todo backup: o backup diário não
/// roda Argon2id (64 MiB é pesado para segundo plano), e trocar o código
/// re-embrulha 108 bytes em vez de re-cifrar cinco anos de dados.
///
/// **Autenticação do cabeçalho (decisão de implementação, set/2026).** O
/// embrulho da mestra usa como AAD os bytes 0..36 (versão, suíte, salt e os
/// parâmetros do Argon2); o conteúdo usa como AAD o cabeçalho inteiro, 0..132.
/// Adulterar um parâmetro — baixar a memória do Argon2 para facilitar força
/// bruta, trocar o nonce — invalida a tag em vez de passar despercebido.
///
/// Primitivas: pacote `cryptography` (Dart puro), conferido contra
/// referências independentes nos testes — Argon2id contra o OpenSSL do Node
/// (`crypto.argon2Sync`) e XChaCha20-Poly1305 contra o vetor A.3.1 do
/// draft-irtf-cfrg-xchacha.
library;

import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'excecoes_backup.dart';

/// "DSMB".
const List<int> magicDsmb = [0x44, 0x53, 0x4D, 0x42];

/// Versão do layout em bytes (independente do `formato_versao` do payload).
const int versaoEnvelopeAtual = 1;

/// XChaCha20-Poly1305 + Argon2id.
const int suiteXChachaArgon2id = 1;

const int tamanhoCabecalhoChave = 108;
const int tamanhoCabecalhoCompleto = 132;
const int _tamanhoTag = 16;
const int _tamanhoChave = 32;

/// Parâmetros do Argon2id gravados no envelope.
class ParametrosKdf {
  const ParametrosKdf({
    required this.memoriaKib,
    required this.iteracoes,
    required this.paralelismo,
  });

  /// Os da especificação: m = 64 MiB, t = 3, p = 1.
  static const padrao = ParametrosKdf(
    memoriaKib: 65536,
    iteracoes: 3,
    paralelismo: 1,
  );

  final int memoriaKib;
  final int iteracoes;
  final int paralelismo;

  /// Limites aceitos NA LEITURA. O de baixo é o mínimo de memória recomendado
  /// pela OWASP para Argon2id (19 MiB): um envelope que pedisse menos seria
  /// fraco demais para confiar. O de cima protege contra um blob que peça
  /// 64 GiB e derrube o app na restauração.
  void validar() {
    if (memoriaKib < 19456 || memoriaKib > 1048576) {
      throw BackupInvalidoException(
        'parâmetro de memória do Argon2 fora da faixa aceita: $memoriaKib KiB',
      );
    }
    if (iteracoes < 1 || iteracoes > 10) {
      throw BackupInvalidoException(
        'iterações do Argon2 fora da faixa aceita: $iteracoes',
      );
    }
    if (paralelismo < 1 || paralelismo > 4) {
      throw BackupInvalidoException(
        'paralelismo do Argon2 fora da faixa aceito: $paralelismo',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ParametrosKdf &&
      other.memoriaKib == memoriaKib &&
      other.iteracoes == iteracoes &&
      other.paralelismo == paralelismo;

  @override
  int get hashCode => Object.hash(memoriaKib, iteracoes, paralelismo);
}

/// Os bytes 0..108: a chave-mestra embrulhada pela KEK do código.
class CabecalhoChave {
  CabecalhoChave._(this.bytes);

  /// Os 108 bytes, prontos para gravar no aparelho e prefixar cada backup.
  final Uint8List bytes;

  /// Relê um cabeçalho gravado, validando estrutura e parâmetros.
  factory CabecalhoChave.deBytes(List<int> bytes) {
    if (bytes.length < tamanhoCabecalhoChave) {
      throw const BackupInvalidoException('cabeçalho de chave incompleto');
    }
    final b = Uint8List.fromList(bytes.sublist(0, tamanhoCabecalhoChave));
    for (var i = 0; i < 4; i++) {
      if (b[i] != magicDsmb[i]) {
        throw const BackupInvalidoException(
          'não é um arquivo de backup do Desmalha (assinatura "DSMB" ausente)',
        );
      }
    }
    if (b[4] > versaoEnvelopeAtual) {
      throw BackupDeVersaoFuturaException(
        'envelope versão ${b[4]}; este app lê até a $versaoEnvelopeAtual',
      );
    }
    if (b[4] != versaoEnvelopeAtual) {
      throw BackupInvalidoException('versão de envelope inválida: ${b[4]}');
    }
    if (b[5] != suiteXChachaArgon2id) {
      throw BackupInvalidoException('suíte criptográfica desconhecida: ${b[5]}');
    }
    final cabecalho = CabecalhoChave._(b);
    cabecalho.parametros.validar();
    return cabecalho;
  }

  ByteData get _dados => ByteData.sublistView(bytes);

  List<int> get salt => bytes.sublist(8, 24);

  ParametrosKdf get parametros => ParametrosKdf(
    memoriaKib: _dados.getUint32(24, Endian.little),
    iteracoes: _dados.getUint32(28, Endian.little),
    paralelismo: bytes[32],
  );

  List<int> get _aadEmbrulho => bytes.sublist(0, 36);
  List<int> get _nonceEmbrulho => bytes.sublist(36, 60);
  List<int> get _embrulhada => bytes.sublist(60, 108);

  /// Desembrulha a chave-mestra com o [codigo] de recuperação. Caro: roda o
  /// Argon2id. Só em primeiro plano (restauração em outra plataforma, troca
  /// de código).
  ///
  /// Lança [ChaveDeBackupIncorretaException] se o código não confere.
  Future<Uint8List> chaveMestraPeloCodigo(String codigo) async {
    final kek = await _derivarKek(codigo, salt, parametros);
    try {
      final mestra = await _aead.decrypt(
        SecretBox(
          _embrulhada.sublist(0, _tamanhoChave),
          nonce: _nonceEmbrulho,
          mac: Mac(_embrulhada.sublist(_tamanhoChave)),
        ),
        secretKey: SecretKey(kek),
        aad: _aadEmbrulho,
      );
      return Uint8List.fromList(mestra);
    } on SecretBoxAuthenticationError {
      throw const ChaveDeBackupIncorretaException(
        'o código de recuperação não abre este backup',
      );
    }
  }
}

final _aead = Xchacha20.poly1305Aead();

Future<List<int>> _derivarKek(
  String codigo,
  List<int> salt,
  ParametrosKdf p,
) async {
  final chave = await Argon2id(
    parallelism: p.paralelismo,
    memory: p.memoriaKib,
    iterations: p.iteracoes,
    hashLength: _tamanhoChave,
  ).deriveKeyFromPassword(password: codigo, nonce: salt);
  return chave.extractBytes();
}

List<int> _aleatorios(Random aleatorio, int n) =>
    List<int>.generate(n, (_) => aleatorio.nextInt(256));

/// Embrulha a [chaveMestra] com a KEK derivada do [codigo] — uma vez, quando
/// o código de recuperação é confirmado. Caro: roda o Argon2id.
Future<CabecalhoChave> embrulharChaveMestra({
  required List<int> chaveMestra,
  required String codigo,
  ParametrosKdf parametros = ParametrosKdf.padrao,
  Random? aleatorio,
}) async {
  if (chaveMestra.length != _tamanhoChave) {
    throw ArgumentError('a chave-mestra tem de ter 32 bytes');
  }
  if (codigo.isEmpty) throw ArgumentError('código de recuperação vazio');
  parametros.validar();
  final rnd = aleatorio ?? Random.secure();
  final b = Uint8List(tamanhoCabecalhoChave);
  final d = ByteData.sublistView(b);
  b.setRange(0, 4, magicDsmb);
  b[4] = versaoEnvelopeAtual;
  b[5] = suiteXChachaArgon2id;
  b.setRange(8, 24, _aleatorios(rnd, 16));
  d.setUint32(24, parametros.memoriaKib, Endian.little);
  d.setUint32(28, parametros.iteracoes, Endian.little);
  b[32] = parametros.paralelismo;
  b.setRange(36, 60, _aleatorios(rnd, 24));

  final kek = await _derivarKek(codigo, b.sublist(8, 24), parametros);
  final caixa = await _aead.encrypt(
    chaveMestra,
    secretKey: SecretKey(kek),
    nonce: b.sublist(36, 60),
    aad: b.sublist(0, 36),
  );
  b.setRange(60, 92, caixa.cipherText);
  b.setRange(92, 108, caixa.mac.bytes);
  return CabecalhoChave._(b);
}

/// Sela o [conteudo] (o payload já gzipado) num `.dsmb` completo.
///
/// Só a chave-mestra é necessária: o [cabecalho] já traz o embrulho. O
/// chamador garante que o cabeçalho foi feito para ESTA mestra (ver
/// `impressaoDaChaveMestra`) — com mestra trocada, o blob abriria no mesmo
/// aparelho e nunca pelo código de recuperação.
Future<Uint8List> selarDsmb({
  required CabecalhoChave cabecalho,
  required List<int> chaveMestra,
  required List<int> conteudo,
  Random? aleatorio,
}) async {
  if (chaveMestra.length != _tamanhoChave) {
    throw ArgumentError('a chave-mestra tem de ter 32 bytes');
  }
  final rnd = aleatorio ?? Random.secure();
  final cabecalhoCompleto = Uint8List(tamanhoCabecalhoCompleto)
    ..setRange(0, tamanhoCabecalhoChave, cabecalho.bytes)
    ..setRange(tamanhoCabecalhoChave, tamanhoCabecalhoCompleto,
        _aleatorios(rnd, 24));
  final caixa = await _aead.encrypt(
    conteudo,
    secretKey: SecretKey(chaveMestra),
    nonce: cabecalhoCompleto.sublist(tamanhoCabecalhoChave),
    aad: cabecalhoCompleto,
  );
  return Uint8List.fromList([
    ...cabecalhoCompleto,
    ...caixa.cipherText,
    ...caixa.mac.bytes,
  ]);
}

/// Abre um `.dsmb` com a chave-mestra do aparelho (restauração na mesma
/// plataforma — não pede o código).
Future<Uint8List> abrirDsmbComChaveMestra(
  List<int> dsmb,
  List<int> chaveMestra,
) async {
  final cabecalho = CabecalhoChave.deBytes(dsmb);
  return _abrirConteudo(dsmb, cabecalho, chaveMestra);
}

/// Abre um `.dsmb` com o código de recuperação (restauração em outra
/// plataforma). Devolve também a mestra, para o aparelho novo guardá-la.
Future<({Uint8List conteudo, Uint8List chaveMestra})> abrirDsmbComCodigo(
  List<int> dsmb,
  String codigo,
) async {
  final cabecalho = CabecalhoChave.deBytes(dsmb);
  final mestra = await cabecalho.chaveMestraPeloCodigo(codigo);
  return (
    conteudo: await _abrirConteudo(dsmb, cabecalho, mestra),
    chaveMestra: mestra,
  );
}

Future<Uint8List> _abrirConteudo(
  List<int> dsmb,
  CabecalhoChave cabecalho,
  List<int> chaveMestra,
) async {
  if (dsmb.length < tamanhoCabecalhoCompleto + _tamanhoTag) {
    throw const BackupInvalidoException('backup truncado');
  }
  final cabecalhoCompleto = dsmb.sublist(0, tamanhoCabecalhoCompleto);
  final corpo = dsmb.sublist(tamanhoCabecalhoCompleto);
  try {
    final aberto = await _aead.decrypt(
      SecretBox(
        corpo.sublist(0, corpo.length - _tamanhoTag),
        nonce: cabecalhoCompleto.sublist(tamanhoCabecalhoChave),
        mac: Mac(corpo.sublist(corpo.length - _tamanhoTag)),
      ),
      secretKey: SecretKey(chaveMestra),
      aad: cabecalhoCompleto,
    );
    return Uint8List.fromList(aberto);
  } on SecretBoxAuthenticationError {
    // Chave errada, byte adulterado em qualquer ponto (cabeçalho incluído) ou
    // corrupção no armazenamento: indistinguíveis por construção do AEAD.
    throw const ChaveDeBackupIncorretaException(
      'o backup não abre com esta chave, ou foi alterado depois de gravado',
    );
  }
}

/// Impressão digital da chave-mestra (16 bytes, hex): para o app conferir,
/// antes de selar, que o [CabecalhoChave] guardado foi feito para a mestra
/// atual — sem precisar do código. Não revela a chave (SHA-256 com domínio).
Future<String> impressaoDaChaveMestra(List<int> chaveMestra) async {
  final h = await Sha256().hash([
    ...'desmalha-dsmb-impressao-v1'.codeUnits,
    ...chaveMestra,
  ]);
  return h.bytes
      .sublist(0, 16)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
}

/// SHA-256 em hex minúsculo — o hash do CIPHERTEXT que vai para
/// `backups_metadados` (a camada de integridade de trânsito/armazenamento).
Future<String> sha256Hex(List<int> bytes) async {
  final h = await Sha256().hash(bytes);
  return h.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
