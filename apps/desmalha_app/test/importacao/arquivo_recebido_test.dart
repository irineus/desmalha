import 'dart:convert';
import 'dart:typed_data';

import 'package:desmalha_app/auth/porta_auth.dart';
import 'package:desmalha_app/auth/portal_auth.dart';
import 'package:desmalha_app/auth/servico_auth.dart';
import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/dados/repositorio_importacao.dart';
import 'package:desmalha_app/importacao/arquivo_recebido.dart';
import 'package:desmalha_app/importacao/tela_importacao.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/porta_auth_falsa.dart';
import '../servicos_falsos.dart';
import 'extratos_falsos.dart';

void main() {
  group('recebimentoDoCanal', () {
    test('nome + bytes vira arquivo', () {
      final bytes = Uint8List.fromList(utf8.encode('OFXHEADER:100'));
      final r = recebimentoDoCanal({'nome': 'agosto.ofx', 'bytes': bytes})!;
      expect(r.arquivo!.nome, 'agosto.ofx');
      expect(r.arquivo!.bytes, bytes);
      expect(r.erro, isNull);
    });

    test('grande e ilegível viram falha com o nome e o motivo', () {
      expect(
        recebimentoDoCanal({'nome': 'filme.mp4', 'erro': 'grande'})!.erro,
        allOf(contains('filme.mp4'), contains('20 MB')),
      );
      expect(
        recebimentoDoCanal({'nome': 'x.ofx', 'erro': 'ilegivel'})!.erro,
        contains('Não foi possível ler "x.ofx"'),
      );
    });

    test('nada reconhecível: ignora', () {
      expect(recebimentoDoCanal(null), isNull);
      expect(recebimentoDoCanal('texto'), isNull);
      expect(recebimentoDoCanal({'nome': 'sem bytes'}), isNull);
    });
  });

  group('Compartilhar → Desmalha', () {
    late BancoLocal banco;
    late ValueNotifier<RecebimentoDeArquivo?> recebido;

    setUp(() {
      banco = BancoLocal(NativeDatabase.memory());
      recebido = ValueNotifier(null);
    });
    tearDown(() => banco.close());

    Future<void> assentar(WidgetTester tester) async {
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    Future<ServicoAutenticacao> montar(
      WidgetTester tester, {
      bool logado = true,
    }) async {
      final servico = ServicoAutenticacao(
        PortaAuthFalsa(
          usuarioInicial: logado
              ? const UsuarioAutenticado(
                  id: '00000000-0000-4000-8000-00000000000a',
                  email: 'pessoa@exemplo.com',
                )
              : null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: temaDesmalha(),
          home: PortalAuth(
            servico: servico,
            servicos: servicosFalsos(
              importacao: RepositorioImportacao(banco),
              arquivoRecebido: recebido,
            ),
          ),
        ),
      );
      await assentar(tester);
      return servico;
    }

    RecebimentoDeArquivo ofx() => RecebimentoDeArquivo.arquivo(
      ofxSintetico([pixAna, pixBruno], nome: 'compartilhado.ofx'),
    );

    testWidgets('com o app aberto: vai direto para a prévia do arquivo', (
      tester,
    ) async {
      await montar(tester);
      expect(find.byType(TelaImportacao), findsNothing);
      recebido.value = ofx();
      await assentar(tester);
      expect(find.byType(TelaImportacao), findsOneWidget);
      expect(find.text('compartilhado.ofx'), findsOneWidget);
      expect(find.text('2 novos'), findsOneWidget);
      expect(recebido.value, isNull, reason: 'consumido: não reabre');
    });

    testWidgets('abertura a frio: o arquivo que chegou antes abre ao entrar', (
      tester,
    ) async {
      recebido.value = ofx();
      await montar(tester);
      expect(find.byType(TelaImportacao), findsOneWidget);
      expect(find.text('2 novos'), findsOneWidget);
    });

    testWidgets('sem login: o arquivo espera; não abre por cima da entrada', (
      tester,
    ) async {
      recebido.value = ofx();
      await montar(tester, logado: false);
      expect(find.byType(TelaImportacao), findsNothing);
      expect(recebido.value, isNotNull, reason: 'guardado para depois');
    });

    testWidgets('arquivo ilegível: o motivo na tela e o seletor à mão', (
      tester,
    ) async {
      await montar(tester);
      recebido.value = const RecebimentoDeArquivo.falha(
        'Não foi possível ler.',
      );
      await assentar(tester);
      expect(find.text('Não foi possível ler.'), findsOneWidget);
      expect(find.text('Escolher outro arquivo'), findsOneWidget);
    });
  });
}
