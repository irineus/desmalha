/// As chaves do backup no aparelho. Mesma regra da chave do banco — NUNCA
/// regenerar em silêncio — e a regra própria do backup: sem código
/// confirmado, não há o que selar.
library;

import 'dart:math';

import 'package:desmalha_app/backup/chaves_backup.dart';
import 'package:desmalha_app/dados/chave_banco.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../servicos_falsos.dart';

class _CofreQueEngole extends CofreEmMemoria {
  @override
  Future<void> gravar(String campo, String valor) async => gravacoes++;
}

void main() {
  test('a mestra é criada uma vez e devolvida sempre a mesma', () async {
    final cofre = CofreEmMemoria();
    final chaves = ChavesBackup(cofre: cofre, aleatorio: Random(1));
    final a = await chaves.obterOuCriarChaveMestra();
    final b = await chaves.obterOuCriarChaveMestra();
    expect(a, hasLength(32));
    expect(b, a);
    expect(cofre.gravacoes, 1);
  });

  test('mestra corrompida no cofre: falha visível, nada regravado', () async {
    final cofre = CofreEmMemoria()..valores[ChavesBackup.campoMestra] = 'xx';
    final chaves = ChavesBackup(cofre: cofre);
    await expectLater(
      chaves.obterOuCriarChaveMestra(),
      throwsA(isA<ChavesBackupException>()),
    );
    expect(cofre.valores[ChavesBackup.campoMestra], 'xx');
    expect(cofre.gravacoes, 0);
  });

  test('cofre que não confirma a gravação: nenhuma mestra fantasma', () async {
    final chaves = ChavesBackup(cofre: _CofreQueEngole());
    await expectLater(
      chaves.obterOuCriarChaveMestra(),
      throwsA(isA<ChavesBackupException>()),
    );
  });

  test('sem código confirmado não há o que selar — e isso é dito', () async {
    final chaves = ChavesBackup(cofre: CofreEmMemoria(), aleatorio: Random(1));
    expect(await chaves.codigoConfirmado(), isFalse);
    await expectLater(
      chaves.chavesParaSelar(),
      throwsA(
        isA<ChavesBackupException>().having(
          (e) => e.mensagem,
          'mensagem',
          contains('desligado'),
        ),
      ),
    );
  });

  test('código confirmado: o cabeçalho guardado abre pelo código e devolve '
      'a mestra do aparelho', () async {
    final chaves = ChavesBackup(cofre: CofreEmMemoria(), aleatorio: Random(2));
    final codigo = gerarCodigoRecuperacao(Random(3));
    await chaves.confirmarCodigo(codigo);

    expect(await chaves.codigoConfirmado(), isTrue);
    final paraSelar = await chaves.chavesParaSelar();
    expect(
      await paraSelar.cabecalho.chaveMestraPeloCodigo(codigo),
      paraSelar.chaveMestra,
    );
  });

  test('o código nunca é guardado no cofre', () async {
    final cofre = CofreEmMemoria();
    final chaves = ChavesBackup(cofre: cofre, aleatorio: Random(2));
    final codigo = gerarCodigoRecuperacao(Random(3));
    await chaves.confirmarCodigo(codigo);
    final simbolos = codigo.replaceAll('-', '');
    for (final valor in cofre.valores.values) {
      expect(valor.toUpperCase(), isNot(contains(simbolos)));
      expect(valor, isNot(contains(codigo)));
    }
  });

  test('cabeçalho feito para OUTRA mestra é recusado antes de selar', () async {
    final cofre = CofreEmMemoria();
    final chaves = ChavesBackup(cofre: cofre, aleatorio: Random(2));
    await chaves.confirmarCodigo(gerarCodigoRecuperacao(Random(3)));
    // A mestra mudou por fora (restauração, bug): o cabeçalho antigo abriria
    // pelo código uma mestra que já não cifra os backups novos.
    cofre.valores[ChavesBackup.campoMestra] = 'ab' * 32;
    expect(await chaves.codigoConfirmado(), isFalse);
    await expectLater(
      chaves.chavesParaSelar(),
      throwsA(isA<ChavesBackupException>()),
    );
  });

  test('código fora do formato canônico nem é aceito', () async {
    final chaves = ChavesBackup(cofre: CofreEmMemoria(), aleatorio: Random(2));
    expect(() => chaves.confirmarCodigo('k7m2q 0a1b2'), throwsArgumentError);
  });

  test('o cofre é o mesmo adaptador do app (Keystore/Keychain)', () {
    expect(ChavesBackup(), isA<ChavesBackup>());
    expect(const CofreSeguroDoSistema(), isA<CofreSeguro>());
  });
}
