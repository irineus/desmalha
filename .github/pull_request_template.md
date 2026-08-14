<!-- Título do PR: prefixo convencional (feat/fix/ci/docs/refactor/test) + resumo curto. -->

## O que muda

<!-- Resumo objetivo da mudança. Referencie o card do board quando houver:
     card "Nome do card" (Fase N). -->

## Por quê

<!-- Problema ou decisão que motivou. Decisão nova de arquitetura/stack/regra
     fiscal vai também para a página "Decisões vigentes" no fechamento do card. -->

## Verificação na sessão

<!-- O CI (android-verify) só roda no main — a branch é verificada ANTES do push;
     o CI é o selo do merge. Marque o que rodou (ou N/A para mudança só de docs). -->

- [ ] `fvm flutter analyze` limpo (`apps/desmalha_app`)
- [ ] `fvm flutter test` verde (`apps/desmalha_app`)
- [ ] `dart test` verde (`packages/desmalha_core`)
- [ ] `fvm flutter build apk --debug` ok — obrigatório se mexeu em `pubspec`, Gradle ou dependência com código nativo
- [ ] N/A — só documentação/config de sessão (o changeset do CI já ignora `**/*.md` e `.claude/**`)

## Regras invioláveis

<!-- Conferir sempre; remover a seção só se o diff obviamente não toca nesses pontos. -->

- [ ] Nenhum `double` para dinheiro ou percentual fiscal — centavos em `int`, pontos-base em `int`
- [ ] Lógica fiscal só em `packages/desmalha_core`, com testes; o app só orquestra e apresenta
- [ ] Nenhum segredo no diff (keystore, senhas, chaves de API, tokens)
- [ ] Versão do Flutter inalterada (só muda por decisão do usuário registrada no board)
- [ ] Não enfraquece o claim "nem nós conseguimos ver seus dados" — nenhum dado fiscal sai do dispositivo em texto claro (inclusive em telemetria/logs de erro)

## Pendências para o board

<!-- O que fica para o fechamento do card, pendências de usuário (fora da nuvem)
     e candidatos a card novo. "Nada" é resposta válida. -->
