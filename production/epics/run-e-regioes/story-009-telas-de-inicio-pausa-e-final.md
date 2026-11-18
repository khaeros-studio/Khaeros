# Story 009: Telas de início, pausa e final ligadas à Run

> **Epic**: Run e regiões (ciclo da run)
> **Status**: Complete
> **Layer**: Feature (consumo na Apresentação)
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/run-e-regioes.md` (UI Requirements; R2 marca da última arma; R6; R7)
**Requirement**: `TR-run-012`, `TR-run-006` (lado da UI)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: UI e HUD; ADR-0013: Persistência do MVP; ADR-0015 (§3, §8)
**ADR Decision Summary**: telas em `Control` dentro de `CanvasLayer`, foco duplo (mouse/gamepad), escala 85–150%; a tela de escolha usa `PortaDaEscolhaDeArma.escolher(i)`; a pausa pergunta `run.abandono_permitido()`; a tela final lê o `ResumoDaRun` (só leitura). A última arma vem do perfil (`PreferenciasDeArma`).
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: HIGH
**Engine Notes**: ADR-0012 HIGH — AccessKit (4.5+) e foco/escala de UI em 4.7.2; usar só o que o ADR-0012 registra como verificado.

**Control Manifest Rules (this layer)**:
- Required (Presentation): UI lê estado por consultas/eventos; nunca escreve estado de jogo; `Input` só na fronteira de input
- Forbidden: UI chamar `creditar`/`gastar` (recebe `LeituraDaConta`)

---

## Acceptance Criteria

*From GDD `design/gdd/run-e-regioes.md`, scoped to this story:*

- [x] Tela de início com 3 cartas (`lamina`, `ressonancia`, `pactos`) e a última arma escolhida vem marcada (TR-run-012; AC-RN-03/28 no lado visível).
- [x] Pausa: "Abandonar run" desabilitado em Bênção e depois de `chefe_subjugado` (AC-RN-15/34 no lado visível); confirmar/cancelar abandono funcionam.
- [x] Tela final mostra os campos do resumo (desfecho, câmaras limpas, Fragmentos coletados + bônus = total, abates, duração, seed; `desfecho_chefe` e dupla em Pactos) e abre 1 vez (AC-RN-11).

---

## Implementation Notes

*Derived from ADR-0012 / ADR-0015:*

- Captura de cada tela tocada (início, pausa normal, pausa com abandono desabilitado, final de vitória, final de morte).

---

## Out of Scope

- Épico `hud`: HUD de combate.
- Épico `vinculo-e-pactos`: tela da dupla e consentimento.

---

## Files

- `src/presentation/telas/tela_de_inicio.gd`, `tela_de_pausa.gd`, `tela_final.gd` (novos; nomes a confirmar com o épico `hud`)
- `src/presentation/game_hud.gd` (**adaptar**: as telas de menu/fim da fatia saem daqui)
- `production/qa/evidence/run-telas-*.png`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: UI
**Required evidence**: captura retida de cada tela tocada em `production/qa/evidence/`.

**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/run-e-regioes/story-007-morte-abandono-e-pausa.md`, `production/epics/run-e-regioes/story-008-resumo-da-run.md`, `production/epics/run-e-regioes/story-010-perfil-e-saida-do-jogo.md` (última arma); épico `production/epics/hud/EPIC.md` (base de UI do ADR-0012)
- Unlocks: None

**Código da fatia**: menus e tela de fim da fatia em `game_hud.gd`/`main.gd` (seleção de menu) — **adaptar** para as telas novas; a seleção de menu sai do `Main`.
