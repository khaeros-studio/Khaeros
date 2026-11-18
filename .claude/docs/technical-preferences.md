# Technical Preferences

<!-- project.yaml at the repo root is the machine-readable source of truth for
     engine, specialists, naming, performance, platform, and testing.framework.
     This file is the human-readable LEGACY FALLBACK: agents and skills resolve
     each key from project.yaml first and fall back here only when the
     project.yaml key is absent. /setup-engine dual-writes both.
     Forbidden patterns and allowed libraries are NOT migrated — they live only
     in this file. Populated by /setup-engine; updated as decisions are made. -->

## Engine & Language

- **Engine**: Godot 4.7
- **Language**: GDScript
- **Rendering**: Forward+ (2D, desktop)
- **Physics**: Godot Physics 2D

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: PC (Windows)
- **Input Methods**: Keyboard/Mouse, Gamepad
- **Primary Input**: Keyboard/Mouse (WASD move, mouse aim)
- **Gamepad Support**: Full gameplay + full remapping in the MVP (right-stick aim, auto-aim fallback); no rumble and no brand-specific button icons (see design/gdd/input-e-controle.md)
- **Touch Support**: None
- **Platform Notes**: Aim follows the mouse cursor; every action also bindable to gamepad. Boon/card choice screens must be fully usable without the mouse.

## Naming Conventions

- **Classes**: PascalCase (e.g., `PlayerController`)
- **Variables**: snake_case (e.g., `move_speed`)
- **Signals/Events**: snake_case past tense (e.g., `health_changed`)
- **Files**: snake_case matching class (e.g., `player_controller.gd`)
- **Scenes/Prefabs**: snake_case matching the file (e.g., `player_controller.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`)

## Performance Budgets

- **Target Framerate**: 60 fps
- **Frame Budget**: 16.6 ms
- **Draw Calls**: <= 500 per frame (2D, batched)
- **Memory Ceiling**: 512 MiB (texturas e recursos em runtime; alerta em 448 MiB conforme Pipeline visual R9 / ADR-0011)

## Testing

