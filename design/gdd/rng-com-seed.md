# RNG com seed

> **Status**: Approved (re-review `/design-review` de 2026-11-05: APPROVED; ver `reviews/rng-com-seed-review-log.md`)
> **Author**: usuário + Claude (design-system)
> **Last Updated**: 2026-11-05
> **Last Verified**: 2026-11-05
> **Implements Pillar**: P3 *Reflexo que se lê* (indireto: bugs e playtests reproduzíveis); P1/P2 (sorteios justos de bênção e porta)

> **Nota (2026-11-12, Run e regiões):** o gatilho "voltar ao Campus" vale também para `nova_run` (Encerrada → Escolha de arma; descarta a seed e os fluxos; a seed nasce ao confirmar a arma): aplicado em States and Transitions. R2 (sorteio ao confirmar a arma) e a linha "Sem run" também aplicados em 2026-11-12; a R7 já diz que o estado inicial inclui a arma.

> **Nota (2026-11-11, Bênçãos):** a Bênçãos usa o F7 por oferta (e por troca) com consumo fixo de 3 reais em `bencaos` e 3 em `raridade`, descartando `3 − min(3, n)` reais; chave (região, índice da câmara).
> **Creative Director Review (CD-GDD-ALIGN)**: pulada (modo Lean)

## Summary

**RNG com seed** é a única fonte de números aleatórios do Khaeros. Cada run tem
uma seed de 32 bits, e cada sorteio usa um fluxo próprio, derivado de
(finalidade, região, profundidade), com um gerador mulberry32 versão-estável. A
mesma seed, com o mesmo estado inicial da run e as mesmas escolhas (portas,
bênçãos e trocas de oferta), reproduz a **estrutura** da run (obstáculos, ondas,
elites, candidatos de spawn, portas, ofertas de bênção), não importa como o
jogador lute (contrato R7). Isso serve para reproduzir bugs, comparar playtests e, no futuro, um "seed do dia".

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `Conteúdo orientado a dados (suave)`

## Overview

**RNG com seed** é a única fonte de números aleatórios do jogo. Cada run nasce de
uma **seed**: um número de 32 bits, sorteado ao começar ou informado em debug.
Todo sorteio da run passa por este sistema:

- layout da câmara (obstáculos);
- composição de onda e elites;
- posição de spawn;
- portas e recompensas;
- ofertas de bênção e raridade;
- variação de comportamento da IA.

Nenhum sistema usa `randf()`, `randi()` ou um `RandomNumberGenerator` próprio
por fora.

A promessa é de **estrutura reproduzível**. A mesma seed, com o mesmo estado
inicial da run e as mesmas escolhas de porta, de bênção e de troca de oferta
(R7), gera as mesmas câmaras, ondas, elites, portas e ofertas,
**não importa como o jogador lute**. Para isso, os sorteios de estrutura não
dividem números com os sorteios de combate: lutar diferente nunca desloca a
próxima oferta.

A run inteira, quadro a quadro, **não** é reproduzível. O Godot Physics 2D não é
determinístico, e o replay por entradas do modo web ficou fora deste jogo
(conceito §3).

O jogador não vê este sistema, mas sente o que ele permite: reproduzir um bug a
partir da seed, comparar playtests sobre a mesma run e, no futuro, um "seed do
dia". Sem ele, cada sistema sortearia por conta própria e nenhuma run poderia
ser repetida.

> **→ vira ADR:** o algoritmo do gerador (o `RandomNumberGenerator` do Godot ou
> um gerador próprio, versão-estável) e o mecanismo de injeção. O ADR
> "determinismo sim/não" do plano (passo 4.2) registra a escolha de
> reprodutibilidade estrutural.

## Detailed Design

### Core Rules

> `systems-designer`, `gameplay-programmer` e `engine-programmer` não foram
> consultados: modo Lean. Revisar manualmente antes de produção.

**R1. Fonte única.** Todo número aleatório que afeta o estado do jogo vem deste
sistema. Fora dele, em código de jogo, são proibidos: `randf`, `randi`,
`randf_range`, `randi_range`, `randfn`, `RandomNumberGenerator`,
`Array.shuffle()` e `Array.pick_random()`. Os dois últimos usam o gerador global
do Godot e furam a seed sem ninguém perceber.

A única exceção é o código de **apresentação** (VFX, variação de áudio, tremor
de câmera), cujo resultado nenhuma regra de jogo lê. Esse código mora em
**`src/presentation/`** e nunca referencia a fonte de fluxos. O único ponto de
entropia permitido fora dele é a função que cria a run (R2).

**R2. Seed da run.**

- É um inteiro de 32 bits sem sinal (0 a 4.294.967.295); 0 é válido.
- Num build normal, ela é sorteada ao criar a run (ao confirmar a arma na Escolha de arma), a partir da entropia do
  sistema. Esse é o único uso permitido do gerador global.
- Num build de debug, pode ser informada: argumento `--seed=3F9A07C2` na linha
  de comando ou campo no menu de debug.
- A seed não muda durante a run.

**R3. Fluxos derivados.** Nenhum sistema sorteia "da seed". Cada sorteio usa um
**fluxo** identificado por **(finalidade, região, profundidade)**. O estado
inicial do fluxo é derivado da seed por hash (Formulas, F2). O mesmo trio sempre
gera a mesma sequência, então o que acontece numa câmara não desloca nada em
outra.

As finalidades formam uma **lista fechada**. Cada uma tem um id numérico fixo,
que nunca é renumerado:

| Id | Finalidade | Sorteia | Dono | Reproduzível |
|---|---|---|---|---|
| 1 | `ondas` | quais inimigos entram em cada onda, dentro do orçamento | Câmaras e ondas | sim |
| 2 | `elites` | quais inimigos viram elite | IA de inimigos e elites | sim |
| 3 | `spawn` | os pontos candidatos de nascimento de cada inimigo (quantidade fixa, R4) | Câmaras e ondas | sim, os candidatos; o ponto escolhido pode depender da posição do jogador |
| 4 | `portas` | quantas portas aparecem e qual recompensa cada uma mostra | Portas e recompensas | sim |
| 5 | `bencaos` | quais Tradições são oferecidas | Bênçãos (Tradições) | sim, dado o mesmo conjunto de bênçãos já pegas |
| 6 | `raridade` | a raridade de cada oferta | Bênçãos (Tradições) | sim |
| 7 | `ia` | timers e variações de comportamento em combate; reforços invocados no meio da luta (quais e onde) | IA de inimigos e elites | **não garantido**: o consumo depende do combate |
| 8 | `layout` | quantos obstáculos a câmara tem, com raio e posição de cada um | Câmaras e ondas | sim |

