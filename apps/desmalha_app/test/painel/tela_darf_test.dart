import 'dart:convert';

import 'package:desmalha_app/onboarding/repositorio_onboarding.dart';
import 'package:desmalha_app/painel/tela_darf.dart';
import 'package:desmalha_app/painel/tela_mes.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lembretes/notificacoes_falsas.dart';
import '../servicos_falsos.dart';

void main() {
  final catalogo = catalogoDoSeed();
  DadosDoMes classificado(int receita) => DadosDoMes(
    receitaTributavelCentavos: receita,
    lancamentosClassificados: 1,
  );

  PainelApurado painel(Map<String, DadosDoMes> dados, String c) =>
      montarPainelMensal(competencia: c, dadosDoAno: dados, catalogo: catalogo)
          as PainelApurado;

  late List<(Uint8List, String, String)> compartilhados;
  late List<Uri> abertas;
  setUp(() {
    compartilhados = [];
    abertas = [];
  });

  Future<void> montar(
    WidgetTester tester,
    PainelApurado p, {
    DateTime? hoje,
    bool comPerfil = true,
  }) async {
    final repo = RepositorioOnboardingMemoria();
    if (comPerfil) {
      repo.perfil = const PerfilDoApp(
        nome: 'Ana Souza',
        cpf: '52998224725',
        onboardingCompleto: true,
      );
    }
    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: TelaDarf(
          servicos: servicosFalsos(
            onboarding: controladorOnboardingFalso(repositorio: repo),
            catalogo: () async => catalogo,
          ),
          painel: p,
          relogio: () => hoje ?? DateTime(2026, 9, 24, 10),
          compartilhar: (b, n, t) async => compartilhados.add((b, n, t)),
          abrirUrl: (u) async => abertas.add(u),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tocar(WidgetTester tester, String chave) async {
    final alvo = find.byKey(Key(chave));
    await tester.ensureVisible(alvo);
    await tester.tap(alvo);
    await tester.pumpAndSettle();
  }

  testWidgets('guia do mês: campos, SEM código de barras, aviso do e-CAC', (
    tester,
  ) async {
    final p = painel({'2026-08': classificado(1000000)}, '2026-08');
    await montar(tester, p);
    expect(
      find.descendant(
        of: find.byKey(const Key('darf_valor_total')),
        matching: find.text(centavosParaExibicao(p.apuracao.valorDarfCentavos)),
      ),
      findsOneWidget,
    );
    expect(find.text('0190'), findsOneWidget);
    expect(find.text('31/08/2026'), findsOneWidget); // período de apuração
    expect(find.text('30/09/2026'), findsOneWidget); // vencimento
    expect(find.text('529.982.247-25'), findsOneWidget);
    expect(find.byKey(const Key('darf_sem_codigo')), findsOneWidget);
    expect(find.byKey(const Key('darf_linha_digitavel')), findsNothing);
    expect(find.byKey(const Key('botao_copiar_codigo')), findsNothing);
    expect(find.byKey(const Key('aviso_ecac_darf')), findsOneWidget);
    expect(find.byKey(const Key('darf_vencida')), findsNothing);
  });

  testWidgets('abrir o e-CAC e compartilhar o PDF', (tester) async {
    await montar(tester, painel({'2026-08': classificado(1000000)}, '2026-08'));
    await tocar(tester, 'botao_abrir_ecac');
    expect(abertas, [urlEcac]);

    await tocar(tester, 'botao_pdf');
    final (bytes, nome, tipo) = compartilhados.single;
    expect(nome, 'darf-0190-2026-08.pdf');
    expect(tipo, 'application/pdf');
    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
  });

  testWidgets('copiar os dados da guia', (tester) async {
    String? copiado;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiado = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    await montar(tester, painel({'2026-08': classificado(1000000)}, '2026-08'));
    await tocar(tester, 'botao_copiar_dados');
    expect(copiado, contains('DARF código 0190'));
    expect(copiado, contains('vencimento 30/09/2026'));
    expect(copiado, contains('CPF 529.982.247-25'));
  });

  testWidgets('guia vencida: SicalcWeb na tela e no PDF', (tester) async {
    await montar(
      tester,
      painel({'2026-08': classificado(1000000)}, '2026-08'),
      hoje: DateTime(2026, 10, 5),
    );
    expect(find.byKey(const Key('darf_vencida')), findsOneWidget);
    await tocar(tester, 'botao_pdf');
    expect(
      latin1.decode(compartilhados.single.$1, allowInvalid: true),
      contains('SicalcWeb'),
    );
  });

  testWidgets('no dia do vencimento ainda não está vencida', (tester) async {
    await montar(
      tester,
      painel({'2026-08': classificado(1000000)}, '2026-08'),
      hoje: DateTime(2026, 9, 30, 23),
    );
    expect(find.byKey(const Key('darf_vencida')), findsNothing);
  });

  testWidgets('sem nome e CPF: sem guia, dizendo o que falta', (tester) async {
    await montar(
      tester,
      painel({'2026-08': classificado(1000000)}, '2026-08'),
      comPerfil: false,
    );
    expect(find.byKey(const Key('sem_guia')), findsOneWidget);
    expect(find.textContaining('nome e CPF'), findsOneWidget);
    expect(find.byKey(const Key('botao_pdf')), findsNothing);
  });

  testWidgets('dezembro sem calendário de 2027: sem guia', (tester) async {
    await montar(tester, painel({'2026-12': classificado(1000000)}, '2026-12'));
    expect(
      find.textContaining('Nenhuma guia sai com data adivinhada'),
      findsOneWidget,
    );
  });

  testWidgets('a partir do Mês: "Ver o DARF" abre a guia', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: Scaffold(
          body: TelaMes(
            servicos: servicosFalsos(
              painel: PainelFalso({'2026-08': classificado(1000000)}),
              catalogo: () async => catalogo,
            ),
            relogio: () => DateTime(2026, 9, 24, 10),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tocar(tester, 'botao_ver_darf');
    expect(find.text('DARF — agosto/2026'), findsOneWidget);
    expect(find.byKey(const Key('darf_sem_codigo')), findsOneWidget);
  });
}
