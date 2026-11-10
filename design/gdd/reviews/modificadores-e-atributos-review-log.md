# Review Log — Modificadores e atributos

## Review — 2026-11-06 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Scope signal: M
Specialists: nenhum (lean); leitura crítica por revisor independente em contexto limpo (o autor do GDD é a sessão que rodou a revisão, a pedido do usuário)
Blocking items: 5 | Recommended: 9
Summary: Núcleo correto (F1/F2/F4/F5, as 21 chaves e os oráculos batem com o cânone), mas a semântica dos gatilhos, a janela pós-esquiva, a granularidade do 4º acerto e a F3 deixariam o programador adivinhando ou divergindo do cânone sem registro. Revisão aplicada na mesma sessão com decisões do usuário (Abalo vale para projéteis; demais pontos pela paridade com o cânone).
Prior verdict resolved: First review
Findings:
- [BLOCKING] Detailed Design R4 + AC-09: `apos_esquiva` contraditório; cânone abre no início da esquiva e consome no disparo, para todos os alvos — corrigido (R4, AC-09; OQ3 fechada).
- [BLOCKING] Detailed Design R4/R11/F2: granularidade e momento de avaliação do M indefinidos (por alvo, projétil no disparo, Selo por tick, parede) — corrigido (R12 nova).
- [BLOCKING] Detailed Design R5: 7 gatilhos sem semântica (reflexo pós-escudo e sem projétil, explosão sem M em cadeia de 4, cura por qualquer morte, corte não conta acerto, status fracionário, recusa substitui a Vida) — corrigido (R13 nova).
- [BLOCKING] Formulas F3 + AC-24: escudo fora da ordem, faixa de saída errada, exemplos contraditórios, Abalo × projétil indefinido — corrigido (F3; Abalo vale para projéteis, divergência registrada).
- [BLOCKING] Formulas F1 + R3: produto de dois negativos positivo; condição em qualquer atributo; `valor()` de `dano_*` indefinido — corrigido (max(0,…), condição só em `dano_todo`).
- [RECOMMENDED] R6: duração em passos inteiros; reaplicar usa max — aplicado.
- [RECOMMENDED] R9: escudo substitui na câmara; trocas/recusas sobem e descem; Vida inicial — aplicado.
- [RECOMMENDED] R10: armadura da elite fica com IA/Combate; chefe × 0,12 testado — aplicado.
- [RECOMMENDED] R2: `dano_esquiva` removido — aplicado.
- [RECOMMENDED] F2: inimigos e `slots` ausente — aplicado.
- [RECOMMENDED] Formulas: tabela de divergências deliberadas; Summary sem "exatamente" — aplicado.
- [RECOMMENDED] Cruzamento com Conteúdo: `ModifiersTuning`, checagem de params divergentes, referência R8 → R5, unidade de `empurrao` — tabela adicionada aqui; pedidos ao Conteúdo na Open Question 6.
- [RECOMMENDED] Acceptance: ~10 ACs com números concretos; AC-29 (agora AC-32) com 17 níveis e caminhos do fixture — aplicado (32 ACs).
Nota: hash do GDD omitido de propósito — o documento foi revisado nesta mesma sessão depois da revisão; a re-review deve lê-lo inteiro.
Reviewed-Content-Hash: design/registry/entities.yaml 9e15742c879b4df6d25276f67cc172e8a4772594
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/gdd/conteudo-orientado-a-dados.md 713f540fb86cae916ad0f8feb321742bd7402b30
Reviewed-Content-Hash: design/gdd/game-concept.md 7a92fedac35eb57647163df6664bff45fef7fba2

