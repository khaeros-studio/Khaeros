# Story 002: Sorteio das portas livres (quantas e quais tipos, F2)

> **Epic**: Portas e recompensas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/portas-e-recompensas.md` (R6, R7; F2)
**Requirement**: `TR-portas-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: RNG determinístico
**ADR Decision Summary**: mulberry32 próprio com fluxos por finalidade; o fluxo `portas` consome exatamente 4 reais por escolha livre, com chave pelo índice da câmara; lint de CI proíbe `randf`/`shuffle`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: LOW
**Engine Notes**: nenhuma API de engine; aritmética inteira de 64 bits própria (ADR-0005).

**Control Manifest Rules (this layer)**:
- Required: RNG próprio, fluxos por finalidade com posse; argumentos validados antes do primeiro avanço (ADR-0005)
- Forbidden: `randf`, `randi`, `shuffle`, `RandomNumberGenerator` em regra de jogo
- Guardrail: o consumo do fluxo não depende da posição, da Vida nem das escolhas anteriores

---

## Acceptance Criteria

*From GDD `design/gdd/portas-e-recompensas.md`, scoped to this story:*

- [x] **AC-PR-07** Próxima de combate: `u0` = 0,2999 → 3 portas; `u0` = 0,3 → 2.
- [x] **AC-PR-09** Com `n` = 3: os três tipos, em ordem sorteada; com `n` = 2: dois tipos diferentes; nunca dois iguais.
- [x] **AC-PR-11** Fronteiras: `u1` 0,4999 → bênção; 0,5 → Fragmentos; 0,8333 → Fragmentos; 0,8334 → cura; com bênção primeiro, `u2` 0,6666 → Fragmentos; 0,6667 → cura.
- [x] **AC-PR-13** `provacao` com peso 0 nunca sai; com cura 0, `n` fica em 2 e as portas são bênção e Fragmentos.
- [x] **AC-PR-14** 100 000 sorteios, n = 2: bênção+Fragmentos 0,583, bênção+cura 0,267, Fragmentos+cura 0,150 (± 0,01); P(bênção na escolha) 0,895 (± 0,01).

---

## Implementation Notes

*Derived from ADR-0005 and ADR-0015 §4:*

- Função pura `SorteioDePortas.sortear(tabela: RewardTable, fluxo) -> Array[StringName]`: lê sempre 4 reais (`u0` = quantas, `u1`/`u2` = tipos, `u3` = ordem), mesmo com n = 2.
- Testes injetam um fluxo dublê que devolve reais escolhidos (fronteiras) e o fluxo real para a distribuição (seed fixa, determinístico).
- Pesos e `chance_3_portas` vêm da `RewardTable`; nada literal.

---

## Out of Scope

- Story 003: portas forçadas, chaves por índice e o trio do chefe.
- Story 007: aplicar a escolha.

---

## Files

- `src/gameplay/portas/sorteio_de_portas.gd`
- `tests/unit/portas/portas_sorteio_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/portas/portas_sorteio_test.gd` — must exist and pass.

**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/portas-e-recompensas/story-001-reward-table-e-validacao.md`; épico `production/epics/rng/EPIC.md` (fluxos por finalidade)
- Unlocks: `production/epics/portas-e-recompensas/story-003-portas-forcadas-e-chaves.md`

**Código da fatia**: nenhum equivalente; construção do zero.
