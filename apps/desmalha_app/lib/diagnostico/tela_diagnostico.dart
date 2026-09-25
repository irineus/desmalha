/// Diagnóstico para o suporte (decisão 11 do owner): a pessoa VÊ o que vai
/// sair antes de mandar, e manda pelo Compartilhar do sistema — o app não
/// envia nada sozinho.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';

import '../lembretes/controlador_lembretes.dart' show competenciaPorExtenso;
import '../painel/controlador_painel.dart'
    show competenciaAnterior, competenciaDe;
import '../painel/tela_darf.dart' show CompartilharArquivo, compartilharNoSistema;
import '../servicos_do_app.dart';
import '../tema/tipografia.dart';
import '../tema/tokens.dart';

class TelaDiagnostico extends StatefulWidget {
  const TelaDiagnostico({
    super.key,
    required this.servicos,
    this.hoje,
    this.compartilhar = compartilharNoSistema,
  });

  final ServicosDoApp servicos;
  final DateTime Function()? hoje;
  final CompartilharArquivo compartilhar;

  @override
  State<TelaDiagnostico> createState() => _TelaDiagnosticoState();
}

class _TelaDiagnosticoState extends State<TelaDiagnostico> {
  late String _competencia = competenciaDe((widget.hoje ?? DateTime.now)());
  ResumoDiagnostico? _resumo;
  String? _erro;

  @override
  void initState() {
    super.initState();
    unawaited(_carregar());
  }

  Future<void> _carregar() async {
    try {
      final catalogo = await widget.servicos.catalogo();
      final r = await widget.servicos.diagnostico.resumo(_competencia, catalogo);
      if (mounted) setState(() => _resumo = r);
    } on Exception catch (e) {
      if (mounted) setState(() => _erro = 'Não foi possível montar: $e');
    }
  }

  void _irPara(String c) {
    setState(() {
      _competencia = c;
      _resumo = null;
    });
    unawaited(_carregar());
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final fiscal = TipografiaFiscal.de(context);
    final atual = competenciaDe((widget.hoje ?? DateTime.now)());
    final r = _resumo;
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnóstico para o suporte')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EspacosDesmalha.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Se o cálculo de um mês parecer errado, mande este resumo ao '
                'suporte. Ele leva só números e versões: sem nomes, CPFs, '
                'CNPJs nem descrições do extrato. Confira abaixo exatamente '
                'o que sai.',
                style: texto.bodyMedium,
              ),
              const SizedBox(height: EspacosDesmalha.s3),
              Row(
                children: [
                  IconButton(
                    key: const Key('diagnostico_mes_anterior'),
                    tooltip: 'Mês anterior',
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _irPara(competenciaAnterior(_competencia)),
                  ),
                  Expanded(
                    child: Text(
                      competenciaPorExtenso(_competencia),
                      textAlign: TextAlign.center,
                      style: texto.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Mês seguinte',
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _competencia.compareTo(atual) >= 0
                        ? null
                        : () => _irPara(competenciaSeguinte(_competencia)),
                  ),
                ],
              ),
              const SizedBox(height: EspacosDesmalha.s2),
              if (_erro != null)
                Text(_erro!, style: const TextStyle(color: CoresDesmalha.falha))
              else if (r == null)
                const Center(child: CircularProgressIndicator())
              else ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: CoresDesmalha.neutroFundo,
                    borderRadius: BorderRadius.circular(RaiosDesmalha.medio),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(EspacosDesmalha.s3),
                    child: SelectableText(
                      r.texto,
                      key: const Key('conteudo_diagnostico'),
                      style: fiscal.dado,
                    ),
                  ),
                ),
                const SizedBox(height: EspacosDesmalha.s4),
                FilledButton(
                  key: const Key('botao_compartilhar_diagnostico'),
                  onPressed: () => unawaited(
                    widget.compartilhar(
                      Uint8List.fromList(utf8.encode(r.texto)),
                      'diagnostico-desmalha-$_competencia.json',
                      'application/json',
                    ),
                  ),
                  child: const Text('Compartilhar com o suporte'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
