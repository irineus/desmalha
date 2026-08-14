import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

void main() {
  group('parseDataCivil', () {
    test('dd/MM/yyyy', () {
      expect(parseDataCivil('31/07/2026', 'dd/MM/yyyy'), '2026-07-31');
      expect(parseDataCivil('01/01/2026', 'dd/MM/yyyy'), '2026-01-01');
    });

    test('dígito único quando há separador', () {
      expect(parseDataCivil('1/7/2026', 'dd/MM/yyyy'), '2026-07-01');
    });

    test('outros separadores e ordens', () {
      expect(parseDataCivil('2026-07-31', 'yyyy-MM-dd'), '2026-07-31');
      expect(parseDataCivil('31-07-2026', 'dd-MM-yyyy'), '2026-07-31');
      expect(parseDataCivil('31.07.2026', 'dd.MM.yyyy'), '2026-07-31');
    });

    test('formatos compactos de largura fixa', () {
      expect(parseDataCivil('31072026', 'ddMMyyyy'), '2026-07-31');
      expect(parseDataCivil('20260731', 'yyyyMMdd'), '2026-07-31');
    });

    test('ano de dois dígitos com pivô', () {
      expect(parseDataCivil('31/07/26', 'dd/MM/yy'), '2026-07-31');
      expect(parseDataCivil('31/07/99', 'dd/MM/yy'), '1999-07-31');
    });

    test('espaços nas pontas são tolerados', () {
      expect(parseDataCivil('  31/07/2026 ', 'dd/MM/yyyy'), '2026-07-31');
    });

    test('data de calendário inválida', () {
      expect(parseDataCivil('31/02/2026', 'dd/MM/yyyy'), isNull);
      expect(parseDataCivil('00/07/2026', 'dd/MM/yyyy'), isNull);
      expect(parseDataCivil('31/13/2026', 'dd/MM/yyyy'), isNull);
    });

    test('bissexto: 29/02 só em ano bissexto', () {
      expect(parseDataCivil('29/02/2024', 'dd/MM/yyyy'), '2024-02-29');
      expect(parseDataCivil('29/02/2026', 'dd/MM/yyyy'), isNull);
      expect(parseDataCivil('29/02/2000', 'dd/MM/yyyy'), '2000-02-29');
      expect(parseDataCivil('29/02/2100', 'dd/MM/yyyy'), isNull);
    });

    test('não casa com o formato', () {
      expect(parseDataCivil('31-07-2026', 'dd/MM/yyyy'), isNull);
      expect(parseDataCivil('31/07', 'dd/MM/yyyy'), isNull);
      expect(parseDataCivil('31/07/2026 extra', 'dd/MM/yyyy'), isNull);
      expect(parseDataCivil('', 'dd/MM/yyyy'), isNull);
    });
  });

  group('parseDataOfx', () {
    test('só a data', () {
      expect(parseDataOfx('20260731'), '2026-07-31');
    });

    test('com hora e fuso', () {
      expect(parseDataOfx('20260731120000[-3:BRT]'), '2026-07-31');
      expect(parseDataOfx('20260731235959.000[-03:EST]'), '2026-07-31');
    });

    test('inválidos', () {
      expect(parseDataOfx('2026073'), isNull);
      expect(parseDataOfx('20261331'), isNull);
      expect(parseDataOfx('abcdefgh'), isNull);
    });
  });

  group('ehDataCivilValida', () {
    test('limites de dias por mês', () {
      expect(ehDataCivilValida(2026, 4, 30), isTrue);
      expect(ehDataCivilValida(2026, 4, 31), isFalse);
      expect(ehDataCivilValida(2026, 12, 31), isTrue);
    });

    test('anos fora da janela plausível de extrato', () {
      expect(ehDataCivilValida(1899, 1, 1), isFalse);
      expect(ehDataCivilValida(2201, 1, 1), isFalse);
    });
  });
}
