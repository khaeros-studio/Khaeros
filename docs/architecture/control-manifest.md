# Control Manifest

> **Engine**: Godot 4.7 (pin 4.7.2.stable, instalado, sem gap)
> **Last Updated**: 2026-11-16
> **Manifest Version**: 2026-11-16
> **ADRs Covered**: ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0008, ADR-0009, ADR-0010, ADR-0011, ADR-0012, ADR-0013, ADR-0014, ADR-0015, ADR-0016, ADR-0017, ADR-0018 (18 de 18, todos Accepted)
> **ADRs Left Out**: nenhum
> **Status**: Active — regenerar com `/create-control-manifest update` quando um ADR mudar

`Manifest Version` é a data de geração deste manifesto. As stories a embutem quando
são escritas, e `/story-readiness` compara a versão da story com esta para achar
stories escritas contra regras antigas. É sempre igual a `Last Updated`.

Referência rápida do programador, extraída dos ADRs Accepted, de
`architecture.md` (Architecture Principles, Module Ownership), de `project.yaml`,
de `.claude/docs/technical-preferences.md` e de `docs/engine-reference/godot/`.
O **porquê** de cada regra está no ADR citado.

**Notas de geração**
- Seções lidas por ADR: Decision (incl. Implementation Guidelines), Alternatives Considered, Performance Implications, Engine Compatibility e Validation Criteria (pedido do orquestrador). Ausências: ADR-0003 não tem Alternatives, Performance nem Validation; ADR-0004 e ADR-0005 não têm Alternatives nem Performance; ADR-0006, ADR-0007 e ADR-0008 não têm Performance Implications. As regras dessas categorias para esses ADRs ficam vazias, não omitidas por descuido.
- **TD-MANIFEST: PASS (2026-11-17) — revisado independentemente por lead-programmer contra os 18 ADRs Accepted e os experimentos EX-0001..EX-0016.**

---

## Foundation Layer Rules

*Aplica-se a: Orquestrador do passo, canal de eventos, entidades/portadores (estrutura), catálogo de dados, RNG, Input, Cena/viewport/câmera, persistência (adaptador e repositórios).*

