import 'package:flutter/material.dart';

import '../tema/componentes.dart';
import '../tema/tipografia.dart';
import '../tema/tokens.dart';
import 'controlador_backup.dart';
import 'tela_codigo_recuperacao.dart';
import 'tela_restaurar.dart';

String _quando(DateTime? em) {
  if (em == null) return 'nunca';
  final l = em.toLocal();
  String d(int n) => n.toString().padLeft(2, '0');
  return '${d(l.day)}/${d(l.month)}/${l.year} às ${d(l.hour)}:${d(l.minute)}';
}

String _tamanho(int? bytes) {
  if (bytes == null) return '—';
  if (bytes < 1024) return '$bytes B';
  final kib = bytes ~/ 1024;
  if (kib < 1024) return '$kib KB';
  return '${kib ~/ 1024},${((kib % 1024) * 10 ~/ 1024)} MB';
}

/// Ajustes > Backup: o estado, a regra do automático, o código de
/// recuperação e "Fazer backup agora".
class TelaBackup extends StatefulWidget {
  const TelaBackup({super.key, required this.controlador, this.aoRestaurar});

  final ControladorBackup controlador;

  /// Depois de uma restauração: as telas de dados recarregam.
  final VoidCallback? aoRestaurar;

  @override
  State<TelaBackup> createState() => _TelaBackupState();
}

class _TelaBackupState extends State<TelaBackup> {
  bool _entendiDescarte = false;

