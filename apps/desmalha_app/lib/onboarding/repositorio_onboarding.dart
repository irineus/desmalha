/// O que o onboarding guarda no banco local cifrado: a linha única de
/// `perfil` (nome e CPF — o CPF vai impresso no DARF) e o espelho dos
/// aceites de documento legal (`aceites_termos_local`; o registro que vale
/// é o do servidor, `registrar_aceite`).
library;

import 'package:drift/drift.dart' show Variable;

import '../dados/banco.dart';

/// O perfil local, no que o app usa hoje.
class PerfilDoApp {
  const PerfilDoApp({
    required this.nome,
    required this.cpf,
    required this.onboardingCompleto,
    this.usuarioRemotoId,
  });

  final String nome;

  /// Só dígitos.
  final String cpf;
  final bool onboardingCompleto;
  final String? usuarioRemotoId;
}

abstract interface class RepositorioOnboarding {
  Future<PerfilDoApp?> lerPerfil();

  /// Cria ou atualiza nome e CPF da linha única.
  Future<void> salvarDados({
    required String nome,
    required String cpf,
    required String? usuarioRemotoId,
    required DateTime em,
  });

  Future<void> registrarCodigoConfirmado(DateTime em);

  Future<void> concluirOnboarding(DateTime em);

  /// Pares `(documento, versao)` aceitos e confirmados pelo servidor.
  Future<Set<(String, String)>> aceitesSincronizados();

  Future<void> registrarAceiteLocal({
    required String documento,
    required String versao,
    required DateTime em,
  });
}

class RepositorioOnboardingDrift implements RepositorioOnboarding {
  RepositorioOnboardingDrift(this.banco);
  final BancoLocal banco;

  @override
  Future<PerfilDoApp?> lerPerfil() async {
    final linha = await banco
        .customSelect(
          'SELECT nome, cpf, onboarding_completo, usuario_remoto_id '
          'FROM perfil WHERE id = 1',
        )
        .getSingleOrNull();
    if (linha == null) return null;
    return PerfilDoApp(
      nome: linha.read<String>('nome'),
      cpf: linha.read<String>('cpf'),
      onboardingCompleto: linha.read<int>('onboarding_completo') == 1,
      usuarioRemotoId: linha.readNullable<String>('usuario_remoto_id'),
    );
  }

  @override
  Future<void> salvarDados({
    required String nome,
    required String cpf,
    required String? usuarioRemotoId,
    required DateTime em,
  }) {
    final ms = em.toUtc().millisecondsSinceEpoch;
    return banco.customStatement(
      'INSERT INTO perfil (id, usuario_remoto_id, nome, cpf, criado_em, '
      'atualizado_em) VALUES (1, ?, ?, ?, ?, ?) '
      'ON CONFLICT(id) DO UPDATE SET nome = excluded.nome, '
      'cpf = excluded.cpf, usuario_remoto_id = excluded.usuario_remoto_id, '
      'atualizado_em = excluded.atualizado_em',
      [usuarioRemotoId, nome, cpf, ms, ms],
    );
  }

  @override
  Future<void> registrarCodigoConfirmado(DateTime em) => banco.customStatement(
    'UPDATE perfil SET codigo_recuperacao_confirmado_em = ?, '
    'atualizado_em = ? WHERE id = 1',
    [em.toUtc().millisecondsSinceEpoch, em.toUtc().millisecondsSinceEpoch],
  );

  @override
  Future<void> concluirOnboarding(DateTime em) async {
    // Sem a linha do perfil não há o que concluir — e um UPDATE que não
    // acha linha passaria calado, deixando o usuário preso no onboarding.
    final alteradas = await banco.customUpdate(
      'UPDATE perfil SET onboarding_completo = 1, atualizado_em = ? '
      'WHERE id = 1',
      variables: [Variable.withInt(em.toUtc().millisecondsSinceEpoch)],
    );
    if (alteradas != 1) {
      throw StateError('onboarding concluído sem perfil salvo');
    }
  }

  @override
  Future<Set<(String, String)>> aceitesSincronizados() async {
    final linhas = await banco
        .customSelect(
          'SELECT documento, versao FROM aceites_termos_local '
          'WHERE sincronizado = 1',
        )
        .get();
    return {
      for (final l in linhas)
        (l.read<String>('documento'), l.read<String>('versao')),
    };
  }

  @override
  Future<void> registrarAceiteLocal({
    required String documento,
    required String versao,
    required DateTime em,
  }) => banco.customStatement(
    'INSERT INTO aceites_termos_local (documento, versao, aceito_em, '
    'sincronizado) VALUES (?, ?, ?, 1) '
    'ON CONFLICT(documento, versao) DO UPDATE SET sincronizado = 1',
    [documento, versao, em.toUtc().millisecondsSinceEpoch],
  );
}

/// Para testes e para o build sem banco.
class RepositorioOnboardingMemoria implements RepositorioOnboarding {
  PerfilDoApp? perfil;
  DateTime? codigoConfirmadoEm;
  final Set<(String, String)> aceites = {};

  @override
  Future<PerfilDoApp?> lerPerfil() async => perfil;

  @override
  Future<void> salvarDados({
    required String nome,
    required String cpf,
    required String? usuarioRemotoId,
    required DateTime em,
  }) async => perfil = PerfilDoApp(
    nome: nome,
    cpf: cpf,
    onboardingCompleto: perfil?.onboardingCompleto ?? false,
    usuarioRemotoId: usuarioRemotoId,
  );

  @override
  Future<void> registrarCodigoConfirmado(DateTime em) async =>
      codigoConfirmadoEm = em;

  @override
  Future<void> concluirOnboarding(DateTime em) async {
    final p = perfil;
    if (p == null) throw StateError('onboarding concluído sem perfil salvo');
    perfil = PerfilDoApp(
      nome: p.nome,
      cpf: p.cpf,
      onboardingCompleto: true,
      usuarioRemotoId: p.usuarioRemotoId,
    );
  }

  @override
  Future<Set<(String, String)>> aceitesSincronizados() async => {...aceites};

  @override
  Future<void> registrarAceiteLocal({
    required String documento,
    required String versao,
    required DateTime em,
  }) async => aceites.add((documento, versao));
}
