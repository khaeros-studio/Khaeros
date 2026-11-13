# Review Log — Cena 3/4 e câmera

## Review — 2026-11-05 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Scope signal: L
Specialists: nenhum (modo lean)
Blocking items: 2 | Recommended: 6
Summary: Documento sólido e com matemática correta: os exemplos e oráculos de F2–F6 e das AC-02/05/13/21/23–26 foram recalculados e conferem, 0 conflitos com o registro (`unit_to_px` 1,5, `tick_rate` 60) e os valores do cânone (arena 1280×720, raio 18, Investida 220 u/10 ticks, hitstop 36) batem. Os dois bloqueantes são de contrato: a lista de camadas não bate com o Art Bible que cita (10 linhas contra "9 camadas", z sem fonte, parallax do primeiro plano ausente) e a câmera persegue a 60 Hz de física com suavização por quadro de render, sem posição interpolada.
Prior verdict resolved: First review
Findings:
- [BLOCKING] Detailed Design (R4) + Overview + Visual Requirements: "9 camadas do §6.3 com z do §8.6", mas a tabela tem 10 linhas com outra composição; z −30/−25/−20 não estão no §8.6; o §8.6 põe o primeiro plano em Parallax2D 1,1–1,2 e o GDD não tem fator de parallax nem regra de sangria/deriva para camadas com parallax.
- [BLOCKING] Detailed Design (R7) + F3: `P` vem da física a 60 passos/s e a suavização roda por quadro de render; em > 60 Hz a câmera treme. Definir `P` interpolado e a fonte do "tempo real" (o `delta` de `_process` é escalado por `Engine.time_scale`).
- [RECOMMENDED] Detailed Design (R1) + AC-01/02/03: pillarbox acima de 43:18 não é nativo do `keep_height`; exige troca em tempo de execução no `size_changed` (escopo do ADR).
- [RECOMMENDED] Formulas (F2): lookahead do mouse com `L` cheio em qualquer distância; com o cursor sobre o personagem o alvo salta até 240 px.
- [RECOMMENDED] Formulas (F5) + States (Intro de chefe): falta a composição do zoom da intro com o zoom dos impulsos; AC-30 testa só a intro.
- [RECOMMENDED] Game Feel: "acompanham o hitstop (… chefe 0,30 s)" confunde meia-vida com hitstop (chefe = 36 passos = 0,6 s).
- [RECOMMENDED] Acceptance Criteria (AC-30): "Todas as transições da tabela funcionam" não é testável; enumerar as transições com resultado.
- [RECOMMENDED] Dependencies: o GDD de Conteúdo não lista `CameraTuning` na tabela de `*Tuning` por sistema.
- [ADVISORY] Estrutura: Player Fantasy e Tuning Knobs ausentes (advisory no `standard`). Nice-to-have: R6 "sangria para o lookahead" enganosa; linha do Input na tabela de interações ("limiar do mouse") obscura; desempate do y-sort por spawn × pooling; onde a retícula é desenhada sob impulso; intro de chefe respeita o F4?
Reviewed-Content-Hash: design/gdd/cena-3-4-e-camera.md 25dedcea9a23d476bbd1c2a1f7b72ddf58b086e6
Reviewed-Content-Hash: design/registry/entities.yaml 1f8fd61bc45bcc1e5a3e242aa0184e02d1e42908
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/gdd/input-e-controle.md b8a36b427418daa826a878b66425fb9495f9c83e
Reviewed-Content-Hash: design/gdd/conteudo-orientado-a-dados.md 713f540fb86cae916ad0f8feb321742bd7402b30
Reviewed-Content-Hash: design/gdd/rng-com-seed.md 7120bf39aa292ef62c925a348a2f4b6657c2d27f
Reviewed-Content-Hash: design/gdd/game-concept.md 7a92fedac35eb57647163df6664bff45fef7fba2
Reviewed-Content-Hash: design/art/art-bible.md 5b3f20b7d140cd94e71176a860601c2b75f364a9

