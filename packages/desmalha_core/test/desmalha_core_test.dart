import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

void main() {
  group('centavosParaExibicao', () {
    test('zero', () {
      expect(centavosParaExibicao(0), 'R\$ 0,00');
    });

    test('menos de um real mantém dois dígitos de centavos', () {
      expect(centavosParaExibicao(9), 'R\$ 0,09');
      expect(centavosParaExibicao(99), 'R\$ 0,99');
    });

    test('valores sem separador de milhar', () {
      expect(centavosParaExibicao(100), 'R\$ 1,00');
      expect(centavosParaExibicao(99999), 'R\$ 999,99');
    });

    test('separador de milhar com ponto, decimal com vírgula', () {
      expect(centavosParaExibicao(123456), 'R\$ 1.234,56');
      expect(centavosParaExibicao(100000000), 'R\$ 1.000.000,00');
      expect(centavosParaExibicao(123456789012), 'R\$ 1.234.567.890,12');
    });

    test('negativos levam o sinal antes do R\$', () {
      expect(centavosParaExibicao(-9), '-R\$ 0,09');
      expect(centavosParaExibicao(-123456), '-R\$ 1.234,56');
    });
  });
}
