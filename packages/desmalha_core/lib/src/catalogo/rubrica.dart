/// Rubricas do livro-caixa — conteúdo versionado do catálogo (tipo
/// `rubrica`), nunca hardcoded no app.
///
/// A lista sai das Decisões vigentes, seção 3 (dedutíveis e vedados), com a
/// trava de 20% da residência fechada nas rodadas 4 e 4b do contador
/// (25/09/2026): aluguel, condomínio, energia, água, IPTU, gás, taxas
/// municipais, internet e telefone residenciais. Linha ou chip EXCLUSIVO da
/// atividade deduz 100%, com declaração de exclusividade.
///
/// Rubrica vedada existe de propósito: o usuário registra o gasto (ele é
/// real e o comprovante precisa ser guardado), vê por que não deduz, e o
/// motor não o soma. Esconder a rubrica levaria o usuário a lançá-la numa
/// dedutível "parecida".
library;

import '../carne_leao/apuracao.dart';

/// Onde a rubrica se aplica — agrupa a lista na tela de despesa.
enum GrupoRubrica {
  /// Espaço usado só para a atividade (consultório, escritório): 100%.
  espacoProfissional,

  /// Manutenção da residência usada também como espaço profissional: a
  /// trava de 20% se aplica por lançamento.
  residencia,

  /// Custeio da atividade (material, conselho, marketing, contador...).
  atividade,

  /// Não dedutível no livro-caixa de pessoa física.
  vedada,
}

class Rubrica {
  Rubrica({
    required this.id,
    required this.nome,
    required this.grupo,
    required this.dedutivel,
    required this.travaResidencia,
    required this.exigeDeclaracaoExclusividade,
    required this.orientacao,
    required this.ordem,
    required this.fonte,
  }) {
    if (grupo == GrupoRubrica.vedada && dedutivel) {
      throw FormatException(
        'rubrica "$id": grupo vedada não pode ser '
        'dedutível',
      );
    }
    if (grupo != GrupoRubrica.vedada && !dedutivel) {
      throw FormatException(
        'rubrica "$id": não dedutível precisa estar no '
        'grupo vedada',
      );
    }
    if (travaResidencia != (grupo == GrupoRubrica.residencia)) {
      throw FormatException(
        'rubrica "$id": a trava de 20% vale exatamente '
        'para o grupo residencia',
      );
    }
    if (!dedutivel && (orientacao == null || orientacao!.isEmpty)) {
      throw FormatException(
        'rubrica "$id": rubrica vedada precisa dizer '
        'por quê em "orientacao"',
      );
    }
    if (exigeDeclaracaoExclusividade &&
        (orientacao == null || orientacao!.isEmpty)) {
      throw FormatException(
        'rubrica "$id": declaração de exclusividade '
        'precisa da orientação de comprovante',
      );
    }
  }

  /// Identificador estável, gravado em cada despesa (`rubrica_codigo`).
  final String id;

  final String nome;
  final GrupoRubrica grupo;

  /// `false` só no grupo [GrupoRubrica.vedada].
  final bool dedutivel;

  /// Só 20% do valor deduz (`travaHomeOfficePontosBase`), por lançamento.
  final bool travaResidencia;

  /// A despesa só entra depois de a pessoa declarar que o item é exclusivo
  /// da atividade (rodada 4b: linha ou chip exclusivo).
  final bool exigeDeclaracaoExclusividade;

  /// O que guardar como comprovante, ou por que a rubrica não deduz.
  final String? orientacao;

  /// Posição na lista da tela.
  final int ordem;

  /// Origem rastreável da regra.
  final String fonte;

  /// A despesa de [valorCentavos] nesta rubrica, com a trava de 20% e a
  /// vedação decididas pela rubrica — nunca por quem registra.
  DespesaLivroCaixa despesa(int valorCentavos) => DespesaLivroCaixa(
    valorCentavos: valorCentavos,
    sujeitaTravaHomeOffice: travaResidencia,
    dedutivel: dedutivel,
  );

  factory Rubrica.fromJson(Map<String, Object?> json) {
    String texto(String campo) {
      final valor = json[campo];
      if (valor is! String || valor.isEmpty) {
        throw FormatException('rubrica: campo "$campo" ausente ou vazio');
      }
      return valor;
    }

    bool booleano(String campo) {
      final valor = json[campo];
      if (valor is! bool) {
        throw FormatException('rubrica: campo "$campo" precisa ser booleano');
      }
      return valor;
    }

    final grupoTexto = texto('grupo');
    final grupo = GrupoRubrica.values.where((g) => g.name == grupoTexto);
    if (grupo.isEmpty) {
      throw FormatException('rubrica: grupo "$grupoTexto" desconhecido');
    }
    final ordem = json['ordem'];
    if (ordem is! int) {
      throw const FormatException('rubrica: "ordem" precisa ser inteiro');
    }
    final orientacao = json['orientacao'];
    if (orientacao != null && orientacao is! String) {
      throw const FormatException('rubrica: "orientacao" precisa ser texto');
    }
    return Rubrica(
      id: texto('id'),
      nome: texto('nome'),
      grupo: grupo.single,
      dedutivel: booleano('dedutivel'),
      travaResidencia: booleano('travaResidencia'),
      exigeDeclaracaoExclusividade: booleano('exigeDeclaracaoExclusividade'),
      orientacao: orientacao as String?,
      ordem: ordem,
      fonte: texto('fonte'),
    );
  }
}
