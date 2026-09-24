import 'dart:io';
import 'dart:math';

import 'package:desmalha_app/backup/chaves_backup.dart';
import 'package:desmalha_app/backup/estado_backup.dart';
import 'package:desmalha_app/backup/politica_backup.dart';
import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/versao.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../servicos_falsos.dart';
import 'armazenamento_falso.dart';

final _agora = DateTime.utc(2026, 9, 24, 12);

void main() {
  group('política do automático', () {
    DecisaoBackup decidir({
      DateTime? ultimo,
      bool sessao = true,
      bool codigo = true,
      bool wifi = true,
    }) => decidirBackupAutomatico(
      agora: _agora,
      ultimoSucessoEm: ultimo,
      comSessao: sessao,
      codigoConfirmado: codigo,
      emWifi: wifi,
    );

    test('primeiro backup, no Wi-Fi, com código: executa', () {
      expect(decidir().executar, isTrue);
    });
    test('sem código confirmado: NÃO liga', () {
      expect(
        decidir(codigo: false).motivo,
        MotivoSemBackup.codigoNaoConfirmado,
      );
    });
    test('fora do Wi-Fi: espera', () {
      expect(decidir(wifi: false).motivo, MotivoSemBackup.foraDoWifi);
    });
    test('já fez nas últimas 24 h: espera', () {
      expect(
        decidir(ultimo: _agora.subtract(const Duration(hours: 23))).motivo,
        MotivoSemBackup.jaFezHoje,
      );
      expect(
        decidir(ultimo: _agora.subtract(const Duration(hours: 25))).executar,
        isTrue,
      );
    });
    test('sem sessão: nada', () {
      expect(decidir(sessao: false).motivo, MotivoSemBackup.semSessao);
    });
    test('aviso de desatualizado: nunca, ou mais de 7 dias', () {
      expect(backupDesatualizado(agora: _agora, ultimoSucessoEm: null), isTrue);
      expect(
        backupDesatualizado(
          agora: _agora,
          ultimoSucessoEm: _agora.subtract(const Duration(days: 8)),
        ),
        isTrue,
      );
      expect(
        backupDesatualizado(
          agora: _agora,
          ultimoSucessoEm: _agora.subtract(const Duration(days: 6)),
        ),
        isFalse,
      );
    });
  });

  group('controlador', () {
    late ChavesBackup chaves;

    setUpAll(() async {
      chaves = ChavesBackup(cofre: CofreEmMemoria(), aleatorio: Random(5));
      await chaves.confirmarCodigo(gerarCodigoRecuperacao(Random(6)));
    });

    test('automático faz o primeiro backup e registra o sucesso', () async {
      final estado = RepositorioEstadoBackupMemoria();
      final c = controladorBackupFalso(
        chaves: chaves,
        estado: estado,
        relogio: () => _agora,
      );
      expect((await c.automatico()).executar, isTrue);
      expect(estado.estado.ultimaSeq, 1);
      expect(estado.estado.ultimoSucessoEm, _agora);
      expect(c.desatualizado, isFalse);
    });

    test('dia seguinte sem mudança: não sobe nada (conteúdo igual)', () async {
      final estado = RepositorioEstadoBackupMemoria();
      final armazenamento = ArmazenamentoFalso();
      var agora = _agora;
      final c = controladorBackupFalso(
        chaves: chaves,
        estado: estado,
        armazenamento: armazenamento,
        relogio: () => agora,
      );
      await c.automatico();
      agora = agora.add(const Duration(days: 2));
      await c.automatico();
      expect(armazenamento.objetos, hasLength(1));
      expect(c.ultimoAviso, contains('Nada mudou'));
    });

    test('dia seguinte com mudança: sobe', () async {
      final fonte = FonteEmMemoria();
      final armazenamento = ArmazenamentoFalso();
      var agora = _agora;
      final c = controladorBackupFalso(
        chaves: chaves,
        fonte: fonte,
        armazenamento: armazenamento,
        relogio: () => agora,
      );
      await c.automatico();
      fonte.documentos = [
        ...fonte.documentos,
        const DocumentoBackup('dependentes', {'id': 'd1', 'nome': 'X'}),
      ];
      agora = agora.add(const Duration(days: 2));
      await c.automatico();
      expect(armazenamento.metadados.keys.toList()..sort(), [1, 2]);
    });

    test('sem código confirmado: automático não liga, nada sobe', () async {
      final semCodigo = ChavesBackup(
        cofre: CofreEmMemoria(),
        aleatorio: Random(1),
      );
      final armazenamento = ArmazenamentoFalso();
      final c = controladorBackupFalso(
        chaves: semCodigo,
        armazenamento: armazenamento,
      );
      final d = await c.automatico();
      expect(d.motivo, MotivoSemBackup.codigoNaoConfirmado);
      expect(armazenamento.chamadas, isEmpty);
    });

    test(
      'falha fica registrada e visível, sem apagar o último sucesso',
      () async {
        final estado = RepositorioEstadoBackupMemoria();
        final armazenamento = ArmazenamentoFalso();
        var agora = _agora;
        final c = controladorBackupFalso(
          chaves: chaves,
          estado: estado,
          armazenamento: armazenamento,
          relogio: () => agora,
        );
        await c.fazerAgora();
        armazenamento.engolirProximoEnvio = true;
        agora = agora.add(const Duration(days: 1));
        await c.fazerAgora();
        expect(c.ultimaFalha, contains('NÃO foi dado como feito'));
        expect(estado.estado.resultado, 'falha');
        expect(estado.estado.ultimoSucessoEm, _agora);
      },
    );
  });

  test(
    'estado persiste no banco local (backup_estado), sucesso e falha',
    () async {
      final banco = BancoLocal(NativeDatabase.memory());
      final repo = RepositorioEstadoBackupDrift(banco);
      expect((await repo.ler()).ultimoSucessoEm, isNull);
      await repo.registrarSucesso(
        seq: 3,
        hashConteudo: 'sha256:x',
        em: _agora,
        tamanhoBytes: 900,
        formatoVersao: 1,
      );
      await repo.registrarFalha('sem rede');
      final e = await repo.ler();
      expect(e.ultimaSeq, 3);
      expect(e.ultimoSucessoEm, _agora);
      expect(e.resultado, 'falha');
      expect(e.erroDetalhe, 'sem rede');
      await banco.close();
    },
  );

  test('versão do app no manifesto = version do pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      RegExp(
        r'^version:\s*(\S+)',
        multiLine: true,
      ).firstMatch(pubspec)!.group(1),
      versaoDoApp,
    );
  });
}
