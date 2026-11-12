# Selo e Fluxo

> **Status**: Approved (2026-11-10; Efeitos de status: o AC-SF-21 passa a 28 passos de Abalo depois do círculo, F4 de Efeitos de status)
> **Author**: usuário + Claude (design-system, modo Lean)
> **Last Updated**: 2026-11-10
> **Last Verified**: 2026-11-10
> **Implements Pillar**: P3 *Reflexo que se lê* (área e tempo do Selo visíveis)

> **Nota (2026-11-11, HUD):** pendente: tirar "número de Fluxo" das opções de acessibilidade (não existe na Art Bible §7.9) ou pedir a opção ao art-director; Pronto = recarga 0 e Fluxo ≥ `custo_fluxo`, Em recarga tem precedência.

## Summary

**Selo e Fluxo** define o recurso Fluxo (0 a 100, começa cheio, passa de câmara
em câmara, sobe com o tempo e com os acertos) e o Selo, que custa 40 e planta, à
frente da mira, um círculo de 142,5 px por 3,33 s que desacelera e fere a
multidão (7,2/s × M). O dano é silencioso (sem `acerto`), e vários Selos somam o
dano, mas não a lentidão. As regras seguem o cânone convertido, com 28 critérios
de aceite e a meta de o Selo valer ~5–20% do dano num alvo.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Combate núcleo, Modificadores e atributos, Conteúdo orientado a dados, Input e controle`

## Overview

> `game-designer` e `systems-designer` não consultados nesta seção: modo Lean.

**Selo e Fluxo** define o terceiro verbo de ataque do Iniciado e o recurso que o
paga. O **Fluxo** é uma barra de 0 a 100. A run começa com ela cheia, e o Fluxo
passa de uma câmara para a outra, sem voltar a encher. Ele sobe sozinho
(3,6/s) e a cada acerto de arma (+3 por alvo). O **Selo** gasta 40 de Fluxo e
planta, 180 px à frente da mira, um círculo de 142,5 px que dura 3,33 s.
Inimigos dentro dele andam a 50% e perdem 7,2 de Vida por segundo, escalados
pelo `dano_selo` e pelos modificadores (Modificadores F2). Uma recarga de 0,5 s
separa dois Selos. Vários podem estar ativos ao mesmo tempo: o dano soma, a
lentidão não.

O jogador aperta o Selo (só pelo buffer: segurar não repete) e decide **onde**
e **quando** marcar o chão. O Selo não é o golpe que mata: ele prende a
multidão para o Ataque e o Especial terminarem. Bater no inimigo devolve
Fluxo, então quem ataca mais planta mais Selos. O Selo não sai durante a
esquiva nem durante a investida.

A **fantasia** é a de um Iniciado que já toca o Fluxo de Khaeros: ele escreve
no chão e a Beira obedece por alguns segundos. Uma linha de Ecos atravessa o
círculo e fica presa nele, e o jogador escolhe quem cai primeiro.

As regras seguem o cânone (`action-core/src/engine.ts`), convertidas para px e
segundos (Conteúdo F1–F4), com uma decisão do usuário (2026-11-10): o dano do
Selo **não** emite o evento `acerto`, como o dano de status. A zona
desenhada é a leitura, não um flash por passo.

Sem este sistema, o combate teria só a arma e a esquiva. Faltaria o recurso
que recompensa quem bate e a única ferramenta de controle de área que as duas
armas do MVP compartilham.

> **→ vira ADR:** onde vivem os Selos ativos (lista própria no estado do
> combate, como os projéteis) e o teste de sobreposição círculo × círculo sem
> `Area2D` (mesma decisão do Combate OQ1).

## Detailed Design

### Core Rules

> `game-designer`, `systems-designer` e `ai-programmer` não consultados nesta
> seção: modo Lean. As regras seguem o cânone (`engine.ts:38–45`, `:575`,
> `:783–795`, `:875–882`, `:940–945`, `:1289–1290`), convertido para px e
> segundos.

**R1. Fluxo (recurso).**

- `fluxo` é um float de 0 a `fluxo_max` (100). Este sistema guarda o valor; o
  HUD o lê.
- No início da run, `fluxo` = `fluxo_max` (confirmado, decisão do usuário, 2026-11-12; pedido da Run e regiões, Run R8). Ele **passa
  de uma câmara para a outra**: a Transição não o muda (decisão do usuário,
  2026-11-10; cânone).
- **Ganho:**
  - **regeneração:** + `regen_fluxo_s` / 60 (3,6/s = 0,06 por passo) em todo
    passo vivo, no começo do item 6 da R1 do Combate;
  - **acerto de arma:** + `fluxo_por_acerto` (3) a cada `acerto_de_arma` do
    Combate (R8.2), um por alvo, inclusive no quarto acerto. Corte da esquiva,
    parede, explosão, reflexo, status e o próprio Selo não geram Fluxo.
- Todo ganho é limitado a `fluxo_max`; o Fluxo nunca fica negativo. Somar e
  limitar em qualquer ordem dá o mesmo resultado (os dois ganhos são ≥ 0).
- No hitstop e fora de Jogo (Combate R1), o Fluxo não muda.

**R2. Plantar o Selo** (item 6 da R1 do Combate, depois do golpe do jogador).

1. A recarga do Selo, se > 0, cai 1.
2. O Selo sai se **todas** valem:
   - o Input diz "quer Selo" (só buffer, Input R6);
   - o jogador não está em esquiva (Movimento R6, lida depois do Movimento);
   - não há investida ativa, com o valor que o Combate leu **no item 5, antes
     de disparar** (guardado e entregue ao Selo; é falso no passo em que a
     investida dispara, como no cânone). A consulta ao vivo no item 6 veria a
     investida já em curso;
   - a recarga é 0;
   - `fluxo` ≥ `custo_fluxo` (40).
3. Quando sai:
   - o `selo` é removido do buffer e `fluxo` −= `custo_fluxo`;
   - a recarga passa a `passos(recarga_s)` (30): o próximo Selo pode sair 30
     passos depois;
   - nasce um Selo em `centro = prender(pos_jogador + mira × distancia_px)`. A
     `mira` é a mesma unitária do Combate (Input R5), e `distancia_px` é 180.
     `prender` limita o centro ao retângulo jogável da câmara encolhido de
     `margem_borda_px` (30) em cada lado;
   - o Selo **ignora obstáculos**: é uma marca no chão (decisão do usuário,
     2026-11-10);
   - sai o evento `selo` (centro, `raio_px`, duração em passos).
4. Quando não sai, o toque fica no buffer até sair ou expirar (Input R6). O
   evento `selo_sem_fluxo` sai **uma vez por toque novo de Selo** (o Input
   expõe "selo apertado neste passo", contrato novo; o prazo do buffer é um só,
   então o flag, não o buffer, define "toque novo"), quando φ₆ < `custo_fluxo`
   no passo do toque, seja qual for o outro bloqueio.
5. O Selo pode sair no mesmo passo de um Ataque ou de um Especial.

**R3. Selo ativo.**

- Cada Selo tem centro fixo, `raio_px` (142,5) e `restante` =
  `passos(duracao_s)` (200).
- Um inimigo está **dentro** se é atingível (Combate R9: não está surgindo e tem
  Vida > 0) e `distância(centro, inimigo) ≤ raio_px + r_inimigo`.
- No início do item 6, as marcas "no Selo" do passo anterior são zeradas.
- A cada passo vivo, no item 6, depois da R2: para cada Selo, na ordem de
  criação, e para cada inimigo da lista que esteja dentro:
  - o Selo fere com `dano_passo × M(Selo)`, em que `dano_passo` =
    `dano_selo_s` / 60 (7,2/s = 0,12 por passo) e M é a F2 do Modificadores,
    grupo Selo, avaliada a cada passo;
  - o golpe usa o **caminho silencioso** de `ferir_inimigo` (Combate R8, o mesmo
    do dano de status): só os itens 1 e 3, sem `acerto`, sem empurrão, sem
    cambaleio, sem hitstop, sem contador de acertos e sem Fluxo (decisão do
    usuário, 2026-11-10);
  - o inimigo é marcado **no Selo** neste passo;
  - com o gatilho `selo_abala`, recebe o Abalo (Modificadores R5), renovado a
    cada passo dentro do Selo.
- Um Selo plantado neste passo já fere neste passo.
- Depois, `restante` −= 1 em cada Selo; ao chegar a 0, o Selo some e sai o
  evento `selo_fim` (centro). Um Selo fere, portanto, em exatamente 200 passos
  vivos.
- Vários Selos **somam** o dano. A marca "no Selo" é uma só, mesmo dentro de
  dois.

**R4. Lentidão.**

- A consulta `no_selo(inimigo)` vale até o próximo item 6.
- A IA multiplica a **velocidade de andar** do inimigo por `fator_lentidao`
  (0,5) enquanto a consulta é verdadeira, junto com o `fator_cambaleio` do
  Combate (0,5 × 0,4 = 0,2).
- Avanços e investidas de inimigo seguem a regra da IA; no cânone a lentidão
  não os afeta (**provisório** até o GDD de IA).
- Elite e chefe também são feridos e desacelerados (cânone: o Selo não respeita
  armadura).
- Um inimigo que entra no círculo durante o item 7 só fica "no Selo" no passo
  seguinte (o cânone testa a posição antes de mover).

**R5. Mortes.** Um inimigo morto pelo Selo cai na varredura do Combate (R14):
hitstop de abate, `cura_ao_abater` e `explosao_ao_abater`, como qualquer morte.
Com Vida ≤ 0, ele deixa de ser atingível, e os Selos seguintes o pulam.

**R6. Troca de câmara e fim da run.** No quadro da metade do wipe (Combate R1,
Transição), todos os Selos ativos são apagados, sem `selo_fim`. O Fluxo e a
recarga passam como estão. Fora de Jogo (Morte, pausa, Bênção), nada do Selo
roda.

**R7. `SealTuning`** (Conteúdo R1). Durações em segundos (Conteúdo F7), taxas
por segundo (Conteúdo F3), distâncias em px (Conteúdo F4).

| Campo | Valor inicial | Cânone |
|---|---|---|
| `fluxo_max` | 100 | `FLUX_MAX` 100 |
| `regen_fluxo_s` | 3,6/s | `FLUX_REGEN_PER_TICK` 0,06 |
| `fluxo_por_acerto` | 3 | `FLUX_PER_HIT` 3 |
| `custo_fluxo` | 40 | `CAST_COST` 40 |
| `recarga_s` | 0,5 (30 passos) | `CAST_COOLDOWN_TICKS` 30 |
| `raio_px` | 142,5 | `SEAL_RADIUS` 95 u |
| `duracao_s` | 3,3333 (200 passos) | `SEAL_TICKS` 200 |
| `dano_selo_s` | 7,2/s | `SEAL_DAMAGE_PER_TICK` 0,12 |
| `fator_lentidao` | 0,5 | `slow = 0.5` |
| `distancia_px` | 180 | `aim × 120` u |
| `margem_borda_px` | 30 | `WALL + 20` u |

**R8. Injeção.** O sistema recebe por injeção:

- o `SealTuning`;
- a amostra e o buffer do Input;
- as consultas "em esquiva" (Movimento) e "investida ativa" (Combate);
- a posição do jogador e a mira;
- o aviso "câmara nova" (item 3 da Transição, Combate R1), que apaga os Selos;
- a lista de inimigos com posição, raio e "atingível";
- o retângulo jogável (Câmaras);
- `ferir_inimigo` e o M do Modificadores.

Os testes montam tudo em memória.

### States and Transitions

**Selo (cada um):**

| Estado | Entra quando | Sai quando |
|---|---|---|
| Ativo | plantado (R2) | `restante` = 0 → Expirado; câmara nova → Apagado |
| Expirado | fim da duração (`selo_fim`) | — (removido) |
| Apagado | metade do wipe (R6) | — (removido, sem evento) |

**Verbo do jogador** (estados sobrepostos):

| Estado | Condição |
|---|---|
| Pronto | recarga 0 e `fluxo` ≥ `custo_fluxo` |
| Sem Fluxo | `fluxo` < `custo_fluxo` |
| Em recarga | recarga > 0 |
| Bloqueado | em esquiva ou investida ativa |

**Mundo:** como no Combate. No hitstop e fora de Jogo, os Selos, a recarga e o
Fluxo ficam parados.

### Interactions with Other Systems

| Sistema | Recebe daqui | Fornece para cá | Dono da interface |
|---|---|---|---|
| Input e controle | consumo do `selo` no buffer | `selo` (só buffer), mira | Input |
| Movimento e esquiva | — | "em esquiva" | Movimento |
| Combate núcleo | dano silencioso via `ferir_inimigo` (caminho de status) | `acerto_de_arma`, "investida ativa" lida no item 5 (guardada), item 6 da R1, varredura de mortes, "câmara nova" | Combate (impacto), este GDD (quando e quanto) |
| Modificadores e atributos | — | M do grupo Selo (`dano_selo`), gatilho `selo_abala` | Modificadores |
| Conteúdo orientado a dados | — | `SealTuning`, conversões F3, F4, F7 | Conteúdo (formato), este GDD (semântica) |
| IA de inimigos e elites | `no_selo(inimigo)`, `fator_lentidao` | lista de inimigos (posição, raio, atingível) | este GDD (consulta), IA (como desacelera); **provisório** |
| Efeitos de status | Abalo do `selo_abala` (via Modificadores R5) | — | Modificadores / Status |
| Câmaras e ondas | — | retângulo jogável; "câmara nova" no estado Transição | Câmaras; **provisório** |
| Run e regiões | — | início da run (Fluxo cheio) | Run; **provisório** |
| HUD | `fluxo`, `fluxo_max`, recarga, `selo_sem_fluxo` | — | HUD |
| Feedback de combate (VFX) / Pipeline visual / Áudio | eventos `selo`, `selo_fim`, `selo_sem_fluxo` | — | apresentação |

## Formulas

> `systems-designer` consultado (modo Lean). Contas refeitas contra o cânone
> (`engine.ts:537–542`, `:778–795`, `:940–946`), a F11 do Combate, as F1–F3 das
> Armas, a F2 do Modificadores e as F3, F4 e F7 do Conteúdo. Este GDD não
> redefine nenhuma fórmula desses donos.

**Convenções.** `passos(t)` é o F7 do Conteúdo; `TICK_RATE` = 60. F_max =
`fluxo_max` (100); C = `custo_fluxo` (40); a = `fluxo_por_acerto` (3); r =
`regen_fluxo_s` / 60 (0,06 por passo); R_s = passos(`recarga_s`) (30); D =
passos(`duracao_s`) (200); δ = `dano_selo_s` / 60 (0,12 por passo), calculado
**uma vez, na carga**. O hitstop e os estados fora de Jogo congelam Fluxo,
recarga e Selos, então as contas de Fluxo e de duração são em **passos vivos**.
A fração viva do tempo real é ρ = R_esp / (R_esp + H_ciclo) (Armas F1).

Inimigos do Limiar (cânone `arenaContent.ts:88–96`; raio × 1,5; andar × 90):

| Inimigo | Vida (p 0) | Raio (px) | Andar (px/s) |
|---|---|---|---|
| Eco Perdido | 30 | 24 | 153 |
| Anomalia Menor | 24 | 22,5 | 117 |
| Fenda Errante | 46 | 30 | 126 |
| Anomalia Maior (chefe) | 700 | 63 | 108 |

### F1. Fluxo por passo

The flux_step formula is defined as:

`φ₅ = min(F_max, φ + a × n₅)` (acertos de arma do item 5) ;
`φ₆ = min(F_max, φ₅ + r)` (começo do item 6) ;
`s = quer_selo ∧ ¬esquiva ∧ ¬investida ∧ recarga = 0 ∧ φ₆ ≥ C` ;
`φ₆' = φ₆ − C × s` ;
`φ' = min(F_max, φ₆' + a × n₈)` (acertos do item 8, projéteis) ;
no hitstop e fora de Jogo: `φ' = φ`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| φ | float | 0–F_max | calculated | Fluxo no começo do passo |
| F_max, a, C | float | > 0 (100; 3; 40) | data file | `fluxo_max`, `fluxo_por_acerto`, `custo_fluxo` |
| r | float | ≥ 0 (0,06) | calculated | `regen_fluxo_s` / 60 (Conteúdo F3) |
| n₅, n₈ | int | ≥ 0 | calculated | `acerto_de_arma` (Combate R8.2) no item 5 e no item 8, um por alvo, inclusive no 4º acerto |
| s | bool | — | calculated | o Selo saiu neste passo (no máximo um por passo) |

