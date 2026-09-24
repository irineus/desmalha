/// Parser de extratos CSV dirigido por [PerfilCsv].
///
/// O tokenizador segue o RFC 4180 no essencial: campos entre aspas podem
/// conter o delimitador e quebras de linha, e aspas internas são escapadas
/// por duplicação (`""`). O delimitador vem do perfil do banco.
///
/// Roda inteiramente no dispositivo: o arquivo bruto nunca vai ao servidor
/// (ADR local-first).
library;

import 'data_civil.dart';
import 'perfil_csv.dart';
import 'transacao_importada.dart';
import 'valor_monetario.dart';

/// Interpreta o conteúdo de um CSV já decodificado, segundo o [perfil].
///
/// Lança [ExtratoInvalidoException] quando o arquivo não tem nem as linhas
/// de cabeçalho que o perfil promete. Linhas individuais problemáticas viram
/// [AvisoImportacao] com o número da linha física e são puladas.
ExtratoImportado parseCsv(String conteudo, PerfilCsv perfil) {
  final linhas = _tokenizar(conteudo, perfil.delimitador);

  if (linhas.length < perfil.linhasCabecalho) {
    throw ExtratoInvalidoException(
      'o arquivo tem ${linhas.length} linha(s), menos que as '
      '${perfil.linhasCabecalho} de cabeçalho do perfil "${perfil.id}"',
    );
  }

  final maiorColuna = perfil.colunasLidas.reduce((a, b) => a > b ? a : b);

  final transacoes = <TransacaoImportada>[];
  final avisos = <AvisoImportacao>[];

  for (final linha in linhas.skip(perfil.linhasCabecalho)) {
    final campos = linha.campos;
    if (campos.length == 1 && campos[0].trim().isEmpty) continue;

    if (campos.length <= maiorColuna) {
      avisos.add(AvisoImportacao(
        linha: linha.numero,
        mensagem: 'esperava ao menos ${maiorColuna + 1} colunas, '
            'encontrou ${campos.length} — linha pulada',
      ));
      continue;
    }

    final descricao = campos[perfil.colunaDescricao].trim();
    final descricaoNormalizada = descricao.toLowerCase();
    if (perfil.descricoesIgnoradas
        .any((d) => d.trim().toLowerCase() == descricaoNormalizada)) {
      continue;
    }

    final dataBruta = campos[perfil.colunaData];
    final data = parseDataCivil(dataBruta, perfil.formatoData);
    if (data == null) {
      avisos.add(AvisoImportacao(
        linha: linha.numero,
        mensagem: 'data inválida para o formato '
            '"${perfil.formatoData}": "${dataBruta.trim()}" — linha pulada',
      ));
      continue;
    }

    final int valor;
    if (perfil.creditoDebitoSeparados) {
      final resultado = _valorDeCreditoDebito(
        campos[perfil.colunaCredito!],
        campos[perfil.colunaDebito!],
        perfil.formatoValor,
      );
      if (resultado.aviso != null) {
        avisos.add(AvisoImportacao(
          linha: linha.numero,
          mensagem: '${resultado.aviso} — linha pulada',
        ));
        continue;
      }
      valor = resultado.valor!;
    } else {
      final valorBruto = campos[perfil.colunaValor!];
      final lido = parseValorMonetario(valorBruto, perfil.formatoValor);
      if (lido == null) {
        avisos.add(AvisoImportacao(
          linha: linha.numero,
          mensagem: 'valor inválido: "${valorBruto.trim()}" — linha pulada',
        ));
        continue;
      }
      final colunaTipo = perfil.colunaTipo;
      if (colunaTipo != null) {
        final tipo = campos[colunaTipo].trim().toLowerCase();
        final debito = perfil.marcadorDebito!.trim().toLowerCase();
        valor = tipo == debito ? -lido.abs() : lido.abs();
      } else {
        valor = lido;
      }
    }

    final colunaId = perfil.colunaIdExterno;
    final idExterno =
        colunaId == null ? null : campos[colunaId].trim();

    transacoes.add(TransacaoImportada(
      data: data,
      valorCentavos: valor,
      descricao: descricao,
      idExterno: (idExterno == null || idExterno.isEmpty) ? null : idExterno,
    ));
  }

  return ExtratoImportado(
    formato: FormatoExtrato.csv,
    transacoes: transacoes,
    avisos: avisos,
    banco: perfil.banco,
  );
}