Uma finalidade nova entra nesta tabela, com id novo, antes de ser usada. As
finalidades **1–6 e 8** são as **finalidades de estrutura**: as que a R7
garante.

**R4. Ordem dentro do fluxo.** O sistema dono define a ordem dos sorteios no seu
fluxo e a documenta no próprio GDD. Ele itera listas do catálogo sempre **na
ordem do manifesto** (Conteúdo R10). Nunca itera ordem de `Dictionary`, de hash
ou da árvore de cena para sortear. Como isso não se verifica por varredura,
cada GDD dono tem um critério de aceite do tipo "reordenar a carga não muda o
resultado".

**R4b. Consumo fixo.** Nas finalidades de estrutura, quantos números cada
decisão consome, e em que ordem, **não pode depender do estado do combate**:
posição do jogador, Vida, inimigos vivos, tempo ou quadros. Quando a decisão
precisa do combate (por exemplo, nascer longe do jogador e fora das pedras), o
dono sorteia **sempre K candidatos** (K definido no GDD dele) e depois escolhe
um deles por uma regra determinística, sem sortear de novo. O sorteio que só
existe por causa do combate (reforços invocados no meio da luta) usa o fluxo
`ia`. Cada GDD dono tem um critério de aceite do tipo "o jogador em outra
posição não muda o estado do fluxo".

**R5. Operações.** Cada fluxo oferece exatamente estas operações, todas
determinísticas e com consumo de números definido em Formulas:

- real em [0, 1);
- inteiro em [0, n), com n ≥ 1;
- inteiro em [a, b];
- real em [a, b);
- **escolha ponderada**: recebe pesos ≥ 0 com soma > 0 e devolve um índice;
- **k distintos de n**, sem repetição: usado nas 3 ofertas de bênção;
- **embaralhar** uma cópia de lista.

Não há amostragem por rejeição sem limite. O laço com `guard < 30` que o cânone
usa nas bênçãos dá lugar a "k distintos de n".

**R6. Gerador próprio, versão-estável.** A sequência é definida pela fórmula deste
GDD (mulberry32, a mesma do cânone) e não depende da versão do Godot nem do
sistema operacional. A implementação precisa bater com valores de referência
tirados do cânone TypeScript (teste de paridade). O ADR confirma a escolha.

**R7. Contrato de reprodução.** Com os **mesmos** seis elementos:

- seed;
- versão do jogo;
- impressão do conteúdo;
- **estado inicial da run**: arma e Doutrina jurada, e o nível de cada melhoria
  da Oficina;
- sequência de escolhas de porta e de bênção;
- **usos de "Trocar ofertas"**: em que oferta cada carga foi gasta,

as finalidades de estrutura (1–6 e 8) dão **os mesmos resultados em cada
profundidade**. Não são garantidos:

- o combate (dano, tempo, posições ao longo do tempo);
- a finalidade `ia`;
- o ponto de spawn **escolhido** entre os candidatos, quando a regra do dono
  depende da posição do jogador. Os candidatos são garantidos (R4b).

O texto da seed (R8) mostra só os três primeiros elementos. O estado inicial
fica na telemetria de início de run. O caminho (escolhas de porta e de bênção e
usos de troca) fica na telemetria de fim de run. Todo relatório de erro traz os
dois.

**R8. Seed visível.**

- **Formato:** `3F9A-07C2 · v0.1.0 · c1B4E`. São 8 hex maiúsculos com hífen no
  meio, a versão do jogo (`application/config/version`) e a impressão do
  conteúdo com 4 hex.
- **Onde aparece:** na tela de pausa, nas telas de morte e de vitória e no
  overlay de debug. Também é registrada na telemetria (início da run) e em todo
  relatório de erro, junto com o estado inicial da run (R7).
- **Entrada (só debug):** 1 a 8 dígitos hex, com ou sem hífen, sem diferenciar
  maiúsculas. Qualquer outra coisa é recusada com mensagem; a seed não é
  "corrigida" em silêncio.

**R9. Injeção.** Cada sistema consumidor recebe na construção uma **fonte de
fluxos**, à qual pede o fluxo de (finalidade, região, profundidade). Não existe
singleton global de RNG. Os testes injetam uma seed fixa ou uma fonte falsa que
devolve valores pré-definidos.

Também são injetados, para que a R2 seja testável: a **fonte de entropia**, o
**tipo de build** (debug ou release) e os **argumentos de linha de comando**.
As operações F3–F8 existem também como **funções puras de u**, para os testes
partirem de um valor de u fixo.

### States and Transitions

| Estado | Significado | Entra quando | Sai para |
|---|---|---|---|
| Sem run | Menu/Campus ou Escolha de arma: não há seed; pedir um fluxo é erro | O jogo abre, ou a run termina | Run ativa |
| Run ativa | Seed fixada; fluxos derivados sob demanda | A run é criada (seed sorteada ou informada) | Encerrada |
| Encerrada | A seed fica legível para a tela final e a telemetria; qualquer pedido de fluxo, novo ou já aberto, é erro | Morte, vitória ou abandono | Sem run (ao voltar ao Campus) ou, por `nova_run`, **Escolha de arma** (sem run nem seed ainda; a seed nasce **ao confirmar a arma**, quando a run é criada, porque o estado inicial inclui a arma; Run R1/R2/R8) |

Em **Sem run**, ler a seed devolve "sem seed".

Cada fluxo nasce no primeiro pedido de (finalidade, região, profundidade) e
guarda só o estado de 32 bits. Pedir de novo o mesmo trio na mesma run devolve
**o mesmo fluxo, continuando de onde parou**. Ele não recomeça.

### Interactions with Other Systems

