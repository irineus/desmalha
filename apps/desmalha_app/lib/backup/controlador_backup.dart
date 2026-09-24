/// O backup visto pela interface: estado, automático e "Fazer backup agora".
///
/// Liga a regra (`politica_backup.dart`), o serviço (`servico_backup.dart`)
/// e o estado local (`estado_backup.dart`). Toda falha vira `ultimaFalha` e
/// fica registrada — nenhuma é engolida em silêncio, nem no automático.
library;

import 'package:flutter/foundation.dart';

import 'chaves_backup.dart';
import 'estado_backup.dart';
import 'politica_backup.dart';
import 'servico_backup.dart';

class ControladorBackup extends ChangeNotifier {
  ControladorBackup({
    required this.servico,
    required this.chaves,
    required this.estadoPersistido,
    required this.emWifi,
    required this.comSessao,
    DateTime Function()? relogio,
  }) : _relogio = relogio ?? DateTime.now;

  final ServicoBackup Function() servico;
  final ChavesBackup chaves;
  final RepositorioEstadoBackup estadoPersistido;
  final Future<bool> Function() emWifi;
  final bool Function() comSessao;
  final DateTime Function() _relogio;

  EstadoBackup estado = EstadoBackup.vazio;
  bool codigoConfirmado = false;
  bool executando = false;
  String? ultimaFalha;
  String? ultimoAviso;
  bool _carregado = false;

  bool get carregado => _carregado;

  bool get desatualizado => backupDesatualizado(
    agora: _relogio(),
    ultimoSucessoEm: estado.ultimoSucessoEm,
  );

  Future<void> recarregar() async {
    estado = await estadoPersistido.ler();
    codigoConfirmado = await chaves.codigoConfirmado();
    ultimaFalha = estado.resultado == 'falha' ? estado.erroDetalhe : null;
    _carregado = true;
    notifyListeners();
  }

  /// Ao abrir e ao voltar ao app. Devolve a decisão tomada (para teste e log).
  Future<DecisaoBackup> automatico() async {
    await recarregar();
    if (executando) return const DecisaoBackup.nao(MotivoSemBackup.jaFezHoje);
    final decisao = decidirBackupAutomatico(
      agora: _relogio(),
      ultimoSucessoEm: estado.ultimoSucessoEm,
      comSessao: comSessao(),
      codigoConfirmado: codigoConfirmado,
      emWifi: await emWifi(),
    );
    if (decisao.executar) {
      await _executar(pularSeConteudoFor: estado.ultimoHashConteudo);
    }
    return decisao;
  }

  /// "Fazer backup agora": pedido explícito — ignora Wi-Fi e o 1×/dia, e
  /// faz mesmo sem mudança (a pessoa pediu).
  Future<void> fazerAgora() => _executar();

  Future<void> _executar({String? pularSeConteudoFor}) async {
    executando = true;
    ultimaFalha = null;
    ultimoAviso = null;
    notifyListeners();
    try {
      final r = await servico().fazerBackup(
        pularSeConteudoFor: pularSeConteudoFor,
      );
      if (r == null) {
        ultimoAviso = 'Nada mudou desde o último backup.';
      } else {
        await estadoPersistido.registrarSucesso(
          seq: r.seq,
          hashConteudo: r.hashConteudo,
          em: _relogio(),
          tamanhoBytes: r.tamanhoBytes,
          formatoVersao: 1,
        );
        ultimoAviso = 'Backup feito.';
      }
    } on FalhaBackup catch (e) {
      await estadoPersistido.registrarFalha(e.mensagem);
      ultimaFalha = e.mensagem;
    } on Exception catch (e) {
      final mensagem = 'O backup falhou: $e';
      await estadoPersistido.registrarFalha(mensagem);
      ultimaFalha = mensagem;
    } finally {
      executando = false;
      estado = await estadoPersistido.ler();
      notifyListeners();
    }
  }
}
