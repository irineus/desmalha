/// Peças do fechamento usadas pela aba Mês e pela tela de DARF: o acerto
/// de uma guia paga, o histórico de pagamentos e o diálogo "paguei".
library;

import 'dart:async';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';

import '../importacao/tela_importacao.dart' show dataBr;
import '../lembretes/controlador_lembretes.dart' show competenciaPorExtenso;
import '../tema/componentes.dart';
import '../tema/tipografia.dart';
import '../tema/tokens.dart';
import 'repositorio_fechamento.dart';

/// O acerto de uma guia paga, nas palavras que a pessoa age: P8 →
/// complementar pelo SicalcWeb; P9 → pago a maior, acerto na declaração;
/// rodada 5 → P13 DARF próprio em atraso por competência, P14 diferença
/// abaixo de R$ 10,00 sem guia, P15 retificadora de ano anterior.
class AcertoDaGuiaNaTela extends StatelessWidget {
  const AcertoDaGuiaNaTela({
    super.key,
    required this.acerto,
    required this.pedeRetificadora,
  });

  final AcertoDaGuia acerto;
  final bool pedeRetificadora;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final retificadora = pedeRetificadora
        ? Padding(
            padding: const EdgeInsets.only(top: EspacosDesmalha.s2),
            child: Text(
              'Se você já entregou a declaração de '
              '${int.parse(acerto.guia.periodo.substring(0, 4)) + 1}, faça '
              'a retificadora com os valores novos: é ela que regulariza o '
              'ano, e também o caminho para reaver pagamento a maior.',
              key: const Key('acerto_retificadora'),
              style: texto.bodySmall,
            ),
          )
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [..._corpo(context, acerto), ?retificadora],
    );
  }

  List<Widget> _corpo(BuildContext context, AcertoDaGuia a) {
    final texto = Theme.of(context).textTheme;
    return switch (a) {
      AcertoEmDia() => const [],
      AcertoComplementar(:final competencia, :final diferencaCentavos) => [
          BannerObrigacao(
            key: const Key('acerto_complementar'),
            titulo: 'Falta pagar ${centavosParaExibicao(diferencaCentavos)} '
                'de ${competenciaPorExtenso(competencia)}.',
            texto: 'O recálculo ficou maior que o DARF pago. Gere o DARF '
                'complementar da competência '
                '${competenciaPorExtenso(competencia)} no SicalcWeb, que soma '
                'multa e juros. A diferença não vai para outro mês.',
          ),
        ],
      AcertoPagoAMaior(:final diferencaCentavos) => [
          Text(
            'Pago a maior: ${centavosParaExibicao(diferencaCentavos)}. O '
            'acerto é na declaração anual — o app não abate de outra guia.',
            key: const Key('acerto_pago_a_maior'),
            style: texto.bodyMedium,
          ),
        ],
      AcertoAbaixoDoMinimo(:final diferencaCentavos) => [
          BannerObrigacao(
            key: const Key('acerto_abaixo_do_minimo'),
            titulo: 'Diferença de ${centavosParaExibicao(diferencaCentavos)} '
                'a pagar, sem guia.',
            texto: 'Abaixo de R\$ 10,00 não sai DARF — a lei e o SicalcWeb '
                'não permitem. O valor é cobrado, com as correções, na '
                'declaração anual. Não o some a outra guia.',
          ),
        ],
      AcertoReagrupado(:final emAtraso, :final doPeriodo) => [
          for (final g in emAtraso)
            BannerObrigacao(
              key: Key('acerto_em_atraso_${g.competencia}'),
              titulo: '${competenciaPorExtenso(g.competencia)} passou a ter '
                  'DARF próprio: ${centavosParaExibicao(g.valorCentavos)}.',
              texto: 'A correção tirou o mês da guia de '
                  '${competenciaPorExtenso(a.guia.periodo)}. Gere o DARF da '
                  'competência ${competenciaPorExtenso(g.competencia)} no '
                  'SicalcWeb, que soma multa e juros, e marque como pago na '
                  'tela do mês.',
            ),
          ..._corpo(context, doPeriodo),
        ],
    };
  }
}

