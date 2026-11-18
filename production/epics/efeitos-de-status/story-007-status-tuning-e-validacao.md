# Story 007: StatusTuning no catálogo e validação ST1–ST11

> **Epic**: Efeitos de status
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/efeitos-de-status.md` (R9, Formulas: Faixas e Validação do `StatusTuning`)
**Requirement**: `TR-status-011`

**ADR Governing Implementation**: ADR-0004: Catálogo de dados
**ADR Decision Summary**: Catálogo `.tres` com manifesto explícito e validadores; erro impede a run; avisos informativos; durações em segundos convertidas em passos na carga; cópia por `duplicate_deep`.
**ADR Version**: ADR-0004 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM (ADR-0004: `Resource`/`duplicate_deep` no 4.7)
**Engine Notes**: conferir `duplicate_deep` em `docs/engine-reference/godot/` antes de usar.

**Control Manifest Rules (this layer)**:
- Required: todo número de jogo do catálogo validado
- Forbidden: literais de tuning no código
- Guardrail: validação só na carga

---

## Acceptance Criteria

- [x] AC-ST-21 — duração < 1 passo, taxa < 0, `max_acumulos_queimadura` < 1 ou `reducao_dano_causado` fora de [0,1): erro ST1–ST4, run não começa
- [x] AC-ST-22 — catálogo de fábrica: só o ST9 informativo (Eco 75, Anomalia 60, Fenda 115; Anomalia 50 Queimadura); `max_acumulos_sangramento` 0 dispara ST5; soma Sangramento+Queimadura com M=4 não dispara ST5
- [x] AC-ST-26 — `intervalo_numero_s` < 1 passo: ST6; > min(durações): ST10; campo fora da faixa: ST11

---

## Implementation Notes

- ST5 e ST7–ST9 rodam no host do MV1 (Movimento OQ3), como diz o AC-ST-22.
- Os valores de fábrica entram no `.tres` do catálogo (entrega 1 do épico assets-e-conteudo).

---

## Out of Scope

- Infra do catálogo e do validador (épico conteudo)

---

## Files

- src/foundation/catalogo/status_tuning.gd
- src/foundation/catalogo/validadores/validador_status.gd
- assets/data/status_tuning.tres
- tests/integration/status/status_tuning_validacao_test.gd

Fatia: `session_catalog.gd` (JSON) não tem `StatusTuning`; o novo recurso nasce no catálogo `.tres`, sem adaptar o JSON.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/unit/status/status_numero_consulta_e_tuning_test.gd`

**Status**: [x] Created and passing (2026-11-18)

---

## Dependencies

- Depends on: épico `production/epics/conteudo/` (catálogo e manifesto, validadores V1–V11); épico `production/epics/movimento-e-esquiva/` (host do MV1)
- Unlocks: `production/epics/efeitos-de-status/story-001-modelo-e-aplicar.md` em produção (os testes usam dublê)
