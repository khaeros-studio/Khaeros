# Cena 3/4 e câmera

> **Status**: Approved (2026-11-10: correções de contrato do `/review-all-gdds` 3ª passada — C-B1, camada `contorno de telégrafo` em z 5 e 11 camadas; S-B1, corte da câmera no quadro da metade do wipe, no estado Transição; mantido Approved por decisão do usuário. Antes: re-review de 2026-11-08: APPROVED, 0 bloqueantes, depois dos warnings do `/review-all-gdds` de 2026-11-06 — C-W6 a C-W9, C-I2, C-I3)
> **Author**: usuário + Claude (design-system)
> **Last Updated**: 2026-11-10 (C-B1 e S-B1 do cross-review: R4, R10, AC-09, AC-10, AC-22, OQ1). Antes, 2026-11-08 (re-review: justificativa do hitstop sem `time_scale` corrigida na R7, relógio injetado na R12 e AC-28, caso sem `CameraTuning` em Edge Cases e AC-39). Antes, 2026-11-06: hitstop sem `time_scale`, hitstop como referência ao `CombatTuning`, `unit_to_px` só na importação, OQ8 fechada
> **Last Verified**: 2026-11-08
> **Implements Pillar**: P3 *Reflexo que se lê* (arena e telégrafos sempre legíveis)
> **Creative Director Review (CD-GDD-ALIGN)**: pulada (modo Lean)

> **Nota (2026-11-11, Feedback de combate):** pendente: F5 aceita `escala` como entrada do impulso; a regra de um impulso por passo é do Feedback (a Cena soma o que recebe).

> **Nota (2026-11-11, revisão cruzada):** (Resolvidos em 2026-11-12: Dependencies atualizadas para os GDDs existentes; R7, F3, R12 e Edge Cases no `t_apres`; ACs 26–30 e novo AC-30b; AC-19 e AC-37 corrigidos; R8 e F5 com `escala`, "zoom principal", `dir` nulo, `t_apres`, remetente único; estados Bênção/Morte/Transição.)

## Summary

**Cena 3/4 e câmera** define o espaço do jogo: viewport lógico de 1920×1080 com
`keep_height` (personagem a ~1/12 da altura), 1 unidade do cânone = 1,5 px,
plano de jogo igual à tela e profundidade por y-sort em 11 camadas de render
(as 9 do Art Bible; o telégrafo em duas). A câmera segue o jogador com limites, olha um pouco para
onde se mira e recebe impulsos
de impacto (chute, tremor, zoom ≤ 1,15) escalados pela acessibilidade. A mira do
mouse nunca treme com a tela.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `Conteúdo orientado a dados (suave)`, `Input e controle (suave, por contrato; lookahead)`

## Overview

**Cena 3/4 e câmera** define o espaço onde o jogo acontece e como ele é visto. O
**viewport lógico é 1920×1080** (Art Bible §8.6), com `keep_height`: o
personagem ocupa sempre ~1/12 da altura da tela (90 ± 5 px na vista lógica), e
telas mais largas mostram mais largura (sangria ≥ 370 px por lado; pillarbox
acima de 43:18). A unidade do
cânone vale **1,5 px de mundo**, então a arena canônica de 1280×720 vira
exatamente uma tela.

O **plano de jogo é o plano da tela**: colisão, alcance e telégrafo vivem em px
de mundo, sem compressão vertical, como no cânone. O "3/4" é da arte: chão
pintado em perspectiva, sprites de frente-3/4 e **profundidade por y-sort** (quem
está mais abaixo na tela é desenhado na frente).

A cena é desenhada em **11 camadas de render**, que implementam as 9 camadas de
arte do Art Bible §6.3: objetos e personagens dividem o y-sort, o telégrafo se
divide em preenchimento e contorno (Pipeline visual R5), e sombras de contato e
pós vêm do §8.6. A ordem z e o fator de parallax de cada camada são
fixos (R4).

A **câmera segue o jogador com limites**: ela anda suavemente, mas nunca mostra
fora da câmara. Uma câmara do tamanho da tela fica com a câmera parada. A câmera
também recebe os **impulsos de impacto** (chute direcional, tremor, zoom ≤
1,15), sempre escalados pela opção de tremor da acessibilidade.

O jogador não pensa neste sistema, mas sente o efeito: a arena inteira, ou
quase, legível de relance, quem está na frente de quem sempre claro, e o golpe
que "empurra" a tela.

Sem este sistema, cada cena teria sua escala, a profundidade quebraria (inimigo
desenhado atrás de uma coluna que está atrás dele) e a mira do mouse erraria o
mundo.

> **→ vira ADR:** estrutura de nós (CanvasLayers, `y_sort_enabled`, Camera2D ou
> câmera própria, Parallax2D), as chaves do `project.godot`, a troca de aspecto
> acima de 43:18 (R1) e a âncora do parallax no centro da câmara (R4).

## Detailed Design

### Core Rules

> `game-designer`, `ux-designer` e `gameplay-programmer` não foram consultados:
> modo Lean. Revisar manualmente antes de produção.

**R1. Escala e janela.**

- Viewport lógico **1920×1080**. Stretch `canvas_items`, aspect `keep_height`,
  scale `fractional`, com as chaves explícitas no `project.godot`, porque o 4.7
  mudou os padrões.
- A janela padrão é 1280×720 (`commands.run`) e renderiza na resolução nativa
  da janela.
- Ultrawide mostra mais largura, até **43:18** (W ≤ 2580, cobre 2560×1080 e
  3440×1440); acima disso, pillarbox.
- O `keep_height` do Godot não tem limite de largura, então as chaves sozinhas
  não fazem o pillarbox. Ele é uma troca em tempo de execução no `size_changed`:
  acima de 43:18, `content_scale_aspect` = `keep` com `content_scale_size` =
  2580×1080; abaixo, volta ao `keep_height` com 1920×1080. As propriedades
  existem no 4.7.2 instalado; o mecanismo final é do ADR.
- Abaixo de 16:9 (16:10, 4:3), letterbox: a largura visível nunca fica abaixo de
  1920.

**R2. Unidade.** 1 unidade do cânone = **1,5 px de mundo** (`unit_to_px`). Todo
valor espacial do jogo está em px de mundo. A conversão acontece **uma vez, na
importação** (Conteúdo F4): o dado gravado já está em px, e nenhum sistema em
jogo multiplica por `unit_to_px` de novo.

**R3. Plano de jogo = tela.**

- Posição (x, y) em px de mundo, com y crescendo para baixo. Círculos de
  colisão, alcance e telégrafo são círculos na tela.
- Não existe eixo de altura no jogo. Um "voo" (projétil, salto visual) é só um
  **deslocamento visual**; a colisão fica na posição de chão.

**R4. Camadas.** A tabela abaixo é a **lista canônica** de camadas de render.
Ela implementa as 9 camadas de arte do Art Bible §6.3: objetos (5) e personagens
(6) dividem a camada de y-sort, o telégrafo (7) é desenhado em duas passadas
(preenchimento e contorno; Pipeline visual R5), e sombras de contato e pós vêm
do §8.6. Toda
coisa visível pertence a **exatamente uma** camada desta tabela. O código de
jogo escolhe a camada pelo nome e nunca mexe em `z_index` nem no parallax
diretamente.

| Camada | Art Bible §6.3 | z | Parallax p |
|---|---|---|---|
| fundo | 1 | −30 ¹ | 1,0 ² |
| névoa distante | 2 | −25 ¹ | 1,0 ² |
| parede traseira | 3 | −20 ¹ | 1,0 |
| chão | 4 | −10 | 1,0 |
| sombras de contato | — (§8.6) | −6 | 1,0 |
| telégrafo (preenchimento) | 7 | −5 | 1,0 |
| objetos + personagens (y-sort) | 5 e 6 | 0 | 1,0 |
| contorno de telégrafo | 7 (duas passadas; Pipeline R5) | 5 | 1,0 |
| primeiro plano e névoa frontal | 8 | 10 | 1,1–1,2 (§8.6); valor no `CameraTuning` |
| pós | — (§8.6) | 50 | presa à tela |
| UI | 9 | 100 | presa à tela |

