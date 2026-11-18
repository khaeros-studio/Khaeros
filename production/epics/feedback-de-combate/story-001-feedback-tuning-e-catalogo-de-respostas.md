# Story 001: FeedbackTuning e catálogo evento → resposta com validação FB1–FB3

> **Epic**: Feedback de combate
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

Dados do Feedback: o `FeedbackTuning` validado (janelas, tetos, limiares de degradação) e o catálogo que dá, para cada evento da R3, R10 e R15, a resposta, a prioridade P0–P4, o preset de câmera e o gancho de áudio. Sem esse catálogo o árbitro não tem o que decidir.

**GDD**: `design/gdd/feedback-de-combate.md` (R3, R10, R15, Tuning Knobs, Edge Cases)
**Requirement**: `TR-feedback-014`, `TR-feedback-003` (catálogo), `TR-feedback-015` (catálogo das 13 linhas das Maldições)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Catálogo de dados; ADR-0002: Canal de eventos
**ADR Decision Summary**: Tuning e tabelas como definições `.tres` do catálogo (manifesto explícito, validadores, cópia por `duplicate_deep`); as linhas são indexadas pelo tipo de `EventoDoPasso` da lista do passo.
**ADR Version**: ADR-0004 2026-11-16; ADR-0002 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Só `Resource`; sem API pós-corte.

**Control Manifest Rules (this layer)**:
- Required: todo stream vem de `SomDef` do catálogo (o gancho é só `StringName` aqui)
- Forbidden: never caminho literal de som
- Guardrail: n/a

---

## Acceptance Criteria

*From GDD `design/gdd/feedback-de-combate.md`, scoped to this story:*

- [x] AC-FB-02 [L] R3 — catálogo completo (cada evento da R3 e R10 com linha, prioridade, preset e gancho ou "—")
- [x] AC-FB-22 [L] R10 — lacunas (resposta mínima, sem flash, impact frame ou câmera; `jogador_morreu` sem impact frame)
- [x] AC-FB-23 [L] R10 — surgimento sem contorno tracejado
- [x] AC-FB-25 [L] Edge — validação (`FB1` evento sem linha; `FB2` gancho sem som; `FB3` limiares de retorno)
- [x] AC-FB-32 [L] R15 — catálogo das Maldições (nada de telégrafo de chão, magenta ou dourado; `maldicao_golpe` é P3)

---

## Implementation Notes

*Derived from ADR-0004 and ADR-0002:*

- `FeedbackTuning` e `CatalogoDeRespostas` em `src/content/`, validados na carga; aviso `FB2` uma vez por gancho por run (o lado do áudio está em `production/epics/audio/story-001-somdef-audiotuning-e-pedidos.md`).
- Decisão registrada: o catálogo de respostas é um `Resource` único com linhas tipadas (uma por evento), não um `.tres` por evento.

---

## Out of Scope

- Story 002: o árbitro que usa o catálogo

---

## Files

- `src/content/feedback_tuning.gd`
- `src/content/catalogo_de_respostas.gd`
- `src/content/validacao/validador_feedback.gd`
- `tests/unit/feedback/feedback_tuning_e_catalogo_test.gd`

Código da fatia: `src/foundation/session_catalog.gd` guarda tuning em `Dictionary` — **substituir** pelo catálogo; nada reaproveitado.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/feedback/feedback_tuning_e_catalogo_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/feedback/feedback_tuning_e_catalogo_test.gd`, `production/qa/evidence/feedback-combate-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/conteudo/EPIC.md` (catálogo ADR-0004); `production/epics/orquestrador-do-passo/EPIC.md` (tipos de `EventoDoPasso`, ADR-0002)
- Unlocks: `production/epics/feedback-de-combate/story-002-arbitro-puro.md`
