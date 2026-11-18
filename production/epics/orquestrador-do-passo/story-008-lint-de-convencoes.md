# Story 008: Teste de convenções do passo (lint de código)

> **Epic**: orquestrador-do-passo
> **Status**: Done
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `docs/architecture/adr-0001-orquestrador-do-passo.md` §Implementation Guidelines (sem GDD)
**Requirement**: nenhum TR próprio.

**ADR Governing Implementation**: ADR-0001: Orquestrador do passo e estados de jogo (+ ADR-0002)
**ADR Decision Summary**: Regras "must never" (sem `Autoload`, sem `SceneTree.paused`, sem `Time`/`OS`/`Timer`/`create_timer` na lógica, sem `_physics_process` em módulo, sem sinais entre módulos de regra) precisam ser verificáveis por CI.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: busca textual em `.gd` e em `project.godot`; sem API pós-corte.

**Control Manifest Rules (this layer)**:
- Required: as regras de Forbidden da Foundation do manifesto são verificadas.
- Forbidden: os itens acima na lógica de `src/foundation`, `src/gameplay`.
- Guardrail: o teste roda em CI em segundos.

---

## Acceptance Criteria

*Do ADR-0001 Implementation Guidelines:*

- [ ] `project.godot` não tem seção `[autoload]` com lógica de jogo.
- [ ] Nenhum `.gd` de lógica (fora de `src/presentation` e `src/app`) contém `SceneTree.paused`, `get_tree().paused`, `Time.`, `OS.`, `Engine.time_scale`, `Timer`, `create_timer`.
- [ ] Só `src/app/main.gd` tem `_physics_process`; só nós de Apresentação têm `_process`.
- [ ] Nenhum módulo de regra declara `signal` (sinais só em `src/presentation`).
- [ ] O teste falha (mutação verificada) ao inserir cada padrão proibido num arquivo temporário de teste.

---

## Implementation Notes

Teste gdUnit4 que varre `res://src/` com `DirAccess`/`FileAccess` (leitura no editor/CI, não em runtime de jogo). Lista de pastas "de lógica" e padrões em constante do próprio teste, com a nota de que novas pastas de `src/` devem entrar nela. Exceções explícitas e justificadas por arquivo (ex.: `game_session.gd` enquanto durar a fatia, marcado com a story 007).

---

## Out of Scope

- Lint do RNG (épico `rng`, AC-32) e do catálogo (épico `conteudo`, AC-24).

---

## Files

- `tests/unit/orquestrador/convencoes_do_passo_test.gd`

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/orquestrador/convencoes_do_passo_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/orquestrador-do-passo/story-004-ordem-do-passo.md`
- Unlocks: None

## Completion Notes

**Concluída em**: 2026-11-16 · engine-programmer (subagente).

**Arquivo**: `tests/unit/orquestrador/convencoes_do_passo_test.gd`.

**Testes**: 4 casos, 4 passaram: varredura de `res://src` inteiro sem violações; `project.godot` sem `[autoload]`; mutação de cada um dos 10 padrões (`SceneTree.paused`, `get_tree().paused`, `Time.`, `OS.`, `Engine.time_scale`, `Timer`, `create_timer`, `signal`, `_physics_process`, `_process`) num arquivo virtual de `src/gameplay/` é detectada; comentário, Apresentação e `main.gd` não acusam, e `_physics_process` em Apresentação acusa.

**Decisões**: a mutação é feita sobre texto em memória com caminho de lógica, pela mesma função `violacoes()` da varredura (sem gravar arquivo em `src/`). Pastas de lógica: `src/foundation`, `src/gameplay`, `src/content` (constante com nota para novas pastas). `_process` é permitido em `src/presentation` e no `main.gd` (o ADR-0001 manda o `Main` repassar `_process`). Exceções por arquivo, justificadas: `game_input.gd` (legado, story 007 / épico input), `input/rotulos_de_acao.gd` (`OS.get_keycode_string`, conversão pura), `rng/fonte_de_entropia_do_sistema.gd` (entropia real, RNG story 004).
