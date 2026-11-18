# Story 002: MixadorDeVozes — dedupe, limites e roubo (F4)

> **Epic**: Áudio: ganchos e vozes
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

A decisão de quem toca, pura e sem som: dedupe por gancho no passo, limite por gancho (4) e total (16), roubo por prioridade com a mais antiga cedendo, P0 nunca roubada.

**GDD**: `docs/architecture/adr-0016-audio-ganchos-e-vozes.md` (requisito de `design/gdd/feedback-de-combate.md` R9/F4)
**Requirement**: `TR-feedback-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016: Áudio: ganchos e vozes
**ADR Decision Summary**: `MixadorDeVozes` (RefCounted) mantém por slot gancho, prioridade, ordem e ocupado; a cada passo libera, deduplica, ordena (estável), aplica limite por gancho e total e devolve `ComandoDeVoz(slot, gancho, parar_antes)`; resultado depende só da sequência de pedidos e liberações.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: MEDIUM
**Engine Notes**: Lógica pura; sem API de áudio.

**Control Manifest Rules (this layer)**:
- Required: decisão de voz em `MixadorDeVozes` puro; P0 nunca é roubada; entrega sem alocar
- Forbidden: never guardar `PedidoDeSom` além da entrega
- Guardrail: áudio < 0,05 ms por passo

---

## Acceptance Criteria

*From `design/gdd/feedback-de-combate.md` AC-FB-21 and ADR-0016 Validation V-2:*

- [x] AC-FB-21 [L] R9/F4 — vozes: área com 5 alvos → 1 voz; 16 vozes (3 de P4) + P3 novo → cai a P4 mais antiga; 16 vozes P0–P1 + P3 → descartado; 5º do mesmo gancho só derruba o mais antigo desse gancho com prioridade igual ou maior
- [x] V-2: 16 vozes em P0 + P0 novo → descartado e `vozes_p0_descartadas()` = 1
- [x] `zerar()` deixa o Mixador como novo (Nova run)

---

## Implementation Notes

*Derived from ADR-0016 §4 and Key Interfaces:*

- `_init(vozes_max_total, vozes_max_gancho)`, `liberar(slot)`, `resolver(pedidos, saida) -> int`, `zerar()`, `vozes_p0_descartadas()`.
- Dedupe por varredura linear (≤ ~40 pedidos); ordenação estável num array de trabalho pré-alocado.

---

## Out of Scope

- Story 004: aplicar os comandos nos `AudioStreamPlayer`

---

## Files

- `src/presentation/audio/mixador_de_vozes.gd`, `comando_de_voz.gd`
- `tests/unit/audio/mixador_de_vozes_test.gd`

Código da fatia: nenhum.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/audio/mixador_de_vozes_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/audio/mixador_de_vozes_test.gd`, `production/qa/evidence/audio-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/audio/story-001-somdef-audiotuning-e-pedidos.md`
- Unlocks: `production/epics/audio/story-004-audio-do-jogo-no.md`