**Output Range:** φ' ∈ [0, F_max]. O que passa do teto se perde. O acerto do
item 5 (Corte, Investida, Onda) já conta no teste do Selo do mesmo passo; o do
item 8 (Pulso) só conta no seguinte.
**Example:** φ = 37; um Corte acerta um Eco: φ₅ = 40, φ₆ = 40,06, o Selo sai e
φ' = 0,06. Com φ = 99 e a Onda em 5 alvos: φ₅ = min(100, 114) = 100.

### F2. Dano do Selo e passos até matar

The seal_damage formula is defined as:

`δ = dano_selo_s / 60` ; por passo, num inimigo dentro de k Selos:
`ΔVida = −k × δ × M_t` ;
um Selo em quem fica dentro n passos: `δ × n × M` (máximo `δ × D × M` = 24 M) ;
passos até matar com k Selos: `n_k = ceil(Vida / (k × δ × M))` (mata se n_k ≤ D) ;
rajada de dois Selos (0 e R_s): `S(t) = min(t + 1, D) + clamp(t − R_s + 1, 0, D)`, o
abate sai no menor t com `δ × M × S(t) ≥ Vida` ;
teto de Selos ativos: `S_max = ceil(D / R_s)` (7)

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| dano_selo_s | float | ≥ 0 (7,2) | data file | `SealTuning` |
| M_t | float | ≥ 0 | calculated | F2 do Modificadores, grupo Selo, a cada passo; `vida_abaixo` vale; `apos_esquiva` e `enesimo_acerto` não |
| k | int | 0–S_max | calculated | Selos que contêm o inimigo no passo |
| Vida | float | > 0 | data file / calculated | Vida atual do alvo |
| D, R_s | int | ≥ 1 (200; 30) | calculated | passos(`duracao_s`), passos(`recarga_s`) |
| S(t) | int | 0–2D | calculated | "Selo-passos" acumulados no alvo |

