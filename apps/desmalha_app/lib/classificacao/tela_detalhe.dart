/// Detalhe do lançamento (wireframe M5): corrigir a classificação e
/// informar o CPF de quem pagou — e, na saúde, de quem foi atendido.
///
/// Rodada 2/2b: profissão regulamentada exige o CPF do pagador por
/// lançamento; sem ele o recebimento continua tributável e o cálculo segue
/// — "Informar depois" é resposta válida, e o item fica em "Falta CPF".
/// Saúde exige também o beneficiário, que por padrão é o próprio pagador.
library;

import 'dart:async';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';

import '../importacao/tela_importacao.dart' show dataBr;
import '../servicos_do_app.dart';
import '../tema/componentes.dart';
import '../tema/tipografia.dart';
import '../tema/tokens.dart';
import 'aba_lancamentos.dart' show nomeDaClassificacao;
import 'repositorio_classificacao.dart';
import 'tela_repasse.dart';

class TelaDetalhe extends StatefulWidget {
  const TelaDetalhe({
    super.key,
    required this.servicos,
    required this.lancamentoId,
  });

  final ServicosDoApp servicos;
  final String lancamentoId;

  @override
  State<TelaDetalhe> createState() => _TelaDetalheState();
}

class _TelaDetalheState extends State<TelaDetalhe> {
  DetalheLancamento? _d;
  ClassificacaoLancamento? _classificacao;
  final _documento = TextEditingController();
  final _nomeBeneficiario = TextEditingController();
  final _cpfBeneficiario = TextEditingController();
  bool _outroBeneficiario = false;
  String? _erroDocumento;
  String? _erroBeneficiario;

  RepositorioClassificacao get _repo => widget.servicos.classificacao;

  @override
  void initState() {
    super.initState();
    unawaited(_carregar());
  }

  @override
  void dispose() {
    _documento.dispose();
    _nomeBeneficiario.dispose();
    _cpfBeneficiario.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final d = await _repo.detalhe(widget.lancamentoId);
    if (!mounted) return;
    setState(() {
      _d = d;
      _classificacao = d.respostas.classificacao;
      _documento.text = d.respostas.documentoPagador ?? '';
      _nomeBeneficiario.text = d.respostas.nomeBeneficiario ?? '';
      _cpfBeneficiario.text = d.respostas.cpfBeneficiario ?? '';
      _outroBeneficiario = d.respostas.cpfBeneficiario != null;
    });
  }

  bool get _exigeCpf => _d?.profissao?.regulamentada ?? false;
  bool get _saude => _d?.profissao?.saude ?? false;

