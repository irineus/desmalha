import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/dados/repositorio_importacao.dart';
import 'package:desmalha_app/importacao/controlador_importacao.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lembretes/notificacoes_falsas.dart';
import '../servicos_falsos.dart';
import 'extratos_falsos.dart';

void main() {
  late BancoLocal banco;
  late RepositorioImportacao repo;
  late SeletorFalso seletor;

  setUp(() {
    banco = BancoLocal(NativeDatabase.memory());
    repo = RepositorioImportacao(banco);
    seletor = SeletorFalso();
  });
  tearDown(() => banco.close());

  ControladorImportacao novo() => ControladorImportacao(
    repositorio: repo,
    seletor: seletor,
    carregarCatalogo: () async => catalogoDoSeed(),
  );

  Future<int> linhasEmTransacoes() async =>
      (await banco
              .customSelect('SELECT count(*) AS n FROM transacoes')
              .getSingle())
          .read<int>('n');

  /// Importa [arquivo] numa conta nova e confirma.
  Future<void> importarBase(ArquivoSelecionado arquivo) async {
    seletor.proximo = arquivo;
    final c = novo();
    await c.escolherArquivo();
    if (!c.contaDefinida) await c.selecionarConta(null); // conta nova
    await c.confirmar();
    expect(c.estado, EstadoImportacao.concluida);
  }

  test('primeira importação: conta nova, prévia, nada gravado antes de '
      'confirmar', () async {
    seletor.proximo = ofxSintetico([pixAna, pixBruno, mercado]);
    final c = novo();
    await c.escolherArquivo();
    expect(c.estado, EstadoImportacao.previa);
    expect(c.novaConta, isTrue);
    expect(c.apelidoNovaConta, '0260 final 5678');
    expect(c.resultado!.quantidadeNova, 3);
    expect(await linhasEmTransacoes(), 0, reason: 'prévia não grava');

    await c.confirmar();
    expect(c.estado, EstadoImportacao.concluida);
    expect(c.resumo!.persistidas, 3);
    expect(await linhasEmTransacoes(), 3);
    final contas = await repo.listarContas();
    expect(contas.single.bancoCodigo, '0260');
  });

  test('o mesmo arquivo de novo: avisa antes da prévia', () async {
    await importarBase(ofxSintetico([pixAna]));
    seletor.proximo = ofxSintetico([pixAna]);
    final c = novo();
    await c.escolherArquivo();
    expect(c.estado, EstadoImportacao.jaImportado);
    expect(c.jaImportadoEm, isNotNull);
  });

  test(
    'extrato sobreposto: o que já existe é suprimido e não grava de novo',
    () async {
      await importarBase(ofxSintetico([pixAna, pixBruno]));
      seletor.proximo = ofxSintetico([pixBruno, mercado], nome: 'agosto-2.ofx');
      final c = novo();
      await c.escolherArquivo();
      // A única conta do mesmo banco vem pré-selecionada.
      expect(c.novaConta, isFalse);
      expect(c.contaId, isNotNull);
      expect(c.resultado!.quantidadeSuprimida, 1);
      expect(c.resultado!.quantidadeNova, 1);
      await c.confirmar();
      expect(c.resumo!.persistidas, 1);
      expect(c.resumo!.suprimidas, 1);
      expect(await linhasEmTransacoes(), 3);
    },
  );

  test(
    'possível duplicata: confirmar exige decidir, e a decisão vale',
    () async {
      await importarBase(ofxSintetico([pixAna]));
      // Mesmo Pix, mas o banco afirma identificador DIFERENTE: possível
      // duplicata — o core não decide, o usuário decide.
      seletor.proximo = ofxSintetico([
        (
          data: '2026-08-03',
          centavos: 45000,
          fitid: 'OUTRO',
          memo: 'PIX RECEBIDO ANA',
        ),
      ], nome: 'outro.ofx');
      final c = novo();
      await c.escolherArquivo();
      expect(c.indicesPossiveis, [0]);
      expect(c.pendentesDeDecisao, 1);
      expect(c.podeConfirmar, isFalse);
      await c.confirmar(); // sem decisão: não faz nada
      expect(c.estado, EstadoImportacao.previa);
      expect(await linhasEmTransacoes(), 1);

      c.decidir(0, manter: true);
      expect(c.podeConfirmar, isTrue);
      await c.confirmar();
      expect(c.resumo!.persistidas, 1);
      expect(await linhasEmTransacoes(), 2);
    },
  );

  test('possível duplicata descartada não grava', () async {
    await importarBase(ofxSintetico([pixAna]));
    seletor.proximo = ofxSintetico([
      (
        data: '2026-08-03',
        centavos: 45000,
        fitid: 'OUTRO',
        memo: 'PIX RECEBIDO ANA',
      ),
    ], nome: 'outro.ofx');
    final c = novo();
    await c.escolherArquivo();
    c.decidir(0, manter: false);
    await c.confirmar();
    expect(c.resumo!.descartadasPeloUsuario, 1);
    expect(await linhasEmTransacoes(), 1);
  });

  test('decidir índice que não é possível duplicata é erro', () async {
    seletor.proximo = ofxSintetico([pixAna]);
    final c = novo();
    await c.escolherArquivo();
    expect(() => c.decidir(0, manter: true), throwsArgumentError);
  });

  test(
    'duas contas de bancos diferentes: não adivinha, pede a conta',
    () async {
      await importarBase(ofxSintetico([pixAna], banco: '0260'));
      await importarBase(
        ofxSintetico([pixBruno], banco: '0001', nome: 'bb.ofx'),
      );
      seletor.proximo = ofxSintetico(
        [mercado],
        banco: '0341',
        nome: 'itau.ofx',
      );
      final c = novo();
      await c.escolherArquivo();
      expect(c.contaId, isNull);
      expect(c.novaConta, isFalse);
      expect(c.resultado, isNull);
      expect(c.podeConfirmar, isFalse);
      await c.selecionarConta(null);
      expect(c.podeConfirmar, isTrue);
    },
  );

  test('conta existente escolhida à mão: compara contra ela', () async {
    await importarBase(ofxSintetico([pixAna], banco: '0260'));
    await importarBase(ofxSintetico([pixBruno], banco: '0001', nome: 'bb.ofx'));
    seletor.proximo = ofxSintetico(
      [pixAna, mercado],
      banco: '0341',
      nome: 'x.ofx',
    );
    final c = novo();
    await c.escolherArquivo();
    final nubank = (await repo.listarContas()).firstWhere(
      (k) => k.bancoCodigo == '0260',
    );
    await c.selecionarConta(nubank.id);
    expect(c.resultado!.quantidadeSuprimida, 1);
  });

  test('CSV: pergunta o banco e lê com o perfil escolhido', () async {
    seletor.proximo = csvNubankSintetico();
    final c = novo();
    await c.escolherArquivo();
    expect(c.estado, EstadoImportacao.escolherBanco);
    expect(
      c.perfis.map((p) => p.banco),
      containsAll(['Nubank', 'Banco Inter', 'Banco do Brasil']),
    );
    await c.escolherPerfil(c.perfis.firstWhere((p) => p.banco == 'Nubank'));
    expect(c.estado, EstadoImportacao.previa);
    expect(c.apelidoNovaConta, 'Nubank');
    expect(
      [for (final i in c.resultado!.itens) i.transacao.valorCentavos],
      [45000, -8990],
    );
  });

  test('arquivo que não é extrato: falha visível, nada gravado', () async {
    seletor.proximo = ArquivoSelecionado(
      nome: 'foto.ofx',
      bytes: ofxSintetico([pixAna]).bytes.sublist(0, 10),
    );
    final c = novo();
    await c.escolherArquivo();
    // "OFXHEADER:" sem o documento <OFX>: o conteúdo diz OFX, o parser
    // recusa, e a tela mostra o motivo.
    expect(c.estado, EstadoImportacao.falha);
    expect(c.mensagem, contains('<OFX> ausente'));
    expect(await linhasEmTransacoes(), 0);
  });

  test('desistir do seletor não muda nada', () async {
    final c = novo();
    await c.escolherArquivo();
    expect(c.estado, EstadoImportacao.inicial);
  });

  test('arquivo sem lançamentos: prévia sem confirmar', () async {
    seletor.proximo = ofxSintetico(const []);
    final c = novo();
    await c.escolherArquivo();
    expect(c.estado, EstadoImportacao.previa);
    expect(c.extrato!.avisos, isNotEmpty);
    expect(c.podeConfirmar, isFalse);
  });

  test('nenhum double em valor: centavos inteiros do começo ao fim', () async {
    seletor.proximo = ofxSintetico([
      (data: '2026-08-06', centavos: 10001, fitid: 'F9', memo: 'PIX 100,01'),
    ]);
    final c = novo();
    await c.escolherArquivo();
    await c.confirmar();
    final v = await banco
        .customSelect(
          'SELECT valor_centavos AS v, typeof(valor_centavos) AS t FROM transacoes',
        )
        .getSingle();
    expect((v.read<int>('v'), v.read<String>('t')), (10001, 'integer'));
    expect(
      (await repo.transacoesJaImportadas(
        c.contaId ?? (await repo.listarContas()).single.id,
      )).single.valorCentavos,
      10001,
    );
  });

  group('sem transação parcial', () {
    test(
      'falha ao confirmar: a prévia volta, com o motivo, e nada foi gravado',
      () async {
        await importarBase(ofxSintetico([pixAna]));
        seletor.proximo = ofxSintetico([pixBruno], nome: 'b.ofx');
        final c = novo();
        await c.escolherArquivo();
        // Força a falha: a conta some antes da confirmação (FK).
        await banco.customStatement('PRAGMA foreign_keys = ON');
        await banco.customStatement('DELETE FROM transacoes');
        await banco.customStatement('DELETE FROM importacoes');
        await banco.customStatement('DELETE FROM contas_bancarias');
        await c.confirmar();
        expect(c.estado, EstadoImportacao.previa);
        expect(c.mensagem, contains('não foi gravada'));
        expect(await linhasEmTransacoes(), 0);
      },
    );
  });

  test('tipo do core: resultado é o da deduplicação real', () async {
    seletor.proximo = ofxSintetico([pixAna, pixAna]);
    final c = novo();
    await c.escolherArquivo();
    // O mesmo FITID duas vezes no arquivo: possível duplicata, não
    // supressão silenciosa.
    expect(
      c.resultado!.itens.map((i) => i.motivo),
      contains(MotivoDeduplicacao.identificadorRepetidoNoArquivo),
    );
  });
}