¹ z proposto por este GDD: o §8.6 só ordena do chão para cima; a ordem segue o
§6.3. ² 1,0 até o Pipeline visual decidir um parallax de fundo; se ficar
diferente de 1, vale a F7.

- **Parallax p:** a camada anda p px na tela por px que a câmera anda. Com a
  câmera no centro da câmara, toda camada coincide com o mundo. Só camadas com
  p = 1,0 estão em px de mundo: colisão, telégrafo e y-sort ficam todos nelas.
- Uma camada com p ≠ 1 **deriva** em relação ao mundo pela F7. O primeiro plano
  (p > 1) é posto fora do jogável por pelo menos essa deriva, para nunca cobrir
  a área jogável (Art Bible §3.4). Uma camada opaca com p < 1 cobre jogável +
  sangria + deriva.
- **Âncora do parallax:** o `Parallax2D` do 4.7.2 desloca a camada pelo scroll
  do `Camera2D` (`screen_offset`), e por isso coincide com o mundo quando esse
  offset é zero, não no centro da câmara. Para valer a F7, a camada recebe o
  deslocamento à mão: `ignore_camera_scroll` ligado e `screen_offset` calculado
  a partir de `câmera_final` e do centro da câmara, ou um `scroll_offset` por
  câmara, refeito no corte (R10). Isso vale também com a câmera própria da R9.
  Os três membros existem no 4.7.2; o mecanismo é do ADR.

> **Telégrafo em duas passadas** (decisão do usuário, 2026-11-10; Pipeline visual
> R5): o **preenchimento** fica em z −5, abaixo do y-sort, e o corpo dos
> personagens o cobre (Art Bible §8.6); o **contorno** fica em z 5, acima do
> y-sort e abaixo do primeiro plano, a 100%, e nunca some atrás de um corpo
> (§6.3). Isso resolve a contradição entre o §6.3 e o §8.6 (OQ1 fechada); a
> emenda do Art Bible fica com o art-director (Pipeline visual OQ4).

**R5. Y-sort.**

- Nas camadas de objetos e personagens, a ordem segue o **y do pé**: o ponto de
  apoio, que é o centro da sombra de contato.
- Em empate de y, vale a ordem de criação (spawn), que é estável.
- Objetos grandes (Anomalia Maior, ~6× a largura do jogador) usam o centro da
  base.
- Um projétil ordena pela posição da sua sombra no chão; o deslocamento visual
  não muda a ordem.

**R6. Câmara.**

- Retângulo **jogável** entre **1920×1080 e 2880×1620** (1,5 tela por eixo).
- **Sangria de arte** além do jogável: ≥ 370 px nas laterais (330 visíveis em
  43:18 + 40 do chute), para o ultrawide e o chute, e ≥ 40 px em cima e embaixo,
  para o chute e o tremor nunca mostrarem vazio. O lookahead não pede sangria:
  o alvo é preso (F4) antes da suavização.
- A sangria vale para as camadas com p = 1,0. Camadas com parallax seguem a F7
  (R4).
- Os limites são dados (`CameraTuning`). O tamanho de cada câmara é dado do GDD
  de Câmaras e ondas.

**R7. Câmera segue com limites.**

- Alvo = posição do jogador + **lookahead** na direção da mira, de até 120 px,
  escalado pela distância do cursor (mouse) ou pela inclinação (analógico) (F2).
- **P é a posição de render do jogador**, interpolada entre os dois últimos
  passos de física: `P = lerp(P_anterior, P_atual, f_i)`, com
  `f_i = Engine.get_physics_interpolation_fraction()`. A câmera roda a cada
  quadro de render (`_process`), e a interpolação de física do projeto
  (`physics/common/physics_interpolation`) fica ligada, para os sprites usarem a
  mesma posição. Num teleporte (spawn, corte da R10), P_anterior = P_atual e o
  nó chama `reset_physics_interpolation()`. As três APIs existem no 4.7.2
  instalado.
- O nó da câmera fica com `physics_interpolation_mode` = `OFF`. Ele já calcula
  o próprio P e anda em `_process`. No 4.7.2 o `Camera2D` não sobrescreve o
  padrão `INHERIT`, então, com a interpolação do projeto ligada, o motor o
  interpolaria de novo entre passos e os degraus voltariam. (O `Parallax2D` já
  vem com `OFF`.)
- O **relógio da câmera** (Δt da F3 e idade dos impulsos da F5) é o `t_apres`
  do Pipeline F8 (com `dt_max_apres`), não `Time.get_ticks_usec()`: não é
  escalado por `Engine.time_scale` e fica parado em Pausa e Bênção. Assim a
  câmera não depende de como o hitstop é feito.
- **O hitstop não usa `Engine.time_scale`.** Ele é um contador de passos do
  Combate núcleo: a física continua rodando a 60 passos/s e os sistemas vivos
  pulam o passo enquanto o contador não zera. O Input amostra e guarda o buffer
  durante o hitstop (Input R6, F3), e Modificadores conta durações em passos
  vivos (Modificadores R6). Com `time_scale`, os passos de física continuam a
  60/s, só que com `delta` escalado: no 4.7.2, `time_scale` = 0 dá passos com
  `delta` = 0 (conferido no motor instalado em 2026-11-08). Assim os contadores
  de passo contariam o hitstop como passo vivo, e um `time_scale` fracionário
  quebraria o passo fixo de 1/60 que as durações em passos supõem. O contador do
  Combate é a única definição de "passo vivo". Isto é requisito para o GDD de
  Combate núcleo (cross-review 2026-11-06, C-W7, decisão do usuário).
- A câmera persegue o alvo com suavização exponencial (Formulas) e é presa para
  que a vista nunca saia do jogável + sangria.
- Numa câmara do tamanho da tela, a câmera fica parada no centro.

**R8. Impulsos de câmera** (apresentação, em `src/presentation/`).

- O **Feedback de combate envia** (remetente único, um impulso por passo:
  Combate → Feedback → Cena) impulsos com intensidade: **chute** direcional (desloca
  na direção do golpe e decai), **tremor** (oscila e decai) e **zoom** (decai).
  O impulso aceita `escala` como entrada (F5) e o preset "zoom principal"; `dir`
  nulo vale (sem direção: sobram tremor e zoom).
  O teto de 1,15 vale para o zoom **total**, impulsos mais intro de chefe (F5).
- Chute e tremor são multiplicados pela opção **Tremor de câmera** (0–100%).
- Com **Redução de movimento** ligada, zoom e lookahead ficam desligados.
- Os impulsos correm em **tempo de apresentação** (`t_apres`), não congelam no hitstop: o "soco" é
  visto durante o congelamento. O relógio é o `t_apres` do Pipeline F8 (com
  `dt_max_apres`), não `ticks_usec`: fica parado em Pausa e Bênção. Ao entrar em
  Bênção a câmera zera os impulsos, como na Pausa.
- O tremor usa o gerador cosmético (permitido pela R1 do RNG).

**R9. Conversão tela → mundo.** É a consulta que o Input usa (R5 do Input). Usa
a câmera **base**, seguida e com lookahead, **sem** chute, tremor nem zoom de
impacto: a mira do mouse nunca treme junto com a tela. A câmera guarda **duas**
posições suavizadas (F3): `pos_seguir`, com alvo = jogador, e `pos`, com alvo =
jogador + lookahead. Para calcular a direção do lookahead (F2) usa-se
`pos_seguir`, o que evita o laço "a mira move a câmera, que move a mira". A conversão é própria: o `Camera2D` nativo e
`get_global_mouse_position()` incluiriam os impulsos.

