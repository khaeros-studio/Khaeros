# Portas e recompensas

> **Status**: Approved (2026-11-11; revisão única por subagente, 3 bloqueantes corrigidos sem re-review; sem entrada no review log)
> **Author**: usuário + Claude (design-system, modo Lean)
> **Last Updated**: 2026-11-11
> **Last Verified**: 2026-11-11
> **Implements Pillar**: P2 *A Beira cobra* (escolher uma porta custa as outras); P4

> **Nota (2026-11-11, Economia de Fragmentos):** pendente: `creditar(porta, n)` devolve o efetivo; Portas segue dona de `fragmentos_base`/`fragmentos_passo_prof`. ("Morte vence a limpeza" feito em 2026-11-12, R2 e AC-PR-23.)

> **Nota (2026-11-11, Bênçãos):** pendente: R3 passa a pedir com `pedir_oferta(região, índice_câmara)`, trata `oferta_ja_aberta` e `sem_bencao`, e consulta `restantes()` para tirar o peso da porta de bênção com pool 0; "3 ofertas" significa 3 cartas.

> **Nota (2026-11-11, Telemetria local):** pendente: evento de porta escolhida com `tipo` e `opcoes` (tipos oferecidos).

> **Nota (2026-11-13):** Provação > 0 como erro agora é a regra PV7 (validação da `RewardTable`).

> **Decisões do usuário (2026-11-12) aplicadas:** a câmara de índice 5 do Limiar não dá recompensa (só a vitória, Run R4); a porta depois do índice 4 é forçada `ultima`; 3 escolhas livres (depois dos índices 0, 1 e 3); recompensas concedidas nos índices 1, 2 e 4; o `p_max` é das Câmaras (R3).

## Summary

