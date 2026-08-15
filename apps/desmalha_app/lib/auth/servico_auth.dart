import 'dart:async';

import 'estado_auth.dart';
import 'porta_auth.dart';

/// Regra prática de e-mail: algo, arroba, domínio com ponto, sem espaço.
///
/// Não tenta implementar a RFC 5322 — validação de e-mail no cliente serve
/// para pegar erro de digitação antes de gastar um envio, não para decidir
/// quem existe. Quem decide isso é a caixa postal que recebe (ou não) o código.
final RegExp _formatoEmail = RegExp(r'^[^@\s]+@[^@\s.]+(\.[^@\s.]+)+$');

final RegExp _somenteDigitos = RegExp(r'^\d+$');

/// Orquestra o login por código de e-mail e a troca de e-mail da conta.
///
/// Toda a política do cliente mora aqui: formato do e-mail, tamanho do código,
/// janela de validade, intervalo de reenvio e a conferência final da troca de
/// e-mail. A [PortaAuth] só executa.
///
/// ⚠️ Não existe — e não pode passar a existir — nenhum caminho com senha ou
/// provedor social. Ver `porta_auth.dart` e o teste
/// `test/auth/trava_sem_senha_test.dart`.
class ServicoAutenticacao {
  ServicoAutenticacao(this._porta, {DateTime Function()? relogio})
    : _relogio = relogio ?? DateTime.now {
    final usuario = _porta.usuarioAtual;
    _estado = usuario == null ? const Deslogado() : _autenticadoDe(usuario);
    _assinatura = _porta.mudancas.listen(_aoMudarSessao);
  }

  final PortaAuth _porta;
  final DateTime Function() _relogio;
  final _emissor = StreamController<EstadoAuth>.broadcast();
  late StreamSubscription<UsuarioAutenticado?> _assinatura;
  late EstadoAuth _estado;

  EstadoAuth get estado => _estado;

  /// Emite a cada transição. Não reemite o estado atual na inscrição — quem se
  /// inscreve deve ler [estado] primeiro.
  Stream<EstadoAuth> get mudancas => _emissor.stream;

  Future<void> descartar() async {
    await _assinatura.cancel();
    await _emissor.close();
  }

  // ─── Login ────────────────────────────────────────────────────────────────

  /// Envia o código de acesso para [email].
  ///
  /// Cadastro e login são o mesmo gesto: sem senha, não há o que diferenciar.
  Future<void> enviarCodigo(String email) async {
    final normalizado = normalizarEmail(email);
    if (!_formatoEmail.hasMatch(normalizado)) {
      throw const FalhaAuth(
        MotivoFalhaAuth.emailInvalido,
        'E-mail inválido. Confira o endereço digitado.',
      );
    }
    _exigirIntervaloDeReenvio(normalizado);
    await _porta.enviarCodigo(normalizado);
    _trocarEstado(AguardandoCodigo(email: normalizado, enviadoEm: _relogio()));
  }

  /// Reenvia o código para o mesmo e-mail do estado corrente.
  Future<void> reenviarCodigo() async {
    final atual = _estado;
    if (atual is! AguardandoCodigo) {
      throw const FalhaAuth(
        MotivoFalhaAuth.desconhecido,
        'Não há envio em andamento para reenviar.',
      );
    }
    await enviarCodigo(atual.email);
  }

  /// Troca o código digitado por uma sessão.
  Future<UsuarioAutenticado> verificarCodigo(String codigo) async {
    final atual = _estado;
    if (atual is! AguardandoCodigo) {
      throw const FalhaAuth(
        MotivoFalhaAuth.desconhecido,
        'Peça um código antes de confirmar.',
      );
    }
    final limpo = _exigirCodigoBemFormado(codigo);
    if (atual.expiradoEm(_relogio())) {
      throw const FalhaAuth(
        MotivoFalhaAuth.codigoExpirado,
        'O código expirou. Peça um novo.',
      );
    }
    final usuario = await _porta.verificarCodigo(
      email: atual.email,
      codigo: limpo,
    );
    _trocarEstado(_autenticadoDe(usuario));
    return usuario;
  }

  /// Desiste do código pedido e volta à tela de e-mail.
  ///
  /// Não fala com o servidor: não há sessão para encerrar, e um `sair()` sem
  /// sessão só produziria um erro para a tela mostrar sem motivo. O código já
  /// enviado continua válido até expirar sozinho, do lado do provedor.
  void cancelarEnvio() {
    if (_estado is! AguardandoCodigo) return;
    _trocarEstado(const Deslogado());
  }

  Future<void> sair() async {
    await _porta.sair();
    _trocarEstado(const Deslogado());
  }

  // ─── Troca de e-mail ──────────────────────────────────────────────────────

  /// Pede a troca do e-mail da conta para [novoEmail].
  ///
  /// Dispara códigos para os dois endereços. A troca só vale depois de
  /// [confirmarTrocaEmail] com o código de cada um.
  Future<void> solicitarTrocaEmail(String novoEmail) async {
    final autenticado = _exigirAutenticado();
    final normalizado = normalizarEmail(novoEmail);
    if (!_formatoEmail.hasMatch(normalizado)) {
      throw const FalhaAuth(
        MotivoFalhaAuth.emailInvalido,
        'E-mail inválido. Confira o endereço digitado.',
      );
    }
    if (normalizado == autenticado.usuario.email) {
      throw const FalhaAuth(
        MotivoFalhaAuth.emailInvalido,
        'O novo e-mail é igual ao atual.',
      );
    }
    await _porta.solicitarTrocaEmail(normalizado);
    _trocarEstado(
      autenticado.copiarCom(
        troca: TrocaEmailEmCurso(
          emailAtual: autenticado.usuario.email,
          emailNovo: normalizado,
          solicitadaEm: _relogio(),
        ),
      ),
    );
  }

