# Armas das Doutrinas

> **Status**: Approved
> **Author**: usuário + Claude (design-system, modo Lean; emenda Pactos aprovada pelo usuário em 2026-11-16)
> **Last Updated**: 2026-11-18

> **Nota (emenda Pactos, 2026-11-15, aprovada pelo usuário em 2026-11-16):** a Besta do Vínculo (Doutrina de Pactos) entra no MVP como 3ª arma, com os números de `maldicoes.md` §Constantes (l. 462) sem mudança. Acrescentados: R2b (`WeaponDef pactos`, Virote, Chamado do Pacto, evento `acerto_virote`), F7 (DPS composto Besta + Maldição, leitura da F6 de Maldições), contas das F1–F6 para a Besta, AV9, Edge Cases, Dependencies (Maldições, Forte, bidirecional), ACs AC-AR-41 a 52 e Open Questions 11–16. O texto aprovado antes da emenda fica; onde ele diz "duas armas", vale a R2b.
> **Last Verified**: 2026-11-10
> **Implements Pillar**: P1 *Toda bênção é uma filosofia* (a arma é a Doutrina jurada) e P3 *Reflexo que se lê*

> **Nota (2026-11-11, Run e regiões):** o `p_max` é lido da **região** (dono: Câmaras R3; Limiar 4); `ArmasTuning.p_max` é só alias, lido apenas pelo aviso WV8 das Câmaras.

> **Nota (2026-11-11, revisão cruzada):** pendente: D-W11 (Ressonância à distância) segue aberta. Resolvido: Dependencies listam IA, Câmaras, Run e Modificadores como downstream; teto de M = `teto_multiplicador_dano` 4,0 (provisório; Modificadores F2/AC-04b), DPS máx. ≈ 265,9 (66,471 × 4), com o AC-AR-40.

## Summary

**Armas das Doutrinas** define a arma da run, uma por Doutrina, como um
`WeaponDef` com Vida, velocidade, Ataque e Especial. A mecânica dos golpes é do
Combate núcleo; aqui ficam os números e a identidade. No MVP entram a Lâmina do
Juramento (perto, combo que quebra a preparação, Investida) e o Foco Ressonante
(Pulso à distância, Onda em área, menos Vida), escolhidas numa tela antes da run.
As duas ficam dentro de ±15% no tempo para matar o chefe (hoje 0,7%), e a arma
não restringe as bênçãos. **(emenda Pactos, 2026-11-15)** Entra no MVP a terceira
arma, a Besta do Vínculo (Pactos): Virote à distância e Chamado do Pacto, que
manda a Maldição em campo saltar. Ela é uma arma **composta** (Besta + Maldição),
com paridade medida pela F7 (TTK 10,47–10,53 s, diferença máxima 0,74%).
**(emenda Pactos, 2026-11-15, valores da Maldições R18)** Com o ataque básico
da Maldição em `18,00–18,36 DPS` e a técnica contada, a F7 dá TTK
`10,09–10,82 s` (piso `64,70`, teto `69,35 DPS`) e paridade máxima `4,33%`,
dentro da meta `±5%` (`meta_paridade_pactos`).

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Combate núcleo, Modificadores e atributos, Conteúdo orientado a dados; Tela de bênção e componente de carta (por contrato); Input e controle (suave)`

## Overview

**Armas das Doutrinas** define a arma que o Iniciado carrega na run: uma por
Doutrina, e é ela que muda o jeito de lutar. Cada arma é um `WeaponDef` com Vida
máxima base, velocidade de andar, um **Ataque** e um **Especial** (dois
`AttackDef`). Este GDD escolhe os números e a identidade de cada arma; a mecânica
das formas de golpe (arco, círculo, projétil, investida), do combo, da recarga e
do impacto é do Combate núcleo. A esquiva e o Selo são iguais para todas as armas.

No MVP entram duas armas, com os números do cânone:

- **Lâmina do Juramento** (Doutrina da Lâmina): corpo a corpo de combo. O
  terceiro Corte é pesado e quebra a preparação do inimigo, e a Investida é
  ataque e fuga ao mesmo tempo;
- **Foco Ressonante** (Ressonância): distância e risco. O Pulso alcança longe, a
  Onda de Ressonância controla a área, e a arma paga com 20 de Vida a menos.

As outras quatro armas (Guardião e Véu na fatia vertical; Transmutação e Pactos
no Alpha) já têm lugar no dado, mas os números delas são decididos quando a fase
chegar. No MVP o jogador escolhe a arma numa tela simples antes da run. A arma
não restringe as bênçãos: qualquer Tradição pode sair com qualquer arma.

**(emenda Pactos, 2026-11-15)** O MVP passa a ter **três** armas: Lâmina,
Ressonância e **Besta do Vínculo** (Pactos), esta com números de `maldicoes.md`
(§Constantes, l. 462):

- **Besta do Vínculo** (Pactos): distância com parceira. O Virote dirige o foco
  da Maldição em campo (Maldições R4.1), e o Chamado do Pacto a manda saltar,
  segurar e atrair inimigos (Maldições R13). Cerca de 60% do dano vem da Besta e
  40% da Maldição (Maldições F6, ML7).

Ficam para depois só três armas: Guardião e Véu (fatia vertical) e Transmutação
(Alpha).

**Para o jogador:** lutar do jeito da Doutrina que ele jurou. Com a Lâmina, ele
entra, encadeia e quebra o ataque do inimigo antes que saia. Com a Ressonância,
ele mede a distância, segura a linha com a Onda e vive mais perto do limite. A
troca de arma muda a leitura da silhueta (Art Bible §5.4) e o ritmo da câmara,
sem mudar as regras do combate (P1, P3).

## Detailed Design

### Core Rules

> `game-designer` consultado para contexto e balanço (modo Lean, 2026-11-10);
> `systems-designer`, `art-director` e `economy-designer` não consultados nesta
> seção. Números do cânone (`combat-rules/src/arenaContent.ts:27–66`) convertidos
> pelas F1, F2, F4 e F5 do Conteúdo. Decisões do usuário (2026-11-10): números do
> cânone com meta de paridade; Pulso com empurrão 540; tela de escolha antes da
> run; a arma não restringe bênçãos.

**R1. A arma é um `WeaponDef`** (Conteúdo R1), com estes campos e só estes:

| Campo | Tipo | Quem lê |
|---|---|---|
| `id` | id do mapa (Conteúdo R2) | todos |
| `doutrina` | id de Doutrina | Bênçãos, HUD, Telemetria |
| `chave_nome` | chave de tradução (nome canônico, V5) | UI |
| `vida_max` | int | Modificadores R2 (base de `vida_max` do jogador) |
| `velocidade` | px/s (Conteúdo F2) | Modificadores R2 (base de `velocidade`), Movimento R4 |
| `ataque` | `AttackDef` | Combate R3–R7 |
| `especial` | `AttackDef` | Combate R3–R7 |

A esquiva (Movimento), o Selo (GDD de Selo e Fluxo) e a Vida do resto do jogo
são iguais para todas as armas. Uma arma não traz regra própria em código: tudo
o que a diferencia está nestes campos e nos `AttackDef` (formas e params do
Combate).

**R2. As armas do MVP** (números do cânone; decisão do usuário).

| | Lâmina do Juramento | Foco Ressonante |
|---|---|---|
| `id` / `doutrina` | `lamina` / `lamina` | `ressonancia` / `ressonancia` |
| `vida_max` | 100 | 80 |
| `velocidade` | 387 px/s (4,3 u) | 378 px/s (4,2 u) |
| **Ataque** | **Corte**: `arco`, `alcance_px` 142,5, `meio_angulo_graus` 69,51, dano 14, `recarga_s` 0,2667 (16 passos), `empurrao` 450 px/s, `multiplicadores_combo` [1; 1; 1,8], sem status | **Pulso**: `projetil`, `velocidade_pxs` 990, `raio_px` 15, `vida_s` 0,8333 (50 passos), `leque` [0], `atravessa` falso, dano 12, `recarga_s` 0,2333 (14), **`empurrao` 540 px/s**, sem combo, sem status |
| **Especial** | **Investida**: `avanco`, `distancia_px` 330, `duracao_s` 0,1667 (10 passos), `raio_px` 69, dano 26, `recarga_s` 1,1667 (70), `empurrao` 1080, sem combo | **Onda de Ressonância**: `circulo`, `raio_px` 195, `deslocamento_px` 0, dano 30, `recarga_s` 1,5 (90), `empurrao` 1260, sem combo |
| Recuperação (Combate F2) | Corte 8 passos; Investida 0 | Pulso 7; Onda 12 (preso no teto) |

- **Empurrão do Pulso:** 540 px/s é o valor que o motor do cânone aplicava de
  fato (6 u fixo, `engine.ts:1174`), não os 3 u escritos no dado. Fica abaixo da
  parede (630) e do pesado (900): o Pulso empurra, mas não bate na parede nem
  quebra a preparação (decisão do usuário, 2026-11-10).
- **Nenhuma arma do MVP cura por acerto nem tem guarda** (Modificadores R12;
  Combate R3).

**R2b. Besta do Vínculo, 3ª arma do MVP** (emenda Pactos, 2026-11-15). Números de
`maldicoes.md` §Constantes (l. 462) e F6 (l. 382–415), sem mudança. Mesma
estrutura da R2:

| | Besta do Vínculo |
|---|---|
| `id` / `doutrina` | `pactos` / `pactos` |
| `vida_max` | 90 |
| `velocidade` | 382,5 px/s (4,25 u) |
| **Ataque** | **Virote**: `projetil`, `velocidade_pxs` 1170, `raio_px` 12, `vida_s` 0,75 (45 passos), `leque` [0], `atravessa` falso, dano 10, `recarga_s` 0,25 (15 passos), `empurrao` 360 px/s, sem combo, sem status |
| **Especial** | **Chamado do Pacto**: forma nova `chamado` (sem params próprios; a geometria é do `MaldicoesTuning`: `alcance_chamado_px` 420, `duracao_salto_s` 0,20, `raio_chamado_px` 135, `raio_atracao_px` 210), dano 17, `recarga_s` 2,0 (120 passos), `empurrao` **0**, sem combo, sem status |
| Recuperação (Combate F2) | Virote 8 passos (round(7,5) longe do zero); Chamado 12 (min(12, 60), preso no teto) |

- **Virote** (projétil do jogador; Combate R7, R8.2): é golpe de arma
  (`de_arma` verdadeiro). Atinge o **primeiro inimigo atingível** com
  `distância ≤ 12 + r_inimigo` e some (`atravessa` falso). Conta acerto, emite
  `acerto_de_arma` (gera Fluxo no Selo) e **não pede hitstop**, como todo
  projétil do jogador (Combate R10: projétil do jogador 0). Não fere a Maldição
  (Maldições R1). Empurrão 360 < `parede_vel_min` 630 e < `empurrao_pesado` 900:
  nunca é pesado nem bate na parede sozinho (F5b).
- **Chamado do Pacto** (Especial; mecânica em Maldições R13 e F4): ao disparar,
  pede à Maldição em campo o salto até o ponto mirado, limitado a
  `alcance_chamado_px`. O golpe de área no pouso é da Maldição: dano 17 ×
  ~~`M_maldicao` (Maldições F4)~~ `M_chamado` = M do jogador no grupo
  Especial, congelado no disparo (Combate R3.1) (emenda Pactos, 2026-11-15),
  `de_arma` **falso** (sem acerto, sem Fluxo, sem
  `golpe_*`, sem hitstop; Maldições R6).
  - **Recusa** (Maldições R13 e Edge Cases l. 498): sem Maldição em campo, ou
    com ela `Saltando`, o Chamado é **recusado**: a recarga do Especial **não**
    é gasta, não há recuperação, e o toque sai do buffer. No mesmo passo, o
    teste do Ataque segue normal (Combate R3: "senão, o mesmo teste para o
    Ataque"). A recusa emite o evento lógico `chamado_indisponivel`, uma vez por
    toque novo (mesma regra de `troca_indisponivel`).
  - **Ponto mirado:** mouse, o ponto do cursor (vetor de mira do Input R5, com
    módulo); gamepad, `jogador + mira × alcance_chamado_px` (a mira do gamepad
    não tem módulo; contrato pedido ao Input). O caso de vetor
    zero é o da Maldições F4.
  - **Ordem no passo:** o Combate R3 vale como para qualquer Especial (Especial
    primeiro, um golpe por passo, recarga = passos(`recarga_s`), recuperação 12).
    Os itens 1–3 do R3 (combo, M, dano do golpe) **não** se aplicam à forma
    `chamado`: o dano é calculado no pouso pela Maldições F4. O item 8 (forma)
    é o pedido de salto. **Contrato pedido ao Combate núcleo** (forma `chamado`
    na lista das R4–R6 e teste de recusa antes do disparo) e ao **Conteúdo** (valor
    novo no enum de forma; ver AV9).
- **Empurrão 0 no Chamado:** o Chamado segura e atrai (R13.3–4);
  empurrar espalharia o grupo que a atração junta e brigaria com a *Convergência*
  do Soberano (puxa 60 px para o centro). Com 0, não há cambaleio nem "Quebrou!"
  pelo Chamado (Combate R8.4, R8.7).
- **Evento `acerto_virote`** (saída deste GDD, para Maldições R4.1): todo
  `acerto_de_arma` do Combate (R8.2, R17) com `slot` = ataque, enquanto a arma
  equipada é `pactos`. Campos: `alvo` (id), `autor_player_id`, `passo`. Sai no
  mesmo passo do impacto, depois da Vida descontada, **inclusive** com dano 0
  (M = 0; Combate Edge Cases l. 1019) e inclusive se o golpe mata (a Maldições
  R4.1 descarta marca não atingível). Implementação: é um **filtro** sobre o
  `acerto_de_arma`, sem sinal novo e sem regra própria da arma (R1).
  O Chamado nunca gera
  `acerto_virote` (é `de_arma` falso).
- **Bênçãos de slot com a Besta** (R5): `dano_ataque_pct` vale para o Virote
  como para qualquer Ataque. O Chamado usa o M do portador da Maldição
  (Maldições F4). Para a R5 continuar valendo, este GDD **pede** que o
  `dano_especial_pct` do dono some no M do golpe do Chamado (slot especial do
  portador da Maldição; contrato aceito em Combate R3.1 / Maldições R13). Sem isso, a bênção de Especial não
  faz nada com a Besta (falsa escolha, P1).
- **Sem Maldição pactuada** (Maldições R2: "com nenhuma, o Iniciado luta só com a
  Besta"): o Chamado é sempre recusado e o DPS cai para o do Virote (40, F7). A
  paridade da R6 vale só com Maldição em campo (Edge Cases; Open Questions 12).

**R3. Identidade** (game-concept §6–§7; Art Bible §3.3, §5.4).

| Arma | Filosofia (Mestre) | Papel na câmara | Leitura da silhueta |
|---|---|---|---|
| Lâmina do Juramento | foco, timing, ímpeto (Halvar) | perto; combo que quebra a preparação a cada terceiro golpe; a Investida entra ou sai com 0,2 s invulnerável | diagonal: espada reta longa, corpo inclinado para a frente |
| Foco Ressonante | risco calculado perto do limite (Maren) | longe; Pulso contínuo sem hitstop; a Onda é o golpe pesado e controla a área; menos Vida | círculos concêntricos: orbe acima da cabeça, braço estendido |
| Besta do Vínculo (emenda Pactos) | vínculo: o fardo nunca é carregado sozinho (Sorcha; game-concept §6) | longe, em dupla: o Virote marca o alvo da Maldição, o Chamado a manda segurar e atrair; Vida intermediária | "par ligado por fio" (Art Bible §3.3); a silhueta da Besta é do `art-director` (o §5.4 ainda não a tem; Open Questions 15) |

O alcance que o jogador lê é o do desenho do golpe (*smear*, anel, projétil;
Combate Visual/Audio V2–V5), não o tamanho da arma no sprite: a espada mede ~54
px, o Corte acerta até 142,5 px do centro.

**R4. Escolha da arma no MVP** (decisão do usuário, 2026-11-10).

- Antes de cada run, uma **tela de escolha** mostra as duas armas como cartas
  (componente de carta do GDD de Tela de bênção e componente de carta), com nome,
  Doutrina, Vida, velocidade relativa e os nomes do Ataque e do Especial, cada
  um com uma linha de descrição.
- **Descrição de uma linha:** vem da chave derivada `<chave_nome>_DESC` do
  `AttackDef` (sem campo novo no `WeaponDef` nem no `AttackDef`; R1).
- **Velocidade relativa:** `velocidade` < `ArmasTuning.vel_media_min` (360) é
  "lenta"; de 360 a `vel_media_max` (400), inclusive, "média"; acima de 400,
  "rápida". As duas armas do MVP (387 e 378) são "média". **(emenda Pactos)** A
  tela mostra **três** cartas; a Besta (382,5) também é "média". Na primeira
  vez, continua a Lâmina.
- A última arma confirmada vem selecionada; na primeira vez, a Lâmina. A escolha
  é lembrada no arquivo local `user://preferencias.cfg` (`ConfigFile`, seção
  `[armas]`, chave `ultima_arma` = id da arma), sem perfil. O arquivo só é
  gravado ao confirmar. Na fatia vertical, o Save e perfil passa a ser o dono
  dessa informação e lê o arquivo uma vez para migrar.
- **Builds de playtest** (flag do build): nenhuma arma vem pré-selecionada,
  confirmar fica bloqueado até o jogador escolher uma carta, e o build **não lê
  nem grava** o `user://preferencias.cfg`, para que a taxa de escolha da R6 meça
  preferência e não inércia. Fora desses builds, vale a pré-seleção acima.
- A arma fica **fixa durante a run**; não há troca no meio.
- Na fatia vertical, a tela é substituída pela Doutrina jurada no Rito de
  Iniciação e pelo Campus (GDDs desses sistemas).

**R5. Bênçãos e Selo** (decisão do usuário, 2026-11-10).

- A arma **não restringe** o pool de bênçãos: qualquer Tradição pode ser
  oferecida com qualquer arma. Pesos, se houver, são do GDD de Bênçãos.
- As bênçãos de slot (`dano_ataque_pct`, `dano_especial_pct`) valem para o Ataque
  e o Especial da arma que estiver em uso, sem distinção de forma.
- O Selo é o mesmo para todas as armas.

**R6. Meta de paridade** (decisão do usuário, 2026-11-10).

- Sem bênçãos, o tempo para matar o chefe do Limiar (700 de Vida) deve ficar a
  ±15% entre as armas (F2), no modelo **combinado**: o Especial usado a cada
  recarga e o Ataque no resto (decisão do usuário, 2026-11-10). Hoje: Lâmina
  10,53 s, Ressonância 10,45 s (0,7%). O modelo "só Ataque" (13,2 × 13,6 s, 3,4%)
  é informativo.
- O "TTK do chefe" é uma **razão de DPS contra um alvo**: o chefe do Limiar só
  existe como dado no MVP (a run não chega a ele) e a Vida 700 só dá a escala;
  a razão não depende dela. As câmaras do MVP são de grupo, com pontos de corte
  (F3), e quem mede isso é o playtest.
