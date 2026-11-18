# ADR-0002: Canal de eventos

## Status
Accepted · 2026-11-16 (aprovado pelo usuário; Proposed em data do ADR)

## Date
2026-11-13

## Last Verified
2026-11-17 (experimentos EX-0002-1..3 no Godot 4.7.2: teto seguro ~20 eventos/passo em debug registrado com medição em release pendente, `filter()` tipado confirmado, `@abstract` estático vs `Script.new()` anotado, VR(2) e VR(3) verificados). Antes: 2026-11-16 (emenda Pactos e pendências: catálogo completo de eventos, eventos de Pactos, consumidor Áudio; ver "Emenda Pactos e pendências"). Anterior: 2026-11-15 (revisão: regra "lista só para itens anteriores, chamada direta para posteriores", crédito tardio do Pulso, `aplicar_status` síncrono, entrega em passo congelado; lacunas 1, 3, 4 e 5 de `architecture-review.md`). Original: 2026-11-13, contra `docs/engine-reference/godot/` e os GDDs aprovados.

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
| **Verification Required** | (1) custo de alocar um `RefCounted` por evento em GDScript (`EX-0002-1`): **PARCIAL (medido em debug, 2026-11-16)** — teto seguro de ~20 eventos/passo em debug (p99 `166–198 µs`, dentro dos `300 µs` do Combate; com 50 eventos sobe a `330–482 µs`), medição no template de release pendente; (2) `Array[EventoDoPasso]` tipado com subclasses em `@abstract` (`EX-0002-2`): **VERIFICADO** — `filter()` de array tipado devolve array tipado no 4.7.2, e `@abstract` é análise estática (bloqueia `EventoDoPasso.new()`, mas não impede `Script.new()` dinâmico); (3) ordem em que um sinal do Godot chama os conectados e efeito de `CONNECT_DEFERRED` (`EX-0002-3`): **VERIFICADO** — deferidos rodam após o retorno do emissor na ordem de conexão, confirmando a necessidade da lista explícita para a ordem fixa Telemetria → HUD → Feedback → Telas → Áudio |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (o orquestrador esvazia a lista no fim do passo; deve estar Accepted antes deste ser aceito) |
| **Enables** | ADR-0010 (Resolução do combate no passo: quais eventos cada item emite), ADR-0011 (Pipeline: pedidos do Feedback), ADR-0012 (UI e HUD: sinais na Apresentação), ADR-0016 (Áudio: último consumidor da entrega), ADR-0017 (Aliados e invocações: emite os eventos de Maldição), ADR-0015 (Ciclo da run: emite os eventos de run e de Pactos) |
| **Blocks** | Épicos de Combate, Feedback de combate, HUD e Telemetria |
| **Ordering Note** | O alvo nos eventos é o id inteiro do ADR-0003 (crescente por ordem de surgimento na run), nunca referência à entidade |

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
- **Módulos de regra** (Selo, Câmaras, Run, Portas…) **leem a própria lista do passo só para eventos de itens anteriores ao seu**: um módulo posterior consulta `do_tipo()` e vê os eventos que os itens anteriores já emitiram. A ordem é a do passo, não a de quem foi injetado ou conectado. É assim que Selo (item 6) lê o `acerto_de_arma` do item 5, e que Run e Portas veem `jogador_morreu` e a `camara_limpa` no mesmo passo e a morte vence.
- **Produtor depois de quem reage, ou efeito no instante do impacto → chamada direta.** Quando a reação muda estado de regra e o produtor roda no mesmo item ou depois do módulo que reage, o produtor chama a interface injetada do módulo, de forma síncrona. Casos do MVP:
  - `status.aplicar_status(alvo_id, id, n)`, chamado pelo Combate no impacto (itens 5, 7 e 8; Status R2–R3) e pelo Selo (item 6). O efeito existe no alvo no mesmo instante; o dano por passo (item 7) o fere no mesmo passo se aplicado nos itens 5 ou 6 e só no passo seguinte se aplicado no item 8 (AC-ST-08).
  - `selo.creditar_acerto_tardio()`, chamado pelo Combate uma vez por alvo atingido por projétil no item 8. O Selo aplica `φ ← min(F_max, φ + a)` a cada chamada, o que equivale a `min(F_max, φ₆' + a × n₈)` da F1 porque as parcelas são positivas. O teste do Selo no item 6 não muda de lugar; o saldo só serve no passo seguinte (AC-SF-26: 38,9 → 41,96). Em hitstop e fora de `JOGO` o item 8 não roda, então não há crédito.
  - O `acerto_de_arma` continua sendo emitido nos dois casos, como **notificação** (Selo lê o do item 5; Apresentação e Telemetria recebem todos), nunca como o caminho que aplica status ou credita Fluxo do item 8.
