/// Dados locais por conta NO APARELHO, com banco SQLite real (em memória),
/// Keystore real e a limpeza real: o aparelho tem os dados da Ana (perfil,
/// extrato, lançamento, chave do backup); o Beto entra; a tela barra antes
/// do app; ele apaga; banco e cofre ficam vazios e o onboarding recomeça.
///
///   fvm flutter test integration_test/dados_outra_conta_no_aparelho_test.dart
///
/// Com `--dart-define=CAPTURA=true`, pausa em cada tela.
library;

import 'package:desmalha_app/auth/porta_auth.dart';
import 'package:desmalha_app/auth/portal_auth.dart';
import 'package:desmalha_app/auth/servico_auth.dart';
import 'package:desmalha_app/backup/chaves_backup.dart';
import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/dados/chave_banco.dart';
import 'package:desmalha_app/dados/limpeza_local.dart';
import 'package:desmalha_app/onboarding/repositorio_onboarding.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/auth/porta_auth_falsa.dart';
import '../test/servicos_falsos.dart';

const _captura = bool.fromEnvironment('CAPTURA');
const _beto = '00000000-0000-4000-8000-0000000000bb';

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

  testWidgets('outra conta no aparelho: barrada, apaga, recomeça', (
    tester,
  ) async {
    final banco = BancoLocal(NativeDatabase.memory());
    final cofre = _CofrePrefixado(const CofreSeguroDoSistema());
    final chaves = ChavesBackup(cofre: cofre);
    final repo = RepositorioOnboardingDrift(banco);

    // Os dados da Ana neste aparelho.
    await repo.salvarDados(
      nome: 'Ana Souza',
      cpf: '52998224725',
      usuarioRemotoId: '00000000-0000-4000-8000-0000000000aa',
      em: DateTime.utc(2026, 9, 1),
    );
    await repo.concluirOnboarding(DateTime.utc(2026, 9, 1));
    await banco.customStatement(
      "INSERT INTO contas_bancarias (id, apelido, criado_em) VALUES ('c', 'C', 0)",
    );
    await banco.customStatement(
      "INSERT INTO transacoes (id, conta_id, data, valor_centavos, "
      "descricao_raw, criado_em) VALUES ('t', 'c', '2026-08-03', 45000, "
      "'PIX', 0)",
    );
    await chaves.obterOuCriarChaveMestra();
    expect(await cofre.ler(ChavesBackup.campoMestra), isNotNull);

    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: PortalAuth(
          servico: ServicoAutenticacao(
            PortaAuthFalsa(
              usuarioInicial: const UsuarioAutenticado(
                id: _beto,
                email: 'beto@exemplo.com',
              ),
            ),
          ),
          servicos: servicosFalsos(
            chavesBackup: chaves,
            onboarding: controladorOnboardingFalso(
              repositorio: repo,
              limpeza: LimpezaLocalDoApp(banco: banco, chaves: chaves),
              usuarioId: () => _beto,
            ),
          ),
        ),
      ),
    );
    await _esperar(tester, find.text('Este celular tem dados de outra conta'));
    await _marcar(tester, 'outra-conta');
    expect(find.text('Seu mês'), findsNothing);
    expect(find.textContaining('Ana'), findsNothing);

    await tester.tap(find.byKey(const Key('caixa_apagar_dados_locais')));
    await tester.pumpAndSettle();
    await _marcar(tester, 'outra-conta-confirmada');
    await tester.tap(find.byKey(const Key('botao_apagar_dados_locais')));
    await _esperar(tester, find.text('Passo 1 de 6'));
    await _marcar(tester, 'onboarding-da-conta-nova');

    for (final tabela in tabelasDaConta) {
      final n = await banco
          .customSelect('SELECT count(*) AS n FROM $tabela')
          .getSingle();
      expect(n.read<int>('n'), 0, reason: tabela);
    }
    for (final campo in [
      ChavesBackup.campoMestra,
      ChavesBackup.campoCabecalho,
      ChavesBackup.campoImpressao,
    ]) {
      expect(await cofre.ler(campo), isNull, reason: campo);
    }
    await banco.close();
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
  @override
  Future<void> apagar(String campo) => _real.apagar('$_prefixo$campo');
}
