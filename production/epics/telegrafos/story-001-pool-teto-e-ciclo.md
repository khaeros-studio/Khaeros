# Story 001: Pool fixo, teto de 24 e ciclo de vida em passos vivos

> **Epic**: Telégrafos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/telegrafos.md` (R1–R3, F1)
**Requirement**: `TR-telegrafos-001`, `TR-telegrafos-002`, `TR-telegrafos-003`, `TR-telegrafos-012`

**ADR Governing Implementation**: ADR-0014: Telégrafos: geometria e teto; ADR-0003: Entidades e portadores; ADR-0001: Orquestrador do passo
**ADR Decision Summary**: `Telegrafos extends RefCounted` com `Array[TelegrafoSlot]` de exatamente `teto_telegrafos` slots alocados em `iniciar_run()`; vaga = menor índice; `Dictionary` id→índice garante um por inimigo; recusa devolve `false` (sem fila, sem despejo) e soma `recusas_por_teto`. Ciclo `CRESCENDO → DISPARO|QUEBRADO|CANCELADO → livre` (terminais ocupam vaga por 2 passos); `varrer()` no início do item 7 libera antes do laço; `avancar(id)` depois do Status. Mira travada em `iniciar_telegrafo`; vetor zero → `(1, 0)` por `length_squared() == 0`.
**ADR Version**: ADR-0014 2026-11-16 · ADR-0003 2026-11-16 · ADR-0001 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: `Vector2.normalized()` com zero é NOT SOURCEABLE — nunca depender dele (teste explícito).

**Control Manifest Rules (this layer)**:
- Required: pool de exatamente `teto_telegrafos`, vaga de menor índice, terminais contam até liberados; `varrer()`/`avancar()` só em passo vivo
- Forbidden: `Node`/`Area2D`/`Timer` por telégrafo; `iniciar_telegrafo` alocar, crescer, enfileirar ou despejar; simulação depender da ordem dos slots
- Guardrail: < 0,05 ms por passo vivo (24 incrementos em `varrer()`)

---

## Acceptance Criteria

- [x] AC-TG-01 — Eco: `preparo` 26, p 0 → 0,5 em 13 passos → 1 e `disparo` no 26º
- [x] AC-TG-02 — jogador anda 300 px no preparo: mira do passo 0
- [x] AC-TG-03 — 2º pedido do mesmo inimigo recusado; 25º pedido recusado com 24 ativos; aceito no passo em que uma vaga sai
- [x] AC-TG-04 — dono empurrado 40 px: posição acompanha; mira e dimensões não mudam
- [x] AC-TG-05 — hitstop 6, pausa, Bênção, Transição: `restante` e p congelados
- [x] AC-TG-06 — lentidão do Selo e Abalo não mudam o preparo (26)
- [x] AC-TG-25 — sai da lista 2 passos após terminal; mira = direção dono→alvo no passo 0; distância 0 → (1; 0)
- [x] AC-TG-21 — roda com `TelegraphTuning`, lista de inimigos e `ferir_jogador` dublês, sem SceneTree

---

## Implementation Notes

- Posição nunca guardada no slot enquanto o dono existe: lida da `ConsultaDeInimigos` (dona: IA).
- `p = 1 − restante/preparo`. Contador `seq` só para ordem de desenho.
- Eventos `TelegrafoIniciado`, `TelegrafoDisparou` (ADR-0002), só ids/valores.

---

## Out of Scope

- story-002/003: formas e testes; story-006: quebrar/cancelar; story-008: `publicar()`

---

## Files

- src/gameplay/telegrafos/telegrafos.gd
- src/gameplay/telegrafos/telegrafo_slot.gd
- src/gameplay/telegrafos/telegrafo_tipos.gd
- tests/unit/telegrafos/telegrafos_pool_e_ciclo_test.gd

Fatia: `game_session.gd` guarda `phase = "windup"`, `timer` e `aim` no dicionário do inimigo (mira zero → `Vector2.DOWN`): **substituir**; a fatia só sai de cena quando a IA (épico ia-de-inimigos-e-elites story-002) passar a chamar este módulo.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/telegrafos/telegrafos_pool_e_ciclo_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: épico `production/epics/orquestrador-do-passo/` (item 7, passo vivo); épico `production/epics/conteudo/` (`TelegraphTuning`; dublê basta para o teste)
- Unlocks: `production/epics/telegrafos/story-002-derivar-formas.md`, `story-006-quebrar-e-cancelar.md`, `story-008-publicar-vistas.md`; `production/epics/ia-de-inimigos-e-elites/story-002-fases-surgimento-e-melee.md`