- **Apresentação** (Telemetria, HUD, Feedback, Telas; o Áudio recebe ganchos do Feedback) recebe a lista esvaziada **no fim de cada `passo_fisico()`**, inclusive nos estados fora de `JOGO`, numa ordem fixa registrada pelo `Main`: Telemetria, HUD, Feedback, Telas, Áudio (ADR-0012: a Tela de bênção recebe a oferta por evento; ADR-0016: o Áudio é o último, consome o `PedidoDeSom` do Feedback e a `FilaDeSonsDeInterface` de Telas e HUD, e não só ganchos).

**Cadeia de controle.** Fluxos em que a ordem muda o resultado, e que atravessam estados ou passos (`camara_limpa` → Portas → `pedir_oferta` → Bênçãos → Tela → `escolher`/`trocar` → `tela_fechada` → Portas abrem, `creditar`, `nova_run`), usam **chamada direta por interface injetada** entre módulos de regra. **Sinais do Godot existem só nos nós de Apresentação** (Tela, HUD), onde já são o mecanismo natural dos `Control`.

Eventos que nascem fora do passo (um clique na Tela de bênção, numa chamada de UI) entram na mesma lista e são entregues no próximo `passo_fisico()`.

### Architecture Diagram
```
 item 5  Combate ──emitir(AcertoDeArma)──┐       ──status.aplicar_status() (direto, no impacto)
 item 6  Selo   ◄──do_tipo(&"acerto_de_arma")──┤   EventosDoPasso (append-only, dentro do passo)
 item 7  Status: dano por passo (chamado pelo orquestrador, por inimigo); impacto ──aplicar_status() direto
 item 8  Combate ──emitir(AcertoDeArma)──┤       ──selo.creditar_acerto_tardio() + aplicar_status() (diretos)
 item 9  Combate ──emitir(InimigoMorreu)────┤      ──pedir_estado(MORTE) se o jogador morreu
 item 10 Câmaras ◄─do_tipo(&"inimigo_morreu")┘ ──emitir(CamaraLimpa)
                                              │
              final comum de passo_fisico()  (Orquestrador esvazia UMA vez, em todo estado, mesmo vazia)
                                              ▼
              Telemetria ─► HUD ─► Feedback ─► Telas ─► Áudio          ordem fixa

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

# consumidor da Apresentação (Telemetria, HUD, Feedback, Telas, Áudio; ordem de entrega fixa)
@abstract
class_name ConsumidorDeEventos extends RefCounted
@abstract func consumir(eventos: Array[EventoDoPasso]) -> void   # somente leitura; nunca escreve em jogo; a regra do 4.7 vale também para as implementações
```

Leitura de campos da subclasse: `do_tipo()` devolve a base, então o módulo faz o downcast a cada uso (`var m := e as InimigoMorreu`). Para montar um `Array[EventoDoPasso]` de retorno, criar o array tipado e usar `append`, ou usar `filter()`: no 4.7.2, `filter()` sobre um `Array[EventoDoPasso]` devolve um array do mesmo tipo (verificado em 2026-11-16) e a atribuição funciona.
Exemplo de subclasse: `InimigoMorreu(alvo_id: int, posicao: Vector2, elite: bool, chefe: bool, vel_empurrao: float, impact_passos: int)`, com os campos do GDD de Combate (V12). `alvo_id` é o id do ADR-0003.

