import { assert, assertEquals } from "@std/assert";

import { paginaExclusao, PRAZOS } from "./pagina.ts";

const html = paginaExclusao();

Deno.test("a página declara os três prazos da PP v0.2", () => {
  // A exigência do Google Play não é só "ter uma página": é dizer o que é
  // apagado, o que é retido e por quanto tempo. Estes três prazos são os mesmos
  // que as rotinas do banco executam — se um mudar lá e não mudar aqui, a
  // página passa a mentir para o usuário e para a loja.
  for (const prazo of Object.values(PRAZOS)) {
    assert(html.includes(prazo), `a página não menciona o prazo "${prazo}"`);
  }
});

Deno.test("a página avisa que o dado do aparelho não é apagado por aqui", () => {
  // O app é local-first: o livro-caixa nunca esteve no servidor. Excluir a
  // conta e deixar o usuário achando que o celular também foi limpo seria o
  // tipo de meia-verdade que o claim de privacidade não sobrevive.
  assert(/nunca estiveram[\s\S]{0,40}no nosso servidor/.test(html));
  assert(html.includes("desinstale o aplicativo"));
  // E que ele precisa exportar antes: a guarda de 5 anos é obrigação dele.
  assert(html.includes("cinco anos"));
});

Deno.test("a página avisa que a exclusão dos backups não tem volta", () => {
  assert(html.includes("não tem volta"));
  assert(/não há como recuperá-los/.test(html));
});

Deno.test("a página não depende de nenhum recurso externo", () => {
  // Sem CDN, sem fonte remota, sem analytics: a página precisa abrir num
  // aparelho velho e numa rede ruim, e um pedido a terceiro numa página de
  // exclusão de conta contaria a esse terceiro quem está saindo.
  const externos = html.match(/(?:src|href)\s*=\s*["']\s*(?:https?:)?\/\//gi);
  assertEquals(externos, null, `a página busca recurso externo: ${externos}`);
});

Deno.test("a página monta texto sem nenhuma escrita de HTML", () => {
  // As mensagens carregam texto que veio do servidor. Escrever HTML aqui seria
  // um caminho de injeção numa página que não tem por que ter nenhum.
  //
  // A busca é pela ESCRITA, não pela palavra: o comentário que explica a regra
  // dentro da página menciona `innerHTML` de propósito, e proibir a menção
  // faria o próprio "por quê" reprovar o teste.
  const escritas = html.match(
    /\.(?:inner|outer)HTML\s*=|insertAdjacentHTML|document\.write/g,
  );
  assertEquals(escritas, null, `a página escreve HTML: ${escritas}`);
  assert(html.includes("textContent"), "a página não usa textContent");
});

Deno.test("sem endpoint, o formulário posta na própria rota", () => {
  // É o caso de a página ser servida PELA função: um caminho fixo quebraria se
  // a rota mudasse de nome, e quebraria calado — o botão não faria nada.
  assert(html.includes("location.pathname"));
});

Deno.test("com endpoint, o formulário posta na URL absoluta", () => {
  // É o caso real: a página é servida do Cloudflare Pages, origem diferente da
  // função. Sem a URL absoluta, o `fetch` iria para o próprio Pages e o botão
  // devolveria 404 — falha que só aparece clicando.
  const alvo = "https://exemplo.supabase.co/functions/v1/excluir-conta";
  const comAlvo = paginaExclusao(alvo);

  assert(comAlvo.includes(`fetch(${JSON.stringify(alvo)}`));
  assert(!comAlvo.includes("location.pathname"));
});

Deno.test("o endpoint entra como literal JSON, não concatenado", () => {
  // O valor vai para dentro de um <script>. Interpolar cru deixaria uma aspa ou
  // um `</script>` no endereço fechar o bloco — e esta página existe para
  // apagar conta, não é lugar de descobrir injeção depois.
  const hostil = 'https://x/"+alert(1)+"';
  const gerada = paginaExclusao(hostil);

  assert(gerada.includes(JSON.stringify(hostil)));
  assert(!gerada.includes('"+alert(1)+"'));
});
