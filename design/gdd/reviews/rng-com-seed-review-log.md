# Review Log — RNG com seed

## Review — 2026-11-05 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Scope signal: M
Specialists: nenhum (modo lean)
Blocking items: 2 | Recommended: 4
Summary: Matemática exemplar: todos os vetores F1–F8, fmix32 e AC-09 foram recalculados de forma independente em Python e conferem; 0 conflitos com o registro; estados, injeção e ACs sólidos. Os dois bloqueantes estão no contrato de reprodução R7, a promessa central do sistema: o consumo de `spawn` pode depender do combate, e o contrato omite a troca de ofertas e o estado inicial da run. Correções curtas e textuais.
Prior verdict resolved: First review
Findings:
- [BLOCKING] Detailed Design (R4/R7) + AC-27: nada proíbe que o número de sorteios nas finalidades 1–6 dependa do combate; o cânone `randomSpawnPoint` (engine.ts:350) rejeita pontos perto do jogador (até 14 tentativas) e os reforços do chefe (engine.ts:1126) sorteiam spawn no meio da luta. Falta regra de consumo fixo, destino das invocações (`ia`) e AC com posição do jogador diferente.
- [BLOCKING] Detailed Design (R7): contrato omite o uso de "Trocar ofertas" (conceito §5, cânone §57.3) e o estado inicial da run (arma/Doutrina jurada, melhorias da Oficina), que mudam pool, cargas de troca e raridade das bênçãos; falta dizer onde isso fica registrado.
- [RECOMMENDED] Detailed Design (R3) + AC-25: sem finalidade de layout/obstáculos, embora o Overview prometa "as mesmas câmaras" (cânone `buildObstacles`, engine.ts:268).
- [RECOMMENDED] Formulas (F6) + Edge Cases + AC-15: com pesos inteiros e W = 2³¹ exato, `C_último·2³²` = 2⁶³ estoura int64; limite deve ser W ≤ 2³¹−1.
- [RECOMMENDED] Dependencies (R8): impressão do catálogo segue provisória, sem dono no GDD de Conteúdo.
- [RECOMMENDED] Estrutura: Tuning Knobs e Player Fantasy ausentes (advisory no `standard`).
Reviewed-Content-Hash: design/gdd/rng-com-seed.md 0d9f92867cb96575143991bafd647cdc0dd80af5
Reviewed-Content-Hash: design/registry/entities.yaml 6425f6c34695e858cbdfe728f801dc00ce2432a1
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/gdd/conteudo-orientado-a-dados.md 282013685bbe56afa56bba088a2e13f6a7c2eb51
Reviewed-Content-Hash: design/gdd/game-concept.md 7a92fedac35eb57647163df6664bff45fef7fba2

### Revisão aplicada — 2026-11-05 (mesma sessão, decisões do usuário)
- Bloqueante 1 → R4b "Consumo fixo" (K candidatos de spawn; reforços no meio da luta → `ia`), R3/R7 ajustadas, Edge Cases, AC-34 e AC-35.
- Bloqueante 2 → R7 com 6 elementos (+ estado inicial da run, + usos de "Trocar ofertas"), registrados na telemetria e no relatório de erro; texto da seed inalterado; AC-23 e AC-27 ajustados.
- Recomendada aplicada → finalidade 8 `layout`; "finalidades de estrutura" = 1–6 e 8; F2, AC-25, AC-30 e nota do registro ajustados.
- Não aplicadas: limite W ≤ 2³¹−1 no F6; seção Tuning Knobs. Status → In Review, aguardando re-review.

