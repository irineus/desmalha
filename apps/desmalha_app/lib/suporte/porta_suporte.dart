/// O envio de extrato ao suporte do lado do servidor: o bucket
/// `suporte-extratos` (caixa de entrada só de escrita) e a tabela
/// `envios_suporte`, que carimba o consentimento e o prazo de 30 dias
/// (migration `*_envios_suporte.sql`).
library;

import 'dart:typed_data';

/// O que o servidor registrou.
class EnvioRegistrado {
  const EnvioRegistrado({required this.path, required this.expiraEm});

  final String path;

  /// Carimbado pelo servidor: consentimento + 30 dias.
  final DateTime expiraEm;
}

class FalhaEnvioSuporte implements Exception {
  const FalhaEnvioSuporte(this.mensagem);
  final String mensagem;
  @override
  String toString() => 'FalhaEnvioSuporte: $mensagem';
}

abstract interface class PortaSuporte {
  /// Envia [bytes] para `suporte-extratos/<path>` (sem sobrescrever) e
  /// registra o envio. Lança [FalhaEnvioSuporte].
  Future<EnvioRegistrado> enviar({
    required String path,
    required Uint8List bytes,
    required String motivo,
    String? bancoInformado,
  });
}
