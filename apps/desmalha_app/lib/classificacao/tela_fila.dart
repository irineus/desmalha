/// Classificar um a um (wireframe M4): um recebimento por vez, com gesto e
/// com botões, e "Desfazer" visível por alguns segundos depois de cada
/// toque — gesto rápido erra, e o histórico é longe demais para corrigir.
///
/// Deslizar para a direita marca como cliente; para a esquerda, como
/// pessoal. Os botões dizem o mesmo por extenso (o gesto nunca é o único
/// caminho), e "Pular" deixa o item na fila.
library;

import 'dart:async';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';

import '../importacao/tela_importacao.dart' show dataBr;
import '../servicos_do_app.dart';
import '../tema/componentes.dart';
import '../tema/tipografia.dart';
import '../tema/tokens.dart';
import 'aba_lancamentos.dart' show classificacoesDeUmToque, nomeDaClassificacao;
import 'repositorio_classificacao.dart';

class TelaFila extends StatefulWidget {
  const TelaFila({super.key, required this.servicos});

  final ServicosDoApp servicos;

  @override
  State<TelaFila> createState() => _TelaFilaState();
}

class _TelaFilaState extends State<TelaFila> {
  List<ItemDaFila>? _itens;
  int _posicao = 0;

  RepositorioClassificacao get _repo => widget.servicos.classificacao;

  @override
  void initState() {
    super.initState();
    unawaited(_carregar());
  }

  Future<void> _carregar() async {
    // Só o que falta classificar: o "proposto pela regra" se confirma na
    // lista, com o toque dele.
    final fila = [
      for (final i in await _repo.fila())
        if (i.propostoPelaRegra == null) i,
    ];
    if (mounted) setState(() => _itens = fila);
  }

  ItemDaFila? get _atual {
    final itens = _itens;
    if (itens == null || _posicao >= itens.length) return null;
    return itens[_posicao];
  }

  Future<void> _classificar(ClassificacaoLancamento c) async {
    final item = _atual;
    if (item == null) return;
    final posicao = _posicao;
    final r = await _repo.classificar(
      item.transacaoId,
      RespostasClassificacao(classificacao: c),
    );
    widget.servicos.dadosAlterados.value++;
    if (!mounted) return;
    setState(() => _posicao++);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Marcado como ${nomeDaClassificacao(c).toLowerCase()}.'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => unawaited(_desfazer(r.lancamentoId, posicao)),
          ),
        ),
      );
  }

  Future<void> _desfazer(String lancamentoId, int posicao) async {
    await _repo.desfazerClassificacao(lancamentoId);
    widget.servicos.dadosAlterados.value++;
    if (mounted) setState(() => _posicao = posicao);
  }

  void _pular() => setState(() => _posicao++);

  @override
  Widget build(BuildContext context) {
    final itens = _itens;
    final atual = _atual;
    return Scaffold(
      appBar: AppBar(title: const Text('Classificar um a um')),
      body: SafeArea(
        child: itens == null
            ? const Center(child: CircularProgressIndicator())
            : atual == null
                ? Padding(
                    padding: const EdgeInsets.all(EspacosDesmalha.s4),
                    child: EstadoVazio(
                      key: const Key('fila_concluida'),
                      mensagem: itens.isEmpty
                          ? 'Nada esperando classificação.'
                          : 'Pronto: você passou por todos. O cálculo do mês '
                              'já conta com o que você separou.',
                      rotuloAcao: 'Voltar aos lançamentos',
                      aoAgir: () => Navigator.of(context).pop(),
                    ),
                  )
                : _cartao(context, atual, itens.length),
      ),
    );
  }

  Widget _cartao(BuildContext context, ItemDaFila item, int total) {
    final texto = Theme.of(context).textTheme;
    final fiscal = TipografiaFiscal.de(context);
    return ListView(
      padding: const EdgeInsets.all(EspacosDesmalha.s4),
      children: [
        Text(
          '${_posicao + 1} de $total',
          key: const Key('fila_progresso'),
          style: fiscal.rotulo,
        ),
        const SizedBox(height: EspacosDesmalha.s3),
        Dismissible(
          key: ValueKey('cartao_${item.transacaoId}'),
          onDismissed: (direcao) => unawaited(_classificar(
            direcao == DismissDirection.startToEnd
                ? ClassificacaoLancamento.rendimentoPf
                : ClassificacaoLancamento.pessoal,
          )),
          background: _fundoDoGesto('Cliente', Alignment.centerLeft),
          secondaryBackground: _fundoDoGesto('Pessoal', Alignment.centerRight),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(EspacosDesmalha.s5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.chaveRemetente ?? 'Sem nome na descrição',
                      style: texto.titleLarge),
                  const SizedBox(height: EspacosDesmalha.s1),
                  Text(item.descricao, style: fiscal.dado),
                  const SizedBox(height: EspacosDesmalha.s3),
                  Text(dataBr(item.data), style: fiscal.dado),
                  const SizedBox(height: EspacosDesmalha.s2),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ValorEmReais(item.valorCentavos, estilo: fiscal.valor),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: EspacosDesmalha.s2),
        Text(
          'Deslize para a direita se for cliente, para a esquerda se for '
          'pessoal — ou escolha abaixo.',
          style: texto.bodySmall,
        ),
        const SizedBox(height: EspacosDesmalha.s4),
        for (final c in classificacoesDeUmToque) ...[
          OutlinedButton(
            key: Key('fila_${c.name}'),
            onPressed: () => unawaited(_classificar(c)),
            child: Text(nomeDaClassificacao(c)),
          ),
          const SizedBox(height: EspacosDesmalha.s2),
        ],
        TextButton(
          key: const Key('fila_pular'),
          onPressed: _pular,
          child: const Text('Pular por enquanto'),
        ),
      ],
    );
  }

  Widget _fundoDoGesto(String rotulo, Alignment lado) => Container(
        alignment: lado,
        padding: const EdgeInsets.symmetric(horizontal: EspacosDesmalha.s5),
        decoration: BoxDecoration(
          color: CoresDesmalha.salviaClara,
          borderRadius: BorderRadius.circular(RaiosDesmalha.medio),
        ),
        child: Text(rotulo, style: const TextStyle(color: CoresDesmalha.salviaEscura)),
      );
}
