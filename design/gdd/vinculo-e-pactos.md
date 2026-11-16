# Vínculo e pactos

> **Status**: Approved (usuário, 2026-11-16)
> **Author**: game-designer (lote Pactos, 2026-11-15) — aguarda aprovação do usuário
> **Last Updated**: 2026-11-15
> **Implements Pillar**: P1 *Toda bênção é uma filosofia* (pacto consentido, não comandado); P4 *Ritual, não pressão* (vínculo que cresce devagar, sem perda); P2 *A Beira cobra* (proteger custa risco; pactuar com o chefe custa Fragmentos); P5 *O mundo não se explica de uma vez* (história das espécies em fragmentos)

## Summary

**Vínculo e pactos** é o sistema que dá Maldições ao Iniciado de Pactos e as faz
crescer entre runs. Ele define: o **primeiro pacto** (o *Vulto Mudo*, concedido
na primeira vez que o jogador escolhe Pactos); o **encontro de pacto** numa
câmara de combate (uma Maldição acuada que o jogador protege das Anomalias, sem
derrotá-la, e que depois consente); a **escolha da dupla** antes da expedição;
os **pontos e níveis de vínculo** de cada espécie (5 níveis, ganhos pequenos e de
qualidade, com prova de que Pactos fica a `≤ 4,33%` da paridade de TTK no nível
máximo, com a técnica, dentro da meta `±5%` — emenda Pactos, 2026-11-15); o registro do pacto com a **Maldição-chefe** após `Subjugado`; e a
**lista exata de campos** que o Save e perfil grava.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Maldições, Save e perfil (por contrato), Câmaras e ondas (por contrato), Portas e recompensas (por contrato), Chefes (por contrato), RNG com seed, Conteúdo orientado a dados, Modificadores e atributos`

## Overview

**Vínculo e pactos** é a camada de progressão da Doutrina de Pactos. As
Maldições (`maldicoes.md`) dizem como cada criatura luta. Este GDD diz **como ela
chega** ao jogador e **o que fica** entre uma run e outra.

- **Como chega.** Ninguém captura uma Maldição. Numa câmara de combate, o
  jogador encontra uma Maldição **acuada**, ferida, cercada pelas Anomalias. Se a
  protege até a câmara ficar limpa, ela **consente** e o pacto nasce. Se ela cai,
  foge pela fenda e volta numa run futura. Cânone: o vínculo é "consentido, não
  comandado" e "sem jaulas" (`FRENTE4_Tradicoes_e_Reconciliacao.md` §2.2); O
  Fardo Repartido é "construído inteiramente sobre consentimento" (§1.5).
- **O primeiro pacto.** A iniciação dos Pactos exige testemunha de outro
  Portador (FRENTE4 §1.5, O Primeiro Vínculo). No MVP, sem o Rito de Iniciação
  (Vertical Slice), a primeira escolha de Pactos concede o *Vulto Mudo* diante
  de uma testemunha, num cartão curto.
- **O que fica.** Cada espécie pactuada tem **pontos de vínculo**. Eles vêm de
  lutar junto: câmaras, abates, técnicas e vitórias. Os pontos sobem o **nível**
  (1 a 5). Os níveis dão pouco número e mais qualidade: um pouco de Vida, volta
  mais rápida da Exaustão, um pouco de dano no ataque básico e, no topo, a
  amarra completa e a última memória da espécie. Cânone: em Os Que Ficam "o bônus
  se constrói pelo tempo em convivência, não por técnica" (FRENTE4 §1.5).
- **Nada se perde.** Pontos ganhos numa run valem mesmo na morte e no abandono,
  como os Fragmentos (Run R5–R6). O vínculo nunca decai (P4).

**Fantasia:** a criatura não é um item. É alguém que aceitou ficar. O jogador
deve sentir que o pacto foi **merecido**, protegendo, e que o vínculo cresceu
**porque lutaram juntos**.

**Sem este sistema,** Pactos teria Maldições sem origem, a escolha "pacto ou
derrota" do chefe não registraria nada e nada passaria de uma run para a outra.

> **→ vira ADR:** onde vive o `PerfilVinculo` em memória (objeto injetado, sem
> singleton), como a câmara de encontro injeta a Maldição acuada sem mudar o
> consumo dos fluxos de estrutura, e o formato da gravação (dono: Save e perfil).

## Detailed Design

### Core Rules

Os valores nomeados (`chance_encontro` etc.) estão no `VinculoTuning` (Formulas,
tabela final). Regras marcadas **[a confirmar]** são escolhas deste GDD que o
usuário ainda não aprovou.

#### A. Perfil de vínculo

**V1. Perfil.** O `PerfilVinculo` é um objeto injetado que guarda, por espécie
do catálogo `CurseDef` (`maldicoes.md` §Catálogo), o estado de pacto e vínculo, e
alguns contadores globais. É **o conteúdo** que o Save e perfil grava (V30). Ele
atravessa runs e sessões. Nenhum outro sistema escreve nele.

**V2. Pontos são a verdade; o nível é derivado.** O nível de uma espécie é
calculado dos pontos pela F3. O campo `nivel` é gravado como cache (o brief
pede) e, ao carregar, é **recalculado**. Se diferir, vale o recalculado.

#### B. Primeiro pacto

**V3. Primeiro pacto [a confirmar].** Quando o jogador confirma a arma **Besta
do Vínculo** na Escolha de arma (Run R2 passo 1) e `primeiro_pacto_concedido` é
falso:

1. a espécie `especie_primeiro_pacto` (`vulto_mudo`, Comum) passa a
   `pactuada = true`, `nivel = 1`, `vinculo_pontos = 0`;
2. `primeiro_pacto_concedido = true`;
3. abre o cartão **"O Primeiro Vínculo"** (uma tela, um botão "Aceitar"; texto do
   `narrative-director`, com a testemunha de outro Portador, FRENTE4 §1.5);
4. o Vínculo emite `pacto_registrado("vulto_mudo")`; o Save grava neste ponto
   seguro (Menus, V32).

Por que o *Vulto Mudo*: é o Comum do catálogo (kit mais simples, R3 de
Maldições) e, como a Sombra Muda de Serel, é "mudo" (`maldicoes.md` Catálogo).
Assim a primeira run de Pactos nunca é só a Besta (`40 DPS` contra `66,5`,
Maldições F6), o que daria TTK de `17,5 s` e quebraria a paridade.

No Vertical Slice, o **Rito de Iniciação** (sistema 24) assume este momento. A
regra de dados é a mesma.

#### C. Encontro de pacto

**V4. O que é.** Um **encontro de pacto** é uma câmara de **combate** normal
(layout, ondas e recompensa da porta, Câmaras R4–R7, Portas R2) com uma
**Maldição acuada** a mais. Não é um tipo novo de câmara nem uma porta nova:
a sequência da região (Câmaras R1) e o fluxo `portas` (Portas R7) não mudam.

**V5. Só para Pactos [a confirmar].** O encontro só existe em runs com a
Doutrina `pactos`. Nas outras Doutrinas ele **não aparece** e nada o substitui.
Motivo: só quem jurou Pactos escolhe entre pacto e derrota (decisão do
usuário); dar outra recompensa às outras Doutrinas mexeria na economia das
Portas (Portas F3, Economia F3) sem ganho de identidade.

**V6. Quando aparece.** No máximo **um** encontro por run. Ele é sorteado **ao
criar a run**, logo depois da seed (Run R2 passo 2), no fluxo novo `pactos`
(contrato pedido ao RNG, V40), com **consumo fixo de 4 reais** (F1). O sorteio
decide: se há encontro, em que câmara e com que espécie.

- **Câmaras candidatas:** `indices_encontro` = `[1, 2]` do Limiar (combate, p 1 e
  p 2). Ficam fora: a de índice 0 (primeira câmara e primeira bênção), o
  santuário (3), as de índice 4 e 5 (~~2 ondas mais pesadas e a última, sem
  recompensa, Portas R1~~ (emenda Pactos, 2026-11-15) 2 ondas mais pesadas antes
  do chefe; o índice 5 agora tem recompensa, Run R3-P) e o chefe (6). **[a confirmar]**
- **Chance:** `chance_encontro` (`0,6`) por run de Pactos.
- **Garantias** (qualquer uma força o encontro):
  1. **primeiro encontro:** `primeiro_encontro_visto` falso. O encontro vai para
     a câmara de índice `indices_encontro[0]` (1) e a espécie é a de **menor
     raridade ainda não pactuada** (empate: ordem do manifesto). No MVP, depois
     do *Vulto Mudo*, é o *Espreitador da Fenda* (Refinado);
  2. **encontro pendente:** `encontro_pendente` não é vazio (V12, V13). A
     espécie é a pendente;
  3. **piedade:** `runs_pactos_sem_encontro ≥ pity_runs` (`2`).
- **Espécie:** só espécies **regulares** (raridade ≠ `primordial`; a Primordial
  só vem pelo chefe, Maldições R16). Se existe regular não pactuada, ela é
  escolhida com chance `chance_nao_pactuada` (`0,75`); senão, uma já pactuada
  (o encontro vira **reafirmação**, V11). Dentro de cada grupo, a escolha é
  ponderada por `peso_raridade` (F1).

**V7. A Maldição acuada.** Na montagem da câmara do encontro (Câmaras R4, depois
do layout e antes da 1ª onda), nasce a acuada:

- **Posição:** o primeiro ponto livre de `pontos_acuada` (`(960; 540)`,
  `(660; 540)`, `(1260; 540)`, `(960; 360)`, `(960; 720)`), livre = distância ao
  centro de cada pedra `> r_pedra + raio_especie + spawn_folga_pedra_px` (12,
  Câmaras R15). Se nenhum serve, o último. Não consome RNG.
- **Corpo:** silhueta da forma aliada da espécie (`CurseDef`), encolhida. Raio
  da espécie. **Não anda e não ataca.** Não usa passivas, Efeitos nem
  `reducao_dano` (F2).
- **Vida:** `vida_acuada = round(vida_max_base × frac_vida_acuada)` (F2), sem
  bônus de vínculo e sem regeneração.
- **Facção:** nem inimiga nem aliada. Nada do jogador a fere (Virote, Selo,
  explosões, status, Maldição em campo): **sem fogo amigo**, como Maldições R1.
  Ela **não conta** na câmara limpa (Câmaras R9) e não bloqueia ninguém.
  Obstáculos não importam (ela não se move).

**V8. Quem as Anomalias atacam [a confirmar].** Na câmara do encontro, enquanto a
acuada está no estado `Acuada`:

- cada inimigo que nasce recebe o alvo padrão pela **ordem de nascimento na
  onda** (Câmaras R7, ordem da composição): ordem par (0, 2, 4…) mira a
  **acuada**; ordem ímpar mira o **jogador**;
- a atração (Chamado do Pacto, *Queda de Pilar*, *Pulso de Soberania*,
  Maldições R7) tem prioridade: um inimigo atraído mira a **Maldição em campo**
  enquanto durar. Ao acabar a atração, volta ao seu alvo padrão;
- como em Maldições R7, **um golpe só testa o seu alvo**: o golpe mirado na
  acuada não fere o jogador nem a Maldição em campo, e vice-versa;
- se a acuada sai (`Fugiu`, V12), todo inimigo que mirava nela passa a mirar o
  jogador no mesmo passo.

Esta é a mecânica central do encontro: proteger é **puxar as Anomalias** para a
própria Maldição (Chamado) e **matar rápido** as que miram a acuada.

**V9. Sucesso.** A câmara fica limpa (Câmaras R9–R11) com `Vida_acuada > 0`. A
acuada passa a `Aguardando` e fica no lugar, com o prompt **Interagir** (alcance
da porta, Câmaras R13: `raio_especie + 27 + 15 px`).

- **Ordem com as Portas (contrato pedido, V41):** a recompensa da câmara sai
  primeiro (Portas R2 passo 2, inclusive a Tela de bênção). As portas **só
  abrem depois** de o encontro ser resolvido (`pacto_resolvido`). O jogador
  não perde o encontro saindo por uma porta.
- **Interagir** abre a **tela de consentimento** (UI Requirements). A tela é um
  estado **fora de Jogo**, como a Bênção (ADR-0001; contrato com Save R5.1): o
  mundo para enquanto ela está aberta e a escolha acontece lá. Assim o pacto
  grava no ponto seguro **do mesmo instante** (Save R5.1), e não na Transição
  seguinte. A tela do chefe (V18) segue a mesma regra.
  - **(emenda Pactos, 2026-11-15)** A tela de consentimento usa o **estado Bênção**
    do ADR-0001 (o mesmo da Tela de bênção), sem estado novo. **[a confirmar]**

**V10. Consentimento e pacto novo.** Na tela, se a espécie **não** está
pactuada:

- se `encontros_bem_sucedidos + 1 ≥ encontros_para_consentir(raridade)`: a tela
  oferece **"Oferecer o vínculo"** e **"Deixá-la ir"**.
  - *Oferecer:* ela consente. `pactuada = true`, `nivel = 1`, `vinculo_pontos =
    0`, `encontros_bem_sucedidos += 1`, e se `encontro_pendente` era ela, ele é
    limpo. Emite `pacto_registrado(especie_id)` (gatilho do Save R5).
  - *Deixá-la ir:* `encontros_bem_sucedidos += 1`, sem pacto; ela parte em paz.
    Nada fica pendente. Grava no próximo gatilho (V32).
- senão (Raras na 1ª vez, V13): a tela mostra que ela **ainda não confia**, mas
  deixa uma amarra de Osso; um só botão, **"Ela voltará"**.
  `encontros_bem_sucedidos += 1` e `encontro_pendente = [especie]`. Grava no
  próximo gatilho (V32).

Em qualquer caso, `encontros_vistos += 1` já foi contado quando ela nasceu
(V14).

**V11. Reafirmação (espécie já pactuada).** A tela oferece **"Reafirmar o
vínculo"** e **"Deixá-la ir"**. Reafirmar soma `pts_reafirmar` (`6`) aos pontos
**da run** dessa espécie (V20); Deixá-la ir não soma nada. Cânone: o primeiro
pacto "precisa ser reafirmado… nunca presumido como permanente" (FRENTE4 §1.5).

**V12. Falha.** Se `Vida_acuada ≤ 0` na fase Combate:

1. ela passa a `Fugiu`: dissolve-se numa fenda no chão em `12` passos e sai;
2. os inimigos que a miravam passam a mirar o jogador (V8);
3. `encontro_pendente = [especie]` (**ela volta** na próxima run de Pactos, com a
   garantia 2 da V6) **[a confirmar]**; grava no próximo gatilho (V32);
4. a câmara segue normal: ondas, limpeza, recompensa e portas, sem esperar nada.

Ela **não morre**: Maldições são resíduos de Anomalia, e o jogador não a derrotou.

**V13. Espécies raras contam a história em vários encontros [a confirmar].**
`encontros_para_consentir` por raridade: Comum 1, Refinado 1, **Raro 2**,
**Épico 2**, Primordial 1. Um *Baluarte de Cinza* (Raro) precisa de **dois**
encontros bem-sucedidos. O primeiro revela uma memória e marca a espécie como
pendente; o segundo vem garantido na run de Pactos seguinte (V6, garantia 2) e
abre o consentimento. A Primordial fica com 1 porque o chefe já é a prova, e
`chefes.md` R9 registra o pacto na primeira escolha `pactuar`.

**V14. Contagem de encontros.** `encontros_vistos` da espécie sobe `1` quando a
acuada **nasce** na câmara, e quando o chefe da espécie entra em `Subjugado`
(V18). `primeiro_encontro_visto = true` no mesmo momento. Ver a acuada já conta,
mesmo que o jogador morra em seguida.

**V15. Entrar na dupla durante a run [a confirmar].** Se o jogador pactua no
encontro e a dupla da run tem **uma** Maldição (caso da primeira run de
Pactos), a nova entra **agora** como reserva, no estado `Pronta`, com
`Vida = min(Vida_acuada, vida_max)` (nível 1, sem bônus) e regenera na reserva
(Maldições R10). A partir daí a troca e a técnica existem (Maldições R11–R12).
Com a dupla cheia, a nova só vai para o perfil.

#### D. Primeira run de Pactos (resumo das regras acima)

- Ao escolher a Besta pela primeira vez, ganha o *Vulto Mudo* (V3).
- A dupla tem só ele: sem troca nem técnica (Maldições R2).
- O encontro é **garantido** na câmara de índice 1, com o *Espreitador da
  Fenda* (V6, garantia 1).
- Se protegê-lo, ele entra na reserva na hora (V15) e a run segue com troca e
  técnica. Se falhar, ele volta garantido na próxima run (V12).

#### E. Escolha da dupla

**V16. Tela "Escolha do Pacto".** Na Escolha de arma, ao confirmar a Besta (e
depois do cartão da V3, se houver), abre a tela de dupla. A **seed só nasce ao
confirmar a dupla** (contrato pedido à Run e ao RNG, V40, V42), porque a dupla e
o perfil fazem parte do estado inicial (RNG R7).

| Espécies pactuadas | O que a tela faz |
|---|---|
| 0 | não acontece: a V3 garante 1. Se o perfil vier sem pacto (corrompido, V33), a V3 roda de novo |
| 1 | tela pulada (V16b): a espécie vai sozinha, sem reserva; um aviso curto na carga |
| 2 | as duas já vêm na dupla. O jogador só escolhe **quem começa em campo** (trocar a ordem) |
| 3 ou mais | o jogador escolhe 2. A **1ª escolhida começa em campo** e a 2ª fica na reserva (Maldições R2). Vem marcada a `ultima_dupla`, se ainda for válida |

- Cada cartão mostra: nome, raridade, nível e barra de vínculo (pontos até o
  próximo nível), resumo do kit (R3 de Maldições) e as memórias reveladas (F5).
- Uma espécie só entra uma vez na dupla.
- Confirmar atualiza `ultima_dupla` e é gatilho de gravação do Save ("Dupla
  escolhida", Save R5).

**V16b. Contrato com a Run (emenda de `run-e-regioes.md`).**

- A Run chama `pedir_dupla()` quando a arma confirmada é a Besta (depois da V3).
- O Vínculo responde `dupla_confirmada(campo: String, reserva: String)`;
  `reserva = ""` quando não há segunda Maldição.
- **Com 0 ou 1 espécie pactuada a tela é pulada** (pedido da Run): com 1, o
  Vínculo responde na hora `dupla_confirmada(id, "")`; com 0, roda a V3 antes e
  responde com o *Vulto Mudo*. A tabela acima vale para 2 ou mais; a linha "1"
  vira só um aviso curto na tela de carregamento, sem botão.
- A Run cria a seed **depois** de `dupla_confirmada` (V40).

#### F. Pontos e níveis

**V17. Fontes de pontos (por espécie da dupla, na run).** Somados em
`pontos_run[especie]`, em memória:

| Evento | Pontos | Teto por run | Quem recebe |
|---|---|---|---|
| câmara de combate ou de chefe **limpa** em que a espécie acertou ≥ 1 golpe (ataque, Efeito ou Chamado) | `pts_camara` (2) | — (6 câmaras: 12) | cada espécie que acertou |
| **abate** feito por golpe da espécie (Maldições R6) | `pts_abate` (1) | `teto_abates_run` (12) | a autora do golpe |
| **técnica combinada** que acertou ≥ 1 inimigo (Maldições R12) | `pts_tecnica` (1) | `teto_tecnicas_run` (6) | as duas (Saída e Entrada) |
| **vitória** da run | `pts_vitoria` (8) | 1 vez | as espécies da dupla no fim |
| **reafirmação** num encontro (V11) | `pts_reafirmar` (6) | 1 vez (1 encontro por run) | a espécie reafirmada |
| **pactuar** com o chefe já pactuado (V18) | `pts_reafirmar_chefe` (10) | 1 vez | a Primordial; no nível máximo, cada espécie da dupla (V18.5) |

Sem pontos por tempo em campo: tempo pode ser moído fugindo de um inimigo. Todas
as fontes acima têm teto natural (inimigos e câmaras são finitos).

**V18. Pacto com a Maldição-chefe** (fluxo de `chefes.md` R9, F6). Quando chega
`chefe_subjugado(id)`:

1. `encontros_vistos += 1` e `primeiro_encontro_visto = true` (V14);
2. o chefe ajoelhado ganha o prompt **Interagir** (resposta à OQ1 de Chefes,
   **[a confirmar]**). Interagir abre a tela **Pactuar / Exorcizar**, com o preço
   à vista: "Pactuar: 0 Fragmentos" e "Exorcizar: +6 Fragmentos" (P2);
3. **Pactuar**, espécie não pactuada: `pactuada = true`, `nivel = 1`,
   `vinculo_pontos = 0`, `encontros_bem_sucedidos += 1`; emite
   `pacto_registrado("soberano_do_limiar")`. A espécie não entra na dupla desta
   run (a run acaba com a vitória);
4. **Pactuar, espécie já pactuada e abaixo do nível máximo [a confirmar]:** soma
   `pts_reafirmar_chefe` (10) aos pontos da run do *Soberano*,
   `encontros_bem_sucedidos += 1` e revela memória (F5, pelo encontro). Emite
   `pacto_registrado` (o Save grava; Save R5 inclui `pactuar` no chefe);
5. **Pactuar, espécie já no nível máximo (5) [a confirmar]: "o fardo
   repartido".** Os 10 pontos não teriam efeito no *Soberano*. Eles vão
   **inteiros para cada espécie da dupla desta run** (`pts_reafirmar_chefe` para
   cada uma, até 2). Se uma delas também já está no nível 5, a parte dela vai
   para a espécie pactuada de **menor nível** fora da dupla (empate: ordem do
   manifesto); se todas estão no máximo, não há ganho mecânico e a tela diz isso
   ("O vínculo já está inteiro"), deixando o Exorcizar como a escolha racional.
   Por que não converter em Fragmentos: Pactuar igual a Exorcizar apagaria a
   escolha (P2). Comparação: +10 pontos para duas espécies equivalem a um terço
   de uma run de vitória de cada (F3), contra `+6` Fragmentos (~27% da renda
   máxima de uma run, Economia F3). Moedas diferentes, decisão real;
6. **Exorcizar**: nada muda no pacto (o encontro já contou). O Chefes credita os
   `+6` (Chefes R9).

Em todos os casos, depois da escolha o Vínculo emite **`chefe_escolhido(id,
escolha)`** (`escolha ∈ {pactuar, exorcizar}`), que o Chefes (F6) e a Run
(emenda de `run-e-regioes.md`) escutam. A tela é fora de Jogo (V9).

O registro do pacto com a Primordial é o mesmo de qualquer espécie. Um pacto
feito numa run que termina em morte ou abandono **continua valendo** (está no
perfil desde o `pacto_registrado`). No `Subjugado` não há morte possível (fase
fora de combate, Chefes R9); sair do jogo antes de escolher conta como **nenhuma
escolha**: o encontro conta, o pacto não, e a run é consolidada como abandono
(V20b).

**V19. Níveis.** `nivel_max = 5`. O nível vem dos pontos (F3). Ganhos de cada
nível, cumulativos, aplicados **no começo da run** (estado inicial, nunca no
meio):

| Nível | Pontos (acumulados) | Nome | Ganho | Tipo |
|---|---|---|---|---|
| 1 | 0 (ao pactuar) | Pacto | kit base da espécie; 1ª memória | — |
| 2 | 20 | Confiança | `+5%` de `vida_max` (`bonus_vida`, fonte `vinculo`) | número pequeno |
| 3 | 50 | Passo comum | tempo de `Exausta` `× 0,90` (`mult_recuperacao`) | qualidade |
| 4 | 90 | Golpe partilhado | `+5%` no dano do **ataque básico** (`bonus_dano_basico`) | número pequeno |
| 5 | 140 | Laço reafirmado | amarra de Osso completa na silhueta, título no cartão e +1 memória (F5) | só qualidade e lore |

- O vínculo **não** muda: Chamado, Efeitos de Saída e Entrada, recarga da troca,
  regeneração na reserva, Besta, nem `M` do Modificadores. Assim a técnica e o
  Chamado ficam fora da conta de poder (F4).
- **Regra ML5 (Maldições):** os bônus são os mesmos para toda espécie. A F4 prova
  que, mesmo com uma espécie no nível 5 e outra no 1, `vida` e `DPS_autonomo`
  ficam dentro dos limites do ML5 (`1,50` e `1,15`). O vínculo **não fura** a
  regra "raridade dá profundidade, não números maiores".

**V20. Fechar a run.** Em `run_encerrada` (vitória, morte ou abandono), antes da
tela final:

1. para cada espécie com `pontos_run > 0`: `vinculo_pontos += pontos_run`
   (teto `pontos_teto`), recalcula o nível (F3);
2. atualiza `runs_pactos_sem_encontro`: `0` se a acuada nasceu nesta run, senão
   `+1`;
3. `runs_pactos_iniciadas += 1`;
4. emite `vinculo_atualizado` (para a tela final e a Telemetria);
5. o Save grava no gatilho "Fim da run" (Save R5), depois desta consolidação.

Os pontos valem em qualquer fim (P4, como os Fragmentos em Run R5–R6).

**V20b. Sair do jogo no meio da run (contrato com Save R10).** Se o jogador sai
normalmente (menu Sair ou fechar a janela) com uma run de Pactos ativa, o Save
chama `escrever()` e, antes disso, o Vínculo **consolida a run como abandono**:
aplica a V20 inteira, com a mesma regra de uma derrota (sem `pts_vitoria`). Um
encontro em `Aguardando` vira `Abandonado` (`encontro_pendente = [especie]`). Em
queda do processo vale o último arquivo gravado: os pontos da run se perdem, mas
um pacto já feito não, porque grava no ponto seguro da própria tela (V9).

**V21. Run de outra Doutrina.** Não sorteia encontro (V5), não soma pontos e não
muda nenhum campo. O fluxo `pactos` não é pedido.

#### G. Memórias (lore em fragmentos)

**V22. Memórias.** Cada `CurseDef` ganha `memorias: Array[StringName]` (chaves de
texto, conteúdo do `narrative-director`). A quantidade segue a raridade (mesma
lógica da R3 de Maldições): Comum 1, Refinado 2, Raro 3, Épico 4, Primordial 4.
Quantas estão reveladas é **derivado** (F5), não gravado. Ficam no cartão da
dupla e na tela de consentimento. Uma memória é um fragmento, nunca biografia
(P5).

#### H. Contrato com Save e perfil

**V30. Campos persistidos (o conteúdo, dono: Vínculo).** O Save e perfil é dono
do **formato, de quando grava no disco e da corrupção** (`save-e-perfil.md`
R2–R10). O Vínculo é dono desta lista. São as **chaves de primeiro nível** do
dicionário de `escrever()` (seção `[vinculo]`, Save R2–R3). Só `bool`, `int`,
`String`, `Array` e `Dictionary` desses tipos: **sem `float` e sem
`StringName`** (Save R3). Ids são `String`.

| Chave | Tipo | Inicial | Faixa válida (checada em `ler()`) | Significado |
|---|---|---|---|---|
| `versao` | int | `1` | `≥ 1` | versão do conteúdo do Vínculo (migrações de conteúdo, Save R6) |
| `primeiro_pacto_concedido` | bool | `false` | — | V3 já rodou |
| `primeiro_encontro_visto` | bool | `false` | — | algum encontro (campo ou chefe) já nasceu (garantia 1, V6) |
| `runs_pactos_iniciadas` | int | `0` | `0–2 147 483 647` | runs de Pactos encerradas (V20) |
| `runs_pactos_sem_encontro` | int | `0` | `0–1 000` | runs de Pactos seguidas sem acuada (piedade, V6) |
| `encontro_pendente` | Array[String] | `[]` | 0–1 id de espécie **regular** | espécie que volta garantida (V12, V13). É `Array` porque o Save só filtra ids fora de `especies` em campos de `campos_de_ids()` |
| `ultima_dupla` | Array[String] | `[]` | 0–2 ids distintos de espécies pactuadas; `""` = vaga vazia | dupla da última run (V16) |
| `especies` | Dictionary[String → Dictionary] | uma entrada por `CurseDef` do manifesto, com os valores abaixo | chave = id da espécie (exigência do Save R3) | estado por espécie |
| `especies[id].pactuada` | bool | `false` | — | há pacto |
| `especies[id].vinculo_pontos` | int | `0` | `0–pontos_teto` (9 999) | verdade do vínculo (V2) |
| `especies[id].nivel` | int | `0` | `0` se não pactuada; `1–nivel_max` (5) se pactuada | cache de F3 (V2) |
| `especies[id].encontros_vistos` | int | `0` | `0–1 000 000` | acuadas e `Subjugado` vistos (V14) |
| `especies[id].encontros_bem_sucedidos` | int | `0` | `0–encontros_vistos` | encontros vencidos (V10, V13, V18) |

Não são gravados (derivados): memórias reveladas (F5), bônus de nível (F4),
`pontos_run` (só durante a run). O registro por espécie traz os 4 campos que o
Save assumiu (Save R3) e acrescenta `encontros_bem_sucedidos`.

**V31. Interface com o Save (Save R3).**

- `escrever() -> Dictionary`: devolve o dicionário da V30, completo, com as
  espécies **na ordem do manifesto** (Conteúdo R10), para o texto ser igual byte a
  byte entre estados iguais (Save R5.2).
- `ler(dados: Dictionary) -> void`: recebe o que o Save leu, já migrado e
  filtrado (`{}` na primeira execução, no corrompido e na versão futura). Aplica
  os padrões e **valida as faixas** (V33).
- `campos_de_ids() -> Array[String]`: devolve `["ultima_dupla",
  "encontro_pendente"]`.
- Migrações de conteúdo: funções puras `migrar_vinculo(v_de, dados) -> dados`,
  registradas na cadeia do Save (Save R6). No MVP não há nenhuma (versão 1).

**V32. Quando o Save grava (gatilhos do Save R5 que vêm do Vínculo).**

| Gatilho | Quando, no Vínculo | Estado do jogo |
|---|---|---|
| `pacto_registrado(especie_id)` (nome provisório do Save) | V3 (primeiro pacto, `especie_id = vulto_mudo`), V10 "Oferecer", V18 "Pactuar" (novo ou reafirmado) | fora de Jogo: cartão da V3 (Menus) ou tela de consentimento (V9). Grava no mesmo ponto seguro |
| Dupla escolhida | V16, ao confirmar | Menus |
| Fim da run | V20, depois da consolidação | Morte ou tela final |
| Sair do jogo | V20b, depois da consolidação como abandono | — |

As outras mudanças (Deixá-la ir, "Ela voltará", reafirmação, fuga, contadores)
ficam **pendentes em memória** e vão no próximo gatilho (Save R5.3). Uma queda do
processo antes disso as perde; o pacto nunca.

**V33. Validação em `ler()` (conteúdo; a corrupção do arquivo é do Save R8).**
Cada caso corrige só a entrada afetada e nunca trava o jogo:

- chave ausente ou de tipo errado: vale o inicial da V30;
- espécie do manifesto ausente em `especies`: entra com os iniciais. Ids fora do
  manifesto nem chegam (órfãos guardados pelo Save, R9);
- espécie `obsoleta` (Save R9): carregada, mas fora da tela de dupla e do
  sorteio;
- número fora da faixa: cortado na faixa;
- `nivel` diferente de F3(`vinculo_pontos`): vale F3;
- `pactuada = false` com pontos > 0: pontos mantidos, nível 0;
- `encontros_bem_sucedidos > encontros_vistos`: corta em `encontros_vistos`;
- `ultima_dupla`: `""` é vaga vazia (Save R9); id não pactuado ou repetido sai;
  mais de 2 entradas, ficam as 2 primeiras;
- `encontro_pendente`: `""`, id Primordial ou id já pactuado (salvo Raro ainda
  em consentimento, V13) sai; mais de 1, fica o primeiro;
- nenhuma espécie pactuada com `primeiro_pacto_concedido = true`: a V3 roda de
  novo na próxima escolha da Besta.

Cada correção emite o aviso `VP-S1` no log, uma vez por chave.

#### I. Injeção

**V34. Injeção.** Recebe: `VinculoTuning`, o catálogo `CurseDef`, o estado do
perfil (vindo de `ler()`), a fonte de fluxos do RNG, os eventos de Câmaras,
Combate, Maldições, Chefes e Run, e um emissor para `pacto_registrado`. Testes
montam tudo em memória, sem disco.

### States and Transitions

**Encontro (por run):**

| Estado | Entra quando | Sai para |
|---|---|---|
| `Sem encontro` | run criada sem encontro, ou Doutrina ≠ `pactos` | — |
| `Planejado` | o sorteio da F1 decidiu índice e espécie | `Acuada` (montagem da câmara do índice) ou `Não alcançado` (a run acaba antes) |
| `Acuada` | a acuada nasce (V7); `encontros_vistos += 1` | `Aguardando` (câmara limpa com Vida > 0) ou `Fugiu` (Vida ≤ 0) |
| `Aguardando` | V9 | `Resolvido` (escolha na tela) ou `Abandonado` (fim da run sem escolha) |
| `Fugiu` | V12 | fim (a câmara segue) |
| `Resolvido` | pactuada, reafirmada, deixada ir ou "Ela voltará" | fim (`pacto_resolvido`, as portas abrem) |
| `Não alcançado` / `Abandonado` | morte ou abandono antes | fim; em `Abandonado`, `encontro_pendente = [especie]` |

**Espécie (no perfil):** `Sem pacto` → (`encontros_bem_sucedidos` suficiente e
"Oferecer", ou `pactuar` no chefe) → `Pactuada nível 1` → … → `Pactuada nível 5`.
Não há volta: o pacto não se desfaz no MVP.

**Mundo:** no hitstop, na pausa e na Transição, a acuada congela como o resto
(Maldições R15). A Vida dela só muda por golpe.

### Interactions with Other Systems

| Sistema | Entra no Vínculo | Sai do Vínculo | Dono do contrato |
|---|---|---|---|
| Maldições | `CurseDef` (raridade, `vida_max`, kit), eventos de golpe, abate e técnica por espécie | dupla da run, entrada na reserva no meio da run (V15), bônus de nível (F4) | Maldições (emenda pedida, V43) |
| Save e perfil | `ler(dados)` na carga e no reset | `escrever()`, `campos_de_ids()`, `pacto_registrado(especie_id)` | Save (formato); Vínculo (conteúdo, V30) |
| Câmaras e ondas | montagem da câmara, `camara_limpa`, ordem de nascimento | acuada a injetar (V7), alvo padrão por ordem (V8) | Câmaras (emenda pedida, V41) |
| Portas e recompensas | recompensa concedida | `pacto_resolvido` libera o passo 3 (abrir portas) | Portas (emenda pedida, V41) |
| IA de inimigos e elites | — | alvo `acuada` por inimigo (V8) | IA (emenda pedida, V44) |
| Combate núcleo | golpe de inimigo na acuada | `ferir_acuada` (sem fogo amigo, sem hitstop) | Combate (emenda pedida, V44) |
| Chefes | `chefe_subjugado(id)` | `chefe_escolhido(id, escolha)`, `escolha ∈ {pactuar, exorcizar}` | Chefes (V47) |
| RNG com seed | fluxo `pactos` (novo) | estado inicial ampliado (perfil e dupla) | RNG (emenda pedida, V40) |
| Run e regiões | Doutrina, criação da run, `run_encerrada`, vitória | tela de dupla antes da seed, `vinculo_atualizado` | Run (emenda pedida, V42) |
| Modificadores | — | fonte `vinculo` com `vida_max` `+5%` no portador da Maldição | Modificadores (emenda pedida, V43) |
| Conteúdo orientado a dados | `VinculoTuning`, `CurseDef.memorias` | — | Conteúdo (validações VP1–VP9) |
| HUD, Telas, Áudio | — | Vida da acuada, telas de consentimento, dupla e chefe; painel de vínculo na tela final | apresentação |
| Telemetria local | — | eventos `encontro_pacto`, `pacto`, `vinculo_fim_run` | Telemetria (emenda pedida, V45) |

**Contratos pedidos (resumo; ninguém edita o GDD do outro neste lote):**

- **V40. RNG com seed:** finalidade nova `pactos` (próximo id livre, proposto
  `9`), estrutura, reproduzível; chave (`pactos`, região, 0); consumo fixo de 4
  reais por run de Pactos (F1). R7: o **estado inicial** passa a incluir a dupla,
  as espécies pactuadas com nível, `encontro_pendente`,
  `primeiro_encontro_visto` e `runs_pactos_sem_encontro`. R2: em Pactos, a seed
  nasce ao confirmar a dupla.
- **V41. Câmaras e ondas + Portas e recompensas:** na câmara do encontro, a
  Câmaras injeta a acuada (V7) e passa a ordem de nascimento à IA; a acuada não
  conta na câmara limpa. As Portas ganham o passo **2b**: se há encontro em
  `Aguardando`, esperar `pacto_resolvido` antes do passo 3.
  - **(emenda Pactos, 2026-11-15) Consultas expostas:** `encontro_na_camara(indice)`
    devolve a espécie do encontro naquele índice ou vazio (Câmaras R4 passo 2b,
    `camaras-e-ondas.md:247-248`); `encontro_aguardando()` devolve verdadeiro só com
    a acuada em `Aguardando` (Portas R2-P passo 2b, R11-P). Nenhuma consome RNG.
- **V42. Run e regiões:** a Escolha de arma ganha o passo da Escolha do Pacto
  quando a arma é a Besta; `run_encerrada` chega ao Vínculo antes da tela final.
- **V43. Maldições + Modificadores:** Maldições R2 aceita a dupla crescer de 1
  para 2 no meio da run (V15); F3 ganha `× (1 + bonus_dano_basico)` só no
  `dano_basico`; F2 usa `recuperacao_exausta_s × mult_recuperacao`. Modificadores
  ganha a fonte `vinculo` (aplicada no começo da run, como a Oficina) com
  `vida_max` percentual.
- **V44. IA + Combate:** alvo padrão `acuada` por inimigo; `ferir_acuada(dano)`
  com dano inteiro, sem hitstop, sem invulnerabilidade. O Vínculo expõe
  `acuada_atingivel()` (consulta da IA e do Combate) e `falhar_encontro()`
  (chamada síncrona do Combate quando a Vida da acuada chega a 0; Combate R25,
  IA R22). O `ferir_acuada` do Combate também aplica o M do atacante (elite,
  Abalo) **[a confirmar]** (emenda de alinhamento, 2026-11-16).
- **V45. Telemetria local:** `run_iniciada.estado_inicial` ganha `pactos` e
  `dupla`; eventos novos `encontro_pacto` (`indice_camara`, `especie`,
  `resultado` ∈ {`pactuada`, `reafirmada`, `deixada`, `voltara`, `fugiu`,
  `abandonado`}, `vida_restante`), `pacto` (`especie`, `origem` ∈ {`primeiro`,
  `encontro`, `chefe`}) e `vinculo_fim_run` (por espécie da dupla: `pontos_run`,
  `vinculo_pontos`, `nivel`, `subiu_nivel`).
- **V47. Chefes:** a escolha volta por `chefe_escolhido(id, escolha)` (V18); a
  tela é aberta por Interagir no chefe ajoelhado (resposta à OQ1 de Chefes).
- **V46. Save e perfil:** a lista da V30, a interface da V31 e os gatilhos da
  V32. O nome `pacto_registrado(especie_id)` fica fixado aqui (era provisório no
  Save R5); `campos_de_ids()` ganha `encontro_pendente` além de `ultima_dupla`.

## Formulas

> Convenções: `passos(t)` é a F7 do Conteúdo (60 passos/s, `round` x,5 para longe
> do zero). DPS e TTK seguem as Maldições F3 e F6. `round` é o mesmo da F7.

### F1. Sorteio do encontro (`pact_encounter_draw`)

Ao criar uma run de Pactos, no fluxo (`pactos`, região, 0), **sempre 4 reais**
`u0, u1, u2, u3` (RNG R4b), mesmo quando há garantia:

`G1 = ¬primeiro_encontro_visto` ; `G2 = encontro_pendente ≠ []` ; `G3 = runs_pactos_sem_encontro ≥ pity_runs` ;
`ocorre = G1 ∨ G2 ∨ G3 ∨ (u0 < chance_encontro)` ;
`indice = G1 ? indices_encontro[0] : indices_encontro[floor(u1 × n_idx)]` ;
`especie = G2 ? encontro_pendente[0] : G1 ? menor_raridade(NP) : (NP ≠ ∅ ∧ (u2 < chance_nao_pactuada ∨ P = ∅)) ? pond(NP, u3) : pond(P, u3)` ;
`pond(S, u) = escolha ponderada (RNG F6) em S, na ordem do manifesto, com peso peso_raridade(raridade(e))`

`NP` = regulares não pactuadas; `P` = regulares pactuadas. Ordem de prioridade
das garantias: G2 > G1 para a espécie (o pendente sempre volta).

| Variável | Tipo | Faixa | Fonte | Descrição |
|---|---|---|---|---|
| `u0…u3` | float | [0, 1) | RNG `pactos` | 4 reais, consumo fixo |
| `chance_encontro` | float | `0,3–0,9` (MVP `0,6`) | `VinculoTuning` | chance por run sem garantia |
| `pity_runs` | int | `1–4` (MVP `2`) | `VinculoTuning` | runs seguidas sem acuada que forçam o encontro |
| `indices_encontro` | int[] | índices de combate, ~~sem 0 nem o último~~ sem 0 e `< camaras_jogaveis − 2` (nem a última câmara de combate antes do chefe; emenda Pactos, 2026-11-15) (MVP `[1, 2]`) | `VinculoTuning` | câmaras candidatas |
| `n_idx` | int | `≥ 1` | calculado | tamanho de `indices_encontro` |
| `chance_nao_pactuada` | float | `0,5–1,0` (MVP `0,75`) | `VinculoTuning` | chance de vir uma espécie nova quando existe |
| `peso_raridade` | dict | Comum 3, Refinado 2, Raro 1, Épico 1 | `VinculoTuning` | peso dentro do grupo |

**Saída:** `ocorre` bool; `indice ∈ indices_encontro`; `especie` regular.
**Taxa de encontros** com `chance_encontro = 0,6` e `pity_runs = 2`: intervalo
médio entre encontros `1 × 0,6 + 2 × 0,4 × 0,6 + 3 × 0,4² = 1,56` runs, ou
**`0,641` encontro por run** (sem contar G1 e G2).

**Exemplo:** perfil com *Vulto* e *Espreitador* pactuados, sem pendente,
`runs_pactos_sem_encontro = 0`, `u = (0,42; 0,81; 0,30; 0,55)`. `ocorre`
(`0,42 < 0,6`); `indice = indices[floor(0,81 × 2)] = 2`; `u2 = 0,30 < 0,75` e
`NP = {baluarte}` → *Baluarte de Cinza*. Com `u2 = 0,90`: grupo `P`, pesos
`3 : 2`, `u3 = 0,55 < 0,6` → *Vulto Mudo* (reafirmação).

### F2. Vida da acuada e janela de proteção (`pact_encounter_survival`)

`vida_acuada = round(vida_max_base × frac_vida_acuada)` ;
`dano_in = max(1, round(dano_inimigo × (elite ? 1,25 : 1)))` (sem redução, sem passiva) ;
`t_exposta(onda) = Vida_onda / (DPS_pactos × eficiencia)` ;
`dano_onda ≈ n_na_acuada × (dano_in / ciclo_min) × t_exposta` ;
`sobrevive ⇔ vida_acuada > Σ dano_onda`

| Variável | Tipo | Faixa | Fonte | Descrição |
|---|---|---|---|---|
| `vida_max_base` | int | `95–135` | `CurseDef` | Vida da espécie sem vínculo |
| `frac_vida_acuada` | float | `0,8–1,6` (MVP `1,2`) | `VinculoTuning` | fração da Vida da espécie na acuada |
| `n_na_acuada` | int | `ceil(n_onda / 2)` | V8 | inimigos de ordem par |
| `dano_inimigo`, `ciclo_min` | — | Eco: `9`, `1,60 s` | Maldições F7 | golpe e ciclo do Eco Perdido |
| `DPS_pactos` | float | ~~`66,5`~~ → `64,70` (emenda Pactos, 2026-11-15) | Maldições F6 com a técnica (piso) | DPS combinado de referência: Besta + *Vulto* nível 1, dupla de 1, sem técnica (`40 + 24,70`) |
| `eficiencia` | float | `0–1` | modelo | fração do DPS teórico que o jogador entrega |

**Saída:** `vida_acuada` = *Vulto* `132`, *Espreitador* `114`, *Baluarte* `162`.
**Exemplo (emenda Pactos, 2026-11-15; índice 2, p 2, 2 ondas de 4 Ecos de `33`
de Vida, Câmaras F2 e IA +5%/p, *Espreitador* acuado, jogador com o *Vulto*):**
`Vida_onda = 132`. Com `eficiencia = 0,5`: `t_exposta = 132 / 32,35 = 4,08 s`;
`dano_onda = 2 × 5,625 × 4,08 = 45,9`; duas ondas `91,8 < 114` → **sobrevive
com 22**, sem usar o Chamado. Com `eficiencia = 0,35`: `t = 5,83 s`, `65,6` por
onda, `131,2 > 114` → **foge**. O limiar é `eficiencia ≈ 0,40`
(`4 × 5,625 × 132 / (114 × 64,70)`): o jogador falha se ignorar a acuada, não
por azar. Cada Chamado que atrai os dois Ecos da acuada tira até `1,5 s` de
exposição, com respiro de `0,5 s` antes da próxima atração (Maldições R17, F4b).
No índice 1 (p 1, 3 Ecos de `31,5`): `2,92 s`, `33` de dano.
(Antes da emenda: `66,5 DPS`, `3,97 s`, sobra `24`, limiar `0,39`, atração `3,0 s`.)

### F3. Pontos e nível (`bond_points_and_level`)

`pontos_run(e) = pts_camara × C(e) + pts_abate × min(A(e), teto_abates_run) + pts_tecnica × min(T(e), teto_tecnicas_run) + pts_vitoria × V(e) + extra(e)` ;
`vinculo_pontos' = min(pontos_teto, vinculo_pontos + pontos_run)` ;
`nivel = pactuada ? 1 + #{k : vinculo_pontos ≥ limiares_nivel[k]} : 0`

