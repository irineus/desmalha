import 'porta_auth.dart';

/// Troca de e-mail em curso.
///
/// O e-mail É a conta, então trocá-lo exige confirmação nos DOIS endereços: o
/// atual (para provar que quem pede tem a conta) e o novo (para provar que a
/// caixa de destino existe e é de quem pede). Uma confirmação só bastaria para
/// sequestrar a conta a partir de uma sessão esquecida aberta.
class TrocaEmailEmCurso {
  const TrocaEmailEmCurso({
    required this.emailAtual,
    required this.emailNovo,
    required this.solicitadaEm,
    this.confirmadoAtual = false,
    this.confirmadoNovo = false,
  });

  final String emailAtual;
  final String emailNovo;
  final DateTime solicitadaEm;

  /// Lados já confirmados NESTA execução do app.
  ///
  /// O provedor não expõe qual dos dois lados já respondeu — só que existe uma
  /// troca pendente. Depois de reabrir o app, os dois voltam a `false` e a tela
  /// pede os dois códigos de novo; o lado já confirmado responde "código
  /// inválido", que é ruim de UX mas honesto. Preferimos isso a marcar como
  /// confirmado o que não temos como saber.
  final bool confirmadoAtual;
  final bool confirmadoNovo;

  bool get concluidaLocalmente => confirmadoAtual && confirmadoNovo;

  TrocaEmailEmCurso copiarCom({bool? confirmadoAtual, bool? confirmadoNovo}) =>
      TrocaEmailEmCurso(
        emailAtual: emailAtual,
        emailNovo: emailNovo,
        solicitadaEm: solicitadaEm,
        confirmadoAtual: confirmadoAtual ?? this.confirmadoAtual,
        confirmadoNovo: confirmadoNovo ?? this.confirmadoNovo,
      );
}

/// Onde o usuário está no fluxo de autenticação.
sealed class EstadoAuth {
  const EstadoAuth();
}

/// Sem sessão. Ponto de partida e destino do logout.
class Deslogado extends EstadoAuth {
  const Deslogado();
}

/// Código enviado, aguardando digitação.
class AguardandoCodigo extends EstadoAuth {
  const AguardandoCodigo({required this.email, required this.enviadoEm});

  final String email;
  final DateTime enviadoEm;

  DateTime get expiraEm => enviadoEm.add(validadeCodigoOtp);

  /// Instante a partir do qual o reenvio é permitido.
  DateTime get liberaReenvioEm => enviadoEm.add(intervaloReenvioOtp);

  bool expiradoEm(DateTime agora) => !agora.isBefore(expiraEm);

  bool podeReenviarEm(DateTime agora) => !agora.isBefore(liberaReenvioEm);
}

/// Sessão ativa. [troca] só é preenchida enquanto houver troca de e-mail
/// pendente de confirmação.
class Autenticado extends EstadoAuth {
  const Autenticado(this.usuario, {this.troca});

  final UsuarioAutenticado usuario;
  final TrocaEmailEmCurso? troca;

  Autenticado copiarCom({
    UsuarioAutenticado? usuario,
    TrocaEmailEmCurso? troca,
    bool limparTroca = false,
  }) => Autenticado(
    usuario ?? this.usuario,
    troca: limparTroca ? null : (troca ?? this.troca),
  );
}
