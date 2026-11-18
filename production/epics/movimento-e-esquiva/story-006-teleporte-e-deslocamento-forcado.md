# Story 006: Teleporte, deslocar(v) e aviso de reset de interpolação

> **Epic**: Movimento e esquiva
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/movimento-e-esquiva.md`
**Requirement**: TR-movimento-008
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0008: Movimento e colisão própria](../../../docs/architecture/adr-0008-movimento-e-colisao-propria.md); [ADR-0007: Cena, viewport e câmera](../../../docs/architecture/adr-0007-cena-viewport-e-camera.md)
**ADR Decision Summary**: Círculos e retângulo próprios, sem CharacterBody2D; o Movimento é o único escritor da posição do jogador; ordem interna R3 fixa e três pedidos síncronos ao Combate na largada da esquiva. teleportar(pos) zera esquiva e Corte, preserva cargas; deslocar não repete Corte nem contadores; a Apresentação recebe aviso para não interpolar.
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

- [x] **AC-32 [L] R1** Teleporte: posição e anterior iguais, esquiva e Corte zerados, cargas preservadas.
- [x] **AC-58 [L] R9** deslocar(v) com mover (0,0): resolve colisão sem repetir Corte/contadores.
- [x] **AC-27/AC-28 [L] R9** Investida/deslocamento externo e cancelamento pela esquiva.
- [x] **AC-44a [I] Cena R7** Nó de apresentação real recebe o aviso de teleporte e reseta a interpolação.

---

## Implementation Notes

**Código atual da fatia**: src/gameplay/movement.gd (44 linhas, funções estáticas sobre Dictionary) — **reaproveitar a matemática** (resolve, recharge, teleport, displace) e **substituir a forma** (estado tipado por jogador com player_id, portador do Modificadores, contrato do Combate); a esquiva em src/gameplay/game_session.gd (_start_dash) migra para cá. Reaproveitar teleport() e displace() (a posição física anterior não é substituída no deslocamento externo). O aviso sai como evento/consulta lida pela Apresentação (ADR-0002).

---

## Out of Scope

- Evidência visual sem rastro: story 009.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/gameplay/movimento/movimento.gd (estende)
- tests/unit/movement/teleporte_e_deslocamento_test.gd
- tests/integration/movement/reset_de_interpolacao_no_teleporte_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/movement/teleporte_e_deslocamento_forcado_test.gd` — deve existir e passar

**Status**: [x] Complete (`tests/unit/movement/teleporte_e_deslocamento_forcado_test.gd`, `production/qa/evidence/movimento-esquiva-evidence.md`)

---

## Dependencies

- Depends on: [story 003](story-003-esquiva-e-contrato-com-o-combate.md), [story 005](story-005-colisao-propria.md); production/epics/cena-e-camera/EPIC.md
- Unlocks: story 009
