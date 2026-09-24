/// O conteúdo de cada aba enquanto as telas fiscais não chegam.
///
/// Cada aba provisória diz o que vai morar ali, em vez de uma tela em branco
/// que parece defeito. As telas de verdade entram pelos cards da Fase 5:
/// dashboard do mês, importação, DARF (e, fora desta cadeia, classificação,
/// livro-caixa e relatório anual).
library;

import 'package:flutter/material.dart';

import '../auth/servico_auth.dart';
import '../auth/tela_conta.dart';
import '../backup/tela_codigo_recuperacao.dart';
import '../servicos_do_app.dart';
import '../tema/componentes.dart';
import '../tema/tokens.dart';
import 'casca.dart';

/// O que o porteiro põe em cada aba depois do login.
Widget conteudoDaAba(
  AbaDoApp aba,
  ServicoAutenticacao servico,
  ServicosDoApp servicos,
) => switch (aba) {
  AbaDoApp.mes => const AbaProvisoria(
    titulo: 'Seu mês',
    mensagem:
        'Aqui vai aparecer o imposto do mês, com o vencimento e o '
        'que falta resolver — calculado só sobre o que você classificar.',
  ),
  AbaDoApp.lancamentos => const AbaProvisoria(
    titulo: 'Lançamentos',
    mensagem:
        'Os recebimentos do seu extrato aparecem aqui para você '
        'separar o que veio de cliente do que é pessoal.',
  ),
  AbaDoApp.despesas => const AbaProvisoria(
    titulo: 'Despesas',
    mensagem:
        'Aluguel da sala, conselho, material — tudo isso reduz o '
        'imposto. O livro-caixa chega numa próxima versão.',
  ),
  AbaDoApp.ano => const AbaProvisoria(
    titulo: 'Seu ano',
    mensagem:
        'O fechamento do ano, mês a mês, para a declaração — chega '
        'numa próxima versão.',
  ),
  AbaDoApp.ajustes => TelaAjustes(servico: servico, servicos: servicos),
};

/// Uma aba que ainda não tem tela: título + estado vazio honesto.
class AbaProvisoria extends StatelessWidget {
  const AbaProvisoria({
    super.key,
    required this.titulo,
    required this.mensagem,
  });

  final String titulo;
  final String mensagem;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(EspacosDesmalha.s4),
      children: [
        Text(titulo, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: EspacosDesmalha.s4),
        EstadoVazio(mensagem: mensagem),
      ],
    ),
  );
}

/// Ajustes: a conta hoje; backup e exclusão de conta entram pelos cards
/// seguintes.
class TelaAjustes extends StatelessWidget {
  const TelaAjustes({super.key, required this.servico, required this.servicos});

  final ServicoAutenticacao servico;
  final ServicosDoApp servicos;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(EspacosDesmalha.s4),
      children: [
        Text('Ajustes', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: EspacosDesmalha.s4),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Sua conta'),
            subtitle: const Text('E-mail de acesso, saída e exclusão'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    TelaConta(servico: servico, exclusao: servicos.exclusao),
              ),
            ),
          ),
        ),
        _ItemCodigoRecuperacao(servicos: servicos),
      ],
    ),
  );
}

/// Ajustes > Código de recuperação, com o estado atual escrito — sem código
/// confirmado o backup automático fica desligado, e isso aparece AQUI, não
/// só quando alguém procura.
class _ItemCodigoRecuperacao extends StatefulWidget {
  const _ItemCodigoRecuperacao({required this.servicos});

  final ServicosDoApp servicos;

  @override
  State<_ItemCodigoRecuperacao> createState() => _ItemCodigoRecuperacaoState();
}

class _ItemCodigoRecuperacaoState extends State<_ItemCodigoRecuperacao> {
  late Future<bool> _confirmado = widget.servicos.chavesBackup
      .codigoConfirmado();

  @override
  Widget build(BuildContext context) => Card(
    child: FutureBuilder<bool>(
      future: _confirmado,
      builder: (context, estado) {
        final confirmado = estado.data;
        return ListTile(
          key: const Key('item_codigo_recuperacao'),
          leading: const Icon(Icons.key_outlined),
          title: const Text('Código de recuperação'),
          subtitle: Text(switch (confirmado) {
            null => 'Conferindo…',
            true => 'Confirmado. Abre seus backups em outro celular.',
            false => 'Não configurado — o backup automático está desligado.',
          }),
          trailing: confirmado == false
              ? const Selo('pendente', tipo: TipoSelo.obrigacao)
              : const Icon(Icons.chevron_right),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<bool>(
                builder: (_) =>
                    TelaCodigoRecuperacao(chaves: widget.servicos.chavesBackup),
              ),
            );
            if (mounted) {
              setState(() {
                _confirmado = widget.servicos.chavesBackup.codigoConfirmado();
              });
            }
          },
        );
      },
    ),
  );
}
