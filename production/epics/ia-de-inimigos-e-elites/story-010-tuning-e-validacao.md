# Story 010: IATuning, EnemyDef e EliteRules — validação IV1–IV9 e teto de dano

> **Epic**: IA de inimigos e elites
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/ia-de-inimigos-e-elites.md` (R12, R14, F5, Faixas e Validação)
**Requirement**: `TR-ia-014`

**ADR Governing Implementation**: ADR-0004: Catálogo de dados; ADR-0018 (Implementation Guidelines: nenhum literal)
**ADR Decision Summary**: Todo número da IA vem de `IATuning`, `EnemyDef`, `EliteRules`, `ChefesTuning` e `BossPatternDef` já convertidos para passos e px na carga; erros IV1–IV4 impedem a run; avisos IV5–IV9.
**ADR Version**: ADR-0004 2026-11-16 · ADR-0018 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM (ADR-0004)

**Control Manifest Rules (this layer)**:
- Required: catálogo validado
- Forbidden: literal de jogo no código
- Guardrail: validação só na carga

---

## Acceptance Criteria

- [x] AC-IA-23 — Lâmina: 7 golpes da Fenda elite, `t_min_morrer` 240; Ressonância 5 e 160; `alvo_dano_camera` fora de 0,10–0,50: IV7
- [x] AC-IA-24 — passos < 1, `ranged_perto_px` ≥ `ranged_longe_px`, `charger_reaproxima_px` ≥ `charger_engaja_px`, fator fora de [0,1], comportamento desconhecido: IV1–IV4, run não começa
- [x] AC-IA-25 — fábrica sem IV5–IV9
- [x] AC-IA-29 — velocidade 280: IV5; `avanco_passos` 20 com N 26: IV6; Vida 40 / dano 16: IV7; margem 250: IV8; fora da faixa: IV9

---

## Implementation Notes

- IV6 lê o N do `TelegraphTuning` (fonte única).

---

## Out of Scope

- Infra do validador (épico conteudo)

---

## Files

- src/foundation/catalogo/ia_tuning.gd
- src/foundation/catalogo/elite_rules.gd
- src/foundation/catalogo/validadores/validador_ia.gd
- tests/integration/ia/ia_tuning_validacao_test.gd

Fatia: `session_catalog.gd` (JSON com os dois inimigos) — os valores migram para `.tres` no épico assets-e-conteudo; este validador roda sobre o `.tres`.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/ia/ia_tuning_validacao_test.gd`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: épico `production/epics/conteudo/`; `production/epics/telegrafos/story-009-tuning-e-validacao.md` (N para IV6)
- Unlocks: None
