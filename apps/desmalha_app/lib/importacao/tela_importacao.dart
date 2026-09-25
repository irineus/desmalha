/// Tela de importação de extrato (wireframe M2).
library;

import 'dart:async';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';

import '../servicos_do_app.dart';
import '../suporte/tela_envio_suporte.dart';
import '../tema/componentes.dart';
import '../tema/tipografia.dart';
import '../tema/tokens.dart';
import 'arquivo_recebido.dart';
import 'controlador_importacao.dart';

/// `'2026-08-03'` → `'03/08/2026'`.
String dataBr(String data) =>
    '${data.substring(8, 10)}/${data.substring(5, 7)}/${data.substring(0, 4)}';

/// `n` + singular/plural: `plural(1, 'novo', 'novos')` → `'1 novo'`.
String plural(int n, String singular, String plural) =>
    '$n ${n == 1 ? singular : plural}';

const Map<MotivoDeduplicacao, String> textoDoMotivo = {
  MotivoDeduplicacao.identificadorConfere:
      'O banco identifica como o mesmo lançamento já importado.',
  MotivoDeduplicacao.dadosConferem:
      'Mesma data, valor e descrição de um lançamento já importado.',
  MotivoDeduplicacao.identificadorDivergente:
      'Mesma data, valor e descrição de um já importado, mas o banco diz que '
      'são lançamentos diferentes.',
  MotivoDeduplicacao.identificadorRepetidoNoArquivo:
      'O mesmo identificador do banco aparece duas vezes neste arquivo.',
};

// ─── Tela de importação ─────────────────────────────────────────────

class TelaImportacao extends StatefulWidget {
  const TelaImportacao({super.key, required this.servicos, this.recebido});

  final ServicosDoApp servicos;

  /// Arquivo entregue por outro app: a tela já abre na prévia dele (ou no
  /// motivo de não ter sido lido).
  final RecebimentoDeArquivo? recebido;

  @override
  State<TelaImportacao> createState() => _TelaImportacaoState();
}

class _TelaImportacaoState extends State<TelaImportacao> {
  late final ControladorImportacao _c = ControladorImportacao(
    repositorio: widget.servicos.importacao,
    seletor: widget.servicos.seletorDeArquivo,
    carregarCatalogo: widget.servicos.catalogo,
    aplicarRegras: widget.servicos.classificacao.aplicarRegrasAosNovos,
  );

