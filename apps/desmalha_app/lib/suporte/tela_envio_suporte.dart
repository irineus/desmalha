/// "Enviar este arquivo ao suporte" (decisão 11 do owner): só quando o app
/// não conseguiu ler o extrato. É a exceção única ao "nem nós conseguimos
/// ver seus dados" — por isso a tela diz, antes, exatamente o que sai, para
/// quê e por quanto tempo, e nada sai sem a marcação.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../importacao/controlador_importacao.dart' show ArquivoSelecionado;
import '../importacao/tela_importacao.dart' show dataBr;
import '../tema/componentes.dart';
import '../tema/tokens.dart';
import 'porta_suporte.dart';
import 'servico_suporte.dart';

class TelaEnvioSuporte extends StatefulWidget {
  const TelaEnvioSuporte({
    super.key,
    required this.servico,
    required this.arquivo,
    required this.motivo,
  });

  final ServicoSuporte servico;
  final ArquivoSelecionado arquivo;

  /// A falha de leitura que motivou o envio.
  final String motivo;

  @override
  State<TelaEnvioSuporte> createState() => _TelaEnvioSuporteState();
}

class _TelaEnvioSuporteState extends State<TelaEnvioSuporte> {
  final _banco = TextEditingController();
  bool _consentiu = false;
  bool _enviando = false;
  EnvioRegistrado? _enviado;
  String? _erro;

  @override
  void dispose() {
    _banco.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      final r = await widget.servico.enviarExtrato(
        widget.arquivo,
        motivo: 'Arquivo não lido na importação: ${widget.motivo}',
        bancoInformado: _banco.text,
      );
      if (mounted) setState(() => _enviado = r);
    } on FalhaEnvioSuporte catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  String _data(DateTime d) {
    final l = d.toLocal();
    return dataBr(
      '${l.year}-${l.month.toString().padLeft(2, '0')}-'
      '${l.day.toString().padLeft(2, '0')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final enviado = _enviado;
    return Scaffold(
      appBar: AppBar(title: const Text('Enviar ao suporte')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EspacosDesmalha.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: enviado != null
                ? [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Selo('enviado', tipo: TipoSelo.ok),
                    ),
                    const SizedBox(height: EspacosDesmalha.s3),
                    Text(
                      'Recebemos o arquivo. Ele é apagado automaticamente em '
                      '${_data(enviado.expiraEm)}.',
                      key: const Key('envio_concluido'),
                      style: texto.bodyLarge,
                    ),
                    const SizedBox(height: EspacosDesmalha.s4),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Voltar'),
                    ),
                  ]
                : [
                    Text(
                      'O app não conseguiu ler este arquivo. Você pode '
                      'mandá-lo ao suporte para descobrirmos o porquê.',
                      style: texto.bodyLarge,
                    ),
                    const SizedBox(height: EspacosDesmalha.s3),
                    BannerObrigacao(
                      key: const Key('escopo_envio'),
                      titulo: 'O que sai do seu celular',
                      texto: 'O arquivo "${widget.arquivo.nome}" exatamente '
                          'como veio do banco — com os nomes, CPFs e valores '
                          'de quem te pagou. É a única vez em que o app '
                          'manda seus dados para nós. Só o suporte vê, só '
                          'para corrigir a leitura de extratos, e o arquivo '
                          'é apagado automaticamente em 30 dias.',
                    ),
                    const SizedBox(height: EspacosDesmalha.s3),
                    TextField(
                      key: const Key('campo_banco_envio'),
                      controller: _banco,
                      decoration: const InputDecoration(
                        labelText: 'De qual banco é o extrato? (opcional)',
                      ),
                    ),
                    CheckboxListTile(
                      key: const Key('consentimento_envio'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _consentiu,
                      onChanged: _enviando
                          ? null
                          : (v) => setState(() => _consentiu = v ?? false),
                      title: const Text(
                        'Autorizo enviar este arquivo ao suporte, que o apaga '
                        'em 30 dias.',
                      ),
                    ),
                    if (_erro != null)
                      Text(
                        _erro!,
                        key: const Key('erro_envio'),
                        style: const TextStyle(color: CoresDesmalha.falha),
                      ),
                    const SizedBox(height: EspacosDesmalha.s3),
                    FilledButton(
                      key: const Key('botao_confirmar_envio'),
                      onPressed: _consentiu && !_enviando
                          ? () => unawaited(_enviar())
                          : null,
                      child: const Text('Enviar ao suporte'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Não enviar'),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}
