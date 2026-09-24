import 'package:desmalha_core/catalogo_arquivos.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

/// Layout FICTÍCIO (mesmo schema do layout_darf_test), só para exercitar a
/// escolha do layout. Não é o layout da Receita Federal.
Map<String, Object?> _layout(String id, {required bool conferido}) => {
  'tipo': TipoCatalogo.layoutDarfCodigoBarras,
  'id': id,
  'conteudo': {
    'id': id,
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
  },
};

void main() {
  final itens = itensDoCatalogoNoRepositorio('.');
  final catalogo = Catalogo.fromItens(itens);
  final ana = Contribuinte(cpf: '529.982.247-25', nome: 'Ana Souza');

  DadosDoMes classificado(int receita) => DadosDoMes(
    receitaTributavelCentavos: receita,
    lancamentosClassificados: 1,
  );

  PainelApurado painel(
    Map<String, DadosDoMes> dados,
    String c, [
    Catalogo? cat,
  ]) =>
      montarPainelMensal(
            competencia: c,
            dadosDoAno: dados,
            catalogo: cat ?? catalogo,
          )
          as PainelApurado;

  test('DARF emitido: a guia do motor, vencimento do painel, sem código', () {
    final p = painel({'2026-08': classificado(1000000)}, '2026-08');
    final r = guiaDoMes(painel: p, contribuinte: ana, catalogo: catalogo);
    final g = (r as GuiaPronta).documento;
    expect(g.codigoReceita, '0190');
    expect(g.competencia, '2026-08');
    expect(g.periodoApuracao, '2026-08-31');
    expect(g.dataVencimento, p.vencimento);
    expect(g.dataVencimento, '2026-09-30');
    expect(g.valorPrincipalCentavos, p.apuracao.valorDarfCentavos);
    expect(g.valorTotalCentavos, p.apuracao.valorDarfCentavos);
    expect(g.contribuinte.cpf, '52998224725');
    expect(
      g.codigoBarras,
      isNull,
      reason: 'nenhum layout conferido no catálogo: sem código de barras',
    );
    expect(g.competenciasAbrangidas, ['2026-08']);
  });

  test('mês que acumulou antes entra nas competências abrangidas', () {
    final pequena = [for (var r = 500000; r <= 900000; r += 100) r].firstWhere(
      (r) =>
          painel({'2026-03': classificado(r)}, '2026-03').apuracao.statusDarf ==
          StatusDarf.acumulaParaProximoMes,
    );
    final p = painel({
      '2026-03': classificado(pequena),
      '2026-05': classificado(1000000),
    }, '2026-05');
    final g =
        (guiaDoMes(painel: p, contribuinte: ana, catalogo: catalogo)
                as GuiaPronta)
            .documento;
    expect(g.competenciasAbrangidas, ['2026-03', '2026-05']);
    expect(g.valorPrincipalCentavos, p.apuracao.valorDarfCentavos);
  });

  test('mês que não gera DARF: sem guia', () {
    final p = painel({
      '2026-08': const DadosDoMes(lancamentosClassificados: 2),
    }, '2026-08');
    expect(
      (guiaDoMes(painel: p, contribuinte: ana, catalogo: catalogo) as SemGuia)
          .motivo,
      MotivoSemGuia.naoEmitida,
    );
  });

  test('dezembro sem feriados de 2027: sem guia, nunca data adivinhada', () {
    final p = painel({'2026-12': classificado(1000000)}, '2026-12');
    expect(
      (guiaDoMes(painel: p, contribuinte: ana, catalogo: catalogo) as SemGuia)
          .motivo,
      MotivoSemGuia.semCalendario,
    );
  });

  test('sem nome e CPF: sem guia', () {
    final p = painel({'2026-08': classificado(1000000)}, '2026-08');
    expect(
      (guiaDoMes(painel: p, contribuinte: null, catalogo: catalogo) as SemGuia)
          .motivo,
      MotivoSemGuia.semContribuinte,
    );
  });

  group('código de barras', () {
    test('um layout conferido: a guia sai com código', () {
      final cat = Catalogo.fromItens([
        ...itens,
        _layout('darf-a', conferido: true),
      ]);
      final p = painel({'2026-08': classificado(1000000)}, '2026-08', cat);
      final g =
          (guiaDoMes(painel: p, contribuinte: ana, catalogo: cat) as GuiaPronta)
              .documento;
      expect(g.codigoBarras, isNotNull);
    });

    test('layout NÃO conferido: sem código', () {
      final cat = Catalogo.fromItens([
        ...itens,
        _layout('darf-a', conferido: false),
      ]);
      final p = painel({'2026-08': classificado(1000000)}, '2026-08', cat);
      expect(
        (guiaDoMes(painel: p, contribuinte: ana, catalogo: cat) as GuiaPronta)
            .documento
            .codigoBarras,
        isNull,
      );
    });

    test('dois conferidos: não escolhe às cegas, sem código', () {
      final cat = Catalogo.fromItens([
        ...itens,
        _layout('darf-a', conferido: true),
        _layout('darf-b', conferido: true),
      ]);
      final p = painel({'2026-08': classificado(1000000)}, '2026-08', cat);
      expect(
        (guiaDoMes(painel: p, contribuinte: ana, catalogo: cat) as GuiaPronta)
            .documento
            .codigoBarras,
        isNull,
      );
    });
  });
}
