import 'dart:convert';

import 'package:desmalha_core/catalogo_arquivos.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:test/test.dart';

/// As únicas chaves que podem levar texto: identificadores técnicos e
/// estados. Qualquer outra folha de texto no resumo é dado que não devia
/// sair do aparelho (decisão 11 do owner).
const _textoPermitido = {
  'competencia',
  'versoes.motor',
  'versoes.app',
  'versoes.catalogo',
  'estadoDoMes',
  'apuracao.tabelaIrpf',
  'apuracao.cenarioVencedor',
  'apuracao.statusDarf',
};

void _conferirFolhas(Object? valor, String caminho) {
  switch (valor) {
    case final Map<String, Object?> m:
      for (final e in m.entries) {
        _conferirFolhas(e.value, caminho.isEmpty ? e.key : '$caminho.${e.key}');
      }
    case final List<Object?> l:
      for (final v in l) {
        _conferirFolhas(v, caminho);
      }
    case String():
      expect(_textoPermitido, contains(caminho),
          reason: 'texto em "$caminho" — só identificadores técnicos saem');
    case int() || bool():
      break;
    default:
      fail('folha de tipo ${valor.runtimeType} em "$caminho" (nada de double)');
  }
}

void main() {
  final catalogo = Catalogo.fromItens(itensDoCatalogoNoRepositorio('.'));
  final painel = montarPainelMensal(
    competencia: '2026-08',
    dadosDoAno: const {
      '2026-08': DadosDoMes(
        receitaTributavelCentavos: 600000,
        lancamentosClassificados: 3,
        recebimentosAClassificar: 2,
      ),
    },
    catalogo: catalogo,
  );

  ResumoDiagnostico resumo(PainelMensal p) => montarResumoDiagnostico(
        competencia: '2026-08',
        painel: p,
        contagemPorClassificacao: const {
          ClassificacaoLancamento.rendimentoPf: 2,
          ClassificacaoLancamento.pessoal: 1,
        },
        pendencias: const PendenciasDoMes(
          recebimentosAClassificar: 2,
          documentosPendentes: 1,
          inssRespondido: false,
        ),
        mesFechado: false,
        versaoApp: '1.0.0+1',
        versaoCatalogo: '2026-01',
      );

  test('mês apurado: a apuração em números, versões e contagens', () {
    final r = resumo(painel);
    final json = r.toJson();
    expect(json['competencia'], '2026-08');
    expect((json['versoes']! as Map)['motor'], versaoDoMotor);
    expect(json['estadoDoMes'], 'apurado');
    final apuracao = json['apuracao']! as Map<String, Object?>;
    expect(apuracao['impostoDevidoCentavos'], 39454);
    expect(apuracao['receitaBrutaCentavos'], 600000);
    expect((json['lancamentosPorClassificacao']! as Map)['rendimentoPf'], 2);
    expect((json['lancamentosPorClassificacao']! as Map)['recebidoPj'], 0);
    expect((json['pendencias']! as Map)['documentosPendentes'], 1);
    expect(jsonDecode(r.texto), json, reason: 'o texto é o mesmo JSON');
  });

  test('nenhuma folha de texto fora dos identificadores técnicos, nenhum '
      'double', () {
    _conferirFolhas(resumo(painel).toJson(), '');
    _conferirFolhas(resumo(const PainelSemDados('2026-08')).toJson(), '');
  });

  test('mês sem apuração não leva o bloco da apuração', () {
    final json = resumo(const PainelAClassificar('2026-08', 4)).toJson();
    expect(json['estadoDoMes'], 'aClassificar');
    expect(json.containsKey('apuracao'), isFalse);
  });

  test('competência fora do formato é recusada', () {
    expect(
      () => montarResumoDiagnostico(
        competencia: 'agosto',
        painel: const PainelSemDados('2026-08'),
        contagemPorClassificacao: const {},
        pendencias: const PendenciasDoMes(
          recebimentosAClassificar: 0,
          documentosPendentes: 0,
          inssRespondido: false,
        ),
        mesFechado: false,
        versaoApp: '1.0.0',
      ),
      throwsArgumentError,
    );
  });
}
