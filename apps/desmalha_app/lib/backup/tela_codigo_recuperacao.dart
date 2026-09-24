import 'dart:math';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';

import '../tema/componentes.dart';
import '../tema/tipografia.dart';
import '../tema/tokens.dart';
import 'chaves_backup.dart';

enum _Etapa { inicio, mostrando, confirmando, preparando, pronto }

/// Gerar, mostrar UMA vez e confirmar o código de recuperação.
///
/// Sem código confirmado o backup automático não liga (e a tela de backup
/// diz isso). O código nunca é guardado: sai da memória quando a tela fecha.
class TelaCodigoRecuperacao extends StatefulWidget {
  const TelaCodigoRecuperacao({
    super.key,
    required this.chaves,
    this.aleatorio,
  });

  final ChavesBackup chaves;

  /// Só para teste: sorteio determinístico do código e dos grupos.
  final Random? aleatorio;

  @override
  State<TelaCodigoRecuperacao> createState() => _TelaCodigoRecuperacaoState();
}

class _TelaCodigoRecuperacaoState extends State<TelaCodigoRecuperacao> {
  _Etapa _etapa = _Etapa.inicio;
  bool? _jaConfirmado;
  String? _codigo;
  List<int> _grupos = const [];
  final _campos = [TextEditingController(), TextEditingController()];
  String? _erro;

  @override
  void initState() {
    super.initState();
    widget.chaves.codigoConfirmado().then((v) {
      if (mounted) setState(() => _jaConfirmado = v);
    });
  }

  @override
  void dispose() {
    for (final c in _campos) {
      c.dispose();
    }
    super.dispose();
  }

  void _gerar() {
    setState(() {
      _codigo = gerarCodigoRecuperacao(widget.aleatorio);
      _grupos = sortearGruposParaConfirmar(widget.aleatorio);
      for (final c in _campos) {
        c.clear();
      }
      _erro = null;
      _etapa = _Etapa.mostrando;
    });
  }

  Future<void> _confirmar() async {
    final codigo = _codigo!;
    final confere = [
      for (var i = 0; i < 2; i++)
        grupoConfere(codigo, _grupos[i], _campos[i].text),
    ].every((ok) => ok);
    if (!confere) {
      setState(
        () => _erro =
            'Não confere com o código. Confira o que você '
            'anotou — ou gere outro código e anote de novo.',
      );
      return;
    }
    setState(() {
      _erro = null;
      _etapa = _Etapa.preparando;
    });
    try {
      await widget.chaves.confirmarCodigo(codigo);
      if (!mounted) return;
      setState(() {
        _codigo = null; // esquecido: não fica nem na memória da tela
        _etapa = _Etapa.pronto;
      });
    } on ChavesBackupException catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.mensagem;
        _etapa = _Etapa.confirmando;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final fiscal = TipografiaFiscal.de(context);
    Widget p(String t) => Padding(
      padding: const EdgeInsets.only(bottom: EspacosDesmalha.s3),
      child: Text(t, style: texto.bodyMedium),
    );

    final conteudo = switch (_etapa) {
      _Etapa.inicio => [
        p(
          'O código de recuperação abre seus backups em outro celular — se '
          'este se perder, quebrar ou for trocado. Ele aparece uma única '
          'vez: você anota à mão e guarda longe do celular.',
        ),
        p(
          'Sem ele e sem este aparelho, ninguém consegue abrir seus backups '
          '— nem nós. É isso que mantém seus dados só seus.',
        ),
        if (_jaConfirmado == true)
          const BannerObrigacao(
            titulo: 'Você já tem um código confirmado.',
            texto:
                'Gerar outro faz os PRÓXIMOS backups abrirem só com o '
                'novo; os já enviados continuam abrindo com o antigo.',
          ),
        const SizedBox(height: EspacosDesmalha.s4),
        FilledButton(
          key: const Key('botao_gerar_codigo'),
          onPressed: _gerar,
          child: const Text('Gerar meu código'),
        ),
      ],
      _Etapa.mostrando => [
        p(
          'Anote exatamente como aparece, em papel. Ele não será mostrado de '
          'novo.',
        ),
        Container(
          padding: const EdgeInsets.all(EspacosDesmalha.s4),
          decoration: BoxDecoration(
            color: CoresDesmalha.superficie,
            border: Border.all(color: CoresDesmalha.linha),
            borderRadius: BorderRadius.circular(RaiosDesmalha.medio),
          ),
          child: SelectableText(
            _codigo!.replaceAll('-', '  '),
            key: const Key('codigo_recuperacao'),
            textAlign: TextAlign.center,
            style: fiscal.valor.copyWith(fontSize: 22, letterSpacing: 1.5),
          ),
        ),
        const SizedBox(height: EspacosDesmalha.s4),
        FilledButton(
          key: const Key('botao_ja_anotei'),
          onPressed: () => setState(() => _etapa = _Etapa.confirmando),
          child: const Text('Já anotei'),
        ),
      ],
      _Etapa.confirmando => [
        p(
          'Para confirmar que ficou anotado, digite dois grupos do seu '
          'código.',
        ),
        for (var i = 0; i < 2; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: EspacosDesmalha.s3),
            child: TextField(
              key: Key('campo_grupo_$i'),
              controller: _campos[i],
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              style: fiscal.valorLinha.copyWith(fontSize: 18),
              decoration: InputDecoration(
                labelText: '${_grupos[i] + 1}º grupo (de 5)',
              ),
            ),
          ),
        if (_erro != null)
          Padding(
            padding: const EdgeInsets.only(bottom: EspacosDesmalha.s3),
            child: Text(
              _erro!,
              key: const Key('erro_codigo'),
              style: texto.bodyMedium!.copyWith(color: CoresDesmalha.falha),
            ),
          ),
        FilledButton(
          key: const Key('botao_confirmar_codigo_recuperacao'),
          onPressed: _confirmar,
          child: const Text('Confirmar código'),
        ),
        TextButton(
          key: const Key('botao_gerar_outro'),
          onPressed: _gerar,
          child: const Text('Perdi a anotação: gerar outro código'),
        ),
      ],
      _Etapa.preparando => [
        const SizedBox(height: EspacosDesmalha.s5),
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: EspacosDesmalha.s4),
        Text(
          'Preparando a proteção dos seus backups. Leva alguns segundos.',
          key: const Key('preparando_codigo'),
          textAlign: TextAlign.center,
          style: texto.bodyMedium,
        ),
      ],
      _Etapa.pronto => [
        const Align(
          alignment: Alignment.centerLeft,
          child: Selo('código confirmado', tipo: TipoSelo.ok),
        ),
        const SizedBox(height: EspacosDesmalha.s3),
        p(
          'Pronto. Seus backups agora podem ser abertos em outro celular com '
          'esse código. Guarde a anotação — ela não aparece de novo.',
        ),
        FilledButton(
          key: const Key('botao_concluir_codigo'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Concluir'),
        ),
      ],
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Código de recuperação')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EspacosDesmalha.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: conteudo,
          ),
        ),
      ),
    );
  }
}
