/// Importação de extrato (wireframe M2): arquivo → leitura no aparelho →
/// prévia com a deduplicação → decisão por possível duplicata → confirmação.
///
/// Nada entra em `transacoes` antes da confirmação. A regra de
/// deduplicação é a do `desmalha_core` (`conciliarImportacao`) e a
/// persistência, a do [RepositorioImportacao]: suprimida nunca vira linha,
/// possível duplicata só vira linha com decisão explícita do usuário.
library;

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/foundation.dart';

import '../dados/banco.dart';
import '../dados/repositorio_importacao.dart';

/// O arquivo que o usuário escolheu.
class ArquivoSelecionado {
  const ArquivoSelecionado({required this.nome, required this.bytes});

  final String nome;
  final Uint8List bytes;
}

/// Porta do seletor de arquivos do sistema.
abstract interface class SeletorDeArquivo {
  /// `null` quando o usuário desiste.
  Future<ArquivoSelecionado?> escolher();
}

enum EstadoImportacao {
  inicial,
  lendo,

  /// CSV: o formato não diz o banco — o usuário escolhe o perfil.
  escolherBanco,

  /// O mesmo arquivo (mesmo SHA-256) já foi importado.
  jaImportado,
  previa,
  confirmando,
  concluida,
  falha,
}

class ControladorImportacao extends ChangeNotifier {
  ControladorImportacao({
    required this.repositorio,
    required this.seletor,
    required this.carregarCatalogo,
  });

  final RepositorioImportacao repositorio;
  final SeletorDeArquivo seletor;
  final Future<Catalogo> Function() carregarCatalogo;

  EstadoImportacao _estado = EstadoImportacao.inicial;
  ArquivoSelecionado? _arquivo;
  String? _hash;
  List<PerfilCsv> _perfis = const [];
  PerfilCsv? _perfil;
  ExtratoImportado? _extrato;
  List<ContaBancaria> _contas = const [];
  String? _contaId;
  bool _novaConta = false;
  String _apelidoNovaConta = '';
  ResultadoDeduplicacao? _resultado;
  final Map<int, bool> _decisoes = {};
  ResumoConfirmacao? _resumo;
  String? _mensagem;
  DateTime? _jaImportadoEm;

  EstadoImportacao get estado => _estado;
  ArquivoSelecionado? get arquivo => _arquivo;
  List<PerfilCsv> get perfis => _perfis;
  ExtratoImportado? get extrato => _extrato;
  List<ContaBancaria> get contas => _contas;
  String? get contaId => _contaId;
  bool get novaConta => _novaConta;
  String get apelidoNovaConta => _apelidoNovaConta;
  ResultadoDeduplicacao? get resultado => _resultado;
  Map<int, bool> get decisoes => Map.unmodifiable(_decisoes);
  ResumoConfirmacao? get resumo => _resumo;

  /// Texto da falha (estado [EstadoImportacao.falha]) ou do erro ao
  /// confirmar (a prévia continua na tela).
  String? get mensagem => _mensagem;
  DateTime? get jaImportadoEm => _jaImportadoEm;

  /// Índices (em `resultado.itens`) das possíveis duplicatas.
  List<int> get indicesPossiveis => [
    for (var i = 0; i < (_resultado?.itens.length ?? 0); i++)
      if (_resultado!.itens[i].situacao ==
          SituacaoDeduplicacao.possivelDuplicata)
        i,
  ];

  int get pendentesDeDecisao =>
      indicesPossiveis.where((i) => !_decisoes.containsKey(i)).length;

  bool get contaDefinida =>
      _novaConta ? _apelidoNovaConta.trim().isNotEmpty : _contaId != null;

  /// Confirmar exige conta definida, lançamentos no arquivo e TODAS as
  /// possíveis duplicatas decididas — sem padrão silencioso.
  bool get podeConfirmar =>
      _estado == EstadoImportacao.previa &&
      _resultado != null &&
      _resultado!.itens.isNotEmpty &&
      contaDefinida &&
      pendentesDeDecisao == 0;

  Future<void> escolherArquivo() async {
    final arquivo = await seletor.escolher();
    if (arquivo == null) return;
    _reiniciar();
    _arquivo = arquivo;
    _mudar(EstadoImportacao.lendo);
    try {
      _hash = await sha256Hex(arquivo.bytes);
      final anterior = await repositorio.importacaoConfirmadaDoArquivo(_hash!);
      if (anterior != null) {
        _jaImportadoEm = DateTime.fromMillisecondsSinceEpoch(anterior.criadoEm);
        _mudar(EstadoImportacao.jaImportado);
        return;
      }
      if (arquivo.bytes.isEmpty) {
        throw const ExtratoInvalidoException('arquivo vazio');
      }
      if (detectarFormatoExtrato(arquivo.bytes) == FormatoExtrato.csv) {
        _perfis = (await carregarCatalogo()).perfisCsv;
        _mudar(EstadoImportacao.escolherBanco);
        return;
      }
      await _ler();
    } on ExtratoInvalidoException catch (e) {
      _falhar('Não foi possível ler este arquivo: ${e.mensagem}.');
    } on Exception catch (e) {
      _falhar('Não foi possível ler este arquivo: $e');
    }
  }

