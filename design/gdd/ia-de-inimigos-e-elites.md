# IA de inimigos e elites

> **Status**: Approved (emenda Pactos aprovada pelo usuário em 2026-11-16) — antes: Approved (2026-11-11; revisão única por subagente, 2 bloqueantes corrigidos sem re-review; sem entrada no review log)
> **Author**: usuário + Claude (design-system, modo Lean)
> **Last Updated**: 2026-11-15 (emenda Pactos, encontro de pacto: alvo `acuada` por `ordem` — R22, R15, R16, R19, F6, States, Edge Cases, Dependencies, AC-IA-50–57, OQ15; contrato V44 de `vinculo-e-pactos.md` e R7-P de `camaras-e-ondas.md`); 2026-11-15 (emenda Pactos: alvo por inimigo, `atrair`, `imobilizado`, consulta de alvos, Maldição no espaço, `chefe` ativo — R16–R21, F6; alinhado depois a Chefes R3 "só o alvo" e Maldições R17/F4b: atração sem renovação, respiro, `atrair(id, passos, passos_respiro)`)
> **Last Verified**: 2026-11-11
> **Implements Pillar**: P3 *Reflexo que se lê* (inimigos previsíveis); P2 *A Beira cobra*

## Summary

**IA de inimigos e elites** define como cada inimigo se move, ataca e se recupera
(`melee`, `ranged`, `charger`; `chefe` reservado) em cinco fases, sempre
passando por um telégrafo com a mira travada, e quais inimigos nascem elite (a
partir da profundidade 3, Vida × 2,4, sem cambalear nem quebrar, no máximo um por
onda). Existe para o jogador enfrentar inimigos legíveis que pressionam sem
trapacear, e para declarar o alvo de dano recebido que as Câmaras usam.

**Emenda Pactos (2026-11-15):** cada inimigo tem um **alvo** (o jogador por
padrão; a Maldição em campo enquanto atraído), a IA atende os pedidos
`atrair` e `imobilizar` das Maldições, publica a consulta de alvos que Input,
Movimento e Maldições usam, e o comportamento `chefe` deixa de ser reservado
(Soberano do Limiar, `chefes.md`). Regras R16–R21 e F6.
**(emenda Pactos, 2026-11-15; encontro de pacto)** Na câmara do encontro, os
inimigos de `ordem` par miram a Maldição **acuada** até ela sair; os de ordem
ímpar miram o jogador (R22; Vínculo V8, V44).

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

> **Emenda Pactos (2026-11-15):** o "jogador" das regras abaixo passa a ser o
> **alvo** do inimigo (R16). Sem Pactos na run, o alvo é sempre o jogador e
> nada muda. O `chefe` é ativo no MVP (R21); onde o texto antigo diz
> "reservado", vale a R21.

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
| `chefe` | anda até 300 px do jogador (reservado) — **emenda Pactos:** ver R21 (Chefes R4) | `timer` ≤ 0 |

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

**Emenda Pactos (2026-11-15) à R15:** recebe também a Maldição em campo (existe
ou não, posição, raio, Vida > 0, `fator_andar_atraido`), a chamada
`ferir_maldicao` do Combate (emenda) e o módulo de Chefes (R21).
**(emenda Pactos, 2026-11-15; encontro de pacto)** Recebe também: a consulta da
acuada do Vínculo (existe, estado, posição, raio), o campo `ordem` de cada
inimigo no nascimento (Câmaras R7-P) e a chamada `ferir_acuada` do Combate (R25).

**R16. Alvo por inimigo** (emenda Pactos, 2026-11-15; Maldições R7).

- Cada inimigo tem um **alvo**: o **jogador**, por padrão.
- Enquanto `restante_atracao > 0` **e** há Maldição em campo, o alvo é a
  **Maldição em campo**.
- No passo da IA (R2), o inimigo lê o alvo e depois `restante_atracao` desce 1.
  Uma atração de N passos aplicada antes do item 7 vale por N passos vivos,
  contando o passo em que foi aplicada.
- **Fim na hora:** se a Maldição sai de campo (Troca, Exaustão ou troca de
  câmara; Maldições R7, R9, R14), a IA zera `restante_atracao` de todos os
  inimigos no mesmo passo. A Maldição que entra não herda a atração.
- **Respiro** (emenda Pactos, 2026-11-15; Maldições R17.3, F4b): toda vez que
  a atração de um inimigo acaba, por qualquer motivo (fim do tempo, saída de
  campo, `TransicaoFase` do chefe), a IA põe `restante_respiro =
  passos_respiro` do pedido que a criou (30, Maldições F4b) no mesmo passo.
  Enquanto `restante_respiro > 0`, o inimigo ~~mira o jogador~~ **mira o seu alvo padrão**
  (emenda Pactos, 2026-11-15; encontro de pacto: o jogador, ou a acuada pela R22;
  fora do encontro é sempre o jogador, sem mudança) e recusa `atrair`
  (R17). Desce 1 por passo vivo no passo da IA, como a atração. Na troca de
  câmara o inimigo some e o respiro some com ele.
- **O alvo substitui "o jogador"** nas R4, R6, R7 e R11 e na R4 do Chefes: a
  direção do andar, as distâncias de engajamento, recuo e contorno, o alcance
  do `melee` (alcance + raio do alvo, F6), a mira travada e o teste de acerto
  (Telégrafos R2a e R6a, emenda). A visibilidade da R11 continua sendo a do
  próprio inimigo na vista.
- **Alvo travado:** no passo em que a IA chama `iniciar_telegrafo`, o alvo
  daquele passo fica travado no telégrafo, junto com a mira (Telégrafos R2a).
  O preparo e a execução em curso testam o alvo travado, mesmo que o alvo mude
  depois.
