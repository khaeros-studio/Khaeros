# Story 003: Preempção no mesmo passo e remetente único de impulso de câmera

> **Epic**: Feedback de combate
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

Regras de disputa no mesmo passo: chefe > recusa > passes > telégrafos para impact frame e flash (via limitador F6 do Pipeline), um só impulso de câmera por passo (o de maior peso), letreiros e pedidos repetidos, e o que sobra de um pedido negado.

**GDD**: `design/gdd/feedback-de-combate.md` (R3, R4, R8, R12, R17)
**Requirement**: `TR-feedback-003`, `TR-feedback-004`, `TR-feedback-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Pipeline visual; ADR-0007: Cena, viewport e câmera; ADR-0002: Canal de eventos
**ADR Decision Summary**: O `EstadoVisual` responde `aceito` a cada pedido; com `false` o Feedback tira só o flash chapado e mantém zoom, manchas, hitstop e número; a câmera é própria (ADR-0007) e tela→mundo ignora impulsos; o Feedback é o remetente único do impulso.
**ADR Version**: ADR-0011 2026-11-16; ADR-0007 2026-11-14; ADR-0002 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Lógica pura.

**Control Manifest Rules (this layer)**:
- Required: a Apresentação só lê e nunca escreve no jogo
- Forbidden: never o Feedback aplicar opção diretamente
- Guardrail: n/a

---

## Acceptance Criteria

*From GDD `design/gdd/feedback-de-combate.md`, scoped to this story:*

- [x] AC-FB-16 [L] R12 — impact frame (chefe vence recusa; impact frame vence a inversão no sprite do jogador)
- [x] AC-FB-17 [L] R12 — câmera (um impulso por passo, o de maior peso/`escala`)
- [x] AC-FB-18 [L] R12 — letreiros e repetição (≤ 2 letreiros; pedidos idênticos no mesmo alvo e passo viram um)
- [x] AC-FB-20 [L] R8 — limitador (impact frame negado: sai só o flash chapado; flash de telégrafo negado: telégrafo sem o osso, visível)
- [x] AC-FB-37 [L] R17 — câmera da Maldição (`chamado_pouso` escala 0,6; jogador vence; ataques básicos sem impulso)

---

## Implementation Notes

*Derived from ADR-0011 §7 and ADR-0007:*

- O árbitro chama `EstadoVisual.pedir_*` através de uma interface injetada (dublê nos testes).
- O impulso sai como pedido para a câmera; quem aplica é a câmera do épico cena-e-camera.

---

## Out of Scope

- `production/epics/pipeline-visual/story-002-limitador-de-flashes-f6.md`: a regra F6 em si

---

## Files

- `src/presentation/feedback/arbitro_de_feedback.gd` (preempção)
- `src/presentation/feedback/seletor_de_impulso.gd`
- `tests/unit/feedback/preempcao_e_impulso_de_camera_test.gd`

Código da fatia: `src/presentation/game_camera.gd::impulse` (fila de até `max_impulses`) — **adaptar** no épico cena-e-camera para receber um impulso por passo do Feedback; o decaimento da fatia é referência de sensação.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/feedback/preempcao_e_impulso_de_camera_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/feedback/arbitro_e_preempcao_test.gd`, `production/qa/evidence/feedback-combate-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/feedback-de-combate/story-002-arbitro-puro.md`, `production/epics/pipeline-visual/story-002-limitador-de-flashes-f6.md`
- Unlocks: `production/epics/feedback-de-combate/story-008-vistas-e-pool-de-vfx.md`
