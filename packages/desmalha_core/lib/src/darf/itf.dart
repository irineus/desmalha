/// Codificação Interleaved 2 of 5 (ITF), a simbologia do código de barras de
/// arrecadação da FEBRABAN.
///
/// Produz apenas a geometria — larguras de barras e espaços em módulos. Quem
/// desenha (PDF, tela) decide quanto vale um módulo. Nenhuma dependência de
/// renderização entra aqui.
///
/// "Interleaved" porque os dígitos andam em pares: o primeiro do par vira as
/// barras, o segundo vira os espaços entre elas. Daí a exigência de
/// quantidade PAR de dígitos — os 44 do padrão de arrecadação satisfazem.
library;

/// Padrões de largura por dígito: `false` = estreito, `true` = largo.
/// Cada dígito são cinco elementos, dois deles largos (daí "2 of 5").
const List<List<bool>> _padroes = [
  [false, false, true, true, false], // 0
  [true, false, false, false, true], // 1
  [false, true, false, false, true], // 2
  [true, true, false, false, false], // 3
  [false, false, true, false, true], // 4
  [true, false, true, false, false], // 5
  [false, true, true, false, false], // 6
  [false, false, false, true, true], // 7
  [true, false, false, true, false], // 8
  [false, true, false, true, false], // 9
];

/// Um elemento do código de barras: uma barra ou um espaço, com sua largura.
class ElementoItf {
  const ElementoItf({required this.ehBarra, required this.modulos});

  /// `true` para barra (preta), `false` para espaço (branco).
  final bool ehBarra;

  /// Largura em módulos.
  final int modulos;

  @override
  bool operator ==(Object other) =>
      other is ElementoItf &&
      other.ehBarra == ehBarra &&
      other.modulos == modulos;

  @override
  int get hashCode => Object.hash(ehBarra, modulos);

  @override
  String toString() => '${ehBarra ? 'barra' : 'espaço'}($modulos)';
}

/// Codifica [digitos] em ITF.
///
/// [modulosLargo] é a razão largo:estreito, que o padrão ITF permite entre
/// 2 e 3. O default 3 é o usado pelas implementações de arrecadação: dá mais
/// tolerância de leitura quando o módulo é impresso pequeno.
///
/// A saída sempre alterna barra e espaço, começando por barra: guarda de
/// início (barra, espaço, barra, espaço estreitos), os pares de dígitos e a
/// guarda de fim (barra larga, espaço estreito, barra estreita).
List<ElementoItf> codificarItf(String digitos, {int modulosLargo = 3}) {
  if (digitos.isEmpty) {
    throw ArgumentError.value(digitos, 'digitos', 'não pode ser vazio');
  }
  if (digitos.length.isOdd) {
    throw ArgumentError.value(
      digitos,
      'digitos',
      'ITF exige quantidade par de dígitos (recebidos ${digitos.length})',
    );
  }
  if (modulosLargo < 2 || modulosLargo > 3) {
    throw ArgumentError.value(
      modulosLargo,
      'modulosLargo',
      'a razão largo:estreito do ITF vai de 2 a 3',
    );
  }

  final elementos = <ElementoItf>[
    const ElementoItf(ehBarra: true, modulos: 1),
    const ElementoItf(ehBarra: false, modulos: 1),
    const ElementoItf(ehBarra: true, modulos: 1),
    const ElementoItf(ehBarra: false, modulos: 1),
  ];

  for (var i = 0; i < digitos.length; i += 2) {
    final barras = _padrao(digitos, i);
    final espacos = _padrao(digitos, i + 1);
    for (var j = 0; j < 5; j++) {
      elementos
        ..add(ElementoItf(
          ehBarra: true,
          modulos: barras[j] ? modulosLargo : 1,
        ))
        ..add(ElementoItf(
          ehBarra: false,
          modulos: espacos[j] ? modulosLargo : 1,
        ));
    }
  }

  elementos
    ..add(ElementoItf(ehBarra: true, modulos: modulosLargo))
    ..add(const ElementoItf(ehBarra: false, modulos: 1))
    ..add(const ElementoItf(ehBarra: true, modulos: 1));

  return elementos;
}

/// Largura total do símbolo em módulos, sem as margens de silêncio.
int larguraEmModulos(List<ElementoItf> elementos) =>
    elementos.fold(0, (total, elemento) => total + elemento.modulos);

List<bool> _padrao(String digitos, int posicao) {
  final codigo = digitos.codeUnitAt(posicao) - 0x30;
  if (codigo < 0 || codigo > 9) {
    throw ArgumentError.value(
      digitos,
      'digitos',
      'caractere não numérico na posição $posicao',
    );
  }
  return _padroes[codigo];
}
