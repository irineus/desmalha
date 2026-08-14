import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:desmalha_app/monitoring.dart';

void main() {
  test('sem SENTRY_DSN no build, o monitoramento fica desligado', () {
    // Testes rodam sem --dart-define, então este é o estado padrão do repo:
    // nenhum DSN embutido, nenhum SDK inicializado, nenhum tráfego.
    expect(sentryDsn, isEmpty);
    expect(monitoringEnabled, isFalse);
  });

  test('bootstrap sem DSN executa o app direto, sem inicializar o Sentry',
      () async {
    var ran = false;
    await bootstrap(() => ran = true);
    expect(ran, isTrue);
    expect(Sentry.isEnabled, isFalse);
  });

  test('configuração do SDK é anônima por construção', () {
    final options = SentryFlutterOptions();
    configureMonitoring(
      options,
      dsn: 'https://key@sentry.example/1',
      environment: 'production',
    );

    expect(options.dsn, 'https://key@sentry.example/1');
    expect(options.environment, 'production');

    // Garantias do claim "nem nós conseguimos ver seus dados".
    expect(options.sendDefaultPii, isFalse);
    expect(options.attachScreenshot, isFalse);
    // ignore: experimental_member_use
    expect(options.attachViewHierarchy, isFalse);

    // Sem tracing de performance no MVP.
    expect(options.tracesSampleRate, isNull);

    expect(options.beforeSend, isNotNull);
  });

  test('beforeSend remove identidade do evento', () async {
    final event = SentryEvent(
      user: SentryUser(id: 'abc', email: 'x@y.z', ipAddress: '1.2.3.4'),
      serverName: 'device-name',
    );

    final result = await stripIdentity(event, Hint());

    expect(result, isNotNull);
    expect(result!.user, isNull);
    expect(result.serverName, isNull);
  });
}
