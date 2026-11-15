# ADR-0001: Orquestrador do passo e estados de jogo

## Status
Proposed

## Date
2026-11-13

## Last Verified
2026-11-13 (contra `docs/engine-reference/godot/` e os GDDs aprovados; itens marcados "a verificar" não foram confirmados)

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
| **Post-Cutoff APIs Used** | `@abstract` (4.5, confirmado), usado na base `Passo`. Regra do 4.7 (confirmada): `override` de método com retorno tipado herda o tipo e exige `return` explícito; `passo()` e `passo_congelado()` retornam `void` e não são afetados, mas qualquer override futuro com retorno não-void é |
| **Verification Required** | (1) `physics/common/physics_ticks_per_second` e `max_physics_steps_per_frame`: valores padrão e efeito quando o quadro atrasa; (2) ordem entre `_physics_process` e `_process` dentro do mesmo quadro; (3) `RenderingServer.global_shader_parameter_set` chamado a cada quadro (usado pelo Pipeline); (4) que não usar `SceneTree.paused` não deixa nenhum nó de apresentação rodando por engano (Tweens, `AnimationPlayer`, partículas, sons); (5) como a perda de foco da janela chega ao `Main` (notificação de foco e `application/run/pause_on_focus_loss`), exigida por `input-e-controle` (TR input-008); (6) o primeiro quadro depois de arrastar a janela no Windows e se `dt_max_apres` (0,1 s) o cobre. Nenhum destes itens está coberto por `docs/engine-reference/`: são NOT SOURCEABLE até um experimento confirmar |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None (primeiro ADR) |
| **Enables** | ADR-0002 (Canal de eventos: o orquestrador esvazia a lista no fim do passo), ADR-0006 (Input por passo), ADR-0007 (Cena e câmera), ADR-0010 (Resolução do combate no passo), ADR-0011 (Pipeline visual: relógios) |
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
- Manter `t_vivo` (avança 1/60 por passo vivo) e `t_apres` (tempo real com teto `dt_max_apres`, 0,1 s) e entregá-los ao Pipeline (Pipeline R4).
- Executar na troca de câmara as seis ações em ordem no mesmo quadro (Combate R1, Transição).
- Ser testável em memória, com módulos falsos.

## Decision

Quatro peças, todas na Foundation.

**1. `OrquestradorDoPasso` (lógica pura).** Classe `RefCounted`, sem `SceneTree`, que guarda o estado de jogo e a ordem do passo. Recebe todos os módulos por injeção. Não lê `Input` do Godot nem o relógio de parede: o tempo entra como `delta_real` em `quadro()` e como contagem de passos.

**2. `Main` (nó fino na cena raiz).** Constrói os módulos na ordem de inicialização do `architecture.md`, injeta, e só repassa os dois ganchos da engine. Não é `Autoload`.

**3. Estado de jogo próprio, sem `SceneTree.paused`.** Enum `EstadoDeJogo` com `INICIANDO`, `MENU`, `JOGO`, `PAUSA`, `BENCAO`, `TRANSICAO`, `MORTE`. O orquestrador simplesmente não chama o passo vivo fora de `JOGO`. A UI e o Pipeline continuam funcionando porque nenhum nó é pausado pela engine; quem para é o relógio (`t_apres`).

**4. O Combate guarda o contador de hitstop** (R10). O orquestrador só **consulta** `combate.hitstop_ativo()` e, em passo congelado, manda o Combate descontá-lo. Isto corrige o mapa de posse do `architecture.md` v1, que dava o contador ao orquestrador.

