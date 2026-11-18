# Story 001: Canal de eventos do passo (EventoDoPasso, EventosDoPasso, ConsumidorDeEventos)

> **Epic**: orquestrador-do-passo
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: —

## Context

**GDD**: `docs/architecture/adr-0002-canal-de-eventos.md` (módulo sem GDD)
**Requirement**: nenhum TR próprio (épico sem TR). Sustenta TR-combate-nucleo-009, TR-feedback-001/003/009, TR-hud-001, TR-telemetria-*.

**ADR Governing Implementation**: ADR-0002: Canal de eventos
**ADR Decision Summary**: Lista append-only por passo (`EventosDoPasso`), eventos como subclasses tipadas de `EventoDoPasso` (`@abstract`, `RefCounted`), esvaziada uma vez por passo pelo orquestrador; Apresentação recebe a lista, módulos de regra leem só eventos de itens anteriores.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: `@abstract` (4.5) e regra 4.7 de `return` explícito em override tipado não-void; `filter()` pode devolver `Array` sem tipo (usar `append` em array tipado).

**Control Manifest Rules (this layer)**:
- Required: `do_tipo()`/`todos()` devolvem cópia nova; `esvaziar()` devolve o array antigo e passa a usar um novo; `emitir()` com `assert` em debug durante a entrega (`_entregando`); downcast `as` antes de ler campos.
- Forbidden: sinais do Godot entre módulos de regra; barramento global por nome; evento como `Dictionary`; payload com `Node` ou referência viva.
- Guardrail: um `RefCounted` por evento; emissão entra no orçamento do Combate (0,3 ms).

---

## Acceptance Criteria

*Do ADR-0002 "Validation Criteria" (o módulo não tem GDD):*

- [ ] Módulo posterior vê, via `do_tipo()`, o evento emitido por item anterior e não vê os de itens posteriores (módulos falsos).
- [ ] `esvaziar()` entrega o conteúdo íntegro e deixa a lista vazia; `do_tipo()` e `todos()` devolvem cópia (mutar o resultado não altera a lista).
- [ ] `emitir()` falha por `assert` em debug quando chamado durante a entrega à Apresentação.
- [ ] Consumidores recebem a lista na ordem Telemetria, HUD, Feedback, Telas, Áudio.
- [ ] Evento de UI enfileirado fora do passo é entregue uma vez no passo seguinte.
- [ ] Teste de convenção: campos de cada evento iguais antes e depois da entrega (imutabilidade) e a lista é liberada (sem ciclo de `RefCounted`).
- [ ] Alerta em debug quando o passo emite eventos demais (limite provisório em constante).

---

## Implementation Notes

Arquivos próprios: `evento_do_passo.gd` (`@abstract`, `n_vivo`/`n_passo` preenchido por `emitir()`), `eventos_do_passo.gd`, `consumidor_de_eventos.gd` (`@abstract func consumir(eventos)`). Catálogo de subclasses de evento fica com os donos (ADR-0002 tabela; ADR-0010 para Combate); aqui entram só duas subclasses de teste e `EvPassoVivo` (emitido pelo orquestrador). Interfaces de chamada direta (`aplicar_status`, `creditar_acerto_tardio`) ficam nos épicos dos donos. Constantes (limite de alerta) em `Resource` de tuning ou constante nomeada, nunca número solto.

**Código atual**: `GameSession.step()` devolve `Array[String]`; substituído na story 007, não aqui.

---

## Out of Scope

- story-003/004: chamada de `esvaziar()` no final comum e ordem do passo.
- story-007: migrar a fatia de `Array[String]` para eventos.
- Subclasses de evento dos sistemas: épicos dos donos.

---

## Files

- `src/foundation/eventos/evento_do_passo.gd`, `eventos_do_passo.gd`, `consumidor_de_eventos.gd`
- `tests/unit/orquestrador/eventos_do_passo_test.gd`

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/orquestrador/eventos_do_passo_test.gd` — must exist and pass.

**Status**: [x] Criado e passando (19 casos, 0 falhas, 2026-11-16)

---

## Dependencies

- Depends on: `production/epics/experimentos-de-engine/story-004-eventos-aritmetica-latencia.md`
- Unlocks: `production/epics/orquestrador-do-passo/story-003-orquestrador-estado-e-pedidos.md`

---

## Completion Notes

**Data**: 2026-11-16 · **Agente**: engine-programmer (subagente)

**Arquivos criados**
- `src/foundation/eventos/evento_do_passo.gd`: `EventoDoPasso` (`@abstract`), `n_passo` e `N_PASSO_NAO_EMITIDO`
- `src/foundation/eventos/eventos_do_passo.gd`: `EventosDoPasso` (`emitir`, `ha`, `do_tipo`, `todos`, `esvaziar`, `entregar`, `entregando`, `passo_atual`, `limite_alerta`)
- `src/foundation/eventos/consumidor_de_eventos.gd`: `ConsumidorDeEventos` (`@abstract consumir`)
- `src/foundation/eventos/ev_passo_vivo.gd`: `EvPassoVivo` (`passo_vivo`, `n_vivo`)
- `tests/unit/orquestrador/eventos_do_passo_test.gd`

**Testes**: 19 casos, 0 erros, 0 falhas, 0 órfãos (gdUnit4, saída 0) em `-a res://tests/unit/orquestrador`. Os 7 critérios de aceite estão cobertos (ordem de itens com módulos falsos, cópias, esvaziar íntegro, `assert` na entrega via `is_runtime_error`, ordem dos consumidores, UI entregue uma vez no passo seguinte, imutabilidade dos campos e liberação por `weakref`, alerta de excesso via `is_push_warning`).

**Decisões tomadas (para revisão)**
1. **`n_passo` é contado pelo próprio canal**: começa em 0 e `esvaziar()` incrementa. Como o orquestrador esvazia exatamente uma vez por `passo_fisico()`, o número coincide com a contagem de passos sem API extra. Um evento de UI emitido entre passos recebe o número do passo em que é entregue.
2. **A entrega mora no canal**: `entregar(lote, consumidores)`, porque a flag `_entregando` precisa estar onde `emitir()` a lê. O orquestrador (story 003/004) chama `eventos.entregar(eventos.esvaziar(), consumidores)` no final comum. Depois de esvaziada, a lista passa a ser somente leitura (`Array.make_read_only()`), e os 5 consumidores recebem o mesmo array sem cópia.
3. **Alerta de excesso só em debug** por `assert(_verificar_excesso())`: o `assert` some no release e a lógica não lê `OS`. O alerta sai uma vez por passo (`push_warning`). O limite provisório fica em `LIMITE_ALERTA_PADRAO = 128` e pode ser injetado no construtor para teste.
4. Em release, `emitir()` durante a entrega e `emitir(null)` são ignorados.
5. O `n_vivo` citado nas notas de implementação é campo de `EvPassoVivo` (construtor), não da base. A base tem só `n_passo`, como no ADR-0002.

**Pendências**
- A dependência `experimentos-de-engine/story-004` (medição de eventos, aritmética e latência) continua `Ready`. O custo de alocação por evento e o limite de alerta definitivo saem dessa medição.
- **Aprovação**: os quatro arquivos de `src/foundation/eventos/` foram gravados com base no brief do orquestrador. O hook de escrita avisou que a exceção de subagente cobre só `production/`, `docs/` e `tests/`, então o usuário precisa revisar e aprovar esses arquivos de `src/`.