| Sistema | Recebe daqui | Fornece para cá | Dono da interface |
|---|---|---|---|
| Câmaras e ondas | fluxos `ondas`, `spawn`, `layout` | profundidade e região atuais | este GDD (fluxo), Câmaras (ordem dos sorteios, K candidatos) |
| IA de inimigos e elites | fluxos `elites`, `ia` | — | idem |
| Portas e recompensas | fluxo `portas` | — | idem |
| Bênçãos (Tradições) | fluxos `bencaos`, `raridade` | — | idem |
| Run e regiões | criação e fim da seed; profundidade e região | estado inicial da run; escolha de porta/bênção e uso de troca de oferta (registro do caminho) | Run |
| Conteúdo orientado a dados | — | listas em ordem do manifesto (R10); **impressão do catálogo** (Conteúdo R12: curta de 4 hex para a tela, completa de 64 hex) | Conteúdo |
| HUD / Menus / telas de fim de run | texto da seed (R8) | — | UI |
| Telemetria local | seed, versão, impressão e estado inicial no início da run; caminho (escolhas e trocas) no fim | — | Telemetria |
| Save e perfil (fatia vertical) | seed e estados de fluxo, se houver save no meio da run | — | Save |

**Impressão do catálogo:** definida no GDD de Conteúdo orientado a dados (R12,
incorporada em 2026-11-05). O texto da seed usa a forma curta, e a telemetria e o
relatório de erro podem usar a completa.

## Formulas

> Proposta do `systems-designer` (consultado: modo Lean, seção de risco alto).
> Todos os exemplos foram **calculados e cruzados** em 2026-11-05: Python 3.13 =
> Godot 4.7.2 (`godot --headless -s`) em todas as fórmulas, e Node, rodando a
> cópia literal do `nextRandom` do cânone, = Python no F1. Escolhas de k > n,
> parse e real [a,b): usuário, 2026-11-05.

Constantes (fazem parte da "versão do jogo" da R7; mudar qualquer uma muda
todas as seeds):

- `M = 0xFFFFFFFF`: máscara de 32 bits.
- `W = 0x6D2B79F5`: incremento do mulberry32 (cânone).
- `G = 0x9E3779B9`: constante de mistura da derivação.
- `C1 = 0x85EBCA6B`, `C2 = 0xC2B2AE35`: constantes do `fmix32`.

Todo inteiro entra **mascarado em 32 bits sem sinal**. Um valor negativo nunca
entra numa fórmula; a máscara é aplicada na fronteira, ao sortear a seed ou ao
ler de save.

Propriedades **verificadas por análise**, sem critério de teste: o período 2³²
do F1, o viés do F4, as permutações inalcançáveis do F8 com n ≥ 13 e a chance de
colisão de fluxos do F2.

### F1. Passo do gerador (mulberry32)

The mulberry32_step formula is defined as:

`s' = (s + W) & M ; t = imul(s' ^ (s' >> 15), s' | 1) ; t = t ^ ((t + imul(t ^ (t >> 7), t | 61)) & M) ; u = (t ^ (t >> 14)) & M`

com `imul(a, b) = (a·(b & 0xFFFF) + (((a·(b >> 16)) & 0xFFFF) << 16)) & M`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| s | int | 0–2³²−1 | calculated | estado do fluxo antes do passo |
| s' | int | 0–2³²−1 | calculated | estado novo, guardado pelo fluxo |
| W | int | 0x6D2B79F5 | constant | incremento |
| M | int | 0xFFFFFFFF | constant | máscara |
| a, b | int | 0–2³²−1 | calculated | operandos do `imul` |
| u | int | 0–2³²−1 | calculated | saída de 32 bits |

**Output Range:** `s'` e `u` em [0, 2³²−1]; período do estado = 2³². O `imul` em
metades de 16 bits nunca passa de 2⁴⁹, então não estoura o inteiro de 64 bits do
GDScript. Cada chamada consome **1 número**.
**Example:** seed 0 → u = `4434B462`, `00159C37`, `39285B08`, `256D8104`,
`77A2CBD4`. Seed `3F9A07C2` → u = `0865C80A`, `D260910A`, `B37DB9FA`,
`91FD7BCE`, `7A515CDF`.

### F2. Estado inicial de um fluxo

The stream_state formula is defined as:

`s0 = mix(mix(mix(fmix32((seed + G) & M), finalidade), região), profundidade)`

com `mix(h, x) = fmix32(((h ^ x) + G) & M)` e
`fmix32(h): h ^= h >> 16 ; h = imul(h, C1) ; h ^= h >> 13 ; h = imul(h, C2) ; h ^= h >> 16`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| seed | int | 0–2³²−1 | calculated (R2) | seed da run |
| finalidade | int | 1–8 | constant (tabela R3) | id da finalidade |
| região | int | 0–255 | calculated | índice da região na run |
| profundidade | int | 0–1023 | calculated | índice da câmara na região, a partir de 0, santuário e chefe incluídos (no MVP, com uma região, igual ao número da câmara na run); o `p` das Câmaras é outra coisa |
| s0 | int | 0–2³²−1 | calculated | estado inicial do fluxo |

**Output Range:** [0, 2³²−1]; todo valor, inclusive 0, é estado válido. O
`fmix32` é uma bijeção com efeito avalanche: com o mesmo prefixo (seed,
finalidade, região), profundidades diferentes dão **sempre** estados diferentes.
O pré-mix da seed evita que seeds vizinhas troquem fluxos entre si. Risco
aceito: dois fluxos de 32 bits podem se sobrepor deslocados, com chance da ordem
de 0,08% por run, imperceptível.
**Example:** seed `3F9A07C2`, finalidade 4 (`portas`), região 0, profundidades
0–4 → `0EC3245B`, `3043CE64`, `CFBE45BC`, `B0B08409`, `83C51646`. Seed 0,
finalidade 1, região 0, profundidade 0 → `E8A7E13D`. `fmix32(1)` = `514E28B7`.

### F3. Real em [0, 1)

The unit_real formula is defined as:

`r = u / 4294967296.0`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| u | int | 0–2³²−1 | calculated (F1) | saída do passo |
| r | float | 0 – 0,99999999976716936 | calculated | real |