| Variável | Tipo | Faixa | Fonte | Descrição |
|---|---|---|---|---|
| `C(e)` | int | `0–6` | runtime | câmaras de combate e chefe limpas em que `e` acertou |
| `A(e)` | int | `≥ 0` | runtime | abates de golpes de `e` |
| `T(e)` | int | `≥ 0` | runtime | técnicas com acerto em que `e` participou |
| `V(e)` | int | `0–1` | runtime | vitória com `e` na dupla |
| `extra(e)` | int | `0, 6, 10, 16` | V11, V18 | reafirmação e pactuar no chefe |
| `pts_camara`, `pts_abate`, `pts_tecnica`, `pts_vitoria` | int | ver tabela | `VinculoTuning` | 2, 1, 1, 8 |
| `limiares_nivel` | int[4] | crescente | `VinculoTuning` | `[20, 50, 90, 140]` |
| `pontos_teto` | int | `≥ 140` (MVP `9 999`) | `VinculoTuning` | teto do inteiro |

**Saída:** `pontos_run ∈ [0, 54]` (máximo: `12 + 12 + 6 + 8 + 6 + 10`); `nivel ∈ {0} ∪ [1, 5]`.

| Run (estimativa por espécie da dupla) | C | A | T | V | Pontos |
|---|---|---|---|---|---|
| Vitória típica | 6 | 6 | 4 | 1 | **30** |
| Morte típica no índice 4 | 4 | 4 | 3 | 0 | **15** |
| Teto sem extras | 6 | 12 | 6 | 1 | **38** |

