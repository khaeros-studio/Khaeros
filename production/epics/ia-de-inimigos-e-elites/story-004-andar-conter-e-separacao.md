# Story 004: Andar com Selo e cambaleio, conter e separação par a par

> **Epic**: IA de inimigos e elites
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/ia-de-inimigos-e-elites.md` (R9, R12)
**Requirement**: `TR-ia-006`, `TR-ia-012`

**ADR Governing Implementation**: ADR-0018 (§3 velocidade, §6 separação); ADR-0008: Movimento e colisão própria; ADR-0010
**ADR Decision Summary**: Velocidade = `velocidade × lentidão do Selo (no_selo do item 6) × cambaleio × fator de atração`; avanço ignora os três. Conter por `resolver_colisao` do ADR-0008. `fim_do_item_7()`: um passe `i < j` em ordem de id, metade da sobreposição para cada, normal `(0, −1)` com centros iguais, depois `conter` em ordem de id; fora: Maldição, acuada, `SURGINDO`, `SUBJUGADO`.
**ADR Version**: ADR-0018 2026-11-16 · ADR-0008 2026-11-16 · ADR-0010 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: Movimento é o único escritor da posição do jogador; a da IA é dela
- Forbidden: `CharacterBody2D`, física da engine
- Guardrail: separação um passe só, sem iteração

---

## Acceptance Criteria

- [x] AC-IA-12 — Eco 2,55 px/passo; Selo 76,5 px/s; cambaleando 61,2; os dois 30,6; avanço 7,56 nos quatro
- [x] AC-IA-13 — dois Ecos a 20 px: 14 px cada em sentidos opostos; elite raio 28,8
- [x] AC-IA-14 — corpo dentro de obstáculo ou além da parede volta ao limite no mesmo passo

---

## Implementation Notes

- `no_selo`/cambaleio lidos por consulta injetada (Selo, Combate); nada é escrito neles.

---

## Out of Scope

- story-007: Maldição fora da separação e `conter` exposto

---

## Files

- src/gameplay/ia/modulo_de_ia.gd
- tests/unit/ia/ia_andar_e_separacao_test.gd

Fatia: `movement.gd` tem colisão do jogador; a separação de inimigos da fatia (se houver em `game_session.gd`) é substituída. Reaproveitar só a lógica de `resolver_colisao` que o épico movimento-e-esquiva extrair.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ia/ia_andar_e_separacao_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/ia-de-inimigos-e-elites/story-002-fases-surgimento-e-melee.md`; épico `production/epics/movimento-e-esquiva/` (`resolver_colisao`)
- Unlocks: `production/epics/ia-de-inimigos-e-elites/story-007-imobilizar-puxar-e-conter.md`
