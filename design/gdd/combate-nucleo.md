# Combate núcleo

> **Status**: Approved (2026-11-11, Efeitos de status: o número de dano de status é o agregado da R8 deles; 2026-11-10, Selo e Fluxo: a Transição também apaga os Selos (R1, item 3); o dano do Selo usa o caminho silencioso da R8 e sai da lista de origens do `acerto` na R17, decisão do usuário; 2026-11-10, correções de contrato do `/review-all-gdds` 3ª passada, mantido Approved por decisão do usuário: C-B2, durações visuais no `CombatTuning` e nos eventos; S-B1, estado Transição no orquestrador; S-B2, câmara limpa só com hitstop 0; S-W5, hitstop parado fora de Jogo. 2026-11-10: exemplos do Pulso alinhados ao empurrão 540 do GDD de Armas, com aval do usuário, sem mudar regra; `/design-review` 2026-11-09, lean, por subagentes: NEEDS REVISION — 3 bloqueantes nas regras e 8 nos critérios, revisados; re-review 2026-11-09: regras APPROVED, critérios com 2 correções de uma linha aplicadas, e as recomendadas das duas re-reviews aplicadas na mesma data; aprovado pelo usuário)
> **Author**: usuário + Claude (design-system, modo Lean)
> **Last Updated**: 2026-11-10 (cross-review: R1, R10, R15, R17, V1, V6, V10–V12, CV22, AC-10, AC-78, AC-95–AC-97, OQ11)
> **Last Verified**: 2026-11-09
> **Implements Pillar**: P3 *Reflexo que se lê* (hitstop, buffer, cancelamento; baseline §55)

> **Nota (2026-11-11, HUD):** pendente: o fio de Vida do inimigo e o prompt de interação são do HUD (UI Requirements); o fio lê a queda da Vida do inimigo, não o `acerto`.

> **Nota (2026-11-11, Feedback de combate):** pendente: V7 cita a fonte única da soma de 300 ms e do teto de 6 (Feedback R6/F1/F2) e a exceção do dourado; V14: o Feedback envia um impulso por passo; A1 provisória; o crítico é a flag `enesimo_acerto` (acerto marcado).

> **Nota (2026-11-11, Telemetria local):** pendente: `jogador_atingido` com `atacante_tipo` e `ataque_id` e a causa no `jogador_morreu` (a Telemetria grava `causa: null` sem eles).

> **Nota (2026-11-11, revisão cruzada):** pendente: áudio do acerto marcado soma ao do peso (AC-80b, Feedback R3); duração da inversão no passo da recusa (R17/AC-77/AC-97 × Feedback R12) e relógio de `area` (V1/V3). (Resolvidos em 2026-11-12: V14 remetente único, linhas de `jogador_morreu` e `acerto_de_arma` na R17, Dependencies.)

## Summary

**Combate núcleo** resolve o golpe do jogador e o impacto, a cada passo vivo.
Define as quatro formas de golpe (arco, círculo, projétil e investida), com
combo, recarga e recuperação; aplica o dano com o multiplicador do Modificadores,
o empurrão que decai, o cambaleio, o "Quebrou!" (um golpe pesado interrompe a
preparação do inimigo), o impacto na parede e a varredura de mortes; e resolve o
dano no jogador (0,67 s de invulnerabilidade, escudo, refletir e recusa de
morte). É o dono do hitstop (3 passos no leve, 6 no pesado, vale o maior) e da
ordem do passo. Na Lâmina, o combo tira 14, 14 e 25,2, e o terceiro golpe é
pesado. A promessa do P3: cada golpe pesa, e cada erro é do jogador.

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `Movimento e esquiva, Modificadores e atributos, Conteúdo orientado a dados, Input e controle; IA de inimigos e elites e Câmaras e ondas (por contrato)`

## Overview

**Combate núcleo** resolve tudo o que acontece quando um golpe sai e quando ele
acerta, a cada passo vivo de física (60/s). Tem três partes:

- **o golpe do jogador:** as quatro formas do cânone (arco, círculo, projétil e
  investida), com combo, recarga e recuperação. O Combate define como cada forma
  funciona; os números de cada arma (Lâmina, Ressonância) vêm do `AttackDef` e
  são escolhidos pelo GDD de Armas das Doutrinas (decisão do usuário,
  2026-11-09);
- **o impacto:** dano com o multiplicador do Modificadores (F2), empurrão que
  decai, cambaleio, "Quebrou!" (um golpe pesado interrompe a preparação do
  inimigo), impacto na parede, gatilhos de abate e a varredura de mortes;
- **o dano no jogador:** invulnerabilidade, redução, guarda, escudo, refletir e
  recusa de morte (F3 do Modificadores).

O Combate também é o dono do **hitstop**: um contador de passos em que o mundo
inteiro congela, e é o único que define o que é "passo vivo" para os outros
sistemas (Cena R7). Ele lê o golpe e o Selo do Input (o buffer), a posição e a
consulta "em esquiva" do Movimento, e honra o contrato que o Movimento definiu
(pedidos, `deslocar(v)` e o desconto da invulnerabilidade). Os números moram no
`AttackDef` e no `CombatTuning`.

Para o jogador, a promessa é a do P3 e do baseline §55: **cada golpe pesa, e
cada erro é dele.**

- O acerto congela a tela por alguns quadros, empurra o inimigo e, se for
  pesado, quebra o ataque que ele preparava.
- O golpe sai no passo do toque ou assim que a recarga deixa, porque o buffer
  guarda o comando.
- Nada acerta o jogador sem que um telégrafo tenha avisado (dono: Telégrafos).

Sem este sistema, não existe luta: só movimento.

> **→ vira ADR:** detectar acertos com círculos e distâncias próprias, como no
> cânone, ou com `Area2D` do Godot; e a ordem do passo (orquestrador). A
> referência do motor (`docs/engine-reference/godot/modules/physics.md`) não
> cobre a física 2D do 4.7.

## Detailed Design

### Core Rules

> `game-designer`, `systems-designer`, `ai-programmer` e `art-director` não
> foram consultados: modo Lean. Revisar manualmente antes de produção. As regras
> seguem o cânone (`action-core/src/engine.ts:63–84`, `:537–636`, `:666–765`,
> `:774–885`, `:940–980`, `:1162–1222`, `:1247–1308`) convertido para px e
> segundos (Conteúdo F1, F2, F4), com três decisões do usuário (2026-11-09):
> inimigo morto não age no passo (R14), projétil do jogador usa o empurrão do
> dado (R6) e o hitstop vale pelo maior (R10).

**R1. Ordem do passo vivo.** O orquestrador do passo chama, nesta ordem:

1. Input: amostra e buffer (Input R2, R6).
2. Se o hitstop está ativo (R10): passo congelado. O contador cai 1, o Input
   guarda o buffer com o prazo parado, o Movimento recebe `passo_congelado()`, e
   nada mais roda. Fim do passo.
3. **Combate, início do passo** (R2): descontos do jogador.
4. Movimento (Movimento R3).
5. **Combate, golpe do jogador** (R3): investida em curso e disparo.
6. Selo (GDD de Selo e Fluxo).
7. Inimigos, um por vez, na ordem estável da lista: Status (dano por passo),
   **Combate, impacto** (R12), IA (comportamento).
8. **Combate, projéteis** (R7).
9. **Combate, varredura de mortes** (R14).
10. Câmaras e ondas (próxima onda, câmara limpa).

Os itens 3, 5, 7, 8 e 9 são deste GDD. A ordem dos outros é dos donos; este GDD
só exige que o 3 venha antes do Movimento e o 5 depois dele.

**Estados de jogo do orquestrador** (cross-review 2026-11-10, S-B1 e S-W5). O
orquestrador só executa a R1 no estado **Jogo**. Fora dele (pausa, Bênção,
menus, Morte e Transição) a R1 não roda e nenhum contador do Combate desconta,
**nem o de hitstop**: uma pausa no meio do hitstop o retoma de onde parou. Em
cada passo de física fora de Jogo, o orquestrador só chama o `passo_congelado()`
do Movimento (Movimento R2), fora da R1.

**Transição** (troca de câmara; decisão do usuário, 2026-11-10):

- Começa no passo vivo em que as Câmaras pedem a troca (a porta) e dura o wipe
  do Pipeline visual (R7, `duracao_wipe_s`).
- A cada passo da Transição, o Movimento recebe `passo_congelado()` e nada mais
  do mundo roda. O Input fica no contexto Transição (Input R10): nenhuma ação de
  jogo e o buffer esvazia.
- No **quadro da metade do wipe** (o primeiro quadro de render com
  `progresso_wipe` ≥ 0,5, com a tela coberta; o wipe avança por quadro, e os
  passos de física seguem a 60 Hz), o orquestrador faz, nesta ordem e no mesmo
  quadro:
  1. avisa "câmara nova" ao Combate, que zera o hitstop, a investida e a
     recuperação (R10);
  2. teleporta o jogador para a entrada da câmara nova (Movimento R1; o
     teleporte cancela a esquiva);
  3. as Câmaras montam a câmara nova e o Selo apaga os Selos ativos (Selo e
     Fluxo R6);
  4. os VFX dos dois relógios são apagados (V1);
  5. a câmera corta para o alvo da câmara nova (Cena R10);
  6. o Pipeline troca a LUT, se a região mudou, e zera os relógios (Pipeline
     visual R2, R8, F8).
- Na segunda metade, o mundo segue congelado, já com a câmara nova na tela. Ao
  descobrir (fim do wipe), o estado volta a Jogo, e o passo seguinte é o
  primeiro passo vivo da câmara nova.

**R2. Início do passo.** Cada contador do jogador > 0 cai 1, nesta ordem:
invulnerabilidade, recarga do Ataque, recarga do Especial, guarda, janela
`apos_esquiva` (Modificadores R4), recuperação e as janelas de combo do Ataque e
do Especial. Quando a janela de combo de um slot chega a 0, o passo do combo
daquele slot volta a 0.
Descontar antes do Movimento faz `garantir_invulneravel(n)` proteger exatamente
n passos, contando o do pedido (contrato da F4 do Movimento), e a recuperação de
n passos deixar o jogador lento por n − 1 passos, como no cânone.

**R3. Disparo do golpe do jogador.** Depois do Movimento:

- **Não dispara** se a consulta "em esquiva" do Movimento é verdadeira ou se há
  investida ativa (R6).
- **Especial primeiro:** se o Especial está segurado ou no buffer e a recarga
  dele é 0, ele dispara. Senão, o mesmo teste para o Ataque. Só um dos dois
  dispara por passo.
- **Segurar repete:** segurar o botão conta como toque (Input R6). Disparar tira
  o botão do buffer.
- **O golpe sai em câmara limpa** também (cânone).

Ao disparar, no mesmo passo e nesta ordem:

1. **Combo** (só se o `AttackDef` tem `multiplicadores_combo`): cada slot
   (Ataque, Especial) tem o seu passo de combo e a sua janela (decisão do
   usuário, 2026-11-09; o cânone usava um contador só).
   `mult = combo[passo_combo mod n]`, depois `passo_combo = (passo_combo + 1) mod n`
   e a janela de combo do slot volta a `janela_combo_s`. O combo avança mesmo se
   o golpe errar. Sem lista, `mult` = 1 e o combo não muda.
2. **Multiplicador de dano** (Modificadores F2, R12), avaliado **agora**: o
   Combate pede ao portador `M_sem` (contexto com `enesimo_acerto` falso) e
   `M_com` (com `enesimo_acerto` verdadeiro), os dois com a Vida atual e a
   janela `apos_esquiva` como está. Depois **fecha** a janela `apos_esquiva`,
   acerte ou não (Modificadores R4).
3. **Dano do golpe:** `dano_golpe = AttackDef.dano × mult`. O dano por alvo é
   `dano_golpe × M_sem` ou `dano_golpe × M_com`, escolhido no impacto (R8).
4. **Recarga:** a do slot passa a `passos(AttackDef.recarga_s)`. Não há
   modificador de recarga no MVP (Modificadores R2).
5. **Guarda:** se o `AttackDef` tem `guarda_s`, a guarda passa a `passos(guarda_s)`
   (nenhuma arma do MVP tem).
6. **Finalizador:** se `mult > limiar_finalizador`, o golpe é **pesado** e o
   empurrão é `max(AttackDef.empurrao × mult, empurrao_pesado)`. Senão, o
   empurrão é `AttackDef.empurrao`. Este é o empurrão do golpe em qualquer forma,
   inclusive o projétil (F3).
7. **Recuperação** (fora da investida): `min(passos(recuperacao_max_s),
   round(passos(recarga_s) × fator_recuperacao_golpe))`, com a recarga **base**
   do `AttackDef`, sem modificadores de recarga (F2). O Movimento lê "em
   recuperação" = recuperação > 0 (Movimento R4). A esquiva a cancela.
8. **Forma** (R4–R6), que testa os alvos e aplica o impacto (R8).

**R4. Forma `arco` (corpo a corpo).** Params: `alcance_px`, `meio_angulo_graus`
(Conteúdo F5).

- Para cada inimigo atingível (R9), com `d` = distância do jogador ao inimigo e
  `u` = direção do jogador ao inimigo: é atingido se `d ≤ alcance_px + r_inimigo`
  **e** (`d < r_inimigo + raio_jogador_px + folga_encostado_px` **ou**
  `mira · u ≥ cos(meio_angulo_graus)`).
  - O primeiro teste vale em qualquer direção: um inimigo colado nas costas é
    atingido (cânone, decisão do usuário).
  - Com `d` = 0, `u` é a própria mira.
- Os alvos são testados na ordem estável da lista e recebem o impacto (R8) com
  direção `u`.
- Depois dos testes: evento `golpe`; se houve ≥ 1 alvo, hitstop **pesado** se o
  golpe é pesado (finalizador, Especial ou empurrão ≥ `empurrao_pesado`), senão
  **leve**. É um hitstop por golpe, não por alvo. O quarto acerto não sobe o
  hitstop do golpe (cânone); ele é pesado só no impacto (R8) e na apresentação
  (Visual/Audio V6, V14).
- **Passo de apoio:** por último, o Combate pede ao Movimento
  `deslocar(mira × passo_apoio_px)` (Movimento R9). Vem depois do teste de
  acerto, para não mudar o alcance.

**R5. Forma `circulo` (área).** Params: `raio_px`, `deslocamento_px`. Centro =
jogador + mira × `deslocamento_px`. Cada inimigo atingível com
`distância(centro, inimigo) ≤ raio_px + r_inimigo` recebe o impacto, com direção
do jogador ao inimigo. Evento `area`; hitstop como no arco. Sem passo de apoio.

**R6. Forma `projetil` e forma `avanco` (investida).**

- **`projetil`.** Params: `velocidade_pxs`, `raio_px`, `vida_s` (Conteúdo F6),
  `leque` (lista de índices), `atravessa`.
  - Um projétil por índice do leque. O índice k gira a mira em
    `giro_leque_graus × ceil(k / 2)` (12°), positivo para k ímpar e negativo para k par (0 = sem
    giro; 1 = +12°; 2 = −12°; 3 = +24°…). Giro positivo é horário na tela (y para
    baixo).
  - Nasce em jogador + direção × `nascimento_projetil_px` e leva `dano_golpe`,
    `M_sem`, `M_com`, o empurrão do item 6 da R3 (o cânone ignorava o dado
    e usava 6 u fixo; aqui vale o dado, e o Pulso de fábrica grava 540 px/s, Armas
    R2) e o status. O voo é a R7.
  - Evento `disparo`. **Sem hitstop no disparo.**
- **`avanco`.** Params: `distancia_px`, `duracao_s`, `raio_px`.
  - Fica **investida ativa** por N = `passos(duracao_s)` passos, com
    `d = mira × distancia_px / N` por passo (vetor). O Movimento aplica `d` a
    partir do passo seguinte (Movimento R9).
  - Pede `garantir_invulneravel(N + passos(invuln_extra_investida_s))`.
  - Evento `investida`. Sem recuperação.
  - **Em cada passo de investida**, a partir do passo **seguinte** ao disparo
    (item 5 da R1, depois do Movimento; F6): cada
    inimigo atingível a `≤ raio_px + r_inimigo` que ainda não foi atingido nesta
    investida recebe o impacto, com o empurrão do `AttackDef` (sem a regra do
    finalizador) e direção de `d`. Hitstop **pesado** no primeiro alvo da
    investida e **leve** nos seguintes.
  - **Contador da investida:** posto em N no disparo. O Movimento lê
    "investida ativa" = contador > 0 no item 4 e aplica `d`. No item 5 do mesmo
    passo, **antes** do teste de disparo, se o contador > 0: o Combate testa os
    alvos na posição atual e desconta 1. A consulta do disparo (R3) lê o
    contador depois do desconto: no último passo (s+N) ela já é falsa, e um
    golpe guardado sai nesse passo (cânone `engine.ts:822–837`, `:865`). Assim
    saem exatamente N deslocamentos, do s+1 ao s+N (F6).
  - Termina quando o contador chega a 0 ou quando a esquiva a cancela (R18).
  - **Divergência declarada:** o teste de alvos da investida é feito depois da
    colisão do Movimento (posição presa); o cânone testava antes do
    `resolveCollisions`. A diferença só aparece colado em parede ou obstáculo.

**R7. Projéteis em voo** (do jogador e dos inimigos; item 8 da R1).

- A cada passo vivo: anda `velocidade_pxs / 60` e a vida cai 1 passo. O
  projétil anda já no passo em que nasce (item 8 do mesmo passo; cânone). O passo
  em que a vida chega a 0 **não testa acerto** (cânone; F5).
- **Some** se a vida acaba, se o centro sai do retângulo jogável ou se encosta num
  obstáculo (`distância < r_obstaculo + raio_px × fator_raio_obstaculo_projetil`,
  0,5). Ordem do teste em cada passo: move, vida, retângulo e obstáculo,
  acerto: o projétil que some por obstáculo não acerta nesse passo.
- **Do jogador:** atinge o primeiro inimigo atingível com
  `distância ≤ raio_px + r_inimigo`, com o impacto na direção do voo. Se
  `atravessa`, continua e não atinge o mesmo inimigo duas vezes; senão some.
- **De inimigo:** atinge o jogador com `distância ≤ raio_px + raio_jogador_px`
  pela R13, sem atacante (não reflete). Leva o `M` do disparo (Modificadores
  R12). A IA cria o projétil com `disparar_projetil(posição, direção,
  velocidade_pxs, raio_px, vida_s, dano_base, M_disparo, atravessa)`, que emite
  `disparo` com dono "inimigo". Se o jogador está invulnerável, o projétil **atravessa e continua**
  (cânone).

**R8. Impacto em inimigo** (`ferir_inimigo`). Usado pelas formas, pelo Corte da
esquiva, pela parede, pela explosão e pelo reflexo. Entrada: alvo, dano ou
(`dano_golpe`, `M_sem`, `M_com`), direção, empurrão, status, `de_arma`, `pesado`.

1. Se o alvo não é atingível (R9), nada acontece.
2. **Golpe de arma** (`de_arma`: arco, círculo, investida, projétil do jogador):
   - o contador de acertos do jogador sobe 1 (Modificadores R4: por alvo);
   - se o portador tem `dano_enesimo_acerto` e o contador é múltiplo de
     `a_cada`, o dano é `dano_golpe × M_com` e o acerto é **marcado** (`enesimo_acerto` verdadeiro; "quarto acerto" no texto deste GDD é o caso `a_cada` = 4);
     senão, `dano_golpe × M_sem`;
   - emite `acerto_de_arma` (o Selo soma Fluxo; o Status aplica `golpe_*`).
3. Vida −= dano, sem limitar ao que resta. O dano a inimigos é fracionário
   (Modificadores F3).
4. **Pesado** = `pesado` de entrada (o finalizador, F3), ou acerto marcado (`enesimo_acerto`), ou
   empurrão de entrada ≥ `empurrao_pesado` (antes do `fator_empurrao` do alvo).
   O Especial só sobe o hitstop do golpe (R4); no impacto ele segue esta regra.
5. Evento `acerto` (alvo, posição, direção, dano, pesado, `enesimo_acerto`).
6. **Empurrão:** `vel_empurrao += direção × empurrão × valor(fator_empurrao)`
   do alvo (elite × 0,4, chefe × 0,12; Modificadores R10). **Soma** à velocidade
   que ele já tinha.
7. **Cambaleio e "Quebrou!"** (só se o alvo não é chefe nem elite e o empurrão
   de entrada é > 0; a "armadura" de elite e chefe é regra deste GDD, Modificadores R10):
   - cambaleio = `max(cambaleio, passos(cambaleio_s))`;
   - se o golpe é pesado, o alvo está **em preparação** e a Vida > 0: "Quebrou!".
     O Combate pede à IA que passe o alvo para **recuperação** por
     `passos(quebrou_recuperacao_s)`, e emite `quebrou`. Um ataque já em
     execução nunca é cancelado.
8. Status do `AttackDef` (ou do Corte) vai para o GDD de Efeitos de status.

O dano por passo do Status e do Selo (Selo e Fluxo R3) chama o impacto com `de_status`: só os itens 1 e 3
(atingível e Vida), sem evento `acerto`, sem empurrão, sem cambaleio e sem
hitstop (cânone).

**R9. Atingível.** Um inimigo é atingível se não está surgindo (a duração é da
IA) e tem Vida > 0. É a mesma lista que o Movimento recebe para o Corte e o
Input usa na mira (consulta de alvos da IA).

**R10. Hitstop.**

- O Combate guarda um contador. `pedir_hitstop(n)` faz
  `contador = max(contador, n)`: **vale o maior** (cânone; decisão do usuário,
  fecha o D-N1). O teto prático é o abate de chefe.
- O passo em que o hitstop é pedido **termina normalmente**: os inimigos, os
  projéteis e a varredura ainda rodam nele. O congelamento começa no passo
  seguinte (R1, item 2).
- Enquanto o contador > 0, nada do mundo roda: só o Input (buffer com prazo
  parado) e o `passo_congelado()` do Movimento. Contadores de modificadores,
  status, recargas e invulnerabilidade não descontam.
- **Câmara nova** (decisão do usuário, 2026-11-10): o aviso chega no quadro da
  metade do wipe, no estado Transição (R1). O Combate zera o contador de
  hitstop, a investida e a recuperação (como o `cancelar` da R18). Recargas,
  combo, janelas, guarda e invulnerabilidade passam para a câmara nova como
  estão. O pedido de troca só sai de passo vivo (a porta).
- **Câmara limpa espera o hitstop** (decisão do usuário, 2026-11-10): o
  orquestrador só chama a avaliação de "câmara limpa" do item 10 da R1 com o
  contador de hitstop em 0. Se o passo pediu hitstop (o último abate pede ao
  menos `hitstop_abate_s`), a avaliação fica para o primeiro passo vivo depois
  do congelamento. Assim a câmara limpa, a porta e a Bênção (Run e regiões)
  nunca começam com um hitstop pendente. É contrato para Câmaras e ondas e
  Run e regiões.
- A consulta "hitstop ativo" é do orquestrador (Movimento R2, Input R6).

| Causa | Hitstop | Cânone |
|---|---|---|
| Golpe leve com ≥ 1 alvo (arco, círculo) | `hitstop_leve_s` (3 passos) | `HITSTOP_LIGHT` |
| Golpe pesado ou Especial com ≥ 1 alvo; 1º alvo da investida | `hitstop_pesado_s` (6) | `HITSTOP_HEAVY` |
| 2º alvo em diante da investida; impacto na parede | leve (3) | `HITSTOP_LIGHT` |
| Projétil do jogador | nenhum | — |
| Abate de inimigo comum | `hitstop_abate_s` (4) | `HITSTOP_KILL` |
| Abate de elite | pesado (6) | `HITSTOP_HEAVY` |
| Abate de chefe | `hitstop_abate_chefe_s` (36) | `HITSTOP_BOSS_KILL` |
| Jogador atingido | `hitstop_atingido_s` (6) | `HITSTOP_HURT` |
| Recusa de morte | `hitstop_recusa_s` (18; vale o maior sobre o de atingido) | — (divergência: o cânone usava 6) |
| Corte da esquiva, refletir, dano do Selo, dano de status, explosão | nenhum (o abate, se houver, cobre) | — |

**R11. Impacto na parede** (item 7 da R1, dentro do impacto do inimigo):

1. `v` = módulo de `vel_empurrao` **antes** de mover.
2. Se `v` > 0, o inimigo anda `vel_empurrao / 60` e é preso pelas paredes e
   pelos obstáculos da câmara (mesma regra da R10 do Movimento, com o raio
   dele). A separação entre inimigos (IA) **não** conta como parede.
3. Se a posição foi corrigida e `v ≥ parede_vel_min`: `vel_empurrao` = 0, evento
   `parede`, impacto com dano `parede_dano × M_parede` (grupo Ataque, contexto
   com a Vida atual do jogador; Modificadores R12), direção do jogador ao
   inimigo (cânone), empurrão 0, `de_arma` falso,
   `pesado` falso, e hitstop leve.
4. Depois, `vel_empurrao ×= queda_empurrao`; abaixo de `empurrao_zero`, zera.

**R12. Impacto do inimigo por passo** (item 7 da R1): só para inimigos com Vida
> 0. Aplica a R11 e desconta 1 do cambaleio. Enquanto cambaleia, a IA anda ×
`fator_cambaleio` (a IA lê "cambaleando"); o relógio de ataque dele **não**
para (baseline §55). O empurrão não é afetado pelo cambaleio. Um golpe do item 5
deixa a IA lenta `passos(cambaleio_s)` − 1 passos vivos, porque o desconto do
item 7 já roda no mesmo passo (cânone).

**R13. Dano no jogador** (`ferir_jogador`; Modificadores F3, R13). Entrada:
`dano_base`, `M_atacante`, atacante (ou nenhum, para projétil), tipo.

