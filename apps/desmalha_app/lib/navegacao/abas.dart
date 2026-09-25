/// O conteúdo de cada aba enquanto as telas fiscais não chegam.
///
/// Cada aba provisória diz o que vai morar ali, em vez de uma tela em branco
/// que parece defeito. As telas de verdade entram pelos cards da Fase 5:
/// dashboard do mês, importação, DARF (e, fora desta cadeia, classificação,
/// livro-caixa e relatório anual).
library;

import 'package:flutter/material.dart';

import '../auth/servico_auth.dart';
import '../auth/tela_conta.dart';
import '../backup/tela_backup.dart';
import '../classificacao/aba_lancamentos.dart';
import '../despesas/aba_despesas.dart';
import '../painel/tela_mes.dart';
import '../lembretes/controlador_lembretes.dart';
import '../servicos_do_app.dart';
import '../tema/componentes.dart';
import '../tema/tokens.dart';
import 'casca.dart';

/// O que o porteiro põe em cada aba depois do login.
Widget conteudoDaAba(
  AbaDoApp aba,
  ServicoAutenticacao servico,
  ServicosDoApp servicos,
) => switch (aba) {
  AbaDoApp.mes => TelaMes(servicos: servicos),
  AbaDoApp.lancamentos => AbaLancamentos(servicos: servicos),
  AbaDoApp.despesas => AbaDespesas(servicos: servicos),
  AbaDoApp.ano => const AbaProvisoria(
    titulo: 'Seu ano',
    mensagem:
        'O fechamento do ano, mês a mês, para a declaração — chega '
        'numa próxima versão.',
  ),
  AbaDoApp.ajustes => TelaAjustes(servico: servico, servicos: servicos),
};

/// Uma aba que ainda não tem tela: título + estado vazio honesto.
class AbaProvisoria extends StatelessWidget {
  const AbaProvisoria({
    super.key,
    required this.titulo,
    required this.mensagem,
    this.aviso,
  });

  final String titulo;
  final String mensagem;

  /// Aviso no topo (ex.: backup desligado/desatualizado).
  final Widget? aviso;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(EspacosDesmalha.s4),
      children: [
        Text(titulo, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: EspacosDesmalha.s4),
        ?aviso,
        EstadoVazio(mensagem: mensagem),
      ],
    ),
  );
}

/// Ajustes: a conta hoje; backup e exclusão de conta entram pelos cards
/// seguintes.
class TelaAjustes extends StatelessWidget {
  const TelaAjustes({super.key, required this.servico, required this.servicos});

  final ServicoAutenticacao servico;
  final ServicosDoApp servicos;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(EspacosDesmalha.s4),
      children: [
        Text('Ajustes', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: EspacosDesmalha.s4),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Sua conta'),
            subtitle: const Text('E-mail de acesso, saída e exclusão'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    TelaConta(servico: servico, exclusao: servicos.exclusao),
              ),
            ),
          ),
        ),
        _ItemBackup(servicos: servicos),
        _ItemLembreteDarf(controlador: servicos.lembretes),
      ],
    ),
  );
}

/// Navegador global do app — o aviso de backup no Mês abre a tela de backup
/// a partir de uma aba que não tem a rota de Ajustes por perto.
final chaveNavegadorDoApp = GlobalKey<NavigatorState>();

void abrirTelaBackup(ServicosDoApp servicos) {
  chaveNavegadorDoApp.currentState?.push(
    MaterialPageRoute<void>(
      builder: (_) => TelaBackup(controlador: servicos.backup),
    ),
  );
}

/// Ajustes > Backup, com o estado escrito no próprio item: sem código
/// confirmado o automático fica desligado, e isso aparece AQUI.
class _ItemBackup extends StatelessWidget {
  const _ItemBackup({required this.servicos});

  final ServicosDoApp servicos;

  @override
  Widget build(BuildContext context) => Card(
    child: ListenableBuilder(
      listenable: servicos.backup,
      builder: (context, _) {
        final c = servicos.backup;
        final (subtitulo, selo) = !c.carregado
            ? ('Conferindo…', null)
            : !c.codigoConfirmado
            ? (
                'Desligado — falta confirmar o código de recuperação.',
                const Selo('desligado', tipo: TipoSelo.falha),
              )
            : c.desatualizado
            ? (
                'Desatualizado — mais de 7 dias sem backup.',
                const Selo('desatualizado', tipo: TipoSelo.falha),
              )
            : ('Em dia. Automático 1× por dia no Wi-Fi.', null);
        return ListTile(
          key: const Key('item_backup'),
          leading: const Icon(Icons.cloud_upload_outlined),
          title: const Text('Backup'),
          subtitle: Text(subtitulo),
          trailing: selo ?? const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => TelaBackup(controlador: c)),
          ),
        );
      },
    ),
  );
}

/// Ajustes > Lembrete do DARF: o próximo vencimento avisado ou, em
/// vermelho, por que o aviso NÃO vai aparecer — notificação não autorizada,
/// ano sem calendário de feriados, erro ao agendar.
class _ItemLembreteDarf extends StatelessWidget {
  const _ItemLembreteDarf({required this.controlador});

  final ControladorLembretes controlador;

  static const _textoSemPermissao =
      'O aparelho não autorizou. Libere em Configurações > Apps > Desmalha '
      '> Notificações.';

  Future<void> _permitir(BuildContext context) async {
    final mensageiro = ScaffoldMessenger.of(context);
    if (!await controlador.permitir()) {
      mensageiro.showSnackBar(
        const SnackBar(content: Text(_textoSemPermissao)),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: ListenableBuilder(
      listenable: controlador,
      builder: (context, _) {
        final c = controlador;
        final proximo = c.agendados.isEmpty ? null : c.agendados.first;
        final falha = c.falhaDeCalendario;
        final (subtitulo, selo) = !c.carregado
            ? ('Conferindo…', null)
            : c.erro != null
            ? (c.erro!, const Selo('erro', tipo: TipoSelo.falha))
            : !c.permitidas
            ? (
                'Desligado — o aparelho não autorizou notificações. '
                    'Toque para permitir.',
                const Selo('desligado', tipo: TipoSelo.falha),
              )
            : proximo == null && falha != null
            ? (
                'Sem aviso: o calendário de feriados de '
                    '${falha.anoDoVencimento} ainda não foi publicado, e o '
                    'vencimento não é calculado sem ele.',
                const Selo('sem calendário', tipo: TipoSelo.falha),
              )
            : proximo == null
            ? ('Nenhum vencimento a avisar.', null)
            : (
                'Próximo: ${dataCurta(proximo.vencimento)} (competência '
                    '${competenciaPorExtenso(proximo.competencia)}). Aviso '
                    '3 dias antes e no dia, às 9h.'
                    '${falha == null ? '' : ' Depois disso, falta o '
                              'calendário de feriados de '
                              '${falha.anoDoVencimento}.'}',
                null,
              );
        return ListTile(
          key: const Key('item_lembrete_darf'),
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('Lembrete do DARF'),
          subtitle: Text(subtitulo),
          trailing: selo,
          onTap: c.carregado && !c.permitidas ? () => _permitir(context) : null,
        );
      },
    ),
  );
}
