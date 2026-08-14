---
name: proxima-tarefa
description: Consulta e atualiza o board do Desmalha no Notion (database "App Carnê-Leão — Roadmap de Construção"). Use quando o usuário disser "próxima tarefa", "concluí", "marca em andamento", "status do board" ou similar.
---

# Board do Desmalha no Notion

Pré-requisito: ferramentas do Notion MCP disponíveis. Se não estiverem, diga ao usuário que o conector Notion precisa ser habilitado no Claude Code e pare.

## Leitura obrigatória antes de opinar sobre qualquer decisão
Fazer fetch da página "Desmalha — Decisões vigentes" (ID `3b92f3f4-b9b2-818a-84a8-d8f08aa7a5f1`). Em conflito com qualquer outra fonte, ela vence. Se a leitura falhar, avisar antes de seguir.

## Identificadores
- Data source do board: `d50a2925-fb74-4f67-b0db-af03ef41d1b4`
- Propriedades: Tarefa (título), Fase (select, valores com prefixo numérico e acentos exatos, ex. "3. Setup e Infraestrutura"), Status ("A fazer" / "Em andamento" / "Concluído"), Prioridade ("Alta" / "Média" / "Baixa"), Notas (texto).

## Próxima tarefa
Query SQL no data source, excluindo Concluído, ordenando por Fase ASC → Em andamento primeiro → Prioridade Alta→Baixa. Apresentar a primeira com as Notas completas (elas carregam a decisão bloqueante). Perguntar se marca "Em andamento".

## Conclusão de tarefa
1. Persistir resultados: se substanciais, criar página "Resultado: [tarefa] (mês/ano)" como SUBPÁGINA do card (`parent: page_id` do card) — nunca página solta na raiz do workspace.
2. Atualizar Notas do card (⚠️ `update_properties` SOBRESCREVE Notas — ler o valor atual primeiro e reenviar completo).
3. Atualizar a página de Decisões vigentes via `update_content` (edições pontuais, nunca replace): decisão nova na seção certa com data e card de origem; decisão substituída vai para "Decisões superadas" com motivo; linha no Histórico.
4. Status = "Concluído". Parar — um item do board por sessão; a próxima só em nova sessão.

## Proibições
Nunca deletar cards. Nunca tocar em outros databases do workspace. IDs de página em UUID hifenizado nas atualizações.
