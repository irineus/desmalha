/// As portas e serviços que as telas atrás do login usam — num objeto só,
/// montado no `main.dart` com as implementações reais e nos testes com as
/// falsas. Uma tela nova pega daqui o que precisa, em vez de cada serviço
/// virar mais um parâmetro atravessando porteiro, casca e abas.
library;

import 'backup/chaves_backup.dart';
import 'conta/porta_exclusao_conta.dart';

class ServicosDoApp {
  const ServicosDoApp({required this.exclusao, required this.chavesBackup});

  /// Exclusão da conta pelo app (Ajustes > Sua conta).
  final PortaExclusaoConta exclusao;

  /// Chave-mestra e código de recuperação do backup (Ajustes).
  final ChavesBackup chavesBackup;
}
