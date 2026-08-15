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
5. **Fechar o ciclo do Git antes de encerrar**: oferecer explicitamente abrir o PR da branch da tarefa e fazer o merge. Branch empurrada sem PR some — já aconteceu com o motor de cálculo, concluído no board e ausente do `main` por duas sessões. Se houver PR aberto de tarefa anterior ainda não mergeado, dizer no resumo final. Ver regra permanente 7 do `CLAUDE.md`.
6. **Apagar a branch depois do merge** — parte do mesmo ciclo, não um extra. Ver abaixo.

## Limpeza de branch depois do merge

Branch mergeada que fica no remoto vira ruído, e ruído é o que escondeu a branch do motor de cálculo por duas sessões. Com o remoto limpo, uma branch sobrando é **sinal de alerta**; com dez branches velhas, ninguém repara na décima primeira.

**Antes de apagar, confirmar que o conteúdo está no `main` — e não decidir por `git branch --merged`.** O repositório mergeia por **rebase**, o que cria um commit novo: a ponta da branch deixa de ser ancestral do `main` e some do `--merged`, mesmo com tudo integrado. Medido em 15/ago/2026, com as oito branches da época todas integralmente no `main`: **`--merged` reconheceu apenas uma.**

O erro é assimétrico, e é isso que importa: se `--merged` lista a branch, ela está mergeada; se **não** lista, não se conclui nada. Usar `git cherry`, que compara por *patch-id* e enxerga através do rebase:

```
git fetch origin --quiet
git cherry main origin/<branch> | grep '^+' | wc -l    # 0 = tudo já está no main
```

Zero linhas com `+` significa que nenhum patch da branch está fora do `main`. Só então apagar:

```
git push origin --delete <branch>     # remoto
git branch -D <branch>                # local
```

⚠️ **O token da sessão de nuvem pode não ter permissão para remover refs.** Quando não tiver, o push falha com `HTTP 403` e **repetir não resolve** — não é falha de rede, então não gastar as tentativas de backoff nisso. O servidor MCP do GitHub também não expõe deleção de branch (só `create_branch`). Nesse caso, **dizer que não deu e passar o link** (`https://github.com/irineus/desmalha/branches`) em vez de dar a limpeza como feita.

Ao fechar uma tarefa, vale rodar o `git cherry` em **todas** as branches remotas e listar as que já estão no `main`: a limpeza acumulada é barata e é o que mantém o sinal funcionando.

## Proibições
Nunca deletar cards. Nunca tocar em outros databases do workspace. IDs de página em UUID hifenizado nas atualizações.
