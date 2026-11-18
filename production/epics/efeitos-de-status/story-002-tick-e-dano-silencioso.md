# Story 002: Tick no item 7 e dano silencioso

> **Epic**: Efeitos de status
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/efeitos-de-status.md` (R4, F2, F3)
**Requirement**: `TR-status-003`, `TR-status-004`

**ADR Governing Implementation**: ADR-0010: Resolução do combate no passo; ADR-0001: Orquestrador do passo
**ADR Decision Summary**: Item 7, por inimigo vivo em ordem estável: `portador.avancar(1)` → `status.tick(id)` → `telegrafos.avancar` → impacto → `ia.passo`. Dano de status via `ferir_inimigo_de_status` (só R8 itens 1 e 3): sem `acerto`, empurrão, hitstop, Fluxo nem contador. O aplicado no item 8 fere a partir do passo seguinte.
**ADR Version**: ADR-0010 2026-11-16 · ADR-0001 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH (ADR-0010/0001 marcados HIGH pelo ciclo do passo; o código em si é aritmética pura)
**Engine Notes**: nenhuma API pós-cutoff no módulo; o risco vem da ordem do passo do orquestrador (ADR-0001), validada por EX-0001/0002.

**Control Manifest Rules (this layer)**:
- Required: só roda em passo vivo; ordem do item 7 do ADR-0010
- Forbidden: Status pedir hitstop; Status ser chamado em outro ponto do item 7
- Guardrail: zero alocação no `tick`

---

## Acceptance Criteria

- [x] AC-ST-06 — Sangramento e Queimadura coexistem: 0,12/passo (0–179), 0,04 (180–239); Vida 976,0
- [x] AC-ST-08 — aplicado no item 5/6 fere no mesmo passo; no item 8, a partir do passo 1
- [x] AC-ST-12 — dano silencioso: sem `acerto`, empurrão, cambaleio, hitstop, Fluxo nem contador de acertos
- [x] AC-ST-13 — ordem Sangramento → Queimadura; morte pelo primeiro pula o segundo; golpe e status no mesmo passo: status pulado
- [x] AC-ST-24 — Eco Vida 30: A_s 4 morre no 188º passo; A_s 3 não morre em 240 (Vida 5); teto: 75 passos
- [x] AC-ST-25 — DPS por passo nunca passa de 0,4

---

## Implementation Notes

- `tick(inimigo_id)` é o único ponto de entrada no item 7 (ADR-0010 §"Dono do contrato do passo (2)").
- Durante `TransicaoFase` do chefe o dano vira 0 por `invulneravel_por_fase`, mas a duração continua descendo (ADR-0010 B2) — o Status não testa isso, o Combate testa.
- Comparação de Vida com tolerância 1e-6 nos testes.

---

## Out of Scope

- story-003: varredura de mortes, congelamento e limpeza
- story-006: número agregado

---

## Files

- src/gameplay/status/modulo_de_status.gd
- tests/unit/status/status_tick_test.gd

Fatia: nada a reaproveitar.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/status/status_tick_e_morte_test.gd` — must exist and pass

**Status**: [x] Created and passing (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/efeitos-de-status/story-001-modelo-e-aplicar.md`; épico `production/epics/combate-nucleo/` (`ferir_inimigo_de_status`); épico `production/epics/orquestrador-do-passo/` (item 7)
- Unlocks: `production/epics/efeitos-de-status/story-003-morte-congelamento-e-limpeza.md`
