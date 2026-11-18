# Story 006: Lint de CI contra RNG proibido e troca do RNG da fatia

> **Epic**: RNG com seed
> **Status**: Done
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-16

## Context

**GDD**: `design/gdd/rng-com-seed.md`
**Requirement**: `TR-rng-001`, `TR-rng-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: RNG determinístico
**ADR Decision Summary**: As APIs aleatórias da engine são proibidas no código de jogo, com lint de CI sobre `.gd` e scripts embutidos; RNG cosmético fica só em `src/presentation/` e nunca lê a fonte de fluxos. "A criação do lint acompanha o primeiro código de produção de RNG."
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7 (pin 4.7.2) | **Risk**: LOW
**Engine Notes**: O verificador deve reconhecer comentários e literais para localizar chamadas reais; scripts embutidos em `.tscn` e `.tres` entram no escopo.

**Control Manifest Rules (this layer)**:
- Required: RNG de cosméticos em `src/presentation/`, e nenhuma regra lê o resultado (ADR-0005)
- Forbidden: `RandomNumberGenerator`, `randf`/`randi`/`shuffle`/`pick_random` na lógica; única exceção a função de entropia da criação da run (ADR-0005)
- Guardrail: o relatório traz o número de arquivos varridos (> 0); varredura de zero arquivos é NOT ASSESSED, não aprovação

---

## Acceptance Criteria

*From GDD `design/gdd/rng-com-seed.md`, scoped to this story:*

- [x] **AC-32** Escopo: `*.gd` mais scripts embutidos em `*.tscn` e `*.tres` sob `src/`, exceto `src/presentation/`; padrões `\brandf\(`, `\brandi\(`, `randf_range`, `randi_range`, `randfn`, `rand_from_seed`, `\brandomize\(`, `\bseed\(`, `RandomNumberGenerator`, `\.shuffle\(`, `\.pick_random\(` e `hex_to_int` no parse; única exceção o ponto de entropia da R2; 0 ocorrências, com o número de arquivos varridos (> 0) no relatório
- [x] **AC-32 (fixture)** Uma fixture com uma violação plantada é detectada (o lint falha na fixture)
- [x] **AC-32 (apresentação)** Em `src/presentation/` nenhuma referência à fonte de fluxos
- [x] O RNG próprio de espera da IA em `src/gameplay/game_session.gd` é substituído por um fluxo `ia` da fonte (story 003) ou por um dublê injetado, de modo que o lint passe sobre a fatia (verificado pelo AC-32)

---

## Implementation Notes

*Derived from ADR-0005 (Decision: Seed, telemetria e fronteira da apresentação):*

O CI verifica as chamadas proibidas do AC-32 em GDScript e em scripts embutidos de cenas e recursos, com uma exceção localizada para a função de entropia da criação da run (story 004). O verificador distingue comentários e literais de chamadas reais e é testado com uma violação inserida em fixture. Código atual da fatia: `game_session.gd` tem RNG próprio só para a espera da IA, a **substituir** (nada a reaproveitar); o ritmo da IA real vem do épico ia-de-inimigos-e-elites, então aqui basta trocar a fonte sem mudar o comportamento observado da fatia (conferir com `tests/integration/run_gameplay.gd`).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: a função de entropia permitida
- Épico ia-de-inimigos-e-elites: a IA real que consome `ia`

---

## Files

- `tools/ci/lint_rng.gd`
- `tests/integration/rng/lint_rng_test.gd`
- `tests/integration/rng/fixtures/violacao_plantada.gd`
- `src/gameplay/game_session.gd` (trocar o RNG da espera da IA)

---

## QA Test Cases

N/A — no qa-lead specs at this tier (QL-STORY: skipped — lean); implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/rng/lint_rng_test.gd` — must exist and pass

**Status**: [x] Criado e passando (8/8)

---

## Dependencies

- Depends on: `production/epics/rng/story-003-fonte-de-fluxos-posse-e-ciclo-de-vida.md`, `production/epics/rng/story-004-seed-da-run-texto-e-entropia.md`
- Unlocks: None

## Completion Notes

**Concluida em**: 2026-11-16 (gameplay-programmer, sem commit)

- Criados: `tools/ci/lint_rng.gd` (SceneTree sem `class_name`; funções estáticas testáveis; exit 0 OK, 1 violação, 2 NOT ASSESSED com zero arquivos), `tests/integration/rng/lint_rng_test.gd`, `tests/integration/rng/fixtures/violacao_plantada.gd` (1 chamada real + iscas em comentário, texto e texto triplo).
- Editados: `src/gameplay/game_session.gd` (só a troca do RNG: o gerador próprio `_rng_state`/`_imul` saiu; `start()` cria uma `FonteDeFluxos` por run com a seed da sessão e a espera da IA consome `FluxosDeIa.ia(0, 0).inteiro(n)`; `configure()` ganhou o parâmetro opcional `relator_rng`, com relator padrão interno via `push_warning`); `.github/workflows/tests.yml` (passo "Lint RNG (AC-32)" que baixa o Godot 4.7.2 Linux e roda o lint).
- Resultado do lint no projeto real: arquivos_varridos=131, violacoes=0, isentos=1 (`src/foundation/rng/fonte_de_entropia_do_sistema.gd`), apresentacao_varridos=5.
- Testes: lint_rng_test 8/8; suites rng (unit+integration) 76/76 sem erros; `run_gameplay.gd` 35/35, `run_app.gd` 9/9, `run_ui_flow.gd` 23/23.
- Decisoes: comentários e literais são apagados antes da busca (em `src/presentation/` os literais contam, para pegar `preload` da fonte); `\bseed\(` conta só a função global — `func seed(` e `.seed(` (método de `FonteDeFluxos`) não contam; `hex_to_int` é proibido em todo o escopo; a isenção é por arquivo exato. Região/profundidade (0, 0) para a câmara única da fatia.
- Observação: a sequência da espera mudou (fluxo derivado em vez da seed crua), então a partida roteirizada de `run_gameplay.gd` termina igual (vitória, 13 abates), mas com HP 92 em vez de 100 e 1020 passos em vez de 1001; nenhuma verificação depende disso.
- Pendencias: (1) o ponto de composição (`src/app/main.gd`, não editado) deve injetar um relator real em `configure()`; (2) a URL de download do Godot no passo de CI não foi exercitada localmente — confirmar na primeira execução do workflow; (3) a IA real que consome `ia` fica no épico ia-de-inimigos-e-elites.
