import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

void main() {
  group('codificarItf', () {
    test('abre com a guarda de início e fecha com a de fim', () {
      final elementos = codificarItf('01');
      expect(elementos.take(4), [
        const ElementoItf(ehBarra: true, modulos: 1),
        const ElementoItf(ehBarra: false, modulos: 1),
        const ElementoItf(ehBarra: true, modulos: 1),
        const ElementoItf(ehBarra: false, modulos: 1),
      ]);
      expect(elementos.skip(elementos.length - 3), [
        const ElementoItf(ehBarra: true, modulos: 3),
        const ElementoItf(ehBarra: false, modulos: 1),
        const ElementoItf(ehBarra: true, modulos: 1),
      ]);
    });

    test('intercala: o 1º dígito do par vira barras, o 2º vira espaços', () {
      // 0 = estreito, estreito, largo, largo, estreito (barras)
      // 1 = largo, estreito, estreito, estreito, largo (espaços)
      final miolo = codificarItf('01').skip(4).take(10).toList();
      expect(miolo.map((e) => e.ehBarra), [
        true, false, true, false, true, false, true, false, true, false, //
      ]);
      expect(miolo.map((e) => e.modulos), [
        1, 3, // barra estreita do 0, espaço largo do 1
        1, 1, //
        3, 1, //
        3, 1, //
        1, 3, //
      ]);
    });

    test('alterna barra e espaço do começo ao fim', () {
      final elementos = codificarItf('8' * 44);
      for (var i = 0; i < elementos.length; i++) {
        expect(elementos[i].ehBarra, i.isEven,
            reason: 'elemento $i deveria ${i.isEven ? 'ser' : 'não ser'} barra');
      }
    });

    test('44 dígitos ocupam 405 módulos na razão 3:1', () {
      // 4 (guarda) + 22 pares × 18 + 5 (fim) = 405. Fixar isso protege o
      // dimensionamento do desenho: se a geometria mudar, o teste avisa.
      expect(larguraEmModulos(codificarItf('0' * 44)), 405);
    });

    test('a razão 2:1 encurta o símbolo e continua válida', () {
      final elementos = codificarItf('0' * 44, modulosLargo: 2);
      expect(larguraEmModulos(elementos), 4 + 22 * 14 + 4);
      expect(elementos.every((e) => e.modulos == 1 || e.modulos == 2), isTrue);
    });

    test('recusa quantidade ímpar de dígitos', () {
      expect(() => codificarItf('123'), throwsArgumentError);
    });

    test('recusa entrada vazia, não numérica e razão fora de 2 a 3', () {
      expect(() => codificarItf(''), throwsArgumentError);
      expect(() => codificarItf('1a'), throwsArgumentError);
      expect(() => codificarItf('12', modulosLargo: 4), throwsArgumentError);
      expect(() => codificarItf('12', modulosLargo: 1), throwsArgumentError);
    });

    test('a geometria volta a ser os mesmos dígitos quando decodificada', () {
      // Decodifica a partir das larguras, como faz um leitor óptico. Protege
      // a ordem da intercalação: trocar barras por espaços produziria um
      // símbolo que passa nos testes de contagem mas lê outro número.
      const digitos = '85870000003944612340190529982247252026030000';
      expect(_decodificarItf(codificarItf(digitos)), digitos);
    });

    test('cada dígito usa exatamente dois elementos largos', () {
      for (var d = 0; d <= 9; d++) {
        final barras =
            codificarItf('${d}0').skip(4).take(10).where((e) => e.ehBarra);
        expect(barras.where((e) => e.modulos == 3).length, 2,
            reason: 'dígito $d deveria ter 2 barras largas');
      }
    });
  });
}

/// Decodificador de referência, escrito a partir da tabela do padrão ITF e
/// independente da implementação: lê as larguras e devolve os dígitos.
///
/// A chave é a posição dos dois elementos largos entre os cinco do dígito.
const Map<String, String> _tabelaLeitura = {
  '23': '0',
  '04': '1',
  '14': '2',
  '01': '3',
  '24': '4',
  '02': '5',
  '12': '6',
  '34': '7',
  '03': '8',
  '13': '9',
};

String _decodificarItf(List<ElementoItf> elementos) {
  final miolo = elementos.sublist(4, elementos.length - 3);
  final digitos = StringBuffer();
  for (var i = 0; i < miolo.length; i += 10) {
    final bloco = miolo.sublist(i, i + 10);
    final barras = [for (var j = 0; j < 10; j += 2) bloco[j].modulos > 1];
    final espacos = [for (var j = 1; j < 10; j += 2) bloco[j].modulos > 1];
    digitos
      ..write(_tabelaLeitura[_chave(barras)])
      ..write(_tabelaLeitura[_chave(espacos)]);
  }
  return digitos.toString();
}

String _chave(List<bool> largos) => [
      for (var i = 0; i < largos.length; i++)
        if (largos[i]) '$i',
    ].join();
