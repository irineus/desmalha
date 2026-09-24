/// [PortaNotificacoes] sobre o `flutter_local_notifications`.
///
/// O agendamento vai em UTC (`tz.UTC`): o instante absoluto já foi calculado
/// na hora local do aparelho, e o lembrete não repete por componente de
/// data — então não precisa da base de fusos nem de descobrir o fuso do
/// aparelho. O reagendamento depois de reiniciar o aparelho é do próprio
/// plugin (`ScheduledNotificationBootReceiver`, no AndroidManifest).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'porta_notificacoes.dart';

/// Canal Android dos lembretes de vencimento.
const String canalLembreteDarf = 'lembrete_darf';

class PortaNotificacoesLocais implements PortaNotificacoes {
  PortaNotificacoesLocais([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _inicializado = false;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> inicializar() async {
    if (_inicializado) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Sem pedir nada no boot: a permissão é pedida por ação do usuário.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _inicializado = true;
  }

  @override
  Future<bool> permitidas() async {
    await inicializar();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _android?.areNotificationsEnabled() ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return (await _ios?.checkPermissions())?.isEnabled ?? false;
    }
    return false;
  }

  @override
  Future<bool> pedirPermissao() async {
    await inicializar();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _android?.requestNotificationsPermission() ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _ios?.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }

  @override
  Future<Set<int>> agendadas() async {
    await inicializar();
    return {for (final p in await _plugin.pendingNotificationRequests()) p.id};
  }

  @override
  Future<void> cancelar(int id) async {
    await inicializar();
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> agendar({
    required int id,
    required DateTime instante,
    required String titulo,
    required String corpo,
  }) async {
    await inicializar();
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(instante.toUtc(), tz.UTC),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          canalLembreteDarf,
          'Vencimento do DARF',
          channelDescription:
              'Aviso de vencimento do carnê-leão: 3 dias antes e no dia.',
          styleInformation: BigTextStyleInformation(corpo),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: titulo,
      body: corpo,
    );
  }
}
