# Story 002: RegistroDeBencaos — pool, tomadas e restantes

> **Epic**: Bênçãos e Tradições
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/bencaos-tradicoes.md` (R2, R8, R9)
**Requirement**: `TR-bencaos-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição (§2 escopos); ADR-0009: Atributos e modificadores
**ADR Decision Summary**: `RegistroDeBencaos` vive no `EscopoDaRun` e morre com ele: Nova run recria o escopo, sem `reset()`; `restantes()` e `tomadas()` são consultas síncronas.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Nenhuma API de engine.

**Control Manifest Rules (Feature)**:
- Required: módulo de run criado pela `FabricaDaRun`
- Forbidden: `reset()` em módulo de escopo de run

---

## Acceptance Criteria

*From GDD `design/gdd/bencaos-tradicoes.md`, scoped to this story:*

- [x] AC-BN-01: sem tomadas o pool tem 18; depois de tomar 1, 17, e ela nunca volta a sair numa oferta.
- [x] AC-BN-15: depois de 2 tomadas, `restantes()` = 16 e `tomadas()` tem 2 entradas (id, raridade) na ordem em que foram pegas.
- [x] AC-BN-16: após Nova run (escopo recriado), `tomadas()` é vazio e `restantes()` = 18.

---

## Implementation Notes

- `livres()` devolve o pool na **ordem do manifesto** (índices estáveis para o F7 da story 003).
- `tomadas()` devolve cópia somente leitura (o `ResumoDaRun` usa `make_read_only()`).

---

## Out of Scope

- Story 003: sorteio
- Story 006: quando registrar (ordem da escolha)

---

## Files

- `src/gameplay/bencaos/registro_de_bencaos.gd`
- `tests/unit/bencaos/registro_de_tomadas_test.gd`

Código atual da fatia: `blessing_counts` de `game_session.gd` é **substituído** por este registro (ADR-0015 Migration Plan).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/bencaos/registro_de_tomadas_test.gd` — must exist and pass
**Status**: [x] Created and passing (2026-11-17)

---

## Dependencies

- Depends on: `production/epics/bencaos-tradicoes/story-001-pool-e-tuning-no-catalogo.md`
- Unlocks: `production/epics/bencaos-tradicoes/story-003-sorteio-da-oferta.md`

## Completion Notes

2026-11-17. Criado `src/gameplay/bencaos/registro_de_bencaos.gd` (`livres()` na ordem do manifesto, `restantes()`, `tomadas()` somente leitura `{id, raridade}`, `registrar()` recusa repetido/fora do pool, sem `reset()`). Teste `tests/unit/bencaos/registro_de_tomadas_test.gd` — 5 casos, 5 passaram. Nova run = novo objeto (a `FabricaDaRun`, épico Run, ainda não existe: o teste recria o registro).
