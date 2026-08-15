/// Endereço e chave pública do projeto Supabase, injetados no build.
///
/// Mesmo padrão do `SENTRY_DSN` em `monitoring.dart`: entram por
/// `--dart-define`, nunca versionados. A chave publicável não é segredo — ela
/// é pública por construção e quem protege as tabelas é o RLS —, mas manter o
/// repositório sem credencial de projeto nenhuma é regra permanente 1 do
/// `CLAUDE.md`, e não vale abrir exceção para o caso fácil.
///
/// ```
/// fvm flutter run \
///   --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
///   --dart-define=SUPABASE_PUBLISHABLE_KEY=<chave publicável do projeto>
/// ```
///
/// Projetos antigos ainda exibem a chave como *anon key*: é o mesmo valor e
/// entra na mesma variável.
library;

const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

const String supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

/// `true` quando o build recebeu as duas variáveis.
///
/// Sem elas o app **não** finge que autentica: a tela de entrada diz que o
/// build está sem configuração. Testes e CI rodam assim de propósito — como o
/// Sentry sem DSN —, e a diferença aparece na tela em vez de virar um erro de
/// rede confuso na primeira tentativa de login.
bool get supabaseConfigurado =>
    supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
