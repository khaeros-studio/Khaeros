# Story 005: Escuta em playtest — no máximo 3 tons, estalo sempre audível, custo medido

> **Epic**: Áudio: ganchos e vozes
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

O que só se prova ouvindo: em multidão nunca soam mais de 3 tons, o estalo do disparo nunca some, e o custo da entrega fica abaixo de 0,05 ms por passo. Também acompanha o contador `vozes_p0_descartadas` na telemetria de debug.

**GDD**: `docs/architecture/adr-0016-audio-ganchos-e-vozes.md` (requisito de `design/gdd/telegrafos.md` § Visual/Audio)
**Requirement**: `TR-telegrafos-014`, `TR-feedback-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016: Áudio: ganchos e vozes
**ADR Decision Summary**: Tons top 3 por `p`; estalo como gancho P0 `sfx_telegrafo_disparo`; `vozes_p0_descartadas` > 0 num playtest leva o audio-director a rever `vozes_max_total`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: Exige áudio real (não o driver dummy).

**Control Manifest Rules (this layer)**:
- Required: ≤ 3 tons em multidão; P0 nunca é roubada
- Forbidden: n/a
- Guardrail: áudio < 0,05 ms por passo

---

## Acceptance Criteria

*From ADR-0016 Validation V-6 and Performance Implications:*

- [x] V-6: playtest na câmara de multidão registra "nunca mais de 3 tons" e "o estalo sempre audível"
- [x] Custo da entrega do áudio < 0,05 ms por passo na cena de multidão do Pipeline (antes/depois registrado)
- [x] `vozes_p0_descartadas` registrado; se > 0, decisão do audio-director anotada

---

## Implementation Notes

*Derived from ADR-0016 Risks and Performance Implications:*

- Gravar áudio curto da sessão como evidência, além da nota escrita.

---

## Out of Scope

- Mixagem e conteúdo dos sons (audio-director)

---

## Files

- `production/qa/evidence/audio-005-escuta.md` (testador, build, resultado, medição)
- `production/qa/evidence/audio-005-*.wav` ou vídeo com som

Código da fatia: nenhum.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: gravação retida em `production/qa/evidence/` + sign-off em `production/qa/evidence/audio-005-escuta.md` (o "screenshot" deste critério de áudio é a gravação)
**Status**: [x] Complete (`tests/unit/audio/audio_do_jogo_test.gd`, `production/qa/evidence/audio-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/audio/story-004-audio-do-jogo-no.md`, `production/epics/pipeline-visual/story-010-impact-frames-orcamento-e-leitura.md` (cena de multidão/estresse)
- Unlocks: None
