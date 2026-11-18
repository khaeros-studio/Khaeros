# Story 003: Ranged e charger, e o retângulo visível

> **Epic**: IA de inimigos e elites
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/ia-de-inimigos-e-elites.md` (R4, R6, R11, F3, F4)
**Requirement**: `TR-ia-009`

**ADR Governing Implementation**: ADR-0018: IA de inimigos e chefe (§3, §7); ADR-0007: Cena, viewport e câmera
**ADR Decision Summary**: `ComportamentoRanged` e `ComportamentoCharger` sem estado. Ranged só entra em preparo com o centro em `ConsultaDeVista.retangulo_visivel().grow(margem_visivel_px)` (estado base da câmera, sem impulsos); fora dele avança ao alvo sem recuar nem contornar. Avanço do charger ignora Selo, cambaleio e atração; contato 1× por avanço.
**ADR Version**: ADR-0018 2026-11-16 · ADR-0007 2026-11-14

**Engine**: Godot 4.7.2 | **Risk**: LOW (IA); HIGH no ADR-0007 só no lado que publica o retângulo (fora desta story)

**Control Manifest Rules (this layer)**:
- Required: porta `ConsultaDeVista` injetada; nos testes, `Rect2` fixo
- Forbidden: ler a `Camera2D`/viewport direto da IA
- Guardrail: —

---

## Acceptance Criteria

- [x] AC-IA-03 — Anomalia: 300 px recua 1,95; 450 contorna 0,975 (perpendicular); 700 avança; < 975 visível: preparo; 976: não
- [x] AC-IA-04 — Fenda: 500 avança; 400 parada; ≤ 570: preparo; 571: não
- [x] AC-IA-08 — `disparar_projetil` 1× na mira travada, parada 6 passos, projétil 6,9 px/passo
- [x] AC-IA-09 — avanço 26 passos a 7,56 (196,6 px) com/sem Selo e cambaleio; parede para; um contato fere
- [x] AC-IA-19 — fora da vista não prepara e avança; dentro prepara; `margem_visivel_px` 100 prepara até 100 px fora
- [x] AC-IA-28 — fora da vista a 300 px: avança (não recua) até entrar; ao entrar, recua e prepara
- [x] AC-IA-22 (resto) — ciclo Anomalia 142, Fenda 158; 1º tiro 106–155; 1º avanço 112–161

---

## Implementation Notes

- Contato do avanço: `circulos_encostam` via `Telegrafos.dentro` (forma do avanço); a marca "já feriu neste avanço" fica no `InimigoRef`.

---

## Out of Scope

- story-006: ranged/charger atraídos (AC-IA-43)

---

## Files

- src/gameplay/ia/comportamento_ranged.gd
- src/gameplay/ia/comportamento_charger.gd
- src/gameplay/ia/consulta_de_vista.gd
- tests/unit/ia/ia_ranged_charger_test.gd

Fatia: `game_session.gd` tem só dois inimigos; o ranged da fatia é referência. O retângulo visível hoje vem de `game_camera.gd` — **adaptar** no épico cena-e-camera para publicar o estado base por quadro.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

QL-STORY: skipped — lean

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ia/ia_ranged_charger_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/ia-de-inimigos-e-elites/story-002-fases-surgimento-e-melee.md`; `production/epics/telegrafos/story-003-forma-e-testes-de-acerto.md`; épico `production/epics/cena-e-camera/` (retângulo base)
- Unlocks: `production/epics/ia-de-inimigos-e-elites/story-006-alvo-e-atracao.md`
