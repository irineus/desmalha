import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

void main() {
  group('dvModulo10Arrecadacao', () {
    test('soma pesos 2 e 1 da direita para a esquerda', () {
      // '1234' → 4×2=8, 3×1=3, 2×2=4, 1×1=1 → soma 16 → DV = (10−6)%10 = 4.
      expect(dvModulo10Arrecadacao('1234'), '4');
    });

    test('soma os algarismos quando o produto passa de 9', () {
      // '9' → 9×2 = 18 → 1+8 = 9 → DV = 10−9 = 1.
      expect(dvModulo10Arrecadacao('9'), '1');
    });

    test('resto zero produz DV zero, não dez', () {
      expect(dvModulo10Arrecadacao('0000'), '0');
    });

    test('recusa entrada não numérica', () {
      expect(() => dvModulo10Arrecadacao('12a4'), throwsArgumentError);
      expect(() => dvModulo10Arrecadacao(''), throwsArgumentError);
    });
  });

  group('dvModulo11Arrecadacao', () {
    test('pesos de 2 a 9 da direita para a esquerda', () {
      // '1234' → 4×2 + 3×3 + 2×4 + 1×5 = 30 → resto 8 → DV = 11−8 = 3.
      expect(dvModulo11Arrecadacao('1234'), '3');
    });

    test('reinicia o peso em 2 depois do 9', () {
      // '111111111' → pesos 2..9 e volta a 2 → soma 46 → resto 2 → DV 9.
      expect(dvModulo11Arrecadacao('111111111'), '9');
    });

    test('resto 0 e resto 1 produzem DV 0', () {
      expect(dvModulo11Arrecadacao('0000'), '0'); // soma 0 → resto 0
      expect(dvModulo11Arrecadacao('6'), '0'); // 6×2 = 12 → resto 1
    });

    test('resto 10 produz DV 1', () {
      expect(dvModulo11Arrecadacao('5'), '1'); // 5×2 = 10 → resto 10
    });
  });

  group('CodigoBarrasArrecadacao.montar', () {
    CodigoBarrasArrecadacao exemplo({
      IdentificadorValor identificador = IdentificadorValor.valorEfetivoModulo10,
      int valorCentavos = 39454,
    }) =>
        CodigoBarrasArrecadacao.montar(
          segmento: 5,
          identificadorValor: identificador,
          valorCentavos: valorCentavos,
          identificacaoOrgao: '1234',
          campoLivre: '0190123456789012345678901'.substring(0, 25),
        );

    test('produz 44 dígitos com produto 8 na primeira posição', () {
      final codigo = exemplo();
      expect(codigo.digitos, hasLength(44));
      expect(codigo.digitos[0], '8');
      expect(RegExp(r'^\d{44}$').hasMatch(codigo.digitos), isTrue);
    });

    test('expõe as partes nas posições do padrão', () {
      final codigo = exemplo();
      expect(codigo.segmento, 5);
      expect(codigo.identificadorValor,
          IdentificadorValor.valorEfetivoModulo10);
      expect(codigo.valorCentavos, 39454);
      expect(codigo.identificacaoOrgao, '1234');
      expect(codigo.campoLivre, hasLength(25));
    });

    test('valor entra como 11 dígitos de centavos, com zeros à esquerda', () {
      final codigo = exemplo(valorCentavos: 1000);
      expect(codigo.digitos.substring(4, 15), '00000001000');
      expect(codigo.valorCentavos, 1000);
    });

    test('identificador 8 troca o DV geral para módulo 11', () {
      final porDez = exemplo();
      final porOnze =
          exemplo(identificador: IdentificadorValor.valorEfetivoModulo11);
      // Mesmos dados, DV calculado por módulos diferentes: o padrão amarra a
      // escolha do módulo ao dígito da posição 3, e não à preferência de quem
      // emite.
      expect(porOnze.identificadorValor.usaModulo11, isTrue);
      expect(porDez.identificadorValor.usaModulo11, isFalse);
      expect(porOnze.digitos.substring(4), porDez.digitos.substring(4));
    });

    test('recusa partes fora do tamanho e valores impossíveis', () {
      expect(
        () => CodigoBarrasArrecadacao.montar(
          segmento: 5,
          identificadorValor: IdentificadorValor.valorEfetivoModulo10,
          valorCentavos: 100,
          identificacaoOrgao: '123',
          campoLivre: '0' * 25,
        ),
        throwsArgumentError,
      );
      expect(
        () => CodigoBarrasArrecadacao.montar(
          segmento: 5,
          identificadorValor: IdentificadorValor.valorEfetivoModulo10,
          valorCentavos: 100,
          identificacaoOrgao: '1234',
          campoLivre: '0' * 24,
        ),
        throwsArgumentError,
      );
      expect(
        () => CodigoBarrasArrecadacao.montar(
          segmento: 0,
          identificadorValor: IdentificadorValor.valorEfetivoModulo10,
          valorCentavos: 100,
          identificacaoOrgao: '1234',
          campoLivre: '0' * 25,
        ),
        throwsArgumentError,
      );
      expect(
        () => CodigoBarrasArrecadacao.montar(
          segmento: 5,
          identificadorValor: IdentificadorValor.valorEfetivoModulo10,
          valorCentavos: -1,
          identificacaoOrgao: '1234',
          campoLivre: '0' * 25,
        ),
        throwsArgumentError,
      );
      expect(
        () => CodigoBarrasArrecadacao.montar(
          segmento: 5,
          identificadorValor: IdentificadorValor.valorEfetivoModulo10,
          valorCentavos: valorMaximoCodigoBarrasCentavos + 1,
          identificacaoOrgao: '1234',
          campoLivre: '0' * 25,
        ),
        throwsArgumentError,
      );
    });
  });

  group('CodigoBarrasArrecadacao.parse', () {
    final original = CodigoBarrasArrecadacao.montar(
      segmento: 5,
      identificadorValor: IdentificadorValor.valorEfetivoModulo11,
      valorCentavos: 39454,
      identificacaoOrgao: '1234',
      campoLivre: '0' * 25,
    );

    test('faz round-trip com o código montado', () {
      expect(CodigoBarrasArrecadacao.parse(original.digitos), original);
    });

    test('ignora espaços e separadores da digitação', () {
      final espacado = '${original.digitos.substring(0, 11)} '
          '${original.digitos.substring(11, 22)} '
          '${original.digitos.substring(22, 33)} '
          '${original.digitos.substring(33)}';
      expect(CodigoBarrasArrecadacao.parse(espacado), original);
    });

    test('recusa DV geral adulterado', () {
      final dvErrado = original.dvGeral == '9' ? '8' : '9';
      final adulterado =
          '${original.digitos.substring(0, 3)}$dvErrado'
          '${original.digitos.substring(4)}';
      expect(
        () => CodigoBarrasArrecadacao.parse(adulterado),
        throwsFormatException,
      );
    });

    test('recusa comprimento errado e produto diferente de 8', () {
      expect(
        () => CodigoBarrasArrecadacao.parse('8' * 43),
        throwsFormatException,
      );
      expect(
        () => CodigoBarrasArrecadacao.parse('7${original.digitos.substring(1)}'),
        throwsFormatException,
      );
    });
  });

  group('linha digitável', () {
    final codigo = CodigoBarrasArrecadacao.montar(
      segmento: 5,
      identificadorValor: IdentificadorValor.valorEfetivoModulo10,
      valorCentavos: 12345,
      identificacaoOrgao: '9876',
      campoLivre: '1234567890123456789012345',
    );

    test('tem 48 dígitos: quatro blocos de 11 mais um DV cada', () {
      expect(codigo.linhaDigitavel, hasLength(48));
      expect(RegExp(r'^\d{48}$').hasMatch(codigo.linhaDigitavel), isTrue);
    });

    test('cada bloco carrega o DV de módulo 10 dos seus 11 dígitos', () {
      final linha = codigo.linhaDigitavel;
      for (var i = 0; i < 4; i++) {
        final bloco = codigo.digitos.substring(i * 11, (i + 1) * 11);
        expect(linha.substring(i * 12, i * 12 + 11), bloco);
        expect(linha[i * 12 + 11], dvModulo10Arrecadacao(bloco));
      }
    });

    test('a versão formatada preserva os mesmos dígitos', () {
      final formatada = codigo.linhaDigitavelFormatada;
      expect(formatada.split(' '), hasLength(4));
      expect(formatada.replaceAll(RegExp(r'[ -]'), ''), codigo.linhaDigitavel);
    });
  });

  group('IdentificadorValor', () {
    test('resolve pelo dígito', () {
      expect(IdentificadorValor.doDigito('6'),
          IdentificadorValor.valorEfetivoModulo10);
      expect(IdentificadorValor.doDigito('9'),
          IdentificadorValor.valorReferenciaModulo11);
    });

    test('recusa dígito fora de 6 a 9', () {
      expect(() => IdentificadorValor.doDigito('5'), throwsFormatException);
    });
  });
}
