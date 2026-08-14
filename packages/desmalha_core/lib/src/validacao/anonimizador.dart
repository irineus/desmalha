/// Anonimização estrutural de extratos OFX/CSV.
///
/// Gera uma cópia do arquivo com nomes/CPFs fictícios e valores perturbados,
/// preservando a ESTRUTURA (delimitadores, formato de data, encoding, linhas
/// de saldo, aspas, quebras de linha) — o insumo seguro para virar fixture
/// de regressão e perfil de banco novo, sem que o extrato real entre no
/// repositório.
///
/// É uma HEURÍSTICA determinística (mesma entrada → mesma saída), não uma
/// garantia: o usuário deve revisar o arquivo gerado antes de compartilhar.
/// Regras de substituição:
/// - CPFs (`000.000.000-00`, inclusive mascarados com `•`/`*`) → fictícios,
///   preservando distinção: originais diferentes viram fictícios diferentes.
/// - Sequências de 5+ dígitos (contas, telefones, documentos) → dígitos
///   fictícios de mesmo comprimento.
/// - Prováveis nomes de pessoa (2+ palavras fora do vocabulário bancário) →
///   nomes fictícios, preservando caixa alta.
/// - Valores monetários → perturbados em até ±15%, mantendo o sinal.
/// - Identificadores externos (FITID/coluna de id) → sequenciais fictícios,
///   preservando duplicatas (insumo do card de deduplicação).
///
/// Sem `double` em valor algum e sem fonte de aleatoriedade do sistema:
/// a perturbação usa um gerador congruente linear com semente fixa.
library;

import '../extrato/perfil_csv.dart';
import '../extrato/valor_monetario.dart';

/// Anonimizador com estado (mapeamentos e gerador determinísticos).
///
/// Use UMA instância por arquivo: os mapeamentos garantem que o mesmo CPF,
/// nome ou id repetido no arquivo vira sempre o mesmo substituto.
class Anonimizador {
  Anonimizador({int semente = 0xDE5A}) : _estado = semente;

  int _estado;

  final Map<String, String> _cpfs = {};
  final Map<String, String> _digitos = {};
  final Map<String, String> _nomes = {};
  final Map<String, String> _ids = {};

  static const _nomesFicticios = [
    'ANA FICTICIA ALVES',
    'BRUNO FICTICIO BARROS',
    'CARLA FICTICIA CASTRO',
    'DAVI FICTICIO DUARTE',
    'ELISA FICTICIA ESTEVES',
    'FABIO FICTICIO FARIA',
    'GILDA FICTICIA GOMES',
    'HUGO FICTICIO HORTA',
    'IARA FICTICIA IGREJAS',
    'JONAS FICTICIO JUSTO',
    'LIVIA FICTICIA LIMA',
    'MARCOS FICTICIO MOTA',
  ];

  /// Vocabulário bancário que NUNCA é tratado como nome de pessoa —
  /// preservá-lo mantém a estrutura que o parser e os perfis reconhecem.
  /// Comparação sem caixa e sem acentos.
  static const _vocabularioBancario = {
    'pix', 'ted', 'doc', 'transferencia', 'transf', 'recebida', 'recebido',
    'enviada', 'enviado', 'compra', 'cartao', 'debito', 'credito',
    'pagamento', 'pagto', 'pgto', 'boleto', 'tarifa', 'saque', 'deposito',
    'rendimento', 'aplicacao', 'resgate', 'saldo', 'anterior', 'juros',
    'iof', 'estorno', 'devolucao', 'liquidacao', 'cobranca', 'dinheiro',
    'celular', 'conta', 'corrente', 'poupanca', 'banco', 'agencia',
    'titular', 'folha', 'salario', 'mensalidade', 'assinatura', 'servico',
    'servicos', 'honorarios', 'consulta', 'sessao', 'pacote', 'parcela',
    'referente', 'pelo', 'pela', 'via', 'em', 'no', 'na', 'com', 'sem',
    'para', 'por', 'a', 'o', 'qr', 'code', 'internet', 'mobile', 'app',
    'caixa', 'eletronico', 'automatico', 'agendada', 'agendado', 'mesma',
    'outra', 'mes', 'dia', 'ltda', 'me', 'mei', 'sa', 'cnpj', 'cpf',
  };

  static const _conectivosDeNome = {'da', 'de', 'do', 'das', 'dos', 'e'};