**Portas e recompensas** decide o que cada câmara dá ao ser limpa (bênção, 2 ou 3
Fragmentos, ou 30% de cura) e quais portas aparecem depois: 2 ou 3 portas de tipos
**distintos**, cada uma mostrando a recompensa da próxima câmara. A primeira câmara
da run dá uma bênção. Entrar numa porta custa as outras (P2). Dona da `RewardTable`,
do fluxo `portas` (consumo fixo) e da curva de Fragmentos por porta.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Câmaras e ondas, RNG com seed, Conteúdo orientado a dados`

## Overview

> `game-designer` e `economy-designer` não consultados nesta seção: modo Lean.

**Portas e recompensas** decide o que cada câmara dá ao ser limpa e quais portas
o jogador vê depois. A porta mostra a **recompensa da próxima câmara** (Hades): o
jogador escolhe um destino e, ao limpá-lo, recebe o que a porta prometia. No MVP
há três tipos: **bênção** (3 ofertas de Tradição), **Fragmentos** (2 ou 3) e
**cura** (30% da Vida máxima). A primeira câmara da run sempre dá uma bênção.

- **Quantas portas:** 2 (70%) ou 3 (30%); só 1 antes do santuário (cura), do
  chefe (bênção) e da última câmara jogável (`ultima`, sem recompensa).
- **Quais:** tipos **distintos** na mesma escolha (sorteio ponderado 3/2/1 sem
  reposição); com 3 portas, os três tipos aparecem.
- **Ordem ao limpar:** a recompensa da câmara, depois a Bênção (se for o caso),
  depois as portas.
- **Dono dos números:** a `RewardTable` (pesos, chance de 3 portas, Fragmentos e
  cura por porta). As Câmaras cuidam do estado, da posição e da interação das
  portas.

A **fantasia** é a de escolher o próprio destino com o preço à vista: cada porta
promete uma coisa, e entrar numa delas é abrir mão das outras (P2). Quem precisa
de Vida entra pela cura; quem quer ficar mais forte, pela bênção; quem poupa,
pelos Fragmentos.

As regras seguem o cânone (`engine.ts:394–416`, `:467–508`, `:231`), convertido,
com três decisões do usuário (2026-11-11): tipos distintos na mesma escolha
(fecha a D-N2); a primeira câmara dá uma bênção; o Altar de Provação fica
fora do MVP (Câmaras OQ 5). Sem este sistema a run não teria recompensa nem
escolha de caminho.

> **→ vira ADR:** como a recompensa pendente e as portas são guardadas no estado
> da run, e a integração com a Tela de bênção (pausa do mundo e retorno).

## Detailed Design

### Core Rules

> `game-designer` e `economy-designer` não consultados nesta seção: modo Lean. As
> regras seguem o cânone (`engine.ts:231`, `:394–416`, `:467–533`), com a
> profundidade p das Câmaras (só combate, Câmaras R3).

**R1. Tipos de recompensa** (tokens do Conteúdo R8): `bencao`, `fragmentos` e
`cura`; `provacao` é **reservado** (Alpha, Câmaras OQ 5). Cada câmara de combate
tem **uma** recompensa, que é a da porta escolhida na câmara anterior; a **primeira
câmara da run** tem `bencao` (decisão do usuário, 2026-11-11; cânone). **Exceção
(decisão do usuário, 2026-11-12):** a última câmara jogável da região (no Limiar, a de
índice 5) **não dá recompensa**: limpá-la só dá a vitória (+15 Fragmentos,
`fragmentos_vitoria`, Economia; Run R4).

**R2. Conceder** (ao receber `camara_limpa(p, tipo)` das Câmaras, fase Limpa). Em
ordem:
0. **morte vence a limpeza:** se `jogador_morreu` e `camara_limpa` chegam no mesmo
   passo, as Portas **não creditam** nada (nem recompensa, nem Fragmentos, nem
   pedido de oferta); a Run encerra com morte;
1. se o tipo da câmara é `santuario`: nenhuma recompensa (a cura de 40% já foi
   dada na entrada; Câmaras R12); vai ao passo 3;
1b. se a câmara é a última jogável da região (índice 5 no Limiar): nenhuma
   recompensa; a Run responde `fim_da_run` (vitória, +15) e **não há porta**
   (Run R4);
2. concede a recompensa da câmara (R3 a R5), emitindo `recompensa(tipo,
   quantidade)`; se for bênção, as Portas chamam `pedir_oferta(região, índice da
   câmara limpa)` na Bênçãos e **não abrem a tela** (a Bênçãos e a Tela de bênção
   abrem, e o mundo para até a escolha; Pipeline R2); `bencao_escolhida` só chega
   depois de `tela_fechada`, e só então vai ao passo 3;
3. pede às Câmaras que abram as portas (R6 a R8).

No chefe (reservado), a recompensa é a do chefe (Run e regiões) e não há portas.

**R3. Bênção.** Pede ao GDD de Bênçãos **3 ofertas** (fluxos `bencaos` e
`raridade`). Se não restar nenhuma bênção por tomar, a recompensa **vira
Fragmentos** (R4, cânone).

**R4. Fragmentos.** Quantidade = `fragmentos_base + floor(p / fragmentos_passo_prof)`
= 2 + floor(p / 3), com p da câmara **que acabou de ser limpa**: 2, 2, 2, 3, 3
nas câmaras de combate p 0 a 4. É a quantidade que a porta mostrou (R8). Entra na conta da run (Economia de Fragmentos).

**R5. Cura.** Quantidade = `round(Vida_max × cura_pct)` (30%: 30 com a Lâmina, 24
com a Ressonância), limitada à Vida máxima. A cura é dada mesmo com a Vida cheia
(a porta já foi escolhida).

**R6. Quantas portas.** Depende da **próxima câmara** (da `RegionDef`, via Run):
- próxima é de **combate**: `n` = 3 com chance `chance_3_portas` (0,3), senão 2;
- próxima é o **santuário**: 1 porta, `santuario` (a cura de 40% é a recompensa;
  não sorteia nem consome o fluxo);
- próxima é o **chefe** (reservado): 1 porta, `chefe` (não sorteia);
- a próxima é a **última câmara jogável** (no Limiar, a de índice 5; a porta é a
  depois do índice 4): 1 porta, `ultima`, **sem ícone de recompensa** (a câmara não
  dá recompensa); não sorteia e consome **0 reais** do fluxo `portas`.

**R7. Quais tipos** (decisão do usuário, 2026-11-11: tipos distintos). O fluxo
`portas` usa a chave (`portas`, região, **índice da câmara na região**, santuário e chefe incluídos; Câmaras R3, RNG): a escolha feita ao limpar a câmara de índice i usa a chave de i, e não p. Consome **sempre 4 reais** por escolha de combate (RNG R4b):
- `u0` decide `n` (R6);
- `u1`: 1º tipo, ponderado por `pesos` (bênção 3, Fragmentos 2, cura 1);
- `u2`: 2º tipo, ponderado entre os que restam;
- `u3`: consumido e **não usado** (o 3º tipo é o que sobra), para o consumo ser
  fixo.

As portas usam os `n` primeiros tipos, **na ordem sorteada, da esquerda para a
direita**. Com 3 portas aparecem os três tipos. Tipos com peso 0 não saem.

**R8. O que a porta mostra.** O tipo (ícone) e a quantidade: "+2 ou +3
Fragmentos", "+30% de Vida" e "bênção (3 ofertas)". Entrar numa porta custa as
outras: o preço (P2) é o caminho que se deixa para trás. Mestre por porta é do
GDD de Mestres ofertantes (Vertical Slice).

**R9. Escolha.** As Câmaras entregam `porta_escolhida(i)` (Câmaras R13); este
GDD guarda o tipo como a recompensa da próxima câmara e o entrega à Run. A porta
`santuario` e a `chefe` não carregam recompensa de porta.

**R10. `RewardTable`** (Conteúdo R1).

| Campo | Valor inicial | Cânone |
|---|---|---|
| `pesos` | bênção 3, Fragmentos 2, cura 1, Provação 0 (reservado) | `[boon×3, fragments×2, heal]` |
| `chance_3_portas` | 0,3 | `nextRandom < 0,3` |
| `fragmentos_base` | 2 | `2 + …` |
| `fragmentos_passo_prof` | 3 | `floor(depth / 3)` |
| `cura_pct` | 0,3 | `HEAL_REWARD` 0,3 |
| `primeira_recompensa` | `bencao` | `enterRoom(..., "boon")` |
| `provacao_prof_min` / `provacao_repetida_vira` | 2 / `bencao` (reservados) | `TRIAL_MIN_DEPTH` 2 |

A cura do santuário (40%) é do `RoomTuning` das Câmaras, **não** da `RewardTable`
(dono único; edição pequena no Conteúdo).

**R11. Injeção.** Recebe por injeção: `RewardTable`, `camara_limpa` e
`porta_escolhida` das Câmaras, a próxima câmara e o tipo (Run), o fluxo `portas`,
a Vida do jogador e a conta de Fragmentos. As ofertas vêm do GDD de Bênçãos. Os
testes montam tudo em memória.

### States and Transitions

| Estado | Entra quando | Sai para |
|---|---|---|
| Recompensa pendente | entrada de uma câmara (a da porta) | Concedida (`camara_limpa`) |
| Recompensa concedida | R2 passo 2 | Portas abertas |
| Portas fechadas | R2 passo 3 antes de abrir | Portas abertas (Câmaras R13) |
| Porta escolhida | `porta_escolhida(i)` | Recompensa pendente da câmara seguinte |

**Mundo:** a recompensa e as portas só acontecem na fase Limpa das Câmaras (sem combate).
Na Bênção, o mundo para até a escolha.

### Interactions with Other Systems

| Sistema | Recebe daqui | Fornece para cá | Dono da interface |
|---|---|---|---|
| Câmaras e ondas | quantas portas e quais tipos; pedido de abrir | `camara_limpa(p, tipo)`, `porta_escolhida(i)`, estado e posição das portas | Câmaras (portas), este GDD (conteúdo) |
| Bênçãos (Tradições) | `pedir_oferta(região, índice da câmara limpa)` (3 cartas); as Portas **não abrem a tela** | oferta, `bencao_escolhida` (só depois de `tela_fechada`) | Bênçãos; **provisório** |
| Tela de bênção e componente de carta | — (quem a abre é a Bênçãos) | `tela_fechada` | Tela de bênção; **provisório** |
| Economia de Fragmentos | Fragmentos por porta (R4) | a conta da run | Economia; **provisório** |
| Run e regiões | recompensa da próxima câmara | próxima câmara e tipo; início da run | Run; **provisório** |
| RNG com seed | — | fluxo `portas` (4 reais) | RNG |
| Conteúdo orientado a dados | — | `RewardTable`, tokens de recompensa | Conteúdo |
| Modificadores e atributos | cura (Vida) | `vida_max` | Modificadores |
| HUD / Feedback de combate (VFX) / Áudio | evento `recompensa`, portas | — | apresentação |

## Formulas

> `systems-designer` e `economy-designer` não consultados nesta seção: modo Lean.
> Conta do cânone e dos GDDs aprovados. `round` arredonda x,5 para longe do zero
> (F7 do Conteúdo).

### F1. Fragmentos por porta

The door_fragments formula is defined as:

`fragmentos(p) = fragmentos_base + floor(p / fragmentos_passo_prof)` ; p = profundidade da câmara **limpa**

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| p | int | 0–`p_max` (4) | calculated | profundidade (Câmaras R3) |
| fragmentos_base | int | ≥ 0 (2) | data file | `RewardTable` |
| fragmentos_passo_prof | int | ≥ 1 (3) | data file | `RewardTable` |

**Output Range:** 2 a 3 no Limiar (sobe 1 a cada 3 de profundidade).
**Example:** p 0, 1, 2 → 2; p 3, 4 → 3; p 6 → 4. No Limiar a porta de Fragmentos paga nos índices 1, 2 e 4 (p 1, 2 e 3); o índice 5 (p 4) não dá recompensa. O total das 3 câmaras escolhidas por porta é 2 + 2 + 3 = **7**, no máximo.

### F2. Quantas portas e quais tipos

The door_draw formula is defined as:

`n = 3` se `u0 < chance_3_portas`, senão `2` ;
1º tipo: ponderado por `pesos` com `u1` ; 2º tipo: ponderado entre os que restam com `u2` ; o 3º é o que sobra ;
`P(par {a, b}) = P(a, depois b) + P(b, depois a)` ; fluxo `portas`: **4 reais por escolha**, sempre

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| u0…u3 | float | [0, 1) | RNG `portas` | os 4 reais (u3 não é usado) |
| chance_3_portas | float | 0–1 (0,3) | data file | `RewardTable` |
| pesos | float[3] | ≥ 0 (3; 2; 1) | data file | `RewardTable` |
| n | int | 2–3 | calculated | número de portas |

**Output Range:** tipos distintos; com n = 3 aparecem os três.
**Example (pesos 3/2/1):** o 1º tipo: bênção para u1 < 0,5; Fragmentos para 0,5 ≤ u1 < 0,8333; cura acima. O 2º tipo: com bênção primeiro, Fragmentos se u2 < 0,6667; com Fragmentos primeiro, bênção se u2 < 0,75; com cura primeiro, bênção se u2 < 0,6.

| Par (n = 2) | Probabilidade |
|---|---|
| bênção + Fragmentos | 0,5 × 2/3 + 1/3 × 3/4 = 0,5833 |
| bênção + cura | 0,5 × 1/3 + 1/6 × 3/5 = 0,2667 |
| Fragmentos + cura | 1/3 × 1/4 + 1/6 × 2/5 = 0,1500 |

P(bênção na escolha) = 0,3 × 1 + 0,7 × 0,85 = **0,895**; Fragmentos 0,8133; cura 0,5917 (soma 2,3 = nº médio de portas).

### F3. Bênçãos por run (Limiar)

The run_boons formula is defined as:

`E[bênçãos] = 1 + k × P(bênção na escolha)` se o jogador sempre escolhe bênção quando há ; k = nº de escolhas livres ; teto = 1 + k

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| k | int | ≥ 0 (3) | calculated | portas livres no Limiar (sequência: combate, combate, combate, santuário, combate, combate, chefe) |
| P | float | 0–1 (0,895) | calculated | F2 |

**Output Range:** de 1 (a primeira câmara) a 1 + k.
**Example:** o Limiar tem 3 escolhas livres (as portas depois das câmaras de índice 0, 1 e 3; no MVP a porta antes do santuário (depois do índice 2) é forçada, a porta depois do índice 4 é a forçada `ultima` (sem recompensa), depois do índice 5 não há porta (Run R4, `fim_da_run`) e a do chefe é reservada): E = 1 + 3 × 0,895 = 3,685 ≈ **3,69 bênçãos**, máximo 4 no teto de escolha; quem nunca escolhe bênção tem 1 (mínimo).

### F4. Cura da porta

The door_heal formula is defined as:

`cura = round(Vida_max × cura_pct)` ; `Vida' = min(Vida_max, Vida + cura)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| Vida_max | int | 80–100 | calculated | atual do jogador (Modificadores) |
| cura_pct | float | 0–1 (0,3) | data file | `RewardTable` |

