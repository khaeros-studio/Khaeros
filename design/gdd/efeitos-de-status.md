# Efeitos de status

> **Status**: Approved (2026-11-11; revisão única por subagente, 4 bloqueantes de texto corrigidos sem re-review; sem entrada no review log)
> **Author**: usuário + Claude (design-system, modo Lean)
> **Last Updated**: 2026-11-10
> **Last Verified**: 2026-11-10
> **Implements Pillar**: P3 *Reflexo que se lê* (o estado do inimigo é visível)

## Summary

**Efeitos de status** define os três estados que um inimigo carrega depois de
ser atingido: Sangramento (2,4/s por acúmulo, até 10 acúmulos, 4 s), Queimadura
(4,8/s por acúmulo, até 6, 3 s) e Abalo (o inimigo causa −30%, 4 s). Reaplicar
renova a duração e soma acúmulos, o dano de status é silencioso e plano (sem M),
e o jogador vê um número agregado a cada 0,5 s. As regras seguem o cânone, com o
teto de Sangramento como decisão deste GDD.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Combate núcleo, Modificadores e atributos, Conteúdo orientado a dados`

## Overview

> `game-designer` e `systems-designer` não consultados nesta seção: modo Lean.

**Efeitos de status** define os três estados que um inimigo carrega depois de
ser atingido: **Sangramento** e **Queimadura**, que ferem por passo, e
**Abalo**, que o faz causar 30% menos dano. Cada inimigo guarda os três ao
mesmo tempo.

- **Sangramento** (4 s): 2,4 de Vida por segundo por acúmulo, com no máximo 10.
- **Queimadura** (3 s): 4,8 por segundo por acúmulo, com no máximo 6.
- **Abalo** (4 s): o inimigo causa −30%; não acumula.

Reaplicar um status renova a duração, e os acúmulos somam. O jogador não toca
neste sistema: os status chegam por golpes de arma, pela bênção
`golpe_sangramento` ou `golpe_queimadura`, pelo Corte da esquiva e pelo Selo
(Abalo), e o dano segue sozinho.

A **fantasia** é a de plantar uma marca e ver a Beira consumir o inimigo: o
dano continua enquanto o jogador já cuida do próximo. O inimigo marcado é
legível de relance, sem competir com o telégrafo.

As regras seguem o cânone (`engine.ts:48–53`, `:544–553`, `:928–938`),
convertido para px e segundos, com uma regra deste GDD: o dano de status roda no
item 7 do passo, pelo caminho silencioso do Combate (R8, `de_status`: sem
`acerto`, sem empurrão, sem hitstop). Sem este sistema, as bênçãos de
Sangramento e Queimadura e a Forma Fixa não teriam efeito, e o combate teria só
dano direto.

> **→ vira ADR:** onde vivem os status (campos no estado de cada inimigo, como
> as marcas do Selo) e a ordem de aplicação no item 7.

## Detailed Design

### Core Rules

> `game-designer`, `systems-designer` e `ai-programmer` não consultados nesta
> seção: modo Lean. As regras seguem o cânone (`engine.ts:48–53`, `:544–553`,
> `:576–577`, `:597`, `:609`, `:928–938`), convertido para passos e segundos.

**R1. Modelo.** Cada inimigo guarda três estados independentes, em passos vivos:

- **Sangramento:** `acumulos` (float ≥ 0) e `restante` (int ≥ 0).
- **Queimadura:** `acumulos` e `restante`.
- **Abalo:** só `restante`.

Um estado está **ativo** se `restante` > 0. Os três coexistem e não se limpam
entre si. O jogador não tem status no MVP.

**R2. Aplicar** (`aplicar_status(alvo, id, n)`, síncrono, chamado pelo Combate no
impacto e pelo Selo). Se o alvo não é atingível (Combate R9: surgindo ou
Vida ≤ 0), ou `n` ≤ 0, nada acontece.

- **Sangramento:** `acumulos` = `min(max_acumulos_sangramento, acumulos + n)`
  (teto **10**; o cânone não tinha teto; decisão do usuário, 2026-11-10;
  0 = sem teto); `restante` =
  `passos(duracao_sangramento_s)` (240).
- **Queimadura:** `acumulos` = `min(max_acumulos_queimadura, acumulos + n)`
  (teto 6); `restante` = `passos(duracao_queimadura_s)` (180).
- **Abalo:** `restante` = `max(restante, passos(duracao))`. Não acumula e nunca
  encurta. O Abalo do Selo usa a `duracao_s` do gatilho `selo_abala` (0,5 s = 30
  passos, dos quais o Abalo dura 28 depois do círculo, F4); o das outras fontes, `duracao_abalo_s` (4 s = 240 passos).
- Acúmulos fracionários valem (a Estocada aplica 0,5).

**R3. Fontes** (as quatro do MVP). Em um golpe de arma, o Combate chama a R2 por
alvo atingido, primeiro com os gatilhos `golpe_sangramento` e `golpe_queimadura`
(Modificadores R13), depois com o `status` do `AttackDef`; a ordem não muda o
resultado. As fontes:

- o `status` do `AttackDef` (Combate R8, item 8);
- o gatilho `golpe_*`, só por golpe de arma, por alvo;
- o Corte da esquiva: 1 acúmulo de Sangramento (param `sangramento` do gatilho
  `corte_da_esquiva`);
- o Selo: `selo_abala`, renovado a cada passo dentro do círculo (Selo e Fluxo R3).

Dano de status, explosão e reflexo **não** aplicam status.

**R4. Dano por passo** (item 7 da R1 do Combate, por inimigo, na ordem estável da
lista; **antes** do impacto e da IA). Para cada inimigo atingível:

1. se o Sangramento está ativo: `ferir_inimigo(dano = r_s × acumulos,
   de_status)`, com r_s = `dano_sangramento_s` / 60; `restante` −= 1; ao chegar a 0, `acumulos` = 0;
2. se a Queimadura está ativa e o inimigo ainda tem Vida > 0: o mesmo, com
   r_q = `dano_queimadura_s` / 60;
3. o Abalo, se ativo: `restante` −= 1.

- O dano usa o caminho silencioso do Combate R8: sem `acerto`, sem empurrão, sem
  cambaleio, sem hitstop, sem contador de acertos e sem Fluxo.
- **Sem M:** o dano de status não passa pelo `multiplicador_de_dano` (cânone).
  Bênção de dano de status é do GDD de Bênçãos.
- Um inimigo surgindo não é atingível: a R2 recusa o status, então ele não chega a
  surgir com status. A regra "os contadores não descem" é só defensiva, para um
  sistema futuro que aplique antes do surgimento.
- Um status aplicado nos itens 5 ou 6 já fere nesse passo; um aplicado no item 8
  (projétil) fere no passo seguinte. O Abalo do Selo (item 6) desce 1 já no item
  7 do mesmo passo, então são 29 passos abalados contando o último dentro do círculo, 28 depois
  dele (o cânone dá 30; divergência de 1–2 passos, aceita).

**R5. Morte.** Um inimigo com Vida ≤ 0 deixa de ser atingível e não recebe mais
dano de status (Combate R14, "morto não age"). A varredura (item 9) fecha a morte
com o hitstop de abate, `cura_ao_abater` e `explosao_ao_abater`. Os status somem
com o inimigo.

**R6. Abalo e quem lê.** A consulta `abalado(inimigo)` é verdadeira com
`restante` > 0. O Modificadores aplica o multiplicador `1 − reducao_dano_causado`
(0,7) a todo dano que o abalado causa, inclusive projéteis lidos **no disparo**
(Modificadores R5). Este GDD só guarda a duração e a consulta. A consulta
`estado(inimigo)` entrega `acumulos` e `restante` de cada status, para HUD e VFX.

**R7. Troca de câmara e fim da run.** Os status somem com os inimigos na troca de
câmara; nada passa para a câmara nova. Fora de Jogo (pausa, Bênção, Transição,
Morte), os contadores não descem.

**R8. Número de dano** (decisão do usuário, 2026-11-10; o Combate V7 delega isto
a este GDD). Um número **agregado** por inimigo com Sangramento ou Queimadura
ativo, a cada `intervalo_numero_s` (0,5 s), com a soma do dano de status do
período (`round`, com o resto acumulado; F5). O período é contado **em passos vivos, por inimigo**: começa quando o inimigo passa a ter Sangramento ou Queimadura ativo e recomeça a cada número mostrado; só a animação do número corre no relógio de apresentação. Sem número por passo. Ligado ao mesmo
toggle de números do Combate (V7).

**R9. `StatusTuning`** (Conteúdo R1). Durações em segundos (Conteúdo F7), taxas
por segundo (Conteúdo F3).

| Campo | Valor inicial | Cânone |
|---|---|---|
| `duracao_sangramento_s` | 4 (240 passos) | `BLEED_TICKS` 240 |
| `dano_sangramento_s` | 2,4/s por acúmulo | `BLEED_DPT` 0,04 |
| `max_acumulos_sangramento` | 10 | sem teto (divergência: teto proposto pelo `systems-designer`) |
| `duracao_queimadura_s` | 3 (180 passos) | `BURN_TICKS` 180 |
| `dano_queimadura_s` | 4,8/s por acúmulo | `BURN_DPT` 0,08 |
| `max_acumulos_queimadura` | 6 | `BURN_MAX_STACKS` 6 |
| `duracao_abalo_s` | 4 (240 passos) | `WEAK_TICKS` 240 |
| `reducao_dano_causado` | 0,3 | `× 0.7` |
| `intervalo_numero_s` | 0,5 (30 passos) | — (proposta, R8) |

**R10. Injeção.** Recebe por injeção: o `StatusTuning`, a lista de inimigos
(atingível, ordem estável), `ferir_inimigo` (Combate) e a duração do
`selo_abala`. Os testes montam tudo em memória.

### States and Transitions

| Estado (por status, por inimigo) | Entra quando | Sai quando |
|---|---|---|
| Inativo | `restante` = 0 | a R2 aplica |
| Ativo | a R2 aplica (`restante` ← duração) | `restante` chega a 0 → Inativo (Sangramento e Queimadura zeram `acumulos`); inimigo morto ou câmara nova → removido |

**Mundo:** como no Combate. No hitstop e fora de Jogo, os contadores ficam
parados.

### Interactions with Other Systems

| Sistema | Recebe daqui | Fornece para cá | Dono da interface |
|---|---|---|---|
| Combate núcleo | dano por passo via `ferir_inimigo` (`de_status`) | `status` do golpe e do Corte; item 7; atingível; varredura | Combate (impacto), este GDD (quando e quanto) |
| Modificadores e atributos | `abalado(inimigo)`, `reducao_dano_causado` | gatilhos `golpe_sangramento`, `golpe_queimadura`, `selo_abala`, `corte_da_esquiva` | Modificadores (multiplicador), este GDD (duração) |
| Selo e Fluxo | — | Abalo (`selo_abala`) a cada passo dentro do círculo | Selo / Modificadores |
| Conteúdo orientado a dados | — | `StatusTuning`, F3, F7, V4/V10 (ids, marcador `{status.abalo…}`) | Conteúdo (formato), este GDD (semântica) |
| IA de inimigos e elites | `estado(inimigo)` | lista de inimigos | este GDD (consulta); **provisório** |
| Câmaras e ondas | — | "câmara nova" (limpa os status) | Câmaras; **provisório** |
| Armas das Doutrinas | — | `status` dos `AttackDef` (Estocada, Leque, Gota, Transmutar) | Armas |
| HUD / VFX / Pipeline visual / Áudio | `estado(inimigo)`, número agregado (R8) | — | apresentação |

## Formulas

> `systems-designer` consultado (modo Lean). Contas contra o cânone
> (`engine.ts:48–53`, `:544–553`, `:576–577`, `:928–938`), a F1 e a F3 das
> Armas e a R13 do Modificadores. Este GDD não redefine nenhuma fórmula desses
> donos.

**Convenções.** `passos(t)` é o F7 do Conteúdo; `TICK_RATE` = 60. Taxas por
passo calculadas **uma vez, na carga**: r_s = `dano_sangramento_s` / 60 (0,04) e
r_q = `dano_queimadura_s` / 60 (0,08). D_s = 240, D_q = 180, D_a = 240 passos.
C_s = `max_acumulos_sangramento` (**10**; 0 = sem teto), C_q = 6. Contas em
**passos vivos**. Vida dos comuns (p 0): Eco 30, Anomalia 24, Fenda 46, chefe
700; elite × 2,4; profundidade × (1 + 0,05 p) (números da IA de inimigos e elites, F2).

**As armas do MVP não aplicam status** (Armas R2: Corte e Pulso "sem status").
As fontes são as bênçãos `golpe_sangramento` e `golpe_queimadura` (n = 1 por
alvo, base do cânone) e o Corte da esquiva (1 acúmulo). Fontes de acúmulo por
segundo g, com n = 1:

| Fonte | g (acúmulos/s) |
|---|---|
| Lâmina, Corte (60/16) | 3,75 |
| Lâmina, Corte + Onda + esquiva | ≈ 4,92 |
| Ressonância, Pulso (60/14, 1 alvo) | 4,29 |
| Ressonância, Pulso + Investida + esquiva | ≈ 5,64 |
| Corte da esquiva (0,5 esquiva/s, placeholder do Movimento) | 0,5 |

A cadência viva é teto (o hitstop só reduz) e um golpe aplica por alvo, então
grupos multiplicam.

### F1. Acúmulos e duração ao reaplicar

The status_stack formula is defined as:

`aplicar(n)`, `n > 0`, alvo atingível:
- Sangramento: `A' = min(C_s, A + n)` (sem teto se C_s = 0); `restante' = D_s`
- Queimadura: `A' = min(C_q, A + n)`; `restante' = D_q`
- Abalo: `restante' = max(restante, D_x)`
- por passo (item 7): `restante' = restante − 1`; ao chegar a 0, `A' = 0`
- empilha se `restante > 0` na hora da aplicação; senão recomeça do zero
- intervalo máximo entre aplicações que ainda empilha: Δ ≤ D − 1 passos

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| A | float | 0–C | calculated | `acumulos` |
| n | float | > 0 (0,5; 1; 2) | data file | acúmulos do `status`, da bênção ou do Corte |
| C_s, C_q | float | C_s ≥ 0 (0 = sem teto); C_q ≥ 1 | data file | tetos |
| D_s, D_q, D_x | int | ≥ 1 | calculated | passos(duração) |
| restante | int | 0–D | calculated | passos vivos restantes |

