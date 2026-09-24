import 'package:flutter/material.dart';

import '../auth/servico_auth.dart';
import '../tema/componentes.dart';
import '../tema/tokens.dart';
import 'porta_exclusao_conta.dart';

/// Excluir a conta: explica ANTES o que some e o que fica, exige confirmação
/// e só diz "excluída" quando o servidor confirmou.
///
/// A redação é a da página web pública (`pagina.ts`), não uma nova: são os
/// dois caminhos do mesmo ato, e divergir no texto seria prometer coisas
/// diferentes para a mesma exclusão.
class TelaExclusaoConta extends StatefulWidget {
  const TelaExclusaoConta({
    super.key,
    required this.servico,
    required this.exclusao,
  });

  final ServicoAutenticacao servico;
  final PortaExclusaoConta exclusao;

  @override
  State<TelaExclusaoConta> createState() => _TelaExclusaoContaState();
}

class _TelaExclusaoContaState extends State<TelaExclusaoConta> {
  bool _entendi = false;
  bool _ocupado = false;
  String? _erro;

  Future<void> _excluir() async {
    setState(() {
      _ocupado = true;
      _erro = null;
    });
    try {
      await widget.exclusao.excluirContaDaSessao();
    } on FalhaExclusaoConta catch (falha) {
      // A conta continua como estava. Dizer o contrário seria a única
      // resposta pior do que falhar.
      if (mounted) {
        setState(() {
          _ocupado = false;
          _erro = falha.mensagem;
        });
      }
      return;
    }
    // Confirmada pelo servidor: derruba a sessão local e volta à entrada.
    if (!mounted) return;
    final mensageiro = ScaffoldMessenger.maybeOf(context);
    await widget.servico.encerrarAposExclusao();
    mensageiro?.showSnackBar(
      const SnackBar(
        key: Key('aviso_conta_excluida'),
        content: Text('Conta excluída. Seus backups foram apagados.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final forte = texto.bodyMedium!.copyWith(fontWeight: FontWeight.w700);
    Widget item(String titulo, String corpo) => Padding(
      padding: const EdgeInsets.only(bottom: EspacosDesmalha.s3),
      child: Text.rich(
        TextSpan(
          style: texto.bodyMedium,
          children: [
            TextSpan(text: '$titulo ', style: forte),
            TextSpan(text: corpo),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Excluir minha conta')),
      body: SafeArea(
        // Rolagem que constrói tudo: a tela é curta, e o que a pessoa lê
        // antes de confirmar precisa existir inteiro (inclusive para teste).
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EspacosDesmalha.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'A exclusão é irreversível. Os backups são cifrados com uma '
                'chave que só você tem — nem nós conseguimos recuperá-los '
                'depois.',
                style: texto.bodyLarge,
              ),
              const SizedBox(height: EspacosDesmalha.s5),
              Text('O que acontece com cada coisa', style: texto.titleLarge),
              const SizedBox(height: EspacosDesmalha.s3),
              item(
                'Seus backups e qualquer arquivo enviado ao suporte:',
                'apagados ${PrazosExclusao.arquivos}.',
              ),
              item(
                'Sua conta e seu cadastro:',
                'a conta é bloqueada na hora e apagada em definitivo depois de '
                    '${PrazosExclusao.conta}.',
              ),
              item(
                'O registro de que você aceitou os termos:',
                'mantido por ${PrazosExclusao.aceite}, desvinculado do seu '
                    'cadastro. Ele deixa de apontar para você e passa a existir '
                    'só como prova de que o aceite ocorreu.',
              ),
              const SizedBox(height: EspacosDesmalha.s4),
              Text('O que fica no seu celular', style: texto.titleLarge),
              const SizedBox(height: EspacosDesmalha.s3),
              Text(
                'Seus lançamentos, o livro-caixa e as apurações nunca estiveram '
                'no nosso servidor — eles vivem cifrados dentro do aplicativo, '
                'neste aparelho. Excluir a conta não apaga esses dados do '
                'celular. Para eliminá-los, desinstale o aplicativo.',
                style: texto.bodyMedium,
              ),
              const SizedBox(height: EspacosDesmalha.s3),
              Text(
                'Se você ainda precisa deles, exporte antes: a lei exige que '
                'você guarde os comprovantes por cinco anos, e nós não teremos '
                'como devolvê-los.',
                style: texto.bodyMedium,
              ),
              const SizedBox(height: EspacosDesmalha.s5),
              CheckboxListTile(
                key: const Key('confirmo_exclusao'),
                value: _entendi,
                onChanged: _ocupado
                    ? null
                    : (v) => setState(() => _entendi = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Entendi que meus backups são apagados na hora e não podem '
                  'ser recuperados.',
                ),
              ),
              const SizedBox(height: EspacosDesmalha.s3),
              // Destrutivo: contorno vermelho, nunca preenchimento sálvia — a
              // ação primária desta tela é não fazer nada.
              OutlinedButton(
                key: const Key('botao_confirmar_exclusao'),
                style: estiloBotaoDestrutivo(),
                onPressed: _entendi && !_ocupado ? _excluir : null,
                child: _ocupado
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Excluir minha conta'),
              ),
              if (_erro != null) ...[
                const SizedBox(height: EspacosDesmalha.s4),
                Text(
                  _erro!,
                  key: const Key('erro_exclusao'),
                  style: texto.bodyMedium!.copyWith(color: CoresDesmalha.falha),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
