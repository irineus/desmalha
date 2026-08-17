/// Prova NO APARELHO da propriedade que os testes de host provam no host:
/// o banco abre cifrado, com a chave saída do cofre do sistema (Keystore no
/// Android, Keychain no iOS), e `PRAGMA cipher_version` responde.
///
/// Exercita a cadeia inteira de verdade — gerar/reler a chave no cofre,
/// abrir o arquivo em documentos, conferir a cifra — que é o que o boot do
/// app faz antes do `runApp`.
///
/// Rodar com um emulador/aparelho conectado:
///   fvm flutter test integration_test
///
/// Este é também o teste que o card "Manter iOS compilável e testado em
/// simulador" agenda para o simulador iOS: a armadilha histórica do
/// SQLCipher no iOS é linkar o SQLite do sistema e abrir SEM cifra, calado.
library;

import 'package:desmalha_app/dados/conexao_cifrada.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('o banco do aparelho abre cifrado e com chave do cofre',
      (tester) async {
    // Se o binário embarcado vier sem SQLCipher, é AQUI que estoura
    // (BancoSemCifraException) — o mesmo caminho do boot real.
    await abrirBancoNoBoot();

    final linhas =
        await bancoDoApp().customSelect('PRAGMA cipher_version;').get();
    expect(linhas, isNotEmpty);
    final versao = linhas.first.data.values.first?.toString().trim() ?? '';
    expect(versao, isNotEmpty);
    // ignore: avoid_print — é o registro da prova no log do teste.
    print('cipher_version no aparelho: $versao');
  });
}
