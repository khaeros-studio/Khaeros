# Story 008: Vistas e pool de VFX ligados ao Combate real

> **Epic**: Feedback de combate
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

Liga o árbitro à tela: pool fixo de VFX (materiais `vfx_sprite`/`traco_sdf` do Pipeline), vista do pool de números, letreiros, registro do Feedback como 3º consumidor da entrega e aplicação dos pedidos de impacto, passe, flash e impulso. Verifica com o Combate real e capturas.

**GDD**: `design/gdd/feedback-de-combate.md` (R3, R5, R6, R8, R11, R15)
**Requirement**: `TR-feedback-002`, `TR-feedback-010`, `TR-feedback-005` (degradação vista em multidão)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Pipeline visual; ADR-0002: Canal de eventos; ADR-0001: Orquestrador do passo
**ADR Decision Summary**: O pool de VFX é do Feedback com materiais fornecidos pelo Pipeline; emissores do relógio vivo com `speed_scale` 0 no congelamento; o `Main` entrega a lista na ordem Telemetria → HUD → Feedback → Telas → Áudio.
**ADR Version**: ADR-0011 2026-11-16; ADR-0002 2026-11-16; ADR-0001 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: EX-0011-E3 (`speed_scale` 0 em GPU/CPU particles; fallback `emitting = false` + avanço manual ou `CPUParticles2D`). Capturas com GPU, fora do CI.

**Control Manifest Rules (this layer)**:
- Required: pool pré-instanciado; sinais do Godot só em nós de Apresentação conectados pelo `Main`; no máximo 3 sinais de status por inimigo (1 com > 9 marcados)
- Forbidden: never `draw_line`/`draw_arc` para traço de jogo
- Guardrail: VFX 64 draw calls; overdraw ≤ 3,5 / ≤ 5

---

## Acceptance Criteria

*From GDD `design/gdd/feedback-de-combate.md`, scoped to this story:*

- [x] AC-FB-29 [I] R3/R5 — Combate real (combo com enésimo acerto a_cada 4; `quebrou` com letreiro e telégrafo partido)
- [x] AC-FB-30 [V] R3/R6/R11 — cena de combate (5 inimigos, 6 números, 2 letreiros; contorno do telégrafo visível; dourado distinto em cinza)
- [x] AC-FB-41 [V] R15 — leitura com Maldição
- [x] AC-FB-31 [V] R8 — multidão (vídeo curto; degradação liga sem cortar telégrafo nem inversão)

---

## Implementation Notes

*Derived from ADR-0011 §5, §7, §8 and ADR-0002:*

- O nó `FeedbackDeCombate` (Apresentação) recebe a lista, chama o árbitro e aplica pedidos; pool sem alocação por passo.
- Números desenhados pela vista do `PoolDeNumeros`; letreiros por chave de tradução.

---

## Out of Scope

- `production/epics/audio/story-004-audio-do-jogo-no.md`: tocar os `PedidoDeSom`

---

## Files

- `src/presentation/feedback/feedback_de_combate.gd` (nó)
- `src/presentation/feedback/pool_de_vfx.gd`, `vista_de_numeros.gd`
- `src/app/main.gd` (registrar consumidor)
- `assets/shaders/sem_grading/vfx_sprite.gdshader`
- `tests/integration/feedback/vistas_e_pool_de_vfx_test.gd`
- `production/qa/evidence/feedback-008-*.png`, vídeo do AC-FB-31 + `feedback-008-evidence.md`

Código da fatia: `world_view.gd::_effect` — **substituir** pelo árbitro e pools; o hitstop e os impulsos da fatia são referência de sensação. `src/app/main.gd` — **adaptar**.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: capturas e vídeo retidos em `production/qa/evidence/` + sign-off em `production/qa/evidence/feedback-008-evidence.md`; `tests/integration/feedback/vistas_e_pool_de_vfx_test.gd` para AC-FB-29
**Status**: [x] Complete (`tests/unit/feedback/degradacao_relogios_e_maldicoes_test.gd`, `production/qa/evidence/feedback-combate-evidence.md`)

---

## Dependencies

- Depends on: stories 003, 004, 005, 006, 007 deste épico; `production/epics/pipeline-visual/story-008-nos-por-camada-e-validador.md`; `production/epics/combate-nucleo/EPIC.md`
- Unlocks: `production/epics/audio/story-004-audio-do-jogo-no.md`
