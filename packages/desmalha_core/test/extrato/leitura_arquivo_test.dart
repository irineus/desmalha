import 'dart:convert';
import 'dart:io';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

import '../fixtures/sinteticas/gerador.dart';

void main() {
  final nubank = PerfilCsv.fromJson(
    jsonDecode(File('perfis/nubank-conta-csv-v1.json').readAsStringSync())
        as Map<String, Object?>,
  );
  const csvNubank =
      'Data,Valor,Identificador,Descrição\n'
      '03/08/2026,450.00,id-1,Transferência recebida pelo Pix - ANA\n'
      '05/08/2026,-89.90,id-2,Compra no débito - MERCADO\n';

  group('detectarFormatoExtrato', () {
    // As 8 sintéticas cobrem SGML e XML, UTF-8 com e sem BOM, Latin-1 e
    // cp1252, CRLF e LF: o conteúdo manda, em todas.
    for (final f in gerarFixtures()) {
      test('OFX: ${f.especificacao.arquivo}', () {
        expect(detectarFormatoExtrato(f.bytes), FormatoExtrato.ofx);
      });
    }

    test('CSV do Nubank', () {
      expect(
        detectarFormatoExtrato(utf8.encode(csvNubank)),
        FormatoExtrato.csv,
      );
    });
  });

  group('lerArquivoDeExtrato', () {
    test('OFX: o mesmo que o parser devolve para a fixture', () {
      for (final f in gerarFixtures()) {
        final extrato = lerArquivoDeExtrato(f.bytes);
        expect(extrato.formato, FormatoExtrato.ofx);
        expect(
          extrato.transacoes,
          f.transacoes,
          reason: f.especificacao.arquivo,
        );
      }
    });

    test('CSV com o perfil do banco', () {
      final extrato = lerArquivoDeExtrato(
        utf8.encode(csvNubank),
        perfil: nubank,
      );
      expect(extrato.formato, FormatoExtrato.csv);
      expect(
        [for (final t in extrato.transacoes) t.valorCentavos],
        [45000, -8990],
      );
      expect(periodoDoExtrato(extrato), ('2026-08-03', '2026-08-05'));
    });

    test('CSV sem perfil: não adivinha o banco', () {
      expect(
        () => lerArquivoDeExtrato(utf8.encode(csvNubank)),
        throwsArgumentError,
      );
    });

    test('arquivo vazio é inválido', () {
      expect(
        () => lerArquivoDeExtrato(const []),
        throwsA(isA<ExtratoInvalidoException>()),
      );
    });

    test('extrato sem lançamentos: período nulo', () {
      final vazia = gerarFixtures().firstWhere(
        (f) => f.especificacao.quantidade == 0,
      );
      expect(periodoDoExtrato(lerArquivoDeExtrato(vazia.bytes)), isNull);
    });
  });
}
