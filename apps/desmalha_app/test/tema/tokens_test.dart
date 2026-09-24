// Os tokens do app são TRANSCRIÇÃO do documento de design versionado. Este
// teste lê o `:root` de docs/design/desmalha-design-system.html e reprova se
// uma cor, um raio ou um espaçamento divergir — o design muda no documento, e
// o app acompanha ou fica vermelho.

import 'dart:io';

import 'package:desmalha_app/tema/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _documento = '../../docs/design/desmalha-design-system.html';

Map<String, String> _variaveisDoRoot() {
  final html = File(_documento).readAsStringSync();
  final root = RegExp(r':root\s*\{(.*?)\}', dotAll: true).firstMatch(html);
  if (root == null) throw StateError(':root ausente do documento de design');
  return {
    for (final m in RegExp(r'--([a-z0-9-]+)\s*:\s*([^;]+);')
        .allMatches(root.group(1)!))
      m.group(1)!: m.group(2)!.trim(),
  };
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

void main() {
  final v = _variaveisDoRoot();

  test('o documento de design está versionado e tem os onze papéis', () {
    expect(v.keys, containsAll(_cores.keys));
  });

  for (final entrada in _cores.entries) {
    test('cor --${entrada.key}', () {
      expect(_hex(entrada.value), v[entrada.key]!.toUpperCase());
    });
  }

  test('raios --r-sm/md/lg', () {
    expect('${RaiosDesmalha.pequeno.toInt()}px', v['r-sm']);
    expect('${RaiosDesmalha.medio.toInt()}px', v['r-md']);
    expect('${RaiosDesmalha.grande.toInt()}px', v['r-lg']);
  });

  test('espaçamentos --s1 a --s8', () {
    const escala = [
      EspacosDesmalha.s1,
      EspacosDesmalha.s2,
      EspacosDesmalha.s3,
      EspacosDesmalha.s4,
      EspacosDesmalha.s5,
      EspacosDesmalha.s6,
      EspacosDesmalha.s7,
      EspacosDesmalha.s8,
    ];
    for (var i = 0; i < escala.length; i++) {
      expect('${escala[i].toInt()}px', v['s${i + 1}'], reason: 's${i + 1}');
    }
  });
}

const _cores = <String, Color>{
  'papel': CoresDesmalha.papel,
  'superficie': CoresDesmalha.superficie,
  'tinta': CoresDesmalha.tinta,
  'tinta-fraca': CoresDesmalha.tintaFraca,
  'salvia': CoresDesmalha.salvia,
  'salvia-escura': CoresDesmalha.salviaEscura,
  'salvia-clara': CoresDesmalha.salviaClara,
  'obrigacao': CoresDesmalha.obrigacao,
  'obrigacao-bg': CoresDesmalha.obrigacaoFundo,
  'falha': CoresDesmalha.falha,
  'linha': CoresDesmalha.linha,
};