### Architecture Diagram
```
Main (Node, cena raiz)                        OrquestradorDoPasso (RefCounted, lógica pura)
  _physics_process() ───────────────────────►  passo_fisico()
  _process(delta)    ───────────────────────►  quadro(delta_real)
                                                  │ estado: INICIANDO·MENU·JOGO·PAUSA·BENCAO·TRANSICAO·MORTE
                                                  │ relógios: t_vivo, t_apres
                                                  ▼
   passo_fisico() em JOGO:  Input → [hitstop? congela] → Combate-início → Movimento → Combate-golpe
                            → Selo → Inimigos (Status→Telégrafos→impacto→IA) → Projéteis → mortes
                            → Câmaras → fim do passo (t_vivo += 1/60; esvazia lista de eventos)
   passo_fisico() fora de JOGO:  Movimento.passo_congelado(); Input no contexto do estado
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
func t_vivo() -> float
func t_apres() -> float
func pedir_estado(novo: EstadoDeJogo.Valor) -> bool    # false se a transição não é permitida
func hitstop_ativo() -> bool                     # consulta delegada ao Combate (Movimento R2, Input R6)
```
Módulos do passo implementam `Passo` (ver `architecture.md`, API 1): `passo(amostra)` e `passo_congelado()`. Em 4.7, um `override` com retorno tipado precisa de `return` explícito.

### Implementation Guidelines
- Os módulos **must** receber o tempo como contagem de passos; **must never** ler `Time`, `OS` nem `Engine.time_scale` na lógica de jogo.
- **Must never** usar `SceneTree.paused` para pausar o jogo; **must never** declarar o orquestrador como `Autoload`.
- Nenhum módulo de jogo **must** ter `_physics_process` próprio; só a Apresentação pode ter `_process`. A ordem do passo é a do orquestrador, não a de `process_priority`.
- A ordem dos itens 3, 5, 7, 8 e 9 é do Combate (R1); a dos demais itens é dos donos. O orquestrador só a executa e **must** expô-la como uma lista única, testável.
- `project.godot` **must** declarar explicitamente `physics/common/physics_ticks_per_second = 60` e `physics/common/max_physics_steps_per_frame`, em vez de depender dos padrões (valores a decidir no experimento).
- Fora de `JOGO`, em cada passo de física o orquestrador **must** chamar só o `passo_congelado()` do Movimento (Combate R1).
- Na Transição, as seis ações da troca de câmara **must** rodar uma única vez e no mesmo quadro, em ordem fixa.
- Testes **must** montar o orquestrador com módulos falsos que registram a ordem de chamada.
- Lógica de jogo **must never** usar `Timer` nem `create_timer`: o tempo é contagem de passos. Esperas de apresentação usam `t_apres` ou `t_vivo`.
- `quadro()` **must never** assumir "um passo por quadro": entre dois quadros podem rodar vários `passo_fisico()` (quadro atrasado) ou nenhum (monitor acima de 60 Hz).
- O passo é de 1/60 s a partir de **uma constante única**, validada contra `Engine.physics_ticks_per_second` em `Main._ready()`; se divergirem, o `Main` **must** falhar de forma ruidosa.
- A Apresentação **must** ser guiada por `t_vivo` ou ter os players parados explicitamente em hitstop e pausa. Sem `SceneTree.paused`, Tweens, `AnimationPlayer` e partículas da engine continuam animando.
- A perda de foco da janela e a desconexão do gamepad ativo **must** chegar ao `Main` e virar `pedir_estado(PAUSA)` quando o estado é `JOGO` (`input-e-controle`, TR input-008).
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
- **Menu e `t_apres`:** os GDDs não dizem se `t_apres` corre em `MENU`. *Mitigação:* tratar como pergunta aberta até o GDD de Menus (Vertical Slice).
- **`@abstract` e override (4.7):** esquecer o `return` explícito num `override` com retorno não-void quebra a carga. *Mitigação:* teste de carga dos módulos no CI.
- **Apresentação animando durante hitstop e pausa** (o risco mais provável de bug visível): sem `SceneTree.paused`, sprites, partículas e sons da engine continuam. *Mitigação:* guiar a Apresentação por `t_vivo` ou parar os players; verificação (4).
- **Janela sem foco ou arrastada:** o loop continua rodando sem foco, e o arraste no Windows pode gerar um `delta` grande no quadro seguinte. *Mitigação:* ligar o desfoco a `PAUSA`; verificações (5) e (6).
- **`delta` do `_physics_process` ignorado:** se `physics_ticks_per_second` mudar, `t_vivo += 1/60` fica errado. *Mitigação:* constante única validada em `Main._ready()`.
- **Entrada em quadro atrasado:** vários passos seguidos veem a mesma amostra, e um aperto e solto no mesmo quadro pode se perder. *Mitigação:* o buffer por evento alimenta o Input; decisão do ADR-0006.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| combate-nucleo.md | R1: ordem fixa dos 10 itens, só no estado Jogo (TR combate-nucleo-001, provisório) | `passo_fisico()` executa a ordem e só em `JOGO` |
| combate-nucleo.md | R10: hitstop como contador de passos, nunca `Engine.time_scale` (TR combate-nucleo-002) | Combate guarda o contador; o orquestrador consulta e congela |
| combate-nucleo.md | Transição: seis ações no quadro de `progresso_wipe` ≥ 0,5 (TR combate-nucleo-011) | `quadro()` executa as seis ações uma vez, em ordem |
| movimento-e-esquiva.md | R2: `passo_congelado()` fora de Jogo; Movimento não consulta hitstop (TR movimento-002, 003) | O orquestrador decide e chama `passo_congelado()` |
| cena-3-4-e-camera.md | Relógio de câmera é `t_apres`; corte no quadro do wipe (TR cena-009, 011) | O orquestrador mantém `t_apres` e dispara o corte na Transição |
| pipeline-visual.md | R4: `t_vivo` e `t_apres`, ambos a 0 no meio do wipe (TR pipeline-004) | O orquestrador mantém e entrega os dois relógios ao Pipeline |
| ia-de-inimigos-e-elites.md | IA roda no item 7, na ordem estável, nunca em hitstop (TR ia-001) | Ordem e congelamento garantidos pelo orquestrador |
| camaras-e-ondas.md | Câmara montada na metade do wipe; "câmara limpa" só com hitstop 0 (TR camaras-002, 007) | Montagem na ação 3 da Transição; avaliação só com `hitstop_ativo()` falso |
| run-e-regioes.md | Morte vence a limpeza no mesmo passo (TR run-005) | A varredura de mortes (item 9) roda antes das Câmaras (item 10) |
| input-e-controle.md | Perda de foco ou desconexão do gamepad pausa (TR input-008) | `pedir_estado(PAUSA)` a partir do estado `JOGO` |

