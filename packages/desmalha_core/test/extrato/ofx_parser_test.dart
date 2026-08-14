import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

/// Fixture no estilo dos OFX 1.x (SGML) de Itaú/Banco do Brasil: cabeçalho
/// texto plano, elementos-folha sem fechamento, datas com fuso.
const _ofx1Sgml = '''
OFXHEADER:100
DATA:OFXSGML
VERSION:102
SECURITY:NONE
ENCODING:USASCII
CHARSET:1252
COMPRESSION:NONE
OLDFILEUID:NONE
NEWFILEUID:NONE

<OFX>
<SIGNONMSGSRSV1>
<SONRS>
<STATUS>
<CODE>0
<SEVERITY>INFO
</STATUS>
<DTSERVER>20260801100000[-3:BRT]
<LANGUAGE>POR
<FI>
<ORG>Banco Fixture S.A.
<FID>341
</FI>
</SONRS>
</SIGNONMSGSRSV1>
<BANKMSGSRSV1>
<STMTTRNRS>
<TRNUID>1
<STMTRS>
<CURDEF>BRL
<BANKACCTFROM>
<BANKID>0341
<BRANCHID>1234
<ACCTID>56789-0
<ACCTTYPE>CHECKING
</BANKACCTFROM>
<BANKTRANLIST>
<DTSTART>20260701000000[-3:BRT]
<DTEND>20260731235959[-3:BRT]
<STMTTRN>
<TRNTYPE>CREDIT
<DTPOSTED>20260703100000[-3:BRT]
<TRNAMT>2500.00
<FITID>2026070301
<MEMO>PIX RECEBIDO MARIA DA SILVA
</STMTTRN>
<STMTTRN>
<TRNTYPE>DEBIT
<DTPOSTED>20260710100000[-3:BRT]
<TRNAMT>-150.75
<FITID>2026071002
<MEMO>PAGAMENTO CONTA LUZ
</STMTTRN>
<STMTTRN>
<TRNTYPE>CREDIT
<DTPOSTED>20260728100000[-3:BRT]
<TRNAMT>980.50
<FITID>2026072803
<MEMO>PIX RECEBIDO JOSE &amp; FILHOS LTDA
</STMTTRN>
</BANKTRANLIST>
<LEDGERBAL>
<BALAMT>3329.75
<DTASOF>20260731
</LEDGERBAL>
</STMTRS>
</STMTTRNRS>
</BANKMSGSRSV1>
</OFX>
''';

/// Fixture no estilo dos OFX 2.x (XML) de Nubank/Inter: declaração XML,
/// tags fechadas, NAME em vez de MEMO.
const _ofx2Xml = '''
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?OFX OFXHEADER="200" VERSION="220" SECURITY="NONE" OLDFILEUID="NONE" NEWFILEUID="NONE"?>
<OFX>
  <SIGNONMSGSRSV1>
    <SONRS>
      <STATUS><CODE>0</CODE><SEVERITY>INFO</SEVERITY></STATUS>
      <DTSERVER>20260801100000</DTSERVER>
      <LANGUAGE>POR</LANGUAGE>
    </SONRS>
  </SIGNONMSGSRSV1>
  <BANKMSGSRSV1>
    <STMTTRNRS>
      <TRNUID>1</TRNUID>
      <STMTRS>
        <CURDEF>BRL</CURDEF>
        <BANKACCTFROM>
          <BANKID>0260</BANKID>
          <ACCTID>12345678-9</ACCTID>
          <ACCTTYPE>CHECKING</ACCTTYPE>
        </BANKACCTFROM>
        <BANKTRANLIST>
          <DTSTART>20260701</DTSTART>
          <DTEND>20260731</DTEND>
          <STMTTRN>
            <TRNTYPE>CREDIT</TRNTYPE>
            <DTPOSTED>20260705</DTPOSTED>
            <TRNAMT>1200.00</TRNAMT>
            <FITID>68b1a2c3-0001</FITID>
            <NAME>Transferência recebida pelo Pix - ANA PEREIRA</NAME>
          </STMTTRN>
          <STMTTRN>
            <TRNTYPE>DEBIT</TRNTYPE>
            <DTPOSTED>20260712</DTPOSTED>
            <TRNAMT>-89.90</TRNAMT>
            <FITID>68b1a2c3-0002</FITID>
            <NAME>Compra no débito - FARMACIA</NAME>
          </STMTTRN>
        </BANKTRANLIST>
      </STMTRS>
    </STMTTRNRS>
  </BANKMSGSRSV1>
</OFX>
''';

