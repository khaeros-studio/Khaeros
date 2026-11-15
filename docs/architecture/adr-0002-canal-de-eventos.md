# ADR-0002: Canal de eventos

## Status
Proposed

## Date
2026-11-13

## Last Verified
2026-11-13 (contra `docs/engine-reference/godot/` e os GDDs aprovados; itens marcados "a verificar" não foram confirmados)

## Decision Makers
Usuário (khaeros-studio) e Claude (sessão de Arquitetura). TD-ADR não rodou (review_mode lean).

## Summary
Os módulos do Khaeros precisam se avisar de ~20 tipos de evento (golpe, acerto, inimigo_morreu, camara_limpa, saldo_mudou…) sem acoplamento forte e sem perder o determinismo. Decidido: uma **lista append-only de eventos tipados por passo** (`EventosDoPasso`), que os módulos de regra leem dentro do próprio passo e que o orquestrador entrega à Apresentação, em ordem fixa, no fim de cada passo; a cadeia de controle entre sistemas usa **chamada direta por interface injetada**, e sinais do Godot só existem nos nós de Apresentação.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (pin 4.7.2) |
| **Domain** | Core (Scripting) |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` |
| **Post-Cutoff APIs Used** | `@abstract` (4.5, confirmado) na base `EventoDoPasso`. Regra do 4.7 (confirmada): `override` de método com retorno tipado herda o tipo e exige `return` explícito; vale para o `tipo() -> StringName` de cada subclasse |
| **Verification Required** | (1) custo de alocar um `RefCounted` por evento em GDScript, com dezenas de eventos por passo (a medir no protótipo de arquitetura); (2) `Array[EventoDoPasso]` tipado com subclasses em `@abstract`; (3) ordem em que um sinal do Godot chama os conectados, e o efeito de `CONNECT_DEFERRED`, usados só nos nós de Apresentação. Nenhum destes itens está coberto por `docs/engine-reference/`: são NOT SOURCEABLE até um experimento confirmar |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (o orquestrador esvazia a lista no fim do passo; deve estar Accepted antes deste ser aceito) |
| **Enables** | ADR-0010 (Resolução do combate no passo: quais eventos cada item emite), ADR-0011 (Pipeline: pedidos do Feedback), ADR-0012 (UI e HUD: sinais na Apresentação) |
| **Blocks** | Épicos de Combate, Feedback de combate, HUD e Telemetria |
| **Ordering Note** | O tipo do alvo nos eventos (`InimigoRef`) é decidido no ADR-0003; até lá os eventos usam um identificador de alvo opaco |

## Context

### Problem Statement
O Combate emite 13 eventos (V1–V15), e Selo, Status, Movimento, IA, Câmaras, Portas, Bênçãos e Economia emitem outros. Há dois tipos de consumidor: a Apresentação (Feedback, HUD, Telemetria, Áudio), que só reage, e os módulos de regra (Selo, Status, Câmaras, Run), cuja reação muda o resultado do passo. Sem uma decisão única, cada GDD assume um mecanismo diferente e a ordem de entrega fica implícita.

### Constraints
- Passo fixo de 60 Hz e ordem fixa dos 10 itens (ADR-0001); mesma seed e mesmo catálogo geram a mesma estrutura de run.
- A Apresentação só lê e nunca escreve no jogo (princípio 4); a lógica de jogo não depende do `SceneTree` nem de singleton (princípio 2).
- Posições registradas: `passo_da_simulacao`, `pausa_do_jogo`, e os padrões proibidos `orquestrador_como_autoload`, `timer_na_logica_de_jogo`, `ordem_do_passo_por_process_priority`.
- O Feedback é "árbitro puro": recebe a lista de eventos do passo e os dois relógios, devolve pedidos, e é testável sem renderizar (Feedback R14).
- A Telemetria só escuta, nunca altera estado e absorve toda falha (Telemetria R2).

### Requirements
- Representar cada evento com campos fixos e verificáveis.
- Entregar os eventos à Apresentação em ordem determinística.
- Permitir que um módulo de regra reaja, no mesmo passo, a um evento emitido por um item anterior, sem callbacks.
- Fazer valer "morte vence a limpeza" (Run R5, Portas R3) sem depender de ordem de conexão.
- Ser testável em memória.

## Decision

Três regras, todas na Foundation.

**1. Lista de eventos do passo (`EventosDoPasso`).** Um objeto `RefCounted` de lógica pura, criado pelo `Main` e injetado nos módulos. Os módulos de regra chamam `emitir(evento)` durante o passo. A lista é **append-only dentro do passo** e é esvaziada **uma vez por `passo_fisico()`**, pelo orquestrador, ao final do passo.

**2. Eventos como classes tipadas.** Cada tipo é uma subclasse de `EventoDoPasso` (`@abstract`, `RefCounted`) com campos fixos definidos no construtor e **imutáveis depois de emitidos**. O GDScript não tem campo somente leitura: a imutabilidade é **convenção**, garantida por revisão e por teste, não pelo compilador. O payload guarda só dados (valores e identificadores): nunca carrega `Node`, nem referência ao `EventosDoPasso` ou ao módulo emissor (RefCounted não tem coletor de ciclos, e uma referência de volta vaza).

**3. Dois consumidores, duas regras.**
- **Módulos de regra** (Selo, Status, Câmaras, Run, Portas…) **leem a própria lista do passo**: um módulo posterior consulta `do_tipo()` e vê só os eventos que os itens anteriores já emitiram. A ordem é a do passo, não a de quem foi injetado ou conectado. É assim que Selo (item 6) lê o `acerto_de_arma` do item 5, e que Run e Portas veem `jogador_morreu` e a `camara_limpa` no mesmo passo e a morte vence.
- **Apresentação** (Telemetria, HUD, Feedback; o Áudio recebe ganchos do Feedback) recebe a lista esvaziada **no fim de cada `passo_fisico()`**, inclusive nos estados fora de `JOGO`, numa ordem fixa registrada pelo `Main`: Telemetria, HUD, Feedback.

**Cadeia de controle.** Fluxos em que a ordem muda o resultado, e que atravessam estados ou passos (`camara_limpa` → Portas → `pedir_oferta` → Bênçãos → Tela → `escolher`/`trocar` → `tela_fechada` → Portas abrem, `creditar`, `nova_run`), usam **chamada direta por interface injetada** entre módulos de regra. **Sinais do Godot existem só nos nós de Apresentação** (Tela, HUD), onde já são o mecanismo natural dos `Control`.

Eventos que nascem fora do passo (um clique na Tela de bênção, numa chamada de UI) entram na mesma lista e são entregues no próximo `passo_fisico()`.

### Architecture Diagram
```
 item 5  Combate ──emitir(AcertoDeArma)──┐
 item 6  Selo   ◄──do_tipo(&"acerto_de_arma")──┤   EventosDoPasso (append-only, dentro do passo)
 item 7  Status ◄──do_tipo(&"acerto")───────┤
 item 9  Combate ──emitir(InimigoMorreu)────┤
 item 10 Câmaras ◄─do_tipo(&"inimigo_morreu")┘ ──emitir(CamaraLimpa)
                                              │
              fim de passo_fisico()  (Orquestrador esvazia UMA vez)
                                              ▼
              Telemetria ─► HUD ─► Feedback ─► (ganchos) Áudio        ordem fixa

 Cadeia de controle (chamada direta, interface injetada):
   Câmaras ─camara_limpa─► Portas ─pedir_oferta─► Bênçãos ─oferta_aberta─► Tela (Control; sinais só aqui)
                                  ◄─bencao_escolhida (após tela_fechada)─
