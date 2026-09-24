import 'dart:async';

import 'package:flutter/material.dart';

import '../importacao/tela_importacao.dart';
import '../navegacao/abas.dart';
import '../navegacao/casca.dart';
import '../onboarding/telas_onboarding.dart';
import '../servicos_do_app.dart';
import 'configuracao_supabase.dart';
import 'estado_auth.dart';
import 'servico_auth.dart';
import 'tela_login.dart';

/// Porteiro do app: mostra o login enquanto não há sessão e, depois, a casca
/// com as cinco abas (a conta mora em Ajustes).
class PortalAuth extends StatefulWidget {
  const PortalAuth({super.key, required this.servico, required this.servicos});

  final ServicoAutenticacao servico;

  /// O que as telas atrás do login usam (exclusão, chaves do backup...).
  final ServicosDoApp servicos;

  @override
  State<PortalAuth> createState() => _PortalAuthState();
}

class _PortalAuthState extends State<PortalAuth> {
  StreamSubscription<EstadoAuth>? _assinatura;

  /// Boas-vindas (O1) antes do login, até o toque em "Entrar". Quem já
  /// esteve na conta nesta execução (saiu, excluiu a conta) volta direto à
  /// tela de entrada — é lá que o aviso de conta excluída aparece.
  bool _querEntrar = false;

  @override
  void initState() {
    super.initState();
    _querEntrar = widget.servico.estado is! Deslogado;
    _assinatura = widget.servico.mudancas.listen((estado) {
      if (!mounted) return;
      // Saiu da conta com uma tela empilhada por cima (ex.: Ajustes > Sua
      // conta): sem este pop, o login ficaria ESCONDIDO atrás de uma tela que
      // já não tem conta para mostrar.
      if (estado is! Autenticado) {
        Navigator.of(context).popUntil((rota) => rota.isFirst);
      }
      if (estado is! Deslogado) _querEntrar = true;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _assinatura?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => switch (widget.servico.estado) {
    // Onboarding (e aceite de documento legal novo) antes do app; as rotinas
    // de abertura só depois dele — backup sem código confirmado não roda.
    Autenticado() => PorteiroOnboarding(
      servicos: widget.servicos,
      child: GatilhosDeAbertura(
        servicos: widget.servicos,
        child: CascaDoApp(
          construir: (aba) =>
              conteudoDaAba(aba, widget.servico, widget.servicos),
        ),
      ),
    ),
    AguardandoCodigo() => TelaLogin(servico: widget.servico),
    _ when !_querEntrar => TelaBoasVindas(
      aoEntrar: () => setState(() => _querEntrar = true),
    ),
    _ => TelaLogin(servico: widget.servico),
  };
}

/// Tela de um build sem configuração de servidor válida: sem
/// `SUPABASE_URL`/`SUPABASE_PUBLISHABLE_KEY`, ou com a URL apontando direto
/// para o Supabase em vez do gateway (ver `configuracao_supabase.dart`).
///
/// Diz o que está errado em vez de abrir um login que erraria na rede — a
/// mesma escolha da guia de DARF que sai sem código de barras: falhar visível
/// vale mais do que parecer funcionar.
class TelaSemConfiguracao extends StatelessWidget {
  const TelaSemConfiguracao({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.build_circle_outlined, size: 48),
              const SizedBox(height: 16),
              Text(
                'Build sem configuração de servidor',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${problemaDeConfiguracao ?? 'configuração inválida'}. '
                'Sem o endereço do gateway e a chave do tenant não há como '
                'entrar na conta — rode com '
                '--dart-define-from-file=<arquivo fora do repositório>.',
                key: const Key('motivo_sem_configuracao'),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Rotinas de abertura: ao entrar e a cada volta ao app.
///
/// - Backup automático — o dado só muda com o app aberto, então é aí que
///   ele pode ter mudado. A decisão (1× por dia, Wi-Fi, código confirmado,
///   conteúdo mudou) é da política, não daqui.
/// - Lembretes do DARF — reagendados com o catálogo local do momento, para
///   acompanhar feriado novo e o calendário do ano seguinte.
class GatilhosDeAbertura extends StatefulWidget {
  const GatilhosDeAbertura({
    super.key,
    required this.servicos,
    required this.child,
  });

  final ServicosDoApp servicos;
  final Widget child;

  @override
  State<GatilhosDeAbertura> createState() => _GatilhosDeAberturaState();
}

class _GatilhosDeAberturaState extends State<GatilhosDeAbertura>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _rodar();
    widget.servicos.arquivoRecebido.addListener(_abrirArquivoRecebido);
    // Abertura a frio: o arquivo pode ter chegado antes do login.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _abrirArquivoRecebido(),
    );
  }

  @override
  void dispose() {
    widget.servicos.arquivoRecebido.removeListener(_abrirArquivoRecebido);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// "Compartilhar → Desmalha": abre a importação já com o arquivo. Só
  /// aqui, atrás do login e do onboarding, porque a importação grava no
  /// banco da conta.
  Future<void> _abrirArquivoRecebido() async {
    final recebido = widget.servicos.arquivoRecebido.value;
    if (recebido == null || !mounted) return;
    widget.servicos.arquivoRecebido.value = null;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            TelaImportacao(servicos: widget.servicos, recebido: recebido),
      ),
    );
    widget.servicos.dadosAlterados.value++;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _rodar();
  }

  void _rodar() {
    unawaited(widget.servicos.backup.automatico());
    unawaited(widget.servicos.lembretes.sincronizar());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
