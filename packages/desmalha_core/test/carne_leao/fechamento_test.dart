import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

void main() {
  group('motivosQueImpedemFechar', () {
    test('recebimento a classificar impede; nada pendente libera', () {
      expect(motivosQueImpedemFechar(recebimentosAClassificar: 0), isEmpty);
      expect(motivosQueImpedemFechar(recebimentosAClassificar: 1),
          ['Falta classificar 1 recebimento do mês.']);
      expect(motivosQueImpedemFechar(recebimentosAClassificar: 3),
          ['Faltam classificar 3 recebimentos do mês.']);
    });
  });

  group('GuiaPaga', () {
    test('o período é a última competência, em qualquer ordem de entrada', () {
      final g = GuiaPaga(
        competencias: ['2026-02', '2026-01'],
        principalPagoCentavos: 1789,
      );
      expect(g.competencias, ['2026-01', '2026-02']);
      expect(g.periodo, '2026-02');
    });

    test('sem competência ou sem valor pago é recusada', () {
      expect(
        () => GuiaPaga(competencias: const [], principalPagoCentavos: 1),
        throwsArgumentError,
      );
      expect(
        () => GuiaPaga(competencias: const ['2026-03'], principalPagoCentavos: 0),
        throwsArgumentError,
      );
    });
  });

  group('acertoDaGuia', () {
    test('período ausente do recálculo = nada devido → pago a maior (P9)', () {
      final g = GuiaPaga(
        competencias: const ['2026-03'],
        principalPagoCentavos: 39454,
      );
      final a = acertoDaGuia(g, const {});
      expect(a, isA<AcertoPagoAMaior>());
      expect((a as AcertoPagoAMaior).diferencaCentavos, 39454);
    });
  });

  group('acertoPedeRetificadora (P15, rodada 5)', () {
    final guia = GuiaPaga(
      competencias: const ['2026-12'],
      principalPagoCentavos: 39454,
    );

    test('acerto de ano anterior pede a retificadora', () {
      expect(
        acertoPedeRetificadora(
          AcertoComplementar(guia,
              competencia: '2026-12', diferencaCentavos: 40814),
          '2027-05-10',
        ),
        isTrue,
      );
    });

    test('no mesmo ano, ou sem diferença, não', () {
      expect(
        acertoPedeRetificadora(
          AcertoPagoAMaior(guia, diferencaCentavos: 100),
          '2026-12-20',
        ),
        isFalse,
      );
      expect(acertoPedeRetificadora(AcertoEmDia(guia), '2027-05-10'),
          isFalse);
    });
  });
}
