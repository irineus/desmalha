/// Payload do backup: export LÓGICO em NDJSON gzipado, com manifesto.
///
/// Especificação: "Resultado: Revisar modelagem de dados para local-first",
/// seção 6. O blob NÃO é cópia do arquivo SQLite: cifrar o `.db` acoplaria o
/// backup ao schema físico, e restaurar um backup da v1.3 na v2.0 exigiria
/// rodar migrações do Drift sobre um arquivo estranho, sem validar antes.
///
/// Primeira linha: o manifesto. Demais: `{"t":"<tabela>","d":{…}}`.
///
/// Regras de versionamento (as seis da especificação, aqui as que são do
/// payload):
/// 1. `formato_versao` é independente do schema local.
/// 2. Escreve sempre na versão corrente; lê da 1 em diante, sem prazo.
/// 3. Migração é cadeia de funções puras sobre os documentos, aplicada ANTES
///    de tocar o banco — nunca "importa e conserta depois".
/// 4. Blob com `formato_versao` maior que a suportada: recusa integral.
///
/// Três camadas de integridade, cada uma pegando uma falha diferente: o
/// `sha256` do ciphertext nos metadados do servidor (trânsito/armazenamento),
/// a tag do AEAD (adulteração/chave errada) e o `hash_conteudo` daqui (bug
/// do próprio serializador).
library;

import 'dart:convert';
import 'dart:io' show gzip;

import 'package:cryptography/cryptography.dart';

import 'excecoes_backup.dart';

/// Versão do formato lógico que este app escreve.
const int formatoBackupAtual = 1;

/// As tabelas que ENTRAM no export (seção 6). Ficam de fora, de propósito:
/// catálogo (re-baixável; as apurações guardam o snapshot das versões),
/// `notificacoes_locais`, `backup_estado`, `envios_suporte`, `auditoria` —
/// ruído operacional do aparelho, não patrimônio fiscal.
const Set<String> tabelasDoBackupV1 = {
  'perfil',
  'contas_bancarias',
  'importacoes',
  'transacoes',
  'remetentes',
  'lancamentos',
  'historico_classificacao',
  'despesas_livro_caixa',
  'pagamentos_inss',
  'dependentes',
  'apuracoes_mensais',
  'darfs',
  'aceites_termos_local',
};

/// Plataformas que gravam backup.
const Set<String> plataformasDoBackup = {'android', 'ios'};

/// Uma linha do export: a tabela e a linha como mapa coluna → valor.
class DocumentoBackup {
  const DocumentoBackup(this.tabela, this.dados);

  final String tabela;

  /// Valores JSON: `String`, `int`, `bool`, `null`. **Nunca `double`** —
  /// dinheiro é centavo inteiro e percentual é ponto-base (regra inviolável).
  final Map<String, Object?> dados;

  Map<String, Object?> toJson() => {'t': tabela, 'd': dados};
}

/// O manifesto (primeira linha do NDJSON).
class ManifestoBackup {
  const ManifestoBackup({
    required this.formatoVersao,
    required this.appVersao,
    required this.schemaLocalVersao,
    required this.geradoEm,
    required this.seq,
    required this.plataforma,
    required this.hashConteudo,
    required this.contagens,
    required this.catalogoVersoes,
  });

  final int formatoVersao;
  final String appVersao;
  final int schemaLocalVersao;

  /// Instante ISO-8601 em UTC.
  final String geradoEm;
  final int seq;
  final String plataforma;

  /// `sha256:<hex>` sobre as linhas de documento, na ordem gravada.
  final String hashConteudo;
  final Map<String, int> contagens;
  final Map<String, Object?> catalogoVersoes;

  Map<String, Object?> toJson() => {
    'tipo': 'manifesto',
    'formato_versao': formatoVersao,
    'app_versao': appVersao,
    'schema_local_versao': schemaLocalVersao,
    'gerado_em': geradoEm,
    'seq': seq,
    'plataforma': plataforma,
    'hash_conteudo': hashConteudo,
    'contagens': contagens,
    'catalogo_versoes': catalogoVersoes,
  };
}

/// Backup lido, validado e migrado para [formatoBackupAtual].
class ConteudoBackup {
  const ConteudoBackup(this.manifesto, this.documentos);
  final ManifestoBackup manifesto;
  final List<DocumentoBackup> documentos;
}

