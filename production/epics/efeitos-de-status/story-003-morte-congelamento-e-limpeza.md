# Story 003: Morte por status, congelamento e troca de câmara

> **Epic**: Efeitos de status
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/efeitos-de-status.md` (R5, R7)
**Requirement**: `TR-status-005`, `TR-status-007`, `TR-status-008`

**ADR Governing Implementation**: ADR-0010: Resolução do combate no passo; ADR-0001: Orquestrador do passo
**ADR Decision Summary**: Morte por status fechada na varredura do item 9 (hitstop de abate e `ao_abater` vêm da varredura, não do Status). Nada de status roda em passo congelado nem fora de Jogo. `camara_nova()` do Combate chama `status.limpar_todos()` (ação 1 da R1).
**ADR Version**: ADR-0010 2026-11-16 · ADR-0001 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH (estados de jogo próprios do ADR-0001, sem `SceneTree.paused`)
**Engine Notes**: congelamento é do orquestrador (não chamar `tick`), nunca `SceneTree.paused`.

**Control Manifest Rules (this layer)**:
- Required: estado de jogo próprio; limpar antes de a câmara nova existir
- Forbidden: `SceneTree.paused`; `Timer`
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-ST-14 — Eco Vida 0,04 + Sangramento 1: removido na varredura do mesmo passo, hitstop de abate 4 (do passo seguinte), `cura_ao_abater` e `explosao_ao_abater` disparam
- [x] AC-ST-15 — hitstop de 6, pausa, Bênção, Transição e Morte: `restante` e A não mudam
- [x] AC-ST-16 — troca de câmara: nenhum estado de status existe na câmara nova

---

## Implementation Notes

- `limpar_todos()` zera o registro por inimigo sem alocar; o mapa id→estado é esvaziado (ids não reiniciam, ADR-0018).
- Teste de integração com o orquestrador e o Combate reais (ou dublês fiéis) para provar a ordem item 7 → item 9.

---

## Out of Scope

- story-006: número final na descarga (AC-ST-20)

---

## Files

- src/gameplay/status/modulo_de_status.gd
- tests/integration/status/status_morte_e_congelamento_test.gd

Fatia: `game_session.gd` não tem status; a pausa da fatia não é usada (substituída pelo orquestrador).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/unit/status/status_tick_e_morte_test.gd`

**Status**: [x] Created and passing (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/efeitos-de-status/story-002-tick-e-dano-silencioso.md`; épicos `production/epics/combate-nucleo/` (varredura, `camara_nova`) e `production/epics/orquestrador-do-passo/` (estados de jogo)
- Unlocks: None
