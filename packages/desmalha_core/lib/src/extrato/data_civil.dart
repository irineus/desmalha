/// Conversão de datas textuais de extrato para data civil `'YYYY-MM-DD'`.
///
/// Data civil é sempre `String` no formato ISO reduzido (convenção do
/// projeto). Falha de parse retorna `null` — quem chama decide se vira aviso.
library;

/// Converte [bruto] em `'YYYY-MM-DD'` segundo o [formato] do perfil do banco.
///
/// Tokens aceitos no formato: `dd`, `MM`, `yyyy`, `yy`; qualquer outro
/// caractere é literal obrigatório (`/`, `-`, `.` etc.). Quando o token é
/// seguido de literal, aceita 1 ou 2 dígitos (`1/7/2026` com `dd/MM/yyyy`);
/// em formatos compactos sem literais (`ddMMyyyy`), a largura é fixa.
/// Ano de 2 dígitos: `00–69` → `20xx`, `70–99` → `19xx`.
String? parseDataCivil(String bruto, String formato) {
  final texto = bruto.trim();
  var posTexto = 0;
  var posFormato = 0;
  int? dia;
  int? mes;
  int? ano;

  while (posFormato < formato.length) {
    final restoFormato = formato.substring(posFormato);
    String? token;
    for (final candidato in const ['yyyy', 'yy', 'MM', 'dd']) {
      if (restoFormato.startsWith(candidato)) {
        token = candidato;
        break;
      }
    }

    if (token == null) {
      // Literal: precisa casar exatamente com o próximo caractere do texto.
      if (posTexto >= texto.length ||
          texto[posTexto] != formato[posFormato]) {
        return null;
      }
      posTexto++;
      posFormato++;
      continue;
    }

    final aposToken = posFormato + token.length;
    final proximoEhLiteral = aposToken < formato.length &&
        !'yMd'.contains(formato[aposToken]);
    final larguraMinima = proximoEhLiteral || aposToken >= formato.length
        ? (token == 'yyyy' ? 4 : (token == 'yy' ? 2 : 1))
        : token.length;
    final larguraMaxima = token == 'yyyy' ? 4 : (token == 'yy' ? 2 : 2);

    var digitos = '';
    while (posTexto < texto.length &&
        digitos.length < larguraMaxima &&
        _ehDigito(texto[posTexto])) {
      digitos += texto[posTexto];
      posTexto++;
      // Em formato compacto (sem literal à frente), respeita a largura exata.
      if (!proximoEhLiteral && digitos.length == token.length) break;
    }
    if (digitos.length < larguraMinima) return null;

    final valor = int.parse(digitos);
    switch (token) {
      case 'dd':
        dia = valor;
      case 'MM':
        mes = valor;
      case 'yyyy':
        ano = valor;
      case 'yy':
        ano = valor <= 69 ? 2000 + valor : 1900 + valor;
    }
    posFormato = aposToken;
  }

  if (posTexto != texto.length) return null;
  if (dia == null || mes == null || ano == null) return null;
  if (!ehDataCivilValida(ano, mes, dia)) return null;

  final mm = mes.toString().padLeft(2, '0');
  final dd = dia.toString().padLeft(2, '0');
  return '$ano-$mm-$dd';
}

/// Converte o `DTPOSTED` de um OFX (`YYYYMMDD`, com hora e fuso opcionais,
/// ex.: `20260731120000[-3:BRT]`) em `'YYYY-MM-DD'`.
String? parseDataOfx(String bruto) {
  final texto = bruto.trim();
  if (texto.length < 8) return null;
  final digitos = texto.substring(0, 8);
  if (!digitos.codeUnits.every((u) => u >= 0x30 && u <= 0x39)) return null;
  final ano = int.parse(digitos.substring(0, 4));
  final mes = int.parse(digitos.substring(4, 6));
  final dia = int.parse(digitos.substring(6, 8));
  if (!ehDataCivilValida(ano, mes, dia)) return null;
  return '${digitos.substring(0, 4)}-${digitos.substring(4, 6)}-'
      '${digitos.substring(6, 8)}';
}

/// Valida uma data do calendário civil, incluindo anos bissextos.
bool ehDataCivilValida(int ano, int mes, int dia) {
  if (ano < 1900 || ano > 2200) return false;
  if (mes < 1 || mes > 12) return false;
  if (dia < 1) return false;
  const diasPorMes = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  var maximo = diasPorMes[mes - 1];
  final bissexto = (ano % 4 == 0 && ano % 100 != 0) || ano % 400 == 0;
  if (mes == 2 && bissexto) maximo = 29;
  return dia <= maximo;
}

bool _ehDigito(String caractere) {
  final unidade = caractere.codeUnitAt(0);
  return unidade >= 0x30 && unidade <= 0x39;
}
