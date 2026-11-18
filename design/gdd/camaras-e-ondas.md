# Câmaras e ondas

> **Status**: Approved
> **Status anterior**: Approved (2026-11-11; emenda Pactos aprovada pelo usuário em 2026-11-16)
> **Author**: usuário + Claude (design-system, modo Lean)
> **Last Updated**: 2026-11-18 (consolidação de decisões aprovadas em 2026-11-16); 2026-11-15 (emenda Pactos: R1-P a R20-P, F6, Edge Cases, Dependencies e AC-CO-28 a AC-CO-43)
> **Last Verified**: 2026-11-11
> **Implements Pillar**: P3 *Reflexo que se lê* (arena legível); P2 *A Beira cobra*

> **Nota (2026-11-11, HUD):** pendente: remover dos UI Requirements "o número da câmara" no HUD (o HUD não mostra progresso); o prompt é só da porta, verbo "Interagir", alcance R13.

## Summary

**Câmaras e ondas** define a unidade de jogo do MVP: uma arena de 1920×1080 px com
2 a 4 pedras sorteadas e um ponto de entrada, onde 1 a 3 ondas (no Limiar, 1 a 2) de inimigos
nascem por um orçamento que cresce com a profundidade (0 a 4 no Limiar). Ao limpar
a última onda, com o hitstop em 0, as portas abrem para a próxima câmara. Dona
da profundidade p, da consulta "em combate", do spawn e do fim da câmara.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `IA de inimigos e elites, RNG com seed, Conteúdo orientado a dados, Cena 3/4 e câmera, Modificadores e atributos`

> **Nota (2026-11-11, revisão cruzada):** pendente: "morte vence a limpeza" (Edge/AC-CO-16) fica como regra única com Run R5, Portas e Economia. Aplicados: OQ 8 resolvida pelas Portas R2; Bidirecionalidade atualizada; a OQ 10 (dano) existe aqui, e a citação da Telemetria R11 é conferida no GDD dela.

## Overview

> `game-designer` e `level-designer` não consultados nesta seção: modo Lean.

**Câmaras e ondas** define a unidade de jogo do MVP: a **câmara**, uma arena de
1920×1080 px com obstáculos e um jeito de entrar e sair. Uma câmara de combate
traz de 1 a 3 **ondas** de inimigos, sorteadas por um orçamento que cresce com a
**profundidade** (a posição da câmara de combate na região, de 0 a 4 no Limiar).
Quando a última onda cai e o hitstop acaba, a câmara fica **limpa**, as portas
abrem e o jogador escolhe a próxima.

- **Ciclo:** entrada (Transição) → combate em ondas → câmara limpa → recompensa →
  portas → próxima câmara. O santuário é uma câmara sem combate que cura 40%.
- **Dono do espaço:** o retângulo jogável, os obstáculos (2 a 4 pedras sorteadas,
  ou fixas no santuário e no chefe) e o ponto de entrada.
- **Dono das ondas:** o orçamento, a composição, o número de ondas, o ponto de
  nascimento de cada inimigo e a chamada ao sorteio de elite (IA).
- **Dono do "em combate":** a consulta que o Combate usa para saber quando o
  jogador pode ser ferido.
- **Portas:** este GDD cuida do estado (fechada, aberta), da posição e da
  interação; **Portas e recompensas** cuida de quantas e quais.

A **fantasia** é a de entrar numa arena que se lê de relance: obstáculos que
viram cobertura, ondas que chegam em ritmo e uma câmara que, ao ser limpa,
respira. O jogador sente a descida: cada câmara é um pouco mais cheia que a
anterior.

As regras seguem o cânone (`engine.ts:246–416`, `:467–533`, `:1290–1305`),
convertido para px e passos, com quatro decisões do usuário (2026-11-11): a
profundidade conta só as câmaras de combate (0 a 4); no MVP toda câmara tem
1920×1080 px; as portas são divididas com Portas e recompensas; os obstáculos
são procedurais, como no cânone. Sem este sistema não haveria arena, ondas nem
fim de câmara.

> **→ vira ADR:** como a câmara é montada e desmontada (cena por câmara ou uma
> arena reconfigurada), onde vivem as ondas e a lista de obstáculos, e o tipo de
> colisão de pedras e paredes.

## Detailed Design

### Core Rules

> `game-designer` e `level-designer` não consultados nesta seção: modo Lean. As
> regras seguem o cânone (`engine.ts:246–316`, `:318–416`, `:467–533`,
> `:1290–1305`), convertido para px e passos (unidade × 1,5 px; Conteúdo F4, F7).

**R1. Tipos de câmara.** `combate`, `santuario` e `chefe` (reservado, Vertical
Slice). A sequência de cada região (Limiar: combate, combate, combate,
santuário, combate, combate, chefe) é da `RegionDef` (Run e regiões, Conteúdo).
*(Ver R1-P: o chefe entra no MVP.)*

**R2. A câmara.** Um retângulo de `tamanho_px` (**1920×1080 no MVP**, dentro dos
limites de 1920×1080 a 2880×1620 da Cena R6), com origem em (0; 0). O
**retângulo jogável** que Movimento, Selo, Telégrafos e IA recebem é esse
retângulo inteiro; a parede visual fica na sangria da Cena R6. **Divergência do
cânone:** o cânone recuava 51 px (`WALL`, 34 u) para dentro dos 1920×1080; aqui o
chão já é o retângulo da câmara. Cada câmara tem obstáculos (círculos) e um ponto
de entrada.

**R3. Profundidade p.** É o índice da câmara de **combate** na região, a partir
de 0; o santuário e o chefe **não contam** (decisão do usuário, 2026-11-11;
divergência do cânone, que conta o santuário e dá 0, 1, 2, 4, 5). No Limiar, p
vai de 0 a 4, e `p_max(região)` = nº de câmaras de combate − 1 (**as Câmaras são a dona única do `p_max`**, decisão do usuário, 2026-11-12; Run e Armas leem). **Santuário e chefe**
usam, em `camara_limpa(p, tipo)`, no escurecimento do Pipeline e na Vida, o p da
última câmara de combate anterior (sem salto de escurecimento). **A chave do RNG
não é p:** é o **índice da câmara na região**, santuário e chefe incluídos
(RNG, "profundidade"); no Limiar, as câmaras de combate têm índice 0, 1, 2, 4, 5. As Câmaras
informam p à IA (`sortear_elite`, Vida +5% por p), aos Modificadores (fonte
`profundidade`), ao Pipeline (escurecimento) e às Armas (validação). Isso fecha
a C-W4 do cross-review: p tem **um** dono.

**R4. Montar a câmara.** No quadro da metade do wipe (passo 3 da Transição,
Combate R1), depois do teleporte do jogador:
1. o jogador fica na **entrada** (960; 930) px (cânone: 100 u acima da borda de
   baixo);
2. o layout é gerado (R5) e as ondas são compostas (R6);
3. a câmara vai à fase Combate e a primeira onda nasce (R7), no mesmo quadro.

O santuário e o chefe têm layout fixo (R12, R14) e não sorteiam.

**R5. Layout de obstáculos** (câmara de combate; fluxo `layout` do RNG; decisão
do usuário: procedural do cânone). Número de pedras = 2 + inteiro em [0, 3) (2 a
4). Para cada pedra, **10 candidatos sempre** (RNG R4b), cada um com raio
= 42 + 1,5 × inteiro em [0, 26) px (42 a 79,5), x ∈ [270; 1650] e y ∈ [255; 765]
px. A pedra fica no **primeiro candidato** que respeita `folga_obstaculo_px`
(105 px) das pedras já postas (distância dos centros ≥ r₁ + r₂ + 105); se
nenhum respeita, a pedra é omitida (o cânone também omitia). O layout não
depende do combate.

**R6. Ondas** (fluxo `ondas`). O **orçamento** de cada onda é
`3 + 0,9 × p + 2 × índice_da_região`; o nº de ondas é 1 se p < 2, 2 se p < 6 e 3
depois (`WaveRules`). Cada onda sorteia, até 20 vezes, um inimigo do pool da
`RegionDef` com custo ≤ orçamento restante (Eco 1, Anomalia 1,5, Fenda 2),
desconta o custo e para quando nada cabe ou a onda chega a **9 inimigos**
(`max_inimigos_onda`). Todas as ondas da câmara são compostas na montagem.

**R7. Nascer** (fluxos `elites` e `spawn`). Para cada inimigo da onda, na ordem:
- a IA decide primeiro se é elite (`sortear_elite(p, ja_ha_elite)`, 1 real por
  inimigo); as Câmaras guardam `ja_ha_elite` e passam o booleano. O raio do elite
  (× 1,2) entra na margem dos candidatos, como no cânone;
- o fluxo `spawn` sorteia **sempre 14 candidatos** (x e y), com x ∈ [raio + 111;
  1920 − raio − 111] e y ∈ [raio + 111; 1080 − raio − 111] px (cânone:
  `WALL + raio + 40` u; o chão não recua a parede, mas o nascimento mantém as
  coordenadas absolutas do cânone);
- escolhe o **primeiro** candidato a **mais de** 390 px do jogador e fora das
  pedras (distância ao centro da pedra > r_pedra + raio + 12 px); se nenhum
  serve, o **último** (o cânone usava o último também);
- o inimigo nasce em Surgindo (IA R3). O ponto escolhido pode depender da
  posição do jogador; os 14 candidatos, não.

**R8. Fases da câmara.** Entrada (a Transição), **Combate** (ondas), **Limpa**
(portas) e Saída (Transição). A fase **Combate** vale da montagem até a câmara
limpa, inclusive no vão entre ondas e enquanto os inimigos surgem.

