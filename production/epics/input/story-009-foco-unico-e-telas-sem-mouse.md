# Story 009: Foco único, telas sem mouse e campo de texto

> **Epic**: Input e controle
> **Status**: Complete
> **Layer**: Foundation
> **Type**: UI
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/input-e-controle.md`
**Requirement**: `TR-input-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0006: Input por passo (com ADR-0012 para a UI)
**ADR Decision Summary**: Uma via de execução: a UI recebe comandos de tela do provedor sem ler `Input`; hover chama `grab_focus()` fora de Texto mantendo um foco navegável; `pressed` nativo e comandos amostrados não podem executar a mesma confirmação duas vezes; o campo de texto aceita edição nativa mas o roteador impede navegação e confirmação nos controles vizinhos.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: HIGH
**Engine Notes**: Foco duplo do 4.6 (teclado/gamepad separado do mouse): foco visual real a validar; testar a via nativa de `Control` (atalhos) para bloquear dupla confirmação e bypass da barreira.

**Control Manifest Rules (this layer)**:
- Required: um único modelo de foco; foco inicial em toda tela (ADR-0006, ADR-0012)
- Forbidden: UI ler `Input`/`InputEvent`; `_gui_input` para ações; `pressed` de `BaseButton` ligado a uma ação; `Button` nativo com foco da engine (ADR-0012)
- Guardrail: no máximo uma confirmação por passo

---

## Acceptance Criteria

*From GDD `design/gdd/input-e-controle.md`, scoped to this story:*

- [x] **AC-33** Para cada tela do inventário da R9: existe foco inicial; `ui_navegar` alcança todos os controles focáveis; mouse sintético sobre outro controle focável move o foco para ele e o `ui_navegar` seguinte parte desse controle (foco único). Na Tela de bênção: 1/2/3 focam a carta sem confirmar; Enter, Espaço, E ou A confirmam; R troca as ofertas; o gamepad navega e aceita, respeitadas as travas de 500/300 ms (zeradas no teste)
- [x] **AC-34** Screenshot de cada tela operada só por teclado e só por gamepad, com o foco visível
- [x] **AC-36** Campo de seed do debug (contexto Texto): `ui_aceitar` entra em edição; digitar `A1D3` grava "A1D3" e o foco não se move; Enter confirma e volta ao Menu; Esc sai sem mudar o valor e não abre a Pausa; `XYZ` + Enter → continua em Texto com a mensagem do RNG; com `ui_aceitar`/`ui_voltar` remapeados para F1/F2, em edição só Enter e Esc confirmam e cancelam, e Espaço e E viram texto; A do gamepad não entra em edição; mouse sobre o botão vizinho mantém a edição; clique no botão vizinho sai da edição sem acioná-lo

---

## Implementation Notes

*Derived from ADR-0006 §5:*

O adaptador observa os eventos antes de os controles os consumirem; um clique identificado passa por uma consulta de alvo visual e sua confirmação obedece ao mesmo contexto e barreira do teclado. Cartas 1–3 apenas focam; as travas de 500/300 ms pertencem à Tela de bênção. Confirmação usa borda de subida, sem repetição por segurar; navegação repetida é política da UI. Entrada em Texto só por teclado e clique, Enter e Esc físicos fixos; não confundir códigos físicos de bind com caracteres digitados. Esta story entrega o roteador de foco e o campo de texto, com uma cena de teste; o item AC-33 é fechado tela a tela à medida que os épicos hud e tela-de-bencao-e-carta criam as telas do inventário R9 (a lista fica registrada no arquivo de evidência).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: contextos e barreira de troca
- Épicos hud e tela-de-bencao-e-carta: as telas em si

---

## Files

- `src/foundation/input/roteador_de_foco.gd`
- `src/presentation/campo_de_texto_de_debug.gd`
- `tests/integration/input/foco_unico_test.gd`
- `tests/integration/input/campo_de_texto_test.gd`
- `production/qa/evidence/input-foco-telas-<tela>.png` (um por tela)
- `production/qa/evidence/input-telas-sem-mouse-evidence.md`

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: um screenshot retido de cada tela tocada, em `production/qa/evidence/`; mais `tests/integration/input/foco_unico_test.gd`

**Status**: [x] Complete — `production/qa/evidence/input-foco-unico-evidence.md` e `tests/unit/input/foco_unico_test.gd`

---

## Dependencies

- Depends on: `production/epics/input/story-005-contextos-barreira-foco-e-desconexao.md`; `production/epics/hud/` e `production/epics/tela-de-bencao-e-carta/` (stories ainda por criar, para as telas do inventário)
- Unlocks: `production/epics/rng/story-007-texto-da-seed-na-interface.md`
