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
}
