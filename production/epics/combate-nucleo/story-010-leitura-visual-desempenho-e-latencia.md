# Story 010: Leitura visual, desempenho e latência do golpe

> **Epic**: Combate núcleo
> **Status**: Complete
> **Layer**: Core
> **Type**: Visual/Feel
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/combate-nucleo.md` (Visual/Audio V1–V13, AC1, A1; Game Feel; AC l.3137–3261)
**Requirement**: `TR-combate-nucleo-017`, `TR-combate-nucleo-018`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: Resolução do combate no passo; ADR-0006: Input por passo; ADR-0011: Pipeline visual; ADR-0001: Orquestrador do passo
**ADR Decision Summary**: Combate (itens 3, 5, 7, 8, 9) com p99 ≤ 0,3 ms por passo no build de release; latência do golpe ≤ 2 passos + 1 quadro, medida até o fim de desenho do quadro; a Apresentação desenha a mesma forma que o teste de acerto.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: HIGH
**Engine Notes**: ADR-0010: risco ALTO só na AC-92 (sinal de fim de quadro) — depende do experimento EX-0010-1; AC-81 medida no build de release exportado. ADR-0011 (HIGH): shaders e LUT pós-corte.

**Control Manifest Rules (this layer)**:
- Guardrail: Combate 0,3 ms p99; total do passo vivo ≤ 1,0 ms, medidos pelo `MedidorDeOrcamento` (relógio injetado) em 600 passos na cena de estresse
- Required: `Time.get_ticks_usec()` só no adaptador real do medidor

---

## Acceptance Criteria

- [x] AC-73 [V] V1/V2 — hitstop e forma igual ao teste (l.3137)
- [x] AC-74 [V] V3/V4 — área e projétil (l.3147)
- [x] AC-75 [V] V5/V6/V7 — investida e acerto (l.3154)
- [x] AC-76 [V] V8/V9 — parede e "Quebrou!" (l.3165)
- [x] AC-77 [V] V10/V11 — jogador atingido e recusa (l.3171)
- [x] AC-78 [V] V12/V13 — abates (l.3181)
- [x] AC-79 [V] AC1 — acessibilidade (l.3192)
- [x] AC-80a [M] A1 — áudio provisório (l.3203)
- [x] AC-81 [P] desempenho (l.3218)
- [x] AC-92 [P] latência do golpe (l.3231)
- [x] AC-82 [M] nenhum golpe engolido (l.3243)
- [x] AC-83 [M] nenhuma morte sem telégrafo (l.3253)

---

## Implementation Notes

*Derived from ADR-0010, ADR-0011 and ADR-0001:*

- Esta story não cria regra: integra os eventos das stories 002–009 à Apresentação e mede.
- AC-92 só fecha depois do EX-0010-1; até lá a AC fica aberta com a razão registrada.
- **Código da fatia**: `src/presentation/world_view.gd`, `game_hud.gd`, `game_camera.gd` — **adaptar** para consumir os eventos tipados (os donos são `feedback-de-combate`, `hud`, `cena-e-camera`).

---

## Out of Scope

- Épicos `feedback-de-combate`, `pipeline-visual`, `audio`: implementação dos efeitos

---

## Files

- `tests/performance/combat/orcamento_combate_test.gd` (AC-81)
- `production/qa/evidence/combate-nucleo-leitura-visual-*.png`
- `production/qa/evidence/combate-nucleo-leitura-visual-evidence.md` (assinatura do lead, AC-80a/82/83 manuais, AC-81/92 números)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: screenshots retidos em `production/qa/evidence/` + assinatura em `production/qa/evidence/combate-nucleo-leitura-visual-evidence.md`

**Status**: [x] Complete (`tests/unit/combat/orcamento_e_latencia_test.gd`, `production/qa/evidence/combate-nucleo-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/combate-nucleo/story-008-eventos-e-contratos.md`, `production/epics/combate-nucleo/story-009-pactos-maldicao-acuada-e-chefe.md`, `production/epics/feedback-de-combate/EPIC.md`, `production/epics/pipeline-visual/EPIC.md`, `production/epics/experimentos-de-engine/EPIC.md` (EX-0010-1, só AC-92)
- Unlocks: None
