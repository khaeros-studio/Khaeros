# Story 002: Máquina de fases, surgimento e comportamento melee

> **Epic**: IA de inimigos e elites
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/ia-de-inimigos-e-elites.md` (R3–R7, F3)
**Requirement**: `TR-ia-003`, `TR-ia-004` (fluxo `ia`), `TR-ia-005`

**ADR Governing Implementation**: ADR-0018: IA de inimigos e chefe (§3, §9); ADR-0014; ADR-0005: RNG determinístico
**ADR Decision Summary**: `enum Fase { SURGINDO, APROXIMACAO, PREPARO, EXECUCAO, RECUPERACAO, ... }`; `passo(id)` na ordem fixa do §3; comportamentos sem estado (`ComportamentoMelee`). Espera inicial `20 + ia.inteiro(50)`; recuperação `recarga` + `10 + ia.inteiro(30)`. Preparo = `iniciar_telegrafo(...)` (recusa → fica em aproximação e tenta no seguinte); execução no passo de `disparou_neste_passo`. Fluxo `ia` só em `ao_surgir` e no fim da recuperação, em ordem de id.
**ADR Version**: ADR-0018 2026-11-16 · ADR-0014 2026-11-16 · ADR-0005 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: timers em passos vivos; RNG só pelo fluxo `ia`
- Forbidden: contador de preparo na IA; `randf`/`randi`/`shuffle` (lint do ADR-0005)
- Guardrail: zero alocação em `passo()`

---

## Acceptance Criteria

- [x] AC-IA-01 — 50 passos de surgimento (não atingível, sem ataque/telégrafo/status); no 50, aproximação com `timer` 20 + n
- [x] AC-IA-02 — Eco anda 2,55 px/passo; `timer` ≤ 0 e ≤ 78 px: preparo e `iniciar_telegrafo` 1×; 79: não
- [x] AC-IA-05 — preparo parado 26 passos; execução sai no passo do disparo
- [x] AC-IA-06 — 24 telégrafos ativos: recusa, fica em aproximação, tenta no seguinte
- [x] AC-IA-07 — dentro do setor: `ferir_jogador(9)` 1× e parado 10 passos; fora: sem dano, mesmos 10
- [x] AC-IA-10 — recuperação do Eco 50 passos, anda 1,02 px/passo se > 90 px; fim: `timer` 10 + n
- [x] AC-IA-22 (Eco) — ciclo mínimo do Eco 96 passos

---

## Implementation Notes

- Todo estado no `InimigoRef`; `Comportamento` é `@abstract` com `ao_surgir` e `decidir`.
- Números do `IATuning`/`EnemyDef` já em passos e px.

---

## Out of Scope

- story-003: ranged/charger; story-004: lentidão/cambaleio; story-005: quebra

---

## Files

- src/gameplay/ia/modulo_de_ia.gd
- src/gameplay/ia/comportamento_melee.gd
- tests/unit/ia/ia_fases_e_melee_test.gd

Fatia: `game_session.gd::_enemy_step`/`_enemy_fire` (fases em string, `randf` direto) — **substituir**; a fatia é só referência de comportamento.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ia/ia_fases_e_melee_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/ia-de-inimigos-e-elites/story-001-lista-estavel-e-consultas.md`; `production/epics/telegrafos/story-001-pool-teto-e-ciclo.md`, `production/epics/telegrafos/story-004-disparo.md`; épico `production/epics/rng/` (fluxo `ia`)
- Unlocks: `production/epics/ia-de-inimigos-e-elites/story-003-ranged-charger-e-vista.md`, `story-004-andar-conter-e-separacao.md`
