# Story 003: Padrões 0 (Garra) e 1 (Irrupção) com alvo travado

> **Epic**: Chefes
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/chefes.md` (R3, R4, R5.1, R5.2; F1, F2)
**Requirement**: `TR-chefes-004`, `TR-chefes-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014: Telégrafos: geometria e teto; ADR-0018 (§4, §8); ADR-0010: Resolução do combate no passo
**ADR Decision Summary**: mira travada em `iniciar_telegrafo`, nunca reescrita; teste de acerto e vista saem do mesmo `FormaDeTelegrafo`; cada golpe testa só o alvo travado e chama só o `ferir_*` da facção dele; alvo ausente falha no vazio. Retângulo dimensionado pelo raio do alvo travado; cancelamento na `TransicaoFase` e no abate.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: LOW
**Engine Notes**: vetor zero vira `(1, 0)` por teste explícito de `length_squared() == 0` (ADR-0014).

**Control Manifest Rules (this layer)**:
- Required: mira travada; teste de acerto via `GeometriaDeAcerto` (ADR-0014)
- Forbidden: o golpe percorrer "todos os jogadores"; conta de forma na IA fora do adaptador

---

## Acceptance Criteria

*From GDD `design/gdd/chefes.md`, scoped to this story:*

- [x] **AC-CH-04** `Aproximacao`, `padrao = 0`, `timer = 0`, jogador a 150 px em (0, 1): após 30 passos de preparo o `setor` (R 165 px, 78,46°) dispara, 16 de dano se o jogador continuar no setor; 10 passos de `Execucao`; `Recuperacao` 60 passos (Fase 1), `padrao = 1`.
- [x] **AC-CH-05** Padrão 1 a 400 px: preparo 36, avanço de 24 passos a 11,25 px/passo (270 px, ignora lentidão do Selo), contato (`dist < 72`) fere no máximo 1 vez com 18; `Recuperacao` 75, `padrao = 2`.
- [x] **AC-CH-06** Avanço contra o pilar em (390; 300): no 10º passo, o corpo para no limite 96 px e fica ali nos 14 passos restantes, sem atravessar.
- [x] **AC-CH-11** Chefe atraído por `vulto_mudo` em (700, 400), jogador em (1200, 700): a mira do P0 aponta para a Maldição; o setor fere a Maldição (16) e não o jogador, mesmo que ele entre depois.

---

## Implementation Notes

*Derived from ADR-0018 §8 e ADR-0014:*

- Execução por funções puras por forma (setor; avanço com contato 1×). Colisão do avanço por `resolver_colisao` do ADR-0008 dentro do deslocamento.

---

## Out of Scope

- Story 004: Padrão 2. Story 005: Padrão 3.

---

## Files

- `src/gameplay/ia/padroes_do_chefe.gd`
- `tests/unit/chefes/chefes_padroes_0_1_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/chefes/chefes_padroes_0_1_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `production/epics/chefes/story-002-maquina-de-fases-do-chefe.md`; épicos `production/epics/movimento-e-esquiva/EPIC.md` (colisão própria), `production/epics/maldicoes/EPIC.md` (atração; dublê aceitável)
- Unlocks: `production/epics/chefes/story-004-padrao-2-pulso-e-radiais.md`

**Código da fatia**: teste do setor inline em `_enemy_fire` (`game_session.gd`) — **substituir** pelo `GeometriaDeAcerto` do épico `telegrafos`.
