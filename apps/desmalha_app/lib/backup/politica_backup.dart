/// Quando o backup AUTOMÁTICO roda — regra pura, sem relógio nem rede.
///
/// Cadência decidida com o owner (24/09/2026): automático 1×/dia, só em
/// Wi-Fi, e só se houve alteração desde o último backup bem-sucedido; aviso
/// visível depois de 7 dias sem backup bem-sucedido; SEM código de
/// recuperação confirmado, o automático não liga (e a tela diz isso).
///
/// **Agendador (decisão técnica, set/2026): nenhum em segundo plano.** No
/// Desmalha o dado fiscal só muda com o app aberto (local-first, sem
/// sincronização), então disparar ao abrir e ao voltar ao app cobre toda
/// alteração sem rodar sessão, cofre e rede num isolate de segundo plano. O
/// "só se mudou" é o `hash_conteudo` dos documentos contra o do último
/// sucesso.
library;

enum MotivoSemBackup { semSessao, codigoNaoConfirmado, foraDoWifi, jaFezHoje }

class DecisaoBackup {
  const DecisaoBackup.executar() : motivo = null;
  const DecisaoBackup.nao(MotivoSemBackup this.motivo);

  /// `null` = executar (o serviço ainda pula se o conteúdo não mudou).
  final MotivoSemBackup? motivo;
  bool get executar => motivo == null;
}

const Duration intervaloAutomatico = Duration(hours: 24);
const Duration prazoAvisoDesatualizado = Duration(days: 7);

DecisaoBackup decidirBackupAutomatico({
  required DateTime agora,
  required DateTime? ultimoSucessoEm,
  required bool comSessao,
  required bool codigoConfirmado,
  required bool emWifi,
}) {
  if (!comSessao) return const DecisaoBackup.nao(MotivoSemBackup.semSessao);
  if (!codigoConfirmado) {
    return const DecisaoBackup.nao(MotivoSemBackup.codigoNaoConfirmado);
  }
  if (!emWifi) return const DecisaoBackup.nao(MotivoSemBackup.foraDoWifi);
  if (ultimoSucessoEm != null &&
      agora.difference(ultimoSucessoEm) < intervaloAutomatico) {
    return const DecisaoBackup.nao(MotivoSemBackup.jaFezHoje);
  }
  return const DecisaoBackup.executar();
}

/// `true` quando o aviso "backup desatualizado" tem de aparecer: nunca
/// houve backup bem-sucedido, ou o último passou de 7 dias.
bool backupDesatualizado({
  required DateTime agora,
  required DateTime? ultimoSucessoEm,
}) =>
    ultimoSucessoEm == null ||
    agora.difference(ultimoSucessoEm) > prazoAvisoDesatualizado;

/// Intervalo do lembrete do código de recuperação (decisão 10 do owner:
/// a cada 90 dias, redigitar 2 grupos; dispensável, volta 90 dias depois).
const Duration intervaloLembreteCodigo = Duration(days: 90);

/// `true` quando o lembrete do código tem de aparecer: há código
/// confirmado e passaram 90 dias desde a última conferência (ou dispensa).
/// Sem data registrada não lembra — quem confirmou antes desta regra ganha
/// a data na primeira abertura.
bool lembreteDoCodigoDevido({
  required DateTime agora,
  required bool codigoConfirmado,
  required DateTime? conferidoEm,
}) =>
    codigoConfirmado &&
    conferidoEm != null &&
    agora.difference(conferidoEm) >= intervaloLembreteCodigo;
