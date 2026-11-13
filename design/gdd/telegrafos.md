# Telégrafos

> **Status**: Approved (2026-11-11; revisão única por subagente, 5 bloqueantes corrigidos sem re-review; sem entrada no review log)
> **Author**: usuário + Claude (design-system, modo Lean)
> **Last Updated**: 2026-11-11
> **Last Verified**: 2026-11-11
> **Implements Pillar**: P3 *Reflexo que se lê* (de onde vem o golpe e quando)

## Summary

**Telégrafos** é o aviso visual de todo golpe inimigo: uma forma no chão (setor,
faixa, retângulo ou anel) que cresce durante a preparação, com a mira travada, e
dispara no passo em que o golpe sai. A forma é o teste de acerto (P3), o
preparo mínimo é de 0,4 s e o Pipeline visual a desenha. Existe para o jogador
ler de relance de onde vem o golpe e quando, e para nada acertá-lo sem aviso.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Pipeline visual, Combate núcleo`

> **Nota (2026-11-11, revisão cruzada):** Dependencies atualizadas: IA, Câmaras, VFX e Telemetria agora existem (Chefes e Áudio seguem sem GDD).

## Overview

> `game-designer` não consultado nesta seção: modo Lean.

**Telégrafos** é o aviso visual de todo golpe inimigo: uma forma desenhada no
chão que **cresce** durante a preparação do atacante e **dispara** quando o
golpe sai. Ele decide, para cada ataque, a forma (`circulo`, `setor`,
`retangulo`, `anel`), o tamanho, o tempo, o modo de crescimento e a mira, e
entrega ao Pipeline visual o progresso `p` de 0 a 1.

- A forma do telégrafo **é o teste de acerto**: o que o jogador vê é o que o
  fere (P3). O telégrafo e o `ferir_jogador` usam a mesma geometria, sem margem
  escondida.
- A **mira fica travada** no início da preparação (cânone). O jogador lê uma
  vez e se move.
- Todo golpe tem um telégrafo, inclusive o projétil: a Anomalia mostra a
  **faixa do disparo**, ao longo da mira, até o alcance do projétil.
- O telégrafo só se parte com um golpe pesado na hora certa (Combate V9); fora
  isso, o único remédio é a esquiva.

A **fantasia** é a de poder ler a morte chegando: o jogador entra na arena, vê o
chão se acender em magenta e osso, e sabe de onde vem o golpe e quando. Quando
erra, o erro é dele.

As regras seguem o cânone (`engine.ts:995–1135`, `arenaContent.ts:86–97`),
convertido para px e passos. O Pipeline desenha, a IA decide quando iniciar a
preparação, e este GDD decide **o que** aparece. Sem este sistema, os inimigos
feririam sem aviso e o pilar P3 não se cumpriria.

> **→ vira ADR:** onde vivem os telégrafos ativos (uma lista própria no estado
> do combate, como os Selos e os projéteis) e como a forma de acerto e o desenho
> dividem a mesma definição.

## Detailed Design

### Core Rules

> `game-designer`, `ai-programmer` e `art-director` não consultados nesta seção:
> modo Lean. As regras seguem o cânone (`engine.ts:995–1135`, `:889–901`,
> `arenaContent.ts:86–97`), convertido para px e passos (unidade × 1,5 px;
> Conteúdo F4).

**R1. Modelo.** Um telégrafo tem: dono (o inimigo), forma e dimensões (R5),
âncora (a posição do dono), **mira travada** (R2), `preparo` (passos, total),
`restante` (passos), modo de crescimento (R8) e estado (`crescendo`, `disparo`,
`quebrado`, `cancelado`; Pipeline R5). Cada inimigo tem **no máximo um**
telégrafo ativo.

**R2. Criar.** Quando a IA põe o inimigo em preparação, ela chama
`iniciar_telegrafo(inimigo, ataque)`. No mesmo passo:
- a **mira é travada** na direção do inimigo ao jogador e não muda mais (cânone);
- `preparo` = `passos(preparo_s)` do `EnemyDef` (Eco 26, Anomalia 36, Fenda 42);
  `restante` = `preparo`;
- se já há 24 telégrafos ativos (`teto_telegrafos`, **do Pipeline R9**: este GDD só
  o lê), a IA **não** inicia a preparação neste passo e tenta no seguinte. Com os
  9 inimigos do MVP (1 telégrafo cada) o teto não é atingido; ele cobre chefe e
  invocações futuras.

**R3. Progresso.** A cada passo vivo (item 7 do Combate), antes da IA decidir:
`restante` −= 1 e `p = 1 − restante / preparo` (linear). O telégrafo **acompanha
o dono** (posição e rotação da forma), com a mira travada. Um empurrão que
move o dono move o telégrafo com ele. O Pipeline recebe `p` e o estado a cada
quadro (o relógio é o vivo: para no hitstop, na pausa e na Bênção).

**R4. Disparo.** Quando `restante` chega a 0, o telégrafo passa a `disparo` (o
Pipeline mostra o flash de osso por 2 passos vivos) e **o golpe é resolvido no
mesmo passo**:
- `setor` (melee): a IA testa a R6 e chama `ferir_jogador` uma vez, se acertar;
- `retangulo` de projétil: a IA chama `disparar_projetil` na mira travada, saindo
  do atirador;
- `retangulo` de avanço: começa o avanço (Combate/IA); o dano é por contato (R6).

O dano do inimigo e o M do disparo vêm do `EnemyDef` e do Modificadores; este
GDD não os define.

**R5. Formas por ataque** (MVP; a forma é a do teste de acerto, R6):

| Ataque | Forma | Dimensões | Crescimento |
|---|---|---|---|
| Eco Perdido (melee) | `setor` | raio 90 px = (34 + 18 + 0,5 × 16) × 1,5; meio-ângulo 78,46° (`acos 0,2`) | `centro_a_borda` |
| Anomalia Menor (projétil) | `retangulo` ancorado no atirador | comprimento 1728 px = saída + alcance + acerto, até a parede (F3); largura 81 px = 2 × (13,5 + 27) | `ao_longo_do_eixo` |
| Fenda Errante (avanço) | `retangulo` ancorado no lado **traseiro** do atacante (recuado 57 px do centro) | comprimento 310,6 px = percurso 196,6 + 2 × 57; largura 114 px = 2 × 57 | `ao_longo_do_eixo` |
| Chefe (provisório, Vertical Slice) | anel (rajada de 12), retângulo (avanço), setor (leque), círculo (invocação) | do GDD de Chefes | `borda_ao_centro` no anel e no círculo |

Contas: raio do jogador 18 u = 27 px; projétil inimigo raio 9 u = 13,5 px, a
4,6 u/passo = 6,9 px/passo, 240 passos de vida = 1656 px; avanço da Fenda =
1,4 × 3,6 × 26 passos = 131 u = 196,6 px; contato = (20 + 18) u = 57 px.

**R6. O teste de acerto é a forma.**
- **Setor e anel:** o **centro** do jogador dentro da forma (o raio do jogador já
  está nas dimensões da R5). Tocar a borda com o corpo sem o centro dentro não
  fere.
- **Faixa do projétil:** o comprimento é `min(saída + alcance + raio de acerto,
  distância do centro do atirador até a parede ou obstáculo na mira)` (F3); o projétil, em voo, acerta pela R7
  do Combate (distância ≤ `raio_px` + `raio_jogador_px`), que é o que a largura
  da faixa representa.
- **Avanço:** o **teste** é o contato do cânone (círculo): a cada passo do
  avanço, distância dos centros < 57 px, em qualquer direção, **uma vez por
  avanço**. O retângulo é a **envoltória** desse varrido, da traseira do
  atacante (−57 px) até 57 px além do fim do percurso; ele cobre tudo o que fere
  e passa nos quatro cantos por até 23,6 px: o desenho nunca é menor que o
  perigo. O telégrafo some 2 passos depois do disparo, mas o avanço dura 26: a
  partir daí, o próprio inimigo em movimento é a leitura (decisão P3).
- Esquiva, recusa e invulnerabilidade valem como no Combate (R13): um golpe que
  encontra o jogador invulnerável não fere.

**R7. Quebrar e cancelar.**
- **Quebrado:** o Combate pede "Quebrou!" (golpe pesado em preparação, R8.7); o
  telégrafo passa a `quebrado` (rachadura de 2 passos, sem flash; V9) e o golpe
  **não sai**. A IA põe o inimigo em recuperação por `passos(quebrou_recuperacao_s)`.
- **Cancelado:** o dono morre ou a câmara troca; o telégrafo some em 2 passos.
  Ele não dispara.
- Elite e chefe não quebram (Combate R8.7): o telégrafo deles só pode ser
  esquivado.

**R8. Crescimento.** O preenchimento cresce de 0 a 100% em `p`, linear, **sem
pulsar** (Art Bible §4.5). `centro_a_borda`: do atacante para fora (setor);
`ao_longo_do_eixo`: do atacante ao fim da faixa; `borda_ao_centro`: da borda para
o centro (anel e círculo). O contorno fica a 100% desde o passo 0 (Pipeline R5).

**R9. Leitura mínima.** `preparo` ≥ `preparo_min_s` (0,4 s = 24 passos) em todo
ataque de inimigo comum, para o jogador ter tempo de ler e reagir (menor do
MVP: Eco do Veio, 24 passos = o mínimo; Eco, 26). O chefe pode ter menos, se o GDD de Chefes justificar.

**R10. `TelegraphTuning`** (Conteúdo R1). Duração em segundos (Conteúdo F7).

| Campo | Valor inicial | Cânone |
|---|---|---|
| `preparo_min_s` | 0,4 (24 passos) | — (proposta, R9) |
| `teto_telegrafos` | 24 | `teto` do Pipeline R9 (24 × 2 passadas) |
| `reacao_ref_s` | 0,25 (15 passos) | — (proposta, F6) |
| `folga_min` | 8 passos | — (proposta, F6) |

As **dimensões são derivadas** dos campos que o `EnemyDef` já tem (alcance, raio,
velocidade, velocidade do projétil) pelas F2–F4, e a forma sai do comportamento
(`melee` → setor, `ranged` → faixa, `charger` → avanço). O `EnemyDef` guarda só
o `preparo` (`preparo_s`); o Conteúdo ganha o `TelegraphTuning` (Conteúdo R1,
edição pequena de 2026-11-11). Fonte única: nada de dimensão gravada à parte.

**R11. Injeção.** Recebe por injeção: o `TelegraphTuning`, os `EnemyDef`, a
posição do jogador e do inimigo, a geometria da câmara (parede e obstáculos), o
M e o dano via IA e Combate (`ferir_jogador`, `disparar_projetil`). Os testes
montam tudo em memória.

### States and Transitions

| Estado | Entra quando | Sai quando |
|---|---|---|
| `crescendo` | a IA inicia a preparação (R2) | `restante` = 0 → `disparo`; "Quebrou!" → `quebrado`; dono morto ou câmara nova → `cancelado` |
| `disparo` | `restante` = 0 | 2 passos vivos depois (flash do Pipeline), sai da lista |
| `quebrado` | o Combate quebra a preparação | 2 passos depois, sai da lista |
| `cancelado` | dono morto ou câmara nova | 2 passos depois (opacidade 1 → 0,5 → 0), sai da lista |

**Mundo:** como no Combate. No hitstop e fora de Jogo, `restante` e `p` não
mudam.

### Interactions with Other Systems

| Sistema | Recebe daqui | Fornece para cá | Dono da interface |
|---|---|---|---|
| Pipeline visual | forma, posição, rotação, dimensões, `p`, modo e estado de cada telégrafo | desenho (duas passadas, flash, rachadura) | Pipeline R5 (desenho), este GDD (conteúdo) |
| Combate núcleo | a forma do golpe (igual ao teste de acerto) | `ferir_jogador`, "Quebrou!", `disparar_projetil` | Combate (dano), este GDD (geometria) |
| IA de inimigos e elites | `iniciar_telegrafo`, mira travada, passo do disparo | início da preparação, `EnemyDef`, recuperação | IA (quando), este GDD (o quê); **provisório** |
| Modificadores e atributos | — | dano e M do golpe | Modificadores |
| Conteúdo orientado a dados | — | `TelegraphTuning`, `EnemyDef` (preparo, alcance, ângulo), F4, F7 | Conteúdo (formato), este GDD (semântica) |
| Câmaras e ondas | — | parede e obstáculos (comprimento da faixa), "câmara nova" | Câmaras; **provisório** |
| Feedback de combate (VFX) / HUD / Áudio | estado do telégrafo (disparo, quebra) | — | apresentação |
| Chefes (Vertical Slice) | formas e tempos provisórios dos padrões | os 4 padrões | Chefes |

## Formulas

> `systems-designer` não consultado nesta seção: modo Lean (poucas fórmulas,
> todas com conta do cânone). Conversões: unidade × 1,5 px (Conteúdo F4);
> `passos(t)` é o F7 do Conteúdo; 60 passos por segundo.

### F1. Progresso do telégrafo

The telegraph_progress formula is defined as:

`p = 1 − restante / preparo` ; `preparo = passos(preparo_s)` (F7 do Conteúdo: 0,4333 s → 26) ; `restante` cai 1 por passo vivo

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| preparo | int | ≥ 24 (comum) | data file | passos(`preparo_s` do `EnemyDef`) |
| restante | int | 0–preparo | calculated | passos que faltam para o disparo |
| p | float | 0–1 | calculated | progresso entregue ao Pipeline |

**Output Range:** p ∈ [0, 1]; p = 0 no passo da criação e p = 1 no passo do disparo. Linear, sem curva.
**Example:** Eco (preparo 26): p = 0,5 com restante 13; p = 1 no 26º passo.

### F2. Setor do golpe corpo a corpo

The melee_sector formula is defined as:

`R = (alcance_u + raio_jogador_u + 0,5 × raio_inimigo_u) × 1,5` ; `θ = arccos(0,2)` (meio-ângulo) ;
acerta se `|jogador − inimigo| ≤ R` e `dir(inimigo → jogador) · mira_travada ≥ cos θ` (com distância 0, o produto escalar vale 1, como no cânone)

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| alcance_u | float | > 0 (34) | data file | `range` do inimigo, em unidades do cânone |
| raio_jogador_u | float | 18 | constant | `PLAYER_RADIUS` do cânone (27 px) |
| raio_inimigo_u | float | > 0 (16) | data file | raio do inimigo |
| R | float | > 0 | calculated | raio do setor em px |
| θ | float | 78,46° | constant | meio-ângulo (cânone: produto escalar ≥ 0,2) |

**Output Range:** R > 0; θ fixo em 78,46° (arco de 156,9°).
**Example:** Eco Perdido: (34 + 18 + 8) × 1,5 = 90 px. Eco do Veio (38; 17): (38 + 18 + 8,5) × 1,5 = 96,75 px.

### F3. Faixa do projétil

The shot_lane formula is defined as:

`largura = 2 × (raio_proj_u + raio_jogador_u) × 1,5` ;
`saida = (raio_inimigo_u + 6) × 1,5` ; `alcance = vida_passos × v_u × 1,5` ; `r_acerto = (raio_proj_u + raio_jogador_u) × 1,5` ;
`comprimento = min(saida + alcance + r_acerto, distância do centro do atirador até a parede ou obstáculo na mira)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| raio_proj_u | float | 9 | constant | raio do projétil inimigo (cânone), 13,5 px |
| vida_passos | int | 240 | constant | `ticksLeft` do projétil inimigo (cânone) |
| v_u | float | > 0 (4,6) | data file | `projectileSpeed` em u/passo |
| largura, alcance, comprimento | float | > 0 | calculated | px |

