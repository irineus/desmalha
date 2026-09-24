/// Gerador VERSIONADO das fixtures sintéticas de extrato OFX.
///
/// ⚠️ LEIA O README AO LADO ANTES DE CONFIAR NESTAS FIXTURES. Elas provam que
/// o parser e ESTE gerador concordam — nada além disso. Não provam cobertura
/// de banco real nenhum: foram escritas a partir do mesmo entendimento de OFX
/// que o parser tem. É por isso que os bancos são fictícios (`SINTETICO-*`,
/// BANKID 9xx) — nome de banco real aqui seria afirmar cobertura que não
/// existe.
///
/// Por que um gerador, e não arquivos soltos: as 12 fixtures de 16/ago/2026
/// nunca chegaram ao repositório e foram desmascaradas pela UNIFORMIDADE —
/// doze "bancos" com a conta terminando em 678, todos UTF-8, FITID em 100%,
/// ~30 dias. Aqui cada eixo desses varia de propósito, e o teste
/// `fixtures_sinteticas_test.dart` reprova se a variedade cair.
///
/// Regenerar (a partir de `packages/desmalha_core`):
///
///     fvm dart run test/fixtures/sinteticas/gerador.dart
///
/// O teste reprova se o que está em disco divergir do que o gerador produz:
/// fixture editada à mão deixa de ser do gerador e perde o rótulo.
library;

import 'dart:convert';
import 'dart:io';

import 'package:desmalha_core/desmalha_core.dart';

/// Como o arquivo representa o texto em bytes.
enum Codificacao { utf8, utf8ComBom, latin1, cp1252 }

/// Quantos lançamentos carregam FITID.
enum CoberturaFitid { todos, parcial, nenhum }

/// Forma do DTPOSTED.
enum FormatoData { curto, comHora, comFuso }

/// A receita de uma fixture. Cada campo é um eixo que extrato real varia.
class EspecificacaoFixture {
  const EspecificacaoFixture({
    required this.arquivo,
    required this.org,
    required this.bankId,
    required this.conta,
    required this.sgml,
    required this.codificacao,
    required this.crlf,
    required this.inicio,
    required this.dias,
    required this.quantidade,
    required this.fitid,
    required this.formatoData,
    required this.virgulaDecimal,
    required this.semente,
    this.charsetDeclarado,
    this.repeticoesNoMesmoDia = false,
  });

  final String arquivo;

  /// `<ORG>` do bloco de assinatura; `null` = arquivo sem ORG, e o banco sai
  /// do BANKID.
  final String? org;
  final String bankId;
  final String conta;

  /// OFX 1.x (SGML, folhas sem fechamento) ou 2.x (XML).
  final bool sgml;
  final Codificacao codificacao;

  /// O que o cabeçalho DIZ — pode mentir, como em banco real.
  final String? charsetDeclarado;
  final bool crlf;

  /// Data civil do primeiro lançamento.
  final String inicio;

  /// Período coberto: o último lançamento cai em `inicio + dias - 1`.
  final int dias;
  final int quantidade;
  final CoberturaFitid fitid;
  final FormatoData formatoData;
  final bool virgulaDecimal;
  final int semente;

  /// Pix legítimos repetidos: mesmo dia, valor e descrição, FITIDs
  /// distintos — o caso que a deduplicação precisa manter como dois.
  final bool repeticoesNoMesmoDia;
}

