/// Código de recuperação do backup — o que destrava a chave-mestra em outro
/// aparelho.
///
/// Quem perde o aparelho E o código perde os dados, e o operador não tem
/// como ajudar (consequência aceita no ADR local-first). Por isso o código é
/// feito para ser anotado À MÃO e digitado de volta sem erro:
///
/// - **Crockford base32** (`0-9 A-Z` sem `I L O U`): nada que se confunda
///   escrevendo ou lendo; na volta, `O` vira `0` e `I`/`L` viram `1`, caixa e
///   espaços não importam.
/// - **25 símbolos em 5 grupos de 5** (`K7M2Q-…`): 125 bits de entropia — a
///   KEK ainda passa por Argon2id de 64 MiB, mas a força não depende dele.
/// - A confirmação pede para redigitar grupos sorteados: prova que a pessoa
///   anotou, sem exigir que redigite tudo.
library;

import 'dart:math';

/// Alfabeto de Crockford, na ordem canônica.
const String alfabetoCodigoRecuperacao = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

const int gruposDoCodigo = 5;
const int simbolosPorGrupo = 5;

/// Gera um código novo no formato canônico `XXXXX-XXXXX-XXXXX-XXXXX-XXXXX`.
String gerarCodigoRecuperacao([Random? aleatorio]) {
  final rnd = aleatorio ?? Random.secure();
  return [
    for (var g = 0; g < gruposDoCodigo; g++)
      String.fromCharCodes([
        for (var i = 0; i < simbolosPorGrupo; i++)
          alfabetoCodigoRecuperacao.codeUnitAt(
            rnd.nextInt(alfabetoCodigoRecuperacao.length),
          ),
      ]),
  ].join('-');
}

/// Leva o que a pessoa digitou ao formato canônico, ou `null` se não é um
/// código possível. É o formato canônico que alimenta o Argon2id — o mesmo
/// código digitado de jeitos diferentes tem de derivar a mesma chave.
String? normalizarCodigoRecuperacao(String entrada) {
  final simbolos = _normalizarSimbolos(entrada);
  if (simbolos == null ||
      simbolos.length != gruposDoCodigo * simbolosPorGrupo) {
    return null;
  }
  return [
    for (var g = 0; g < gruposDoCodigo; g++)
      simbolos.substring(g * simbolosPorGrupo, (g + 1) * simbolosPorGrupo),
  ].join('-');
}

/// Dois grupos distintos (índices 0..4, em ordem) para a confirmação.
List<int> sortearGruposParaConfirmar([Random? aleatorio]) {
  final rnd = aleatorio ?? Random.secure();
  final indices = List<int>.generate(gruposDoCodigo, (i) => i)..shuffle(rnd);
  return indices.take(2).toList()..sort();
}

/// `true` se [digitado] é o grupo [indice] do código [canonico] — com a
/// mesma tolerância da normalização (caixa, espaços, O/0, I/L/1).
bool grupoConfere(String canonico, int indice, String digitado) {
  final grupos = canonico.split('-');
  if (indice < 0 || indice >= grupos.length) return false;
  return _normalizarSimbolos(digitado) == grupos[indice];
}

/// Um grupo digitado no formato canônico (5 símbolos), ou `null` — mesma
/// tolerância do código inteiro. Usado pelo lembrete de 90 dias, que
/// confere grupos contra o verificador do aparelho.
String? normalizarGrupoRecuperacao(String digitado) {
  final s = _normalizarSimbolos(digitado);
  return s == null || s.length != simbolosPorGrupo ? null : s;
}

String? _normalizarSimbolos(String entrada) {
  final buffer = StringBuffer();
  for (final c in entrada.toUpperCase().runes) {
    final s = String.fromCharCode(c);
    if (s == ' ' || s == '-' || s == '\t') continue;
    final mapeado = switch (s) {
      'O' => '0',
      'I' || 'L' => '1',
      _ => s,
    };
    if (!alfabetoCodigoRecuperacao.contains(mapeado)) return null;
    buffer.write(mapeado);
  }
  return buffer.toString();
}