- A paridade é **hipótese de playtest**, não certeza: o alcance do Pulso e a
  quebra de preparação da Lâmina não entram no DPS. O playtest (build de
  playtest, sem pré-seleção; R4) confere:
  - escolha de arma entre 35% e 65% das runs (Telemetria local);
  - taxa de vitória por câmara sem diferença maior que 15 pontos.
  - **(emenda Pactos, 2026-11-15)** Com três armas, a faixa de escolha passa a
    **18%–48%** por arma (1/3 ± 15 pontos, a mesma folga da faixa de duas);
    a vitória por câmara compara **cada par** de armas. A
    Besta é medida em runs com ao menos uma Maldição pactuada; runs sem
    Maldição são anotadas à parte (R2b).
  - **Pactos é arma composta:** o "TTK do chefe" dela soma Besta e Maldição em
    campo (F7, leitura da Maldições F6). A validação dela é o ML7/ML8 de
    Maldições, não o AV2 (Validação).
- Fora da meta, quem ajusta é o `/balance-check`, mexendo só nos números do
  `AttackDef` (este GDD).

**R7. Armas futuras** (só como dado; números decididos quando a fase chegar).

| Arma | Fase | Situação |
|---|---|---|
| Escudo-Bastião (Guardião) | fatia vertical | números do cânone como ponto de partida; dois problemas a resolver no GDD da fase: a guarda (2 s) é maior que a recarga da Muralha (1,33 s) e fica ativa o tempo todo, e o Golpe de Escudo (900 = pesado em todo acerto; o CV8 do Combate avisa) trava a preparação de qualquer inimigo comum, o que o CV18 não pega (AV4 deste GDD; Open Questions) |
| Adagas do Véu | fatia vertical | números do cânone; margem apertada no CV17 (cambaleio 8 × recarga 9) |
| Cálice da Transmutação | Alpha | números do cânone |
| Besta do Vínculo (Pactos) | ~~Alpha~~ **MVP (emenda Pactos, 2026-11-15)** | números na R2b, vindos de `maldicoes.md` §Constantes; o cânone só tem o "Laço dos Pactos" (chicote, `arenaContent.ts:67–74`), descartado pela adaptação aprovada no game-concept (§6, 2026-11-05; Conteúdo OQ4); a cura por acerto do Laço não é herdada (cross-review C-I8) |

- As armas são **horizontais**: todas no mesmo nível de poder; não há níveis de
  arma. O desbloqueio (custo, ordem) é do GDD de Desbloqueio de armas.
- A guarda (`guarda_s` do `AttackDef`) continua regra do Combate (R13), com a
  validação nova AV1 (passos(`guarda_s`) < passos(`recarga_s`), aviso; Formulas).
- **Profundidade:** nas contas deste GDD, p = 0 é a primeira câmara de combate da
  região (como no Pipeline visual R3); o ganho de Vida por profundidade é o do
  Modificadores R10 aplica; a fórmula (`depth_hp_bonus`, 0,05 × p) e as constantes de
  elite são da **IA de inimigos e elites** (F2).

**R8. Nomes canônicos** (Conteúdo V5). Armas: "Lâmina do Juramento", "Foco
Ressonante", "Escudo-Bastião", "Adagas do Véu", "Cálice da Transmutação",
"Besta do Vínculo". Ataque / Especial: "Corte" / "Investida"; "Pulso" / "Onda de
Ressonância"; "Golpe de Escudo" / "Muralha"; "Estocada" / "Leque de Lâminas";
"Gota Corrosiva" / "Transmutar"; "Virote" / "Chamado do Pacto" (aprovados no
game-concept §6, 2026-11-05).