**Instantâneo da mira.** São dois relógios, e cada consulta tem a sua regra:

- **Input (passo de física):** o ponto do cursor no mundo usa a `pos` do
  **último quadro de render**, que é a tela que o jogador viu sob o cursor. O
  vetor da mira parte da posição de física do jogador (`P_atual`), não do P
  interpolado, porque é dali que o golpe sai.
- **Câmera (quadro de render):** o lookahead da F2 usa o P interpolado e
  `pos_seguir` do quadro atual.
- A diferença entre o personagem desenhado e a origem da mira é de no máximo
  um passo de movimento (33 px na Investida) e é aceita: ela some no passo
  seguinte e não muda a direção para um cursor a mais de algumas dezenas de px.

**R10. Troca de câmara.** A troca acontece no estado de jogo **Transição**
(Combate núcleo R1). A câmera **corta** direto para a posição-alvo da câmara
nova, sem deslizar, no **quadro da metade do wipe** de tinta (o primeiro com
`progresso_wipe` ≥ 0,5; Pipeline visual R7, F8): é o mesmo quadro em que o jogador é teleportado e a câmara nova começa
(estado Corte, que zera os impulsos). Antes desse quadro a câmera mostra a
câmara velha parada; depois dele, a nova. A transição visual (wipe) é do
Pipeline visual.

**R11. Dados.** Ficam num `CameraTuning`: suavização, lookahead máximo, raio de
lookahead do mouse (`R_mouse`), limites de tamanho de câmara, parâmetros de
chute, tremor e zoom, teto do zoom (1,15) e parallax por camada.

**R12. Injeção.** A câmera expõe "tela → mundo" e recebe impulsos por interface.
O relógio de apresentação da R7 (`t_apres`, Pipeline F8) também é injetado, assim
como o `CameraTuning` (Conteúdo). Os testes injetam câmera falsa, impulsos
roteirizados e relógio roteirizado.

### States and Transitions

| Estado | Significado | Entra quando | Sai para |
|---|---|---|---|
| Seguindo | Persegue o alvo; impulsos ativos | Começo da câmara, fim da pausa | Corte, Pausa, Bênção, Morte, Transição, Intro de chefe |
| Corte | 1 quadro: posiciona direto no alvo e zera os impulsos | Troca de câmara | Seguindo |
| Pausa | Câmera parada; impulsos zerados | Pausa do jogo | Seguindo (ou Bênção, se a Pausa abriu por cima da Bênção: a câmera fica parada) |
| Bênção | Câmera parada; impulsos zerados (`t_apres` parado) | Tela de Bênção abre | Seguindo |
| Morte | Impulsos zerados | Morte do jogador | (fim da run) |
| Transição | Impulsos zerados | Transição de câmara | Corte / Seguindo |
| Intro de chefe (fatia vertical) | Enquadramento e zoom ≤ 1,15 comandados pelo GDD de Chefes; o jogador não controla. Impulsos permitidos; o teto de 1,15 vale para o zoom total (F5); com Redução de movimento, o zoom da intro fica desligado | O chefe entra | Seguindo |

O hitstop **não** é estado da câmera: ela continua seguindo (o jogador está
parado) e os impulsos correm no tempo de apresentação (`t_apres`, que corre no
hitstop e para em Pausa e Bênção).

### Interactions with Other Systems

| Sistema | Recebe daqui | Fornece para cá | Dono da interface |
|---|---|---|---|
| Input e controle | conversão tela → mundo (R9) | `fonte_mira` e `intensidade_mira` (amostra, Input R2) e consulta de cursor no quadro de render (Input R5), para o lookahead (F2) | este GDD (conversão), Input (amostra e consulta) |
| Pipeline visual | camadas e ordem z (R4); viewport e stretch | shaders por camada, transição entre câmaras | este GDD (camadas), Pipeline (como desenha) |
| Movimento e esquiva | plano de jogo em px (R3), limites da câmara | posição do jogador (alvo) | este GDD |
| Combate núcleo | requisito: hitstop como contador de passos, sem `Engine.time_scale` (R7) | valores de hitstop (`CombatTuning`); não envia impulsos | Combate (hitstop) |
| Feedback de combate (VFX) | formato do impulso (R8) | impulsos de câmera (chute, tremor, zoom); é o remetente único | este GDD (formato do impulso) |
| Câmaras e ondas / Run e regiões | limites de tamanho (R6) | retângulo jogável e sangria de cada câmara; evento de troca | Câmaras |
| Telégrafos | camadas e z (R4: preenchimento em z −5, contorno em z 5; Pipeline visual R5) | — | Pipeline visual / Telégrafos |
| Acessibilidade e opções | — | Tremor de câmera (0–100%), Redução de movimento | Acessibilidade |
| Conteúdo orientado a dados | — | `CameraTuning` (injetado a cada entrada em Pronto e retirado ao sair dele, Conteúdo Edge Cases › Recarga); valores espaciais já em px (`unit_to_px` = 1,5, aplicado só na importação, Conteúdo F4) | este GDD (`CameraTuning`), Conteúdo (`unit_to_px`) |
| Chefes (fatia vertical) | estado Intro de chefe | enquadramento da intro | Chefes |

## Formulas

> Proposta do `systems-designer` (consultado: modo Lean, seção de risco alto).
> Exemplos recalculados em Python em 2026-11-05. Os valores do F5 são
> placeholders: o cânone (§55.3) não traz números. Escolhas de laço da mira,
> margem vertical, letterbox e limite 43:18: usuário, 2026-11-05. "Passos" neste
> GDD são passos de física (60/s, `tick_rate`). As chaves de stretch foram
> conferidas no Godot 4.7.2 instalado (`scale_mode` aceita
> `fractional`/`integer`; `aspect` aceita `keep_height`). Revisão de
> 2026-11-05 (usuário, após `/design-review`): lookahead escalado pela distância
> do cursor (F2), `P` interpolado e relógio de apresentação (`t_apres`, R7), teto conjunto do zoom (F5)
> e deriva do parallax (F7, nova). Re-review de 2026-11-05 (APPROVED; aplicado
> a pedido do usuário): interpolação OFF no nó da câmera (R7), âncora do
> parallax (R4), validação cruzada do tamanho de câmara (Edge Cases, OQ 9) e
> instantâneo da mira (R9).

### F1. Unidade do cânone → px de mundo

Esta fórmula **é a F4 do Conteúdo** (`d_px = d_u × UNIT_TO_PX`), repetida aqui
só para leitura. Ela roda **só no script de importação** do cânone; o jogo lê o
valor já em px e não converte de novo. O dono da constante é o GDD de Conteúdo
(registro: `unit_to_px`, `source: design/gdd/conteudo-orientado-a-dados.md`); este GDD só escolheu o valor 1,5
(R1, viewport de 1920×1080).

`px_mundo = u × unit_to_px`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| u | float | ≥ 0 | cânone | valor no cânone (unidades), lido pelo script de importação |
| unit_to_px | float | 1,5 | constante do script de importação (Conteúdo F4; registro) | px de mundo por unidade |
| px_mundo | float | ≥ 0 | calculated | valor gravado no `.tres`, em px de mundo |

**Output Range:** linear, sem limite.
**Example:** a arena de 1280×720 vira 1920×1080 (uma tela exata), e o raio do
jogador, 18, vira 27 px.

### F2. Alvo da câmera (com lookahead)

The camera_target formula is defined as:

`alvo = P + lookahead_ligado × normaliza(m) × L × a`, com
`normaliza(0, 0) = (0, 0)`

