/// Extrato entregue por outro app ("Compartilhar → Desmalha" ou "Abrir
/// com"), lido no lado Android por `MainActivity.kt` e repassado aqui.
///
/// O app guarda o recebimento num [ValueNotifier] até alguém atrás do login
/// consumi-lo — a abertura a frio pode chegar antes do login ou do
/// onboarding; o arquivo espera e abre a importação quando o app estiver
/// pronto.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'controlador_importacao.dart';

/// Um arquivo recebido, ou o motivo de não ter sido lido.
class RecebimentoDeArquivo {
  const RecebimentoDeArquivo.arquivo(ArquivoSelecionado this.arquivo)
    : erro = null;
  const RecebimentoDeArquivo.falha(String this.erro) : arquivo = null;

  final ArquivoSelecionado? arquivo;

  /// Mensagem para a tela quando não deu para ler.
  final String? erro;
}

/// Traduz o que o canal nativo entrega. Público para teste.
RecebimentoDeArquivo? recebimentoDoCanal(Object? bruto) {
  if (bruto is! Map) return null;
  final nome = bruto['nome'] is String ? bruto['nome'] as String : 'arquivo';
  return switch (bruto['erro']) {
    'grande' => RecebimentoDeArquivo.falha(
      '"$nome" tem mais de 20 MB — não parece um extrato de banco.',
    ),
    'ilegivel' => RecebimentoDeArquivo.falha(
      'Não foi possível ler "$nome", que o outro app enviou. Tente '
      'compartilhar de novo ou escolha o arquivo pelo botão abaixo.',
    ),
    _ when bruto['bytes'] is Uint8List => RecebimentoDeArquivo.arquivo(
      ArquivoSelecionado(nome: nome, bytes: bruto['bytes'] as Uint8List),
    ),
    _ => null,
  };
}

/// Liga o canal `desmalha/arquivo_recebido` ao [recebido].
class ArquivoRecebidoDoSistema {
  ArquivoRecebidoDoSistema(this.recebido);

  final ValueNotifier<RecebimentoDeArquivo?> recebido;
  static const _canal = MethodChannel('desmalha/arquivo_recebido');

  /// Pega o que chegou na abertura a frio e passa a ouvir os próximos.
  Future<void> iniciar() async {
    _canal.setMethodCallHandler((chamada) async {
      if (chamada.method == 'arquivoRecebido') {
        final r = recebimentoDoCanal(chamada.arguments);
        if (r != null) recebido.value = r;
      }
    });
    try {
      final r = recebimentoDoCanal(
        await _canal.invokeMethod<Object?>('pegarPendente'),
      );
      if (r != null) recebido.value = r;
    } on MissingPluginException {
      // Plataforma sem o lado nativo (testes, iOS por ora): nada a receber.
    }
  }
}
