/// "Compartilhar → Desmalha" NO APARELHO, pelo caminho nativo real: com o
/// app aberto e logado, o roteiro de captura manda por adb um ACTION_SEND
/// apontando para um OFX SINTÉTICO; o MainActivity.kt recebe, o canal
/// entrega ao Dart e a importação abre.
///
/// Limite medido (24/09/2026): o adb (usuário shell) não consegue conceder
/// ao app a leitura do arquivo — o Android exige que quem compartilha tenha
/// o acesso (o Meus Arquivos tem, pelo provedor dele). Aqui a leitura cai no
/// caminho de falha, e a tela abre dizendo o motivo: o que se prova é o
/// encanamento intent → Kotlin → canal → tela, e a falha honesta. A leitura
/// com permissão de verdade é conferida no aparelho, pelo Meus Arquivos.
///
/// Só com o roteiro (`--dart-define=CAPTURA=true`), que envia o intent.
library;

import 'package:desmalha_app/auth/porta_auth.dart';
import 'package:desmalha_app/auth/portal_auth.dart';
import 'package:desmalha_app/auth/servico_auth.dart';
import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/dados/repositorio_importacao.dart';
import 'package:desmalha_app/importacao/arquivo_recebido.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/auth/porta_auth_falsa.dart';
import '../test/servicos_falsos.dart';

const _captura = bool.fromEnvironment('CAPTURA');

Future<void> _esperar(WidgetTester tester, Finder alvo) async {
  for (var i = 0; i < 600 && alvo.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('arquivo compartilhado abre a prévia', (tester) async {
    if (!_captura) return;
    final recebido = ValueNotifier<RecebimentoDeArquivo?>(null);
    await ArquivoRecebidoDoSistema(recebido).iniciar();
    final banco = BancoLocal(NativeDatabase.memory());
    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: PortalAuth(
          servico: ServicoAutenticacao(
            PortaAuthFalsa(
              usuarioInicial: const UsuarioAutenticado(
                id: '00000000-0000-4000-8000-00000000000a',
                email: 'pessoa@exemplo.com',
              ),
            ),
          ),
          servicos: servicosFalsos(
            importacao: RepositorioImportacao(banco),
            arquivoRecebido: recebido,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('CAPTURA:enviar-sistema');
    // A aba Mês também tem um botão "Importar extrato": espera pela TELA.
    await _esperar(tester, find.textContaining('que o outro app enviou'));
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('CAPTURA:importacao-aberta');
    await Future<void>.delayed(const Duration(seconds: 8));
    expect(find.widgetWithText(AppBar, 'Importar extrato'), findsOneWidget);
    expect(
      find.textContaining('que o outro app enviou'),
      findsOneWidget,
      reason: 'sem a permissão do remetente, a falha é dita na tela',
    );
    await banco.close();
  });
}
