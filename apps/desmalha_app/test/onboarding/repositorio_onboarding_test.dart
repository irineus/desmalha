import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/onboarding/repositorio_onboarding.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BancoLocal banco;
  late RepositorioOnboardingDrift repo;
  final agora = DateTime.utc(2026, 9, 24, 13);

  setUp(() {
    banco = BancoLocal(NativeDatabase.memory());
    repo = RepositorioOnboardingDrift(banco);
  });
  tearDown(() => banco.close());

  test('perfil: vazio, salvo, atualizado, concluído', () async {
    expect(await repo.lerPerfil(), isNull);
    await repo.salvarDados(
      nome: 'Ana',
      cpf: '52998224725',
      usuarioRemotoId: 'uid-1',
      em: agora,
    );
    var p = (await repo.lerPerfil())!;
    expect(
      (p.nome, p.cpf, p.onboardingCompleto, p.usuarioRemotoId),
      ('Ana', '52998224725', false, 'uid-1'),
    );

    await repo.salvarDados(
      nome: 'Ana Souza',
      cpf: '52998224725',
      usuarioRemotoId: 'uid-1',
      em: agora,
    );
    await repo.registrarCodigoConfirmado(agora);
    await repo.concluirOnboarding(agora);
    p = (await repo.lerPerfil())!;
    expect((p.nome, p.onboardingCompleto), ('Ana Souza', true));

    final codigo = await banco
        .customSelect(
          'SELECT codigo_recuperacao_confirmado_em AS c FROM perfil',
        )
        .getSingle();
    expect(codigo.read<int>('c'), agora.millisecondsSinceEpoch);
  });

  test('concluir sem perfil lança — UPDATE sem linha não passa calado', () {
    expect(repo.concluirOnboarding(agora), throwsStateError);
  });

  test('aceites: espelho local idempotente, só o sincronizado conta', () async {
    expect(await repo.aceitesSincronizados(), isEmpty);
    await repo.registrarAceiteLocal(
      documento: 'termos_uso',
      versao: '2026-09-v1',
      em: agora,
    );
    await repo.registrarAceiteLocal(
      documento: 'termos_uso',
      versao: '2026-09-v1',
      em: agora,
    );
    // Linha não sincronizada (ex.: gravada antes de o servidor confirmar)
    // não conta como aceite.
    await banco.customStatement(
      "INSERT INTO aceites_termos_local VALUES ('politica_privacidade', "
      "'2026-09-v1', 0, 0)",
    );
    expect(await repo.aceitesSincronizados(), {('termos_uso', '2026-09-v1')});
  });
}
