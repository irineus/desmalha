import 'dart:async';

import 'package:flutter/material.dart';

import '../navegacao/abas.dart';
import '../navegacao/casca.dart';
import 'estado_auth.dart';
import 'servico_auth.dart';
import 'tela_login.dart';

/// Porteiro do app: mostra o login enquanto não há sessão e, depois, a casca
/// com as cinco abas (a conta mora em Ajustes).
class PortalAuth extends StatefulWidget {
  const PortalAuth({super.key, required this.servico});

  final ServicoAutenticacao servico;

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
    Autenticado() => CascaDoApp(
      construir: (aba) => conteudoDaAba(aba, widget.servico),
    ),
    _ => TelaLogin(servico: widget.servico),
  };
}

/// Tela de um build sem `SUPABASE_URL`/`SUPABASE_ANON_KEY`.
///
/// Diz o que está faltando em vez de abrir um login que erraria na rede — a
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
              const Text(
                'Este build não recebeu SUPABASE_URL e '
                'SUPABASE_PUBLISHABLE_KEY, então não há como entrar na conta. '
                'Rode com --dart-define para as duas variáveis.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
