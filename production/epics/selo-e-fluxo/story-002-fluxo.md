# Story 002: Fluxo — regeneração, acerto de arma e congelamento

> **Epic**: Selo e Fluxo
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/selo-e-fluxo.md` (R1, R1a, F1; AC l.786–791, l.822–823, l.829–830)
**Requirement**: `TR-selo-001`, `TR-selo-007`, `TR-selo-008`, `TR-selo-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: Resolução do combate no passo; ADR-0002: Canal de eventos; ADR-0001: Orquestrador do passo
**ADR Decision Summary**: Fluxo float 0..100, regenera por passo vivo no item 6 e ganha +3 por `acerto_de_arma` do item 5; o acerto do item 8 é creditado no fim do passo (`creditar_acerto_tardio`) e só serve no seguinte; Fluxo parado no hitstop e fora de Jogo; só `acerto_de_arma` gera Fluxo (Virote sim, golpe de Maldição não).
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: LOW
**Engine Notes**: Aritmética pura; `passo_congelado()` da base `@abstract` do ADR-0001 (4.5).

**Control Manifest Rules (this layer)**:
- Required (Core, contrato): `selo.creditar_acerto_tardio` uma vez por `acerto_de_arma` do item 8
- Required: reset do Fluxo na nova run é estado do Selo (Run só chama `nova_run`)
- Forbidden: `Engine.time_scale`, `Timer`

---

## Acceptance Criteria

- [x] AC-SF-01 [L] R1/F1 — regeneração (l.786)
- [x] AC-SF-02 [L] R1/F1 — teto (l.787)
- [x] AC-SF-03 [L] R1 — acerto de arma (l.788)
- [x] AC-SF-04 [L] R1 — por alvo (l.789)
- [x] AC-SF-05 [L] R1/Edge — congelado (l.790)
- [x] AC-SF-06 [L] R1/R6 — passa de câmara (l.791)
- [x] AC-SF-25 [L] R1/R2 — hitstop (l.822)
- [x] AC-SF-26 [L] F1 — item 8 (l.823)
- [x] AC-SF-29 [L] R1a/F1 — Virote gera Fluxo (l.829)
- [x] AC-SF-30 [L] R1a — Maldição não gera Fluxo (l.830)

---

## Implementation Notes

*Derived from ADR-0010, ADR-0002 and ADR-0001:*

- `Selo extends RefCounted`, escopo de run; Fluxo float; lê os eventos `acerto_de_arma` do item 5 na lista do passo; o crédito tardio do item 8 fica pendente até o fim do passo.
- `passo_congelado()` não mexe no Fluxo; `nova_run()` zera conforme o GDD.
- Fixture FS do GDD (l.778): dublês de Combate, Movimento, Input e Câmaras.
- **Código da fatia**: nenhum — construção do zero.

---

## Out of Scope

- Story 003: o gasto de Fluxo ao plantar

---

## Files

- `src/gameplay/selo/selo.gd` (Fluxo)
- `tests/unit/selo/fluxo_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/selo/fluxo_test.gd` — must exist and pass

**Status**: [x] Created and passing (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/selo-e-fluxo/story-001-seal-tuning-e-validacao.md`, `production/epics/combate-nucleo/story-002-passo-vivo-e-hitstop.md`. Sem dependência dura de `armas-das-doutrinas/story-006` nem de `maldicoes`: AC-SF-29/30 usam dublê de evento (`acerto_de_arma` de origem Virote; golpe de origem `maldicao`), o que evita o ciclo selo-002 → armas-006 → combate-009 → combate-008 → selo-004 → selo-002; a confirmação com a Besta real fica em `production/epics/combate-nucleo/story-008-eventos-e-contratos.md` (AC-70)
- Unlocks: `production/epics/selo-e-fluxo/story-003-plantar-o-selo.md`
