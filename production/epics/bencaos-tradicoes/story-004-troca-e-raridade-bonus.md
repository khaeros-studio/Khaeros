# Story 004: Troca da oferta e raridade_bonus

> **Epic**: Bênçãos e Tradições
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/bencaos-tradicoes.md` (R6, R7, Edge Cases "Escolha e troca")
**Requirement**: `TR-bencaos-003`, `TR-bencaos-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: RNG determinístico; ADR-0012: UI e HUD (Decisão 11)
**ADR Decision Summary**: Cada troca re-sorteia do pool inteiro com mais 6 reais da mesma chave da câmara; a Tela testa `trocar` antes de `aceitar` no mesmo passo (a troca vence); sem cargas, a troca é ignorada e não consome.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW (lógica); a parte de Tela é HIGH (ADR-0012), fora desta story
**Engine Notes**: Nenhuma API de engine.

**Control Manifest Rules (Feature)**:
- Required: base de trocas vem de `BencaosTuning.trocas_iniciais` (posse resolvida); o atributo `trocas_oferta` do Modificadores só soma
- Forbidden: RNG da engine

---

## Acceptance Criteria

*From GDD `design/gdd/bencaos-tradicoes.md`, scoped to this story:*

- [x] AC-BN-04 / AC-BN-11: com `trocas_oferta` 1 a troca re-sorteia, gasta 1 (resta 0) e consome mais 3 + 3 reais do fluxo da câmara; com 0 é recusada sem consumir real.
- [x] AC-BN-12: a troca pode devolver uma carta da oferta anterior; com `raridade_bonus` 1, a troca mantém o bônus.
- [x] AC-BN-13: pool 1 e 1 troca → aceita; a carta sai com raridade re-sorteada.
- [x] AC-BN-14: bônus 1 → Comum vira Rara, Rara vira Épica, Épica continua; u 0,59 com bônus 1 dá Rara.

---

## Implementation Notes

- `raridade_bonus` é 0 no MVP (reservado, Provação), mas a lógica e o teto em Épica são implementados e testados.
- Emite `oferta_trocada` (evento da story 006).

---

## Out of Scope

- Story 006: precedência troca × escolha no mesmo passo (contrato com a Tela)

---

## Files

- `src/gameplay/bencaos/sorteio_de_oferta.gd`
- `src/gameplay/bencaos/bencaos.gd`
- `tests/unit/bencaos/troca_e_bonus_test.gd`

Código atual da fatia: nenhum (a fatia não tem troca).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/bencaos/troca_e_bonus_test.gd` — must exist and pass
**Status**: [x] Created and passing (2026-11-17)

---

## Dependencies

- Depends on: `production/epics/bencaos-tradicoes/story-003-sorteio-da-oferta.md`
- Unlocks: `production/epics/bencaos-tradicoes/story-006-escolha-aplicar-e-eventos.md`

## Completion Notes

2026-11-17. `Bencaos.trocar()` (em `src/gameplay/bencaos/bencaos.gd`) e `SorteioDeOferta.aplicar_bonus()`; eventos `ev_oferta_trocada.gd` (e `ev_oferta_aberta.gd`). Trocas = `trocas_iniciais` + `inteiro(trocas_oferta)` − gastas na run. Teste `tests/unit/bencaos/troca_e_bonus_test.gd` — 7 casos, 7 passaram. `raridade_bonus` usa a parte inteira do float do tuning (0–1).
