import 'dart:convert';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

void main() {
  group('PerfilCsv.fromJson', () {
    Map<String, Object?> jsonMinimo() => {
          'id': 'nubank-conta-csv-v1',
          'banco': 'Nubank',
          'delimitador': ',',
          'formatoData': 'dd/MM/yyyy',
          'formatoValor': 'pontoDecimal',
          'colunaData': 0,
          'colunaValor': 1,
          'colunaDescricao': 3,
        };

    test('perfil mínimo com defaults', () {
      final perfil = PerfilCsv.fromJson(jsonMinimo());
      expect(perfil.id, 'nubank-conta-csv-v1');
      expect(perfil.linhasCabecalho, 1);
      expect(perfil.encoding, isNull);
      expect(perfil.colunaIdExterno, isNull);
      expect(perfil.colunaTipo, isNull);
      expect(perfil.descricoesIgnoradas, isEmpty);
      expect(perfil.formatoValor, FormatoValor.pontoDecimal);
    });

    test('perfil completo faz round-trip por JSON', () {
      final original = {
        ...jsonMinimo(),
        'id': 'bb-conta-csv-v1',
        'banco': 'Banco do Brasil',
        'encoding': 'latin-1',
        'linhasCabecalho': 2,
        'formatoValor': 'virgulaDecimal',
        'colunaIdExterno': 6,
        'colunaTipo': 5,
        'marcadorDebito': 'D',
        'descricoesIgnoradas': ['Saldo Anterior', 'S A L D O'],
      };

      final perfil = PerfilCsv.fromJson(original);
      // Round-trip por string, como o catálogo versionado entregará.
      final reserializado = jsonDecode(jsonEncode(perfil.toJson()));
      expect(reserializado, original);
    });

    test('campo obrigatório ausente falha alto', () {
      final json = jsonMinimo()..remove('formatoData');
      expect(() => PerfilCsv.fromJson(json), throwsFormatException);
    });

    test('delimitador com mais de um caractere é rejeitado', () {
      final json = jsonMinimo()..['delimitador'] = ';;';
      expect(() => PerfilCsv.fromJson(json), throwsFormatException);
    });

    test('formatoValor desconhecido é rejeitado', () {
      final json = jsonMinimo()..['formatoValor'] = 'centavosDiretos';
      expect(() => PerfilCsv.fromJson(json), throwsFormatException);
    });

    test('colunaTipo sem marcadorDebito é rejeitado', () {
      final json = jsonMinimo()..['colunaTipo'] = 5;
      expect(() => PerfilCsv.fromJson(json), throwsFormatException);
    });

    test('coluna negativa é rejeitada', () {
      final json = jsonMinimo()..['colunaValor'] = -1;
      expect(() => PerfilCsv.fromJson(json), throwsFormatException);
    });
  });

  group('PerfilCsv — crédito e débito em colunas separadas', () {
    Map<String, Object?> jsonSeparado() => {
          'id': 'banco-sep-conta-csv-v1',
          'banco': 'Banco Separado',
          'delimitador': ';',
          'formatoData': 'dd/MM/yyyy',
          'formatoValor': 'virgulaDecimal',
          'colunaData': 0,
          'colunaDescricao': 1,
          'colunaCredito': 3,
          'colunaDebito': 4,
        };

    test('carrega e faz round-trip sem inventar colunaValor', () {
      final perfil = PerfilCsv.fromJson(jsonSeparado());
      expect(perfil.creditoDebitoSeparados, isTrue);
      expect(perfil.colunaValor, isNull);
      expect(jsonDecode(jsonEncode(perfil.toJson())),
          {...jsonSeparado(), 'linhasCabecalho': 1});
    });

    test('perfil publicado (coluna única) segue idêntico: campo novo é '
        'opcional e nunca aparece no JSON dele', () {
      final perfil = PerfilCsv.fromJson({
        'id': 'nubank-conta-csv-v1',
        'banco': 'Nubank',
        'delimitador': ',',
        'formatoData': 'dd/MM/yyyy',
        'formatoValor': 'pontoDecimal',
        'colunaData': 0,
        'colunaValor': 1,
        'colunaDescricao': 3,
      });
      expect(perfil.creditoDebitoSeparados, isFalse);
      expect(perfil.toJson().keys,
          isNot(anyOf(contains('colunaCredito'), contains('colunaDebito'))));
    });

    test('colunaValor junto com crédito/débito é recusado (ambíguo)', () {
      final json = jsonSeparado()..['colunaValor'] = 2;
      expect(() => PerfilCsv.fromJson(json), throwsFormatException);
    });

    test('crédito sem débito (e vice-versa) é recusado', () {
      expect(() => PerfilCsv.fromJson(jsonSeparado()..remove('colunaDebito')),
          throwsFormatException);
      expect(() => PerfilCsv.fromJson(jsonSeparado()..remove('colunaCredito')),
          throwsFormatException);
    });

    test('nenhum layout de valor é recusado', () {
      final json = jsonSeparado()
        ..remove('colunaCredito')
        ..remove('colunaDebito');
      expect(() => PerfilCsv.fromJson(json), throwsFormatException);
    });

    test('crédito e débito na mesma coluna é recusado', () {
      final json = jsonSeparado()..['colunaDebito'] = 3;
      expect(() => PerfilCsv.fromJson(json), throwsFormatException);
    });

    test('colunaTipo com crédito/débito separados é recusado', () {
      final json = jsonSeparado()
        ..['colunaTipo'] = 5
        ..['marcadorDebito'] = 'D';
      expect(() => PerfilCsv.fromJson(json), throwsFormatException);
    });
  });
}