**Output Range:** dano ≥ 0, sem teto; com M = 0 o Selo só desacelera. O dano não
é limitado à Vida restante (Combate R8). Pico: S_max × δ = 0,84 por passo
(50,4/s × M), a 280 de Fluxo em 180 passos. Os 200 passos vivos duram ~267 passos
reais com a Lâmina (4,45 s) e ~213 com a Ressonância (3,56 s). No catálogo do
cânone o M do Selo chega a ≈ 4,2 (100,8 por Selo).
**Example (M = 1):**

| Inimigo | p | Vida | 1 Selo sozinho | Selos em fila | Rajada (0 e 30): abate no passo |
|---|---|---|---|---|---|
| Eco | 0 | 30 | não (fica com 6) | 2 | 139 (=) |
| Anomalia | 0 | 24 | **mata no 200º passo (=)** | 1 (=) | 114 (=) |
| Fenda | 0 | 46 | não (22) | 2 | 213 |
| Fenda | 1 | 48 | não (24) | 2 (=) | 229 (=) |
| Fenda | 4 | 55 | não | 3 | não mata |
| Chefe | — | 700 | não | 30 (97,2 s vivos) | não |

Com M = 1, toda Vida múltipla de 3 empata o passo (±1, inofensivo); só
Vida = k × 24 decide se o alvo **sobrevive** no último passo (SV10; Open
Questions). Com Forma Fixa Comum (M 1,6), um Selo sozinho mata o Eco de p 0 no
157º passo de dano (t = 156 contando de 0).

### F3. Ganho médio de Fluxo por arma

The flux_income formula is defined as:

`k = R_esp / R_atk` ; `acertos_ciclo = k × m + N` ;
`G_vivo = regen_fluxo_s + a × acertos_ciclo × 60 / R_esp` (Fluxo/s vivo) ;
`H_ciclo = k × h̄_atk + h_esp(N)` ; `G_real = G_vivo × R_esp / (R_esp + H_ciclo)` ;
por passo: `g = G_vivo / 60`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| R_atk, R_esp | int | ≥ 1 (16/70; 14/90) | calculated | recargas do Ataque e do Especial (Armas F1) |
| m, N | int | ≥ 1 | calculated | alvos por Ataque e por Especial (Pulso sempre 1) |
| h̄_atk, h_esp(N) | float | ≥ 0 | calculated | hitstop médio do Ataque (Corte 4; Pulso 0) e do Especial (Onda 6; Investida 6 + 3 × (N − 1), pior caso) |
| G_vivo, G_real | float | ≥ regen | calculated | Fluxo por segundo vivo e real |

**Output Range:** G_vivo ≥ `regen_fluxo_s`, sem teto (cresce com os alvos).
Premissas de teto da F1 das Armas (jogador perfeito, todo golpe com alvo). O
Fluxo real chega em degraus de 3 por alvo.
**Example:**

