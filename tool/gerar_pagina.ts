/**
 * Gera `site/index.html` — a página pública de exclusão de conta.
 *
 * POR QUE EXISTE UM ARQUIVO GERADO E VERSIONADO
 *
 * A página não pode ser servida pela edge function: o gateway do Supabase
 * reescreve `text/html` para `text/plain` e injeta uma CSP de sandbox, então
 * quem abre o link vê o código-fonte (ver `supabase/operacao/publicacao.md`).
 * Ela precisa de hospedagem própria — Cloudflare Pages, no caso.
 *
 * O Cloudflare Pages serve uma pasta. Poderia rodar um build, mas a imagem de
 * build dele tem Node e não Deno, e trocar o gerador de linguagem para caber
 * na esteira de terceiro é deixar a ferramenta escolher a arquitetura. Então o
 * HTML é gerado aqui, versionado em `site/`, e o Pages serve estático, sem
 * build nenhum.
 *
 * ⚠️ Arquivo gerado que se commita apodrece calado quando alguém edita o
 * gerador e esquece de rodar. Por isso o CI regenera e **reprova se divergir**
 * (`tool/testar_edge.sh`). Não edite `site/index.html` à mão: edite
 * `supabase/functions/_compartilhado/pagina.ts` e rode este script.
 *
 *   deno run --allow-read --allow-write tool/gerar_pagina.ts
 *   deno run --allow-read tool/gerar_pagina.ts --conferir
 */

import { paginaExclusao } from "../supabase/functions/_compartilhado/pagina.ts";

/**
 * Para onde o formulário posta.
 *
 * É o `desmalha-dev` porque é o único projeto que existe hoje. Quando houver
 * produção, ela ganha um projeto do Pages próprio, gerado deste mesmo arquivo
 * com o ref de lá — e é a URL de produção que vai para a ficha do Google Play.
 * Deixar isso explícito num arquivo versionado é melhor do que descobrir, no
 * dia da submissão, que a página da loja fala com o banco de desenvolvimento.
 */
const ENDPOINT =
  "https://caqxssmxeiuutfguxdzj.supabase.co/functions/v1/excluir-conta";

const DESTINO = new URL("../site/index.html", import.meta.url);

const html = paginaExclusao(ENDPOINT);

if (Deno.args.includes("--conferir")) {
  const atual = await Deno.readTextFile(DESTINO).catch(() => "");
  if (atual !== html) {
    console.error(
      "site/index.html está desatualizado em relação a pagina.ts.\n" +
        "Rode: deno run --allow-read --allow-write tool/gerar_pagina.ts",
    );
    Deno.exit(1);
  }
  console.log("site/index.html está em dia com pagina.ts");
} else {
  await Deno.mkdir(new URL("../site/", import.meta.url), { recursive: true });
  await Deno.writeTextFile(DESTINO, html);
  console.log(`site/index.html gerado (${html.length} bytes)`);
}
