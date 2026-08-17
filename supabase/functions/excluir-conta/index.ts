/**
 * Exclusão de conta — a função que o app e a página web chamam.
 *
 * Duas portas de entrada, um só caminho de exclusão:
 *
 *   • **App** — `POST` com `Authorization: Bearer <token da sessão>` e
 *     `{"acao":"excluir"}`. A sessão já prova quem é.
 *   • **Web** — a página em `GET` pede o e-mail, o servidor manda um código, e
 *     `{"acao":"confirmar"}` troca o código pela identidade. O Google Play
 *     exige esse caminho: quem trocou de celular ou já desinstalou o app
 *     precisa conseguir excluir a conta mesmo assim.
 *
 * Quem executa é `_compartilhado/exclusao.ts`, onde a ordem obrigatória dos
 * três passos está isolada do HTTP e coberta por teste. Este arquivo faz só o
 * que depende de rede: descobrir de quem é a conta e ligar os adaptadores.
 *
 * ⚠️ Esta função roda SEM verificação automática de JWT (a página precisa abrir
 * no navegador de quem não tem sessão). Logo, toda rota aqui é pública, e cada
 * uma tem de provar por si de quem é a conta antes de apagar qualquer coisa.
 * Ver `supabase/operacao/publicacao.md`.
 */

import { createClient } from "@supabase/supabase-js";

import {
  type ApiDeArmazenamento,
  type Dependencias,
  excluirConta,
  FalhaNaExclusao,
} from "../_compartilhado/exclusao.ts";
import { paginaExclusao } from "../_compartilhado/pagina.ts";

// ─── Ambiente ────────────────────────────────────────────────────────────────

/**
 * Lê a variável, aceitando o nome novo e o antigo.
 *
 * Projetos criados em épocas diferentes expõem a chave pública como
 * `PUBLISHABLE_KEY` ou como `ANON_KEY`, e a secreta como `SECRET_KEY` ou
 * `SERVICE_ROLE_KEY`. Aceitar os dois evita que a função morra em produção por
 * um detalhe de nomenclatura da plataforma.
 */
function variavel(...nomes: string[]): string {
  for (const nome of nomes) {
    const valor = Deno.env.get(nome);
    if (valor) return valor;
  }
  // Falha no arranque, e não na primeira exclusão pela metade.
  throw new Error(`variável de ambiente ausente: ${nomes.join(" ou ")}`);
}

const URL_DO_PROJETO = variavel("SUPABASE_URL");
const CHAVE_PUBLICA = variavel("SUPABASE_PUBLISHABLE_KEY", "SUPABASE_ANON_KEY");
const CHAVE_SECRETA = variavel("SUPABASE_SECRET_KEY", "SUPABASE_SERVICE_ROLE_KEY");

const semSessao = { auth: { persistSession: false, autoRefreshToken: false } };

/** Cliente com `service_role`: apaga arquivo, encerra conta e bane. */
const administrador = createClient(URL_DO_PROJETO, CHAVE_SECRETA, semSessao);

/** Cliente público: só serve para mandar e conferir o código de e-mail. */
const publico = createClient(URL_DO_PROJETO, CHAVE_PUBLICA, semSessao);

// ─── Adaptadores ─────────────────────────────────────────────────────────────

const armazenamento: ApiDeArmazenamento = {
  async listarPagina(balde, prefixo, deslocamento, limite) {
    const { data, error } = await administrador.storage
      .from(balde)
      .list(prefixo, { limit: limite, offset: deslocamento });
    if (error) throw error;
    // Pasta vem sem `id` na listagem da Storage API — é o que separa "objeto
    // para apagar" de "prefixo para percorrer".
    return (data ?? []).map((e) => ({ nome: e.name, ehPasta: e.id === null }));
  },

  async remover(balde, caminhos) {
    const { error } = await administrador.storage.from(balde).remove(caminhos);
    if (error) throw error;
  },
};

const dependencias: Dependencias = {
  armazenamento,
  conformidade: {
    async encerrarConta(usuarioId) {
      // Porta estreita em `public`: o PostgREST não enxerga o schema
      // `conformidade`. Ver 20260817010000_rpc_encerrar_conta.sql.
      const { error } = await administrador.rpc("encerrar_conta_do_usuario", {
        p_usuario: usuarioId,
      });
      if (error) throw error;
    },
  },
  identidade: {
    async banir(usuarioId, duracao) {
      const { error } = await administrador.auth.admin.updateUserById(
        usuarioId,
        { ban_duration: duracao },
      );
      if (error) throw error;
    },
  },
};

// ─── HTTP ────────────────────────────────────────────────────────────────────

