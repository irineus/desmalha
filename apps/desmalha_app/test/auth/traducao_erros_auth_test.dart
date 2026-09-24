import 'package:desmalha_app/auth/porta_auth.dart';
import 'package:desmalha_app/auth/porta_auth_supabase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  FalhaAuth traduzir(AuthException e) => PortaAuthSupabase.traduzirErroAuth(e);

  group('rede × servidor', () {
    test('sem resposta (sem statusCode): é a conexão', () {
      final f = traduzir(
        AuthRetryableFetchException(message: 'SocketException: Failed host'),
      );
      expect(f.motivo, MotivoFalhaAuth.redeIndisponivel);
      expect(f.mensagem, contains('Verifique sua conexão'));
    });

    test('500 do servidor (e-mail do código recusado): NÃO é a conexão', () {
      // O caso do S23 em 24/09/2026: o SDK embrulha o 500 como "retryable".
      final f = traduzir(
        AuthRetryableFetchException(
          message:
              '{"code":500,"error_code":"unexpected_failure",'
              '"msg":"Error sending confirmation email"}',
          statusCode: '500',
        ),
      );
      expect(f.motivo, MotivoFalhaAuth.servidorComErro);
      expect(f.mensagem, contains('erro 500'));
      expect(f.mensagem, isNot(contains('conexão')));
    });

    test('504 do gateway: servidor', () {
      expect(
        traduzir(AuthRetryableFetchException(statusCode: '504')).motivo,
        MotivoFalhaAuth.servidorComErro,
      );
    });
  });

  group('conta excluída (banida até o expurgo)', () {
    test(
      'user_banned: diz que a conta foi excluída, não "código inválido"',
      () {
        final f = traduzir(
          const AuthApiException(
            'User is banned',
            statusCode: '403',
            code: 'user_banned',
          ),
        );
        expect(f.motivo, MotivoFalhaAuth.contaExcluida);
        expect(f.mensagem, contains('foi excluída'));
        expect(f.mensagem, contains('30 dias'));
        expect(f.mensagem, isNot(contains('inválido')));
      },
    );

    test('403 sem código conhecido continua sendo código inválido', () {
      expect(
        traduzir(
          const AuthApiException(
            'Token has expired or is invalid',
            statusCode: '403',
          ),
        ).motivo,
        MotivoFalhaAuth.codigoInvalido,
      );
    });
  });

  test('limite de envio continua com a própria mensagem', () {
    expect(
      traduzir(
        const AuthApiException(
          'rate',
          statusCode: '429',
          code: 'over_email_send_rate_limit',
        ),
      ).motivo,
      MotivoFalhaAuth.limiteExcedido,
    );
  });
}
