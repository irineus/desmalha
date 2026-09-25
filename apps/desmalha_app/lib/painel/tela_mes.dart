/// Aba Mês (wireframe M1): o DARF do mês, o vencimento, a pendência e a
/// evolução do ano — tudo do motor, sobre lançamentos CLASSIFICADOS.
///
/// Sem lançamento classificado no mês, a tela não mostra imposto nenhum:
/// mostra o estado vazio honesto (importe / classifique).
library;

import 'dart:async';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';

import '../backup/tela_backup.dart';
import '../importacao/tela_importacao.dart';
import '../lembretes/controlador_lembretes.dart'
    show competenciaPorExtenso, dataCurta;
import '../navegacao/abas.dart' show abrirTelaBackup;
import '../servicos_do_app.dart';
import '../tema/componentes.dart';
import '../tema/tipografia.dart';
import '../tema/tokens.dart';
import 'controlador_painel.dart';
import 'pergunta_inss.dart';
import 'tela_darf.dart';
import 'tela_memoria.dart';
import 'widgets_fechamento.dart';

/// Texto do contador para o mês sem imposto (M11) — literal.
const String textoMesIsento = 'Você está isento de recolhimento neste mês.';

const _mesesCurtos = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun', //
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];

class TelaMes extends StatefulWidget {
  const TelaMes({super.key, required this.servicos, this.relogio});

  final ServicosDoApp servicos;
  final DateTime Function()? relogio;

  @override
  State<TelaMes> createState() => _TelaMesState();
}

class _TelaMesState extends State<TelaMes> {
  late final ControladorPainel _c = ControladorPainel(
    repositorio: widget.servicos.painel,
    carregarCatalogo: widget.servicos.catalogo,
    fechamento: widget.servicos.fechamento,
    relogio: widget.relogio,
  );

  @override
  void initState() {
    super.initState();
    widget.servicos.dadosAlterados.addListener(_recarregar);
    unawaited(_c.carregar());
  }

  @override
  void dispose() {
    widget.servicos.dadosAlterados.removeListener(_recarregar);
    _c.dispose();
    super.dispose();
  }

  void _recarregar() => unawaited(_c.carregar());

