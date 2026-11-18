# Story 007: Respostas das Maldições e ganchos sfx_maldicao_*

> **Epic**: Feedback de combate
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

Emenda Pactos: golpe de Maldição sem hitstop nem câmera, flash da Maldição atingida limitado, marca única do Virote e os ganchos `sfx_maldicao_*` com um som por gancho por passo.

**GDD**: `design/gdd/feedback-de-combate.md` (§ Maldições, R15–R18, R9)
**Requirement**: `TR-feedback-015`, `TR-feedback-016`; emissão de `TR-feedback-008` (um som por gancho por passo, lado Feedback)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Canal de eventos; ADR-0011: Pipeline visual; ADR-0016: Áudio: ganchos e vozes
**ADR Decision Summary**: Ganchos `sfx_maldicao_*` saem como `PedidoDeSom` do Feedback, com as prioridades da R15, sem regra especial no Áudio; fio e Virote em `traco_sdf`, nenhum telégrafo SDF para golpe de Maldição.
**ADR Version**: ADR-0002 2026-11-16; ADR-0011 2026-11-16; ADR-0016 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Lógica pura.

**Control Manifest Rules (this layer)**:
- Required: sons só por `PedidoDeSom`
- Forbidden: never vistas chamarem `play()`
- Guardrail: n/a

---

## Acceptance Criteria

*From GDD `design/gdd/feedback-de-combate.md`, scoped to this story:*

- [x] AC-FB-33 [L] R15 — impacto sem hitstop
- [x] AC-FB-38 [L] R18 — flash limitado (passos 0, 5, 20; ≤ 3/s)
- [x] AC-FB-39 [L] R15 — marca única do Virote
- [x] AC-FB-40 [L] R15/R9 — ganchos (`maldicao_exausta` uma vez; um `sfx_maldicao_ataque`; `sfx_maldicao_recusa` P4 sem VFX)
- [x] AC-FB-21 [L] R9/F4 — primeira cláusula, lado Feedback: uma área com 5 alvos gera **um** `sfx_acerto_leve` no passo (as demais cláusulas em `production/epics/audio/story-002-mixador-de-vozes.md`)

---

## Implementation Notes

*Derived from ADR-0016 §1, §7 and ADR-0011 Pactos amendment:*

- Dedupe por gancho no passo no árbitro; o Mixador repete como salvaguarda.

---

## Out of Scope

- `production/epics/pipeline-visual/story-009-traco-do-jogador-e-vfx-das-maldicoes.md`: desenho do fio e do ilhós

---

## Files

- `src/presentation/feedback/arbitro_de_feedback.gd` (linhas R15–R18)
- `tests/unit/feedback/respostas_das_maldicoes_test.gd`

Código da fatia: nenhum (Maldições não existem na fatia).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/feedback/respostas_das_maldicoes_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/feedback/degradacao_relogios_e_maldicoes_test.gd`, `production/qa/evidence/feedback-combate-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/feedback-de-combate/story-003-preempcao-e-impulso-de-camera.md`, `production/epics/feedback-de-combate/story-004-pool-de-numeros-de-dano.md`, `production/epics/audio/story-001-somdef-audiotuning-e-pedidos.md` (tipo `PedidoDeSom`); `production/epics/maldicoes/EPIC.md` (eventos R15)
- Unlocks: `production/epics/feedback-de-combate/story-008-vistas-e-pool-de-vfx.md`
