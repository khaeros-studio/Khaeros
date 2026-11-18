# ADR-0011 — Pipeline visual

## Status

Accepted · 2026-11-16 (aprovado pelo usuário; Proposed em 2026-11-15; experimentos E1–E7 e EX-0001-3 verificados em 2026-11-17)

## Date

2026-11-15

## Last Verified

2026-11-17 (verificação de engine E1–E7 e EX-0001-3 concluída em `prototypes/pipeline-verificacao/`; evidências em `production/qa/evidence/experimentos/ex-0001-3-global-set.md`, `ex-0011-e1-e3.md` e `ex-0011-e4-e7.md`). Antes: 2026-11-16 (emenda Pactos: R5a, R5b; aresta para ADR-0014). Antes: 2026-11-15. Fontes lidas: GDD de Pipeline visual (R1–R13, Estados, F6, F8–F10, Open Questions), Feedback de combate (R1–R12, por busca), ADR-0001, ADR-0007, `architecture.md` (Apresentação, Data Flow, ordem de inicialização) e `docs/engine-reference/godot/` (VERSION, breaking-changes, current-best-practices, `modules/rendering.md`).

## Decision Makers

Proposta da aba de Arquitetura (technical-artist), por delegação do usuário. O aceite depende dos experimentos E1–E7 e da revisão consolidada. O que muda sensação ou número fica em "Decisões pendentes do usuário".

## Summary

O Pipeline visual se divide em duas partes. `EstadoVisual` é lógica pura (`RefCounted`): modo de tela, limitador de flashes F6, oclusão F9, fator de profundidade F2 e progresso dos passes. `PipelineVisual` é um nó fino da Apresentação e o **único escritor** dos globais de shader e dos uniforms dos passes, uma vez por quadro. Os shaders se agrupam em três famílias por `.gdshaderinc`, com a família marcada pela pasta. A LUT regional fica num `global uniform sampler2D`, com o plano B de um uniform por material. Os passes de tela são `ColorRect`s opacos no `CanvasLayer` Pós, sem cópia da tela. O orçamento de 500 draw calls é contado por proxy em runtime, mas a fonte de verdade é a captura no PIX ou no RenderDoc.

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Godot 4.7, pin 4.7.2 (instalado, sem gap) |
| **Domain** | Rendering 2D / Shaders |
| **Layer** | Apresentação |
| **Knowledge Risk** | HIGH: o renderer 2D, os globais de shader e o Shader Baker não estão na referência |
| **References Consulted** | `VERSION.md`, `breaking-changes.md`, `current-best-practices.md`, `modules/rendering.md` |
| **Post-Cutoff APIs Used** | Shader Baker (4.5, confirmado na referência, sem detalhe de chave); D3D12 como backend padrão no Windows (4.6, confirmado); linhas de `CanvasItem` sem feather (4.7, confirmado); saída HDR (4.7, existe, sem chave de projeto documentada) |
| **Verification Required** | E1–E7 e EX-0001-3 **VERIFICADOS** em 2026-11-17 no Godot 4.7.2 (`prototypes/pipeline-verificacao/`; ver seção "Verificação de engine (2026-11-17)"): `RenderingServer.global_shader_parameter_set`, `global uniform` (escalar, cor e `sampler2D`) em `canvas_item` com hints `filter_linear, repeat_disable`, `instance uniform` em `canvas_item`, `CanvasGroup.fit_margin` (em px/unidades de canvas, fixado em `8.0`), `speed_scale = 0.0` em emissores GPU/CPU e `AnimatedSprite2D`, chaves `rendering/textures/canvas_textures/default_texture_filter=2`, `rendering/2d/snap/snap_2d_transforms_to_pixel=false`, `rendering/2d/snap/snap_2d_vertices_to_pixel=false`, `rendering/viewport/hdr_2d=false`, `light_mask`/`range_item_cull_mask` e `shader_baker/enabled=true` no preset de exportação |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | [ADR-0001](adr-0001-orquestrador-do-passo.md): estado, relógios e as seis ações da Transição; [ADR-0002](adr-0002-canal-de-eventos.md): lista de eventos entregue à Apresentação; [ADR-0003](adr-0003-entidades-e-portadores.md): ids; [ADR-0004](adr-0004-catalogo-de-dados.md): `VisualTuning`, LUTs e máscaras; [ADR-0007](adr-0007-cena-viewport-e-camera.md): camadas, z, Pós/UI, ordem do quadro; [ADR-0014](adr-0014-telegrafos-geometria-e-teto.md): pool de nós indexado por `VistaDeTelegrafo.slot` (aresta acrescentada em 2026-11-16) |
| **Enables** | ADR-0012 UI (shader `ui`, `sem_grading`); stories de VFX do Feedback |
| **Blocks** | Stories visuais de produção (materiais, LUT, passes, telégrafo) até o aceite e o E1–E4 |
| **Ordering Note** | Os experimentos E1–E3 vêm antes do aceite; E4–E7 podem fechar depois, com o fallback já escrito aqui |

## Context

