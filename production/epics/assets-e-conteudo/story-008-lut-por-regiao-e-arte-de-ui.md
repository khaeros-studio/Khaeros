# Story 008: LUT por região, VFX base e arte de UI (cartas, placas, ícones, glifos, fonte)

> **Epic**: Assets e conteúdo
> **Status**: Complete
> **Layer**: Foundation (arte acompanha a Apresentação)
> **Type**: Visual/Feel
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/pipeline-visual.md` (LUT por região, VFX); `design/gdd/tela-de-bencao-e-carta.md` R4 (anatomia da carta); `design/gdd/hud.md` (osso e tinta, Visual/Audio Requirements); `design/art/art-bible.md` §7.5, §7.8
**Requirement**: N/A — sem TR próprio; consumido por TR-hud-011, TR-tela-bencao-002/008 e pelos TRs de `pipeline-visual`/`feedback-de-combate`.
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Pipeline visual
**ADR Decision Summary**: LUT 32³ em fita 1024×32, perfil P4 (lossless, sem mipmaps, sem repetição, sem `source_color`), trocada só na última ação da Transição. Camada de UI com material `ui`/`sem_grading`; orçamento de draw calls de UI 80.
**ADR Version**: ADR-0011 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: escrita do global `lut_regiao` (E2 do ADR-0011, NOT SOURCEABLE) — a captura depende de EX-0011.

**Control Manifest Rules (Presentation)**:
- Required: `PipelineVisual` é o único escritor de globais
- Forbidden: `TIME` em shader de mundo
- Guardrail: UI ≤ 80 draw calls; VFX ≤ 64

---

## Acceptance Criteria

*From the epic scope (entrega 2), ADR-0011 §6 and GDD Tela R4:*

- [x] LUT do Limiar em `assets/art/` no formato 1024×32 P4 (import sem mipmaps/repetição, sem `source_color`), com captura antes/depois.
- [x] Arte de carta: moldura 320 × 500 com as 6 zonas da Art Bible §7.5, coroas das Doutrinas do MVP, ornamentos Comum/Rara/Épica, selo de preço, glifos e ícones de ganho das bênçãos do MVP.
- [x] Arte do HUD: placas de tinta, segmentos de osso, gota de Fluxo, chevrons, ícone de Fragmentos, glifos de teclado/gamepad.
- [x] Fonte(s) da UI importadas conforme o Pipeline (e fonte de leitura alternativa, opção 12).
- [x] Capturas + sign-off do art-director em `production/qa/evidence/arte-ui-lut-evidence.md`.

---

## Implementation Notes

*Derived from ADR-0011 §6:*

- Amostragem manual com meio texel de margem; não depender do filtro do sampler global.

---

## Out of Scope

- Épico `pipeline-visual`: shaders e passes
- Story 007: arte específica de Maldições

---

## Files

- `assets/art/lut/limiar.png` (+ `.import`)
- `assets/art/ui/{cartas,hud,glifos,fontes}/*`
- `production/qa/evidence/arte-ui-lut-evidence.md` + capturas

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: screenshots retidos + sign-off em `production/qa/evidence/arte-ui-lut-evidence.md`
**Status**: [x] Created and signed off (`production/qa/evidence/arte-ui-lut-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/experimentos-de-engine/` (EX-0011 E1–E3 para validar a LUT); `production/epics/pipeline-visual/` (formato de material da UI)
- Unlocks: `production/epics/hud/story-006-vista-do-hud-control-ancoras-e-escala.md`; `production/epics/tela-de-bencao-e-carta/story-005-carta-view-e-vista-da-tela.md`
