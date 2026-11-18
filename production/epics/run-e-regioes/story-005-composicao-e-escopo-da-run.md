# Story 005: Composição da sessão, EscopoDaRun e nova_run por recriação

> **Epic**: Run e regiões (ciclo da run)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/gdd/run-e-regioes.md` (R8, R8-P, R11)
**Requirement**: `TR-run-008`, `TR-run-016`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0015: Ciclo da run e composição (§1, §2, §9); ADR-0003; ADR-0005; ADR-0009; ADR-0013
**ADR Decision Summary**: `Main` fino chama `ComposicaoDaSessao.montar(deps)` uma vez; a `SessaoDeJogo` é dona dos escopos perfil > sessão > run > câmara. **Recriar, não zerar**: `nova_run()` = `escopo_run.desligar()` → soltar → `conta.nova_run()` → `Run.fase = ESCOLHA_DE_ARMA` → `pedir_estado(MENU)`. Saldo, perfil e registro de pactos ficam fora do reset.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (4.7.2 instalado) | **Risk**: LOW
**Engine Notes**: verificar em 4.7.2 que nenhuma classe é autoload (`project.godot` sem `[autoload]` de gameplay); dublês Nulos com `return` explícito.

**Control Manifest Rules (this layer)**:
- Required: só `ComposicaoDaSessao` e `FabricaDaRun` chamam `.new()` em módulos (ADR-0015)
- Required: escopo menor pode referenciar maior, nunca o contrário; sessão ouve a run por eventos
- Forbidden: autoload, `get_node` absoluto, `SceneTree.paused`, `reset()` em módulo de escopo de run

---

## Acceptance Criteria

*From GDD `design/gdd/run-e-regioes.md`, scoped to this story:*

- [x] **AC-RN-19** Com saldo 11 e Fluxo, bênçãos e abates ≠ 0, após `nova_run`: saldo 11; 0 inimigos, 0 Selos, 0 status, 0 bênçãos, Fluxo = `fluxo_max` (100), abates 0, duração 0.
- [x] **AC-RN-20** A segunda run recebe outra seed do provedor e cada fluxo recomeça do estado derivado dela.
- [x] **AC-RN-36** Run de Pactos que pactuou o chefe, saldo 30, `nova_run`: saldo 30, dupla e Maldições zeradas, chefe ausente, e o dublê de Vínculo ainda lista `soberano_do_limiar` como pactuado.
- [x] **AC-RN-26** O sistema roda com os dublês, sem SceneTree. (ADR-0015 Validation: o `EscopoDaRun` antigo é liberado — `WeakRef` nulo.)

---

## Implementation Notes

*Derived from ADR-0015 §1–§2, §9 e Migration Plan:*

- Criar `src/app/composicao_da_sessao.gd`, `src/gameplay/sessao_de_jogo.gd`, `src/gameplay/run/escopo_da_run.gd`, `fabrica_da_run.gd`.
- `_init` que recebe `null` troca pela Nula e avisa o relator uma vez.
- `Main` em `_ready()` monta a sessão; `_physics_process` → `orquestrador.passo_fisico()` → `sessao.gravar_se_pendente(estado)`.

---

## Out of Scope

- Story 010: gravação do perfil e saída do jogo.
- Épico `orquestrador-do-passo`: extração do passo.

---

## Files

- `src/app/composicao_da_sessao.gd`, `src/app/main.gd` (adaptar)
- `src/gameplay/sessao_de_jogo.gd`
- `src/gameplay/run/escopo_da_run.gd`, `src/gameplay/run/fabrica_da_run.gd`
- `tests/integration/run/run_nova_run_test.gd`

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/run/run_nova_run_test.gd` — must exist and pass.

**Status**: [x] Created and verified (2026-11-18)

---

## Dependencies

- Depends on: `production/epics/run-e-regioes/story-004-inicio-da-run.md`; épicos `production/epics/orquestrador-do-passo/EPIC.md`, `production/epics/economia-de-fragmentos/EPIC.md` (`ContaFragmentos`), `production/epics/persistencia/EPIC.md` (`PerfilNulo`)
- Unlocks: `production/epics/run-e-regioes/story-006-vitoria.md`, `production/epics/run-e-regioes/story-010-perfil-e-saida-do-jogo.md`

**Código da fatia**: `src/gameplay/game_session.gd` — **substituir** pela composição (manter a fatia jogável por trás do `Main` até a troca; os testes de `tests/integration/run_gameplay.gd` são reescritos contra a `SessaoDeJogo`). `src/app/main.gd` — **adaptar** a nó fino. `movement.gd`, `game_input.gd`, `game_camera.gd`, `game_hud.gd`, `world_view.gd` passam a ser montados pela composição (adaptação deles é dos seus épicos).