**R9. Próxima onda e câmara limpa** (item 10 da R1 do Combate). A avaliação roda
**só com o hitstop em 0** (contrato do Combate R10, decisão do usuário,
2026-11-10), então espera o congelamento do último abate. Sem inimigos vivos:
- se há onda seguinte, ela nasce no mesmo passo (`intervalo_onda_s` = 0, como no
  cânone) e a fase segue Combate;
- se não há, a câmara fica **limpa** (R11).

**R10. "Em combate"** (consulta que o Combate usa; R13.1). Verdadeira na fase
Combate; falsa na Entrada, na fase Limpa, no santuário e na Saída. A lista de
inimigos vazia não basta (vão entre ondas). Fora de combate, o jogador não leva
dano e os projéteis inimigos são removidos ao limpar.

**R11. Câmara limpa.** Ao limpar, no mesmo passo:
1. os projéteis inimigos são removidos (cânone); os telégrafos já foram
   cancelados com os donos;
2. sai o evento `camara_limpa(p, tipo)`;
3. Portas e recompensas concede a recompensa da câmara (Bênção, Fragmentos ou
   cura; **a última câmara jogável, índice 5 no Limiar, não dá recompensa e não tem
   portas**, Run R4) e depois pede as portas; a Bênção só abre com a câmara limpa e sem
   telégrafo vivo (Pipeline R2). *(Ver R11-P: a última jogável passa a ser o
   chefe, índice 6; e Portas R2 passo 2b no encontro de pacto.)*

**R12. Santuário.** Câmara sem combate: ao montar, cura `santuario_cura` (40%) da
Vida máxima do jogador, a fase vai direto a **Limpa**, sai `camara_limpa(p, santuario)` (a cura já aplicada; Portas e recompensas não dá recompensa extra) e as portas abrem. Layout
fixo: uma pedra de raio 63 px em (960; 495). Não há ondas, elites nem sorteio.

**R13. Portas** (divisão com Portas e recompensas; decisão do usuário). Este GDD
cuida do **estado**, da **posição** e da **interação**:
- as portas nascem **fechadas** e **abrem** quando Portas e recompensas as
  entrega (R11), em fila no alto, a y = 177 px, espaçadas de 450 px e centradas
  em x = 960;
- o jogador interage (Interagir) a ≤ raio da porta (69) + raio do jogador (27) +
  15 px = 111 px;
- a interação escolhe aquela porta (a recompensa da próxima câmara) e **pede a
  troca**: o orquestrador entra em Transição (Combate R1); a próxima câmara vem
  da `RegionDef` (Run) e é montada no quadro da metade do wipe (R4).
Quantas portas há e qual recompensa cada uma mostra é de Portas e recompensas.
Depois da câmara de índice 4 há **1 porta forçada** `ultima` (sem ícone de recompensa;
decisão do usuário, 2026-11-12: a câmara de índice 5 não dá recompensa), em x = 960
como toda porta única (a do santuário e a do chefe); depois da de índice 5 não há porta.
*(Ver R13-P: com o chefe no MVP, a porta depois do índice 4 é escolha livre, a
depois do índice 5 é a forçada `chefe` e a depois do índice 6 não existe.)*

**R14. Chefe** (reservado). Layout fixo: 4 pedras de 51 px em (390; 300), (1530;
300), (390; 750) e (1530; 750), uma onda só com o chefe, no ponto (960; 285) px.
Os números do chefe são do GDD de Chefes. *(Ver R14-P e R18-P: deixa de ser
reservado.)*

**R15. `WaveRules` e `RoomTuning`** (Conteúdo R1). Durações em segundos (F7),
distâncias em px (F4).

| Campo | Valor inicial | Cânone |
|---|---|---|
| `orcamento_base` | 3 | `3` |
| `orcamento_por_prof` | 0,9 | `state.depth * 0,9` |
| `orcamento_por_regiao` | 2 | `regionIndex * 2` |
| `ondas_limites` | [2; 6] (1 / 2 / 3 ondas) | `depth < 2 ? 1 : depth < 6 ? 2 : 3` |
| `max_inimigos_onda` | 9 | `MAX_ENEMIES` 9 |
| `intervalo_onda_s` | 0 | 0 (na hora) |
| `camara_largura_px` / `camara_altura_px` | 1920 / 1080 | 1280 / 720 u |
| `entrada_px` | (960; 930) | (640; 620) u |
| `obstaculos_min` / `obstaculos_var` | 2 / 3 | `2 + randomInt(3)` |
| `obstaculo_raio_min_px` / `_passos` | 42 / 26 (de 1,5 px) | 28 + `randomInt(26)` u |
| `obstaculo_x_px` / `obstaculo_y_px` | [270; 1650] / [255; 765] | 180–1100 u / 170–510 u |
| `folga_obstaculo_px` | 105 | 70 u |
| `obstaculo_tentativas` | 10 | 10 |
| `spawn_candidatos` | 14 | 14 tentativas |
| `spawn_dist_jogador_px` | 390 | 260 u |
| `spawn_margem_px` / `spawn_folga_pedra_px` | 111 / 12 | `WALL` + 40 u / 8 u |
| `portas_y_px` / `portas_espaco_px` | 177 / 450 | `WALL + 84` u / 300 u |
| `porta_raio_px` / `interagir_folga_px` | 69 / 15 | 46 u / 10 u |
| `santuario_cura` | 0,4 | `SANCTUARY_HEAL` 0,4 |

A Provação (Altar), a chance de elite e a Vida do chefe não são do MVP ou são de
outros GDDs.

**R16. Injeção.** Recebe por injeção: `WaveRules`, `RoomTuning`, a `RegionDef`
(sequência, pool, custo dos inimigos), os fluxos `layout`, `ondas`, `spawn` do RNG,
a posição do jogador, a lista de inimigos, o hitstop do Combate e as chamadas de
Portas e recompensas e da Run. Os testes montam tudo em memória.

#### Regras da emenda Pactos (emenda Pactos, 2026-11-15)

> Pedidas por `vinculo-e-pactos.md` (V4, V7, V8, V9, V41), `chefes.md` (R2, R8,
> R9, F6), `combate-nucleo.md` (R14, R19, R24), `maldicoes.md` (R1, R14) e
> `run-e-regioes.md` (R3-P, R4-P, F1-P). O texto antigo das R1–R16 fica; onde
> ele diverge, vale a regra "-P" abaixo.

**R1-P. Chefe no MVP.** O tipo `chefe` deixa de ser reservado. O Limiar tem **7
câmaras jogáveis** (Run R3-P, F1-P): índices 0 a 6 = combate, combate, combate,
santuário, combate, combate, **chefe**. A sequência continua da `RegionDef`.

**R3-P. Profundidade do chefe.** A câmara do chefe (índice 6) usa `p = 4`, o p
da última câmara de combate anterior, como a R3 já dizia para santuário e chefe
(Chefes R2). `p_max` continua **4** (Run F1-P): o chefe não é câmara de combate.
A chave do RNG da câmara do chefe é o índice 6, mas ela não pede nenhum fluxo
(R14-P).

**R4-P. Montagem com Maldição e com encontro.** A R4 ganha dois passos:
1. o jogador fica na entrada (960; 930) px (R4.1, sem mudança);
1b. **Maldição em campo** (se a run tem uma em campo): as Câmaras calculam
   `pos_entrada_maldicao` (F6) e pedem `reposicionar_maldicao(pos)` às Maldições,
   que fazem o resto da Maldições R14 (atração, imobilização e marca terminam;
   Vida, estado e recargas ficam). É o ponto a `distancia_seguir_px` **atrás** do
   jogador, isto é, abaixo dele, do lado oposto às portas
   (Maldições, Edge Cases: "atrás do jogador na entrada"). Não consome RNG e não
   muda nenhum sorteio;
2. o layout é gerado (R5; fixo no santuário e no chefe) e as ondas são compostas
   (R6);
2b. **câmara do encontro de pacto:** as Câmaras perguntam a Vínculo e pactos
   `encontro_na_camara(indice)`. Se a resposta é uma espécie, as Câmaras passam a
   lista de pedras já postas e Vínculo e pactos faz nascer a **acuada** no
   primeiro ponto livre de `pontos_acuada` (V7). A posição é regra de Vínculo e
   pactos; as Câmaras só guardam `pos_acuada` para a R7-P. Não consome RNG;
3. a câmara vai à fase Combate e a primeira onda nasce (R7, R7-P), no mesmo
   quadro.

**R7-P. Ordem de nascimento e distância da acuada.** A R7 ganha dois itens:
- **ordem:** cada inimigo recebe o seu índice `ordem` na onda (0, 1, 2…, a ordem
  da composição da R6) e as Câmaras o passam à IA junto com a posição. Na câmara
  do encontro, a IA usa a paridade de `ordem` para o alvo padrão (Vínculo V8,
  contrato V44 com a IA): par mira a acuada, ímpar mira o jogador. Fora do
  encontro, `ordem` não muda nada;
- **distância da acuada:** na câmara do encontro, enquanto a acuada
  está no estado `Acuada`, um candidato de nascimento também precisa estar a
  **mais de** `spawn_dist_acuada_px` (240) de `pos_acuada` (F3-P). Motivo: um
  inimigo que nasce colado na acuada a fere antes que o jogador leia a onda; com
  240 px e o `Surgindo` de 50 passos, o jogador tem tempo de chegar com o Chamado.
  Os 14 candidatos continuam sendo sorteados **sempre** (RNG R4b); muda só qual
  deles é escolhido, como já acontece com a posição do jogador. Se nenhum serve,
  vale o último (R7).

