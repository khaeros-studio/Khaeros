# Story 002: Ordem do passo vivo, hitstop e transição

> **Epic**: Combate núcleo
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/combate-nucleo.md` (R1, R10, F9; AC l.2167–2258)
**Requirement**: `TR-combate-nucleo-001`, `TR-combate-nucleo-002`, `TR-combate-nucleo-011`, `TR-combate-nucleo-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010: Resolução do combate no passo; ADR-0001: Orquestrador do passo e estados de jogo; ADR-0011: Pipeline visual (só o quadro de `progresso_wipe >= 0,5`)
**ADR Decision Summary**: Os 10 itens do passo vivo rodam em ordem fixa, só no estado Jogo; hitstop é um contador de passos (vale o maior) que congela a partir do passo seguinte, nunca `Engine.time_scale`; a transição executa seis ações em ordem no quadro da metade do wipe; câmara limpa só é avaliada com hitstop em 0.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: HIGH
**Engine Notes**: ADR-0001: `@abstract` na base `Passo` (4.5); verificar ordem `_physics_process`/`_process` e `max_physics_steps_per_frame` (NEEDS VERIFICATION no ADR-0001). A lógica do Combate em si é aritmética pura (risco baixo).

**Control Manifest Rules (this layer)**:
- Required: hitstop só nas origens da tabela R10; `pedir_hitstop(n)` é privado e faz `max`
- Required: Combate respeita a ordem da tabela da seção 2 do ADR-0010
- Forbidden: `Engine.time_scale`, `SceneTree.paused`, `Timer`

---

## Acceptance Criteria

- [x] AC-05 [I] R1 — ordem do passo (l.2167)
- [x] AC-06 [L] R10 — o passo do pedido termina; os seguintes congelam (l.2175)
- [x] AC-07 [L] R10/F9 — tabela do hitstop (l.2182)
- [x] AC-08 [L] F9/F1 — combo da Lâmina num Eco (l.2199)
- [x] AC-09 [L] R10 — o congelado não desconta (l.2207)
- [x] AC-10 [L] R1/R10 — câmara nova zera (l.2223)
- [x] AC-95 [L] R10 — câmara limpa espera o hitstop (l.2235)
- [x] AC-96 [L] R1 — ordem da metade do wipe e fora de Jogo (l.2241)
- [x] AC-11 [I] R10 + Input R6 — buffer congelado (l.2251)

---

## Implementation Notes

*Derived from ADR-0010 and ADR-0001:*

- O Combate expõe os itens 3, 5, 7-impacto, 8 e 9 como métodos chamados pelo orquestrador na ordem fixa; não chama outros módulos fora dessa ordem.
- `pedir_hitstop(n)` privado, `contador = max(contador, n)`; o passo do pedido termina inteiro; os seguintes chamam `passo_congelado()` dos módulos.
- `hitstop_ativo()`/consulta de câmara limpa só verdadeira com contador em 0 (contrato com Câmaras e Run).
- Transição: as seis ações em ordem no quadro em que `progresso_wipe >= 0,5`; fora de Jogo nada desconta.
- **Código da fatia**: o laço de `src/gameplay/game_session.gd` e o hitstop de `src/app/main.gd` — **substituir** pela ordem do orquestrador; `main.gd` fica com o épico `orquestrador-do-passo`.

---

## Out of Scope

- Story 003: disparo do golpe (item 5)
- Épico `orquestrador-do-passo`: a máquina de estados de jogo e o relógio de 60 Hz

---

## Files

- `src/gameplay/combate/combate.gd` (itens do passo, contador de hitstop)
- `tests/unit/combat/hitstop_test.gd`
- `tests/integration/combat/ordem_do_passo_test.gd` (AC-05, AC-11)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/combat/hitstop_test.gd` — must exist and pass; AC-05/AC-11 em `tests/integration/combat/ordem_do_passo_test.gd`

**Status**: [x] Complete (`src/gameplay/combate/combate.gd`, `tests/unit/combat/hitstop_test.gd`, `production/qa/evidence/combate-nucleo-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/combate-nucleo/story-001-combat-tuning-e-esqueleto.md`, `production/epics/orquestrador-do-passo/EPIC.md`, `production/epics/input/EPIC.md` (buffer, AC-11)
- Unlocks: `production/epics/combate-nucleo/story-003-disparo-do-golpe-e-combo.md`, `production/epics/selo-e-fluxo/story-002-fluxo.md`
