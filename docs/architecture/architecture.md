# Khaeros — Master Architecture

## Document Status
- Version: 1.13
- Last Updated: 2026-11-17 (v1.13: propagação dos experimentos EX-0001..0016 nos ADRs e em `architecture.md`, PC de referência fixado no ADR-0004 com `TR-conteudo-015` promovido a ✅ `400/400 (100%)`, e limpeza de `Open Questions`; v1.12: Doutrina de Pactos — ADRs 0015–0018 aceitos, emendas em 0001–0014, registro com 400 requisitos e revisão de 2026-11-16; v1.11: ADRs 0009–0014 propostos, revisão de 0001/0002 e revisão cruzada; v1.10: primeira fatia jogável integrada por pedido explícito; v1.9: Movimento; v1.8: Cena/câmera; v1.7: Input; v1.6: RNG; v1.5: catálogo; v1.4: entidades; v1.3: co-op; v1.2: eventos; v1.1: hitstop e orquestrador)
- Engine: Godot 4.7.2 (pin 4.7), GDScript, Forward+ (D3D12 padrão no Windows)
- Reference PC (CPU / Load Budgets): AMD Ryzen 5 5600H (6C/12T), 16 GB RAM, SSD NVMe, GPU RTX 3050 Laptop, Windows 11 Home 10.0.26300
- Review mode: lean
- GDDs Covered (26 de 26 do MVP): maldicoes, chefes, vinculo-e-pactos, save-e-perfil, conteudo-orientado-a-dados, rng-com-seed, input-e-controle, cena-3-4-e-camera, pipeline-visual, modificadores-e-atributos, movimento-e-esquiva, combate-nucleo, armas-das-doutrinas, selo-e-fluxo, efeitos-de-status, telegrafos, ia-de-inimigos-e-elites, camaras-e-ondas, portas-e-recompensas, run-e-regioes, bencaos-tradicoes, economia-de-fragmentos, hud, tela-de-bencao-e-carta, feedback-de-combate, telemetria-local
- ADRs Referenced: [ADR-0001](adr-0001-orquestrador-do-passo.md), [ADR-0002](adr-0002-canal-de-eventos.md), [ADR-0003](adr-0003-entidades-e-portadores.md), [ADR-0004](adr-0004-catalogo-de-dados.md), [ADR-0005](adr-0005-rng-deterministico.md), [ADR-0006](adr-0006-input-por-passo.md), [ADR-0007](adr-0007-cena-viewport-e-camera.md), [ADR-0008](adr-0008-movimento-e-colisao-propria.md), [ADR-0009](adr-0009-atributos-e-modificadores.md), [ADR-0010](adr-0010-resolucao-do-combate-no-passo.md), [ADR-0011](adr-0011-pipeline-visual.md), [ADR-0012](adr-0012-ui-e-hud.md), [ADR-0013](adr-0013-persistencia-do-mvp.md), [ADR-0014](adr-0014-telegrafos-geometria-e-teto.md), [ADR-0015](adr-0015-ciclo-da-run-e-composicao.md), [ADR-0016](adr-0016-audio-ganchos-e-vozes.md), [ADR-0017](adr-0017-aliados-e-invocacoes.md) e [ADR-0018](adr-0018-ia-de-inimigos-e-chefe.md), todos Accepted em 2026-11-16 (aprovação do usuário) e atualizados com as verificações `EX-0001..0016` em 2026-11-17. 18 de 18 necessários escritos (ver "Required ADRs")
- Technical Requirements Baseline: 400 requisitos permanentes em `tr-registry.yaml` (`400/400 ✅ Covered (Accepted) (100%)`, `0 🟡`, `0 ⚠️`, `0 ❌`)
- TD-ARCHITECTURE: 2026-11-13 — skipped — lean mode (nenhum diretor revisou esta arquitetura)
- LP-FEASIBILITY: 2026-11-13 — skipped — lean mode (nenhum diretor revisou esta arquitetura)

> **Limite da extração dos requisitos:** a leitura do `pipeline-visual` não cobriu Formulas (F1–F10), Edge Cases, Dependencies nem Acceptance Criteria; a dos GDDs de dados, RNG, IA, câmaras, portas, telemetria, run, bênçãos e economia não cobriu Edge Cases nem Acceptance Criteria. Requisitos dessas seções podem faltar na linha de base; `/architecture-review` revalida.

## Engine Knowledge Gap Summary

### Estado de implementação — 2026-11-14

O pedido explícito do usuário “faça a integração do jogo” autorizou avançar da preparação para uma primeira fatia executável. `scenes/main.tscn` agora é a cena inicial, com módulos novos em `src/app`, `src/foundation`, `src/gameplay` e `src/presentation`. Integra Lâmina, controles/buffer, movimento/colisão, câmera, dois inimigos, três ondas, bênçãos e telas. [Como jogar e limites](../COMO-JOGAR.md); [evidência](../../production/qa/evidence/integracao-jogavel/README.md).

Os ADRs foram aceitos em 2026-11-16; a fatia de 2026-11-14 foi feita antes do aceite e precisa ser conferida contra eles nas stories. `GameSession` é uma composição de combate/IA/ondas para a integração inicial, ainda a separar conforme os contratos completos. Dados usam JSON validado e impressão do arquivo, não o catálogo `.tres`/hash canônico; RNG próprio cobre espera de IA, não os oito fluxos. Bênçãos são explícitas, sem sistema geral de modificadores. Arte e camadas visuais são provisórias; não há Selo/Fluxo, Ressonância, áudio final, persistência ou remapeamento. O protótipo anterior foi preservado.

O modelo conhece a engine até ~4.3. Fontes: `docs/engine-reference/godot/`.

**Risco ALTO** (conferido contra a referência e verificado nos experimentos `EX-0001..0016` em 2026-11-16):
- **Rendering 2D** (pipeline-visual, cena-3-4-e-camera, feedback-de-combate): linhas de `CanvasItem` sem feather (4.7), D3D12 padrão no Windows (4.6), Shader Baker (4.5), `LinearToSRGB` sem clamp (4.7). `RenderingServer.frame_post_draw` **VERIFICADO (`EX-0010-1`)** (1× por quadro, pior caso medido `33,33 ms ≤ 50 ms`). Interpolação 2D, `reset_physics_interpolation()` no mesmo passo após teleporte e pillarbox em runtime **VERIFICADOS (`EX-0007-NV`)**.
- **UI e Input** (hud, tela-de-bencao-e-carta, input-e-controle): foco duplo mouse/teclado-gamepad (4.6); `InputEvent.device` de mouse e teclado deixa de ser `0` (4.7); `Control.offset_transform_*` e `offset_transform_visual_only = true` **VERIFICADOS (`EX-0012 E1`)**; esvaziamento de `ui_*` preservando `ui_text_*` em `LineEdit` **VERIFICADO (`EX-0012 E2`)**; barreira de retorno após `NOTIFICATION_APPLICATION_FOCUS_IN` **VERIFICADA (`EX-0012 E3` / `EX-0001-5`)**; `focus_behavior_recursive`/`mouse_behavior_recursive` **VERIFICADOS (`EX-0012 E4`)**; CSV plural/contexto com `0` singular em `pt_BR` **VERIFICADO (`EX-0012 E6`)**; `DisplayServer.clipboard_set/get` **VERIFICADO (`EX-0012 CB`)**.
- **GDScript** (todo o código): em 4.7 um `override` de método com retorno tipado herda o tipo e exige `return` explícito (**quebra**); escrita em elemento de packed array não chama o setter (4.7); `@abstract` (4.5, **VERIFICADO em `EX-0002-2`** como checagem estática que não impede `Script.new()` dinâmico); `Array[T].filter()` devolve array tipado no 4.7.2 (**VERIFICADO em `EX-0002-2`**); `float` é IEEE-754 binary64 no build padrão (**VERIFICADO em `EX-0009-1`**, `2^52 + 1.0 != 2^52`).

**Risco MÉDIO** (todos **VERIFICADOS** no 4.7.2): `Resource.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` (`EX-0004-NV`); `ResourceLoader.load(..., CACHE_MODE_IGNORE_DEEP)` (`EX-0004-NV`); `HashingContext` SHA-256 (`EX-0004-NV`); CSV `keep` exigindo `exclude_filter="assets/data/canon/*"` (`EX-0004-NV`); `FileAccess.store_line` + `flush`, sequência `.old` em `DirAccess.rename` no Windows, `ConfigFile.parse` exigindo `schema_version`, `Time` UTC + `"Z"`, `OS.shell_open` e `NOTIFICATION_WM_CLOSE_REQUEST` (`EX-0013 E-P1..P7`); interpolação de física 2D e `reset_physics_interpolation()` (`EX-0007-NV`).

