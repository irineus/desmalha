/// Onboarding (wireframes, fluxo O).
///
/// Antes do login, [TelaBoasVindas] (O1). Depois dele, [PorteiroOnboarding]
/// decide entre o [FluxoOnboarding] — aceite (O2), seus dados, como
/// funciona (O5), código de recuperação, lembrete do DARF, traga seu
/// extrato (O6) — e o app.
///
/// Ficam fora deste card, de propósito: O3 (profissão regulamentada liga a
/// exigência de CPF do pagador, que só a classificação usa) e O4 (INSS e
/// dependentes são deduções do livro-caixa) — os dois moram em cards de
/// regra fiscal ainda em aberto. O extrato de exemplo de O6 é card próprio.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../backup/tela_codigo_recuperacao.dart';
import '../servicos_do_app.dart';
import '../tema/componentes.dart';
import '../tema/tokens.dart';
import 'controlador_onboarding.dart';
import 'porta_aceite.dart';

/// Disclaimer validado e ampliado pelo contador (ago/2026, "Resultado:
/// Consultar contador"). Texto LITERAL — não resumir nem reescrever.
const String disclaimerDesmalha =
    'O app é uma ferramenta de apoio ao cálculo do carnê-leão; não substitui '
    'a orientação de um profissional de contabilidade. O aplicativo '
    'automatiza o cálculo gerencial com base na legislação tributária atual. '
    'A exatidão, classificação correta dos lançamentos e a manutenção dos '
    'comprovantes por 5 anos são de inteira responsabilidade do usuário. '
    'Recomendamos a supervisão periódica de um contador de sua confiança.';

// ─── O1 — Boas-vindas (antes do login) ──────────────────────────────

class TelaBoasVindas extends StatelessWidget {
  const TelaBoasVindas({super.key, required this.aoEntrar});

  final VoidCallback aoEntrar;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    Widget passo(String n, String t) => Padding(
      padding: const EdgeInsets.only(bottom: EspacosDesmalha.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: CoresDesmalha.salviaClara,
            foregroundColor: CoresDesmalha.salviaEscura,
            child: Text(n, style: texto.labelLarge),
          ),
          const SizedBox(width: EspacosDesmalha.s3),
          Expanded(child: Text(t, style: texto.bodyLarge)),
        ],
      ),
    );
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EspacosDesmalha.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: EspacosDesmalha.s6),
              Text('Desmalha', style: texto.displaySmall),
              const SizedBox(height: EspacosDesmalha.s4),
              Text(
                'Recebe de clientes pessoa física pelo seu trabalho? Isso entra '
                'no carnê-leão, mês a mês. O Desmalha organiza seu extrato, '
                'calcula o imposto e prepara o DARF.',
                style: texto.titleMedium,
              ),
              const SizedBox(height: EspacosDesmalha.s5),
              passo('1', 'Importe o extrato do seu banco.'),
              passo('2', 'Marque o que é receita do seu trabalho.'),
              passo(
                '3',
                'Confira o imposto do mês, pague o DARF e registre no e-CAC.',
              ),
              const SizedBox(height: EspacosDesmalha.s4),
              Text(
                disclaimerDesmalha,
                key: const Key('disclaimer'),
                style: texto.bodySmall,
              ),
              const SizedBox(height: EspacosDesmalha.s5),
              FilledButton(
                key: const Key('botao_entrar_boas_vindas'),
                onPressed: aoEntrar,
                child: const Text('Entrar com meu e-mail'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Porteiro depois do login ───────────────────────────────────────

class PorteiroOnboarding extends StatefulWidget {
  const PorteiroOnboarding({
    super.key,
    required this.servicos,
    required this.child,
    required this.aoSair,
  });

  final ServicosDoApp servicos;

  /// Sair da conta (a tela de dados de outra conta oferece isso).
  final Future<void> Function() aoSair;

  /// O app em si, depois do onboarding e com os aceites em dia.
  final Widget child;

  @override
  State<PorteiroOnboarding> createState() => _PorteiroOnboardingState();
}

class _PorteiroOnboardingState extends State<PorteiroOnboarding> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.servicos.onboarding.carregar());
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.servicos.onboarding,
    builder: (context, _) {
      final c = widget.servicos.onboarding;
      if (!c.carregado) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (c.erroAoCarregar != null) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(EspacosDesmalha.s5),
              child: Text(c.erroAoCarregar!),
            ),
          ),
        );
      }
      // Antes de tudo — onboarding, aceite, app e backup automático: dado
      // de outra conta no aparelho nunca aparece nem vai para o backup desta.
      if (c.dadosDeOutraConta) {
        return TelaDadosDeOutraConta(
          servicos: widget.servicos,
          aoSair: widget.aoSair,
        );
      }
      if (c.precisaOnboarding) {
        return FluxoOnboarding(servicos: widget.servicos);
      }
      if (c.precisaAceite || c.bloqueadoSemPublicacao) {
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(EspacosDesmalha.s5),
              child: _ConteudoAceite(controlador: c, aoConcluir: () {}),
            ),
          ),
        );
      }
      return widget.child;
    },
  );
}

