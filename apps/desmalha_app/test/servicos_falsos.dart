import 'dart:math';

import 'package:desmalha_app/classificacao/repositorio_classificacao.dart';
import 'package:desmalha_app/despesas/repositorio_despesas.dart';
import 'package:desmalha_app/painel/repositorio_fechamento.dart';
import 'package:desmalha_app/relatorio/repositorio_relatorio.dart';
import 'package:desmalha_app/backup/chaves_backup.dart';
import 'package:desmalha_app/backup/controlador_backup.dart';
import 'package:desmalha_app/backup/estado_backup.dart';
import 'package:desmalha_app/backup/servico_backup.dart';
import 'package:desmalha_app/conta/porta_exclusao_conta.dart';
import 'package:desmalha_app/dados/banco.dart';
import 'package:desmalha_app/dados/chave_banco.dart';
import 'package:desmalha_app/dados/limpeza_local.dart';
import 'package:desmalha_app/dados/repositorio_importacao.dart';
import 'package:desmalha_app/importacao/arquivo_recebido.dart';
import 'package:desmalha_app/importacao/controlador_importacao.dart';
import 'package:desmalha_app/lembretes/controlador_lembretes.dart';
import 'package:desmalha_app/onboarding/controlador_onboarding.dart';
import 'package:desmalha_app/painel/repositorio_painel.dart';
import 'package:desmalha_app/onboarding/porta_aceite.dart';
import 'package:desmalha_app/onboarding/repositorio_onboarding.dart';
import 'package:desmalha_app/servicos_do_app.dart';
import 'package:desmalha_core/desmalha_core.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';

import 'backup/armazenamento_falso.dart';
import 'conta/porta_exclusao_falsa.dart';
import 'lembretes/notificacoes_falsas.dart';

/// Cofre do sistema em memória, com contagem de gravações.
class CofreEmMemoria implements CofreSeguro {
  final Map<String, String> valores = {};
  int gravacoes = 0;

  @override
  Future<String?> ler(String campo) async => valores[campo];

  @override
  Future<void> gravar(String campo, String valor) async {
    gravacoes++;
    valores[campo] = valor;
  }

  @override
  Future<void> apagar(String campo) async => valores.remove(campo);
}

/// Banco local de mentira para o backup: uma lista de documentos.
class FonteEmMemoria implements FonteDocumentosBackup {
  List<DocumentoBackup> documentos = const [
    DocumentoBackup('transacoes', {'id': 'tx-1', 'valor_centavos': 45000}),
  ];
  List<DocumentoBackup>? importados;

  @override
  Future<int> versaoDoSchemaLocal() async => 1;
  @override
  Future<List<DocumentoBackup>> exportar() async => documentos;
  @override
  Future<void> importar(List<DocumentoBackup> d) async => importados = d;
}

/// Controlador de backup com portas em memória.
ControladorBackup controladorBackupFalso({
  ChavesBackup? chaves,
  ArmazenamentoFalso? armazenamento,
  RepositorioEstadoBackup? estado,
  FonteDocumentosBackup? fonte,
  bool wifi = true,
  bool sessao = true,
  DateTime Function()? relogio,
}) {
  final c =
      chaves ?? ChavesBackup(cofre: CofreEmMemoria(), aleatorio: Random(1));
  final porta = armazenamento ?? ArmazenamentoFalso();
  final f = fonte ?? FonteEmMemoria();
  return ControladorBackup(
    servico: () => ServicoBackup(
      porta: porta,
      chaves: c,
      fonte: f,
      usuarioId: () => '00000000-0000-4000-8000-00000000000a',
      appVersao: '1.0.0',
      plataforma: 'android',
    ),
    chaves: c,
    estadoPersistido: estado ?? RepositorioEstadoBackupMemoria(),
    emWifi: () async => wifi,
    comSessao: () => sessao,
    relogio: relogio,
  );
}

