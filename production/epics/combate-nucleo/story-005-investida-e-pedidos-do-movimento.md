# Story 005: Investida e pedidos síncronos do Movimento

> **Epic**: Combate núcleo
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/combate-nucleo.md` (R6, R18, F6; AC l.2458–2504, l.2834–2918)
**Requirement**: `TR-combate-nucleo-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: Resolução do combate no passo; ADR-0008: Movimento e colisão própria
**ADR Decision Summary**: O Movimento é o único escritor da posição; o Combate atende os pedidos síncronos `cancelar`, `garantir_invulneravel`, `aplicar_corte` e `esquiva_iniciada`; o Corte pesado não pede hitstop.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: LOW
**Engine Notes**: Colisão própria, sem `CharacterBody2D` (ADR-0008); nenhuma API pós-corte além de `@abstract`.

**Control Manifest Rules (this layer)**:
- Required: ordem da largada `cancelar` → `garantir_invulneravel(D+E)` → `esquiva_iniciada`
- Required: invulnerabilidade é contador por jogador em `RecursosDoJogador`, só o Combate escreve, todo pedido usa `max`
- Forbidden: o Combate escrever a posição física do jogador

---

## Acceptance Criteria

- [x] AC-94 [L] R6/Modificadores R12 — o M da investida é do disparo (l.2458)
- [x] AC-33 [L] R6/F6 — deslocamento e invulnerabilidade (l.2463)
- [x] AC-34 [L] R6/F6 — alvos a partir do passo seguinte, um acerto por alvo (l.2474)
- [x] AC-35 [L] Edge — a esquiva cancela a investida (l.2485)
- [x] AC-36 [L] Edge — investida contra a parede (l.2494)
- [x] AC-58 [L] contrato, com dublê (l.2834)
- [x] AC-59 [I] contrato com o Movimento real (l.2845)
- [x] AC-84 [L] R18 — `cancelar` e `garantir_invulneravel` (l.2859)
- [x] AC-85 [L] R18 — `aplicar_corte` (l.2873)
- [x] AC-86 [L] R18 — `esquiva_iniciada` (l.2888)

---

## Implementation Notes

*Derived from ADR-0010 and ADR-0008:*

- A investida pede deslocamento ao Movimento (`deslocar`, sem repetir Corte/contadores); o Combate guarda a investida ativa e a expõe ao Selo (TR-selo-004, story `selo-e-fluxo/story-003`).
- Corte da esquiva: `aplicar_corte` síncrono, sem hitstop.
- **Código da fatia**: `src/gameplay/movement.gd` — **adaptar** no épico `movimento-e-esquiva`; aqui só o lado do Combate. Corte na esquiva de `game_session.gd` — **substituir**.

---

## Out of Scope

- Épico `movimento-e-esquiva`: a esquiva, o Corte e a colisão em si

---

## Files

- `src/gameplay/combate/combate.gd` (investida, pedidos do Movimento)
- `tests/unit/combat/investida_test.gd`, `tests/unit/combat/pedidos_do_movimento_test.gd`
- `tests/integration/combat/contrato_movimento_test.gd` (AC-59)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/combat/contrato_movimento_test.gd` + unit tests above — must exist and pass

**Status**: [x] Complete (`tests/unit/combat/investida_e_movimento_test.gd`, `production/qa/evidence/combate-nucleo-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/combate-nucleo/story-003-disparo-do-golpe-e-combo.md`, `production/epics/combate-nucleo/story-004-geometria-e-projeteis.md`, `production/epics/movimento-e-esquiva/EPIC.md`
- Unlocks: `production/epics/selo-e-fluxo/story-003-plantar-o-selo.md`