- **Alvo travado ausente:** se o alvo travado era a Maldição e ela saiu de
  campo depois da trava (mesmo que volte) ou tem Vida ≤ 0, o golpe **falha no
  vazio** e não fere o jogador (Maldições Edge Cases). O inimigo segue o ciclo
  normal.
- **Um golpe de comum ou elite só testa o seu alvo travado** (Maldições R7).
  ~~Exceção: os padrões de área do chefe testam o jogador e a Maldição (Chefes
  R3; Telégrafos R5a).~~ **Sem exceção** (emenda Pactos, 2026-11-15; Chefes R3
  emendado): todo golpe do chefe também testa só o alvo travado no início do
  Preparo — o setor, o contato do avanço, o pulso do anel, **cada um dos 12
  projéteis radiais** e o círculo. Deslocamentos não são golpes: o puxão da
  *Convergência* e o pulso repulsor da `TransicaoFase` movem o jogador **e** a
  Maldição em campo (Chefes R3, R5.4, R7).
- **Andar atraído:** enquanto atraído, a velocidade de andar (R9) é
  multiplicada por `fator_andar_atraido`, lido da Maldição em campo a cada
  passo (1,0 por padrão; 0,80 com a passiva *Presença do Limiar* do Soberano,
  Maldições §Catálogo). Não vale para o avanço do `charger` nem para o avanço do
  chefe. **[a confirmar]** (mecanismo: leitura da Maldição em campo, não valor
  guardado por atração).

**R17. Pedido `atrair(id, passos, passos_respiro)`** (emenda Pactos,
2026-11-15; assinatura e regra conforme Maldições R17 e R21).

- Quem chama: Maldições (Chamado R13.4, *Queda de Pilar*, *Pulso de
  Soberania*).
- **Aceita** se o inimigo existe, é atingível (Combate R9: fora do surgimento,
  Vida > 0), há Maldição em campo **e o inimigo está livre**:
  `restante_atracao = 0` e `restante_respiro = 0`. Vale para comuns, elites,
  chefe e lacaios.
- **Efeito:** `restante_atracao = passos` e o inimigo guarda `passos_respiro`
  para o fim desta atração (R16, Respiro).
- ~~`restante_atracao = max(restante_atracao, passos)`~~ — **substituído:**
  sem renovação. Um pedido a um inimigo já atraído ou em respiro é **recusado**:
  não soma, não estende, não encurta (Maldições R17.2, F4b).
- **Recusa:** nada muda e devolve falso.
- `passos` e `passos_respiro` chegam convertidos (`passos(duracao_atracao_s)`
  = 90 e `passos(respiro_atracao_s)` = 30, Maldições F4b; o *Pulso de
  Soberania* aplica 60). A IA não tem número próprio de atração nem de respiro.
  ~~180~~ (valor antigo, Maldições F4).
- Chefe em `TransicaoFase`: o 1º passo da transição zera a atração (Chefes R7)
  e abre o respiro (R16). Um pedido depois do respiro vale normalmente.

**R18. Estado `imobilizado` e pedido `imobilizar(id, passos)`** (emenda Pactos,
2026-11-15; Maldições R13.3).

- **Aceita só em inimigo comum** atingível, incluindo lacaios invocados.
  **Elite e chefe são imunes** (armadura, Combate R8.7; Chefes R1): devolve
  falso e nada muda. Eles são imunes à imobilização, **não** à atração (R17).
- **Efeito:** `restante_imob = max(restante_imob, passos)`. Enquanto
  `restante_imob > 0`, o inimigo está imobilizado. Desce 1 por passo vivo no
  passo da IA, como a atração.
- **Imobilizado não anda** (aproximação, recuo, contorno, aproximação do
  `charger`, andar da recuperação) e **não começa preparo**.
- O `timer` continua descendo. Quando a imobilização acaba e as condições da R4
  valem, o preparo começa no mesmo passo.
- **Preparo ou execução em curso continua:** o telégrafo dispara no tempo, o
  projétil sai e o avanço do `charger` anda os 26 passos.
- Empurrão (Combate) e separação (R9) ainda movem o corpo: imobilizado é "não
  anda", não "preso".
- "Quebrou!" e cambaleio funcionam igual. A recuperação corre parada.
- Não é status do GDD de Efeitos de status (sem ícone de status). A IA expõe
  `esta_imobilizado(id)` e `esta_atraido(id)` para a sinergia das Maldições
  (Maldições F5). A "marca" que *Paredes de Sombra* põe em elites e chefes é
  estado das Maldições, não da IA.

**R19. Consulta de alvos** (emenda Pactos, 2026-11-15; responde ao Input OQ 5 e
ao Movimento OQ 4).

- `atingiveis()`: lista só de leitura dos inimigos atingíveis (Combate R9), em
  **ordem estável de spawn**, cada um com `id`, posição, raio, `elite` e
  `chefe`.
- **`id`:** inteiro crescente na ordem de spawn, único na run e nunca reusado.
  Assim "menor id" e "primeiro da lista" são o mesmo critério. **[a confirmar]**
- `mais_perto(ponto, raio_max)`: o inimigo de menor (distância, `id`) entre os
  atingíveis com distância ≤ `raio_max` (inclusivo). Sem nenhum, devolve vazio.
- **Usos:** Maldições R4.2 e F1 (ponto = jogador, `raio_max` = `alcance_fio_px`,
  480 px); Input F4 (ponto = jogador, R = 1350 px, ignora d = 0, empate pelo
  primeiro da lista: o mesmo critério); Corte do Movimento (usa o raio).
- O chefe `Subjugado` e os inimigos em surgimento não estão na lista.
- (emenda Pactos, 2026-11-15; encontro de pacto) A **acuada não está na lista**:
  não é inimiga (Vínculo V7). Nem a mira do gamepad, nem o fio das Maldições, nem
  o Corte a encontram.

**R20. A Maldição e o espaço** (emenda Pactos, 2026-11-15; Maldições R1).

