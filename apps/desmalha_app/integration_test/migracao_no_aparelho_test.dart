/// Prova NO APARELHO da migração v1 → v2: um arquivo SQLCipher criado com o
/// esquema v1 (o que está nos aparelhos de hoje) é reaberto pelo app v2, que
/// migra DENTRO do arquivo cifrado — `alterTable` recria tabelas, e o
/// arquivo precisa continuar cifrado e legível só com a chave.
///
/// Os testes de host provam a lógica da migração; este prova que ela roda no
/// SQLCipher do aparelho, com a mesma chave raw do boot.
///
///   fvm flutter test integration_test/migracao_no_aparelho_test.dart
library;

import 'dart:io';

import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/dados/conexao_cifrada.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../test/dados/generated/schema_v1.dart' as v1;

const _chave = 'a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1'
    'a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('arquivo cifrado v1 migra para v2 no aparelho', (tester) async {
    final dir = await getTemporaryDirectory();
    final arquivo = File(p.join(dir.path, 'migracao_v1.db'));
    if (arquivo.existsSync()) arquivo.deleteSync();
    addTearDown(() {
      if (arquivo.existsSync()) arquivo.deleteSync();
    });

    NativeDatabase conexao() => NativeDatabase(
          arquivo,
          setup: (db) => prepararCifra(db, _chave),
        );

    // 1. O banco como a v1 o deixa no aparelho.
    final antigo = v1.DatabaseAtV1(conexao());
    Future<void> sql(String s) => antigo.customStatement(s);
    await sql("INSERT INTO contas_bancarias (id, apelido, criado_em) "
        "VALUES ('c1', 'Conta', 1)");
    await sql('INSERT INTO transacoes (id, conta_id, data, valor_centavos, '
        "descricao_raw, criado_em) VALUES ('t1', 'c1', '2026-08-10', 45000, "
        "'PIX RECEBIDO MARIA', 1)");
    await sql('INSERT INTO lancamentos (id, transacao_id, competencia, '
        'data_recebimento, valor_centavos, classificacao, criado_em, '
        "atualizado_em) VALUES ('l1', 't1', '2026-08', '2026-08-10', 45000, "
        "'tributavel', 1, 2)");
    await sql('INSERT INTO apuracoes_mensais (id, competencia, '
        'receita_bruta_centavos, despesas_livro_caixa_centavos, inss_centavos, '
        'qtde_dependentes, deducao_dependentes_centavos, '
        'desconto_simplificado_centavos, imposto_cenario_real_centavos, '
        'imposto_cenario_simplificado_centavos, cenario_aplicado, '
        'base_calculo_centavos, aliquota_bp, parcela_deduzir_centavos, '
        'imposto_apurado_centavos, imposto_devido_centavos, tabela_irpf_id, '
        'catalogo_versoes_snapshot, parametros_snapshot, motor_versao, '
        "app_versao, calculada_em) VALUES ('ap', '2026-08', 45000, 0, 0, 0, 0, "
        "60720, 0, 0, 'simplificado', 0, 0, 0, 0, 0, 1, '{}', '{}', '1', '1', 1)");
    await sql('INSERT INTO darfs (id, apuracao_id, competencia, valor_centavos, '
        "vencimento, criado_em) VALUES ('g', 'ap', '2026-08', 0, '2026-09-30', 1)");
    await antigo.close();

    // 2. O app v2 abre o mesmo arquivo, com a mesma chave.
    final banco = BancoLocal(conexao());

    final versao =
        await banco.customSelect('PRAGMA user_version;').getSingle();
    expect(versao.data.values.first, 2);
    final cifra =
        await banco.customSelect('PRAGMA cipher_version;').get();
    expect(cifra, isNotEmpty, reason: 'o arquivo segue SQLCipher');

    final l = await banco
        .customSelect("SELECT classificacao, confirmada_em FROM lancamentos")
        .getSingle();
    expect(l.data, {'classificacao': 'rendimentoPf', 'confirmada_em': 2});
    final ligacao =
        await banco.customSelect('SELECT * FROM darf_competencias').getSingle();
    expect(ligacao.data['apuracao_id'], 'ap');
    final cat = await banco
        .customSelect("SELECT name FROM sqlite_master WHERE name LIKE 'cat_%'")
        .get();
    expect(cat, isEmpty);

    // 3. Em repouso, o arquivo migrado continua ilegível sem a chave.
    await banco.close();
    final cabecalho = arquivo.readAsBytesSync().take(15).toList();
    expect(String.fromCharCodes(cabecalho), isNot('SQLite format 3'));
  });
}
