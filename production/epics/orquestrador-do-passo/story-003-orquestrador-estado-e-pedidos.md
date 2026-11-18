# Story 003: OrquestradorDoPasso: estado de jogo, pedidos de estado e final comum

> **Epic**: orquestrador-do-passo
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `docs/architecture/adr-0001-orquestrador-do-passo.md` (sem GDD)
**Requirement**: nenhum TR próprio. Sustenta TR-combate-nucleo-001, TR-run-005, TR-input-008.

**ADR Governing Implementation**: ADR-0001: Orquestrador do passo e estados de jogo (+ ADR-0002)
**ADR Decision Summary**: `OrquestradorDoPasso` `RefCounted` de lógica pura; enum `EstadoDeJogo.Valor` próprio (sem `SceneTree.paused`); todo `passo_fisico()` termina em `_finalizar_passo(vivo)`; módulos pedem estado por `pedir_estado`, `MORTE` vence.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: `passo_fisico()` e `quadro()` retornam `void`; override futuro com retorno não-void exige `return` explícito (4.7).

**Control Manifest Rules (this layer)**:
- Required: `estado_de_jogo.gd` próprio; pedido pendente dentro do passo, valendo só no passo 4 do final comum; final comum na ordem n_vivos, n_passos_em_jogo, `esvaziar()` uma vez (mesmo vazia), aplicar pedido.
- Forbidden: `Autoload`; `SceneTree.paused`; ler `Time`/`OS`.
- Guardrail: custo próprio do orquestrador desprezível.

---

## Acceptance Criteria

*Do ADR-0001 "Validation Criteria" (sem GDD):*

- [ ] Pedidos de `MORTE` e `BENCAO` no mesmo passo resultam em `MORTE`, aplicada só no final comum.
- [ ] Fora do passo (UI, foco), o pedido vale na hora se permitido; transição não permitida devolve `false`.
- [ ] `retomar()` sai de `PAUSA` para o estado anterior (`JOGO` ou `BENCAO`) e devolve `false` fora de `PAUSA`; `PAUSA` só a partir de `JOGO` ou `BENCAO`.
- [ ] Final comum: evento de UI enfileirado em `BENCAO` é entregue no passo seguinte; os eventos do passo que pede hitstop são entregues nesse passo; o passo congelado seguinte entrega uma lista vazia uma vez.
- [ ] `passos_em_jogo()` conta passos iniciados em `JOGO` (inclusive hitstop); caso AC-TL-06: 1.044 em Jogo, 30 de hitstop, 600 de pausa e 120 de Bênção dão diferença 1.044 e `duracao_s = 17,40`. Caso AC-RN-23: 3.600 passos com hitstop = 60 s.
- [ ] `t_vivo()` = `n_vivos / 60.0` (contador inteiro) e para durante o hitstop.
- [ ] Tabela de pedidos de estado do ADR-0001 (quem pede o quê) coberta por testes de permitido/negado.

---

## Implementation Notes

Estado, pedidos e `_finalizar_passo(vivo)` com módulos e `EventosDoPasso` injetados (story 001). Passo de 1/60 s numa constante única nomeada, não numérica solta. A ordem dos itens do passo vivo e as chamadas aos módulos ficam na story 004.

---

## Out of Scope

- story-004: ordem dos itens e hitstop; story-005: `quadro()`, `t_apres` e troca de câmara; story-006: `Main`.

---

## Files

- `src/foundation/orquestrador/estado_de_jogo.gd`, `orquestrador_do_passo.gd`
- `tests/unit/orquestrador/orquestrador_estado_test.gd`

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/orquestrador/orquestrador_estado_test.gd` — must exist and pass.

**Status**: [x] Criado e passando (2026-11-16)

---

## Dependencies

- Depends on: `production/epics/orquestrador-do-passo/story-001-canal-de-eventos.md`, `production/epics/experimentos-de-engine/story-001-passo-e-quadro.md`
- Unlocks: `story-004-ordem-do-passo.md`, `story-005-relogios-e-quadro.md`

---

## Completion Notes

**Concluída em**: 2026-11-16 (implementada junto com 004 e 005, mesmo arquivo central).

**Arquivos**: `src/foundation/orquestrador/estado_de_jogo.gd`, `orquestrador_do_passo.gd`; teste `tests/unit/orquestrador/orquestrador_estado_test.gd` (+ dublês compartilhados `tests/unit/orquestrador/dubles_do_orquestrador.gd`, não é suíte).

**Testes**: 19 casos, 19 passaram, 0 erros/falhas/órfãos (gdUnit4, pasta `tests/unit/orquestrador`: 68/68 com as stories 001/002).

**Decisões**:
- Tabela de pedidos (ADR-0001 §6) virou `OrquestradorDoPasso.transicao_permitida(de, para)`: MORTE←JOGO; BENCAO←JOGO; TRANSICAO←JOGO|MENU; MENU←INICIANDO|JOGO|PAUSA|MORTE (boot, vitória, abandono pela pausa, fim da Morte); JOGO←BENCAO|TRANSICAO; PAUSA←JOGO|BENCAO. Mesmo estado é negado; PAUSA→anterior só por `retomar()`. Teste cobre a matriz 7×7.
- Dois pedidos no mesmo passo: MORTE vence; entre dois não-MORTE o primeiro (item anterior) fica e o segundo devolve `false`. O ADR não dizia isso.
- `retomar()` dentro do passo fica pendente como pedido.
- O item 1 emite `EvPassoVivo(passos_em_jogo antes do incremento)` em todo passo iniciado em JOGO (story 001). Por isso o passo congelado seguinte ao hitstop entrega um lote com só `passo_vivo`, não vazio; a lista vazia é provada num passo fora de JOGO. Isso diverge do texto do ADR-0001 "Validation Criteria", que é anterior ao `EvPassoVivo`.
- `PASSOS_POR_SEGUNDO = 60` é a constante única; `duracao_s(passos)` estático (AC-TL-06 = 17,40 s; AC-RN-23 = 60 s).

**Pendências**: validação de `PASSOS_POR_SEGUNDO` contra `Engine.physics_ticks_per_second` fica no `Main._ready()` (story 006).