O GDD de Pipeline visual (Approved em 2026-11-10) diz *como* cada coisa é desenhada: famílias de grading, LUT por região, escurecimento linear por profundidade, telégrafo SDF em duas passadas, traço do jogador, impact frame por modo global, dois relógios sem `TIME` e orçamentos. Ele mesmo envia para um ADR a estrutura de nós e materiais, o caminho do grading e quem escreve os relógios. Há três tensões nos documentos. O GDD R8 diz que o orquestrador escreve os relógios. O `architecture.md` diz que o Orquestrador liga o `modo_bencao`. O ADR-0007 diz que o progresso do wipe é do Pipeline, e o ADR-0001 o lê no `quadro()`. A fatia jogável (`src/presentation/world_view.gd`) desenha tudo num único `Node2D` por `_draw()`, com `draw_line`/`draw_arc` (que no 4.7 perderam o feather), e usa os `SpriteFrames` dos quatro atores em `assets/art/runtime/`. Ela não tem famílias, globais nem passes.

## Decision

### 1. Duas peças: lógica pura e escritor único

`EstadoVisual extends RefCounted` guarda o modo de tela (Normal, Impacto, Bênção, Transição, Morte; prioridade Transição > Morte > Bênção > Impacto), o `LimitadorDeFlashes` (F6, com relógio monotônico em µs injetado), o `PasseDeTela` (modo wipe ou fade, progresso 0 → 1), a oclusão por prop (F9, com histerese), o `fator_profundidade` (F2, calculado em double na CPU) e o estado "sujo" de cada global. Não toca em `RenderingServer` nem na árvore, e os testes o montam inteiro em memória. `PipelineVisual extends Node`, filho do `Main`, recebe por `configurar()` o `EstadoVisual`, o `VisualTuning` e um `EscritorDeGlobais`. Ele é o **único** código do jogo que escreve globais de shader e uniforms de passe.

**Quem escreve.** O orquestrador continua dono dos **valores** (`t_vivo()`, `t_apres()`, `estado()`) e decide quando a Bênção liga e desliga. O Pipeline é dono da **escrita**. Assim o GDD R8 e o conflito 2 do `architecture.md` passam a ser lidos como "decide o valor", não como "chama a engine". A Bênção desliga em `tela_fechada`, como pede a nota de 2026-11-11 do GDD.

### 2. Ordem no quadro

Na ordem do ADR-0007, `Main._process(delta)` faz:

1. `orquestrador.quadro(delta)`: avança `t_apres` e `passe.avancar(min(delta, dt_max_apres))`. Com `TRANSICAO`, progresso ≥ 0,5 e `troca_feita` falso, roda as seis ações. A última chama `estado_visual.trocar_regiao(...)` e zera os relógios;
2. a Cena aplica geometria, câmera e camadas;
3. `pipeline_visual.aplicar_quadro()`: escreve `t_vivo` e `t_apres` em todo quadro, os demais globais só quando estão sujos (`modo_impacto`, `modo_bencao`, `fator_profundidade`, `lut_regiao`, cores da região, `escala_traco`) e os uniforms `progresso_wipe` e `progresso_morte` dos materiais dos passes;
4. HUD e Feedback.

Como a LUT nova e os relógios zerados são escritos no mesmo quadro da troca, com a tela já coberta, nenhum quadro mostra a câmara nova com a LUT velha. O `PasseDeTela` é **objeto do Pipeline avançado pelo orquestrador** (injeção). Isso concilia o ADR-0007 ("progresso próprio do Pipeline") com o ADR-0001 ("`quadro()` testa ≥ 0,5"). Ele não lê `t_apres`, então o zero dos relógios não o afeta. A Transição não aceita pausa (ADR-0001: PAUSA só a partir de JOGO ou BENCAO), o que responde em parte à OQ14 do GDD. O modo wipe ou fade (limitador cheio, F6; Redução de movimento, R11) é decidido **no pedido** e não muda durante o passe.

### 3. Globais de shader

Os globais ficam declarados em `[shader_globals]` no `project.godot`: `lut_regiao` (sampler2D), `cor_nevoa`, `cor_feixe`, `cor_fundo`, `fator_profundidade` (float), `modo_impacto` (int: 0 nenhum, 1 recusa, 2 chefe, 3 reduzido), `modo_bencao` (int 0/1), `saturacao_bencao`, `valor_bencao`, `t_vivo`, `t_apres` e `escala_traco` (s_tela × zoom). O caminho primário de escrita é `RenderingServer.global_shader_parameter_set(nome, valor)`, que é **NOT SOURCEABLE** e passa pelo E2. A escrita passa por uma interface `EscritorDeGlobais`, com duas implementações:

- `EscritorGlobalRS` (primário);
- `EscritorPorMaterial` (plano B), que mantém um registro de materiais por família e faz `set_shader_parameter` em cada um.

O plano B é usado só para o que o E2 reprovar: a LUT, os escalares ou os dois. O resto da regra não muda. Os escalares de tuning (`saturacao_bencao`, `valor_bencao`) são escritos na carga. Nenhum shader de mundo usa `TIME`. A UI (`ui`) pode usar.

### 4. Famílias, marca e lista fechada de shaders

```text
assets/shaders/
  familias/amb_graded.gdshaderinc   # F1 (força 1), F2, F5, modo_impacto
  familias/char_tint.gdshaderinc    # F1 (forca_grading_personagem), F5, modo_impacto
  familias/sem_grading.gdshaderinc  # só modo_impacto
  comum/lut.gdshaderinc  comum/sdf.gdshaderinc  comum/tracejado.gdshaderinc  # F1, F4, F7
  amb_graded/  amb_sprite.gdshader  amb_mascara.gdshader  amb_aditivo.gdshader
  char_tint/   char_sprite.gdshader char_grupo.gdshader
  sem_grading/ tel_sdf.gdshader     traco_sdf.gdshader   vfx_sprite.gdshader  ui.gdshader
  passes/      pass_wipe.gdshader   pass_morte.gdshader   # fora das famílias
```