/// O conjunto versionado. Mudar aqui é mudar as fixtures — regenere.
const especificacoes = <EspecificacaoFixture>[
  EspecificacaoFixture(
    arquivo: 'a-sgml-cp1252-crlf-54dias.ofx',
    org: 'SINTETICO-A', bankId: '901', conta: '000987651',
    sgml: true, codificacao: Codificacao.cp1252, charsetDeclarado: '1252',
    crlf: true, inicio: '2026-03-09', dias: 54, quantidade: 40,
    fitid: CoberturaFitid.todos, formatoData: FormatoData.comFuso,
    virgulaDecimal: true, semente: 11,
  ),
  EspecificacaoFixture(
    arquivo: 'b-xml-utf8-lf-30dias-fitid-parcial.ofx',
    org: 'SINTETICO-B', bankId: '902', conta: '4471029',
    sgml: false, codificacao: Codificacao.utf8, crlf: false,
    inicio: '2026-01-01', dias: 30, quantidade: 25,
    fitid: CoberturaFitid.parcial, formatoData: FormatoData.curto,
    virgulaDecimal: false, semente: 23,
  ),
  EspecificacaoFixture(
    arquivo: 'c-xml-utf8bom-crlf-7dias-sem-fitid.ofx',
    org: 'SINTETICO-C', bankId: '903', conta: '8820-3',
    sgml: false, codificacao: Codificacao.utf8ComBom, crlf: true,
    inicio: '2026-06-22', dias: 7, quantidade: 6,
    fitid: CoberturaFitid.nenhum, formatoData: FormatoData.comHora,
    virgulaDecimal: false, semente: 37,
  ),
  EspecificacaoFixture(
    arquivo: 'd-sgml-latin1-lf-92dias-sem-org.ofx',
    org: null, bankId: '904', conta: '55501384',
    sgml: true, codificacao: Codificacao.latin1,
    charsetDeclarado: 'ISO-8859-1', crlf: false,
    inicio: '2025-10-01', dias: 92, quantidade: 80,
    fitid: CoberturaFitid.todos, formatoData: FormatoData.comHora,
    virgulaDecimal: false, semente: 41,
  ),
  EspecificacaoFixture(
    // Declara 1252 e entrega UTF-8: a autodetecção precisa ganhar do
    // cabeçalho.
    arquivo: 'e-sgml-utf8-declara-1252-crlf-1dia.ofx',
    org: 'SINTETICO-E', bankId: '905', conta: '31-7',
    sgml: true, codificacao: Codificacao.utf8, charsetDeclarado: '1252',
    crlf: true, inicio: '2026-02-27', dias: 1, quantidade: 3,
    fitid: CoberturaFitid.todos, formatoData: FormatoData.curto,
    virgulaDecimal: true, semente: 53,
  ),
  EspecificacaoFixture(
    arquivo: 'f-xml-cp1252-lf-45dias-fitid-parcial.ofx',
    org: 'SINTETICO-F', bankId: '906', conta: '000000019',
    sgml: false, codificacao: Codificacao.cp1252,
    charsetDeclarado: 'windows-1252', crlf: false,
    inicio: '2026-07-15', dias: 45, quantidade: 30,
    fitid: CoberturaFitid.parcial, formatoData: FormatoData.comFuso,
    virgulaDecimal: false, semente: 67,
  ),
  EspecificacaoFixture(
    arquivo: 'g-sgml-utf8-lf-sem-lancamentos.ofx',
    org: 'SINTETICO-G', bankId: '907', conta: '7002146',
    sgml: true, codificacao: Codificacao.utf8, charsetDeclarado: 'UTF-8',
    crlf: false, inicio: '2026-04-01', dias: 30, quantidade: 0,
    fitid: CoberturaFitid.todos, formatoData: FormatoData.curto,
    virgulaDecimal: false, semente: 71,
  ),
  EspecificacaoFixture(
    arquivo: 'h-xml-utf8-crlf-15dias-pix-repetidos.ofx',
    org: 'SINTETICO-H', bankId: '908', conta: '19283-0',
    sgml: false, codificacao: Codificacao.utf8, crlf: true,
    inicio: '2026-08-03', dias: 15, quantidade: 20,
    fitid: CoberturaFitid.todos, formatoData: FormatoData.comHora,
    virgulaDecimal: false, semente: 89, repeticoesNoMesmoDia: true,
  ),
];