  /// Próximo pseudoaleatório em `[0, limite)` — LCG clássico, sem `double`.
  int _proximo(int limite) {
    _estado = (_estado * 1103515245 + 12345) & 0x7FFFFFFF;
    return _estado % limite;
  }

  // ── Substituições elementares ──────────────────────────────────────────

  static final _regexCpf = RegExp(r'[\d•*]{3}\.\d{3}\.\d{3}-[\d•*]{2}');
  static final _regexDigitosLongos = RegExp(r'\d{5,}');

  String _cpfFicticio(String original) => _cpfs.putIfAbsent(original, () {
        final n = (_cpfs.length + 1).toString().padLeft(9, '0');
        final meio = '${n.substring(0, 3)}.${n.substring(3, 6)}'
            '.${n.substring(6, 9)}';
        final mascara = original.contains('•')
            ? '•'
            : (original.contains('*') ? '*' : null);
        if (mascara == null) return '$meio-00';
        // Mantém o padrão de mascaramento do banco (ex.: •••.123.456-••).
        return '$mascara$mascara$mascara${meio.substring(3)}-$mascara$mascara';
      });

  String _digitosFicticios(String original) =>
      _digitos.putIfAbsent(original, () {
        final buffer = StringBuffer();
        for (var i = 0; i < original.length; i++) {
          buffer.write(_proximo(10));
        }
        return buffer.toString();
      });

  String _nomeFicticio(String original, {required bool caixaAlta}) {
    final chave = _semAcentos(original.toLowerCase());
    final nome = _nomes.putIfAbsent(
      chave,
      () => _nomesFicticios[_nomes.length % _nomesFicticios.length],
    );
    if (caixaAlta) return nome;
    return nome
        .split(' ')
        .map((p) => p[0] + p.substring(1).toLowerCase())
        .join(' ');
  }

  /// Id externo fictício, preservando duplicatas do original.
  String idFicticio(String original) => _ids.putIfAbsent(
        original,
        () => 'FIC${(_ids.length + 1).toString().padLeft(6, '0')}',
      );

  /// Perturba centavos em até ±15%, mantendo sinal e nunca zerando.
  int perturbarCentavos(int centavos) {
    if (centavos == 0) return 0;
    final permilagem = _proximo(301) - 150; // [-150, +150] ‰
    var perturbado = centavos + (centavos.abs() * permilagem) ~/ 1000;
    if (centavos > 0 && perturbado <= 0) perturbado = 1;
    if (centavos < 0 && perturbado >= 0) perturbado = -1;
    return perturbado;
  }

  // ── Texto livre (descrições, MEMO/NAME) ────────────────────────────────

  /// Anonimização completa de texto livre: CPFs, dígitos longos e prováveis
  /// nomes de pessoa.
  String anonimizarTexto(String texto) =>
      _substituirNomes(anonimizarConservador(texto));

  /// Anonimização conservadora (cabeçalhos e campos estruturais): só CPFs e
  /// sequências longas de dígitos — nunca palavras, para não corromper
  /// rótulos como `Data Lançamento` que o perfil do banco espera.
  String anonimizarConservador(String texto) => texto
      .replaceAllMapped(_regexCpf, (m) => _cpfFicticio(m.group(0)!))
      .replaceAllMapped(
          _regexDigitosLongos, (m) => _digitosFicticios(m.group(0)!));

  String _substituirNomes(String texto) {
    final palavras = texto.split(' ');

    // 1ª passada: palavra é candidata a nome se for só letras (2+) e não
    // pertencer ao vocabulário bancário.
    final candidata = List<bool>.generate(palavras.length, (i) {
      final palavra = palavras[i];
      if (palavra.length < 2) return false;
      if (!_soLetras(palavra)) return false;
      return !_vocabularioBancario.contains(_semAcentos(palavra.toLowerCase()));
    });

    // 2ª passada: conectivos (da/de/do/…) entram no nome quando cercados
    // por candidatas — "JOAO DA SILVA" é um nome só.
    for (var i = 1; i < palavras.length - 1; i++) {
      if (candidata[i]) continue;
      if (_conectivosDeNome.contains(_semAcentos(palavras[i].toLowerCase())) &&
          candidata[i - 1] &&
          candidata[i + 1]) {
        candidata[i] = true;
      }
    }

    // Substitui sequências de 2+ candidatas; palavra isolada fica (heurística
    // documentada: "Uber" sozinho não é tratado como nome).
    final resultado = <String>[];
    var i = 0;
    while (i < palavras.length) {
      if (!candidata[i]) {
        resultado.add(palavras[i]);
        i++;
        continue;
      }
      var fim = i;
      while (fim + 1 < palavras.length && candidata[fim + 1]) {
        fim++;
      }
      if (fim == i) {
        resultado.add(palavras[i]);
        i++;
        continue;
      }
      final trecho = palavras.sublist(i, fim + 1).join(' ');
      final caixaAlta = trecho == trecho.toUpperCase();
      resultado.add(_nomeFicticio(trecho, caixaAlta: caixaAlta));
      i = fim + 1;
    }

    return resultado.join(' ');
  }

