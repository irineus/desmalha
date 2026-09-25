/// Aba Despesas — livro-caixa do mês (wireframe M8).
///
/// O que foi pago na competência, com o quanto de cada despesa deduz (a
/// trava de 20% da casa e as vedações vêm da rubrica do catálogo), e os
/// débitos do extrato do mês, que viram despesa com um toque (decisão 5 do
/// owner) — e, se o mesmo favorecido se repete, com a proposta em lote que
/// declara quantidade e valor antes de aplicar.
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
    if (!mounted) return;
    setState(() {
      _despesas = despesas;
      _debitos = debitos;
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
