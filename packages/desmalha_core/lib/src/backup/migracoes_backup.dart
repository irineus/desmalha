/// Migrações do formato lógico do backup — funções PURAS sobre os
/// documentos, aplicadas por `lerPayload` antes de qualquer toque no banco
/// (regra 3 do versionamento).
///
/// Cada migração espelha o passo do banco local de mesmo número
/// (`BancoLocal._migrarV1ParaV2` no app): um backup gravado antes do passo
/// precisa chegar ao banco com o mesmo formato que o próprio banco teria
/// chegado. O golden de cada formato anterior prova isso contra valores
/// escritos à mão (`esperado_atual.json`), não contra esta função.
library;

import 'payload_backup.dart';

/// Formato 1 → 2 (schema local v2, cadeia 2, 25/09/2026).
///
/// - Estados passam aos `.name` dos enums do desmalha_core.
/// - Reembolso/repasse do formato 1 não guardavam o titular do comprovante
///   nem a essencialidade, que o formato 2 exige: o lançamento (e o seu
///   histórico) sai, e a transação volta à fila para ser classificada com as
///   perguntas. Chutar a resposta seria decidir a tributação pelo usuário.
/// - A guia deixa de apontar para UMA apuração: nasce a linha de
///   `darf_competencias`.
List<DocumentoBackup> migrarBackup1Para2(List<DocumentoBackup> documentos) {
  const semRespostas = {'reembolso', 'repasse_terceiros'};
  final lancamentosQueSaem = {
    for (final d in documentos)
      if (d.tabela == 'lancamentos' && semRespostas.contains(d.dados['classificacao']))
        d.dados['id'],
  };
  final competenciaDaApuracao = {
    for (final d in documentos)
      if (d.tabela == 'apuracoes_mensais') d.dados['id']: d.dados['competencia'],
  };

  final saida = <DocumentoBackup>[];
  for (final d in documentos) {
    final dados = Map<String, Object?>.of(d.dados);
    switch (d.tabela) {
      case 'lancamentos':
        if (lancamentosQueSaem.contains(dados['id'])) continue;
        _mapear(dados, 'classificacao', _classificacao);
        _mapear(dados, 'origem_classificacao', _origem);
        dados['status_documento_pagador'] =
            dados['cpf_pagador'] != null ? 'informado' : 'naoExigido';
        // No formato 1 toda classificação gravada foi um toque do usuário.
        dados['confirmada_em'] = dados['atualizado_em'] ?? dados['criado_em'];
      case 'historico_classificacao':
        if (lancamentosQueSaem.contains(dados['lancamento_id'])) continue;
        _mapear(dados, 'de', _classificacao);
        _mapear(dados, 'para', _classificacao);
      case 'remetentes':
        final nome = dados['nome'];
        if (nome is String) dados['chave_nome'] = _maiusculaAscii(nome.trim());
        final padrao = dados.remove('classificacao_padrao');
        dados['regra_classificacao'] = switch (padrao) {
          'tributavel' => 'rendimentoPf',
          'pessoal' => 'pessoal',
          _ => null,
        };
      case 'apuracoes_mensais':
        _mapear(dados, 'cenario_aplicado', _cenario);
        final tabela = dados['tabela_irpf_id'];
        if (tabela is int) dados['tabela_irpf_id'] = '$tabela';
        final devido = dados['imposto_devido_centavos'];
        if (devido is int) {
          final anterior = dados['imposto_diferido_anterior_centavos'];
          final total = devido + (anterior is int ? anterior : 0);
          dados['total_para_darf_centavos'] = total;
          dados['status_darf'] = _statusDarf(total, dados['competencia']);
        }
      case 'darfs':
        _mapear(dados, 'status', _statusGuia);
        final apuracao = dados.remove('apuracao_id');
        saida.add(DocumentoBackup('darfs', dados));
        if (apuracao != null) {
          saida.add(DocumentoBackup('darf_competencias', {
            'darf_id': dados['id'],
            'competencia': competenciaDaApuracao[apuracao] ?? dados['competencia'],
            'apuracao_id': apuracao,
          }));
        }
        continue;
    }
    saida.add(DocumentoBackup(d.tabela, dados));
  }
  return saida;
}

void _mapear(
  Map<String, Object?> dados,
  String coluna,
  Map<String, String> de,
) {
  final v = dados[coluna];
  if (v is String && de.containsKey(v)) dados[coluna] = de[v];
}

const _classificacao = {
  'tributavel': 'rendimentoPf',
  'repasse_terceiros': 'repasse',
};
const _origem = {
  'sugestao_aceita': 'sugestaoAceita',
  'regra_remetente': 'regraRemetente',
};
const _cenario = {
  'real': 'deducoesReais',
  'simplificado': 'descontoSimplificado',
};
const _statusGuia = {
  'gerado': 'gerada',
  'vencido': 'gerada', // "vencida" deixou de ser estado gravado
  'pago': 'paga',
  'cancelado': 'cancelada',
};

/// A regra do DARF mínimo do motor (Lei 9.430/1996, art. 68), sobre o que o
/// formato 1 já gravava.
String _statusDarf(int total, Object? competencia) {
  if (total == 0) return 'semImposto';
  if (total >= 1000) return 'emitido';
  if (competencia is String && competencia.endsWith('-12')) {
    return 'residuoParaDirpf';
  }
  return 'acumulaParaProximoMes';
}

/// O `UPPER(TRIM(nome))` da migração do banco: o UPPER do SQLite só toca
/// ASCII, e as duas migrações precisam produzir a mesma chave. A chave
/// definitiva (normalização do desmalha_core) é recalculada pela
/// classificação.
String _maiusculaAscii(String s) => String.fromCharCodes([
      for (final c in s.codeUnits) c >= 0x61 && c <= 0x7a ? c - 0x20 : c,
    ]);