/// Descrições com acento, `&` e um travessão (só representável em cp1252,
/// não em latin-1 — por isso só entra nos arquivos cp1252 e UTF-8).
const _descricoes = [
  'PIX RECEBIDO JOÃO DA SILVA',
  'PIX RECEBIDO MARIA CONCEIÇÃO',
  'TED RECEBIDA CLÍNICA SÃO JOSÉ',
  'PIX ENVIADO ALUGUEL SALA',
  'PAGTO BOLETO ÁGUA E ESGOTO',
  'TARIFA PACOTE SERVIÇOS',
  'PIX RECEBIDO SOUZA & FILHOS',
  'DOC RECEBIDO ANDRÉ LUÍS',
];
const _descricaoComTravessao = 'PIX RECEBIDO CONSULTA – RETORNO';

/// Uma fixture pronta: os bytes e o que o parser tem de devolver.
class FixtureSintetica {
  FixtureSintetica(this.especificacao, this.bytes, this.transacoes);

  final EspecificacaoFixture especificacao;
  final List<int> bytes;
  final List<TransacaoImportada> transacoes;
}

/// Gerador congruencial linear — determinístico e sem depender da
/// implementação de `Random` do SDK, que pode mudar entre versões.
class _Lcg {
  _Lcg(int semente) : _estado = semente;
  int _estado;
  int proximo(int limite) {
    _estado = (_estado * 1103515245 + 12345) & 0x7fffffff;
    return _estado % limite;
  }
}

String _somarDias(String dataCivil, int dias) {
  final d = DateTime.utc(
    int.parse(dataCivil.substring(0, 4)),
    int.parse(dataCivil.substring(5, 7)),
    int.parse(dataCivil.substring(8, 10)),
  ).add(Duration(days: dias));
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${dois(d.month)}-${dois(d.day)}';
}

List<TransacaoImportada> _lancamentos(EspecificacaoFixture e) {
  final rnd = _Lcg(e.semente);
  final saida = <TransacaoImportada>[];
  final permiteTravessao = e.codificacao != Codificacao.latin1;
  for (var i = 0; i < e.quantidade; i++) {
    // Espalha pelo período inteiro, primeiro e último dia inclusive.
    final offset = e.quantidade == 1
        ? 0
        : (i * (e.dias - 1)) ~/ (e.quantidade - 1);
    var descricao = _descricoes[rnd.proximo(_descricoes.length)];
    if (permiteTravessao && i % 7 == 3) descricao = _descricaoComTravessao;
    final credito = descricao.startsWith('PIX RECEBIDO') ||
        descricao.startsWith('TED RECEBIDA') ||
        descricao.startsWith('DOC RECEBIDO');
    // 1 centavo a 25 mil reais; centavos quebrados de propósito.
    final valor = 1 + rnd.proximo(2500000);
    final fitidPresente = switch (e.fitid) {
      CoberturaFitid.todos => true,
      CoberturaFitid.nenhum => false,
      CoberturaFitid.parcial => i % 3 != 1,
    };
    saida.add(TransacaoImportada(
      data: _somarDias(e.inicio, offset),
      valorCentavos: credito ? valor : -valor,
      descricao: descricao,
      idExterno: fitidPresente
          ? '${e.bankId}${e.inicio.replaceAll('-', '')}${i.toString().padLeft(5, '0')}'
          : null,
    ));
  }
  if (e.repeticoesNoMesmoDia && saida.length >= 4) {
    // Três Pix idênticos no mesmo dia, cada um com o seu FITID.
    final base = saida[2];
    for (final j in [3, 4]) {
      saida[j] = TransacaoImportada(
        data: base.data,
        valorCentavos: base.valorCentavos.abs(),
        descricao: 'PIX RECEBIDO JOÃO DA SILVA',
        idExterno: saida[j].idExterno,
      );
    }
    saida[2] = TransacaoImportada(
      data: base.data,
      valorCentavos: base.valorCentavos.abs(),
      descricao: 'PIX RECEBIDO JOÃO DA SILVA',
      idExterno: base.idExterno,
    );
  }
  return saida;
}

