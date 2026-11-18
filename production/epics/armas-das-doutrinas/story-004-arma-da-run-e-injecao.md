# Story 004: Arma da run — estados, injeção e telemetria

> **Epic**: Armas das Doutrinas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/armas-das-doutrinas.md` (R5, R9, States and Transitions l.295; AC l.1291, l.1330, l.1376–1401, l.1474, l.1709, l.1812)
**Requirement**: `TR-armas-003`, `TR-armas-005`, `TR-armas-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição; ADR-0009: Atributos e modificadores; ADR-0010: Resolução do combate no passo; ADR-0001: Orquestrador do passo; ADR-0002: Canal de eventos; ADR-0013: Persistência do MVP
**ADR Decision Summary**: No começo da run a `FabricaDaRun` injeta a arma: portador com `vida_max` e velocidade base, Combate com os dois `AttackDef`; estados Escolhendo → Equipada → Encerrada, arma fixa durante a run; a arma escolhida chega à Telemetria local pelo canal de eventos.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: LOW
**Engine Notes**: ADR-0015 (LOW): lógica pura; colaboradores Nulos com `return` explícito em override não-void (4.7).

**Control Manifest Rules (this layer)**:
- Required: toda criação passa por `ComposicaoDaSessao`/`FabricaDaRun`; `nova_run()` leva a `Run.fase = ESCOLHA_DE_ARMA`
- Required: a Run só troca o `EstadoDeJogo` por `pedir_estado`
- Forbidden: Autoload, `SceneTree.paused`, `reset()` em módulo de escopo de run

---

## Acceptance Criteria

- [x] AC-AR-06 [I] R9 — injeção no começo da run (l.1291)
- [x] AC-AR-10 [L] estados e arma fixa (l.1330)
- [x] AC-AR-14 [I] R5 — bênçãos de slot valem para a arma em uso (l.1376)
- [x] AC-AR-15 [L] R5 — a arma não restringe o pool (l.1390)
- [x] AC-AR-21 [I] F5 — fogo contínuo não bate na parede (l.1474)
- [x] AC-AR-36 [I] R2/R9 — a arma escolhida é a que luta (l.1709)
- [x] AC-AR-51 [I] R5 — bênçãos com a Besta (l.1812)

---

## Implementation Notes

*Derived from ADR-0015, ADR-0009 and ADR-0010:*

- `ArmaDaRun` (RefCounted, escopo de run) guarda o estado; `FabricaDaRun` lê a escolha e injeta no portador e no Combate.
- Telemetria: evento com a arma da run no canal; a Telemetria (Apresentação) grava.
- **Código da fatia**: a montagem em `src/app/main.gd` e `src/gameplay/game_session.gd` — **substituir** pela `FabricaDaRun` (épico `run-e-regioes`).

---

## Out of Scope

- Story 005: preferência `ultima_arma`; Story 007: a tela

---

## Files

- `src/gameplay/armas/arma_da_run.gd`
- `tests/unit/weapons/arma_da_run_test.gd`
- `tests/integration/weapons/injecao_da_arma_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/unit/armas/escolha_e_injecao_test.gd` — must exist and pass

**Status**: [x] Created and passing (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/armas-das-doutrinas/story-002-validacao-das-armas.md`, `production/epics/combate-nucleo/story-003-disparo-do-golpe-e-combo.md`, `production/epics/run-e-regioes/EPIC.md`, `production/epics/bencaos-tradicoes/EPIC.md`, `production/epics/telemetria-local/EPIC.md`
- Unlocks: `production/epics/armas-das-doutrinas/story-005-preferencia-ultima-arma.md`, `production/epics/armas-das-doutrinas/story-007-tela-de-escolha-de-arma.md`
