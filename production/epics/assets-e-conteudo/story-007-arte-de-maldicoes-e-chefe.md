# Story 007: Arte das Maldições e do chefe (atores, silhuetas de HUD, retratos de escolha)

> **Epic**: Assets e conteúdo
> **Status**: Complete
> **Layer**: Foundation (arte acompanha a Apresentação)
> **Type**: Visual/Feel
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/maldicoes.md` (ML-V1, UI Requirements); `design/gdd/chefes.md`; `design/gdd/hud.md` (Visual/Audio Requirements, OQ 11: silhueta de HUD por espécie); `design/art/art-bible.md` §3.3
**Requirement**: N/A — sem TR próprio; consumido por TR-hud-013 (Bloco do Pacto), TR-tela-bencao-015 e pelos TRs de `maldicoes`/`chefes`/`pipeline-visual`.
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Pipeline visual; ADR-0012: UI e HUD (Bloco do Pacto, escolha do Pacto)
**ADR Decision Summary**: Atores no formato `SpriteFrames` em `assets/art/runtime/<ator>/` com shader de família; silhuetas do Bloco do Pacto em osso sobre tinta, sem magenta; espécie sem silhueta usa contorno genérico (fallback do HUD).
**ADR Version**: ADR-0011 2026-11-16 · ADR-0012 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: as do ADR-0011 (E3).

**Control Manifest Rules (Presentation)**:
- Required: shader de família em todo `CanvasItem` de mundo; material da UI `ui`
- Forbidden: magenta nas silhuetas de Maldição (ML-V1)
- Guardrail: entidades ≤ 200 draw calls

---

## Acceptance Criteria

*From the epic scope and the GDDs above:*

- [x] Atlas de ator para as 4 espécies (`vulto_mudo`, `espreitador_da_fenda`, `baluarte_de_cinza`, `soberano_do_limiar`) e para o chefe, passando em `validate_runtime_atlases.gd`.
- [x] Silhueta de HUD por espécie (72 × 72 e 56 × 56 a 100%) + contorno genérico de Maldição, em osso, sem magenta.
- [x] Retrato/corpo de carta para a Escolha do Pacto (modo `maldicao`).
- [x] Capturas in-game + sign-off do art-director em `production/qa/evidence/arte-maldicoes-chefe-evidence.md`.

---

## Implementation Notes

*Derived from ADR-0011 §5 e ADR-0012 §10:*

- Specs de geração novas em `design/art/asset-specs/` são do art-director (pedido antes desta story começar).

---

## Out of Scope

- Story 008: LUT e arte de UI genérica

---

## Files

- `assets/art/runtime/{vulto_mudo,espreitador_da_fenda,baluarte_de_cinza,soberano_do_limiar}/*`
- `assets/art/ui/maldicoes/*` (silhuetas de HUD e retratos)
- `production/qa/evidence/arte-maldicoes-chefe-evidence.md` + capturas

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: screenshots retidos + sign-off em `production/qa/evidence/arte-maldicoes-chefe-evidence.md`
**Status**: [x] Created and signed off (`production/qa/evidence/arte-maldicoes-chefe-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/assets-e-conteudo/story-006-arte-lote-02-inimigos-do-limiar.md` (mesmo processo); spec de arte das Maldições pelo art-director
- Unlocks: `production/epics/hud/story-006-vista-do-hud-control-ancoras-e-escala.md` (Bloco do Pacto com silhuetas); `production/epics/tela-de-bencao-e-carta/story-008-modo-maldicao-escolha-do-pacto.md`
