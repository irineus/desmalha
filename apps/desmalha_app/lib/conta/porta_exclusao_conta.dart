/// Exclusão da conta pelo app — o segundo caminho que o Google Play exige
/// (o primeiro é a página web pública da edge function `excluir-conta`).
///
/// Porta separada da `PortaAuth` DE PROPÓSITO: exclusão não é operação do SDK
/// de auth, e a `PortaAuth` existe pequena para que a trava anti-senha seja
/// auditável de olho. Quem executa a exclusão é o servidor, na ordem que não
/// pode mudar (Storage API → `encerrar_conta` → banimento), parando no
/// primeiro passo que falha.
library;

/// O que o app precisa do servidor para excluir a conta da sessão atual.
abstract interface class PortaExclusaoConta {
  /// Pede ao servidor a exclusão da conta da sessão em curso.
  ///
  /// Só retorna normalmente se o servidor CONFIRMOU a exclusão. Qualquer
  /// outra coisa — erro do servidor, rede, sessão ausente — é
  /// [FalhaExclusaoConta], e a conta NÃO pode ser dada como excluída.
  Future<void> excluirContaDaSessao();
}

/// A exclusão não foi confirmada pelo servidor. [mensagem] vai para a tela.
class FalhaExclusaoConta implements Exception {
  const FalhaExclusaoConta(this.mensagem, {this.causa});

  final String mensagem;
  final Object? causa;

  @override
  String toString() => 'FalhaExclusaoConta: $mensagem';
}

/// Os três prazos da PP v0.2, como a página web de exclusão os declara
/// (`supabase/functions/_compartilhado/pagina.ts`, `PRAZOS`). Um teste
/// confere que os dois textos continuam iguais: prazo que muda num lugar e
/// não no outro transforma uma das telas em mentira para o usuário e para a
/// loja.
abstract final class PrazosExclusao {
  static const arquivos = 'imediatamente, sem carência';
  static const conta = '30 dias';
  static const aceite = '5 anos';
}
