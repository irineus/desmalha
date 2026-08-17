/// Deduplicação de transações entre importações de extrato.
///
/// Importar dois extratos com períodos sobrepostos é o caso comum — exportar
/// o mês cheio depois de já ter importado a quinzena. Sem deduplicação a
/// receita duplica e o imposto sai errado: isto é correção de cálculo, não
/// conveniência de UX.
///
/// A regra vive aqui como função pura para ser testável com `dart test`. Quem
/// aplica são duas camadas de fora: a persistência (Drift), que não grava o
/// que veio suprimido, e a prévia da tela de importação (Fase 5), que declara
/// ao usuário o que foi suprimido e pede decisão sobre o que ficou marcado.
///
/// ## Duas camadas de comparação, e por que elas se comportam diferente
///
/// 1. **Identificador do banco** ([TransacaoImportada.idExterno]: FITID no
///    OFX, coluna Identificador no CSV). Igual em ambos os lados ⇒ é o mesmo
///    lançamento, suprimido sem perguntar.
/// 2. **Chave composta** (data, valor em centavos e descrição normalizada),
///    usada para o que a camada 1 não resolveu. Aqui a trava é a **contagem**:
///    o enésimo lançamento idêntico do arquivo novo só casa com o enésimo
///    lançamento idêntico já importado. Nunca se suprime mais ocorrências do
///    que a base já tem, então dois Pix legítimos de mesmo valor, mesmo dia e
///    mesmo remetente continuam valendo dois — e o terceiro entra como novo.
///
/// As camadas correm em **duas passadas sobre o arquivo inteiro**, nunca
/// intercaladas: a chave forte resolve tudo o que pode antes de a chave
/// composta pegar qualquer ocorrência. Intercalar faria a ordem das linhas
/// decidir o veredito — um lançamento no começo do arquivo tomaria pela chave
/// fraca o par de um lançamento mais adiante que casava por identificador
/// exato.
///
/// A assimetria entre as duas camadas é deliberada e foi decidida em
/// 17/ago/2026 com o usuário: **ausência de identificador é o banco não
/// afirmando nada** (suprimir é seguro), enquanto **identificador divergente
/// é o banco afirmando que são lançamentos distintos** — e essa afirmação não
/// se contraria em silêncio nos dois sentidos. Sobrescrevê-la suprimindo
/// poderia apagar receita legítima (imposto a menos, o erro que favorece o
/// usuário e só aparece no cruzamento da Receita); aceitá-la cegamente
/// duplicaria a receita num banco que regera o FITID a cada exportação. Então
/// o lançamento entra **marcado** como possível duplicata, e quem decide é o
/// usuário na prévia.
///
/// O erro residual desta regra corre para CIMA e é visível: se o banco
/// reexportar o mesmo lançamento com a descrição alterada, nada casa, a
/// receita aparece duplicada na prévia e o usuário vê. É o lado certo para
/// errar — o oposto sairia como imposto a menos, calado.
library;

import 'transacao_importada.dart';

/// O que fazer com um lançamento do arquivo novo.
enum SituacaoDeduplicacao {
  /// Não corresponde a nada já importado: pode ser persistido.
  nova,

  /// É um lançamento já importado, reconhecido com segurança suficiente para
  /// não perguntar. A prévia declara quantos e quanto foram suprimidos.
  duplicataSuprimida,

  /// Há indício de duplicata, mas não certeza. Nada é descartado nem gravado
  /// sem decisão do usuário na prévia.
  possivelDuplicata,
}

/// Por que um lançamento deixou de ser tratado como novo.
///
/// O núcleo não guarda texto de interface: a apresentação escolhe as palavras.
enum MotivoDeduplicacao {
  /// O identificador do banco confere com o de um lançamento já importado.
  identificadorConfere,

  /// Data, valor e descrição normalizada conferem com um lançamento já
  /// importado ainda não pareado, e nenhum dos dois lados afirma identificador
  /// diferente.
  dadosConferem,

  /// Data, valor e descrição conferem, mas os dois lados trazem
  /// identificadores do banco **diferentes** — o banco está afirmando que são
  /// lançamentos distintos.
  identificadorDivergente,

  /// O mesmo identificador aparece duas vezes dentro do próprio arquivo.
  /// Por especificação o FITID é único na conta, então isto é o banco listando
  /// o lançamento duas vezes ou desrespeitando a especificação — não se
  /// adivinha qual.
  identificadorRepetidoNoArquivo,
}

/// Um lançamento do arquivo novo com o veredito da deduplicação.
class LancamentoConciliado {
  const LancamentoConciliado._({
    required this.transacao,
    required this.situacao,
    this.motivo,
    this.correspondente,
  });

  /// Lançamento sem correspondência: entra no livro-caixa.
  const LancamentoConciliado.nova(TransacaoImportada transacao)
      : this._(transacao: transacao, situacao: SituacaoDeduplicacao.nova);

