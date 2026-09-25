/// Persistência do livro-caixa: despesas manuais (M9) e débitos do extrato
/// que viram despesa (decisão 5 do owner).
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

  DebitoDoExtrato _debito(QueryRow r) => DebitoDoExtrato(
        transacaoId: r.read<String>('id'),
        data: r.read<String>('data'),
        valorCentavos: -r.read<int>('valor_centavos'),
        descricao: r.read<String>('descricao_raw'),
        chave: chaveDoRemetente(r.read<String>('descricao_raw')),
      );
}