- A Maldição **não** está na lista de inimigos. Ela não entra na separação da
  R9, não empurra nem é empurrada por inimigos e não bloqueia o andar deles. Um
  inimigo atraído para no alcance dela pela R4, não por colisão.
- Ela **é contida como os inimigos:** a função de conter da R9 (obstáculos e
  retângulo da câmara, com o raio do corpo) é a mesma que Maldições aplica ao
  corpo dela a cada passo vivo, inclusive no salto (para no obstáculo,
  Maldições R13.1). A IA expõe a função; quem move a Maldição é Maldições.

**R21. Chefe deixa de ser reservado** (emenda Pactos, 2026-11-15; Chefes R1–R12).
Substitui o "reservado" da R1, R4 e R13.

- `chefe` é comportamento ativo no MVP: o *Soberano do Limiar*, na 7ª câmara do
  Limiar (Chefes R2).
- **A IA dá:** as cinco fases e o campo `padrao` (R1), o alvo (R16), `atrair`
  (R17), colisão e separação (R9), o passo e a parada (R2) e "morto não age".
- **Chefes acrescenta** `TransicaoFase`, `HitstopFinal`, `Subjugado` e `Morto`, e
  define distâncias, padrões, recargas e fúria (Chefes R4–R7). A linha `chefe`
  da R4 passa a ser a Chefes R4: 180 px no Padrão 0; 300 px nos demais, com
  preparo em qualquer distância quando `timer` ≤ 0.
- **Pedido `subjugar(id)`** (emenda Pactos, 2026-11-15; Combate R14,
  `combate-nucleo.md` l. 725): o Combate o chama no passo `s` em que marca o
  chefe Subjugado. A IA põe Vida 0, para a IA do chefe (sem decisão, sem
  movimento próprio) e desliga a colisão ofensiva. O chefe **fica na lista** e
  não é atingível (Combate R9) até a escolha de Chefes R9.
- **Esperas fixas:** o chefe não consome o fluxo `ia` (Chefes R2, R6). A R3 e a
  R7 não valem para ele.
- **Sem elite e sem bônus de profundidade** (R10, F2; Chefes R1). A câmara do
  chefe não tem onda: `sortear_elite` não é chamado e o fluxo `elites` não é
  consumido (Chefes AC-CH-01). Isto prevalece sobre o Edge Case antigo "se a
  onda tiver um chefe".
- Armadura (R8), imune à imobilização (R18), atraível (R17).
- **Lacaios** (`invocado_pelo_chefe`): IA `melee` normal (R3–R9), sempre comuns,
  sem consumir `elites` nem `spawn`, imobilizáveis e atraíveis. Chefes os cria e
  remove (Chefes R8).
- A F5 desta IA continua sendo só de comuns e elites. O dano do chefe tem a F5 e
  o CH5 do Chefes. O IV5 não vale para o chefe (o CH7 cobre).
- A separação da R9 vale para o chefe e os lacaios com a regra do cânone
  (metade da sobreposição para cada). **[a confirmar]**

**R22. Alvo `acuada` no encontro de pacto** (emenda Pactos, 2026-11-15;
`vinculo-e-pactos.md` V7, V8, V12, contrato V44; `camaras-e-ondas.md` R7-P).

- **A acuada é um alvo possível.** Ela fica parada no seu ponto fixo
  (`pos_acuada`, Vínculo V7) e não ataca. A IA a lê pela consulta do Vínculo:
  existe, estado, posição e raio (o raio da espécie: 24 / 22,5 / 30).
- **Campo `ordem`:** cada inimigo guarda no nascimento o índice `ordem` na onda
  (0, 1, 2…, a ordem da composição), que as Câmaras passam junto com a posição
  (Câmaras R7-P). Quem nasce sem `ordem` (lacaios do chefe) usa `ordem = −1`.
  Fora do encontro, `ordem` não muda nada.
- **Alvo padrão:** `acuada` se a acuada existe no estado `Acuada` **e** `ordem` é
  par (0, 2, 4…); senão `jogador`. A IA avalia isso a cada leitura do alvo, então
  a mudança vale para todos de uma vez: quando a acuada sai de `Acuada` (pacto
  ou falha; `Aguardando`, V9, ou `Fugiu`, V12), todo inimigo volta a ter o
  jogador como alvo padrão. Quem já agiu neste passo lê o jogador no seguinte;
  quem age depois da falha, no mesmo item 7, já lê o jogador (Vínculo V12.2).
  Ela não volta a `Acuada`.
- **Prioridade (convive com a R16 e a R17):** atraído → **Maldição em campo**;
  senão, inclusive no **respiro** → **alvo padrão**. A atração vale para os
  inimigos de ordem par também: o Chamado puxa da acuada para a Maldição em
  campo, e ao acabar a atração o inimigo volta à acuada (Vínculo V8; AC-VP-10).
  A R17 não muda: `atrair` não olha o alvo padrão.
- **Alvo travado (R16):** o alvo do passo do `iniciar_telegrafo` pode ser a
  acuada e fica travado. O golpe travado nela **só testa a acuada** e chama só
  `ferir_acuada` (Combate R25); não fere o jogador nem a Maldição em campo, e
  vice-versa (Vínculo V8). **Alvo travado ausente:** se a acuada saiu de `Acuada`
  depois da trava, o golpe falha no vazio, como com a Maldição ausente.
- **Projétil:** o `ranged` mirado na acuada dispara com `alvo = acuada` (Combate
  R7, R22).
- **O alvo substitui "o jogador"** como na R16: direção do andar, engajamento,
  recuo e contorno do `ranged`, distâncias do `charger`, alcance do `melee`
  (`alcance_px + raio_acuada`, F6) e mira travada. A visibilidade da R11 segue a
  do próprio inimigo na vista.