1. Nada acontece se o jogador está invulnerável ou fora de combate. "Em
   combate" é uma consulta injetada das Câmaras (verdadeira da porta fechada até
   a câmara limpa, inclusive no vão entre ondas); a lista de inimigos vazia
   **não** basta. Na Bênção e nos menus o Combate nem roda. Fora de combate, o
   projétil inimigo segue voando, sem dano (cânone).
2. `dano = max(1, round(dano_base × M_atacante × (1 − min(teto_reducao,
   max(0, reducao))) × guarda))`; guarda = `fator_guarda` (0,5) com a guarda
   ativa, senão 1.
3. O escudo absorve até `dano`; `vida_perdida = dano − absorvido`.
4. Vida −= `vida_perdida`. Invulnerabilidade = `max(atual,
   passos(invuln_atingido_s))`, **mesmo** que o escudo tenha absorvido tudo.
5. Hitstop de jogador atingido; evento `jogador_atingido` (vida_perdida).
6. **Refletir:** com atacante corpo a corpo, gatilho `refletir_dano` e
   `vida_perdida > 0`, o atacante recebe impacto com dano `vida_perdida × valor`,
   sem M, direção do jogador ao atacante (cânone), empurrão 0, `de_arma` falso.
   Vem antes do teste de morte.
7. **Morte:** com Vida ≤ 0 e recusa restante, a Vida passa a
   `max(1, round(vida_max × vida_ao_voltar))`, a invulnerabilidade a `passos(invuln_s)`
   (params do gatilho `recusas_morte`), gasta 1 recusa, pede o hitstop da
   recusa (`hitstop_recusa_s`, decisão do usuário, 2026-11-09, para o *impact
   frame* da Visual/Audio V11 ser legível) e emite `recusou_morte`.
   Sem recusa: Vida = 0, evento `jogador_morreu`. A Run encerra a run e o Input
   sai de Jogo.

A geometria do golpe inimigo (alcance, ângulo, quando acerta) é da IA e dos
Telégrafos, que chamam `ferir_jogador`. O telégrafo e o teste de acerto têm de
ser a mesma forma (P3).

**R14. Varredura de mortes** (item 9 da R1).

- **Inimigo morto não age** (decisão do usuário, divergência do cânone): com
  Vida ≤ 0 ele deixa de ser atingível e pula impacto e IA até a varredura, mesmo
  no passo em que morreu.
- Até `passes_varredura` (4) passes. Cada passe tira, no início, o retrato dos
  inimigos com Vida ≤ 0; quem morre durante o passe fica para o seguinte. Cada
  um do retrato sai da lista e:
  - contagem de abates + 1, evento `inimigo_morreu` (posição, elite, chefe);
  - hitstop de abate (comum, elite ou chefe);
  - `cura_ao_abater`: o jogador cura `valor`, até `vida_max`, **exceto** se o
    jogador já está Morto neste passo (R13.7): morto não cura, e a recusa não é testada de novo;
  - `explosao_ao_abater`: impacto com dano `valor` (sem M), empurrão `empurrao`,
    `de_arma` falso, em todo inimigo atingível a `≤ raio_px + r_alvo` do morto,
    inclusive chefes; evento `explosao`;
  - se o morto é chefe: a Vida de todos os outros inimigos vira 0.
- Mortos criados pelo 4º passe ficam para o passo seguinte (Modificadores R13).
- **Se o jogador morreu neste passo:** o resto do passo roda (hitstop, explosões,
  eventos), sem cura; o orquestrador para os passos vivos a partir do seguinte
  (o Input sai de Jogo).

**R15. `CombatTuning`** (dado; Conteúdo R1). Valores em segundos, convertidos
pelo F7 do Conteúdo; px e px/s pela F2/F4. As faixas serão conferidas no
Formulas.

| Campo | Valor inicial | Cânone |
|---|---|---|
| `hitstop_leve_s` | 0,05 (3 passos) | `HITSTOP_LIGHT` 3 |
| `hitstop_pesado_s` | 0,1 (6) | `HITSTOP_HEAVY` 6 |
| `hitstop_abate_s` | 0,0667 (4) | `HITSTOP_KILL` 4 |
| `hitstop_atingido_s` | 0,1 (6) | `HITSTOP_HURT` 6 |
| `hitstop_abate_chefe_s` | 0,6 (36) | `HITSTOP_BOSS_KILL` 36 |
| `hitstop_recusa_s` | 0,3 (18) | — (cânone: 6, o de atingido) |
| `empurrao_pesado` | 900 px/s | `HEAVY_KNOCKBACK` 10 u/passo |
| `limiar_finalizador` | 1,2 | `mult > 1.2` |
| `janela_combo_s` | 0,5667 (34) | `COMBO_WINDOW_TICKS` 34 |
| `recuperacao_max_s` | 0,2 (12) | `RECOVER_MAX_TICKS` 12 |
| `fator_recuperacao_golpe` | 0,5 | `cooldown × 0,5` |
| `passo_apoio_px` | 10,5 | `MELEE_STEP` 7 u |
| `folga_encostado_px` | 6 | `+ 4` u |
| `nascimento_projetil_px` | 36 | 24 u |
| `invuln_extra_investida_s` | 0,0333 (2) | `ticks + 2` |
| `cambaleio_s` | 0,1333 (8) | `STAGGER_TICKS` 8 |
| `fator_cambaleio` | 0,4 | `× 0,4` |
| `quebrou_recuperacao_s` | 0,4 (24) | `recover` 24 |
| `parede_vel_min` | 630 px/s | `WALL_SLAM_SPEED` 7 u/passo |
| `parede_dano` | 8 | `WALL_SLAM_DAMAGE` 8 |
| `queda_empurrao` | 0,78 por passo | `× 0,78` |
| `empurrao_zero` | 4,5 px/s | `0,05` u/passo |
| `invuln_atingido_s` | 0,6667 (40) | `HURT_INVULN_TICKS` 40 |
| `passes_varredura` | 4 | `sweepDeaths` |
| `fator_guarda` | 0,5 | guarda × 0,5 (Modificadores F3) |
| `giro_leque_graus` | 12 | `rotate` do leque |
| `fator_raio_obstaculo_projetil` | 0,5 | `raio × 0,5` contra obstáculo |
| `flash_acerto_s` | 0,0833 (5 passos vivos) | — (Art Bible §5.5; V6) |
| `extra_inversao_s` | 0,0667 (4 passos vivos) | — (V10; emenda ao "2 quadros" do §5.5) |
| `impact_chefe_s` | 0,2 (12 passos de apresentação) | — (Art Bible §2.9; V12) |

**Durações visuais** (cross-review 2026-11-10, C-B2; decisão do usuário: o dono
é o Combate). Os três últimos campos são do Combate, e o Pipeline visual só os
implementa (Pipeline R7, R12). A duração do *impact frame* da recusa é
passos(`hitstop_recusa_s`), sem campo próprio. As do *impact frame* contam em
**passos de apresentação** (1/60 s de `t_apres`, Pipeline R8); as do flash e da
inversão, em passos vivos. As durações vão prontas nos eventos (R17).

`fator_recuperacao` (andar a 45% em recuperação) é do `MovementTuning`. O Fluxo
por acerto é do GDD de Selo e Fluxo. Pisos e tetos de dano são do
`ModifiersTuning`.

**R16. Injeção.** O Combate recebe por injeção: o portador do jogador e os dos
inimigos (Modificadores R11), a amostra de entrada (Input R2), as consultas do
Movimento (posição, "em esquiva", raio), a lista de inimigos com posição, raio,
estado da IA (surgindo, em preparação, em execução) e comportamento (elite,
chefe), a geometria da câmara e a consulta "em combate" das Câmaras (R13.1), o
`CombatTuning` e os `AttackDef` da arma. Os
testes montam tudo em memória.

**R17. Eventos e recursos do jogador.** `peso_visual` do `acerto` é resolvido
pelo Combate:

- **arco, círculo e investida:** pesado se o golpe pediu hitstop pesado (golpe
  pesado ou Especial no arco e no círculo; 1º alvo da investida) ou se o alvo é
  quarto acerto;
- **projétil:** pesado só se o golpe é finalizador;
- senão, **leve**.

É o que a Visual/Audio V6 e V14 usam, sem refazer a regra. O número dourado do
quarto acerto sai em todo quarto acerto, qualquer que seja o `peso_visual`
(decisão do usuário, 2026-11-09). Num `acerto` sem arma, o slot é "nenhum" e a forma é a
origem (`corte`, `parede`, `reflexo`, `explosao`; o Selo não emite `acerto`, Selo e Fluxo R3). O `vel_empurrao` do
`inimigo_morreu` é a velocidade total do alvo no momento da morte, já com o
empurrão do golpe que o matou.

O Combate guarda a Vida atual, o
escudo e as recusas restantes do jogador (recursos; Modificadores R1, R9); os
testes os montam pela fixture. Campos dos eventos:

| Evento | Campos |
|---|---|
| `golpe` | posição, mira, slot, `alcance_px`, `meio_angulo_graus`, pesado, n.º de alvos |
| `area` | centro, `raio_px`, slot, pesado, n.º de alvos |
| `disparo` | posição, direção, dono (jogador / inimigo) |
| `investida` | posição, direção, N |
| `acerto` | alvo, posição, direção, dano, pesado, `enesimo_acerto`, de_arma, slot, forma, `peso_visual` (leve / pesado), `flash_passos` = passos(`flash_acerto_s`) |
| `parede` | alvo, posição, normal da parede |
| `quebrou` | alvo, posição |
| `jogador_atingido` | Vida perdida, direção do atacante ao jogador (projétil: voo), `inversao_passos` = hitstop pedido pelo golpe + passos(`extra_inversao_s`), `invuln_passos` = invulnerabilidade atribuída |
| `recusou_morte` | Vida nova, `impact_passos` = passos(`hitstop_recusa_s`) (de apresentação), `invuln_passos` = invulnerabilidade atribuída |
| `inimigo_morreu` | alvo, posição, elite, chefe, `vel_empurrao` do golpe que o matou (para o deslize da V12), `impact_passos` = passos(`impact_chefe_s`) no chefe (de apresentação), 0 nos outros |
| `explosao` | posição, `raio_px` |
| `acerto_de_arma` | alvo, slot, `enesimo_acerto`, pesado (o Selo soma Fluxo; o Status aplica `golpe_*`; só golpes de arma) |
| `jogador_morreu` | `causa` (pedido pela Telemetria: `atacante_tipo` e `ataque_id` do último `jogador_atingido`; `null` se faltarem) |

**R18. Pedidos do Movimento** (contrato da OQ2 do Movimento), síncronos:

- **`cancelar`:** zera o contador da investida e a recuperação. Não mexe em
  combo, janelas, recargas nem invulnerabilidade.
- **`garantir_invulneravel(n)`:** invulnerabilidade = `max(atual, n)`.
- **`aplicar_corte(alvo, dano, direção, empurrão, sangramento)`:** chama a R8
  com o dano pronto (o Movimento já aplicou o M), `de_arma` falso e `pesado`
  falso. Não conta acerto, não gera Fluxo, não aciona `golpe_*` e não pede
  hitstop (Modificadores R13). Com empurrão ≥ `empurrao_pesado`, o impacto
  ainda vira pesado pela R8.4 (cânone).
- **`esquiva_iniciada`:** se o portador tem `dano_apos_esquiva`, a janela
  `apos_esquiva` passa a `passos(janela_s)` (o param é único por tipo, V11 do
  Conteúdo). Uma esquiva nova reinicia a janela inteira (cânone `empowerTicks`).
  Sem o gatilho, nada. A janela desconta na R2 e fecha no disparo (R3).

### States and Transitions

**Jogador (lado do Combate)** — estados sobrepostos, cada um com o seu contador:

| Estado | Entra quando | Sai quando |
|---|---|---|
| Pronto (Ataque / Especial) | recarga do slot = 0 | dispara (R3) |
| Em recarga | dispara | a recarga chega a 0 (R2) |
| Em recuperação | dispara forma que não é `avanco` | recuperação chega a 0, ou a esquiva cancela |
| Em investida | dispara `avanco` | N passos acabam, ou a esquiva cancela |
| Invulnerável | esquiva, investida, golpe recebido, recusa | o contador chega a 0 |
| Morto | Vida ≤ 0 sem recusa | fim da run (Run e regiões) |

**Inimigo (lado do Combate):**

| Estado | Entra quando | Sai para |
|---|---|---|
| Surgindo | spawn (IA) | Atingível |
| Atingível | fim do surgimento | Morto (Vida ≤ 0) |
| Cambaleando (sobreposto) | impacto com empurrão > 0, sem armadura | Atingível, quando o contador acaba |
| Empurrado (sobreposto) | `vel_empurrao` ≠ 0 | parado, quando zera ou bate na parede |
| Morto | Vida ≤ 0 | Removido, na varredura (R14) |

**Mundo:** Vivo ↔ Congelado (hitstop > 0). Todos os contadores acima param em
Congelado. Fora do estado de jogo Jogo (pausa, Bênção, menus, Morte, Transição;
R1) a R1 não roda e nada desconta, nem o hitstop.

### Interactions with Other Systems

| Sistema | Recebe daqui | Fornece para cá | Dono da interface |
|---|---|---|---|
| Input e controle | consumo de Ataque e Especial no buffer; "hitstop ativo" (via orquestrador) | Ataque e Especial (toque, segurado, buffer), mira | Input (amostra), este GDD (quando o golpe sai) |
| Movimento e esquiva | "em recuperação", investida ativa e `d`, `contexto_de_dano` (Vida atual e máxima), pedido `deslocar(v)`; executa `cancelar`, `garantir_invulneravel`, `aplicar_corte`, `esquiva_iniciada` | posição, raio, "em esquiva", pedidos | Movimento (contrato), este GDD (execução) |
| Modificadores e atributos | contexto (Vida, janela `apos_esquiva`, contador de acertos) | `valor`, `multiplicador_de_dano`, gatilhos | Modificadores |
| Conteúdo orientado a dados | — | `AttackDef`, `CombatTuning` | Conteúdo (formato), este GDD (semântica) |
| Armas das Doutrinas | — | os números de cada `AttackDef` | Armas |
| Selo e Fluxo | `acerto_de_arma` (Fluxo); "hitstop ativo" | dano do Selo por passo via `ferir_inimigo` | Selo |
| Efeitos de status | status do golpe e do Corte; `acerto_de_arma` (`golpe_*`) | dano por passo via `ferir_inimigo` (sem evento `acerto`, cânone) | Status |
| IA de inimigos e elites | pedido de "Quebrou!" (recuperação), "cambaleando" | estado (surgindo, preparação, execução), elite, chefe, chamadas de `ferir_jogador` e `disparar_projetil` | IA; **provisório** |
| Telégrafos | — | a forma do golpe inimigo (igual ao telégrafo) | Telégrafos; **provisório** |
| Câmaras e ondas | abates, `jogador_morreu`; "câmara limpa" só avaliada com hitstop 0 (R10) | retângulo, obstáculos, pedido de troca de câmara (estado Transição, R1; zera hitstop, investida e recuperação), consulta "em combate" (R13.1) | Câmaras; **provisório** |
| Run e regiões | `jogador_morreu` | — | Run |
| Cena 3/4 e câmera | eventos para chute, tremor e zoom | — | Cena (impulsos), este GDD (eventos) |
| HUD / Feedback de combate (VFX) / Áudio | eventos `golpe`, `area`, `disparo`, `investida`, `acerto`, `parede`, `quebrou`, `jogador_atingido`, `recusou_morte`, `inimigo_morreu`, `explosao` | — | apresentação |
| Pipeline visual | eventos com as durações visuais (R15, R17); estado de jogo e "câmara nova" no quadro da metade do wipe (R1) | progresso do wipe (`progresso_wipe`, Pipeline R7) | este GDD (durações, ordem), Pipeline (como desenha) |

## Formulas

> Proposta do `systems-designer` (consultado: modo Lean, seção de risco alto).
> Contas refeitas contra o cânone (`engine.ts:556–636`, `:666–765`, `:778–839`,
> `:949–980`, `:1162–1222`; `arenaContent.ts`). Escolhas de combo, hitstop
> mínimo, recuperação e trava do "Quebrou!": usuário, 2026-11-09.

Convenções: `passos(t)` é o F7 do Conteúdo; `TICK_RATE` = 60. **R** =
passos(`AttackDef.recarga_s`), **J** = passos(`janela_combo_s`), **N** =
passos(`duracao_s`) da investida, **E** = passos(`invuln_extra_investida_s`). As
somas de passos são feitas em inteiros, como no MV3 do Movimento. O dano a
inimigos é float; o dano ao jogador é inteiro (F3 do Modificadores).

### F1. Dano de um golpe por alvo

The weapon_hit_damage formula is defined as:

`c = combo[passo_combo mod n]` (c = 1 sem lista) ; `dano_golpe = AttackDef.dano × c` ;
`dano_alvo = dano_golpe × (quarto ? M_com : M_sem)` ;
`quarto = tem_enesimo ∧ (contador_acertos mod a_cada = 0)`, com o contador já
somado (+1) **antes** do teste

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| AttackDef.dano | float | > 0 (cânone 9–30) | data file | dano base do golpe (Armas) |
| combo | float[] | n ≥ 1, cada entrada > 0 | data file | `multiplicadores_combo`; ausente → c = 1 |
| passo_combo | int | 0 – n−1 | calculated | **um por slot** (Ataque, Especial); volta a 0 quando a janela do slot zera (R2) |
| c | float | > 0 (cânone 1–1,8) | calculated | multiplicador do passo do combo |
| M_sem, M_com | float | ≥ 0 | calculated | F2 do Modificadores, avaliada no disparo (R3.2). M_com = M_sem × (1 + valor) |
| contador_acertos | int | ≥ 1 no teste | calculated | +1 por alvo de golpe de arma (Modificadores R4) |
| a_cada | int | ≥ 1 (4) | data file | param de `dano_enesimo_acerto` |
| dano_alvo | float | ≥ 0 | calculated | Vida tirada do alvo, sem limitar ao que resta |

**Output Range:** ≥ 0, sem teto (a F2 do Modificadores não tem teto). Dano 0
ainda aplica empurrão, cambaleio e status (R8). Entrada de combo ≤ 0 é recusada
(CV4).
**Example:** Lâmina, Corte 14, combo [1; 1; 1,8], sem bênção: 14 → 14 → 25,2. Um
Eco Perdido (30) cai no 3º golpe (53,2 acumulado). Com +25% Ataque (M_sem 1,25)
e Linha Contada +60% (M_com 2,0): o 3º golpe tira 31,5; se for o 4º acerto do
contador, 25,2 × 2,0 = 50,4. Pulso: 12 × 1,25 = 15.

### F2. Recuperação do golpe

The attack_recovery formula is defined as:

`rec = 0` se a forma é `avanco` ; senão
`rec = min(passos(recuperacao_max_s), round(R × fator_recuperacao_golpe))` ;
passos lentos = `max(0, rec − 1)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| recuperacao_max_s | float | 0,0167–0,5 | data file | `CombatTuning` |
| fator_recuperacao_golpe | float | 0–1 | data file | `CombatTuning` |
| R | int | ≥ 1 | calculated | recarga **base** do `AttackDef`, sem modificadores de recarga (cânone) |
| rec | int | 0 – passos(recuperacao_max_s) | calculated | contador posto no disparo (R3, item 7) |

**Output Range:** inteiro de 0 a 30 nas faixas; `round` leva o x,5 para longe
do zero. Com fator ≤ 1, `rec` ≤ R. O jogador anda lento por rec − 1 passos,
porque a R2 desconta antes do Movimento. A esquiva zera o contador. A
recuperação **não** impede o próximo golpe: só a recarga impede.
**Example:** Corte: min(12, round(16 × 0,5) = 8) = 8 → 7 passos lentos
(0,117 s). Pulso: 7 → 6. Onda: round(45) = 45, preso em **12** → 11. Investida:
0.

### F3. Finalizador e golpe pesado

The finisher_knockback formula is defined as:

`fin = c > limiar_finalizador` ;
`emp = fin ? max(AttackDef.empurrao × c, empurrao_pesado) : AttackDef.empurrao` ;
`pesado = fin ∨ quarto ∨ emp ≥ empurrao_pesado` (com o `emp` de entrada,
**antes** do `fator_empurrao`, cânone `engine.ts:581`) ;
`emp_efetivo = emp × valor(fator_empurrao)` do alvo

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| c | float | > 0 | calculated | F1 |
| limiar_finalizador | float | 1,0–1,45 | data file | `CombatTuning` (1,2) |
| AttackDef.empurrao | float | ≥ 0 (cânone 180–1980 px/s) | data file | F2 do Conteúdo (× 90) |
| empurrao_pesado | float | 460–1080 px/s | data file | `CombatTuning` (900) |
| fator_empurrao | float | 0–1 (comum 1, elite 0,4, chefe 0,12) | calculated | Modificadores R10 |
| emp_efetivo | float | ≥ 0 px/s | calculated | velocidade somada ao alvo (F7) |

**Output Range:** `emp` ≥ `empurrao_pesado` sempre que `fin`: todo finalizador
é pesado e quebra a preparação (R8). Sem combo, c = 1 e nunca há finalizador
(CV3). O projétil leva este mesmo `emp` (com o finalizador, se a arma tiver
combo).
**Example:** Corte 450 px/s, leve. 3º golpe: 1,8 > 1,2 → max(810, 900) = **900**,
pesado; contra elite 360, contra chefe 108. Investida 1080 e Onda 1260: pesadas
pelo empurrão. Pulso 540 (Armas R2): leve.

### F4. Teste de acerto do arco e do círculo

The melee_hit_test formula is defined as:

**Arco:** acerta se `d ≤ alcance_px + r_i` **∧** (`d < r_i + raio_jogador_px +
folga_encostado_px` **∨** `mira · u ≥ cos_meio`), com
`cos_meio = cos(meio_angulo_graus)` e `u = mira` se d = 0.
**Círculo:** acerta se `|inimigo − (jogador + mira × deslocamento_px)| ≤ raio_px + r_i`.

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| d | float | ≥ 0 | calculated | distância jogador–inimigo, centro a centro |
| alcance_px | float | > 0 (cânone 105–180) | data file | Conteúdo F4 |
| meio_angulo_graus | float | 5–180 | data file | Conteúdo F5 |
| cos_meio | float | −1–0,996 | calculated | calculado na carga |
| r_i | float | > 0 (22,5–63) | data file | `EnemyDef.raio`, com elite × 1,2 |
| raio_jogador_px | float | 10–50 (27) | data file | `MovementTuning` |
| folga_encostado_px | float | 0–20 (6) | data file | `CombatTuning` |
| raio_px, deslocamento_px | float | > 0, ≥ 0 | data file | params do `circulo` |

**Output Range:** booleano. O alcance usa `≤`; o encostado usa `<` (cânone). Pode
ser feito com distância ao quadrado, sem raiz. Com meio-ângulo 180°, o arco vira
um círculo de raio `alcance_px`.
**Example:** Corte (142,5 px, 69,51°, cos 0,35) contra Eco (24): alcance limite
166,5 px; o anel de encostado vale para d < 57 px. A 150 px e 60° da mira:
0,5 ≥ 0,35, acerta. A 150 px e 80°: 0,17, erra. A 50 px, nas costas: 50 < 57,
acerta. Onda (195 px, deslocamento 0) contra Eco: acerta até 219 px.

### F5. Leque e alcance do projétil

The projectile_fan formula is defined as:

`θ_k = 0` se k = 0 ; senão `θ_k = (k ímpar ? +1 : −1) × giro_leque_graus × ceil(k / 2)` (12°)
(positivo = horário, y para baixo) ; `s = velocidade_pxs / 60` ;
`L = passos(vida_s)` ; `alcance_testado = nascimento_projetil_px + (L − 1) × s`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| k | int | ≥ 0 | data file | índice no `leque` |
| velocidade_pxs | float | > 0 (cânone 720–1170) | data file | Conteúdo F2 |
| vida_s | float | > 0 | data file | Conteúdo F6 |
| L | int | ≥ 2 (CV13) | calculated | passos de vida |
| s | float | > 0 | calculated | px por passo |
| nascimento_projetil_px | float | 27–60 (36) | data file | `CombatTuning` |
| alcance_testado | float | > 0 | calculated | último centro testado, medido a partir do jogador |

**Output Range:** θ ∈ {0, ±12°, ±24°…}. O passo que zera a vida **não testa
acerto** (cânone `engine.ts:1164–1168`; R7): há L − 1 testes, e com L = 1 o
projétil nunca acerta. Parede e obstáculos encurtam o voo. O "alcance" do F6 do
Conteúdo (v × vida) é só informativo e não é o alcance real.
**Example:** Pulso: s = 16,5 px, L = 50 → 36 + 49 × 16,5 = **844,5 px** a partir
do jogador (o F6 do Conteúdo mostra 825). Leque [0, 1, 2]: 0°, +12°, −12°.

### F6. Investida

The lunge formula is defined as:

`N = passos(duracao_s)` ; `d = mira × distancia_px / N` (por passo, do passo s+1
ao s+N) ; `inv = N + E` (pedido no passo s; protege s … s+N+E−1) ;
`cauda = E − 1` passos protegidos depois do último deslocamento ; alvo atingido
no passo t (s+1 ≤ t ≤ s+N) se `|inimigo − jogador_t| ≤ raio_px + r_i`, uma vez
por investida

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| distancia_px | float | ≥ 0 (cânone 330) | data file | param `avanco` |
| duracao_s | float | > 0 | data file | param `avanco` |
| N | int | ≥ 1 | calculated | passos de investida |
| raio_px | float | > 0 (69) | data file | param `avanco` |
| invuln_extra_investida_s | float | 0–0,1 (aceita 0) | data file | `CombatTuning` |
| E | int | 0–6 | calculated | passos extras |
| inv | int | ≥ N | calculated | pedido `garantir_invulneravel` |

**Output Range:** distância total = `distancia_px` sem parede. Com E = 0 a
invulnerabilidade acaba **antes** do último deslocamento (cauda −1); com E = 1,
junto com ele; com E = 2 (cânone), sobra 1 passo de cauda. E < 1 é aviso (CV15).
**Example:** Lâmina: N = 10, d = 33 px por passo, 330 px. inv = 12: protege do s
ao s+11; os deslocamentos vão do s+1 ao s+10; cauda de 1 passo. Contra Eco,
acerta a ≤ 93 px; a faixa varrida tem 186 px de largura. Hitstop 6 no 1º alvo e
3 nos seguintes.

### F7. Empurrão: soma, queda, distância e passos

The knockback_travel formula is defined as:

`v0 = |vel_atual + Σ dir_j × emp_efetivo_j|` (soma vetorial) ; em cada passo
vivo, se `|v| > 0`: anda `v/60`, depois `v ×= q`, e zera se `|v| < z` ;
`n = 0` se v0 = 0 ; senão `n = max(1, floor(ln(z / v0) / ln(q)) + 1)` ;
`dist = (v0/60) × (1 − q^n) / (1 − q)` ; `dist_∞ = v0 / (60 × (1 − q))`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| v0 | float | ≥ 0 px/s | calculated | módulo da soma; golpes opostos se cancelam |
| q | float | 0,5–0,95 (0,78) | data file | `queda_empurrao` |
| z | float | 0,9–30 (4,5) px/s | data file | `empurrao_zero` |
| n | int | ≥ 0 | calculated | passos com movimento |
| dist | float | ≥ 0 px | calculated | percurso sem parede |

**Output Range:** `dist` < `dist_∞` = v0 × 0,0758 (com q 0,78). É finito só com
0 < q < 1 e z > 0 (CV6). Para golpes do item 5 em alvo que sobrevive, o primeiro
movimento é no mesmo passo do golpe (o item 7 da R1 vem depois do item 5); acertos
do item 8 (projétil) e do item 9 (explosão) empurram a partir do passo seguinte.
O alvo que morre não anda (R14); o corpo desliza só na apresentação
(Visual/Audio V12).
**Example (q 0,78, z 4,5):**

| Fonte | v0 (px/s) | n (passos) | dist (px) |
|---|---|---|---|
| Pulso (Armas R2) | 540 | 20 (0,33 s) | 40,62 |
| Dado de teste com 270 (FP-R) | 270 | 17 (0,28 s) | 20,16 |
| Corte | 450 | 19 | 33,79 |
| Finalizador | 900 | 22 (0,37 s) | 67,89 |
| Investida | 1080 | 23 | 81,55 |
| Onda | 1260 | 23 | 95,14 |
| Finalizador contra elite | 360 | 18 | 26,96 |

### F8. Impacto na parede

The wall_slam formula is defined as:

`bate = corrigida ∧ v ≥ parede_vel_min` (v medido **antes** de mover;
"corrigida" = presa por parede ou obstáculo da câmara, **não** pela separação
entre inimigos, que é da IA) ;
`k_p = v0 ≥ p ? floor(ln(p / v0) / ln(q)) + 1 : 0` ;
`alcance_parede = (v0/60) × (1 − q^k_p) / (1 − q)` ;
`dano_parede = parede_dano × M_parede`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| p | float | 460–900 px/s (630) | data file | `parede_vel_min` |
| v0, q | float | — | calculated / data file | F7 |
| k_p | int | ≥ 0 | calculated | deslocamentos com v ≥ p |
| alcance_parede | float | ≥ 0 px | calculated | o inimigo bate se o vão entre a borda dele e a parede for < alcance_parede (parede perpendicular) |
| parede_dano | float | 0–30 (8) | data file | `CombatTuning` |
| M_parede | float | ≥ 0 | calculated | F2, grupo Ataque, sem `apos_esquiva` nem 4º acerto |

**Output Range:** dano ≥ 0. Na batida, o empurrão zera, o hitstop é leve, o
impacto não é pesado e não há cambaleio (empurrão 0).
**Example (p 630):** finalizador 900: k_p = 2 (900, 702), janela **26,7 px**.
Investida 1080: k_p = 3, 43,0 px. Onda 1260: k_p = 3, 50,2 px. Corte 450 e Pulso
270 nunca batem. Contra elite (× 0,4), nenhuma arma atual bate (360, 432, 504).
Dano 8, ou 10 com +25% Ataque.

### F9. Hitstop

The hitstop_total formula is defined as:

`h(passo) = max(pedidos do passo)` (num passo vivo o contador é sempre 0, então
"vale o maior" decide dentro do passo) ; `congelado = Σ h(passo)` ;
`f_cong = congelado / (vivos + congelado)` ; em combo sustentado de n golpes:
`f_cong = Σ h_i / (n × R + Σ h_i)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| pedidos | int | 1–90 | data file | tabela da R10 convertida por passos(); mínimo 1 passo |
| h | int | 0–90 | calculated | passos congelados depois daquele passo |
| f_cong | float | 0–1 | calculated | fração do tempo real congelada |

