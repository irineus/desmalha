/// Estado da aba Mês: qual competência está na tela e o painel dela.
library;

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/foundation.dart';

import 'repositorio_painel.dart';

/// Competência `'YYYY-MM'` de [d].
String competenciaDe(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

String competenciaAnterior(String c) {
  final ano = int.parse(c.substring(0, 4));
  final mes = int.parse(c.substring(5, 7));
  return mes == 1
      ? '${ano - 1}-12'
      : '$ano-${(mes - 1).toString().padLeft(2, '0')}';
}

/// A competência que a aba abre: a do DARF que vence a seguir — a do mês
/// passado até o vencimento dela (último dia útil deste mês); depois, a
/// deste mês. Sem calendário para decidir, a do mês passado.
String competenciaInicial(DateTime hoje, Catalogo catalogo) {
  final atual = competenciaDe(hoje);
  final anterior = competenciaAnterior(atual);
  final dataHoje = '$atual-${hoje.day.toString().padLeft(2, '0')}';
  try {
    return catalogo.vencimentoDarfDe(anterior).compareTo(dataHoje) >= 0
        ? anterior
        : atual;
  } on StateError {
    return anterior;
  }
}

class ControladorPainel extends ChangeNotifier {
  ControladorPainel({
    required this.repositorio,
    required this.carregarCatalogo,
    DateTime Function()? relogio,
  }) : _relogio = relogio ?? DateTime.now;

  final RepositorioPainel repositorio;
  final Future<Catalogo> Function() carregarCatalogo;
  final DateTime Function() _relogio;

  String? _competencia;
  PainelMensal? _painel;
  String? _erro;

  String? get competencia => _competencia;
  PainelMensal? get painel => _painel;
  String? get erro => _erro;

  /// Hoje, como data civil `'YYYY-MM-DD'`.
  String get hoje {
    final d = _relogio();
    return '${competenciaDe(d)}-${d.day.toString().padLeft(2, '0')}';
  }

  /// A competência do mês corrente: a aba não navega para o futuro.
  String get competenciaAtual => competenciaDe(_relogio());

  bool get podeAvancar =>
      _competencia != null && _competencia!.compareTo(competenciaAtual) < 0;

  Future<void> carregar([String? competencia]) async {
    try {
      final catalogo = await carregarCatalogo();
      final c =
          competencia ??
          _competencia ??
          competenciaInicial(_relogio(), catalogo);
      final dados = await repositorio.dadosDoAno(int.parse(c.substring(0, 4)));
      _competencia = c;
      _painel = montarPainelMensal(
        competencia: c,
        dadosDoAno: dados,
        catalogo: catalogo,
      );
      _erro = null;
    } on Exception catch (e) {
      _erro = 'Não foi possível montar o mês: $e';
    }
    notifyListeners();
  }

  Future<void> anterior() => carregar(competenciaAnterior(_competencia!));

  Future<void> proximo() async {
    if (!podeAvancar) return;
    final ano = int.parse(_competencia!.substring(0, 4));
    final mes = int.parse(_competencia!.substring(5, 7));
    await carregar(
      mes == 12
          ? '${ano + 1}-01'
          : '$ano-${(mes + 1).toString().padLeft(2, '0')}',
    );
  }
}
