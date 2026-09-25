import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

void main() {
  group('efeitoDoLancamento', () {
    test('rendimento de PF entra na receita; PJ vai só ao relatório anual '
        '(P1); pessoal não entra em nada', () {
      final pf = efeitoDoLancamento(ClassificacaoLancamento.rendimentoPf);
      expect((pf.entraNaReceita, pf.geraDespesa, pf.rendimentoDePj),
          (true, false, false));
      final pj = efeitoDoLancamento(ClassificacaoLancamento.recebidoPj);
      expect((pj.entraNaReceita, pj.geraDespesa, pj.rendimentoDePj),
          (false, false, true));
      final pessoal = efeitoDoLancamento(ClassificacaoLancamento.pessoal);
      expect(
          (pessoal.entraNaReceita, pessoal.geraDespesa), (false, false));
    });

    for (final c in [
      ClassificacaoLancamento.reembolso,
      ClassificacaoLancamento.repasse,
    ]) {
      test('${c.name}: a mesma árvore (P2) — cliente neutro; profissional é '
          'receita, e despesa só se essencial', () {
        final cliente =
            efeitoDoLancamento(c, titular: TitularComprovante.cliente);
        expect((cliente.entraNaReceita, cliente.geraDespesa), (false, false));
        final essencial = efeitoDoLancamento(c,
            titular: TitularComprovante.profissional, custoEssencial: true);
        expect((essencial.entraNaReceita, essencial.geraDespesa), (true, true));
        final naoEssencial = efeitoDoLancamento(c,
            titular: TitularComprovante.profissional, custoEssencial: false);
        expect((naoEssencial.entraNaReceita, naoEssencial.geraDespesa),
            (true, false));
      });

      test('${c.name} sem as respostas não é decidido por ninguém', () {
        expect(() => efeitoDoLancamento(c), throwsArgumentError);
        expect(
          () => efeitoDoLancamento(c, titular: TitularComprovante.profissional),
          throwsArgumentError,
        );
      });
    }
  });

  test('totaisDoMes separa receita, rendimento de PJ e despesa dedutível', () {
    final t = totaisDoMes(
      lancamentos: const [
        LancamentoClassificado(
            valorCentavos: 600000,
            classificacao: ClassificacaoLancamento.rendimentoPf),
        LancamentoClassificado(
            valorCentavos: 200000,
            classificacao: ClassificacaoLancamento.recebidoPj),
        LancamentoClassificado(
            valorCentavos: 99900, classificacao: ClassificacaoLancamento.pessoal),
      ],
      despesas: const [
        DespesaLivroCaixa(valorCentavos: 100000),
        DespesaLivroCaixa(valorCentavos: 50000, sujeitaTravaHomeOffice: true),
      ],
    );
    expect(t.receitaTributavelCentavos, 600000);
    expect(t.rendimentosPjCentavos, 200000);
    expect(t.despesasDedutiveisCentavos, 110000);
  });

  group('statusDocumento (rodada 2/2b)', () {
    Profissao profissao({required bool regulamentada}) => Profissao(
          id: 'x',
          nome: 'X',
          regulamentada: regulamentada,
          saude: false,
          conselho: regulamentada ? 'C' : null,
          meiPermitido: null,
          fonte: 't',
        );
    final pf = efeitoDoLancamento(ClassificacaoLancamento.rendimentoPf);

    test('regulamentada sem CPF: pendente — tributável do mesmo jeito', () {
      expect(
        statusDocumento(
          classificacao: ClassificacaoLancamento.rendimentoPf,
          efeito: pf,
          profissao: profissao(regulamentada: true),
          temDocumento: false,
        ),
        StatusDocumentoPagador.pendente,
      );
    });

    test('não regulamentada ou sem profissão: não exigido', () {
      for (final p in [profissao(regulamentada: false), null]) {
        expect(
          statusDocumento(
            classificacao: ClassificacaoLancamento.rendimentoPf,
            efeito: pf,
            profissao: p,
            temDocumento: false,
          ),
          StatusDocumentoPagador.naoExigido,
        );
      }
    });

    test('PJ sem CNPJ: pendente (vai ao relatório anual)', () {
      expect(
        statusDocumento(
          classificacao: ClassificacaoLancamento.recebidoPj,
          efeito: efeitoDoLancamento(ClassificacaoLancamento.recebidoPj),
          profissao: null,
          temDocumento: false,
        ),
        StatusDocumentoPagador.pendente,
      );
    });

    test('com documento: informado', () {
      expect(
        statusDocumento(
          classificacao: ClassificacaoLancamento.pessoal,
          efeito: EfeitoFiscal.nenhum,
          profissao: null,
          temDocumento: true,
        ),
        StatusDocumentoPagador.informado,
      );
    });
  });

  group('proposta por remetente (decisão 4)', () {
    test('declara quantidade e total: "Marcar os outros 2 como cliente '
        '(R\$ 900,00)"', () {
      final p = propostaParaRemetente(
        classificada: ClassificacaoLancamento.rendimentoPf,
        pendentes: const [
          (id: 'a', valorCentavos: 45000),
          (id: 'b', valorCentavos: 45000),
        ],
      )!;
      expect(p.rotulo, 'Marcar os outros 2 como cliente (R\$ 900,00)');
      expect(p.ids, ['a', 'b']);
    });

    test('um só: "o outro"', () {
      final p = propostaParaRemetente(
        classificada: ClassificacaoLancamento.pessoal,
        pendentes: const [(id: 'a', valorCentavos: 12000)],
      )!;
      expect(p.rotulo, 'Marcar o outro como pessoal (R\$ 120,00)');
    });

    test('sem pendentes, ou reembolso/repasse: sem proposta', () {
      expect(
        propostaParaRemetente(
            classificada: ClassificacaoLancamento.rendimentoPf,
            pendentes: const []),
        isNull,
      );
      expect(
        propostaParaRemetente(
          classificada: ClassificacaoLancamento.reembolso,
          pendentes: const [(id: 'a', valorCentavos: 1)],
        ),
        isNull,
        reason: 'as respostas são de cada recebimento, não do remetente',
      );
    });

    test('regra só vale confirmada, e nunca para reembolso/repasse', () {
      expect(
        classificacaoPelaRegra(
            regra: ClassificacaoLancamento.rendimentoPf, regraConfirmada: true),
        ClassificacaoLancamento.rendimentoPf,
      );
      expect(
        classificacaoPelaRegra(
            regra: ClassificacaoLancamento.rendimentoPf,
            regraConfirmada: false),
        isNull,
      );
      expect(
        classificacaoPelaRegra(
            regra: ClassificacaoLancamento.repasse, regraConfirmada: true),
        isNull,
      );
    });
  });
}
