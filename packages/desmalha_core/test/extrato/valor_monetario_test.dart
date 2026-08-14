import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

void main() {
  group('parseValorMonetario — vírgula decimal (padrão brasileiro)', () {
    int? parse(String s) => parseValorMonetario(s, FormatoValor.virgulaDecimal);

    test('valores simples', () {
      expect(parse('150,00'), 15000);
      expect(parse('0,09'), 9);
      expect(parse('1234,5'), 123450);
      expect(parse('1234'), 123400);
    });

    test('milhar com ponto', () {
      expect(parse('1.234,56'), 123456);
      expect(parse('1.234.567,89'), 123456789);
    });

    test('sinais e símbolo de moeda', () {
      expect(parse('-150,00'), -15000);
      expect(parse('+150,00'), 15000);
      expect(parse('150,00-'), -15000);
      expect(parse('R\$ 1.234,56'), 123456);
      expect(parse('-R\$ 0,09'), -9);
      expect(parse('(123,45)'), -12345);
    });

    test('fração sem parte inteira', () {
      expect(parse(',56'), 56);
    });

    test('casas decimais além de duas só quando forem zero', () {
      expect(parse('12,340'), 1234);
      expect(parse('12,3400'), 1234);
      expect(parse('12,345'), isNull);
    });

    test('entradas inválidas', () {
      expect(parse(''), isNull);
      expect(parse('   '), isNull);
      expect(parse('abc'), isNull);
      expect(parse('12,34,56'), isNull);
      expect(parse('12a,34'), isNull);
      expect(parse('-'), isNull);
    });
  });

  group('parseValorMonetario — ponto decimal', () {
    int? parse(String s) => parseValorMonetario(s, FormatoValor.pontoDecimal);

    test('valores simples', () {
      expect(parse('150.00'), 15000);
      expect(parse('-1234.5'), -123450);
      expect(parse('1,234.56'), 123456);
      expect(parse('7'), 700);
    });
  });

  group('parseValorOfx', () {
    test('ponto decimal (especificação)', () {
      expect(parseValorOfx('-150.00'), -15000);
      expect(parseValorOfx('2500.9'), 250090);
      expect(parseValorOfx('1234'), 123400);
    });

    test('vírgula decimal (bancos brasileiros)', () {
      expect(parseValorOfx('-150,00'), -15000);
      expect(parseValorOfx('2500,90'), 250090);
    });

    test('separador de milhar não existe em TRNAMT', () {
      expect(parseValorOfx('1.234,56'), isNull);
      expect(parseValorOfx('1,234.56'), isNull);
    });
  });
}
