import 'package:desmalha_core/desmalha_core.dart';

/// Um livro-caixa pequeno e FICTÍCIO, com uma linha de cada tabela que o
/// backup leva de mais importante, no formato ATUAL ([formatoBackupAtual]).
/// CPF e nomes inventados; valores em centavos e pontos-base inteiros.
const List<DocumentoBackup> amostraBackup = [
  DocumentoBackup('perfil', {
    'id': 1,
    'usuario_remoto_id': '00000000-0000-4000-8000-000000000001',
    'nome': 'Pessoa Fictícia',
    'cpf': '000.000.000-00',
    'profissao_codigo': 'psicologia',
    'exige_cpf_pagador': 1,
    'onboarding_completo': 1,
    'codigo_recuperacao_confirmado_em': 1790000000000,
    'criado_em': 1789000000000,
    'atualizado_em': 1790000000000,
  }),
  DocumentoBackup('contas_bancarias', {
    'id': 'conta-1',
    'apelido': 'Conta principal',
    'banco_codigo': '901',
    'origem': 'manual',
    'ativa': 1,
    'criado_em': 1789000000000,
  }),
  DocumentoBackup('transacoes', {
    'id': 'tx-1',
    'conta_id': 'conta-1',
    'importacao_id': null,
    'data': '2026-08-18',
    'valor_centavos': 45000,
    'descricao_raw': 'PIX RECEBIDO CLIENTE FICTICIO',
    'fitid': '9012026081800001',
    'criado_em': 1789500000000,
  }),
  DocumentoBackup('transacoes', {
    'id': 'tx-2',
    'conta_id': 'conta-1',
    'importacao_id': null,
    'data': '2026-08-20',
    'valor_centavos': -12000,
    'descricao_raw': 'PAGTO ALUGUEL SALA',
    'fitid': null,
    'criado_em': 1789500000000,
  }),
  DocumentoBackup('apuracoes_mensais', {
    'id': 'ap-2026-08',
    'competencia': '2026-08',
    'versao': 1,
    'receita_bruta_centavos': 1140000,
    'aliquota_bp': 2750,
    'imposto_devido_centavos': 175786,
    'cenario_aplicado': 'deducoesReais',
    'total_para_darf_centavos': 175786,
    'status_darf': 'emitido',
  }),
  DocumentoBackup('darfs', {
    'id': 'darf-2026-08',
    'codigo_receita': '0190',
    'competencia': '2026-08',
    'valor_centavos': 175786,
    'vencimento': '2026-09-30',
    'status': 'gerada',
  }),
  DocumentoBackup('darf_competencias', {
    'darf_id': 'darf-2026-08',
    'competencia': '2026-08',
    'apuracao_id': 'ap-2026-08',
  }),
  DocumentoBackup('aceites_termos_local', {
    'documento': 'termos_uso',
    'versao': '2026-09-v1',
    'aceito_em': 1789000000000,
    'sincronizado': 1,
  }),
];
