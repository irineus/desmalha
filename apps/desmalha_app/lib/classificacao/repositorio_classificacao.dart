/// Persistência da classificação — onde as respostas do usuário viram
/// lançamento, remetente e (no repasse essencial) despesa do livro-caixa.
///
/// A regra fiscal NÃO mora aqui: o efeito de cada classificação, a chave do
/// remetente, a situação do documento e a proposta por remetente são do
/// desmalha_core (`classificacao/`). Este arquivo grava o que o core decide
/// e guarda o que é preciso para desfazer.
///
/// Decisões do owner (25/09/2026) aplicadas aqui:
/// - 3: sem documento, o remetente é achado pela chave de nome; com CPF ou
///   CNPJ, pelo documento. Informar o CPF NÃO promove o remetente sem
///   documento de mesmo nome — homônimos se separam assim que há CPF, e só
///   o lançamento em que ele foi informado vai para o remetente do CPF.
/// - 4: a proposta nasce da classificação e nada é aplicado sem toque;
///   aceitar confirma a regra do remetente e grava `sugestaoAceita`, com
///   desfazer. Lançamento NOVO de remetente com regra confirmada nasce
///   `regraRemetente` sem `confirmada_em` — "proposto pela regra" na fila.
library;

import 'dart:convert';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../dados/banco.dart';

/// Um recebimento importado ainda sem classificação, ou um lançamento
/// "proposto pela regra" aguardando o toque.
class ItemDaFila {
  const ItemDaFila({
    required this.transacaoId,
    required this.data,
    required this.valorCentavos,
    required this.descricao,
    required this.chaveRemetente,
    this.propostoPelaRegra,
    this.lancamentoId,
  });

  final String transacaoId;
  final String data;
  final int valorCentavos;
  final String descricao;

  /// Nome do pagador extraído da descrição, ou `null` se não há nome.
  final String? chaveRemetente;

  /// Classificação que a regra do remetente aplicou, ainda sem toque.
  final ClassificacaoLancamento? propostoPelaRegra;
  final String? lancamentoId;
}

/// As respostas de uma classificação. Reembolso e repasse exigem
/// [titular]; no CPF do profissional, também [custoEssencial] — e, se
/// essencial, [dataPagamentoCusto] (P3: a despesa entra no mês em que o
/// custo foi PAGO).
class RespostasClassificacao {
  const RespostasClassificacao({
    required this.classificacao,
    this.titular,
    this.custoEssencial,
    this.dataPagamentoCusto,
    this.valorCustoCentavos,
    this.documentoPagador,
    this.nomePagador,
    this.cpfBeneficiario,
    this.nomeBeneficiario,
  });

  final ClassificacaoLancamento classificacao;
  final TitularComprovante? titular;
  final bool? custoEssencial;
  final String? dataPagamentoCusto;

  /// Valor do custo; padrão = o valor recebido.
  final int? valorCustoCentavos;

  /// CPF ou CNPJ, com ou sem máscara. Inválido é recusado.
  final String? documentoPagador;
  final String? nomePagador;
  final String? cpfBeneficiario;
  final String? nomeBeneficiario;
}

class ResultadoClassificacao {
  const ResultadoClassificacao({
    required this.lancamentoId,
    required this.remetenteId,
    required this.proposta,
  });

  final String lancamentoId;
  final String? remetenteId;

  /// "Marcar os outros N como …" para os pendentes do mesmo remetente.
  final PropostaDeRegra? proposta;
}

/// O que aceitar uma proposta mudou — o bastante para desfazer.
class ProposicaoAceita {
  const ProposicaoAceita({
    required this.remetenteId,
    required this.lancamentosCriados,
    required this.regraAnterior,
    required this.regraConfirmadaAnterior,
  });

  final String remetenteId;
  final List<String> lancamentosCriados;
  final String? regraAnterior;
  final int? regraConfirmadaAnterior;
}