// ─── Dados de outra conta no aparelho ───────────────────────────────

/// O aparelho tem dados criados por outra conta. Decisão do owner
/// (24/09/2026): os dados locais pertencem à conta que os criou — a conta
/// desta sessão só entra depois de apagá-los. Nunca herdar em silêncio.
class TelaDadosDeOutraConta extends StatefulWidget {
  const TelaDadosDeOutraConta({
    super.key,
    required this.servicos,
    required this.aoSair,
  });

  final ServicosDoApp servicos;
  final Future<void> Function() aoSair;

  @override
  State<TelaDadosDeOutraConta> createState() => _TelaDadosDeOutraContaState();
}

class _TelaDadosDeOutraContaState extends State<TelaDadosDeOutraConta> {
  bool _entendi = false;
  bool _ocupado = false;
  String? _erro;

  Future<void> _apagar() async {
    setState(() {
      _ocupado = true;
      _erro = null;
    });
    try {
      await widget.servicos.onboarding.apagarDadosLocais();
      await widget.servicos.backup.recarregar();
      widget.servicos.dadosAlterados.value++;
    } on Exception catch (e) {
      if (mounted) {
        setState(
          () => _erro =
              'Não foi possível apagar os dados deste celular: $e. Nada '
              'da outra conta foi mostrado.',
        );
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(EspacosDesmalha.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _titulo(context, 'Este celular tem dados de outra conta'),
            _paragrafo(
              context,
              'Os lançamentos, o perfil e o código de backup guardados neste '
              'celular foram criados com outra conta. Para entrar com a sua, '
              'é preciso apagá-los daqui.',
            ),
            _paragrafo(
              context,
              'Só este celular é afetado: os backups da outra conta, se ela '
              'ainda existir, continuam na nuvem dela. Se os dados são seus e '
              'você entrou com o e-mail errado, saia e entre com o e-mail '
              'certo.',
            ),
            CheckboxListTile(
              key: const Key('caixa_apagar_dados_locais'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _entendi,
              onChanged: _ocupado ? null : (v) => setState(() => _entendi = v!),
              title: const Text(
                'Entendo que os dados deste celular serão apagados e que '
                'isso não se desfaz.',
              ),
            ),
            const SizedBox(height: EspacosDesmalha.s3),
            if (_erro != null) _textoErro(_erro!),
            OutlinedButton(
              key: const Key('botao_apagar_dados_locais'),
              style: estiloBotaoDestrutivo(),
              onPressed: _entendi && !_ocupado ? _apagar : null,
              child: Text(
                _ocupado ? 'Apagando…' : 'Apagar os dados deste celular',
              ),
            ),
            TextButton(
              key: const Key('botao_sair_outra_conta'),
              onPressed: _ocupado ? null : widget.aoSair,
              child: const Text('Sair desta conta'),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── O fluxo ────────────────────────────────────────────────────────

enum _Passo { aceite, dados, comoFunciona, codigo, lembrete, extrato }

class FluxoOnboarding extends StatefulWidget {
  const FluxoOnboarding({super.key, required this.servicos});

  final ServicosDoApp servicos;

  @override
  State<FluxoOnboarding> createState() => _FluxoOnboardingState();
}

class _FluxoOnboardingState extends State<FluxoOnboarding> {
  int _indice = 0;

  void _avancar() => setState(() {
    if (_indice < _Passo.values.length - 1) _indice++;
  });

  @override
  Widget build(BuildContext context) {
    final servicos = widget.servicos;
    final c = servicos.onboarding;
    final passo = _Passo.values[_indice];
    final texto = Theme.of(context).textTheme;
    final corpo = switch (passo) {
      _Passo.aceite => _ConteudoAceite(controlador: c, aoConcluir: _avancar),
      _Passo.dados => _PassoDados(controlador: c, aoConcluir: _avancar),
      _Passo.comoFunciona => _PassoComoFunciona(aoConcluir: _avancar),
      _Passo.codigo => _PassoCodigo(servicos: servicos, aoConcluir: _avancar),
      _Passo.lembrete => _PassoLembrete(
        servicos: servicos,
        aoConcluir: _avancar,
      ),
      _Passo.extrato => _PassoExtrato(controlador: c),
    };
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EspacosDesmalha.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Passo ${_indice + 1} de ${_Passo.values.length}',
                key: const Key('progresso_onboarding'),
                style: texto.labelMedium,
              ),
              const SizedBox(height: EspacosDesmalha.s2),
              LinearProgressIndicator(
                value: (_indice + 1) / _Passo.values.length,
              ),
              const SizedBox(height: EspacosDesmalha.s5),
              KeyedSubtree(key: ValueKey(passo), child: corpo),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _titulo(BuildContext context, String t) => Padding(
  padding: const EdgeInsets.only(bottom: EspacosDesmalha.s4),
  child: Text(t, style: Theme.of(context).textTheme.headlineSmall),
);

Widget _paragrafo(BuildContext context, String t) => Padding(
  padding: const EdgeInsets.only(bottom: EspacosDesmalha.s3),
  child: Text(t, style: Theme.of(context).textTheme.bodyMedium),
);

Widget _textoErro(String t) => Padding(
  padding: const EdgeInsets.only(bottom: EspacosDesmalha.s3),
  child: Text(t, style: const TextStyle(color: CoresDesmalha.falha)),
);

// ─── O2 — Aceite ────────────────────────────────────────────────────

class _ConteudoAceite extends StatefulWidget {
  const _ConteudoAceite({required this.controlador, required this.aoConcluir});

  final ControladorOnboarding controlador;
  final VoidCallback aoConcluir;

  @override
  State<_ConteudoAceite> createState() => _ConteudoAceiteState();
}

class _ConteudoAceiteState extends State<_ConteudoAceite> {
  bool _marcado = false;
  bool _ocupado = false;
  String? _erro;

  Future<void> _aceitar() async {
    setState(() {
      _ocupado = true;
      _erro = null;
    });
    try {
      await widget.controlador.aceitarPendentes();
      if (mounted) widget.aoConcluir();
    } on FalhaAceite catch (f) {
      if (mounted) setState(() => _erro = f.mensagem);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controlador;
    final pendentes = c.aceitesPendentes;
    final faltam = c.naoPublicados;
    final podeSeguir =
        (pendentes.isEmpty || _marcado) && !c.bloqueadoSemPublicacao;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _titulo(context, 'Termos e privacidade'),
        for (final d in pendentes)
          Card(
            child: ListTile(
              title: Text(nomesDocumentosLegais[d.documento]!),
              subtitle: Text('Versão ${d.versao}'),
              trailing: TextButton(
                onPressed: () => launchUrl(
                  Uri.parse(d.url),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Text('Ler'),
              ),
            ),
          ),
        if (faltam.isNotEmpty)
          BannerObrigacao(
            key: const Key('aviso_termos_nao_publicados'),
            titulo:
                '${faltam.map((t) => nomesDocumentosLegais[t]).join(' e ')} '
                'ainda não ${faltam.length == 1 ? 'foi publicado' : 'foram publicados'}.',
            texto: c.permiteSeguirSemTermos
                ? 'Este é um build de desenvolvimento: você pode seguir, e o '
                      'aceite será pedido quando o texto for publicado. Nenhum '
                      'aceite é registrado sem o texto.'
                : 'O Desmalha só pode ser usado depois do aceite. Aguarde a '
                      'publicação e abra o app de novo.',
          ),
        if (pendentes.isNotEmpty) ...[
          const SizedBox(height: EspacosDesmalha.s3),
          CheckboxListTile(
            key: const Key('caixa_aceite'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _marcado,
            onChanged: _ocupado ? null : (v) => setState(() => _marcado = v!),
            title: Text(
              'Li e aceito ${pendentes.map((d) => nomesDocumentosLegais[d.documento]).join(' e ')}.',
            ),
          ),
        ],
        const SizedBox(height: EspacosDesmalha.s3),
        if (_erro != null) _textoErro(_erro!),
        FilledButton(
          key: const Key('botao_aceite_continuar'),
          onPressed: podeSeguir && !_ocupado
              ? (pendentes.isEmpty ? widget.aoConcluir : _aceitar)
              : null,
          child: Text(
            _ocupado
                ? 'Registrando…'
                : pendentes.isEmpty
                ? 'Continuar'
                : 'Aceitar e continuar',
          ),
        ),
      ],
    );
  }
}

// ─── Seus dados ─────────────────────────────────────────────────────

class _PassoDados extends StatefulWidget {
  const _PassoDados({required this.controlador, required this.aoConcluir});

  final ControladorOnboarding controlador;
  final VoidCallback aoConcluir;

  @override
  State<_PassoDados> createState() => _PassoDadosState();
}

class _PassoDadosState extends State<_PassoDados> {
  late final _nome = TextEditingController(
    text: widget.controlador.perfil?.nome ?? '',
  );
  late final _cpf = TextEditingController(
    text: widget.controlador.perfil?.cpf ?? '',
  );
  String? _erro;
  bool _ocupado = false;

  @override
  void dispose() {
    _nome.dispose();
    _cpf.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() => _ocupado = true);
    final erro = await widget.controlador.salvarDados(
      nome: _nome.text,
      cpf: _cpf.text,
    );
    if (!mounted) return;
    setState(() {
      _ocupado = false;
      _erro = erro;
    });
    if (erro == null) widget.aoConcluir();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _titulo(context, 'Seus dados'),
      _paragrafo(
        context,
        'Nome e CPF vão impressos no DARF. Ficam só neste aparelho, no banco '
        'cifrado — e no seu backup, que só você abre.',
      ),
      TextField(
        key: const Key('campo_nome'),
        controller: _nome,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Nome completo'),
      ),
      const SizedBox(height: EspacosDesmalha.s3),
      TextField(
        key: const Key('campo_cpf'),
        controller: _cpf,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.\- ]')),
        ],
        decoration: const InputDecoration(labelText: 'CPF'),
      ),
      const SizedBox(height: EspacosDesmalha.s4),
      if (_erro != null) _textoErro(_erro!),
      FilledButton(
        key: const Key('botao_dados_continuar'),
        onPressed: _ocupado ? null : _salvar,
        child: const Text('Continuar'),
      ),
    ],
  );
}

// ─── O5 — Como funciona ─────────────────────────────────────────────

class _PassoComoFunciona extends StatelessWidget {
  const _PassoComoFunciona({required this.aoConcluir});

  final VoidCallback aoConcluir;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _titulo(context, 'O Desmalha calcula. O e-CAC registra.'),
      _paragrafo(
        context,
        'O livro-caixa oficial do carnê-leão é o Carnê-Leão Web, no e-CAC. '
        'O Desmalha organiza seus recebimentos, calcula o imposto do mês e '
        'prepara o DARF (código 0190) e os totais para você levar até lá.',
      ),
      const BannerObrigacao(
        key: Key('aviso_ecac'),
        titulo: 'Pagar o DARF não registra nada no e-CAC.',
        texto:
            'Todo mês, depois de pagar, replique os totais no Carnê-Leão '
            'Web. O Desmalha mostra o que levar.',
      ),
      const SizedBox(height: EspacosDesmalha.s4),
      FilledButton(
        key: const Key('botao_como_funciona_continuar'),
        onPressed: aoConcluir,
        child: const Text('Entendi'),
      ),
    ],
  );
}

// ─── Código de recuperação (obrigatório — cláusula 7 dos Termos) ────

class _PassoCodigo extends StatefulWidget {
  const _PassoCodigo({required this.servicos, required this.aoConcluir});

  final ServicosDoApp servicos;
  final VoidCallback aoConcluir;

  @override
  State<_PassoCodigo> createState() => _PassoCodigoState();
}

enum _EstadoCodigo { conferindo, jaConfirmado, backupExistente, novo, erro }

class _PassoCodigoState extends State<_PassoCodigo> {
  _EstadoCodigo _estado = _EstadoCodigo.conferindo;
  bool _voltouSemConfirmar = false;

  @override
  void initState() {
    super.initState();
    unawaited(_conferir());
  }

  Future<void> _conferir() async {
    setState(() => _estado = _EstadoCodigo.conferindo);
    try {
      if (await widget.servicos.chavesBackup.codigoConfirmado()) {
        await widget.servicos.onboarding.registrarCodigoConfirmado();
        if (mounted) setState(() => _estado = _EstadoCodigo.jaConfirmado);
        return;
      }
      // Conta que já tem backup na nuvem (reinstalação, aparelho novo):
      // gerar um código aqui criaria uma chave-mestra NOVA, e os próximos
      // backups empurrariam os antigos para fora das 3 versões guardadas.
      final existe = await widget.servicos.backup.existeBackupNaNuvem();
      if (mounted) {
        setState(
          () => _estado = existe
              ? _EstadoCodigo.backupExistente
              : _EstadoCodigo.novo,
        );
      }
    } on Exception {
      if (mounted) setState(() => _estado = _EstadoCodigo.erro);
    }
  }

  Future<void> _gerar() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            TelaCodigoRecuperacao(chaves: widget.servicos.chavesBackup),
      ),
    );
    if (await widget.servicos.chavesBackup.codigoConfirmado()) {
      await widget.servicos.onboarding.registrarCodigoConfirmado();
      if (mounted) widget.aoConcluir();
    } else if (mounted) {
      setState(() => _voltouSemConfirmar = true);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: switch (_estado) {
      _EstadoCodigo.conferindo => [
        _titulo(context, 'Código de recuperação'),
        const Center(child: CircularProgressIndicator()),
      ],
      _EstadoCodigo.jaConfirmado => [
        _titulo(context, 'Código de recuperação'),
        const Align(
          alignment: Alignment.centerLeft,
          child: Selo('código confirmado', tipo: TipoSelo.ok),
        ),
        const SizedBox(height: EspacosDesmalha.s4),
        FilledButton(
          key: const Key('botao_codigo_continuar'),
          onPressed: widget.aoConcluir,
          child: const Text('Continuar'),
        ),
      ],
      _EstadoCodigo.backupExistente => [
        _titulo(context, 'Você já tem backup na nuvem'),
        const BannerObrigacao(
          key: Key('aviso_backup_existente'),
          titulo: 'Não vamos gerar um código novo agora.',
          texto:
              'Seus backups abrem com o código que você anotou. A '
              'restauração neste aparelho ainda não está disponível; até lá '
              'o backup automático fica desligado, para não misturar chaves.',
        ),
        const SizedBox(height: EspacosDesmalha.s4),
        FilledButton(
          key: const Key('botao_codigo_continuar'),
          onPressed: widget.aoConcluir,
          child: const Text('Continuar'),
        ),
      ],
      _EstadoCodigo.erro => [
        _titulo(context, 'Código de recuperação'),
        _textoErro(
          'Não conseguimos conferir se você já tem backup na nuvem. Confira '
          'a conexão.',
        ),
        FilledButton(
          key: const Key('botao_codigo_tentar'),
          onPressed: _conferir,
          child: const Text('Tentar de novo'),
        ),
      ],
      _EstadoCodigo.novo => [
        _titulo(context, 'Código de recuperação'),
        _paragrafo(
          context,
          'Seus dados ficam só no seu celular, e o backup vai cifrado. O '
          'código de recuperação é a única chave que abre esse backup em '
          'outro aparelho — nem nós conseguimos abrir sem ele.',
        ),
        _paragrafo(
          context,
          'É obrigatório: sem ele, perder o celular é perder os dados.',
        ),
        if (_voltouSemConfirmar)
          _textoErro(
            'O código ainda não foi confirmado. Este passo é obrigatório.',
          ),
        FilledButton(
          key: const Key('botao_codigo_gerar'),
          onPressed: _gerar,
          child: const Text('Gerar meu código'),
        ),
      ],
    },
  );
}

// ─── Lembrete do DARF ───────────────────────────────────────────────

class _PassoLembrete extends StatefulWidget {
  const _PassoLembrete({required this.servicos, required this.aoConcluir});