| Cenário | G vivo (/s) | G real (/s) |
|---|---|---|
| Só regeneração | 3,60 | 3,60 |
| Lâmina combinada, 1 alvo | 17,42 | 13,04 |
| Lâmina, Corte 1, Investida 5 | 27,71 | 18,38 |
| Lâmina, Corte 3, Investida 5 | 50,21 | 33,31 |
| Ressonância combinada, 1 alvo | 18,46 | 17,30 |
| Ressonância, Pulso 1, Onda 5 | 26,46 | 24,80 |

**Nenhum golpe paga um Selo sozinho:** a Onda em 5 alvos rende 15 (< 40); só
≥ 14 alvos pagariam 40. Em grupo, a Lâmina ganha até ~2× o Fluxo da Ressonância
(decisão do usuário, 2026-11-10: aceitar e vigiar no playtest).

### F4. Ritmo de Selos

The seal_rhythm formula is defined as:

`T = max(R_s, C / g)` passos vivos entre Selos, em regime ;
`A = min(g / C, 1 / R_s) × D` (Selos ativos em média) ;
rajada da barra cheia: `t_k = max((k − 1) × R_s, ⌈(k × C − F_max) / g⌉)`, com
`t_1 = 0` ;
laço de recarga: `g ≥ C / R_s`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| g | float | ≥ r | calculated | F3, por passo vivo |
| T | float | ≥ R_s | calculated | intervalo médio entre Selos |
| A | float | 0–6,67 | calculated | Selos ativos em média |
| t_k | int | ≥ 0 | calculated | passo vivo do k-ésimo Selo, apertando sempre que pode |

**Output Range:** T ≥ 0,5 s; A ≤ 6,67 (pico S_max = 7). O laço (Selo a cada
recarga) pede G_vivo ≥ 80/s, que nenhum cenário da F3 alcança (a Lâmina precisa
de ≥ 5,53 alvos em todo golpe; a Ressonância, de ≥ 32 na Onda). Manter um Selo
sempre ativo custa 12/s, e as duas armas passam disso num alvo só.
**Example:**

| Cenário | T (s vivos) | A | 3º Selo (passo) |
|---|---|---|---|
| Só regeneração | 11,11 | 0,30 | 334 |
| Lâmina combinada, 1 alvo | 2,30 | 1,45 | ≈ 69 |
| Lâmina, Corte 3, Investida 5 | 0,80 | 4,18 | 60 |
| Ressonância combinada, 1 alvo | 2,17 | 1,54 | ≈ 65 |
| Ressonância, Onda 5 | 1,51 | 2,20 | 60 |

Só regeneração: Selos em 0 (100 → 60) e 30 (61,8 → 21,8); o 3º precisa de
18,2 / 0,06 → 304 passos depois, no passo 334.

### F5. Fração do dano vinda do Selo

The seal_damage_share formula is defined as:

`DPS_selo_real = A × dano_selo_s × M_selo × n_dentro × ρ` ;
`DPS_arma_real = D_ciclo × M × 60 / (R_esp + H_ciclo)` (somado em todos os
alvos; Armas F1) ;
`f_selo = DPS_selo_real / (DPS_selo_real + DPS_arma_real)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| A | float | 0–6,67 | calculated | F4 |
| M_selo, M | float | ≥ 0 | calculated | F2 do Modificadores, grupo Selo / grupos de arma |
| n_dentro | int | ≥ 1 | calculated | alvos dentro de todos os Selos o tempo todo |
| ρ | float | 0–1 | calculated | fração viva (Lâmina 0,749 em 1 alvo e 0,664 com Investida 5; Ressonância 0,9375) |
| f_selo | float | 0–1 | calculated | parte do dano total vinda do Selo |

**Output Range:** 0 a 1; é um **teto** (todo Selo gasto inteiro no mesmo
grupo, ninguém morre).
**Example (M = 1):**

| Cenário | f_selo |
|---|---|
| Lâmina, 1 alvo | 10,5% |
| Ressonância, 1 alvo | 13,4% |
| Lâmina, Corte 1 + Investida 5, 5 no Selo | 31,8% |
| Ressonância, Onda 5, 5 no Selo | 34,4% |
| 1 alvo, M_selo 2,8 (Forma Fixa Épica + Fluxo Profundo 3) | 24,8% (Lâmina) / 30,3% (Ressonância) |

**Leitura:** o Selo é fraco como dano em alvo único e forte em grupo, como diz
o Overview ("prende a multidão"); no chefe é quase só lentidão (108 → 54 px/s).
**Meta** (decisão do usuário, 2026-11-10, aviso SV12; passa a valer com **M = 4**,
o `teto_multiplicador_dano` provisório do Modificadores F2, decisão de 2026-11-12):
f_selo entre 0,05 e 0,20 em 1 alvo e ≤ 0,45 em grupo de 5 (proposta, não cânone).
**Conta com M = 4:** com `M_selo` e `M` no mesmo valor (os dois no teto de 4), o fator
se cancela na razão `f_selo`; os números da tabela acima não mudam (Lâmina 10,5% e
31,8%; Ressonância 13,4% e 34,4%), dentro da meta. Cenário misto (M do Selo no teto e
M da arma menor) não foi calculado aqui.

### F6. Centro do Selo preso ao retângulo jogável

The seal_center_clamp formula is defined as:

`bruto = pos_jogador + mira × distancia_px` ;
`centro.x = clamp(bruto.x, x0 + m, x1 − m)` ; `centro.y = clamp(bruto.y, y0 + m, y1 − m)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| pos_jogador | vec2 | dentro do jogável | calculated | posição após o Movimento |
| mira | vec2 | unitária | calculated | a do Combate (Input R5) |
| distancia_px | float | ≥ 0 (180) | data file | `SealTuning` |
| x0, y0, x1, y1 | float | jogável 1920×1080 a 2880×1620 | data file (Câmaras) | retângulo jogável (Cena R6) |
| m | float | ≥ 0 (30) | data file | `margem_borda_px` |

**Output Range:** o centro fica no retângulo encolhido; exige `x1 − x0 ≥ 2m` e
`y1 − y0 ≥ 2m` (hoje 60 contra 1080; erro SV3 se não). O clamp é **por eixo**:
perto da parede o centro escorrega ao longo dela, e obstáculos são ignorados.
**Example (câmara 1920×1080):** jogador (960, 540), mira (1, 0) → (1140, 540).
Jogador (100, 540), mira (−1, 0) → (30, 540). Jogador (27, 540), mira (−1, 0) →
(30, 540): o Selo nasce centrado no jogador e pega quem o cerca.

### F7. Lentidão efetiva e travessia

The seal_slow formula is defined as:

`v_ef = v_andar × (no_selo ? f_l : 1) × (cambaleando ? f_c : 1)` (k ≥ 1 Selos:
um só f_l) ;
`t_trav = 2 × (raio_px + r_i) / (v_andar × f_l)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| v_andar | float | > 0 (108–153) | data file | andar do `EnemyDef` (Conteúdo F2) |
| f_l, f_c | float | 0–1 (0,5; 0,4) | data file | `fator_lentidao`, `fator_cambaleio` (só comuns) |
| r_i | float | > 0 | data file | raio do inimigo |

**Output Range:** v_ef ∈ [0, v_andar]; o menor caso é × 0,2. Vários Selos não
multiplicam a lentidão. Avanços e investidas de inimigo seguem a IA (provisório,
R4).
**Example:** Eco no Selo: 76,5 px/s; no Selo e cambaleando: 30,6; atravessa em
4,35 s (> 3,33 s de duração). Chefe: 54 px/s, 7,61 s. Com f_l > 0,653 ou
`raio_px` < 103,5, o Eco cruza antes de o Selo acabar.

### Faixas do `SealTuning`

| Campo | Inicial | Faixa | O que quebra fora dela |
|---|---|---|---|
| `fluxo_max` | 100 | 80–160 | < 80: a barra cheia paga só 1 Selo; > 160: 4 Selos seguidos; < custo: erro (SV1) |
| `regen_fluxo_s` | 3,6/s | 1,8–6,0 (aceita 0) | < 1,8: um Selo a cada > 22 s sem bater; > 6: o acerto perde peso; ≥ 12: Selo permanente sem bater (SV5) |
| `fluxo_por_acerto` | 3 | 1–4 (aceita 0) | 0: o Selo não recompensa bater; ≥ 5,53: Selo a cada recarga com a Lâmina (SV6) |
| `custo_fluxo` | 40 | 35–50 | < 33,4: 3 Selos seguidos; > 50: só 1; > `fluxo_max`: erro (SV1) |
| `recarga_s` | 0,5 (30) | 0,25–1,0 (15–60) | < 15: até 14 Selos ativos; ≥ duração: Selos nunca se sobrepõem (SV7); não aceita 0 |
| `raio_px` | 142,5 | 105–195 | < 103,5: o Eco atravessa antes do fim; > 195: cobre mais que a Onda |
| `duracao_s` | 3,3333 (200) | 2,5–4,0 (150–240) | < 150: a zona some antes da multidão chegar; ≥ 250 passos: um Selo mata o Eco de p 0 |
| `dano_selo_s` | 7,2/s | 4,8–8,4 | < 4,8: só controle; ≥ 9: um Selo mata o Eco de p 0 |
| `fator_lentidao` | 0,5 | 0,35–0,65 | < 0,35: o Eco parece congelado; > 0,653: cruza o Selo antes do fim |
| `distancia_px` | 180 | 120–210 | ≤ 115,5: pega as costas; > 214,5: quem encosta na frente fica fora (SV8) |
| `margem_borda_px` | 30 | 0–60 (aceita 0) | > 187,5: inimigo na parede escapa de todo Selo (SV9); 2 × margem ≥ lado da câmara: erro (SV3) |

Faixas inclusivas. `recarga_s` e `duracao_s` são comparados em passos (F7 do
Conteúdo). Os limites com inimigos usam r_min = 22,5 (Anomalia) e o Eco.

### Validação do `SealTuning`

Somam-se às faixas do V2 do Conteúdo. **Erros** vão para a tela de erros do
catálogo e a run não começa; **avisos** ficam no registro de validação.

| Regra | Tipo | Condição | Por quê |
|---|---|---|---|
| SV1 | erro | `fluxo_max` ≤ 0, `custo_fluxo` ≤ 0, ou `custo_fluxo` > `fluxo_max` | Selo grátis ou impossível |
| SV2 | erro | passos(`recarga_s`) ou passos(`duracao_s`) < 1; `raio_px` ≤ 0; `fator_lentidao` ∉ [0, 1]; `regen_fluxo_s`, `fluxo_por_acerto`, `dano_selo_s`, `distancia_px` ou `margem_borda_px` < 0 | Selo sem recarga, que acelera, cura ou drena Fluxo |
| SV3 | erro, cruzada com Câmaras | 2 × `margem_borda_px` ≥ largura ou altura do jogável de alguma câmara | `prender` sem solução |
| SV4 | aviso | `fluxo_max` < 2 × `custo_fluxo`, ou ≥ 4 × `custo_fluxo` | a rajada de abertura some ou vira 4 Selos |
| SV5 | aviso | `regen_fluxo_s` × `duracao_s` ≥ `custo_fluxo` | a regeneração mantém um Selo sempre ativo (hoje 12 contra 40) |
| SV6 | aviso, cruzada com Armas | `custo_fluxo` ≤ `fluxo_por_acerto` × `alvos_ref`, ou G_vivo (F3, `alvos_ref` alvos em todo golpe) ≥ `custo_fluxo` × 60 / passos(`recarga_s`) em alguma arma | laço de Fluxo (hoje 9 contra 40; Lâmina 45,1 contra 80) |
| SV7 | aviso | passos(`recarga_s`) ≥ passos(`duracao_s`) | "vários somam" vira letra morta |
| SV8 | aviso, cruzada com Movimento e Inimigos | `distancia_px` > `raio_px` + `raio_jogador_px` + 2 × r_min, ou ≤ `raio_px` − `raio_jogador_px` | zona cega na frente (214,5) ou Selo que cobre as costas (115,5) |
| SV9 | aviso, cruzada com Inimigos | `margem_borda_px` > `raio_px` + 2 × r_min | inimigo na parede fora de todo Selo |
| SV10 | aviso, informativo, cruzada com Inimigos | para cada comum do pool e p de 0 a `p_max`: Vida_p ≤ δ × D, ou Vida_p = k × δ × D para k de 1 a 3 (tolerância 1e-6) | o Selo vira o golpe que mata, ou a morte no último passo depende do double. **Dispara no catálogo de fábrica:** Anomalia p 0 e Fenda p 1 (aceito, decisão do usuário) |
| SV11 | aviso | campo fora da faixa de design | as contas deste GDD deixam de valer |
| SV12 | aviso, cruzada com Armas | f_selo (F5, M = 4, o teto do Modificadores F2) fora de 0,05–0,20 em 1 alvo, ou > 0,45 em grupo de 5, em alguma arma | o Selo vira enfeite ou o dano principal |

**Saída do validador:** uma entrada por regra e por objeto; o erro suspende o
aviso da mesma regra. **Constantes do validador** (proposta): `alvos_ref` 3,
`f_selo_min` 0,05, `f_selo_max` 0,20, `f_selo_grupo_max` 0,45; ficam no recurso de
validação do `ArmasTuning.p_max` (4), **fora** do `SealTuning`. SV3, SV6, SV8–SV10
e SV12 dependem de dados de outros sistemas e rodam onde roda o MV1 do Movimento
(Movimento OQ3).

## Edge Cases

> `systems-designer` não consultado nesta seção: modo Lean.

**Fluxo**

- **Se o Fluxo estiver cheio:** regeneração e acertos são perdidos (F1). Não há banco de reserva.
- **Se o Fluxo estiver abaixo de 40 e o jogador tocar o Selo:** o toque fica no buffer. Sai um `selo_sem_fluxo` por toque novo (flag "selo apertado neste passo" do Input). Se o Fluxo chegar a 40 antes de o buffer expirar (10 passos vivos sem toque novo), o Selo sai.
- **Se o Fluxo chegar a 40 exatamente:** o Selo sai (`≥`).
- **Se um acerto do item 5 completar os 40 no mesmo passo do toque:** o Selo sai nesse passo (F1, φ₆). Um acerto do item 8 (Pulso) só vale no passo seguinte.
- **Se vários alvos forem atingidos pelo mesmo golpe:** cada alvo soma +3 (Onda em 5 alvos: +15), limitado ao teto.
- **Se `regen_fluxo_s` for 0 no dado:** o Fluxo só sobe por acerto; é aceito (o SV5 não dispara).

**Plantar**

- **Se o toque vier durante a esquiva ou a investida:** o toque fica no buffer e, se ainda valer, o Selo sai no primeiro passo em que a consulta está falsa (o último passo da esquiva, com o restante passando de 1 a 0; Movimento R6) ou no passo em que a investida deixa de estar ativa.
- **Se o Selo e a investida forem pedidos no mesmo passo:** a investida dispara primeiro (item 5); o Selo, que roda depois, usa o valor de "investida ativa" lido no item 5 (falso) e sai nesse passo (cânone). Ele nasce na posição do jogador depois do Movimento.
- **Se a mira for zero:** vale a última mira do Combate (Input R5).
- **Se o jogador mirar na parede estando colado nela:** o centro vai ao limite da margem e o Selo nasce centrado no jogador (F6): um "Selo à minha volta", sem erro. O VFX não o trata como falha.
- **Se o centro cair dentro de um obstáculo:** o Selo nasce ali; obstáculos são ignorados (R2).
- **Se o jogador tocar duas vezes seguidas durante a recarga:** o toque só fica no buffer e sai se a recarga restante for ≤ 10 passos (o buffer dura 10 passos vivos, Input F3); com mais que isso, o toque se perde.

**Selo ativo**

- **Se um inimigo estiver surgindo:** não é atingível; não leva dano e não fica "no Selo". Ao terminar o surgimento, entra normalmente.
- **Se dois Selos se sobrepuserem sobre o mesmo inimigo:** o dano soma; a lentidão e o Abalo não (R3).
- **Se um inimigo morrer pelo Selo no meio do item 6:** os Selos seguintes do mesmo passo o pulam. A varredura (item 9) fecha a morte com o hitstop de abate.
- **Se o jogador morrer no mesmo passo:** o item 6 roda por inteiro nesse passo; a partir do seguinte o orquestrador sai de Jogo e o Selo para (Combate R14).
- **Se um hitstop começar:** Selos, recarga e Fluxo ficam parados até o fim; o Selo dura 200 passos **vivos**, mais tempo real (F2).
- **Se `duracao_s` ou `recarga_s` resultar em 0 passos:** é erro (SV2); a run não começa.
- **Se o M do Selo for 0:** o Selo desacelera e abala, sem dano.

**Troca de câmara e fim da run**

- **Se a câmara trocar com Selos ativos:** são apagados na metade do wipe, sem `selo_fim`. O Fluxo e a recarga passam (R6).
- **Se o jogo pausar ou a Bênção abrir:** nada do Selo roda; o buffer segue a regra do Input.
- **Se a run terminar por morte:** o Fluxo e os Selos não são guardados; a próxima run começa com Fluxo 100.

**Números**

- **Se um inimigo entrar no Selo, sair e entrar de novo:** só recebe dano nos passos em que está dentro; sem acúmulo extra.
- **Se a Vida do alvo for k × 24 (empate no último passo):** o resultado depende do double e é fixado no teste (SV10, decisão do usuário).
- **Se o jogador estiver no canto de uma câmara 1920×1080:** o centro (canto 30; 30, com o jogador em (60; 60)) fica a 42,4 px dele (F6) e o Selo ainda o cobre (raio 142,5).

**Conflitos com outros GDDs:** nenhum nas partes já aprovadas. O Combate R8 e a R17 foram ajustados em 2026-11-10 (o Selo não emite `acerto`).

## Dependencies

**Depende de (upstream)**

| Sistema | Tipo | O que vem de lá | Sem ele |
|---|---|---|---|
| Combate núcleo | Forte | `acerto_de_arma` (Fluxo), "investida ativa", `ferir_inimigo` (caminho silencioso), item 6 da R1, varredura de mortes | o Selo não fere nem ganha Fluxo |
| Modificadores e atributos | Forte | M do grupo Selo (`dano_selo`, F2), gatilho `selo_abala` | dano sem bênçãos, sem Abalo |
| Conteúdo orientado a dados | Forte | `SealTuning`, conversões F3, F4, F7, validação V2 | números no código |
| Input e controle | Forte | `selo` (só buffer), mira | não há comando |
| Movimento e esquiva | Suave | "em esquiva" | o Selo sairia durante a esquiva |
| Armas das Doutrinas | Suave | recargas, DPS e Vida por profundidade (Formulas F3–F5, SV6, SV12) | as metas de validação ficam sem referência |
| IA de inimigos e elites | Forte, **por contrato** | lista de inimigos (posição, raio, atingível) | não há alvo |
| Câmaras e ondas | Suave, **por contrato** | retângulo jogável; "câmara nova" | câmara padrão 1920×1080 sem obstáculos |
| Run e regiões | Suave, **por contrato** | Fluxo cheio no início da run | o Fluxo começa em `fluxo_max` por padrão |

**É dependência de (downstream)**

| Sistema | Tipo | O que recebe |
|---|---|---|
| IA de inimigos e elites | Forte | `no_selo(inimigo)` e `fator_lentidao` |
| Efeitos de status | Suave | Abalo do `selo_abala` |
| Bênçãos (Tradições) | Suave | `dano_selo_pct`, `selo_abala`, bênçãos de Fluxo (Transmutação) |
| HUD | Suave | `fluxo`, `fluxo_max`, recarga, `selo_sem_fluxo` |
| Feedback de combate (VFX) / Pipeline visual / Áudio | Suave | eventos `selo`, `selo_fim`, `selo_sem_fluxo` |
| Telemetria local | Suave | Selos plantados, Fluxo gasto e `selo_sem_fluxo` por run |
| Rito de Iniciação e Campus (fatia vertical) | Suave | Fluxo Profundo (melhoria permanente de `dano_selo_pct`, Conteúdo) |

**Bidirecionalidade:**

- Combate, Modificadores, Conteúdo, Input e Movimento já listam o Selo e Fluxo.
  O Combate R8 e a R17 foram ajustados em 2026-11-10 (o Selo não emite `acerto`).
- IA, Status, Bênçãos, HUD, VFX, Telemetria, Câmaras, Run e Campus ainda não
  existem. Cada um, ao ser escrito, deve listar "Selo e Fluxo" em Dependencies e
  honrar os contratos acima.
- **Índice:** a linha 10 lista Combate, Modificadores, Conteúdo e Input;
  acrescentar Movimento (suave) e IA, Câmaras e Run (suaves, por contrato).

## Visual/Audio Requirements

> `art-director` e `audio-director` não consultados: modo Lean.

- **Gramática do jogador** (Combate Visual/Audio, Pipeline R6): o Selo é ação do
  Iniciado, então o **anel do Selo é tracejado em osso de mundo** `#CFC6B4`
  (L* ≤ 82), com a largura, o traço e o intervalo do tracejado do Pipeline
  (escalados com a resolução). Nunca em magenta (perigo e custo, Art Bible §4).
