# Story 007: ferir_jogador e varredura de mortes

> **Epic**: Combate núcleo
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/combate-nucleo.md` (R13, R13.1–R13.7, R14, F10; AC l.2702–2833)
**Requirement**: `TR-combate-nucleo-008`, `TR-combate-nucleo-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: Resolução do combate no passo; ADR-0009: Atributos e modificadores; ADR-0003: Entidades e portadores
**ADR Decision Summary**: `ferir_jogador` com dano inteiro e um único arredondamento; recursos do jogador no Combate por `player_id`; "em combate" é consulta das Câmaras; varredura de mortes com retrato por passe (até 4), morto não age, morte do jogador para os passos seguintes.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: LOW
**Engine Notes**: ADR-0010 Verification (1): exemplos da F10 no meio exato com `arredondar_meio_longe_do_zero`.

**Control Manifest Rules (this layer)**:
- Required: Vida do jogador em `int`, um único arredondamento
- Required: `pedir_estado(MORTE)` só no fim do item 9
- Forbidden: remover inimigo por troca com o último; campo singular "o jogador"

---

## Acceptance Criteria

- [x] AC-48 [L] R13/F10 — fórmula (l.2702)
- [x] AC-49 [L] R13.3–4/Edge — escudo (l.2721)
- [x] AC-50 [L] R13/F10/Edge — dois inimigos e o teto (l.2727)
- [x] AC-51 [L] R13.6 — refletir (l.2732)
- [x] AC-53 [L] R13.7 — recusa (l.2751)
- [x] AC-87 [L] R13.1 — "em combate" é consulta das Câmaras (l.2768)
- [x] AC-54 [L] R14 — abate (l.2784)
- [x] AC-55 [L] R14/Edge — o chefe zera os outros (l.2791)
- [x] AC-56 [L] R14/Edge — cadeia de mais de 4 passes (l.2799)
- [x] AC-57 [L] R14/Edge — a explosão pega o chefe (l.2810)
- [x] AC-88 [L] R14/R13.7 — morto não cura nem revive (l.2814)

---

## Implementation Notes

*Derived from ADR-0010:*

- `RecursosDoJogador` por `player_id` (0 no solo): Vida int, escudo, invulnerabilidade (contador, `max`).
- Varredura do item 9: retrato por passe, até 4 passes; mortos saem preservando ordem; `pedir_estado(MORTE)` no fim.
- **Código da fatia**: `_hurt_player` de `src/gameplay/game_session.gd` — **substituir**.

---

## Out of Scope

- Story 009: abates creditados à Maldição, lacaios do chefe e Subjugado

---

## Files

- `src/gameplay/combate/combate.gd` (`ferir_jogador`, item 9)
- `src/gameplay/combate/recursos_do_jogador.gd`
- `tests/unit/combat/ferir_jogador_test.gd`, `tests/unit/combat/varredura_de_mortes_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/combat/ferir_jogador_test.gd` e `tests/unit/combat/varredura_de_mortes_test.gd` — must exist and pass

**Status**: [x] Complete (`tests/unit/combat/ferir_jogador_e_varredura_test.gd`, `production/qa/evidence/combate-nucleo-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/combate-nucleo/story-006-dano-no-inimigo-e-empurrao.md`, `production/epics/camaras-e-ondas/EPIC.md` (consulta "em combate"; dublê até lá)
- Unlocks: `production/epics/combate-nucleo/story-008-eventos-e-contratos.md`, `production/epics/combate-nucleo/story-009-pactos-maldicao-acuada-e-chefe.md`