Média 50/50 = `22,5` por run. **Até o nível 5:** `140 / 22,5 ≈ 6,2` → 7 runs
típicas com a espécie; no teto, `ceil(140 / 38) = 4` runs. O nível 2 vem em uma
vitória típica (`30 ≥ 20`). Sem zona morta longa: o maior intervalo entre
níveis é `50` pontos (4 → 5), cerca de 2 vitórias.

### F4. Bônus de nível, ML5 e paridade de TTK (`bond_level_bonus_parity`)

`vida_max_v = round(vida_max × (1 + (nivel ≥ 2 ? bonus_vida : 0)))` ;
`passos_exausta_v = passos(recuperacao_exausta_s_especie × (nivel ≥ 3 ? mult_recuperacao : 1))` ;
`dano_basico_v = dano_basico × (1 + (nivel ≥ 4 ? bonus_dano_basico : 0))` ;
`DPS_autonomo_v = ((dano_basico_v + dano_extra_ciclo) × M × 60) / C_atk` (Maldições F3) ;
`DPS_pactos_v = DPS_besta + f_campo_atk × DPS_autonomo_v + dano_chamado × 60 / R_esp` (Maldições F6) ;
`DPS_teto_v = DPS_pactos_v + D_tecnica_max / recarga_troca_s` ;
`paridade(x) = |TTK_x − TTK_ref| / min(TTK_x, TTK_ref)` para `ref ∈ {lamina, ressonancia}`