**Output Range:** [0, 1 − 2⁻³²]; nunca chega a 1, e a divisão por potência de 2
é exata. Consome 1 número. É idêntico ao cânone.
**Example:** u = `4434B462` → 0,266429208685 (1ª saída da seed 0).

### F4. Inteiro em [0, n)

The bounded_int formula is defined as:

`v = (u · n) >> 32`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| u | int | 0–2³²−1 | calculated (F1) | saída do passo |
| n | int | 1–2²¹ | calculated | tamanho do intervalo |
| v | int | 0 – n−1 | calculated | resultado |

**Output Range:** [0, n−1]. Consome 1 número, inclusive com n = 1. n < 1 ou
n > 2²¹ é erro (relator de erros). Equivale ao `floor(r·n)` do cânone. Viés máximo relativo ≈
2,3 × 10⁻⁸ para n ≤ 100; nulo para potências de 2.
**Example:** n = 100: u = 42949672 → 0; 42949673 → 1; 0x80000000 → 50;
0xFFFFFFFF → 99. A partir do estado `B0B08409` (portas, profundidade 3):
n = 100 → 13; n = 6 → 0.

### F5. Inteiro em [a, b] e real em [a, b)

The range formulas are defined as:

`vi = a + F4(b − a + 1)` ; `vr = a + (b − a)·r`, e se `vr ≥ b` então `vr = a`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| a, b | int ou float | a ≤ b | data file | limites |
| r | float | [0, 1) | calculated (F3) | real |
| vi | int | a – b | calculated | inteiro |
| vr | float | [a, b) | calculated | real |

**Output Range:** vi em [a, b]; vr em [a, b). O retorno para `a` só acontece por
arredondamento extremo (b − a minúsculo perto de |a|). a > b é erro; no inteiro,
b − a + 1 > 2²¹ também. Consome 1 número.
**Example:** a = 5, b = 10, u = 0x80000000 → F4(6) = 3 → 8. a = 2, b = 4,
r = 0,25 → 2,5.

### F6. Escolha ponderada

The weighted_pick formula is defined as:

`i* = menor i tal que x < C_i`, com `C_i = Σ_{j ≤ i} w_j` e `W = C_último`.
Se **todos** os pesos são inteiros: `x = u·W`, comparado com `C_i·2³²` (exato).
Se algum peso é real: `x = r·W`, comparado com `C_i`. ±INF e NaN são erro.

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| w_i | int ou float | ≥ 0 | data file | pesos, na ordem do manifesto |
| W | int ou float | > 0 | calculated | soma dos pesos |
| u / r | int / float | F1 / F3 | calculated | número sorteado |
| i* | int | 0 – len−1 | calculated | índice escolhido |

**Output Range:** um índice com peso > 0; um peso 0 nunca é escolhido. Consome
exatamente 1 número. Lista vazia, peso negativo ou W = 0 é erro. Os pesos
`[3, 2, 1]` reproduzem o `pool` do cânone (bênção × 3, Fragmentos × 2, cura × 1).
**Example:** estado `B0B08409`: pesos `[3, 2, 1]` → 0; pesos `[0, 5, 0, 1]` → 1.

### F7. k distintos de n

The k_distinct formula is defined as:

`idx = [0 … n−1] ; k' = min(k, n) ; para i = 0 … k'−1: j = i + F4(n − i) ; troca idx[i] ↔ idx[j] ; resultado = idx[0 … k'−1]`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| n | int | ≥ 0 | calculated | tamanho do conjunto (ex.: Tradições ainda disponíveis) |
| k | int | ≥ 0 | data file | quantos tirar (3 nas ofertas) |
| k' | int | 0 – n | calculated | quantos saem de fato |
| idx | int[] | 0 – n−1 | calculated | índices na ordem do manifesto |

**Output Range:** k' índices distintos, na ordem sorteada. Com **k > n, devolve
os n** (decisão do usuário); o que fazer com a vaga vazia é decisão do GDD de
Bênçãos. Consome exatamente k' números.
**Example:** estado `B0B08409`, n = 8, k = 3 → `[1, 6, 7]`; estado final
`F832F1E8`.

### F8. Embaralhar uma cópia

The shuffle formula is defined as:

`para i = n−1 … 1: j = F4(i + 1) ; troca a[i] ↔ a[j]` (sobre uma cópia; a lista
original não muda)

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| a | lista | n ≥ 0 | calculated | cópia da lista |
| n | int | ≥ 0 | calculated | tamanho |

**Output Range:** uma permutação de `a`. Consome n − 1 números (0 se n ≤ 1). Para
n ≥ 13 nem toda permutação é alcançável por um fluxo de 32 bits; isso é aceito.
**Example:** estado `B0B08409`, `[0 … 9]` → `[3, 6, 2, 4, 0, 5, 9, 8, 7, 1]`;
estado final `8737CDA6`.

### F9. Seed como texto

The seed_text formula is defined as:

`texto = "%04X-%04X" % [u >> 16, u & 0xFFFF]` ; `parse(t)`: se `len(t) = 9` e
`t[4] = "-"`, remove o hífen; aceita se sobram 1 a 8 caracteres em
`[0-9A-Fa-f]`; senão, recusa

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| u | int | 0 – 4.294.967.295 | calculated | seed |
| t | String | texto livre | data file (entrada de debug) | texto digitado |

**Output Range:** a formatação sempre dá 9 caracteres maiúsculos. O parse devolve
[0, 2³²−1] ou recusa com mensagem. Nada é corrigido: espaços, `0x`, sinal e
hífen fora da posição 4+4 são recusados. Não usar `String.hex_to_int()`, que é
leniente.
**Example:** 1.067.059.138 → `3F9A-07C2`; 0 → `0000-0000`; 4.294.967.295 →
`FFFF-FFFF`. Aceitos: `3F9A-07C2`, `3f9a07c2` → 1.067.059.138; `7C2` → 1986;
`0` → 0. Recusados: vazio, `123456789`, `3F9A-07C`, `3F9A--07C2`, ` 3F9A07C2`,
`0x3F9A07C2`, `-1`, `G123`, `3F9A_07C2`, `12-34`.

