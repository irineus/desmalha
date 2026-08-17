/**
 * Testes do publicador do catálogo (`tool/publicar_catalogo.ts`).
 *
 * O teste roda com --allow-read e carrega o MANIFESTO REAL do repositório —
 * o mesmo que o workflow publica — em vez de cópias inline que divergem
 * caladas. A validação semântica de cada tipo (faixas, datas, colunas) é do
 * teste Dart em packages/desmalha_core/test/catalogo/; aqui se prova o que é
 * do publicador: coleta, canonização, escape e as duas saídas SQL.
 */

import {
  assertEquals,
  assertStringIncludes,
  assertThrows,
} from "@std/assert";
import {
  coletarItens,
  itemDeArquivo,
  sqlConferir,
  sqlPublicar,
} from "../../../tool/publicar_catalogo.ts";

const RAIZ = new URL("../../..", import.meta.url).pathname.replace(/\/$/, "");

Deno.test("coleta o manifesto real: perfis + tabela IRPF + feriados", () => {
  const itens = coletarItens(RAIZ);
  const chaves = itens.map((i) => `${i.tipo}/${i.id}`);
  assertEquals(chaves, [
    "feriados_bancarios/feriados-bancarios-2026",
    "tabela_irpf/irpf-mensal-2026-01",
    "perfil_csv/bb-conta-csv-v1",
    "perfil_csv/inter-conta-csv-v1",
    "perfil_csv/nubank-conta-csv-v1",
  ]);
});

Deno.test("nome de arquivo divergente do id do conteúdo é recusado", () => {
  assertThrows(
    () => itemDeArquivo("tabela_irpf", "um-nome.json", '{"id": "outro"}'),
    Error,
    "mentiria",
  );
});

Deno.test("tipo e id fora do formato do banco são recusados aqui, antes", () => {
  assertThrows(() =>
    itemDeArquivo("Tipo Errado", "x.json", '{"id": "x"}')
  );
  assertThrows(() =>
    itemDeArquivo("perfil_csv", "Maiusculo.json", '{"id": "Maiusculo"}')
  );
});

Deno.test("JSON inválido e não-objeto são recusados nomeando o arquivo", () => {
  assertThrows(() => itemDeArquivo("perfil_csv", "a.json", "{quebrado"), Error, "a.json");
  assertThrows(() => itemDeArquivo("perfil_csv", "a.json", "[1]"), Error, "objeto");
});

Deno.test("aspas simples no conteúdo saem dobradas no SQL", () => {
  const item = itemDeArquivo(
    "feriados_bancarios",
    "feriados-bancarios-2027.json",
    JSON.stringify({
      id: "feriados-bancarios-2027",
      ano: 2027,
      fonte: "comunicado 'oficial' da FEBRABAN",
      datas: ["2027-01-01"],
    }),
  );
  const sql = sqlPublicar([item]);
  assertStringIncludes(sql, "comunicado ''oficial'' da FEBRABAN");
  // Toda linha de INSERT precisa manter as aspas balanceadas — é o que o
  // escape existe para garantir, e é verificável contando.
  for (const linha of sql.split("\n")) {
    assertEquals(
      (linha.match(/'/g) ?? []).length % 2,
      0,
      `aspas desbalanceadas em: ${linha}`,
    );
  }
});

Deno.test("publicar: upsert idempotente e remoção do que saiu do repo", () => {
  const itens = coletarItens(RAIZ);
  const sql = sqlPublicar(itens);
  assertStringIncludes(sql, "begin;");
  assertStringIncludes(sql, "commit;");
  assertStringIncludes(sql, "on conflict (tipo, id) do update");
  // publicado_em só avança quando o conteúdo mudou de verdade.
  assertStringIncludes(
    sql,
    "where public.catalogo_itens.conteudo is distinct from excluded.conteudo",
  );
  assertStringIncludes(sql, "delete from public.catalogo_itens");
  assertEquals(sql.match(/insert into/g)?.length, itens.length);
});

Deno.test("publicar manifesto vazio é recusado — apagaria o catálogo", () => {
  assertThrows(() => sqlPublicar([]), Error, "vazio");
});

Deno.test("conferir: conta, exige cada item e compara o conteúdo", () => {
  const itens = coletarItens(RAIZ);
  const sql = sqlConferir(itens);
  assertStringIncludes(sql, `if v_n <> ${itens.length} then`);
  for (const item of itens) {
    assertStringIncludes(sql, `'item ${item.tipo}/${item.id} ausente`);
    assertStringIncludes(sql, `'item ${item.tipo}/${item.id} divergente`);
  }
  assertEquals(sql.match(/raise exception/g)!.length, 1 + itens.length * 2);
});

Deno.test("conferir recusa conteúdo que quebraria a citação do DO", () => {
  assertThrows(
    () =>
      sqlConferir([
        {
          tipo: "perfil_csv",
          id: "x",
          conteudo: '{"id":"x","nota":"$dsm_catalogo$"}',
        },
      ]),
    Error,
    "tag",
  );
});
