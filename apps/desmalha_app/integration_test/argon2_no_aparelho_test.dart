/// Custo REAL do Argon2id do backup no aparelho — a prova que a escolha da
/// biblioteca de cripto exigia (card "Backup cifrado ponta a ponta").
///
///   fvm flutter test integration_test/argon2_no_aparelho_test.dart
///
/// A derivação (m = 64 MiB, t = 3, p = 1) só roda em primeiro plano: ao
/// confirmar o código de recuperação e ao restaurar em outra plataforma. O
/// backup diário não a roda — ele reaproveita o cabeçalho de chave. O teto
/// abaixo é o limite do aceitável para uma tela que diz "preparando"; o
/// número medido fica no log e no card.
library;

import 'dart:math';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Argon2id 64 MiB/t=3 cabe numa espera de primeiro plano', (
    tester,
  ) async {
    final mestra = List<int>.generate(32, (i) => i);
    final tempos = <int>[];
    late CabecalhoChave cabecalho;
    for (var i = 0; i < 3; i++) {
      final relogio = Stopwatch()..start();
      cabecalho = await embrulharChaveMestra(
        chaveMestra: mestra,
        codigo: 'MEDICAO-NO-APARELHO',
        aleatorio: Random(i),
      );
      tempos.add(relogio.elapsedMilliseconds);
    }
    final relogio = Stopwatch()..start();
    final desembrulhada = await cabecalho.chaveMestraPeloCodigo(
      'MEDICAO-NO-APARELHO',
    );
    tempos.add(relogio.elapsedMilliseconds);
    // ignore: avoid_print
    print('ARGON2ID_MS: $tempos');
    expect(desembrulhada, mestra);
    expect(tempos.reduce(max), lessThan(15000));
  });
}
