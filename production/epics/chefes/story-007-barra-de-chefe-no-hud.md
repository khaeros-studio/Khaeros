# Story 007: Barra de chefe no HUD

> **Epic**: Chefes
> **Status**: Complete
> **Layer**: Feature (consumo na Apresentação)
> **Type**: UI
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/chefes.md` (R10; UI Requirements)
**Requirement**: `TR-chefes-015`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: UI e HUD
**ADR Decision Summary**: HUD em `Control` dentro de `CanvasLayer`, escala 85–150%; lê Vida, `vida_max`, fase e `subjugado` das vistas publicadas no mesmo passo; sem fio de Vida sob o chefe.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: HIGH
**Engine Notes**: ADR-0012 HIGH (UI 4.5–4.7: AccessKit, escala); usar só o que o ADR registra como verificado.

**Control Manifest Rules (this layer)**:
- Required (Presentation): HUD lê vistas/eventos e nunca escreve estado de jogo
- Guardrail: atualização sem alocação por quadro

---

## Acceptance Criteria

*From GDD `design/gdd/chefes.md`, scoped to this story:*

- [x] **AC-CH-20** Chefe com 700/700 sofrendo dano até 340/700: barra no topo central (960 × 14 px, y 48, nome "Soberano do Limiar" em H2), sem fio sob os pés, atualiza no mesmo passo e aciona a Fúria no entalhe de 50%.
- [x] UI Requirements: entalhe racha e barra pulsa na `TransicaoFase`; moldura em Osso claro sólido nos 30 passos invulneráveis; fade-out de 0,25 s em `Subjugado`/`Morto`.

---

## Implementation Notes

*Derived from ADR-0012:*

- Capturas: barra cheia, após a Fúria, durante a invulnerabilidade, no fade-out; escala 85% e 150%.

---

## Out of Scope

- Épico `hud`: demais elementos do HUD.

---

## Files

- `src/presentation/game_hud.gd` (**adaptar**) ou `src/presentation/hud/barra_de_chefe.gd` (novo, conforme o épico `hud`)
- `production/qa/evidence/chefes-barra-*.png`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**: captura retida de cada estado da barra em `production/qa/evidence/`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/chefes/story-006-defesas-e-transicao-de-fase.md`; épico `production/epics/hud/EPIC.md`
- Unlocks: None

**Código da fatia**: `src/presentation/game_hud.gd` — **adaptar** (acrescentar a barra lendo a vista publicada pela IA).
