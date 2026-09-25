/// Estado do onboarding depois do login: aceite dos documentos legais,
/// dados do perfil (nome e CPF), código de recuperação e conclusão.
///
/// Documento legal sem versão publicada no catálogo NÃO vira aceite
/// inventado: o servidor recusaria (allowlist `documentos_legais`) e o
/// registro não provaria nada. Enquanto faltar publicação, o build de
/// desenvolvimento segue com a pendência escrita na tela; o build de
/// release fica parado nela ([permiteSeguirSemTermos]) — usar o app sem
/// aceite dos Termos não é uma leitura jurídica que o app escolhe sozinho.
library;

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/foundation.dart';

import '../dados/limpeza_local.dart';
import 'porta_aceite.dart';
import 'repositorio_onboarding.dart';

/// Nomes dos documentos para a tela.
const Map<String, String> nomesDocumentosLegais = {
  TipoDocumentoLegal.termosUso: 'Termos de uso',
  TipoDocumentoLegal.politicaPrivacidade: 'Política de privacidade',
};

/// Ordem fixa em que os documentos aparecem.
const List<String> ordemDocumentosLegais = [
  TipoDocumentoLegal.termosUso,
  TipoDocumentoLegal.politicaPrivacidade,
];

class ControladorOnboarding extends ChangeNotifier {
  ControladorOnboarding({
    required this.repositorio,
    required this.aceite,
    required this.carregarCatalogo,
    required this.usuarioId,
    required this.limpeza,
    this.permiteSeguirSemTermos = kDebugMode,
    DateTime Function()? relogio,
  }) : _relogio = relogio ?? DateTime.now;

  final RepositorioOnboarding repositorio;
  final PortaAceite aceite;
  final Future<Catalogo> Function() carregarCatalogo;
  final String? Function() usuarioId;

  /// Apaga do aparelho os dados de outra conta.
  final LimpezaLocal limpeza;

  /// `true` só em build de desenvolvimento: sem documento publicado, o app
  /// segue com a pendência visível. Em release, para.
  final bool permiteSeguirSemTermos;
  final DateTime Function() _relogio;

  bool _carregado = false;
  String? _erroAoCarregar;
  PerfilDoApp? _perfil;
  List<DocumentoLegal> _vigentes = const [];
  List<String> _naoPublicados = const [];
  Set<(String, String)> _aceitos = const {};

  bool get carregado => _carregado;
  String? get erroAoCarregar => _erroAoCarregar;
  PerfilDoApp? get perfil => _perfil;

  bool get precisaOnboarding => !(_perfil?.onboardingCompleto ?? false);

  /// O aparelho tem dados criados por OUTRA conta (decisão do owner,
  /// 24/09/2026: os dados locais pertencem à conta que os criou). Perfil sem
  /// dono registrado também conta como de outra conta: não dá para provar
  /// que é desta, e herdar em silêncio mostraria dado alheio.
  bool get dadosDeOutraConta {
    final perfil = _perfil;
    final sessao = usuarioId();
    return perfil != null && sessao != null && perfil.usuarioRemotoId != sessao;
  }

  /// Apaga os dados locais da outra conta e recomeça: o onboarding volta
  /// para a conta desta sessão.
  Future<void> apagarDadosLocais() async {
    await limpeza.apagarDadosDaConta();
    await carregar();
  }

  /// Documentos publicados cuja versão vigente ainda não foi aceita.
  List<DocumentoLegal> get aceitesPendentes => [
    for (final d in _vigentes)
      if (!_aceitos.contains((d.documento, d.versao))) d,
  ];

  /// Documentos sem nenhuma versão publicada no catálogo.
  List<String> get naoPublicados => _naoPublicados;

  /// Sem publicação e em release: o app não segue.
  bool get bloqueadoSemPublicacao =>
      _naoPublicados.isNotEmpty && !permiteSeguirSemTermos;

  /// Depois do onboarding, uma versão nova publicada volta a pedir aceite.
  bool get precisaAceite => aceitesPendentes.isNotEmpty;

  Future<void> carregar() async {
    try {
      final catalogo = await carregarCatalogo();
      _vigentes = [
        for (final tipo in ordemDocumentosLegais)
          ?catalogo.documentoLegalVigente(tipo),
      ];
      _naoPublicados = [
        for (final tipo in ordemDocumentosLegais)
          if (catalogo.documentoLegalVigente(tipo) == null) tipo,
      ];
      _aceitos = await repositorio.aceitesSincronizados();
      _perfil = await repositorio.lerPerfil();
      _erroAoCarregar = null;
    } on Exception catch (e) {
      _erroAoCarregar = 'Não foi possível abrir seus dados locais: $e';
    } finally {
      _carregado = true;
      notifyListeners();
    }
  }

  /// Registra no servidor o aceite de cada pendente e, só depois de cada
  /// confirmação, o espelho local. Lança [FalhaAceite].
  Future<void> aceitarPendentes() async {
    for (final d in aceitesPendentes) {
      await aceite.registrar(documento: d.documento, versao: d.versao);
      await repositorio.registrarAceiteLocal(
        documento: d.documento,
        versao: d.versao,
        em: _relogio(),
      );
    }
    _aceitos = await repositorio.aceitesSincronizados();
    notifyListeners();
  }

  /// Valida e salva nome e CPF. Devolve a mensagem de erro, ou `null`.
  Future<String?> salvarDados({
    required String nome,
    required String cpf,
  }) async {
    final nomeLimpo = nome.trim().replaceAll(RegExp(r'\s+'), ' ');
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
    if (nomeLimpo.length < 2) return 'Informe seu nome.';
    if (!cpfValido(cpfLimpo)) {
      return 'CPF inválido. Confira os 11 dígitos.';
    }
    await repositorio.salvarDados(
      nome: nomeLimpo,
      cpf: cpfLimpo,
      usuarioRemotoId: usuarioId(),
      em: _relogio(),
    );
    _perfil = await repositorio.lerPerfil();
    notifyListeners();
    return null;
  }

  Future<void> registrarCodigoConfirmado() =>
      repositorio.registrarCodigoConfirmado(_relogio());

  Future<void> concluir() async {
    await repositorio.concluirOnboarding(_relogio());
    _perfil = await repositorio.lerPerfil();
    notifyListeners();
  }
}
