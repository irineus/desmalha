import 'dart:convert';
import 'dart:io';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:desmalha_app/catalogo/porta_catalogo.dart';
import 'package:desmalha_app/catalogo/repositorio_catalogo.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dublê da porta remota: devolve o que o teste mandar, ou falha como a
/// rede falha.
class PortaFalsa implements PortaCatalogoRemota {
  PortaFalsa(this.resposta);

  List<Map<String, Object?>>? resposta;
  int chamadas = 0;

  @override
  Future<List<Map<String, Object?>>> buscarItens() async {
    chamadas++;
    final resposta = this.resposta;
    if (resposta == null) {
      throw ExcecaoCatalogoRemoto('sem rede (dublê)');
    }
    return resposta;
  }
}

Map<String, Object?> itemFeriados({int ano = 2026, String fonte = 'teste'}) => {
      'tipo': 'feriados_bancarios',
      'id': 'feriados-bancarios-$ano',
      'conteudo': {
        'id': 'feriados-bancarios-$ano',
        'ano': ano,
        'fonte': fonte,
        'datas': ['$ano-12-25'],
      },
    };

String snapshotDe(List<Map<String, Object?>> itens) =>
    jsonEncode(Catalogo.fromItens(itens).toJson());

void main() {
  late Directory temporario;
  late File cache;

  setUp(() {
    temporario = Directory.systemTemp.createTempSync('catalogo-teste');
    cache = File('${temporario.path}/catalogo_cache.json');
  });

  tearDown(() => temporario.deleteSync(recursive: true));

  RepositorioCatalogo repositorio({
    PortaCatalogoRemota? remota,
    String? seed,
  }) =>
      RepositorioCatalogo(
        remota: remota,
        arquivoCache: cache,
        carregarSeed: () async =>
            seed ??
            snapshotDe([itemFeriados(fonte: 'seed embarcado')]),
      );

  test('sem cache, carrega do seed embarcado', () async {
    final catalogo = await repositorio().carregar();
    expect(catalogo.feriadosPorAno.single.fonte, 'seed embarcado');
  });

  test('cache existente vence o seed', () async {
    cache.writeAsStringSync(
      snapshotDe([itemFeriados(fonte: 'do cache')]),
    );
    final catalogo = await repositorio().carregar();
    expect(catalogo.feriadosPorAno.single.fonte, 'do cache');
  });

  test('cache corrompido não derruba: cai para o seed', () async {
    cache.writeAsStringSync('{isso não é json');
    final catalogo = await repositorio().carregar();
    expect(catalogo.feriadosPorAno.single.fonte, 'seed embarcado');
  });

  test('cache com conteúdo inválido também cai para o seed', () async {
    // JSON bem formado, catálogo malformado — um tipo conhecido que não
    // valida precisa ser tratado como cache corrompido, não como fatal.
    cache.writeAsStringSync(jsonEncode({
      'formatoVersao': 1,
      'itens': [
        {
          'tipo': 'tabela_irpf',
          'id': 'irpf-quebrada',
          'conteudo': {'id': 'irpf-quebrada'},
        },
      ],
    }));
    final catalogo = await repositorio().carregar();
    expect(catalogo.feriadosPorAno.single.fonte, 'seed embarcado');
  });

  test('atualizar valida, grava o cache e uma nova instância o lê', () async {
    final porta = PortaFalsa([itemFeriados(fonte: 'do servidor')]);
    expect(await repositorio(remota: porta).atualizar(), isTrue);

    // Instância nova, sem rede: só o cache explica o resultado.
    final catalogo = await repositorio().carregar();
    expect(catalogo.feriadosPorAno.single.fonte, 'do servidor');
  });

  test('atualizar troca o catálogo em memória da própria instância',
      () async {
    final porta = PortaFalsa([itemFeriados(fonte: 'do servidor')]);
    final repo = repositorio(remota: porta);
    expect((await repo.carregar()).feriadosPorAno.single.fonte,
        'seed embarcado');
    await repo.atualizar();
    expect((await repo.carregar()).feriadosPorAno.single.fonte,
        'do servidor');
  });

  test('falha de rede devolve false e preserva o cache', () async {
    cache.writeAsStringSync(snapshotDe([itemFeriados(fonte: 'do cache')]));
    final porta = PortaFalsa(null);
    expect(await repositorio(remota: porta).atualizar(), isFalse);
    expect((await repositorio().carregar()).feriadosPorAno.single.fonte,
        'do cache');
  });

  test('payload malformado devolve false e NUNCA substitui um cache bom',
      () async {
    cache.writeAsStringSync(snapshotDe([itemFeriados(fonte: 'do cache')]));
    final porta = PortaFalsa([
      {
        'tipo': 'tabela_irpf',
        'id': 'irpf-quebrada',
        'conteudo': {'id': 'irpf-quebrada'},
      },
    ]);
    expect(await repositorio(remota: porta).atualizar(), isFalse);
    expect((await repositorio().carregar()).feriadosPorAno.single.fonte,
        'do cache');
  });

  test('sem configuração de servidor, atualizar é não-op', () async {
    expect(await repositorio(remota: null).atualizar(), isFalse);
    expect(cache.existsSync(), isFalse);
  });

  test('tipo desconhecido vindo do servidor sobrevive no cache', () async {
    // Compatibilidade para a frente: o servidor ganha um tipo novo, o app
    // antigo ignora MAS não descarta — quando o app atualizar, o conteúdo
    // já está no aparelho.
    final porta = PortaFalsa([
      itemFeriados(),
      {
        'tipo': 'simulacao_pf_cnpj',
        'id': 'v1',
        'conteudo': {'qualquer': 'coisa'},
      },
    ]);
    expect(await repositorio(remota: porta).atualizar(), isTrue);
    final relido = await repositorio().carregar();
    expect(relido.tiposIgnorados, ['simulacao_pf_cnpj']);
  });
}
