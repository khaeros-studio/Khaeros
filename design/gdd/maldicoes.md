# Maldições (aliados do pacto)

> **Status**: Approved
> **Nota da emenda (2026-11-15, aprovada pelo usuário em 2026-11-16):** aceita ou resolve os contratos pedidos hoje por Armas (OQ16, M do Chamado), Combate (R1 item 6.1, R3.1, R20–R23), IA (R16–R18), HUD (R17–R19), Feedback (R15), Modificadores (R14, F6), Vínculo e pactos (V15, V43, F4), Input (R1a) e Chefes (R3). Mudanças de número: atração do Chamado `3,0 → 1,5 s` com respiro `0,5 s` (R17); técnica entra na paridade e os danos do kit caem (R18, F6, Catálogo). O conteúdo aprovado fica; o novo está marcado "(emenda Pactos, 2026-11-15)".
> **Author**: usuário + Claude (aba de Design)
> **Last Updated**: 2026-11-18 (consolidação de decisões aprovadas em 2026-11-16); 2026-11-16 (alinhamento: Abalo do *Eco de Muralha* `4,0 → 1,5 s`, ML1, AC-ML-36, OQ9); 2026-11-15 (emenda Pactos: Summary, R7, R13, R17–R24, Interactions, F3–F7, Constantes, Catálogo, ML1, ML7, ML8, Edge Cases, Dependencies, Visual/Audio, UI, ACs, Open Questions)
> **Last Verified**: 2026-11-15 (`/design-review` único por `qa-lead`: 2 bloqueantes formais e 4 recomendadas aplicados; **Approved** pelo usuário antes da emenda)
> **Implements Pillar**: P3 (combate legível), P1 (escolha com identidade)

## Summary

**Maldições (aliados do pacto)** define as criaturas autônomas que lutam ao lado do Iniciado da Doutrina de Pactos (`Besta do Vínculo`). O jogador leva até **duas Maldições** por expedição entre as espécies pactuadas: uma age em campo ligada pelo fio de vínculo (`480 px`) e a outra permanece na reserva regenerando Vida (`5%/s`), entrando pela **Troca** manual (`4,0 s` de recarga, disparando a **Técnica Combinada**: `Efeito de Saída` + `Efeito de Entrada` no mesmo passo) ou por troca automática quando a de campo fica **Exausta** (`Vida ≤ 0`, recuperando na reserva em `10,0 s` com `50%` da Vida). O Especial da Besta (**Chamado do Pacto**) faz a Maldição saltar até o ponto mirado (`420 px` em `12` passos), causar dano em área, imobilizar o inimigo comum mais próximo (`1,5 s`) e atrair inimigos (`3,0 s`). No MVP entram 3 espécies regulares em escada de raridade (*Vulto Mudo* Comum, *Espreitador da Fenda* Refinado e *Baluarte de Cinza* Raro) e 1 Primordial (*Soberano do Limiar*, forma aliada da Maldição-chefe), calibradas na divisão **~60% Besta (`40,0 DPS`) + ~40% Maldição (`26,5–26,9 DPS`)**, mantendo o TTK combinado em `10,47–10,53 s` (dentro de `0,8%` da Lâmina e da Ressonância).