`a = min(1, |m| / R_mouse)` no mouse; `a` = módulo do analógico direito depois
da zona morta (F2 do Input); `a = 0` com a mira automática do gamepad.

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| P | vec2 | dentro da câmara | calculated | posição de render do jogador (R7) |
| m | vec2 | qualquer | calculated | mouse: vetor do jogador até o cursor, convertido com `pos_seguir` (câmera **sem** lookahead; quebra o laço); analógico: vetor do analógico |
| L | float | 0 – 120 px | data file (`CameraTuning`) | lookahead máximo, 120 |
| R_mouse | float | 240 – 960 px | data file (`CameraTuning`) | distância do cursor que dá o lookahead cheio, 480 (placeholder, playtest) |
| a | float | 0 – 1 | calculated | intensidade do lookahead |
| lookahead_ligado | bool | 0 ou 1 | data file (opção) | 0 com Redução de movimento |

**Output Range:** |alvo − P| ≤ L; mira nula → sem lookahead. No mouse, o
lookahead cresce com a distância do cursor até R_mouse, então um cursor que
passa por cima do personagem não faz o alvo saltar. No analógico, módulo 0,5 →
60 px. Com a mira automática, 0.
**Example:** P = (1000, 600).

- Cursor a (300, 400) do jogador: |m| = 500, a = 1 → direção (0,6; 0,8) → alvo
  (1072, 696).
- Cursor a (60, 80): |m| = 100, a = 100/480 → 25 px → alvo (1015, 620).
- Com Redução de movimento: (1000, 600).

### F3. Suavização (independente da taxa de quadros)

The camera_smoothing formula is defined as:

`k = ln 2 / h ; pos ← pos + (alvo_preso − pos) × (1 − e^(−k·Δt))`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| h | float | 0,08 – 0,25 s | data file | meia-vida, 0,12 s |
| k | float | ≈ 2,8 – 8,7 s⁻¹ | calculated | taxa; h = 0,12 → k ≈ 5,78 |
| Δt | float | > 0 s | calculated | tempo de apresentação do quadro de render: diferença de `t_apres` (Pipeline F8, limitada por `dt_max_apres`; parado em Pausa e Bênção; R7). No quadro em que o Pipeline zera o `t_apres` (metade do wipe) a diferença não é usada. |
| alvo_preso | vec2 | dentro do F4 | calculated | alvo já preso aos limites |
| pos | vec2 | dentro do F4 | calculated | centro da câmera base |

**Output Range:** o fator fica em [0, 1) para qualquer Δt, então não há
overshoot. A ordem é F2 → F4 (no alvo) → F3, e `pos` nunca sai dos limites. No
corte (R10), `pos = alvo_preso`.
**Example:** fração que ainda falta = 2^(−t/h): 0,1 s → 56,1%; 0,12 s → 50%;
0,24 s → 25%; 0,25 s → 23,6%. Duas fatias de 0,05 s dão o mesmo que uma de
0,1 s.

### F4. Prender a vista aos limites

The camera_clamp formula is defined as:

`e = clamp((W − 1920) / 2, 0, b)`

`cx = (x1 − x0 + 2e ≤ W) ? (x0 + x1)/2 : clamp(ax, x0 − e + W/2, x1 + e − W/2)`

`cy = (y1 − y0 ≤ 1080) ? (y0 + y1)/2 : clamp(ay, y0 + 540, y1 − 540)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| x0, x1, y0, y1 | float | jogável de 1920×1080 a 2880×1620 | data file (Câmaras) | retângulo jogável |
| b | float | ≥ 370 | data file | sangria lateral de arte |
| W | float | 1920 – 2580 | calculated | largura visível (16:9 → 1920; 2560×1080 → 2560; 43:18 ou mais → 2580; abaixo de 16:9, letterbox → 1920) |
| e | float | 0 – b | calculated | sangria que de fato aparece |
| (ax, ay) | vec2 | qualquer | calculated | alvo do F2 |

**Output Range:** um eixo que cabe na vista fica centralizado. A sangria lateral
só aparece no excesso de largura além de 16:9, para que uma câmara de uma tela
fique parada em 16:9.
**Example:**

- 16:9, câmara 1920×1080 com x0 = 0 → cx = 960 e cy = 540 (parada).
- 21:9, mesma câmara → e = 300, cx = 960; a vista vai de x = −300 a 2220.
- 16:9, câmara de 2880 de largura, ax = 100 → cx = 960 (preso).

### F5. Impulsos (chute, tremor, zoom)

The camera_impulse formula is defined as:

`d_i = 2^(−t_i / h_i)`

`desloc = limita(s_t × Σ_i (dir_i × Ak_i × d_i + ruído_i × As_i × d_i), 40)`

`zoom = min(1,15; 1 + (1 − rm) × Σ_i Z_i × d_i)`

(Entrada do impulso: preset, `escala` e `dir`; a `escala` multiplica Ak, As e Z do preset. `dir` nulo vale: o termo do chute some. Preset "zoom principal" aceito, usado pelo Feedback na `recusou_morte`. O relógio de `t_i` é o `t_apres` do Pipeline F8.)

`zoom_total = min(1,15; zoom_intro × zoom)`

`câmera_final = pos + desloc`, com escala `zoom_total`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| t_i | float | ≥ 0 s | calculated | idade do impulso em tempo de apresentação (`t_apres`: corre no hitstop, para em Pausa e Bênção) |
| h_i | float | 0,05 – 0,30 s | data file | meia-vida do preset |
| Ak_i / As_i | float | 0 – 32 / 0 – 14 px | data file | amplitude do chute / do tremor |
| Z_i | float | 0 – 0,10 | data file | zoom extra |
| dir_i | vec2 | unitário | calculated | direção do golpe |
| ruído_i | vec2 | cada eixo em [−1, 1] | calculated | gerador cosmético |
| s_t | float | 0 – 1 | data file (opção) | Tremor de câmera |
| rm | int | 0 ou 1 | data file (opção) | Redução de movimento |
| zoom_intro | float | 1 – 1,15 | calculated (Chefes) | zoom comandado na Intro de chefe; 1 fora dela e com rm = 1 |

**Output Range:** |desloc| ≤ 40 px; `limita` encurta o vetor e mantém a
direção. O zoom total fica entre 1 e 1,15, qualquer que seja a soma de intro e
impulsos; zoom > 1 aproxima, com pivô no centro da vista. O ruído do tremor é sorteado a cada quadro de render, uniforme em
[−1, 1] por eixo. Um impulso é descartado quando d_i < 0,05.
Valores iniciais (placeholders, playtest):

| Preset | Hitstop (referência, `CombatTuning`) | h | Ak | As | Z |
|---|---|---|---|---|---|
| leve | 3 passos (`HITSTOP_LIGHT`) | 0,05 s | 10 px | 3 px | 0,02 |
| pesado | 6 passos (`HITSTOP_HEAVY`) | 0,10 s | 20 px | 8 px | 0,04 |
| chefe | 36 passos (`HITSTOP_BOSS_KILL`, só a morte do chefe) | 0,30 s | 32 px | 14 px | 0,10 |

A coluna Hitstop **não é dado deste GDD**. Os valores são do `CombatTuning`
(dono: Combate núcleo; Conteúdo R1) e estão aqui só para ler a meia-vida ao lado
do congelamento. O cânone (`engine.ts:63–67`) também tem KILL 4 e HURT 6, sem
preset de câmera próprio. Se o Combate mudar um valor, esta tabela segue o
`CombatTuning`. Esta Cena é dona só de h, Ak, As e Z (`CameraTuning`).

**Example:**

- Pesado em t = 0,1 s, dir (1, 0), s_t = 0,5, ruído (0,5; −1) → d = 0,5 →
  (10 + 2, −4) × 0,5 = (6, −2), com módulo ≈ 6,32 px.
- Dois impulsos de chefe em t = 0 → 64 px, limitado a 40 (só teste do teto: em jogo o Feedback manda um impulso por passo).
- Chefe em t = 0,6 s → zoom 1,025. Com rm = 1 → zoom 1.
- Intro de chefe com zoom_intro 1,10 e um pesado em t = 0 (zoom 1,04) →
  zoom_total 1,144. Com zoom_intro 1,15 → 1,196, limitado a 1,15.

### F6. Tela → mundo (câmera base)

The screen_to_world formula is defined as:

`mundo = C + (m_lógico − (W/2, 540))`, com
`m_lógico = (m_janela − origem_viewport) / f` e `f = altura_janela / 1080` (ou
`largura_janela / 1920` com letterbox)

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| C | vec2 | dentro do F4 | calculated | `pos` do F3, sem impulsos (para o lookahead do F2: a mesma câmera sem lookahead) |
| m_janela | vec2 | px da janela | calculated | posição do mouse |
| origem_viewport | vec2 | ≥ 0 | calculated | deslocamento das faixas (pillarbox ou letterbox) |
| f | float | > 0 | calculated | px de janela por px lógico |

**Output Range:** sem limite. Um mouse sobre as faixas fica preso à borda da
vista.
**Example:** janela 1280×720 → f = 2/3; mouse em (960, 180) → m_lógico
(1440, 270); com C = (1500, 800) → mundo (1980, 530).

### F7. Deriva de uma camada com parallax

The parallax_drift formula is defined as:

`deriva_x = |1 − p| × ((Lx − 1920) / 2 + 40)`

`deriva_y = |1 − p| × ((Ly − 1080) / 2 + 40)`

`desloc_camada = (1 − p) × (câmera_final − centro_da_câmara)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| p | float | 1,0 – 1,2 (fundo: a definir pelo Pipeline) | data file (`CameraTuning`) | parallax da camada (R4) |
| Lx, Ly | float | 1920 – 2880 / 1080 – 1620 | data file (Câmaras) | tamanho do jogável |
| 40 | float | 40 px | teto do F5 | chute e tremor máximos |
| deriva_x, deriva_y | float | ≥ 0 | calculated | quanto a camada pode se afastar do mundo, por lado |
| desloc_camada | vec2 | ± deriva | calculated | deslocamento da camada em relação ao mundo |

