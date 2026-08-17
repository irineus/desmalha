/// Repositório do catálogo versionado: rede → cache local → seed embarcado.
///
/// O app precisa calcular OFFLINE — é requisito do card ("cache local com
/// fallback para a última versão conhecida"). A ordem de leitura é:
///
///   1. memória (o catálogo já carregado nesta execução);
///   2. cache local (o último snapshot baixado do servidor);
///   3. seed embarcado no APK (`assets/catalogo/seed.json`, gerado do
///      repositório por `desmalha_core:gerar_seed_catalogo` e conferido por
///      teste a cada `flutter test`).
///
/// `atualizar()` busca do servidor, VALIDA com `Catalogo.fromItens` e só
/// então grava o cache — payload malformado nunca substitui um cache bom.
/// Falha de rede não é erro: offline é o estado normal de um app local-first,
/// e o retorno `false` diz só "continue com o que há".
///
/// Limitação assumida: não há relógio global de versão no conteúdo, então o
/// cache sempre vence o seed — mesmo que uma atualização do app embarque um
/// seed mais novo que um cache antigo. A primeira `atualizar()` com rede
/// resolve; um marcador de versão de publicação pode entrar no futuro se
/// isso se mostrar insuficiente.
///
/// O catálogo NÃO é dado fiscal (tabela pública de imposto, feriados,
/// perfis de banco), por isso o cache é um arquivo JSON simples fora do
/// banco cifrado — o SQLCipher protege o livro-caixa, não o calendário da
/// FEBRABAN.
library;

import 'dart:convert';
import 'dart:io';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'porta_catalogo.dart';

/// Caminho do seed dentro do bundle do app.
const String assetSeedCatalogo = 'assets/catalogo/seed.json';

class RepositorioCatalogo {
  RepositorioCatalogo({
    required this.remota,
    required this.arquivoCache,
    Future<String> Function()? carregarSeed,
  }) : _carregarSeed =
            carregarSeed ?? (() => rootBundle.loadString(assetSeedCatalogo));

  /// `null` num build sem configuração de servidor: `atualizar()` vira
  /// não-op e o app vive de cache/seed — mesma postura das telas de auth.
  final PortaCatalogoRemota? remota;

  /// Snapshot local, ex.: `<suporte>/catalogo_cache.json`.
  final File arquivoCache;

  final Future<String> Function() _carregarSeed;

  Catalogo? _memoria;

  /// O catálogo disponível agora, sem rede: memória → cache → seed.
  ///
  /// Cache ilegível ou corrompido não derruba nada: cai para o seed — a
  /// próxima `atualizar()` com rede o reescreve. O seed, por sua vez, é
  /// gerado e validado no repositório; se ainda assim estiver malformado, a
  /// [FormatException] sobe, porque aí não existe catálogo nenhum e calcular
  /// sem tabela não é opção.
  Future<Catalogo> carregar() async {
    final memoria = _memoria;
    if (memoria != null) return memoria;

    try {
      if (arquivoCache.existsSync()) {
        final catalogo = Catalogo.fromJson(
          jsonDecode(arquivoCache.readAsStringSync()) as Map<String, Object?>,
        );
        _memoria = catalogo;
        return catalogo;
      }
    } on Exception {
      // Cache corrompido — segue para o seed.
    }

    final catalogo = Catalogo.fromJson(
      jsonDecode(await _carregarSeed()) as Map<String, Object?>,
    );
    _memoria = catalogo;
    return catalogo;
  }

  /// Busca o catálogo do servidor e, se ele validar inteiro, grava o cache
  /// e passa a servi-lo. Devolve `true` quando o catálogo local ficou
  /// atualizado; `false` em qualquer falha — rede, resposta malformada,
  /// conteúdo inválido — SEM tocar no cache existente.
  Future<bool> atualizar() async {
    final remota = this.remota;
    if (remota == null) return false;
    try {
      final itens = await remota.buscarItens();
      final catalogo = Catalogo.fromItens(itens);

      arquivoCache.parent.createSync(recursive: true);
      // Escrita atômica: gravar direto e cair no meio deixaria um cache pela
      // metade que a próxima leitura descartaria como corrompido — funciona,
      // mas jogaria fora um catálogo já baixado. rename é atômico no mesmo
      // diretório.
      final temporario = File('${arquivoCache.path}.tmp');
      temporario.writeAsStringSync(jsonEncode(catalogo.toJson()));
      temporario.renameSync(arquivoCache.path);

      _memoria = catalogo;
      return true;
    } on Exception {
      return false;
    }
  }
}
