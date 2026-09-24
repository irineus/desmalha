/// Export e import LÓGICOS do banco local — o conteúdo do backup.
///
/// Não é cópia do arquivo SQLite (acoplaria o backup ao schema físico): cada
/// linha das tabelas do backup vira um `DocumentoBackup`, e a restauração
/// reinsere linha a linha, numa transação, com as FKs conferidas no commit.
///
/// Tabelas e o que fica de fora: `tabelasDoBackupV1` no `desmalha_core`.
/// A `previa_json` das importações é estado de trabalho e sai do export.
library;

import 'package:desmalha_core/desmalha_core.dart';
import 'package:drift/drift.dart';

import '../dados/banco.dart';
import 'servico_backup.dart';

/// Ordem que respeita as referências (pai antes de filho). A restauração
/// apaga na ordem inversa e insere nesta.
const List<String> ordemDasTabelasDoBackup = [
  'perfil',
  'contas_bancarias',
  'importacoes',
  'transacoes',
  'remetentes',
  'apuracoes_mensais',
  'lancamentos',
  'historico_classificacao',
  'despesas_livro_caixa',
  'pagamentos_inss',
  'dependentes',
  'darfs',
  'aceites_termos_local',
];

/// Falha na restauração: nada foi aplicado (transação desfeita).
class FalhaRestauracao implements Exception {
  const FalhaRestauracao(this.mensagem);
  final String mensagem;
  @override
  String toString() => 'FalhaRestauracao: $mensagem';
}

class ExportacaoLocal implements FonteDocumentosBackup {
  ExportacaoLocal(this.banco);

  final BancoLocal banco;

  @override
  Future<int> versaoDoSchemaLocal() async => banco.schemaVersion;

  @override
  Future<List<DocumentoBackup>> exportar() async {
    final docs = <DocumentoBackup>[];
    for (final tabela in ordemDasTabelasDoBackup) {
      final linhas = await banco.customSelect('SELECT * FROM "$tabela"').get();
      for (final linha in linhas) {
        final dados = Map<String, Object?>.of(linha.data);
        if (tabela == 'importacoes') dados.remove('previa_json');
        docs.add(DocumentoBackup(tabela, dados));
      }
    }
    return docs;
  }

  @override
  Future<void> importar(List<DocumentoBackup> documentos) async {
    final porTabela = <String, List<DocumentoBackup>>{};
    for (final d in documentos) {
      if (!ordemDasTabelasDoBackup.contains(d.tabela)) {
        throw FalhaRestauracao('tabela fora do backup: ${d.tabela}');
      }
      (porTabela[d.tabela] ??= []).add(d);
    }
    try {
      await banco.transaction(() async {
        // FKs conferidas no COMMIT, não linha a linha: a ordem de inserção
        // deixa de importar, e uma referência quebrada derruba tudo.
        await banco.customStatement('PRAGMA defer_foreign_keys = ON;');
        for (final tabela in ordemDasTabelasDoBackup.reversed) {
          await banco.customStatement('DELETE FROM "$tabela";');
        }
        for (final tabela in ordemDasTabelasDoBackup) {
          for (final doc in porTabela[tabela] ?? const <DocumentoBackup>[]) {
            final colunas = doc.dados.keys.toList();
            await banco.customInsert(
              'INSERT INTO "$tabela" (${colunas.map((c) => '"$c"').join(', ')}) '
              'VALUES (${List.filled(colunas.length, '?').join(', ')})',
              variables: [
                for (final c in colunas) Variable<Object>(doc.dados[c]),
              ],
            );
          }
        }
      });
    } on Exception catch (e) {
      throw FalhaRestauracao(
        'a restauração não pôde ser aplicada e nada foi alterado: $e',
      );
    }
  }
}