/// [ServicosDoApp] para teste: portas falsas e cofre em memória.
ServicosDoApp servicosFalsos({
  PortaExclusaoConta? exclusao,
  ChavesBackup? chavesBackup,
  ControladorBackup? backup,
  ControladorLembretes? lembretes,
  ControladorOnboarding? onboarding,
  RepositorioImportacao? importacao,
  SeletorDeArquivo? seletorDeArquivo,
  Future<Catalogo> Function()? catalogo,
  RepositorioPainel? painel,
  RepositorioClassificacao? classificacao,
  RepositorioDespesas? despesas,
  RepositorioFechamento? fechamento,
  RepositorioRelatorio? relatorio,
  ValueNotifier<RecebimentoDeArquivo?>? arquivoRecebido,
}) {
  final chaves =
      chavesBackup ??
      ChavesBackup(cofre: CofreEmMemoria(), aleatorio: Random(1));
  return ServicosDoApp(
    exclusao: exclusao ?? PortaExclusaoFalsa(),
    chavesBackup: chaves,
    backup: backup ?? controladorBackupFalso(chaves: chaves),
    lembretes: lembretes ?? controladorLembretesFalso(),
    onboarding: onboarding ?? controladorOnboardingFalso(concluido: true),
    importacao: importacao ?? _importacaoPadrao,
    seletorDeArquivo: seletorDeArquivo ?? SeletorFalso(),
    catalogo: catalogo ?? () async => Catalogo.fromItens(const []),
    painel: painel ?? PainelFalso(),
    classificacao: classificacao ??
        RepositorioClassificacao(
          _importacaoPadraoBanco,
          catalogo: () async => Catalogo.fromItens(const []),
        ),
    despesas: despesas ??
        RepositorioDespesas(
          _importacaoPadraoBanco,
          catalogo: () async => Catalogo.fromItens(const []),
        ),
    fechamento: fechamento ?? RepositorioFechamento(_importacaoPadraoBanco),
    relatorio: relatorio ??
        RepositorioRelatorio(
          _importacaoPadraoBanco,
          painel: painel ?? PainelFalso(),
          fechamento: fechamento ?? RepositorioFechamento(_importacaoPadraoBanco),
        ),
    dadosAlterados: ValueNotifier(0),
    arquivoRecebido: arquivoRecebido ?? ValueNotifier(null),
  );
}

/// Agregados do painel em memória, sem banco.
class PainelFalso implements RepositorioPainel {
  PainelFalso([Map<String, DadosDoMes>? dados]) : dados = dados ?? {};

  final Map<String, DadosDoMes> dados;

  @override
  Future<Map<String, DadosDoMes>> dadosDoAno(int ano) async => {
    for (final e in dados.entries)
      if (e.key.startsWith('$ano-')) e.key: e.value,
  };
}

/// Um banco em memória só, criado na primeira vez (final de topo é
/// preguiçoso): um por chamada fazia o Drift avisar de instâncias múltiplas
/// e deixava bancos abertos. Quem precisa de banco próprio passa o seu.
final _importacaoPadraoBanco = BancoLocal(NativeDatabase.memory());
final _importacaoPadrao = RepositorioImportacao(
  _importacaoPadraoBanco,
);

/// Seletor de arquivo que entrega o que o teste mandar (ou desiste).
class SeletorFalso implements SeletorDeArquivo {
  SeletorFalso([this.proximo]);

  ArquivoSelecionado? proximo;

  @override
  Future<ArquivoSelecionado?> escolher() async => proximo;
}

/// Limpeza em memória: esvazia o repositório do onboarding (o perfil e os
/// aceites locais) e conta as chamadas.
class LimpezaFalsa implements LimpezaLocal {
  LimpezaFalsa(this.repositorio);

  final RepositorioOnboardingMemoria repositorio;
  int chamadas = 0;

  @override
  Future<void> apagarDadosDaConta() async {
    chamadas++;
    repositorio
      ..perfil = null
      ..codigoConfirmadoEm = null
      ..aceites.clear();
  }
}

/// Aceite em memória: registra o que o servidor teria gravado.
class AceiteFalso implements PortaAceite {
  AceiteFalso({this.falha});

  /// Se não nula, toda chamada lança esta falha.
  FalhaAceite? falha;
  final List<(String, String)> registrados = [];

  @override
  Future<void> registrar({
    required String documento,
    required String versao,
  }) async {
    if (falha != null) throw falha!;
    registrados.add((documento, versao));
  }
}

/// Onboarding com banco em memória. [concluido]: perfil já salvo e
/// onboarding feito — o padrão dos testes que só querem chegar ao app.
ControladorOnboarding controladorOnboardingFalso({
  bool concluido = false,
  RepositorioOnboarding? repositorio,
  AceiteFalso? aceite,
  Catalogo? catalogo,
  bool permiteSeguirSemTermos = true,
  LimpezaLocal? limpeza,
  String? Function()? usuarioId,
}) {
  final repo = repositorio ?? RepositorioOnboardingMemoria();
  if (concluido &&
      repo is RepositorioOnboardingMemoria &&
      repo.perfil == null) {
    repo.perfil = const PerfilDoApp(
      nome: 'Pessoa de Teste',
      cpf: '52998224725',
      onboardingCompleto: true,
      usuarioRemotoId: '00000000-0000-4000-8000-00000000000a',
    );
  }
  return ControladorOnboarding(
    // Repositório real (Drift) exige a limpeza real, passada pelo teste.
    limpeza: limpeza ?? LimpezaFalsa(repo as RepositorioOnboardingMemoria),
    repositorio: repo,
    aceite: aceite ?? AceiteFalso(),
    // Sem asset: o catálogo vazio (nenhum documento legal publicado — o
    // estado real de hoje) resolve sem IO, e o porteiro não prende o
    // pumpAndSettle.
    carregarCatalogo: () async => catalogo ?? Catalogo.fromItens(const []),
    usuarioId: usuarioId ?? () => '00000000-0000-4000-8000-00000000000a',
    permiteSeguirSemTermos: permiteSeguirSemTermos,
    relogio: () => DateTime.utc(2026, 9, 24, 13),
  );
}
