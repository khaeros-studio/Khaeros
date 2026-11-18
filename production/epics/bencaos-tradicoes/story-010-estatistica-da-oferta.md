# Story 010: Estatística da oferta — presença e raridade (F1, F3, F4-P)

> **Epic**: Bênçãos e Tradições
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/bencaos-tradicoes.md` (F1, F2, F3, F4, F4-P)
**Requirement**: `TR-bencaos-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: RNG determinístico
**ADR Decision Summary**: mulberry32 próprio com seed fixa: o teste estatístico é determinístico (mesmo resultado em toda execução).
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Teste de 100 000 ofertas: manter abaixo de alguns segundos no runner headless.

**Control Manifest Rules (Feature)**:
- Forbidden: RNG da engine; seeds aleatórias em teste

---

## Acceptance Criteria

*From GDD `design/gdd/bencaos-tradicoes.md`, scoped to this story:*

- [x] AC-BN-21: seed fixa, pool 18, 100 000 ofertas em fluxo contínuo → cada bênção com frequência 0,1667 (± 0,005); com 14 livres, 0,2143 (± 0,005); depois de 4 tomadas o pool tem 14.
- [x] AC-BN-22: nas mesmas ofertas, fração com ao menos uma Épica 0,271 (± 0,005) e com ao menos uma Rara ou melhor 0,784 (± 0,005).
- [x] AC-BN-25: pool 13, 100 000 ofertas → cada bênção com frequência 0,2308 (± 0,005).

---

## Implementation Notes

- "Fluxo contínuo" = um único fluxo avançando, não uma chave por oferta.

---

## Out of Scope

- Balanceamento das raridades (balance-check)

---

## Files

- `tests/unit/bencaos/estatistica_da_oferta_test.gd`

Código atual da fatia: nenhum.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/bencaos/estatistica_da_oferta_test.gd` — must exist and pass
**Status**: [x] Created and passing (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/bencaos-tradicoes/story-003-sorteio-da-oferta.md`
- Unlocks: None
