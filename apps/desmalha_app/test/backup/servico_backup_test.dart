import 'dart:math';
import 'dart:typed_data';

import 'package:desmalha_app/backup/chaves_backup.dart';
import 'package:desmalha_app/backup/servico_backup.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../servicos_falsos.dart';
import 'armazenamento_falso.dart';

const _uid = '00000000-0000-4000-8000-00000000000a';

class _FonteFalsa implements FonteDocumentosBackup {
  List<DocumentoBackup> documentos = [
    const DocumentoBackup('transacoes', {
      'id': 'tx-1',
      'valor_centavos': 45000,
    }),
  ];
  List<DocumentoBackup>? importados;

  @override
  Future<int> versaoDoSchemaLocal() async => 1;
  @override
  Future<List<DocumentoBackup>> exportar() async => documentos;
  @override
  Future<void> importar(List<DocumentoBackup> d) async => importados = d;
}

void main() {
  late ChavesBackup chavesConfirmadas;

  setUpAll(() async {
    // Uma derivação Argon2id real, reaproveitada: é o que o app faz.
    final cofre = CofreEmMemoria();
    chavesConfirmadas = ChavesBackup(cofre: cofre, aleatorio: Random(5));
    await chavesConfirmadas.confirmarCodigo(gerarCodigoRecuperacao(Random(6)));
  });

  ServicoBackup servico(
    ArmazenamentoFalso porta,
    _FonteFalsa fonte, {
    ChavesBackup? chaves,
    String? uid = _uid,
  }) => ServicoBackup(
    porta: porta,
    chaves: chaves ?? chavesConfirmadas,
    fonte: fonte,
    usuarioId: () => uid,
    appVersao: '1.0.0',
    plataforma: 'android',
    relogio: () => DateTime.utc(2026, 9, 24),
  );

  test(
    'ordem: upload → confere → registra → prune; caminho <uid>/<seq>',
    () async {
      final porta = ArmazenamentoFalso();
      final r = (await servico(porta, _FonteFalsa()).fazerBackup())!;
      expect(r.seq, 1);
      expect(porta.objetos.keys, ['$_uid/000001.dsmb']);
      final i = porta.chamadas;
      // A conferência pós-envio é a ÚLTIMA listagem de objetos antes do
      // registro (a primeira serve para escolher a seq).
      final envio = i.indexOf('enviar $_uid/000001.dsmb');
      final conferencia = i.lastIndexOf('listarObjetos');
      expect(envio, lessThan(conferencia));
      expect(conferencia, lessThan(i.indexOf('registrarMetadado 1')));
      expect(porta.metadados[1]!.sha256, r.sha256);
    },
  );

  test('seq monotônica e só os 3 mais recentes ficam — objeto antes do '
      'registro', () async {
    final porta = ArmazenamentoFalso();
    final s = servico(porta, _FonteFalsa());
    for (var i = 0; i < 5; i++) {
      await s.fazerBackup();
    }
    expect(porta.metadados.keys.toList()..sort(), [3, 4, 5]);
    expect(porta.objetos.keys.toList()..sort(), [
      '$_uid/000003.dsmb',
      '$_uid/000004.dsmb',
      '$_uid/000005.dsmb',
    ]);
    final i = porta.chamadas;
    final removeuObjeto = i.lastIndexOf('removerObjetos $_uid/000002.dsmb');
    final removeuRegistro = i.lastIndexOf('removerMetadados 2');
    expect(removeuObjeto, greaterThanOrEqualTo(0));
    expect(removeuObjeto, lessThan(removeuRegistro));
  });

  test('nunca sobrescreve: caminho ocupado vira falha visível', () async {
    final porta = ArmazenamentoFalso()
      ..outroAparelhoOcupaOProximoCaminho = true;
    await expectLater(
      servico(porta, _FonteFalsa()).fazerBackup(),
      throwsA(
        isA<FalhaBackup>().having(
          (f) => f.mensagem,
          'mensagem',
          contains('Outro aparelho'),
        ),
      ),
    );
    expect(porta.objetos['$_uid/000001.dsmb'], [1, 2, 3]);
  });

  test(
    'servidor que diz OK e não guarda: backup NÃO dado como feito',
    () async {
      final porta = ArmazenamentoFalso()..engolirProximoEnvio = true;
      await expectLater(
        servico(porta, _FonteFalsa()).fazerBackup(),
        throwsA(
          isA<FalhaBackup>().having(
            (f) => f.mensagem,
            'mensagem',
            contains('NÃO foi dado como feito'),
          ),
        ),
      );
      expect(porta.metadados, isEmpty);
    },
  );

  test('blob órfão (registro falhou) é varrido no backup seguinte', () async {
    final porta = ArmazenamentoFalso()..falharProximoRegistro = true;
    final s = servico(porta, _FonteFalsa());
    await expectLater(s.fazerBackup(), throwsA(anything));
    expect(porta.objetos.keys, ['$_uid/000001.dsmb']);
    expect(porta.metadados, isEmpty);

    // A seq seguinte pula o órfão (não fica presa no caminho ocupado), e o
    // prune o apaga.
    final r = (await s.fazerBackup())!;
    expect(r.seq, 2);
    expect(r.removidos, ['$_uid/000001.dsmb']);
    expect(porta.objetos.keys, ['$_uid/000002.dsmb']);
    expect(porta.metadados.keys, [2]);
  });

  test('sem código confirmado: não sela, não envia, e diz por quê', () async {
    final porta = ArmazenamentoFalso();
    final semCodigo = ChavesBackup(
      cofre: CofreEmMemoria(),
      aleatorio: Random(9),
    );
    await expectLater(
      servico(porta, _FonteFalsa(), chaves: semCodigo).fazerBackup(),
      throwsA(
        isA<FalhaBackup>().having(
          (f) => f.mensagem,
          'mensagem',
          contains('desligado'),
        ),
      ),
    );
    expect(porta.chamadas, isEmpty);
  });

  test('sem sessão: nada acontece', () async {
    final porta = ArmazenamentoFalso();
    await expectLater(
      servico(porta, _FonteFalsa(), uid: null).fazerBackup(),
      throwsA(isA<FalhaBackup>()),
    );
    expect(porta.chamadas, isEmpty);
  });

  test(
    'restauração: baixa o mais recente, confere tudo e só então importa',
    () async {
      final porta = ArmazenamentoFalso();
      final fonte = _FonteFalsa();
      final s = servico(porta, fonte);
      await s.fazerBackup();
      fonte.documentos = [
        const DocumentoBackup('transacoes', {
          'id': 'tx-2',
          'valor_centavos': 99,
        }),
      ];
      await s.fazerBackup();

      final conteudo = await s.restaurarMaisRecente();
      expect(conteudo.manifesto.seq, 2);
      expect(fonte.importados!.single.dados['id'], 'tx-2');
    },
  );

  test(
    'blob adulterado no servidor: sha256 não confere, nada é importado',
    () async {
      final porta = ArmazenamentoFalso();
      final fonte = _FonteFalsa();
      final s = servico(porta, fonte);
      await s.fazerBackup();
      final path = porta.objetos.keys.single;
      porta.objetos[path] = Uint8List.fromList(porta.objetos[path]!)
        ..[200] ^= 1;
      await expectLater(
        s.restaurarMaisRecente(),
        throwsA(
          isA<FalhaBackup>().having(
            (f) => f.mensagem,
            'mensagem',
            contains('Nada foi restaurado'),
          ),
        ),
      );
      expect(fonte.importados, isNull);
    },
  );
}
