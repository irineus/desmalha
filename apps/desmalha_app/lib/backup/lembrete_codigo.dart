/// Lembrete do código de recuperação (decisão 10 do owner — suposição do
/// owner, com veto antes do disparo): a cada 90 dias, redigitar 2 grupos
/// sorteados. Dispensável ("Agora não"), mas volta 90 dias depois.
///
/// Quem perde o aparelho E o código perde os dados, e nem o suporte ajuda.
/// Conferir de tempos em tempos é o que transforma "anotei em algum lugar"
/// em "sei onde está".
library;

import 'dart:async';
import 'dart:math';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';

import '../tema/componentes.dart';
import '../tema/tokens.dart';
import 'controlador_backup.dart';

/// O cartão no Mês, enquanto o lembrete está devido.
class LembreteCodigo extends StatelessWidget {
  const LembreteCodigo({super.key, required this.controlador, this.aleatorio});

  final ControladorBackup controlador;

  /// Só para teste: sorteio determinístico dos grupos.
  final Random? aleatorio;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controlador,
        builder: (context, _) {
          if (!controlador.lembreteCodigo) return const SizedBox.shrink();
          final texto = Theme.of(context).textTheme;
          return Card(
            key: const Key('lembrete_codigo'),
            child: Padding(
              padding: const EdgeInsets.all(EspacosDesmalha.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Confira seu código de recuperação',
                    style: texto.titleMedium,
                  ),
                  const SizedBox(height: EspacosDesmalha.s1),
                  Text(
                    'Faz 90 dias. Digite dois grupos do código que você '
                    'anotou — é ele que traz seus dados para um celular novo.',
                    style: texto.bodySmall,
                  ),
                  const SizedBox(height: EspacosDesmalha.s2),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          key: const Key('botao_conferir_codigo'),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => TelaConferirCodigo(
                                controlador: controlador,
                                aleatorio: aleatorio,
                              ),
                            ),
                          ),
                          child: const Text('Conferir'),
                        ),
                      ),
                      const SizedBox(width: EspacosDesmalha.s2),
                      Expanded(
                        child: OutlinedButton(
                          key: const Key('botao_adiar_lembrete'),
                          onPressed: () =>
                              unawaited(controlador.adiarLembreteCodigo()),
                          child: const Text('Agora não'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class TelaConferirCodigo extends StatefulWidget {
  const TelaConferirCodigo({
    super.key,
    required this.controlador,
    this.aleatorio,
  });

  final ControladorBackup controlador;
  final Random? aleatorio;

  @override
  State<TelaConferirCodigo> createState() => _TelaConferirCodigoState();
}

class _TelaConferirCodigoState extends State<TelaConferirCodigo> {
  late final List<int> _grupos = sortearGruposParaConfirmar(widget.aleatorio);
  final _campos = [TextEditingController(), TextEditingController()];
  final _completo = TextEditingController();

  /// O aparelho não tem verificador de grupos: pede o código inteiro.
  bool _pedirCompleto = false;
  bool _conferindo = false;
  String? _erro;

  @override
  void dispose() {
    for (final c in [..._campos, _completo]) {
      c.dispose();
    }
    super.dispose();
  }

  static const _naoConfere =
      'Não confere. Olhe de novo o que você anotou. Se perdeu o código, gere '
      'um novo em Ajustes > Backup — os próximos backups passam a abrir com '
      'ele.';

  Future<void> _conferir() async {
    setState(() {
      _conferindo = true;
      _erro = null;
    });
    final c = widget.controlador;
    final bool ok;
    if (_pedirCompleto) {
      ok = await c.conferirCodigoCompleto(_completo.text);
    } else {
      final r = await c.conferirGrupos({
        _grupos[0]: _campos[0].text,
        _grupos[1]: _campos[1].text,
      });
      if (r == null) {
        if (mounted) {
          setState(() {
            _pedirCompleto = true;
            _conferindo = false;
          });
        }
        return;
      }
      ok = r;
    }
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código conferido. Até daqui a 90 dias.')),
      );
      Navigator.of(context).pop();
    } else {
      setState(() {
        _erro = _naoConfere;
        _conferindo = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Conferir o código')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EspacosDesmalha.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_pedirCompleto) ...[
                Text(
                  'Este aparelho confere pelo código inteiro, uma vez. Leva '
                  'alguns segundos.',
                  style: texto.bodyLarge,
                ),
                TextField(
                  key: const Key('campo_codigo_completo'),
                  controller: _completo,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  decoration:
                      const InputDecoration(labelText: 'Código de recuperação'),
                ),
              ] else ...[
                Text(
                  'Digite os grupos ${_grupos[0] + 1} e ${_grupos[1] + 1} do '
                  'seu código.',
                  key: const Key('grupos_pedidos'),
                  style: texto.bodyLarge,
                ),
                for (var i = 0; i < 2; i++)
                  TextField(
                    key: Key('campo_grupo_$i'),
                    controller: _campos[i],
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Grupo ${_grupos[i] + 1}',
                    ),
                  ),
              ],
              if (_erro != null) ...[
                const SizedBox(height: EspacosDesmalha.s2),
                BannerObrigacao(
                  key: const Key('erro_conferencia'),
                  titulo: 'O código não confere.',
                  texto: _erro!,
                ),
              ],
              const SizedBox(height: EspacosDesmalha.s4),
              FilledButton(
                key: const Key('confirmar_conferencia'),
                onPressed: _conferindo ? null : () => unawaited(_conferir()),
                child: const Text('Conferir'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
