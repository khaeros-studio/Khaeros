# Movimento e esquiva

> **Status**: Approved (`/design-review` 2026-11-08, lean: NEEDS REVISION, 6 bloqueantes revisados; re-review independente 2026-11-08: **APPROVED**, 0 bloqueantes, 4 recomendadas aplicadas na mesma data, com o pedido `deslocar(v)`)
> **Author**: usuário + Claude (design-system, modo Lean)
> **Last Updated**: 2026-11-08
> **Last Verified**: 2026-11-08
> **Implements Pillar**: P3 *Reflexo que se lê* ("a esquiva com invulnerabilidade sempre responde")
> **Creative Director Review (CD-GDD-ALIGN)**: pulada (modo Lean)

## Summary

**Movimento e esquiva** move o personagem do jogador no plano de jogo. Ele anda
com a velocidade da arma e dos modificadores, e esquiva: um deslocamento de
0,15 s e 202,5 px, com 0,2 s de invulnerabilidade, que gasta uma carga
recarregada a cada 0,7 s e cancela a investida e a recuperação do golpe. É a
promessa do P3: com carga, a esquiva sai no passo do toque e nada do inimigo
acerta durante ela. O sistema também detecta e calcula o Corte da esquiva, que o
Combate aplica.

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `Input e controle, Cena 3/4 e câmera, Modificadores e atributos, Conteúdo orientado a dados; Combate núcleo (por contrato)`

> **Nota (2026-11-11, revisão cruzada):** pendente: Dependencies listam Efeitos de status e Armas (hoje só na tabela de Interactions); registro `hurt_invuln_steps` sem `referenced_by` Movimento.

## Overview

**Movimento e esquiva** move o personagem do jogador no plano de jogo, a cada
passo vivo de física (60/s). Tem duas partes:

- **andar:** a velocidade vem da arma (`WeaponDef`) e dos modificadores de
  `velocidade`, e o analógico permite andar devagar;
- **esquiva:** um deslocamento curto e rápido, com invulnerabilidade, que gasta
  uma **carga**. As cargas se recarregam sozinhas, uma de cada vez. Esta parte
  também define o que a esquiva cancela.

O sistema consome do Input só `mover` e o toque de `esquiva` no buffer. Do
Modificadores lê `velocidade`, `cargas_esquiva` e o gatilho `corte_da_esquiva`.
Os números (duração, velocidade e recarga da esquiva, invulnerabilidade, fator
de recuperação) moram no `MovementTuning`. O plano é o da Cena 3/4: px de mundo,
sem eixo de altura.

Para o jogador, a promessa é a do P3: **a esquiva sempre responde**.

- Com carga disponível, ela sai no passo do toque, ou assim que a esquiva
  anterior termina.
- Ela interrompe a investida e a recuperação de um golpe.
- Durante ela, nada do inimigo acerta.

Assim, quem morre por não esquivar sente que errou, e não que o jogo engoliu o
comando. Sem este sistema, não há como ler um telégrafo e sair dele, e o combate
do cânone (`engine.ts:806–865`) perde o seu eixo.

> **→ vira ADR:** se o corpo do jogador é um `CharacterBody2D` ou uma cinemática
> própria de círculos, como no cânone. A referência do motor não cobre o
> `CharacterBody2D` no 4.7 (`docs/engine-reference/godot/modules/physics.md` só
> traz o 3D).

## Detailed Design

### Core Rules

> `game-designer`, `art-director`, `technical-artist` e `gameplay-programmer`
> não foram consultados: modo Lean. Revisar manualmente antes de produção. As
> regras seguem o cânone (`engine.ts:33–35`, `:778–865`), com duas mudanças
> decididas pelo usuário em 2026-11-08: a esquiva é cancelada na troca de câmara
> (R1), e o Corte tem um teto de alvos opcional (R8).

**R1. Corpo do jogador.**

- É um círculo de raio `raio_jogador_px` na posição de chão (Cena R3). O cânone
  usa `PLAYER_RADIUS` 18 u, que dá 27 px.
- **Só o Movimento escreve a posição.** Ele guarda a posição atual e a do passo
  anterior, que a Cena 3/4 interpola (Cena R7). Outro sistema que precise mover
  o jogador pede `deslocar(v)` (R9).
- **Teleporte** (`teleportar(pos)`, chamado por Câmaras e ondas no spawn e na
  troca de câmara):
  - a posição anterior passa a ser igual à atual, e o Movimento emite o aviso
    de teleporte. Quem chama `reset_physics_interpolation()` é o nó de
    apresentação do jogador, ao receber o aviso (Cena R7); a lógica do
    Movimento roda sem SceneTree (R12);
  - a esquiva em curso é **cancelada** (decisão do usuário; no cânone ela
    continuava);
  - cargas, recarga e invulnerabilidade não mudam.

**R2. Passo vivo.**

- O Movimento roda uma vez por passo de física, só quando o Input está no estado
  Jogo.
- Ele **não roda** durante o hitstop (o contador do Combate, Cena R7), a pausa
  ou a Bênção.
- **Quem decide é só o orquestrador do passo.** Ele lê o estado do Input e o
  hitstop do Combate e chama `passo()` ou `passo_congelado()`. O Movimento não
  consulta o hitstop por conta própria.
- **Passo congelado:** em todo passo de física em que o Movimento não roda
  (hitstop, pausa, Bênção, Input fora de Jogo), ele recebe a chamada
  `passo_congelado()`, que só faz posição anterior = atual. Sem isso, a
  interpolação da Cena (R7) repetiria o último trecho (até 22,5 px na esquiva) a
  cada passo do congelamento, e a câmera tremeria no hitstop. Nada mais muda.
- Todos os contadores daqui (esquiva restante, recarga) contam só passos vivos.
- Ele roda **antes** do Combate e do Selo (Input R6, ordem Movimento → Combate →
  Selo).
- Andar e esquivar também valem em câmara limpa, sem inimigos (cânone).

**R3. Ordem dentro do passo.**

0. Sincronizar o máximo de cargas (R7, "O atributo mudou").
1. Recarga (R7).
2. Início de esquiva (R5).
3. Deslocamento, **exatamente um**, nesta prioridade: investida (R9), esquiva
   (R6) ou andar (R4). A prioridade vale depois do `cancelar` da R5: se a
   esquiva saiu neste passo, não há investida. Se o Combate informar investida
   ativa durante uma esquiva, é violação do contrato; a esquiva vence, e o
   Movimento registra um aviso de depuração.
4. Corte da esquiva (R8), se houve deslocamento de esquiva neste passo
   (inclusive o último).
5. Colisão (R10).

**R4. Andar.**

- Fora de esquiva e de investida, com |`mover`| > 0, o personagem anda na
  direção de `mover` normalizado. A velocidade é `valor(velocidade)` ×
  min(1, |`mover`|) × f_rec (F1).
- **f_rec** = `fator_recuperacao` enquanto o Combate informa "em recuperação de
  golpe"; senão, 1. A recuperação é do Combate (cânone `recoverTicks`).
- Não há aceleração nem inércia: o personagem para no passo em que `mover` é
  zero (cânone).
- Andar não muda a direção em que o personagem olha, que vem da mira (Input R5).

**R5. Início da esquiva.**

- **Condições** (todas):
  - a esquiva está no **buffer**; segurar não conta (Input R6);
  - cargas ≥ 1;
  - não está em esquiva.
  - Investida e recuperação **não** impedem a esquiva: ela as cancela.
- **Ao iniciar**, no mesmo passo:
  1. a direção é `mover` normalizado se |`mover`| > 0; senão, `mirar`, que é
     sempre unitária. A velocidade é sempre a cheia, qualquer que seja o módulo
     do analógico;
  2. cargas − 1;
  3. esquiva restante = passos(`duracao_esquiva_s`), pelo F7 do Conteúdo;
  4. pedidos ao Combate, **síncronos e nesta ordem**. O `cancelar` vale no
     mesmo passo, antes do deslocamento (R3):
     - **cancelar** investida e recuperação;
     - `garantir_invulneravel(passos(duracao_esquiva_s) + passos(invuln_extra_s))`;
     - avisar **`esquiva_iniciada`**. É aqui que o Combate abre a janela
       `apos_esquiva` (Modificadores R4);
  5. esvazia a lista de alvos do Corte;
  6. consome a esquiva do buffer;
  7. emite o evento `esquiva` (VFX e áudio).
- **Sem carga:** a esquiva não sai, e o sistema emite o evento
  `esquiva_sem_carga` uma vez por toque novo (Edge Cases). O toque fica no
  buffer até o prazo acabar (Input, Edge Cases). Se uma carga voltar antes disso, a esquiva sai nesse
  passo.
- **Durante uma esquiva:** um toque novo fica no buffer. Ele sai no passo
  seguinte ao fim da esquiva, se ainda houver prazo e carga (cânone).
- **Durante uma esquiva e sem carga** (decisão do usuário, 2026-11-08): o toque
  novo emite `esquiva_sem_carga` no passo em que chega, uma vez, como fora da
  esquiva, e fica no buffer. Se uma carga voltar dentro do prazo, a esquiva sai
  no primeiro passo depois do fim da atual.
- **"Toque novo"** é o toque de esquiva que entra no buffer ou renova o prazo
  dele (Input F3). Um toque novo sem carga feito durante um congelamento
  (hitstop) emite o evento no primeiro passo vivo, como o som da esquiva (A1). O limite de uma reação a cada 0,2 s (Visual/Audio V5, A1) é
  dos consumidores (HUD e áudio): o Movimento não filtra o evento.

**R6. Deslocamento da esquiva.**

- A cada passo de esquiva, o personagem anda `velocidade_esquiva_pxs` / 60 na
  direção fixada (F2) e a esquiva restante cai 1. No zero, a esquiva termina ao
  fim daquele passo.
- A velocidade da esquiva **não** escala com `velocidade` nem com nenhum
  modificador (cânone).
- **"Em esquiva"** (decisão do usuário, 2026-11-08, paridade com o cânone) é a
  consulta que Combate, Selo, HUD e Pipeline leem depois do Movimento: é
  verdadeira quando a esquiva restante é > 0 ao fim do Movimento daquele passo.
  - No último passo da esquiva (restante 1 → 0), o deslocamento e o Corte
    acontecem, mas a consulta já é **falsa**. Golpe e Selo guardados podem sair
    nesse mesmo passo (cânone `engine.ts:865`). Com D = 9, a consulta é
    verdadeira nos passos s a s+7 e falsa a partir de s+8.
  - Uma nova esquiva só começa quando a restante é 0 no início do passo, então
    duas esquivas seguidas continuam separadas por exatamente D passos.

**R7. Cargas e recarga.**

- O máximo é `valor(cargas_esquiva)`. A base é `cargas_base` do
  `MovementTuning`, e o piso 1 é do Modificadores (R2).
- **Recarga:** uma carga por vez (F3).
  - Enquanto cargas < máximo, o sistema conta passos(`recarga_s`). Quando a
    conta fecha, ganha 1 carga.
  - Se ainda estiver abaixo do máximo, a conta recomeça no passo seguinte.
  - A recarga conta durante a esquiva.
  - Com c = `cargas_max`, o contador é 0: se as cargas chegam ao máximo pela R9 do
    Modificadores, o contador zera (Edge Cases).
- **O atributo mudou** (Modificadores R9): se sobe, o jogador ganha a diferença
  na hora; se desce, as cargas atuais são cortadas ao novo máximo.
  - **Como o Movimento percebe:** no item 0 da R3, a cada passo vivo, ele
    compara `valor(cargas_esquiva)` com o `cargas_max` guardado. Se mudou, aplica a
    diferença ou o corte, zera o contador se c = `cargas_max` e guarda o novo `cargas_max`.
  - Uma mudança feita com o Movimento congelado (a bênção é escolhida na
    Bênção) vale no primeiro passo vivo depois dela.
  - Se `cargas_max` desce e as cargas continuam abaixo do novo máximo, o contador
    continua de onde estava.
