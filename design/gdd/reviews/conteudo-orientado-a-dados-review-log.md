# Review Log — Conteúdo orientado a dados

## Review — 2026-11-05 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Scope signal: L
Specialists: nenhum (modo lean)
Blocking items: 3 | Recommended: 8
Summary: Contrato R1–R11 sólido, ACs testáveis e todos os exemplos de F1–F8 conferem com `arenaContent.ts`/`engine.ts`; 0 conflitos com o registro. Três lacunas impedem a implementação: falta o mapeamento de ids cânone → Godot, o `EffectDef` de valor único com a V10 não representa as bênçãos canônicas, e o `assert` em debug da R10 contradiz o AC-21. Todas são correções curtas.
Prior verdict resolved: First review
Findings:
- [BLOCKING] Detailed Design (R2/R11/V5) + AC-34: sem tabela de mapeamento cânone → Godot (`BLADE`→`lamina`, `BEIRA_LIMIAR`→`limiar`, `boss_anomalia_maior`→`anomalia_maior`); não diz se `BoonDef.doutrina`/V5 usam `BLADE` ou `lamina`.
- [BLOCKING] Detailed Design (R1 `EffectDef`, V10) + AC-20: um só `valor` não carrega as constantes das descrições canônicas (Corte Fantasma 10, Linha Contada 4º, Penumbra 50%, Forma Fixa −30%, Matéria Residual 12, Os Que Ficam 40%, Fardo Repartido 300%); V10 reprova o conteúdo real, inclusive do MVP.
- [BLOCKING] Detailed Design (R10) × AC-21: `assert` em debug interrompe o teste gdUnit4 antes de verificar `null` e o relator; mover o assert para o relator padrão injetado.
- [RECOMMENDED] Detailed Design (R9, V7, V9) + AC-08: em release, V7 precisa de `ResourceLoader.exists`; `.csv` em `res://` é importado como tradução por padrão (verificar no 4.7.2) — `ids_registrados.csv`, `canon/`, CSV PT-BR; ou restringir V5/V9 ao CI/editor.
- [RECOMMENDED] Formulas (F1, F7): "gravada completa (0,266667)" contraditório; empates x,5 após multiplicadores podem divergir do cânone (5 ticks × 0,5: cânone 3, truncado 2); falta AC de paridade de empate.
- [RECOMMENDED] Detailed Design (V5): só cobre Tradições; nomes de inimigos/chefes/regiões/armas sem checagem; arma de Pactos do cânone ≠ adaptação aprovada.
- [RECOMMENDED] Detailed Design (V9): quem/quando acrescenta ids a `ids_registrados.csv` não está definido.
- [RECOMMENDED] States and Transitions: recarga em debug não diz como sistemas com catálogo injetado recebem o novo, nem o cache do `ResourceLoader`.
- [RECOMMENDED] Dependencies × systems-index: índice diz "sem dependências"; GDD declara Localização e contrato com Modificadores/IA/Combate/Status — registrar em Circular Dependencies como resolvido por contrato.
- [RECOMMENDED] Formulas (F6) × UI Requirements: linhas informativas de `reach_px` não cabem no modelo erro/aviso.
- [RECOMMENDED] Detailed Design (R5): nenhuma checagem de que o id bate com o nome `[id].tres`.
- [NICE] Player Fantasy e Tuning Knobs ausentes (advisory em standard); F8 `y_cap` "∞" × `sem_teto`; registro `linear_curve` output_range [0,…] × piso negativo permitido; Interactions sem Diálogo e lore/VFX; `fenda_erante` (exemplo) × canônico `fenda_errante`; Open Q4 "nada de Pactos"; AC-24 mais estrito.
Reviewed-Content-Hash: design/gdd/conteudo-orientado-a-dados.md f86760f8b87796e6a6a1748e23e989ac730a16de
Reviewed-Content-Hash: design/registry/entities.yaml 47848c4cf32a5a22219cb7f8d550c4bdf8a34a23
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/gdd/systems-index.md 436a7c59e7697bba0983866b289eb7d9ece6ba2e
Reviewed-Content-Hash: design/gdd/game-concept.md 7a92fedac35eb57647163df6664bff45fef7fba2
Reviewed-Content-Hash: design/art/art-bible.md 53a18f284ee0e7251a1d40ae5b33218bc34e531a