  Future<void> _restaurar() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TelaRestaurar(
          restaurar: widget.controlador.restaurarComCodigo,
          substituiDadosLocais: true,
        ),
      ),
    );
    widget.aoRestaurar?.call();
  }

  @override
  void initState() {
    super.initState();
    widget.controlador.recarregar();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controlador,
    builder: (context, _) {
      final c = widget.controlador;
      final texto = Theme.of(context).textTheme;
      final fiscal = TipografiaFiscal.de(context);
      final selo = !c.codigoConfirmado
          ? const Selo('desligado', tipo: TipoSelo.falha)
          : c.desatualizado
          ? const Selo('desatualizado', tipo: TipoSelo.falha)
          : const Selo('em dia', tipo: TipoSelo.ok);

      return Scaffold(
        appBar: AppBar(title: const Text('Backup')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(EspacosDesmalha.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(EspacosDesmalha.s4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Último backup',
                                style: texto.titleLarge,
                              ),
                            ),
                            KeyedSubtree(
                              key: const Key('selo_backup'),
                              child: selo,
                            ),
                          ],
                        ),
                        const SizedBox(height: EspacosDesmalha.s2),
                        Text(
                          _quando(c.estado.ultimoSucessoEm),
                          key: const Key('ultimo_backup_em'),
                          style: fiscal.valorLinha,
                        ),
                        Text(
                          'tamanho ${_tamanho(c.estado.tamanhoBytes)} · '
                          'cifrado neste aparelho',
                          style: fiscal.dado,
                        ),
                      ],
                    ),
                  ),
                ),
                if (!c.codigoConfirmado) ...[
                  const SizedBox(height: EspacosDesmalha.s3),
                  Text(
                    'O backup automático está DESLIGADO: falta confirmar o '
                    'código de recuperação. Sem ele, um backup não poderia ser '
                    'aberto em outro celular — por isso nenhum é feito.',
                    key: const Key('aviso_backup_desligado'),
                    style: texto.bodyMedium!.copyWith(
                      color: CoresDesmalha.falha,
                    ),
                  ),
                ] else if (c.desatualizado) ...[
                  const SizedBox(height: EspacosDesmalha.s3),
                  Text(
                    'Faz mais de 7 dias sem um backup bem-sucedido. Se este '
                    'celular se perder, o que mudou desde então se perde junto.',
                    key: const Key('aviso_backup_desatualizado'),
                    style: texto.bodyMedium!.copyWith(
                      color: CoresDesmalha.falha,
                    ),
                  ),
                ],
                if (c.ultimaFalha != null) ...[
                  const SizedBox(height: EspacosDesmalha.s3),
                  Text(
                    c.ultimaFalha!,
                    key: const Key('falha_backup'),
                    style: texto.bodyMedium!.copyWith(
                      color: CoresDesmalha.falha,
                    ),
                  ),
                ],
                if (c.backupsAntigos) ...[
                  const SizedBox(height: EspacosDesmalha.s3),
                  Card(
                    key: const Key('painel_backups_antigos'),
                    child: Padding(
                      padding: const EdgeInsets.all(EspacosDesmalha.s4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Seus backups antigos',
                            style: texto.titleMedium,
                          ),
                          const SizedBox(height: EspacosDesmalha.s2),
                          Text(
                            'Eles só abrem com o código de recuperação antigo. '
                            'Sem ele, ninguém — nem nós — consegue abri-los, e '
                            'isso não tem volta. Se você achar o código, '
                            'restaure; se não, descarte-os para o backup '
                            'voltar a funcionar com o código novo.',
                            style: texto.bodyMedium,
                          ),
                          OutlinedButton(
                            key: const Key('botao_restaurar_backup'),
                            onPressed: _restaurar,
                            child: const Text('Achei o código: restaurar'),
                          ),
                          CheckboxListTile(
                            key: const Key('marcar_descarte'),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: _entendiDescarte,
                            onChanged: (v) =>
                                setState(() => _entendiDescarte = v ?? false),
                            title: const Text(
                              'Entendo: vou descartar os backups antigos, que '
                              'ninguém mais consegue abrir.',
                            ),
                          ),
                          FilledButton(
                            key: const Key('botao_descartar_antigos'),
                            onPressed: _entendiDescarte && !c.executando
                                ? c.descartarBackupsAntigos
                                : null,
                            child: const Text('Descartar e ligar o backup'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (c.ultimoAviso != null) ...[
                  const SizedBox(height: EspacosDesmalha.s3),
                  Text(
                    c.ultimoAviso!,
                    key: const Key('aviso_backup'),
                    style: texto.bodyMedium,
                  ),
                ],
                const SizedBox(height: EspacosDesmalha.s4),
                FilledButton(
                  key: const Key('botao_backup_agora'),
                  onPressed: c.codigoConfirmado && !c.executando
                      ? c.fazerAgora
                      : null,
                  child: c.executando
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Fazer backup agora'),
                ),
                const SizedBox(height: EspacosDesmalha.s4),
                Text('Como funciona', style: texto.titleLarge),
                const SizedBox(height: EspacosDesmalha.s2),
                Text(
                  'Automático, uma vez por dia, quando você abre o app no '
                  'Wi-Fi e algo mudou desde o último backup. Os 3 mais '
                  'recentes ficam guardados, cifrados com uma chave que só '
                  'você tem — nem nós conseguimos abri-los.',
                  style: texto.bodyMedium,
                ),
                const SizedBox(height: EspacosDesmalha.s4),
                OutlinedButton(
                  key: const Key('botao_ir_codigo'),
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<bool>(
                        builder: (_) => TelaCodigoRecuperacao(chaves: c.chaves),
                      ),
                    );
                    await c.recarregar();
                  },
                  child: Text(
                    c.codigoConfirmado
                        ? 'Código de recuperação'
                        : 'Confirmar o código de recuperação',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// O aviso que aparece FORA de Ajustes (no Mês) quando o backup está
/// desligado ou desatualizado — requisito da cláusula 7 dos Termos v0.2.
class AvisoBackup extends StatelessWidget {
  const AvisoBackup({super.key, required this.controlador, this.aoTocar});

  final ControladorBackup controlador;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controlador,
    builder: (context, _) {
      if (!controlador.carregado ||
          (controlador.codigoConfirmado && !controlador.desatualizado)) {
        return const SizedBox.shrink();
      }
      final texto = !controlador.codigoConfirmado
          ? 'Backup desligado: confirme o código de recuperação em Ajustes.'
          : 'Sem backup há mais de 7 dias. Toque para fazer agora.';
      return Padding(
        padding: const EdgeInsets.only(bottom: EspacosDesmalha.s3),
        child: Material(
          color: CoresDesmalha.falhaFundo,
          borderRadius: BorderRadius.circular(RaiosDesmalha.medio),
          child: InkWell(
            key: const Key('aviso_backup_mes'),
            borderRadius: BorderRadius.circular(RaiosDesmalha.medio),
            onTap: aoTocar,
            child: Padding(
              padding: const EdgeInsets.all(EspacosDesmalha.s4),
              child: Row(
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    color: CoresDesmalha.falha,
                  ),
                  const SizedBox(width: EspacosDesmalha.s3),
                  Expanded(
                    child: Text(
                      texto,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: CoresDesmalha.falha,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