> **(emenda Pactos, 2026-11-15)** A atração do Chamado passa a `1,5 s` (`90` passos) com respiro de `0,5 s` (`30` passos) sem renovar atração ativa: nenhum inimigo mira a Maldição mais de `1,5 s` seguidos nem mais de `75%` do tempo (R17, F4b). A técnica combinada entra na paridade (F6): o ataque básico cai para `18,0–18,36 DPS` e a técnica máxima para `14` de dano, e Pactos fica entre `−3,5%` (sem técnica, dupla de 1) e `+4,3%` (técnica a cada `4,0 s`, vínculo nível 5) da Lâmina e da Ressonância.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Combate núcleo, IA de inimigos e elites, Armas das Doutrinas, Modificadores e atributos`

## Overview

**Maldições** são as criaturas com que o Iniciado de Pactos tem vínculo. São
resíduos de Anomalia que aceitaram um pacto, da mesma natureza da Sombra Muda
de Serel. São a outra metade da arma da Doutrina: enquanto o jogador atira à
distância com a Besta do Vínculo, uma Maldição luta corpo a corpo ao lado dele.

O jogador leva **duas Maldições** por expedição, escolhidas entre as que já
pactuou. Uma fica em campo e a outra, na reserva, entra pela **troca** ou numa
**técnica combinada**. Em campo, a Maldição é **autônoma**: escolhe alvos, se
move e ataca por conta própria, porque o vínculo é consentido e não comandado.
O jogador age sobre ela só por **pedidos**: o Chamado do Pacto (o Especial da
Besta, que a faz avançar, segurar e atrair inimigos), a troca e a técnica
combinada.

Cada espécie tem uma **raridade** fixa (Comum, Refinado, Raro, Épico ou
Primordial), um kit próprio e uma história. O vínculo com cada uma cresce entre
runs (GDD de Vínculo e pactos).

Por baixo, a Maldição é um **portador** como os outros combatentes
(Modificadores R1). Ela é da facção do jogador: não é atingível pelos golpes
dele e não impede a câmara de ficar limpa. Seus golpes entram no impacto do
Combate como dano que não é de arma, por isso não contam acerto, não geram
Fluxo e não pedem hitstop.

**Fantasia:** nunca lutar sozinho. A Doutrina diz que o fardo nunca é carregado
por um só, e o jogador deve sentir que vence *com* a criatura, não *através*
dela.

**Sem este sistema,** Pactos seria só mais uma arma à distância. A Doutrina
perderia a identidade e o jogo perderia a escolha entre fazer pacto e derrotar.

## Detailed Design

### Core Rules

Decisões do usuário de 2026-11-15: inimigos miram o jogador salvo se atraídos;
Vida 0 = Exausta com troca automática; técnica combinada na troca; ação Troca
com recarga; alvo da Maldição segue o Virote; abates dela são do dono; raridade
= quantidade de habilidades; Chamado avança, imobiliza e atrai. Os valores
nomeados (`alcance_fio_px` etc.) estão na seção Formulas.

**R1. Facção.** A Maldição é um combatente da **facção do jogador**, ligado ao
`player_id` do dono, e é um **portador** (Modificadores R1). Ela **não** entra na
lista de inimigos nem na de atingíveis, e por isso:

- nada do jogador a fere: Virote, Selo, explosões, reflexo e status (sem fogo
  amigo);
- ela não conta na avaliação de câmara limpa;
- ela não bloqueia o jogador e não é bloqueada por inimigos;
- obstáculos e o retângulo da câmara a contêm, como aos inimigos (IA R9).

**R2. Dupla da expedição.** Antes da expedição o jogador escolhe 2 Maldições
entre as pactuadas (Vínculo e pactos). A primeira escolhida começa **em campo**
e a segunda fica na **reserva**. Com uma só pactuada não há reserva, troca nem
técnica. Com nenhuma, o Iniciado luta só com a Besta.
- **(emenda Pactos, 2026-11-15)** O caso "nenhuma pactuada" só existe com dublê
  (testes). No jogo, o Vínculo V3 concede o Vulto Mudo antes da 1ª expedição de
  Pactos, então a dupla tem sempre ao menos 1 Maldição.

**R3. Espécie e raridade.** Cada espécie tem raridade fixa e um kit:

| Raridade | Kit |
|---|---|
| Comum | ataque básico, um Efeito de Saída e um Efeito de Entrada (R12) |
| Refinado | + uma passiva |
| Raro | + um efeito próprio no Chamado |
| Épico | + uma segunda passiva |
| Primordial | + uma habilidade única (só a forma pactuada de uma Maldição-chefe) |

A raridade dá profundidade, não números maiores: as faixas de atributos são
próximas (Formulas). A tabela de raridade das Maldições é própria. A
`RarityTable` das bênçãos (Comum, Rara, Épica) não se aplica.

**R4. Alvo da Maldição.** A cada passo vivo, ela escolhe o primeiro destes que
existir:

1. a **marca do Virote**: o último inimigo que o Virote do dono acertou, se
   ainda é atingível e está dentro do fio (R5);
2. o inimigo atingível **mais perto do jogador**, dentro do fio;
3. nenhum, e ela volta para perto do jogador, a `distancia_seguir_px`.

Um Virote em outro inimigo move a marca. Em distâncias iguais vence o menor id.

**R5. Fio de vínculo.** Se a distância até o jogador passar de
`alcance_fio_px`, a Maldição larga o alvo e volta até ficar a
`distancia_seguir_px`. O fio é sempre visível (Art Bible §3.3).

**R6. Ataque e dano.**

- A Maldição ataca com o ataque básico da espécie, usando as formas do Combate
  (arco, círculo ou investida curta): preparo curto, execução e recuperação.
- Ela **não usa o telégrafo de chão**, que é reservado a perigo (Visual/Audio).
- Cada acerto chama o impacto do Combate (R8) com `de_arma` falso e o `pesado`
  do ataque: não conta acerto, não gera Fluxo, não aciona `golpe_*` e não pede
  hitstop.
- O acerto ainda pode causar empurrão, cambaleio e "Quebrou!", e usa o M do
  portador da Maldição (Modificadores F2).
- **Abates feitos por ela são do dono** (`autor_player_id`). Cura ao abater,
  explosão ao abater, contagem de abates e hitstop de abate seguem o Combate
  R14.

**R7. Inimigos atraídos.**

- Por padrão, todo inimigo mira o jogador.
- Um inimigo **atraído** (pelo Chamado ou por passiva) mira a Maldição em campo
  por `duracao_atracao_s`. A aproximação, a mira do telégrafo e o teste de
  acerto passam a usar a posição e o raio dela.
- **Um golpe de inimigo só testa o seu alvo.** Um telégrafo mirado no jogador
  não fere a Maldição, e um mirado nela não fere o jogador. Com projéteis vale o
  mesmo.
- Se a Maldição sai de campo, a atração termina na hora e o inimigo volta a
  mirar o jogador.
- **(emenda Pactos, 2026-11-15)** A atração não se renova enquanto está ativa e
  tem respiro depois de acabar (R17). Vale também para o chefe: cada golpe dele
  testa só o alvo travado (Chefes R3 emendado), o que confirma a regra acima.
  Puxão e onda de choque do chefe (Chefes R5 Padrão 3, R7) não são golpes: movem
  o jogador e a Maldição sem dano e não contradizem esta regra.

**R8. Vida e dano recebido.**

- A Vida é inteira e o dano recebido segue a F3 do Modificadores, como a do
  jogador.
- Ela não tem invulnerabilidade após o golpe e não pede hitstop de atingido,
  para o mundo não congelar.
- O golpe recebido tem só feedback visual (Visual/Audio). No MVP ela não recebe
  status, como o jogador.

**R9. Exaustão.** Com Vida ≤ 0, a Maldição em campo fica **Exausta**:

1. recua pelo fio e sai de campo, e as atrações terminam;
2. se a reserva está **Pronta**, ela entra na hora: é a **troca automática**,
   que não gasta a recarga e não dispara técnica;
3. a Exausta vai para a reserva e, depois de `recuperacao_exausta_s` de passos
   vivos, volta Pronta com `vida_retorno_frac` × `vida_max`.

Com as duas Exaustas, o jogador luta sozinho até uma voltar, e ela entra em
campo sozinha.

**R10. Reserva.** A Maldição na reserva não age e não é atingível. Ao entrar na
reserva em `Pronta`, seu acumulador fracionário de cura (`acum_regen`) inicia
em `0` e ela recupera `regen_reserva_frac_s` × `vida_max` por segundo de passo
vivo, até o máximo.

**R11. Troca.** Com a ação nova **Troca** (emenda no Input), ela acontece
quando: há Maldição em campo, a reserva está Pronta, a recarga da troca é 0 e o
passo é vivo.

- A de campo vai para a reserva e a reserva entra ao lado do jogador.
- A recarga passa a `recarga_troca_s`.
- Sem as condições, o toque é recusado, emite o evento lógico
  `troca_indisponivel` e é sinalizado (UI Requirements).

**R12. Técnica combinada.**

- Toda **troca manual** dispara a técnica: a que sai executa o seu **Efeito de
  Saída** onde está, e a que entra executa o seu **Efeito de Entrada** ao
  chegar, no mesmo passo e nessa ordem.
- A técnica é a combinação das duas partes, por isso 3 espécies dão 6
  combinações ordenadas sem escrever cada par.
- O Efeito de Entrada pode ler o que a Saída deixou. Exemplo: Saída "paredes de
  sombra" prende inimigos; Entrada "salto à distância" causa dano extra a
  inimigos presos. O resultado é a emboscada.

**R13. Chamado do Pacto** (Especial da Besta; a recarga é do GDD de Armas).

1. A Maldição em campo salta em linha reta até o ponto mirado, limitado a
   `alcance_chamado_px` do jogador. O salto leva `passos_salto`, atravessa
   inimigos e para em obstáculo.
2. Ao chegar, faz um golpe de área de raio `raio_chamado_px`: dano do Chamado,
   com `de_arma` falso.
3. O inimigo comum mais perto do centro fica **imobilizado** por
   `duracao_imobilizar_s`: não anda e não começa preparo. Um preparo ou execução
   em curso não é cancelado. Elites e chefes não são imobilizados, por causa da
   armadura do Combate R8.
4. Todo inimigo dentro de `raio_atracao_px` fica **atraído** (R7), incluindo
   elites e chefes.
5. Espécies Raras ou acima acrescentam o seu efeito próprio.

Sem Maldição em campo, o Chamado é recusado e a recarga não é gasta.

**(emenda Pactos, 2026-11-15)** Quem recusa e emite `chamado_indisponivel` é o
Combate (R3.1), consultando `pode_chamar` (R22). O dano do pouso usa o
`M_chamado` que o Combate envia (o M do jogador no grupo Especial, Combate
R3.1), não o M do portador da Maldição. A atração do item 4 dura
`duracao_atracao_s` (agora `1,5 s`) e segue a R17.

**R14. Câmaras.**

- Na troca de câmara, a Maldição em campo é teleportada para junto do jogador.
- Atração, imobilização e marca terminam.
- Vida, estados (Pronta ou Exausta) e recargas continuam como estavam.
- Ao fim da run nada passa adiante, exceto o vínculo (Vínculo e pactos).
- **(emenda Pactos, 2026-11-15)** O teleporte é o pedido
  `reposicionar_maldicao(pos)`, chamado pelo Câmaras na troca de câmara com o
  ponto da F6 dele: `pos = (960 ; min(930 + distancia_seguir_px, 1080 − raio_px))`
  = `(960 ; min(1035, 1080 − raio))`. Com os raios do MVP (`22,5–30 px`) dá
  sempre `(960, 1035)`. No mesmo passo: estado `Seguindo`, `estourou_fio`
  falso, alvo e marca limpos (`marca_virote_mudou` vazio), atração e
  imobilização encerradas (com respiro, R17) e a IA avisada (R21). Só a Maldição
  em campo é reposicionada; a reserva não tem posição. A coordenada
  `(960, 930)` da Edge Case de câmara limpa é a do jogador, não a da Maldição.

**R15. Congelamentos.** Hitstop, pausa e transição congelam as Maldições como o
resto do mundo. A morte do jogador encerra a run, e as Maldições não mudam esse
desfecho.

**R16. Maldição-chefe.** A espécie Primordial do MVP aparece primeiro como chefe
(GDD de Chefes, com a sua forma de inimigo). O pacto ou a derrota é decidido no
GDD de Vínculo e pactos. Pactuada, ela usa a forma aliada deste GDD, e a forma
de chefe não passa para o aliado.

#### Regras novas (emenda Pactos, 2026-11-15)

**R17. Atração limitada** (resolve a OQ16 de Armas). A
atração antiga (`180` passos) passava da recarga do Chamado (`120`) e podia
virar permanente. Agora:

1. `duracao_atracao_s` cai de `3,0 s` para **`1,5 s`** (`90` passos), menor que
   a recarga do Chamado (Armas, `120` passos).
2. **Sem renovação:** um pedido de atração a um inimigo já atraído é recusado.
   Não soma e não estende (troca o `max` da IA R17; contrato pedido à IA).
3. **Respiro:** quando a atração de um inimigo acaba, por qualquer motivo (fim
   do tempo, saída de campo, `TransicaoFase` do chefe), ele fica
   `respiro_atracao_s` (**`0,5 s`**, `30` passos vivos) recusando atração.
4. Nenhuma fonte de atração passa de `duracao_atracao_s` (ML1). *Queda de
   Pilar* fica em `90` passos; *Pulso de Soberania* passa de "renova `1,0 s`"
   para "**aplica** `1,0 s` (`60` passos) a quem está livre".
5. Prova na F4b: no máximo `1,5 s` seguidos e `75%` do tempo mirando a Maldição.

**R18. Técnica na paridade.** A técnica combinada passa a
contar na F6 com troca manual a cada `recarga_troca_s`. Para caber em `±5%` da
Lâmina e da Ressonância, o ataque básico das 4 espécies cai `10%` e os Efeitos
de Saída e Entrada caem para `5` e `6–7` de dano (Catálogo). A recarga da troca
(`4,0 s`) não muda.

**R19. Interface de leitura `estado_pacto(player_id)`** (contrato do HUD R19).
Devolve, sem efeito colateral:

- `campo`, `reserva`: vazio ou `{especie_id, vida, vida_max, estado,
  restante_exausta, total_exausta}`;
- `estado` ∈ {`Ativa`, `Saltando`, `Pronta`, `Exausta`}. `Ativa` junta Seguindo,
  Perseguindo, Preparo, Execução e Recuperação;
- `total_exausta`: os passos de Exaustão **da fonte**, fixados no passo em que
  ela ficou Exausta (`600`; *Soberano* `480`; com vínculo nível ≥ 3, `540` e
  `432`, Vínculo F4). `0` fora de Exausta;
- `recarga_troca_passos` (restante) e `recarga_troca_total`
  (`passos(recarga_troca_s)` = `240`);
- `troca_disponivel`: as condições da R11 sem a de passo vivo (há campo, campo
  não Saltando, reserva Pronta, recarga 0). Assim o HUD lê o mesmo valor na
  pausa.

**R20. Eventos emitidos** (contratos do HUD R18–R19 e do Feedback R15). Um por
fato, no passo em que acontece, nunca em passo congelado:

| Evento | Payload | Quando |
|---|---|---|
| `troca_feita` | `player_id`, `tipo` ∈ {`manual`, `automatica`}, `saiu_id`, `entrou_id` | troca manual (R11) ou automática (R9.2) |
| `troca_indisponivel` | `player_id`, `motivo` ∈ {`recarga`, `sem_reserva`, `reserva_exausta`, `saltando`, `sem_campo`} | toque novo recusado (R11) |
| `tecnica_combinada` | `player_id`, `saida_id`, `entrada_id`, `acertos` | troca manual, depois das duas partes (R12) |
| `maldicao_entrou` | `curse_id`, `origem` ∈ {`automatica`, `retorno`, `inicio`} | entrada sem técnica (R9, campo vazio) |
| `maldicao_pronta` | `curse_id` | fim da Exaustão na reserva (R9.3) |
| `maldicao_golpe` | `curse_id`, forma | execução do ataque básico (R6) |
| `chamado_salto`, `chamado_pouso` | `curse_id`, origem, destino | início e pouso do salto (R13) |
| `marca_virote_mudou` | `player_id`, `inimigo_id` ou vazio | a marca muda, some com a morte do alvo ou na troca de câmara (R4, R14) |
| `atraido` / `atracao_fim` | `inimigo_id`, `passos` / `inimigo_id` | pedido aceito pela IA / fim detectado (abaixo) |
| `imobilizado` / `imobilizacao_fim` | `inimigo_id`, `passos` / `inimigo_id` | pedido aceito pela IA / fim detectado |
| `fio_estourou` | `curse_id` | `estourou_fio` passa de falso a verdadeiro (F1) |

- `chamado_indisponivel` **não** é emitido aqui: o Combate já o emite na R3.1.
  Um emissor só, para o som não sair duas vezes.
- `maldicao_atingida` e `maldicao_exausta` são do Combate (R21).
- **Fins de atração e imobilização:** a IA desconta os dois no item 7. As
  Maldições guardam os ids que atraíram ou imobilizaram e, no início do 6.1,
  emitem o fim dos que a IA dá como livres (`esta_atraido`, `esta_imobilizado`,
  IA R18). O fim chega com `1` passo de atraso, dentro do `≤ 1` passo do
  Feedback. Na saída de campo, `atracao_fim` sai no mesmo passo.

**R21. Contratos com a IA** (IA R15–R17).

- **`fator_andar_atraido`:** a Maldição em campo expõe o valor a cada passo:
  `1,0` por padrão, `0,80` com o *Soberano* (*Presença do Limiar*). A IA lê,
  não guarda.
- **Saída de campo avisada no mesmo passo:** `maldicao_saiu_de_campo(player_id)`
  é chamada de forma síncrona na troca manual (6.1), dentro de `exaurir`
  (itens 7 e 8, Combate R21) e na troca de câmara. Os inimigos que ainda vão
  rodar no item 7 daquele passo já miram o jogador.
- **Pedido de atração:** `atrair(id, passos, passos_respiro)`. A Maldição envia
  os dois números convertidos; a IA continua sem número próprio.

**R22. Contratos com o Combate** (Combate R3.1, R20–R23).

- `pode_chamar(player_id)`: há Maldição em campo e ela não está `Saltando`.
- `pedir_chamado(player_id, ponto_mirado, dano_golpe, M_chamado)`: chega no
  item 5 e é executado no 6.1 do mesmo passo (passo 3 da ordem abaixo).
- `maldicao_atingivel(curse_id)`: em campo, `Vida > 0` e não `Saltando`
  (salto imune, Edge Cases).
- **Passivas condicionais por código** (Modificadores R14, fonte
  `especie:<curse_id>:<passiva>`): *Faro do Vínculo* aplica `velocidade +15%`
  no passo em que o alvo é a `marca_virote` e o estado é Perseguindo, e remove
  no passo em que isso deixa de valer (inclui troca, Exaustão e câmara).
  *Presença do Limiar* não é atributo do portador: é o `fator_andar_atraido`.
  *Carapaça Ancorada* é fixa e vai na fonte `especie` do começo da run.

**R23. Ordem dentro do item 6.1** (Combate R1 item 6.1, R23).
Só em passo vivo:

1. Fins de atração e imobilização do passo anterior (R20).
2. Contadores: `recarga_troca` −1, `restante_exausta` −1 (a que zera fica
   Pronta), regeneração da reserva (F2).
3. Campo vazio e uma Pronta: ela entra sem técnica (`maldicao_entrou`).
4. Chamado pedido no item 5: começa o salto (`Saltando`, `chamado_salto`).
5. Troca manual do buffer: testa a R11 (recusada se o passo 4 começou o
   salto). Aceita: Saída, abates da Saída, Entrada, `troca_feita`,
   `tecnica_combinada`, aviso à IA.
6. Salto em curso: avança; no passo de pouso, golpe, imobilização e atração
   (R13).
7. Fio (F1), alvo (R4), passivas condicionais (R22) e movimento.
8. Ataque básico (fases; o impacto vai pela R20 do Combate).

A troca automática não está aqui: ela acontece dentro de `exaurir` (itens 7 e
8), e a que entra só age no 6.1 seguinte (Combate R23).

**R24. Dupla, vínculo e bênçãos durante a run** (Vínculo V15, V43;
Modificadores R14, F6).

- **A dupla pode crescer no meio da run.** Com dupla de 1, um pacto feito na
  run entra como **reserva** `Pronta`, com `Vida = min(Vida_acuada, vida_max)`
  e `acum_regen = 0`. O portador dela nasce nesse passo, já com os espelhos dos
  modificadores atuais do jogador (contrato pedido a Modificadores R14). Daí em
  diante troca e técnica existem. Se a de campo estiver Exausta, a nova entra
  em campo no 6.1 seguinte (R23 passo 3). Com a dupla cheia, nada muda na run.
- **Vínculo nas fórmulas:** a F2 usa `recuperacao_exausta_s × mult_recuperacao`
  (nível ≥ 3) e a F3 usa `dano_basico × (1 + bonus_dano_basico)` (nível ≥ 4),
  com os valores do Vínculo F4. A Vida extra vem da fonte `vinculo` do
  Modificadores. O vínculo não toca técnica, Chamado nem recarga da troca
  (Vínculo V19).
- **Propagação de bênçãos (resposta à OQ3):** `dano_todo_pct` e
  `velocidade_pct` do jogador ganham espelho em cada portador da dupla
  (Modificadores R14, F6, `fator_propagacao_maldicao = 1,0`). Assim
  `M_maldicao` e `valor(velocidade)` acompanham o jogador e a F1 continua
  provada. Os outros tipos não propagam. O Chamado já recebe as bênçãos de
  Especial pelo `M_chamado` (R13 emenda).

### States and Transitions

| Estado | Onde | Entra quando | Sai quando |
|---|---|---|---|
| Seguindo | campo | sem alvo (R4.3), ou fio estourado (R5) | um alvo surge e está no fio (após `d_jog ≤ distancia_seguir_px` se entrou por R5) |
| Perseguindo | campo | tem alvo | alcança o alvo (Preparo), perde o alvo ou estoura o fio |
| Preparo, Execução, Recuperação | campo | ciclo do ataque básico (R6) | o ciclo acaba e ela volta a Perseguindo ou Seguindo |
| Saltando | campo | Chamado (R13) | chega ao ponto mirado e aplica o golpe |
| Pronta | reserva | troca para a reserva, ou fim da recuperação | entra em campo (troca manual ou automática) |
| Exausta | reserva | Vida ≤ 0 em campo (R9) | `recuperacao_exausta_s` acaba e ela fica Pronta |

Troca, Exaustão e troca de câmara interrompem qualquer estado de campo, menos
Saltando. Durante o salto a troca é recusada.

### Interactions with Other Systems

| Sistema | Entra na Maldição | Sai da Maldição | Dono do contrato |
|---|---|---|---|
| Combate núcleo | consulta de atingíveis e impacto R8 | pedidos de impacto (`de_arma` falso), abates com autor = dono, `ferir_maldicao` (novo) | Combate (emenda) |
| IA de inimigos e elites | lista e posição dos inimigos | consulta "alvo do inimigo" (jogador ou Maldição) e pedido ~~`atrair(id, passos)`~~ `atrair(id, passos, passos_respiro)` (emenda Pactos, 2026-11-15) | IA (emenda) |
| Armas das Doutrinas | o Chamado como Especial, o evento de acerto do Virote (marca) | salto e golpe do Chamado | Armas (emenda da Besta) |
| Input e controle | ação nova Troca | — | Input (emenda) |
| Modificadores | portador com atributos | M do atacante, `dano_recebido` | Modificadores |
| Câmaras e ondas | troca de câmara, posição de entrada | não conta em câmara limpa | Câmaras (emenda) |
| Telégrafos | mira travada para o alvo do inimigo (R7) | — | Telégrafos (emenda) |
| HUD e Feedback | — | Vida em campo e na reserva, recarga da troca, estados | HUD e Feedback (emenda) |
| Vínculo e pactos | espécies pactuadas, dupla e vínculo | uso da Maldição para crescer o vínculo | Vínculo e pactos |
| Chefes | forma de chefe da espécie Primordial | — | Chefes |

**Provisório:** a ação Troca no Input, `ferir_maldicao` no Combate, `atrair` e o
alvo por inimigo na IA, a mira pelo alvo nos Telégrafos e a regra de câmara
limpa em Câmaras são hipóteses deste GDD. Viram emendas nos GDDs donos depois
da aprovação.

**(emenda Pactos, 2026-11-15)** Os donos já escreveram as emendas. Contratos
aceitos aqui: Combate (`pode_chamar`, `pedir_chamado`, `maldicao_atingivel`,
item 6.1; R22, R23), IA (`fator_andar_atraido`, saída de campo síncrona,
`atrair` com respiro; R17, R21), HUD (`estado_pacto()`, `troca_feita`; R19,
R20), Feedback (eventos da R20), Modificadores (espelhos e passivas por código;
R22, R24), Vínculo (dupla que cresce, F2/F3 com vínculo; R24), Input (Troca em
R/Tab e LT), Chefes (golpe testa só o alvo travado; R7).

## Formulas

> Proposta conjunta do `systems-designer` e do `game-designer` (2026-11-15). Convenções: `passos(t)` é a F7 do Conteúdo (`duration_to_steps`, `TICK_RATE = 60`, empate `x,5` para longe do zero); distâncias em px de mundo (`unit_to_px = 1,5`); velocidades em px/s; multiplicador de dano `M` pela F2 do Modificadores (`hit_damage_multiplier`, teto `4,0`) avaliado no portador da Maldição; dano recebido inteiro pela F3 do Modificadores (`damage_taken`). Golpes de Maldição chamam `ferir_inimigo` com `de_arma = false` (hitstop = 0, Fluxo = 0, sem contador de acertos da arma; Combate R8/R10).

### F1. Geometria do fio de vínculo, escolha de alvo e retorno (`curse_follow_and_tether`)

The curse_follow_and_tether formula is defined as:

`d_jog = ||pos_maldicao − pos_jogador||` ;
`estourou_fio = (d_jog > alcance_fio_px) ∨ (estourou_fio_ant ∧ d_jog > distancia_seguir_px)` ;
`candidatos = { e ∈ inimigos_atingiveis : ||pos(e) − pos_jogador|| ≤ alcance_fio_px }` ;
`alvo = marca_virote` se (`¬estourou_fio` e `marca_virote ∈ candidatos`) ;
senão `arg min_{e ∈ candidatos} (||pos(e) − pos_jogador||, e.id)` se (`¬estourou_fio` e `candidatos ≠ ∅`) ;
senão `nenhum` (estado `Seguindo`, move até `d_jog ≤ distancia_seguir_px` com passo `min(max(0, d_jog − distancia_seguir_px), valor(velocidade) / 60)`)

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| `pos_maldicao`, `pos_jogador` | Vector2 | dentro da câmara (`1920×1080`) | runtime | posição atual da Maldição em campo e do dono |
| `d_jog` | float | `[0, 2203]` px | calculated | distância euclidiana entre a Maldição e o jogador |
| `alcance_fio_px` | float | `360–660` (MVP `480`) | data file | `MaldicoesTuning.alcance_fio_px`: raio máximo do fio a partir do jogador (R5) |
| `distancia_seguir_px` | float | `75–150` (MVP `105`) | data file | `MaldicoesTuning.distancia_seguir_px`: distância de repouso ao lado do jogador (R4.3, R5) |
| `marca_virote` | int / null | id de inimigo ou vazio | runtime | último inimigo atingido pelo Virote do dono (R4.1) |
| `valor(velocidade)` | float | `300–550` px/s | calculated | F1 do Modificadores (`derived_value`) no portador da Maldição |
| `estourou_fio` | bool | `true` / `false` | calculated | se verdadeiro, limpa o alvo atual e força o estado `Seguindo` até `d_jog ≤ distancia_seguir_px` |

**Output Range:** `d_jog ≥ 0`. `distancia_seguir_px < alcance_fio_px` é garantido por validação (ML1), criando uma banda de histerese de `480 − 105 = 375 px` que impede oscilação entre `Perseguindo` e `Seguindo` na borda do fio. Quando `d_jog == 0`, a direção de retorno usa `(1, 0)`.

**Example:** *Vulto Mudo* (`velocidade = 405 px/s`, `6,75 px/passo`) persegue um inimigo e o jogador esquiva na direção oposta, levando `d_jog` a `493,5 px > 480 px`. No mesmo passo vivo, `estourou_fio = true`: a Maldição larga o alvo, entra em `Seguindo` e percorre `493,5 − 105 = 388,5 px` de volta ao jogador em `ceil(388,5 / 6,75) = 58` passos vivos (`0,967 s`), parando a `105 px`.

---

### F2. Retorno de Exaustão e regeneração na reserva (`curse_recovery_and_reserve_regen`)

The curse_recovery_and_reserve_regen formula is defined as:

Em `Exausta` (a cada passo vivo): `restante_exausta' = max(0, restante_exausta − 1)` ;
quando `restante_exausta'` chega a `0`, passa a `Pronta` com:
`Vida_retorno = clamp(round(valor(vida_max) × vida_retorno_frac), 1, valor(vida_max))` e `acum_regen = 0` ;
Em `Pronta` na reserva (a cada passo vivo, com `Vida < valor(vida_max)`):
`acum_regen' = acum_regen + (valor(vida_max) × regen_reserva_frac_s) / 60` ;
`ganho = floor(acum_regen')` ; `Vida' = min(valor(vida_max), Vida + ganho)` ; `acum_regen'' = (Vida' ≥ valor(vida_max)) ? 0 : (acum_regen' − ganho)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| `valor(vida_max)` | int | `60–200` (MVP `95–135`) | calculated | Vida máxima derivada do portador da Maldição (`CurseDef.vida_max` via Modificadores F1) |
| `recuperacao_exausta_s` | float | `6,0–16,0` s (MVP `10,0` s = `600` passos) | data file | `MaldicoesTuning.recuperacao_exausta_s`: tempo em passos vivos para sair de `Exausta` (R9.3) |
| `vida_retorno_frac` | float | `0,25–0,75` (MVP `0,50`) | data file | `MaldicoesTuning.vida_retorno_frac`: fração da Vida máxima ao voltar de `Exausta` (R9.3) |
| `regen_reserva_frac_s` | float | `0,02–0,10` /s (MVP `0,05` /s) | data file | `MaldicoesTuning.regen_reserva_frac_s`: fração de `vida_max` curada por segundo na reserva (R10) |
| `acum_regen` | float | `[0, 1)` | runtime | acumulador fracionário de cura na reserva (mantém Vida inteira, R8) |
| `Vida_retorno`, `Vida'` | int | `[1, valor(vida_max)]` | calculated | Vida inteira da Maldição após retorno ou passo de regeneração |

