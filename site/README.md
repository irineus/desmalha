# A página pública de exclusão de conta

`index.html` é **gerado** de
[`supabase/functions/_compartilhado/pagina.ts`](../supabase/functions/_compartilhado/pagina.ts).
Não edite à mão — edite o gerador e rode:

```bash
deno run --allow-read --allow-write tool/gerar_pagina.ts
```

`tool/testar_edge.sh` regenera e **reprova se divergir**, porque arquivo gerado
que se commita apodrece calado: alguém edita o gerador, esquece de rodar, e a
página publicada fica velha sem nenhum sinal.

## Por que não é servida pela edge function

Porque não funciona. O gateway do Supabase reescreve `text/html` para
`text/plain` e injeta `Content-Security-Policy: default-src 'none'; sandbox`, de
modo que quem abre o link vê o **código-fonte** — e, ainda que renderizasse, a
CSP mataria o script do formulário. Medido em 17/ago/2026; detalhes em
[`supabase/operacao/publicacao.md`](../supabase/operacao/publicacao.md).

A função segue existindo e fazendo o trabalho: ela recebe os `POST` desta página
e executa a exclusão. O que mudou é só de onde o HTML é servido.

## Publicar no Cloudflare Pages

O GitHub Pages não serve aqui: em repositório **privado** ele exige plano Pro ou
Team, e este repositório é privado no plano Free. O Cloudflare Pages publica de
repositório privado no plano gratuito.

Configuração, uma vez:

1. Cloudflare → **Workers & Pages** → **Create** → **Pages** → **Connect to Git**
2. autorizar o GitHub e escolher `irineus/desmalha`
3. **Production branch:** `main`
4. **Build command:** *(deixar vazio)*
5. **Build output directory:** `site`

Sem build: o HTML já está pronto no repositório, e a imagem de build do
Cloudflare tem Node e não Deno. Trocar o gerador de linguagem para caber na
esteira de um terceiro seria deixar a ferramenta escolher a arquitetura.

Cada push no `main` que toque em `site/` republica sozinho.

## ⚠️ O endpoint é o do `desmalha-dev`

O formulário posta em
`https://caqxssmxeiuutfguxdzj.supabase.co/functions/v1/excluir-conta` — o
projeto de **desenvolvimento**, porque é o único que existe.

Quando houver produção, ela precisa de um projeto do Pages próprio, gerado do
mesmo `tool/gerar_pagina.ts` com o ref de lá, e é a URL de produção que vai para
o campo de exclusão de conta do Play Console. Descobrir no dia da submissão que
a página da loja apaga contas do banco de desenvolvimento seria caro.

## O que ainda falta antes de declarar a URL na loja

- publicar no Cloudflare Pages e **abrir o endereço num navegador** para ver a
  página renderizada — é o passo que o `supabase.co` não permitia;
- clicar o fluxo inteiro com uma conta descartável, seguindo o roteiro de
  conferência em [`supabase/operacao/publicacao.md`](../supabase/operacao/publicacao.md);
- o **botão dentro do app**: o Google Play exige os dois caminhos, e ele é card
  próprio no board.
