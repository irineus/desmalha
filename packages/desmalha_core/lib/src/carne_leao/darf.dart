/// Vencimento do DARF do carnê-leão (código 0190).
///
/// Vence no último dia útil do mês SEGUINTE à competência, ANTECIPANDO em
/// fim de semana e feriado bancário. Os feriados (inclusive os móveis:
/// carnaval, sexta-feira santa, corpus christi) vêm da tabela versionada
/// servida pela API — nunca são calculados nem hardcoded aqui.
library;

import '../extrato/data_civil.dart';

/// Código de receita do carnê-leão no DARF.
const String codigoReceitaCarneLeao = '0190';

/// Data civil `'YYYY-MM-DD'` de vencimento do DARF da [competencia]
/// (`'YYYY-MM'`).
///
/// [feriadosBancarios] é o conjunto de datas civis `'YYYY-MM-DD'` que não
/// contam como dia útil, vindo da tabela `feriado_bancario` versionada.
/// Sábado e domingo nunca são úteis, com ou sem entrada no conjunto.
String vencimentoDarf(String competencia, Set<String> feriadosBancarios) {
  final mesVencimento = competenciaSeguinte(competencia);
  var data = ultimoDiaDoMes(mesVencimento);
  while (_ehFimDeSemana(data) || feriadosBancarios.contains(data)) {
    data = diaAnterior(data);
    if (!data.startsWith(mesVencimento)) {
      throw StateError(
        'nenhum dia útil no mês de vencimento $mesVencimento — '
        'tabela de feriados inconsistente',
      );
    }
  }
  return data;
}

/// Competência seguinte a [competencia] (`'2026-12'` → `'2027-01'`).
String competenciaSeguinte(String competencia) {
  final ano = int.parse(competencia.substring(0, 4));
  final mes = int.parse(competencia.substring(5, 7));
  final proximoAno = mes == 12 ? ano + 1 : ano;
  final proximoMes = mes == 12 ? 1 : mes + 1;
  return '$proximoAno-${proximoMes.toString().padLeft(2, '0')}';
}

/// Último dia do mês da [competencia], como data civil `'YYYY-MM-DD'`.
String ultimoDiaDoMes(String competencia) {
  final ano = int.parse(competencia.substring(0, 4));
  final mes = int.parse(competencia.substring(5, 7));
  var dia = 31;
  while (!ehDataCivilValida(ano, mes, dia)) {
    dia--;
  }
  return '$competencia-${dia.toString().padLeft(2, '0')}';
}

/// Data civil do dia anterior a [data] (`'YYYY-MM-DD'`).
String diaAnterior(String data) {
  final civil = DateTime.utc(
    int.parse(data.substring(0, 4)),
    int.parse(data.substring(5, 7)),
    int.parse(data.substring(8, 10)),
  ).subtract(const Duration(days: 1));
  final mm = civil.month.toString().padLeft(2, '0');
  final dd = civil.day.toString().padLeft(2, '0');
  return '${civil.year}-$mm-$dd';
}

bool _ehFimDeSemana(String data) {
  final civil = DateTime.utc(
    int.parse(data.substring(0, 4)),
    int.parse(data.substring(5, 7)),
    int.parse(data.substring(8, 10)),
  );
  return civil.weekday == DateTime.saturday ||
      civil.weekday == DateTime.sunday;
}
