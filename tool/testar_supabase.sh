#!/usr/bin/env bash
# Desmalha — aplica as migrations do backend e roda a suíte de conformidade.
#
# Dois modos:
#
#   ./tool/testar_supabase.sh
#       Sobe um Postgres local descartável, aplica os arremedos de ambiente
#       (supabase/tests/shims_locais.sql), aplica TODAS as migrations do
#       repositório numa base limpa e roda a suíte. Não precisa de nuvem.
#       Responde: "as migrations do repositório reproduzem o schema sozinhas?"
#
#   SUPABASE_DB_URL='postgresql://...' ./tool/testar_supabase.sh --remoto
#       Roda só a suíte contra um projeto Supabase já migrado (ex.: desmalha-dev).
#       Não aplica migration nem shim. A suíte termina em ROLLBACK, então não
#       deixa resíduo — mas NUNCA aponte para produção com dados reais.
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUITE="$RAIZ/supabase/tests/conformidade_identidade.sql"

if [[ "${1:-}" == "--remoto" ]]; then
  : "${SUPABASE_DB_URL:?defina SUPABASE_DB_URL}"
  exec psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f "$SUITE"
fi

PGBIN="$(ls -d /usr/lib/postgresql/*/bin 2>/dev/null | sort -V | tail -1 || true)"
[[ -n "$PGBIN" ]] && export PATH="$PGBIN:$PATH"
command -v initdb >/dev/null || { echo "PostgreSQL não encontrado no PATH"; exit 1; }

DADOS="${TMPDIR:-/tmp}/desmalha-pg"
SOCK="${TMPDIR:-/tmp}/desmalha-pgsock"
PORTA=55432

# initdb e o servidor recusam rodar como root; em container isso é o caso comum.
COMO=""
if [[ "$(id -u)" -eq 0 ]]; then
  id postgres >/dev/null 2>&1 || { echo "rode como usuário não-root ou tenha o usuário 'postgres'"; exit 1; }
  COMO="postgres"
fi
executar() { if [[ -n "$COMO" ]]; then su "$COMO" -c "PATH=$PATH $*"; else eval "$*"; fi; }

limpar() { executar "pg_ctl -D $DADOS -m immediate stop" >/dev/null 2>&1 || true; }
trap limpar EXIT

rm -rf "$DADOS"; mkdir -p "$DADOS" "$SOCK"
[[ -n "$COMO" ]] && chown -R "$COMO" "$DADOS" "$SOCK"

executar "initdb -D $DADOS -U postgres --auth=trust" >/dev/null
# listen_addresses vazio: só socket Unix. Sem isso o script colide com qualquer
# outro Postgres que já esteja na porta — e não há motivo para abrir TCP aqui.
executar "pg_ctl -D $DADOS -o '-p $PORTA -k $SOCK -c listen_addresses=' -l $DADOS/log -w start" >/dev/null

PSQL=(psql -h "$SOCK" -p "$PORTA" -U postgres -v ON_ERROR_STOP=1 -q)

"${PSQL[@]}" -c "create database desmalha;"

ARGS=(-d desmalha -f "$RAIZ/supabase/tests/shims_locais.sql")
for m in "$RAIZ"/supabase/migrations/*.sql; do ARGS+=(-f "$m"); done
"${PSQL[@]}" "${ARGS[@]}"

# A chave do Vault é sorteada dentro do banco, como em produção.
"${PSQL[@]}" -d desmalha -c \
  "insert into vault.secrets (name, secret)
   values ('desmalha_aceites_hmac_key', encode(extensions.gen_random_bytes(32),'hex'))
   on conflict (name) do nothing;"

psql -h "$SOCK" -p "$PORTA" -U postgres -d desmalha -v ON_ERROR_STOP=1 -f "$SUITE"
