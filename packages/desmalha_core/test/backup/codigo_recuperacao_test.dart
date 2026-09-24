import 'dart:math';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

void main() {
  test('formato canônico: 5 grupos de 5, só o alfabeto de Crockford', () {
    final codigo = gerarCodigoRecuperacao(Random(1));
    expect(codigo, matches(RegExp(r'^[0-9A-HJKMNP-TV-Z]{5}(-[0-9A-HJKMNP-TV-Z]{5}){4}$')));
    expect(codigo, isNot(matches(RegExp('[ILOU]'))));
  });

  test('alfabeto de 32 símbolos sem I, L, O, U → 125 bits', () {
    expect(alfabetoCodigoRecuperacao.length, 32);
    expect(alfabetoCodigoRecuperacao, isNot(matches(RegExp('[ILOU]'))));
    expect(gruposDoCodigo * simbolosPorGrupo * 5, 125);
  });

  test('códigos gerados não se repetem', () {
    final r = Random(7);
    final vistos = {for (var i = 0; i < 2000; i++) gerarCodigoRecuperacao(r)};
    expect(vistos, hasLength(2000));
  });

  test('a normalização tolera o que a mão erra, e chega ao mesmo canônico',
      () {
    const canonico = 'K7M2Q-0A1B2-C3D4E-F5G6H-J8K9M';
    for (final digitado in [
      canonico,
      'k7m2q-0a1b2-c3d4e-f5g6h-j8k9m',
      'K7M2Q 0A1B2 C3D4E F5G6H J8K9M',
      'K7M2QOA1B2C3D4EF5G6HJ8K9M', // O no lugar de 0, sem separador
      'K7M2Q-0AIB2-C3D4E-F5G6H-J8K9M', // I no lugar de 1
      'K7M2Q-0ALB2-C3D4E-F5G6H-J8K9M', // L no lugar de 1
    ]) {
      expect(normalizarCodigoRecuperacao(digitado), canonico, reason: digitado);
    }
  });

  test('o que não é código possível vira null, nunca "quase igual"', () {
    expect(normalizarCodigoRecuperacao(''), isNull);
    expect(normalizarCodigoRecuperacao('K7M2Q-0A1B2-C3D4E-F5G6H'), isNull);
    expect(normalizarCodigoRecuperacao('K7M2Q-0A1B2-C3D4E-F5G6H-J8K9MX'),
        isNull);
    expect(normalizarCodigoRecuperacao('K7M2Q-0A1B2-C3D4E-F5G6H-J8K9U'),
        isNull, reason: 'U não existe no alfabeto');
    expect(normalizarCodigoRecuperacao('K7M2Q-0A1B2-C3D4E-F5G6H-J8K9!'),
        isNull);
  });

  test('confirmação: dois grupos distintos, e o grupo confere com tolerância',
      () {
    final grupos = sortearGruposParaConfirmar(Random(3));
    expect(grupos, hasLength(2));
    expect(grupos.toSet(), hasLength(2));
    expect(grupos.every((g) => g >= 0 && g < 5), isTrue);

    const canonico = 'K7M2Q-0A1B2-C3D4E-F5G6H-J8K9M';
    expect(grupoConfere(canonico, 1, '0a1b2'), isTrue);
    expect(grupoConfere(canonico, 1, 'OAIB2'), isTrue);
    expect(grupoConfere(canonico, 1, '0A1B3'), isFalse);
    expect(grupoConfere(canonico, 2, '0A1B2'), isFalse);
    expect(grupoConfere(canonico, 7, '0A1B2'), isFalse);
  });

  test('o código normalizado abre o que o canônico embrulhou', () async {
    final canonico = gerarCodigoRecuperacao(Random(11));
    final mestra = List<int>.generate(32, (i) => 255 - i);
    final cabecalho = await embrulharChaveMestra(
      chaveMestra: mestra,
      codigo: canonico,
    );
    final digitadoNaVolta = canonico.toLowerCase().replaceAll('-', ' ');
    final normalizado = normalizarCodigoRecuperacao(digitadoNaVolta)!;
    expect(await cabecalho.chaveMestraPeloCodigo(normalizado), mestra);
  });
}
