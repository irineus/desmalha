import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

void main() {
  test('dependentesNoMes: entrada e saída contam o mês inteiro (P7)', () {
    const deps = [
      VigenciaDependente(inicio: '2026-03-31'),
      VigenciaDependente(inicio: '2025-01-01', fim: '2026-03-01'),
    ];
    expect(dependentesNoMes(deps, '2026-02'), 1);
    expect(dependentesNoMes(deps, '2026-03'), 2);
    expect(dependentesNoMes(deps, '2026-04'), 1);
  });

  test('INSS: só o principal; "não paguei" e sem resposta deduzem zero (P6)',
      () {
    expect(
      inssDedutivelDoMes(const [
        PagamentoInssDoMes.pago(principalCentavos: 32000, acrescimosCentavos: 1200),
        PagamentoInssDoMes.pago(principalCentavos: 5000),
      ]),
      37000,
    );
    expect(inssDedutivelDoMes(const [PagamentoInssDoMes.naoPago()]), 0);
    expect(inssDedutivelDoMes(const []), 0);
  });

  test('cartão entra no mês da compra, também na virada do ano (P5)', () {
    expect(
      competenciaDaDespesa(
          forma: FormaPagamentoDespesa.cartaoCredito, dataPagamento: '2026-12-20'),
      '2026-12',
    );
    expect(
      () => competenciaDaDespesa(
          forma: FormaPagamentoDespesa.dinheiro, dataPagamento: '2026-12'),
      throwsArgumentError,
    );
  });

  test('entradaDoMes junta receita, livro-caixa, INSS e dependentes', () {
    final e = entradaDoMes(
      competencia: '2026-03',
      receitaTributavelCentavos: 800000,
      despesas: const [
        DespesaLivroCaixa(valorCentavos: 100000),
        DespesaLivroCaixa(valorCentavos: 240000, sujeitaTravaHomeOffice: true),
      ],
      inss: const [PagamentoInssDoMes.pago(principalCentavos: 32000, acrescimosCentavos: 1200)],
      dependentes: const [VigenciaDependente(inicio: '2026-03-20')],
    );
    expect(e.receitaBrutaCentavos, 800000);
    expect(e.despesasDedutiveisCentavos, 148000);
    expect(e.inssPagoCentavos, 32000);
    expect(e.numeroDependentes, 1);
  });
}
