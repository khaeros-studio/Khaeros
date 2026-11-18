# Story 004: TelaBencaoTuning — injeção e validação TB1–TB10

> **Epic**: Tela de bênção e carta
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/tela-de-bencao-e-carta.md` (Tuning Knobs, códigos TB)
**Requirement**: `TR-tela-bencao-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Catálogo de dados
**ADR Decision Summary**: Catálogo `.tres` com manifesto explícito; o esquema de cada definição declara campos, tipos, limites; validação em duas passadas com diagnóstico (arquivo, campo, regra, valor, nível); ajustes publicados só após zero erros; na recarga os ajustes da Tela de bênção são revogados e reinjetados.
**ADR Version**: ADR-0004 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: `CACHE_MODE_IGNORE_DEEP` na recarga — NEEDS VERIFICATION (ADR-0004).

**Control Manifest Rules (Foundation — catálogo; consumidor na Presentation)**:
- Required: esquema declara campos, tipos, obrigatoriedade, limites; a validação distingue campo ausente de valor gravado
- Forbidden: executar o importador de conteúdo em runtime
- Guardrail: validação do catálogo ≤ 30 ms

---

## Acceptance Criteria

*From GDD `design/gdd/tela-de-bencao-e-carta.md`:*

- [x] AC-TB-35 [L] — `trava_confirmar_ms` 400 gera TB1; `entrada_s` 0,5 gera TB3; `anim_confirmar_s` 0,7 gera TB5; `foco_escala` 1,2 gera TB6; o dado de fábrica não gera TB; cada um dos 10 campos fora da faixa gera só o seu código (TB1 a TB10), texto `TelaBencaoTuning: <campo> <valor> fora da faixa <min>–<max>`.
- [x] O `GrupoDeCartas` lê travas e durações só do `TelaBencaoTuning` injetado (nenhum 500/300/0,45 literal no código).

---

## Implementation Notes

*Derived from ADR-0004 (Validação e diagnóstico; Recarga):*

- Regras TB por campo registradas no validador do Conteúdo (R9 de lá); o tipo `TelaBencaoTuning` em `src/content/` se o épico `conteudo` ainda não o tiver.
- Na recarga entre runs, a Tela recebe ajustes vazios e depois os novos.

---

## Out of Scope

- `production/epics/assets-e-conteudo/story-001-manifesto-e-tunings-da-fatia.md`: o arquivo `.tres` de fábrica

---

## Files

- `src/content/tela_bencao_tuning.gd` (se ausente)
- regras TB no validador do Conteúdo (arquivo definido pelo épico `conteudo`)
- `tests/unit/tela_bencao/tela_bencao_tuning_validacao_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/tela_bencao/tela_bencao_tuning_validacao_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/tela_bencao/tuning_carta_view_e_bencaos_real_test.gd`, `production/qa/evidence/tela-bencao-carta-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/conteudo/` (story do validador por tipo); `production/epics/assets-e-conteudo/story-001-manifesto-e-tunings-da-fatia.md`
- Unlocks: `production/epics/tela-de-bencao-e-carta/story-005-carta-view-e-vista-da-tela.md`