## Review — 2026-11-06 — Verdict: NEEDS REVISION
Review mode: lean · Workflow: standard
Scope signal: L
Specialists: nenhum (lean); re-review independente em sessão separada (só o GDD e as fontes que ele cita)
Blocking items: 1 | Recommended: 4
Summary: Os 5 bloqueantes anteriores foram resolvidos e o núcleo bate com o cânone (21 chaves, F1–F5, oráculos dos ACs, máximo ≈14,08, elite/profundidade, 18 Tradições e 17 níveis). Resta um bloqueante pequeno: a R12 avalia M da investida no impacto, mas o cânone congela o dano no disparo, e lida ao pé da letra a Penumbra nunca fortalece a investida. Usuário escolheu revisar em outra sessão.
Prior verdict resolved: Yes (5/5)
Findings:
- [BLOCKING] Detailed Design R12: linha "Especial (incl. investida)" diz M "por alvo, no impacto"; cânone congela `p.lungeDamage` no disparo (`engine.ts:758`) e consome `empowerTicks` ali (`:677`) — tratar como projétil (M no disparo, 4º acerto no impacto) e cobrir no AC-29.
- [RECOMMENDED] Detailed Design R13 + AC-30: mortes além do 4º passe da explosão não definidas (cânone: processadas no passo seguinte).
- [RECOMMENDED] Edge Cases × R6: reaplicar fonte "substitui" × duração `max(restante, nova)` — dizer que o valor substitui e a duração segue a R6.
- [RECOMMENDED] Cruzamento com Conteúdo: `:617` usa `{status.abalo.reducao_dano:pct}`, nome que colide com o atributo `reducao_dano` daqui (Abalo é `dano_todo` × 0,7).
- [RECOMMENDED] Registry: expressão de `hit_damage_multiplier` só cita multiplicadores condicionais; a F2 inclui os incondicionais (elite, Abalo).
- [NICE-TO-HAVE] Interactions (l. 302) "−30%" → "× 0,7"; linha da F3 na tabela de divergências (produto comutativo, só ponto flutuante); lentidão do Selo e cambaleio como regras, não modificadores; R9 com recusas descendo depois de gastas.
Reviewed-Content-Hash: design/gdd/modificadores-e-atributos.md ab1a1fd01d956a852143b88a289f5946382f53de
Reviewed-Content-Hash: design/registry/entities.yaml 9e15742c879b4df6d25276f67cc172e8a4772594
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md a63d8fba9b7142eeb43791f061e2e1533c429b43
Reviewed-Content-Hash: design/gdd/conteudo-orientado-a-dados.md 713f540fb86cae916ad0f8feb321742bd7402b30
Reviewed-Content-Hash: design/gdd/game-concept.md 7a92fedac35eb57647163df6664bff45fef7fba2

## Revisão aplicada — 2026-11-06 (mesma sessão da re-review, decisões do usuário)

| Achado | Correção no GDD |
|---|---|
| [BLOCKING] Investida na R12 | Linha nova "Investida (`lunge`, Ataque ou Especial)": M congelado no disparo (`p.lungeDamage`), 4º acerto no impacto; caso novo no AC-29 (2,1 mesmo com a janela consumida e a Vida curada). |
| [RECOMMENDED] Explosão em cadeia | R13 e AC-30: mortes além do 4º passe são processadas no passo seguinte. |
| [RECOMMENDED] Reaplicar fonte | Edge Cases: o valor substitui; a duração segue a R6. |
| [RECOMMENDED] Campo do Abalo | R5: 0,7 = 1 − `reducao_dano_causado` do `StatusTuning` (nome acertado no Conteúdo). Interações: "× 0,7". |
| [RECOMMENDED] Registro | `hit_damage_multiplier`: expressão cita multiplicadores incondicionais e condicionais (revised 2026-11-06). |
| Decisão do usuário | `empurrao` em px/s (F2 do Conteúdo, × 90), não × 1,5. |

## Revisão aplicada — 2026-11-06 (warnings do `/review-all-gdds` de 2026-11-06)

Fonte: `design/gdd/gdd-cross-review-2026-11-06.md` (veredito FAIL; este GDD só com warnings). Decisão do usuário na AC-29. Status: Approved → **In Review** até a próxima `/review-all-gdds`.

| Achado | Correção no GDD |
|---|---|
| C-W1 tokens de forma | R12: `arc`/`circle`/`lunge` → `arco`/`circulo`/`avanco` (e `projetil` na linha do projétil), com nota de que os tokens são os do mapa R2 do Conteúdo. |
| C-W5 arma de Pactos | R12: regra genérica ("mudança de Vida entre alvos, por exemplo arma com cura por acerto"); nenhuma arma de fábrica do MVP cura por acerto. AC-29: "Círculo de Pacto" → Corte da Lâmina do Juramento (`arco`) com portador falso que muda a Vida para 55 depois do 1º alvo (decisão do usuário: Vida roteirizada). |
| C-I1 nomes provisórios | Apagada a frase sobre os provisórios do mapa do Conteúdo (`dash_damage` etc.). |
| OQ6 (C-W2/C-W3) | Fechada: o Conteúdo já lista o `ModifiersTuning` (R1, Interactions, Dependencies) e tem a V11 (AC-50). R2 (cabeçalho do `ModifiersTuning`), Edge Cases (params divergentes) e AC-26 agora citam a V11. |

Nenhuma fórmula ou valor mudou.
