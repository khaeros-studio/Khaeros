# Story 009: Evidência visual e de feel: sem rastro no teleporte, esquiva em 1920×1080, áudio

> **Epic**: Movimento e esquiva
> **Status**: Complete
> **Layer**: Core
> **Type**: Visual/Feel
> **Estimate**: S
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/movimento-e-esquiva.md`
**Requirement**: TR-movimento-008 (evidência AC-44b), TR-movimento-012 (evidência AC-46/47)
*(Texto do requisito em `docs/architecture/tr-registry.yaml` — ler na hora da revisão)*

**ADR Governing Implementation**: [ADR-0008: Movimento e colisão própria](../../../docs/architecture/adr-0008-movimento-e-colisao-propria.md); [ADR-0007](../../../docs/architecture/adr-0007-cena-viewport-e-camera.md)
**ADR Decision Summary**: Círculos e retângulo próprios, sem CharacterBody2D; o Movimento é o único escritor da posição do jogador; ordem interna R3 fixa e três pedidos síncronos ao Combate na largada da esquiva.
**ADR Version**: 2026-11-16 (Last Verified; todos Accepted)

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Câmera/viewport e interpolação do 4.7 (ADR-0007, HIGH): validar em build, nunca por teste headless.

**Control Manifest Rules (this layer)**:
- Required: Movimento é o único escritor da posição; passo_congelado() só iguala anterior=atual; Corte antes da colisão; resolver_colisao função pura sobre obstáculos ordenados (ADR-0008)
- Forbidden: CharacterBody2D/Area2D/ShapeCast2D, solver da engine, subpassos, margem, epsilon, normal dependente de velocidade; Timer; Engine.time_scale; dependência de ordem de Dictionary (ADR-0008, ADR-0010)
- Guardrail: Movimento (item 4) ≤ 0,2 ms p99 por passo (provisório, ADR-0001/ADR-0008)

---

## Acceptance Criteria

*Do GDD `design/gdd/movimento-e-esquiva.md`, recortados para esta story:*

- [x] **AC-44b [V] Cena R7** Build em 1280×720, troca de câmara: sem rastro do jogador no teleporte (screenshot retido).
- [x] **AC-46 [V] R5/V3** Build em 1280×720, câmara de 1920×1080: esquiva legível e sem corte da câmera (screenshot retido).
- [x] **AC-47 [M] R5** O testador faz 20 esquivas e ouve o áudio provisório nas 20 (resultado registrado).
- [x] Assinatura do lead no documento de evidência.

---

## Implementation Notes

Rodar o jogo e capturar (procedimento .claude/docs/run-and-observe.md). Usar a fatia integrada (src/app/main.gd, game_camera.gd, world_view.gd) já ligada ao novo Movimento; adaptar apenas o necessário para a captura.

---

## Out of Scope

- Lógica: stories 003–008.

---

## Files

*Previstos; `/dev-story` substitui pela lista real.*

- production/qa/evidence/movimento-teleporte-sem-rastro-*.png, movimento-esquiva-1080-*.png
- production/qa/evidence/evidencia-visual-e-feel-da-esquiva-evidence.md

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**:
- Visual/Feel: screenshot retido em `production/qa/evidence/` + assinatura do lead em `production/qa/evidence/evidencia-visual-e-feel-da-esquiva-evidence.md`

**Status**: [x] Complete (`production/qa/evidence/movimento-esquiva-evidence.md`)

---

## Dependencies

- Depends on: [story 006](story-006-teleporte-e-deslocamento-forcado.md), [story 008](story-008-consultas-e-eventos-de-saida.md); production/epics/cena-e-camera/EPIC.md; production/epics/pipeline-visual/EPIC.md
- Unlocks: None
