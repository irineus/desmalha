import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

/// Cenário de referência das duas decisões travadas em 17/ago/2026: o cliente
/// recebeu DOIS Pix de R$ 250,00 no mesmo dia, do mesmo remetente — são dois
/// atendimentos de verdade, R$ 500,00 de receita. Depois de importar a
/// quinzena, o usuário importa o mês cheio, que traz os mesmos lançamentos.
TransacaoImportada _pix({
  String data = '2026-03-12',
  int centavos = 25000,
  String descricao = 'PIX RECEBIDO MARIA SILVA',
  String? id,
}) =>
    TransacaoImportada(
      data: data,
      valorCentavos: centavos,
      descricao: descricao,
      idExterno: id,
    );

List<SituacaoDeduplicacao> _situacoes(ResultadoDeduplicacao r) =>
    r.itens.map((i) => i.situacao).toList();

List<MotivoDeduplicacao?> _motivos(ResultadoDeduplicacao r) =>
    r.itens.map((i) => i.motivo).toList();

void main() {
  group('camada 1 — identificador do banco', () {
    test('reimportar o mesmo arquivo não deixa nada para persistir', () {
      final arquivo = [
        _pix(id: 'FIT-1'),
        _pix(id: 'FIT-2'),
        _pix(centavos: -15075, descricao: 'PAGTO BOLETO CEMIG', id: 'FIT-3'),
      ];

      final resultado =
          conciliarImportacao(jaImportadas: arquivo, novas: arquivo);

      expect(resultado.novas, isEmpty);
      expect(resultado.quantidadeSuprimida, 3);
      expect(
        _motivos(resultado),
        everyElement(MotivoDeduplicacao.identificadorConfere),
      );
    });

    test('o par já consumido pelo identificador não marca um lançamento '
        'legítimo idêntico que veio no mesmo arquivo', () {
      // Este é o caso que a conciliação erraria se a camada 1 não retirasse a
      // ocorrência da base também do alcance da camada 2.
      final resultado = conciliarImportacao(
        jaImportadas: [_pix(id: 'FIT-1')],
        novas: [_pix(id: 'FIT-1'), _pix(id: 'FIT-9')],
      );

      expect(_situacoes(resultado), [
        SituacaoDeduplicacao.duplicataSuprimida,
        SituacaoDeduplicacao.nova,
      ]);
      expect(resultado.novas.single.idExterno, 'FIT-9');
    });

    test('a chave forte resolve o arquivo inteiro antes da chave composta: '
        'a ordem das linhas não decide o veredito', () {
      // O par da base tem o identificador do SEGUNDO lançamento do arquivo. Se
      // as camadas corressem intercaladas, o primeiro lançamento tomaria esse
      // par pela chave composta (saindo marcado por identificador divergente) e
      // o segundo — que é o mesmo lançamento, comprovado pelo identificador —
      // acabaria persistido como novo, duplicando a receita.
      final resultado = conciliarImportacao(
        jaImportadas: [_pix(id: 'FIT-2')],
        novas: [_pix(id: 'FIT-1'), _pix(id: 'FIT-2')],
      );

      expect(_situacoes(resultado), [
        SituacaoDeduplicacao.nova,
        SituacaoDeduplicacao.duplicataSuprimida,
      ]);
      expect(
        _motivos(resultado)[1],
        MotivoDeduplicacao.identificadorConfere,
      );
    });

    test('identificador repetido dentro do próprio arquivo vira possível '
        'duplicata, não suprimida', () {
      // FITID é único na conta por especificação: repetição é o banco listando
      // o mesmo lançamento duas vezes OU desrespeitando a especificação. Não
      // se adivinha qual — e adivinhar errado apagaria receita.
      final resultado = conciliarImportacao(
        jaImportadas: const [],
        novas: [_pix(id: 'FIT-1'), _pix(id: 'FIT-1')],
      );

      expect(_situacoes(resultado), [
        SituacaoDeduplicacao.nova,
        SituacaoDeduplicacao.possivelDuplicata,
      ]);
      expect(
        resultado.possiveisDuplicatas.single.motivo,
        MotivoDeduplicacao.identificadorRepetidoNoArquivo,
      );
    });

    test('lançamento sem identificador casa com base que tem identificador '
        'e é suprimido: o arquivo novo não afirma nada em contrário', () {
      final resultado = conciliarImportacao(
        jaImportadas: [_pix(id: 'FIT-1')],
        novas: [_pix()],
      );

      expect(resultado.novas, isEmpty);
      expect(
        resultado.suprimidas.single.motivo,
        MotivoDeduplicacao.dadosConferem,
      );
    });
  });

  group('camada 2 — chave composta, com a contagem como trava', () {
    test('os dois Pix de R\$ 250,00 reimportados são suprimidos e a receita '
        'segue R\$ 500,00', () {
      final resultado = conciliarImportacao(
        jaImportadas: [_pix(), _pix()],
        novas: [_pix(), _pix()],
      );

      expect(resultado.novas, isEmpty);
      expect(resultado.quantidadeSuprimida, 2);
      expect(resultado.creditosSuprimidosCentavos, 50000);
      expect(resultado.debitosSuprimidosCentavos, 0);
    });

    test('um terceiro Pix idêntico entra como novo — nunca se suprime mais '
        'ocorrências do que a base tem', () {
      final resultado = conciliarImportacao(
        jaImportadas: [_pix(), _pix()],
        novas: [_pix(), _pix(), _pix()],
      );

      expect(_situacoes(resultado), [
        SituacaoDeduplicacao.duplicataSuprimida,
        SituacaoDeduplicacao.duplicataSuprimida,
        SituacaoDeduplicacao.nova,
      ]);
      expect(resultado.novas, hasLength(1));
    });

    test('dois Pix idênticos no mesmo arquivo, com livro-caixa vazio, '
        'continuam valendo dois', () {
      final resultado = conciliarImportacao(
        jaImportadas: const [],
        novas: [_pix(), _pix()],
      );

      expect(resultado.novas, hasLength(2));
      expect(resultado.quantidadeSuprimida, 0);
      expect(resultado.quantidadePossivelDuplicata, 0);
    });

    test('crédito e débito de mesmo módulo não se confundem', () {
      final resultado = conciliarImportacao(
        jaImportadas: [_pix(centavos: 25000)],
        novas: [_pix(centavos: -25000)],
      );

      expect(resultado.novas, hasLength(1));
    });

    test('data diferente não casa', () {
      final resultado = conciliarImportacao(
        jaImportadas: [_pix(data: '2026-03-12')],
        novas: [_pix(data: '2026-03-13')],
      );

      expect(resultado.novas, hasLength(1));
    });

    test('deduplica débito do livro-caixa como deduplica receita', () {
      final despesa = _pix(centavos: -15075, descricao: 'PAGTO BOLETO CEMIG');
      final resultado = conciliarImportacao(
        jaImportadas: [despesa],
        novas: [despesa],
      );

      expect(resultado.novas, isEmpty);
      expect(resultado.debitosSuprimidosCentavos, -15075);
      expect(resultado.creditosSuprimidosCentavos, 0);
    });
  });

  group('identificador divergente — o banco afirma que são distintos', () {
    test('marca como possível duplicata em vez de suprimir ou duplicar', () {
      final resultado = conciliarImportacao(
        jaImportadas: [_pix(id: 'FIT-1')],
        novas: [_pix(id: 'REGERADO-1')],
      );

      final item = resultado.itens.single;
      expect(item.situacao, SituacaoDeduplicacao.possivelDuplicata);
      expect(item.motivo, MotivoDeduplicacao.identificadorDivergente);
      expect(item.correspondente?.idExterno, 'FIT-1');
      expect(resultado.novas, isEmpty, reason: 'não pode duplicar em silêncio');
      expect(
        resultado.suprimidas,
        isEmpty,
        reason: 'não pode apagar receita em silêncio',
      );
    });

    test('banco que regera o identificador: só o excedente da contagem é '
        'lançamento novo, o resto fica marcado', () {
      final resultado = conciliarImportacao(
        jaImportadas: [_pix(id: 'FIT-1')],
        novas: [_pix(id: 'REGERADO-1'), _pix(id: 'REGERADO-2')],
      );

      expect(_situacoes(resultado), [
        SituacaoDeduplicacao.possivelDuplicata,
        SituacaoDeduplicacao.nova,
      ]);
    });
  });

  group('normalizarDescricao', () {
    test('ignora caixa, espaçamento e acentuação', () {
      expect(
        normalizarDescricao('  Pix   recebido   José  da Silva\t'),
        'PIX RECEBIDO JOSE DA SILVA',
      );
      expect(
        normalizarDescricao('TRANSFERÊNCIA RECEBIDA — MARIA'),
        normalizarDescricao('transferencia recebida — maria'),
      );
    });

    test('preserva dígitos e pontuação, que é o que distingue lançamentos '
        'parecidos', () {
      expect(
        normalizarDescricao('PIX 001'),
        isNot(normalizarDescricao('PIX 002')),
      );
      // MEMO truncado do Itaú, que cola a data no fim do nome.
      expect(
        normalizarDescricao('PIX TRANSF SHIRLEI06 08'),
        isNot(normalizarDescricao('PIX TRANSF SHIRLEI07 08')),
      );
      expect(
        normalizarDescricao('PIX-MARIA'),
        isNot(normalizarDescricao('PIX MARIA')),
      );
    });

    test('descrição que só varia em caixa e espaço deduplica de verdade', () {
      final resultado = conciliarImportacao(
        jaImportadas: [_pix(descricao: 'PIX RECEBIDO  MARIA SILVA')],
        novas: [_pix(descricao: 'Pix recebido María Silva')],
      );

      expect(resultado.quantidadeSuprimida, 1);
    });

    test('nome parecido mas diferente não é a mesma transação', () {
      final resultado = conciliarImportacao(
        jaImportadas: [_pix(descricao: 'PIX RECEBIDO MARIA SILVA')],
        novas: [_pix(descricao: 'PIX RECEBIDO MARIO SILVA')],
      );

      expect(resultado.novas, hasLength(1));
    });
  });

  group('resultado', () {
    test('preserva a ordem do arquivo e não omite nenhum lançamento', () {
      final novas = [
        _pix(id: 'FIT-1'),
        _pix(centavos: 30000, descricao: 'PIX RECEBIDO JOAO', id: 'FIT-2'),
        _pix(centavos: -8000, descricao: 'PAGTO BOLETO NET', id: 'FIT-3'),
      ];

      final resultado = conciliarImportacao(
        jaImportadas: [_pix(id: 'FIT-2')],
        novas: novas,
      );

      expect(resultado.itens, hasLength(novas.length));
      expect(
        resultado.itens.map((i) => i.transacao).toList(),
        novas,
        reason: 'suprimir é decisão que o usuário tem direito de ver',
      );
      expect(_situacoes(resultado), [
        SituacaoDeduplicacao.nova,
        SituacaoDeduplicacao.duplicataSuprimida,
        SituacaoDeduplicacao.nova,
      ]);
    });

    test('âncora contra vacuidade: sem base, nada é suprimido nem marcado', () {
      final novas = [
        _pix(id: 'FIT-1'),
        _pix(centavos: 30000, descricao: 'PIX RECEBIDO JOAO'),
        _pix(centavos: -8000, descricao: 'PAGTO BOLETO NET'),
      ];

      final resultado =
          conciliarImportacao(jaImportadas: const [], novas: novas);

      expect(resultado.novas, novas);
      expect(resultado.quantidadeSuprimida, 0);
      expect(resultado.quantidadePossivelDuplicata, 0);
      expect(resultado.creditosSuprimidosCentavos, 0);
      expect(resultado.debitosSuprimidosCentavos, 0);
    });

    test('não altera as listas recebidas', () {
      final jaImportadas = [_pix(id: 'FIT-1')];
      final novas = [_pix(id: 'FIT-1'), _pix(id: 'FIT-2')];

      conciliarImportacao(jaImportadas: jaImportadas, novas: novas);

      expect(jaImportadas, hasLength(1));
      expect(novas, hasLength(2));
    });

    test('identificador com espaço de borda é o mesmo identificador', () {
      final resultado = conciliarImportacao(
        jaImportadas: [_pix(id: 'FIT-1')],
        novas: [_pix(id: ' FIT-1 ', descricao: 'DESCRICAO REESCRITA')],
      );

      expect(
        resultado.suprimidas.single.motivo,
        MotivoDeduplicacao.identificadorConfere,
      );
    });

    test('identificador vazio conta como ausente', () {
      final resultado = conciliarImportacao(
        jaImportadas: [_pix(id: '')],
        novas: [_pix(id: '   ')],
      );

      expect(
        resultado.suprimidas.single.motivo,
        MotivoDeduplicacao.dadosConferem,
        reason: 'string vazia não é afirmação de identidade',
      );
    });
  });
}