  @override
  void initState() {
    super.initState();
    final recebido = widget.recebido;
    if (recebido?.arquivo != null) {
      unawaited(_c.usarArquivo(recebido!.arquivo!));
    } else if (recebido?.erro != null) {
      _c.falharRecebimento(recebido!.erro!);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Importar extrato')),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: _c,
        builder: (context, _) => SingleChildScrollView(
          padding: const EdgeInsets.all(EspacosDesmalha.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: switch (_c.estado) {
              EstadoImportacao.inicial => _inicial(context),
              EstadoImportacao.lendo || EstadoImportacao.confirmando => const [
                SizedBox(height: EspacosDesmalha.s6),
                Center(child: CircularProgressIndicator()),
              ],
              EstadoImportacao.escolherBanco => _escolherBanco(context),
              EstadoImportacao.jaImportado => _jaImportado(context),
              EstadoImportacao.previa => _previa(context),
              EstadoImportacao.concluida => _concluida(context),
              EstadoImportacao.falha => _falha(context),
            },
          ),
        ),
      ),
    ),
  );

  List<Widget> _inicial(BuildContext context) => [
    Text(
      'Escolha o arquivo do extrato (OFX ou CSV) que você exportou do banco. '
      'Nada é gravado antes de você conferir a prévia.',
      style: Theme.of(context).textTheme.bodyMedium,
    ),
    const SizedBox(height: EspacosDesmalha.s2),
    Text(
      'O seletor abre na pasta Download: salve ou copie o extrato para lá. '
      'Pastas internas de outros apps (Android/data) não aparecem para '
      'nenhum seletor de arquivos.',
      key: const Key('dica_pasta_download'),
      style: Theme.of(context).textTheme.bodySmall,
    ),
    const SizedBox(height: EspacosDesmalha.s4),
    FilledButton(
      key: const Key('botao_escolher_arquivo'),
      onPressed: _c.escolherArquivo,
      child: const Text('Escolher arquivo'),
    ),
  ];

  List<Widget> _escolherBanco(BuildContext context) => [
    Text(
      'Este arquivo é CSV. De qual banco ele veio?',
      style: Theme.of(context).textTheme.titleMedium,
    ),
    const SizedBox(height: EspacosDesmalha.s3),
    for (final p in _c.perfis)
      Card(
        child: ListTile(
          key: Key('perfil_${p.id}'),
          title: Text(p.banco),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _c.escolherPerfil(p),
        ),
      ),
    const SizedBox(height: EspacosDesmalha.s3),
    Text(
      'Banco que não está na lista ainda não tem leitura de CSV. Se ele '
      'exporta OFX, use o OFX.',
      style: Theme.of(context).textTheme.bodySmall,
    ),
  ];

  List<Widget> _jaImportado(BuildContext context) {
    final em = _c.jaImportadoEm!;
    return [
      BannerObrigacao(
        key: const Key('aviso_ja_importado'),
        titulo: 'Este arquivo já foi importado.',
        texto:
            'Ele entrou em ${em.day.toString().padLeft(2, '0')}/'
            '${em.month.toString().padLeft(2, '0')}/${em.year}. Importar de '
            'novo não acrescenta nada.',
      ),
      const SizedBox(height: EspacosDesmalha.s4),
      OutlinedButton(
        onPressed: _c.recomecar,
        child: const Text('Escolher outro arquivo'),
      ),
    ];
  }

  List<Widget> _falha(BuildContext context) => [
    Text(
      _c.mensagem ?? 'Não foi possível ler o arquivo.',
      key: const Key('erro_importacao'),
      style: const TextStyle(color: CoresDesmalha.falha),
    ),
    const SizedBox(height: EspacosDesmalha.s4),
    OutlinedButton(
      onPressed: _c.recomecar,
      child: const Text('Escolher outro arquivo'),
    ),
    // O parse falhou: o único caso em que o extrato pode ir ao suporte
    // (decisão 11 do owner), com consentimento na tela seguinte.
    if (_c.arquivo case final arquivo?)
      TextButton(
        key: const Key('botao_enviar_suporte'),
        onPressed: () => Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => TelaEnvioSuporte(
              servico: widget.servicos.suporte,
              arquivo: arquivo,
              motivo: _c.mensagem ?? 'arquivo não reconhecido',
            ),
          ),
        ),
        child: const Text('Enviar este arquivo ao suporte'),
      ),
  ];

  List<Widget> _concluida(BuildContext context) {
    final r = _c.resumo!;
    return [
      const Align(
        alignment: Alignment.centerLeft,
        child: Selo('importado', tipo: TipoSelo.ok),
      ),
      const SizedBox(height: EspacosDesmalha.s3),
      Text(
        r.persistidas == 1
            ? '1 lançamento gravado.'
            : '${r.persistidas} lançamentos gravados.',
        key: const Key('resumo_importacao'),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      if (r.suprimidas > 0)
        Text(
          r.suprimidas == 1
              ? '1 já existia e não entrou de novo.'
              : '${r.suprimidas} já existiam e não entraram de novo.',
        ),
      if (r.descartadasPeloUsuario > 0)
        Text(
          r.descartadasPeloUsuario == 1
              ? '1 descartado por você.'
              : '${r.descartadasPeloUsuario} descartados por você.',
        ),
      const SizedBox(height: EspacosDesmalha.s4),
      FilledButton(
        key: const Key('botao_importacao_ok'),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Pronto'),
      ),
    ];
  }

  List<Widget> _previa(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final extrato = _c.extrato!;
    final periodo = periodoDoExtrato(extrato);
    final r = _c.resultado;
    return [
      Text(_c.arquivo!.nome, style: texto.titleMedium),
      Text(
        periodo == null
            ? 'Sem lançamentos'
            : '${dataBr(periodo.$1)} a ${dataBr(periodo.$2)} · '
                  '${plural(extrato.transacoes.length, 'lançamento', 'lançamentos')}',
        style: TipografiaFiscal.de(context).dado,
      ),
      const SizedBox(height: EspacosDesmalha.s4),
      _SeletorConta(controlador: _c),
      if (extrato.avisos.isNotEmpty) ...[
        const SizedBox(height: EspacosDesmalha.s3),
        BannerObrigacao(
          key: const Key('avisos_leitura'),
          titulo:
              '${extrato.avisos.length} '
              '${extrato.avisos.length == 1 ? 'aviso' : 'avisos'} na leitura '
              'do arquivo.',
          texto: extrato.avisos
              .take(5)
              .map(
                (a) =>
                    '${a.linha == null ? '' : 'Linha ${a.linha}: '}${a.mensagem}',
              )
              .join('\n'),
        ),
      ],
      const SizedBox(height: EspacosDesmalha.s4),
      if (extrato.transacoes.isEmpty)
        const EstadoVazio(
          mensagem: 'Este arquivo não tem lançamentos no período.',
        )
      else if (r == null)
        Text(
          'Escolha a conta para comparar com o que já foi importado.',
          style: texto.bodyMedium,
        )
      else
        ..._resultado(context, r),
      if (_c.mensagem != null) ...[
        const SizedBox(height: EspacosDesmalha.s3),
        Text(
          _c.mensagem!,
          key: const Key('erro_confirmacao'),
          style: const TextStyle(color: CoresDesmalha.falha),
        ),
      ],
      const SizedBox(height: EspacosDesmalha.s4),
      if (_c.pendentesDeDecisao > 0)
        Padding(
          padding: const EdgeInsets.only(bottom: EspacosDesmalha.s2),
          child: Text(
            'Falta decidir '
            '${plural(_c.pendentesDeDecisao, 'possível duplicata', 'possíveis duplicatas')}.',
            key: const Key('falta_decidir'),
            style: texto.bodySmall,
          ),
        ),
      FilledButton(
        key: const Key('botao_confirmar_importacao'),
        onPressed: _c.podeConfirmar ? _c.confirmar : null,
        child: const Text('Confirmar importação'),
      ),
    ];
  }

  List<Widget> _resultado(BuildContext context, ResultadoDeduplicacao r) {
    final texto = Theme.of(context).textTheme;
    int soma(Iterable<TransacaoImportada> ts, {required bool creditos}) => ts
        .where((t) => creditos ? t.valorCentavos > 0 : t.valorCentavos < 0)
        .fold(0, (s, t) => s + t.valorCentavos);
    final novas = r.novas;
    return [
      _BlocoResumo(
        chave: 'bloco_novos',
        titulo: plural(r.quantidadeNova, 'novo', 'novos'),
        subtitulo: 'Entram ao confirmar.',
        creditos: soma(novas, creditos: true),
        debitos: soma(novas, creditos: false),
        itens: novas,
      ),
      if (r.quantidadeSuprimida > 0)
        _BlocoResumo(
          chave: 'bloco_suprimidos',
          titulo: plural(
            r.quantidadeSuprimida,
            'já importado',
            'já importados',
          ),
          subtitulo: 'Não entram de novo.',
          creditos: r.creditosSuprimidosCentavos,
          debitos: r.debitosSuprimidosCentavos,
          itens: [for (final i in r.suprimidas) i.transacao],
        ),
      if (_c.indicesPossiveis.isNotEmpty) ...[
        const SizedBox(height: EspacosDesmalha.s4),
        Text(
          '${plural(_c.indicesPossiveis.length, 'possível duplicata', 'possíveis duplicatas')}'
          ' — decida ${_c.indicesPossiveis.length == 1 ? 'antes de confirmar' : 'uma a uma'}',
          style: texto.titleSmall,
        ),
        const SizedBox(height: EspacosDesmalha.s2),
        for (final i in _c.indicesPossiveis)
          _CartaoPossivel(
            indice: i,
            item: r.itens[i],
            decisao: _c.decisoes[i],
            aoDecidir: (manter) => _c.decidir(i, manter: manter),
          ),
      ],
    ];
  }
}