**Output Range:** 0 com p = 1 ou com a câmera no centro da câmara. O termo
`(L − tela) / 2` é a meia excursão da câmera presa pelo F4 (a sangria visível do
ultrawide não muda essa excursão), e o 40 é o chute máximo. O primeiro plano
fica fora do jogável por pelo menos a deriva; uma camada opaca com p < 1 cobre
jogável + sangria + deriva.
**Example:**

- p = 1,2, câmara de 2880×1620 → deriva (104, 62) px.
- p = 1,2, câmara de 1920×1080 → deriva (8, 8): só o chute.
- p = 1,2, câmara de 2880, câmera parada em cx = centro + 480 → a camada está
  96 px à esquerda do mundo.
- p = 1,0 → (0, 0).

## Edge Cases

> `systems-designer` não consultado nesta seção: modo Lean. Os pontos de atenção
> que ele levantou em Formulas estão incorporados.

**Janela e escala**

- **Se a janela for redimensionada, ou alternar tela cheia, durante o jogo:** W,
  f e as faixas são recalculados no mesmo quadro. A câmera é presa de novo (F4)
  **na hora**, sem suavização, para nunca mostrar vazio.
- **Se a proporção passar de 43:18** (32:9): pillarbox, com W = 2580.
- **Se a proporção for abaixo de 16:9:** letterbox, com W = 1920 (R1).
- **Se a janela for muito pequena** (640×360): o jogo funciona com f = 1/3. A
  legibilidade da UI fica com a Escala de UI (Acessibilidade).

**Câmara**

- **Se uma câmara vier com jogável menor que 1920×1080 ou maior que o limite do
  `CameraTuning`:** é erro de validação cruzada (tamanho da câmara × limites do
  `CameraTuning`), e o jogo não inicia: mostra a tela de erros do catálogo (GDD
  de Conteúdo). O V2 do Conteúdo não cobre esse caso: ele confere faixas e
  regras dentro de uma classe, e o catálogo ainda não tem classe de câmara. A
  regra fica com o GDD de Câmaras, que define o dado da câmara (Open Question 9).
  As faixas do próprio `CameraTuning` continuam no V2.
- **Se a câmara tiver bordas orgânicas:** a câmera usa o **retângulo
  envolvente** do jogável. As paredes curvas são colisão do GDD de Câmaras.
- **Se o primeiro plano estiver perto demais do jogável:** com p > 1 ele deriva
  até a margem da F7 e pode cobrir a área jogável. Conferir a margem é tarefa do
  checklist de arte, como a sangria; o jogo não corrige.
- **Se a arte tiver sangria menor que a exigida:** o **jogo** preenche o que
  fica além da arte com a cor de fundo da região (dado da região), nunca com
  vazio transparente.
  Conferir a sangria é tarefa do checklist de arte (Art Bible §8.7), não do
  jogo.

**Y-sort**

- **Se dois pés tiverem o mesmo y:** vale a ordem de spawn (R5).
- **Se o personagem passar atrás de um objeto alto ou de um chefe:** a ordem
  segue o pé e o objeto fica na frente. A regra de oclusão do Art Bible §6.3
  (objeto a ~40% de opacidade onde cobre personagem ou telégrafo) é implementada
  pelo Pipeline visual. Se ela vale também para chefes fica em Open Questions.
- **Se um projétil "voar" por cima de um objeto:** pode ser desenhado atrás
  dele, porque ordena pela sombra. É aceito: só o visual muda, a colisão continua
  no chão.

**Câmera e impulsos**

- **Se o jogador se deslocar rápido** (Investida da Lâmina: 330 px em 10
  passos): a suavização (F3) persegue, sem regra especial. Se o jogador sair da
  vista, o alvo preso traz a câmera de volta.
- **Se um quadro demorar muito** (travada de 1 s): o fator do F3 fica perto de 1
  e a câmera chega ao alvo sem passar dele.
- **Se a mira vier da mira automática do gamepad:** o lookahead é **0**. Ele só
  usa mira controlada pelo jogador (mouse ou analógico direito), para a câmera
  não pular quando o alvo automático troca.
- **Se o cursor passar por cima do personagem:** o lookahead tende a 0 com a
  distância (F2), então o alvo não salta de um lado para o outro.
- **Se o monitor rodar acima de 60 Hz** (144 Hz): a câmera usa a posição
  interpolada do jogador (R7) e anda a cada quadro de render, sem degraus de
  60 Hz.
- **Durante o hitstop** (contador de passos do Combate; `Engine.time_scale`
  fica fora, R7): a câmera e os impulsos usam o `t_apres` (R7; Pipeline F8), então
  não congelam. Se alguém escalar `time_scale` (debug, câmera lenta), a câmera
  continua no relógio de apresentação pelo mesmo motivo.
- **Se muitos impulsos chegarem juntos** (vários abates): o deslocamento soma até
  no máximo 40 px e o zoom até 1,15. No máximo **16 impulsos ativos**; o mais
  velho sai primeiro.
- **Se o Tremor de câmera estiver em 0:** chute e tremor são zero. O zoom de
  impacto continua, a menos que Redução de movimento esteja ligada.
- **Se o jogo pausar ou trocar de câmara durante um impulso:** os impulsos são
  zerados e não voltam ao sair da pausa. Um impulso que chega **durante** a
  pausa é descartado. Redimensionar a janela durante a pausa recalcula e prende
  normalmente.
