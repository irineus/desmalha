/// Porta de autenticação: a fronteira entre o app e o provedor de identidade.
///
/// Existe por dois motivos, nesta ordem de importância:
///
/// 1. **Reduzir a superfície da trava anti-senha.** A decisão do projeto é OTP
///    por e-mail, SEM SENHA, e o Supabase não tem toggle para desativar login
///    por senha — a garantia primária é do código do app. Concentrar o SDK num
///    único arquivo transforma "o app inteiro precisa ser auditado" em "um
///    arquivo precisa ser auditado", e é isso que o teste
///    `test/auth/trava_sem_senha_test.dart` verifica a cada execução.
/// 2. Tornar o serviço de autenticação testável sem rede e sem
///    `Supabase.initialize`.
///
/// Repare no que esta interface NÃO tem: nenhum método aceita senha, nenhum
/// método fala de provedor social. O que não existe na porta não pode ser
/// chamado por engano lá na frente.
library;

/// Identidade do usuário autenticado, reduzida ao que o app precisa.
///
/// Sem CPF, sem nome, sem dado fiscal: o servidor nunca precisou disso e a
/// modelagem de `public.perfis` deliberadamente não guarda.
class UsuarioAutenticado {
  const UsuarioAutenticado({
    required this.id,
    required this.email,
    this.emailPendente,
  });

  /// `auth.users.id` — a mesma chave de `public.perfis.id`.
  final String id;

  /// E-mail em vigor. É a conta: não há outro identificador de login.
  final String email;

  /// E-mail novo aguardando confirmação, quando há troca em curso.
  ///
  /// Enquanto não for `null`, a troca ainda não terminou — os dois endereços
  /// precisam confirmar.
  final String? emailPendente;

  @override
  String toString() =>
      'UsuarioAutenticado(id: $id, email: $email, emailPendente: $emailPendente)';
}

/// Motivo de uma falha de autenticação, já traduzido do jargão do provedor.
///
/// A distinção entre [codigoInvalido] e [codigoExpirado] importa para a UI:
/// "código errado" pede recomeçar a digitação, "código expirado" pede reenvio.
enum MotivoFalhaAuth {
  /// E-mail em formato inválido (barrado antes de sair do aparelho).
  emailInvalido,

  /// Código fora do formato esperado (não são [tamanhoCodigoOtp] dígitos).
  codigoMalFormado,

  /// Código não confere com o que o servidor emitiu.
  codigoInvalido,

  /// Código passou da janela de validade.
  codigoExpirado,

  /// Provedor recusou por excesso de tentativas ou reenvios.
  limiteExcedido,

  /// A requisição não chegou ao servidor (sem rede, DNS, tempo esgotado).
  redeIndisponivel,

  /// O servidor respondeu com erro (5xx) — a rede está boa; o problema é
  /// do outro lado (ex.: o provedor de e-mail recusou o envio do código).
  servidorComErro,

  /// A conta deste e-mail foi excluída e está na carência de 30 dias da
  /// Política de Privacidade: o acesso fica bloqueado até o expurgo.
  contaExcluida,

  /// O e-mail novo da troca já pertence a outra conta.
  emailJaEmUso,

  /// Operação exigia sessão e não havia nenhuma.
  naoAutenticado,

  /// Falha que a porta não soube classificar.
  desconhecido,
}

/// Falha de autenticação com mensagem pronta para a tela.
class FalhaAuth implements Exception {
  const FalhaAuth(this.motivo, this.mensagem, {this.causa});

  final MotivoFalhaAuth motivo;

  /// Texto em português, endereçado ao usuário.
  ///
  /// Nunca carrega dado fiscal nem o código digitado — a mesma regra que vale
  /// para breadcrumb do Sentry vale aqui, porque mensagem de erro vaza para
  /// log e para tela compartilhada.
  final String mensagem;

  /// Erro original do provedor, para diagnóstico. Não vai para a tela.
  final Object? causa;

  @override
  String toString() => 'FalhaAuth(${motivo.name}): $mensagem';
}

/// Quantidade de dígitos do código enviado por e-mail.
///
/// ⚠️ Espelha uma configuração DE SERVIDOR (Supabase → Authentication →
/// Providers → Email → *Email OTP Length*). Ver `supabase/operacao/autenticacao.md`.
/// Se as duas divergirem, ninguém consegue entrar — falha visível, e não uma
/// conta criada em silêncio por um caminho que não deveria existir.
const int tamanhoCodigoOtp = 8;

/// Janela de validade do código, espelhando *Email OTP Expiration*.
const Duration validadeCodigoOtp = Duration(seconds: 600);

/// Intervalo mínimo entre dois envios para o mesmo e-mail.
///
/// O provedor também limita; a trava local existe para não gastar a cota de
/// e-mail nem levar o usuário a um erro que a tela poderia ter evitado.
const Duration intervaloReenvioOtp = Duration(seconds: 60);

/// Operações de identidade que o app precisa — e só elas.
abstract interface class PortaAuth {
  /// Dispara o código de acesso para [email], criando a conta se ainda não
  /// existir. Cadastro e login são o mesmo gesto quando não há senha.
  Future<void> enviarCodigo(String email);

  /// Troca o código pelo par de tokens da sessão.
  Future<UsuarioAutenticado> verificarCodigo({
    required String email,
    required String codigo,
  });

  /// Pede a troca do e-mail da conta.
  ///
  /// Com *Secure email change* ligado no provedor, isto dispara um código para
  /// o endereço ATUAL e outro para o NOVO: a troca só se completa com as duas
  /// confirmações. Ver `supabase/operacao/autenticacao.md`.
  Future<void> solicitarTrocaEmail(String novoEmail);

  /// Confirma um dos dois lados da troca de e-mail.
  ///
  /// [email] é o endereço que recebeu este código — o atual numa chamada, o
  /// novo na outra.
  Future<UsuarioAutenticado> confirmarTrocaEmail({
    required String email,
    required String codigo,
  });

  /// Relê a identidade direto do provedor, sem confiar no cache local.
  ///
  /// É o que permite conferir se a troca de e-mail de fato aconteceu, em vez
  /// de deduzir do sucesso das chamadas anteriores.
  Future<UsuarioAutenticado?> recarregarUsuario();

  /// Encerra a sessão neste aparelho.
  Future<void> sair();

  /// Sessão corrente, se houver, sem ida à rede.
  UsuarioAutenticado? get usuarioAtual;

  /// Emite a cada mudança de sessão (login, logout, refresh de token).
  Stream<UsuarioAutenticado?> get mudancas;
}