**Output Range:** largura = 81 px (= 2 × r_acerto); comprimento ≤ saída + alcance + r_acerto, o que o projétil realmente percorre mais o que ele alcança.
**Example:** Anomalia Menor: largura 2 × (9 + 18) × 1,5 = 81 px; saída (15 + 6) × 1,5 = 31,5 px, alcance 240 × 4,6 × 1,5 = 1656 px e r_acerto 40,5 px: comprimento 1728 px, ou menos se a parede ou o obstáculo vierem antes. Anomalia do Veio (raio 16; 5,2): saída 33 + alcance 1872 + 40,5 = 1945,5 px.

### F4. Avanço (envoltória)

The charge_lane formula is defined as:

`percurso = v_u × 3,6 × N × 1,5` ; `R_c = (raio_inimigo_u + raio_jogador_u) × 1,5` ;
`L = percurso + 2 × R_c` (de −R_c a percurso + R_c no eixo da mira) ; `W = 2 × R_c` ; folga do canto = `(√2 − 1) × R_c`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| v_u | float | > 0 (1,4) | data file | velocidade de andar do inimigo (u/passo) |
| N | int | 26 | constant | passos do avanço (cânone) |
| raio_inimigo_u | float | > 0 (20) | data file | raio do inimigo |
| R_c | float | > 0 | calculated | alcance de contato em px (57) |
| L, W | float | > 0 | calculated | comprimento e largura do retângulo em px |

