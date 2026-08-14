import 'dart:convert';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

void main() {
  group('decodificarExtrato — autodetecção', () {
    test('UTF-8 válido', () {
      final bytes = utf8.encode('Transferência Pix — João');
      expect(decodificarExtrato(bytes), 'Transferência Pix — João');
    });

    test('BOM UTF-8 é removido', () {
      final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode('Data,Valor')];
      expect(decodificarExtrato(bytes), 'Data,Valor');
    });

    test('bytes inválidos em UTF-8 caem para Windows-1252', () {
      // "Transferência" em Latin-1/CP1252: 'ê' = 0xEA, inválido em UTF-8.
      final bytes = latin1.encode('Transferência');
      expect(decodificarExtrato(bytes), 'Transferência');
    });

    test('faixa alta do CP1252 vira caractere tipográfico', () {
      // 0x93/0x94 são “ ” no CP1252 (indefinidos no Latin-1).
      final bytes = [0x93, 0x50, 0x69, 0x78, 0x94];
      expect(decodificarExtrato(bytes), '“Pix”');
    });
  });

  group('decodificarExtrato — charset explícito', () {
    test('latin-1 preserva bytes da faixa alta como Latin-1', () {
      final bytes = latin1.encode('ção');
      expect(decodificarExtrato(bytes, encoding: 'latin-1'), 'ção');
      expect(decodificarExtrato(bytes, encoding: 'iso-8859-1'), 'ção');
    });

    test('utf-8 estrito lança em bytes inválidos', () {
      expect(
        () => decodificarExtrato([0xEA], encoding: 'utf-8'),
        throwsFormatException,
      );
    });

    test('cp1252 e windows-1252 são sinônimos', () {
      expect(decodificarExtrato([0x80], encoding: 'cp1252'), '€');
      expect(decodificarExtrato([0x80], encoding: 'windows-1252'), '€');
    });

    test('charset desconhecido lança ArgumentError', () {
      expect(
        () => decodificarExtrato([0x41], encoding: 'utf-16'),
        throwsArgumentError,
      );
    });
  });
}
