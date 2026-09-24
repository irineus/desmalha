import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

/// Perfis de referência modelados nos formatos publicamente conhecidos dos
/// bancos-alvo. Em produção os perfis vêm do catálogo versionado da API;
/// estes existem para exercitar o schema e o parser.
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

const _perfilInter = PerfilCsv(
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

/// Layout de DUAS colunas de valor (Crédito/Débito), descrito no card a
/// partir do que se sabe de Bradesco/Santander/Banrisul — AINDA NÃO
/// conferido contra CSV real. Nenhum perfil de banco é publicado com ele.
const _perfilCreditoDebito = PerfilCsv(
  id: 'banco-separado-conta-csv-v1',
  banco: 'Banco Separado',
  delimitador: ';',
  linhasCabecalho: 1,
  formatoData: 'dd/MM/yyyy',
  formatoValor: FormatoValor.virgulaDecimal,
  colunaData: 0,
  colunaDescricao: 1,
  colunaCredito: 3,
  colunaDebito: 4,
);

void main() {
  group('parseCsv — perfil estilo Nubank', () {
    test('extrai transações com identificador', () {
      const csv = 'Data,Valor,Identificador,Descrição\n'
          '03/07/2026,2500.00,68b1-0001,Transferência recebida pelo Pix - MARIA DA SILVA\n'
          '10/07/2026,-150.75,68b1-0002,Pagamento de boleto efetuado - CEMIG\n';

      final extrato = parseCsv(csv, _perfilNubank);

      expect(extrato.formato, FormatoExtrato.csv);
      expect(extrato.banco, 'Nubank');
      expect(extrato.avisos, isEmpty);
      expect(extrato.transacoes, hasLength(2));
      expect(
        extrato.transacoes[0],
        const TransacaoImportada(
          data: '2026-07-03',
          valorCentavos: 250000,
          descricao: 'Transferência recebida pelo Pix - MARIA DA SILVA',
          idExterno: '68b1-0001',
        ),
      );
      expect(extrato.transacoes[1].valorCentavos, -15075);
    });

    test('campo entre aspas pode conter o delimitador', () {
      const csv = 'Data,Valor,Identificador,Descrição\n'
          '05/07/2026,980.50,68b1-0003,"Pix recebido - JOSE, FILHOS & CIA"\n';

      final extrato = parseCsv(csv, _perfilNubank);
      expect(extrato.avisos, isEmpty);
      expect(
        extrato.transacoes.single.descricao,
        'Pix recebido - JOSE, FILHOS & CIA',
      );
    });

    test('aspas escapadas por duplicação', () {
      const csv = 'Data,Valor,Identificador,Descrição\n'
          '05/07/2026,10.00,x,"Pagamento ""adiantado"" de honorários"\n';

      final extrato = parseCsv(csv, _perfilNubank);
      expect(
        extrato.transacoes.single.descricao,
        'Pagamento "adiantado" de honorários',
      );
    });
  });

  group('parseCsv — perfil estilo Inter (preâmbulo e vírgula decimal)', () {
    test('pula as linhas de preâmbulo do perfil', () {
      const csv = 'Extrato Conta Corrente\n'
          'Conta;12345678-9\n'
          'Período;01/07/2026 a 31/07/2026\n'
          '\n'
          'Data Lançamento;Descrição;Valor;Saldo\n'
          '03/07/2026;Pix recebido: "Cp :MARIA DA SILVA";R\$ 2.500,00;R\$ 3.000,00\n'
          '10/07/2026;Pagamento efetuado: "CEMIG";-R\$ 150,75;R\$ 2.849,25\n';

      final extrato = parseCsv(csv, _perfilInter);

      expect(extrato.avisos, isEmpty);
      expect(extrato.transacoes, hasLength(2));
      expect(extrato.transacoes[0].valorCentavos, 250000);
      expect(extrato.transacoes[0].data, '2026-07-03');
      expect(extrato.transacoes[1].valorCentavos, -15075);
      expect(extrato.transacoes[0].idExterno, isNull);
    });
  });

  group('parseCsv — perfil estilo Banco do Brasil (coluna de tipo D/C)', () {
    test('sinal vem da coluna de tipo e linhas de saldo são ignoradas', () {
      const csv = '"Data","Lançamento","Detalhes","N. documento","Valor","Tipo"\n'
          '"01/07/2026","Saldo Anterior","","0","1.000,00","C"\n'
          '"03/07/2026","Pix - Recebido","MARIA DA SILVA","0","2.500,00","C"\n'
          '"10/07/2026","Pagamento de Boleto","CEMIG","123","150,75","D"\n'
          '"31/07/2026","S A L D O","","0","3.349,25","C"\n';

      final extrato = parseCsv(csv, _perfilBancoDoBrasil);

      expect(extrato.avisos, isEmpty);
      expect(extrato.transacoes, hasLength(2));
      expect(extrato.transacoes[0].valorCentavos, 250000);
      expect(extrato.transacoes[1].valorCentavos, -15075);
      expect(extrato.transacoes[1].descricao, 'Pagamento de Boleto');
    });
  });

  group('parseCsv — linhas problemáticas viram avisos', () {
    test('data e valor inválidos apontam a linha física', () {
      const csv = 'Data,Valor,Identificador,Descrição\n'
          '99/99/2026,10.00,a,Data quebrada\n'
          '05/07/2026,dez reais,b,Valor quebrado\n'
          '06/07/2026,20.00,c,Linha boa\n';

      final extrato = parseCsv(csv, _perfilNubank);

      expect(extrato.transacoes, hasLength(1));
      expect(extrato.transacoes.single.descricao, 'Linha boa');
      expect(extrato.avisos, hasLength(2));
      expect(extrato.avisos[0].linha, 2);
      expect(extrato.avisos[0].mensagem, contains('data inválida'));
      expect(extrato.avisos[1].linha, 3);
      expect(extrato.avisos[1].mensagem, contains('valor inválido'));
    });

    test('linha com colunas de menos vira aviso', () {
      const csv = 'Data,Valor,Identificador,Descrição\n'
          '05/07/2026,10.00\n';

      final extrato = parseCsv(csv, _perfilNubank);
      expect(extrato.transacoes, isEmpty);
      expect(extrato.avisos.single.linha, 2);
      expect(extrato.avisos.single.mensagem, contains('colunas'));
    });

    test('linhas vazias são puladas em silêncio', () {
      const csv = 'Data,Valor,Identificador,Descrição\n'
          '\n'
          '05/07/2026,10.00,x,Ok\n'
          '\n';

      final extrato = parseCsv(csv, _perfilNubank);
      expect(extrato.avisos, isEmpty);
      expect(extrato.transacoes, hasLength(1));
    });

    test('CRLF é tratado como uma única quebra', () {
      const csv = 'Data,Valor,Identificador,Descrição\r\n'
          '05/07/2026,10.00,x,Ok\r\n';

      final extrato = parseCsv(csv, _perfilNubank);
      expect(extrato.avisos, isEmpty);
      expect(extrato.transacoes, hasLength(1));
    });

    test('arquivo menor que o cabeçalho prometido derruba a importação', () {
      expect(
        () => parseCsv('so uma linha', _perfilInter),
        throwsA(isA<ExtratoInvalidoException>()),
      );
    });
  });

  group('parseCsv — os três layouts de valor dão o mesmo lançamento', () {
    // Um crédito de R$ 1.200,00 e um débito de R$ 850,00 escritos nos três
    // layouts que o PerfilCsv representa.
    const esperado = [
      TransacaoImportada(
          data: '2026-07-10', valorCentavos: 120000, descricao: 'PIX RECEBIDO'),
      TransacaoImportada(
          data: '2026-07-15', valorCentavos: -85000, descricao: 'ALUGUEL'),
    ];

    test('1. valor assinado numa coluna', () {
      const perfil = PerfilCsv(
        id: 'assinado',
        banco: 'X',
        delimitador: ';',
        formatoData: 'dd/MM/yyyy',
        formatoValor: FormatoValor.virgulaDecimal,
        colunaData: 0,
        colunaValor: 2,
        colunaDescricao: 1,
      );
      const csv = 'Data;Histórico;Valor\n'
          '10/07/2026;PIX RECEBIDO;1.200,00\n'
          '15/07/2026;ALUGUEL;-850,00\n';
      final extrato = parseCsv(csv, perfil);
      expect(extrato.avisos, isEmpty);
      expect(extrato.transacoes, esperado);
    });

    test('2. valor sem sinal + coluna de tipo', () {
      const perfil = PerfilCsv(
        id: 'tipo',
        banco: 'X',
        delimitador: ';',
        formatoData: 'dd/MM/yyyy',
        formatoValor: FormatoValor.virgulaDecimal,
        colunaData: 0,
        colunaValor: 2,
        colunaDescricao: 1,
        colunaTipo: 3,
        marcadorDebito: 'D',
      );
      const csv = 'Data;Histórico;Valor;Tipo\n'
          '10/07/2026;PIX RECEBIDO;1.200,00;C\n'
          '15/07/2026;ALUGUEL;850,00;D\n';
      final extrato = parseCsv(csv, perfil);
      expect(extrato.avisos, isEmpty);
      expect(extrato.transacoes, esperado);
    });

    test('3. crédito e débito em colunas separadas', () {
      const csv = 'Data;Histórico;Docto.;Crédito (R\$);Débito (R\$);Saldo (R\$)\n'
          '10/07/2026;PIX RECEBIDO;001;"1.200,00";;"3.450,00"\n'
          '15/07/2026;ALUGUEL;002;;"850,00";"2.600,00"\n';
      final extrato = parseCsv(csv, _perfilCreditoDebito);
      expect(extrato.avisos, isEmpty);
      expect(extrato.transacoes, esperado);
    });
  });

  group('parseCsv — crédito/débito separados: o que não fecha vira aviso', () {
    List<TransacaoImportada> ok(String linha) {
      final e = parseCsv('cab\n$linha\n', _perfilCreditoDebito);
      expect(e.avisos, isEmpty, reason: linha);
      return e.transacoes;
    }

    String aviso(String linha) {
      final e = parseCsv('cab\n$linha\n', _perfilCreditoDebito);
      expect(e.transacoes, isEmpty, reason: linha);
      return e.avisos.single.mensagem;
    }

    test('débito com sinal negativo é o mesmo débito', () {
      expect(ok('15/07/2026;ALUGUEL;;;-850,00').single.valorCentavos, -85000);
    });

    test('a outra coluna preenchida com zero conta como vazia', () {
      expect(ok('10/07/2026;PIX;;1.200,00;0,00').single.valorCentavos, 120000);
      expect(ok('15/07/2026;ALUGUEL;;0,00;850,00').single.valorCentavos, -85000);
    });

    test('as duas preenchidas: pula, não soma nem escolhe', () {
      expect(aviso('10/07/2026;PIX;;100,00;50,00'),
          contains('crédito e débito preenchidos'));
    });

    test('nenhuma preenchida: pula', () {
      expect(aviso('10/07/2026;PIX;;;'), contains('sem valor'));
      expect(aviso('10/07/2026;PIX;;0,00;0,00'), contains('sem valor'));
    });

    test('negativo na coluna de crédito: pula, nunca vira receita positiva', () {
      // Estorno escrito como crédito negativo é ambíguo; tratá-lo como
      // receita de R$ 300 inflaria o rendimento.
      expect(aviso('10/07/2026;ESTORNO;;-300,00;'),
          contains('negativo na coluna de crédito'));
    });

    test('valor ilegível em qualquer das colunas: pula', () {
      expect(aviso('10/07/2026;PIX;;abc;'), contains('crédito inválido'));
      expect(aviso('10/07/2026;PIX;;;xyz'), contains('débito inválido'));
    });

    test('linha curta demais para a coluna de débito: pula', () {
      expect(aviso('10/07/2026;PIX;;1,00'), contains('colunas'));
    });
  });
}
