/// Persistência de importações de extrato — onde os vereditos do
/// `conciliarImportacao` (desmalha_core) viram (ou deixam de virar) linhas.
///
/// Contrato com o card de deduplicação (17/ago/2026):
/// - `duplicataSuprimida` **nunca** é gravada — não existe caminho nesta API
///   que a persista.
/// - `possivelDuplicata` só é gravada com decisão EXPLÍCITA do usuário,
///   tomada na prévia (Fase 5). Decisão faltando não vira padrão silencioso
///   em nenhum dos dois sentidos: a confirmação falha e a prévia continua lá.
/// - `nova` é gravada.
///
/// A regra de comparação em si vive no core; aqui só se aplica o resultado.
library;

import 'package:desmalha_core/desmalha_core.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'banco.dart';

/// O que a confirmação efetivamente fez, para a prévia declarar ao usuário.
class ResumoConfirmacao {
  const ResumoConfirmacao({
    required this.persistidas,
    required this.suprimidas,
    required this.descartadasPeloUsuario,
  });

  /// Quantas linhas entraram em `transacoes` (novas + possíveis mantidas).
  final int persistidas;

  /// Quantas o veredito suprimiu sem perguntar (identificador do banco ou
  /// dados conferem). Não foram gravadas.
  final int suprimidas;

  /// Quantas possíveis duplicatas o usuário mandou descartar.
  final int descartadasPeloUsuario;
}

class RepositorioImportacao {
  RepositorioImportacao(this._banco, {int Function()? agoraEpochMs})
      : _agoraEpochMs =
            agoraEpochMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  final BancoLocal _banco;
  final int Function() _agoraEpochMs;
  final _uuid = const Uuid();

  Future<String> criarConta({
    required String apelido,
    String? bancoCodigo,
  }) async {
    final id = _uuid.v7();
    await _banco.into(_banco.contasBancarias).insert(
          ContasBancariasCompanion.insert(
            id: id,
            apelido: apelido,
            bancoCodigo: Value(bancoCodigo),
            criadoEm: _agoraEpochMs(),
          ),
        );
    return id;
  }

  /// Registra a importação em estado `previa` — persistida para não perder o
  /// trabalho se o app for a background com um OFX de meses aberto (decisão
  /// nº 4 da modelagem). Nada entra em `transacoes` neste passo.
  Future<String> registrarPrevia({
    required String contaId,
    required FormatoExtrato formato,
    required String nomeArquivo,
    required String hashArquivo,
    String? parserCodigo,
    int? parserVersao,
    String? previaJson,
    String? periodoInicio,
    String? periodoFim,
    int? totalLinhas,
  }) async {
    final id = _uuid.v7();
    await _banco.into(_banco.importacoes).insert(
          ImportacoesCompanion.insert(
            id: id,
            contaId: contaId,
            formato: formato.name,
            nomeArquivo: nomeArquivo,
            hashArquivo: hashArquivo,
            parserCodigo: Value(parserCodigo),
            parserVersao: Value(parserVersao),
            previaJson: Value(previaJson),
            periodoInicio: Value(periodoInicio),
            periodoFim: Value(periodoFim),
            totalLinhas: Value(totalLinhas),
            criadoEm: _agoraEpochMs(),
          ),
        );
    return id;
  }

