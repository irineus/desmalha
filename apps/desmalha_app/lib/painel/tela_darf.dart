/// Tela de DARF (wireframe D1): a guia do mês, o PDF para salvar ou
/// enviar, e o caminho de pagamento.
///
/// Postura vigente: enquanto o layout do código de barras não for conferido
/// contra um DARF real, a guia sai SEM código de barras e o pagamento vai
/// pelo e-CAC. E a tela sempre diz que pagar o DARF não registra o
/// livro-caixa no e-CAC.
library;

import 'dart:async';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../importacao/tela_importacao.dart' show dataBr;
import '../lembretes/controlador_lembretes.dart' show competenciaPorExtenso;
import '../servicos_do_app.dart';
import '../tema/componentes.dart';
import '../tema/tipografia.dart';
import '../tema/tokens.dart';

/// Porta de entrada do e-CAC, onde fica o Carnê-Leão Web.
final Uri urlEcac = Uri.parse('https://cav.receita.fazenda.gov.br/');

/// Compartilhamento nativo de um arquivo (o teste troca por um falso).
typedef CompartilharArquivo =
    Future<void> Function(Uint8List bytes, String nome, String tipo);

Future<void> compartilharNoSistema(
  Uint8List bytes,
  String nome,
  String tipo,
) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: tipo, name: nome)],
      fileNameOverrides: [nome],
    ),
  );
}

Future<void> abrirNoNavegador(Uri url) async {
  await launchUrl(url, mode: LaunchMode.externalApplication);
}

/// Observação impressa na guia vencida (e repetida na tela).
const String textoGuiaVencida =
    'Guia vencida: pago depois do vencimento, o DARF tem multa e juros. '
    'Gere a guia atualizada no SicalcWeb, da Receita Federal — o valor desta '
    'guia é o original.';

class TelaDarf extends StatefulWidget {
  const TelaDarf({
    super.key,
    required this.servicos,
    required this.painel,
    this.relogio,
    this.compartilhar = compartilharNoSistema,
    this.abrirUrl = abrirNoNavegador,
  });

  final ServicosDoApp servicos;
  final PainelApurado painel;
  final DateTime Function()? relogio;
  final CompartilharArquivo compartilhar;
  final Future<void> Function(Uri) abrirUrl;

  @override
  State<TelaDarf> createState() => _TelaDarfState();
}

class _TelaDarfState extends State<TelaDarf> {
  ResultadoGuia? _guia;
  String? _erro;

  String get _hoje {
    final d = (widget.relogio ?? DateTime.now)();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    unawaited(_montar());
  }

  Future<void> _montar() async {
    try {
      final catalogo = await widget.servicos.catalogo();
      final perfil = await widget.servicos.onboarding.repositorio.lerPerfil();
      final guia = guiaDoMes(
        painel: widget.painel,
        contribuinte: perfil == null
            ? null
            : Contribuinte(cpf: perfil.cpf, nome: perfil.nome),
        catalogo: catalogo,
      );
      if (mounted) setState(() => _guia = guia);
    } on Exception catch (e) {
      if (mounted) setState(() => _erro = 'Não foi possível montar a guia: $e');
    } on Error catch (e) {
      // Catálogo inconsistente (vencimento divergente): falha visível.
      if (mounted) setState(() => _erro = 'Não foi possível montar a guia: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('DARF — ${competenciaPorExtenso(widget.painel.competencia)}'),
    ),
    body: SafeArea(
      // Coluna rolável, não ListView: os botões do fim da guia precisam
      // existir mesmo fora da tela (ListView só constrói o que aparece).
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(EspacosDesmalha.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: switch ((_guia, _erro)) {
            (_, final String erro) => [
              Text(erro, style: const TextStyle(color: CoresDesmalha.falha)),
            ],
            (null, _) => const [Center(child: CircularProgressIndicator())],
            (SemGuia(:final motivo), _) => [
              Text(
                switch (motivo) {
                  MotivoSemGuia.naoEmitida => 'Este mês não gera DARF.',
                  MotivoSemGuia.semCalendario =>
                    'O vencimento não pode ser calculado: o calendário de '
                        'feriados bancários do ano ainda não foi publicado. '
                        'Nenhuma guia sai com data adivinhada.',
                  MotivoSemGuia.semContribuinte =>
                    'Faltam seu nome e CPF, que vão impressos na guia.',
                },
                key: const Key('sem_guia'),
                style: const TextStyle(color: CoresDesmalha.falha),
              ),
            ],
            (GuiaPronta(:final documento), _) => _guiaPronta(
              context,
              documento,
            ),
          },
        ),
      ),
    ),
  );

