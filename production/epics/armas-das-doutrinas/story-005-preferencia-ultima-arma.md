# Story 005: Pré-seleção, confirmação e preferência `ultima_arma`

> **Epic**: Armas das Doutrinas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/armas-das-doutrinas.md` (R4; AC l.1309–1358)
**Requirement**: `TR-armas-006`, `TR-armas-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0013: Persistência do MVP
**ADR Decision Summary**: A última arma fica em `user://preferencias.cfg` `[armas] ultima_arma`, gravada só ao confirmar, pelo adaptador de persistência (gravação atômica com `.bak`); o build de playtest não pré-seleciona e faz zero leituras e gravações de `preferencias.cfg`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: MEDIUM
**Engine Notes**: ADR-0013: `FileAccess.store_*` devolve `bool` (4.4, confirmado); `flush()` e `DirAccess.rename` sobre destino no Windows são NOT SOURCEABLE — ficam no adaptador do épico `persistencia`, testados lá. Esta story usa dublê do repositório.

**Control Manifest Rules (this layer)**:
- Forbidden: a Run gravar disco
- Required: colaborador opcional com variante Nula (repositório de preferências nulo no playtest)

---

## Acceptance Criteria

- [x] AC-AR-08 [L] R4 — arma pré-selecionada (l.1309)
- [x] AC-AR-09 [L] R4 — confirmar e Esc (l.1323)
- [x] AC-AR-11 [L] R4 — uma carta; arma inválida (l.1340)
- [x] AC-AR-39 [L] R4 — build de playtest (l.1345)

---

## Implementation Notes

*Derived from ADR-0013 and ADR-0015:*

- Lógica da escolha (`EscolhaDeArma`, RefCounted) separada da tela; lê/grava pelo repositório de preferências injetado; no playtest recebe a variante Nula e o teste conta zero chamadas.
- **Código da fatia**: nenhum — construção do zero.

---

## Out of Scope

- Story 007: a tela e a navegação
- Épico `persistencia`: o adaptador de arquivo

---

## Files

- `src/gameplay/armas/escolha_de_arma.gd`
- `tests/unit/weapons/escolha_de_arma_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/armas/escolha_e_injecao_test.gd` — must exist and pass

**Status**: [x] Created and passing (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/armas-das-doutrinas/story-004-arma-da-run-e-injecao.md`, `production/epics/persistencia/EPIC.md`
- Unlocks: `production/epics/armas-das-doutrinas/story-007-tela-de-escolha-de-arma.md`