- **Espaço:** a acuada **não entra na separação** da R9, não empurra, não é
  empurrada e não bloqueia o andar; um inimigo para no alcance dela pela R4, não
  por colisão. Como não se move, a função de conter não é aplicada a ela
  (Vínculo V7). Ela **não está** na lista de atingíveis do jogador (R19).
- **Sem efeito fora do encontro:** sem acuada, o alvo padrão é sempre o jogador e
  a IA é a mesma de antes. A câmara do chefe nunca tem acuada (o encontro cai
  nos índices 1 e 2; Vínculo, Edge Cases), e por isso o chefe e os lacaios
  sempre têm o jogador como alvo padrão.

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

**Emenda Pactos (2026-11-15):**

| Sobreposto | Entra quando | Sai quando | Efeito |
|---|---|---|---|
| Atraído | `atrair` aceito (R17) | `restante_atracao` = 0, ou a Maldição sai de campo (R16) | alvo = Maldição em campo; andar × `fator_andar_atraido` |
| Respiro (emenda Pactos, 2026-11-15) | fim de Atraído, por qualquer motivo (R16) | `restante_respiro` = 0 | alvo = jogador; `atrair` recusado (R17) |
| Imobilizado (só comuns) | `imobilizar` aceito (R18) | `restante_imob` = 0 | não anda, não começa preparo; preparo e execução em curso continuam |
| Mirando a acuada (emenda Pactos, 2026-11-15; R22) | nasce com `ordem` par e a acuada em `Acuada` | a acuada sai de `Acuada` (pacto ou falha); fica suspenso enquanto Atraído | alvo padrão = acuada, inclusive no respiro |

O chefe tem as fases extras do Chefes (`TransicaoFase`, `HitstopFinal`,
`Subjugado`, `Morto`; R21).

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
| **Maldições** (emenda Pactos) | consulta de alvos (R19), alvo de cada inimigo (R16), `atrair` (R17), `imobilizar`, `esta_imobilizado`, `esta_atraido` (R18), função de conter (R20) | Maldição em campo (posição, raio, Vida, `fator_andar_atraido`), pedidos de atração e imobilização, saída de campo | Maldições (pedido), este GDD (efeito) |
| **Chefes** (MVP, emenda Pactos) | fases, `padrao`, alvo, `atrair`, colisão, IA dos lacaios (R21) | padrões, `TransicaoFase`, `Subjugado`, criação e remoção de lacaios | Chefes (padrões), este GDD (máquina) |
| Input e controle / Movimento (emenda Pactos) | consulta de alvos (R19) | — | este GDD (resposta) |
| **Vínculo e pactos** (emenda Pactos, 2026-11-15; contrato V44) | alvo `acuada` de cada inimigo (R22) | a acuada (existe, estado, posição, raio) | Vínculo (acuada), este GDD (alvo) |
| Câmaras e ondas, `ordem` (emenda Pactos, 2026-11-15) | — | `ordem` de cada inimigo no nascimento (Câmaras R7-P) | Câmaras |

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

### F6. Alvo, alcance e andar pelo alvo (emenda Pactos, 2026-11-15)

The target_reach formula is defined as:

`alvo = Maldição em campo` se `restante_atracao > 0` e há Maldição em campo ; senão `jogador` (R16) ;
(emenda Pactos, 2026-11-15; encontro de pacto) o "senão" passa a ser `alvo_padrao = acuada` se a acuada está em `Acuada` e `ordem mod 2 = 0` (com `ordem ≥ 0`), senão `jogador` (R22) ;
`d_alvo = |pos_alvo − pos_inimigo|` ; `alcance_total = alcance_px + raio_alvo_px` (`melee`, R4) ;
`v_andar = velocidade × f_selo × f_cambaleio × (atraído ? fator_andar_atraido : 1) × (imobilizado ? 0 : 1)` ;
~~`restante_atracao' = max(restante_atracao, passos_pedido)`~~ → `restante_atracao' = passos_pedido` só se `restante_atracao = 0` e `restante_respiro = 0`, senão recusa (R17, emenda Pactos 2026-11-15) ; ao zerar a atração, `restante_respiro' = passos_respiro` (R16) ; `restante_imob' = max(restante_imob, passos_pedido)` (R18, só comuns)

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| raio_alvo_px | float | 22,5–30 (Maldições) ou 27 (jogador) | data file | raio do jogador (Movimento) ou da espécie em campo (Maldições §Catálogo: 24 / 22,5 / 30 / 28,5); (emenda Pactos, 2026-11-15) ou da espécie acuada (24 / 22,5 / 30, Vínculo V7) |
| ordem | int | −1 ou 0–8 | Câmaras R7-P | índice do inimigo na onda; −1 sem ordem (lacaios) (emenda Pactos, 2026-11-15) |
| alcance_px | float | > 0 (Eco 51) | data file | `EnemyDef.alcance` × 1,5 (Conteúdo F4) |
| fator_andar_atraido | float | 0,80–1,0 | data file | da Maldição em campo (1,0; *Presença do Limiar* 0,80) |
| passos_pedido | int | 1–300 | calculated | do pedido (atração ~~180~~ 90, *Pulso de Soberania* 60, imobilização 90; Maldições F4, F4b) |
| passos_respiro | int | 15–60 (MVP 30) | calculated | do pedido de atração (`passos(respiro_atracao_s)`, Maldições F4b) |

**Output Range:** `alcance_total` entre 73,5 e 81 px no Eco; `v_andar ≥ 0`. Sem Pactos, `alvo = jogador` e F6 = R4 de antes (78 px).
**Example:** Eco atraído pelo *Vulto Mudo* (24 px): `alcance_total` = 51 + 24 = 75 px; pelo *Baluarte* (30 px): 81 px; pelo *Soberano* (28,5 px): 79,5 px; jogador: 78 px. Eco atraído pelo *Soberano*: 153 × 0,80 = 122,4 px/s (2,04 px/passo); no Selo, 61,2 px/s. Fenda atraída: o avanço segue 7,56 px/passo.

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