**Output Range:** h ≤ o maior campo de hitstop do Tuning (hoje o abate de chefe, 36). Os passos congelados não descontam
recargas nem invulnerabilidade: o hitstop alonga o tempo real sem comer o tempo
vivo. Um modo de acessibilidade que encurte o hitstop é do GDD de Acessibilidade
e opções (multiplicador separado), não deste Tuning.
**Example:** combo da Lâmina num Eco (o 3º golpe mata): 3 + 3 + max(6, 4) = 12
congelados; o abate sai a 32 passos vivos + 6 congelados = **38 passos
(0,633 s)**. Lâmina sustentada: f_cong = 12 / 60 = 0,20. Abate do chefe: 36; os
reforços zerados morrem no passe seguinte com 4, e o máximo segue 36 (0,6 s).

### F10. Dano no jogador

The player_damage_resolution formula is defined as:

`dano` e `vida_perdida`: **F3 do Modificadores** (não reescrita) ; se
invulnerável ou fora de combate: nada ; senão
`inv' = passos(invuln_atingido_s)` ;
`refletido = vida_perdida × valor(refletir_dano)` se o atacante é corpo a corpo e
`vida_perdida > 0` ; se Vida ≤ 0 e recusas ≥ 1:
`Vida = max(1, round(vida_max × vida_ao_voltar))`, `inv = passos(invuln_s)` ;
teto de dano = `dano` a cada `passos(invuln_atingido_s)` passos vivos (global: a invulnerabilidade é única)

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| dano, vida_perdida | int | ≥ 1 / ≥ 0 | calculated | F3 do Modificadores |
| invuln_atingido_s | float | 0,25–1,5 (0,6667) | data file | `CombatTuning` |
| valor(refletir_dano) | float | > 0 | calculated | já inclui o × 3 do cânone |
| vida_ao_voltar | float | 0–1 (0,4) | data file | param de `recusas_morte` |
| invuln_s | float | > 0 (2,0) | data file | param de `recusas_morte` |

**Output Range:** uma fonte tira no máximo `dano` a cada 40 passos vivos (46 em
tempo real, com o hitstop de 6). A recusa nunca devolve Vida 0 (`max(1, …)`).
**Example:** Eco: 9 → teto de 13,5 Vida/s vivo (11,7/s real). Fenda elite:
13 × 1,25 = 16,25 → 16; com Voo do Escudo (0,12): 14,3 → 14; com escudo 10:
Vida perdida 4, invulnerabilidade 40. Refletir 3,0 sobre 4 devolve 12. Recusa
com `vida_max` 100: Vida 40, invulnerabilidade 120.

### F11. DPS de referência

The weapon_dps_ref formula is defined as:

`c̄ = R < J ? média(combo) : combo[0]` (1 sem lista) ;
`DPS_vivo = dano × M × c̄ × 60 / R` ;
`DPS_real = dano × M × Σc × 60 / (n × R + Σ h_i)` (cada golpe com ≥ 1 alvo, sem
abates)

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| dano, combo, R | — | F1 | data file | `AttackDef` |
| J | int | 31–60 (34) | calculated | janela de combo |
| M | float | ≥ 0 | calculated | F2 do Modificadores (1 sem bênção) |
| h_i | int | — | calculated | hitstop do golpe i (F9) |
| DPS | float | ≥ 0 por alvo | calculated | Vida/s por alvo |

**Output Range:** ≥ 0. R ≥ 1 por validação. Com R ≥ J, o combo reseta antes de
todo golpe e o finalizador nunca sai (CV5).
**Example (M = 1, por alvo):**

| Golpe | DPS vivo | DPS real |
|---|---|---|
| Corte com combo | 53,2 × 60 / 48 = **66,5** | 53,2 × 60 / 60 = **53,2** |
| Corte sem combo | 52,5 | 44,2 |
| Investida | 22,3 | 20,5 |
| Pulso | 51,4 | 51,4 (sem hitstop) |
| Onda | 20,0 por alvo, em área | 18,75 |

Leitura: em tempo real, o Pulso (de longe) quase empata com o Corte (de perto),
porque o hitstop "cobra" ~20% da Lâmina. Chefe (700) sem esquivas: Lâmina
13,2 s, Pulso 13,6 s.

### Faixas do `CombatTuning`

| Campo | Inicial | Faixa | O que quebra fora dela |
|---|---|---|---|
| `hitstop_leve_s` | 0,05 (3) | 0,0167–0,1 (1–6) | acima de 6 o golpe rápido parece lento; dentro das faixas, o CV2 (f_cong > 0,33) só dispara no canto leve 6 + pesado 12 (0,333) |
| `hitstop_pesado_s` | 0,1 (6) | 0,05–0,2 (3–12) | abaixo do leve, o pesado parece fraco (CV1) |
| `hitstop_abate_s` | 0,0667 (4) | 0,0167–0,2 (1–12) | ondas grandes congelam demais |
| `hitstop_atingido_s` | 0,1 (6) | 0,0333–0,25 (2–15) | abaixo, o golpe recebido não se lê; acima, esconde o telégrafo seguinte |
| `hitstop_abate_chefe_s` | 0,6 (36) | 0,2–1,5 (12–90) | acima de 1,5 s parece travamento |
| `hitstop_recusa_s` | 0,3 (18) | 0,1–0,6 (6–36) | abaixo de 6, o *impact frame* da recusa não se lê |
| `empurrao_pesado` | 900 px/s | 460–1080 | ≤ 450: todo Corte quebra preparação; > 1080: a Investida deixa de ser pesada; > 1260, a Onda |
| `limiar_finalizador` | 1,2 | 1,0–1,45 | < 1: tudo é pesado; ≥ 1,8 a Lâmina perde o finalizador |
| `janela_combo_s` | 0,5667 (34) | 0,5167–1,0 (31–60) | curta demais mata combos (CV5); > 1 s o reset some na prática |
| `recuperacao_max_s` | 0,2 (12) | 0,0167–0,5 (1–30) | acima de 30, a Onda prende o jogador 0,5 s lento |
| `fator_recuperacao_golpe` | 0,5 | 0–1 | > 1: CV9; 0 = sem recuperação |
| `passo_apoio_px` | 10,5 | 0–24 (aceita 0) | ≥ 49,5 atravessa inimigo (CV14) |
| `folga_encostado_px` | 6 | 0–20 | grande: as costas viram zona de acerto (CV19) |
| `nascimento_projetil_px` | 36 | 27–60 | < 27 nasce dentro do corpo; > 60 cria zona cega (CV20) |
| `invuln_extra_investida_s` | 0,0333 (2) | 0–0,1 (0–6), aceita 0 | 0: cauda −1 (CV15) |
| `cambaleio_s` | 0,1333 (8) | 0,0167–0,15 (1–9) | ≥ menor recarga de golpe com empurrão: inimigo lento para sempre (CV17) |
| `fator_cambaleio` | 0,4 | 0–1 | 0 congela o andar da IA (não o relógio dela) |
| `quebrou_recuperacao_s` | 0,4 (24) | 0,1667–0,8 (10–48) | perto de n × R − preparo: trava (CV18) |
| `parede_vel_min` | 630 px/s | 460–900 | ≤ 450: Corte bate na parede; > 900: finalizador não bate |
| `parede_dano` | 8 | 0–30 | > 30: a parede vira a arma principal |
| `queda_empurrao` | 0,78 | 0,5–0,95 | ≥ 1 nunca para |
| `empurrao_zero` | 4,5 px/s | 0,9–30 | 0: nunca zera; acima de ~50: o empurrão do Pulso no chefe (540 × 0,12 = 64,8) some no 2º passo |
| `invuln_atingido_s` | 0,6667 (40) | 0,25–1,5 (15–90) | < 15: dois inimigos encadeiam acertos; > 90: a esquiva perde valor |
| `passes_varredura` | 4 | 1–8 (int) | 0: ninguém morre |
| `fator_guarda` | 0,5 | 0–1 | 1 anula a guarda; 0 deixa o jogador imune com a guarda |
| `giro_leque_graus` | 12 | 3–45 | leque muito aberto deixa buracos entre projéteis |
| `fator_raio_obstaculo_projetil` | 0,5 | 0–1 | 1 faz o projétil sumir antes de encostar visualmente |
| `flash_acerto_s` | 0,0833 (5) | 0,0167–0,1667 (1–10) | acima de 10, o flash de um Corte encosta no do Corte seguinte (R = 16) e o inimigo parece sempre aceso |
| `extra_inversao_s` | 0,0667 (4) | 0,0333–0,1667 (2–10) | abaixo de 2, a inversão some com o hitstop (§5.5 pede ≥ 2 quadros); acima de 10, ela cobre a animação Dano |
| `impact_chefe_s` | 0,2 (12) | 0,0833–0,6 (5–36) | abaixo de 5 não se lê; acima do hitstop do chefe, passa do congelamento (CV22) |

As relações entre campos (pesado ≥ leve, recusa ≥ atingido) são o aviso CV1,
não erro de faixa. Os campos de hitstop **não aceitam zero** (mínimo 1 passo; F7 do Conteúdo).
`invuln_extra_investida_s` e `passo_apoio_px` aceitam.

### Validação do `CombatTuning` e dos `AttackDef`

Somam-se às faixas do V2 do Conteúdo. Os **erros** vão para a tela de erros do
catálogo e a run não começa; os **avisos** ficam no registro de validação.

| Regra | Tipo | Condição | Por quê |
|---|---|---|---|
| CV1 | aviso | fora da ordem leve ≤ abate ≤ pesado ≤ abate_chefe, ou leve > atingido, ou atingido > abate_chefe, ou recusa < atingido, ou recusa > abate_chefe | "vale o maior" pede a hierarquia (hoje 3 ≤ 4 ≤ 6 ≤ 36) |
| CV2 | aviso | `f_cong` (F9) > 0,33 em alguma arma com combo sustentado | o congelado domina (Lâmina 0,20) |
| CV3 | erro / aviso | erro: `limiar_finalizador` < 1. Aviso: combo sem entrada > limiar, ou com mais de uma | finalizador ausente ou duplicado |
| CV4 | erro | entrada de combo ≤ 0, ou lista vazia (erro; arma sem combo = campo ausente) | dano negativo cura; `mod 0` |
| CV5 | erro | `AttackDef` com combo e R ≥ J | o combo reseta antes do disparo e nunca avança (Lâmina: margem 18) |
| CV6 | erro / aviso | erro: `empurrao_zero` ≤ 0, ou `queda_empurrao` ∉ (0, 1). Aviso: `empurrao_zero` ≥ menor empurrão efetivo do catálogo (menor `empurrao` > 0 entre os `AttackDef` e o Corte da esquiva, × o menor `fator_empurrao`, inclusive o do chefe) | o empurrão nunca zera, ou zera no 1º passo |
| CV7 | erro / aviso | erro: `parede_vel_min` ≤ `empurrao_zero`. Aviso: ≤ maior empurrão leve (Ataques sem finalizador e o Corte da esquiva), ou > `empurrao_pesado` | golpe leve bateria na parede, ou o finalizador não bateria |
| CV8 | aviso | algum Ataque tem `empurrao` ≥ `empurrao_pesado` | todo acerto daquele Ataque quebraria a preparação |
| CV9 | erro | `fator_recuperacao_golpe` ∉ [0, 1] | lento sem parar |
| CV10 | erro | R = 0 em algum `AttackDef` | um golpe por passo |
| CV11 | erro | `passes_varredura` < 1 | ninguém morre |
| CV12 | erro / aviso, cruzada com Inimigos | erro: `s` > 2 × (`raio_px` + r_min). Aviso: `s` > `raio_px` + r_min | o projétil pularia inimigos (Pulso 16,5 contra 37,5) |
| CV13 | erro | L < 2 | o projétil nunca testa acerto |
| CV14 | aviso | `passo_apoio_px` ≥ `raio_jogador_px` + r_min, ou ≥ `r_obs_min` + `raio_jogador_px` | o passo de apoio atravessaria um corpo |
| CV15 | erro / aviso | erro: R da investida ≤ N + E. Aviso: (N + E) / R > 0,5, ou E < 1 | invulnerabilidade perpétua (hoje 12 / 70) |
| CV16 | aviso | `distancia_px` / N > 2 × (`raio_px` + r_min) | a investida pularia alvos (33 contra 183) |
| CV17 | aviso | passos(`cambaleio_s`) ≥ menor R entre golpes com empurrão > 0 | inimigo comum lento para sempre (MVP: 8 contra 14) |
| CV18 | aviso, cruzada com IA | existe inimigo comum e arma com combo com Q ≤ n × R < Q + W e Vida > dano × Σc (n = entradas do combo, Q = passos(`quebrou_recuperacao_s`), W = preparo do `EnemyDef`) | o finalizador quebraria toda preparação (trava). MVP: não dispara |
| CV19 | aviso | `raio_jogador_px` + `folga_encostado_px` ≥ menor `alcance_px` de arco | o encostado vira o arco inteiro |
| CV20 | aviso | `nascimento_projetil_px` + s − (`raio_px` + r_min) > `raio_jogador_px` + r_min | zona cega à queima-roupa |
| CV21 | aviso | passos(`invuln_atingido_s`) ≤ passos(`hitstop_atingido_s`) | congelamento maior que a proteção |
| CV22 | aviso | passos(`impact_chefe_s`) > passos(`hitstop_abate_chefe_s`), ou passos(`hitstop_atingido_s`) + passos(`extra_inversao_s`) ≥ passos(`invuln_atingido_s`) | o *impact frame* do chefe passa do congelamento, ou a inversão cobre toda a invulnerabilidade |

**Saída do validador:** uma entrada por regra e por objeto; o erro vence o aviso
da mesma regra; o CV1 é uma entrada só, com todas as causas; o CV3 é avaliado
mesmo numa lista de combo recusada pelo CV4.

O CV12, o CV14, o CV16, o CV17 e o CV18 dependem de dados de outros sistemas
(inimigos, câmaras): rodam onde o MV1 do Movimento roda (Movimento OQ3).

## Edge Cases

> `systems-designer` não consultado nesta seção: modo Lean. Os pontos de limite
> que ele levantou em Formulas estão incorporados. Revisar manualmente.

**Disparo**

- **Se Ataque e Especial chegarem no mesmo passo, com as duas recargas em 0:**
  sai o Especial (R3). O Ataque fica no buffer ou segurado e sai no primeiro
  passo em que puder.
- **Se o golpe for tocado durante a esquiva:** fica no buffer e sai no último
  passo da esquiva, quando "em esquiva" já é falsa (Movimento R6), se a recarga
  for 0 e o prazo não tiver acabado.
- **Se o golpe for tocado durante o hitstop:** o prazo do buffer fica parado
  (Input R6) e o golpe sai no primeiro passo vivo em que a recarga for 0.
- **Se o golpe for tocado durante uma investida:** fica no buffer; sai no último
  passo da investida (R6), se o prazo do buffer não tiver acabado. Com N > 10,
  um toque feito cedo se perde; segurar o botão funciona.
- **Se o golpe não acertar ninguém:** o combo avança, a janela `apos_esquiva`
  fecha, a recarga e a recuperação começam e o passo de apoio do arco acontece
  (cânone). Sai o evento `golpe`, sem hitstop.
- **Se o golpe sair em câmara limpa:** sai normalmente, sem alvos (cânone).
- **Se a janela `apos_esquiva` estiver aberta e o golpe sair no último passo da
  esquiva:** o bônus vale (R3, item 2) e a janela fecha.

**Formas**

- **Se um inimigo estiver exatamente na borda do alcance:** é atingido (`≤`,
  F4). Exatamente na borda do anel de encostado: não conta como encostado (`<`).
- **Se vários inimigos estiverem no arco:** todos são atingidos, na ordem
  estável da lista; o hitstop é um só, do golpe (R4).
- **Se o 4º acerto cair no meio de um golpe com vários alvos:** o contador sobe
  por alvo; só o alvo cujo número for múltiplo de `a_cada` recebe `M_com` e
  conta como pesado (F1).
- **Se a investida bater na parede ou num obstáculo:** o Movimento prende o
  jogador (Movimento R10); a investida segue os N passos e continua testando
  alvos na posição presa.
- **Se a esquiva cancelar a investida no meio:** os alvos já atingidos ficam
  atingidos; a invulnerabilidade que sobrou continua (vale o maior, Movimento
  F4); a recarga do slot não volta.
- **Se o projétil nascer dentro de um obstáculo ou fora do retângulo:** some no
  primeiro passo de voo, sem acertar (R7).
- **Se o projétil do jogador passar por um inimigo surgindo:** não o atinge e
  continua (R9).

**Impacto em inimigo**

- **Se o dano for maior que a Vida restante:** a Vida fica negativa; o excesso
  não passa para outro alvo. O inimigo morre na varredura (R14).
- **Se o dano for 0** (M = 0): empurrão, cambaleio, status e `acerto_de_arma`
  acontecem mesmo assim (cânone).
- **Se o golpe matar o alvo:** não há "Quebrou!" (exige Vida > 0), e o alvo
  morto não age mais neste passo (R14).
- **Se um golpe pesado acertar um inimigo já em execução:** não cancela; só a
  preparação é quebrada (R8).
- **Se dois golpes empurrarem o mesmo inimigo em direções opostas no mesmo
  passo:** os vetores se somam e podem se anular (F7).
- **Se um elite ou chefe receber golpes seguidos:** não cambaleia nem quebra,
  mas o empurrão se acumula e pode passar de `parede_vel_min` (F8).
- **Se o inimigo for empurrado contra um canto:** é preso pelas duas bordas; a
  batida acontece uma vez, porque o empurrão zera nela (R11).
- **Se o inimigo for empurrado contra outro inimigo:** não é batida na parede
  (R11); a separação é da IA.

**Hitstop**

- **Se vários hitstops forem pedidos no mesmo passo** (golpe pesado e abate):
  vale o maior (R10).
- **Se uma cadeia de mortes passar de 4 passes:** os mortos que sobram morrem no
  próximo passo vivo, com o hitstop de abate deles naquele passo (R14).
- **Se a câmara trocar com hitstop ativo:** o contador zera (R10).
- **Se o chefe morrer:** os outros inimigos são zerados e morrem no passe
  seguinte; o hitstop continua 36, porque o deles (4) é menor.

**Dano no jogador**

- **Se dois inimigos acertarem o jogador no mesmo passo:** o primeiro na ordem
  estável aplica o dano; o segundo encontra a invulnerabilidade e não faz nada
  (R13).
- **Se o escudo absorver todo o dano:** Vida perdida 0, mas a invulnerabilidade
  de 40 passos, o hitstop e o evento acontecem (cânone). Não há reflexo (exige
  Vida perdida > 0).
- **Se o reflexo matar o atacante:** a Vida dele fica ≤ 0 e ele sai na
  varredura do fim do passo.
- **Se um projétil inimigo encontrar o jogador invulnerável** (esquiva,
  investida, golpe recebido): atravessa e continua; pode acertar depois que a
  invulnerabilidade acabar, se ainda estiver no corpo dele (R7).
- **Se o jogador for atingido em câmara limpa:** nada acontece (R13, item 1).
- **Se o jogador morrer e o último inimigo morrer no mesmo passo:** a morte
  vence. O Input sai de Jogo e a câmara não conta como limpa (dono: Câmaras e
  ondas, que ignora "câmara limpa" depois de `jogador_morreu`).
- **Se houver mais de uma recusa de morte:** cada morte gasta uma (R13).
- **Se `vida_max` mudar no meio do combate:** a Vida atual segue a F4 do
  Modificadores.

**Mortes**

- **Se um inimigo morrer por status** (Sangramento, Queimadura): é uma morte
  como outra. Dispara `cura_ao_abater`, `explosao_ao_abater` e o hitstop de
  abate.
- **Se `cura_ao_abater` acontecer com a Vida cheia:** a cura é limitada a
  `vida_max`.
- **Se a explosão ao abater pegar um chefe:** o chefe recebe o dano (sem M).

**Dados**

- **Se o `CombatTuning` não estiver disponível** (catálogo em Falhou): o Combate
  não roda e a run não começa (Conteúdo R12). Não há valor padrão escondido no
  código.
- **Se um `AttackDef` citar uma forma não registrada:** é erro de validação do
  Conteúdo (V4), e a run não começa.

**Conflitos com outros GDDs:** nenhum. O prazo do buffer congelado no hitstop é
o da R6 do Input; os pisos de dano e a F3 são do Modificadores; o contrato com o
Movimento (pedidos, `deslocar(v)`, desconto da invulnerabilidade, "em esquiva")
é honrado como está.

## Dependencies

**Depende de (upstream)**

