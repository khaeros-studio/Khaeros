# Story 005: Fontes de status (golpes, Corte, Selo) e Maldições

> **Epic**: Efeitos de status
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/efeitos-de-status.md` (R1a, R3, R3a)
**Requirement**: `TR-status-013` (e as chamadas de `TR-status-002` pelas fontes)

**ADR Governing Implementation**: ADR-0010: Resolução do combate no passo; ADR-0017: Aliados e invocações
**ADR Decision Summary**: O Combate chama `aplicar_status` no impacto (item 8 da R8), inclusive no Corte; o golpe de Maldição (item 6.1) aplica Abalo pelo impacto do Combate e nunca dispara `golpe_*` de bênção (`de_arma` falso). Maldições não carregam status (filtro de facção). Saída antes de Entrada no mesmo passo.
**ADR Version**: ADR-0010 2026-11-16 · ADR-0017 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH (ADR-0010)
**Engine Notes**: sem API pós-cutoff no Status; o risco é de ordem do passo.

**Control Manifest Rules (this layer)**:
- Required: chamada síncrona de `aplicar_status` no impacto
- Forbidden: Status testar facção por geometria própria (filtro é do Combate)
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-ST-17 — `golpe_sangramento` 1 em 3 alvos: A=1 em cada; Corte aplica 1 de Sangramento por alvo; Selo aplica Abalo
- [x] AC-ST-18 — `golpe_*` e `status` do `AttackDef` no mesmo golpe: ordem não muda A nem `restante`
- [x] AC-ST-27 — Cratera de Cinza / Rastro Cortante: Abalo 240 a partir do item 6.1; Eco de Muralha: 90 **[a confirmar no GDD — implementar com o valor do catálogo, não literal]**
- [x] AC-ST-28 — golpe de Maldição não aciona `golpe_sangramento`/`golpe_queimadura`
- [x] AC-ST-29 — nenhuma chamada de R2 tem Maldição como alvo; `estado()` não existe para ela
- [x] AC-ST-30 — troca Baluarte → Espreitador: `abalado` já verdadeiro quando a Entrada consulta no mesmo passo

---

## Implementation Notes

- Status não sabe a origem; os testes usam dublês de Combate/Selo/Maldições chamando `aplicar_status` na ordem real.
- AC-ST-27 tem valor marcado "[a confirmar]" no GDD: a story não bloqueia, porque o número vem do catálogo.

---

## Out of Scope

- Lógica do Selo (épico selo-e-fluxo) e das Maldições (épico maldicoes)

---

## Files

- src/gameplay/status/modulo_de_status.gd
- tests/integration/status/status_fontes_test.gd

Fatia: nada a reaproveitar.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/unit/status/status_abalo_e_fontes_test.gd`

**Status**: [x] Created and passing (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/efeitos-de-status/story-004-abalo.md`; épicos `production/epics/combate-nucleo/`, `production/epics/selo-e-fluxo/`, `production/epics/maldicoes/` (dublês bastam para o teste)
- Unlocks: None
