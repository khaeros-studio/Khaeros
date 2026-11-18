# Story 006: Espelho do SDF do telégrafo (F3, F4) e do tracejado (F7)

> **Epic**: Pipeline visual
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

Matemática pura do telégrafo: SDF de cada forma, raio interno e zonas, composição de anel e cor, crescimento em p, malha de borda gerada na CPU, escala do traço (F3) e tracejado periódico (F7). É a base dos `comum/sdf.gdshaderinc` e `comum/tracejado.gdshaderinc` e da malha `ArrayMesh` dos 24 slots.

**GDD**: `design/gdd/pipeline-visual.md` (§ F3, § F4, § F7)
**Requirement**: `TR-pipeline-005` (parte lógica), `TR-pipeline-014` (malha do secundário reaproveita a mesma geração)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Pipeline visual; ADR-0014: Telégrafos: geometria e teto
**ADR Decision Summary**: Telégrafo em unidades de canvas, quad de preenchimento (z −5) e `ArrayMesh` de borda (z 5) por slot; o contorno secundário do R5a usa a mesma malha de borda (só vértices a mais).
**ADR Version**: ADR-0011 2026-11-16; ADR-0014 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Lógica pura; a largura medida do contorno depende do EX-0011-E4 (story 007).

**Control Manifest Rules (this layer)**:
- Required: 24 slots de telégrafo (48 nós) pré-instanciados na carga
- Forbidden: Never `draw_line`/`draw_arc`/`Line2D` sem textura para traço de jogo
- Guardrail: sombras + telégrafos 54 draw calls

---

## Acceptance Criteria

*From GDD `design/gdd/pipeline-visual.md`, scoped to this story:*

- [x] AC-PV-18 [L] F3 — tabela de s_tela
- [x] AC-PV-20 [L] F4 — SDF de cada forma
- [x] AC-PV-21 [L] F4 — raio interno e zonas
- [x] AC-PV-60 [L] F4 — anel e composição da cor
- [x] AC-PV-61 [L] F4/F10 — malha de borda do contorno
- [x] AC-PV-22 [L] F4 — crescimento em p = 0, 0,5 e 1
- [x] AC-PV-23 [L] F4 — completa exatamente em p = 1
- [x] AC-PV-82 [L] F4 — p ≥ 1 sem linha nem fresta
- [x] AC-PV-28 [L] F7 — tracejado (P = 14, r_t = 8/14)
- [x] AC-PV-62 [L] F7 — δ periódico e derivada analítica

---

## Implementation Notes

*Derived from ADR-0011 §4, §5 and ADR-0014:*

- Espelho em `VisualMath` (story 004) ou arquivo irmão `visual_math_sdf.gd`; gerador de malha de borda puro, saída em arrays reutilizáveis (sem alocar por passo).
- Fixtures C120, C100, A60, R400, S200 da FPV; aa = 1/(s_tela × z).

---

## Out of Scope

- Story 007: pool de nós, estados no tempo, captura

---

## Files

- `src/presentation/visual/visual_math_sdf.gd`
- `src/presentation/visual/malha_de_borda.gd`
- `assets/shaders/comum/sdf.gdshaderinc`, `assets/shaders/comum/tracejado.gdshaderinc`
- `tests/unit/visual/espelho_sdf_e_tracejado_test.gd`

Código da fatia: `world_view.gd::_telegraph`/`_sector` desenham com `draw_*` — **substituir**; nada reaproveitado.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/visual/espelho_sdf_e_tracejado_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/pipeline/sdf_telegrafos_camadas_e_orcamento_test.gd`, `production/qa/evidence/pipeline-visual-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/pipeline-visual/story-001-visual-tuning-e-validacao.md`
- Unlocks: `production/epics/pipeline-visual/story-007-pool-de-telegrafos-24-slots.md`