  Future<void> _importar() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TelaImportacao(servicos: widget.servicos),
      ),
    );
    widget.servicos.dadosAlterados.value++;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final texto = Theme.of(context).textTheme;
        final painel = _c.painel;
        return RefreshIndicator(
          onRefresh: _c.carregar,
          // Coluna rolável (e não ListView, que só constrói o que aparece):
          // a evolução e os avisos do fim existem mesmo fora da tela.
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(EspacosDesmalha.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Seu mês', style: texto.headlineMedium),
                const SizedBox(height: EspacosDesmalha.s2),
                AvisoBackup(
                  controlador: widget.servicos.backup,
                  aoTocar: () => abrirTelaBackup(widget.servicos),
                ),
                if (_c.competencia != null) _navegacao(context),
                const SizedBox(height: EspacosDesmalha.s3),
                if (_c.erro != null)
                  Text(
                    _c.erro!,
                    style: const TextStyle(color: CoresDesmalha.falha),
                  )
                else if (painel == null)
                  const Center(child: CircularProgressIndicator())
                else
                  ..._conteudo(context, painel),
              ],
            ),
          ),
        );
      },
    ),
  );

  Widget _navegacao(BuildContext context) => Row(
    children: [
      IconButton(
        key: const Key('mes_anterior'),
        tooltip: 'Mês anterior',
        onPressed: _c.anterior,
        icon: const Icon(Icons.chevron_left),
      ),
      Expanded(
        child: Text(
          competenciaPorExtenso(_c.competencia!),
          key: const Key('competencia_na_tela'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      IconButton(
        key: const Key('mes_seguinte'),
        tooltip: 'Mês seguinte',
        onPressed: _c.podeAvancar ? _c.proximo : null,
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );

  List<Widget> _conteudo(
    BuildContext context,
    PainelMensal painel,
  ) => switch (painel) {
    PainelSemDados() => [
      EstadoVazio(
        key: const Key('mes_sem_dados'),
        mensagem:
            'Nenhum lançamento em ${competenciaPorExtenso(painel.competencia)}. '
            'Importe o extrato do banco para começar.',
        rotuloAcao: 'Importar extrato',
        aoAgir: _importar,
      ),
    ],
    PainelAClassificar(:final recebimentosAClassificar) => [
      EstadoVazio(
        key: const Key('mes_a_classificar'),
        mensagem:
            'Classifique seus lançamentos: '
            '${recebimentosAClassificar == 1 ? '1 recebimento' : '$recebimentosAClassificar recebimentos'} '
            'de ${competenciaPorExtenso(painel.competencia)} ainda sem '
            'classificação. O imposto só é calculado sobre o que você '
            'classificar. Separe cliente e pessoal na aba Lançamentos.',
      ),
    ],
    PainelSemTabela() => [
      Text(
        'A tabela do IRPF de ${competenciaPorExtenso(painel.competencia)} '
        'não está no catálogo do app, e o imposto não é calculado sem '
        'ela. Atualize o app.',
        key: const Key('mes_sem_tabela'),
        style: const TextStyle(color: CoresDesmalha.falha),
      ),
    ],
    PainelApurado() => _apurado(context, painel),
  };

  Future<void> _fecharMes(EstadoFechamento f, String competencia) async {
    final m = f.meses[competencia];
    if (m == null) return;
    await widget.servicos.fechamento.fecharSemGuia(m);
    widget.servicos.dadosAlterados.value++;
  }

  Future<void> _registrarCorrecao(EstadoFechamento f) async {
    final regravadas = await widget.servicos.fechamento.registrarCorrecao(
      f.meses,
    );
    widget.servicos.dadosAlterados.value++;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Correção registrada: '
          '${regravadas.map(competenciaPorExtenso).join(', ')}.',
        ),
      ),
    );
  }

  /// O mês já tem guia paga: o que foi pago e o acerto de hoje.
  List<Widget> _pago(BuildContext context, EstadoFechamento f) {
    final texto = Theme.of(context).textTheme;
    final fiscal = TipografiaFiscal.de(context);
    final pagamento = f.pagamento!;
    return [
      Text(
        f.guia!.competencias.length > 1
            ? 'DARF pago (período ${competenciaPorExtenso(f.guia!.periodo)})'
            : 'DARF pago',
        style: texto.labelLarge,
      ),
      ValorEmReais(
        f.guia!.principalPagoCentavos,
        key: const Key('valor_pago'),
        estilo: fiscal.valorDestaque,
      ),
      Text(
        'Pago em ${dataCurta(pagamento.pagoEm)}.',
        key: const Key('pago_em'),
        style: texto.bodyMedium,
      ),
      if (f.acerto != null) ...[
        const SizedBox(height: EspacosDesmalha.s2),
        AcertoDaGuiaNaTela(acerto: f.acerto!, pedeRetificadora: f.pedeRetificadora),
      ],
    ];
  }

  List<Widget> _apurado(BuildContext context, PainelApurado p) {
    final a = p.apuracao;
    final f = _c.estado;
    final texto = Theme.of(context).textTheme;
    final fiscal = TipografiaFiscal.de(context);
    final emAndamento = p.competencia == _c.competenciaAtual;
    Widget linha(String rotulo, int centavos, {Key? key}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: EspacosDesmalha.s1),
      child: Row(
        children: [
          Expanded(child: Text(rotulo, style: texto.bodyMedium)),
          ValorEmReais(centavos, key: key),
        ],
      ),
    );

    final destaque = switch (a.statusDarf) {
      _ when f?.pagamento != null => [
        ..._pago(context, f!),
        const SizedBox(height: EspacosDesmalha.s3),
        OutlinedButton(
          key: const Key('botao_ver_darf'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TelaDarf(
                servicos: widget.servicos,
                painel: p,
                estado: f,
                relogio: widget.relogio,
              ),
            ),
          ),
          child: const Text('Ver o DARF'),
        ),
      ],
      StatusDarf.emitido => [
        Text('DARF do mês', style: texto.labelLarge),
        ValorEmReais(
          a.valorDarfCentavos,
          key: const Key('valor_darf'),
          estilo: fiscal.valorDestaque,
        ),
        if (p.vencimento == null)
          Text(
            'Vencimento indisponível: ${p.motivoSemVencimento}.',
            key: const Key('vencimento'),
            style: const TextStyle(color: CoresDesmalha.falha),
          )
        else if (p.vencimento!.compareTo(_c.hoje) < 0) ...[
          Text(
            'Venceu ${dataCurta(p.vencimento!)} (código 0190).',
            key: const Key('vencimento'),
            style: const TextStyle(color: CoresDesmalha.falha),
          ),
          // Decisão vigente (DARF em atraso): o app mostra o valor original
          // e direciona ao SicalcWeb, que calcula multa e juros.
          Text(
            'Pago depois do vencimento, o DARF tem multa e juros: gere a '
            'guia atualizada no SicalcWeb, da Receita Federal. O valor acima '
            'é o original.',
            key: const Key('aviso_atraso'),
            style: texto.bodySmall,
          ),
        ] else
          Text(
            'Vence ${dataCurta(p.vencimento!)} (código 0190).',
            key: const Key('vencimento'),
            style: texto.bodyMedium,
          ),
        const SizedBox(height: EspacosDesmalha.s3),
        FilledButton(
          key: const Key('botao_ver_darf'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TelaDarf(
                servicos: widget.servicos,
                painel: p,
                estado: _c.estado,
                relogio: widget.relogio,
              ),
            ),
          ),
          child: const Text('Ver o DARF'),
        ),
        if (a.impostoAcumuladoAnteriorCentavos > 0)
          Text(
            'Inclui ${centavosParaExibicao(a.impostoAcumuladoAnteriorCentavos)} '
            'acumulados de meses anteriores, abaixo do mínimo de R\$ 10,00.',
            style: texto.bodySmall,
          ),
      ],
      StatusDarf.acumulaParaProximoMes => [
        Text(
          'Imposto de ${centavosParaExibicao(a.totalParaDarfCentavos)}, '
          'abaixo do mínimo de R\$ 10,00: não gera DARF neste mês. Soma ao '
          'do próximo mês, sem multa nem juros.',
          key: const Key('mes_acumula'),
          style: texto.titleMedium,
        ),
      ],
      StatusDarf.residuoParaDirpf => [
        Text(
          'Imposto de ${centavosParaExibicao(a.totalParaDarfCentavos)}, '
          'abaixo do mínimo de R\$ 10,00 em dezembro: não passa para '
          'janeiro — entra na declaração anual (DIRPF).',
          key: const Key('mes_residuo_dirpf'),
          style: texto.titleMedium,
        ),
      ],
      StatusDarf.semImposto => [
        Text(
          textoMesIsento,
          key: const Key('mes_isento'),
          style: texto.titleMedium,
        ),
      ],
    };
    // Mês sem guia (isento, resíduo de dezembro) fecha pelo botão.
    final semGuia =
        a.statusDarf == StatusDarf.semImposto ||
        a.statusDarf == StatusDarf.residuoParaDirpf;

    return [
      if (f?.fechado ?? false)
        const Padding(
          padding: EdgeInsets.only(bottom: EspacosDesmalha.s2),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Selo('mês fechado', tipo: TipoSelo.ok),
          ),
        )
      else if (emAndamento)
        const Padding(
          padding: EdgeInsets.only(bottom: EspacosDesmalha.s2),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Selo('mês em andamento', tipo: TipoSelo.neutro),
          ),
        ),
      if (f?.correcaoPendente ?? false) ...[
        BannerObrigacao(
          key: const Key('correcao_pendente'),
          titulo: 'Os dados de um mês fechado mudaram.',
          texto:
              'O cálculo abaixo já usa os valores novos. Registre a '
              'correção para gravar a nova versão do mês.',
        ),
        FilledButton(
          key: const Key('botao_registrar_correcao'),
          onPressed: () => unawaited(_registrarCorrecao(f!)),
          child: const Text('Registrar a correção'),
        ),
        const SizedBox(height: EspacosDesmalha.s3),
      ],
      Card(
        child: Padding(
          padding: const EdgeInsets.all(EspacosDesmalha.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: destaque,
          ),
        ),
      ),
      if (f != null && semGuia && !f.fechado && !emAndamento) ...[
        const SizedBox(height: EspacosDesmalha.s3),
        if (f.motivosQueImpedem.isEmpty)
          OutlinedButton(
            key: const Key('botao_fechar_mes'),
            onPressed: () => unawaited(_fecharMes(f, p.competencia)),
            child: const Text('Fechar mês'),
          )
        else
          Text(
            f.motivosQueImpedem.join(' '),
            key: const Key('motivos_nao_fecha'),
            style: texto.bodySmall,
          ),
      ],
      if (!(f?.fechado ?? false)) ...[
        const SizedBox(height: EspacosDesmalha.s3),
        PerguntaInss(servicos: widget.servicos, competencia: p.competencia),
      ],
      if (p.recebimentosAClassificar > 0) ...[
        const SizedBox(height: EspacosDesmalha.s3),
        BannerObrigacao(
          key: const Key('pendencia_classificar'),
          titulo:
              '${p.recebimentosAClassificar == 1 ? '1 recebimento' : '${p.recebimentosAClassificar} recebimentos'} '
              'a classificar.',
          texto:
              'Não entram no cálculo acima até serem classificados — o '
              'imposto do mês pode subir.',
        ),
      ],
      const SizedBox(height: EspacosDesmalha.s4),
      Text('Como chegou a esse valor', style: texto.titleSmall),
      linha(
        'Receita tributável',
        a.receitaBrutaCentavos,
        key: const Key('receita_tributavel'),
      ),
      linha(
        a.cenarioVencedor == CenarioVencedor.descontoSimplificado
            ? 'Imposto do mês (desconto simplificado)'
            : 'Imposto do mês (deduções do livro-caixa)',
        a.impostoDevidoCentavos,
        key: const Key('imposto_devido'),
      ),
      // O mesmo redutor que a memória de cálculo mostra (M10).
      if (redutorExibidoCentavos(a) > 0)
        Text(
          'Já com a redução de '
          '${centavosParaExibicao(redutorExibidoCentavos(a))} da Lei '
          '15.270/2025.',
          key: const Key('nota_redutor'),
          style: texto.bodySmall,
        ),
      if (_c.memoria != null)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('botao_memoria'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TelaMemoria(memoria: _c.memoria!),
              ),
            ),
            child: const Text('Ver memória de cálculo'),
          ),
        ),
      const SizedBox(height: EspacosDesmalha.s2),
      Text(
        'Livro-caixa, INSS e dependentes entram pela aba Despesas — o '
        'cálculo acima já conta o que está lá.',
        key: const Key('aviso_deducoes'),
        style: texto.bodySmall,
      ),
      const SizedBox(height: EspacosDesmalha.s4),
      Text('Evolução do ano', style: texto.titleSmall),
      const SizedBox(height: EspacosDesmalha.s2),
      _Evolucao(evolucao: p.evolucao),
    ];
  }
}