| Sistema | Tipo | O que vem de lá | Sem ele |
|---|---|---|---|
| Movimento e esquiva | Forte, **por contrato** | posição e raio do jogador, "em esquiva" (Movimento R6), execução de `deslocar(v)` e da investida (R9), pedidos `cancelar`, `garantir_invulneravel`, `aplicar_corte`, `esquiva_iniciada` | não há golpe nem esquiva que cancele |
| Modificadores e atributos | Forte | `valor`, `multiplicador_de_dano` (F2), F3, F4, gatilhos (`refletir_dano`, `recusas_morte`, `explosao_ao_abater`, `cura_ao_abater`, `dano_enesimo_acerto`), `fator_empurrao` | dano sem bênçãos, sem elite, sem Abalo |
| Conteúdo orientado a dados | Forte | `AttackDef` (formas registradas), `CombatTuning`, conversões F1, F2, F4, F5, F6, F7, tela de erros para CV1–CV22 | números no código, o que a regra do projeto proíbe |
| Input e controle | Forte | Ataque e Especial (toque, segurado, buffer), mira unitária (Input R2, R5, R6) | não há comando |
| IA de inimigos e elites | Forte, **por contrato** | lista de inimigos (posição, raio, ordem estável), estado (surgindo, em preparação, em execução), elite e chefe; executa o pedido de "Quebrou!" e chama `ferir_jogador` e `disparar_projetil` | não há em quem bater |
| Câmaras e ondas | Suave, **por contrato** | retângulo jogável e obstáculos (parede, projéteis), pedido de troca de câmara (Transição, R1), consulta "em combate" (R13.1) | câmara padrão de 1920×1080 sem obstáculos (a mesma regra da Cena), sempre "em combate" |

**Ciclos resolvidos por contrato**

- **Movimento ↔ Combate.** O Movimento define a interface (consultas e
  pedidos); o Combate a implementa e ela é injetada (Movimento, Dependencies).
  Este GDD honra o contrato como está.
- **Combate ↔ IA.** A IA depende do Combate (dano, cambaleio, "Quebrou!"); o
  Combate precisa do estado da IA e da lista de inimigos. **Resolução:** o
  Combate define a interface (estado do inimigo, pedido de "Quebrou!",
  `ferir_jogador`, `disparar_projetil`); a IA a implementa e chama, por
  injeção. Nenhum dos dois chama a lógica interna do outro. Falta registrar em
  "Circular Dependencies" do índice (Open Questions).

**É dependência de (downstream)**

| Sistema | Tipo | O que recebe |
|---|---|---|
| Movimento e esquiva | Forte | "em recuperação", investida ativa e `d`, `contexto_de_dano`, `deslocar(v)` |
| Armas das Doutrinas | Forte | as 4 formas, combo, recarga, recuperação; Armas só escolhe os números do `AttackDef` |
| Selo e Fluxo | Forte | `acerto_de_arma` (Fluxo), `ferir_inimigo` (dano do Selo), "hitstop ativo" |
| Efeitos de status | Forte | status do golpe e do Corte, `acerto_de_arma` (`golpe_*`), `ferir_inimigo` (dano por passo) |
| Telégrafos | Forte | `ferir_jogador`; a forma do telégrafo tem de ser a do teste de acerto (R13) |
| IA de inimigos e elites | Forte | "cambaleando", pedido de "Quebrou!", `ferir_jogador`, `disparar_projetil` |
| Câmaras e ondas | Suave | abates, `jogador_morreu` (ignorar "câmara limpa" depois dela); "câmara limpa" só com hitstop 0 (R10) |
| Pipeline visual | Suave | durações visuais nos eventos (R15, R17); estado de jogo e "câmara nova" (R1) |
| Run e regiões | Suave | `jogador_morreu` |
| Chefes (fatia vertical) | Forte | armadura, `hitstop_abate_chefe`, morte do chefe zera os outros (R14) |
| Cena 3/4 e câmera | Suave | eventos para chute, tremor e zoom (Cena F5) |
| HUD | Suave | Vida, escudo, recusas, eventos `jogador_atingido` e `recusou_morte` |
| Feedback de combate (VFX) / Áudio | Suave | todos os eventos da R1–R14 |
| Telemetria local | Suave | `jogador_morreu` (causa), abates |

**Bidirecionalidade:**

- Movimento, Modificadores, Conteúdo e Input já listam o Combate (Movimento
  Dependencies; Modificadores l. 562; Conteúdo l. 770; Input, consumidores do
  buffer). O contrato do Movimento (OQ2) foi honrado sem mudança.
- Selo, Status, Telégrafos, IA, Câmaras, HUD, Feedback de combate, Pipeline, Run e
  Telemetria já existem (2026-11-12); **Chefes continua não existindo** (e o Áudio
  não tem GDD próprio). Telégrafos, Câmaras, HUD e Feedback devem listar o
  "Combate núcleo" em Dependencies (a conferir) e honrar os contratos acima. O índice já tem o Combate no Depends
  On de Armas, Selo, Status, Telégrafos, IA, HUD e VFX.
- **Ajuste no índice:** a linha 8 do Combate lista Movimento, Modificadores,
  Conteúdo e Input; falta "IA de inimigos e elites (por contrato)" e "Câmaras e
  ondas (suave)".

## Visual/Audio Requirements

> `art-director` consultado (modo Lean). `audio-director` não consultado: o GDD
> de Áudio ainda não existe, e os requisitos de som são provisórios. Quadros a
> 60 passos/s; um quadro desenhado a 12 qps (Art Bible §5.8) dura 5 passos. Px a
> 1080p. Escolhas de sinal da invulnerabilidade, relógios do VFX, hitstop da
> recusa e abate de elite: usuário, 2026-11-09.

**Regra que governa tudo.** Todo golpe do jogador (arco, área, projétil,
investida, explosão de bênção) é **ação do jogador**: osso, manchas de tinta e
contorno **tracejado fino** (1,5–2 px; traço de 8 px, intervalo de 6 px;
proposta). Nunca usa a borda grossa de 4 px, o preenchimento que cresce, o
magenta ou L* ≥ 88, que são do telégrafo (Art Bible §1, §4.2, §4.3, §4.5). A
única exceção ao L* ≥ 88 é o *impact frame* (§4.2), só no abate de chefe e na
recusa de morte (V11, V12).

**Forma igual ao teste (P3).** O desenho de cada golpe tem o tamanho do teste de
acerto: o *smear* do arco vai até `alcance_px` com abertura
`meio_angulo_graus`; o anel da área tem `raio_px`; o projétil é desenhado com
`raio_px`; a frente da investida tem `raio_px`. Como o teste soma `r_inimigo`:
**se o corpo do inimigo encosta no desenho, ele foi atingido.**

**V1. Relógios e o que congela no hitstop**

- **Relógio vivo** (passos vivos; congela no hitstop, na pausa e na Bênção):
  sprites e rig de jogador e inimigos, *smear*, imagens residuais (Movimento
  V3), flash de acerto, projéteis, telégrafos, animações de morte e partículas
  de status e de dissipação. Emissores do relógio vivo recebem `speed_scale` 0
  no hitstop, porque o hitstop não usa `time_scale` (Cena R7).
- **Relógio de apresentação** (tempo real; corre no hitstop, para na pausa e na
  Bênção): impulsos de câmera (Cena R8), flipbook de impacto e suas fagulhas,
  números de dano, letreiro "Quebrou!", *impact frame*, névoa, feixes e
  pulsação dos veios. O ambiente não congela de propósito: num hitstop de
  0,1 s a diferença não se vê.
- **Pose no hitstop:** o jogador segura o quadro de contato com o *smear*
  visível ("painel de quadrinho"); o inimigo segura o flash na posição em
  que o passo do golpe o deixou (se sobreviveu a um golpe do item 5, o item 7
  da R1 já aplicou o primeiro deslocamento do empurrão, F7). Sobre a cena
  congelada, a estrela de impacto, o número e a câmera se mexem.
- **Câmara nova** (quadro da metade do wipe, R1) zera o hitstop (R10) e apaga
  os VFX dos dois relógios.

**V2. `golpe` (forma arco)**

- **Sem antecipação visível:** o acerto é no passo do toque (R3), então o
  primeiro quadro já é o contato com o *smear* (o P3 vence a antecipação do
  §5.8, como na esquiva). A antecipação **mora na recuperação do golpe
  anterior**: o último quadro de saída do golpe n é a pose de preparo do n+1.
- **Quadros:** contato com *smear*, 1 quadro (5 passos); continuação, 2–3
  quadros de 5 passos, todos aceitáveis se cortados pela esquiva ou pelo
  próximo golpe.
- **Smear:** meia-lua de tinta **aberta** (nunca setor fechado), miolo L* ≤ 10
  afinando nas pontas, fio de luz em osso de mundo `#CFC6B4` (L* 78–82) na
  borda de fora, contorno tracejado fino só no raio de fora (`alcance_px`);
  some em 2 quadros em 3–5 manchas de tinta. O finalizador tem arco 20% mais
  grosso e 1 mancha a mais na direção da mira.
- **Sem alvo:** o *smear* toca igual, sem hitstop, câmera nem fagulha. O passo
  de apoio não tem VFX próprio.

**V3. `area` (forma círculo)**

- 1 quadro de gesto (por arma), com a antecipação da V2.
- **Anel tracejado fino em osso** (L* ≤ 82), centrado em jogador + mira ×
  `deslocamento_px`, que **expande** de 40% a 100% de `raio_px` em 4 passos e
  some em 6 (≤ 10 passos). **Nunca** preenchido, parado no chão ou de borda
  grossa. 4–6 manchas de tinta saltam no raio final. O telégrafo cresce por
  dentro e permanece; a área do jogador é contorno que se abre e some (exceção
  do Selo, §4.3, estendida à área: linha nova no Art Bible).
- **Camada:** sombras e telégrafos (z −5), **abaixo** de qualquer telégrafo
  ativo.

**V4. `disparo` e projétil do jogador**

- 1 quadro de disparo com recuo do corpo (rig) e 2 de saída cortáveis.
- Respingo de tinta em `nascimento_projetil_px`, 1 quadro, sem flash de luz.
- **Corpo:** glifo em osso (L* ≤ 82) com contorno de tinta de 2 px, raio visual
  = `raio_px`, rastro de 3 traços tracejados em tinta. **Nunca magenta** e nunca
  com a borda grossa dos projéteis inimigos. No leque, todos iguais.
- **Fim:** vida acabou, some em 2 quadros em tinta; obstáculo, respingo de 24 px
  na superfície. Sem hitstop e sem câmera (R6).

**V5. `investida` (forma avanço)**

- O passo do disparo mostra a pose agachada de arranque (1 quadro, 1 passo); o
  deslocamento começa no passo seguinte (R6).
- Pose esticada pelos N passos, depois 2–3 quadros de saída cortáveis.
- **Rastro:** pincelada de tinta sólida alongada atrás do jogador, aberta e
  afinando, pela duração + 6 passos; frente em arco osso tracejado com
  `raio_px`. **Não** usa as imagens residuais da esquiva (esquiva ≠ ataque) nem
  os fiapos do Eco (§3.2). A invulnerabilidade da investida não tem sinal
  próprio.

**V6. `acerto` em inimigo**

- **Flash** (todos): 1 quadro em osso, L* ~80 (§5.5), segurado no hitstop;
  `flash_acerto_s` (5 passos vivos; `flash_passos` do evento `acerto`, R17).
- **Tranco de cambaleio** (sem armadura, empurrão > 0): o rig inclina 8–12° para
  longe do golpe e volta em `cambaleio_s` (procedural: os inimigos não têm
  animação de dano; linha nova). **Elite e chefe:** flash e tranco de 3°, sem
  cambaleio.
- **Leve:** estrela de impacto de tinta de 64 px, 5–7 pontas anguladas,
  **aberta** (nunca disco), alongada 1,6:1 na direção do golpe, miolo osso
  L* 78–82; 3 quadros no relógio de apresentação (250 ms); fagulhas ≤ 8.
- **Pesado** (`peso_visual` pesado no evento `acerto`, R17): estrela de 112 px, mancha de tinta direcional de 140 px no
  sentido do empurrão, fagulhas ≤ 16.
- **Quarto acerto:** a estrela e a câmera seguem o `peso_visual` (R17; no
  projétil, leve), e o número sai sempre em dourado (V7). Nenhum outro
  dourado no VFX de combate (o dourado é da aura de elite, §4.3). O "crítico" do
  §7.7 é o quarto acerto no MVP.
- **Refletir e explosão:** visual leve, sem fagulha. **Status por passo:** sem
  flash (não emite `acerto`).

**V7. Número de dano: aparece** (Art Bible §7.7; §7.9 nº 7, ligado por padrão)

- A leitura principal do acerto é flash, hitstop, empurrão e estrela; o número
  é secundária, para avaliar a build (P1). O fio de Vida diz quanto falta; o
  número diz quanto valeu.
- Osso `#CFC6B4` 28 px com contorno de tinta de 2 px; quarto acerto 36 px
  dourado. Nasce acima da cabeça, 130% → 100% em 2 quadros, sobe 24 px e some
  em ≤ 0,6 s, no relógio de apresentação. Golpes no mesmo alvo em 300 ms somam
  num número; até 6 números na tela.
- O número mostra o valor arredondado; fração < 0,5 não gera número e entra na
  soma. Dano no jogador nunca gera número. Número de status é do GDD de Efeitos de status (R8: agregado a cada 0,5 s).

**V8. `parede`**

- Meia estrela de tinta de 96 px colada na parede, miolo osso; poeira na névoa
  da região (L* ≤ 45); rachadura de tinta só na parede (nunca no chão de
  combate), some em 2 s.
- Inimigo: novo flash e 1 quadro de esmagamento (rig). Hitstop leve. Número com
  o dano.

**V9. `quebrou` ("Quebrou!")** — a ameaça sumiu.

1. **O telégrafo do alvo se parte** (requisito para o GDD de Telégrafos): uma
   rachadura de tinta atravessa o preenchimento em 2 quadros e ele some, **sem**
   o flash de disparo.
2. **Corpo:** pose de recuo (rig); marca estática de três traços quebrados em
   tinta e osso, 32 px, acima da cabeça por `quebrou_recuperacao_s`
   ("vulnerável"). Não pulsa.
3. **Letreiro "Quebrou!"** (onomatopeia de quadrinho, §7.7): ~44 px, osso
   `#E6DFCF`, contorno de tinta de 3 px, letras anguladas a −8°, no mundo, 24 px
   acima do número; 130% → 100% em 2 quadros, some em ≤ 0,6 s, no relógio de
   apresentação. Só osso e tinta: lê em tons de cinza.
4. **Vários no mesmo passo:** um letreiro só (primeiro alvo da lista); os outros
   ganham marca e telégrafo partido; até 2 letreiros na tela.
5. Com a opção Números de dano "desligado", o letreiro some; a informação fica no
   telégrafo partido e na marca.
6. Nenhum impulso de câmera a mais.

**V10. `jogador_atingido`**

- **Inversão de silhueta** (§5.5, exclusiva deste evento): tinta chapada com
  contorno em osso, pelos passos de hitstop + `extra_inversao_s` (4 passos
  vivos; `inversao_passos` do evento, R17); depois a animação
  Dano (2–3 quadros), cortável pela esquiva.
- **Invulnerabilidade pós-dano:** o contorno do Iniciado fica **tracejado em
  osso** pelo tempo exato da invulnerabilidade, sem piscar e sem mudar a
  luminosidade (não conta como flash). Distinto das imagens residuais da
  esquiva. Linha nova no Art Bible; viabilidade com o technical-artist.
- **Tela:** nada de tela cheia, sem vermelho. Segmento rachado e vinheta de Vida
  baixa são do HUD (§7.7, §7.8).
- **Escudo absorveu tudo:** a inversão acontece igual; o HUD não racha segmento.

**V11. `recusou_morte`** — a morte (§2.8) revertida.

- **Impact frame:** a tela vai a tinta chapada (L* ≤ 10) com o Iniciado em osso
  pleno `#E6DFCF` (L* ≥ 88), segurado pelo hitstop da recusa
  (passos(`hitstop_recusa_s`) = 18 passos de apresentação; `impact_passos` do
  evento, R17), saindo em 1 quadro. Contornos dos telégrafos
  ativos e silhuetas dos inimigos continuam desenhados por cima, em osso (P3).
- Depois: manchas de tinta entram pelas bordas até 12% e recuam em 18 passos,
  **abaixo** de telégrafos e personagens.
- Corpo: contorno tracejado de invulnerabilidade (V10) pelos passos de
  `invuln_s`.

**V12. `inimigo_morreu`**

- **Todos:** animação de morte no relógio vivo, ≤ 30 passos, sem colisão, no
  y-sort; os passos do hitstop de abate mostram o flash. Ecos se desfazem em
  fiapos; Anomalias racham e o magenta sai em partículas (L* ≤ 70) que **sobem e
  se dispersam**, nunca assentam nem formam anel (§3.4).
- **Corpo desliza** (decisão do usuário, 2026-11-09): o morto não anda na
  lógica (R14), mas a animação de morte herda a direção e a velocidade do
  empurrão do golpe que o matou (`vel_empurrao` do evento), como deslizamento só
  de apresentação: decai × `queda_empurrao` por passo, sem colisão, sem dano e
  sem batida na parede. O golpe final continua parecendo forte (P3).
- **Comum:** estrela leve sobre o último quadro.
- **Elite:** a coroa de espinhos estilhaça em 2 quadros, a aura dourada se apaga
  sem flash, mancha de tinta de 192 px. **Sem** *impact frame*.
- **Chefe** (§2.9): *impact frame* em osso com manchas de tinta nos primeiros
  `impact_chefe_s` (12 passos de apresentação; `impact_passos` do evento, R17)
  dos 36 passos congelados; nos outros 24, a cena congelada
  com o chefe na pose de morte; depois a arena esquenta.

**V13. `explosao`** (bênção `explosao_ao_abater`) — poder do jogador.

- Anel osso tracejado expandindo até `raio_px` em 4 passos, com 6 manchas de
  tinta; **nunca magenta**. Sem hitstop próprio (o do abate cobre); os alvos
  recebem a V6 leve. Em cadeia, até 4 anéis simultâneos; os outros só a mancha
  de 48 px.

**V14. Impulsos de câmera pedidos à Cena (F5)**

| Evento | Preset | Escala | Direção |
|---|---|---|---|
| `golpe`/`area` sem alvo; `disparo`; início da `investida` | nenhum | — | — |
| `acerto` com `peso_visual` leve (arco, círculo, investida) | leve | 1,0 | mira |
| `acerto` com `peso_visual` pesado (arco, círculo, investida) | pesado | 1,0 | mira, ou `d` na investida |
| 2º alvo em diante da investida | leve | 0,5 | `d` |
| `acerto` de projétil com `peso_visual` leve (inclui o quarto acerto) | nenhum | — | — |
| `acerto` de projétil com `peso_visual` pesado (finalizador) | leve | 0,6 | voo |
| `parede` | leve | 1,0 | empurrão |
| `quebrou` | nenhum a mais | — | — |
| `jogador_atingido` | pesado | 1,0 | do atacante ao jogador (projétil: voo) |
| `recusou_morte` | pesado | 1,0 (zoom principal) | sem direção |
| `inimigo_morreu` comum / elite / chefe | leve 0,6 / pesado / chefe | — | sem direção |
| `explosao` | leve | 0,5 | sem direção |

- **Um impulso por passo, remetente único (Combate → Feedback → destino):** o
  Combate só **emite os eventos** da tabela acima; o **Feedback é o único
  remetente** do impulso de câmera à Cena e do pedido de impact frame ao
  Pipeline. O Feedback escolhe o maior preset do passo (chefe > pesado > leve;
  no mesmo preset, a maior `escala`), com a direção do evento que venceu, como o
  hitstop. Empate: `recusou_morte` vence `jogador_atingido`. "Sem direção" =
  vetor nulo (sobram tremor e zoom).
- **Tremor de câmera** (0–100%) multiplica chute e tremor; **Redução de
  movimento** desliga o zoom (Cena R8). O hitstop continua com as duas.

**V15. Orçamento em multidão** (9 inimigos; Art Bible §8.6)

- Até 6 estrelas criadas por passo; do 7º alvo em diante, só o flash.
- Fagulhas: um emissor por golpe, até 24 partículas; até 4 emissores de impacto
  ativos; teto global de 24 emissores. Até 40 flipbooks simultâneos; overdraw
  de VFX ≤ 0,5 tela.
- Acima do teto sai o mais antigo do relógio de apresentação; nunca se corta
  flash, telégrafo partido ou inversão.
- Ordem sobre o inimigo: estrela < flash < número < marca de vulnerável <
  "Quebrou!".

**A1. Áudio (requisito provisório; o audio-director decide)**

- **Regra herdada (§4.7):** nenhum som do Combate pode tornar inaudível a deixa
  sonora do telégrafo.
- **Fatos para o audio-director:** o hitstop congela o mundo, não o relógio de
  apresentação; `golpe`, `area`, `acerto`, `parede` e `quebrou` são emitidos no
  passo vivo anterior ao congelamento (R10).
- **Clima:** `golpe`/`area` risco de pincel seco (área mais grave); `disparo`
  estalo de tinta leve; `investida` rasgo de pincelada longo; acerto leve seco e
  abafado; pesado com corpo e grave; quarto acerto com timbre "consagrado", sem
  ser alegre; `parede` pedra e osso; `quebrou` algo que estala e se parte, curto
  e inconfundível; `jogador_atingido` corte seco distinto de todo acerto no
  inimigo; `recusou_morte` some e volta (a única "respiração"); morte de Eco
  sopro que se desfaz, de Anomalia cristal rachando, de elite o dourado se
  apagando, de chefe o silêncio do *impact frame* e a liberação; `explosao`
  tinta estourando, nunca o timbre do Fluxo.
- **Ordem de importância para a leitura** (insumo, não mixagem): 1. deixa do
  telégrafo; 2. `jogador_atingido` e `recusou_morte`; 3. `quebrou`; 4. abate de
  chefe; 5. acerto pesado, `parede`, abate de elite; 6. acerto leve, abate
  comum, `explosao`; 7. `golpe`, `area`, `disparo`, `investida`.
- Eventos iguais no mesmo passo soam como um só.

**AC1. Acessibilidade**

- **Daltonismo (§4.7):** nada depende de matiz. Golpe do jogador × telégrafo:
  tracejado fino sem preenchimento, L* ≤ 82, contra borda de 4 px,
  preenchimento que cresce e L* ≥ 88. Quarto acerto também pelo tamanho.
  "Quebrou!" em osso e tinta. Projétil do jogador nunca magenta. Todo print de
  aprovação passa pelos 3 simuladores e por tons de cinza.
- **Flashes (§7.7):** limitador global de 3 por segundo; *impact frame* no
  máximo 1 por segundo; o do chefe tem **preempção** (decisão do usuário,
  2026-11-10; Pipeline visual R7, F6): se uma recusa ocupou a janela de 1 s, o
  do chefe a substitui e corta a recusa ainda na tela, e no mesmo passo vence o
  chefe. O
  flash L* ~80 num sprite de inimigo não conta (abaixo do limiar de área).
- **Reduzir flashes** (§7.9 nº 4): o *impact frame* vira o hitstop com o mundo
  dessaturado 1 passo na escada; o flash de inimigo cai para L* ~65.
- **Tremor de câmera** (§7.9 nº 3): a 0%, sobram hitstop, estrela e flash.
- **Redução de movimento** (§7.9 nº 5): sem zoom; números e "Quebrou!" só com
  fade; as manchas da recusa aparecem e somem sem avançar. Hitstop, tranco,
  empurrão, *smear* e animações continuam (são informação de jogo).
- **Números de dano** (§7.9 nº 7): ligado, tudo; reduzido, só quarto acerto e
  somas; desligado, nenhum número nem "Quebrou!".
- Encurtar o hitstop é do GDD de Acessibilidade e opções (F9).

**Linhas novas para o Art Bible** (Open Questions): dois relógios (§8.6/§8.9);
o que conta como flash e a prioridade do *impact frame* (§7.7); tranco
procedural (§5.8); anel tracejado da área e da explosão (§4.3/§3.4); número do
"tracejado fino" (§4.3); rastro da investida (§5.8); projétil do jogador
nunca magenta; contorno tracejado de invulnerabilidade (§5.5); marca de
vulnerável e telégrafo partido (§3.x/§4.5, com Telégrafos); crítico = quarto
acerto e arredondamento do número (§7.7); *impact frame* da recusa (§2.8/§9.2);
morte de inimigo ≤ 30 passos (§5.8); "Reduzir flashes" (§7.9 nº 4); letreiro
"Quebrou!" e localização (§7.7).

## Game Feel

- **Latência:** o golpe sai **no passo do toque**, se a recarga deixa. O Input
  amostra antes de todo sistema, e o Combate roda logo depois do Movimento no
  mesmo passo (R1). O teste de acerto é no mesmo passo; o congelamento começa no
  seguinte (R10). Do toque ao acerto há 1 passo (≤ 16,7 ms), mais até 1 passo
  de interpolação no render (Cena R7), que é aceito.
- **Peso pelo congelamento, não pela lentidão:** o acerto leve congela 3 passos
  (0,05 s), o pesado 6 (0,1 s). Os passos congelados não descontam recarga, então
  o hitstop dá peso sem roubar tempo de ação (F9). Na Lâmina, ~20% do tempo real
  é congelado (alvo; acima de 33% é aviso CV2).
- **Ritmo da Lâmina:** um corte a cada 16 passos (0,27 s); o combo de três
  (14, 14, 25,2) dura um ciclo de ~1,0 s de tempo real (o abate de um Eco sai a
  0,63 s), e o terceiro é pesado: congela 6,
  empurra 68 px e quebra a preparação do inimigo. O passo de apoio de 10,5 px
  por corte faz o jogador avançar ~32 px no combo, sem perder a mira.
- **Ritmo da Ressonância:** o Pulso sai a cada 14 passos e **não congela**: a
  arma de longe é contínua e leve. A Onda (90 passos de recarga) é o golpe
  pesado da arma: congela 6 e empurra 95 px.
- **Golpe com peso, sem prender:** a recuperação deixa o jogador a 45% da
  velocidade por poucos passos (7 no Corte, 11 na Onda) e a esquiva a cancela
  (Movimento R5). A recuperação nunca impede o próximo golpe.
