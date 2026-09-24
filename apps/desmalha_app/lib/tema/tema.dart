/// O `ThemeData` do Desmalha (tema claro — o escuro está fora do MVP).
///
/// Tudo sai de `tokens.dart` e `tipografia.dart`. Duas escolhas que não são
/// óbvias olhando só o Material:
/// - O azul-obrigação NÃO entra no `ColorScheme`. Se entrasse (como
///   `secondary` ou `tertiary`), algum componente do Material o usaria para
///   ênfase ou foco, e a regra "azul só marca obrigação fiscal" cairia sem
///   ninguém escrever uma linha. Quem precisa dele pede
///   `CoresDesmalha.obrigacao` explicitamente — os componentes de
///   `componentes.dart`.
/// - `secondary`/`tertiary` são tons de sálvia pelo mesmo motivo.
library;

import 'package:flutter/material.dart';

import 'tipografia.dart';
import 'tokens.dart';

ThemeData temaDesmalha() {
  const esquema = ColorScheme(
    brightness: Brightness.light,
    primary: CoresDesmalha.salvia,
    onPrimary: Colors.white,
    primaryContainer: CoresDesmalha.salviaClara,
    onPrimaryContainer: CoresDesmalha.salviaEscura,
    secondary: CoresDesmalha.salviaEscura,
    onSecondary: Colors.white,
    secondaryContainer: CoresDesmalha.salviaClara,
    onSecondaryContainer: CoresDesmalha.salviaEscura,
    tertiary: CoresDesmalha.salviaEscura,
    onTertiary: Colors.white,
    error: CoresDesmalha.falha,
    onError: Colors.white,
    errorContainer: CoresDesmalha.falhaFundo,
    onErrorContainer: CoresDesmalha.falha,
    surface: CoresDesmalha.superficie,
    onSurface: CoresDesmalha.tinta,
    onSurfaceVariant: CoresDesmalha.tintaFraca,
    surfaceContainerLowest: CoresDesmalha.superficie,
    surfaceContainerLow: CoresDesmalha.papel,
    surfaceContainer: CoresDesmalha.papel,
    surfaceContainerHigh: CoresDesmalha.neutroFundo,
    surfaceContainerHighest: CoresDesmalha.abaInativaFundo,
    outline: CoresDesmalha.tintaFraca,
    outlineVariant: CoresDesmalha.linha,
  );

  final texto = textThemeDesmalha();
  const cantoMedio = BorderRadius.all(Radius.circular(RaiosDesmalha.medio));
  const tamanhoMinimoBotao = Size(
    EspacosDesmalha.toqueMinimo,
    EspacosDesmalha.toqueMinimo,
  );
  const paddingBotao = EdgeInsets.symmetric(horizontal: 20, vertical: 13);

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: CoresDesmalha.papel,
    canvasColor: CoresDesmalha.papel,
    dividerColor: CoresDesmalha.linha,
    fontFamily: FamiliasDesmalha.karla,
    textTheme: texto,
    // Área de toque mínima de 48px em tudo que é tocável.
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    extensions: [TipografiaFiscal.padrao],
    appBarTheme: AppBarTheme(
      backgroundColor: CoresDesmalha.papel,
      foregroundColor: CoresDesmalha.tinta,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: texto.headlineSmall,
    ),
    cardTheme: const CardThemeData(
      color: CoresDesmalha.superficie,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.only(bottom: EspacosDesmalha.s3),
      shape: RoundedRectangleBorder(
        borderRadius: cantoMedio,
        side: BorderSide(color: CoresDesmalha.linha),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: CoresDesmalha.linha,
      thickness: 1,
      space: 1,
    ),
    // Uma ação primária por tela: FilledButton é o primário.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CoresDesmalha.salvia,
        foregroundColor: Colors.white,
        minimumSize: tamanhoMinimoBotao,
        padding: paddingBotao,
        shape: const RoundedRectangleBorder(borderRadius: cantoMedio),
        textStyle: texto.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CoresDesmalha.salvia,
        side: const BorderSide(color: CoresDesmalha.salvia),
        minimumSize: tamanhoMinimoBotao,
        padding: paddingBotao,
        shape: const RoundedRectangleBorder(borderRadius: cantoMedio),
        textStyle: texto.labelLarge,
      ),
    ),
    // Fantasma: ação terciária, em tinta fraca.
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: CoresDesmalha.tintaFraca,
        minimumSize: tamanhoMinimoBotao,
        padding: paddingBotao,
        shape: const RoundedRectangleBorder(borderRadius: cantoMedio),
        textStyle: texto.labelLarge,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: CoresDesmalha.superficie,
      border: OutlineInputBorder(
        borderRadius: cantoMedio,
        borderSide: BorderSide(color: CoresDesmalha.linha),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: cantoMedio,
        borderSide: BorderSide(color: CoresDesmalha.linha),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: cantoMedio,
        borderSide: BorderSide(color: CoresDesmalha.salvia, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: cantoMedio,
        borderSide: BorderSide(color: CoresDesmalha.falha),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      minTileHeight: EspacosDesmalha.toqueMinimo,
      iconColor: CoresDesmalha.tintaFraca,
    ),
    // A barra de abas do sistema visual: superfície branca, filete no topo,
    // rótulo em Plex Mono, aba ativa em sálvia.
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: CoresDesmalha.superficie,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 64,
      indicatorColor: CoresDesmalha.salviaClara,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (estados) => IconThemeData(
          color: estados.contains(WidgetState.selected)
              ? CoresDesmalha.salviaEscura
              : CoresDesmalha.tintaFraca,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (estados) => estados.contains(WidgetState.selected)
            ? texto.labelSmall!.copyWith(
                color: CoresDesmalha.salvia,
                fontWeight: FontWeight.w600,
              )
            : texto.labelSmall,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: CoresDesmalha.tinta,
      shape: RoundedRectangleBorder(borderRadius: cantoMedio),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: CoresDesmalha.salvia,
    ),
  );
}
