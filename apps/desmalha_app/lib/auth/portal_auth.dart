import 'dart:async';

import 'package:flutter/material.dart';

import '../navegacao/abas.dart';
import '../navegacao/casca.dart';
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

  @override
  void initState() {
    super.initState();
    _assinatura = widget.servico.mudancas.listen((estado) {
      if (!mounted) return;
      // Saiu da conta com uma tela empilhada por cima (ex.: Ajustes > Sua
      // conta): sem este pop, o login ficaria ESCONDIDO atrás de uma tela que
      // já não tem conta para mostrar.
      if (estado is! Autenticado) {
        Navigator.of(context).popUntil((rota) => rota.isFirst);
      }
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
    Autenticado() => GatilhoBackupAutomatico(
      servicos: widget.servicos,
      child: CascaDoApp(
        construir: (aba) => conteudoDaAba(aba, widget.servico, widget.servicos),
      ),
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

/// Dispara o backup automático ao entrar e a cada volta ao app — o dado só
/// muda com o app aberto, então é aí que ele pode ter mudado. A decisão (1×
/// por dia, Wi-Fi, código confirmado, conteúdo mudou) é da política, não
/// daqui.
class GatilhoBackupAutomatico extends StatefulWidget {
  const GatilhoBackupAutomatico({
    super.key,
    required this.servicos,
    required this.child,
  });

  final ServicosDoApp servicos;
  final Widget child;

  @override
  State<GatilhoBackupAutomatico> createState() =>
      _GatilhoBackupAutomaticoState();
}

class _GatilhoBackupAutomaticoState extends State<GatilhoBackupAutomatico>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(widget.servicos.backup.automatico());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.servicos.backup.automatico());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