**Risco BAIXO**: Physics 2D (inalterada; `physics_ticks_per_second=60`, `max_physics_steps_per_frame=8`, ordem `_physics_process` → `_process`, parada da Apresentação por `PROCESS_MODE_DISABLED`/explícita e clamp `dt_max_apres` no 1º quadro **VERIFICADOS em `EX-0001-1..6`**), Audio (`get_bus_index` `-1`, `pitch_scale > 0` faixa `0,25–4`, `stream_paused` reportando `playing == false`, `linear_to_db`, `default_bus_layout.tres`, loop WAV `edit/loop_mode=2` com `loop_end=-1` e `mix_rate` `48000 Hz` **CONFIRMADOS em `EX-0016-A`**), Animation 2D. Navigation não é usada (a IA é movimento direto, sem pathfinding).

**VERIFICADOS nos experimentos `EX-0001..0016` (2026-11-16, saíram de NOT SOURCEABLE / NEEDS VERIFICATION):**
- **Orquestrador e Foco (`EX-0001-1..6`):** VR(1), VR(2), VR(3), VR(4), VR(5) e VR(6) verificados no 4.7.2 (`NOTIFICATION_APPLICATION_FOCUS_OUT`, inexistência de `pause_on_focus_loss`, parada da Apresentação sem `SceneTree.paused`, clamp `dt_max_apres` no 1º quadro e `RenderingServer.global_shader_parameter_set` em `1,8 µs` média / `4 µs` p99 para 2 globais por quadro em `EX-0001-3`).
- **Eventos (`EX-0002-1..3`):** VR(2) e VR(3) verificados (`filter()` tipado, `@abstract` estático vs `Script.new()`, `CONNECT_DEFERRED` por ordem de conexão); VR(1) medido em debug com teto seguro de ~20 eventos/passo (`166–198 µs` p99) e fallback de pool decidido caso o binário de release ultrapasse `0,3 ms` com 50 eventos.
- **Catálogo (`EX-0004-NV`):** `HashingContext` SHA-256, `CACHE_MODE_IGNORE_DEEP`, CSV `keep` (`exclude_filter="assets/data/canon/*"` obrigatório), `Resource.DEEP_DUPLICATE_ALL` e tempo de carga síncrona (`160,8 ms` texto / `86,2 ms` `.pck` < `250 ms` no PC de referência fixado).
- **Cena e Câmera (`EX-0007-NV`):** interpolação de física 2D, `reset_physics_interpolation()` no mesmo passo após teleporte e pillarbox/letterbox em runtime (com nota de escala fracionária `2,1328 × 2,1333` em `1366×768`).
- **Aritmética (`EX-0009-1`):** `float` IEEE-754 binary64 (`2^52 + 1.0 != 2^52`, `0.1 + 0.2 == 0x3fd3333333333334`) e nota sobre literais em empate no tokenizer.
- **Latência de Combate (`EX-0010-1`):** `RenderingServer.frame_post_draw` dispara 1× por quadro; pior caso medido `33,33 ms ≤ 50 ms` (AC-92).
- **UI e Localização (`EX-0012 E1–E6, CB`):** `offset_transform_visual_only = true`, esvaziamento de `ui_*` preservando `ui_text_*`, barreira de retorno pós-foco, `focus_behavior_recursive`/`mouse_behavior_recursive`, CSV plural/contexto (`0` singular em `pt_BR`) e `DisplayServer.clipboard_set/get`.
- **Persistência e Telemetria (`EX-0013 E-P1..P7`):** `store_line` + `flush` (`p99 ≤ 1 ms/linha`, picos isolados do SO geram `TL2` benigno), sequência `.old` obrigatória em `gravar_atomico`, exigência de `schema_version` após `ConfigFile.parse == OK`, concatenação de `"Z"` em UTC, `OS.shell_open` e `NOTIFICATION_WM_CLOSE_REQUEST`.
- **Pipeline Visual (`EX-0011 E1–E7` e `EX-0001-3`):** orçamento de draw calls na cena de estresse F10 (`444 ≤ 500`, `D_g = 292`, `E1`), `global uniform sampler2D` com LUT `1024×32` (erro `≤ 1/255`, `EscritorGlobalRS` primário e `EscritorPorMaterial` fallback, `E2`), congelamento em hitstop (`speed_scale = 0`, `E3`), contorno SDF de `4 px` com malha de borda `ArrayMesh` (`-90%` área no `C120`, `E4`), `CanvasGroup` com `fit_margin = 8.0` (`E5`), quad SDF para o fio do Vínculo (`E6`) e `ShaderMaterial` próprio por entidade (`p99 = 11/22/43 µs` para 9/20/40 entidades, `E7`) **VERIFICADOS** em `prototypes/pipeline-verificacao/`.
- **Áudio (`EX-0016-A`):** itens 1–6 confirmados (`get_bus_index` `-1`, `pitch_scale` `0,25–4`, `stream_paused` com `playing == false`, `linear_to_db`, `default_bus_layout.tres`, loop WAV `edit/loop_mode=2` com `loop_end=-1`, `mix_rate` `48000 Hz`).

**Único item de infraestrutura de release ainda pendente (sem impacto na arquitetura):**
- Repetição das medições de exportação no binário `.exe` de release quando os export templates do Godot 4.7.2 forem instalados em `%APPDATA%\Godot\export_templates\` (o empacotamento `.pck` já foi verificado com `--export-pack` + `--main-pack`).

## System Layer Map

```
┌───────────────────────────────────────────────────────────────┐
│ APRESENTAÇÃO  (só lê eventos e estado; nunca escreve em jogo) │
│  HUD · Tela de bênção+carta · Feedback de combate (VFX)       │
│  Pipeline visual* · Telemetria local*     [VS: Áudio, Menus,  │
│                                            Acessibilidade]    │
├───────────────────────────────────────────────────────────────┤
│ FEATURE  (regras de jogo; lógica pura, sem SceneTree)         │
│  Armas · Selo e Fluxo · Efeitos de status · Telégrafos        │
│  IA de inimigos e elites · Câmaras e ondas · Portas           │
│  Run e regiões · Bênçãos · Economia de Fragmentos             │
│                [VS/Alpha: Chefes, Criatura, Oficina, Campus…] │
├───────────────────────────────────────────────────────────────┤
│ CORE  (o passo de simulação)                                  │
│  Modificadores e atributos · Movimento e esquiva · Combate    │
├───────────────────────────────────────────────────────────────┤
│ FOUNDATION  (integração com a engine e serviços sem dep.)     │
│  Conteúdo orientado a dados · RNG com seed · Input e controle │
│  Cena 3/4 e câmera · Orquestrador do passo**                  │
│                          [VS: Save e perfil, Localização]     │
├───────────────────────────────────────────────────────────────┤
│ PLATFORM: Godot 4.7.2 (GDScript, Forward+, D3D12 no Windows)  │
└───────────────────────────────────────────────────────────────┘
```

**Regra de dependência:** só se chama para baixo. Para cima e para os lados só há eventos (sinais) e consultas injetadas. As 5 dependências circulares do `systems-index.md` (Run↔Economia, Input↔IA, Input↔Cena, Movimento↔Combate, Combate↔IA) já estão resolvidas por contrato injetado.

**Desvios do `systems-index.md`** (o índice continua com a classificação antiga até ser atualizado):
- \* **Pipeline visual** está em Apresentação (o índice o põe em Core): é dono de shaders, LUT, passes e relógios, e nenhuma regra de jogo depende dele.
- \* **Telemetria local** é observador na Apresentação (o índice a põe em Polish): só escuta eventos e grava.
- \*\* **Orquestrador do passo** é um módulo de Foundation **sem GDD**: 8 dos 22 GDDs o pressupõem e nenhum o define. Ganha ADR próprio (0001).

Sistemas de Vertical Slice e Alpha ficam reservados no lugar do índice, sem desenho agora.

## Module Ownership

Legenda de risco: ⚠️ pós-corte (4.5+); **confirmado** = coberto por `docs/engine-reference/`.

### Foundation

| Módulo | Posse | Expõe | Consome | APIs da engine |
|---|---|---|---|---|
| **Conteúdo** | Catálogo `.tres` (13 tipos de Resource + Pactos/Áudio), validadores V1–V11, impressão SHA-256 | `obter(tipo,id)`, `listar/filtrar` (ordem do manifesto), impressão, relator de erros | Arquivos `assets/data/` | `Resource`, `ResourceLoader`; `duplicate_deep(DEEP_DUPLICATE_ALL)`, `CACHE_MODE_IGNORE_DEEP`, `HashingContext` SHA-256 e CSV `keep` (`exclude_filter` obrigatório): **VERIFICADOS (`EX-0004-NV`)** |
| **RNG** | Seed da run, estado dos fluxos (9 finalidades) | `fluxo(finalidade, região, índice)` e operações puras | Lista e impressão do catálogo, entropia injetada | Nenhuma (GDScript puro, int64; 33 checks verificados). BAIXO |
| **Input** | Amostra por passo, buffer de 10 passos, remapeamento, arquivo de binds | Amostra, `rotulo_acao`, cursor, `fonte_mira` | Consulta de alvos (IA), conversão tela→mundo (Cena), "hitstop ativo" | `Input`, `InputMap`, `InputEvent`; `device` ≠ 0 (4.7), foco duplo (4.6) e barreira de foco (`EX-0012 E2/E3`, 38 checks): **VERIFICADOS** |
| **Cena 3/4 e câmera** | Viewport, 11 camadas, câmera própria, snapshot tela→mundo | Conversão sem impulsos, bases `pos`/`pos_seguir`, geometria da vista | `t_apres` (Orquestrador), retângulo (Câmaras), posições (Movimento), impulsos (Feedback) | ADR-0007: `canvas_transform`, três faixas de stretch, parallax manual, interpolação 2D, `reset_physics_interpolation()` e pillarbox em runtime: **VERIFICADOS (`EX-0007-NV` + 67 checks)** |
| **Orquestrador do passo** *(novo, sem GDD)* | Estado de jogo (Jogo/Pausa/Bênção/Transição/Morte/Menu), ordem do passo, `t_vivo` e `t_apres` (o contador de hitstop é do Combate, R10) | Estado atual, sinal de passo, `passo()`/`passo_congelado()`, consulta `hitstop_ativo()` (delegada ao Combate) | Todos os módulos do passo | `_physics_process` a 60 Hz; retorno tipado herdado em override (4.7); sem `SceneTree.paused`; VR(1,2,4,5,6) **VERIFICADOS (`EX-0001-1..6`)**; item 6.1 Maldições (ADR-0017) |
| **Persistência / Save e perfil** | Armazém de arquivos em `user://` (gravação atômica com `.old` e `.bak`), `user://perfil.cfg` (um perfil; seção `[vinculo]` opaca), binds, preferências, opções, telemetria `.jsonl` | Repositórios por dono (`RepositorioDeBinds`, `RepositorioDePerfil`, `RepositorioDeOpcoes`, `RepositorioDePreferencias`, telemetria); gravação só fora de Jogo | Run/Ciclo da run (quando gravar), Vínculo, Input, Armas, Telemetria | `ConfigFile`, `FileAccess`, `DirAccess`, `NOTIFICATION_WM_CLOSE_REQUEST`: **E-P1..P7 VERIFICADOS (`EX-0013`)** |

