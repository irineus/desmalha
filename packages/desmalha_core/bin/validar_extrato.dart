/// CLI local de validação de extratos OFX/CSV.
///
/// Roda na máquina do usuário — o extrato real NUNCA entra em repositório,
/// sessão de nuvem ou servidor (ADR local-first). O arquivo é apenas LIDO;
/// nada é transmitido. A única escrita possível é a cópia anonimizada,
/// quando `--anonimizar` é pedido explicitamente.
///
/// Uso (na raiz do monorepo ou de packages/desmalha_core):
///   `fvm dart run desmalha_core:validar_extrato <arquivo> [opções]`
///
/// Opções:
///   `--perfil <perfil.json>` — perfil CSV do banco (obrigatório para CSV);
///   exemplos em packages/desmalha_core/perfis/.
///   `--formato <ofx|csv>` — força o formato (padrão: autodetecta).
///   `--encoding <charset>` — força utf-8 | latin-1 | windows-1252
///   (padrão: autodetecta; perfil CSV pode fixar).
///   `--anonimizar` — gera cópia com nomes/CPFs fictícios e valores
///   perturbados, preservando a estrutura.
///   `--saida <arquivo>` — caminho da cópia anonimizada
///   (padrão: `<arquivo>.anonimizado.<ext>`).
///   `--ajuda` — mostra esta ajuda.
///
/// Código de saída: 0 = validado sem avisos; 1 = validado com avisos;
/// 2 = erro (arquivo inválido, perfil malformado, argumentos errados).
library;

import 'dart:convert';
import 'dart:io';

import 'package:desmalha_core/desmalha_core.dart';
import 'package:desmalha_core/validacao.dart';

const _ajuda = '''
validar_extrato — validação LOCAL de extratos OFX/CSV do Desmalha

O arquivo é apenas lido; nada é gravado nem transmitido (a única escrita é
a cópia anonimizada, se --anonimizar for pedido). O relatório traz SÓ
agregados — é o que pode ser colado de volta na sessão de planejamento.

Uso:
  fvm dart run desmalha_core:validar_extrato <arquivo> [opções]

Opções:
  --perfil <perfil.json>   perfil CSV do banco (obrigatório para CSV);
                           exemplos em packages/desmalha_core/perfis/
  --formato <ofx|csv>      força o formato (padrão: autodetecta)
  --encoding <charset>     força utf-8 | latin-1 | windows-1252
  --anonimizar             gera cópia anonimizada preservando a estrutura
  --saida <arquivo>        caminho da cópia (padrão: <arquivo>.anonimizado.<ext>)
  --ajuda                  mostra esta ajuda

Confira a soma de créditos/débitos contra o app do banco: soma batendo e
zero avisos inesperados = parser validado para esse extrato.''';

void main(List<String> argumentos) {
  try {
    exitCode = _executar(argumentos);
  } on _ErroDeUso catch (erro) {
    stderr.writeln('erro: ${erro.mensagem}');
    stderr.writeln('use --ajuda para ver as opções');
    exitCode = 2;
  } on ExtratoInvalidoException catch (erro) {
    stderr.writeln('erro: ${erro.mensagem}');
    exitCode = 2;
  } on FormatException catch (erro) {
    stderr.writeln('erro: ${erro.message}');
    exitCode = 2;
  } on FileSystemException catch (erro) {
    stderr.writeln('erro: ${erro.message}: ${erro.path}');
    exitCode = 2;
  } on ArgumentError catch (erro) {
    stderr.writeln('erro: ${erro.message}');
    exitCode = 2;
  }
}

class _ErroDeUso implements Exception {
  const _ErroDeUso(this.mensagem);

  final String mensagem;
}

