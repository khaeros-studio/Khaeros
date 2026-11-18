# Story 005: Fluxo da limpeza (R2): ordem, morte, santuário e fim da run

> **Epic**: Portas e recompensas
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/portas-e-recompensas.md` (R2, R2-P passos 0, 1, 1b, 2, 3; States and Transitions)
**Requirement**: `TR-portas-002`, `TR-portas-003`, `TR-portas-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição (§3, §4); ADR-0001: Orquestrador do passo; ADR-0002: Canal de eventos; ADR-0012: UI e HUD
**ADR Decision Summary**: as Portas processam `camara_limpa` (item 10): (0) Run fora de `ATIVA` → nada (morte vence a limpeza pela ordem do passo, sem flag extra); (1) santuário → abre portas; (1b) `run.proxima(i) == FIM_DA_RUN` → nada, a Run trata a vitória; (2) concede; bênção → `pedir_oferta`, pedem `BENCAO` e esperam `tela_fechada`/`bencao_escolhida`; (3) abre as portas. Estados só por `pedir_estado`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: HIGH
**Engine Notes**: lógica pura `RefCounted`; risco HIGH herdado do ADR-0001/0002/0012 (orquestrador e UI). Eventos são subclasses tipadas de `EventoDoPasso` (`@abstract`, 4.5+) com `tipo()` de `return` explícito.

**Control Manifest Rules (this layer)**:
- Required: Portas consultam `run.ativa()` antes de conceder (ADR-0015)
- Required: módulos nunca trocam o estado; chamam `pedir_estado(novo)` (ADR-0001)
- Required: reação a evento de item anterior lê `do_tipo()`; a produtor do mesmo item ou posterior, chamada direta (ADR-0002)
- Forbidden: `SceneTree.paused`

---

## Acceptance Criteria

*From GDD `design/gdd/portas-e-recompensas.md`, scoped to this story:*

- [x] **AC-PR-02 / AC-PR-25** Recompensa `bencao`: ordem = `recompensa`, `pedir_oferta(região, índice)` (as Portas não abrem a tela), `bencao_escolhida` só aceita depois de `tela_fechada`, e só então as portas abrem.
- [x] **AC-PR-23** `jogador_morreu` e `camara_limpa` no mesmo passo (recompensa `fragmentos`): nenhum `creditar`, nenhum `pedir_oferta`, nenhuma porta; a Run encerra com morte.
- [x] **AC-PR-06 / AC-PR-30** Santuário limpo: nenhuma recompensa, as portas abrem. `camara_limpa(4, chefe)` do índice 6 (abate, Pactuar ou Exorcizar): nenhum `recompensa`, `pedir_oferta`, `creditar` pelas Portas, nenhuma porta; a Run responde `fim_da_run`.
- [x] **AC-PR-31** Porta `fragmentos` escolhida depois do índice 4: ao limpar o índice 5 (p 4), `recompensa(fragmentos, 3)` sai e depois abre 1 porta `chefe`. (AC-PR-24 antigo — índice 5 como fim — vale só com a `RegionDef` dublê de 6 câmaras.)

---

## Implementation Notes

*Derived from ADR-0015 §3–§4 Implementation Guidelines:*

- Máquina das Portas: `OCIOSA → CONCEDENDO → AGUARDANDO_BENCAO → (AGUARDANDO_PACTO, story 006) → PORTAS_ABERTAS`, com tabela de transição explícita.
- `bencao_escolhida` fora de `AGUARDANDO_BENCAO` ou antes de `tela_fechada` é ignorado.
- Testes com orquestrador e canal reais (ou falsos que registram a ordem) e dublês de Run, Câmaras, Bênçãos e Economia; sem SceneTree.

---

## Out of Scope

- Story 006: espera do pacto (passo 2b).
- Épico `run-e-regioes` story 006: o lado da Run na vitória.

---

## Files

- `src/gameplay/portas/portas.gd` (máquina de estados e handler de `camara_limpa`)
- `src/gameplay/portas/eventos_de_portas.gd` (`EvRecompensa`, `EvPortasAbertas`)
- `tests/unit/portas/portas_fluxo_limpeza_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/portas/portas_fluxo_limpeza_test.gd` — must exist and pass.

**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/portas-e-recompensas/story-003-portas-forcadas-e-chaves.md`, `production/epics/portas-e-recompensas/story-004-conceder-recompensa.md`, `production/epics/run-e-regioes/story-001-maquina-de-estados-da-run.md`; épicos `production/epics/orquestrador-do-passo/EPIC.md`, `production/epics/camaras-e-ondas/EPIC.md` (emissora de `camara_limpa`)
- Unlocks: `production/epics/portas-e-recompensas/story-006-aguardando-pacto.md`, `production/epics/portas-e-recompensas/story-007-escolha-da-porta.md`, `production/epics/run-e-regioes/story-006-vitoria.md`

**Código da fatia**: `game_session.gd` abre bênção ao fim da onda sem portas; essa lógica é **substituída** (não migrar).