  static bool _soLetras(String palavra) {
    for (final ponto in palavra.runes) {
      final ehAscii = (ponto >= 0x41 && ponto <= 0x5A) ||
          (ponto >= 0x61 && ponto <= 0x7A);
      final ehLatino = ponto >= 0xC0 && ponto <= 0xFF && ponto != 0xD7 &&
          ponto != 0xF7;
      if (!ehAscii && !ehLatino) return false;
    }
    return true;
  }

  static String _semAcentos(String texto) {
    const mapa = {
      'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
      'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c', 'ñ': 'n',
    };
    final buffer = StringBuffer();
    for (var i = 0; i < texto.length; i++) {
      buffer.write(mapa[texto[i]] ?? texto[i]);
    }
    return buffer.toString();
  }
}

// ── OFX ──────────────────────────────────────────────────────────────────

/// Anonimiza um OFX preservando a estrutura SGML/XML intacta.
String anonimizarOfx(String conteudo, {Anonimizador? anonimizador}) {
  final anon = anonimizador ?? Anonimizador();
  var texto = conteudo;
  texto = _substituirTagOfx(
      texto, 'ACCTID', (v) => anon.anonimizarConservador(v));
  texto = _substituirTagOfx(texto, 'FITID', anon.idFicticio);
  texto = _substituirTagOfx(
      texto, 'TRNAMT', (v) => _perturbarValorOfx(v, anon));
  texto = _substituirTagOfx(
      texto, 'BALAMT', (v) => _perturbarValorOfx(v, anon));
  texto = _substituirTagOfx(texto, 'MEMO', anon.anonimizarTexto);
  texto = _substituirTagOfx(texto, 'NAME', anon.anonimizarTexto);
  return texto;
}

/// Substitui o valor dos elementos-folha `<tag>`, nas duas sintaxes (SGML
/// sem fechamento e XML `<tag>…</tag>` — o `</tag>` fica fora do grupo).
String _substituirTagOfx(
  String conteudo,
  String tag,
  String Function(String valor) transformar,
) {
  final regex = RegExp('(<$tag>)([^<\r\n]*)', caseSensitive: false);
  return conteudo.replaceAllMapped(regex, (m) {
    final valor = m.group(2)!.trim();
    if (valor.isEmpty) return m.group(0)!;
    return '${m.group(1)}${transformar(valor)}';
  });
}

String _perturbarValorOfx(String bruto, Anonimizador anon) {
  final centavos = parseValorOfx(bruto);
  if (centavos == null) return bruto;
  final perturbado = anon.perturbarCentavos(centavos);
  final separador = bruto.contains(',') ? ',' : '.';
  return _renderizarCentavos(perturbado, separador);
}

/// Renderiza centavos como texto (`-1234.56`), sem separador de milhar.
String _renderizarCentavos(int centavos, String separadorDecimal) {
  final sinal = centavos < 0 ? '-' : '';
  final absoluto = centavos.abs();
  return '$sinal${absoluto ~/ 100}$separadorDecimal'
      '${(absoluto % 100).toString().padLeft(2, '0')}';
}

// ── CSV ──────────────────────────────────────────────────────────────────