```gdscript
# interfaces de chamada direta usadas pelo Combate (classes @abstract próprias; adaptador se o módulo já estende outra base)
func aplicar_status(alvo_id: int, id: StringName, n: float) -> void   # Status R2; síncrono
func creditar_acerto_tardio(player_id: int) -> void                    # Selo F1, um por alvo no item 8; player_id 0 no solo
```

### Catálogo de eventos (fechado em 2026-11-16)

Cada linha é uma subclasse de `EventoDoPasso`; `tipo()` devolve o `StringName` da coluna `tipo`. Todo evento de jogador carrega `player_id` (0 no solo). Os ids de alvo, de Maldição e de chefe são inteiros do ADR-0003; `especie_id` e `curse_id` são ids estáveis de `CurseDef` (`StringName`). Os eventos do Combate (V1–V15, incluindo `acerto_de_arma`, `jogador_atingido`, `jogador_morreu`, `inimigo_morreu`) ficam no ADR-0010; esta tabela fecha os demais.

| Classe | `tipo` | Campos | Emissor (item) | Requisito |
|---|---|---|---|---|
| `EvSelo` | `selo` | `player_id`, `centro: Vector2`, `raio_px: float`, `duracao_passos: int` | Selo (6) | TR-selo-012 |
| `EvSeloSemFluxo` | `selo_sem_fluxo` | `player_id` (uma vez por toque novo) | Selo (6) | TR-selo-012 |
| `EvSeloFim` | `selo_fim` | `player_id` | Selo (6) | TR-selo-012 |
| `EvOfertaAberta` | `oferta_aberta` | `player_id`, `indice_camara`, `cartas: Array[Dictionary]` (`id`, `raridade`), `trocas: int` | Bênçãos (na chamada de `pedir_oferta`; entregue no fim do passo) | TR-bencaos-007 |
| `EvOfertaTrocada` | `oferta_trocada` | `player_id`, `cartas`, `trocas` (restantes) | Bênçãos (chamada da Tela) | TR-bencaos-007 |
| `EvBencaoTomada` | `bencao_tomada` | `player_id`, `id`, `raridade`, `trocas_restantes` | Bênçãos, em `notificar_tela_fechada()` | TR-bencaos-007 |
| `EvPortaEscolhida` | `porta_escolhida` | `player_id`, `indice_camara`, `tipo: StringName`, `opcoes: Array[StringName]` | Portas | TR-portas-008 |
| `EvCamaraEntrou` | `camara_entrou` | `indice`, `p`, `tipo` (`combate`, `santuario`, `chefe`) | Run (ADR-0015) | TR-telemetria-003 |
| `EvPassoVivo` | `passo_vivo` | `n_vivo: int` (passo em estado Jogo; não conta pausa, Bênção nem Transição; conta hitstop) | Orquestrador (item 1, só em `JOGO`) | TR-telemetria-003 |
| `EvJogadorMorreu` (campos novos) | `jogador_morreu` | acrescenta `causa_tipo_inimigo`, `causa_ataque` (vazios se desconhecidos) | Combate (9) | TR-telemetria-003 |
| `EvFimDaRun` | `fim_da_run` | `motivo` (`vitoria`, `morte`, `abandono`) | Run | TR-run-004 |
| `EvRunEncerrada` | `run_encerrada` | `resumo: Dictionary` (12 campos, Run R7-P), `caminho: Array` | Run | TR-run-007 |

**Pactos (emenda 2026-11-16).** Emitidos por Maldições (item 6.1, ADR-0017), Combate (itens 5, 7, 8, 9), Vínculo e Chefes (ADR-0015). Todos com `player_id`.