- **Framework**: gdUnit4 (installed by /test-setup)
- **Minimum Coverage**: 100% dos requisitos técnicos (400/400 TRs) e critérios de aceite de lógica/integração
- **Required Tests**: Balance formulas, gameplay systems, networking (if applicable)

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- **Sem `Autoload`/singleton para lógica de jogo**: `OrquestradorDoPasso` e todos os módulos de regra são `RefCounted` puros injetados pelo `Main` (`ComposicaoDaSessao` / `FabricaDaRun`) — ADR-0001, ADR-0013, ADR-0015.
- **Sem `SceneTree.paused` para pausar o jogo**: usar o estado de jogo próprio (`EstadoDeJogo.Valor`) no `OrquestradorDoPasso` e parada explícita na Apresentação — ADR-0001.
- **Sem `Engine.time_scale`, `Timer`, `create_timer`, `Time` ou `OS` na simulação**: o tempo de jogo é contagem inteira de passos a 60 Hz (`PASSO = 1.0 / 60.0`) — ADR-0001.
- **Sem sinais do Godot entre módulos de regra**: usar a lista tipada `EventoDoPasso` do canal de eventos e chamadas síncronas contratadas por injeção — ADR-0002.
- **Sem `randf`, `randi`, `shuffle`, `pick_random` ou `RandomNumberGenerator` na lógica**: usar `FluxoRng` determinístico de 64 bits (única exceção: função de entropia inicial da criação da run; RNG cosmético restrito a `src/presentation/`) — ADR-0005.
- **Sem gravar `.cfg` durante um passo em estado `JOGO`**: gatilhos apenas marcam o perfil como pendente; a gravação atômica (`gravar_atomico` com sequência `.old`) ocorre fora de `JOGO` via `ArmazemDeArquivos` — ADR-0013, ADR-0015.

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- **gdUnit4**: framework de testes automatizados em `res://addons/gdUnit4` (nenhum outro addon de terceiros no MVP).

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [ADR-0001: Orquestrador do passo e estados de jogo](../../docs/architecture/adr-0001-orquestrador-do-passo.md) — **Accepted** (2026-11-16)
- [ADR-0002: Canal de eventos](../../docs/architecture/adr-0002-canal-de-eventos.md) — **Accepted** (2026-11-16)
- [ADR-0003: Representação de entidades e portadores](../../docs/architecture/adr-0003-entidades-e-portadores.md) — **Accepted** (2026-11-16)
- [ADR-0004: Catálogo de dados](../../docs/architecture/adr-0004-catalogo-de-dados.md) — **Accepted** (2026-11-16)
- [ADR-0005: RNG determinístico](../../docs/architecture/adr-0005-rng-deterministico.md) — **Accepted** (2026-11-16)
- [ADR-0006: Input por passo](../../docs/architecture/adr-0006-input-por-passo.md) — **Accepted** (2026-11-16)
- [ADR-0007: Cena, viewport e câmera](../../docs/architecture/adr-0007-cena-viewport-e-camera.md) — **Accepted** (2026-11-16)
- [ADR-0008: Movimento e colisão própria](../../docs/architecture/adr-0008-movimento-e-colisao-propria.md) — **Accepted** (2026-11-16)
- [ADR-0009: Atributos e modificadores](../../docs/architecture/adr-0009-atributos-e-modificadores.md) — **Accepted** (2026-11-16)
- [ADR-0010: Resolução do combate no passo](../../docs/architecture/adr-0010-resolucao-do-combate-no-passo.md) — **Accepted** (2026-11-16)
- [ADR-0011: Pipeline visual](../../docs/architecture/adr-0011-pipeline-visual.md) — **Accepted** (2026-11-16)
- [ADR-0012: UI e HUD](../../docs/architecture/adr-0012-ui-e-hud.md) — **Accepted** (2026-11-16)
- [ADR-0013: Persistência do MVP](../../docs/architecture/adr-0013-persistencia-do-mvp.md) — **Accepted** (2026-11-16)
- [ADR-0014: Telégrafos: geometria de acerto e teto 24](../../docs/architecture/adr-0014-telegrafos-geometria-e-teto.md) — **Accepted** (2026-11-16)
- [ADR-0015: Ciclo da run e composição](../../docs/architecture/adr-0015-ciclo-da-run-e-composicao.md) — **Accepted** (2026-11-16)
- [ADR-0016: Áudio: ganchos e vozes](../../docs/architecture/adr-0016-audio-ganchos-e-vozes.md) — **Accepted** (2026-11-16)
- [ADR-0017: Aliados e invocações](../../docs/architecture/adr-0017-aliados-e-invocacoes.md) — **Accepted** (2026-11-16)
- [ADR-0018: IA de inimigos e chefe](../../docs/architecture/adr-0018-ia-de-inimigos-e-chefe.md) — **Accepted** (2026-11-16)

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist (all .gd files)
- **Shader Specialist**: godot-shader-specialist (.gdshader files, VisualShader resources)
- **UI Specialist**: godot-specialist (no dedicated UI specialist — primary covers all UI)
- **Additional Specialists**: godot-gdextension-specialist (GDExtension / native C++ bindings only)
- **Routing Notes**: Invoke primary for architecture decisions, ADR validation, and cross-cutting code review. Invoke GDScript specialist for code quality, signal architecture, static typing enforcement, and GDScript idioms. Invoke shader specialist for material design and shader code. Invoke GDExtension specialist only when native extensions are involved.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row says [TO BE CONFIGURED], fall back to Primary for that file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.gd files) | godot-gdscript-specialist |
| Shader / material files (.gdshader, VisualShader) | godot-shader-specialist |
| UI / screen files (Control nodes, CanvasLayer) | godot-specialist |
| Scene / prefab / level files (.tscn, .tres) | godot-specialist |
| Native extension / plugin files (.gdextension, C++) | godot-gdextension-specialist |
| General architecture review | godot-specialist |