class _SeletorConta extends StatefulWidget {
  const _SeletorConta({required this.controlador});

  final ControladorImportacao controlador;

  @override
  State<_SeletorConta> createState() => _SeletorContaState();
}

class _SeletorContaState extends State<_SeletorConta> {
  late final _apelido = TextEditingController(
    text: widget.controlador.apelidoNovaConta,
  );

  @override
  void dispose() {
    _apelido.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controlador;
    const nova = '__nova__';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: const Key('seletor_conta'),
          initialValue: c.novaConta ? nova : c.contaId,
          decoration: const InputDecoration(labelText: 'Conta'),
          hint: const Text('Escolha a conta'),
          items: [
            for (final conta in c.contas)
              DropdownMenuItem(value: conta.id, child: Text(conta.apelido)),
            const DropdownMenuItem(value: nova, child: Text('Nova conta')),
          ],
          onChanged: (v) => c.selecionarConta(v == nova ? null : v),
        ),
        if (c.novaConta) ...[
          const SizedBox(height: EspacosDesmalha.s3),
          TextField(
            key: const Key('campo_apelido_conta'),
            controller: _apelido,
            decoration: const InputDecoration(labelText: 'Nome da conta'),
            onChanged: c.mudarApelidoNovaConta,
          ),
          if (c.contas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: EspacosDesmalha.s2),
              child: Text(
                'Conta nova não é comparada com nada já importado. Se este '
                'extrato é de uma conta que você já usa, escolha-a acima.',
                key: const Key('aviso_conta_nova'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ],
    );
  }
}