### Core

| Módulo | Posse | Expõe | Consome | APIs da engine |
|---|---|---|---|---|
| **Modificadores** | Portador (atributos, modificadores, gatilhos) | `valor()`, `inteiro()`, `congelar_dano()`, `multiplicador_de_dano()`, `gatilhos()`, `aplicar/remover/avancar` | Definições (`EffectDef`, `RarityTable`) | GDScript puro (`float` IEEE-754 binary64 **VERIFICADO em `EX-0009-1`**). BAIXO |
| **Movimento** | **Única** escritora da posição do jogador, cargas de esquiva | Posição atual/anterior, "em esquiva", `deslocar`, `teleportar` | Amostra (Input), portador, geometria (Câmaras), lista de alvos (IA), contrato do Combate | Nenhuma (colisão própria; 51 checks verificados). Nó de apresentação: `Node2D` |
| **Combate núcleo** | Golpes, projéteis, empurrão, varredura de mortes, Vida do jogador, eventos | Eventos V1–V15, `ferir_jogador/inimigo/maldicao/acuada`, `disparar_projetil`, `aplicar_corte`, `subjugar` | Portador, amostra, geometria, lista de inimigos, `CombatTuning` | Matemática própria; `RenderingServer.frame_post_draw` (AC-92, `33,33 ms ≤ 50 ms`): **VERIFICADO (`EX-0010-1`)** |

### Feature (lógica pura; nenhuma usa API de engine)

| Módulo | Posse | Expõe | Consome |
|---|---|---|---|
| **Armas** | `WeaponDef`, `ArmasTuning`, arma da run | `WeaponDef` ao Modificadores, 2 `AttackDef` ao Combate | Catálogo, Run |
| **Selo e Fluxo** | Lista de Selos, `fluxo` | `no_selo()`, `fator_lentidao`, eventos `selo`/`selo_fim` | Combate (`acerto_de_arma`), Input, Modificadores |
| **Efeitos de status** | Estado por inimigo (Sangramento, Queimadura, Abalo) | `aplicar_status`, `abalado()`, `estado()` | Combate (`ferir_inimigo`), IA (lista) |
| **Telégrafos** | Lista de telégrafos (teto 24) | `iniciar_telegrafo`, estado por quadro | IA, Combate, Câmaras (geometria) |
| **IA e elites** | Fases dos inimigos, **lista de inimigos (ordem estável)**, `sortear_elite` | Lista, `sortear_elite`, consulta de alvos | Combate, Telégrafos, RNG, retângulo de vista |
| **Câmaras e ondas** | Layout, ondas, `p`, portas físicas, "em combate" | `camara_limpa(p,tipo)`, retângulo, obstáculos | IA, RNG, Orquestrador (Transição) |
| **Portas e recompensas** | `RewardTable`, recompensa pendente | `recompensa`, `pedir_oferta`, `creditar` | Câmaras, Bênçãos, RNG |
| **Run e regiões** | Máquina da run, seed, resumo | `nova_run`, `run_encerrada`, `fim_da_run` | Câmaras, Portas, Economia, RNG |
| **Bênçãos** | Pool de 18 `BoonDef`, bênçãos tomadas | `oferta_aberta`, `bencao_tomada` | Modificadores, RNG, Portas |
| **Economia** | `ContaFragmentos` (saldo, coletados) | `saldo()`, `creditar`, `saldo_mudou` | Portas, Run |
| **Maldições** (ADR-0017) | `ModuloDeMaldicoes` (item 6.1), `MaldicaoRef` da dupla, troca, técnica combinada, Chamado, reserva/Exaustão, IA de aliado | Consulta da Maldição em campo, `EvMaldicaoTrocada`/`EvTecnicaCombinada`/`EvMaldicaoFerida`/`EvMaldicaoExausta` | Input (`troca`, `ponto_mira`), Modificadores (portadores), Combate (facção ALIADO), Movimento (geometria), catálogo (`CurseDef`, `MaldicoesTuning`) |
| **Vínculo e pactos** (ADR-0015, ADR-0017) | Pontos e nível por espécie, encontro de pacto e acuada, consentimento, conteúdo da seção `[vinculo]` | `EvVinculoGanho`, `EvPactoFormado`, `EvEncontroFalhou`, fonte `vinculo:<curse_id>` | RNG (`pactos`), Combate (`ferir_acuada`), Persistência, `VinculoTuning` |
| **Chefes** (ADR-0018, ADR-0014) | Padrões do chefe (`BossPatternDef`), fases e Fúria, alvo travado, Pactuar/Exorcizar | `EvChefeSubjugado`, `EvChefeExorcizado`, telégrafos com alvo travado | IA, Telégrafos, Combate (`subjugar`), `ChefesTuning` |

### Apresentação

| Módulo | Posse | Consome | APIs da engine |
|---|---|---|---|
| **HUD** | Controls do HUD (somente leitura) | Combate, Selo, Movimento, Economia, Câmaras, Input | `Control`, `CanvasLayer`; foco duplo (4.6) e `ui_*` esvaziados **VERIFICADOS (`EX-0012`)** |
| **Tela de bênção e carta** | `CartaView`, máquina de 8 estados | Bênçãos (`oferta_aberta`), Input | `Control`; `offset_transform_visual_only = true`, barreira de retorno e `clipboard_set/get`: **VERIFICADOS (`EX-0012`)** |
| **Áudio** (ADR-0016) | Barramentos, pool de vozes, eventos→sons pela lista do passo (`SomDef`, `AudioTuning`) | Lista de eventos do passo, relógios, estado de jogo | `AudioStreamPlayer`, `AudioServer` (`get_bus_index`, `pitch_scale`, `stream_paused`, `linear_to_db`, `default_bus_layout.tres`, loop WAV): **CONFIRMADOS (`EX-0016-A`)** |
| **Feedback de combate** | Árbitro eventos→respostas, pool de VFX e números | Eventos do Combate, relógios | `GPUParticles2D`/`CPUParticles2D` (`speed_scale = 0` **VERIFICADO em `EX-0001-4`**), `AudioStreamPlayer` |
| **Pipeline visual** | Shaders (3 famílias), LUT, `shader_globals`, passes de tela, relógios `t_apres` | Região, telégrafos, estado do orquestrador | `global uniform` com sampler em `canvas_item` + Shader Baker (E2, com plano B `EscritorPorMaterial`), `CanvasGroup`, `Parallax2D`; linhas de `CanvasItem` sem feather (4.7) |
| **Telemetria** | Arquivo `.jsonl`, retenção | Eventos de Run, Bênçãos, Portas, Combate, Economia | `FileAccess.store_line` (`bool`) + `flush` (`p99 ≤ 1 ms/linha`, sobrevivência a `OS.kill`): **VERIFICADOS (`EX-0013 E-P1`)** |

