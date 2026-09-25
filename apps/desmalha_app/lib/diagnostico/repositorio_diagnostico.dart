/// Reúne, do aparelho, só o que o resumo de diagnóstico pode levar —
/// contagens e estados, nunca nome, CPF ou descrição (decisão 11 do owner).
/// Quem decide o formato é o core (`montarResumoDiagnostico`).
library;

import 'package:desmalha_core/desmalha_core.dart';
import 'package:drift/drift.dart' show Variable;

import '../dados/banco.dart';
import '../painel/repositorio_fechamento.dart';
import '../painel/repositorio_painel.dart';
import '../versao.dart';

class RepositorioDiagnostico {
  RepositorioDiagnostico(
    this._banco, {
    required RepositorioPainel painel,
    required RepositorioFechamento fechamento,
    // Parâmetro nomeado não pode começar com underscore.
    // ignore: prefer_initializing_formals
  })  : _painel = painel,
        // ignore: prefer_initializing_formals
        _fechamento = fechamento;

  final BancoLocal _banco;
  final RepositorioPainel _painel;
  final RepositorioFechamento _fechamento;

  Future<ResumoDiagnostico> resumo(String competencia, Catalogo catalogo) async {
    final ano = int.parse(competencia.substring(0, 4));
    final dados = await _painel.dadosDoAno(ano);
    final guias = await _fechamento.guiasPagas(ano);
    final painel = montarPainelMensal(
      competencia: competencia,
      dadosDoAno: dados,
      catalogo: catalogo,
      periodosQuitados: {for (final g in guias) g.periodo},
    );
    final variaveis = [Variable.withString(competencia)];
    final contagens = {
      for (final l in await _banco.customSelect(
        'SELECT classificacao, COUNT(*) AS n FROM lancamentos '
        'WHERE competencia = ? GROUP BY classificacao',
        variables: variaveis,
      ).get())
        ClassificacaoLancamento.values.byName(l.read<String>('classificacao')):
            l.read<int>('n'),
    };
    final pendentes = await _banco.customSelect(
      'SELECT COUNT(*) AS n FROM lancamentos WHERE competencia = ? '
      "AND status_documento_pagador = 'pendente'",
      variables: variaveis,
    ).getSingle();
    final inss = await _banco.customSelect(
      'SELECT COUNT(*) AS n FROM pagamentos_inss WHERE competencia = ?',
      variables: variaveis,
    ).getSingle();
    String? versaoCatalogo;
    try {
      versaoCatalogo = catalogo.tabelaVigentePara(competencia).id;
    } on StateError {
      versaoCatalogo = null;
    }
    return montarResumoDiagnostico(
      competencia: competencia,
      painel: painel,
      contagemPorClassificacao: contagens,
      pendencias: PendenciasDoMes(
        recebimentosAClassificar:
            dados[competencia]?.recebimentosAClassificar ?? 0,
        documentosPendentes: pendentes.read<int>('n'),
        inssRespondido: inss.read<int>('n') > 0,
      ),
      mesFechado: (await _fechamento.fechadas(ano)).containsKey(competencia),
      versaoApp: versaoDoApp,
      versaoCatalogo: versaoCatalogo,
    );
  }
}