```

### Key Interfaces
```gdscript
# evento_do_passo.gd   (formato da referência da engine: @abstract na linha de cima)
@abstract
class_name EventoDoPasso extends RefCounted
var n_passo: int = -1            # preenchido por EventosDoPasso.emitir(); somente leitura POR CONVENÇÃO (GDScript não tem campo readonly)
@abstract func tipo() -> StringName
# Em 4.7, cada subclasse precisa de `return` explícito: func tipo() -> StringName: return &"inimigo_morreu"
# O override mantém o tipo de retorno herdado: nunca `-> void` nem outro tipo.

# eventos_do_passo.gd
class_name EventosDoPasso extends RefCounted
func emitir(e: EventoDoPasso) -> void                    # só em passo ou em chamada de UI; erra em debug se chamado durante a entrega
func ha(tipo: StringName) -> bool                        # já houve, neste passo?
func do_tipo(tipo: StringName) -> Array[EventoDoPasso]   # SEMPRE uma cópia nova, só dos já emitidos, na ordem de emissão
func todos() -> Array[EventoDoPasso]                     # SEMPRE uma cópia nova, ordenada
func esvaziar() -> Array[EventoDoPasso]                  # só o Orquestrador; devolve o array antigo e passa a usar um array novo (nunca clear() no devolvido)