String _valor(int centavos, bool virgula) {
  final sinal = centavos < 0 ? '-' : '';
  final abs = centavos.abs();
  final reais = abs ~/ 100;
  final cents = (abs % 100).toString().padLeft(2, '0');
  return '$sinal$reais${virgula ? ',' : '.'}$cents';
}

String _dtposted(String dataCivil, FormatoData f, int i) {
  final base = dataCivil.replaceAll('-', '');
  final hora = (8 + i % 12).toString().padLeft(2, '0');
  return switch (f) {
    FormatoData.curto => base,
    FormatoData.comHora => '$base${hora}3000',
    FormatoData.comFuso => '$base${hora}3000.000[-3:BRT]',
  };
}

String _escapar(String texto) => texto
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

String _texto(EspecificacaoFixture e, List<TransacaoImportada> ts) {
  final l = <String>[];
  final fim = _somarDias(e.inicio, e.dias - 1).replaceAll('-', '');
  final ini = e.inicio.replaceAll('-', '');
  // Folha: SGML sem fechamento, XML fechado.
  String folha(String tag, String valor) =>
      e.sgml ? '<$tag>$valor' : '<$tag>$valor</$tag>';

  if (e.sgml) {
    l.addAll([
      'OFXHEADER:100',
      'DATA:OFXSGML',
      'VERSION:102',
      'SECURITY:NONE',
      'ENCODING:USASCII',
      'CHARSET:${e.charsetDeclarado ?? 'NONE'}',
      'COMPRESSION:NONE',
      'OLDFILEUID:NONE',
      'NEWFILEUID:NONE',
      '',
    ]);
  } else {
    l.addAll([
      '<?xml version="1.0" encoding="${e.charsetDeclarado ?? 'UTF-8'}"?>',
      '<?OFX OFXHEADER="200" VERSION="211" SECURITY="NONE" '
          'OLDFILEUID="NONE" NEWFILEUID="NONE"?>',
    ]);
  }
  l.add('<OFX>');
  l.addAll([
    '<SIGNONMSGSRSV1>',
    '<SONRS>',
    '<STATUS>',
    folha('CODE', '0'),
    folha('SEVERITY', 'INFO'),
    '</STATUS>',
    folha('DTSERVER', '${fim}235959'),
    folha('LANGUAGE', 'POR'),
    if (e.org != null) ...[
      '<FI>',
      folha('ORG', e.org!),
      folha('FID', e.bankId),
      '</FI>',
    ],
    '</SONRS>',
    '</SIGNONMSGSRSV1>',
    '<BANKMSGSRSV1>',
    '<STMTTRNRS>',
    folha('TRNUID', '1'),
    '<STATUS>',
    folha('CODE', '0'),
    folha('SEVERITY', 'INFO'),
    '</STATUS>',
    '<STMTRS>',
    folha('CURDEF', 'BRL'),
    '<BANKACCTFROM>',
    folha('BANKID', e.bankId),
    folha('ACCTID', e.conta),
    folha('ACCTTYPE', 'CHECKING'),
    '</BANKACCTFROM>',
    '<BANKTRANLIST>',
    folha('DTSTART', ini),
    folha('DTEND', fim),
  ]);
  for (var i = 0; i < ts.length; i++) {
    final t = ts[i];
    l.addAll([
      '<STMTTRN>',
      folha('TRNTYPE', t.valorCentavos < 0 ? 'DEBIT' : 'CREDIT'),
      folha('DTPOSTED', _dtposted(t.data, e.formatoData, i)),
      folha('TRNAMT', _valor(t.valorCentavos, e.virgulaDecimal)),
      if (t.idExterno != null) folha('FITID', t.idExterno!),
      folha('MEMO', _escapar(t.descricao)),
      '</STMTTRN>',
    ]);
  }
  l.addAll([
    '</BANKTRANLIST>',
    '<LEDGERBAL>',
    folha('BALAMT', e.virgulaDecimal ? '0,00' : '0.00'),
    folha('DTASOF', fim),
    '</LEDGERBAL>',
    '</STMTRS>',
    '</STMTTRNRS>',
    '</BANKMSGSRSV1>',
    '</OFX>',
    '',
  ]);
  return l.join(e.crlf ? '\r\n' : '\n');
}