**A marca de família é a pasta.** O validador de debug percorre os `CanvasItem`s das nove camadas de mundo e avisa, no registro, sobre cada nó sem `ShaderMaterial` ou com shader fora de `amb_graded/`, `char_tint/` ou `sem_grading/`. Um teste estático confere que cada `.gdshader` da pasta inclui o `.gdshaderinc` da própria família. Um shader novo entra na pasta e na tabela R1 antes de entrar no jogo. Uma variante é outro `ShaderMaterial` do mesmo shader. Um `render_mode` diferente é outro arquivo. O grading, o escurecimento e a dessaturação da Bênção são calculados em luz linear: as texturas de cor usam `source_color`, a LUT não. O telégrafo e o traço vivem em unidades de canvas; só o `char_grupo` e os passes usam `escala_traco` com `FRAGCOORD`.

### 5. Nós e materiais por camada

A árvore é a do ADR-0007, sem nós novos de câmera. As diferenças são estas:

- **Ambiente:** sprites e máscaras com `amb_*`, com material compartilhado por variante.
- **Entidades:** cada âncora do y-sort tem um `ShaderMaterial` **próprio**, duplicado no spawn (uniforms `papel`, `flash`, `alfa_oclusao`). Não se usa `instance uniform` (E7). O jogador fica num `CanvasGroup` com `char_grupo` (contorno de invulnerabilidade, inversão), e o `fit_margin` sai da R6 (unidade a confirmar no E5). Os atores animados usam `AnimatedSprite2D` com os `SpriteFrames` já existentes em `assets/art/runtime/<ator>/`, com `char_sprite`, `speed_scale` 0 e quadro escolhido pelo passo vivo (avanço manual; E3).
- **Telégrafos:** um **pool fixo de 24 slots** (`teto_telegrafos`), pré-instanciado na carga. Cada slot tem um quad de preenchimento (`MeshInstance2D` em `TelegrafoPreenchimento`, z −5) e uma malha de borda `ArrayMesh` (em `TelegrafoContorno`, z 5), cada um com seu `ShaderMaterial`. Um slot livre fica com `visible = false`. O ADR-0014 é dono do mapeamento id → slot e publica o campo `VistaDeTelegrafo.slot` (0..`teto_telegrafos`−1, estável durante a ocupação; revisão cruzada de 2026-11-15); este ADR só lê `forma, pos, rot, dims, p, modo, estado, seq` por slot, e o slot que não vem na publicação do passo fica `visible = false`. Os anéis de área ficam num nó irmão anterior aos preenchimentos.
- **VFX:** o pool é do Feedback, com materiais `vfx_sprite`/`traco_sdf` fornecidos aqui. Os emissores do relógio vivo ficam com `speed_scale` 0 no congelamento (E3).
- **Pós (layer 50):** dois `ColorRect`s em tela cheia com `pass_wipe` e `pass_morte`, cada um com `visible = false` fora do uso (0 draw calls). Um terceiro, `pass_vinheta` (antes dos dois, na mesma camada), desenha a vinheta de Vida baixa do HUD (hud.md R4; ADR-0012 calcula e publica a intensidade): o `PipelineVisual` escreve o uniform `intensidade_vinheta` do material no `aplicar_quadro()` e mantém `visible = false` com intensidade 0. Acrescentado na revisão cruzada de 2026-11-15; a família de shader segue a lista fechada da §4 (tipo `pass_*`). Eles desenham tinta opaca e **não leem a tela**: não há `BackBufferCopy`, `hint_screen_texture`, `WorldEnvironment` nem `Compositor`. Pela referência, o `Compositor` se pendura em `WorldEnvironment`/`Camera3D`, o que não serve a este projeto 2D. A UI (layer 100) fica intacta por construção.
- **Luz:** até 2 `PointLight2D` de chefe. Os `sem_grading` ficam fora da máscara da luz (nomes a verificar).

### 6. LUT

A LUT é uma textura 32³ em fita 1024×32, perfil P4: lossless, sem mipmaps, sem repetição e **sem `source_color`**. A amostragem é manual, com duas leituras (uma por fatia de azul) e `mix`, e meio texel de margem, para não depender do filtro do sampler global. A troca de LUT acontece só na última ação da Transição. No plano B, a LUT vira `uniform sampler2D lut_regiao` em cada include de família, escrito pelo `EscritorPorMaterial` na mesma ação. O custo dessa escrita fica escondido sob o wipe e entra na medição do E2.

### 7. Feedback, impact frame e limitador