### Revisão aplicada — 2026-11-05 (mesma sessão, decisões do usuário)
- [BLOCKING → resolvido] R4: tabela = lista canônica de 10 camadas de render mapeada às 9 do §6.3; z −30/−25/−20 marcados como proposta; coluna parallax (primeiro plano 1,1–1,2, demais 1,0); F7 nova (deriva `|1−p| × ((L−tela)/2 + 40)`); Visual Requirements, Edge Cases, AC-09, AC-32, AC-33.
- [BLOCKING → resolvido] R7: `P` interpolado (`Engine.get_physics_interpolation_fraction`, interpolação de física ligada, `reset_physics_interpolation` no teleporte); relógio real `Time.get_ticks_usec`; AC-34, AC-35 (oráculo simulado: 0,22%), AC-28 com `time_scale` 0.
- [RECOMMENDED → resolvido] R1 pillarbox por troca de `content_scale_aspect` (ADR; AC-36); F2 lookahead `a = min(1, |m|/R_mouse)`, R_mouse 480 (AC-19); F5 `zoom_total = min(1,15; zoom_intro × zoom)` (States, AC-30); Game Feel meia-vida × hitstop; AC-30 enumerada; R6 sem "sangria para o lookahead".
- [RECOMMENDED → em aberto] `CameraTuning` no GDD de Conteúdo: Open Question 8 (não editado).
- APIs conferidas no Godot 4.7.2: `get_physics_interpolation_fraction`, `physics/common/physics_interpolation`, `reset_physics_interpolation`, `Time.get_ticks_usec`, `Window.content_scale_aspect/size`, `Parallax2D.scroll_scale`.
- Índice: linha 5 → In Review. Próximo: re-review em sessão nova.

## Review — 2026-11-05 — Verdict: APPROVED
Review mode: lean · Workflow: standard
Scope signal: L
Specialists: nenhum (modo lean)
Blocking items: 0 | Recommended: 4
Summary: Re-review do documento inteiro e das fontes citadas (Art Bible §3.4/§6.3/§8.6, Input R3/R5, Conteúdo F4/V2/tabela de `*Tuning`, RNG R1, conceito §11, cânone `ARENA_WIDTH/HEIGHT` 1280×720 e `PLAYER_RADIUS` 18). Os 2 bloqueantes anteriores estão resolvidos: R4 agora mapeia as 10 camadas de render às 9 do §6.3 com z e parallax batendo com o §8.6, e a F7 fecha a deriva; R7 define `P` interpolado e relógio real, e o oráculo da AC-35 (0,22%) confere em simulação. Todos os exemplos e oráculos de F1–F7 e das AC-02/05/13/19/21/23–26/30/32/34 foram recalculados e conferem; 0 conflitos com o registro (12 entradas). As 4 recomendadas são de implementação (ADR) ou de contrato entre GDDs e não bloqueiam.
Prior verdict resolved: Yes (2/2 bloqueantes; 5/6 recomendadas resolvidas, `CameraTuning` no Conteúdo segue como Open Question 8, coberto pela linha genérica "um por sistema MVP")
Findings:
- [RECOMMENDED] Detailed Design (R7): a câmera anda em `_process` com a interpolação de física do projeto ligada; o nó da câmera herda `physics_interpolation_mode` (padrão INHERIT) e seria interpolado de novo entre passos. Dizer que o nó da câmera fica com interpolação OFF (ela já calcula o próprio P); a AC-35 é simulada e não pega isso: acrescentar [M] a 144 Hz.
- [RECOMMENDED] Detailed Design (R4) + F7: o `Parallax2D` segue o scroll do `Camera2D` (`screen_offset`) e coincide com o mundo na origem da câmera, não no centro da câmara; com câmera própria (R9) ou corte (R10), é preciso `ignore_camera_scroll`/`screen_offset` manual ou `scroll_offset` por câmara. Acrescentar à lista do ADR (Overview).
- [RECOMMENDED] Edge Cases (câmara fora dos limites) + AC-15: atribui a rejeição ao V2 do Conteúdo, mas o V2 só valida faixas e regras dentro da classe, e o Conteúdo não tem classe de câmara. Nomear a regra como validação cruzada (câmara × `CameraTuning`) a definir no GDD de Câmaras, ou pedir uma V nova ao Conteúdo.
- [RECOMMENDED] Detailed Design (R9) × Input R5: a mira é lida no passo de física, mas a conversão usa `pos` do último quadro de render e o personagem aparece em P interpolado (até 1 passo atrás; 33 px na Investida). Dizer qual instantâneo da câmera e qual posição do jogador o Input usa.
- [ADVISORY] Estrutura: Player Fantasy e Tuning Knobs ausentes (advisory no `standard`; R11 e as tabelas de variáveis cobrem as faixas). Nice-to-have: "feixes" (§8.6, z 10) não aparecem na tabela da R4; AC-30 usa zoom_intro 1,3, fora da faixa 1–1,15 declarada (marcar como entrada fora de faixa); linha do Input na tabela de interações ("limiar do mouse") ainda obscura; desempate do y-sort por spawn × pooling; onde a retícula é desenhada sob impulso; a intro de chefe respeita o F4?; cabeçalho do GDD (linha 3) ainda diz "In Review".
Reviewed-Content-Hash: design/gdd/cena-3-4-e-camera.md bf9f8290fd25fbbcf0bfced27a6545f1e4b40409
Reviewed-Content-Hash: design/registry/entities.yaml 832cf69c5f7aadbfd447979cf318ec63197597e0
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/gdd/input-e-controle.md b8a36b427418daa826a878b66425fb9495f9c83e
Reviewed-Content-Hash: design/gdd/conteudo-orientado-a-dados.md 713f540fb86cae916ad0f8feb321742bd7402b30
Reviewed-Content-Hash: design/gdd/rng-com-seed.md 7120bf39aa292ef62c925a348a2f4b6657c2d27f
Reviewed-Content-Hash: design/gdd/game-concept.md 7a92fedac35eb57647163df6664bff45fef7fba2
Reviewed-Content-Hash: design/art/art-bible.md 5b3f20b7d140cd94e71176a860601c2b75f364a9

