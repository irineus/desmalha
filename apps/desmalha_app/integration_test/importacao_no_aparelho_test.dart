/// Importação de extrato NO APARELHO:
///
/// - o seletor REAL do sistema (Storage Access Framework) abre, e desistir
///   dele (o roteiro manda BACK por adb) não muda nada;
/// - o fluxo inteiro com uma fixture SINTÉTICA do gerador versionado
///   (nunca extrato real): prévia, confirmação, lista na aba, o mesmo
///   arquivo recusado de novo, e uma possível duplicata decidida à mão.
///
///   fvm flutter test integration_test/importacao_no_aparelho_test.dart
///
/// Com `--dart-define=CAPTURA=true`, pausa em cada tela.
library;

import 'dart:typed_data';

import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/dados/repositorio_importacao.dart';
import 'package:desmalha_app/importacao/controlador_importacao.dart';
import 'package:desmalha_app/importacao/seletor_arquivo_sistema.dart';
import 'package:desmalha_app/classificacao/aba_lancamentos.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../../packages/desmalha_core/test/fixtures/sinteticas/gerador.dart';
import '../test/importacao/extratos_falsos.dart';
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

Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  await _esperar(tester, alvo);
  await tester.ensureVisible(alvo);
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

/// O primeiro pedido vai ao seletor REAL; os seguintes, à fila de teste.
class _SeletorDoRoteiro implements SeletorDeArquivo {
  final fila = <ArquivoSelecionado>[];
  bool usouOSistema = false;
  bool sistemaDevolveu = false;

  @override
  Future<ArquivoSelecionado?> escolher() async {
    if (!usouOSistema) {
      usouOSistema = true;
      final r = await const SeletorDeArquivoDoSistema().escolher();
      sistemaDevolveu = true;
      return r;
    }
    return fila.removeAt(0);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('importação no aparelho', (tester) async {
    final banco = BancoLocal(NativeDatabase.memory());
    final seletor = _SeletorDoRoteiro();
    final servicos = servicosFalsos(
      importacao: RepositorioImportacao(banco),
      seletorDeArquivo: seletor,
      catalogo: catalogoDoBundle,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: Scaffold(body: AbaLancamentos(servicos: servicos)),
      ),
    );
    await _esperar(tester, find.byKey(const Key('lancamentos_vazio')));
    await _marcar(tester, 'lanc-vazio');

    // 1. Seletor real do sistema — só com o roteiro de captura, que manda
    //    BACK por adb (o teste não alcança a interface do sistema).
    await _tocar(tester, find.text('Importar extrato'));
    if (_captura) {
      await tester.tap(find.byKey(const Key('botao_escolher_arquivo')));
      await tester.pump(const Duration(seconds: 2));
      // ignore: avoid_print
      print('CAPTURA:seletor-sistema');
      for (var i = 0; i < 600 && !seletor.sistemaDevolveu; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
      expect(seletor.sistemaDevolveu, isTrue);
      expect(find.byKey(const Key('botao_escolher_arquivo')), findsOneWidget);
    } else {
      seletor.usouOSistema = true;
    }

    // 2. Fixture sintética "a" (SGML, cp1252, CRLF, 54 dias, 40 lançamentos).
    final a = gerarFixtures().firstWhere(
      (f) => f.especificacao.arquivo.startsWith('a-'),
    );
    final arquivoA = ArquivoSelecionado(
      nome: a.especificacao.arquivo,
      bytes: Uint8List.fromList(a.bytes),
    );
    seletor.fila.add(arquivoA);
    await _tocar(tester, find.byKey(const Key('botao_escolher_arquivo')));
    await _esperar(tester, find.byKey(const Key('bloco_novos')));
    await _marcar(tester, 'previa-fixture-a');
    expect(find.text('${a.transacoes.length} novos'), findsOneWidget);

    await _tocar(tester, find.byKey(const Key('botao_confirmar_importacao')));
    await _esperar(tester, find.byKey(const Key('resumo_importacao')));
    await _marcar(tester, 'importacao-concluida');
    expect(
      find.text('${a.transacoes.length} lançamentos gravados.'),
      findsOneWidget,
    );
    await _tocar(tester, find.byKey(const Key('botao_importacao_ok')));
    await _esperar(tester, find.text(a.especificacao.arquivo));
    await _marcar(tester, 'lanc-com-importacao');

    // 3. O mesmo arquivo de novo.
    seletor.fila.add(arquivoA);
    await _tocar(tester, find.byKey(const Key('botao_importar_outro')));
    await _tocar(tester, find.byKey(const Key('botao_escolher_arquivo')));
    await _esperar(tester, find.byKey(const Key('aviso_ja_importado')));
    await _marcar(tester, 'ja-importado');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 4. Possível duplicata: o primeiro lançamento da fixture reaparece com
    //    identificador diferente, na mesma conta (o mesmo banco da "a").
    final primeiro = a.transacoes.first;
    seletor.fila.add(
      ofxSintetico(
        [
          (
            data: primeiro.data,
            centavos: primeiro.valorCentavos,
            fitid: 'OUTRO-ID',
            memo: primeiro.descricao,
          ),
        ],
        nome: 'reexportado.ofx',
        banco: a.especificacao.org ?? a.especificacao.bankId,
        conta: a.especificacao.conta,
      ),
    );
    await _tocar(tester, find.byKey(const Key('botao_importar_outro')));
    await _tocar(tester, find.byKey(const Key('botao_escolher_arquivo')));
    await _esperar(tester, find.byKey(const Key('possivel_0')));
    await _marcar(tester, 'previa-possivel-duplicata');
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('botao_confirmar_importacao')),
          )
          .onPressed,
      isNull,
    );
    await _tocar(tester, find.text('Descartar'));
    await _marcar(tester, 'possivel-decidida');
    await _tocar(tester, find.byKey(const Key('botao_confirmar_importacao')));
    await _esperar(tester, find.byKey(const Key('resumo_importacao')));
    expect(find.text('1 descartado por você.'), findsOneWidget);

    final n = await banco
        .customSelect('SELECT count(*) AS n FROM transacoes')
        .getSingle();
    expect(n.read<int>('n'), a.transacoes.length);
    await banco.close();
  });
}
