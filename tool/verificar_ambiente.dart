// tool/verificar_ambiente.dart — verificador de ambiente de build do Desmalha.
//
// Roda igual no Windows, no Linux e no runner do Codemagic: Dart puro, só
// `dart:io`/`dart:convert`/`dart:async`, sem pubspec e sem dependência. É o par do
// `tool/setup_env.sh` — o script INSTALA (só Linux), este VERIFICA (todo lugar).
//
//   fvm dart run tool/verificar_ambiente.dart
//   fvm dart run tool/verificar_ambiente.dart --android    # exige aparelho/emulador Android
//
// Sai com 0 se tudo essencial confere, 1 se algo falhou. As versões esperadas não
// são escritas aqui: saem do `.fvmrc`, do `tool/setup_env.sh` e do `build.gradle.kts`,
// para que este arquivo não vire uma terceira cópia que envelhece em silêncio.
//
// Por que existe: sem ele, "o ambiente está certo" é uma afirmação que só vale para
// quem instalou, no dia em que instalou. Ambiente divergente não falha na hora —
// falha num build de release, meses depois, com outra versão de toolchain.
//
// Duas regras de construção, ambas aprendidas na marra:
//  - O Flutter é invocado pelo caminho do SDK EM USO, nunca por `fvm flutter`. Com um
//    `.fvmrc` apontando para versão não instalada, o fvm bloqueia tentando baixá-la e
//    o verificador pendura — justo no caso que ele existe para denunciar.
//  - Toda chamada externa tem limite de tempo. Verificador que trava é pior do que
//    verificador que reprova: um dá veredito, o outro só ocupa o terminal.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final exigirAndroid = args.contains('--android');
  if (args.any((a) => a == '-h' || a == '--help')) {
    stdout.writeln(
      'Uso: dart run tool/verificar_ambiente.dart [--android]\n\n'
      '  --android   além do resto, exige um aparelho ou emulador Android conectado\n'
      '              (é o critério do Bloco 3: hot reload precisa de alvo real).',
    );
    exit(0);
  }

  final raiz = _raizDoRepo();
  if (raiz == null) {
    stderr.writeln(
      'ERRO: não achei a raiz do repositório (procurei por .fvmrc subindo a partir '
      'de ${Directory.current.path}). Rode de dentro do repo.',
    );
    exit(1);
  }

  final r = _Relatorio();
  stdout.writeln('Desmalha — verificação de ambiente');
  stdout.writeln('repo: ${raiz.path}');
  stdout.writeln('so:   ${Platform.operatingSystem}');
  stdout.writeln('');

  final esperado = _lerEsperado(raiz, r);
  final sdkFlutter = await _verificarFlutter(raiz, esperado, r);
  await _verificarJdk(r);
  _verificarAndroidSdk(esperado, r);
  _verificarPinsDoGradle(esperado, r);
  await _verificarDispositivos(raiz, sdkFlutter, exigirAndroid, r);

  r.imprimirResumo();
  exit(r.falhou ? 1 : 0);
}

// --------------------------------------------------------------- valores esperados

/// Versões que o repositório já declara. Fonte única: `.fvmrc` para o Flutter,
/// as constantes do `tool/setup_env.sh` para o Android SDK e o `build.gradle.kts`
/// para as decisões travadas do Android.
class _Esperado {
  String? flutter;
  String? plataformaAndroid; // ex.: android-36
  String? buildTools; // ex.: 36.0.0
  String? ndk; // ex.: 28.2.13676358
  String? applicationId;
  int? minSdk;
}

