# Story 008: Consultas e eventos esquiva/esquiva_sem_carga para HUD, Pipeline e Áudio

> **Epic**: Movimento e esquiva
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/movimento-e-esquiva.md`
**Requirement**: TR-movimento-012
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0008: Movimento e colisão própria](../../../docs/architecture/adr-0008-movimento-e-colisao-propria.md); [ADR-0002: Canal de eventos](../../../docs/architecture/adr-0002-canal-de-eventos.md); [ADR-0012](../../../docs/architecture/adr-0012-ui-e-hud.md)
**ADR Decision Summary**: Círculos e retângulo próprios, sem CharacterBody2D; o Movimento é o único escritor da posição do jogador; ordem interna R3 fixa e três pedidos síncronos ao Combate na largada da esquiva. Eventos tipados no canal por passo; consumidores da Apresentação só leem.
**ADR Version**: 2026-11-16 (Last Verified; todos Accepted)

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: GDScript puro sobre Vector2 (float32; tolerância ±0,001 px por passo, ±0,01 px acumulado). Sem física da engine. Interpolação/reset na Apresentação segue ADR-0007 (HIGH).

**Control Manifest Rules (this layer)**:
- Required: Movimento é o único escritor da posição; passo_congelado() só iguala anterior=atual; Corte antes da colisão; resolver_colisao função pura sobre obstáculos ordenados (ADR-0008)
- Forbidden: CharacterBody2D/Area2D/ShapeCast2D, solver da engine, subpassos, margem, epsilon, normal dependente de velocidade; Timer; Engine.time_scale; dependência de ordem de Dictionary (ADR-0008, ADR-0010)
- Guardrail: Movimento (item 4) ≤ 0,2 ms p99 por passo (provisório, ADR-0001/ADR-0008)

---

## Acceptance Criteria

*Do GDD `design/gdd/movimento-e-esquiva.md`, recortados para esta story:*

- [x] **AC-55 [L]** Contrato de saída para HUD e Pipeline: mover (0,0) até ... — consultas (cargas, recarga, esquiva em curso) e eventos conforme o GDD.
- [x] **AC-42 [L] F4** O Movimento não guarda invulnerabilidade.
- [x] **AC-43 [I] R2** Estados do Input: cargas_max = c = 2, mover (1,0) só em ... — esquiva em Pausa/Bênção não gasta carga.
- [x] **AC-56 [I]** Invulnerabilidade de fato com Combate real: esquiva tocada no passo s com a FP.

---

## Implementation Notes

Eventos como subclasses de EventoDoPasso com ids inteiros no payload. Reação a evento de item anterior: ler do_tipo(); de item posterior: chamada direta. Adaptar game_hud.gd (cargas) só no épico hud.

---

## Out of Scope

- Exibição das cargas: épico hud. Som: épico audio.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/gameplay/movimento/eventos_do_movimento.gd, movimento.gd (estende)
- tests/unit/movement/contrato_de_saida_test.gd
- tests/integration/movement/estados_do_input_e_invulnerabilidade_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/movement/consultas_e_eventos_de_saida_test.gd` ou documento de playtest

**Status**: [x] Complete (`tests/unit/movement/contrato_de_saida_test.gd`, `tests/unit/combat/investida_e_movimento_test.gd`, `production/qa/evidence/movimento-esquiva-evidence.md`)

---

## Dependencies

- Depends on: [story 003](story-003-esquiva-e-contrato-com-o-combate.md), [story 004](story-004-cargas-e-recarga.md), [story 007](story-007-corte-da-esquiva.md); production/epics/combate-nucleo/EPIC.md
- Unlocks: story 009; production/epics/hud/EPIC.md; production/epics/audio/EPIC.md
