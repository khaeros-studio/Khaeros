# ADR-0001: Orquestrador do passo e estados de jogo

## Status
Accepted · 2026-11-16 (aprovado pelo usuário; Proposed em data do ADR)

## Date
2026-11-13

## Last Verified
2026-11-17 (experimentos EX-0001-1..6 no Godot 4.7.2: VR(1), VR(2), VR(4), VR(5) e VR(6) verificados; `NOTIFICATION_APPLICATION_FOCUS_OUT`, ausência de `pause_on_focus_loss`, `process_mode = PROCESS_MODE_DISABLED` / parada explícita e clamp `dt_max_apres` no 1º quadro registrados). Antes: 2026-11-16 (emenda Pactos: item 6.1 Maldições, Bênção também para a tela de consentimento, citação do Pipeline corrigida para R8). Antes: 2026-11-15 (revisão: final comum do passo, contadores `n_vivos` e `passos_em_jogo`, pedidos de estado; lacunas 1 e 2 de `architecture-review.md`). Original: 2026-11-13, contra `docs/engine-reference/godot/` e os GDDs aprovados.

## Decision Makers
Usuário (khaeros-studio) e Claude (sessão de Arquitetura). TD-ADR não rodou (review_mode lean).

## Summary
Oito dos 22 GDDs do MVP pressupõem um "orquestrador do passo" que nenhum define: ordem fixa dos itens do passo, estado de jogo, congelamento por hitstop, relógios `t_vivo` e `t_apres` e a troca de câmara no quadro de render. Decidido: um `OrquestradorDoPasso` em lógica pura (`RefCounted`, sem `SceneTree`, com estado de jogo próprio e sem `SceneTree.paused`), acionado por um `Node` raiz fino que só repassa `_physics_process` e `_process`.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (pin 4.7.2) |
| **Domain** | Core (Scripting) |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` |
| **Post-Cutoff APIs Used** | `@abstract` (4.5, confirmado), usado na base `Passo`. Regra do 4.7 (confirmada): `override` de método com retorno tipado **não-void** herda o tipo e exige `return` explícito. `passo()` e `passo_congelado()` retornam `void` e não precisam de `return`; todo override futuro com retorno não-void precisa |
| **Verification Required** | (1) `physics/common/physics_ticks_per_second` (=60) e `max_physics_steps_per_frame` (=8): **VERIFICADOS** no 4.7.2 (`EX-0001-1`); o `delta` de `_process` é suavizado por `physics_jitter_fix` (0.5 padrão) e atrasos ≥ 250 ms batem no teto 8 e descartam tempo; (2) ordem `_physics_process` antes de `_process` dentro do mesmo quadro: **VERIFICADA** (`EX-0001-2`, 0 violações; 0 passos em quadros acima de 60 Hz é normal); (3) `RenderingServer.global_shader_parameter_set` chamado a cada quadro (usado pelo Pipeline, ADR-0011): continua a verificar no protótipo do Pipeline; (4) parar a Apresentação sem `SceneTree.paused`: **VERIFICADO** (`EX-0001-4`) — tanto `process_mode = PROCESS_MODE_DISABLED` no nó-raiz da apresentação quanto a parada explícita por tipo (`Tween.pause()`, `AnimationPlayer.speed_scale = 0`, `GPUParticles2D`/`CPUParticles2D`/`AnimatedSprite2D.speed_scale = 0`, `AudioStreamPlayer.stream_paused = true`) congelam todos os seis tipos e retomam limpo; (5) notificações de foco no `Main`: **VERIFICADO** (`EX-0001-5`) — `NOTIFICATION_APPLICATION_FOCUS_OUT` chega primeiro e uma vez por troca (gatilho de `pedir_estado(PAUSA)`); `NOTIFICATION_WM_WINDOW_FOCUS_IN` pode chegar duplicado ao restaurar janela (tratar ganho de foco como idempotente); `application/run/pause_on_focus_loss` **não existe** no 4.7.2 (`ProjectSettings.has_setting` = false; removido); desconexão de gamepad (`Input.joy_connection_changed`) confirmada na API, pendente de teste com hardware físico; (6) loop modal de mover janela e 1º quadro no Windows: **VERIFICADO** (`EX-0001-6`) — o loop modal de mover não gera `delta` > 0,05 s; o maior `delta` real vem do **1º quadro** da execução (0,13–0,14 s com 7–8 passos), coberto pelo clamp `dt_max_apres` (0,1 s) ativo desde o 1º quadro |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None (primeiro ADR) |
| **Enables** | ADR-0002 (Canal de eventos: o orquestrador esvazia a lista no fim do passo), ADR-0006 (Input por passo), ADR-0007 (Cena e câmera), ADR-0010 (Resolução do combate no passo), ADR-0011 (Pipeline visual: relógios), ADR-0012 a ADR-0018 (estados, pedidos de estado, passo fixo e orçamento) |
| **Blocks** | Qualquer épico de Foundation, Core ou Feature que rode dentro do passo |
| **Ordering Note** | Os ADRs 0002, 0006, 0007, 0010 e 0011 detalham pontos que este ADR só delimita (canal de eventos, buffer, interpolação, ordem interna do Combate, globais do Pipeline) |

## Context

### Problem Statement
O Combate (R1) diz que "o orquestrador do passo chama, nesta ordem" dez itens, mas nenhum GDD diz o que é o orquestrador, onde vive, quem o constrói nem como pausa, bênção e transição de câmara o afetam. Sem decisão, cada módulo assume um dono diferente, e a ordem do passo (de que dependem determinismo, hitstop e testabilidade) fica espalhada pelo `SceneTree`.

### Constraints
- Passo de simulação fixo de 60 Hz; hitstop é contador de passos, nunca `Engine.time_scale` (Combate R10).
- Lógica de jogo sem `SceneTree` e sem singleton, tudo injetado (princípios de arquitetura 2 e 4; `coding-standards.md`: injeção em vez de singleton).
- A Apresentação só lê (princípio 4); a Transição troca de câmara no quadro de render em que `progresso_wipe` ≥ 0,5, enquanto os passos de física seguem a 60 Hz (Combate R1, Pipeline R7).
- Pausa, Bênção, Menus, Morte e Transição não descontam nenhum contador, nem o de hitstop.
- Godot 4.7: retorno tipado herdado em `override` exige `return` explícito; as chaves de `physics/common/*` não estão cobertas pela referência da engine.

### Requirements
- Executar os 10 itens do passo vivo (Combate R1) em ordem fixa, só no estado Jogo.
- Congelar o passo quando há hitstop, sem descontar nada, e chamar `passo_congelado()` do Movimento fora do estado Jogo (Movimento R2).
- Manter o estado de jogo (Jogo, Pausa, Bênção, Menus, Morte, Transição) e expô-lo ao Input (contexto), HUD, Pipeline e Câmara.
- Manter `t_vivo` (avança 1/60 por passo vivo, parado no hitstop) e `t_apres` (tempo real com teto `dt_max_apres`, 0,1 s) e entregá-los ao Pipeline (Pipeline R8).
- Contar os passos em estado Jogo **incluindo os de hitstop**, para a duração da run (Run F3) e da câmara (Telemetria F1).
- Entregar a lista de eventos uma vez por passo físico, em todo estado (ADR-0002), e aplicar as trocas de estado pedidas pelos módulos num ponto único.
- Executar na troca de câmara as seis ações em ordem no mesmo quadro (Combate R1, Transição).
- Ser testável em memória, com módulos falsos.

## Decision

Quatro peças, todas na Foundation.

**1. `OrquestradorDoPasso` (lógica pura).** Classe `RefCounted`, sem `SceneTree`, que guarda o estado de jogo e a ordem do passo. Recebe todos os módulos por injeção. Não lê `Input` do Godot nem o relógio de parede: o tempo entra como `delta_real` em `quadro()` e como contagem de passos.

**2. `Main` (nó fino na cena raiz).** Constrói os módulos na ordem de inicialização do `architecture.md`, injeta, e só repassa os dois ganchos da engine. Não é `Autoload`.

**3. Estado de jogo próprio, sem `SceneTree.paused`.** Enum `EstadoDeJogo` com `INICIANDO`, `MENU`, `JOGO`, `PAUSA`, `BENCAO`, `TRANSICAO`, `MORTE`. O orquestrador simplesmente não chama o passo vivo fora de `JOGO`. A UI e o Pipeline continuam funcionando porque nenhum nó é pausado pela engine; quem para é o relógio (`t_apres`).

**4. O Combate guarda o contador de hitstop** (R10). O orquestrador só **consulta** `combate.hitstop_ativo()` e, em passo congelado, manda o Combate descontá-lo. Isto corrige o mapa de posse do `architecture.md` v1, que dava o contador ao orquestrador.

**5. Final comum de todo passo físico** (revisão de 2026-11-15). Todo `passo_fisico()`, seja vivo, congelado por hitstop ou fora de `JOGO`, termina no mesmo bloco `_finalizar_passo(vivo)`, nesta ordem:
1. se o passo foi vivo, `n_vivos += 1`; `t_vivo()` devolve `n_vivos / 60.0` (contador inteiro, sem soma de float acumulada; Pipeline F de `t_vivo`);
2. se o estado no início do passo era `JOGO` (vivo **ou** congelado por hitstop), `n_passos_em_jogo += 1`;
3. `eventos.esvaziar()` exatamente uma vez e entrega à Apresentação, **mesmo com a lista vazia** (ADR-0002). Um evento de UI emitido fora do passo (clique na Tela de bênção) entra na lista e sai neste ponto do passo seguinte;
4. aplica o pedido de estado pendente (decisão 6).

**6. Pedidos de estado.** Os módulos não trocam o estado: chamam `pedir_estado(novo)`. Durante o passo o pedido fica **pendente** e só vale no passo 4 do final comum; fora do passo (UI, foco da janela) vale na hora, se permitido. Com dois pedidos no mesmo passo, `MORTE` vence qualquer outro (Run R5: morte vence a limpeza). Origens:

| Para | Quem pede | Quando |
|---|---|---|
| `MORTE` | Combate | varredura de mortes (item 9) com o jogador sem recusa restante |
| `BENCAO` | Portas | `camara_limpa` aceita, ao pedir a oferta às Bênçãos |
| `TRANSICAO` | Câmaras | interação com a porta |
| `MENU` | `SessaoDeJogo` (fora do passo: escolha de arma/dupla, abandono) · Run (vitória, mesmo passo de `run_encerrada`) · UI ao fim de `MORTE` (ADR-0015 §3); `MENU → TRANSICAO` no início da run | menus, escolha de arma e dupla, telas finais |
| `BENCAO` | Vínculo (ADR-0015 §5, porta do Vínculo; o `ModuloDeMaldicoes` é do ADR-0017) · Run/Câmaras, escolha do chefe Pactuar/Exorcizar (ADR-0015) | tela de consentimento do pacto; tela de escolha do chefe |
| `JOGO` | Bênçãos (após `tela_fechada`) · Vínculo (ao fechar o consentimento) · orquestrador (fim do wipe) | ao fechar a tela ou no fim da Transição. A escolha do chefe é aplicada no 1º passo vivo depois que a tela fecha (ADR-0015) |
| estado anterior | menu de pausa, por `retomar()` | volta a `JOGO` ou `BENCAO`, o que estava antes da pausa |
| `PAUSA` | Input/`Main` | menu, perda de foco, desconexão do gamepad ativo, só a partir de `JOGO` ou `BENCAO` (Run: pausa abre em Bênção) |

`t_vivo` (com `n_vivos`) e `t_apres` zeram na ação de troca de câmara, na metade do wipe (Combate R1, Pipeline R7), e não no pedido de `TRANSICAO`. `passos_em_jogo()` nunca zera dentro da run.

### Architecture Diagram
```
Main (Node, cena raiz)                        OrquestradorDoPasso (RefCounted, lógica pura)
  _physics_process() ───────────────────────►  passo_fisico()
  _process(delta)    ───────────────────────►  quadro(delta_real)
                                                  │ estado: INICIANDO·MENU·JOGO·PAUSA·BENCAO·TRANSICAO·MORTE
                                                  │ relógios: t_vivo, t_apres
                                                  ▼
   passo_fisico() em JOGO, vivo:  Input → Combate-início → Movimento → Combate-golpe → Selo
                            → Maldições (item 6.1; ordem interna: ADR-0017 §Ordem do item 6.1, GDD maldicoes R23)
                            → Inimigos (telegrafos.varrer; ia.inicio_do_item_7; por inimigo vivo: avancar(1)→Status→Telégrafos→impacto→IA (ADR-0018);
                               fim_do_item_7 par a par; ADR-0010 §2)
                            → Projéteis → mortes → Câmaras
                            → _finalizar_passo(vivo = true)
   passo_fisico() em JOGO, hitstop:  Input (buffer com prazo parado) → Combate desconta 1
                            → Movimento.passo_congelado() → _finalizar_passo(vivo = false)
   passo_fisico() fora de JOGO:  Input no contexto do estado → Movimento.passo_congelado()
                            → _finalizar_passo(vivo = false)
   _finalizar_passo(vivo):  n_vivos += 1 se vivo · n_passos_em_jogo += 1 se começou em JOGO
                            · esvaziar() e entregar UMA vez (mesmo vazia) · aplicar pedido de estado (MORTE vence)
   quadro():  t_apres += min(delta_real, dt_max_apres) se JOGO/TRANSICAO/MORTE
              se TRANSICAO e progresso_wipe ≥ 0,5 e troca ainda não feita → 6 ações em ordem
              relógios → Pipeline
```

### Key Interfaces
```gdscript
# estado_de_jogo.gd (arquivo próprio, para os outros módulos não escreverem OrquestradorDoPasso.EstadoDeJogo)
class_name EstadoDeJogo
enum Valor { INICIANDO, MENU, JOGO, PAUSA, BENCAO, TRANSICAO, MORTE }

# orquestrador_do_passo.gd
class_name OrquestradorDoPasso extends RefCounted

func passo_fisico() -> void                      # 1 vez por _physics_process
func quadro(delta_real: float) -> void           # 1 vez por _process
func estado() -> EstadoDeJogo.Valor
func t_vivo() -> float                           # n_vivos / 60.0; zera na troca de câmara
func t_apres() -> float
func passos_em_jogo() -> int                     # passos em JOGO, incluindo hitstop; monotônico na run (Run F3, Telemetria F1)
func pedir_estado(novo: EstadoDeJogo.Valor) -> bool    # false se a transição não é permitida; dentro do passo fica pendente até o final comum
func retomar() -> bool                           # sai de PAUSA para o estado de antes (JOGO ou BENCAO); false fora de PAUSA
func hitstop_ativo() -> bool                     # consulta delegada ao Combate (Movimento R2, Input R6)
```
Módulos do passo implementam `Passo` (ver `architecture.md`, API 1): `passo(amostra)` e `passo_congelado()`. Em 4.7, um `override` com retorno tipado não-void precisa de `return` explícito; os dois métodos de `Passo` são `void`. Como o GDScript tem herança única, um módulo que já estende outra base expõe `Passo` por um objeto adaptador.

Consumidores de duração guardam o valor de `passos_em_jogo()` no início do que medem e calculam a diferença: a Run no início da run, a Telemetria no início de cada câmara. Exemplo da Telemetria (AC-TL-06): 1.044 passos em Jogo, 30 deles de hitstop, com 600 de pausa e 120 de Bênção, dão diferença 1.044 e `duracao_s = 17,40`.

### Implementation Guidelines
- Os módulos **must** receber o tempo como contagem de passos; **must never** ler `Time`, `OS` nem `Engine.time_scale` na lógica de jogo.
- **Must never** usar `SceneTree.paused` para pausar o jogo; **must never** declarar o orquestrador como `Autoload`.
- Nenhum módulo de jogo **must** ter `_physics_process` próprio; só a Apresentação pode ter `_process`. A ordem do passo é a do orquestrador, não a de `process_priority`.
- A ordem dos itens 3, 5, 7, 8 e 9 é do Combate (R1); a dos demais itens é dos donos. O orquestrador só a executa e **must** expô-la como uma lista única, testável.
- `project.godot` **must** declarar explicitamente `physics/common/physics_ticks_per_second = 60` e `physics/common/max_physics_steps_per_frame = 8` (padrões medidos no 4.7.2 em `EX-0001-1`, fixados explicitamente). O clamp `dt_max_apres` (0,1 s) **must** valer desde o 1º quadro de execução (onde ocorre o maior `delta` real, ~0,13–0,14 s).
- Fora de `JOGO`, em cada passo de física o orquestrador **must** chamar só o `passo_congelado()` do Movimento (Combate R1).
- Na Transição, as seis ações da troca de câmara **must** rodar uma única vez e no mesmo quadro, em ordem fixa.
- Testes **must** montar o orquestrador com módulos falsos que registram a ordem de chamada.
- Lógica de jogo **must never** usar `Timer` nem `create_timer`: o tempo é contagem de passos. Esperas de apresentação usam `t_apres` ou `t_vivo`.
- `quadro()` **must never** assumir "um passo por quadro" nem "passos = atraso / 16,7 ms": `physics_jitter_fix` (0.5 padrão) espalha a dívida e o teto `max_physics_steps_per_frame = 8` descarta atrasos > ~133 ms; entre dois quadros podem rodar 0 a 8 `passo_fisico()`.
- O passo é de 1/60 s a partir de **uma constante única**, validada contra `Engine.physics_ticks_per_second` em `Main._ready()`; se divergirem, o `Main` **must** falhar de forma ruidosa.
- A Apresentação **must** ser guiada por `t_vivo` ou parada em hitstop e pausa por `process_mode = PROCESS_MODE_DISABLED` no nó-raiz da apresentação ou parada explícita por tipo (`Tween.pause()`, `AnimationPlayer.speed_scale = 0`, `GPUParticles2D`/`CPUParticles2D`/`AnimatedSprite2D.speed_scale = 0`, `AudioStreamPlayer.stream_paused = true`; ambos verificados em `EX-0001-4`).
- A perda de foco da janela **must** ser capturada por `NOTIFICATION_APPLICATION_FOCUS_OUT` no `Main` (não existe `application/run/pause_on_focus_loss` no 4.7.2) e o retorno de foco **must** ser tratado de forma idempotente (`NOTIFICATION_WM_WINDOW_FOCUS_IN` pode repetir ao restaurar janela; `EX-0001-5`), virando `pedir_estado(PAUSA)` quando o estado é `JOGO` (`input-e-controle`, TR input-008), assim como a desconexão do gamepad ativo (`Input.joy_connection_changed`).
- O `Main` **must** injetar os módulos por método explícito (`configurar()`) antes de `add_child` dos nós de Apresentação, porque o `_ready()` dos filhos roda antes do do pai.
- Adicionar ou remover nós de física da engine dentro de `passo_fisico()` **must** ser evitado (pode gerar "Can't change this state while flushing queries"); se hitboxes forem `Area2D`, usar `call_deferred`. A decisão de hitboxes por geometria própria é do ADR-0010.

## Alternatives Considered

### Alternative 1: `Autoload` singleton `GameLoop`
- **Description**: o orquestrador é um `Autoload` com `_physics_process` e `_process`; os módulos o acessam por nome global.
- **Pros**: acesso simples, sem injeção; padrão comum em Godot.
- **Cons**: contraria o princípio "sem singleton"; os testes dependem do `SceneTree` e do estado global; qualquer módulo poderia pedir transição de estado.
- **Rejection Reason**: quebra a testabilidade em memória, que é a razão de existir da lógica pura.

### Alternative 2: Cada sistema com seu `_physics_process`, ordenado por `process_priority`
- **Description**: a ordem do passo emerge da prioridade dos nós; hitstop e pausa param os nós com `process_mode`/`SceneTree.paused`.
- **Pros**: nenhum código de orquestração; usa o modelo nativo da engine.
- **Cons**: a ordem fica implícita e espalhada; hitstop e Transição precisam parar uns nós e outros não; `SceneTree.paused` também pararia a UI da Bênção e o Pipeline; testes exigem a árvore.
- **Rejection Reason**: a ordem do passo é determinística e crítica (dez itens, com restrições entre eles), e deve ser lida num lugar só.

## Consequences

### Positive
- A ordem do passo, o hitstop e a Transição passam a ter um dono único e testável sem engine.
- Pausa, Bênção e Transição não dependem de `SceneTree.paused`: a UI e os relógios de apresentação seguem funcionando.
- Os oito GDDs que pressupõem o orquestrador deixam de depender de uma definição implícita.

### Negative
- Um módulo a mais para escrever e manter; o `Main` precisa montar todos os módulos na ordem certa.
- A pausa "por estado" exige disciplina: nenhum nó de jogo pode ter lógica própria fora do passo.
- Itens da engine continuam a verificar (passo atrasado, ordem `_process`/`_physics_process`).

## Risks
- **Passo atrasado ("espiral"):** se um quadro demora, o Godot pode rodar vários passos de física no mesmo quadro ou descartar tempo. *Mitigação:* definir `max_physics_steps_per_frame` explicitamente e medir no protótipo de arquitetura.
- **Ordem `_physics_process` vs `_process` não confirmada** na referência. *Mitigação:* o orquestrador não depende dela, porque guarda `troca_feita` e age no primeiro `quadro()` com `progresso_wipe` ≥ 0,5.
- **`Main` virar um nó gordo.** *Mitigação:* o `Main` só constrói, injeta e repassa; a lógica fica no `RefCounted`.
- **Pedido de estado no meio do passo:** um módulo posterior ainda roda no mesmo passo depois de um pedido de `MORTE`. *Mitigação:* o pedido só vale no final comum; Run e Portas consultam a morte antes de creditar (ADR-0002), e o final comum faz `MORTE` vencer.
- **`@abstract` e override (4.7):** esquecer o `return` explícito num `override` com retorno não-void quebra a carga. *Mitigação:* teste de carga dos módulos no CI.
- **Apresentação animando durante hitstop e pausa** (o risco mais provável de bug visível): sem `SceneTree.paused`, sprites, partículas e sons da engine continuam. *Mitigação:* guiar a Apresentação por `t_vivo` ou parar os players; verificação (4).
- **Janela sem foco ou arrastada:** o loop continua rodando sem foco, e o arraste no Windows pode gerar um `delta` grande no quadro seguinte. *Mitigação:* ligar o desfoco a `PAUSA`; verificações (5) e (6).
- **`delta` do `_physics_process` ignorado:** se `physics_ticks_per_second` mudar, `n_vivos / 60` fica errado. *Mitigação:* constante única validada em `Main._ready()`.
- **Entrada em quadro atrasado:** vários passos seguidos veem a mesma amostra, e um aperto e solto no mesmo quadro pode se perder. *Mitigação:* o buffer por evento alimenta o Input; decisão do ADR-0006.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| combate-nucleo.md | R1: ordem fixa dos 10 itens, só no estado Jogo (TR combate-nucleo-001, provisório) | `passo_fisico()` executa a ordem e só em `JOGO` |
| combate-nucleo.md | R10: hitstop como contador de passos, nunca `Engine.time_scale` (TR combate-nucleo-002) | Combate guarda o contador; o orquestrador consulta e congela |
| combate-nucleo.md | Transição: seis ações no quadro de `progresso_wipe` ≥ 0,5 (TR combate-nucleo-011) | `quadro()` executa as seis ações uma vez, em ordem |
| movimento-e-esquiva.md | R2: `passo_congelado()` fora de Jogo; Movimento não consulta hitstop (TR movimento-002, 003) | O orquestrador decide e chama `passo_congelado()` |
| cena-3-4-e-camera.md | Relógio de câmera é `t_apres`; corte no quadro do wipe (TR cena-009, 011) | O orquestrador mantém `t_apres` e dispara o corte na Transição |
| pipeline-visual.md | R8: `t_vivo` e `t_apres`, ambos a 0 no meio do wipe (TR pipeline-004) | O orquestrador mantém e entrega os dois relógios ao Pipeline |
| ia-de-inimigos-e-elites.md | IA roda no item 7, na ordem estável, nunca em hitstop (TR ia-001) | Ordem e congelamento garantidos pelo orquestrador |
| camaras-e-ondas.md | Câmara montada na metade do wipe; "câmara limpa" só com hitstop 0 (TR camaras-002, 007) | Montagem na ação 3 da Transição; avaliação só com `hitstop_ativo()` falso |
| run-e-regioes.md | Morte vence a limpeza no mesmo passo (TR run-005) | A varredura de mortes (item 9) roda antes das Câmaras (item 10), e no final comum `MORTE` vence outro pedido de estado |
| run-e-regioes.md | F3: duração em passos de Jogo, incluindo hitstop (AC-RN-23) | `passos_em_jogo()` conta o passo congelado em `JOGO` |
| telemetria-local.md | F1: duração da câmara em passos de Jogo, incluindo hitstop (AC-TL-06) | Diferença de `passos_em_jogo()` desde o início da câmara |
| input-e-controle.md | Perda de foco ou desconexão do gamepad pausa (TR input-008) | `pedir_estado(PAUSA)` a partir do estado `JOGO` |

## Performance Implications
- **CPU**: o orquestrador só despacha chamadas; custo próprio desprezível. Orçamentos dos módulos são dos GDDs (provisórios), somados abaixo (p99, build exportado):

| Bloco do passo vivo | Orçamento p99 |
|---|---|
| Movimento (item 4) | 0,2 ms |
| Combate (itens 3, 5, 7-impacto, 8, 9) | 0,3 ms |
| Maldições (item 6.1, ADR-0017) | 0,1 ms |
| IA de inimigos e chefe (item 7, ADR-0018) | 0,15 ms |
| Telégrafos (dentro do item 7, ADR-0014) | < 0,05 ms |
| Status (ADR-0009 não tem orçamento próprio; fixado aqui) | ≤ 0,05 ms |

**Harness comum de orçamento de CPU (TR-movimento-014).** Um único `MedidorDeOrcamento` (relógio injetado, `Time.get_ticks_usec()` no adaptador real) mede cada bloco desta tabela na cena de estresse, por passo, com média e p99 em 600 passos; o Movimento usa o mesmo harness contra o teto provisório de 0,2 ms. ADR-0017 e ADR-0018 medem contra este total de 1,0 ms, não contra 16,6 ms nem outro teto.
| Telemetria | até 3 ms só no passo da morte (fora do passo vivo comum) |
| **Total do passo vivo** | **≤ 1,0 ms** |

  Os blocos somam 0,75 ms; o resto da folga cobre Input, Selo, Projéteis, Câmaras e o final comum. Se a medição estourar 1,0 ms, o corte é decidido por este ADR, não por cada módulo.
- **Memory**: desprezível.
- **Load Time**: desprezível.
- **Network**: N/A.

## Migration Plan
O protótipo `prototypes/combate-camara-concept/` é descartável e não migra. A fatia jogável de 2026-11-14 concentra o passo em `src/gameplay/game_session.gd` (`step()`, com `hitstop` e `_pending_hitstop` locais) e em `src/app/main.gd`. No épico de Foundation, extrair o `OrquestradorDoPasso` dessa sessão: primeiro a ordem do passo e o final comum, com os testes da fatia passando, depois cada item para o módulo dono.

## Validation Criteria
- Teste unitário com módulos falsos prova a ordem exata dos 10 itens e que fora de `JOGO` só `passo_congelado()` é chamado.
- Teste prova que hitstop pendente não desconta contadores e que "câmara limpa" só é avaliada com `hitstop_ativo()` falso.
- Teste prova que as seis ações da Transição rodam uma vez, em ordem, no primeiro quadro com `progresso_wipe` ≥ 0,5.
- Teste prova o final comum: evento de UI enfileirado em `BENCAO` é entregue no passo seguinte; os eventos do passo que pede hitstop são entregues nesse passo; o passo congelado seguinte entrega a lista uma vez — em `JOGO` ela traz só o `EvPassoVivo` (o `n_vivo` conta hitstop, ADR-0002 catálogo), fora de `JOGO` vem vazia (ajuste de 2026-11-16, confirmado na implementação do orquestrador).
- Teste reproduz AC-TL-06 (17,40 s) e AC-RN-23 (3.600 passos com hitstop = 60 s) por `passos_em_jogo()`, e prova que `t_vivo` para no hitstop.
- Teste prova que pedidos de `MORTE` e `BENCAO` no mesmo passo resultam em `MORTE`, aplicada só no final comum.
- Experimento no protótipo de arquitetura fecha os seis itens de "Verification Required".

## Emenda (2026-11-16): Doutrina de Pactos
- **Item 6.1 Maldições** entra no passo vivo entre Selo (6) e Inimigos (7). Ordem completa (Combate R1): 1 Input · 2 hitstop? · 3 Combate-início · 4 Movimento · 5 Combate-golpe · 6 Selo · **6.1 Maldições** (ordem interna: ADR-0017 §Ordem do item 6.1, GDD maldicoes R23; a troca automática da Exaustão sai em `exaurir`, chamado pelo Combate nos itens 7/8) · 7 Inimigos · 8 Projéteis · 9 varredura de mortes · 10 Câmaras. O orquestrador chama `ModuloDeMaldicoes` (ADR-0017) como mais um `Passo` injetado; no hitstop o item não roda (os contadores da reserva e a recarga da Troca congelam junto). Em runs sem Pactos o módulo existe e não faz nada.
- **Acuada** (criatura do encontro de pacto) não tem item próprio: o dano nela entra nos itens 7/8 e a falha do encontro é avisada ao Vínculo antes do item 9 (ADR-0015, ADR-0017).
- **Estado `BENCAO`** também serve à **tela de consentimento do pacto** (ADR-0012, ADR-0015): mesmas regras de pausa, relógios e contexto de Input; nenhum estado novo no enum.
- Citação dos relógios corrigida: `t_vivo`/`t_apres` são **Pipeline R8** (antes citado como R4).

## Nota: preparação para co-op (2026-11-13)
Decisão do usuário: co-op online de 1 a 4 jogadores depois do MVP solo, com host autoritativo. **Esta nota não muda a decisão do ADR e não prevê código de rede.** Para a base solo não impedir o co-op: o orquestrador roda só no host e o cliente roda só a Apresentação; o estado de jogo (`EstadoDeJogo`) segue global; e o `Passo.passo(amostra)` do passo vivo passará a receber as amostras por jogador (indexadas por `player_id`, 0 no solo) quando o co-op entrar. Detalhes e regras em `docs/architecture/architecture.md`, seção "Preparação para co-op".

## Verificação de engine (2026-11-16)

Fonte: `production/epics/experimentos-de-engine/` (Completion Notes), `production/qa/evidence/experimentos/ex-0001-passo-e-quadro.md` e `production/qa/evidence/experimentos/ex-0001-foco-e-apresentacao.md`. Editor 4.7.2 standard, Windows 11.

- **VR(1) VERIFICADO (`EX-0001-1`):** `physics/common/physics_ticks_per_second = 60` e `physics/common/max_physics_steps_per_frame = 8` são os padrões medidos no 4.7.2. O `delta` de `_process` é suavizado pelo `physics_jitter_fix` (0.5 padrão), um atraso isolado não produz `atraso / 16,7` passos imediatos e, com 250 ms de atraso, o teto 8 (~133 ms) descarta o restante. **Exigência:** gravar as duas chaves explicitamente no `project.godot` de produção.
- **VR(2) VERIFICADO (`EX-0001-2`):** em 100 quadros medidos (0, 1 e 2+ passos), 0 violações — todos os `_physics_process` do quadro rodam antes do `_process` daquele quadro; quadros com 0 passos chamam apenas `_process` (71% dos quadros sem vsync a ~1 100 fps).
- **VR(4) VERIFICADO (`EX-0001-4`):** com apenas a flag lógica própria, `Tween`, `AnimationPlayer`, `AnimatedSprite2D`, `AudioStreamPlayer`, `GPUParticles2D` e `CPUParticles2D` seguem rodando. Tanto `process_mode = PROCESS_MODE_DISABLED` no nó-raiz da apresentação quanto a parada explícita por tipo (`Tween.pause()`/`play()`, `speed_scale = 0` em `AnimationPlayer`/partículas/`AnimatedSprite2D`, e `AudioStreamPlayer.stream_paused = true`) congelam os seis tipos com Δ=0 e retomam sem perda.
- **VR(5) VERIFICADO (`EX-0001-5`):** na perda de foco a ordem é `NOTIFICATION_APPLICATION_FOCUS_OUT` (2017) → `NOTIFICATION_WM_WINDOW_FOCUS_OUT` (1005) → `Window.focus_exited`. No ganho: `NOTIFICATION_APPLICATION_FOCUS_IN` (2016) → `NOTIFICATION_WM_WINDOW_FOCUS_IN` (1004, pode chegar duplicado ao restaurar após minimizar) → `Window.focus_entered`. Usar `NOTIFICATION_APPLICATION_FOCUS_OUT` no `Main` para `pedir_estado(PAUSA)` e tratar o ganho de foco como idempotente. A chave `application/run/pause_on_focus_loss` **não existe** no 4.7.2 (`ProjectSettings.has_setting` = false) e foi descartada. Desconexão de gamepad (`Input.joy_connection_changed`) confirmada no `--doctool`, pendente de verificação com hardware físico.
- **VR(6) VERIFICADO (`EX-0001-6`):** o loop modal de mover a janela no Windows (`WM_SYSCOMMAND/SC_MOVE`) não bloqueia o loop do Godot 4.7.2 nem gera `delta` > 0,05 s após soltar. O maior `delta` real ocorre no **1º quadro** de execução (0,13–0,14 s, 7–8 passos), cortado para 0,1 s pelo clamp `dt_max_apres` que deve valer desde o 1º quadro.
- **Pendências pós-MVP / release:** (a) VR(3) `RenderingServer.global_shader_parameter_set` fica com o protótipo do Pipeline (ADR-0011); (b) repetir as medições no `.exe` exportado quando os templates 4.7.2 estiverem instalados; (c) teste manual com gamepad físico e arrasto de janela com mouse físico.

## Related
- `docs/architecture/architecture.md` (v1; precisa de correção: o contador de hitstop é do Combate, não do orquestrador)
- GDDs: combate-nucleo (R1, R10, Transição), movimento-e-esquiva (R2), input-e-controle, cena-3-4-e-camera, pipeline-visual (R7, R8), ia-de-inimigos-e-elites, camaras-e-ondas, run-e-regioes
- ADR-0002, 0006, 0007, 0010, 0011 (a escrever)