_Esperado _lerEsperado(Directory raiz, _Relatorio r) {
  final e = _Esperado();
  final sep = Platform.pathSeparator;

  final fvmrc = File('${raiz.path}$sep.fvmrc');
  if (fvmrc.existsSync()) {
    try {
      final json = jsonDecode(fvmrc.readAsStringSync()) as Map<String, dynamic>;
      e.flutter = json['flutter'] as String?;
    } on FormatException catch (erro) {
      r.falha('.fvmrc', 'JSON inválido: $erro');
    }
  }
  if (e.flutter == null) {
    r.falha(
      '.fvmrc',
      'não declara a versão do Flutter — é a fonte da verdade do pin.',
    );
  }

  final setup = File('${raiz.path}${sep}tool${sep}setup_env.sh');
  if (setup.existsSync()) {
    final texto = setup.readAsStringSync();
    e.plataformaAndroid = _constanteShell(texto, 'ANDROID_PLATFORM');
    e.buildTools = _constanteShell(texto, 'BUILD_TOOLS');
    e.ndk = _constanteShell(texto, 'NDK_VERSION');

    // O setup_env.sh carrega a própria cópia da versão do Flutter e já falha se
    // divergir do .fvmrc. Repetimos a conferência: quem roda só o verificador
    // (Windows, onde o script não roda) precisa ver essa divergência também.
    final noSetup = _constanteShell(texto, 'FLUTTER_VERSION');
    if (noSetup != null && e.flutter != null && noSetup != e.flutter) {
      r.falha(
        'pin do Flutter',
        '.fvmrc pede ${e.flutter} mas tool/setup_env.sh pina $noSetup — alinhe os dois '
            '(a versão só muda por decisão registrada no board).',
      );
    }
  } else {
    r.falha(
      'tool/setup_env.sh',
      'ausente — dele saem as versões esperadas do Android SDK.',
    );
  }

  final gradle = File(
    '${raiz.path}${sep}apps${sep}desmalha_app${sep}android${sep}app${sep}build.gradle.kts',
  );
  if (gradle.existsSync()) {
    final texto = gradle.readAsStringSync();
    e.applicationId = RegExp(
      r'applicationId\s*=\s*"([^"]+)"',
    ).firstMatch(texto)?.group(1);
    final min = RegExp(r'minSdk\s*=\s*(\d+)').firstMatch(texto)?.group(1);
    e.minSdk = min == null ? null : int.tryParse(min);
  } else {
    r.falha('build.gradle.kts', 'ausente em apps/desmalha_app/android/app/.');
  }

  return e;
}

String? _constanteShell(String texto, String nome) =>
    RegExp('^$nome="([^"]*)"', multiLine: true).firstMatch(texto)?.group(1);

// ------------------------------------------------------------------------ Flutter

/// Verifica o pin e devolve a raiz do SDK do Flutter em uso (ou null).
Future<Directory?> _verificarFlutter(
  Directory raiz,
  _Esperado e,
  _Relatorio r,
) async {
  // O Dart que está executando este arquivo vem de dentro do SDK do Flutter:
  // <flutter>/bin/cache/dart-sdk/bin/dart. Subir quatro níveis a partir de `bin`
  // dá a raiz do SDK. Conferir por aí é mais forte do que perguntar ao `flutter`
  // do PATH: prova a versão REALMENTE em uso agora, não a que o PATH resolveria.
  var dir = File(
    Platform.resolvedExecutable,
  ).absolute.parent; // .../dart-sdk/bin
  for (var i = 0; i < 4; i++) {
    dir = dir.parent;
  }
  final sep = Platform.pathSeparator;
  final marcador = File(
    '${dir.path}${sep}bin${sep}cache${sep}flutter.version.json',
  );

  if (!marcador.existsSync()) {
    r.aviso(
      'Flutter (SDK em uso)',
      'este Dart não parece vir de um SDK do Flutter (${Platform.resolvedExecutable}). '
          'Rode via `fvm dart run` para que o pin seja conferido.',
    );
    return null;
  }

  String? emUso;
  try {
    final json =
        jsonDecode(marcador.readAsStringSync()) as Map<String, dynamic>;
    emUso = json['frameworkVersion'] as String?;
  } on FormatException {
    // cai no aviso abaixo
  }

  if (emUso == null) {
    r.aviso(
      'Flutter (SDK em uso)',
      'não consegui ler frameworkVersion de ${marcador.path}.',
    );
  } else if (e.flutter != null && emUso != e.flutter) {
    r.falha(
      'Flutter (SDK em uso)',
      'rodando $emUso, mas o .fvmrc pina ${e.flutter}. '
          'Rode `fvm install` e use `fvm flutter` / `fvm dart`.',
    );
  } else {
    r.ok('Flutter (SDK em uso)', '$emUso  (${dir.path})');
  }

  // Segunda conferência: o `flutter` que o PATH resolve. Um PATH apontando para
  // outro SDK não quebra este comando, mas quebra o build feito fora do fvm — no
  // Android Studio, por exemplo, que resolve o SDK por local.properties/PATH.
  final noPath = await _rodar('flutter', ['--version', '--machine'], raiz);
  switch (noPath.estado) {
    case _Estado.ausente:
      r.info(
        'Flutter (PATH)',
        'nenhum `flutter` no PATH — ok se você sempre usa `fvm flutter`.',
      );
    case _Estado.travou:
      r.aviso(
        'Flutter (PATH)',
        '`flutter --version` não respondeu no tempo limite.',
      );
    case _Estado.rodou:
      final versaoPath = _versaoDe(noPath.saida);
      if (versaoPath == null) {
        r.aviso(
          'Flutter (PATH)',
          'não entendi a saída de `flutter --version`.',
        );
      } else if (e.flutter != null && versaoPath != e.flutter) {
        r.aviso(
          'Flutter (PATH)',
          'o PATH resolve $versaoPath, diferente do pin ${e.flutter}. O Android Studio '
              'usa o SDK do PATH/local.properties, não o fvm — aponte-o para o SDK pinado.',
        );
      } else {
        r.ok('Flutter (PATH)', versaoPath);
      }
  }

  return dir;
}