**R8-P. Fase `Subjugado`.** Só existe na câmara do chefe numa run de Pactos
(Chefes R9). A câmara entra em `Subjugado` ao receber `chefe_subjugado(id)` dos
Chefes, no 1º passo vivo depois do hitstop do chefe (`s + 37`, Chefes F6). Sai
para **Limpa** quando os Chefes resolvem a escolha (R18-P).

**R9-P. Câmara limpa: quem conta.** A avaliação da R9 olha só a lista de
inimigos do Combate (R9, Combate R9). **Não contam:** a Maldição em campo e a da
reserva (Maldições R1, Combate R19) e a acuada (Vínculo V7). Na fase
`Subjugado`, a R9 **não é avaliada**: o chefe subjugado continua na lista com
`Vida = 0` (Chefes R9, Combate R24), e a câmara só fica limpa pela R18-P, nunca
pela lista vazia.

**R10-P. "Em combate" em `Subjugado`.** A consulta da R10 é **falsa** na fase
`Subjugado` (contrato pedido por Chefes R9 e Combate R24). Por isso
`ferir_jogador` e `ferir_maldicao` não fazem nada (Combate R13.1, R21.1). Entre o
passo `s` do golpe final e `s + 37` a fase ainda é Combate, mas o mundo está
congelado pelo hitstop e os projéteis já foram removidos (Combate R24).

**R11-P. Última câmara jogável e encontro.** Substitui o parêntese da R11.3:
- a **última câmara jogável** do Limiar passa a ser o **chefe (índice 6)**: não dá
  recompensa de Portas e não tem portas (Portas R2 1b, Run R4-P);
- o **índice 5** vira câmara de combate comum (Run R3-P e OQ 10 da
  Run): dá a recompensa da porta escolhida depois do índice 4 e abre a porta
  forçada `chefe`;
- na **câmara do encontro**, as Portas concedem a recompensa e depois esperam
  `pacto_resolvido` antes de pedir as portas (Portas R2 passo 2b). A câmara fica
  na fase **Limpa** nesse tempo ("em combate" falso), com as portas **fechadas**.

**R13-P. Portas no Limiar com chefe.** Substitui o último parágrafo da R13:
- depois do índice 4: **escolha livre** de 2 ou 3 portas (Portas R6), nas posições
  da R13;
- depois do índice 5: **1 porta forçada `chefe`**, em x = 960 (porta única);
- depois do índice 6: **nenhuma** porta (Run `fim_da_run`).
A porta `ultima` não aparece mais no Limiar. Fica válida para uma região cuja
última câmara jogável não seja chefe (Portas R6-P).

**R14-P. Câmara do chefe sem sorteio.** A R14 vale no MVP (Chefes R2). Na
montagem do índice 6:
- layout fixo: 4 pedras de 51 px em (390; 300), (1530; 300), (390; 750) e
  (1530; 750); **não** pede o fluxo `layout`;
- uma onda só com o chefe, em (960; 285), estado `Surgindo` (IA R3); **não** pede
  os fluxos `ondas` e `spawn`;
- **não** chama `sortear_elite` e **não** consome o fluxo `elites` (Chefes R2,
  R8). `ja_ha_elite` fica falso;
- os lacaios do chefe (Chefes R8) entram na lista de inimigos pelo módulo de
  Chefes, sem passar pela R7, sem fluxo `elites` e sem fluxo `spawn`. O teto de
  `max_inimigos_onda` (9) vale para chefe + lacaios (Chefes CH6: `1 + 3 = 4`);
- não há encontro de pacto (Vínculo VP3 proíbe o último índice);
- a Maldição em campo entra pela R4-P 1b, como em qualquer câmara.

**R18-P. Fim da câmara do chefe.**
- **Fora de Pactos** (Lâmina, Ressonância): o chefe sai da lista no passo `s`
  (Combate R24, sem a marca); no 1º passo vivo depois do hitstop (`s + 37`), a R9
  vê a lista vazia e a câmara fica limpa (R11-P): `camara_limpa(4, chefe)`. A
  Economia já creditou os 6 pelos Chefes (Chefes R9).
- **Com Pactos:** em `s + 37` a câmara vai a `Subjugado` (R8-P). A câmara só fica
  limpa quando os Chefes pedem `limpar_camara_chefe()`, depois de
  `resolver_subjugado(id, escolha)` (Pactuar ou Exorcizar; Chefes R9, Combate
  R24). Nesse passo as Câmaras rodam a R11 (projéteis já removidos, telégrafos já
  cancelados) e emitem `camara_limpa(4, chefe)` **uma vez**. As Câmaras não leem
  a escolha.
- Nos dois casos, a Run recebe `camara_limpa(4, chefe)` com `i = 6` e encerra em
  vitória (Run R4-P); as Portas não concedem nada e não abrem portas (Portas R2
  1b).

**R19-P. Encontro numa câmara comum.** O encontro (Vínculo V4) **não muda** o
tipo da câmara, o layout (R5), a composição das ondas (R6), o sorteio de elite
(R7) nem o consumo dos fluxos `layout`, `ondas`, `elites` e `spawn`. Muda só: a
acuada a mais (R4-P 2b), a `ordem` usada pela IA (R7-P), a distância extra de
nascimento (R7-P) e a espera de `pacto_resolvido` antes das portas (R11-P).

**R20-P. Injeção.** A R16 ganha: a consulta `encontro_na_camara(indice)` e
`pos_acuada` de Vínculo e pactos; `reposicionar_maldicao(pos)` e o raio da
espécie em campo das Maldições; `chefe_subjugado(id)` e `limpar_camara_chefe()`
dos Chefes; `distancia_seguir_px` do `MaldicoesTuning`.

### States and Transitions

| Fase | Entra quando | Sai para |
|---|---|---|
| Entrada | o jogador interage com uma porta (Transição) | Combate (câmara de combate), Limpa (santuário), Combate do chefe (reservado) |
| Combate | a montagem da câmara (R4) | Limpa (última onda sem inimigos e hitstop 0) |
| Limpa | R9 ou o santuário | Saída (interação com a porta) |
| Saída | interação com a porta | Entrada da câmara seguinte |

**Portas:** fechada → aberta (R13). **Ondas:** onda i → onda i + 1 (no mesmo passo em
que a lista fica vazia, com hitstop 0).
**Mundo:** como no Combate. No hitstop e fora de Jogo, as ondas não avançam.

**Emenda Pactos (2026-11-15):**

| Fase | Entra quando | Sai para |
|---|---|---|
| Entrada | o jogador interage com uma porta (Transição) | Combate (câmara de combate e chefe, R14-P), Limpa (santuário) |
| Combate (chefe) | a montagem do índice 6 (R14-P) | Limpa (fora de Pactos: lista vazia e hitstop 0, R18-P) ou `Subjugado` (Pactos: `chefe_subjugado`, R8-P) |
| `Subjugado` | `chefe_subjugado(id)` (só chefe com Pactos) | Limpa (`limpar_camara_chefe()` dos Chefes, R18-P) |
| Limpa (encontro) | R9 na câmara do encontro | portas fechadas até `pacto_resolvido` (Portas 2b), depois Saída |

"Em combate" por fase: Combate **verdadeiro**; Entrada, Limpa, `Subjugado`,
Saída e santuário **falso** (R10, R10-P). A tela de escolha do chefe e a tela de
consentimento são estados fora de Jogo (Vínculo V9): a fase da câmara não muda
enquanto elas estão abertas.

### Interactions with Other Systems

| Sistema | Recebe daqui | Fornece para cá | Dono da interface |
|---|---|---|---|
| IA de inimigos e elites | posição de nascimento, `sortear_elite(p, ja_ha_elite)`, retângulo e vista, obstáculos, "câmara nova" | lista de inimigos, regras de elite | IA (comportamento), este GDD (quando e onde) |
| Combate núcleo | "em combate", "câmara limpa" (hitstop 0), retângulo, obstáculos, pedido de troca | abates, `jogador_morreu`, hitstop | Combate; **por contrato** |
| RNG com seed | fluxos `layout`, `ondas`, `spawn` | números | RNG |
| Conteúdo orientado a dados | — | `WaveRules`, `RoomTuning`, `RegionDef` | Conteúdo |
| Portas e recompensas | `camara_limpa(p, tipo)`, estado e posição das portas, escolha | recompensa da câmara, quantas e quais portas | Portas (recompensas), este GDD (estado) |
| Run e regiões | `camara_limpa`, "câmara pedida", p e `p_max` | sequência da região, próxima câmara | Run; **provisório** |
| Modificadores e atributos | p (fonte `profundidade`) | — | Modificadores |
| Armas das Doutrinas | `p_max(região)` | — | Armas |
| Pipeline visual | p (escurecimento) e a câmara atual | — | Pipeline |
| Cena 3/4 e câmera | tamanho, retângulo e entrada; "câmara nova" | limites do `CameraTuning` | Cena (limites), este GDD (tamanho) |
| Movimento, Selo, Telégrafos | retângulo jogável e obstáculos | — | cada um (consulta) |
| HUD / Feedback de combate / Áudio | `camara_limpa`, portas abertas, onda nova | — | apresentação |
| Vínculo e pactos *(emenda Pactos)* | índice da câmara, lista de pedras, `ordem` de nascimento, `camara_limpa` | `encontro_na_camara(indice)`, `pos_acuada`, `pacto_resolvido` (via Portas) | Vínculo e pactos (V41); este GDD (quando) |
| Maldições *(emenda Pactos)* | `reposicionar_maldicao(pos)` na montagem, "em combate" | raio da espécie em campo, `distancia_seguir_px` | Maldições (R14); este GDD (o ponto, F6) |
| Chefes *(emenda Pactos)* | arena fixa (R14-P), "em combate" (falso em `Subjugado`) | `chefe_subjugado(id)`, `limpar_camara_chefe()`, lacaios na lista | Chefes (desfecho); este GDD (fase e `camara_limpa`) |