### Vetores de referência

Viram fixture dos testes; os scripts de referência vão para `tools/` na
implementação.

| Entrada | Saída | Conferido em |
|---|---|---|
| F1, seed 0, passos 1–5 (estado) | `6D2B79F5`, `DA56F3EA`, `47826DDF`, `B4ADE7D4`, `21D961C9` | Python = Godot = Node (cânone) |
| F1, seed 0, passos 1–5 (u) | `4434B462`, `00159C37`, `39285B08`, `256D8104`, `77A2CBD4` | Python = Godot = Node |
| F1, seed `3F9A07C2`, passos 1–5 (u) | `0865C80A`, `D260910A`, `B37DB9FA`, `91FD7BCE`, `7A515CDF` | Python = Godot = Node |
| F2 fmix32(0 / 1 / FFFFFFFF) | `00000000` / `514E28B7` / `81F16F39` | Python = Godot |
| F2 (`3F9A07C2`, 4, 0, 0…4) | `0EC3245B`, `3043CE64`, `CFBE45BC`, `B0B08409`, `83C51646` | Python = Godot |
| F2 (0, 1, 0, 0) | `E8A7E13D` | Python = Godot |
| F4 a partir de `B0B08409`, n = 6 / 100 | 0 / 13 (estado `1DDBFDFE`) | Python = Godot = Node (cânone `randomInt`) |
| F4, n = 100, u = 42949672 / 42949673 / `80000000` / `FFFFFFFF` | 0 / 1 / 50 / 99 | Python = Godot = Node |
| `imul(FFFFFFFF, FFFFFFFF)` | `00000001` | Node (cânone `Math.imul`) |
| F6 a partir de `B0B08409` | `[3,2,1]` → 0; `[0,5,0,1]` → 1 | Python = Godot |
| F7 a partir de `B0B08409`, n = 8, k = 3 | `[1, 6, 7]`, estado `F832F1E8` | Python = Godot |
| F8 a partir de `B0B08409`, `[0…9]` | `[3,6,2,4,0,5,9,8,7,1]`, estado `8737CDA6` | Python = Godot |
| F9 formato e parse | lista do F9 | Python = Godot |

**Sem paridade com o cânone:** F2, F6 e F7 mudam a ordem de consumo em relação ao
modo web, porque os fluxos e "k distintos" são novos. A paridade com o cânone
vale só para F1, F3 e F4.

## Edge Cases

> `systems-designer` não consultado nesta seção: modo Lean. Os pontos de atenção
> que ele levantou em Formulas estão incorporados.

**Seed**

- **Se a seed for 0:** é válida. O F2 soma `G` antes de misturar, então não há
  fluxo degenerado.
- **Se uma seed chegar fora de 32 bits sem sinal** (negativa, ou um inteiro de
  64 bits vindo de relógio ou de save): ela é mascarada com `& M` na fronteira,
  antes de qualquer fórmula.
- **Se a seed digitada em debug for inválida:** é recusada com mensagem citando
  o texto. A run não é criada e o campo continua com o que foi digitado.
- **Se `--seed=` vier inválido na linha de comando (debug):** o jogo não cria a
  run e mostra o erro. Nunca cai em seed aleatória em silêncio.
- **Se `--seed=` vier num build de release:** é ignorado, e uma linha no log
  registra "seed ignorada em release" (R2).

**Fluxos**

- **Se um fluxo for pedido no estado Sem run:** o relator de erros registra
  (finalidade, região, profundidade, quem pediu) e a fonte devolve `null`. Não
  há `assert`, para manter o comportamento testável.
- **Se o id de finalidade não estiver na tabela R3, ou região fora de 0–255, ou
  profundidade fora de 0–1023 (inclusive negativas):** é o mesmo tratamento de
  erro do item anterior.
- **Se um fluxo for pedido no estado Encerrada, mesmo um já aberto:** erro.
  Depois do fim da run nada mais é sorteado.
- **Se um sistema pedir uma finalidade que não é dele:** não consegue. A fonte
  injetada em cada sistema **só abre as finalidades dele** (tabela R3), e o
  pedido de outra é erro. Assim dois sistemas nunca intercalam consumo no mesmo
  fluxo.
- **Se o mesmo trio for pedido de novo na mesma run** (por exemplo, a recompensa
  calculada depois da câmara limpa): devolve o mesmo fluxo, continuando de onde
  parou (estados).
- **Se uma câmara não pedir alguma finalidade** (o Santuário não tem ondas):
  nada acontece. Os fluxos das outras profundidades não mudam, porque a
  derivação é por profundidade.
- **Se uma nova run começar na mesma sessão:** os fluxos da run anterior são
  descartados no estado Encerrada → Sem run, e a nova seed deriva tudo de novo.

**Operações** (um erro **nunca consome número**, para não deslocar o resto da
sequência)

- **F4 com n < 1:** erro, devolve 0.
- **F5 com a > b:** erro, devolve a. **Com a = b:** devolve a e consome 1
  número, como qualquer chamada válida.
- **F4 com n > 2²¹, ou F5 inteiro com b − a + 1 > 2²¹:** erro, devolve 0 / a.
- **F6 com lista vazia, peso negativo, NaN, ±INF ou W = 0:** erro, devolve −1.
- **F6 com pesos inteiros cuja soma passa de 2³¹:** erro, porque o caminho exato
  `u·W` estouraria 2⁶³. Os pesos do jogo são pequenos (o cânone usa 3/2/1).
- **F7 com k = 0 ou n = 0:** lista vazia, 0 números consumidos. **Com k > n:**
  devolve n itens (decidido).
- **F8 com n ≤ 1:** devolve uma cópia, 0 números consumidos.

**Reprodução**

- **Se a impressão do conteúdo ou a versão do jogo forem diferentes:** a mesma
  seed pode dar outra estrutura. Como a tela mostra seed, versão e impressão
  juntas, a diferença fica visível no relato, e o jogo não tenta compensar.
- **Se o jogador escolher outra porta:** layout, ondas, spawn e elites das próximas
  profundidades **não mudam**. A exceção é escolher a Provação, que muda as
  regras da câmara. As ofertas de bênção podem mudar, porque o conjunto de
  bênçãos já pegas muda (R3).
