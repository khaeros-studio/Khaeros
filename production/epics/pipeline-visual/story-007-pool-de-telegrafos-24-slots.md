# Story 007: Pool de 24 slots de telégrafo, duas passadas e contorno secundário

> **Epic**: Pipeline visual
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

Os 48 nós de telégrafo (quad z −5 + borda z 5 por slot) pré-instanciados, lidos de `VistaDeTelegrafo` por slot; estados do telégrafo, intensidade de acessibilidade (`contorno_px`), comportamento acima do teto e o contorno tracejado secundário do chefe que mira a Maldição.

**GDD**: `design/gdd/pipeline-visual.md` (R5, R5a, F4, Edge Cases)
**Requirement**: `TR-pipeline-005`, `TR-pipeline-014`, `TR-pipeline-012` (contorno de acessibilidade do telégrafo)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Pipeline visual; ADR-0014: Telégrafos: geometria e teto
**ADR Decision Summary**: O ADR-0014 é dono do mapeamento id → slot e publica `VistaDeTelegrafo.slot`; este ADR só lê `forma, pos, rot, dims, p, modo, estado, seq`; slot ausente na publicação fica `visible = false`. Secundário: círculo no raio do alvo, só contorno tracejado, mesma malha e draw call, some no passo do flash do principal.
**ADR Version**: ADR-0011 2026-11-16; ADR-0014 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Largura do contorno, malha × quad e custo dependem do EX-0011-E4 (1080p/1440p/4K). Critérios [V] rodam com GPU, fora do CI.

**Control Manifest Rules (this layer)**:
- Required: 24 slots (48 nós) pré-instanciados na carga; material por slot
- Forbidden: Never `TIME` em shader de mundo; never `draw_line`/`draw_arc`
- Guardrail: sombras + telégrafos 54 draw calls (6 + 24 × 2)

---

## Acceptance Criteria

*From GDD `design/gdd/pipeline-visual.md`, scoped to this story:*

- [x] AC-PV-24 [L] R5/F4 — estados (Telégrafos dublê)
- [x] AC-PV-75 [L] R5/R11 — intensidade do telégrafo (opção de acessibilidade, 6 px × `escala_traco`, sem pulsar)
- [x] AC-PV-25 [I] R5/R6 — duas passadas e camadas
- [x] AC-PV-49 [I] R9/Edge — acima do teto (30 pedidos)
- [x] AC-PV-84 [I] R5a — contorno secundário (Padrão 3 do Soberano do Limiar)
- [x] AC-PV-85 [L] R5a — estados (secundário some no disparo, sem flash)
- [x] AC-PV-19 [V] F3/F4/E4 — contorno medido na captura
- [x] AC-PV-26 [V] R5/Art Bible §6.3 — corpo por cima, contorno visível
- [x] AC-PV-27 [V] Edge — sobreposição e borda da câmara

---

## Implementation Notes

*Derived from ADR-0011 §5, §8 and the Pactos amendment:*

- `MeshInstance2D` em `TelegrafoPreenchimento` (z −5) e `ArrayMesh` em `TelegrafoContorno` (z 5), um `ShaderMaterial` `tel_sdf` por nó; anéis de área num nó irmão anterior aos preenchimentos.
- `tel_sdf` reserva o uniform `contorno_px`; crescimento sem oscilação de alfa nem de largura.
- O flash do telégrafo passa por `EstadoVisual.pedir_flash_telegrafo(area)`; negado deixa o telégrafo sem o osso, mas visível.

---

## Out of Scope

- `production/epics/telegrafos/EPIC.md`: geometria de acerto, alvo travado e publicação das vistas
- Story 010: orçamento medido em captura

---

## Files

- `src/presentation/visual/pool_de_telegrafos.gd`
- `assets/shaders/sem_grading/tel_sdf.gdshader`
- `tests/unit/visual/estados_do_telegrafo_test.gd`
- `tests/integration/visual/pool_de_telegrafos_test.gd`
- `tests/integration/visual/cena_captura.tscn` (criação, compartilhada pelas stories 008–010)
- `production/qa/evidence/pipeline-visual-007-*.png` + `pipeline-visual-007-evidence.md`

Código da fatia: `world_view.gd::_telegraph` — **substituir**.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/visual/pool_de_telegrafos_test.gd` + `tests/unit/visual/estados_do_telegrafo_test.gd`; capturas dos [V] retidas em `production/qa/evidence/` com assinatura (technical-artist para medida, art-director para leitura)
**Status**: [x] Complete (`tests/unit/pipeline/sdf_telegrafos_camadas_e_orcamento_test.gd`, `production/qa/evidence/pipeline-visual-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/pipeline-visual/story-005-escritor-de-globais-e-pipeline-visual.md`, `production/epics/pipeline-visual/story-006-espelho-sdf-e-tracejado.md`; `production/epics/telegrafos/EPIC.md` (publicação `VistaDeTelegrafo`); `production/epics/experimentos-de-engine/EPIC.md` (EX-0011-E4)
- Unlocks: `production/epics/pipeline-visual/story-010-impact-frames-orcamento-e-leitura.md`, `production/epics/audio/story-003-seletor-de-tons-dos-telegrafos.md`
