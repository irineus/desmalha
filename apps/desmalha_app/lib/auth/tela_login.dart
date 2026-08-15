import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'estado_auth.dart';
import 'porta_auth.dart';
import 'servico_auth.dart';

/// Entrada na conta: e-mail, depois o código que chegou nele.
///
/// Não há campo de senha nem botão de provedor social, e não é por enquanto:
/// ver `porta_auth.dart` e `test/auth/trava_sem_senha_test.dart`.
class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key, required this.servico});

  final ServicoAutenticacao servico;

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _email = TextEditingController();
  final _codigo = TextEditingController();
  bool _ocupado = false;
  String? _erro;
  String? _aviso;

  @override
  void dispose() {
    _email.dispose();
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _executar(Future<void> Function() acao, {String? aviso}) async {
    setState(() {
      _ocupado = true;
      _erro = null;
      _aviso = null;
    });
    try {
      await acao();
      if (mounted) setState(() => _aviso = aviso);
    } on FalhaAuth catch (falha) {
      if (mounted) setState(() => _erro = falha.mensagem);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = widget.servico.estado;
    final aguardando = estado is AguardandoCodigo;

    return Scaffold(
      appBar: AppBar(title: const Text('Entrar no Desmalha')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    aguardando
                        ? 'Enviamos um código de $tamanhoCodigoOtp dígitos para '
                              '${estado.email}.'
                        : 'Sua conta é o seu e-mail. Não existe senha: a cada '
                              'entrada enviamos um código.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  if (!aguardando) ..._camposEmail() else ..._camposCodigo(),
                  if (_erro != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _erro!,
                      key: const Key('erro_auth'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (_aviso != null) ...[
                    const SizedBox(height: 16),
                    Text(_aviso!, key: const Key('aviso_auth')),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _camposEmail() => [
    TextField(
      key: const Key('campo_email'),
      controller: _email,
      enabled: !_ocupado,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      autofillHints: const [AutofillHints.email],
      decoration: const InputDecoration(
        labelText: 'Seu e-mail',
        border: OutlineInputBorder(),
      ),
      onSubmitted: (_) => _enviar(),
    ),
    const SizedBox(height: 16),
    FilledButton(
      key: const Key('botao_enviar_codigo'),
      onPressed: _ocupado ? null : _enviar,
      child: Text(_ocupado ? 'Enviando…' : 'Enviar código'),
    ),
  ];

  List<Widget> _camposCodigo() => [
    TextField(
      key: const Key('campo_codigo'),
      controller: _codigo,
      enabled: !_ocupado,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(tamanhoCodigoOtp),
      ],
      autofillHints: const [AutofillHints.oneTimeCode],
      decoration: const InputDecoration(
        labelText: 'Código recebido',
        border: OutlineInputBorder(),
      ),
      onSubmitted: (_) => _confirmar(),
    ),
    const SizedBox(height: 16),
    FilledButton(
      key: const Key('botao_confirmar_codigo'),
      onPressed: _ocupado ? null : _confirmar,
      child: Text(_ocupado ? 'Confirmando…' : 'Entrar'),
    ),
    const SizedBox(height: 8),
    TextButton(
      key: const Key('botao_reenviar'),
      onPressed: _ocupado ? null : _reenviar,
      child: const Text('Reenviar código'),
    ),
    TextButton(
      key: const Key('botao_trocar_email_login'),
      onPressed: _ocupado ? null : _recomecar,
      child: const Text('Usar outro e-mail'),
    ),
  ];

  Future<void> _enviar() =>
      _executar(() => widget.servico.enviarCodigo(_email.text));

  Future<void> _confirmar() =>
      _executar(() => widget.servico.verificarCodigo(_codigo.text));

  Future<void> _reenviar() => _executar(
    widget.servico.reenviarCodigo,
    aviso: 'Código reenviado. Confira sua caixa de entrada.',
  );

  void _recomecar() {
    _codigo.clear();
    setState(() {
      _erro = null;
      _aviso = null;
      widget.servico.cancelarEnvio();
    });
  }
}
