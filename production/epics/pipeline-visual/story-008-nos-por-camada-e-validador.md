# Story 008: Nós por camada (ambiente, entidades, oclusão), material por entidade e validador

> **Epic**: Pipeline visual
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

Troca o `_draw()` imediato de `world_view.gd` por nós nas camadas do ADR-0007: ambiente com `amb_*` (material compartilhado por variante), entidades com `AnimatedSprite2D` + `char_sprite` e material próprio duplicado no spawn, quadro escolhido pelo passo vivo (congela no hitstop), oclusão F9 e o validador de família de debug, que também acusa `tel_sdf` com dono da facção do jogador.

**GDD**: `design/gdd/pipeline-visual.md` (R1, R4, R5b, R6, R8, R9, F9)
**Requirement**: `TR-pipeline-001`, `TR-pipeline-011`, `TR-pipeline-016`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Pipeline visual; ADR-0001: Orquestrador do passo
**ADR Decision Summary**: Cada âncora do y-sort tem `ShaderMaterial` próprio (uniforms `papel`, `flash`, `alfa_oclusao`), sem `instance uniform`; atores com `speed_scale` 0 e avanço manual pelo passo vivo; emissores do relógio vivo com `speed_scale` 0 no congelamento; validador percorre os `CanvasItem`s das nove camadas de mundo.
**ADR Version**: ADR-0011 2026-11-16; ADR-0001 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: EX-0011-E3 (`speed_scale` 0 em emissores, avanço manual de `AnimatedSprite2D`; fallback `emitting = false` + avanço manual ou `CPUParticles2D` pelo passo) e EX-0011-E7 (material por entidade × compartilhado; fallback: material por papel com `flash` via `modulate`, que muda a R6 e precisa de decisão). `light_mask`/`range_item_cull_mask` NOT SOURCEABLE.

**Control Manifest Rules (this layer)**:
- Required: material duplicado por entidade no spawn e devolvido ao pool no despawn; validador ativo em debug; apresentação guiada por `t_vivo`/`t_apres`
- Forbidden: Never manter `world_view.gd` com `_draw()` como pipeline
- Guardrail: entidades 200 draw calls; ambiente 40

---

## Acceptance Criteria

*From GDD `design/gdd/pipeline-visual.md`, scoped to this story:*

- [x] AC-PV-05 [I] R1 — validador de família (debug)
- [x] AC-PV-88 [L] R5b — Maldição sem `tel_sdf` (validador acusa dono da facção do jogador)
- [x] AC-PV-33 [L] F9 — exemplo do GDD (oclusão)
- [x] AC-PV-34 [L] F9 — regras
- [x] AC-PV-74 [I] R6 — material único por entidade (EX-0011-E7)
- [x] AC-PV-46 [I] R8/E3 — emissores e animações congelam
- [x] AC-PV-72 [I] R9 — `light_mask` dos `sem_grading`
- [x] AC-PV-50 [V] R4 — névoa nunca sobre o chão
- [x] AC-PV-52 [V] R4 — veios e primeiro plano

---

## Implementation Notes

*Derived from ADR-0011 §5 and Migration Plan step 4:*

- Ordem: ambiente com `amb_sprite`, depois entidades com `char_sprite` sobre os `SpriteFrames` de `assets/art/runtime/<ator>/` (conferir a margem de 6 texels da OQ12; reimportar se faltar). Telégrafos ficam na story 007.
- Oclusão F9 com histerese no `EstadoVisual`; a chave de y-sort do jogador é o y do pé.
- `world_view.gd` fica como desenho de debug até a cena nova passar na captura; depois sai do caminho do `Main`.

---

## Out of Scope

- Story 009: `CanvasGroup` do jogador, inversão, imagens residuais
- `production/epics/feedback-de-combate/story-008-vistas-e-pool-de-vfx.md`: pool de VFX

---

## Files

- `src/presentation/visual/vista_do_ambiente.gd`
- `src/presentation/visual/vista_de_entidade.gd`, `pool_de_materiais.gd`
- `src/presentation/visual/validador_de_familia.gd`
- `src/presentation/world_view.gd` (rebaixado a debug, depois removido do `Main`)
- `assets/shaders/amb_graded/*.gdshader`, `assets/shaders/char_tint/char_sprite.gdshader`
- `tests/unit/visual/oclusao_f9_test.gd`, `tests/unit/visual/validador_tel_sdf_faccao_test.gd`
- `tests/integration/visual/nos_por_camada_test.gd`
- `production/qa/evidence/pipeline-visual-008-*.png` + `pipeline-visual-008-evidence.md`

Código da fatia: `world_view.gd` **substituir**; **reaproveitar** `_ensure_atlases` (carga de atlas/manifestos), `_draw_elite_part` (montagem das peças da elite, reescrita como nós) e `tools/art/validate_runtime_atlases.gd` como base do pipeline de sprites.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/visual/nos_por_camada_test.gd` + os dois [L] acima; capturas de AC-PV-50/52 retidas em `production/qa/evidence/` com assinatura do art-director
**Status**: [x] Complete (`tests/unit/pipeline/sdf_telegrafos_camadas_e_orcamento_test.gd`, `production/qa/evidence/pipeline-visual-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/pipeline-visual/story-005-escritor-de-globais-e-pipeline-visual.md`; `production/epics/experimentos-de-engine/EPIC.md` (EX-0011-E3, EX-0011-E7); `production/epics/cena-e-camera/EPIC.md` (camadas e y-sort)
- Unlocks: `production/epics/pipeline-visual/story-009-traco-do-jogador-e-vfx-das-maldicoes.md`, `production/epics/pipeline-visual/story-010-impact-frames-orcamento-e-leitura.md`, `production/epics/feedback-de-combate/story-008-vistas-e-pool-de-vfx.md`