### Conflitos de posse resolvidos (donos aprovados)
1. **Contador de hitstop:** o **Combate** guarda o contador (`pedir_hitstop(n)`, R10); o Orquestrador só consulta `hitstop_ativo()` e congela o passo. *(Corrigido na v1.1: a v1 dava o contador ao Orquestrador, o que contradizia o GDD de Combate; ver ADR-0001.)*
2. **`modo_bencao` (Pipeline):** o **Orquestrador** liga e desliga ao entrar e sair do estado Bênção.
3. **Lista de inimigos:** dona é a **IA**; Combate, Selo e Status só leem (ordem estável).
4. **`p_max`:** dono **Câmaras**; `ArmasTuning` guarda só alias (aviso WV8).
5. **`trocas_oferta`:** dono **`BencaosTuning.trocas_iniciais`**; Modificadores só soma.
6. **Reset do Fluxo na nova run:** estado do **Selo**; a **Run** só chama `nova_run`.
7. **Número agregado de dano de status:** o contador é do **Feedback**, não do Status.

O [ADR-0003](adr-0003-entidades-e-portadores.md) propõe estado de combatente e portador em `RefCounted`, com slots internos reutilizáveis para os telégrafos.

## Data Flow

Tudo roda na **thread principal**; nenhum fluxo cruza thread. A gravação da telemetria é síncrona (decisão do GDD).

### 1. Passo de simulação (60 Hz, só no estado Jogo)
A ordem vem do Combate R1, do Selo (item 6), do Status e dos Telégrafos (item 7) e das Câmaras (item 10). A numeração dos demais itens fica no GDD do Combate; o ADR 0001 a transcreve.

```
Orquestrador.passo()                      (síncrono, ordem fixa, 1 vez por _physics_process)
 1  Input.amostra()            → mover, mirar, apertados, buffer            [Input → todos]
 2  hitstop > 0 ?  sim → Movimento.passo_congelado(); fim do passo (nada desconta)
 3  Combate: início do passo   (recuperação, invulnerabilidade, "câmara limpa?" só com hitstop=0)
 4  Movimento.passo()          → posição (única escritora)
 5  Combate: golpe do jogador  → eventos golpe/acerto/acerto_de_arma
 6  Selo.passo()               → planta, fere por Selo (ferir_inimigo silencioso)
 7  Inimigos: Status tick → Telégrafos (progresso) → impacto → IA   [ordem estável da lista da IA]
 8  Projéteis · varredura de mortes (até 4 passes)
 9  Telemetria/Run recebem "passo vivo" (t_vivo += 1/60)
10  Câmaras: câmara limpa? → camara_limpa(p,tipo) → Portas → recompensa
```

**Quadro de render** (`_process`, taxa livre): o Orquestrador atualiza relógio e eventual corte do wipe → a Cena publica geometria da janela e calcula câmera/camadas (P_ant, P_atual, fração) → o Pipeline escreve `shader_globals` (`t_vivo`, `t_apres`, `modo_*`) → o HUD lê o estado atual por consulta (nunca só por evento) → o Feedback aplica pedidos aos pools de VFX e números. A arbitragem e entrega de impulsos de câmera pelo Feedback acontecem no fim do passo, antes da avaliação da câmera no próximo render; a aplicação posterior dos outros efeitos não deve atrasar o impulso. O [ADR-0007](adr-0007-cena-viewport-e-camera.md) propõe essa sequência e o reset de época no corte.
**NEEDS VERIFICATION:** `get_physics_interpolation_fraction()` e a interpolação de física 2D.

### 2. Eventos
| Canal | Quando usar | Exemplos |
|---|---|---|
| **Lista de eventos do passo** (`Array` de eventos tipados, ordenada, esvaziada pelo Orquestrador no fim do passo e entregue em ordem fixa) | Notificações de efeito: quem escuta não muda o resultado do passo | `golpe`, `acerto`, `inimigo_morreu`, `jogador_atingido` → Feedback, Telemetria, HUD, Áudio |
| **Chamada síncrona / sinal imediato** | Fluxo de controle em que a ordem muda o resultado | `camara_limpa`, `porta_escolhida`, `oferta_aberta`, `tela_fechada`, `jogador_morreu`, `creditar` |

Motivo: o Feedback é um árbitro puro que recebe "a lista de eventos do passo" (Feedback R1), e a ordem de entrega fixa preserva o determinismo. Sinais do Godot em tudo seriam mais simples, mas a ordem entre conectados é difícil de garantir e testar. A decisão final é o ADR 0002.

Cadeia crítica: `Combate → camara_limpa → Portas → pedir_oferta → Bênçãos → oferta_aberta → Tela → (escolher) → preco_revelado → tela_fechada → bencao_escolhida → Portas abrem`. A Tela só devolve `escolher(i)`/`trocar()`; Bênçãos segura `bencao_escolhida` até `tela_fechada`.

### 3. Salvar e carregar (MVP)
**Não há save no meio da run no MVP.**

| Dado | Dono | Onde | Formato |
|---|---|---|---|
| Última arma escolhida | Armas | `user://preferencias.cfg`, seção `[armas]` | `ConfigFile` (migra para Save e perfil na fatia vertical) |
| Remapeamento | Input | arquivo próprio em `user://` | formato do Input, local do Save |
| `telemetria_ligada` | Telemetria | configuração do usuário (não é Save) | `ConfigFile` |
| Sessão de telemetria | Telemetria | `user://telemetria/sessao-*.jsonl` (≤ 2 MiB, últimas 20) | JSON Lines, síncrono |
| Saldo de Fragmentos | Economia | **só memória**; `exportar()`/`importar()` prontos | `int` |
| Estado dos fluxos do RNG | RNG | **não persiste** (só com save no meio da run, fatia vertical) | — |

Dono da serialização futura: Save e perfil (Vertical Slice, Foundation). Até lá cada dono grava o seu arquivo. **NOT SOURCEABLE:** flush e append do `FileAccess`.

### 4. Ordem de inicialização
```
 1 Conteúdo      carrega catálogo, valida (V1–V11 + 2ª passada), calcula impressão   ← erro bloqueia a run
 2 RNG           recebe fonte de entropia, tipo de build, args de linha de comando
 3 Input         recebe InputTuning do catálogo (sem catálogo: só digital)
 4 Cena/câmera   aplica chaves do project.godot, recebe CameraTuning
 5 Pipeline      recebe VisualTuning, escreve shader_globals iniciais (Shader Baker no export)
 6 Orquestrador  estado "Pronto"
 7 Feature       Modificadores → Movimento → Combate → Selo/Status/Telégrafos/IA → Câmaras/Portas/Run/Bênçãos/Economia (injeção)
 8 Apresentação  HUD, Feedback, Telemetria
 9 Menu / escolha de arma → Run
```
Input e Câmera têm injeção retirada ao sair de Pronto e reinjetada ao entrar. O ADR-0001 propõe a composição no nó raiz, sem `Autoload`.

**Fluxos de maior risco:** montar layout + até 3 ondas + 1ª onda num único quadro da Transição (custo não medido); telemetria síncrona no passo da morte (até 3 linhas, orçamento 3 ms).

## API Boundaries

Contratos em GDScript tipado, com os nomes dos GDDs. Tipos usados: `RefCounted`, `Resource`, `StringName`, `Array[T]`, `Dictionary`, `Vector2`, `@abstract` (4.5, confirmado). ⚠️ Regra do 4.7: `override` de método com retorno tipado herda o tipo e exige `return` explícito (`return null` no mínimo).

### 1. Orquestrador ↔ módulos do passo
```gdscript
@abstract class_name Passo extends RefCounted
@abstract func passo(amostra: AmostraDeEntrada) -> void          # só chamado no estado Jogo
func passo_congelado() -> void: return                           # hitstop/pausa: anterior = atual
```
- Invariante: nenhum módulo chama `Input`, `Engine.time_scale` nem lê o relógio de parede.
- Garantia: `passo()` roda no máximo 1 vez por `_physics_process`, na ordem do fluxo 1.

### 2. Conteúdo (catálogo)
```gdscript
func obter(tipo: StringName, id: StringName) -> Resource         # null + relator em erro
func listar(tipo: StringName) -> Array[Resource]                 # ordem do manifesto, sem `obsoleto`
func impressao() -> String                                        # 64 hex; curta = 4 hex
```
- Invariante: definições somente leitura; cópia mutável só por `duplicate_deep()` e nunca volta ao catálogo.
- Garantia: ≥ 1 erro de validação bloqueia a run antes do menu; ordem estável entre execuções.

### 3. RNG
```gdscript
func fluxo(finalidade: int, regiao: int, indice_camara: int) -> FluxoRng
# FluxoRng: real() -> float [0,1), inteiro(n: int) -> int, escolha_ponderada(pesos), k_distintos(n, k)
```
- Invariante: chamadas aleatórias globais ficam restritas à apresentação e à função de entropia da criação da run, conforme RNG R1 e AC-32. O consumo das finalidades estruturais 1–6 e 8 segue a ordem fixa dos donos. A finalidade `ia`, id 7, admite consumo dependente do combate.
- Garantia: estrutura reproduzível com seed, versão do jogo, impressão completa do catálogo, estado inicial, escolhas de portas/bênçãos e usos de troca de oferta idênticos. Os candidatos de spawn são reproduzíveis, e a seleção final pode depender da posição do jogador. O [ADR-0005](adr-0005-rng-deterministico.md) propõe os contratos de fonte e validade dos fluxos.

