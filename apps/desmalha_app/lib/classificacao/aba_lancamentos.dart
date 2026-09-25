/// Aba Lançamentos (wireframe M3): o que chegou do extrato, separado em
/// "A classificar", "Falta CPF" e "Prontos".
///
/// Regras do sistema visual e do card:
/// - classificação e CPF são estados independentes — os dois selos
///   convivem no mesmo item, e falta de CPF nunca bloqueia o cálculo;
/// - a proposta por remetente só se aplica com o botão que declara
///   quantidade e valor ("Marcar os outros 2 como cliente (R$ 900,00)"),
///   e toda ação tem desfazer;
/// - azul-obrigação só marca pendência fiscal; nada aqui é vermelho.
library;

import 'dart:async';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';

import '../dados/banco.dart';
import '../importacao/tela_importacao.dart';
import '../servicos_do_app.dart';
import '../tema/componentes.dart';
import '../tema/tipografia.dart';
import '../tema/tokens.dart';
import 'repositorio_classificacao.dart';
import 'tela_detalhe.dart';
import 'tela_fila.dart';
import 'tela_remetentes.dart';
import 'tela_repasse.dart';

/// As classificações que um toque resolve (reembolso e repasse pedem as
/// perguntas do detalhe).
const classificacoesDeUmToque = [
  ClassificacaoLancamento.rendimentoPf,
  ClassificacaoLancamento.recebidoPj,
  ClassificacaoLancamento.pessoal,
];

/// Como cada classificação aparece num botão ou selo.
String nomeDaClassificacao(ClassificacaoLancamento c) => switch (c) {
      ClassificacaoLancamento.rendimentoPf => 'Cliente',
      ClassificacaoLancamento.recebidoPj => 'Recebido de empresa',
      ClassificacaoLancamento.pessoal => 'Pessoal',
      ClassificacaoLancamento.reembolso => 'Reembolso',
      ClassificacaoLancamento.repasse => 'Repasse',
    };

String _explicacao(ClassificacaoLancamento c) => switch (c) {
      ClassificacaoLancamento.rendimentoPf =>
        'Pagamento de um atendimento seu. Entra no imposto do mês.',
      ClassificacaoLancamento.recebidoPj =>
        'Pago por empresa, sem imposto retido. Fica fora do cálculo do mês e '
            'vai para o relatório anual.',
      ClassificacaoLancamento.pessoal =>
        'Transferência sua, presente, devolução. Não entra em nada.',
      _ => '',
    };

class AbaLancamentos extends StatefulWidget {
  const AbaLancamentos({super.key, required this.servicos});

  final ServicosDoApp servicos;

  @override
  State<AbaLancamentos> createState() => _AbaLancamentosState();
}

class _AbaLancamentosState extends State<AbaLancamentos> {
  List<Importacao>? _importacoes;
  List<ItemDaFila> _fila = const [];
  List<LancamentoDaLista> _faltaCpf = const [];
  List<LancamentoDaLista> _prontos = const [];

  /// Proposta nascida da última classificação, com o remetente dela.
  ({PropostaDeRegra proposta, String remetenteId, String nome})? _proposta;

  RepositorioClassificacao get _repo => widget.servicos.classificacao;

  @override
  void initState() {
    super.initState();
    widget.servicos.dadosAlterados.addListener(_recarregar);
    unawaited(_carregar());
  }

  @override
  void dispose() {
    widget.servicos.dadosAlterados.removeListener(_recarregar);
    super.dispose();
  }

  void _recarregar() => unawaited(_carregar());

  Future<void> _carregar() async {
    final importacoes =
        await widget.servicos.importacao.importacoesConfirmadas();
    final fila = await _repo.fila();
    final faltaCpf = await _repo.classificados(soPendentesDeDocumento: true);
    final prontos = await _repo.classificados();
    if (!mounted) return;
    setState(() {
      _importacoes = importacoes;
      _fila = fila;
      _faltaCpf = faltaCpf;
      _prontos = prontos;
    });
  }

  /// Avisa o resto do app (aba Mês) e recarrega esta aba.
  void _mudou() => widget.servicos.dadosAlterados.value++;

