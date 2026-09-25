/// Persistência do livro-caixa: despesas manuais (M9) e débitos do extrato
/// que viram despesa (decisão 5 do owner) — e as outras deduções do mês,
/// INSS e dependentes.
///
/// A regra fiscal é do core: a rubrica (catálogo) decide a trava de 20% e a
/// vedação (`Rubrica.despesa`), e a competência sai de `competenciaDaDespesa`
/// — cartão de crédito pela data da COMPRA (rodada 4b, P5). Este arquivo só
/// grava o que o core decide.
library;

import 'dart:convert';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../dados/banco.dart';

/// Uma despesa como a aba Despesas (M8) mostra.
class DespesaDoMes {
  const DespesaDoMes({
    required this.id,
    required this.rubrica,
    required this.data,
    required this.forma,
    required this.valorCentavos,
    required this.dedutivelCentavos,
    required this.descricao,
    required this.doExtrato,
    required this.deRepasse,
  });

  final String id;

  /// A rubrica do catálogo, ou `null` se o catálogo não a tem mais.
  final Rubrica? rubrica;
  final String data;
  final FormaPagamentoDespesa forma;
  final int valorCentavos;
  final int dedutivelCentavos;
  final String? descricao;
  final bool doExtrato;

  /// Nasceu do custo de um reembolso/repasse essencial (P2/P3).
  final bool deRepasse;
}

/// Um débito do extrato que ainda não é despesa.
class DebitoDoExtrato {
  const DebitoDoExtrato({
    required this.transacaoId,
    required this.data,
    required this.valorCentavos,
    required this.descricao,
    required this.chave,
  });

  final String transacaoId;
  final String data;

  /// Positivo (o débito do extrato, sem o sinal).
  final int valorCentavos;
  final String descricao;

  /// Chave do favorecido extraída da descrição — agrupa débitos recorrentes.
  final String? chave;
}

/// Uma resposta sobre o INSS do mês: uma guia paga (principal e acréscimos
/// separados — só o principal deduz, rodada 4, P6) ou o "não paguei".
class InssDoMes {
  const InssDoMes({
    required this.id,
    required this.situacao,
    required this.principalCentavos,
    required this.acrescimosCentavos,
  });

  final String id;
  final SituacaoInss situacao;
  final int principalCentavos;
  final int acrescimosCentavos;
}

/// Um dependente com a vigência: conta o mês inteiro em que existiu em
/// qualquer dia (rodada 4, P7 — a conta é do core, `dependentesNoMes`).
class DependenteCadastrado {
  const DependenteCadastrado({
    required this.id,
    required this.nome,
    required this.inicio,
    required this.fim,
  });

  final String id;
  final String nome;
  final String inicio;
  final String? fim;
}

/// "Lançar os outros 2 como Aluguel da casa (R$ 2.400,00)": a mesma
/// proposta por remetente da classificação, para débitos recorrentes.
class PropostaDeDespesa {
  const PropostaDeDespesa({
    required this.rubrica,
    required this.debitos,
  });

  final Rubrica rubrica;
  final List<DebitoDoExtrato> debitos;

  int get totalCentavos {
    var t = 0;
    for (final d in debitos) {
      t += d.valorCentavos;
    }
    return t;
  }

  String get rotulo {
    final alvo =
        debitos.length == 1 ? 'o outro' : 'os outros ${debitos.length}';
    return 'Lançar $alvo como ${rubrica.nome} '
        '(${centavosParaExibicao(totalCentavos)})';
  }
}