- **"Corte" e o Corte da esquiva:** o Ataque da Lâmina se chama "Corte"; o
  efeito da bênção de esquiva aparece para o jogador pelo nome da bênção ("O
  Corte Fantasma"), nunca como "Corte" solto. O texto dos GDDs usa "Corte da
  esquiva" para o efeito; o HUD e as cartas, o nome da bênção.

**R9. Injeção.** O sistema de Armas entrega ao começo da run o `WeaponDef`
escolhido: o Modificadores monta o portador do jogador com a Vida e a velocidade
base, e o Combate recebe os dois `AttackDef`. Os testes montam armas em memória.

### States and Transitions

| Estado | Entra quando | Sai para |
|---|---|---|
| Escolhendo | a run vai começar (MVP: tela de escolha) | Equipada |
| Equipada | o jogador confirma a arma | Encerrada, no fim da run |
| Encerrada | fim da run (morte ou vitória) | Escolhendo, na próxima run |

Não há troca de arma durante a run.

### Interactions with Other Systems

| Sistema | Recebe daqui | Fornece para cá | Dono da interface |
|---|---|---|---|
| Combate núcleo | os dois `AttackDef` da arma | as formas, o combo, a recarga e o impacto | Combate (mecânica), este GDD (números) |
| Modificadores e atributos | `vida_max` e `velocidade` base | — | Modificadores |
| Movimento e esquiva | `velocidade` (via Modificadores) | — | Movimento |
| Conteúdo orientado a dados | os `WeaponDef` e `AttackDef` no catálogo | validação (V1–V11), conversões | Conteúdo (formato), este GDD (valores e faixas) |
| Bênçãos (Tradições) | `doutrina` da arma | — | Bênçãos |
| Tela de bênção e componente de carta | os dados da carta de arma | o componente de carta | UI |
| Input e controle | — | navegação da tela de escolha; Ataque e Especial segurados (via Combate, Input R7) | Input |
| HUD | nome da arma e do Ataque e do Especial | — | HUD |
| Telemetria local | arma escolhida em cada run | — | Telemetria |
| Feedback de combate (VFX) / Pipeline visual | — (o desenho segue a forma do `AttackDef`) | — | VFX |
| Rito de Iniciação, Campus, Desbloqueio de armas (fases futuras) | lista de armas e Doutrinas | quais armas estão disponíveis | esses GDDs |
| Maldições (emenda Pactos) | `WeaponDef pactos`; o disparo do Chamado (forma `chamado`); o evento `acerto_virote` (R2b) | o salto e o golpe do Chamado; a consulta "pode chamar" (Maldição em campo e não `Saltando`); o DPS da Maldição em campo (F3 dela) para a F7 | Maldições (salto, golpe, marca), este GDD (números do `WeaponDef`, recarga, evento) |

## Formulas

> Proposta do `systems-designer` (consultado: modo Lean, 2026-11-10). Contas
> refeitas contra o cânone (`arenaContent.ts:27–97`) e contra as F1–F3, F7, F9–F11
> do Combate núcleo e as F1–F3 e R10 do Modificadores. Contas conferidas na 1ª
> revisão independente (2026-11-10).

Convenções: `passos(t)` é o F7 do Conteúdo; `TICK_RATE` = 60. **R** =
passos(`recarga_s`) de um `AttackDef`; **J** = passos(`janela_combo_s`) = 34;
**Q** = passos(`quebrou_recuperacao_s`) = 24; **W** = passos(preparo do
`EnemyDef`). Hitstop (Combate R10): leve 3, pesado 6, projétil do jogador 0.
q = `queda_empurrao` 0,78; z = `empurrao_zero` 4,5. Este GDD **não redefine**
nenhuma fórmula do Combate: as F1–F6 abaixo são leituras delas com os números das
armas.

Inimigos do Limiar usados nas contas (cânone, `arenaContent.ts:88–96`):

| Inimigo | Vida | Dano | Raio (px) | Preparo W (passos) |
|---|---|---|---|---|
| Eco Perdido (`eco_perdido`) | 30 | 9 | 24 | 26 |
| Anomalia Menor (`anomalia_menor`) | 24 | 8 | 22,5 | 36 |
| Fenda Errante (`fenda_errante`) | 46 | 13 | 30 | 42 |
| Anomalia Maior (chefe) | 700 | 16 | 63 | 40 |

### F1. DPS de referência por arma

The weapon_dps formula is defined as:

`DPS_vivo(golpe)` e `DPS_real(golpe)`: **F11 do Combate** (não reescrita) ;
combinado, com o Especial disparado a cada recarga e o Ataque no resto:
`k = R_esp / R_atk` (Ataques por ciclo do Especial) ;
`D_ciclo = k × dano_atk × c̄_atk + dano_esp × c̄_esp` ;
`H_ciclo = k × h̄_atk + h_esp` ;
`DPS_comb_vivo = D_ciclo × M × 60 / R_esp` ; `DPS_comb_real = D_ciclo × M × 60 / (R_esp + H_ciclo)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| dano_atk, dano_esp | float | > 0 (cânone 9–30) | data file | `AttackDef.dano` do Ataque e do Especial |
| R_atk, R_esp | int | ≥ 1 (MVP 14–90) | calculated | passos(`recarga_s`) de cada slot |
| c̄ | float | > 0 | calculated | média do combo se R < J, senão `combo[0]`; 1 sem combo (F11 do Combate) |
| h̄_atk | float | 0–12 | calculated | hitstop médio por Ataque com alvo (Corte: (3+3+6)/3 = 4; Pulso: 0) |
| h_esp | int | 0–12 | calculated | hitstop do Especial com alvo (círculo e 1º alvo da investida: 6) |
| k | float | ≥ 1 | calculated | Ataques que cabem em uma recarga do Especial |
| M | float | ≥ 0 | calculated | F2 do Modificadores (1 sem bênção), igual nos dois slots |
| DPS_comb_vivo, DPS_comb_real | float | ≥ 0 | calculated | Vida/s contra **um** alvo |

**Output Range:** ≥ 0, sem teto. É um **teto** de jogador perfeito contra um alvo
parado, sem esquivas e sem abates. Duas perdas ficam de fora, as duas pequenas:
(a) só um golpe sai por passo e o Especial tem prioridade (Combate R3): quando os
dois ficam prontos juntos, o Ataque atrasa 1 passo (≤ 1,5% do ciclo); (b) a
investida bloqueia o Ataque por N passos, mas **não custa nada** se for disparada
logo depois de um Corte, porque 1 + N = 11 < R_atk = 16. O DPS combinado é
invariante a `dano_todo` (M multiplica os dois slots) e muda com as bênçãos de
slot na proporção da F6.

**Example (M = 1, um alvo):**

| Arma | Golpe | DPS vivo | DPS real |
|---|---|---|---|
| Lâmina | Corte (combo [1; 1; 1,8], R 16) | 66,5 | 53,2 |
| Lâmina | Investida (R 70, h 6) | 22,3 | 20,5 |
| Lâmina | **combinado** (k = 4,375) | **88,8** | **66,5** |
| Ressonância | Pulso (R 14, h 0) | 51,4 | 51,4 |
| Ressonância | Onda (R 90, h 6) | 20,0 | 18,75 |
| Ressonância | **combinado** (k = 6,43) | **71,4** | **67,0** |

Lâmina: D_ciclo = 4,375 × 17,733 + 26 = 103,58; H_ciclo = 4,375 × 4 + 6 = 23,5;
real = 103,58 × 60 / 93,5 = 66,47. Ressonância: D_ciclo = 6,43 × 12 + 30 = 107,14;
H_ciclo = 6; real = 107,14 × 60 / 96 = 66,96. O hitstop "cobra" 25% do vivo da
Lâmina e 6% da Ressonância; em tempo real as duas empatam.

### F2. Tempo para matar o chefe e paridade

The boss_ttk_parity formula is defined as:

`TTK_x = Vida_chefe / DPS_real_x` (contínuo) ;
`paridade = |TTK_a − TTK_b| / min(TTK_a, TTK_b)` ; meta (R6): `paridade ≤ 0,15`

Forma discreta (para testes): `TTK_disc = (g − 1) × R_atk + Σ h_i (i < g)` passos,
com `g` = golpes até a Vida acumulada ≥ `Vida_chefe` (F3) e o primeiro golpe no
passo 0.

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| Vida_chefe | int | > 0 (700) | data file | `EnemyDef.vida` do chefe do Limiar; sem ganho por profundidade (Modificadores R10) |
| DPS_real_x | float | > 0 | calculated | F1: do Ataque (modelo "só Ataque") ou combinado |
| TTK_x | float | > 0 s | calculated | tempo real até o abate |
| paridade | float | ≥ 0 | calculated | diferença relativa entre duas armas |
| g | int | ≥ 1 | calculated | golpes até matar |

**Output Range:** `paridade` ≥ 0, sem teto. Divisão por zero impossível (DPS > 0
por validação: dano > 0 e R ≥ 1). Com o mesmo M nos dois slots, a paridade não
muda com bênçãos de `dano_todo`; uma bênção de slot +X muda o TTK de cada arma
pela fração da F6, e a diferença entre as frações (25,1% × 28,0%) move a
paridade em ~0,03 × X. O voo do Pulso (distância / 990 px/s, ~0,3 s a 300 px) e
as esquivas não entram.

**Example (sem bênção):**

| Modelo | Lâmina | Ressonância | Paridade |
|---|---|---|---|
| Só Ataque, contínuo | 700 / 53,2 = **13,16 s** | 700 / 51,43 = **13,61 s** | **3,4%** |
| Só Ataque, discreto | 40 Cortes: 39 × 16 + 13 × 12 = 780 passos = 13,0 s | 59 Pulsos: 58 × 14 = 812 = 13,53 s | 4,1% |
| Combinado, contínuo | 700 / 66,47 = **10,53 s** | 700 / 66,96 = **10,45 s** | **0,7%** |

Folga de ajuste (só Ataque, Lâmina fixa): a paridade fica ≤ 0,15 com o dano do
Pulso entre **10,80 e 14,27** (hoje 12). No combinado, entre 9,72 e 14,35.

### F3. Golpes até matar por profundidade

The hits_to_kill formula is defined as:

`Vida_p = round(Vida_base × (1 + 0,05 × p) × (elite ? 2,4 : 1))` (F1 do
Modificadores: percentual de `profundidade`, multiplicador de `elite`, arredondado
no fim, meio longe do zero) ;
`D_k = Σ_{i=0}^{k−1} dano × combo[i mod n]` (dano acumulado do golpe i, combo a
partir do passo 0) ; `g(p) = min{k : D_k ≥ Vida_p}` ;
`margem = D_g − Vida_p` (sobra do golpe que mata) e `falta = Vida_p − D_{g−1}`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| Vida_base | int | > 0 (24–46 comuns) | data file | `EnemyDef.vida` |
| p | int | ≥ 0 | calculated | profundidade da câmara (Câmaras); chefes não ganham |
| elite | bool | — | calculated | elite a partir da profundidade 3 (game-concept §5) |
| Vida_p | int | ≥ 1 | calculated | Vida máxima no spawn |
| dano, combo | float, float[] | F1 do Combate | data file | `AttackDef` |
| D_k | float | ≥ 0 | calculated | dano somado de k golpes |
| g | int | ≥ 1 | calculated | golpes até matar |
| margem, falta | float | ≥ 0 / > 0 | calculated | distância ao ponto de corte (AV3) |

**Output Range:** g ≥ 1, sem teto. `Vida_p` cresce +5% por profundidade (+1,5 no
Eco), então **todo ponto de corte vira em alguma profundidade**; o que importa é
onde ele cai. `g` do Corte supõe o combo começando no passo 0 naquele alvo; o
combo é por slot, não por alvo (Combate R3.1), então o mesmo inimigo pode cair um
golpe antes ou depois conforme a fase. Sem bênção.

**Example.** D_k: Corte 14 · 28 · 53,2 · 67,2 · 81,2 · 106,4 · 120,4 · 134,4 ·
159,6; Pulso 12k; Onda 30k; Investida 26k. `*` = margem ou falta ≤ 2 (AV3);
`=` = exatamente no corte.

| Inimigo | p | Vida_p | Corte | Pulso | Onda | Investida |
|---|---|---|---|---|---|---|
| Eco | 0 | 30 | 3 (falta 2 no 2º: 28) `*` | 3 | **1 `=`** | 2 |
| Eco | 1 | 32 | 3 | 3 | 2 (falta 2) `*` | 2 |
| Eco | 3 | 35 | 3 | 3 (margem 1) `*` | 2 | 2 |
| Eco | 4 | 36 | 3 | 3 `=` | 2 | 2 |
| Eco | 7 | 41 | 3 | 4 | 2 | 2 |
| Anomalia | 0 | 24 | 2 | **2 `=`** | 1 | 1 (margem 2) `*` |
| Anomalia | 2 | 26 | 2 (margem 2) `*` | 3 (falta 2) `*` | 1 | 1 `=` |
| Anomalia | 3 | 28 | 2 `=` | 3 | 1 (margem 2) `*` | 2 (falta 2) `*` |
| Anomalia | 5 | 30 | 3 (falta 2) `*` | 3 | 1 `=` | 2 |
| Fenda | 0 | 46 | 3 | 4 (margem 2) `*` | 2 | 2 |
| Fenda | 3 | 53 | 3 (margem 0,2) `*` | 5 | 2 | 3 (falta 1) `*` |
| Fenda | 4 | 55 | 4 (falta 1,8) `*` | 5 | 2 | 3 |
| Fenda | 6 | 60 | 4 | 5 `=` | 2 `=` | 3 |
| Eco elite | 3 | 83 | 6 (falta 1,8) `*` | 7 (margem 1) `*` | 3 | 4 |
| Eco elite | 5 | 90 | 6 | 8 | 3 `=` | 4 |
| Anomalia elite | 3 | 66 | 4 (margem 1,2) `*` | 6 | 3 | 3 |
| Fenda elite | 3 | 127 | 8 | 11 | 5 | 5 |
| Fenda elite | 7 | 149 | 9 | 13 | 5 (margem 1) `*` | 6 |

Vida_p completa (p 0–7): Eco 30, 32, 33, 35, 36, 38, 39, 41; Anomalia 24, 25, 26,
28, 29, 30, 31, 32; Fenda 46, 48, 51, 53, 55, 58, 60, 62. Elite (p 3–7): Eco 83,
86, 90, 94, 97; Anomalia 66, 69, 72, 75, 78; Fenda 127, 132, 138, 144, 149
(confere com o exemplo do Modificadores: 46 na profundidade 7 → 149).

**Pontos frágeis que mudam a leitura:**

- **Onda × Eco em p = 0:** 30 = 30. A Onda mata o Eco num golpe só na
  profundidade 0 e precisa de dois a partir da 1 (32). Qualquer +1 de Vida ou −1
  de dano dobra o tempo de abate com o Especial.
- **Corte × Eco em p = 0:** dois Cortes tiram 28 de 30. Um Corte de 15 mataria o
  Eco no 2º golpe e mudaria o ritmo da Lâmina inteira contra o inimigo mais comum.
- **Pulso × Anomalia em p = 0:** 24 = 24, morre no 2º Pulso; em p = 1 (25), no 3º.
- **Corte × Fenda em p = 3:** 53 contra 53,2 (margem 0,2): é o último ponto em
  que o finalizador mata a Fenda; em p = 4 ela sobrevive ao combo e morre no 4º
  Corte, dentro do 2º período (o AV4 não avisa: exige sobreviver a 2 períodos).
- **Ordem do cálculo:** os casos de meio exato (Eco 31,5, 34,5, 37,5 e 40,5;
  Fenda 57,5) dependem de a F1 do Modificadores ser avaliada em double na ordem
  `base × (1 + Σ percentuais) × Π multiplicadores`, com a fonte `profundidade`
  gravada como **um** percentual 0,05 × p, e não como p percentuais de 0,05
  somados. A AC-AR-18 confere esses cinco casos no GDScript; se a ordem do
  Modificadores mudar, a tabela muda junto (Open Questions).

### F4. Golpes recebidos até morrer

The hits_to_die formula is defined as:

`dano = max(1, round(dano_base × (elite ? 1,25 : 1)))` (**F3 do Modificadores**,
sem redução, guarda nem escudo) ; `g_morte = ceil(vida_max / dano)` ;
tempo mínimo até morrer = `(g_morte − 1) × passos(invuln_atingido_s)` passos vivos

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| vida_max | int | ≥ 20 (MVP 80–100) | data file | `WeaponDef.vida_max`, sem bênção |
| dano_base | float | > 0 (8–16) | data file | `EnemyDef.dano` |
| dano | int | ≥ 1 | calculated | dano por acerto, inteiro |
| g_morte | int | ≥ 1 | calculated | acertos até Vida ≤ 0, sem recusa |
| passos(invuln_atingido_s) | int | 15–90 (40) | data file | `CombatTuning`; teto de um acerto a cada 40 passos (F10 do Combate) |

**Output Range:** g_morte ≥ 1. `vida_max` múltiplo exato do dano deixa o
jogador em Vida 0 no último acerto: +1 de Vida (Vigor, Muro de Pedras) compra um
acerto inteiro. Com recusa (`recusas_morte`), soma-se `ceil(round(vida_max ×
0,4) / dano)`.

**Example (sem bênção, sem recusa):**

| Atacante | dano | Lâmina (100) | Ressonância (80) |
|---|---|---|---|
| Eco | 9 | 12 | 9 |
| Eco elite | 11 (11,25) | 10 | 8 |
| Anomalia | 8 | 13 | **10 `=`** |
| Anomalia elite | 10 (8 × 1,25) | **10 `=`** | **8 `=`** |
| Fenda | 13 | 8 | 7 |
| Fenda elite | 16 (16,25) | 7 | **5 `=`** |
| Chefe | 16 | 7 | **5 `=`** |

Contra o chefe, a Ressonância morre em 5
acertos (tempo mínimo 4 × 40 = 160 passos, 2,67 s) e a Lâmina em 7 (240 passos,
4,0 s): **−29% de margem** pelos 20 de Vida, contra 0,7% de diferença de TTK no
modelo combinado da R6 (3,4% só Ataque). A
paridade da R6 mede só o lado ofensivo; o custo da Vida menor é a "conta do
risco" que a Ressonância paga em troca do alcance (R3), e o playtest confere se
ela fecha.

### F5. Empurrão efetivo do Pulso

The pulse_knockback formula is defined as:

`emp_ef = 540 × valor(fator_empurrao)` (F3 do Combate; o Pulso não tem combo,
então nunca há finalizador) ; distância e passos: **F7 do Combate** ;
empurrão sustentado (Pulsos seguidos no mesmo alvo):
`v_sust = emp_ef / (1 − q^R_atk)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| 540 | float | — | data file | `AttackDef.empurrao` do Pulso (6 u × 90; R2) |
| valor(fator_empurrao) | float | 0–1 (comum 1, elite 0,4, chefe 0,12) | calculated | Modificadores R10 |
| emp_ef | float | ≥ 0 px/s | calculated | velocidade somada ao alvo |
| q, R_atk | float, int | 0,78; 14 | data file / calculated | queda por passo; recarga do Pulso |
| v_sust | float | ≥ emp_ef | calculated | velocidade logo depois de cada Pulso em fogo contínuo |

**Output Range:** `emp_ef` ≤ 540 < 630 (`parede_vel_min`) < 900
(`empurrao_pesado`): o Pulso **nunca** é pesado nem bate na parede sozinho. Em
fogo contínuo, `v_sust` = 540 / (1 − 0,78¹⁴) = 540 / 0,9691 = **557,2 px/s**, ainda
abaixo de 630 (margem 72,8). O teto do `empurrao` do Pulso que mantém isso é
630 × 0,96914 = **610,56 px/s** (AV5). Somado a outra fonte (Onda, Corte da
esquiva), pode bater: isso é intencional (combo de fontes).

**Example (F7 do Combate, q 0,78, z 4,5):**

| Alvo | emp_ef (px/s) | passos | dist (px) | Bate na parede? |
|---|---|---|---|---|
| Comum | 540 | 20 | 40,6 | não (< 630) |
| Elite (× 0,4) | 216 | 16 | 16,1 | não |
| Chefe (× 0,12) | 64,8 | 11 | 4,6 | não |
| (comparação) Corte 450 / finalizador 900 / Onda 1260 | — | 19 / 22 / 23 | 33,8 / 67,9 / 95,1 | não / sim / sim |

### F6. Fração do dano do Especial

The special_damage_share formula is defined as:

`f_esp = (dano_esp × c̄_esp) / D_ciclo` (F1) ;
efeito de uma bênção de slot no DPS combinado:
`ΔDPS/DPS = X_esp × f_esp` (`dano_especial_pct`) ou `X_atk × (1 − f_esp)`
(`dano_ataque_pct`)

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| dano_esp, c̄_esp | float | > 0 | data file / calculated | F1 |
| D_ciclo | float | > 0 | calculated | F1 |
| f_esp | float | 0–1 (alvo 0,15–0,40) | calculated | parte do dano que vem do Especial, um alvo |
| X_esp, X_atk | float | ≥ 0 | data file | valor somado da bênção de slot (0,25 = +25%) |

**Output Range:** 0 a 1. A fração é a mesma no tempo vivo e no real (o hitstop
não muda o dano). Conta para **um** alvo: em grupo, a Onda (área) e o Corte
(arco) sobem; o Pulso (`atravessa` falso) e a Investida (uma faixa) não.

**Example:** Lâmina 26 / 103,58 = **25,1%**; Ressonância 30 / 107,14 = **28,0%**.
Uma bênção de Especial +25% dá +6,3% (Lâmina) e +7,0% (Ressonância) no DPS
combinado; uma de Ataque +25% dá +18,7% e +18,0%. O valor relativo de uma bênção
de Ataque é ~3× o de uma de Especial em um alvo, nas duas armas.

### F7. DPS composto da Besta do Vínculo e paridade (emenda Pactos, 2026-11-15)

The pact_weapon_composite_dps formula is defined as:

Leitura da **F6 de Maldições** (`pact_doctrine_combined_ttk`, l. 382–415), sem
redefinir. Primeiro a F1 deste GDD só com a arma, depois a Maldição em campo:
`k = R_esp / R_atk` ; `D_ciclo = k × dano_virote + dano_chamado` ; `H_ciclo = 0`
(Virote: projétil do jogador; Chamado: `de_arma` falso) ;
`DPS_arma = D_ciclo × M × 60 / R_esp` (vivo = real) ;
`f_campo_atk = (R_esp − N_salto) / R_esp` ;
`DPS_pactos = DPS_arma + f_campo_atk × DPS_autonomo` ;
`TTK_pactos = Vida_chefe / DPS_pactos` ; paridade pela F2, com `DPS_real_x` =
`DPS_pactos` para a Besta.

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| dano_virote, R_atk | float, int | 10; 15 | data file / calculated | Ataque da `WeaponDef pactos` (R2b) |
| dano_chamado, R_esp | float, int | 17; 120 | data file / calculated | Especial da `WeaponDef pactos` (R2b) |
| N_salto | int | 6–18 (12) | data file | `passos(MaldicoesTuning.duracao_salto_s)`; a Maldição não ataca no salto |
| DPS_autonomo | float | 20,0–20,4 (M = 1) | calculated | Maldições F3, da espécie em campo |
| M | float | ≥ 0 (1) | calculated | igual para o jogador e a Maldição só se o `dano_todo` propagar (Maldições OQ3) |
| DPS_arma, DPS_pactos | float | ≥ 0 | calculated | Vida/s contra um alvo |
| TTK_pactos | float | > 0 s | calculated | tempo até 700 de dano |

**Output Range:** `DPS_pactos` ≥ `DPS_besta` (Virote só) = 40. Vale com a Maldição
em campo **o tempo todo** e o Chamado nunca recusado. Sem Maldição, `DPS_pactos`
= 40 (só o Virote; o Chamado é recusado). A perda (a) da F1 (Ataque atrasa 1
passo quando os dois ficam prontos juntos) aqui acontece **todo ciclo**, porque
120 = 8 × 15: ≤ 1/120 = 0,8% do ciclo. A paridade **não** é invariante a
`dano_todo` se ele não propagar para a Maldição: aí só 60,2% do DPS sobe
(Open Questions 13).

**Example (M = 1, um alvo, chefe 700):** k = 8; D_ciclo = 80 + 17 = 97;
DPS_arma = 97 × 60 / 120 = **48,5**; f_campo_atk = 108 / 120 = 0,9.

| Besta + | DPS_arma | Maldição autônoma (0,9 × F3) | **DPS_pactos** | **TTK** | paridade × Lâmina (10,5310) | × Ressonância (10,4533) |
|---|---|---|---|---|---|---|
| Vulto / Baluarte / Soberano (20,0) | 48,5 | 18,0 | **66,50** | **10,5263 s** | 0,0004 | 0,0070 |
| Espreitador (20,4) | 48,5 | 18,36 | **66,86** | **10,4697 s** | 0,0059 | 0,0016 |
| sem Maldição (Chamado recusado) | 40,0 | 0 | 40,00 | 17,50 s | 0,6618 | **0,6741** |

- **Divisão 60/40 (ML7):** `f_besta` = 40 / 66,5 = **0,6015**; 40 / 66,86 =
  **0,5983**. O Chamado é 8,5 / 66,5 = **12,8%** do total; o resto da Maldição,
  27,1%.
- **Paridade máxima do MVP** com as três armas: continua **0,0074** (Lâmina ×
  Ressonância); a Besta fica entre as duas.
- **Conferência com Maldições F6:** DPS e TTK batem. A coluna "Diferença p/ o
  menor TTK" de lá mostra 0,73% para Vulto/Baluarte/Soberano; com valores sem
  arredondar dá **0,70%** (66,964 / 66,5 − 1 = 0,00698). Diferença de
  arredondamento, sem efeito no ML8 (registrado, não alterado).
- **"Só Ataque" (informativo):** Virote + Maldição autônoma o ciclo todo, sem
  Chamado: 40 + 20 = 60 → 11,67 s (12,8% mais rápida que a Lâmina só Ataque,
  16,7% que a Ressonância). Não vira aviso, como no AV2.
- **Folga de ajuste** (combinado, Lâmina e Ressonância fixas): paridade ≤ 0,15
  com o dano do Virote entre **7,93 e 12,40** (hoje 10); o ML7 só aperta fora
  de 6,63–15,46.
- **Fluxo (informativo, um alvo):** acertos de arma por segundo real — Besta
  8 / 2,0 s = 4,0; Lâmina 5,375 / 1,558 s = 3,45; Ressonância 7,43 / 1,6 s =
  4,64. O Chamado não gera Fluxo.

**Contas das F1–F6 para a Besta** (emenda Pactos; mesma regra, números da R2b):

- **F1 por golpe:** Virote vivo = real = 10 × 60 / 15 = **40,0**; Chamado (como
  golpe da arma) 17 × 60 / 120 = **8,5**, hitstop 0.
- **F3, golpes até matar** (sem bênção; Virote 10k; Chamado 17k: 17 · 34 · 51 ·
  68 · 85; o Chamado sozinho a cada 2 s não é como o inimigo morre, a linha é
  informativa). `*` = margem ou falta ≤ 2; `=` exato:

| Inimigo | p | Vida_p | Virote | Chamado |
|---|---|---|---|---|
| Eco | 0 | 30 | **3 `=`** | 2 (margem 4) |
| Eco | 1 | 32 | 4 (falta 2) `*` | 2 (margem 2) `*` |
| Eco | 2 | 33 | 4 | 2 (margem 1) `*` |
| Eco | 3 | 35 | 4 | 3 (falta 1) `*` |
| Eco | 4 | 36 | 4 | 3 (falta 2) `*` |
| Anomalia | 0 | 24 | 3 | 2 |
| Anomalia | 3 | 28 | 3 (margem 2) `*` | 2 |
| Anomalia | 4 | 29 | 3 (margem 1) `*` | 2 |
| Anomalia | 5 | 30 | 3 `=` | 2 (margem 4) |
| Anomalia | 7 | 32 | 4 | 2 (margem 2) `*` |
| Fenda | 0 | 46 | 5 | 3 |
| Fenda | 1 | 48 | 5 (margem 2) `*` | 3 |
| Fenda | 2 | 51 | 6 (falta 1) `*` | **3 `=`** |
| Fenda | 3 | 53 | 6 | 4 (falta 2) `*` |
| Eco elite | 3 | 83 | 9 | 5 (margem 2) `*` |
| Eco elite | 4 | 86 | 9 | 6 (falta 1) `*` |
| Anomalia elite | 4 | 69 | 7 (margem 1) `*` | 5 (falta 1) `*` |
| Fenda elite | 4 | 132 | 14 (falta 2) `*` | 8 |

- **F4, golpes recebidos (Vida 90):** Eco 9 → **10 `=`**; Eco elite 11 → 9;
  Anomalia 8 → 12; Anomalia elite 10 → **9 `=`**; Fenda 13 → 7; Fenda elite 16
  → 6; chefe 16 → 6 (tempo mínimo 5 × 40 = 200 passos, 3,33 s). Contra o chefe:
  Lâmina 7, Besta 6, Ressonância 5. Inimigos **atraídos** miram a Maldição, não o
  jogador (Maldições R7): a Vida da Besta conta menos acertos do que a F4 supõe.
- **F5b, empurrão do Virote** (F7 do Combate, q 0,78, z 4,5): emp_ef comum 360
  (18 passos, 26,96 px), elite 144 (14 passos, 10,57 px), chefe 43,2 (10 passos,
  3,00 px); `v_sust` = 360 / (1 − 0,78¹⁵) = 360 / 0,97593 = **368,88 px/s** <
  630; teto do AV5 com R = 15: 630 × 0,97593 = **614,84 px/s**.
- **F5 do Combate, alcance testado do Virote:** s = 1170 / 60 = 19,5; L = 45;
  36 + 44 × 19,5 = **894 px** (o F6 do Conteúdo mostra 877,5).
- **F6, fração do Especial:** `f_esp` da arma = 17 / 97 = **0,1753** (dentro de
  0,15–0,40, sem AV8). No composto, o Chamado é 12,8% (abaixo de 0,15):
  `dano_ataque_pct` +25% dá **+15,0%** no DPS composto; `dano_especial_pct` +25%
  dá **+3,2%**, e só se o contrato da R2b for aceito (senão, 0). É a OQ 8 mais
  forte na Besta (Open Questions 14).

#### F7 com os valores da emenda Pactos (2026-11-15)

A Maldições mudou os números depois desta F7: R18 (ataque básico `−10%`: dano
`9` / `7,65` / `12,6` / `9,8`, F3 `18,00–18,36 DPS`; Saída `5`; Entrada `6`,
`9` com sinergia, ou `7`; `D_tecnica_max = 14`, F5), R17/F4b (atração `1,5 s`)
e F6 com a técnica (meta `meta_paridade_pactos = 0,05`). A arma não muda:
`DPS_arma = 48,5`. A tabela acima fica como registro; vale esta.

`DPS_pactos_piso = DPS_arma + f_campo_atk × DPS_autonomo` (vínculo nível 1,
sem técnica) ;
`DPS_pactos_teto = DPS_arma + f_campo_atk × DPS_autonomo(vínculo nível 5) +
D_tecnica_max / recarga_troca_s` (Maldições F6 com a técnica) ;
paridade pela F2.

| Variável | Tipo | Faixa | Fonte | Descrição |
|---|---|---|---|---|
| DPS_autonomo | float | `18,00–18,36` (nível 1); `18,82–19,28` (nível 5) | Maldições F3 (emenda) e Vínculo F4 | ataque básico da espécie em campo, M = 1 |
| D_tecnica_max, recarga_troca_s | float | `14`; `4,0 s` | Maldições F5, `MaldicoesTuning` | técnica a cada recarga: `3,50 DPS` |
| meta_paridade_pactos | float | `0,05` | `MaldicoesTuning` | meta da Doutrina; o AV2/ML8 (`0,15`) continua como erro de piso |

| Besta + | DPS_arma | Maldição autônoma (0,9 × F3) | Técnica | **DPS_pactos** | **TTK** | × Lâmina (10,5310) | × Ressonância (10,4533) | `f_besta` |
|---|---|---|---|---|---|---|---|---|
| Vulto / Baluarte / Soberano (18,00), piso | 48,5 | 16,20 | 0 | **64,70** | **10,8192 s** | 0,0274 | **0,0350** | 0,6182 |
| Espreitador (18,36), piso | 48,5 | 16,52 | 0 | **65,02** | **10,7653 s** | 0,0222 | 0,0298 | 0,6152 |
| Espreitador nível 1 + técnica | 48,5 | 16,52 | 3,50 | 68,52 | 10,2154 s | 0,0309 | 0,0233 | 0,5837 |
| **Espreitador nível 5 (19,28) + técnica, teto** | 48,5 | 17,35 | 3,50 | **69,35** | **10,0937 s** | **0,0433** | 0,0356 | 0,5768 |
| sem Maldição (Chamado recusado) | 40,0 | 0 | 0 | 40,00 | 17,50 s | 0,6618 | 0,6741 | 1 |

- **Parcela da Maldição (leitura da Maldições F6):** Maldição autônoma +
  Chamado (`8,5`) = **`24,70–25,85 DPS`** (piso `24,70` no *Vulto*; `25,02` no
  *Espreitador*; `25,85` no *Espreitador* nível 5). Aqui o Chamado está dentro
  do `DPS_arma` (golpe da arma); lá, na parcela da Maldição. O total é o mesmo.
- **Divisão (ML7):** `f_besta` `0,577–0,618`, dentro de `[0,50; 0,70]`. O
  Chamado é `8,5 / 64,70 = 13,1%` do piso; a Maldição autônoma, `25,0%`.
- **Paridade:** piso `3,50%` (Ressonância), teto **`4,33%`** (Lâmina), as duas
  `≤ 5%`. Margem `0,67` ponto no teto. A Besta deixa de ficar entre as duas
  armas: sem técnica fica abaixo, com técnica acima. Paridade máxima do MVP com
  as três armas: **`0,0433`**.
- **Conferência com Maldições F6 com a técnica:** DPS e TTK batem. Lá o piso
  dá `3,49%` porque usa `10,454 s`; aqui `10,4533 s` dá `3,50%`. Arredondamento,
  sem efeito na meta.
- **"Só Ataque" (informativo):** Virote + Maldição autônoma o ciclo todo, sem
  Chamado: `40 + 18 = 58` → `12,07 s` (`7,7%` mais rápida que a Lâmina só
  Ataque, `12,1%` que a Ressonância). Não vira aviso, como no AV2.
- **Folga do dano do Virote** (`DPS_arma = 4 × dano_virote + 8,5`; Lâmina,
  Ressonância e Maldição fixas): com a meta `0,05`, piso `≥ 66,96 / 1,05 =
  63,77` e teto `≤ 66,47 × 1,05 = 69,79` dão **`9,77–10,11`** (hoje `10`). Com o
  `0,15` do AV2/ML8: `8,38–11,77`. O ML7 só aperta fora de `7,34–14,41`. A folga
  ficou estreita: mexer no Virote mexe na meta.
- **F6, fração do Especial no composto:** `dano_ataque_pct` +25% dá **+15,5%**
  no piso (`10 / 64,70`); `dano_especial_pct` +25% dá **+3,3%**
  (`2,125 / 64,70`), e só se o contrato da R2b for aceito (Open Questions 14).
- **F4, inimigos atraídos:** a atração dura no máximo `1,5 s` e cada inimigo
  recusa atração por `0,5 s` depois (Maldições R17, F4b): mira a Maldição no
  máximo `75%` do tempo. A Vida da Besta volta a contar acertos na janela livre.

### Faixas dos campos (V2 do Conteúdo)

A coluna **V2** é erro de carga (a run não começa). A coluna **Faixa de design**
é aviso (AV7), no registro de validação, como os CVs do Combate. Unidades depois
da F1–F5 do Conteúdo.

**`WeaponDef`**

| Campo | V2 (erro) | Faixa de design (aviso) | MVP | O que quebra fora |
|---|---|---|---|---|
| `vida_max` | int, 20–300 (20 = piso de `vida_max`, Modificadores R2) | 70–140 | 100 / 80 | < 70: o chefe (16) mata em ≤ 5 acertos e a recusa devolve ≤ 28; perto de 30, Preço com Nome (−10) já encosta no piso 20. > 140: a Vida apaga a diferença de risco entre armas (F4) |
| `velocidade` | float, 200–600 px/s | **342–423** (o que o Movimento supõe; cânone 3,8–4,7 u) | 387 / 378 | fora de 342–423, as contas do Movimento (F1, esquiva contra andar) deixam de valer; observação: o jogador já anda perto do projétil do chefe (378 px/s, igual à Ressonância) e abaixo do da Anomalia (414), então fugir andando não basta e a esquiva é necessária; > 423: com +24% de bênçãos passa de 524 px/s e o andar compete com a esquiva (1350 px/s) na leitura |

**`AttackDef` (todas as formas)**

| Campo | V2 (erro) | Faixa de design (aviso) | MVP | O que quebra fora |
|---|---|---|---|---|
| `dano` | float, > 0 e ≤ 200 | Ataque 6–30; Especial 12–60 | 14 / 12; 26 / 30 | Ataque > 30 mata o Eco em 1 golpe em p = 0 (em 30, a borda aceita, já mata: ponto frágil do AV3); Especial ≥ 62 mata toda comum do Limiar em 1 até p 7 (Fenda 62). A faixa é por campo; a fração entre campos é o AV8: com o Ataque atual, o `f_esp` sai de 0,15–0,40 com Especial < 13,7 ou > 51,7, dentro desta faixa |
| `recarga_s` | > 0 (R ≥ 1, CV10) | Ataque 0,1667–0,5 (10–30); Especial 0,6667–2,5 (40–150) | 16 / 14; 70 / 90 | Ataque com R ≤ passos(`cambaleio_s`) = 8: CV17; Ataque com combo e R ≥ J (34): CV5; Especial curto puxa a F6 para > 0,40 |
| `empurrao` | float, 0–1980 px/s (F2 do Conteúdo) | Ataque < `empurrao_pesado` (900); Especial ≥ `empurrao_pesado` se o golpe deve quebrar preparação. O teto do Ataque sem combo (`parede_vel_min` × (1 − q^R)) é do AV5, não do AV7 | 450 / 540; 1080 / 1260 | Ataque ≥ 900: CV8, AV7 e AV4; Ataque sem combo acima do teto: AV5 |
| `multiplicadores_combo` | CV3, CV4 | 2–5 entradas, cada 0,5–2,5, uma só > `limiar_finalizador` | [1; 1; 1,8] / — | CV5 (R × n contra J), CV18/AV4 (trava) |
| `guarda_s` | ≥ 0 | ≤ 0,5 × `recarga_s` (checado pelo AV1, não pelo AV7) | — | ≥ `recarga_s`: guarda permanente (AV1) |

**Params por forma** (Combate R4–R6)

| Forma | Param | V2 (erro) | Faixa de design (aviso) | MVP | O que quebra fora |
|---|---|---|---|---|---|
| `arco` | `alcance_px` | > 0 | 90–240 | 142,5 | ≤ 33 (`raio_jogador` + folga): CV19; > 240 passa do raio da Onda (195) e o arco vira golpe de área |
| `arco` | `meio_angulo_graus` | 5–180 (Conteúdo F5) | 45–90 | 69,51 | < 45: erra inimigos que circulam; 180 vira círculo |
| `circulo` | `raio_px` | > 0 | 120–240 | 195 | < 120: menor que o alcance do arco, perde o papel de área; > 240: o diâmetro passa de 480 px, perto da metade da altura da câmara (1080 px) |
| `circulo` | `deslocamento_px` | ≥ 0 | 0–300 | 0 | > `raio_px` − `raio_jogador`: o centro sai do jogador e cria zona cega colada (intencional na Transmutação) |
| `projetil` | `velocidade_pxs` | > 0 | 600–1500 | 990 | CV12 (s > raio_px + r_min pula inimigos) |
| `projetil` | `raio_px` | > 0 | 9–30 | 15 | CV12, CV20 |
| `projetil` | `vida_s` | > 0; L ≥ 2 (CV13) | alcance testado (F5 do Combate) 400–1100 px | 844,5 | > 1100: atravessa a câmara inteira; < 400: some antes do meio da tela |
| `projetil` | `leque` | lista não vazia de ints ≥ 0, sem repetidos | 1–5 entradas | [0] | leque grande abre buracos (`giro_leque_graus`) |
| `projetil` | `atravessa` | bool | — | falso | — |
| `avanco` | `distancia_px` | ≥ 0 | 150–450 | 330 | CV16 (pula alvos); > 450 atravessa meia câmara invulnerável |
| `avanco` | `duracao_s` | > 0 | 0,1–0,3 (6–18) | 0,1667 (10) | CV15 ((N + E) / R > 0,5); 1 + N ≥ R_atk faz a investida custar Ataques (F1) |
| `avanco` | `raio_px` | > 0 | 40–100 | 69 | CV16 |
| `chamado` (emenda Pactos) | — (sem params; geometria no `MaldicoesTuning`, faixas e ML1/ML6 de Maldições) | — | — | — | — |

**Besta do Vínculo nas faixas (emenda Pactos, 2026-11-15)** — todos dentro, sem AV7:
`vida_max` 90 (70–140); `velocidade` 382,5 (342–423); Virote `dano` 10 (6–30),
R 15 (10–30), `velocidade_pxs` 1170 (600–1500), `raio_px` 12 (9–30), alcance
testado 894 px (400–1100), `leque` [0], `empurrao` 360 (< 900; < teto do AV5
614,84); Chamado `dano` 17, R 120 (40–150), `empurrao` 0.

- **Faixa de `dano` do Especial de forma `chamado`:** a faixa do Especial aqui é
  12–60 e a de `dano_chamado` na Maldições F4 é 10–35. Para a forma `chamado`, o
  AV7 usa a **interseção 12–35** (acima de 35 o Chamado passa
  do golpe da Maldição que Maldições calibrou; abaixo de 12, a regra deste GDD).
- **CVs do Combate com o Virote** (AV6): CV12 s 19,5 < 12 + 22,5 = 34,5; CV13 L
  45 ≥ 2; CV17 R 15 > cambaleio 8; CV20 36 + 19,5 − 34,5 = 21 ≤ 27 + 22,5 =
  49,5; CV6 menor empurrão efetivo do catálogo passa a 360 × 0,12 = 43,2 > z
  4,5; CV7 maior empurrão leve continua 540 (Pulso). Nenhum dispara.

### Validação das armas

Somam-se ao V2 do Conteúdo e aos CV1–CV21 do Combate. **AV6: todo `AttackDef`
de arma passa pelos CVs do Combate que se aplicam à forma dele** (CV3–CV5, CV8,
CV10, CV12, CV13, CV15–CV20); este GDD não os repete.

| Regra | Tipo | Condição | Por quê |
|---|---|---|---|
| AV1 | aviso (decisão do usuário, 2026-11-10; o Guardião é da fatia vertical) | `AttackDef` com `guarda_s` e passos(`guarda_s`) / R > 0,5. **Uma** entrada por objeto: com passos(`guarda_s`) ≥ R, a mensagem é "guarda permanente"; senão, "razão > 0,5" | guarda ativa o tempo todo: × 0,5 de dano permanente (Escudo-Bastião hoje: 120 contra 80) |
| AV2 | aviso | `paridade` (F2) > `meta_paridade` (0,15) entre duas armas do catálogo com números, no modelo combinado; o modelo "só Ataque" sai como linha informativa | meta da R6 (hoje 0,7% combinado, 3,4% só Ataque) |
| AV3 | aviso (informativo) | para cada golpe de arma, inimigo do pool da região e profundidade de câmara de combate: margem ou falta (F3) ≤ `margem_fragil` (2) com g ≤ `g_max_fragil` (3) | ponto de corte frágil: um ajuste de ±2 Vida ou ±1 de dano muda o número de golpes (Onda × Eco 30 = 30) |
| AV4 | aviso, cruzada com IA | inimigo comum com Vida_p > `periodos_trava` (2) × D do período (sobrevive a ≥ 2 períodos; quem morre no 2º período não é trava) e `(ceil(Q / P) × P − Q) < W`, com `P = R` se o Ataque é pesado em todo acerto (`empurrao` ≥ `empurrao_pesado`) e `P = n × R` se só o finalizador é pesado; Vida_p na **maior** profundidade da região | generaliza o CV18 para n = 1 e para a profundidade: o golpe pesado chega sempre antes do fim do preparo e o inimigo nunca ataca (trava) |
| AV5 | aviso | Ataque sem combo, leve, com `empurrao / (1 − q^R)` ≥ `parede_vel_min` | fogo contínuo empurraria o alvo até a parede sem golpe pesado (Pulso: 557,2 contra 630) |
| AV6 | — | ver acima | — |
| AV7 | aviso | campo fora da faixa de design (tabelas acima) | o número sai do espaço em que as contas deste GDD valem |
| AV8 | aviso | `f_esp` (F6) fora de `f_esp_min`–`f_esp_max` (0,15–0,40) | uma das bênçãos de slot perde ou domina o valor |
| AV9 (emenda Pactos) | erro | forma `chamado` fora do slot `especial`, ou num `WeaponDef` cuja `doutrina` não é `pactos`; ou `chamado` com `multiplicadores_combo`, `status` ou `guarda_s` | o Chamado só existe como pedido à Maldição (Maldições R13); combo, status e guarda não têm efeito nele e esconderiam erro de dado. **Contrato pedido ao Conteúdo** (vira regra de carga) |

**Pactos na validação (emenda Pactos, 2026-11-15):**

- **AV2 e Pactos:** o AV2 compara só armas **sem** Maldição. Pares com `pactos`
  são do **ML8** de Maldições (2ª passada, com o catálogo de `CurseDef`), que já
  estende o AV2; assim o mesmo par não sai duas vezes. A
  divisão 60/40 é o **ML7**. As contas são as da F7.
- **AV3 com a Besta:** Virote e Chamado são golpes de arma da tabela da F3 (F7).
  Com `p_max` 4 (fábrica) entram **8** linhas: Virote — Eco (0, 3), Anomalia (3,
  3), (4, 3); Chamado — Eco (1, 2), (2, 2), (3, 3), (4, 3), Fenda (2, 3). O
  catálogo de fábrica passa de 20 para **28** linhas AV3. Com `p_max` 7 entram
  mais 2 — Virote Anomalia (5, 3) e Chamado Anomalia (7, 2) — e o conjunto da
  AC-AR-25 passa de 29 para **39** (AC-AR-49).
- **AV4:** o Virote nunca é pesado e o Chamado é Especial com empurrão 0: o AV4
  não se aplica à Besta.
- **AV5:** Virote 368,88 < 630, sem aviso. **AV8:** 0,1753, sem aviso (o 12,8%
  do composto é linha informativa da F7, não AV8). **AV1:** sem guarda.

**Esclarecimentos da validação** (2026-11-10, a partir da revisão dos critérios):

- **Saída:** uma entrada por regra e por objeto; o erro de uma regra suspende o
  aviso da mesma regra (como no Pipeline visual). A razão guarda/recarga > 0,5 é
  parte do AV1, não do AV7.
- **Faixas são inclusivas** nas duas bordas. `recarga_s`, `duracao_s` e `vida_s`
  são comparados em **passos** (F7 do Conteúdo); a coluna em px de `vida_s` é o
  alcance testado do Combate F5 (844,5 no Pulso), não o "alcance" informativo do
  F6 do Conteúdo (825).
- **Profundidade máxima do Limiar no MVP:** as câmaras de combate têm p de 0 a 4
  (cinco câmaras de combate antes do chefe; no MVP a run não chega ao chefe). O
  AV3 e o AV4 leem o `p_max` da **região** (dono: Câmaras R3; fábrica = 4);
  `ArmasTuning.p_max` é só alias, lido apenas pelo aviso WV8 das Câmaras
  (Tuning Knobs).
- **AV3 e a tabela da F3:** o `*` da tabela marca margem **ou** falta ≤ 2 de
  Vida, em qualquer g; o AV3 só avisa quando, além disso, g ≤ 3.
- **Conjunto exato por código:** cada critério confere só os avisos do código
  AV que ele testa; outros AV, CV ou V2 que o mesmo valor gera ficam fora.
- **Propriedade desconhecida num `.tres`:** o Godot ignora em silêncio; o erro
  de carga do 8º campo (AC-AR-01) depende de uma regra que o Conteúdo ainda não
  tem (**provisório**, Open Questions).
- **Arquivo de preferências corrompido** também gera aviso de debug (como arma
  desconhecida; Edge Cases).
- **Não há chamada de troca de arma durante a run:** a arma é escolhida uma vez
  (R4); não existe API de troca no meio.

**AV4 com os números do MVP (Q 24):** Lâmina, P = 48: ceil(24/48) × 48 − 24 =
24, menor que W do Eco (26), da Anomalia (36) e da Fenda (42). A condição de
Vida decide: 2 × D = 106,4, e a maior comum do Limiar até p 7 é a Fenda (62),
que morre no 4º Corte, dentro do 2º período. **O AV4 não dispara no catálogo de
fábrica** em nenhuma profundidade (o CV18 do Combate também não).
Escudo-Bastião (fatia vertical), P = 30: 6 < W de todos, trava qualquer comum
com Vida > 2 × 22 = 44 (o CV8 avisa que todo acerto é pesado, mas não avisa da
trava).
Ressonância: o Pulso nunca é pesado; o AV4 não se aplica.

## Edge Cases

> `game-designer` e `systems-designer` não consultados nesta seção: modo Lean.

**Escolha e dado**

- **Se o arquivo de preferências não existir ou estiver corrompido:** a tela de
  escolha abre com a Lâmina selecionada e o arquivo é regravado ao confirmar.
  Ausente não avisa (é a primeira vez); corrompido gera 1 aviso de debug.
- **Em build de playtest** (R4): o arquivo não é lido nem gravado, nenhuma arma
  vem selecionada e confirmar fica bloqueado até o jogador escolher uma carta;
  o caso acima e o seguinte não se aplicam.
- **Se o arquivo lembrar uma arma que não está no catálogo** (removida, ou de uma
  fase futura num build do MVP): vale a Lâmina, e o debug registra o aviso.
- **Se o catálogo tiver uma arma com `AttackDef` inválido:** é erro do Conteúdo
  (V1–V11, CV do Combate, AV deste GDD) e a run não começa (Conteúdo R12). A tela
  de escolha nunca mostra arma inválida.
- **Se o jogador fechar a tela de escolha sem confirmar** (Esc): volta ao menu
  anterior, sem começar a run.
- **Se só houver uma arma disponível:** a tela de escolha ainda aparece, com uma
  carta, para o jogador ver o que vai usar.

**Durante a run**

- **Se uma bênção de slot for pega** (`dano_ataque_pct`, `dano_especial_pct`):
  vale para o Ataque ou o Especial da arma em uso, qualquer que seja a forma
  (R5).
- **Se uma bênção mudar `vida_max` ou `velocidade`:** o Modificadores recalcula
  sobre a base da arma (Modificadores F1, F4); a arma não muda.
- **Se o jogador morrer:** a arma não muda nem perde nada; a próxima run abre a
  tela de escolha de novo (R4).
- **Se uma Tradição da própria Doutrina da arma sair:** não há efeito especial no
  MVP; sinergias de Doutrina, se houver, são do GDD de Bênçãos.

**Números**

- **Se o ganho de Vida por profundidade tirar a Onda do ponto de corte do Eco
  Perdido** (30 de dano contra 30 de Vida em p = 0; 32 em p = 1): a Onda passa a
  precisar de 2 golpes a partir da segunda câmara. É esperado e está registrado
  como ponto frágil (F3, AV3); não é defeito.
- **Se o Pulso acertar um inimigo encostado numa parede:** 540 px/s fica abaixo
  de `parede_vel_min` (630): não há batida (Combate F8). Isso vale para Pulsos
  espaçados (o intervalo deixa o empurrão decair); Pulsos em rajada somam o empurrão
  (Combate R8.6) e podem bater se a soma passar de 630.
- **Se dois Pulsos atingirem o mesmo inimigo no mesmo passo:** os empurrões
  somam (1080) e podem bater na parede; é consequência da regra do Combate.

**Conflitos com outros GDDs:**

- **Empurrão do projétil (Conteúdo, Edge Cases "Constantes escondidas",
  l. 638–650):** a lista do Conteúdo punha o empurrão fixo de 6 u do projétil
  (`engine.ts:1174`) como campo do `CombatTuning`. Com o aval do usuário
  (2026-11-10), o Conteúdo passa a dizer que o empurrão do projétil é o do
  `AttackDef` (Pulso 540), como manda o Combate R6; não existe campo global de
  empurrão de projétil. A emenda no Conteúdo já foi feita (Conteúdo, Status e
  l. 638–641, 2026-11-10).
- Os dois problemas do Guardião (fatia vertical) ficam nas Open Questions.

**Besta do Vínculo (emenda Pactos, 2026-11-15)**

- **Se o jogador apertar Especial sem Maldição em campo** (nenhuma pactuada, as
  duas Exaustas, ou só uma e ela Exausta): o Chamado é recusado, a recarga do
  Especial fica como está (0), sem recuperação, e sai `chamado_indisponivel`
  uma vez por toque novo (R2b; Maldições R13, AC-ML-18). Segurado, não repete o
  evento.
- **Se a Maldição estiver `Saltando`:** recusado do mesmo jeito (Maldições Edge
  Cases l. 498). Com R_esp 120 > N_salto 12, só acontece se a recarga for
  reduzida por dado de teste.
- **Se Especial e Ataque estiverem segurados e o Chamado for recusado:** o
  Virote sai no mesmo passo, se a recarga dele for 0 (Combate R3).
- **Se o Virote matar o inimigo:** `acerto_virote` sai com esse alvo; a marca
  aponta para um morto e a Maldições R4.1 cai para o item 2 (mais perto do
  jogador).
- **Se o Virote acertar com dano 0** (M = 0): ainda é acerto de arma e move a
  marca (R2b).
- **Se o Virote passar pela Maldição:** não a atinge (Maldições R1) e segue até o
  primeiro inimigo atingível.
- **Se o jogador jogar Pactos sem nenhuma Maldição pactuada:** DPS 40, TTK 17,5 s,
  67% mais lento que a Ressonância (F7). Não há aviso: o ML8 só olha a dupla.
  Isso fere a paridade da R6 na primeira run de Pactos; registrado como conflito
  (Open Questions 12).
- **Se a atração do Chamado (180 passos) for renovada antes de acabar** (recarga
  120): os inimigos no raio podem mirar a Maldição sem parar enquanto ela estiver
  em campo. É cobertura forte para o jogador (a F4 deixa de valer); a Exaustão
  (Maldições R9) é o limite. Registrado para o `/balance-check` (Open Questions
  16), sem mudar números de Maldições.
  **(emenda Pactos, 2026-11-15) Resolvido:** a Maldições R17/F4b pôs a atração
  em `1,5 s` (`90` passos) com respiro de `0,5 s` (`30` passos). Atração e
  respiro somam `120` passos, igual à recarga do Chamado: o Chamado a cada
  recarga atrai `90` e deixa `30` livres. Nenhum inimigo mira a Maldição mais
  de `1,5 s` seguidos nem mais de `75%` do tempo, com qualquer mistura de
  fontes. A F4 vale de novo na janela livre (F7 com os valores da emenda).
- **Se uma bênção de `dano_todo` for pega com a Besta:** sobe o Virote; sobe a
  Maldição só se a propagação da Maldições OQ3 for aceita (F7).

## Dependencies

**Depende de (upstream)**

| Sistema | Tipo | O que vem de lá | Sem ele |
|---|---|---|---|
| Combate núcleo | Forte | formas de golpe, combo, recarga, recuperação, impacto, CV1–CV21 | a arma não faz nada |
| Modificadores e atributos | Forte | `vida_max` e `velocidade` como atributos com base na arma; F2 (bênçãos de slot) | sem Vida nem velocidade |
| Conteúdo orientado a dados | Forte | formato do `WeaponDef` e do `AttackDef`, conversões F2–F7, validação V1–V11, nomes canônicos (V5) | números no código, o que a regra do projeto proíbe |
| Tela de bênção e componente de carta | Suave, **por contrato** | o componente de carta para a tela de escolha (R4) | a tela de escolha usa uma lista simples |
| Input e controle | Suave | navegação da tela de escolha (teclado, mouse, gamepad); Ataque e Especial segurados chegam via Combate (Input R7) | a tela de escolha não navega |
| Maldições (emenda Pactos) | **Forte** | a Maldição em campo que o Chamado manda saltar (R13), a consulta "pode chamar", o DPS autônomo (F3) para a F7, ML7/ML8 | o Chamado é sempre recusado e a Besta fica em 40 DPS (F7) |

**É dependência de (downstream)**

| Sistema | Tipo | O que recebe |
|---|---|---|
| Modificadores e atributos | Forte | a base de `vida_max` e `velocidade` (R9 injeta a base da arma no atributo) |
| IA de inimigos e elites | Suave | Vida por profundidade e dano dos golpes (F3; avisos AV3 e AV4; F5 e IV7 da IA citam as armas) |
| Câmaras e ondas | Suave | `ArmasTuning.p_max` como alias, lido apenas pelo WV8 (o `p_max` é da região, R3) |
| Run e regiões | Suave | a arma da run e a profundidade `p` (R9) |
| Movimento e esquiva | Suave | `velocidade` base (via Modificadores) |
| Bênçãos (Tradições) | Suave | `doutrina` da arma; os slots Ataque e Especial |
| HUD | Suave | nomes da arma, do Ataque e do Especial |
| Telemetria local | Suave | arma escolhida em cada run (meta de paridade, R6) |
| Selo e Fluxo | Suave | recargas, DPS e Vida por profundidade (Formulas F3–F5, SV6, SV12 do Selo) |
| Efeitos de status | Suave | `status` dos `AttackDef` (nenhum nas armas do MVP; DPS de referência para ST5) |
| Feedback de combate (VFX) / Pipeline visual | Suave | as formas e os params dos `AttackDef` (o desenho do golpe tem o tamanho do teste) |
| ~~Criatura do pacto (Alpha)~~ **Maldições (MVP; emenda Pactos)** | Forte | a `WeaponDef pactos`, o disparo do Chamado do Pacto (forma `chamado`) e o evento `acerto_virote` (marca, Maldições R4.1); `maldicoes.md` Dependencies l. 510 já lista Armas (bidirecional) |
| Desbloqueio de armas (Alpha) | Forte | a lista de armas e Doutrinas |
| Rito de Iniciação e Campus (fatia vertical) | Forte | a arma da Doutrina jurada, que substitui a tela de escolha |

**Bidirecionalidade:**

- O Combate (Overview, Interactions, Dependencies), o Modificadores (R2), o
  Movimento (R4, R11) e o Conteúdo (R1) já citam as armas e o `WeaponDef`.
- Bênçãos, HUD, Telemetria, Tela de bênção, IA, Câmaras, Run, Selo e Efeitos de
  status já existem: conferir que cada um lista "Armas das Doutrinas" em
  Dependencies. Criatura do pacto, Desbloqueio, Rito e Campus ainda não existem;
  cada um, ao ser escrito, deve listar "Armas das Doutrinas".
- O Input e controle já lista Armas (`input-e-controle.md:542`). O Movimento cita
  o `WeaponDef` pelo Conteúdo, sem nomear Armas: na próxima edição dele,
  acrescentar "Armas das Doutrinas (suave, via Modificadores)".
- **(emenda Pactos)** Maldições ↔ Armas é **Forte nos dois sentidos**: Armas
  fornece a Besta, o Chamado e `acerto_virote`; Maldições fornece o salto, a
  consulta "pode chamar" e o DPS da F7. `maldicoes.md` já cita Armas
  (Interactions l. 224, Dependencies l. 510). A forma `chamado` pede emenda no
  Combate núcleo (R3, R4–R6) e no Conteúdo (enum, AV9); o ponto mirado no
  gamepad pede emenda no Input (R5). A "Criatura do pacto" deixou de ser GDD
  separado: é o GDD de Maldições.
- **Índice:** a linha 9 lista Combate, Modificadores e Conteúdo; acrescentar
  "Tela de bênção e componente de carta (suave, por contrato)" e "Input e
  controle (suave)", e o status passa de "Not Started" para "Designed".

## Tuning Knobs

Os números de cada arma vivem no `WeaponDef` e nos `AttackDef` (R2), com as
faixas da seção Faixas dos campos. Os limites da validação vivem no recurso
**`ArmasTuning`** (dado, um `*Tuning` por sistema, Conteúdo R1; entra na tabela
de `*Tuning` do Conteúdo). Nada disso fica literal no GDScript.

| Campo | Inicial | Faixa segura | Categoria | O que afeta | Por que este valor |
|---|---|---|---|---|---|
| `meta_paridade` | 0,15 | 0,05–0,30 | curva | AV2 (R6, F2) | decisão do usuário; < 0,05 avisa por ruído do modelo contínuo, > 0,30 deixa uma arma dominar |
| `margem_fragil` | 2 (Vida) | 0–5 | gate de validação | AV3 (F3) | ±2 de Vida é o que um ajuste pequeno de dado move; 0 deixa só os casos `=` |
| `g_max_fragil` | 3 | 1–6 | gate de validação | AV3 | acima de 3 golpes, um a mais ou a menos não muda a leitura da câmara |
| `p_max` | 4 (Limiar do MVP: 5 câmaras de combate) | 0–20 | gate | AV3, AV4 | o dono é Câmaras (R3): o valor é lido da região, e `ArmasTuning.p_max` é só alias |
| `periodos_trava` | 2 | 1–4 | gate de validação | AV4 (o "2 ×") | quem morre dentro do 2º período não chega a ser travado |
| `f_esp_min` / `f_esp_max` | 0,15 / 0,40 | 0–1, min < max | curva | AV8 (F6) | abaixo, a bênção de Especial não vale nada; acima, o Ataque vira enchimento |
| `vel_media_min` / `vel_media_max` | 360 / 400 px/s | dentro de 342–423, min < max | apresentação | rótulo de velocidade da carta (R4, UI): < min "lenta", min–max "média", > max "rápida" | as duas do MVP (387, 378) ficam "média": diferença de 2,4% que o jogador não sente; o rótulo só muda com armas futuras fora dessa faixa |
| Faixas de design | tabelas de Faixas dos campos | — | curva | AV7 | o espaço em que as contas deste GDD valem |

As metas do playtest (escolha de 35–65%, vitória por câmara a ≤ 15 pontos; R6)
são critérios de playtest, não dado de jogo. **(emenda Pactos)** Com três armas,
18–48% (R6). A Besta não acrescenta campo ao `ArmasTuning`: os
números dela vivem no `WeaponDef pactos` (R2b) e a geometria do Chamado no
`MaldicoesTuning` (dono: Maldições). A faixa de `dano` 12–35 da forma `chamado`
entra nas faixas de design do AV7.

## Visual/Audio Requirements

> `art-director` e `audio-director` não consultados: modo Lean. A arma não cria
> VFX próprio: o desenho de cada golpe é o da forma (Combate Visual/Audio V2–V5;
> Pipeline visual R6) e tem o tamanho do teste de acerto.

- **Silhueta por arma** (Art Bible §3.3, §5.4): a Lâmina dá à silhueta uma
  diagonal (espada reta longa, ~0,6 da altura, corpo inclinado para a frente); o
  Foco dá uma silhueta mais alta (orbe acima da cabeça, braço estendido). A
  troca de arma tem de ser lida no teste da miniatura a 90 px (§3.1).
- **Animação** (Art Bible §5.8, ajustada ao combo de cada arma): a Lâmina tem 3
  golpes no combo; o Foco não tem combo (1 quadro de disparo e 2 de saída no
  Pulso; 1 de gesto na Onda, contra os 8–12 quadros-chave do Especial no §5.8,
  que entram na mesma emenda). A regra "quadros por golpe × entradas do combo da
  arma" substitui o "3 golpes × 4–6 quadros, por arma" do §5.8 (emenda no Art
  Bible, Open Questions). Todo quadro de saída pode ser cortado pelo próximo
  golpe ou pela esquiva.