int _executar(List<String> argumentos) {
  String? arquivo;
  String? caminhoPerfil;
  String? formatoForcado;
  String? encodingForcado;
  String? caminhoSaida;
  var anonimizar = false;

  String valorDe(String opcao, Iterator<String> resto) {
    if (!resto.moveNext()) {
      throw _ErroDeUso('a opção $opcao exige um valor');
    }
    return resto.current;
  }

  final iterador = argumentos.iterator;
  while (iterador.moveNext()) {
    final argumento = iterador.current;
    switch (argumento) {
      case '--ajuda' || '--help' || '-h':
        stdout.writeln(_ajuda);
        return 0;
      case '--perfil':
        caminhoPerfil = valorDe(argumento, iterador);
      case '--formato':
        formatoForcado = valorDe(argumento, iterador).toLowerCase();
        if (formatoForcado != 'ofx' && formatoForcado != 'csv') {
          throw _ErroDeUso('--formato aceita "ofx" ou "csv"');
        }
      case '--encoding':
        encodingForcado = valorDe(argumento, iterador);
      case '--anonimizar':
        anonimizar = true;
      case '--saida':
        caminhoSaida = valorDe(argumento, iterador);
      default:
        if (argumento.startsWith('--')) {
          throw _ErroDeUso('opção desconhecida: $argumento');
        }
        if (arquivo != null) {
          throw _ErroDeUso('só um arquivo por vez (recebi "$arquivo" '
              'e "$argumento")');
        }
        arquivo = argumento;
    }
  }

  if (arquivo == null) {
    throw const _ErroDeUso('informe o arquivo de extrato a validar');
  }
  if (caminhoSaida != null && !anonimizar) {
    throw const _ErroDeUso('--saida só faz sentido com --anonimizar');
  }

  final bytes = File(arquivo).readAsBytesSync();

  PerfilCsv? perfil;
  if (caminhoPerfil != null) {
    final json = jsonDecode(File(caminhoPerfil).readAsStringSync());
    if (json is! Map<String, Object?>) {
      throw const FormatException('o perfil precisa ser um objeto JSON');
    }
    perfil = PerfilCsv.fromJson(json);
  }

  // Encoding: opção da linha de comando > perfil do banco > autodetecção.
  final decodificado = decodificarComDiagnostico(
    bytes,
    encoding: encodingForcado ?? perfil?.encoding,
  );

  final formato = switch (formatoForcado) {
    'ofx' => FormatoDetectado.ofx,
    'csv' => FormatoDetectado.csv,
    _ => detectarFormato(decodificado.texto, nomeArquivo: arquivo),
  };

  final ExtratoImportado extrato;
  switch (formato) {
    case FormatoDetectado.ofx:
      extrato = parseOfx(decodificado.texto);
    case FormatoDetectado.csv:
      if (perfil == null) {
        throw const _ErroDeUso(
          'arquivo CSV exige --perfil <perfil.json> — exemplos em '
          'packages/desmalha_core/perfis/',
        );
      }
      extrato = parseCsv(decodificado.texto, perfil);
  }

  final relatorio = RelatorioExtrato.doExtrato(
    extrato,
    encoding: decodificado.encoding,
  );
  stdout.writeln('Arquivo:            $arquivo');
  stdout.writeln(relatorio.render());

  if (anonimizar) {
    final anonimizado = switch (formato) {
      FormatoDetectado.ofx => anonimizarOfx(decodificado.texto),
      FormatoDetectado.csv => anonimizarCsv(decodificado.texto, perfil!),
    };
    final destino = caminhoSaida ?? _caminhoAnonimizado(arquivo);
    File(destino).writeAsBytesSync(codificarSaida(
      anonimizado,
      decodificado.encoding,
      comBom: decodificado.comBom,
    ));
    stdout
      ..writeln()
      ..writeln('Cópia anonimizada:  $destino')
      ..writeln('⚠ A anonimização é heurística — revise o arquivo gerado '
          'antes de compartilhar.');
  }

  return relatorio.avisos.isEmpty ? 0 : 1;
}

/// `extrato.csv` → `extrato.anonimizado.csv`; sem extensão, sufixa no fim.
String _caminhoAnonimizado(String arquivo) {
  final barra = arquivo.replaceAll('\\', '/').lastIndexOf('/');
  final ponto = arquivo.lastIndexOf('.');
  if (ponto <= barra) return '$arquivo.anonimizado';
  return '${arquivo.substring(0, ponto)}.anonimizado'
      '${arquivo.substring(ponto)}';
}