/// Windows-1252 para o que as descrições usam: Latin-1 mais o travessão.
List<int> _cp1252(String texto) => [
      for (final c in texto.runes)
        if (c == 0x2013)
          0x96
        else if (c <= 0xFF && (c < 0x80 || c > 0x9F))
          c
        else
          throw ArgumentError('caractere U+${c.toRadixString(16)} fora do '
              'subconjunto cp1252 do gerador'),
    ];

List<int> _bytes(EspecificacaoFixture e, String texto) =>
    switch (e.codificacao) {
      Codificacao.utf8 => utf8.encode(texto),
      Codificacao.utf8ComBom => [0xEF, 0xBB, 0xBF, ...utf8.encode(texto)],
      Codificacao.latin1 => latin1.encode(texto),
      Codificacao.cp1252 => _cp1252(texto),
    };

/// Todas as fixtures, em memória.
List<FixtureSintetica> gerarFixtures() => [
      for (final e in especificacoes)
        () {
          final ts = _lancamentos(e);
          return FixtureSintetica(e, _bytes(e, _texto(e, ts)), ts);
        }(),
    ];

/// Resumo legível do conjunto — versionado ao lado das fixtures para que o
/// eixo de variação de cada uma seja visível sem abrir o gerador.
String manifesto(List<FixtureSintetica> fixtures) {
  const enc = JsonEncoder.withIndent('  ');
  return '${enc.convert({
        'aviso': 'SINTÉTICAS. Provam que parser e gerador concordam; NÃO '
            'provam cobertura de banco real. Ver README.md.',
        'fixtures': [
          for (final f in fixtures)
            {
              'arquivo': f.especificacao.arquivo,
              'ofx': f.especificacao.sgml ? '1.x SGML' : '2.x XML',
              'codificacao': f.especificacao.codificacao.name,
              'charset_declarado': f.especificacao.charsetDeclarado,
              'quebra_de_linha': f.especificacao.crlf ? 'CRLF' : 'LF',
              'conta_final': f.especificacao.conta
                  .replaceAll(RegExp(r'\D'), '')
                  .substring(f.especificacao.conta
                          .replaceAll(RegExp(r'\D'), '')
                          .length -
                      3),
              'periodo_dias': f.especificacao.dias,
              'lancamentos': f.transacoes.length,
              'fitid': f.especificacao.fitid.name,
              'dtposted': f.especificacao.formatoData.name,
              'decimal': f.especificacao.virgulaDecimal ? 'vírgula' : 'ponto',
              'org': f.especificacao.org ?? '(ausente — banco pelo BANKID)',
            },
        ],
      })}\n';
}

/// Escreve as fixtures e o manifesto em `test/fixtures/sinteticas/`.
void main() {
  final dir = Directory('test/fixtures/sinteticas');
  if (!dir.existsSync()) {
    stderr.writeln('rode a partir de packages/desmalha_core');
    exit(2);
  }
  final fixtures = gerarFixtures();
  for (final f in fixtures) {
    File('${dir.path}/${f.especificacao.arquivo}').writeAsBytesSync(f.bytes);
  }
  File('${dir.path}/manifesto.json').writeAsStringSync(manifesto(fixtures));
  stdout.writeln('${fixtures.length} fixtures sintéticas escritas em ${dir.path}');
}