**Output Range:** `Vida` inteira em `[1, valor(vida_max)]` quando `Pronta` e `0` quando `Exausta`. Tempo para curar da metade ao topo na reserva: `(1 − 0,50) / 0,05 = 10,0 s` (`600` passos vivos).

**Example:** *Baluarte de Cinza* (`vida_max = 135`) chega a `Vida ≤ 0` em campo: fica `Exausta` por `600` passos vivos (`10,0 s`) e volta `Pronta` com `Vida_retorno = round(135 × 0,50) = 68`. Na reserva, soma `(135 × 0,05) / 60 = 0,1125` Vida/passo vivo, atingindo `135/135` em `ceil((135 − 68) / 0,1125) = 596` passos vivos (`9,93 s`).

---

### F3. Ciclo do ataque básico e DPS autônomo (`curse_basic_attack_dps`)

The curse_basic_attack_dps formula is defined as:

`P = passos(preparo_s)` ; `E = passos(execucao_s)` ; `R = passos(recuperacao_s)` ;
`C_atk = P + E + R` ;
`dano_golpe = (dano_basico + dano_extra_ciclo) × M_maldicao` ;
`DPS_autonomo = (dano_golpe × 60) / C_atk`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| `preparo_s`, `execucao_s`, `recuperacao_s` | float | `> 0` (`P, E, R ≥ 1`) | data file | durações das 3 fases do ataque básico da espécie (`CurseDef`, R6) |
| `C_atk` | int | `15–60` passos (MVP `25–42`) | calculated | duração total do ciclo em passos vivos (`0,417–0,70 s`) |
| `dano_basico` | float | `5–25` (MVP `8,5–14`) | data file | dano base do ataque básico da espécie (`CurseDef`) |
| `dano_extra_ciclo` | float | `≥ 0` (MVP `0` ou `1,0`) | calculated | dano médio por ciclo de habilidade única (*Soberano do Limiar*: `+3` a cada 3 ataques = `+1,0`/ciclo) |
| `M_maldicao` | float | `[0, 4,0]` (`1,0` sem bênção) | calculated | F2 do Modificadores no portador da Maldição |
| `DPS_autonomo` | float | `≥ 0` (MVP `20,0–20,4` com `M = 1`) | calculated | Vida/s causada pela Maldição em combate contínuo (`DPS_vivo = DPS_real`, pois `de_arma = false` não gera hitstop) |

**Output Range:** `DPS_autonomo > 0`, limitado por `4,0 × DPS_base`.

**Example (`M_maldicao = 1`):**
- *Vulto Mudo* (Comum): `8 + 6 + 16 = 30` passos (`0,50 s`), `dano = 10` → **`20,00 DPS`**
- *Espreitador da Fenda* (Refinado): `6 + 5 + 14 = 25` passos (`0,417 s`), `dano = 8,5` → **`20,40 DPS`**
- *Baluarte de Cinza* (Raro): `12 + 8 + 22 = 42` passos (`0,70 s`), `dano = 14` (`pesado = true`) → **`20,00 DPS`**
- *Soberano do Limiar* (Primordial): `9 + 6 + 21 = 36` passos (`0,60 s`), `dano = 11` (`+1,0`/ciclo do 3º golpe) → **`20,00 DPS`**