**Output Range:** 0 a Vida_max.
**Example:** Lâmina (100): 30; Ressonância (80): 24; com Vida 85/100: o jogador ganha 15, mas o evento mostra 30 (nominal). O santuário cura 40% (32 com a Ressonância; Câmaras).

### Faixas da `RewardTable`

| Campo | Inicial | Faixa | O que quebra fora dela |
|---|---|---|---|
| `pesos` (bênção / Fragmentos / cura) | 3 / 2 / 1 | 1–6 cada (soma > 0) | cura 0: uma porta a menos; bênção 1: pouca Tradição por run |
| `chance_3_portas` | 0,3 | 0–0,6 | > 0,6: quase sempre os três tipos, a escolha some |
| `fragmentos_base` | 2 | 1–4 | 0: a porta de Fragmentos não vale nada |
| `fragmentos_passo_prof` | 3 | 2–5 | 1: a curva dobra em p 4 |
| `cura_pct` | 0,3 | 0,15–0,39 | ≥ 0,4: a cura da porta passa a do santuário (PV4) |
| `primeira_recompensa` | bênção | `bencao`, `fragmentos` ou `cura` | token inválido: erro PV2; vale na 1ª câmara da run (a Run decide se uma região nova a repete) |

Faixas inclusivas. `provacao_prof_min` e `provacao_repetida_vira` são reservados (Alpha).

