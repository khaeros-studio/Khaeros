# Story 001: SealTuning e validação SV1–SV12

> **Epic**: Selo e Fluxo
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/selo-e-fluxo.md` (Faixas do `SealTuning` l.559; Validação l.578; F3–F5; AC l.821, l.832)
**Requirement**: `TR-selo-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Catálogo de dados
**ADR Decision Summary**: Os valores do Selo vêm do `SealTuning` .tres no catálogo com manifesto explícito, validado na carga (SV1–SV12) e copiado por `duplicate_deep`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: MEDIUM
**Engine Notes**: ADR-0004: `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` (4.5), constante fora de `docs/engine-reference/` — confirmada só no experimento de 2026-11-14.

**Control Manifest Rules (this layer)**:
- Required: toda criação passa por `ComposicaoDaSessao`/`FabricaDaRun`, dependências no `_init`
- Forbidden: valor de jogo escondido no código

---

## Acceptance Criteria

- [x] AC-SF-24 [I] R7/Formulas — dado e validação (l.821)
- [x] AC-SF-32 [I] F3–F5 — números da Besta (l.832)

---

## Implementation Notes

*Derived from ADR-0004:*

- `SealTuning` com `class_name`, no manifesto; validador SV1–SV12 na carga; erros bloqueiam, avisos ao relatório. Conversões s→passos na carga.
- **Código da fatia**: nenhum código do Selo na fatia — construção do zero.

---

## Out of Scope

- Stories 002–005: o comportamento que usa os valores

---

## Files

- `src/content/defs/seal_tuning.gd`, `src/content/validacao/validador_seal_tuning.gd`
- `assets/data/seal_tuning.tres`
- `tests/integration/selo/seal_tuning_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/unit/selo/seal_tuning_test.gd` — must exist and pass

**Status**: [x] Created and passing (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/conteudo/EPIC.md`, `production/epics/armas-das-doutrinas/story-001-weapondef-e-armas-de-fabrica.md` (números da Besta, AC-SF-32)
- Unlocks: `production/epics/selo-e-fluxo/story-002-fluxo.md`
