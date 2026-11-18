# Story 003: Fórmulas de referência das armas (F1–F7)

> **Epic**: Armas das Doutrinas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/armas-das-doutrinas.md` (Formulas F1–F7 l.346–773; AC l.1402–1519, l.1779–1797)
**Requirement**: `TR-armas-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Catálogo de dados; ADR-0009: Atributos e modificadores; ADR-0010: Resolução do combate no passo
**ADR Decision Summary**: Os valores vêm do `ArmasTuning` e dos `WeaponDef` validados; as contas de referência (DPS, TTK, golpes até matar, empurrão, fração do Especial, DPS composto da Besta) usam as fórmulas do Combate e o arredondamento próprio do ADR-0009.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: LOW
**Engine Notes**: Aritmética pura; nenhuma API pós-corte. Contas do validador em double.

**Control Manifest Rules (this layer)**:
- Required (Core, reaproveitado): tudo em `float` até o fim; arredondar só por `arredondar_meio_longe_do_zero`
- Forbidden: `round()`/`roundi()`

---

## Acceptance Criteria

- [x] AC-AR-16 [L] F1 — DPS de referência, M = 1, um alvo (l.1402)
- [x] AC-AR-17 [L] F2/R6 — TTK do chefe e paridade (l.1415)
- [x] AC-AR-18 [L] F3 — golpes até matar (l.1426)
- [x] AC-AR-19 [L] F4 — golpes recebidos até morrer (l.1451)
- [x] AC-AR-20 [L] F5 — empurrão do Pulso, Combate real (l.1463)
- [x] AC-AR-22 [L] F6 — fração do Especial (l.1503)
- [x] AC-AR-40 [L] F1 — teto de M = 4,0 (provisório) (l.1507)
- [x] AC-AR-47 [L] F7 — DPS composto e paridade, M = 1 (l.1779)
- [x] AC-AR-48 [L] F3/F4/F5b — contas da Besta (l.1793)

---

## Implementation Notes

*Derived from ADR-0009 and ADR-0010:*

- Funções puras `static` sobre `WeaponDef` + `CombatTuning`, reusando `formulas_de_combate.gd` (story `combate-nucleo/story-006`), nunca reimplementando F1/F3 do Combate.
- **Código da fatia**: nenhum — construção do zero.

---

## Out of Scope

- Story 008: DPS **medido** em run (AC-AR-35)

---

## Files

- `src/gameplay/armas/formulas_de_armas.gd`
- `tests/unit/weapons/formulas_de_armas_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/armas/formulas_de_armas_test.gd` — must exist and pass

**Status**: [x] Created and passing (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/armas-das-doutrinas/story-001-weapondef-e-armas-de-fabrica.md`, `production/epics/combate-nucleo/story-006-dano-no-inimigo-e-empurrao.md`
- Unlocks: `production/epics/armas-das-doutrinas/story-002-validacao-das-armas.md`
