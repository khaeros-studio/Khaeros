# Story 003: Sorteio da oferta — F7, raridade e consumo fixo de 6 reais

> **Epic**: Bênçãos e Tradições
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/bencaos-tradicoes.md` (R3, R4, R13-P, F5)
**Requirement**: `TR-bencaos-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: RNG determinístico
**ADR Decision Summary**: A Bênçãos é autorizada só nos fluxos 5 `bencaos` e 6 `raridade`, com chave (região, índice da câmara); k distintos de n pelo F7 (Fisher–Yates parcial, min(k,n) avanços); finalidades 1–6 mantêm quantidade e ordem fixas de sorteios.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: Proibido `randf`/`randi`/`shuffle` (lint de CI do ADR-0005).

**Control Manifest Rules (Feature)**:
- Required: listas de opções na ordem do manifesto
- Forbidden: RNG da engine em lógica

---

## Acceptance Criteria

*From GDD `design/gdd/bencaos-tradicoes.md`, scoped to this story:*

- [x] AC-BN-02: pool 18 → 3 cartas; pool 2 → 2 cartas; pool 0 → nenhuma carta e `sem_bencao`.
- [x] AC-BN-03: u = (0,5; 0; 0,99), n = 18 → índices 9, 1, 17; n = 2, u = (0,5; 0,99; x) → índices 1, 0; a oferta consome sempre 6 reais (3 `bencaos` + 3 `raridade`), inclusive com pool 2 e 0.
- [x] AC-BN-05: u 0,5999 → Comum; 0,6 → Rara; 0,8999 → Rara; 0,9 → Épica; carta i usa o real i; reais de cartas inexistentes descartados.
- [x] AC-BN-06 / AC-BN-07: mesma seed + mesmas escolhas e trocas → mesma oferta; o estado do fluxo depois da oferta não depende das escolhas anteriores; `pedir_oferta(limiar, i)` usa a chave do índice. **Nota (R13-P prevalece sobre o texto antigo do AC-BN-07):** as câmaras com oferta no Limiar são 0, 1, 2, 4 e 5.

---

## Implementation Notes

*Derived from ADR-0005:*

- F7 com k' = min(3, n); depois descartar 3 − k' reais do fluxo `bencaos` (extensão de consumo fixo). Com n = 0 o F7 do RNG não consome: o descarte de 3 garante o fixo.
- `raridade` consome sempre 3 reais; limites estritos `u < 0,6`, `u < 0,9` a partir da `RarityTable`.

---

## Out of Scope

- Story 004: troca e `raridade_bonus`
- Story 010: verificação estatística (F1/F3)

---

## Files

- `src/gameplay/bencaos/sorteio_de_oferta.gd`
- `tests/unit/bencaos/sorteio_da_oferta_test.gd`

Código atual da fatia: `_rng_state`/`_imul`/`_integer` de `game_session.gd` **não** são reaproveitados; usar o RNG do épico rng.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/bencaos/sorteio_da_oferta_test.gd` — must exist and pass
**Status**: [x] Created and passing (2026-11-17)

---

## Dependencies

- Depends on: `production/epics/bencaos-tradicoes/story-002-registro-de-tomadas.md`; `production/epics/rng/EPIC.md` (fluxos por chave e F7 — story a criar)
- Unlocks: `production/epics/bencaos-tradicoes/story-004-troca-e-raridade-bonus.md`, `production/epics/bencaos-tradicoes/story-005-contrato-pedir-oferta.md`, `production/epics/bencaos-tradicoes/story-010-estatistica-da-oferta.md`

## Completion Notes

2026-11-17. Criados `src/gameplay/bencaos/sorteio_de_oferta.gd` e `carta_da_oferta.gd`. F7 do `FluxoRng` com k' = min(tamanho_oferta, n) + descarte até 3; raridade sempre 3 reais, carta i usa real i. Teste `tests/unit/bencaos/sorteio_da_oferta_test.gd` — 7 casos, 7 passaram (F5 9/1/17 e 1/0 com dublê `FluxoRoteirizado` que injeta u32 nas operações reais; determinismo e isolamento de chaves com `FonteDeFluxos` real).
- Decisão técnica: os pesos viram inteiros (resolução 1e-6, arredondamento do Modificadores) antes de acumular, porque 0,6+0,3 em float dá 0,8999… e 0,6/0,9999… > 0,6 quebrava o AC-BN-05.
