# Story 004: Dano do Selo, abates e imunidade da Maldição

> **Epic**: Selo e Fluxo
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/selo-e-fluxo.md` (R3, R3a, R5, F2; AC l.805–812, l.825, l.831)
**Requirement**: `TR-selo-005`, `TR-selo-010`, `TR-selo-015`, `TR-selo-012` (`selo_fim`)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: Resolução do combate no passo; ADR-0009: Atributos e modificadores; ADR-0002: Canal de eventos
**ADR Decision Summary**: O Selo fere por passo pelo caminho silencioso de `ferir_inimigo`, lendo o M do grupo Selo a cada passo; o inimigo morto pelo Selo cai na varredura do Combate; o teste dentro do Selo percorre só inimigos (Maldição imune); `selo_fim` emitido pelo Selo.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: LOW
**Engine Notes**: Aritmética pura; teste de círculo pela `GeometriaDeAcerto` (story `combate-nucleo/story-004`).

**Control Manifest Rules (this layer)**:
- Required (Core): `GeometriaDeAcerto` para todo teste de acerto; Vida do inimigo em float
- Forbidden (Core): o caminho silencioso pedir hitstop ou contar acerto de arma

---

## Acceptance Criteria

- [x] AC-SF-14 [L] R3/F2 — dano de um Selo (l.805)
- [x] AC-SF-15 [L] R3 — dentro e fora (l.806)
- [x] AC-SF-16 [L] R3/F2 — dois Selos (l.807)
- [x] AC-SF-17 [L] R3 — M a cada passo (l.808)
- [x] AC-SF-18 [L] R3 — silencioso (l.809)
- [x] AC-SF-19 [L] R3/R5 — abate pelo Selo (l.810)
- [x] AC-SF-20 [L] R3/F2 — abate em dois Selos (l.811)
- [x] AC-SF-21 [L] R3 — Abalo (l.812)
- [x] AC-SF-28 [L] R3/F2 — M por Selo (l.825)
- [x] AC-SF-31 [L] R3a — Selo não fere a Maldição (l.831)

---

## Implementation Notes

*Derived from ADR-0010 and ADR-0009:*

- Chama `ferir_inimigo` no caminho silencioso; nunca escreve Vida; morte resolvida pela varredura do item 9.
- Percorre a lista de inimigos atingíveis do Combate/IA; Maldição não está nela por construção.
- **Código da fatia**: nenhum — construção do zero.

---

## Out of Scope

- `combate-nucleo/story-007`: a varredura de mortes em si

---

## Files

- `src/gameplay/selo/selo.gd` (dano, `selo_fim`)
- `tests/unit/selo/dano_do_selo_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/selo/dano_lentidao_e_camara_test.gd` — must exist and pass

**Status**: [x] Created and passing (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/selo-e-fluxo/story-003-plantar-o-selo.md`, `production/epics/combate-nucleo/story-006-dano-no-inimigo-e-empurrao.md`, `production/epics/modificadores/EPIC.md`, `production/epics/efeitos-de-status/EPIC.md` (Abalo, AC-SF-21; dublê até lá)
- Unlocks: `production/epics/combate-nucleo/story-008-eventos-e-contratos.md` (AC-70)
