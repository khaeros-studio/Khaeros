# IA de inimigos e elites

> **Status**: Approved (2026-11-11; revisão única por subagente, 2 bloqueantes corrigidos sem re-review; sem entrada no review log)
> **Author**: usuário + Claude (design-system, modo Lean)
> **Last Updated**: 2026-11-11
> **Last Verified**: 2026-11-11
> **Implements Pillar**: P3 *Reflexo que se lê* (inimigos previsíveis); P2 *A Beira cobra*

## Summary

**IA de inimigos e elites** define como cada inimigo se move, ataca e se recupera
(`melee`, `ranged`, `charger`; `chefe` reservado) em cinco fases, sempre
passando por um telégrafo com a mira travada, e quais inimigos nascem elite (a
partir da profundidade 3, Vida × 2,4, sem cambalear nem quebrar, no máximo um por
onda). Existe para o jogador enfrentar inimigos legíveis que pressionam sem
trapacear, e para declarar o alvo de dano recebido que as Câmaras usam.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Combate núcleo, Telégrafos, RNG com seed, Conteúdo orientado a dados, Modificadores e atributos`

> **Nota (2026-11-11, revisão cruzada):** pendente: Dependencies listam Armas (F5, IV7); registro em `entities.yaml` do `depth_hp_bonus` e das constantes de elite (dono: esta IA, decisão de 2026-11-12).

## Overview

> `game-designer` e `ai-programmer` não consultados nesta seção: modo Lean.

**IA de inimigos e elites** define como cada inimigo se move, ataca e se recupera,
e quais inimigos nascem elite. Cada inimigo é uma máquina de cinco estados
(surgindo, aproximação, preparo, execução, recuperação) com um dos comportamentos
do MVP: `melee` (o Eco corre ao jogador), `ranged` (a Anomalia mantém distância e
atira) e `charger` (a Fenda se alinha e avança). O `chefe` é reservado.

- **Previsível:** todo golpe passa por um telégrafo com a mira travada
  (Telégrafos); a IA decide **quando** iniciá-lo, nunca esconde o golpe.
- **Sem trapaça:** os inimigos não esquivam, não fogem e não se curam; quem
  cambaleia ou toma o "Quebrou!" perde o ataque (Combate).
- **Elites:** a partir da 3ª profundidade, um comum pode nascer elite (Vida × 2,4,
  dano × 1,25, raio × 1,2, empurrão × 0,4, sem cambalear nem quebrar). A IA define
  as regras e o sorteio; as Câmaras só chamam.
- **Multidão:** até 9 inimigos, que se separam sem se atropelar.

A **fantasia** é a de enfrentar uma Beira que pressiona sem trapacear: cada
inimigo tem um jeito próprio de ameaçar (o corredor, o atirador, o investidor), o
jogador aprende o ritmo de cada um e, quando erra, o erro é dele (P3). O elite
é o inimigo que ele precisa esquivar, não atropelar.

As regras seguem o cânone (`engine.ts:318–392`, `:915–1156`, `arenaContent.ts:86–97`),
convertido para px e passos, com três decisões do usuário (2026-11-11): o dano
dos inimigos segue fixo e este GDD declara um **alvo de dano recebido** para as
Câmaras; a lentidão do Selo **não** desacelera o avanço da Fenda; a IA define as
regras e o sorteio do elite. Sem este sistema, os inimigos não teriam
comportamento, o Combate não teria alvos que reagissem e os telégrafos nunca
seriam iniciados.

> **→ vira ADR:** onde vive o estado de cada inimigo (campos próprios, como os
> Selos e os telégrafos), a lista estável de inimigos e a separação par a par.

## Detailed Design

### Core Rules

> `game-designer`, `ai-programmer` e `systems-designer` não consultados nesta
> seção: modo Lean. As regras seguem o cânone (`engine.ts:318–392`, `:915–1156`,
> `arenaContent.ts:86–97`), convertido para px e passos (unidade × 1,5 px;
> velocidade u/passo × 90 px/s; Conteúdo F2, F4, F7).

**R1. Estado de cada inimigo.** Posição, raio, Vida (Combate), `fase`, `timer`,
mira travada (Telégrafos R2), `elite`, `padrao` (só o chefe), cambaleio
(Combate), `no_selo` (Selo R4), status (Efeitos de status). O comportamento e os
números vêm do `EnemyDef` (Conteúdo): `melee`, `ranged`, `charger` e o `chefe`
reservado.

**R2. Passo da IA** (item 7 da R1 do Combate, por inimigo, na ordem estável da
lista): 1. Status (dano por passo); 2. Combate, impacto (empurrão, cambaleio); 3.
**IA** (esta regra). O Selo roda antes, no item 6 (Selo R3), e deixa a marca `no_selo` que a IA lê aqui. Um inimigo com Vida ≤ 0 não age ("morto não age", Combate
R14). Fora do estado de jogo Jogo (pausa, Bênção, Transição, Morte), nada roda;
no hitstop, nada roda.

**R3. Surgindo** (`fase` = surgindo). Dura `surgimento_s` (50 passos). O inimigo
não é atingível, não ataca, não tem telégrafo e não recebe status. Ao fim,
passa a aproximação com `timer` = `espera_inicial_passos` = 20 + inteiro em
[0, 50) (fluxo `ia` do RNG; Combate R9).

**R4. Aproximação** (`fase` = aproximação). A cada passo, `timer` −= 1. O
movimento depende do comportamento (velocidade efetiva na R9):

| Comportamento | Movimento | Começa o preparo quando |
|---|---|---|
| `melee` | anda **sempre** em direção ao jogador | `timer` ≤ 0 e distância ≤ alcance + 27 px (hoje 78 px) |
| `ranged` | **fora da vista (R11): avança sempre em direção ao jogador**, ignorando o recuo e o contorno; na vista: distância < 345 px: recua; > 570 px: avança; entre as duas: contorna (perpendicular, a 0,5 da velocidade) | `timer` ≤ 0 e distância < 975 px, e o inimigo está visível (R11) |
| `charger` | avança se a distância > 456 px (não anda mais perto) | `timer` ≤ 0 e distância ≤ 570 px |
| `chefe` | anda até 300 px do jogador (reservado) | `timer` ≤ 0 |

Contas: alcance do melee (34 + 18) u = 78 px com o raio do jogador (27 px)
incluído em 51 + 27; ranged 230, 380 e 650 u = 345, 570 e 975 px; charger 380 u =
570 px e 80% = 456 px. O jogador anda a 378–387 px/s, mais rápido que qualquer
comum (Eco 153, Anomalia 117, Fenda 126 px/s).

**R5. Preparo** (`fase` = preparo). Ao entrar, a IA chama `iniciar_telegrafo`
(Telégrafos R2: mira travada, preparo, teto de 24); se ele recusar, a IA fica em
aproximação e tenta no passo seguinte. Durante o preparo o inimigo **não anda**
(só o empurrão o move) e o `timer` desce (Eco 26, Anomalia 36, Fenda 42 passos).
Ao chegar a 0: o telégrafo dispara e a IA executa o golpe **no mesmo passo**
(R6).

**R6. Execução** (`fase` = execução, mira travada). No passo do disparo:
- `melee`: testa a forma (Telégrafos F2) e chama `ferir_jogador` uma vez; fica
  parado 10 passos (`execucao_melee_passos`);
- `ranged`: chama `disparar_projetil` na mira travada (Telégrafos F3) e fica
  parado 6 passos;
- `charger`: avança `avanco_passos` (26) passos a `velocidade × 3,6` em linha
  reta; fere por contato, uma vez por avanço (Telégrafos R6). **O avanço não é
  desacelerado pelo Selo** nem pelo cambaleio (decisão do usuário, 2026-11-11);
  uma parede ou obstáculo o para (colisão, R9).

O dano é o do `EnemyDef` (elite × 1,25, Abalo × 0,7 pelo Modificadores); o M do
projétil é o do disparo (Modificadores R12).

**R7. Recuperação** (`fase` = recuperação). `timer` = `recarga` do `EnemyDef`
(Eco 50, Anomalia 90, Fenda 80 passos; chefe em fúria × 0,6). Os não-`ranged`
andam em direção ao jogador a 0,4 da velocidade se a distância > 90 px; o
`ranged` não anda. No fim, volta a aproximação com `timer` = 10 + inteiro em
[0, 30) (fluxo `ia`).

**R8. Quebrar e armadura** (Combate R8.7). O Combate chama
`pedir_recuperacao(inimigo)` quando um golpe pesado acerta um **comum** em
preparo: o telégrafo vira `quebrado` (Telégrafos R7), a fase passa a
recuperação por `passos(quebrou_recuperacao_s)` (24) e o golpe não sai. **Elite e
chefe nunca quebram nem cambaleiam** (armadura). Um ataque já em execução nunca
é cancelado.

**R9. Movimento.**
- Velocidade efetiva = `velocidade` × (`no_selo` ? `fator_lentidao` (0,5) : 1) ×
  (cambaleando ? `fator_cambaleio` (0,4) : 1). Os dois valem para o **andar**
  (aproximação, recuo, contorno, recuperação); o avanço do `charger` os ignora.
- Cada passo (exceto surgindo), o corpo é empurrado para fora de obstáculos e preso à câmara
  (parede + raio). O empurrão (Combate) é somado depois.
- **Separação:** ao fim do item 7, para cada par com distância < soma dos raios,
  cada um é empurrado pela metade da sobreposição, em sentidos opostos (cânone).
  Vale para elites e comuns.

**R10. Elites.**
- **Regras** (`EliteRules`, Conteúdo; **a IA é a dona** destes números e do
  `depth_hp_bonus` de +5% por profundidade, F2): Vida × 2,4 (arredondada), dano × 1,25,
  raio × 1,2, empurrão × 0,4 (via Modificadores R10), armadura (R8), sem
  Fragmentos por abate (Economia), e um máximo de **1 elite por onda**.
- **Sorteio** (`sortear_elite(profundidade, ja_ha_elite)`; a IA define, as Câmaras
  chamam, por inimigo e na ordem da onda, **guardam** se a onda já tem elite e
  passam esse booleano; decisão do usuário, 2026-11-11): o fluxo `elites` do RNG, que consome **1 real por inimigo da
  onda, sempre**, sem depender do combate (RNG R4b). É elite se profundidade ≥
  `elite_prof_min` (3), `r < chance(profundidade)` (F1) e ainda não há elite na
  onda. Chefe não é elite.
- **Divergência do cânone:** o cânone só consumia o RNG quando a chance existia,
  pulava o sorteio depois do primeiro elite e na sala de chefe; o RNG exige consumo
  fixo, então aqui o fluxo consome 1 real por inimigo em todos esses casos.
- **Dono único das regras:** `elite_prof_min`, `max_elites_onda`, a curva de
  chance e os multiplicadores são da `EliteRules` (Conteúdo); o `IATuning` não os
  repete.

**R11. Atacar só quando visível** (proposta, resposta à Armas D-I8). Um `ranged`
só inicia o preparo se o centro dele está dentro do retângulo visível da câmera
(mais `margem_visivel_px`). Fora da vista, ele **avança em direção ao jogador** (R4) até entrar na vista, sem recuar nem contornar, para nunca ficar parado fora dela.
Assim nenhum tiro nasce de fora da tela.

**R12. Alvo de dano recebido** (resposta à D-W14, para o GDD de Câmaras e o
`/balance-check`). O dano dos inimigos é fixo (cânone; decisão do usuário,
2026-11-11); a Vida sobe 5% por sala nos comuns. Meta para um jogador mediano:
perder, em média, `alvo_dano_camera` (**0,25** da Vida máxima, proposta) por
câmara de combate; abaixo de 0,10 ou acima de 0,50, a câmara é ajustada pelas
Câmaras (nº de inimigos, orçamento), não por este GDD. A meta é verificada pela
Telemetria local (dano recebido por câmara) e pelo `/balance-check` (OQ 10).

**R13. Chefe** (reservado, Vertical Slice). O comportamento `chefe` tem 4
padrões em ciclo e fúria abaixo de 50% da Vida (cooldown × 0,6); os números e a
invocação são do GDD de Chefes. A IA só garante a máquina de estados e os
contratos.

**R14. `IATuning`** (Conteúdo R1). Durações em segundos (F7), distâncias em px
(F4).

| Campo | Valor inicial | Cânone |
|---|---|---|
| `surgimento_s` | 0,8333 (50) | `SPAWN_TICKS` 50 |
| `espera_inicial_s` | 0,3333 (20) + até 0,8333 | `20 + randomInt(50)` |
| `espera_s` | 0,1667 (10) + até 0,5 | `10 + randomInt(30)` |
| `ranged_perto_px` / `ranged_longe_px` | 345 / 570 | 230 / 380 u |
| `ranged_ataque_px` | 975 | 650 u |
| `charger_engaja_px` / `charger_reaproxima_px` | 570 / 456 | 380 u, `× 0,8` |
| `fator_recuperacao_andar` | 0,4 | `× 0,4` |
| `recuperacao_dist_min_px` | 90 | 60 u |
| `fator_contorno` | 0,5 | `× 0,5` |
| `execucao_melee_passos` / `execucao_ranged_passos` | 10 / 6 | 10 / 6 |
| `avanco_passos` | 26 | 26 |
| `alvo_dano_camera` | 0,25 | — (proposta, R12) |
| `margem_visivel_px` | 0 | — (proposta, R11) |

Os números por inimigo (Vida, velocidade, raio, dano, alcance, preparo, recarga,
velocidade do projétil) ficam no `EnemyDef`; as regras de elite, em `EliteRules`
(curva de chance: `LinearCurveDef`, F8 do Conteúdo).

**R15. Injeção.** Recebe por injeção: `IATuning`, `EnemyDef`, `EliteRules`, a
lista de inimigos, a posição e o raio do jogador, a geometria da câmara
(retângulo, obstáculos) e da vista, o fluxo `ia` e o fluxo `elites` do RNG, e as
chamadas do Combate (`ferir_jogador`, `disparar_projetil`) e dos Telégrafos
(`iniciar_telegrafo`). Os testes montam tudo em memória.

### States and Transitions

| Fase | Entra quando | Sai para |
|---|---|---|
| Surgindo | spawn | Aproximação (50 passos) |
| Aproximação | fim do surgimento ou da recuperação | Preparo (condições da R4) |
| Preparo | a IA chama `iniciar_telegrafo` | Execução (`timer` 0), Recuperação ("Quebrou!") |
| Execução | disparo do telégrafo | Recuperação (fim dos passos de execução) |
| Recuperação | fim da execução; "Quebrou!" | Aproximação |
| Morto | Vida ≤ 0 | removido na varredura (Combate R14) |

**Sobrepostos:** cambaleando (Combate), no Selo (Selo), status (Status), elite.
**Mundo:** como no Combate: no hitstop e fora de Jogo, nada roda.

### Interactions with Other Systems

| Sistema | Recebe daqui | Fornece para cá | Dono da interface |
|---|---|---|---|
| Combate núcleo | lista de inimigos (posição, raio, estado, elite, chefe), `ferir_jogador`, `disparar_projetil`, recuperação | impacto, cambaleio, "Quebrou!", `pedir_recuperacao`, "morto não age" | Combate (contrato), este GDD (comportamento) |
| Telégrafos | `iniciar_telegrafo`, passo do disparo | forma, mira travada, preparo, teto | Telégrafos (forma), este GDD (quando) |
| Selo e Fluxo | `no_selo(inimigo)` e `fator_lentidao` | marca "no Selo" | Selo |
| Efeitos de status | lista de inimigos, `estado(inimigo)` | dano por passo, Abalo | Status |
| Modificadores e atributos | `elite`, `profundidade` (fontes) | dano e M do golpe | Modificadores |
| RNG com seed | fluxo `ia` e fluxo `elites` | números | RNG |
| Conteúdo orientado a dados | — | `EnemyDef`, `EliteRules`, `IATuning` | Conteúdo (formato), este GDD (semântica) |
| Câmaras e ondas | `sortear_elite`, regras de elite, alvo de dano (R12) | quando e onde nascem, retângulo, obstáculos, "câmara nova" | Câmaras; **provisório** |
| Chefes (Vertical Slice) | máquina de estados | padrões e números | Chefes |
| Feedback de combate (VFX) / Áudio / HUD | fase de cada inimigo, elite | — | apresentação |

## Formulas

> `systems-designer` não consultado nesta seção: modo Lean. Contas do cânone
> (`engine.ts`, `arenaContent.ts`) e dos GDDs aprovados. `passos(t)` é o F7 do
> Conteúdo; 60 passos por segundo; velocidade u/passo × 90 = px/s.

Inimigos do Limiar (p 0): Eco 30 Vida, 153 px/s, dano 9, preparo 26, recarga 50;
Anomalia 24, 117, 8, 36, 90; Fenda 46, 126, 13, 42, 80; chefe 700 (reservado).

### F1. Chance de elite

The elite_chance formula is defined as:

`chance(p) = 0` se `p < elite_prof_min` ; senão `min(0,25 ; 0,05 + 0,02 × p)` (F8 do Conteúdo, `LinearCurveDef`) ;
`P(≥ 1 elite na onda de n) = 1 − (1 − chance)ⁿ` (o máximo é 1 por onda) ;
no sorteio: 1 real `r` ∈ [0, 1) por inimigo, sempre (RNG R4b); elite se `r < chance` e ainda não há elite na onda

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| p | int | ≥ 0 | calculated | profundidade da câmara de combate (0 = a primeira; Armas R7) |
| elite_prof_min | int | ≥ 0 (3) | data file | `EliteRules` |
| chance | float | 0–0,25 | calculated | chance por inimigo |
| n | int | 1–9 | calculated | inimigos da onda |
| r | float | [0, 1) | RNG `elites` | 1 por inimigo, sempre |

**Output Range:** chance ∈ {0} ∪ [0,11 ; 0,25]; teto em p ≥ 10. No MVP (p de 0 a 4): 0 em p 0–2, 0,11 em p 3, 0,13 em p 4.
**Example:** p 4, onda de 5 inimigos: P(≥ 1 elite) = 1 − 0,87⁵ = 50,2%; onda de 3: 34,1%. p 2: 0.

### F2. Números do elite

The elite_stats formula is defined as:

`Vida = round(Vida_base × (1 + 0,05 p) × 2,4)` ; `dano = dano_base × 1,25` (arredondado no golpe, Modificadores F3) ; `raio = raio_base × 1,2` ; `fator_empurrao = 0,4`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| Vida_base | int | > 0 | data file | `EnemyDef` |
| 2,4 / 1,25 / 1,2 / 0,4 | float | — | data file | `EliteRules` (fonte `elite`, Modificadores R10) |

**Dono (decisão do usuário, 2026-11-12):** a **IA de inimigos e elites é a dona** do `depth_hp_bonus` (+5% de Vida por profundidade, 0,05 × p; não vale para chefes) e das constantes de elite (Vida × 2,4, dano × 1,25, raio × 1,2, empurrão × 0,4). Modificadores R10 aplica; Armas, Status e Selo só citam.

**Output Range:** Vida ≥ 2,4 × base; o chefe não é elite.
**Example (p 0):** Eco elite: Vida 72, raio 28,8 px, dano 11,25 (11 no golpe). Anomalia: Vida 58, dano 10. Fenda: Vida 110, dano 16. Com p 4, o Eco elite tem 86 (30 × 1,2 × 2,4 = 86,4).

### F3. Ciclo de ataque e dano potencial

The attack_cycle formula is defined as:

`ciclo_min = preparo + execução + recarga + 10` passos (espera mínima) ; `ciclo_med = ciclo_min + 14,5` (espera média de 10 + [0, 30)) ;
`dps_pot = dano × 60 / ciclo` (se **todo** golpe acertasse)

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| preparo, recarga | int | ≥ 1 | data file | passos(`preparo_s`, `recarga_s`) do `EnemyDef` |
| execução | int | 6 / 10 / 26 | data file | `IATuning` (ranged / melee / charger) |
| dano | float | > 0 | data file | `EnemyDef` (elite × 1,25) |

**Output Range:** ciclo ≥ 90 passos nos comuns; o dano real é muito menor (R12, F5).
**Example:**

| Inimigo | ciclo mín. | ciclo médio | dano | dps potencial (mín.) |
|---|---|---|---|---|
| Eco | 26 + 10 + 50 + 10 = 96 (1,6 s) | 110,5 (1,84 s) | 9 | 5,6/s |
| Anomalia | 36 + 6 + 90 + 10 = 142 (2,37 s) | 156,5 (2,6 s) | 8 | 3,4/s |
| Fenda | 42 + 26 + 80 + 10 = 158 (2,63 s) | 172,5 (2,9 s) | 13 | 4,9/s |

### F4. Primeiro golpe e chegada

The first_strike formula is defined as:

`t_primeiro = surgimento + espera_inicial + preparo` (passos, a partir do spawn) ;
`t_chegada_melee = (d − alcance_total) / (v × f_lentidão × f_cambaleio)` s

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| surgimento | int | 50 | data file | passos(`surgimento_s`) |
| espera_inicial | int | 20–69 | RNG `ia` | 20 + [0, 50) |
| d | float | > 0 | calculated | distância do spawn ao jogador, px |
| alcance_total | float | 78 | data file | alcance + raio do jogador (melee), px |
| v, f_lentidão, f_cambaleio | float | — | data file | andar, 0,5 no Selo, 0,4 cambaleando |

**Output Range:** t_primeiro ≥ 50 + 20 + preparo. O Eco corpo a corpo demora a chegar, os atiradores não.
**Example:** Anomalia: 50 + (20 a 69) + 36 = 106–155 passos (1,77–2,58 s) até o 1º tiro, se estiver a < 975 px e visível. Eco a 600 px: (600 − 78) / 153 = 3,41 s para chegar; no Selo, 6,8 s; no Selo e cambaleando, 17 s. Fenda: 50 + (20 a 69) + 42 = 112–161 passos até o 1º avanço, se a distância ≤ 570 px.

### F5. Teto de dano por invulnerabilidade

The damage_cap formula is defined as:

`golpes_cap = 60 / passos(invuln_atingido_s)` por segundo (1,5) ;
`n_golpes = ceil(Vida_max / dano_max)` ; `t_min_morrer = (n_golpes − 1) × passos(invuln_atingido_s)` passos ;
alvo da R12: `golpes_alvo = alvo_dano_camera × Vida_max / dano_medio`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| invuln_atingido_s | float | 0,25–1,5 | data file | `CombatTuning` (0,667 s = 40 passos) |
| Vida_max | int | 80 / 100 | data file | `WeaponDef` (Armas) |
| dano_max | int | 16 | calculated | maior golpe do MVP: Fenda elite (16,25 → 16) |
| alvo_dano_camera | float | 0,10–0,50 | data file | `IATuning` (0,25) |
| dano_medio | float | > 0 | calculated | média dos danos que acertam (~10) |

**Output Range:** t_min_morrer ≥ 0; com invulnerabilidade de 40 passos o jogador nunca recebe mais de 1,5 golpes por segundo, qualquer que seja a multidão.
**Example:** Lâmina (100): n = ceil(100 / 16) = 7 golpes da Fenda elite, t_min = 6 × 40 = 240 passos (4 s). Ressonância (80): n = 5, t_min = 160 passos (2,67 s). Alvo 0,25: 2,5 golpes de ~10 por câmara com a Lâmina, 2 com a Ressonância.

### Faixas do `IATuning`

| Campo | Inicial | Faixa | O que quebra fora dela |
|---|---|---|---|
| `surgimento_s` | 0,8333 (50) | 0,5–1,2 (30–72) | < 0,5: o inimigo ataca antes de o jogador o ver; > 1,2: câmara parada esperando |
| `espera_inicial_s` | 0,3333 + até 0,8333 | 0,2–0,6 + até 0,5–1,2 | < 0,2: o 1º golpe sai logo ao surgir; > 1,2: a onda parece parada |
| `espera_s` | 0,1667 + até 0,5 | 0,1–0,4 + até 0,3–0,8 | < 0,1: o comum ataca em sequência cerrada |
| `ranged_perto_px` / `ranged_longe_px` | 345 / 570 | 250–400 / 450–700 (perto < longe) | perto ≥ longe: o atirador oscila; > 700: foge do alcance de tela |
| `ranged_ataque_px` | 975 | 700–1100 | > 1100: atira de muito longe (a R11 só deixa atirar na vista); < 700: não alcança o outro lado da câmara |
| `charger_engaja_px` / `charger_reaproxima_px` | 570 / 456 | 400–700 / 300–600 (reaproxima < engaja) | reaproxima ≥ engaja: a Fenda para antes de poder atacar |
| `fator_recuperacao_andar` | 0,4 | 0–1 | 1: o inimigo cola no jogador na recuperação |
| `recuperacao_dist_min_px` | 90 | 60–150 | < 60: encosta; > 150: nunca fecha a distância |
| `fator_contorno` | 0,5 | 0–1 | 0: o atirador fica parado entre as duas distâncias |
| `execucao_melee_passos` / `execucao_ranged_passos` | 10 / 6 | 1–20 / 1–15 | 0: ficam sem recuo |
| `avanco_passos` | 26 | 12–40 | muda o retângulo da Fenda (Telégrafos F4) |
| `elite_prof_min` (`EliteRules`) | 3 | 1–6 | > `p_max` (4): nenhum elite no MVP |
| `max_elites_onda` (`EliteRules`) | 1 | 1–3 | > 3: onda só de elites |
| `alvo_dano_camera` | 0,25 | 0,10–0,50 | < 0,10: o jogador não é ameaçado; > 0,50: câmara de 2 golpes mortais |
| `margem_visivel_px` | 0 | 0–200 | > 200: tiro de fora da vista |

Faixas inclusivas, comparadas em passos (F7 do Conteúdo).

### Validação do `IATuning`, `EnemyDef` e `EliteRules`

Somam-se às faixas do V2 do Conteúdo. **Erros** vão para a tela de erros do catálogo e a run não começa; **avisos** ficam no registro de validação.

| Regra | Tipo | Condição | Por quê |
|---|---|---|---|
| IV1 | erro | passos(`surgimento_s`) < 1, `avanco_passos` < 1, execução < 1, ou `espera` com piso < 1 passo | inimigo que age sem aviso ou fase de 0 passos |
| IV2 | erro | `ranged_perto_px` ≥ `ranged_longe_px`, ou `charger_reaproxima_px` ≥ `charger_engaja_px` | atirador que oscila, charger que nunca ataca |
| IV3 | erro | algum fator ∉ [0, 1], ou `elite_prof_min` < 0, ou `max_elites_onda` < 1 | valores sem sentido |
| IV4 | erro | `EnemyDef` com comportamento fora de {`melee`, `ranged`, `charger`, `chefe`} | inimigo sem estados (Conteúdo R8) |
| IV5 | aviso, cruzada com Movimento | velocidade de um comum ≥ 0,8 × a menor velocidade do jogador (342) | o jogador deixa de ser mais rápido que os comuns (hoje 153 contra 342) |
| IV6 | aviso, cruzada com Telégrafos | `avanco_passos` difere do N da F4 de Telégrafos | o retângulo da Fenda deixa de ser a envoltória |
| IV7 | aviso, cruzada com Armas e Câmaras | F5: `t_min_morrer` < 2 s para alguma arma, ou `alvo_dano_camera` fora de 0,10–0,50 | o jogador pode morrer sem reação (hoje 2,67 s e 4 s) |
| IV8 | aviso | `margem_visivel_px` > 200 | tiro de fora da vista (a R11 garante o resto) |
| IV9 | aviso | campo fora da faixa de design | as contas deste GDD deixam de valer |

**Saída do validador:** uma entrada por regra e por objeto; o erro suspende o aviso da mesma regra. IV5–IV8 dependem de dados de outros sistemas e rodam onde roda o MV1 do Movimento (Movimento OQ3).

## Edge Cases

> `game-designer` e `ai-programmer` não consultados nesta seção: modo Lean.

**Surgir e aproximar**

- **Se o jogador estiver em cima do ponto de spawn:** nada acontece durante o surgimento (não atingível, não ataca, sem contato); o `melee` só inicia o preparo depois dos 50 passos.
- **Se o inimigo surgir dentro de um Selo:** o Selo não o fere nem o desacelera até ele sair do surgimento (Selo R3, atingível).
- **Se um `ranged` estiver fora da vista com `timer` ≤ 0:** não inicia o preparo (R11); ele **avança em direção ao jogador** até entrar na vista, para não ficar parado para sempre.
- **Se o `charger` já estiver dentro de 456 px:** não anda mais perto; só espera o `timer` e a distância ≤ 570 px.
- **Se a distância do `melee` ao jogador for 0:** a direção usa a última direção ao jogador (como o cânone); o preparo começa normalmente.

**Preparo, execução e quebra**

- **Se o teto de 24 telégrafos estiver cheio:** a IA fica em aproximação e tenta no passo seguinte (R5).
- **Se um golpe pesado quebrar a preparação:** a IA põe o inimigo em recuperação por 24 passos; o golpe não sai (R8). Um golpe pesado em execução, elite ou chefe não quebra.
- **Se o jogador estiver invulnerável no disparo:** o golpe não fere; o inimigo segue o ciclo normal (Telégrafos Edge).
- **Se o inimigo for empurrado no preparo:** o telégrafo o acompanha; a fase não muda (Telégrafos R3).
- **Se o avanço da Fenda bater numa parede ou obstáculo:** ela para de se mover contra ele (colisão, R9) e termina os 26 passos; o contato continua valendo uma vez.
- **Se a Fenda acertar o jogador e ainda estiver avançando:** só o primeiro contato fere (uma vez por avanço, Telégrafos R6).

**Movimento**

- **Se o inimigo estiver no Selo e cambaleando:** velocidade × 0,5 × 0,4 = 0,2 (R9); o avanço da Fenda ignora os dois.
- **Se dois inimigos se sobrepuserem:** cada um é empurrado pela metade da sobreposição, em sentidos opostos, uma vez por passo (R9); em multidão, vários empurrões somam.
- **Se um inimigo for empurrado para dentro de um obstáculo ou parede:** a colisão o devolve ao limite no mesmo passo (R9).

**Elites**

- **Se a onda tiver um chefe:** o chefe não é elite; o sorteio consome o real e o ignora (R10).
- **Se já houver um elite na onda:** os demais inimigos ainda consomem 1 real cada, mas não podem ser elite (R10).
- **Se a profundidade for menor que 3:** nenhum elite, e mesmo assim cada inimigo consome 1 real (consumo fixo).
- **Se o elite tomar um golpe pesado ou um empurrão:** não cambaleia nem quebra; só o empurrão reduzido (× 0,4) o move (Combate R8).
- **Se o elite abater:** não paga Fragmentos (Economia); o hitstop de abate é o pesado (Combate R10).

**Tempo, câmara e morte**

- **Se houver hitstop, pausa, Bênção ou Transição:** nenhuma fase avança (R2).
- **Se a câmara trocar:** os inimigos e os telégrafos somem (Telégrafos R7, Status R7).
- **Se o jogador morrer no mesmo passo:** o item 7 roda inteiro e os inimigos param a partir do seguinte (Combate R14).
- **Se o inimigo morrer no meio do preparo:** o telégrafo é cancelado e o golpe não sai ("morto não age").
- **Se o fluxo `ia` do RNG for consumido diferente por causa do combate:** é esperado; só o `elites` é estável por seed (RNG R7).

**Números**

- **Se um comum tiver velocidade ≥ 0,8 × a do jogador:** aviso IV5; o jogo continua, mas o jogador deixa de poder fugir.
- **Se o alvo de dano da câmara ficar fora de 0,10–0,50:** aviso IV7; as Câmaras ajustam a composição.

**Conflitos com outros GDDs:** nenhum nas partes aprovadas. Divergências do cânone, declaradas: consumo fixo do RNG no sorteio de elite (RNG R4b), o ataque do `ranged` só na vista (R11) e o avanço da Fenda sem lentidão (que é o cânone).

## Dependencies

**Depende de (upstream)**

| Sistema | Tipo | O que vem de lá | Sem ele |
|---|---|---|---|
| Combate núcleo | Forte | impacto, cambaleio, `pedir_recuperacao`, `ferir_jogador`, `disparar_projetil`, "morto não age", item 7 da R1 | os inimigos não ferem nem reagem |
| Telégrafos | Forte | `iniciar_telegrafo`, mira travada, forma, preparo, teto de 24 | o golpe sairia sem aviso |
| Conteúdo orientado a dados | Forte | `EnemyDef`, `EliteRules`, `IATuning`, F2, F4, F7, F8 (curva), comportamentos registrados | números no código |
| RNG com seed | Forte | fluxos `elites` (consumo fixo) e `ia` (não garantido) | o sorteio não é reproduzível |
| Modificadores e atributos | Forte | fonte `elite` (Vida, dano, raio, empurrão), profundidade, Abalo | sem elites nem escala |
| Selo e Fluxo | Suave | `no_selo(inimigo)`, `fator_lentidao` | sem lentidão |
| Efeitos de status | Suave | `estado(inimigo)`, dano por passo no item 7 | sem status nos inimigos |
| Câmaras e ondas | Forte, **por contrato** | quando e onde nascem, retângulo e vista, obstáculos, "câmara nova" | câmara padrão 1920×1080 sem obstáculos |
| Movimento e esquiva | Suave | velocidade do jogador (validação IV5) | sem validação de velocidade |

**É dependência de (downstream)**

| Sistema | Tipo | O que recebe |
|---|---|---|
| Câmaras e ondas | Forte | `sortear_elite`, regras de elite, alvo de dano por câmara (R12) |
| Combate núcleo | Forte | lista de inimigos, estado, `ferir_jogador`, `disparar_projetil` |
| Telégrafos | Forte | o início da preparação e o passo do disparo |
| Input e controle | Suave, **por contrato** | a **consulta de alvos** definida no Input: inimigos fora do spawn, em ordem estável (mira do gamepad) |
| Chefes (Vertical Slice) | Forte | a máquina de estados e os contratos |
| Criatura do pacto (Alpha) | Suave | alvos e a lista de inimigos |
| Feedback de combate (VFX) / Áudio / HUD | Suave | fase de cada inimigo, elite |
| Telemetria local | Suave | golpes recebidos por tipo de inimigo, elites por run |

**Bidirecionalidade:**

- Combate, Telégrafos, Selo e Fluxo, Efeitos de status, RNG, Modificadores e
  Conteúdo já citam a IA.
- Chefes, Criatura e Áudio ainda não existem; Câmaras, Feedback (VFX), HUD e Telemetria já existem e devem listar a IA em Dependencies (conferência pendente). **Armas das Doutrinas** (Forte): a F5 usa a `vida_max` das armas e o IV7 é cruzado com Armas (AV3/AV4).
  Cada um, ao ser escrito, deve listar "IA de inimigos e elites" em Dependencies.
- **Índice:** a linha 14 lista Combate, Telégrafos, RNG, Conteúdo e Modificadores;
  acrescentar Selo e Fluxo e Efeitos de status (suaves), Câmaras (por contrato) e
  Movimento (suave).

## Visual/Audio Requirements

> `art-director` e `audio-director` não consultados: modo Lean.

- **Legibilidade** (P3, Art Bible §4.5, §5): cada inimigo tem silhueta e
  comportamento próprios: o Eco corre, a Anomalia flutua à distância, a Fenda se
  alinha antes de investir. As Anomalias ficam com L* ≤ 70 (magenta de corpo),
  abaixo do telégrafo.
- **Surgindo:** animação de 50 passos (fiapos de tinta se formando), sem
  colisão e sem telégrafo; o inimigo só é "atingível" ao terminar.
- **Preparo e execução:** o corpo mostra a pose de preparo durante o telégrafo
  (sem andar) e a pose de ataque nos 6, 10 ou 26 passos da execução; a
  recuperação mostra o recuo (cortável pelo cambaleio).
- **Elite:** a **coroa de espinhos** e a aura dourada pulsante (Art Bible §4.3);
  raio × 1,2, para ler de relance; o dourado é só do elite no VFX de combate.
- **Cambaleio e quebra:** tranco procedural (Combate V6); elite só 3° de tranco.
- **Selo:** inimigo no Selo mostra o sinal fino sob os pés (Selo e Fluxo, Visual).
- **Multidão** (9 inimigos): silhuetas e telégrafos distintos; sem efeito de
  corpo que cubra o contorno do telégrafo.
- **Áudio** (provisório): um som de surgimento baixo; um grunhido curto no início
  do preparo de cada tipo (Eco, Anomalia, Fenda); sem som contínuo.

> 📌 **Asset Spec** — rodar `/asset-spec system:ia-de-inimigos-e-elites` depois do
> Art Bible: rigs e poses de Eco, Anomalia e Fenda (surgir, preparo, execução,
> recuperação), coroa e aura de elite.

## Game Feel

- **Cada inimigo é um jeito de ser ameaçado:** o jogador aprende o ritmo do Eco
  (corre e golpeia), da Anomalia (recua, atira) e da Fenda (se alinha, investe).
- **Pressão sem trapaça:** a ameaça vem de vários inimigos ao mesmo tempo, não de
  um inimigo injusto; o telégrafo diz sempre onde e quando.
- **Tempo de reação:** 11 a 27 passos de folga (Telégrafos F6); o primeiro golpe
  de um atirador sai em 1,8 a 2,6 s depois de surgir.
- **Elite:** o inimigo que se esquiva, não se atropela.
- **Alvo de playtest** (proposta): ≥ 80% dos testadores descrevem em uma frase
  como cada comum ataca ("corre", "atira", "investe"), sem dica (registro [M]).

## UI Requirements

- Sem tela própria. A Vida dos inimigos comuns não é mostrada; a barra do chefe é
  do GDD de HUD e de Chefes.
- O HUD não mostra o estado dos inimigos. Os sinais de elite, Selo e status são
  VFX no mundo (Pipeline, Efeitos de status, Selo).
- Acessibilidade: o elite se diferencia por forma (coroa) e tamanho (raio × 1,2),
  não só pela cor dourada (Art Bible §7.9).

## Cross-References

| Documento | Seção | Uso neste GDD |
|---|---|---|
| `design/gdd/combate-nucleo.md` | R1 (item 7), R7, R8.7, R9, R13, R14, R16 | ordem do passo, projétil inimigo, quebrar, atingível, dano no jogador, morto não age, contratos |
| `design/gdd/telegrafos.md` | R2, R5, R6, R7, F2–F4 | preparo, mira travada, formas, avanço, quebra |
| `design/gdd/modificadores-e-atributos.md` | R10, R12, F2 | fonte `elite`, M do disparo, Abalo |
| `design/gdd/conteudo-orientado-a-dados.md` | R1, R8, V2, F2, F4, F7, F8 | `EnemyDef`, `EliteRules`, comportamentos registrados, conversões, curva de chance |
| `design/gdd/rng-com-seed.md` | R4b, R7, tabela de finalidades | fluxos `elites` e `ia` |
| `design/gdd/selo-e-fluxo.md` | R3, R4 | `no_selo`, lentidão |
| `design/gdd/efeitos-de-status.md` | R4, R6 | dano por passo, Abalo |
| `design/gdd/armas-das-doutrinas.md` | F3, F4, R7 | Vida por profundidade, golpes recebidos, p = 0 |
| `design/gdd/movimento-e-esquiva.md` | R4 | velocidade do jogador (IV5) |
| `design/gdd/cena-3-4-e-camera.md` | R6 | retângulo jogável e vista |
| `design/gdd/gdd-cross-review-2026-11-10.md` | D-W11, D-W14, D-I8 | alvo de dano recebido, ataque de fora da tela |
| Khaeros `packages/action-core/src/engine.ts` | `:318–392`, `:915–1156` | spawn, `updateEnemy`, separação |
| Khaeros `packages/combat-rules/src/arenaContent.ts` | `:86–97` | números dos inimigos |

## Acceptance Criteria

> `qa-lead` não consultado (modo Lean); a revisão única do GDD cobre regras e
> critérios. A F5 vale só para o MVP (Estilhaço Vivo e os chefes passam de 20 de dano).

**Fixture IA** (comparações de distância e de chance com tolerância de 1e-9; provisório: dublês de Combate, Telégrafos, Selo, Status, RNG e
Câmaras): `IATuning` de fábrica, jogador em (0; 0) com raio 27 px e Vida 100,
câmara 1920×1080 com vista igual, passos contados a partir de 0; o fluxo `ia`
devolve o inteiro que o critério diz.

**Fases**

- **AC-IA-01 [L] R3 — surgindo.** Nos 50 passos de surgimento o inimigo não é atingível, não ataca, não tem telégrafo e não recebe status; no passo 50 a fase é aproximação com `timer` = 20 + n (n = 0 → 20; n = 49 → 69).
- **AC-IA-02 [L] R4 — melee.** Eco a 600 px anda 2,55 px por passo; com `timer` ≤ 0 e distância ≤ 78 px entra em preparo e chama `iniciar_telegrafo` uma vez; com distância 79: não entra.
- **AC-IA-03 [L] R4 — ranged.** Anomalia a 300 px recua 1,95 px/passo; a 450 px contorna a 0,975 px/passo (perpendicular); a 700 px avança; com `timer` ≤ 0 e distância < 975 px, visível, entra em preparo; a 976 px: não.
- **AC-IA-04 [L] R4 — charger.** Fenda a 500 px avança; a 400 px não anda; com `timer` ≤ 0 e distância ≤ 570 px entra em preparo; a 571 px: não entra.
- **AC-IA-05 [L] R5 — preparo parado.** Nos 26 passos do preparo do Eco a posição não muda (sem empurrão); a execução sai no mesmo passo em que o telégrafo dispara.
- **AC-IA-06 [L] R5 — teto de telégrafos.** Com 24 telégrafos ativos, `iniciar_telegrafo` é recusado e a IA fica em aproximação; no passo seguinte tenta de novo.
- **AC-IA-07 [L] R6 — melee.** Jogador dentro do setor: `ferir_jogador(9)` uma vez e o Eco fica parado 10 passos; fora do setor: nenhum dano, mesmos 10 passos.
- **AC-IA-08 [L] R6 — ranged.** `disparar_projetil` uma vez, na mira travada, e a Anomalia fica parada 6 passos; velocidade do projétil 6,9 px/passo.
- **AC-IA-09 [L] R6/R9 — charger.** Avança 26 passos a 7,56 px/passo (196,6 px), com ou sem Selo e com ou sem cambaleio; a parede o para; um único contato fere.
- **AC-IA-10 [L] R7 — recuperação.** Eco: 50 passos; anda a 1,02 px/passo se a distância > 90 px; Anomalia não anda; no fim, aproximação com `timer` = 10 + n (n de 0 a 29).
- **AC-IA-11 [L] R8 — quebrar.** Golpe pesado em um comum em preparo: recuperação de 24 passos, o golpe não sai e o telégrafo é `quebrado`; em execução, elite e chefe: nada.

**Movimento**

- **AC-IA-12 [L] R9 — velocidade.** Eco: 153 px/s (2,55 px/passo); no Selo 76,5; cambaleando 61,2; nos dois 30,6; o avanço da Fenda segue 7,56 px/passo nos quatro casos.
- **AC-IA-13 [L] R9 — separação.** Dois Ecos a 20 px (raios 24 + 24): sobreposição 28, cada um empurrado 14 px em sentidos opostos; elite usa raio 28,8.
- **AC-IA-14 [L] R9 — obstáculos e parede.** Um corpo dentro de um obstáculo ou além da parede volta ao limite no mesmo passo.

**Elites**

- **AC-IA-15 [L] R10/F1 — sorteio.** Onda de 4 inimigos em p 4 (chance 0,13): consome exatamente 4 reais; com r = 0,12 no 1º, o 1º é elite; os 3 seguintes não, mesmo com r < 0,13; r = 0,13 exato: não é elite; em p 1, 4 reais e nenhum elite.
- **AC-IA-16 [L] R10/F2 — números.** Eco elite em p 0: Vida 72, raio 28,8 px, dano 11 no golpe; em p 4, Vida 86; o chefe nunca é elite; com p 2 e r = 0, nenhum elite.
- **AC-IA-17 [L] R10 — consumo fixo.** O jogador em outra posição ou com outra Vida não muda o estado do fluxo `elites` depois da onda.
- **AC-IA-18 [L] R8/R10 — armadura do elite.** O elite não cambaleia e a preparação dele não quebra com golpe pesado.

**Visível e passo**

- **AC-IA-19 [L] R11 — ranged fora da vista.** Anomalia fora do retângulo visível com `timer` ≤ 0: não inicia o preparo e avança até o jogador; dentro da vista: inicia; com `margem_visivel_px` 100, inicia a até 100 px fora.
- **AC-IA-20 [L] R2 — ordem e parada.** Por inimigo: Status, impacto, IA, nessa ordem; Vida ≤ 0: a IA não age; hitstop, pausa, Bênção e Transição: nenhuma fase avança.
- **AC-IA-21 [L] R2/Edge — jogador morre.** O item 7 roda inteiro no passo da morte e os inimigos param no passo seguinte.

**Fórmulas e dados**

- **AC-IA-22 [L] F3/F4 — ciclos.** Ciclo mínimo: Eco 96, Anomalia 142, Fenda 158 passos; 1º tiro da Anomalia entre 106 e 155 passos; 1º avanço da Fenda entre 112 e 161.
- **AC-IA-23 [L] F5/R12 — teto de dano.** Lâmina: 7 golpes da Fenda elite e `t_min_morrer` 240 passos; Ressonância: 5 e 160; fora de `alvo_dano_camera` 0,10–0,50: aviso IV7.
- **AC-IA-24 [I] R14 — erros.** Passos < 1, `ranged_perto_px` ≥ `ranged_longe_px`, `charger_reaproxima_px` ≥ `charger_engaja_px`, fator fora de [0, 1] ou comportamento desconhecido: erro IV1–IV4 e a run não começa.
- **AC-IA-25 [I] R14 — avisos de fábrica.** O catálogo de fábrica não gera nenhum aviso IV5–IV9 (comuns a 153, 117 e 126 px/s contra 0,8 × 342 = 273,6; `avanco_passos` 26 = N dos Telégrafos; `t_min_morrer` 2,67 s ≥ 2 s; `margem_visivel_px` 0 ≤ 200).

**Captura e playtest**

- **AC-IA-26 [V] Visual/Audio — elite.** Captura de uma onda de 5 com 1 elite: a coroa e o raio × 1,2 o distinguem em tons de cinza e nos 3 simuladores de daltonismo; as Anomalias não passam de L* 70.
- **AC-IA-27 [M] Game Feel — leitura.** Registro com testador, build e contagem: ≥ 80% descrevem como cada comum ataca, sem dica (proposta).
- **AC-IA-28 [L] R4/R11 — fora da vista a menos de 345 px.** Anomalia fora do retângulo visível e a 300 px do jogador (com `timer` ≤ 0): avança em direção ao jogador (não recua) até entrar na vista; ao entrar, passa às regras da vista (recua) e, com o `timer` ≤ 0 e a distância < 975 px, inicia o preparo.
- **AC-IA-29 [I] R14 — avisos com dado defeituoso.** Comum com velocidade 280 px/s: aviso IV5; `avanco_passos` 20 com N = 26 nos Telégrafos: IV6; Vida do jogador 40 e dano máximo 16 (`t_min_morrer` 80 passos): IV7; `margem_visivel_px` 250: IV8; campo fora da faixa: IV9.
- **AC-IA-30 [L] F1 — curva de chance.** p 3: chance 0,11; p 4: 0,13; p 9: 0,23; p 10: 0,25; p 12: 0,25 (teto); p 2: 0; comparações com tolerância 1e-9.

## Open Questions

| # | Pergunta | Dono | Resolver até |
|---|---|---|---|
| 1 | R11 (ranged só ataca na vista) é regra nova, fora do cânone: conferir a sensação | game-designer | primeiro playtest |
| 2 | `alvo_dano_camera` 0,25 é proposta (D-W14); calibrar com o primeiro playtest e o `/balance-check` | game-designer + Câmaras | primeiro playtest |
| 3 | O avanço da Fenda não é desacelerado (cânone); depois do Selo, vale revisar | game-designer | `/balance-check` |
| 4 | Padrões e fúria do chefe, reforços invocados (fluxo `ia`) | Chefes | GDD de Chefes |
| 5 | Altar de Provação (chance 0,45, até 3 elites por onda): fora do MVP | Câmaras / Alpha | GDD de Câmaras |
| 6 | A IA reage ao status (fugir ao queimar)? | game-designer | Alpha |
| 7 | Máximo de 9 inimigos simultâneos e orçamento de onda: dono das Câmaras | Câmaras e ondas | GDD de Câmaras |
| 8 | Índice: linha 14 com Selo, Status, Câmaras e Movimento em Depends On | usuário / producer | próxima edição do índice |
| 9 | Velocidade dos comuns × velocidade do jogador (IV5): manter o jogador sempre mais rápido? | game-designer | `/balance-check` |
| 10 | `alvo_dano_camera` só é verificável com dado de jogo: a Telemetria local grava o dano recebido por câmara e o `/balance-check` o compara com 0,25; o dano segue sem escala com a profundidade (cânone) | Câmaras / Telemetria | primeiro playtest |
