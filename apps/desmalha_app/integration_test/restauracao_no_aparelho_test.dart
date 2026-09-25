/// A restauração pelo código NO APARELHO (decisão 10 do owner): backup
/// feito com uma chave-mestra no Keystore, Keystore apagado ("aparelho
/// novo"), restauração com o código — Argon2id real, banco SQLCipher —, a
/// mestra adotada no Keystore e o próximo backup abrindo com o MESMO
/// código.
///
///   fvm flutter test integration_test/restauracao_no_aparelho_test.dart -d emulator-5554
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

  testWidgets('aparelho novo restaura com o código e segue no mesmo código', (
    tester,
  ) async {
    const uid = '00000000-0000-4000-8000-0000000000fe';
    final armazenamento = ArmazenamentoFalso();
    ServicoBackup servico(BancoLocal banco, ChavesBackup chaves) =>
        ServicoBackup(
          porta: armazenamento,
          chaves: chaves,
          fonte: ExportacaoLocal(banco),
          usuarioId: () => uid,
          appVersao: '1.0.0',
        );

    // Aparelho antigo.
    final antigo = ChavesBackup(cofre: const CofreSeguroDoSistema());
    await antigo.esquecer();
    final codigo = gerarCodigoRecuperacao(Random.secure());
    await antigo.confirmarCodigo(codigo);
    final origem = BancoLocal(NativeDatabase.memory());
    await origem.customStatement(
      "INSERT INTO contas_bancarias (id, apelido, origem, ativa, criado_em) "
      "VALUES ('conta-1', 'Conta principal', 'manual', 1, 1)",
    );
    await origem.customStatement(
      "INSERT INTO transacoes (id, conta_id, data, valor_centavos, "
      "descricao_raw, criado_em) VALUES ('tx-1', 'conta-1', '2026-08-18', "
      "45000, 'PIX CLIENTE', 1)",
    );
    await servico(origem, antigo).fazerBackup();

    // Aparelho novo: Keystore vazio.
    await antigo.esquecer();
    final novo = ChavesBackup(cofre: const CofreSeguroDoSistema());
    final destino = BancoLocal(NativeDatabase.memory());

    await expectLater(
      servico(destino, novo)
          .restaurarComCodigo(gerarCodigoRecuperacao(Random.secure())),
      throwsA(isA<FalhaBackup>()),
    );
    expect(await novo.codigoConfirmado(), isFalse,
        reason: 'código errado não toca no Keystore');

    final relogio = Stopwatch()..start();
    await servico(destino, novo).restaurarComCodigo(codigo);
    // ignore: avoid_print
    print('RESTAURAR_COM_CODIGO_MS: ${relogio.elapsedMilliseconds}');
    final tx = await destino
        .customSelect('SELECT id, valor_centavos FROM transacoes')
        .get();
    expect(tx.single.data, {'id': 'tx-1', 'valor_centavos': 45000});
    expect(await novo.codigoConfirmado(), isTrue);
    expect(await novo.vinculadoAosBackups(), isTrue);

    final r = (await servico(destino, novo).fazerBackup())!;
    final bytes = armazenamento.objetos[ServicoBackup.caminhoDe(uid, r.seq)]!;
    final aberto = await abrirDsmbComCodigo(bytes, codigo);
    expect(
      (await lerPayload(aberto.conteudo))
          .documentos
          .where((d) => d.tabela == 'transacoes')
          .single
          .dados['id'],
      'tx-1',
      reason: 'o próximo backup abre com o mesmo código',
    );

    await novo.esquecer();
    await origem.close();
    await destino.close();
  });
}
