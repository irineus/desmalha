/// Banco local do Desmalha — Drift sobre SQLCipher.
///
/// O schema vive em `esquema.drift` (transcrição do DDL decidido na
/// modelagem local-first, ago/2026). Esta classe só orquestra: versão,
/// migrations e os pragmas por conexão.
///
/// ## Fronteira de arquitetura (não cruzar)
/// Regra fiscal e regra de comparação ficam no `desmalha_core` (Dart puro,
/// testável sem emulador). Drift e SQLCipher vivem aqui no app. A
/// persistência APLICA vereditos do core (ex.: `conciliarImportacao`);
/// nunca os reimplementa.
///
/// ## Como evoluir o schema (a v2 foi a primeira migração: ver [_migrarV1ParaV2])
/// 1. Editar `esquema.drift` e incrementar [schemaVersion].
/// 2. Escrever o passo em [migration] (`onUpgrade`).
/// 3. Exportar o snapshot da versão nova:
///    `fvm dart run drift_dev schema dump lib/dados/banco.dart drift_schemas/`
/// 4. Gerar os helpers de teste de migração:
///    `fvm dart run drift_dev schema generate drift_schemas/ test/dados/generated/`
///    e cobrir o caminho vN→vN+1 em `test/dados/migracao_test.dart`.
/// O teste `validateDatabaseSchema` reprova schema editado sem bump de
/// versão — mudar o `.drift` sem seguir os passos acima não passa em CI.
///
/// O schema local é independente do `formato_versao` do backup `.dsmb`
/// (regra 1 do versionamento do backup): refactor local não incrementa o
/// formato do envelope, e vice-versa.
library;

import 'package:drift/drift.dart';

part 'banco.g.dart';