**Output Range:** A ∈ [0, C]; `restante` ∈ [0, D]. Os acúmulos **não decaem um
a um**: zeram todos juntos quando `restante` chega a 0.
**Example:** Queimadura com A = 5,5 e n = 1: A' = min(6, 6,5) = 6 (0,5 perdido),
`restante` 180. Sangramento com A = 3 e `restante` 1 recebe n = 1: A' = 4,
`restante` 240; com `restante` 0: A' = 1.

### F2. Dano de status e DPS em regime

The status_damage formula is defined as:

- por passo: `ΔVida = −r × A` (sem M; R4)
- uma aplicação sem reaplicar: `T₁ = n × r × D` (Sangramento 9,6 n; Queimadura 14,4 n)
- cadência contínua g (acúmulos/s): `A(t) = min(C, n × g × t)`; `DPS(t) = taxa_s × A(t)`;
  `DPS_max = taxa_s × C`; `t_teto = C / (n × g)`
- sem teto: `Dano(t) = (taxa_s / 2) × n × g × t²`
- cauda ao parar de aplicar: `r × A × D` (no teto: Sangramento 96; Queimadura 86,4)

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| r | float | ≥ 0 (0,04; 0,08) | calculated | `taxa_s / 60` |
| taxa_s | float | ≥ 0 (2,4; 4,8) | data file | `StatusTuning` |
| g | float | ≥ 0 (3,75–5,64) | calculated | acúmulos/s das fontes acima |
| t | float (s) | ≥ 0 | calculated | tempo desde o 1º acúmulo, com aplicação contínua |
| C | float | ≥ 1 (ou ∞) | data file | teto |

