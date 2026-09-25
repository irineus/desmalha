/// Núcleo fiscal do Desmalha: motor de cálculo, parser OFX e regras do
/// carnê-leão, em Dart puro (sem dependência de Flutter).
///
/// Convenções invioláveis (ver CLAUDE.md na raiz do monorepo):
/// dinheiro em `int` de centavos, percentuais em pontos-base, nunca `double`.
library;

export 'src/backup/codigo_recuperacao.dart';
export 'src/backup/envelope_dsmb.dart';
export 'src/backup/excecoes_backup.dart';
export 'src/backup/payload_backup.dart';
export 'src/carne_leao/apuracao.dart';
export 'src/carne_leao/estados_persistidos.dart';
export 'src/carne_leao/darf.dart';
export 'src/carne_leao/lembrete_vencimento.dart';
export 'src/carne_leao/painel_mensal.dart';
export 'src/carne_leao/repasse.dart';
export 'src/carne_leao/tabela_irpf.dart';
export 'src/catalogo/catalogo.dart';
export 'src/catalogo/documento_legal.dart';
export 'src/catalogo/feriados_bancarios.dart';
export 'src/catalogo/profissao.dart';
export 'src/catalogo/rubrica.dart';
export 'src/darf/codigo_barras_arrecadacao.dart';
export 'src/darf/documento_darf.dart';
export 'src/darf/guia_do_mes.dart';
export 'src/darf/itf.dart';
export 'src/darf/layout_darf.dart';
export 'src/darf/pdf_darf.dart';
export 'src/darf/pdf_minimo.dart';
export 'src/dinheiro.dart';
export 'src/extrato/csv_parser.dart';
export 'src/extrato/data_civil.dart';
export 'src/extrato/decodificacao.dart';
export 'src/extrato/deduplicacao.dart';
export 'src/extrato/leitura_arquivo.dart';
export 'src/extrato/ofx_parser.dart';
export 'src/extrato/perfil_csv.dart';
export 'src/extrato/transacao_importada.dart';
export 'src/extrato/valor_monetario.dart';
