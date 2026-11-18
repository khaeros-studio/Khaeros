# Story 004: Sorteio do encontro (F1) no fluxo RNG `pactos` e consultas do encontro

> **Epic**: Vínculo e pactos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/vinculo-e-pactos.md` (C. Encontro de pacto; F1 `pact_encounter_draw`; G1, G3)
**Requirement**: `TR-vinculo-002`, `TR-vinculo-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: RNG determinístico; ADR-0015: Ciclo da run e composição
**ADR Decision Summary**: mulberry32 próprio com fluxos por finalidade; `pactos` é fluxo próprio. `planejar_encontro(doutrina, fluxo_pactos)` consome sempre 4 reais em Pactos, mesmo com garantia, e nada fora; encontro só nos índices `indices_encontro = [1, 2]`, no máximo um por run; 1º garantido no índice 1 com o Espreitador. `encontro_na_camara`/`encontro_aguardando` não usam RNG.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: LOW
**Engine Notes**: Lint de CI contra `randf`/`shuffle` (ADR-0005).

**Control Manifest Rules (Feature)**:
- Required: módulos criados pela `FabricaDaRun`; dependências no `_init`
- Forbidden: `randf`, `randi`, `shuffle` na regra
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-VP-03 (F1, G1): `primeiro_encontro_visto = false` e só *Vulto* pactuado → qualquer seed planeja índice 1 com `espreitador_da_fenda`; o fluxo `pactos` avançou exatamente 4 reais.
- [x] AC-VP-04 (F1): mesma seed, perfis diferentes só em `encontro_pendente` → os 4 reais e o estado final do fluxo são iguais.
- [x] AC-VP-05 (F1): fonte falsa `u = (0,42; 0,81; 0,30; 0,55)`, *Vulto* + *Espreitador* pactuados, sem garantia → `ocorre`, índice 2, `baluarte_de_cinza`; com `u2 = 0,90`, `vulto_mudo`.
- [x] AC-VP-06 (F1, G3): `runs_pactos_sem_encontro = 2` e `u0 = 0,99` → `ocorre = true`.

---

## Implementation Notes

- Fonte de aleatoriedade injetada (interface do fluxo), dublê com sequência fixa nos testes.
- Estado do encontro: `Planejado(i, especie)` → `Aguardando`/`Fugiu`/`Resolvido`.

---

## Out of Scope

- Nascimento da acuada: story 005. Run de outra Doutrina (AC-VP-02, fluxo não pedido) é testada na story 005.

---

## Files

- `src/gameplay/vinculo/sorteio_do_encontro.gd`, `encontro_de_pacto.gd`
- `tests/unit/vinculo/sorteio_do_encontro_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/vinculo/sorteio_do_encontro_test.gd` — must exist and pass
**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/vinculo-e-pactos/story-003-primeiro-pacto-e-escolha-da-dupla.md`; épico `production/epics/rng/` (fluxo `pactos`)
- Unlocks: `production/epics/vinculo-e-pactos/story-005-acuada-alvo-e-fuga.md`