- **Zona:** o interior do círculo é um tom levemente mais claro que o chão
  (preenchimento fraco, sem brilho), para ler a área sem cobrir telégrafos nem
  personagens. Fica abaixo do y-sort (Cena R4), nunca acima dos personagens.
- **Tempo restante:** o anel perde segmentos até sumir no passo 199; sem piscar
  (limite de 3 flashes/s). A leitura é em **passos vivos**, não em tempo real.
- **Eventos:**
  - `selo`: o anel é desenhado em 3 passos de apresentação, do jogador até o
    centro, com um estalo de tinta;
  - `selo_fim`: o tracejado se desfaz em fiapos de tinta, sem flash;
  - `selo_sem_fluxo`: a barra de Fluxo do HUD pisca uma vez em osso, com um som
    seco (sem tela cheia, sem vermelho).
- **Inimigo no Selo:** só um tracejado fino sob os pés, em osso; sem tinta no
  corpo, para não competir com o flash de acerto nem com o Abalo.
- **Áudio** (requisito provisório): som de escrita na pedra (curto, grave) ao
  plantar; zumbido baixo e contínuo enquanto houver Selo; silêncio no fim.
- **Multidão:** vários Selos desenham os anéis, mas só o preenchimento mais
  recente fica visível.

> 📌 **Asset Spec** — rodar `/asset-spec system:selo-e-fluxo` depois do Art
> Bible: anel tracejado, preenchimento da zona, fiapos de dissolução, ícone e
> barra de Fluxo.