String? _versaoDe(String saida) {
  final inicio = saida.indexOf('{');
  if (inicio >= 0) {
    try {
      final json = jsonDecode(saida.substring(inicio)) as Map<String, dynamic>;
      final v = json['frameworkVersion'] as String?;
      if (v != null) return v;
    } on FormatException {
      // cai no regex abaixo
    }
  }
  return RegExp(r'Flutter (\S+)').firstMatch(saida)?.group(1);
}

// ---------------------------------------------------------------------------- JDK

Future<void> _verificarJdk(_Relatorio r) async {
  final javaHome = Platform.environment['JAVA_HOME'];
  final sep = Platform.pathSeparator;
  final exe = javaHome == null ? 'java' : '$javaHome${sep}bin${sep}java';

  final res = await _rodar(exe, ['-version'], null);
  if (res.estado != _Estado.rodou || res.codigo != 0) {
    r.falha(
      'JDK 17',
      'não consegui executar `java -version`. JAVA_HOME=${javaHome ?? "(não definido)"}',
    );
    return;
  }

  // `java -version` escreve na saída de erro por convenção histórica.
  final texto = '${res.erro}${res.saida}';
  final maior = int.tryParse(
    RegExp(r'version "(\d+)').firstMatch(texto)?.group(1) ?? '',
  );
  // A primeira linha nem sempre é a da versão: JAVA_TOOL_OPTIONS, quando definida,
  // imprime um "Picked up ..." na frente de tudo.
  final linhas = texto
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty);
  final linhaVersao = linhas.firstWhere(
    (l) => l.contains('version "'),
    orElse: () => linhas.isEmpty ? '(sem saída)' : linhas.first,
  );

  if (maior == null) {
    r.aviso('JDK 17', 'não entendi a versão em: $linhaVersao');
  } else if (maior != 17) {
    r.falha(
      'JDK 17',
      'encontrei JDK $maior. O Gradle do projeto compila com sourceCompatibility 17; '
          'outra major quebra o build com erro difícil de ler.',
    );
  } else {
    r.ok('JDK 17', linhaVersao);
  }
}

// -------------------------------------------------------------------- Android SDK