- **Alcance:** o jogador lê o alcance pelo desenho do golpe, não pelo tamanho
  da arma no sprite (R3).
- **Áudio** (requisito provisório): cada arma tem a sua família de sons de golpe,
  dentro do clima do Combate A1 (Lâmina: risco de pincel seco; Foco: estalo de
  tinta leve no Pulso, grave na Onda).
- **(emenda Pactos)** Besta do Vínculo: o Virote usa o desenho de projétil do
  jogador (Combate V4), em escala menor que o Pulso (raio 12 contra 15). O
  Chamado não tem desenho próprio da arma: o que se vê é o salto e o pouso da
  Maldição (Maldições ML-V3, ML-V4, Game Feel). Silhueta, sprite e som da Besta
  ficam com `art-director` e `audio-director` (Open Questions 15).

> 📌 **Asset Spec** — rodar `/asset-spec system:armas-das-doutrinas` depois do
> Art Bible: sprites e rig das duas armas do MVP, quadros por golpe e ícones das
> cartas da tela de escolha.

## Game Feel

- **Duas maneiras de jogar a mesma câmara:** com a Lâmina, o jogador entra,
  encadeia três Cortes e quebra a preparação no terceiro, e usa a Investida para
  entrar ou sair; com o Foco, ele mantém distância, atira sem parar (o Pulso não
  congela) e guarda a Onda para quando a linha aperta.
