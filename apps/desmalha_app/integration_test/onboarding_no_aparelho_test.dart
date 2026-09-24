/// Onboarding NO APARELHO: boas-vindas → entrar (auth falsa) → aceite com
/// os documentos ainda não publicados → seus dados → como funciona →
/// código de recuperação com Argon2id real e mestra no Keystore → lembrete
/// com o plugin real → traga seu extrato → Mês.
///
/// A permissão de notificação é concedida por adb antes (o teste não toca
/// no diálogo do sistema):
///
///   adb shell pm grant com.desmalha.app android.permission.POST_NOTIFICATIONS
///   fvm flutter test integration_test/onboarding_no_aparelho_test.dart
///
/// Com `--dart-define=CAPTURA=true`, pausa em cada tela.
library;

import 'package:desmalha_app/auth/portal_auth.dart';
import 'package:desmalha_app/auth/servico_auth.dart';
import 'package:desmalha_app/backup/chaves_backup.dart';
import 'package:desmalha_app/dados/chave_banco.dart';
import 'package:desmalha_app/lembretes/controlador_lembretes.dart';
import 'package:desmalha_app/lembretes/porta_notificacoes_locais.dart';
import 'package:desmalha_app/navegacao/abas.dart';
import 'package:desmalha_app/onboarding/repositorio_onboarding.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/auth/porta_auth_falsa.dart';
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

Future<void> _tocar(WidgetTester tester, String chave) async {
  final alvo = find.byKey(Key(chave));
  await _esperar(tester, alvo);
  await tester.ensureVisible(alvo);
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding completo no aparelho', (tester) async {
    final chaves = ChavesBackup(
      cofre: _CofrePrefixado(const CofreSeguroDoSistema()),
    );
    final repo = RepositorioOnboardingMemoria();
    final servico = ServicoAutenticacao(PortaAuthFalsa());
    final servicos = servicosFalsos(
      chavesBackup: chaves,
      backup: controladorBackupFalso(chaves: chaves),
      lembretes: ControladorLembretes(
        porta: PortaNotificacoesLocais(),
        carregarCatalogo: catalogoDoBundle,
      ),
      onboarding: controladorOnboardingFalso(
        repositorio: repo,
        // O catálogo do seed: hoje sem documento legal publicado.
        catalogo: await catalogoDoBundle(),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        navigatorKey: chaveNavegadorDoApp,
        home: PortalAuth(servico: servico, servicos: servicos),
      ),
    );
    await _marcar(tester, 'boas-vindas');
    await _tocar(tester, 'botao_entrar_boas_vindas');

    await tester.enterText(
      find.byKey(const Key('campo_email')),
      'pessoa@exemplo.com',
    );
    await _tocar(tester, 'botao_enviar_codigo');
    await tester.enterText(find.byKey(const Key('campo_codigo')), '12345678');
    await _tocar(tester, 'botao_confirmar_codigo');

    await _esperar(tester, find.byKey(const Key('progresso_onboarding')));
    await _marcar(tester, 'onb-aceite');
    expect(
      find.byKey(const Key('aviso_termos_nao_publicados')),
      findsOneWidget,
    );
    await _tocar(tester, 'botao_aceite_continuar');

    await tester.enterText(find.byKey(const Key('campo_nome')), 'Ana Souza');
    await tester.enterText(
      find.byKey(const Key('campo_cpf')),
      '529.982.247-25',
    );
    await _marcar(tester, 'onb-dados');
    await _tocar(tester, 'botao_dados_continuar');

    await _marcar(tester, 'onb-como-funciona');
    await _tocar(tester, 'botao_como_funciona_continuar');

    await _esperar(tester, find.byKey(const Key('botao_codigo_gerar')));
    await _marcar(tester, 'onb-codigo');
    await _tocar(tester, 'botao_codigo_gerar');
    await _tocar(tester, 'botao_gerar_codigo');
    final codigo = normalizarCodigoRecuperacao(
      tester
          .widget<SelectableText>(find.byKey(const Key('codigo_recuperacao')))
          .data!,
    )!;
    await _tocar(tester, 'botao_ja_anotei');
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
    await _tocar(tester, 'botao_concluir_codigo');

    await _esperar(tester, find.byKey(const Key('botao_ativar_lembrete')));
    await _marcar(tester, 'onb-lembrete');
    await _tocar(tester, 'botao_ativar_lembrete');
    expect(servicos.lembretes.permitidas, isTrue);

    await _esperar(tester, find.byKey(const Key('botao_concluir_onboarding')));
    await _marcar(tester, 'onb-extrato');
    await _tocar(tester, 'botao_concluir_onboarding');

    await _esperar(tester, find.text('Seu mês'));
    await _marcar(tester, 'mes-depois-do-onboarding');
    expect(repo.perfil!.onboardingCompleto, isTrue);
    expect(repo.perfil!.cpf, '52998224725');
    expect(await chaves.codigoConfirmado(), isTrue);
  });
}

/// Keystore real, com os campos prefixados: o teste não toca a chave de
/// backup do app instalado no mesmo emulador.
class _CofrePrefixado implements CofreSeguro {
  _CofrePrefixado(this._real);
  final CofreSeguro _real;
  static final _prefixo = 'teste_${DateTime.now().microsecondsSinceEpoch}_';
  @override
  Future<String?> ler(String campo) => _real.ler('$_prefixo$campo');
  @override
  Future<void> gravar(String campo, String valor) =>
      _real.gravar('$_prefixo$campo', valor);
}
