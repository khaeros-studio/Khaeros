# Story 001: WaveRules, RoomTuning e RegionDef no catálogo (WV1–WV11)

> **Epic**: Câmaras e ondas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/camaras-e-ondas.md` (R2, R15, "Faixas do WaveRules e do RoomTuning", "Validação do WaveRules, RoomTuning e da RegionDef")
**Requirement**: `TR-camaras-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Catálogo de dados
**ADR Decision Summary**: `WaveRules`, `RoomTuning` e `RegionDef` são `.tres` do manifesto, validados na carga (WV1–WV9; WV10/WV11 na emenda Pactos); erro bloqueia a run, aviso vai ao relatório.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM (ADR-0004)
**Engine Notes**: Resource `.tres`; `duplicate_deep` conforme ADR-0004.

**Control Manifest Rules (Feature)**:
- Required: tuning do catálogo validado; posse — `p_max` é das Câmaras
- Forbidden: números de gameplay hardcoded

---

## Acceptance Criteria

*From GDD `design/gdd/camaras-e-ondas.md`, scoped to this story:*

- [x] AC-CO-22: câmara 1920×1080 e 2880×1620 aceitas; 1900×1080 e 2881×1620 → erro WV2.
- [x] AC-CO-23: `orcamento_base` ≤ 0, `max_inimigos_onda` < 1, `spawn_candidatos` < 1, `ondas_limites` não crescente, entrada dentro de pedra fixa ou pool sem inimigo ≤ `orcamento_base` → erros WV1, WV3, WV4.
- [x] AC-CO-24: catálogo de fábrica sem avisos WV5–WV9; `max_inimigos_onda` 5 → WV5; `spawn_dist_jogador_px` 600 → WV6; `obstaculo_raio_min_px` 150 → WV7; `ArmasTuning.p_max` 5 → WV8; `orcamento_base` 6 → WV9.
- [x] AC-CO-42: `spawn_dist_acuada_px` 400 → aviso WV10; `RegionDef` com `chefe` no índice 4 → erro WV11 e a run não começa; fábrica sem WV10/WV11.

---

## Implementation Notes

- WV8 cruza com `ArmasTuning.p_max`: a validação roda depois da carga de todo o catálogo (validadores cruzados do ADR-0004).

---

## Out of Scope

- Stories 003–005: uso dos valores

---

## Files

- `src/content/wave_rules.gd`, `src/content/room_tuning.gd`, `src/content/region_def.gd`
- validadores WV1–WV11 em `src/content/`
- `.tres` de fábrica (Limiar)
- `tests/unit/camaras/tuning_e_validacao_test.gd`

Código atual da fatia: as ondas e o tamanho da arena em `data/integration/gameplay.json` lidos por `session_catalog.gd` são **substituídos** por estes recursos.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/camaras/tuning_e_validacao_test.gd` — must exist and pass
**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/conteudo/EPIC.md` (manifesto e validação — story a criar)
- Unlocks: `production/epics/camaras-e-ondas/story-002-profundidade-e-sequencia.md`, `production/epics/camaras-e-ondas/story-003-layout-de-pedras.md`, `production/epics/camaras-e-ondas/story-004-composicao-das-ondas.md`
