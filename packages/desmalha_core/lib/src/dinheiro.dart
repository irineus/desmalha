/// Formata um valor em centavos para exibição em reais, no padrão brasileiro.
///
/// `123456` → `R$ 1.234,56` · `-9` → `-R$ 0,09` · `0` → `R$ 0,00`
///
/// Aritmética inteira do início ao fim: dinheiro nunca passa por `double`.
String centavosParaExibicao(int centavos) {
  final negativo = centavos < 0;
  final abs = centavos.abs();
  final reais = (abs ~/ 100).toString();

  final buffer = StringBuffer();
  for (var i = 0; i < reais.length; i++) {
    if (i > 0 && (reais.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(reais[i]);
  }

  final resto = (abs % 100).toString().padLeft(2, '0');
  return '${negativo ? '-' : ''}R\$ $buffer,$resto';
}