| Variável | Tipo | Faixa | Fonte | Descrição |
|---|---|---|---|---|
| `bonus_vida` | float | `0–0,055` (MVP `0,05`) | `VinculoTuning` | teto pelo ML5 de Vida |
| `mult_recuperacao` | float | `0,80–1,0` (MVP `0,90`) | `VinculoTuning` | encurta a Exaustão |
| `bonus_dano_basico` | float | ~~`0–0,12`~~ → `0–0,07` (MVP `0,05`) (emenda Pactos, 2026-11-15) **[a confirmar]** | `VinculoTuning` | teto pela paridade com técnica (`≤ 0,076`); o ML5 de DPS (`0,127`) deixou de ser o limite |
| `f_campo_atk` | float | `0,9` | Maldições F6 | `(120 − 12) / 120` |
| `DPS_besta`, `dano_chamado × 60 / R_esp` | float | `40,0`; `8,5` | Maldições F6 | parcelas fixas, que o vínculo não toca |
| `D_tecnica_max` | float | ~~`28`~~ → `14` (emenda Pactos, 2026-11-15) | Maldições F5 e Catálogo (R18) | Saída que controla (`5`) + Entrada com sinergia (`6 × 1,5 = 9`) |
| `recarga_troca_s` | float | `4,0` | Maldições Tuning | o vínculo não muda |
| `TTK_lamina`, `TTK_ressonancia` | float | `10,531`; `10,454` s | Maldições F6 | referências a 700 HP (`66,47`; `66,96 DPS`) |
| `meta_paridade_pactos` | float | `0,05` | `MaldicoesTuning` (Maldições F6 com a técnica) | meta da Doutrina; faixa permitida `63,77–69,79 DPS` |

