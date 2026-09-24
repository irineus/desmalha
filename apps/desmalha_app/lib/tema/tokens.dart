/// Tokens do sistema visual do Desmalha — transcritos de
/// `docs/design/desmalha-design-system.html` (v0.1, ago/2026).
///
/// Nomeados por PAPEL, nunca por cor: o tema escuro (fora do MVP) vira uma
/// tabela nova com os mesmos nomes, não um retrabalho. O teste
/// `test/tema/tokens_test.dart` lê o `:root` do HTML versionado e reprova se
/// um valor daqui divergir de lá — o documento de design é a fonte, este
/// arquivo é a transcrição.
///
/// Duas regras de aplicação que dependem destes nomes (ver o HTML):
/// - [CoresDesmalha.obrigacao] marca SÓ obrigação fiscal. Não é cor de link,
///   de botão nem de ênfase — por isso não entra no `ColorScheme`.
/// - [CoresDesmalha.falha] só quando algo falhou de verdade (DARF vencido,
///   importação quebrada, exclusão irreversível). Pendência nunca é vermelha.
library;

import 'package:flutter/material.dart';

/// As cores, por papel. `const` e sem instância: o tema lê daqui.
abstract final class CoresDesmalha {
  /// Fundo do app: off-white com viés vegetal.
  static const papel = Color(0xFFEEF2EC);

  /// Cartões e blocos.
  static const superficie = Color(0xFFFFFFFF);

  /// Texto e números principais.
  static const tinta = Color(0xFF16241F);

  /// Texto secundário — 6,6:1 sobre papel.
  static const tintaFraca = Color(0xFF48594F);

  /// Marca e ação primária.
  static const salvia = Color(0xFF3E6B5A);

  /// Texto e ícone sobre preenchimento sálvia (6,8:1).
  static const salviaEscura = Color(0xFF2B5142);

  /// Preenchimento calmo, estado resolvido.
  static const salviaClara = Color(0xFFD8E5DA);

  /// ÚNICA cor de atenção fiscal.
  static const obrigacao = Color(0xFF2E4C7E);
  static const obrigacaoFundo = Color(0xFFE3EAF5);

  /// Só erro real.
  static const falha = Color(0xFFA32B22);

  /// Filetes e bordas.
  static const linha = Color(0xFFD3DDD3);

  // Tons dos selos e do banner, literais no HTML (não são tokens do :root,
  // mas são o que os componentes usam).
  static const obrigacaoBorda = Color(0xFFC6D5EC);
  static const neutroFundo = Color(0xFFEAEEE9);
  static const falhaFundo = Color(0xFFF6E4E2);
  static const abaInativaFundo = Color(0xFFE5EBE4);
}

/// Raios de borda (`--r-sm`, `--r-md`, `--r-lg`).
abstract final class RaiosDesmalha {
  static const pequeno = 6.0;
  static const medio = 12.0;
  static const grande = 20.0;

  /// Pílula (selos, chips): `border-radius: 999px`.
  static const pilula = 999.0;
}

/// Escala de espaçamento (`--s1` a `--s8`).
abstract final class EspacosDesmalha {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 24.0;
  static const s6 = 32.0;
  static const s7 = 48.0;
  static const s8 = 72.0;

  /// Regra de aplicação: área de toque mínima de 48px.
  static const toqueMinimo = 48.0;
}
