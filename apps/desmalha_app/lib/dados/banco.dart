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
/// ## Como evoluir o schema (a partir da v2)
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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        beforeOpen: (details) async {
          // Por conexão, sempre — sem isto toda FK do schema é decorativa
          // (nota gravada no próprio DDL da modelagem).
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );
}
