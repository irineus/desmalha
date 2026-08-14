/// Conversão de valores monetários textuais para centavos (`int`).
///
/// Aritmética inteira e manipulação de string do início ao fim: nenhum valor
/// monetário passa por `double` em momento algum (regra inviolável do
/// projeto). Falha de parse retorna `null` — quem chama decide se vira aviso.
library;

/// Convenção de separadores do valor no arquivo de origem.
enum FormatoValor {
  /// Decimal com vírgula, milhar com ponto: `1.234,56` (padrão brasileiro).
  virgulaDecimal,

  /// Decimal com ponto, milhar com vírgula: `1,234.56` ou `1234.56`.
  pontoDecimal,
}

/// Converte um valor textual de extrato em centavos, segundo o [formato].
///
/// Aceita símbolo `R$`, espaços (inclusive NBSP), sinal antes ou depois do
/// número e parênteses contábeis (`(123,45)` = negativo). Mais de duas casas
/// decimais só é aceito quando os dígitos excedentes forem zero — extrato
/// bancário não tem fração de centavo, e arredondar em silêncio esconderia
/// arquivo corrompido ou perfil de banco errado.
int? parseValorMonetario(String bruto, FormatoValor formato) {
  final separadorDecimal = formato == FormatoValor.virgulaDecimal ? ',' : '.';
  final separadorMilhar = formato == FormatoValor.virgulaDecimal ? '.' : ',';

  var texto =
      bruto.replaceAll('R\$', '').replaceAll(RegExp('[\\s\u00A0 ]'), '');
  if (texto.isEmpty) return null;

  var negativo = false;
  if (texto.startsWith('(') && texto.endsWith(')')) {
    negativo = true;
    texto = texto.substring(1, texto.length - 1);
  }
  if (texto.startsWith('-')) {
    negativo = true;
    texto = texto.substring(1);
  } else if (texto.startsWith('+')) {
    texto = texto.substring(1);
  } else if (texto.endsWith('-')) {
    negativo = true;
    texto = texto.substring(0, texto.length - 1);
  }
  if (texto.isEmpty) return null;

  texto = texto.replaceAll(separadorMilhar, '');

  final partes = texto.split(separadorDecimal);
  if (partes.length > 2) return null;
  final parteInteira = partes[0];
  final parteDecimal = partes.length == 2 ? partes[1] : '';

  if (parteInteira.isEmpty && parteDecimal.isEmpty) return null;
  if (!_soDigitos(parteInteira) || !_soDigitos(parteDecimal)) return null;

  final String centavosTexto;
  if (parteDecimal.length <= 2) {
    centavosTexto = parteDecimal.padRight(2, '0');
  } else {
    if (parteDecimal.substring(2).replaceAll('0', '').isNotEmpty) return null;
    centavosTexto = parteDecimal.substring(0, 2);
  }

  final reais = parteInteira.isEmpty ? 0 : int.parse(parteInteira);
  final centavos = int.parse(centavosTexto);
  final total = reais * 100 + centavos;
  return negativo ? -total : total;
}

/// Converte o `TRNAMT` de um OFX em centavos.
///
/// A especificação manda ponto decimal sem separador de milhar, mas bancos
/// brasileiros emitem vírgula com frequência; o último `.` ou `,` presente é
/// tratado como separador decimal. Qualquer outro separador torna o valor
/// inválido (`null`) — TRNAMT não carrega milhar.
int? parseValorOfx(String bruto) {
  final texto = bruto.trim();
  final ultimoPonto = texto.lastIndexOf('.');
  final ultimaVirgula = texto.lastIndexOf(',');
  final formato = ultimaVirgula > ultimoPonto
      ? FormatoValor.virgulaDecimal
      : FormatoValor.pontoDecimal;
  final separadorMilhar = formato == FormatoValor.virgulaDecimal ? '.' : ',';
  if (texto.contains(separadorMilhar)) return null;
  return parseValorMonetario(texto, formato);
}

bool _soDigitos(String texto) {
  for (final unidade in texto.codeUnits) {
    if (unidade < 0x30 || unidade > 0x39) return false;
  }
  return true;
}