- **"Quebrou!" recompensa a leitura (P3):** acertar um golpe pesado enquanto o
  inimigo prepara (o telégrafo está crescendo) interrompe o ataque e o deixa
  0,4 s em recuperação. Arriscar ficar perto para quebrar, ou esquivar por
  segurança, é a escolha central do combate de perto. Elites e chefes não
  quebram: a armadura é lida pela aura (Art Bible §4.3).
- **Empurrão que se lê:** o corte comum empurra ~34 px, o finalizador ~68 px e a
  Onda ~95 px, em ~0,3–0,4 s, desacelerando (× 0,78 por passo). A parede só
  responde a golpes pesados (F8): prensar um inimigo contra a parede é uma
  recompensa de posicionamento, com dano extra e hitstop.
- **Ser atingido:** o golpe congela 6 passos e dá 0,67 s de invulnerabilidade,
  tempo para ler a situação e sair; dois inimigos não encadeiam acertos. O
  escudo absorve o dano, mas não esconde o golpe (o congelamento e o evento
  acontecem).
- **Abates:** o comum congela 4 passos; o chefe, 36 (0,6 s), "o fôlego depois"
  (Art Bible §2.9).
- **Afinar sem código:** todos os números estão no `CombatTuning` e nos
  `AttackDef`, e recarregam entre runs em debug (Conteúdo, Game Feel).
- **Alvos de playtest (P3):**
  - nenhum golpe "engolido": todo toque de Ataque ou Especial feito em passo
    vivo, com a recarga do slot em 0 depois do item 3, fora de esquiva e de
    investida e sem disparo do outro slot no mesmo passo, sai no mesmo passo; e
    todo toque guardado no buffer sai no primeiro passo vivo elegível dentro do
    prazo (o log de debug registra toques, recargas e disparos por passo);
  - nenhuma morte por golpe inimigo sem telégrafo visível antes (dono:
    Telégrafos; o log registra o passo do telégrafo e o do acerto).

## UI Requirements

- **Sem tela própria.** O Combate só fornece dados e eventos à interface:
  - ao HUD: Vida atual e máxima do jogador, escudo, recusas restantes, eventos
    `jogador_atingido` (Vida perdida) e `recusou_morte`;
  - à apresentação no mundo: número de dano por `acerto` (valor, quarto
    acerto), letreiro e marca do "Quebrou!", fio de Vida do inimigo comum (Vida
    atual e máxima, a partir do primeiro golpe; Art Bible §7.8).
- **Números de dano e "Quebrou!"** seguem a Visual/Audio V7 e V9 e a opção
  "Números de dano" (Art Bible §7.9 nº 7). O layout e o estilo são do GDD de
  HUD e do de Feedback de combate (VFX).
- **Vida do jogador no HUD:** a barra, os segmentos, a vinheta de Vida baixa e o
  segmento que racha são do GDD de HUD (Art Bible §7.8). Este GDD não define
  limiar de Vida baixa.
- **A invulnerabilidade não aparece no HUD.** Ela é lida no corpo (Visual/Audio
  V10).

> **📌 UX Flag — Combate núcleo:** este sistema alimenta o HUD e os números no
> mundo. No Pre-Production, rode `/ux-design` para o HUD antes das epics; as
> stories de UI citam `design/ux/hud.md`, não este GDD.

## Cross-References

| Documento | Seção | Uso neste GDD |
|---|---|---|
| `design/gdd/movimento-e-esquiva.md` | R2, R3, R4, R5, R6, R8, R9, R10, F4, Dependencies, OQ2 | ordem do passo, "em esquiva", recuperação, investida e `deslocar(v)`, Corte, colisão, desconto da invulnerabilidade, contrato |
| `design/gdd/modificadores-e-atributos.md` | R2, R4, R5, R10, R11, R12, R13, F2, F3, F4 | atributos, condições, gatilhos que o Combate executa, elite e chefe, consumidores de dano, multiplicador, dano recebido, Vida máxima |
| `design/gdd/conteudo-orientado-a-dados.md` | R1, R12, V2, V4, F1, F2, F4, F5, F6, F7 | `AttackDef`, `CombatTuning`, retirada do Tuning, faixas, formas registradas, conversões |
| `design/gdd/input-e-controle.md` | R2, R5, R6, F3 | Ataque, Especial, segurar repete, buffer com prazo congelado no hitstop, mira |
| `design/gdd/cena-3-4-e-camera.md` | R7, R8, F5 | hitstop como contador sem `time_scale`, impulsos de câmera, Redução de movimento |
| `design/gdd/gdd-cross-review-2026-11-06b.md` | D-N1, S-W2 | empilhamento do hitstop (resolvido: vale o maior) e abates em cadeia |
| `design/gdd/game-concept.md` | §3 (P3) | "todo ataque inimigo é telegrafado; morrer tem que parecer culpa do jogador" |
| `design/art/art-bible.md` | §1, §2.8, §2.9, §3.4, §4.2, §4.3, §4.5, §4.7, §5.5, §5.8, §7.7, §7.8, §7.9, §8.6, §8.9 | gramática da ação do jogador, impact frame, números, flashes, acessibilidade, orçamento de VFX |
| Khaeros `packages/action-core/src/engine.ts` | `:31–84`, `:537–636`, `:666–765`, `:774–885`, `:940–980`, `:1162–1222`, `:1247–1308` | constantes, dano, golpes, passo do jogador, empurrão e parede, projéteis e varredura, ordem do passo |
| Khaeros `packages/combat-rules/src/arenaContent.ts` | `ARENA_WEAPONS`, `ARENA_ENEMIES` | números da Lâmina, da Ressonância e dos inimigos do Limiar |
| Khaeros `docs/baseline.md` | §55 | hitstop, buffer, cancelamento, cambaleio, "Quebrou!", parede |
| `docs/engine-reference/godot/modules/physics.md` | — | lacuna: não cobre a física 2D do 4.7 (Open Questions) |

## Acceptance Criteria

> Proposta do `qa-lead` (consultado: modo Lean, seção de risco alto). As contas
> de F1–F11 foram refeitas por script a partir dos exemplos do próprio GDD.
> **Versão 2 (2026-11-09):** alinhada às R6, R7, R13.1, R14, R17, R18 e ao CV1
> revistos e às correções da revisão; as contas dos critérios que mudaram foram
> refeitas por script.
>
> Evidência: **[L]** `tests/unit/combat/`; **[I]** `tests/integration/combat/`;
> **[UI]** screenshot em `production/qa/evidence/`; **[V]** Visual/Feel:
> screenshot em `production/qa/evidence/` com assinatura do lead; **[P]**
> desempenho; **[M]** manual, com testador, build e resultado registrados. O
> Combate não tem tela própria: nenhum critério é [UI].
>
> Tolerâncias: dano ±0,001; posição ±0,001 px por passo (±0,01 px quando
> acumulada por mais de 20 passos; o `Vector2` é float32); paridade ±0,05 px
> (AC-71). Passos, contagens, pedidos de hitstop, eventos e a ordem deles são
> exatos. Alcance e raio usam `≤`; encostado usa `<` (F4). **A borda exata só
> é testada quando coordenadas e raios são representáveis em binário**
> (inteiros, x,5, x,25…); senão, os pontos de teste ficam a ±0,001 da borda,
> um de cada lado (ex.: o raio da Elite, 24 × 1,2 = 28,799999999999997 em
> double). O mesmo vale para igualdades decimais na validação (seção L).
>
> Cada critério é independente: o teste copia a fixture e o roteiro citados;
> nenhum critério depende do resultado de outro. Os params de teste
> (`janela_s` 1,0, `a_cada` 1) são escolhidos para encurtar roteiros; o conteúdo
> usa `janela_s` 1,5 (90 passos) e `a_cada` 4.
>
> Nada de seed nem de tempo real: tudo roda por passos e com dublês injetados
> (R16). Os contratos com IA, Telégrafos, Câmaras, Selo e Status são
> **provisórios**: os critérios que dependem deles usam dublês que honram este
> GDD e serão rodados de novo com os sistemas reais. O que só pode ser testado
> com o sistema real fica **BLOQUEADO até o GDD X**.
>
> **Fixture padrão (FP):**
>
> - `CombatTuning` padrão (R15). Em passos: leve 3, pesado 6, abate 4,
>   atingido 6, abate de chefe 36, recusa 18 (`hitstop_recusa_s` 0,3), J = 34,
>   `recuperacao_max` 12, E = 2, cambaleio 8, "Quebrou!" 24, `invuln_atingido`
>   40. Os outros campos: `empurrao_pesado` 900, `limiar_finalizador` 1,2,
>   `fator_recuperacao_golpe` 0,5, `passo_apoio_px` 10,5,
>   `folga_encostado_px` 6, `nascimento_projetil_px` 36, `fator_cambaleio` 0,4,
>   `parede_vel_min` 630, `parede_dano` 8, `queda_empurrao` 0,78,
>   `empurrao_zero` 4,5, `passes_varredura` 4, `fator_guarda` 0,5,
>   `giro_leque_graus` 12, `fator_raio_obstaculo_projetil` 0,5.
> - **Lâmina** (arma da FP):
>   - Ataque = **Corte** (`arco`): alcance 142,5 px, meio-ângulo 69,51°
>     (`cos_meio` = 0,350044), dano 14, R = 16, empurrão 450, combo [1; 1; 1,8].
>   - Especial = **Investida** (`avanco`): 330 px em N = 10, raio 69, dano 26,
>     R = 70, empurrão 1080, sem combo.
> - **Ressonância** (quando o critério diz **FP-R**):
>   - Ataque = **Pulso** (`projetil`): 990 px/s (s = 16,5 px), raio 15, L = 50,
>     leque [0], não atravessa, dano 12, R = 14, empurrão 270 (dado de teste;
>     o Pulso de fábrica grava 540, Armas R2), sem combo.
>   - Especial = **Onda** (`circulo`): raio 195, deslocamento 0, dano 30, R = 90,
>     empurrão 1260, sem combo.
> - **Jogador:** (960; 540), raio 27, mira (1; 0), Vida 100/100, escudo 0, sem
>   recusa e sem guarda. Portador real de Modificadores em memória, sem
>   modificadores (M_sem = M_com = 1).
> - **Câmara:** retângulo jogável (0; 0)–(1920; 1080), sem obstáculos. O centro
>   de um inimigo de raio r fica preso em [r; 1920 − r] × [r; 1080 − r]; o do
>   jogador, quando o critério liga a colisão, em [27; 1893] × [27; 1053].
> - **Câmaras dublê:** responde "em combate" **verdadeiro** e "câmara limpa"
>   falso (R13.1), salvo quando o critério diz; a lista de inimigos vazia
>   **não** muda a resposta. Os critérios que chamam `ferir_jogador` ou lançam
>   projétil inimigo com a lista vazia (AC-09 b, AC-32, AC-33, AC-48, AC-49,
>   AC-53, AC-58, AC-59, AC-87 a) dependem dessa consulta.
> - **Inimigos**, cada um com portador real (`fator_empurrao`: comum 1, elite
>   0,4, chefe 0,12):
>   - **Eco**: raio 24, Vida 30, comum. "Eco ferido (V)" é um Eco com Vida V.
>   - **Saco**: raio 24, Vida 1000, comum, com `fator_empurrao` 0 no portador
>     (não sai do lugar).
>   - **Saco móvel**: o Saco com `fator_empurrao` 1.
>   - **Elite**: raio 28,8 (24 × 1,2), Vida 1000.
>   - **Chefe**: raio 63, Vida 700.
>
>   A lista começa vazia. A ordem da lista é a ordem em que o critério cita os
>   inimigos.
> - **Movimento dublê:**
>   - guarda a posição do jogador (o teste pode mudá-la);
>   - "em esquiva" vem do roteiro e é falsa por padrão;
>   - executa `deslocar(v)` na hora, somando v à posição (sem colisão, salvo
>     quando o critério diz outra coisa);
>   - no item 4 lê "em recuperação" e o contador da investida e, se ele é > 0,
>     aplica `d` (R6). "O Movimento aplica `d` no passo t" é o que o dublê
>     registra; "investida ativa" fica reservado para a consulta do disparo
>     (R3), lida no item 5 depois do desconto;
>   - envia `cancelar`, `garantir_invulneravel(n)`, `aplicar_corte` e
>     `esquiva_iniciada` quando o roteiro manda;
>   - registra tudo o que lê e pede.
> - **IA dublê:**
>   - o estado de cada inimigo vem do roteiro (livre por padrão; surgindo, em
>     preparação, em execução);
>   - registra os pedidos de "Quebrou!" (alvo, passos) e a leitura de
>     "cambaleando" no turno dela;
>   - chama `ferir_jogador` e `disparar_projetil` quando o roteiro manda;
>   - não move inimigos e não separa.
> - **Input dublê**, em Jogo:
>   - "toque em n" põe o botão em `apertados_neste_passo` no passo n e no buffer
>     pelo prazo do Input F3 (10 passos vivos, com o prazo parado no hitstop);
>   - "segurado em a–b" marca o botão segurado nesses passos;
>   - disparar tira o botão do buffer.
> - **Selo e Status dublês** não fazem nada, salvo quando o critério manda. O
>   Selo dublê pode chamar `ferir_inimigo` no item 6; o Status dublê, no turno
>   do inimigo no item 7 (com `de_status`).
> - **Orquestrador de teste** com a ordem da R1, e um espião de eventos e de
>   pedidos de hitstop (passo, ordem e campos).
>
> Os passos são numerados a partir de 0 e contam **todos** os passos do
> orquestrador, vivos e congelados. "Após n" é o estado ao fim do passo n.
> "Golpe sem alvo" quer dizer que nenhum inimigo atingível passou no teste, e
> por isso não há hitstop.

**A. Dados, injeção e faixas**

- **AC-01 [L] R15 — conversões.** FP:
  - os passos do `CombatTuning` são os listados na FP; `hitstop_abate_s`
    0,0667 dá round(4,002) = 4;
  - Corte R = 16; Investida N = 10 e R = 70; Pulso L = 50, R = 14 e
    s = 16,5; Onda R = 90;
  - `cos_meio` = 0,350044 ±0,000001, calculado na carga e não a cada passo;
  - `fator_guarda` 0,5, `giro_leque_graus` 12 e `fator_raio_obstaculo_projetil`
    0,5 vêm do `CombatTuning` (trocar o valor no dado muda o comportamento nas
    AC-27, AC-29 e AC-48; nenhum valor de código).
- **AC-02 [L] R16 — determinismo sem SceneTree.**
  - O Combate é criado num teste gdUnit4 sem SceneTree e sem autoload, só com
    os dublês da FP.
  - O roteiro é o arquivo versionado
    `tests/unit/combat/fixtures/roteiro_determinismo.json`: 1200 passos com a
    FP e 1200 com a FP-R, 5 Ecos e 1 Elite com estados de IA roteirizados,
    toques e segurados de Ataque e Especial, esquivas do dublê e um
    `ferir_jogador(9)` a cada 50 passos.
  - Duas instâncias novas, cada uma com dublês novos, dão sequências idênticas
    bit a bit de posições, Vidas, contadores, hitstop e eventos.
- **AC-03 [L] faixas do `CombatTuning`.** Cada linha muda um campo da FP.
  Cada linha confere só a presença ou a ausência do erro de faixa daquele
  campo; os avisos CV que o valor gera são das AC-60 a AC-64.

  | Campo | Aceitos | Erro de faixa |
  |---|---|---|
  | `hitstop_leve_s` | 0,0167 (1) e 0,1 (6) | 0 e 0,101 |
  | `hitstop_pesado_s` | 0,05 (3) e 0,2 (12) | 0,049 e 0,201 |
  | `hitstop_abate_s` | 0,0167 e 0,2 | 0 e 0,201 |
  | `hitstop_atingido_s` | 0,0333 (2) e 0,25 (15) | 0,033 e 0,251 |
  | `hitstop_abate_chefe_s` | 0,2 (12) e 1,5 (90) | 0,199 e 1,501 |
  | `hitstop_recusa_s` | 0,1 (6) e 0,6 (36) | 0,099 e 0,601 |
  | `empurrao_pesado` | 460 e 1080 | 459,99 e 1080,01 |
  | `limiar_finalizador` | 1,0 e 1,45 | 0,99 e 1,46 |
  | `janela_combo_s` | 0,5167 (31) e 1,0 (60) | 0,516 e 1,001 |
  | `recuperacao_max_s` | 0,0167 e 0,5 | 0,016 e 0,501 |
  | `fator_recuperacao_golpe` | 0 e 1 | −0,01 e 1,01 |
  | `passo_apoio_px` | 0 e 24 | −0,01 e 24,01 |
  | `folga_encostado_px` | 0 e 20 | −0,01 e 20,01 |
  | `nascimento_projetil_px` | 27 e 60 | 26,99 e 60,01 |
  | `invuln_extra_investida_s` | 0 (E = 0) e 0,1 (6) | −0,01 e 0,101 |
  | `cambaleio_s` | 0,0167 e 0,15 (9) | 0,016 e 0,151 |
  | `fator_cambaleio` | 0 e 1 | −0,01 e 1,01 |
  | `quebrou_recuperacao_s` | 0,1667 (10) e 0,8 (48) | 0,166 e 0,801 |
  | `parede_vel_min` | 460 e 900 | 459,99 e 900,01 |
  | `parede_dano` | 0 e 30 | −0,01 e 30,01 |
  | `queda_empurrao` | 0,5 e 0,95 | 0,49 e 0,951 |
  | `empurrao_zero` | 0,9 e 30 | 0,89 e 30,01 |
  | `invuln_atingido_s` | 0,25 (15) e 1,5 (90) | 0,249 e 1,501 |
  | `passes_varredura` | 1 e 8 | 0, 9 e 4,5 (não inteiro) |
  | `fator_guarda` | 0 e 1 | −0,01 e 1,01 |
  | `giro_leque_graus` | 3 e 45 | 2,99 e 45,01 |
  | `fator_raio_obstaculo_projetil` | 0 e 1 | −0,01 e 1,01 |

  As relações entre campos (leve ≤ abate ≤ pesado ≤ abate de chefe, recusa ≥
  atingido…) não são faixa: são o aviso CV1 (AC-60).
- **AC-04 [L] R16/Dados — sem valor escondido.** Criar o Combate sem
  `CombatTuning`, ou sem `AttackDef`, falha na construção com erro nomeado. O
  Combate não roda nenhum passo e não usa valor padrão de código.

**B. Passo vivo e hitstop**

- **AC-05 [I] R1 — ordem do passo** (provisório: o orquestrador real vem da
  ADR do passo). Orquestrador real, com dublês que registram cada chamada, 3
  inimigos na lista e 300 passos:
  - num passo vivo, a ordem é sempre: Input → Combate início → Movimento →
    Combate golpe → Selo → para cada inimigo, na ordem da lista: Status,
    Combate impacto, IA → Combate projéteis → Combate varredura → Câmaras;
  - num passo congelado, só Input e `passo_congelado()` do Movimento são
    chamados.
- **AC-06 [L] R10 — o passo do pedido termina; os seguintes congelam.** FP,
  Saco móvel em (1060; 540), Ataque segurado em 0–40:
  - no passo 0, o Corte acerta, é pedido o hitstop 3, e o Saco já anda nesse
    passo (item 7): x = 1067,5 após 0;
  - nos passos 1–3, x = 1067,5 e a recarga do Ataque fica em 16;
  - após 4, x = 1073,35 e a recarga está em 15;
  - o segundo golpe sai no passo 19 (16 passos vivos: 4 a 19).
- **AC-07 [L] R10/F9 — tabela do hitstop.** FP ou FP-R, cada linha num roteiro
  novo, com a fixture completa na linha:

  | Causa (roteiro) | Passos congelados |
  |---|---|
  | Corte, Saco em (1060; 540), Ataque tocado em 0 | 1–3 |
  | Corte, lista vazia, Ataque tocado em 0 | nenhum |
  | 3º Corte (finalizador): Ataque segurado; Saco em (1060; 540) surgindo até 31; golpes 0 e 16 sem alvo; 3º no 32 | 33–38 |
  | Onda (FP-R), Saco em (1100; 540), Especial tocado em 0 | 1–6 |
  | Pulso (FP-R), Saco em (1100; 540), Ataque tocado em 0: acerta no passo 3 (x = 1062) | nenhum |
  | Investida, Sacos em (1100; 540) e (1250; 540), Especial tocado em 0: acertos nos passos 2 e 12 | 3–8 e 13–15 |
  | Corte que mata um Eco ferido (14) em (1060; 540), toque em 0: max(3, 4) | 1–4 |
  | Onda (FP-R) que mata uma Elite com Vida 30 em (1100; 540), toque em 0: max(6, abate de elite 6) | 1–6 |
  | Onda (FP-R) que mata um Chefe com Vida 30 em (1100; 540), toque em 0 | 1–36 |
  | Eco corpo a corpo em (700; 540) chama `ferir_jogador(9, 1, Eco)` no passo 0, sem golpe | 1–6 |
  | Recusa: `recusas_morte` 1 (vida_ao_voltar 0,4; invuln_s 2,0), Vida 5, Eco em (700; 540) chama `ferir_jogador(9, 1, Eco)` no passo 0: max(6, 18) | 1–18 |
  | Batida na parede no passo 2 (roteiro da AC-46 a) | 3–5 |
- **AC-08 [L] F9/F1 — combo da Lâmina num Eco.** FP, Eco em (1060; 540),
  Ataque segurado em 0–40 (segurado até 60, sairia um 4º golpe, sem alvo, no
  passo 60):
  - golpes nos passos 0, 19 e 38;
  - congelados: 1–3, 20–22 e 39–44;
  - Vida do Eco: 16 após 0, 2 após 19, e −23,2 no 38, quando ele sai na
    varredura e é emitido `inimigo_morreu`;
  - o abate sai a 38 passos do primeiro golpe: 32 vivos + 6 congelados.
- **AC-09 [L] R10 — o congelado não desconta.** FP, Saco móvel em
  (1060; 540). No passo 0, o Movimento dublê pede `garantir_invulneravel(12)`
  e o Ataque é tocado; o Corte acerta e os passos 1–3 congelam.
  - Após 0 e após cada passo de 1 a 3: invulnerabilidade 12, recarga do
    Ataque 16, recuperação 8, janela de combo 34, cambaleio do Saco 7,
    `vel_empurrao` 351 e x do Saco 1067,5.
  - Após 4: 11, 15, 7, 33, 6 e x = 1073,35.
  - Um `ferir_jogador(9)` no passo 14 não faz nada. No passo 15 tira 9 (roteiros
    separados).
  - (b) Janela `apos_esquiva`: sem golpe, lista vazia, portador com
    `dano_apos_esquiva` (janela 60). No passo 0, o Movimento dublê envia
    `esquiva_iniciada` e o teste chama `ferir_jogador(9)` sem atacante (item
    7): passos 1–6 congelados. Janela 60 e invulnerabilidade 40 após 0 e após
    cada passo de 1 a 6; 59 e 39 após 7.
  - (c) Guarda: **Corte-guarda** (AC-21), Saco móvel em (1060; 540), Ataque
    tocado em 0: guarda 6 após 0 e após cada passo de 1 a 3; 5 após 4.
- **AC-10 [L] R1/R10 — câmara nova zera** (provisório: Câmaras e orquestrador
  dublês). FP-R, Chefe com Vida 30 em (1100; 540), Especial tocado em 0; a Onda
  mata o Chefe e a varredura do passo 0 pede o hitstop 36:
  - (a) sem troca de câmara, os passos 1–36 congelam e o 37 é vivo;
  - (b) a fixture força hitstop 36, investida com 5 passos, recuperação 8,
    recarga do Ataque 9 e invulnerabilidade 20, e o orquestrador dublê entra
    em Transição: até a metade do wipe nenhum desses contadores muda; no quadro
    da metade, depois do aviso "câmara nova", hitstop, investida e recuperação
    são 0, e recarga 9 e invulnerabilidade 20 continuam.

  O aviso não chega em passo congelado nem em passo vivo: só no quadro da
  metade da Transição (R1).
- **AC-95 [L] R10 — câmara limpa espera o hitstop** (provisório: Câmaras
  dublê). O mesmo roteiro da AC-10 (a), com o Chefe como único inimigo: o
  Câmaras dublê não recebe a avaliação de "câmara limpa" no passo 0 (hitstop
  36 pedido) nem nos passos 1–36, e a recebe no passo 37, com a lista vazia.
  Com um Eco (abate comum, hitstop 4) no lugar do Chefe, ela chega no passo 5.
- **AC-96 [L] R1 — ordem da metade do wipe e fora de Jogo** (provisório:
  orquestrador, Câmaras, Cena e Pipeline dublês). Um espião registra as
  chamadas do quadro da metade da Transição: "câmara nova" (Combate),
  teleporte (Movimento), montagem (Câmaras), VFX apagados, corte da câmera
  (Cena), LUT e relógios (Pipeline), nessa ordem e no mesmo quadro, e nenhuma
  delas em outro quadro (o quadro da metade é o primeiro com `progresso_wipe`
  ≥ 0,5). Em cada passo de física da Transição, o Movimento recebe 1
  `passo_congelado()` e o Combate nenhuma chamada da R1. Com hitstop 20 e a
  pausa aberta no 5º passo congelado por 100 quadros, o contador é 15 ao abrir
  e 15 ao fechar.
- **AC-11 [I] R10 + Input R6 — buffer congelado.** Input real, FP-R, Chefe com
  Vida 30 em (1100; 540):
  - Especial tocado em 0: a Onda mata o Chefe e os passos 1–36 congelam;
  - o Ataque tocado no passo 2 sai no passo 37 (`disparo`), embora o hitstop
    seja mais longo que o buffer de 10.

**C. Disparo**