/// Migração pura de uma versão do formato para a seguinte.
typedef MigracaoBackup =
    List<DocumentoBackup> Function(List<DocumentoBackup> documentos);

/// A cadeia oficial. Vazia enquanto só existe a v1; a v2 entra como
/// `1: migrar1Para2`, com golden file da v1 continuando a restaurar.
const Map<int, MigracaoBackup> migracoesBackup = {};

/// Serializa e gzipa o payload. Calcula `hash_conteudo` e `contagens`.
Future<List<int>> serializarPayload({
  required List<DocumentoBackup> documentos,
  required String appVersao,
  required int schemaLocalVersao,
  required DateTime geradoEm,
  required int seq,
  required String plataforma,
  Map<String, Object?> catalogoVersoes = const {},
}) async {
  if (!plataformasDoBackup.contains(plataforma)) {
    throw ArgumentError.value(plataforma, 'plataforma');
  }
  if (seq < 1) throw ArgumentError.value(seq, 'seq', 'começa em 1');
  final contagens = <String, int>{};
  final linhas = <String>[];
  for (final doc in documentos) {
    _validarDocumento(doc, formatoBackupAtual);
    contagens[doc.tabela] = (contagens[doc.tabela] ?? 0) + 1;
    linhas.add(jsonEncode(_canonico(doc.toJson())));
  }
  final corpo = linhas.join('\n');
  final manifesto = ManifestoBackup(
    formatoVersao: formatoBackupAtual,
    appVersao: appVersao,
    schemaLocalVersao: schemaLocalVersao,
    geradoEm: geradoEm.toUtc().toIso8601String(),
    seq: seq,
    plataforma: plataforma,
    hashConteudo: await _hash(corpo),
    contagens: Map.fromEntries(
      contagens.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    ),
    catalogoVersoes: catalogoVersoes,
  );
  final ndjson = linhas.isEmpty
      ? jsonEncode(manifesto.toJson())
      : '${jsonEncode(manifesto.toJson())}\n$corpo';
  return gzip.encode(utf8.encode(ndjson));
}

/// Lê um payload gzipado: valida tudo e migra para [formatoBackupAtual].
///
/// Qualquer divergência é recusa integral ([BackupInvalidoException] ou
/// [BackupDeVersaoFuturaException]) — nunca restauração parcial.
Future<ConteudoBackup> lerPayload(
  List<int> gzipado, {
  int formatoSuportado = formatoBackupAtual,
  Map<int, MigracaoBackup> migracoes = migracoesBackup,
}) async {
  final String texto;
  try {
    texto = utf8.decode(gzip.decode(gzipado));
  } on FormatException catch (e) {
    throw BackupInvalidoException('conteúdo ilegível: ${e.message}');
  } on Exception {
    throw const BackupInvalidoException('conteúdo não é gzip válido');
  }
  final quebra = texto.indexOf('\n');
  final linhaManifesto = quebra < 0 ? texto : texto.substring(0, quebra);
  final corpo = quebra < 0 ? '' : texto.substring(quebra + 1);

  final m = _objeto(linhaManifesto, 'manifesto');
  if (m['tipo'] != 'manifesto') {
    throw const BackupInvalidoException('a primeira linha não é o manifesto');
  }
  final versao = m['formato_versao'];
  if (versao is! int || versao < 1) {
    throw BackupInvalidoException('formato_versao inválido: $versao');
  }
  if (versao > formatoSuportado) {
    throw BackupDeVersaoFuturaException(
      'backup no formato $versao; este app lê até o $formatoSuportado. '
      'Atualize o aplicativo para restaurar.',
    );
  }
  final manifesto = _manifesto(m, versao);

  if (await _hash(corpo) != manifesto.hashConteudo) {
    throw const BackupInvalidoException(
      'hash do conteúdo não confere com o manifesto',
    );
  }

  var documentos = <DocumentoBackup>[];
  if (corpo.isNotEmpty) {
    var n = 0;
    for (final linha in const LineSplitter().convert(corpo)) {
      n++;
      final o = _objeto(linha, 'documento $n');
      final t = o['t'];
      final d = o['d'];
      if (t is! String || d is! Map<String, Object?> || o.length != 2) {
        throw BackupInvalidoException('documento $n malformado');
      }
      documentos.add(DocumentoBackup(t, d));
    }
  }

  final contagens = <String, int>{};
  for (final doc in documentos) {
    contagens[doc.tabela] = (contagens[doc.tabela] ?? 0) + 1;
  }
  if (!_mesmoMapa(contagens, manifesto.contagens)) {
    throw BackupInvalidoException(
      'contagens do manifesto (${manifesto.contagens}) não conferem com o '
      'conteúdo ($contagens)',
    );
  }

  for (final doc in documentos) {
    _validarDocumento(doc, versao);
  }

  // Cadeia de migrações puras, antes de qualquer toque no banco.
  for (var v = versao; v < formatoSuportado; v++) {
    final migrar = migracoes[v];
    if (migrar == null) {
      throw BackupInvalidoException('falta a migração do formato $v para ${v + 1}');
    }
    documentos = migrar(documentos);
  }
  return ConteudoBackup(manifesto, documentos);
}

