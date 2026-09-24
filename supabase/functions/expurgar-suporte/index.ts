/**
 * Expurgo dos 30 dias de `envios_suporte` — chamada diária do pg_cron.
 *
 * Agendada em `supabase/pos_deploy/20_agendamento_expurgo.sql` (pg_cron +
 * pg_net). A ordem e a regra "o banco é a testemunha" estão em
 * `_compartilhado/expurgo_suporte.ts`, cobertas por teste; aqui só se ligam
 * os adaptadores.
 *
 * ⚠️ Roda SEM verificação de JWT (config.toml): o pg_net chama sem sessão, e
 * guardar uma chave no banco só para isto seria segredo novo onde não
 * precisa. É seguro porque a função não recebe NADA de quem chama — não lê
 * corpo nem parâmetro — e só executa o que já venceu pelo relógio do banco.
 * Quem a chamar antes da hora só antecipa uma limpeza que já era devida. A
 * resposta traz contagens, nunca caminhos de arquivo.
 */

import { createClient } from "@supabase/supabase-js";

import {
  type DependenciasDoExpurgo,
  expurgarEnviosSuporte,
  ExpurgoIncompleto,
} from "../_compartilhado/expurgo_suporte.ts";

function variavel(...nomes: string[]): string {
  for (const nome of nomes) {
    const valor = Deno.env.get(nome);
    if (valor) return valor;
  }
  throw new Error(`variável de ambiente ausente: ${nomes.join(" ou ")}`);
}

const administrador = createClient(
  variavel("SUPABASE_URL"),
  variavel("SUPABASE_SECRET_KEY", "SUPABASE_SERVICE_ROLE_KEY"),
  { auth: { persistSession: false, autoRefreshToken: false } },
);

const dependencias: DependenciasDoExpurgo = {
  async listarVencidos() {
    const { data, error } = await administrador.rpc("envios_suporte_vencidos");
    if (error) throw error;
    return (data ?? []) as { id: string; path: string }[];
  },
  async remover(balde, caminhos) {
    const { error } = await administrador.storage.from(balde).remove(caminhos);
    if (error) throw error;
  },
  async confirmar() {
    const { data, error } = await administrador.rpc(
      "confirmar_expurgo_envios_suporte",
    );
    if (error) throw error;
    return Number(data ?? 0);
  },
};

function json(corpo: unknown, status = 200): Response {
  return new Response(JSON.stringify(corpo), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

Deno.serve(async (requisicao) => {
  if (requisicao.method !== "POST") {
    return json({ ok: false, mensagem: "Método não suportado." }, 405);
  }
  try {
    const resultado = await expurgarEnviosSuporte(dependencias);
    console.log(`expurgo de envios ao suporte: ${JSON.stringify(resultado)}`);
    return json({ ok: true, ...resultado });
  } catch (erro) {
    // 500 fica em net._http_response e no log da função: falha visível.
    if (erro instanceof ExpurgoIncompleto) {
      console.error(erro.message);
      return json({ ok: false, pendentes: erro.pendentes, ...erro.resultado }, 500);
    }
    console.error(`expurgo de envios ao suporte falhou: ${erro}`);
    return json({ ok: false, mensagem: "falha no expurgo" }, 500);
  }
});