const CORS = {
  // Liberado de propósito: nenhuma rota aqui entrega nada a quem não trouxer
  // um código de e-mail válido ou um token de sessão válido. Restringir origem
  // não acrescentaria garantia, e atrapalharia builds web e de depuração.
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

function json(corpo: unknown, status = 200): Response {
  return new Response(JSON.stringify(corpo), {
    status,
    headers: { ...CORS, "content-type": "application/json; charset=utf-8" },
  });
}

function erro(mensagem: string, status: number): Response {
  return json({ ok: false, mensagem }, status);
}

Deno.serve(async (requisicao) => {
  if (requisicao.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS });
  }

  if (requisicao.method === "GET") {
    return new Response(paginaExclusao(), {
      headers: {
        ...CORS,
        "content-type": "text/html; charset=utf-8",
        // A página é um formulário de ação irreversível: uma versão velha em
        // cache poderia postar num contrato que mudou.
        "cache-control": "no-store",
        "x-content-type-options": "nosniff",
        "referrer-policy": "no-referrer",
      },
    });
  }

  if (requisicao.method !== "POST") {
    return erro("Método não suportado.", 405);
  }

  let corpo: Record<string, unknown>;
  try {
    corpo = await requisicao.json();
  } catch {
    return erro("Corpo da requisição inválido.", 400);
  }

  switch (corpo.acao) {
    case "enviar-codigo":
      return await enviarCodigo(texto(corpo.email));
    case "confirmar":
      return await confirmarEExcluir(texto(corpo.email), texto(corpo.codigo));
    case "excluir":
      return await excluirPelaSessao(requisicao.headers.get("authorization"));
    default:
      return erro("Ação desconhecida.", 400);
  }
});

function texto(valor: unknown): string {
  return typeof valor === "string" ? valor.trim() : "";
}

/**
 * Manda o código para o e-mail — se, e só se, já existir conta com ele.
 *
 * `shouldCreateUser: false` não é detalhe: sem ele, digitar um e-mail sem conta
 * nesta página CRIARIA a conta que a pessoa veio excluir.
 */
async function enviarCodigo(email: string): Promise<Response> {
  // Resposta única, dê no que der. Esta página é pública e indexável por quem
  // quiser: se ela respondesse diferente para e-mail com e sem conta, viraria
  // um consultor de quem é cliente do Desmalha — e a lista de clientes de um
  // app de imposto não é informação neutra.
  const neutra = json({
    ok: true,
    mensagem: "Se houver uma conta com esse e-mail, o código foi enviado.",
  });

  if (!email) return neutra;

  const { error } = await publico.auth.signInWithOtp({
    email,
    options: { shouldCreateUser: false },
  });
  // Só o excesso de tentativas é dito em voz alta: ele não revela se a conta
  // existe, e calá-lo deixaria o usuário repetindo um envio que não vai sair.
  if (error?.code === "over_email_send_rate_limit") {
    return erro("Muitas tentativas seguidas. Aguarde alguns minutos.", 429);
  }
  if (error) console.warn("envio de código recusado:", error.code ?? error.name);
  return neutra;
}

/** Troca o código pela identidade e executa a exclusão. */
async function confirmarEExcluir(
  email: string,
  codigo: string,
): Promise<Response> {
  if (!email || !codigo) {
    return erro("Informe o e-mail e o código recebido.", 400);
  }

  const { data, error } = await publico.auth.verifyOtp({
    email,
    token: codigo,
    type: "email",
  });
  const usuario = data?.user;
  if (error || !usuario) {
    // Mensagem única para código errado, expirado e já usado: distinguir os
    // três ajudaria mais quem está tentando adivinhar do que quem digitou torto.
    return erro("Código inválido ou expirado. Peça um novo.", 401);
  }

  return await executar(usuario.id);
}

/** Caminho do app: a sessão em curso já diz de quem é a conta. */
async function excluirPelaSessao(
  autorizacao: string | null,
): Promise<Response> {
  const token = autorizacao?.replace(/^Bearer\s+/i, "").trim();
  if (!token) return erro("Entre na sua conta para continuar.", 401);

  // Valida o token contra o servidor de auth. A chave pública do projeto também
  // chega neste cabeçalho em alguns clientes; ela não resolve para usuário
  // nenhum e cai aqui como não autenticada, que é o desejado.
  const { data, error } = await administrador.auth.getUser(token);
  if (error || !data?.user) {
    return erro("Sua sessão terminou. Entre de novo.", 401);
  }

  return await executar(data.user.id);
}

async function executar(usuarioId: string): Promise<Response> {
  try {
    const relatorio = await excluirConta(dependencias, usuarioId);
    // Só o id e as contagens: e-mail é dado pessoal e não vai para log, mesma
    // regra que vale para breadcrumb do Sentry.
    console.info("conta excluída", usuarioId, relatorio.arquivosRemovidos);
    return json({ ok: true, mensagem: "Conta excluída." });
  } catch (falha) {
    if (falha instanceof FalhaNaExclusao) {
      console.error(`exclusão parou em "${falha.passo}"`, usuarioId, falha.causa);
      // 500 mesmo quando a culpa é de um blob que não saiu: do ponto de vista
      // de quem pediu, a exclusão não aconteceu, e dizer que aconteceu seria a
      // única resposta pior do que falhar.
      return erro(
        "Não foi possível concluir a exclusão agora. Nada foi dado como " +
          "excluído. Tente de novo em alguns minutos.",
        500,
      );
    }
    console.error("falha inesperada na exclusão", usuarioId, falha);
    return erro("Não foi possível concluir a exclusão agora.", 500);
  }
}
