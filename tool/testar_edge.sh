#!/usr/bin/env bash
# Desmalha — type-check e testes das edge functions.
#
#   ./tool/testar_edge.sh
#
# Roda dentro de supabase/functions porque é lá que mora o deno.json com o mapa
# de importações; de fora, os especificadores nus (@supabase/supabase-js) não
# resolvem e o type-check falha sem que nada esteja errado no código.
#
# Precisa do Deno no PATH. A máquina Windows de UI não tem Deno instalado, e não
# precisa ter: isto é código de servidor, como a suíte de
# `tool/testar_supabase.sh`. Para rodar lá pontualmente, o binário avulso do
# Deno resolve sem instalação (https://deno.com).
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v deno >/dev/null || {
  echo "Deno não encontrado no PATH — veja https://deno.com" >&2
  exit 1
}

cd "$RAIZ/supabase/functions"

# find, e não um glob: `**` só é recursivo com globstar ligado, e sem ele o
# type-check passaria a cobrir um nível só — calado, que é o pior jeito de
# reduzir cobertura. Uma função nova entra sozinha nesta lista.
mapfile -t FONTES < <(find . -name '*.ts' -not -path './node_modules/*' | sort)
[[ ${#FONTES[@]} -gt 0 ]] || { echo "nenhum fonte .ts encontrado" >&2; exit 1; }

deno check "${FONTES[@]}"

# `site/index.html` é gerado de pagina.ts e versionado, porque o Cloudflare Pages
# serve estático e sem build. Arquivo gerado que se commita apodrece calado —
# alguém edita o gerador, esquece de rodar, e a página publicada fica velha sem
# nenhum sinal. Esta conferência é o sinal.
deno run --allow-read "$RAIZ/tool/gerar_pagina.ts" --conferir

# --allow-read: os testes leem só os próprios fontes (a página é montada em
# memória). Nenhuma permissão de rede ou de escrita é concedida — se um teste
# passar a precisar de rede, é sinal de que virou teste de integração e não
# pertence mais a esta suíte.
deno test --allow-read
