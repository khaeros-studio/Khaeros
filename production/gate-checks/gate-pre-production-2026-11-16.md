# Gate Check: Technical Setup → Pre-Production

**Date**: 2026-11-17 (re-executado após fechamento da arquitetura, dos experimentos `EX-0001..0016` + `EX-0011 E1–E7`, da revisão `TD-MANIFEST` e do painel de diretores; avaliação inicial em 2026-11-16)
**Checked by**: `gate-check` skill (`technical-director` + `producer` + `lead-programmer` + `godot-specialist`)
**Gate file**: `.claude/skills/gate-check/references/gate-pre-production.md`
**Config resolvida**: `workflow: standard` · `review_mode: lean` · `qa.level: standard` · `team.size: individual` · `testing.strict`: unset (logic/integration = BLOCKING por padrão) · `performance.enforce: warn` · `system_overrides`: none · `project.stage`: `"Pre-Production"` (avançado após este PASS)

## Required Artifacts (tier `standard`): 9/9 presentes

- [x] Engine escolhida: Godot 4.7 em `CLAUDE.md` e `project.yaml` (`engine.name: "Godot"`, 4.7.2 instalado)
- [x] Configuração do projeto: `project.yaml` tem `engine`, `naming` e `performance` (`target_fps: 60`, `frame_budget_ms: 16.6`, `max_draw_calls: 500`, `memory_ceiling_mb: 512`), sincronizados em `.claude/docs/technical-preferences.md` (com `Forbidden Patterns` e `Architecture Decisions Log` `ADR-0001..0018`)
- [x] Art bible `design/art/art-bible.md`: 9 seções `##`; sign-off AD-ART-BIBLE "SKIPPED 2026-11-05 — lean mode"
- [x] ADRs Foundation (no `standard`, só os críticos): 18 ADRs (`ADR-0001` a `ADR-0018`), **18/18 `Accepted` em 2026-11-16** e atualizados com as verificações `EX-0001..0016` em 2026-11-17
- [x] Referência da engine: `docs/engine-reference/godot/VERSION.md` (pin 4.7, instalado 4.7.2, sem gap)
- [x] Framework de testes: `addons/gdUnit4/`, `tests/unit/` e `tests/integration/` existem
- [x] CI: `.github/workflows/tests.yml`
- [x] Teste de exemplo: `tests/unit/smoke/smoke_framework_test.gd` (+ suítes unitárias e de integração em `tests/`)
- [x] `docs/architecture/architecture.md` (`v1.13`, 2026-11-17)

Recomendados no `standard` (todos presentes):
- [x] `docs/architecture/requirements-traceability.md` (`400/400 ✅ Covered (Accepted) (100%)`)
- [x] `docs/architecture/control-manifest.md` (`TD-MANIFEST: PASS (2026-11-17)` por `lead-programmer`)
- [x] `design/accessibility-requirements.md`: **Accessibility Tier Target: Standard**
- [x] `design/ux/interaction-patterns.md` + `design/ux/hud.md` + 5 telas
- [x] `production/epics/index.md` (30 épicos, 265 stories, `400/400` TRs) + `production/sprints/sprint-001.md..sprint-009.md` (`48/49` stories da Sprint 1 `done`)

## Quality Checks: 12/12 passando

- [x] `/architecture-review` modo `full` executado e aprovado: [architecture-review-2026-11-16.md](../../docs/architecture/architecture-review-2026-11-16.md) (`Mode: full`, **`Verdict: PASS`**)
- [x] Matriz de rastreabilidade com **zero gaps em todas as camadas**: **400 TRs, ✅ 400 (`100%`), 🟡 0, ⚠️ 0, ❌ 0** (`TR-conteudo-015` fechado com PC de referência e medições `160,8 ms / 86,2 ms ≤ 250 ms` no `ADR-0004`)
- [x] Auditoria de engine sem API depreciada (`18/18` com Engine Compatibility no pin 4.7.2; `Engine Specialist: PASS` por `godot-specialist`)
- [x] 18/18 ADRs com seção Engine Compatibility e resultados de `EX-0001..0016` + `EX-0011 E1–E7`
- [x] 18/18 ADRs com seção GDD Requirements Addressed
- [x] 18/18 ADRs com seção ADR Dependencies
- [x] Versão de engine consistente (4.7 / 4.7.2)
- [x] `adr-dep-graph.sh`: 18 ADRs, 91 arestas, **nenhum `CYCLE:`**, nenhum `NO_DEPS_SECTION`/`UNFILLED_DEPS`
- [x] Domínios HIGH RISK do `VERSION.md` verificados nos experimentos `EX-0001..0016` e documentados nos ADRs e em `architecture.md` `v1.13` (`0` questões abertas de MVP em `§Open Questions`)
- [x] Naming e budgets definidos em `project.yaml` e `.claude/docs/technical-preferences.md` (`60 fps`, `16,6 ms`, `≤ 500 draw calls`, `memory_ceiling_mb: 512`)
- [x] Tier de acessibilidade definido (`Standard`)
- [x] **Suíte de testes e classes da Foundation íntegras**: classes `GeradorDeIds`, `InimigoRef`, `JogadorRef` e `RetratoDeMortos` presentes em `src/foundation/entidades/` e `tests/unit/save/armazem_de_arquivos_e_caminhos_test.gd` concluído sem erros de parse (`10/10` stories de `persistencia` e `8/8` de `orquestrador-do-passo` em `Done`).

## Director Panel Assessment: 2/2 PASS (`READY`)

- **`technical-director` (`TD-PHASE-GATE`)**: **`READY / PASS`** — 18/18 ADRs `Accepted`, `400/400 ✅ Covered (Accepted)`, zero gaps e zero ciclos, todos os experimentos de engine `EX-0001..0016` e `EX-0011 E1–E7` verificados e propagados, PC de referência e orçamentos de CPU/memória fixados.
- **`producer` (`PR-PHASE-GATE`)**: **`READY / PASS`** — 30 épicos e 265 stories integralmente decompostos sem bloqueios (`0 Blocked`), marco MVP ([mvp.md](../milestones/mvp.md)) e 9 sprints ([sprint-001.md](../sprints/sprint-001.md) a `sprint-009.md`) planejados, com `48/49` stories da Sprint 1 já entregues (`done`).

## Blockers

- **Nenhum.** (Os 2 bloqueantes de 2026-11-16 foram integralmente resolvidos.)

## Verdict: PASS

Todos os artefatos obrigatórios e recomendados do tier `standard` estão completos, as 12 checagens de qualidade passam (`400/400 ✅ Covered`, `18/18 ADRs Accepted`, `9/9` stories de `experimentos-de-engine` em `Done`, `TD-MANIFEST: PASS`) e o painel de diretores (`TD-PHASE-GATE` + `PR-PHASE-GATE`) aprovou a transição com `READY / PASS`.

## Stage

**Avançado para `Pre-Production`** em `production/stage.txt` e `project.yaml` (`2026-11-17`).