**Output Range:** L = percurso + 2 × R_c; o retângulo cobre a cápsula inteira do varrido (traseira incluída) e passa dela só nos quatro cantos, por `(√2 − 1) × R_c` (o desenho nunca é menor que o perigo).
**Example:** Fenda Errante: percurso 1,4 × 3,6 × 26 × 1,5 = 196,6 px; R_c = (20 + 18) × 1,5 = 57; L = 196,6 + 114 = 310,6 px; W = 114 px; folga do canto 23,6 px. Estilhaço Vivo (1,6; 21): percurso 224,6, R_c 58,5, L 341,6, W 117.

### F5. Testes de acerto

The telegraph_hit formula is defined as:

- `setor`: F2 (distância e produto escalar com a mira travada);
- `retangulo` (projétil): o projétil em voo acerta pela R7 do Combate; a faixa só **mostra** o corredor;
- `retangulo` (avanço): a cada passo do avanço, acerta se `|jogador − atacante| < R_c` e ainda não acertou neste avanço (uma vez por avanço);
- eixo local do retângulo (só para o desenho e a captura; o teste do avanço é o contato): `x' = (jogador − centro_do_atacante) · mira`, `y' = (jogador − centro_do_atacante) × mira`; dentro se `−R_c ≤ x' ≤ percurso + R_c` e `|y'| ≤ W / 2`; no setor, o teste é o da F2.

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| mira | vec2 | unitária | calculated | mira travada na criação |
| origem | vec2 | no chão | calculated | posição atual do dono |
| x', y' | float | — | calculated | coordenadas do jogador no eixo da faixa |

