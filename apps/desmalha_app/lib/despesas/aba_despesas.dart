/// Aba Despesas — livro-caixa do mês (wireframe M8).
///
/// O que foi pago na competência, com o quanto de cada despesa deduz (a
/// trava de 20% da casa e as vedações vêm da rubrica do catálogo), e os
/// débitos do extrato do mês, que viram despesa com um toque (decisão 5 do
/// owner) — e, se o mesmo favorecido se repete, com a proposta em lote que
/// declara quantidade e valor antes de aplicar.
///
/// Mais as outras deduções: o INSS pago no mês (principal e acréscimos
/// separados — só o principal deduz, rodada 4, P6) ou o "não paguei", e os
/// dependentes com a vigência (o mês inteiro conta, P7).
library;

import 'dart:async';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';

import '../importacao/tela_importacao.dart' show dataBr;
import '../lembretes/controlador_lembretes.dart' show competenciaPorExtenso;
import '../painel/controlador_painel.dart' show competenciaAnterior, competenciaDe;
import '../servicos_do_app.dart';
import '../tema/componentes.dart';
import '../tema/tipografia.dart';
import '../tema/tokens.dart';
import 'repositorio_despesas.dart';
import 'tela_nova_despesa.dart';

class AbaDespesas extends StatefulWidget {
  const AbaDespesas({super.key, required this.servicos, this.hoje});

  final ServicosDoApp servicos;

  /// Relógio para teste; padrão = agora.
  final DateTime Function()? hoje;

  @override
  State<AbaDespesas> createState() => _AbaDespesasState();
}

class _AbaDespesasState extends State<AbaDespesas> {
  late String _competencia;
  List<DespesaDoMes>? _despesas;
  List<DebitoDoExtrato> _debitos = const [];
  List<InssDoMes> _inss = const [];
  List<DependenteCadastrado> _dependentes = const [];

  RepositorioDespesas get _repo => widget.servicos.despesas;

  @override
  void initState() {
    super.initState();
    _competencia = competenciaDe((widget.hoje ?? DateTime.now)());
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
    final despesas = await _repo.despesasDoMes(_competencia);
    final debitos = await _repo.debitosDoMes(_competencia);
    final inss = await _repo.inssDoMes(_competencia);
    final dependentes = await _repo.dependentes();
    if (!mounted) return;
    setState(() {
      _despesas = despesas;
      _debitos = debitos;
      _inss = inss;
      _dependentes = dependentes;
    });
  }

  void _irPara(String competencia) {
    setState(() {
      _competencia = competencia;
      _despesas = null;
    });
    unawaited(_carregar());
  }

  Future<void> _nova({DebitoDoExtrato? debito}) async {
    final r = await Navigator.of(context).push<ResultadoNovaDespesa>(
      MaterialPageRoute(
        builder: (_) => TelaNovaDespesa(
          servicos: widget.servicos,
          debito: debito,
          competencia: _competencia,
        ),
      ),
    );
    widget.servicos.dadosAlterados.value++;
    if (r?.proposta != null && mounted) await _oferecer(r!.proposta!);
  }

