import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

/// A migração 1→2 dos documentos espelha a do banco local
/// (`apps/desmalha_app/test/dados/migracao_test.dart` prova a do banco com
/// os mesmos casos). Aqui ficam os casos que o golden v1 não tem.
void main() {
  List<DocumentoBackup> migrar(List<DocumentoBackup> docs) =>
      migracoesBackup[1]!(docs);

  Map<String, Object?> unico(List<DocumentoBackup> docs, String tabela) =>
      docs.singleWhere((d) => d.tabela == tabela).dados;

  test('a cadeia oficial tem 1→2 e é esta função', () {
    expect(migracoesBackup.keys, [1]);
    expect(formatoBackupAtual, 2);
  });

  test('lançamento: classificação, origem, documento e confirmação', () {
    final saida = migrar(const [
      DocumentoBackup('lancamentos', {
        'id': 'l1',
        'classificacao': 'tributavel',
        'origem_classificacao': 'regra_remetente',
        'cpf_pagador': '111',
        'criado_em': 1,
        'atualizado_em': 9,
      }),
    ]);
    expect(unico(saida, 'lancamentos'), {
      'id': 'l1',
      'classificacao': 'rendimentoPf',
      'origem_classificacao': 'regraRemetente',
      'cpf_pagador': '111',
      'status_documento_pagador': 'informado',
      'criado_em': 1,
      'atualizado_em': 9,
      'confirmada_em': 9,
    });
  });

  test('reembolso e repasse sem respostas saem com o histórico; o resto fica',
      () {
    final saida = migrar(const [
      DocumentoBackup('lancamentos',
          {'id': 'l1', 'classificacao': 'reembolso', 'criado_em': 1}),
      DocumentoBackup('lancamentos',
          {'id': 'l2', 'classificacao': 'repasse_terceiros', 'criado_em': 1}),
      DocumentoBackup('lancamentos',
          {'id': 'l3', 'classificacao': 'pessoal', 'criado_em': 1}),
      DocumentoBackup('historico_classificacao',
          {'lancamento_id': 'l2', 'de': null, 'para': 'repasse_terceiros'}),
      DocumentoBackup('historico_classificacao',
          {'lancamento_id': 'l3', 'de': 'tributavel', 'para': 'pessoal'}),
      DocumentoBackup('transacoes', {'id': 't2'}),
    ]);
    expect([for (final d in saida) '${d.tabela}:${d.dados['id'] ?? d.dados['lancamento_id']}'],
        ['lancamentos:l3', 'historico_classificacao:l3', 'transacoes:t2']);
    expect(unico(saida, 'historico_classificacao')['de'], 'rendimentoPf');
  });

  test('remetente: chave de nome ASCII-maiúscula igual à do banco; regra só '
      'onde não falta resposta', () {
    final saida = migrar(const [
      DocumentoBackup('remetentes',
          {'id': 'r1', 'nome': '  João Souza ', 'classificacao_padrao': 'tributavel'}),
      DocumentoBackup('remetentes',
          {'id': 'r2', 'nome': 'Ana', 'classificacao_padrao': 'reembolso'}),
    ]);
    final r1 = saida[0].dados;
    // UPPER(TRIM(nome)) do SQLite: só ASCII vira maiúscula.
    expect(r1['chave_nome'], 'JOãO SOUZA');
    expect(r1['regra_classificacao'], 'rendimentoPf');
    expect(r1.containsKey('classificacao_padrao'), isFalse);
    expect(saida[1].dados['regra_classificacao'], isNull);
  });

  test('apuração: destino do DARF mínimo em cada faixa', () {
    Map<String, Object?> ap(int devido, int anterior, String comp) => migrar([
          DocumentoBackup('apuracoes_mensais', {
            'id': 'a',
            'competencia': comp,
            'imposto_devido_centavos': devido,
            'imposto_diferido_anterior_centavos': anterior,
            'cenario_aplicado': 'simplificado',
            'tabela_irpf_id': 3,
          }),
        ]).single.dados;
    expect(ap(0, 0, '2026-05')['status_darf'], 'semImposto');
    expect(ap(600, 400, '2026-05')['status_darf'], 'emitido');
    expect(ap(600, 0, '2026-05')['status_darf'], 'acumulaParaProximoMes');
    expect(ap(600, 0, '2026-12')['status_darf'], 'residuoParaDirpf');
    final a = ap(600, 400, '2026-05');
    expect(a['total_para_darf_centavos'], 1000);
    expect(a['cenario_aplicado'], 'descontoSimplificado');
    expect(a['tabela_irpf_id'], '3');
  });

  test('guia: status novo e ligação com a competência da apuração', () {
    final saida = migrar(const [
      DocumentoBackup('apuracoes_mensais',
          {'id': 'ap-07', 'competencia': '2026-07', 'imposto_devido_centavos': 0}),
      DocumentoBackup('darfs', {
        'id': 'g',
        'apuracao_id': 'ap-07',
        'competencia': '2026-08',
        'status': 'pago',
      }),
    ]);
    expect(unico(saida, 'darfs'), {'id': 'g', 'competencia': '2026-08', 'status': 'paga'});
    expect(unico(saida, 'darf_competencias'),
        {'darf_id': 'g', 'competencia': '2026-07', 'apuracao_id': 'ap-07'});
  });
}
