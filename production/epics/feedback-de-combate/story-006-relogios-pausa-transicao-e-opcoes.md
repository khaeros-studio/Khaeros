# Story 006: Relógios vivo/apresentação, pausa, Bênção, Transição e opções de acessibilidade

> **Epic**: Feedback de combate
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

As respostas vivas congelam no hitstop e as de apresentação correm; pausa e Bênção param os dois relógios; a Transição descarta a fila e as respostas vivas; as opções de acessibilidade (tremor, Reduzir flashes, Redução de movimento, números reduzido/desligado) são pedidas aos donos, nunca contornadas.

**GDD**: `design/gdd/feedback-de-combate.md` (R2, R6, R7, R13, Edge Cases, F5)
**Requirement**: `TR-feedback-006`, `TR-feedback-012`, `TR-feedback-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Orquestrador do passo; ADR-0002: Canal de eventos; ADR-0011: Pipeline visual; ADR-0007: Cena, viewport e câmera; ADR-0013: Persistência do MVP
**ADR Decision Summary**: Estado próprio sem `SceneTree.paused`; `t_vivo`/`t_apres` do orquestrador; relógios zerados na última das seis ações do wipe; opções lidas do `opcoes.cfg [acessibilidade]` pelos donos (câmera, Pipeline) — o Feedback só pede.
**ADR Version**: ADR-0001 2026-11-16; ADR-0002 2026-11-16; ADR-0011 2026-11-16; ADR-0007 2026-11-14; ADR-0013 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Players de VFX parados explicitamente (EX-0011-E3); nada de `SceneTree.paused`/`Engine.time_scale`.

**Control Manifest Rules (this layer)**:
- Required: apresentação guiada por `t_vivo`/`t_apres` ou com players parados explicitamente em hitstop e pausa
- Forbidden: never o Feedback aplicar opção diretamente
- Guardrail: n/a

---

## Acceptance Criteria

*From GDD `design/gdd/feedback-de-combate.md`, scoped to this story:*

- [x] AC-FB-03 [L] R2 — relógios (hitstop de 6 passos: flash e `disparo` congelam, estrela continua)
- [x] AC-FB-10 [L] F5/R6 — números "reduzido"
- [x] AC-FB-11 [L] R6 — números "desligado"
- [x] AC-FB-19 [L] R7 — opções (tremor 0%, Reduzir flashes, Redução de movimento)
- [x] AC-FB-24 [L] R13 — Transição (fila e respostas vivas descartadas; Nova run zera agregação e nível)
- [x] AC-FB-26 [L] Edge — pausa e Bênção

---

## Implementation Notes

*Derived from ADR-0001, ADR-0011 §2 and ADR-0013:*

- Cada resposta carrega o relógio que a governa (`vivo` ou `apres`); o avanço lê os valores do orquestrador.
- Na Bênção, números e letreiros somem e não voltam (Pipeline AC-PV-71).

---

## Out of Scope

- `production/epics/pipeline-visual/story-003-modos-de-tela-passes-e-relogios.md`: os relógios em si

---

## Files

- `src/presentation/feedback/respostas_vivas.gd`
- `src/presentation/feedback/arbitro_de_feedback.gd` (opções e Transição)
- `tests/unit/feedback/relogios_pausa_transicao_e_opcoes_test.gd`

Código da fatia: o hitstop de `game_session.gd`/`main.gd` é **referência de sensação** apenas; o congelamento passa a vir do orquestrador.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/feedback/relogios_pausa_transicao_e_opcoes_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/feedback/degradacao_relogios_e_maldicoes_test.gd`, `production/qa/evidence/feedback-combate-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/feedback-de-combate/story-004-pool-de-numeros-de-dano.md`, `production/epics/pipeline-visual/story-003-modos-de-tela-passes-e-relogios.md`; `production/epics/persistencia/EPIC.md` (`opcoes.cfg [acessibilidade]`)
- Unlocks: `production/epics/feedback-de-combate/story-008-vistas-e-pool-de-vfx.md`