  /// Lançamentos já importados da conta, prontos para servir de base ao
  /// `conciliarImportacao`. Trazer mais do que o período do arquivo não
  /// altera o resultado (contrato do core), então não se filtra por data.
  Future<List<TransacaoImportada>> transacoesJaImportadas(
    String contaId,
  ) async {
    final linhas = await (_banco.select(_banco.transacoes)
          ..where((t) => t.contaId.equals(contaId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.data),
            (t) => OrderingTerm.asc(t.criadoEm),
          ]))
        .get();
    return [
      for (final t in linhas)
        TransacaoImportada(
          data: t.data,
          valorCentavos: t.valorCentavos,
          descricao: t.descricaoRaw,
          idExterno: t.fitid,
        ),
    ];
  }

  /// Confronta o arquivo novo com o que a conta já tem — açúcar sobre o core
  /// para a prévia da Fase 5.
  Future<ResultadoDeduplicacao> conciliarArquivo({
    required String contaId,
    required List<TransacaoImportada> novas,
  }) async {
    return conciliarImportacao(
      jaImportadas: await transacoesJaImportadas(contaId),
      novas: novas,
    );
  }

  /// Confirma uma importação em prévia, aplicando os vereditos.
  ///
  /// [decisoesPossiveis] mapeia o índice do item em [ResultadoDeduplicacao.itens]
  /// para a decisão do usuário (`true` = manter e gravar, `false` =
  /// descartar). As chaves têm de cobrir EXATAMENTE as possíveis duplicatas
  /// do resultado: faltar uma, ou sobrar chave que não é possível duplicata,
  /// derruba a confirmação com [ArgumentError] — decisão de deduplicação não
  /// tem padrão silencioso.
  ///
  /// Tudo numa transação: ou a importação inteira confirma, ou nada muda e a
  /// prévia continua válida.
  Future<ResumoConfirmacao> confirmarImportacao({
    required String importacaoId,
    required ResultadoDeduplicacao resultado,
    required Map<int, bool> decisoesPossiveis,
  }) async {
    final indicesPossiveis = <int>{
      for (var i = 0; i < resultado.itens.length; i++)
        if (resultado.itens[i].situacao == SituacaoDeduplicacao.possivelDuplicata)
          i,
    };
    if (!_mesmoConjunto(decisoesPossiveis.keys.toSet(), indicesPossiveis)) {
      throw ArgumentError(
        'decisoesPossiveis precisa cobrir exatamente os índices das possíveis '
        'duplicatas ($indicesPossiveis); veio ${decisoesPossiveis.keys.toSet()}',
      );
    }

    return _banco.transaction(() async {
      final importacao = await (_banco.select(_banco.importacoes)
            ..where((i) => i.id.equals(importacaoId)))
          .getSingleOrNull();
      if (importacao == null) {
        throw ArgumentError('importação não encontrada: $importacaoId');
      }
      if (importacao.status != 'previa') {
        // A porta contra confirmar duas vezes (e duplicar a receita inteira
        // do arquivo) é esta transição única, junto com uq_importacao_hash.
        throw StateError(
          'importação ${importacao.status != 'confirmada' ? 'em estado '
              '"${importacao.status}"' : 'já confirmada'}: '
          'confirmar exige estado "previa"',
        );
      }

      final agora = _agoraEpochMs();
      var persistidas = 0;
      var descartadas = 0;
      for (var i = 0; i < resultado.itens.length; i++) {
        final item = resultado.itens[i];
        final gravar = switch (item.situacao) {
          SituacaoDeduplicacao.nova => true,
          SituacaoDeduplicacao.duplicataSuprimida => false,
          SituacaoDeduplicacao.possivelDuplicata => decisoesPossiveis[i]!,
        };
        if (!gravar) {
          if (item.situacao == SituacaoDeduplicacao.possivelDuplicata) {
            descartadas++;
          }
          continue;
        }
        final t = item.transacao;
        await _banco.into(_banco.transacoes).insert(
              TransacoesCompanion.insert(
                id: _uuid.v7(),
                contaId: importacao.contaId,
                importacaoId: Value(importacaoId),
                data: t.data,
                valorCentavos: t.valorCentavos,
                descricaoRaw: t.descricao,
                fitid: Value(t.idExterno),
                criadoEm: agora,
              ),
            );
        persistidas++;
      }

      await (_banco.update(_banco.importacoes)
            ..where((i) => i.id.equals(importacaoId)))
          .write(
        ImportacoesCompanion(
          status: const Value('confirmada'),
          previaJson: const Value(null),
          totalImportadas: Value(persistidas),
          totalDuplicadas: Value(resultado.quantidadeSuprimida),
          totalIgnoradas: Value(descartadas),
        ),
      );

      return ResumoConfirmacao(
        persistidas: persistidas,
        suprimidas: resultado.quantidadeSuprimida,
        descartadasPeloUsuario: descartadas,
      );
    });
  }

  static bool _mesmoConjunto(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);
}