**Output Range:** DPS ∈ [0, taxa_s × C]; Sangramento 24/s (teto 10),
Queimadura 28,8/s (teto 6). Sem teto o DPS é ilimitado (decisão do usuário,
2026-11-10: teto 10).
**Example (n = 1, g = 3,75):** com teto 10, o Sangramento chega ao teto em 2,67 s
e fica em 24/s (36% dos 66,47 da Lâmina). Sem teto, o DPS seria 36 em 4 s e 90 em
10 s (passa a arma em 7,4 s); com a Ressonância (g = 4,29), 41 e 103 (6,5 s).
Comparações: um Selo faz 7,2/s; a Queimadura no teto equivale a 4 Selos.

### F3. Tempo até matar só por status

The status_kill formula is defined as:

- acúmulos mínimos para matar numa aplicação: `n_min = V / (r × D)`
- com A constante: `passos_matar = ceil(V / (r × A))` (mata sem renovar se ≤ D)
- no teto: `passos_teto = ceil(V / (r × C))`
- `V = round(Vida_base × (1 + 0,05 p) × (elite ? 2,4 : 1))`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| V | float | > 0 | calculated | Vida atual do alvo (Armas F3) |
| A | float | > 0 | calculated | acúmulos constantes |
| C | float | ≥ 1 | data file | teto efetivo |

