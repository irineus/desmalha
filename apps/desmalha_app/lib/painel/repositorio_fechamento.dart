/// Persistência do fechamento: a apuração gravada, o DARF pago e o
/// histórico de pagamentos (decisão 7 do owner, 25/09/2026).
///
/// Quem fecha o mês é marcar o DARF como pago — fecha o período da guia e
/// os meses que ela absorveu (N:1). Mês sem guia (isento, resíduo de
/// dezembro) fecha pelo botão "Fechar mês". Uma apuração fechada nunca é
/// editada: a correção grava versão +1 e a anterior vira `substituida`.
///
/// O que o acerto de uma guia paga significa (P8/P9, rodada 5) é do core
/// (`acertoDaGuia`); aqui só se grava e se lê.
library;

import 'dart:convert';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../dados/banco.dart';
import '../versao.dart';

/// Um mês recalculado, com o que a apuração gravada precisa guardar.
class MesApurado {
  const MesApurado({
    required this.apuracao,
    required this.dados,
    required this.tabela,
  });

  final ApuracaoMensal apuracao;
  final DadosDoMes dados;
  final TabelaIrpf tabela;
}

/// Um DARF marcado como pago.
class PagamentoDarf {
  const PagamentoDarf({
    required this.id,
    required this.periodo,
    required this.competencias,
    required this.principalCentavos,
    required this.acrescimosCentavos,
    required this.pagoEm,
  });

  final String id;

  /// Período de apuração da guia (a última competência, P10).
  final String periodo;
  final List<String> competencias;
  final int principalCentavos;

  /// Multa e juros: registrados, nunca contam como imposto (P11).
  final int acrescimosCentavos;
  final String pagoEm;
}

/// O que a apuração fechada gravou — o bastante para saber se o recálculo
/// de hoje ainda é o mesmo.
class ApuracaoFechada {
  const ApuracaoFechada({
    required this.id,
    required this.competencia,
    required this.versao,
    required this.assinatura,
    required this.fechadaEm,
  });

  final String id;
  final String competencia;
  final int versao;
  final String assinatura;
  final int? fechadaEm;
}

/// Os números que, se mudarem, pedem uma nova versão da apuração.
String assinaturaDe(MesApurado m) => [
      m.apuracao.receitaBrutaCentavos,
      m.dados.despesasDedutiveisCentavos,
      m.dados.inssDedutivelCentavos,
      m.dados.dependentes,
      m.apuracao.impostoDevidoCentavos,
      m.apuracao.totalParaDarfCentavos,
    ].join('/');

class RepositorioFechamento {
  RepositorioFechamento(
    this._banco, {
    int Function()? agoraEpochMs,
    // Parâmetro nomeado não pode começar com underscore.
    // ignore: prefer_initializing_formals
  }) : _agoraEpochMs =
            agoraEpochMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  final BancoLocal _banco;
  final int Function() _agoraEpochMs;
  final _uuid = const Uuid();

  /// Os DARFs pagos com período no [ano], do mais recente ao mais antigo.
  Future<List<PagamentoDarf>> pagamentos(int ano) async {
    final linhas = await _banco.customSelect(
      'SELECT d.id, d.competencia, d.valor_pago_centavos, '
      'd.acrescimos_pagos_centavos, d.pago_em, '
      "GROUP_CONCAT(dc.competencia, ',') AS abrangidas "
      'FROM darfs d LEFT JOIN darf_competencias dc ON dc.darf_id = d.id '
      "WHERE d.status = 'paga' AND substr(d.competencia, 1, 4) = ? "
      'GROUP BY d.id ORDER BY d.pago_em DESC, d.criado_em DESC',
      variables: [Variable.withString('$ano')],
    ).get();
    return [
      for (final l in linhas)
        PagamentoDarf(
          id: l.read<String>('id'),
          periodo: l.read<String>('competencia'),
          competencias: ([
            ...?l.read<String?>('abrangidas')?.split(','),
          ]..sort()),
          principalCentavos: l.read<int>('valor_pago_centavos'),
          acrescimosCentavos: l.read<int>('acrescimos_pagos_centavos'),
          pagoEm: l.read<String>('pago_em'),
        ),
    ];
  }

  /// As guias pagas do [ano], uma por período: a original e os
  /// complementares somam o principal pago daquele período.
  Future<List<GuiaPaga>> guiasPagas(int ano) async {
    final porPeriodo = <String, (Set<String>, int)>{};
    for (final p in await pagamentos(ano)) {
      final (comps, total) = porPeriodo[p.periodo] ?? (<String>{}, 0);
      porPeriodo[p.periodo] =
          ({...comps, ...p.competencias, p.periodo}, total + p.principalCentavos);
    }
    return [
      for (final e in porPeriodo.entries)
        GuiaPaga(
          competencias: e.value.$1.toList(),
          principalPagoCentavos: e.value.$2,
        ),
    ]..sort((a, b) => a.periodo.compareTo(b.periodo));
  }

