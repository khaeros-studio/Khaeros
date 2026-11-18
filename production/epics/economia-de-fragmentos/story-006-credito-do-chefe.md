# Story 006: Crédito do chefe (abate, Exorcizar; nada ao Pactuar)

> **Epic**: Economia de Fragmentos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/economia-de-fragmentos.md` (R2-P, R4-P, F3-P, Edge Cases da emenda Pactos)
**Requirement**: `TR-economia-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição (§4.5); ADR-0001: Orquestrador do passo; ADR-0010: Resolução do combate no passo
**ADR Decision Summary**: Fora de Pactos, Chefes chamam `creditar(CHEFE, 6)` no 1º passo vivo após o hitstop do chefe (`s + 37`), antes de `camara_limpa(4, chefe)`; em Pactos, o crédito sai só no Exorcizar, após `resolver_subjugado`; Pactuar não chama `creditar`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH (ADR-0001/ADR-0010)
**Engine Notes**: Passo de 60 Hz próprio; nada de `SceneTree.paused`.

**Control Manifest Rules (Feature)**:
- Required: Portas/Run consultam `run.ativa()` (morte vence)
- Forbidden: a Economia guardar a taxa do chefe (`RegionDef.fragmentos_chefe` é o dono)

---

## Acceptance Criteria

*From GDD `design/gdd/economia-de-fragmentos.md`, scoped to this story:*

- [x] AC-EF-31: saldo 11 (coletados 5), abate com Lâmina → `saldo_mudou(17, +6, chefe)` antes de `camara_limpa`; a Run lê coletados 11 e credita 15; saldo 32; total 26.
- [x] AC-EF-32 / AC-EF-33: Pactuar → nenhum `saldo_mudou` com origem `chefe`, saldo 26 após a vitória; Exorcizar → exatamente 1 `saldo_mudou(17, +6, chefe)`, saldo 32.
- [x] AC-EF-34: `jogador_morreu` no passo em que o chefe zera a Vida → nenhum crédito `chefe` nem `vitoria`; saldo intacto.
- [x] AC-EF-35: índice 5 recompensado: 4 portas de Fragmentos + abate + vitória = 31; + Pactuar = 25.

---

## Implementation Notes

*Derived from ADR-0015 §4.5:*

- A Economia não muda (aceita créditos duplicados; garantir 1 crédito é de Chefes F6). Este teste é o guarda da duplicação (Edge Case).
- `creditar(chefe, 0)` é recusado com `EC1` (story 001); Chefes não devem chamar.

---

## Out of Scope

- Épico chefes: quando o chefe chama `creditar`
- Épico vinculo-e-pactos: escolha Pactuar/Exorcizar

---

## Files

- `tests/integration/economia/credito_do_chefe_test.gd`

Código atual da fatia: nenhum.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/economia/credito_do_chefe_test.gd`
**Status**: [x] Created and passing (2026-11-16)

---

## Dependencies

- Depends on: `production/epics/economia-de-fragmentos/story-005-ordem-com-run-e-portas.md`; `production/epics/chefes/EPIC.md` e `production/epics/vinculo-e-pactos/EPIC.md` (stories a criar; pode rodar antes com dublês de Chefes)
- Unlocks: None

## Completion Notes

**2026-11-16 (gameplay-programmer).** Teste `tests/integration/economia/credito_do_chefe_test.gd` (6 casos, passou): abate → `saldo_mudou(17,+6,chefe)` antes de `camara_limpa`, saldo 32, total 26; Pactuar → nenhum crédito chefe, 26; Exorcizar → exatamente 1 crédito chefe, 32; morte no passo do abate → nada; extremos 31/25; `creditar(chefe, 0)` → EC1.

Pendência: Chefes/Run/Câmaras são dublês (épicos chefes e vinculo-e-pactos sem código). O guarda contra crédito duplicado precisa rodar de novo com o `Chefes` real.