  final ServicosDoApp servicos;
  final VoidCallback aoConcluir;

  @override
  State<_PassoLembrete> createState() => _PassoLembreteState();
}

class _PassoLembreteState extends State<_PassoLembrete> {
  bool _ocupado = false;

  Future<void> _ativar() async {
    setState(() => _ocupado = true);
    await widget.servicos.lembretes.permitir();
    if (mounted) widget.aoConcluir();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _titulo(context, 'Lembrete do vencimento'),
      _paragrafo(
        context,
        'O DARF do carnê-leão vence no último dia útil do mês seguinte. O '
        'Desmalha avisa 3 dias antes e no dia, às 9h — o aviso é do próprio '
        'celular, sem passar por servidor.',
      ),
      FilledButton(
        key: const Key('botao_ativar_lembrete'),
        onPressed: _ocupado ? null : _ativar,
        child: const Text('Ativar lembrete'),
      ),
      TextButton(
        key: const Key('botao_lembrete_agora_nao'),
        onPressed: _ocupado ? null : widget.aoConcluir,
        child: const Text('Agora não'),
      ),
    ],
  );
}

// ─── O6 — Traga seu extrato ─────────────────────────────────────────

class _PassoExtrato extends StatefulWidget {
  const _PassoExtrato({required this.controlador});

  final ControladorOnboarding controlador;

  @override
  State<_PassoExtrato> createState() => _PassoExtratoState();
}

class _PassoExtratoState extends State<_PassoExtrato> {
  String? _erro;

  Future<void> _concluir() async {
    try {
      await widget.controlador.concluir();
    } on StateError catch (e) {
      if (mounted) setState(() => _erro = 'Não foi possível concluir: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _titulo(context, 'Traga seu extrato'),
      _paragrafo(
        context,
        'No app ou no internet banking do seu banco, procure "Exportar '
        'extrato" e escolha o formato OFX (ou CSV). Um mês inteiro é o '
        'suficiente para começar.',
      ),
      _paragrafo(
        context,
        'Depois, importe o arquivo pela aba Lançamentos. O arquivo é lido '
        'no celular e nunca sai dele.',
      ),
      if (_erro != null) _textoErro(_erro!),
      FilledButton(
        key: const Key('botao_concluir_onboarding'),
        onPressed: _concluir,
        child: const Text('Começar a usar'),
      ),
    ],
  );
}
