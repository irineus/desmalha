# Catálogo versionado — fonte da verdade

Este diretório (mais `perfis/`, ver abaixo) é o que o servidor serve ao app
na tabela `catalogo_itens` (só-leitura, ver
`supabase/migrations/*_catalogo.sql`). A publicação é um passo do workflow
`.github/workflows/supabase.yml`: sincroniza estes arquivos com o banco e
confere lendo de volta. **Corrigir conteúdo = editar aqui e mergear** — sem
release do app, sem review de loja.

## Convenção

```
catalogo/<tipo>/<id>.json      # o nome do arquivo É o id do item
perfis/<id>.json               # tipo perfil_csv (ver nota)
```

| tipo                        | schema (desmalha_core)      | conteúdo hoje |
|-----------------------------|-----------------------------|---------------|
| `tabela_irpf`               | `TabelaIrpf`                | irpf-mensal-2026-01 |
| `feriados_bancarios`        | `FeriadosBancarios`         | 2026 (FEBRABAN + 31/12) |
| `perfil_csv`                | `PerfilCsv`                 | Nubank, Inter, BB |
| `layout_darf_codigo_barras` | `LayoutCodigoBarrasDarf`    | nenhum — só entra conferido contra DARF real |

Os perfis CSV moram em `perfis/` (fora daqui) porque o CLI de validação e o
roteiro do usuário no Windows já apontam para lá; o manifesto de publicação
(`tool/publicar_catalogo.ts`) e o teste de carga
(`test/catalogo/catalogo_test.dart`) incluem os dois diretórios.

## Regras

- Todo item carrega `fonte` rastreável. Conteúdo sem origem é inútil três
  meses depois.
- `id` dentro do JSON = nome do arquivo sem `.json`. Teste reprova
  divergência.
- A tabela do IRPF daqui precisa bater com a dos cenários table-driven
  (`cenarios/cenarios_carne_leao.json`) quando os ids coincidem — teste
  reprova divergência. Os cenários são a prova do motor; o catálogo é o que
  o app usa. Divergir seria calcular com uma tabela e testar com outra.
- Item novo de tipo desconhecido pelo app antigo é **ignorado** pelo
  `Catalogo` (compatibilidade para a frente); conteúdo malformado de tipo
  conhecido **falha alto**.
- Valores fiscais seguem as convenções invioláveis: centavos em `int`,
  pontos-base em `int`, nunca ponto flutuante.