**Output Range:** verdadeiro ou falso; o dano é chamado uma vez por golpe (`ferir_jogador`), e invulnerabilidade, esquiva e recusa valem como no Combate (R13).
**Example:** Eco em (0; 0), mira (1; 0), jogador em (80; 20): distância 82,5 ≤ 90 e produto escalar 0,97 ≥ 0,2: acerta. Em (−10; 0): produto escalar −1: não acerta.

### F6. Folga de leitura

The read_margin formula is defined as:

`folga = preparo − passos(reacao_ref_s)` ; recomendado `folga ≥ folga_min`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| preparo | int | ≥ 1 | data file | F1 |
| reacao_ref_s | float | 0,15–0,4 (0,25) | data file | tempo de reação de referência (proposta), 15 passos |
| folga_min | int | ≥ 0 (8) | data file | passos que sobram para agir (proposta) |

**Output Range:** folga ∈ [−reação, preparo − 1]; negativa = o jogador não consegue reagir só olhando.
**Example:** Eco 26 − 15 = 11 passos (0,18 s); Anomalia 36 − 15 = 21; Fenda 42 − 15 = 27. O 0,25 s e o 8 são propostas, não cânone.

### Faixas do `TelegraphTuning`

| Campo | Inicial | Faixa | O que quebra fora dela |
|---|---|---|---|
| `preparo_min_s` | 0,4 (24) | 0,3–0,43 (18–26) | < 0,3: o mínimo deixa de proteger a leitura; > 0,43 (26 passos): o Eco (26) e o Eco do Veio (24) passam a gerar o TV3 |
| `teto_telegrafos` | 24 (dono: Pipeline R9; aqui só leitura) | 12–24 | 24 × 2 passadas = orçamento de draw calls do Pipeline; > 24 estoura o orçamento. O teto cobre chefe e invocações futuras e **não** é atingido por 9 inimigos (1 telégrafo cada); < 12 já poderia fazer a IA esperar com chefe e invocações |
| `reacao_ref_s` | 0,25 (15) | 0,15–0,4 | < 0,15: a folga é otimista; > 0,4: avisa em todo ataque do MVP |
| `folga_min` | 8 | 4–15 | < 4: ataques sem reação possível; > 15: avisa em todo ataque do MVP |

