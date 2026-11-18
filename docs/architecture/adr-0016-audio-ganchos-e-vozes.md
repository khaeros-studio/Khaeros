# ADR-0016: Áudio — ganchos, barramentos e pool de vozes

## Status

Accepted · 2026-11-16 (aprovado pelo usuário; Proposed em data do ADR)

> **Quem pode mover para `Accepted`:** o usuário, ou `technical-director` com a confirmação
> explícita do usuário. Nenhum outro agente e nenhuma skill sozinha.

## Date

2026-11-16

## Last Verified

2026-11-17 (experimentos EX-0016-A: itens 1–6 marcados como Confirmados: `get_bus_index` `-1`, `pitch_scale > 0` faixa `0,25–4`, `stream_paused` reportando `playing == false`, `linear_to_db`, `default_bus_layout.tres`, loop WAV `edit/loop_mode=2` com `loop_end=-1` e `mix_rate` do dispositivo `48000 Hz`). Antes: 2026-11-16

## Decision Makers

engine-programmer (rascunho por agente, a pedido do usuário); revisão: usuário e technical-director.
Conteúdo sonoro e mixagem continuam com o audio-director (Feedback OQ 4 e OQ 9).

## Summary

Os GDDs definem ganchos de áudio (nome e prioridade), mas não dizem quem toca os sons, como as
vozes são limitadas nem como o tom dos telégrafos acompanha `p`. Decidido: um nó `AudioDoJogo` na
Apresentação, 5º consumidor da entrega do passo (depois de Telas). Ele recebe os `PedidoDeSom` do
Feedback e das Telas, deduplica por gancho no passo e reparte as vozes de um pool fixo de
`AudioStreamPlayer` por prioridade, com roubo (F4). Um `MixadorDeVozes` puro decide quem toca. Há 4
barramentos (Master, Música, Efeitos, Interface), com volumes em `opcoes.cfg [audio]`, e no máximo
3 tons de telégrafo, com o pitch dado por `p`.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (instalado 4.7.2) |
| **Domain** | Audio |
| **Layer** | Presentation |
| **Knowledge Risk** | LOW para o que a referência confirma (sem mudança de áudio em 4.4–4.6, e as duas de 4.7 não se aplicam aqui); MEDIUM para as APIs marcadas abaixo |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `modules/audio.md`, `breaking-changes.md` (linhas de Audio), `deprecated-apis.md`, `current-best-practices.md` (área de áudio e driver dummy no headless) |
| **Post-Cutoff APIs Used** | Nenhuma. O ADR evita `AudioStreamPlayer2D/3D` (cujo `area_mask` padrão mudou na 4.7) e `AudioEffectSpectrumAnalyzer` (cujo `tap_back_pos` foi removido na 4.7) |
| **Verification Required** | Ver tabela "Confirmação de API" abaixo |

### Confirmação de API

| API | Situação na referência / Experimento | Uso aqui |
|---|---|---|
| `AudioStreamPlayer` (`stream`, `play()`, `playing`, `bus`) | **Confirmada** (`modules/audio.md`, Playing Audio e Pooling) | voz do pool |
| Pool pré-alocado de `AudioStreamPlayer` | **Confirmada** como padrão recomendado (`modules/audio.md`) | pool fixo |
| `AudioServer.get_bus_index`, `set_bus_volume_db`, `set_bus_mute` | **Confirmadas** (`modules/audio.md`, Audio Buses) | volumes e mudo |
| `get_bus_index` devolvendo `-1` para um nome inexistente | **Confirmada (EX-0016-A, 2026-11-16)** (`"Inexistente"` = `-1`, `""` = `-1`) | checagem na partida |
| `AudioStreamPlayer.pitch_scale` | **Confirmada (EX-0016-A, 2026-11-16)** (`pitch_scale > 0`, faixa `0,25–4` medida em tempo real com erro < 3%; `0.0` gera erro e mantém `1.0`) | tom do telégrafo |
| `AudioStreamPlayer.stream_paused` | **Confirmada (EX-0016-A, 2026-11-16)** (congela e retoma da mesma posição; reporta `playing == false` enquanto pausado) | pausa e Bênção |
| `AudioStreamPlayer.volume_db` | **Confirmada (EX-0016-A, 2026-11-16)** (aceita `-inf`, ganho RMS exato) | ganho por voz |
| `linear_to_db()` (@GlobalScope) | **Confirmada (EX-0016-A, 2026-11-16)** (`1.0→0.0`, `0.5→-6.0206`, `0.0→-inf`) | volume linear → dB |
| Layout de barramentos em `res://default_bus_layout.tres` | **Confirmada (EX-0016-A, 2026-11-16)** (carregado por padrão no editor e no `.pck` exportado: 4 buses `Master`, `Musica`, `Efeitos`, `Interface`) | barramentos |
| Loop do stream do tom (flag de import do WAV) | **Confirmada (EX-0016-A, 2026-11-16)** (WAV com `edit/loop_mode=2` Forward e `edit/loop_end=-1` padrão; proibido `loop_end == nº de amostras`) | tom contínuo |
| `AudioStreamPolyphonic` | **NOT SOURCEABLE**, por isso **não é usado** | — |
| Driver de áudio dummy no `--headless` | citado em `current-best-practices.md` | testes de integração sem som |