- **Peso diferente, mesmas regras:** a Lâmina congela 3 + 3 + 6 passos num combo;
  o Pulso não congela; a Onda congela 6. O ritmo muda, o tempo para matar fica
  igual (F2).
- **Risco visível:** a Ressonância aguenta 2 golpes a menos do chefe (F4). O
  jogador sente que está perto do limite; é a filosofia de Maren.
- **Alvo de playtest:** os testadores conseguem descrever a diferença entre as
  duas armas em uma frase cada, sem dica (registro [M]).
- **(emenda Pactos) Nunca sozinho:** com a Besta, o jogador atira e esquiva sem
  microgerenciar; mirar o Virote já escolhe o alvo da Maldição, e o Chamado é o
  momento pedido (salto, segura, atrai). O Virote não congela; o peso vem do
  pouso do Chamado (chute de câmera da Maldições Game Feel). Alvo de playtest:
  o testador diz, sem dica, que "a criatura vai atrás do que eu acerto" (AC-AR-52).

## UI Requirements

- **Tela de escolha da arma** (R4): duas cartas com nome, Doutrina, Vida,
  velocidade (mostrada como relativa: "lenta", "média" ou "rápida", pelos
  limiares do `ArmasTuning`, R4; não em px/s) e os nomes do Ataque e do Especial
  com uma linha de descrição (chave `<chave_nome>_DESC`, R4). Navegação por teclado,
  mouse e gamepad (Input). A última arma confirmada vem selecionada, salvo no
  build de playtest, em que nada vem selecionado (R4).
- **HUD:** nenhuma informação nova; os chevrons e a Vida já existem. O nome da
  arma aparece na pausa (GDD de HUD/Menus).
- **(emenda Pactos)** A tela de escolha mostra três cartas. A carta da Besta usa
  os mesmos campos (Vida 90, "média", "Virote" / "Chamado do Pacto"). Se o
  jogador não tem Maldição pactuada, a carta mostra uma linha de aviso
  ("sem Maldição: o Chamado não responde"; texto final do
  ux-designer). A recusa do Chamado (`chamado_indisponivel`) pede feedback no
  HUD como o da Troca (Maldições UI Requirements); dono: HUD.

> **📌 UX Flag — Armas das Doutrinas:** a tela de escolha é uma tela nova. No
> Pre-Production, rodar `/ux-design` para ela (pode reaproveitar o componente de
> carta) antes das epics.

## Cross-References

| Documento | Seção | Uso neste GDD |
|---|---|---|
| `design/gdd/combate-nucleo.md` | R3–R8, R13, R15, F1–F3, F7, F8, F11, CV1–CV21, Visual/Audio V2–V5 | formas, combo, recarga, recuperação, impacto, validação, DPS de referência, desenho dos golpes |
| `design/gdd/modificadores-e-atributos.md` | R2, R10, R12, F1–F4, OQ4 | atributos com base na arma, profundidade e elite, consumidores de dano, guarda |
| `design/gdd/conteudo-orientado-a-dados.md` | R1, R2, R11, V2, V5, F2–F7 | `WeaponDef`, `AttackDef`, ids, nomes canônicos, faixas, conversões |
| `design/gdd/movimento-e-esquiva.md` | R4, R11 | velocidade de andar da arma |
| `design/gdd/pipeline-visual.md` | R1, R6 | traço e materiais dos golpes |
| `design/gdd/game-concept.md` | §3, §6, §7 | pilares, uma arma por Doutrina, Mestres |
| `design/art/art-bible.md` | §3.1, §3.3, §5.4, §5.8 | silhueta, forma dominante, animação |
| Khaeros `packages/combat-rules/src/arenaContent.ts` | `ARENA_WEAPONS`, `ARENA_ENEMIES` | números das 6 armas e dos inimigos do Limiar |
| Khaeros `packages/action-core/src/engine.ts` | `:1174` | o empurrão fixo de 6 u do projétil (origem do Pulso 540) |
| `design/gdd/maldicoes.md` (emenda Pactos) | R1, R2, R4.1, R6, R7, R9, R13, F3, F4, F6, §Constantes (l. 462), ML1, ML7, ML8, Edge Cases (l. 498), OQ3, AC-ML-05, 18, 22 | números da Besta, Chamado, marca do Virote, DPS da Maldição, paridade composta |
| `design/gdd/input-e-controle.md` (emenda Pactos) | R5 | vetor de mira e ponto mirado do Chamado |
| `design/gdd/combate-nucleo.md` (emenda Pactos) | R7 (projétil do jogador: primeiro atingível), R8.2, R10 (hitstop 0 do projétil), R17, F5, Edge Cases l. 1019 | Virote e `acerto_virote` |

## Acceptance Criteria

