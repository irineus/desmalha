import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

/// Layout FICTÍCIO, só para exercitar o schema. Não é o layout da Receita
/// Federal e não deve ser copiado para o catálogo.
Map<String, Object?> layoutJson({bool conferido = true}) => {
      'id': 'darf-0190-ficticio-v1',
      'segmento': 5,
      'identificador_valor': '8',
      'identificacao_orgao': '1234',
      'campo_livre': [
        {'fonte': 'codigo_receita', 'tamanho': 4},
        {'fonte': 'cpf_contribuinte', 'tamanho': 11},
        {'fonte': 'competencia_aaaamm', 'tamanho': 6},
        {'fonte': 'constante', 'tamanho': 4, 'constante': '0000'},
      ],
      'origem': 'fixture de teste — sem valor normativo',
      'conferido_contra_documento_real': conferido,
    };

void main() {
  group('LayoutCodigoBarrasDarf.fromJson', () {
    test('lê o layout do catálogo e faz round-trip do JSON', () {
      final layout = LayoutCodigoBarrasDarf.fromJson(layoutJson());
      expect(layout.id, 'darf-0190-ficticio-v1');
      expect(layout.segmento, 5);
      expect(layout.identificadorValor,
          IdentificadorValor.valorEfetivoModulo11);
      expect(layout.campoLivre, hasLength(4));
      expect(layout.toJson(), layoutJson());
    });

    test('exige que os trechos somem exatamente 25 dígitos', () {
      final curto = layoutJson()
        ..['campo_livre'] = [
          {'fonte': 'codigo_receita', 'tamanho': 4},
        ];
      expect(
        () => LayoutCodigoBarrasDarf.fromJson(curto),
        throwsArgumentError,
      );
    });

    test('recusa fonte desconhecida', () {
      final json = layoutJson()
        ..['campo_livre'] = [
          {'fonte': 'inventada', 'tamanho': 25},
        ];
      expect(
        () => LayoutCodigoBarrasDarf.fromJson(json),
        throwsFormatException,
      );
    });

    test('trecho constante exige dígitos do tamanho declarado', () {
      final json = layoutJson()
        ..['campo_livre'] = [
          {'fonte': 'constante', 'tamanho': 25, 'constante': '123'},
        ];
      expect(
        () => LayoutCodigoBarrasDarf.fromJson(json),
        throwsFormatException,
      );

      final naoNumerica = layoutJson()
        ..['campo_livre'] = [
          {'fonte': 'constante', 'tamanho': 25, 'constante': 'a' * 25},
        ];
      expect(
        () => LayoutCodigoBarrasDarf.fromJson(naoNumerica),
        throwsFormatException,
      );
    });

    test('recusa campos obrigatórios ausentes', () {
      final semId = layoutJson()..remove('id');
      expect(() => LayoutCodigoBarrasDarf.fromJson(semId),
          throwsFormatException);

      final semOrigem = layoutJson()..remove('origem');
      expect(() => LayoutCodigoBarrasDarf.fromJson(semOrigem),
          throwsFormatException);

      final semCampoLivre = layoutJson()..remove('campo_livre');
      expect(() => LayoutCodigoBarrasDarf.fromJson(semCampoLivre),
          throwsFormatException);
    });

    test('layout sem a marca de conferência assume não conferido', () {
      final json = layoutJson()..remove('conferido_contra_documento_real');
      expect(
        LayoutCodigoBarrasDarf.fromJson(json).conferidoContraDocumentoReal,
        isFalse,
      );
    });
  });

  group('montarCodigoBarras', () {
    test('compõe o campo livre na ordem dos trechos, com zeros à esquerda',
        () {
      final layout = LayoutCodigoBarrasDarf.fromJson(layoutJson());
      final codigo = layout.montarCodigoBarras(
        codigoReceita: '0190',
        cpfContribuinte: '529.982.247-25',
        competencia: '2026-03',
        dataVencimento: '2026-04-30',
        valorCentavos: 39454,
      );
      expect(codigo.campoLivre, '0190${'52998224725'}${'202603'}0000');
      expect(codigo.valorCentavos, 39454);
      expect(codigo.identificacaoOrgao, '1234');
      // O código montado tem de sobreviver ao próprio validador.
      expect(CodigoBarrasArrecadacao.parse(codigo.digitos), codigo);
    });

    test('RECUSA layout não conferido contra documento real', () {
      final layout =
          LayoutCodigoBarrasDarf.fromJson(layoutJson(conferido: false));
      expect(
        () => layout.montarCodigoBarras(
          codigoReceita: '0190',
          cpfContribuinte: '52998224725',
          competencia: '2026-03',
          dataVencimento: '2026-04-30',
          valorCentavos: 39454,
        ),
        throwsStateError,
      );
    });

    test('recusa dado que não cabe no trecho em vez de truncar', () {
      final json = layoutJson()
        ..['campo_livre'] = [
          {'fonte': 'cpf_contribuinte', 'tamanho': 5},
          {'fonte': 'constante', 'tamanho': 20, 'constante': '0' * 20},
        ];
      final layout = LayoutCodigoBarrasDarf.fromJson(json);
      expect(
        () => layout.montarCodigoBarras(
          codigoReceita: '0190',
          cpfContribuinte: '52998224725',
          competencia: '2026-03',
          dataVencimento: '2026-04-30',
          valorCentavos: 100,
        ),
        throwsArgumentError,
      );
    });

    test('vencimento e valor entram nos trechos correspondentes', () {
      final json = layoutJson()
        ..['campo_livre'] = [
          {'fonte': 'vencimento_aaaammdd', 'tamanho': 8},
          {'fonte': 'valor_centavos', 'tamanho': 11},
          {'fonte': 'numero_referencia', 'tamanho': 6},
        ];
      final layout = LayoutCodigoBarrasDarf.fromJson(json);
      final codigo = layout.montarCodigoBarras(
        codigoReceita: '0190',
        cpfContribuinte: '52998224725',
        competencia: '2026-03',
        dataVencimento: '2026-04-30',
        valorCentavos: 39454,
        numeroReferencia: 'REF-42',
      );
      expect(codigo.campoLivre, '20260430${'00000039454'}${'000042'}');
    });
  });
}
