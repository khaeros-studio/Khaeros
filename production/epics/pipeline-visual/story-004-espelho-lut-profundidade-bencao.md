# Story 004: Espelho em CPU de F1 (LUT), F2 (profundidade) e F5 (Bênção)

> **Epic**: Pipeline visual
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

F1, F2 e F5 vivem em shader, mas o GDD exige um espelho GDScript puro (`VisualMath`) como oráculo. O `fator_profundidade` (F2) é calculado de fato na CPU, em double e em luz linear, e só então escrito como global.

**GDD**: `design/gdd/pipeline-visual.md` (§ F1, § F2, § F5)
**Requirement**: `TR-pipeline-002`, `TR-pipeline-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Pipeline visual
**ADR Decision Summary**: LUT 32³ em fita 1024×32, sem mipmaps/repeat/`source_color`, amostrada à mão com duas leituras e `mix` e meio texel de margem; grading, escurecimento e dessaturação da Bênção em luz linear; F2 em double na CPU.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: O espelho lê `Image` RGBA8 e reproduz o bilinear em R e G e o `mix` em B (saída ±1/255). Um [L] do espelho não prova o shader (story 005 compara).

**Control Manifest Rules (this layer)**:
- Required: grading em linear; texturas de cor com `source_color`, LUT sem
- Forbidden: Never lógica de jogo ler o `EstadoVisual`
- Guardrail: LUT 128 KiB por região

---

## Acceptance Criteria

*From GDD `design/gdd/pipeline-visual.md`, scoped to this story:*

- [x] AC-PV-07 [L] F1 — LUT identidade
- [x] AC-PV-08 [L] F1 — convenção dos eixos (`lut_permutada`)
- [x] AC-PV-09 [L] F1 — amostragem e exemplo c = (0,60; 0,50; 0,40)
- [x] AC-PV-13 [L] F2 — multiplicador por profundidade
- [x] AC-PV-14 [L] F2 — L\* do chão e da parede, em linear
- [x] AC-PV-16 [L] F5 — Bênção (`lut_passagem`, `saturacao_bencao` 0,20)
- [x] AC-PV-71 [L] R2/Edge — números e letreiros somem na Bênção

---

## Implementation Notes

*Derived from ADR-0011 §1, §3, §6:*

- `VisualMath` (nome a confirmar no ADR; usar este) em `src/presentation/visual/`, `RefCounted` estático, sem SceneTree.
- `EstadoVisual.definir_profundidade(p)` usa a F2 do espelho e marca `fator_profundidade` sujo.
- Tolerâncias do GDD: L\* ±0,05; cor ±0,0005; LUT ±1/255.

---

## Out of Scope

- Story 005: shaders `lut.gdshaderinc` e famílias, e a leitura de volta (AC-PV-10, 17)

---

## Files

- `src/presentation/visual/visual_math.gd`
- `src/presentation/visual/estado_visual.gd` (definir_profundidade)
- `tests/unit/visual/espelho_lut_profundidade_bencao_test.gd`

Código da fatia: nenhuma cor de `world_view.gd` (consts `INK`, `BONE`…) entra; cores vêm da região/tuning.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/visual/espelho_lut_profundidade_bencao_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/pipeline/modos_relogios_e_lut_test.gd`, `production/qa/evidence/pipeline-visual-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/pipeline-visual/story-001-visual-tuning-e-validacao.md`
- Unlocks: `production/epics/pipeline-visual/story-005-escritor-de-globais-e-pipeline-visual.md`