class RepositorioClassificacao {
  RepositorioClassificacao(
    this._banco, {
    required Future<Catalogo> Function() catalogo,
    int Function()? agoraEpochMs,
    // Parâmetro nomeado não pode começar com underscore.
    // ignore: prefer_initializing_formals
  })  : _catalogo = catalogo,
        _agoraEpochMs =
            agoraEpochMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  final BancoLocal _banco;
  final Future<Catalogo> Function() _catalogo;
  final int Function() _agoraEpochMs;
  final _uuid = const Uuid();

  // ── Fila ──────────────────────────────────────────────────────────────

  /// Créditos sem lançamento e lançamentos "propostos pela regra", mais
  /// recentes primeiro.
  Future<List<ItemDaFila>> fila() async {
    final linhas = await _banco.customSelect(
      'SELECT t.id, t.data, t.valor_centavos, t.descricao_raw, '
      'l.id AS lancamento_id, l.classificacao '
      'FROM transacoes t LEFT JOIN lancamentos l ON l.transacao_id = t.id '
      'WHERE t.valor_centavos > 0 AND (l.id IS NULL OR l.confirmada_em IS NULL) '
      'ORDER BY t.data DESC, t.id',
    ).get();
    return [
      for (final r in linhas)
        ItemDaFila(
          transacaoId: r.read<String>('id'),
          data: r.read<String>('data'),
          valorCentavos: r.read<int>('valor_centavos'),
          descricao: r.read<String>('descricao_raw'),
          chaveRemetente: chaveDoRemetente(r.read<String>('descricao_raw')),
          lancamentoId: r.readNullable<String>('lancamento_id'),
          propostoPelaRegra: switch (r.readNullable<String>('classificacao')) {
            null => null,
            final c => ClassificacaoLancamento.values.byName(c),
          },
        ),
    ];
  }

  // ── Classificar ───────────────────────────────────────────────────────

