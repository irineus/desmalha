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

    test('palavra isolada TAMBÉM é tratada como nome', () {
      // Regra invertida em 16/ago/2026 depois do primeiro extrato real: em
      // MEMO de Pix, palavra solta fora do vocabulário é quase sempre
      // primeiro nome. O custo aceito é embaralhar estabelecimento junto.
      final anon = Anonimizador();
      expect(anon.anonimizarTexto('GISELE'), isNot(contains('GISELE')));
      expect(anon.anonimizarTexto('Uber'), isNot(contains('Uber')));
    });

    test('vocabulário bancário isolado continua sobrevivendo', () {
      final anon = Anonimizador();
      expect(anon.anonimizarTexto('PIX TRANSF'), 'PIX TRANSF');
      expect(anon.anonimizarTexto('TED'), 'TED');
    });

    test('palavra funcional curta e isolada não vira nome', () {
      // O piso de 3 letras e os conectivos: sem eles, substituir palavra
      // isolada sujaria a fixture trocando "de" e "as" por nome fictício.
      final anon = Anonimizador();
      expect(anon.anonimizarTexto('de as um no'), 'de as um no');
      expect(anon.anonimizarTexto('Pagamento de mensalidade em 15/07/2026'),
          'Pagamento de mensalidade em 15/07/2026');
      // Conectivo GRUDADO num nome continua sendo absorvido por ele —
      // comportamento antigo, que "JOAO DA SILVA" é um nome só.
      final comNome = anon.anonimizarTexto('recebido de MARIA SOUZA');
      expect(comNome, startsWith('recebido '));
      expect(comNome, isNot(contains('MARIA')));
      expect(comNome, isNot(contains('SOUZA')));
    });

    group('MEMO truncado em largura fixa (vazamentos do Itaú real)', () {
      // Os quatro casos abaixo saíram de um extrato REAL do Itaú, onde o
      // banco corta o MEMO numa largura fixa e cola a data no fim. Nenhum
      // arquivo sintético tinha mostrado isso.

      test('nome colado à data não escapa mais', () {
        final anon = Anonimizador();
        final saida = anon.anonimizarTexto('PIX TRANSF SHIRLEI06 08');
        expect(saida, isNot(contains('SHIRLEI')));
        // A data colada é estrutura: o sufixo sobrevive.
        expect(saida, endsWith('06 08'));
        expect(saida, startsWith('PIX TRANSF '));
      });

      test('nome isolado entre vocabulário e data não escapa mais', () {
        final anon = Anonimizador();
        final saida = anon.anonimizarTexto('PIX TRANSF GISELE 04 08');
        expect(saida, isNot(contains('GISELE')));
        expect(saida, endsWith(' 04 08'));
      });

      test('sobrenome truncado no fim de um nome completo não escapa', () {
        final anon = Anonimizador();
        final saida = anon.anonimizarTexto('PIX Carla Souza Santo29 06');
        expect(saida, isNot(contains('Carla')));
        expect(saida, isNot(contains('Souza')));
        expect(saida, isNot(contains('Santo')));
        expect(saida, endsWith('29 06'));
      });

      test('nome do próprio titular colado à data não escapa', () {
        final anon = Anonimizador();
        final saida = anon.anonimizarTexto('DEV PIX Irineu Juni02 08');
        expect(saida, isNot(contains('Irineu')));
        expect(saida, isNot(contains('Juni')));
        expect(saida, endsWith('02 08'));
      });

      test('inicial solta (1 letra) não vira nome, mas some com o nome', () {
        final anon = Anonimizador();
        // 'PAULO J05' → PAULO é candidato; 'J' tem 1 letra e não é.
        final saida = anon.anonimizarTexto('PIX TRANSF PAULO J05 08');
        expect(saida, isNot(contains('PAULO')));
        expect(saida, endsWith('08'));
      });
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

    test('agrupamento de milhar do original é preservado', () {
      const csvBb = 'Data,Histórico,Detalhes,Doc,Valor,Tipo\n'
          '10/07/2026,Pix recebido,,,"12.345,67",C\n';
      final saida = anonimizarCsv(csvBb, _perfilBancoDoBrasil);
      // O ponto de milhar é estrutura: sem ele a fixture deixaria de
      // exercitar o caminho onde um formatoValor errado morde.
      expect(saida, matches(RegExp(r'"\d{1,3}\.\d{3},\d{2}"')));
    });
  });

  group('anonimizarCsvSemPerfil', () {
    // Bradesco-ish: preâmbulo, rótulos, ';' e valores com milhar.
    const csvBancoNovo = 'Extrato de Conta Corrente\n'
        'Titular;JOSE CLIENTE REAL;CPF;123.456.789-00\n'
        'Agência;1234;Conta;56789-0\n'
        'Data;Histórico;Docto.;Crédito (R\$);Débito (R\$);Saldo (R\$)\n'
        '10/07/2026;PIX RECEBIDO MARIA PACIENTE SILVA;001234;"1.200,00";;'
        '"3.450,00"\n'
        '15/07/2026;PAGAMENTO ALUGUEL CONSULTORIO;001235;;"850,00";'
        '"2.600,00"\n';

    test('detecta o delimitador pela regularidade de colunas', () {
      expect(detectarDelimitadorCsv(csvBancoNovo), ';');
      expect(
        detectarDelimitadorCsv('Data,Valor,Descrição\n'
            '10/07/2026,100.00,Pix recebido; urgente\n'
            '11/07/2026,200.00,Outro; caso\n'),
        ',',
      );
    });

    test('nome de cliente em linha de lançamento NÃO sobrevive', () {
      final r = anonimizarCsvSemPerfil(csvBancoNovo);
      // É a razão de o modo existir: emprestar o perfil de outro banco
      // jogaria a descrição no tratamento conservador, que preserva nomes.
      expect(r.conteudo, isNot(contains('MARIA')));
      expect(r.conteudo, isNot(contains('PACIENTE')));
      expect(r.conteudo, isNot(contains('SILVA')));
    });

    test('data é preservada e valor é perturbado com o milhar', () {
      final r = anonimizarCsvSemPerfil(csvBancoNovo);
      expect(r.conteudo, contains('10/07/2026'));
      expect(r.conteudo, contains('15/07/2026'));
      expect(r.conteudo, isNot(contains('1.200,00')));
      expect(r.conteudo, isNot(contains('850,00')));
      expect(r.conteudo, matches(RegExp(r'"\d{1,3}\.\d{3},\d{2}"')));
    });

    test('rótulos de coluna chegam legíveis a quem vai escrever o perfil', () {
      final r = anonimizarCsvSemPerfil(csvBancoNovo);
      expect(
        r.conteudo,
        contains('Data;Histórico;Docto.;Crédito (R\$);Débito (R\$);'
            'Saldo (R\$)'),
      );
      expect(r.conteudo, contains('Extrato de Conta Corrente'));
    });

    test('CPF e dígitos longos somem até no preâmbulo', () {
      final r = anonimizarCsvSemPerfil(csvBancoNovo);
      expect(r.conteudo, isNot(contains('123.456.789-00')));
      expect(r.conteudo, isNot(contains('56789')));
    });

    test('estrutura inferida descreve o arquivo sem revelar conteúdo', () {
      final r = anonimizarCsvSemPerfil(csvBancoNovo);
      expect(r.estrutura.delimitador, ';');
      expect(r.estrutura.colunas, 6);
      expect(r.estrutura.linhasLancamento, 2);
      // Título, titular, agência e rótulos: nenhuma tem data.
      expect(r.estrutura.linhasPreambulo, 4);
    });

    test('a saída é parseável pelo perfil escrito a partir da estrutura', () {
      // Exatamente o que o usuário faz depois: escrever o perfil olhando a
      // cópia anonimizada. Se a anonimização tivesse corrompido a estrutura,
      // este parse falharia.
      //
      // Fixture próprio, de coluna de valor ÚNICA e assinada: o layout de
      // Crédito/Débito em colunas separadas do `csvBancoNovo` não é
      // representável no `PerfilCsv` de hoje (ele tem `colunaValor` +
      // `colunaTipo`, não duas colunas de valor).
      const csvValorUnico = 'Extrato de Conta Corrente\n'
          'Titular;JOSE CLIENTE REAL;CPF;123.456.789-00\n'
          'Data;Histórico;Docto.;Valor (R\$)\n'
          '10/07/2026;PIX RECEBIDO MARIA PACIENTE SILVA;001234;"1.200,00"\n'
          '15/07/2026;PAGAMENTO ALUGUEL CONSULTORIO;001235;"-850,00"\n';
      final r = anonimizarCsvSemPerfil(csvValorUnico);
      const perfilNovo = PerfilCsv(
        id: 'banco-novo-conta-csv-v1',
        banco: 'Banco Novo',
        delimitador: ';',
        linhasCabecalho: 3,
        formatoData: 'dd/MM/yyyy',
        formatoValor: FormatoValor.virgulaDecimal,
        colunaData: 0,
        colunaValor: 3,
        colunaDescricao: 1,
      );
      final extrato = parseCsv(r.conteudo, perfilNovo);
      expect(extrato.avisos, isEmpty);
      expect(extrato.transacoes.length, 2);
      // O sinal do débito sobrevive à perturbação.
      expect(extrato.transacoes[1].valorCentavos, isNegative);
    });

    test('é determinística: mesma entrada, mesma saída', () {
      expect(
        anonimizarCsvSemPerfil(csvBancoNovo).conteudo,
        anonimizarCsvSemPerfil(csvBancoNovo).conteudo,
      );
    });

    test('CRLF, aspas e BOM-vizinhos são preservados', () {
      const csvCrlf = 'Data;Descrição;Valor\r\n'
          '10/07/2026;"PIX; RECEBIDO";"1.200,00"\r\n';
      final r = anonimizarCsvSemPerfil(csvCrlf);
      expect(r.conteudo, contains('\r\n'));
      expect(r.conteudo.split('\r\n').length, csvCrlf.split('\r\n').length);
      expect(r.conteudo, contains('"'));
    });

    test('arquivo sem nenhuma data reconhecível não finge ter lançamentos',
        () {
      final r = anonimizarCsvSemPerfil('Titular;JOSE CLIENTE REAL\n'
          'Saldo;1.000,00\n');
      expect(r.estrutura.linhasLancamento, 0);
      // Sem data não há como distinguir rótulo de texto livre: tudo cai no
      // conservador, que preserva nomes. O CLI avisa em cima deste zero.
      expect(r.estrutura.linhasPreambulo, 2);
    });

    test('delimitador pode ser imposto por quem chama', () {
      final r = anonimizarCsvSemPerfil(
        'Data|Descrição|Valor\n10/07/2026|PIX JOAO REAL|1.200,00\n',
        delimitador: '|',
      );
      expect(r.estrutura.delimitador, '|');
      expect(r.estrutura.colunas, 3);
      expect(r.conteudo, isNot(contains('JOAO')));
    });
  });
}
