# Story 004: Ordem fixa do passo vivo, hitstop e passo fora de JOGO

> **Epic**: orquestrador-do-passo
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `docs/architecture/adr-0001-orquestrador-do-passo.md` (sem GDD)
**Requirement**: nenhum TR próprio. Sustenta TR-combate-nucleo-001/002, TR-movimento-002/003, TR-ia-001.

**ADR Governing Implementation**: ADR-0001: Orquestrador do passo e estados de jogo
**ADR Decision Summary**: Passo vivo em ordem fixa (1 Input, 3 Combate-início, 4 Movimento, 5 Combate-golpe, 6 Selo, 6.1 Maldições, 7 Inimigos, 8 Projéteis, 9 mortes, 10 Câmaras); em hitstop só desconto e `passo_congelado()`; fora de `JOGO` só `passo_congelado()` do Movimento.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: interface `Passo` `@abstract` com `passo(amostra)` e `passo_congelado()`, ambos `void`; módulo com outra base usa adaptador (herança única).

**Control Manifest Rules (this layer)**:
- Required: a ordem do passo exposta como lista única testável; testes com módulos falsos que registram a ordem; orquestrador só consulta `hitstop_ativo()` (contador é do Combate).
- Forbidden: `_physics_process` próprio em módulo de jogo; ordenar por `process_priority`; adicionar/remover nós de física dentro de `passo_fisico()`.
- Guardrail: total do passo vivo ≤ 1,0 ms p99.

---

## Acceptance Criteria

*Do ADR-0001 "Validation Criteria":*

- [ ] Teste com módulos falsos prova a ordem exata dos itens do passo vivo (inclui 6.1) e que fora de `JOGO` só `passo_congelado()` do Movimento é chamado.
- [ ] Hitstop pendente não desconta contadores; "câmara limpa" só é avaliada com `hitstop_ativo()` falso; no hitstop o Combate desconta 1 e o item 6.1 não roda.
- [ ] A lista de ordem é única (uma constante/função) e o teste a compara à lista do ADR.
- [ ] Um passo vivo termina em `_finalizar_passo(true)`; o de hitstop em `_finalizar_passo(false)` com `n_passos_em_jogo` incrementado.
- [ ] Nenhum módulo falso é chamado duas vezes por passo.

---

## Implementation Notes

O orquestrador recebe os módulos por injeção como `Passo`. Módulos futuros (Selo, Maldições, IA, Câmaras) entram como falsos/nulos injetáveis; um módulo ausente é erro explícito de composição, não `null` silencioso. Chamada dos itens 3/5/7/8/9 segue a interface do Combate (ADR-0010; ordem interna é do dono).

**Código atual**: `GameSession.step()` concentra passo, hitstop local e `_pending_hitstop`: **substituir** gradualmente (story 007).

---

## Out of Scope

- Conteúdo de cada item (épicos dos donos); `quadro()` e relógios (story-005); composição (story-006).

---

## Files

- `src/foundation/orquestrador/passo.gd`, `ordem_do_passo.gd` (+ ajuste em `orquestrador_do_passo.gd`)
- `tests/unit/orquestrador/ordem_do_passo_test.gd`

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/orquestrador/ordem_do_passo_test.gd` — must exist and pass.

**Status**: [x] Criado e passando (2026-11-16)

---

## Dependencies

- Depends on: `production/epics/orquestrador-do-passo/story-003-orquestrador-estado-e-pedidos.md`
- Unlocks: `story-005-relogios-e-quadro.md`, `story-007-migracao-da-fatia.md`

---

## Completion Notes

**Concluída em**: 2026-11-16.

**Arquivos**: `src/foundation/orquestrador/passo.gd` (`@abstract Passo`), `ordem_do_passo.gd` (lista única `OrdemDoPasso.itens()`/`modulos()`), `fonte_de_amostra.gd` e `controle_de_hitstop.gd` (interfaces novas, ver abaixo), `passo_fisico()` em `orquestrador_do_passo.gd`; teste `tests/unit/orquestrador/ordem_do_passo_test.gd`.

**Testes**: 9 casos, 9 passaram (ordem exata e comparação com a lista do ADR incluindo 6.1; uma chamada por módulo; mesma amostra para todos; fora de JOGO só `movimento:congelado` em MENU/PAUSA/BENCAO/TRANSICAO/MORTE; hitstop: Combate desconta 1 e Movimento congela, sem 6.1 nem Câmaras; hitstop pendente não desconta; Câmaras só com hitstop inativo; contadores vivo/hitstop; módulo ausente).

**Decisões / desvios**:
- Dois arquivos fora da lista da story, mesma pasta: `FonteDeAmostra` (item 1, `amostrar()`, chamado uma vez por passo em todo estado) e `ControleDeHitstop` (`hitstop_ativo()` + `passo_congelado_do_combate()`, nomes do ADR-0010). O Input e o Combate não são um `Passo` único, por isso precisam de interfaces próprias. Os itens 3/5/7/8/9 entram como adaptadores `Passo` (dono: Combate/IA, story 006/007).
- `configurar_passo(fonte, hitstop, modulos: Dictionary[StringName, Passo])` devolve as chaves ausentes e faz `push_error`; sem configuração, `passo_fisico()` faz `push_error` e não roda (erro explícito, não `null` silencioso).
- `hitstop_ativo()` é consultado uma vez por passo em JOGO; não é consultado fora de JOGO.

**Pendências**: orçamento de 1,0 ms p99 não medido aqui (harness `MedidorDeOrcamento`, cena de estresse). Adaptadores reais e migração de `GameSession.step()`: stories 006/007.