### 4. Input
```gdscript
class_name AmostraDeEntrada extends RefCounted   # snapshot somente leitura
var mover: Vector2; var mirar: Vector2; var fonte_mira: StringName; var intensidade_mira: float
func apertado(acao: StringName) -> bool; func segurado(acao: StringName) -> bool
# ComandosDoPasso é uma capacidade separada, válida só no passo/contexto atual:
func quer(acao: StringName) -> bool
func consumir(acao: StringName) -> bool
# Consulta do provedor para HUD/UI:
func rotulo_acao(acao: StringName, dispositivo: StringName) -> Dictionary   # {texto, glifo}
```
- Invariante: código de jogo nunca referencia tecla nem o singleton `Input`; mouse e teclado se identificam por tipo de evento, nunca por `device == 0` (4.7).
- Garantia: 1 amostra por passo, inclusive para telas fora de Jogo; bordas drenadas uma vez. Troca de contexto esvazia buffer/bordas, invalida consumo corrente e bloqueia entradas físicas até soltar. O [ADR-0006](adr-0006-input-por-passo.md) detalha contador compartilhado, hitstop, remapeamento e persistência proposta.

### 5. Modificadores (portador)
```gdscript
func valor(atributo: StringName) -> float                         # contínuos; não vale para dano_*
func inteiro(atributo: StringName) -> int                         # só os 5 atributos inteiros (AC-05)
func congelar_dano(slot: int, ctx: ContextoDeDano) -> DanoCongelado   # M congelado no disparo
func multiplicador_de_dano(slot: int, ctx: ContextoDeDano) -> float   # já com teto
func gatilhos(tipo: StringName) -> ResumoDeGatilho                # ex.: gatilhos(&"refletir_dano").total
func fontes_de(atributo: StringName) -> Array[LinhaDeFonte]       # HUD/Tela: "de onde vem"
func aplicar_fonte(fonte: FonteDeModificador) -> void; func remover_fonte(id_fonte: StringName) -> void
func avancar(passos: int) -> void                                 # só em passo vivo
```
Detalhes e fórmulas (`FormulasDeModificadores.dano_recebido`, arredondamento meio longe do zero) no [ADR-0009](adr-0009-atributos-e-modificadores.md).
- Invariante: duração em passos inteiros; M de golpe congelado no disparo; reaplicar = `max(restante, nova)`.
- Garantia: recálculo imediato após `aplicar`, `remover_fonte` ou expiração; `reducao_dano` ≤ 0,6.

### 6. Movimento ↔ Combate (contrato injetado, resolve o ciclo)
```gdscript
# Movimento define; Combate implementa (injetado em Movimento)
func em_recuperacao() -> bool;  func investida_ativa() -> Dictionary;  func contexto_de_dano() -> Dictionary
# Movimento chama, nesta ordem, no início da esquiva:
func cancelar() -> void;  func garantir_invulneravel(passos: int) -> void;  func esquiva_iniciada() -> void
# Combate chama no Movimento:
func deslocar(v: Vector2) -> void
# Câmaras chama no Movimento, no spawn/troca:
func teleportar(pos: Vector2) -> void
```
- Invariante: só o Movimento escreve a posição do jogador; ninguém chama a lógica interna do outro.
- Garantia: "em esquiva" é falso no último passo (restante 1→0); `teleportar` iguala anterior = atual e emite aviso.
- O [ADR-0008](adr-0008-movimento-e-colisao-propria.md) propõe a ordem máximo → recarga → início → deslocamento → Corte → colisão. `deslocar` repete colisão sem avançar contadores; o resolver discreto não garante ausência de interseções entre extremos. Metadados de novos toques durante hitstop complementam o ADR-0006.

### 7. Combate ↔ IA ↔ Telégrafos (o Combate define a interface)
```gdscript
func ferir_jogador(player_id: int, dano_base: float, m_atacante: float, atacante_id: int, ataque_id: StringName) -> void   # 1 vez por golpe; assinatura canônica no ADR-0010
# Pactos (ADR-0010): ferir_maldicao, ferir_acuada, subjugar(inimigo_id), disparar_projetil(..., alvo_id, alvo_faccao)
func ferir_inimigo(alvo: InimigoRef, dano: float, causa: StringName) -> void  # causa "silencioso" p/ Selo e Status
func disparar_projetil(...8 params...) -> void
func iniciar_telegrafo(inimigo: InimigoRef, ataque: AttackDef) -> bool   # false se teto 24
func pedir_recuperacao(inimigo: InimigoRef, passos: int) -> void
```
- Invariante: mira travada no início do preparo; dano ao jogador é inteiro `max(1, round(...))`, a inimigo é `float`.
- Garantia: o golpe resolve no mesmo passo em que o telégrafo chega a 0; morto não age nem é atingível.

### 8. Status e Selo
```gdscript
func aplicar_status(alvo: InimigoRef, id: StringName, n: float) -> bool   # recusa se n ≤ 0 ou alvo inatingível
func abalado(alvo: InimigoRef) -> bool;  func no_selo(alvo: InimigoRef) -> bool
```
- Garantia: contadores só descem em passo vivo; status aplicado nos itens 5/6 fere no mesmo passo, no item 8 no seguinte.

### 9. Cadeia Run, Câmaras, Portas, Bênçãos, Tela (síncrona)
```gdscript
signal camara_limpa(p: int, tipo: StringName)          # Câmaras → Portas e Run
func pedir_oferta(regiao: int, indice: int) -> void     # Portas → Bênçãos
signal oferta_aberta(cartas: Array[CartaView], trocas: int)   # Bênçãos → Tela
func escolher(i: int) -> void;  func trocar() -> void   # Tela → Bênçãos (sem estado de jogo na Tela)
signal tela_fechada()                                   # Tela → Bênçãos → Portas
```
- Invariante: `bencao_escolhida` só sai depois de `tela_fechada`; morte vence a limpeza no mesmo passo.
- Garantia: se o pool é 0, a recompensa vira Fragmentos; oferta já aberta responde `oferta_ja_aberta`.

### 10. Economia
```gdscript
func creditar(origem: StringName, q: int) -> bool       # q float (mesmo 2.0) é recusado; EC1
func gastar(custo: int, motivo: StringName) -> bool     # atômico; ninguém chama no MVP
func saldo() -> int;  func coletados_run() -> int;  func exportar() -> int;  func importar(v: int) -> bool
```
- Garantia: saldo ≥ 0, teto 999 999; só Run e Portas (e, no futuro, a Oficina) escrevem.

### 11. Lista de eventos do passo e leitura da Apresentação
```gdscript
class_name EventoDoPasso extends RefCounted             # tipo + payload tipado, ordem de inserção
func emitir(e: EventoDoPasso) -> void                    # só no passo; entregue pelo Orquestrador em ordem fixa
# HUD/Feedback/Telemetria leem por interface de leitura injetada (testáveis com fontes falsas)
```
- Invariante: a Apresentação não escreve em jogo; evento sem linha de resposta no Feedback gera erro FB1 (log) e o jogo segue.

Os ADRs 0001 e 0002 propõem os contratos de `Passo` e `EventoDoPasso`. O [ADR-0003](adr-0003-entidades-e-portadores.md) detalha a proposta para `InimigoRef`.

## ADR Audit