  /// As apurações fechadas vigentes do [ano], por competência.
  Future<Map<String, ApuracaoFechada>> fechadas(int ano) async {
    final linhas = await (_banco.select(_banco.apuracoesMensais)
          ..where((a) =>
              a.status.equals(StatusApuracao.fechada.name) &
              a.competencia.like('$ano-%')))
        .get();
    return {
      for (final a in linhas)
        a.competencia: ApuracaoFechada(
          id: a.id,
          competencia: a.competencia,
          versao: a.versao,
          assinatura: [
            a.receitaBrutaCentavos,
            a.despesasLivroCaixaCentavos,
            a.inssCentavos,
            a.qtdeDependentes,
            a.impostoDevidoCentavos,
            a.totalParaDarfCentavos,
          ].join('/'),
          fechadaEm: a.fechadaEm,
        ),
    };
  }

  /// Marca a guia do [periodo] como paga: grava o DARF e fecha a apuração
  /// de cada competência que ela abrange ([meses] traz o recálculo de
  /// cada uma). Devolve o id do DARF.
  Future<String> marcarPago({
    required String periodo,
    required List<String> competencias,
    required Map<String, MesApurado> meses,
    required int principalCentavos,
    required String vencimento,
    required String pagoEm,
    int acrescimosCentavos = 0,
  }) async {
    if (principalCentavos <= 0) {
      throw ArgumentError('o principal pago precisa ser positivo');
    }
    if (acrescimosCentavos < 0) {
      throw ArgumentError('acréscimos não podem ser negativos');
    }
    if (!competencias.contains(periodo)) {
      throw ArgumentError('a guia abrange o próprio período');
    }
    return _banco.transaction(() async {
      final apuracoes = <String, String>{};
      for (final c in competencias) {
        final m = meses[c];
        if (m == null) throw ArgumentError('falta o recálculo de $c');
        apuracoes[c] = await _gravarFechada(m);
      }
      return _gravarDarf(
        periodo: periodo,
        apuracoes: apuracoes,
        principalCentavos: principalCentavos,
        acrescimosCentavos: acrescimosCentavos,
        vencimento: vencimento,
        pagoEm: pagoEm,
      );
    });
  }

  /// O DARF complementar de P8, pago: soma ao principal do [periodo].
  Future<String> registrarComplementar({
    required String periodo,
    required int principalCentavos,
    required String vencimento,
    required String pagoEm,
    int acrescimosCentavos = 0,
  }) async {
    if (principalCentavos <= 0) {
      throw ArgumentError('o principal pago precisa ser positivo');
    }
    return _banco.transaction(() async {
      final vigente = await (_banco.select(_banco.apuracoesMensais)
            ..where((a) =>
                a.competencia.equals(periodo) &
                a.status.equals(StatusApuracao.fechada.name)))
          .getSingleOrNull();
      if (vigente == null) {
        throw StateError('$periodo não tem guia paga para complementar');
      }
      return _gravarDarf(
        periodo: periodo,
        apuracoes: {periodo: vigente.id},
        principalCentavos: principalCentavos,
        acrescimosCentavos: acrescimosCentavos,
        vencimento: vencimento,
        pagoEm: pagoEm,
      );
    });
  }

  /// "Fechar mês" de um mês sem guia: isento ou resíduo de dezembro.
  Future<String> fecharSemGuia(MesApurado m) async {
    final status = m.apuracao.statusDarf;
    if (status != StatusDarf.semImposto &&
        status != StatusDarf.residuoParaDirpf) {
      throw StateError(
        'mês com imposto a recolher fecha marcando o DARF como pago',
      );
    }
    return _banco.transaction(() => _gravarFechada(m));
  }

  /// Grava a correção: cada mês fechado cujo recálculo mudou ganha versão
  /// +1, e a anterior vira `substituida`. Devolve as competências
  /// regravadas.
  Future<List<String>> registrarCorrecao(Map<String, MesApurado> meses) =>
      _banco.transaction(() async {
        final regravadas = <String>[];
        final anos = {for (final c in meses.keys) int.parse(c.substring(0, 4))};
        for (final ano in anos) {
          for (final f in (await fechadas(ano)).values) {
            final m = meses[f.competencia];
            if (m == null || assinaturaDe(m) == f.assinatura) continue;
            final novo = await _gravarFechada(m);
            await (_banco.update(_banco.darfCompetencias)
                  ..where((d) => d.apuracaoId.equals(f.id)))
                .write(DarfCompetenciasCompanion(apuracaoId: Value(novo)));
            regravadas.add(f.competencia);
          }
        }
        regravadas.sort();
        return regravadas;
      });

