import 'dart:math';

import 'package:desmalha_app/backup/chaves_backup.dart';
import 'package:desmalha_app/backup/controlador_backup.dart';
import 'package:desmalha_app/backup/estado_backup.dart';
import 'package:desmalha_app/backup/servico_backup.dart';
import 'package:desmalha_app/conta/porta_exclusao_conta.dart';
import 'package:desmalha_app/dados/chave_banco.dart';
import 'package:desmalha_app/lembretes/controlador_lembretes.dart';
import 'package:desmalha_app/servicos_do_app.dart';
import 'package:desmalha_core/desmalha_core.dart';

import 'backup/armazenamento_falso.dart';
import 'conta/porta_exclusao_falsa.dart';
import 'lembretes/notificacoes_falsas.dart';

/// Cofre do sistema em memória, com contagem de gravações.
class CofreEmMemoria implements CofreSeguro {
  final Map<String, String> valores = {};
  int gravacoes = 0;

  @override
  Future<String?> ler(String campo) async => valores[campo];

  @override
  Future<void> gravar(String campo, String valor) async {
    gravacoes++;
    valores[campo] = valor;
  }
}

/// Banco local de mentira para o backup: uma lista de documentos.
class FonteEmMemoria implements FonteDocumentosBackup {
  List<DocumentoBackup> documentos = const [
    DocumentoBackup('transacoes', {'id': 'tx-1', 'valor_centavos': 45000}),
  ];
  List<DocumentoBackup>? importados;

  @override
  Future<int> versaoDoSchemaLocal() async => 1;
  @override
  Future<List<DocumentoBackup>> exportar() async => documentos;
  @override
  Future<void> importar(List<DocumentoBackup> d) async => importados = d;
}

/// Controlador de backup com portas em memória.
ControladorBackup controladorBackupFalso({
  ChavesBackup? chaves,
  ArmazenamentoFalso? armazenamento,
  RepositorioEstadoBackup? estado,
  FonteDocumentosBackup? fonte,
  bool wifi = true,
  bool sessao = true,
  DateTime Function()? relogio,
}) {
  final c =
      chaves ?? ChavesBackup(cofre: CofreEmMemoria(), aleatorio: Random(1));
  final porta = armazenamento ?? ArmazenamentoFalso();
  final f = fonte ?? FonteEmMemoria();
  return ControladorBackup(
    servico: () => ServicoBackup(
      porta: porta,
      chaves: c,
      fonte: f,
      usuarioId: () => '00000000-0000-4000-8000-00000000000a',
      appVersao: '1.0.0',
      plataforma: 'android',
    ),
    chaves: c,
    estadoPersistido: estado ?? RepositorioEstadoBackupMemoria(),
    emWifi: () async => wifi,
    comSessao: () => sessao,
    relogio: relogio,
  );
}

/// [ServicosDoApp] para teste: portas falsas e cofre em memória.
ServicosDoApp servicosFalsos({
  PortaExclusaoConta? exclusao,
  ChavesBackup? chavesBackup,
  ControladorBackup? backup,
  ControladorLembretes? lembretes,
}) {
  final chaves =
      chavesBackup ??
      ChavesBackup(cofre: CofreEmMemoria(), aleatorio: Random(1));
  return ServicosDoApp(
    exclusao: exclusao ?? PortaExclusaoFalsa(),
    chavesBackup: chaves,
    backup: backup ?? controladorBackupFalso(chaves: chaves),
    lembretes: lembretes ?? controladorLembretesFalso(),
  );
}