### Pedido externo — 2026-11-05 (GDD RNG com seed, R8)
- Incluir na revisão: o catálogo expõe uma **impressão digital** (hash do conteúdo carregado, em ordem do manifesto), exibida com 4 hex junto da seed (`3F9A-07C2 · v0.1.0 · c1B4E`). Serve ao contrato de reprodução da R7 do RNG (mesma seed só reproduz com o mesmo conteúdo). Formato e algoritmo ficam a cargo do GDD de Conteúdo. Fonte: `design/gdd/rng-com-seed.md` (R8, Dependencies).

## Revisão aplicada — 2026-11-05 (sessão separada, aprovada pelo usuário)
Status do GDD: In Review (aguarda novo `/design-review` em sessão nova).

| Bloqueante | Correção no GDD |
|---|---|
| Mapeamento de ids cânone → Godot | R2: `assets/data/canon/mapa_ids.csv` (`tipo,id_canon,id_godot`) para doutrinas/armas, regiões, chefes, inimigos, melhorias e tipos de efeito; usado só pela importação, pela paridade AC-34 e pela V5; `BoonDef.doutrina` guarda o token Godot (`lamina`); `trad_*` sem mapa. AC-34/AC-37 ajustados; AC-39 novo. |
| `EffectDef` de valor único × V10 | R1: `valor` = número lido antes da raridade (constante do cânone multiplicada para dentro, exato por linearidade) + `params` nomeados que não escalam; R7: sintaxe `{campo:formato}`, `{tipo.campo}`, `{status.<id>.<campo>}`, formatos `int`/`pct`/`num`, valor absoluto; V3/V10 ajustadas; Edge Cases lista as 8 Tradições com constante escondida (inclui Fundo do Poço 50%, que o review não listou; o −30% de Forma Fixa é do Abalo). AC-41 e AC-42 novos. |
| R10 `assert` × AC-21 | R10: a consulta só devolve `null` e entrega ao relator injetado; o relator padrão faz log + `push_error` + `assert` em debug (`parar_em_debug`); o relator falso só registra. AC-21 ajustado; AC-43 novo. |

Recomendadas resolvidas:
- Release/CSV/V7: verificado no 4.7.2 que `.csv` em `res://` vira Translation por padrão e que `importer="keep"` funciona; R5 manda `canon/` usar `keep` e ficar fora do export; V5/V9 só CI e debug (R9); V7 por `ResourceLoader.exists`; CSV PT-BR conferido pela tradução importada. AC-08 ajustado; AC-45 novo.
- V5 ampliada: nomes de Tradições, armas (com Ataque/Especial), inimigos, chefes, regiões e melhorias; arma de Pactos = adaptação aprovada (Besta do Vínculo) em R11. AC-40 novo.
- V9: a importação acrescenta as linhas; conteúdo manual, no mesmo commit; o registro só cresce (CI compara com o branch principal). AC-44 novo.

Recomendadas em aberto (usuário não escolheu nesta passada): F1/F7 "0,266667" (teste no 4.7.2: `.tres` guarda float64 completo, e 5 × 0,5 → 3, 9 × 0,5 → 5 já batem com o cânone; falta só texto + AC); recarga em debug × DI/cache (`CACHE_MODE_IGNORE_DEEP` existe no 4.7.2); gravidade "info" para `reach_px`; id × nome `[id].tres`; Circular Dependencies no índice. Desejáveis: todos em aberto.