### Validação da `RewardTable`

Somam-se às faixas do V2 e do V8 do Conteúdo (pesos ≥ 0, soma > 0). **Erros** vão para a tela de erros do catálogo e a run não começa; **avisos** ficam no registro de validação.

| Regra | Tipo | Condição | Por quê |
|---|---|---|---|
| PV1 | erro | `chance_3_portas` ∉ [0, 1], `cura_pct` ∉ [0, 1], `fragmentos_base` < 0 ou `fragmentos_passo_prof` < 1 | sorteio ou quantidade sem sentido |
| PV2 | erro | `primeira_recompensa` fora de {`bencao`, `fragmentos`, `cura`} (`provacao` é reservado) | 1ª câmara sem recompensa |
| PV7 | erro | `pesos` com `provacao` > 0 (a Provação é reservada, Alpha) | a Provação não existe no MVP; o peso não pode sair no sorteio |
| PV3 | aviso | menos de 3 tipos com peso > 0 e `chance_3_portas` > 0 | três portas distintas são impossíveis |
| PV4 | aviso | `cura_pct` ≥ `santuario_cura` (0,4, Câmaras) | a porta cura mais que o santuário |
| PV5 | aviso, cruzada com Bênçãos | F2: P(bênção na escolha) < 0,8 | pouca Tradição por run (hoje 0,895) |
| PV6 | aviso | campo fora da faixa de design | as contas deste GDD deixam de valer |

