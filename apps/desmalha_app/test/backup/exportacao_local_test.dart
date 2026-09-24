/// Export → backup → import no banco local de verdade (Drift + SQLCipher
/// em memória): o conteúdo volta idêntico, a prévia de importação fica de
/// fora e uma restauração que quebraria uma FK não altera nada.
library;

import 'package:desmalha_app/backup/exportacao_local.dart';
import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _povoar(BancoLocal b) async {
  await b.customStatement(
    "INSERT INTO contas_bancarias (id, apelido, origem, ativa, criado_em) "
    "VALUES ('conta-1', 'Conta principal', 'manual', 1, 1789000000000)",
  );
  await b.customStatement(
    "INSERT INTO importacoes (id, conta_id, formato, nome_arquivo, "
    "hash_arquivo, previa_json, status, criado_em) VALUES ('imp-1', "
    "'conta-1', 'ofx', 'extrato.ofx', 'h1', '{\"segredo\":1}', 'confirmada', "
    "1789000000000)",
  );
  for (final (id, valor) in [('tx-1', 45000), ('tx-2', -12000)]) {
    await b.customStatement(
      "INSERT INTO transacoes (id, conta_id, importacao_id, data, "
      "valor_centavos, descricao_raw, fitid, criado_em) VALUES ('$id', "
      "'conta-1', 'imp-1', '2026-08-18', $valor, 'PIX $id', 'F$id', "
      "1789500000000)",
    );
  }
  await b.customStatement(
    "INSERT INTO aceites_termos_local (documento, versao, aceito_em, "
    "sincronizado) VALUES ('termos_uso', '2026-09-v1', 1789000000000, 1)",
  );
}

void main() {
  late BancoLocal origem;
  late BancoLocal destino;

  setUp(() {
    origem = BancoLocal(NativeDatabase.memory());
    destino = BancoLocal(NativeDatabase.memory());
  });

  tearDown(() async {
    await origem.close();
    await destino.close();
  });

  test('export → payload → import devolve as mesmas linhas', () async {
    await _povoar(origem);
    final docs = await ExportacaoLocal(origem).exportar();
    final payload = await serializarPayload(
      documentos: docs,
      appVersao: '1.0.0',
      schemaLocalVersao: 1,
      geradoEm: DateTime.utc(2026, 9, 24),
      seq: 1,
      plataforma: 'android',
    );
    final lido = await lerPayload(payload);
    await ExportacaoLocal(destino).importar(lido.documentos);

    final de = await ExportacaoLocal(origem).exportar();
    final para = await ExportacaoLocal(destino).exportar();
    expect(para.map((d) => d.toJson()).toList(),
        de.map((d) => d.toJson()).toList());
    expect(para.where((d) => d.tabela == 'transacoes'), hasLength(2));
  });

  test('a prévia de importação não entra no backup', () async {
    await _povoar(origem);
    final docs = await ExportacaoLocal(origem).exportar();
    final imp = docs.singleWhere((d) => d.tabela == 'importacoes');
    expect(imp.dados.containsKey('previa_json'), isFalse);
  });

  test('restaurar substitui o que havia no destino', () async {
    await _povoar(origem);
    await destino.customStatement(
      "INSERT INTO contas_bancarias (id, apelido, origem, ativa, criado_em) "
      "VALUES ('conta-velha', 'Antiga', 'manual', 1, 1)",
    );
    await ExportacaoLocal(destino)
        .importar(await ExportacaoLocal(origem).exportar());
    final contas = await destino
        .customSelect('SELECT id FROM contas_bancarias')
        .get();
    expect(contas.map((r) => r.data['id']), ['conta-1']);
  });

  test('referência quebrada: FALHA e o destino fica como estava', () async {
    await destino.customStatement(
      "INSERT INTO contas_bancarias (id, apelido, origem, ativa, criado_em) "
      "VALUES ('conta-velha', 'Antiga', 'manual', 1, 1)",
    );
    const quebrado = [
      DocumentoBackup('transacoes', {
        'id': 'tx-1',
        'conta_id': 'conta-que-nao-existe',
        'data': '2026-08-18',
        'valor_centavos': 1,
        'descricao_raw': 'x',
        'criado_em': 1,
      }),
    ];
    await expectLater(
      ExportacaoLocal(destino).importar(quebrado),
      throwsA(isA<FalhaRestauracao>()),
    );
    final contas = await destino
        .customSelect('SELECT id FROM contas_bancarias')
        .get();
    expect(contas.map((r) => r.data['id']), ['conta-velha'],
        reason: 'transação desfeita por inteiro');
  });

  test('a ordem de restauração cobre exatamente as tabelas do backup', () {
    expect(ordemDasTabelasDoBackup.toSet(), tabelasDoBackupV1);
  });
}
