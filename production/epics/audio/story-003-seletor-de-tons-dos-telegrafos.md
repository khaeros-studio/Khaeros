# Story 003: SeletorDeTons — no máximo 3 telégrafos soando, pitch por p

> **Epic**: Áudio: ganchos e vozes
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

Dentre as vistas de telégrafo em preparação, soam as 3 de maior `p` (empate: menor `seq`), cada tom preso ao `slot`; o pitch sobe linear com `p`. O estalo do disparo não é tom: é o gancho P0 `sfx_telegrafo_disparo` do Feedback.

**GDD**: `docs/architecture/adr-0016-audio-ganchos-e-vozes.md` (requisito de `design/gdd/telegrafos.md` § Visual/Audio)
**Requirement**: `TR-telegrafos-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016: Áudio: ganchos e vozes; ADR-0014: Telégrafos: geometria e teto
**ADR Decision Summary**: `pitch = tom_pitch_min + (tom_pitch_max − tom_pitch_min) · clamp(p, 0, 1)`; slot fora do top 3 para no passo, o que entra começa no passo; quebra e cancelamento param o tom; publicação `VistaDeTelegrafo` do ADR-0014 lida só por leitura.
**ADR Version**: ADR-0016 2026-11-16; ADR-0014 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: Lógica pura; `pitch_scale` (aplicação) fica na story 004 e é NOT SOURCEABLE até o EX-0016-A.

**Control Manifest Rules (this layer)**:
- Required: ≤ 3 tons em multidão; decisão em `SeletorDeTons` puro; entrega sem alocar
- Forbidden: n/a
- Guardrail: seleção top 3 sobre ≤ `teto_telegrafos` vistas, < 0,05 ms por passo

---

## Acceptance Criteria

*From ADR-0016 Validation V-3 (TR-telegrafos-014):*

- [x] 5 telégrafos em preparação com `p` distintos → os 3 maiores
- [x] Empate de `p` → menor `seq`
- [x] `p` = 0 → `tom_pitch_min`; `p` = 1 → `tom_pitch_max`
- [x] Telégrafo disparado → fora da seleção

---

## Implementation Notes

*Derived from ADR-0016 §5 and Key Interfaces:*

- `static func selecionar(vistas, quantas, teto, slots: PackedInt32Array, pitches: PackedFloat32Array, tuning) -> int`, saídas pré-alocadas.

---

## Out of Scope

- Story 004: tocar e parar as 3 vozes de tom

---

## Files

- `src/presentation/audio/seletor_de_tons.gd`
- `tests/unit/audio/seletor_de_tons_dos_telegrafos_test.gd`

Código da fatia: nenhum.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/audio/seletor_de_tons_dos_telegrafos_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/audio/seletor_de_tons_dos_telegrafos_test.gd`, `production/qa/evidence/audio-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/audio/story-001-somdef-audiotuning-e-pedidos.md`; `production/epics/telegrafos/EPIC.md` (tipo `VistaDeTelegrafo` com `slot`, `p`, `seq`, `estado`)
- Unlocks: `production/epics/audio/story-004-audio-do-jogo-no.md`