class _Evolucao extends StatelessWidget {
  const _Evolucao({required this.evolucao});

  final List<MesDaEvolucao> evolucao;

  @override
  Widget build(BuildContext context) {
    final maior = evolucao.fold<int>(
      0,
      (m, e) => (e.apuracao?.impostoDevidoCentavos ?? 0) > m
          ? e.apuracao!.impostoDevidoCentavos
          : m,
    );
    return Column(
      key: const Key('evolucao'),
      children: [
        for (final e in evolucao)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    _mesesCurtos[int.parse(e.competencia.substring(5, 7)) - 1],
                    style: TipografiaFiscal.de(context).rotulo,
                  ),
                ),
                Expanded(
                  child: e.apuracao == null
                      ? Text(
                          'sem lançamentos classificados',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      // Proporção por flex inteiro: nada de ponto
                      // flutuante perto de valor fiscal, nem no desenho.
                      : e.apuracao!.impostoDevidoCentavos == 0
                      ? const SizedBox(height: 10)
                      : Row(
                          children: [
                            Expanded(
                              flex: e.apuracao!.impostoDevidoCentavos,
                              child: Container(
                                height: 10,
                                color: CoresDesmalha.salvia,
                              ),
                            ),
                            if (maior > e.apuracao!.impostoDevidoCentavos)
                              Expanded(
                                flex: maior - e.apuracao!.impostoDevidoCentavos,
                                child: const SizedBox(height: 10),
                              ),
                          ],
                        ),
                ),
                if (e.apuracao != null)
                  SizedBox(
                    width: 110,
                    child: ValorEmReais(e.apuracao!.impostoDevidoCentavos),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