| Classe | `tipo` | Campos | Emissor |
|---|---|---|---|
| `EvMaldicaoTrocada` | `troca_feita` | `modo` (`manual`, `automatica`), `saiu_id`, `entrou_id` (ids `MaldicaoRef`) | Maldições (6.1) |
| `EvTecnicaCombinada` | `tecnica_combinada` | `saida_id`, `entrada_id`, `acertos: int` | Maldições (6.1) |
| `EvMaldicaoFerida` | `maldicao_atingida` | `maldicao_id`, `dano: float`, `origem: int` (id do atacante) | Combate (`ferir_maldicao`) |
| `EvMaldicaoExausta` | `maldicao_exausta` | `maldicao_id`, `curse_id` | Combate (único emissor, após `exaurir` síncrono; GDD Combate R17, Maldições R20) |
| `EvAcuadaFerida` | `acuada_atingida` | `dano: float`, `vida_restante: int`, `origem: int` | Combate (`ferir_acuada`) |
| `EvEncontroFalhou` | `encontro_falhou` | `especie_id`, `indice_camara` | Vínculo (antes do item 9) |
| `EvPactoFormado` | `pacto_registrado` | `especie_id`, `origem` (`primeiro`, `encontro`, `chefe`) | Vínculo (gatilho de gravação do Save R5) |
| `EvChefeVencido` | `chefe_vencido` | `id`, `subjugado: bool`, `posicao`, `autor_player_id`, `impact_passos` (ADR-0010; nome do GDD de Combate R17) | Combate, na varredura do item 9 do passo `s` em que o chefe chega a Vida ≤ 0 (ADR-0010 §11; Chefes R9b.2). Os Chefes o assinam |
| `EvChefeSubjugado` | `chefe_subjugado` | `chefe_id`, `posicao` | **Chefes** (`ModuloDeChefes`, ADR-0018), em `s + 37`, só se `subjugado` (Chefes R9 e R9b.2). Nunca o `subjugar` do Combate |
| `EvChefeExorcizado` | `chefe_exorcizado` | `chefe_id`, `posicao`, `impact_passos` | Combate (`resolver_subjugado`, só no Exorcizar; ADR-0010 §11), chamado pelos Chefes em R9b.3 |
| `EvVinculoGanho` | `vinculo_atualizado` | `especies: Array[Dictionary]` (`id`, `pontos_run`, `vinculo_pontos`, `nivel`, `subiu_nivel`) | Vínculo, no fecho da run |

Eventos de run e de Pactos com nome fixo no GDD (os nomes do GDD prevalecem sobre os do brief; a tabela acima traz os eventos do núcleo; esta traz os de run e de Pactos, e a ela se remete quando um mesmo `tipo` aparecer nas duas. As classes de Pactos do GDD podem ter nome diferente do `tipo`, por exemplo `EvPactoFormado` emite `pacto_registrado` e `EvMaldicaoFerida` emite `maldicao_atingida`; vale sempre o `tipo`):

| Classe | `tipo` | Campos | Emissor |
|---|---|---|---|
| `EvDuplaConfirmada` | `dupla_confirmada` | `player_id`, `campo_id`, `reserva_id` (`StringName`, `&""` = vaga vazia) | Run (fim da escolha da dupla; cria a seed, RNG R2-P) |
| `EvPactoResolvido` | `pacto_resolvido` | `player_id`, `especie_id`, `resultado` (`pactuada`, `reafirmada`, `deixada`, `voltara`, `fugiu`, `abandonado`) | Vínculo (libera as Portas, Portas R2) |
| `EvChefeEscolhido` | `chefe_escolhido` | `player_id`, `chefe_id`, `escolha` (`pactuar`, `exorcizar`) | Vínculo, ao fechar a tela Pactuar/Exorcizar (estado `BENCAO`, evento de UI fora do passo). Os Chefes aplicam R9b.3 no 1º passo vivo depois (ADR-0015 §5); as Câmaras emitem `camara_limpa(4, chefe)` (Chefes R9b.4) |
| `EvEncontroPacto` | `encontro_pacto` | `player_id`, `indice_camara`, `especie`, `resultado`, `vida_restante: int` | Vínculo (Telemetria R4-P) |
| ~~`EvVinculoFimRun`~~ | — | **fundido em `EvVinculoGanho`** (um fato, uma classe, `tipo` = `vinculo_atualizado`); a Telemetria grava esse evento com o nome de linha `vinculo_fim_run` (revisão 2026-11-16, 🟡6) | Vínculo |
| `EvAcertoVirote` | `acerto_virote` | `player_id`, `alvo_id`, `posicao` | Combate (item 7, acerto do Virote da Besta do Vínculo); a Maldição o assina para a marca (TR-armas-013, nome do GDD de Armas) |