  List<Widget> _guiaPronta(BuildContext context, DocumentoDarf g) {
    final texto = Theme.of(context).textTheme;
    final fiscal = TipografiaFiscal.de(context);
    final vencida = g.venceuAte(_hoje);
    Widget campo(String rotulo, String valor, {Key? key}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: EspacosDesmalha.s1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(rotulo, style: texto.bodyMedium)),
          Expanded(
            flex: 3,
            child: Text(
              valor,
              key: key,
              textAlign: TextAlign.right,
              style: fiscal.dado,
            ),
          ),
        ],
      ),
    );

    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(EspacosDesmalha.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Valor a pagar', style: texto.labelLarge),
              ValorEmReais(
                g.valorTotalCentavos,
                key: const Key('darf_valor_total'),
                estilo: fiscal.valorDestaque,
              ),
              const SizedBox(height: EspacosDesmalha.s3),
              campo(
                'Código da receita',
                g.codigoReceita,
                key: const Key('darf_codigo'),
              ),
              campo('Período de apuração', dataBr(g.periodoApuracao)),
              campo(
                'Vencimento',
                dataBr(g.dataVencimento),
                key: const Key('darf_vencimento'),
              ),
              campo('Nome', g.contribuinte.nome),
              campo('CPF', g.contribuinte.cpfFormatado),
              if (g.competenciasAbrangidas.length > 1)
                campo(
                  'Inclui as competências',
                  g.competenciasAbrangidas
                      .map(competenciaPorExtenso)
                      .join(', '),
                  key: const Key('darf_abrangidas'),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: EspacosDesmalha.s3),
      if (vencida) ...[
        Text(
          textoGuiaVencida,
          key: const Key('darf_vencida'),
          style: const TextStyle(color: CoresDesmalha.falha),
        ),
        const SizedBox(height: EspacosDesmalha.s3),
      ],
      if (g.codigoBarras == null)
        const BannerObrigacao(
          key: Key('darf_sem_codigo'),
          titulo: 'Esta guia sai sem código de barras.',
          texto:
              'O layout do código ainda não foi conferido contra um DARF '
              'real, e um código adivinhado poderia pagar a guia errada. '
              'Emita e pague o DARF pelo Carnê-Leão Web, no e-CAC, com os '
              'valores acima.',
        )
      else ...[
        Text('Código de barras', style: texto.labelLarge),
        SelectableText(
          g.codigoBarras!.linhaDigitavelFormatada,
          key: const Key('darf_linha_digitavel'),
          style: fiscal.dado,
        ),
        const SizedBox(height: EspacosDesmalha.s2),
        FilledButton(
          key: const Key('botao_copiar_codigo'),
          onPressed: () => _copiar(
            g.codigoBarras!.linhaDigitavel,
            'Código de barras copiado.',
          ),
          child: const Text('Copiar código de barras'),
        ),
      ],
      const SizedBox(height: EspacosDesmalha.s3),
      const BannerObrigacao(
        key: Key('aviso_ecac_darf'),
        titulo: 'Pagar o DARF não registra nada no e-CAC.',
        texto:
            'O livro-caixa oficial é o Carnê-Leão Web. Depois de pagar, '
            'replique os totais do mês lá.',
      ),
      const SizedBox(height: EspacosDesmalha.s4),
      if (g.codigoBarras == null)
        FilledButton(
          key: const Key('botao_abrir_ecac'),
          onPressed: () => widget.abrirUrl(urlEcac),
          child: const Text('Abrir o e-CAC'),
        ),
      OutlinedButton(
        key: const Key('botao_pdf'),
        onPressed: () => _compartilharPdf(g, vencida),
        child: const Text('Salvar ou enviar o PDF'),
      ),
      TextButton(
        key: const Key('botao_copiar_dados'),
        onPressed: () => _copiar(
          'DARF código ${g.codigoReceita} · período de apuração '
              '${dataBr(g.periodoApuracao)} · vencimento '
              '${dataBr(g.dataVencimento)} · CPF ${g.contribuinte.cpfFormatado} · '
              'valor ${centavosParaExibicao(g.valorTotalCentavos)}',
          'Dados da guia copiados.',
        ),
        child: const Text('Copiar os dados da guia'),
      ),
    ];
  }

  Future<void> _copiar(String texto, String aviso) async {
    await Clipboard.setData(ClipboardData(text: texto));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(aviso)));
    }
  }

  Future<void> _compartilharPdf(DocumentoDarf g, bool vencida) async {
    final bytes = gerarPdfDarf(
      g,
      observacao: vencida ? textoGuiaVencida : null,
    );
    await widget.compartilhar(
      bytes,
      'darf-0190-${g.competencia}.pdf',
      'application/pdf',
    );
  }
}
