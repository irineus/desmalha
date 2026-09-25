/// Aba Ano: o relatório anual para a declaração de IRPF, mês a mês, nas
/// cinco colunas da ficha de rendimentos de PF (receitas, livro-caixa,
/// INSS, dependentes, imposto pago), a seção de PJ sem IRRF e o PDF para
/// levar à declaração ou ao contador (decisão 9 do owner).
///
/// Sem marca de "prévia": os números são os do app, com as regras do
/// contador (rodadas 4 e 5).
library;

import 'dart:async';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';

import '../painel/tela_darf.dart' show CompartilharArquivo, compartilharNoSistema;
import '../servicos_do_app.dart';
import '../tema/componentes.dart';
import '../tema/tipografia.dart';
import '../tema/tokens.dart';

/// Aviso sobre outras fontes de renda — TEXTO PROVISÓRIO, pendente de
/// revisão de marketing e jurídica (registrado no card da tela).
const String avisoOutrasRendas =
    'Este relatório cobre o que você recebeu como autônomo: de pessoas '
    'físicas, pelo carnê-leão, e de empresas sem retenção. Se você teve '
    'outras rendas no ano — salário, aluguel, aplicações, pensão —, elas '
    'também entram na declaração e mudam o imposto final.';

const _mesesPorExtenso = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', //
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

class AbaAno extends StatefulWidget {
  const AbaAno({
    super.key,
    required this.servicos,
    this.hoje,
    this.compartilhar = compartilharNoSistema,
  });

  final ServicosDoApp servicos;

  /// Relógio para teste; padrão = agora.
  final DateTime Function()? hoje;
  final CompartilharArquivo compartilhar;

  @override
  State<AbaAno> createState() => _AbaAnoState();
}

class _AbaAnoState extends State<AbaAno> {
  late int _ano = (widget.hoje ?? DateTime.now)().year;
  RelatorioAnual? _relatorio;
  String? _erro;

  int get _anoAtual => (widget.hoje ?? DateTime.now)().year;

  @override
  void initState() {
    super.initState();
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
    try {
      final catalogo = await widget.servicos.catalogo();
      final r = await widget.servicos.relatorio.relatorio(_ano, catalogo);
      if (!mounted) return;
      setState(() {
        _relatorio = r;
        _erro = null;
      });
    } on StateError catch (e) {
      // Falta a tabela do IRPF de um mês com dependente: falha visível.
      if (mounted) setState(() => _erro = 'Não foi possível montar o ano: ${e.message}');
    }
  }

  void _irPara(int ano) {
    setState(() {
      _ano = ano;
      _relatorio = null;
    });
    unawaited(_carregar());
  }

