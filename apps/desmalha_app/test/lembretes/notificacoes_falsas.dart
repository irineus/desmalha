import 'dart:convert';
import 'dart:io';

import 'package:desmalha_app/catalogo/repositorio_catalogo.dart';
import 'package:desmalha_app/lembretes/controlador_lembretes.dart';
import 'package:desmalha_app/lembretes/porta_notificacoes.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Um aviso agendado na porta falsa.
typedef AvisoAgendado = ({DateTime instante, String titulo, String corpo});

/// Notificações em memória: o que está agendado, por id.
class NotificacoesFalsas implements PortaNotificacoes {
  NotificacoesFalsas({this.permitido = true, this.concedeAoPedir = true});

  bool permitido;
  bool concedeAoPedir;
  int pedidosDePermissao = 0;
  final Map<int, AvisoAgendado> avisos = {};

  @override
  Future<void> inicializar() async {}

  @override
  Future<bool> permitidas() async => permitido;

  @override
  Future<bool> pedirPermissao() async {
    pedidosDePermissao++;
    if (concedeAoPedir) permitido = true;
    return permitido;
  }

  @override
  Future<Set<int>> agendadas() async => avisos.keys.toSet();

  @override
  Future<void> cancelar(int id) async => avisos.remove(id);

  @override
  Future<void> agendar({
    required int id,
    required DateTime instante,
    required String titulo,
    required String corpo,
  }) async => avisos[id] = (instante: instante, titulo: titulo, corpo: corpo);
}

/// O catálogo do seed embarcado — o mesmo que o app usa offline — lido do
/// disco, para testes sem binding.
Catalogo catalogoDoSeed() => Catalogo.fromJson(
  jsonDecode(File('assets/catalogo/seed.json').readAsStringSync())
      as Map<String, Object?>,
);

ControladorLembretes controladorLembretesFalso({
  NotificacoesFalsas? porta,
  Catalogo? catalogo,
  DateTime? agora,
}) => ControladorLembretes(
  porta: porta ?? NotificacoesFalsas(),
  // Pelo bundle: vale em testWidgets e no aparelho (integration_test).
  carregarCatalogo: () async =>
      catalogo ??
      Catalogo.fromJson(
        jsonDecode(await rootBundle.loadString(assetSeedCatalogo))
            as Map<String, Object?>,
      ),
  relogio: () => agora ?? DateTime(2026, 9, 24, 10),
);
