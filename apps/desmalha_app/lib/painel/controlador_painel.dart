/// Estado da aba Mês: qual competência está na tela e o painel dela.
library;

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/foundation.dart';

import 'repositorio_fechamento.dart';
import 'repositorio_painel.dart';

/// Onde a competência na tela está no fechamento (decisão 7 do owner).
class EstadoFechamento {
  const EstadoFechamento({
    required this.fechado,
    required this.guia,
    required this.acerto,
    required this.pagamentos,
    required this.correcaoPendente,
    required this.motivosQueImpedem,
    required this.meses,
    required this.tocaDeclaracao,
  });

  /// A competência tem apuração fechada vigente.
  final bool fechado;

  /// A guia paga que abrange a competência, se houver.
  final GuiaPaga? guia;

  /// O acerto dessa guia contra o recálculo de hoje (P8/P9, rodada 5).
  final AcertoDaGuia? acerto;

  /// Os pagamentos do ano, do mais recente ao mais antigo.
  final List<PagamentoDarf> pagamentos;

  /// Algum mês fechado do ano mudou depois do fechamento.
  final bool correcaoPendente;

  /// Por que a competência ainda não pode fechar (vazio = pode).
  final List<String> motivosQueImpedem;

  /// O ano recalculado, com o que a apuração gravada precisa guardar.
  final Map<String, MesApurado> meses;

  /// P15 (rodada 5): o acerto é de ano cuja declaração pode já ter sido
  /// entregue.
  final bool tocaDeclaracao;

  /// O pagamento mais recente da guia desta competência.
  PagamentoDarf? get pagamento {
    final g = guia;
    if (g == null) return null;
    for (final p in pagamentos) {
      if (p.periodo == g.periodo) return p;
    }
    return null;
  }
}

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
    this.fechamento,
    DateTime Function()? relogio,
  }) : _relogio = relogio ?? DateTime.now;

  final RepositorioPainel repositorio;

  /// Sem ele (testes antigos), o painel não sabe de guia paga nem de mês
  /// fechado.
  final RepositorioFechamento? fechamento;
  final Future<Catalogo> Function() carregarCatalogo;
  final DateTime Function() _relogio;

  String? _competencia;
  PainelMensal? _painel;
  EstadoFechamento? _estado;
  String? _erro;

  String? get competencia => _competencia;
  PainelMensal? get painel => _painel;
  EstadoFechamento? get estado => _estado;
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
      final ano = int.parse(c.substring(0, 4));
      final dados = await repositorio.dadosDoAno(ano);
      final guias = await fechamento?.guiasPagas(ano) ?? const <GuiaPaga>[];
      final quitados = {for (final g in guias) g.periodo};
      _competencia = c;
      _painel = montarPainelMensal(
        competencia: c,
        dadosDoAno: dados,
        catalogo: catalogo,
        periodosQuitados: quitados,
      );
      _estado = await _estadoDoFechamento(
        c,
        dados: dados,
        catalogo: catalogo,
        guias: guias,
      );
      _erro = null;
    } on Exception catch (e) {
      _erro = 'Não foi possível montar o mês: $e';
    }
    notifyListeners();
  }

  Future<EstadoFechamento?> _estadoDoFechamento(
    String c, {
    required Map<String, DadosDoMes> dados,
    required Catalogo catalogo,
    required List<GuiaPaga> guias,
  }) async {
    final repo = fechamento;
    final painel = _painel;
    if (repo == null || painel is! PainelApurado) return null;
    final ano = int.parse(c.substring(0, 4));
    final Map<String, ApuracaoMensal> recalculadas;
    final Map<String, MesApurado> meses;
    try {
      recalculadas = apurarAno(
        ate: '$ano-12',
        dadosDoAno: dados,
        catalogo: catalogo,
        periodosQuitados: {for (final g in guias) g.periodo},
      );
      meses = {
        for (final a in recalculadas.values)
          a.competencia: MesApurado(
            apuracao: a,
            dados: dados[a.competencia] ?? const DadosDoMes(),
            tabela: catalogo.tabelaVigentePara(a.competencia),
          ),
      };
    } on StateError {
      // Falta tabela de um mês adiante: o painel do mês na tela vale, o
      // fechamento espera o catálogo.
      return null;
    }
    final fechadas = await repo.fechadas(ano);
    GuiaPaga? guia;
    for (final g in guias) {
      if (g.competencias.contains(c)) guia = g;
    }
    final acerto = guia == null ? null : acertoDaGuia(guia, recalculadas);
    return EstadoFechamento(
      fechado: fechadas.containsKey(c),
      guia: guia,
      acerto: acerto,
      pagamentos: await repo.pagamentos(ano),
      correcaoPendente: fechadas.values.any((f) {
        final m = meses[f.competencia];
        return m != null && assinaturaDe(m) != f.assinatura;
      }),
      motivosQueImpedem: motivosQueImpedemFechar(
        recebimentosAClassificar: painel.recebimentosAClassificar,
      ),
      meses: meses,
      tocaDeclaracao:
          acerto != null && acertoTocaDeclaracaoEntregue(acerto, hoje),
    );
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