class RepositorioDespesas {
  RepositorioDespesas(
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

  /// As rubricas do catálogo, em ordem. Vazia = catálogo antigo: a tela diz
  /// isso e não deixa registrar (nunca inventa rubrica local).
  Future<List<Rubrica>> rubricas() async => (await _catalogo()).rubricas;

  /// Registra uma despesa. Com [transacaoId], é um débito do extrato: o
  /// valor e a data saem da transação, e a forma é `extrato`.
  ///
  /// Recusa ([ArgumentError]) rubrica que o catálogo não tem, valor não
  /// positivo, e a linha exclusiva sem a declaração de exclusividade
  /// (rodada 4b).
  Future<String> registrar({
    required String rubricaId,
    int? valorCentavos,
    String? dataPagamento,
    FormaPagamentoDespesa forma = FormaPagamentoDespesa.outra,
    String? descricao,
    bool declarouExclusividade = false,
    String? transacaoId,
  }) async {
    final rubrica = (await _catalogo()).rubricaPorId(rubricaId);
    if (rubrica == null) {
      throw ArgumentError('rubrica fora do catálogo: $rubricaId');
    }
    if (rubrica.exigeDeclaracaoExclusividade && !declarouExclusividade) {
      throw ArgumentError(
        '${rubrica.nome} só entra com a declaração de uso exclusivo',
      );
    }
    return _banco.transaction(() async {
      var valor = valorCentavos;
      var data = dataPagamento;
      var formaFinal = forma;
      var texto = descricao;
      if (transacaoId != null) {
        final t = await (_banco.select(_banco.transacoes)
              ..where((t) => t.id.equals(transacaoId)))
            .getSingle();
        if (t.valorCentavos >= 0) {
          throw ArgumentError('só débito do extrato vira despesa');
        }
        valor = -t.valorCentavos;
        data = t.data;
        formaFinal = FormaPagamentoDespesa.extrato;
        texto ??= t.descricaoRaw;
      }
      if (valor == null || valor <= 0) {
        throw ArgumentError('valor da despesa precisa ser positivo');
      }
      if (data == null) throw ArgumentError('falta a data da despesa');
      final agora = _agoraEpochMs();
      final id = _uuid.v7();
      await _banco.into(_banco.despesasLivroCaixa).insert(
            DespesasLivroCaixaCompanion.insert(
              id: id,
              rubricaCodigo: rubrica.id,
              competencia:
                  competenciaDaDespesa(forma: formaFinal, dataPagamento: data),
              dataPagamento: data,
              formaPagamento: Value(formaFinal.name),
              valorCentavos: valor,
              valorDedutivelCentavos: rubrica.despesa(valor).dedutivelCentavos,
              descricao: Value(texto),
              homeOffice: Value(rubrica.travaResidencia ? 1 : 0),
              transacaoId: Value(transacaoId),
              exclusividadeDeclaradaEm:
                  Value(declarouExclusividade ? agora : null),
              criadoEm: agora,
            ),
          );
      await _banco.into(_banco.auditoria).insert(
            AuditoriaCompanion.insert(
              entidade: 'despesas_livro_caixa',
              entidadeId: Value(id),
              acao: 'criar',
              detalhe: Value(jsonEncode({'rubrica': rubrica.id})),
              criadoEm: agora,
            ),
          );
      return id;
    });
  }

  /// Exclui uma despesa lançada pela pessoa. A despesa de um repasse se
  /// corrige reclassificando o recebimento, não por aqui.
  Future<void> excluir(String id) async {
    final d = await (_banco.select(_banco.despesasLivroCaixa)
          ..where((d) => d.id.equals(id)))
        .getSingle();
    if (d.lancamentoOrigemId != null) {
      throw StateError(
        'despesa de repasse: corrija o recebimento que a gerou',
      );
    }
    await (_banco.delete(_banco.despesasLivroCaixa)
          ..where((d) => d.id.equals(id)))
        .go();
  }

  /// As despesas da [competencia], mais recentes primeiro.
  Future<List<DespesaDoMes>> despesasDoMes(String competencia) async {
    final catalogo = await _catalogo();
    final linhas = await (_banco.select(_banco.despesasLivroCaixa)
          ..where((d) => d.competencia.equals(competencia))
          ..orderBy([
            (d) => OrderingTerm.desc(d.dataPagamento),
            (d) => OrderingTerm.asc(d.id),
          ]))
        .get();
    return [
      for (final d in linhas)
        DespesaDoMes(
          id: d.id,
          rubrica: catalogo.rubricaPorId(d.rubricaCodigo),
          data: d.dataPagamento,
          forma: FormaPagamentoDespesa.values.byName(d.formaPagamento),
          valorCentavos: d.valorCentavos,
          dedutivelCentavos: d.valorDedutivelCentavos,
          descricao: d.descricao,
          doExtrato: d.transacaoId != null,
          deRepasse: d.lancamentoOrigemId != null,
        ),
    ];
  }

  /// Débitos da [competencia] que ainda não são despesa.
  Future<List<DebitoDoExtrato>> debitosDoMes(String competencia) async {
    final linhas = await _banco.customSelect(
      'SELECT t.id, t.data, t.valor_centavos, t.descricao_raw '
      'FROM transacoes t LEFT JOIN despesas_livro_caixa d ON d.transacao_id = t.id '
      'WHERE t.valor_centavos < 0 AND d.id IS NULL '
      'AND substr(t.data, 1, 7) = ? ORDER BY t.data DESC, t.id',
      variables: [Variable.withString(competencia)],
    ).get();
    return [for (final r in linhas) _debito(r)];
  }

  /// Os outros débitos (de qualquer mês) do mesmo favorecido de
  /// [transacaoId] — a proposta para débitos recorrentes. `null` se não há.
  Future<PropostaDeDespesa?> propostaPara(
    String transacaoId,
    String rubricaId,
  ) async {
    final rubrica = (await _catalogo()).rubricaPorId(rubricaId);
    if (rubrica == null || rubrica.exigeDeclaracaoExclusividade) return null;
    final base = await (_banco.select(_banco.transacoes)
          ..where((t) => t.id.equals(transacaoId)))
        .getSingle();
    final chave = chaveDoRemetente(base.descricaoRaw);
    if (chave == null) return null;
    final linhas = await _banco.customSelect(
      'SELECT t.id, t.data, t.valor_centavos, t.descricao_raw '
      'FROM transacoes t LEFT JOIN despesas_livro_caixa d ON d.transacao_id = t.id '
      'WHERE t.valor_centavos < 0 AND d.id IS NULL AND t.id != ? '
      'ORDER BY t.data, t.id',
      variables: [Variable.withString(transacaoId)],
    ).get();
    final iguais = [
      for (final r in linhas)
        if (_debito(r).chave == chave) _debito(r),
    ];
    if (iguais.isEmpty) return null;
    return PropostaDeDespesa(rubrica: rubrica, debitos: iguais);
  }

  /// Aplica a proposta — só os débitos que ela declarou. Devolve os ids das
  /// despesas criadas, para o desfazer.
  Future<List<String>> aceitarProposta(PropostaDeDespesa proposta) async {
    final ids = <String>[];
    for (final d in proposta.debitos) {
      ids.add(await registrar(
        rubricaId: proposta.rubrica.id,
        transacaoId: d.transacaoId,
      ));
    }
    return ids;
  }

  // ─── INSS ──────────────────────────────────────────────────────────

  /// As respostas de INSS da [competencia] (mês do PAGAMENTO efetivo).
  Future<List<InssDoMes>> inssDoMes(String competencia) async {
    final linhas = await (_banco.select(_banco.pagamentosInss)
          ..where((p) => p.competencia.equals(competencia))
          ..orderBy([(p) => OrderingTerm.asc(p.criadoEm)]))
        .get();
    return [
      for (final p in linhas)
        InssDoMes(
          id: p.id,
          situacao: SituacaoInss.values.byName(p.situacao),
          principalCentavos: p.valorCentavos,
          acrescimosCentavos: p.acrescimosCentavos,
        ),
    ];
  }

  /// Registra uma guia paga no mês. Um "não paguei" anterior do mesmo mês
  /// sai — a pessoa mudou a resposta.
  Future<String> registrarInssPago({
    required String competencia,
    required int principalCentavos,
    int acrescimosCentavos = 0,
  }) async {
    if (principalCentavos <= 0) {
      throw ArgumentError('o principal da guia precisa ser positivo');
    }
    if (acrescimosCentavos < 0) {
      throw ArgumentError('acréscimos não podem ser negativos');
    }
    return _banco.transaction(() async {
      await (_banco.delete(_banco.pagamentosInss)
            ..where((p) =>
                p.competencia.equals(competencia) &
                p.situacao.equals(SituacaoInss.naoPago.name)))
          .go();
      final id = _uuid.v7();
      await _banco.into(_banco.pagamentosInss).insert(
            PagamentosInssCompanion.insert(
              id: id,
              competencia: competencia,
              valorCentavos: principalCentavos,
              acrescimosCentavos: Value(acrescimosCentavos),
              criadoEm: _agoraEpochMs(),
            ),
          );
      return id;
    });
  }

  /// Grava "não paguei" — a resposta existe e o mês deduz zero de INSS.
  /// Recusa ([StateError]) se o mês já tem guia paga: exclua a guia antes.
  Future<void> registrarInssNaoPago(String competencia) async {
    await _banco.transaction(() async {
      final atuais = await inssDoMes(competencia);
      if (atuais.any((i) => i.situacao == SituacaoInss.pago)) {
        throw StateError('o mês já tem guia de INSS paga');
      }
      if (atuais.isNotEmpty) return;
      await _banco.into(_banco.pagamentosInss).insert(
            PagamentosInssCompanion.insert(
              id: _uuid.v7(),
              competencia: competencia,
              situacao: Value(SituacaoInss.naoPago.name),
              valorCentavos: 0,
              criadoEm: _agoraEpochMs(),
            ),
          );
    });
  }

  Future<void> excluirInss(String id) =>
      (_banco.delete(_banco.pagamentosInss)..where((p) => p.id.equals(id)))
          .go();

  // ─── Dependentes ───────────────────────────────────────────────────

  Future<List<DependenteCadastrado>> dependentes() async => [
        for (final d in await (_banco.select(_banco.dependentes)
              ..orderBy([
                (d) => OrderingTerm.asc(d.vigenciaInicio),
                (d) => OrderingTerm.asc(d.id),
              ]))
            .get())
          DependenteCadastrado(
            id: d.id,
            nome: d.nome,
            inicio: d.vigenciaInicio,
            fim: d.vigenciaFim,
          ),
      ];

  /// Cadastra um dependente desde [inicio] (`'YYYY-MM-DD'`).
  Future<String> adicionarDependente({
    required String nome,
    required String inicio,
    String? fim,
  }) async {
    final limpo = nome.trim();
    if (limpo.isEmpty) throw ArgumentError('falta o nome do dependente');
    _validarVigencia(inicio, fim);
    final id = _uuid.v7();
    await _banco.into(_banco.dependentes).insert(
          DependentesCompanion.insert(
            id: id,
            nome: limpo,
            vigenciaInicio: inicio,
            vigenciaFim: Value(fim),
            criadoEm: _agoraEpochMs(),
          ),
        );
    return id;
  }

  /// Registra (ou desfaz, com `null`) a última data como dependente.
  Future<void> encerrarDependente(String id, String? fim) async {
    final d = await (_banco.select(_banco.dependentes)
          ..where((d) => d.id.equals(id)))
        .getSingle();
    _validarVigencia(d.vigenciaInicio, fim);
    await (_banco.update(_banco.dependentes)..where((d) => d.id.equals(id)))
        .write(DependentesCompanion(vigenciaFim: Value(fim)));
  }

  Future<void> excluirDependente(String id) =>
      (_banco.delete(_banco.dependentes)..where((d) => d.id.equals(id))).go();

  static final _dataCivil = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  void _validarVigencia(String inicio, String? fim) {
    if (!_dataCivil.hasMatch(inicio) ||
        (fim != null && !_dataCivil.hasMatch(fim))) {
      throw ArgumentError('data fora do formato AAAA-MM-DD');
    }
    if (fim != null && fim.compareTo(inicio) < 0) {
      throw ArgumentError('o fim não pode vir antes do início');
    }
  }

  DebitoDoExtrato _debito(QueryRow r) => DebitoDoExtrato(
        transacaoId: r.read<String>('id'),
        data: r.read<String>('data'),
        valorCentavos: -r.read<int>('valor_centavos'),
        descricao: r.read<String>('descricao_raw'),
        chave: chaveDoRemetente(r.read<String>('descricao_raw')),
      );
}