Os itens 1 a 6 foram **Confirmados (EX-0016-A, 2026-11-16)** no Godot 4.7.2 (driver WASAPI, `mix_rate` do dispositivo `48000 Hz`, ver seção "Verificação de engine (2026-11-16)").

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (estado de jogo, hitstop, final comum do passo), ADR-0002 (lista do passo e ordem de entrega), ADR-0004 (catálogo: `SomDef` e `AudioTuning`), ADR-0012 (Telas, `RelogioDeInterface`, sons de UI só por evento de áudio), ADR-0013 (`opcoes.cfg`), ADR-0014 (`publicar(Array[VistaDeTelegrafo])`) |
| **Enables** | Stories de áudio do Feedback (R9/R10/R18), de Maldições (ML-A1), de Chefes (CH-A1), da Tela de bênção e da deixa sonora da Vida baixa (HUD) |
| **Blocks** | Toda story que toque som. A fatia jogável atual não toca som |
| **Ordering Note** | Pede emendas a três ADRs (seção "Pedidos a outros ADRs"). Sem elas, este ADR não fecha |

## Context

### Problem Statement

O Feedback (R9, F4) define ganchos com prioridade, a regra de um som por gancho por passo e os
limites `vozes_max_gancho` (4) e `vozes_max_total` (16). Os Telégrafos (Visual/Audio) pedem um tom
que sobe com `p`, um estalo no disparo e no máximo 3 telégrafos soando. Maldições (ML-A1), Chefes
(CH-A1), HUD e Tela de bênção acrescentam ganchos. Nenhum ADR diz onde o som é tocado, quem aplica
os limites, como os volumes são guardados nem o que acontece com o som em pausa, hitstop, Bênção e
Transição. O ADR-0002 só registra que "o Áudio recebe ganchos do Feedback", e o ADR-0012 proíbe a
vista de chamar `AudioStreamPlayer` direto.

### Current State

Não há código de áudio em `src/`. O ADR-0002 desenha `Feedback ─► (ganchos) Áudio`, e o ADR-0012
acrescentou `Telas` como 4º consumidor.

### Constraints

- A Apresentação só lê (ADR-0002 §3): o Áudio nunca emite evento nem escreve em estado de jogo.
- Não há `SceneTree.paused` (ADR-0001 §3): o som não para sozinho na pausa, quem para é a nossa lógica.
- O hitstop é contagem de passos e congela o mundo, não o tempo real (ADR-0001, Combate R10).
- Nenhum caminho literal de asset no código: os sons vêm do catálogo (ADR-0004).
- Zero alocação no caminho quente da entrega do passo, a 60 Hz.
- Os testes unitários não tocam som nem fazem I/O.

### Requirements

- Um som por gancho por passo, com limites por gancho e total, e corte por prioridade (F4, AC-FB-21).
- Tom de telégrafo com pitch por `p`, estalo no disparo e teto de 3 tons.
- Volumes por categoria persistidos nas opções.
- Gancho sem som mapeado: silêncio e aviso `FB2`, sem falhar.
- Os ganchos já emitidos tocam até o fim na Transição de câmara (Feedback, Edge Cases).

## Decision

### 1. Onde o Áudio entra na entrega

O `Main` registra a ordem: **Telemetria → HUD → Feedback → Telas → Áudio**. O Áudio é o 5º e
último consumidor. Ele não lê a lista de eventos bruta para decidir sons de combate. A cada passo,
consome:

1. os `PedidoDeSom` que o Feedback devolveu neste passo, ao lado dos `PedidoImpacto`, `PedidoPasse`
   etc. do ADR-0011. O Feedback continua sendo o árbitro de qual evento vira qual gancho e com qual
   prioridade (R3, R10, R15);
2. os `PedidoDeSom` de interface que Telas e `ModeloDoHud` puseram numa `FilaDeSonsDeInterface`
   (RefCounted, injetada, pré-alocada) durante a entrega deles neste passo (cartas, foco,
   confirmação, Fragmentos, deixa da Vida baixa). Isso cumpre o ADR-0012 ("sons de UI por eventos
   de áudio") sem que uma vista toque som;
3. a publicação dos telégrafos (`Array[VistaDeTelegrafo]` do ADR-0014, já preenchido no final
   comum do passo), só por leitura, para os tons.

Ficar por último garante que os pedidos de Feedback e Telas do mesmo passo já existam quando o
Áudio resolve as vozes. Isso dá determinismo: a mesma sequência de passos produz as mesmas
decisões de voz.

### 2. Barramentos

| Barramento | Envia para | Conteúdo | Chave em `opcoes.cfg [audio]` |
|---|---|---|---|
| `Master` | saída | tudo | `master` |
| `Musica` | Master | música (sem conteúdo no MVP; o barramento já fica reservado) | `musica` |
| `Efeitos` | Master | ganchos de combate e mundo, tons e estalos de telégrafo | `efeitos` |
| `Interface` | Master | sons de Telas e HUD | `interface` |

- O layout vive num recurso de barramentos editado no editor (caminho padrão do Godot, NOT
  SOURCEABLE). Na partida, o `AudioDoJogo` resolve os quatro índices uma vez com `get_bus_index`.
  Se faltar algum, ele avisa e usa `Master`.
- Os nomes ficam como `StringName` constantes numa única classe `BarramentosDeAudio`, que não guarda
  caminho de arquivo.
- Volume é `float` linear ∈ [0, 1], padrão 1,0 para `master` e 0,8 para os demais (valores
  provisórios, audio-director). Fora da faixa ou de outro tipo = chave inválida, que volta ao padrão
  (mesma regra do `[ui] escala`). Em 0, o barramento fica mudo (`set_bus_mute`). Acima de 0, o volume
  vira dB com `linear_to_db` e vai para `set_bus_volume_db`.
- Quem lê e grava é o `RepositorioDeOpcoes` (ADR-0013). A tela de opções (ADR-0012) aplica o volume
  na hora e grava ao confirmar, nunca durante `JOGO`.

### 3. Pools fixos, montados na composição

| Pool | Vozes | Barramento | Política |
|---|---|---|---|
| Efeitos (ganchos) | `vozes_max_total` (16) | Efeitos | F4 completa (§4) |
| Tons de telégrafo | `teto_tons_telegrafo` (3) | Efeitos | §5, fora da conta das 16 |
| Interface | `vozes_interface` (4) | Interface | dedupe por gancho no passo; cheio → rouba a mais antiga |
| Música | 2 (crossfade futuro) | Musica | fora do escopo do MVP |

Os `AudioStreamPlayer` (não posicionais) são criados uma vez no `_ready` do `AudioDoJogo` e nunca
mais. Nenhum nó de áudio é criado em runtime.

### 4. `MixadorDeVozes`: dedupe, limites e roubo (F4)

Lógica pura (`RefCounted`), sem nós e sem streams. Ele mantém, por slot, `gancho: StringName`,
`prioridade: int` (0 = P0 … 4 = P4), `ordem: int` (contador monotônico de início) e `ocupado`.
A cada passo:

1. **Liberar:** o nó informa os slots cujo player terminou (`playing == false` **e** `stream_paused == false` — verificado em `EX-0016-A`: uma voz com `stream_paused = true` reporta `playing == false`, portanto o pool nunca pode tratar `playing == false` sozinho como "voz livre" enquanto pausado), consultando os 16
   uma vez por passo, sem sinal `finished`, para manter a decisão síncrona e testável.
2. **Deduplicar:** pedidos com o mesmo gancho no passo viram um só. Fica o de maior prioridade e,
   no empate, o primeiro recebido. O Feedback já faz isso (R9); o Mixador repete a regra como
   salvaguarda, porque Feedback e Telas são fontes distintas.
3. **Ordenar:** os pedidos restantes por prioridade (P0 primeiro). No empate, vale a ordem de
   chegada (ordenação estável, num array de trabalho pré-alocado).
4. **Limite por gancho:** se o gancho já tem `vozes_max_gancho` vozes, o novo derruba a **mais
   antiga desse gancho** quando tem prioridade igual ou maior. Senão, é descartado.
5. **Limite total:** se há slot livre, usa. Senão, a vítima é a voz de **menor prioridade**, a mais
   antiga no empate. Se a vítima tem prioridade menor que a do novo, é roubada. Se a vítima tem
   prioridade igual, também é roubada (a mais antiga cede). Se o novo tem prioridade menor que todas,
   **ele** é descartado. **P0 nunca é roubada:** com as 16 vozes em P0, um P0 novo é descartado e
   conta no contador de diagnóstico `vozes_p0_descartadas`.
6. **Devolver** uma lista fixa de `ComandoDeVoz(slot, gancho, parar_antes)`, que o nó aplica:
   `stop()`, troca o `stream` e `play()`.

O resultado não depende de tempo real, só da sequência de pedidos e das liberações. É isso que
torna o AC-FB-21 testável sem som.

### 5. Tons dos telégrafos

- **Quem soa:** dentre as vistas publicadas no estado de preparação (antes do disparo), as
  `teto_tons_telegrafo` (3) de **maior `p`**. No empate, o menor `seq`. O tom fica ligado ao
  `slot` do telégrafo (chave estável do ADR-0014 §8). Um slot que sai do top 3 tem a voz parada no
  passo, e o que entra começa no passo. Em multidão nunca há mais de 3 tons.
- **Pitch:** `pitch = tom_pitch_min + (tom_pitch_max − tom_pitch_min) · clamp(p, 0, 1)`, aplicado a
  cada passo em `pitch_scale` (`pitch_scale > 0`, faixa validada no `AudioTuning` em `0,25–4`; nunca passar `0`, que gera erro na engine). Padrões provisórios: 1,0 e 2,0 (uma oitava). O stream do tom é um
  laço curto e único (`SomDef` de id `sfx_telegrafo_tom`), importado de WAV com `edit/loop_mode=2` (Forward) e `edit/loop_end=-1` (padrão; nunca usar `loop_end` igual ao nº de amostras, que produz estalo na emenda), com período contendo número inteiro de ciclos e sem presumir `44100 Hz` (o `mix_rate` real é o do dispositivo, ex. `48000 Hz` no WASAPI).
- **Estalo no disparo:** **não** é tom. É o gancho P0 `sfx_telegrafo_disparo` que o Feedback já
  pede (R9) e que entra no pool de Efeitos pela §4. No mesmo passo, a voz de tom daquele slot para.
- **Quebra e cancelamento:** o tom para. Som próprio de quebra só sai se o Feedback pedir um gancho.

### 6. Comportamento por estado

| Situação | Efeitos (ganchos) | Tons | Interface |
|---|---|---|---|
| `JOGO`, passo vivo | normal | normal | normal |
| Hitstop (passo congelado) | as vozes seguem tocando; os pedidos do passo do golpe tocam (o som do impacto **é** o hitstop) | seguem, com o pitch fixo (`p` não avança) | normal |
| `PAUSA` | todas as vozes em `stream_paused = true` e retomam de onde pararam (como as respostas visuais, Feedback Edge Cases) | pausados | toca (menu de pausa) |
| `BENCAO` | pausadas como na pausa | parados (os telégrafos já não estão em preparação) | toca (Tela de bênção) |
| `TRANSICAO` | as vozes já tocando **terminam**; não há pedido novo, porque o mundo não roda | parados no passo em que a publicação esvazia | normal |
| `MORTE` / `MENU` | terminam; o `sfx_jogador_morreu` do passo da morte toca | parados | normal |
| Nova run | `parar_tudo()` e o Mixador zerado | parados | — |

O estado vem do orquestrador por consulta (`estado_de_jogo()`, ADR-0001) na entrega. O Áudio não
usa `t_apres` nem o `RelogioDeInterface`: suas decisões ocorrem na entrega do passo físico, e a
reprodução corre no tempo real do servidor de áudio. Fades futuros, como os de música, devem usar
`t_real()` do `RelogioDeInterface`.

### 7. Sons por catálogo

- Tipo novo `SomDef` no catálogo (ADR-0004), com `id: StringName` = nome do gancho
  (`sfx_acerto_leve`, `sfx_maldicao_ataque`, `chefe_surgimento`…), `caminho_stream: String` (campo
  de texto, como os caminhos de arte), `ganho_db: float` (padrão 0) e `variacoes: Array[String]`
  (opcional; com variação, a escolha é round-robin por gancho, sem RNG de jogo).
- `AudioTuning` (ajuste do catálogo): `vozes_max_gancho`, `vozes_max_total`, `vozes_interface`,
  `teto_tons_telegrafo`, `tom_pitch_min`, `tom_pitch_max`. Os dois primeiros têm o Feedback F4 como
  dono semântico, e os valores são os do GDD.
- Na construção da run, o `AudioDoJogo` resolve todo `SomDef` para `AudioStream` uma única vez e
  monta um `Dictionary[StringName, AudioStream]`. Nada é carregado no caminho quente.
- Um gancho pedido sem `SomDef`, ou com stream que não carrega, gera silêncio e o aviso `FB2`,
  **uma vez por gancho por run**. O jogo segue.
- Recarga do catálogo (ADR-0004): o `AudioDoJogo` entra na lista de consumidores persistentes que
  recebem ajustes vazios ao sair de Pronto. Com ajustes vazios, ele para tudo e fica mudo.

### Architecture Diagram

```
passo_fisico() ─ final comum (ADR-0001) ─ esvaziar() ─► entrega (ordem do Main)
  Telemetria ─► HUD ──┐ ─► Feedback ──────┐ ─► Telas ──┐ ─► AudioDoJogo (Node)
                      │   PedidoDeSom[]   │           │       │ estado_de_jogo() (consulta)
                      └──────► FilaDeSonsDeInterface ◄┘       │ VistaDeTelegrafo[] (leitura)
                                             │                ▼
                                             └───► MixadorDeVozes (RefCounted, puro)
                                                        │ ComandoDeVoz[]
                                                        ▼
                         pool Efeitos(16) · Tons(3) · Interface(4) · Musica(2)  AudioStreamPlayer
                                                        ▼
                         barramentos Efeitos / Interface / Musica ─► Master  (opcoes.cfg [audio])
```

### Key Interfaces

```gdscript
## Pedido de som. Criado pelo Feedback (combate) ou pelas Telas/HUD (interface).
## Ex.: PedidoDeSom.new(&"sfx_acerto_leve", 3, 0)
class_name PedidoDeSom extends RefCounted
var gancho: StringName
var prioridade: int      # 0 = P0 (nunca cortado) … 4 = P4
var player_id: int

## Fila de interface, esvaziada pelo AudioDoJogo no mesmo passo.
## Ex.: fila.pedir(&"sfx_carta_foco", 2, player_id)
class_name FilaDeSonsDeInterface extends RefCounted
func pedir(gancho: StringName, prioridade: int, player_id: int) -> void
func drenar_para(saida: Array[PedidoDeSom]) -> int      # sem alocar; devolve quantos

## Lógica pura de vozes (F4). Testável sem nós.
## Ex.: var m := MixadorDeVozes.new(16, 4); m.liberar(3); var n := m.resolver(pedidos, comandos)
class_name MixadorDeVozes extends RefCounted
func _init(vozes_max_total: int, vozes_max_gancho: int) -> void
func liberar(slot: int) -> void
func resolver(pedidos: Array[PedidoDeSom], saida: Array[ComandoDeVoz]) -> int
func zerar() -> void
func vozes_p0_descartadas() -> int

## Seleção pura dos tons. Ex.: var n := SeletorDeTons.selecionar(vistas, qtd, 3, saida_slots, saida_pitch, tuning)
class_name SeletorDeTons extends RefCounted
static func selecionar(vistas: Array[VistaDeTelegrafo], quantas: int, teto: int,
        slots: PackedInt32Array, pitches: PackedFloat32Array, tuning: AudioTuning) -> int

## Nó da Apresentação. Composto pelo Main e registrado como 5º consumidor.
class_name AudioDoJogo extends Node
func consumir_passo(pedidos_feedback: Array[PedidoDeSom], estado: int,
        vistas: Array[VistaDeTelegrafo], quantas_vistas: int) -> void
func aplicar_volumes(master: float, musica: float, efeitos: float, interface: float) -> void
func parar_tudo() -> void
```

### Implementation Guidelines

- O `AudioDoJogo` **must** criar todos os players no `_ready`, e **must never** instanciar
  `AudioStreamPlayer` depois disso.
- Nenhum código **must** conter caminho literal de som. Todo stream vem de `SomDef` do catálogo.
- Vistas, Telas e HUD **must never** chamar `play()`. Pedem pela `FilaDeSonsDeInterface`.
- O Áudio **must never** emitir evento, escrever em módulo de regra ou guardar `PedidoDeSom` além
  do passo.
- A decisão de voz **must** ficar no `MixadorDeVozes` e no `SeletorDeTons` (puros). O nó só aplica
  comandos.
- A entrega **must not** alocar: arrays de pedidos, comandos, slots e pitches são pré-alocados no
  tamanho máximo, e o dedupe é varredura linear (≤ ~40 pedidos por passo).
- O Áudio **must never** usar `Engine.time_scale` nem `SceneTree.paused` para pausar.

## Alternatives Considered

### Alternativa 1: um `AudioStreamPolyphonic` por barramento
- **Description**: um player com stream polifônico e `max_polyphony`, tocando cada gancho como uma voz.
- **Pros**: menos nós, e o engine faz a mixagem das vozes.
- **Cons**: API ausente da referência (NOT SOURCEABLE). O roubo da engine não segue a F4 (prioridade
  e "a mais antiga do mesmo gancho"), e o pitch por voz para o tom fica incerto.
- **Estimated Effort**: semelhante, mais o protótipo de verificação.
- **Rejection Reason**: a F4 exige controle explícito de quem cai, e o pool é o padrão confirmado.

### Alternativa 2: o Áudio lê a lista de eventos e mapeia sozinho evento → som
- **Description**: consumidor independente, com tabela própria de evento para gancho.
- **Pros**: não depende do Feedback.
- **Cons**: duplica o catálogo de respostas e as prioridades do Feedback (R3, R15), e as duas
  tabelas divergem.
- **Estimated Effort**: maior.
- **Rejection Reason**: o GDD faz do Feedback o dono dos ganchos e prioridades.

### Alternativa 3: o Áudio entre Feedback e Telas
- **Description**: a ordem do ADR-0002 como desenhada, com o Áudio logo após o Feedback.
- **Pros**: não mexe na ordem do ADR-0012.
- **Cons**: os sons de Telas do mesmo passo ficariam para o passo seguinte, ou exigiriam um segundo
  caminho de reprodução.
- **Rejection Reason**: um único ponto de resolução por passo é mais simples e determinístico.

## Consequences

### Positive
- O AC-FB-21 e o teto de 3 tons são testáveis em unidade, sem som.
- Há um só lugar com política de voz e um só caminho para som de UI.
- Os volumes por categoria ficam prontos para a tela de opções.

### Negative
- O Feedback ganha um tipo de pedido a mais (`PedidoDeSom`).
- Telas e HUD ganham a dependência da `FilaDeSonsDeInterface`.
- A consulta de `playing` a cada passo (≤ 25 players) é um custo pequeno, mas fixo.
- O som não é posicional no MVP.

### Neutral
- O barramento Música existe sem conteúdo.
- O co-op ouve todos os `player_id` localmente. O filtro por jogador, se vier, fica no Mixador.

## Risks
- **`pitch_scale` e `stream_paused` com comportamento diferente do esperado na 4.7** (NOT
  SOURCEABLE). *Mitigação:* protótipo V-1. A alternativa para a pausa é `stop()` com
  `get_playback_position()` guardada, e para o tom, 3 streams pré-transpostos.
- **Estalo cortado com 16 vozes P0.** *Mitigação:* o contador `vozes_p0_descartadas` vai na
  telemetria de debug. Se passar de 0 num playtest, o audio-director revê `vozes_max_total`.
- **Tom de laço audível como clique na troca de slot.** *Mitigação:* o audio-director entrega o
  laço com ataque curto.
- **Fonte de verdade dupla do dedupe** (Feedback e Mixador). *Mitigação:* a regra é idêntica, e o
  teste do Mixador cobre os pedidos já deduplicados.

## Performance Implications

- **CPU:** a entrega do áudio é O(pedidos · vozes) ≤ 40 × 16 comparações, mais a ordenação de ≤ 40
  e a seleção top 3 de ≤ `teto_telegrafos` vistas. Alvo: < 0,05 ms por passo. Medir na story, com
  a cena de multidão do Pipeline, antes e depois.
- **Memória:** 25 `AudioStreamPlayer` fixos e os streams do catálogo carregados na construção da run
  (tamanho pelo conteúdo do audio-director). Nenhuma alocação por passo.
- **Carregamento:** a resolução dos `SomDef` é síncrona na construção da run, como o resto do
  catálogo (ADR-0004).

## GDD Requirements Addressed

| GDD | Requisito | Como este ADR atende |
|---|---|---|
| feedback-de-combate.md | **TR-feedback-008** — R9, F4: um som por gancho por passo; limites por gancho (4) e total (16); corte por prioridade, a mais antiga no empate, P0 nunca | §4 `MixadorDeVozes` (dedupe, limite por gancho, limite total, roubo); `AudioTuning` com os valores do GDD |
| feedback-de-combate.md | Edge Cases: Transição (ganchos emitidos tocam), gancho sem som (`FB2`), Pausa/Bênção retomam, área com 5 alvos = 1 som | §6 e §7 |
| feedback-de-combate.md | R18 e ML-A1: ganchos `sfx_maldicao_*` seguem a R9/F4 com as prioridades da R15 | entram como `PedidoDeSom` do Feedback, sem regra especial |
| telegrafos.md | **TR-telegrafos-014** — Visual/Audio: tom que sobe com `p`, estalo no disparo, no máximo 3 telégrafos soando, sem som contínuo em multidão | §5 `SeletorDeTons` (top 3 por `p`, pitch linear em `p`) e estalo pelo gancho P0 `sfx_telegrafo_disparo` |
| chefes.md | CH-A1: ganchos do chefe | `SomDef` por gancho, pedidos pelo Feedback |
| hud.md | Deixa sonora da Vida baixa e som de Fragmentos são do Áudio (OQ 4) | `FilaDeSonsDeInterface`, barramento Interface |
| tela-de-bencao-e-carta.md | Sons de entrada, foco, confirmação e rachadura (OQ 6); um som por carta | `FilaDeSonsDeInterface`; o dedupe por gancho no passo combina com a defasagem de 60–80 ms entre cartas |
| (ADR-0012) | Sons de UI só por evento de áudio, nunca chamados da vista | Implementation Guidelines |

## Validation Criteria

- **V-1 (protótipo de engine, antes da 1ª story):** em `prototypes/`, no Godot 4.7.2, confirmar
  `pitch_scale` em tempo real, `stream_paused` retomando da mesma posição, `get_bus_index` = −1 para
  um nome inexistente, `linear_to_db`, carga do layout de barramentos e laço do stream importado.
  Registrar a saída, como no protótipo do catálogo.
- **V-2 (unidade, Mixador):** os quatro casos do AC-FB-21 (5 alvos → 1 voz; 16 vozes com 3 de P4 +
  P3 → cai a P4 mais antiga; 16 em P0–P1 + P3 → descartado; 5º do mesmo gancho só derruba com
  prioridade ≥), mais "16 em P0 + P0 → descartado e contador = 1".
- **V-3 (unidade, Seletor):** 5 telégrafos em preparação com `p` distintos → os 3 maiores; empate
  de `p` → menor `seq`; `p` = 0 → `tom_pitch_min`; `p` = 1 → `tom_pitch_max`; telégrafo disparado
  → fora da seleção.
- **V-4 (integração, headless com driver dummy):** a entrega na ordem Telemetria → HUD → Feedback →
  Telas → Áudio; pedido de Tela e de Feedback no mesmo passo resolvidos juntos; `PAUSA` pausa e
  retoma os Efeitos e mantém a Interface; gancho sem `SomDef` → um aviso `FB2` por run.
- **V-5 (alocação):** 600 passos de multidão sem crescimento de objetos (monitor de objetos antes e
  depois).
- **V-6 (escuta, playtest):** a observação "nunca mais de 3 tons" e "o estalo sempre audível" fica
  registrada em `production/qa/evidence/`.

## Pedidos a outros ADRs

- **ADR-0002:** a ordem de entrega passa a ser Telemetria → HUD → Feedback → Telas → **Áudio**
  (substitui "o Áudio recebe ganchos do Feedback" e o diagrama).
- **ADR-0011 / Feedback:** o Feedback ganha `PedidoDeSom` entre os pedidos devolvidos por passo.
- **ADR-0012:** Telas e `ModeloDoHud` recebem a `FilaDeSonsDeInterface` por injeção. A tela de
  opções ganha os 4 volumes.
- **ADR-0013:** `opcoes.cfg` ganha a seção `[audio]` (`master`, `musica`, `efeitos`, `interface`,
  `float` ∈ [0, 1]).
- **ADR-0004:** tipos `SomDef` e `AudioTuning`. O `AudioDoJogo` entra entre os consumidores
  persistentes reinjetados na recarga.

## Decisões tomadas pelo agente (a revisar)

1. O Áudio é o **5º consumidor, depois de Telas**, e não fica logo após o Feedback.
2. **Empate no limite total:** um novo com a mesma prioridade da vítima rouba a mais antiga. A F4
   só fixa o caso "a recém-chegada é a de menor prioridade".
3. **16 vozes todas P0 + P0 novo → o novo é descartado** (lido de "P0 nunca"), com contador de
   diagnóstico.
4. **Os tons ficam fora das 16 vozes** (pool próprio de 3), e a Interface também (pool de 4). A F4
   fala de "vozes de combate".
5. "Sem som contínuo em multidão" foi lido como **teto de 3 tons, os de maior `p`**. Não há modo
   pulsado.
6. Pitch **linear em `p`**, de 1,0 a 2,0 (provisório). O volume do tom não varia com `p`.
7. **Hitstop não pausa o som.** O tom congela o pitch. Pausa e Bênção pausam os Efeitos e mantêm a
   Interface.
8. Som **não posicional** (`AudioStreamPlayer`) no MVP.
9. Volumes lineares em `opcoes.cfg [audio]`, padrão 1,0 / 0,8 / 0,8 / 0,8.
10. Variação de som por **round-robin**, sem RNG.

## Verificação de engine (2026-11-16)

Fonte: `production/qa/evidence/experimentos/ex-0016-audio-api.md` (story-009). Godot 4.7.2 standard + `.pck` exportado, driver WASAPI, `mix_rate` do dispositivo `48000 Hz`, Windows 11.

- **Item 1 — `AudioServer.get_bus_index`: Confirmado (EX-0016-A).** `Master=0`, `Musica=1`, `Efeitos=2`, `Interface=3`; `"Inexistente" = -1` e `"" = -1`. Layout carregado automaticamente de `res://default_bus_layout.tres`.
- **Item 2 — `pitch_scale` em tempo real: Confirmado (EX-0016-A).** Altera a frequência da mesma voz em reprodução sem reiniciar; faixa `0,25–4` medida com erro < 3% (`113,0 Hz` a `1762,0 Hz` sobre base `441 Hz`). `pitch_scale = 0.0` emite `ERROR: Condition "p_pitch_scale <= 0.0"` e mantém `1.0`: `AudioTuning` deve validar `pitch_scale > 0` (faixa `0,25–4`) e nunca enviar `0`.
- **Item 3 — `stream_paused`: Confirmado (EX-0016-A).** Pausa e retoma do mesmo ponto (`0,758 s → 1,271 s` após `0,5 s`), mas **reporta `playing == false` enquanto `stream_paused == true`**. O critério de voz livre no pool deve exigir `not player.playing and not player.stream_paused`.
- **Item 4 — `volume_db` / `linear_to_db()`: Confirmado (EX-0016-A).** `linear_to_db(1.0) = 0.0`, `linear_to_db(0.5) = -6.0206`, `linear_to_db(0.0) = -inf` (aceito em `volume_db` com RMS `0.00000`; razão RMS medida `0,5002`).
- **Item 5 — `default_bus_layout.tres` no `.pck` exportado: Confirmado (EX-0016-A).** Quatro barramentos preservados com `send → Master` e `get_bus_index("Inexistente") = -1`. Ferramentas headless que geram o `.tres` devem ser idempotentes, pois `--script` headless também carrega o layout padrão.
- **Item 6 — Loop WAV por import e `mix_rate`: Confirmado (EX-0016-A).** `.import` com `edit/loop_mode=2` (Forward) e `edit/loop_end=-1` (padrão, resultando em `loop_end = n_amostras - 1`) faz loop contínuo sem estalo. **Proibido** definir `loop_end` igual ao nº de amostras (`44100`), o que lê além do fim e gera salto de `0,39–0,66` (estalo). O `mix_rate` real do servidor é o do dispositivo (`48000 Hz` em WASAPI), nunca presumir `44100 Hz`.
