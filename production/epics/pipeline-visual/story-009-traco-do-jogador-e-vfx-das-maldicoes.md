# Story 009: Traço do jogador (CanvasGroup, inversão, imagens residuais) e VFX das Maldições

> **Epic**: Pipeline visual
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

O jogador fica num `CanvasGroup` com `char_grupo` (contorno de invulnerabilidade, inversão, flash), com imagens residuais no y do pé. As Maldições ganham fio de vínculo e marca do Virote em `traco_sdf` (z −5), sem telégrafo SDF; o corpo da Maldição é `char_sprite`, sem contorno de invulnerabilidade nem inversão.

**GDD**: `design/gdd/pipeline-visual.md` (R6, R5b, F7)
**Requirement**: `TR-pipeline-006`, `TR-pipeline-015`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Pipeline visual
**ADR Decision Summary**: `CanvasGroup` + `char_grupo` com `fit_margin` da R6 (unidade a confirmar no E5); E5 escolhe snapshot (a) ou rig duplicado (b) para as imagens residuais; fio e Virote em `traco_sdf` (família `sem_grading`), no pool do Feedback, `largura_fio_px` × `escala_traco`, fio some na reserva, Exaustão e troca de câmara.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: EX-0011-E5 (`CanvasGroup.fit_margin` unidade, `TEXTURE_PIXEL_SIZE`, contorno por fora, custo) e EX-0011-E6 (`Line2D` texturizada × quad SDF de segmento) — ambos NOT SOURCEABLE. Linhas de `CanvasItem` sem feather no 4.7 (confirmado).

**Control Manifest Rules (this layer)**:
- Required: apresentação guiada por `t_vivo`/`t_apres`; material por entidade
- Forbidden: Never `draw_line`/`draw_arc`/`Line2D` sem textura para traço de jogo
- Guardrail: overdraw ≤ 3,5 telas na média, ≤ 5 no pico; VFX 64 draw calls

---

## Acceptance Criteria

*From GDD `design/gdd/pipeline-visual.md`, scoped to this story:*

- [x] AC-PV-31 [L] R6 — tempos do corpo (Combate dublê)
- [x] AC-PV-80 [L] R6 — a inversão substitui o tracejado
- [x] AC-PV-67 [L] R6 — inversão no CanvasGroup (espelho)
- [x] AC-PV-83 [I] R6 — imagens residuais no y do pé
- [x] AC-PV-86 [I] R5b — fio de vínculo (300, 420 e 500 px; z −5)
- [x] AC-PV-87 [I] R5b — marca do Virote (um só ilhós)
- [x] AC-PV-29 [V] R6/F7 — tracejado de ação e imagens residuais
- [x] AC-PV-30 [V] R6/E5 — contorno de invulnerabilidade na silhueta
- [x] AC-PV-32 [V] R6/R11 — flash de acerto visto
- [x] AC-PV-68 [V] R6/E5 — inversão vista
- [x] AC-PV-78 [V] R6 — fio de vínculo (E2 e E6)

---

## Implementation Notes

*Derived from ADR-0011 §5 and the Pactos amendment:*

- Só `char_grupo` e os passes usam `escala_traco` com `FRAGCOORD`; o traço vive em unidades de canvas.
- Nenhum shader novo na lista fechada; faixas novas (`largura_fio_px` etc.) entram no `VisualTuning` com regras VV.

---

## Out of Scope

- `production/epics/feedback-de-combate/story-007-respostas-das-maldicoes.md`: quando a marca do Virote muda de alvo (AC-FB-39)

---

## Files

- `src/presentation/visual/vista_do_jogador.gd`
- `src/presentation/visual/imagens_residuais.gd`
- `src/presentation/visual/vista_fio_de_vinculo.gd`
- `assets/shaders/char_tint/char_grupo.gdshader`, `assets/shaders/sem_grading/traco_sdf.gdshader`
- `tests/unit/visual/traco_do_jogador_test.gd`
- `tests/integration/visual/traco_e_maldicoes_test.gd`
- `production/qa/evidence/pipeline-visual-009-*.png` + `pipeline-visual-009-evidence.md`

Código da fatia: `world_view.gd::_player` — **substituir**; os tempos de flash/invulnerabilidade da fatia são só referência de sensação.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: capturas retidas em `production/qa/evidence/` + sign-off em `production/qa/evidence/pipeline-visual-009-evidence.md`; os [L]/[I] em `tests/unit/visual/traco_do_jogador_test.gd` e `tests/integration/visual/traco_e_maldicoes_test.gd`
**Status**: [x] Complete (`tests/unit/pipeline/sdf_telegrafos_camadas_e_orcamento_test.gd`, `production/qa/evidence/pipeline-visual-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/pipeline-visual/story-008-nos-por-camada-e-validador.md`; `production/epics/experimentos-de-engine/EPIC.md` (EX-0011-E5, EX-0011-E6)
- Unlocks: `production/epics/feedback-de-combate/story-007-respostas-das-maldicoes.md`
