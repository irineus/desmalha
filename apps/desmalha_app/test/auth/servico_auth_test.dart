import 'package:desmalha_app/auth/estado_auth.dart';
import 'package:desmalha_app/auth/porta_auth.dart';
import 'package:desmalha_app/auth/servico_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'porta_auth_falsa.dart';

void main() {
  late PortaAuthFalsa porta;
  late DateTime agora;
  late ServicoAutenticacao servico;

  setUp(() {
    porta = PortaAuthFalsa();
    agora = DateTime.utc(2026, 8, 15, 12);
    servico = ServicoAutenticacao(porta, relogio: () => agora);
  });

  tearDown(() async {
    await servico.descartar();
    await porta.fechar();
  });

  Future<void> entrar({String email = 'pessoa@exemplo.com'}) async {
    await servico.enviarCodigo(email);
    await servico.verificarCodigo('12345678');
  }

  group('envio do código', () {
    test('normaliza o e-mail antes de mandar para o provedor', () async {
      await servico.enviarCodigo('  Pessoa@Exemplo.COM ');

      expect(porta.argumentos['enviarCodigo']!['email'], 'pessoa@exemplo.com');
      expect(servico.estado, isA<AguardandoCodigo>());
      expect((servico.estado as AguardandoCodigo).email, 'pessoa@exemplo.com');
    });

    test('recusa e-mail malformado sem tocar na rede', () async {
      await expectLater(
        servico.enviarCodigo('pessoa@sem-dominio'),
        throwsA(
          isA<FalhaAuth>().having(
            (f) => f.motivo,
            'motivo',
            MotivoFalhaAuth.emailInvalido,
          ),
        ),
      );
      expect(porta.chamadas, isEmpty);
    });

    test('segura o reenvio dentro do intervalo e libera depois', () async {
      await servico.enviarCodigo('pessoa@exemplo.com');

      agora = agora.add(const Duration(seconds: 30));
      await expectLater(
        servico.reenviarCodigo(),
        throwsA(
          isA<FalhaAuth>().having(
            (f) => f.motivo,
            'motivo',
            MotivoFalhaAuth.limiteExcedido,
          ),
        ),
      );
      expect(porta.chamadas, ['enviarCodigo']);

      agora = agora.add(intervaloReenvioOtp);
      await servico.reenviarCodigo();
      expect(porta.chamadas, ['enviarCodigo', 'enviarCodigo']);
    });
  });

  group('verificação do código', () {
    test('exige exatamente $tamanhoCodigoOtp dígitos', () async {
      await servico.enviarCodigo('pessoa@exemplo.com');

      for (final ruim in ['123456', '123456789', 'abcdefgh', '1234567a']) {
        await expectLater(
          servico.verificarCodigo(ruim),
          throwsA(
            isA<FalhaAuth>().having(
              (f) => f.motivo,
              'motivo',
              MotivoFalhaAuth.codigoMalFormado,
            ),
          ),
          reason: 'código "$ruim" deveria ser recusado localmente',
        );
      }
      expect(porta.chamadas, ['enviarCodigo']);
    });

    test('tolera espaços colados junto com o código', () async {
      await servico.enviarCodigo('pessoa@exemplo.com');
      await servico.verificarCodigo(' 1234 5678 ');

      expect(porta.argumentos['verificarCodigo']!['codigo'], '12345678');
      expect(servico.estado, isA<Autenticado>());
    });

    test('recusa código depois da janela de ${validadeCodigoOtp.inSeconds}s '
        'sem gastar chamada', () async {
      await servico.enviarCodigo('pessoa@exemplo.com');
      agora = agora.add(validadeCodigoOtp);

      await expectLater(
        servico.verificarCodigo('12345678'),
        throwsA(
          isA<FalhaAuth>().having(
            (f) => f.motivo,
            'motivo',
            MotivoFalhaAuth.codigoExpirado,
          ),
        ),
      );
      expect(porta.chamadas, ['enviarCodigo']);
    });

    test('aceita no último instante da janela', () async {
      await servico.enviarCodigo('pessoa@exemplo.com');
      agora = agora.add(validadeCodigoOtp - const Duration(seconds: 1));

      await servico.verificarCodigo('12345678');
      expect(servico.estado, isA<Autenticado>());
    });

    test('não verifica sem envio anterior', () async {
      await expectLater(
        servico.verificarCodigo('12345678'),
        throwsA(isA<FalhaAuth>()),
      );
      expect(porta.chamadas, isEmpty);
    });
  });

  group('sessão', () {
    test('sair volta ao estado deslogado', () async {
      await entrar();
      await servico.sair();

      expect(servico.estado, isA<Deslogado>());
      expect(porta.chamadas.last, 'sair');
    });

    test('sessão pré-existente nasce autenticada', () async {
      final outra = PortaAuthFalsa(
        usuarioInicial: const UsuarioAutenticado(
          id: 'uid',
          email: 'pessoa@exemplo.com',
        ),
      );
      final servicoRetomado = ServicoAutenticacao(outra);
      expect(servicoRetomado.estado, isA<Autenticado>());
      await servicoRetomado.descartar();
      await outra.fechar();
    });

    test('refresh de token não apaga a troca de e-mail em andamento', () async {
      await entrar();
      await servico.solicitarTrocaEmail('novo@exemplo.com');

      porta.emitirSessao(
        const UsuarioAutenticado(
          id: 'uid-teste',
          email: 'pessoa@exemplo.com',
          emailPendente: 'novo@exemplo.com',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect((servico.estado as Autenticado).troca, isNotNull);
    });

    test('sessão retomada com troca pendente reconstrói o andamento', () async {
      final outra = PortaAuthFalsa(
        usuarioInicial: const UsuarioAutenticado(
          id: 'uid',
          email: 'pessoa@exemplo.com',
          emailPendente: 'novo@exemplo.com',
        ),
      );
      final retomado = ServicoAutenticacao(outra);

      final troca = (retomado.estado as Autenticado).troca;
      expect(troca, isNotNull);
      expect(troca!.emailNovo, 'novo@exemplo.com');
      // Nenhum lado é dado como confirmado: o provedor não diz qual respondeu.
      expect(troca.confirmadoAtual, isFalse);
      expect(troca.confirmadoNovo, isFalse);

      await retomado.descartar();
      await outra.fechar();
    });
  });

  group('troca de e-mail', () {
    test('exige sessão', () async {
      await expectLater(
        servico.solicitarTrocaEmail('novo@exemplo.com'),
        throwsA(
          isA<FalhaAuth>().having(
            (f) => f.motivo,
            'motivo',
            MotivoFalhaAuth.naoAutenticado,
          ),
        ),
      );
      expect(porta.chamadas, isEmpty);
    });

    test('recusa trocar para o mesmo endereço', () async {
      await entrar();
      await expectLater(
        servico.solicitarTrocaEmail('PESSOA@exemplo.com'),
        throwsA(
          isA<FalhaAuth>().having(
            (f) => f.motivo,
            'motivo',
            MotivoFalhaAuth.emailInvalido,
          ),
        ),
      );
      expect(porta.chamadas, isNot(contains('solicitarTrocaEmail')));
    });

    test('só conclui depois de confirmar nos DOIS endereços', () async {
      await entrar();
      await servico.solicitarTrocaEmail('novo@exemplo.com');

      final soUm = await servico.confirmarTrocaEmail(
        email: 'pessoa@exemplo.com',
        codigo: '11111111',
      );
      expect(soUm, isFalse, reason: 'uma confirmação não pode bastar');
      expect(porta.chamadas, isNot(contains('recarregarUsuario')));

      final troca = (servico.estado as Autenticado).troca!;
      expect(troca.confirmadoAtual, isTrue);
      expect(troca.confirmadoNovo, isFalse);

      porta.recargaProgramada = () =>
          const UsuarioAutenticado(id: 'uid-teste', email: 'novo@exemplo.com');
      final concluida = await servico.confirmarTrocaEmail(
        email: 'novo@exemplo.com',
        codigo: '22222222',
      );

      expect(concluida, isTrue);
      expect(porta.chamadas, contains('recarregarUsuario'));
      final estado = servico.estado as Autenticado;
      expect(estado.usuario.email, 'novo@exemplo.com');
      expect(estado.troca, isNull);
    });

    test('recusa código de endereço fora da troca', () async {
      await entrar();
      await servico.solicitarTrocaEmail('novo@exemplo.com');

      await expectLater(
        servico.confirmarTrocaEmail(
          email: 'terceiro@exemplo.com',
          codigo: '11111111',
        ),
        throwsA(isA<FalhaAuth>()),
      );
      expect(porta.chamadas, isNot(contains('confirmarTrocaEmail')));
    });

    test('falha visível quando o servidor mantém o e-mail antigo', () async {
      await entrar();
      await servico.solicitarTrocaEmail('novo@exemplo.com');
      await servico.confirmarTrocaEmail(
        email: 'pessoa@exemplo.com',
        codigo: '11111111',
      );

      // O servidor aceitou os dois códigos mas não efetivou a troca.
      porta.recargaProgramada = () => const UsuarioAutenticado(
        id: 'uid-teste',
        email: 'pessoa@exemplo.com',
        emailPendente: 'novo@exemplo.com',
      );

      await expectLater(
        servico.confirmarTrocaEmail(
          email: 'novo@exemplo.com',
          codigo: '22222222',
        ),
        throwsA(isA<FalhaAuth>()),
      );
      // O estado NÃO pode dizer que o login virou o e-mail novo.
      expect((servico.estado as Autenticado).usuario.email, 'pessoa@exemplo.com');
    });

    test('códigos da troca também expiram em ${validadeCodigoOtp.inSeconds}s',
        () async {
      await entrar();
      await servico.solicitarTrocaEmail('novo@exemplo.com');
      agora = agora.add(validadeCodigoOtp);

      await expectLater(
        servico.confirmarTrocaEmail(
          email: 'novo@exemplo.com',
          codigo: '11111111',
        ),
        throwsA(
          isA<FalhaAuth>().having(
            (f) => f.motivo,
            'motivo',
            MotivoFalhaAuth.codigoExpirado,
          ),
        ),
      );
      expect(porta.chamadas, isNot(contains('confirmarTrocaEmail')));
    });
  });

  test('o fluxo completo só usa os métodos de código de e-mail', () async {
    await entrar();
    await servico.solicitarTrocaEmail('novo@exemplo.com');
    await servico.confirmarTrocaEmail(
      email: 'pessoa@exemplo.com',
      codigo: '11111111',
    );
    porta.recargaProgramada = () =>
        const UsuarioAutenticado(id: 'uid-teste', email: 'novo@exemplo.com');
    await servico.confirmarTrocaEmail(
      email: 'novo@exemplo.com',
      codigo: '22222222',
    );
    await servico.sair();

    expect(porta.chamadas.toSet(), {
      'enviarCodigo',
      'verificarCodigo',
      'solicitarTrocaEmail',
      'confirmarTrocaEmail',
      'recarregarUsuario',
      'sair',
    });
  });
}