  /// Classifica o crédito [transacaoId] com [respostas] (ou reclassifica o
  /// lançamento que ele já tem), e devolve a proposta para os pendentes do
  /// mesmo remetente.
  Future<ResultadoClassificacao> classificar(
    String transacaoId,
    RespostasClassificacao respostas, {
    OrigemClassificacao origem = OrigemClassificacao.manual,
  }) async {
    // O core decide antes de qualquer escrita: resposta faltando é recusa.
    final efeito = efeitoDoLancamento(
      respostas.classificacao,
      titular: respostas.titular,
      custoEssencial: respostas.custoEssencial,
    );
    if (efeito.geraDespesa && respostas.dataPagamentoCusto == null) {
      throw ArgumentError(
        'custo essencial exige a data em que foi pago (P3: a despesa entra '
        'no mês do pagamento)',
      );
    }
    final documento = switch (respostas.documentoPagador) {
      null || '' => null,
      final d => documentoDoPagador(d) ??
          (throw ArgumentError('CPF/CNPJ inválido: $d')),
    };
    final beneficiario = switch (respostas.cpfBeneficiario) {
      null || '' => null,
      final d => switch (documentoDoPagador(d)) {
          (digitos: final c, ehCnpj: false) => c,
          _ => throw ArgumentError('CPF do beneficiário inválido: $d'),
        },
    };
    final catalogo = await _catalogo();
    final profissao = await _profissaoDoPerfil(catalogo);

    return _banco.transaction(() async {
      final t = await _transacao(transacaoId);
      if (t.valorCentavos <= 0) {
        throw ArgumentError('só crédito é classificado como recebimento');
      }
      final chave = chaveDoRemetente(t.descricaoRaw);
      final remetenteId = await _remetente(
        chave: chave,
        documento: documento,
        nome: respostas.nomePagador ?? chave,
      );

      final agora = _agoraEpochMs();
      final anterior = await (_banco.select(_banco.lancamentos)
            ..where((l) => l.transacaoId.equals(transacaoId)))
          .getSingleOrNull();
      final id = anterior?.id ?? _uuid.v7();
      final status = statusDocumento(
        classificacao: respostas.classificacao,
        efeito: efeito,
        profissao: profissao,
        temDocumento: documento != null,
      );
      final linha = LancamentosCompanion(
        id: Value(id),
        transacaoId: Value(transacaoId),
        competencia: Value(t.data.substring(0, 7)),
        dataRecebimento: Value(t.data),
        valorCentavos: Value(t.valorCentavos),
        classificacao: Value(respostas.classificacao.name),
        comprovanteTitular: Value(respostas.titular?.name),
        custoEssencial: Value(switch (respostas.custoEssencial) {
          null => null,
          true => 1,
          false => 0,
        }),
        remetenteId: Value(remetenteId),
        cpfPagador: Value(documento != null && !documento.ehCnpj
            ? documento.digitos
            : null),
        cnpjPagador:
            Value(documento != null && documento.ehCnpj ? documento.digitos : null),
        nomePagador: Value(respostas.nomePagador ?? chave),
        statusDocumentoPagador: Value(status.name),
        cpfBeneficiario: Value(profissao?.saude ?? false ? beneficiario : null),
        nomeBeneficiario: Value(profissao?.saude ?? false
            ? respostas.nomeBeneficiario
            : null),
        origemClassificacao: Value(origem.name),
        confirmadaEm: Value(agora),
        criadoEm: Value(anterior?.criadoEm ?? agora),
        atualizadoEm: Value(agora),
      );
      await _banco.into(_banco.lancamentos).insertOnConflictUpdate(linha);
      await _banco.into(_banco.historicoClassificacao).insert(
            HistoricoClassificacaoCompanion.insert(
              lancamentoId: id,
              de: Value(anterior?.classificacao),
              para: respostas.classificacao.name,
              motivo: Value(origem.name),
              criadoEm: agora,
            ),
          );

      // A despesa do repasse essencial (P2/P3): uma só por lançamento, com
      // a data do pagamento do custo. Reclassificar para outra coisa a tira.
      await (_banco.delete(_banco.despesasLivroCaixa)
            ..where((d) => d.lancamentoOrigemId.equals(id)))
          .go();
      if (efeito.geraDespesa) {
        final rubrica = catalogo.rubricaPorId(rubricaCustoRepassadoEssencial);
        if (rubrica == null) {
          throw StateError(
            'catálogo sem a rubrica $rubricaCustoRepassadoEssencial: '
            'atualize o catálogo antes de lançar o custo',
          );
        }
        final valor = respostas.valorCustoCentavos ?? t.valorCentavos;
        final data = respostas.dataPagamentoCusto!;
        await _banco.into(_banco.despesasLivroCaixa).insert(
              DespesasLivroCaixaCompanion.insert(
                id: _uuid.v7(),
                rubricaCodigo: rubrica.id,
                competencia: data.substring(0, 7),
                dataPagamento: data,
                valorCentavos: valor,
                valorDedutivelCentavos: rubrica.despesa(valor).dedutivelCentavos,
                descricao: Value('Custo repassado: ${t.descricaoRaw}'),
                lancamentoOrigemId: Value(id),
                criadoEm: agora,
              ),
            );
      }

      final proposta = chave == null || documento != null
          ? null
          : propostaParaRemetente(
              classificada: respostas.classificacao,
              pendentes: await _pendentesComChave(chave, excluir: transacaoId),
            );
      return ResultadoClassificacao(
        lancamentoId: id,
        remetenteId: remetenteId,
        proposta: proposta,
      );
    });
  }

  /// Toque no "proposto pela regra": a classificação vira confirmada.
  Future<void> confirmar(String lancamentoId) async {
    await (_banco.update(_banco.lancamentos)
          ..where((l) => l.id.equals(lancamentoId)))
        .write(LancamentosCompanion(confirmadaEm: Value(_agoraEpochMs())));
  }

