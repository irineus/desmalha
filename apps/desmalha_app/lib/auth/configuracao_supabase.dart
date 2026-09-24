/// Endereço do servidor e chave pública do tenant, injetados no build.
///
/// O Desmalha NASCE atrás do gateway Fulcrum (card "Desmalha atrás do
/// gateway Fulcrum", set/2026): o app nunca fala com `*.supabase.co`. Ele
/// fala com `https://api.desmalha.app` (produção) ou
/// `https://api-dev.desmalha.app` (dev), levando a chave do TENANT, e o
/// gateway troca essa chave pela do destino. Consequência que vale o
/// desenho: trocar de destino (ou a morte das chaves legadas do Supabase) é
/// a troca de um segredo no gateway, sem publicar app.
///
/// Mesmo padrão do `SENTRY_DSN` em `monitoring.dart`: os dois valores entram
/// por `--dart-define`, nunca versionados. A chave do tenant é pública por
/// construção (vai no binário), mas manter o repositório sem credencial de
/// projeto nenhuma é regra permanente 1 do `CLAUDE.md`. Em dev, o arquivo
/// fica FORA do repositório:
///
/// ```
/// fvm flutter run --dart-define-from-file=C:\Users\<voce>\.desmalha\dev.json
/// ```
///
/// com `{"SUPABASE_URL": "https://api-dev.desmalha.app",
/// "SUPABASE_PUBLISHABLE_KEY": "TENANT_PUBLIC_KEY do env desmalha-dev"}`.
/// Os nomes das variáveis continuam os do SDK do Supabase de propósito: o
/// gateway fala o mesmo protocolo, e o adaptador não muda.
library;

const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

const String supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

/// Por que [url] NÃO serve como endereço do servidor, ou `null` se serve.
///
/// É o `gateway_url_test` do contrato do Fulcrum aplicado em runtime, e não
/// só no teste: um build apontado direto para o Supabase não "funciona meio
/// torto" — ele recusa a configuração e mostra o motivo na tela
/// (`TelaSemConfiguracao`). Mesma postura da guia de DARF sem código de
/// barras: falhar visível em vez de parecer funcionar.
String? motivoUrlRecusada(String url) {
  if (url.isEmpty) return 'SUPABASE_URL não foi informada';
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasAuthority) {
    return 'SUPABASE_URL não é um endereço: "$url"';
  }
  if (uri.scheme != 'https') {
    return 'SUPABASE_URL precisa ser https: "$url"';
  }
  final host = uri.host.toLowerCase();
  if (host == 'supabase.co' ||
      host.endsWith('.supabase.co') ||
      host.endsWith('.supabase.in')) {
    return 'SUPABASE_URL aponta direto para o Supabase ($host). O app fala '
        'só com o gateway: https://api.desmalha.app ou '
        'https://api-dev.desmalha.app';
  }
  return null;
}

/// O que falta na configuração deste build, ou `null` se está completa.
String? get problemaDeConfiguracao {
  final url = motivoUrlRecusada(supabaseUrl);
  if (url != null) return url;
  if (supabasePublishableKey.isEmpty) {
    return 'SUPABASE_PUBLISHABLE_KEY (a chave pública do tenant) não foi '
        'informada';
  }
  return null;
}

/// `true` quando o build recebeu as duas variáveis e a URL é do gateway.
///
/// Sem isso o app **não** finge que autentica: a tela de entrada diz o que
/// está errado. Testes e CI rodam sem as variáveis de propósito — como o
/// Sentry sem DSN.
bool get supabaseConfigurado => problemaDeConfiguracao == null;