`pacto_registrado(especie_id)` e `vinculo_atualizado` são os de `EvPactoFormado` e `EvVinculoGanho`. Nomes de classe (`EvPactoFormado`, `EvMaldicaoFerida`) podem diferir do `tipo`; **o `tipo` é o contrato** (Telemetria, Áudio, testes) e a classe é só nome GDScript — não há divergência de `tipo` entre as duas tabelas. Um emissor por fato (harmonização 2026-11-16, Chefes R9b): `chefe_vencido` = Combate (queda, item 9); `chefe_subjugado` = Chefes (`s + 37`); `chefe_escolhido` = Vínculo (decisão); `chefe_exorcizado` = Combate (efeito do `resolver_subjugado`); `camara_limpa` = só Câmaras; `encontro_falhou` não tem nome no GDD (o Vínculo usa `falhar_encontro()` síncrono), então `EvEncontroFalhou` é só notificação.

Eventos auxiliares de Maldição sem consumidor de regra (`maldicao_entrou`, `maldicao_pronta`, `maldicao_golpe`, `chamado_salto`, `chamado_pouso`, `troca_indisponivel`, `marca_virote_mudou`, `atraido`, `atracao_fim`, `imobilizado`, `imobilizacao_fim`, `fio_estourou`; Maldições "Eventos") seguem a mesma regra e ficam definidos no ADR-0017. Os nomes `tipo` seguem os GDDs, para a Telemetria e o Áudio casarem com o texto de design.