**Vida (nível ≥ 2):** *Vulto* `116`, *Espreitador* `100`, *Baluarte* `142`,
*Soberano* `126`. **Exaustão (nível ≥ 3):** `540` passos (`9,0 s`); *Soberano*
`passos(8,0 × 0,9) = 432` (`7,2 s`).

**Valores da emenda Pactos (2026-11-15).** A Maldições R18 cortou `10%` do
ataque básico (`9` / `7,65` / `12,6` / `9,8`; F3: `18,00–18,36 DPS`), a Saída
para `5` e a Entrada para `6` (`9` com sinergia) ou `7`; `D_tecnica_max = 14`
(F5). A F6 passou a contar a técnica, com meta `±5%`
(`meta_paridade_pactos = 0,05`). As tabelas abaixo usam esses valores. As
antigas (base `20,00–20,40 DPS`, técnica `28`, meta `15%`) ficam registradas no
fim desta seção.

**Prova do ML5 (pior mistura de níveis na mesma dupla):**
- Vida: `142 (Baluarte nível 5) / 95 (Espreitador nível 1) = 1,495 ≤ 1,50` ✓.
  (Com `bonus_vida = 0,056` daria `143 / 95 = 1,505`: por isso o teto `0,055`.)
- DPS: `18,36 × 1,05 / 18,00 = 19,28 / 18,00 = 1,071 ≤ 1,15` ✓ (igual à
  Maldições F3, emenda).

**Prova da paridade no nível 5, sem técnica (Maldições F6, M = 1, 700 HP):**

