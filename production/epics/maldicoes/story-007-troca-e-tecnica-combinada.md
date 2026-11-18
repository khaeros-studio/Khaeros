# Story 007: Ação Troca e Técnica Combinada por dados

> **Epic**: Maldições (Doutrina de Pactos)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/maldicoes.md` (R11, R12, F5)
**Requirement**: `TR-maldicoes-010`, `TR-maldicoes-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017: Aliados e invocações; ADR-0006: Input por passo; ADR-0004: Catálogo de dados
**ADR Decision Summary**: Sub-passo 5 do 6.1: troca manual do buffer testa a R11; aceita, executa `saida` da que sai e depois `entrada` da que entra no mesmo passo, emite `troca_feita(manual)`, `tecnica_combinada`, `maldicao_saiu_de_campo` e fixa a recarga. A Entrada lê o estado deixado pela Saída (imobilizado, atraído, Abalo) para a sinergia F5 e só considera ids atingíveis. Nenhum par tem código próprio. A ação Troca vem do input por passo (buffer de 10 passos, congelado no hitstop).
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: HIGH (ADR-0006) / LOW (ADR-0017)
**Engine Notes**: ADR-0006: amostra própria por passo; nada de `Input` direto na regra.

**Control Manifest Rules (Core)**:
- Required: todo dano por `aplicar_golpe_maldicao`; ordem da R23
- Forbidden: código por par de espécies
- Guardrail: item 6.1 ≤ 0,1 ms

---

## Acceptance Criteria

*Valores da emenda Pactos (2026-11-15) prevalecem:*

- [x] AC-ML-15 (R11, R12, F5): `vulto_mudo` em campo, `espreitador_da_fenda` `Pronta`, recarga 0, Troca → no mesmo passo *Paredes de Sombra* causa **5** + `imobilizado` 90 passos; *Salto de Emboscada* lê `imobilizado` e causa **`6 × 1,5 = 9`** (**14** no passo); `recarga_troca = 240`; sai 1 `troca_feita(manual)` e 1 `tecnica_combinada`.
- [x] AC-ML-16 (R11): com `recarga_troca = 120`, reserva `Exausta` ou Maldição `Saltando`, Troca não muda nada e emite `troca_indisponivel` uma vez por toque.

---

## Implementation Notes

- A ação `troca` é do épico `input` (bind R / Tab, LT); aqui só se consome `ComandosDoPasso`.
- `troca_indisponivel(motivo)` com motivos `recarga`, `exausta`, `sem_reserva`, `saltando`.
- Reusa `ExecutorDeTecnica` da story 004.

---

## Out of Scope

- 008: Chamado no mesmo passo (AC-ML-32).

---

## Files

- `src/gameplay/maldicoes/troca_de_maldicao.gd`, `executor_de_tecnica.gd`
- `assets/data/curses/*.tres` (campos `saida`/`entrada` preenchidos)
- `tests/unit/maldicoes/troca_e_tecnica_combinada_test.gd`

Código da fatia: `src/foundation/game_input.gd` é adaptado pelo épico `input` (ação `troca`); esta story não o edita.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/maldicoes/troca_e_tecnica_combinada_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/maldicoes/story-006-contadores-regeneracao-e-dupla-que-cresce.md`; épicos `production/epics/input/` (ação Troca), `production/epics/efeitos-de-status/` (Abalo para a sinergia)
- Unlocks: `production/epics/maldicoes/story-008-chamado-do-pacto-e-atracao.md`
