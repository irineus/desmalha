/// Formatação de centavos para exibição no relatório do CLI.
///
/// Manipulação de string e aritmética inteira do início ao fim — nenhum
/// valor monetário passa por `double` (regra inviolável do projeto).
library;

/// Formata centavos como `R$ 1.234,56` (sinal antes do símbolo).
String formatarCentavos(int centavos) {
  final negativo = centavos < 0;
  final absoluto = centavos.abs();
  final reais = (absoluto ~/ 100).toString();
  final resto = (absoluto % 100).toString().padLeft(2, '0');

  final comMilhar = StringBuffer();
  for (var i = 0; i < reais.length; i++) {
    if (i > 0 && (reais.length - i) % 3 == 0) comMilhar.write('.');
    comMilhar.write(reais[i]);
  }

  return '${negativo ? '-' : ''}R\$ $comMilhar,$resto';
}
