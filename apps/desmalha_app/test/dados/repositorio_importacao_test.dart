/// O contrato entre a persistência e a regra de deduplicação do core:
/// suprimida nunca vira linha, possível duplicata só vira linha com decisão
/// explícita, e decisão faltando derruba a confirmação em vez de virar
/// padrão silencioso. Os cenários usam o `conciliarImportacao` REAL — não
/// vereditos montados à mão — para que uma mudança de comportamento no core
/// apareça aqui também.
library;

import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/dados/repositorio_importacao.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BancoLocal banco;
  late RepositorioImportacao repo;
  late String contaId;

  setUp(() async {
    banco = BancoLocal(NativeDatabase.memory());
    repo = RepositorioImportacao(banco, agoraEpochMs: () => 1755000000000);
    contaId = await repo.criarConta(apelido: 'Nubank PF');
  });

  tearDown(() => banco.close());

  Future<String> novaPrevia({String hash = 'hash-1'}) {
    return repo.registrarPrevia(
      contaId: contaId,
      formato: FormatoExtrato.ofx,
      nomeArquivo: 'extrato.ofx',
      hashArquivo: hash,
    );
  }

  /// Primeira importação: base com FIT001, FIT002 e um Pix sem identificador.
  Future<void> importarBase() async {
    const arquivo = [
      TransacaoImportada(
          data: '2026-01-05',
          valorCentavos: 40000,
          descricao: 'PIX JOAO',
          idExterno: 'FIT001'),
      TransacaoImportada(
          data: '2026-01-08',
          valorCentavos: 15000,
          descricao: 'PIX ANA',
          idExterno: 'FIT002'),
      TransacaoImportada(
          data: '2026-01-10', valorCentavos: 25000, descricao: 'PIX MARIA'),
    ];
    final id = await novaPrevia(hash: 'hash-base');
    final resultado =
        await repo.conciliarArquivo(contaId: contaId, novas: arquivo);
    expect(resultado.quantidadeNova, 3, reason: 'base limpa: tudo é novo');
    await repo.confirmarImportacao(
      importacaoId: id,
      resultado: resultado,
      decisoesPossiveis: const {},
    );
  }

  /// Reimportação sobreposta: um suprimido por identificador, um por dados,
  /// um marcado por identificador divergente e um genuinamente novo.
  const arquivoSobreposto = [
    // Mesmo FIT001 da base → suprimida sem perguntar.
    TransacaoImportada(
        data: '2026-01-05',
        valorCentavos: 40000,
        descricao: 'PIX JOAO',
        idExterno: 'FIT001'),
    // Mesmos dados do Pix sem id da base, nenhum lado afirma id → suprimida.
    TransacaoImportada(
        data: '2026-01-10', valorCentavos: 25000, descricao: 'PIX MARIA'),
    // Mesmos dados do FIT002, mas o banco afirma OUTRO id → possível
    // duplicata; quem decide é o usuário.
    TransacaoImportada(
        data: '2026-01-08',
        valorCentavos: 15000,
        descricao: 'PIX ANA',
        idExterno: 'FIT999'),
    // Novo de verdade.
    TransacaoImportada(
        data: '2026-01-20',
        valorCentavos: 50000,
        descricao: 'PIX CARLA',
        idExterno: 'FIT777'),
  ];

  test('novas são gravadas; suprimidas nunca; possível só com decisão',
      () async {
    await importarBase();
    final id = await novaPrevia();
    final resultado = await repo.conciliarArquivo(
        contaId: contaId, novas: arquivoSobreposto);
    expect(resultado.quantidadeSuprimida, 2);
    expect(resultado.quantidadePossivelDuplicata, 1);
    expect(resultado.quantidadeNova, 1);

    final resumo = await repo.confirmarImportacao(
      importacaoId: id,
      resultado: resultado,
      decisoesPossiveis: const {2: true}, // usuário manteve o FIT999
    );

    expect(resumo.persistidas, 2);
    expect(resumo.suprimidas, 2);
    expect(resumo.descartadasPeloUsuario, 0);

    final linhas = await banco.select(banco.transacoes).get();
    expect(linhas, hasLength(5), reason: '3 da base + FIT999 mantido + novo');
    // O FIT001 suprimido segue existindo UMA vez — a reimportação não dobrou
    // a receita (o erro que sairia como imposto a mais... e o inverso, como
    // imposto a menos na malha).
    expect(linhas.where((t) => t.fitid == 'FIT001'), hasLength(1));
    expect(linhas.where((t) => t.fitid == 'FIT999'), hasLength(1));

    final importacao = await (banco.select(banco.importacoes)
          ..where((i) => i.id.equals(id)))
        .getSingle();
    expect(importacao.status, 'confirmada');
    expect(importacao.previaJson, isNull);
    expect(importacao.totalImportadas, 2);
    expect(importacao.totalDuplicadas, 2);
    expect(importacao.totalIgnoradas, 0);
  });

  test('usuário descarta a possível duplicata: não grava e conta como '
      'ignorada', () async {
    await importarBase();
    final id = await novaPrevia();
    final resultado = await repo.conciliarArquivo(
        contaId: contaId, novas: arquivoSobreposto);

    final resumo = await repo.confirmarImportacao(
      importacaoId: id,
      resultado: resultado,
      decisoesPossiveis: const {2: false},
    );

    expect(resumo.persistidas, 1);
    expect(resumo.descartadasPeloUsuario, 1);
    final linhas = await banco.select(banco.transacoes).get();
    expect(linhas.where((t) => t.fitid == 'FIT999'), isEmpty);
    final importacao = await (banco.select(banco.importacoes)
          ..where((i) => i.id.equals(id)))
        .getSingle();
    expect(importacao.totalIgnoradas, 1);
  });

  test('decisão faltando NÃO tem padrão silencioso: a confirmação cai e '
      'nada é gravado', () async {
    await importarBase();
    final id = await novaPrevia();
    final resultado = await repo.conciliarArquivo(
        contaId: contaId, novas: arquivoSobreposto);

    await expectLater(
      repo.confirmarImportacao(
        importacaoId: id,
        resultado: resultado,
        decisoesPossiveis: const {}, // faltou decidir o índice 2
      ),
      throwsArgumentError,
    );

    final linhas = await banco.select(banco.transacoes).get();
    expect(linhas, hasLength(3), reason: 'só a base; a prévia continua lá');
    final importacao = await (banco.select(banco.importacoes)
          ..where((i) => i.id.equals(id)))
        .getSingle();
    expect(importacao.status, 'previa');
  });

  test('decisão sobre índice que não é possível duplicata também cai — '
      'decisão fantasma é bug de quem chama, não ruído a ignorar', () async {
    await importarBase();
    final id = await novaPrevia();
    final resultado = await repo.conciliarArquivo(
        contaId: contaId, novas: arquivoSobreposto);

    await expectLater(
      repo.confirmarImportacao(
        importacaoId: id,
        resultado: resultado,
        decisoesPossiveis: const {2: true, 3: true},
      ),
      throwsArgumentError,
    );
  });

  test('confirmar duas vezes não duplica: a segunda cai por estado', () async {
    await importarBase();
    final id = await novaPrevia();
    final resultado = await repo.conciliarArquivo(
        contaId: contaId, novas: arquivoSobreposto);
    await repo.confirmarImportacao(
      importacaoId: id,
      resultado: resultado,
      decisoesPossiveis: const {2: true},
    );

    await expectLater(
      repo.confirmarImportacao(
        importacaoId: id,
        resultado: resultado,
        decisoesPossiveis: const {2: true},
      ),
      throwsStateError,
    );
    expect(await banco.transacoes.count().getSingle(), 5);
  });

  test('dois Pix legítimos idênticos no mesmo arquivo valem dois', () async {
    const doisIguais = [
      TransacaoImportada(
          data: '2026-02-01', valorCentavos: 25000, descricao: 'PIX GISELE'),
      TransacaoImportada(
          data: '2026-02-01', valorCentavos: 25000, descricao: 'PIX GISELE'),
    ];
    final id = await novaPrevia();
    final resultado =
        await repo.conciliarArquivo(contaId: contaId, novas: doisIguais);
    expect(resultado.quantidadeNova, 2);

    final resumo = await repo.confirmarImportacao(
      importacaoId: id,
      resultado: resultado,
      decisoesPossiveis: const {},
    );
    expect(resumo.persistidas, 2);
  });

  test('identificador repetido no arquivo, mantido duas vezes pelo usuário, '
      'persiste duas linhas com o mesmo fitid (desvio 1 do schema em ação)',
      () async {
    const repetido = [
      TransacaoImportada(
          data: '2026-03-01',
          valorCentavos: 10000,
          descricao: 'PIX RENATA',
          idExterno: 'FITDUP'),
      TransacaoImportada(
          data: '2026-03-01',
          valorCentavos: 10000,
          descricao: 'PIX RENATA',
          idExterno: 'FITDUP'),
    ];
    final id = await novaPrevia();
    final resultado =
        await repo.conciliarArquivo(contaId: contaId, novas: repetido);
    expect(resultado.quantidadePossivelDuplicata, 1);

    await repo.confirmarImportacao(
      importacaoId: id,
      resultado: resultado,
      decisoesPossiveis: const {1: true},
    );
    final linhas = await banco.select(banco.transacoes).get();
    expect(linhas.where((t) => t.fitid == 'FITDUP'), hasLength(2));
  });
}