- **AC-12 [L] R3 — sai no passo do toque.** FP, golpes sem alvo:
  - toque em 0: `golpe` no passo 0; recarga 16 após 0, 1 após 15, 0 após 16;
  - segurado em 0–40: golpes exatamente nos passos 0, 16 e 32;
  - toque só em 0: um golpe só, porque o disparo tira o botão do buffer;
  - toques em 0 e 8: golpes em 0 e 16;
  - borda do buffer (Input F3: o toque vale no passo dele e nos 9 seguintes):
    toques em 0 e 6, só o golpe do 0 e nenhum nos passos 1–40; toques em 0 e
    7, golpes em 0 e 16.
- **AC-13 [L] R3/Edge — Especial primeiro.** FP-R, Ataque e Especial tocados
  em 0, sem alvos:
  - no passo 0 sai só a Onda (`area`);
  - o Pulso sai no passo 1 (`disparo`);
  - recarga do Especial 90 após 0; recarga do Ataque 14 após 1.
- **AC-14 [L] R3/Edge — esquiva e investida bloqueiam.** FP, golpes sem alvo:
  - "em esquiva" verdadeira nos passos 0–7, Ataque tocado em 2: nenhum golpe
    nos passos 2–7; o golpe sai no 8;
  - "em esquiva" verdadeira em 0–19, toque em 2: nenhum golpe nos passos 0–40
    (o prazo venceu);
  - Especial tocado em 0 (Investida) e Ataque tocado em 3: nenhum Corte nos
    passos 0–9; o Corte sai no passo **10**, o do último deslocamento: no item
    5 do passo 10 o contador cai de 1 a 0 antes do teste de disparo, e a
    consulta já é falsa (R6).
- **AC-15 [L] R3/Edge — golpe sem alvo e câmara limpa.** FP, lista vazia,
  Ataque tocado em 0, portador com a janela `apos_esquiva` aberta. No passo 0:
  - 1 evento `golpe`, nenhum pedido de hitstop;
  - recarga 16, recuperação 8;
  - passo do combo do Ataque 0 → 1, janela de combo 34;
  - janela `apos_esquiva` fechada;
  - 1 pedido `deslocar((10,5; 0))`.

  Com o Câmaras dublê em "câmara limpa" ("em combate" falso), o resultado é o
  mesmo: o golpe sai (R3).
- **AC-16 [L] R2/R3.1 — combo e janela.** FP, Saco em (1060; 540) surgindo até
  o passo X − 1 e atingível a partir do X. Toques em 0, 16 e X:
  - X = 49 (janela em 1): o Saco recebe 25,2 e o acerto é pesado;
  - X = 50 (a janela chegou a 0 e o combo voltou a 0): recebe 14,0 e o acerto é
    leve;
  - os golpes dos passos 0 e 16 erraram e mesmo assim avançaram o combo.
- **AC-17 [L] R3.1 — combo por slot** (divergência do cânone). FP com o
  Especial trocado pela **Onda-combo** (Onda com `multiplicadores_combo`
  [1; 2]). Saco em (1060; 540), surgindo até 31. Ataque segurado em 0–40 e
  Especial tocado em 8:
  - Cortes em 0, 16 e 32; Onda no 8, sem alvo;
  - após 8, o passo do combo do Especial é 1 e o do Ataque continua **1** (o
    Corte do 0 o levou a 1; só o do 16 o leva a 2);
  - no passo 32, o Saco recebe 25,2 (finalizador). Um contador único teria
    dado 14.
- **AC-18 [L] R3.2 — M no disparo; a janela `apos_esquiva` fecha.** FP,
  portador real com `dano_apos_esquiva` +50% (janela de 60 passos). O
  Movimento dublê envia `esquiva_iniciada` no passo 0, com "em esquiva" falsa.
  Saco em (1060; 540):
  - toques em 0 e 16: o Saco recebe 21,0 no 0 e 14,0 no 19;
  - variante, com o Saco surgindo até 15 e toques em 0 e 16: o golpe do 0 erra
    e o do 16 tira 14,0, porque a janela fechou mesmo sem acerto.
- **AC-19 [L] Edge — golpe no último passo da esquiva, com bônus.** O portador
  e o Saco da AC-18. `esquiva_iniciada` no passo 0, "em esquiva" verdadeira em
  0–7, Ataque tocado em 2:
  - o Corte sai no 8 e tira 21,0;
  - após 8, a janela `apos_esquiva` está fechada.
- **AC-20 [L] R3.2/R6 — o projétil leva o M do disparo.** FP-R, portador real
  com `dano_vida_baixa_pct` +40% (abaixo de 50%), Saco em (1100; 540), Ataque
  tocado em 0:
  - Vida 60/100 no disparo, e o teste põe a Vida em 40 entre os passos 0 e 1
    (sem dano): o Saco recebe 12,0;
  - Vida 40 no disparo, posta em 60 depois: o Saco recebe 16,8.
- **AC-21 [L] R3.5 — guarda** (provisório: OQ8, a guarda pode virar
  modificador temporário). FP com o **Corte-guarda** (Corte com `guarda_s`
  0,1, 6 passos) e um Eco corpo a corpo em (700; 540), fora do arco. Ataque
  tocado em 0, sem alvo. Em roteiros separados, a IA dublê chama
  `ferir_jogador(9, M 1, Eco)`:
  - no passo 0: dano 5 (round(4,5)), Vida 95;
  - no passo 5: dano 5;
  - no passo 6: dano 9.
- **AC-22 [L] R3.7/F2 — recuperação.** Golpes sem alvo, disparo no passo 0. O
  Movimento dublê lê "em recuperação":

  | Golpe | rec | Verdadeiro nos passos | Falso no 0 e no |
  |---|---|---|---|
  | Corte (FP) | 8 | 1–7 | 8 |
  | Pulso (FP-R) | 7 | 1–6 | 7 |
  | Onda (FP-R): round(45), preso em 12 | 12 | 1–11 | 12 |
  | Investida (FP) | 0 | nenhum | — |
  | Corte, `fator_recuperacao_golpe` 0 | 0 | nenhum | — |
  | Corte, `fator_recuperacao_golpe` 1: min(12, 16) | 12 | 1–11 | 12 |
  | Onda, `recuperacao_max_s` 0,5: min(30, 45) | 30 | 1–29 | 30 |
  | `AttackDef` com recarga 0,0833 (5): round(2,5) = 3 | 3 | 1–2 | 3 |

  Com o Corte, um `cancelar` do dublê no passo 3 deixa a recuperação em 0 após
  3, e a leitura no passo 4 já é falsa.

**D. Arco e círculo**

- **AC-23 [L] R4/F4 — teste do arco.** FP, um alvo por roteiro, Ataque tocado
  em 0:

  | Alvo em | Situação | Atingido? |
  |---|---|---|
  | Eco (1126,5; 540) | d = 166,5, na borda do alcance | sim |
  | Eco (1126,501; 540) | além da borda | não |
  | Eco (1035; 669,9038) | 150 px a 60° (0,5 ≥ 0,35) | sim |
  | Eco (986,0472; 687,7212) | 150 px a 80° (0,174) | não |
  | Eco (1012,7762; 680,4089) | 150 px a 69,4° | sim |
  | Eco (1012,2858; 680,5923) | 150 px a 69,6° | não |
  | Eco (910; 540) | d = 50, nas costas (encostado) | sim |
  | Eco (903,001; 540) | d = 56,999, nas costas | sim |
  | Eco (903; 540) | d = 57, nas costas (`<`, não encostado) | não |
  | Saco móvel (960; 540) | d = 0: u = mira | sim; após 0, x = 967,5 |
  | Elite (1131,299; 540) | d = 171,299, dentro de 142,5 + 28,8 (borda não exata em binário: ±0,001) | sim |
  | Elite (1131,301; 540) | d = 171,301, além da borda | não |

  Com mira (0; −1), um Eco em (960; 373,5) é atingido.
- **AC-24 [L] R4 — vários alvos, um hitstop.** FP. Ecos B (1060; 480), A
  (1060; 540) e C (1060; 600), nesta ordem na lista, e um Eco D em (900; 540),
  nas costas a 60 px. Ataque tocado em 0:
  - 3 eventos `acerto`, na ordem B, A, C, seguidos de 1 evento `golpe`;
  - D não é atingido;
  - 1 pedido de hitstop 3 (passos 1–3 congelados).
- **AC-25 [L] R4 — passo de apoio depois do teste.** FP:
  - Eco em (1126,5; 540): o `acerto` sai antes do único pedido
    `deslocar((10,5; 0))`; após 0, o jogador está em (970,5; 540);
  - com mira (0,6; 0,8), sem alvo, o pedido é `deslocar((6,3; 8,4))`;
  - Onda, Pulso e Investida (FP e FP-R) não pedem `deslocar`.
- **AC-26 [L] R5/F4 — círculo.** FP-R, Especial tocado em 0, um Saco por
  roteiro:
  - (1179; 540): atingido; (1179,001; 540): não; (741; 540), nas costas:
    atingido;
  - evento `area` (não `golpe`), sem `deslocar`, hitstop 6 com alvo e nenhum
    sem alvo.

  Com a **Onda-60** (deslocamento 60, centro em (1020; 540)):
  - (1239; 540) e (801; 540): atingidos; (800,999; 540): não;
  - um Saco móvel em (990; 640) é empurrado na direção do jogador ao inimigo,
    (0,2873; 0,9578) ±0,0001, e não na direção do centro,
    (−0,2873; 0,9578).

**E. Projéteis**

- **AC-27 [L] R6/F5 — nascimento e leque.** FP com o **Pulso-leque** (leque
  [0; 1; 2; 3]), Ataque tocado em 0. O espião lê os projéteis logo depois do
  item 5:
  - 4 projéteis, nascidos em (996; 540), (995,2133; 547,4848),
    (995,2133; 532,5152) e (992,8876; 554,6425), com direções de 0°, +12°,
    −12° e +24° (horário, y para baixo);
  - cada um leva dano do golpe 12, M_sem 1 e empurrão 270;
  - 1 evento `disparo`, nenhum hitstop, nenhum `deslocar`; recarga 14 e
    recuperação 7;
  - com `giro_leque_graus` 20: nascidos em (996; 540), (993,8289; 552,3127),
    (993,8289; 527,6873) e (987,5776; 563,1404), com 0°, +20°, −20° e +40°.
- **AC-28 [L] R7/F5 — alcance testado.** FP-R, Ataque tocado em 0:
  - Eco em (1843,5; 540): atingido 1 vez, com dano 12;
  - Eco em (1843,501; 540): nunca é atingido;
  - nos dois casos, o projétil faz exatamente 49 testes de acerto, e o último
    centro testado é x = 1804,5 (960 + 844,5);
  - o projétil some no passo em que a vida chega a 0, sem testar.
- **AC-29 [L] R7/Edge — o projétil some** (depende da ordem por passo da R7:
  move, vida, retângulo e obstáculo, acerto). FP-R, Ataque tocado em 0:
  - obstáculo (1010; 540; r 42) e Saco em (1030; 540): no passo 0 o projétil
    vai a x = 1012,5, a 2,5 px do centro do obstáculo (< 42 + 15 × 0,5 =
    49,5), e some; o Saco, a 17,5 px (≤ 39), **não** é atingido, porque o teste
    de obstáculo vem antes do de acerto;
  - `fator_raio_obstaculo_projetil`, com obstáculo (1060; 540; r 42) e lista
    vazia: 0,5 → some no passo 0 (47,5 < 49,5); 0 → some no passo 1 (no 0,
    47,5 ≥ 42; no 1, x = 1029 e 31 < 42); 1 → some no passo 0 (47,5 < 57);
  - jogador em (1893; 540), o máximo para o raio 27: o projétil nasce em
    (1929; 540), fora do retângulo, e some no passo 0 (x = 1945,5), sem
    `acerto`.
- **AC-30 [L] R7/R9 — atravessa e surgindo.** FP-R:
  - **Pulso-atravessa**, Sacos em (1100; 540) e (1200; 540): cada um é atingido
    exatamente 1 vez, embora fique vários passos dentro do alcance, e o
    projétil continua;
  - Pulso normal: só o Saco do 1100 é atingido, e o projétil some ali;
  - Pulso normal com o Saco do 1100 surgindo durante todo o voo: ele não é
    atingido, e o do 1200 é.
- **AC-31 [L] R6/F3 — empurrão do dado e finalizador no projétil**
  (divergência do cânone, que usava 6 u, 540 px/s):
  - FP-R, Saco móvel em (1100; 540), um Pulso: `vel_empurrao` recebe 270 na
    direção (1; 0);
  - **Pulso-combo** ([1; 1; 1,8]), Ataque segurado em 0–40 (disparos em 0, 14 e
    28; o projétil não pede hitstop), Saco móvel em preparação em (1100; 540): os 2 primeiros acertos levam empurrão 270,
    são leves e não pedem "Quebrou!"; o 3º tira 21,6, leva 900, é pesado e gera
    1 pedido "Quebrou!"(Saco, 24).
- **AC-32 [L] R7 — projétil inimigo.** FP. O teste injeta antes do passo 0 um
  projétil inimigo em (1100; 540), direção (−1; 0), 540 px/s, raio 12, vida 120
  passos, dano 9 e M 1,25:
  - jogador vulnerável: acerta no passo 11 (x = 992); dano round(11,25) = 11,
    Vida 89; o projétil some;
  - com `garantir_invulneravel(12)` no passo 0: no 11 atravessa sem dano; acerta
    no passo 12 (x = 983);
  - com `refletir_dano` 3,0 no portador: nada é refletido, porque o projétil não
    tem atacante.

- **AC-93 [L] R7 — `disparar_projetil`** (provisório: IA dublê). A IA dublê
  chama `disparar_projetil((1100; 540), (−1; 0), 600, 9, 4,0, 9, 1,0, falso)`
  no passo 0: há 1 evento `disparo` com dono "inimigo", o projétil anda já no
  passo 0 (x = 1090 após 0) e acerta o jogador em (960; 540) no passo em que a
  distância fica ≤ 36 (raio 9 + 27): passo 10, com x = 990 e dano 9.

**F. Investida**

- **AC-94 [L] R6/Modificadores R12 — o M da investida é do disparo.** FP com
  `dano_vida_baixa_pct` +40% (`limiar_vida` 0,5), Vida do jogador 40/100, Saco
  em (1000; 540) (Vida 1000). Especial tocado em 0; a fixture põe a Vida em 60
  antes do passo 1: o acerto do passo 1 tira 26 × 1,4 = **36,4**. No inverso
  (60 no disparo, 40 depois), tira **26,0**.
- **AC-33 [L] R6/F6 — deslocamento e invulnerabilidade.** FP, Especial tocado
  em 0, sem alvos:
  - 1 `garantir_invulneravel(12)` e 1 evento `investida` no passo 0;
  - o Movimento aplica d = (33; 0) nos passos 1–10 e não aplica no 0 nem no
    11; após 10, o jogador está em (1290; 540);
  - a consulta "investida ativa" do disparo (lida depois do desconto) é falsa
    no 0, verdadeira nos passos 1–9 e falsa no 10;
  - "em recuperação" é falsa em 0–12; recarga do Especial 70 após 0 e 0 após 70;
  - `ferir_jogador(9)` nos passos 0 ou 11 não faz nada; no 12 tira 9 (roteiros
    separados);
  - com mira (0,6; 0,8), d = (19,8; 26,4).
- **AC-34 [L] R6/F6 — alvos a partir do passo seguinte, um acerto por alvo.** FP,
  Especial tocado em 0:
  - Saco em (1000; 540), a 40 px no passo 0: nenhum `acerto` no passo 0. É
    atingido no 1, com dano 26 e empurrão 1080 na direção (1; 0), e nunca mais.
  - Saco em (1092; 633): atingido no passo 4, a d = 93,000. Em
    (1092; 633,001): nunca.
  - Sacos S1 (1100; 540) e S2 (1250; 540):
    - S1 é atingido no passo 2, com hitstop 6 (passos 3–8 congelados);
    - S2 é atingido no passo 12, com hitstop 3 (passos 13–15 congelados);
    - o Movimento aplica `d` nos passos 1, 2, 9–12 e 16–19 (10 deslocamentos),
      e após 19 o jogador está em (1290; 540).
- **AC-35 [L] Edge — a esquiva cancela a investida.** FP, Especial tocado em 0,
  Saco em (1000; 540), Saco S2 em (1150; 540). O dublê envia `cancelar` no
  passo 9, antes de ler o contador da investida:
  - o Saco é atingido no 1, e os passos 2–7 congelam;
  - o Movimento aplica `d` só nos passos 1 e 8 e não aplica a partir do 9;
    após 9, o jogador está em (1026; 540) e S2 nunca é atingido;
  - a recarga do Especial após 9 é 67 (70 menos 3 passos vivos), e não volta;
  - a invulnerabilidade após 9 é 9. Um `garantir_invulneravel(12)` no 9 a leva
    a 12; um `garantir_invulneravel(5)` a deixa em 9.
- **AC-36 [L] Edge — investida contra a parede.** FP, Movimento dublê com a
  colisão da R10 do Movimento (centro do jogador ≤ 1893), jogador em
  (1700; 540), Especial tocado em 0:
  - x = 1733, 1766, 1799, 1832 e 1865 nos passos 1–5, e preso em 1893 nos
    passos 6–10;
  - o Movimento aplica `d` nos passos 1–10 (preso a partir do 6);
  - um Saco em (1893; 633), surgindo até o passo 9, é atingido no passo 10, na
    posição presa.

**G. Impacto em inimigo**

- **AC-37 [L] R8/F1 — dano, contador por alvo e quarto acerto.** FP, portador
  real com Ataque +25% (M_sem 1,25) e `dano_enesimo_acerto` com `a_cada` 4 e
  valor 0,6 (M_com 2,0). Ataque segurado.
  - (a) Sacos B (1060; 480), A (1060; 540) e C (1060; 600), nesta ordem; B e C
    surgindo até o passo 18:
    - no passo 0, A recebe 17,5 (contador 1);
    - no passo 19, B recebe 17,5 (2), A 17,5 (3) e C 28,0 (4): `acerto` de C
      com quarto acerto verdadeiro, pesado e `peso_visual` pesado; **1 pedido
      de hitstop 3** (o quarto acerto não sobe o hitstop do golpe, R4);
    - sem `dano_enesimo_acerto`, C recebe 17,5 e o quarto acerto é falso.
  - (b) Saco A (1060; 540) e Eco ferido (17) D (1060; 600), nesta ordem:
    - no passo 0, A recebe 17,5 (1) e D recebe 17,5 (2) e morre;
      max(3, 4): congelados 1–4;
    - no passo 20, A recebe 17,5 (3);
    - no passo 39, A recebe 25,2 × 2,0 = 50,4 (4), com finalizador e quarto
      acerto.
  - (c) FP-R com o mesmo portador: um Pulso tira 15,0.
- **AC-38 [L] R8/F3 — finalizador, pesado e fator do alvo.** FP, Ataque
  segurado, golpes em 0 e 16 sem alvo (o alvo surge no 32) e o 3º Corte no 32.
  Alvo em (1060; 540):

  | Alvo (estado) | Deslocamento no passo 32 | Pesado | Cambaleio | "Quebrou!" |
  |---|---|---|---|---|
  | Saco móvel (em preparação) | 15,0 px (900) | sim | sim | 1 pedido (24) |
  | Saco móvel (em execução) | 15,0 | sim | sim | nenhum |
  | Elite (em preparação) | 6,0 (360) | sim | não | nenhum |
  | Chefe (em preparação) | 1,8 (108) | sim | não | nenhum |

  O 1º Corte no Saco móvel em preparação (sem alvo surgindo) desloca 7,5 px, é
  leve, dá cambaleio e não pede "Quebrou!".
- **AC-39 [L] R8.6/F7 — empurrões se somam.** FP, Saco móvel em (1060; 540),
  Ataque tocado em 0. No item 6 do passo 0, o Selo dublê chama
  `ferir_inimigo(dano 0, empurrão 450, de_arma falso)`:
  - direção (−1; 0): `vel_empurrao` = 0 e x = 1060 nos passos 0–30; nenhum
    evento `parede`; o cambaleio é posto;
  - direção (1; 0): v0 = 900; x = 1075 após 0, e x = 1127,8936 após 24 (22
    passos com movimento: 0 e 4–24).
- **AC-40 [L] R8 — dano 0, excesso e Corte da esquiva.** FP:
  - (a) portador com Ataque −100% (M = 0), **Corte-sangra** (status
    Sangramento 1), Saco móvel em (1060; 540): a Vida do Saco fica em 1000. Há
    `acerto_de_arma`, o deslocamento no passo 0 é 7,5, o cambaleio é posto e o
    Status dublê recebe Sangramento 1.
  - (b) Eco ferido (10) em (1060; 540) e Eco em (1060; 600), nesta ordem: o
    primeiro fica com −4 e sai na varredura; o segundo recebe 14, nada do
    excesso.
  - (c) o Movimento dublê envia `aplicar_corte` (dano 10, empurrão 360 em
    (1; 0), Sangramento 1) para um Saco móvel:
    - há `acerto` com dano 10 e o Saco recebe `vel_empurrao` 360 e cambaleio;
    - o Status dublê recebe Sangramento 1;
    - o contador de acertos não muda, não há `acerto_de_arma` e nenhum hitstop é
      pedido.

    Isso confirma a AC-26 do Movimento (nenhum hitstop no Corte, R10).
- **AC-41 [L] R8.7/R12 — cambaleio** (o desconto do item 7 roda no mesmo passo, R12). FP, Saco móvel em
  (1060; 540), Ataque tocado em 0:
  - a IA dublê lê "cambaleando" verdadeiro nos passos 0 e 4–9 e falso no 10 (a
    IA não roda nos congelados 1–3);
  - variante: no passo 6, o Selo dublê aplica
    `ferir_inimigo(dano 0, empurrão 100)`. O cambaleio após 6 é 7, que é
    max(5, 8) − 1, e a leitura é verdadeira até o passo 12 e falsa no 13;
  - uma Elite atingida nunca está "cambaleando".
- **AC-42 [L] R8.7 — "Quebrou!".** FP-R, Especial tocado em 0, alvo em
  (1100; 540):

  | Alvo e estado | Pedido à IA | Evento `quebrou` |
  |---|---|---|
  | Saco móvel em preparação | 1 pedido (Saco, 24) | 1 |
  | Saco móvel em execução | nenhum | 0 |
  | Saco móvel livre | nenhum | 0 |
  | Eco (Vida 30) em preparação, morto pela Onda | nenhum | 0 |
  | Elite em preparação | nenhum | 0 |
  | Chefe em preparação | nenhum | 0 |
- **AC-43 [L] R9 — atingível.** FP, Ataque tocado em 0:
  - um Saco surgindo em (1060; 540): nenhum `acerto` e nenhum hitstop; o
    contador de acertos não muda;
  - um Eco com Vida 0 (posta antes do passo 0) na mesma posição: não é
    atingido e sai na varredura do passo 0.
- **AC-44 [L] R14/R12 — morto não age** (divergência do cânone). FP, Eco ferido
  (14) em (1060; 540), em execução, e a IA dublê programada para chamar
  `ferir_jogador(9)` no turno dele no passo 0. Ataque tocado em 0:
  - o Eco morre no item 5 e não é empurrado (x = 1060 até a varredura);
  - a IA dublê não é chamada para ele no passo 0; a Vida do jogador fica em 100;
  - ele sai na varredura do passo 0.
- **AC-89 [L] R4/R8.4 — hitstop do golpe × pesado do impacto.** Saco móvel em
  preparação, um roteiro por linha, toque em 0:

  | Golpe | Saco em | Hitstop | `pesado` no `acerto` | `peso_visual` | "Quebrou!" | x após 0 |
  |---|---|---|---|---|---|---|
  | **Onda-270** (FP-R; Onda com empurrão 270) | (1100; 540) | 6 (Especial, R4) | falso (270 < 900) | pesado | nenhum | 1104,5 |
  | **Corte-900** (FP; Corte com empurrão 900), 1º golpe do combo | (1060; 540) | 6 (empurrão ≥ 900) | verdadeiro | pesado | 1 pedido (Saco, 24) | 1075 |
  | Corte da FP, 1º golpe | (1060; 540) | 3 | falso | leve | nenhum | 1067,5 |

  Nas três linhas o Saco cambaleia. O Corte-900 dá CV8 na validação (AC-62).
- **AC-90 [L] R8 — dano de status (`de_status`)** (provisório: Status dublê;
  com o real na AC-70). FP, nenhum toque. No turno do alvo no item 7 do passo
  0, o Status dublê chama `ferir_inimigo` com `de_status` e dano 5:
  - Saco móvel em preparação em (1060; 540): Vida 995; nenhum `acerto`, nenhum
    `acerto_de_arma`, `vel_empurrao` 0, cambaleio 0, nenhum pedido de
    "Quebrou!", nenhum pedido de hitstop; contador de acertos 0;
  - Saco surgindo: Vida 1000 (item 1 da R8);
  - Eco ferido (5): Vida 0; o impacto e a IA dele são pulados (R14); sai na
    varredura do passo 0 com `inimigo_morreu` e hitstop 4; com `cura_ao_abater`
    5 e Vida 90, a Vida vai a 95.
- **AC-97 [L] R15/R17 — durações visuais nos eventos.** Com o `CombatTuning`
  de fábrica, o espião confere: `acerto` do 1º Corte da AC-06 com
  `flash_passos` 5; `jogador_atingido` de um golpe de 9 (hitstop 6) com
  `inversao_passos` 10 e `invuln_passos` 40; `recusou_morte` com
  `impact_passos` 18; `inimigo_morreu` do Chefe da AC-10 com `impact_passos`
  12, e de um Eco com 0. Com `impact_chefe_s` 0,6 (36 passos) e
  `hitstop_abate_chefe_s` 0,5 (30), ambos dentro das faixas, o validador
  registra o aviso CV22 e nenhum erro de faixa.