**Saída do validador:** uma entrada por regra e por objeto; o erro suspende o aviso da mesma regra. PV5 depende de dados de outros sistemas e roda na 2ª passada do validador do Conteúdo, como o MV1 do Movimento (decidido 2026-11-13).

## Edge Cases

> `game-designer` não consultado nesta seção: modo Lean.

**Conceder**

- **Se a recompensa é bênção e não resta nenhuma por tomar:** vira Fragmentos, com a quantidade da R4 (R3, cânone).
- **Se a recompensa é cura e a Vida está cheia:** é dada igual (0 efetivo); o evento mostra a quantidade nominal (R5).
- **Se a câmara limpa é o santuário:** nenhuma recompensa; as portas abrem (R2).
- **Se a câmara limpa é a última jogável (índice 5 no Limiar):** nenhuma recompensa e nenhuma porta; a Run encerra com vitória (+15; R1, R2 passo 1b).
- **Se a morte e a limpeza chegam no mesmo passo:** a morte vence; as Portas não creditam (R2 passo 0).
- **Se a câmara limpa é o chefe (reservado):** a recompensa é a do chefe (Run); sem portas (R2).
- **Se o jogador abrir a pausa ou a Bênção estiver aberta:** o mundo para; as portas só abrem depois da escolha (R2).
- **Se houver hitstop pendente ao limpar:** as Câmaras só limpam com hitstop 0 (Câmaras R9); nada é concedido antes.

**Portas**

- **Se a próxima câmara é o santuário ou o chefe:** 1 porta forçada, sem sorteio e sem consumir o fluxo (R6).
- **Se menos de 3 tipos têm peso > 0:** `n` fica limitado ao número de tipos disponíveis (R7) e o PV3 avisa.
- **Se o `pesos` zerar um tipo (cura 0):** ele não aparece; com 2 tipos, as 2 portas são esses dois.
- **Se a Provação (reservada) tiver peso > 0 no dado:** erro PV7 (a run não começa) até o Alpha defini-la; não sai no MVP.
- **Se o jogador sair da região com a porta escolhida e a região acabar:** a Run decide o que vem depois (vitória ou próxima região).
- **Se duas escolhas seguidas oferecerem o mesmo tipo:** vale; a regra de tipos distintos é por escolha, não entre escolhas.

**Números**

- **Se a Vida máxima mudar por bênção:** a cura usa a Vida máxima do momento da concessão (F4).
- **Se p for maior que `p_max`:** os Fragmentos seguem a fórmula (F1), sem teto.
- **Se o jogador estiver em outra posição ou com outra Vida:** o fluxo `portas` não muda (RNG R4b).

**Divergências do cânone, declaradas:** a porta antes do santuário é `santuario` (no cânone era `heal`) e o fluxo `portas` consome 4 reais fixos (RNG R4b).

**Conflitos com outros GDDs:** um, resolvido: a cura do santuário aparece na `RewardTable` do Conteúdo e no `RoomTuning` das Câmaras; o dono é as Câmaras, e o Conteúdo é editado.

## Dependencies

**Depende de (upstream)**

| Sistema | Tipo | O que vem de lá | Sem ele |
|---|---|---|---|
| Câmaras e ondas | Forte, **por contrato** | `camara_limpa(p, tipo)`, `porta_escolhida(i)`, estado e posição das portas | nada dispara a recompensa |
| RNG com seed | Forte | fluxo `portas` (4 reais fixos) | as portas não são reproduzíveis |
| Conteúdo orientado a dados | Forte | `RewardTable`, tokens de recompensa (V4, V8), F7 | números no código |
| Run e regiões | Forte, **por contrato** | próxima câmara e tipo, início da run | sem destino das portas |
| Bênçãos (Tradições) | Forte, **por contrato** | 3 ofertas por pedido; "sem bênção por tomar" | a recompensa de bênção não existe |
| Economia de Fragmentos | Suave, **por contrato** | a conta da run | Fragmentos sem destino |
| Modificadores e atributos | Suave | `vida_max` para a cura | cura sem base |