> Proposta do `qa-lead` (consultado: modo Lean, 2026-11-10), corrigida na 1ª
> revisão independente (2026-11-10). As contas de R2, F1–F6, das faixas e dos
> AV1–AV8 foram refeitas por script a partir do cânone convertido (Conteúdo F1–F7)
> e das fórmulas do Combate; onde o script discorda do GDD, a divergência está na
> nota de cobertura, com linha.
>
> Evidência: **[L]** `tests/unit/weapons/`; **[I]** `tests/integration/weapons/`;
> **[UI]** screenshot de cada tela tocada, retido em `production/qa/evidence/`;
> **[V]** Visual/Feel: screenshot retido em `production/qa/evidence/` com
> assinatura do lead; **[P]** desempenho; **[M]** manual, com testador, build e
> resultado registrados.
>
> Tolerâncias: dano e DPS calculado ±0,001 (as contas são do validador, em
> double); DPS **medido** em run ±2%; posição ±0,01 px (o `Vector2` é float32);
> frações e paridade ±0,0001. Passos, contagens de golpes, `g`, eventos, avisos e
> erros são exatos. **"Conjunto exato"** quer dizer: a lista de avisos/erros que
> sai é igual à da linha, nem mais nem menos (a ordem não importa). Bordas
> decimais que não são representáveis em binário (0,15; 0,5 × 0,2667) são
> testadas a ±0,001 do limite, um ponto de cada lado; bordas em passos são
> testadas exatas.
>
> Cada critério é independente: o teste copia a fixture e o roteiro citados;
> nenhum critério depende do resultado de outro. Nada de seed nem de tempo real:
> tudo roda por passos (`TICK_RATE` 60), com o catálogo, o Combate e o
> Modificadores montados em memória (R9) e dublês injetados para o resto. Os
> contratos com Bênçãos, Telemetria, Tela de bênção, HUD e Câmaras são
> **provisórios**: os critérios que dependem deles usam dublês que honram este
> GDD; o que só pode ser testado com o sistema real fica **BLOQUEADO até o GDD X**.
>
> **Fixture de armas (FA):**
>
> - **Catálogo de fábrica:** o `.tres` versionado do Conteúdo com as duas armas do
>   MVP, carregado pelo carregador real (V1–V11, CV do Combate, AV deste GDD).
> - **Catálogo de teste (FA-T):** cópia em memória do catálogo de fábrica em que o
>   critério troca só os campos que cita. "Lâmina ×s" é a Lâmina com o `dano` do
>   Ataque e do Especial multiplicados por s e `id` `lamina_teste`.
> - `CombatTuning` padrão (FP do Combate): J = 34, Q = 24, leve 3, pesado 6,
>   `recuperacao_max` 12, `fator_recuperacao_golpe` 0,5, `empurrao_pesado` 900,
>   `parede_vel_min` 630, q = 0,78, z = 4,5, `invuln_atingido` 40.
> - `ArmasTuning` padrão (Tuning Knobs): `meta_paridade` 0,15, `margem_fragil` 2,
>   `g_max_fragil` 3, `periodos_trava` 2, `f_esp` 0,15–0,40, faixas de design
>   das tabelas e `vel_media_min`/`vel_media_max` 360/400. A FA usa a
>   **região de teste** com `p_max` 7 (o `p_max` é lido da região, dono: Câmaras
>   R3); `ArmasTuning.p_max` é só alias, lido apenas pelo WV8 das Câmaras. Com
>   a região de teste em 7 e o alias em 4, o WV8 **é gerado** como aviso
>   (consistente com Câmaras AC-CO-24); o valor de fábrica (4) só vale onde o
>   critério diz "`ArmasTuning` de fábrica".
> - **Inimigos do Limiar** (cânone): Eco 30/9/24/W 26; Anomalia 24/8/22,5/36;
>   Fenda 46/13/30/42; chefe 700/16/63/40. `fator_empurrao`: comum 1, elite 0,4,
>   chefe 0,12.
> - **Região de teste:** pool {Eco, Anomalia, Fenda}, câmaras de combate com
>   p = 0…`p_max`, elite a partir de p = 3. Padrão `p_max` = 7; o critério diz
>   quando muda.
> - **Saco** e **Saco móvel**: os da FP do Combate (raio 24, Vida 1000, comum;
>   `fator_empurrao` 0 e 1). **Elite móvel:** a Elite da FP do Combate (raio 28,8,
>   Vida 1000, `fator_empurrao` 0,4). **Câmara:** (0; 0)–(1920; 1080), sem obstáculos.
>   **Jogador:** (960; 540), raio 27, mira (1; 0).
> - **Movimento dublê** (FP do Combate) que **não** executa `deslocar` nem `d`,
>   salvo quando o critério diz; **Input dublê** da FP do Combate.
> - **Preferências dublê:** um `FileAccess` em memória para `user://` (estados:
>   ausente, conteúdo dado pelo critério), com registro de leituras e gravações.
> - **Bênçãos dublê:** devolve o pool que recebe, registra o que o sistema de
>   Armas pede e aplica modificadores no portador real quando o roteiro manda.
> - Espião de eventos, do registro de validação (avisos, erros, linhas
>   informativas) e do log de debug.
>
> Os passos são numerados a partir de 0 e contam todos os passos do orquestrador,
> vivos e congelados. "Após n" é o estado ao fim do passo n.

**A. Dado, conversões e injeção (R1, R2, R9)**

- **AC-AR-01 [L] R1 — os 7 campos.** O esquema de `WeaponDef` tem exatamente
  `id`, `doutrina`, `chave_nome`, `vida_max`, `velocidade`, `ataque`, `especial`.
  - **Provisório** (Open Questions 9): a fixture `.tres` em texto
    `tests/unit/weapons/fixtures/arma_campo_extra.tres`, com um 8º campo
    (`guarda_extra = 1`), não carrega: erro de carga do Conteúdo e a run não
    começa. Depende de o Conteúdo ganhar a regra de propriedade desconhecida
    (o Godot a ignora em silêncio).
  - Um `WeaponDef` sem `especial` não carrega (erro de campo obrigatório).
  - Nenhum outro arquivo do sistema de Armas guarda número de jogo: o teste lista
    as constantes numéricas dos scripts de `src/` do sistema e a lista é vazia
    (exceto 0 e 1 de controle).
- **AC-AR-02 [L] R2 — Lâmina do Juramento, carregada do catálogo de fábrica.**
  `id` `lamina`, `doutrina` `lamina`, `vida_max` 100, `velocidade` 387,0.
  - Ataque: forma `arco`, `alcance_px` 142,5, `meio_angulo_graus` 69,51,
    `cos_meio` 0,350044 ±0,000001, `dano` 14, `recarga_s` = 16/60 em float64
    (não 0,2667), R = 16, `empurrao` 450, `multiplicadores_combo` [1; 1; 1,8],
    sem status, sem `guarda_s`.
  - Especial: forma `avanco`, `distancia_px` 330, `duracao_s` = 10/60 (N = 10),
    `raio_px` 69, `dano` 26, `recarga_s` = 70/60 (R = 70), `empurrao` 1080,
    sem combo.
- **AC-AR-03 [L] R2 — Foco Ressonante, carregado do catálogo de fábrica.**
  `id` `ressonancia`, `doutrina` `ressonancia`, `vida_max` 80, `velocidade` 378,0.
  - Ataque: `projetil`, `velocidade_pxs` 990, `raio_px` 15, `vida_s` = 50/60
    (L = 50), `leque` [0], `atravessa` falso, `dano` 12, `recarga_s` = 14/60
    (R = 14), **`empurrao` 540** (não 270, que é o dado de teste da FP-R do
    Combate), sem combo, sem status.
  - Especial: `circulo`, `raio_px` 195, `deslocamento_px` 0, `dano` 30,
    `recarga_s` = 90/60 (R = 90), `empurrao` 1260, sem combo.
- **AC-AR-04 [L] R2 — conversões do cânone** (importação do Conteúdo a partir de
  `arenaContent.ts:27–66`; F2 × 90, F4 × 1,5, F1 ticks/60, F7
  `max(1, round(t × 60))`):

  | Cânone | Conversão | Gravado | Passos (F7) |
  |---|---|---|---|
  | `moveSpeed` 4,3 / 4,2 | F2 | 387 / 378 px/s | — |
  | Corte `range` 95, `dot` 0,35 | F4, F5 | 142,5 px; 69,51° | — |
  | Corte / Pulso / Investida / Onda `cooldownTicks` 16 / 14 / 70 / 90 | F1 | 16/60 … 90/60 s | 16 / 14 / 70 / 90 |
  | Investida `distance` 220, duração 10 ticks, `radius` 46 | F4, F1 | 330 px; 10/60 s; 69 px | 10 |
  | Pulso `projectileSpeed` 11, `radius` 10, `rangeTicks` 50 | F2, F4, F6 | 990 px/s; 15 px; 50/60 s | 50 |
  | Onda `radius` 130 | F4 | 195 px | — |
  | `knockback` Corte 5 / Investida 12 / Onda 14 | F2 | 450 / 1080 / 1260 px/s | — |
  | Pulso: 6 u fixo do motor (`engine.ts:1174`), não os 3 u do dado | F2 | **540** px/s | — |

  Cada duração passa pela F7 uma vez, no fim: `16/60 × 60` dá 16, não 17.
- **AC-AR-05 [L] recuperação derivada (Combate F2).** Com a FA,
  `rec = min(12, round(R × 0,5))`; investida sem recuperação (Combate R6):

  | Golpe | R | rec (passos) |
  |---|---|---|
  | Corte | 16 | 8 |
  | Investida | 70 | 0 |
  | Pulso | 14 | 7 |
  | Onda | 90 | 12 (min(12, 45), preso no teto) |

- **AC-AR-06 [I] R9 — injeção no começo da run.** Com Combate e Modificadores
  reais em memória, para cada arma do catálogo de fábrica, ao entrar em Equipada:
  - o portador do jogador nasce com `vida_max` base 100 (Lâmina) / 80
    (Ressonância), Vida atual igual, e `velocidade` base 387 / 378; sem bênção,
    o valor final é igual à base;
  - o Combate recebe os dois `AttackDef` da arma escolhida (mesma instância do
    catálogo, comparada por referência) nos slots Ataque e Especial;
  - uma bênção dublê `vida_max` +10 aplicada depois recalcula sobre a base da
    arma (110 / 90) e não altera o `WeaponDef` do catálogo (Edge Cases).
- **AC-AR-07 [L] R1 — arma sem regra própria.** Em FA-T, `lamina_clone` é a
  Lâmina com outro `id`, `doutrina` e `chave_nome`. O roteiro versionado
  `tests/unit/weapons/fixtures/roteiro_clone.json` (600 passos, Ataque e
  Especial com toques e segurados, 3 Ecos) dá, com `lamina` e com
  `lamina_clone`, sequências idênticas bit a bit de posições, Vidas, recargas,
  hitstop e eventos. O mesmo com `ressonancia` e um clone.

**B. Escolha da arma (R4, estados)**

- **AC-AR-08 [L] R4 — arma pré-selecionada.** Catálogo de fábrica; cada linha
  monta a tela de escolha (lógica, sem render) com o arquivo de preferências da
  coluna. Conjunto exato de avisos de debug.

  | Arquivo de preferências | Selecionada | Aviso de debug |
  |---|---|---|
  | ausente (primeira vez) | `lamina` | nenhum |
  | `ultima_arma = "ressonancia"` | `ressonancia` | nenhum |
  | `ultima_arma = "lamina"` | `lamina` | nenhum |
  | bytes inválidos (corrompido) | `lamina` | 1 aviso (arquivo corrompido) |
  | `ultima_arma = "adagas_veu"` (fora do catálogo) | `lamina` | 1 aviso, citando `adagas_veu` |
  | `ultima_arma = ""` | `lamina` | 1 aviso (arma desconhecida) |

  Nenhuma linha grava o arquivo ao abrir a tela.
- **AC-AR-09 [L] R4 — confirmar e Esc.**
  - Arquivo corrompido, o jogador confirma `ressonancia`: o arquivo é regravado
    com `ultima_arma = "ressonancia"`, uma gravação; reabrir a tela seleciona
    `ressonancia`.
  - Arquivo com `lamina`, o jogador move a seleção para `ressonancia` e aperta
    Esc: nenhuma gravação, nenhuma run começa (o estado volta ao menu anterior,
    não entra em Equipada); reabrir seleciona `lamina`.
- **AC-AR-10 [L] estados e arma fixa.** Com a flag de playtest desligada:
  Escolhendo → (confirmar) Equipada →
  (`jogador_morreu` ou vitória) Encerrada → (nova run) Escolhendo. Durante
  Equipada:
  - não existe API de troca (Esclarecimentos): a inspeção do contrato público do
    sistema de Armas não acha método de equipar fora de Escolhendo, e, durante
    600 passos de run, gravar outra arma no arquivo de preferências não muda a
    arma equipada;
  - depois de `jogador_morreu`, a próxima run abre Escolhendo com a arma
    da run anterior selecionada (Edge Cases: "a arma não muda nem perde nada").
- **AC-AR-11 [L] R4 — uma carta; arma inválida.**
  - FA-T só com `lamina`: a tela tem 1 carta, selecionada; confirmar funciona.
  - FA-T com `ressonancia` de `recarga_s` 0 (erro CV10 do Combate): o carregador
    dá erro, a run não começa e a tela de escolha não é montada (nunca mostra
    arma inválida; Conteúdo R12).
- **AC-AR-39 [L] R4 — build de playtest.** Catálogo de fábrica, flag de
  playtest ligada, Preferências dublê com `ultima_arma = "ressonancia"`:
  - a tela abre sem carta selecionada e o registro do dublê mostra **zero
    leituras** do `user://preferencias.cfg`;
  - confirmar sem carta escolhida não faz nada (o estado continua Escolhendo,
    nenhuma run começa);
  - o jogador escolhe `lamina` e confirma: entra em Equipada com `lamina` e o
    dublê mostra **zero gravações**;
  - depois de `jogador_morreu`, a próxima Escolhendo abre de novo sem carta
    selecionada;
  - conjunto exato de avisos de debug: nenhum (o arquivo não é lido, então não
    há "corrompido" nem "arma desconhecida").
  - Linha de controle: a mesma fixture com a flag desligada seleciona
    `ressonancia` (AC-AR-08).
- **AC-AR-12 [UI] R4 — tela de escolha.** Build com o catálogo de fábrica, 1920
  × 1080. Screenshots retidos: (a) primeira vez, Lâmina selecionada; (b) depois
  de uma run com a Ressonância, Ressonância selecionada; (c) FA-T com uma arma
  só. Cada carta mostra o nome canônico, a Doutrina, Vida (100 / 80), velocidade
  e os nomes do Ataque e do Especial (R8); a seleção é distinguível sem cor
  (forma ou contorno). A velocidade aparece como rótulo, "média" nas duas armas
  (387 e 378 entre 360 e 400, R4), e cada golpe mostra o texto da chave
  `<chave_nome>_DESC` do `AttackDef` (nenhuma chave sem tradução). Usa o
  componente de carta do GDD de Tela de bênção.
- **AC-AR-13 [V] R3 — silhueta das armas.** Screenshot retido do Iniciado com
  cada arma, parado e atacando, no fundo da câmara do Limiar: Lâmina lê
  diagonal (espada reta longa, corpo inclinado), Ressonância lê círculos
  concêntricos (orbe acima da cabeça, braço estendido), Art Bible §5.4.
  Assinatura do `art-director`. **BLOQUEADO até os sprites das armas.**

**C. Bênçãos (R5)**

- **AC-AR-14 [I] R5 — bênçãos de slot valem para a arma em uso.** Combate e
  Modificadores reais; Bênçãos dublê aplica no portador. Alvo: Saco em
  (1040; 540) para a Lâmina (80 px: dentro da Investida parada, 93, e do Corte,
  166,5) e em (1100; 540) para a Ressonância (dentro do Pulso e da Onda, 219);
  um golpe de cada slot, primeiro golpe do combo:

  | Bênção | Lâmina: Corte / Investida | Ressonância: Pulso / Onda |
  |---|---|---|
  | nenhuma | 14 / 26 | 12 / 30 |
  | `dano_ataque_pct` +0,25 | 17,5 / 26 | 15 / 30 |
  | `dano_especial_pct` +0,25 | 14 / 32,5 | 12 / 37,5 |

  A forma do golpe não muda a regra (arco, avanço, projétil e círculo dão a
  mesma razão 1,25 ±0,001).
- **AC-AR-15 [L] R5 — a arma não restringe o pool.** Bênçãos dublê com um pool de
  todas as Tradições do MVP. Com `lamina` e com `ressonancia` equipadas, o
  sistema de Armas não filtra nem repesa: o pool que o dublê recebe é igual
  (mesmos ids, mesmos pesos) nas duas runs, e o único dado que Armas fornece às
  Bênçãos é a `doutrina` (registro do dublê). Pesos por Doutrina, se vierem,
  são do GDD de Bênçãos (fora deste critério).

**D. Fórmulas (F1–F6, R6)**

> As contas de D são do relatório de validação (linhas informativas), calculadas
> a partir do catálogo carregado. Nenhum número da tabela vive no código.

- **AC-AR-16 [L] F1 — DPS de referência, M = 1, um alvo.**

  | Golpe | DPS vivo | DPS real |
  |---|---|---|
  | Corte (c̄ 1,2667, R 16, h̄ 4) | 66,500 | 53,200 |
  | Investida (R 70, h 6) | 22,286 | 20,526 |
  | Lâmina combinado (k 4,375; D_ciclo 103,583; H_ciclo 23,5) | **88,786** | **66,471** |
  | Pulso (R 14, h 0) | 51,429 | 51,429 |
  | Onda (R 90, h 6) | 20,000 | 18,750 |
  | Ressonância combinado (k 6,4286; D_ciclo 107,143; H_ciclo 6) | **71,429** | **66,964** |

  Com M = 1,3 (bênção `dano_todo` dublê) os seis combinados e os por golpe
  sobem × 1,3 e a razão Lâmina/Ressonância não muda (±0,0001).
- **AC-AR-17 [L] F2/R6 — TTK do chefe e paridade.** Catálogo de fábrica, chefe
  700:
  - combinado contínuo: Lâmina 10,5310 s, Ressonância 10,4533 s, paridade
    0,0074 (0,7%); sem AV2;
  - só Ataque contínuo: 13,1579 s e 13,6111 s, paridade 0,0344 (3,4%), como
    **linha informativa** (não aviso);
  - só Ataque discreto: Lâmina g = 40 Cortes, `TTK_disc` = 39 × 16 + 13 × 12 =
    780 passos; Ressonância g = 59 Pulsos, 58 × 14 = 812 passos; paridade
    0,0410;
  - folga (linha informativa): dano do Pulso com paridade ≤ 0,15 entre 10,80 e
    14,27 (só Ataque) e 9,72 e 14,35 (combinado), passo de 0,01.
- **AC-AR-18 [L] F3 — golpes até matar.** Região de teste, sem bênção, combo a
  partir do passo 0. (a) Vida_p: Eco 30, 32, 33, 35, 36, 38, 39, 41; Anomalia
  24, 25, 26, 28, 29, 30, 31, 32; Fenda 46, 48, 51, 53, 55, 58, 60, 62; elite
  (p 3–7) Eco 83, 86, 90, 94, 97; Anomalia 66, 69, 72, 75, 78; Fenda 127, 132,
  138, 144, 149. (b) g, margem, falta (exatos; margem e falta ±0,001):

  | Inimigo, p | Vida_p | Corte | Pulso | Onda | Investida |
  |---|---|---|---|---|---|
  | Eco 0 | 30 | 3 (falta 2) | 3 | 1 (margem 0) | 2 |
  | Eco 1 | 32 | 3 | 3 | 2 (falta 2) | 2 |
  | Eco 4 | 36 | 3 | 3 (margem 0) | 2 | 2 |
  | Anomalia 0 | 24 | 2 | 2 (margem 0) | 1 | 1 (margem 2) |
  | Anomalia 1 | 25 | 2 | 3 (falta 1) | 1 | 1 (margem 1) |
  | Anomalia 3 | 28 | 2 (margem 0) | 3 | 1 (margem 2) | 2 (falta 2) |
  | Anomalia 5 | 30 | 3 (falta 2) | 3 | 1 (margem 0) | 2 |
  | Fenda 3 | 53 | 3 (margem 0,2) | 5 | 2 | 3 (falta 1) |
  | Fenda 4 | 55 | 4 (falta 1,8) | 5 | 2 | 3 |
  | Fenda 6 | 60 | 4 | 5 (margem 0) | 2 (margem 0) | 3 |
  | Eco elite 3 | 83 | 6 (falta 1,8) | 7 (margem 1) | 3 | 4 |
  | Fenda elite 7 | 149 | 9 | 13 | 5 (margem 1) | 6 |

  Os pontos frágeis da F3 são reproduzidos: Onda × Eco 30 = 30 em p 0 e 2 golpes
  em p 1; Corte × Eco 28 de 30; Pulso × Anomalia 24 = 24; Corte × Fenda 53,2
  contra 53 em p 3 e 4 golpes em p 4. Os meios exatos (Eco p 1, 3, 5, 7; Fenda
  p 5) são conferidos no GDScript com a ordem de cálculo da nota da F3.