### Required Patterns
- **`OrquestradorDoPasso` é `RefCounted` de lógica pura, sem `SceneTree`; recebe todos os módulos por injeção.** O tempo entra como `delta_real` em `quadro()` e como contagem de passos — source: ADR-0001
- **`Main` é um nó fino na cena raiz:** constrói os módulos na ordem de inicialização do `architecture.md`, injeta por método explícito (`configurar()`) **antes** de `add_child` dos nós de Apresentação, e só repassa `_physics_process`→`passo_fisico()` e `_process`→`quadro()` — source: ADR-0001
- **Estado de jogo próprio** (`EstadoDeJogo.Valor`: INICIANDO, MENU, JOGO, PAUSA, BENCAO, TRANSICAO, MORTE), em arquivo próprio `estado_de_jogo.gd` — source: ADR-0001
- **Módulos nunca trocam o estado: chamam `pedir_estado(novo)`.** Dentro do passo o pedido fica pendente até o final comum; `MORTE` vence qualquer outro pedido no mesmo passo — source: ADR-0001
- **Todo `passo_fisico()` termina em `_finalizar_passo(vivo)`**, nesta ordem: `n_vivos += 1` se vivo → `n_passos_em_jogo += 1` se começou em JOGO → `eventos.esvaziar()` exatamente uma vez e entrega à Apresentação mesmo com lista vazia → aplica pedido de estado pendente — source: ADR-0001, ADR-0002
- **Fora de `JOGO`, cada passo de física chama só `Movimento.passo_congelado()`** — source: ADR-0001
- **O contador de hitstop é do Combate;** o orquestrador só consulta `hitstop_ativo()` — source: ADR-0001, architecture.md (Conflitos de posse #1)
- **Passo de 1/60 s numa constante única**, validada contra `Engine.physics_ticks_per_second` em `Main._ready()`; divergência falha de forma ruidosa. `project.godot` declara explicitamente `physics_ticks_per_second = 60` e `max_physics_steps_per_frame` — source: ADR-0001
- **A ordem do passo é exposta como lista única e testável;** testes montam o orquestrador com módulos falsos que registram a ordem de chamada — source: ADR-0001
- **`quadro()` não assume um passo por quadro** (pode haver vários ou nenhum entre dois quadros) — source: ADR-0001
- **As seis ações da troca de câmara rodam uma única vez, no mesmo quadro, em ordem fixa;** `t_vivo`/`t_apres` zeram na troca (metade do wipe), não no pedido de TRANSICAO; `passos_em_jogo()` nunca zera na run — source: ADR-0001
- **Perda de foco da janela e desconexão do gamepad ativo chegam ao `Main` e viram `pedir_estado(PAUSA)`** quando em JOGO; usar `NOTIFICATION_APPLICATION_FOCUS_OUT` no `Main` para pedir `PAUSA` (não existe `application/run/pause_on_focus_loss` no 4.7.2) e tratar `NOTIFICATION_WM_WINDOW_FOCUS_IN` como idempotente (pode chegar duplicado ao restaurar janela) — source: ADR-0001, EX-0001-5
- **Todo evento é subclasse tipada de `EventoDoPasso` (`@abstract`, `RefCounted`)**, campos definidos no construtor, imutáveis depois de emitidos (convenção garantida por revisão e teste); cada subclasse implementa `tipo() -> StringName` com `return` explícito. No Godot 4.7.2 `filter()` sobre array tipado preserva o tipo (`is_typed() == true`), mas `@abstract` só bloqueia instanciação estática (`EventoDoPasso.new()`) — instanciação dinâmica via `Script.new()` continua proibida — source: ADR-0002, EX-0002-2
- **Payload só com dados e ids inteiros;** sem `Node`, sem referência viva a combatente, sem referência ao canal, ao emissor ou a outro evento — source: ADR-0002, ADR-0003
- **`do_tipo()` e `todos()` devolvem cópia nova a cada chamada; `esvaziar()` devolve o array antigo e passa a usar um novo** (nunca `clear()` no devolvido) — source: ADR-0002
- **`emitir()` dá `assert` em debug se chamado durante a entrega à Apresentação** (flag `_entregando`) — source: ADR-0002
- **Downcast (`as`) antes de ler campos da subclasse do evento** — source: ADR-0002
- **Reação a evento de item anterior: ler `do_tipo()`; reação a produtor do mesmo item ou posterior: chamada direta do produtor** — source: ADR-0002
- **Estado vivo de combatente em `RefCounted`** (`InimigoRef`, `JogadorRef`, `MaldicaoRef`); definições do catálogo são `Resource` tratadas como imutáveis — source: ADR-0003
- **Identificador de combatente é `int` de uma sequência crescente única da run** (inimigos e Maldições compartilham o contador); nunca `StringName` nem índice de array — source: ADR-0003
- **Posse de campos por sistema** (IA: lista/fases/posição do inimigo; Combate: Vida/escudo/impacto; Movimento: posição/cargas do jogador; Modificadores: atributos; Status: efeitos; Selo: `no_selo`/Fluxo). Mudanças só pela interface do dono — source: ADR-0003, architecture.md (Module Ownership)
- **Resultado guardado além da chamada guarda o id e revalida;** portador não guarda referência forte de volta ao combatente (evitar ciclos) — source: ADR-0003
- **Varredura de mortes sobre retrato ordenado** dos inimigos com Vida ≤ 0; mortes geradas no passe vão para o passe seguinte — source: ADR-0003
- **Chefe é `InimigoRef` com `chefe: bool`; a acuada não é `InimigoRef`** e fica fora da lista de inimigos (pertence ao Vínculo) — source: ADR-0003
- **Catálogo: esquema declara campos, tipos, obrigatoriedade, limites e regras entre campos;** a validação distingue campo ausente de valor gravado — source: ADR-0004
- **Cópia mutável com sub-recursos usa `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)`** (`duplicate_deep()` padrão compartilha sub-recurso externo) — source: ADR-0004, EX-0004-NV
- **Ids de `CurseDef` são append-only** (nunca mudam nem se reaproveitam; ordem no manifesto só cresce no fim) — source: ADR-0004
- **Importação CSV→`.tres` por `tools/content-import/`, só em editor/CI;** preset de exportação declara `exclude_filter="assets/data/canon/*"` (CSV `importer="keep"` entra no `.pck` se não excluído explicitamente); teste de paridade em `tests/integration/content/` — source: ADR-0004, EX-0004-NV
- **RNG próprio em aritmética inteira de 64 bits**, fluxos por finalidade com posse e autorização; argumentos validados antes do primeiro avanço; pedido inválido gera diagnóstico e conserva a sequência — source: ADR-0005
- **Consumo de `spawn` fixo em 14 candidatos por nascimento;** filtros (ex.: acuada) aplicados depois do sorteio — source: ADR-0005
- **RNG de cosméticos fica em `src/presentation/`** e nenhuma regra lê seu resultado — source: ADR-0005
- **Input: `Input`/`InputEvent` só na fronteira de input** (inclusive telas); amostra uma vez por passo, cada borda descartada uma vez, capacidades invalidadas no fim do passo/troca de contexto — source: ADR-0006
- **Mapa de binds próprio é a autoridade;** `Input.use_accumulated_input` desativado no ponto de composição — source: ADR-0006
- **Buffer com contador único;** entradas `{acao, passo_do_toque, epoca, durante_congelamento}`; consumidor só aceita a época corrente; consumo de uma ação nunca apaga as outras — source: ADR-0006, ADR-0008
- **Remapeamento é transação sobre cópia** validada por inteiro antes de publicar; arquivo inválido preservado em `.bak` antes de substituir — source: ADR-0006
- **Eventos identificados por classe**, sem assumir `device == 0` para teclado/mouse — source: ADR-0006, deprecated-apis.md
- **Cena: pixels de mundo sem segunda conversão 1,5; duas bases (`pos`, `pos_seguir`), câmera visual separada e snapshot explícito para Input** — source: ADR-0007
- **Todo teleporte (spawn, reposicionamento de câmera, troca de câmara) chama `reset_physics_interpolation()` no mesmo passo logo após atribuir a posição nova** (evita quadros fantasmas varrendo a tela) — source: ADR-0007, EX-0007-NV
- **Stretch `canvas_items`, escala `fractional`, janela inicial 1280×720, chaves explícitas no `project.godot`;** geometria publicada antes de usar janela redimensionada — source: ADR-0007
- **Um único escritor de canvas, camadas e parallax;** sem dupla interpolação. Ordem de desenho por `(pé_interpolado.y, ordem_criacao_visual)` com registro central de criação injetado — source: ADR-0007
- **`receber_impulso` só do Feedback e rejeita época diferente da atual** — source: ADR-0007
- **Persistência: todo acesso a disco passa por `ArmazemDeArquivos`;** `FileAccess`/`DirAccess`/`ConfigFile.load/save` só em `ArmazemUserGodot` — source: ADR-0013
- **Todo `bool`/`Error` devolvido é verificado** e vira estado explícito (Parada por falha, valor só em memória), nunca exceção nem laço de nova tentativa — source: ADR-0013
- **`.cfg` só por `gravar_atomico` mantendo a sequência `.old` (`destino → .old`, `.tmp → destino`);** nunca usar `DirAccess.rename` único sobre destino existente no Windows (apaga antes de mover e perde o destino se a origem falhar); arquivo inválido preservado em `.bak`/`.bak2`/… (nunca apaga backup) — source: ADR-0013, EX-0013-P2
- **Em `ConfigFile.parse()`, retorno `OK` sozinho não valida o arquivo** (lixo binário retorna `OK` com 0 seções, e erro de parse deixa seções parciais) — exigir sempre a seção `[meta]` e chave `schema_version` e descartar o objeto inteiro em erro — source: ADR-0013, EX-0013-P3
- **Em timestamps UTC da telemetria/sessão, concatenar `"Z"` em `Time.get_datetime_string_from_system(true)`** (a engine retorna `YYYY-MM-DDTHH:MM:SS` sem sufixo `Z`) — source: ADR-0013, EX-0013-P5
- **Gatilhos só marcam o perfil como pendente;** o `Main` grava fora de JOGO. `carregar()` dos repositórios nunca falha (padrões em erro); catálogo em Falhou → modo Sem gravação — source: ADR-0013
- **Opções em `user://opcoes.cfg`, lidas/gravadas só pelo `RepositorioDeOpcoes`;** cada dono recebe o valor por injeção — source: ADR-0013
- **Testes de unidade com `ArmazemEmMemoria` e relógio falso;** testes `[I]` usam armazém real em raiz temporária e limpam ao fim — source: ADR-0013

### Forbidden Approaches
- **Never declarar o orquestrador (ou qualquer lógica) como `Autoload`/singleton `GameLoop`** — quebra a testabilidade em memória — source: ADR-0001 (Alt. 1), ADR-0013, ADR-0015
- **Never ordenar o passo por `_physics_process` de cada sistema + `process_priority`** — ordem implícita e espalhada; nenhum módulo de jogo tem `_physics_process` próprio — source: ADR-0001 (Alt. 2)
- **Never usar `SceneTree.paused`** para pausar o jogo — pararia UI da Bênção e Pipeline — source: ADR-0001
- **Never ler `Time`, `OS` ou `Engine.time_scale` na lógica de jogo** — tempo é contagem de passos — source: ADR-0001
- **Never usar `Timer` nem `create_timer` na lógica** — source: ADR-0001
- **Never adicionar/remover nós de física da engine dentro de `passo_fisico()`** ("Can't change this state while flushing queries") — source: ADR-0001
- **Never usar sinais do Godot para eventos entre módulos de regra** — determinismo e "morte vence a limpeza" não podem depender da ordem de conexão — source: ADR-0002 (Alt. 1)
- **Never barramento global publicar/assinar por nome** — source: ADR-0002 (Alt. 2)
- **Never evento como `Dictionary` com `tipo`** — source: ADR-0002 (Alt. 3)
- **Never depender da ordem de registro, conexão ou injeção para reagir a eventos; never ler a lista esperando eventos de itens posteriores nem em "gancho de fim de passo"** — source: ADR-0002
- **Never consumidor da Apresentação chamar `emitir()`, escrever em estado de jogo ou guardar o evento além do passo** — source: ADR-0002
- **Never avançar gameplay por callbacks de teclado, sinais da UI ou eventos de gamepad; never `_unhandled_input` por nó para ações** — source: ADR-0006
- **Never o `InputMap` guardar buffer ou decidir contexto/dispositivo;** espelho para a engine é derivado e nunca segunda via de execução — source: ADR-0006
- **Never medir sensação/fluidez por aprovação de testes headless** — source: ADR-0007
- **Never presumir `InputEvent.position` em pixel de janela** — normalizar para espaço Janela uma vez — source: ADR-0007
- **Never usar `ProjectSettings` ou `OS` fora do armazém real e do `Main`** — source: ADR-0013
- **Never gravar `.cfg` durante um passo em estado JOGO** — source: ADR-0013
- **Never ler o `.jsonl` no jogo, gravar nele caminho absoluto, nome de usuário ou hora local, nem criar telemetria num cliente co-op** — source: ADR-0013
- **Never `RandomNumberGenerator` da engine, `randf`/`randi`/`shuffle`/`pick_random` na lógica** — a única exceção é a função de entropia da criação da run; CI verifica (AC-32) — source: ADR-0005
- **Never executar o importador de conteúdo em runtime** — source: ADR-0004

### Performance Guardrails
- **Orquestrador**: custo próprio desprezível; o **total do passo vivo é ≤ 1,0 ms p99**, e estourar 1,0 ms decide o corte no ADR-0001, não em cada módulo — source: ADR-0001
- **Catálogo (AC-38)**: mediana de 5 cargas frias ≤ 250 ms; validação ≤ 30 ms; harness em `tests/performance/content/`, evidência em `production/qa/evidence/` — source: ADR-0004 (TR-conteudo-015)
- **Telemetria**: ≤ 1 ms por linha, ≤ 3 ms por passo, só no passo da morte (fora do passo vivo comum) — source: ADR-0013, ADR-0001
- **Persistência**: carga dos `.cfg` uma vez na inicialização; gravação só por ação fora do passo — source: ADR-0013
- **Eventos**: um `RefCounted` por evento; a emissão do Combate entra no orçamento dele (0,3 ms) — source: ADR-0002

---

## Core Layer Rules

*Aplica-se a: Modificadores/portador, Movimento e colisão própria, Combate núcleo, Maldições (aliados), IA de inimigos e chefe.*

### Required Patterns
- **`Portador extends RefCounted` para todo combatente**, com `id_combatente: int`, `player_id: int` (−1 em inimigo); portador do jogador endereçado por `player_id` (0 no solo) — source: ADR-0009
- **Agregados reconstruídos dentro de `aplicar_fonte`, `remover_fonte` e da expiração em `avancar`** — source: ADR-0009
- **Fontes percorridas em ordem canônica** (`id_fonte`, depois ordem do efeito) — source: ADR-0009
- **Tudo em `float` até o fim de F1/F2/F3; arredondar só pela função própria** (`arredondar_meio_longe_do_zero`), só nos 5 inteiros e em F3 — source: ADR-0009, ADR-0010
- **`teto_multiplicador_dano` aplicado por último** — source: ADR-0009
- **Modificadores registra e nunca executa;** executores leem `gatilhos()` (`ResumoDeGatilho` cacheado). `AplicadorDeEfeitos` aplica F5 ao `valor`, nunca aos `params` — source: ADR-0009
- **Abalo com um único relógio, no Status** — source: ADR-0009
- **Movimento é o único escritor da posição física do jogador;** conserva a ordem R3 e os três pedidos síncronos da largada (`cancelar` → `garantir_invulneravel(D+E)` → `esquiva_iniciada`) — source: ADR-0008
- **`passo_congelado()` faz somente anterior=atual;** a Cena usa esse histórico (sem histórico divergente) — source: ADR-0008, ADR-0007
- **Corte antes da colisão; `deslocar` sem repetir Corte/contadores;** `teleportar(pos)` zera esquiva e Corte, preserva cargas — source: ADR-0008
- **Colisão própria (`resolver_colisao`, função pura) sobre array ordenado de obstáculos circulares imutáveis;** borda estrita de colisão, borda inclusiva do Corte; contato exato não empurra — source: ADR-0008
- **Combate respeita a ordem da tabela da seção 2 e o `≤`/`<` da F4** — source: ADR-0010
- **Hitstop só nas origens da tabela R10; `pedir_hitstop(n)` é privado e faz `max`** — source: ADR-0010
- **Vida do inimigo em `float`, do jogador em `int`, um único arredondamento** — source: ADR-0010
- **Invulnerabilidade é contador por jogador em `RecursosDoJogador`, só o Combate escreve, todo pedido usa `max`** — source: ADR-0010
- **`selo.creditar_acerto_tardio` uma vez por `acerto_de_arma` do item 8; `status.aplicar_status` síncrono no impacto** — source: ADR-0010
- **`pedir_estado(MORTE)` só no fim do item 9** — source: ADR-0010
- **`GeometriaDeAcerto` (módulo `static`, sem estado) para todo teste de acerto**, inclusive Telégrafos; alvo é círculo, toque inclusivo da borda — source: ADR-0010, ADR-0014
- **Combate lê a marca `subjugavel` no estado do inimigo, nunca a Doutrina** — source: ADR-0010
- **Maldições: ordem da R23 (item 6.1); jogadores e alvos iterados por id crescente;** todo dano a inimigo por `aplicar_golpe_maldicao`; `exaurir` síncrono avisando a IA dentro dele — source: ADR-0017
- **Durações de atração e respiro lidas do `MaldicoesTuning`, convertidas na carga** — source: ADR-0017
- **Tudo por `player_id`**; `MaldicaoRef` com portador próprio, nunca destruído na Exaustão — source: ADR-0017
- **Sem fogo amigo por construção:** Maldição fora da lista de atingíveis; único caminho de dano é `ferir_maldicao` — source: ADR-0017
- **IA: `ModuloDeIA` e `Comportamento` são `RefCounted` puros; comportamentos sem estado; todo estado por inimigo no `InimigoRef`** — source: ADR-0018
- **IA dona da lista de inimigos em ordem estável de id** — source: ADR-0003, ADR-0018, architecture.md (Conflitos #3)
- **`passo()` lê o alvo antes de descer atração/respiro/imobilização** e abre o respiro no mesmo passo em que a atração acaba — source: ADR-0018
- **Todo golpe testa só o alvo travado e chama só o `ferir_*` da facção dele;** alvo ausente falha no vazio — source: ADR-0018, ADR-0014
- **Separação: passe `i < j` em ordem de id, metade da sobreposição para cada, normal `(0, −1)` em centros iguais** — source: ADR-0018
- **`atingiveis()`, `publicar()`, `alvo_efetivo()` preenchem valores pré-alocados** (`AlvoDeInimigo` nunca criado no passo) — source: ADR-0018
- **RNG na IA: `ia` só em `ao_surgir` e no fim da recuperação, em ordem de id; `sortear_elite` consome 1 real sempre** — source: ADR-0018, ADR-0005

### Forbidden Approaches
- **Never recalcular agregados em leitura nem expor bandeira de sujo** — cálculo sob demanda rejeitado (custo sem ganho) — source: ADR-0009
- **Never depender de ordem de inserção ou de iteração de `Dictionary`** — source: ADR-0009, ADR-0008
- **Never piso por efeito, epsilon, `int()` intermediário, nem `round()`/`roundi()` como fonte de arredondamento** — source: ADR-0009, ADR-0010
- **Never guardar Vida, escudo, cargas, contador de acertos ou janela pós-esquiva no portador** — source: ADR-0009
- **Never mutar `Modificador`, `DanoCongelado` ou `params` do catálogo depois de criado** — reaplicação cria fonte nova — source: ADR-0009
- **Never usar solver da engine, subpassos, margem, epsilon ou normal dependente de velocidade na colisão** — source: ADR-0008
- **Never usar `Area2D`/`ShapeCast2D`, consulta de física, `Timer`, `Engine.time_scale` ou sinal do Godot na regra de combate** — física 2D do 4.7 não coberta pela referência e bordas não controláveis — source: ADR-0010, ADR-0017, ADR-0018
- **Never `_ferir_inimigo` pedir hitstop** — source: ADR-0010
- **Never remover projétil ou inimigo por troca com o último** — quebra ordem estável — source: ADR-0010
- **Never campo singular "o jogador" / "a Maldição"** para Vida, invulnerabilidade ou recursos — source: ADR-0010, ADR-0017
- **Never a Maldição escrever Vida de inimigo, pedir hitstop, usar RNG, propagar gatilho fora de `tipos_propagados_maldicao`** — source: ADR-0017
- **Never a IA contar preparo por conta própria** (disparo = `disparou_neste_passo`) — source: ADR-0018, ADR-0014
- **Never o chefe consumir RNG; never lacaios consumirem `elites` ou `spawn`** — source: ADR-0018
- **Never separação incluir Maldição, acuada, `SURGINDO` ou `SUBJUGADO`; never expor `InimigoRef` fora** — source: ADR-0018

### Performance Guardrails
Tabela de orçamento do passo vivo (p99, build de release exportado, PC de medição abaixo) — source: ADR-0001

| Bloco do passo vivo | Orçamento p99 | Source |
|---|---|---|
| Movimento (item 4) | 0,2 ms | ADR-0001, ADR-0008 |
| Combate (itens 3, 5, 7-impacto, 8, 9; inclui emissão de eventos) | 0,3 ms | ADR-0001, ADR-0002 |
| Maldições (item 6.1) | 0,1 ms | ADR-0001, ADR-0017 |
| IA de inimigos e chefe (item 7), 9 inimigos | 0,15 ms (estresse: 36 inimigos ≤ 0,6 ms) | ADR-0001, ADR-0018 |
| Telégrafos (dentro do item 7) | < 0,05 ms | ADR-0001, ADR-0014 |
| Status | ≤ 0,05 ms | ADR-0001 |
| Telemetria | até 3 ms só no passo da morte | ADR-0001, ADR-0013 |
| **Total do passo vivo** | **≤ 1,0 ms** | ADR-0001 |

- Todos os blocos são medidos pelo **harness único `MedidorDeOrcamento`** (relógio injetado; `Time.get_ticks_usec()` só no adaptador real), na cena de estresse, média e p99 em 600 passos. ADR-0017 e ADR-0018 medem contra o total de 1,0 ms, não contra 16,6 ms — source: ADR-0001 (TR-movimento-014)
- Combate: sem alocação no caminho quente além dos eventos; testes de acerto sem raiz quadrada — source: ADR-0010
- Modificadores: leitura O(1)/O(k ≤ 3); sem orçamento próprio, entra no do passo — source: ADR-0009

---

## Feature Layer Rules

*Aplica-se a: Telégrafos, ciclo da run e composição, Câmaras/Portas/Bênçãos/Economia/Vínculo/Chefes (lógica pura; nenhuma usa API de engine — architecture.md, Module Ownership).*

### Required Patterns
- **`Telegrafos` é `RefCounted` puro; pool de exatamente `teto_telegrafos` slots alocados em `iniciar_run()`**, nunca redimensionado; vaga livre = menor índice; slots terminais contam até liberados — source: ADR-0014
- **`varrer()` e `avancar()` só em passo vivo, na ordem da Decisão 3** — source: ADR-0014
- **Teste de acerto e vista saem do mesmo `FormaDeTelegrafo`, que chama `GeometriaDeAcerto`;** dimensões de `FormasDeTelegrafo.derivar()` (a mesma do validador TV2) — source: ADR-0014
- **Mira travada em `iniciar_telegrafo`, nunca reescrita;** vetor zero vira `(1, 0)` por teste explícito de `length_squared() == 0` — source: ADR-0014
- **`cancelar_todos()` antes de as Câmaras removerem inimigos, sem emitir evento** — source: ADR-0014
- **`publicar()` preenche vistas pré-alocadas** — source: ADR-0014
- **Toda criação de módulo passa por `ComposicaoDaSessao` (sessão/perfil) ou `FabricaDaRun` (run);** dependências no `_init` — source: ADR-0015
- **Escopos: menor pode referenciar maior, nunca o contrário;** quem é de sessão ouve a run por eventos no canal — source: ADR-0015
- **`nova_run()` = `escopo_run.desligar()` → soltar → `conta.nova_run()` → `Run.fase = ESCOLHA_DE_ARMA` → `pedir_estado(MENU)`;** seed nova só em `→ ATIVA` — source: ADR-0015
- **A Run só troca o `EstadoDeJogo` por `pedir_estado`** — source: ADR-0015, ADR-0001
- **Gravação do perfil só em `gravar_se_pendente` (estado ≠ JOGO) ou em `sair_do_jogo()`** — source: ADR-0015, ADR-0013
- **`ResumoDaRun` sem setters; arrays com `make_read_only()`** — source: ADR-0015
- **Todo colaborador opcional tem variante Nula** (`ContaFragmentosNula`, `VinculoNulo`, `ChefesNulo`, `BencaosNula`…) com `return` explícito em todo override não-void — source: ADR-0015
- **Portas consultam `run.ativa()` antes de conceder** (morte vence a limpeza) — source: ADR-0015
- **`saldo` de Fragmentos é de sessão; nunca vai para `perfil.cfg`;** a run nunca é salva no MVP — source: ADR-0015
- **Posse resolvida:** `p_max` é das Câmaras; `trocas_oferta` de `BencaosTuning.trocas_iniciais`; reset do Fluxo é do Selo (Run só chama `nova_run`) — source: architecture.md (Conflitos de posse)

### Forbidden Approaches
- **Never `Telegrafos` criar `Node`, `Area2D`, corpo de física ou `Timer` por telégrafo** — source: ADR-0014
- **Never `iniciar_telegrafo` alocar, crescer o array, enfileirar pedido ou despejar outro telégrafo** — source: ADR-0014
- **Never a simulação depender da ordem dos slots** — source: ADR-0014
- **Never conta de forma em IA, Combate, Pipeline ou em Telegrafos fora do adaptador; never dimensões lidas de campos gravados no catálogo** — source: ADR-0014
- **Never o golpe percorrer "todos os jogadores"** (testa só o alvo travado) — source: ADR-0014
- **Never expor `TelegrafoSlot` nem `InimigoRef`** — source: ADR-0014
- **Never Autoload, `get_node` absoluto em lógica, `SceneTree.paused`, nem `reset()` em módulo de escopo de run** — source: ADR-0015
- **Never a Run gravar disco ou guardar números das Maldições** — source: ADR-0015

### Performance Guardrails
- **Telégrafos**: < 0,05 ms por passo vivo (até 24 incrementos em `varrer()`) — source: ADR-0014, ADR-0001

---

## Presentation Layer Rules

*Aplica-se a: Pipeline visual, UI/HUD/Tela de bênção, Áudio, Feedback de combate, Telemetria.*

### Required Patterns
- **A Apresentação só lê e nunca escreve no jogo;** é a única camada que pode ter `_process` — source: architecture.md (Principles #4), ADR-0001
- **Apresentação guiada por `t_vivo`/`t_apres` ou com players parados explicitamente em hitstop e pausa** (sem `SceneTree.paused`, Tweens/`AnimationPlayer`/partículas continuam) — source: ADR-0001
- **Sinais do Godot só em nós de Apresentação (`Control`, `CanvasLayer`), conectados explicitamente pelo `Main`** — source: ADR-0002
- **`PipelineVisual` é o único escritor de globais e uniforms de passe,** uma vez por quadro e depois das ações da Transição — source: ADR-0011
- **`t_vivo` e `t_apres` escritos a partir do orquestrador, sem relógio próprio;** LUT trocada e relógios zerados só na última das seis ações — source: ADR-0011
- **Todo `CanvasItem` de mundo com shader de uma das três pastas de família;** validador ativo em debug — source: ADR-0011
- **Material duplicado por entidade no spawn e devolvido ao pool no despawn; 24 slots de telégrafo (48 nós) pré-instanciados na carga** — source: ADR-0011
- **Sinais de status: no máximo 3 por inimigo; com > 9 inimigos marcados, um só (o de maior acúmulo)** — source: ADR-0011
- **UI recebe entrada só por `ComandosDeTela` do provedor** — source: ADR-0012, ADR-0006
- **Todo `Control` interativo com `mouse_filter = MOUSE_FILTER_IGNORE`; `project.godot` esvazia os eventos das ações nativas de navegação/confirmação (E2)** — source: ADR-0012
- **HUD lê valores por consulta em toda entrega e na criação** — source: ADR-0012
- **Teste de acerto da UI pelo slot de layout;** manter `offset_transform_visual_only = true` (padrão 4.7.2) nas cartas/controles com animação de offset/escala e calcular o anel de foco e geometria visual pelo slot + offset conhecidos, nunca por `get_global_transform_with_canvas()` (que permanece no slot quando `visual_only = true`) — source: ADR-0012, ADR-0007, EX-0012-E1
- **Animações de UI por `t_ui`/`t_real` (`RelogioDeInterface` avançado pelo `Main._process` com `min(delta_real, dt_max)`)** — source: ADR-0012
- **Todo texto visível é chave de tradução** (CSV com `?context` e `?plural` e linhas de continuação com `keys` vazio; em `pt_BR` o valor `0` usa a forma singular conforme CLDR) — source: ADR-0012, EX-0012-E6
- **`CartaView` recebe `DadosDaCarta` (só dados), nunca lê `BoonDef`;** `GrupoDeCartas` é a máquina de 8 estados com relógio injetado — source: ADR-0012
- **Sons de UI por eventos de áudio / `FilaDeSonsDeInterface`** — source: ADR-0012, ADR-0016
- **`AudioDoJogo` cria todos os `AudioStreamPlayer` no `_ready`;** decisão de voz em `MixadorDeVozes`/`SeletorDeTons` puros; no pool de vozes, considerar `stream_paused` além de `playing == false` para saber se a voz está livre (voz pausada reporta `playing == false`); validar `pitch_scale > 0` (faixa `0,25–4,0`, nunca `0.0`); P0 nunca é roubada; ≤ 3 tons em multidão; entrega sem alocar (arrays pré-alocados) — source: ADR-0016, EX-0016-A
- **Todo stream vem de `SomDef` do catálogo;** WAVs em loop contínuo usam `edit/loop_mode=2` (Forward) com `edit/loop_end=-1` (padrão) no `.import` (nunca `loop_end` igual ao nº de amostras, que gera estalo na emenda) — source: ADR-0016, EX-0016-A
- **Telemetria é `ConsumidorDeEventos` puro;** conta bytes em memória e aplica R9 antes de escrever — source: ADR-0013

### Forbidden Approaches
- **Never `TIME` em shader de mundo, nem `fmod` nos relógios** — source: ADR-0011
- **Never `draw_line`, `draw_arc` ou `Line2D` sem textura para traço de jogo** (linhas de `CanvasItem` sem feather no 4.7); never manter `world_view.gd` com `_draw()` como pipeline — source: ADR-0011
- **Never ler a tela nos passes, nem `WorldEnvironment` com glow** — source: ADR-0011
- **Never lógica de jogo ler o `EstadoVisual`** — source: ADR-0011
- **Never a UI ler `Input`/`InputEvent`, usar `_gui_input` para ações nem ligar `pressed` de `BaseButton` a uma ação;** never usar `Button` nativo com foco da engine (foco duplo do 4.6, dupla confirmação) — source: ADR-0012
- **Never o HUD guardar estado de jogo nem chamar método de escrita** — source: ADR-0012
- **Never teste de acerto pelo visual com `offset_transform_*` nem `get_global_mouse_position()`** — source: ADR-0012, ADR-0007
- **Never escalar a margem segura de 48 px; never raiz escalada filha direta de `Container`** — source: ADR-0012
- **Never `Timer`, `create_timer` ou `Tween` sem controle de pausa na UI** — source: ADR-0012
- **Never string literal de interface em `.gd` ou `.tscn`** — source: ADR-0012
- **Never vistas, Telas e HUD chamarem `play()`; never `AudioStreamPlayer` direto da vista** — source: ADR-0016, ADR-0012
- **Never instanciar players de áudio fora do `_ready`; never caminho literal de som** — source: ADR-0016
- **Never o Áudio emitir evento, escrever em módulo de regra ou guardar `PedidoDeSom` além da entrega; never `Engine.time_scale`/`SceneTree.paused` para pausar** — source: ADR-0016
- **Never o Feedback aplicar opção diretamente** (pede aos donos) — source: ADR-0013

### Performance Guardrails
- **Draw calls**: teto de 500 (ambiente 40, sombras+telégrafos 54, entidades 200, VFX 64, passes 6, UI 80, reserva ≥ 56), contado sem lote exceto sombras — source: ADR-0011, technical-preferences.md
- **Overdraw**: ≤ 3,5 telas na média, ≤ 5 no pico — source: ADR-0011
- **Áudio** (seleção top 3 sobre ≤ `teto_telegrafos` vistas): < 0,05 ms por passo — source: ADR-0016

---

## Global Rules (All Layers)

### GDScript 4.7
- **Tipagem estática em tudo:** variáveis, parâmetros, retornos, `Array[T]`; never `Array`/`Dictionary` sem tipo — source: deprecated-apis.md (Patterns), ADR-0003
- **`override` de método com retorno tipado não-void herda o tipo e exige `return` explícito** (nunca mudar para `-> void` ou outro tipo); vale para subclasses de `EventoDoPasso`, implementações de `@abstract`, dublês Nulos e falsos de teste — source: ADR-0001, ADR-0002, ADR-0009, ADR-0014, ADR-0015, ADR-0018
- **Bases de contrato com `@abstract`** (classe e métodos; `@abstract` na linha de cima da classe), por exemplo `Passo`, `EventoDoPasso`, consumidores, `Comportamento`. Módulo que já estende outra base expõe o contrato por adaptador (herança única) — source: ADR-0001, ADR-0002, ADR-0009, ADR-0018
- **Sem Autoload/singleton para lógica;** tudo por injeção — source: architecture.md (Principles #2), ADR-0001, ADR-0013, ADR-0015
- **Sem `SceneTree` na lógica** (`get_tree()`, `get_node` absoluto, `SceneTree.paused`, `Timer`/`create_timer`) — source: architecture.md (Principles #2), ADR-0001, ADR-0015
- **Sem `randf`/`randi`/`randi_range`/`shuffle`/`pick_random`/`RandomNumberGenerator` fora do RNG próprio** (cosmético só em `src/presentation/`, nunca lido por regra) — source: ADR-0005, architecture.md (Principles #1)
- **Sem números de gameplay literais:** valores em `Resource`/`*Tuning` validados na carga (`ModifiersTuning`, `StatusTuning`, `CombatTuning`, `MaldicoesTuning`, `RoomTuning`…) — source: architecture.md (Principles #3), ADR-0009, ADR-0017, coding-standards.md
- **Sem `Time`/`OS`/`Engine.time_scale` na lógica de jogo** — source: ADR-0001
- **Só se chama para baixo;** para cima e para os lados, só eventos e consultas injetadas — source: architecture.md (Principles #4)
- **Não se afirma o que não foi verificado:** NOT SOURCEABLE / NEEDS VERIFICATION vira experimento antes de decisão firme — source: architecture.md (Principles #5)

### Naming Conventions
| Element | Convention | Example | Source |
|---|---|---|---|
| Classes | PascalCase | `OrquestradorDoPasso` | `naming.classes` in project.yaml |
| Variables | snake_case | `n_passos_em_jogo` | `naming.variables` in project.yaml |
| Signals/Events | past_tense | `tela_fechada`, `inimigo_morreu` | `naming.signals` in project.yaml |
| Files | snake_case | `orquestrador_do_passo.gd` | `naming.files` in project.yaml |
| Scenes | snake_case | `main.tscn` | `naming.scenes` in project.yaml |
| Constants | SCREAMING_SNAKE | `PASSOS_POR_SEGUNDO` | `naming.constants` in project.yaml |

### Performance Budgets
| Target | Value | Source |
|---|---|---|
| Framerate | 60 fps | `performance.target_fps` in project.yaml, technical-preferences.md |
| Frame budget | 16,6 ms | `performance.frame_budget_ms` in project.yaml, technical-preferences.md |
| Passo vivo (simulação) | ≤ 1,0 ms p99 | ADR-0001 |
| Draw calls | ≤ 500 por quadro | `performance.max_draw_calls` in project.yaml, technical-preferences.md, ADR-0011 |
| Memory ceiling | 512 MiB (alerta em 448 MiB) | `performance.memory_ceiling_mb` in project.yaml, technical-preferences.md, ADR-0011 |

**PC de medição (todos os orçamentos e TR-conteudo-015):** AMD Ryzen 5 5600H (6c/12t), 16 GB RAM, NVIDIA RTX 3050 Laptop, SSD, **build de release exportado** — decisão do orquestrador em 2026-11-16. Medições em editor ou build de debug não fecham orçamento. Exceção explícita: a latência do golpe (AC-92, TR-combate-nucleo-018) é especificada em build de desenvolvimento, 60 Hz, vsync ligado, medida até `RenderingServer.frame_post_draw` (verificado em EX-0010-1: 33,3 ms máx ≤ 50 ms) — source: ADR-0010, EX-0010-1.

### Approved Libraries / Addons
- gdUnit4 — framework de testes — source: technical-preferences.md (Testing). Nenhum outro addon aprovado ("None configured yet").

### Forbidden Patterns (technical-preferences.md)
- Sem `Autoload`/singleton para lógica de jogo; tudo por injeção de dependências.
- Sem `SceneTree.paused` para pausar o jogo (estado de jogo próprio no `OrquestradorDoPasso`).
- Sem `Engine.time_scale`, `Timer`, `create_timer`, `Time` ou `OS` na simulação (tempo é contagem de passos).
- Sem sinais do Godot entre módulos de regra (usar canal `EventoDoPasso` e chamadas síncronas contratadas).
- Sem `randf`/`randi`/`shuffle`/`pick_random`/`RandomNumberGenerator` fora da função de entropia inicial da run (usar `FluxoRng` determinístico).
- Sem gravar `.cfg` durante um passo em estado `JOGO`.

### Forbidden APIs (Godot 4.7)
Aplicáveis a um projeto 2D em GDScript — source: `docs/engine-reference/godot/deprecated-apis.md`:
- `TileMap` → `TileMapLayer` (4.3)
- `VisibilityNotifier2D` → `VisibleOnScreenNotifier2D`; `YSort` → `Node2D.y_sort_enabled` (4.0)
- `yield()` → `await signal`; `connect("signal", obj, "method")` → `signal.connect(callable)`; `instance()` → `instantiate()` (4.0)
- `OS.get_ticks_msec()` → `Time.get_ticks_msec()` (e, na lógica, nenhum dos dois: ADR-0001)
- `duplicate()` em recurso aninhado → `duplicate_deep()` (4.5)
- `$NodePath` em `_process()` → referência `@onready` em cache
- `Texture2D` em `Shader.set/get_default_texture_parameter()` → `Texture` (4.4)
- `event.device == 0` para teclado/mouse → `event is InputEventKey`/`InputEventMouse` ou `DEVICE_ID_MOUSE`/`DEVICE_ID_KEYBOARD` (4.7)
- `RichTextLabel.ImageUpdateMask.UPDATE_WIDTH_IN_PERCENT` → `UPDATE_WIDTH_UNIT`; `width_in_percent`/`height_in_percent` → `width_unit`/`height_unit` (4.7)
- `DisplayServer.AccessibilityLiveMode` → `AccessibilityServer.AccessibilityLiveMode` (4.7)
- Addons pela aba AssetLib → Asset Store (4.7)

Deixados de fora (não se aplicam a um projeto 2D sem 3D): `VisibilityNotifier3D`, `Navigation3D`, `get_world()`, `Skeleton3D.bone_pose_updated`, GodotPhysics3D→Jolt, `Compositor`/`CompositorEffect`, `EditorSceneFormatImporter*`, `AudioEffectSpectrumAnalyzer.tap_back_pos`, `AnimationPlayer.method_call_mode`/`playback_active` (ainda válidos como rename caso `AnimationPlayer` seja usado na Apresentação).

### Engine API — verificações realizadas e pendentes
- **Verificados em 2026-11-16 (`EX-0001..EX-0016`, Godot 4.7.2 editor + `.pck`):**
  - `Resource.DEEP_DUPLICATE_ALL`, `HashingContext` SHA-256, `ResourceLoader.load(..., CACHE_MODE_IGNORE_DEEP)` e CSV `importer="keep"` (com `exclude_filter="assets/data/canon/*"`) — source: ADR-0004, EX-0004-NV
  - `physics_ticks_per_second = 60` e `max_physics_steps_per_frame = 8` em quadro atrasado; ordem `_physics_process` antes de `_process`; `NOTIFICATION_APPLICATION_FOCUS_OUT` no `Main`; parada explícita / `process_mode = PROCESS_MODE_DISABLED` sem `SceneTree.paused`; arrasto da janela coberto por `dt_max_apres = 0,1 s` — source: ADR-0001, EX-0001-1..6
  - `Control.offset_transform_visual_only = true` (E1), esvaziar ações nativas `ui_*` preservando `ui_text_*` (E2), barreira de retorno após `APPLICATION_FOCUS_IN` (E3), `focus/mouse_behavior_recursive` (E4), CSV `?context`/`?plural` (E6), `DisplayServer.clipboard_set/get` (CB) — source: ADR-0012, EX-0012
  - `float` como IEEE-754 binary64 (`2^52 + 1 != 2^52`, `0.1 + 0.2 == 0x3FD3333333333334`; evitar literais float em empate exato nos fixtures) — source: ADR-0009, EX-0009-1
  - `RenderingServer.frame_post_draw` (1× por quadro) e latência toque→golpe ≤ 33,3 ms a 60 Hz vsync — source: ADR-0010, EX-0010-1
  - `FileAccess.store_line` + `flush` (sobrevive a kill do processo), `gravar_atomico` com sequência `.old`, `ConfigFile.parse` exigindo `[meta]/schema_version`, `Time.get_datetime_string_from_system(true) + "Z"`, `OS.shell_open`, `NOTIFICATION_WM_CLOSE_REQUEST` — source: ADR-0013, EX-0013-P1..P7
  - `AudioServer.get_bus_index`, `pitch_scale > 0`, `stream_paused` (reporta `playing == false`), `volume_db`/`linear_to_db`, `default_bus_layout.tres` e loop WAV (`edit/loop_mode=2`, `edit/loop_end=-1`) — source: ADR-0016, EX-0016-A
- **Verificações ainda pendentes (não usar como fato sem medir):**
  - Experimentos `EX-0011-E1..E7` e `EX-0001-3` do Pipeline visual (`global uniform` com sampler em `canvas_item` + Shader Baker, draw calls em PIX/RenderDoc, SDF, `CanvasGroup`, `Line2D` × SDF, material por entidade) — source: ADR-0011, story-006/007 de `experimentos-de-engine`
  - Rodada em binário de **template de release exportado** (quando os export templates 4.7.2 forem instalados), monitor de 144 Hz real e desconexão com gamepad físico — source: EX-0001..EX-0016
  - `Vector2.normalized()` com vetor zero: nunca depender (testar `length_squared() == 0`) — source: ADR-0014

### Cross-Cutting Constraints
- **Determinismo:** passo fixo 60 Hz, hitstop como contador de passos, RNG próprio, iteração em ordem estável de id; dois runs com o mesmo roteiro produzem os mesmos estados/eventos — source: architecture.md (Principles #1), ADR-0005, ADR-0008
- **Co-op preparado:** todo estado de jogador por `player_id`, nunca campo singular — source: ADR-0009, ADR-0010, ADR-0017
- **Testes:** regras puras testáveis em memória com dublês injetados; nenhum teste depende de `SceneTree` para lógica — source: ADR-0001, ADR-0013, coding-standards.md
- **Evidência visual:** histórias que mudam algo observável exigem screenshot retido em `production/qa/evidence/`; testes headless não provam sensação — source: coding-standards.md, ADR-0007
