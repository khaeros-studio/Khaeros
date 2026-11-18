# Story 007: Tela de escolha de arma

> **Epic**: Armas das Doutrinas
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/armas-das-doutrinas.md` (R4, UI Requirements l.1126; AC l.1359)
**Requirement**: `TR-armas-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: UI e HUD; ADR-0006: Input por passo
**ADR Decision Summary**: Tela antes da run com o componente de carta (Control em CanvasLayer), navegável por teclado, mouse e gamepad com foco duplo, escala de 85–150%.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: HIGH
**Engine Notes**: ADR-0012: foco duplo (4.6) — `grab_focus()` só mexe no foco de teclado/gamepad; `Control.offset_transform_*` (4.7) com efeito no retângulo de acerto NOT SOURCEABLE (E1); esvaziar ações nativas `ui_*` (E2) a verificar. ADR-0006 (HIGH): eventos por classe, sem assumir `device == 0`.

**Control Manifest Rules (this layer)**:
- Required: a tela lê o estado da `EscolhaDeArma` (story 005) e só envia intenções; nenhuma regra na UI
- Forbidden: Autoload, `get_node` absoluto em lógica

---

## Acceptance Criteria

- [x] AC-AR-12 [UI] R4 — tela de escolha (l.1359)

---

## Implementation Notes

*Derived from ADR-0012 and ADR-0006:*

- Reusar o componente de carta do épico `tela-de-bencao-e-carta`; textos por chave `<chave_nome>` e `<chave_nome>_DESC`.
- **Código da fatia**: nenhuma tela de arma na fatia — construção do zero; `src/presentation/game_hud.gd` não é tocado.

---

## Out of Scope

- Story 005: a lógica de pré-seleção e gravação

---

## Files

- `src/presentation/ui/tela_escolha_de_arma.gd`, `scenes/ui/tela_escolha_de_arma.tscn`
- `production/qa/evidence/armas-tela-de-escolha-*.png`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: UI
**Required evidence**: screenshot retido de cada estado da tela (teclado, mouse, gamepad; escala 85% e 150%) em `production/qa/evidence/` (`production/qa/evidence/armas-doutrinas-evidence.md`, `tests/unit/armas/escolha_e_injecao_test.gd`)

**Status**: [x] Verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/armas-das-doutrinas/story-005-preferencia-ultima-arma.md`, `production/epics/tela-de-bencao-e-carta/EPIC.md`, `production/epics/input/EPIC.md`
- Unlocks: `production/epics/armas-das-doutrinas/story-008-verificacao-em-jogo.md`