  const LancamentoConciliado.suprimida({
    required TransacaoImportada transacao,
    required MotivoDeduplicacao motivo,
    TransacaoImportada? correspondente,
  }) : this._(
          transacao: transacao,
          situacao: SituacaoDeduplicacao.duplicataSuprimida,
          motivo: motivo,
          correspondente: correspondente,
        );

  const LancamentoConciliado.possivelDuplicata({
    required TransacaoImportada transacao,
    required MotivoDeduplicacao motivo,
    TransacaoImportada? correspondente,
  }) : this._(
          transacao: transacao,
          situacao: SituacaoDeduplicacao.possivelDuplicata,
          motivo: motivo,
          correspondente: correspondente,
        );

  final TransacaoImportada transacao;
  final SituacaoDeduplicacao situacao;

  /// `null` apenas quando [situacao] é [SituacaoDeduplicacao.nova].
  final MotivoDeduplicacao? motivo;

  /// Lançamento já importado que motivou o veredito, quando existir — a prévia
  /// mostra o par ao usuário em vez de só um número.
  final TransacaoImportada? correspondente;

  @override
  String toString() => 'LancamentoConciliado(${situacao.name}'
      '${motivo == null ? '' : ', ${motivo!.name}'}, $transacao)';
}

/// Resultado da conciliação, na ordem do arquivo importado.
class ResultadoDeduplicacao {
  const ResultadoDeduplicacao(this.itens);

  /// Todos os lançamentos do arquivo novo, na ordem em que apareceram nele.
  /// Nada é omitido: suprimir é uma decisão que o usuário tem direito de ver.
  final List<LancamentoConciliado> itens;

  Iterable<LancamentoConciliado> _com(SituacaoDeduplicacao situacao) =>
      itens.where((i) => i.situacao == situacao);

  /// Lançamentos que devem ser persistidos.
  List<TransacaoImportada> get novas =>
      _com(SituacaoDeduplicacao.nova).map((i) => i.transacao).toList();

  List<LancamentoConciliado> get suprimidas =>
      _com(SituacaoDeduplicacao.duplicataSuprimida).toList();

  List<LancamentoConciliado> get possiveisDuplicatas =>
      _com(SituacaoDeduplicacao.possivelDuplicata).toList();

  int get quantidadeNova => _com(SituacaoDeduplicacao.nova).length;

  int get quantidadeSuprimida =>
      _com(SituacaoDeduplicacao.duplicataSuprimida).length;

  int get quantidadePossivelDuplicata =>
      _com(SituacaoDeduplicacao.possivelDuplicata).length;

  /// Soma dos créditos suprimidos, em centavos (sempre ≥ 0). Créditos e
  /// débitos ficam separados de propósito: um total líquido misturando os dois
  /// não é um número que se possa mostrar ao usuário.
  int get creditosSuprimidosCentavos => _somar(suprimidas, positivos: true);

  /// Soma dos débitos suprimidos, em centavos (sempre ≤ 0).
  int get debitosSuprimidosCentavos => _somar(suprimidas, positivos: false);

  static int _somar(
    List<LancamentoConciliado> itens, {
    required bool positivos,
  }) {
    var total = 0;
    for (final item in itens) {
      final valor = item.transacao.valorCentavos;
      if (positivos ? valor > 0 : valor < 0) total += valor;
    }
    return total;
  }
}