## Review — 2026-11-05 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Scope signal: L
Specialists: nenhum (modo lean)
Blocking items: 1 | Recommended: 6
Summary: Re-review. Os 3 bloqueantes anteriores estão resolvidos e conferem com o cânone: as 18 descrições de `arenaContent.ts` cabem em `valor`/`params`/`{status.…}`, as linhas de `engine.ts` citadas batem, F1–F8 recalculadas conferem e há 0 conflitos com o registro. Resta 1 bloqueante: a impressão do catálogo, pedida pelo GDD RNG com seed (aprovado) para R7/R8, não foi incorporada.
Prior verdict resolved: Yes (3/3 bloqueantes anteriores)
Findings:
- [BLOCKING] Detailed Design (R9/R10) + Interactions: impressão do catálogo (4 hex do texto da seed, RNG R7/R8) sem definição: o que entra no hash, serialização, algoritmo, quando recalcula, AC.
- [RECOMMENDED] Formulas (F8) × R9: `y_floor > y_cap` é "erro de validação" sem checagem que o cubra (V1/V2 só por campo); o Input pede o mesmo para `zm + ze`.
- [RECOMMENDED] States + Edge Cases (recarga em debug) + AC-06: cache do `ResourceLoader` e como os sistemas injetados recebem o catálogo novo (em aberto desde a revisão anterior).
- [RECOMMENDED] Formulas (F1): "gravada completa (0,266667)" contraditório (em aberto).
- [RECOMMENDED] Formulas (F6) × UI Requirements: `reach_px` "linha informativa" fora do modelo erro/aviso (em aberto).
- [RECOMMENDED] Interactions/Dependencies × systems-index: faltam Input e controle (`InputTuning`) e a impressão para o RNG; linha 1 do índice com "—" em Depends On (em aberto).
- [RECOMMENDED] Detailed Design (R5): sem checagem id × nome `[id].tres` (em aberto).
- [NICE] F8 "y_cap pode ser ∞" × `sem_teto`; registro `linear_curve` output_range [0,…] × piso negativo; lista de constantes escondidas exemplificativa (ex.: `engine.ts:1102/1106`).
Reviewed-Content-Hash: design/gdd/conteudo-orientado-a-dados.md 282013685bbe56afa56bba088a2e13f6a7c2eb51
Reviewed-Content-Hash: design/registry/entities.yaml 2e7e7f09d99ae23fd214b5eef78da6f326821aaa
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/gdd/rng-com-seed.md 0105f1becdf248e5e60ba368c147b13ec0e4ff8c
Reviewed-Content-Hash: design/gdd/input-e-controle.md 9b7dc63de550e9880df174e86e06ae4e5b9432d6
Reviewed-Content-Hash: design/gdd/game-concept.md 7a92fedac35eb57647163df6664bff45fef7fba2
Reviewed-Content-Hash: design/art/art-bible.md 53a18f284ee0e7251a1d40ae5b33218bc34e531a

## Revisão aplicada — 2026-11-05 (mesma sessão da re-review, decisões do usuário)

| Achado | Correção no GDD |
|---|---|
| [BLOCKING] Impressão do catálogo | R12 nova: SHA-256 (`HashingContext`) sobre serialização canônica (ordem do manifesto, campos em ordem alfabética, float64 IEEE-754 com −0,0 → 0,0, texto UTF-8 com comprimento; chaves entram, textos traduzidos e `canon/` não); curta = 4 hex maiúsculos para a tela, completa = 64 hex para telemetria e relatório; recalculada em cada carga e recarga. Interactions, Dependencies e Cross-References citam o RNG (R7, R8). AC-46 novo. |
| [RECOMMENDED] Regras entre campos | "Regras por campo" + V2: cada classe declara uma lista fixa de regras entre campos; violação sai como erro V2 citando os dois campos. F8 e AC-36 ajustados. |
| [RECOMMENDED] Recarga em debug | Edge Cases: leitura com `CACHE_MODE_IGNORE_DEEP`; nenhum sistema guarda o catálogo entre runs, a run seguinte recebe o novo por injeção; impressão recalculada. AC-47 novo. |
| [RECOMMENDED] Texto da F1 | "Grava-se o float64 de `ticks / 60` sem arredondar". |

Verificado no Godot 4.7.2: `HashingContext.HASH_SHA256` e `ResourceLoader.CACHE_MODE_IGNORE_DEEP` existem.
Em aberto (usuário não escolheu nesta passada): `reach_px` × modelo erro/aviso; bidirecionalidade com Input e controle e linha 1 do índice; id × nome `[id].tres`; desejáveis.


### Mudança externa — 2026-11-05 (GDD Cena 3/4 e câmera)
- Escala corrigida por decisão do usuário: viewport lógico 1920×1080 (Art Bible §8.6) → `unit_to_px` 1,0 → **1,5** (registro revisado). Foram atualizados só os números dependentes de escala neste GDD; nenhuma regra mudou. Fonte: `design/gdd/cena-3-4-e-camera.md` (R1, R2, F1). Reconferir na próxima revisão.

