/// Remetentes conhecidos (wireframe M7): quem já pagou, e as regras que o
/// app aprendeu — sempre confirmadas pela pessoa, e desfeitas por ela.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../servicos_do_app.dart';
import '../tema/componentes.dart';
import '../tema/tipografia.dart';
import '../tema/tokens.dart';
import 'aba_lancamentos.dart' show nomeDaClassificacao;
import 'repositorio_classificacao.dart';

class TelaRemetentes extends StatefulWidget {
  const TelaRemetentes({super.key, required this.servicos});

  final ServicosDoApp servicos;

  @override
  State<TelaRemetentes> createState() => _TelaRemetentesState();
}

class _TelaRemetentesState extends State<TelaRemetentes> {
  List<RemetenteConhecido>? _lista;

  @override
  void initState() {
    super.initState();
    unawaited(_carregar());
  }

  Future<void> _carregar() async {
    final l = await widget.servicos.classificacao.remetentes();
    if (mounted) setState(() => _lista = l);
  }

  Future<void> _esquecer(RemetenteConhecido r) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Parar de aplicar a regra?'),
        content: Text(
          'Recebimentos novos de ${r.nome} voltam a esperar a sua '
          'classificação. O que já foi classificado continua como está.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirmar_esquecer'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Parar de aplicar'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    await widget.servicos.classificacao.esquecerRegra(r.id);
    widget.servicos.dadosAlterados.value++;
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final lista = _lista;
    final fiscal = TipografiaFiscal.de(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Remetentes')),
      body: SafeArea(
        child: lista == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(EspacosDesmalha.s4),
                children: [
                  Text(
                    'O app aprende com o que você classifica e propõe o mesmo '
                    'para o próximo recebimento de quem já pagou — mas só '
                    'aplica depois que você confirma.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: EspacosDesmalha.s4),
                  if (lista.isEmpty)
                    const EstadoVazio(
                      key: Key('remetentes_vazio'),
                      mensagem: 'Classifique um recebimento e quem pagou '
                          'aparece aqui.',
                    )
                  else
                    for (final r in lista)
                      Card(
                        child: ListTile(
                          key: Key('remetente_${r.id}'),
                          title: Text(r.nome),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${r.lancamentos == 1 ? '1 recebimento' : '${r.lancamentos} recebimentos'}'
                                '${r.documento == null ? '' : ' · ${r.documento!.length == 11 ? 'CPF' : 'CNPJ'} informado'}',
                                style: fiscal.dado,
                              ),
                              const SizedBox(height: EspacosDesmalha.s1),
                              if (r.regraConfirmada && r.regra != null)
                                Selo(
                                  'regra: ${nomeDaClassificacao(r.regra!).toLowerCase()}',
                                  tipo: TipoSelo.ok,
                                )
                              else
                                const Selo('sem regra', tipo: TipoSelo.neutro),
                            ],
                          ),
                          trailing: r.regraConfirmada
                              ? TextButton(
                                  key: Key('esquecer_${r.id}'),
                                  onPressed: () => unawaited(_esquecer(r)),
                                  child: const Text('Parar de aplicar'),
                                )
                              : ValorEmReais(r.totalCentavos),
                        ),
                      ),
                ],
              ),
      ),
    );
  }
}
