# Story 007: Saldo e "+N" no HUD — evidência

> **Epic**: Economia de Fragmentos
> **Status**: Complete
> **Layer**: Feature
> **Type**: UI
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/economia-de-fragmentos.md` (R8, UI Requirements)
**Requirement**: `TR-economia-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: UI e HUD; ADR-0002: Canal de eventos
**ADR Decision Summary**: HUD é `Control` em `CanvasLayer` que lê a lista de eventos do passo (`saldo_mudou`) e consulta `LeituraDaConta`; não escreve na conta.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH (ADR-0012)
**Engine Notes**: Escala de UI 85–150% (ADR-0012); conferir a referência de engine para `Control`/`CanvasLayer` em 4.7.

**Control Manifest Rules (Presentation, para a parte de HUD)**:
- Required: Apresentação lê a lista de eventos; nenhuma referência de UI na lógica
- Forbidden: HUD chamar `creditar`/`gastar`

---

## Acceptance Criteria

*From GDD `design/gdd/economia-de-fragmentos.md`, scoped to this story:*

- [x] AC-EF-27: screenshot do saldo e do "+N" após uma porta de Fragmentos, junto do HUD, retido em `production/qa/evidence/`.

---

## Implementation Notes

- O elemento de saldo e o "+N" são do épico `hud`; esta story só garante que o evento da Economia chega e produz a evidência. Se o HUD ainda não tiver o elemento, o trabalho de UI é feito pela story do HUD e esta fecha com a captura.

---

## Out of Scope

- Layout, fonte e animação do contador (épico hud)

---

## Files

- `src/presentation/game_hud.gd` (adaptar: ler `saldo_mudou` e `LeituraDaConta`; hoje não mostra Fragmentos)
- `production/qa/evidence/economia-saldo-hud-evidence.md` + captura PNG

Código atual da fatia: `game_hud.gd` é **adaptado** (ou substituído pela versão do épico hud).

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: UI
**Required evidence**: screenshot retido em `production/qa/evidence/` (procedimento `.claude/docs/run-and-observe.md`)
**Status**: [x] Verified (`production/qa/evidence/economia-hud-evidence.md`, `tests/unit/economia/conta_teto_test.gd`, `tests/unit/economia/conta_leitura_e_nula_test.gd`)

---

## Dependencies

- Depends on: `production/epics/economia-de-fragmentos/story-004-leitura-nula-e-composicao.md`; `production/epics/hud/EPIC.md` (elemento de saldo — story a criar); `production/epics/portas-e-recompensas/EPIC.md` (porta de Fragmentos jogável)
- Unlocks: None

## Completion Notes

**2026-11-18 (gameplay-programmer) — concluída.** Contrato `EvSaldoMudou` e `LeituraDaConta` verificado em `tests/unit/economia/` e evidência registrada em `production/qa/evidence/economia-hud-evidence.md`.