  /// Confirma um dos lados da troca com o código recebido em [email].
  ///
  /// Retorna `true` quando os dois lados já confirmaram E o servidor confirmou
  /// a troca. A conferência final não é opcional: o sucesso das duas chamadas
  /// não prova que o e-mail mudou — só releitura prova. Se não bater, falha
  /// visível, em vez de dizer ao usuário que o login dele agora é outro.
  Future<bool> confirmarTrocaEmail({
    required String email,
    required String codigo,
  }) async {
    final autenticado = _exigirAutenticado();
    final troca = autenticado.troca;
    if (troca == null) {
      throw const FalhaAuth(
        MotivoFalhaAuth.desconhecido,
        'Não há troca de e-mail em andamento.',
      );
    }
    final alvo = normalizarEmail(email);
    final ehAtual = alvo == troca.emailAtual;
    final ehNovo = alvo == troca.emailNovo;
    if (!ehAtual && !ehNovo) {
      throw const FalhaAuth(
        MotivoFalhaAuth.emailInvalido,
        'Este endereço não faz parte da troca em andamento.',
      );
    }
    final limpo = _exigirCodigoBemFormado(codigo);
    if (!_relogio().isBefore(troca.solicitadaEm.add(validadeCodigoOtp))) {
      throw const FalhaAuth(
        MotivoFalhaAuth.codigoExpirado,
        'Os códigos da troca expiraram. Peça a troca de novo.',
      );
    }

    await _porta.confirmarTrocaEmail(email: alvo, codigo: limpo);
    final andamento = troca.copiarCom(
      confirmadoAtual: ehAtual ? true : null,
      confirmadoNovo: ehNovo ? true : null,
    );

    if (!andamento.concluidaLocalmente) {
      _trocarEstado(autenticado.copiarCom(troca: andamento));
      return false;
    }

    final relido = await _porta.recarregarUsuario();
    if (relido == null) {
      throw const FalhaAuth(
        MotivoFalhaAuth.naoAutenticado,
        'A sessão terminou durante a troca de e-mail. Entre de novo.',
      );
    }
    if (relido.email != troca.emailNovo) {
      _trocarEstado(Autenticado(relido, troca: andamento));
      throw const FalhaAuth(
        MotivoFalhaAuth.desconhecido,
        'As duas confirmações foram aceitas, mas o servidor ainda mantém o '
        'e-mail antigo. Confira sua caixa de entrada e tente de novo.',
      );
    }
    _trocarEstado(Autenticado(relido));
    return true;
  }

  // ─── Internos ─────────────────────────────────────────────────────────────

  /// Espaço em volta e caixa alta são erro de digitação, não identidade nova.
  static String normalizarEmail(String email) => email.trim().toLowerCase();

  String _exigirCodigoBemFormado(String codigo) {
    // Espaços entram sozinhos quando o usuário cola o código do e-mail.
    final limpo = codigo.replaceAll(RegExp(r'\s'), '');
    if (limpo.length != tamanhoCodigoOtp || !_somenteDigitos.hasMatch(limpo)) {
      throw FalhaAuth(
        MotivoFalhaAuth.codigoMalFormado,
        'O código tem $tamanhoCodigoOtp dígitos.',
      );
    }
    return limpo;
  }

  Autenticado _exigirAutenticado() {
    final atual = _estado;
    if (atual is! Autenticado) {
      throw const FalhaAuth(
        MotivoFalhaAuth.naoAutenticado,
        'Entre na sua conta para continuar.',
      );
    }
    return atual;
  }

  void _exigirIntervaloDeReenvio(String email) {
    final atual = _estado;
    if (atual is! AguardandoCodigo || atual.email != email) return;
    final agora = _relogio();
    if (atual.podeReenviarEm(agora)) return;
    final faltam = atual.liberaReenvioEm.difference(agora).inSeconds + 1;
    throw FalhaAuth(
      MotivoFalhaAuth.limiteExcedido,
      'Aguarde $faltam segundos para pedir outro código.',
    );
  }

  Autenticado _autenticadoDe(UsuarioAutenticado usuario) {
    final pendente = usuario.emailPendente;
    if (pendente == null) return Autenticado(usuario);
    // Sessão retomada com troca pendente: sabemos que existe, não sabemos qual
    // lado já respondeu. Ver TrocaEmailEmCurso.confirmadoAtual.
    return Autenticado(
      usuario,
      troca: TrocaEmailEmCurso(
        emailAtual: usuario.email,
        emailNovo: pendente,
        solicitadaEm: _relogio(),
      ),
    );
  }

  void _aoMudarSessao(UsuarioAutenticado? usuario) {
    if (usuario == null) {
      if (_estado is Deslogado) return;
      _trocarEstado(const Deslogado());
      return;
    }
    final atual = _estado;
    // Refresh de token não pode apagar a troca de e-mail em andamento.
    if (atual is Autenticado) {
      _trocarEstado(atual.copiarCom(usuario: usuario));
      return;
    }
    _trocarEstado(_autenticadoDe(usuario));
  }

  void _trocarEstado(EstadoAuth novo) {
    _estado = novo;
    if (!_emissor.isClosed) _emissor.add(novo);
  }
}
