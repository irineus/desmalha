import 'package:desmalha_app/auth/porta_auth.dart';
import 'package:desmalha_app/auth/portal_auth.dart';
import 'package:desmalha_app/auth/servico_auth.dart';
import 'package:desmalha_app/onboarding/repositorio_onboarding.dart';
import 'package:desmalha_app/onboarding/telas_onboarding.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/porta_auth_falsa.dart';
import '../servicos_falsos.dart';

const _ana = '00000000-0000-4000-8000-0000000000aa';
const _beto = '00000000-0000-4000-8000-0000000000bb';

void main() {
  late RepositorioOnboardingMemoria repo;
  late LimpezaFalsa limpeza;

  setUp(() {
    repo = RepositorioOnboardingMemoria()
      ..perfil = const PerfilDoApp(
        nome: 'Ana',
        cpf: '52998224725',
        onboardingCompleto: true,
        usuarioRemotoId: _ana,
      );
    limpeza = LimpezaFalsa(repo);
  });

  /// Entra no app com a sessão de [uid] num aparelho com os dados da Ana.
  Future<ServicoAutenticacao> entrarComo(
    WidgetTester tester,
    String uid,
  ) async {
    final servico = ServicoAutenticacao(
      PortaAuthFalsa(
        usuarioInicial: UsuarioAutenticado(id: uid, email: '$uid@exemplo.com'),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: PortalAuth(
          servico: servico,
          servicos: servicosFalsos(
            onboarding: controladorOnboardingFalso(
              repositorio: repo,
              limpeza: limpeza,
              usuarioId: () => uid,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return servico;
  }

  testWidgets('a mesma conta entra direto no app', (tester) async {
    await entrarComo(tester, _ana);
    expect(find.byType(TelaDadosDeOutraConta), findsNothing);
    expect(find.text('Seu mês'), findsOneWidget);
  });

  testWidgets('outra conta: barrada ANTES do app — nada da Ana aparece', (
    tester,
  ) async {
    await entrarComo(tester, _beto);
    expect(find.byType(TelaDadosDeOutraConta), findsOneWidget);
    expect(find.text('Seu mês'), findsNothing);
    expect(find.textContaining('Ana'), findsNothing);
    expect(limpeza.chamadas, 0, reason: 'nada é apagado sem confirmação');
  });

  testWidgets('apagar exige confirmar; depois, onboarding da conta nova', (
    tester,
  ) async {
    await entrarComo(tester, _beto);
    final botao = find.byKey(const Key('botao_apagar_dados_locais'));
    expect(tester.widget<OutlinedButton>(botao).onPressed, isNull);

    await tester.tap(find.byKey(const Key('caixa_apagar_dados_locais')));
    await tester.pumpAndSettle();
    await tester.tap(botao);
    await tester.pumpAndSettle();

    expect(limpeza.chamadas, 1);
    expect(repo.perfil, isNull);
    expect(find.byType(TelaDadosDeOutraConta), findsNothing);
    expect(find.text('Passo 1 de 6'), findsOneWidget);
  });

  testWidgets('sair desta conta: volta à entrada, sem apagar nada', (
    tester,
  ) async {
    await entrarComo(tester, _beto);
    await tester.tap(find.byKey(const Key('botao_sair_outra_conta')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('campo_email')), findsOneWidget);
    expect(limpeza.chamadas, 0);
    expect(repo.perfil!.usuarioRemotoId, _ana);
  });

  testWidgets('perfil sem dono registrado: tratado como de outra conta', (
    tester,
  ) async {
    repo.perfil = const PerfilDoApp(
      nome: 'Ana',
      cpf: '52998224725',
      onboardingCompleto: true,
    );
    await entrarComo(tester, _ana);
    expect(find.byType(TelaDadosDeOutraConta), findsOneWidget);
  });

  testWidgets('aparelho sem perfil: onboarding normal, sem a tela', (
    tester,
  ) async {
    repo.perfil = null;
    await entrarComo(tester, _beto);
    expect(find.byType(TelaDadosDeOutraConta), findsNothing);
    expect(find.text('Passo 1 de 6'), findsOneWidget);
  });
}