Faixas inclusivas, comparadas em passos (F7 do Conteúdo). Os quatro campos são do `TelegraphTuning`.

### Validação do `TelegraphTuning` e dos `EnemyDef`

Somam-se às faixas do V2 do Conteúdo. **Erros** vão para a tela de erros do catálogo e a run não começa; **avisos** ficam no registro de validação.

| Regra | Tipo | Condição | Por quê |
|---|---|---|---|
| TV1 | erro | passos(`preparo_s`) < 1, ou `teto_telegrafos` < 1, ou `preparo_min_s` ≤ 0 | telégrafo que dispara sem aviso, ou sem espaço |
| TV2 | erro | comportamento de inimigo sem forma mapeada, ou dimensão derivada (F2–F4) ≤ 0 | golpe sem telégrafo (Combate: nada acerta sem aviso) |
| TV3 | aviso | passos(`preparo_s`) < passos(`preparo_min_s`) em um comum | leitura abaixo do mínimo (hoje menor: Eco 26 ≥ 24) |
| TV4 | aviso | F6: `folga` < `folga_min` | o jogador não reage só olhando |
| TV5 | aviso, cruzada com Câmaras | `teto_telegrafos` < número máximo de telégrafos simultâneos possíveis (inimigos de uma onda × 1, mais chefe e invocações quando existirem) | a IA vai esperar para atacar; o teto de 24 (Pipeline R9) não é atingido por 9 inimigos, então este aviso é sobre um teto reduzido |
| TV6 | aviso | campo fora da faixa de design | as contas deste GDD deixam de valer |

**Saída do validador:** uma entrada por regra e por objeto; o erro suspende o aviso da mesma regra. TV3–TV5 dependem de dados de outros sistemas e rodam onde roda o MV1 do Movimento (Movimento OQ3).

## Edge Cases

> `game-designer` não consultado nesta seção: modo Lean.

**Criar e durar**

- **Se a IA tentar iniciar uma preparação com 24 telégrafos ativos:** a preparação não começa e a IA tenta no passo seguinte (R2).
- **Se o jogador estiver dentro do setor quando o telégrafo é criado:** nada acontece; o golpe só é resolvido no disparo, e sair a tempo evita o dano.
- **Se o jogador se mover durante a preparação:** a mira travada não rastreia (R2); o telégrafo continua apontando para onde o jogador estava.
- **Se o dono for empurrado durante a preparação:** o telégrafo acompanha a posição dele (R3); a forma e a mira não mudam.
- **Se `preparo_s` virar 0 passos:** é erro (TV1); a run não começa.
- **Se houver hitstop, pausa, Bênção ou Transição:** `restante` e `p` não mudam (R3).
- **Se o dono estiver na faixa de lentidão do Selo ou com Abalo:** o preparo não muda (a lentidão é só do andar); o Abalo só muda o dano.

**Disparo**

- **Se o jogador estiver invulnerável no passo do disparo (esquiva, investida, pós-dano, recusa):** o golpe não fere (Combate R13); o telégrafo dispara normalmente.
- **Se o projétil sair com o jogador fora da faixa:** o projétil sai igual; a faixa é o corredor da mira travada.
- **Se a faixa do projétil encontrar um obstáculo ou a parede antes do alcance:** ela termina ali (F3), e o projétil some no obstáculo (Combate R7).
- **Se o avanço da Fenda terminar sem tocar o jogador:** nenhum dano; o telégrafo já sumiu (2 passos depois do disparo), e o avanço é a leitura.
- **Se o jogador for tocado duas vezes no mesmo avanço:** só a primeira conta (uma vez por avanço, F4).

**Quebrar e cancelar**

- **Se um golpe pesado quebrar a preparação no mesmo passo em que ela chegaria a 0:** o golpe do jogador roda no item 5, antes da IA (item 7); se o Combate já pediu "Quebrou!" nesse passo, o telégrafo é `quebrado` e o golpe não sai (R7).
- **Se um golpe pesado só chegar depois do passo do disparo (por exemplo, um projétil no item 8 desse passo):** o inimigo já está em execução; nada quebra.
- **Se o dono morrer na preparação (Vida ≤ 0):** o telégrafo é `cancelado` e **não dispara** ("morto não age", Combate R14).
- **Se a câmara trocar:** os telégrafos ativos são cancelados sem disparar.
- **Se um inimigo elite ou o chefe tomar um golpe pesado:** o telégrafo não quebra (Combate R8.7); só a esquiva evita o golpe.

**Multidão**

- **Se dois telégrafos se sobrepuserem:** os dois contornos ficam visíveis (z 5); o preenchimento mais recente fica por cima (Pipeline R5). Cada golpe fere separadamente, e o primeiro a ferir dá invulnerabilidade de 40 passos que protege dos demais (Combate R13).
- **Se o atacante estiver fora da tela:** o telégrafo é desenhado igual; a leitura de fora da tela é problema de IA e câmera (Armas D-I8).

**Números**

- **Se a câmara for menor que o alcance do projétil:** a faixa termina na parede (F3).
- **Se o preparo de um ataque comum for menor que 24 passos:** aviso TV3, não erro.

**Conflitos com outros GDDs:** nenhum nas partes aprovadas. O Combate R7 e R13 já delegavam a geometria a este GDD.

