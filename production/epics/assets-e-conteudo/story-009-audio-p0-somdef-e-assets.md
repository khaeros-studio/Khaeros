# Story 009: Áudio P0 — arquivos em assets/audio, SomDef e AudioTuning no catálogo

> **Epic**: Assets e conteúdo
> **Status**: Complete
> **Layer**: Foundation (áudio acompanha a Apresentação)
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/feedback-de-combate.md` (ganchos e prioridades); `design/gdd/telegrafos.md` (estalo no disparo); ganchos de áudio dos demais GDDs
**Requirement**: N/A — sem TR próprio; consumido por TR-feedback-008, TR-telegrafos-014 e pelo épico `audio`.
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016: Áudio: ganchos e vozes; ADR-0004: Catálogo de dados
**ADR Decision Summary**: `AudioDoJogo` toca pedidos (`PedidoDeSom`) de um pool fixo por prioridade (P0 nunca roubada), 4 barramentos (Master, Música, Efeitos, Interface); todo stream vem de `SomDef` do catálogo, nunca de caminho literal; `SomDef` e `AudioTuning` entram pelo mesmo manifesto e validação.
**ADR Version**: ADR-0016 2026-11-16 · ADR-0004 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: as da seção "Confirmação de API" do ADR-0016.

**Control Manifest Rules (Presentation)**:
- Required: todo stream vem de `SomDef` do catálogo
- Forbidden: caminho literal de som; vistas/Telas/HUD chamarem `play()`
- Guardrail: seleção de áudio < 0,05 ms por passo

---

## Acceptance Criteria

*From the epic scope (entrega 3) and ADR-0016:*

- [x] `assets/audio/` criado com um arquivo por gancho **P0** do ADR-0016 (incluindo `sfx_telegrafo_disparo`) e os sons de UI pedidos por HUD/Tela (`sfx_maldicao_recusa` etc. conforme o Feedback).
- [x] Um `SomDef` por gancho, com barramento e prioridade do ADR-0016, e um `AudioTuning` com os valores do GDD de Feedback (limites 4 por gancho, 16 total), registrados no manifesto.
- [x] Carregador chega a Pronto; nenhum caminho de som literal fora do catálogo.
- [x] Teste de escuta em jogo + sign-off do audio-director em `production/qa/evidence/audio-p0-evidence.md`.

---

## Implementation Notes

*Derived from ADR-0016 e ADR-0004:*

- Ganchos P1–P4 ficam fora desta story (acompanham o épico `audio`).

---

## Out of Scope

- Épico `audio`: `AudioDoJogo`, `MixadorDeVozes`, `SeletorDeTons`

---

## Files

- `assets/audio/**` (novos)
- `assets/data/audio/*.tres` (`SomDef`), `assets/data/tuning/audio_tuning.tres`; `assets/data/content_catalog.tres` (acrescentar)
- `production/qa/evidence/audio-p0-evidence.md`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Visual/Feel (audio sync)
**Required evidence**: registro de escuta + sign-off em `production/qa/evidence/audio-p0-evidence.md`
**Status**: [x] Created (`production/qa/evidence/assets-e-conteudo-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/assets-e-conteudo/story-001-manifesto-e-tunings-da-fatia.md`; `production/epics/conteudo/` (tipos `SomDef`, `AudioTuning`)
- Unlocks: `production/epics/audio/` (stories de reprodução)