### Implementation Guidelines
- Todo evento **must** ser uma subclasse tipada de `EventoDoPasso`, com campos definidos no construtor e **must never** ser alterado depois de emitido.
- O payload **must never** carregar `Node` nem referência viva a inimigo: usa o identificador do alvo (tipo final decidido no ADR-0003).
- O evento **must** guardar só dados; **must never** guardar referência ao `EventosDoPasso`, ao módulo emissor nem a outro evento (ciclo de `RefCounted` vaza).
- `do_tipo()` e `todos()` **must** devolver uma cópia nova a cada chamada; `esvaziar()` **must** devolver o array antigo e passar a usar um array novo, sem `clear()` no devolvido. Em GDScript, arrays passam por referência: sem isso o consumidor recebe um array vazio ou muta a lista interna.
- Um módulo que lê `do_tipo()` e emite dentro do laço **must** saber que o laço não vê o evento novo (a lista lida é cópia); o evento novo só aparece nas leituras seguintes.
- `emitir()` **must** errar em debug quando chamado durante a entrega à Apresentação (flag interna `_entregando` com `assert`), porque o tipo não impõe isso sozinho.
- O módulo de regra **must** fazer o downcast do evento (`as`) antes de ler campos da subclasse.
- Um módulo de regra **must** reagir a um evento de item anterior lendo `do_tipo()` e **must never** depender da ordem de registro, de conexão ou de injeção.
- Quando o produtor roda no mesmo item ou depois de quem reage, a reação **must** ser chamada direta do produtor; um módulo **must never** ler a lista esperando eventos de itens posteriores, nem num "gancho de fim de passo".
- Um consumidor da Apresentação **must never** chamar `emitir()`, nem escrever em estado de jogo, nem guardar o evento além do passo (copia o que precisa).
- O orquestrador **must** chamar `esvaziar()` exatamente uma vez por `passo_fisico()`, também fora de `JOGO`, e entregar a lista aos consumidores na ordem registrada pelo `Main`.
- Os eventos emitidos no passo que pede o hitstop **must** ser entregues normalmente. Em passos congelados e fora de `JOGO`, nenhum módulo de regra emite; a lista entregue traz só eventos nascidos fora do passo (UI), muitas vezes vazia, e é entregue mesmo assim (final comum do ADR-0001). A Apresentação segue pelos relógios (`t_apres`).
- Na cadeia de controle, a ordem é a da chamada: **must never** haver sinais do Godot entre módulos de regra.
- Sinais do Godot **must** ficar restritos a nós de Apresentação (`Control`, `CanvasLayer`); o `Main` os conecta explicitamente.
- A base `EventoDoPasso` **must** ser `@abstract`; cada subclasse **must** implementar `tipo()` com `return` explícito. Como `@abstract` no 4.7.2 é verificação estática e não bloqueia `load(...).new()` (`Script.new()` dinâmico; verificado em `EX-0002-2`), o código **must never** instanciar eventos por reflexão/script dinâmico e um teste unitário **must** garantir que `EventoDoPasso` nunca é instanciado diretamente.
- Em debug, um passo que emite eventos demais **should** gerar um alerta acima do teto seguro medido em `EX-0002-1` (~20 eventos/passo no binário debug, onde a alocação leva 166–198 µs p99); a medição no binário de release fica pendente da instalação dos templates 4.7.2.

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
- **Identidade do alvo:** o id do ADR-0003 precisa continuar associando eventos ao alvo certo depois de remoção ou troca de câmara. *Mitigação:* ids nunca reutilizados na run; teste de integração do ADR-0003.
- **Crédito tardio esquecido:** um projétil novo que acerta e não chama `creditar_acerto_tardio()`. *Mitigação:* teste AC-SF-26 e AC-ST-08 no Combate.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| armas-das-doutrinas.md | Virote emite `acerto_virote` para a marca da Maldição (TR-armas-013, R2b) | Evento no catálogo de Pactos; emitido no item 5 e lido da lista pelo módulo de Maldições no item 6.1 do mesmo passo (produtor anterior, regra da lista) |
| combate-nucleo.md | Eventos V1–V15 emitidos pelo Combate e consumidos por HUD, Feedback, Áudio, Selo, Status, Câmaras, Run e Telemetria (TR-combate-nucleo-009) | `emitir()` na lista; módulos de regra leem `do_tipo()`; Apresentação recebe no fim do passo |
| feedback-de-combate.md | Árbitro puro: recebe a lista de eventos do passo e devolve pedidos, testável sem renderizar (TR feedback-001, R14) | `ConsumidorDeEventos.consumir(eventos)` recebe a lista; testes montam a lista em memória |
| feedback-de-combate.md | Cada resposta declara relógio; respostas de apresentação correm durante o hitstop (TR feedback-006) | Passos congelados não trazem eventos de regra; a Apresentação segue por `t_apres` |
| hud.md | O HUD só lê e lê o estado por consulta, nunca só por evento (TR hud-001, 002) | HUD é consumidor read-only; a consulta de estado continua sendo o caminho de criação |
| telemetria-local.md | Só escuta, nunca altera estado, absorve falhas (TR telemetria-002) | Telemetria é consumidor read-only, primeira na ordem de entrega |
| selo-e-fluxo.md | `acerto_de_arma` do item 5 alimenta o Fluxo no item 6 (TR selo-001, 007) | Selo lê `do_tipo(&"acerto_de_arma")` no próprio passo |
| selo-e-fluxo.md | F1 e AC-SF-26: acerto do item 8 credita Fluxo no fim do passo e só serve no seguinte | Combate chama `selo.creditar_acerto_tardio()` por alvo no item 8 |
| efeitos-de-status.md | R2–R3: aplicação síncrona no impacto e pelo Selo; AC-ST-08 (item 8 fere a partir do passo seguinte) | `status.aplicar_status()` por chamada direta; o dano por passo do item 7 já rodou quando o item 8 aplica |
| run-e-regioes.md | Morte vence a limpeza no mesmo passo (TR run-005) | Run lê `jogador_morreu` e `camara_limpa` da lista e ignora a limpeza; o final comum do ADR-0001 também faz `MORTE` vencer |
| portas-e-recompensas.md | Concessão ao `camara_limpa`; nada creditado se `jogador_morreu` cair no mesmo passo (TR portas-003) | Portas confere `ha(&"jogador_morreu")` antes de conceder |
| selo-e-fluxo.md | Eventos `selo`, `selo_sem_fluxo` e `selo_fim` (TR-selo-012) | `EvSelo`, `EvSeloSemFluxo`, `EvSeloFim` no catálogo, emitidos no item 6 |
| bencaos-tradicoes.md | `oferta_aberta`, `oferta_trocada`, `bencao_tomada` para Tela, HUD, Áudio e Telemetria (TR-bencaos-007) | `EvOfertaAberta`, `EvOfertaTrocada`, `EvBencaoTomada` no catálogo; `bencao_tomada` sai em `notificar_tela_fechada()` |
| portas-e-recompensas.md | Evento de porta escolhida com `tipo` e `opcoes` (TR-portas-008) | `EvPortaEscolhida` |
| telemetria-local.md | Causa da morte, câmara entrou, passo vivo (TR-telemetria-003) | `EvJogadorMorreu` ampliado, `EvCamaraEntrou`, `EvPassoVivo` |
| run-e-regioes.md | `fim_da_run` e `run_encerrada` (TR-run-004, TR-run-007) | `EvFimDaRun`, `EvRunEncerrada` |
| maldicoes.md, vinculo-e-pactos.md, chefes.md | Eventos de troca, técnica, ferimento, exaustão, acuada, pacto, chefe e vínculo (TR-maldicoes-NNN, TR-vinculo-NNN, TR-chefes-NNN: registrar no `tr-registry.yaml`) | Catálogo "Pactos"; todos com `player_id`; Áudio como 5º consumidor (último) |
| tela-de-bencao-e-carta.md | Sinais de saída `preco_revelado` e `tela_fechada`; Bênçãos segura `bencao_escolhida` (TR tela-de-bencao-007) | Sinais só na UI; a cadeia entre módulos de regra é chamada direta |

