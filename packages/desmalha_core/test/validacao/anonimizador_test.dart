import 'package:desmalha_core/desmalha_core.dart';
import 'package:desmalha_core/validacao.dart';
import 'package:test/test.dart';

const _perfilNubank = PerfilCsv(
  id: 'nubank-conta-csv-v1',
  banco: 'Nubank',
  delimitador: ',',
  formatoData: 'dd/MM/yyyy',
  formatoValor: FormatoValor.pontoDecimal,
  colunaData: 0,
  colunaValor: 1,
  colunaDescricao: 3,
  colunaIdExterno: 2,
);

const _perfilBancoDoBrasil = PerfilCsv(
  id: 'bb-conta-csv-v1',
  banco: 'Banco do Brasil',
  delimitador: ',',
  formatoData: 'dd/MM/yyyy',
  formatoValor: FormatoValor.virgulaDecimal,
  colunaData: 0,
  colunaValor: 4,
  colunaDescricao: 1,
  colunaTipo: 5,
  marcadorDebito: 'D',
  descricoesIgnoradas: ['Saldo Anterior', 'S A L D O'],
);

const _ofx = '''
OFXHEADER:100
DATA:OFXSGML
<OFX>
<BANKMSGSRSV1>
<STMTRS>
<CURDEF>BRL
<BANKACCTFROM>
<BANKID>0260
<ACCTID>12345678-9
</BANKACCTFROM>
<BANKTRANLIST>
<STMTTRN>
<TRNTYPE>CREDIT
<DTPOSTED>20260710120000[-3:BRT]
<TRNAMT>1500.00
<FITID>PIX001
<MEMO>Pix recebido de JOAO DA SILVA 123.456.789-01
</STMTTRN>
<STMTTRN>
<TRNTYPE>CREDIT
<DTPOSTED>20260711120000[-3:BRT]
<TRNAMT>200.50
<FITID>PIX002
<MEMO>Pix recebido de JOAO DA SILVA 123.456.789-01
</STMTTRN>
<STMTTRN>
<TRNTYPE>DEBIT
<DTPOSTED>20260715120000[-3:BRT]
<TRNAMT>-45.90
<FITID>PIX001
<MEMO>Tarifa de pacote de servicos
</STMTTRN>
</BANKTRANLIST>
<LEDGERBAL>
<BALAMT>1654.60
</LEDGERBAL>
</STMTRS>
</BANKMSGSRSV1>
</OFX>
''';