## Review — 2026-11-06 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Scope signal: L
Specialists: nenhum (modo lean)
Blocking items: 2 | Recommended: 5
Summary: Re-review. O bloqueante anterior (impressão do catálogo) está resolvido pela R12 + AC-46; F1–F8 recalculadas e as linhas de `engine.ts` citadas conferem; 0 conflitos de valor com o registro. Restam 2 bloqueantes novos, cada um uma decisão de uma linha: a unidade do empurrão (sem fórmula e contraditória com o GDD de Modificadores) e o chefe do Limiar no MVP (AC-39 × R1 × V4/AC-20). Usuário escolheu revisar em outra sessão.
Prior verdict resolved: Yes (1/1)
Findings:
- [BLOCKING] Formulas (F1–F6) + Edge Cases (constantes escondidas): unidade do empurrão indefinida — `AttackDef` empurrão e `params.empurrao` gravados crus (4, 8), Modificadores R5 diz "F4, × 1,5", cânone é velocidade unidade/tick com queda × 0,78/tick (`engine.ts:957–968`, F2 daria × 90); AC-34 sem valor esperado.
- [BLOCKING] Detailed Design R1 × AC-39 × V4/AC-01/AC-20: importação grava `limiar` com chefe `anomalia_maior`, mas o MVP tem "sem chefe" e só 3 `EnemyDef` → V4 falha no conteúdo real; editar o `.tres` à mão quebra o AC-34.
- [RECOMMENDED] Interactions/Dependencies: Input e controle (`InputTuning`) e Cena 3/4 (`CameraTuning`) ausentes; "nenhum desses GDDs existe ainda" (l. 714) defasado; l. 345 põe o buffer no `CombatTuning`, mas o dono é o `InputTuning` (registro `input_buffer_steps`).
- [RECOMMENDED] R2/R7/V10/Edge Cases/AC-42: nomes provisórios de tipo de efeito (`max_hp`, `nth_hit_double`, `dash_damage`, "R8") — os finais estão na R5 de Modificadores.
- [RECOMMENDED] Edge Cases l. 617 + AC-42: `{status.abalo.reducao_dano:pct}` colide com o atributo `reducao_dano` de Modificadores (Abalo é `dano_todo` × 0,7).
- [RECOMMENDED] R9: pedidos de Modificadores pendentes — checagem de `params` divergentes entre definições (fora do modelo V2 por classe) e citar `ModifiersTuning`.
- [RECOMMENDED] R12: fixar endianness, largura do prefixo de comprimento, campo opcional nulo e se o nome do campo entra nos bytes.
- [NICE] `reach_px` fora do modelo erro/aviso; id × nome `[id].tres`; F8 "y_cap pode ser ∞" × `sem_teto`; `output_range` de `linear_curve` no registro (todos herdados).
Reviewed-Content-Hash: design/gdd/conteudo-orientado-a-dados.md 4169d9d276a0cd879f79c301db4766d1dea1692c
Reviewed-Content-Hash: design/registry/entities.yaml 9e15742c879b4df6d25276f67cc172e8a4772594
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/gdd/modificadores-e-atributos.md ab1a1fd01d956a852143b88a289f5946382f53de
Reviewed-Content-Hash: design/gdd/input-e-controle.md b8a36b427418daa826a878b66425fb9495f9c83e
Reviewed-Content-Hash: design/gdd/cena-3-4-e-camera.md cc1737d8cc81e6e00548b786a173030331210478
Reviewed-Content-Hash: design/gdd/systems-index.md 5b3f30f32185ada333cd6f1aecadd081c68088bc
Reviewed-Content-Hash: design/gdd/game-concept.md 7a92fedac35eb57647163df6664bff45fef7fba2

## Revisão aplicada — 2026-11-06 (mesma sessão da re-review, decisões do usuário)

| Achado | Correção no GDD |
|---|---|
| [BLOCKING] Unidade do empurrão | Empurrão = velocidade inicial em px/s pela F2 (× 90): R6, F2 (faixa 0–22 → 0–1980; queda × 0,78 por passo no `CombatTuning`), constantes escondidas (projétil 6 → 540, parede 7 → 630, queda), Corte Fantasma `empurrao` 360 e Matéria Residual 720; AC-29 com os exemplos. Modificadores R5 alinhado. |
| [BLOCKING] Chefe do Limiar no MVP | O chefe `anomalia_maior` entra no manifesto do MVP como dado (R1); a Run do MVP não leva à câmara do chefe. Edge case novo; AC-48 novo. |
| [RECOMMENDED] Input e Cena 3/4 | Interactions, Dependencies e Cross-References citam `InputTuning` e `CameraTuning`; bidirecionalidade atualizada; buffer saiu do `CombatTuning` (dono: Input). |
| [RECOMMENDED] Nomes provisórios | Nomes finais da R5 de Modificadores (`vida_max_plano`, `dano_enesimo_acerto`, `corte_da_esquiva`…) em R2, R7, V10, Edge Cases e AC-42. |
| [RECOMMENDED] Campo do Abalo | `status.abalo.reducao_dano` → `reducao_dano_causado` (0,3); Modificadores aplica × (1 − 0,3). |

