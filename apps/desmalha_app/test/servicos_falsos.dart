import 'dart:math';

import 'package:desmalha_app/backup/chaves_backup.dart';
import 'package:desmalha_app/conta/porta_exclusao_conta.dart';
import 'package:desmalha_app/dados/chave_banco.dart';
import 'package:desmalha_app/servicos_do_app.dart';

import 'conta/porta_exclusao_falsa.dart';

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

/// [ServicosDoApp] para teste: portas falsas e cofre em memória.
ServicosDoApp servicosFalsos({
  PortaExclusaoConta? exclusao,
  ChavesBackup? chavesBackup,
}) => ServicosDoApp(
  exclusao: exclusao ?? PortaExclusaoFalsa(),
  chavesBackup:
      chavesBackup ??
      ChavesBackup(cofre: CofreEmMemoria(), aleatorio: Random(1)),
);