/// Confronta os lançamentos de uma importação nova com os já importados.
///
/// [jaImportadas] são os lançamentos que já estão no livro-caixa — basta
/// trazer os do período coberto pelo arquivo, mas passar mais não altera o
/// resultado. [novas] precisa vir **na ordem do arquivo**: a ordem é o que
/// define qual ocorrência casa com qual quando há lançamentos idênticos.
///
/// Não persiste, não transmite e não altera as listas recebidas.
ResultadoDeduplicacao conciliarImportacao({
  required Iterable<TransacaoImportada> jaImportadas,
  required List<TransacaoImportada> novas,
}) {
  final base = [for (final t in jaImportadas) _OcorrenciaBase(t)];
  final porIdentificador = <String, List<_OcorrenciaBase>>{};
  final porChaveComposta = <String, List<_OcorrenciaBase>>{};
  for (final ocorrencia in base) {
    final id = _identificador(ocorrencia.transacao);
    if (id != null) {
      porIdentificador.putIfAbsent(id, () => []).add(ocorrencia);
    }
    porChaveComposta
        .putIfAbsent(chaveComposta(ocorrencia.transacao), () => [])
        .add(ocorrencia);
  }

  final vereditos = List<LancamentoConciliado?>.filled(novas.length, null);

  // Passada 1 — chave forte, no arquivo INTEIRO antes de qualquer chave fraca.
  // Se a camada 2 pudesse consumir ocorrências durante a mesma varredura, um
  // lançamento no começo do arquivo tomaria pela chave fraca o par de um
  // lançamento mais adiante que casava pelo identificador exato, e a ordem das
  // linhas passaria a decidir o veredito. Consumir aqui também tira a
  // ocorrência do alcance da camada 2 — sem isso, um segundo lançamento
  // legítimo e idêntico do arquivo casaria com uma base já pareada.
  final identificadoresDoArquivo = <String>{};
  for (var i = 0; i < novas.length; i++) {
    final nova = novas[i];
    final id = _identificador(nova);
    if (id == null) continue;

    final parPorId = _consumir(porIdentificador[id]);
    if (parPorId != null) {
      vereditos[i] = LancamentoConciliado.suprimida(
        transacao: nova,
        motivo: MotivoDeduplicacao.identificadorConfere,
        correspondente: parPorId.transacao,
      );
      continue;
    }
    if (!identificadoresDoArquivo.add(id)) {
      vereditos[i] = LancamentoConciliado.possivelDuplicata(
        transacao: nova,
        motivo: MotivoDeduplicacao.identificadorRepetidoNoArquivo,
      );
    }
  }

  // Passada 2 — chave composta, só no que sobrou. A contagem é a trava:
  // ocorrências além do que a base tem são lançamentos novos, não duplicatas.
  for (var i = 0; i < novas.length; i++) {
    if (vereditos[i] != null) continue;
    final nova = novas[i];

    final parComposto = _consumir(porChaveComposta[chaveComposta(nova)]);
    if (parComposto == null) {
      vereditos[i] = LancamentoConciliado.nova(nova);
      continue;
    }

    final idDaBase = _identificador(parComposto.transacao);
    final id = _identificador(nova);
    final bancoAfirmaQueSaoDistintos =
        id != null && idDaBase != null && id != idDaBase;
    vereditos[i] = bancoAfirmaQueSaoDistintos
        ? LancamentoConciliado.possivelDuplicata(
            transacao: nova,
            motivo: MotivoDeduplicacao.identificadorDivergente,
            correspondente: parComposto.transacao,
          )
        : LancamentoConciliado.suprimida(
            transacao: nova,
            motivo: MotivoDeduplicacao.dadosConferem,
            correspondente: parComposto.transacao,
          );
  }

  return ResultadoDeduplicacao(
    [for (final veredito in vereditos) veredito!],
  );
}

/// Chave da camada 2: data civil, valor em centavos e descrição normalizada.
///
/// Data e valor vêm primeiro e são estruturados, então a descrição livre no
/// fim não cria ambiguidade mesmo contendo o separador.
String chaveComposta(TransacaoImportada transacao) =>
    '${transacao.data}|${transacao.valorCentavos}'
    '|${normalizarDescricao(transacao.descricao)}';

/// Normaliza a descrição para comparação entre exportações do mesmo banco.
///
/// Normaliza apenas o que o banco varia sem querer dizer nada: caixa,
/// espaçamento e acentuação. **Pontuação e dígitos são preservados**, porque
/// eles costumam ser justamente o que distingue dois lançamentos parecidos
/// (`PIX 001` × `PIX 002`, e o MEMO do Itaú que cola a data no fim do nome).
///
/// A escolha é conservadora de propósito: normalizar mais aumentaria a chance
/// de colapsar lançamentos distintos, que é o erro caro. Normalizar de menos
/// deixa a receita aparecer duplicada na prévia, onde o usuário enxerga.
String normalizarDescricao(String descricao) {
  final maiuscula = descricao.toUpperCase();
  final semAcento = StringBuffer();
  for (final unidade in maiuscula.split('')) {
    final indice = _comAcento.indexOf(unidade);
    semAcento.write(indice < 0 ? unidade : _semAcento[indice]);
  }
  return semAcento.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

const _comAcento = 'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÑÇ';
const _semAcento = 'AAAAAEEEEIIIIOOOOOUUUUNC';

/// Identificador do banco pronto para comparação, ou `null` se não houver.
///
/// Só espaços de borda são descartados. A caixa é preservada: baixar a caixa
/// poderia colapsar identificadores distintos, e o preço disso seria suprimir
/// receita legítima.
String? _identificador(TransacaoImportada transacao) {
  final id = transacao.idExterno?.trim();
  return (id == null || id.isEmpty) ? null : id;
}

_OcorrenciaBase? _consumir(List<_OcorrenciaBase>? candidatos) {
  if (candidatos == null) return null;
  for (final candidato in candidatos) {
    if (!candidato.consumida) {
      candidato.consumida = true;
      return candidato;
    }
  }
  return null;
}

/// Lançamento já importado e o controle de já ter sido pareado nesta rodada —
/// cada um responde por no máximo uma ocorrência do arquivo novo.
class _OcorrenciaBase {
  _OcorrenciaBase(this.transacao);

  final TransacaoImportada transacao;
  bool consumida = false;
}