  Future<void> escolherPerfil(PerfilCsv perfil) async {
    _perfil = perfil;
    _mudar(EstadoImportacao.lendo);
    try {
      await _ler();
    } on ExtratoInvalidoException catch (e) {
      _falhar(
        'O arquivo não parece um extrato CSV do ${perfil.banco}: '
        '${e.mensagem}.',
      );
    } on Exception catch (e) {
      _falhar('Não foi possível ler este arquivo: $e');
    }
  }

  Future<void> _ler() async {
    final extrato = lerArquivoDeExtrato(_arquivo!.bytes, perfil: _perfil);
    _extrato = extrato;
    _contas = await repositorio.listarContas();
    _apelidoNovaConta = _sugestaoDeApelido(extrato);
    final codigo = _codigoDoBanco(extrato);
    final mesmoBanco = [
      for (final c in _contas)
        if (codigo != null && c.bancoCodigo == codigo) c,
    ];
    // Só pré-seleciona sem ambiguidade: conta do mesmo banco, única; ou a
    // única conta que existe. Escolher errado desligaria a deduplicação
    // (ela é por conta) e duplicaria a receita.
    if (mesmoBanco.length == 1) {
      _contaId = mesmoBanco.single.id;
    } else if (_contas.isEmpty) {
      _novaConta = true;
    }
    await _conciliar();
    _mudar(EstadoImportacao.previa);
  }

  /// `null` = nova conta.
  Future<void> selecionarConta(String? contaId) async {
    _novaConta = contaId == null;
    _contaId = contaId;
    await _conciliar();
    notifyListeners();
  }

  void mudarApelidoNovaConta(String apelido) {
    _apelidoNovaConta = apelido;
    notifyListeners();
  }

  void decidir(int indice, {required bool manter}) {
    if (!indicesPossiveis.contains(indice)) {
      throw ArgumentError.value(indice, 'indice', 'não é possível duplicata');
    }
    _decisoes[indice] = manter;
    notifyListeners();
  }

  Future<void> confirmar() async {
    if (!podeConfirmar) return;
    _mensagem = null;
    _mudar(EstadoImportacao.confirmando);
    try {
      final extrato = _extrato!;
      final contaId = _novaConta
          ? await repositorio.criarConta(
              apelido: _apelidoNovaConta.trim(),
              bancoCodigo: _codigoDoBanco(extrato),
            )
          : _contaId!;
      final periodo = periodoDoExtrato(extrato);
      final importacaoId = await repositorio.registrarPrevia(
        contaId: contaId,
        formato: extrato.formato,
        nomeArquivo: _arquivo!.nome,
        hashArquivo: _hash!,
        parserCodigo: _perfil?.id,
        periodoInicio: periodo?.$1,
        periodoFim: periodo?.$2,
        totalLinhas: extrato.transacoes.length,
      );
      _resumo = await repositorio.confirmarImportacao(
        importacaoId: importacaoId,
        resultado: _resultado!,
        decisoesPossiveis: Map.of(_decisoes),
      );
      _mudar(EstadoImportacao.concluida);
    } on Exception catch (e) {
      // A confirmação é uma transação: nada foi gravado. A prévia volta.
      _mensagem = 'A importação não foi gravada: $e';
      _mudar(EstadoImportacao.previa);
    }
  }

  void recomecar() {
    _reiniciar();
    _mudar(EstadoImportacao.inicial);
  }

  Future<void> _conciliar() async {
    _decisoes.clear();
    final novas = _extrato!.transacoes;
    if (_novaConta) {
      _resultado = conciliarImportacao(jaImportadas: const [], novas: novas);
    } else if (_contaId != null) {
      _resultado = await repositorio.conciliarArquivo(
        contaId: _contaId!,
        novas: novas,
      );
    } else {
      _resultado = null; // falta escolher a conta
    }
  }

  String? _codigoDoBanco(ExtratoImportado extrato) =>
      _perfil?.id ?? extrato.banco;

  String _sugestaoDeApelido(ExtratoImportado extrato) {
    if (_perfil != null) return _perfil!.banco;
    final banco = extrato.banco;
    final conta = extrato.conta?.replaceAll(RegExp(r'\D'), '');
    final finalConta = conta == null || conta.length < 4
        ? ''
        : ' final ${conta.substring(conta.length - 4)}';
    return '${banco ?? 'Conta'}$finalConta';
  }

  void _reiniciar() {
    _arquivo = null;
    _hash = null;
    _perfis = const [];
    _perfil = null;
    _extrato = null;
    _contas = const [];
    _contaId = null;
    _novaConta = false;
    _apelidoNovaConta = '';
    _resultado = null;
    _decisoes.clear();
    _resumo = null;
    _mensagem = null;
    _jaImportadoEm = null;
  }

  void _falhar(String mensagem) {
    _mensagem = mensagem;
    _mudar(EstadoImportacao.falha);
  }

  void _mudar(EstadoImportacao estado) {
    _estado = estado;
    notifyListeners();
  }
}
