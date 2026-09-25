import 'dart:math';

import 'package:desmalha_app/auth/porta_auth.dart';
import 'package:desmalha_app/auth/portal_auth.dart';
import 'package:desmalha_app/auth/servico_auth.dart';
import 'package:desmalha_app/backup/chaves_backup.dart';
import 'package:desmalha_app/backup/porta_armazenamento_backup.dart';
import 'package:desmalha_app/onboarding/controlador_onboarding.dart';
import 'package:desmalha_app/onboarding/porta_aceite.dart';
import 'package:desmalha_app/onboarding/repositorio_onboarding.dart';
import 'package:desmalha_app/onboarding/telas_onboarding.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../auth/porta_auth_falsa.dart';
import '../backup/armazenamento_falso.dart';
import '../lembretes/notificacoes_falsas.dart';
import '../servicos_falsos.dart';
import 'documentos_falsos.dart';

/// Confirma o código sem o Argon2id de 64 MiB (coberto em
/// chaves_backup_test e no aparelho).
class _ChavesRegistradoras extends ChavesBackup {
  _ChavesRegistradoras({bool jaConfirmado = false})
    : super(cofre: CofreEmMemoria(), aleatorio: Random(1)) {
    if (jaConfirmado) confirmados.add('ja');
  }
  final confirmados = <String>[];
  @override
  Future<bool> codigoConfirmado() async => confirmados.isNotEmpty;
  @override
  Future<void> confirmarCodigo(String codigoCanonico) async =>
      confirmados.add(codigoCanonico);
}

class _Cenario {
  _Cenario({
    Catalogo? catalogo,
    bool permiteSeguirSemTermos = true,
    bool codigoJaConfirmado = false,
    bool backupNaNuvem = false,
    FalhaAceite? falhaAceite,
  }) {
    chaves = _ChavesRegistradoras(jaConfirmado: codigoJaConfirmado);
    if (backupNaNuvem) {
      armazenamento.metadados[1] = const MetadadoBackup(
        seq: 1,
        path: '00000000-0000-4000-8000-00000000000a/000001.dsmb',
        tamanhoBytes: 10,
        sha256: 'x',
        formatoVersao: 1,
      );
    }
    aceite.falha = falhaAceite;
    onboarding = controladorOnboardingFalso(
      repositorio: repo,
      aceite: aceite,
      catalogo: catalogo,
      permiteSeguirSemTermos: permiteSeguirSemTermos,
    );
  }

  final repo = RepositorioOnboardingMemoria();
  final aceite = AceiteFalso();
  final armazenamento = ArmazenamentoFalso();
  final notificacoes = NotificacoesFalsas(permitido: false);
  late final _ChavesRegistradoras chaves;
  late final ControladorOnboarding onboarding;

