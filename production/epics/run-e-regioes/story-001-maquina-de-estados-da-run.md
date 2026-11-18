# Story 001: Máquina de estados da Run (com Escolha da dupla)

> **Epic**: Run e regiões (ciclo da run)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/run-e-regioes.md` (R1, R1-P; States and Transitions)
**Requirement**: `TR-run-001`, `TR-run-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição (§3); ADR-0001: Orquestrador do passo
**ADR Decision Summary**: `Run.Fase` = `SEM_RUN`, `ESCOLHA_DE_ARMA`, `ESCOLHA_DA_DUPLA`, `ATIVA`, `ENCERRADA` (+ `motivo`); a Run nunca escreve o `EstadoDeJogo`, só chama `orquestrador.pedir_estado()`. `ESCOLHA_DA_DUPLA` só com Pactos e ≥ 2 pactuadas; Esc volta a `ESCOLHA_DE_ARMA` sem seed. A fase `Subjugado` do chefe não encerra a run.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: LOW
**Engine Notes**: `RefCounted` puro; regra 4.7 de `return` explícito em override tipado.

**Control Manifest Rules (this layer)**:
- Required: a Run só troca o `EstadoDeJogo` por `pedir_estado` (ADR-0015, ADR-0001)
- Required: estado com tabela de transição explícita; transição fora da tabela é recusada
- Forbidden: `reset()` em módulo de escopo de run; Run gravar disco

---

## Acceptance Criteria

*From GDD `design/gdd/run-e-regioes.md`, scoped to this story:*

- [x] **AC-RN-01** Sem run → Escolha de arma → Ativa → Encerrada, na ordem; `nova_run` leva Encerrada a Escolha de arma; qualquer outra transição é recusada.
- [x] **AC-RN-17** Um fim recebido com a run Encerrada é ignorado e o resumo não muda.
- [x] **AC-RN-29 (parte de estados)** Com 2 pactuadas: estado Escolha da dupla; Esc volta a Escolha de arma sem seed criada; com 0 ou 1 pactuada, segue direto a Ativa.

---

## Implementation Notes

*Derived from ADR-0015 §3 Key Interfaces:*

- `class_name Run extends RefCounted` com `enum Fase`, `fase()`, `ativa()`, `doutrina()`, `regiao()`, `indice()`; tabela `TRANSICOES: Dictionary[Fase, Array[Fase]]`.
- Teste com orquestrador falso que registra os `pedir_estado`.

---

## Out of Scope

- Story 004: o que acontece dentro de `→ ATIVA`.
- Story 005: recriação do escopo em `nova_run`.

---

## Files

- `src/gameplay/run/run.gd`
- `tests/unit/run/run_estados_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/run/run_estados_test.gd` — must exist and pass.

**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: épico `production/epics/orquestrador-do-passo/EPIC.md` (`EstadoDeJogo`, `pedir_estado`)
- Unlocks: todas as demais stories deste épico; `production/epics/portas-e-recompensas/story-005-fluxo-da-limpeza.md`

**Código da fatia**: `game_session.gd` guarda estado em `String` (`"menu"`, `"jogo"`) — **substituir** pela `Run`.