### Correções pós-aprovação — 2026-11-05 (pedido do usuário, mesma sessão da re-review)
- [RECOMMENDED → aplicado] R7: nó da câmera com `physics_interpolation_mode` = `OFF` (no 4.7.2 o `Camera2D` herda `INHERIT`; o `Parallax2D` já vem `OFF`). AC-38 nova ([I] modo do nó + [M] 144 Hz com gravação retida).
- [RECOMMENDED → aplicado] R4 + Overview (lista do ADR): âncora do parallax. O `Parallax2D` coincide com o mundo com `screen_offset` zero, não no centro da câmara: `ignore_camera_scroll` + `screen_offset` à mão ou `scroll_offset` por câmara, refeito no corte.
- [RECOMMENDED → aplicado] Edge Cases + AC-15: o tamanho de câmara vira validação cruzada câmara × `CameraTuning`, dona o GDD de Câmaras (V2 não cobre); Open Question 9 nova.
- [RECOMMENDED → aplicado] R9: "Instantâneo da mira": o Input usa a `pos` do último render e mede a mira a partir de `P_atual`; a câmera usa P interpolado. Diferença de até 1 passo aceita. AC-37 nova.
- Cabeçalho do GDD já estava em Approved (outra sessão). Nota de revisão em Formulas atualizada. Nice-to-haves não aplicados. Um re-review não é necessário: as mudanças só detalham a implementação e não mexem em fórmulas nem valores.

### Mudança externa — 2026-11-06 (GDD Input e controle, 3ª re-review)
- Por decisão do usuário, o Input passou a expor `fonte_mira`, `intensidade_mira` (amostra, Input R2) e uma consulta de cursor lida no quadro de render (Input R5), para o lookahead da F2. Neste GDD: a linha do Input em Interactions agora lista esses dados e não cita mais a "posição da câmera para o limiar do mouse", que a F5 do Input não usa; o Input entrou em "Depende de" (Suave, por contrato), com uma nota de ciclo. Índice: Depends On da linha 5 e um ciclo novo em Circular Dependencies. Nenhuma regra, fórmula ou valor mudou, e o status segue Approved. Reconferir na próxima revisão.

## Revisão aplicada — 2026-11-06 (warnings do `/review-all-gdds` de 2026-11-06)

Fonte: `design/gdd/gdd-cross-review-2026-11-06.md` (veredito FAIL; este GDD só com warnings). Decisão do usuário no C-W7. Status: Approved → **In Review** até a próxima `/review-all-gdds`.

| Achado | Correção no GDD |
|---|---|
| C-W6 Input em Depende de | Já aplicado em 2026-11-06 (mudança externa acima). Agora também no Quick reference e nas Cross-References (Input R2, R5, R6, F2, F3). Índice: l. 155 corrigida (Input → Cena é forte). |
| C-W7 hitstop × `time_scale` | Decisão do usuário: proibir `time_scale`. R7: o hitstop é contador de passos do Combate núcleo (física rodando, sistemas vivos pulam o passo), requisito para o GDD de Combate; a câmera mantém o relógio real. Edge Cases e AC-28 reescritos (sem a variante `time_scale` = 0). Interactions e Dependencies: requisito registrado na linha do Combate. |
| C-W8 dono do hitstop | F5: coluna "Hitstop (referência, `CombatTuning`)" com os nomes do cânone (`HITSTOP_LIGHT`/`HEAVY`/`BOSS_KILL`; 36 só na morte do chefe) e nota de que a Cena é dona só de h, Ak, As e Z. Game Feel idem. |
| C-W9 `unit_to_px` | R2 e F1: a F1 é a F4 do Conteúdo, aplicada só no script de importação; o jogo lê px e não converte de novo. AC-07 vira teste do script de importação. Interactions, Dependencies e Cross-References atualizadas. |
| C-I2 OQ8 | Fechada: o Conteúdo lista o `CameraTuning` (R1 e Interactions). Nota de bidirecionalidade atualizada. |
| C-I3 limiar do mouse | Já aplicado em 2026-11-06 (mudança externa acima); a linha do Input em Interactions não cita mais a posição da câmera. |

