import { assert, assertEquals, assertThrows } from "@std/assert";

import { payloadAuth } from "../../../tool/auth_para_api.ts";

const COM_TOKEN = "<p>Seu código: {{ .Token }}</p>";

const CONFIG = `
[auth.email]
otp_length = 8
otp_expiry = 600
double_confirm_changes = true

[auth.email.template.confirmation]
subject = "Seu código de acesso ao Desmalha"
content_path = "./supabase/templates/codigo_de_acesso.html"

[auth.email.template.magic_link]
subject = "Seu código de acesso ao Desmalha"
content_path = "./supabase/templates/codigo_de_acesso.html"

[auth.email.template.email_change]
subject = "Confirme a troca de e-mail no Desmalha"
content_path = "./supabase/templates/troca_de_email.html"

[auth.external.apple]
enabled = false
[auth.external.google]
enabled = false
`;

const payload = payloadAuth(CONFIG, () => COM_TOKEN);

Deno.test("os valores saem do config.toml, e não do código", () => {
  assertEquals(payload.mailer_otp_length, 8);
  assertEquals(payload.mailer_otp_exp, 600);
  assertEquals(payload.mailer_secure_email_change_enabled, true);
  assertEquals(
    payload.mailer_subjects_email_change,
    "Confirme a troca de e-mail no Desmalha",
  );
});

Deno.test("o payload NÃO contém nenhum campo de SMTP", () => {
  // É a razão de este módulo existir. `supabase config push` manda a
  // configuração inteira e apaga o SMTP do projeto, que só existe no painel.
  // Se um campo smtp_* entrar aqui um dia, o efeito volta.
  const smtp = Object.keys(payload).filter((k) => k.startsWith("smtp"));
  assertEquals(smtp, []);
});

Deno.test("provedores sociais viram false explícito, um a um", () => {
  assertEquals(payload.external_apple_enabled, false);
  assertEquals(payload.external_google_enabled, false);
});

Deno.test("template sem {{ .Token }} é recusado na montagem", () => {
  // Falhar aqui é muito melhor do que publicar: um template sem token manda
  // link, e a tela do app pede 8 dígitos. O usuário fica olhando para uma
  // mensagem que não serve para nada, e nada no servidor reclama.
  assertThrows(
    () => payloadAuth(CONFIG, () => "<p>sem token nenhum</p>"),
    Error,
    "{{ .Token }}",
  );
});

Deno.test("config.toml incompleto é recusado", () => {
  assertThrows(() => payloadAuth("[auth.email]\notp_length = 8\n", () => COM_TOKEN));
  assertThrows(() => payloadAuth("", () => COM_TOKEN), Error, "[auth.email]");
});

Deno.test("o config.toml de verdade produz um payload válido", () => {
  // Âncora: os testes acima usam um TOML de mentira. Este garante que o arquivo
  // que o workflow realmente lê continua atravessando a montagem.
  const raiz = new URL("../../../", import.meta.url);
  const toml = Deno.readTextFileSync(new URL("supabase/config.toml", raiz));
  const real = payloadAuth(
    toml,
    (c) => Deno.readTextFileSync(new URL(c.replace(/^\.\//, ""), raiz)),
  );

  assertEquals(real.mailer_otp_length, 8);
  assertEquals(real.mailer_otp_exp, 600);
  assert(
    Object.keys(real).filter((k) => k.startsWith("external_")).length >= 19,
    "os provedores sociais do config.toml não chegaram ao payload",
  );
  assertEquals(Object.keys(real).filter((k) => k.startsWith("smtp")), []);
});
