# Bênçãos (Tradições)

> **Status**: Approved (2026-11-11; revisão única por subagente: 5 bloqueantes e 5 grupos de recomendadas, corrigidos sem re-review; sem entrada no review log)
> **Author**: usuário + Claude (design-system, modo Lean)
> **Last Updated**: 2026-11-11
> **Last Verified**: 2026-11-11
> **Implements Pillar**: P1 *Toda bênção é uma filosofia*; P4

> **Nota (2026-11-11, Tela de bênção e carta):** pendente: a Bênçãos monta `CartaView` (id, nome, doutrina, raridade, glifo, ícone, texto, `preco_texto`); `oferta_trocada(cartas, trocas)` com o mesmo payload; segura `bencao_escolhida` até `tela_fechada`; R11/Edge Cases: a pausa **abre** em Bênção (Input é a fonte; **aplicada**: o Input já tem Pausa entrando por `pausar` na Bênção); `tamanho_oferta` 4–5 reservado (R3/R4 fixam 3).

## Summary

**Bênçãos (Tradições)** decide a oferta de bênçãos: quando uma câmara dá bênção,
sorteia 3 Tradições entre as que o jogador ainda não tem, cada uma com uma raridade
(Comum, Rara ou Épica); o jogador escolhe uma, ou troca as ofertas, e o efeito entra
na run. No MVP o pool são as 18 Tradições do cânone, o sorteio é puro e não há troca
até a Oficina.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Modificadores e atributos, RNG com seed, Armas das Doutrinas, Conteúdo orientado a dados`

> **Nota (2026-11-11, revisão cruzada):** pendente: `pedir_oferta` recebe o **índice da câmara limpa**; D-W15 (Ataque ≈ 3× Especial), teto de cargas de esquiva e teto do M do Selo continuam sem dono; pool zerado muda as probabilidades das Portas (F2/PV5).

## Overview

> `game-designer` e `systems-designer` não consultados nesta seção: modo Lean.

**Bênçãos (Tradições)** é a dona da oferta, não do efeito. As Portas pedem uma
oferta quando a câmara limpa dá bênção; este sistema sorteia 3 cartas, deixa o
jogador escolher e entrega a escolhida ao Modificadores, que aplica o efeito.

- **O pool:** as **18 Tradições** do cânone, de todas as Doutrinas, para qualquer
  arma (decisão do usuário, 2026-11-11). Uma bênção nunca se repete nem evolui.
- **A oferta:** 3 cartas (bênçãos distintas), cada uma com raridade sorteada (60%
  Comum, 30% Rara, 10% Épica; ×1, ×1,5, ×2). **Sorteio puro**, sem garantia de
  Doutrina: é possível uma run sem nenhuma Tradição da arma (OQ 8).
- **A escolha:** pegar uma carta, ou trocar as ofertas (precisa de trocas; no MVP
  a base é 0). Não se pode pular.
- **O fim do pool:** sem bênção por tomar, a recompensa vira Fragmentos. É código
  defensivo: o Limiar dá no máximo 4 bênçãos (o pool termina em 14), e o caso só se
  testa por injeção.
- **Sem Mestre:** no MVP a oferta é anônima; o Mestre de cada Doutrina é da fatia
  vertical.

A **fantasia** é a de que cada bênção é uma filosofia (P1): escolher é aceitar uma
leitura do mundo e o preço dela, e a mesma Beira muda de cara conforme o que se
aceita. Sem este sistema a run seria só combate: não haveria build.

As regras seguem o cânone (`engine.ts:418–433`, `:458–465`, `:1253–1271`; `ARENA_BOONS`,
`ARENA_RARITY_NAMES`), com três decisões do usuário (2026-11-11): pool de 18, sorteio
puro e troca com base 0.

> **→ vira ADR:** como a oferta e a lista de tomadas são guardadas no estado da run, e
> a integração com a Tela de bênção (pausa do mundo e retorno).

## Detailed Design

### Core Rules

> `game-designer` e `systems-designer` não consultados nesta seção: modo Lean.

**R1. Escopo.** As 18 `BoonDef` (Tradições, ids `trad_*` do cânone) formam o pool.
Nome, descrição e efeito vêm do dado; os efeitos são do Modificadores.

**R2. Pool.** 18 menos as já tomadas. Uma bênção **nunca se repete nem evolui**
(cânone).

**R3. Oferta.** As Portas pedem com `pedir_oferta(região, índice_câmara)` (o índice
da câmara na região, o mesmo de Portas R7; no MVP, com uma região, igual ao número
da câmara na run). Uma **oferta** tem n_cartas = `min(3, pool)` **cartas** (o "3
ofertas" de Portas R3 significa 3 cartas). Com pool 0, a Bênçãos emite `sem_bencao`
e a recompensa vira Fragmentos (Portas R3); as Portas podem consultar `restantes()`
antes de pedir, só para o peso da porta. Com uma oferta já aberta, o pedido é
respondido com `oferta_ja_aberta` e a oferta aberta continua.

**R4. Sorteio** (fluxos `bencaos` e `raridade`, com a chave (região, índice da
câmara)):
- `livres` = as bênçãos do pool **na ordem do manifesto** (índice no manifesto das
  `BoonDef`; Conteúdo R10, RNG R4); n = nº de `livres`; k' = `min(3, n)`;
- `bencaos` usa o RNG **F7** (k distintos de n): para i = 0 … k'−1, `j = i + F4(n −
  i)`, troca `idx[i] ↔ idx[j]`; a carta i é `idx[i]`. Depois **descarta 3 − k'
  reais** (extensão do F7 para o consumo fixo de 3);
- `raridade` consome **3 reais**; a carta i (na ordem do sorteio) usa o real i: u <
  0,6 Comum; u < 0,9 Rara; senão Épica (mais o `raridade_bonus`, R7); os reais das
  cartas que não existem são descartados;
- **6 reais por oferta e 6 por troca**, nunca dependentes do combate (RNG R4b). A
  quantidade de trocas é escolha do jogador, e o RNG já a prevê (RNG Edge Cases).

**Divergências do cânone, declaradas:** o F7 por troca no lugar do laço de rejeição
do cânone (consumo variável); e a raridade em fluxo próprio, sorteada para todas as
cartas, e não intercalada com a escolha.

**R5. Escolha.** O jogador pega 1 das cartas, ou troca (R6); se a troca e a escolha
chegarem no mesmo passo, **a troca vence** (cânone). **Não pode pular** (cânone). Ao
pegar, em ordem:
1. o Modificadores recebe `(efeito, raridade)` e aplica `valor × escala[raridade]`
   (Modificadores F5);
2. a Bênçãos registra (id, raridade);
3. emite `bencao_tomada(id, raridade)` e `bencao_escolhida`;
4. só então as Portas abrem as portas, ou a Run encerra com vitória (Run R4).
Os eventos `oferta_aberta(cartas, trocas)` (ao abrir) e `oferta_trocada` (a cada
troca) vão para a Tela, o HUD, o Áudio e a Telemetria.

**R6. Troca.** Com `trocas_oferta` ≥ 1, gasta 1 e re-sorteia (R4) do **pool
inteiro**, que pode repetir cartas da oferta anterior, **mantendo o
`raridade_bonus`** (cânone). A troca não custa tempo, porque o mundo está parado. A
base do MVP é **0**; a Oficina soma depois.

**R7. Raridade.** A `RarityTable` (Comum 60% / Rara 30% / Épica 10%; escalas 1 / 1,5 /
2) é daqui (Conteúdo). O `raridade_bonus` (Provação) é +1 com teto Épica e vale 0 no
MVP (reservado, Câmaras OQ 5).

**R8. Consultas.** `restantes()` (tamanho do pool, para as Portas) e `tomadas()` (para
a Run, o HUD e a Telemetria).

**R9. Reset.** A lista de tomadas zera na Nova run (Run R8).

**R10. Texto.** A descrição mostrada já vem com o número da raridade ofertada
(como `describeArenaBoon` no cânone), formatado como o Modificadores arredonda: ao
inteiro mais próximo, meio longe de zero (Rara de O Muro de Pedras: "+38"; Épica:
"+50").

**R11. Mundo.** Com a oferta aberta o mundo para (Pipeline R2; Input no contexto
Bênção). A tela e o componente de carta são do GDD de Tela de bênção.

**R12. Injeção.** Recebe as `BoonDef`, a `RarityTable`, `BencaosTuning`
(`tamanho_oferta` 3, `trocas_iniciais` 0), os fluxos e o Modificadores. Os testes
montam tudo em memória.

### States and Transitions

| Estado | Entra quando | Sai para |
|---|---|---|
| Sem oferta | início da run, ou depois de uma escolha | Oferta aberta (pedido das Portas) ou Sem oferta (`sem_bencao`) |
| Oferta aberta (cartas, trocas) | o pedido das Portas, com pool ≥ 1 | Escolhida, ou Oferta aberta de novo (troca, R6) |
| Escolhida | o jogador pega uma carta (R5) | Sem oferta |

Com pool 0 não há Oferta aberta: sai `sem_bencao` na hora. O mundo fica parado
durante toda a Oferta aberta (R11).

### Interactions with Other Systems

| Sistema | Recebe daqui | Fornece para cá | Dono da interface |
|---|---|---|---|
| Portas e recompensas | `bencao_escolhida`, `sem_bencao`, `oferta_ja_aberta`, `restantes()` | `pedir_oferta(região, índice_câmara)` | Portas (pedido); Bênçãos (oferta) |
| Modificadores e atributos | o efeito escolhido e a escala da raridade | `trocas_oferta`, `aplicar` | Modificadores |
| Conteúdo orientado a dados | — | `BoonDef`, `RarityTable`, `BencaosTuning` | Conteúdo |
| RNG com seed | — | fluxos `bencaos` e `raridade` | RNG |
| Run e regiões | `tomadas()` | início e reset da run | Run |
| Tela de bênção e componente de carta | cartas (id, raridade, texto), trocas restantes | escolha, troca | Tela; **provisório** |
| Armas das Doutrinas | — | bênçãos que escalam os golpes | Armas |
| HUD / Áudio / Telemetria | `oferta_aberta`, `oferta_trocada`, `bencao_tomada` | — | apresentação |

## Formulas

**F1. Chance de uma bênção estar na oferta** = `min(3, n) / n`, com n = pool. Em
n = 18: 1/6 (0,167); em n = 14 (fim do Limiar): 3/14 (0,214).

**F2. Raridade.** Comum 0,6; Rara 0,3; Épica 0,1. Escala esperada = 0,6 × 1 + 0,3 ×
1,5 + 0,1 × 2 = **1,25**.

**F3. Raridade por oferta.** P(ao menos uma Épica em 3 cartas) = 1 − 0,9³ = **0,271**;
P(ao menos uma Rara ou melhor) = 1 − 0,6³ = **0,784**.

**F4. Pool.** n = 18 − k tomadas. No Limiar há no máximo 4 bênçãos (Portas F3), então
n termina em 14 e o pool não esgota sem debug.

**F5. Exemplo de sorteio (F7 do RNG).** n = 18 (índices 0 a 17 do manifesto), u =
(0,5; 0; 0,99): i = 0 → j = 0 + `F4(18)` = 9, troca 0 ↔ 9; i = 1 → j = 1 + `F4(17)` =
1, sem troca; i = 2 → j = 2 + `F4(16)` = 17, troca 2 ↔ 17. Oferta: índices **9, 1, 17**.
Com n = 2 e u = (0,5; 0,99; x): i = 0 → j = 1, troca; i = 1 → j = 1; oferta:
índices **1, 0**; o 3º real é descartado.

## Tuning Knobs

| Knob | Padrão | Faixa | Categoria | Efeito e racional |
|---|---|---|---|---|
| `tamanho_oferta` | 3 | 1–5 | gate | cartas por oferta (cânone 3); **4–5 reservado**: BN1 exige 3 no MVP (R3/R4 fixam 3 reais); acima de 5 a tela não cabe |
| `trocas_iniciais` | 0 | 0–5 | gate | trocas no começo da run; a Oficina soma; 0 é o cânone; **dono único da base de trocas** (Bênçãos): o atributo `trocas_oferta` do Modificadores só soma (OQ: ajustar o Modificadores) |
| pesos da `RarityTable` | 0,6 / 0,3 / 0,1 | somam > 0 | curva | `ARENA` `roll < 0,6 / 0,9`; mais Épica sobe a força média (F2, F3) |
| escalas da `RarityTable` | 1 / 1,5 / 2 | ≥ 1, crescentes | curva | `RARITY_SCALE` (Modificadores F5) |
| `raridade_bonus` | 0 | 0–1 | gate | Provação (reservado): +1 com teto Épica |

**Validação** (junto com os V* do Conteúdo): BN1 (erro) `tamanho_oferta` ≠ 3 no MVP (4–5 reservado) ou fora de 1–5
ou `trocas_iniciais` negativa; BN2 (erro) `RarityTable` com pesos que não somam > 0
ou escalas não crescentes.

## Edge Cases

**Oferta**
- **Pool com 1 ou 2 bênçãos:** a oferta tem 1 ou 2 cartas; os 6 reais são consumidos
  mesmo assim (R4).
- **Pool 0:** consome os 6 reais por uniformidade e emite `sem_bencao`.
- **Pedido de oferta com uma oferta aberta, ou fora de uma run:** ignorado (erro de
  contrato); a oferta aberta continua.
- **Mesma seed e mesmas escolhas** (e as mesmas trocas): mesmas ofertas. Escolhas
  diferentes mudam o pool, mas não o consumo de reais da câmara seguinte (a chave é o
  índice da câmara); uma troca numa câmara não altera os fluxos de outra (RNG AC-27).

**Escolha e troca**
- **Escolher um índice sem carta:** ignorado; a oferta continua.
- **Pular a oferta:** não existe.
- **Troca e escolha no mesmo passo:** a troca vence (cânone).
- **Pedido com a oferta aberta:** respondido com `oferta_ja_aberta`; a oferta aberta continua e as Portas não esperam por uma segunda.
- **Troca sem `trocas_oferta`:** recusada, sem consumir real.
- **Troca com uma oferta de 1 carta:** permitida; re-sorteia a raridade (e a mesma
  carta sai de novo, pois o pool inteiro volta).
- **A mesma bênção em raridades diferentes pela troca:** é normal (R6).
- **Bênção com efeito negativo** (O Preço com Nome: Vida −10): o Modificadores resolve
  o piso de Vida.

**Mundo**
- **Morte ou abandono com a oferta aberta:** não acontece: o mundo está parado, a morte
  não ocorre, e a pausa **abre** em Bênção (Input R10 é a fonte) com "Abandonar run"
  desabilitado (Run R6); a pausa nunca pula a escolha.

## Dependencies

| Sistema | Força | Interface | Se faltar |
|---|---|---|---|
| Modificadores e atributos | Forte | aplica o efeito; `trocas_oferta` | sem efeito |
| RNG com seed | Forte | fluxos `bencaos` e `raridade` | sem sorteio |
| Conteúdo orientado a dados | Forte | `BoonDef`, `RarityTable`, `BencaosTuning`; BN1 e BN2 (Conteúdo R1 e R9) | sem pool |
| Portas e recompensas | Forte | pedido de oferta; `pedir_oferta(região, índice_câmara)` e `restantes()` para tirar o peso da porta de bênção quando o pool esgota (**edição pendente** em Portas R3) | sem recompensa de bênção |
| Armas das Doutrinas | Suave | bênçãos que escalam os golpes | — |
| Run e regiões | Suave | `tomadas()` no resumo, reset | resumo sem bênçãos |
| Tela de bênção e componente de carta, HUD, Telemetria | por contrato | cartas, escolha, eventos | dublês |
| Mestres ofertantes | reservado | retrato e voz (fatia vertical) | oferta anônima |

## Visual/Audio Requirements

Nenhum efeito próprio. Pede à apresentação: a Tela de bênção com as cartas (arte e
cor da Doutrina, a raridade legível) e o aviso de troca. Som de abrir a oferta, de
escolher e de trocar: Áudio (fatia vertical).

## Game Feel

Escolher e trocar respondem no mesmo passo, sem espera (o mundo está parado). Tempo
de leitura e de confirmação: GDD da Tela de bênção.

## UI Requirements

A Tela de bênção mostra de 1 a 5 cartas (id, raridade, texto) na **ordem do
sorteio**, o número de trocas restantes e o botão de troca. A spec de UX é do GDD de
Tela de bênção (Open Question 6).

## Cross-References

Seguem as dependências. Os valores de `BencaosTuning` entram no registro de entidades
quando o GDD for aprovado.

## Acceptance Criteria

> Fixture BN (provisório): as 18 `BoonDef` de fábrica em ordem do manifesto (a fixture
> mapeia índice → id `trad_*`), `RarityTable` e `BencaosTuning` de fábrica
> (`tamanho_oferta` 3, `trocas_iniciais` 0), RNG com seed fixa, dublês de Portas,
> Modificadores, Run e Tela, sem SceneTree.

- **AC-BN-01 [L] R1/R2 — pool.** Com nenhuma tomada, o pool tem 18; depois de tomar 1, 17, e ela nunca volta a sair numa oferta.
- **AC-BN-02 [L] R3 — tamanho.** Pool 18: 3 cartas; pool 2: 2 cartas; pool 0: nenhuma carta e `sem_bencao`.
- **AC-BN-03 [L] R4/F5 — F7 e consumo.** Com u = (0,5; 0; 0,99) e n = 18, a oferta é os índices 9, 1, 17; com n = 2 e u = (0,5; 0,99; x), os índices 1, 0. Em ambos, a oferta consome 6 reais (3 de `bencaos` e 3 de `raridade`), inclusive com pool 2 e pool 0.
- **AC-BN-04 [L] R4 — troca consome.** Uma troca consome mais 3 + 3 reais do mesmo fluxo da câmara.
- **AC-BN-05 [L] R4 — limites da raridade.** u 0,5999 → Comum; 0,6 → Rara; 0,8999 → Rara; 0,9 → Épica; a carta i usa o real i, e os reais das cartas que não existem são descartados.
- **AC-BN-06 [L] R4 — determinismo.** Mesma seed, mesma câmara, mesmas escolhas e mesmas trocas dão a mesma oferta; escolhas anteriores diferentes mudam o pool, mas o estado do fluxo depois da oferta (sem troca) é o mesmo; uma troca na câmara 1 não altera o fluxo da câmara 2.
- **AC-BN-07 [L] R4 — chave.** O pedido `pedir_oferta(limiar, índice)` usa a chave do índice: as câmaras que dão oferta no Limiar (índices 0, 1, 2 e 4; a de índice 5 não dá recompensa) usam as chaves 0, 1, 2 e 4.
- **AC-BN-08 [I] R5 — aplicar com escala.** Pegar O Muro de Pedras Épico entrega ao Modificadores `(efeito Vida máxima 25, Épica)`; com Vida base 100, a Vida máxima final é 150; Rara, 138 (137,5 arredondado meio longe de zero).
- **AC-BN-09 [I] R5 — ordem dos eventos.** A ordem é: efeitos aplicados, registro, `bencao_tomada`, `bencao_escolhida`, e só então as Portas abrem as portas.
- **AC-BN-10 [L] R5 — sem pular, índice inválido, mesmo passo.** Pular é ignorado; o índice 3 numa oferta de 3 cartas (0 a 2) é ignorado; troca e escolha no mesmo passo: a troca vence.
- **AC-BN-11 [L] R6 — troca.** Com `trocas_oferta` 1: re-sorteia, gasta 1 (resta 0) e consome 6 reais; com 0: recusada, sem consumir real.
- **AC-BN-12 [L] R6 — pool inteiro e bônus.** Uma troca pode devolver uma carta da oferta anterior (u que repete o índice 9); com `raridade_bonus` 1, a troca mantém o bônus.
- **AC-BN-13 [L] R6 — oferta de 1 carta.** Com pool 1 e 1 troca, a troca é aceita e a carta sai com raridade re-sorteada.
- **AC-BN-14 [L] R7 — `raridade_bonus`.** Com bônus 1: Comum vira Rara, Rara vira Épica, Épica continua Épica; u 0,59 com bônus 1 dá Rara.
- **AC-BN-15 [L] R8 — consultas.** Depois de 2 tomadas, `restantes()` = 16 e `tomadas()` tem 2 entradas (id, raridade) na ordem em que foram pegas.
- **AC-BN-16 [I] R9 — reset.** Após Nova run, `tomadas()` é vazio e `restantes()` = 18.
- **AC-BN-17 [I] R3 — sem bênção e pedido repetido.** Com pool 0, as Portas recebem `sem_bencao` e a recompensa vira Fragmentos; um pedido com a oferta aberta recebe `oferta_ja_aberta` e a oferta continua.
- **AC-BN-18 [L] R10 — texto.** A carta de O Muro de Pedras Épico mostra "+50 de Vida máxima"; a Rara, "+38 de Vida máxima".
- **AC-BN-19 [I] R11 — mundo parado.** Com a oferta aberta por 60 passos, os contadores do Combate permanecem iguais; depois da escolha, voltam a descontar.
- **AC-BN-20 [I] R12 — injeção.** O sistema roda com os dublês, sem SceneTree, incluindo a injeção de um pool vazio e de `trocas_oferta` > 0.
- **AC-BN-21 [L] F1/F4 — presença e pool.** Com seed fixa, pool 18 e 100 000 ofertas num fluxo contínuo, cada bênção aparece com frequência 0,1667 (± 0,005); com 14 livres, 0,2143 (± 0,005); depois de 4 tomadas o pool tem 14.
- **AC-BN-22 [L] F3 — raridade.** Nas mesmas 100 000 ofertas, a fração com ao menos uma Épica é 0,271 (± 0,005) e com ao menos uma Rara ou melhor, 0,784 (± 0,005).
- **AC-BN-23 [L] Validação.** `tamanho_oferta` 0 ou 6 e `trocas_iniciais` −1: BN1; pesos 0 / 0 / 0 ou escalas 1 / 1 / 2: BN2.

## Open Questions

| # | Pergunta | Dono | Prazo |
|---|---|---|---|
| 1 | Edições pendentes: Conteúdo (`BencaosTuning`, BN1 e BN2) e Portas (`restantes()` tira o peso da porta de bênção com pool 0) | donos de cada GDD | próxima edição de cada um |
| 2 | Mestres ofertantes (retrato e voz da Doutrina) | Mestres ofertantes | fatia vertical |
| 3 | Os 18 efeitos são placeholders calibrados por piloto automático | Telemetria / `/balance-check` | playtest humano |
| 4 | Bênçãos de duas Doutrinas combinadas | game-designer | depois do MVP |
| 5 | Provação e `raridade_bonus` | Câmaras / Bênçãos | Alpha |
| 6 | Spec da Tela de bênção e do componente de carta (ordem das cartas = ordem do sorteio) | ux-designer | GDD de Tela de bênção |
| 7 | Campos de telemetria: oferta, escolha, raridade, trocas | Telemetria local | GDD de Telemetria |
| 8 | Sinergia garantida com a Doutrina da arma e pool filtrado por arma: revisitar depois do playtest | game-designer | primeiro playtest |
| 9 | Eventos novos: `bencao_tomada`, `oferta_aberta`, `oferta_trocada`, `oferta_ja_aberta` ainda não existem em Run, Portas, HUD e Telemetria | donos de cada GDD | próxima edição de cada um |
| 10 | O RNG chama a profundidade de "número da câmara na run" e Portas R7 de "índice na região": iguais no MVP (uma região); alinhar quando houver mais de uma | RNG / Portas | Alpha (Veio Instável) |
| 11 | `trocas_oferta` (atributo do Modificadores) × `trocas_iniciais` (`BencaosTuning`): o dono único da base de trocas é `trocas_iniciais`; o Modificadores só soma. Ajustar o texto do Modificadores e conferir que a R6 lê o total sem contar a base duas vezes | Bênçãos / Modificadores | próxima edição do Modificadores |