  Future<void> _importar() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TelaImportacao(servicos: widget.servicos),
      ),
    );
    _mudou();
  }

  // ── Ações ─────────────────────────────────────────────────────────────

  Future<void> _classificar(
    ItemDaFila item,
    ClassificacaoLancamento classificacao,
  ) async {
    final r = await _repo.classificar(
      item.transacaoId,
      RespostasClassificacao(classificacao: classificacao),
    );
    if (!mounted) return;
    setState(() {
      _proposta = r.proposta == null
          ? null
          : (
              proposta: r.proposta!,
              remetenteId: r.remetenteId!,
              nome: item.chaveRemetente ?? '',
            );
    });
    _avisar(
      'Marcado como ${nomeDaClassificacao(classificacao).toLowerCase()}.',
      desfazer: () async {
        await _repo.desfazerClassificacao(r.lancamentoId);
        if (mounted) setState(() => _proposta = null);
        _mudou();
      },
    );
    _mudou();
  }

  Future<void> _aceitarProposta() async {
    final p = _proposta;
    if (p == null) return;
    final aceita = await _repo.aceitarProposta(p.proposta, p.remetenteId);
    if (!mounted) return;
    setState(() => _proposta = null);
    _avisar(
      '${p.proposta.quantidade == 1 ? '1 recebimento marcado' : '${p.proposta.quantidade} recebimentos marcados'} '
      'como ${rotuloDaClassificacao(p.proposta.classificacao)}.',
      desfazer: () async {
        await _repo.desfazer(aceita);
        _mudou();
      },
    );
    _mudou();
  }

  Future<void> _confirmarRegra(ItemDaFila item) async {
    await _repo.confirmar(item.lancamentoId!);
    _mudou();
  }

  void _avisar(String texto, {required Future<void> Function() desfazer}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(texto),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => unawaited(desfazer()),
          ),
        ),
      );
  }

  Future<void> _escolher(ItemDaFila item) async {
    final escolha = await showModalBottomSheet<ClassificacaoLancamento>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _EscolhaDeClassificacao(item: item),
    );
    if (escolha == null || !mounted) return;
    if (escolha == ClassificacaoLancamento.repasse) {
      // "Reembolso ou repasse": as perguntas do 2º passo (M6).
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => TelaRepasse(
            servicos: widget.servicos,
            transacaoId: item.transacaoId,
            data: item.data,
            valorCentavos: item.valorCentavos,
            nome: item.chaveRemetente,
          ),
        ),
      );
      return;
    }
    await _classificar(item, escolha);
  }

  Future<void> _abrirDetalhe(LancamentoDaLista l) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TelaDetalhe(
          servicos: widget.servicos,
          lancamentoId: l.lancamentoId,
        ),
      ),
    );
    _mudou();
  }

  Future<void> _abrirRemetentes() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TelaRemetentes(servicos: widget.servicos),
      ),
    );
    _mudou();
  }

  Future<void> _abrirFila() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TelaFila(servicos: widget.servicos),
      ),
    );
    _mudou();
  }

  // ── Tela ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final importacoes = _importacoes;
    return SafeArea(
      child: importacoes == null
          ? const Center(child: CircularProgressIndicator())
          : importacoes.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(EspacosDesmalha.s4),
                  children: [
                    Text('Lançamentos', style: texto.headlineMedium),
                    const SizedBox(height: EspacosDesmalha.s4),
                    EstadoVazio(
                      key: const Key('lancamentos_vazio'),
                      mensagem:
                          'Importe o extrato OFX ou CSV do seu banco. O '
                          'arquivo é lido neste celular e nunca sai dele.',
                      rotuloAcao: 'Importar extrato',
                      aoAgir: _importar,
                    ),
                  ],
                )
              : DefaultTabController(
                  length: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          EspacosDesmalha.s4,
                          EspacosDesmalha.s4,
                          EspacosDesmalha.s4,
                          0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text('Lançamentos',
                                  style: texto.headlineMedium),
                            ),
                            IconButton(
                              key: const Key('botao_remetentes'),
                              tooltip: 'Remetentes',
                              icon: const Icon(Icons.people_outline),
                              onPressed: _abrirRemetentes,
                            ),
                          ],
                        ),
                      ),
                      TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        tabs: [
                          Tab(
                            key: const Key('aba_a_classificar'),
                            text: 'A classificar ${_fila.length}',
                          ),
                          Tab(
                            key: const Key('aba_falta_cpf'),
                            text: 'Falta CPF ${_faltaCpf.length}',
                          ),
                          const Tab(
                            key: Key('aba_prontos'),
                            text: 'Prontos',
                          ),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _aClassificar(importacoes),
                            _listaFaltaCpf(),
                            _listaProntos(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _aClassificar(List<Importacao> importacoes) {
    final texto = Theme.of(context).textTheme;
    final proposta = _proposta;
    return ListView(
      padding: const EdgeInsets.all(EspacosDesmalha.s4),
      children: [
        if (proposta != null) ...[
          _BannerProposta(
            nome: proposta.nome,
            proposta: proposta.proposta,
            aoAceitar: _aceitarProposta,
            aoRecusar: () => setState(() => _proposta = null),
          ),
          const SizedBox(height: EspacosDesmalha.s4),
        ],
        if (_fila.isEmpty)
          const EstadoVazio(
            key: Key('fila_vazia'),
            mensagem:
                'Nenhum recebimento esperando classificação. O cálculo do mês '
                'já conta com tudo o que você separou.',
          )
        else ...[
          for (final item in _fila)
            _ItemDaFila(
              item: item,
              aoTocar: () => _escolher(item),
              aoConfirmarRegra: () => _confirmarRegra(item),
            ),
          const SizedBox(height: EspacosDesmalha.s3),
          FilledButton(
            key: const Key('botao_classificar_um_a_um'),
            onPressed: _abrirFila,
            child: const Text('Classificar um a um'),
          ),
        ],
        const SizedBox(height: EspacosDesmalha.s6),
        Text('Extratos importados', style: texto.titleMedium),
        const SizedBox(height: EspacosDesmalha.s2),
        for (final i in importacoes)
          Card(
            child: ListTile(
              title: Text(i.nomeArquivo),
              subtitle: Text(
                '${i.periodoInicio == null ? 'Sem lançamentos' : '${dataBr(i.periodoInicio!)} a ${dataBr(i.periodoFim!)}'}'
                ' · ${i.totalImportadas ?? 0} gravados'
                '${(i.totalDuplicadas ?? 0) > 0 ? ' · ${i.totalDuplicadas} já existiam' : ''}',
              ),
            ),
          ),
        const SizedBox(height: EspacosDesmalha.s3),
        OutlinedButton(
          key: const Key('botao_importar_outro'),
          onPressed: _importar,
          child: const Text('Importar outro extrato'),
        ),
      ],
    );
  }

  Widget _listaFaltaCpf() => ListView(
        padding: const EdgeInsets.all(EspacosDesmalha.s4),
        children: [
          if (_faltaCpf.isEmpty)
            const EstadoVazio(
              key: Key('falta_cpf_vazio'),
              mensagem: 'Nenhum recebimento esperando CPF do pagador.',
            )
          else ...[
            BannerObrigacao(
              titulo: _faltaCpf.length == 1
                  ? 'Um recebimento sem CPF do pagador.'
                  : '${_faltaCpf.length} recebimentos sem CPF do pagador.',
              texto:
                  'Sua profissão exige o CPF de quem pagou. O cálculo do mês '
                  'já conta esses valores — só o registro está incompleto.',
            ),
            const SizedBox(height: EspacosDesmalha.s4),
            for (final l in _faltaCpf)
              _ItemClassificado(lancamento: l, aoTocar: () => _abrirDetalhe(l)),
          ],
        ],
      );

  Widget _listaProntos() => ListView(
        padding: const EdgeInsets.all(EspacosDesmalha.s4),
        children: [
          if (_prontos.isEmpty)
            const EstadoVazio(
              key: Key('prontos_vazio'),
              mensagem: 'Os recebimentos classificados aparecem aqui.',
            )
          else
            for (final l in _prontos)
              _ItemClassificado(lancamento: l, aoTocar: () => _abrirDetalhe(l)),
        ],
      );
}

// ── Peças ───────────────────────────────────────────────────────────────

class _BannerProposta extends StatelessWidget {
  const _BannerProposta({
    required this.nome,
    required this.proposta,
    required this.aoAceitar,
    required this.aoRecusar,
  });

  final String nome;
  final PropostaDeRegra proposta;
  final VoidCallback aoAceitar;
  final VoidCallback aoRecusar;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final outros = proposta.quantidade == 1
        ? 'Há mais 1 recebimento'
        : 'Há mais ${proposta.quantidade} recebimentos';
    return Container(
      key: const Key('banner_proposta'),
      padding: const EdgeInsets.all(EspacosDesmalha.s4),
      decoration: BoxDecoration(
        color: CoresDesmalha.superficie,
        border: Border.all(color: CoresDesmalha.linha),
        borderRadius: BorderRadius.circular(RaiosDesmalha.medio),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$outros de ${nome.isEmpty ? 'quem pagou' : nome}. O app só marca '
            'se você confirmar.',
            style: texto.bodyMedium,
          ),
          const SizedBox(height: EspacosDesmalha.s3),
          FilledButton(
            key: const Key('botao_aceitar_proposta'),
            onPressed: aoAceitar,
            child: Text(proposta.rotulo),
          ),
          TextButton(
            key: const Key('botao_recusar_proposta'),
            onPressed: aoRecusar,
            child: const Text('Agora não'),
          ),
        ],
      ),
    );
  }
}

