# Story 003: Esquiva: largada, direção, buffer e pedidos síncronos ao Combate

> **Epic**: Movimento e esquiva
> **Status**: Done — com pendências
> **Layer**: Core
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/movimento-e-esquiva.md`
**Requirement**: TR-movimento-005, TR-movimento-006
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0008: Movimento e colisão própria](../../../docs/architecture/adr-0008-movimento-e-colisao-propria.md); [ADR-0006: Input por passo](../../../docs/architecture/adr-0006-input-por-passo.md); [ADR-0010](../../../docs/architecture/adr-0010-resolucao-do-combate-no-passo.md)
**ADR Decision Summary**: Círculos e retângulo próprios, sem CharacterBody2D; o Movimento é o único escritor da posição do jogador; ordem interna R3 fixa e três pedidos síncronos ao Combate na largada da esquiva. Esquiva consumida do buffer de Input (10 passos, época corrente).
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

- [ ] **AC-06 [L] R5/R6/F2** FP, mover (1,0) só no passo 0, toque em 0: deslocamento e duração conforme o GDD.
- [ ] **AC-07 [L] R5** Pedidos ao Combate, nesta ordem: cancelar, garantir_invulneravel(D+E), esquiva_iniciada.
- [ ] **AC-08 [L] R5** Direção da esquiva (deslocamento do passo 0, ±0,001).
- [ ] **AC-09 [L] R5** Esquiva segurada nos passos 0–30 sem nunca aparecer em borda: não repete.
- [ ] **AC-10 [L] R6** Com valor(velocidade) = 580,5 (+50%) e com 0, a esquiva é a mesma (independe do atributo).
- [ ] **AC-11 [L] F4/MV3**; **AC-12 [L] R5/R3** esquiva sem carga: toque no congelamento emite esquiva_sem_carga no 1º passo vivo; **AC-13** encadeada; **AC-49** toque durante a esquiva sem carga.

---

## Implementation Notes

**Código atual da fatia**: src/gameplay/movement.gd (44 linhas, funções estáticas sobre Dictionary) — **reaproveitar a matemática** (resolve, recharge, teleport, displace) e **substituir a forma** (estado tipado por jogador com player_id, portador do Modificadores, contrato do Combate); a esquiva em src/gameplay/game_session.gd (_start_dash) migra para cá. Migrar _start_dash de game_session.gd para cá; o contrato do Combate é injetado (interface), a invulnerabilidade pertence ao Combate (Movimento não guarda; AC-42). Consumir só entradas da época corrente; consumir uma ação nunca apaga as outras.

---

## Out of Scope

- Cargas e recarga: story 004. Corte: story 007.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/gameplay/movimento/esquiva.gd, movimento.gd (estende)
- tests/unit/movement/esquiva_e_contrato_com_o_combate_test.gd

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/movement/esquiva_e_contrato_com_o_combate_test.gd` — deve existir e passar

**Status**: [x] Criado e passando (2026-11-16)

---

## Dependencies

- Depends on: [story 002](story-002-andar-e-ordem-do-passo.md); production/epics/input/EPIC.md (buffer, época)
- Unlocks: stories 004, 006–009

## Completion Notes

- **Arquivos**: src/gameplay/movimento/{esquiva.gd (direção), ev_esquiva.gd, ev_esquiva_sem_carga.gd}, movimento.gd (largada); tests/unit/movement/esquiva_e_contrato_com_o_combate_test.gd (13 casos: AC-06..AC-13, AC-49, variante do AC-12 e toque sem carga durante hitstop).
- Execução (2026-11-16, Godot 4.7.2): `tests/unit/movement` + `tests/integration/movement` = 42 casos, 0 falhas, 0 erros, 0 órfãos; `tests/integration/run_gameplay.gd` (fatia) continua 35/35. Legado `src/gameplay/movement.gd` e `game_session.gd` intocados até a composição do Main trocar (pendência do Main).
- **Decisões**: toques novos = borda `esquiva` na amostra + `drenar_esquivas_congeladas()` (ADR-0008 §4); avaliados depois de sincronizar/recarregar e antes de gastar; um `esquiva_sem_carga` por toque, inclusive durante esquiva; com carga a contagem é descartada (sem gastos múltiplos). Eventos levam player_id e época da run. Invulnerabilidade só por pedido ao Combate (Movimento não guarda).
- **Pendências**: caso "vários toques no mesmo hitstop" segue a proposta do ADR-0008 §4 (um evento por toque), ainda marcada como clarificação a confirmar na revisão Input/Movimento. Migração do `_start_dash` de game_session.gd acontece quando o Main trocar para o módulo novo.