## Performance Implications
- **CPU**: um `RefCounted` por evento, dezenas por passo no pior caso; custo a medir. O orçamento de Combate (p99 ≤ 0,3 ms/passo, provisório) inclui a emissão dos próprios eventos.
- **Memory**: a lista é esvaziada a cada passo; pico pequeno e sem acúmulo.
- **Load Time**: desprezível.
- **Network**: N/A.

## Migration Plan
O protótipo `prototypes/combate-camara-concept/` é descartável e não migra. A fatia jogável de 2026-11-14 devolve `Array[String]` de `GameSession.step()` como eventos; no épico de Foundation esses textos viram subclasses de `EventoDoPasso`, e a sessão passa a emitir em `EventosDoPasso`.

## Validation Criteria
- Teste com módulos falsos prova que um módulo posterior vê o evento emitido por um item anterior e não vê os de itens posteriores.
- Teste prova que `jogador_morreu` e `camara_limpa` no mesmo passo resultam em "morte vence" para Run e Portas.
- Teste prova que `esvaziar()` roda uma vez por `passo_fisico()`, também fora de `JOGO`, e que os consumidores recebem na ordem Telemetria, HUD, Feedback, Telas, Áudio.
- Teste prova que `emitir()` erra em debug quando chamado durante a entrega à Apresentação.
- Teste reproduz AC-SF-26 (Fluxo 38,9 → 41,96 com o Pulso no item 8; Selo só no passo 1) e AC-ST-08 (status do item 5 fere no passo 0; do item 8, a partir do passo 1).
- Teste prova que um evento de UI enfileirado em `BENCAO` é entregue uma vez no passo seguinte.
- Teste prova que `do_tipo()` e `todos()` devolvem cópia (mutar o resultado não altera a lista) e que `esvaziar()` entrega o conteúdo íntegro e deixa a lista vazia.
- Teste de convenção compara os campos de cada evento antes e depois da entrega (imutabilidade) e confere que a lista é liberada (sem ciclo).
- Medição no protótipo de arquitetura fecha o custo de alocação e os itens de "Verification Required".

## Emenda Pactos e pendências (2026-11-16)

