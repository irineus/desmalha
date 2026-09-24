import 'package:desmalha_app/conta/porta_exclusao_conta.dart';

/// Porta de exclusão de mentira: conta as chamadas e falha quando mandada.
class PortaExclusaoFalsa implements PortaExclusaoConta {
  int chamadas = 0;

  /// Falha a lançar na próxima chamada, se houver.
  FalhaExclusaoConta? falhaProgramada;

  @override
  Future<void> excluirContaDaSessao() async {
    chamadas++;
    final falha = falhaProgramada;
    if (falha != null) {
      falhaProgramada = null;
      throw falha;
    }
  }
}
