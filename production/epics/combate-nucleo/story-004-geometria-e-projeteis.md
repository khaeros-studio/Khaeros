# Story 004: GeometriaDeAcerto (arco, círculo, leque) e projéteis

> **Epic**: Combate núcleo
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/combate-nucleo.md` (R4–R7, F4, F5; AC l.2318–2462)
**Requirement**: `TR-combate-nucleo-005`, `TR-combate-nucleo-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: Resolução do combate no passo; ADR-0014: Telégrafos: geometria e teto
**ADR Decision Summary**: Uma única `GeometriaDeAcerto` (módulo `static`, sem estado) testa arco, círculo e leque e é reusada pelos Telégrafos (forma = teste); projéteis numa lista própria com ordem fixa de teste por passo e `disparar_projetil` para a IA.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: LOW
**Engine Notes**: Nenhuma API de física (ADR-0010 consultou `modules/physics.md` só para confirmar isso).

**Control Manifest Rules (this layer)**:
- Required: `GeometriaDeAcerto` para todo teste de acerto; alvo é círculo, toque inclusivo da borda; `≤`/`<` da F4
- Forbidden: remover projétil por troca com o último
- Guardrail: testes de acerto sem raiz quadrada; sem alocação no caminho quente além dos eventos

---

## Acceptance Criteria

- [x] AC-20 [L] R3.2/R6 — o projétil leva o M do disparo (l.2318)
- [x] AC-23 [L] R4/F4 — teste do arco (l.2351)
- [x] AC-24 [L] R4 — vários alvos, um hitstop (l.2370)
- [x] AC-25 [L] R4 — passo de apoio depois do teste (l.2376)
- [x] AC-26 [L] R5/F4 — círculo (l.2381)
- [x] AC-27 [L] R6/F5 — nascimento e leque (l.2396)
- [x] AC-28 [L] R7/F5 — alcance testado (l.2407)
- [x] AC-29 [L] R7/Edge — o projétil some (l.2413)
- [x] AC-30 [L] R7/R9 — atravessa e surgindo (l.2425)
- [x] AC-31 [L] R6/F3 — empurrão do dado e finalizador no projétil (l.2432)
- [x] AC-32 [L] R7 — projétil inimigo (l.2440)
- [x] AC-93 [L] R7 — `disparar_projetil` (l.2450)

---

## Implementation Notes

*Derived from ADR-0010 and ADR-0014:*

- `GeometriaDeAcerto` é `static`, sem estado; comparações por distância ao quadrado; borda inclusiva conforme a F4. Os Telégrafos chamam a mesma função (via `FormaDeTelegrafo`), nunca conta de forma própria.
- Projéteis: array pré-alocado, remoção que preserva ordem; testados em ordem fixa no passo.
- **Código da fatia**: a estocada e os testes de distância de `src/gameplay/game_session.gd` — **substituir**.

---

## Out of Scope

- Story 006: o dano aplicado por cada acerto (`ferir_inimigo`)
- Story 009: projétil com alvo Maldição/acuada (AC-106, AC-116)

---

## Files

- `src/gameplay/combate/geometria_de_acerto.gd`
- `src/gameplay/combate/projeteis.gd`
- `tests/unit/combat/geometria_de_acerto_test.gd`, `tests/unit/combat/projeteis_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/combat/geometria_de_acerto_test.gd` e `tests/unit/combat/projeteis_test.gd` — must exist and pass

**Status**: [x] Complete (`tests/unit/combat/geometria_de_acerto_test.gd`, `tests/unit/combat/projeteis_test.gd`, `production/qa/evidence/combate-nucleo-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/combate-nucleo/story-003-disparo-do-golpe-e-combo.md`
- Unlocks: `production/epics/combate-nucleo/story-006-dano-no-inimigo-e-empurrao.md`, `production/epics/telegrafos/EPIC.md`, `production/epics/ia-de-inimigos-e-elites/EPIC.md`
