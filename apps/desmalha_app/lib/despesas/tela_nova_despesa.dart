/// Nova despesa (wireframe M9): rubrica do catálogo, valor, data e forma de
/// pagamento — e, antes de salvar, quanto dela deduz.
///
/// Regras (Decisões vigentes §3, rodadas 4 e 4b):
/// - a trava de 20% da casa e as vedações são da RUBRICA, nunca de um
///   interruptor na tela;
/// - no cartão de crédito vale a data da COMPRA (P5) — a fatura não conta;
/// - "linha ou chip exclusivo da atividade" só entra com a declaração de
///   uso exclusivo, e a tela diz o que guardar como comprovante;
/// - rubrica vedada pode ser registrada (o gasto é real), mostra por que não
///   deduz, e entra com zero.
library;

import 'dart:async';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';

import '../importacao/tela_importacao.dart' show dataBr;
import '../servicos_do_app.dart';
import '../tema/componentes.dart';
import '../tema/tipografia.dart';
import '../tema/tokens.dart';
import 'repositorio_despesas.dart';

/// O que salvar produziu: a proposta para débitos iguais, se houver.
class ResultadoNovaDespesa {
  const ResultadoNovaDespesa({this.proposta});
  final PropostaDeDespesa? proposta;
}

const _nomesDosGrupos = {
  GrupoRubrica.espacoProfissional: 'Consultório ou escritório',
  GrupoRubrica.residencia: 'Sua casa, se você atende nela (deduz 20%)',
  GrupoRubrica.atividade: 'Custeio da atividade',
  GrupoRubrica.vedada: 'Não dedutíveis',
};

const _nomesDasFormas = {
  FormaPagamentoDespesa.outra: 'Pix, boleto ou débito',
  FormaPagamentoDespesa.dinheiro: 'Dinheiro',
  FormaPagamentoDespesa.cartaoCredito: 'Cartão de crédito',
};

class TelaNovaDespesa extends StatefulWidget {
  const TelaNovaDespesa({
    super.key,
    required this.servicos,
    required this.competencia,
    this.debito,
  });

  final ServicosDoApp servicos;

  /// Mês aberto na aba — a data sugerida cai nele.
  final String competencia;

  /// Débito do extrato que está virando despesa (valor e data fixos).
  final DebitoDoExtrato? debito;

  @override
  State<TelaNovaDespesa> createState() => _TelaNovaDespesaState();
}

class _TelaNovaDespesaState extends State<TelaNovaDespesa> {
  List<Rubrica>? _rubricas;
  Rubrica? _rubrica;
  FormaPagamentoDespesa _forma = FormaPagamentoDespesa.outra;
  late String _data;
  final _valor = TextEditingController();
  final _descricao = TextEditingController();
  bool _declarou = false;
  String? _erro;

  RepositorioDespesas get _repo => widget.servicos.despesas;

  @override
  void initState() {
    super.initState();
    final d = widget.debito;
    _data = d?.data ?? _sugestaoDeData();
    if (d != null) {
      _valor.text = centavosParaExibicao(
        d.valorCentavos,
      ).replaceFirst(r'R$ ', '');
    }
    unawaited(
      _repo.rubricas().then((r) {
        if (mounted) setState(() => _rubricas = r);
      }),
    );
  }

  /// Hoje, se o mês aberto é o atual; senão, o último dia do mês aberto.
  String _sugestaoDeData() {
    final hoje = DateTime.now();
    final mm = hoje.month.toString().padLeft(2, '0');
    final dd = hoje.day.toString().padLeft(2, '0');
    final iso = '${hoje.year}-$mm-$dd';
    return iso.startsWith(widget.competencia)
        ? iso
        : ultimoDiaDoMes(widget.competencia);
  }

  @override
  void dispose() {
    _valor.dispose();
    _descricao.dispose();
    super.dispose();
  }

  int? get _valorCentavos =>
      parseValorMonetario(_valor.text, FormatoValor.virgulaDecimal);

