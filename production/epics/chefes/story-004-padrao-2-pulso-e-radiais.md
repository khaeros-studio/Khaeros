# Story 004: Padrão 2 (Pulso de Soberania) e 12 projéteis de alvo único

> **Epic**: Chefes
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/chefes.md` (R3, R5.3; F1, F2)
**Requirement**: `TR-chefes-007`, `TR-chefes-005` (forma `anel`)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: Resolução do combate no passo; ADR-0018 (§8); ADR-0014
**ADR Decision Summary**: `disparar_projetil(alvo = id)`: projétil de alvo único atravessa quem não é o alvo e some por pilar, parede ou tempo; pulso + 12 projéteis a 30° da mira travada; cada golpe só fere o alvo travado.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: HIGH
**Engine Notes**: risco herdado do ADR-0010 (ordem dos itens do passo); a story é lógica pura.

**Control Manifest Rules (this layer)**:
- Required: projéteis em estado `RefCounted` do Combate; ids inteiros (ADR-0003)
- Forbidden: corpo de física/`Area2D` por projétil

---

## Acceptance Criteria

*From GDD `design/gdd/chefes.md`, scoped to this story:*

- [x] **AC-CH-07** Fim dos 36 de preparo do P2: o `anel` (210 px) fere o alvo travado (jogador) a ≤ 210 px com 15 e empurrão 900 px/s; uma Maldição a ≤ 210 px não sofre dano; nascem 12 projéteis a 54 px do centro, a 30° (360 px/s, r 13,5, vida 180 passos, 12 de dano); 12 de execução + 90 de recuperação, `padrao = 3`.
- [x] **AC-CH-27** Travado no jogador, Maldição na linha de um projétil a 150 px: o projétil a atravessa sem dano e sem sumir; travado na Maldição, o jogador na linha é atravessado sem dano.

---

## Implementation Notes

*Derived from ADR-0018 §8 / ADR-0010:*

- O campo `alvo` do projétil é o id travado; o Combate só testa esse id.

---

## Out of Scope

- Story 005: Padrão 3.

---

## Files

- `src/gameplay/ia/padroes_do_chefe.gd`
- `src/gameplay/combate/` (parâmetro `alvo` em `disparar_projetil`, se o épico `combate-nucleo` ainda não o tiver)
- `tests/unit/chefes/chefes_padrao_2_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/chefes/chefes_padrao_2_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/chefes/story-003-padroes-0-e-1-e-alvo-travado.md`; épico `production/epics/combate-nucleo/EPIC.md` (projéteis)
- Unlocks: `production/epics/chefes/story-005-padrao-3-convergencia-e-lacaios.md`

**Código da fatia**: projéteis em `Dictionary` na fatia — **substituídos** pelo Combate do ADR-0010.
