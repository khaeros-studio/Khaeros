# Story 002: Profundidade p, p_max e chave do RNG pelo índice

> **Epic**: Câmaras e ondas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/camaras-e-ondas.md` (R1-P, R3, R3-P)
**Requirement**: `TR-camaras-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição (§4); ADR-0005: RNG determinístico
**ADR Decision Summary**: As Câmaras são donas de `p`/`p_max` e derivam `p` do índice; a chave dos fluxos de estrutura é sempre `(regiao, i)` vinda da Run — o índice, santuário incluído, nunca `p`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Nenhuma API de engine.

**Control Manifest Rules (Feature)**:
- Required: `p_max` é das Câmaras (posse resolvida)
- Forbidden: Autoload

---

## Acceptance Criteria

*From GDD `design/gdd/camaras-e-ondas.md`, scoped to this story:*

- [x] AC-CO-01: no Limiar, combate têm p = 0, 1, 2, 3, 4; santuário não tem p; `p_max` = 4.
- [x] AC-CO-28: os índices 0–6 do Limiar são combate, combate, combate, santuário, combate, combate, chefe; a câmara 6 usa p = 4 e `p_max` continua 4.
- [x] TR-camaras-001: os fluxos `layout`, `ondas`, `spawn` são pedidos com chave `(regiao, i)`; duas câmaras com o mesmo `p` e índices diferentes recebem fluxos diferentes.

---

## Implementation Notes

- A sequência é da Run (`proxima(i)`); as Câmaras só derivam `p` dela.

---

## Out of Scope

- Épico run-e-regioes: `proxima(i)` e `avancar()`

---

## Files

- `src/gameplay/camaras/camaras.gd`
- `tests/unit/camaras/profundidade_e_sequencia_test.gd`

Código atual da fatia: `wave_index` de `game_session.gd` é **substituído** (índice da Run + `p` das Câmaras).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/camaras/profundidade_e_sequencia_test.gd` — must exist and pass
**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/camaras-e-ondas/story-001-tuning-e-validacao-wv.md`; `production/epics/rng/EPIC.md` (fluxos por chave — story a criar)
- Unlocks: `production/epics/camaras-e-ondas/story-006-montagem-na-transicao.md`
