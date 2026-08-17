/**
 * Sincroniza o catálogo versionado do repositório com `public.catalogo_itens`.
 *
 * A FONTE DA VERDADE são os arquivos do repositório:
 *
 *   packages/desmalha_core/catalogo/<tipo>/<id>.json
 *   packages/desmalha_core/perfis/<id>.json          (tipo perfil_csv)
 *
 * Este script não conecta em nada: EMITE SQL no stdout, e é o psql do
 * workflow quem executa — mesmo desenho do `auth_para_api.ts`, que monta o
 * payload e deixa o `curl` falar com a API. Dois modos:
 *
 *   --sql-publicar   upsert de cada item + remoção do que saiu do repo,
 *                    numa transação só. `publicado_em` só avança quando o
 *                    conteúdo de fato mudou.
 *   --sql-conferir   DO block que LÊ DE VOLTA e levanta exceção se o banco
 *                    não ficou exatamente como o repositório. Roda numa
 *                    conexão separada, depois do commit: "o psql saiu com 0"
 *                    diz que o pedido foi aceito, não que o projeto ficou
 *                    como se queria — a lição do SMTP, três vezes.
 *
 * A validação daqui espelha os CHECKs da migration do catálogo (formato de
 * tipo e id, id do arquivo = id do conteúdo) para reprovar ANTES de tocar no
 * banco, com mensagem que aponta o arquivo. O schema semântico de cada tipo
 * (faixas crescentes, datas válidas...) é provado pelo teste Dart
 * `packages/desmalha_core/test/catalogo/catalogo_test.dart`, que carrega
 * estes mesmos arquivos.
 */

/** Uma linha de `catalogo_itens` a publicar. */
export interface ItemCatalogo {
  tipo: string;
  id: string;
  /** JSON canônico (uma linha) do conteúdo. */
  conteudo: string;
}

const RE_TIPO = /^[a-z][a-z0-9_]*$/;
const RE_ID = /^[a-z0-9][a-z0-9-]*$/;

/** Valida e canoniza um arquivo do catálogo. Lança `Error` nomeando o alvo. */
export function itemDeArquivo(
  tipo: string,
  nomeArquivo: string,
  texto: string,
): ItemCatalogo {
  if (!nomeArquivo.endsWith(".json")) {
    throw new Error(`${nomeArquivo}: esperado arquivo .json`);
  }
  const id = nomeArquivo.slice(0, -".json".length);
  if (!RE_TIPO.test(tipo)) {
    throw new Error(`tipo "${tipo}" fora do formato [a-z][a-z0-9_]*`);
  }
  if (!RE_ID.test(id)) {
    throw new Error(
      `${nomeArquivo}: id "${id}" fora do formato [a-z0-9][a-z0-9-]*`,
    );
  }
  let dado: unknown;
  try {
    dado = JSON.parse(texto);
  } catch (erro) {
    throw new Error(`${tipo}/${nomeArquivo}: JSON inválido — ${erro}`);
  }
  if (dado === null || typeof dado !== "object" || Array.isArray(dado)) {
    throw new Error(`${tipo}/${nomeArquivo}: o conteúdo precisa ser objeto`);
  }
  const idDoConteudo = (dado as Record<string, unknown>).id;
  if (idDoConteudo !== id) {
    throw new Error(
      `${tipo}/${nomeArquivo}: o campo "id" do conteúdo é ` +
        `${JSON.stringify(idDoConteudo)}, mas o nome do arquivo diz "${id}" — ` +
        `o catálogo mentiria sobre o que serve`,
    );
  }
  return { tipo, id, conteudo: JSON.stringify(dado) };
}

/** Lê o manifesto inteiro do repositório. */
export function coletarItens(raiz: string): ItemCatalogo[] {
  const itens: ItemCatalogo[] = [];

  const lerDiretorio = (caminho: string, tipo: string) => {
    const nomes: string[] = [];
    for (const entrada of Deno.readDirSync(caminho)) {
      if (entrada.isFile && entrada.name.endsWith(".json")) {
        nomes.push(entrada.name);
      }
    }
    nomes.sort();
    for (const nome of nomes) {
      itens.push(
        itemDeArquivo(
          tipo,
          nome,
          Deno.readTextFileSync(`${caminho}/${nome}`),
        ),
      );
    }
  };

  const base = `${raiz}/packages/desmalha_core/catalogo`;
  const tipos: string[] = [];
  for (const entrada of Deno.readDirSync(base)) {
    if (entrada.isDirectory) tipos.push(entrada.name);
  }
  tipos.sort();
  for (const tipo of tipos) lerDiretorio(`${base}/${tipo}`, tipo);

  lerDiretorio(`${raiz}/packages/desmalha_core/perfis`, "perfil_csv");

  if (itens.length === 0) {
    throw new Error(
      "nenhum item de catálogo encontrado — o manifesto vazio apagaria o " +
        "catálogo inteiro do projeto, e isso não pode acontecer por acidente",
    );
  }
  return itens;
}