- O começo da run abre com as cargas no máximo. A troca de câmara não restaura
  cargas (cânone).

**R8. Corte da esquiva** (gatilho `corte_da_esquiva`; Modificadores R5, R12,
R13). O Movimento **detecta** e o Combate **aplica**.

- Só vale se o total do gatilho for > 0.
- Em cada passo de esquiva, depois do deslocamento, um inimigo é cortado quando:
  - está na lista de atingíveis injetada (R12). A IA já exclui quem está
    surgindo ou tem Vida ≤ 0, e o Movimento não refaz esse filtro;
  - ainda não foi cortado nesta esquiva;
  - está a uma distância ≤ `raio_jogador_px` + raio do inimigo +
    `alcance_extra_px`. A comparação é por distância ao quadrado contra o
    alcance ao quadrado, sem epsilon, no float do motor (F5).
- Cada inimigo cortado entra na lista. O **Movimento calcula o dano** (F6) pelo
  portador, com `multiplicador_de_dano(ataque, contexto)`.
  - A consulta `contexto_de_dano` do Combate devolve **só a Vida atual e a
    máxima**.
  - O Movimento monta o contexto com essa Vida e com `apos_esquiva` = falso e
    `enesimo_acerto` = falso, mesmo que a janela `apos_esquiva` já esteja aberta
    neste passo (R5, item 4).
- Depois envia ao Combate o pedido `aplicar_corte`, com:
  - dano = total × M(grupo Ataque); na F2 do Modificadores, `vida_abaixo` vale,
    `apos_esquiva` e `enesimo_acerto` não;
  - empurrão `empurrao`, na direção da esquiva;
  - Sangramento `sangramento`, pelo GDD de Efeitos de status.
- O Corte **não** conta acerto, não gera Fluxo, não aciona `golpe_*` e não pede
  hitstop (cânone).
- **Teto (D-W6):** com `alvos_max_corte` definido, a esquiva para de cortar
  quando a lista chega ao teto. Os inimigos são testados na ordem estável da
  lista de alvos. O valor inicial é **vazio**, sem teto, como no cânone. Quem
  decide o teto é o `/balance-check`.

**R9. Investida.** Enquanto o Combate informa "investida ativa", com um
deslocamento por passo `d` (vetor em px por passo), o Movimento aplica `d` no
lugar de andar. A
esquiva cancela a investida (R5). O dano de contato da investida é do Combate,
lido na posição depois do deslocamento.

- **Pedido `deslocar(v)`** (decisão do usuário, 2026-11-08). É o caminho para o
  passo de apoio do golpe corpo a corpo: no cânone, o golpe empurra o jogador
  `MELEE_STEP` 7 u (10,5 px) na direção da mira, depois do acerto
  (`engine.ts:713–717`).
  - É um pedido síncrono do Combate, feito no mesmo passo e depois do
    Movimento.
  - O Movimento soma `v` à posição atual e roda de novo a colisão (R10).
  - A posição anterior não muda, e nada mais muda: contadores, esquiva e Corte
    ficam como estavam.
  - O valor de `v` e quando pedir são do Combate.

**R10. Colisão.**

- Depois do deslocamento, para cada obstáculo da câmara (círculos, dado de
  Câmaras e ondas), na ordem do dado: se a distância for menor que
  r_obstáculo + `raio_jogador_px`, o jogador é empurrado para fora ao longo da
  normal (do centro do obstáculo até o jogador). Se os centros coincidirem, a
  normal é (0, −1).
- Em seguida a posição é presa ao retângulo jogável, encolhido do raio.
- É uma passada por passo (cânone).
- **Inimigos não bloqueiam o jogador**, nem andando nem na esquiva (cânone).
  Atravessar um inimigo é legítimo.

**R11. `MovementTuning`** (dado; já listado na R1 do Conteúdo). As faixas são
propostas e serão conferidas no Formulas.

| Campo | Valor inicial | Faixa | Cânone |
|---|---|---|---|
| `cargas_base` | 1 | 1 – 3 | `dashCharges: 1` |
| `duracao_esquiva_s` | 0,15 (9 passos) | 0,05 – 0,5 (aviso MV8 acima de 10 passos) | `DASH_TICKS` 9 |
| `velocidade_esquiva_pxs` | 1350 | 300 – 3000 | `DASH_SPEED` 15 (F2) |
| `invuln_extra_s` | 0,05 (3 passos) | 0 – 0,25 | `DASH_TICKS + 3` |
| `recarga_s` | 0,7 (42 passos) | 0,1 – 3,0 | `DASH_RECHARGE_TICKS` 42 |
| `fator_recuperacao` | 0,45 | 0 – 1 | `RECOVER_MOVE_FACTOR` |
| `raio_jogador_px` | 27 | 10 – 50 (MV4) | `PLAYER_RADIUS` 18 (F4) |
| `alvos_max_corte` | vazio (sem teto) | ≥ 1 ou vazio | — (D-W6) |

A velocidade de andar não está aqui: ela é `WeaponDef.velocidade`, pela F2 do
Conteúdo. A Lâmina tem 4,3, que dá 387 px/s.

**R12. Injeção.** O Movimento recebe por injeção:

- o portador do jogador (Modificadores R11);
- a amostra de entrada (Input R2);
- as consultas do Combate (em recuperação, investida ativa e o `d` dela,
  `contexto_de_dano` com a Vida atual e a máxima) e a interface de pedidos do
  Combate. O hitstop não é consultado: quem decide o congelamento é o
  orquestrador (R2);
- a geometria da câmara (retângulo e obstáculos);
- a lista de inimigos atingíveis, com posição e raio;
- o `MovementTuning`.

Os testes montam tudo isso em memória.

### States and Transitions

| Estado | Entra quando | Sai para |
|---|---|---|
| Livre (parado ou andando) | Começo da run; fim da esquiva; fim da investida; fim do congelamento | Em esquiva (R5), Em investida (o Combate inicia), Congelado |
| Em esquiva | Início válido (R5) | Livre (esquiva restante = 0, ou teleporte), Congelado (o contador continua depois) |
| Em investida | O Combate informa investida ativa | Livre (fim informado pelo Combate), Em esquiva (cancela), Congelado |
| Congelado | Hitstop, pausa, Bênção, Input fora de Jogo | O estado anterior, com todos os contadores intactos |

A recarga (R7) corre em paralelo em Livre, Em esquiva e Em investida, e para em
Congelado.

### Interactions with Other Systems

| Sistema | Recebe daqui | Fornece para cá | Dono da interface |
|---|---|---|---|
| Input e controle | consumo da esquiva no buffer | `mover` (0–1), `mirar`, esquiva no buffer | Input (amostra), este GDD (quando a esquiva sai) |
| Modificadores e atributos | — (a esquiva não é fonte de modificador) | `valor(velocidade)`, `valor(cargas_esquiva)`, `gatilhos(corte_da_esquiva)` | Modificadores |
| Combate núcleo | `esquiva_iniciada`, pedidos (cancelar investida e recuperação, `garantir_invulneravel`, aplicar Corte), posição do jogador, "em esquiva" | em recuperação, investida ativa e `d` (vetor), pedido `deslocar(v)`, `contexto_de_dano` (só Vida atual e máxima, para o M do Corte); desconto da invulnerabilidade (F4) | este GDD (pedidos), Combate (execução); **provisório** |
| Selo e Fluxo | "em esquiva" (o Selo não sai durante a esquiva, cânone) | — | Selo |
| Cena 3/4 e câmera | posição atual e anterior, aviso de teleporte | plano em px (R3) | Cena |
| Câmaras e ondas | — | retângulo jogável, obstáculos, chamada de `teleportar` | Câmaras; **provisório** |
| IA de inimigos e elites | posição do jogador (alvo) | lista de inimigos atingíveis (posição, raio, ordem estável) | IA; **provisório** |
| Efeitos de status | — (o Combate repassa o Sangramento do Corte) | — | Status |
| Conteúdo orientado a dados | — | `MovementTuning`, `WeaponDef.velocidade` (px/s) | Conteúdo |
| HUD | cargas atuais e máximo, progresso da recarga (fração 0–1 do contador; 0 com c = M), eventos `esquiva` e `esquiva_sem_carga` | — | HUD |
| Pipeline visual / áudio | eventos `esquiva` (com a posição de início e a direção da esquiva) e `esquiva_sem_carga`, posição, "em esquiva" (Visual/Audio V2, V3) | — | Pipeline |

Os contratos com Combate, Câmaras e IA são **provisórios**, porque esses GDDs
ainda não existem. Cada um, ao ser escrito, deve honrá-los.

## Formulas

> Proposta do `systems-designer` (consultado: modo Lean, seção de risco alto).
> Contas refeitas contra o cânone (`engine.ts:269–292`, `:778–865`;
> `arenaContent.ts`). Escolhas de validação (MV1, MV4, MV2/MV7): usuário,
> 2026-11-08.

Convenções: `passos(t)` é o F7 do Conteúdo; `TICK_RATE` = 60 (constante).
**D** = passos(`duracao_esquiva_s`), **E** = passos(`invuln_extra_s`),
**R** = passos(`recarga_s`). D, E e R são quantizados **separadamente**, e as
somas são feitas em inteiros (MV3).

### F1. Velocidade de andar

The walk_speed formula is defined as:

`v_andar = valor(velocidade) × min(1, |mover|) × f_rec` ; deslocamento por passo
= `v_andar / TICK_RATE`, na direção de `mover` normalizado

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| valor(velocidade) | float | ≥ 0 (base 342–423) | calculated | F1 do Modificadores sobre `WeaponDef.velocidade` (F2 do Conteúdo), em px/s |
| mover | vec2 | módulo 0–1 | calculated | amostra do Input; o `min` é só proteção |
| f_rec | float | 0–1 | data file | `fator_recuperacao` em recuperação; senão 1 |
| TICK_RATE | int | 60 | constant | passos/s |
| v_andar | float | 0 – valor(velocidade) | calculated | velocidade efetiva |

**Output Range:** 0 a `valor(velocidade)`. Sem clamp próprio, sem aceleração;
posição em float.
**Example:** Lâmina 4,3 × 60 × 1,5 = 387 px/s → 6,45 px/passo. Com +12%:
433,44 px/s. Analógico 0,5 em recuperação: 387 × 0,5 × 0,45 = 87,075 px/s.

### F2. Esquiva: passos e distância

The dash_displacement formula is defined as:

`D = passos(duracao_esquiva_s)` ; `d_passo = velocidade_esquiva_pxs / TICK_RATE`
; `dist_total = D × d_passo`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| duracao_esquiva_s | float | 0,05–0,5 | data file | `MovementTuning` |
| velocidade_esquiva_pxs | float | 300–3000 | data file | `MovementTuning`; não escala com nada |
| D | int | 3–30 | calculated | passos de esquiva, contando o do início |
| d_passo | float | 5–50 px | calculated | deslocamento por passo |
| dist_total | float | 15–1500 px | calculated | sem obstáculo nem parede |

**Output Range:** 15 a 1500 px nos extremos. Usa os passos quantizados; parede
e obstáculo encurtam (R10).
**Example:** D = round(0,15 × 60) = 9; 1350 / 60 = 22,5 px; 9 × 22,5 =
**202,5 px** (cânone: 135 u × 1,5). Com 0,14 s: D = 8 → 180 px, não 189.

### F3. Recarga de cargas

The dash_recharge formula is defined as:

`T_k = k × R − p` ; `T_cheio = (cargas_max − c0) × R − p` (passos vivos) ; taxa
sustentada = `TICK_RATE / R` cargas/s

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| recarga_s | float | 0,1–3,0 | data file | `MovementTuning` |
| R | int | 6–180 | calculated | passos(`recarga_s`) |
| cargas_max | int | ≥ 1 | calculated | `valor(cargas_esquiva)` (não confundir com o M, multiplicador de dano do Corte) |
| c0 | int | 0 – cargas_max | calculated | cargas atuais |
| p | int | 0 – R−1 (0 se c0 = cargas_max) | calculated | progresso do contador em andamento |
| k | int | 1 – (cargas_max − c0) | calculated | cargas a recuperar |
| T_k, T_cheio | int | ≥ 0 | calculated | passos até k cargas / até o cheio |

**Output Range:** inteiros ≥ 0. Regras exatas (cânone `engine.ts:790–794`):

- o contador só corre com c < `cargas_max`, e **gastar uma carga não o zera**;
- a carga volta R passos depois do passo da esquiva, porque a recarga vem antes
  do início no mesmo passo (R3), e já vale no passo em que volta;
- o contador congela no hitstop: em relógio, a recarga leva R passos mais os
  passos congelados.

**Example:** R = 42. Esquiva no passo 100 → carga de volta no 142. `cargas_max` = 3,
c0 = 0: T_cheio = 126 passos (2,1 s). `cargas_max` = 3, c0 = 2, p = 10: T_cheio = 32. Taxa
sustentada: 60 / 42 = 1,4286 cargas/s.

### F4. Invulnerabilidade da esquiva

The dash_invulnerability formula is defined as:

`inv_esquiva = D + E` ; `inv_depois = max(inv_antes, inv_esquiva)` (pedido
`garantir_invulneravel`)

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| D | int | 3–30 | calculated | F2 |
| invuln_extra_s | float | 0–0,25 | data file | `MovementTuning`; **aceita 0** |
| E | int | 0–15 | calculated | passos(`invuln_extra_s`); 0 só se o campo é 0 |
| inv_antes | int | ≥ 0 | calculated | contador do Combate no início |
| inv_esquiva | int | 3–45 | calculated | passos que a esquiva garante |
| inv_depois | int | ≥ inv_esquiva | calculated | contador depois do pedido |

**Output Range:** `inv_esquiva` ≥ D por construção; o pedido nunca reduz o
contador.

- **Contrato provisório com o Combate** (paridade com o cânone,
  `engine.ts:780`, `:816`): o contador protege o passo em que é posto e é
  descontado no início de cada passo vivo seguinte, antes de qualquer dano.
  Assim `garantir_invulneravel(n)` pedido no passo s protege exatamente os
  passos vivos s a s+n−1, inclusive o golpe que chega no próprio passo do
  toque. As imagens residuais (Visual/Audio V3) duram esses mesmos n passos.

- Cobertura sustentada = `inv_esquiva / R`.
- Rajada de N cargas = `(N−1) × D + inv_esquiva` passos contínuos.

**Example:** 9 + 3 = **12 passos (0,2 s)**. inv_antes = 25 → 25. Cobertura
12/42 = 28,6%. Rajada de 3 cargas: 2 × 9 + 12 = 30 passos, e depois um buraco
de 12 passos até a primeira carga voltar no passo 42.

### F5. Alcance do Corte da esquiva

The dash_cut_reach formula is defined as:

`alcance_corte(i) = raio_jogador_px + raio_inimigo_px(i) + alcance_extra_px` ;
o inimigo i é cortado se `distância(jogador, i) ≤ alcance_corte(i)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| raio_jogador_px | float | 10–50 | data file | `MovementTuning` |
| raio_inimigo_px | float | > 0 (cânone 22,5–69) | data file | `EnemyDef` |
| alcance_extra_px | float | ≥ 0 | data file | param do gatilho `corte_da_esquiva` (Modificadores R5; Conteúdo, Constantes escondidas: 9) |
| distância | float | ≥ 0 | calculated | centro a centro, depois do deslocamento (R3) |
| alvos_max_corte | int | ≥ 1 ou vazio | data file | teto (R8) |

**Output Range:** mínimo 32,5 px. Comparação `≤` (inclusiva, cânone), feita
como `distância² ≤ alcance²`, sem epsilon, no float do motor. As posições da
AC-18 são exatas em float32 e fazem o contrato da borda. Cada inimigo, no máximo
uma vez por esquiva. O teste só olha a posição no fim de cada passo (aviso MV6).
**Example:** Eco Perdido (24 px): 27 + 24 + 9 = 60 px. Estilhaço Vivo (31,5):
67,5 px. Anomalia Maior (63): 99 px.

### F6. Dano do Corte da esquiva

The dash_cut_damage formula is defined as:

`dano_corte = total_gatilho × M_ataque` ; `M_ataque = max(0, 1 + P_todo +
P_ataque) × Π_incond`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| total_gatilho | float | > 0 (com 0, o Corte não acontece) | calculated | total de `corte_da_esquiva` (Corte Fantasma Comum: 10) |
| P_todo | float | ≥ −1 | calculated | Σ % de `dano_todo`, com `vida_abaixo` se valer |
| P_ataque | float | ≥ −1 | calculated | Σ % do grupo Ataque |
| Π_incond | float | ≥ 0 | calculated | multiplicadores incondicionais do portador; hoje 1 |
| M_ataque | float | ≥ 0 | calculated | F2 do Modificadores **sem** `apos_esquiva` nem `enesimo_acerto` |

**Output Range:** ≥ 0, sem teto (F2 do Modificadores).

- Com M = 0, o dano é 0, mas empurrão e Sangramento seguem (cânone:
  `damageEnemy` aplica os dois com dano 0). O Combate confirma.
- Dano por esquiva = `dano_corte × min(n_atingidos, alvos_max_corte)`.
- O cânone (`engine.ts:848`) não aplica `empowerTicks` ao Corte, o que confirma a
  R12 do Modificadores.

**Example:** Corte Comum 10, +20% `dano_todo`, +25% Ataque, Fundo do Poço +40%
(Vida < 50%): M = 1 + 0,60 + 0,25 = 1,85 → 18,5. Sem Vida baixa: 14,5. Sem
bênção: 10 (um Eco Perdido de 30 de Vida cai em 3 esquivas).

### F7. A esquiva não atravessa obstáculo

The dash_tunnel_safety formula is defined as:

`d_passo < r_obs_min + raio_jogador_px` ; `margem = (r_obs_min +
raio_jogador_px) / d_passo`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| d_passo | float | 5–50 px | calculated | F2 |
| r_obs_min | float | > 0 | calculated | menor raio de obstáculo em todos os dados de Câmaras |
| raio_jogador_px | float | 10–50 | data file | `MovementTuning` |
| margem | float | > 0 | calculated | quantas vezes o passo cabe no raio combinado |

**Output Range:** margem > 1 é seguro.

- Prova: com passo menor que o raio combinado, o ponto de chegada fica no mesmo
  semiplano do de saída, e o empurrão da R10 devolve o jogador ao lado de onde
  veio.
- Com passo ≥ raio combinado, já dá para atravessar.
- A parede é sempre segura, porque a posição é presa ao retângulo.

**Example:** cânone, 22,5 px:

- sala comum, r 28 u = 42 px (`engine.ts:283`): 69 / 22,5 = **3,07**;
- pilar de chefe, 51 px: 3,47;
- santuário, 63 px: 4,0;
- pior canto das faixas (3000 px/s, raio 10, obstáculo 42): 52 / 50 = 1,04.

### Validação do `MovementTuning`

Somam-se às faixas do V2 do Conteúdo. Os **erros** chegam à tela de erros do
catálogo, e a run não começa. Os **avisos** ficam só no registro de validação, e
a run começa.

| Regra | Tipo | Condição | Por quê |
|---|---|---|---|
| MV1 | erro, cruzada com Câmaras | `velocidade_esquiva_pxs / 60 ≥ r_obs_min + raio_jogador_px` (F7); **aviso** com margem < 2 | a esquiva atravessaria obstáculos. Fica com Câmaras até existir a classe de câmara (Cena OQ9) |
| MV2 | erro | `R ≤ D + E` | invulnerabilidade perpétua esquivando sem parar; **aviso** se `(D + E) / R > 0,5` (cânone 0,286) |
| MV3 | regra | `inv_esquiva = passos(duracao) + passos(extra)`, soma de inteiros | pode dar 1 passo a menos que passos(soma); a soma de inteiros é a canônica |
| MV4 | faixa | `raio_jogador_px` de 10 a **50** | diâmetro < vão mínimo de 105 px entre obstáculos do cânone (70 u, `engine.ts:286`); a checagem contra o vão real é do GDD de Câmaras |
| MV5 | erro | `alvos_max_corte` = 0 ou negativo | 0 seria ambíguo; "sem teto" é vazio |
| MV6 | aviso, cruzada com Inimigos e Bênçãos | `d_passo > 2 × (raio_jogador_px + r_inimigo_min + alcance_extra_px)`. `r_inimigo_min` = menor `raio` dos `EnemyDef` do catálogo; `alcance_extra_px` = param do gatilho `corte_da_esquiva` (igual entre fontes, V11 do Conteúdo). Sem gatilho no catálogo, a regra não roda | o Corte pularia inimigos pequenos; hoje 22,5 < 117 (2 × (27 + 22,5 + 9)) |
| MV7 | aviso | `dist_total` fora de [2 × `raio_jogador_px`, 600 px] | esquiva menor que o corpo, ou maior que ~⅓ da tela |
| MV8 | aviso, cruzada com o `InputTuning` | `D > input_buffer_steps` (10) | um toque dado no começo de uma esquiva longa vence antes do fim dela, e a esquiva encadeada se perde (R5). Decisão do usuário, 2026-11-08: a faixa de `duracao_esquiva_s` fica 0,05–0,5 para experimentação |

`invuln_extra_s` é declarado como campo que **aceita zero** (F7 do Conteúdo).
Os outros campos de tempo têm mínimo > 0.

## Edge Cases

> `systems-designer` não consultado: modo Lean. Revisar manualmente.

**Esquiva e buffer**

- **Se chegar um toque de esquiva com 0 cargas:** a esquiva não sai, e o toque
  fica no buffer até o prazo acabar (Input). O sistema emite
  `esquiva_sem_carga` **uma vez por toque novo** (não a cada passo em que o toque
  segue no buffer), e o HUD pisca o indicador de cargas (decisão do usuário,
  2026-11-08). Se uma carga voltar antes do prazo, a esquiva sai nesse passo.
- **Se chegar um toque durante uma esquiva:** fica no buffer e sai no passo
  seguinte ao fim, se ainda houver prazo e carga (R5). Duas esquivas seguidas
  ficam separadas por exatamente D passos.
- **Se chegar um toque durante uma esquiva e com 0 cargas:** `esquiva_sem_carga`
  sai no passo do toque, uma vez, e o toque fica no buffer (R5). Com M = 1, ele
  quase sempre vence antes de a carga voltar (R = 42 contra 10 de prazo).
- **Se outros botões forem tocados com a esquiva no buffer:** o buffer tem um
  contador único (Input F3), então um Ataque tocado renova o prazo do toque de
  esquiva também. Igual ao cânone; não é um "toque novo" de esquiva e não emite
  outro `esquiva_sem_carga`.
- **Se a esquiva for longa** (D > 10, aviso MV8): um toque dado nos primeiros
  passos vence antes do fim, e a esquiva encadeada não sai.
- **Se o toque e o hitstop caírem no mesmo passo:** o Movimento não roda no
  hitstop (R2). O toque fica congelado no buffer, com o prazo parado (Input R6),
  e a esquiva sai no primeiro passo vivo. **Hitstops não somam: vale o maior**
  (Combate R10; D-N1 fechado), então o atraso é o do maior hitstop do passo.
- **Se `mover` = 0 na hora da esquiva:** a direção é `mirar`, que nunca tem
  comprimento zero (Input R5). Com o mouse, o jogador esquiva em direção ao
  cursor; parado no gamepad sem alvo, a direção é para onde ele olha, e no
  último caso (0, −1).
- **Se `mover` for oposto à mira:** vale `mover` (cânone). Recuar esquivando
  enquanto se mira no inimigo é o uso esperado.

**Estados e interrupções**

- **Se vier hitstop, pausa ou Bênção no meio da esquiva:** a esquiva congela com
  a direção, os passos restantes e a lista do Corte, e continua do ponto em que
  parou quando o passo vivo volta. A invulnerabilidade também congela, porque o
  Combate conta passos vivos. A posição anterior fica igual à atual em cada
  passo congelado (R2), então o personagem fica parado na tela.
- **Se a pausa vier com um toque de esquiva no buffer:** a pausa é troca de
  contexto e esvazia o buffer (Input, Edge Cases; R10 do Input). O toque se
  perde, como na Bênção.
- **Se houver teleporte no meio da esquiva:** a esquiva é cancelada (R1). A
  invulnerabilidade que sobrou continua, porque é do Combate, e a carga gasta
  não volta.
- **Se a esquiva sair no mesmo passo em que o Combate iniciaria uma investida:**
  o Movimento roda antes (R3). A esquiva sai e marca "em esquiva", e o Combate
  não dispara golpe enquanto a consulta é verdadeira (cânone). O golpe fica no
  buffer ou segurado e sai no último passo da esquiva, quando a consulta já é
  falsa (R6).
- **Se a run terminar no meio da esquiva:** não acontece por dano que respeita a
  invulnerabilidade. Dano que a ignora (status no jogador, se existir) é do GDD
  de Efeitos de status. Se a run terminar por outra causa, o Input sai de Jogo
  (Morte ou Menu) e o Movimento para, com `passo_congelado()` (R2).

**Cargas**

- **Se as cargas chegarem ao máximo pela R9 do Modificadores** (o atributo sobe
  ou desce): o
  contador de recarga **zera** (decisão do usuário, 2026-11-08; divergência
  deliberada do cânone, que guardava o progresso). Com c = M, o contador é
  sempre 0, como o F3 diz.
- **Se `cargas_esquiva` descer no meio da esquiva:** a esquiva continua. Só as
  cargas restantes são cortadas.
- **Se `cargas_esquiva` descer e as cargas continuarem abaixo do novo máximo:**
  o contador segue de onde estava (R7).
- **Se `cargas_esquiva` mudar durante a Bênção:** vale no primeiro passo vivo
  depois dela (R3, item 0).
- **Se `cargas_esquiva` for muito alto:** o Modificadores só tem piso, não
  teto. A quantidade de chevrons que o HUD comporta é pergunta aberta (Open
  Questions).
- **Se `cargas_esquiva` cair abaixo de 1:** o piso 1 é do Modificadores (R2,
  Edge Cases). O jogador sempre tem uma esquiva.

**Velocidade e deslocamento**

- **Se `valor(velocidade)` = 0** (um debuff de −100% no futuro): o jogador não
  anda, mas esquiva com a velocidade cheia (R6). A fuga sempre responde (P3).
- **Se a esquiva for contra a parede:** a posição é presa ao retângulo (R10) e o
  jogador fica parado na parede. Os passos da esquiva continuam correndo e a
  invulnerabilidade vale inteira. A esquiva não termina antes por bater na
  parede (cânone).
- **Se a esquiva for contra um obstáculo:** a cada passo o jogador é empurrado
  para fora pela normal (R10) e desliza pela borda. Ele não atravessa, por
  causa do MV1/F7.
- **Se o jogador continuar dentro de um obstáculo depois da passada de
  colisão** (só possível com um layout que viole o vão mínimo do MV4): o
  próximo passo resolve de novo. Garantir o vão é do GDD de Câmaras.
- **Se o analógico estiver logo acima da zona morta:** anda devagar,
  proporcional ao módulo (F1). A esquiva sai sempre com a velocidade cheia.

**Corte da esquiva**

- **Se o inimigo estiver surgindo:** não pode ser cortado. Se ele termina de
  surgir no meio da esquiva e está no alcance, é cortado nesse passo, desde que
  ainda não esteja na lista.
- **Se houver mais inimigos no alcance do que `alvos_max_corte` no mesmo
  passo:** são cortados os primeiros, na ordem estável da lista de alvos (IA).
- **Se o Corte matar:** a morte e o hitstop de abate são do Combate (varredura
  de mortes). Se o hitstop congelar a esquiva, ela continua depois (acima).
- **Se o mesmo inimigo for atravessado em esquivas seguidas:** a lista esvazia a
  cada esquiva (R5), então ele é cortado de novo (cânone). É o que o
  `alvos_max_corte` calibra (D-W6).
- **Se M = 0:** dano 0, mas o empurrão e o Sangramento continuam (F6).
- **Se o gatilho sumir** (a fonte foi removida) no meio da esquiva: o Corte para
  no passo seguinte.

**Conflitos com outros GDDs:** nenhum. Os pisos (`cargas_esquiva` ≥ 1,
`velocidade` ≥ 0) são respeitados, e o prazo do buffer congelado no hitstop é o
da R6 do Input.

## Dependencies

**Depende de (upstream)**

| Sistema | Tipo | O que vem de lá | Sem ele |
|---|---|---|---|
| Input e controle | Forte | `mover` (0–1), `mirar`, esquiva no buffer (Input R2, R5, R6) | Não há comando |
| Cena 3/4 e câmera | Forte | Plano de jogo em px, sem eixo de altura (Cena R3); interpolação e reset no teleporte (Cena R7) | Posição sem referencial, e o render engasga |
| Modificadores e atributos | Forte | `valor(velocidade)`, `valor(cargas_esquiva)` com piso 1, `gatilhos(corte_da_esquiva)`, F2 (M do grupo Ataque) | Velocidade e cargas sem base; Corte impossível |
| Conteúdo orientado a dados | Forte | `MovementTuning`, `WeaponDef.velocidade` em px/s (F2), F7 (passos), tela de erros para MV1–MV8; `InputTuning` (`input_buffer_steps`) para o MV8 | Números no código, o que a regra do projeto proíbe |
| Combate núcleo | Forte, **por contrato** | Consultas: em recuperação, investida ativa e `d` (vetor), `contexto_de_dano` (só Vida atual e máxima); hitstop ativo, lido pelo orquestrador (R2). Pede `deslocar(v)` para o passo de apoio (R9). Executa os pedidos: cancelar, `garantir_invulneravel` (descontado no início de cada passo vivo seguinte, F4), aplicar Corte, abrir `apos_esquiva`. Golpe e Selo respeitam a consulta "em esquiva" (R6) | A esquiva sai sem invulnerabilidade e sem cancelar; o Corte não aplica dano |
| Câmaras e ondas | Suave, **por contrato** | Retângulo jogável, obstáculos (círculos), `teleportar`; vão mínimo ≥ diâmetro do jogador (MV4); `r_obs_min` para o MV1 | Câmara padrão de 1920×1080 sem obstáculos (a mesma regra da Cena) |
| IA de inimigos e elites | Suave, **por contrato** | A **consulta de alvos** que o Input já define (inimigos fora do spawn, ordem estável), acrescida do raio de cada um | O Corte não corta ninguém; o resto funciona |

**Ciclo resolvido por contrato:** o Combate depende do Movimento (posição, "em
esquiva", pedidos), e o Movimento depende do Combate (recuperação, investida,
hitstop, invulnerabilidade). Os dois lados se ligam como Input ↔ IA:

- o **Movimento define a interface** de pedidos e de consultas;
- o Combate a implementa, e ela é injetada (R12);
- nenhum dos dois chama a lógica interna do outro.

**É dependência de (downstream)**

| Sistema | Tipo | O que recebe |
|---|---|---|
| Combate núcleo | Forte | Posição do jogador, "em esquiva", `esquiva_iniciada`, pedidos (R5, R8) |
| Cena 3/4 e câmera | Forte | Posição atual e anterior (alvo da câmera, interpolação), aviso de teleporte |
| HUD | Suave | Cargas atuais e máximo, progresso da recarga, eventos `esquiva` e `esquiva_sem_carga` |
| Selo e Fluxo | Suave | "em esquiva": o Selo não sai durante a esquiva (cânone) |
| IA de inimigos e elites | Suave | Posição do jogador (alvo) |
| Pipeline visual / Feedback de combate (VFX) / Áudio | Suave | Evento `esquiva`, posição |
| Bênçãos | Indireta (via Modificadores) | Corte Fantasma, Penumbra e bênçãos de carga extra chegam como modificadores e gatilhos |

**Bidirecionalidade:**

- Input, Cena, Modificadores e Conteúdo já listam o Movimento. A Cena descreve o
  que entrega como "plano de jogo em px (R3), limites da câmara". O retângulo da
  câmara vem do GDD de Câmaras, e a Cena só tem os limites de tamanho. Não há
  contradição.
- Combate, HUD, Selo, IA e Câmaras ainda não existem. Cada um, ao ser escrito,
  deve listar "Movimento e esquiva" em Dependencies e honrar o contrato acima. O
  índice já tem o Movimento no Depends On do Combate e do HUD.
- O ciclo Movimento ↔ Combate ainda não está em "Circular Dependencies" do
  índice (Open Questions).

## Visual/Audio Requirements

> `art-director` consultado (modo Lean). `audio-director` não consultado: o GDD
> de Áudio ainda não existe, e os requisitos de som são provisórios. Escolhas de
> animação, direção do sprite e HUD: usuário, 2026-11-08.

**Regra que governa tudo:** a esquiva é **ação do jogador**: osso e tinta,
contorno **tracejado e fino**. Ela nunca usa a borda grossa, o preenchimento que
cresce, o magenta ou o valor L* ≥ 88 do telégrafo (Art Bible §1, §4.2, §4.3).

**V1. Andar (Livre)**

- **Parado:** Idle de 6 quadros em loop, um por arma. **Andando:** Corrida de 8
  quadros em loop, compartilhada (§5.8; ação `run`, §8.2).
- **Direções:** 8, sendo 5 desenhadas e 3 espelhadas. O sprite olha para a
  **mira** (R4). Andar de costas usa a Corrida tocada ao contrário no MVP, sem
  asset novo (decisão do usuário).
- **Analógico devagar (F1):** a Corrida toca mais devagar, proporcional a
  min(1, |`mover`|).
- **Parar:** volta ao Idle no passo em que `mover` é zero, sem quadro de freio.
- **Mancha de contato:** tinta com borda irregular, **nunca elipse limpa**,
  porque o círculo no chão é exclusivo do telégrafo (§5.5, §3.4).
- **Camadas:** o personagem fica em `objetos + personagens (y-sort)`, ordenado
  pelo pé (Cena R4, R5); a mancha fica em `sombras de contato`.

**V2. Início da esquiva (evento `esquiva`)**

- **Sem antecipação:** o primeiro quadro visível já é a pose esticada, porque a
  esquiva se desloca no passo do toque (R5). O P3 vence os 1–2 quadros de
  antecipação do §5.8.
- **Quadros** (decisão do usuário):
  - 2 quadros durante o deslocamento: a pose esticada mantida, mais 1;
  - 3 ou 4 quadros de saída já no estado Livre, que qualquer ação corta (andar,
    golpe, nova esquiva).
  - As imagens residuais mostram a velocidade. Isso pede uma linha nova no §5.8
    do Art Bible (Open Questions).
- **Direção do sprite:** durante a esquiva, ele olha para a direção da esquiva,
  quantizada em 8, e volta para a mira no fim (decisão do usuário).
- **Relógio da animação:** a animação conta D passos vivos a partir do evento
  `esquiva`, e não a consulta "em esquiva", que já é falsa no último passo de
  deslocamento (R6). Assim a saída não começa um passo antes do último
  trecho.

**V3. Durante a esquiva e a invulnerabilidade**

- **O que se vê:** 2–3 imagens residuais em osso tracejado ao longo do trajeto.
  Nunca fiapos de tinta, que são do Eco (§5.8, §3.2). Valor ≤ 82 (§4.2).
- **A invulnerabilidade é lida nas imagens residuais.**
  - Elas duram D + E passos vivos, ou seja 12, lidos do `MovementTuning`.
  - A última some no passo em que a invulnerabilidade acaba.
  - Os 3 passos extras **não** têm sinal próprio: são folga, e sinalizá-los
    convida a jogar no limite do quadro.
- **Proibido no corpo:** piscar, tingir ou usar a inversão de silhueta, que é
  exclusiva de "jogador atingido" (§5.5).
- **As imagens são geradas por passo, não por distância.** Contra a parede, elas
  se empilham no próprio jogador, e a leitura da invulnerabilidade continua.
- **Hitstop, pausa e Bênção:** as imagens congelam junto com a esquiva.
  **Teleporte:** elas são apagadas.
- **Camada:** `objetos + personagens (y-sort)`, cada uma no y do pé onde foi
  deixada, **sem** mancha de contato.

**V4. Fim da esquiva:** volta ao Idle ou à Corrida na direção da mira. Todo
quadro de saída precisa parecer aceitável se for cortado (§5.8), porque uma
esquiva encadeada sai exatamente D passos depois.

**V5. `esquiva_sem_carga`**

- **No mundo:** nada, sem gesto de falha.
- **No HUD** (requisito **provisório**, Open Questions):
  - os chevrons vazios dão **uma** reação de forma: um tremor lateral de ~4 px
    em 2 quadros "em dois" (§7.7);
  - nunca em loop, nunca em magenta e nunca como flash de luminância (o limite é
    3 flashes por segundo, §7.7);
  - no máximo 1 reação a cada 0,2 s;
  - camada `UI`.

**V6. Corte da esquiva:** deste sistema, só a detecção (R8). O flash de acerto,
o Sangramento e o empurrão são do Combate, do VFX e de Status. O Corte usa as
mesmas imagens residuais, sem variante visual.

**V7. Cargas no HUD** (segue o §7.8 e o §7.7, sem redesenho)

- chevrons de 32 px logo abaixo da Vida, em osso: cheio é preenchido, vazio é só
  contorno;
- o chevron que está recarregando enche de baixo para cima, com a fração do
  contador (F3), um de cada vez (R7), e congela fora dos passos vivos;
- quando o máximo muda, os chevrons aparecem ou somem sem animação de destaque;
- camada `UI`.

**A1. Áudio (requisito)**

- **`esquiva`:**
  - um risco seco de tinta, nada mágico, no passo em que a esquiva sai;
  - se o toque caiu no hitstop, o som sai no primeiro passo vivo;
  - uma vez começado, um hitstop posterior não o corta;
  - **nunca encobre a deixa sonora do telégrafo** (§4.7).
- **`esquiva_sem_carga`:** negação curta e abafada, distinta da esquiva, de
  prioridade menor, com o mesmo limite de 0,2 s.
- **Passos ao andar:** opcionais, de prioridade baixa; param no hitstop.
- **Corte:** nenhum som deste sistema.

**AC1. Acessibilidade**

- **Redução de movimento** (§7.9 nº 5; Cena R8): nada muda, porque animação e
  imagens residuais são informação de jogo. A esquiva não pede zoom.
- **Tremor de câmera** (§7.9 nº 3): a esquiva não manda chute nem tremor.
- **Daltonismo** (§4.7): nada depende de matiz.
  - Esquiva × telégrafo: tracejado fino contra borda grossa com preenchimento,
    e valor ≤ 82 contra ≥ 88.
  - Chevron cheio × vazio: preenchido contra contorno.
- **Escala de UI** (§7.9 nº 1) e **Alto contraste** (§7.9 nº 10): os chevrons
  seguem as duas opções. No alto contraste, contorno sólido de 3 px.

## Game Feel

- **Latência:** a esquiva sai **no passo do toque**. O Input amostra antes de
  todo sistema, e o Movimento é o primeiro consumidor (Input R2, R6). Do toque
  ao deslocamento há 1 passo de física (≤ 16,7 ms), mais o atraso visual de até
  1 passo da interpolação (Cena R7), que é aceito.
- **Andar sem massa física:** sem aceleração nem desaceleração. O personagem
  para no passo em que `mover` zera (6,45 px/passo na Lâmina). O peso vem da
  animação, não da física.
- **Esquiva curta e decidida:** 0,15 s e 202,5 px, cerca de 3,75 diâmetros do
  corpo. O pico de 1350 px/s é ~3,5× o andar. A invulnerabilidade de 0,2 s cobre
  a esquiva e mais 0,05 s de folga.
- **A fuga sempre responde:** a esquiva cancela a investida e a recuperação do
  golpe (R5). Ela não cancela outra esquiva: o toque espera e a próxima sai
  exatamente 9 passos depois.
- **Golpe com peso, sem prender:** durante a recuperação (≤ 12 passos no
  cânone, regra do Combate) o personagem anda a 45%, e a esquiva corta a
  recuperação.
- **Ritmo:** uma esquiva a cada 0,7 s, cerca de uma por respiração. As cargas
  extras dão rajada sem mudar o ritmo sustentado (F3, F4).
- **Hitstop:** a esquiva congela com o mundo, e o buffer garante que o toque não
  se perde (Input F3).
- **Afinar sem código:** todos os números estão no `MovementTuning` e recarregam
  entre runs em debug (Conteúdo, Game Feel).
- **Alvo de playtest (P3):** nenhuma morte por um golpe que chega quando havia
  carga e um toque de esquiva registrado nos 10 passos anteriores. Se acontecer,
  é bug, não balanceamento. O log de debug registra os toques de esquiva e as
  cargas por passo para conferir.

## UI Requirements

- **Sem tela própria.** O sistema só fornece dados ao HUD: cargas atuais e
  máximo, progresso da recarga (fração 0–1) e os eventos `esquiva` e
  `esquiva_sem_carga`.
- **Indicador de cargas:** chevrons logo abaixo da Vida (Art Bible §7.8). O
  layout e o estilo são do GDD de HUD. A reação a `esquiva_sem_carga` é
  provisória (Visual/Audio V5).
- **A invulnerabilidade não aparece no HUD.** Ela é lida no corpo, pelas imagens
  residuais (V3).

> **📌 UX Flag — Movimento e esquiva:** este sistema alimenta o HUD. No
> Pre-Production, rode `/ux-design` para o HUD antes das epics; as stories de UI
> citam `design/ux/hud.md`, não este GDD.

## Cross-References

| Documento | Seção | Uso neste GDD |
|---|---|---|
| `design/gdd/input-e-controle.md` | R2, R5, R6, F3, Edge Cases | `mover`, `mirar`, esquiva só no buffer, ordem dos consumidores, prazo congelado no hitstop, toque sem carga |
| `design/gdd/cena-3-4-e-camera.md` | R3, R4, R5, R7, R8 | Plano em px, camadas e y-sort, interpolação e reset no teleporte, hitstop sem `time_scale`, impulsos de câmera |
| `design/gdd/modificadores-e-atributos.md` | R2, R4, R5, R9, R11, R12, R13, F2, Edge Cases | `velocidade` e `cargas_esquiva` com piso, `apos_esquiva`, `corte_da_esquiva` e M do grupo Ataque, cargas sobem e descem, consulta do portador |
| `design/gdd/conteudo-orientado-a-dados.md` | R1, V2, F2, F4, F7, Edge Cases › Constantes escondidas | `MovementTuning`, conversões de velocidade, distância e passos, params do Corte Fantasma, tela de erros |
| `design/gdd/gdd-cross-review-2026-11-06.md` | D-W6 | Corte na invulnerabilidade, resolvido pelo M só percentual e pelo `alvos_max_corte` |
| `design/gdd/gdd-cross-review-2026-11-06b.md` | D-N1 | Hitstops que se somam atrasam a esquiva guardada (dono: Combate) |
| `design/gdd/game-concept.md` | §3 (P3) | "a esquiva com invulnerabilidade sempre responde" |
| `design/art/art-bible.md` | §1, §3.4, §4.2, §4.3, §4.7, §5.5, §5.8, §7.7, §7.8, §7.9, §8.2 | Gramática das ações do jogador, animação, chevrons, acessibilidade |
| Khaeros `packages/action-core/src/engine.ts` | `:31–35`, `:72–73`, `:269–292`, `:556–598`, `:640–654`, `:778–865` | Constantes da esquiva, recuperação, obstáculos, `damageEnemy`, colisão, `updatePlayer` |
| Khaeros `packages/combat-rules/src/arenaContent.ts` | `ARENA_WEAPONS` | `moveSpeed` das armas |
| `docs/engine-reference/godot/modules/physics.md` | — | Lacuna: não cobre o `CharacterBody2D` (Open Questions) |

## Acceptance Criteria

> Proposta do `qa-lead` (consultado: modo Lean, seção de risco alto). As contas
> foram refeitas contra o cânone (`engine.ts:778–865`, só leitura). Tolerâncias e
> dono do dano do Corte: usuário, 2026-11-08.
>
> Evidência: **[L]** `tests/unit/movement/`; **[I]** `tests/integration/movement/`;
> **[UI]** screenshot em `production/qa/evidence/`; **[V]** Visual/Feel:
> screenshot em `production/qa/evidence/` com assinatura do lead; **[P]**
> desempenho; **[M]** manual, com testador, build e resultado registrados.
>
> Tolerância de posição: ±0,001 px em esquiva e em passo único; ±0,01 px em andar
> acumulado (o `Vector2` é float32; Open Questions); ±0,05 px na paridade.
> Dano e fração de recarga: ±0,001. Cargas, passos e contagens são exatos.
> A borda do Corte é exata (F5).
>
> Cada critério é independente: repete a fixture e o roteiro que usa, sem
> remeter a outro critério.
>
> Nada de seed nem de tempo real: tudo roda por passos e com dublês injetados
> (R12). Os contratos com Combate, Selo, Câmaras e IA são **provisórios**. Os
> critérios que dependem deles usam dublês que honram o contrato deste GDD, e
> devem ser rodados de novo com os sistemas reais quando os GDDs deles existirem.
>
> **Fixture padrão (FP):**
>
> - `MovementTuning` padrão (R11), que dá D = 9, E = 3, R = 42;
> - retângulo jogável (0, 0)–(1920, 1080), sem obstáculos; o centro do jogador
>   fica preso em [27, 1893] × [27, 1053];
> - jogador em (960, 540); `valor(velocidade)` = 387; M = c = 1; sem gatilho
>   `corte_da_esquiva`;
> - Combate dublê sem recuperação, sem investida e sem hitstop. Ele registra os
>   pedidos, honra `cancelar` no mesmo passo, faz `garantir_invulneravel` como
>   max e fornece `contexto_de_dano`;
> - Input dublê em Jogo, com `mover` (0, 0) e `mirar` (1, 0). "Toque em n" quer
>   dizer que a esquiva entra em `apertados_neste_passo` no passo n e fica no
>   buffer pelo prazo do Input F3 (10 passos);
> - lista de alvos vazia. "Eco" é um inimigo de raio 24.
>
> **Fixture do Corte (FP-Corte):** FP mais gatilho `corte_da_esquiva` com total
> 10 e params `alcance_extra_px` 9, `empurrao` 360 e `sangramento` 1; portador
> sem modificadores de dano (M_ataque = 1).
>
> Os passos são numerados a partir de 0. "Após n" é o estado ao fim do passo n.
> "Em esquiva no passo n" é o valor da consulta lida por um dublê que roda
> depois do Movimento no passo n (R6).

**A. Dados e injeção**

- **AC-01 [L] R11/F2/F3/F4.** Na FP: D = 9, E = 3, R = 42, `d_passo` = 22,5,
  `inv_esquiva` = 12, `dist_total` = 202,5. Com `duracao_esquiva_s` = 0,14:
  D = 8 e `dist_total` = 180,0 (não 189).
- **AC-02 [L] R12.** O Movimento é criado num teste gdUnit4 sem SceneTree e sem
  autoload, só com os dublês da FP-Corte. O roteiro é o arquivo versionado
  `tests/unit/movement/fixtures/roteiro_determinismo.json` (1000 passos de
  `mover`, `mirar`, toques, hitstop e um Eco andando). Duas instâncias novas do
  Movimento, cada uma com dublês novos, dão sequências de posição, cargas e
  eventos idênticas bit a bit.

**B. Andar**

- **AC-03 [L] R4/F1.** FP, `mover` (1, 0): após 0 o jogador está em
  (966,45; 540) ±0,001; após 59, em (1347; 540) ±0,01.
- **AC-04 [L] F1.** Deslocamento de um único passo (±0,001):

  | `mover` | `valor(velocidade)` | Em recuperação | Deslocamento |
  |---|---|---|---|
  | (0,6; 0,8) | 387 | não | (3,87; 5,16) |
  | (0,3; 0,4) | 387 | não | (1,935; 2,58) |
  | (1; 0) | 433,44 | não | (7,224; 0) |
  | (1; 0) | 387 | sim (0,45) | (2,9025; 0) |
  | (0,5; 0) | 387 | sim | (1,45125; 0) |
  | (1; 0) | 387 | sim, `fator_recuperacao` 0 | (0; 0) |
  | (1; 0) | 387 | sim, `fator_recuperacao` 1 | (6,45; 0) |
  | (0; 0) | 387 | não | (0; 0) |
  | (1; 0) | 0 | não | (0; 0) |
- **AC-05 [L] R4.** `mover` (−1, 0) nos passos 0–9 e (0, 0) no passo 10: a
  posição após 10 é igual à posição após 9 (exata), porque não há inércia. O
  Movimento não escreve `mirar` (o dublê continua em (1, 0)).

**C. Início e deslocamento da esquiva**

- **AC-06 [L] R5/R6/F2.** FP, `mover` (1, 0) só no passo 0, toque em 0:
  - após k (k = 0…8), x = 982,5 + 22,5k; após 8, x = 1162,5;
  - o deslocamento de esquiva acontece nos passos 0–8;
  - "em esquiva" é verdadeiro nos passos 0–7 e falso a partir do 8 (R6: no
    último passo a consulta já é falsa);
  - após 9, o jogador está em (1162,5; 540);
  - a lista de alvos está vazia: a câmara limpa também esquiva.
- **AC-07 [L] R5.** FP, `mover` (1, 0) só no passo 0, toque em 0: tudo isto
  acontece **no passo 0, uma vez cada e nesta ordem**, e nada se repete nos
  passos 1–8:
  - cargas 1 → 0;
  - esquiva restante 8 ao fim do passo 0 e 0 ao fim do 8;
  - pedidos `cancelar`, `garantir_invulneravel(12)` e `esquiva_iniciada`;
  - a esquiva sai do buffer;
  - o evento `esquiva` é emitido.
- **AC-08 [L] R5.** Direção (deslocamento do passo 0, ±0,001):

  | `mover` | `mirar` | Deslocamento |
  |---|---|---|
  | (0; 0) | (0; −1) | (0; −22,5) |
  | (0,2; 0) | (1; 0) | (22,5; 0): velocidade cheia com analógico fraco |
  | (−1; 0) | (1; 0) | (−22,5; 0): `mover` vence a mira |
  | (0,6; 0,8) | (1; 0) | (13,5; 18); total após 8: (121,5; 162) |

  Se `mover` passa a (0, 1) no passo 4, os passos 4–8 continuam em (22,5; 0): a
  direção fica fixada no início.
- **AC-09 [L] R5.** Esquiva **segurada** nos passos 0–30, sem nunca aparecer em
  `apertados_neste_passo`: nenhuma esquiva e nenhum evento.
- **AC-10 [L] R6.** Com `valor(velocidade)` = 580,5 (+50%) e com 0, a esquiva é
  idêntica à da AC-06 (202,5 px). Com 0, o jogador não anda mas esquiva.
- **AC-11 [L] F4/MV3.**
  - `invuln_extra_s` = 0 → o pedido é `garantir_invulneravel(9)`.
  - `duracao_esquiva_s` = 0,158 e `invuln_extra_s` = 0,058 → o pedido é
    `garantir_invulneravel(12)`, soma de inteiros 9 + 3, e **não** 13, que seria
    `passos(0,216)`.
- **AC-12 [L] R5/R3 — esquiva sem carga.** FP, toque em 100 (a esquiva sai;
  c = 0):
  - toque em 135 com c = 0: não sai esquiva, e `esquiva_sem_carga` é emitido 1
    vez no passo 135 e nenhuma vez nos passos 136–137;
  - toque novo em 138: segundo evento no passo 138, e só ele;
  - a carga volta no passo 142, e a esquiva sai **nesse mesmo passo** (a
    recarga vem antes do início). O toque de 138 ainda está no buffer em 142,
    porque o toque novo renova o prazo (Input F3: contador único);
  - depois disso, nenhum `esquiva_sem_carga`.

  Variante: FP com toque em 0 e outro em 10 (c = 0). O do passo 10 emite 1
  evento; o buffer vence antes do passo 42, e nenhuma esquiva sai no 42.
- **AC-13 [L] R5 — esquiva encadeada.** FP com M = c = 2, `mover` (1, 0) nos
  passos 0–18, toques em 0 e em 4:
  - `esquiva_iniciada` sai nos passos 0 e 9: separação de exatamente D = 9;
  - nenhum início nos passos 1–8;
  - após 8, x = 1162,5; após 17, x = 1365; após 18, x = 1371,45, já andando;
  - c = 0 após 9.
- **AC-49 [L] R5 — toque durante a esquiva, sem carga.** FP (M = 1), `mover`
  (0, 0), toques em 0 e em 4:
  - a esquiva sai no 0 (c = 0);
  - `esquiva_sem_carga` é emitido 1 vez, no passo 4, e nenhuma vez nos passos
    5–9;
  - nenhuma esquiva sai nos passos 9–42: o toque de 4 vence o prazo no buffer
    antes de a carga voltar no 42.

**D. Cargas e recarga**

- **AC-14 [L] R7/F3.** M = 1, toque em 100: c = 0 nos passos 100–141, e c = 1 a
  partir do 142 (R passos depois). O contador fica em 0 a partir do 142.
- **AC-15 [L] F3 — gastar não zera o contador.** M = c = 3, toques em 0, 9 e 18
  com `mover` (0, 0):
  - c = 0 após 18;
  - c = 1 no passo 42, 2 no 84 e 3 no 126 (T_cheio = 3 × 42 − 18 = 108 a partir
    do 18);
  - a recarga conta durante as esquivas;
  - o contador fica em 0 a partir do 126.
- **AC-16 [L] R7 — o atributo muda.**
  - (a) M = c = 1, M sobe para 2: c = 2 na hora, contador 0.
  - (b) M = c = 2, toque em 0 (c = 1), M sobe para 3 antes do passo 21: c = 2 na
    hora, o contador mantém p = 20, e c = 3 no passo 42.
  - (c) **Divergência do cânone.** M = c = 2, toque em 0 (c = 1), M desce para 1
    antes do passo 21: c = 1 = M e o contador **zera**. Depois, toque em 30
    (c = 0): a carga volta no passo **72**. O cânone a devolveria no 52.
  - (d) M = c = 3, toque em 0 com `mover` (1, 0) só no passo 0, M desce para 1
    antes do passo 3: c = 1 e a esquiva continua até o 8 (x = 1162,5).
- **AC-17 [L] R7.** No começo da run, c = M (com M = 2, c = 2). FP (M = 1),
  toque em 0: após o passo 15, c = 0 e p = 15. `teleportar((400; 300))` entre
  os passos 15 e 16 deixa c = 0 e p = 15, e a carga volta no passo 42.
- **AC-50 [L] R3/R7 — o máximo muda na Bênção.** FP (M = c = 1), toque em 0
  (c = 0); Input em Bênção nos passos 10–20, e durante ela `cargas_esquiva`
  sobe para 2:
  - nos passos 10–20 o Movimento não roda: c = 0 e p = 9;
  - no passo 21, item 0 da R3: M = 2 e c = 1 (ganha a diferença); o contador
    segue, porque c < M;
  - a próxima carga volta no passo 53 (42 + 11 passos congelados), e então
    c = 2 e o contador zera.

**E. Corte da esquiva**

> Base deste bloco: FP-Corte, com `mover` (1, 0) só no passo 0 e toque em 0
> (esquiva para +x), salvo quando o critério diz outra coisa.

- **AC-18 [L] R8/F5 — o alcance é inclusivo.**
  - Eco em (1042,5; 540): cortado no passo 0, a distância de exatamente 60,000.
  - Eco em (1005; 600): cortado no passo 1.
  - Eco em (1005; 600,001): nunca é cortado.
  - Inimigo de raio 31,5 em (1050; 607,5): cortado no passo 3 (alcance 67,5).
- **AC-19 [L] R8.** O Eco em (1042,5; 540) fica no alcance nos passos 0–5 e gera
  **um** pedido `aplicar_corte`, com dano 10, empurrão 360 na direção (1, 0) e
  Sangramento 1.
- **AC-20 [L] R8.**
  - Com total 0, ou sem gatilho: nenhum pedido.
  - Se o gatilho some antes do passo 3, um Eco em (1050; 600), que seria cortado
    no 3, não é cortado.
  - Andar através de um Eco não gera pedido.
- **AC-21 [L] R8/R3 — o Corte vem antes da colisão.** Jogador em (1890; 540), Eco
  em (1912,5; 600), esquiva para +x:
  - o Eco é cortado no passo 0, porque a distância antes da colisão é 60,0
    (depois dela seria 63,09);
  - após 0, o jogador está em (1893; 540).
- **AC-22 [L] R8 — teto.** Ecos B (982,5; 500), A (982,5; 580) e C (982,5; 540),
  nesta ordem na lista:
  - sem teto: 3 pedidos no passo 0, na ordem B, A, C;
  - com `alvos_max_corte` = 2: pedidos para B e A no passo 0, e C não é cortado
    nesta esquiva.
- **AC-23 [L] R8 — esquivas seguidas.** M = c = 2, Eco em (1042,5; 540), toque em
  0 com `mover` (1, 0), toque em 4 e `mover` (−1, 0) no passo 9:
  - pedidos para o Eco no passo 0 e no passo 11 (x = 1095, distância 52,5);
  - a lista está vazia no início da segunda esquiva.
- **AC-24 [L] F6 — o Movimento calcula o dano.** Portador real de Modificadores,
  em memória; o Combate dublê fornece `contexto_de_dano` com Vida 40/100 (abaixo
  de 50%) ou 60/100:

  | Modificadores ativos | Vida | Dano no pedido |
  |---|---|---|
  | `dano_todo` +20%, `dano_vida_baixa_pct` +40%, Ataque +25%, `dano_apos_esquiva` com a janela aberta, `dano_enesimo_acerto` ativo | 40/100 | 18,5 |
  | os mesmos | 60/100 | 14,5 |
  | nenhum | — | 10 |
  | Ataque −100% (M = 0) | — | 0, e o pedido **ainda leva** empurrão 360 e Sangramento 1 |
- **AC-25 [L] R8 — inimigo surgindo.** A lista injetada já vem filtrada pela IA.
  - Eco em (1042,5; 540) ausente da lista nos passos 0–1 (surgindo) e presente a
    partir do 2: cortado no passo 2.
  - Ausente em todos os passos: nenhum pedido.
- **AC-26 [L] R8 — o Corte não é golpe.** FP-Corte, Eco em (1042,5; 540),
  esquiva para +x: nos passos 0–8 o Movimento só envia `aplicar_corte` ao
  Combate dublê (fora `cancelar`, `garantir_invulneravel` e
  `esquiva_iniciada` no passo 0): nenhum pedido de hitstop, acerto, Fluxo ou
  `golpe_*`. Provisório: confirmar com o Combate real que o Corte não conta
  acerto.
- **AC-51 [L] R8 — contexto do dano.** FP-Corte com `dano_apos_esquiva` +50%
  ativo no portador. O Combate dublê abre a janela `apos_esquiva` no
  `esquiva_iniciada` e devolve em `contexto_de_dano` só Vida 60/100. Eco em
  (1042,5; 540): o pedido do passo 0 leva dano 10,000 ±0,001, e o contexto
  passado a `multiplicador_de_dano` tem `apos_esquiva` = falso e
  `enesimo_acerto` = falso.

**F. Investida, colisão e teleporte**

- **AC-27 [L] R9/R3.** Investida ativa com d = (12, 0) nos passos 0–4 e `mover`
  (0, 1):
  - após 4, o jogador está em (1020; 540): só a investida desloca;
  - no passo 5, já sem investida, ele anda até (1020; 546,45).
- **AC-28 [L] R5/R9 — a esquiva cancela.**
  - Investida ativa com d = (12, 0) a partir do passo 0, `mover` (0, 0), toque
    em 2:
    - após 1, x = 984;
    - no passo 2 há 1 `cancelar`, e o deslocamento é só 22,5, sem os 12 da
      investida: x = 1006,5;
    - após 10, x = 1186,5.
  - Em recuperação, toque em 0: há 1 `cancelar`, e a esquiva anda 22,5 por
    passo, sem o fator 0,45.
- **AC-58 [L] R9 — `deslocar(v)`.** FP, `mover` (0, 0):
  - no passo 0, depois do Movimento, o Combate dublê pede
    `deslocar((10,5; 0))`: após 0, atual = (970,5; 540) e anterior =
    (960; 540);
  - com o obstáculo O (1000; 540; r 42) e o jogador em (925; 540), o mesmo
    pedido leva a 935,5, e a colisão devolve a (931; 540);
  - cargas, contador de recarga e esquiva restante não mudam.
- **AC-29 [L] R10.** Obstáculo O em (1000; 540), r = 42:
  - Jogador em (931; 540) com `mover` (1, 0): após 0 está em (931; 540). Ele vai
    a 937,45 e é empurrado de volta.
  - Teleporte para (1000; 540) e um passo com `mover` 0: (1000; 471), pela
    normal (0, −1).
  - Parede: (1890; 540) com `mover` (1, 0) dá (1893; 540).
  - **A ordem do dado conta.** Obstáculos A (1000; 540) e B (1000; 640), ambos
    r = 42, teleporte para (1000; 590), um passo com `mover` 0:
    - com a lista [A, B], o resultado é (1000; 571);
    - com [B, A], é (1000; 609).
  - Um Eco não bloqueia: sem obstáculos, jogador em (960; 540) e Eco em
    (980; 540), com `mover` (1, 0) por 20 passos, o jogador chega a
    (1089; 540) ±0,01.
  - A borda não empurra: jogador a exatamente 69,000 do centro de O, em
    (931; 540), com `mover` 0, fica em (931; 540); a 68,999, em
    (931,001; 540), é empurrado para (931; 540) ±0,001.
- **AC-30 [L] F7 — a esquiva não atravessa.** Jogador em (900; 540), O em
  (1000; 540) com r = 42, esquiva para +x:
  - após 0, x = 922,5; após 1 a 8, x = 931,0;
  - em nenhum passo x passa de 931;
  - a esquiva dura os 9 passos.
- **AC-31 [L] R10 — esquiva contra a parede.** Jogador em (1880; 540), esquiva
  para +x:
  - x = 1893 após cada passo de 0 a 8;
  - a esquiva restante cai 1 por passo; "em esquiva" vale nos passos 0–7 e é
    falsa no 8 (R6);
  - `garantir_invulneravel(12)` é pedido 1 vez;
  - a esquiva não termina antes por bater na parede.
- **AC-32 [L] R1 — teleporte.**
  - (a) Andando, `teleportar((400; 300))` deixa atual = anterior = (400; 300) e
    emite 1 aviso de teleporte.
  - (b) FP-Corte com um Eco em (430; 300). Esquiva para +x a partir do passo
    0, `teleportar((400; 300))` entre os passos 2 e 3:
    - "em esquiva" fica falso;
    - o passo 3 com `mover` 0 deixa o jogador em (400; 300);
    - c continua 0, e o contador segue, com a carga de volta no passo 42;
    - não há novo `garantir_invulneravel` depois do teleporte, e o Eco, a 30 px
      (dentro do alcance de 60), não recebe pedido de Corte.

**G. Passo vivo**

- **AC-33 [L] R2 — hitstop no meio da esquiva.** FP-Corte, Eco em
  (1042,5; 540), `mover` (1, 0) só no passo 0, toque em 0 (esquiva para +x),
  hitstop ativo nos passos 3–7:
  - após 2 a 7, x = 1027,5; a esquiva restante (6) e o contador de recarga
    (p = 2) ficam congelados;
  - os passos 8–13 completam a esquiva: x = 1162,5 após 13, e o estado é Livre
    no 14;
  - a carga volta no passo 47 (42 + 5);
  - o Eco, cortado no passo 0, não é cortado de novo depois do hitstop.
- **AC-52 [L] R2 — passo congelado.** FP, `mover` (1, 0) só no passo 0, toque
  em 0, hitstop ativo nos passos 3–7 (o orquestrador chama
  `passo_congelado()`):
  - ao fim de cada passo de 3 a 7, posição anterior = atual = (1027,5; 540);
  - após 8, anterior = (1027,5; 540) e atual = (1050; 540).
- **AC-34 [I] R2 + Input F3.** Input real, toque no passo 5, hitstop nos passos
  5–19 (mais longo que o buffer de 10): a esquiva sai no passo 20, porque o
  prazo do buffer fica congelado no hitstop.

**H. Validação do `MovementTuning`**

- **AC-35 [L] MV1** (cruzada; dublê da geometria de Câmaras, que fornece
  `r_obs_min`):

  | `velocidade_esquiva_pxs` | `raio_jogador_px` | `r_obs_min` | Resultado |
  |---|---|---|---|
  | 3000 (50 px) | 10 | 30 | **erro** (50 ≥ 40) |
  | 2400 (40 px) | 27 | 42 | aviso (margem 1,725 < 2) |
  | 1350 | 27 | 42 | nada (margem 3,07) |
- **AC-36 [L] MV2.**

  | `recarga_s` | R | D + E | Resultado |
  |---|---|---|---|
  | 0,2 | 12 | 12 | **erro** (R ≤ D + E) |
  | 0,35 | 21 | 12 | aviso (0,571 > 0,5) |
  | 0,4 | 24 | 12 | nada (0,5 não é > 0,5) |
  | 0,7 | 42 | 12 | nada |
- **AC-37 [L] MV4/MV5.**
  - `raio_jogador_px` 9 e 51: erro de faixa. 10 e 50: aceitos.
  - `alvos_max_corte` 0 e −1: **erro**. Vazio e 1: aceitos.
- **AC-53 [L] R11 — faixas dos campos.** Cada linha muda um campo da FP:

  | Campo | Aceitos | Erro de faixa |
  |---|---|---|
  | `cargas_base` | 1 e 3 | 0 e 4 |
  | `duracao_esquiva_s` | 0,05 (D = 3) e 0,5 (D = 30) | 0,049 e 0,51 |
  | `velocidade_esquiva_pxs` | 300 e 3000 | 299 e 3001 |
  | `invuln_extra_s` | 0 (E = 0) e 0,25 (E = 15) | −0,01 e 0,26 |
  | `recarga_s` | 0,1 (R = 6) e 3,0 (R = 180) | 0,09 e 3,01 |
  | `fator_recuperacao` | 0 e 1 | −0,01 e 1,01 |

  `recarga_s` 0,1 é testado com `duracao_esquiva_s` 0,05 e `invuln_extra_s` 0
  (D + E = 3 < 6), para o MV2 não disparar. Arredondamento: 0,125 s dá 7,5 →
  **8** passos (F7 do Conteúdo arredonda o meio para longe do zero).
- **AC-38 [L] MV6/MV7** (podem coexistir com outros avisos):
  - MV6: raio do jogador 10, `r_inimigo_min` 10, `alcance_extra_px` 0 e
    3000 px/s → aviso, porque 50 > 40. Com os valores da FP, sem aviso.
  - MV7:
    - D = 3 a 300 px/s dá 15 px, menor que 54 → aviso;
    - D = 30 a 1350 px/s dá 675 px, maior que 600 → aviso;
    - D = 24 a 1500 px/s dá exatamente 600 px → sem aviso;
    - os 202,5 px da FP → sem aviso.
- **AC-54 [L] MV1/MV2/MV6/MV7/MV8 — os limites exatos.**
  - MV1: 1350 px/s (22,5), raio 10, `r_obs_min` 12,5 → **erro** (22,5 ≥ 22,5).
    1350 px/s, raio 27, `r_obs_min` 18 → margem 2,0 exata → nada.
  - MV2: `recarga_s` 0,2167 (R = 13) com D + E = 12 → só aviso (12/13 > 0,5),
    não erro.
  - MV6: raio 10, `r_inimigo_min` 10, `alcance_extra_px` 0: 2400 px/s
    (`d_passo` 40 = 40) → sem aviso; 2401 px/s → aviso.
  - MV7: D = 3 a 1080 px/s dá exatamente 54 px (2 × 27) → sem aviso.
  - MV8 (com `input_buffer_steps` 10): `duracao_esquiva_s` 0,17 (D = 10) →
    sem aviso; 0,18 (D = 11) → aviso; 0,15 (D = 9) → sem aviso.
- **AC-39 [I] — erros e avisos chegam ao destino.**
  - Um catálogo com MV2 e MV5 violados é recusado com as 2 entradas (regra e
    campo) na lista de erros da validação, e a run não começa. A captura da
    tela de erros é critério do GDD de Conteúdo, dono da tela.
  - Um catálogo só com avisos (MV6, MV7, MV8 e a margem do MV2) carrega e
    deixa a run começar. Os avisos ficam no registro de validação, e a lista de
    erros fica vazia.
  - **Adiado:** o MV1 entra neste critério quando o GDD de Câmaras e ondas
    decidir onde a regra roda (OQ3).

**I. Integração entre sistemas** (provisório: dublês de Combate, Selo, Câmaras e
IA)

- **AC-40 [I] ordem e bloqueio.** Orquestrador de passo real, Input real, e
  dublês de Combate e Selo que registram a ordem das chamadas e consultam "em
  esquiva":
  - em 300 passos, a ordem é sempre Movimento → Combate → Selo;
  - com `mover` (1, 0) só no passo 0 e toque em 0: no passo 0, o Combate lê
    "em esquiva" = verdadeiro e a posição já deslocada (x = 982,5);
  - Combate e Selo leem "em esquiva" = verdadeiro nos passos 0–7 e falso no 8
    (R6), e a posição que leem no passo 8 é x = 1162,5.
  - Que golpe e Selo respeitem a consulta é critério dos GDDs de Combate e de
    Selo; aqui só se testa o valor que o Movimento expõe.
- **AC-41 [I] `esquiva_iniciada` abre `apos_esquiva`.** Portador real de
  Modificadores, e um Combate dublê que abre a janela no `esquiva_iniciada`
  (Modificadores R4):
  - no passo 0, `apos_esquiva` já é verdadeira no portador;
  - mesmo assim, o Corte desse passo, com `dano_apos_esquiva` ativo, dá dano 10
    (F6);
  - há 1 `esquiva_iniciada` por esquiva: com M = c = 2, `mover` (1, 0) nos
    passos 0–18 e toques em 0 e em 4, são 2, nos passos 0 e 9.
- **AC-42 [L] F4 — o Movimento não guarda invulnerabilidade.** FP com o Combate
  dublê informando um contador de invulnerabilidade de 25: o pedido do passo 0
  continua `garantir_invulneravel(12)`. O Movimento não tem contador próprio de
  invulnerabilidade, e nenhuma consulta dele devolve um. (O "max" é critério
  do GDD de Combate.)
- **AC-43 [I] R2 — estados do Input.** Input real, M = c = 2, `mover` (1, 0) só
  no passo 0, esquiva no passo 0 e toque no 2:
  - Pausa nos passos 3 a 40, inclusive, e volta a Jogo no 41: nos passos
    pausados o Movimento não roda (x = 1027,5, restante 6, p = 2). A esquiva
    termina em 1162,5 no passo 46. O toque do passo 2 se perdeu, porque a
    pausa é troca de contexto e esvazia o buffer (Input, Edge Cases; R10 do
    Input); não sai segunda esquiva nos passos 41–80.
  - Bênção no lugar da Pausa: o mesmo resultado.
  - Menu (fim da run) no lugar da Pausa: o Movimento não roda a partir do 3.
- **AC-44a [I] Cena R7 — reset no teleporte.** Nó de apresentação real do
  jogador, com um espião em `reset_physics_interpolation()`, jogador andando a
  partir de (960; 540): `teleportar((400; 300))` no passo N deixa atual =
  anterior = (400; 300), emite 1 aviso de teleporte, e o nó chama
  `reset_physics_interpolation()` exatamente 1 vez. Sem teleporte, nenhuma
  chamada.
- **AC-44b [V] Cena R7 — sem rastro no teleporte.** Build em 1280×720, troca de
  câmara com o jogador andando: a gravação quadro a quadro da troca não mostra
  o jogador em nenhum ponto entre a posição antiga e a nova. Evidência em
  `production/qa/evidence/` com assinatura do lead.

**J. Paridade com o cânone**

- **AC-45 [I] paridade** (`engine.ts:778–865`, só leitura). Duas partes, para
  uma falha dizer de que lado está: **45a** gera a fixture (passo de
  ferramenta) e **45b** é o teste no Godot.
  - **45a — Fixture.** Um script Node, fora do jogo, importa o `engine.ts` sem
    alterá-lo e roda o passo público do motor sobre um `RunState` montado à mão:
    - arena 1280×720 u, `WALL` 34;
    - um obstáculo fixo (640; 330; r 42) u, sem obstáculos aleatórios;
    - sem inimigos, mods zerados, Lâmina com `moveSpeed` 4,3;
    - jogador em (300; 360) u.

    O roteiro tem cerca de 600 `InputFrame`s, com eixos inteiros de `AXIS_MAX`
    16 (16/16, 8/16 e diagonal). Ele cobre:
    - esquiva com `mover`;
    - esquiva com `mover` 0 (vale a mira);
    - toque durante a esquiva;
    - toque sem carga;
    - esquiva contra o obstáculo e contra a parede.

    Por passo, a fixture grava:
    - a entrada;
    - a mira normalizada;
    - o bit de esquiva no buffer antes do passo (`bufferButtons & DASH`);
    - a posição em u;
    - `dashCharges`.

    Grava também o hash do commit do Khaeros. Saída versionada:
    `tests/integration/movement/fixtures/paridade_canone.json`. O teste não
    chama Node.
  - **45b — Teste.** No Godot, a FP é sobrescrita assim:
    - jogador em (450; 540), que é (300; 360) u × 1,5;
    - retângulo jogável (51; 51)–(1869; 1029), com o centro preso em
      [78, 1842] × [78, 1002] (encolhido do raio 27, R10);
    - obstáculo (960; 495; r 63);
    - o resto vem da FP;
    - o Input dublê entrega `mover` = eixo/16, a mira e a esquiva no buffer
      conforme os bits gravados, o que isola o Movimento das diferenças do
      Input.

    Por passo, a posição tem de ser a do cânone × 1,5, com ±0,05 px, e as cargas
    têm de ser iguais (exato).
  - **Divergências deliberadas** ficam fora do roteiro (sem teleporte e sem
    mudança de `cargas_esquiva`). Elas são cobertas pela AC-32(b) e pela
    AC-16(c), que exigem o comportamento novo.
  - Recuperação e investida ficam fora (dependem do Combate). Entram na
    paridade quando o Combate existir.

**K. O que o jogador vê, e desempenho**

- **AC-46 [V] R5/V3.** Build em 1280×720, numa câmara de 1920×1080 (câmera
  parada, Cena R7), com VFX e áudio provisórios ligados ao evento `esquiva`, no
  modo de passo a passo de depuração (um passo de física por comando; entre
  comandos, o orquestrador chama `passo_congelado()`, então a captura mostra a
  posição atual, não uma interpolada). Capturas da mesma esquiva nos passos 0, 4 e 8, e mais
  uma com hitstop no meio dela:
  - o deslocamento do centro do jogador entre o passo 0 e o 8 é 120 ± 3 px de
    tela (180 px de mundo × 2/3); a esquiva inteira dá 135 px de tela;
  - as imagens residuais seguem o V3 (osso tracejado, sem tingir o corpo) e
    ficam paradas na captura do hitstop.
  - Evidência em `production/qa/evidence/` com assinatura do lead.
- **AC-47 [M] R5.** O testador faz 20 esquivas e ouve o áudio provisório nas 20.
  Um toque com 0 cargas não produz esquiva, nem VFX, nem áudio de esquiva. O
  registro em `production/qa/evidence/` traz testador, build e o resultado
  (20/20). O pisca do HUD fica para quando o GDD do HUD existir. A sensação
  fica para Game Feel.
- **AC-48 [P] desempenho** (em `tests/performance/movement/`, desvio explícito
  das duas pastas do formato; decisão do usuário, 2026-11-08).
  - Roteiro: 10 000 passos com roteiro fixo, 9 inimigos na lista, Corte ativo
    sem teto, uma esquiva a cada 42 passos e 6 obstáculos.
  - Medida: custo médio e p99 de um passo do Movimento, com
    `Time.get_ticks_usec`, headless, no PC de desenvolvimento.
  - **Passa com p99 ≤ 0,2 ms** (≈ 1,2% do quadro de 16,6 ms); falha acima.
    Provisório: revisar quando houver orçamento por sistema.
  - Registro em `production/qa/evidence/movimento-desempenho-[data].md`, com a
    máquina, o build, a média e o p99.
- **AC-55 [L] contrato de saída para HUD e Pipeline.** FP, `mover` (0, 0) até
  o passo 99, (1, 0) no 100, toque em 100:
  - o evento `esquiva` do passo 100 leva direção (1, 0) e posição de início
    (960; 540);
  - após 121, a fração de recarga é 21/42 = 0,5 ±0,001;
  - com c = M (após 142), a fração é 0;
  - **variante**, no mesmo roteiro mais hitstop nos passos 125–129: a fração
    fica igual (24/42) do fim do 124 ao fim do 129, e a carga volta no 147.

**L. A promessa do P3** (depende do Combate real)

- **AC-56 [I] invulnerabilidade de fato — BLOQUEADO até o GDD de Combate
  núcleo.** Combate real, esquiva tocada no passo s com a FP:
  - um golpe inimigo aplicado ao jogador em qualquer passo de s a s+11
    (inclusive o próprio s) causa dano 0;
  - o mesmo golpe no passo s+12 causa o dano cheio.
- **AC-57 [M] alvo de playtest do P3.** Sessão de 30 minutos, com o log de
  depuração de toques de esquiva e cargas por passo ligado: 0 mortes por um
  golpe que chega quando havia carga e um toque de esquiva nos 10 passos
  anteriores. Registro em `production/qa/evidence/` com testador e build.

Cobertura: R1–R12, F1–F7 e MV1–MV8 têm ao menos um critério cada, e os limites
das faixas da R11 e das validações estão na AC-53 e na AC-54. Os Edge Cases de
maior risco estão nos blocos C, D, E, F e G. Lacunas assumidas:

- **Visual/Audio:** só o que a AC-46 e a AC-47 cobrem. Chevrons, tremor do HUD
  e direção do sprite entram nos critérios do HUD e do Pipeline.
- **Promessa do P3 com o Combate real:** AC-56, bloqueada até o GDD de Combate.
- **Comportamento nos extremos do MV4** (vão mínimo entre obstáculos): é do GDD
  de Câmaras.

## Open Questions

| # | Pergunta | Dono | Resolver até |
|---|---|---|---|
| 1 | Corpo do jogador: `CharacterBody2D` ou cinemática própria de círculos (cânone)? Posição em float32 ou float64 (as tolerâncias dos ACs dependem disso)? A referência do motor não cobre o 2D | technical-director + godot-specialist | ADR, antes de `/create-architecture` |
| 2 | Contratos provisórios com o Combate, a honrar: consultas (recuperação, investida e `d` vetor, `contexto_de_dano` só com a Vida atual e a máxima; o hitstop é lido pelo orquestrador), pedidos (`cancelar`, `garantir_invulneravel`, `aplicar_corte`, `esquiva_iniciada` e, do Combate para cá, `deslocar(v)` para o passo de apoio, R9), desconto da invulnerabilidade no início de cada passo vivo seguinte (F4), golpe e Selo pela consulta "em esquiva" (R6), chamada `passo_congelado()` pelo orquestrador (R2) | dono do GDD de Combate núcleo | ao escrever o Combate |
| 3 | Onde roda o MV1 (cruzada com Câmaras) e a garantia do vão mínimo do MV4 | dono do GDD de Câmaras e ondas + Conteúdo | GDD de Câmaras (liga à OQ9 da Cena) |
| 4 | A consulta de alvos do Input não traz o raio; o Corte precisa dele | dono do GDD de IA | GDD de IA |
| 5 | Valor do `alvos_max_corte` (D-W6) | `/balance-check` com o dono de Bênçãos | antes da fatia vertical |
| 6 | Linha nova no Art Bible §5.8 (esquiva com 2 quadros mais saída cortável) e reação do HUD a `esquiva_sem_carga` no §7.7, com o aval do `ux-designer` | art-director + ux-designer | antes de produzir os assets da esquiva |
| 7 | O ciclo Movimento ↔ Combate em "Circular Dependencies" do índice | usuário / producer | próxima edição do índice |
| 8 | Requisitos de áudio provisórios (Visual/Audio A1) | audio-director | GDD de Áudio |
| 9 | Teto de `cargas_esquiva`: o Modificadores só tem piso. Quantos chevrons o HUD comporta, e se o `ModifiersTuning` ganha um teto | dono do GDD de HUD + Modificadores | GDD de HUD |
