# Story 001: ModuloDeIA — lista estável, ciclo do item 7 e consultas de alvos

> **Epic**: IA de inimigos e elites
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/ia-de-inimigos-e-elites.md` (R1, R2, R13, R19)
**Requirement**: `TR-ia-001`, `TR-ia-002`, `TR-ia-011`, `TR-ia-013`, `TR-ia-016`

**ADR Governing Implementation**: ADR-0018: IA de inimigos e chefe (§1, §2, §5 consultas, §9 `criar_inimigo`); ADR-0003: Entidades e portadores; ADR-0010; ADR-0001
**ADR Decision Summary**: `ModuloDeIA extends RefCounted` é dono da lista de `InimigoRef` em ordem de id (contador da run compartilhado com `MaldicaoRef`), implementa `remover_morto`/`pedir_recuperacao`/`subjugar` do ADR-0010, e expõe `inicio_do_item_7`, `passo(id)` (só se `vivo(id)`: Vida > 0 e não `SUBJUGADO`), `fim_do_item_7`, `criar_inimigo`, `camara_nova` (ids não reiniciam), `atingiveis()` (pré-alocado, ordem de id, sem Maldição/acuada/`SURGINDO`/`SUBJUGADO`) e `mais_perto(ponto, raio_max)` (menor (dist², id), inclusivo, −1 se vazio).
**ADR Version**: ADR-0018 2026-11-16 · ADR-0003 2026-11-16 · ADR-0010 2026-11-16 · ADR-0001 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW (ADR-0018); `@abstract` (4.5+) na base `Comportamento` — verificar erro de parse em subclasse incompleta no 4.7.2 (ADR-0018 Verification 1)
**Engine Notes**: `override` com retorno não-void exige `return` explícito (4.7).

**Control Manifest Rules (this layer)**:
- Required: `RefCounted` puro; dependências no `configurar`; consultas preenchem valores pré-alocados
- Forbidden: `Node`, `Timer`, `Area2D`, física da engine; expor `InimigoRef`; Autoload
- Guardrail: IA ≤ 0,15 ms p99 por passo vivo com 9 inimigos; zero alocação em `passo()`/`fim_do_item_7()`

---

## Acceptance Criteria

- [x] AC-IA-20 — por inimigo: Status, impacto, IA nessa ordem; Vida ≤ 0 não age; hitstop/pausa/Bênção/Transição: nenhuma fase avança
- [x] AC-IA-21 — item 7 roda inteiro no passo da morte do jogador; inimigos param no seguinte
- [x] AC-IA-41 — `atingiveis()` [1, 3] com posição e raio; `mais_perto(jogador, 480)`: 1; 481/480 → 3 (inclusivo); além → vazio; ids nunca se repetem
- [x] AC-IA-56 (parte R19) — `atingiveis()` e `mais_perto` nunca devolvem a acuada
- [x] TR-ia-013 — testes com dublês de Combate, Telégrafos, RNG, Câmaras, sem SceneTree
- [x] Medição ADR-0018 Verification 3: `passo()` não aloca (contagem de objetos antes/depois de 600 passos)

---

## Implementation Notes

- Mudança aceita no ADR-0010 §2: condição do passo (5) é `vivo(id)`, não `atingivel(id)`.
- O laço do item 7 percorre um retrato do tamanho da lista (lacaios criados no passo só agem no seguinte).

---

## Out of Scope

- story-002/003: comportamentos; story-004: separação

---

## Files

- src/gameplay/ia/modulo_de_ia.gd
- src/gameplay/ia/inimigo_ref.gd
- src/gameplay/ia/vista_de_inimigo.gd
- src/gameplay/ia/comportamento.gd
- tests/unit/ia/ia_lista_e_consultas_test.gd

Fatia: a lista de inimigos em dicionários de `game_session.gd` (`_enemy_step`) é **referência**, substituída por este módulo; `game_input.gd`/`movement.gd` passam a consultar `atingiveis()`/`mais_perto` (adaptação nos épicos input e movimento-e-esquiva).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ia/ia_lista_e_consultas_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: épicos `production/epics/orquestrador-do-passo/`, `production/epics/combate-nucleo/` (interface `ModuloDeIA`)
- Unlocks: todas as demais stories deste épico; `production/epics/efeitos-de-status/story-001-modelo-e-aplicar.md` (consulta `atingivel`)
