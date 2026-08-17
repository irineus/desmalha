import 'package:flutter/material.dart';

import 'auth/configuracao_supabase.dart';
import 'auth/porta_auth_supabase.dart';
import 'auth/portal_auth.dart';
import 'auth/servico_auth.dart';
import 'dados/conexao_cifrada.dart';
import 'monitoring.dart';

Future<void> main() async {
  await bootstrap(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Antes de tudo que é rede: o banco local abre e a cifra é conferida.
    // Sem SQLCipher no binário, o app cai AQUI, ruidosamente — nunca segue
    // gravando dado fiscal em claro (ver conexao_cifrada.dart).
    await abrirBancoNoBoot();
    await inicializarSupabase();
    runApp(
      DesmalhaApp(
        servico: supabaseConfigurado
            ? ServicoAutenticacao(PortaAuthSupabase.doClienteGlobal())
            : null,
      ),
    );
  });
}

class DesmalhaApp extends StatelessWidget {
  const DesmalhaApp({super.key, required this.servico});

  /// `null` num build sem configuração de servidor — ver [TelaSemConfiguracao].
  final ServicoAutenticacao? servico;

  @override
  Widget build(BuildContext context) {
    final servico = this.servico;
    return MaterialApp(
      title: 'Desmalha',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F6E4F)),
      ),
      home: servico == null
          ? const TelaSemConfiguracao()
          : PortalAuth(servico: servico),
    );
  }
}