## Dependencies

**Depende de (upstream)**

| Sistema | Tipo | O que vem de lá | Sem ele |
|---|---|---|---|
| Pipeline visual | Forte | a primitiva de telégrafo (formas, estados, duas passadas, cores, contorno, flash) | o telégrafo não é desenhado |
| Combate núcleo | Forte | `ferir_jogador`, `disparar_projetil`, "Quebrou!", invulnerabilidade, "morto não age" | o golpe não fere nem quebra |
| IA de inimigos e elites | Forte, **por contrato** | `iniciar_telegrafo`, o passo do disparo, a recuperação | ninguém inicia a preparação |
| Conteúdo orientado a dados | Forte | `EnemyDef` (preparo, alcance, ângulo, largura), `TelegraphTuning`, F4 e F7 | números no código |
| Modificadores e atributos | Suave | dano e M do golpe (via IA e Combate) | dano base |
| Câmaras e ondas | Suave, **por contrato** | parede e obstáculos (comprimento da faixa), "câmara nova" | câmara padrão 1920×1080 sem obstáculos |

**É dependência de (downstream)**

| Sistema | Tipo | O que recebe |
|---|---|---|
| IA de inimigos e elites | Forte | forma, mira travada e passo do disparo de cada ataque |
| Pipeline visual | Forte | forma, posição, rotação, dimensões, `p`, modo e estado de cada telégrafo |
| Feedback de combate (VFX) / Áudio | Suave | estado do telégrafo (disparo, quebra, cancelamento) |
| Chefes (Vertical Slice) | Forte | as formas e o tempo dos 4 padrões (provisório) |
| Telemetria local | Suave | golpes que acertaram sem esquiva, por tipo de telégrafo |

**Bidirecionalidade:**

- O Pipeline (R5, Dependencies) e o Combate (R13, Interactions, Dependencies) já
  listam Telégrafos.
- IA, Câmaras e ondas, Feedback de combate (VFX) e Telemetria local já existem; a
  conferência de que cada um lista "Telégrafos" em Dependencies é do
  `/review-all-gdds`. Chefes e Áudio ainda não existem: ao serem escritos, devem
  listar "Telégrafos" em Dependencies e honrar os contratos acima. O Combate
  núcleo já existe e consta em Dependencies (upstream) e nesta lista.
- **Índice:** a linha 13 lista Pipeline e Combate; acrescentar Conteúdo, IA
  (por contrato) e Câmaras (suave, por contrato).

## Visual/Audio Requirements

> `art-director` e `audio-director` não consultados: modo Lean. O desenho é do
> Pipeline visual (R5, F4, F10); este GDD só dá o conteúdo.

- **Cores e traço** (Pipeline R5, Art Bible §4.5): núcleo `#FFD3EE` (L* ≈ 88),
  anel `#FF3DAE`, contorno `#0D0E14` de 4 px a 1080p, a 100% desde o passo 0. O
  telégrafo é dono do topo da escada de valor e **nunca pulsa: ele cresce**.
- **Crescimento por forma:** setor do atacante para fora; faixa e avanço ao longo
  do eixo; anel e círculo da borda para o centro (R8).
- **Disparo:** flash de osso por 2 passos vivos (Pipeline R5), no mesmo passo do
  golpe.
- **Quebrado:** rachadura de tinta atravessando o preenchimento em 2 passos, sem
  flash (Combate V9). **Cancelado:** some em 2 passos (opacidade 1 → 0,5 → 0).
- **Camadas:** preenchimento em z −5 (abaixo do y-sort, coberto pelos corpos) e
  contorno em z 5 (acima do y-sort), então o contorno nunca some atrás de um
  corpo (Cena R4).
- **Faixa do projétil:** estreita (81 px) e longa; em multidão só o contorno e
  um preenchimento fraco para não cobrir o chão (a atenção é limitada, Armas D-I8
  e Pipeline F10).
- **Acessibilidade:** forma e valor, não só cor; contorno de 6 px na opção de
  intensidade do telégrafo (Art Bible §7.9).
- **Áudio** (requisito provisório): um tom de aviso que sobe com `p` e um estalo
  no disparo, no máximo 3 telégrafos soando ao mesmo tempo; sem som contínuo em
  multidão.

> 📌 **Asset Spec** — rodar `/asset-spec system:telegrafos` depois do Art Bible:
> a malha de borda, o preenchimento por forma, a rachadura e o som de aviso.

## Game Feel

- **Leitura de relance:** o jogador entra na arena e sabe de onde vem cada golpe
  e quando, sem olhar o inimigo.
- **Tempo para agir:** de 0,43 s (Eco) a 0,7 s (Fenda); com a reação de referência
  de 0,25 s, sobram 11 a 27 passos para esquivar (F6).
- **Justiça:** o erro é do jogador; o telégrafo nunca mente (a forma é o teste, o
  desenho nunca é menor que o perigo).
- **Alvo de playtest** (proposta): ≥ 80% dos testadores evitam o primeiro golpe
  do Eco sem dica (registro [M]).

## UI Requirements

- Sem tela própria. O telégrafo é desenho no mundo (Pipeline).
- **Opções de acessibilidade:** intensidade do telégrafo (contorno de 6 px),
  forma e valor sempre ligados (Art Bible §7.9).
