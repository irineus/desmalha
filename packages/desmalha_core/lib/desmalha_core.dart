/// Núcleo fiscal do Desmalha: motor de cálculo, parser OFX e regras do
/// carnê-leão, em Dart puro (sem dependência de Flutter).
///
/// Convenções invioláveis (ver CLAUDE.md na raiz do monorepo):
/// dinheiro em `int` de centavos, percentuais em pontos-base, nunca `double`.
library;

export 'src/carne_leao/apuracao.dart';
export 'src/carne_leao/darf.dart';
export 'src/carne_leao/repasse.dart';
export 'src/carne_leao/tabela_irpf.dart';
export 'src/dinheiro.dart';
export 'src/extrato/csv_parser.dart';
export 'src/extrato/data_civil.dart';
export 'src/extrato/decodificacao.dart';
export 'src/extrato/ofx_parser.dart';
export 'src/extrato/perfil_csv.dart';
export 'src/extrato/transacao_importada.dart';
export 'src/extrato/valor_monetario.dart';