/// Anonimiza um CSV dirigido pelo [perfil], preservando delimitadores,
/// aspas, quebras de linha (LF/CRLF/CR), cabeçalhos e linhas de saldo.
String anonimizarCsv(
  String conteudo,
  PerfilCsv perfil, {
  Anonimizador? anonimizador,
}) {
  final anon = anonimizador ?? Anonimizador();
  final registros = _lerRegistrosCsv(conteudo, perfil.delimitador);

  for (var i = 0; i < registros.length; i++) {
    final registro = registros[i];
    final campos = registro.campos;

    if (i < perfil.linhasCabecalho) {
      // Preâmbulos carregam nome do titular e número da conta (ex.: Inter),
      // mas também rótulos de coluna que o perfil espera — tratamento
      // conservador: só CPFs e sequências longas de dígitos.
      for (final campo in campos) {
        campo.texto = anon.anonimizarConservador(campo.texto);
      }
      continue;
    }

    if (campos.length == 1 && campos[0].texto.trim().isEmpty) continue;

    for (var c = 0; c < campos.length; c++) {
      final campo = campos[c];
      if (c == perfil.colunaValor) {
        final centavos =
            parseValorMonetario(campo.texto, perfil.formatoValor);
        if (centavos != null) {
          final separador =
              perfil.formatoValor == FormatoValor.virgulaDecimal ? ',' : '.';
          campo.texto =
              _renderizarCentavos(anon.perturbarCentavos(centavos), separador);
        }
      } else if (c == perfil.colunaIdExterno) {
        final id = campo.texto.trim();
        if (id.isNotEmpty) campo.texto = anon.idFicticio(id);
      } else if (c == perfil.colunaDescricao) {
        final descricao = campo.texto.trim().toLowerCase();
        final ehLinhaDeSaldo = perfil.descricoesIgnoradas
            .any((d) => d.trim().toLowerCase() == descricao);
        // Linhas de saldo são estrutura que a fixture deve preservar.
        if (!ehLinhaDeSaldo) campo.texto = anon.anonimizarTexto(campo.texto);
      } else if (c == perfil.colunaData || c == perfil.colunaTipo) {
        // Estrutura pura: preservar.
      } else {
        campo.texto = anon.anonimizarConservador(campo.texto);
      }
    }
  }

  return _escreverRegistrosCsv(registros, perfil.delimitador);
}

class _CampoCsv {
  _CampoCsv(this.texto, {required this.entreAspas});

  String texto;

  /// O campo estava entre aspas no original — a serialização preserva.
  final bool entreAspas;
}

class _RegistroCsv {
  _RegistroCsv(this.campos, this.terminador);

  final List<_CampoCsv> campos;

  /// Quebra de linha que encerrou o registro (`\n`, `\r\n`, `\r` ou vazio
  /// na última linha sem quebra final) — preservada byte a byte.
  final String terminador;
}

/// Tokenizador com ida e volta: `_escreverRegistrosCsv(_lerRegistrosCsv(x))`
/// reproduz `x` byte a byte para CSVs bem formados. Segue as mesmas regras
/// do parser (`csv_parser.dart`): aspas só abrem campo quando ele começa,
/// `""` escapa aspas, campo entre aspas pode conter delimitador e quebras.
List<_RegistroCsv> _lerRegistrosCsv(String conteudo, String delimitador) {
  final registros = <_RegistroCsv>[];
  var campos = <_CampoCsv>[];
  final campo = StringBuffer();
  var campoComAspas = false;
  var entreAspas = false;

  void fechaCampo() {
    campos.add(_CampoCsv(campo.toString(), entreAspas: campoComAspas));
    campo.clear();
    campoComAspas = false;
  }

  void fechaRegistro(String terminador) {
    fechaCampo();
    registros.add(_RegistroCsv(campos, terminador));
    campos = <_CampoCsv>[];
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
      campo.write(c);
      i++;
      continue;
    }

    if (c == '"' && campo.isEmpty && !campoComAspas) {
      entreAspas = true;
      campoComAspas = true;
      i++;
      continue;
    }
    if (c == delimitador) {
      fechaCampo();
      i++;
      continue;
    }
    if (c == '\r') {
      final crlf = i + 1 < conteudo.length && conteudo[i + 1] == '\n';
      fechaRegistro(crlf ? '\r\n' : '\r');
      i += crlf ? 2 : 1;
      continue;
    }
    if (c == '\n') {
      fechaRegistro('\n');
      i++;
      continue;
    }
    campo.write(c);
    i++;
  }

  if (campo.isNotEmpty || campoComAspas || campos.isNotEmpty) {
    fechaRegistro('');
  }

  return registros;
}

String _escreverRegistrosCsv(
  List<_RegistroCsv> registros,
  String delimitador,
) {
  final buffer = StringBuffer();
  for (final registro in registros) {
    for (var c = 0; c < registro.campos.length; c++) {
      if (c > 0) buffer.write(delimitador);
      final campo = registro.campos[c];
      if (campo.entreAspas) {
        buffer
          ..write('"')
          ..write(campo.texto.replaceAll('"', '""'))
          ..write('"');
      } else {
        buffer.write(campo.texto);
      }
    }
    buffer.write(registro.terminador);
  }
  return buffer.toString();
}
