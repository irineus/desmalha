@TestOn('vm')
library;

import 'dart:io';

import 'package:desmalha_app/auth/estado_auth.dart';
import 'package:desmalha_app/auth/porta_auth.dart';
import 'package:desmalha_app/auth/portal_auth.dart';
import 'package:desmalha_app/auth/servico_auth.dart';
import 'package:desmalha_app/conta/porta_exclusao_conta.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/porta_auth_falsa.dart';
import '../servicos_falsos.dart';
import 'porta_exclusao_falsa.dart';

void main() {
  group('tela — Ajustes > Sua conta > Excluir minha conta', () {
    late PortaAuthFalsa porta;
    late ServicoAutenticacao servico;
    late PortaExclusaoFalsa exclusao;

    setUp(() {
      porta = PortaAuthFalsa(
        usuarioInicial: const UsuarioAutenticado(
          id: 'uid-teste',
          email: 'pessoa@exemplo.com',
        ),
      );
      servico = ServicoAutenticacao(porta);
      exclusao = PortaExclusaoFalsa();
    });

    tearDown(() async {
      await servico.descartar();
      await porta.fechar();
    });

    Future<void> ateATelaDeExclusao(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: temaDesmalha(),
          home: PortalAuth(
          servico: servico,
          servicos: servicosFalsos(exclusao: exclusao),
        ),
        ),
      );
      await tester.tap(find.text('Ajustes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sua conta'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('botao_excluir_conta')));
      await tester.tap(find.byKey(const Key('botao_excluir_conta')));
      await tester.pumpAndSettle();
    }

    Future<void> confirmar(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(const Key('confirmo_exclusao')));
      await tester.tap(find.byKey(const Key('confirmo_exclusao')));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const Key('botao_confirmar_exclusao')),
      );
      await tester.tap(find.byKey(const Key('botao_confirmar_exclusao')));
      await tester.pumpAndSettle();
    }

    testWidgets('diz ANTES o que some, o que fica e que é irreversível', (
      tester,
    ) async {
      await ateATelaDeExclusao(tester);
      expect(find.textContaining('irreversível'), findsOneWidget);
      expect(find.textContaining(PrazosExclusao.arquivos), findsOneWidget);
      expect(find.textContaining(PrazosExclusao.conta), findsOneWidget);
      expect(find.textContaining(PrazosExclusao.aceite), findsOneWidget);
      expect(find.textContaining('desinstale o aplicativo'), findsOneWidget);
      expect(find.textContaining('exporte antes'), findsOneWidget);
    });

    testWidgets('sem marcar a confirmação, o botão não executa nada', (
      tester,
    ) async {
      await ateATelaDeExclusao(tester);
      await tester.ensureVisible(
        find.byKey(const Key('botao_confirmar_exclusao')),
      );
      await tester.tap(find.byKey(const Key('botao_confirmar_exclusao')));
      await tester.pumpAndSettle();
      expect(exclusao.chamadas, 0);
    });

    testWidgets('falha do servidor: mostra o motivo e a conta SEGUE aberta', (
      tester,
    ) async {
      await ateATelaDeExclusao(tester);
      exclusao.falhaProgramada = const FalhaExclusaoConta(
        'Não foi possível concluir a exclusão agora. Nada foi dado como '
        'excluído.',
      );
      await confirmar(tester);

      expect(exclusao.chamadas, 1);
      expect(find.byKey(const Key('erro_exclusao')), findsOneWidget);
      expect(
        find.textContaining('Nada foi dado como excluído'),
        findsOneWidget,
      );
      expect(servico.estado, isA<Autenticado>());
      expect(porta.chamadas, isNot(contains('sair')));
      expect(find.byKey(const Key('aviso_conta_excluida')), findsNothing);
    });

    testWidgets(
      'confirmada pelo servidor: sessão derrubada e volta à entrada',
      (tester) async {
        await ateATelaDeExclusao(tester);
        await confirmar(tester);

        expect(exclusao.chamadas, 1);
        expect(porta.chamadas, contains('sair'));
        expect(find.byKey(const Key('campo_email')), findsOneWidget);
        expect(find.byKey(const Key('aviso_conta_excluida')), findsOneWidget);
      },
    );

    testWidgets('mesmo com o logout recusado (conta banida), volta à entrada', (
      tester,
    ) async {
      await ateATelaDeExclusao(tester);
      porta.falhaProgramada = const FalhaAuth(
        MotivoFalhaAuth.naoAutenticado,
        'Sua sessão terminou.',
      );
      await confirmar(tester);
      expect(find.byKey(const Key('campo_email')), findsOneWidget);
    });
  });

  group('os prazos são os mesmos da página web de exclusão', () {
    test('PrazosExclusao == PRAZOS de pagina.ts', () {
      final ts = File(
        '../../supabase/functions/_compartilhado/pagina.ts',
      ).readAsStringSync();
      String prazo(String chave) =>
          RegExp('$chave:\\s*"([^"]+)"').firstMatch(ts)!.group(1)!;
      expect(PrazosExclusao.arquivos, prazo('arquivos'));
      expect(PrazosExclusao.conta, prazo('conta'));
      expect(PrazosExclusao.aceite, prazo('aceite'));
    });
  });
}
