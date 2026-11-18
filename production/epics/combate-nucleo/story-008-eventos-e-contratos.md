# Story 008: Eventos tipados e contratos com IA, Telégrafos, Câmaras, Selo e Status

> **Epic**: Combate núcleo
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/combate-nucleo.md` (R15, R17, F11; Visual/Audio V14, A1; AC l.2608–2656, l.3023–3136, l.3210)
**Requirement**: `TR-combate-nucleo-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Canal de eventos; ADR-0010: Resolução do combate no passo
**ADR Decision Summary**: O Combate emite `EventoDoPasso` tipados com campos fixos e durações já em passos para HUD, Feedback, Áudio, Selo, Status, Câmaras, Run e Telemetria; a Apresentação só lê a lista; integrações síncronas pelos contratos do ADR-0010.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: HIGH
**Engine Notes**: ADR-0002 (HIGH): `@abstract` (4.5) na base de eventos; override com retorno tipado exige `return` explícito (4.7). Nada de sinal do Godot na regra.

**Control Manifest Rules (this layer)**:
- Required: `selo.creditar_acerto_tardio` uma vez por `acerto_de_arma` do item 8
- Forbidden: sinal do Godot na regra de combate
- Guardrail: sem alocação no caminho quente além dos eventos

---

## Acceptance Criteria

- [x] AC-97 [L] R15/R17 — durações visuais nos eventos (l.2608)
- [x] AC-91 [L] R17 — campos dos eventos e `peso_visual` (l.2616)
- [x] AC-66 [L] F11/F9 (l.3023)
- [x] AC-67 [I] IA (l.3035)
- [x] AC-68 [I] Telégrafos (l.3042)
- [x] AC-69 [I] Câmaras (l.3045)
- [x] AC-70 [I] Selo e Status (l.3054)
- [x] AC-71 [I] paridade (l.3061)
- [x] AC-72 [L] V14 — um impulso de câmera por passo (l.3115)
- [x] AC-80b [L] A1 — eventos iguais no mesmo passo soam como um (l.3210)

---

## Implementation Notes

*Derived from ADR-0002 and ADR-0010:*

- Classes de evento com campos fixos (`EvAcerto` etc.), base `@abstract`; o Combate anexa à lista do passo, nunca chama a Apresentação.
- AC-67–70 com os módulos reais quando existirem; até lá dublês, e a story fica aberta até a integração real passar.
- **Código da fatia**: o `Array[String]` devolvido por `src/gameplay/game_session.gd` — **substituir** por eventos tipados; `src/presentation/game_hud.gd` e `world_view.gd` — **adaptar** para ler a lista de eventos (no épico `hud`/`feedback-de-combate`).

---

## Out of Scope

- Story 009: eventos de Pactos (`maldicao_atingida`, `chamado`, `chefe_vencido`…)
- Épicos `feedback-de-combate`, `audio`, `hud`: o consumo dos eventos

---

## Files

- `src/gameplay/combate/eventos/` (classes de evento)
- `tests/unit/combat/eventos_test.gd`
- `tests/integration/combat/contratos_test.gd` (AC-67–71)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/combat/contratos_test.gd` + `tests/unit/combat/eventos_test.gd` — must exist and pass

**Status**: [x] Complete (`src/gameplay/combate/eventos_do_combate.gd`, `tests/unit/combat/eventos_e_contratos_test.gd`, `production/qa/evidence/combate-nucleo-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/combate-nucleo/story-007-dano-no-jogador-e-varredura.md`, `production/epics/ia-de-inimigos-e-elites/EPIC.md`, `production/epics/telegrafos/EPIC.md`, `production/epics/camaras-e-ondas/EPIC.md`, `production/epics/selo-e-fluxo/story-004-dano-do-selo.md`, `production/epics/efeitos-de-status/EPIC.md`
- Unlocks: `production/epics/combate-nucleo/story-010-leitura-visual-desempenho-e-latencia.md`