| Espécie no nível 5 | `dano_basico_v` | `DPS_autonomo_v` | Maldição + Chamado | `DPS_pactos_v` | TTK | p/ Lâmina | p/ Ressonância |
|---|---|---|---|---|---|---|---|
| *Vulto* / *Baluarte* | `9,45` / `13,23` | `18,90` | `0,9 × 18,90 + 8,5 = 25,51` | `65,51` | `10,685 s` | `1,47%` | `2,21%` |
| *Espreitador* | `8,0325` | `19,28` | `25,85` | `65,85` | `10,630 s` | `0,94%` | `1,69%` |
| *Soberano* | `10,29` | `(10,29 + 1) × 60 / 36 = 18,82` | `25,44` | `65,44` | `10,697 s` | `1,57%` | **`2,32%`** |

Sem técnica, Pactos fica **abaixo** das duas referências. No nível 1 o piso é
`64,70 DPS` (`3,49%` p/ Ressonância, Maldições F6); o vínculo **aproxima** a
Doutrina da paridade (`3,49% → 2,21%` no *Vulto*).

**Prova da paridade no nível 5, com técnica a cada recarga (teto, Maldições F6
com a técnica):** `DPS_tecnica = 14 / 4,0 = 3,50`.

| Caso (`M = 1`, 700 HP) | Besta | Maldição + Chamado | Técnica | Total | TTK | Paridade (pior ref) |
|---|---|---|---|---|---|---|
| Teto base, *Espreitador* nível 1 | `40,00` | `25,02` | `3,50` | `68,52` | `10,215 s` | `3,09%` (Lâmina) |
| Teto nível 5, *Vulto* / *Baluarte* | `40,00` | `25,51` | `3,50` | `69,01` | `10,143 s` | `3,82%` (Lâmina) |
| Teto nível 5, *Soberano* | `40,00` | `25,44` | `3,50` | `68,94` | `10,154 s` | `3,72%` (Lâmina) |
| **Teto nível 5, *Espreitador*** | `40,00` | `25,85` | `3,50` | **`69,35`** | `10,094 s` | **`4,33%`** (Lâmina) |

Pior caso **`4,33% ≤ 5%`** ✓ (`meta_paridade_pactos`), igual à Maldições F6
com a técnica. O vínculo soma `1,24` ponto percentual ao teto
(`3,09% → 4,33%`). **Margem: `0,67` ponto.** Por isso a regra V19 proíbe
vínculo na técnica, no Chamado e na recarga da troca.

**Teto do `bonus_dano_basico` pela paridade:** `DPS_teto ≤ 66,47 × 1,05 =
69,79` → `DPS_autonomo_v(Espreitador) ≤ (69,79 − 40 − 8,5 − 3,5) / 0,9 =
19,77` → `bonus_dano_basico ≤ 19,77 / 18,36 − 1 = 0,077`. A faixa de design
passa a `0–0,07` **[a confirmar]**. Com `0,08`: `69,85 DPS` → `5,08%` → aviso
VP7.

**Registro (antes da emenda, meta `15%`):** nível 5 sem técnica `67,33–67,78
DPS`, pior `1,96%`; teto com técnica `28` a cada `4,0 s`: base `73,86 DPS`
(`11,11%`), nível 5 `74,78 DPS` (`12,49%`). O achado "a F6 não conta a técnica"
foi resolvido pela Maldições F6 com a técnica (OQ3 fechada).

### F5. Memórias reveladas (`bond_memories_revealed`)

`n_mem = memorias_por_raridade(raridade)` ;
`reveladas = min(n_mem, max(encontros_vistos, pactuada ? 1 : 0) + (nivel ≥ nivel_max ? 1 : 0))`

| Variável | Tipo | Faixa | Fonte | Descrição |
|---|---|---|---|---|
| `memorias_por_raridade` | dict | Comum 1, Refinado 2, Raro 3, Épico 4, Primordial 4 | `VinculoTuning` | igual a `len(CurseDef.memorias)` (VP7) |

**Exemplo:** *Baluarte* com 1 encontro visto, sem pacto → 1; 2 encontros e pacto
→ 2; nível 5 → 3 (todas). *Vulto* concedido na V3 (0 encontros) → 1.

### Tabela consolidada: `VinculoTuning` (`assets/data/tuning/vinculo_tuning.tres`)

| Campo | Valor MVP | Faixa de design | Categoria | Papel |
|---|---|---|---|---|
| `especie_primeiro_pacto` | `vulto_mudo` | id Comum regular | gate | V3 |
| `chance_encontro` | 0,6 | 0,3–0,9 | gate | F1 |
| `pity_runs` | 2 | 1–4 | gate | F1 (G3) |
| `indices_encontro` | [1, 2] | índices de combate, ~~sem 0 nem o último~~ sem 0 e `< camaras_jogaveis − 2` (emenda Pactos, 2026-11-15) | gate | V6 |
| `chance_nao_pactuada` | 0,75 | 0,5–1,0 | curva | F1 |
| `peso_raridade` | 3 / 2 / 1 / 1 | 1–6 cada | curva | F1 |
| `pontos_acuada` | 5 pontos (V7) | dentro de `[270; 1650] × [255; 765]` | feel | V7 |
| `frac_vida_acuada` | 1,2 | 0,8–1,6 | feel | F2 |
| `encontros_para_consentir` | 1 / 1 / 2 / 2 / 1 | 1–3 | gate | V13 |
| `pts_camara` / `pts_abate` / `pts_tecnica` / `pts_vitoria` | 2 / 1 / 1 / 8 | 1–4 / 1–2 / 1–3 / 4–15 | curva | F3 |
| `teto_abates_run` / `teto_tecnicas_run` | 12 / 6 | 6–20 / 3–10 | curva | F3 |
| `pts_reafirmar` / `pts_reafirmar_chefe` | 6 / 10 | 3–12 / 5–20 | curva | V11, V18 |
| `limiares_nivel` | [20, 50, 90, 140] | crescente, último 80–300 | curva | F3 |
| `nivel_max` | 5 | fixo no MVP (= 1 + tamanho de `limiares_nivel`) | — | V19 |
| `pontos_teto` | 9 999 | ≥ último limiar | gate | F3 |
| `bonus_vida` | 0,05 | 0–0,055 | curva | F4 |
| `mult_recuperacao` | 0,90 | 0,80–1,0 | feel | F4 |
| `bonus_dano_basico` | 0,05 | ~~0–0,12~~ → 0–0,07 (emenda Pactos, 2026-11-15) **[a confirmar]** | curva | F4 (teto pela paridade com técnica) |
| `memorias_por_raridade` | 1 / 2 / 3 / 4 / 4 | 1–6 | — | F5 |

### Validações (`VP1`–`VP9`, no Conteúdo orientado a dados)

| Código | Nível | Condição | Protege |
|---|---|---|---|
| VP1 | erro | `limiares_nivel` vazio, não estritamente crescente ou com valor ≤ 0 | F3 sem níveis |
| VP2 | erro | `especie_primeiro_pacto` não é `CurseDef` Comum regular | primeira run sem Maldição |
| VP3 | erro | `indices_encontro` vazio, com índice que não é de combate, com o índice 0 ou com ~~a última câmara jogável~~ índice `≥ camaras_jogaveis − 2` (a última câmara de combate antes do chefe e o chefe; emenda Pactos, 2026-11-15) | encontro no santuário, no chefe ou na câmara ~~sem portas~~ que abre a porta forçada `chefe` |
| VP4 | erro | `chance_*` fora de [0, 1], `frac_vida_acuada ≤ 0`, `pity_runs < 1`, `encontros_para_consentir < 1` ou peso < 0 | sorteio sem sentido |
| VP5 | aviso (2ª passada) | `round(max(vida_max) × (1 + bonus_vida)) / min(vida_max) > 1,50` ou `max(DPS) × (1 + bonus_dano_basico) / min(DPS) > 1,15` | ML5 com o vínculo |
| VP6 | aviso (2ª passada) | F4: paridade no nível máximo, sem técnica, `> meta_paridade_pactos` (`0,05`; antes `0,15`, emenda Pactos, 2026-11-15) contra Lâmina ou Ressonância | ML8 com o vínculo |
| VP7 | aviso (2ª passada) | `len(CurseDef.memorias) ≠ memorias_por_raridade(raridade)` ou F4: teto com técnica `> meta_paridade_pactos` (`0,05`; antes `0,15`, emenda Pactos, 2026-11-15) | F5 e margem de poder |
| VP8 | erro | o manifesto não tem nenhuma espécie regular além da do primeiro pacto | encontro sem espécie |
| VP9 | aviso | campo fora da faixa de design | as contas deste GDD deixam de valer |

## Edge Cases

**Encontro**
- **Se o jogador morrer na câmara do encontro com a acuada viva:** a run acaba
  (morte vence, Run R5); o encontro fica `Não alcançado` ou `Abandonado`
  (`encontro_pendente = [especie]`); `encontros_vistos` já contou.
- **Se a acuada e o último inimigo caírem no mesmo passo:** a Vida da acuada é
  avaliada antes da câmara limpa (o golpe resolve no item do Combate, a limpeza
  no item 10 das Câmaras, Combate R1). Vida ≤ 0 → `Fugiu`; a câmara limpa sem
  encontro.
- **Se um inimigo atraído pela Maldição em campo bater na acuada:** não acontece;
  o golpe só testa o seu alvo (V8).
- **Se a acuada nascer onde há uma pedra em todos os 5 pontos:** vale o último
  ponto (`(960; 720)`); ela não colide com nada e pode se sobrepor visualmente.
  Com no máximo 4 pedras de raio ≤ 79,5 e 5 pontos afastados ≥ 180 px, é raro.
- **Se a onda tiver 1 inimigo só:** ordem 0 → mira a acuada; o jogador não é
  alvo naquela onda (só a acuada corre risco).
- **Se a câmara do encontro sortear elite (p ≥ 3, IA):** não ocorre no MVP
  (índices 1 e 2 têm p 1 e 2). Se `indices_encontro` incluir p ≥ 3, `dano_in` usa
  `× 1,25` (F2).
- **Se a Bênção abrir na limpeza da câmara do encontro:** ela vem primeiro (V9);
  a acuada espera em `Aguardando`; as portas só abrem depois de
  `pacto_resolvido`.
- **Se o jogador sair do jogo em `Aguardando`:** V20b; `encontro_pendente =
  [especie]`; ela volta garantida.
- **Se o encontro sorteado for numa câmara que a run não alcança:** `Não
  alcançado`; `runs_pactos_sem_encontro += 1`; G3 garante depois.
- **Se `encontro_pendente` aponta para espécie que virou `obsoleta`:** sai na
  validação (V33); o sorteio segue normal.
