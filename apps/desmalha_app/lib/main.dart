import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'auth/configuracao_supabase.dart';
import 'auth/porta_auth_supabase.dart';
import 'auth/portal_auth.dart';
import 'auth/servico_auth.dart';
import 'backup/chaves_backup.dart';
import 'backup/controlador_backup.dart';
import 'backup/estado_backup.dart';
import 'backup/exportacao_local.dart';
import 'backup/porta_armazenamento_backup_http.dart';
import 'backup/servico_backup.dart';
import 'catalogo/porta_catalogo_rest.dart';
import 'conta/porta_exclusao_conta_http.dart';
import 'catalogo/repositorio_catalogo.dart';
import 'classificacao/repositorio_classificacao.dart';
import 'dados/conexao_cifrada.dart';
import 'dados/limpeza_local.dart';
import 'dados/repositorio_importacao.dart';
import 'despesas/repositorio_despesas.dart';
import 'painel/repositorio_fechamento.dart';
import 'importacao/arquivo_recebido.dart';
import 'importacao/seletor_arquivo_sistema.dart';
import 'lembretes/controlador_lembretes.dart';
import 'lembretes/porta_notificacoes_locais.dart';
import 'monitoring.dart';
import 'onboarding/controlador_onboarding.dart';
import 'onboarding/porta_aceite_http.dart';
import 'onboarding/repositorio_onboarding.dart';
import 'navegacao/abas.dart';
import 'painel/repositorio_painel.dart';
import 'servicos_do_app.dart';
import 'tema/tema.dart';
import 'versao.dart';

Future<void> main() async {
  await bootstrap(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Antes de tudo que é rede: o banco local abre e a cifra é conferida.
    // Sem SQLCipher no binário, o app cai AQUI, ruidosamente — nunca segue
    // gravando dado fiscal em claro (ver conexao_cifrada.dart).
    await abrirBancoNoBoot();
    await inicializarSupabase();
    if (!supabaseConfigurado) {
      runApp(const DesmalhaApp(servico: null, servicos: null));
      return;
    }
    final catalogo = await _repositorioCatalogo();
    final lembretes = ControladorLembretes(
      porta: PortaNotificacoesLocais(),
      carregarCatalogo: catalogo.carregar,
    );
    // Em segundo plano, sem segurar o boot: o catálogo local (cache ou seed)
    // já serve qualquer cálculo; isto só o mantém fresco quando há rede.
    // Falhar é rotina (avião, servidor fora) e `atualizar()` devolve `false`
    // em vez de lançar. Se trouxe feriado ou ano novo, os lembretes são
    // reagendados com ele.
    unawaited(
      catalogo.atualizar().then((atualizou) {
        if (atualizou) return lembretes.sincronizar();
      }),
    );
    final arquivoRecebido = ValueNotifier<RecebimentoDeArquivo?>(null);
    unawaited(ArquivoRecebidoDoSistema(arquivoRecebido).iniciar());
    final portaAuth = PortaAuthSupabase.doClienteGlobal();
    final chavesBackup = ChavesBackup();
    runApp(
      DesmalhaApp(
        servico: ServicoAutenticacao(portaAuth),
        servicos: ServicosDoApp(
          exclusao: PortaExclusaoContaHttp(
            url: supabaseUrl,
            chavePublicavel: supabasePublishableKey,
            tokenDaSessao: () => portaAuth.tokenDeAcesso,
          ),
          chavesBackup: chavesBackup,
          backup: ControladorBackup(
            servico: () => ServicoBackup(
              porta: PortaArmazenamentoBackupHttp(
                url: supabaseUrl,
                chavePublicavel: supabasePublishableKey,
                tokenDaSessao: () => portaAuth.tokenDeAcesso,
              ),
              chaves: chavesBackup,
              fonte: ExportacaoLocal(bancoDoApp()),
              usuarioId: () => portaAuth.usuarioAtual?.id,
              appVersao: versaoDoApp,
            ),
            chaves: chavesBackup,
            estadoPersistido: RepositorioEstadoBackupDrift(bancoDoApp()),
            emWifi: _emWifi,
            comSessao: () => portaAuth.usuarioAtual != null,
          ),
          lembretes: lembretes,
          onboarding: ControladorOnboarding(
            repositorio: RepositorioOnboardingDrift(bancoDoApp()),
            aceite: PortaAceiteHttp(
              url: supabaseUrl,
              chavePublicavel: supabasePublishableKey,
              tokenDaSessao: () => portaAuth.tokenDeAcesso,
            ),
            carregarCatalogo: catalogo.carregar,
            usuarioId: () => portaAuth.usuarioAtual?.id,
            limpeza: LimpezaLocalDoApp(
              banco: bancoDoApp(),
              chaves: chavesBackup,
            ),
          ),
          importacao: RepositorioImportacao(bancoDoApp()),
          seletorDeArquivo: const SeletorDeArquivoDoSistema(),
          catalogo: catalogo.carregar,
          painel: RepositorioPainelDrift(bancoDoApp()),
          classificacao: RepositorioClassificacao(
            bancoDoApp(),
            catalogo: catalogo.carregar,
          ),
          despesas: RepositorioDespesas(
            bancoDoApp(),
            catalogo: catalogo.carregar,
          ),
          fechamento: RepositorioFechamento(bancoDoApp()),
          dadosAlterados: ValueNotifier(0),
          arquivoRecebido: arquivoRecebido,
        ),
      ),
    );
  });
}

/// Wi-Fi (ou cabo): o backup automático não gasta o plano de dados.
Future<bool> _emWifi() async {
  final redes = await Connectivity().checkConnectivity();
  return redes.contains(ConnectivityResult.wifi) ||
      redes.contains(ConnectivityResult.ethernet);
}

/// Repositório do catálogo versionado: rede → cache local → seed.
Future<RepositorioCatalogo> _repositorioCatalogo() async {
  final diretorio = await getApplicationSupportDirectory();
  return RepositorioCatalogo(
    remota: PortaCatalogoRest(
      url: supabaseUrl,
      chavePublicavel: supabasePublishableKey,
    ),
    arquivoCache: File('${diretorio.path}/catalogo_cache.json'),
  );
}

class DesmalhaApp extends StatelessWidget {
  const DesmalhaApp({super.key, required this.servico, required this.servicos});

  /// `null` num build sem configuração de servidor — ver [TelaSemConfiguracao].
  final ServicoAutenticacao? servico;
  final ServicosDoApp? servicos;

  @override
  Widget build(BuildContext context) {
    final servico = this.servico;
    final servicos = this.servicos;
    return MaterialApp(
      title: 'Desmalha',
      navigatorKey: chaveNavegadorDoApp,
      theme: temaDesmalha(),
      home: servico == null || servicos == null
          ? const TelaSemConfiguracao()
          : PortalAuth(servico: servico, servicos: servicos),
    );
  }
}