**É dependência de (downstream)**

| Sistema | Tipo | O que recebe |
|---|---|---|
| Câmaras e ondas | Forte | quantas portas e quais tipos; pedido de abrir |
| Run e regiões | Forte | a recompensa da próxima câmara |
| Bênçãos / Tela de bênção e componente de carta | Forte | o pedido de oferta e a abertura da tela |
| Economia de Fragmentos | Suave | Fragmentos por porta |
| HUD / Feedback de combate (VFX) / Áudio | Suave | evento `recompensa`, portas abertas |
| Telemetria local | Suave | escolhas de porta por tipo |

**Bidirecionalidade:**

- Câmaras (R11, R13), RNG (finalidade `portas`), Conteúdo (`RewardTable`) e o
  cross-review já citam Portas e recompensas.
- Run, Bênçãos, Tela de bênção, Economia, HUD, VFX, Áudio e Telemetria ainda não
  existem; cada um, ao ser escrito, deve listar "Portas e recompensas" em
  Dependencies.
- **Índice:** a linha 17 lista Câmaras, RNG e Conteúdo; acrescentar Run e regiões e
  Bênçãos (por contrato) e Economia de Fragmentos (suave).

## Visual/Audio Requirements

> `art-director` e `audio-director` não consultados: modo Lean.

- **Porta** (Art Bible, Câmaras V): moldura dourada atravessada por rachaduras
  magenta, que mostram ganho e preço juntos; abertas, com a moldura acesa;
  fechadas, em tinta apagada.
- **Ícone por tipo**, distinto por **forma e valor**, não só por cor: bênção (a
  Tradição, uma chama de tinta), Fragmentos (cacos), cura (gota), santuário e chefe
  (símbolos próprios). A quantidade escrita ao lado ("+2", "+30%").
- **Conceder:** Fragmentos sobem como cacos do chão até a conta; cura, uma luz quente
  no corpo do jogador, sem flash de tela; a bênção abre a Tela de bênção.
- **Áudio** (provisório): um som por tipo ao conceder; um estalo ao abrir as portas.

> 📌 **Asset Spec** — rodar `/asset-spec system:portas-e-recompensas` depois do Art
> Bible: moldura da porta (fechada e aberta), ícones dos 5 tipos, efeitos de
> conceder.

## Game Feel

- **Escolher o destino:** o jogador lê as portas de relance e decide em poucos
  segundos; o preço (as portas que sobram) fica à vista.
- **Respiro com propósito:** a câmara limpa dá a recompensa e abre uma decisão, não
  um corredor.
- **Tensão entre tipos:** Vida baixa puxa a cura; build fraca puxa a bênção; quem
  poupa vai nos Fragmentos.
- **Alvo de playtest** (proposta): ≥ 80% dos testadores dizem o que cada porta dá
  antes de entrar (registro [M]).

## UI Requirements

- **Portas no mundo:** ícone, quantidade e moldura (Câmaras R13); o aviso "Interagir"
  perto da porta é do HUD.
- **Tela de bênção:** do GDD de Tela de bênção e componente de carta.
- **Evento `recompensa`:** o HUD mostra o ganho (Fragmentos na conta, Vida na barra).
- Acessibilidade: o tipo se diferencia por forma e texto, não só por cor
  (Art Bible §7.9).

> **📌 UX Flag — Portas e recompensas:** a leitura das portas e a Tela de bênção são
> UI. No Pre-Production, rodar `/ux-design` para o HUD e a Tela de bênção antes das
> epics.

## Cross-References

| Documento | Seção | Uso neste GDD |
|---|---|---|
| `design/gdd/camaras-e-ondas.md` | R3, R9, R11, R12, R13, OQ 5, OQ 8 | `camara_limpa`, p, estado e posição das portas, Provação fora do MVP |
| `design/gdd/rng-com-seed.md` | R4b, tabela de finalidades | fluxo `portas` |
| `design/gdd/conteudo-orientado-a-dados.md` | R1, R8, V4, V8, F7 | `RewardTable`, tokens, pesos |
| `design/gdd/modificadores-e-atributos.md` | R2, R10 | `vida_max` |
| `design/gdd/armas-das-doutrinas.md` | R2 | Vida máxima 100 e 80 |
| `design/gdd/gdd-cross-review-2026-11-06b.md` | D-N2, D-N5 | tipos distintos, curva de Fragmentos |
| `design/gdd/gdd-cross-review-2026-11-10.md` | D-W16, D-W8 | porta de Fragmentos, soma com a Economia |
| `design/gdd/game-concept.md` | §3, §6 | pilar P2, portas |
| Khaeros `packages/action-core/src/engine.ts` | `:231`, `:394–416`, `:467–533` | sorteio, recompensas, avanço |

