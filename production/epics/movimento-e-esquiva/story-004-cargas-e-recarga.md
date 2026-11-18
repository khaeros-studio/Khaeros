# Story 004: Cargas de esquiva, recarga e sincronia com o atributo

> **Epic**: Movimento e esquiva
> **Status**: Done — com pendências
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/movimento-e-esquiva.md`
**Requirement**: TR-movimento-010
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0008: Movimento e colisão própria](../../../docs/architecture/adr-0008-movimento-e-colisao-propria.md); [ADR-0009](../../../docs/architecture/adr-0009-atributos-e-modificadores.md)
**ADR Decision Summary**: Círculos e retângulo próprios, sem CharacterBody2D; o Movimento é o único escritor da posição do jogador; ordem interna R3 fixa e três pedidos síncronos ao Combate na largada da esquiva. Máximo de cargas sincronizado com o atributo cargas_max do portador no item 0 do passo.
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

- [ ] **AC-14 [L] R7/F3** cargas_max = 1, toque em 100: c = 0 nos passos 100–141, e c = 1 a partir do passo previsto.
- [ ] **AC-15 [L] F3** Gastar não zera o contador de recarga (cargas_max = c = 3, toques em 0, 9 e 18).
- [ ] **AC-16 [L] R7** O atributo muda (+1/−1): cargas atuais ajustadas conforme o GDD.
- [ ] **AC-17 [L] R7** No começo da run, c = cargas_max.
- [ ] **AC-50 [L] R3/R7** O máximo muda na Bênção, no meio da recarga.

---

## Implementation Notes

**Código atual da fatia**: src/gameplay/movement.gd (44 linhas, funções estáticas sobre Dictionary) — **reaproveitar a matemática** (resolve, recharge, teleport, displace) e **substituir a forma** (estado tipado por jogador com player_id, portador do Modificadores, contrato do Combate); a esquiva em src/gameplay/game_session.gd (_start_dash) migra para cá. Reaproveitar a lógica de recharge() (não zera ao gastar; avança antes de um possível gasto). Sincronizar o máximo no item 0 do passo consultando o portador; a notificação de mudança vem da story 007 de modificadores.

---

## Out of Scope

- Evento esquiva_sem_carga: story 003/008.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/gameplay/movimento/cargas_de_esquiva.gd
- tests/unit/movement/cargas_e_recarga_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/movement/cargas_e_recarga_test.gd` — deve existir e passar

**Status**: [x] Criado e passando (2026-11-16)

---

## Dependencies

- Depends on: [story 003](story-003-esquiva-e-contrato-com-o-combate.md); production/epics/modificadores/story-007-atributo-x-recurso-cargas-elite-run.md
- Unlocks: story 008

## Completion Notes

- **Arquivos**: src/gameplay/movimento/cargas_de_esquiva.gd; tests/unit/movement/cargas_e_recarga_test.gd (8 casos: AC-14, AC-15, AC-16 a–d, AC-17 parte de cargas, AC-50).
- Execução (2026-11-16, Godot 4.7.2): `tests/unit/movement` + `tests/integration/movement` = 42 casos, 0 falhas, 0 erros, 0 órfãos; `tests/integration/run_gameplay.gd` (fatia) continua 35/35. Legado `src/gameplay/movement.gd` e `game_session.gd` intocados até a composição do Main trocar (pendência do Main).
- **Decisões**: máximo lido por `inteiro(Atributos.CARGAS_ESQUIVA)` no item 0 de cada passo vivo (sem depender do aviso do `OuvinteDeAtributos`); subir soma a diferença, descer corta, zera progresso só se ficar cheio (divergência do cânone do AC-16c, conforme GDD).
- **Pendências**: parte de teleporte do AC-17 (c/p preservados no teleporte) fica para a story 006 (`teleportar`).