# consumidor da Apresentação (Telemetria, HUD, Feedback)
@abstract
class_name ConsumidorDeEventos extends RefCounted
@abstract func consumir(eventos: Array[EventoDoPasso]) -> void   # somente leitura; nunca escreve em jogo; a regra do 4.7 vale também para as implementações
```

Leitura de campos da subclasse: `do_tipo()` devolve a base, então o módulo faz o downcast a cada uso (`var m := e as InimigoMorreu`). Para montar um `Array[EventoDoPasso]` de retorno, criar o array tipado e usar `append` (um `filter()` pode devolver `Array` sem tipo e a atribuição falha em tempo de execução).
Exemplo de subclasse: `InimigoMorreu(alvo_id, posicao: Vector2, elite: bool, chefe: bool, vel_empurrao: float, impact_passos: int)`, com os campos do GDD de Combate (V12).

### Implementation Guidelines
- Todo evento **must** ser uma subclasse tipada de `EventoDoPasso`, com campos definidos no construtor e **must never** ser alterado depois de emitido.
- O payload **must never** carregar `Node` nem referência viva a inimigo: usa o identificador do alvo (tipo final decidido no ADR-0003).
- O evento **must** guardar só dados; **must never** guardar referência ao `EventosDoPasso`, ao módulo emissor nem a outro evento (ciclo de `RefCounted` vaza).
- `do_tipo()` e `todos()` **must** devolver uma cópia nova a cada chamada; `esvaziar()` **must** devolver o array antigo e passar a usar um array novo, sem `clear()` no devolvido. Em GDScript, arrays passam por referência: sem isso o consumidor recebe um array vazio ou muta a lista interna.
- Um módulo que lê `do_tipo()` e emite dentro do laço **must** saber que o laço não vê o evento novo (a lista lida é cópia); o evento novo só aparece nas leituras seguintes.
- `emitir()` **must** errar em debug quando chamado durante a entrega à Apresentação (flag interna `_entregando` com `assert`), porque o tipo não impõe isso sozinho.
- O módulo de regra **must** fazer o downcast do evento (`as`) antes de ler campos da subclasse.
- Um módulo de regra **must** reagir a um evento lendo `do_tipo()` e **must never** depender da ordem de registro, de conexão ou de injeção.
- Um consumidor da Apresentação **must never** chamar `emitir()`, nem escrever em estado de jogo, nem guardar o evento além do passo (copia o que precisa).
- O orquestrador **must** chamar `esvaziar()` exatamente uma vez por `passo_fisico()`, também fora de `JOGO`, e entregar a lista aos consumidores na ordem registrada pelo `Main`.
- Os eventos emitidos no passo que pede o hitstop **must** ser entregues normalmente; em passos congelados a lista vem vazia e a Apresentação segue pelos relógios (`t_apres`), não por eventos.
- Na cadeia de controle, a ordem é a da chamada: **must never** haver sinais do Godot entre módulos de regra.
- Sinais do Godot **must** ficar restritos a nós de Apresentação (`Control`, `CanvasLayer`); o `Main` os conecta explicitamente.
- A base `EventoDoPasso` **must** ser `@abstract`; cada subclasse **must** implementar `tipo()` com `return` explícito.
- Em debug, um passo que emite eventos demais **should** gerar um alerta; o limite é provisório e sai da medição no protótipo.

## Alternatives Considered

### Alternative 1: Sinais do Godot para todos os eventos
- **Description**: cada módulo declara `signal`s e os consumidores se conectam; a lista de eventos não existe.
- **Pros**: idiomático; pouco código de infraestrutura.
- **Cons**: a ordem de chamada dos conectados depende da ordem de conexão (não confirmada na referência da engine); a reação "no mesmo passo" vira ordem de conexão escondida na lógica de jogo; testar exige montar a árvore.
- **Rejection Reason**: o determinismo e a regra "morte vence a limpeza" não podem depender de ordem de conexão.

### Alternative 2: Barramento global (`Autoload`) com publicar/assinar por nome
- **Description**: um singleton `EventBus` com `publish("nome", payload)` e `subscribe`.
- **Pros**: desacopla ao máximo; fácil de acessar de qualquer lugar.
- **Cons**: é um singleton global (princípio 2 e o padrão `orquestrador_como_autoload` mostram o caminho oposto); sem tipo nem checagem do payload; ordem de assinantes implícita; difícil de testar em memória.
- **Rejection Reason**: contraria a injeção e a testabilidade que sustentam a arquitetura.

### Alternative 3: Evento como `Dictionary` com `tipo`
- **Description**: o mesmo canal duplo, mas cada evento é um `Dictionary` com `tipo` e campos livres.
- **Pros**: menos código; nenhuma classe por evento.
- **Cons**: um campo errado só falha em tempo de execução; o GDScript não ajuda; os GDDs listam campos fixos por evento (ex.: `inimigo_morreu`).
- **Rejection Reason**: ~20 classes pequenas custam menos do que bugs de campo silenciosos num jogo cujos GDDs já especificam o payload.

## Consequences

### Positive
- Um único mecanismo, com ordem determinística, para os ~20 tipos de evento.
- "Morte vence a limpeza" vira uma leitura da lista, testável sem engine.
- Feedback e Telemetria seguem testáveis em memória com uma lista montada à mão.
- A Apresentação fica fora da lógica: não consegue reordenar nem alterar o passo.

### Negative
- ~20 classes de evento para escrever e manter.
- Reagir "lendo a lista" cria acoplamento temporal: um módulo só vê o que os itens anteriores emitiram, então mudar a ordem do passo muda o comportamento (a ordem já é fixa por ADR-0001).
- Alocação de objetos por passo: custo a medir.

## Risks
- **Custo de alocação:** dezenas de `RefCounted` por passo em GDScript. *Mitigação:* medir no protótipo de arquitetura; se pesar, reutilizar instâncias por tipo.
- **Reação fora de ordem:** um módulo pode ler a lista antes de o item que emite rodar. *Mitigação:* teste com módulos falsos que prova a ordem dos 10 itens e o que cada um vê.
- **Eventos de UI atrasados:** um evento nascido de um clique espera até o próximo `passo_fisico()` (até ~16,7 ms). *Mitigação:* aceitável para notificações; o que exige resposta imediata é controle e vai por chamada direta. Como tudo roda na thread principal e a entrega acontece dentro de `passo_fisico()`, um clique nunca chega no meio da entrega: o evento espera o passo seguinte.
- **Imutabilidade e `n_passo` só por convenção:** o GDScript não impõe campo somente leitura. *Mitigação:* revisão, teste que compara os campos antes e depois da entrega, e a regra de só guardar dados.
- **Cópia vs referência em arrays:** devolver a própria lista interna deixa o consumidor mutá-la, ou recebê-la vazia depois de um `clear()`. *Mitigação:* cópia em `do_tipo()` e `todos()`, e array novo em `esvaziar()`.
- **Ciclo de referência e vazamento:** evento ou módulo que guarda ponteiro de volta ao `EventosDoPasso`. *Mitigação:* a regra "evento só guarda dados" e um teste que confere que a lista é liberada.
- **Alocação (nota do especialista):** reutilizar instâncias conflita com "imutável depois de emitido" e com um consumidor que retém o evento; por isso o ADR não prevê pool. Medir antes de mudar.
- **Sinais na UI (a verificar):** a ordem de chamada dos conectados e o `CONNECT_DEFERRED` não estão na referência. *Mitigação:* a Apresentação não depende da ordem entre sinais; verificação (3).
- **Payload com alvo opaco até o ADR-0003:** retrabalho possível quando `InimigoRef` for definido. *Mitigação:* o campo é um identificador, troca de tipo localizada.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| combate-nucleo.md | Eventos V1–V15 emitidos pelo Combate e consumidos por HUD, Feedback, Áudio, Selo, Status, Câmaras, Run e Telemetria (TR combate-nucleo-009, provisório) | `emitir()` na lista; módulos de regra leem `do_tipo()`; Apresentação recebe no fim do passo |
| feedback-de-combate.md | Árbitro puro: recebe a lista de eventos do passo e devolve pedidos, testável sem renderizar (TR feedback-001, R14) | `ConsumidorDeEventos.consumir(eventos)` recebe a lista; testes montam a lista em memória |
| feedback-de-combate.md | Cada resposta declara relógio; respostas de apresentação correm durante o hitstop (TR feedback-006) | Passos congelados entregam lista vazia; a Apresentação segue por `t_apres` |
| hud.md | O HUD só lê e lê o estado por consulta, nunca só por evento (TR hud-001, 002) | HUD é consumidor read-only; a consulta de estado continua sendo o caminho de criação |
| telemetria-local.md | Só escuta, nunca altera estado, absorve falhas (TR telemetria-002) | Telemetria é consumidor read-only, primeira na ordem de entrega |
| selo-e-fluxo.md | `acerto_de_arma` do item 5 alimenta o Fluxo no item 6 (TR selo-001, 007) | Selo lê `do_tipo(&"acerto_de_arma")` no próprio passo |
| efeitos-de-status.md | Status aplicado por `acerto_de_arma` e gatilhos (TR efeitos-de-status-005) | Status lê a lista do passo |
| run-e-regioes.md | Morte vence a limpeza no mesmo passo (TR run-005) | Run lê `jogador_morreu` e `camara_limpa` da lista e ignora a limpeza |
| portas-e-recompensas.md | Concessão ao `camara_limpa`; nada creditado se `jogador_morreu` cair no mesmo passo (TR portas-003) | Portas confere `ha(&"jogador_morreu")` antes de conceder |
| tela-de-bencao-e-carta.md | Sinais de saída `preco_revelado` e `tela_fechada`; Bênçãos segura `bencao_escolhida` (TR tela-de-bencao-007) | Sinais só na UI; a cadeia entre módulos de regra é chamada direta |

## Performance Implications
- **CPU**: um `RefCounted` por evento, dezenas por passo no pior caso; custo a medir. O orçamento de Combate (p99 ≤ 0,3 ms/passo, provisório) inclui a emissão dos próprios eventos.
- **Memory**: a lista é esvaziada a cada passo; pico pequeno e sem acúmulo.
- **Load Time**: desprezível.
- **Network**: N/A.

## Migration Plan
Não há código de produção ainda. O protótipo `prototypes/combate-camara-concept/` é descartável e não migra.

## Validation Criteria
- Teste com módulos falsos prova que um módulo posterior vê o evento emitido por um item anterior e não vê os de itens posteriores.
- Teste prova que `jogador_morreu` e `camara_limpa` no mesmo passo resultam em "morte vence" para Run e Portas.
- Teste prova que `esvaziar()` roda uma vez por `passo_fisico()`, também fora de `JOGO`, e que os consumidores recebem na ordem Telemetria, HUD, Feedback.
- Teste prova que `emitir()` erra em debug quando chamado durante a entrega à Apresentação.
- Teste prova que `do_tipo()` e `todos()` devolvem cópia (mutar o resultado não altera a lista) e que `esvaziar()` entrega o conteúdo íntegro e deixa a lista vazia.
- Teste de convenção compara os campos de cada evento antes e depois da entrega (imutabilidade) e confere que a lista é liberada (sem ciclo).
- Medição no protótipo de arquitetura fecha o custo de alocação e os itens de "Verification Required".

## Related
- ADR-0001 (orquestrador do passo; esvazia a lista); ADR-0003 (tipo do alvo `InimigoRef`); ADR-0010, 0011, 0012
- `docs/architecture/architecture.md` (Data Flow, cenário 2; API 9 e 11)
- GDDs: combate-nucleo, feedback-de-combate (R1, R14), hud, telemetria-local, selo-e-fluxo, efeitos-de-status, camaras-e-ondas, portas-e-recompensas, run-e-regioes, bencaos-tradicoes, tela-de-bencao-e-carta, economia-de-fragmentos