O Feedback continua árbitro puro (ADR-0002). Ele devolve, por passo, pedidos tipados que a Apresentação aplica: `PedidoImpacto(modo, impact_passos)`, `PedidoPasse(tipo)` e `PedidoFlashTelegrafo(area_somada)`. O `EstadoVisual` responde a cada pedido com `aceito: bool`, aplicando F6 (chefe > recusa > passes > telégrafos no mesmo passo, preempção do chefe), a prioridade do modo de tela e a espera da Bênção. Com `false`, o Feedback tira só o flash chapado e mantém zoom, manchas, hitstop e número (Feedback R8). O passe obrigatório nunca é negado. Com a janela cheia, ele sai em modo fade. A duração do impacto chega em passos de apresentação e é descontada pelo `EstadoVisual` a cada 1/60 s de `t_apres`. O Pipeline fornece ao Feedback os tetos por grupo (R9) e uma **contagem de draw calls por proxy** (instâncias visíveis por grupo), que alimenta a degradação do Feedback. A política de corte (P4 → P2, depois a mais antiga) continua no Feedback.

### 8. Números, sinais de status, acessibilidade do telégrafo, validador e memória (fechamento 2026-11-16)

- **Pool de números (TR-feedback-007, TR-feedback-015, TR-status-009).** Dono: este ADR. O `PoolDeNumeros` (RefCounted, lógica pura, testável sem engine) vive na Apresentação e corre no **relógio de apresentação** (`t_apres`); a vista só desenha. Regras (Feedback R6, F1, F2): por alvo, no máximo **um número aberto por faixa** — `golpe`, `dourado`, `status`. Golpe novo **soma** ao de golpe aberto se `t_agora − t_nasceu ≤ janela_soma_s` (300 ms), senão abre outro; o dourado nunca soma nem recebe soma; `parede` e reflexo/explosão no mesmo alvo e passo somam ao golpe. Soma em fração, arredonda no fim (< 0,5 sem número); cada soma reinicia a vida de 0,6 s. **Teto de 6** vivos: ao nascer o 7º sai um vivo pela F2 (o mais antigo). O **dano da Maldição** (Feedback R16) entra na faixa `golpe` do mesmo alvo e soma com o do jogador (número agregado jogador + Maldição). A opção "Números de dano" (F5) desliga o pool sem mudar dano. **Status:** quem conta o período em **passos vivos por inimigo**, com o resto acumulado (`round`, Status F5), é o módulo de Status, que emite o valor pronto; o pool só o mostra na faixa `status` (sem somar com golpe) e anima em `t_apres`. Morte entre períodos: nada; último status zerado com resto ≥ 1: número final.
- **Sinais de status (TR-status-012).** A vista lê `estado(inimigo)` (consulta pura do Status: `acumulos`, `restante` por status) em toda entrega; no máximo **3 sinais** por inimigo; com **mais de 9 inimigos marcados**, um só sinal por inimigo (o de maior acúmulo). Os sinais entram no grupo VFX do orçamento.
- **Contorno de acessibilidade do telégrafo (TR-telegrafos-013).** `tel_sdf` reserva o uniform `contorno_px`; com a opção de intensidade do telégrafo ligada (ADR-0013, `[acessibilidade]`), vale `contorno_telegrafo_alto_px` = 6 px × `escala_traco`. O crescimento continua **sem pulsar** (sem oscilação de alfa nem de largura), nas duas passadas z −5/z 5.
- **Validador (TR-pipeline-016).** Além do nó sem família (R1), o validador de debug acusa como erro de autoria todo nó `tel_sdf` cujo dono é da facção do jogador (Maldição, aliado, invocação), AC-PV-88.
- **Memória de textura (TR-pipeline-009).** Teto 512 MiB residente, alerta em 448; os tetos do Art Bible §8.6 somam 504 MiB no pior caso, então o VV13 dispara de propósito e fica registrado, não bloqueia. Medição: `Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)` amostrado na cena de estresse do E1 e na câmara do chefe, conferido com a captura PIX/RenderDoc (fonte de verdade). NEEDS VERIFICATION: a constante do monitor não está em `docs/engine-reference/godot/`.

### Key Interfaces

```gdscript
# escritor_de_globais.gd
@abstract class_name EscritorDeGlobais extends RefCounted
@abstract func escrever(nome: StringName, valor: Variant) -> void

# estado_visual.gd: lógica pura, sem RenderingServer
class_name EstadoVisual extends RefCounted
enum ModoTela { NORMAL, IMPACTO, BENCAO, TRANSICAO, MORTE }
enum ModoImpacto { NENHUM = 0, RECUSA = 1, CHEFE = 2, REDUZIDO = 3 }
func configurar(tuning: VisualTuning, relogio_monotonico_us: Callable) -> void
func pedir_impacto(modo: ModoImpacto, impact_passos: int) -> bool
func pedir_passe(tipo: StringName) -> PasseDeTela        # nunca nega; devolve wipe ou fade
func pedir_flash_telegrafo(area_canvas2: float) -> bool
func trocar_regiao(lut: Texture2D, cores: CoresDaRegiao) -> void
func definir_profundidade(p: int) -> void
func definir_bencao(ligada: bool) -> void                # o orquestrador decide
func avancar_apres(dt_apres: float) -> void
func globais_sujos() -> Dictionary                       # nome -> valor; limpa ao ler

# passe_de_tela.gd
class_name PasseDeTela extends RefCounted
func avancar(dt_apres_limitado: float) -> void
func progresso() -> float
func eh_fade() -> bool

# pipeline_visual.gd: único escritor
class_name PipelineVisual extends Node
func configurar(estado: EstadoVisual, orq: OrquestradorDoPasso, escritor: EscritorDeGlobais) -> void
func aplicar_quadro() -> void                            # chamado pelo Main, 1 vez por quadro
```

