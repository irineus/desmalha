/// As três vozes tipográficas do Desmalha.
///
/// Cada família tem um trabalho e não faz o do vizinho (sistema visual v0.1):
/// - **Fraunces** — voz humana: títulos e marca.
/// - **Karla** — voz da interface: tudo que se lê corrido.
/// - **IBM Plex Mono** — voz fiscal: todo número, data, CPF e código.
///
/// Um valor em R$ nunca aparece em Karla: a mudança de família é o sinal de
/// "isto é conferível". Por isso os estilos fiscais ficam num
/// [ThemeExtension] próprio ([TipografiaFiscal]) em vez de disputar papel no
/// `TextTheme` do Material.
///
/// Fraunces e Karla são fontes VARIÁVEIS (um arquivo cada). O peso é pedido
/// por `fontWeight` E pelo eixo `wght` em `fontVariations`: o primeiro
/// escolhe o arquivo, o segundo é o que de fato move o eixo da fonte
/// variável — sem ele, o texto sai no peso padrão do arquivo.
library;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// Nomes das famílias como declarados no `pubspec.yaml`.
abstract final class FamiliasDesmalha {
  static const fraunces = 'Fraunces';
  static const karla = 'Karla';
  static const plexMono = 'IBMPlexMono';
}

/// Fraunces 600. Dois regimes, como no documento de design:
/// - [cartaz] (`.disp`): corte óptico fixo em 96 (144 na marca) e -0,02em —
///   o título grande de abertura;
/// - título de tela (`h4` dos telefones): corte óptico = tamanho da fonte,
///   que é o `font-optical-sizing: auto` do navegador, e -0,01em. Com 96 num
///   título de 20px o desenho fica de cartaz, fino e apertado demais.
TextStyle _fraunces(double tamanho, {double? cartaz}) => TextStyle(
  fontFamily: FamiliasDesmalha.fraunces,
  fontSize: tamanho,
  fontWeight: FontWeight.w600,
  fontVariations: [
    const FontVariation('wght', 600),
    FontVariation('opsz', cartaz ?? tamanho),
  ],
  letterSpacing: (cartaz == null ? -0.01 : -0.02) * tamanho,
  height: 1.1,
  color: CoresDesmalha.tinta,
);

TextStyle _karla(double tamanho, FontWeight peso, {Color? cor}) => TextStyle(
  fontFamily: FamiliasDesmalha.karla,
  fontSize: tamanho,
  fontWeight: peso,
  fontVariations: [FontVariation('wght', peso.value.toDouble())],
  height: 1.55,
  color: cor ?? CoresDesmalha.tinta,
);

TextStyle _mono(double tamanho, FontWeight peso, {Color? cor}) => TextStyle(
  fontFamily: FamiliasDesmalha.plexMono,
  fontSize: tamanho,
  fontWeight: peso,
  // Dígitos tabulares: colunas de número precisam bater na vertical.
  fontFeatures: const [FontFeature.tabularFigures()],
  color: cor ?? CoresDesmalha.tinta,
);

/// O `TextTheme` do Material, nas vozes humana e de interface.
TextTheme textThemeDesmalha() => TextTheme(
  displayLarge: _fraunces(64, cartaz: 144),
  displayMedium: _fraunces(40, cartaz: 96),
  displaySmall: _fraunces(34, cartaz: 96),
  headlineLarge: _fraunces(32),
  headlineMedium: _fraunces(28),
  headlineSmall: _fraunces(20),
  titleLarge: _karla(17, FontWeight.w600),
  titleMedium: _karla(16, FontWeight.w600),
  titleSmall: _karla(14, FontWeight.w600),
  bodyLarge: _karla(16, FontWeight.w400),
  bodyMedium: _karla(15, FontWeight.w400),
  bodySmall: _karla(12.5, FontWeight.w400, cor: CoresDesmalha.tintaFraca),
  // Rótulo de botão: Karla 600 15, sentence case.
  labelLarge: _karla(15, FontWeight.w600),
  // Rótulos pequenos de interface (a barra de abas usa a voz fiscal).
  labelMedium: _karla(13, FontWeight.w600, cor: CoresDesmalha.tintaFraca),
  labelSmall: _mono(10.5, FontWeight.w500, cor: CoresDesmalha.tintaFraca),
);

/// A voz fiscal: todo valor, data, CPF e código.
@immutable
class TipografiaFiscal extends ThemeExtension<TipografiaFiscal> {
  const TipografiaFiscal({
    required this.valorDestaque,
    required this.valor,
    required this.valorLinha,
    required this.dado,
    required this.rotulo,
  });

  /// Plex Mono 600, 34 — o valor que é a coisa maior da tela (M1, D1).
  final TextStyle valorDestaque;

  /// Plex Mono 600, 26 — total da linha de apuração.
  final TextStyle valor;

  /// Plex Mono 400, 14.5 — valor numa linha de lista ou de apuração.
  final TextStyle valorLinha;

  /// Plex Mono 400, 12 — datas, CPF, código de receita.
  final TextStyle dado;

  /// Plex Mono 500, 11 — rótulo de competência, legenda de bloco.
  final TextStyle rotulo;

  static final padrao = TipografiaFiscal(
    valorDestaque: _mono(34, FontWeight.w600).copyWith(
      letterSpacing: -0.02 * 34,
      height: 1.1,
    ),
    valor: _mono(26, FontWeight.w600),
    valorLinha: _mono(14.5, FontWeight.w400),
    dado: _mono(12, FontWeight.w400, cor: CoresDesmalha.tintaFraca),
    rotulo: _mono(11, FontWeight.w500, cor: CoresDesmalha.tintaFraca).copyWith(
      letterSpacing: 0.12 * 11,
    ),
  );

  /// Atalho: `TipografiaFiscal.de(context).valor`.
  static TipografiaFiscal de(BuildContext context) =>
      Theme.of(context).extension<TipografiaFiscal>() ?? padrao;

  @override
  TipografiaFiscal copyWith({
    TextStyle? valorDestaque,
    TextStyle? valor,
    TextStyle? valorLinha,
    TextStyle? dado,
    TextStyle? rotulo,
  }) => TipografiaFiscal(
    valorDestaque: valorDestaque ?? this.valorDestaque,
    valor: valor ?? this.valor,
    valorLinha: valorLinha ?? this.valorLinha,
    dado: dado ?? this.dado,
    rotulo: rotulo ?? this.rotulo,
  );

  @override
  TipografiaFiscal lerp(TipografiaFiscal? other, double t) {
    if (other == null) return this;
    return TipografiaFiscal(
      valorDestaque: TextStyle.lerp(valorDestaque, other.valorDestaque, t)!,
      valor: TextStyle.lerp(valor, other.valor, t)!,
      valorLinha: TextStyle.lerp(valorLinha, other.valorLinha, t)!,
      dado: TextStyle.lerp(dado, other.dado, t)!,
      rotulo: TextStyle.lerp(rotulo, other.rotulo, t)!,
    );
  }
}