- O HUD não mostra telégrafos.

## Cross-References

| Documento | Seção | Uso neste GDD |
|---|---|---|
| `design/gdd/pipeline-visual.md` | R5, F4, F6, F10, R9 | primitiva de telégrafo, formas, estados, orçamento (24) |
| `design/gdd/combate-nucleo.md` | R7, R8.7, R13, R14, V9 | projétil inimigo, "Quebrou!", dano no jogador, morto não age, telégrafo partido |
| `design/gdd/conteudo-orientado-a-dados.md` | R1, V2, F4, F7 | `TelegraphTuning`, `EnemyDef`, conversões |
| `design/gdd/modificadores-e-atributos.md` | R5, F2 | dano do inimigo, Abalo |
| `design/gdd/cena-3-4-e-camera.md` | R4, R6 | camadas z −5 e 5, parede da câmara |
| `design/gdd/movimento-e-esquiva.md` | R6 | invulnerabilidade da esquiva |
| `design/gdd/armas-das-doutrinas.md` | D-I8 (cross-review) | leitura de ataque de fora da tela |
| `design/art/art-bible.md` | §4.5, §6.3, §7.9, §8.6 | cores, movimento, camadas, acessibilidade |
| Khaeros `packages/action-core/src/engine.ts` | `:889–901`, `:995–1135` | windup, projétil inimigo, avanço |
| Khaeros `packages/combat-rules/src/arenaContent.ts` | `:86–97` | números dos inimigos |

## Acceptance Criteria

> `qa-lead` não consultado: economia de tokens; a revisão única do GDD cobre
> regras e critérios.

**Fixture TG** (provisório: dublês de IA, Combate, Pipeline e Câmaras):
`TelegraphTuning` de fábrica, jogador com raio 27 px e Vida 100, câmara
1920×1080, passos contados a partir de 0. Nos critérios de forma, o atacante fica em
(0; 0) com a mira (1; 0) e o jogador nas posições que o critério dá.

**Criar e durar**

- **AC-TG-01 [L] R2/R3/F1 — progresso.** Eco: `iniciar_telegrafo` no passo 0: `preparo` 26, `restante` 26, p = 0; após 13 passos vivos, p = 0,5; no 26º passo, p = 1 e estado `disparo`.
- **AC-TG-02 [L] R2 — mira travada.** O jogador anda 300 px durante o preparo: a mira do telégrafo continua a do passo 0.
- **AC-TG-03 [L] R2 — um por inimigo e teto.** Um 2º `iniciar_telegrafo` do mesmo inimigo é recusado. Com um dublê que injeta 24 telégrafos ativos (o jogo real do MVP, com 9 inimigos, não chega a 24), o 25º pedido é recusado; é aceito no passo em que um telégrafo sai da lista.
- **AC-TG-04 [L] R3 — acompanha o dono.** O dono é empurrado 40 px durante o preparo: a posição da forma acompanha, e a mira e as dimensões não mudam.
- **AC-TG-05 [L] R3/Edge — parado.** Hitstop de 6 passos, pausa, Bênção e Transição: `restante` e p não mudam em nenhum passo congelado.
- **AC-TG-06 [L] R3/Edge — lentidão e Abalo.** Eco no Selo (lentidão 0,5) e com Abalo: o preparo continua 26 passos.

**Formas e testes**

- **AC-TG-07 [L] R5/F2 — setor do Eco.** O telégrafo do Eco é um `setor` de raio 90 px e meio-ângulo 78,46° (± 0,01), crescimento `centro_a_borda`.
- **AC-TG-08 [L] R6/F2/F5 — teste do setor.** Eco em (0; 0) com a mira (1; 0): jogador em (80; 20): distância 82,5 e produto escalar 0,97, acerta (9 de dano pela IA dublê); em (−10; 0): não acerta; em (89,9; 0): acerta; em (90,1; 0): não acerta; a 78,40° da mira e 90 px: acerta; a 78,52°: não.
- **AC-TG-09 [L] R5/F3 — faixa do projétil.** Anomalia Menor: `retangulo` com largura 81 px e comprimento 1728 px (câmara livre); com a parede a 600 px na mira: 600 px; com um obstáculo a 400 px: 400 px. Crescimento `ao_longo_do_eixo`.
- **AC-TG-10 [L] R4/F5 — projétil.** No passo do disparo, `disparar_projetil` é chamado uma vez, na mira travada, com o jogador dentro ou fora da faixa.
- **AC-TG-11 [L] R5/F4 — avanço.** Fenda Errante: `retangulo` de 310,6 × 114 px (± 0,1), a partir de −57 px do centro do atacante; Estilhaço Vivo: 341,6 × 117; folga do canto 23,6 px na Fenda.
- **AC-TG-12 [L] R6/F4 — contato do avanço.** Durante o avanço, o jogador a 56 px do atacante: acerta; a 58 px: não acerta; no 12º passo do avanço, com o atacante a 56 px (acerta) e a 58 px (não acerta) do centro do jogador; uma segunda passagem no mesmo avanço não fere; um jogador logo atrás do atacante a 30 px também acerta.
- **AC-TG-13 [L] R5/R8 — entrega ao Pipeline.** Em cada quadro, o espião do Pipeline recebe forma, posição, rotação, dimensões, p, modo e estado de cada telégrafo: Eco `setor` 90 px, 78,46°, `centro_a_borda`; Anomalia `retangulo` 81 × 1728 px, `ao_longo_do_eixo`; Fenda `retangulo` 114 × 310,6 px, `ao_longo_do_eixo`; p 0 → 1 em passos de 1/preparo.