**Alvo, atração e imobilização** (emenda Pactos, 2026-11-15)

- **Se a run não tem Pactos:** `restante_atracao` e `restante_imob` ficam em 0 e o comportamento é idêntico ao aprovado (regressão: AC-IA-01 a 30 continuam valendo).
- **Se a Maldição sai de campo com um golpe travado nela em preparo ou execução:** o telégrafo dispara normal, o golpe falha no vazio e o jogador não é ferido; a próxima mira já é no jogador (R16).
- **Se a atração começa no meio de um preparo travado no jogador:** o golpe segue no jogador; o inimigo passa a andar para a Maldição a partir do passo seguinte ao fim da execução (R16).
- **Se a Maldição está `Saltando`:** ela segue sendo o alvo, na posição atual do salto; um golpe que a encontra no salto não fere (Maldições Edge Cases) e não passa para o jogador.
- **Se, no mesmo item 7, um inimigo deixa a Maldição com Vida ≤ 0 e outro dispara depois travado nela:** o segundo golpe não fere ninguém (R16, alvo travado ausente).
- **Se a Troca põe outra Maldição em campo:** a nova não herda a atração; um golpe travado na anterior não fere a nova, mesmo que ela esteja dentro da forma.
- **Se um `ranged` atraído está fora da vista:** avança em direção à Maldição até entrar na vista (R11 com o alvo).
- **Se um `charger` atraído já está a menos de 456 px da Maldição:** não anda; espera o `timer` e a distância ≤ 570 px dela.
- **Se a distância do inimigo ao alvo Maldição é 0:** mesma regra do jogador (última direção no andar; mira (1; 0) no telégrafo, Telégrafos AC-TG-25).
- ~~**Se chegam dois pedidos de atração ou de imobilização:** vale o maior restante (R17, R18).~~ (substituído para a atração, emenda Pactos 2026-11-15)
- **Se chegam dois pedidos de imobilização:** vale o maior restante (R18).
- **Se chega um pedido de atração a um inimigo atraído ou em respiro:** recusado, devolve falso, nada muda; no mesmo passo, o primeiro pedido aceito vence e os seguintes são recusados (R17; Maldições R17.2). O dano e o empurrão da mesma fonte valem normalmente.
- **Se o Chamado cai a cada recarga (120 passos) sobre o mesmo inimigo:** 90 passos atraído, 30 em respiro mirando o jogador; nunca mais de 90 seguidos (Maldições F4b).
- **Se a Maldição sai de campo com inimigos atraídos:** zera a atração e abre o respiro de 30 no mesmo passo; a Maldição que entra não os atrai nesses 30 passos (Maldições Edge Cases).
- **Se um golpe do chefe está travado no jogador e a Maldição está dentro da forma (setor, anel, círculo, trajeto do avanço ou de um projétil radial):** só o jogador é testado; a Maldição não é ferida. O inverso vale com o chefe atraído (R16; Chefes R3).
- **Se o puxão da *Convergência* ou o pulso repulsor da `TransicaoFase` resolve:** move o jogador e a Maldição em campo, qualquer que seja o alvo; o dano do círculo segue só no alvo travado (Chefes R3).
- **Se o pedido chega num inimigo em surgimento ou morto:** é recusado (R17, R18).
- **Se `imobilizar` é pedido para elite ou chefe:** recusado, devolve falso; o mesmo golpe ainda pode atraí-los (R18).
- **Se um `ranged` imobilizado está fora da vista:** fica parado até a imobilização acabar (no máximo `passos_pedido`) e depois segue a R11.
- **Se o comum imobilizado toma "Quebrou!":** vai para a recuperação de 24 passos e não anda nela enquanto imobilizado.
- **Se o chefe atraído entra em `TransicaoFase`:** o pulso zera a atração, abre o respiro de 30 passos e o chefe volta a mirar o jogador (Chefes R7; Maldições Edge Cases).
- **Se a câmara troca:** os inimigos somem e nenhuma atração ou imobilização passa adiante (Maldições R14).
- **Se a Maldição encosta num inimigo:** nada acontece; não há separação entre ela e os inimigos (R20).

**Acuada do encontro de pacto** (emenda Pactos, 2026-11-15; R22; Vínculo V7–V12)

- **Se a onda tem 1 inimigo só:** ordem 0 → mira a acuada; o jogador não é alvo naquela onda (Vínculo, Edge Cases).
- **Se a acuada cai (`Fugiu`) com golpes travados nela em preparo ou execução:** os telégrafos disparam normal, os golpes falham no vazio e ninguém é ferido; a próxima mira é no jogador (R22, alvo travado ausente).
- **Se a acuada cai no item 7 antes de outros inimigos agirem:** os que agem depois, no mesmo passo, já leem o jogador; os que já agiram leem no passo seguinte (R22).
- **Se um inimigo de ordem par é atraído pelo Chamado:** mira a Maldição em campo pela atração; no respiro e depois, volta à acuada se ela ainda está em `Acuada`, senão ao jogador (R16, R22).
- **Se um inimigo atraído pela Maldição em campo passa pela acuada:** o golpe travado na Maldição não fere a acuada (R22; Vínculo, Edge Cases).
- **Se o jogador está dentro da forma de um golpe travado na acuada:** não é ferido; o golpe só testa a acuada (Vínculo AC-VP-09).
- **Se um `ranged` de ordem par está a menos de 345 px da acuada:** recua dela, mesmo com o jogador longe (R4 com o alvo acuada); se está fora da vista, avança até entrar na vista (R11).
- **Se inimigos se acumulam sobre a acuada:** separam-se entre si pela R9, mas não dela; o corpo dela pode ficar sob os inimigos (R22, Espaço).
- **Se a câmara limpa com a acuada viva:** não há inimigo para mirar; ela vai a `Aguardando` e a R22 deixa de valer (Vínculo V9).
- **Se a acuada nasce sobre uma pedra (último ponto, Vínculo Edge Cases):** nada muda para a IA; os inimigos contornam a pedra pela R9 e param no alcance da acuada pela R4. Um `melee` que não alcança por causa da pedra fica encostado nela até o alvo mudar.
- **Se um inimigo da câmara do encontro nasce sem `ordem` (não deveria):** `ordem = −1`, alvo padrão jogador.

