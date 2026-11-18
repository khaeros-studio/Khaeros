# Story 002: Andar, ordem interna do passo, passo() e passo_congelado()

> **Epic**: Movimento e esquiva
> **Status**: Done — com pendências
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/movimento-e-esquiva.md`
**Requirement**: TR-movimento-002, TR-movimento-003, TR-movimento-004
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0008: Movimento e colisão própria](../../../docs/architecture/adr-0008-movimento-e-colisao-propria.md); [ADR-0001](../../../docs/architecture/adr-0001-orquestrador-do-passo.md)
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

- [ ] **AC-03 [L] R4/F1** FP, mover (1, 0): posição após N passos conforme o GDD.
- [ ] **AC-04 [L] F1** Deslocamento de um único passo (±0,001).
- [ ] **AC-05 [L] R4** mover (−1,0) nos passos 0–9 e (0,0) no 10: a parada é imediata, sem inércia.
- [ ] **AC-52 [L] R2** Passo congelado: só anterior = atual; nenhuma consulta ao hitstop.
- [ ] **AC-40 [I] ordem e bloqueio** Orquestrador de passo real e Input real: Movimento roda só em Jogo, antes de Combate e Selo (TR-movimento-002/004).

---

## Implementation Notes

**Código atual da fatia**: src/gameplay/movement.gd (44 linhas, funções estáticas sobre Dictionary) — **reaproveitar a matemática** (resolve, recharge, teleport, displace) e **substituir a forma** (estado tipado por jogador com player_id, portador do Modificadores, contrato do Combate); a esquiva em src/gameplay/game_session.gd (_start_dash) migra para cá. Reaproveitar a matemática de resolve() para o andar (conferir contra os ADRs: sem margem/epsilon). O orquestrador decide passo() ou passo_congelado(); fora de JOGO só passo_congelado(). O Movimento não consulta hitstop.

---

## Out of Scope

- Esquiva: story 003. Colisão: story 005.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/gameplay/movimento/movimento.gd (estende)
- tests/unit/movement/andar_e_ordem_do_passo_test.gd
- tests/integration/movement/ordem_e_bloqueio_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/movement/andar_e_ordem_do_passo_test.gd` — deve existir e passar

**Status**: [x] Criado e passando (2026-11-16)

---

## Dependencies

- Depends on: [story 001](story-001-estado-do-jogador-e-modulo-puro.md); production/epics/orquestrador-do-passo/EPIC.md; production/epics/input/EPIC.md
- Unlocks: stories 003–009

## Completion Notes

- **Arquivos**: movimento.gd (passo/passo_congelado, F1, investida); tests/unit/movement/andar_e_ordem_do_passo_test.gd (5 casos: AC-03, AC-04 tabela inteira, AC-05, AC-52, investida); tests/integration/movement/ordem_e_bloqueio_test.gd (2 casos: AC-40 em 300 passos + fora de JOGO só passo_congelado).
- Execução (2026-11-16, Godot 4.7.2): `tests/unit/movement` + `tests/integration/movement` = 42 casos, 0 falhas, 0 erros, 0 órfãos; `tests/integration/run_gameplay.gd` (fatia) continua 35/35. Legado `src/gameplay/movement.gd` e `game_session.gd` intocados até a composição do Main trocar (pendência do Main).
- **Decisões**: Movimento recebe `ComandosDoPasso` por `FonteDeComandos.comandos_do_passo(amostra.id_passo)` porque `Passo.passo()` só recebe a amostra.
- **Pendências**: AC-40 usa o `OrquestradorDoPasso` real e o `BufferDeComandos` real, mas a amostra vem de uma `FonteDeAmostra` de roteiro, não do `ProvedorDeEntrada` completo (precisaria do adaptador de engine); refazer com Input completo na composição do Main. Combate/Selo são dublês.
