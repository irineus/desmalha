/// Apaga do aparelho tudo o que pertence a uma conta: as tabelas do banco
/// local (perfil, extratos, lançamentos, apurações, aceites, estado do
/// backup...) e as chaves do backup no cofre do sistema.
///
/// Decisão do owner (24/09/2026, card "Dados locais pertencem à conta que os
/// criou"): outra conta só entra no aparelho depois de apagar os dados da
/// anterior. Fica o que é do APARELHO: a chave do banco cifrado e as tabelas
/// `cat_*` (espelho do catálogo público).
///
/// Não toca em nada do servidor: os backups da outra conta, se ela ainda
/// existir, continuam lá.
library;

import '../backup/chaves_backup.dart';
import 'banco.dart';

/// As tabelas da conta, na ordem de apagar (filhas antes das mães). Um
/// teste confere que TODA tabela do esquema fora `cat_*` está aqui: tabela
/// nova que escapasse da lista sobreviveria à troca de conta.
const List<String> tabelasDaConta = [
  'historico_classificacao',
  'lancamentos',
  'darfs',
  'despesas_livro_caixa',
  'apuracoes_mensais',
  'pagamentos_inss',
  'dependentes',
  'transacoes',
  'importacoes',
  'remetentes',
  'contas_bancarias',
  'notificacoes_locais',
  'backup_estado',
  'envios_suporte',
  'auditoria',
  'aceites_termos_local',
  'perfil',
];

abstract interface class LimpezaLocal {
  Future<void> apagarDadosDaConta();
}

class LimpezaLocalDoApp implements LimpezaLocal {
  LimpezaLocalDoApp({required this.banco, required this.chaves});

  final BancoLocal banco;
  final ChavesBackup chaves;

  @override
  Future<void> apagarDadosDaConta() async {
    // Chaves primeiro: se o cofre falhar, o banco continua inteiro e a tela
    // diz o erro — melhor que um banco vazio com a mestra antiga viva.
    await chaves.esquecer();
    await banco.transaction(() async {
      // `remetentes` referencia a si mesma (titular_remetente_id).
      await banco.customStatement('PRAGMA defer_foreign_keys = ON');
      for (final tabela in tabelasDaConta) {
        await banco.customStatement('DELETE FROM $tabela');
      }
    });
  }
}