  // ── Proposta por remetente ────────────────────────────────────────────

  /// Aplica [proposta] (só o que ela declarou) e confirma a regra do
  /// [remetenteId]. Devolve o necessário para [desfazer].
  Future<ProposicaoAceita> aceitarProposta(
    PropostaDeRegra proposta,
    String remetenteId,
  ) {
    return _banco.transaction(() async {
      final remetente = await (_banco.select(_banco.remetentes)
            ..where((r) => r.id.equals(remetenteId)))
          .getSingle();
      final criados = <String>[];
      for (final transacaoId in proposta.ids) {
        final r = await classificar(
          transacaoId,
          RespostasClassificacao(classificacao: proposta.classificacao),
          origem: OrigemClassificacao.sugestaoAceita,
        );
        criados.add(r.lancamentoId);
      }
      await (_banco.update(_banco.remetentes)
            ..where((r) => r.id.equals(remetenteId)))
          .write(RemetentesCompanion(
        regraClassificacao: Value(proposta.classificacao.name),
        regraConfirmadaEm: Value(_agoraEpochMs()),
      ));
      await _auditar('remetentes', remetenteId, 'atualizar', {
        'proposta_aceita': proposta.classificacao.name,
        'lancamentos': criados,
      });
      return ProposicaoAceita(
        remetenteId: remetenteId,
        lancamentosCriados: criados,
        regraAnterior: remetente.regraClassificacao,
        regraConfirmadaAnterior: remetente.regraConfirmadaEm,
      );
    });
  }

  /// Desfaz [aceita]: os lançamentos voltam à fila e a regra volta ao que
  /// era.
  Future<void> desfazer(ProposicaoAceita aceita) {
    return _banco.transaction(() async {
      for (final id in aceita.lancamentosCriados) {
        await (_banco.delete(_banco.historicoClassificacao)
              ..where((h) => h.lancamentoId.equals(id)))
            .go();
        await (_banco.delete(_banco.lancamentos)..where((l) => l.id.equals(id)))
            .go();
      }
      await (_banco.update(_banco.remetentes)
            ..where((r) => r.id.equals(aceita.remetenteId)))
          .write(RemetentesCompanion(
        regraClassificacao: Value(aceita.regraAnterior),
        regraConfirmadaEm: Value(aceita.regraConfirmadaAnterior),
      ));
      await _auditar('remetentes', aceita.remetenteId, 'atualizar', {
        'proposta_desfeita': aceita.lancamentosCriados,
      });
    });
  }

  /// Aplica as regras CONFIRMADAS aos créditos sem lançamento (chamado
  /// depois de confirmar uma importação). Devolve quantos receberam
  /// proposta da regra.
  Future<int> aplicarRegrasAosNovos() {
    return _banco.transaction(() async {
      final regras = await (_banco.select(_banco.remetentes)
            ..where((r) =>
                r.regraConfirmadaEm.isNotNull() &
                r.cpf.isNull() &
                r.cnpj.isNull()))
          .get();
      final porChave = {for (final r in regras) r.chaveNome: r};
      if (porChave.isEmpty) return 0;
      final pendentes = await _banco.customSelect(
        'SELECT t.id, t.data, t.valor_centavos, t.descricao_raw '
        'FROM transacoes t LEFT JOIN lancamentos l ON l.transacao_id = t.id '
        'WHERE t.valor_centavos > 0 AND l.id IS NULL',
      ).get();
      final agora = _agoraEpochMs();
      var aplicados = 0;
      for (final p in pendentes) {
        final remetente =
            porChave[chaveDoRemetente(p.read<String>('descricao_raw'))];
        if (remetente == null) continue;
        final classificacao = classificacaoPelaRegra(
          regra: switch (remetente.regraClassificacao) {
            null => null,
            final c => ClassificacaoLancamento.values.byName(c),
          },
          regraConfirmada: true,
        );
        if (classificacao == null) continue;
        final data = p.read<String>('data');
        await _banco.into(_banco.lancamentos).insert(
              LancamentosCompanion.insert(
                id: _uuid.v7(),
                transacaoId: Value(p.read<String>('id')),
                competencia: data.substring(0, 7),
                dataRecebimento: data,
                valorCentavos: p.read<int>('valor_centavos'),
                classificacao: classificacao.name,
                remetenteId: Value(remetente.id),
                nomePagador: Value(remetente.nome),
                origemClassificacao:
                    Value(OrigemClassificacao.regraRemetente.name),
                criadoEm: agora,
                atualizadoEm: agora,
              ),
            );
        aplicados++;
      }
      return aplicados;
    });
  }