**Output Range:** `passos_matar` ∈ [1, ∞); acima de D, uma aplicação sem renovar
não mata.
**Example:** Eco (30) com A = 4: ceil(30 / 0,16) = 188 passos ≤ 240, morre; com
A = 3: 250 > 240, não morre (n_min = 3,125).

| Inimigo (p 0) | n_min Sangramento | n_min Queimadura | Sangramento no teto 10 | Queimadura no teto 6 |
|---|---|---|---|---|
| Eco 30 | 3,125 | 2,083 | 75 passos (1,25 s) | 63 (1,05 s) |
| Anomalia 24 | 2,5 | 1,667 | 60 (1,0 s) | 50 (0,83 s) |
| Fenda 46 | 4,79 | 3,19 | 115 (1,92 s) | 96 (1,6 s) |
| Chefe 700 | 72,9 | 48,6 | 1750 (29,2 s) | 1459 (24,3 s) |

### F4. Abalo

The shaken_damage formula is defined as:

- `dano_recebido = dano_base_do_inimigo × (1 − reducao_dano_causado)` (0,7;
  arredondamento do Modificadores)
- Abalo do Selo: D = 30; o item 7 do mesmo passo já desconta 1, então são **29
  passos abalados contando o último dentro do círculo, 28 depois dele**
  (cânone: 30)
- reaplicar: `restante' = max(restante, D)`, sem soma

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| reducao_dano_causado | float | [0, 1) | data file | `StatusTuning` |
| dano_base | float | ≥ 0 | calculated | dano do inimigo antes do Abalo |
| D | int | ≥ 1 | calculated | passos(`duracao_s` do gatilho) ou passos(`duracao_abalo_s`) |

**Output Range:** multiplicador ∈ (0, 1]; 1 sem Abalo.
**Example:** projétil de 10 lido no disparo com Abalo: 7; disparado 1 passo
depois de o Abalo acabar: 10, e não muda em voo (Modificadores R5).

### F5. Número agregado

The status_number formula is defined as:

- `S = Σ (r_s × A_s + r_q × A_q)` nos passos vivos do período de cada inimigo
  (começa na primeira aplicação e recomeça a cada número; dano de status
  realmente aplicado, limitado à Vida restante)
- a cada `I = passos(intervalo_numero_s)` (30), exibe `round(S)`; se `round(S)`
  = 0, não exibe e o resto fica acumulado para o período seguinte
- ao zerar o último status ativo, descarrega o resto se `round(resto)` ≥ 1; na
  morte, não descarrega (decisão do usuário, 2026-11-10)

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| I | int | ≥ 1 (30) | calculated | passos(`intervalo_numero_s`) |
| S | float | ≥ 0 | calculated | soma do período |
| A_s, A_q | float | ≥ 0 | calculated | acúmulos a cada passo |

**Output Range:** S ∈ [0, I × (r_s × A_s + r_q × A_q)]. O número é do relógio de
apresentação e **não altera nenhum dano**.
**Example:** A_s = 10 e A_q = 6 por 30 passos: S = 30 × (0,4 + 0,48) = 26,4,
exibe "26". Só 1 Sangramento: S = 1,2, exibe "1".

### Faixas do `StatusTuning`

| Campo | Inicial | Faixa | O que quebra fora dela |
|---|---|---|---|
| `duracao_sangramento_s` | 4 (240) | 2,5–6 (150–360) | < 2,5: 1 acúmulo dá < 6; > 6: o pool quase nunca zera |
| `dano_sangramento_s` | 2,4/s | 1,8–3,6 | > 3,6: 1 acúmulo = 14,4 (meio Eco); com teto 10, DPS máx 36/s (54% da arma) |
| `max_acumulos_sangramento` | 10 | 8–12 (aceita 0) | 0: DPS ilimitado (ST5); < 6: abaixo da Queimadura; > 12: DPS máx > 28,8/s (o de 12), acima da Queimadura |
| `duracao_queimadura_s` | 3 (180) | 2–4 (120–240) | < 2: cauda no teto 57,6; > 4: 115, mais que o Eco elite (72) |
| `dano_queimadura_s` | 4,8/s | 3,6–6,0 | > 5,54: DPS máx > 50% da arma (ST5); < 3,6: mata o Eco no teto só em > 1,4 s |
| `max_acumulos_queimadura` | 6 | 4–8 | > 8: 38,4/s (58%); < 4: o teto some (< 19,2/s); < 1: erro |
| `duracao_abalo_s` | 4 (240) | 2–6 | sem consumidor no MVP (só o Selo aplica, com `selo_abala`); < 2 não cobre a leitura |
| `reducao_dano_causado` | 0,3 | 0,15–0,45 (aceita 0) | ≥ 0,5: inimigo quase inofensivo; < 0,15: o Abalo some; ≥ 1: erro |
| `intervalo_numero_s` | 0,5 (30) | 0,25–1,0 (15–60) | < 0,25: número por passo; > 1: o dano parece preso |

Faixas inclusivas, comparadas em passos (F7 do Conteúdo).

### Validação do `StatusTuning`

Somam-se às faixas do V2 do Conteúdo. **Erros** vão para a tela de erros do
catálogo e a run não começa; **avisos** ficam no registro de validação.