- **AC-AR-19 [L] F4 — golpes recebidos até morrer.** Modificadores real, sem
  bênção e sem recusa; `dano = max(1, round(base × elite))`:

  | Atacante | dano | Lâmina (100) | Ressonância (80) | tempo mínimo Ressonância (passos) |
  |---|---|---|---|---|
  | Eco / elite | 9 / 11 | 12 / 10 | 9 / 8 | 320 / 280 |
  | Anomalia / elite | 8 / 10 | 13 / 10 | 10 / 8 | 360 / 280 |
  | Fenda / elite | 13 / 16 | 8 / 7 | 7 / 5 | 240 / 160 |
  | Chefe | 16 | 7 | 5 | 160 |

  Lâmina × chefe: 240 passos. Com `vida_max` 81 (bênção +1), a Ressonância
  sobrevive a 5 acertos do chefe e morre no 6º (81/16 = 5,06; o "+1 compra um acerto").
- **AC-AR-20 [L] F5 — empurrão do Pulso, Combate real.** Pulso de fábrica (540),
  um acerto, alvo longe das paredes; o alvo anda a partir do passo seguinte ao
  acerto (o projétil é o item 8 da R1 do Combate; F7 do Combate):

  | Alvo (`fator_empurrao`) | emp_ef | passos com movimento | distância (±0,01 px) | `parede` |
  |---|---|---|---|---|
  | Saco móvel (1) | 540 | 20 | 40,62 | não |
  | Elite móvel (0,4) | 216 | 16 | 16,06 | não |
  | Chefe (0,12) | 64,8 | 11 | 4,59 | não |

  O Pulso nunca marca golpe pesado (nenhum pedido de "Quebrou!", hitstop 0).
- **AC-AR-21 [I] F5 — fogo contínuo não bate na parede.** Combate real,
  **jogador em (1200; 540)**, mira (1; 0), Saco móvel em (1500; 540) (396 px da
  posição encostada, x = 1920 − 24 = 1896), Ataque da Ressonância segurado nos
  passos 0–599, Movimento dublê parado. O Pulso alcança o Saco até x = 1200 +
  844,5 + (15 + 24) = 2083,5 > 1896, então os acertos continuam até a parede
  (com o jogador em 960, o limite seria 1843,5 e o Saco pararia em 1867,89 px
  depois de 9 acertos, sem encostar). Os números exatos abaixo vêm do script da
  re-review (ordem das R1, R3, R7 e R11 do Combate; primeiro disparo no passo
  0, primeiro acerto no passo 13). **Derivação do passo 13** (conferida contra
  a R1 e a R7 do Combate): o projétil nasce a `nascimento_projetil_px` = 36 px
  do jogador (x = 1236) e anda 990/60 = 16,5 px já no passo em que nasce (item 5
  dispara, item 8 anda, mesmo passo). O contato é a 39 px do centro do Saco
  (raio_px 15 + r 24), ou seja, a x = 1461: faltam 1461 − 1236 = 225 px, e
  225/16,5 = 13,64 passos, então são 14 deslocamentos (passos 0 a 13) e o
  primeiro acerto é no passo 13 (x = 1467). Sem o offset de 36 px a conta seria
  261/16,5 = 15,8 (passo 15), que não é a regra do Combate. O teste os confere contra o oráculo gerado
  das mesmas regras:
  - nenhum evento `parede` e nenhum dano de parede;
  - a maior velocidade do Saco logo depois de um acerto fica ≤ 557,20 px/s
    (v_sust; ±0,01) e < 630 (o voo cresce com a distância, então o intervalo
    entre acertos é ≥ 14 passos);
  - o Saco encosta (x = 1896) no passo 166, depois do 10º acerto (40,91 px por
    ciclo de 14 passos em regime), e termina lá, sem `parede`: 41 acertos na
    janela, Vida final 508 (o Saco não morre: a janela de 600 passos fica longe
    dos 84 acertos que o matariam).
  - Linha de controle: o mesmo roteiro com o Pulso de FA-T `empurrao` 650
    (v_sust 670,7 ≥ 630) gera ≥ 1 `parede` antes do passo 599; a primeira sai
    quando o Saco encosta, no passo 150, depois do 9º acerto (650 ≥ 630). O
    Saco não morre na janela, mesmo com o dano de parede.
- **AC-AR-22 [L] F6 — fração do Especial.** `f_esp` Lâmina 0,2510; Ressonância
  0,2800. Efeito de bênção de slot +0,25 no DPS combinado: Especial +6,28% /
  +7,00%; Ataque +18,72% / +18,00% (±0,0001). O teste confere a previsão contra
  o DPS combinado da F1 recalculado com o `dano` bentado (mesma fração).
- **AC-AR-40 [L] F1 — teto de M = 4,0 (provisório).** Modificadores real com
  `teto_multiplicador_dano` 4,0 (M efetivo = min(M, 4,0); Modificadores F2/AC-04b),
  Lâmina combinada de fábrica: DPS máximo = 66,471 × 4 = 265,884 (±0,01). TTK do
  chefe (Vida 700) com o DPS máximo: 700/265,88 ≈ 2,63 s. **Provisório:** o
  valor 4,0 do teto é provisório; se o teto mudar, o critério é recalculado
  (DPS máx. = 66,471 × teto).

**E. Validação (AV1–AV8)**

> Cada linha muda um campo de FA-T e confere o **conjunto exato** dos avisos AV
> daquele critério; avisos CV e V2 que o mesmo valor gera são de outros
> critérios. Onde dois AV podem sair juntos, a linha diz.

- **AC-AR-23 [L] AV1 — guarda.** Corte de FA-T (R = 16) com `guarda_s`:

  | `guarda_s` | passos | AV1 |
  |---|---|---|
  | ausente | — | nenhum |
  | 8/60 | 8 (razão 0,5) | nenhum |
  | 9/60 | 9 (0,5625) | 1 entrada: razão > 0,5 |
  | 15/60 | 15 | 1 entrada: razão > 0,5 |
  | 16/60 | 16 (= R) | 1 entrada: guarda permanente |
  | 20/60 | 20 | 1 entrada: guarda permanente |

  A comparação é em passos (F7), nunca em segundos. Uma entrada AV1 por objeto
  (Esclarecimentos); nenhuma linha gera AV7 de `guarda_s`.
- **AC-AR-24 [L] AV2 — paridade.** Catálogo de teste só com `lamina` e "Lâmina
  ×s" (`lamina_teste`), **sem** `ressonancia` (paridade combinada = s − 1):

  | s | paridade | AV2 |
  |---|---|---|
  | 1,149 | 0,149 | nenhum |
  | 1,151 | 0,151 | 1 aviso, citando o par |
  | 0,85 | 0,1765 | 1 aviso (a mais lenta é a referência do `min`) |

  Catálogo de fábrica: nenhum AV2; a linha informativa "só Ataque" sai com
  0,0344 e nunca vira aviso, nem com s = 1,2 nela. Catálogo com 3 armas
  (`lamina`, `ressonancia`, Lâmina ×1,151): conjunto exato
  {`lamina`×`lamina_teste`}; `ressonancia`×`lamina_teste` dá 10,4533 / 9,1494 −
  1 = 0,1425 e não avisa. Com Lâmina ×1,17: {`lamina`×`lamina_teste` (0,17),
  `ressonancia`×`lamina_teste` (10,4533 / 9,0008 − 1 = 0,1614)}.
- **AC-AR-25 [L] AV3 — pontos frágeis (informativo), conjunto exato.** Catálogo
  de fábrica, região de teste com `p_max` 7 (o `p_max` é lido da **região**, dono: Câmaras R3; `ArmasTuning.p_max` é só alias, lido apenas pelo WV8; esta região de teste com `p_max` 7 e alias 4 **gera** o WV8 como aviso, consistente com Câmaras AC-CO-24), elites de p 3. Condição: margem ou
  falta ≤ 2 **e** g ≤ 3. As linhas informativas são exatamente estas 29
  (inimigo, p, golpe, g):
  - Eco: (0, Corte, 3), (0, Onda, 1), (1, Onda, 2), (3, Pulso, 3), (4, Pulso, 3);
  - Anomalia: (0, Pulso, 2), (0, Investida, 1), (1, Pulso, 3), (1, Investida,
    1), (2, Corte, 2), (2, Pulso, 3), (2, Investida, 1), (3, Corte, 2), (3,
    Onda, 1), (3, Investida, 2), (4, Corte, 3), (4, Onda, 1), (5, Corte, 3), (5,
    Onda, 1), (6, Onda, 2), (7, Onda, 2);
  - Fenda: (2, Investida, 2), (3, Corte, 3), (3, Investida, 3), (5, Onda, 2),
    (6, Onda, 2), (7, Onda, 3);
  - elites: Eco elite (5, Onda, 3), Anomalia elite (7, Investida, 3).

  Fora do conjunto, por exemplo: Fenda 4 Corte (falta 1,8, g = 4) e Eco elite 3
  Corte (g = 6), que a tabela da F3 marca com `*` (o `*` vale em qualquer g; o AV3, só com g ≤ 3). Com
  `margem_fragil` 0 o conjunto fica só com os 9 casos `=` de g ≤ 3: Eco (0,
  Onda, 1), (4, Pulso, 3); Anomalia (0, Pulso, 2), (2, Investida, 1), (3, Corte,
  2), (5, Onda, 1); Fenda (6, Onda, 2); Eco elite (5, Onda, 3); Anomalia elite
  (7, Investida, 3).
  - **`ArmasTuning` de fábrica** (alias `p_max` 4 = o da região de fábrica, sem a sobrescrita da FA): o
    conjunto exato são as 20 linhas acima com p ≤ 4 (saem as 9 de p 5–7:
    Anomalia (5, Corte), (5, Onda), (6, Onda), (7, Onda); Fenda (5, Onda), (6,
    Onda), (7, Onda); Eco elite (5, Onda); Anomalia elite (7, Investida)).
- **AC-AR-26 [L] AV4 — trava por golpe pesado.** O `p_max` vem da região (Câmaras R3; `ArmasTuning.p_max` é só alias, lido apenas pelo WV8; região de teste com `p_max` 7 e alias 4 gera o WV8 como aviso, consistente com Câmaras AC-CO-24). Catálogo de fábrica (Q = 24;
  Lâmina P = n × R = 48; ceil(24/48) × 48 − 24 = 24 < W de todas as comuns):

  | Região | AV4 |
  |---|---|
  | `p_max` 3 (Fenda 53 ≤ 2 × 53,2 = 106,4) | nenhum |
  | `p_max` 4 (Fenda 55 ≤ 106,4: morre no 4º Corte, no 2º período) | nenhum |
  | `p_max` 7 (Fenda 62 ≤ 106,4) | nenhum |
  | qualquer, Ressonância | nenhum (o Pulso nunca é pesado) |

  FA-T, Ataque de teste sem combo com `dano` 14, `empurrao` 900 e R = 30 (P = 30;
  30 − 24 = 6 < W; 2 × D = 28), conjunto exato por `p_max`:

  | `p_max` | Vida_p (Eco / Anomalia / Fenda) | AV4 |
  |---|---|---|
  | 3 | 35 / 28 / 53 | Eco, Fenda (Anomalia 28 = 28, borda: não avisa) |
  | 4 | 36 / 29 / 55 | Eco, Anomalia, Fenda |
  | 7 | 41 / 32 / 62 | Eco, Anomalia, Fenda |

  Elites não entram (só comuns).
- **AC-AR-27 [L] AV5 — empurrão contínuo de Ataque leve sem combo.** Pulso de
  FA-T (R = 14, teto 630 × (1 − 0,78¹⁴) = 610,56):

  | `empurrao` | AV5 |
  |---|---|
  | 540 (fábrica; 557,20 contínuo: 540/(1 − 0,78¹⁴) = 557,196) | nenhum |
  | 610 | nenhum |
  | 611 | 1 aviso |
  | 899 | 1 aviso |
  | 900 | nenhum AV5 (golpe pesado: é o CV8 do Combate e o AV4) |

  Corte (com combo) com `empurrao` 620: nenhum AV5 (só sem combo).
- **AC-AR-28 [L] AV6 — CV do Combate valem para arma.** FA-T: Corte com
  `multiplicadores_combo` [1; 1; 1,8] e `recarga_s` 34/60 (R = J) dá o CV5 do
  Combate citando `lamina`; Pulso com `vida_s` 1/60 (L = 1) dá o erro CV13. O
  relatório não repete a regra com código AV.
- **AC-AR-29 [L] AV7 — faixas de design (aviso).** FA-T, um campo por linha;
  bordas em passos exatas, as decimais a ±0,01:

  | Campo | Sem aviso | AV7 |
  |---|---|---|
  | `vida_max` | 70 e 140 | 69 e 141 |
  | `velocidade` | 342 e 423 | 341,99 e 423,01 |
  | `dano` do Ataque | 6 e 30 (faixa inclusiva) | 5,99 e 30,01 |
  | `dano` do Especial | 12 e 60 | 11,99 e 60,01 |
  | R do Ataque | 10 e 30 passos | 9 e 31 |
  | R do Especial | 40 e 150 passos | 39 e 151 |
  | `arco.alcance_px` | 90 e 240 | 89,99 e 240,01 |
  | `arco.meio_angulo_graus` | 45 e 90 | 44,99 e 90,01 |
  | `circulo.raio_px` | 120 e 240 | 119,99 e 240,01 |
  | `circulo.deslocamento_px` | 0 e 300 | 300,01 |
  | `projetil.velocidade_pxs` | 600 e 1500 | 599,99 e 1500,01 |
  | `projetil.raio_px` | 9 e 30 | 8,99 e 30,01 |
  | `projetil.leque` | 1 e 5 entradas | 6 entradas |
  | `avanco.distancia_px` | 150 e 450 | 149,99 e 450,01 |
  | `avanco.duracao_s` | 6 e 18 passos | 5 e 19 |
  | `avanco.raio_px` | 40 e 100 | 39,99 e 100,01 |
  | `projetil.vida_s` (Pulso, s = 16,5; alcance testado 36 + (L − 1) × 16,5) | L = 24 (415,5 px) e 65 (1092 px) | L = 23 (399 px) e 66 (1108,5 px) |
  | `empurrao` do Ataque (Corte, com combo: sem AV5) | 0 e 899,99 | 900 (o CV8 e o AV4 que o mesmo valor gera ficam fora) |
  | `multiplicadores_combo` do Corte (`limiar_finalizador` 1,2) | [1; 1,8], [1; 1; 1; 1; 1,8] e [0,5; 1; 2,5] | [1,8] (1 entrada), [1; 1; 1; 1; 1; 1,8] (6), [0,49; 1; 1,8], [1; 1; 2,51] e [1; 1,8; 1,8] (duas acima do limiar; o CV3 que sai junto fica fora) |

  `vida_s` = L/60; a borda é em px do alcance testado (Combate F5), calculado
  dos passos. Catálogo de fábrica: nenhum AV7.
- **AC-AR-30 [L] V2 — faixas de erro de carga.** FA-T, um campo por linha; a run
  não começa nas colunas de erro. O caso não inteiro usa fixture `.tres` em
  texto (`vida_max = 100.5`), porque um campo `int` tipado em memória não guarda
  100,5; ele é **provisório** como a AC-AR-01 (Open Questions 9):

  | Campo | Aceitos | Erro |
  |---|---|---|
  | `vida_max` | 20 e 300 | 19, 301 e 100,5 (não inteiro, `.tres` em texto) |
  | `velocidade` | 200 e 600 | 199,99 e 600,01 |
  | `dano` | 0,01 e 200 | 0, −1 e 200,01 |
  | `empurrao` | 0 e 1980 | −0,01 e 1980,01 |
  | `meio_angulo_graus` | 5 e 180 | 4,99 e 180,01 |
  | `leque` | [0] e [0; 1; 2] | [] e [0; 0] |

- **AC-AR-31 [L] AV8 — fração do Especial.** Lâmina de FA-T com o `dano` da
  Investida trocado (D_ataque por ciclo 77,583):

  | `dano` Investida | f_esp | AV8 |
  |---|---|---|
  | 13,6 | 0,1492 | 1 aviso |
  | 13,8 | 0,1510 | nenhum |
  | 51,6 | 0,3994 | nenhum |
  | 51,9 | 0,4008 | 1 aviso |

- **AC-AR-32 [L] catálogo de fábrica — relatório completo, conjunto exato.**
  Região de teste `p_max` 7 (o `p_max` é lido da região, dono: Câmaras R3; o
  alias `ArmasTuning.p_max` só é lido pelo WV8, e com alias 4 e região 7 o WV8
  **é gerado** como aviso, consistente com Câmaras AC-CO-24; o WV8 é das Câmaras,
  não um código AV): zero erros; avisos AV = {}
  (nenhum AV1, AV2, AV4, AV5, AV7 nem AV8). O conjunto exato vale para as
  **linhas informativas com código AV**: as 29 do AV3 (lista da AC-AR-25), a
  linha "só Ataque" do AV2 (0,0344), as duas linhas de folga do AV2 (AC-AR-17)
  e a linha de alcance do Pulso do AV7 (`vida_s` L = 50, alcance testado 844,5
  px). As linhas informativas **sem** código AV (contas da seção D: DPS, TTK,
  g, F4, F5, f_esp) ficam fora deste conjunto; quem as confere são as AC-AR-16 a
  22.

**F. Nomes (R8, V5 do Conteúdo)**

- **AC-AR-33 [L] R8 — nomes canônicos.** As chaves `chave_nome` das armas e dos
  `AttackDef` do catálogo de fábrica resolvem, em pt-BR e em NFC, para
  exatamente: "Lâmina do Juramento", "Foco Ressonante", "Corte", "Investida",
  "Pulso", "Onda de Ressonância". Um `WeaponDef` de FA-T com "Lamina do
  Juramento" (sem acento) dá erro V5; a mesma grafia em NFD passa. As quatro
  armas futuras, quando entrarem no catálogo, são conferidas contra a lista da
  R8 pela mesma regra.
- **AC-AR-34 [L] R8 — "Corte" × Corte da esquiva.** Varredura da tabela de
  tradução: nenhuma chave de bênção, carta ou HUD diferente da do Ataque da
  Lâmina resolve para o texto "Corte" sozinho; o efeito da bênção de esquiva
  resolve para "O Corte Fantasma". Varredura de `design/gdd/*.md`: toda menção
  ao efeito usa "Corte da esquiva" ou o nome da bênção (lista de ocorrências
  revisada pelo `qa-lead`; o teste automatizado cobre só a tabela de tradução).

**G. Integração (Combate e Modificadores reais)**