- **Se a IA consumir números em ordem que depende do combate:** isso só afeta o
  fluxo `ia`, que já é "não garantido". O fluxo `ia` é a única exceção à R4
  (ordem fixa).
- **Se algum código sortear por tempo** (quadros, `Time`, delta): é proibido em
  código de jogo. Pausa e hitstop nunca mudam um resultado das finalidades de
  estrutura (1–6 e 8).
- **Se a regra de spawn do dono depender da posição do jogador** (nascer longe
  dele): o fluxo `spawn` sorteia sempre os K candidatos, e a escolha entre eles
  não sorteia nada (R4b). O jogador em outro lugar pode mudar o ponto escolhido,
  mas não o estado do fluxo nem as ondas seguintes.
- **Se um chefe invocar reforços no meio da luta:** quais e onde saem do fluxo
  `ia`, nunca de `ondas` ou `spawn` (R3).
- **Se o estado inicial da run for diferente** (outra arma, outra Doutrina,
  outro nível de melhoria): a mesma seed pode dar outras ofertas. A diferença
  aparece na telemetria e no relatório de erro (R7).
- **Se o jogador gastar uma carga de "Trocar ofertas":** o fluxo `bencaos` (e o
  de `raridade`) da profundidade continua de onde parou. Só as ofertas daquela
  profundidade mudam. As finalidades 1–4 e 8 não mudam em nenhuma profundidade.
- **Se código de apresentação ler um fluxo de jogo por engano:** a estrutura
  passa a depender de efeito visual. É proibido pela R1, e o teste de varredura
  de código (Acceptance) pega.
- **Se no futuro houver save no meio da run:** o save precisa guardar a seed
  **e o estado dos fluxos abertos da câmara atual**. Recomeçar esses fluxos do
  `s0` daria outra câmara. Fica registrado para o GDD de Save e perfil.

**Colisão**

- **Se dois fluxos diferentes se sobrepuserem deslocados** (chance da ordem de
  0,08% por run, F2): aceito. Dois sorteios parecidos em lugares diferentes não
  quebram nenhuma regra.

## Dependencies

**Depende de (upstream)**

| Sistema | Tipo | O que vem de lá | Sem ele |
|---|---|---|---|
| Conteúdo orientado a dados | Suave | Listas na ordem do manifesto (Conteúdo R10), base da R4 | Sem ordem estável, os sorteios mudariam com a ordem de carga |
| Conteúdo orientado a dados | Suave | **Impressão do catálogo** com 4 hex (R8), definida no Conteúdo R12 (SHA-256 sobre a serialização canônica) | A seed aparece sem o campo `c____`, e a R7 fica sem como provar que o conteúdo é o mesmo |
| Relator de erros (mecanismo do Conteúdo R10, forma definida em ADR) | Contrato | Destino dos erros de fluxo e de operação | Os erros não teriam onde ser registrados de forma testável |

**É dependência de (downstream)**

| Sistema | Tipo | O que recebe |
|---|---|---|
| Câmaras e ondas | Forte | Fluxos `ondas`, `spawn`, `layout`; define K (candidatos de spawn, R4b) |
| IA de inimigos e elites | Forte | Fluxos `elites`, `ia` |
| Portas e recompensas | Forte | Fluxo `portas` |
| Bênçãos (Tradições) | Forte | Fluxos `bencaos`, `raridade` |
| Run e regiões | Forte | Criação e fim da seed; é quem informa região e profundidade |
| Telemetria local | Suave | Seed, versão, impressão, estado inicial e caminho (escolhas e trocas) |
| Menus / HUD / telas de fim de run | Suave | Texto da seed (F9) |
| Save e perfil (fatia vertical) | Suave | Seed e estado dos fluxos abertos, se houver save no meio da run |

**Bidirecionalidade:** IA, Câmaras, Portas e Bênçãos já citam "RNG com seed" no
índice. Run e regiões e Telemetria local passam a citá-lo também (decisão do
usuário, 2026-11-05). Nenhum desses GDDs existe; cada um, ao ser escrito, deve
listar "RNG com seed" em Dependencies.

**Pedido ao GDD de Conteúdo (atendido):** a impressão do catálogo entrou como
R12 do Conteúdo na re-review de 2026-11-05, com o AC-46 de lá.

## Visual/Audio Requirements

Não se aplica. O RNG não tem nenhum evento visível ou sonoro. O único texto dele
é a seed (UI Requirements).

## Game Feel

Não se aplica diretamente, porque o jogador não opera este sistema. Requisito
indireto: pausa, hitstop e taxa de quadros **nunca** mudam portas, ondas ou
ofertas (R7). A sensação do combate pode ser afinada sem alterar a estrutura de
uma seed.

## UI Requirements

- **Texto da seed** (F9 + R8): `3F9A-07C2 · v0.1.0 · c1B4E`, numa linha
  discreta, sem destaque.
  - Aparece na tela de pausa, nas telas de morte e de vitória e no overlay de
    debug.
  - Fonte monoespaçada ou com algarismos tabulares, para não confundir 0/O e
    1/I. Contraste e fonte seguem o Art Bible §7.
- **Copiar seed:** um botão ou atalho na pausa e nas telas de fim. Copia o
  texto completo para a área de transferência, para relatos de bug.
- **Campo de seed (só debug):** fica no menu de debug.
  - Aceita só o que o F9 aceita.
  - Com entrada inválida, o texto continua no campo e aparece uma mensagem que
    cita o que foi digitado.
  - O texto das mensagens vem de chaves de tradução.
  - É usável por teclado e gamepad.

## Cross-References

