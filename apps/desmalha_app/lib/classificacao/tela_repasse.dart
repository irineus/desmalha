/// Reembolso e repasse — o 2º passo (wireframe M6).
///
/// Regra fechada com o contador (rodadas 2b e 4, P2/P3): a tributação
/// depende de em nome de quem está a nota ou o recibo do custo.
/// - No CPF do cliente: o valor só passou por você — fica fora de tudo.
/// - No seu CPF: é receita; e o custo só entra como despesa se for
///   essencial para prestar o serviço, no mês em que VOCÊ PAGOU.
///
/// Nada aqui é decidido pela pessoa: cada resposta é pergunta explícita, e
/// sem elas o app não classifica (a árvore mora no desmalha_core).
library;

import 'dart:async';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';

import '../importacao/tela_importacao.dart' show dataBr;
import '../servicos_do_app.dart';
import '../tema/tipografia.dart';
import '../tema/tokens.dart';
import 'repositorio_classificacao.dart';

class TelaRepasse extends StatefulWidget {
  const TelaRepasse({
    super.key,
    required this.servicos,
    required this.transacaoId,
    required this.data,
    required this.valorCentavos,
    required this.nome,
    this.anteriores,
  });

  final ServicosDoApp servicos;
  final String transacaoId;

  /// Data do recebimento, `'YYYY-MM-DD'`.
  final String data;
  final int valorCentavos;
  final String? nome;

  /// Respostas já gravadas (reclassificação a partir do detalhe).
  final RespostasClassificacao? anteriores;

  @override
  State<TelaRepasse> createState() => _TelaRepasseState();
}

class _TelaRepasseState extends State<TelaRepasse> {
  ClassificacaoLancamento? _tipo;
  TitularComprovante? _titular;
  bool? _essencial;
  late String _dataCusto;
  late final TextEditingController _valorCusto;
  String? _erro;

  @override
  void initState() {
    super.initState();
    final a = widget.anteriores;
    final repasseOuReembolso = a != null &&
        (a.classificacao == ClassificacaoLancamento.reembolso ||
            a.classificacao == ClassificacaoLancamento.repasse);
    _tipo = repasseOuReembolso ? a.classificacao : null;
    _titular = repasseOuReembolso ? a.titular : null;
    _essencial = repasseOuReembolso ? a.custoEssencial : null;
    _dataCusto = a?.dataPagamentoCusto ?? widget.data;
    _valorCusto = TextEditingController(
      text: centavosParaExibicao(a?.valorCustoCentavos ?? widget.valorCentavos)
          .replaceFirst(r'R$ ', ''),
    );
  }

  @override
  void dispose() {
    _valorCusto.dispose();
    super.dispose();
  }

  bool get _completo =>
      _tipo != null &&
      _titular != null &&
      (_titular == TitularComprovante.cliente || _essencial != null);

  String _efeito() {
    if (_titular == TitularComprovante.cliente) {
      return 'O valor só passou por você: fica fora do imposto e do '
          'livro-caixa. Guarde a nota no nome do cliente.';
    }
    if (_essencial == true) {
      return 'Entra na receita de ${_mes(widget.data)}, e o custo entra no '
          'livro-caixa de ${_mes(_dataCusto)} — o mês em que você pagou.';
    }
    return 'Entra na receita de ${_mes(widget.data)}. Sem ser essencial ao '
        'serviço, o custo não é dedutível.';
  }

  static String _mes(String data) => '${data.substring(5, 7)}/${data.substring(0, 4)}';

  Future<void> _escolherData() async {
    final atual = DateTime.parse(_dataCusto);
    final escolhida = await showDatePicker(
      context: context,
      initialDate: atual,
      firstDate: DateTime(atual.year - 1),
      lastDate: DateTime.parse(widget.data).add(const Duration(days: 366)),
      helpText: 'Quando você pagou esse custo?',
    );
    if (escolhida == null) return;
    final mm = escolhida.month.toString().padLeft(2, '0');
    final dd = escolhida.day.toString().padLeft(2, '0');
    setState(() => _dataCusto = '${escolhida.year}-$mm-$dd');
  }