| Regra | Tipo | Condição | Por quê |
|---|---|---|---|
| ST1 | erro | passos(`duracao_sangramento_s`), passos(`duracao_queimadura_s`) ou passos(`duracao_abalo_s`) < 1 | status que expira antes de agir |
| ST2 | erro | `dano_sangramento_s` < 0 ou `dano_queimadura_s` < 0 | status que cura |
| ST3 | erro | `max_acumulos_queimadura` < 1, ou `max_acumulos_sangramento` < 0 | teto que anula a Queimadura, ou teto negativo |
| ST4 | erro | `reducao_dano_causado` ∉ [0, 1) | Abalo que cura o jogador ou anula todo o dano |
| ST5 | aviso, cruzada com Armas | `taxa_s × teto` (∞ se o teto é 0) > `x_dps` (0,50) × o menor DPS real de arma (66,47) | o status vira o dano principal (hoje: Queimadura 28,8 = 43%, Sangramento 24 = 36%; sem teto dispara). Caso somado, com M = 4 (teto do Modificadores F2): Sangramento + Queimadura somados ≤ X% do DPS da arma; hoje 24/s + 28,8/s = 52,8/s contra 66,47 × 4 = 265,9/s = **≈ 20%** (X = 50 como o `x_dps` do ST5 vale também para a soma) |
| ST6 | aviso | passos(`intervalo_numero_s`) < 1 | número por passo ou divisão por zero |
| ST7 | aviso, cruzada com Inimigos | Sangramento ou Queimadura no teto mata o comum de menor Vida do pool, p de 0 a `p_max`, em menos de `y_matar_s` (0,5 s) | status que dispensa a arma (hoje 0,83 s, passa) |
| ST8 | aviso, informativo, cruzada com Inimigos | n_min ≤ 1 para algum comum do pool | 1 acúmulo mata numa aplicação (hoje 1,67, passa) |
| ST9 | aviso, informativo, cruzada com Inimigos | Vida_p / (r × C) é inteiro exato (C = teto de Sangramento ou de Queimadura), para algum comum e p de 0 a `p_max` (tolerância 1e-6) | a morte no último passo depende do double. **Dispara no catálogo de fábrica:** com o Sangramento no teto (0,4/passo), Eco 75, Anomalia 60 e Fenda 115 passos exatos em p 0; com a Queimadura no teto, Anomalia 50 (aceito, como o SV10 do Selo) |
| ST10 | aviso | passos(`intervalo_numero_s`) > min(D_s, D_q) | o número da cauda curta some |
| ST11 | aviso | campo fora da faixa de design | as contas deste GDD deixam de valer |

**Saída do validador:** uma entrada por regra e por objeto; o erro suspende o
aviso da mesma regra. **Constantes do validador** (proposta): `x_dps` 0,50 e
`y_matar_s` 0,5, no recurso de validação do `ArmasTuning`, **fora** do
`StatusTuning`. ST5 e ST7–ST9 dependem de dados de outros sistemas e rodam onde
roda o MV1 do Movimento (Movimento OQ3).

## Edge Cases

> `systems-designer` não consultado nesta seção: modo Lean.

**Aplicar**

- **Se o alvo estiver surgindo ou com Vida ≤ 0, ou `n` ≤ 0:** nada acontece (R2).
- **Se um status for reaplicado com `restante` = 1:** os acúmulos somam e o `restante` volta à duração cheia (F1).
- **Se a Queimadura já estiver no teto (6):** o excesso de `n` se perde, e o `restante` renova mesmo assim.
- **Se `n` for fracionário (Estocada, 0,5):** vale; A = 0,5 fere 0,02 por passo.
- **Se o Abalo for reaplicado com duração menor (Selo, 30 passos, sobre um Abalo de 200):** não encurta (`max`).
- **Se o inimigo estiver dentro do Selo:** o Abalo é renovado a cada passo (R3).
- **Se um golpe de área atingir vários alvos:** cada alvo recebe o status por conta própria; os estados não se misturam entre inimigos.

**Dano e morte**

- **Se Sangramento e Queimadura estiverem ativos no mesmo passo:** o Sangramento fere primeiro; se ele mata, a Queimadura não fere (alvo não atingível, R4).
- **Se o status mata:** a varredura (item 9) fecha a morte no mesmo passo, com hitstop de abate, `cura_ao_abater` e `explosao_ao_abater`, sem `acerto` e sem Fluxo (R5).
- **Se um golpe e um status matarem no mesmo passo:** o inimigo já está morto quando o item 7 roda; o dano de status é pulado.
- **Se o dano de status passar da Vida que resta:** não é limitado (Combate R8). O número agregado usa só o dano que coube na Vida (F5).
- **Se o jogador morrer no mesmo passo:** o item 7 roda por inteiro nesse passo; a partir do seguinte o Combate para (Combate R14).

**Tempo**

- **Se houver hitstop, pausa, Bênção, Transição ou Morte:** os contadores ficam parados (R7).
- **Se o inimigo estiver surgindo:** o status é recusado (R2); a regra "contadores parados" é só defensiva.
- **Se a câmara trocar:** os status somem com os inimigos; nada passa para a câmara nova.
- **Se o Abalo do Selo durar 28 passos depois do círculo (o AC-SF-21 do Selo dizia 30):** vale o 28 deste GDD (F4); o AC-SF-21 foi alinhado em 2026-11-10 (OQ 8).
- **Se um projétil inimigo já estiver em voo quando o Abalo acabar ou começar:** o dano dele é o lido no disparo e não muda em voo (Modificadores R5).

**Número agregado**

