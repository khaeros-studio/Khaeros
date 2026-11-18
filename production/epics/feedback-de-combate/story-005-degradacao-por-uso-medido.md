# Story 005: Degradação de VFX por uso medido, com histerese, e P0/P1 protegidos

> **Epic**: Feedback de combate
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

Quando o uso do orçamento de VFX sobe, o Feedback corta por prioridade (P4 → P3 → P2, o mais antigo primeiro) em níveis com histerese, sem jamais cortar flash de acerto, telégrafo, telégrafo partido, inversão e P1.

**GDD**: `design/gdd/feedback-de-combate.md` (R4, R8, F3)
**Requirement**: `TR-feedback-004`, `TR-feedback-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Pipeline visual
**ADR Decision Summary**: O Pipeline fornece os tetos por grupo (R9) e uma contagem de draw calls por proxy (instâncias visíveis por grupo) que alimenta a degradação; a política de corte fica no Feedback.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Lógica pura; se o EX-0011-E1 mostrar o monitor infiel, o proxy é estimativa conservadora.

**Control Manifest Rules (this layer)**:
- Required: a Apresentação só lê
- Forbidden: n/a
- Guardrail: VFX 64 draw calls

---

## Acceptance Criteria

*From GDD `design/gdd/feedback-de-combate.md`, scoped to this story:*

- [x] AC-FB-12 [L] R4 — corte por orçamento
- [x] AC-FB-13 [L] F3/R8 — níveis
- [x] AC-FB-14 [L] F3 — histerese (0,76–0,89 por 10 s não muda o nível)
- [x] AC-FB-28 [L] R4 — P0/P1 sob degradação

---

## Implementation Notes

*Derived from ADR-0011 §7:*

- `uso` = proxy do grupo VFX / teto do grupo, entregue por interface injetada (dublê no teste).
- Limiares do `FeedbackTuning` (validação FB3 na story 001).

---

## Out of Scope

- `production/epics/pipeline-visual/story-010-impact-frames-orcamento-e-leitura.md`: o proxy real e a captura

---

## Files

- `src/presentation/feedback/degradacao_de_vfx.gd`
- `tests/unit/feedback/degradacao_por_uso_medido_test.gd`

Código da fatia: nenhum.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/feedback/degradacao_por_uso_medido_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/feedback/degradacao_relogios_e_maldicoes_test.gd`, `production/qa/evidence/feedback-combate-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/feedback-de-combate/story-002-arbitro-puro.md`
- Unlocks: `production/epics/feedback-de-combate/story-008-vistas-e-pool-de-vfx.md`
