import 'package:desmalha_core/desmalha_core.dart';
import 'package:desmalha_core/validacao.dart';
import 'package:test/test.dart';

void main() {
  group('RelatorioExtrato.doExtrato', () {
    final extrato = ExtratoImportado(
      formato: FormatoExtrato.csv,
      transacoes: const [
        TransacaoImportada(
          data: '2026-07-15',
          valorCentavos: 150000,
          descricao: 'Pix recebido',
          idExterno: 'abc',
        ),
        TransacaoImportada(
          data: '2026-07-01',
          valorCentavos: 30000,
          descricao: 'Pix recebido',
        ),
        TransacaoImportada(
          data: '2026-07-31',
          valorCentavos: -4550,
          descricao: 'Tarifa',
        ),
      ],
      avisos: const [
        AvisoImportacao(linha: 7, mensagem: 'valor inválido: "x" — pulada'),
      ],
      banco: 'Banco Teste',
      conta: '12345-6',
      moeda: 'BRL',
    );

    final relatorio = RelatorioExtrato.doExtrato(extrato, encoding: 'utf-8');

    test('agrega créditos, débitos e líquido em centavos', () {
      expect(relatorio.totalTransacoes, 3);
      expect(relatorio.quantidadeCreditos, 2);
      expect(relatorio.somaCreditosCentavos, 180000);
      expect(relatorio.quantidadeDebitos, 1);
      expect(relatorio.somaDebitosCentavos, -4550);
      expect(relatorio.liquidoCentavos, 175450);
    });

    test('período vem das datas extremas, não da ordem do arquivo', () {
      expect(relatorio.dataInicial, '2026-07-01');
      expect(relatorio.dataFinal, '2026-07-31');
    });

    test('conta id externo presente e ausente', () {
      expect(relatorio.comIdExterno, 1);
      expect(relatorio.semIdExterno, 2);
    });

    test('mascara a conta mantendo só o final', () {
      expect(relatorio.contaMascarada, '••••5-6');
    });

    test('render traz agregados e avisos, nunca descrições de transação', () {
      final texto = relatorio.render();
      expect(texto, contains('R\$ 1.800,00'));
      expect(texto, contains('180000 centavos'));
      expect(texto, contains('2026-07-01 a 2026-07-31'));
      expect(texto, contains('linha 7'));
      expect(texto, contains('revise antes de compartilhar'));
      expect(texto, isNot(contains('Pix recebido')));
      expect(texto, isNot(contains('12345-6')));
    });

    test('render sem avisos declara "nenhum"', () {
      final limpo = RelatorioExtrato.doExtrato(
        ExtratoImportado(formato: FormatoExtrato.ofx, transacoes: const []),
        encoding: 'utf-8',
      );
      expect(limpo.render(), contains('nenhum'));
    });
  });

  group('mascararConta', () {
    test('conta curta é toda mascarada', () {
      expect(mascararConta('123'), '•••');
    });

    test('nulo e vazio passam adiante', () {
      expect(mascararConta(null), isNull);
      expect(mascararConta(''), '');
    });
  });
}
