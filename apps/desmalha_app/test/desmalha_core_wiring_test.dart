// Fumaça da integração monorepo: o app resolve e executa código do
// desmalha_core via dependência de path.
import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app enxerga o desmalha_core', () {
    expect(centavosParaExibicao(123456), 'R\$ 1.234,56');
  });
}
