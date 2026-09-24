import { assertEquals, assertRejects } from "@std/assert";

import {
  BALDE_SUPORTE,
  type DependenciasDoExpurgo,
  type EnvioVencido,
  expurgarEnviosSuporte,
  ExpurgoIncompleto,
  TAMANHO_DO_LOTE,
} from "./expurgo_suporte.ts";

/**
 * Um bucket e um banco de mentira que se comportam como os de verdade no que
 * importa: o banco só confirma o que sumiu do bucket.
 */
function mundo(vencidos: EnvioVencido[], opcoes: {
  storageMente?: boolean;
  removerFalha?: boolean;
} = {}) {
  const noBucket = new Set(vencidos.map((v) => v.path));
  let pendentes = [...vencidos];
  const chamadas: string[] = [];
  const lotes: string[][] = [];

  const dep: DependenciasDoExpurgo = {
    listarVencidos() {
      chamadas.push("listar");
      return Promise.resolve([...pendentes]);
    },
    remover(balde, caminhos) {
      chamadas.push(`remover:${balde}`);
      lotes.push(caminhos);
      if (opcoes.removerFalha) return Promise.reject(new Error("storage 500"));
      // "storageMente": responde OK e não apaga — o caso 2xx ≠ feito.
      if (!opcoes.storageMente) for (const c of caminhos) noBucket.delete(c);
      return Promise.resolve();
    },
    confirmar() {
      chamadas.push("confirmar");
      const antes = pendentes.length;
      pendentes = pendentes.filter((v) => noBucket.has(v.path));
      return Promise.resolve(antes - pendentes.length);
    },
  };
  return { dep, chamadas, lotes };
}

const envio = (n: number): EnvioVencido => ({
  id: `id-${n}`,
  path: `11111111-1111-4111-8111-111111111111/extrato-${n}.ofx`,
});

Deno.test("nada vencido: não chama a Storage API, só confirma e relê", async () => {
  const { dep, chamadas } = mundo([]);
  assertEquals(await expurgarEnviosSuporte(dep), { vencidos: 0, confirmados: 0 });
  assertEquals(chamadas, ["listar", "confirmar", "listar"]);
});

Deno.test("vencidos: remove no bucket certo, ANTES de confirmar", async () => {
  const { dep, chamadas, lotes } = mundo([envio(1), envio(2)]);
  assertEquals(await expurgarEnviosSuporte(dep), { vencidos: 2, confirmados: 2 });
  assertEquals(chamadas, [
    "listar",
    `remover:${BALDE_SUPORTE}`,
    "confirmar",
    "listar",
  ]);
  assertEquals(lotes, [[envio(1).path, envio(2).path]]);
});

Deno.test("2xx da Storage API sem o arquivo sumir FALHA — o banco é a testemunha", async () => {
  const { dep } = mundo([envio(1), envio(2)], { storageMente: true });
  const erro = await assertRejects(
    () => expurgarEnviosSuporte(dep),
    ExpurgoIncompleto,
  );
  assertEquals(erro.pendentes, 2);
  assertEquals(erro.resultado, { vencidos: 2, confirmados: 0 });
});

Deno.test("falha na remoção interrompe antes da confirmação", async () => {
  const { dep, chamadas } = mundo([envio(1)], { removerFalha: true });
  await assertRejects(() => expurgarEnviosSuporte(dep), Error, "storage 500");
  assertEquals(chamadas, ["listar", `remover:${BALDE_SUPORTE}`]);
});

Deno.test("remove em lotes, sem perder nem repetir caminho", async () => {
  const total = TAMANHO_DO_LOTE * 2 + 7;
  const todos = Array.from({ length: total }, (_, i) => envio(i));
  const { dep, lotes } = mundo(todos);
  assertEquals(await expurgarEnviosSuporte(dep), {
    vencidos: total,
    confirmados: total,
  });
  assertEquals(lotes.map((l) => l.length), [TAMANHO_DO_LOTE, TAMANHO_DO_LOTE, 7]);
  assertEquals(lotes.flat(), todos.map((e) => e.path));
});