`EscritorDeGlobais` é `@abstract` (4.5, confirmado). Os dois métodos concretos são `void`, então a regra de `return` explícito do 4.7 não se aplica.

### Implementation Guidelines

- MUST ter um único escritor de globais e de uniforms de passe (`PipelineVisual`), uma vez por quadro e depois das ações da Transição.
- MUST escrever `t_vivo` e `t_apres` a partir dos valores do orquestrador, sem relógio próprio.
- MUST trocar a LUT e zerar os relógios só na última das seis ações.
- MUST manter todo `CanvasItem` de mundo com shader de uma das três pastas de família, e o validador ativo em debug.
- MUST duplicar o material por entidade no spawn e devolvê-lo ao pool no despawn.
- MUST pré-instanciar os 24 slots de telégrafo (48 nós) na carga.
- MUST NEVER usar `TIME` em shader de mundo, nem `fmod` nos relógios.
- MUST NEVER usar `draw_line`, `draw_arc` ou `Line2D` sem textura para traço de jogo.
- MUST NEVER ler a tela nos passes, nem pôr `WorldEnvironment` com glow.
- MUST NEVER deixar lógica de jogo ler o `EstadoVisual`: as regras não dependem do Pipeline.

## Alternatives Considered

| Alternativa | Benefício | Motivo de rejeição |
|---|---|---|
| Orquestrador chama `RenderingServer` direto | Um salto a menos | Quebra o "lógica pura sem engine" do ADR-0001 e os testes em memória |
| Passe de tela para o impact frame | Um shader só | O GDD decide modo global por material; o passe custaria +1 tela de overdraw e não faria o contorno por família |
| Plano B (uniform por material) como padrão | Não depende do E2 | Custa N escritas por troca e um registro de materiais; fica como fallback |
| Marca de família por constante no shader | Mais explícita | O validador teria de analisar o código; a pasta é verificável por caminho e por teste estático |
| Manter `world_view.gd` com `_draw()` | Já funciona na fatia | Um único `CanvasItem` não aceita famílias nem camadas; linhas sem feather no 4.7 |
| Telégrafos criados e destruídos por ataque | Menos memória ociosa | Picos de alocação; o pool fixo casa com o teto de 24 e com o ADR-0014 |

## Consequences

Os ganhos: a regra P3 vira propriedade verificável (família por pasta, telégrafo em z 5, globais com um escritor), e a lógica visual (limitador, oclusão, modos, passes) fica testável sem render. Os custos: um material por entidade, 48 nós de telégrafo residentes e dependência de experimentos para três APIs centrais. Se o E2 reprovar os globais, o plano B troca só o escritor. Se o E1 mostrar o lote do y-sort, o orçamento sobra, e ele nunca é contado a favor.

## Risks

- **Globais em `canvas_item` ou com Shader Baker falham (E2):** mitigado pelo plano B, já atrás da mesma interface.
- **Paridade D3D12 × Vulkan:** o E2 roda nos dois backends (`--rendering-driver vulkan`), com captura no PIX e no RenderDoc.
- **Material por entidade caro na CPU (E7):** o fallback é material compartilhado por papel, com `flash` via `modulate` reservado. Esse fallback muda a R6 e precisa de decisão.
- **Emissores ignoram `speed_scale` 0 (E3):** o fallback é `emitting = false` mais `interpolate`/avanço manual, ou `CPUParticles2D` avançadas pelo passo.
- **`fit_margin` em unidade errada (E5):** o contorno é cortado. O E5 mede e corrige a fórmula.
- **Contagem de draw calls 2D invisível no monitor (E1):** a verdade fica só na captura, e o proxy do Feedback vira estimativa conservadora.

## GDD Requirements Addressed

| GDD | Requisito | Como |
|---|---|---|
| pipeline-visual.md | R1 famílias, include, marca, lista fechada | §4: pastas, includes, validador e teste estático |
| pipeline-visual.md | R2, F1 LUT global ou plano B; Bênção F5 | §3, §6; `definir_bencao` decidido pelo orquestrador, saída em `tela_fechada` |
| pipeline-visual.md | R3, F2 `fator_profundidade` na CPU, em linear | §1, §3 |
| pipeline-visual.md | R5, F4 telégrafo em duas passadas e malha de borda | §5: 24 slots × (quad z −5 + `ArrayMesh` z 5) |
| pipeline-visual.md | R6 material por entidade, `CanvasGroup`, imagens residuais | §5; E5 escolhe snapshot (a) ou rig (b) |
| pipeline-visual.md | R7, F6 impact frame global, limitador, wipe, morte; AC-PV-81 | §2, §7 |
| pipeline-visual.md | R8, F8 relógios sem `TIME`, zero no meio do wipe | §2, §3 |
| pipeline-visual.md | R9, F10 orçamento 500 e overdraw | Performance Implications; proxy e captura |
| pipeline-visual.md | R10 chaves de projeto; R12–R13 tuning e injeção | Migration Plan; `configurar()` |
| feedback-de-combate.md | R4/R8 limitador e degradação; R11 impact frame não é camada; R12 preempção | §7 |
| combate-nucleo.md | Transição: seis ações no quadro ≥ 0,5 | §2 (`PasseDeTela` avançado pelo orquestrador) |
| feedback-de-combate.md | R6, F1, F2, F5, R16 (TR-feedback-007, TR-feedback-015) | §8: `PoolDeNumeros` com faixas, 300 ms, teto 6, número agregado jogador + Maldição |
| efeitos-de-status.md | R8, F5 (TR-status-009); estado(inimigo) e multidão (TR-status-012) | §8: valor do período vem do Status; máx. 3 sinais, um só com > 9 marcados |
| telegrafos.md / pipeline-visual.md | contorno 6 px, sem pulsar (TR-telegrafos-013) | §8: `contorno_px` em `tel_sdf` |
| pipeline-visual.md | R5b, AC-PV-88 (TR-pipeline-016) | §8: validador acusa `tel_sdf` com dono da facção do jogador |
| pipeline-visual.md | R9 memória 512/448 MiB (TR-pipeline-009) | §8: monitor + captura no E1 e na câmara do chefe |

