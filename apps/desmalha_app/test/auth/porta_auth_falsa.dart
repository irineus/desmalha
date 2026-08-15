import 'dart:async';

import 'package:desmalha_app/auth/porta_auth.dart';

/// Porta de autenticação de mentira, com memória do que foi chamado.
///
/// Serve a dois propósitos: rodar o serviço sem rede e registrar a sequência
/// exata de chamadas, para que o teste possa afirmar o que o app faz — e o que
/// ele nunca faz.
class PortaAuthFalsa implements PortaAuth {
  PortaAuthFalsa({UsuarioAutenticado? usuarioInicial})
    : _usuario = usuarioInicial;

  /// Nome de cada método chamado, em ordem.
  final List<String> chamadas = <String>[];

  /// Argumentos da última chamada de cada método.
  final Map<String, Map<String, String?>> argumentos = {};

  final _emissor = StreamController<UsuarioAutenticado?>.broadcast();
  UsuarioAutenticado? _usuario;

  /// Falha a ser lançada na próxima chamada, se houver.
  FalhaAuth? falhaProgramada;

  /// Usuário devolvido por [recarregarUsuario]; por padrão, o corrente.
  UsuarioAutenticado? Function()? recargaProgramada;

  void _registrar(String metodo, [Map<String, String?> args = const {}]) {
    chamadas.add(metodo);
    argumentos[metodo] = args;
    final falha = falhaProgramada;
    if (falha != null) {
      falhaProgramada = null;
      throw falha;
    }
  }

  /// Simula o provedor empurrando uma sessão nova (login, refresh, logout).
  void emitirSessao(UsuarioAutenticado? usuario) {
    _usuario = usuario;
    _emissor.add(usuario);
  }

  Future<void> fechar() => _emissor.close();

  @override
  Future<void> enviarCodigo(String email) async {
    _registrar('enviarCodigo', {'email': email});
  }

  @override
  Future<UsuarioAutenticado> verificarCodigo({
    required String email,
    required String codigo,
  }) async {
    _registrar('verificarCodigo', {'email': email, 'codigo': codigo});
    final usuario = UsuarioAutenticado(id: 'uid-teste', email: email);
    _usuario = usuario;
    return usuario;
  }

  @override
  Future<void> solicitarTrocaEmail(String novoEmail) async {
    _registrar('solicitarTrocaEmail', {'novoEmail': novoEmail});
    final atual = _usuario;
    if (atual != null) {
      _usuario = UsuarioAutenticado(
        id: atual.id,
        email: atual.email,
        emailPendente: novoEmail,
      );
    }
  }

  @override
  Future<UsuarioAutenticado> confirmarTrocaEmail({
    required String email,
    required String codigo,
  }) async {
    _registrar('confirmarTrocaEmail', {'email': email, 'codigo': codigo});
    return _usuario ?? UsuarioAutenticado(id: 'uid-teste', email: email);
  }

  @override
  Future<UsuarioAutenticado?> recarregarUsuario() async {
    _registrar('recarregarUsuario');
    final programada = recargaProgramada;
    if (programada != null) {
      _usuario = programada();
    }
    return _usuario;
  }

  @override
  Future<void> sair() async {
    _registrar('sair');
    _usuario = null;
  }

  @override
  UsuarioAutenticado? get usuarioAtual => _usuario;

  @override
  Stream<UsuarioAutenticado?> get mudancas => _emissor.stream;
}