## Formulas

> `systems-designer` não consultado nesta seção: modo Lean. Contas do cânone e dos
> GDDs aprovados. `passos(t)` é o F7 do Conteúdo; 60 passos por segundo; unidade
> × 1,5 px.

### F1. Orçamento e número de ondas

The wave_budget formula is defined as:

`orçamento(p, r) = orcamento_base + orcamento_por_prof × p + orcamento_por_regiao × r` ;
`n_ondas(p) = 1` se `p < ondas_limites[0]`, `2` se `p < ondas_limites[1]`, senão `3` ;
`custo_total(p, r) = orçamento × n_ondas`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| p | int | 0–`p_max` (4) | calculated | profundidade (R3) |
| r | int | ≥ 0 | calculated | índice da região (Limiar = 0) |
| orcamento_base, _por_prof, _por_regiao | float | > 0 (3; 0,9; 2) | data file | `WaveRules` |
| ondas_limites | int[2] | crescente (2; 6) | data file | `WaveRules` |

**Output Range:** orçamento ≥ 3; no Limiar, de 3 a 6,6.
**Example (Limiar, r = 0):**

| p | orçamento | ondas | custo total |
|---|---|---|---|
| 0 | 3,0 | 1 | 3,0 |
| 1 | 3,9 | 1 | 3,9 |
| 2 | 4,8 | 2 | 9,6 |
| 3 | 5,7 | 2 | 11,4 |
| 4 | 6,6 | 2 | 13,2 |

No Veio Instável (r = 1) o mesmo p soma 2: 5,0 a 8,6.

### F2. Tamanho da onda

The wave_size formula is defined as:

`n_max = min(max_inimigos_onda, floor(orçamento / custo_min))` ;
`n_min` = nº de inimigos quando a onda gasta o orçamento pelos mais caros primeiro até nada caber (limite inferior, conta gulosa) ;
`custo_min` e `custo_max` são os do pool da região (Eco 1; Fenda 2)

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| custo_min, custo_max | float | > 0 (1; 2) | data file | `EnemyDef` do pool |
| max_inimigos_onda | int | ≥ 1 (9) | data file | `WaveRules` |
| n_min, n_max | int | ≥ 1 | calculated | menor e maior nº de inimigos de uma onda |

**Output Range:** n_max ≤ 9; no Limiar, o pico simultâneo é 6 (p 4, só Ecos).
**Example (Limiar):**

| p | n_min | n_max | Observação |
|---|---|---|---|
| 0 | 2 | 3 | Fenda + Eco, ou 3 Ecos |
| 1 | 2 | 3 | |
| 2 | 2 | 4 | |
| 3 | 3 | 5 | |
| 4 | 3 | 6 | 3 Fendas, ou 6 Ecos |

### F3. Candidatos de nascimento

The spawn_pick formula is defined as:

`C_i = (x_i, y_i)`, i = 1…K, com `x ∈ [raio + m, L − raio − m]` e `y ∈ [raio + m, A − raio − m]` ;
`válido(C) = |C − jogador| > d_min ∧ ∀ pedra: |C − pedra| > r_pedra + raio + f` ;
escolhe o primeiro `C_i` válido; se nenhum, `C_K`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| K | int | ≥ 1 (14) | data file | `spawn_candidatos` (consumo fixo: 2K reais por inimigo) |
| m | float | 111 | data file | `spawn_margem_px` (`WALL` 51 + 40 u = 60) |
| d_min | float | 390 | data file | `spawn_dist_jogador_px` |
| f | float | 12 | data file | `spawn_folga_pedra_px` |
| L, A | float | 1920, 1080 | data file | tamanho da câmara |

**Output Range:** ponto dentro da câmara. A chance de nenhum dos 14 ser válido é ≈ 10⁻⁵ (válido ≥ 55% com o jogador no centro e 4 pedras: 0,45¹⁴ ≈ 1,4·10⁻⁵); então o fallback quase nunca vale.
**Example:** raio do Eco 24: x ∈ [135; 1785], y ∈ [135; 945]; o jogador em (960; 930): um candidato em (960; 700) está a 230 px (< 390) e é recusado.

### F4. Pedras

The obstacle_layout formula is defined as:

`n = obstaculos_min + inteiro em [0, obstaculos_var)` ; `r = 42 + 1,5 × inteiro em [0, 26)` ;
pedra aceita no 1º candidato (de 10) com `|c − c_j| ≥ r + r_j + 105` para todas as pedras já postas ;
`cobertura = Σ π r² / (L × A)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| n | int | 2–4 | RNG `layout` | nº de pedras tentadas |
| r | float | 42–79,5 | RNG `layout` | raio |
| x, y | float | [270; 1650], [255; 765] | RNG `layout` | centro |
| cobertura | float | 0–1 | calculated | fração da câmara ocupada |

**Output Range:** 0 a 4 pedras (uma pode ser omitida); cobertura máxima 4 × π × 79,5² / 2 073 600 = 3,8% (média ≈ 1,7% com 3 pedras de raio médio 61 px). As pedras nunca cobrem a entrada (y máximo da pedra 765 + 79,5 = 844,5 < 903 = 930 − 27).
**Example:** 3 pedras de raio 60, 50 e 70: cobertura (11 310 + 7 854 + 15 394) / 2 073 600 = 1,7%.

### F5. Duração esperada da câmara (teto)

The room_duration formula is defined as:

`t_onda ≈ t_surgir + t_chegada + Vida_onda / DPS_real` ;
`t_câmara ≈ Σ t_onda` ; `t_chegada = (d − alcance) / v_andar`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| t_surgir | float | 0,83 s | data file | 50 passos (IA) |
| t_chegada | float | ≥ 0 | calculated | só o melee; (600 − 78) / 153 = 3,41 s a 600 px |
| Vida_onda | float | > 0 | calculated | soma das Vidas (Armas F3: × (1 + 0,05 p)) |
| DPS_real | float | 66,47 | calculated | Lâmina combinada (Armas F1) |

**Output Range:** ordem de grandeza, jogador perfeito: uma estimativa, não regra.
**Example:** p 0 (3 Ecos, Vida 90): 0,83 + 3,41 + 1,35 = 5,6 s. p 4 (2 ondas de 6 Ecos, Vida 36 cada, 216): 0,83 + 3,41 + 3,25 = 7,5 s por onda, ≈ 15 s. Com a Ressonância (66,96) o resultado é igual.

### F3-P. Candidatos de nascimento no encontro (emenda Pactos, 2026-11-15)

The spawn_pick_encounter formula is defined as:

`válido_P(C) = válido(C) ∧ (¬acuada_presente ∨ |C − pos_acuada| > d_acuada)` ;
escolhe o primeiro `C_i` com `válido_P`; se nenhum, `C_K` (como na F3)

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| válido(C) | bool | — | F3 | regra antiga (jogador e pedras) |
| acuada_presente | bool | — | Vínculo e pactos | câmara do encontro com a acuada no estado `Acuada` |
| pos_acuada | Vector2 | um dos 5 `pontos_acuada` | Vínculo V7 | posição fixa da acuada |
| d_acuada | float | 0–390 (240) | data file | `spawn_dist_acuada_px` (`RoomTuning`); 0 desliga |

**Output Range:** um ponto da câmara. Consumo do fluxo `spawn` igual ao da F3 (2K
reais por inimigo). Com a acuada em (960; 540) e o jogador na entrada, o
disco de 240 px tira ≈ 13% da área de nascimento; a chance de nenhum dos 14
servir fica ≈ 0,55¹⁴ ≈ 2·10⁻⁴.
**Example:** acuada em (960; 540), jogador em (960; 930), Eco (raio 24). C₁ =
(1100; 480): a 471 px do jogador (ok), a 152 px da acuada (< 240): recusado.
C₂ = (1200; 400): a 582 px do jogador e a 278 px da acuada: escolhido.

### F6. Ponto da Maldição na entrada (emenda Pactos, 2026-11-15)

The curse_entry_point formula is defined as:

`pos_entrada_maldicao = (entrada.x ; min(entrada.y + distancia_seguir_px, A − raio_especie))`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| entrada | Vector2 | (960; 930) | `RoomTuning.entrada_px` | ponto do jogador (R4) |
| distancia_seguir_px | float | 75–150 (105) | `MaldicoesTuning` (Maldições F1) | distância de repouso |
| raio_especie | float | 22,5–30 | `CurseDef` (Maldições, catálogo) | raio da Maldição em campo |
| A | float | 1080 | `RoomTuning` | altura da câmara |

**Output Range:** y entre 1005 e `A − raio_especie`; x = 960. Fica dentro do
retângulo jogável e abaixo de toda pedra (y máximo de pedra sorteada 844,5, F4;
pedras fixas do chefe e do santuário em y ≤ 750 e ≤ 495).
**Example:** *Baluarte de Cinza* (raio 30), `distancia_seguir_px` 105: (960;
1035), borda em 1065 ≤ 1080. Com `distancia_seguir_px` 150: min(1080; 1050) =
(960; 1050).

### Faixas do `WaveRules` e do `RoomTuning`

| Campo | Inicial | Faixa | O que quebra fora dela |
|---|---|---|---|
| `orcamento_base` | 3 | 2–5 | < 2: a 1ª onda é 1 Eco; > 5: a 1ª câmara já enche |
| `orcamento_por_prof` | 0,9 | 0,5–1,5 | < 0,5: a curva fica plana; > 1,5: p 4 passa de 9 inimigos |
| `orcamento_por_regiao` | 2 | 1–3 | < 1: a Região 2 não pesa |
| `ondas_limites` | [2; 6] | [1–4; 3–10], crescente | iguais: duas ondas pulam; > 10: nunca 3 ondas |
| `max_inimigos_onda` | 9 | 6–12 | < 6: p 4 do Limiar (6 Ecos) perde inimigos; > 12: multidão ilegível |
| `intervalo_onda_s` | 0 | 0–1 | > 1: a câmara parece parada |
| `camara_largura_px` / `_altura_px` | 1920 / 1080 | 1920–2880 / 1080–1620 | fora: erro WV2 (limites da Cena R6) |
| `obstaculos_min` / `_var` | 2 / 3 | 0–4 / 1–3 | `_min` + `_var` − 1 > 6: câmara entupida |
| `obstaculo_raio_min_px` / `_passos` | 42 / 26 | 30–60 / 10–40 | > 100 de raio: pedra maior que a Onda |
| `folga_obstaculo_px` | 105 | 60–200 | < 60: corredores estreitos que o jogador não passa (raio 27 → 54) |
| `obstaculo_tentativas` | 10 | 5–20 | < 5: pedras omitidas demais |
| `spawn_candidatos` | 14 | 8–24 | < 8: o fallback sai muito |
| `spawn_dist_jogador_px` | 390 | 300–600 | > 540: poucos pontos válidos (WV6) |
| `spawn_margem_px` / `spawn_folga_pedra_px` | 111 / 12 | 60–160 / 0–30 | < 60: nasce na parede |
| `portas_espaco_px` | 450 | 300–600 | < 300: portas se tocam (raio 69); < 282: duas portas ao alcance |
| `portas_y_px` / `porta_raio_px` / `entrada_px` | 177 / 69 / (960; 930) | 150–260 / 50–90 / dentro da câmara, fora das pedras | porta fora da vista ou sob a parede; entrada sobre uma pedra (WV3) |
| `interagir_folga_px` | 15 | 0–45 | > 45: interage de longe |
| `santuario_cura` | 0,4 | 0,2–0,6 | > 0,6: o santuário vira vitória |
| `spawn_dist_acuada_px` *(emenda Pactos)* | 240 **[a confirmar]** | 0–390 | 0: inimigo nasce colado na acuada e a fere antes da leitura; > 390: poucos pontos válidos com o jogador na entrada (WV10) |

Faixas inclusivas, comparadas em passos (F7 do Conteúdo).

### Validação do `WaveRules`, `RoomTuning` e da `RegionDef`

Somam-se às faixas do V2 do Conteúdo. **Erros** vão para a tela de erros do catálogo e a run não começa; **avisos** ficam no registro de validação.

| Regra | Tipo | Condição | Por quê |
|---|---|---|---|
| WV1 | erro | `orcamento_base` ≤ 0, `max_inimigos_onda` < 1, `spawn_candidatos` < 1, `obstaculo_tentativas` < 1, ou `ondas_limites` não crescente | onda vazia ou sorteio sem candidatos |
| WV2 | erro, cruzada com Cena | tamanho de uma câmara fora de 1920×1080–2880×1620 (`CameraTuning`) | câmera sem limites válidos (fecha a Cena OQ9) |
| WV3 | erro | a entrada fora da câmara, ou dentro de uma pedra de layout fixo (santuário e chefe) com a folga do raio do jogador | jogador preso ao nascer |
| WV4 | erro, cruzada com Conteúdo | nenhum inimigo do pool tem custo ≤ `orcamento_base` | onda vazia em p 0 |
| WV5 | aviso | `floor(orçamento_pmax / custo_min)` > `max_inimigos_onda` | o teto de 9 corta o orçamento (hoje 6 ≤ 9) |
| WV6 | aviso | `spawn_dist_jogador_px` > 0,5 × altura da câmara (540) | poucos pontos válidos, fallback frequente |
| WV7 | aviso | cobertura máxima de pedras (4 × π × r_max²) > 15% da câmara | câmara entupida (hoje 3,8%) |
| WV8 | aviso, cruzada com Armas | `ArmasTuning.p_max` ≠ `p_max` derivado da `RegionDef` | validação de armas usa uma profundidade que não existe |
| WV9 | aviso | campo fora da faixa de design | as contas deste GDD deixam de valer |
| WV10 *(emenda Pactos)* | aviso | `spawn_dist_acuada_px` > `spawn_dist_jogador_px` | o fallback (último candidato) passa a sair com frequência no encontro |
| WV11 *(emenda Pactos)* | erro, cruzada com Run | a `RegionDef` tem câmara `chefe` fora do último índice jogável, ou mais de uma | a R18-P encerraria a run no meio |

**Saída do validador:** uma entrada por regra e por objeto; o erro suspende o aviso da mesma regra. WV2–WV5 e WV8 dependem de dados de outros sistemas e rodam na 2ª passada do validador do Conteúdo, como o MV1 do Movimento (decidido 2026-11-13).

## Edge Cases

> `game-designer` e `level-designer` não consultados nesta seção: modo Lean.

**Montar e nascer**

- **Se nenhum dos 14 candidatos de um inimigo for válido:** vale o último (R7); é raro (≈ 10⁻⁵).
- **Se uma pedra não achar candidato em 10 tentativas:** ela é omitida e a câmara tem uma pedra a menos (R5).
- **Se a câmara tiver 0 pedras de layout (as 4 omitidas):** vale; `obstaculos_min` ≥ 2 só limita a tentativa.
- **Se a onda for mais cara que o orçamento restante em qualquer sorteio:** o sorteio para (R6); a onda pode sair com menos custo que o orçamento.
- **Se o pool só tiver inimigos mais caros que o orçamento:** erro WV4; a run não começa.

**Combate e ondas**

- **Se a última morte pedir hitstop:** a avaliação espera o hitstop acabar (R9, Combate R10); a câmara não limpa nem a onda nasce durante o congelamento.
- **Se os inimigos morrerem todos no mesmo passo em que o jogador morre:** o Combate decide a morte; a câmara não é dada como limpa depois de `jogador_morreu` (Combate R14).
- **Se um inimigo estiver surgindo quando os outros morrerem:** a lista não está vazia; a onda não termina até ele surgir e morrer.
- **Se os reforços do chefe nascerem (Vertical Slice):** a lista passa de 9 só se `max_inimigos_onda` permitir; o teto vale também para reforços (IA R13).

**Limpar e portas**

- **Se a câmara limpar com projéteis inimigos em voo:** são removidos no mesmo passo (R11); os do jogador e os Selos seguem.
- **Se o jogador estiver em cima de uma porta quando ela abre:** a interação só vale com o botão (R13); nada acontece sozinho.
- **Se uma pedra ficar junto de uma porta (a pedra mais alta chega a y = 175,5, e a porta fica em y = 177 com raio 69; igual ao cânone):** a pedra não desloca a porta nem bloqueia a interação (que é por distância); o desenho põe as portas acima das pedras.
- **Se o jogador estiver ao alcance de mais de uma porta:** não acontece com o espaçamento de 450 px (o alcance é 111 px; mesmo com 300 px e folga 45, o alcance seria 141 < 150); se um dado futuro permitir, vale a primeira da lista (o cânone usa `find`).
- **Se a Bênção abrir ao limpar:** as portas só abrem depois de ela fechar (R11).
- **Se o jogador interagir durante o hitstop ou a Transição:** o Input ignora a ação (Input R10).

**Santuário e chefe**

- **Se o jogador estiver com a Vida cheia ao entrar no santuário:** a cura vale 0; as portas abrem igual.
- **Se o jogador morrer no santuário (por status de uma câmara anterior):** não há inimigos; o Combate decide (Combate R14).

**Tempo, troca e dados**

- **Se houver hitstop, pausa ou Bênção:** as ondas e a limpeza não avançam (R9).
- **Se a troca de câmara pedir uma região nova:** a LUT e os relógios mudam na metade do wipe (Pipeline R7); o p recomeça em 0.
- **Se a câmara tiver tamanho fora de 1920×1080–2880×1620:** erro WV2; a run não começa.
- **Se o layout, as ondas ou os pontos dependerem de outro estado do jogo:** não podem; só o ponto escolhido depende da posição do jogador (RNG R4b).

**Encontro de pacto (emenda Pactos, 2026-11-15)**

- **Se a acuada e o último inimigo caírem no mesmo passo:** o golpe resolve no item do Combate, antes do item 10; a acuada vai a `Fugiu` e a câmara limpa **sem** espera de `pacto_resolvido` (Vínculo, Edge Cases; Portas 2b não espera).
- **Se a acuada fugir no meio da câmara:** as ondas seguem iguais; a distância extra da R7-P deixa de valer a partir da onda seguinte (`acuada_presente` falso); o consumo do fluxo `spawn` não muda.
- **Se a câmara limpar com a acuada viva e a recompensa for bênção:** a Bênção abre primeiro e para o mundo; depois a câmara fica em Limpa com as portas fechadas até `pacto_resolvido` (R11-P, Portas 2b).
- **Se o jogador morrer na câmara do encontro:** morte vence (Combate R14, Run R5); nada de portas; o estado do encontro é de Vínculo e pactos.
- **Se o jogador tentar sair sem resolver o encontro:** não há porta aberta para interagir (R11-P); o único caminho é Interagir com a acuada.
- **Se a acuada estiver a ≤ 111 px de uma porta:** não acontece; os `pontos_acuada` têm y ≥ 360 e as portas ficam em y = 177 (distância ≥ 183 px). E as portas estão fechadas enquanto ela aguarda.
- **Se o encontro cair numa câmara de 1 onda (p 1) ou 2 ondas (p 2):** a regra é a mesma; a acuada passa as ondas no mesmo lugar.
- **Se a câmara do encontro não sortear nenhuma pedra:** a acuada nasce no 1º ponto, (960; 540).

**Chefe (emenda Pactos, 2026-11-15)**

- **Se o jogador morrer no passo em que o chefe zera a Vida:** morte vence; sem `Subjugado` e sem `camara_limpa` (Chefes, Edge Cases; Run R5-P).
- **Se `jogador_morreu` chegar na fase `Subjugado`:** não deveria (em combate falso, R10-P); se chegar (status residual), vale a morte e a câmara não limpa.
- **Se houver lacaios vivos quando o chefe cai:** os Chefes os removem no passo `s` (Chefes R9); a R9 não espera por eles.
- **Se a Maldição em campo estiver em `Preparo`, `Execução` ou `Saltando` quando a fase vira `Subjugado`:** a lista de atingíveis está vazia (o chefe não é atingível); ela termina sem efeito e passa a `Seguindo` (Maldições, Edge Cases).
- **Se os Chefes pedirem `limpar_camara_chefe()` duas vezes:** a segunda é ignorada; `camara_limpa(4, chefe)` sai uma vez só.
- **Se `limpar_camara_chefe()` chegar fora da fase `Subjugado`:** é ignorado e registrado como erro de integração.
- **Se a run de Pactos chegar ao chefe sem Maldição em campo (todas Exaustas):** a R4-P 1b não reposiciona ninguém; o resto é igual.

**Conflitos com outros GDDs:** nenhum nas partes aprovadas. Divergências do cânone, declaradas: p só de combate (R3), chão = retângulo inteiro (R2) e sorteios com consumo fixo (R5, R7). *(Emenda Pactos: o índice 5 comum depende da OQ 10 da Run, que ainda conflita com Chefes F6 — ver OQ 11.)*

## Dependencies

**Depende de (upstream)**

| Sistema | Tipo | O que vem de lá | Sem ele |
|---|---|---|---|
| IA de inimigos e elites | Forte | `sortear_elite`, regras de elite, alvo de dano por câmara, comportamento de nascimento | os inimigos não agem |
| RNG com seed | Forte | fluxos `layout`, `ondas`, `spawn` (consumo fixo) | a câmara não é reproduzível |
| Conteúdo orientado a dados | Forte | `WaveRules`, `RoomTuning`, `RegionDef` (sequência, pool, custo), conversões F4 e F7 | números no código |
| Cena 3/4 e câmera | Forte | limites de tamanho (`CameraTuning`), vista, "câmara nova" no corte | câmara sem tamanho válido |
| Combate núcleo | Forte, **por contrato** | hitstop (câmara limpa só com 0), Transição (R1), `jogador_morreu`, abates | a câmara limparia durante o congelamento |
| Modificadores e atributos | Suave | fontes `profundidade` e `elite` | sem escala por p |
| Portas e recompensas | Forte, **por contrato** | recompensa da câmara, quantas e quais portas | sem recompensa |
| Run e regiões | Forte, **por contrato** | sequência da região, próxima câmara, região atual | sem fluxo de câmaras |
| Vínculo e pactos *(emenda Pactos)* | Forte, **por contrato** (V41) | `encontro_na_camara(indice)`, nascimento e `pos_acuada` | sem acuada no encontro |
| Chefes *(emenda Pactos)* | Forte, **por contrato** | `chefe_subjugado(id)`, `limpar_camara_chefe()`, lacaios | a câmara do chefe não termina |
| Maldições *(emenda Pactos)* | Suave | `reposicionar_maldicao(pos)`, raio da espécie, `distancia_seguir_px` | a Maldição fica na câmara anterior |

**É dependência de (downstream)**

| Sistema | Tipo | O que recebe |
|---|---|---|
| IA de inimigos e elites | Forte | posição de nascimento, `sortear_elite(p, ja_ha_elite)`, retângulo, obstáculos |
| Combate núcleo | Forte | "em combate", "câmara limpa", retângulo, obstáculos, pedido de troca |
| Movimento, Selo, Telégrafos | Forte | retângulo jogável e obstáculos |
| Portas e recompensas | Forte | `camara_limpa(p, tipo)`, estado e posição das portas |
| Run e regiões | Forte | `camara_limpa`, "câmara pedida", p e `p_max` (Câmaras é a **dona** do `p_max`, R3; o `ArmasTuning.p_max` é só alias, com o aviso WV8) |
| Armas, Modificadores, Pipeline visual | Suave | p e `p_max` (validação, Vida, escurecimento) |
| Cena 3/4 e câmera | Suave | tamanho, retângulo e entrada da câmara |
| HUD / Feedback de combate (VFX) / Áudio | Suave | `camara_limpa`, onda nova, portas abertas |
| Telemetria local | Suave | duração e dano recebido por câmara |
| Vínculo e pactos *(emenda Pactos)* | Forte | índice da câmara, pedras, `ordem` de nascimento, `camara_limpa` (fim da fase Combate do encontro) |
| Chefes *(emenda Pactos)* | Forte | arena fixa (R14-P), fase `Subjugado`, "em combate" falso nela |
| Maldições *(emenda Pactos)* | Forte | ponto de entrada (F6), "em combate", retângulo e obstáculos |
| IA de inimigos e elites *(emenda Pactos)* | Forte | `ordem` de cada inimigo na onda (R7-P), para o alvo padrão do encontro (V44) |

**Bidirecionalidade:**

- *(emenda Pactos, 2026-11-15)* Vínculo e pactos (Dependencies e V41), Chefes
  (R2, R9, Dependencies) e Maldições (R1, R14) já citam Câmaras e ondas. A IA
  precisa citar o campo `ordem` quando aplicar o contrato V44.

- Combate, Cena, RNG, IA, Conteúdo, Movimento, Selo, Telégrafos e Efeitos de status
  já citam as Câmaras. O Armas e o Pipeline ainda dizem que a Run informa p (OQ 3).
- Portas e recompensas, Run e regiões, HUD, Feedback de combate, Pipeline visual
  e Telemetria local já existem; a conferência de que cada um lista "Câmaras e
  ondas" em Dependencies é do `/review-all-gdds`. Só Áudio ainda não existe: ao
  ser escrito, deve listá-las.
- **Índice:** a linha 16 lista IA, RNG, Conteúdo, Cena e Modificadores;
  acrescentar Combate, Portas e recompensas e Run e regiões (por contrato).

## Visual/Audio Requirements

> `art-director`, `level-designer` e `audio-director` não consultados: modo Lean.

- **Arena legível** (P3, Art Bible §1): o chão é o retângulo inteiro da câmara; as
  pedras (ruínas da Beira) se distinguem do chão por valor e silhueta, e **nunca
  cobrem um telégrafo** (contorno em z 5, Cena R4). A sangria da Cena R6 esconde a
  parede.
- **Onda nova:** os inimigos nascem com os fiapos de tinta da IA (50 passos); sem
  flash de tela e sem câmera.
- **Câmara limpa:** a arena "respira": uma queda de intensidade da música e das
  partículas; as portas se acendem com a moldura dourada e as rachaduras magenta
  (ganho e preço juntos, Art Bible §3.3).
- **Portas:** fechadas em tinta apagada, abertas com a moldura; o aviso
  "Interagir" aparece a 111 px (HUD).
- **Santuário:** a pedra central e uma luz quente; sem inimigos.
- **Áudio** (provisório): um grave curto ao nascer uma onda, silêncio e um acorde
  curto ao limpar, um estalo ao abrir a porta.

> 📌 **Asset Spec** — rodar `/asset-spec system:camaras-e-ondas` depois do Art
> Bible: pedras (3 raios), portas (fechada e aberta), arte do chão do Limiar e do
> santuário.

## Game Feel

- **Descer:** cada câmara é um pouco mais cheia que a anterior (3 a 6 inimigos
  por onda, 1 a 2 ondas); o jogador sente o crescimento sem ver um número.
- **Ritmo:** de ~5,6 s (p 0) a ~15 s (p 4) por câmara, no teto de um jogador
  perfeito (F5); o vão entre ondas é 0, então a pressão não cai.
- **Respiro:** a câmara limpa é o único momento sem ameaça antes da próxima.
- **Alvo de playtest** (proposta): a câmara 0 dura entre 10 e 25 s e a 4 entre 25
  e 60 s com o jogador médio (registro [M]).

## UI Requirements

- Sem tela própria. O HUD mostra o aviso "Interagir" perto da porta (a 111 px) e,
  na opção de acessibilidade, o número da câmara.
- A Bênção e as recompensas são telas de outros GDDs (Tela de bênção, Portas).
- Acessibilidade: as portas se diferenciam por moldura e posição, não só pela cor.

## Cross-References

| Documento | Seção | Uso neste GDD |
|---|---|---|
| `design/gdd/ia-de-inimigos-e-elites.md` | R3, R10, R11, R12, F1, F2 | surgimento, `sortear_elite`, vista, alvo de dano |
| `design/gdd/combate-nucleo.md` | R1 (Transição), R10, R13.1, R14 | hitstop, "em combate", `jogador_morreu` |
| `design/gdd/rng-com-seed.md` | R4b, tabela de finalidades | fluxos `layout`, `ondas`, `spawn` |
| `design/gdd/conteudo-orientado-a-dados.md` | R1, R8, V2, F4, F7 | `WaveRules`, `RegionDef`, conversões |
| `design/gdd/cena-3-4-e-camera.md` | R6, R10, OQ9 | tamanho, limites, corte |
| `design/gdd/telegrafos.md` | R2, F3 | parede e obstáculos |
| `design/gdd/selo-e-fluxo.md` | R2, F6 | retângulo jogável |
| `design/gdd/movimento-e-esquiva.md` | R10 | colisão com pedras e retângulo |
| `design/gdd/armas-das-doutrinas.md` | R7, OQ | `p_max` |
| `design/gdd/pipeline-visual.md` | R3 | escurecimento por p |
| `design/gdd/gdd-cross-review-2026-11-10.md` | C-W4, D-W14 | dono de p, alvo de dano |
| Khaeros `packages/action-core/src/engine.ts` | `:246–416`, `:467–533`, `:1290–1305` | câmara, ondas, portas |
| `design/gdd/vinculo-e-pactos.md` *(emenda Pactos)* | V4, V7, V8, V9, V12, V41, VP3, Edge Cases | encontro, acuada, alvo por `ordem`, espera das portas |
| `design/gdd/chefes.md` *(emenda Pactos)* | R2, R8, R9, F6, CH6 | arena, lacaios, `Subjugado`, desfecho |
| `design/gdd/combate-nucleo.md` *(emenda Pactos)* | R13.1, R14, R19, R21, R24 | em combate, varredura do chefe, Maldição fora da lista |
| `design/gdd/maldicoes.md` *(emenda Pactos)* | R1, R14, F1, Edge Cases | não conta na limpeza, reposicionamento |
| `design/gdd/run-e-regioes.md` *(emenda Pactos)* | R3-P, R4-P, R5-P, F1-P, OQ 10 | 7 câmaras, índice 5 comum, vitória no chefe |
| Khaeros `packages/combat-rules/src/arenaContent.ts` | `:86–116` | região, pool, custos |

## Acceptance Criteria

> `qa-lead` não consultado (modo Lean); a revisão única do GDD cobre regras e
> critérios.

**Fixture CO** (provisório: dublês de IA, Combate, RNG, Portas, Run e Cena):
`WaveRules` e `RoomTuning` de fábrica, `RegionDef` do Limiar, jogador em
(960; 930) com raio 27 px, passos contados a partir de 0; os fluxos dão os
valores que o critério diz; comparações de distância com tolerância de 1e-9.

**Profundidade e montagem**

- **AC-CO-01 [L] R3 — profundidade.** No Limiar (combate, combate, combate, santuário, combate, combate, chefe): as câmaras de combate têm p = 0, 1, 2, 3, 4; santuário e chefe não têm p; `p_max` = 4.
- **AC-CO-02 [L] R4 — montagem.** Na metade do wipe, depois do teleporte: o jogador fica em (960; 930), a fase é Combate e a 1ª onda nasce no mesmo quadro.
- **AC-CO-03 [L] R2/Movimento R10 — chão.** Câmara 1920×1080: o jogador é preso a x ∈ [27; 1893] e y ∈ [27; 1053].

**Layout**

- **AC-CO-04 [L] R5/F4 — pedras.** Com `layout` dublê dando n = 1 (3 pedras): o fluxo consome 1 + 3 × 30 = 91 números; cada pedra fica no 1º candidato com folga ≥ 105 px (centros a r₁ + r₂ + 104,9: recusado; + 105: aceito).
- **AC-CO-05 [L] R5 — omitir.** Se nenhum dos 10 candidatos de uma pedra respeita a folga, ela é omitida (a câmara tem 2 pedras) e o consumo continua 91.
- **AC-CO-06 [L] R5/F4 — faixas.** Raio ∈ [42; 79,5] em passos de 1,5; x ∈ [270; 1650]; y ∈ [255; 765]; nenhuma pedra cobre a entrada (844,5 < 903).

**Ondas**

- **AC-CO-07 [L] R6/F1 — orçamento.** p 0 a 4 no Limiar: 3; 3,9; 4,8; 5,7; 6,6, com 1, 1, 2, 2, 2 ondas; na região 1 (índice 1), p 0: 5,0.
- **AC-CO-08 [L] R6/F2 — composição.** p 0 (orçamento 3), sorteio dublê [Fenda, Eco]: onda de 2 inimigos, custo 3; [Eco, Eco, Eco]: 3 inimigos; nenhuma onda passa do orçamento; com orçamento 20, a onda para em 9 inimigos.
- **AC-CO-09 [L] R7/F3 — spawn.** 14 candidatos por inimigo, 28 reais, **sempre**; o 1º candidato a 390,0 px do jogador é recusado (a regra é "mais de 390"), o 2º a 390,1 px é escolhido; sem nenhum válido, vale o 14º.
- **AC-CO-10 [L] R7 — pedras e elite.** Candidato a r_pedra + raio + 12 de uma pedra: recusado; a r_pedra + raio + 12,1: aceito. A IA recebe `sortear_elite(p, ja_ha_elite)` por inimigo, na ordem da onda, com `ja_ha_elite` falso até o 1º elite e verdadeiro depois.
- **AC-CO-11 [L] R5/R7 — consumo fixo.** O jogador em outra posição ou com outra Vida não muda o estado dos fluxos `layout`, `ondas` e `spawn` depois da câmara (RNG R4b).

**Combate e limpar**

- **AC-CO-12 [L] R9/R10 — vão entre ondas.** Lista vazia, hitstop 0 e uma onda seguinte: ela nasce no mesmo passo; "em combate" fica verdadeiro, inclusive com os inimigos surgindo.
- **AC-CO-13 [L] R9 — hitstop.** No passo do último abate (hitstop 4 pedido, contador > 0): o item 10 é pulado; os passos congelados seguintes nem rodam a R1; no 1º passo vivo (contador 0), a limpeza é avaliada.
- **AC-CO-14 [L] R9/R11 — limpar.** Última onda sem inimigos e hitstop 0: a fase vira Limpa no mesmo passo, os projéteis inimigos são removidos e `camara_limpa(p, tipo)` sai uma vez.
- **AC-CO-15 [L] R10 — "em combate".** Falso na Entrada, na fase Limpa, na Saída e no santuário; verdadeiro na fase Combate.
- **AC-CO-16 [L] R9/Combate R14 — morte.** O jogador morre no passo em que o último inimigo cai: a câmara não é dada como limpa.

**Santuário, portas e chefe**

- **AC-CO-17 [L] R12 — santuário.** Vida 70/100: cura 30 (limitada a 100); Vida 40/100: cura 40; a fase vai a Limpa, as portas abrem, sem ondas; a pedra tem raio 63 px em (960; 495).
- **AC-CO-18 [L] R13 — posições.** Portas nascem fechadas; abertas, 2 portas em x = 735 e 1185, 3 portas em 510, 960 e 1410, todas a y = 177; a porta forçada única (`santuario`, `chefe` ou `ultima`) em x = 960. Depois da câmara de índice 4 há exatamente 1 porta `ultima`, sem ícone de recompensa; depois da de índice 5, nenhuma (Run `fim_da_run`).
- **AC-CO-19 [L] R13 — interação.** Interagir a 111 px: escolhe a porta; a 112 px: nada; com o espaçamento de fábrica nunca há duas ao alcance; durante hitstop ou Transição, nada.
- **AC-CO-20 [L] R13/R4 — troca.** A interação pede a troca (Transição) e a próxima câmara, da `RegionDef`, é montada na metade do wipe.
- **AC-CO-21 [L] R14 — chefe.** Layout fixo de 4 pedras de 51 px em (390; 300), (1530; 300), (390; 750), (1530; 750) e uma onda só com o chefe em (960; 285) (reservado).

**Dados e validação**

- **AC-CO-22 [I] R2/WV2 — tamanho.** Câmara 1920×1080 e 2880×1620: aceitas; 1900×1080 e 2881×1620: erro WV2.
- **AC-CO-23 [I] R15 — erros.** `orcamento_base` ≤ 0, `max_inimigos_onda` < 1, `spawn_candidatos` < 1, `ondas_limites` não crescente, entrada dentro de uma pedra fixa ou pool sem inimigo ≤ `orcamento_base`: erros WV1, WV3, WV4.
- **AC-CO-24 [I] R15 — avisos de fábrica.** O catálogo de fábrica não gera nenhum aviso WV5 a WV9; com `max_inimigos_onda` 5: WV5; `spawn_dist_jogador_px` 600: WV6; `obstaculo_raio_min_px` 150 (cobertura máxima 21,7%): WV7; `ArmasTuning.p_max` 5: WV8; `orcamento_base` 6: WV9.

**Captura e playtest**

- **AC-CO-25 [V] Visual/Audio — arena.** Captura de uma câmara com 4 pedras e 6 inimigos: as pedras se distinguem do chão, não cobrem o contorno dos telégrafos, e a sangria esconde a parede, em tons de cinza e nos 3 simuladores de daltonismo.
- **AC-CO-26 [V] Visual/Audio — portas.** Captura da câmara limpa com 2 e 3 portas abertas: a moldura dourada e as rachaduras magenta se leem por forma e valor.
- **AC-CO-27 [M] Game Feel — duração.** Registro com testador, build e contagem: a câmara 0 dura entre 10 e 25 s e a 4 entre 25 e 60 s com o jogador médio (proposta).

**Emenda Pactos (2026-11-15)** — Fixture CO-P: a Fixture CO mais dublês de
Vínculo e pactos, Maldições e Chefes; `MaldicoesTuning.distancia_seguir_px` 105;
`spawn_dist_acuada_px` 240. Os AC-CO-18 e AC-CO-21 antigos valem só onde não
contrariam os abaixo (portas do Limiar e chefe reservado foram substituídos).

- **AC-CO-28 [L] R1-P/R3-P — sequência com chefe.** GIVEN a `RegionDef` do Limiar, WHEN as 7 câmaras são listadas, THEN os índices 0–6 são combate, combate, combate, santuário, combate, combate, chefe; a câmara 6 usa p = 4 e `p_max` continua 4.
- **AC-CO-29 [L] R14-P — chefe sem sorteio.** GIVEN a montagem do índice 6, WHEN a câmara monta, THEN há 4 pedras de 51 px em (390; 300), (1530; 300), (390; 750), (1530; 750), o chefe nasce em (960; 285) em `Surgindo`, e os fluxos `layout`, `ondas`, `spawn` e `elites` têm o mesmo estado de antes da montagem (0 reais consumidos); `sortear_elite` não é chamado.
- **AC-CO-30 [L] R18-P — chefe fora de Pactos.** GIVEN Lâmina e o golpe final no passo 640, WHEN o hitstop de 36 passos acaba, THEN no passo 677 a fase vira Limpa e `camara_limpa(4, chefe)` sai uma vez; nenhuma porta abre.
- **AC-CO-31 [L] R8-P/R10-P — `Subjugado`.** GIVEN Pactos e o golpe final no passo 640, WHEN chega `chefe_subjugado` no passo 677, THEN a fase é `Subjugado`, "em combate" é falso, a R9 não roda (o chefe com Vida 0 segue na lista) e `camara_limpa` não sai.
- **AC-CO-32 [L] R18-P — fim por escolha.** GIVEN a fase `Subjugado`, WHEN os Chefes pedem `limpar_camara_chefe()` depois de `resolver_subjugado(id, pactuar)` (ou `exorcizar`), THEN a fase vira Limpa e `camara_limpa(4, chefe)` sai uma vez no mesmo passo; um segundo pedido é ignorado.
- **AC-CO-33 [L] R18-P — pedido fora de hora.** GIVEN a câmara do chefe na fase Combate, WHEN chega `limpar_camara_chefe()`, THEN nada muda e um erro de integração é registrado.
- **AC-CO-34 [L] R9-P — quem conta.** GIVEN a última onda morta, a Maldição em campo viva e a acuada viva, WHEN o hitstop é 0, THEN a câmara fica limpa no mesmo passo.
- **AC-CO-35 [L] R4-P 1b/F6 — Maldição na entrada.** GIVEN a *Baluarte de Cinza* (raio 30) em campo a (400; 300) na câmara anterior, WHEN a câmara nova monta, THEN o jogador fica em (960; 930) e as Câmaras pedem `reposicionar_maldicao((960; 1035))`; com `distancia_seguir_px` 150, o ponto é (960; 1050). Sem Maldição em campo, o pedido não sai.
- **AC-CO-36 [L] R4-P 2b — acuada.** GIVEN `encontro_na_camara(1)` = `espreitador_da_fenda`, WHEN o índice 1 monta, THEN a consulta acontece depois do layout e da composição e antes da 1ª onda, Vínculo e pactos recebe a lista de pedras, e o estado dos fluxos `layout`, `ondas`, `elites` e `spawn` depois da câmara é igual ao da mesma seed sem encontro **se** nenhum candidato escolhido mudou de índice (o consumo é o mesmo).
- **AC-CO-37 [L] R7-P — `ordem`.** GIVEN uma onda de 3 Ecos na câmara do encontro, WHEN nascem, THEN a IA recebe `ordem` 0, 1 e 2 na ordem da composição; fora do encontro a IA recebe os mesmos índices.
- **AC-CO-38 [L] R7-P/F3-P — distância da acuada.** GIVEN a acuada em (960; 540) no estado `Acuada`, jogador em (960; 930) e um Eco, WHEN o 1º candidato é (1100; 480) e o 2º (1200; 400), THEN o 1º é recusado e o 2º escolhido; um candidato a exatos 240,0 px da acuada é recusado e um a 240,1 px é aceito; com a acuada em `Fugiu`, o (1100; 480) é aceito.
- **AC-CO-39 [L] R11-P — encontro segura as portas.** GIVEN a câmara do encontro limpa com a acuada em `Aguardando` e recompensa `fragmentos`, WHEN `camara_limpa` sai, THEN a fase é Limpa, "em combate" é falso, as portas continuam fechadas até as Portas pedirem a abertura (depois de `pacto_resolvido`).
- **AC-CO-40 [L] R13-P — portas do Limiar.** GIVEN o Limiar, WHEN as câmaras 4, 5 e 6 ficam limpas, THEN depois do índice 4 abrem 2 ou 3 portas livres (x = 735/1185 ou 510/960/1410), depois do índice 5 abre 1 porta `chefe` em x = 960, e depois do índice 6 nenhuma; a porta `ultima` não aparece.
- **AC-CO-41 [L] R19-P — encontro não mexe no resto.** GIVEN a mesma seed com e sem encontro no índice 2, WHEN a câmara monta, THEN o layout, a composição das ondas e as decisões de elite são idênticas.
- **AC-CO-42 [L] WV10/WV11 — validação.** `spawn_dist_acuada_px` 400: aviso WV10; uma `RegionDef` com `chefe` no índice 4: erro WV11 e a run não começa; o catálogo de fábrica não gera WV10 nem WV11.
- **AC-CO-43 [M] Game Feel — encontro legível.** Registro com testador, build e contagem: em ≥ 80% das câmaras de encontro, nenhum inimigo fere a acuada nos primeiros 2 s depois de nascer (proposta; alavanca `spawn_dist_acuada_px`).

## Open Questions

| # | Pergunta | Dono | Resolver até |
|---|---|---|---|
| 1 | O chão é o retângulo inteiro da câmara (o cânone recuava 51 px de parede): conferir a leitura e as distâncias de nascimento | game-designer | primeiro playtest |
| 2 | Selo F6 (margem 30 px do chão = 81 px do cânone, `WALL + 20 u`), Telégrafos e Movimento R10 aceitam o chão como a câmara inteira. O fixture AC-45b do Movimento usa (51; 51)–(1869; 1029) como override de paridade e não muda; manter a margem de 30 px do Selo | dono do Selo e do Movimento | `/design-review` |
| 3 | Armas (`p_max`, OQ) e Pipeline (R3: "informada pela Run") dizem que p vem de outro dono: atualizar para as Câmaras | dono de Armas e Pipeline | próxima edição de cada um |
| 4 | `intervalo_onda_s` = 0 (cânone): a próxima onda nasce na hora; testar um respiro | game-designer | primeiro playtest |
| 5 | Altar de Provação (orçamento × 1,35, elite 0,45, até 3 por onda): fora do MVP | Portas / Alpha | GDD de Portas |
| 6 | Posição do santuário na sequência do Limiar (4ª câmara) e cura de 40% | Run e regiões | GDD de Run |
| 7 | Layouts desenhados à mão e câmaras maiores que 1920×1080 | level-designer | Alpha |
| 8 | ~~Ordem entre `camara_limpa`, a Bênção e a abertura das portas~~ **Resolvida:** Portas R2 (`camara_limpa` → Bênção → portas) | Portas e recompensas | — |
| 9 | Índice: linha 16 com Combate, Portas e Run em Depends On | usuário / producer | próxima edição do índice |
| 10 | O alvo de dano recebido por câmara (IA R12, 0,25 da Vida) e `invuln_atingido_s` (Combate, 40 passos) só se verificam em jogo; a alavanca é a composição por orçamento (F1) (D-W14) | Telemetria / `/balance-check` | primeiro playtest |
| 11 *(emenda Pactos)* | ~~Índice 5 comum com recompensa (Run R3-P) vs. Chefes F6 ("até 7 de portas"): a R11-P e a R13-P seguem a Run; se o usuário escolher "índice 5 sem recompensa", a porta depois do 4 volta a ser forçada (sem ícone)~~ **Resolvida:** Chefes F6 foi emendado com o índice 5 recompensado (10/25/31); a R11-P e a R13-P ficam como estão | usuário; Run; Chefes | ~~antes de aprovar a emenda~~ — |
| 12 *(emenda Pactos)* | `spawn_dist_acuada_px` 240 e a regra em si (R7-P; aprovada em 2026-11-16, validar sensação no 1º playtest) | usuário / level-designer | primeiro playtest do encontro |
| 13 *(emenda Pactos)* | ~~Maldição "atrás" = abaixo do jogador na entrada (F6)~~ **Resolvida (2026-11-16):** sim, abaixo do jogador na entrada | — | — |
| 14 *(emenda Pactos)* | ~~Nome da chamada `limpar_camara_chefe()` e quem emite `camara_limpa(4, chefe)` (Chefes R9 diz "as Câmaras emitem" num ramo e "emite" no outro): contrato pedido a Chefes~~ **Resolvida:** Chefes R9b fecha o contrato: só as Câmaras emitem `camara_limpa(4, chefe)`; com Pactos, os Chefes chamam `limpar_camara_chefe()` depois de `resolver_subjugado(id, escolha)`; fora de Pactos, sai pela lista vazia | Chefes | ~~próxima edição de Chefes~~ — |
| 15 *(emenda Pactos)* | Campo `ordem` no nascimento: contrato pedido à IA (V44) | IA de inimigos e elites | emenda da IA |