- **Se o inimigo morrer entre dois períodos:** o resto não é mostrado (F5).
- **Se o último status zerar com resto ≥ 1:** o número final é mostrado antes de sumir.
- **Se o toggle de números estiver desligado:** nenhum número, e o dano não muda.

**Números**

- **Se `max_acumulos_sangramento` for 0:** sem teto; o DPS cresce sem limite e o ST5 avisa.
- **Se o alvo for elite ou chefe:** não há imunidade (cânone); o Sangramento no teto leva 29,2 s para matar o chefe (F3).
- **Se a Vida de um comum cair numa morte exata de passo (Eco, Anomalia e Fenda p 0 com o Sangramento no teto; Anomalia p 0 com a Queimadura no teto):** o resultado depende do double e é fixado no teste (ST9, aceito).

**Conflitos com outros GDDs:** um, resolvido: o AC-SF-21 do Selo (30 passos) foi alinhado a 28. O Combate V6 e V7 delegavam o número de dano de status a este GDD; a R8 o resolve.

## Dependencies

**Depende de (upstream)**

| Sistema | Tipo | O que vem de lá | Sem ele |
|---|---|---|---|
| Combate núcleo | Forte | `ferir_inimigo` (`de_status`), item 7 da R1, `status` do golpe e do Corte, atingível (R9), varredura de mortes | o status não fere nem é aplicado |
| Modificadores e atributos | Forte | gatilhos `golpe_sangramento`, `golpe_queimadura`, `selo_abala`, `corte_da_esquiva`; multiplicador do Abalo | sem fontes de status por bênção |
| Conteúdo orientado a dados | Forte | `StatusTuning`, conversões F3 e F7, validação V2/V4/V10 | números no código |
| Selo e Fluxo | Suave | Abalo do Selo (`selo_abala`) | o Abalo não tem fonte no MVP |
| Armas das Doutrinas | Suave | `status` dos `AttackDef` (nenhum nas armas do MVP) | só as bênçãos aplicam status |
| IA de inimigos e elites | Forte, **por contrato** | lista de inimigos (atingível, ordem estável) | não há alvo |
| Câmaras e ondas | Suave, **por contrato** | "câmara nova" limpa os status | os status somem com os inimigos |

**É dependência de (downstream)**

| Sistema | Tipo | O que recebe |
|---|---|---|
| Modificadores e atributos | Forte | `abalado(inimigo)` e `reducao_dano_causado` (multiplicador do Abalo) |
| IA de inimigos e elites | Suave | `estado(inimigo)` |
| Bênçãos (Tradições) | Suave | os status como efeito (Sombra Viva, Molde Vivo, Forma Fixa) |
| HUD / Feedback de combate (VFX) / Pipeline visual / Áudio | Suave | `estado(inimigo)`, número agregado |
| Telemetria local | Suave | dano por status por run |

**Bidirecionalidade:**

- Combate (R8, V6/V7, Interactions, Dependencies), Modificadores (R5, R12, R13)
  e Conteúdo (R1, `StatusTuning`) já citam Efeitos de status.
- Selo e Fluxo cita o Abalo; este GDD o lista. O Armas lista Efeitos de status como downstream. Movimento ↔ Status: o Corte da esquiva aplica 1 Sangramento (Movimento R3); o Movimento lista Efeitos de status.
- IA, Câmaras, Bênçãos, HUD, Feedback (VFX) e Telemetria já existem; cada um deve listar "Efeitos de status" em Dependencies (conferência pendente). Chefes e Áudio ainda não existem.
- **Índice:** a linha 11 lista Combate, Modificadores e Conteúdo; acrescentar
  Selo e Fluxo, Armas (suaves) e IA e Câmaras (por contrato).

## Visual/Audio Requirements

> `art-director` e `audio-director` não consultados: modo Lean.

- **Legibilidade sem competir com o telégrafo** (P3): o inimigo marcado mostra o
  status por um **sinal pequeno e fixo** perto dos pés ou da cabeça (ícone ou
  fiapos de tinta), nunca por tinta sobre o corpo, para não cobrir o telégrafo
  nem o flash de acerto. Um sinal por status ativo, no máximo 3.
- **Sangramento:** gotas de tinta escura caindo do corpo; a quantidade cresce
  com os acúmulos (1, 2–5, 6–10).
- **Queimadura:** brasas em magenta e dourado esmaecido (o dano do jogador nunca
  é magenta; a brasa é a "Beira consumindo", não o golpe); cresce com os
  acúmulos (1–2, 3–4, 5–6).
- **Abalo:** o inimigo treme levemente e o contorno perde força; sem flash.
- **Número agregado** (R8): em osso, pequeno, subindo do inimigo; distinto do
  número de golpe (V7 do Combate) por tamanho e cor mais fria.
- **Relógio:** todos os efeitos de status contam em **passos vivos** (param no
  hitstop e na pausa); o número agregado corre no relógio de apresentação.
- **Multidão:** com mais de 9 inimigos marcados, os sinais caem para um só por
  inimigo (o de maior acúmulo).
- **Áudio** (provisório): estalo seco e baixo ao aplicar; sem som contínuo.

> 📌 **Asset Spec** — rodar `/asset-spec system:efeitos-de-status` depois do Art
> Bible: gotas, brasas, tremor, sinais e fonte do número agregado.

## Game Feel

- **Dano que continua sem o jogador:** o jogador planta a marca e vira para o
  próximo inimigo; o número agregado confirma que o dano segue.
- **Peso:** sem hitstop, sem câmera e sem flash. Status é leitura, não soco.
- **Ritmo:** o Sangramento no teto chega em ~2–3 s de golpes seguidos; a
  Queimadura, em ~1,5 s de golpes seguidos com `golpe_queimadura` (no MVP, só a bênção aplica status).