/// Os DARFs pagos do ano, do mais recente ao mais antigo.
class HistoricoDePagamentos extends StatelessWidget {
  const HistoricoDePagamentos({super.key, required this.pagamentos});

  final List<PagamentoDarf> pagamentos;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final fiscal = TipografiaFiscal.de(context);
    return Column(
      key: const Key('historico_pagamentos'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Pagamentos do ano', style: texto.titleMedium),
        for (final p in pagamentos)
          ListTile(
            key: Key('pagamento_${p.id}'),
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Período ${competenciaPorExtenso(p.periodo)}'
              '${p.competencias.length > 1 ? ' (inclui ${p.competencias.where((c) => c != p.periodo).map(competenciaPorExtenso).join(', ')})' : ''}',
            ),
            subtitle: Text(
              'pago em ${dataBr(p.pagoEm)}'
              '${p.acrescimosCentavos > 0 ? ' · mais ${centavosParaExibicao(p.acrescimosCentavos)} de multa e juros' : ''}',
              style: fiscal.dado,
            ),
            trailing: ValorEmReais(p.principalCentavos),
          ),
      ],
    );
  }
}

/// O que a pessoa informa ao marcar um DARF como pago.
class Pagamento {
  const Pagamento({
    required this.pagoEm,
    required this.principalCentavos,
    required this.acrescimosCentavos,
  });

  final String pagoEm;
  final int principalCentavos;

  /// Multa e juros: registrados, nunca contam como imposto pago (P11).
  final int acrescimosCentavos;
}

/// "Paguei": a data e, se pagou com atraso, a multa e os juros. O
/// principal é o da guia (ou o do complementar) e vem preenchido.
class DialogoPagamento extends StatefulWidget {
  const DialogoPagamento({
    super.key,
    required this.titulo,
    required this.principalCentavos,
    required this.hoje,
    required this.vencida,
  });

  final String titulo;
  final int principalCentavos;

  /// Data civil `'YYYY-MM-DD'`.
  final String hoje;
  final bool vencida;

  @override
  State<DialogoPagamento> createState() => _DialogoPagamentoState();
}

class _DialogoPagamentoState extends State<DialogoPagamento> {
  late String _pagoEm = widget.hoje;
  final _acrescimos = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _acrescimos.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final hoje = DateTime.parse(widget.hoje);
    final d = await showDatePicker(
      context: context,
      helpText: 'Data do pagamento',
      initialDate: DateTime.parse(_pagoEm),
      firstDate: DateTime(hoje.year - 6),
      lastDate: hoje,
    );
    if (d == null || !mounted) return;
    setState(() => _pagoEm = '${d.year}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}');
  }

  void _confirmar() {
    final acrescimos = _acrescimos.text.trim().isEmpty
        ? 0
        : parseValorMonetario(_acrescimos.text, FormatoValor.virgulaDecimal);
    if (acrescimos == null || acrescimos < 0) {
      setState(() => _erro = 'A multa e os juros não estão num formato válido.');
      return;
    }
    Navigator.of(context).pop(Pagamento(
      pagoEm: _pagoEm,
      principalCentavos: widget.principalCentavos,
      acrescimosCentavos: acrescimos,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final fiscal = TipografiaFiscal.de(context);
    return AlertDialog(
      title: Text(widget.titulo),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Principal')),
                ValorEmReais(widget.principalCentavos, estilo: fiscal.valor),
              ],
            ),
            TextButton(
              key: const Key('pagamento_data'),
              onPressed: () => unawaited(_escolherData()),
              child: Text('Pago em ${dataBr(_pagoEm)}'),
            ),
            if (widget.vencida)
              TextField(
                key: const Key('pagamento_acrescimos'),
                controller: _acrescimos,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: r'Multa e juros pagos (R$)',
                  helperText: 'Ficam registrados, mas não são imposto.',
                ),
              ),
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.only(top: EspacosDesmalha.s2),
                child: Text(
                  _erro!,
                  style: const TextStyle(color: CoresDesmalha.falha),
                ),
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
          key: const Key('confirmar_pagamento'),
          onPressed: _confirmar,
          child: const Text('Registrar pagamento'),
        ),
      ],
    );
  }
}
