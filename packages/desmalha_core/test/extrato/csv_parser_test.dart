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
}
