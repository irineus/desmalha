import 'dart:convert';
import 'dart:io';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:desmalha_core/validacao.dart';
import 'package:test/test.dart';

/// Data fixa renderizada no `formatoData` do perfil.
String _dataNoFormato(String formato) => formato
    .replaceAll('yyyy', '2026')
    .replaceAll('MM', '07')
    .replaceAll('dd', '10')
    .replaceAll('yy', '26');

/// Monta um CSV sintético NA FORMA que o perfil declara: delimitador,
/// contagem de colunas, formato de data e de valor vêm todos do próprio
/// perfil, e não de uma cópia escrita à mão no teste.
String _csvNaFormaDoPerfil(PerfilCsv perfil, String descricao) {
  final colunas = [
    perfil.colunaData,
    perfil.colunaValor,
    perfil.colunaDescricao,
    perfil.colunaIdExterno ?? 0,
    perfil.colunaTipo ?? 0,
  ].reduce((a, b) => a > b ? a : b) +
      1;

  final campos = List.filled(colunas, '');
  campos[perfil.colunaData] = _dataNoFormato(perfil.formatoData);
  campos[perfil.colunaValor] =
      perfil.formatoValor == FormatoValor.virgulaDecimal ? '1500,00' : '1500.00';
  campos[perfil.colunaDescricao] = descricao;
  if (perfil.colunaIdExterno != null) {
    campos[perfil.colunaIdExterno!] = 'id-0001';
  }
  if (perfil.colunaTipo != null) {
    // Um marcador que NÃO é o de débito — a linha é um crédito.
    campos[perfil.colunaTipo!] = perfil.marcadorDebito == 'C' ? 'D' : 'C';
  }

  final cabecalho = [
    for (var i = 0; i < perfil.linhasCabecalho; i++)
      List.generate(colunas, (c) => 'Rotulo$c').join(perfil.delimitador),
  ];
  return '${[...cabecalho, campos.join(perfil.delimitador)].join('\n')}\n';
}

/// Os JSONs em `perfis/` são os perfis de referência que o usuário passa ao
/// CLI (`--perfil`) e o embrião do catálogo versionado servido pela API.
/// Este teste garante que continuam carregáveis por [PerfilCsv.fromJson].
void main() {
  group('perfis de referência em perfis/', () {
    final arquivos = Directory('perfis')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();

    test('existem os três perfis iniciais', () {
      final nomes = arquivos.map((f) => f.uri.pathSegments.last).toSet();
      expect(
        nomes,
        containsAll({
          'nubank-conta-csv-v1.json',
          'inter-conta-csv-v1.json',
          'bb-conta-csv-v1.json',
        }),
      );
    });

    for (final arquivo in Directory('perfis')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))) {
      test('${arquivo.uri.pathSegments.last} carrega e o id bate com o nome',
          () {
        final json =
            jsonDecode(arquivo.readAsStringSync()) as Map<String, Object?>;
        final perfil = PerfilCsv.fromJson(json);
        expect('${perfil.id}.json', arquivo.uri.pathSegments.last);
        // Round-trip: o que o catálogo servir tem de voltar idêntico.
        expect(PerfilCsv.fromJson(perfil.toJson()).toJson(), perfil.toJson());
      });

      test('${arquivo.uri.pathSegments.last}: anonimizar → parsear fecha o '
          'ciclo do CLI', () {
        // Exercita o ARQUIVO que o usuário passa em `--perfil`, e não uma
        // cópia inline: os outros testes constroem `PerfilCsv` à mão, então
        // um JSON que divergisse do que eles supõem passaria despercebido.
        //
        // É o ciclo inteiro do card: extrato entra, cópia anonimizada sai,
        // e é ela que vira fixture. Se a anonimização corromper a estrutura
        // que o próprio perfil declara, o parse acusa aqui.
        final json =
            jsonDecode(arquivo.readAsStringSync()) as Map<String, Object?>;
        final perfil = PerfilCsv.fromJson(json);

        const descricao = 'Pix recebido de MARIANA PACIENTE ANDRADE '
            '123.456.789-01';
        final csv = _csvNaFormaDoPerfil(perfil, descricao);

        final original = parseCsv(csv, perfil);
        expect(original.avisos, isEmpty,
            reason: 'a fixture sintética precisa ser válida no perfil');
        expect(original.transacoes.length, 1);

        final anonimo = anonimizarCsv(csv, perfil);
        for (final vazamento in [
          'MARIANA',
          'PACIENTE',
          'ANDRADE',
          '123.456.789-01',
        ]) {
          expect(anonimo, isNot(contains(vazamento)),
              reason: '"$vazamento" sobreviveu em:\n$anonimo');
        }

        final relido = parseCsv(anonimo, perfil);
        expect(relido.avisos, isEmpty,
            reason: 'a cópia anonimizada precisa continuar legível pelo '
                'MESMO perfil — é o que a torna utilizável como fixture');
        expect(relido.transacoes.length, original.transacoes.length);
        expect(relido.transacoes.first.data, original.transacoes.first.data,
            reason: 'data é estrutura, preservada');
        expect(relido.transacoes.first.valorCentavos.sign,
            original.transacoes.first.valorCentavos.sign);
      });
    }
  });
}