## Game Feel

- **O verbo da posição:** o Selo é decidido pelo "onde". O jogador mira, toca e
  vê a área no mesmo passo (alvo: o anel aparece no passo do toque, no máximo 1
  passo de apresentação depois).
- **Peso:** sem hitstop e sem câmera. O jogador sente o Selo pela multidão que
  atola, não por um soco.
- **Ritmo:** com uma arma batendo, um Selo a cada ~2–3 s; sem bater, a barra
  obriga a esperar ~11 s.
- **Leitura da barra:** 40 é o limiar; o HUD marca o ponto com um traço.
- **Alvo de playtest:** os testadores descrevem o Selo como "prende e fere a
  multidão", sem dica (registro [M]).

## UI Requirements

- **Barra de Fluxo** (HUD): valor 0–`fluxo_max`, com a marca do custo (40);
  estados Pronto, Sem Fluxo e Em recarga (a recarga é curta, 0,5 s; basta
  escurecer o ícone).
- **Ícone do Selo** ao lado da barra, com o botão do Input (`selo`, remapeável).
- Pisca de `selo_sem_fluxo` (uma vez por toque novo). Sem número de Fluxo por
  padrão; o número entra nas opções de acessibilidade.
- HUD e VFX contam a duração em passos vivos (Formulas, F2).

> **📌 UX Flag — Selo e Fluxo:** a barra e o ícone são parte do HUD. No
> Pre-Production, rodar `/ux-design` para o HUD (`design/ux/hud.md`) antes das
> epics.

## Cross-References

| Documento | Seção | Uso neste GDD |
|---|---|---|
| `design/gdd/combate-nucleo.md` | R1 (item 6), R8, R9, R14, R17, F11, V1, V9 | ordem do passo, caminho silencioso, atingível, varredura, eventos, DPS de referência |
| `design/gdd/modificadores-e-atributos.md` | R5, R12, F2, tabela de consumidores | M do Selo, Abalo, `dano_selo_pct`, `selo_abala` |
| `design/gdd/conteudo-orientado-a-dados.md` | R1, V2, F3, F4, F7 | `SealTuning`, validação, conversões |
| `design/gdd/input-e-controle.md` | R5, R6, R10 | mira, buffer do `selo`, contexto Transição |
| `design/gdd/movimento-e-esquiva.md` | R6 | "em esquiva" |
| `design/gdd/armas-das-doutrinas.md` | F1–F3 | recargas, DPS e Vida por profundidade (F3–F5) |
| `design/gdd/pipeline-visual.md` | R6 | traço do jogador, anéis de área |
| `design/gdd/cena-3-4-e-camera.md` | R4, R6 | camadas, retângulo jogável |
| `design/gdd/game-concept.md` | §3, §6 | Selo como "feitiço de área" de Fluxo |
| Khaeros `packages/action-core/src/engine.ts` | `:38–45`, `:575`, `:783–795`, `:875–882`, `:940–945` | números e regras do Selo e do Fluxo |
| Khaeros `packages/combat-rules/src/arenaContent.ts` | `:153`, `:206` | Forma Fixa e Fluxo Profundo (M do Selo) |

## Acceptance Criteria

> `qa-lead` não consultado: economia de tokens; a revisão única do GDD cobre
> regras e critérios. Os valores de F3–F5 (ritmo e fração) são conferidos pelo
> validador (AC-SF-24) e pelo `/balance-check`, não por critério de jogo.

**Fixture FS** (provisório: dublês de Combate, Movimento, Input e Câmaras):
`SealTuning` de fábrica, Fluxo 100, jogador em (960; 540), mira (1; 0), jogável
1920×1080 a partir de (0; 0), Saco imóvel (Vida 1000, raio 24) e M = 1, salvo
quando o critério diz.

**Fluxo**

- **AC-SF-01 [L] R1/F1 — regeneração.** Fluxo 0, 100 passos vivos: 6,00 (± 1e-6).
- **AC-SF-02 [L] R1/F1 — teto.** Fluxo 99,97, um passo: 100,00. Com a Onda em 5 alvos a Fluxo 99: 100,00 (os 14 de sobra se perdem).
- **AC-SF-03 [L] R1 — acerto de arma.** Fluxo 10, um Corte acerta o Saco no item 5: +3 e a regeneração do passo = 13,06. Corte da esquiva, parede, explosão, reflexo, dano de status e dano do Selo não somam nada.
- **AC-SF-04 [L] R1 — por alvo.** A Onda em 3 alvos (Fluxo 0): +9 num passo; o 4º acerto de um alvo também soma +3.
- **AC-SF-05 [L] R1/Edge — congelado.** Fluxo 50, hitstop de 6 passos, pausa e Transição: o Fluxo não muda em nenhum passo congelado nem fora de Jogo.
- **AC-SF-06 [L] R1/R6 — passa de câmara.** Fluxo 55; a Transição na metade do wipe: o Fluxo continua 55 e a recarga não zera. No início da run, Fluxo 100.

**Plantar**

