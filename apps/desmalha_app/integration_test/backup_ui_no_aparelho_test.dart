/// Ajustes > Backup NO APARELHO: desligado sem código (e o aviso no Mês),
/// confirmar o código (Argon2id real, mestra no Keystore), "Fazer backup
/// agora" e o estado "em dia". O armazenamento é o falso com as regras do
/// servidor; o servidor real é provado pelo workflow "Prova do gateway".
///
///   fvm flutter test integration_test/backup_ui_no_aparelho_test.dart
///
/// Com `--dart-define=CAPTURA=true`, pausa em cada tela.
library;

import 'package:desmalha_app/auth/porta_auth.dart';
import 'package:desmalha_app/auth/portal_auth.dart';
import 'package:desmalha_app/auth/servico_auth.dart';
import 'package:desmalha_app/backup/chaves_backup.dart';
import 'package:desmalha_app/dados/chave_banco.dart';
import 'package:desmalha_app/navegacao/abas.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/auth/porta_auth_falsa.dart';
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

  testWidgets('backup: desligado → código → fazer agora → em dia', (
    tester,
  ) async {
    // Cofre REAL (Keystore), com campos isolados deste teste.
    final cofre = _CofrePrefixado(const CofreSeguroDoSistema());
    final chaves = ChavesBackup(cofre: cofre);
    final porta = PortaAuthFalsa(
      usuarioInicial: const UsuarioAutenticado(
        id: 'uid-vitrine',
        email: 'pessoa@exemplo.com',
      ),
    );
    final servico = ServicoAutenticacao(porta);
    final servicos = servicosFalsos(
      chavesBackup: chaves,
      backup: controladorBackupFalso(chaves: chaves),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        navigatorKey: chaveNavegadorDoApp,
        home: PortalAuth(servico: servico, servicos: servicos),
      ),
    );
    await _esperar(tester, find.byKey(const Key('aviso_backup_mes')));
    await _marcar(tester, 'mes-aviso');
    expect(find.textContaining('Backup desligado'), findsOneWidget);

    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('item_backup')));
    await _marcar(tester, 'backup-desligado');
    expect(find.byKey(const Key('aviso_backup_desligado')), findsOneWidget);

    await tester.tap(find.byKey(const Key('botao_ir_codigo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao_gerar_codigo')));
    await tester.pumpAndSettle();
    final codigo = normalizarCodigoRecuperacao(
      tester
          .widget<SelectableText>(find.byKey(const Key('codigo_recuperacao')))
          .data!,
    )!;
    await tester.tap(find.byKey(const Key('botao_ja_anotei')));
    await tester.pumpAndSettle();
    final partes = codigo.split('-');
    for (var i = 0; i < 2; i++) {
      final rotulo = tester
          .widget<TextField>(find.byKey(Key('campo_grupo_$i')))
          .decoration!
          .labelText!;
      await tester.enterText(
        find.byKey(Key('campo_grupo_$i')),
        partes[int.parse(rotulo.substring(0, 1)) - 1],
      );
    }
    await tester.tap(
      find.byKey(const Key('botao_confirmar_codigo_recuperacao')),
    );
    await _esperar(tester, find.byKey(const Key('botao_concluir_codigo')));
    await tester.tap(find.byKey(const Key('botao_concluir_codigo')));
    await _esperar(tester, find.text('Fazer backup agora'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('botao_backup_agora')));
    await _esperar(tester, find.text('em dia'));
    await _marcar(tester, 'backup-em-dia');
    expect(find.text('em dia'), findsOneWidget);
    expect(find.text('nunca'), findsNothing);

    await servico.descartar();
    await porta.fechar();
  });
}

/// Keystore real, mas com os campos prefixados: o teste não toca a chave
/// de backup do app instalado no mesmo emulador.
class _CofrePrefixado implements CofreSeguro {
  _CofrePrefixado(this._real);
  final CofreSeguro _real;
  static final _prefixo = 'teste_${DateTime.now().microsecondsSinceEpoch}_';
  @override
  Future<String?> ler(String campo) => _real.ler('$_prefixo$campo');
  @override
  Future<void> gravar(String campo, String valor) =>
      _real.gravar('$_prefixo$campo', valor);
  @override
  Future<void> apagar(String campo) => _real.apagar('$_prefixo$campo');
}
