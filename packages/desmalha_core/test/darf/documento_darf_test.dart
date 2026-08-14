import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

import '../carne_leao/tabela_irpf_test.dart' show tabela2026;
import 'layout_darf_test.dart' show layoutJson;

void main() {
  final tabela = tabela2026();
  final contribuinte = Contribuinte(
    cpf: '529.982.247-25',
    nome: 'Maria Autônoma de Souza',
    telefone: '(11) 90000-0000',
  );

  /// Feriados do exemplo: 30/04/2026 é quinta-feira útil, então o vencimento
  /// de 2026-03 cai nele; declarado feriado, deve antecipar para 29/04.
  const semFeriados = <String>{};

  ApuracaoMensal apurar(String competencia, int receitaCentavos) => apurarMes(
        entrada: EntradaApuracao(
          competencia: competencia,
          receitaBrutaCentavos: receitaCentavos,
        ),
        tabela: tabela,
      );

  group('Contribuinte', () {
    test('normaliza o CPF para dígitos e formata para impressão', () {
      expect(contribuinte.cpf, '52998224725');
      expect(contribuinte.cpfFormatado, '529.982.247-25');
    });

    test('recusa CPF inválido, repetido ou de tamanho errado', () {
      expect(() => Contribuinte(cpf: '529.982.247-26', nome: 'X'),
          throwsArgumentError);
      expect(() => Contribuinte(cpf: '111.111.111-11', nome: 'X'),
          throwsArgumentError);
      expect(() => Contribuinte(cpf: '5299822472', nome: 'X'),
          throwsArgumentError);
    });

    test('recusa nome vazio', () {
      expect(() => Contribuinte(cpf: '52998224725', nome: '   '),
          throwsArgumentError);
    });
  });

  group('cpfValido', () {
    test('aceita CPF com dígitos verificadores corretos', () {
      expect(cpfValido('52998224725'), isTrue);
    });

    test('rejeita os onze repetidos, que passam no cálculo mas não são CPF',
        () {
      for (var d = 0; d <= 9; d++) {
        expect(cpfValido('$d' * 11), isFalse, reason: 'CPF $d repetido');
      }
    });

    test('rejeita não numérico e tamanho errado', () {
      expect(cpfValido('5299822472a'), isFalse);
      expect(cpfValido(''), isFalse);
      expect(cpfValido('529982247251'), isFalse);
    });
  });

  group('DocumentoDarf.daApuracao', () {
    test('monta a guia com período de apuração e vencimento corretos', () {
      final apuracao = apurar('2026-03', 600000);
      expect(apuracao.statusDarf, StatusDarf.emitido);

      final guia = DocumentoDarf.daApuracao(
        apuracao: apuracao,
        contribuinte: contribuinte,
        feriadosBancarios: semFeriados,
      );

      expect(guia.codigoReceita, '0190');
      expect(guia.competencia, '2026-03');
      // Período de apuração é o último dia do mês apurado.
      expect(guia.periodoApuracao, '2026-03-31');
      // Vencimento: último dia útil do mês seguinte (30/04/2026, quinta).
      expect(guia.dataVencimento, '2026-04-30');
      expect(guia.valorPrincipalCentavos, apuracao.valorDarfCentavos);
      expect(guia.competenciasAbrangidas, ['2026-03']);
    });

    test('multa e juros são sempre zero — atraso vai para o SicalcWeb', () {
      final guia = DocumentoDarf.daApuracao(
        apuracao: apurar('2026-03', 600000),
        contribuinte: contribuinte,
        feriadosBancarios: semFeriados,
      );
      expect(guia.multaCentavos, 0);
      expect(guia.jurosCentavos, 0);
      expect(guia.valorTotalCentavos, guia.valorPrincipalCentavos);
    });

    test('antecipa o vencimento quando o último dia útil é feriado', () {
      final guia = DocumentoDarf.daApuracao(
        apuracao: apurar('2026-03', 600000),
        contribuinte: contribuinte,
        feriadosBancarios: const {'2026-04-30'},
      );
      expect(guia.dataVencimento, '2026-04-29');
    });

    test('recusa competência que não gera guia', () {
      final semImposto = apurar('2026-03', 100000);
      expect(semImposto.statusDarf, isNot(StatusDarf.emitido));
      expect(
        () => DocumentoDarf.daApuracao(
          apuracao: semImposto,
          contribuinte: contribuinte,
          feriadosBancarios: semFeriados,
        ),
        throwsArgumentError,
      );
    });

    test('sem layout no catálogo, a guia sai SEM código de barras', () {
      final guia = DocumentoDarf.daApuracao(
        apuracao: apurar('2026-03', 600000),
        contribuinte: contribuinte,
        feriadosBancarios: semFeriados,
      );
      expect(guia.codigoBarras, isNull);
    });

    test('layout não conferido não produz código de barras nem estoura', () {
      // A trava é do produto, não só da API: um layout provisório publicado
      // por engano no catálogo não pode virar guia paga.
      final layout =
          LayoutCodigoBarrasDarf.fromJson(layoutJson(conferido: false));
      final guia = DocumentoDarf.daApuracao(
        apuracao: apurar('2026-03', 600000),
        contribuinte: contribuinte,
        feriadosBancarios: semFeriados,
        layout: layout,
      );
      expect(guia.codigoBarras, isNull);
    });

    test('layout conferido produz código de barras com o valor da guia', () {
      final layout = LayoutCodigoBarrasDarf.fromJson(layoutJson());
      final apuracao = apurar('2026-03', 600000);
      final guia = DocumentoDarf.daApuracao(
        apuracao: apuracao,
        contribuinte: contribuinte,
        feriadosBancarios: semFeriados,
        layout: layout,
      );
      expect(guia.codigoBarras, isNotNull);
      expect(guia.codigoBarras!.valorCentavos, guia.valorTotalCentavos);
      expect(guia.codigoBarras!.digitos, hasLength(44));
      expect(guia.codigoBarras!.linhaDigitavel, hasLength(48));
    });
  });

  group('venceuAte', () {
    final guia = DocumentoDarf.daApuracao(
      apuracao: apurar('2026-03', 600000),
      contribuinte: contribuinte,
      feriadosBancarios: semFeriados,
    );

    test('no dia do vencimento ainda não venceu', () {
      expect(guia.venceuAte('2026-04-30'), isFalse);
    });

    test('no dia seguinte, venceu', () {
      expect(guia.venceuAte('2026-05-01'), isTrue);
    });

    test('antes do vencimento, não venceu', () {
      expect(guia.venceuAte('2026-04-01'), isFalse);
    });
  });

  group('darfsDaSequencia (N:1 do DARF mínimo)', () {
    test('uma guia por competência quando todas passam do mínimo', () {
      final apuracoes = apurarSequencia(
        entradas: [
          EntradaApuracao(competencia: '2026-03', receitaBrutaCentavos: 600000),
          EntradaApuracao(competencia: '2026-04', receitaBrutaCentavos: 600000),
        ],
        tabelaPara: (_) => tabela,
      );
      final guias = darfsDaSequencia(
        apuracoes: apuracoes,
        contribuinte: contribuinte,
        feriadosBancarios: semFeriados,
      );
      expect(guias, hasLength(2));
      expect(guias.map((g) => g.competenciasAbrangidas), [
        ['2026-03'],
        ['2026-04'],
      ]);
    });

    test('mês retido abaixo do mínimo é absorvido pela guia seguinte', () {
      // R$ 3.102,60 de receita deixa base de R$ 2.495,40 pelo simplificado:
      // 7,5% menos a parcela a deduzir dá R$ 4,99, positivo e abaixo do
      // mínimo. O segundo mês carrega os dois.
      final apuracoes = apurarSequencia(
        entradas: [
          EntradaApuracao(competencia: '2026-03', receitaBrutaCentavos: 310260),
          EntradaApuracao(competencia: '2026-04', receitaBrutaCentavos: 600000),
        ],
        tabelaPara: (_) => tabela,
      );
      expect(apuracoes[0].statusDarf, StatusDarf.acumulaParaProximoMes);
      expect(apuracoes[0].impostoDevidoCentavos, 499);
      expect(apuracoes[1].statusDarf, StatusDarf.emitido);

      final guias = darfsDaSequencia(
        apuracoes: apuracoes,
        contribuinte: contribuinte,
        feriadosBancarios: semFeriados,
      );
      expect(guias, hasLength(1));
      expect(guias.single.competenciasAbrangidas, ['2026-03', '2026-04']);
      expect(guias.single.competencia, '2026-04');
      expect(guias.single.periodoApuracao, '2026-04-30');
      expect(
        guias.single.valorPrincipalCentavos,
        apuracoes[1].totalParaDarfCentavos,
      );
    });

    test('competência sem imposto não gera guia nem é absorvida', () {
      final apuracoes = apurarSequencia(
        entradas: [
          EntradaApuracao(competencia: '2026-03', receitaBrutaCentavos: 100000),
          EntradaApuracao(competencia: '2026-04', receitaBrutaCentavos: 600000),
        ],
        tabelaPara: (_) => tabela,
      );
      final guias = darfsDaSequencia(
        apuracoes: apuracoes,
        contribuinte: contribuinte,
        feriadosBancarios: semFeriados,
      );
      expect(guias, hasLength(1));
      expect(guias.single.competenciasAbrangidas, ['2026-04']);
    });

    test('resíduo de dezembro não vira guia e não transporta', () {
      final apuracoes = apurarSequencia(
        entradas: [
          EntradaApuracao(competencia: '2026-12', receitaBrutaCentavos: 310260),
        ],
        tabelaPara: (_) => tabela,
      );
      expect(apuracoes.single.statusDarf, StatusDarf.residuoParaDirpf);
      expect(
        darfsDaSequencia(
          apuracoes: apuracoes,
          contribuinte: contribuinte,
          feriadosBancarios: semFeriados,
        ),
        isEmpty,
      );
    });
  });
}