## Acceptance Criteria

> `qa-lead` não consultado (modo Lean); a revisão única do GDD cobre regras e
> critérios.

**Fixture PR** (provisório: dublês de Câmaras, Run, Bênçãos, Economia e RNG):
`RewardTable` de fábrica, Limiar, jogador com Vida máxima 100, Bênçãos dublê com pool de 8 bênçãos por tomar (vazio no AC-PR-03), passos a partir de
0; o fluxo `portas` dá os reais que o critério diz; comparações com tolerância de
1e-9.

**Conceder**

- **AC-PR-01 [L] R1/R2 — primeira câmara.** A 1ª câmara da run, sem porta anterior, dá `bencao` ao limpar.
- **AC-PR-02 [L] R2 — ordem.** Câmara de combate limpa com recompensa `bencao`: ordem = `recompensa`, Tela de bênção até a escolha, abertura das portas; as portas não abrem antes da escolha.
- **AC-PR-03 [L] R3 — sem bênção por tomar.** Nenhuma bênção resta: a recompensa vira Fragmentos com a quantidade da R4 (p 1: 2).
- **AC-PR-04 [L] R4/F1 — Fragmentos.** Câmaras limpas em p 0, 1, 2, 3, 4: 2, 2, 2, 3, 3; p 6: 4.
- **AC-PR-05 [L] R5/F4 — cura.** Vida 50/100: 80; Vida 85/100: 100 (ganho 15, evento 30); Ressonância (80 de Vida máxima, Vida 40): 64 (cura 24); Vida cheia: sem efeito e evento nominal.
- **AC-PR-06 [L] R2 — santuário e chefe.** Santuário limpo: nenhuma recompensa, as portas abrem; chefe (reservado): recompensa da Run e sem portas.

**Portas**

- **AC-PR-07 [L] R6 — quantas.** Próxima de combate: `u0` = 0,2999 → 3 portas; `u0` = 0,3 → 2.
- **AC-PR-08 [L] R6 — forçadas.** Próxima é o santuário: 1 porta `santuario`; é o chefe: 1 porta `chefe`; é a última câmara jogável (depois do índice 4 no Limiar): 1 porta `ultima`, sem ícone de recompensa; nenhuma consome o fluxo.
- **AC-PR-09 [L] R7/F2 — tipos distintos.** Com `n` = 3: os três tipos, em ordem sorteada; com `n` = 2: dois tipos diferentes; nunca dois iguais.
- **AC-PR-10 [L] R7 — consumo e chave.** Cada escolha de combate consome exatamente 4 reais (n = 2 ou 3); as forçadas, 0; o jogador em outra posição ou com outra Vida não muda o estado do fluxo. Mesma seed e mesmo índice de câmara dão as mesmas portas, independentemente das escolhas anteriores; as escolhas livres do Limiar (depois das câmaras de índice 0, 1 e 3) usam as chaves 0, 1 e 3; as portas forçadas (depois do índice 2, `santuario`, e depois do índice 4, `ultima`) consomem 0 e não precisam de chave.
- **AC-PR-11 [L] R7/F2 — fronteiras.** 1º tipo: `u1` 0,4999 → bênção; 0,5 → Fragmentos; 0,8333 → Fragmentos; 0,8334 → cura (a fronteira é 5/6 = 0,83333…). 2º tipo com bênção primeiro: `u2` 0,6666 → Fragmentos; 0,6667 → cura.
- **AC-PR-12 [L] R7 — posições.** A ordem sorteada vale da esquerda para a direita (R13 das Câmaras: x = 735, 1185 com 2 portas; 510, 960, 1410 com 3).
- **AC-PR-13 [L] R7 — peso 0.** `provacao` com peso 0 nunca sai; com cura 0, `n` fica em 2 e as portas são bênção e Fragmentos.
- **AC-PR-14 [L] R7/F2 — distribuição.** Com 100 000 sorteios do fluxo, n = 2: bênção + Fragmentos 0,583, bênção + cura 0,267, Fragmentos + cura 0,150 (± 0,01); P(bênção na escolha) 0,895 (± 0,01).
- **AC-PR-15 [L] R8 — o que a porta mostra.** Cada porta mostra tipo e quantidade, com a quantidade de Fragmentos da **próxima** câmara de combate (depois da câmara p 1: +2; depois do santuário, cuja próxima é a câmara p 3: +3; depois de p 2 a porta é a forçada `santuario`; depois do índice 4 a porta é a forçada `ultima`, sem quantidade).

**Escolha e dados**