## Performance Implications

O teto é de 500 draw calls: ambiente 40, sombras e telégrafos 54 (6 + 24 × 2), entidades 200, VFX 64, passes 6, UI 80, reserva ≥ 56. O orçamento é contado **sem lote**, exceto nas sombras. Overdraw: ≤ 3,5 telas na média e ≤ 5 no pico. A malha de borda tira cerca de 0,6 tela no pico de 24 telégrafos, em relação ao contorno em quad cheio (F10: 1,38 → 0,76), ao custo de vértices CPU fixos por slot. Os passes ocultos custam 0, e o wipe soma +1 tela só durante 0,4 s, medido à parte. A CPU escreve 2 globais por quadro mais os sujos. No plano B, a troca de LUT custa N escritas sob a tela coberta. A memória da LUT é de 128 KiB por região. Partículas, luz e memória de textura seguem a R9 sem mudança.

## Migration Plan

1. Rodar o E1–E3 num projeto de protótipo em `prototypes/pipeline-verificacao/`, sem tocar no `project.godot` principal.
2. Após o aceite, declarar as chaves da R10 e os `[shader_globals]` (nomes confirmados pelo E2).
3. Criar `EstadoVisual`, `PasseDeTela` e `LimitadorDeFlashes` com testes em `tests/unit/pipeline_visual/`.
4. Trocar o `_draw()` de `world_view.gd` por nós por camada (ADR-0007): primeiro o ambiente com `amb_sprite`, depois as entidades com `AnimatedSprite2D` e `char_sprite` sobre os atlas existentes (conferindo a margem de 6 texels da OQ12 e reimportando se faltar), por fim os telégrafos do pool. `world_view.gd` fica como desenho de debug até a cena nova passar na captura.
5. Ligar Feedback, passes e Bênção.

## Validation Criteria

Plano dos experimentos. Cada um retém capturas em `production/qa/evidence/`.

- **E1 (draw calls 2D):** cena de estresse da F10 (24 telégrafos, 120 entidades, 60 props, 24 emissores, 40 flipbooks). Comparar `Performance` e monitor do editor com PIX (D3D12) e RenderDoc (Vulkan), medindo por diferença D_g. Passa se a soma ficar ≤ 500 e o monitor for fiel ±5%. Senão, a captura é a única verdade.
- **E2 (globais e LUT):** shader `canvas_item` com `global uniform float`, `int` e `sampler2D`, escrito por `global_shader_parameter_set`; exportar com Shader Baker; testar hints `filter_linear`/`repeat_disable` no global e a LUT identidade (diferença ≤ 1/255). Rodar em D3D12 e Vulkan. Se reprovar, usar o plano B para o item reprovado.
- **E3 (relógios):** `TIME` com o jogo parado, `speed_scale` 0 em GPU e CPU particles, avanço manual de `AnimatedSprite2D`. Passa se nada animar no hitstop simulado de 36 passos.
- **E4 (SDF do telégrafo):** contorno de 4 px a 1080p, 1440p e 4K, malha de borda × quad e custo de GPU com 24 telégrafos.
- **E5 (`CanvasGroup`):** contorno por fora, inversão, unidade do `fit_margin`, `TEXTURE_PIXEL_SIZE` e custo; snapshot × rig duplicado para as imagens residuais.
- **E6 (fio de vínculo):** `Line2D` com textura × quad SDF de segmento (suavização e custo).
- **E7 (material por entidade):** 9, 20 e 40 entidades com material próprio × compartilhado, medindo tempo de CPU por quadro; `instance uniform` em `canvas_item`.

Testes em memória: F6 (exemplos do GDD), F9, ordem de prioridade dos modos, `PasseDeTela` ≥ 0,5 uma vez e fade com a janela cheia.

## Emenda (2026-11-16): Doutrina de Pactos

Conferido contra `pipeline-visual.md` (emenda Pactos: R5a, R5b, AC-PV-84 a 88, OQ 15–16):

