/// Parser de extratos OFX (Open Financial Exchange), versões 1.x e 2.x.
///
/// OFX 1.x é SGML: cabeçalho `OFXHEADER:100` em texto plano e elementos-folha
/// sem tag de fechamento (`<TRNAMT>-150.00`). OFX 2.x é XML bem-formado.
/// Os agregados `<STMTTRN>…</STMTTRN>` são fechados nas duas versões, o que
/// permite um único caminho de extração para ambas.
///
/// Roda inteiramente no dispositivo: o arquivo bruto nunca vai ao servidor
/// (ADR local-first).
library;

import 'data_civil.dart';
import 'transacao_importada.dart';
import 'valor_monetario.dart';

/// Interpreta o conteúdo de um arquivo OFX já decodificado para texto.
///
/// Lança [ExtratoInvalidoException] se o conteúdo não for OFX. Transações
/// individuais com campos ausentes ou inválidos viram [AvisoImportacao] e são
/// puladas; as demais seguem no resultado.
ExtratoImportado parseOfx(String conteudo) {
  if (!RegExp('<OFX>', caseSensitive: false).hasMatch(conteudo)) {
    throw const ExtratoInvalidoException(
      'o arquivo não contém um documento OFX (<OFX> ausente)',
    );
  }

  final moeda = _valorDaTag(conteudo, 'CURDEF');
  final banco = _valorDaTag(conteudo, 'ORG') ?? _valorDaTag(conteudo, 'BANKID');
  final conta = _valorDaTag(conteudo, 'ACCTID');

  final transacoes = <TransacaoImportada>[];
  final avisos = <AvisoImportacao>[];

  final blocos = RegExp(
    r'<STMTTRN>(.*?)</STMTTRN>',
    caseSensitive: false,
    dotAll: true,
  ).allMatches(conteudo);

  var ordinal = 0;
  for (final bloco in blocos) {
    ordinal++;
    final corpo = bloco.group(1)!;

    final dataBruta = _valorDaTag(corpo, 'DTPOSTED');
    final valorBruto = _valorDaTag(corpo, 'TRNAMT');
    final memo = _valorDaTag(corpo, 'MEMO');
    final name = _valorDaTag(corpo, 'NAME');
    final fitid = _valorDaTag(corpo, 'FITID');

    if (dataBruta == null) {
      avisos.add(AvisoImportacao(
        mensagem: 'transação $ordinal: DTPOSTED ausente — lançamento pulado',
      ));
      continue;
    }
    final data = parseDataOfx(dataBruta);
    if (data == null) {
      avisos.add(AvisoImportacao(
        mensagem: 'transação $ordinal: DTPOSTED inválido '
            '("$dataBruta") — lançamento pulado',
      ));
      continue;
    }

    if (valorBruto == null) {
      avisos.add(AvisoImportacao(
        mensagem: 'transação $ordinal: TRNAMT ausente — lançamento pulado',
      ));
      continue;
    }
    final valor = parseValorOfx(valorBruto);
    if (valor == null) {
      avisos.add(AvisoImportacao(
        mensagem: 'transação $ordinal: TRNAMT inválido '
            '("$valorBruto") — lançamento pulado',
      ));
      continue;
    }

    final descricao = (memo != null && memo.isNotEmpty) ? memo : (name ?? '');
    transacoes.add(TransacaoImportada(
      data: data,
      valorCentavos: valor,
      descricao: descricao,
      idExterno: (fitid == null || fitid.isEmpty) ? null : fitid,
    ));
  }

  if (ordinal == 0 && transacoes.isEmpty) {
    // OFX válido pode não ter lançamentos no período; não é erro, mas o
    // usuário precisa saber que a prévia veio vazia por isso.
    avisos.add(const AvisoImportacao(
      mensagem: 'o arquivo OFX não contém lançamentos (<STMTTRN> ausente)',
    ));
  }

  return ExtratoImportado(
    formato: FormatoExtrato.ofx,
    transacoes: transacoes,
    avisos: avisos,
    banco: banco,
    conta: conta,
    moeda: moeda,
  );
}

/// Extrai o valor do primeiro elemento-folha `<tag>` do trecho, cobrindo as
/// duas sintaxes: SGML (valor termina na próxima tag ou quebra de linha) e
/// XML (`<tag>valor</tag>`).
String? _valorDaTag(String trecho, String tag) {
  final busca = RegExp('<$tag>([^<\r\n]*)', caseSensitive: false);
  final resultado = busca.firstMatch(trecho);
  if (resultado == null) return null;
  final bruto = resultado.group(1)!.trim();
  return _decodificarEntidadesXml(bruto);
}

/// OFX 2.x escapa entidades XML nos valores; OFX 1.x usa `&amp;` e afins com
/// frequência mesmo sendo SGML. Decodificar aqui vale para os dois.
String _decodificarEntidadesXml(String texto) {
  if (!texto.contains('&')) return texto;
  return texto
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');
}
