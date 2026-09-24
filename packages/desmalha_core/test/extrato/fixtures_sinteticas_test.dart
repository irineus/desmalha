// As fixtures sintéticas de OFX: o que elas provam, e a trava contra a
// uniformidade que desmascarou as de 16/ago/2026. Ver
// test/fixtures/sinteticas/README.md.

import 'dart:io';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

import '../fixtures/sinteticas/gerador.dart';

const _dir = 'test/fixtures/sinteticas';

String _ultimos3(String conta) {
  final digitos = conta.replaceAll(RegExp(r'\D'), '');
  return digitos.substring(digitos.length - 3);
}

void main() {
  final fixtures = gerarFixtures();

  group('o disco é a saída do gerador', () {
    for (final f in fixtures) {
      test(f.especificacao.arquivo, () {
        final arquivo = File('$_dir/${f.especificacao.arquivo}');
        expect(arquivo.existsSync(), isTrue,
            reason: 'rode: fvm dart run test/fixtures/sinteticas/gerador.dart');
        // Byte a byte: CRLF, BOM e codificação SÃO o que se quer provar.
        // (O .gitattributes da pasta impede o git de reescrever os bytes.)
        expect(arquivo.readAsBytesSync(), f.bytes,
            reason: 'fixture editada à mão ou gerador alterado sem regenerar '
                '— sem a correspondência, o rótulo "sintética, do gerador" '
                'deixa de ser verdade');
      });
    }

    test('manifesto.json', () {
      expect(
        File('$_dir/manifesto.json').readAsStringSync(),
        manifesto(fixtures),
      );
    });

    test('nenhum arquivo de extrato solto na pasta, fora do gerador', () {
      // Uma fixture real (ou de outra origem) colocada aqui herdaria o
      // rótulo errado. Fixture real mora em outro diretório, com o seu README.
      final esperados = {for (final f in fixtures) f.especificacao.arquivo};
      final presentes = Directory(_dir)
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((n) => n.endsWith('.ofx') || n.endsWith('.csv'))
          .toSet();
      expect(presentes, esperados);
    });
  });

  group('parser e gerador concordam', () {
    for (final f in fixtures) {
      test(f.especificacao.arquivo, () {
        // Autodetecção, como no app: o charset declarado pode mentir.
        final extrato = parseOfx(decodificarExtrato(f.bytes));
        expect(extrato.transacoes, f.transacoes);
        expect(extrato.conta, f.especificacao.conta);
        expect(extrato.banco, f.especificacao.org ?? f.especificacao.bankId);
        expect(extrato.moeda, 'BRL');
        if (f.transacoes.isEmpty) {
          expect(extrato.avisos.single.mensagem, contains('não contém lançamentos'));
        } else {
          expect(extrato.avisos, isEmpty);
        }
      });
    }
  });

  group('variedade — a trava contra o conjunto uniforme de 16/ago', () {
    final specs = especificacoes;

    test('cada conta termina em dígitos diferentes', () {
      final finais = specs.map((e) => _ultimos3(e.conta)).toList();
      expect(finais.toSet(), hasLength(finais.length),
          reason: 'doze "bancos" terminando em 678 foi o que denunciou o '
              'conjunto anterior');
    });

    test('quatro codificações, incluindo cabeçalho que mente', () {
      expect(specs.map((e) => e.codificacao).toSet(),
          Codificacao.values.toSet());
      expect(
          specs.any((e) =>
              e.codificacao == Codificacao.utf8 &&
              e.charsetDeclarado == '1252'),
          isTrue);
    });

    test('FITID em 100%, em parte e em nenhum lançamento', () {
      expect(specs.map((e) => e.fitid).toSet(), CoberturaFitid.values.toSet());
      final parcial = fixtures.firstWhere(
          (f) => f.especificacao.fitid == CoberturaFitid.parcial);
      final com = parcial.transacoes.where((t) => t.idExterno != null).length;
      expect(com, allOf(greaterThan(0), lessThan(parcial.transacoes.length)));
    });

    test('períodos de 1 a 92 dias, não "~30 dias" em todos', () {
      final dias = specs.map((e) => e.dias).toList();
      expect(dias.reduce((a, b) => a < b ? a : b), 1);
      expect(dias.reduce((a, b) => a > b ? a : b), greaterThanOrEqualTo(90));
      expect(dias.where((d) => d >= 25 && d <= 35).length,
          lessThan(dias.length ~/ 2));
    });

    test('o período declarado é o que os lançamentos cobrem', () {
      for (final f in fixtures.where((f) => f.transacoes.length > 1)) {
        final datas = f.transacoes.map((t) => t.data).toList()..sort();
        final ini = DateTime.parse(datas.first);
        final fim = DateTime.parse(datas.last);
        expect(fim.difference(ini).inDays + 1, f.especificacao.dias,
            reason: f.especificacao.arquivo);
      }
    });

    test('SGML e XML, CRLF e LF, vírgula e ponto, com e sem ORG', () {
      expect(specs.map((e) => e.sgml).toSet(), {true, false});
      expect(specs.map((e) => e.crlf).toSet(), {true, false});
      expect(specs.map((e) => e.virgulaDecimal).toSet(), {true, false});
      expect(specs.map((e) => e.org == null).toSet(), {true, false});
      expect(specs.map((e) => e.formatoData).toSet(),
          FormatoData.values.toSet());
    });

    test('Pix legítimos idênticos no mesmo dia continuam sendo três', () {
      final f = fixtures
          .firstWhere((f) => f.especificacao.repeticoesNoMesmoDia);
      final repetidos = f.transacoes
          .where((t) => t.descricao == 'PIX RECEBIDO JOÃO DA SILVA' &&
              t.data == f.transacoes[2].data &&
              t.valorCentavos == f.transacoes[2].valorCentavos)
          .toList();
      expect(repetidos, hasLength(3));
      expect(repetidos.map((t) => t.idExterno).toSet(), hasLength(3));
    });

    test('nenhum banco real: ORG e BANKID fictícios', () {
      for (final e in specs) {
        expect(e.org == null || e.org!.startsWith('SINTETICO-'), isTrue);
        expect(e.bankId, startsWith('9'));
      }
    });
  });
}