  Future<void> _escolherData() async {
    final atual = DateTime.parse(_data);
    final escolhida = await showDatePicker(
      context: context,
      initialDate: atual,
      firstDate: DateTime(atual.year - 1),
      lastDate: DateTime(atual.year + 1, 12, 31),
      helpText: _forma == FormaPagamentoDespesa.cartaoCredito
          ? 'Data da compra'
          : 'Data do pagamento',
    );
    if (escolhida == null) return;
    final mm = escolhida.month.toString().padLeft(2, '0');
    final dd = escolhida.day.toString().padLeft(2, '0');
    setState(() => _data = '${escolhida.year}-$mm-$dd');
  }

  Future<void> _salvar() async {
    final r = _rubrica;
    if (r == null) {
      setState(() => _erro = 'Escolha a categoria da despesa.');
      return;
    }
    final valor = _valorCentavos;
    if (widget.debito == null && (valor == null || valor <= 0)) {
      setState(() => _erro = 'Informe o valor, como 120,00.');
      return;
    }
    if (r.exigeDeclaracaoExclusividade && !_declarou) {
      setState(() => _erro = 'Confirme que a linha é só da atividade.');
      return;
    }
    final d = widget.debito;
    await _repo.registrar(
      rubricaId: r.id,
      valorCentavos: d == null ? valor : null,
      dataPagamento: d == null ? _data : null,
      forma: _forma,
      descricao: _descricao.text.trim().isEmpty ? null : _descricao.text.trim(),
      declarouExclusividade: _declarou,
      transacaoId: d?.transacaoId,
    );
    final proposta = d == null
        ? null
        : await _repo.propostaPara(d.transacaoId, r.id);
    if (mounted) {
      Navigator.of(context).pop(ResultadoNovaDespesa(proposta: proposta));
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final fiscal = TipografiaFiscal.de(context);
    final rubricas = _rubricas;
    final r = _rubrica;
    final valor = _valorCentavos;
    final debito = widget.debito;
    return Scaffold(
      appBar: AppBar(
        title: Text(debito == null ? 'Nova despesa' : 'Débito como despesa'),
      ),
      body: SafeArea(
        child: rubricas == null
            ? const Center(child: CircularProgressIndicator())
            : rubricas.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(EspacosDesmalha.s4),
                child: EstadoVazio(
                  key: Key('sem_rubricas'),
                  mensagem:
                      'O catálogo deste aparelho ainda não tem as '
                      'categorias de despesa. Conecte-se à internet e '
                      'abra o app de novo.',
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(EspacosDesmalha.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (debito != null) ...[
                      Text(
                        debito.chave ?? debito.descricao,
                        style: texto.titleMedium,
                      ),
                      Text(
                        '${dataBr(debito.data)} · ${centavosParaExibicao(debito.valorCentavos)}',
                        style: fiscal.dado,
                      ),
                      const SizedBox(height: EspacosDesmalha.s4),
                    ],
                    Text('Categoria', style: texto.titleSmall),
                    const SizedBox(height: EspacosDesmalha.s2),
                    for (final grupo in GrupoRubrica.values) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          top: EspacosDesmalha.s2,
                          bottom: EspacosDesmalha.s1,
                        ),
                        child: Text(
                          _nomesDosGrupos[grupo]!,
                          style: fiscal.rotulo,
                        ),
                      ),
                      Wrap(
                        spacing: EspacosDesmalha.s2,
                        runSpacing: EspacosDesmalha.s2,
                        children: [
                          for (final item in rubricas.where(
                            (x) => x.grupo == grupo,
                          ))
                            ChoiceChip(
                              key: Key('rubrica_${item.id}'),
                              label: Text(item.nome),
                              selected: r?.id == item.id,
                              onSelected: (_) => setState(() {
                                _rubrica = item;
                                _declarou = false;
                                _erro = null;
                              }),
                            ),
                        ],
                      ),
                    ],
                    if (r?.orientacao != null) ...[
                      const SizedBox(height: EspacosDesmalha.s3),
                      Text(
                        r!.orientacao!,
                        key: const Key('orientacao_rubrica'),
                        style: texto.bodyMedium,
                      ),
                    ],
                    if (r?.exigeDeclaracaoExclusividade ?? false)
                      CheckboxListTile(
                        key: const Key('declaracao_exclusividade'),
                        contentPadding: EdgeInsets.zero,
                        value: _declarou,
                        onChanged: (v) =>
                            setState(() => _declarou = v ?? false),
                        title: const Text(
                          'Declaro que esta linha é usada só na minha '
                          'atividade profissional.',
                        ),
                      ),
                    if (debito == null) ...[
                      const SizedBox(height: EspacosDesmalha.s4),
                      TextField(
                        key: const Key('valor_despesa'),
                        controller: _valor,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Valor (R\$)',
                        ),
                        onChanged: (_) => setState(() => _erro = null),
                      ),
                      const SizedBox(height: EspacosDesmalha.s4),
                      Text('Como pagou', style: texto.titleSmall),
                      const SizedBox(height: EspacosDesmalha.s2),
                      Wrap(
                        spacing: EspacosDesmalha.s2,
                        children: [
                          for (final MapEntry(key: f, value: nome)
                              in _nomesDasFormas.entries)
                            ChoiceChip(
                              key: Key('forma_${f.name}'),
                              label: Text(nome),
                              selected: _forma == f,
                              onSelected: (_) => setState(() => _forma = f),
                            ),
                        ],
                      ),
                      const SizedBox(height: EspacosDesmalha.s3),
                      OutlinedButton(
                        key: const Key('data_despesa'),
                        onPressed: _escolherData,
                        child: Text(
                          '${_forma == FormaPagamentoDespesa.cartaoCredito ? 'Data da compra' : 'Data do pagamento'}: ${dataBr(_data)}',
                        ),
                      ),
                      if (_forma == FormaPagamentoDespesa.cartaoCredito)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: EspacosDesmalha.s1,
                          ),
                          child: Text(
                            'No cartão vale a data em que você comprou — a '
                            'data da fatura não conta.',
                            key: const Key('nota_cartao'),
                            style: texto.bodySmall,
                          ),
                        ),
                    ],
                    const SizedBox(height: EspacosDesmalha.s3),
                    TextField(
                      key: const Key('descricao_despesa'),
                      controller: _descricao,
                      decoration: const InputDecoration(
                        labelText: 'Descrição (opcional)',
                      ),
                    ),
                    if (r != null && (valor != null || debito != null)) ...[
                      const SizedBox(height: EspacosDesmalha.s4),
                      _Deduz(
                        rubrica: r,
                        valorCentavos: debito?.valorCentavos ?? valor!,
                      ),
                    ],
                    if (_erro != null) ...[
                      const SizedBox(height: EspacosDesmalha.s2),
                      Text(
                        _erro!,
                        key: const Key('erro_despesa'),
                        style: const TextStyle(color: CoresDesmalha.falha),
                      ),
                    ],
                    const SizedBox(height: EspacosDesmalha.s4),
                    FilledButton(
                      key: const Key('botao_salvar_despesa'),
                      onPressed: () => unawaited(_salvar()),
                      child: const Text('Salvar despesa'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Quanto deduz, decidido pela rubrica (core), antes de salvar.
class _Deduz extends StatelessWidget {
  const _Deduz({required this.rubrica, required this.valorCentavos});

  final Rubrica rubrica;
  final int valorCentavos;

  @override
  Widget build(BuildContext context) {
    final deduz = rubrica.despesa(valorCentavos).dedutivelCentavos;
    final texto = !rubrica.dedutivel
        ? 'Não deduz. O gasto fica registrado com o comprovante.'
        : rubrica.travaResidencia
        ? 'Deduz 20%: ${centavosParaExibicao(deduz)}'
        : 'Deduz tudo: ${centavosParaExibicao(deduz)}';
    return Text(
      texto,
      key: const Key('quanto_deduz'),
      style: TipografiaFiscal.de(context).valorLinha,
    );
  }
}