- **Se a câmera estiver sem `CameraTuning`** (catálogo em Falhou, ou Tuning
  retirado ao sair de Pronto numa recarga; Conteúdo, Edge Cases › Recarga): a
  câmera fica parada onde está, sem suavização, sem lookahead e sem impulsos.
  Impulsos que chegam são descartados, e nenhum valor fixo no código substitui o
  Tuning. Nesse estado só a tela de erros do catálogo é desenhada, presa à tela.
  Quando o Tuning volta (entrada em Pronto), ele vale a partir do quadro
  seguinte; como isso só acontece fora da run, a câmara seguinte começa com
  Corte (R10).
- **Se o mouse estiver sobre as faixas pretas:** a posição fica presa à borda da
  vista (F6).

## Dependencies

**Depende de (upstream)**

| Sistema | Tipo | O que vem de lá | Sem ele |
|---|---|---|---|
| Conteúdo orientado a dados | Suave | `CameraTuning`; valores espaciais já em px (`unit_to_px` = 1,5, só na importação, Conteúdo F4) | Valores ficariam no código |
| Câmaras e ondas (via dado) | Suave, por contrato | Retângulo jogável e sangria de cada câmara; evento de troca | Usa uma câmara padrão de 1920×1080 |
| Acessibilidade e opções (via configurações) | Suave, por contrato | Tremor de câmera (0–100%), Redução de movimento | Padrões: tremor 100%, Redução desligada (Art Bible §7.9) |
| Input e controle (via contrato) | Suave, por contrato | `fonte_mira`, `intensidade_mira` e consulta de cursor (Input R2, R5), para o lookahead (F2) | Sem lookahead (`a` = 0) |
| Pipeline visual (via contrato) | Forte, por contrato | `t_apres`, `dt_max_apres` e `progresso_wipe` (Pipeline F8, R7) | Sem relógio de apresentação para a suavização e os impulsos, e sem o quadro do corte (R10) |

As opções e o retângulo das câmaras chegam como **valores injetados**
(configurações e dado da câmara). Com o Input, a dependência vai nos dois
sentidos: o Input usa a conversão tela → mundo (R9), e a Cena lê a fonte da mira
e a consulta de cursor. O ciclo se resolve por contrato, porque os dois lados só
expõem interfaces de leitura. A Cena 3/4 não chama esses sistemas, então uma
Foundation não passa a depender de sistemas de camadas mais altas.

**É dependência de (downstream)**

| Sistema | Tipo | O que recebe |
|---|---|---|
| Pipeline visual | Forte | Viewport, stretch, camadas e ordem z (R1, R4) |
| Movimento e esquiva | Forte | Plano de jogo em px (R3), limites da câmara |
| Input e controle | Forte (para a mira do mouse) | Conversão tela → mundo (R9, F6) |
| Câmaras e ondas | Forte | Limites de tamanho de câmara (R6) e sangria exigida |
| Feedback de combate (VFX) / Combate núcleo | Suave | Interface de impulsos de câmera (F5); o Combate recebe o requisito do hitstop sem `time_scale` (R7) |
| Telégrafos | Suave | Camadas e z do preenchimento e do contorno (R4) |
| Chefes (fatia vertical) | Suave | Estado Intro de chefe |

**Bidirecionalidade:** Pipeline visual, Movimento e Input já citam a Cena 3/4 no
índice. Câmaras e ondas e Feedback de combate (VFX) passam a citá-la (decisão do
usuário, 2026-11-05). Já existem os GDDs de Input, Movimento, Pipeline visual,
Câmaras e ondas, Feedback de combate, Combate núcleo, Telégrafos e Conteúdo (cada
um deve listar "Cena 3/4 e câmera" em Dependencies: conferir na revisão); só o de
Chefes ainda não existe e, ao ser escrito, deve listá-la. O GDD de Conteúdo
já lista o `CameraTuning` na tabela de `*Tuning` por sistema (R1) e na linha da
Cena em Interactions (Open Question 8, fechada em 2026-11-06).

## Visual/Audio Requirements

O conteúdo visual de cada camada é do Art Bible §6.3 e do Pipeline visual. Este
sistema exige só quatro coisas:

- toda câmara tem arte cobrindo o jogável mais a sangria (≥ 370 px nas laterais
  e ≥ 40 px em cima e embaixo) nas camadas com p = 1,0;
- o primeiro plano (p > 1) fica fora do jogável por pelo menos a deriva da F7
  (104 px nas laterais e 62 px em cima e embaixo numa câmara de 2880×1620 com
  p = 1,2), e uma camada opaca com p < 1 cobre também essa deriva;
- cada região define uma **cor de fundo** para o que ficar além da arte;
- a sombra de contato fica na camada de sombras e marca o pé usado no y-sort.

Não há som próprio.

## Game Feel

- **Câmera:** segue com meia-vida de 0,12 s, sem atraso perceptível nem
  overshoot.
- **Lookahead:** até 120 px, para ver para onde se mira; no mouse, cresce com a
  distância do cursor até 480 px.
- **Impacto:** chute direcional mais tremor e zoom curtos, com meia-vida de
  0,05 s (leve), 0,10 s (pesado) e 0,30 s (chefe). O hitstop correspondente,
  referência ao `CombatTuning` (dono: Combate núcleo), é de 3, 6 e 36 passos
  (0,05, 0,10 e 0,6 s; o 36 é só a morte do chefe). As meias-vidas são
  placeholders deste GDD e o lead assina no playtest (AC-31).
- **Legibilidade antes de tudo:** o deslocamento nunca passa de 40 px nem o zoom
  de 1,15, e a mira não treme com a tela.

## UI Requirements

A UI fica na camada 100, presa à tela, nunca ao mundo. Ela usa a área visível
inteira; em ultrawide, o HUD fica dentro de uma faixa central de 16:9 (1920 px)
para não espalhar informação nos cantos. O letterbox e o pillarbox são pretos
puros.

## Cross-References

| Documento | Seção | Uso neste GDD |
|---|---|---|
| `design/art/art-bible.md` | §3.4, §5.6, §5.9, §6.3, §7.9, §8.6 | Primeiro plano fora do jogável, escala do personagem, 9 camadas de arte, ordem z e parallax do primeiro plano, opções de tremor e movimento, stretch e zoom ≤ 1,15 |
| `design/gdd/game-concept.md` | §11 | Câmera 3/4, arena inteira ou quase visível |
| `design/gdd/conteudo-orientado-a-dados.md` | R1, F4, V2 | `CameraTuning` e `CombatTuning` (hitstop) na tabela de `*Tuning`; `unit_to_px` (1,5, só na importação); validação de `CameraTuning` |
| `design/gdd/modificadores-e-atributos.md` | R6 | Durações em passos vivos (por que o hitstop não usa `time_scale`) |
| `design/gdd/input-e-controle.md` | R2, R5, R6, F2, F3 | Mira (conversão tela → mundo), zona morta usada no lookahead, fonte e intensidade da mira; buffer que roda no hitstop |
| `design/gdd/rng-com-seed.md` | R1 | Tremor com gerador cosmético em `src/presentation/` |
| Khaeros `packages/action-core/src/types.ts`, `engine.ts` | `ARENA_WIDTH/HEIGHT`, `PLAYER_RADIUS` | Arena 1280×720 e raio 18 do cânone |
| Khaeros `docs/baseline.md` | §55.3 | Chute de câmera direcional |
| `docs/engine-reference/godot/breaking-changes.md` | stretch (4.7) | Chaves explícitas no `project.godot` |

## Acceptance Criteria