void _verificarAndroidSdk(_Esperado e, _Relatorio r) {
  final env = Platform.environment;
  final home = env['ANDROID_HOME'] ?? env['ANDROID_SDK_ROOT'];
  if (home == null) {
    r.falha(
      'Android SDK',
      'ANDROID_HOME (ou ANDROID_SDK_ROOT) não está definido. No Windows o Android '
          r'Studio instala em %LOCALAPPDATA%\Android\Sdk — defina a variável para lá.',
    );
    return;
  }
  if (!Directory(home).existsSync()) {
    r.falha('Android SDK', 'ANDROID_HOME aponta para $home, que não existe.');
    return;
  }
  r.ok('Android SDK', home);

  final sep = Platform.pathSeparator;
  void exigirDir(String rotulo, String caminho, String porque) {
    if (Directory(caminho).existsSync()) {
      r.ok(rotulo, caminho);
    } else {
      r.falha(rotulo, 'ausente em $caminho — $porque');
    }
  }

  if (e.plataformaAndroid != null) {
    exigirDir(
      '  platform ${e.plataformaAndroid}',
      '$home${sep}platforms$sep${e.plataformaAndroid}',
      'é o compileSdk do Flutter ${e.flutter}. Instale com '
          '`sdkmanager "platforms;${e.plataformaAndroid}"`.',
    );
  }
  if (e.buildTools != null) {
    exigirDir(
      '  build-tools ${e.buildTools}',
      '$home${sep}build-tools$sep${e.buildTools}',
      'instale com `sdkmanager "build-tools;${e.buildTools}"`.',
    );
  }
  if (e.ndk != null) {
    exigirDir(
      '  ndk ${e.ndk}',
      '$home${sep}ndk$sep${e.ndk}',
      'é o ndkVersion do Flutter ${e.flutter}; o SQLCipher (Fase 4) precisa dele. '
          'Instale com `sdkmanager "ndk;${e.ndk}"`.',
    );
  }

  final adb = File(
    '$home${sep}platform-tools${sep}adb${Platform.isWindows ? ".exe" : ""}',
  );
  if (adb.existsSync()) {
    r.ok('  platform-tools', adb.path);
  } else {
    r.falha(
      '  platform-tools',
      'adb não encontrado em ${adb.path} — `sdkmanager "platform-tools"`.',
    );
  }

  if (File('$home${sep}licenses${sep}android-sdk-license').existsSync()) {
    r.ok('  licenças', 'aceitas');
  } else {
    r.falha(
      '  licenças',
      'não aceitas — rode `flutter doctor --android-licenses`.',
    );
  }
}

// ------------------------------------------------------------- pins do build.gradle

void _verificarPinsDoGradle(_Esperado e, _Relatorio r) {
  // Decisões travadas no board. Um `flutter create` futuro, ou um merge desatento,
  // reescreve build.gradle.kts com os padrões do template e rebaixa as duas em silêncio.
  if (e.applicationId == 'com.desmalha.app') {
    r.ok('applicationId', e.applicationId!);
  } else {
    r.falha(
      'applicationId',
      'está "${e.applicationId ?? "?"}", esperado "com.desmalha.app" (decisão travada).',
    );
  }

  if (e.minSdk == 26) {
    r.ok('minSdk', '26');
  } else {
    r.falha(
      'minSdk',
      'está "${e.minSdk ?? "?"}", esperado 26 (decisão travada: SQLCipher, Keystore '
          'de hardware e custo do Argon2id).',
    );
  }
}

// --------------------------------------------------------------------- dispositivos