## Performance Implications
- **CPU**: o orquestrador só despacha chamadas; custo próprio desprezível. Orçamentos dos módulos são dos GDDs (Combate p99 ≤ 0,3 ms/passo, Movimento ≤ 0,2 ms, provisórios).
- **Memory**: desprezível.
- **Load Time**: desprezível.
- **Network**: N/A.

## Migration Plan
Não há código de produção ainda. O protótipo `prototypes/combate-camara-concept/` é descartável e não migra.

## Validation Criteria
- Teste unitário com módulos falsos prova a ordem exata dos 10 itens e que fora de `JOGO` só `passo_congelado()` é chamado.
- Teste prova que hitstop pendente não desconta contadores e que "câmara limpa" só é avaliada com `hitstop_ativo()` falso.
- Teste prova que as seis ações da Transição rodam uma vez, em ordem, no primeiro quadro com `progresso_wipe` ≥ 0,5.
- Experimento no protótipo de arquitetura fecha os quatro itens de "Verification Required".

## Nota: preparação para co-op (2026-11-13)
Decisão do usuário: co-op online de 1 a 4 jogadores depois do MVP solo, com host autoritativo. **Esta nota não muda a decisão do ADR e não prevê código de rede.** Para a base solo não impedir o co-op: o orquestrador roda só no host e o cliente roda só a Apresentação; o estado de jogo (`EstadoDeJogo`) segue global; e o `Passo.passo(amostra)` do passo vivo passará a receber as amostras por jogador (indexadas por `player_id`, 0 no solo) quando o co-op entrar. Detalhes e regras em `docs/architecture/architecture.md`, seção "Preparação para co-op".

## Related
- `docs/architecture/architecture.md` (v1; precisa de correção: o contador de hitstop é do Combate, não do orquestrador)
- GDDs: combate-nucleo (R1, R10, Transição), movimento-e-esquiva (R2), input-e-controle, cena-3-4-e-camera, pipeline-visual (R4, R7), ia-de-inimigos-e-elites, camaras-e-ondas, run-e-regioes
- ADR-0002, 0006, 0007, 0010, 0011 (a escrever)