> Proposta do `qa-lead` (consultado: modo Lean, seção de risco alto), ajustada ao
> limite 43:18 e às decisões do usuário de 2026-11-05. Oráculos conferidos em
> Python.
>
> Evidência: **[L]** `tests/unit/scene/`; **[I]** `tests/integration/scene/`;
> **[UI]** screenshot em `production/qa/evidence/`; **[M]** manual. Tolerância
> ±0,01, salvo indicação. Todo teste de impulso usa ruído fixo injetado.

**A. Janela e escala**

- **AC-01 [I] R1** O `project.godot` tem as chaves escritas (não são padrão do
  motor): viewport 1920×1080, `canvas_items`, `keep_height`, `fractional`,
  janela inicial 1280×720.
- **AC-02 [L] R1/F4/F6**

  | Janela | W | f | Origem das faixas |
  |---|---|---|---|
  | 1280×720 | 1920 | 2/3 | (0, 0) |
  | 2520×1080 | 2520 | 1 | (0, 0) |
  | 2560×1080 | 2560 | 1 | (0, 0) |
  | 3440×1440 | 2580 | 4/3 | (0, 0) |
  | 3840×1080 (32:9) | 2580 | 1 | x = 630 |
  | 1920×1200 | 1920 | 1 | y = 60 |
  | 1440×1080 (4:3) | 1920 | 0,75 | y = 135 |
  | 640×360 | 1920 | 1/3 | (0, 0) |
- **AC-03 [UI] R1** Capturas:
  - em 16:9, 2560×1080, 3440×1440, 32:9, 16:10 e 4:3: faixas só nas laterais
    em 32:9, e só em cima e embaixo em 16:10 e 4:3;
  - em 2560×1080, 320 px de sangria visível de cada lado, sem faixas;
  - o personagem mede 90 ± 5 px na vista lógica.
- **AC-04 [I]** Ultrawide com câmara de 2880 e câmera encostada à esquerda → a
  janela muda para 16:9 → no quadro do `size_changed`, W = 1920 e `pos` já está
  presa pelo F4, sem suavização. **[M]** alternar tela cheia.
- **AC-05 [L] F6**
  - 1280×720, mouse (960, 180), C = (1500, 800) → (1980, 530).
  - 3840×1080, mouse (1920, 540) → C; mouse na faixa, em (100, 540) →
    x = C.x − 1290.
  - 1440×1080, mouse (720, 540) → C; mouse em (720, 50) → y = C.y − 540.
- **AC-06 [L] R9** Câmera falsa com chute de 40 px, tremor e zoom de 1,15 → tela
  → mundo idêntico ao da câmera sem impulsos.

**B. Unidade e plano**

- **AC-07 [L] F1** (teste do script de importação, Conteúdo F4) **GIVEN** o
  script de importação com `UNIT_TO_PX` = 1,5 e uma fixture do cânone com arena
  1280×720 e raio 18 **THEN** os valores gravados são 1920×1080 e 27, e 0 → 0
  **AND** com a constante do script trocada para 2, o raio gravado é 36 (prova
  que o valor não está fixo no código) **AND**, em jogo, o sistema que lê o
  raio 27 do `.tres` usa 27, sem multiplicar de novo.
- **AC-08 [I] R3** Projétil desenhado 60 px acima → colide pela posição de chão.
  Só sobreposição de sprite → não colide.

**C. Camadas e y-sort**

- **AC-09 [I] R4** Todo CanvasItem visível está em exatamente uma das 11
  camadas, com o z e o parallax da tabela. Um grep por atribuição a `z_index` em `src/`, fora do módulo de
  camadas, encontra 0 ocorrências.
- **AC-10 [UI] R4** Um item por camada mostra a ordem da tabela. Um inimigo
  em pé sobre um telégrafo cobre o preenchimento (z −5) e não cobre o contorno
  (z 5); o primeiro plano (z 10) cobre os dois.
- **AC-11 [L] R5**
  - Pé em y 500 contra 520 → o de 520 na frente.
  - Empate em 500 → quem nasceu depois fica na frente, e a ordem fica estável
    por 100 quadros.
  - Projétil com sombra em y 480 e deslocamento visual −80, contra inimigo com
    pé em 500 → o projétil fica atrás.
  - Objeto grande ordena pelo centro da base.
- **AC-12 [UI] R5** Duas screenshots: personagem atrás e na frente de uma
  coluna.

**D. Câmara e limites**

- **AC-13 [L] F4**
  - 16:9, câmara 1920×1080 → (960, 540).
  - 2520×1080 → e = 300, vista de −300 a 2220.
  - 3440×1440 → e = 330.
  - 16:9, câmara de 2880: ax 100 → 960; ax 5000 → 1920.
  - Câmara de 1620 de altura: ay 0 → 540; ay 2000 → 1080.
- **AC-14 [I] R7** 16:9, câmara 1920×1080, jogador roteirizado percorre os cantos
  mirando por 600 quadros → `pos` = (960, 540) em todos.
- **AC-15 [L]+[I] R6** A validação cruzada câmara × `CameraTuning` (dona: GDD de
  Câmaras, Open Question 9) rejeita 1919×1080 e 2881×1620, nomeando a câmara,
  e aceita os limites exatos. Com catálogo inválido → tela de erros do
  catálogo.
- **AC-16 [L]** Um jogável poligonal produz o retângulo envolvente esperado.
- **AC-17 [I]** Investida roteirizada (330 px em 10 passos) com h = 0,12 → o pé
  do jogador nunca sai da vista.
- **AC-18 [I] Edge** Uma câmara com sangria curta numa vista 2580 → a área além
  da arte tem exatamente a cor de fundo da região.

**E. Alvo e lookahead**

- **AC-19 [L] F2**
  - P (1000, 600), mouse com m = (300, 400) e R_mouse 480 → (1072, 696).
  - Mouse com m = (60, 80) → (1015, 620).
  - Mira (0, 0) → P.
  - Em 360 direções e distâncias do cursor de 0 a 2000 px, |alvo − P| ≤ 120, e
    |alvo − P| nunca diminui quando a distância aumenta na mesma direção.
  - Redução de movimento → P; mira automática → P.
  - Analógico direito: o lookahead depende de `intensidade_mira`. Com s bruto 0,5
    depois da zona morta, o Input F2 dá `intensidade_mira` 0,4 e o lookahead é
    48 px (120 × 0,4). Com `intensidade_mira` 0,5 direto, 60 px.
- **AC-20 [L] R9** Duas câmeras com a mesma `pos_seguir` e lookahead diferente →
  direção da mira idêntica.

**F. Suavização**

- **AC-21 [L] F3** Com h = 0,12, de 0 para 100:
  - Δt 0,10 → 43,9; 0,12 → 50; 0,24 → 75; 1 → 99,69;
  - duas fatias de 0,05 = uma de 0,10 (1e-6);
  - para Δt de 0,001 a 5, nunca passa de 100.
- **AC-22 [L] R10** Na troca de câmara: `pos` = alvo preso no mesmo quadro, e
  nenhum impulso ativo. Com um wipe roteirizado de 2·M quadros, `pos` fica na
  câmara velha até o quadro M − 1 e está no alvo preso da câmara nova no
  quadro M, o mesmo do teleporte do jogador.

**G. Impulsos**

- **AC-23 [L]** Pesado em t 0,1, dir (1, 0), s_t 0,5, ruído (0,5; −1) → (6, −2),
  módulo 6,32.
- **AC-24 [L]** Dois de chefe em t 0, ruído 0 → módulo 40 na direção (1, 0) e
  zoom 1,15.
- **AC-25 [L]** Chefe em t 0,6 → zoom 1,025. rm = 1 → zoom 1. s_t = 0 → desloc 0
  e zoom 1,025.
- **AC-26 [L]** (relógio de apresentação roteirizado, `t_apres`) Leve ativo em t 0,21 (d = 0,054) e descartado em t 0,22
  (d = 0,047). 17 impulsos enviados → 16 ativos, e o primeiro saiu.
