import 'dart:io';
import 'dart:math';

import 'package:desmalha_app/backup/chaves_backup.dart';
import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/dados/chave_banco.dart';
import 'package:desmalha_app/dados/limpeza_local.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../servicos_falsos.dart';

/// Cofre que finge apagar mas mantém o valor — o caso em que a limpeza
/// NÃO pode seguir para o banco.
class _CofreTeimoso extends CofreEmMemoria {
  @override
  Future<void> apagar(String campo) async {}
}

void main() {
  late BancoLocal banco;
  setUp(() => banco = BancoLocal(NativeDatabase.memory()));
  tearDown(() => banco.close());

  Future<int> linhas(String tabela) async =>
      (await banco
              .customSelect('SELECT count(*) AS n FROM $tabela')
              .getSingle())
          .read<int>('n');

  Future<void> popular() async {
    Future<void> sql(String s) => banco.customStatement(s);
    await sql(
      "INSERT INTO perfil (id, usuario_remoto_id, nome, cpf, criado_em, "
      "atualizado_em) VALUES (1, 'uid-ana', 'Ana', '52998224725', 0, 0)",
    );
    await sql(
      "INSERT INTO aceites_termos_local VALUES ('termos_uso', '2026-09-v1', 0, 1)",
    );
    await sql(
      "INSERT INTO contas_bancarias (id, apelido, criado_em) VALUES ('c', 'C', 0)",
    );
    await sql(
      "INSERT INTO importacoes (id, conta_id, formato, nome_arquivo, "
      "hash_arquivo, status, criado_em) VALUES ('i', 'c', 'ofx', 'a.ofx', "
      "'h', 'confirmada', 0)",
    );
    await sql(
      "INSERT INTO transacoes (id, conta_id, importacao_id, data, "
      "valor_centavos, descricao_raw, criado_em) VALUES ('t', 'c', 'i', "
      "'2026-08-03', 45000, 'PIX ANA', 0)",
    );
    await sql(
      "INSERT INTO lancamentos (id, transacao_id, competencia, "
      "data_recebimento, valor_centavos, classificacao, criado_em, "
      "atualizado_em) VALUES ('l', 't', '2026-08', '2026-08-03', 45000, "
      "'tributavel', 0, 0)",
    );
    await sql(
      "INSERT INTO backup_estado (id, ultima_seq, resultado) VALUES (1, 3, 'ok')",
    );
    // Do APARELHO, não da conta: o espelho do catálogo público fica.
    await sql("INSERT INTO cat_versoes VALUES ('feriados', 1, 0, 0, 'h')");
  }

  test('toda tabela do esquema fora cat_* está na lista da limpeza', () {
    final esquema = File('lib/dados/esquema.drift').readAsStringSync();
    final tabelas = {
      for (final m in RegExp(r'CREATE TABLE (\w+)').allMatches(esquema))
        m.group(1)!,
    };
    final daConta = tabelas.where((t) => !t.startsWith('cat_')).toSet();
    expect(daConta, isNotEmpty);
    expect(
      tabelasDaConta.toSet(),
      daConta,
      reason: 'tabela nova fora da lista sobreviveria à troca de conta',
    );
  });

  test(
    'apaga os dados da conta e as chaves do backup; o catálogo fica',
    () async {
      await popular();
      final cofre = CofreEmMemoria();
      final chaves = ChavesBackup(cofre: cofre, aleatorio: Random(1));
      await chaves.obterOuCriarChaveMestra();
      cofre
        ..valores[ChavesBackup.campoCabecalho] = 'cab'
        ..valores[ChavesBackup.campoImpressao] = 'imp'
        ..valores[ChaveBanco.campoCofre] = 'chave-do-banco';

      await LimpezaLocalDoApp(
        banco: banco,
        chaves: chaves,
      ).apagarDadosDaConta();

      for (final tabela in tabelasDaConta) {
        expect(await linhas(tabela), 0, reason: tabela);
      }
      expect(await linhas('cat_versoes'), 1, reason: 'catálogo é do aparelho');
      expect(
        cofre.valores.keys,
        [ChaveBanco.campoCofre],
        reason: 'só as chaves do backup saem; a do banco é do aparelho',
      );
      expect(await chaves.codigoConfirmado(), isFalse);
    },
  );

  test('cofre que não apaga: erro, e o banco fica inteiro', () async {
    await popular();
    final cofre = _CofreTeimoso();
    final chaves = ChavesBackup(cofre: cofre, aleatorio: Random(1));
    await chaves.obterOuCriarChaveMestra();

    await expectLater(
      LimpezaLocalDoApp(banco: banco, chaves: chaves).apagarDadosDaConta(),
      throwsA(isA<ChavesBackupException>()),
    );
    expect(await linhas('perfil'), 1);
    expect(await linhas('transacoes'), 1);
  });
}