@DriftDatabase(include: {'esquema.drift'})
class BancoLocal extends _$BancoLocal {
  BancoLocal(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, de, para) async {
          if (de < 2) await _migrarV1ParaV2(m);
        },
        beforeOpen: (details) async {
          // Por conexão, sempre — sem isto toda FK do schema é decorativa
          // (nota gravada no próprio DDL da modelagem).
          await customStatement('PRAGMA foreign_keys = ON;');
          if (details.hadUpgrade) {
            // As migrações rodam com FK desligada (o PRAGMA acima vem
            // DEPOIS delas): uma referência quebrada no caminho só apareceria
            // na próxima escrita. Aqui ela aparece na abertura, alto.
            final quebradas =
                await customSelect('PRAGMA foreign_key_check;').get();
            if (quebradas.isNotEmpty) {
              throw StateError(
                'migração ${details.versionBefore}→${details.versionNow} '
                'deixou ${quebradas.length} referência(s) quebrada(s): '
                '${quebradas.first.data}',
              );
            }
          }
        },
      );

  /// v1 → v2 (cadeia 2, decisão 6 do owner, 25/09/2026). Ver o cabeçalho de
  /// `esquema.drift`. Os valores de estado passam aos `.name` dos enums do
  /// desmalha_core; nada fiscal é inventado:
  ///
  /// - reembolso/repasse da v1 não guardavam em nome de quem estava o
  ///   comprovante nem a essencialidade, que a v2 exige (rodadas 2b e 4).
  ///   Esses lançamentos saem e o crédito volta à fila para ser classificado
  ///   com as perguntas — com registro na `auditoria`. Chutar a resposta
  ///   seria decidir a tributação pelo usuário.
  /// - `status_darf` da apuração é derivado das colunas que a v1 já tinha,
  ///   com a regra do DARF mínimo do motor (Lei 9.430/1996, art. 68).
  /// - a guia deixa de apontar para UMA apuração: vira linha em
  ///   `darf_competencias`.
  Future<void> _migrarV1ParaV2(Migrator m) async {
    // 1. Reembolso/repasse sem as respostas obrigatórias voltam à fila.
    await customStatement('''
      INSERT INTO auditoria (entidade, entidade_id, acao, detalhe, criado_em)
      SELECT 'lancamentos', id, 'excluir',
             json_object('motivo', 'migracao_v2_reclassificar',
                         'classificacao_v1', classificacao,
                         'transacao_id', transacao_id,
                         'valor_centavos', valor_centavos),
             CAST(strftime('%s','now') AS INTEGER) * 1000
        FROM lancamentos
       WHERE classificacao IN ('reembolso', 'repasse_terceiros');
    ''');
    await customStatement('''
      DELETE FROM historico_classificacao
       WHERE lancamento_id IN (SELECT id FROM lancamentos
                                WHERE classificacao IN ('reembolso', 'repasse_terceiros'));
    ''');
    await customStatement('''
      DELETE FROM lancamentos
       WHERE classificacao IN ('reembolso', 'repasse_terceiros');
    ''');
    for (final coluna in ['de', 'para']) {
      await customStatement('''
        UPDATE historico_classificacao SET $coluna = CASE $coluna
          WHEN 'tributavel' THEN 'rendimentoPf'
          WHEN 'repasse_terceiros' THEN 'repasse'
          ELSE $coluna END;
      ''');
    }

    // 2. DARF N:1: a ligação nasce da FK única antes de a coluna sair.
    await m.createTable(darfCompetencias);
    await customStatement('''
      INSERT INTO darf_competencias (darf_id, competencia, apuracao_id)
      SELECT d.id, a.competencia, d.apuracao_id
        FROM darfs d JOIN apuracoes_mensais a ON a.id = d.apuracao_id;
    ''');

    // 3. Tabelas reescritas com o esquema v2.
    await m.alterTable(TableMigration(perfil));
    await m.alterTable(TableMigration(
      remetentes,
      columnTransformer: {
        remetentes.chaveNome: const CustomExpression<String>('UPPER(TRIM(nome))'),
        remetentes.regraClassificacao: const CustomExpression<String>(
          "CASE classificacao_padrao WHEN 'tributavel' THEN 'rendimentoPf' "
          "WHEN 'pessoal' THEN 'pessoal' ELSE NULL END",
        ),
      },
      newColumns: [
        remetentes.chaveNome,
        remetentes.cnpj,
        remetentes.regraClassificacao,
        remetentes.regraConfirmadaEm,
      ],
    ));
    await m.alterTable(TableMigration(
      apuracoesMensais,
      columnTransformer: {
        apuracoesMensais.cenarioAplicado: const CustomExpression<String>(
          "CASE cenario_aplicado WHEN 'real' THEN 'deducoesReais' "
          "ELSE 'descontoSimplificado' END",
        ),
        apuracoesMensais.tabelaIrpfId:
            const CustomExpression<String>('CAST(tabela_irpf_id AS TEXT)'),
        apuracoesMensais.totalParaDarfCentavos: const CustomExpression<int>(
          'imposto_devido_centavos + imposto_diferido_anterior_centavos',
        ),
        apuracoesMensais.statusDarf: const CustomExpression<String>(
          'CASE WHEN imposto_devido_centavos + imposto_diferido_anterior_centavos = 0 '
          "THEN 'semImposto' "
          'WHEN imposto_devido_centavos + imposto_diferido_anterior_centavos >= 1000 '
          "THEN 'emitido' "
          "WHEN substr(competencia, 6, 2) = '12' THEN 'residuoParaDirpf' "
          "ELSE 'acumulaParaProximoMes' END",
        ),
      },
      newColumns: [
        apuracoesMensais.totalParaDarfCentavos,
        apuracoesMensais.statusDarf,
      ],
    ));
    await m.alterTable(TableMigration(
      lancamentos,
      columnTransformer: {
        lancamentos.classificacao: const CustomExpression<String>(
          "CASE classificacao WHEN 'tributavel' THEN 'rendimentoPf' "
          'ELSE classificacao END',
        ),
        lancamentos.origemClassificacao: const CustomExpression<String>(
          "CASE origem_classificacao WHEN 'sugestao_aceita' THEN 'sugestaoAceita' "
          "WHEN 'regra_remetente' THEN 'regraRemetente' ELSE 'manual' END",
        ),
        lancamentos.statusDocumentoPagador: const CustomExpression<String>(
          "CASE WHEN cpf_pagador IS NOT NULL THEN 'informado' "
          "ELSE 'naoExigido' END",
        ),
        // Na v1 toda classificação gravada foi um toque do usuário.
        lancamentos.confirmadaEm: const CustomExpression<int>('atualizado_em'),
      },
      newColumns: [
        lancamentos.comprovanteTitular,
        lancamentos.custoEssencial,
        lancamentos.cnpjPagador,
        lancamentos.statusDocumentoPagador,
        lancamentos.cpfBeneficiario,
        lancamentos.nomeBeneficiario,
        lancamentos.confirmadaEm,
      ],
    ));
    await m.alterTable(TableMigration(
      despesasLivroCaixa,
      newColumns: [
        despesasLivroCaixa.formaPagamento,
        despesasLivroCaixa.transacaoId,
        despesasLivroCaixa.lancamentoOrigemId,
        despesasLivroCaixa.exclusividadeDeclaradaEm,
      ],
    ));
    await m.alterTable(TableMigration(
      pagamentosInss,
      newColumns: [pagamentosInss.situacao, pagamentosInss.acrescimosCentavos],
    ));
    await m.alterTable(TableMigration(
      darfs,
      columnTransformer: {
        darfs.status: const CustomExpression<String>(
          "CASE status WHEN 'pago' THEN 'paga' WHEN 'cancelado' THEN 'cancelada' "
          "ELSE 'gerada' END",
        ),
      },
      newColumns: [darfs.acrescimosPagosCentavos],
    ));

    // 4. Índices: o alterTable recria os da v1; os novos e o que mudou de
    //    predicado ('gerado' → 'gerada') entram aqui.
    await customStatement('DROP INDEX IF EXISTS idx_darfs_venc;');
    await m.createIndex(idxDarfsVenc);
    await m.createIndex(uqRemetentesCnpj);
    await m.createIndex(uqRemetentesChaveNome);
    await m.createIndex(uqInssNaoPago);
    await m.createIndex(idxDarfCompetenciasComp);

    // 5. O catálogo local sai: filhas antes das mães.
    for (final tabela in const [
      'cat_faixas_irpf',
      'cat_tabelas_irpf',
      'cat_parametros_fiscais',
      'cat_feriados_bancarios',
      'cat_rubricas',
      'cat_profissoes',
      'cat_perfis_parser',
      'cat_versoes',
    ]) {
      await customStatement('DROP TABLE IF EXISTS $tabela;');
    }
  }
}
