# Story 007: Migrar a fatia jogável para o orquestrador e para eventos tipados

> **Epic**: orquestrador-do-passo
> **Status**: Done — com pendências
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `docs/architecture/adr-0001-orquestrador-do-passo.md` §Migration Plan; `adr-0002` §Migration Plan
**Requirement**: nenhum TR próprio (épico sem TR).

**ADR Governing Implementation**: ADR-0001: Orquestrador do passo e estados de jogo (+ ADR-0002, ADR-0003)
**ADR Decision Summary**: No épico de Foundation, extrair o `OrquestradorDoPasso` de `GameSession`: primeiro a ordem do passo e o final comum com os testes da fatia passando, depois cada item para o módulo dono; os textos de `Array[String]` viram subclasses de `EventoDoPasso`.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: a fatia de 2026-11-14 antecede o aceite dos ADRs; nada dela entra sem conferência contra eles.

**Control Manifest Rules (this layer)**:
- Required: ordem do passo do orquestrador; eventos tipados; Apresentação só lê.
- Forbidden: lógica nova fora dos módulos donos; `Array[String]` como canal de eventos.
- Guardrail: a fatia continua jogável durante a troca (índice de épicos).

---

## Acceptance Criteria

*Do ADR-0001/0002 Migration Plan; "a fatia continua jogável" do `production/epics/index.md`:*

- [ ] `GameSession.step()` passa a ser chamado pelo orquestrador como um módulo `Passo` (ou fatiado em módulos), na ordem do ADR-0001; os testes atuais (`tests/integration/run_gameplay.gd`, `run_app.gd`, `run_ui_flow.gd`, `run_catalog.gd`, `run_input_camera.gd` e `tests/unit/smoke/playable_integration_test.gd`) seguem passando.
- [ ] Os textos que `step()` devolvia (`Array[String]`) são emitidos como subclasses de `EventoDoPasso` e o `Main`/`WorldView`/`GameHud` os leem da lista entregue.
- [ ] O hitstop local (`hitstop`, `_pending_hitstop`) é consultado pelo orquestrador por `hitstop_ativo()` e some do laço do `Main`.
- [ ] Screenshot da fatia rodando (arena, jogador, inimigos, HUD) retido em `production/qa/evidence/` mostrando que nada regrediu.
- [ ] Nenhum arquivo da fatia usado sem conferência: cada item migrado cita o ADR que o autoriza no cabeçalho do arquivo.

---

## Implementation Notes

**Código atual a tratar**: `src/gameplay/game_session.gd`: **adaptar** (envolver como módulo `Passo`, depois extrair item a item para os donos nos épicos `movimento-e-esquiva`, `combate-nucleo`, `ia-de-inimigos-e-elites`); `src/gameplay/movement.gd`: **reaproveitar** como adaptador até o épico de Movimento; `src/foundation/game_input.gd`: **reaproveitar** até o épico `input`; `src/presentation/game_camera.gd`, `game_hud.gd`, `world_view.gd`: **reaproveitar** lendo eventos tipados (sua troca é dos épicos `cena-e-camera`, `hud`, `pipeline-visual`); `src/foundation/session_catalog.gd`: tratado no épico `conteudo`. Rodar a fatia, observar e salvar a captura (regra do projeto: parse check não é run).

---

## Out of Scope

- Reescrever cada módulo (épicos dos donos); trocar HUD/câmera/arte (épicos de Apresentação).

---

## Files

- `src/gameplay/game_session.gd`, `src/app/main.gd`, `src/presentation/world_view.gd`, `game_hud.gd`, `game_camera.gd` (leitura de eventos)
- `tests/integration/orquestrador/migracao_da_fatia_test.gd`
- `production/qa/evidence/orquestrador-migracao-da-fatia.png`

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/orquestrador/migracao_da_fatia_test.gd` e a captura retida acima.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `story-002-entidades-e-identidade.md`, `story-004-ordem-do-passo.md`, `story-006-main-composicao.md`
- Unlocks: épicos `modificadores`, `movimento-e-esquiva`, `combate-nucleo`

## Completion Notes

**Concluída em**: 2026-11-16 · engine-programmer (subagente).

**Arquivos**: `src/gameplay/eventos_da_fatia.gd` (novo: `EventosDaFatia.EvComandoExecutado`, `EvGolpeSentido`, subclasses de `EventoDoPasso`), `src/app/adaptadores_da_fatia.gd` (novo), `src/app/main.gd`; teste `tests/integration/orquestrador/migracao_da_fatia_test.gd`; captura `production/qa/evidence/orquestrador-migracao-da-fatia.png` (janela real, `--qa-capture=jogo`: arena, jogador, inimigos e HUD; a mesma execução regravou `production/qa/evidence/integracao-jogavel/jogo.png`).

**Testes**: 6 casos, 6 passaram (passo vivo chama `step()` uma vez por passo e conta `passos_em_jogo`/`n_vivos`; hitstop da fatia consultado por `hitstop_ativo()` congela e desconta; pausa não avança a regra; textos viram eventos tipados e o comando é consumido; Movimento congela só fora de JOGO; espelho de estados pela tabela do ADR-0001). Scripts da fatia: `run_app` 9/0, `run_gameplay` 35/0, `run_ui_flow` 23/0, `run_catalog` 38/0, `run_input_camera` 32/0 (checks/falhas).

**Decisões** (ADR-0001/0002 §Migration Plan, ADR-0003):
- `GameSession.step()` é chamado só pelo orquestrador, num ponto por passo: vivo = módulo `combate_inicio` (`PassoDaFatia`); hitstop = `HitstopDaFatia.passo_congelado_do_combate()` (o `step()` desconta, ADR-0001 decisão 4); fora de JOGO = `MovimentoDaFatia.passo_congelado()`. Os outros 8 módulos são `PassoVazio` até os épicos donos extraírem cada item.
- O hitstop sumiu do laço do `Main`; o orquestrador o consulta por `hitstop_ativo()`.
- Os `Array[String]` de `step()` viram `EvComandoExecutado` na lista do passo; o impulso de câmera que o `Main` calculava por diferença de vida virou `EvGolpeSentido`, lido pelo consumidor Feedback (`FeedbackDaFatia`). A API de `step()` foi mantida (os scripts da fatia a chamam direto).
- A fatia segue dona do texto de estado; `AdaptadoresDaFatia.espelhar()` leva o orquestrador ao mesmo estado só por pedidos válidos da tabela (busca em largura; `vitoria` → MENU). Fachada transitória.
- Pedido de pausa colhido no item 1 pausa a sessão antes da regra (o passo congela, como antes).

**Pendências**:
- A autoridade de estado ainda é da `GameSession`; virar o orquestrador dono (e o `_handle_ui` ir para HUD/Telas) depende dos épicos hud, tela-de-bencao-e-carta e run-e-regioes.
- `world_view.gd`/`game_hud.gd` ainda leem `app.session` direto (só o Feedback lê eventos); a troca é dos épicos de Apresentação. `game_session.gd` não foi alterado nesta story (não precisou).