- **AC-AR-35 [I] F1 — DPS medido em run, por arma.** Combate e Modificadores
  reais em memória, catálogo de fábrica, sem bênção. Movimento dublê não executa
  `d` nem `deslocar` (o jogador não sai do lugar com a investida). Alvo: **Saco**
  (`fator_empurrao` 0, parado como supõe o F1) em (1040; 540) para a Lâmina (80
  px: dentro da Investida parada, 69 + 24 = 93, e do Corte, 166,5) e (1100; 540)
  para a Ressonância (dentro do Pulso e da Onda, 219). Roteiro "jogador
  perfeito" versionado em `tests/integration/weapons/fixtures/roteiro_dps_{lamina,
  ressonancia}.json`: Ataque segurado; Especial apertado no primeiro passo vivo
  em que está pronto **e** o **passo vivo anterior** teve disparo de Ataque (F1,
  perda b; os passos congelados pelo hitstop do Corte não contam como
  "anterior"). Passos 0–599 de cada arma:
  - DPS real medido = dano somado no Saco × 60 / 600, **igual ao oráculo
    discreto** gerado por script a partir do mesmo roteiro e das regras do
    Combate (±0,5%); o F1 combinado é só referência (±5%: Lâmina 66,47,
    Ressonância 66,96), porque o modelo contínuo não conta a ordem exata do
    disparo no passo. Referência do script da re-review: Lâmina 662,8 de dano
    (66,28/s, −0,3% do F1), Ressonância 672 (67,20/s, +0,35%);
  - número de Especiais disparados = **6 em cada arma** (no script da
    re-review: Investidas nos passos 4, 111, 215, 322, 429 e 533; Ondas nos
    passos 1, 105, 209, 313, 417 e 521).
- **AC-AR-36 [I] R2/R9 — a arma escolhida é a que luta.** Fluxo completo em
  memória: tela de escolha lógica → confirmar `ressonancia` → run com Combate e
  Modificadores reais → o primeiro Ataque cria um projétil de 990 px/s e raio
  15, o primeiro Especial um círculo de raio 195; Vida 80/80. Mesmo fluxo com
  `lamina`: arco de 142,5 e avanço de 330; Vida 100/100.

**H. Playtest da meta (R6)**

- **AC-AR-37 [M] R6 — escolha de arma.** Em ≥ 40 runs de ≥ 5 testadores
  (build de playtest registrado, sem pré-seleção da arma; R4), cada arma é escolhida em 35% a 65% das runs (Telemetria
  local). **BLOQUEADO até o GDD de Telemetria local**; até lá, planilha manual
  com testador, run, arma.
- **AC-AR-38 [M] R6 — vitória por câmara.** Nas mesmas runs, a taxa de vitória
  por câmara do Limiar (câmaras completadas / câmaras iniciadas) de uma arma
  fica a ≤ 15 pontos percentuais da outra, por câmara e no total. Fora da meta,
  o resultado vai para o `/balance-check` (só números do `AttackDef`). Mesmo
  bloqueio da AC-AR-37. **Registro para o `/balance-check` (ADVISORY), não
  pass/fail:** o veredito de pass/fail exige n ≥ 100 runs por arma; com ~20
  runs o erro-padrão ≈ 15,6 pontos, que é ≥ a meta de ≤ 15. **Amostra:** com ~20 runs por arma, a diferença de 15
  pontos numa câmara está dentro do ruído (o erro-padrão de uma taxa perto de
  50% com 20 runs é ~11 pontos por arma). O registro anota o número de runs por
  arma e por câmara junto de cada taxa, para o `/balance-check` ler a diferença
  com esse ruído.

**I. Besta do Vínculo (emenda Pactos, 2026-11-15)**

> Fixture extra **FA-P**: catálogo de fábrica com `pactos` (R2b) e os 4 `CurseDef`
> e o `MaldicoesTuning` de fábrica de `maldicoes.md`; Maldições real em memória
> (ou dublê que honra Maldições R4, R13 e F3, dito no critério). Onde as ACs
> antigas falam do "catálogo de fábrica com as duas armas", o catálogo de fábrica
> pós-emenda tem as três; as contagens que mudam estão na AC-AR-49 e AC-AR-50, e
> as linhas das ACs antigas sobre `lamina` e `ressonancia` continuam valendo.

- **AC-AR-41 [L] R2b — Besta do Vínculo, carregada do catálogo de fábrica.**
  **GIVEN** FA-P, **WHEN** o carregador real lê `pactos`, **THEN** `id` e
  `doutrina` `pactos`, `vida_max` 90, `velocidade` 382,5; Ataque `projetil`,
  `velocidade_pxs` 1170, `raio_px` 12, `vida_s` = 45/60 (L = 45), `leque` [0],
  `atravessa` falso, `dano` 10, `recarga_s` = 15/60 (R = 15), `empurrao` 360,
  sem combo, sem status; Especial forma `chamado`, `dano` 17, `recarga_s` =
  120/60 (R = 120), `empurrao` 0, sem combo, sem status, sem `guarda_s`; zero
  erros e zero avisos AV/CV para `pactos`.
- **AC-AR-42 [L] Combate F2 — recuperação da Besta.** **GIVEN** a FA, **WHEN**
  Virote e Chamado disparam, **THEN** `rec` = 8 (round(7,5)) e 12 (min(12, 60)).
  Um Chamado **recusado** não põe recuperação (rec 0).
- **AC-AR-43 [I] R2b — Virote é golpe de arma sem hitstop.** **GIVEN** Combate e
  Selo dublê reais, jogador em (960; 540) mira (1; 0), Saco em (1100; 540),
  **WHEN** um Virote acerta, **THEN** o Saco perde 10, sai 1 `acerto_de_arma`
  (slot ataque), o contador de acertos sobe 1, o dublê do Selo recebe 1 acerto
  para Fluxo, **nenhum** pedido de hitstop, `pesado` falso, e o projétil some.
  Com dois Sacos em linha (1100 e 1200), só o primeiro é atingido.
- **AC-AR-44 [L] R2b — evento `acerto_virote` e marca.** **GIVEN** `pactos`
  equipada e o espião de eventos, **WHEN** (a) um Virote acerta o inimigo id 5,
  (b) um Virote com M = 0 acerta o id 2, (c) um Virote mata o id 7, (d) o
  Chamado acerta o id 9, **THEN** saem `acerto_virote` com alvo 5, 2 e 7, no
  passo do impacto, e **nenhum** para o id 9. Com `lamina` equipada, o Corte não
  gera `acerto_virote`. Com Maldições real, após (a) o alvo da Maldição é o id 5
  no passo vivo seguinte (Maldições AC-ML-05).
- **AC-AR-45 [I] R2b — Chamado dispara o salto.** **GIVEN** FA-P, `vulto_mudo` em
  campo em (900; 540), jogador em (960; 540), cursor do mouse em (1460; 540),
  Especial com recarga 0, **WHEN** o jogador aperta Especial, **THEN** a
  Maldição recebe o pedido com ponto alvo (1380; 540) (limitado a 420 px), a
  recarga do Especial passa a 120, a recuperação a 12, e o golpe do pouso é
  `de_arma` falso (nenhum `acerto_de_arma`, nenhum hitstop, nenhum Fluxo).
  Com gamepad e mira (0; 1): ponto alvo (960; 960) **[provisório até o Input]**.
- **AC-AR-46 [L] R2b — Chamado recusado não gasta recarga.** **GIVEN** recarga
  do Especial 0, **WHEN** o jogador aperta Especial com (a) nenhuma Maldição em
  campo, (b) a Maldição `Saltando`, **THEN** nada salta, a recarga fica 0, a
  recuperação fica 0, sai 1 `chamado_indisponivel` por toque novo (segurar 30
  passos não repete) e, com o Ataque segurado e pronto, um Virote sai no mesmo
  passo.
- **AC-AR-47 [L] F7 — DPS composto e paridade, M = 1.** **GIVEN** FA-P e chefe
  700, **WHEN** o validador calcula a F7, **THEN** DPS_arma 48,500; DPS_pactos
  66,500 (Vulto, Baluarte, Soberano) e 66,860 (Espreitador); TTK 10,5263 e
  10,4697 s; `f_besta` 0,6015 e 0,5983; paridade máxima entre as três armas
  0,0074 (Lâmina × Ressonância); zero AV2 com `pactos` (o par é do ML8) e zero
  ML7/ML8. Linha informativa sem Maldição: 40,000 e 17,5000 s.
  **(emenda Pactos, 2026-11-15) Valores que valem (F7 com os valores da
  emenda):** DPS_arma 48,500; piso DPS_pactos 64,700 (Vulto, Baluarte,
  Soberano) e 65,024 (Espreitador); TTK 10,8192 e 10,7653 s; teto (Espreitador
  nível 5 + técnica `14 / 4,0`) 69,350 e 10,0937 s; `f_besta` 0,6182, 0,6152 e
  0,5768; paridade máxima entre as três armas 0,0433 (teto × Lâmina), piso
  0,0350 (× Ressonância), ambas `≤ meta_paridade_pactos` 0,05; zero AV2 com
  `pactos` e zero ML7/ML8. Com dano do Virote 10,2 (teto 70,15 DPS, 9,9786 s, 5,54%), sai
  o aviso da meta de Pactos (Maldições ML8).
- **AC-AR-48 [L] F3/F4/F5b — contas da Besta.** **GIVEN** a região de teste,
  **THEN** os `g`, margens e faltas da tabela da F7 batem exatos (±0,001); F4
  com Vida 90: 10, 9, 12, 9, 7, 6, 6 (Eco, Eco elite, Anomalia, Anomalia elite,
  Fenda, Fenda elite, chefe); F5b: 26,96 px / 18 passos, 10,57 / 14, 3,00 / 10
  (±0,01), `v_sust` 368,88 e teto 614,84; alcance testado 894 px.
- **AC-AR-49 [L] AV3 com a Besta — conjunto exato.** **GIVEN** catálogo de
  fábrica pós-emenda, **WHEN** a validação roda com a região de teste `p_max` 7,
  **THEN** as linhas AV3 são as 29 da AC-AR-25 **mais** estas 10: Virote — Eco
  (0, 3), Anomalia (3, 3), (4, 3), (5, 3); Chamado — Eco (1, 2), (2, 2), (3, 3),
  (4, 3), Anomalia (7, 2), Fenda (2, 3): 39 no total. Com `ArmasTuning` de
  fábrica (`p_max` 4): 20 + 8 = **28** (saem Virote Anomalia 5 e Chamado
  Anomalia 7). Com `margem_fragil` 0: 9 + 3 = 12 (Virote Eco 0, Anomalia 5;
  Chamado Fenda 2).
- **AC-AR-50 [L] AV9 e relatório de fábrica.** **GIVEN** FA-T, **WHEN** (a) a
  Lâmina tem Especial de forma `chamado`, (b) `pactos` tem `chamado` no slot
  Ataque, (c) o Chamado tem `multiplicadores_combo` [1; 1,8], **THEN** cada caso
  dá 1 erro AV9 e a run não começa. Catálogo de fábrica pós-emenda: zero erros,
  zero avisos AV, linhas informativas = as da AC-AR-32 com as 39 AV3 da AC-AR-49
  no lugar das 29 e mais a linha de alcance do Virote (L = 45, 894 px).
- **AC-AR-51 [I] R5 — bênçãos com a Besta.** **GIVEN** Combate, Modificadores e
  Maldições reais, **WHEN** `dano_ataque_pct` +0,25, **THEN** o Virote causa
  12,5 e o ataque básico da Maldição não muda. **WHEN** `dano_especial_pct`
  +0,25, **THEN** o Chamado causa 21,25. **BLOQUEADO até o contrato da R2b ser
  aceito por Maldições/Modificadores** (OQ3 de Maldições).
- **AC-AR-52 [M] R3/Game Feel — leitura da dupla.** Em ≥ 10 runs com a Besta e
  ao menos uma Maldição, ≥ 70% dos testadores descrevem, sem dica, que a
  Maldição ataca o que o Virote acerta e que o Chamado a faz saltar. Registro com
  testador, build e frase. A AC-AR-37 passa a usar a faixa 18–48% por arma
  (R6) e a AC-AR-38 compara cada par; a AC-AR-12 ganha a carta
  da Besta (Vida 90, "média").

**Nota de cobertura**

- Contagem: 31 [L] (com a AC-AR-40, teto do M), 5 [I] (AC-AR-06, 14, 21, 35, 36), 1 [UI] (12), 1 [V] (13),
  2 [M] (37, 38; a AC-AR-38 é ADVISORY) — 40 critérios (a AC-AR-39 fica no bloco B, junto da R4); nenhum [P] (o GDD não define orçamento; a
  validação do catálogo herda o [P] do Conteúdo, se houver).
- Cobertura por regra: R1 01, 07; R2 02–04, 36; Combate F2 05; R3 13; R4 08–12, 39;
  R5 14, 15; R6 17, 37, 38; R7 (só AV1/AV4 de teste) 23, 26; R8 33, 34; R9 06;
  estados 10; F1 16, 35; F2 17, 24; F3 18, 25; F4 19; F5 20, 21, 27; F6 22, 31;
  faixas 29, 30; AV1–AV8 23–32; Edge Cases 06, 08–11, 14, 18, 21, 39.
- Fora da cobertura: "dois Pulsos no mesmo passo somam 1080" (Edge Cases, linhas
  641–642) não é produzível com `leque` [0] e R 14; a soma é do Combate R8 e
  fica nos ACs dele. Tradição da própria Doutrina (linhas 628–629): sem efeito
  no MVP, nada a testar aqui.
- Contas refeitas por script: conversões e passos (R2, F7), `cos_meio`
  0,350044, recuperação 8/0/7/12, F1 (88,79/66,47; 71,43/66,96; por golpe
  66,5/53,2, 22,29/20,53, 51,43, 20,0/18,75), F2 (0,74%; 3,44%; 780 e 812
  passos; folgas 10,80–14,27 e 9,72–14,35), F3 completa (p 0–7 e elites), F4,
  F5 (40,62 px/20; 16,06/16; 4,59/11; v_sust 557,19; teto 610,56), F6 (25,10%,
  28,00%; +6,28/+7,00 e +18,72/+18,00), bordas do AV8 (13,69 e 51,72). Todas
  conferem com o GDD. A 1ª revisão independente (2026-11-10) refez as contas e
  corrigiu a geometria das AC-AR-21 e 35, o conjunto da AC-AR-24 e o AV4 (2
  períodos). A re-review (2026-11-10) refez tudo de novo por script, simulou a
  AC-AR-21 (passo 166, 10º acerto; 41 acertos e Vida 508 em 600 passos) e a
  AC-AR-35 (6 Especiais por arma com "passo vivo anterior"; o Especial guloso
  daria 7 e a Lâmina a −4,4%), e listou os 20 AV3 de fábrica (`p_max` 4).
- **(emenda Pactos)** +12 critérios (AC-AR-41 a 52): 8 [L] (41, 42, 44, 46–50),
  3 [I] (43, 45, 51; a 51 BLOQUEADA), 1 [M] (52). Total 52. Cobertura: R2b
  41–46, 51; F7 47; F3/F4/F5b 48; AV3 49; AV9 50; R6 52. Contas da F7 feitas à
  mão nesta emenda; o script da re-review precisa refazê-las antes da aprovação.
- **Ambiguidades:** nenhuma aberta. As 1 a 11 da proposta original foram
  resolvidas na 1ª revisão e na re-review (2026-11-10): o Saco parado do F1 na
  AC-AR-35 (o Saco móvel fica na AC-AR-21) e o roteiro "perfeito" com "passo
  vivo anterior" e oráculo discreto.

## Open Questions

| # | Pergunta | Dono | Resolver até |
|---|---|---|---|
| 1 | Guardião (fatia vertical): a guarda de 2 s contra a recarga de 1,33 s (AV1) e a trava do Golpe de Escudo (AV4; o CV18 do Combate precisa contar Ataques sempre pesados, n = 1, e a Vida da maior profundidade) | game-designer + dono do Combate | GDD de Armas da fatia vertical |
| 2 | ~~Nomes do Ataque e do Especial da Besta do Vínculo~~: resolvida, "Virote" / "Chamado do Pacto" aprovados no game-concept (§6, 2026-11-05) | — | — |
| 3 | ~~Números da Besta do Vínculo, com a Criatura do pacto~~: **resolvida (emenda Pactos, 2026-11-15)**: R2b com os números de `maldicoes.md` §Constantes; F7 confere a paridade | — | — |
| 4 | Emenda no Art Bible §5.8: quadros por golpe × entradas do combo da arma, e o Especial (hoje 8–12 quadros-chave por arma) contra o gesto de 1 quadro da Onda | art-director | antes de produzir as animações |
| 5 | Pontos frágeis de golpes até matar (Onda × Eco, Pulso × Anomalia, Corte × Fenda em p = 3): manter, ou subir um ponto de dano para estabilizar | `/balance-check` | depois do primeiro playtest |
| 6 | Combate: o CV18 deve olhar Ataques sempre pesados (n = 1) e a Vida da profundidade máxima da região (achado do systems-designer) | dono do Combate | próxima edição do Combate |
| 7 | Índice: linha 9 com "Tela de bênção e componente de carta (suave, por contrato)" e "Input e controle (suave)"; status "Designed" | usuário / producer | próxima edição do índice |
| 8 | Bênçãos: contra um alvo, uma bênção de Ataque vale ~3× a de Especial nas duas armas (F6: +18,7% contra +6,3%/+7,0% com +25%). Magnitudes diferentes por slot, ou valor do Especial em grupo, para a escolha não ser falsa (P1) | game-designer (GDD de Bênçãos) | GDD de Bênçãos |
| 9 | Conteúdo: regra de erro para propriedade desconhecida e para tipo errado no texto do `.tres` (o Godot ignora ou converte em silêncio); AC-AR-01 e AC-AR-30 são provisórias até lá | dono do Conteúdo | antes das epics de Armas |
| 10 | Modificadores: fixar a ordem de cálculo da fonte `profundidade` (um percentual 0,05 × p) para os meios exatos da F3 | dono do Modificadores | antes da AC-AR-18 |
| 11 | (emenda Pactos) Forma `chamado`: emenda no Combate (R3: teste de recusa antes do disparo; itens 1–3 não se aplicam; item 8 = pedido de salto) e no Conteúdo (enum de forma, AV9 como erro de carga) | donos do Combate e do Conteúdo | antes das epics de Pactos |
| 12 | (emenda Pactos) Besta sem Maldição pactuada: 40 DPS, TTK 17,5 s (67% fora da paridade). Garantir um pacto antes da 1ª run de Pactos (Vínculo e pactos), ou aceitar a desvantagem | usuário + Vínculo e pactos | GDD de Vínculo e pactos |
| 13 | (emenda Pactos) `dano_todo` e `dano_especial_pct` do dono no M da Maldição (Maldições OQ3): sem propagação, a paridade muda com bênção e a bênção de Especial é morta na Besta (AC-AR-51 bloqueada) | Maldições + Modificadores | antes da AC-AR-51 |
| 14 | (emenda Pactos) Bênção de Especial com a Besta vale +3,2% (+3,3% com os valores da emenda de 2026-11-15) do DPS composto com +25% (Lâmina 6,3%, Ressonância 7,0%); agrava a OQ 8 | GDD de Bênçãos / `/balance-check` | GDD de Bênçãos |
| 15 | (emenda Pactos) Silhueta, sprite, animação e som da Besta do Vínculo (Art Bible §5.4 não tem) | art-director + audio-director | antes dos assets de Pactos |
| 16 | ~~(emenda Pactos) Atração do Chamado (180 passos) maior que a recarga (120)~~: **fechada (emenda Pactos, 2026-11-15)**: Maldições R17/F4b põe a atração em `1,5 s` (90 passos) e o respiro em `0,5 s` (30); `90 + 30 = 120` = recarga do Chamado; teto `75%` do tempo e `1,5 s` seguidos (Edge Cases; F7 com os valores da emenda) | — | — |
| 11 | Registry: registrar as F1–F6 e as constantes (100/80, 387/378, Pulso 540, `ArmasTuning`) | producer | próxima passada do `/design-system` |
