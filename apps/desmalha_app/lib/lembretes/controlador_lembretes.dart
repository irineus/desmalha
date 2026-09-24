/// Lembrete LOCAL de vencimento do DARF do carnê-leão.
///
/// A cada abertura do app (e a cada volta a ele), [sincronizar] refaz o
/// plano do `desmalha_core` com o catálogo local e reagenda os avisos: 3
/// dias antes e no dia do vencimento, às 9h. Reagendar sempre é o que mantém
/// o aviso certo quando o catálogo traz feriado novo ou o ano seguinte.
///
/// O texto fala da DATA, nunca de valor: o lembrete não afirma que há
/// imposto a pagar.
///
/// Falhas ficam visíveis em Ajustes, nunca em silêncio: notificação não
/// autorizada, catálogo sem o calendário de feriados do ano do vencimento,
/// erro do plugin.
library;

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/foundation.dart';

import 'porta_notificacoes.dart';

/// Hora local em que os avisos aparecem.
const int horaDoLembrete = 9;

/// Faixa de ids reservada aos lembretes do DARF: `AAAAMM × 10 + (0|1)`.
const int _primeiroIdLembrete = 2000000;
const int _ultimoIdLembrete = 2999999;

bool ehIdDeLembreteDarf(int id) =>
    id >= _primeiroIdLembrete && id <= _ultimoIdLembrete;

/// Id estável do aviso: reagendar o mesmo aviso substitui, não duplica.
int idDoLembrete(LembreteVencimento l) =>
    int.parse(l.competencia.replaceAll('-', '')) * 10 + (l.noDia ? 1 : 0);

/// Instante local do aviso: [horaDoLembrete] da data do aviso.
DateTime instanteDoAviso(LembreteVencimento l) {
  final d = DateTime.parse(l.dataDoAviso);
  return DateTime(d.year, d.month, d.day, horaDoLembrete);
}

const _meses = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', //
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];
const _diasDaSemana = [
  'segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo', //
];

/// `'2026-08'` → `'agosto/2026'`.
String competenciaPorExtenso(String competencia) =>
    '${_meses[int.parse(competencia.substring(5, 7)) - 1]}/'
    '${competencia.substring(0, 4)}';

/// `'2026-09-30'` → `'quarta, 30/09'`.
String dataCurta(String data) {
  final d = DateTime.parse(data);
  return '${_diasDaSemana[d.weekday - 1]}, '
      '${data.substring(8, 10)}/${data.substring(5, 7)}';
}

String tituloDoLembrete(LembreteVencimento l) => l.noDia
    ? 'Carnê-leão: o DARF vence hoje'
    : 'Carnê-leão: o DARF vence em $diasDeAntecedenciaDoLembrete dias';

String corpoDoLembrete(LembreteVencimento l) =>
    'Competência ${competenciaPorExtenso(l.competencia)}: '
    '${l.noDia ? 'hoje, ' : ''}${dataCurta(l.vencimento)}, '
    '${l.noDia ? 'é o último dia' : 'é o vencimento'} (código 0190). '
    'Abra o Desmalha para conferir se há imposto a pagar.';

class ControladorLembretes extends ChangeNotifier {
  ControladorLembretes({
    required this.porta,
    required this.carregarCatalogo,
    DateTime Function()? relogio,
  }) : _relogio = relogio ?? DateTime.now;

  final PortaNotificacoes porta;
  final Future<Catalogo> Function() carregarCatalogo;
  final DateTime Function() _relogio;

  bool _carregado = false;
  bool _permitidas = false;
  PlanoLembretesDarf? _plano;
  List<LembreteVencimento> _agendados = const [];
  String? _erro;
  Future<void>? _emCurso;

  /// Já houve uma sincronização (com sucesso ou não)?
  bool get carregado => _carregado;

  /// O sistema autoriza notificações? Sem isso o aviso não aparece.
  bool get permitidas => _permitidas;

  /// Avisos efetivamente agendados na última sincronização.
  List<LembreteVencimento> get agendados => _agendados;

  /// O calendário acabou antes do horizonte (ano sem feriados publicados).
  FalhaDeCalendario? get falhaDeCalendario => _plano?.falhaDeCalendario;

  /// Erro da última sincronização (plugin, catálogo ilegível).
  String? get erro => _erro;

  /// Refaz o plano e reagenda. Chamadas simultâneas compartilham a mesma
  /// execução.
  Future<void> sincronizar() =>
      _emCurso ??= _sincronizar().whenComplete(() => _emCurso = null);

  /// Pede a permissão ao sistema e sincroniza. Devolve se ficou concedida.
  Future<bool> permitir() async {
    try {
      await porta.pedirPermissao();
    } on Exception catch (e) {
      _erro = 'Não foi possível pedir a permissão: $e';
    }
    // O diálogo do sistema pausa e retoma o app, e a volta dispara uma
    // sincronização que pode ter lido a permissão ANTES da resposta: espera
    // ela acabar e roda uma nova.
    await _emCurso;
    await sincronizar();
    return _permitidas;
  }

  Future<void> _sincronizar() async {
    try {
      _permitidas = await porta.permitidas();
      final agora = _relogio();
      final plano = planejarLembretesDarf(
        catalogo: await carregarCatalogo(),
        hoje: _dataCivil(agora),
      );
      // Folga de 1 minuto: o plugin recusa instante no passado, e um aviso
      // das 9h avaliado às 8h59min59s chegaria a ele já vencido.
      final limite = agora.add(const Duration(minutes: 1));
      final aAgendar = [
        for (final l in plano.lembretes)
          if (instanteDoAviso(l).isAfter(limite)) l,
      ];
      // Agenda mesmo sem permissão: se o usuário autorizar depois pelas
      // configurações do sistema, os avisos já estão lá.
      for (final id in await porta.agendadas()) {
        if (ehIdDeLembreteDarf(id)) await porta.cancelar(id);
      }
      for (final l in aAgendar) {
        await porta.agendar(
          id: idDoLembrete(l),
          instante: instanteDoAviso(l),
          titulo: tituloDoLembrete(l),
          corpo: corpoDoLembrete(l),
        );
      }
      _plano = plano;
      _agendados = List.unmodifiable(aAgendar);
      _erro = null;
    } on Exception catch (e) {
      _erro = 'Não foi possível agendar os lembretes: $e';
    } finally {
      _carregado = true;
      notifyListeners();
    }
  }

  static String _dataCivil(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