void _validarDocumento(DocumentoBackup doc, int versao) {
  if (versao == 1 && !tabelasDoBackupV1.contains(doc.tabela)) {
    throw BackupInvalidoException(
      'tabela "${doc.tabela}" não faz parte do backup (formato $versao)',
    );
  }
  if (doc.tabela == 'importacoes' && doc.dados.containsKey('previa_json')) {
    // A prévia é estado de trabalho, não patrimônio: fica de fora do export.
    throw const BackupInvalidoException(
      'importacoes não leva previa_json no backup',
    );
  }
  _semPontoFlutuante(doc.dados, doc.tabela);
}

void _semPontoFlutuante(Object? valor, String caminho) {
  switch (valor) {
    case double():
      throw BackupInvalidoException(
        'ponto flutuante no backup ($caminho = $valor): dinheiro é centavo '
        'inteiro, percentual é ponto-base',
      );
    case Map<String, Object?>():
      valor.forEach((k, v) => _semPontoFlutuante(v, '$caminho.$k'));
    case List<Object?>():
      for (var i = 0; i < valor.length; i++) {
        _semPontoFlutuante(valor[i], '$caminho[$i]');
      }
    case null || String() || int() || bool():
      return;
    default:
      throw BackupInvalidoException(
        'tipo não serializável no backup em $caminho: ${valor.runtimeType}',
      );
  }
}

/// Chaves ordenadas em todos os níveis: a mesma linha sempre vira os mesmos
/// bytes, e o hash não depende da ordem em que o banco devolveu as colunas.
Object? _canonico(Object? v) => switch (v) {
  Map<String, Object?>() => {
    for (final k in (v.keys.toList()..sort())) k: _canonico(v[k]),
  },
  List<Object?>() => [for (final e in v) _canonico(e)],
  _ => v,
};

Future<String> _hash(String corpo) async {
  final h = await Sha256().hash(utf8.encode(corpo));
  return 'sha256:${h.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
}

Map<String, Object?> _objeto(String linha, String rotulo) {
  try {
    final v = jsonDecode(linha);
    if (v is Map<String, Object?>) return v;
  } on FormatException {
    // cai abaixo
  }
  throw BackupInvalidoException('$rotulo não é um objeto JSON');
}

ManifestoBackup _manifesto(Map<String, Object?> m, int versao) {
  T campo<T>(String nome) {
    final v = m[nome];
    if (v is! T) throw BackupInvalidoException('manifesto sem "$nome" válido');
    return v;
  }

  final plataforma = campo<String>('plataforma');
  if (!plataformasDoBackup.contains(plataforma)) {
    throw BackupInvalidoException('plataforma desconhecida: $plataforma');
  }
  final contagensBruto = campo<Map<String, Object?>>('contagens');
  final contagens = <String, int>{};
  contagensBruto.forEach((k, v) {
    if (v is! int || v < 0) {
      throw BackupInvalidoException('contagem inválida para "$k"');
    }
    contagens[k] = v;
  });
  return ManifestoBackup(
    formatoVersao: versao,
    appVersao: campo<String>('app_versao'),
    schemaLocalVersao: campo<int>('schema_local_versao'),
    geradoEm: campo<String>('gerado_em'),
    seq: campo<int>('seq'),
    plataforma: plataforma,
    hashConteudo: campo<String>('hash_conteudo'),
    contagens: contagens,
    catalogoVersoes: (m['catalogo_versoes'] as Map<String, Object?>?) ?? {},
  );
}

bool _mesmoMapa(Map<String, int> a, Map<String, int> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
