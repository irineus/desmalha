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
import '../tema/componentes.dart';
import '../tema/tokens.dart';
import 'casca.dart';

/// O que o porteiro põe em cada aba depois do login.
Widget conteudoDaAba(AbaDoApp aba, ServicoAutenticacao servico) =>
    switch (aba) {
      AbaDoApp.mes => const AbaProvisoria(
        titulo: 'Seu mês',
        mensagem: 'Aqui vai aparecer o imposto do mês, com o vencimento e o '
            'que falta resolver — calculado só sobre o que você classificar.',
      ),
      AbaDoApp.lancamentos => const AbaProvisoria(
        titulo: 'Lançamentos',
        mensagem: 'Os recebimentos do seu extrato aparecem aqui para você '
            'separar o que veio de cliente do que é pessoal.',
      ),
      AbaDoApp.despesas => const AbaProvisoria(
        titulo: 'Despesas',
        mensagem: 'Aluguel da sala, conselho, material — tudo isso reduz o '
            'imposto. O livro-caixa chega numa próxima versão.',
      ),
      AbaDoApp.ano => const AbaProvisoria(
        titulo: 'Seu ano',
        mensagem: 'O fechamento do ano, mês a mês, para a declaração — chega '
            'numa próxima versão.',
      ),
      AbaDoApp.ajustes => TelaAjustes(servico: servico),
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
  const TelaAjustes({super.key, required this.servico});

  final ServicoAutenticacao servico;

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
            subtitle: const Text('E-mail de acesso e saída'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TelaConta(servico: servico),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
