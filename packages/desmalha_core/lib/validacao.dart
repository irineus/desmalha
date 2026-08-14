/// Ferramentas de validação LOCAL de extratos (CLI `validar_extrato`).
///
/// Biblioteca separada de `desmalha_core.dart` de propósito: o app nunca
/// importa nada daqui — este código existe para o executável de linha de
/// comando que roda na máquina do usuário, validando o parser contra
/// extratos reais sem que o dado sensível saia de lá (ADR local-first).
library;

export 'src/validacao/anonimizador.dart';
export 'src/validacao/codificacao_saida.dart';
export 'src/validacao/deteccao.dart';
export 'src/validacao/formatacao.dart';
export 'src/validacao/relatorio.dart';
