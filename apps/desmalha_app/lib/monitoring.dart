import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Monitoramento de erros (Sentry), anônimo por construção.
///
/// O DSN entra por `--dart-define=SENTRY_DSN=...` (variável cifrada do
/// Codemagic em builds de release). Sem DSN — dev, testes e CI de
/// verificação — o app sobe direto, sem inicializar o SDK e sem tráfego
/// de telemetria.
///
/// Restrições que este módulo garante (claim "nem nós conseguimos ver
/// seus dados"): nenhum PII, nenhuma captura de tela ou hierarquia de
/// views, nenhum usuário identificado. Dado fiscal nunca pode aparecer
/// em mensagem de erro ou breadcrumb; exceções de código fiscal devem
/// carregar apenas tipo e contexto estrutural, nunca valores.
const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

/// Ambiente reportado ao Sentry (ex.: `production`, `staging`).
const String sentryEnvironment = String.fromEnvironment(
  'SENTRY_ENVIRONMENT',
  defaultValue: 'production',
);

/// Monitoramento só liga quando um DSN foi injetado no build.
bool get monitoringEnabled => sentryDsn.isNotEmpty;

/// Sobe o app, com Sentry na frente quando habilitado.
Future<void> bootstrap(FutureOr<void> Function() appRunner) async {
  if (!monitoringEnabled) {
    await appRunner();
    return;
  }
  await SentryFlutter.init(
    (options) => configureMonitoring(
      options,
      dsn: sentryDsn,
      environment: sentryEnvironment,
    ),
    appRunner: appRunner,
  );
}

/// Configuração anônima do SDK. Separada do [bootstrap] para ser
/// verificável em teste sem inicializar o Sentry de verdade.
@visibleForTesting
void configureMonitoring(
  SentryFlutterOptions options, {
  required String dsn,
  required String environment,
}) {
  options.dsn = dsn;
  options.environment = environment;

  // Anônimo: sem IP, sem usuário, sem imagem da tela do usuário.
  options.sendDefaultPii = false;
  options.attachScreenshot = false;
  // ignore: experimental_member_use — garantia explícita mesmo sendo o default.
  options.attachViewHierarchy = false;

  // Sem tracing de performance no MVP — só crash/erro.
  options.tracesSampleRate = null;

  // Defesa em profundidade: mesmo que algum código venha a popular o
  // usuário no escopo, o evento sai sem identidade.
  options.beforeSend = stripIdentity;
}

/// Remove identidade do evento antes do envio.
@visibleForTesting
FutureOr<SentryEvent?> stripIdentity(SentryEvent event, Hint hint) {
  event.user = null;
  event.serverName = null;
  return event;
}