- **AC-91 [L] R17 — campos dos eventos e `peso_visual`.** O espião confere os
  campos da tabela da R17 nos roteiros indicados:
  - `golpe` (FP, Eco em (1060; 540), Ataque tocado em 0): posição (960; 540),
    mira (1; 0), slot Ataque, `alcance_px` 142,5, `meio_angulo_graus` 69,51,
    pesado falso, 1 alvo; no 3º Corte da AC-38, pesado verdadeiro. `area` (Onda
    da AC-26): centro (960; 540), `raio_px` 195, slot Especial, pesado
    verdadeiro. `investida` (AC-33): posição (960; 540), direção (1; 0), N 10.
  - `acerto`:

    | Roteiro | Slot / forma | `pesado` | `peso_visual` |
    |---|---|---|---|
    | 1º Corte num Saco (AC-06) | Ataque / arco | falso | leve |
    | 3º Corte, finalizador (AC-38) | Ataque / arco | verdadeiro | pesado |
    | Quarto acerto num Corte leve: C da AC-37 (a) | Ataque / arco | verdadeiro | pesado |
    | Onda-270 (AC-89) | Especial / circulo | falso | pesado |
    | Investida: S1 / S2 da AC-34 | Especial / avanco | verdadeiro / verdadeiro | pesado / leve |
    | Pulso (AC-31, 1º bullet) | Ataque / projetil | falso | leve |
    | 3º Pulso-combo, finalizador (AC-31) | Ataque / projetil | verdadeiro | pesado |
    | Pulso com `dano_enesimo_acerto` (`a_cada` 1, valor 0,6) no portador: dano 19,2, quarto acerto | Ataque / projetil | verdadeiro | leve |
    | Parede (AC-46 a), reflexo (AC-51), Corte da esquiva (AC-85), explosão (AC-56) | — (`de_arma` falso) | falso | leve |

  - direção do `acerto` da parede = do jogador ao inimigo (R11.3): (1; 0) na
    AC-46 (a); no canto da AC-47, com o Saco preso em (1896; 1056),
    (0,8757; 0,4828) ±0,0001, que não é a direção do empurrão (0,6; 0,8) nem a
    normal da parede. `parede` da AC-46 (a): alvo o Saco, posição (1896; 540),
    normal (−1; 0);
  - `jogador_atingido`: Vida perdida e direção do atacante ao jogador,
    (−0,6; −0,8) na AC-51; no projétil da AC-32, a do voo, (−1; 0);
  - `inimigo_morreu`: Corte que mata um Eco ferido (14) em (1060; 540):
    posição (1060; 540), elite falso, chefe falso, `vel_empurrao` (450; 0);
    Onda (FP-R) que mata uma Elite com Vida 30 em (1100; 540): elite
    verdadeiro, `vel_empurrao` (504; 0) (1260 × 0,4). A posição lógica do morto
    não muda (R14; o deslize é só da V12);
  - `recusou_morte` da AC-53: Vida nova 40. `explosao` da AC-56: posição do
    morto, `raio_px` 60.

  Slot e forma são conferidos só com `de_arma` verdadeiro (a R17 não diz o
  valor nos impactos sem arma).

**H. Empurrão e parede**

- **AC-45 [L] R11/F7 — percurso do empurrão.** FP, alvo em (500; 300). No item
  6 do passo 0, o Selo dublê chama `ferir_inimigo(dano 0, direção (1; 0),
  empurrão E)`:

  | Alvo | E de entrada | 1º deslocamento (passo 0) | n (passos 0…n−1) | Distância |
  |---|---|---|---|---|
  | Saco móvel | 270 | 4,5 | 17 | 20,1550 |
  | Saco móvel | 450 | 7,5 | 19 | 33,7872 |
  | Saco móvel | 900 | 15,0 | 22 | 67,8936 |
  | Saco móvel | 1080 | 18,0 | 23 | 81,5484 |
  | Saco móvel | 1260 | 21,0 | 23 | 95,1398 |
  | Elite | 900 (360) | 6,0 | 18 | 26,9612 |
  | Chefe | 900 (108) | 1,8 | 13 | 7,8582 |

  `vel_empurrao` = 0 após o passo n − 1, e nada se move a partir do passo n.
- **AC-46 [L] R11/F8 — impacto na parede.** FP. No item 6 do passo 0, o Selo
  dublê chama `ferir_inimigo` com direção (1; 0):
  - (a) Saco móvel em (1846; 540), E = 1260: x = 1867 após 0 e 1883,38 após 1.
    No passo 2, a posição é corrigida para 1896 com v = 766,584 ≥ 630. Então:
    - evento `parede`, `vel_empurrao` = 0;
    - impacto com dano 8 (Vida 992), empurrão 0, não pesado, **sem
      cambaleio**, sem `acerto_de_arma`; o `acerto` tem direção (1; 0), do
      jogador ao Saco (R11.3), e `peso_visual` leve;
    - o contador de acertos não muda;
    - hitstop 3 (passos 3–5 congelados).
  - (b) Saco móvel em (1845,8; 540), E = 1260: corrigido no passo 3 com
    v = 597,9355. Não bate, não toma dano e não pede hitstop; após 3,
    `vel_empurrao` = 466,3897.
  - (c) como (a), com o portador do jogador com Ataque +25%: dano 10.
  - (d) E = 900: em (1870; 540), bate no passo 1; em (1869; 540), não bate.
  - (e) E = 450 e E = 270, com o Saco móvel em (1896; 540): não bate.
  - (f) Elite em (1871,2; 540) com duas chamadas de 1260 no mesmo passo
    (v0 = 1008): bate no passo 1. Com uma chamada (504), em (1891,2; 540): não
    bate.
- **AC-47 [L] R11/Edge — canto, obstáculo e separação.** FP, E = 1260:
  - Saco móvel em (1876; 1036), direção (0,6; 0,8): 1 batida, no passo 1, em
    (1896; 1056); 1 evento `parede` e dano 8 uma vez;
  - obstáculo (1100; 540; r 42) e Saco móvel em (1000; 540), direção (1; 0):
    x = 1021 após 0; no passo 1, corrigido para 1034 e bate;
  - Sacos móveis em (1000; 540) e (1040; 540), o primeiro empurrado em (1; 0),
    com a IA dublê sem separação: nenhum evento `parede` e nenhum dano de
    parede (provisório: ver AC-67).

**I. Dano no jogador**

- **AC-48 [L] R13/F10 — fórmula.** FP, lista vazia ("em combate" verdadeiro
  pela FP). O teste chama `ferir_jogador` sem atacante no passo 0, cada linha
  num roteiro novo. "Guarda sim": a fixture põe o contador de guarda em 6
  antes do passo 0 (5 depois da R2 do passo 0, ativa):

  | `dano_base` | M_atacante | Redução (portador) | Guarda | Dano | Vida |
  |---|---|---|---|---|---|
  | 9 | 1 | 0 | não | 9 | 91 |
  | 13 | 1,25 | 0 | não | 16 | 84 |
  | 13 | 1,25 | 0,12 | não | 14 | 86 |
  | 9 | 1 | 0 | sim | 5 | 95 |
  | 1 | 0,4 | 0 | não | 1 | 99 |
  | 9 | 1 | −0,2 | não | 9 | 91 |
  | 9 | 1 | 0 | sim, `fator_guarda` 0 | 1 (max(1, 0)) | 99 |
  | 9 | 1 | 0 | sim, `fator_guarda` 1 | 9 | 91 |

  Em todas as linhas: invulnerabilidade 40, 1 pedido de hitstop 6 e 1
  `jogador_atingido` com a Vida perdida. Com invulnerabilidade > 0 ou com
  "em combate" falso: nada (sem evento, sem hitstop, Vida 100).
- **AC-49 [L] R13.3–4/Edge — escudo.** FP:
  - escudo 10, dano 14: absorve 10, Vida perdida 4, Vida 96, escudo 0;
  - escudo 20, dano 9: Vida perdida 0, escudo 11, Vida 100. Mesmo assim:
    invulnerabilidade 40, hitstop 6 e `jogador_atingido(0)`;
  - nessa segunda linha, com `refletir_dano` 3,0 e atacante corpo a corpo,
    nada é refletido.
- **AC-50 [L] R13/F10/Edge — dois inimigos e o teto.** FP, Ecos A e B, nesta
  ordem, os dois corpo a corpo, chamam `ferir_jogador(9)` no passo 10:
  - Vida 91, 1 evento e 1 pedido de hitstop (passos 11–16 congelados);
  - B chama de novo no passo 55: nada; no 56: Vida 82, 46 passos depois do
    primeiro.
- **AC-51 [L] R13.6 — refletir.** FP, `refletir_dano` 3,0, Eco A corpo a corpo
  em (990; 580). A chama `ferir_jogador(13, M 1,25, A)` no passo 0, com
  redução 0,12 e escudo 10:
  - Vida perdida 4; A recebe 12 (Vida 18), sem M, com empurrão 0 e **sem
    cambaleio**;
  - há `acerto` de A, com direção (0,6; 0,8) (do jogador ao atacante), sem
    `acerto_de_arma`, e o contador de acertos não muda;
  - o único pedido de hitstop é o 6 do jogador atingido (o reflexo não pede);
    `jogador_atingido` tem direção (−0,6; −0,8).
- **AC-52 [L] R13.6–7/Edge — refletir antes da morte; morte e último inimigo
  no mesmo passo.** FP, Vida 5, sem recusa, `refletir_dano` 3,0, Eco ferido
  (20) A como único inimigo. A chama `ferir_jogador(9, 1, A)` no passo 0:
  - A recebe 27 (Vida −7);
  - a Vida do jogador fica em 0 e sai `jogador_morreu`;
  - A sai na varredura do mesmo passo e a lista fica vazia;
  - ordem dos eventos: `jogador_atingido`, `acerto`(A), `jogador_morreu`,
    `inimigo_morreu`(A).

  Que a câmara não conte como limpa está na AC-69.
- **AC-53 [L] R13.7 — recusa.** FP, `recusas_morte` total 1 (vida_ao_voltar
  0,4, invuln_s 2,0), Vida 5/100:
  - `ferir_jogador(9)` no passo 0: Vida 40, invulnerabilidade 120, recusas 0,
    hitstop 18 (passos 1–18), eventos `jogador_atingido` e `recusou_morte`, e
    nenhum `jogador_morreu`;
  - `ferir_jogador(50)` no passo 137: nada. No passo 138: Vida 0 e
    `jogador_morreu`;
  - com `recusas_morte` total 2: o passo 0 dá o mesmo resultado, com recusas 1;
    `ferir_jogador(50)` no 138 leva a Vida a −10 e gasta a 2ª: Vida 40,
    invulnerabilidade 120, recusas 0, hitstop 18 (passos 139–156),
    `recusou_morte` e nenhum `jogador_morreu`; `ferir_jogador(50)` no 275 não
    faz nada, e no 276 dá Vida 0 e `jogador_morreu`;
  - com `vida_max` 3, a Vida volta a 1 (round(1,2)); com `vida_max` 1, volta a 1
    (max(1, 0)).

  `vida_max` mudando no meio do combate segue a F4 do Modificadores: coberto
  pelos critérios do Modificadores, não aqui.
- **AC-87 [L] R13.1 — "em combate" é consulta das Câmaras** (provisório:
  Câmaras dublê; com as Câmaras reais na AC-69). FP:
  - (a) lista vazia e "em combate" verdadeiro (o vão entre ondas):
    `ferir_jogador(9)` sem atacante no passo 0 tira 9 (Vida 91), com
    invulnerabilidade 40, hitstop 6 e `jogador_atingido`. A lista vazia não
    basta para recusar o dano;
  - (b) Eco corpo a corpo em (700; 540) na lista e "em combate" falso:
    `ferir_jogador(9, 1, Eco)` no passo 0 não faz nada: Vida 100,
    invulnerabilidade 0, nenhum hitstop, nenhum evento;
  - (c) o projétil inimigo da AC-32, com "em combate" falso nos passos 0–11 e
    verdadeiro a partir do 12: no passo 11 (x = 992) segue sem dano e sem
    sumir; no 12 (x = 983) acerta, tira 11 e some;
  - (d) o golpe do jogador sai com "em combate" falso (AC-15).

**J. Varredura de mortes**

- **AC-54 [L] R14 — abate.** FP, Eco ferido (14) em (1060; 540), Ataque tocado
  em 0:
  - contagem de abates +1 e 1 `inimigo_morreu` (posição (1060; 540), elite
    falso, chefe falso), com hitstop 4;
  - com `cura_ao_abater` 5: Vida 97 → 100 (limitada); Vida 90 → 95.

  FP-R, Onda: uma Elite com Vida 30 dá hitstop 6; um Chefe com Vida 30, 36.
- **AC-55 [L] R14/Edge — o chefe zera os outros.** FP-R, Chefe com Vida 30 em
  (1100; 540) e Ecos em (500; 540) e (300; 300), fora da Onda. Especial tocado
  em 0:
  - 1º passe: sai o Chefe e os Ecos ficam com Vida 0;
  - 2º passe: saem os dois Ecos;
  - 3 abates, eventos na ordem Chefe, Eco, Eco; hitstop 36 (passos 1–36); lista
    vazia após 0;
  - com `cura_ao_abater` 5 e Vida 80: Vida 95.
- **AC-56 [L] R14/Edge — cadeia de mais de 4 passes** (retrato no início de cada passe, R14). FP, gatilho
  `explosao_ao_abater` (valor 30, raio 60, empurrão 0). Eco1 é um Eco ferido
  (14) em (1060; 540); Eco2 a Eco6 em x = 1140, 1220, 1300, 1380 e 1460, todos
  com y = 540. A lista está na ordem Eco6, Eco5, …, Eco1. Ataque tocado em 0:
  - no passo 0, morrem Eco1, Eco2, Eco3 e Eco4 (4 passes) e saem 4 eventos
    `explosao`; Eco5 fica com Vida 0;
  - hitstop 4 (passos 1–4);
  - no passo 5, Eco5 não age (a IA dublê não é chamada para ele), sai no 1º
    passe, e a explosão dele mata Eco6, que sai no 2º;
  - hitstop 4 (passos 6–9); 6 abates no total;
  - Eco1 não foi empurrado e explodiu de (1060; 540).
- **AC-57 [L] R14/Edge — a explosão pega o chefe.** FP, portador com Ataque
  +25%, `explosao_ao_abater` (valor 30, raio 160, empurrão 0), Eco ferido (14)
  em (1060; 540) e Chefe em (1060; 760), fora do arco. Ataque tocado em 0: o
  Chefe recebe 30 (não 37,5) e fica com Vida 670.
- **AC-88 [L] R14/R13.7 — morto não cura nem revive.** FP, Vida 5, sem recusa,
  portador com `cura_ao_abater` 5. Eco ferido (14) E1 em (1060; 540) e Eco B
  corpo a corpo em (700; 540), nesta ordem. Ataque tocado em 0; a IA dublê faz
  B chamar `ferir_jogador(9, 1, B)` no turno dele no passo 0:
  - item 5: E1 recebe 14 (Vida 0); item 7: E1 não age, B tira 9 e a Vida do
    jogador fica em 0, com `jogador_morreu`; item 9: E1 sai, com
    `inimigo_morreu` e hitstop 4, e a Vida do jogador **continua 0**;
  - eventos na ordem: `acerto`(E1), `golpe`, `jogador_atingido`,
    `jogador_morreu`, `inimigo_morreu`(E1); pedidos de hitstop 3, 6 e 4
    (contador 6);
  - com `explosao_ao_abater` (valor 30, raio 400, empurrão 0) também: a
    explosão de E1 tira 30 de B (a 360 px), que sai no 2º passe do mesmo
    passo: o resto do passo roda;
  - o Combate expõe "jogador morto" verdadeiro ao fim do passo 0 (o orquestrador
    real, que para os passos vivos, é da AC-05);
  - variante com `recusas_morte` 1 (vida_ao_voltar 0,4; invuln_s 2,0): a Vida
    volta a 40 no item 7, a cura do item 9 a leva a 45, e o hitstop é 18.

**K. Contrato com o Movimento**

- **AC-58 [L] contrato, com dublê.** FP, sem alvos, salvo quando indicado:
  - **desconto:** `garantir_invulneravel(12)` no passo 0. Um
    `ferir_jogador(9)` em qualquer passo de 0 a 11 não faz nada; no 12, tira 9;
  - **vale o maior:** pedidos de 25 no passo 0 e de 12 no 3: após 3, a
    invulnerabilidade é 22;
  - **recuperação:** Corte no passo 0. "Em recuperação" é verdadeira nos passos
    1–7 (7 passos lentos para uma recuperação de 8) e falsa no 0 e no 8;
  - **apoio:** com um Eco em (1126,5; 540), o teste de acerto usa x = 960, e o
    único `deslocar((10,5; 0))` chega depois do `acerto`;
  - **investida:** Especial no passo 0. O Movimento não aplica `d` no passo 0
    e aplica no 1; um Saco a 40 px não é testado no passo 0.
- **AC-59 [I] contrato com o Movimento real.** FP com o Movimento real
  (`MovementTuning` padrão):
  - (a) esquiva tocada no passo 0: um `ferir_jogador(9)` da IA dublê em
    qualquer passo de 0 a 11 não tira Vida; no 12 tira 9. Isso desbloqueia a
    AC-56 do Movimento.
  - (b) `mover` (1; 0) segurado, Ataque tocado em 0, sem alvo: x = 976,95 após
    0 (966,45 + 10,5); 2,9025 por passo nos passos 1–7 (997,2675 após 7); e
    1003,7175 após 8.
  - (c) `mover` (0; 0), Especial tocado em 0:
    - após k (1 a 3), x = 960 + 33k;
    - uma esquiva tocada no 4 cancela: o passo 4 anda só 22,5, e x = 1261,5
      após 12;
    - a invulnerabilidade vai a 12 no passo 4: `ferir_jogador(9)` no 15 não faz
      nada e no 16 tira 9.
- **AC-84 [L] R18 — `cancelar` e `garantir_invulneravel`.** FP, lista vazia,
  portador com `dano_apos_esquiva` (janela 60). Ataque tocado em 0 (Corte sem
  alvo); o Movimento dublê envia `garantir_invulneravel(20)` no passo 0,
  `esquiva_iniciada` no passo 1 e `cancelar` no passo 3, antes de ler "em
  recuperação":
  - após 3, recuperação 0 (era 5); a leitura de "em recuperação" é falsa no 3
    e no 4;
  - após 3, sem mudança pelo `cancelar`: recarga do Ataque 13, passo do combo
    do Ataque 1, janela de combo do Ataque 31, invulnerabilidade 17, janela
    `apos_esquiva` 58;
  - o `cancelar` da investida (contador a 0, alvos já atingidos ficam,
    recarga não volta) é a AC-35;
  - `garantir_invulneravel(n)` = max(atual, n): AC-35 (9 com n 12 → 12; com
    n 5 → 9) e AC-58 (25 e 12 → 22 após 3).
- **AC-85 [L] R18 — `aplicar_corte`.** FP, portador com `dano_enesimo_acerto`
  (`a_cada` 1, valor 0,6), Saco móvel em preparação em (1060; 540), nenhum
  toque. No passo 0, o Movimento dublê envia `aplicar_corte(Saco, 10, (1; 0),
  360, Sangramento 1)`:
  - 1 `acerto` com dano 10 (o M já veio do Movimento), `de_arma` falso, quarto
    acerto falso, pesado falso e `peso_visual` leve;
  - contador de acertos 0; nenhum `acerto_de_arma`, e os dublês de Selo e de
    Status não recebem acerto (sem Fluxo e sem `golpe_*`);
  - o Status dublê recebe Sangramento 1;
  - recebe `vel_empurrao` 360 no impacto; após 0, `vel_empurrao` 280,8
    (360 × 0,78), cambaleio 7 (8 − 1, R12) e x = 1066;
    nenhum pedido de "Quebrou!";
  - nenhum pedido de hitstop: o passo 1 é vivo.

  A AC-40 (c) cobre o mesmo pedido sem o gatilho de quarto acerto.
- **AC-86 [L] R18 — `esquiva_iniciada`.** FP, portador com `dano_apos_esquiva`
  +50% (`janela_s` 1,0: 60 passos), Saco em (1060; 540), "em esquiva" do dublê
  falsa. Roteiros separados:
  - `esquiva_iniciada` no passo 0: janela 60 após 0 e 50 após 10; um Corte
    tocado em 59 tira 21,0 (janela 1 no disparo); tocado em 60, tira 14,0 (a
    janela chegou a 0 na R2 do passo 60);
  - `esquiva_iniciada` nos passos 0 e 10: janela 60 após 10 (reinicia
    inteira); Corte tocado em 69 tira 21,0; em 70, 14,0;
  - portador sem `dano_apos_esquiva`: `esquiva_iniciada` no passo 0 deixa a
    janela em 0, sem erro, e um Corte no 0 tira 14,0;
  - a janela não desconta em passo congelado: AC-09 (b).

**L. Validação (CV1–CV22)**

> **Fixture de validação (FV):** o `CombatTuning` da FP; o catálogo com os
> quatro `AttackDef` da Lâmina e da Ressonância e o gatilho `corte_da_esquiva`
> com `empurrao` 360 (Movimento); dublês de Inimigos, Câmaras e IA com
> `r_min` 22,5, `r_obs_min` 42, `raio_jogador_px` 27 e um inimigo comum com
> Vida 30 e preparo W 8. Cada linha muda a FV só no que diz.
>
> Cada linha lista o **conjunto exato** de entradas do validador (erros de
> faixa deste GDD, "faixa", e regras CV); uma entrada a mais ou a menos
> reprova. Convenção destes critérios: numa regra "erro / aviso", cada objeto
> dá uma entrada só (erro se a condição de erro vale, senão aviso), e o CV1 é
> uma entrada só, com todas as causas. Erros do V2 do Conteúdo ficam fora da
> comparação.
>
> Igualdades com decimais não representáveis em binário são testadas a
> ±0,001 da borda, nunca nela: 14 × 3,8 = 53,199999999999996 e 240 × 0,12 =
> 28,799999999999997 em double; o 0,33 do CV2 nunca é testado em igualdade.

- **AC-60 [L] CV1/CV2/CV21 — hitstop.**

  | Mudança (passos) | Conjunto exato |
  |---|---|
  | FV (3 ≤ 4 ≤ 6 ≤ 36; atingido 6; recusa 18); Lâmina f_cong = 12/60 = 0,20 | nenhum |
  | leve 4, abate 4, atingido 4 (0,0667 cada) | nenhum (igualdades) |
  | leve 4, abate 4, atingido 3 (0,05) | CV1 (leve > atingido) |
  | abate 7 (0,1167) | CV1 (abate > pesado) |
  | pesado 12, abate de chefe 12 (0,2 cada) | CV1 (recusa 18 > abate de chefe 12) |
  | pesado 12, abate de chefe 18 (0,3, = recusa) | nenhum |
  | pesado 12, abate de chefe 12, atingido 13 (0,2167) | CV1 (atingido > abate de chefe; recusa > abate de chefe) |
  | atingido 15 (0,25), recusa 6 (0,1) | CV1 (recusa < atingido) |
  | recusa 36 (0,6), abate de chefe 30 (0,5) | CV1 (recusa > abate de chefe) |
  | recusa 36, abate de chefe 36 | nenhum |
  | leve 6 (0,1), pesado 11 (0,1833): f_cong = 23/71 = 0,324 | CV1 (leve > abate) |
  | leve 6, pesado 12: f_cong = 24/72 = 0,333… | CV1 (leve > abate); CV2 |
  | `invuln_atingido_s` 0,25 (15) e atingido 0,25 (15) | CV21 |
  | `invuln_atingido_s` 0,25 (15) e atingido 0,2333 (14) | nenhum |
- **AC-61 [L] CV3/CV4/CV5 — combo.**

  | Mudança | Conjunto exato |
  |---|---|
  | `limiar_finalizador` 0,99 | faixa (`limiar_finalizador`); CV3 **erro** |
  | `limiar_finalizador` 1,0 | nenhum (só 1,8 > 1,0) |
  | Corte com combo [1; 1; 1,2] (limiar 1,2) | CV3 aviso (Corte: sem finalizador) |
  | [1,5; 1; 1,8] | CV3 aviso (Corte: dois finalizadores) |
  | `limiar_finalizador` 1,45 com [1; 1; 1,8] | nenhum |
  | [1; 0; 1,8] | CV4 **erro** |
  | [1; −0,5] | CV3 aviso (nenhuma entrada > 1,2); CV4 **erro** |
  | [] (lista vazia) | CV3 aviso; CV4 **erro** |
  | [0,001] | CV3 aviso (sem CV4) |
  | Corte com recarga 0,55 (R = 33), J = 34 | nenhum |
  | Corte com recarga 0,5667 (R = 34) | CV5 **erro** |
  | Pulso, sem combo, com recarga 0,5667 | nenhum |
- **AC-62 [L] CV6/CV7/CV8 — empurrão.** FV. O fator do chefe no CV6 é a
  constante `fator_empurrao_chefe` (0,12, `ModifiersTuning`), e não sai da
  lista de inimigos (a FV não tem chefe): o menor empurrão efetivo da FV é
  270 × 0,12 = 32,4 (Pulso). O "maior empurrão leve" do CV7 é o `empurrao`
  dos Ataques, sem o finalizador, e o do Corte da esquiva: 450 na FV.

  | Mudança | Conjunto exato |
  |---|---|
  | `empurrao_zero` 0 / `queda_empurrao` 0 / `queda_empurrao` 1 | faixa do campo; CV6 **erro** |
  | Pulso com empurrão 240 e `empurrao_zero` 28,801 | CV6 aviso |
  | o mesmo, com `empurrao_zero` 28,799 | nenhum |
  | `empurrao_zero` 30 com a FV (30 < 32,4) | nenhum |
  | `parede_vel_min` 4,5 (= `empurrao_zero`) | faixa (`parede_vel_min`); CV7 **erro** |
  | Corte com empurrão 630 e `parede_vel_min` 630 | CV7 aviso |
  | Corte com empurrão 629,99 | nenhum |
  | `parede_vel_min` 900 e `empurrao_pesado` 900 | nenhum |
  | `parede_vel_min` 900 e `empurrao_pesado` 899 | CV7 aviso |
  | Corte com empurrão 460 e `empurrao_pesado` 460 | CV7 aviso (630 > 460); CV8 |
  | `empurrao_pesado` 460 com a FV | CV7 aviso (630 > 460) |
  | `empurrao_pesado` 1080 (= Investida) | nenhum |
