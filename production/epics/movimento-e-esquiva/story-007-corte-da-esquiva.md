# Story 007: Corte da esquiva: consulta ordenada, dano via portador e aplicar_corte

> **Epic**: Movimento e esquiva
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/movimento-e-esquiva.md`
**Requirement**: TR-movimento-009
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0008: Movimento e colisão própria](../../../docs/architecture/adr-0008-movimento-e-colisao-propria.md); [ADR-0009](../../../docs/architecture/adr-0009-atributos-e-modificadores.md); [ADR-0010](../../../docs/architecture/adr-0010-resolucao-do-combate-no-passo.md)
**ADR Decision Summary**: Círculos e retângulo próprios, sem CharacterBody2D; o Movimento é o único escritor da posição do jogador; ordem interna R3 fixa e três pedidos síncronos ao Combate na largada da esquiva. O Corte consulta inimigos em ordem estável, calcula M pelo portador (F6 do GDD) e chama aplicar_corte no Combate; sem hitstop; o Corte não é golpe.
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

- [x] **AC-18 [L] R8/F5** O alcance é inclusivo.
- [x] **AC-19/AC-20 [L] R8** Eco no alcance nos passos 0–5 gera um Corte; acerto único por esquiva.
- [x] **AC-21 [L]** O Corte vem antes da colisão. **AC-22** teto de acertos por esquiva. **AC-23** esquivas seguidas.
- [x] **AC-24 [L] F6** O Movimento calcula o dano com portador real de Modificadores.
- [x] **AC-25 [L]** Inimigo surgindo: a lista injetada já vem filtrada pela IA.
- [x] **AC-26 [L]** O Corte não é golpe (sem hitstop, sem contadores de golpe).
- [x] **AC-51 [L]** Contexto do dano com dano_apos_esquiva +50%.
- [x] **AC-41 [I]** esquiva_iniciada abre apos_esquiva no portador real.

---

## Implementation Notes

Consulta de inimigos por interface injetada em ordem de id; dano = F6 via multiplicador_de_dano(contexto) do portador; aplicar_corte do Combate. Sem Area2D/ShapeCast.

---

## Out of Scope

- Resolução do dano e eventos: épico combate-nucleo.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/gameplay/movimento/corte_da_esquiva.gd
- tests/unit/movement/corte_da_esquiva_test.gd
- tests/integration/movement/esquiva_abre_apos_esquiva_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/movement/corte_da_esquiva_test.gd` — deve existir e passar

**Status**: [x] Complete (`tests/unit/movement/corte_da_esquiva_test.gd`, `production/qa/evidence/movimento-esquiva-evidence.md`)

---

## Dependencies

- Depends on: [story 003](story-003-esquiva-e-contrato-com-o-combate.md), [story 005](story-005-colisao-propria.md); production/epics/modificadores/story-003-condicionais-e-multiplicador-de-dano.md; production/epics/combate-nucleo/EPIC.md (aplicar_corte)
- Unlocks: story 008