  Future<void> montar(WidgetTester tester) async {
    final servico = ServicoAutenticacao(
      PortaAuthFalsa(
        usuarioInicial: const UsuarioAutenticado(
          id: '00000000-0000-4000-8000-00000000000a',
          email: 'pessoa@exemplo.com',
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: PortalAuth(
          servico: servico,
          servicos: servicosFalsos(
            chavesBackup: chaves,
            backup: controladorBackupFalso(
              chaves: chaves,
              armazenamento: armazenamento,
            ),
            lembretes: controladorLembretesFalso(
              porta: notificacoes,
              catalogo: Catalogo.fromItens(const []),
            ),
            onboarding: onboarding,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _tocar(WidgetTester tester, String chave) async {
  final alvo = find.byKey(Key(chave));
  await tester.ensureVisible(alvo);
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

String _passo(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('progresso_onboarding'))).data!;

Future<void> _preencherDados(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('campo_nome')), 'Ana Souza');
  await tester.enterText(find.byKey(const Key('campo_cpf')), '529.982.247-25');
  await _tocar(tester, 'botao_dados_continuar');
}

void main() {
  testWidgets('boas-vindas: disclaimer do contador, literal, antes do login', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: PortalAuth(
          servico: ServicoAutenticacao(PortaAuthFalsa()),
          servicos: servicosFalsos(),
        ),
      ),
    );
    expect(find.text(disclaimerDesmalha), findsOneWidget);
    expect(disclaimerDesmalha, contains('não substitui a orientação'));
    expect(disclaimerDesmalha, contains('comprovantes por 5 anos'));
    await _tocar(tester, 'botao_entrar_boas_vindas');
    expect(find.byKey(const Key('campo_email')), findsOneWidget);
  });

  testWidgets('caminho inteiro: sem termos publicados, código gerado e '
      'confirmado pela tela real, lembrete, e o app abre no Mês', (
    tester,
  ) async {
    final c = _Cenario();
    await c.montar(tester);

    // Aceite: nada publicado → aviso, nenhum aceite inventado.
    expect(_passo(tester), 'Passo 1 de 6');
    expect(
      find.byKey(const Key('aviso_termos_nao_publicados')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('caixa_aceite')), findsNothing);
    await _tocar(tester, 'botao_aceite_continuar');
    expect(c.aceite.registrados, isEmpty);

    // Seus dados: CPF errado não passa.
    await tester.enterText(find.byKey(const Key('campo_nome')), 'Ana Souza');
    await tester.enterText(find.byKey(const Key('campo_cpf')), '52998224724');
    await _tocar(tester, 'botao_dados_continuar');
    expect(find.textContaining('CPF inválido'), findsOneWidget);
    expect(_passo(tester), 'Passo 2 de 6');
    await _preencherDados(tester);
    expect(c.repo.perfil!.cpf, '52998224725');

    // Como funciona: o aviso de que pagar não registra no e-CAC.
    expect(find.byKey(const Key('aviso_ecac')), findsOneWidget);
    await _tocar(tester, 'botao_como_funciona_continuar');

    // Código: sem backup na nuvem → gerar e confirmar na tela real.
    expect(_passo(tester), 'Passo 4 de 6');
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
      final grupo = int.parse(RegExp(r'^(\d)º').firstMatch(rotulo)!.group(1)!);
      await tester.enterText(
        find.byKey(Key('campo_grupo_$i')),
        partes[grupo - 1],
      );
    }
    await _tocar(tester, 'botao_confirmar_codigo_recuperacao');
    await _tocar(tester, 'botao_concluir_codigo');
    expect(c.chaves.confirmados, [codigo]);
    expect(c.repo.codigoConfirmadoEm, isNotNull);

    // Lembrete: pede a permissão ao sistema.
    expect(_passo(tester), 'Passo 5 de 6');
    await _tocar(tester, 'botao_ativar_lembrete');
    expect(c.notificacoes.pedidosDePermissao, 1);

    // Traga seu extrato → conclui e abre o app.
    expect(_passo(tester), 'Passo 6 de 6');
    await _tocar(tester, 'botao_concluir_onboarding');
    expect(c.repo.perfil!.onboardingCompleto, isTrue);
    expect(find.text('Seu mês'), findsOneWidget);
  });

  testWidgets('código é obrigatório: voltar sem confirmar não avança', (
    tester,
  ) async {
    final c = _Cenario();
    await c.montar(tester);
    await _tocar(tester, 'botao_aceite_continuar');
    await _preencherDados(tester);
    await _tocar(tester, 'botao_como_funciona_continuar');
    await _tocar(tester, 'botao_codigo_gerar');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(_passo(tester), 'Passo 4 de 6');
    expect(find.textContaining('Este passo é obrigatório'), findsOneWidget);
    expect(c.repo.codigoConfirmadoEm, isNull);
  });

  testWidgets('conta com backup na nuvem: NÃO gera chave nova', (tester) async {
    final c = _Cenario(backupNaNuvem: true);
    await c.montar(tester);
    await _tocar(tester, 'botao_aceite_continuar');
    await _preencherDados(tester);
    await _tocar(tester, 'botao_como_funciona_continuar');
    expect(find.byKey(const Key('aviso_backup_existente')), findsOneWidget);
    expect(find.byKey(const Key('botao_codigo_gerar')), findsNothing);
    await _tocar(tester, 'botao_codigo_continuar');
    expect(c.chaves.confirmados, isEmpty);
    expect(_passo(tester), 'Passo 5 de 6');
  });

  testWidgets('código já confirmado neste aparelho: segue direto', (
    tester,
  ) async {
    final c = _Cenario(codigoJaConfirmado: true);
    await c.montar(tester);
    await _tocar(tester, 'botao_aceite_continuar');
    await _preencherDados(tester);
    await _tocar(tester, 'botao_como_funciona_continuar');
    expect(find.text('código confirmado'), findsOneWidget);
    expect(c.repo.codigoConfirmadoEm, isNotNull);
  });

  testWidgets('release sem termos publicados: parado no aceite', (
    tester,
  ) async {
    final c = _Cenario(permiteSeguirSemTermos: false);
    await c.montar(tester);
    expect(
      find.textContaining('só pode ser usado depois do aceite'),
      findsOneWidget,
    );
    final botao = tester.widget<FilledButton>(
      find.byKey(const Key('botao_aceite_continuar')),
    );
    expect(botao.onPressed, isNull);
  });

  testWidgets('termos publicados: aceite exige marcar, registra e segue', (
    tester,
  ) async {
    final c = _Cenario(
      catalogo: catalogoComDocumentos(
        termos: '2026-09-v1',
        politica: '2026-09-v1',
      ),
    );
    await c.montar(tester);
    expect(find.byKey(const Key('aviso_termos_nao_publicados')), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('botao_aceite_continuar')))
          .onPressed,
      isNull,
    );
    await _tocar(tester, 'caixa_aceite');
    await _tocar(tester, 'botao_aceite_continuar');
    expect(c.aceite.registrados, [
      ('termos_uso', '2026-09-v1'),
      ('politica_privacidade', '2026-09-v1'),
    ]);
    expect(_passo(tester), 'Passo 2 de 6');
  });

  testWidgets('servidor recusa o aceite: mostra o motivo e não avança', (
    tester,
  ) async {
    final c = _Cenario(
      catalogo: catalogoComDocumentos(
        termos: '2026-09-v1',
        politica: '2026-09-v1',
      ),
      falhaAceite: const FalhaAceite('Sem conexão agora.'),
    );
    await c.montar(tester);
    await _tocar(tester, 'caixa_aceite');
    await _tocar(tester, 'botao_aceite_continuar');
    expect(find.text('Sem conexão agora.'), findsOneWidget);
    expect(_passo(tester), 'Passo 1 de 6');
    expect(c.repo.aceites, isEmpty);
  });

  testWidgets('depois do onboarding, termos novos pedem aceite antes do app', (
    tester,
  ) async {
    final c = _Cenario(
      catalogo: catalogoComDocumentos(
        termos: '2026-10-v1',
        politica: '2026-09-v1',
      ),
    );
    c.repo
      ..perfil = const PerfilDoApp(
        nome: 'Ana',
        cpf: '52998224725',
        onboardingCompleto: true,
        usuarioRemotoId: '00000000-0000-4000-8000-00000000000a',
      )
      ..aceites.addAll({
        ('termos_uso', '2026-09-v1'),
        ('politica_privacidade', '2026-09-v1'),
      });
    await c.montar(tester);
    expect(find.text('Seu mês'), findsNothing);
    expect(find.text('Versão 2026-10-v1'), findsOneWidget);
    await _tocar(tester, 'caixa_aceite');
    await _tocar(tester, 'botao_aceite_continuar');
    expect(find.text('Seu mês'), findsOneWidget);
  });
}
