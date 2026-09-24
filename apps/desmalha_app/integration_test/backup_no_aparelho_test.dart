/// O ciclo do backup NO APARELHO: chave-mestra no Keystore de verdade,
/// código confirmado (Argon2id real), export do banco SQLCipher do aparelho,
/// selagem, "upload" (armazenamento em memória com as regras do servidor),
/// prune, download, conferência e restauração num banco vazio.
///
///   fvm flutter test integration_test/backup_no_aparelho_test.dart
///
/// O servidor de verdade (bucket `backups` e `backups_metadados` pelo
/// gateway) é provado pelo workflow "Prova do gateway (dev)".
library;

import 'dart:math';

import 'package:desmalha_app/backup/chaves_backup.dart';
import 'package:desmalha_app/backup/exportacao_local.dart';
import 'package:desmalha_app/backup/servico_backup.dart';
import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/dados/chave_banco.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/backup/armazenamento_falso.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('backup e restauração no aparelho, com Keystore e SQLCipher', (
    tester,
  ) async {
    final chaves = ChavesBackup(cofre: const CofreSeguroDoSistema());
    final mestra1 = await chaves.obterOuCriarChaveMestra();
    final mestra2 = await chaves.obterOuCriarChaveMestra();
    expect(mestra2, mestra1, reason: 'o Keystore devolve a mesma mestra');

    final relogio = Stopwatch()..start();
    await chaves.confirmarCodigo(gerarCodigoRecuperacao(Random.secure()));
    // ignore: avoid_print
    print('CONFIRMAR_CODIGO_MS: ${relogio.elapsedMilliseconds}');

    final origem = BancoLocal(NativeDatabase.memory());
    final destino = BancoLocal(NativeDatabase.memory());
    final versao = await origem.customSelect('PRAGMA cipher_version;').get();
    expect(versao.single.data.values.first.toString(), isNotEmpty,
        reason: 'banco do aparelho com SQLCipher');
    await origem.customStatement(
      "INSERT INTO contas_bancarias (id, apelido, origem, ativa, criado_em) "
      "VALUES ('conta-1', 'Conta principal', 'manual', 1, 1)",
    );
    await origem.customStatement(
      "INSERT INTO transacoes (id, conta_id, data, valor_centavos, "
      "descricao_raw, criado_em) VALUES ('tx-1', 'conta-1', '2026-08-18', "
      "45000, 'PIX CLIENTE', 1)",
    );

    final armazenamento = ArmazenamentoFalso();
    ServicoBackup servico(BancoLocal banco) => ServicoBackup(
      porta: armazenamento,
      chaves: chaves,
      fonte: ExportacaoLocal(banco),
      usuarioId: () => '00000000-0000-4000-8000-0000000000ff',
      appVersao: '1.0.0',
    );

    for (var i = 0; i < 4; i++) {
      await servico(origem).fazerBackup();
    }
    expect(armazenamento.metadados.keys.toList()..sort(), [2, 3, 4]);

    await servico(destino).restaurarMaisRecente();
    final tx = await destino
        .customSelect('SELECT id, valor_centavos FROM transacoes')
        .get();
    expect(tx.single.data, {'id': 'tx-1', 'valor_centavos': 45000});

    await origem.close();
    await destino.close();
  });
}