Nenhuma fórmula ou valor de câmera mudou.

## Review — 2026-11-08 — Verdict: APPROVED
Review mode: lean · Workflow: standard
Scope signal: L
Specialists: nenhum (modo lean)
Blocking items: 0 | Recommended: 4
Summary: Re-review do documento inteiro depois dos warnings da 1ª passada do `/review-all-gdds` (C-W6–C-W9, C-I2, C-I3). Nenhuma mudança de 2026-11-06 quebrou algo. O hitstop como contador de passos e a câmera em tempo real (R7, Edge Cases, AC-28) batem com Input R6/F3 e Modificadores R6. A coluna de hitstop da F5 é só referência ao `CombatTuning` e confere com o cânone (`engine.ts:63–67`). `unit_to_px` só na importação (R2, F1, AC-07) bate com Conteúdo F4, R6 e Interactions. Input em "Depende de" bate com Input R2/R5, e a OQ8 está fechada. Exemplos de F2/F3/F5/F7 e AC-05/19/23/25/26/30/32 recalculados, todos conferem; 0 conflitos com o registro (12 entradas). Testado no Godot 4.7.2 instalado: com `Engine.time_scale = 0`, `_physics_process` continua a ~60/s com `delta` 0, então a justificativa antiga da R7 estava errada (a regra continua).
Prior verdict resolved: Yes (os 6 itens de 2026-11-06 conferidos; a 2ª passada do cross-review não trouxe item novo para a Cena)
Findings:
- [RECOMMENDED] Detailed Design (R7): "com `time_scale` = 0 não há passo de física" é falso no 4.7.2 (passos continuam com `delta` 0). O motivo certo: contadores de passo contariam o hitstop como vivo, e um `time_scale` fracionário quebra o passo fixo de 1/60.
- [RECOMMENDED] Edge Cases + Acceptance Criteria: falta o caso da câmera sem `CameraTuning` (retirado ao sair de Pronto, ou catálogo em Falhou; Conteúdo l. 727–739, l. 375). É o lado da Cena do S-W4.
- [RECOMMENDED] Detailed Design (R12) + AC-28: a AC-28 media "0,1 s reais" e a R12 não injetava o relógio, então o teste dependia do tempo real.
- [RECOMMENDED] systems-index linha 5 (C-I5): o Depends On não cita Câmaras e ondas nem Acessibilidade, e o GDD lista as duas como Suave, por contrato.
- [ADVISORY] Estrutura: Player Fantasy e Tuning Knobs ausentes (advisory no `standard`). Nice-to-have: na AC-07, trocar a cláusula "em jogo, usa 27" por uma busca de 0 `unit_to_px` em `src/`, e o teste do script é do Conteúdo; o índice l. 156 diz "9 camadas"; continuam abertos os nice-to-haves de 2026-11-05.
Reviewed-Content-Hash: design/gdd/cena-3-4-e-camera.md b061430d1e8e5d76d6e3dcd43c6071ed03eaeaea
Reviewed-Content-Hash: design/registry/entities.yaml 03b431a3014ea0ed34194a06bdc78843376f3fc0
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/gdd/input-e-controle.md 2ea385c0168ba5678a78ce6d1337c978d2aeaa96
Reviewed-Content-Hash: design/gdd/conteudo-orientado-a-dados.md aaa3594233936dd8d81a87d75dd66b8ed11214bd
Reviewed-Content-Hash: design/gdd/modificadores-e-atributos.md e35d33e0ca4fb5045bcadb4955df5c08107ee528
Reviewed-Content-Hash: design/gdd/gdd-cross-review-2026-11-06b.md 99e8ac82721c627d39bba1ca0412034fc3cecb41

### Correções pós-aprovação — 2026-11-08 (pedido do usuário, mesma sessão da re-review)
- [RECOMMENDED → aplicado] R7: justificativa do hitstop sem `time_scale` reescrita com o comportamento conferido no 4.7.2.
- [RECOMMENDED → aplicado] R12: o relógio real da R7 e o `CameraTuning` passam a ser injetados; AC-28 com relógio roteirizado.
- [RECOMMENDED → aplicado] Edge Cases: câmera sem `CameraTuning` (parada, sem lookahead nem impulsos, nenhum valor fixo no código; Corte na câmara seguinte); AC-39 nova; linha do Conteúdo em Interactions cita injeção e retirada.
- [RECOMMENDED → em aberto] C-I5 no índice (não aplicado, escolha do usuário).
- Status: cabeçalho do GDD e linha 5 do índice → **Approved**; Next Steps atualizado. Nenhuma fórmula ou valor mudou.
- O carimbo de hash acima foi gerado **depois** destas correções. Elas são pequenas e foram conferidas ao escrever, mas não passaram por uma re-review separada.
