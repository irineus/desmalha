import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'auth/configuracao_supabase.dart';
import 'auth/porta_auth_supabase.dart';
import 'auth/portal_auth.dart';
import 'auth/servico_auth.dart';
import 'catalogo/porta_catalogo_rest.dart';
import 'catalogo/repositorio_catalogo.dart';
import 'dados/conexao_cifrada.dart';
import 'monitoring.dart';
import 'tema/tema.dart';

Future<void> main() async {
  await bootstrap(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Antes de tudo que é rede: o banco local abre e a cifra é conferida.
    // Sem SQLCipher no binário, o app cai AQUI, ruidosamente — nunca segue
    // gravando dado fiscal em claro (ver conexao_cifrada.dart).
    await abrirBancoNoBoot();
    await inicializarSupabase();
    // Em segundo plano, sem segurar o boot: o catálogo local (cache ou seed)
    // já serve qualquer cálculo; isto só o mantém fresco quando há rede.
    unawaited(_atualizarCatalogo());
    runApp(
      DesmalhaApp(
        servico: supabaseConfigurado
            ? ServicoAutenticacao(PortaAuthSupabase.doClienteGlobal())
            : null,
      ),
    );
  });
}

/// Atualiza o cache local do catálogo versionado a partir do servidor.
///
/// Falhar aqui é rotina (avião, sem configuração, servidor fora): o app
/// segue com o último snapshot — cache ou seed embarcado. Por isso nada
/// sobe: `atualizar()` já devolve `false` em vez de lançar, e o guarda
/// externo cobre só o `path_provider`.
Future<void> _atualizarCatalogo() async {
  if (!supabaseConfigurado) return;
  try {
    final diretorio = await getApplicationSupportDirectory();
    final repositorio = RepositorioCatalogo(
      remota: PortaCatalogoRest(
        url: supabaseUrl,
        chavePublicavel: supabasePublishableKey,
      ),
      arquivoCache: File('${diretorio.path}/catalogo_cache.json'),
    );
    await repositorio.atualizar();
  } on Exception {
    // Offline é o estado normal de um app local-first.
  }
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
      theme: temaDesmalha(),
      home: servico == null
          ? const TelaSemConfiguracao()
          : PortalAuth(servico: servico),
    );
  }
}
