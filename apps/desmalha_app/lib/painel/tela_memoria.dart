/// Memória de cálculo (wireframe M10): a linha de apuração na ordem do
/// cálculo, como uma conta de subtração que se segue com o dedo, e o
/// comparativo entre os dois cenários. A tela inteira é a prova — nada de
/// gráfico.
///
/// Os valores vêm do core ([memoriaDeCalculo]) sobre a mesma apuração da
/// aba Mês: os números aqui e lá são os mesmos (decisão 8 do owner).
library;

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';

import '../lembretes/controlador_lembretes.dart' show competenciaPorExtenso;
import '../tema/componentes.dart';
import '../tema/tipografia.dart';
import '../tema/tokens.dart';

/// Percentual em pontos-base para exibição (`2750` → `27,5%`).
String percentualDe(int pontosBase) {
  final inteiro = pontosBase ~/ 100;
  final resto = pontosBase % 100;
  if (resto == 0) return '$inteiro%';
  final decimais =
      resto % 10 == 0 ? '${resto ~/ 10}' : resto.toString().padLeft(2, '0');
  return '$inteiro,$decimais%';
}

class TelaMemoria extends StatelessWidget {
  const TelaMemoria({super.key, required this.memoria});

  final MemoriaDeCalculo memoria;

  String _mesCurto() => competenciaPorExtenso(memoria.competencia)
      .split('/')
      .first;

  (String, String?) _rotulo(LinhaDaMemoria l) => switch (l.termo) {
        TermoDaMemoria.receita => ('Recebido de pessoas físicas', null),
        TermoDaMemoria.livroCaixa => ('Livro-caixa de ${_mesCurto()}', '−'),
        TermoDaMemoria.saldoNegativoAnterior => (
            'Saldo negativo de meses anteriores',
            '−',
          ),
        TermoDaMemoria.inss => ('INSS pago no mês', '−'),
        TermoDaMemoria.dependentes => (
            l.quantidade == 1 ? '1 dependente' : '${l.quantidade} dependentes',
            '−',
          ),
        TermoDaMemoria.descontoSimplificado => ('Desconto simplificado', '−'),
        TermoDaMemoria.base => ('Base de cálculo', null),
        TermoDaMemoria.impostoPelaAliquota => (
            'Alíquota ${percentualDe(memoria.aliquotaPontosBase)}',
            null,
          ),
        TermoDaMemoria.parcelaDeduzir => ('Parcela a deduzir', '−'),
        TermoDaMemoria.impostoApurado => ('Imposto apurado', null),
        TermoDaMemoria.redutor => ('Redução da Lei 15.270/2025', '−'),
        TermoDaMemoria.impostoDevido => ('Imposto de ${_mesCurto()}', null),
        TermoDaMemoria.acumuladoAnterior => (
            'Acumulado de meses abaixo de R\$ 10,00',
            '+',
          ),
        TermoDaMemoria.totalParaDarf => ('Total a recolher', null),
      };

  static const _subtotais = {
    TermoDaMemoria.base,
    TermoDaMemoria.impostoApurado,
    TermoDaMemoria.impostoDevido,
    TermoDaMemoria.totalParaDarf,
  };

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final fiscal = TipografiaFiscal.de(context);
    final m = memoria;
    final reais = m.cenario == CenarioVencedor.deducoesReais;
    final resultado = m.linhas.last;
    return Scaffold(
      appBar: AppBar(title: const Text('Memória de cálculo')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EspacosDesmalha.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'competência ${competenciaPorExtenso(m.competencia)}',
                style: fiscal.rotulo,
              ),
              const SizedBox(height: EspacosDesmalha.s3),
              for (final l in m.linhas) ...[
                if (_subtotais.contains(l.termo)) const Divider(thickness: 2),
                _Linha(
                  key: Key('memoria_${l.termo.name}'),
                  sinal: _rotulo(l).$2,
                  rotulo: _rotulo(l).$1,
                  centavos: l.valorCentavos,
                  destaque: identical(l, resultado),
                ),
              ],
              if (m.baseLimitadaAZero) ...[
                const SizedBox(height: EspacosDesmalha.s2),
                Text(
                  'As deduções passaram da receita: a base fica em zero. O '
                  'que sobrar de INSS e dependentes não passa para o mês '
                  'seguinte — só o livro-caixa passa.',
                  key: const Key('memoria_base_zero'),
                  style: texto.bodySmall,
                ),
              ],
              const SizedBox(height: EspacosDesmalha.s4),
              Text(
                reais
                    ? 'Pelo desconto simplificado seria '
                        '${centavosParaExibicao(m.impostoSimplificadoCentavos)}'
                        '. Mantivemos as deduções reais, que dão '
                        '${centavosParaExibicao(m.impostoDeducoesReaisCentavos)}.'
                    : 'Pelas deduções reais seria '
                        '${centavosParaExibicao(m.impostoDeducoesReaisCentavos)}'
                        '. Aplicamos o desconto simplificado, que dá '
                        '${centavosParaExibicao(m.impostoSimplificadoCentavos)}.',
                key: const Key('memoria_comparativo'),
                style: texto.bodyMedium,
              ),
              if (m.redutorCentavos > 0)
                Text(
                  'Os dois valores são antes da redução da Lei 15.270/2025.',
                  style: texto.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({
    super.key,
    required this.sinal,
    required this.rotulo,
    required this.centavos,
    required this.destaque,
  });

  final String? sinal;
  final String rotulo;
  final int centavos;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final fiscal = TipografiaFiscal.de(context);
    final linha = Padding(
      padding: const EdgeInsets.symmetric(vertical: EspacosDesmalha.s1),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(sinal ?? '', style: fiscal.dado),
          ),
          Expanded(
            child: Text(
              rotulo,
              style: destaque ? texto.titleMedium : texto.bodyMedium,
            ),
          ),
          ValorEmReais(centavos, estilo: destaque ? fiscal.valor : null),
        ],
      ),
    );
    if (!destaque) return linha;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CoresDesmalha.salviaClara,
        borderRadius: BorderRadius.circular(EspacosDesmalha.s2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: EspacosDesmalha.s2),
        child: linha,
      ),
    );
  }
}
