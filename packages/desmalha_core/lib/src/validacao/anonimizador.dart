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
/// - Prováveis nomes de pessoa (palavras fora do vocabulário bancário) →
///   nomes fictícios, preservando caixa alta. Palavra ISOLADA também é
///   substituída: num MEMO de Pix brasileiro, palavra solta fora do
///   vocabulário é quase sempre primeiro nome. O custo é embaralhar nome de
///   estabelecimento junto (`CLARO`, `CEEE`), e ele foi aceito — errar para
///   o lado de anonimizar demais é o único erro barato aqui.
/// - Dígitos colados à palavra são separados antes da avaliação
///   (`SHIRLEI06` → `SHIRLEI` + `06`) e o sufixo é preservado: banco que
///   trunca o MEMO em largura fixa e cola a data no fim (Itaú) escondia o
///   nome inteiro da heurística.
/// - Valores monetários → perturbados em até ±15%, mantendo o sinal.
/// - Identificadores externos (FITID/coluna de id) → sequenciais fictícios,
///   preservando duplicatas (insumo do card de deduplicação).
///
/// Sem `double` em valor algum e sem fonte de aleatoriedade do sistema:
/// a perturbação usa um gerador congruente linear com semente fixa.
library;

import '../extrato/data_civil.dart';
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

  /// Substitutos de palavra ISOLADA. Um nome só, e não o trio acima: o MEMO
  /// do banco tem largura fixa, e trocar uma palavra por três descolaria a
  /// fixture do tamanho que o arquivo real tem.
  static const _primeirosNomesFicticios = [
    'FICTNOME',
    'FICTALVES',
    'FICTBARROS',
    'FICTCASTRO',
    'FICTDUARTE',
    'FICTESTEVES',
    'FICTFARIA',
    'FICTGOMES',
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
    // Palavras funcionais: desde que palavra ISOLADA passou a ser
    // substituída, um "as" ou "uma" solto viraria nome fictício e sujaria a
    // fixture sem ganho nenhum de privacidade.
    'as', 'os', 'um', 'uma', 'uns', 'umas', 'ao', 'aos', 'nos', 'nas',
    'este', 'esta', 'esse', 'essa', 'isso', 'que', 'sao', 'ate', 'apos',
    'antes', 'sobre', 'entre', 'nao', 'sim', 'mais', 'menos', 'total',
    'valor', 'data', 'numero', 'ref', 'obs', 'id', 'lancamento',
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

  String _nomeFicticio(
    String original, {
    required bool caixaAlta,
    required bool isolada,
  }) {
    final chave = _semAcentos(original.toLowerCase());
    final pool = isolada ? _primeirosNomesFicticios : _nomesFicticios;
    final nome = _nomes.putIfAbsent(
      chave,
      () => pool[_nomes.length % pool.length],
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

    // 1ª passada: separa o prefixo de letras do resto de cada palavra. O
    // resto existe porque banco trunca o MEMO em largura fixa e cola a data
    // no fim (`SHIRLEI06`): sem separar, o token não é "só letras", é
    // reprovado como candidato, e o nome inteiro escapa da heurística.
    final letras = <String>[];
    final restos = <String>[];
    for (final palavra in palavras) {
      var corte = 0;
      while (corte < palavra.length && _ehLetra(palavra.codeUnitAt(corte))) {
        corte++;
      }
      letras.add(palavra.substring(0, corte));
      restos.add(palavra.substring(corte));
    }

    // Candidata a nome: prefixo de 2+ letras fora do vocabulário bancário.
    final candidata = List<bool>.generate(palavras.length, (i) {
      if (letras[i].length < 2) return false;
      return !_vocabularioBancario.contains(_semAcentos(letras[i].toLowerCase()));
    });

    // 2ª passada: conectivos (da/de/do/…) entram no nome quando cercados
    // por candidatas — "JOAO DA SILVA" é um nome só.
    for (var i = 1; i < palavras.length - 1; i++) {
      if (candidata[i]) continue;
      if (_conectivosDeNome.contains(_semAcentos(letras[i].toLowerCase())) &&
          candidata[i - 1] &&
          candidata[i + 1]) {
        candidata[i] = true;
      }
    }

    // Substitui toda sequência de candidatas, INCLUSIVE de uma só palavra:
    // em MEMO de Pix, palavra solta fora do vocabulário é quase sempre
    // primeiro nome, e deixá-la passar foi o que vazou nomes reais no
    // primeiro extrato de verdade. O que sobra depois das letras (a data
    // colada) é preservado — é estrutura do arquivo.
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

      // Candidata SOZINHA só vira nome com 3+ letras e fora dos conectivos:
      // nome de pessoa com duas letras não existe na prática, e sem esse
      // piso um "de" ou "as" solto viraria nome fictício.
      if (fim == i &&
          (letras[i].length < 3 ||
              _conectivosDeNome.contains(_semAcentos(letras[i].toLowerCase())))) {
        resultado.add(palavras[i]);
        i++;
        continue;
      }

      final trecho = [for (var j = i; j <= fim; j++) letras[j]].join(' ');
      final caixaAlta = trecho == trecho.toUpperCase();
      final sufixo = [for (var j = i; j <= fim; j++) restos[j]].join();
      resultado.add(_nomeFicticio(
            trecho,
            caixaAlta: caixaAlta,
            isolada: fim == i,
          ) +
          sufixo);
      i = fim + 1;
    }

    return resultado.join(' ');
  }

  static bool _ehLetra(int ponto) {
    final ehAscii = (ponto >= 0x41 && ponto <= 0x5A) ||
        (ponto >= 0x61 && ponto <= 0x7A);
    final ehLatino =
        ponto >= 0xC0 && ponto <= 0xFF && ponto != 0xD7 && ponto != 0xF7;
    return ehAscii || ehLatino;
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
  // TRNAMT não carrega separador de milhar (parseValorOfx rejeita).
  return _renderizarCentavos(perturbado, separador);
}

/// Renderiza centavos como texto (`-1234.56`).
///
/// Com [separadorMilhar] não nulo, reagrupa a parte inteira de três em três
/// (`-1.234,56`): o agrupamento é ESTRUTURA do arquivo do banco, e uma
/// fixture que o perde deixa de exercitar justamente o caminho onde um
/// `formatoValor` errado no perfil morde.
String _renderizarCentavos(
  int centavos,
  String separadorDecimal, {
  String? separadorMilhar,
}) {
  final sinal = centavos < 0 ? '-' : '';
  final absoluto = centavos.abs();
  var inteira = (absoluto ~/ 100).toString();
  if (separadorMilhar != null) {
    final buffer = StringBuffer();
    for (var i = 0; i < inteira.length; i++) {
      if (i > 0 && (inteira.length - i) % 3 == 0) buffer.write(separadorMilhar);
      buffer.write(inteira[i]);
    }
    inteira = buffer.toString();
  }
  return '$sinal$inteira$separadorDecimal'
      '${(absoluto % 100).toString().padLeft(2, '0')}';
}

/// Separadores da convenção, na ordem (decimal, milhar).
(String, String) _separadoresDe(FormatoValor formato) =>
    formato == FormatoValor.virgulaDecimal ? (',', '.') : ('.', ',');

/// Perturba um campo de valor preservando a convenção e o agrupamento de
/// milhar do original. Retorna `null` quando o texto não é valor no [formato].
String? _perturbarCampoValor(
  String bruto,
  FormatoValor formato,
  Anonimizador anon,
) {
  final centavos = parseValorMonetario(bruto, formato);
  if (centavos == null) return null;
  final (decimal, milhar) = _separadoresDe(formato);
  return _renderizarCentavos(
    anon.perturbarCentavos(centavos),
    decimal,
    separadorMilhar: bruto.contains(milhar) ? milhar : null,
  );
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
        final perturbado =
            _perturbarCampoValor(campo.texto, perfil.formatoValor, anon);
        if (perturbado != null) campo.texto = perturbado;
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

// ── CSV de banco ainda sem perfil ────────────────────────────────────────

/// Formatos de data testados na detecção de linha de lançamento.
///
/// Não é o catálogo de formatos suportados pelo parser — é só o conjunto que
/// permite reconhecer QUE uma linha é lançamento, para não tratar rótulo de
/// coluna como texto livre.
const _formatosDataConhecidos = [
  'dd/MM/yyyy',
  'dd-MM-yyyy',
  'dd.MM.yyyy',
  'yyyy-MM-dd',
  'yyyy/MM/dd',
  'dd/MM/yy',
  'ddMMyyyy',
  'yyyyMMdd',
];

/// Campo com cara de valor monetário: parte decimal de exatamente dois
/// dígitos. Restringir a isso é o que impede perturbar número de agência,
/// identificador de lançamento ou data compacta.
final _regexValorAparente = RegExp(r'^\d{1,3}([.,]\d{3})+[.,]\d{2}$|^\d+[.,]\d{2}$');

/// O que a anonimização sem perfil conseguiu inferir da estrutura.
///
/// São só agregados — nenhum conteúdo do extrato. É o que pode ser colado de
/// volta numa sessão de planejamento para construir o perfil do banco.
class EstruturaCsvInferida {
  const EstruturaCsvInferida({
    required this.delimitador,
    required this.colunas,
    required this.linhasPreambulo,
    required this.linhasLancamento,
  });

  /// Delimitador usado (detectado ou imposto por quem chamou).
  final String delimitador;

  /// Número de colunas das linhas de lançamento (o valor mais frequente).
  final int colunas;

  /// Linhas sem data reconhecível — cabeçalhos, preâmbulos e rodapés.
  /// Elas recebem tratamento CONSERVADOR para que os rótulos de coluna
  /// sobrevivam, e por isso são as que o usuário precisa revisar à mão.
  final int linhasPreambulo;

  /// Linhas com ao menos um campo de data reconhecível.
  final int linhasLancamento;
}

/// Resultado da anonimização de um CSV de banco ainda sem perfil.
class AnonimizacaoSemPerfil {
  const AnonimizacaoSemPerfil({
    required this.conteudo,
    required this.estrutura,
  });

  final String conteudo;
  final EstruturaCsvInferida estrutura;
}

/// Detecta o delimitador de um CSV pela consistência do número de campos.
///
/// Vence o candidato que produz o maior número de linhas com a MESMA
/// quantidade de campos (mínimo de dois campos) — a regularidade de colunas é
/// o que distingue o separador real de uma vírgula que aparece dentro de uma
/// descrição. Empate resolve pela ordem dos candidatos.
String detectarDelimitadorCsv(String conteudo) {
  const candidatos = [';', ',', '\t', '|'];
  var melhor = candidatos.first;
  var melhorPontuacao = 0;

  for (final candidato in candidatos) {
    final registros = _lerRegistrosCsv(conteudo, candidato);
    final frequencia = <int, int>{};
    for (final registro in registros) {
      final campos = registro.campos.length;
      if (campos < 2) continue;
      frequencia[campos] = (frequencia[campos] ?? 0) + 1;
    }
    final pontuacao =
        frequencia.values.fold(0, (maior, n) => n > maior ? n : maior);
    if (pontuacao > melhorPontuacao) {
      melhorPontuacao = pontuacao;
      melhor = candidato;
    }
  }

  return melhor;
}

/// Anonimiza um CSV de banco para o qual AINDA NÃO EXISTE perfil.
///
/// Existe porque o caminho do card — extrato que falha vira fixture
/// anonimizada e perfil novo — é circular sem ele: [anonimizarCsv] exige o
/// perfil que ainda não foi escrito. E emprestar o perfil de outro banco não
/// serve: com as colunas trocadas, a descrição cairia no tratamento
/// conservador, que remove CPF e dígitos longos mas NÃO remove nomes — o
/// extrato real vazaria nomes de clientes para dentro da fixture.
///
/// Sem perfil, a única estrutura reconhecível é a data, e ela decide o
/// tratamento de cada linha:
/// - linha COM data (lançamento) → data preservada, valor perturbado, todo o
///   resto tratado como texto livre (CPFs, dígitos longos e nomes);
/// - linha SEM data (cabeçalho, preâmbulo, rodapé) → tratamento conservador,
///   para que os rótulos de coluna cheguem legíveis a quem vai escrever o
///   perfil. ⚠️ Conservador não remove nomes: preâmbulo com nome do titular
///   sobrevive de propósito, e é o que o usuário precisa revisar à mão.
///   [EstruturaCsvInferida.linhasPreambulo] diz quantas são.
AnonimizacaoSemPerfil anonimizarCsvSemPerfil(
  String conteudo, {
  String? delimitador,
  Anonimizador? anonimizador,
}) {
  final anon = anonimizador ?? Anonimizador();
  final separador = delimitador ?? detectarDelimitadorCsv(conteudo);
  final registros = _lerRegistrosCsv(conteudo, separador);

  var linhasPreambulo = 0;
  final colunasPorLinha = <int, int>{};

  for (final registro in registros) {
    final campos = registro.campos;
    if (campos.length == 1 && campos[0].texto.trim().isEmpty) continue;

    final colunaData = _indiceDaData(campos);
    if (colunaData == null) {
      linhasPreambulo++;
      for (final campo in campos) {
        campo.texto = anon.anonimizarConservador(campo.texto);
      }
      continue;
    }

    colunasPorLinha[campos.length] = (colunasPorLinha[campos.length] ?? 0) + 1;

    for (var c = 0; c < campos.length; c++) {
      if (c == colunaData) continue; // Estrutura pura: preservar.
      final campo = campos[c];
      final perturbado = _perturbarSeValorAparente(campo.texto, anon);
      campo.texto = perturbado ?? anon.anonimizarTexto(campo.texto);
    }
  }

  var colunas = 0;
  var maiorFrequencia = 0;
  colunasPorLinha.forEach((quantidade, frequencia) {
    if (frequencia > maiorFrequencia) {
      maiorFrequencia = frequencia;
      colunas = quantidade;
    }
  });

  return AnonimizacaoSemPerfil(
    conteudo: _escreverRegistrosCsv(registros, separador),
    estrutura: EstruturaCsvInferida(
      delimitador: separador,
      colunas: colunas,
      linhasPreambulo: linhasPreambulo,
      linhasLancamento: maiorFrequencia == 0
          ? 0
          : colunasPorLinha.values.fold(0, (soma, n) => soma + n),
    ),
  );
}

/// Índice do primeiro campo que é data em algum formato conhecido.
int? _indiceDaData(List<_CampoCsv> campos) {
  for (var c = 0; c < campos.length; c++) {
    final texto = campos[c].texto.trim();
    if (texto.isEmpty) continue;
    for (final formato in _formatosDataConhecidos) {
      if (parseDataCivil(texto, formato) != null) return c;
    }
  }
  return null;
}

/// Perturba o campo se ele tiver cara de valor; `null` se não tiver.
String? _perturbarSeValorAparente(String bruto, Anonimizador anon) {
  var texto =
      bruto.replaceAll('R\$', '').replaceAll(RegExp(r'[\s\u00A0]'), '');
  if (texto.startsWith('(') && texto.endsWith(')')) {
    texto = texto.substring(1, texto.length - 1);
  }
  if (texto.startsWith('-') || texto.startsWith('+')) {
    texto = texto.substring(1);
  } else if (texto.endsWith('-') || texto.endsWith('+')) {
    texto = texto.substring(0, texto.length - 1);
  }
  if (!_regexValorAparente.hasMatch(texto)) return null;

  // A convenção é a do próprio campo: o ÚLTIMO separador é o decimal.
  final formato = texto.lastIndexOf(',') > texto.lastIndexOf('.')
      ? FormatoValor.virgulaDecimal
      : FormatoValor.pontoDecimal;
  return _perturbarCampoValor(bruto, formato, anon);
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
