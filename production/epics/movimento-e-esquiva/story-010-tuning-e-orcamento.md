# Story 010: MovementTuning (MV1–MV8) validado e orçamento de 0,2 ms

> **Epic**: Movimento e esquiva
> **Status**: Complete
> **Layer**: Core
> **Type**: Config/Data
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/movimento-e-esquiva.md`
**Requirement**: TR-movimento-013, TR-movimento-014
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md); [ADR-0001](../../../docs/architecture/adr-0001-orquestrador-do-passo.md); [ADR-0008: Movimento e colisão própria](../../../docs/architecture/adr-0008-movimento-e-colisao-propria.md)
**ADR Decision Summary**: Valores de tuning vêm do catálogo validado (MovementTuning, MV1–MV8); orçamento do Movimento até 0,2 ms por passo, medido pelo MedidorDeOrcamento.
**ADR Version**: 2026-11-16 (Last Verified; todos Accepted)

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: Medição de CPU exige build exportado de release e relógio injetado (MedidorDeOrcamento); ver EX-0001/0002 em experimentos-de-engine.

**Control Manifest Rules (this layer)**:
- Required: Movimento é o único escritor da posição; passo_congelado() só iguala anterior=atual; Corte antes da colisão; resolver_colisao função pura sobre obstáculos ordenados (ADR-0008)
- Forbidden: CharacterBody2D/Area2D/ShapeCast2D, solver da engine, subpassos, margem, epsilon, normal dependente de velocidade; Timer; Engine.time_scale; dependência de ordem de Dictionary (ADR-0008, ADR-0010)
- Guardrail: Movimento (item 4) ≤ 0,2 ms p99 por passo (provisório, ADR-0001/ADR-0008)

---

## Acceptance Criteria

*Do GDD `design/gdd/movimento-e-esquiva.md`, recortados para esta story:*

- [x] **AC-35..38 [L] MV1/MV2/MV4–MV7** Validação de cada knob do MovementTuning (faixas, avisos que podem coexistir).
- [x] **AC-53 [L] R11** Faixas dos campos: cada linha muda um campo da FP.
- [x] **AC-54 [L]** Limites exatos MV1/MV2/MV6/MV7/MV8.
- [x] **AC-39 [I]** Erros e avisos chegam ao destino (relator).
- [x] **AC-48 [P]** Desempenho em tests/performance/movement/: p99 ≤ 0,2 ms por passo na cena de estresse, 600 passos (desvio explícito se medido fora de release).
- [x] Nenhum valor de tuning hardcoded em src/gameplay/movimento/.

---

## Implementation Notes

**Código atual da fatia**: src/gameplay/movement.gd (44 linhas, funções estáticas sobre Dictionary) — **reaproveitar a matemática** (resolve, recharge, teleport, displace) e **substituir a forma** (estado tipado por jogador com player_id, portador do Modificadores, contrato do Combate); a esquiva em src/gameplay/game_session.gd (_start_dash) migra para cá. Constantes hoje em game_session.gd/movement.gd (TICK_RATE, durações, raios) migram para o catálogo .tres de MovementTuning; durações convertidas em passos na carga (quantização única como Movement.ticks).

---

## Out of Scope

- Importação do conteúdo: épico conteudo.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- assets/data/ (MovementTuning.tres), src/gameplay/movimento/movement_tuning.gd
- tests/unit/movement/movement_tuning_test.gd
- tests/performance/movement/orcamento_do_movimento_test.gd
- production/qa/smoke-*.md (smoke de Config/Data)

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- Config/Data: smoke check em `production/qa/smoke-*.md`

**Status**: [x] Complete (`src/gameplay/movimento/movement_tuning.gd`, `tests/unit/movement/movement_tuning_test.gd`, `production/qa/evidence/movimento-esquiva-evidence.md`)

---

## Dependencies

- Depends on: [story 001](story-001-estado-do-jogador-e-modulo-puro.md); production/epics/conteudo/EPIC.md; production/epics/experimentos-de-engine/EPIC.md
- Unlocks: None