| Documento | Seção | Uso neste GDD |
|---|---|---|
| `design/gdd/conteudo-orientado-a-dados.md` | R10 (ordem do manifesto, relator de erros), R12 | Base da R4; destino dos erros; impressão do catálogo (R12) |
| `design/gdd/game-concept.md` | §3 anti-pilares, §4 loop | Reprodução estrutural (sem replay determinístico); câmaras, portas e ofertas |
| `design/gdd/systems-index.md` | enumeração, Circular Dependencies | Donos das finalidades; dependências |
| `design/registry/entities.yaml` | `tick_rate` | Nenhum sorteio por tempo (Edge Cases) |
| Khaeros `packages/action-core/src/math.ts` | `nextRandom`, `randomInt` | Mulberry32 e F4, com paridade verificada em Node |
| Khaeros `packages/action-core/src/engine.ts` | `rollDoors`, `rollBoonOffer`, `buildWaves`, elites | Pontos que sorteiam; pesos 3/2/1 das portas |
| `docs/engine-reference/godot/modules/physics.md` | Determinism | Godot Physics "Inconsistent", motivo da promessa estrutural |

## Acceptance Criteria

> Proposta do `qa-lead` (consultado: modo Lean, seção de risco alto), ajustada às
> decisões do usuário de 2026-11-05.
>
> Evidência: **[L]** `tests/unit/rng/`; **[I]** `tests/integration/rng/`;
> **[UI]** `production/qa/evidence/`. "Fonte de teste" = seed fixa + relator de
> erros falso injetado, sem I/O.

**Gerador e paridade (F1, F3, F4, R6)**

- **AC-01 [L]** Estado `00000000`, 5 passos → estados `6D2B79F5 DA56F3EA
  47826DDF B4ADE7D4 21D961C9` e saídas `4434B462 00159C37 39285B08 256D8104
  77A2CBD4`.
- **AC-02 [L]** Estado `3F9A07C2`, 5 passos → saídas `0865C80A D260910A
  B37DB9FA 91FD7BCE 7A515CDF` (paridade com o cânone).
- **AC-03 [L]** `imul(FFFFFFFF, FFFFFFFF)` = `00000001`.
- **AC-04 [L]** F3: u = `4434B462` / `FFFFFFFF` / 0 → 0,266429208685 (±1e-12)
  / < 1 / 0.
- **AC-05 [L]** F4, n = 100: u = 42949672 / 42949673 / `80000000` / `FFFFFFFF`
  → 0 / 1 / 50 / 99. A partir de `B0B08409`: F4(6) = 0; F4(100) = 13, com
  estado final `1DDBFDFE`. n = 1 → 0 e consome 1.
- **AC-06 [L]** Para uma lista fixa de u e n ∈ {1, 2, 3, 6, 7, 100, 2²¹},
  `(u·n) >> 32` = `floor(u/2³²·n)`.

**Derivação (F2, R3)**

- **AC-07 [L]** `fmix32(0 / 1 / FFFFFFFF)` = `00000000` / `514E28B7` /
  `81F16F39`.
- **AC-08 [L]** (`3F9A07C2`, 4, 0, 0…4) → `0EC3245B 3043CE64 CFBE45BC B0B08409
  83C51646`; (0, 1, 0, 0) → `E8A7E13D`.
- **AC-09 [L]** Para as seeds 0, `3F9A07C2` e `FFFFFFFF`, as profundidades
  0…1023 dão 1024 estados distintos.
- **AC-10 [L]** As seeds −1 e 2³² + 5, passando pela fronteira, derivam o mesmo
  que `FFFFFFFF` e `00000005`.

**Operações (F5–F8, R5)**

- **AC-11 [L]** F5:
  - a = 5, b = 10, u = `80000000` → 8;
  - a = 2,0, b = 4,0, u = `40000000` → 2,5;
  - a = b = 7 → 7 e consome 1;
  - com u = `FFFFFFFF`, vr < b.
- **AC-12 [L]** F6, a partir de `B0B08409`: `[3,2,1]` → 0 e `[0,5,0,1]` → 1,
  consumindo 1. Com u = 0 e com u = `FFFFFFFF`, `[0,5,0,1]` → 1 e 3 (peso 0
  nunca sai). Pesos `[1, 2.5]` vão pelo caminho real.
- **AC-13 [L]** F7, a partir de `B0B08409`:
  - n = 8, k = 3 → `[1,6,7]`, com estado final `F832F1E8`;
  - n = 2, k = 5 → 2 índices distintos, consome 2;
  - k = 0 ou n = 0 → `[]`, e o estado não muda.
- **AC-14 [L]** F8, a partir de `B0B08409`, sobre `[0…9]` →
  `[3,6,2,4,0,5,9,8,7,1]`, estado final `8737CDA6`, lista original intacta.
  n ≤ 1 → cópia, consome 0.
- **AC-15 [L]** **Erros não consomem.** Casos:
  - F4(0);
  - F4 com n > 2²¹;
  - F5 com a > b;
  - F6 com lista vazia, peso negativo, NaN, ±INF, W = 0 ou soma inteira > 2³¹.

  Cada caso devolve o valor previsto (0 / a / −1), o relator recebe exatamente 1
  registro, o estado fica idêntico e a próxima saída é a que viria sem o erro.
- **AC-16 [L]** F7 com n = k = 200 consome exatamente 200 números.

**Seed e texto (F9, R2, R8)**

- **AC-17 [L]** Formatação: 1067059138 → `3F9A-07C2`; 0 → `0000-0000`;
  4294967295 → `FFFF-FFFF`.
- **AC-18 [L]** O parse aceita e recusa exatamente as listas do F9. Cada recusa
  gera uma mensagem que cita o texto digitado.
- **AC-19 [L]** Seed `3F9A07C2`, versão 0.1.0 e impressão falsa `1B4E`
  (injetada) → `3F9A-07C2 · v0.1.0 · c1B4E`.
- **AC-20 [I]** Com build "debug" injetado:
  - `--seed=3F9A07C2` → seed 1067059138;
  - `--seed=xyz` → nenhuma run, erro mostrado, nenhuma seed sorteada;
  - depois de N sorteios, a seed lida continua a mesma.
- **AC-21 [I]** Com build "release" injetado e `--seed=3F9A07C2` → a seed vem da
  entropia falsa e o log contém "seed ignorada em release". Mais um smoke manual
  no build exportado.
- **AC-22 [UI]** Screenshots da pausa, da morte, da vitória e do overlay de
  debug mostram o texto completo da seed. O campo de debug com entrada inválida
  mantém o texto e mostra a mensagem.
