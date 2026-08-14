import 'dart:convert';

import 'package:desmalha_core/validacao.dart';
import 'package:test/test.dart';

void main() {
  group('decodificarComDiagnostico', () {
    test('UTF-8 válido é reportado como utf-8', () {
      final resultado =
          decodificarComDiagnostico(utf8.encode('Consulta médica'));
      expect(resultado.texto, 'Consulta médica');
      expect(resultado.encoding, 'utf-8');
      expect(resultado.comBom, isFalse);
    });

    test('BOM UTF-8 é detectado e consumido', () {
      final resultado = decodificarComDiagnostico(
          [0xEF, 0xBB, 0xBF, ...utf8.encode('Pix')]);
      expect(resultado.texto, 'Pix');
      expect(resultado.encoding, 'utf-8');
      expect(resultado.comBom, isTrue);
    });

    test('bytes inválidos em UTF-8 caem para windows-1252', () {
      // 'médica' em Latin-1/CP1252: 0xE9 solto é inválido em UTF-8.
      final resultado = decodificarComDiagnostico(
          [0x6D, 0xE9, 0x64, 0x69, 0x63, 0x61]);
      expect(resultado.texto, 'médica');
      expect(resultado.encoding, 'windows-1252');
    });

    test('encoding explícito vence a autodetecção', () {
      final resultado = decodificarComDiagnostico(
        [0x41, 0x42],
        encoding: 'latin1',
      );
      expect(resultado.encoding, 'latin-1');
      expect(resultado.texto, 'AB');
    });

    test('charset desconhecido falha alto', () {
      expect(
        () => decodificarComDiagnostico([0x41], encoding: 'utf-16'),
        throwsArgumentError,
      );
    });
  });

  group('detectarFormato', () {
    test('conteúdo com <OFX> é OFX, qualquer que seja o nome', () {
      expect(
        detectarFormato('<OFX><BANKMSGSRSV1/></OFX>', nomeArquivo: 'x.csv'),
        FormatoDetectado.ofx,
      );
    });

    test('cabeçalho OFXHEADER basta (SGML antes do <OFX>)', () {
      expect(
        detectarFormato('OFXHEADER:100\nDATA:OFXSGML'),
        FormatoDetectado.ofx,
      );
    });

    test('extensão .ofx desempata quando o conteúdo não decide', () {
      expect(
        detectarFormato('qualquer coisa', nomeArquivo: 'extrato.OFX'),
        FormatoDetectado.ofx,
      );
    });

    test('sem indício de OFX é CSV', () {
      expect(
        detectarFormato('Data,Valor\n01/07/2026,10.00',
            nomeArquivo: 'extrato.csv'),
        FormatoDetectado.csv,
      );
    });
  });
}
