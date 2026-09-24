import 'dart:io';

import 'package:desmalha_app/tema/componentes.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:desmalha_app/tema/tipografia.dart';
import 'package:desmalha_app/tema/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _noTema(Widget filho) => MaterialApp(
  theme: temaDesmalha(),
  home: Scaffold(body: Center(child: filho)),
);

void main() {
  final tema = temaDesmalha();

  group('regras de aplicação do sistema visual', () {
    test('azul-obrigação NÃO está no ColorScheme — nenhum componente do '
        'Material o pega para ênfase, link ou foco', () {
      final e = tema.colorScheme;
      final usadas = [
        e.primary, e.onPrimary, e.primaryContainer, e.onPrimaryContainer,
        e.secondary, e.onSecondary, e.secondaryContainer,
        e.onSecondaryContainer, e.tertiary, e.onTertiary, e.surface,
        e.onSurface, e.onSurfaceVariant, e.outline, e.outlineVariant,
        e.inversePrimary, e.surfaceTint,
      ];
      expect(usadas, isNot(contains(CoresDesmalha.obrigacao)));
      expect(usadas, isNot(contains(CoresDesmalha.obrigacaoFundo)));
    });

    test('vermelho é só o de falha, no papel de erro', () {
      expect(tema.colorScheme.error, CoresDesmalha.falha);
      expect(tema.colorScheme.primary, isNot(CoresDesmalha.falha));
    });

    test('a voz fiscal é a Plex Mono, com dígitos tabulares', () {
      final f = TipografiaFiscal.padrao;
      for (final estilo in [
        f.valorDestaque, f.valor, f.valorLinha, f.dado, f.rotulo,
      ]) {
        expect(estilo.fontFamily, FamiliasDesmalha.plexMono);
        expect(estilo.fontFeatures, contains(const FontFeature.tabularFigures()));
      }
      expect(tema.extension<TipografiaFiscal>(), isNotNull);
    });

    test('títulos em Fraunces, interface em Karla — e o peso move o eixo '
        'wght da fonte variável', () {
      final t = tema.textTheme;
      expect(t.headlineMedium!.fontFamily, FamiliasDesmalha.fraunces);
      expect(t.bodyMedium!.fontFamily, FamiliasDesmalha.karla);
      expect(t.headlineMedium!.fontVariations,
          contains(const FontVariation('wght', 600)));
      expect(t.titleLarge!.fontVariations,
          contains(const FontVariation('wght', 600)));
    });

    testWidgets('botão primário tem 48px de área de toque, raio md e é sálvia',
        (tester) async {
      await tester.pumpWidget(
        _noTema(FilledButton(onPressed: () {}, child: const Text('Gerar DARF'))),
      );
      final tamanho = tester.getSize(find.byType(FilledButton));
      expect(tamanho.height, greaterThanOrEqualTo(48));
      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, CoresDesmalha.salvia);
      expect(
        (material.shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(RaiosDesmalha.medio),
      );
    });
  });

  group('componentes', () {
    testWidgets('ValorEmReais recebe centavos int e escreve em Plex Mono, à '
        'direita', (tester) async {
      await tester.pumpWidget(_noTema(const ValorEmReais(175786)));
      final texto = tester.widget<Text>(find.byType(Text));
      expect(texto.data, r'R$ 1.757,86');
      expect(texto.textAlign, TextAlign.right);
      expect(texto.style!.fontFamily, FamiliasDesmalha.plexMono);
    });

    testWidgets('ValorEmReais sem símbolo para linha de apuração',
        (tester) async {
      await tester.pumpWidget(
        _noTema(const ValorEmReais(965041, semSimbolo: true)),
      );
      expect(find.text('9.650,41'), findsOneWidget);
    });

    testWidgets('selo de pendência é azul e tem texto; o de falha é o único '
        'vermelho', (tester) async {
      await tester.pumpWidget(_noTema(const Column(children: [
        Selo('falta CPF', tipo: TipoSelo.obrigacao),
        Selo('vencido', tipo: TipoSelo.falha),
      ])));
      Color corDe(String t) =>
          tester.widget<Text>(find.text(t)).style!.color!;
      expect(corDe('falta CPF'), CoresDesmalha.obrigacao);
      expect(corDe('vencido'), CoresDesmalha.falha);
    });

    testWidgets('estado vazio traz a ação quando há uma', (tester) async {
      var tocou = false;
      await tester.pumpWidget(_noTema(EstadoVazio(
        mensagem: 'Nenhuma despesa em agosto.',
        rotuloAcao: 'Adicionar despesa',
        aoAgir: () => tocou = true,
      )));
      await tester.tap(find.text('Adicionar despesa'));
      expect(tocou, isTrue);
    });
  });

  group('fontes embarcadas', () {
    // Declaradas no pubspec, presentes em disco, licença ao lado, e
    // carregáveis — fonte que falta vira texto na fonte do sistema, em
    // silêncio, e a "voz fiscal" deixa de existir.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final assets = RegExp(r'- asset: (assets/fonts/[^\s]+)')
        .allMatches(pubspec)
        .map((m) => m.group(1)!)
        .toList();

    test('as cinco fontes estão declaradas e existem', () {
      expect(assets, hasLength(5));
      for (final a in assets) {
        expect(File(a).existsSync(), isTrue, reason: a);
      }
    });

    test('cada família tem a licença OFL versionada', () {
      for (final f in ['Fraunces', 'Karla', 'IBMPlexMono']) {
        final licenca = File('assets/fonts/OFL-$f.txt');
        expect(licenca.readAsStringSync(),
            contains('SIL Open Font License'), reason: f);
      }
    });

    testWidgets('os arquivos carregam como fonte', (tester) async {
      for (final a in assets) {
        final dados = await rootBundle.load(a);
        final carregador = FontLoader('teste-$a')
          ..addFont(Future.value(dados));
        await carregador.load();
      }
    });
  });
}