- **AC-23 [I]** A telemetria de início de run e o relatório de erro (sinks
  falsos) contêm seed, versão, impressão e estado inicial da run (arma,
  Doutrina, nível de cada melhoria). A telemetria de fim de run e o relatório
  de erro contêm o caminho: escolhas de porta e bênção e usos de troca.

**Isolamento e reprodução (R3, R4, R7, R9)**

- **AC-24 [L]** Depois de 3 saídas, pedir o mesmo trio de novo devolve o mesmo
  fluxo: a 4ª saída é a 4ª da sequência contínua.
- **AC-25 [L]** Matriz dono × finalidade:
  - Câmaras só abre 1, 3 e 8;
  - IA só abre 2 e 7;
  - Portas só abre 4;
  - Bênçãos só abre 5 e 6.

  Fora da matriz: `null`, 1 erro, nenhum fluxo criado ou consumido.
- **AC-26 [L]** Consumir 1000 números em (`ia`, 0, 2) não altera as saídas de
  (`ondas`, 0, 2) nem de (`portas`, 0, 3).
- **AC-27 [I]** **Contrato R7.**
  - **GIVEN** duas runs simuladas A e B com seed `3F9A07C2` e as mesmas escolhas
    de porta e bênção em 5 profundidades. Em cada profundidade, B consome no
    fluxo `ia` uma quantidade diferente da de A (0 contra 37), intercalada com
    os sorteios de estrutura. A e B têm o mesmo estado inicial e gastam a mesma
    carga de troca na profundidade 2.
  - **THEN** o log das finalidades 1–6 e 8 por profundidade é idêntico.
  - Controle de sanidade: trocar a seed faz os logs diferirem.
  - Variante C: igual a A, mas sem a troca na profundidade 2. As finalidades
    1–4 e 8 continuam idênticas em todas as profundidades.
- **AC-28 [I]** Pular uma finalidade (profundidade 2 sem ondas) não altera as
  ondas da profundidade 3. Uma nova run na mesma sessão, com a mesma seed,
  reproduz a primeira.
- **AC-29 [I]** A seção `[autoload]` do `project.godot` e as `static var` não
  contêm nenhuma instância de RNG.

**Estados**

- **AC-30 [L]** Em Sem run, pedir um fluxo devolve `null` e o relator falso
  recebe (finalidade, região, profundidade, solicitante); a fonte não interrompe
  a execução. Ler a seed devolve "sem seed". Em Run ativa, finalidade 0 ou 9,
  região −1 ou 256 e profundidade −1 ou 1024 recebem o mesmo tratamento.
- **AC-31 [L]** Em Encerrada, a seed é legível, e pedir qualquer trio,
  **inclusive um já aberto**, devolve `null` com erro. Ao passar para Sem run,
  os fluxos são descartados.

**Varredura (R1)**

- **AC-32 [I]** Escopo: `*.gd`, mais scripts embutidos em `*.tscn` e `*.tres`,
  sob `src/` **exceto `src/presentation/`**.
  - Padrões procurados: `\brandf\(`, `\brandi\(`, `randf_range`, `randi_range`,
    `randfn`, `rand_from_seed`, `\brandomize\(`, `\bseed\(`,
    `RandomNumberGenerator`, `\.shuffle\(`, `\.pick_random\(`, e `hex_to_int`
    no parse.
  - Única exceção permitida: o ponto de entropia da R2.
  - Em `src/presentation/`: nenhuma referência à fonte de fluxos.
  - **THEN** 0 ocorrências, com o número de arquivos varridos (> 0) no
    relatório.
  - Uma fixture com uma violação plantada tem de ser detectada.

**Desempenho (ADVISORY, `tests/performance/rng/`)**

- **AC-33** Build headless, 1.000.000 passos e 10.000 derivações: o teste
  **registra** µs/op. Referências: ≤ 2 µs por passo, ≤ 5 µs por derivação,
  ≤ 0,1 ms para abrir uma câmara (≤ 8 fluxos, ~50 sorteios). Nenhum assert de
  tempo; regressão maior que 2× vira bug S3.

**Consumo fixo (R4b)**

- **AC-34 [L]** Dono falso de spawn, com K = 14 candidatos por inimigo e regra
  "primeiro candidato a mais de 260 px do jogador", 5 inimigos, a partir de
  (`spawn`, 0, 2):
  - **GIVEN** o jogador em (100, 100) numa simulação e em (900, 500) na outra;
  - **THEN** o estado do fluxo `spawn` é idêntico depois de cada inimigo. Cada
    candidato usa 2 números (x e y, F5), então são 28 por inimigo e 140 no
    total, mesmo que os pontos escolhidos difiram.
- **AC-35 [L]** Um consumidor falso que invoca 3 reforços pelo fluxo `ia` no
  meio da luta não altera as saídas de (`ondas`, 0, 2), (`spawn`, 0, 2) nem
  (`layout`, 0, 2).

Cobertura: R1–R9 (inclusive R4b) e F1–F9 têm pelo menos um critério cada. O período, o viés, as
permutações com n ≥ 13 e a colisão de fluxos são "verificados por análise"
(Formulas).

## Open Questions

| # | Pergunta | Dono | Resolver até |
|---|---|---|---|
| 1 | ~~Algoritmo e formato da impressão do catálogo (pedido ao GDD de Conteúdo)~~ **Resolvida em 2026-11-05:** Conteúdo R12 (SHA-256, curta de 4 hex e completa de 64 hex) | systems-designer | ✅ |
| 2 | Teste de integração: hitstop e `time_scale` diferentes não mudam as finalidades de estrutura (1–6 e 8) | qa-lead | GDD de Câmaras e ondas |
| 3 | Forma do relator de erros e de como "quem pediu" é identificado | technical-director | ADR, antes de `/create-architecture` |
| 4 | Confirmar em ADR o gerador próprio e a reprodução estrutural ("determinismo sim/não", passo 4.2) | technical-director | Idem |
| 5 | Texto e chaves das mensagens de recusa da seed | ux-designer / Localização | GDD de Localização (fatia vertical) |
| 6 | Run com seed escolhida pelo jogador e "seed do dia" | game-designer | Depois da fatia vertical |
| 7 | Save no meio da run com estado dos fluxos abertos | systems-designer | GDD de Save e perfil |
