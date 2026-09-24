import 'dart:convert';
import 'dart:typed_data';

import 'package:desmalha_app/importacao/controlador_importacao.dart';

/// Um lançamento de OFX sintético.
typedef LinhaOfx = ({String data, int centavos, String? fitid, String memo});

/// OFX SGML mínimo, sintético — nunca um extrato real.
ArquivoSelecionado ofxSintetico(
  List<LinhaOfx> linhas, {
  String nome = 'extrato.ofx',
  String banco = '0260',
  String conta = '12345678',
}) {
  String valor(int c) {
    final abs = c.abs();
    return '${c < 0 ? '-' : ''}${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
  }

  final corpo = StringBuffer()
    ..write(
      'OFXHEADER:100\nDATA:OFXSGML\nVERSION:102\nCHARSET:1252\n\n'
      '<OFX><BANKMSGSRSV1><STMTTRNRS><STMTRS><CURDEF>BRL\n'
      '<BANKACCTFROM><BANKID>$banco\n<ACCTID>$conta\n</BANKACCTFROM>\n'
      '<BANKTRANLIST>\n',
    );
  for (final l in linhas) {
    corpo.write(
      '<STMTTRN><TRNTYPE>${l.centavos < 0 ? 'DEBIT' : 'CREDIT'}\n'
      '<DTPOSTED>${l.data.replaceAll('-', '')}\n'
      '<TRNAMT>${valor(l.centavos)}\n'
      '${l.fitid == null ? '' : '<FITID>${l.fitid}\n'}'
      '<MEMO>${l.memo}\n</STMTTRN>\n',
    );
  }
  corpo.write('</BANKTRANLIST></STMTRS></STMTTRNRS></BANKMSGSRSV1></OFX>\n');
  return ArquivoSelecionado(
    nome: nome,
    bytes: Uint8List.fromList(utf8.encode(corpo.toString())),
  );
}

/// CSV no layout do perfil Nubank de referência (perfis/).
ArquivoSelecionado csvNubankSintetico() => ArquivoSelecionado(
  nome: 'nubank.csv',
  bytes: Uint8List.fromList(
    utf8.encode(
      'Data,Valor,Identificador,Descrição\n'
      '03/08/2026,450.00,id-1,Transferência recebida pelo Pix - ANA\n'
      '05/08/2026,-89.90,id-2,Compra no débito - MERCADO\n',
    ),
  ),
);

const LinhaOfx pixAna = (
  data: '2026-08-03',
  centavos: 45000,
  fitid: 'F1',
  memo: 'PIX RECEBIDO ANA',
);
const LinhaOfx pixBruno = (
  data: '2026-08-04',
  centavos: 30000,
  fitid: 'F2',
  memo: 'PIX RECEBIDO BRUNO',
);
const LinhaOfx mercado = (
  data: '2026-08-05',
  centavos: -8990,
  fitid: 'F3',
  memo: 'COMPRA MERCADO',
);
