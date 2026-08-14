import 'dart:convert';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

import '../carne_leao/tabela_irpf_test.dart' show tabela2026;
import 'layout_darf_test.dart' show layoutJson;

void main() {
  /// Com o redutor da Lei 15.270/2025, para reproduzir o exemplo oficial da
  /// RFB (R$ 6.000 de receita → R$ 394,54 de imposto) dentro do PDF.
  final tabela = tabela2026(
    redutor: const RedutorLei15270(
      tetoCentavos: 31289,
      limiteIsencaoCentavos: 500000,
      limiteTransicaoCentavos: 735000,
      coefACentavos: 97862,
      coefBMilionesimos: 133145,
    ),
  );

  /// Sem redutor: usada onde o teste precisa de imposto pequeno e previsível.
  final tabelaSemRedutor = tabela2026();

  final contribuinte = Contribuinte(
    cpf: '529.982.247-25',
    nome: 'Maria Autônoma de Souza',
    telefone: '(11) 90000-0000',
  );

  DocumentoDarf guia({
    LayoutCodigoBarrasDarf? layout,
    String competencia = '2026-03',
  }) =>
      DocumentoDarf.daApuracao(
        apuracao: apurarMes(
          entrada: EntradaApuracao(
            competencia: competencia,
            receitaBrutaCentavos: 600000,
          ),
          tabela: tabela,
        ),
        contribuinte: contribuinte,
        feriadosBancarios: const {},
        layout: layout,
      );

  /// O conteúdo do PDF é gravado em latin1 e não comprimido, então dá para
  /// procurar o texto do documento nos bytes.
  String comoTexto(List<int> bytes) => latin1.decode(bytes);

  group('estrutura do arquivo', () {
    test('começa com o cabeçalho PDF e termina com %%EOF', () {
      final texto = comoTexto(gerarPdfDarf(guia()));
      expect(texto.startsWith('%PDF-1.4\n'), isTrue);
      expect(texto.trimRight().endsWith('%%EOF'), isTrue);
    });

    test('a tabela xref aponta para o início de cada objeto', () {
      // É a parte do PDF que mais silenciosamente quebra: um offset errado
      // por um byte e o arquivo não abre. Vale conferir de verdade.
      final bytes = gerarPdfDarf(guia());
      final texto = comoTexto(bytes);
      final inicioXref = int.parse(
        RegExp(r'startxref\s+(\d+)').firstMatch(texto)!.group(1)!,
      );
      expect(texto.substring(inicioXref, inicioXref + 4), 'xref');

      final linhas = texto.substring(inicioXref).split('\n');
      final total = int.parse(linhas[1].split(' ')[1]);
      expect(linhas[2], startsWith('0000000000 65535 f'));

      for (var objeto = 1; objeto < total; objeto++) {
        final offset = int.parse(linhas[2 + objeto].substring(0, 10));
        expect(
          texto.substring(offset, offset + '$objeto 0 obj'.length),
          '$objeto 0 obj',
          reason: 'offset do objeto $objeto na xref',
        );
      }
    });

    test('declara /Length coerente com o stream de conteúdo', () {
      final texto = comoTexto(gerarPdfDarf(guia()));
      final declarado = int.parse(
        RegExp(r'<< /Length (\d+) >>\nstream\n').firstMatch(texto)!.group(1)!,
      );
      final inicio = texto.indexOf('stream\n') + 'stream\n'.length;
      final fim = texto.indexOf('endstream');
      expect(fim - inicio, declarado);
    });

    test('é determinístico: mesmo documento, mesmos bytes', () {
      // Sem isso não há como testar o PDF por comparação — e uma data de
      // geração embutida vazaria o horário de uso do app para dentro de um
      // arquivo que o usuário manda para o contador.
      expect(gerarPdfDarf(guia()), gerarPdfDarf(guia()));
      expect(comoTexto(gerarPdfDarf(guia())).contains('CreationDate'), isFalse);
    });
  });

  group('conteúdo da guia', () {
    test('imprime os campos que identificam o recolhimento', () {
      final texto = comoTexto(gerarPdfDarf(guia()));
      expect(texto, contains('DARF'));
      expect(texto, contains('529.982.247-25'));
      expect(texto, contains('Maria Aut'));
      expect(texto, contains('0190'));
      expect(texto, contains('31/03/2026')); // período de apuração
      expect(texto, contains('30/04/2026')); // vencimento
      expect(texto, contains('R\$ 394,54')); // exemplo oficial da RFB
    });

    test('sem código de barras, explica como pagar pelo e-CAC', () {
      final texto = comoTexto(gerarPdfDarf(guia()));
      expect(texto, contains('Guia sem c'));
      expect(texto, contains('e-CAC'));
    });

    test('com layout conferido, imprime a linha digitável', () {
      final documento =
          guia(layout: LayoutCodigoBarrasDarf.fromJson(layoutJson()));
      final texto = comoTexto(gerarPdfDarf(documento));
      final linha = documento.codigoBarras!.linhaDigitavelFormatada;
      expect(texto, contains(linha));
      expect(texto, isNot(contains('Guia sem c')));
    });

    test('não se apresenta como emissão oficial da Receita Federal', () {
      final texto = comoTexto(gerarPdfDarf(guia()));
      expect(texto, contains('preparado pelo Desmalha'));
      expect(texto, contains('emiss'));
    });

    test('explica a guia que quita mais de uma competência', () {
      final apuracoes = apurarSequencia(
        entradas: [
          EntradaApuracao(competencia: '2026-03', receitaBrutaCentavos: 310260),
          EntradaApuracao(competencia: '2026-04', receitaBrutaCentavos: 600000),
        ],
        tabelaPara: (_) => tabelaSemRedutor,
      );
      final guias = darfsDaSequencia(
        apuracoes: apuracoes,
        contribuinte: contribuinte,
        feriadosBancarios: const {},
      );
      final texto = comoTexto(gerarPdfDarf(guias.single));
      expect(texto, contains('03/2026, 04/2026'));
      expect(texto, contains('9.430/1996'));
    });

    test('a observação do app entra no rodapé', () {
      final texto = comoTexto(
        gerarPdfDarf(guia(), observacao: 'Guia vencida — recolha pelo Sicalc.'),
      );
      expect(texto, contains('Guia vencida'));
      expect(texto, contains('Sicalc'));
    });

    test('travessão vira o byte WinAnsi, não interrogação', () {
      // O travessão é U+2014, acima de 0xFF, mas o WinAnsi tem em 0x97 —
      // sem a conversão os títulos do app saem furados no papel.
      final texto = comoTexto(gerarPdfDarf(guia()));
      expect(texto, contains('Carn\u00ea-le\u00e3o \u0097 imposto de renda'));
      expect(texto, isNot(contains('le\u00e3o ? imposto de renda')));
    });

    test('escapa parênteses do texto para não quebrar o PDF', () {
      // O telefone tem parênteses; sem escape, o parser de strings do PDF
      // fecha antes da hora e o arquivo corrompe.
      final texto = comoTexto(gerarPdfDarf(guia()));
      expect(texto, contains(r'\(11\) 90000-0000'));
    });
  });

  group('larguraTexto', () {
    test('usa as métricas das fontes base', () {
      // Em Helvetica 10pt, o espaço tem 278/1000 do tamanho.
      expect(larguraTexto(' ', 10, false), closeTo(2.78, 0.001));
      // Dígitos têm largura fixa de 556 nas duas fontes — é o que mantém as
      // colunas de valores alinhadas.
      expect(larguraTexto('0', 10, false), closeTo(5.56, 0.001));
      expect(larguraTexto('0', 10, true), closeTo(5.56, 0.001));
    });

    test('cresce proporcionalmente ao tamanho', () {
      expect(
        larguraTexto('DARF', 20, false),
        closeTo(larguraTexto('DARF', 10, false) * 2, 0.001),
      );
    });

    test('acentuado não zera a largura', () {
      expect(larguraTexto('ã', 10, false), greaterThan(0));
    });
  });

  group('DocumentoPdf', () {
    test('recusa documento sem páginas', () {
      expect(() => DocumentoPdf().bytes(), throwsStateError);
    });

    test('gera uma página por chamada de novaPagina', () {
      final pdf = DocumentoPdf();
      pdf.novaPagina().texto('a', x: 10, y: 10);
      pdf.novaPagina().texto('b', x: 10, y: 10);
      final texto = latin1.decode(pdf.bytes());
      expect(texto, contains('/Count 2'));
      expect('/Type /Page '.allMatches(texto).length, 2);
    });
  });
}