**Chefe ativo** (emenda Pactos)

- **Na câmara do chefe:** não há onda nem sorteio de elite; o fluxo `elites` não é consumido (R21, Chefes AC-CH-01). O Edge "se a onda tiver um chefe" fica só para uma onda futura que inclua chefe (fora do MVP).
- **Lacaios invocados:** seguem esta IA como comuns; o chefe os cria sem RNG (Chefes R8).

**Conflitos com outros GDDs:** nenhum nas partes aprovadas. Divergências do cânone, declaradas: consumo fixo do RNG no sorteio de elite (RNG R4b), o ataque do `ranged` só na vista (R11) e o avanço da Fenda sem lentidão (que é o cânone).

**Emenda Pactos (2026-11-15):** (1) o Edge antigo "se a onda tiver um chefe, o
sorteio consome o real" diverge de Chefes AC-CH-01 (câmara do chefe sem consumo
de `elites`); vale Chefes (R21). (2) Maldições R7 diz que todo golpe de inimigo
só testa o seu alvo; Chefes R3 abre exceção para os padrões de área do chefe.
Esta IA segue Chefes para o chefe e Maldições para comuns e elites.
**Resolvido (emenda Pactos, 2026-11-15):** o Chefes R3 emendado tirou a
exceção; todo golpe, de qualquer inimigo, só testa o alvo travado (R16). (3) O
`max` antigo da R17 foi trocado pela regra sem renovação e com respiro de
Maldições R17 e F4b.

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
| **Maldições** (emenda Pactos) | Forte, **por contrato** | Maldição em campo (posição, raio, Vida, `fator_andar_atraido`), pedidos `atrair` e `imobilizar`, aviso de saída de campo | sem alvo alternativo: todo inimigo mira o jogador |
| **Chefes** (emenda Pactos) | Forte, **por contrato** | padrões, distâncias, `TransicaoFase`, `Subjugado`, lacaios (R21) | o comportamento `chefe` não tem padrões |
| **Vínculo e pactos** (emenda Pactos, 2026-11-15; contrato V44) | Suave, **por contrato** | a acuada (existe, estado, posição, raio) | sem acuada: o alvo padrão é sempre o jogador |
| Câmaras e ondas, `ordem` (emenda Pactos, 2026-11-15) | Suave, **por contrato** | `ordem` de cada inimigo no nascimento (R7-P) | `ordem = −1`: ninguém mira a acuada |

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
| **Maldições** (emenda Pactos; substitui "Criatura do pacto (Alpha)") | Forte | consulta de alvos (R19), alvo por inimigo (R16), `atrair` (R17), `imobilizado` (R18), função de conter (R20) |
| **Chefes** (MVP, emenda Pactos) | Forte | fases, `padrao`, alvo, `atrair`, colisão e separação, IA dos lacaios (R21) |
| Movimento e esquiva (emenda Pactos) | Suave, **por contrato** | consulta de alvos com raio (R19; Movimento OQ 4) |
| **Vínculo e pactos** (emenda Pactos, 2026-11-15) | Forte, **por contrato** (V44) | alvo `acuada` por inimigo (R22); sem ele, ninguém ataca a acuada |

**Bidirecionalidade:**

- **(emenda Pactos, 2026-11-15; encontro de pacto)** `vinculo-e-pactos.md`
  (Dependencies, l. 850) já lista esta IA (`Forte, por contrato (V44)`: alvo
  padrão `acuada`); `camaras-e-ondas.md` R7-P já passa `ordem`. Este GDD lista os
  dois.

- **Emenda Pactos (2026-11-15):** Maldições já lista esta IA (`Forte`, por
  contrato) e Chefes também (`Forte`). Input lista a consulta de alvos (R19
  responde à OQ 5 dele).

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
- **Emenda Pactos (2026-11-15):** inimigo atraído mostra o traço vertical em Osso
  acima da cabeça (Maldições UI Requirements); imobilizado mostra a pose parada
  com fiapos de sombra nos pés (VFX do Feedback de combate, sem ícone de
  status). Os dois leem `esta_atraido` e `esta_imobilizado` (R18).

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
| `design/gdd/maldicoes.md` (emenda Pactos) | R1, R4, R7, R9, R13, R14, F1, F4, Catálogo, Edge Cases | alvo atraído, `atrair`, `imobilizado`, consulta de alvos, conter |
| `design/gdd/chefes.md` (emenda Pactos) | R1–R8, AC-CH-01 | `chefe` ativo, alvo do chefe, lacaios, sem RNG |
| `design/gdd/input-e-controle.md` (emenda Pactos) | F4, OQ 5 | consulta de alvos |
| `design/gdd/vinculo-e-pactos.md` (emenda Pactos) | V7, V8, V9, V12, V44, Edge Cases, AC-VP-09–11 | acuada como alvo, alvo por `ordem`, saída da acuada |
| `design/gdd/camaras-e-ondas.md` (emenda Pactos) | R4 passo 2b, R7-P, F3-P | `ordem` no nascimento, `pos_acuada` |
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

**Emenda Pactos (2026-11-15)**