void main() {
  group('Anonimizador — substituições elementares', () {
    test('CPFs distintos viram fictícios distintos; repetido repete', () {
      final anon = Anonimizador();
      final a1 = anon.anonimizarTexto('CPF 123.456.789-01');
      final a2 = anon.anonimizarTexto('CPF 123.456.789-01');
      final b = anon.anonimizarTexto('CPF 987.654.321-00');
      expect(a1, a2);
      expect(a1, isNot(contains('123.456.789-01')));
      expect(a1, isNot(equals(b)));
      expect(b, isNot(contains('987.654.321-00')));
    });

    test('CPF mascarado do banco preserva o padrão de máscara', () {
      final anon = Anonimizador();
      final saida = anon.anonimizarTexto('de •••.456.789-••');
      expect(saida, isNot(contains('456.789')));
      expect(saida, startsWith('de •••.'));
      expect(saida, endsWith('-••'));
    });

    test('sequência longa de dígitos vira fictícia de mesmo comprimento', () {
      final anon = Anonimizador();
      final saida = anon.anonimizarTexto('conta 12345678');
      final digitos = RegExp(r'\d+').firstMatch(saida)!.group(0)!;
      expect(digitos.length, 8);
      expect(saida, isNot(contains('12345678')));
    });

    test('datas e números curtos sobrevivem (menos de 5 dígitos)', () {
      final anon = Anonimizador();
      expect(anon.anonimizarTexto('em 15/07/2026 as 12:30'),
          'em 15/07/2026 as 12:30');
    });

    test('nome próprio é substituído; vocabulário bancário fica', () {
      final anon = Anonimizador();
      final saida =
          anon.anonimizarTexto('Transferência recebida pelo Pix - '
              'MARIA OLIVEIRA DOS SANTOS');
      expect(saida, contains('Transferência recebida pelo Pix -'));
      expect(saida, isNot(contains('MARIA')));
      expect(saida, isNot(contains('OLIVEIRA')));
      expect(saida, isNot(contains('SANTOS')));
      // Caixa alta preservada.
      expect(saida, contains('FICTICI'));
    });

    test('mesmo nome vira sempre o mesmo fictício', () {
      final anon = Anonimizador();
      final a = anon.anonimizarTexto('JOAO DA SILVA');
      final b = anon.anonimizarTexto('JOAO DA SILVA');
      expect(a, b);
    });

    test('palavra isolada não é tratada como nome', () {
      final anon = Anonimizador();
      expect(anon.anonimizarTexto('Uber'), 'Uber');
    });

    test('perturbação mantém sinal e fica dentro de ±15%', () {
      final anon = Anonimizador();
      for (final original in [150000, -4590, 1, -1, 33]) {
        final perturbado = anon.perturbarCentavos(original);
        expect(perturbado.sign, original.sign,
            reason: 'sinal de $original');
        final desvio = (perturbado - original).abs();
        // Tolerância inteira: 15% + 1 centavo do arredondamento ~/.
        expect(desvio * 1000 <= original.abs() * 150 + 1000, isTrue,
            reason: '$original → $perturbado');
      }
      expect(anon.perturbarCentavos(0), 0);
    });

    test('id externo preserva duplicatas e distinções', () {
      final anon = Anonimizador();
      expect(anon.idFicticio('A'), anon.idFicticio('A'));
      expect(anon.idFicticio('A'), isNot(anon.idFicticio('B')));
    });
  });

  group('anonimizarOfx', () {
    final saida = anonimizarOfx(_ofx);

    test('é determinística', () {
      expect(anonimizarOfx(_ofx), saida);
    });

    test('remove CPF, nome e conta originais', () {
      expect(saida, isNot(contains('123.456.789-01')));
      expect(saida, isNot(contains('JOAO')));
      expect(saida, isNot(contains('SILVA')));
      expect(saida, isNot(contains('12345678-9')));
    });

    test('o resultado continua um OFX válido com as mesmas transações', () {
      final original = parseOfx(_ofx);
      final anonimo = parseOfx(saida);
      expect(anonimo.transacoes.length, original.transacoes.length);
      expect(anonimo.avisos, isEmpty);
      for (var i = 0; i < original.transacoes.length; i++) {
        expect(anonimo.transacoes[i].data, original.transacoes[i].data,
            reason: 'datas são estrutura, preservadas');
        expect(anonimo.transacoes[i].valorCentavos.sign,
            original.transacoes[i].valorCentavos.sign);
      }
    });

    test('valores são perturbados, não copiados', () {
      final original = parseOfx(_ofx);
      final anonimo = parseOfx(saida);
      final algumDiferente = List.generate(
        original.transacoes.length,
        (i) =>
            original.transacoes[i].valorCentavos !=
            anonimo.transacoes[i].valorCentavos,
      ).any((diferente) => diferente);
      expect(algumDiferente, isTrue);
    });

    test('FITID duplicado continua duplicado (insumo da deduplicação)', () {
      final anonimo = parseOfx(saida);
      expect(anonimo.transacoes[0].idExterno,
          anonimo.transacoes[2].idExterno);
      expect(anonimo.transacoes[0].idExterno,
          isNot(anonimo.transacoes[1].idExterno));
      expect(anonimo.transacoes[0].idExterno, isNot('PIX001'));
    });

    test('estrutura SGML preservada (mesmas linhas, mesmas tags)', () {
      expect(saida.split('\n').length, _ofx.split('\n').length);
      expect(RegExp('<STMTTRN>').allMatches(saida).length, 3);
      expect(saida, contains('<CURDEF>BRL'));
      expect(saida, contains('DTPOSTED>20260710120000[-3:BRT]'));
    });
  });

  group('anonimizarCsv', () {
    const csvNubank = 'Data,Valor,Identificador,Descrição\n'
        '10/07/2026,1500.00,abc-001,'
        'Transferência recebida pelo Pix - MARIA OLIVEIRA - '
        '•••.456.789-•• - NU PAGAMENTOS - Conta: 12345678-9\n'
        '15/07/2026,-45.90,abc-002,"Compra no débito, parcelada - '
        'FARMACIA EXEMPLO LTDA"\n';

    final saida = anonimizarCsv(csvNubank, _perfilNubank);

    test('é determinística', () {
      expect(anonimizarCsv(csvNubank, _perfilNubank), saida);
    });

    test('cabeçalho fica intacto', () {
      expect(saida.split('\n').first, 'Data,Valor,Identificador,Descrição');
    });

    test('remove nome, CPF mascarado e conta da descrição', () {
      expect(saida, isNot(contains('MARIA')));
      expect(saida, isNot(contains('456.789')));
      expect(saida, isNot(contains('12345678-9')));
    });

    test('o resultado continua parseável com o mesmo perfil', () {
      final original = parseCsv(csvNubank, _perfilNubank);
      final anonimo = parseCsv(saida, _perfilNubank);
      expect(anonimo.avisos, isEmpty);
      expect(anonimo.transacoes.length, original.transacoes.length);
      for (var i = 0; i < original.transacoes.length; i++) {
        expect(anonimo.transacoes[i].data, original.transacoes[i].data);
        expect(anonimo.transacoes[i].valorCentavos.sign,
            original.transacoes[i].valorCentavos.sign);
      }
      expect(anonimo.transacoes[0].idExterno,
          isNot(original.transacoes[0].idExterno));
    });

    test('campo entre aspas com delimitador interno segue entre aspas', () {
      final linhas = saida.trimRight().split('\n');
      expect(linhas[2], contains('"'));
      final anonimo = parseCsv(saida, _perfilNubank);
      expect(anonimo.transacoes[1].descricao, contains(','));
    });

    test('linhas de saldo do perfil são preservadas literalmente', () {
      const csvBb = 'Data,Histórico,Detalhes,Doc,Valor,Tipo\n'
          '30/06/2026,Saldo Anterior,,,"1.000,00",C\n'
          '10/07/2026,Pix recebido: CARLOS PEREIRA,,,"2.500,00",C\n'
          '31/07/2026,S A L D O,,,"3.500,00",C\n';
      final saidaBb = anonimizarCsv(csvBb, _perfilBancoDoBrasil);
      expect(saidaBb, contains('Saldo Anterior'));
      expect(saidaBb, contains('S A L D O'));
      expect(saidaBb, isNot(contains('CARLOS')));

      final anonimo = parseCsv(saidaBb, _perfilBancoDoBrasil);
      expect(anonimo.avisos, isEmpty);
      expect(anonimo.transacoes.length, 1);
    });

    test('preâmbulo de cabeçalho é tratado de forma conservadora', () {
      const perfilInter = PerfilCsv(
        id: 'inter-conta-csv-v1',
        banco: 'Banco Inter',
        delimitador: ';',
        linhasCabecalho: 5,
        formatoData: 'dd/MM/yyyy',
        formatoValor: FormatoValor.virgulaDecimal,
        colunaData: 0,
        colunaValor: 2,
        colunaDescricao: 1,
      );
      const csvInter = 'Extrato Conta Corrente\n'
          'Nome;Fulano Cliente Real\n'
          'Conta;12345678\n'
          'Período;01/07/2026 a 31/07/2026\n'
          'Data Lançamento;Descrição;Valor\n'
          '10/07/2026;Pix recebido - BEATRIZ COSTA;"1.200,00"\n';
      final saidaInter = anonimizarCsv(csvInter, perfilInter);
      // Rótulos estruturais sobrevivem; conta numérica não.
      expect(saidaInter, contains('Data Lançamento;Descrição;Valor'));
      expect(saidaInter, contains('Período;01/07/2026 a 31/07/2026'));
      expect(saidaInter, isNot(contains('12345678')));
      expect(saidaInter, isNot(contains('BEATRIZ')));

      final anonimo = parseCsv(saidaInter, perfilInter);
      expect(anonimo.avisos, isEmpty);
      expect(anonimo.transacoes.length, 1);
    });

    test('CRLF é preservado byte a byte', () {
      const csvCrlf = 'Data,Valor,Identificador,Descrição\r\n'
          '10/07/2026,100.00,x1,Pix recebido\r\n';
      final saidaCrlf = anonimizarCsv(csvCrlf, _perfilNubank);
      expect(saidaCrlf, contains('\r\n'));
      expect(saidaCrlf.split('\r\n').length, csvCrlf.split('\r\n').length);
    });
  });
}