void main() {
  group('parseOfx — OFX 1.x SGML', () {
    test('extrai transações, metadados e decodifica entidades', () {
      final extrato = parseOfx(_ofx1Sgml);

      expect(extrato.formato, FormatoExtrato.ofx);
      expect(extrato.moeda, 'BRL');
      expect(extrato.banco, 'Banco Fixture S.A.');
      expect(extrato.conta, '56789-0');
      expect(extrato.avisos, isEmpty);
      expect(extrato.transacoes, hasLength(3));

      expect(
        extrato.transacoes[0],
        const TransacaoImportada(
          data: '2026-07-03',
          valorCentavos: 250000,
          descricao: 'PIX RECEBIDO MARIA DA SILVA',
          idExterno: '2026070301',
        ),
      );
      expect(extrato.transacoes[1].valorCentavos, -15075);
      expect(
        extrato.transacoes[2].descricao,
        'PIX RECEBIDO JOSE & FILHOS LTDA',
      );
    });
  });

  group('parseOfx — OFX 2.x XML', () {
    test('extrai transações usando NAME como descrição', () {
      final extrato = parseOfx(_ofx2Xml);

      expect(extrato.moeda, 'BRL');
      expect(extrato.banco, '0260');
      expect(extrato.conta, '12345678-9');
      expect(extrato.avisos, isEmpty);
      expect(extrato.transacoes, hasLength(2));
      expect(
        extrato.transacoes[0],
        const TransacaoImportada(
          data: '2026-07-05',
          valorCentavos: 120000,
          descricao: 'Transferência recebida pelo Pix - ANA PEREIRA',
          idExterno: '68b1a2c3-0001',
        ),
      );
      expect(extrato.transacoes[1].valorCentavos, -8990);
    });
  });

  group('parseOfx — problemas', () {
    test('arquivo que não é OFX derruba a importação', () {
      expect(
        () => parseOfx('Data;Valor\n01/07/2026;100,00'),
        throwsA(isA<ExtratoInvalidoException>()),
      );
    });

    test('transação sem DTPOSTED vira aviso e é pulada', () {
      const ofx = '''
<OFX><STMTTRN>
<TRNAMT>10.00
<FITID>1
<MEMO>SEM DATA
</STMTTRN><STMTTRN>
<DTPOSTED>20260710
<TRNAMT>20.00
<FITID>2
<MEMO>OK
</STMTTRN></OFX>
''';
      final extrato = parseOfx(ofx);
      expect(extrato.transacoes, hasLength(1));
      expect(extrato.transacoes[0].descricao, 'OK');
      expect(extrato.avisos, hasLength(1));
      expect(extrato.avisos[0].mensagem, contains('DTPOSTED ausente'));
      expect(extrato.avisos[0].mensagem, contains('transação 1'));
    });

    test('TRNAMT inválido vira aviso e é pulado', () {
      const ofx = '''
<OFX><STMTTRN>
<DTPOSTED>20260710
<TRNAMT>abc
<MEMO>VALOR RUIM
</STMTTRN></OFX>
''';
      final extrato = parseOfx(ofx);
      expect(extrato.transacoes, isEmpty);
      expect(extrato.avisos.single.mensagem, contains('TRNAMT inválido'));
    });

    test('OFX sem lançamentos gera aviso de prévia vazia', () {
      final extrato = parseOfx('<OFX><CURDEF>BRL</OFX>');
      expect(extrato.transacoes, isEmpty);
      expect(
        extrato.avisos.single.mensagem,
        contains('não contém lançamentos'),
      );
    });

    test('MEMO vazio cai para NAME', () {
      const ofx = '''
<OFX><STMTTRN>
<DTPOSTED>20260710
<TRNAMT>10.00
<NAME>SO NAME
<MEMO>
</STMTTRN></OFX>
''';
      final extrato = parseOfx(ofx);
      expect(extrato.transacoes.single.descricao, 'SO NAME');
    });
  });
}
