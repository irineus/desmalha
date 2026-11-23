import 'dart:convert';
import 'dart:typed_data';

import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/importacao/controlador_importacao.dart';
import 'package:desmalha_app/importacao/tela_importacao.dart';
import 'package:desmalha_app/suporte/porta_suporte.dart';
import 'package:desmalha_app/suporte/servico_suporte.dart';
import 'package:desmalha_app/tema/tema.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../servicos_falsos.dart';

const _uid = '00000000-0000-4000-8000-00000000000a';

void main() {
  late BancoLocal banco;
  late PortaSuporteFalsa porta;
  late ServicoSuporte servico;
  final arquivo = ArquivoSelecionado(
    nome: 'extrato março (1).ofx',
    bytes: Uint8List.fromList(
      utf8.encode('OFXHEADER:100\nDATA:OFXSGML\nCORROMPIDO'),
    ),
  );

  setUp(() {
    banco = BancoLocal(NativeDatabase.memory());
    porta = PortaSuporteFalsa();
    servico = ServicoSuporte(banco, porta: porta, usuarioId: () => _uid);
  });
  tearDown(() => banco.close());

  test('manda o arquivo como veio, na pasta do titular, e guarda o registro '
      'local com o prazo do servidor', () async {
    final r = await servico.enviarExtrato(
      arquivo,
      motivo: 'não lido',
      bancoInformado: '  ',
    );
    expect(r.path, startsWith('$_uid/'));
    expect(r.path, endsWith('-extrato_mar_o__1_.ofx'));
    expect(porta.recebidos[r.path], arquivo.bytes);
    expect(porta.bancos[r.path], isNull, reason: 'banco em branco não vai');
    final local = await banco.select(banco.enviosSuporte).getSingle();
    expect((local.pathRemoto, local.arquivoNome), (r.path, arquivo.nome));
    expect(local.expiraEm, r.expiraEm.millisecondsSinceEpoch);
  });

  test('falha no servidor não deixa registro local; sem sessão não envia',
      () async {
    porta.falhar = const FalhaEnvioSuporte('fora do ar');
    await expectLater(
      servico.enviarExtrato(arquivo, motivo: 'm'),
      throwsA(isA<FalhaEnvioSuporte>()),
    );
    expect(await banco.select(banco.enviosSuporte).get(), isEmpty);

    final semSessao =
        ServicoSuporte(banco, porta: PortaSuporteFalsa(), usuarioId: () => null);
    await expectLater(
      semSessao.enviarExtrato(arquivo, motivo: 'm'),
      throwsA(isA<FalhaEnvioSuporte>()),
    );
  });

  testWidgets('arquivo que não é lido: o botão aparece na falha; nada sai '
      'sem a marcação; enviado, diz até quando fica', (tester) async {
    final seletor = SeletorFalso()..proximo = arquivo;
    await tester.pumpWidget(
      MaterialApp(
        theme: temaDesmalha(),
        home: TelaImportacao(
          servicos: servicosFalsos(seletorDeArquivo: seletor, suporte: servico),
        ),
      ),
    );
    Future<void> assentar() async {
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 400));
    }

    await assentar();
    await tester.tap(find.byKey(const Key('botao_escolher_arquivo')));
    await assentar();
    expect(find.byKey(const Key('erro_importacao')), findsOneWidget);

    await tester.tap(find.byKey(const Key('botao_enviar_suporte')));
    await assentar();
    expect(find.byKey(const Key('escopo_envio')), findsOneWidget);
    final botao = tester.widget<FilledButton>(
      find.byKey(const Key('botao_confirmar_envio')),
    );
    expect(botao.onPressed, isNull, reason: 'sem consentimento, nada sai');

    await tester.tap(find.byKey(const Key('consentimento_envio')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('botao_confirmar_envio')));
    await tester.tap(find.byKey(const Key('botao_confirmar_envio')));
    await assentar();
    expect(
      tester.widget<Text>(find.byKey(const Key('envio_concluido'))).data,
      contains('25/10/2026'),
    );
    expect(porta.recebidos, hasLength(1));
    expect(porta.motivos.values.single, startsWith('Arquivo não lido'));
  });
}
