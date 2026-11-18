# Story 005: Elites (sorteio e números), armadura e quebra dos comuns

> **Epic**: IA de inimigos e elites
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/ia-de-inimigos-e-elites.md` (R8, R10, F1, F2)
**Requirement**: `TR-ia-004` (fluxo `elites`), `TR-ia-007`, `TR-ia-008`, `TR-ia-010`

**ADR Governing Implementation**: ADR-0018 (§3 quebra, §9 elites); ADR-0005: RNG; ADR-0009: Atributos e modificadores; ADR-0010; ADR-0014
**ADR Decision Summary**: `RegrasDeElite.sortear_elite(profundidade, ja_ha_elite, fluxo_elites)` (static) consome 1 real sempre; chamado pelas Câmaras, nunca na câmara do chefe; máximo 1 elite por onda. Elite, chefe e profundidade são fontes no portador (`elite`, `chefe`, `profundidade`). "Quebrou!" chega por `pedir_recuperacao(id, passos)` só para comuns; elite e chefe têm armadura (o Combate não chama).
**ADR Version**: ADR-0018 2026-11-16 · ADR-0005 2026-11-16 · ADR-0009 2026-11-16 · ADR-0010 2026-11-16 · ADR-0014 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: consumo fixo do fluxo `elites`; comparações com tolerância 1e-9
- Forbidden: RNG da engine
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-IA-15 — onda de 4 em p 4 (0,13): 4 reais; r 0,12 no 1º → elite; seguintes não; r 0,13 exato não; p 1: 4 reais, nenhum
- [x] AC-IA-16 — Eco elite p 0: Vida 72, raio 28,8, dano 11; p 4: Vida 86; chefe nunca elite; p 2 com r 0: nenhum
- [x] AC-IA-17 — posição/Vida do jogador não mudam o estado do fluxo `elites`
- [x] AC-IA-30 — curva: p 3 0,11; p 4 0,13; p 9 0,23; p 10 0,25; p 12 0,25; p 2 0
- [x] AC-IA-11 — golpe pesado em comum em preparo: recuperação 24, golpe não sai, telégrafo `quebrado`; em execução, elite e chefe: nada
- [x] AC-IA-18 — elite não cambaleia e não quebra

---

## Implementation Notes

- Marca visual do elite (coroa, raio × 1,2; AC-IA-26 [V]) é do épico pipeline-visual; aqui só os números e a flag publicada em `publicar()`.

---

## Out of Scope

- AC-IA-26 [V] (captura do elite): épico `production/epics/pipeline-visual/`
- AC-IA-27 [M] (playtest de leitura): registro de playtest fora do gate

---

## Files

- src/gameplay/ia/regras_de_elite.gd
- src/gameplay/ia/modulo_de_ia.gd
- tests/unit/ia/ia_elites_e_quebra_test.gd

Fatia: `game_session.gd` não tem elites; nada a reaproveitar.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ia/ia_elites_e_quebra_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/ia-de-inimigos-e-elites/story-002-fases-surgimento-e-melee.md`; `production/epics/telegrafos/story-006-quebrar-e-cancelar.md`; épicos `production/epics/rng/` (fluxo `elites`), `production/epics/modificadores/` (fontes no portador)
- Unlocks: stories de onda em `production/epics/camaras-e-ondas/`