/// Valor de uma linha no layout de crédito e débito em colunas separadas.
///
/// O sinal vem da COLUNA, não do número: crédito entra positivo, débito
/// negativo — `850,00` e `-850,00` na coluna Débito dão o mesmo lançamento,
/// porque bancos escrevem das duas formas. Coluna com `0,00` conta como
/// vazia (há banco que preenche a outra coluna com zero).
///
/// Tudo o que não fecha vira aviso e a linha é pulada, nunca adivinhada:
/// - as duas preenchidas com valor diferente de zero;
/// - nenhuma preenchida (ou as duas zeradas);
/// - valor negativo na coluna Crédito. Um estorno escrito ali pode ser
///   "crédito negativo" ou "débito na coluna errada", e tratar como receita
///   positiva inflaria o rendimento — o erro não se escolhe, se mostra.
({int? valor, String? aviso}) _valorDeCreditoDebito(
  String creditoBruto,
  String debitoBruto,
  FormatoValor formato,
) {
  int? ler(String bruto) =>
      bruto.trim().isEmpty ? 0 : parseValorMonetario(bruto, formato);

  final credito = ler(creditoBruto);
  if (credito == null) {
    return (valor: null, aviso: 'crédito inválido: "${creditoBruto.trim()}"');
  }
  final debito = ler(debitoBruto);
  if (debito == null) {
    return (valor: null, aviso: 'débito inválido: "${debitoBruto.trim()}"');
  }
  if (credito < 0) {
    return (
      valor: null,
      aviso: 'valor negativo na coluna de crédito: "${creditoBruto.trim()}"',
    );
  }
  if (credito != 0 && debito != 0) {
    return (
      valor: null,
      aviso: 'crédito e débito preenchidos na mesma linha '
          '("${creditoBruto.trim()}" / "${debitoBruto.trim()}")',
    );
  }
  if (credito == 0 && debito == 0) {
    return (valor: null, aviso: 'linha sem valor de crédito nem de débito');
  }
  return (valor: credito != 0 ? credito : -debito.abs(), aviso: null);
}

class _Linha {
  const _Linha(this.numero, this.campos);

  /// Número da linha física (1-based) onde a linha lógica COMEÇA — campos
  /// entre aspas podem se estender por mais de uma linha física.
  final int numero;
  final List<String> campos;
}

List<_Linha> _tokenizar(String conteudo, String delimitador) {
  final linhas = <_Linha>[];
  var campos = <String>[];
  final campo = StringBuffer();
  var entreAspas = false;
  var linhaFisica = 1;
  var inicioLinhaLogica = 1;
  var linhaTemConteudo = false;

  void fechaCampo() {
    campos.add(campo.toString());
    campo.clear();
  }

  void fechaLinha() {
    fechaCampo();
    linhas.add(_Linha(inicioLinhaLogica, campos));
    campos = <String>[];
    linhaTemConteudo = false;
  }

  var i = 0;
  while (i < conteudo.length) {
    final c = conteudo[i];

    if (entreAspas) {
      if (c == '"') {
        final proxima = i + 1 < conteudo.length ? conteudo[i + 1] : null;
        if (proxima == '"') {
          campo.write('"');
          i += 2;
          continue;
        }
        entreAspas = false;
        i++;
        continue;
      }
      if (c == '\n') linhaFisica++;
      campo.write(c);
      i++;
      continue;
    }

    if (c == '"' && campo.isEmpty) {
      entreAspas = true;
      linhaTemConteudo = true;
      i++;
      continue;
    }
    if (c == delimitador) {
      fechaCampo();
      linhaTemConteudo = true;
      i++;
      continue;
    }
    if (c == '\r') {
      // CRLF ou CR isolado encerram a linha; o \n de um CRLF é consumido.
      if (i + 1 < conteudo.length && conteudo[i + 1] == '\n') i++;
      fechaLinha();
      linhaFisica++;
      inicioLinhaLogica = linhaFisica;
      i++;
      continue;
    }
    if (c == '\n') {
      fechaLinha();
      linhaFisica++;
      inicioLinhaLogica = linhaFisica;
      i++;
      continue;
    }
    campo.write(c);
    linhaTemConteudo = true;
    i++;
  }

  // Última linha sem quebra final.
  if (linhaTemConteudo || campo.isNotEmpty || campos.isNotEmpty) {
    fechaLinha();
  }

  return linhas;
}
