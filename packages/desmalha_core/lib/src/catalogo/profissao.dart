/// Profissões — conteúdo versionado do catálogo (tipo `profissao`).
///
/// Regra fechada na rodada 2/2b do contador (ago/2026):
/// - **saúde** (médico, dentista, psicólogo, fisioterapeuta, terapeuta
///   ocupacional, fonoaudiólogo): o lançamento leva o CPF de quem pagou E o
///   CPF do beneficiário (o paciente) — é o que garante a dedução de despesa
///   médica na DIRPF de quem pagou;
/// - **demais regulamentadas** (ex.: advogado, nutricionista): só o CPF de
///   quem pagou;
/// - não regulamentadas: CPF não é exigido.
///
/// Sem CPF o recebimento continua tributável e é lançado: a falta vira
/// pendência documental, nunca dispensa (rodada 2b).
library;

class Profissao {
  Profissao({
    required this.id,
    required this.nome,
    required this.regulamentada,
    required this.saude,
    required this.conselho,
    required this.meiPermitido,
    required this.fonte,
  }) {
    if (saude && !regulamentada) {
      throw FormatException('profissão "$id": saúde implica regulamentada');
    }
    if (regulamentada && (conselho == null || conselho!.isEmpty)) {
      throw FormatException(
        'profissão "$id": regulamentada precisa do '
        'conselho',
      );
    }
  }

  /// Identificador estável, gravado no perfil (`profissao_codigo`).
  final String id;
  final String nome;

  /// Exige o CPF do pagador por lançamento.
  final bool regulamentada;

  /// Exige também o CPF do beneficiário; o padrão é o próprio pagador.
  final bool saude;

  /// Sigla do conselho (CRP, OAB...), quando regulamentada.
  final String? conselho;

  /// Radar PF × CNPJ: `null` = sem definição do contador ainda.
  final bool? meiPermitido;

  final String fonte;

  factory Profissao.fromJson(Map<String, Object?> json) {
    String texto(String campo) {
      final valor = json[campo];
      if (valor is! String || valor.isEmpty) {
        throw FormatException('profissão: campo "$campo" ausente ou vazio');
      }
      return valor;
    }

    bool booleano(String campo) {
      final valor = json[campo];
      if (valor is! bool) {
        throw FormatException('profissão: campo "$campo" precisa ser booleano');
      }
      return valor;
    }

    final conselho = json['conselho'];
    if (conselho != null && conselho is! String) {
      throw const FormatException('profissão: "conselho" precisa ser texto');
    }
    final mei = json['meiPermitido'];
    if (mei != null && mei is! bool) {
      throw const FormatException(
        'profissão: "meiPermitido" precisa ser booleano ou null',
      );
    }
    return Profissao(
      id: texto('id'),
      nome: texto('nome'),
      regulamentada: booleano('regulamentada'),
      saude: booleano('saude'),
      conselho: conselho as String?,
      meiPermitido: mei as bool?,
      fonte: texto('fonte'),
    );
  }
}