**Disparo, quebra e cancelamento**

- **AC-TG-14 [L] R4/R6 — invulnerável.** Jogador invulnerável (esquiva ou pós-dano) no passo do disparo dentro do setor: `ferir_jogador` não tira Vida; o telégrafo dispara igual.
- **AC-TG-15 [L] R7/Edge — quebrar.** Golpe pesado com empurrão > 0 no item 5 no passo 20 do preparo do Eco: o telégrafo vira `quebrado` (2 passos), o `ferir_jogador` não é chamado, a IA recebe a recuperação de 24 passos. Golpe pesado com empurrão 0, elite e chefe: não quebram.
- **AC-TG-16 [L] R7/Edge — cancelar.** Dono com Vida ≤ 0 antes do disparo, ou câmara nova: `cancelado` (2 passos) e nenhum dano nem projétil.
- **AC-TG-17 [L] Edge — sobreposição.** Dois telégrafos de dois Ecos acertam o jogador no mesmo passo: perde a Vida de um golpe só (invulnerabilidade de 40 passos, Combate R13).
- **AC-TG-18 [L] F6 — folga.** Eco 11, Anomalia 21, Fenda 27 passos de folga (reação de 15 passos).

**Dados e validação**

- **AC-TG-19 [I] R10/F-faixas — erros.** passos(`preparo_s`) < 1, `teto_telegrafos` < 1, ataque sem forma ou com dimensão ≤ 0: erro TV1 ou TV2, e a run não começa.
- **AC-TG-20 [I] R10/F-faixas — avisos de fábrica.** O catálogo de fábrica (Eco 26, Eco do Veio 24, Anomalia 36, Fenda 42 passos; formas derivadas do `EnemyDef`) não gera nenhum aviso TV3 a TV6; um Eco com `preparo_s` 0,3 gera o TV3 e o TV4; `teto_telegrafos` 8 gera o TV5.
- **AC-TG-21 [I] R11 — injeção.** O sistema roda com o `TelegraphTuning`, a lista de inimigos e `ferir_jogador` dublês, sem SceneTree.

**Captura e acessibilidade**

- **AC-TG-22 [V] Visual/Audio — multidão.** Captura com 9 inimigos em preparação (3 de cada tipo): cada contorno de 4 px é distinguível, o preenchimento cresce sem pulsar, os tons de cinza e os 3 simuladores de daltonismo mantêm a leitura (valor e forma).
- **AC-TG-23 [V] Visual/Audio — flash e rachadura.** Captura do disparo (flash de osso por 2 passos), da quebra (rachadura sem flash) e do cancelamento (fade em 2 passos).
- **AC-TG-24 [M] Game Feel — leitura.** Registro com testador, build e contagem: ≥ 80% evitam o primeiro golpe do Eco sem dica (proposta).
- **AC-TG-25 [L] R3/R7 — saída da lista e mira.** O telégrafo sai da lista 2 passos depois de `disparo`, `quebrado` ou `cancelado`; a mira travada é a direção do inimigo ao jogador no passo 0.
- **AC-TG-26 [L] F2/F3 — outros inimigos.** Eco do Veio: setor de 96,75 px; Anomalia do Veio: faixa de 1945,5 px (câmara livre); Estilhaço Vivo: 341,6 × 117 px.
- **AC-TG-27 [L] F5 — retângulo.** Faixa da Anomalia com origem (0; 0) e mira (1; 0): jogador em (500; 30): `x'` 500, `y'` 30, dentro; em (500; 41): fora (|y'| > 40,5); em (1730; 0): fora.

## Open Questions

| # | Pergunta | Dono | Resolver até |
|---|---|---|---|
| 1 | O teste é o centro do jogador na forma (generoso). Manter ou passar a círculo do jogador tocando a forma? | game-designer | primeiro playtest (Alpha) |
| 2 | Formas e tempos dos 4 padrões de chefe são provisórios (anel de 12, avanço, leque, invocação) | Chefes | GDD de Chefes |
| 3 | A lentidão do Selo não afeta o avanço da Fenda (cânone); o telégrafo mostra o avanço no tempo normal | IA de inimigos | GDD de IA |
| 4 | `reacao_ref_s` 0,25 s e `folga_min` 8 passos são propostas, não cânone | game-designer | primeiro playtest |
| 5 | Emendas do Art Bible §6.3 e §8.6 (telégrafo em duas passadas, orçamento 54) | art-director | próxima revisão do Art Bible |
| 6 | Leitura de ataque de fora da tela (Pulso 825 px, Armas D-I8): aviso visível na borda? | IA / Cena | GDD de IA |
| 7 | Faixa do projétil de 1656 px em multidão: custo de overdraw e atenção; limitar o comprimento desenhado? | technical-artist | Pipeline F10 / ADR |
| 8 | Índice: linha 13 com Conteúdo, IA e Câmaras em Depends On | usuário / producer | próxima edição do índice |
| 9 | Telégrafo de elite: preparo mais curto ou igual ao comum? | IA / Chefes | GDD de IA |