  Future<String> _gravarFechada(MesApurado m) async {
    final c = m.apuracao.competencia;
    final anteriores = await (_banco.select(_banco.apuracoesMensais)
          ..where((a) => a.competencia.equals(c)))
        .get();
    var versao = 1;
    for (final a in anteriores) {
      if (a.versao >= versao) versao = a.versao + 1;
    }
    await (_banco.update(_banco.apuracoesMensais)
          ..where((a) =>
              a.competencia.equals(c) &
              a.status.isNotValue(StatusApuracao.substituida.name)))
        .write(ApuracoesMensaisCompanion(
          status: Value(StatusApuracao.substituida.name),
        ));
    final a = m.apuracao;
    final agora = _agoraEpochMs();
    final id = _uuid.v7();
    await _banco.into(_banco.apuracoesMensais).insert(
          ApuracoesMensaisCompanion.insert(
            id: id,
            competencia: c,
            versao: Value(versao),
            status: Value(StatusApuracao.fechada.name),
            receitaBrutaCentavos: a.receitaBrutaCentavos,
            despesasLivroCaixaCentavos: m.dados.despesasDedutiveisCentavos,
            saldoNegativoAnteriorCentavos:
                Value(a.saldoNegativoAnteriorCentavos),
            saldoNegativoUtilizadoCentavos:
                Value(a.saldoNegativoUtilizadoCentavos),
            saldoNegativoTransportadoCentavos:
                Value(a.saldoNegativoNovoCentavos),
            inssCentavos: m.dados.inssDedutivelCentavos,
            qtdeDependentes: m.dados.dependentes,
            deducaoDependentesCentavos:
                m.dados.dependentes * m.tabela.valorDependenteCentavos,
            descontoSimplificadoCentavos: m.tabela.descontoSimplificadoCentavos,
            impostoCenarioRealCentavos: a.impostoCenarioACentavos,
            impostoCenarioSimplificadoCentavos: a.impostoCenarioBCentavos,
            cenarioAplicado: a.cenarioVencedor.name,
            baseCalculoCentavos: a.baseCalculoCentavos,
            aliquotaBp: a.aliquotaPontosBase,
            parcelaDeduzirCentavos: a.parcelaDeduzirCentavos,
            impostoApuradoCentavos: a.impostoApuradoCentavos,
            redutorLeiCentavos: Value(a.reducaoRedutorCentavos),
            impostoDevidoCentavos: a.impostoDevidoCentavos,
            impostoDiferidoAnteriorCentavos:
                Value(a.impostoAcumuladoAnteriorCentavos),
            impostoDiferidoCentavos: Value(a.impostoAcumuladoNovoCentavos),
            totalParaDarfCentavos: Value(a.totalParaDarfCentavos),
            statusDarf: a.statusDarf.name,
            isento: Value(a.impostoDevidoCentavos == 0 ? 1 : 0),
            tabelaIrpfId: a.versaoTabelaId,
            catalogoVersoesSnapshot: jsonEncode({'tabelaIrpf': a.versaoTabelaId}),
            parametrosSnapshot: jsonEncode(m.tabela.toJson()),
            motorVersao: versaoDoMotor,
            appVersao: versaoDoApp,
            calculadaEm: agora,
            fechadaEm: Value(agora),
          ),
        );
    await _banco.into(_banco.auditoria).insert(
          AuditoriaCompanion.insert(
            entidade: 'apuracoes_mensais',
            entidadeId: Value(id),
            acao: 'criar',
            detalhe: Value(jsonEncode({'competencia': c, 'versao': versao})),
            criadoEm: agora,
          ),
        );
    return id;
  }

  Future<String> _gravarDarf({
    required String periodo,
    required Map<String, String> apuracoes,
    required int principalCentavos,
    required int acrescimosCentavos,
    required String vencimento,
    required String pagoEm,
  }) async {
    final id = _uuid.v7();
    await _banco.into(_banco.darfs).insert(
          DarfsCompanion.insert(
            id: id,
            competencia: periodo,
            valorCentavos: principalCentavos,
            vencimento: vencimento,
            status: Value(StatusGuiaDarf.paga.name),
            pagoEm: Value(pagoEm),
            valorPagoCentavos: Value(principalCentavos),
            acrescimosPagosCentavos: Value(acrescimosCentavos),
            criadoEm: _agoraEpochMs(),
          ),
        );
    for (final e in apuracoes.entries) {
      await _banco.into(_banco.darfCompetencias).insert(
            DarfCompetenciasCompanion.insert(
              darfId: id,
              competencia: e.key,
              apuracaoId: e.value,
            ),
          );
    }
    return id;
  }
}
