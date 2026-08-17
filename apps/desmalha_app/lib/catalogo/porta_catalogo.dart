/// Porta de acesso remoto ao catálogo versionado.
///
/// Mesmo desenho do `PortaAuth`: o app fala com uma interface estreita e a
/// implementação concreta fica num arquivo só, substituível por dublê nos
/// testes. Aqui a porta é ainda menor — o catálogo é só-leitura por
/// construção (RLS sem policy de escrita no servidor), então existe UM
/// método, de leitura.
library;

/// Falha de comunicação ou resposta inesperada do servidor de catálogo.
///
/// Nunca carrega dado fiscal: o catálogo é conteúdo público (tabela do
/// imposto, feriados, perfis de banco) e a mensagem só descreve o transporte.
class ExcecaoCatalogoRemoto implements Exception {
  ExcecaoCatalogoRemoto(this.mensagem);

  final String mensagem;

  @override
  String toString() => 'ExcecaoCatalogoRemoto: $mensagem';
}

/// O que o app precisa do servidor de catálogo: a lista completa de itens
/// `(tipo, id, conteudo)`, crus — quem valida é `Catalogo.fromItens`, no
/// repositório, ANTES de qualquer gravação em cache.
abstract interface class PortaCatalogoRemota {
  /// Busca todos os itens publicados.
  ///
  /// Lança [ExcecaoCatalogoRemoto] em falha de rede, resposta não-200 ou
  /// corpo que não seja uma lista JSON.
  Future<List<Map<String, Object?>>> buscarItens();
}