- **Se todas as regulares estão pactuadas:** grupo `P` sempre (F1); o encontro é
  reafirmação. Se um dia não houver regular nenhuma (catálogo de teste): VP8.

**Dupla e pacto**
- **Se o jogador pactuar a 2ª espécie no meio da primeira run:** entra na reserva
  agora (V15), com `Vida = min(Vida_acuada, vida_max)`; a técnica fica possível
  na hora; pontos contam daí em diante.
- **Se a reserva entra na run (V15) enquanto a de campo está `Exausta`:** a nova
  entra direto em campo pela troca automática (Maldições R9), sem técnica.
- **Se `ultima_dupla` tiver uma espécie que deixou de existir:** o Save troca por
  `""` (Save R9); a tela não pré-seleciona aquela vaga.
- **Se o jogador tentar pôr a mesma espécie duas vezes:** a tela não deixa (V16).
- **Se o *Soberano* já pactuado estiver na dupla e o jogador pactuar de novo no
  chefe:** V18.4 (ou V18.5 no nível 5). A forma aliada luta e a forma de chefe é
  enfrentada (Chefes, Edge Cases).
- **Se um pacto for feito e a run terminar em morte:** o pacto vale (V18); os
  pontos da run também (V20).

**Pontos e perfil**
- **Se `vinculo_pontos` chegar a `pontos_teto`:** corta no teto; o nível já é 5.
- **Se uma espécie subir dois níveis numa run:** a tela final mostra os dois; os
  ganhos valem na próxima run (V19).
- **Se a técnica acertar só com a Saída (a Entrada erra):** conta para as duas
  (a técnica acertou ≥ 1 inimigo).
- **Se um abate vier de um status aplicado pela Maldição:** no MVP a Maldição não
  aplica dano por status próprio; o Abalo não mata. Só golpe direto conta.
- **Se os lacaios do chefe forem limpos pela queda dele:** não contam abates
  (Chefes R8), nem para o vínculo.
- **Se o perfil vier vazio (primeira execução, corrompido ou versão futura):**
  `ler({})`; tudo no inicial; na próxima escolha da Besta a V3 roda. Em versão
  futura o Save não grava (Save R8): os pactos da sessão valem até fechar.
- **Se `nivel` gravado for 7:** F3 recalcula; `VP-S1` no log.
- **Se a run for de outra Doutrina:** nada muda no perfil (V21).

## Dependencies

### Depends On (Upstream)

| Sistema | Força | O que vem de lá | Sem ele |
|---|---|---|---|
| Maldições | Forte | `CurseDef` (raridade, `vida_max`, kit), eventos de golpe, abate e técnica por espécie | nada a pactuar |
| Save e perfil | Forte, por contrato | `ler(dados)` na carga e no reset; gravação nos gatilhos | vínculo só em memória na sessão |
| Câmaras e ondas | Forte, por contrato (V41) | montagem, ordem de nascimento, `camara_limpa` | sem lugar para a acuada |
| Portas e recompensas | Forte, por contrato (V41) | passo 2b: espera `pacto_resolvido` | o jogador sairia sem resolver |
| IA de inimigos e elites | Forte, por contrato (V44) | alvo padrão `acuada` | ninguém atacaria a acuada |
| Combate núcleo | Forte, por contrato (V44) | `ferir_acuada`, ordem dos itens do passo | a acuada não perde Vida |
| Chefes | Forte | `chefe_subjugado(id)` | sem pacto com a Primordial |
| RNG com seed | Forte, por contrato (V40) | fluxo `pactos` | encontro não reproduzível |
| Run e regiões | Forte, por contrato (V42, V16b) | Doutrina, `pedir_dupla()`, `run_encerrada`, vitória | sem começo nem fim de run |
| Modificadores e atributos | Suave, por contrato (V43) | fonte `vinculo` | sem bônus de Vida |
| Conteúdo orientado a dados | Forte | `VinculoTuning`, `CurseDef.memorias`, VP1–VP9 | números no código |

### Depended On By (Downstream)

| Sistema | Força | O que recebe |
|---|---|---|
| Maldições | Forte | espécies pactuadas, dupla, entrada na reserva no meio da run, bônus de nível (Maldições R2, R16, Interactions) |
| Chefes | Forte | `chefe_escolhido(id, escolha)` (Chefes R9, F6) |
| Save e perfil | Forte | `escrever()`, `campos_de_ids()`, `pacto_registrado(especie_id)` (Save R3, R5) |
| Run e regiões | Forte | `dupla_confirmada(campo, reserva)`, `chefe_escolhido`, `vinculo_atualizado` |
| Portas e recompensas | Forte | `pacto_resolvido` |
| HUD, telas e Áudio | Suave | Vida da acuada, telas, painel de vínculo |
| Telemetria local | Suave | `encontro_pacto`, `pacto`, `vinculo_fim_run`, estado inicial ampliado |
| Rito de Iniciação (Vertical Slice) | Suave | assume a V3 |

**Bidirecionalidade:** ~~Maldições, Chefes e Save já citam este GDD. Câmaras,
Portas, IA, Combate, RNG, Run, Modificadores e Telemetria ainda não: recebem as
emendas V40–V45.~~ (emenda Pactos, 2026-11-15) Maldições, Chefes, Save, Câmaras,
Portas, RNG, Run e Telemetria já citam este GDD. IA, Combate e Modificadores
ainda recebem as emendas V43–V45.

## Visual/Audio Requirements

- **VP-V1. Acuada (Art Bible §3.3, §4.3):** silhueta da forma aliada da espécie,
  encolhida, em Tinta com as amarras de Osso **soltas ou partidas**. Sem
  Magenta (não é perigo) e sem fio de vínculo (ainda não há pacto). Respiração
  curta em loop.
- **VP-V2. Vida da acuada:** barra compacta em Osso acima dela (`96 × 6 px`),
  distinta do fio de Vida dos inimigos (HUD R9). Flash em Osso por `4` passos a
  cada golpe recebido, como a Maldição (ML-V5).
- **VP-V3. Fuga:** ela se dissolve numa fenda de Tinta no chão em `12` passos;
  sem partícula dourada nem Magenta.
- **VP-V4. Consentimento:** ao "Oferecer o vínculo", o fio de Osso nasce do peito
  do Iniciado até ela e as amarras se fecham (`30` passos), antes da tela fechar.
- **VP-V5. Níveis:** cada nível acrescenta um nó na amarra do cartão. No nível 5,
  a amarra completa aparece também na silhueta em campo (decisão final do
  `art-director`).
- **VP-A1. Ganchos de áudio:** `pacto_acuada_surge`, `pacto_acuada_ferida`
  (máximo 1 a cada 4 passos), `pacto_acuada_foge`, `pacto_consentimento`,
  `pacto_selado`, `pacto_reafirmado`, `vinculo_nivel_sobe`.

## Game Feel

- **Proteger, não escoltar.** A acuada não anda: o jogador nunca a guia. A
  pergunta da câmara é "quem eu mato primeiro e para onde puxo as Anomalias", e
  o Chamado (que atrai) vira a ferramenta de proteção. O fardo é repartido
  entre o jogador e a própria Maldição.
- **Falha que não pune.** Ela foge, não morre, e volta garantida (V12). O custo é
  uma run, nunca o pacto.
- **Um momento de calma.** A tela de consentimento abre fora de combate e para o
  mundo. É o único instante da run sem pressa: o pacto deve parecer um gesto, não
  um saque.
- **Crescimento que se nota pouco e se sente.** `+5%` de Vida e de dano não
  mudam o combate; a Exaustão mais curta e a amarra no cartão mostram que "a
  gente já lutou junto". A recompensa principal do vínculo é a memória.

## UI Requirements

- **Tela "Escolha do Pacto" (V16, estado Menus):** cartões das espécies
  pactuadas (nome, raridade em texto e ícone, nível, barra de pontos até o
  próximo nível, kit em 3–5 linhas, memórias reveladas). Dois slots, "Campo" e
  "Reserva". Teclado, mouse e gamepad. Confirmar e Voltar. Pulada com 0 ou 1
  pactuada (V16b).
- **Cartão "O Primeiro Vínculo" (V3):** ilustração da espécie, 2–3 linhas de
  texto e "Aceitar".
- **Prompt Interagir (V9, V18):** o mesmo das portas, com o rótulo do bind
  (`rotulo_acao("interagir")`).
- **Tela de consentimento (V10, V11; fora de Jogo):** nome, raridade, memória
  revelada nesta vez, e os botões do caso: "Oferecer o vínculo" / "Deixá-la ir",
  "Reafirmar o vínculo (+6)" / "Deixá-la ir", ou só "Ela voltará". Sem tempo
  limite.
