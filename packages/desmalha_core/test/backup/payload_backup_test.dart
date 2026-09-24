import 'dart:convert';
import 'dart:io' show gzip;

import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

import 'amostra_backup.dart';

Future<List<int>> _serializar(List<DocumentoBackup> docs) => serializarPayload(
  documentos: docs,
  appVersao: '1.0.0',
  schemaLocalVersao: 1,
  geradoEm: DateTime.utc(2026, 9, 24, 12),
  seq: 7,
  plataforma: 'android',
);

/// Reescreve o NDJSON dentro do gzip — para montar blobs malformados.
List<int> _reescrever(List<int> gz, String Function(String) f) =>
    gzip.encode(utf8.encode(f(utf8.decode(gzip.decode(gz)))));

void main() {
  test('round-trip: exportar → ler devolve os mesmos documentos', () async {
    final lido = await lerPayload(await _serializar(amostraBackup));
    // Igualdade profunda de mapas: a ordem das chaves é canônica na saída.
    expect(lido.documentos.map((d) => d.toJson()).toList(),
        amostraBackup.map((d) => d.toJson()).toList());
    expect(lido.manifesto.formatoVersao, formatoBackupAtual);
    expect(lido.manifesto.seq, 7);
    expect(lido.manifesto.contagens['transacoes'], 2);
  });

  test('a mesma entrada vira os mesmos bytes de NDJSON (ordem de chaves '
      'canônica)', () async {
    final invertida = [
      for (final d in amostraBackup)
        DocumentoBackup(
          d.tabela,
          Map.fromEntries(d.dados.entries.toList().reversed),
        ),
    ];
    String ndjson(List<int> gz) => utf8.decode(gzip.decode(gz));
    expect(ndjson(await _serializar(invertida)),
        ndjson(await _serializar(amostraBackup)));
  });

  test('hashDoConteudo = hash_conteudo do manifesto, e muda com o dado',
      () async {
    final lido = await lerPayload(await _serializar(amostraBackup));
    expect(await hashDoConteudo(amostraBackup), lido.manifesto.hashConteudo);
    final mudado = [
      ...amostraBackup,
      const DocumentoBackup('dependentes', {'id': 'd1', 'nome': 'X'}),
    ];
    expect(await hashDoConteudo(mudado),
        isNot(lido.manifesto.hashConteudo));
  });

  test('backup vazio (usuário novo) é válido', () async {
    final lido = await lerPayload(await _serializar(const []));
    expect(lido.documentos, isEmpty);
  });

  group('recusa integral, nunca restauração parcial', () {
    test('formato de versão futura: "atualize o app"', () async {
      final gz = _reescrever(await _serializar(amostraBackup),
          (t) => t.replaceFirst('"formato_versao":1', '"formato_versao":2'));
      await expectLater(
        lerPayload(gz),
        throwsA(isA<BackupDeVersaoFuturaException>()
            .having((e) => e.mensagem, 'mensagem', contains('Atualize'))),
      );
    });

    test('conteúdo alterado sem atualizar o hash', () async {
      final gz = _reescrever(await _serializar(amostraBackup),
          (t) => t.replaceFirst('"valor_centavos":45000', '"valor_centavos":4500'));
      await expectLater(lerPayload(gz), throwsA(isA<BackupInvalidoException>()));
    });

    test('linha removida é pega pelas contagens do manifesto', () async {
      final gz = _reescrever(await _serializar(amostraBackup), (t) {
        final linhas = t.split('\n')..removeLast();
        return linhas.join('\n');
      });
      await expectLater(lerPayload(gz), throwsA(isA<BackupInvalidoException>()));
    });

    test('ponto flutuante em qualquer valor', () async {
      await expectLater(
        _serializar([
          const DocumentoBackup('transacoes', {'valor_centavos': 450.0}),
        ]),
        throwsA(isA<BackupInvalidoException>()),
      );
    });

    test('tabela que não entra no backup (ruído operacional)', () async {
      for (final t in ['notificacoes_locais', 'auditoria', 'envios_suporte',
        'backup_estado', 'cat_feriados_bancarios']) {
        await expectLater(
          _serializar([DocumentoBackup(t, const {'id': 'x'})]),
          throwsA(isA<BackupInvalidoException>()),
          reason: t,
        );
      }
    });

    test('importação levando a prévia de trabalho', () async {
      await expectLater(
        _serializar([
          const DocumentoBackup('importacoes', {'id': 'i', 'previa_json': '{}'}),
        ]),
        throwsA(isA<BackupInvalidoException>()),
      );
    });

    test('primeira linha que não é manifesto', () async {
      final gz = gzip.encode(utf8.encode('{"t":"perfil","d":{}}'));
      await expectLater(lerPayload(gz), throwsA(isA<BackupInvalidoException>()));
    });

    test('lixo que não é gzip', () async {
      await expectLater(
        lerPayload(utf8.encode('não sou gzip')),
        throwsA(isA<BackupInvalidoException>()),
      );
    });
  });

  test('migração: cadeia de funções puras aplicada antes de devolver',
      () async {
    // Um app hipotético que já lê o formato 2: o blob v1 passa pela migração
    // 1→2 antes de chegar ao banco.
    final lido = await lerPayload(
      await _serializar(amostraBackup),
      formatoSuportado: 2,
      migracoes: {
        1: (docs) => [
          for (final d in docs)
            DocumentoBackup(d.tabela, {...d.dados, 'migrado_para_v2': true}),
        ],
      },
    );
    expect(lido.documentos.every((d) => d.dados['migrado_para_v2'] == true),
        isTrue);
  });

  test('migração faltando na cadeia é recusa, não pulo', () async {
    await expectLater(
      lerPayload(await _serializar(amostraBackup), formatoSuportado: 2,
          migracoes: const {}),
      throwsA(isA<BackupInvalidoException>()),
    );
  });
}