/** Escapa para literal SQL padrão (aspas simples dobradas). */
function sql(texto: string): string {
  return `'${texto.replaceAll("'", "''")}'`;
}

/** SQL que sincroniza o banco com o manifesto, numa transação. */
export function sqlPublicar(itens: ItemCatalogo[]): string {
  if (itens.length === 0) {
    // O DELETE final varreria a tabela inteira. `coletarItens` já recusa
    // manifesto vazio; esta é a mesma trava para quem chamar direto.
    throw new Error("recusado: publicar manifesto vazio apagaria o catálogo");
  }
  const linhas: string[] = ["begin;"];
  for (const item of itens) {
    linhas.push(
      `insert into public.catalogo_itens (tipo, id, conteudo)`,
      `values (${sql(item.tipo)}, ${sql(item.id)}, ${sql(item.conteudo)}::jsonb)`,
      `on conflict (tipo, id) do update`,
      `  set conteudo = excluded.conteudo, publicado_em = now()`,
      // Republicar o mesmo conteúdo não é publicação: sem este WHERE, todo
      // push avançaria publicado_em e o carimbo deixaria de dizer algo.
      `  where public.catalogo_itens.conteudo is distinct from excluded.conteudo;`,
    );
  }
  const chaves = itens
    .map((i) => `(${sql(i.tipo)}, ${sql(i.id)})`)
    .join(",\n    ");
  linhas.push(
    // O repositório é a fonte da verdade também para o que NÃO existe mais:
    // item removido do repo sai do banco, senão o app antigo seguiria
    // baixando conteúdo que ninguém mantém.
    `delete from public.catalogo_itens`,
    ` where (tipo, id) not in (`,
    `    ${chaves}`,
    ` );`,
    "commit;",
  );
  return linhas.join("\n") + "\n";
}

/** SQL que lê de volta e levanta exceção se o banco diverge do manifesto. */
export function sqlConferir(itens: ItemCatalogo[]): string {
  const corpo: string[] = [
    "do $dsm_catalogo$",
    "declare",
    "  v_n     integer;",
    "  v_atual jsonb;",
    "begin",
    "  select count(*) into v_n from public.catalogo_itens;",
    `  if v_n <> ${itens.length} then`,
    `    raise exception 'catálogo com % itens no banco; o repositório tem ${itens.length}', v_n;`,
    "  end if;",
  ];
  for (const item of itens) {
    corpo.push(
      `  select conteudo into v_atual from public.catalogo_itens`,
      `   where tipo = ${sql(item.tipo)} and id = ${sql(item.id)};`,
      `  if v_atual is null then`,
      `    raise exception 'item ${item.tipo}/${item.id} ausente do banco';`,
      `  end if;`,
      `  if v_atual <> ${sql(item.conteudo)}::jsonb then`,
      `    raise exception 'item ${item.tipo}/${item.id} divergente do repositório';`,
      `  end if;`,
    );
  }
  corpo.push("end;", "$dsm_catalogo$;");
  const saida = corpo.join("\n") + "\n";
  // O corpo do DO é dollar-quoted: conteúdo com a tag dentro quebraria a
  // citação. Nenhum JSON do catálogo tem por que conter isso — reprovar aqui
  // é mais claro do que um erro de sintaxe do psql.
  if (saida.split("$dsm_catalogo$").length !== 3) {
    throw new Error(
      "conteúdo de item contém a tag $dsm_catalogo$ — renomeie o conteúdo",
    );
  }
  return saida;
}

if (import.meta.main) {
  const modo = Deno.args[0];
  const itens = coletarItens(".");
  if (modo === "--sql-publicar") {
    console.log(sqlPublicar(itens));
  } else if (modo === "--sql-conferir") {
    console.log(sqlConferir(itens));
  } else {
    console.error(
      "uso: deno run --allow-read tool/publicar_catalogo.ts --sql-publicar | --sql-conferir",
    );
    Deno.exit(2);
  }
}