- **Depends On + ADR-0014**: o pool de 24 slots (48 nós) é indexado por `VistaDeTelegrafo.slot`. A direção fica 0011 → 0014; o 0014 só lista este ADR em Enables (sai o ciclo implícito apontado pela revisão de 2026-11-15).
- **R5a, contorno tracejado secundário**: quando o telégrafo do chefe mira a Maldição (alvo travado, ADR-0014), o slot desenha **um** contorno secundário, círculo no raio do alvo, só contorno (sem preenchimento, núcleo nem anel), tracejado, `contorno_telegrafo_px` (4 px), na camada `contorno de telégrafo` (z 5), **na mesma malha de borda do contorno principal** (mesma draw call; só vértices a mais). Some no passo em que o flash do principal começa, sem flash próprio. Modo de impacto como o principal. Não muda o teto de 54 draw calls de sombras e telégrafos.
- **R5b, VFX das Maldições**: fio de vínculo (jogador → peito da Maldição em campo, `largura_fio_px` × `escala_traco`, some na reserva, Exaustão e troca de câmara) e marca do Virote, ambos em `traco_sdf` da família `sem_grading`, no pool do Feedback; **nenhum telégrafo SDF para golpe de Maldição** (ML-V4). O corpo da Maldição é `char_sprite` (família `char_tint`), como aliado: tinta chapada com contorno osso, sem contorno de invulnerabilidade nem inversão (só o jogador).
- As faixas novas entram no `VisualTuning` com as regras VV do dono; nenhum shader novo na lista fechada.

## Nota de preparação para co-op

A oclusão, o `CanvasGroup` e o contorno de invulnerabilidade são **por jogador**. O `EstadoVisual` guarda listas indexadas por `player_id` (0 no solo), e cada herói terá seu grupo. Os globais e o modo de tela continuam únicos por máquina: num host autoritativo, cada cliente roda o próprio Pipeline com os eventos replicados, e o limitador F6 é local (acessibilidade de quem olha a tela). Não há código de rede aqui.

## Decisões do usuário (resolvidas em 2026-11-15)

**O usuário aceitou todas as recomendações abaixo em 2026-11-15.** Elas valem como decisão deste ADR; o texto de cada item fica como registro das opções.

1. **Redução de movimento ligada no meio de um wipe (OQ14).** Opções: (a) o passe atual termina como começou; (b) vira fade na hora. **Recomendo (a)**: não há salto visual, e o próximo passe já sai em fade.
2. **Fallback do E7, se o material por entidade for caro:** material compartilhado por papel, com o flash via `modulate`. Isso muda o "estado por entidade" da R6 e só vale se o E7 reprovar.
3. **Valores artísticos ainda abertos (OQ3, OQ13, OQ14):** o "passo na escada" do `reduzido` e a cor do contorno no `disparo` ficam com o art-director. Este ADR só reserva os uniforms.

## Clarificações para revisão consolidada

- GDD R8 ("o orquestrador escreve os relógios") e `architecture.md`, conflito 2 ("o Orquestrador liga `modo_bencao`"): lidos aqui como posse do valor. A escrita é só do `PipelineVisual`.
- ADR-0007 ("progresso do wipe é do Pipeline") e ADR-0001 (lê ≥ 0,5): o `PasseDeTela` é do Pipeline e é avançado pelo orquestrador.
- ADR-0014 precisa expor o estado por **slot** (0–23) para o pool de nós daqui. **Resolvido em 2026-11-15:** `VistaDeTelegrafo.slot`. Os campos `flash_passos` (`EvAcerto`), `inversao_passos` (`EvJogadorAtingido`) e `impact_passos` (`EvInimigoMorreu`) já constam do ADR-0010 §10.

## Verificação de engine (2026-11-17)

Fontes: `prototypes/pipeline-verificacao/` (`pipeline_probe.gd`, `project.godot`, `export_presets.cfg`, `shaders/`) e evidências em `production/qa/evidence/experimentos/ex-0001-3-global-set.md`, `ex-0011-e1-e3.md` e `ex-0011-e4-e7.md` (Stories 006 e 007 de `experimentos-de-engine`). Godot 4.7.2.stable, Windows 11, Ryzen 5 5600H + RTX 3050 Laptop.

- **EX-0001-3 (`RenderingServer.global_shader_parameter_set` e `[shader_globals]`): VERIFICADO.**
  - Custo em 10 000 quadros: **2 chamadas/quadro** (`t_vivo`, `t_apres`) = média `1,8 µs`, p50 `2 µs`, p99 `4 µs` (0,02 % de 16,6 ms); **20 chamadas/quadro** (todos os globais sujos + LUT) = média `14,6 µs`, p50 `14 µs`, p99 `29 µs` (0,17 % de 16,6 ms).
  - Chaves de `[shader_globals]` confirmadas no `project.godot`: `lut_regiao` (`sampler2D`), `cor_nevoa`, `cor_feixe`, `cor_fundo` (`color`), `fator_profundidade`, `saturacao_bencao`, `valor_bencao`, `t_vivo`, `t_apres`, `escala_traco` (`float`), `modo_impacto`, `modo_bencao`, `modo_morte` (`int`).
  - Chaves de projeto da R10 confirmadas: `rendering/textures/canvas_textures/default_texture_filter=2`, `rendering/2d/snap/snap_2d_transforms_to_pixel=false`, `rendering/2d/snap/snap_2d_vertices_to_pixel=false`, `rendering/viewport/hdr_2d=false`, `shader_baker/enabled=true` em `export_presets.cfg`.