class _BlocoResumo extends StatelessWidget {
  const _BlocoResumo({
    required this.chave,
    required this.titulo,
    required this.subtitulo,
    required this.creditos,
    required this.debitos,
    required this.itens,
  });

  final String chave;
  final String titulo;
  final String subtitulo;
  final int creditos;
  final int debitos;
  final List<TransacaoImportada> itens;

  @override
  Widget build(BuildContext context) => Card(
    key: Key(chave),
    child: ExpansionTile(
      title: Text(titulo),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitulo),
          // Uma linha por total: os dois lado a lado não cabem em 360 dp
          // quando o mês passa de R$ 100 mil (achado no emulador).
          for (final (rotulo, valor) in [
            ('Entradas', creditos),
            ('Saídas', debitos),
          ])
            Row(
              children: [
                Expanded(child: Text(rotulo)),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: ValorEmReais(valor),
                  ),
                ),
              ],
            ),
        ],
      ),
      children: [for (final t in itens) _LinhaTransacao(t)],
    ),
  );
}

class _LinhaTransacao extends StatelessWidget {
  const _LinhaTransacao(this.t);

  final TransacaoImportada t;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    title: Text(t.descricao, maxLines: 2, overflow: TextOverflow.ellipsis),
    subtitle: Text(dataBr(t.data), style: TipografiaFiscal.de(context).dado),
    trailing: ValorEmReais(t.valorCentavos),
  );
}

class _CartaoPossivel extends StatelessWidget {
  const _CartaoPossivel({
    required this.indice,
    required this.item,
    required this.decisao,
    required this.aoDecidir,
  });

  final int indice;
  final LancamentoConciliado item;
  final bool? decisao;
  final void Function(bool manter) aoDecidir;

  @override
  Widget build(BuildContext context) {
    final existente = item.correspondente;
    return Card(
      key: Key('possivel_$indice'),
      child: Padding(
        padding: const EdgeInsets.all(EspacosDesmalha.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LinhaTransacao(item.transacao),
            Text(
              textoDoMotivo[item.motivo]!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (existente != null) ...[
              const SizedBox(height: EspacosDesmalha.s2),
              Text('Já existe:', style: Theme.of(context).textTheme.labelSmall),
              _LinhaTransacao(existente),
            ],
            const SizedBox(height: EspacosDesmalha.s2),
            SegmentedButton<bool>(
              emptySelectionAllowed: true,
              segments: const [
                ButtonSegment(value: true, label: Text('Manter')),
                ButtonSegment(value: false, label: Text('Descartar')),
              ],
              selected: {?decisao},
              onSelectionChanged: (s) {
                if (s.isNotEmpty) aoDecidir(s.single);
              },
            ),
          ],
        ),
      ),
    );
  }
}
