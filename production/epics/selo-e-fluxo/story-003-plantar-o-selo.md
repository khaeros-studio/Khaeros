# Story 003: Plantar o Selo — custo, recarga, buffer e centro preso

> **Epic**: Selo e Fluxo
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/selo-e-fluxo.md` (R2, F1, F6; AC l.795–801, l.824)
**Requirement**: `TR-selo-002`, `TR-selo-003`, `TR-selo-004`, `TR-selo-011`, `TR-selo-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: Resolução do combate no passo; ADR-0006: Input por passo; ADR-0001: Orquestrador do passo; ADR-0003: Entidades e portadores; ADR-0002: Canal de eventos
**ADR Decision Summary**: O Selo planta no item 6, depois do golpe, consumindo só `selo` do buffer; a flag do Input "selo apertado neste passo" gera `selo_sem_fluxo` uma vez por toque; a investida ativa é lida pelo Combate no item 5 e entregue ao Selo; Selos ativos numa lista em ordem de criação, sem SceneTree; eventos `selo` e `selo_sem_fluxo`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: LOW
**Engine Notes**: A amostra do Input (ADR-0006, HIGH) chega injetada; nada de `Input` do Godot aqui.

**Control Manifest Rules (this layer)**:
- Forbidden: depender de ordem de iteração de `Dictionary`; remover por troca com o último
- Required: dependências no `_init`

---

## Acceptance Criteria

- [x] AC-SF-07 [L] R2/F1 — custo e recarga (l.795)
- [x] AC-SF-08 [L] R2 — Fluxo insuficiente (l.796)
- [x] AC-SF-09 [L] R2/F1 — fronteira (l.797)
- [x] AC-SF-10 [L] R2 — esquiva e investida (l.798)
- [x] AC-SF-11 [L] R2 — ordem e buffer (l.799)
- [x] AC-SF-12 [L] R2/F6 — centro preso (l.800)
- [x] AC-SF-13 [L] R2 — obstáculo (l.801)
- [x] AC-SF-27 [L] R2 — buffer (l.824)

---

## Implementation Notes

*Derived from ADR-0010, ADR-0006 and ADR-0003:*

- Item 6: lê o buffer `selo`, a flag de toque e a investida guardada pelo Combate (story `combate-nucleo/story-005`); centro preso ao retângulo jogável (F6).
- Lista de Selos pré-alocada em ordem de criação; marcas por inimigo para `no_selo`.
- **Código da fatia**: nenhum — construção do zero.

---

## Out of Scope

- Story 004: dano dentro do Selo e `selo_fim`
- Story 005: lentidão e apagar na câmara nova

---

## Files

- `src/gameplay/selo/selo.gd` (plantar, lista de Selos)
- `tests/unit/selo/plantar_selo_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/selo/plantar_selo_test.gd` — must exist and pass

**Status**: [x] Created and passing (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/selo-e-fluxo/story-002-fluxo.md`, `production/epics/combate-nucleo/story-005-investida-e-pedidos-do-movimento.md`, `production/epics/input/EPIC.md`
- Unlocks: `production/epics/selo-e-fluxo/story-004-dano-do-selo.md`, `production/epics/selo-e-fluxo/story-005-lentidao-no-selo-e-camara-nova.md`