- **AC-SF-07 [L] R2/F1 — custo e recarga.** `selo` tocado no passo 0 com Fluxo 100: 1 Selo, Fluxo 60,00 exato (a regeneração do passo se perde no teto antes do gasto), recarga 30; evento `selo` com centro (1140; 540), raio 142,5 e 200 passos. Novo toque no passo 29: não sai; sai no passo 30.
- **AC-SF-08 [L] R2 — Fluxo insuficiente.** Fluxo 30, toque no passo 0: nenhum Selo e um `selo_sem_fluxo`; segurar o botão não repete o evento; um toque novo gera outro.
- **AC-SF-09 [L] R2/F1 — fronteira.** Fluxo 39,94 no começo do passo e regeneração 0,06 → φ₆ = 40,00: o Selo sai (comparação com tolerância φ₆ ≥ C − 1e-9). Com 39,90: não sai.
- **AC-SF-10 [L] R2 — esquiva e investida.** Em esquiva (Movimento): não sai; o toque fica no buffer e sai no último passo da esquiva (restante 1 → 0, consulta já falsa; Movimento R6), se o buffer valer. Em investida ativa (passos 1–9 de uma de 10): não sai. No passo do disparo da investida: sai.
- **AC-SF-11 [L] R2 — ordem e buffer.** No mesmo passo, Ataque, Especial e Selo no buffer: o Selo sai depois do golpe (item 6) e só consome o `selo`.
- **AC-SF-12 [L] R2/F6 — centro preso.** Câmara 1920×1080: jogador (100; 540), mira (−1; 0) → (30; 540). Jogador (60; 60), mira (−0,7071; −0,7071) → (30; 30). Jogador (960; 80), mira (0,6; −0,8) → (1068; 30). Jogador (27; 540), mira (−1; 0) → (30; 540).
- **AC-SF-13 [L] R2 — obstáculo.** Obstáculo sobre o centro (1140; 540): o Selo nasce ali e fere o Saco dentro dele.

**Selo ativo**

- **AC-SF-14 [L] R3/F2 — dano de um Selo.** Saco em (1140; 540), Selo no passo 0: Vida 1000 − 0,12 por passo, 976 depois do passo 199 (± 1e-6), nenhum dano no passo 200; `selo_fim` no passo 199.
- **AC-SF-15 [L] R3 — dentro e fora.** Saco a `raio_px + r` (166,5) do centro: leva dano; a 166,6: não. Inimigo surgindo dentro: não leva e `no_selo` é falso; no primeiro passo depois do surgimento, passa a levar.
- **AC-SF-16 [L] R3/F2 — dois Selos.** Selos nos passos 0 e 30 sobre o mesmo Saco: no passo 100, o dano do passo é 0,24; depois do passo 229, a Vida é 952 (± 1e-6). `no_selo` é uma consulta só.
- **AC-SF-17 [L] R3 — M a cada passo.** Com `dano_selo_pct` +60% (M = 1,6): dano por passo 0,192. Com `dano_vida_baixa_pct` e a Vida do jogador cruzando o limiar no passo 100: o dano muda no passo 101. `dano_apos_esquiva` e `dano_enesimo_acerto` não alteram o dano do Selo.
- **AC-SF-18 [L] R3 — silencioso.** O dano do Selo não emite `acerto`, não dá empurrão, cambaleio, hitstop nem Fluxo, e não incrementa o contador de acertos.
- **AC-SF-19 [L] R3/R5 — abate pelo Selo.** Eco com Vida 0,12 no Selo: no mesmo passo o Combate o varre (item 9) e pede hitstop de abate (4), que congela do passo seguinte em diante; dois Selos no mesmo passo: o 2º o pula depois de Vida ≤ 0.
- **AC-SF-20 [L] R3/F2 — abate em dois Selos.** Fenda (Vida 46) dentro dos Selos 0 e 30: morre no passo 213 (M = 1). Com um Selo só: Vida 22 (± 1e-6).
- **AC-SF-21 [L] R3 — Abalo.** Com `selo_abala` (0,5 s = 30 passos): o inimigo dentro do Selo fica com Abalo renovado; ao sair, ele dura 28 passos (Efeitos de status F4: o item 7 do mesmo passo desconta 1). Um Abalo de 3 s restantes não encurta.

**Lentidão**

- **AC-SF-22 [L] R4/F7 — lentidão.** `no_selo` verdadeiro: a consulta de velocidade da IA dublê devolve fator 0,5 (0,2 com cambaleio); dois Selos: ainda 0,5. O inimigo que entra no círculo no item 7 só é marcado no item 6 seguinte.

**Troca de câmara e dados**

- **AC-SF-23 [L] R6 — apagar.** Dois Selos ativos e a Transição: os dois somem no quadro da metade do wipe, sem `selo_fim`, e nenhum fere no passo seguinte da câmara nova.
- **AC-SF-24 [I] R7/Formulas — dado e validação.** Campo do `SealTuning` fora de SV1–SV3 → erro e a run não começa; fora da faixa → SV11. O catálogo de fábrica produz o SV10 de Anomalia p 0 e Fenda p 1 e nenhum outro aviso (roda no host do MV1, Movimento OQ3); o SV12 não dispara com as Armas de fábrica (Lâmina 10,5% e 31,8%; Ressonância 13,4% e 34,4%).
- **AC-SF-25 [L] R1/R2 — hitstop.** Selo ativo, recarga 20 e Fluxo 50; hitstop de 6 passos: Selo (restante), recarga e Fluxo não mudam durante os 6; no 7º passo voltam a andar.
- **AC-SF-26 [L] F1 — item 8.** Fluxo 38,9; o Pulso acerta no item 8 do passo 0: o Fluxo sai do passo com 41,96 e o Selo só pode sair no passo 1.
- **AC-SF-27 [L] R2 — buffer.** `selo` tocado no passo 0 com Fluxo 39,00 (sem acertos): o Fluxo só chega a 40 no 17º passo; com o prazo de 10 passos do buffer vencido antes disso, o Selo não sai. Com Fluxo 39,70 (chega a 40 no 5º passo), sai no 5º.
- **AC-SF-28 [L] R3/F2 — M por Selo.** Selos plantados com `dano_selo_pct` +60% (M 1,6) e depois com o bônus removido (M 1): o dano de cada passo usa o M do passo, igual para os dois Selos; a marca "no Selo" é uma só.

## Open Questions

| # | Pergunta | Dono | Resolver até |
|---|---|---|---|
| 1 | Lentidão e o avanço da Fenda: o cânone não desacelera investidas de inimigo; manter? | IA de inimigos | GDD de IA |
| 2 | Câmara limpa enche o Fluxo esperando (22–28 s): parar a regeneração com a câmara limpa, ou aceitar? | Câmaras e ondas / Run | GDDs de Câmaras e Run |
| 3 | Cor da barra e do Selo: o Art Bible reserva magenta para perigo e custo, e o game-concept chama o Fluxo de "magenta de Fluxo". A barra é magenta? | art-director | Art Bible / `/asset-spec` |
| 4 | **Decidido (2026-11-12):** o Selo permanente é aceito. Pergunta aberta para o playtest: "Fluxo enche esperando" (Fluxo cheio parado, sem gastar), medida pela Telemetria; sem mudança de número | game-designer | primeiro playtest |
| 5 | **Decidido (2026-11-12):** teto `teto_multiplicador_dano` = 4,0 provisório (Modificadores F2); SV12 e a meta `f_selo` valem com M = 4 | Modificadores | `/balance-check` |
| 6 | Assimetria de Fluxo em grupo (Lâmina até 2× a Ressonância) | `/balance-check` | depois do primeiro playtest |
| 7 | Índice: linha 10 com Movimento, IA, Câmaras e Run em Depends On | usuário / producer | próxima edição do índice |
| 8 | Selo no mesmo passo do disparo da investida (cânone aceito aqui): conferir com Combate e IA | game-designer | `/design-review` |
