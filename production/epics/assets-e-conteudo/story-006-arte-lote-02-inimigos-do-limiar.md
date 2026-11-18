# Story 006: Fechar o lote 02 de arte — Anomalia Menor, Fenda Errante e peças de elite

> **Epic**: Assets e conteúdo
> **Status**: Complete
> **Layer**: Foundation (arte acompanha a Apresentação)
> **Type**: Visual/Feel
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/pipeline-visual.md` (formato de sprite/material); specs `design/art/asset-specs/lote-02-inimigos-limiar.md` e `fila-de-geracao-lote-02.md`; `design/art/art-bible.md`
**Requirement**: N/A — sem TR próprio; os atlas são consumidos pelos TRs de `pipeline-visual`.
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Pipeline visual
**ADR Decision Summary**: Atores animados usam `AnimatedSprite2D` com os `SpriteFrames` de `assets/art/runtime/<ator>/`, `char_sprite`, quadro escolhido pelo passo vivo; atlas conferidos quanto à margem de 6 texels (OQ12), reimportando se faltar; todo `CanvasItem` de mundo com shader de uma das três famílias.
**ADR Version**: ADR-0011 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: avanço manual de quadro (E3 do ADR-0011) — depende de `production/epics/experimentos-de-engine/` EX-0011.

**Control Manifest Rules (Presentation)**:
- Required: todo `CanvasItem` de mundo com shader de uma das três pastas de família
- Forbidden: `draw_line`/`draw_arc` como pipeline
- Guardrail: entidades ≤ 200 draw calls

---

## Acceptance Criteria

*From the epic scope (entrega 2) and the lote 02 spec:*

- [x] Ficha e 4 folhas de Anomalia Menor e de Fenda Errante geradas pela fila e aprovadas contra a Art Bible; peças de elite (X0) prontas.
- [x] Atlas em `assets/art/runtime/{anomalia_menor,fenda_errante,elite_pecas}/` passam em `tools/art/validate_runtime_atlases.gd` (inclui margem de 6 texels).
- [x] `assets/art/runtime/elite_pecas/` e a evidência `production/qa/evidence/assets-lote-02-2026-11-14/` versionadas.
- [x] Captura in-game de cada inimigo + sign-off do art-director em `production/qa/evidence/arte-lote-02-evidence.md`.

---

## Implementation Notes

*Derived from ADR-0011 §5 e Migration Plan 4:*

- Conferir a margem de 6 texels e reimportar onde faltar; sem novo formato de atlas.

---

## Out of Scope

- Story 007: Maldições e chefe
- Épico `pipeline-visual`: troca do `world_view.gd`

---

## Files

- `assets/art/source/raw/*` (folhas geradas); `assets/art/runtime/{anomalia_menor,fenda_errante,elite_pecas}/*`
- `tools/art/validate_runtime_atlases.gd` (já modificado no working tree; manter)
- `production/qa/evidence/arte-lote-02-evidence.md` + capturas

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: screenshots retidos + sign-off em `production/qa/evidence/arte-lote-02-evidence.md`
**Status**: [x] Created and signed off (`production/qa/evidence/arte-lote-02-evidence.md`)

---

## Dependencies

- Depends on: None para gerar; `production/epics/pipeline-visual/` para a captura com shader de família
- Unlocks: `production/epics/assets-e-conteudo/story-007-arte-de-maldicoes-e-chefe.md`
