import { assert, assertEquals, assertRejects } from "@std/assert";

import {
  type ApiDeArmazenamento,
  BALDES_DO_USUARIO,
  type Dependencias,
  DURACAO_BANIMENTO,
  ehUuid,
  excluirConta,
  FalhaNaExclusao,
} from "./exclusao.ts";

const USUARIO = "6f1c6d1e-0a4e-4a1a-9c3f-2b7d5e8a1c40";

/**
 * Registrador comum aos dublês: guarda a sequência de chamadas de TODOS eles.
 *
 * A ordem dos três passos é a propriedade central deste módulo, e ela só é
 * verificável se as chamadas caírem numa linha do tempo única.
 */
type Diario = string[];

class ArmazenamentoFalso implements ApiDeArmazenamento {
  /** `balde -> prefixo -> entradas diretas`, na ordem em que serão paginadas. */
  constructor(
    private readonly arvore: Record<string, Record<string, string[]>>,
    private readonly diario: Diario,
    private readonly falharEm?: string,
  ) {}

  listarPagina(
    balde: string,
    prefixo: string,
    deslocamento: number,
    limite: number,
  ): Promise<{ nome: string; ehPasta: boolean }[]> {
    if (this.falharEm === "listar") {
      return Promise.reject(new Error("storage fora do ar"));
    }
    this.diario.push(`listar ${balde}/${prefixo} @${deslocamento}`);
    const filhos = this.arvore[balde]?.[prefixo] ?? [];
    return Promise.resolve(
      filhos.slice(deslocamento, deslocamento + limite).map((nome) => ({
        nome: nome.replace(/\/$/, ""),
        ehPasta: nome.endsWith("/"),
      })),
    );
  }

  remover(balde: string, caminhos: string[]): Promise<void> {
    if (this.falharEm === "remover") {
      return Promise.reject(new Error("storage recusou a remoção"));
    }
    this.diario.push(`remover ${balde} ${caminhos.length}`);
    for (const caminho of caminhos) this.diario.push(`  - ${caminho}`);
    return Promise.resolve();
  }
}

/** Monta as dependências com uma árvore de arquivos e falhas opcionais. */
function montar(
  arvore: Record<string, Record<string, string[]>> = {},
  falhas: { storage?: string; encerrar?: boolean; banir?: boolean } = {},
): { deps: Dependencias; diario: Diario } {
  const diario: Diario = [];
  return {
    diario,
    deps: {
      armazenamento: new ArmazenamentoFalso(arvore, diario, falhas.storage),
      conformidade: {
        encerrarConta(usuarioId) {
          if (falhas.encerrar) {
            return Promise.reject(
              new Error("ainda há 1 objeto(s) do usuário em backups"),
            );
          }
          diario.push(`encerrar ${usuarioId}`);
          return Promise.resolve();
        },
      },
      identidade: {
        banir(usuarioId, duracao) {
          if (falhas.banir) return Promise.reject(new Error("auth fora do ar"));
          diario.push(`banir ${usuarioId} ${duracao}`);
          return Promise.resolve();
        },
      },
    },
  };
}

/** Uma pasta do usuário com `quantidade` arquivos, em cada balde. */
function comArquivos(quantidade: number): Record<string, Record<string, string[]>> {
  const nomes = Array.from({ length: quantidade }, (_, i) => `arquivo-${i}.dsmb`);
  return Object.fromEntries(
    BALDES_DO_USUARIO.map((balde) => [balde, { [USUARIO]: nomes }]),
  );
}

Deno.test("os três passos acontecem na ordem obrigatória", async () => {
  const { deps, diario } = montar(comArquivos(2));

  const relatorio = await excluirConta(deps, USUARIO);

  const passos = diario.filter((l) => !l.startsWith("  "));
  // Arquivos de TODOS os baldes primeiro; encerramento depois; banimento por
  // último. Trocar a ordem é o defeito que este módulo existe para impedir.
  assertEquals(passos.at(-2), `encerrar ${USUARIO}`);
  assertEquals(passos.at(-1), `banir ${USUARIO} ${DURACAO_BANIMENTO}`);
  assert(
    passos.filter((l) => l.startsWith("remover")).length > 0,
    "nenhuma remoção aconteceu antes do encerramento",
  );
  assert(
    passos.indexOf(`encerrar ${USUARIO}`) >
      passos.findLastIndex((l) => l.startsWith("remover")),
    "o encerramento veio antes da última remoção",
  );
  assertEquals(relatorio.arquivosRemovidos, {
    "backups": 2,
    "suporte-extratos": 2,
  });
});

Deno.test("os dois baldes do usuário são varridos", async () => {
  const { deps, diario } = montar(comArquivos(1));

  await excluirConta(deps, USUARIO);

  for (const balde of BALDES_DO_USUARIO) {
    assert(
      diario.some((l) => l.startsWith(`remover ${balde} `)),
      `o balde "${balde}" não foi varrido`,
    );
  }
});

Deno.test("falha ao listar arquivos interrompe antes de encerrar e banir", async () => {
  const { deps, diario } = montar(comArquivos(1), { storage: "listar" });

  const falha = await assertRejects(
    () => excluirConta(deps, USUARIO),
    FalhaNaExclusao,
  );

  assertEquals(falha.passo, "arquivos");
  // O ponto todo: conta banida com blob vivo é o resultado que a PP v0.2
  // promete não produzir.
  assert(!diario.some((l) => l.startsWith("encerrar")));
  assert(!diario.some((l) => l.startsWith("banir")));
});

