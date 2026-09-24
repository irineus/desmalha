import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../conta/porta_exclusao_conta.dart';
import '../conta/tela_exclusao_conta.dart';
import '../tema/componentes.dart';
import 'estado_auth.dart';
import 'porta_auth.dart';
import 'servico_auth.dart';

/// A conta: qual e-mail está em vigor, como trocá-lo e como sair.
///
/// A troca de e-mail aparece aqui com as duas confirmações explícitas na tela,
/// e não escondidas atrás de um "pronto!". O usuário precisa saber que a conta
/// só mudou quando os dois endereços responderem — inclusive porque, se ele
/// perder o acesso à caixa antiga no meio do caminho, a troca não se completa.
class TelaConta extends StatefulWidget {
  const TelaConta({super.key, required this.servico, required this.exclusao});

  final ServicoAutenticacao servico;
  final PortaExclusaoConta exclusao;

  @override
  State<TelaConta> createState() => _TelaContaState();
}

class _TelaContaState extends State<TelaConta> {
  final _novoEmail = TextEditingController();
  final _codigoAtual = TextEditingController();
  final _codigoNovo = TextEditingController();
  bool _ocupado = false;
  String? _erro;
  String? _aviso;

  @override
  void dispose() {
    _novoEmail.dispose();
    _codigoAtual.dispose();
    _codigoNovo.dispose();
    super.dispose();
  }

  /// Roda [acao] mostrando ocupado, e põe na tela o que ela devolver como
  /// aviso — ou a mensagem da falha, se der errado.
  Future<void> _executar(Future<String?> Function() acao) async {
    setState(() {
      _ocupado = true;
      _erro = null;
      _aviso = null;
    });
    try {
      final aviso = await acao();
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
    if (estado is! Autenticado) {
      // Acontece por um frame entre "sair" e o porteiro trocar de tela. Não é
      // espera por nada: um indicador de progresso aqui giraria para sempre
      // numa tela que já está de saída.
      return const SizedBox.shrink();
    }
    final troca = estado.troca;

    return Scaffold(
      appBar: AppBar(title: const Text('Sua conta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('E-mail da conta', style: _rotulo(context)),
                  const SizedBox(height: 4),
                  Text(
                    estado.usuario.email,
                    key: const Key('email_da_conta'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 32),
                  if (troca == null)
                    ..._solicitarTroca()
                  else
                    ..._confirmarTroca(troca),
                  const SizedBox(height: 32),
                  const Divider(),
                  TextButton(
                    key: const Key('botao_sair'),
                    onPressed: _ocupado
                        ? null
                        : () => _executar(() async {
                            await widget.servico.sair();
                            return null;
                          }),
                    child: const Text('Sair desta conta'),
                  ),
                  const SizedBox(height: 8),
                  // Exigência do Google Play: excluir a conta DENTRO do app,
                  // além da página web. Peso visual de ação destrutiva; a
                  // explicação e a confirmação ficam na tela seguinte.
                  OutlinedButton(
                    key: const Key('botao_excluir_conta'),
                    style: estiloBotaoDestrutivo(),
                    onPressed: _ocupado
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => TelaExclusaoConta(
                                servico: widget.servico,
                                exclusao: widget.exclusao,
                              ),
                            ),
                          ),
                    child: const Text('Excluir minha conta'),
                  ),
                  if (_erro != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _erro!,
                      key: const Key('erro_conta'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (_aviso != null) ...[
                    const SizedBox(height: 16),
                    Text(_aviso!, key: const Key('aviso_conta')),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextStyle? _rotulo(BuildContext context) =>
      Theme.of(context).textTheme.labelMedium;

  List<Widget> _solicitarTroca() => [
    Text('Trocar o e-mail', style: _rotulo(context)),
    const SizedBox(height: 8),
    const Text(
      'Vamos enviar um código para o endereço atual e outro para o novo. '
      'A conta só muda depois que os dois confirmarem.',
    ),
    const SizedBox(height: 16),
    TextField(
      key: const Key('campo_novo_email'),
      controller: _novoEmail,
      enabled: !_ocupado,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      decoration: const InputDecoration(
        labelText: 'Novo e-mail',
        border: OutlineInputBorder(),
      ),
    ),
    const SizedBox(height: 16),
    FilledButton(
      key: const Key('botao_solicitar_troca'),
      onPressed: _ocupado
          ? null
          : () => _executar(() async {
              await widget.servico.solicitarTrocaEmail(_novoEmail.text);
              _novoEmail.clear();
              return null;
            }),
      child: const Text('Pedir a troca'),
    ),
  ];

  List<Widget> _confirmarTroca(TrocaEmailEmCurso troca) => [
    Text('Troca em andamento', style: _rotulo(context)),
    const SizedBox(height: 8),
    Text(
      'Confirme nos dois endereços para que a conta passe a ser '
      '${troca.emailNovo}.',
    ),
    const SizedBox(height: 16),
    _campoDeConfirmacao(
      chave: 'campo_codigo_atual',
      chaveBotao: 'botao_confirmar_atual',
      rotulo: 'Código enviado para ${troca.emailAtual}',
      controlador: _codigoAtual,
      confirmado: troca.confirmadoAtual,
      email: troca.emailAtual,
    ),
    const SizedBox(height: 24),
    _campoDeConfirmacao(
      chave: 'campo_codigo_novo',
      chaveBotao: 'botao_confirmar_novo',
      rotulo: 'Código enviado para ${troca.emailNovo}',
      controlador: _codigoNovo,
      confirmado: troca.confirmadoNovo,
      email: troca.emailNovo,
    ),
  ];

  Widget _campoDeConfirmacao({
    required String chave,
    required String chaveBotao,
    required String rotulo,
    required TextEditingController controlador,
    required bool confirmado,
    required String email,
  }) {
    if (confirmado) {
      return Row(
        children: [
          const Icon(Icons.check),
          const SizedBox(width: 8),
          Expanded(child: Text('$email confirmado.')),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: Key(chave),
          controller: controlador,
          enabled: !_ocupado,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(tamanhoCodigoOtp),
          ],
          decoration: InputDecoration(
            labelText: rotulo,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          key: Key(chaveBotao),
          onPressed: _ocupado
              ? null
              : () => _executar(() async {
                  final concluida = await widget.servico.confirmarTrocaEmail(
                    email: email,
                    codigo: controlador.text,
                  );
                  controlador.clear();
                  return concluida ? 'E-mail da conta atualizado.' : null;
                }),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
