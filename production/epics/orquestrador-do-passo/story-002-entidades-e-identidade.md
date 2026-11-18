# Story 002: Entidades vivas, identidade na run e varredura de mortes

> **Epic**: orquestrador-do-passo
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: —

## Context

**GDD**: `docs/architecture/adr-0003-entidades-e-portadores.md` (sem GDD)
**Requirement**: nenhum TR próprio. Sustenta TR-ia-001, TR-combate-nucleo-011.

**ADR Governing Implementation**: ADR-0003: Entidades e portadores
**ADR Decision Summary**: Estado vivo em `RefCounted` (`InimigoRef`, `JogadorRef`), definições `Resource` imutáveis, id `int` crescente único da run, posse de campos por sistema; chefe é `InimigoRef` com `chefe: bool`; a acuada não é `InimigoRef`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: só `RefCounted`, `Array[T]` tipado e `Resource` por convenção; nenhum dado pós-corte.

**Control Manifest Rules (this layer)**:
- Required: id de combatente `int` de sequência única da run (inimigos e Maldições compartilham o contador); resultado guardado além da chamada guarda o id e revalida; portador não guarda referência forte de volta; varredura de mortes sobre retrato ordenado.
- Forbidden: `StringName` ou índice de array como id; nó de cena como estado.
- Guardrail: sem ciclos de `RefCounted` (nenhum vazamento).

---

## Acceptance Criteria

*Do ADR-0003 "Rastreabilidade e critérios de validação" (sem GDD próprio):*

- [ ] Gerar três inimigos, remover o segundo e gerar outro: a ordem dos sobreviventes e a identidade (id) de cada instância se mantêm; o id não é reaproveitado.
- [ ] Dois `InimigoRef` da mesma definição: alterar um não altera o outro nem a definição (`Resource` do catálogo intacto).
- [ ] A sequência de ids é única e compartilhada (um `GeradorDeIds` injetado) e reinicia com a run.
- [ ] A varredura de mortes usa um retrato ordenado dos inimigos com Vida ≤ 0; mortes geradas durante o passe entram no passe seguinte.
- [ ] `chefe` é campo de `InimigoRef`; a acuada não tem `InimigoRef` e não entra na lista de inimigos.
- [ ] Nenhum campo de `InimigoRef`/`JogadorRef` referencia o portador de volta (teste de liberação por `weakref`).

---

## Implementation Notes

Estruturas só com campos e a posse documentada (IA: lista/fases/posição; Combate: Vida/escudo/impacto; Movimento: posição/cargas do jogador; Modificadores: atributos; Status: efeitos; Selo: `no_selo`/Fluxo). Sem lógica de regra. `Portador` é do épico `modificadores` (ADR-0009); `MaldicaoRef` do épico `maldicoes` (ADR-0017); slots de telégrafo do épico `telegrafos`. O "retrato" é uma função auxiliar `retrato_de_mortos(lista)` testável.

**Código atual**: `src/gameplay/game_session.gd` guarda inimigos como `Dictionary`: **substituir** por `InimigoRef` na story 007 (aqui só os tipos novos).

---

## Out of Scope

- Portador, MaldicaoRef, slots de telégrafo: outros épicos (acima).
- Remoção real via IA (épico `ia-de-inimigos-e-elites`) e varredura do Combate.

---

## Files

- `src/foundation/entidades/inimigo_ref.gd`, `jogador_ref.gd`, `gerador_de_ids.gd`, `retrato_de_mortos.gd`
- `tests/unit/orquestrador/entidades_test.gd`

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/orquestrador/entidades_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: `production/epics/orquestrador-do-passo/story-007-migracao-da-fatia.md`; épicos `modificadores`, `ia-de-inimigos-e-elites`, `combate-nucleo`

## Completion Notes

2026-11-16. Código escrito por agente (engine-programmer) como rascunho e instalado pela sessão principal com a autorização do usuário ("Faça 1-2-3-4").
- Arquivos: `src/foundation/entidades/gerador_de_ids.gd`, `inimigo_ref.gd`, `jogador_ref.gd`, `retrato_de_mortos.gd`; teste `tests/unit/orquestrador/entidades_test.gd`.
- Testes: `-a res://tests/unit/orquestrador` → 32 casos (19 da story 001 + 13 desta), 0 falhas, 0 órfãos.
- Decisões: id começa em `GeradorDeIds.PRIMEIRO_ID = 1`, 0 = `ID_INVALIDO`; `InimigoRef`/`JogadorRef` só com campos e dono documentado; definição tipada como `Resource` até existir o `EnemyDef`; `portador` é `RefCounted` genérico até o épico `modificadores`; efeitos de Status ficam no módulo de Status indexados pelo id; `retrato_de_mortos(lista)` devolve cópia na ordem da lista.
- Pendência: remoção ordenada real é do épico da IA (o teste a simula).
