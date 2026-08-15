import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'configuracao_supabase.dart';
import 'porta_auth.dart';

/// Sobe o cliente Supabase com as variáveis do build.
///
/// Fica neste arquivo, e não num `configuracao_supabase.dart`, para que o SDK
/// continue tendo **um** ponto de entrada no app — é isso que torna a trava
/// anti-senha auditável de olho.
Future<void> inicializarSupabase() async {
  if (!supabaseConfigurado) return;
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
}

/// Implementação da [PortaAuth] sobre o Supabase.
///
/// 🔴 **Este é o único arquivo do app autorizado a falar com o SDK de auth.**
/// A regra não é estética: a decisão do projeto é OTP por e-mail, SEM SENHA, e
/// o Supabase não oferece toggle para desativar autenticação por senha — senha
/// e código vivem no mesmo provedor de e-mail. A garantia é do código do app.
/// Um arquivo pequeno e único é auditável de olho; o app inteiro não é. O teste
/// `test/auth/trava_sem_senha_test.dart` verifica as duas coisas: que o SDK só
/// é importado aqui, e que nenhuma API de senha ou de provedor social aparece
/// em `lib/`.
///
/// A segunda camada da trava está no banco (`20260815000359_trava_sem_senha`):
/// um cadastro com senha que escape do cliente falha alto, em vez de criar em
/// silêncio uma conta cuja senha vira o elo fraco do backup.
class PortaAuthSupabase implements PortaAuth {
  PortaAuthSupabase(this._auth);

  /// Constrói a partir do cliente global, já inicializado por
  /// `Supabase.initialize` (ver `configuracao_supabase.dart`).
  factory PortaAuthSupabase.doClienteGlobal() =>
      PortaAuthSupabase(Supabase.instance.client.auth);

  final GoTrueClient _auth;

  @override
  Future<void> enviarCodigo(String email) => _executar(
    () => _auth.signInWithOtp(email: email, shouldCreateUser: true),
  );

  @override
  Future<UsuarioAutenticado> verificarCodigo({
    required String email,
    required String codigo,
  }) => _executar(() async {
    final resposta = await _auth.verifyOTP(
      email: email,
      token: codigo,
      type: OtpType.email,
    );
    final usuario = resposta.user;
    if (usuario == null) {
      throw const FalhaAuth(
        MotivoFalhaAuth.desconhecido,
        'O servidor aceitou o código mas não devolveu a sessão.',
      );
    }
    return _converter(usuario);
  });

  @override
  Future<void> solicitarTrocaEmail(String novoEmail) =>
      _executar(() => _auth.updateUser(UserAttributes(email: novoEmail)));

  @override
  Future<UsuarioAutenticado> confirmarTrocaEmail({
    required String email,
    required String codigo,
  }) => _executar(() async {
    final resposta = await _auth.verifyOTP(
      email: email,
      token: codigo,
      type: OtpType.emailChange,
    );
    final usuario = resposta.user ?? _auth.currentUser;
    if (usuario == null) {
      throw const FalhaAuth(
        MotivoFalhaAuth.naoAutenticado,
        'A sessão terminou durante a troca de e-mail. Entre de novo.',
      );
    }
    return _converter(usuario);
  });

  @override
  Future<UsuarioAutenticado?> recarregarUsuario() => _executar(() async {
    final resposta = await _auth.getUser();
    final usuario = resposta.user;
    return usuario == null ? null : _converter(usuario);
  });

  @override
  Future<void> sair() => _executar(_auth.signOut);

  @override
  UsuarioAutenticado? get usuarioAtual {
    final usuario = _auth.currentUser;
    return usuario == null ? null : _converter(usuario);
  }

  @override
  Stream<UsuarioAutenticado?> get mudancas => _auth.onAuthStateChange.map(
    (evento) {
      final usuario = evento.session?.user;
      return usuario == null ? null : _converter(usuario);
    },
  );

  static UsuarioAutenticado _converter(User usuario) => UsuarioAutenticado(
    id: usuario.id,
    // `email` é anulável no modelo do SDK porque o mesmo tipo serve para login
    // por telefone. Aqui o e-mail É a conta e não há outro caminho de entrada.
    email: usuario.email ?? '',
    emailPendente: _vazioComoNulo(usuario.newEmail),
  );

  static String? _vazioComoNulo(String? valor) =>
      (valor == null || valor.isEmpty) ? null : valor;

  /// Traduz as exceções do SDK para [FalhaAuth], com mensagem de tela.
  static Future<T> _executar<T>(Future<T> Function() acao) async {
    try {
      return await acao();
    } on FalhaAuth {
      rethrow;
    } on AuthException catch (erro) {
      throw _traduzir(erro);
    } on Object catch (erro) {
      throw FalhaAuth(
        MotivoFalhaAuth.redeIndisponivel,
        'Não foi possível falar com o servidor. Verifique sua conexão.',
        causa: erro,
      );
    }
  }

  static FalhaAuth _traduzir(AuthException erro) {
    if (erro is AuthRetryableFetchException) {
      return FalhaAuth(
        MotivoFalhaAuth.redeIndisponivel,
        'Não foi possível falar com o servidor. Verifique sua conexão.',
        causa: erro,
      );
    }
    if (erro is AuthSessionMissingException) {
      return FalhaAuth(
        MotivoFalhaAuth.naoAutenticado,
        'Sua sessão terminou. Entre de novo.',
        causa: erro,
      );
    }
    return switch (erro.code) {
      'otp_expired' => FalhaAuth(
        MotivoFalhaAuth.codigoExpirado,
        'O código expirou. Peça um novo.',
        causa: erro,
      ),
      'otp_disabled' || 'email_provider_disabled' => FalhaAuth(
        MotivoFalhaAuth.desconhecido,
        'A entrada por código de e-mail está desligada no servidor.',
        causa: erro,
      ),
      'invalid_credentials' || 'validation_failed' => FalhaAuth(
        MotivoFalhaAuth.codigoInvalido,
        'Código inválido. Confira os dígitos e tente de novo.',
        causa: erro,
      ),
      'over_email_send_rate_limit' || 'over_request_rate_limit' => FalhaAuth(
        MotivoFalhaAuth.limiteExcedido,
        'Muitas tentativas seguidas. Aguarde alguns minutos.',
        causa: erro,
      ),
      'email_exists' || 'email_address_not_authorized' => FalhaAuth(
        MotivoFalhaAuth.emailJaEmUso,
        'Este e-mail já está em uso por outra conta.',
        causa: erro,
      ),
      // 403 sem código conhecido, no caminho do código: token gasto ou errado.
      _ when erro.statusCode == '403' => FalhaAuth(
        MotivoFalhaAuth.codigoInvalido,
        'Código inválido ou já usado. Peça um novo.',
        causa: erro,
      ),
      _ => FalhaAuth(
        MotivoFalhaAuth.desconhecido,
        // A mensagem do provedor vem em inglês e às vezes carrega o e-mail —
        // por isso não é repassada à tela.
        'Não foi possível concluir. Tente de novo em instantes.',
        causa: erro,
      ),
    };
  }
}