Os ADRs 0001 a 0018 foram aceitos pelo usuário em 2026-11-16 (Accepted). A auditoria consolidada ocorre em `/architecture-review`. A revisão cruzada de 2026-11-15 (resumo em [architecture-review.md](architecture-review.md#revisão-cruzada-dos-adrs-0001-a-0014-2026-11-15)) alinhou interfaces entre os 14 primeiros; a de 2026-11-16 ([architecture-review-2026-11-16.md](architecture-review-2026-11-16.md)) cobriu os 18 depois da Doutrina de Pactos.

| ADR | Engine Compat | Version | GDD Linkage | Conflicts | Valid |
|-----|--------------|---------|-------------|-----------|-------|
| [ADR-0001: Orquestrador do passo](adr-0001-orquestrador-do-passo.md) | ✅ VR(1–6) verificados (`EX-0001-1..6`, incl. `global_shader_parameter_set` `4 µs` p99) | ✅ (4.7.2) | Combate, Movimento, Input, Câmaras, Run e Telemetria | Lacunas 1–2 tratadas em 2026-11-15; foco, pausa e globais verificados em 2026-11-16/17 | ✅ Accepted |
| [ADR-0002: Canal de eventos](adr-0002-canal-de-eventos.md) | ✅ VR(2,3) verificados (`EX-0002-2..3`); VR(1) ~20 ev/passo ok em debug, fallback de pool decidido | ✅ (4.7.2) | Combate, Selo, Status, Run, Portas, HUD, Feedback, Telas, Áudio e Telemetria | Lacunas 3–4 tratadas em 2026-11-15; `filter()` tipado e `@abstract` verificados em 2026-11-16 | ✅ Accepted |
| [ADR-0003: Entidades e portadores](adr-0003-entidades-e-portadores.md) | ✅ `RefCounted` e arrays tipados verificados em experimento isolado | ✅ (4.7.2) | IA, Combate, Movimento, Modificadores, Selo, Status, Telégrafos e Maldições | Revisão consolidada PASS | ✅ Accepted |
| [ADR-0004: Catálogo de dados](adr-0004-catalogo-de-dados.md) | ✅ `HashingContext`, `IGNORE_DEEP`, `DEEP_DUPLICATE_ALL`, CSV `keep` (`exclude_filter`) e carga `160,8/86,2 ms` verificados (`EX-0004-NV`) | ✅ (4.7.2) | Conteúdo R1–R12, RNG, Pactos e ajustes dos consumidores | PC de referência fixado; `TR-conteudo-015` promovido a ✅ Covered | ✅ Accepted |
| [ADR-0005: RNG determinístico](adr-0005-rng-deterministico.md) | ✅ 33 verificações aritméticas aprovadas | ✅ (4.7.2) | RNG R1–R9, F1/F2/F4/F6 e finalidade 9 `pactos` | Revisão consolidada PASS | ✅ Accepted |
| [ADR-0006: Input por passo](adr-0006-input-por-passo.md) | ✅ 38 verificações de eventos sintéticos, buffer e barreira aprovadas | ✅ (4.7.2) | Input R1–R13, F1–F5, `troca` e `ponto_mira` | Revisão consolidada PASS | ✅ Accepted |
| [ADR-0007: Cena, viewport e câmera](adr-0007-cena-viewport-e-camera.md) | ✅ 67 checks + interpolação 2D, `reset_physics_interpolation()` pós-teleporte e pillarbox verificados (`EX-0007-NV`) | ✅ (4.7.2) | Cena R1–R12, F1–F7 | Escala fracionária em `1366×768` documentada com fallback `integer` | ✅ Accepted |
| [ADR-0008: Movimento e colisão própria](adr-0008-movimento-e-colisao-propria.md) | ✅ 51 verificações em fixtures; limite tangencial reproduzido | ✅ (4.7.2) | Movimento R1–R12, F1–F7 e MV1–MV8 | AC-26 de Corte pesado alinhado com ADR-0010 | ✅ Accepted |
| [ADR-0009: Atributos e modificadores](adr-0009-atributos-e-modificadores.md) | ✅ `float` IEEE-754 binary64 verificado (`EX-0009-1`, `2^52+1 != 2^52`) | ✅ (4.7.2) | Modificadores R1–R14, F1–F6 | Nota de literais em empate no tokenizer registrada | ✅ Accepted |
| [ADR-0010: Resolução do combate](adr-0010-resolucao-do-combate-no-passo.md) | ✅ `RenderingServer.frame_post_draw` verificado (`EX-0010-1`, 1×/quadro, `33,33 ms ≤ 50 ms`) | ✅ (4.7.2) | Combate R1–R25, Selo F1, Status R2–R4, Telégrafos, Chefes | Revisão consolidada PASS | ✅ Accepted |
| [ADR-0011: Pipeline visual](adr-0011-pipeline-visual.md) | ✅ E1–E7 e `EX-0001-3` verificados (`ex-0011-e1-e3.md`, `ex-0011-e4-e7.md`: 444 draw calls, LUT global, `speed_scale=0`, malha SDF, `CanvasGroup`, quad SDF, material por entidade) | ✅ (4.7.2) | Pipeline R1–R12, R5a/R5b, Feedback | Revisão consolidada PASS; plano B `EscritorPorMaterial` preservado | ✅ Accepted |
| [ADR-0012: UI e HUD](adr-0012-ui-e-hud.md) | ✅ E1–E6 e CB verificados (`EX-0012`: `offset_transform_visual_only`, `ui_*`, barreira de foco, CSV plural, clipboard) | ✅ (4.7.2) | HUD, Tela de bênção, Input, Vínculo, Save | Revisão consolidada PASS | ✅ Accepted |
| [ADR-0013: Persistência do MVP](adr-0013-persistencia-do-mvp.md) | ✅ E-P1..E-P7 verificados (`EX-0013`: `flush`, `.old` obrigatório, `schema_version`, UTC+`Z`, `shell_open`, `WM_CLOSE_REQUEST`) | ✅ (4.7.2) | Telemetria, Input, Armas, Economia, Save e Perfil, Vínculo | Mitigação de picos do SO no passo de morte decidida | ✅ Accepted |
| [ADR-0014: Telégrafos](adr-0014-telegrafos-geometria-e-teto.md) | ✅ Sem API nova além de `Vector2` | ✅ (4.7.2) | Telégrafos, IA, Combate, Chefes | Troca de câmara com `LIBERAR_JA` (decisão de 2026-11-15) | ✅ Accepted |
| [ADR-0015: Ciclo da run e composição](adr-0015-ciclo-da-run-e-composicao.md) | ✅ `NOTIFICATION_WM_CLOSE_REQUEST` verificado em `EX-0013 E-P7` | ✅ (4.7.2) | Run, Câmaras, Portas, Economia, Bênçãos, Vínculo, Chefes, Save | Revisão de 2026-11-16: C4 corrigido (consolidação direta antes de `run_encerrada`) | ✅ Accepted |
| [ADR-0016: Áudio: ganchos e vozes](adr-0016-audio-ganchos-e-vozes.md) | ✅ Itens 1–6 confirmados (`EX-0016-A`: `get_bus_index`, `pitch_scale`, `stream_paused`, `linear_to_db`, layout, loop WAV) | ✅ (4.7.2) | Feedback, Telégrafos, Maldições, Chefes, HUD | 5º consumidor da lista (Telemetria→HUD→Feedback→Telas→Áudio) | ✅ Accepted |
| [ADR-0017: Aliados e invocações](adr-0017-aliados-e-invocacoes.md) | ✅ Sem API nova além de `RefCounted`/`Vector2` | ✅ (4.7.2) | Maldições, Armas (Besta), Combate R20–R23, Vínculo, Modificadores | C3 e C5 corrigidos; aceito junto com o 0018 | ✅ Accepted |
| [ADR-0018: IA de inimigos e chefe](adr-0018-ia-de-inimigos-e-chefe.md) | ✅ Sem API nova | ✅ (4.7.2) | IA R1–R22, Chefes, Câmaras R14-P, Vínculo V8 | Lacaios usam `ia` (IA R21); aceito junto com o 0017 | ✅ Accepted |

**Cobertura de rastreabilidade (atualizada em 2026-11-17): 400 requisitos registrados em [tr-registry.yaml](tr-registry.yaml); `400/400 ✅ Covered (Accepted) (100%)`, `0 🟡 Covered (Proposed)`, `0 ⚠️ Partial`, `0 ❌ Gap`.** `TR-conteudo-015` promovido de `⚠️ Partial` a `✅ Covered (Accepted)` após fixar o PC de referência (`AMD Ryzen 5 5600H (6C/12T), 16 GB RAM, SSD NVMe, GPU RTX 3050 Laptop, Windows 11 Home 10.0.26300`) e registrar as medições `160,8 ms` (texto) e `86,2 ms` (`.pck`) `≤ 250 ms` no [ADR-0004](adr-0004-catalogo-de-dados.md). Detalhes em [architecture-review-2026-11-16.md](architecture-review-2026-11-16.md) e [requirements-traceability.md](requirements-traceability.md).

## Required ADRs

Nível `standard`: só os críticos. O mapeamento fino requisito→ADR (`TR-<sistema>-NNN`) é feito por `/architecture-review`; abaixo vão os grupos.

### Obrigatórios antes de codificar

**Foundation (nesta ordem):**

| # | Título | Decide | Cobre (grupos de TR) | Risco |
|---|---|---|---|---|
| 0001 | Orquestrador do passo e estados de jogo | Nó ou `Autoload`; ordem do passo; hitstop como contador; `t_vivo`/`t_apres`; quem liga `modo_bencao`; `_physics_process` a 60 Hz | `combate-nucleo-001/002/011`, `movimento-002/003`, `cena-009/011`, `pipeline-004`, `ia-001`, `camaras-002/007`, `run-005`, `input-008` | **ALTO** (GDScript 4.7; estado próprio, sem `SceneTree.paused`) |
| 0002 | Canal de eventos | Lista do passo + chamadas síncronas; payload de `EventoDoPasso` | `combate-nucleo-009`, `feedback-001/003/009`, `hud-001`, `telemetria-*` | MÉDIO |
| 0003 | Representação de entidades e portadores | Node vs RefCounted vs Resource; `InimigoRef`, pool de telégrafos; lógica sem `SceneTree` | `combate-nucleo-003`, `movimento-011`, `selo-011`, `modificadores-003`, `telegrafos-001`, `status-001/010`, `ia-*` | MÉDIO |
| 0004 | Catálogo de dados | `.tres`, carregador síncrono vs threaded, validação, impressão SHA-256, `duplicate_deep` | `conteudo-orientado-a-dados-*`, todos os `*-Tuning` | MÉDIO (`HashingContext`, CSV `keep`, `ResourceLoader`: NEEDS VERIFICATION) |
| 0005 | RNG determinístico | `mulberry32`, lint de CI contra `randf`/`shuffle` | `rng-com-seed-*`, `ia-004`, `camaras-004..006`, `portas-001`, `bencaos-003` | BAIXO |
| 0006 | Input por passo | `InputMap` vs amostra própria, buffer, remapeamento, ordem de nós | `input-e-controle-*` | **ALTO** (foco duplo 4.6, device IDs 4.7) |
| 0007 | Cena, viewport e câmera | stretch e pillarbox, parallax, câmera própria vs `Camera2D`, interpolação, tela→mundo | `cena-3-4-e-camera-*`, `movimento-008` | **ALTO** (interpolação 2D NOT SOURCEABLE) |

**Core:**

| # | Título | Decide | Cobre | Risco |
|---|---|---|---|---|
| 0008 | Movimento e colisão própria | Círculos + retângulo, sem `CharacterBody2D` | `movimento-001/004/005/007`, `combate-nucleo-012`, `ia-006` | BAIXO |
| 0009 | Atributos e modificadores | Cache vs sob demanda; float vs int e arredondamento determinístico | `modificadores-e-atributos-*` | BAIXO |
| 0010 | Resolução do combate no passo | Ordem de itens, dano float/int, varredura de mortes, empurrão | `combate-nucleo-004..010`, `status-003`, `selo-002/005` | **ALTO** (fim de quadro NOT SOURCEABLE) |

**Apresentação (críticos porque os GDDs marcam pontos NÃO VERIFICADO):**

| # | Título | Decide | Cobre | Risco |
|---|---|---|---|---|
| 0011 | Pipeline visual | Nós e materiais, LUT global vs plano B, famílias de shader, passes, orçamento de draw calls (**a verificar nos experimentos E1–E7**) | `pipeline-visual-*`, `feedback-004/005/010/011` | **ALTO** (E2 NOT SOURCEABLE) |
| 0012 | UI e HUD | `Control` em `CanvasLayer` vs nós no mundo, foco duplo, escala 85–150% | `hud-*`, `tela-de-bencao-e-carta-*` | **ALTO** (foco duplo, `offset_transform_*`) |

### Novo escopo do MVP: Doutrina de Pactos (decisão do usuário, 2026-11-15)

Pactos entra no MVP como **3ª Doutrina** (antes era Alpha). O jogador leva **2 Maldições** (criaturas do pacto) por expedição, **uma em campo** e a outra para troca ou técnica combinada; o vínculo cresce com o uso e pactos novos nascem de encontros na expedição. **Os GDDs existem** (commit 6698079): `maldicoes.md`, `chefes.md`, `vinculo-e-pactos.md`, `save-e-perfil.md`, mais a "emenda Pactos" nos outros 22 e as 21 decisões de `pactos-decisoes-a-confirmar.md`. Cobertura na arquitetura (2026-11-16):

| ADR | Cobre |
|---|---|
| [ADR-0015: Ciclo da run e composição](adr-0015-ciclo-da-run-e-composicao.md) (novo) | Composição da run (Main/GameSession), câmaras→portas→bênção→chefe, Run R3-P, encontro de pacto (índices 1–2), Pactuar/Exorcizar, quando gravar o perfil, resumo de run, `ContaFragmentos` |
| [ADR-0016: Áudio: ganchos e vozes](adr-0016-audio-ganchos-e-vozes.md) (novo) | Barramentos, pool de vozes, eventos→sons, TR-feedback-008, TR-telegrafos-014 |
| [ADR-0017: Aliados e invocações](adr-0017-aliados-e-invocacoes.md) (novo) | `ModuloDeMaldicoes` (item 6.1), `MaldicaoRef`, troca, técnica combinada, Chamado, reserva/Exaustão, IA de aliado |
| [ADR-0018: IA de inimigos e chefe](adr-0018-ia-de-inimigos-e-chefe.md) (novo) | IA de inimigos e do chefe (padrões, fases, Fúria) |
| Emendas de 2026-11-16 | 0001 (item 6.1; Bênção serve ao consentimento), 0002 (eventos novos), 0003 (`MaldicaoRef`; chefe como `InimigoRef` com flags; acuada fora da lista de inimigos), 0004 (`CurseDef`, `BossPatternDef`, `*Tuning` novos, TR-armas-008), 0005 (finalidade 9 `pactos`), 0006 (`troca`, `ponto_mira`), 0008 (geometria das Maldições, deslocamento forçado), 0009 (portador da Maldição, espelho, `furia`), 0010 (facções, `ferir_maldicao`, `ferir_acuada`, `subjugar`), 0011 (contorno secundário, VFX das Maldições), 0012 (HUD do Pacto, consentimento), 0013 (`perfil.cfg` e `[vinculo]`), 0014 (alvo travado) |

### Devem existir antes do sistema correspondente ser construído
- **0013 Persistência do MVP** (`ConfigFile` em `user://`, binds, telemetria, `exportar`/`importar`): `armas-006/007`, `input-006`, `telemetria-001..009`, `economia-005`, `rng-010`. **NOT SOURCEABLE** (flush/append de `FileAccess`).
- **0014 Telégrafos: geometria de acerto e teto 24**: `telegrafos-003/006/010`.

### Podem esperar a implementação
Medir `dc_vfx` em runtime (o pool de vozes agora é do ADR-0016 e o de números do ADR-0011), e tudo de Vertical Slice e Alpha (Criatura, Oficina, Campus). Save e perfil e Chefes saíram desta lista: são MVP desde a Doutrina de Pactos (ADR-0013, ADR-0015, ADR-0018).

Dos 12 ADRs obrigatórios originais, **7 têm risco ALTO**; quatro deles (0001, 0007, 0010, 0011) dependem de itens NOT SOURCEABLE e nascem marcados "a verificar no protótipo". Os quatro de Pactos (0015–0018) são de risco BAIXO a MÉDIO (0016 por API de áudio não verificada). Ordem de aceite sugerida (grafo sem ciclos, 2026-11-16): 0001, 0002, 0003, 0004, 0005, 0006, 0009, 0007, 0013, 0008, 0010, 0014, 0011, 0017+0018 (juntos), 0012, 0015, 0016.

## Architecture Principles

1. **Simulação em passo fixo e estrutura reproduzível.** 60 Hz, hitstop como contador de passos e RNG próprio. A reprodução estrutural depende dos seis elementos de RNG R7, descritos no ADR-0005.
2. **Lógica pura e injetada.** Regras de jogo não dependem do `SceneTree` nem de singleton; tudo entra por injeção, para ser testável em memória (padrão de DI do `coding-standards.md`).
3. **Tudo que se ajusta é dado.** Valores vivem em `Resource` e `*Tuning` validados na carga; nenhum número de jogo literal em GDScript.
4. **Só se chama para baixo.** Para cima e para os lados só há eventos e consultas injetadas; a Apresentação só lê e nunca escreve no jogo.
5. **Não se afirma o que não foi verificado.** Todo item NOT SOURCEABLE ou NEEDS VERIFICATION vira experimento antes de virar decisão firme; um ADR que dependa dele nasce marcado "a verificar".

## Preparação para co-op

Decisão do usuário (2026-11-13): co-op online de 1 a 4 jogadores **depois** do MVP solo. Nada de rede agora; esta seção só garante que a base solo não impeça o co-op e registra o risco. Modelo-alvo: **host-autoritativo** (o host simula; os clientes enviam entrada e apresentam).

**O que a base solo já garante:** passo fixo de 60 Hz, ordem fixa dos 10 itens e RNG próprio por seed (simulação reproduzível); lógica pura sem `SceneTree` e sem singleton (o host roda a simulação sem Apresentação, o cliente roda só a Apresentação); a Apresentação só lê; a lista de eventos do passo (ADR-0002) serve de fluxo de notificações; o buffer de comandos em passos inteiros encaixa em entrada enviada por passo.

**O que hoje assume "um único herói":**

| Ponto | Suposição atual | Preparação |
|---|---|---|
| Input | uma `AmostraDeEntrada` por passo (API 4) | amostra por jogador, indexada por `player_id` (0 no solo) |
| Movimento, Combate, Modificadores | posição única, Vida, portador, cargas e `ferir_jogador(dano, origem, atq)` sem alvo | contratos recebem `player_id`; estado por jogador; `Array[JogadorRef]` em vez de uma referência |
| IA, Telégrafos, Câmaras | alvo é "o jogador"; spawn a >390 px "do jogador" | alvo escolhido na lista; spawn considera todos |
| Câmera, HUD, Bênção | uma câmera, um HUD, uma oferta | decisão de design pendente |
| Run, Economia | a morte do jogador encerra a run; um saldo | morte individual ≠ fim da run; saldo por jogador, decisão pendente |
| Estados globais | pausa, Bênção e hitstop congelam o mundo | online, a pausa não congela o host; hitstop global é decisão pendente |
| Eventos | `alvo_id` | eventos de jogador carregam `player_id` |

**Regras para escrever já (baratas):**
1. Contrato novo que fale "o jogador" nasce com `player_id` (0 no solo) ou recebe a lista de jogadores; nunca guarda o herói em variável única ou global.
2. Estado de jogador (posição, Vida, cargas, Fluxo, portador) vive numa estrutura por jogador, não em campos singulares espalhados.
3. Nenhum módulo de regra lê Input local; só a amostra que o orquestrador entrega (já é regra).
4. Nenhum código de rede e nenhum ADR novo até o co-op entrar.

**Risco: retrofit caro.** Se os contratos ficarem singulares, o co-op exige tocar quase todos os GDDs e módulos. *Mitigação:* as regras acima e uma revisão dos contratos antes de fechar o Pre-Production. Determinismo bit a bit entre máquinas **não** é premissa: com host autoritativo basta o host simular (e o fluxo `ia` já não tem garantia de reprodução).

**Fora do escopo desta nota:** não foram consultadas APIs de rede da engine; `docs/engine-reference/godot/modules/networking.md` não foi lido.

## Open Questions

Todas as perguntas de arquitetura do MVP foram respondidas pelos ADRs `0001–0018` (`Accepted`) e pelos experimentos de engine `EX-0001..0016` (2026-11-16/17). Restam abertas apenas questões pós-MVP (Co-op Alpha) e de infraestrutura de release (instalação dos export templates 4.7.2).

### Fechadas / Resolvidas (MVP)

| Pergunta | Camada | Resolução |
|---|---|---|
| Orquestrador: nó na cena raiz ou `Autoload`? | Foundation | **Fechada / Resolvida** — [ADR-0001](adr-0001-orquestrador-do-passo.md) (`Accepted`) + `EX-0001-1..6`: `OrquestradorDoPasso` em `RefCounted` puro acionado por `Main` (`Node` fino na raiz), sem `Autoload` e sem `SceneTree.paused`. |
| Revisar representação de combatentes, portadores e slots de telégrafo | Foundation/Core | **Fechada / Resolvida** — [ADR-0003](adr-0003-entidades-e-portadores.md), [ADR-0009](adr-0009-atributos-e-modificadores.md) e [ADR-0014](adr-0014-telegrafos-geometria-e-teto.md) (`Accepted`) + `EX-0009-1`: `InimigoRef`, `MaldicaoRef`, `Portador` em `RefCounted` e pool fixo de 24 slots. |
| Payload de `EventoDoPasso` e herança `@abstract` vs duck typing | Foundation | **Fechada / Resolvida** — [ADR-0002](adr-0002-canal-de-eventos.md) (`Accepted`) + `EX-0002-1..3`: subclasses tipadas de `EventoDoPasso` (`@abstract`), `filter()` tipado confirmado, ordem fixa de entrega Telemetria → HUD → Feedback → Telas → Áudio. |
| `HashingContext`, CSV `keep` e `ResourceLoader` síncrono vs threaded | Foundation | **Fechada / Resolvida** — [ADR-0004](adr-0004-catalogo-de-dados.md) (`Accepted`) + `EX-0004-NV`: `HashingContext` SHA-256, `CACHE_MODE_IGNORE_DEEP`, `DEEP_DUPLICATE_ALL` e CSV `keep` (`exclude_filter="assets/data/canon/*"` obrigatório) verificados; carga síncrona medida em `160,8 ms` (texto) / `86,2 ms` (`.pck`) `< 250 ms` no PC de referência fixado (`TR-conteudo-015` ✅). |
| Interpolação de física 2D, `reset_physics_interpolation()`, pillarbox em runtime, parallax manual | Foundation | **Fechada / Resolvida** — [ADR-0007](adr-0007-cena-viewport-e-camera.md) (`Accepted`) + `EX-0007-NV`: interpolação 2D, `reset_physics_interpolation()` no mesmo passo após teleporte e pillarbox/letterbox em runtime verificados. |
| "Sinal de fim de quadro" do 4.7 que o AC-92 exige (latência ≤ 50 ms) | Core | **Fechada / Resolvida** — [ADR-0010](adr-0010-resolucao-do-combate-no-passo.md) (`Accepted`) + `EX-0010-1`: `RenderingServer.frame_post_draw` dispara 1× por quadro; pior caso medido `33,33 ms ≤ 50 ms`. |
| Experimentos de apresentação, foco/UI e áudio (`offset_transform_*`, `ui_*`, barreira de foco, CSV plural, clipboard, barramentos/vozes) | Apresentação | **Fechada / Resolvida** — [ADR-0011](adr-0011-pipeline-visual.md), [ADR-0012](adr-0012-ui-e-hud.md) e [ADR-0016](adr-0016-audio-ganchos-e-vozes.md) (`Accepted`) + `EX-0001-4`, `EX-0012 E1–E6/CB` e `EX-0016-A`; para globais de shader/LUT (E2) o ADR-0011 define o plano B `EscritorPorMaterial` atrás de `EscritorDeGlobais`. |
| Flush e append do `FileAccess` na telemetria e atomicidade de `.cfg` no Windows | Foundation/Apresentação | **Fechada / Resolvida** — [ADR-0013](adr-0013-persistencia-do-mvp.md) (`Accepted`) + `EX-0013 E-P1..P7`: arquivo novo por sessão com `store_line` + `flush` (`p99 ≤ 1 ms/linha`), sequência `.old` obrigatória em `gravar_atomico`, exigência de `schema_version` após `parse == OK`, UTC + `"Z"`, `OS.shell_open` e `NOTIFICATION_WM_CLOSE_REQUEST`. |
| Custo de montar layout + 3 ondas + 1ª onda na Transição e ciclo de vida da run | Feature | **Fechada / Resolvida** — [ADR-0005](adr-0005-rng-deterministico.md), [ADR-0015](adr-0015-ciclo-da-run-e-composicao.md), [ADR-0017](adr-0017-aliados-e-invocacoes.md) e [ADR-0018](adr-0018-ia-de-inimigos-e-chefe.md) (`Accepted`): composição por `EscopoDaRun` e harness comum de orçamento (`MedidorDeOrcamento`, ADR-0001). |
| Formato do Save e perfil (`user://perfil.cfg`) e escopo de persistência no MVP | Foundation | **Fechada / Resolvida** — [ADR-0013](adr-0013-persistencia-do-mvp.md) §7 e [ADR-0015](adr-0015-ciclo-da-run-e-composicao.md) §7 (`Accepted`): `RepositorioDePerfil` com seção `[vinculo]` opaca, gravação coalescida fora de `JOGO`, sem save no meio da run e saldo de Fragmentos em memória no MVP. |
| Extração completa de requisitos técnicos e rastreabilidade dos 26 GDDs | todas | **Fechada / Resolvida** — [tr-registry.yaml](tr-registry.yaml), [requirements-traceability.md](requirements-traceability.md) e [architecture-review-2026-11-16.md](architecture-review-2026-11-16.md): `400/400 ✅ Covered (Accepted) (100%)`, `0 🟡`, `0 ⚠️`, `0 ❌`. |
| Desvios de camada em relação ao `systems-index.md` (Pipeline visual e Telemetria na Apresentação; Orquestrador do passo na Foundation) | todas | **Fechada / Resolvida** — Formalizados em `System Layer Map`, [ADR-0001](adr-0001-orquestrador-do-passo.md), [ADR-0011](adr-0011-pipeline-visual.md) e [ADR-0013](adr-0013-persistencia-do-mvp.md). |

### Abertas (Pós-MVP / Infraestrutura de Release)

| Pergunta | Escopo | Quando fecha |
|---|---|---|
| **Co-op Alpha (pós-MVP):** câmera compartilhada ou por jogador, oferta de bênção por jogador, saldo de Fragmentos por jogador, comportamento de pausa e hitstop online, morte individual vs fim da run (os ganchos `player_id` já estão nos contratos dos ADRs 0001–0018) | Co-op Alpha (pós-MVP) | Decisão de design e ADR de rede antes de iniciar o marco de Co-op Alpha (ver "Preparação para co-op") |
| **Templates de exportação de release (Godot 4.7.2):** instalar os export templates oficiais do 4.7.2 em `%APPDATA%\Godot\export_templates\` e repetir no binário `.exe` de release as medições já validadas no editor e em `.pck` (`EX-0001`, `EX-0002-1`, `EX-0004-NV`, `EX-0013 E-P7`) | Build / Release | Antes do fechamento do marco de Pre-Production / Release |
