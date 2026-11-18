# Story 001: VinculoTuning, memórias do CurseDef e validação VP1–VP9

> **Epic**: Vínculo e pactos
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/vinculo-e-pactos.md` (§ Tabela consolidada `VinculoTuning`; § Validações VP1–VP9; F4)
**Requirement**: `TR-vinculo-017`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Catálogo de dados
**ADR Decision Summary**: Catálogo `.tres` com manifesto explícito, validadores na carga e impressão SHA-256; os módulos recebem tuning validado. `VinculoTuning` e `CurseDef.memorias` entram nesse catálogo; VP5–VP7 rodam na 2ª passada (cruzada com Maldições e armas).
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2) | **Risk**: MEDIUM
**Engine Notes**: ADR-0004: `Resource` `.tres`, `duplicate_deep`.

**Control Manifest Rules (Feature)**:
- Required: toda criação de módulo por `ComposicaoDaSessao`/`FabricaDaRun`, dependências no `_init` (ADR-0015)
- Forbidden: valores de tuning no código
- Guardrail: validação só na carga

---

## Acceptance Criteria

- [x] AC-VP-21 (F4, VP5, VP6, VP7): catálogo do MVP e `VinculoTuning` padrão → 0 avisos VP5/VP6/VP7 (Vida `1,495`, DPS `1,071`, paridade sem técnica `2,32%`, teto com técnica `4,33%`); com `bonus_vida = 0,06` sai VP5; com `bonus_dano_basico = 0,08` sai VP7 (`5,08%`).
- [x] VP1–VP4, VP8, VP9 (§ Validações): cada regra recusa uma fixture inválida com o seu código e aceita o catálogo do MVP.

---

## Implementation Notes

- `assets/data/tuning/vinculo_tuning.tres` (inclui `indices_encontro = [1, 2]`, `frac_vida_acuada`, tetos de pontos, `bonus_vida`, `bonus_dano_basico`, `mult_recuperacao`).
- `CurseDef.memorias` adicionado ao schema da story `production/epics/maldicoes/story-001-catalogo-e-validacao-ml.md`.

---

## Out of Scope

- Uso dos valores: stories 004–008.

---

## Files

- `src/gameplay/vinculo/vinculo_tuning.gd`, `validador_vinculo.gd`
- `assets/data/tuning/vinculo_tuning.tres`
- `tests/unit/vinculo/vinculo_tuning_e_validacao_vp_test.gd`

Código da fatia: nada reaproveitado.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/vinculo/vinculo_tuning_e_validacao_vp_test.gd` — must exist and pass
**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/maldicoes/story-001-catalogo-e-validacao-ml.md`; épico `production/epics/conteudo/`
- Unlocks: stories 002–008 deste épico
