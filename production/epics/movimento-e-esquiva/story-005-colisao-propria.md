# Story 005: Colisão própria: círculos, retângulo, esquiva contra obstáculos

> **Epic**: Movimento e esquiva
> **Status**: Done — com pendências
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/movimento-e-esquiva.md`
**Requirement**: TR-movimento-007
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0008: Movimento e colisão própria](../../../docs/architecture/adr-0008-movimento-e-colisao-propria.md)
**ADR Decision Summary**: Círculos e retângulo próprios, sem CharacterBody2D; o Movimento é o único escritor da posição do jogador; ordem interna R3 fixa e três pedidos síncronos ao Combate na largada da esquiva.
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

- [ ] **AC-29 [L] R10** Obstáculo O em (1000; 540), r = 42: resolução conforme o GDD (borda estrita de colisão; contato exato não empurra).
- [ ] **AC-30 [L] F7** A esquiva não atravessa obstáculo.
- [ ] **AC-59 [L] F7** Raspar a borda é aceito.
- [ ] **AC-31 [L] R10** Esquiva contra a parede.
- [ ] Inimigos não bloqueiam o jogador.

---

## Implementation Notes

**Código atual da fatia**: src/gameplay/movement.gd (44 linhas, funções estáticas sobre Dictionary) — **reaproveitar a matemática** (resolve, recharge, teleport, displace) e **substituir a forma** (estado tipado por jogador com player_id, portador do Modificadores, contrato do Combate); a esquiva em src/gameplay/game_session.gd (_start_dash) migra para cá. Reaproveitar resolve() (passe ordenado de círculos + retângulo recuado), expondo-a como resolver_colisao função pura sobre array ordenado de obstáculos imutáveis; conferir as bordas contra o ADR-0008 (estrita na colisão, inclusiva no Corte). Sem solver nem epsilon.

---

## Out of Scope

- Geometria das Maldições: story 006.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/gameplay/movimento/colisao.gd
- tests/unit/movement/colisao_propria_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/movement/colisao_propria_test.gd` — deve existir e passar

**Status**: [x] Criado e passando (2026-11-16)

---

## Dependencies

- Depends on: [story 001](story-001-estado-do-jogador-e-modulo-puro.md)
- Unlocks: stories 006, 007

## Completion Notes

- **Arquivos**: src/gameplay/movimento/{colisao.gd (`resolver_colisao` + `resolver_colisao_informando` → `ResolucaoDeColisao`), geometria_de_movimento.gd, obstaculo_circular.gd}; tests/unit/movement/colisao_propria_test.gd (9 casos: AC-29 inteiro, AC-30, AC-59, AC-31, inimigo não bloqueia, igualdade das duas variantes).
- Execução (2026-11-16, Godot 4.7.2): `tests/unit/movement` + `tests/integration/movement` = 42 casos, 0 falhas, 0 erros, 0 órfãos; `tests/integration/run_gameplay.gd` (fatia) continua 35/35. Legado `src/gameplay/movement.gd` e `game_session.gd` intocados até a composição do Main trocar (pendência do Main).
- **Decisões**: uma passada na ordem do array, `<` estrito, normal (0,−1) em centro coincidente, clamp ao retângulo encolhido; sem epsilon/margem/solver. A geometria só aceita obstáculos de câmara (inimigos não entram por construção).
- **Pendências**: AC-29 "teleporte para (1000;540)" foi testado com `iniciar(pos)` porque `teleportar` é da story 006. Limite tangencial de F7 (ADR-0008 §6) permanece como documentado.