Future<void> _verificarDispositivos(
  Directory raiz,
  Directory? sdkFlutter,
  bool exigirAndroid,
  _Relatorio r,
) async {
  final sep = Platform.pathSeparator;
  final exe = sdkFlutter == null
      ? 'flutter'
      : '${sdkFlutter.path}${sep}bin${sep}flutter${Platform.isWindows ? ".bat" : ""}';

  final res = await _rodar(exe, ['devices', '--machine'], raiz);
  if (res.estado != _Estado.rodou || res.codigo != 0) {
    final motivo = res.estado == _Estado.travou
        ? '`flutter devices` não respondeu no tempo limite.'
        : 'não consegui rodar `flutter devices`.';
    exigirAndroid
        ? r.falha('Dispositivos', motivo)
        : r.aviso('Dispositivos', motivo);
    return;
  }

  var lista = const <dynamic>[];
  try {
    // O tool às vezes prefixa avisos à saída JSON (ex.: o aviso de rodar como root).
    final inicio = res.saida.indexOf('[');
    if (inicio >= 0)
      lista = jsonDecode(res.saida.substring(inicio)) as List<dynamic>;
  } on FormatException catch (erro) {
    r.aviso(
      'Dispositivos',
      'saída de `flutter devices --machine` ilegível: $erro',
    );
    return;
  }

  final android = lista
      .whereType<Map<String, dynamic>>()
      .where(
        (d) => (d['targetPlatform'] as String? ?? '').startsWith('android'),
      )
      .toList();

  if (android.isEmpty) {
    const msg =
        'nenhum aparelho ou emulador Android conectado. Suba um AVD '
        '(`flutter emulators --launch <id>`) ou ligue um aparelho com depuração USB. '
        'É o alvo do hot reload — sem ele o Bloco 3 não fecha.';
    exigirAndroid
        ? r.falha('Dispositivo Android', msg)
        : r.info('Dispositivo Android', msg);
  } else {
    for (final d in android) {
      r.ok(
        'Dispositivo Android',
        '${d['name']} (${d['id']}, ${d['sdk'] ?? d['targetPlatform']})',
      );
    }
  }
}

// -------------------------------------------------------------------------- auxiliares

Directory? _raizDoRepo() {
  var dir = Directory.current.absolute;
  for (var i = 0; i < 8; i++) {
    if (File('${dir.path}${Platform.pathSeparator}.fvmrc').existsSync())
      return dir;
    final pai = dir.parent;
    if (pai.path == dir.path) break;
    dir = pai;
  }
  return null;
}

enum _Estado { rodou, ausente, travou }

class _Resultado {
  const _Resultado(
    this.estado, {
    this.codigo = -1,
    this.saida = '',
    this.erro = '',
  });
  final _Estado estado;
  final int codigo;
  final String saida;
  final String erro;
}

/// Executa um processo com limite de tempo, distinguindo "não existe" de "travou".
/// O limite é generoso de propósito: em máquina fria o `flutter` gasta segundos só
/// para subir. O que ele impede é o caso patológico — fvm baixando um SDK inteiro.
Future<_Resultado> _rodar(
  String exe,
  List<String> args,
  Directory? dir, {
  Duration limite = const Duration(seconds: 90),
}) async {
  Process proc;
  try {
    // runInShell resolve .bat/.cmd no Windows (flutter e fvm são scripts lá).
    proc = await Process.start(
      exe,
      args,
      workingDirectory: dir?.path,
      runInShell: true,
    );
  } on ProcessException {
    return const _Resultado(_Estado.ausente);
  }

  final saida = StringBuffer();
  final erro = StringBuffer();
  final coleta = Future.wait([
    proc.stdout.transform(utf8.decoder).forEach(saida.write),
    proc.stderr.transform(utf8.decoder).forEach(erro.write),
  ]);

  try {
    final codigo = await proc.exitCode.timeout(limite);
    await coleta.timeout(const Duration(seconds: 5), onTimeout: () => const []);
    return _Resultado(
      _Estado.rodou,
      codigo: codigo,
      saida: '$saida',
      erro: '$erro',
    );
  } on TimeoutException {
    proc.kill(ProcessSignal.sigkill);
    return const _Resultado(_Estado.travou);
  }
}

// --------------------------------------------------------------------------- saída

class _Relatorio {
  final _linhas = <String>[];
  var falhou = false;
  var _avisos = 0;
  var _falhas = 0;

  void ok(String o, String d) => _linhas.add('  [ok]    $o: $d');

  void info(String o, String d) => _linhas.add('  [--]    $o: $d');

  void aviso(String o, String d) {
    _avisos++;
    _linhas.add('  [aviso] $o: $d');
  }

  void falha(String o, String d) {
    _falhas++;
    falhou = true;
    _linhas.add('  [FALHA] $o: $d');
  }

  void imprimirResumo() {
    stdout.writeln(_linhas.join('\n'));
    stdout.writeln('');
    stdout.writeln(
      falhou
          ? 'AMBIENTE INCOMPLETO — $_falhas falha(s), $_avisos aviso(s).'
          : 'Ambiente OK — $_avisos aviso(s).',
    );
  }
}
