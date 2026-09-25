/// "Restaurar com o código de recuperação" (decisão 10 do owner): aparelho
/// novo, reinstalação ou troca entre Android e iPhone — o mesmo código
/// abre o backup em qualquer um.
///
/// O código é digitado, usado e esquecido: não é guardado. Abrir o backup
/// roda o Argon2id (alguns segundos), por isso a tela diz que demora.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../tema/componentes.dart';
import '../tema/tokens.dart';
import 'servico_backup.dart' show FalhaBackup;

class TelaRestaurar extends StatefulWidget {
  const TelaRestaurar({
    super.key,
    required this.restaurar,
    this.substituiDadosLocais = false,
  });

  /// Restaura com o código digitado; lança [FalhaBackup] se não der.
  final Future<void> Function(String codigo) restaurar;

  /// O aparelho já tem dados (a pessoa começou do zero e achou o código):
  /// a tela avisa que eles serão substituídos.
  final bool substituiDadosLocais;

  @override
  State<TelaRestaurar> createState() => _TelaRestaurarState();
}

class _TelaRestaurarState extends State<TelaRestaurar> {
  final _codigo = TextEditingController();
  bool _restaurando = false;
  String? _erro;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _restaurar() async {
    setState(() {
      _restaurando = true;
      _erro = null;
    });
    try {
      await widget.restaurar(_codigo.text);
      if (mounted) Navigator.of(context).pop(true);
    } on FalhaBackup catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _restaurando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurar backup')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EspacosDesmalha.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Digite o código de recuperação que você anotou. É ele que '
                'abre o seu backup — neste celular, em outro, em Android ou '
                'iPhone.',
                style: texto.bodyLarge,
              ),
              if (widget.substituiDadosLocais) ...[
                const SizedBox(height: EspacosDesmalha.s3),
                const BannerObrigacao(
                  key: Key('aviso_substitui_dados'),
                  titulo: 'O que está neste celular será substituído.',
                  texto: 'A restauração traz o backup inteiro no lugar dos '
                      'dados de agora.',
                ),
              ],
              const SizedBox(height: EspacosDesmalha.s4),
              TextField(
                key: const Key('campo_codigo_restauracao'),
                controller: _codigo,
                enabled: !_restaurando,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Código de recuperação',
                  helperText: 'Os 5 grupos, com ou sem os traços.',
                ),
              ),
              if (_erro != null) ...[
                const SizedBox(height: EspacosDesmalha.s2),
                Text(
                  _erro!,
                  key: const Key('erro_restauracao'),
                  style: const TextStyle(color: CoresDesmalha.falha),
                ),
              ],
              const SizedBox(height: EspacosDesmalha.s4),
              FilledButton(
                key: const Key('botao_restaurar'),
                onPressed: _restaurando ? null : () => unawaited(_restaurar()),
                child: _restaurando
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Restaurar'),
              ),
              if (_restaurando) ...[
                const SizedBox(height: EspacosDesmalha.s2),
                Text(
                  'Abrindo o backup com o seu código. Leva alguns segundos.',
                  style: texto.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
