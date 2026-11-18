# Story 004: Composição das ondas — orçamento, tamanho e elite

> **Epic**: Câmaras e ondas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/camaras-e-ondas.md` (R6, F1, F2)
**Requirement**: `TR-camaras-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: RNG determinístico; ADR-0018: IA de inimigos e chefe
**ADR Decision Summary**: As ondas são compostas na montagem pelo fluxo 1 `ondas`, com quantidade e ordem de sorteios fixas; a decisão de elite é da IA (`sortear_elite(p, ja_ha_elite)`, fluxo 2), chamada por inimigo na ordem da onda; teto de 9 inimigos simultâneos.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Nenhuma API de engine.

**Control Manifest Rules (Feature)**:
- Required: listas de opções na ordem do manifesto
- Forbidden: RNG da engine

---

## Acceptance Criteria

*From GDD `design/gdd/camaras-e-ondas.md`, scoped to this story:*

- [x] AC-CO-07: p 0 a 4 no Limiar → orçamento 3; 3,9; 4,8; 5,7; 6,6 com 1, 1, 2, 2, 2 ondas; região 1, p 0 → 5,0.
- [x] AC-CO-08: p 0, sorteio [Fenda, Eco] → onda de 2, custo 3; [Eco, Eco, Eco] → 3 inimigos; nenhuma onda passa do orçamento; orçamento 20 → para em 9.
- [x] AC-CO-10 (parte elite): a IA recebe `sortear_elite(p, ja_ha_elite)` por inimigo, na ordem da onda, com `ja_ha_elite` falso até o 1º elite e verdadeiro depois.
- [x] AC-CO-11 (parte `ondas`): posição e Vida do jogador não mudam o estado do fluxo `ondas`.

---

## Implementation Notes

- Comparações de orçamento com floats (3,9 etc.): usar a regra do GDD (F1) sem `round()`; tolerância do teste 1e-9 (Fixture CO).

---

## Out of Scope

- Story 005: onde cada inimigo nasce
- Story 009: onda do chefe

---

## Files

- `src/gameplay/camaras/composicao_de_ondas.gd`
- `tests/unit/camaras/composicao_das_ondas_test.gd`

Código atual da fatia: as três ondas fixas (`data/integration/gameplay.json`, `game_session.gd::_spawn_wave`) são **substituídas**.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/camaras/composicao_das_ondas_test.gd` — must exist and pass
**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/camaras-e-ondas/story-001-tuning-e-validacao-wv.md`; `production/epics/ia-de-inimigos-e-elites/EPIC.md` (`sortear_elite` — story a criar; dublê até lá)
- Unlocks: `production/epics/camaras-e-ondas/story-005-spawn-e-candidatos.md`, `production/epics/camaras-e-ondas/story-006-montagem-na-transicao.md`
