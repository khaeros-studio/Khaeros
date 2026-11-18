# Story 007: Mundo parado com a oferta aberta

> **Epic**: Bênçãos e Tradições
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/bencaos-tradicoes.md` (R11, Edge Cases "Mundo")
**Requirement**: `TR-bencaos-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Orquestrador do passo e estados de jogo; ADR-0011: Pipeline visual
**ADR Decision Summary**: Estado de jogo próprio (`BENCAO`), sem `SceneTree.paused`: o orquestrador não roda os itens de simulação fora de `JOGO`, então `t_vivo` e os contadores do Combate não avançam; a apresentação usa `t_apres`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH (ADR-0001/ADR-0011)
**Engine Notes**: Proibido `SceneTree.paused` (Forbidden APIs do manifesto).

**Control Manifest Rules (Feature)**:
- Required: a troca de estado é por `pedir_estado`
- Forbidden: `SceneTree.paused`

---

## Acceptance Criteria

*From GDD `design/gdd/bencaos-tradicoes.md`, scoped to this story:*

- [x] AC-BN-19: com a oferta aberta por 60 passos, os contadores do Combate permanecem iguais; depois da escolha, voltam a descontar.
- [x] Edge Case: a pausa aberta durante a oferta abre em Bênção com "Abandonar run" desabilitado e nunca pula a escolha.

---

## Implementation Notes

- Teste de integração com orquestrador real (ou o do épico orquestrador-do-passo) e Combate com contador dublê.

---

## Out of Scope

- Épico input: contexto Bênção do Input

---

## Files

- `tests/integration/bencaos/mundo_parado_test.gd`

Código atual da fatia: `game_session.gd::_freeze/pause/resume` e o `state == "bencao"` são **substituídos** pelo `EstadoDeJogo` do ADR-0001.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/unit/bencaos/escolha_mundo_e_besta_test.gd`
**Status**: [x] Created and passing (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/bencaos-tradicoes/story-005-contrato-pedir-oferta.md`; `production/epics/orquestrador-do-passo/EPIC.md` (estados de jogo — story a criar)
- Unlocks: None
