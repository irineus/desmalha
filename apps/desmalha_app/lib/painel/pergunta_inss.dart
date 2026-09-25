/// A pergunta do INSS no dashboard (wireframe M1): "Você pagou INSS em
/// `<mês>?`. Só aparece enquanto o mês não tem resposta. "Paguei" pede o
/// principal e os acréscimos separados (rodada 4, P6); "Não paguei" fica
/// gravado — a resposta existe e o mês deduz zero (decisão 8 do owner).
///
/// Sem resposta o cálculo não trava: conta zero de INSS e a pergunta
/// segue como pendência (decisão 7).
library;

import 'dart:async';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';

import '../despesas/aba_despesas.dart' show DialogoInss;
import '../lembretes/controlador_lembretes.dart' show competenciaPorExtenso;
import '../servicos_do_app.dart';
import '../tema/tokens.dart';

class PerguntaInss extends StatefulWidget {
  const PerguntaInss({
    super.key,
    required this.servicos,
    required this.competencia,
  });

  final ServicosDoApp servicos;
  final String competencia;

  @override
  State<PerguntaInss> createState() => _PerguntaInssState();
}

class _PerguntaInssState extends State<PerguntaInss> {
  bool? _respondido;
  int? _referencia;

  @override
  void initState() {
    super.initState();
    widget.servicos.dadosAlterados.addListener(_recarregar);
    unawaited(_carregar());
  }

  @override
  void didUpdateWidget(PerguntaInss antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.competencia != widget.competencia) {
      _respondido = null;
      unawaited(_carregar());
    }
  }

  @override
  void dispose() {
    widget.servicos.dadosAlterados.removeListener(_recarregar);
    super.dispose();
  }

  void _recarregar() => unawaited(_carregar());

  Future<void> _carregar() async {
    final repo = widget.servicos.despesas;
    final respostas = await repo.inssDoMes(widget.competencia);
    final referencia = await repo.referenciaInss(widget.competencia);
    if (!mounted) return;
    setState(() {
      _respondido = respostas.isNotEmpty;
      _referencia = referencia;
    });
  }

  Future<void> _paguei() async {
    final r = await showDialog<({int principal, int acrescimos})>(
      context: context,
      builder: (_) => DialogoInss(principalSugeridoCentavos: _referencia),
    );
    if (r == null) return;
    await widget.servicos.despesas.registrarInssPago(
      competencia: widget.competencia,
      principalCentavos: r.principal,
      acrescimosCentavos: r.acrescimos,
    );
    widget.servicos.dadosAlterados.value++;
  }

  Future<void> _naoPaguei() async {
    await widget.servicos.despesas.registrarInssNaoPago(widget.competencia);
    widget.servicos.dadosAlterados.value++;
  }

  @override
  Widget build(BuildContext context) {
    if (_respondido != false) return const SizedBox.shrink();
    final texto = Theme.of(context).textTheme;
    return Card(
      key: const Key('pergunta_inss'),
      child: Padding(
        padding: const EdgeInsets.all(EspacosDesmalha.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Você pagou INSS em '
              '${competenciaPorExtenso(widget.competencia).split('/').first}?',
              style: texto.titleMedium,
            ),
            const SizedBox(height: EspacosDesmalha.s1),
            Text(
              '${_referencia == null ? '' : 'Referência: ${centavosParaExibicao(_referencia!)}. '}'
              'Só entra na dedução se saiu no mês.',
              key: const Key('pergunta_inss_referencia'),
              style: texto.bodySmall,
            ),
            const SizedBox(height: EspacosDesmalha.s2),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: const Key('m1_paguei'),
                    onPressed: () => unawaited(_paguei()),
                    child: const Text('Paguei'),
                  ),
                ),
                const SizedBox(width: EspacosDesmalha.s2),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('m1_nao_paguei'),
                    onPressed: () => unawaited(_naoPaguei()),
                    child: const Text('Não paguei'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
