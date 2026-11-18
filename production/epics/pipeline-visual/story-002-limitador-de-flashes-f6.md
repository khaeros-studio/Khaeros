# Story 002: LimitadorDeFlashes (F6) com preempção do chefe

> **Epic**: Pipeline visual
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

O limitador F6 decide, por pedido, se um flash, impact frame ou passe entra, com relógio monotônico em µs injetado. É lógica pura dentro do `EstadoVisual` e é o ponto de contato com o Feedback (pedido negado é descartado, o evento segue).

**GDD**: `design/gdd/pipeline-visual.md` (§ F6. Limitador de flashes)
**Requirement**: `TR-pipeline-007` (limitador F6)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Pipeline visual
**ADR Decision Summary**: `EstadoVisual` (RefCounted) guarda o `LimitadorDeFlashes`; responde `aceito: bool` a `pedir_impacto`, `pedir_flash_telegrafo` e `pedir_passe` com a ordem chefe > recusa > passes > telégrafos no mesmo passo; o passe obrigatório nunca é negado (sai em fade com a janela cheia).
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Sem API de engine; `@abstract` (4.5) não é necessário aqui.

**Control Manifest Rules (this layer)**:
- Required: `PipelineVisual` é o único escritor de globais; o `EstadoVisual` não toca `RenderingServer`
- Forbidden: Never lógica de jogo ler o `EstadoVisual`
- Guardrail: n/a (lógica pura)

---

## Acceptance Criteria

*From GDD `design/gdd/pipeline-visual.md`, scoped to this story:*

- [x] AC-PV-36 [L] F6 — sequência do exemplo (relógio em µs, limitador vazio)
- [x] AC-PV-37 [L] F6 — área do disparo (C120 no mesmo passo vivo)
- [x] AC-PV-38 [L] F6 — ordem no mesmo passo (1 vaga)
- [x] AC-PV-63 [L] F6 — preempção do chefe
- [x] AC-PV-64 [L] F6 — o teto de 3 flashes/s vale para o chefe
- [x] AC-PV-79 [L] F6/R7 — passe de tela obrigatório nunca é negado

---

## Implementation Notes

*Derived from ADR-0011 §1, §7 and Key Interfaces:*

- `func configurar(tuning: VisualTuning, relogio_monotonico_us: Callable)`; `pedir_impacto(modo, impact_passos) -> bool`; `pedir_flash_telegrafo(area_canvas2) -> bool`; `pedir_passe(tipo) -> PasseDeTela`.
- Com `false`, o Feedback tira só o flash chapado (política no Feedback, não aqui).
- Duração do impacto chega em passos de apresentação e é descontada a cada 1/60 s de `t_apres` (story 003 avança).

---

## Out of Scope

- Story 003: modos de tela, `PasseDeTela`, relógios
- `production/epics/feedback-de-combate/story-003-preempcao-e-impulso-de-camera.md`: o que o Feedback faz com o `false`

---

## Files

- `src/presentation/visual/limitador_de_flashes.gd`
- `src/presentation/visual/estado_visual.gd` (criação; story 003 completa)
- `tests/unit/visual/limitador_de_flashes_f6_test.gd`

Código da fatia: nenhum limitador existe — construção nova.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/visual/limitador_de_flashes_f6_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/pipeline/visual_tuning_e_limitador_test.gd`, `production/qa/evidence/pipeline-visual-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/pipeline-visual/story-001-visual-tuning-e-validacao.md`
- Unlocks: `production/epics/pipeline-visual/story-003-modos-de-tela-passes-e-relogios.md`, `production/epics/feedback-de-combate/story-003-preempcao-e-impulso-de-camera.md`