  Future<void> _oferecer(PropostaDeDespesa p) async {
    final aceitar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Outros pagamentos iguais'),
        content: Text(
          'Há mais ${p.debitos.length == 1 ? '1 débito' : '${p.debitos.length} débitos'} '
          'para o mesmo favorecido no extrato. O app só lança se você '
          'confirmar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Agora não'),
          ),
          FilledButton(
            key: const Key('botao_aceitar_proposta_despesa'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(p.rotulo),
          ),
        ],
      ),
    );
    if (aceitar != true || !mounted) return;
    final ids = await _repo.aceitarProposta(p);
    widget.servicos.dadosAlterados.value++;
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${ids.length == 1 ? '1 despesa lançada' : '${ids.length} despesas lançadas'}.'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => unawaited(() async {
              for (final id in ids) {
                await _repo.excluir(id);
              }
              widget.servicos.dadosAlterados.value++;
            }()),
          ),
        ),
      );
  }

  Future<void> _excluir(DespesaDoMes d) async {
    await _repo.excluir(d.id);
    widget.servicos.dadosAlterados.value++;
  }

  Future<void> _alterou(Future<void> Function() acao) async {
    await acao();
    widget.servicos.dadosAlterados.value++;
  }

  Future<void> _informarInss() async {
    final r = await showDialog<({int principal, int acrescimos})>(
      context: context,
      builder: (_) => const _DialogoInss(),
    );
    if (r == null) return;
    await _alterou(() => _repo.registrarInssPago(
          competencia: _competencia,
          principalCentavos: r.principal,
          acrescimosCentavos: r.acrescimos,
        ));
  }

  Future<void> _adicionarDependente() async {
    final r = await showDialog<({String nome, String inicio})>(
      context: context,
      builder: (_) => _DialogoDependente(inicioSugerido: '$_competencia-01'),
    );
    if (r == null) return;
    await _alterou(
        () => _repo.adicionarDependente(nome: r.nome, inicio: r.inicio));
  }

  Future<void> _gerirDependente(DependenteCadastrado d) async {
    final acao = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(d.nome),
        content: const Text(
          'Se deixou de ser dependente, registre o último dia: o mês dele '
          'ainda conta inteiro.',
        ),
        actions: [
          TextButton(
            key: const Key('excluir_dependente'),
            onPressed: () => Navigator.of(context).pop('excluir'),
            child: const Text('Excluir'),
          ),
          if (d.fim != null)
            TextButton(
              onPressed: () => Navigator.of(context).pop('reabrir'),
              child: const Text('Continua dependente'),
            )
          else
            FilledButton(
              key: const Key('encerrar_dependente'),
              onPressed: () => Navigator.of(context).pop('encerrar'),
              child: const Text('Deixou de ser'),
            ),
        ],
      ),
    );
    if (!mounted) return;
    switch (acao) {
      case 'excluir':
        await _alterou(() => _repo.excluirDependente(d.id));
      case 'reabrir':
        await _alterou(() => _repo.encerrarDependente(d.id, null));
      case 'encerrar':
        final inicio = DateTime.parse(d.inicio);
        final hoje = (widget.hoje ?? DateTime.now)();
        final fim = await _escolherData(
          context,
          titulo: 'Último dia como dependente',
          inicial: inicio.isAfter(hoje) ? inicio : hoje,
          primeira: inicio,
        );
        if (fim != null) {
          await _alterou(() => _repo.encerrarDependente(d.id, fim));
        }
    }
  }

  String _contagemDeDependentes() {
    final n = dependentesNoMes(
      [
        for (final d in _dependentes)
          VigenciaDependente(inicio: d.inicio, fim: d.fim),
      ],
      _competencia,
    );
    final mes = competenciaPorExtenso(_competencia);
    return switch (n) {
      0 => 'Nenhum dependente em $mes.',
      1 => '1 dependente em $mes.',
      _ => '$n dependentes em $mes.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final fiscal = TipografiaFiscal.de(context);
    final despesas = _despesas;
    var dedutivel = 0;
    for (final d in despesas ?? const <DespesaDoMes>[]) {
      dedutivel += d.dedutivelCentavos;
    }
    final atual = competenciaDe((widget.hoje ?? DateTime.now)());
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(EspacosDesmalha.s4),
        children: [
          Text('Despesas', style: texto.headlineMedium),
          const SizedBox(height: EspacosDesmalha.s2),
          Row(
            children: [
              IconButton(
                key: const Key('despesas_mes_anterior'),
                tooltip: 'Mês anterior',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _irPara(competenciaAnterior(_competencia)),
              ),
              Expanded(
                child: Text(
                  competenciaPorExtenso(_competencia),
                  key: const Key('despesas_competencia'),
                  textAlign: TextAlign.center,
                  style: fiscal.rotulo,
                ),
              ),
              IconButton(
                key: const Key('despesas_mes_seguinte'),
                tooltip: 'Mês seguinte',
                icon: const Icon(Icons.chevron_right),
                onPressed: _competencia.compareTo(atual) >= 0
                    ? null
                    : () => _irPara(competenciaSeguinte(_competencia)),
              ),
            ],
          ),
          const SizedBox(height: EspacosDesmalha.s3),
          if (despesas == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text('Livro-caixa do mês', style: texto.titleMedium),
                ),
                ValorEmReais(
                  dedutivel,
                  key: const Key('despesas_total_dedutivel'),
                  estilo: fiscal.valor,
                ),
              ],
            ),
            Text('o quanto deduz, com a trava de 20% da casa aplicada',
                style: texto.bodySmall),
            const SizedBox(height: EspacosDesmalha.s3),
            if (despesas.isEmpty)
              EstadoVazio(
                key: const Key('despesas_vazio'),
                mensagem:
                    'Nenhuma despesa em ${competenciaPorExtenso(_competencia)}. '
                    'Aluguel da sala, conselho, material — tudo isso reduz o '
                    'imposto.',
                rotuloAcao: 'Adicionar despesa',
                aoAgir: () => unawaited(_nova()),
              )
            else ...[
              for (final d in despesas) _ItemDespesa(despesa: d, aoExcluir: _excluir),
              const SizedBox(height: EspacosDesmalha.s3),
              FilledButton(
                key: const Key('botao_nova_despesa'),
                onPressed: () => unawaited(_nova()),
                child: const Text('Adicionar despesa'),
              ),
            ],
            const SizedBox(height: EspacosDesmalha.s6),
            _SecaoInss(
              competencia: _competencia,
              inss: _inss,
              aoInformar: () => unawaited(_informarInss()),
              aoNaoPagar: () => unawaited(
                  _alterou(() => _repo.registrarInssNaoPago(_competencia))),
              aoExcluir: (id) =>
                  unawaited(_alterou(() => _repo.excluirInss(id))),
            ),
            const SizedBox(height: EspacosDesmalha.s6),
            Text('Dependentes', style: texto.titleMedium),
            Text(
              'Cada um conta o mês inteiro em que foi dependente, mesmo que '
              'por um dia só.',
              style: texto.bodySmall,
            ),
            const SizedBox(height: EspacosDesmalha.s2),
            Text(
              _contagemDeDependentes(),
              key: const Key('dependentes_no_mes'),
              style: fiscal.dado,
            ),
            for (final d in _dependentes)
              Card(
                child: ListTile(
                  key: Key('dependente_${d.id}'),
                  title: Text(d.nome),
                  subtitle: Text(
                    'desde ${dataBr(d.inicio)}'
                    '${d.fim == null ? '' : ' até ${dataBr(d.fim!)}'}',
                    style: fiscal.dado,
                  ),
                  onTap: () => unawaited(_gerirDependente(d)),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('botao_novo_dependente'),
                onPressed: () => unawaited(_adicionarDependente()),
                child: const Text('Adicionar dependente'),
              ),
            ),
            if (_debitos.isNotEmpty) ...[
              const SizedBox(height: EspacosDesmalha.s6),
              Text('Débitos do extrato', style: texto.titleMedium),
              Text(
                'Algum destes foi gasto da sua atividade? Toque para lançar no '
                'livro-caixa.',
                style: texto.bodySmall,
              ),
              const SizedBox(height: EspacosDesmalha.s2),
              for (final d in _debitos)
                Card(
                  child: ListTile(
                    key: Key('debito_${d.transacaoId}'),
                    title: Text(d.chave ?? d.descricao),
                    subtitle: Text(dataBr(d.data), style: fiscal.dado),
                    trailing: ValorEmReais(d.valorCentavos),
                    onTap: () => unawaited(_nova(debito: d)),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

Future<String?> _escolherData(
  BuildContext context, {
  required String titulo,
  required DateTime inicial,
  DateTime? primeira,
}) async {
  final d = await showDatePicker(
    context: context,
    helpText: titulo,
    initialDate: inicial,
    firstDate: primeira ?? DateTime(1900),
    lastDate: DateTime(inicial.year + 1, 12, 31),
  );
  if (d == null) return null;
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

class _SecaoInss extends StatelessWidget {
  const _SecaoInss({
    required this.competencia,
    required this.inss,
    required this.aoInformar,
    required this.aoNaoPagar,
    required this.aoExcluir,
  });

  final String competencia;
  final List<InssDoMes> inss;
  final VoidCallback aoInformar;
  final VoidCallback aoNaoPagar;
  final void Function(String id) aoExcluir;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final fiscal = TipografiaFiscal.de(context);
    final naoPago = [
      for (final i in inss)
        if (i.situacao == SituacaoInss.naoPago) i,
    ];
    final pagas = [
      for (final i in inss)
        if (i.situacao == SituacaoInss.pago) i,
    ];
    return Column(
      key: const Key('secao_inss'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INSS pago em ${competenciaPorExtenso(competencia)}',
          style: texto.titleMedium,
        ),
        Text(
          'Vale o mês em que a guia foi paga. Só o principal deduz — multa e '
          'juros de atraso não.',
          style: texto.bodySmall,
        ),
        const SizedBox(height: EspacosDesmalha.s2),
        if (naoPago.isNotEmpty)
          Row(
            children: [
              Expanded(
                child: Text(
                  'Você informou que não pagou INSS neste mês.',
                  key: const Key('inss_nao_pago'),
                  style: texto.bodyMedium,
                ),
              ),
              TextButton(
                key: const Key('inss_mudar_resposta'),
                onPressed: () => aoExcluir(naoPago.first.id),
                child: const Text('Mudar resposta'),
              ),
            ],
          )
        else ...[
          for (final g in pagas)
            Card(
              child: ListTile(
                key: Key('inss_${g.id}'),
                title: const Text('Guia paga'),
                subtitle: g.acrescimosCentavos > 0
                    ? Text(
                        'acréscimos de '
                        '${centavosParaExibicao(g.acrescimosCentavos)} '
                        'não deduzem',
                        style: fiscal.dado,
                      )
                    : null,
                trailing: ValorEmReais(g.principalCentavos),
                onTap: () => unawaited(() async {
                  final excluir = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Excluir esta guia?'),
                      content: const Text(
                        'Ela sai das deduções e o cálculo do mês refaz.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          key: const Key('confirmar_excluir_inss'),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Excluir'),
                        ),
                      ],
                    ),
                  );
                  if (excluir == true) aoExcluir(g.id);
                }()),
              ),
            ),
          Wrap(
            spacing: EspacosDesmalha.s2,
            children: [
              OutlinedButton(
                key: const Key('botao_inss_pago'),
                onPressed: aoInformar,
                child: Text(pagas.isEmpty ? 'Informar INSS pago' : 'Outra guia'),
              ),
              if (pagas.isEmpty)
                TextButton(
                  key: const Key('botao_inss_nao_pago'),
                  onPressed: aoNaoPagar,
                  child: const Text('Não paguei'),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DialogoInss extends StatefulWidget {
  const _DialogoInss();

  @override
  State<_DialogoInss> createState() => _DialogoInssState();
}

class _DialogoInssState extends State<_DialogoInss> {
  final _principal = TextEditingController();
  final _acrescimos = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _principal.dispose();
    _acrescimos.dispose();
    super.dispose();
  }

  void _confirmar() {
    final principal =
        parseValorMonetario(_principal.text, FormatoValor.virgulaDecimal);
    final acrescimos = _acrescimos.text.trim().isEmpty
        ? 0
        : parseValorMonetario(_acrescimos.text, FormatoValor.virgulaDecimal);
    if (principal == null || principal <= 0) {
      setState(() => _erro = 'Informe o valor principal da guia.');
      return;
    }
    if (acrescimos == null || acrescimos < 0) {
      setState(() => _erro = 'Os acréscimos não estão num formato válido.');
      return;
    }
    Navigator.of(context).pop((principal: principal, acrescimos: acrescimos));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('INSS pago'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('inss_principal'),
              controller: _principal,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: r'Valor principal da guia (R$)',
              ),
            ),
            TextField(
              key: const Key('inss_acrescimos'),
              controller: _acrescimos,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: r'Multa e juros, se pagou com atraso (R$)',
                helperText: 'Ficam registrados, mas não deduzem.',
              ),
            ),
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.only(top: EspacosDesmalha.s2),
                child: Text(_erro!, key: const Key('inss_erro')),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('confirmar_inss'),
          onPressed: _confirmar,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _DialogoDependente extends StatefulWidget {
  const _DialogoDependente({required this.inicioSugerido});

  final String inicioSugerido;

  @override
  State<_DialogoDependente> createState() => _DialogoDependenteState();
}

class _DialogoDependenteState extends State<_DialogoDependente> {
  final _nome = TextEditingController();
  late String _inicio = widget.inicioSugerido;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo dependente'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const Key('dependente_nome'),
            controller: _nome,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nome'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: EspacosDesmalha.s2),
          TextButton(
            key: const Key('dependente_inicio'),
            onPressed: () => unawaited(() async {
              final d = await _escolherData(
                context,
                titulo: 'Dependente desde',
                inicial: DateTime.parse(_inicio),
              );
              if (d != null && mounted) setState(() => _inicio = d);
            }()),
            child: Text('Dependente desde ${dataBr(_inicio)}'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('confirmar_dependente'),
          onPressed: _nome.text.trim().isEmpty
              ? null
              : () => Navigator.of(context)
                  .pop((nome: _nome.text.trim(), inicio: _inicio)),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _ItemDespesa extends StatelessWidget {
  const _ItemDespesa({required this.despesa, required this.aoExcluir});

  final DespesaDoMes despesa;
  final Future<void> Function(DespesaDoMes) aoExcluir;

  @override
  Widget build(BuildContext context) {
    final fiscal = TipografiaFiscal.de(context);
    final d = despesa;
    final r = d.rubrica;
    final parcial = d.dedutivelCentavos != d.valorCentavos;
    return Card(
      child: ListTile(
        key: Key('despesa_${d.id}'),
        title: Text(r?.nome ?? 'Rubrica fora do catálogo'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${dataBr(d.data)}'
              '${d.forma == FormaPagamentoDespesa.cartaoCredito ? ' · cartão (data da compra)' : ''}'
              '${d.doExtrato ? ' · extrato' : ''}',
              style: fiscal.dado,
            ),
            const SizedBox(height: EspacosDesmalha.s1),
            Wrap(
              spacing: EspacosDesmalha.s1,
              children: [
                if (r != null && !r.dedutivel)
                  const Selo('não dedutível', tipo: TipoSelo.neutro)
                else if (r?.travaResidencia ?? false)
                  const Selo('20% da casa', tipo: TipoSelo.ok),
                if (d.deRepasse) const Selo('custo de repasse', tipo: TipoSelo.ok),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ValorEmReais(d.valorCentavos),
            if (parcial)
              Text('deduz ${centavosParaExibicao(d.dedutivelCentavos)}',
                  style: fiscal.dado),
          ],
        ),
        onTap: d.deRepasse
            ? null
            : () => unawaited(() async {
                  final excluir = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Excluir esta despesa?'),
                      content: const Text(
                          'Ela sai do livro-caixa e o cálculo do mês refaz.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          key: const Key('confirmar_excluir_despesa'),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Excluir'),
                        ),
                      ],
                    ),
                  );
                  if (excluir == true) await aoExcluir(d);
                }()),
      ),
    );
  }
}
