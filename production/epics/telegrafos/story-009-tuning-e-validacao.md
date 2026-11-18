# Story 009: TelegraphTuning e validação TV1–TV6

> **Epic**: Telégrafos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/telegrafos.md` (R10, Faixas e Validação do `TelegraphTuning` e dos `EnemyDef`)
**Requirement**: `TR-telegrafos-010`, `TR-telegrafos-011`

**ADR Governing Implementation**: ADR-0014: Telégrafos: geometria e teto; ADR-0004: Catálogo de dados
**ADR Decision Summary**: Validação TV1–TV6 usa o mesmo `derivar()` do jogo; erro impede a run; tuning no catálogo `.tres` validado.
**ADR Version**: ADR-0014 2026-11-16 · ADR-0004 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM (ADR-0004)

**Control Manifest Rules (this layer)**:
- Required: dimensões do validador de `derivar()`
- Forbidden: literais de tuning no código
- Guardrail: validação só na carga

---

## Acceptance Criteria

- [x] AC-TG-19 — passos(`preparo_s`) < 1, `teto_telegrafos` < 1, ataque sem forma ou dimensão ≤ 0: TV1/TV2, run não começa
- [x] AC-TG-20 — fábrica (Eco 26, Eco do Veio 24, Anomalia 36, Fenda 42) sem TV3–TV6; Eco `preparo_s` 0,3: TV3 e TV4; `teto_telegrafos` 8: TV5
- [x] AC-TG-39 — fábrica com `soberano_do_limiar` sem TV3/TV4/TV5 (folgas 15, 21, 21, 27 ≥ 8; pior caso 4 ≤ 24)

---

## Implementation Notes

- O validador chama `FormasDeTelegrafo.derivar` (story-002), nunca uma cópia.

---

## Out of Scope

- Infra do validador (épico conteudo)

---

## Files

- src/foundation/catalogo/telegraph_tuning.gd
- src/foundation/catalogo/validadores/validador_telegrafos.gd
- tests/integration/telegrafos/telegrafos_tuning_validacao_test.gd

Fatia: `session_catalog.gd` (JSON) — os campos `tele_*` gravados não migram; o tuning nasce no `.tres`.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/telegrafos/telegrafos_tuning_validacao_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/telegrafos/story-002-derivar-formas.md`, `production/epics/telegrafos/story-007-formas-do-chefe.md`; épico `production/epics/conteudo/`
- Unlocks: None