- **AC-63 [L] CV9/CV10/CV11/CV13/CV15 — limites de um campo.**

  | Mudança | Conjunto exato |
  |---|---|
  | `fator_recuperacao_golpe` −0,01 / 1,01 | faixa; CV9 **erro** |
  | `fator_recuperacao_golpe` 0 / 1 | nenhum |
  | Corte com `recarga_s` 0 (R = 0) | CV2 (f_cong = 12/12); CV10 **erro**; CV17 (8 ≥ 0) |
  | Corte com `recarga_s` 0,0167 (R = 1) | CV2 (12/15 = 0,8); CV17 (8 ≥ 1) |
  | `passes_varredura` 0 / 1 | faixa e CV11 **erro** / nenhum |
  | Pulso com `vida_s` 0,0167 (L = 1) / 0,0333 (L = 2) | CV13 **erro** / nenhum |
  | Investida com recarga 0,2 (R = 12 = N + E) | CV15 **erro** |
  | Investida com recarga 0,2167 (13) / 0,3833 (23) | CV15 aviso (12/13; 12/23 = 0,52) |
  | Investida com recarga 0,4 (24): 12/24 = 0,5 | nenhum |
  | `invuln_extra_investida_s` 0 (E = 0) | CV15 aviso (E < 1) |
- **AC-64 [L] CV12/CV14/CV16–CV20 — validações cruzadas** (provisório:
  dublês de Inimigos, Câmaras e IA; a FV dá `r_min` 22,5, `r_obs_min` 42, raio
  do jogador 27 e o inimigo comum de Vida 30 e W 8; cada linha troca o que diz).

  | Mudança | Conjunto exato |
  |---|---|
  | FV (Pulso: s 16,5; raio 15; r_min 22,5) | nenhum |
  | Pulso com raio 1, r_min 15,5 (16,5 = 16,5) | nenhum |
  | raio 1, r_min 15,4 | CV12 aviso |
  | raio 1, r_min 7,25 (16,5 = 2 × 8,25) | CV12 aviso; CV20 (36 + 16,5 − 8,25 = 44,25 > 34,25) |
  | raio 1, r_min 7,2 | CV12 **erro**; CV20 |
  | `passo_apoio_px` 24, `raio_jogador_px` 10, r_min 14 (`r_obs_min` 42) | CV14 |
  | o mesmo, com r_min 14,001 | nenhum |
  | `passo_apoio_px` 24, raio do jogador 10, r_min 22,5, `r_obs_min` 14 / 14,001 | CV14 / nenhum |
  | Investida com 1830 px em N = 10 (183 = 183) / 1830,01 px | nenhum / CV16 |
  | `cambaleio_s` 0,15 (9) e Pulso R = 14 | nenhum |
  | `cambaleio_s` 0,15 e Pulso com recarga 0,15 (R = 9) / 0,1667 (10) | CV17 / nenhum |
  | `AttackDef` de teste com empurrão 0 e R = 1 | nenhum (ignorado pelo CV17) |
  | Inimigo comum com Vida 60 e W 25; Lâmina (n × R = 48; Q = 24) | CV18 |
  | Vida 60, W 24 (48 < 48 é falso) | nenhum |
  | Vida 53,19, W 25 / Vida 53,21, W 25 (dano × Σc = 14 × 3,8 = 53,199999999999996) | nenhum / CV18 |
  | `quebrou_recuperacao_s` 0,8 (Q = 48), W 1, Vida 60 | CV18 |
  | `raio_jogador_px` 50, `folga_encostado_px` 20, arco com alcance 70 / 70,001 | CV19 / nenhum |
  | `nascimento_projetil_px` 60, Pulso, r_min 17,25 / 17,2 | nenhum (44,25 = 44,25) / CV20 |
- **AC-65 [I] erros e avisos chegam ao destino.** Conteúdo real:
  - um catálogo com CV5 e CV10 violados é recusado com as 2 entradas (regra e
    campo) na lista de erros, e a run não começa;
  - um catálogo só com avisos (CV2, CV17, CV21) carrega, deixa a run começar e
    põe os avisos no registro de validação, com a lista de erros vazia;
  - um catálogo em Falhou deixa o Combate sem rodar;
  - um `AttackDef` com forma não registrada é erro V4 do Conteúdo.

  A captura da tela de erros é critério do GDD de Conteúdo.

**M. DPS de referência**

- **AC-66 [L] F11/F9.** FP ou FP-R, alvo Saco. O Movimento dublê não executa
  `deslocar` nem `d` neste critério.

  | Golpe, roteiro | Janela | Dano | DPS |
  |---|---|---|---|
  | Corte, Ataque segurado, Saco em (1060; 540) | passos 0–299 (15 golpes; 60 congelados) | 266,0 | 53,2/s real; 66,5/s vivo (240 passos vivos) |
  | Pulso, Ataque segurado, Saco em (1100; 540) | passos 0–839 (60 disparos, 60 acertos) | 720,0 | 51,43/s |
  | Onda, Especial segurado, Saco em (1100; 540) | passos 0–959 (10 golpes) | 300,0 | 18,75/s real |
  | Investida, Especial segurado, Saco em (1000; 540) | passos 0–759 (10 acertos, cada um no passo seguinte ao disparo) | 260,0 | 20,53/s real |

**N. Contratos com sistemas não escritos**

- **AC-67 [I] IA — GDD existe; AC a escrever com o dublê atual.** Com a IA
  real:
  - o pedido de "Quebrou!" põe o inimigo em recuperação por 24 passos e
    cancela a preparação;
  - "cambaleando" faz a IA andar a 40%, sem parar o relógio de ataque;
  - a separação entre inimigos nunca gera `parede`;
  - um inimigo morto no item 5 não ataca no item 7.
- **AC-68 [I] Telégrafos — GDD existe; AC a escrever com o dublê atual.** Para cada golpe
  inimigo do MVP, o conjunto de posições do jogador em que `ferir_jogador` é
  chamado é igual à área desenhada pelo telégrafo (amostragem em grade de 3 px).
- **AC-69 [I] Câmaras — GDD existe; AC a escrever com o dublê atual.**
  - Na troca de câmara real (a porta, só com hitstop 0, R10), a Transição
    segue a ordem da R1, e o aviso "câmara nova" chega no quadro da metade
    do wipe (as AC-10 (b) e AC-96 com as Câmaras reais).
  - No roteiro da AC-52, a câmara não conta como limpa depois de
    `jogador_morreu`.
  - O retângulo e os obstáculos reais substituem o dublê da AC-29 e da AC-47.
  - A consulta "em combate" real (porta fechada até câmara limpa, inclusive o
    vão entre ondas) substitui o dublê da AC-87 e da FP.
- **AC-70 [I] Selo e Status — GDD existe; AC a escrever com o dublê atual (Selo e Fluxo e Efeitos de status).**
  - `acerto_de_arma` soma Fluxo e aplica `golpe_*`.
  - O dano por passo do Status mata e dispara `cura_ao_abater`,
    `explosao_ao_abater` e o hitstop de abate (o dano de status não emite `acerto`, R8).

**O. Paridade com o cânone**

- **AC-71 [I] paridade** (`engine.ts`, só leitura), em duas partes, para uma
  falha dizer de que lado está.
  - **71a — Fixture.** Um script Node, fora do jogo, importa o `engine.ts` sem
    alterá-lo e roda o passo público sobre um `RunState` montado à mão:
    - arena de 1280×720 u, sem obstáculos aleatórios;
    - inimigos passivos (não atacam);
    - dois roteiros de ~900 passos, um com a Lâmina e outro com a Ressonância.

    Os roteiros cobrem:
    - combo completo, golpe sem alvo e vários alvos no arco;
    - investida com dois alvos;
    - Onda e Pulso;
    - empurrão até a parede e batida;
    - abates simples e em cadeia.

    Por passo, a fixture grava: entrada; posição do jogador e de cada inimigo
    (u); Vidas; recargas; passo do combo; contador de hitstop; eventos de
    acerto, parede e morte. Grava também o hash do commit do Khaeros. Saída
    versionada em `tests/integration/combat/fixtures/paridade_canone.json`. O
    teste não chama Node.
  - **71b — Teste.** No Godot, a FP é sobrescrita com a arena × 1,5 (px) e as
    velocidades × 90 (px/s). O Input dublê reproduz os botões gravados. Por
    passo:
    - posição do jogador e dos inimigos **com Vida > 0 ao fim do passo** =
      cânone × 1,5, com ±0,05 px. Inimigos com Vida ≤ 0 (que o cânone ainda
      move no passo da morte e o Khaeros não, R14), a posição do evento de
      morte e a origem da explosão ficam fora da comparação;
    - dano ±0,001;
    - hitstop, recargas, combo e eventos iguais (exato), salvo as posições
      acima.
  - **Divergências deliberadas, fora do roteiro:**
    - morto não age: nenhum inimigo morre a menos de 100 px da parede, e os
      inimigos são passivos; nas cadeias de explosão, cada vizinho fica a
      ≥ 24 px da borda do raio (dentro ou fora; o morto do cânone anda até
      21 px no passo da morte, Onda), para que a diferença de origem não mude
      quem é atingido;
    - teste de alvos da investida depois da colisão (R6): nenhuma investida
      passa a menos de 100 px de parede;
    - empurrão do projétil: o Pulso só acerta inimigos que morrem nesse
      acerto;
    - combo por slot: nenhum Especial com a janela de combo do Ataque aberta, e
      vice-versa;
    - hitstop da recusa: não há dano no jogador no roteiro.

    Essas divergências são cobertas pelas AC-44, AC-36, AC-31, AC-17 e AC-53.

**P. O que o jogador vê, câmera, áudio e desempenho**

> Base dos critérios [V]: build em 1920×1080, câmara de 1920×1080 com a câmera
> parada (1 px de mundo = 1 px de tela), no modo de passo a passo de depuração
> (um passo por comando; entre comandos o orquestrador chama
> `passo_congelado()`). As capturas ficam em `production/qa/evidence/`, com
> build e assinatura do lead. A sensação não é automatizada.

- **AC-72 [L] V14 — um impulso de câmera por passo** (provisório: Cena e
  câmera reais; OQ5). O Combate emite os eventos; o **Feedback é o único
  remetente** e escolhe um por passo (maior preset; empate: maior `escala`;
  `recusou_morte` vence `jogador_atingido`). FP ou FP-R, espião do
  pedido do Feedback à Cena. Exatamente 1 pedido por passo, ou nenhum:

  | Passo com | Pedido |
  |---|---|
  | golpe sem alvo; `disparo`; início da investida | nenhum |
  | Corte leve com 1 alvo | leve 1,0, direção da mira |
  | Corte finalizador; Onda com alvo | pesado 1,0, mira |
  | 1º alvo da investida / 2º alvo | pesado 1,0, `d` / leve 0,5, `d` |
  | acerto de Pulso leve / de Pulso-combo pesado | nenhum / leve 0,6, direção do voo |
  | acerto de Pulso com quarto acerto (`peso_visual` leve, AC-91) | nenhum |
  | `parede` | leve 1,0, direção do empurrão |
  | `jogador_atingido` por atacante em (1100; 540) | pesado 1,0, direção (−1; 0) |
  | Corte leve que mata um Eco ferido (14) | leve 1,0, mira (vence o leve 0,6 da morte) |
  | Onda que mata um Chefe com Vida 30 | chefe, vetor nulo |
  | explosão com morte comum | leve 0,6, vetor nulo |
- **AC-73 [V] V1/V2 — hitstop e forma igual ao teste.** FP, Saco em
  (1060; 540), 3º Corte. Capturas no passo do contato, no 2º congelado e no 1º
  vivo depois:
  - o *smear* é uma meia-lua aberta com contorno tracejado fino só na borda de
    fora (o contorno tracejado é **provisório**: viabilidade em aberto, OQ4); o raio de fora é 142,5 ± 3 px e a abertura ±69,5° ± 2°, conferidos
    contra o contorno de depuração do teste;
  - nos congelados, o jogador segura o quadro de contato e o Saco o flash,
    imóveis, na posição deixada pelo passo do golpe (V1);
  - nenhum golpe do jogador usa a borda de 4 px, o magenta ou L* ≥ 88;
  - um golpe sem alvo mostra o *smear*, sem estrela e sem fagulha.
- **AC-74 [V] V3/V4 — área e projétil.**
  - Onda: o anel tracejado em osso vai de 40% a 100% de 195 px em 4 passos e
    some até o passo 10; nunca é preenchido. "Fica abaixo de um telégrafo
    ativo": **BLOQUEADO até o GDD de Telégrafos**.
  - Pulso: o glifo tem raio de 15 ± 1 px; nas capturas em tons de cinza e no
    conta-gotas, nenhum pixel do projétil tem matiz magenta; no
    Pulso-leque, todos os projéteis são iguais.
- **AC-75 [V] V5/V6/V7 — investida e acerto.**
  - Investida: pose de arranque só no passo 0 e rastro de tinta sem as imagens
    residuais da esquiva.
  - Estrela leve de 64 ± 4 px e pesada de 112 ± 6 px, sempre aberta (nunca
    disco).
  - Quarto acerto: o número dourado de 36 px sempre; a estrela segue o
    `peso_visual` (pesada no arco, leve no Pulso). O dourado não
    aparece em nenhum outro VFX de combate.
  - Número de dano em osso, 28 px, que some em ≤ 36 passos do orquestrador
    (vivos ou congelados: o número corre no relógio de apresentação, V1),
    contados nas capturas passo a passo.
- **AC-76 [V] V8/V9 — parede e "Quebrou!".**
  - Parede: meia estrela de 96 px colada na parede e rachadura só na parede.
  - "Quebrou!": letreiro de ~44 px a −8°, legível em tons de cinza, e marca de
    três traços por 24 passos.
  - Com dois "Quebrou!" no mesmo passo, sai um letreiro só.
  - O telégrafo partido fica **BLOQUEADO até o GDD de Telégrafos**.
- **AC-77 [V] V10/V11 — jogador atingido e recusa.**
  - Atingido: a inversão de silhueta dura 6 + 4 passos e o contorno tracejado
    em osso dura exatamente 40 passos, sem piscar; sem vermelho e sem tela
    cheia (contorno tracejado **provisório**, OQ4).
  - Recusa: o *impact frame* (tinta L* ≤ 10, Iniciado em osso L* ≥ 88) é
    segurado pelos 18 passos, com as silhuetas desenhadas por cima. Os
    telégrafos por cima: **BLOQUEADO até o GDD de Telégrafos**.
- **AC-78 [V] V12/V13 — abates.**
  - Morte de inimigo comum em ≤ 30 passos.
  - Elite: a coroa estilhaça e não há *impact frame*.
  - Chefe (abate no passo 0): *impact frame* nos passos congelados 1–12 dos
    36.
  - Preempção (Pipeline visual R7, F6): chefe abatido 0,5 s depois de uma
    recusa (a recusa já saiu da tela, mas ocupa a janela de 1 s) → o *impact
    frame* do chefe aparece mesmo assim. Recusa e abate de chefe no mesmo
    passo → só o do chefe. O corte de uma recusa ainda na tela é da
    AC-PV-63 do Pipeline (relógio roteirizado).
  - Explosão: anel em osso, nunca magenta.
- **AC-79 [V] AC1 — acessibilidade.**
  - As capturas da AC-73 à AC-78 passam pelos 3 simuladores de daltonismo e
    por tons de cinza. Em cada uma, o golpe do jogador se distingue do
    telégrafo por dois critérios medidos (**proposta**, a confirmar pelo
    art-director): padrão de traço (tracejado no golpe × sólido no telégrafo)
    **e** ΔL* ≥ 20 entre os dois traços, no conta-gotas. As capturas com
    telégrafo: **BLOQUEADO até o GDD de Telégrafos**.
  - Toggles — "Reduzir flashes" troca o *impact frame* pelo mundo
    dessaturado; números "desligado" removem números e "Quebrou!"; o tremor a
    0% mantém hitstop, estrela e flash: **BLOQUEADO até o GDD de
    Acessibilidade e opções**.
- **AC-80a [M] A1 — áudio provisório.**
  - O testador dispara 10 vezes cada evento (`golpe`, `area`, `disparo`,
    `investida`, `acerto` leve e pesado, `parede`, `quebrou`,
    `jogador_atingido`, `recusou_morte`, `inimigo_morreu`, `explosao`) e ouve um
    som em cada disparo.
  - Registro com testador, build e contagem. A mixagem fica com o
    audio-director.
- **AC-80b [L] A1 — eventos iguais no mesmo passo soam como um** (provisório:
  camada de áudio do GDD de Áudio; OQ5). Camada de
  áudio com espião de pedidos de som: no máximo 1 pedido por tipo de som por
  passo. No passo 0 da AC-24 (3 `acerto` leves), 1 pedido de `acerto` leve; no
  passo 19 da AC-37 (a) (2 leves e 1 quarto acerto), 1 de `acerto` leve e 1 de
  `acerto` pesado; no passo 0 da AC-55, 1 de `inimigo_morreu` por tipo de
  inimigo (chefe e comum).
- **AC-81 [P] desempenho** (em `tests/performance/combat/`, mesmo desvio da
  AC-48 do Movimento).
  - Roteiro: 10 000 passos com 9 inimigos (6 Ecos, 2 Elites e 1 Chefe com Vida
    10⁹) e exatamente 6 projéteis em voo (3 do jogador e 3 de inimigos,
    recriados ao sumir). Ataque e Especial segurados e golpes com 9 alvos, com
    empurrões e batidas na parede.
  - Medida: soma dos itens 3, 5, 7 (impacto), 8 e 9 por passo, com
    `Time.get_ticks_usec`, headless, no PC de desenvolvimento. Os primeiros
    300 passos são aquecimento e ficam fora da medida.
  - **Passa com p99 ≤ 0,3 ms**; falha acima. Provisório até haver orçamento por
    sistema.
  - Registro em `production/qa/evidence/combate-desempenho-[data].md`, com
    CPU, RAM, SO, build, média e p99.
- **AC-92 [P] latência do golpe** (proposta; em `tests/performance/combat/`,
  build de desenvolvimento, 60 Hz, vsync ligado). Log com timestamps
  (`Time.get_ticks_usec`) do evento de entrada do Ataque e do primeiro quadro
  desenhado com o *smear* daquele golpe (sinal de fim de desenho do quadro; a
  API exata é conferida na referência do 4.7). Em 100 toques com a recarga em
  0, fora de esquiva e de investida, o maior atraso é ≤ 2 passos + 1 quadro
  (≤ 50,0 ms a 60 Hz). Registro em
  `production/qa/evidence/combate-latencia-[data].md`, com CPU, RAM, SO, build
  e os 100 valores.

**Q. A promessa do P3**

- **AC-82 [M] nenhum golpe engolido.** Sessão de 30 minutos com o log de
  depuração de toques, recargas, esquiva, investida, hitstop e disparos por
  passo. Um script de análise do log acha:
  - 0 toques de Ataque ou Especial feitos em passo vivo, com a recarga do slot
    em 0 após o item 3, fora de esquiva e de investida, sem disparo do outro
    slot no mesmo passo, que não saíram no mesmo passo; e
  - 0 toques guardados cujo prazo cobria um passo vivo elegível (as mesmas
    condições) e que não saíram nele.

  Registro com testador, build e o log.
- **AC-83 [M] nenhuma morte sem telégrafo — GDD existe; AC a escrever com o dublê atual.** Sessão de 30 minutos: em 0 acertos no jogador falta um
  telégrafo visível antes, no log.

Cobertura (versão 2): cada regra, fórmula e validação tem ao menos um
critério.
- **Regras:** R1 AC-05; R2 AC-09, AC-22, AC-58; R3 AC-12–AC-22; R4 AC-23–AC-25,
  AC-89; R5 AC-26; R6 AC-14, AC-27, AC-31, AC-33–AC-36; R7 AC-27–AC-32,
  AC-87 (c); R8 AC-37–AC-44, AC-89, AC-90; R9 AC-30, AC-43; R10 AC-06–AC-11;
  R11 AC-45–AC-47; R12 AC-41; R13 AC-48–AC-53, AC-87; R14 AC-44, AC-54–AC-57,
  AC-88; R15 AC-01, AC-03; R16 AC-02, AC-04; R17 AC-24 (ordem), AC-91; R18
  AC-84–AC-86, com AC-35, AC-40 (c) e AC-58.
- **Fórmulas:** F1 AC-08, AC-16, AC-37; F2 AC-22; F3 AC-31, AC-38, AC-89; F4
  AC-23, AC-26; F5 AC-27, AC-28; F6 AC-33–AC-36; F7 AC-39, AC-45; F8 AC-46,
  AC-47; F9 AC-07, AC-08, AC-60; F10 AC-48–AC-50, AC-53; F11 AC-66.
- **Validação:** CV1, CV2 e CV21 AC-60; CV3–CV5 AC-61; CV6–CV8 AC-62; CV9–CV11,
  CV13 e CV15 AC-63; CV12, CV14 e CV16–CV20 AC-64; destino AC-65. As faixas
  dos 27 campos do `CombatTuning` estão na AC-03.

Lacunas assumidas:
- **VFX:** agregação de números em 300 ms, teto de 6 números, limitador de 3
  flashes/s e orçamento em multidão (V15) ficam para os critérios do GDD de
  Feedback de combate.
- **Paridade do dano no jogador:** fica fora da AC-71 (inimigos passivos).
- **A escrever com o dublê atual (GDDs existem):** AC-67, AC-68, AC-69, AC-70, AC-83. **Bloqueadas:** as partes marcadas das
  AC-74, AC-76, AC-77 e AC-79.

Esclarecimentos decididos em 2026-11-09 (o texto das regras foi alinhado):
- saída do validador: uma entrada por regra e por objeto; o erro vence o aviso
  da mesma regra; o CV1 é uma entrada só, com todas as causas;
- o CV3 é avaliado mesmo numa lista de combo inválida (CV4);
- `acerto` sem arma: slot "nenhum" e forma = origem (`corte`, `parede`,
  `reflexo`, `explosao`) (R17; o Selo não emite `acerto`, decisão do usuário, 2026-11-10);
- `aplicar_corte` com empurrão ≥ `empurrao_pesado` é pesado pela R8.4, mesmo com
  `pesado` falso na entrada (cânone; R18);
- `vel_empurrao` do `inimigo_morreu` é a velocidade total do alvo no momento da
  morte, já com o golpe que o matou (R17);
- os números da AC-92 (latência) e o ΔL* da AC-79 são proposta (Open Questions).

## Open Questions

| # | Pergunta | Dono | Resolver até |
|---|---|---|---|
| 1 | Detecção de acertos com círculos e distâncias próprios (cânone) ou com `Area2D`; orquestrador do passo (R1). A referência do motor não cobre a física 2D do 4.7 | technical-director + godot-specialist | ADR, antes de `/create-architecture` |
| 2 | Contratos provisórios: IA (estado, pedido de "Quebrou!", `ferir_jogador`, `disparar_projetil`, separação entre inimigos), Telégrafos (forma = teste de acerto; telégrafo que se parte, V9), Câmaras (geometria, pedido de troca e estado Transição, consulta "em combate", "câmara limpa" só com hitstop 0, ignorar "câmara limpa" depois de `jogador_morreu`), Selo (`acerto_de_arma`, `ferir_inimigo`), Status (`ferir_inimigo` com `de_status`) | donos de cada GDD | ao escrever cada um |
| 3 | Trava do "Quebrou!" (CV18) e cambaleio × recarga (CV17): no Veio, o finalizador da Lâmina quebraria toda preparação do Estilhaço Vivo. Toca a regra do baseline §55 de que o relógio do inimigo não para | game-designer + creative-director, no `/balance-check` | antes do Veio Instável (Alpha) |
| 4 | Linhas novas no Art Bible (lista na Visual/Audio); viabilidade do contorno tracejado no rig e do `speed_scale` dos emissores no hitstop (NÃO VERIFICADO no 4.7.2) | art-director + technical-artist | antes de produzir os VFX do combate |
| 5 | Requisitos de áudio provisórios (Visual/Audio A1) | audio-director | GDD de Áudio |
| 6 | Índice: o ciclo Combate ↔ IA em "Circular Dependencies" e a linha 8 sem "IA (por contrato)" e "Câmaras e ondas (suave)" | usuário / producer | próxima edição do índice |
| 7 | O "alcance" informativo do F6 do Conteúdo (825 px no Pulso) não é o alcance testado (844,5 px, F5 deste GDD). Ajustar a linha informativa do Conteúdo? | dono do Conteúdo | próximo `/review-all-gdds` |
| 8 | A guarda do Guardião (`guarda_s`, × 0,5) é regra deste GDD ou vira modificador temporário (Modificadores OQ4) | game-designer | GDD de Armas, fatia vertical |
| 9 | Letreiro "Quebrou!": desenhado por idioma ou fonte com estilo de letreiramento | art-director + localization-lead | fatia vertical |
| 11 | ~~Troca de câmara com investida ativa ou recuperação~~ **Resolvida em 2026-11-10** (cross-review, S-B1 e S-W2): investida e recuperação zeram na câmara nova; os outros contadores passam como estão (R10) | — | ✅ |
| 10 | Números propostos nos critérios: latência da AC-92 e ΔL* ≥ 20 da AC-79; a API de fim de quadro do 4.7 citada na AC-92 não foi conferida | qa-lead + art-director + godot-specialist | antes da story de VFX do combate |
