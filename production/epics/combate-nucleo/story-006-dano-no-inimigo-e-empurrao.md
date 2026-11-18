# Story 006: ferir_inimigo, empurrão e impacto na parede

> **Epic**: Combate núcleo
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/combate-nucleo.md` (R8, R8.4–R8.7, R9, R11, F1, F3, F7, F8; AC l.2505–2607, l.2657–2701)
**Requirement**: `TR-combate-nucleo-007`, `TR-combate-nucleo-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: Resolução do combate no passo; ADR-0009: Atributos e modificadores; ADR-0008: Movimento e colisão própria
**ADR Decision Summary**: `ferir_inimigo` com dano float, contador de acertos e caminho silencioso para Status e Selo; empurrão e impacto na parede resolvidos com a colisão própria contra paredes e obstáculos.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: LOW
**Engine Notes**: ADR-0010 Verification (1): testar `arredondar_meio_longe_do_zero` no meio exato; não usar `round()`/`roundi()`.

**Control Manifest Rules (this layer)**:
- Required: Vida do inimigo em `float`; `status.aplicar_status` síncrono no impacto
- Forbidden: `_ferir_inimigo` pedir hitstop
- Required: colisão própria (`resolver_colisao`, função pura); contato exato não empurra

---

## Acceptance Criteria

- [x] AC-37 [L] R8/F1 — dano, contador do portador e `enesimo_acerto` (l.2505)
- [x] AC-38 [L] R8/F3 — finalizador, pesado e fator do alvo (l.2522)
- [x] AC-39 [L] R8.6/F7 — empurrões se somam (l.2535)
- [x] AC-40 [L] R8 — dano 0, excesso e Corte da esquiva (l.2542)
- [x] AC-41 [L] R8.7/R12 — cambaleio (l.2558)
- [x] AC-42 [L] R8.7 — "Quebrou!" (l.2566)
- [x] AC-43 [L] R9 — atingível (l.2577)
- [x] AC-44 [L] R14/R12 — morto não age (l.2582)
- [x] AC-89 [L] R4/R8.4 — hitstop do golpe × pesado do impacto (l.2588)
- [x] AC-90 [L] R8 — dano de status (`de_status`) (l.2598)
- [x] AC-45 [L] R11/F7 — percurso do empurrão (l.2657)
- [x] AC-46 [L] R11/F8 — impacto na parede (l.2672)
- [x] AC-47 [L] R11/Edge — canto, obstáculo e separação (l.2691)

---

## Implementation Notes

*Derived from ADR-0010, ADR-0009 and ADR-0008:*

- F1/F3 em float; o caminho silencioso (`de_status`, dano do Selo) não conta acerto de arma nem emite número.
- Empurrão: soma no passo, percurso por passos (F7) com `resolver_colisao`; impacto na parede (F8) é dano extra sem hitstop de `_ferir_inimigo`.
- **Código da fatia**: `_hurt_enemy` de `src/gameplay/game_session.gd` — **substituir** (referência de números apenas).

---

## Out of Scope

- Story 007: dano no jogador e varredura de mortes
- Story 008: forma dos eventos emitidos

---

## Files

- `src/gameplay/combate/combate.gd` (`ferir_inimigo`, empurrão)
- `src/gameplay/combate/formulas_de_combate.gd`
- `tests/unit/combat/ferir_inimigo_test.gd`, `tests/unit/combat/empurrao_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/combat/ferir_inimigo_test.gd` e `tests/unit/combat/empurrao_test.gd` — must exist and pass

**Status**: [x] Complete (`tests/unit/combat/ferir_inimigo_e_empurrao_test.gd`, `production/qa/evidence/combate-nucleo-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/combate-nucleo/story-004-geometria-e-projeteis.md`, `production/epics/movimento-e-esquiva/EPIC.md` (colisão própria), `production/epics/modificadores/EPIC.md`
- Unlocks: `production/epics/combate-nucleo/story-007-dano-no-jogador-e-varredura.md`, `production/epics/selo-e-fluxo/story-004-dano-do-selo.md`, `production/epics/efeitos-de-status/EPIC.md`
