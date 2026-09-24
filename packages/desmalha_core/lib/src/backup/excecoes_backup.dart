/// Falhas do backup. Todas são "recusa integral": nenhuma restauração é
/// feita pela metade — um livro-caixa restaurado em parte é pior do que
/// nenhum, porque parece completo.
library;

/// O arquivo não é um backup válido (estrutura, manifesto, hash, contagens).
class BackupInvalidoException implements Exception {
  const BackupInvalidoException(this.mensagem);
  final String mensagem;
  @override
  String toString() => 'BackupInvalidoException: $mensagem';
}

/// Backup gravado por um app mais novo que este. Caso real e frequente: o
/// usuário atualiza no aparelho novo e restaura no antigo, que ficou para
/// trás. A mensagem de tela é "atualize o app".
class BackupDeVersaoFuturaException implements Exception {
  const BackupDeVersaoFuturaException(this.mensagem);
  final String mensagem;
  @override
  String toString() => 'BackupDeVersaoFuturaException: $mensagem';
}

/// A chave (mestra ou derivada do código) não abre o backup — ou o arquivo
/// foi alterado depois de gravado. O AEAD não distingue os dois casos, e não
/// deve: distinguir ajudaria quem tenta adivinhar.
class ChaveDeBackupIncorretaException implements Exception {
  const ChaveDeBackupIncorretaException(this.mensagem);
  final String mensagem;
  @override
  String toString() => 'ChaveDeBackupIncorretaException: $mensagem';
}
