/// Porta das notificações locais agendadas — o lembrete de vencimento do
/// DARF é local, agendado no aparelho (decisão vigente: push server-side
/// saiu do caminho crítico do MVP). A implementação real fica em
/// `porta_notificacoes_locais.dart`; os testes usam uma em memória.
library;

abstract interface class PortaNotificacoes {
  /// Prepara o plugin. Idempotente; NÃO pede permissão.
  Future<void> inicializar();

  /// O sistema deixa o app mostrar notificação agora?
  Future<bool> permitidas();

  /// Pede a permissão ao sistema (Android 13+: `POST_NOTIFICATIONS`).
  /// Devolve se ficou concedida.
  Future<bool> pedirPermissao();

  /// Ids das notificações agendadas e ainda não entregues.
  Future<Set<int>> agendadas();

  Future<void> cancelar(int id);

  /// Agenda para o [instante] (hora local do aparelho). Precisão de alarme
  /// inexato: um lembrete de DATA não justifica a permissão de alarme exato.
  Future<void> agendar({
    required int id,
    required DateTime instante,
    required String titulo,
    required String corpo,
  });
}
