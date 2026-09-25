/// "Os enums do banco são os do motor" (cadeia 2, decisão 6 do owner).
///
/// Lê `esquema.drift` como texto, extrai cada `CHECK (coluna IN (...))` por
/// tabela e compara com os `.name` do enum do desmalha_core que a coluna
/// grava. Coluna de estado nova sem par aqui reprova, e valor que só existe
/// de um dos lados também: a grafia é uma só, do cenário table-driven até a
/// coluna.
library;

import 'dart:io';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tabela.coluna → o enum do core que ela grava.
final Map<String, List<Enum>> _colunasDeEstado = {
  'remetentes.regra_classificacao': ClassificacaoLancamento.values,
  'apuracoes_mensais.status': StatusApuracao.values,
  'apuracoes_mensais.cenario_aplicado': CenarioVencedor.values,
  'apuracoes_mensais.status_darf': StatusDarf.values,
  'lancamentos.classificacao': ClassificacaoLancamento.values,
  'lancamentos.comprovante_titular': TitularComprovante.values,
  'lancamentos.status_documento_pagador': StatusDocumentoPagador.values,
  'lancamentos.origem_classificacao': OrigemClassificacao.values,
  'despesas_livro_caixa.forma_pagamento': FormaPagamentoDespesa.values,
  'pagamentos_inss.situacao': SituacaoInss.values,
  'darfs.status': StatusGuiaDarf.values,
};

/// CHECKs de lista que não são estado fiscal (origem técnica, catálogo de
/// documentos, estado da prévia...). Declarados para que uma coluna nova
/// tenha de escolher explicitamente de que lado fica.
const Set<String> _listasQueNaoSaoDoMotor = {
  'aceites_termos_local.documento',
  'contas_bancarias.origem',
  'importacoes.formato',
  'importacoes.status',
  'transacoes.contraparte_tipo',
  'notificacoes_locais.tipo',
  'notificacoes_locais.status',
  'backup_estado.resultado',
  'auditoria.acao',
};

/// Tabela.coluna → valores do `CHECK (coluna IN (...))` no `.drift`.
Map<String, Set<String>> checksDeLista(String drift) {
  final semComentario =
      drift.split('\n').map((l) => l.replaceFirst(RegExp(r'--.*'), '')).join('\n');
  final resultado = <String, Set<String>>{};
  final tabela = RegExp(r'CREATE TABLE (\w+) \((.*?)\) AS \w+;', dotAll: true);
  final check = RegExp(r"CHECK\s*\((\w+)\s+IN\s*\(([^)]*)\)\)");
  for (final t in tabela.allMatches(semComentario)) {
    for (final c in check.allMatches(t.group(2)!)) {
      final valores = RegExp("'([^']*)'")
          .allMatches(c.group(2)!)
          .map((v) => v.group(1)!)
          .toSet();
      if (valores.isEmpty) continue; // CHECK (x IN (0, 1)): não é enum
      resultado['${t.group(1)}.${c.group(1)}'] = valores;
    }
  }
  return resultado;
}

void main() {
  final checks = checksDeLista(
    File('lib/dados/esquema.drift').readAsStringSync(),
  );

  test('a leitura do .drift acha os CHECKs (âncora contra vacuidade)', () {
    expect(checks.length, greaterThanOrEqualTo(_colunasDeEstado.length));
    expect(checks['lancamentos.classificacao'], isNotNull);
  });

  for (final MapEntry(key: coluna, value: valores) in _colunasDeEstado.entries) {
    test('$coluna = ${valores.first.runtimeType}.values', () {
      expect(checks[coluna], {for (final v in valores) v.name},
          reason: 'o CHECK de $coluna diverge do enum do motor');
    });
  }

  test('toda lista de CHECK está classificada: do motor ou declaradamente não',
      () {
    final soltas = checks.keys.toSet()
      ..removeAll(_colunasDeEstado.keys)
      ..removeAll(_listasQueNaoSaoDoMotor);
    expect(soltas, isEmpty,
        reason: 'coluna de lista nova: ligue a um enum do desmalha_core ou '
            'declare em _listasQueNaoSaoDoMotor');
  });
}