- **AC-PR-16 [L] R9 — escolha.** `porta_escolhida(i)` guarda o tipo como recompensa da próxima câmara; as portas `santuario`, `chefe` e `ultima` não carregam recompensa.
- **AC-PR-17 [L] F3 — bênçãos por run.** No Limiar (3 escolhas livres), escolhendo sempre bênção quando há, a média em 100 000 runs é 3,69 (± 0,05); nunca escolhendo, 1. Versão determinística: com `u0` ≥ 0,3 e `u1` < 0,5 nas 3 escolhas, são 4 bênçãos; com `u1` ≥ 0,5 e `u2` ≥ 0,75, nenhuma bênção nas portas e 1 no total.
- **AC-PR-18 [I] R10 — erros.** `chance_3_portas` fora de [0, 1], `cura_pct` fora de [0, 1], `fragmentos_passo_prof` 0 ou `primeira_recompensa` = `provacao`: erros PV1 e PV2; `pesos` com `provacao` = 1: erro PV7; a run não começa.
- **AC-PR-19 [I] R10 — avisos.** O catálogo de fábrica não gera nenhum aviso PV3 a PV6; cura 0 com `chance_3_portas` 0,3: PV3 (e PV6, peso fora da faixa); `cura_pct` 0,45: PV4; pesos 1 / 1 / 4 (bênção 1/6; P(bênção no par) = 1 − 0,4667 = 0,5333, P(bênção na escolha) = 0,3 + 0,7 × 0,5333 = 0,673): PV5; campo fora da faixa: PV6.
- **AC-PR-20 [I] R11 — injeção.** O sistema roda com `RewardTable`, Câmaras, Run, Bênçãos e Economia dublês, sem SceneTree.

**Captura e playtest**

- **AC-PR-21 [V] Visual/Audio — ícones.** Captura com 2 e 3 portas abertas: os ícones se distinguem por forma e valor em tons de cinza e nos 3 simuladores de daltonismo; a quantidade é legível.
- **AC-PR-22 [M] Game Feel — leitura.** Registro com testador, build e contagem: ≥ 80% dizem o que cada porta dá antes de entrar (proposta).

**Morte, fim da run e última câmara** (2026-11-12)

- **AC-PR-23 [L] R2 passo 0 — morte vence a limpeza.** `jogador_morreu` e `camara_limpa` no mesmo passo (câmara com recompensa `fragmentos`): nenhum crédito (`creditar` não é chamado), nenhum `pedir_oferta`, nenhuma porta; a Run encerra com morte.
- **AC-PR-24 [L] R2 passo 1b — `fim_da_run`.** Limpar o índice 5 do Limiar: nenhuma recompensa (nenhum evento `recompensa`, nenhum `pedir_oferta`), nenhuma porta, a Run responde `fim_da_run`. `fim_da_run` e `jogador_morreu` no mesmo passo: vale a morte (AC-PR-23).
- **AC-PR-25 [L] R2 passo 2 — roteamento da oferta.** Recompensa `bencao`: as Portas chamam `pedir_oferta(região, índice da câmara limpa)` e não abrem a tela; `bencao_escolhida` só é aceita depois de `tela_fechada`; as portas abrem só depois dele.

## Open Questions

| # | Pergunta | Dono | Resolver até |
|---|---|---|---|
| 1 | D-W16: o cross-review 11-10 recomendou tirar a porta de Fragmentos do sorteio no MVP; o usuário escolheu manter tipos distintos (2026-11-11), então ela fica como a opção de poupar. Os Fragmentos só contam no MVP e só pesam de verdade com a Oficina (Vertical Slice) | game-designer / Economia | GDD de Economia |
| 2 | Altar de Provação (peso, Provação repetida vira bênção, profundidade mínima): fora do MVP, campos reservados | Portas / Alpha | Alpha |
| 3 | Mestre por porta (duas bênçãos diferentes são escolha real, D-W7): fora do MVP | Mestres ofertantes | Vertical Slice |
| 4 | ~~Edição pequena no Conteúdo~~ **Feita em 2026-11-11:** a `RewardTable` perdeu a "cura do Santuário" (é do `RoomTuning`) e ganhou `chance_3_portas`, `primeira_recompensa` e `fragmentos_passo_prof` | — | ✅ |
| 5 | A porta de cura deve ficar fora do sorteio com a Vida cheia? | game-designer | primeiro playtest |
| 6 | Quantidade de Fragmentos da Economia (outras fontes: chefe, vitória) soma com a F1 (D-W8) | Economia de Fragmentos | GDD de Economia |
| 7 | Índice: linha 17 com Run, Bênçãos e Economia em Depends On | usuário / producer | próxima edição do índice |
| 8 | Ordem da Tela de bênção e das portas na pausa e na perda de foco | Tela de bênção / Input | GDD de Tela de bênção |