- **Alvo de playtest:** os testadores dizem qual inimigo está sangrando ou
  queimando sem dica, em câmara com 5 inimigos (registro [M]).

## UI Requirements

- Sem tela própria. O HUD não mostra status de inimigo; o sinal e o número
  agregado são VFX no mundo (R8), ligados ao toggle de números (Combate V7).
- **Barra de Vida do chefe** (GDD de Chefes): pode mostrar os ícones de status
  do chefe; fora do MVP.
- Acessibilidade: o sinal de cada status também diferencia por forma, não só por
  cor (Art Bible §7.9).

## Cross-References

| Documento | Seção | Uso neste GDD |
|---|---|---|
| `design/gdd/combate-nucleo.md` | R1 (item 7), R8, R9, R14, V6, V7 | ordem do passo, caminho silencioso, atingível, varredura, número de dano delegado |
| `design/gdd/modificadores-e-atributos.md` | R5, R12, R13, F2 | gatilhos, Abalo como multiplicador, sem M no dano de status |
| `design/gdd/conteudo-orientado-a-dados.md` | R1, V2, V4, V10, F3, F7 | `StatusTuning`, ids, marcador `{status.abalo…}`, conversões |
| `design/gdd/selo-e-fluxo.md` | R3, F2 | Abalo do Selo (`selo_abala`) |
| `design/gdd/armas-das-doutrinas.md` | R2, F1, F3 | armas do MVP sem status, DPS de referência, Vida por profundidade |
| `design/gdd/movimento-e-esquiva.md` | R9 (Corte da esquiva) | 1 acúmulo de Sangramento |
| `design/gdd/game-concept.md` | §3, §6 | Sangramento e Queimadura como identidade de Doutrinas |
| Khaeros `packages/action-core/src/engine.ts` | `:48–53`, `:544–553`, `:576–577`, `:597`, `:609`, `:928–938` | números e regras dos status |
| Khaeros `packages/combat-rules/src/arenaContent.ts` | `:48–65`, `:146–153` | `status` dos AttackDef e bênçãos |

## Acceptance Criteria

> `qa-lead` não consultado: economia de tokens; a revisão única do GDD cobre
> regras e critérios.

**Fixture ST** (provisório: dublês de Combate, Modificadores e IA): `StatusTuning`
de fábrica (teto de Sangramento 10), Saco imóvel (Vida 1000, raio 24, atingível)
e passos contados a partir de 0; o status é aplicado no item 5 do passo 0, salvo
quando o critério diz.

**Aplicar e durar**

- **AC-ST-01 [L] R2/R4/F1 — Sangramento.** `aplicar(sangramento, 1)`: A = 1, `restante` 240; a cada passo 0–239 a Vida cai 0,04; depois do passo 239, Vida 990,4 (± 1e-6), A = 0 e `restante` 0.
- **AC-ST-02 [L] R2/F1 — reaplicar.** Sangramento n = 1 no passo 0 e n = 1 no passo 100: no passo 100, A = 2 e `restante` 240; Vida final 976,8 (± 1e-6) (100 × 0,04 + 240 × 0,08).
- **AC-ST-03 [L] R2/F1 — teto do Sangramento.** 12 aplicações de n = 1 no mesmo passo: A = 10; depois de 240 passos, Vida 904,0 (± 1e-6). Com `max_acumulos_sangramento` 0: A = 12.
- **AC-ST-04 [L] R2/F1 — Queimadura e teto.** n = 1: 180 passos × 0,08 = 14,4 (Vida 985,6). n = 8: A = 6, Vida 913,6 (6 × 0,08 × 180 = 86,4).
- **AC-ST-05 [L] R2 — fracionário.** n = 0,5: A = 0,5, 0,02 por passo, Vida 995,2 depois de 240 passos.
- **AC-ST-06 [L] R1/R4 — coexistem.** Sangramento 1 e Queimadura 1 no passo 0: 0,12 por passo nos passos 0–179 e 0,04 nos passos 180–239; Vida final 976,0 (± 1e-6).
- **AC-ST-07 [L] R2 — alvo inválido.** `aplicar` com n ≤ 0, com o alvo surgindo ou com Vida ≤ 0: nenhum estado muda e nenhum dano sai. Depois do surgimento, `aplicar` funciona normalmente.
- **AC-ST-08 [L] R2/R4 — passo da aplicação.** Aplicado no item 5 ou 6: fere no mesmo passo (Vida −0,04 no passo 0). Aplicado no item 8 (projétil): fere a partir do passo 1.

**Abalo**

- **AC-ST-09 [L] R2/F4 — duração e `max`.** Abalo de 240 passos: `abalado` verdadeiro nos passos 0–239 e falso depois; reaplicar com 30 sobre `restante` 200 deixa 200; sobre 10, deixa 30.
- **AC-ST-10 [L] R3/F4 — Abalo do Selo.** Inimigo no Selo nos passos 0–9: `abalado` (lido depois do item 7) é verdadeiro até o passo 37 e falso a partir do 38 (29 passos contando o 9º, 28 depois dele).
- **AC-ST-11 [L] R6/F4 — efeito no dano.** Com `abalado`, o dublê do Modificadores devolve 0,7 para o dano do inimigo; um projétil disparado com Abalo leva 7 de 10 e não muda em voo; disparado 1 passo depois de o Abalo acabar, leva 10.

**Dano e morte**