- **Tela Pactuar / Exorcizar (V18; fora de Jogo):** preço à vista ("Pactuar: 0
  Fragmentos" e o ganho de vínculo do caso; "Exorcizar: +6 Fragmentos"). No caso
  V18.5, mostra para quem vão os pontos ou "O vínculo já está inteiro".
- **Painel de vínculo na tela final:** por espécie da dupla, pontos da run por
  fonte, barra animada e "Nível N!" quando sobe.
- **Acessibilidade:** raridade e estado nunca só por cor; texto em todos os
  botões; barras com número (`114/114`).

## Cross-References

- [maldicoes.md](maldicoes.md) (R2 dupla, R3 raridade, R6 abates, R7 alvo, R12 técnica, R16 Primordial; F3, F6 e ML5/ML8)
- [chefes.md](chefes.md) (R9 `Subjugado`, F6, OQ1)
- [save-e-perfil.md](save-e-perfil.md) (R3 seção opaca, R5 gatilhos e ponto seguro, R9 ids, R10 saída)
- [camaras-e-ondas.md](camaras-e-ondas.md) (R1, R4, R7, R9–R13)
- [portas-e-recompensas.md](portas-e-recompensas.md) (R1, R2, R6, R7; F3)
- [run-e-regioes.md](run-e-regioes.md) (R2, R4–R8)
- [rng-com-seed.md](rng-com-seed.md) (R3, R4b, R7; F6)
- [economia-de-fragmentos.md](economia-de-fragmentos.md) (F3 renda por run)
- [telemetria-local.md](telemetria-local.md) (R4 eventos)
- [game-concept.md](game-concept.md) (§2–3 pilares, §6 Pactos, §13b co-op)
- Cânone (só leitura): `FRENTE4_Tradicoes_e_Reconciliacao.md` §1.5 e §2.2; `LORE_Sombra_Muda_e_Cidade_da_Cratera.md` §1

## Acceptance Criteria

- **AC-VP-01 (V3):** **GIVEN** perfil vazio, **WHEN** o jogador confirma a Besta,
  **THEN** `vulto_mudo` fica `pactuada = true`, `nivel = 1`, `vinculo_pontos = 0`,
  `primeiro_pacto_concedido = true`, sai `pacto_registrado("vulto_mudo")` uma vez
  e a Run recebe `dupla_confirmada("vulto_mudo", "")` sem abrir a tela de dupla.
- **AC-VP-02 (V5, V21):** **GIVEN** uma run com a Lâmina, **WHEN** ela corre
  inteira, **THEN** o fluxo `pactos` não é pedido, nenhuma acuada nasce e
  `escrever()` devolve o mesmo dicionário de antes.
- **AC-VP-03 (F1, G1):** **GIVEN** `primeiro_encontro_visto = false` e só o
  *Vulto* pactuado, **WHEN** a run de Pactos é criada com qualquer seed, **THEN**
  o encontro é planejado no índice 1 com `espreitador_da_fenda` e o fluxo
  `pactos` avançou exatamente 4 reais.
- **AC-VP-04 (F1, consumo fixo):** **GIVEN** duas runs com a mesma seed e perfis
  que diferem só em `encontro_pendente`, **WHEN** o sorteio roda, **THEN** os 4
  reais consumidos são iguais nas duas e o estado do fluxo depois é igual.
- **AC-VP-05 (F1, exemplo):** **GIVEN** a fonte falsa com `u = (0,42; 0,81;
  0,30; 0,55)` e *Vulto* + *Espreitador* pactuados, sem garantia, **WHEN** o
  sorteio roda, **THEN** `ocorre`, índice 2, espécie `baluarte_de_cinza`; com
  `u2 = 0,90`, espécie `vulto_mudo`.
- **AC-VP-06 (F1, G3):** **GIVEN** `runs_pactos_sem_encontro = 2` e `u0 = 0,99`,
  **WHEN** o sorteio roda, **THEN** `ocorre = true`.
- **AC-VP-07 (V7, F2):** **GIVEN** o encontro com `espreitador_da_fenda` e
  nenhuma pedra em `(960; 540)`, **WHEN** a câmara monta, **THEN** a acuada nasce
  em `(960; 540)` com `Vida = 114`, `encontros_vistos` da espécie sobe 1 e
  `primeiro_encontro_visto = true`.
- **AC-VP-08 (V7, sem fogo amigo):** **GIVEN** a acuada com `Vida = 114` e um
  inimigo encostado nela, **WHEN** o jogador dispara Virote, Selo e Chamado na
  área, **THEN** a Vida da acuada continua `114`.
- **AC-VP-09 (V8):** **GIVEN** uma onda de 3 Ecos na câmara do encontro, **WHEN**
  nascem, **THEN** os de ordem 0 e 2 miram a acuada e o de ordem 1 mira o
  jogador; um golpe do Eco 0 com o jogador dentro da forma fere só a acuada.
- **AC-VP-10 (V8, atração):** **GIVEN** o Eco 0 mirando a acuada, **WHEN** o
  Chamado o atrai por `180` passos, **THEN** ele mira a Maldição em campo nesse
  tempo e volta a mirar a acuada no passo 181.
- **AC-VP-11 (V12):** **GIVEN** a acuada com `Vida = 5`, **WHEN** um Eco causa
  `9`, **THEN** ela passa a `Fugiu`, sai em 12 passos, os inimigos que a miravam
  passam a mirar o jogador no mesmo passo, `encontro_pendente = [especie]`, e a
  câmara limpa e abre portas sem esperar `pacto_resolvido`.
- **AC-VP-12 (V9, Portas 2b):** **GIVEN** a câmara do encontro limpa com a
  acuada viva e recompensa de bênção, **WHEN** a Tela de bênção fecha, **THEN**
  as portas continuam fechadas até a escolha na tela de consentimento.
- **AC-VP-13 (V10):** **GIVEN** `espreitador_da_fenda` não pactuado em
  `Aguardando`, **WHEN** o jogador interage e escolhe "Oferecer o vínculo",
  **THEN** `pactuada = true`, `nivel = 1`, `encontros_bem_sucedidos = 1`, sai
  `pacto_registrado("espreitador_da_fenda")`, o Save grava no mesmo ponto seguro
  (tela fora de Jogo) e as portas abrem.
- **AC-VP-14 (V13):** **GIVEN** `baluarte_de_cinza` com
  `encontros_bem_sucedidos = 0`, **WHEN** o encontro termina com sucesso, **THEN**
  a tela mostra só "Ela voltará", `encontros_bem_sucedidos = 1`,
  `encontro_pendente = ["baluarte_de_cinza"]`, sem pacto; na próxima run de
  Pactos o sorteio planeja o *Baluarte*; e no 2º sucesso a tela oferece o vínculo.
- **AC-VP-15 (V15):** **GIVEN** a dupla da run só com `vulto_mudo` e a acuada
  `espreitador_da_fenda` com `Vida = 80`, **WHEN** o jogador pactua, **THEN** o
  *Espreitador* entra na reserva `Pronta` com `Vida = 80/95`, e a ação Troca passa
  a ser aceita quando a recarga é 0.
- **AC-VP-16 (V17, F3):** **GIVEN** uma espécie da dupla que, numa vitória,
  acertou em 6 câmaras, fez 15 abates e 7 técnicas, **WHEN** a run fecha, **THEN**
  `pontos_run = 12 + 12 + 6 + 8 = 38`.
- **AC-VP-17 (F3, níveis):** **GIVEN** `vinculo_pontos = 19`, nível 1, **WHEN** a
  run soma `pontos_run = 31`, **THEN** `vinculo_pontos = 50` e `nivel = 3`.
- **AC-VP-18 (V20, morte):** **GIVEN** uma run de Pactos com `pontos_run = 15`
  para o *Vulto*, **WHEN** o jogador morre, **THEN** os 15 pontos são somados,
  `runs_pactos_iniciadas += 1` e o Save grava no gatilho "Fim da run".
- **AC-VP-19 (V20b):** **GIVEN** uma run de Pactos ativa com `pontos_run = 9` e
  um encontro em `Aguardando`, **WHEN** o jogador sai pelo menu, **THEN**
  `escrever()` já traz os 9 pontos somados (sem `pts_vitoria`) e
  `encontro_pendente = [especie]`.
- **AC-VP-20 (F4):** **GIVEN** `baluarte_de_cinza` no nível 5, **WHEN** a run
  começa, **THEN** `vida_max = 142`, Exaustão de `540` passos e ataque básico de
  `13,23` de dano (`12,6 × 1,05`, emenda Pactos, 2026-11-15; antes `14,7`);
  Chamado, Efeitos (Saída `5`, Entrada `7`) e recarga da troca iguais à base.
- **AC-VP-21 (F4, VP5, VP6, VP7) (emenda Pactos, 2026-11-15):** **GIVEN** o
  catálogo do MVP e o `VinculoTuning` padrão, **WHEN** a 2ª passada do validador
  roda, **THEN** zero avisos VP5, VP6 e VP7 (Vida `1,495`, DPS `1,071`, paridade
  sem técnica `2,32%`, teto com técnica `4,33%`); com `bonus_vida = 0,06`, sai
  VP5; com `bonus_dano_basico = 0,08`, sai VP7 (`5,08%`).
- **AC-VP-22 (V18):** **GIVEN** o chefe em `Subjugado` e o *Soberano* não
  pactuado, **WHEN** o jogador interage e escolhe Pactuar, **THEN** a espécie fica
  `pactuada`, nível 1, sai `pacto_registrado("soberano_do_limiar")` e
  `chefe_escolhido("soberano_do_limiar", "pactuar")`, e o Chefes credita 0.
- **AC-VP-23 (V18.5):** **GIVEN** o *Soberano* no nível 5 e a dupla *Vulto*
  (nível 2) e *Espreitador* (nível 5), **WHEN** o jogador escolhe Pactuar,
  **THEN** o *Vulto* ganha 10 pontos da run e os 10 do *Espreitador* vão para o
  *Baluarte* (menor nível fora da dupla).
- **AC-VP-24 (V31, V33):** **GIVEN** `ler()` com `nivel = 7` e
  `vinculo_pontos = 55` numa espécie pactuada e `ultima_dupla = ["vulto_mudo",
  "vulto_mudo"]`, **WHEN** carrega, **THEN** `nivel = 3`, `ultima_dupla =
  ["vulto_mudo"]`, dois avisos `VP-S1`, e `escrever()` só tem `bool`, `int`,
  `String`, `Array` e `Dictionary`, com as espécies na ordem do manifesto.
- **AC-VP-25 (V31):** **GIVEN** o Vínculo, **WHEN** o Save chama
  `campos_de_ids()`, **THEN** recebe `["ultima_dupla", "encontro_pendente"]`.
- **AC-VP-26 (experiencial, playtest):** em 5 playtesters na primeira run de
  Pactos, pelo menos 4 protegem o *Espreitador* na 1ª tentativa e descrevem o
  pacto como "conquistado"; nenhum diz que a acuada caiu "sem chance". Se falhar,
  ajustar `frac_vida_acuada` (F2).

## Open Questions

1. **OQ1 — Preço do pacto de campo (P2).** O pacto no encontro custa só o risco.
   Precisa de um preço visível (por exemplo, a câmara do encontro não pagar a
   recompensa da porta)? Hoje: não.
2. **OQ2 — Testemunha nos pactos de campo.** O cânone exige testemunha de outro
   Portador na iniciação (FRENTE4 §1.5). Quem testemunha um pacto na Beira? Para
   o `narrative-director` (texto, sem mecânica).
3. ~~**OQ3 — Técnica fora da F6 das Maldições.**~~ **Fechada (emenda Pactos,
   2026-11-15):** a Maldições F6 passou a contar a técnica (`D_tecnica_max = 14`,
   meta `±5%`). Teto no nível 5: `4,33%` (F4).
4. **OQ4 — Os Que Ficam (cânone):** a Tradição diz que trocar de par reinicia o
   acúmulo. Aqui o vínculo nunca se perde (P4). Confirmar que a regra fica só
   como texto.
5. **OQ5 — Co-op (§13b):** em co-op, cada jogador de Pactos tem o seu encontro, ou
   a acuada é única e consente a quem a protegeu mais?
6. **OQ6 — Mais níveis no Vertical Slice:** `limiares_nivel` cresce; o que os
   níveis 6+ dão sem furar o ML5 e a margem de `0,67` ponto da F4 (emenda
   Pactos, 2026-11-15; antes `2,5`)? Com essa margem, níveis 6+ só podem dar
   qualidade ou lore, não dano.
7. **OQ7 — Índice 4 como candidato:** abrir `indices_encontro` para p 3 (2 ondas,
   elites possíveis) depois do playtest da F2?
