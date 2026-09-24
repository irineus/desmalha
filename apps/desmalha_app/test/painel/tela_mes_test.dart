import 'package:desmalha_app/painel/controlador_painel.dart';
import 'package:desmalha_app/painel/tela_mes.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lembretes/notificacoes_falsas.dart';
import '../servicos_falsos.dart';

void main() {
  final catalogo = catalogoDoSeed();
  final hoje = DateTime(2026, 9, 24, 10);

  DadosDoMes classificado(int receita, {int aClassificar = 0}) => DadosDoMes(
    receitaTributavelCentavos: receita,
    lancamentosClassificados: 1,
    recebimentosAClassificar: aClassificar,
  );

  ApuracaoMensal motor(Map<String, int> receitas, String c) => apurarSequencia(
    entradas: [
      for (final e in receitas.entries)
        EntradaApuracao(competencia: e.key, receitaBrutaCentavos: e.value),
    ],
    tabelaPara: catalogo.tabelaVigentePara,
  ).firstWhere((a) => a.competencia == c);

  Future<void> montar(
    WidgetTester tester,
    Map<String, DadosDoMes> dados, {
    DateTime? agora,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: Scaffold(
          body: TelaMes(
            servicos: servicosFalsos(
              painel: PainelFalso(dados),
              catalogo: () async => catalogo,
            ),
            relogio: () => agora ?? hoje,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('competenciaInicial', () {
    test('até o vencimento do mês passado, abre nele', () {
      expect(competenciaInicial(DateTime(2026, 9, 24), catalogo), '2026-08');
      expect(competenciaInicial(DateTime(2026, 9, 30), catalogo), '2026-08');
    });
    test('passado o vencimento, abre no mês corrente', () {
      // Set/2026 vence 30/10; em 31/10 já passou.
      expect(competenciaInicial(DateTime(2026, 10, 31), catalogo), '2026-10');
    });
    test('sem calendário para decidir, o mês passado', () {
      expect(competenciaInicial(DateTime(2027, 2, 10), catalogo), '2027-01');
    });
  });

  testWidgets('sem lançamentos: estado vazio, nenhum imposto', (tester) async {
    await montar(tester, {});
    expect(find.text('agosto/2026'), findsOneWidget);
    expect(find.byKey(const Key('mes_sem_dados')), findsOneWidget);
    expect(find.byKey(const Key('valor_darf')), findsNothing);
    expect(
      find.text(textoMesIsento),
      findsNothing,
      reason: 'mês sem dado nunca vira isento',
    );
  });

  testWidgets('só recebimentos a classificar: "classifique", nenhum imposto', (
    tester,
  ) async {
    await montar(tester, {
      '2026-08': const DadosDoMes(recebimentosAClassificar: 7),
    });
    expect(find.byKey(const Key('mes_a_classificar')), findsOneWidget);
    expect(find.textContaining('Classifique seus lançamentos'), findsOneWidget);
    expect(find.textContaining('7 recebimentos'), findsOneWidget);
    expect(find.byKey(const Key('valor_darf')), findsNothing);
  });

  testWidgets('apurado: DARF do motor, vencimento do catálogo, pendência', (
    tester,
  ) async {
    await montar(tester, {'2026-08': classificado(1000000, aClassificar: 3)});
    final ref = motor({'2026-08': 1000000}, '2026-08');
    expect(ref.statusDarf, StatusDarf.emitido);
    expect(
      find.descendant(
        of: find.byKey(const Key('valor_darf')),
        matching: find.text(centavosParaExibicao(ref.valorDarfCentavos)),
      ),
      findsOneWidget,
    );
    expect(find.text('Vence quarta, 30/09 (código 0190).'), findsOneWidget);
    expect(find.byKey(const Key('pendencia_classificar')), findsOneWidget);
    expect(find.textContaining('3 recebimentos'), findsOneWidget);
    expect(find.byKey(const Key('aviso_deducoes')), findsOneWidget);
    expect(find.byKey(const Key('evolucao')), findsOneWidget);
  });

  testWidgets('vencimento passado: venceu, com o caminho do SicalcWeb', (
    tester,
  ) async {
    await montar(tester, {'2026-07': classificado(1000000)});
    await tester.tap(find.byKey(const Key('mes_anterior')));
    await tester.pumpAndSettle();
    expect(find.text('Venceu segunda, 31/08 (código 0190).'), findsOneWidget);
    expect(find.byKey(const Key('aviso_atraso')), findsOneWidget);
  });

  testWidgets('no dia do vencimento ainda "vence"', (tester) async {
    await montar(tester, {
      '2026-08': classificado(1000000),
    }, agora: DateTime(2026, 9, 30, 20));
    expect(find.text('Vence quarta, 30/09 (código 0190).'), findsOneWidget);
    expect(find.byKey(const Key('aviso_atraso')), findsNothing);
  });

  testWidgets('tudo pessoal: o texto do contador para mês isento', (
    tester,
  ) async {
    await montar(tester, {
      '2026-08': const DadosDoMes(lancamentosClassificados: 2),
    });
    expect(find.text(textoMesIsento), findsOneWidget);
    expect(find.byKey(const Key('valor_darf')), findsNothing);
  });

  testWidgets('abaixo do mínimo: acumula para o próximo mês', (tester) async {
    final pequena = [for (var r = 500000; r <= 900000; r += 100) r].firstWhere(
      (r) =>
          motor({'2026-08': r}, '2026-08').statusDarf ==
          StatusDarf.acumulaParaProximoMes,
    );
    await montar(tester, {'2026-08': classificado(pequena)});
    expect(find.byKey(const Key('mes_acumula')), findsOneWidget);
    expect(find.byKey(const Key('valor_darf')), findsNothing);
  });

  testWidgets('dezembro sem feriados de 2027: vencimento indisponível, '
      'nunca adivinhado', (tester) async {
    await montar(tester, {
      '2026-12': classificado(1000000),
    }, agora: DateTime(2026, 12, 20));
    // Em 20/12 abre em novembro; volta... avança para dezembro.
    await tester.tap(find.byKey(const Key('mes_seguinte')));
    await tester.pumpAndSettle();
    expect(find.text('dezembro/2026'), findsOneWidget);
    expect(find.textContaining('Vencimento indisponível'), findsOneWidget);
  });

  testWidgets('navega para trás e não passa do mês corrente', (tester) async {
    await montar(tester, {'2026-07': classificado(1000000)});
    await tester.tap(find.byKey(const Key('mes_anterior')));
    await tester.pumpAndSettle();
    expect(find.text('julho/2026'), findsOneWidget);
    expect(find.byKey(const Key('valor_darf')), findsOneWidget);
    await tester.tap(find.byKey(const Key('mes_seguinte')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mes_seguinte')));
    await tester.pumpAndSettle();
    expect(find.text('setembro/2026'), findsOneWidget);
    expect(
      find.text('mês em andamento'),
      findsNothing,
      reason: 'setembro sem dados mostra o estado vazio',
    );
    final seguinte = tester.widget<IconButton>(
      find.byKey(const Key('mes_seguinte')),
    );
    expect(seguinte.onPressed, isNull);
  });
}