  Future<void> _salvar() async {
    int? valor;
    if (_essencial == true && _titular == TitularComprovante.profissional) {
      valor = parseValorMonetario(_valorCusto.text, FormatoValor.virgulaDecimal);
      if (valor == null || valor <= 0) {
        setState(() => _erro = 'Informe o valor do custo, como 120,00.');
        return;
      }
    }
    final essencialAplica = _titular == TitularComprovante.profissional;
    final a = widget.anteriores;
    await widget.servicos.classificacao.classificar(
      widget.transacaoId,
      RespostasClassificacao(
        classificacao: _tipo!,
        titular: _titular,
        custoEssencial: essencialAplica ? _essencial : null,
        dataPagamentoCusto:
            essencialAplica && _essencial == true ? _dataCusto : null,
        valorCustoCentavos: valor,
        documentoPagador: a?.documentoPagador,
        nomePagador: a?.nomePagador,
        cpfBeneficiario: a?.cpfBeneficiario,
        nomeBeneficiario: a?.nomeBeneficiario,
      ),
    );
    widget.servicos.dadosAlterados.value++;
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final fiscal = TipografiaFiscal.de(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Reembolso ou repasse')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(EspacosDesmalha.s4),
          children: [
            Text(widget.nome ?? 'Recebimento', style: texto.titleLarge),
            Text(
              '${dataBr(widget.data)} · ${centavosParaExibicao(widget.valorCentavos)}',
              style: fiscal.dado,
            ),
            const SizedBox(height: EspacosDesmalha.s5),
            _Pergunta(
              titulo: 'O que é este valor?',
              opcoes: const {
                ClassificacaoLancamento.reembolso:
                    'Reembolso de um gasto que fiz pelo cliente',
                ClassificacaoLancamento.repasse:
                    'Repasse: recebi para pagar um terceiro (custas, taxas)',
              },
              valor: _tipo,
              prefixoChave: 'tipo',
              aoEscolher: (v) => setState(() => _tipo = v),
            ),
            if (_tipo != null)
              _Pergunta(
                titulo: 'Em nome de quem está a nota ou o recibo do custo?',
                opcoes: const {
                  TitularComprovante.cliente: 'No nome do cliente',
                  TitularComprovante.profissional: 'No meu nome (meu CPF)',
                },
                valor: _titular,
                prefixoChave: 'titular',
                aoEscolher: (v) => setState(() => _titular = v),
              ),
            if (_titular == TitularComprovante.profissional)
              _Pergunta(
                titulo: 'Esse custo é essencial para prestar o seu serviço?',
                ajuda: 'Essencial é o que você não teria como deixar de pagar '
                    'para atender — material usado na sessão, a taxa do '
                    'processo. Gasto pessoal do cliente não é.',
                opcoes: const {
                  true: 'Sim, é essencial à atividade',
                  false: 'Não',
                },
                valor: _essencial,
                prefixoChave: 'essencial',
                aoEscolher: (v) => setState(() => _essencial = v),
              ),
            if (_titular == TitularComprovante.profissional &&
                _essencial == true) ...[
              const SizedBox(height: EspacosDesmalha.s3),
              Text('Quando você pagou esse custo?', style: texto.titleSmall),
              const SizedBox(height: EspacosDesmalha.s2),
              OutlinedButton(
                key: const Key('data_custo'),
                onPressed: _escolherData,
                child: Text(dataBr(_dataCusto)),
              ),
              const SizedBox(height: EspacosDesmalha.s3),
              TextField(
                key: const Key('valor_custo'),
                controller: _valorCusto,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Valor do custo (R\$)',
                  errorText: _erro,
                ),
              ),
            ],
            if (_completo) ...[
              const SizedBox(height: EspacosDesmalha.s5),
              Text(_efeito(), key: const Key('efeito_repasse'),
                  style: texto.bodyMedium),
              const SizedBox(height: EspacosDesmalha.s4),
              FilledButton(
                key: const Key('botao_salvar_repasse'),
                onPressed: () => unawaited(_salvar()),
                child: const Text('Salvar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pergunta<T> extends StatelessWidget {
  const _Pergunta({
    required this.titulo,
    required this.opcoes,
    required this.valor,
    required this.prefixoChave,
    required this.aoEscolher,
    this.ajuda,
  });

  final String titulo;
  final String? ajuda;
  final Map<T, String> opcoes;
  final T? valor;
  final String prefixoChave;
  final ValueChanged<T> aoEscolher;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: EspacosDesmalha.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: texto.titleSmall),
          if (ajuda != null) ...[
            const SizedBox(height: EspacosDesmalha.s1),
            Text(ajuda!, style: texto.bodySmall),
          ],
          const SizedBox(height: EspacosDesmalha.s2),
          RadioGroup<T>(
            groupValue: valor,
            onChanged: (v) {
              if (v != null) aoEscolher(v);
            },
            child: Column(
              children: [
                for (final MapEntry(key: k, value: rotulo) in opcoes.entries)
                  RadioListTile<T>(
                    key: Key('${prefixoChave}_$k'),
                    value: k,
                    title: Text(rotulo),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