## Review — 2026-11-05 — Verdict: APPROVED
Review mode: lean · Workflow: standard
Scope signal: M
Specialists: nenhum (modo lean)
Blocking items: 0 | Recommended: 5
Summary: Re-review independente. Os 2 bloqueantes do R7 estão resolvidos: R4b (K candidatos fixos, reforços no meio da luta → `ia`) e R7 com 6 elementos fecham o contrato, e o cânone confirma que os demais sorteios de estrutura (`buildObstacles`, `buildWaves`, elites, `spawnDoors`, `rollBoonOffer`) só dependem de profundidade, conteúdo e escolhas, e que "Trocar ofertas" só toca as bênçãos (engine.ts:1254). Vetores F1–F8 e AC-09 recalculados de novo em Python: conferem; 0 conflitos com o registro (`stream_state` já diz 1–8). A revisão deixou três textos defasados, todos curtos e não bloqueantes.
Prior verdict resolved: Yes
Findings:
- [RECOMMENDED] Detailed Design (R7, linhas 163–166): diz que os usos de troca ficam na telemetria de **início** de run, o que é impossível e contradiz AC-23, Interactions e Dependencies (trocas no fim, com o caminho).
- [RECOMMENDED] Summary (linhas 14–17): promete `spawn` reproduzível "não importa como o jogador lute" (R7 exclui o ponto escolhido), omite `layout` e não cita estado inicial nem trocas.
- [RECOMMENDED] Formulas (F6) + Edge Cases + AC-15 (herdada): com pesos inteiros e W = 2³¹ exato, `C_último·2³²` = 2⁶³ estoura int64; o erro deve valer para W > 2³¹−1.
- [RECOMMENDED] Dependencies (R8) (herdada): impressão do catálogo segue provisória, sem dono no GDD de Conteúdo (Open Question 1).
- [RECOMMENDED] Estrutura (herdada): Tuning Knobs e Player Fantasy ausentes (advisory no `standard`).
- [NICE-TO-HAVE] Acceptance Criteria (AC-33): "≤ 7 fluxos" por câmara ficou desatualizado com a finalidade 8 (até 8 fluxos).
- [NICE-TO-HAVE] Edge Cases (Trocar ofertas) + AC-27 variante C: "só as ofertas daquela profundidade mudam" vale só se a bênção escolhida for a mesma; a variante C deve dizer qual oferta B escolhe sem a troca (ex.: o mesmo índice).
- [NICE-TO-HAVE] Detailed Design (R4b): exigir que a regra de escolha entre os K candidatos sempre devolva um deles (fallback, como o último candidato do cânone), para ninguém sortear de novo quando nenhum serve.
Reviewed-Content-Hash: design/gdd/rng-com-seed.md 95015742492d3144a947d301bfda83e0262c5309
Reviewed-Content-Hash: design/registry/entities.yaml bd8ade7b75e958096d5bee56d03838b3a68cfd0e
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/gdd/conteudo-orientado-a-dados.md 282013685bbe56afa56bba088a2e13f6a7c2eb51
Reviewed-Content-Hash: design/gdd/game-concept.md 7a92fedac35eb57647163df6664bff45fef7fba2

### Correções pós-aprovação — 2026-11-05 (mesma sessão, pedido do usuário)
- Cabeçalho do GDD → Status: Approved.
- R7: estado inicial na telemetria de início; caminho (escolhas e usos de troca) na de fim; relatório de erro traz os dois (agora bate com AC-23).
- Summary: cita estado inicial, trocas de oferta, obstáculos e "candidatos de spawn", e remete à R7.
- AC-33: "≤ 7 fluxos" → "≤ 8 fluxos".
- Só texto; nenhuma regra, fórmula ou AC mudou de sentido. Os hashes acima são da versão revisada, então a próxima checagem vai acusar CHANGED. Em aberto: F6 W ≤ 2³¹−1, impressão do catálogo, Tuning Knobs/Player Fantasy e os nice-to-have (variante C do AC-27, fallback da R4b).

### Nota — 2026-11-05 (re-review do GDD de Conteúdo, a pedido do usuário)
Só alinhamento de texto, sem mudar regra: a impressão do catálogo agora está definida no Conteúdo R12 (SHA-256 sobre a serialização canônica; curta de 4 hex maiúsculos para o texto da seed, completa de 64 hex). Interactions, Dependencies, Cross-References e Open Question 1 deixaram de dizer "provisório" ou "pedido". Como o arquivo mudou, o recibo desta revisão vai acusar CHANGED no próximo `/design-review`.
