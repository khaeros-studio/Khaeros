# Story 006: Main como composição fina, project.godot e foco da janela

> **Epic**: orquestrador-do-passo
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `docs/architecture/adr-0001-orquestrador-do-passo.md` (sem GDD)
**Requirement**: nenhum TR próprio. Sustenta TR-input-008, TR-run-005.

**ADR Governing Implementation**: ADR-0001: Orquestrador do passo e estados de jogo
**ADR Decision Summary**: `Main` é nó fino na cena raiz, sem `Autoload`; constrói módulos na ordem de inicialização, injeta por `configurar()` antes de `add_child` dos nós de Apresentação e só repassa `_physics_process` e `_process`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: chaves `physics/common/*` NOT SOURCEABLE até EX-0001-1; `_ready()` dos filhos roda antes do pai; notificação de foco conforme EX-0001-5.

**Control Manifest Rules (this layer)**:
- Required: passo de 1/60 s numa constante única validada contra `Engine.physics_ticks_per_second` em `Main._ready()` (divergência falha de forma ruidosa); `physics_ticks_per_second = 60` e `max_physics_steps_per_frame` explícitos no `project.godot`; perda de foco e desconexão do gamepad ativo viram `pedir_estado(PAUSA)` em JOGO; ordem de consumidores Telemetria, HUD, Feedback, Telas, Áudio registrada pelo `Main`.
- Forbidden: `Autoload`; lógica de jogo no `Main`; `_physics_process` em módulos.
- Guardrail: `Main` não passa de repasse e composição.

---

## Acceptance Criteria

*Do ADR-0001 (Implementation Guidelines); sem GDD:*

- [ ] `project.godot` declara `physics/common/physics_ticks_per_second = 60` e `max_physics_steps_per_frame` com o valor decidido em EX-0001-1.
- [ ] Com `physics_ticks_per_second` divergente da constante, `Main._ready()` falha com mensagem ruidosa (teste com valor injetado).
- [ ] Os módulos recebem `configurar()` antes de `add_child` dos nós de Apresentação (teste de ordem com nó de Apresentação falso que lê a dependência em `_ready`).
- [ ] Perda de foco com estado `JOGO` resulta em `PAUSA`; com `BENCAO`, idem; em `MENU` não muda (usando a notificação de EX-0001-5).
- [ ] `Main` não é `Autoload` (checagem do `project.godot`) e não declara lógica de regra.
- [ ] Os consumidores da lista são registrados na ordem do ADR-0002/0016.

---

## Implementation Notes

**Código atual**: `src/app/main.gd` (229 linhas): **reaproveitar** como esqueleto (já é `Node`, sem Autoload, usa `_physics_process`); **substituir** o laço (`GameSession.step(sample)` e tratamento de UI em `_handle_ui`, que vai para HUD/Tela). `_notification` (foco) permanece aqui após EX-0001-5. A composição da run em si é do épico `run-e-regioes` (ADR-0015). Em debug a composição pode manter a fatia atual atrás de uma fachada até a story 007.

---

## Out of Scope

- story-007: migrar a fatia jogável; épico `input`: amostragem e contexto; épico `run-e-regioes`: composição da run.

---

## Files

- `src/app/main.gd`, `project.godot`
- `tests/integration/orquestrador/main_composicao_test.gd`

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/orquestrador/main_composicao_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `story-005-relogios-e-quadro.md`, `production/epics/experimentos-de-engine/story-001-passo-e-quadro.md`, `production/epics/experimentos-de-engine/story-003-foco-e-apresentacao.md`
- Unlocks: `story-007-migracao-da-fatia.md`

## Completion Notes

**Concluída em**: 2026-11-16 · engine-programmer (subagente, autorizado a editar `src/app/main.gd`).

**Arquivos**: `src/app/main.gd` (composição), `src/app/adaptadores_da_fatia.gd` (novo, fora da lista: os adaptadores ficam fora do `Main` para ele seguir só repasse e composição); teste `tests/integration/orquestrador/main_composicao_test.gd`. `project.godot` não precisou mudar: já declara `physics_ticks_per_second=60` e `max_physics_steps_per_frame=8` (EX-0001-1) e não tem `[autoload]`.

**Testes**: 8 casos, 8 passaram (erro ruidoso com 30/144 ticks via `Main.erro_de_passo()` estático; chaves do `project.godot` e ausência de `[autoload]`; nó de Apresentação falso vê `app` no `_ready` via `compor_apresentacao()`; foco perdido JOGO→PAUSA, BENCAO→PAUSA (e retomar volta a BENCAO), MENU não muda; ordem dos consumidores).

**Decisões**:
- `Input.use_accumulated_input = false` **não** foi posto no `Main`: a varredura do épico input (`amostra_e_movimento_test`) proíbe ler `Input` fora de `src/foundation/input`/`game_input.gd`, e o `game_input.gd` já o desliga no `_ready` (e restaura na saída). Fica com o provedor novo quando ele for ligado.
- `_ready()`: catálogo da fatia → validação do passo → `session.configure(..., relator_rng)` → Save (`carregar(true)`) → câmera → `compor_apresentacao(world)` → `_compor_passo()`.
- `_physics_process` → `orquestrador.passo_fisico()` → `save.gravar_se_pendente(orquestrador.estado())` (ponto seguro depois da entrega, persistência story 007); `_process` → `orquestrador.quadro(delta)`.
- Consumidores na ordem Telemetria, HUD, Feedback, Telas, Áudio (ADR-0002/0016) + `Save` por último (ADR-0013 §7). Só Feedback e Save têm conteúdo; os outros são nulos nomeados até os épicos donos.
- Foco perdido e desconexão do gamepad: em `jogo` **ou** `bencao` viram pausa (antes só `jogo`).
- `NOTIFICATION_WM_CLOSE_REQUEST` com `set_auto_accept_quit(false)` → `save.pedir_saida(Callable())` → `quit()`.
- Save composto com `PerfilNulo`: não existe ainda `PortaDeSecao` do vínculo, e um `RepositorioDePerfil` com porta falsa regravaria `perfil.cfg` sem a seção do vínculo (risco de perder dados do jogador). Troca para `RepositorioDePerfil(ArmazemUserGodot, ...)` quando o épico vinculo-e-pactos existir.
- `relator_rng`: `AdaptadoresDaFatia.RelatorRngPorAviso` (avisa e conta) injetado em `GameSession.configure()` (pendência do RNG story 006).

**Pendências**:
- Seed da run ainda fixa (`0x4B484145`) para a fatia ser reproduzível; `CriadorDeSeed` + `FonteDeEntropiaDoSistema` entram com a composição da run (épico run-e-regioes, ADR-0015).
- Câmera nova de `src/foundation/cena/` (`CameraDeApresentacao` + `CompositorDeCena` + camadas) **não ligada**: `game_input.sample()`, `world_view.gd` e `game_hud.gd` dependem da API da `game_camera.gd`; a troca exige dividir o `world_view.gd` por camadas (cena-e-camera story 008). Não coube nesta rodada.
- Provedor de input novo (`src/foundation/input/`) não ligado: o `game_input.gd` legado segue como fonte do item 1.
- Catálogo de `src/content/` não ligado: a fatia ainda lê `data/integration/gameplay.json`.
- `consolidar_abandono` do vínculo e a tela `PERFIL_SAIR_SEM_SALVAR` (épicos vinculo-e-pactos, hud).
