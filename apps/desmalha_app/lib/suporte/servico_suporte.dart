/// Envio do extrato bruto ao suporte — a EXCEÇÃO ÚNICA ao "nem nós
/// conseguimos ver seus dados" (decisão 11 do owner). Só acontece quando o
/// app não conseguiu ler o arquivo, com consentimento explícito na tela, e
/// o servidor apaga em 30 dias (expurgo existente).
///
/// O registro local (`envios_suporte`) guarda o que saiu e até quando fica
/// lá — o bucket é só de escrita, então é aqui que a pessoa consulta.
library;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../dados/banco.dart';
import '../importacao/controlador_importacao.dart' show ArquivoSelecionado;
import 'porta_suporte.dart';

class ServicoSuporte {
  ServicoSuporte(
    this._banco, {
    required this.porta,
    required this.usuarioId,
    int Function()? agoraEpochMs,
  }) : _agoraEpochMs =
            agoraEpochMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  final PortaSuporte porta;
  final BancoLocal _banco;

  /// Titular da sessão (`auth.uid()`), ou `null` sem sessão.
  final String? Function() usuarioId;
  final int Function() _agoraEpochMs;
  final _uuid = const Uuid();

  /// Nome seguro para o caminho: letras, dígitos, ponto, hífen e sublinhado.
  static String nomeSeguro(String nome) {
    final limpo = nome.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final curto = limpo.length > 80 ? limpo.substring(limpo.length - 80) : limpo;
    return curto.isEmpty ? 'extrato' : curto;
  }

  /// Envia o [arquivo] como veio, com o [motivo] (a falha de leitura) e o
  /// banco que a pessoa informou. Só depois do consentimento — quem chama
  /// garante isso. Lança [FalhaEnvioSuporte].
  Future<EnvioRegistrado> enviarExtrato(
    ArquivoSelecionado arquivo, {
    required String motivo,
    String? bancoInformado,
  }) async {
    final uid = usuarioId();
    if (uid == null) {
      throw const FalhaEnvioSuporte('Entre na sua conta para enviar.');
    }
    if (motivo.trim().isEmpty) {
      throw ArgumentError('o envio ao suporte precisa de um motivo');
    }
    final id = _uuid.v7();
    final consentimento = _agoraEpochMs();
    final path = '$uid/$id-${nomeSeguro(arquivo.nome)}';
    final banco = bancoInformado?.trim();
    final registrado = await porta.enviar(
      path: path,
      bytes: arquivo.bytes,
      motivo: motivo.trim(),
      bancoInformado: banco == null || banco.isEmpty ? null : banco,
    );
    await _banco.into(_banco.enviosSuporte).insert(
          EnviosSuporteCompanion.insert(
            id: id,
            arquivoNome: arquivo.nome,
            motivo: motivo.trim(),
            consentimentoEm: consentimento,
            enviadoEm: Value(_agoraEpochMs()),
            pathRemoto: Value(registrado.path),
            expiraEm: registrado.expiraEm.millisecondsSinceEpoch,
          ),
        );
    return registrado;
  }
}