class _ItemDaFila extends StatelessWidget {
  const _ItemDaFila({
    required this.item,
    required this.aoTocar,
    required this.aoConfirmarRegra,
  });

  final ItemDaFila item;
  final VoidCallback aoTocar;
  final VoidCallback aoConfirmarRegra;

  @override
  Widget build(BuildContext context) {
    final fiscal = TipografiaFiscal.de(context);
    final regra = item.propostoPelaRegra;
    return Card(
      child: ListTile(
        key: Key('fila_${item.transacaoId}'),
        onTap: aoTocar,
        title: Text(item.chaveRemetente ?? item.descricao),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dataBr(item.data), style: fiscal.dado),
            const SizedBox(height: EspacosDesmalha.s1),
            if (regra == null)
              const Selo('a classificar', tipo: TipoSelo.obrigacao)
            else
              Selo(
                'proposto pela regra: ${nomeDaClassificacao(regra).toLowerCase()}',
                tipo: TipoSelo.obrigacao,
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValorEmReais(item.valorCentavos),
            if (regra != null)
              IconButton(
                key: Key('confirmar_regra_${item.transacaoId}'),
                tooltip: 'Confirmar',
                icon: const Icon(Icons.check),
                onPressed: aoConfirmarRegra,
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemClassificado extends StatelessWidget {
  const _ItemClassificado({required this.lancamento, required this.aoTocar});

  final LancamentoDaLista lancamento;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final fiscal = TipografiaFiscal.de(context);
    final l = lancamento;
    return Card(
      child: ListTile(
        key: Key('lancamento_${l.lancamentoId}'),
        onTap: aoTocar,
        title: Text(l.nome ?? 'Recebimento'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dataBr(l.data), style: fiscal.dado),
            const SizedBox(height: EspacosDesmalha.s1),
            Wrap(
              spacing: EspacosDesmalha.s1,
              runSpacing: EspacosDesmalha.s1,
              children: [
                Selo(
                  nomeDaClassificacao(l.classificacao).toLowerCase(),
                  tipo: l.classificacao == ClassificacaoLancamento.pessoal
                      ? TipoSelo.neutro
                      : TipoSelo.ok,
                ),
                if (l.statusDocumento == StatusDocumentoPagador.pendente)
                  const Selo('falta CPF', tipo: TipoSelo.obrigacao),
              ],
            ),
          ],
        ),
        trailing: ValorEmReais(l.valorCentavos),
      ),
    );
  }
}

class _EscolhaDeClassificacao extends StatelessWidget {
  const _EscolhaDeClassificacao({required this.item});

  final ItemDaFila item;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          EspacosDesmalha.s4,
          0,
          EspacosDesmalha.s4,
          EspacosDesmalha.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(item.chaveRemetente ?? item.descricao, style: texto.titleMedium),
            Text(
              '${dataBr(item.data)} · ${centavosParaExibicao(item.valorCentavos)}',
              style: TipografiaFiscal.de(context).dado,
            ),
            const SizedBox(height: EspacosDesmalha.s3),
            Text('Este recebimento é…', style: texto.bodyMedium),
            const SizedBox(height: EspacosDesmalha.s2),
            for (final c in classificacoesDeUmToque)
              Card(
                child: ListTile(
                  key: Key('escolher_${c.name}'),
                  title: Text(nomeDaClassificacao(c)),
                  subtitle: Text(_explicacao(c)),
                  onTap: () => Navigator.of(context).pop(c),
                ),
              ),
            Card(
              child: ListTile(
                key: const Key('escolher_reembolso_repasse'),
                title: const Text('Reembolso ou repasse'),
                subtitle: const Text(
                  'Você recebeu para cobrir um custo. Depende de em nome de '
                  'quem está a nota — o app pergunta.',
                ),
                trailing: const Icon(Icons.chevron_right),
                // O M6 decide entre reembolso e repasse; aqui só abre o fluxo.
                onTap: () =>
                    Navigator.of(context).pop(ClassificacaoLancamento.repasse),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