Fixture extra: dublê de Maldição em campo (`vulto_mudo`, raio 24 px, Vida 110,
`fator_andar_atraido` 1,0) e dublê de `ferir_maldicao`. Pedidos aplicados no
passo `s`, antes do item 7.

- **AC-IA-31 [L] R16 — alvo padrão e atração.** Jogador em (0; 0), Maldição em (600; 0), Eco em (300; 300) em aproximação. Sem atração, o Eco anda para (0; 0). Após `atrair(eco, 90, 30)` no passo `s`, nos passos `s` a `s + 89` anda para a Maldição; de `s + 90` a `s + 119` (respiro) anda para o jogador e `esta_atraido` é falso. (Emenda Pactos 2026-11-15: antes `atrair(eco, 180)`.)
- **AC-IA-32 [L] R16/F6 — alcance pelo alvo.** Eco atraído pelo *Vulto Mudo* (24 px) com `timer` ≤ 0: a 75 px dele entra em preparo; a 76 px não entra. Atraído por uma Maldição de 30 px: entra a 81 px; a 82 px não.
- **AC-IA-33 [L] R16 — saída de campo.** Dois inimigos com `restante_atracao` 120. A Maldição sai de campo (Troca ou Exaustão) no passo `s`: no mesmo passo os dois ficam com 0 e `restante_respiro` 30 e, no passo da IA, o alvo é o jogador. A Maldição que entra não está atraindo ninguém, e um `atrair` dela nesses dois inimigos é recusado até o passo `s + 29`; em `s + 30` é aceito.
- **AC-IA-34 [L] R16 — alvo travado ausente.** Eco atraído inicia o preparo travado na Maldição; no passo 10 do preparo a Maldição sai de campo; o jogador está dentro do setor no disparo: `ferir_jogador` não é chamado, `ferir_maldicao` não é chamado, o Eco fica parado 10 passos e entra em recuperação.
- **AC-IA-35 [L] R16 — atração no meio do preparo.** Eco em preparo travado no jogador recebe `atrair(eco, 90, 30)` no passo 5 do preparo: no disparo, o teste é contra o jogador (`ferir_jogador(9)` se ele estiver no setor); na recuperação seguinte, anda para a Maldição.
- **AC-IA-36 [L] R17 — pedido de atração (emenda Pactos, 2026-11-15: sem renovação).** Eco livre: `atrair(id, 90, 30)` devolve verdadeiro e `restante_atracao` = 90. Com `restante_atracao` 40: `atrair(id, 60, 30)` e `atrair(id, 90, 30)` devolvem falso e o valor segue 40. Quando a atração zera, `restante_respiro` = 30; durante os 30 passos todo `atrair` devolve falso; no passo seguinte ao fim do respiro, é aceito. Elite aceita (devolve verdadeiro). Inimigo em surgimento ou com Vida ≤ 0: recusa (falso, nada muda). Sem Maldição em campo: recusa.
- **AC-IA-37 [L] R18 — imobilização.** Eco comum em aproximação a 50 px do jogador, `timer` 0, recebe `imobilizar(eco, 90)` no passo `s`: nos passos `s` a `s + 89` a posição não muda (sem empurrão) e não há preparo; o `timer` continua descendo; no passo `s + 90` chama `iniciar_telegrafo` uma vez.
- **AC-IA-38 [L] R18 — em curso continua.** Eco no passo 10 do preparo recebe `imobilizar(eco, 90)`: o telégrafo dispara no passo 26 do preparo. Fenda no 5º passo do avanço recebe `imobilizar`: completa os 26 passos a 7,56 px/passo. Na recuperação seguinte, nenhum dos dois anda enquanto imobilizado.
- **AC-IA-39 [L] R18 — imunes.** `imobilizar` em elite e em chefe devolve falso e `esta_imobilizado` segue falso; `atrair` no mesmo elite e no chefe devolve verdadeiro.
- **AC-IA-40 [L] R18 — empurrão e separação.** Eco imobilizado recebe empurrão de 360 px/s: a posição muda pelo empurrão; dois Ecos imobilizados a 20 px se separam 14 px cada (R9).
- **AC-IA-41 [L] R19 — consulta.** Lista com ids 1 (atingível), 2 (em surgimento) e 3 (atingível): `atingiveis()` devolve [1, 3] com posição e raio. `mais_perto(jogador, 480)` com os ids 1 e 3 a 200 px: devolve 1; com o 1 a 481 px e o 3 a 480 px: devolve 3 (inclusivo); com os dois além de 480: vazio. Ids nunca se repetem na run.
- **AC-IA-42 [L] R20 — Maldição fora da separação.** Maldição (24 px) sobreposta 20 px a um Eco: nenhum dos dois é empurrado pela separação. Maldição com o centro dentro de um obstáculo: a função de conter a devolve ao limite no mesmo passo.
- **AC-IA-43 [L] R16 — ranged e charger atraídos.** Anomalia atraída com a Maldição a 300 px recua 1,95 px/passo para longe dela (o jogador a 800 px não importa). Fenda atraída com a Maldição a 400 px não anda; com `timer` ≤ 0 e a Maldição a 570 px, entra em preparo.
- **AC-IA-44 [L] R16/F6 — andar atraído.** Eco atraído com `fator_andar_atraido` 0,80 (*Soberano* em campo): 2,04 px/passo; no Selo, 1,02 px/passo; a Fenda atraída avança 7,56 px/passo.
- **AC-IA-45 [L] R21 — chefe ativo.** `EnemyDef` com `comportamento = chefe` carrega sem erro IV4; o chefe nunca é elite, tem Vida 700 sem `depth_hp_bonus`, e montar a câmara do chefe até o 1º padrão não consome os fluxos `ia` nem `elites` (estado dos fluxos igual antes e depois).
- **AC-IA-46 [L] R21 — lacaios.** Um `eco_perdido` com `invocado_pelo_chefe` segue a R3–R9 como comum, aceita `imobilizar` e `atrair` e não consome os fluxos `elites` nem `spawn`.
- **AC-IA-47 [L] Edge — sem Pactos.** Run sem Maldição em campo: `atrair` e `imobilizar` nunca são chamados e os AC-IA-01 a 30 passam sem mudança.
- **AC-IA-48 [L] R16 — chefe testa só o alvo travado (emenda Pactos, 2026-11-15; Chefes R3).** Chefe não atraído trava o Padrão 2 no jogador; jogador e Maldição estão dentro de 210 px no disparo e um projétil radial passa sobre a Maldição depois: `ferir_jogador(15)` é chamado uma vez pelo anel e `ferir_maldicao` nunca é chamado, nem pelo anel nem por nenhum dos 12 projéteis. Com o chefe atraído no início do Preparo, o inverso: só `ferir_maldicao`.
- **AC-IA-49 [L] R16/R17 — respiro após `TransicaoFase`.** Chefe atraído com `restante_atracao` 50 entra em `TransicaoFase` no passo `s`: no mesmo passo `restante_atracao` = 0 e `restante_respiro` = 30; `atrair(chefe, 90, 30)` em `s + 10` devolve falso; em `s + 30`, verdadeiro.