  Future<void> _salvar({required bool comDocumento}) async {
    final d = _d!;
    final documento = comDocumento ? _documento.text.trim() : '';
    if (documento.isNotEmpty && documentoDoPagador(documento) == null) {
      setState(() => _erroDocumento = 'CPF ou CNPJ inválido — confira os dígitos.');
      return;
    }
    final cpfBenef = _outroBeneficiario ? _cpfBeneficiario.text.trim() : '';
    if (cpfBenef.isNotEmpty &&
        documentoDoPagador(cpfBenef)?.ehCnpj != false) {
      setState(() => _erroBeneficiario = 'CPF inválido — confira os dígitos.');
      return;
    }
    final c = _classificacao!;
    if (c == ClassificacaoLancamento.reembolso ||
        c == ClassificacaoLancamento.repasse) {
      final salvou = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => TelaRepasse(
            servicos: widget.servicos,
            transacaoId: d.transacaoId,
            data: d.data,
            valorCentavos: d.valorCentavos,
            nome: d.nome,
            anteriores: RespostasClassificacao(
              classificacao: c,
              titular: d.respostas.titular,
              custoEssencial: d.respostas.custoEssencial,
              dataPagamentoCusto: d.respostas.dataPagamentoCusto,
              valorCustoCentavos: d.respostas.valorCustoCentavos,
              documentoPagador: documento.isEmpty ? null : documento,
              nomePagador: d.nome,
              cpfBeneficiario: cpfBenef.isEmpty ? null : cpfBenef,
              nomeBeneficiario:
                  _outroBeneficiario ? _nomeBeneficiario.text.trim() : null,
            ),
          ),
        ),
      );
      if (salvou == true && mounted) Navigator.of(context).pop();
      return;
    }
    await _repo.classificar(
      d.transacaoId,
      RespostasClassificacao(
        classificacao: c,
        documentoPagador: documento.isEmpty ? null : documento,
        nomePagador: d.nome,
        cpfBeneficiario: cpfBenef.isEmpty ? null : cpfBenef,
        nomeBeneficiario:
            _outroBeneficiario ? _nomeBeneficiario.text.trim() : null,
      ),
    );
    widget.servicos.dadosAlterados.value++;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    final texto = Theme.of(context).textTheme;
    final fiscal = TipografiaFiscal.de(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Lançamento')),
      body: SafeArea(
        child: d == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(EspacosDesmalha.s4),
                children: [
                  Text(d.nome ?? 'Recebimento', style: texto.titleLarge),
                  Text(d.descricao, style: fiscal.dado),
                  const SizedBox(height: EspacosDesmalha.s2),
                  Row(
                    children: [
                      Text(dataBr(d.data), style: fiscal.dado),
                      const Spacer(),
                      ValorEmReais(d.valorCentavos, estilo: fiscal.valor),
                    ],
                  ),
                  const SizedBox(height: EspacosDesmalha.s5),
                  Text('Este recebimento é', style: texto.titleSmall),
                  const SizedBox(height: EspacosDesmalha.s2),
                  Wrap(
                    spacing: EspacosDesmalha.s2,
                    runSpacing: EspacosDesmalha.s2,
                    children: [
                      for (final c in ClassificacaoLancamento.values)
                        ChoiceChip(
                          key: Key('classe_${c.name}'),
                          label: Text(nomeDaClassificacao(c)),
                          selected: _classificacao == c,
                          onSelected: (_) => setState(() => _classificacao = c),
                        ),
                    ],
                  ),
                  const SizedBox(height: EspacosDesmalha.s5),
                  if (_exigeCpf &&
                      d.statusDocumento == StatusDocumentoPagador.pendente) ...[
                    BannerObrigacao(
                      titulo: 'Falta o CPF de quem pagou.',
                      texto: 'Sua profissão exige o CPF do pagador em cada '
                          'recebimento. O cálculo já conta este valor — só o '
                          'registro está incompleto. Sem o CPF, quem pagou '
                          'perde a dedução na declaração dele.',
                    ),
                    const SizedBox(height: EspacosDesmalha.s4),
                  ],
                  TextField(
                    key: const Key('campo_documento'),
                    controller: _documento,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _classificacao ==
                              ClassificacaoLancamento.recebidoPj
                          ? 'CNPJ da empresa'
                          : 'CPF de quem pagou',
                      errorText: _erroDocumento,
                    ),
                    onChanged: (_) => setState(() => _erroDocumento = null),
                  ),
                  if (_saude &&
                      _classificacao != ClassificacaoLancamento.recebidoPj &&
                      _classificacao != ClassificacaoLancamento.pessoal) ...[
                    const SizedBox(height: EspacosDesmalha.s4),
                    SwitchListTile(
                      key: const Key('outro_beneficiario'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Quem foi atendido é outra pessoa'),
                      subtitle: const Text(
                        'Ex.: a mãe pagou a sessão do filho. Por padrão, o '
                        'atendido é quem pagou.',
                      ),
                      value: _outroBeneficiario,
                      onChanged: (v) => setState(() => _outroBeneficiario = v),
                    ),
                    if (_outroBeneficiario) ...[
                      TextField(
                        key: const Key('campo_nome_beneficiario'),
                        controller: _nomeBeneficiario,
                        decoration: const InputDecoration(
                            labelText: 'Nome de quem foi atendido'),
                      ),
                      TextField(
                        key: const Key('campo_cpf_beneficiario'),
                        controller: _cpfBeneficiario,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'CPF de quem foi atendido',
                          errorText: _erroBeneficiario,
                        ),
                        onChanged: (_) =>
                            setState(() => _erroBeneficiario = null),
                      ),
                    ],
                  ],
                  const SizedBox(height: EspacosDesmalha.s5),
                  FilledButton(
                    key: const Key('botao_salvar_detalhe'),
                    onPressed: () => unawaited(_salvar(comDocumento: true)),
                    child: const Text('Salvar'),
                  ),
                  if (_exigeCpf)
                    TextButton(
                      key: const Key('botao_informar_depois'),
                      onPressed: () => unawaited(_salvar(comDocumento: false)),
                      child: const Text('Informar depois'),
                    ),
                ],
              ),
      ),
    );
  }
}
