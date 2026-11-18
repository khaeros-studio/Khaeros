# Story 007: Próxima onda, "em combate" e câmara limpa no item 10

> **Epic**: Câmaras e ondas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/camaras-e-ondas.md` (R9, R9-P, R10, R11)
**Requirement**: `TR-camaras-007`, `TR-camaras-008`, `TR-camaras-015`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Orquestrador do passo; ADR-0010: Resolução do combate no passo; ADR-0002: Canal de eventos; ADR-0003: Entidades e portadores
**ADR Decision Summary**: No item 10 do passo, só com hitstop 0, as Câmaras avaliam próxima onda e limpeza; ao limpar removem os projéteis inimigos e emitem `camara_limpa(p, tipo)` uma vez no mesmo passo (únicas emissoras); a contagem usa só a lista de inimigos — Maldições e acuada ficam fora; morte vence a limpeza.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH (ADR-0001/ADR-0010)
**Engine Notes**: Passo de 60 Hz próprio.

**Control Manifest Rules (Feature)**:
- Required: ordem dos itens do passo do ADR-0001/ADR-0010
- Forbidden: emitir `camara_limpa` fora do item 10

---

## Acceptance Criteria

*From GDD `design/gdd/camaras-e-ondas.md`, scoped to this story:*

- [x] AC-CO-12 / AC-CO-15: lista vazia, hitstop 0 e onda seguinte → nasce no mesmo passo; "em combate" verdadeiro na fase Combate (inclusive com inimigos surgindo) e falso na Entrada, Limpa, Saída e santuário.
- [x] AC-CO-13: no passo do último abate com hitstop > 0 o item 10 é pulado; passos congelados não rodam a R1; no 1º passo vivo a limpeza é avaliada.
- [x] AC-CO-14 / AC-CO-16: última onda vazia e hitstop 0 → fase Limpa no mesmo passo, projéteis inimigos removidos, `camara_limpa(p, tipo)` uma vez; jogador morto no passo do último abate → câmara não é dada como limpa.
- [x] AC-CO-34: última onda morta com Maldição e acuada vivas e hitstop 0 → limpa no mesmo passo.

---

## Implementation Notes

- `em_combate()` é consulta pura usada por Selo, HUD e Áudio.

---

## Out of Scope

- Story 008: portas após a limpeza
- Story 009: fase `Subjugado` do chefe

---

## Files

- `src/gameplay/camaras/camaras.gd`
- `tests/unit/camaras/ciclo_de_combate_e_limpar_test.gd`

Código atual da fatia: o teste de vitória/bênção por `wave_index` em `game_session.gd::step` é **substituído**.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/camaras/ciclo_de_combate_e_limpar_test.gd` — must exist and pass
**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/camaras-e-ondas/story-006-montagem-na-transicao.md`; `production/epics/combate-nucleo/EPIC.md` (hitstop e varredura de mortes — story a criar)
- Unlocks: `production/epics/camaras-e-ondas/story-008-santuario-e-portas.md`, `production/epics/camaras-e-ondas/story-009-camara-do-chefe.md`
