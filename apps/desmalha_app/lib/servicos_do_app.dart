/// As portas e serviços que as telas atrás do login usam — num objeto só,
/// montado no `main.dart` com as implementações reais e nos testes com as
/// falsas. Uma tela nova pega daqui o que precisa, em vez de cada serviço
/// virar mais um parâmetro atravessando porteiro, casca e abas.
library;

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/foundation.dart';

import 'backup/chaves_backup.dart';
import 'classificacao/repositorio_classificacao.dart';
import 'backup/controlador_backup.dart';
import 'conta/porta_exclusao_conta.dart';
import 'dados/repositorio_importacao.dart';
import 'importacao/arquivo_recebido.dart';
import 'importacao/controlador_importacao.dart';
import 'painel/repositorio_painel.dart';
import 'lembretes/controlador_lembretes.dart';
import 'onboarding/controlador_onboarding.dart';

class ServicosDoApp {
  const ServicosDoApp({
    required this.exclusao,
    required this.chavesBackup,
    required this.backup,
    required this.lembretes,
    required this.onboarding,
    required this.importacao,
    required this.seletorDeArquivo,
    required this.catalogo,
    required this.painel,
    required this.classificacao,
    required this.dadosAlterados,
    required this.arquivoRecebido,
  });

  /// Exclusão da conta pelo app (Ajustes > Sua conta).
  final PortaExclusaoConta exclusao;

  /// Chave-mestra e código de recuperação do backup (Ajustes).
  final ChavesBackup chavesBackup;

  /// Estado, automático e "Fazer backup agora" (Ajustes > Backup).
  final ControladorBackup backup;

  /// Lembrete local de vencimento do DARF (Ajustes > Lembrete do DARF).
  final ControladorLembretes lembretes;

  /// Aceite dos documentos legais, perfil e conclusão do onboarding.
  final ControladorOnboarding onboarding;

  /// Importações de extrato e contas (aba Lançamentos).
  final RepositorioImportacao importacao;

  /// Seletor de arquivos do sistema (importação).
  final SeletorDeArquivo seletorDeArquivo;

  /// O catálogo versionado local (cache ou seed), sem rede.
  final Future<Catalogo> Function() catalogo;

  /// Agregados por competência para a aba Mês.
  final RepositorioPainel painel;

  /// Classificar recebimentos, propostas por remetente e regras.
  final RepositorioClassificacao classificacao;

  /// Sobe a cada importação confirmada: a aba Mês recalcula.
  final ValueNotifier<int> dadosAlterados;

  /// Extrato entregue por outro app ("Compartilhar → Desmalha"), à espera
  /// de ser aberto na importação quando o app estiver pronto.
  final ValueNotifier<RecebimentoDeArquivo?> arquivoRecebido;
}
