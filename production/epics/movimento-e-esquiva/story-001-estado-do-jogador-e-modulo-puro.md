# Story 001: Estado do jogador tipado, módulo puro injetado e determinismo

> **Epic**: Movimento e esquiva
> **Status**: Done — com pendências
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/movimento-e-esquiva.md`
**Requirement**: TR-movimento-001, TR-movimento-011
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0008: Movimento e colisão própria](../../../docs/architecture/adr-0008-movimento-e-colisao-propria.md); [ADR-0003](../../../docs/architecture/adr-0003-entidades-e-portadores.md)
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

- [ ] **AC-01 [L] R11/F2/F3/F4** Na FP (fixture padrão): D = 9, E = 3, R = 42, d_passo = 22,5 e demais derivados conforme o GDD.
- [ ] **AC-02 [L] R12** O Movimento é criado num teste gdUnit4 sem SceneTree e sem Autoload; dependências (Input, Modificadores, Combate, obstáculos, tuning) injetadas.
- [ ] Só o Movimento escreve a posição do jogador; outros módulos pedem deslocar(v) (TR-movimento-001).
- [ ] Duas instâncias com as mesmas entradas dão posições idênticas bit a bit no mesmo build (TR-movimento-011).

---

## Implementation Notes

**Código atual da fatia**: src/gameplay/movement.gd (44 linhas, funções estáticas sobre Dictionary) — **reaproveitar a matemática** (resolve, recharge, teleport, displace) e **substituir a forma** (estado tipado por jogador com player_id, portador do Modificadores, contrato do Combate); a esquiva em src/gameplay/game_session.gd (_start_dash) migra para cá. Estado por jogador em RefCounted tipado (EstadoDoMovimento: player_id, pos, anterior, cargas, recarga, esquiva em curso). Solo usa player_id = 0 (preparação co-op). Interfaces de entrada/saída como contratos (@abstract) para dublês.

---

## Out of Scope

- story 002: andar e passo. story 003: esquiva. story 005: colisão.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- src/gameplay/movimento/movimento.gd, estado_do_movimento.gd, contratos.gd
- tests/unit/movement/estado_do_jogador_e_modulo_puro_test.gd
- src/gameplay/movement.gd (legado: removido quando o Main migrar)

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/movement/estado_do_jogador_e_modulo_puro_test.gd` — deve existir e passar

**Status**: [x] Criado e passando (2026-11-16)

---

## Dependencies

- Depends on: production/epics/input/EPIC.md, production/epics/modificadores/EPIC.md (stories pendentes); production/epics/orquestrador-do-passo/EPIC.md
- Unlocks: stories 002–010

## Completion Notes

- **Arquivos**: src/gameplay/movimento/{movimento.gd (`MovimentoDoJogador extends Passo`, nome do ADR-0008), estado_do_movimento.gd, parametros_do_movimento.gd, movement_tuning.gd, combate_para_movimento.gd, fonte_de_comandos.gd}; tests/unit/movement/{apoio_movimento.gd (dublês/fixture FP), estado_do_jogador_e_modulo_puro_test.gd (5 casos)}.
- Execução (2026-11-16, Godot 4.7.2): `tests/unit/movement` + `tests/integration/movement` = 42 casos, 0 falhas, 0 erros, 0 órfãos; `tests/integration/run_gameplay.gd` (fatia) continua 35/35. Legado `src/gameplay/movement.gd` e `game_session.gd` intocados até a composição do Main trocar (pendência do Main).
- **Decisões**: "contratos.gd" virou dois arquivos @abstract (`CombateParaMovimento`, `FonteDeComandos`) porque GDScript tem um class_name por arquivo. Portador injetado pelo tipo `ConsultaDeAtributos` (o `Portador` real o estende); testes usam dublê porque precisam mudar velocidade/cargas_esquiva no meio do roteiro. `MovementTuning` criado aqui (padrões 0, valores só por dado/fixture) — validação MV1–MV8, .tres e catálogo continuam da story 010. `publicar_em(JogadorRef)` espelha posição/cargas/esquiva (ADR-0003).
- **Pendências**: AC-02 usa roteiro de 1000 passos gerado por padrão fixo no teste, não o arquivo `fixtures/roteiro_determinismo.json`, e sem Eco/Corte (Corte é story 007) — completar quando a 007 existir. Composição no Main + adaptador `FonteDeComandos` sobre `ProvedorDeEntrada` + adaptador `CombateParaMovimento` do Combate: pendentes (fora do escopo).
