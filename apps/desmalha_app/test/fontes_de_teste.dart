import 'package:flutter_test/flutter_test.dart';

/// Drena o aviso "fontes do sistema mudaram" que o motor emite depois de um
/// `FontLoader.load()`.
///
/// Desde o Flutter 3.50, `loadFontFromList` dispara a mensagem de sistema
/// `fontsChange` de forma assíncrona REAL (fora do relógio falso do
/// `testWidgets`). Ao chegar, ela agenda um frame de relayout; se o teste
/// termina antes, o harness reprova com "An animation is still running even
/// after the widget tree was disposed". Aqui deixamos o event loop real
/// entregar a mensagem e então bombeamos o frame que ela agendou.
Future<void> drenarAvisoDeFontes(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
}
