/// Componentes do sistema visual que o Material não traz prontos.
///
/// Cada um carrega uma regra de aplicação do sistema visual v0.1, e é por
/// isso que existe em vez de um `Container` estilizado em cada tela:
/// - [ValorEmReais] — todo valor em R$ é monoespaçado, com dígitos
///   tabulares e alinhado à direita; recebe CENTAVOS (`int`), nunca `double`.
/// - [Selo] — estado com TEXTO, nunca só cor (daltonismo: sálvia × azul se
///   aproximam em deuteranopia).
/// - [BannerObrigacao] — o único lugar do app que pinta de azul-obrigação;
///   nunca bloqueia o cálculo, diz o que falta e por quê.
/// - [EstadoVazio] — vazio é convite, não lamento: nomeia o ganho e traz a
///   ação.
library;

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/material.dart';

import 'tipografia.dart';
import 'tokens.dart';

/// Um valor em reais, na voz fiscal.
class ValorEmReais extends StatelessWidget {
  const ValorEmReais(
    this.centavos, {
    super.key,
    this.estilo,
    this.semSimbolo = false,
  });

  final int centavos;

  /// Padrão: [TipografiaFiscal.valorLinha].
  final TextStyle? estilo;

  /// Linhas de apuração mostram só o número (`1.757,86`); o total leva R$.
  final bool semSimbolo;

  @override
  Widget build(BuildContext context) {
    final texto = centavosParaExibicao(centavos);
    return Text(
      semSimbolo ? texto.replaceFirst(r'R$ ', '') : texto,
      textAlign: TextAlign.right,
      style: estilo ?? TipografiaFiscal.de(context).valorLinha,
    );
  }
}

/// Os tipos de selo do sistema visual.
enum TipoSelo {
  /// Pendência fiscal (a classificar, falta CPF). Azul-obrigação.
  obrigacao,

  /// Resolvido (pronto, DARF pago). Sálvia.
  ok,

  /// Informativo (pessoal). Cinza.
  neutro,

  /// Falhou de verdade (vencido). Único vermelho.
  falha,
}

/// Selo de estado — pílula com texto em Plex Mono.
class Selo extends StatelessWidget {
  const Selo(this.texto, {super.key, required this.tipo});

  final String texto;
  final TipoSelo tipo;

  @override
  Widget build(BuildContext context) {
    final (fundo, cor, borda) = switch (tipo) {
      TipoSelo.obrigacao => (
        CoresDesmalha.obrigacaoFundo,
        CoresDesmalha.obrigacao,
        CoresDesmalha.obrigacaoBorda,
      ),
      TipoSelo.ok => (
        CoresDesmalha.salviaClara,
        CoresDesmalha.salviaEscura,
        CoresDesmalha.salviaClara,
      ),
      TipoSelo.neutro => (
        CoresDesmalha.neutroFundo,
        CoresDesmalha.tintaFraca,
        CoresDesmalha.neutroFundo,
      ),
      TipoSelo.falha => (
        CoresDesmalha.falhaFundo,
        CoresDesmalha.falha,
        CoresDesmalha.falhaFundo,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: fundo,
        border: Border.all(color: borda),
        borderRadius: BorderRadius.circular(RaiosDesmalha.pilula),
      ),
      child: Text(
        texto,
        style: TipografiaFiscal.de(context).dado.copyWith(
          fontSize: 11.5,
          letterSpacing: 0.04 * 11.5,
          color: cor,
        ),
      ),
    );
  }
}

/// Banner de obrigação fiscal: o que falta, por que é exigido, o que já está
/// resolvido. Nunca bloqueia o cálculo.
class BannerObrigacao extends StatelessWidget {
  const BannerObrigacao({super.key, required this.titulo, required this.texto});

  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final corpo = Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 14);
    return Container(
      padding: const EdgeInsets.all(EspacosDesmalha.s4),
      decoration: const BoxDecoration(
        color: CoresDesmalha.obrigacaoFundo,
        borderRadius: BorderRadius.all(Radius.circular(RaiosDesmalha.medio)),
        border: Border(
          left: BorderSide(color: CoresDesmalha.obrigacao, width: 3),
        ),
      ),
      child: Text.rich(
        TextSpan(
          style: corpo,
          children: [
            TextSpan(
              text: '$titulo ',
              style: const TextStyle(
                color: CoresDesmalha.obrigacao,
                fontWeight: FontWeight.w700,
                fontVariations: [FontVariation('wght', 700)],
              ),
            ),
            TextSpan(text: texto),
          ],
        ),
      ),
    );
  }
}

/// Estado vazio: mensagem que nomeia o ganho concreto + a ação.
class EstadoVazio extends StatelessWidget {
  const EstadoVazio({
    super.key,
    required this.mensagem,
    this.rotuloAcao,
    this.aoAgir,
  }) : assert(
         (rotuloAcao == null) == (aoAgir == null),
         'ação vem com rótulo e callback juntos',
       );

  final String mensagem;
  final String? rotuloAcao;
  final VoidCallback? aoAgir;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontSize: 14,
      color: CoresDesmalha.tintaFraca,
    );
    return CustomPaint(
      painter: const _BordaTracejada(),
      child: Padding(
        padding: const EdgeInsets.all(EspacosDesmalha.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mensagem, style: estilo, textAlign: TextAlign.center),
            if (rotuloAcao != null) ...[
              const SizedBox(height: EspacosDesmalha.s3),
              OutlinedButton(onPressed: aoAgir, child: Text(rotuloAcao!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// `border: 1px dashed var(--linha)` com `--r-md`.
class _BordaTracejada extends CustomPainter {
  const _BordaTracejada();

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = CoresDesmalha.linha
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final caminho = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(RaiosDesmalha.medio),
        ),
      );
    for (final metrica in caminho.computeMetrics()) {
      var d = 0.0;
      while (d < metrica.length) {
        canvas.drawPath(metrica.extractPath(d, d + 5), pincel);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