- **E1 (orçamento de draw calls 2D na cena de estresse F10 ≤ 500 e monitor `Performance`): VERIFICADO.**
  - Na cena de estresse F10 (60 props, 120 entidades, 24 telégrafos × 2 passadas = 48 nós, 40 flipbooks, 24 emissores), a soma analítica sem lote dos grupos da R9 (`40 + 54 + 200 + 64 + 6 + 80 = 444`) fica `≤ 500` com `56` de reserva, e `D_g` medido via `Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)` foi de `292` draw calls (`293 - 1`).
  - Como o `RendererCanvasRender` aplica batching automático quando materiais/texturas coincidem, a degradação em runtime do Feedback usa o **proxy determinístico por grupo** no `EstadoVisual` (nós visíveis sem contar lote a favor, exceto sombras), mantendo `Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME` e `Performance.RENDER_TEXTURE_MEM_USED` como telemetria e a captura PIX/RenderDoc como verdade visual.
- **E2 (`global uniform` em `canvas_item`, LUT identidade e Plano B): VERIFICADO.**
  - `global uniform sampler2D lut_regiao : filter_linear, repeat_disable;`, `global uniform float` e `global uniform int` compilam e funcionam em `canvas_item` (D3D12/Vulkan).
  - Amostragem manual F1 sobre a LUT identidade `1024×32` (32 fatias `32×32`, meio texel de margem, sem mipmaps e sem `source_color`) apresentou erro máximo `≤ 1/255` nas 5 832 cores da grade `18³` (AC-PV-07).
  - **Decisão:** `EscritorGlobalRS` é o escritor padrão para todos os globais (incluindo `lut_regiao`), preservando `EscritorPorMaterial` atrás da interface `EscritorDeGlobais` como fallback seguro sem impacto nos shaders de cena.
- **E3 (congelamento de `t_vivo`, `speed_scale = 0` em partículas e `AnimatedSprite2D`): VERIFICADO.**
  - Nos 36 passos simulados de hitstop (e corroborado por `EX-0001-4`), nenhum shader de mundo usa `TIME`, `t_vivo` congela (`Δ = 0`), `t_apres` avança normalmente, e `speed_scale = 0.0` em `GPUParticles2D`, `CPUParticles2D` e `AnimatedSprite2D` congela toda animação sem reemissão nem salto ao retomar.
- **E4 (contorno SDF de telégrafo de `4 px` em 1080p/1440p/4K e malha de borda vs quad): VERIFICADO.**
  - Contorno interno `−w ≤ d ≤ 0` com `aa = fwidth(d)` produz exatamente `4,00 px` físicos em 1080p, `5,33 px` em 1440p (`6,13 px` com zoom `1,15`) e `8,00 px` em 4K.
  - **Decisão (Opção A confirmada):** contorno em `z = 5` usa `MeshInstance2D` com `ArrayMesh` de borda (`r − w − 2` a `r + 2`), reduzindo a área sombreada do contorno em **90,0 %** no `C120` (`5 931,3` vs `59 536` unid.²) e mantendo o overdraw de 24 telégrafos em `0,7577 ≤ 0,80` tela (contra `1,3781` em quad duplo).
- **E5 (`CanvasGroup` com `fit_margin`, contorno externo, inversão e imagens residuais): VERIFICADO.**
  - `CanvasGroup.fit_margin` e `clear_margin` operam em unidades/pixels locais de canvas; fixados em **`8.0`** para acomodar o contorno de silhueta (`3 px`) e o tracejado (`1,75 px`) sob zoom `1,15` sem corte. O shader `char_grupo.gdshader` lê `hint_screen_texture` com `SCREEN_UV` e `SCREEN_PIXEL_SIZE * escala_traco`.
  - **Decisão para imagens residuais:** **Opção (a) confirmada** (1 sprite/snapshot da pose com `traco_sdf` por imagem residual = 3 draw calls no y-sort, sem duplicar 3 `CanvasGroup`s).
- **E6 (fio do Vínculo: `Line2D` com textura vs quad SDF): VERIFICADO.**
  - **Decisão:** escolhido **Quad/Tira com `traco_sdf.gdshader` (SDF de segmento + `fase_tracejado` F7)** em vez de `Line2D` texturizada. Garante suavização analítica de 1 px físico em qualquer resolução (no 4.7 linhas nativas não têm feather) e mantém a tabela fechada da R1 e a emenda R5b intactas (`traco_sdf` em `z = -5`, 1 draw call).
- **E7 (`ShaderMaterial` por entidade vs compartilhado vs `instance uniform` para 9, 20 e 40 entidades): VERIFICADO.**
  - `instance uniform` compila e funciona em `canvas_item` no Forward+ (4.7.2), mas o custo de CPU de manter **1 `ShaderMaterial` próprio por entidade** (duplicado no spawn) atualizando uniforms a cada passo é de apenas **p50 `5 µs` / p99 `11 µs` para 9 entidades**, **`11 µs` / `22 µs` para 20** e **`21 µs` / `43 µs` para 40 entidades** (< 0,3 % do quadro).
  - **Decisão:** mantido **`ShaderMaterial` próprio por entidade** no pool do y-sort (R6 e §5), sem necessidade do fallback de `modulate` nem de `instance uniform`.

## Related

GDDs: pipeline-visual, feedback-de-combate, cena-3-4-e-camera, combate-nucleo (R1, Transição). ADRs 0001, 0002, 0004, 0007, 0010 (eventos com `flash_passos`, `inversao_passos`, `impact_passos`), 0012, 0014. Código atual: `src/presentation/world_view.gd`; atlas `assets/art/runtime/{iniciado_lamina,eco_perdido,fenda_errante,anomalia_menor}/`.
