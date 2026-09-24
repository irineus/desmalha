import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

String _hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

final _mestra = List<int>.generate(32, (i) => i * 7 % 256);
const _codigo = 'TESTE-CODIGO-DE-RECUPERACAO';

void main() {
  group('primitivas conferidas contra referências independentes', () {
    test('Argon2id = OpenSSL (Node crypto.argon2Sync), parâmetros do padrão',
        () async {
      // node -e "require('crypto').argon2Sync('argon2id', {message:
      //   Buffer.from('ABCDE-FGHIJ-KLMNO-PQRST-UVWXY'), nonce: Buffer.alloc(16,7),
      //   parallelism:1, tagLength:32, memory:65536, passes:3}).toString('hex')"
      final k = await Argon2id(
        parallelism: 1,
        memory: 65536,
        iterations: 3,
        hashLength: 32,
      ).deriveKeyFromPassword(
        password: 'ABCDE-FGHIJ-KLMNO-PQRST-UVWXY',
        nonce: List.filled(16, 7),
      );
      expect(
        _hex(await k.extractBytes()),
        '6ed301aea953252e6c18e861471faeda01944e64cc3b238c89b1c1aff4ef9d80',
      );
    });

    test('XChaCha20-Poly1305 = vetor A.3.1 do draft-irtf-cfrg-xchacha',
        () async {
      final caixa = await Xchacha20.poly1305Aead().encrypt(
        utf8.encode("Ladies and Gentlemen of the class of '99: If I could "
            'offer you only one tip for the future, sunscreen would be it.'),
        secretKey: SecretKey(List.generate(32, (i) => 0x80 + i)),
        nonce: List.generate(24, (i) => 0x40 + i),
        aad: [0x50, 0x51, 0x52, 0x53, 0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5,
          0xc6, 0xc7],
      );
      expect(_hex(caixa.cipherText), startsWith('bd6d179d3e83d43b95765794'));
      expect(_hex(caixa.mac.bytes), 'c0875924c1c7987947deafd8780acf49');
    });
  });

  group('envelope .dsmb', () {
    late CabecalhoChave cabecalho;
    final conteudo = utf8.encode('payload gzipado de mentira');

    setUpAll(() async {
      cabecalho = await embrulharChaveMestra(
        chaveMestra: _mestra,
        codigo: _codigo,
        aleatorio: Random(1),
      );
    });

    test('layout: 108 bytes de cabeçalho, magic, versão, suíte, parâmetros',
        () {
      final b = cabecalho.bytes;
      expect(b, hasLength(tamanhoCabecalhoChave));
      expect(b.sublist(0, 4), magicDsmb);
      expect(b[4], versaoEnvelopeAtual);
      expect(b[5], suiteXChachaArgon2id);
      expect(b.sublist(6, 8), [0, 0]);
      expect(cabecalho.parametros, ParametrosKdf.padrao);
      expect(b.sublist(33, 36), [0, 0, 0]);
    });

    test('selar → 132 bytes de cabeçalho + conteúdo + tag de 16', () async {
      final dsmb = await selarDsmb(
        cabecalho: cabecalho,
        chaveMestra: _mestra,
        conteudo: conteudo,
      );
      expect(dsmb.length, tamanhoCabecalhoCompleto + conteudo.length + 16);
      expect(dsmb.sublist(0, 108), cabecalho.bytes);
    });

    test('mesma plataforma: abre com a chave-mestra, sem o código', () async {
      final dsmb = await selarDsmb(
        cabecalho: cabecalho,
        chaveMestra: _mestra,
        conteudo: conteudo,
      );
      expect(await abrirDsmbComChaveMestra(dsmb, _mestra), conteudo);
    });

    test('outra plataforma: abre com o código e devolve a mestra', () async {
      final dsmb = await selarDsmb(
        cabecalho: cabecalho,
        chaveMestra: _mestra,
        conteudo: conteudo,
      );
      final r = await abrirDsmbComCodigo(dsmb, _codigo);
      expect(r.conteudo, conteudo);
      expect(r.chaveMestra, _mestra);
    });

    test('código errado não abre', () async {
      final dsmb = await selarDsmb(
        cabecalho: cabecalho,
        chaveMestra: _mestra,
        conteudo: conteudo,
      );
      await expectLater(
        abrirDsmbComCodigo(dsmb, 'OUTRO-CODIGO'),
        throwsA(isA<ChaveDeBackupIncorretaException>()),
      );
    });

    test('chave-mestra errada não abre', () async {
      final dsmb = await selarDsmb(
        cabecalho: cabecalho,
        chaveMestra: _mestra,
        conteudo: conteudo,
      );
      await expectLater(
        abrirDsmbComChaveMestra(dsmb, List.filled(32, 9)),
        throwsA(isA<ChaveDeBackupIncorretaException>()),
      );
    });

    test('qualquer byte adulterado — conteúdo, nonce ou salt — é recusado',
        () async {
      final dsmb = await selarDsmb(
        cabecalho: cabecalho,
        chaveMestra: _mestra,
        conteudo: conteudo,
      );
      for (final posicao in [10, 40, 70, 110, dsmb.length - 1, 140]) {
        final adulterado = Uint8List.fromList(dsmb)..[posicao] ^= 0x01;
        await expectLater(
          abrirDsmbComChaveMestra(adulterado, _mestra),
          throwsA(isA<ChaveDeBackupIncorretaException>()),
          reason: 'byte $posicao',
        );
      }
    });

    test('baixar a memória do Argon2 no cabeçalho é pego pelo AAD', () async {
      final dsmb = await selarDsmb(
        cabecalho: cabecalho,
        chaveMestra: _mestra,
        conteudo: conteudo,
      );
      // 64 MiB → 32 MiB: ainda dentro da faixa aceita, então passa pela
      // validação de parâmetros e só o AEAD pode recusar.
      final adulterado = Uint8List.fromList(dsmb);
      ByteData.sublistView(adulterado).setUint32(24, 32768, Endian.little);
      await expectLater(
        abrirDsmbComChaveMestra(adulterado, _mestra),
        throwsA(isA<ChaveDeBackupIncorretaException>()),
      );
    });

    test('envelope de versão futura: recusa com "atualize o app"', () async {
      final dsmb = await selarDsmb(
        cabecalho: cabecalho,
        chaveMestra: _mestra,
        conteudo: conteudo,
      );
      final futuro = Uint8List.fromList(dsmb)..[4] = 2;
      await expectLater(
        abrirDsmbComChaveMestra(futuro, _mestra),
        throwsA(isA<BackupDeVersaoFuturaException>()),
      );
    });

    test('sem a assinatura DSMB, truncado ou com parâmetros absurdos: '
        'recusa antes de gastar Argon2', () async {
      final dsmb = await selarDsmb(
        cabecalho: cabecalho,
        chaveMestra: _mestra,
        conteudo: conteudo,
      );
      await expectLater(
        abrirDsmbComChaveMestra(Uint8List.fromList(dsmb)..[0] = 0x58, _mestra),
        throwsA(isA<BackupInvalidoException>()),
      );
      await expectLater(
        abrirDsmbComChaveMestra(dsmb.sublist(0, 140), _mestra),
        throwsA(isA<BackupInvalidoException>()),
      );
      final gigante = Uint8List.fromList(dsmb);
      ByteData.sublistView(gigante).setUint32(24, 0x7fffffff, Endian.little);
      await expectLater(
        abrirDsmbComCodigo(gigante, _codigo),
        throwsA(isA<BackupInvalidoException>()),
      );
    });

    test('cada selagem usa nonce novo: o mesmo conteúdo nunca vira os mesmos '
        'bytes', () async {
      final a = await selarDsmb(
          cabecalho: cabecalho, chaveMestra: _mestra, conteudo: conteudo);
      final b = await selarDsmb(
          cabecalho: cabecalho, chaveMestra: _mestra, conteudo: conteudo);
      expect(a.sublist(108, 132), isNot(b.sublist(108, 132)));
    });

    test('impressão digital: estável, depende da chave, não a revela',
        () async {
      final i1 = await impressaoDaChaveMestra(_mestra);
      expect(i1, hasLength(32));
      expect(await impressaoDaChaveMestra(_mestra), i1);
      expect(await impressaoDaChaveMestra(List.filled(32, 1)), isNot(i1));
      expect(i1, isNot(contains(_hex(_mestra).substring(0, 8))));
    });
  });
}