- **AC-27 [L]** (relógio de apresentação roteirizado, `t_apres`) s_t 0,25 → exatamente 1/4 do deslocamento de s_t 1, abaixo do
  teto.
- **AC-28 [I] hitstop** Pesado durante um hitstop roteirizado como contador de
  passos (física rodando, sistemas vivos parados, `Engine.time_scale` = 1) e
  relógio de apresentação roteirizado (`t_apres`, R12) avançando 0,1 s → d = 0,5, com o jogo parado.
- **AC-29 [I] pausa** (relógio de apresentação roteirizado, `t_apres`)
  - Impulso ativo → pausa → desloc 0, zoom 1 e `pos` constante.
  - Ao despausar, o impulso não volta.
  - Impulso enviado durante a pausa → descartado.
- **AC-30 [L] estados**, com relógio de apresentação roteirizado (`t_apres`) e eventos roteirizados:
  - Seguindo + troca de câmara → Corte: no mesmo quadro, `pos` = alvo preso e 0
    impulsos ativos; no quadro seguinte, o estado é Seguindo.
  - Seguindo + pausa → Pausa: `pos` constante por 60 quadros, desloc 0, zoom 1;
    ao despausar → Seguindo, sem impulso anterior.
  - Seguindo + chefe entra → Intro de chefe: o enquadramento vem do comando
    roteirizado; ao fim do comando → Seguindo, de novo atrás do jogador.
  - Intro com zoom_intro 1,3 → zoom_total 1,15. zoom_intro 1,10 + pesado em
    t = 0 → 1,144. zoom_intro 1,15 + pesado → 1,15. Com Redução de movimento →
    zoom_total 1.
- **AC-30b [L] Bênção, Morte e Transição** (relógio de apresentação roteirizado,
  `t_apres`; R8, States):
  - Impulso ativo + Tela de Bênção abre → Bênção: desloc 0, zoom 1, 0 impulsos
    ativos; `pos` constante por 60 quadros com `t_apres` parado.
  - Impulso enviado durante a Bênção → descartado (como na Pausa, AC-29); ao fechar
    a Bênção, nenhum impulso anterior volta.
  - Seguindo + Morte do jogador → Morte, e Seguindo + Transição → Transição: nos
    dois, impulsos zerados e câmera parada; impulso que chega é descartado.
  - Pausa aberta por cima da Bênção → fechar a Pausa → volta a **Bênção**, não a
    Seguindo: `pos` constante e 0 impulsos no quadro do retorno; só ao fechar a
    Bênção → Seguindo.
  - A coluna "Sai para" de Seguindo lista Corte, Pausa, Bênção, Morte, Transição
    e Intro de chefe (conferência da tabela de estados).
- **AC-31 [M] Visual/Feel** O lead assina os presets leve, pesado e chefe
  (placeholders), com screenshot do quadro de pico.

**H. Parallax e interpolação** (revisão de 2026-11-05)

- **AC-32 [L] F7**
  - p 1,2, câmara 2880×1620 → deriva (104, 62).
  - p 1,2, câmara 1920×1080 → (8, 8). p 1,0 → (0, 0).
  - p 1,2, câmara de 2880, `câmera_final` = centro + (480, 0) → desloc_camada
    (−96, 0); câmera no centro → (0, 0).
- **AC-33 [I] R4** Câmara de 2880×1620, câmera levada aos quatro cantos com
  chute de 40 px para fora → o deslocamento do primeiro plano em relação ao
  mundo nunca passa da deriva da F7, e as camadas com p = 1,0 têm deslocamento 0.
- **AC-34 [L] R7** P_anterior (0, 0), P_atual (10, 0), f_i 0,25 → P (2,5; 0).
  Num teleporte, P_anterior = P_atual no mesmo quadro.
- **AC-35 [I] R7** Câmara de 2880×1080, Redução de movimento ligada (sem
  lookahead), jogador partindo do centro para a direita a 300 px/s constantes,
  física a 60 Hz e render roteirizado a 144 Hz (Δt 1/144): no último 0,5 s de
  1 s, o avanço de `pos` por quadro varia menos de 1% entre quadros consecutivos
  (sem degraus de 60 Hz) e a câmera não encosta no limite do F4.
- **AC-36 [L] R1** No `size_changed` para 3840×1080, o aspecto vira `keep` com
  2580×1080; de volta a 2560×1080, volta a `keep_height` com 1920×1080.
- **AC-37 [L] R9** Câmera falsa com `pos` do último render = (960, 540),
  P_anterior (0, 0), P_atual (33, 0), f_i 0,5 (P = (16,5; 0)), janela
  1920×1080 e cursor em (960, 540) → o Input recebe a mira (927, 540) como **vetor bruto antes
  de normalizar** (|mirar| = 1 após a normalização, Input AC-02), medida a
  partir de `P_atual`, e não (943,5; 540).
- **AC-38 [I]+[M] R7** **[I]** Com `physics/common/physics_interpolation`
  ligado, o nó da câmera tem `physics_interpolation_mode` = `OFF`. **[M]** Num
  monitor de 144 Hz, Investida e corrida em linha reta numa câmara de 2880: a
  câmera e o personagem andam sem degraus de 60 Hz. Uma gravação a 144 quadros/s
  fica retida em `production/qa/evidence/`.
- **AC-39 [L] Edge** (re-review de 2026-11-08) Câmera com injeção vazia de
  `CameraTuning`, mira roteirizada e um impulso pesado enviado → por 60 quadros,
  `pos` constante, desloc 0, zoom 1 e 0 impulsos ativos. Tuning injetado de novo
  → no quadro seguinte o lookahead volta a valer, e a troca de câmara seguinte
  corta para o alvo preso (R10).

Cobertura: R1–R12 e F1–F7 têm pelo menos um critério cada.

## Open Questions

| # | Pergunta | Dono | Resolver até |
|---|---|---|---|
| 1 | ~~O telégrafo fica acima ou abaixo dos personagens?~~ **Resolvida em 2026-11-10:** duas passadas, preenchimento em z −5 e contorno em z 5 (Pipeline visual R5; R4 deste GDD). A emenda do Art Bible §6.3/§8.6 é do art-director (Pipeline OQ4) | — | ✅ |
| 2 | A oclusão a ~40% vale para personagem coberto por chefe? | art-director | GDD de Pipeline visual |
| 3 | Estrutura de nós (CanvasLayers, `y_sort_enabled`, câmera própria) e custo de draw call do y-sort (NÃO VERIFICADO no Art Bible §8.6) | technical-director | ADR, antes de `/create-architecture` |
| 4 | Sensação dos presets de impulso (leve, pesado, chefe) | game-designer | Protótipo de combate |
| 5 | Enquadramento da intro de chefe | game-designer | GDD de Chefes (fatia vertical) |
| 6 | Parallax do fundo e da névoa distante (hoje 1,0) e valor exato do primeiro plano (1,1–1,2) | technical-artist + art-director | GDD de Pipeline visual |
| 7 | `R_mouse` = 480 px dá a sensação certa de lookahead? | game-designer | Protótipo de combate |
| 8 | ~~O GDD de Conteúdo lista `CameraTuning` na tabela de `*Tuning` por sistema~~ **Resolvida em 2026-11-06:** o Conteúdo lista o `CameraTuning` na R1 (tabela de `*Tuning`) e na linha da Cena em Interactions (cross-review 2026-11-06, C-I2) | — | ✅ |
| 9 | Validação cruzada do tamanho de cada câmara contra os limites do `CameraTuning`: onde mora a regra (classe de câmara no catálogo ou checagem do GDD de Câmaras) e como chega à tela de erros do catálogo | dono do GDD de Câmaras e ondas + dono do GDD de Conteúdo | GDD de Câmaras e ondas |
