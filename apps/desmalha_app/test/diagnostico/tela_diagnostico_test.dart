import 'dart:convert';
import 'dart:typed_data';

import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/diagnostico/repositorio_diagnostico.dart';
import 'package:desmalha_app/diagnostico/tela_diagnostico.dart';
import 'package:desmalha_app/painel/repositorio_fechamento.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lembretes/notificacoes_falsas.dart';
import '../servicos_falsos.dart';

void main() {
  late BancoLocal banco;
  setUp(() => banco = BancoLocal(NativeDatabase.memory()));
  tearDown(() => banco.close());

  testWidgets('o resumo mostra o mês em números e NÃO leva nome, CPF nem '
      'descrição; compartilha o que mostrou', (tester) async {
    await tester.runAsync(() async {
      await banco.customStatement(
        "INSERT INTO contas_bancarias (id, apelido, criado_em) "
        "VALUES ('c', 'Conta da Ana', 0)",
      );
      await banco.customStatement(
        "INSERT INTO transacoes (id, conta_id, data, valor_centavos, "
        "descricao_raw, criado_em) VALUES ('t1', 'c', '2026-08-10', 600000, "
        "'PIX RECEBIDO ANA SOUZA 52998224725', 0)",
      );
      await banco.customStatement(
        'INSERT INTO lancamentos (id, transacao_id, competencia, '
        'data_recebimento, valor_centavos, classificacao, cpf_pagador, '
        'nome_pagador, status_documento_pagador, criado_em, atualizado_em, '
        "confirmada_em) VALUES ('l1', 't1', '2026-08', '2026-08-10', 600000, "
        "'rendimentoPf', '52998224725', 'Ana Souza', 'informado', 0, 0, 0)",
      );
    });
    final painel = PainelFalso({
      '2026-08': const DadosDoMes(
        receitaTributavelCentavos: 600000,
        lancamentosClassificados: 1,
      ),
    });
    final compartilhados = <(Uint8List, String, String)>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: TelaDiagnostico(
          servicos: servicosFalsos(
            catalogo: () async => catalogoDoSeed(),
            diagnostico: RepositorioDiagnostico(
              banco,
              painel: painel,
              fechamento: RepositorioFechamento(banco),
            ),
          ),
          hoje: () => DateTime(2026, 8, 20),
          compartilhar: (b, n, t) async => compartilhados.add((b, n, t)),
        ),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }

    final mostrado = tester
        .widget<SelectableText>(find.byKey(const Key('conteudo_diagnostico')))
        .data!;
    for (final pessoal in ['Ana', 'ANA', '52998224725', 'PIX', 'Conta da']) {
      expect(mostrado, isNot(contains(pessoal)), reason: pessoal);
    }
    final json = jsonDecode(mostrado) as Map<String, Object?>;
    expect((json['lancamentosPorClassificacao']! as Map)['rendimentoPf'], 1);
    expect((json['apuracao']! as Map)['impostoDevidoCentavos'], 39454);

    await tester.ensureVisible(
      find.byKey(const Key('botao_compartilhar_diagnostico')),
    );
    await tester.tap(find.byKey(const Key('botao_compartilhar_diagnostico')));
    await tester.pump();
    expect(utf8.decode(compartilhados.single.$1), mostrado,
        reason: 'sai exatamente o que a pessoa viu');
    expect(compartilhados.single.$2, 'diagnostico-desmalha-2026-08.json');
  });
}