  // ── Internos ──────────────────────────────────────────────────────────

  Future<Transacao> _transacao(String id) async {
    final t = await (_banco.select(_banco.transacoes)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (t == null) throw ArgumentError('transação não encontrada: $id');
    return t;
  }

  Future<Profissao?> _profissaoDoPerfil(Catalogo catalogo) async {
    final perfil = await _banco.select(_banco.perfil).getSingleOrNull();
    final codigo = perfil?.profissaoCodigo;
    return codigo == null ? null : catalogo.profissaoPorId(codigo);
  }

  /// O remetente do lançamento: pelo documento, se informado; senão pela
  /// chave de nome. Cria quando não existe.
  Future<String?> _remetente({
    required String? chave,
    required ({String digitos, bool ehCnpj})? documento,
    required String? nome,
  }) async {
    if (documento == null && chave == null) return null;
    final Remetente? existente;
    if (documento != null) {
      existente = await (_banco.select(_banco.remetentes)
            ..where((r) => documento.ehCnpj
                ? r.cnpj.equals(documento.digitos)
                : r.cpf.equals(documento.digitos)))
          .getSingleOrNull();
    } else {
      existente = await (_banco.select(_banco.remetentes)
            ..where((r) =>
                r.chaveNome.equals(chave!) & r.cpf.isNull() & r.cnpj.isNull()))
          .getSingleOrNull();
    }
    if (existente != null) return existente.id;
    final id = _uuid.v7();
    await _banco.into(_banco.remetentes).insert(
          RemetentesCompanion.insert(
            id: id,
            nome: nome ?? chave ?? documento!.digitos,
            chaveNome: chave ?? documento!.digitos,
            cpf: Value(
                documento != null && !documento.ehCnpj ? documento.digitos : null),
            cnpj: Value(
                documento != null && documento.ehCnpj ? documento.digitos : null),
            criadoEm: _agoraEpochMs(),
          ),
        );
    return id;
  }

  /// Créditos sem lançamento cuja descrição dá a mesma [chave].
  Future<List<PendenteDoRemetente>> _pendentesComChave(
    String chave, {
    required String excluir,
  }) async {
    final linhas = await _banco.customSelect(
      'SELECT t.id, t.valor_centavos, t.descricao_raw '
      'FROM transacoes t LEFT JOIN lancamentos l ON l.transacao_id = t.id '
      'WHERE t.valor_centavos > 0 AND l.id IS NULL AND t.id != ? '
      'ORDER BY t.data, t.id',
      variables: [Variable.withString(excluir)],
    ).get();
    return [
      for (final r in linhas)
        if (chaveDoRemetente(r.read<String>('descricao_raw')) == chave)
          (id: r.read<String>('id'), valorCentavos: r.read<int>('valor_centavos')),
    ];
  }

  Future<void> _auditar(
    String entidade,
    String id,
    String acao,
    Map<String, Object?> detalhe,
  ) =>
      _banco.into(_banco.auditoria).insert(
            AuditoriaCompanion.insert(
              entidade: entidade,
              entidadeId: Value(id),
              acao: acao,
              detalhe: Value(jsonEncode(detalhe)),
              criadoEm: _agoraEpochMs(),
            ),
          );
}
