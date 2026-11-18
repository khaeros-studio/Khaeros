# Story 003: Disparo do golpe, combo por slot, guarda e recuperação

> **Epic**: Combate núcleo
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/combate-nucleo.md` (R2, R3, R3.1–R3.7, F2; AC l.2259–2350, l.3330)
**Requirement**: `TR-combate-nucleo-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: Resolução do combate no passo; ADR-0006: Input por passo; ADR-0009: Atributos e modificadores
**ADR Decision Summary**: Descontos do item 3 antes do Movimento; disparo do item 5 com Especial primeiro, combo por slot e no máximo um golpe por passo; o M é lido no disparo.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: LOW
**Engine Notes**: ADR-0010: aritmética pura; `@abstract` (4.5) nas bases de contratos. Input (ADR-0006, HIGH) é consumido como amostra injetada — nenhum `Input` do Godot aqui.

**Control Manifest Rules (this layer)**:
- Required: tudo em `float` até o fim de F2, arredondar só pela função própria
- Forbidden: `round()`/`roundi()`, `int()` intermediário
- Forbidden: campo singular "o jogador" — recursos por `player_id`

---

## Acceptance Criteria

- [x] AC-12 [L] R3 — sai no passo do toque (l.2259)
- [x] AC-13 [L] R3/Edge — Especial primeiro (l.2267)
- [x] AC-14 [L] R3/Edge — esquiva e investida bloqueiam (l.2272)
- [x] AC-15 [L] R3/Edge — golpe sem alvo e câmara limpa (l.2281)
- [x] AC-16 [L] R2/R3.1 — combo e janela (l.2291)
- [x] AC-17 [L] R3.1 — combo por slot (l.2297)
- [x] AC-18 [L] R3.2 — M no disparo; a janela `apos_esquiva` fecha (l.2306)
- [x] AC-19 [L] Edge — golpe no último passo da esquiva, com bônus (l.2313)
- [x] AC-21 [L] R3.5 — guarda (l.2324)
- [x] AC-22 [L] R3.7/F2 — recuperação (l.2332)
- [x] AC-112 [L] R3.1 — forma `chamado` (l.3330)

---

## Implementation Notes

*Derived from ADR-0010:*

- Item 3: descontos (recuperação, janela de combo, janela pós-esquiva) antes do Movimento (item 4).
- Item 5: Especial antes do Ataque; combo indexado por slot; um golpe por passo; o `AttackDef` do slot vem injetado (story de Armas), nunca regra própria de arma.
- Consome só a amostra do Input por passo (`selo`/`ataque`/`especial` do buffer de 10 passos), nunca `Input` do Godot.
- **Código da fatia**: ataque, combo e golpe pesado de `src/gameplay/game_session.gd` — **substituir**; usar só como referência de sensação. `src/foundation/game_input.gd` fica com o épico `input`.

---

## Out of Scope

- Story 004: teste de acerto e projéteis (inclui AC-20)
- Story 005: investida

---

## Files

- `src/gameplay/combate/combate.gd` (itens 3 e 5)
- `src/gameplay/combate/estado_de_golpe.gd`
- `tests/unit/combat/disparo_do_golpe_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/combat/disparo_do_golpe_test.gd` — must exist and pass

**Status**: [x] Complete (`src/gameplay/combate/combate.gd`, `tests/unit/combat/disparo_do_golpe_test.gd`, `production/qa/evidence/combate-nucleo-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/combate-nucleo/story-002-passo-vivo-e-hitstop.md`, `production/epics/input/EPIC.md`, `production/epics/modificadores/EPIC.md`
- Unlocks: `production/epics/combate-nucleo/story-004-geometria-e-projeteis.md`, `production/epics/combate-nucleo/story-005-investida-e-pedidos-do-movimento.md`