Deno.test("falha ao remover arquivos interrompe antes de encerrar e banir", async () => {
  const { deps, diario } = montar(comArquivos(1), { storage: "remover" });

  const falha = await assertRejects(
    () => excluirConta(deps, USUARIO),
    FalhaNaExclusao,
  );

  assertEquals(falha.passo, "arquivos");
  assert(!diario.some((l) => l.startsWith("encerrar")));
  assert(!diario.some((l) => l.startsWith("banir")));
});

Deno.test("recusa do banco interrompe antes do banimento", async () => {
  // É o caso real de a varredura ter deixado objeto para trás: o banco recusa,
  // e o usuário NÃO pode terminar banido com o arquivo dele retido.
  const { deps, diario } = montar(comArquivos(1), { encerrar: true });

  const falha = await assertRejects(
    () => excluirConta(deps, USUARIO),
    FalhaNaExclusao,
  );

  assertEquals(falha.passo, "encerramento");
  assert(!diario.some((l) => l.startsWith("banir")));
});

Deno.test("falha ao banir é reportada, e não engolida", async () => {
  // Aqui a conta JÁ foi encerrada e os arquivos JÁ sumiram — mas uma sessão
  // aberta pode ter sobrado. Devolver sucesso esconderia isso de quem opera.
  const { deps } = montar(comArquivos(1), { banir: true });

  const falha = await assertRejects(
    () => excluirConta(deps, USUARIO),
    FalhaNaExclusao,
  );

  assertEquals(falha.passo, "banimento");
});

Deno.test("pasta com mais de uma página é varrida inteira", async () => {
  // Sem paginação, a varredura levaria só os 100 primeiros e o banco recusaria
  // o encerramento — falha visível, mas com a conta impossível de excluir.
  const total = 250;
  const { deps, diario } = montar(comArquivos(total));

  const relatorio = await excluirConta(deps, USUARIO);

  assertEquals(relatorio.arquivosRemovidos["backups"], total);
  const removidosEmBackups = diario
    .filter((l) => l.startsWith("remover backups "))
    .map((l) => Number(l.split(" ").at(-1)));
  assertEquals(removidosEmBackups.reduce((a, b) => a + b, 0), total);
  assert(
    removidosEmBackups.every((n) => n <= 100),
    "um lote de remoção passou de 100 caminhos",
  );
});

Deno.test("objeto em subpasta também é apagado", async () => {
  // encerrar_conta conta por (storage.foldername(name))[1], em QUALQUER
  // profundidade. Varrer só o primeiro nível deixaria a conta inencerrável.
  const { deps, diario } = montar({
    "backups": {
      [USUARIO]: ["antigos/", "atual.dsmb"],
      [`${USUARIO}/antigos`]: ["2025.dsmb"],
    },
    "suporte-extratos": {},
  });

  const relatorio = await excluirConta(deps, USUARIO);

  assertEquals(relatorio.arquivosRemovidos["backups"], 2);
  assert(diario.includes(`  - ${USUARIO}/antigos/2025.dsmb`));
  // Pasta não é objeto: apagar o "arquivo" antigos/ devolveria erro do storage.
  assert(!diario.includes(`  - ${USUARIO}/antigos`));
});

Deno.test("aninhamento absurdo falha em vez de virar recursão infinita", async () => {
  // A listagem é dado vindo de fora. Truncar em silêncio deixaria objeto
  // retido — o oposto do que o fluxo promete.
  const arvore: Record<string, string[]> = {};
  let caminho = USUARIO;
  for (let i = 0; i < 12; i++) {
    arvore[caminho] = ["fundo/"];
    caminho = `${caminho}/fundo`;
  }
  const { deps, diario } = montar({ "backups": arvore, "suporte-extratos": {} });

  const falha = await assertRejects(
    () => excluirConta(deps, USUARIO),
    FalhaNaExclusao,
  );

  assertEquals(falha.passo, "arquivos");
  assert(!diario.some((l) => l.startsWith("encerrar")));
});

Deno.test("conta sem nenhum arquivo é encerrada normalmente", async () => {
  // Caminho do usuário que nunca fez backup — e também da segunda tentativa,
  // depois de uma primeira que falhou no banimento.
  const { deps, diario } = montar({});

  const relatorio = await excluirConta(deps, USUARIO);

  assertEquals(relatorio.arquivosRemovidos, {
    "backups": 0,
    "suporte-extratos": 0,
  });
  assert(!diario.some((l) => l.startsWith("remover")));
  assert(diario.includes(`encerrar ${USUARIO}`));
  assert(diario.includes(`banir ${USUARIO} ${DURACAO_BANIMENTO}`));
});

Deno.test("identificador fora do formato não vira prefixo de caminho", async () => {
  // O id vira prefixo na Storage API e argumento de SQL. Um valor inesperado
  // não pode chegar lá e acabar listando a pasta de outra pessoa.
  for (const invalido of ["", "..", "*", `${USUARIO}/..`, "outro-usuario"]) {
    const { deps, diario } = montar(comArquivos(1));
    const falha = await assertRejects(
      () => excluirConta(deps, invalido),
      FalhaNaExclusao,
    );
    assertEquals(falha.passo, "arquivos");
    assertEquals(diario, [], `"${invalido}" chegou a tocar no armazenamento`);
  }
});

Deno.test("ehUuid aceita o formato do auth.users e recusa o resto", () => {
  assert(ehUuid(USUARIO));
  assert(ehUuid(USUARIO.toUpperCase()));
  assert(!ehUuid(USUARIO.slice(0, -1)));
  assert(!ehUuid(`${USUARIO} `));
  assert(!ehUuid(`${USUARIO}/x`));
});