**(emenda Pactos, 2026-11-15) Valores novos (R18), `M = 1`:** ciclos iguais, `dano_basico` `−10%`. Faixa MVP de `DPS_autonomo` passa a `18,00–18,36`; `dano_basico` MVP `7,65–12,6`.
- *Vulto Mudo*: `9 × 60 / 30` = **`18,00 DPS`**
- *Espreitador da Fenda*: `7,65 × 60 / 25` = **`18,36 DPS`**
- *Baluarte de Cinza*: `12,6 × 60 / 42` = **`18,00 DPS`**
- *Soberano do Limiar*: `(9,8 + 1,0) × 60 / 36` = **`18,00 DPS`**
- Com vínculo nível ≥ 4 (R24): `dano_basico × 1,05` → *Espreitador* `8,0325 × 2,4 = 19,28 DPS`; *Vulto*/*Baluarte* `18,90`; *Soberano* `(10,29 + 1) × 60 / 36 = 18,82`. ML5: `19,28 / 18,00 = 1,071 ≤ 1,15` ✓.

---

### F4. Cinemática e impacto do Chamado do Pacto (`curse_pact_call_leap`)

The curse_pact_call_leap formula is defined as:

`u = pos_mirada − pos_jogador` ;
`P_alvo = pos_jogador + (u / ||u||) × min(||u||, alcance_chamado_px)` (se `||u|| == 0`, usa `mira × alcance_chamado_px`) ;
`N_salto = passos(duracao_salto_s)` ;
`passo_salto_px = (P_alvo − pos_inicial_maldicao) / N_salto` (para no primeiro contato com obstáculo ou parede) ;
Ao pousar (passo `s + N_salto`):
`dano_pouse = dano_chamado × M_maldicao` em todo inimigo atingível com `dist ≤ raio_chamado_px + r_inimigo` ;
`passos_imob = passos(duracao_imobilizar_s)` (no comum atingido em `raio_chamado_px + r_inimigo` mais próximo do centro) ;
`passos_atracao = passos(duracao_atracao_s)` (em todo inimigo atingível com `dist ≤ raio_atracao_px + r_inimigo`)

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| `alcance_chamado_px` | float | `240–480` (MVP `420`) | data file | `MaldicoesTuning.alcance_chamado_px`: distância máxima do ponto mirado ao jogador (R13.1; `≤ alcance_fio_px`) |
| `N_salto` (`passos_salto`) | int | `6–18` (MVP `12` = `0,20 s`) | data file | `passos(MaldicoesTuning.duracao_salto_s)`: duração do salto (R13.1) |
| `raio_chamado_px` | float | `90–195` (MVP `135`) | data file | `MaldicoesTuning.raio_chamado_px`: raio do golpe ao pousar (R13.2) |
| `raio_atracao_px` | float | `135–300` (MVP `210`) | data file | `MaldicoesTuning.raio_atracao_px`: raio da atração em área (R13.4; `≥ raio_chamado_px`) |
| `dano_chamado` | float | `10–35` (MVP `17`) | data file | `AttackDef.dano` do Especial da Besta do Vínculo (`Chamado do Pacto`) |
| `duracao_imobilizar_s` | float | `0,75–2,5` s (MVP `1,5` s = `90` passos) | data file | `MaldicoesTuning.duracao_imobilizar_s`: imobilização do comum mais próximo (R13.3) |
| `duracao_atracao_s` | float | `1,5–5,0` s (MVP `3,0` s = `180` passos) | data file | `MaldicoesTuning.duracao_atracao_s`: duração da atração nos inimigos no raio (R7, R13.4) |

**Output Range:** `||P_alvo − pos_jogador|| ∈ [0, alcance_chamado_px]`. Como `alcance_chamado_px (420) ≤ alcance_fio_px (480)` (ML1), o pouso nunca estoura o fio.

**Example:** Jogador em `(500, 500)` mira em `(1000, 500)` → `P_alvo = (920, 500)`. A Maldição em `(440, 500)` salta `480 px` em `12` passos (`40 px/passo`), causa `17` de dano em `135 px`, imobiliza o comum mais próximo por `90` passos (`1,5 s`) e atrai todos até `210 px + r_inimigo` por `180` passos (`3,0 s`).

**(emenda Pactos, 2026-11-15)** `dano_pouse = dano_chamado × M_chamado` (M do jogador no grupo Especial, Combate R3.1), no lugar de `× M_maldicao`. `duracao_atracao_s` MVP passa a **`1,5 s` (`90` passos)**, faixa de design `0,75–1,5 s`. No exemplo, a atração dura `90` passos.

#### F4b. Teto da atração (`curse_attraction_duty`) (emenda Pactos, 2026-11-15)

`L_max = max(passos(duracao_atracao_s), passos de qualquer fonte de atração)` (ML1 garante `L_max = passos(duracao_atracao_s)`) ;
`R_resp = passos(respiro_atracao_s)` ;
`contínuo_max = L_max` ; `f_atracao_max = L_max / (L_max + R_resp)`

| Variável | Tipo | Faixa | Fonte | Descrição |
|---|---|---|---|---|
| `L_max` | int | `45–90` (MVP `90`) | calculado | maior atração que um pedido aceito pode dar |
| `respiro_atracao_s` | float | `0,25–1,0` s (MVP `0,5` s = `30` passos) | `MaldicoesTuning` | tempo em que o inimigo recusa atração depois que ela acaba (R17) |
| `f_atracao_max` | float | `(0, 1)` | calculado | fração máxima do tempo em que um inimigo mira a Maldição |

**Prova.** Pela R17, um pedido só é aceito com o inimigo livre (sem atração e
sem respiro). Cada episódio de atração vem de **um** pedido e dura no máximo
`L_max`. Todo fim abre `R_resp ≥ 1` passos de recusa (ML1). Logo cada trecho
ligado tem `≤ L_max` e é seguido de `≥ R_resp` desligado:
`f_atracao_max = 90 / (90 + 30) = 0,75` e no máximo `1,5 s` seguidos, com
qualquer mistura de Chamado, *Queda de Pilar* e *Pulso de Soberania*. Só com o
Chamado a cada recarga (`120` passos): `90` ligado e `30` livre, exatamente o
teto. Antes da emenda (`180` passos com `max`) o Chamado a cada `120` passos
renovava antes do fim e a atração era permanente.

**Exemplo:** Chamado em `t = 0` atrai o Eco por `90` passos (até `t = 89`);
respiro de `t = 90` a `119`; *Pulso de Soberania* em `t = 100` é recusado; o
Chamado em `t = 120` atrai de novo por `90`.

---

### F5. Dano da Técnica Combinada e sinergia de emboscada (`curse_combined_technique_damage`)

The curse_combined_technique_damage formula is defined as:

Na **troca manual** (mesmo passo vivo, ordem R12: 1º Saída da que sai `S`, 2º Entrada da que entra `E`):
`D_saida(alvo) = dano_saida(S) × M_S` ;
`sinergia_ativa(alvo) = (alvo está preso/imobilizado OU marcado pela Saída OU atraído OU Abalado no instante da Entrada)` ;
`mult_sinergia(alvo) = 1 + (sinergia_ativa(alvo) ? bonus_sinergia_pct(E) : 0)` ;
`D_entrada(alvo) = dano_entrada(E) × mult_sinergia(alvo) × M_E` ;
`D_tecnica(alvo) = D_saida(alvo) + D_entrada(alvo)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| `dano_saida(S)` | float | `5–20` (MVP `8–10`) | data file | dano base do Efeito de Saída da espécie `S` (`CurseDef.efeito_saida`) |
| `dano_entrada(E)` | float | `6–20` (MVP `10–12`) | data file | dano base do Efeito de Entrada da espécie `E` (`CurseDef.efeito_entrada`) |
| `bonus_sinergia_pct(E)` | float | `0–1,0` (MVP `0` ou `0,50`) | data file | bônus percentual da Entrada contra alvo controlado/atraído/Abalado (`CurseDef.efeito_entrada`) |
| `M_S`, `M_E` | float | `[0, 4,0]` (`1,0` sem bênção) | calculated | multiplicador F2 do Modificadores nos portadores de `S` e `E` |
| `D_tecnica(alvo)` | float | `≥ 0` | calculated | dano total da Técnica Combinada num alvo atingido pelas duas partes |

**Output Range:** `D_tecnica ≥ 0`. Como `S` executa antes de `E` no mesmo passo vivo (R12), o controle deixado por `S` já é lido por `E`.

**Example (Emboscada da R12):** *Vulto Mudo* (`S`) sai executando *Paredes de Sombra* (`D_saida = 8`, imobiliza por `90` passos). No mesmo passo, *Espreitador da Fenda* (`E`) entra com *Salto de Emboscada* (`dano_entrada = 12`, `bonus_sinergia_pct = 0,50`): lê `sinergia_ativa = true` e causa `D_entrada = 12 × 1,5 = 18` → `D_tecnica = 8 + 18 = 26` de dano imediato.

**(emenda Pactos, 2026-11-15) Valores novos (R18):** `dano_saida` MVP `5` (todas); `dano_entrada` MVP `6` (com sinergia `+0,50`) ou `7` (sem sinergia). `D_tecnica_max = 5 + 6 × 1,5 = 14` (Saída que controla + Entrada com sinergia). No exemplo: `D_saida = 5`, `D_entrada = 6 × 1,5 = 9` → **`D_tecnica = 14`**. Pares sem sinergia: `5 + 7 = 12`.

---

### F6. DPS combinado da Doutrina de Pactos e paridade de TTK (`pact_doctrine_combined_ttk`)

The pact_doctrine_combined_ttk formula is defined as:

No ciclo do Especial da Besta do Vínculo (`R_esp = passos(recarga_chamado_s)` passos vivos):
`DPS_besta = (dano_virote × 60 / R_virote) × M_jogador` ;
`f_campo_atk = (R_esp − N_salto) / R_esp` ;
`DPS_maldicao_chamado = f_campo_atk × DPS_autonomo + (dano_chamado × 60 / R_esp) × M_maldicao` ;
`DPS_pactos_real = DPS_besta + DPS_maldicao_chamado` ;
`f_besta = DPS_besta / DPS_pactos_real` ; `f_maldicao = DPS_maldicao_chamado / DPS_pactos_real` ;
`TTK_pactos = Vida_chefe / DPS_pactos_real` ;
`paridade_max = max_{a, b ∈ {lamina, ressonancia, pactos}} |TTK_a − TTK_b| / min(TTK_a, TTK_b) ≤ meta_paridade (0,15)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| `dano_virote`, `R_virote` | float, int | `10`; `15` passos (`0,25 s`) | data file / calculated | Ataque `Virote` da Besta do Vínculo (`WeaponDef pactos`) |
| `dano_chamado`, `R_esp` | float, int | `17`; `120` passos (`2,0 s`) | data file / calculated | Especial `Chamado do Pacto` da Besta do Vínculo |
| `N_salto` | int | `12` passos (`0,20 s`) | data file | passos do salto do Chamado em que a Maldição não faz ataque básico |
| `DPS_autonomo` | float | `20,0–20,4` DPS | calculated | F3 da Maldição em campo (`M = 1`) |
| `DPS_besta` | float | `40,00` DPS (`M = 1`) | calculated | DPS real do jogador com o Virote (~60% do total) |
| `DPS_maldicao_chamado` | float | `26,50–26,86` DPS (`M = 1`) | calculated | DPS real da Maldição em campo + Chamado (~40% do total) |
| `Vida_chefe` | int | `700` | data file | Vida de referência para paridade (Armas R6, F2) |
| `TTK_pactos` | float | `10,47–10,53` s | calculated | tempo real para causar `700` de dano no modelo combinado |

**Output Range:** `f_besta ∈ [0,50 ; 0,70]` (meta: ~60% Besta / ~40% Maldição, validada por ML7) e `paridade_max ≤ 0,15` (ML8).

**Example (`M = 1`, alvo de `700 HP`):**
| Doutrina / Arma | Parcela da Arma | Parcela da Maldição | `DPS_comb_real` | `TTK_chefe` (700 HP) | Diferença p/ o menor TTK |
|---|---|---|---|---|---|
| **Lâmina do Juramento** (Armas F1/F2) | `66,47 DPS` (100%) | — | **66,47 DPS** | **10,53 s** | `0,77%` |
| **Foco Ressonante** (Armas F1/F2) | `66,96 DPS` (100%) | — | **66,96 DPS** | **10,45 s** | `0,00%` |
| **Besta + Vulto / Baluarte / Soberano** | `40,00 DPS` (**60,2%**) | `26,50 DPS` (**39,8%**) | **66,50 DPS** | **10,53 s** | `0,73%` |
| **Besta + Espreitador da Fenda** | `40,00 DPS` (**59,8%**) | `26,86 DPS` (**40,2%**) | **66,86 DPS** | **10,47 s** | `0,15%` |

#### F6 com a técnica (emenda Pactos, 2026-11-15)

A F6 antiga não contava a técnica. Com troca a cada `4,0 s`, Pactos ficava
`11,1%` acima da Lâmina, e `12,49%` no vínculo nível 5 (Vínculo F4). Agora:

`DPS_tecnica = D_tecnica_max(S, E) / recarga_troca_s` (teto: troca manual a cada recarga, as duas partes acertam, sinergia ativa) ;
`DPS_pactos_piso = DPS_besta + DPS_maldicao_chamado` (dupla de 1, sem técnica, vínculo nível 1) ;
`DPS_pactos_teto = DPS_besta + DPS_maldicao_chamado(vínculo nível 5) + DPS_tecnica` ;
`DPS_maldicao_chamado = f_campo_atk × DPS_autonomo + (dano_chamado × 60 / R_esp) × M_chamado` ;
`paridade_pactos = max sobre {piso, teto} e ref ∈ {lamina, ressonancia} de |TTK_x − TTK_ref| / min(TTK_x, TTK_ref) ≤ meta_paridade_pactos (0,05)`

| Variável | Tipo | Faixa | Fonte | Descrição |
|---|---|---|---|---|
| `D_tecnica_max` | float | `≥ 0` (MVP `14`) | F5 | maior dano da técnica num alvo |
| `recarga_troca_s` | float | `4,0 s` | `MaldicoesTuning` | frequência máxima da troca manual |
| `DPS_tecnica` | float | MVP `3,50` | calculado | teto da técnica por segundo |
| `meta_paridade_pactos` | float | `0,03–0,15` (MVP `0,05`) | `MaldicoesTuning` | meta da Doutrina, mais justa que o `0,15` do Armas AV2 |

Referências: Lâmina `66,47 DPS` (`10,531 s`), Ressonância `66,96 DPS`
(`10,454 s`). Faixa permitida a `±5%`: `63,77–69,79 DPS`.

| Caso (`M = 1`, 700 HP) | Besta | Maldição + Chamado | Técnica | Total | TTK | Paridade (pior ref) | `f_besta` |
|---|---|---|---|---|---|---|---|
| Piso: *Vulto* / *Baluarte* / *Soberano*, dupla de 1 | `40,00` | `0,9 × 18,00 + 8,5 = 24,70` | `0` | **`64,70`** | `10,819 s` | **`3,49%`** (Ressonância) | `0,618` |
| Piso: *Espreitador*, dupla de 1 | `40,00` | `25,02` | `0` | `65,02` | `10,765 s` | `2,98%` | `0,615` |
| Teto base: *Espreitador* + técnica | `40,00` | `25,02` | `3,50` | `68,52` | `10,215 s` | `3,09%` (Lâmina) | `0,584` |
| Teto nível 5: *Espreitador* + técnica | `40,00` | `0,9 × 19,28 + 8,5 = 25,85` | `3,50` | **`69,35`** | `10,094 s` | **`4,33%`** (Lâmina) | `0,577` |

Pior caso **`4,33% ≤ 5%`** (margem `0,67` ponto) e piso **`3,49%`**. A divisão
fica em `57,7–61,8%` Besta, dentro do ML7. O tempo Exausto (Besta só, `40 DPS`)
fica fora do modelo, como antes.

---

### F7. Golpes até Exaustão e cobertura da dupla (`curse_survivability_and_exhaustion`)

The curse_survivability_and_exhaustion formula is defined as:

`dano_in = max(1, round(dano_inimigo × (elite ? 1,25 : 1) × (1 − min(0,60, max(0, reducao_maldicao)))))` ;
`g_exausta = ceil(valor(vida_max) / dano_in)` ;
`t_campo_min_s = g_exausta × (ciclo_min_inimigo / 60)` ;
`janela_descoberta_s = max(0, recuperacao_exausta_s − t_sobrevivencia_reserva_s)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| `valor(vida_max)` | int | `95–135` (MVP) | calculated | Vida máxima da Maldição |
| `reducao_maldicao` | float | `0–0,60` (`0,15` no *Baluarte*, `0` nas demais) | calculated | atributo `reducao_dano` do portador da Maldição |
| `dano_in` | int | `≥ 1` (`7–16` no Limiar) | calculated | dano inteiro por golpe sofrido pela Maldição (R8) |
| `g_exausta` | int | `≥ 1` (`11–17` vs Eco comum) | calculated | golpes até a Maldição entrar em `Exausta` (R9) |
| `recuperacao_exausta_s` | float | `10,0 s` (`8,0 s` no *Soberano*) | data file | tempo para a 1ª Exausta voltar `Pronta` na reserva |

**Output Range:** `g_exausta ≥ 1`.

**Example:** Contra o **Eco Perdido** (`dano = 9`, ciclo mínimo `1,60 s`): *Espreitador* (`95 HP`) suporta `11` golpes (`17,6 s`); *Vulto* (`110 HP`) suporta `13` golpes (`20,8 s`); *Baluarte* (`135 HP`, redução `0,15`, `dano_in = 8`) suporta `17` golpes (`27,2 s` contra 1 Eco; `13,6 s > 10,0 s` contra 2 Ecos, mantendo `janela_descoberta_s = 0`).

**(emenda Pactos, 2026-11-15) Exposição com atração limitada (F4b):** um inimigo atraído mira a Maldição no máximo `75%` do tempo, então `t_campo_min_atraidos_s = g_exausta × (ciclo_min_inimigo / 60) / (N_atraidos × f_atracao_max)`. *Baluarte* contra 2 Ecos sempre re-atraídos: `17 × 1,60 / (2 × 0,75) = 18,1 s` (antes `13,6 s`). *Espreitador* contra 2 Ecos: `11 × 1,60 / 1,5 = 11,7 s > 10,0 s`, `janela_descoberta_s = 0`. A atração deixa de ser permanente sem tornar a Maldição frágil.

---

### Constantes de sistema (`MaldicoesTuning`) e Catálogo das 4 Espécies (`CurseDef`)

#### 1. `MaldicoesTuning` (`assets/data/tuning/maldicoes_tuning.tres`)

| Campo | Tipo | Valor MVP | V2 (erro de carga) | Faixa de design (aviso ML6) | Papel |
|---|---|---|---|---|---|
| `alcance_fio_px` | float | **480 px** | `180–960` e `> distancia_seguir_px` | `360–660` | Raio máximo do fio a partir do jogador (R5) |
| `distancia_seguir_px` | float | **105 px** | `45–240` e `< alcance_fio_px` | `75–150` | Distância de retorno ao jogador (R4.3, R5) |
| `alcance_chamado_px` | float | **420 px** | `120–960` e `≤ alcance_fio_px` | `240–480` | Alcance máximo do salto do Chamado (R13.1) |
| `duracao_salto_s` | float | **0,20 s** (`12` passos) | `> 0` (`≥ 1` passo) | `0,10–0,30` (`6–18` passos) | Duração do salto do Chamado (`passos_salto`, R13.1) |
| `raio_chamado_px` | float | **135 px** | `> 0` | `90–195` | Raio de dano e imobilização no pouso do Chamado (R13.2, R13.3) |
| `raio_atracao_px` | float | **210 px** | `> 0` e `≥ raio_chamado_px` | `135–300` | Raio da atração do Chamado (R13.4) |
| `duracao_imobilizar_s` | float | **1,50 s** (`90` passos) | `> 0` (`≥ 1` passo) | `0,75–2,50` (`45–150` passos) | Imobilização do comum mais próximo no Chamado (R13.3) |
| `duracao_atracao_s` | float | **3,00 s** (`180` passos) | `> 0` (`≥ 1` passo) | `1,50–5,00` (`90–300` passos) | Tempo em que inimigos atraídos miram a Maldição (R7) |
| `recarga_troca_s` | float | **4,00 s** (`240` passos) | `> 0` (`≥ 1` passo) | `2,00–8,00` (`120–480` passos) | Recarga da ação `Troca` manual (R11) |
| `recuperacao_exausta_s` | float | **10,00 s** (`600` passos) | `> 0` (`≥ 1` passo) | `6,00–16,00` (`360–960` passos) | Tempo em passos vivos para sair de `Exausta` (R9.3) |
| `vida_retorno_frac` | float | **0,50** | `(0, 1]` | `0,25–0,75` | Fração de `vida_max` ao voltar de `Exausta` (R9.3) |
| `regen_reserva_frac_s` | float | **0,05 /s** | `≥ 0` | `0,02–0,10 /s` | Fração de `vida_max` curada por segundo em `Pronta` na reserva (R10) |

- **(emenda Pactos, 2026-11-15) Mudanças e campos novos em `MaldicoesTuning`:**

| Campo | Tipo | Valor MVP | V2 (erro de carga) | Faixa de design (aviso ML6) | Papel |
|---|---|---|---|---|---|
| `duracao_atracao_s` | float | ~~3,00 s~~ → **1,50 s** (`90` passos) | `≥ 1` passo e ML1 | `0,75–1,50` (`45–90` passos) | Atração do Chamado e teto de toda fonte (R17, F4b) |
| `respiro_atracao_s` (novo) | float | **0,50 s** (`30` passos) | `≥ 1` passo | `0,25–1,00` (`15–60` passos) | Recusa de atração depois que ela acaba (R17) |
| `meta_paridade_pactos` (novo) | float | **0,05** | `> 0` | `0,03–0,15` | Meta de paridade com técnica (F6, ML8) |

- **Referência da Besta do Vínculo (`WeaponDef pactos`, emenda no GDD de Armas):** `vida_max = 90`, `velocidade = 382,5 px/s`; Ataque `Virote` (`projetil`, `dano = 10`, `recarga_s = 0,25` / `15` passos, `velocidade_pxs = 1170`, `raio_px = 12`, `vida_s = 0,75`, `empurrao = 360 px/s`, `40,00 DPS`); Especial `Chamado do Pacto` (`dano = 17`, `recarga_s = 2,00` / `120` passos).

#### 2. Catálogo das 4 Espécies do MVP (`CurseDef` em `assets/data/curses/<id>.tres`)

| Campo / Kit | 1. **Vulto Mudo** (`vulto_mudo`) | 2. **Espreitador da Fenda** (`espreitador_da_fenda`) | 3. **Baluarte de Cinza** (`baluarte_de_cinza`) | 4. **Soberano do Limiar** (`soberano_do_limiar`) |
|---|---|---|---|---|
| **Raridade (R3)** | `comum` (regular) | `refinado` (regular) | `raro` (regular) | `primordial` (forma aliada da Maldição-chefe, R16) |
| **Papel e silhueta (§3.3)** | Controle de sombra / parede (quadrúpede esguio em Tinta com dorso lacrado em Osso) | Emboscador ágil de alvo marcado (crescente agachado com talas e lâminas de Osso) | Guardião pesado / quebra-preparo (trapézio largo sobre antebraços pétreos com correias de Osso) | Regente híbrido (1,25× do Iniciado, coroa de cristais selada por anéis de Osso e meias-correntes) |
| `vida_max` / `velocidade` / `raio_px` | `110` / `405 px/s` / `24 px` | `95` / `435 px/s` / `22,5 px` | `135` / `360 px/s` / `30 px` | `120` / `390 px/s` / `28,5 px` |
| **Ataque básico** | *Gume de Penumbra*: `arco` (`105 px`, `60°`), dano **`10`**, emp. `360`, `P/E/R = 8/6/16` (`30` passos, **`20,00 DPS`**) | *Bote Estilhaçado*: `arco` (`112,5 px`, `55°`), dano **`8,5`**, emp. `300`, `P/E/R = 6/5/14` (`25` passos, **`20,40 DPS`**) | *Quebra-Limiar*: `circulo` (`96 px`, desl. `24 px`), dano **`14`**, emp. `900` (`pesado = true`), `P/E/R = 12/8/22` (`42` passos, **`20,00 DPS`**) | *Garra do Véu Rasgado*: `arco` (`120 px`, `65°`), dano **`11`**, emp. `540`, `P/E/R = 9/6/21` (`36` passos, **`20,00 DPS`** c/ hab. única) |
| **Efeito de Saída (R12)** | *Paredes de Sombra*: `circulo` `150 px`, dano **`8`**; **imobiliza** comuns (e marca elites/chefes) por `1,5 s` (`90` passos) | *Rastro Cortante*: `circulo` `120 px`, dano **`9`**, emp. `360 px/s`, aplica **Abalo** (`4,0 s`) | *Cratera de Cinza*: `circulo` `150 px`, dano **`10`**, emp. `720 px/s` e aplica **Abalo** (`4,0 s`) | *Fenda Retida*: `circulo` `150 px`, dano **`9`**; **imobiliza** comuns (e marca elites/chefes) por `1,5 s` (`90` passos) |
| **Efeito de Entrada (R12)** | *Passo Raso*: `circulo` `120 px` ao lado do jogador, dano **`10`**, emp. `450 px/s` (`bonus_sinergia_pct = 0`) | *Salto de Emboscada*: `avanco` até `240 px` (`120 px`), dano **`12`**, **`bonus_sinergia_pct = +0,50`** (`18` de dano vs alvo preso/atraído/Abalado) | *Queda de Pilar*: `circulo` `135 px` ao lado do jogador, dano **`11`**, emp. `630 px/s`; **atrai** atingidos por `1,5 s` (`90` passos) | *Irrupção Primordial*: `avanco` até `240 px` (`120 px`), dano **`11`**, **`bonus_sinergia_pct = +0,50`** (`16,5` de dano vs alvo preso/atraído/Abalado) |
| **Passiva 1 (Refinado+)** | — | *Faro do Vínculo*: `+15%` de `velocidade` ao perseguir o inimigo com a **marca do Virote** (R4.1) | *Carapaça Ancorada*: recebe `reducao_dano = 0,15` (`−15%` de dano recebido) | *Presença do Limiar*: inimigos **atraídos** por ele têm velocidade de andar `× 0,80` (`−20%`) |
| **Efeito no Chamado (Raro+)** | — | — | *Eco de Muralha*: aplica **Abalo** (`4,0 s`) nos atingidos em `raio_chamado_px` (`135 px`) | *Convergência*: puxa inimigos comuns em `raio_atracao_px` (`210 px`) em `60 px` para o centro do pouso |
| **Passiva 2 (Épico+)** | — | — | — | *Vínculo Inquebrável*: tempo de `Exausta` reduzido em `20%` (`8,0 s` = `480` passos) |
| **Habilidade única (Primordial)** | — | — | — | *Pulso de Soberania*: a cada **3º ataque básico concluído**, emite um anel de `135 px` com **`3`** de dano extra (`pesado = true`, emp. `900 px/s`) e renova `1,0 s` de atração |

**Catálogo — valores da emenda Pactos (2026-11-15), R17/R18.** A tabela acima fica como registro do aprovado; valem estes:

| Campo | *Vulto Mudo* | *Espreitador da Fenda* | *Baluarte de Cinza* | *Soberano do Limiar* |
|---|---|---|---|---|
| Ataque básico: dano (DPS) | ~~10~~ → **`9`** (`18,00`) | ~~8,5~~ → **`7,65`** (`18,36`) | ~~14~~ → **`12,6`** (`18,00`) | ~~11~~ → **`9,8`** + `1,0`/ciclo (`18,00`) |
| Efeito de Saída: dano | ~~8~~ → **`5`** | ~~9~~ → **`5`** | ~~10~~ → **`5`** | ~~9~~ → **`5`** |
| Efeito de Entrada: dano | *Passo Raso* ~~10~~ → **`7`** | *Salto de Emboscada* ~~12~~ → **`6`** (`9` com sinergia) | *Queda de Pilar* ~~11~~ → **`7`** (atrai `90` passos, R17) | *Irrupção Primordial* ~~11~~ → **`6`** (`9` com sinergia) |
| Habilidade única | — | — | — | *Pulso de Soberania*: ~~renova~~ **aplica** `1,0 s` (`60` passos) de atração só a inimigo livre (R17); `+3` mantido |
| Efeito no Chamado (alinhamento 2026-11-16) | — | — | *Eco de Muralha*: Abalo ~~`4,0 s`~~ → **`1,5 s`** (`90` passos), campo `duracao_abalo_s` do efeito no `CurseDef`; vale também em elite e chefe | — |

Vida, velocidade, raio, ciclos, passivas, empurrões e efeitos de controle não mudam,
salvo a duração do Abalo do *Eco de Muralha* acima.

**Por que `1,5 s` no Eco de Muralha** (fecha a OQ8 de `efeitos-de-status.md`). Com
`4,0 s` de Abalo e o Chamado a cada `recarga_chamado_s` (`2,0 s` = `120` passos), um
alvo no raio do pouso ficava abalado 100% do tempo, chefe incluído. É a menor mudança
que tira o Abalo permanente sem criar imunidade (o cânone não dá imunidade a chefe,
Status Edge Cases) e sem mexer no Abalo das Saídas:

`cobertura_eco = min(1, passos(duracao_abalo_eco_s) / passos(recarga_chamado_s))`

| Variável | Tipo | Faixa | Descrição |
|---|---|---|---|
| `duracao_abalo_eco_s` | float | `0,5–1,9 s` (faixa de design) | duração do Abalo do *Eco de Muralha* (`CurseDef`) |
| `recarga_chamado_s` | float | `2,0 s` (`120` passos, §Constantes) | recarga do Chamado do Pacto |
| `cobertura_eco` | float | `0,25–0,95`; `1,0` só com duração `≥` recarga (erro ML1) | fração máxima do tempo em que um alvo fica abalado só pelo Eco |

Saída limitada a `[0, 1]` pelo `min`. Máximo `1,0` quando a duração alcança a recarga,
o que o ML1 recusa. Ex.: `90 / 120 = 0,75`. Redução média de dano do alvo no teto,
com Chamado em toda recarga e sempre acertando: `0,30 × 0,75 = 22,5%` (antes: `30%`
constante). Com `1,0 s`: `0,50` e `15%`.

- A cobertura por Trocas (Espreitador + Baluarte, uma Saída com Abalo de `4,0 s` a cada
  `recarga_troca_s` = `4,0 s`) **não muda**: ela pede uma Troca manual exata a cada
  `240` passos e o alvo dentro do círculo da Saída. Aceita como domínio de execução
  (a validar no playtest).

#### 3. Validações de dados (`ML1`–`ML8` no Conteúdo orientado a dados)

| Código | Nível | Condição | O que protege |
|---|---|---|---|
| **ML1** | **erro** | `distancia_seguir_px ≥ alcance_fio_px`, `alcance_chamado_px > alcance_fio_px` ou `raio_atracao_px < raio_chamado_px` | Impede histerese invertida do fio (F1), pouso do Chamado já estourando o fio (F4) e golpe fora do raio de atração (R13) |
| **ML2** | **erro** | Qualquer duração convertida por `passos(...) < 1`, `vida_max < 20` ou `vida_retorno_frac ∉ (0, 1]` | Impede divisão por zero em F3/F4 e estados de 0 passos ou retorno com 0 de Vida em F2 |
| **ML3** | **erro** | `CurseDef` com contagem de peças do kit incompatível com a sua `raridade` (R3) | Garante a regra estrutural da R3 (*raridade = quantidade de habilidades do kit*) |
| **ML4** | **erro** | `CurseDef` com `raridade == primordial` sem `chefe_origem_id` válido ou duplicado | Garante a R3 e a R16 (toda Primordial é exclusivamente a forma pactuada de uma Maldição-chefe) |
| **ML5** | **aviso** | `max(vida_max) / min(vida_max) > 1,50` ou `max(DPS_autonomo) / min(DPS_autonomo) > 1,15` | Protege a R3 (*"A raridade dá profundidade, não números maiores"*) |
| **ML6** | **aviso** | Qualquer campo de `MaldicoesTuning` ou `CurseDef` fora da faixa de design | Alerta quando um número sai do espaço onde as contas de F1–F7 foram provadas |
| **ML7** | **aviso** (2ª passada) | Na F6, `f_besta ∉ [0,50 ; 0,70]` com a Besta do Vínculo | Garante a divisão ~60% Besta / ~40% Maldição |
| **ML8** | **aviso** (2ª passada) | Na F6, diferença relativa de `TTK_pactos` para `TTK_lamina` ou `TTK_ressonancia` `> 0,15` | Estende o AV2 de Armas à Doutrina de Pactos |

**(emenda Pactos, 2026-11-15)**
- **ML1** ganha duas condições (erro): `passos(duracao_atracao_s) + passos(respiro_atracao_s) > passos(recarga_chamado_s)` (`90 + 30 = 120 ≤ 120` ✓), e qualquer atração de `CurseDef` (*Queda de Pilar*, *Pulso de Soberania*) com mais passos que `duracao_atracao_s`. Protege a F4b.
- **ML1** (alinhamento 2026-11-16) ganha mais uma condição (erro): `passos(duracao_abalo_s do Eco de Muralha) ≥ passos(recarga_chamado_s)` (`90 < 120` ✓). Impede o Abalo permanente pelo Chamado.
- **ML7** passa a checar `f_besta ∈ [0,50 ; 0,70]` no piso e no teto da F6 com técnica (`0,577–0,618` ✓).
- **ML8** passa a checar o piso (dupla de 1, nível 1) e o teto (técnica a cada `recarga_troca_s`, vínculo nível 5) contra `meta_paridade_pactos` (`0,05`). O `0,15` do Armas AV2 segue como limite externo. Valores: piso `3,49%`, teto `4,33%`, `0` avisos.

## Edge Cases

> `systems-designer` não consultado separadamente nesta seção — modo Lean (`2026-11-15`, regras derivadas de R1–R16 e F1–F7).

- **Se o jogador iniciar a expedição com apenas 1 Maldição pactuada (R2):** não há reserva; a ação `Troca` é sempre recusada sem gastar recarga (`troca_indisponivel`); se a única Maldição ficar `Exausta`, o jogador luta sozinho pelos `600` passos vivos (`10,0 s`) de `recuperacao_exausta_s` e ela reentra automaticamente em campo com `Vida_retorno` sem disparar Efeito de Entrada.
- **Se as duas Maldições da dupla estiverem `Exaustas` ao mesmo tempo (R9):** ambas descontam seus contadores `restante_exausta` em paralelo a cada passo vivo; a primeira que atingir `0` passa a `Pronta` e entra imediatamente em campo (em empate no mesmo passo vivo, entra a que ficou `Exausta` primeiro), sem gastar `recarga_troca_s` e sem disparar Técnica Combinada.
- **Se o jogador acionar `Troca` ou `Chamado do Pacto` enquanto a Maldição está `Saltando` (R13, States):** o pedido é recusado e não gasta recarga; uma Maldição em salto é imune a dano e empurrão até o passo de pouso (`s + N_salto`), evitando que fique `Exausta` no ar antes de aplicar o impacto do Chamado.
- **Se o caminho do salto do `Chamado do Pacto` ou do `Efeito de Entrada` em avanço encontrar um obstáculo ou parede antes de `P_alvo` (R13.1, F4):** o deslocamento para no último ponto válido encostado no obstáculo/parede e o impacto de pouso (`raio_chamado_px`, imobilização e atração) é aplicado imediatamente naquele ponto e passo.
- **Se a Maldição sair de campo (por `Troca`, `Exaustão` ou troca de câmara) no meio do preparo ou execução de um inimigo atraído (R7):** a atração encerra na hora; um telégrafo inimigo que já havia travado a mira continua na posição/direção travada (Telégrafos R2), mas no passo de impacto testa o seu alvo original (se o alvo era a Maldição que saiu, o golpe falha no vazio e não fere o jogador, R7).
- **Se o Efeito de Saída matar um inimigo no passo da `Troca` manual (R12, F5):** o abate é processado antes do Efeito de Entrada no mesmo passo vivo; se o Efeito de Entrada for um avanço na direção da `marca_virote` e o inimigo marcado tiver morrido na Saída, a Entrada usa o próximo candidato da F1 (inimigo atingível mais perto do jogador dentro do fio, ou a direção da mira do jogador se não houver nenhum).
- **Se a câmara ficar limpa enquanto a Maldição está em `Preparo`, `Execução` ou `Saltando` (R1, R14):** os inimigos já morreram; a Maldição conclui ou interrompe a ação sem efeito hostil e passa a `Seguindo`. Ao atravessar a porta, é reposicionada a `distancia_seguir_px` atrás do jogador na entrada da nova câmara (`(960, 930)` px).
- **Se o jogador morrer no mesmo passo vivo em que a Maldição abate o último inimigo da câmara (R15, Combate R16):** a morte do jogador vence; a run encerra em derrota e `camara_limpa` é ignorada.

**(emenda Pactos, 2026-11-15)**
- **Se o Chamado cair a cada recarga sobre o mesmo grupo (R17, F4b):** cada inimigo fica `90` passos atraído e `30` em respiro, mirando o jogador. O jogador ganha `0,5 s` de pressão a cada ciclo; a Maldição nunca segura um grupo para sempre.
- **Se uma atração chegar a um inimigo atraído ou em respiro (R17):** o pedido é recusado e não sai `atraido`. O dano e o empurrão da mesma fonte valem normalmente.
- **Se a Maldição sair de campo com inimigos atraídos (R7, R21):** a IA zera a atração e abre o respiro no mesmo passo. A que entra (troca automática ou manual) não consegue atrair esses inimigos por `30` passos. A Entrada da técnica (*Queda de Pilar*) é recusada neles nesse passo; isso é aceito.
- **Se o chefe entrar em `TransicaoFase` (Chefes R7):** o zerar da atração abre o respiro; um Chamado depois do respiro atrai normalmente.
- **Se o pacto do meio da run acontecer com a única Maldição Exausta (R24, Vínculo V15):** a nova entra na reserva Pronta e, como o campo está vazio, entra em campo no passo 3 do 6.1 seguinte, com `maldicao_entrou(retorno)` e sem técnica. A Exausta continua contando e volta para a reserva.
- **Se a técnica acertar só com a Saída (F5, F6):** o dano real fica abaixo de `D_tecnica_max`; a F6 usa o teto e por isso é conservadora.
- **Se `Troca` e `Chamado` chegarem no mesmo passo (R23):** o Chamado começa o salto no passo 4 e a Troca é recusada no passo 5 (`troca_indisponivel`, motivo `saltando`), como já era durante o salto.
- **Se `estado_pacto()` for lido na pausa ou na Transição (R19):** devolve o estado congelado; `troca_disponivel` não depende do passo vivo, então o Selo da Troca não pisca ao pausar.
- **Se a marca do Virote morrer (R4, R20):** `marca_virote_mudou` sai com `inimigo_id` vazio no passo da varredura de mortes seguinte; *Faro do Vínculo* é removido no passo 7 do 6.1.

## Dependencies

### Depends On (Upstream)
- **Combate núcleo (`Forte`, por contrato):** fornece a resolução de impacto (`ferir_inimigo` com `de_arma = false` e `autor_player_id`), formas de golpe (`arco`, `circulo`, `avanco`), empurrão, cambaleio, `"Quebrou!"` e o pedido `ferir_maldicao` (sem invulnerabilidade pós-dano e sem hitstop).
- **IA de inimigos e elites (`Forte`, por contrato):** fornece a lista de inimigos atingíveis e consome o alvo por inimigo (jogador por padrão; Maldição em campo enquanto `atraído` por `R7`) e o estado `imobilizado` (`R13.3`).
- **Armas das Doutrinas (`Forte`):** fornece a `WeaponDef pactos` (*Besta do Vínculo*), o evento de acerto do `Virote` (que atualiza `marca_virote`, `R4.1`) e o disparo do Especial `Chamado do Pacto` (`R13`).
- **Modificadores e atributos (`Forte`):** monta os portadores das duas Maldições da dupla e calcula `valor(vida_max)`, `valor(velocidade)`, `M` (`F2`) e `dano_recebido` (`F3`).
- **Conteúdo orientado a dados (`Forte`):** carrega e valida `MaldicoesTuning` e os `CurseDef` (`V1–V11` + `ML1–ML8`).
- **Input e controle (`Forte`, emenda):** expõe a ação `Troca` no passo de física (buffer de 10 passos congelado no hitstop, como Esquiva/Selo).
- **Movimento e esquiva (`Suave`):** fornece a posição do jogador e o contrato de colisão contra obstáculos e paredes da câmara.
- **Telégrafos (`Suave`, por contrato):** trava a mira do telégrafo inimigo na posição da Maldição quando o inimigo inicia o preparo atraído (`R7`).
- **Vínculo e pactos (`Forte`, por contrato):** informa quais espécies estão pactuadas e qual dupla (campo + reserva) o jogador escolheu para a expedição (`R2`).

### Depended On By (Downstream)
- **Chefes (`Forte`):** a Maldição-chefe do Limiar usa a forma de inimigo em `Chefes` e desbloqueia a espécie Primordial `soberano_do_limiar` deste GDD (`R16`).
- **Vínculo e pactos (`Forte`):** lê o catálogo `CurseDef`, as raridades (`R3`) e os eventos de uso/abate para progredir o nível de vínculo entre runs.
- **Câmaras e ondas (`Suave`, por contrato):** reposiciona a Maldição na troca de câmara (`R14`) e a ignora na contagem de inimigos vivos (`R1`).
- **HUD e Feedback de combate (`Suave`, por contrato):** leem Vida, estado (`Pronta` / `Exausta` / progresso de retorno) e recarga da `Troca` para exibição na tela e VFX do fio/troca.

### Emenda Pactos (2026-11-15) — contratos aceitos e pedidos
- **Combate núcleo:** aceita `pode_chamar`, `pedir_chamado(player_id, ponto_mirado, dano_golpe, M_chamado)`, `maldicao_atingivel` e o item 6.1 (R13, R22, R23). `chamado_indisponivel` fica com o Combate (R3.1).
- **IA de inimigos e elites:** aceita `fator_andar_atraido` e a saída de campo síncrona (R21). **Contrato pedido à IA R17:** recusar `atrair` com o inimigo atraído ou em respiro (troca o `max`) e receber `passos_respiro`. **Contrato pedido à IA R16:** abrir o respiro ao zerar a atração e tirar a exceção "padrões de área do chefe testam o jogador e a Maldição", superada pelo Chefes R3.
- **HUD:** aceita `estado_pacto()` com `troca_disponivel` e `total_exausta`, e `troca_feita(manual|automatica)` (R19, R20).
- **Feedback de combate:** aceita os eventos da R20. **Contrato pedido ao Feedback R15:** ganchos com prefixo `sfx_` (ML-A1) e `chamado_indisponivel` com emissor Combate.
- **Modificadores e atributos:** aceita espelhos de `dano_todo_pct` e `velocidade_pct` e a fonte `especie:<curse_id>:<passiva>` por código (R22, R24). **Contrato pedido à R14:** o portador também nasce no meio da run, quando a dupla cresce (R24).
- **Vínculo e pactos:** aceita V15 e V43 (R24). **Contrato pedido à F4:** refazer as tabelas com os valores novos (`DPS_autonomo 18,00–18,36`, `D_tecnica_max = 14`); o teto com técnica passa a `4,33%`.
- **Armas das Doutrinas:** fecha a OQ16 pela R17 e a Edge Case da atração renovada. **Contrato pedido à F7 e ao AV2:** recalcular a parcela da Maldição (`24,70–25,85 DPS`) e citar a F6 com técnica.
- **Input e controle:** aceita a Troca em R / Tab e LT (Input R1a).
- **Chefes:** aceita "cada golpe testa só o alvo travado" (Chefes R3; R7 coerente) e a resposta à OQ2.
- **Câmaras e ondas:** aceita `reposicionar_maldicao(pos)` com o ponto da F6 do Câmaras (R14 emenda).
- **Efeitos de status (`Suave`, por contrato; pedido da emenda do Status):** as Maldições aplicam **Abalo** pelo sistema de Status com autor = dono: *Rastro Cortante* e *Cratera de Cinza* (Saída, `4,0 s` = `duracao_abalo_s` do Status) e *Eco de Muralha* (Chamado do *Baluarte*, `1,5 s` vindo do `CurseDef`, alinhamento 2026-11-16; contrato pedido ao Status R3a: o golpe pode passar a sua duração). O Abalo aplicado no 6.1 fere e conta já no mesmo passo (Combate R23 §8) e é lido pela sinergia da F5. A Maldição **não recebe** status no MVP (R8). Sem o Status, o Abalo não acontece e a sinergia só lê imobilizado e atraído.

## Visual/Audio Requirements

> `art-director` consultado via regras consolidadas do Art Bible (§3.3, §4.3, §5.5, §6.3 — modo Lean, `2026-11-15`).

- **ML-V1. Leitura de facção (Art Bible §3.3 e §4.3):** toda Maldição aliada usa silhueta em **Tinta (`#0D0E14`)** e ardósia fria com **amarras, talas ou anéis em Osso (`#CFC6B4` / `#E6DFCF`)** e **nunca exibe núcleo ou projétil Magenta (`#E0259C`) exposto** em repouso (reservado a perigo inimigo).
- **ML-V2. Fio de vínculo permanente (Art Bible §3.3, Pipeline visual):** um fio curvo em **Osso translúcido** (`largura 2 px`, camada logo abaixo dos personagens no y-sort) liga o peito do Iniciado à Maldição em campo. Quando `d_jog > 0,85 × alcance_fio_px` (`408 px`), o fio tensiona em linha reta tracejada; ao estourar (`> 480 px`), pulsa em Osso claro enquanto puxa a Maldição de volta.
- **ML-V3. Marca do Virote (`R4.1`):** o único inimigo atualmente marcado pelo Virote exibe um pequeno **ilhós/elo de Osso** junto aos pés (sem usar magenta nem dourado), indicando o foco da Maldição.
- **ML-V4. Sem telégrafo de chão (`R6`):** ataques básicos, Efeitos de Saída/Entrada e o pouso do Chamado **nunca** usam o passe de telégrafo SDF do Pipeline visual; são lidos pelos *smears* e anéis rápidos em Tinta e Osso na camada de VFX (Feedback de combate).
- **ML-V5. Dano recebido e Exaustão (`R8`, `R9`):** quando atingida, a Maldição recebe flash em Osso por `4` passos vivos (sem inversão de tela e sem impact frame). Ao entrar em `Exausta`, dissolve-se em partículas de tinta que correm pelo fio de volta ao jogador em `12` passos.
- **ML-A1. Ganchos de áudio (Feedback de combate):** `maldicao_ataque`, `maldicao_chamado_salto`, `maldicao_chamado_pouso`, `maldicao_troca_tecnica`, `maldicao_exausta`, `maldicao_pronta` e `maldicao_recusa` (máximo 1 som por gancho por passo).
  - **(emenda Pactos, 2026-11-15)** Nomes com o prefixo do Feedback: `sfx_maldicao_ataque`, `sfx_maldicao_chamado_salto`, `sfx_maldicao_chamado_pouso`, `sfx_maldicao_troca_tecnica`, `sfx_maldicao_exausta`, `sfx_maldicao_pronta` e `sfx_maldicao_recusa`. A regra de 1 por passo continua.

## Game Feel

- **Parceria consentida, não microgerenciamento:** o jogador nunca precisa clicar para a Maldição bater; mirar e acertar o `Virote` já dirige o foco dela naturalmente (`R4.1`), mantendo o fluxo de tiro e esquiva de um *action roguelike*.
- **O peso do Chamado e da Troca:** embora os ataques básicos da Maldição não tenham hitstop (`de_arma = false`, para não travar a mira do jogador em momentos aleatórios), o pouso do **Chamado do Pacto** e a **Técnica Combinada** na Troca acionam um chute leve de câmera (`6 px`, Cena R8) e *smears* largos de Tinta e Osso, fazendo cada intervenção pedida pelo jogador parecer decisiva.
- **Segurança na falha (P2 + P4):** a **troca automática** quando a Maldição em campo fica `Exausta` (`R9.2`) evita que o jogador perca a linha de frente de surpresa no meio da onda, enquanto a recarga de `10,0 s` cobra o preço caso ele deixe as duas caírem em sequência.

## UI Requirements

- **Bloco do Pacto no HUD (canto inferior esquerdo, junto à arma e ao Selo — emenda no GDD de HUD):**
  - **Slot de Campo (maior):** ícone da silhueta da espécie ativa em Osso, barra compacta de Vida inteira (`Vida / vida_max`) e indicador de estado (`Ativa` ou `Saltando`).
  - **Slot de Reserva (menor, encostado ao de campo):** ícone da 2ª espécie, barra de Vida subindo durante a regeneração (`F2`) ou anel radial de recuperação quando `Exausta` (`restante_exausta / 600`), mais o indicador da recarga da ação `Troca` (`recarga_troca_s`) com o rótulo do bind (`rotulo_acao("troca")`).
- **Feedback de recusa (`R11`, `R13`):** tentar `Troca` com recarga ativa, durante salto, sem reserva ou com reserva `Exausta` emite o evento lógico `troca_indisponivel`, sacode o Slot de Reserva (`4 px` por `0,15 s`) e toca o gancho ~~`maldicao_recusa`~~ `sfx_maldicao_recusa`, uma vez por toque novo (mesma regra de `esquiva_sem_carga` e `selo_sem_fluxo`).
  - **(emenda Pactos, 2026-11-15)** Alinhado à HUD R18: a recusa da `Troca` sacode o Slot de Reserva **e** o selo da Troca (mesmos `4 px` por `0,15 s`).
- **Indicador de inimigo atraído (`R7`):** inimigos com atração ativa exibem um pequeno traço vertical em Osso acima da cabeça (distinto dos ícones de status Sangramento/Queimadura/Abalo).
- **(emenda Pactos, 2026-11-15)** O anel de Exausta usa `1 − restante_exausta / total_exausta`, com `total_exausta` lido da fonte (`600`; *Soberano* `480`, não `600`; vínculo nível ≥ 3: `540` / `432`), pela R19. O bloco lê `estado_pacto()` e `troca_disponivel`; não recalcula condições. O bind exibido é `rotulo_acao("troca")`: R / Tab e LT (Input R1a).

## Cross-References

- [game-concept.md](game-concept.md) (§6 Doutrina de Pactos e Besta do Vínculo)
- [../art/art-bible.md](../art/art-bible.md) (§3.3 leitura de forma "par ligado por fio", §4.3 paleta de aliado vs perigo, §5.5 feedback de dano)
- [combate-nucleo.md](combate-nucleo.md) (R8 impacto com `de_arma = false`, R10 hitstop, R14 autoria de abate)
- [armas-das-doutrinas.md](armas-das-doutrinas.md) (R1–R6 paridade de TTK, emenda 22c da Besta do Vínculo)
- [ia-de-inimigos-e-elites.md](ia-de-inimigos-e-elites.md) (R3–R9 perseguição e colisão, emenda de alvo atraído e imobilização)
- [modificadores-e-atributos.md](modificadores-e-atributos.md) (R1 portador, F1–F3)
- `vinculo-e-pactos.md` (#38 / 22d — obtenção de pactos, escolha da dupla e progressão de vínculo)
- `chefes.md` (#15 / 22b — forma de chefe do *Soberano do Limiar*)

## Acceptance Criteria

> `qa-lead` não consultado separadamente — modo Lean (`2026-11-15`; 23 critérios verificáveis cobrindo R1–R16, F1–F7 e ML1–ML8).

- **AC-ML-01 (R1 — Facção e sem fogo amigo):** **GIVEN** uma Maldição em campo na posição `(600, 540)` e um inimigo em `(640, 540)`, **WHEN** o jogador dispara um `Virote`, ativa um `Selo` ou aciona explosão/status sobre a área, **THEN** o inimigo recebe o dano/efeito normal e a Vida e os estados da Maldição permanecem inalterados.
- **AC-ML-02 (R1 — Câmara limpa):** **GIVEN** uma câmara de combate em que o último inimigo vivo morre e há uma Maldição aliada em campo com `Vida = 110`, **WHEN** o passo vivo avança com `hitstop == 0`, **THEN** `camara_limpa` é emitida normalmente sem exigir a remoção da Maldição.
- **AC-ML-03 (R2 — Dupla da expedição):** **GIVEN** o jogador iniciando a expedição com `["vulto_mudo", "espreitador_da_fenda"]`, **WHEN** a 1ª câmara monta, **THEN** `vulto_mudo` nasce em campo a `105 px` do jogador com `Vida = 110` e `espreitador_da_fenda` fica na reserva no estado `Pronta` com `Vida = 95`.
- **AC-ML-04 (R3, ML3 — Kit por raridade):** **GIVEN** o catálogo do MVP carregado pelo validador do Conteúdo, **WHEN** a checagem `ML3` avalia `vulto_mudo` (`comum`), `espreitador_da_fenda` (`refinado`), `baluarte_de_cinza` (`raro`) e `soberano_do_limiar` (`primordial`), **THEN** todas passam com `0` erros, e um `CurseDef` de teste `comum` com passiva preenchida falha com erro `ML3`.
- **AC-ML-05 (R4, F1 — Prioridade da marca do Virote e desempate por id):** **GIVEN** `vulto_mudo` em campo, o inimigo `id = 2` a `180 px` do jogador e o inimigo `id = 5` a `300 px` (`≤ 480 px`), **WHEN** o `Virote` do jogador acerta `id = 5`, **THEN** no passo vivo seguinte o alvo da Maldição passa a ser `id = 5`; se `marca_virote` for nula e dois inimigos estiverem à mesma distância de `200 px`, vence o menor `id`.
- **AC-ML-06 (R5, F1 — Estouro do fio e retorno com histerese):** **GIVEN** `vulto_mudo` (`velocidade = 405 px/s`, `6,75 px/passo`) perseguindo um inimigo enquanto o jogador se afasta para `d_jog = 493,5 px > 480 px`, **WHEN** avançam `58` passos vivos sem novos comandos, **THEN** no 1º passo a Maldição limpa o alvo e entra em `Seguindo`, ignora inimigos no caminho enquanto `d_jog > 105 px` e no 58º passo atinge `d_jog ≤ 105 px`, voltando a poder escolher alvo.
- **AC-ML-07 (R6, F3 — Ataque básico com `de_arma = false`):** **GIVEN** `vulto_mudo` em alcance de ataque de um Eco Perdido (`30 HP`), **WHEN** correm `30` passos vivos (`P=8, E=6, R=16`), **THEN** o Eco recebe `10` de dano no passo de execução, `hitstop` permanece `0`, o `Fluxo` do jogador não sobe (`+0`) e o contador de acertos da arma não incrementa.
- **AC-ML-08 (R6 — Abate creditado ao dono):** **GIVEN** um Eco Perdido com `8 HP` e o jogador com `Vida = 70/90` e uma bênção `cura_ao_abater = 4`, **WHEN** o ataque básico da Maldição abate o Eco, **THEN** o abate é creditado ao `player_id` do dono, o jogador recupera `+4` de Vida (`74/90`) e o hitstop de abate do Combate R14 é aplicado.
- **AC-ML-09 (R6, F3 — Ataque pesado do Baluarte quebra preparo):** **GIVEN** um Eco Perdido no passo `10` de seu preparo (`windup`) e `baluarte_de_cinza` concluindo o preparo de *Quebra-Limiar* (`dano = 14`, `empurrao = 900`, `pesado = true`), **WHEN** o golpe acerta o Eco, **THEN** o Eco recebe `14` de dano, seu preparo é cancelado com `"Quebrou!"` (`24` passos de recuperação) e recebe empurrão de `900 px/s`.
- **AC-ML-10 (R7 — Atração e isolamento de alvo no telégrafo inimigo):** **GIVEN** um Eco Perdido atraído pela Maldição (`restante_atracao = 180` passos) iniciando e concluindo seu ataque em setor onde tanto a Maldição quanto o jogador estão dentro da geometria, **WHEN** o passo de impacto do Eco executa, **THEN** apenas a Maldição (alvo do Eco) recebe `9` de dano e o jogador recebe `0` de dano.
- **AC-ML-11 (R7 — Fim imediato da atração ao sair de campo):** **GIVEN** dois inimigos atraídos pela Maldição em campo (`restante_atracao = 120` passos), **WHEN** a Maldição sai de campo por `Troca` ou `Exaustão`, **THEN** no mesmo passo `restante_atracao` zera nos dois inimigos e eles voltam a mirar o jogador.
- **AC-ML-12 (R8, F7 — Dano recebido sem invulnerabilidade pós-golpe):** **GIVEN** `baluarte_de_cinza` (`Vida = 135`, `reducao_dano = 0,15`) atingido no mesmo passo vivo por dois Ecos Perdidos comuns (`dano = 9` cada) que o miravam, **WHEN** o passo resolve, **THEN** a Maldição sofre `8 + 8 = 16` de dano (`Vida = 119`), `hitstop` permanece `0` e ela continua atingível no passo seguinte.
- **AC-ML-13 (R9, F2 — Exaustão, troca automática e retorno com 50% da Vida):** **GIVEN** `baluarte_de_cinza` em campo com `Vida = 5` e `vulto_mudo` na reserva `Pronta`, **WHEN** o Baluarte sofre `8` de dano, **THEN** no mesmo passo o Baluarte vai para a reserva em `Exausta` (`restante_exausta = 600` passos), `vulto_mudo` entra em campo sem gastar `recarga_troca_s` e sem disparar Técnica Combinada, e após `600` passos vivos o Baluarte passa a `Pronta` com `Vida = 68` (`round(135 × 0,50)`).
- **AC-ML-14 (R10, F2 — Regeneração na reserva):** **GIVEN** `baluarte_de_cinza` na reserva no estado `Pronta` com `Vida = 68/135` e `acum_regen = 0`, **WHEN** correm `596` passos vivos, **THEN** sua Vida sobe inteira passo a passo até atingir exatamente `135/135` e `acum_regen` zera.
- **AC-ML-15 (R11, R12, F5 — Troca manual e Técnica Combinada de Emboscada):** **GIVEN** `vulto_mudo` em campo perto de um Eco Perdido (`30 HP`), `espreitador_da_fenda` na reserva `Pronta` e `recarga_troca = 0`, **WHEN** o jogador aciona `Troca`, **THEN** no mesmo passo vivo: (1) `vulto_mudo` executa *Paredes de Sombra* (`8` de dano + `imobilizado` por `90` passos) e vai para a reserva; (2) `espreitador_da_fenda` entra executando *Salto de Emboscada*, lê `imobilizado` ativo e causa `12 × 1,5 = 18` de dano (`26` total no passo); (3) `recarga_troca` passa a `240` passos (`4,0 s`).
- **AC-ML-16 (R11 — Recusa de Troca sem condição):** **GIVEN** `recarga_troca = 120` passos (ou reserva em `Exausta`, ou Maldição em campo `Saltando`), **WHEN** o jogador aperta `Troca`, **THEN** nenhuma troca ou técnica ocorre, o estado não muda e o evento `troca_indisponivel` é emitido uma vez para aquele toque.
- **AC-ML-17 (R13, F4 — Chamado do Pacto: salto, pouso, imobilização de comum e atração):** **GIVEN** o jogador em `(500, 500)` mirando em `(1000, 500)`, `vulto_mudo` em `(440, 500)`, um Eco comum em `(900, 500)` e um Eco Elite em `(930, 500)` (mais próximo de `(920, 500)`), **WHEN** o jogador usa o Especial `Chamado do Pacto`, **THEN** `vulto_mudo` salta até `(920, 500)` em `12` passos vivos e no 12º passo causa `17` de dano nos dois, **imobiliza apenas o Eco comum** por `90` passos (o Elite não é imobilizado, R13.3) e **atrai ambos** (comum e Elite) por `180` passos (`3,0 s`).
- **AC-ML-18 (R13 — Chamado sem Maldição em campo):** **GIVEN** as duas Maldições da dupla em `Exausta` (nenhuma em campo) e o Especial da Besta com recarga `0`, **WHEN** o jogador aperta Especial, **THEN** o `Chamado do Pacto` é recusado e a recarga do Especial permanece `0`.
- **AC-ML-19 (R14 — Troca de câmara):** **GIVEN** `espreitador_da_fenda` em campo com `Vida = 60/95`, `vulto_mudo` em `Exausta` na reserva com `restante_exausta = 210` passos e `recarga_troca = 90` passos, **WHEN** a transição de câmara executa o corte no meio do wipe, **THEN** `espreitador_da_fenda` é posicionado junto ao jogador na entrada da nova câmara com `Vida = 60/95`, `marca_virote` limpa, e os contadores `restante_exausta = 210` e `recarga_troca = 90` são preservados.
- **AC-ML-20 (R15 — Congelamento em hitstop, pausa e transição):** **GIVEN** uma Maldição em `Preparo` em campo e outra em `Exausta` na reserva (`restante_exausta = 300`), **WHEN** o jogo roda `6` passos de hitstop (ou permanece em Pausa/Transição), **THEN** a posição, os contadores de ciclo de ataque, `restante_exausta`, `acum_regen` e `recarga_troca` não avançam durante os passos congelados.
- **AC-ML-21 (R16, F3 — Espécie Primordial *Soberano do Limiar*):** **GIVEN** `soberano_do_limiar` em campo executando `3` ciclos completos de ataque básico (`3 × 36 = 108` passos vivos) contra um alvo, **WHEN** o 3º ataque básico conclui, **THEN** além dos `11` de dano de cada golpe, *Pulso de Soberania* causa `+3` de dano pesado (`empurrao = 900`) em `135 px` e renova `60` passos de atração, totalizando `36` de dano em `1,80 s` (`20,00 DPS`).
- **AC-ML-22 (F6, ML7, ML8 — Paridade 60/40 da Doutrina de Pactos):** **GIVEN** os dados do catálogo do MVP para `WeaponDef pactos` e as 4 espécies de `CurseDef`, **WHEN** a validação cruzada calcula a F6 contra `700 HP` com `M = 1`, **THEN** para todas as 4 espécies `f_besta ∈ [0,598 ; 0,602]` (dentro de `[0,50 ; 0,70]`, `0` avisos `ML7`) e `TTK_pactos ∈ [10,47 s ; 10,53 s]` (diferença máxima `≤ 0,77% ≤ 15%` frente à Lâmina `10,53 s` e à Ressonância `10,45 s`, `0` avisos `ML8`).
- **(emenda Pactos, 2026-11-15) ACs atualizados pelos valores novos** (o texto acima fica como registro):
  - **AC-ML-07:** o Eco recebe **`9`** (não `10`).
  - **AC-ML-09:** o Eco recebe **`12,6`** de dano (não `14`); quebra e empurrão iguais.
  - **AC-ML-10:** `restante_atracao = 90` (não `180`); resultado igual.
  - **AC-ML-11:** `restante_atracao = 60`; além de zerar, os dois inimigos ficam com `restante_respiro = 30`.
  - **AC-ML-15:** *Paredes de Sombra* causa **`5`**, *Salto de Emboscada* causa **`6 × 1,5 = 9`**, total **`14`** no passo; sai 1 `troca_feita(manual)` e 1 `tecnica_combinada`.
  - **AC-ML-17:** atrai os dois por **`90`** passos (`1,5 s`); o dano do pouso usa `M_chamado` (`17` com `M = 1`).
  - **AC-ML-21:** cada golpe causa **`9,8`**, o Pulso `+3`, total **`32,4`** em `1,80 s` (**`18,00 DPS`**); o Pulso **aplica** `60` passos de atração só a inimigo livre.
  - **AC-ML-22:** substituído pelo AC-ML-27.
- **AC-ML-24 (R17, F4b — Sem renovação e com respiro):** **GIVEN** um Eco Perdido atraído pelo Chamado em `t = 0` (`restante_atracao = 90`), **WHEN** um *Pulso de Soberania* chega em `t = 50`, a atração acaba em `t = 90` e um novo Chamado pousa sobre ele em `t = 100` e outro em `t = 120`, **THEN** o Pulso de `t = 50` e o Chamado de `t = 100` são recusados (nada muda, sem `atraido`), o Eco mira o jogador de `t = 90` a `t = 119` e volta a ser atraído por `90` passos em `t = 120`.
- **AC-ML-25 (F4b — Teto da atração em 60 s):** **GIVEN** um Eco parado no raio e o Chamado usado a cada `120` passos com *Soberano* em campo emitindo o Pulso a cada `108` passos, **WHEN** correm `3600` passos vivos, **THEN** o Eco nunca fica mais de `90` passos seguidos atraído e a soma dos passos atraído é `≤ 2700` (`75%`).
- **AC-ML-26 (ML1 — Atração maior que a recarga):** **GIVEN** `duracao_atracao_s = 3,0` (`180` passos) e a recarga do Chamado `120` passos, **WHEN** o validador do Conteúdo executa, **THEN** a carga é recusada com erro `ML1`; o mesmo com *Queda de Pilar* de `120` passos e `duracao_atracao_s = 1,5`.
- **AC-ML-27 (F6, ML7, ML8 — Paridade com técnica):** **GIVEN** o catálogo da emenda, a Lâmina `66,47 DPS` e a Ressonância `66,96 DPS`, **WHEN** a validação cruzada calcula o piso (dupla de 1, nível 1) e o teto (técnica de `14` a cada `240` passos, vínculo nível 5) contra `700 HP` com `M = 1`, **THEN** o piso dá `64,70–65,02 DPS` (pior `3,49%`), o teto dá `69,35 DPS` (`4,33%`), `f_besta ∈ [0,577 ; 0,618]`, e saem `0` avisos ML7 e ML8 com `meta_paridade_pactos = 0,05`.
- **AC-ML-28 (R19 — `estado_pacto()`):** **GIVEN** *Soberano* Exausto na reserva há `100` passos e *Vulto* em campo `Saltando` com recarga da troca `90`, **WHEN** o HUD chama `estado_pacto()`, **THEN** recebe `reserva.estado = Exausta`, `restante_exausta = 380`, `total_exausta = 480`, `campo.estado = Saltando`, `recarga_troca_passos = 90`, `recarga_troca_total = 240` e `troca_disponivel = falso`; na pausa a leitura é igual.
- **AC-ML-29 (R20 — Eventos):** **GIVEN** uma dupla em campo, **WHEN** ocorrem, em passos separados, uma troca manual, uma troca automática por Exaustão, um Virote em outro inimigo, um estouro do fio e um Chamado que atrai 2 inimigos, **THEN** saem exatamente: `troca_feita(manual)` + `tecnica_combinada`; `troca_feita(automatica)`; `marca_virote_mudou` com o novo id; 1 `fio_estourou`; 2 `atraido` no pouso e 2 `atracao_fim` no 6.1 do passo seguinte ao fim (ou no mesmo passo, se a Maldição sair de campo). Nenhum `chamado_indisponivel` sai das Maldições.
- **AC-ML-30 (R21 — Saída de campo no mesmo passo):** **GIVEN** 3 Ecos atraídos, o 1º na lista acerta a Maldição e a deixa com `Vida ≤ 0` no item 7, **WHEN** o passo continua, **THEN** `maldicao_saiu_de_campo` é chamada dentro de `exaurir`, e o 2º e o 3º Eco já leem o jogador como alvo no mesmo item 7; o `fator_andar_atraido` lido por eles passa a não valer.
- **AC-ML-31 (R22 — Faro do Vínculo por código):** **GIVEN** *Espreitador* em campo (`435 px/s`) perseguindo a `marca_virote`, **WHEN** o passo 7 do 6.1 roda, **THEN** o portador tem a fonte `especie:espreitador_da_fenda:faro` e `valor(velocidade) = 500,25 px/s`; **WHEN** a marca muda para um inimigo fora do fio, **THEN** no mesmo passo a fonte sai e a velocidade volta a `435`.
- **AC-ML-32 (R23 — Chamado e Troca no mesmo passo):** **GIVEN** recarga da troca `0`, reserva Pronta e o Chamado aceito no item 5, **WHEN** o buffer também traz `troca` no mesmo passo, **THEN** a Maldição começa o salto e a troca é recusada com `troca_indisponivel(saltando)`; nenhuma técnica sai.
- **AC-ML-33 (R24 — Dupla cresce no meio da run):** **GIVEN** dupla de 1 (*Vulto* em campo) e o pacto do *Espreitador* com a acuada em `Vida = 40`, com o jogador tendo `dano_todo_pct +0,20`, **WHEN** `pacto` é resolvido, **THEN** o *Espreitador* entra na reserva `Pronta` com `Vida = 40/95`, `acum_regen = 0`, um portador novo com o espelho `+0,20` (M `1,20`), e a partir do passo seguinte `troca_disponivel` pode ficar verdadeiro.
- **AC-ML-34 (R24 — Vínculo nas fórmulas):** **GIVEN** *Soberano* no vínculo nível 3 e *Vulto* no nível 4, **WHEN** o *Soberano* fica Exausto e o *Vulto* ataca, **THEN** `total_exausta = 432` e o golpe do *Vulto* causa `9 × 1,05 = 9,45`.
- **AC-ML-35 (R14 emenda — `reposicionar_maldicao`):** **GIVEN** *Baluarte* (`raio 30`) em campo com marca, 2 inimigos atraídos e `estourou_fio` verdadeiro, **WHEN** o Câmaras chama `reposicionar_maldicao((960, 1035))` na troca de câmara, **THEN** a Maldição fica em `(960, 1035)` em `Seguindo`, `estourou_fio` falso, sai `marca_virote_mudou` vazio e 2 `atracao_fim`, e a reserva não muda; com um raio de teste `60`, o ponto pedido é `(960, 1020)`.
- **AC-ML-36 (Catálogo, ML1 — Eco de Muralha sem Abalo permanente, alinhamento 2026-11-16):** **GIVEN** *Baluarte* em campo e o chefe parado no raio do pouso, com o Chamado usado a cada `120` passos e sem Trocas, **WHEN** correm `3600` passos vivos, **THEN** cada pouso deixa o chefe abalado por `90` passos, há `30` passos sem Abalo antes de cada pouso seguinte e a soma é `≤ 2700` passos (`75%`); um `CurseDef` de teste com `duracao_abalo_s = 2,0` (`120` passos) no *Eco de Muralha* é recusado com erro `ML1`.

- **AC-ML-23 (ML1, ML2, ML4 — Erros de validação do catálogo):** **GIVEN** três definições inválidas injetadas em teste (`distancia_seguir_px = 500 > alcance_fio_px = 480`; `CurseDef` com `preparo_s = 0`; `CurseDef primordial` com `chefe_origem_id` vazio), **WHEN** o validador do Conteúdo executa, **THEN** a carga é recusada reportando respectivamente os erros `ML1`, `ML2` e `ML4`.

## Open Questions

1. **OQ1 — Bind padrão da ação `Troca` (para emenda no GDD de Input e controle):** usar `Q` / `Tab` no teclado e `LB` (`L1`) no gamepad?
2. **OQ2 — Forma de chefe da espécie Primordial (para o GDD `22b` de Chefes):** quais dos 4 padrões da Maldição-chefe do Limiar são espelhados visualmente em escala reduzida no *Soberano do Limiar* para ensinar a leitura do pacto?
3. **OQ3 — Efeito das bênçãos nas Maldições (para revisão de Modificadores / Bênçãos):** quais chaves de `PlayerMods` (ex.: `dano_todo_pct`, `velocidade_pct`) propagam do portador do jogador para os portadores das Maldições além das bênçãos específicas de vínculo? *(Hipótese deste GDD: no MVP base das 18 Tradições, `dano_todo_pct` propaga ao portador da Maldição para que `M_maldicao` escale na run junto com o jogador).*
4. **OQ4 — Comportamento em Co-op futuro (1 a 4 jogadores, sistema #36):** com mais de um jogador de Pactos na mesma sala, limitar a 1 Maldição em campo por jogador (máx. 4 na câmara) ou reduzir o tamanho visual em `15%` para preservar o orçamento de leitura da tela?
> **(emenda Pactos, 2026-11-15)** **OQ1 resolvida** pelo Input R1a: Troca em **R / Tab** e **LT** (Q e LB colidiam com o `selo`). **OQ2 resolvida** pelo Chefes: o *Soberano* aliado espelha 3 dos 4 padrões pelo nome e pela leitura (*Garra do Véu Rasgado* → ataque básico; *Pulso de Soberania* → habilidade única; *Convergência da Fenda* → efeito no Chamado), com a coroa de cristais selada por anéis de Osso e sem magenta (Chefes CH-V1). **OQ3 resolvida** pelo Modificadores R14/F6 (R24).
>
> **Novas (emenda Pactos):**
> - **OQ6 — Técnica mais forte com recarga maior?** Alternativa à R18: manter a técnica de `28` e subir `recarga_troca_s` para `~6,5 s`, com o ataque básico em `~17 DPS`. Escolhida a recarga de `4,0 s` (o HUD e o Input já citam `240` passos e a troca rápida é o centro da fantasia). Validar no 1º playtest de Pactos.
> - **OQ7 — Danos fracionários** (`7,65`, `12,6`, `9,8`): o Combate arredonda o dano em inimigo? Se arredondar, ajustar para `7,5` / `12,5` / `10` e refazer a F6 (variação `< 0,3` ponto).
> - **OQ8 — Respiro na Entrada da técnica:** a *Queda de Pilar* que entra logo após a saída de campo cai no respiro dos inimigos que a outra atraía. Aceito por simplicidade; reabrir se o playtest mostrar que a técnica parece falhar.
> - ~~**OQ9 — Duração do Abalo do Eco de Muralha (alinhamento 2026-11-16):** `1,5 s` (75% de cobertura no teto) ou `1,0 s` (50%)? A alternativa "não se aplica a chefe" foi descartada por criar imunidade que o cânone não tem.~~ **Fechada (2026-11-16):** `1,5 s` (`90` passos, 75% de cobertura no teto).

5. **OQ5 — Linha de cânone para o termo "Maldições":** registrar na emenda de `docs/NARRATIVE_Mestres_Bencaos_Modo_Acao.md` a distinção de Serel entre *Anomalia bruta* (hostil) e *Maldição* (resíduo que aceitou nome, amarra de osso e fardo partilhado).
