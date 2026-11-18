# Story 005: Lentidão, consulta no_selo e Selos apagados na câmara nova

> **Epic**: Selo e Fluxo
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/selo-e-fluxo.md` (R4, R6, F7; AC l.816, l.820)
**Requirement**: `TR-selo-006`, `TR-selo-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Entidades e portadores; ADR-0001: Orquestrador do passo
**ADR Decision Summary**: A consulta `no_selo(inimigo)` (e `fator_lentidao`) vale até o próximo item 6 e é lida pela IA; os Selos são apagados no quadro da metade do wipe pelo aviso de câmara nova, sem emitir `selo_fim`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: HIGH
**Engine Notes**: ADR-0001 (HIGH): o aviso de câmara nova vem do orquestrador no quadro de `progresso_wipe >= 0,5`; ordem `_physics_process`/`_process` NEEDS VERIFICATION no ADR-0001.

**Control Manifest Rules (this layer)**:
- Forbidden (Core): expor `InimigoRef` fora; a consulta recebe o id/ref opaco da IA
- Forbidden: `reset()` em módulo de escopo de run (apagar Selos ≠ reset do módulo)

---

## Acceptance Criteria

- [x] AC-SF-22 [L] R4/F7 — lentidão (l.816)
- [x] AC-SF-23 [L] R6 — apagar (l.820)

---

## Implementation Notes

*Derived from ADR-0003 and ADR-0001:*

- Marcas por inimigo recalculadas no item 6; `no_selo`/`fator_lentidao` leem as marcas (O(1)).
- `ao_camara_nova()` chamado pelo orquestrador na transição: limpa a lista sem evento.
- **Código da fatia**: nenhum — construção do zero.

---

## Out of Scope

- Épico `ia-de-inimigos-e-elites`: aplicar a lentidão no movimento do inimigo

---

## Files

- `src/gameplay/selo/selo.gd` (consultas, apagar)
- `tests/unit/selo/lentidao_e_camara_nova_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/selo/dano_lentidao_e_camara_test.gd` — must exist and pass

**Status**: [x] Created and passing (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/selo-e-fluxo/story-003-plantar-o-selo.md`, `production/epics/combate-nucleo/story-002-passo-vivo-e-hitstop.md` (transição)
- Unlocks: `production/epics/ia-de-inimigos-e-elites/EPIC.md`
