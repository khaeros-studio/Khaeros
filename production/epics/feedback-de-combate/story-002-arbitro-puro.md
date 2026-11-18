# Story 002: Árbitro puro — eventos e relógios entram, pedidos ordenados saem

> **Epic**: Feedback de combate
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

O coração do épico: `ArbitroDeFeedback` (RefCounted) lê a lista de `EventoDoPasso` do passo e devolve pedidos ordenados (resposta, camada, prioridade, gancho), sem escrever em nenhum sistema. A flag de acerto marcado vem do evento; a ordem de camadas é fixa.

**GDD**: `design/gdd/feedback-de-combate.md` (R1, R5, R8, R11, R14)
**Requirement**: `TR-feedback-001`, `TR-feedback-002`, `TR-feedback-009`, `TR-feedback-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Canal de eventos; ADR-0010: Resolução do combate no passo; ADR-0011: Pipeline visual; ADR-0007: Cena, viewport e câmera
**ADR Decision Summary**: A Apresentação lê a lista de `EventoDoPasso` entregue pelo `Main` (Telemetria → HUD → Feedback → Telas → Áudio) e nunca escreve no jogo; o Combate marca o acerto na flag do evento `acerto`; o impact frame é o global `modo_impacto`, não camada.
**ADR Version**: ADR-0002 2026-11-16; ADR-0010 2026-11-16; ADR-0011 2026-11-16; ADR-0007 2026-11-14

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: Lógica pura, testável com eventos e relógios falsos.

**Control Manifest Rules (this layer)**:
- Required: a Apresentação só lê e nunca escreve no jogo
- Forbidden: never lógica de jogo ler o `EstadoVisual`; never o Feedback aplicar opção diretamente
- Guardrail: VFX 64 draw calls (consumido via degradação, story 005)

---

## Acceptance Criteria

*From GDD `design/gdd/feedback-de-combate.md`, scoped to this story:*

- [x] AC-FB-01 [L] R1/R14 — só lê e ordena
- [x] AC-FB-04 [L] R5 — acerto marcado (flag do evento, sem contagem própria; determinístico)
- [x] AC-FB-15 [L] R8 — estrelas (7 alvos → 6 estrelas)
- [x] AC-FB-27 [L] R11 — camadas (z −5 < telégrafo < entidades < estrela < flash < número < marca < letreiro; impact frame não é camada)

---

## Implementation Notes

*Derived from ADR-0002 and ADR-0011 §7:*

- Saída por passo: pedidos tipados que a Apresentação aplica — VFX, `PedidoImpacto(modo, impact_passos)`, `PedidoPasse(tipo)`, `PedidoFlashTelegrafo(area_somada)`, `PedidoDeSom` (ADR-0016) e impulso de câmera.
- Arrays de saída pré-alocados; o árbitro não guarda referência a sistema de jogo.

---

## Out of Scope

- Story 003 preempção/câmera; 004 números; 005 degradação; 006 relógios/opções; 007 Maldições

---

## Files

- `src/presentation/feedback/arbitro_de_feedback.gd`
- `src/presentation/feedback/pedidos_de_feedback.gd`
- `tests/unit/feedback/arbitro_puro_test.gd`

Código da fatia: `src/gameplay/game_session.gd` gera efeitos como `Dictionary` lidos por `world_view.gd::_effect` — **substituir** pela lista de eventos do orquestrador e pelo árbitro.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/feedback/arbitro_puro_test.gd` — must exist and pass
**Status**: [x] Complete (`tests/unit/feedback/arbitro_e_preempcao_test.gd`, `production/qa/evidence/feedback-combate-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/feedback-de-combate/story-001-feedback-tuning-e-catalogo-de-respostas.md`; `production/epics/combate-nucleo/EPIC.md` (evento `acerto` com flag, ADR-0010)
- Unlocks: stories 003–008 deste épico
