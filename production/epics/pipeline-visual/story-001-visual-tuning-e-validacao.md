# Story 001: VisualTuning no catálogo, injeção e validação VV

> **Epic**: Pipeline visual
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

O Pipeline não guarda valor escondido: todo número sai do `VisualTuning` validado do catálogo, e estado, relógio e opções chegam por injeção (R12/R13). Esta story cria o tipo, as faixas seguras e o validador VV, que todas as outras stories do épico consomem.

**GDD**: `design/gdd/pipeline-visual.md` (§ Faixas seguras do `VisualTuning`, § Validação do `VisualTuning`, AC grupo A)
**Requirement**: `TR-pipeline-013`; parte lógica de `TR-pipeline-008` e `TR-pipeline-009` (somas VV12/VV13)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Catálogo de dados; ADR-0011: Pipeline visual
**ADR Decision Summary**: Definições `.tres` em `src/content/` com manifesto explícito e validadores; o `VisualTuning` é um ajuste do catálogo, lido por `configurar()` do `EstadoVisual`/`PipelineVisual`, sem constante no código.
**ADR Version**: ADR-0004 2026-11-16; ADR-0011 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Lógica pura (`RefCounted`/`Resource`), sem API pós-corte. VV13 dispara de propósito com a FPV (tetos de memória somam 504 MiB > 448).

**Control Manifest Rules (this layer)**:
- Required: A Apresentação só lê e nunca escreve no jogo
- Forbidden: Never lógica de jogo ler o `EstadoVisual`
- Guardrail: Draw calls 500 por grupo (ambiente 40, sombras+telégrafos 54, entidades 200, VFX 64, passes 6, UI 80, reserva ≥ 56)

---

## Acceptance Criteria

*From GDD `design/gdd/pipeline-visual.md`, scoped to this story (texto completo e oráculos no GDD, pelo número):*

- [x] AC-PV-01 [L] R12/R13 — sem valor escondido
- [x] AC-PV-02 [L] R13 — determinismo (duas instâncias com a FPV e o mesmo roteiro dão a mesma saída)
- [x] AC-PV-03 [L] Faixas/VV — validação do `VisualTuning` (conjunto exato de erros e avisos por linha)
- [x] AC-PV-04 [L] VV8–VV10 — telégrafo degenerado
- [x] AC-PV-59 [L] Validação — precedência
- [x] AC-PV-11 [L] VV4 — perfil da LUT
- [x] AC-PV-15 [L] VV3 — piso do chão por LUT (Run e regiões dublê)
- [x] AC-PV-66 [L] VV5/F3 — `contorno_silhueta_px`
- [x] AC-PV-47 [L] F10/VV12/VV13 — somas dos grupos do orçamento e da memória

---

## Implementation Notes

*Derived from ADR-0004 and ADR-0011:*

- `VisualTuning extends Resource` em `src/content/`, entrando no manifesto do catálogo; validação VV roda na carga e devolve conjunto de erros/avisos (não lança).
- Fixture padrão (FPV) e fábricas de LUT (`lut_identidade`, `lut_permutada`, `lut_permutada_invertida`, `lut_constante`, `lut_degrau`, `lut_passagem`) em `tests/unit/visual/fixtures/`, por função de fábrica, como o GDD pede.
- Nada de seed nem tempo real: relógio, `dt_real` e estado do orquestrador são dublês injetados.
- Decisão registrada (agente, brief sem perguntas): a pasta de testes do épico é `tests/unit/visual/` e `tests/integration/visual/` (caminhos que os AC do GDD citam), não `tests/unit/pipeline_visual/` do Migration Plan do ADR-0011.

---

## Out of Scope

- Story 002/003: uso dos valores pelo limitador F6, modos e relógios
- Story 004: fórmulas F1/F2/F5 que leem o tuning

---

## Files

- `src/content/visual_tuning.gd`
- `src/content/validacao/validador_visual_tuning.gd`
- `tests/unit/visual/fixtures/fpv.gd`
- `tests/unit/visual/fixtures/luts.gd`
- `tests/unit/visual/visual_tuning_e_validacao_test.gd`

Código da fatia: `src/foundation/session_catalog.gd` não tem tuning visual — **substituir** pelo catálogo do ADR-0004 (épico conteudo); nada a reaproveitar aqui.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/visual/visual_tuning_e_validacao_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/pipeline/visual_tuning_e_limitador_test.gd`, `production/qa/evidence/pipeline-visual-evidence.md`)

---

## Dependencies

- Depends on: épico `production/epics/conteudo/EPIC.md` (story do catálogo/manifesto do ADR-0004)
- Unlocks: `production/epics/pipeline-visual/story-002-limitador-de-flashes-f6.md`, `story-003-modos-de-tela-passes-e-relogios.md`, `story-004-espelho-lut-profundidade-bencao.md`, `story-006-espelho-sdf-e-tracejado.md`