**Emenda Pactos — encontro de pacto (2026-11-15)**

Fixture extra: dublê do Vínculo com a acuada `espreitador_da_fenda` em (960; 540), raio 22,5 px, estado `Acuada` (o teste pode passá-la a `Fugiu` ou `Aguardando`); jogador em (960; 930); dublê de `ferir_acuada`.

- **AC-IA-50 [L] R22 — alvo por `ordem`.** Onda de 3 Ecos com `ordem` 0, 1 e 2: o alvo dos de ordem 0 e 2 é a acuada e o de ordem 1 é o jogador. Sem acuada (dublê sem encontro), os três miram o jogador. Um lacaio com `ordem = −1` mira o jogador.
- **AC-IA-51 [L] R22 — golpe só na acuada.** Eco de ordem 0 trava o preparo na acuada; no disparo, o jogador e a acuada estão dentro do setor: `ferir_acuada(9, M)` é chamado uma vez, `ferir_jogador` e `ferir_maldicao` nunca. O inverso com o Eco de ordem 1: só `ferir_jogador`.
- **AC-IA-52 [L] R22/F6 — alcance pela acuada.** Eco de ordem 0 com `timer` ≤ 0: a 73,5 px do centro da acuada (51 + 22,5) entra em preparo; a 74 px não.
- **AC-IA-53 [L] R22 — saída da acuada.** Três Ecos (ordem 0, 1, 2) na lista nessa ordem. No item 7 do passo `s`, o Eco 0 derruba a acuada (o dublê vai a `Fugiu`): no mesmo passo o Eco 2 lê o jogador como alvo; a partir de `s + 1`, os três miram o jogador. Com a acuada em `Aguardando`, idem.
- **AC-IA-54 [L] R22 — travado ausente.** Eco de ordem 0 no passo 10 do preparo travado na acuada; ela vai a `Fugiu`; o jogador está no setor no disparo: `ferir_acuada` e `ferir_jogador` não são chamados e o Eco segue para a recuperação.
- **AC-IA-55 [L] R16/R22 — atração e respiro.** Eco de ordem 0 recebe `atrair(eco, 90, 30)` no passo `s`: de `s` a `s + 89` anda para a Maldição em campo; de `s + 90` a `s + 119` (respiro) anda para a acuada, não para o jogador; com a acuada em `Fugiu` no respiro, anda para o jogador. Eco de ordem 1 no mesmo caso: respiro para o jogador.
- **AC-IA-56 [L] R22/R19 — espaço e lista.** Eco sobreposto 20 px à acuada: a separação não move nenhum dos dois. `atingiveis()` e `mais_perto(jogador, 1350)` nunca devolvem a acuada.
- **AC-IA-57 [L] R22 — projétil e ranged.** Anomalia de ordem 0 a 300 px da acuada e 800 px do jogador recua da acuada a 1,95 px/passo; ao disparar, `disparar_projetil` sai com `alvo = acuada`.

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
| 11 | **(emenda Pactos)** A OQ 4 está respondida pelo GDD de Chefes (R21). | — | resolvida |
| 12 | **(emenda Pactos)** ~~Atração renovada por `max` (R17)~~ — atração resolvida por Maldições R17/F4b (sem renovação, respiro de 30). Fica aberto só para a imobilização (`max`, R18): conferir se uma renovação curta deveria somar | game-designer | primeiro playtest de Pactos |
| 13 | **(emenda Pactos)** Separação entre o chefe (45 px) e os lacaios na regra do cânone (metade para cada): o chefe é empurrado por Ecos. Manter ou tornar o chefe imóvel na separação? | game-designer + Chefes | primeiro playtest do chefe |
| 14 | **(emenda Pactos)** Co-op: o alvo hoje é "jogador ou Maldição em campo"; com 1–4 jogadores, o alvo por inimigo precisa de uma lista de candidatos (co-op-ganchos) | ai-programmer | pós-MVP |
| 15 | **(emenda Pactos, 2026-11-15; encontro de pacto)** Confirmar: (a) no respiro o inimigo volta ao **alvo padrão** (a acuada, nos de ordem par), não ao jogador — segue Vínculo V8 e AC-VP-10 e muda a R16 só dentro do encontro **[a confirmar]**; (b) o `ranged` recua e contorna em relação à acuada como faria com o jogador **[a confirmar]**; (c) contrato pedido a Telégrafos: o alvo travado pode ser `acuada` no teste de acerto (R2a, R6a); (d) leitura visual de "este inimigo mira a acuada" (Vínculo VP) | usuário + game-designer + Telégrafos | aprovação da emenda / primeiro playtest do encontro |
