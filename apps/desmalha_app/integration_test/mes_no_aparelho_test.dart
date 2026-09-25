/// Aba Mês NO APARELHO, com o SQL real (Drift em memória) e o catálogo do
/// seed: os quatro estados do mês, navegando pelas competências.
///
/// - ago/2026: recebimentos importados, nenhum classificado → "classifique";
/// - jul/2026: classificados → DARF do motor, vencimento, pendência;
/// - jun/2026: só pessoais → texto do contador para mês isento;
/// - set/2026: nada → importe o extrato.
///
///   fvm flutter test integration_test/mes_no_aparelho_test.dart
///
/// Com `--dart-define=CAPTURA=true`, pausa em cada tela.
library;

import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/painel/repositorio_painel.dart';
import 'package:desmalha_app/painel/tela_mes.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/lembretes/notificacoes_falsas.dart';
import '../test/servicos_falsos.dart';

const _captura = bool.fromEnvironment('CAPTURA');

Future<void> _marcar(WidgetTester tester, String tela) async {
  await tester.pumpAndSettle();
  if (!_captura) return;
  // ignore: avoid_print
  print('CAPTURA:$tela');
  await Future<void>.delayed(const Duration(seconds: 8));
}

Future<void> _esperar(WidgetTester tester, Finder alvo) async {
  for (var i = 0; i < 300 && alvo.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('aba Mês: quatro estados', (tester) async {
    final banco = BancoLocal(NativeDatabase.memory());
    var n = 0;
    Future<void> sql(String s, [List<Object?> v = const []]) =>
        banco.customStatement(s, v);
    await sql(
      "INSERT INTO contas_bancarias (id, apelido, criado_em) VALUES ('c', 'C', 0)",
    );
    Future<String> transacao(String data, int centavos) async {
      final id = 't${n++}';
      await sql(
        'INSERT INTO transacoes (id, conta_id, data, valor_centavos, '
        "descricao_raw, criado_em) VALUES (?, 'c', ?, ?, 'PIX', 0)",
        [id, data, centavos],
      );
      return id;
    }

    Future<void> lancamento(String data, int centavos, String cls) async {
      final t = await transacao(data, centavos);
      await sql(
        'INSERT INTO lancamentos (id, transacao_id, competencia, '
        'data_recebimento, valor_centavos, classificacao, criado_em, '
        "atualizado_em, confirmada_em) VALUES (?, ?, ?, ?, ?, ?, 0, 0, 0)",
        ['l${n++}', t, data.substring(0, 7), data, centavos, cls],
      );
    }

    // jun: só pessoal. jul: R$ 10.000 tributável + 2 a classificar.
    // ago: 3 recebimentos importados, nenhum classificado. set: nada.
    await lancamento('2026-06-10', 50000, 'pessoal');
    await lancamento('2026-07-05', 600000, 'rendimentoPf');
    await lancamento('2026-07-20', 400000, 'rendimentoPf');
    await transacao('2026-07-25', 15000);
    await transacao('2026-07-26', 25000);
    for (final d in ['2026-08-03', '2026-08-10', '2026-08-17']) {
      await transacao(d, 45000);
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: Scaffold(
          body: TelaMes(
            servicos: servicosFalsos(
              painel: RepositorioPainelDrift(banco),
              catalogo: catalogoDoBundle,
            ),
            relogio: () => DateTime(2026, 9, 24, 10),
          ),
        ),
      ),
    );

    await _esperar(tester, find.byKey(const Key('mes_a_classificar')));
    await _marcar(tester, 'mes-agosto-a-classificar');
    expect(find.text('agosto/2026'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mes_anterior')));
    await _esperar(tester, find.byKey(const Key('valor_darf')));
    await _marcar(tester, 'mes-julho-apurado');
    expect(find.text('Venceu segunda, 31/08 (código 0190).'), findsOneWidget);
    expect(find.byKey(const Key('aviso_atraso')), findsOneWidget);
    expect(find.textContaining('2 recebimentos'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('evolucao')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await _marcar(tester, 'mes-julho-evolucao');

    await tester.tap(find.byKey(const Key('mes_anterior')));
    await _esperar(tester, find.byKey(const Key('mes_isento')));
    await _marcar(tester, 'mes-junho-isento');
    expect(find.text(textoMesIsento), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('mes_seguinte')));
      await tester.pumpAndSettle();
    }
    await _esperar(tester, find.byKey(const Key('mes_sem_dados')));
    await _marcar(tester, 'mes-setembro-sem-dados');
    expect(find.text('setembro/2026'), findsOneWidget);
    await banco.close();
  });
}
