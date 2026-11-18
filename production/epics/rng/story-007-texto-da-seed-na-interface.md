# Story 007: Texto da seed na interface (pausa, morte, vitória e debug)

> **Epic**: RNG com seed
> **Status**: Complete
> **Layer**: Foundation
> **Type**: UI
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/rng-com-seed.md`
**Requirement**: `TR-rng-012` (exibição, copiar e campo de debug)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: RNG determinístico (com ADR-0012 para a UI)
**ADR Decision Summary**: O rótulo exibe seed, versão e prefixo curto da impressão do catálogo; a UI recebe o texto pronto e não lê `Input` nem a fonte de fluxos; o campo de seed do debug usa o contexto Texto do Input.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: HIGH (UI: foco duplo do 4.6, ADR-0012)
**Engine Notes**: `Control` em `CanvasLayer`; a cópia usa a área de transferência do SO, a verificar em janela real.

**Control Manifest Rules (this layer)**:
- Required: UI recebe o texto pronto por injeção; um único modelo de foco (ADR-0012)
- Forbidden: UI ler `Input`/`InputEvent` ou usar `_gui_input` para ações (ADR-0012)
- Guardrail: escala de UI 85–150% não pode cortar o texto da seed

---

## Acceptance Criteria

*From GDD `design/gdd/rng-com-seed.md`, scoped to this story:*

- [x] **AC-22** Screenshots da pausa, da morte, da vitória e do overlay de debug mostram o texto completo da seed (`XXXX-XXXX · vX.Y.Z · cXXXX`); o campo de debug com entrada inválida mantém o texto digitado e mostra a mensagem
- [x] Copiar coloca o texto da seed na área de transferência (GDD R8, UI Requirements)

---

## Implementation Notes

*Derived from ADR-0005 (Seed, telemetria e fronteira) e ADR-0012:*

A tela só exibe o texto produzido pela story 004; o campo de debug entra em edição conforme o contexto Texto do Input (Input AC-36) e mostra a mensagem do parse F9 sem apagar o que foi digitado. Esta story não cria as telas de pausa, morte e vitória: encaixa o rótulo da seed nelas e no overlay de debug, quando existirem no épico hud.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: formatação e parse
- Épico hud: as telas hospedeiras (pausa, morte, vitória)
- Épico input: edição de texto e foco

---

## Files

- `src/presentation/rotulo_da_seed.gd`
- `tests/unit/rng/rotulo_da_seed_test.gd`
- `production/qa/evidence/rng-seed-pausa.png`, `rng-seed-morte.png`, `rng-seed-vitoria.png`, `rng-seed-debug.png`

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: um screenshot retido de cada tela tocada, em `production/qa/evidence/`

**Status**: [x] Complete — `production/qa/evidence/rng-texto-seed-ui-evidence.md` e `tests/unit/rng/rotulo_da_seed_test.gd`

---

## Dependencies

- Depends on: `production/epics/rng/story-004-seed-da-run-texto-e-entropia.md`; as telas hospedeiras do épico `production/epics/hud/` (stories ainda por criar — esta story fecha quando as telas existirem)
- Unlocks: None
