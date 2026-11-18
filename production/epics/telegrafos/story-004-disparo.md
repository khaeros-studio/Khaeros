# Story 004: Disparo resolvido no mesmo passo

> **Epic**: Telégrafos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/telegrafos.md` (R4, R6, F6)
**Requirement**: `TR-telegrafos-004`

**ADR Governing Implementation**: ADR-0014: Telégrafos: geometria e teto (Decisão 3); ADR-0010: Resolução do combate no passo
**ADR Decision Summary**: A IA lê `disparou_neste_passo(id)` e executa o golpe no mesmo item 7 (sem contador paralelo). `ferir_jogador` respeita invulnerabilidade (Combate R13); a faixa chama `disparar_projetil` uma vez na mira travada.
**ADR Version**: ADR-0014 2026-11-16 · ADR-0010 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: disparo no mesmo passo; `ferir_*` no máximo uma vez por golpe
- Forbidden: IA contar o preparo
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-TG-10 — no passo do disparo `disparar_projetil` é chamado uma vez na mira travada, jogador dentro ou fora
- [x] AC-TG-14 — jogador invulnerável no setor: sem perda de Vida; o telégrafo dispara igual
- [x] AC-TG-17 — dois Ecos acertam no mesmo passo: Vida de um golpe só
- [x] AC-TG-18 — folgas: Eco 11, Anomalia 21, Fenda 27 passos (reação 15)

---

## Implementation Notes

- Teste com IA dublê que consulta `disparou_neste_passo` e `dentro`; o golpe real é do épico IA (story-002/003).

---

## Out of Scope

- story-005: alvo travado (Maldição/acuada)

---

## Files

- src/gameplay/telegrafos/telegrafos.gd
- tests/unit/telegrafos/telegrafos_disparo_test.gd

Fatia: `_enemy_fire` em `game_session.gd` — substituído junto com a IA.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/telegrafos/telegrafos_disparo_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/telegrafos/story-003-forma-e-testes-de-acerto.md`; épico `production/epics/combate-nucleo/` (`ferir_jogador`, `disparar_projetil`)
- Unlocks: `production/epics/telegrafos/story-005-alvo-travado.md`
