/// Registro do aceite de um documento legal no servidor — o único que vale
/// (`public.registrar_aceite`). O servidor recusa versão que não esteja na
/// allowlist `documentos_legais` e deriva hash do texto, IP e user agent;
/// o app só diz QUAL documento e QUAL versão.
library;

class FalhaAceite implements Exception {
  const FalhaAceite(this.mensagem, {this.causa});

  /// Texto para a tela.
  final String mensagem;

  /// Detalhe técnico (status HTTP, exceção de rede).
  final String? causa;

  @override
  String toString() =>
      'FalhaAceite: $mensagem${causa == null ? '' : ' ($causa)'}';
}

abstract interface class PortaAceite {
  /// Registra o aceite da sessão em curso. Idempotente no servidor por
  /// (usuário, documento, versão). Lança [FalhaAceite] se não confirmou.
  Future<void> registrar({required String documento, required String versao});
}