- **AC-ST-12 [L] R4 — silencioso.** O dano de status não emite `acerto`, não dá empurrão, cambaleio, hitstop, Fluxo, nem incrementa o contador de acertos.
- **AC-ST-13 [L] R4/R5 — ordem e morte.** Eco com Vida 0,05, Sangramento 1 e Queimadura 1: o Sangramento fere (0,04), a Queimadura fere (0,08), Vida −0,07; com Vida 0,03: o Sangramento mata (−0,01) e a Queimadura não fere. Um golpe e um status que matam no mesmo passo: o dano de status é pulado.
- **AC-ST-14 [L] R5 — abate por status.** Eco com Vida 0,04 e Sangramento 1: a varredura (item 9) do mesmo passo o remove, pede hitstop de abate (4, do passo seguinte) e dispara `cura_ao_abater` e `explosao_ao_abater`.
- **AC-ST-15 [L] R7 — parado.** Hitstop de 6 passos, pausa, Bênção, Transição e Morte: `restante` e A não mudam em nenhum passo congelado nem fora de Jogo.
- **AC-ST-16 [L] R7 — câmara nova.** Inimigos com status e a troca de câmara: nenhum estado existe na câmara nova.

**Fontes**

- **AC-ST-17 [L] R3 — golpes e bênçãos.** Com `golpe_sangramento` 1 e um golpe de arma em 3 alvos: cada alvo A = 1. O Corte da esquiva aplica 1 de Sangramento por alvo; o Selo aplica o Abalo.
- **AC-ST-18 [L] R3 — ordem.** `golpe_*` e o `status` do `AttackDef` no mesmo golpe: os dois aplicam, e a ordem não muda A nem `restante`.

**Número agregado**

- **AC-ST-19 [L] R8/F5 — número.** A_s = 10 e A_q = 6 durante 30 passos: exibe "26" no 30º passo vivo depois da primeira aplicação (com 6 passos de hitstop no meio, no 36º passo real); só Sangramento 1 por 30 passos vivos: "1" e resto 0,2 acumulado; com o toggle de números desligado: nenhum número e o dano não muda.
- **AC-ST-20 [L] R8/F5 — descarga.** Último status zera com resto ≥ 1: um número final; inimigo que morre: nenhum.

**Dados e validação**

- **AC-ST-21 [I] R9/Formulas — erros.** `StatusTuning` com duração < 1 passo, taxa < 0, `max_acumulos_queimadura` < 1 ou `reducao_dano_causado` fora de [0, 1): erro ST1–ST4 e a run não começa.
- **AC-ST-22 [I] R9/Formulas — avisos de fábrica.** O catálogo de fábrica produz o ST9 informativo (Eco 75, Anomalia 60 e Fenda 115 passos com o Sangramento no teto; Anomalia 50 com a Queimadura no teto) e nenhum outro aviso; com `max_acumulos_sangramento` 0, o ST5 dispara; com Sangramento + Queimadura somados e M = 4 (24 + 28,8 = 52,8/s contra 66,47 × 4 = 265,9/s, ≈ 20%) o ST5 somado não dispara. As regras ST5 e ST7–ST9 rodam no host do MV1 (Movimento OQ3).
- **AC-ST-23 [L] R4/R6 — consulta.** Com o AC-ST-02, `estado(inimigo)` devolve: passo 99: A_s 1, `restante` 141; passo 100 (depois da 2ª aplicação e do item 7): A_s 2, `restante` 239; passo 340: A_s 0, `restante` 0. Com o AC-ST-10, `restante` do Abalo: 29 no passo 9 e 0 no passo 38.
- **AC-ST-24 [L] F3 — matar só por status.** Eco (Vida 30) com A_s = 4 constante: morre no 188º passo; com A_s = 3: não morre em 240 passos (Vida 5 restante, ± 1e-6). Com o Sangramento no teto (A = 10): 75 passos.
- **AC-ST-25 [L] F2 — teto e DPS máximo.** Corte da esquiva e `golpe_sangramento` 1 a cada 16 passos (g = 3,75): A = min(10, 1 + n) cresce até 10 no 10º passo de aplicação; o DPS por passo nunca passa de 0,4 (24/s).
- **AC-ST-26 [I] R9/Formulas — outras validações.** `intervalo_numero_s` < 1 passo: aviso ST6; > min(duração Sangramento, Queimadura): ST10; qualquer campo fora da faixa: ST11. A injeção (R10): o `StatusTuning`, a lista de inimigos e `ferir_inimigo` vêm de dublês, sem SceneTree.

## Open Questions

| # | Pergunta | Dono | Resolver até |
|---|---|---|---|
| 1 | Teto de Sangramento 10 diverge do cânone (sem teto); conferir a sensação no playtest | game-designer | primeiro playtest |
| 2 | `duracao_abalo_s` (4 s) não tem consumidor no MVP; fica no dado para bênçãos e chefes | Bênçãos / Chefes | GDDs de Bênçãos e Chefes |
| 3 | Escala de raridade de `golpe_sangramento` e `golpe_queimadura` (o cânone mostra n = 1 base) e o dano plano de status sem M perde peso com bênçãos de Ataque | Bênçãos / `/balance-check` | GDD de Bênçãos |
| 4 | Cadência de esquivas por segundo (placeholder 0,5/s) usada nas fontes de Sangramento | Movimento | `/balance-check` |
| 5 | IA lê `estado(inimigo)` para reações (por exemplo, fugir ao queimar)? | IA de inimigos | GDD de IA |
| 6 | Combate V6 e V7: atualizar o texto "número de status é do GDD de Status" para apontar a R8 | usuário / dono do Combate | próxima edição do Combate |
| 7 | Índice: linha 11 com Selo, Armas, IA e Câmaras em Depends On | usuário / producer | próxima edição do índice |
| 8 | Abalo do Selo dura 28 passos depois do círculo (cânone 30); o AC-SF-21 do Selo foi alinhado | game-designer | `/design-review` |
| 9 | Armas das Doutrinas não cita Efeitos de status em Dependencies (suave); o Selo também deve ser listado no Combate | dono de Armas | próxima edição de Armas |
