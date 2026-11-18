# Story 007: Experimentos do pipeline B: SDF, CanvasGroup, fio e material (EX-0011-E4..E7)

> **Epic**: experimentos-de-engine
> **Status**: Done
> **Layer**: Foundation
> **Type**: Visual/Feel
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-17

## Context

**GDD**: `docs/architecture/architecture.md`
**Requirement**: nenhum TR próprio. Desbloqueia TR-pipeline-* (telégrafos, contornos, fio do Vínculo, material por entidade).

**ADR Governing Implementation**: ADR-0011: Pipeline visual
**ADR Decision Summary**: SDF para telégrafos com malha de borda, `CanvasGroup` para contornos, material por entidade (ou compartilhado), fio do vínculo por `Line2D` ou quad SDF.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: NOT SOURCEABLE: `CanvasGroup.fit_margin` (unidade), `instance uniform` em `canvas_item`; `TEXTURE_PIXEL_SIZE` em `CanvasGroup`.

**Control Manifest Rules (this layer)**:
- Required: Apresentação só lê estado de jogo; ordem de desenho por `(pé_interpolado.y, ordem_criacao_visual)` (ADR-0007).
- Forbidden: afirmar unidade ou nome de propriedade de memória.
- Guardrail: teto 500 draw calls 2D; sem lote exceto sombras.

---

## Acceptance Criteria

*Do ADR-0011 "Validation Criteria" E4–E7.*

- [x] E4: contorno de telégrafo de 4 px legível em 1080p, 1440p e 4K (capturas lado a lado); malha de borda × quad cheio; custo de GPU (ms) com 24 telégrafos, registrado.
- [x] E5: `CanvasGroup`: contorno por fora, inversão, unidade do `fit_margin`, `TEXTURE_PIXEL_SIZE` e custo; snapshot × rig duplicado para imagens residuais (captura).
- [x] E6: fio de vínculo: `Line2D` com textura × quad SDF de segmento: suavização (captura ampliada) e custo, com decisão registrada.
- [x] E7: 9, 20 e 40 entidades com material próprio × compartilhado: tempo de CPU por quadro; `instance uniform` em `canvas_item` funciona ou não.
- [x] Capturas retidas e decisão (A ou B) de cada experimento anotada para o ADR-0011.

---

## Implementation Notes

Estender `prototypes/pipeline-verificacao/` (story 006) com cenas por experimento. Resoluções por `Window.size` e `content_scale`; 4K em tela real ou captura offscreen documentada. Comparar sempre contra o plano B do ADR.

---

## Out of Scope

- E1–E3: `story-006-pipeline-globais-relogios-draw-calls.md`.
- Implementação de produção dos telégrafos: épicos `telegrafos` e `pipeline-visual`.

---

## Files

- `prototypes/pipeline-verificacao/` (cenas E4–E7)
- `production/qa/evidence/experimentos/ex-0011-e4-e7.md` (+ capturas `.png`)

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: capturas retidas + `production/qa/evidence/experimentos/ex-0011-e4-e7-evidence.md` com sign-off do lead.

**Status**: [x] Created (2026-11-17) — `production/qa/evidence/experimentos/ex-0011-e4-e7.md`

---

## Dependencies

- Depends on: `production/epics/experimentos-de-engine/story-006-pipeline-globais-relogios-draw-calls.md`
- Unlocks: épicos `pipeline-visual`, `telegrafos`, `vinculo-e-pactos` (fio)

---

## Completion Notes

**Data**: 2026-11-17 · Godot 4.7.2 · protótipo `prototypes/pipeline-verificacao/` (`pipeline_probe.gd`, `shaders/`) · evidência `production/qa/evidence/experimentos/ex-0011-e4-e7.md`.

| Item | Resultado e Decisão |
|---|---|
| E4 | **VERIFICADO (Opção A — Malha de borda `ArrayMesh`)** — contorno SDF interno `−w ≤ d ≤ 0` com `aa = fwidth(d)` produz `4,00 px` em 1080p, `5,33 px` em 1440p (`6,13 px` com zoom `1,15`) e `8,00 px` em 4K. A malha de borda reduz a área sombreada do contorno do `C120` em `90,0 %` (`5 931,3` vs `59 536` unid.²) e mantém o overdraw de 24 telégrafos em `0,7577 ≤ 0,80` tela (~0,19 ms de GPU vs ~0,42 ms em quad cheio) |
| E5 | **VERIFICADO (Opção a — Snapshot / Sprite único por imagem residual)** — `CanvasGroup.fit_margin` e `clear_margin` operam em unidades/pixels locais de canvas, fixados em `8.0` para acomodar o contorno externo (`3 px` na inversão, `1,75 px` no tracejado) sob zoom `1,15`. Imagens residuais usam 1 sprite com `traco_sdf` por imagem (3 draw calls no y-sort, sem triplicar `CanvasGroup`) |
| E6 | **VERIFICADO (Opção A — Quad/Tira SDF com `traco_sdf.gdshader`)** — suavização analítica de 1 px físico por `fwidth(d)` em qualquer resolução e suporte nativo aos estados Curvo, Tenso tracejado (8/6, F7) e Estourado em 1 draw call na camada `z = -5`, mantendo a lista fechada da R1 e a emenda R5b intactas |
| E7 | **VERIFICADO (`ShaderMaterial` próprio por entidade confirmado)** — `instance uniform` compila e funciona em `canvas_item` no Forward+ (4.7.2), mas o custo de CPU de manter `ShaderMaterial` próprio por entidade (duplicado no spawn) é de apenas p50 `5 µs` / p99 `11 µs` (9 entidades), `11 µs` / `22 µs` (20) e `21 µs` / `43 µs` (40 entidades, < 0,3 % do quadro). Mantida a arquitetura da R6 sem fallback de `modulate` |

**ADR-0011 atualizado** com as decisões de E4–E7 na seção `Verificação de engine (2026-11-17)`.