Em aberto: `ModifiersTuning` nomeado na R1 e checagem de params divergentes entre definições (OQ6 de Modificadores); bytes da R12; desejáveis herdados.

## Review — 2026-11-06 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Scope signal: L
Specialists: nenhum (modo lean)
Blocking items: 2 | Recommended: 5
Summary: Re-review independente (só o GDD e as fontes citadas). O empurrão em px/s pela F2 confere com o cânone (move e depois × 0,78, `engine.ts:950–971`; máximo 22 = Muralha), assim como F1–F8, os exemplos dos ACs e as linhas de `engine.ts` citadas; 0 conflitos com o registro. O chefe no MVP foi resolvido só em parte: a referência `RegionDef → EnemyDef` fecha, mas o comportamento `boss` do chefe não tem dono no MVP, e o mapa de ids não cobre comportamentos, formas e status.
Prior verdict resolved: Partial (empurrão resolvido; chefe do Limiar resolvido em parte)
Findings:
- [BLOCKING] R1/R8/Dependencies × AC-48/AC-20: `anomalia_maior` tem `behavior: "boss"` (`arenaContent.ts:96`); a V4 confere contra a lista da IA, e o comportamento de chefe é do sistema Chefes (#15, fatia vertical), ausente do GDD → V4 falha no manifesto real do MVP.
- [BLOCKING] R2 (mapa de ids) × AC-39/AC-34: sem linhas para comportamentos (`melee`/`ranged`/`charger`/`boss`), formas (`arc`…) e status (`bleed`/`burn`/`weak`, `types.ts:61`); R2 grava "só tokens Godot" e o GDD já usa `abalo` → importação dos inimigos do MVP indefinida.
- [RECOMMENDED] Edge Cases: `engine.ts:580` reconhece chefe por `defId.startsWith("boss")`; o prefixo some com o mapa.
- [RECOMMENDED] Edge Cases (constantes escondidas): `HEAVY_KNOCKBACK` 10 (`:69`, limiar e piso do finalizador em `:686`) → 900 px/s; corte `< 0,05` (`:968`) → 4,5 px/s; `MELEE_STEP` 7 (`:75`) → 10,5 px.
- [RECOMMENDED] R12: endianness, largura do prefixo, campo opcional nulo, nome do campo e prefixo de arrays (herdado).
- [RECOMMENDED] R1/R9: `ModifiersTuning` e checagem de params divergentes (OQ6 de Modificadores, herdado).
- [RECOMMENDED] systems-index linha 1: Depends On "—" × Localização (suave) declarada (herdado).
- [NICE] F8 "∞" × `sem_teto`; `output_range` de `linear_curve` no registro; `reach_px` fora do modelo erro/aviso; id × nome `[id].tres`; Player Fantasy e Tuning Knobs (advisory).
Reviewed-Content-Hash: design/registry/entities.yaml 03b431a3014ea0ed34194a06bdc78843376f3fc0
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/gdd/systems-index.md 04be74b35c08840f868acc5593113be39cbf64ec
Reviewed-Content-Hash: design/gdd/modificadores-e-atributos.md 957af996dad8d7c262443e02ec6258db11fe252a
Reviewed-Content-Hash: design/gdd/rng-com-seed.md 7120bf39aa292ef62c925a348a2f4b6657c2d27f
Reviewed-Content-Hash: design/gdd/input-e-controle.md 008ec600b522689f08b91af25a66d66dfdf6ffa8
Reviewed-Content-Hash: design/gdd/cena-3-4-e-camera.md cc1737d8cc81e6e00548b786a173030331210478
Reviewed-Content-Hash: design/gdd/game-concept.md 7a92fedac35eb57647163df6664bff45fef7fba2
Reviewed-Content-Hash: design/art/art-bible.md 5b3f20b7d140cd94e71176a860601c2b75f364a9
(O GDD não foi carimbado de propósito: foi revisado na mesma sessão logo depois do review, e a próxima re-review deve rodar completa.)

## Revisão aplicada — 2026-11-06 (mesma sessão da re-review independente, decisões do usuário)

| Achado | Correção no GDD |
|---|---|
| [BLOCKING] Comportamento de chefe no MVP | R8: chave **reservada** (registrada antes do código; a V4 aceita; pedir em jogo é erro do relator). No MVP, a IA registra `chefe` como reservada; o GDD de Chefes (fatia vertical) implementa. R1 (`EnemyDef`), V4, Edge Cases, Interactions e Dependencies citam Chefes. AC-48 ajustado; AC-49 novo. |
| [BLOCKING] Mapa sem comportamento/forma/status | R2: tokens em português (decisão do usuário): `corpo_a_corpo`, `distancia`, `arremetida`, `chefe`; `arco`, `circulo`, `projetil`, `avanco`; `sangramento`, `queimadura`, `abalo`. `avanco`/`arremetida` evitam colidir com os golpes "Investida" e "Estocada". A importação troca `behavior`, `shape.kind` e `status.id`. R1 e F5 ajustados; AC-39 ampliado. |
| [RECOMMENDED] Chefe pelo prefixo do id | Edge Cases: `engine.ts:580` não é portado; "é chefe" sai do comportamento `chefe`. |

Em aberto: constantes da família do empurrão (`HEAVY_KNOCKBACK`, corte 0,05, `MELEE_STEP`); bytes da R12; `ModifiersTuning` e params divergentes; Depends On da linha 1 do índice; desejáveis herdados.
Pedido externo: o GDD de Modificadores (l. 253–254) ainda usa `circle` e `lunge`; trocar por `circulo` e `avanco` na próxima revisão dele.

## Review — 2026-11-06 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Scope signal: L
Specialists: nenhum (modo lean)
Blocking items: 1 | Recommended: 7
Summary: 3ª re-review, independente (só o GDD e as fontes citadas). Os 2 bloqueantes anteriores estão resolvidos: chave reservada `chefe` (R8, V4, AC-48/AC-49) e tokens em PT de comportamento, forma e status (R2, AC-39), conferidos com `types.ts:61/110` e `arenaContent.ts`. F1–F8, exemplos dos ACs e as 23 linhas de `engine.ts` citadas conferem; 0 conflitos com o registro. Resta 1 bloqueante da mesma família: os tipos de sala e de recompensa do cânone não têm linha no mapa nem lista registrada.
Prior verdict resolved: Yes (2/2)
Findings:
- [BLOCKING] R2/R8/V4 × AC-39/AC-48: `RegionDef limiar` tem `rooms` com `combat`/`sanctuary`/`boss` (`RoomKind`, `types.ts:172`) e as chaves dos pesos de porta da `RewardTable` são `boon`/`fragments`/`heal`/`trial` (`RewardKind`, `:177`; `engine.ts:400–410`); sem linha no mapa, fora dos campos trocados pela importação e sem lista registrada → pelo AC-39 a importação do `limiar` falha; copiar em inglês contraria a decisão dos tokens em PT; um token errado passa na V4.
- [RECOMMENDED] R1: `EnemyDef.região` não existe no cânone e `eco_perdido` está nos pools de `limiar` e `veio` (`arenaContent.ts:20/28`); tirar o campo (o pool da `RegionDef` já diz).
- [RECOMMENDED] Edge Cases (valores): "velocidade de projétil não aceita zero" × `projectileSpeed: 0` de `eco_perdido`/`fenda_errante` → restringir à forma `projetil` do `AttackDef`; no `EnemyDef`, 0 = não atira.
- [RECOMMENDED] Edge Cases (constantes escondidas): `HEAVY_KNOCKBACK` 10 (`:69`, `:686`) → 900 px/s; corte `< 0,05` (`:968`) → 4,5 px/s; `MELEE_STEP` 7 (`:75`) → 10,5 px (herdado).
- [RECOMMENDED] R12: endianness, largura do prefixo, campo opcional nulo, nome do campo (herdado).
- [RECOMMENDED] R1/R9: `ModifiersTuning` e checagem de params divergentes (Modificadores l. 100, OQ6; herdado).
- [RECOMMENDED] systems-index linha 1: Depends On "—" × Localização (suave) (herdado).
- [RECOMMENDED] Entre documentos: Modificadores l. 256–257 ainda usa `circle`/`lunge` (pedido externo já registrado; correção é de lá).
- [NICE] F2 "sem limite" × tabela 0–1980; F8 "∞" × `sem_teto`; `output_range` de `linear_curve`; `reach_px` fora do modelo erro/aviso; AC-39 sem `ranged`/`projectile`/`burn`/`weak`/`combat` na lista de proibidos; Player Fantasy e Tuning Knobs (advisory).
Reviewed-Content-Hash: design/gdd/conteudo-orientado-a-dados.md 2e7d5907f34b67d15cabf9a6b958168a86444da7
Reviewed-Content-Hash: design/registry/entities.yaml 03b431a3014ea0ed34194a06bdc78843376f3fc0
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/gdd/systems-index.md 5eec9727b5fd7eeb0202fd5527ca997747dc6c98
Reviewed-Content-Hash: design/gdd/modificadores-e-atributos.md 854d87123672c80687f1e4e31d40a186831c9716
Reviewed-Content-Hash: design/gdd/rng-com-seed.md 7120bf39aa292ef62c925a348a2f4b6657c2d27f
Reviewed-Content-Hash: design/gdd/input-e-controle.md f3add086d1372cd85137edc2614520e4ebd43fac
Reviewed-Content-Hash: design/gdd/cena-3-4-e-camera.md cc1737d8cc81e6e00548b786a173030331210478
Reviewed-Content-Hash: design/gdd/game-concept.md 7a92fedac35eb57647163df6664bff45fef7fba2
Reviewed-Content-Hash: design/art/art-bible.md 5b3f20b7d140cd94e71176a860601c2b75f364a9
(O hash do GDD inclui a linha de Status atualizada por esta review.)

## Revisão aplicada — 2026-11-06 (a partir de `design/gdd/gdd-cross-review-2026-11-06.md` e da 3ª re-review; decisões do usuário)

| Achado | Correção no GDD |
|---|---|
| [BLOCKING] Tipos de sala e de recompensa fora do mapa (C-B1) | R2: linhas `combat`/`sanctuary`/`boss` → `combate`/`santuario`/`chefe` e `boon`/`fragments`/`heal`/`trial` → `bencao`/`fragmentos`/`cura`/`provacao`. A importação troca `rooms` e as chaves de peso da `RewardTable`. R8: donos Câmaras e ondas e Portas e recompensas; sala `chefe` reservada no MVP. V4 confere as listas. AC-12, AC-39 e AC-48 ajustados. |
| [BLOCKING] Tela de erros sem `InputTuning` (S-B1) | Edge Cases › Recarga e UI Requirements: em Falhou, o Input opera só com entradas digitais (Input R12). AC-51 novo. |
| Recarga e sistemas fora da run (S-W3) | O carregador re-injeta os Tunings de Input e câmera a cada entrada em Pronto. AC-47 ampliado. |
| `ModifiersTuning` (C-W2) | R1 (`*Tuning`), Interactions, Dependencies; piso de Vida e teto de redução vão para ele. |
| Params divergentes (C-W3) | V11 nova (params iguais entre fontes do mesmo tipo de efeito) e AC-50. "V1–V10" → "V1–V11". |
| Cambaleio do chefe (C-W4) | Edge Cases: "não cambaleia" é regra de Combate núcleo e IA (`engine.ts:587`), confirmada pelo GDD de Chefes. |
| `unit_to_px` (C-W9) | Interactions: constante deste GDD, aplicada só na importação (F4). |
| `EnemyDef.região` | Campo removido; o pool da `RegionDef` diz onde o inimigo aparece. |
| Velocidade de projétil 0 | Edge Cases: só a forma `projetil` do `AttackDef` recusa 0; no `EnemyDef`, 0 = não atira. |
| Constantes da família do empurrão | Edge Cases: corte `< 0,05` → 4,5 px/s, `HEAVY_KNOCKBACK` 10 → 900 px/s, `MELEE_STEP` 7 → 10,5 px (F4). |

Em aberto: bytes da R12; Depends On da linha 1 do índice; desejáveis herdados. Os pedidos de Modificadores (`ModifiersTuning` e a checagem de params divergentes, OQ6 e Edge Cases de lá) foram atendidos aqui: falta Modificadores fechar a OQ6 e citar a V11 na próxima revisão dele.
