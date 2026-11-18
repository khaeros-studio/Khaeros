# Story 003: Adaptador FormaDeTelegrafo e testes de acerto

> **Epic**: Telégrafos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/telegrafos.md` (R5, R6, F2–F5)
**Requirement**: `TR-telegrafos-006`, `TR-telegrafos-007`

**ADR Governing Implementation**: ADR-0014: Telégrafos: geometria e teto (Decisões 4, 5); ADR-0010: Resolução do combate no passo (§9 `GeometriaDeAcerto`); ADR-0008: Movimento e colisão própria
**ADR Decision Summary**: `FormaDeTelegrafo` (adaptador interno) monta, a partir do slot, da posição atual do dono e da tabela derivada, os parâmetros de `setor_toca`, `retangulo_orientado_toca`, `circulos_encostam` e `alcance_do_raio` do `GeometriaDeAcerto`; a mesma montagem serve a `dentro(id, ponto)` e à vista. Faixa: `comprimento = min(saida + alcance + r_acerto, alcance_do_raio(...))` pela linha central, recalculado a cada publicação.
**ADR Version**: ADR-0014 2026-11-16 · ADR-0010 2026-11-16 · ADR-0008 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW
**Engine Notes**: fronteiras 89,9/90,1; 78,40°/78,52°; 56/58 px viram teste (NOT SOURCEABLE).

**Control Manifest Rules (this layer)**:
- Required: teste de acerto e vista do mesmo `FormaDeTelegrafo`, que chama `GeometriaDeAcerto`
- Forbidden: conta de forma em IA, Combate, Pipeline ou fora do adaptador
- Guardrail: distâncias comparadas ao quadrado

---

## Acceptance Criteria

- [x] AC-TG-08 — setor do Eco: (80;20) acerta; (−10;0) não; (89,9;0) sim; (90,1;0) não; 78,40° sim; 78,52° não
- [x] AC-TG-09 (comprimento) — 1728 px livre; parede a 600 → 600; obstáculo a 400 → 400 (linha central até a superfície)
- [x] AC-TG-12 — avanço: 56 px acerta, 58 não; 2ª passagem não fere; logo atrás a 30 px acerta
- [x] AC-TG-27 — faixa: (500;30) dentro; (500;41) fora; (1730;0) fora

---

## Implementation Notes

- Convenções: setor com ápice no centro do dono; faixa com `x_min` 0; avanço com `x_min = −R_c`.
- Contato 1× por avanço é estado da IA (épico IA story-003); aqui só o teste geométrico.

---

## Out of Scope

- story-004/005: quem é ferido no disparo

---

## Files

- src/gameplay/telegrafos/forma_de_telegrafo.gd
- src/gameplay/telegrafos/telegrafos.gd (`dentro`)
- tests/unit/telegrafos/telegrafos_testes_de_acerto_test.gd

Fatia: o teste inline de `_enemy_fire` (`cos(deg_to_rad(tele_meio_angulo_graus))`) em `game_session.gd` é **substituído**.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/telegrafos/telegrafos_testes_de_acerto_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/telegrafos/story-002-derivar-formas.md`; épico `production/epics/combate-nucleo/` (`GeometriaDeAcerto`, ADR-0010 §9)
- Unlocks: `production/epics/telegrafos/story-004-disparo.md`, `story-008-publicar-vistas.md`