  Future<void> _pdf(RelatorioAnual r) => widget.compartilhar(
        gerarPdfRelatorioAnual(r, aviso: avisoOutrasRendas),
        'relatorio-carne-leao-${r.ano}.pdf',
        'application/pdf',
      );

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final r = _relatorio;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(EspacosDesmalha.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Seu ano', style: texto.headlineMedium),
            const SizedBox(height: EspacosDesmalha.s2),
            Row(
              children: [
                IconButton(
                  key: const Key('ano_anterior'),
                  tooltip: 'Ano anterior',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _irPara(_ano - 1),
                ),
                Expanded(
                  child: Text(
                    '$_ano',
                    key: const Key('ano_na_tela'),
                    textAlign: TextAlign.center,
                    style: texto.titleMedium,
                  ),
                ),
                IconButton(
                  key: const Key('ano_seguinte'),
                  tooltip: 'Ano seguinte',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _ano >= _anoAtual ? null : () => _irPara(_ano + 1),
                ),
              ],
            ),
            const SizedBox(height: EspacosDesmalha.s3),
            if (_erro != null)
              Text(_erro!, style: const TextStyle(color: CoresDesmalha.falha))
            else if (r == null)
              const Center(child: CircularProgressIndicator())
            else if (r.vazio)
              EstadoVazio(
                key: const Key('ano_vazio'),
                mensagem: 'Nada registrado em $_ano ainda. Os meses que você '
                    'classificar aparecem aqui, prontos para a declaração.',
              )
            else
              ..._relatorioNaTela(context, r),
          ],
        ),
      ),
    );
  }

  List<Widget> _relatorioNaTela(BuildContext context, RelatorioAnual r) {
    final texto = Theme.of(context).textTheme;
    final fiscal = TipografiaFiscal.de(context);
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(EspacosDesmalha.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Total do ano', style: texto.titleMedium),
              const SizedBox(height: EspacosDesmalha.s2),
              _Valores(
                prefixoChave: 'total',
                receitas: r.totalReceitasCentavos,
                livroCaixa: r.totalLivroCaixaCentavos,
                inss: r.totalInssCentavos,
                dependentes: r.totalDependentesCentavos,
                impostoPago: r.totalImpostoPagoCentavos,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: EspacosDesmalha.s3),
      Text('Mês a mês', style: texto.titleMedium),
      Text(
        'As colunas da ficha de rendimentos de pessoa física. Imposto pago '
        'conta só o que você marcou como pago, sem multa e juros.',
        style: texto.bodySmall,
      ),
      for (final m in r.meses)
        ExpansionTile(
          key: Key('mes_${m.competencia}'),
          tilePadding: EdgeInsets.zero,
          title: Text(_mesesPorExtenso[int.parse(m.competencia.substring(5)) - 1]),
          subtitle: Text(
            'receitas ${centavosParaExibicao(m.receitasCentavos)} · pago '
            '${centavosParaExibicao(m.impostoPagoCentavos)}',
            style: fiscal.dado,
          ),
          children: [
            _Valores(
              prefixoChave: m.competencia,
              receitas: m.receitasCentavos,
              livroCaixa: m.livroCaixaCentavos,
              inss: m.inssCentavos,
              dependentes: m.deducaoDependentesCentavos,
              impostoPago: m.impostoPagoCentavos,
            ),
          ],
        ),
      const SizedBox(height: EspacosDesmalha.s4),
      Text('Recebido de empresas (sem retenção)', style: texto.titleMedium),
      Text(
        'Fica fora do carnê-leão e vai para a declaração como rendimento '
        'recebido de pessoa jurídica.',
        style: texto.bodySmall,
      ),
      if (r.fontesPj.isEmpty)
        Text('Nenhum em ${r.ano}.', key: const Key('pj_vazio'))
      else
        for (final f in r.fontesPj)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(f.nome ?? 'Fonte sem nome'),
            subtitle: Text(
              f.cnpj == null
                  ? 'CNPJ não informado'
                  : 'CNPJ ${cnpjFormatado(f.cnpj!)}',
              style: fiscal.dado,
            ),
            trailing: ValorEmReais(f.totalCentavos),
          ),
      const SizedBox(height: EspacosDesmalha.s4),
      BannerObrigacao(
        key: const Key('aviso_outras_rendas'),
        titulo: 'Outras rendas mudam a declaração.',
        texto: avisoOutrasRendas,
      ),
      const SizedBox(height: EspacosDesmalha.s3),
      FilledButton(
        key: const Key('botao_pdf_ano'),
        onPressed: () => unawaited(_pdf(r)),
        child: const Text('Salvar ou enviar o PDF'),
      ),
    ];
  }
}

class _Valores extends StatelessWidget {
  const _Valores({
    required this.prefixoChave,
    required this.receitas,
    required this.livroCaixa,
    required this.inss,
    required this.dependentes,
    required this.impostoPago,
  });

  final String prefixoChave;
  final int receitas;
  final int livroCaixa;
  final int inss;
  final int dependentes;
  final int impostoPago;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    Widget linha(String rotulo, String chave, int centavos) => Padding(
          padding: const EdgeInsets.symmetric(vertical: EspacosDesmalha.s1),
          child: Row(
            children: [
              Expanded(child: Text(rotulo, style: texto.bodyMedium)),
              ValorEmReais(centavos, key: Key('${prefixoChave}_$chave')),
            ],
          ),
        );
    return Column(
      children: [
        linha('Receitas', 'receitas', receitas),
        linha('Livro-caixa', 'livro_caixa', livroCaixa),
        linha('INSS', 'inss', inss),
        linha('Dependentes', 'dependentes', dependentes),
        linha('Imposto pago', 'imposto_pago', impostoPago),
      ],
    );
  }
}
