/// A regra que estes testes travam: a chave do banco NUNCA é regenerada em
/// silêncio. Chave nova sobre banco existente = livro-caixa de até 5 anos
/// ilegível para sempre. Todo caminho estranho do cofre falha visível.
library;

import 'dart:math';

import 'package:desmalha_app/dados/chave_banco.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cofre vazio: gera 32 bytes em hex, grava e passa a devolver sempre '
      'a mesma', () async {
    final cofre = _CofreEmMemoria();
    final chaves = ChaveBanco(cofre: cofre, aleatorio: Random(42));

    final primeira = await chaves.obterOuCriarHex();
    expect(primeira, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(cofre.valores[ChaveBanco.campoCofre], primeira);

    final segunda = await chaves.obterOuCriarHex();
    expect(segunda, primeira);
  });

  test('valor corrompido no cofre: falha visível e NÃO regrava nada', () async {
    final cofre = _CofreEmMemoria()
      ..valores[ChaveBanco.campoCofre] = 'isto-não-é-uma-chave';
    final chaves = ChaveBanco(cofre: cofre, aleatorio: Random(42));

    await expectLater(
      chaves.obterOuCriarHex,
      throwsA(isA<ChaveBancoException>()),
    );
    // Regenerar por cima seria pior que o erro: apagaria o acesso ao banco.
    expect(cofre.valores[ChaveBanco.campoCofre], 'isto-não-é-uma-chave');
    expect(cofre.gravacoes, 0);
  });

  test('cofre que não confirma a gravação: falha antes de cifrar qualquer '
      'coisa com uma chave que pode não existir no próximo boot', () async {
    final cofre = _CofreQueEngoleGravacao();
    final chaves = ChaveBanco(cofre: cofre, aleatorio: Random(42));

    await expectLater(
      chaves.obterOuCriarHex,
      throwsA(isA<ChaveBancoException>()),
    );
  });

  test('instâncias com aleatoriedade distinta geram chaves distintas', () async {
    final a = await ChaveBanco(cofre: _CofreEmMemoria(), aleatorio: Random(1))
        .obterOuCriarHex();
    final b = await ChaveBanco(cofre: _CofreEmMemoria(), aleatorio: Random(2))
        .obterOuCriarHex();
    expect(a, isNot(b));
  });
}

class _CofreEmMemoria implements CofreSeguro {
  final valores = <String, String>{};
  var gravacoes = 0;

  @override
  Future<String?> ler(String campo) async => valores[campo];

  @override
  Future<void> gravar(String campo, String valor) async {
    gravacoes++;
    valores[campo] = valor;
  }
}

/// Aceita o `gravar` sem erro, mas a releitura volta vazia — o análogo do
/// "2xx que não prova nada" registrado no board.
class _CofreQueEngoleGravacao implements CofreSeguro {
  @override
  Future<String?> ler(String campo) async => null;

  @override
  Future<void> gravar(String campo, String valor) async {}
}
