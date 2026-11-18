# Story 005: Padrão 3 (Convergência) — puxão, impacto e lacaios com teto

> **Epic**: Chefes
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/chefes.md` (R5.4, R8; F3)
**Requirement**: `TR-chefes-008`, `TR-chefes-009`, `TR-chefes-017`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0018 (§8); ADR-0008: Movimento e colisão própria; ADR-0010; ADR-0014; ADR-0003
**ADR Decision Summary**: deslocamentos do chefe passam pela porta `DeslocamentosDoChefe` (`imune`, `deslocar`), ligada a `Movimento.deslocar` e ao `ModuloDeMaldicoes`; sem dano, ignorados por invulneráveis. Lacaios: `n = min(lacaios_por_convergencia, max(0, max_lacaios_vivos − vivos), max(0, max_inimigos_onda − vivos_na_lista))`, criados no fim do `passo()` do chefe, `invocado_pelo_chefe = true`, sem consumir `elites`/`spawn` (usam `ia` depois de nascer). Teto de 9 inimigos e 24 telégrafos.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: LOW
**Engine Notes**: nenhuma API pós-cutoff além de `@abstract`.

**Control Manifest Rules (this layer)**:
- Required: Movimento é o único escritor da posição do jogador (ADR-0008)
- Forbidden: lacaios consumirem `elites` ou `spawn`; o chefe consumir RNG

---

## Acceptance Criteria

*From GDD `design/gdd/chefes.md`, scoped to this story:*

- [x] **AC-CH-08** Chefe em (960, 285), jogador em (960, 565) (d 280, fora de 225, ≤ 420, sem esquiva): puxado 75 px para (960, 490) e no mesmo passo recebe 14 do círculo.
- [x] **AC-CH-09** 0 lacaios: nascem 2 `eco_perdido` (Vida 30, `invocado_pelo_chefe`, `Surgindo` 50) em (x − 135, y) e (x + 135, y); com 2 vivos, o próximo P3 invoca 1; com 3, 0.
- [x] (ADR-0018 Validation / TR-chefes-017) O teto de 9 inimigos limita a invocação; chefe + lacaios cabem no teto de 24 telégrafos.

---

## Implementation Notes

*Derived from ADR-0018 §8:*

- Ordem do P3: puxão → impacto → invocação. Posições por `ajustar_obstaculos_e_parede`, `k = 0` à esquerda.

---

## Out of Scope

- Story 008: remoção dos lacaios na queda do chefe.

---

## Files

- `src/gameplay/ia/padroes_do_chefe.gd`, `src/gameplay/ia/deslocamentos_do_chefe.gd`
- `tests/unit/chefes/chefes_padrao_3_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/chefes/chefes_padrao_3_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/chefes/story-004-padrao-2-pulso-e-radiais.md`; épico `production/epics/movimento-e-esquiva/EPIC.md` (`Movimento.deslocar`)
- Unlocks: `production/epics/chefes/story-008-queda-do-chefe-e-limpeza.md`

**Código da fatia**: `movement.gd` — **adaptar** só se o épico `movimento-e-esquiva` ainda não expuser `deslocar`; caso contrário nada.