- **Catálogo fechado.** Pendência de `architecture-review-2026-11-15.md` (Selo, Bênçãos, Portas, campos da Telemetria, Run) resolvida em "Catálogo de eventos". Nenhuma regra de emissão mudou.
- **Eventos de Pactos** (10 classes novas, todas com `player_id`), no catálogo. Os eventos de Maldição nascem no item 6.1; os de ferimento (`EvMaldicaoFerida`, `EvAcuadaFerida`) nascem nas chamadas diretas `ferir_maldicao` e `ferir_acuada` do Combate (ADR-0010) e, como qualquer evento, só chegam à Apresentação no fim do passo.
- **Item 6.1 e leitura da lista.** Maldições (6.1) leem `acerto_de_arma` do item 5 e `jogador_morreu` por `do_tipo()`, como o Selo; não leem nada dos itens 7 a 10. O abate do item 9 reage ao `EvEncontroFalhou` por chamada direta do Vínculo (a falha da acuada é avisada antes do item 9, contrato compartilhado), nunca por leitura de evento posterior.
- **Áudio como consumidor.** Ordem de entrega fixada pelo ADR-0016: **Telemetria, HUD, Feedback, Telas, Áudio** (`Telas` continua 4º, como pediu o ADR-0012; o Áudio é o 5º e último, para consumir o `PedidoDeSom` do Feedback e a `FilaDeSonsDeInterface` de Telas e HUD já preenchidos). Áudio só lê, como os demais.
- **Decisões minhas, para revisão:** (1) `tipo` segue os nomes dos GDDs (`maldicao_atingida`, `acuada_atingida`, `chefe_subjugado`), e a classe segue o contrato (`EvMaldicaoFerida`, `EvAcuadaFerida`); (2) `chefe_vencido` do Combate (GDD) permanece e vira `EvChefeVencido(id, subjugado)`; `chefe_subjugado` (nome do GDD de Chefes e Run) é dos Chefes em `s + 37` e `chefe_exorcizado` é do Combate no `resolver_subjugado` (resolvido em 2026-11-16 conforme Chefes R9b; um emissor por fato); (3) `chefe_exorcizado` e `encontro_falhou` não têm nome em GDD, e o nome é proposta; (4) `vinculo_atualizado` é o `tipo` de `EvVinculoGanho`; (5) `EvPassoVivo` é emitido pelo orquestrador, não pela Run.
- **Pendências:** campos exatos de `chefe_*` e `troca_feita` a conferir com ADR-0017 e ADR-0010; teste de que nenhum consumidor da Apresentação emite; contagem de eventos por passo no pior caso de Pactos (dupla, chefe e 12 projéteis) entra na medição de alocação.

## Verificação de engine (2026-11-16)

Fonte: Completion Notes em `production/epics/experimentos-de-engine/` e `production/qa/evidence/experimentos/ex-0002-eventos.md`. Editor 4.7.2 (build debug), Windows 11.

- **EX-0002-1 — custo por evento: PARCIAL.** p99 do passo com 20 eventos: 166–198 µs; com 50: 330–482 µs; com 100: até 1,4 ms. Tudo em debug. Os 20 eventos típicos cabem com folga; 50 passa do alvo de 0,3 ms em debug.
  - **Fallback (decidido):** se o p99 **em release** com 50 eventos por passo passar de 0,3 ms, trocar a alocação por evento por pool/reuso de objetos de evento (o `CanalDoPasso` reinicia e reaproveita as instâncias a cada passo; a interface `emitir`/`do_tipo` não muda). Medir em release assim que os templates de export 4.7.2 estiverem instalados.
- **VERIFICADO:** `filter()` sobre `Array[EventoDoPasso]` devolve array tipado no 4.7.2 (texto da Decision corrigido).
- **VERIFICADO, com ressalva:** `@abstract` **não** impede a instanciação via `Script.new()` dinâmico (por exemplo `load(caminho).new()`). Não confiar em `@abstract` como trava: a construção de eventos fica restrita às subclasses concretas, e a revisão de código cobra isso.
- **VERIFICADO:** com `CONNECT_DEFERRED`, os conectados recebem o sinal depois que o emissor retorna, na ordem de conexão. Confirma a lista fixa de assinantes da Apresentação.

## Related
- ADR-0001 (orquestrador do passo; esvazia a lista); ADR-0003 (tipo do alvo `InimigoRef`); ADR-0010, 0011, 0012
- `docs/architecture/architecture.md` (Data Flow, cenário 2; API 9 e 11)
- GDDs: combate-nucleo, feedback-de-combate (R1, R14), hud, telemetria-local, selo-e-fluxo, efeitos-de-status, camaras-e-ondas, portas-e-recompensas, run-e-regioes, bencaos-tradicoes, tela-de-bencao-e-carta, economia-de-fragmentos
