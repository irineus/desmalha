/**
 * Traduz `supabase/config.toml` no payload da Management API de auth.
 *
 * POR QUE NÃO `supabase config push`
 *
 * Porque ele **desliga o SMTP do projeto**. Medido em 17/ago/2026: às 04:56 a
 * conferência leu `smtp_host=smtp.resend.com`; o `config push` rodou logo
 * depois no mesmo job; e o "Enable custom SMTP" voltou a desligado, com o
 * e-mail seguinte saindo de novo pelo provedor embutido.
 *
 * O motivo é que ele manda a configuração de auth INTEIRA. Os campos que o
 * `config.toml` não descreve — e o SMTP remoto é um deles, porque o bloco
 * `[auth.email.smtp]` de lá vale para o stack local — vão embora junto. Não é
 * bug do CLI: é o que "push da configuração inteira" significa, e é
 * incompatível com um projeto onde parte da configuração só existe no painel.
 *
 * A saída é escrever apenas os campos que se quer nomear. Este arquivo faz essa
 * lista, e o que não estiver aqui o workflow não toca.
 *
 * O `config.toml` segue sendo a fonte: os valores saem de lá, não daqui.
 */

import { parse } from "jsr:@std/toml@1";

/** O que a Management API aceita, restrito ao que este projeto gerencia. */
export interface PayloadAuth {
  mailer_otp_length: number;
  mailer_otp_exp: number;
  mailer_secure_email_change_enabled: boolean;
  external_email_enabled: boolean;
  mailer_subjects_confirmation: string;
  mailer_templates_confirmation_content: string;
  mailer_subjects_magic_link: string;
  mailer_templates_magic_link_content: string;
  mailer_subjects_email_change: string;
  mailer_templates_email_change_content: string;
  [provedor: string]: string | number | boolean;
}

/**
 * Monta o payload.
 *
 * `lerTemplate` recebe o `content_path` do config.toml e devolve o HTML — fica
 * injetado para o teste não depender de disco.
 */
export function payloadAuth(
  configToml: string,
  lerTemplate: (caminho: string) => string,
): PayloadAuth {
  // deno-lint-ignore no-explicit-any
  const cfg = parse(configToml) as any;
  const email = cfg?.auth?.email;
  if (!email) throw new Error("config.toml sem [auth.email]");

  const modelo = (nome: string) => {
    const t = email.template?.[nome];
    if (!t?.subject || !t?.content_path) {
      throw new Error(`config.toml sem [auth.email.template.${nome}] completo`);
    }
    const html = lerTemplate(t.content_path);
    // Sem o token, o e-mail chega com link e a tela do app pede 8 dígitos —
    // o usuário fica olhando para uma mensagem que não serve para nada.
    if (!html.includes("{{ .Token }}")) {
      throw new Error(
        `template "${nome}" (${t.content_path}) não contém {{ .Token }}`,
      );
    }
    return { subject: t.subject as string, html };
  };

  const confirmacao = modelo("confirmation");
  const magico = modelo("magic_link");
  const troca = modelo("email_change");

  const payload: PayloadAuth = {
    mailer_otp_length: email.otp_length,
    mailer_otp_exp: email.otp_expiry,
    mailer_secure_email_change_enabled: email.double_confirm_changes === true,
    external_email_enabled: true,
    mailer_subjects_confirmation: confirmacao.subject,
    mailer_templates_confirmation_content: confirmacao.html,
    mailer_subjects_magic_link: magico.subject,
    mailer_templates_magic_link_content: magico.html,
    mailer_subjects_email_change: troca.subject,
    mailer_templates_email_change_content: troca.html,
  };

  // "Nenhum provedor social" é decisão de produto, e decisão de produto não
  // fica dependendo de padrão silencioso: cada provedor listado no config.toml
  // vira um `false` explícito no payload.
  for (const [nome, valor] of Object.entries(cfg?.auth?.external ?? {})) {
    payload[`external_${nome}_enabled`] =
      (valor as { enabled?: boolean })?.enabled === true;
  }

  return payload;
}

if (import.meta.main) {
  const raiz = new URL("../", import.meta.url);
  const toml = await Deno.readTextFile(new URL("supabase/config.toml", raiz));
  const payload = payloadAuth(
    toml,
    (caminho) => Deno.readTextFileSync(new URL(caminho.replace(/^\.\//, ""), raiz)),
  );
  console.log(JSON.stringify(payload));
}
