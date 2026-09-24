/// Seletor REAL do sistema, duas vezes seguidas, NO APARELHO: entre as duas
/// aberturas o roteiro de captura cria um .ofx NOVO em Download (com data
/// antiga, como fica o arquivo copiado do PC pelo cabo). A segunda abertura
/// precisa mostrar o arquivo novo — foi o que falhou no S23 do owner com o
/// seletor abrindo em "Recentes".
///
/// Só com o roteiro (`--dart-define=CAPTURA=true`): o teste não alcança a
/// interface do sistema; o roteiro fotografa o seletor e o fecha.
library;

import 'package:desmalha_app/importacao/controlador_importacao.dart';
import 'package:desmalha_app/importacao/seletor_arquivo_sistema.dart';
import 'package:desmalha_app/importacao/tela_importacao.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/servicos_falsos.dart';

const _captura = bool.fromEnvironment('CAPTURA');

/// Conta quantas vezes o seletor do sistema devolveu.
class _SeletorContado implements SeletorDeArquivo {
  int devolvidos = 0;

  @override
  Future<ArquivoSelecionado?> escolher() async {
    final r = await const SeletorDeArquivoDoSistema().escolher();
    devolvidos++;
    return r;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('seletor enxerga o .ofx que acabou de chegar', (tester) async {
    if (!_captura) return;
    final seletor = _SeletorContado();
    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: TelaImportacao(
          servicos: servicosFalsos(seletorDeArquivo: seletor),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final (i, marca) in ['antes', 'depois'].indexed) {
      await tester.tap(find.byKey(const Key('botao_escolher_arquivo')));
      await tester.pump(const Duration(seconds: 3));
      // ignore: avoid_print
      print('CAPTURA:$marca-sistema');
      for (var t = 0; t < 600 && seletor.devolvidos <= i; t++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
      expect(seletor.devolvidos, i + 1);
    }
  });
}
