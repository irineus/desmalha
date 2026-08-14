import 'package:desmalha_core/validacao.dart';
import 'package:test/test.dart';

void main() {
  group('formatarCentavos', () {
    test('valores simples', () {
      expect(formatarCentavos(0), 'R\$ 0,00');
      expect(formatarCentavos(1), 'R\$ 0,01');
      expect(formatarCentavos(100), 'R\$ 1,00');
      expect(formatarCentavos(123456), 'R\$ 1.234,56');
    });

    test('negativos', () {
      expect(formatarCentavos(-1), '-R\$ 0,01');
      expect(formatarCentavos(-123456), '-R\$ 1.234,56');
    });

    test('separador de milhar em valores grandes', () {
      expect(formatarCentavos(100000000), 'R\$ 1.000.000,00');
      expect(formatarCentavos(123456789012), 'R\$ 1.234.567.890,12');
    });
  });
}
