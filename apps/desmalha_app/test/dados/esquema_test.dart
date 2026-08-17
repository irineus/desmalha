/// O schema em execução, conferido contra o que o código gerado espera, e
/// as garantias que vivem no PRÓPRIO banco: FK ligada, transação imutável,
/// arquivo confirmado uma vez só — e os dois desvios da modelagem exigidos
/// pela decisão de deduplicação (17/ago/2026), fixados por teste para não
/// serem "corrigidos" de volta.
library;

import 'package:desmalha_app/dados/banco.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BancoLocal banco;

  setUp(() => banco = BancoLocal(NativeDatabase.memory()));
  tearDown(() => banco.close());

  test('o schema criado bate com o que o código gerado espera — mudou o '
      '.drift? é bump de schemaVersion + migração, nunca edição solta', () async {
    await banco.validateDatabaseSchema(
      options: const ValidationOptions(validateDropped: true),
    );
  });

  test('FK é de verdade, não decorativa (PRAGMA foreign_keys do beforeOpen)',
      () async {
    await expectLater(
      banco.into(banco.transacoes).insert(
            TransacoesCompanion.insert(
              id: 't1',
              contaId: 'conta-que-nao-existe',
              data: '2026-01-10',
              valorCentavos: 25000,
              descricaoRaw: 'PIX RECEBIDO',
              criadoEm: 1,
            ),
          ),
      throwsA(isA<SqliteException>()),
    );
  });

  group('com uma conta criada', () {
    setUp(() async {
      await banco.into(banco.contasBancarias).insert(
            ContasBancariasCompanion.insert(
              id: 'c1',
              apelido: 'Conta PJ… não, PF!',
              criadoEm: 1,
            ),
          );
    });

    Future<void> inserirTransacao(
      String id, {
      String data = '2026-01-10',
      int valorCentavos = 25000,
      String descricao = 'PIX RECEBIDO MARIA',
      String? fitid,
    }) {
      return banco.into(banco.transacoes).insert(
            TransacoesCompanion.insert(
              id: id,
              contaId: 'c1',
              data: data,
              valorCentavos: valorCentavos,
              descricaoRaw: descricao,
              fitid: Value(fitid),
              criadoEm: 1,
            ),
          );
    }

    test('transação bancária é imutável: UPDATE aborta com a mensagem do '
        'trigger', () async {
      await inserirTransacao('t1');
      await expectLater(
        (banco.update(banco.transacoes)..where((t) => t.id.equals('t1')))
            .write(const TransacoesCompanion(valorCentavos: Value(1))),
        throwsA(
          predicate(
            (e) => e.toString().contains('reclassifique o lançamento'),
          ),
        ),
      );
    });

    test('desvio 1 fixado: dois lançamentos com o MESMO fitid convivem — '
        'é o veredito identificadorRepetidoNoArquivo mantido pelo usuário',
        () async {
      await inserirTransacao('t1', fitid: 'FIT001');
      await inserirTransacao('t2', fitid: 'FIT001');
      final total = await banco.transacoes.count().getSingle();
      expect(total, 2);
    });

    test('desvio 2 fixado: dois Pix idênticos (data, valor, descrição) '
        'convivem — a trava é a CONTAGEM da conciliação, não um UNIQUE',
        () async {
      await inserirTransacao('t1');
      await inserirTransacao('t2');
      final total = await banco.transacoes.count().getSingle();
      expect(total, 2);
    });

    test('o mesmo arquivo não confirma duas vezes (uq_importacao_hash), mas '
        'prévia repetida do mesmo arquivo pode existir', () async {
      Future<void> inserirImportacao(String id, String status) {
        return banco.into(banco.importacoes).insert(
              ImportacoesCompanion.insert(
                id: id,
                contaId: 'c1',
                formato: 'ofx',
                nomeArquivo: 'extrato.ofx',
                hashArquivo: 'sha256-igual',
                status: Value(status),
                criadoEm: 1,
              ),
            );
      }

      await inserirImportacao('i1', 'confirmada');
      // Prévia com o mesmo hash não conflita: o índice é parcial.
      await inserirImportacao('i2', 'previa');
      // Confirmar a segunda é que estoura.
      await expectLater(
        (banco.update(banco.importacoes)..where((i) => i.id.equals('i2')))
            .write(const ImportacoesCompanion(status: Value('confirmada'))),
        throwsA(isA<SqliteException>()),
      );
    });
  });
}
