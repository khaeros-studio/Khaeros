# Chefes (MVP: Maldição-chefe do Limiar)

> **Status**: Approved
> **Author**: usuário + Claude (aba de Design, modo Lean; emenda Pactos aprovada pelo usuário em 2026-11-16)
> **Last Updated**: 2026-11-18
> **Last Verified**: 2026-11-15 (`/design-review` único por `qa-lead`: **APPROVED**, 0 bloqueantes, 1 recomendada em R7 aplicada; **Approved** pelo usuário)
> 2026-11-15: 2ª revisão única por `qa-lead` (cruzada com Maldições R7, Combate R14, Telégrafos R6/R7 e Câmaras): **NEEDS REVISION → emenda aplicada**, 3 bloqueantes e 4 recomendadas. B1: cada golpe testa só o alvo travado; puxão e pulso movem jogador e Maldição (R3, R5, F2, F3). B2: lacaios sem abate nem `ao_abater`, chefe de Pactos fica na lista em `Subjugado` (R8, R9, F6; contrato pedido ao Combate R14). B3: `em_furia` só liga no fim da `TransicaoFase` (F4). R1: CH7 com `302,4 px/s`. R2: envoltória do Padrão 1 com `raio_alvo`. R3: AC-CH-15 com Vida exata. R4: contratos pedidos a Câmaras (`Subjugado` fora de combate) e Telégrafos R7. Aprovado pelo usuário em 2026-11-16.
> **Implements Pillar**: P3 *Reflexo que se lê* (padrões de chefe legíveis em 2 fases), P2 *A Beira cobra* (pacto × Fragmentos), P1 *Toda bênção é uma filosofia*

## Summary

**Chefes** define o comportamento `chefe` (que deixa de ser reservado na IA e nas Câmaras) e o confronto final da 7ª câmara do Limiar da Beira (índice `6`): o **Soberano do Limiar** em sua forma hostil de **Maldição-chefe** (`700 HP` fixos, sem bônus de profundidade, armadura contra cambaleio e `"Quebrou!"`, `fator_empurrao_chefe = 0,12`). Ele luta num ciclo determinístico de **4 padrões** com telégrafos próprios (*Garra do Véu Rasgado* em setor, *Irrupção do Limiar* em avanço retangular, *Pulso de Soberania* em anel + 12 projéteis radiais, e *Convergência da Fenda* em círculo com puxão e invocação controlada de até 2 *Ecos Perdidos*, teto de 3 vivos), espelhando em escala de chefe o kit que terá como espécie Primordial aliada (`maldicoes.md` R16). Ao cair para `≤ 50%` de Vida (`350 HP`), executa uma **Transição de Fase** invulnerável de `0,50 s` (`30` passos) com pulso repulsor sem dano e entra na **Fase 2 (Fúria)**: velocidade de aproximação `× 1,15` e recargas `× 0,60` (`+33%` de frequência sem encurtar os preparos). Ao zerar a Vida, Lâmina e Ressonância o abatem direto (`+6` Fragmentos do chefe + `15` da vitória), enquanto Pactos o deixa **`Subjugado`** para escolher entre **Pactuar** (`0` Fragmentos do chefe, registrando o pacto/vínculo) ou **Exorcizar** (`+6` Fragmentos).

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `IA de inimigos e elites, Telégrafos, Modificadores e atributos, Combate núcleo, Câmaras e ondas, Conteúdo orientado a dados, Maldições (suave), Vínculo e pactos (por contrato)`

## Overview

> `game-designer` e `ai-programmer` consultados via decisões consolidadas do usuário e `systems-designer` (modo Lean, 2026-11-15).

**Chefes** fecha a descida de cada região com um teste de leitura, posicionamento e decisão. Enquanto as câmaras de combate testam gestão de multidão e foco em ondas procedurais, a câmara do chefe tem arena fixa, uma única barra de Vida no topo do HUD (`700 HP`) e um oponente de **armadura total** que nunca cambaleia e nunca tem o preparo interrompido por `"Quebrou!"`.

- **No MVP (7ª câmara do Limiar, índice `6`):** o chefe é o **Soberano do Limiar** (`soberano_do_limiar`), uma **Maldição-chefe** de raridade Primordial. Os seus 4 padrões de ataque são a forma hostil e desgovernada do mesmo kit que ele oferece como aliado em [maldicoes.md](maldicoes.md): enfrentar o chefe ensina a ler a criatura aliada, e jogar com ela ensina a ler o chefe.
- **Duas fases legíveis (P3):** na Fase 1 (`700 → 351 HP`), o jogador aprende o ritmo dos 4 telégrafos (`setor`, `retangulo`, `anel` com 12 projéteis, `circulo` com puxão e lacaios). Ao cruzar `350 HP` (`50%`), uma transição curta de `0,50 s` afasta quem está colado, racha o entalhe da barra no HUD e abre a **Fase 2 (Fúria)**: os preparos (`P_i`) continuam idênticos para não trair a memória muscular do jogador, mas as recargas entre golpes caem para `60%` e o chefe caminha `15%` mais rápido.
- **Desfecho com identidade de Doutrina (P1 + P2):** zerar os `700 HP` aciona o congelamento dramático de chefe (`0,60 s` + *impact frame*) e apaga na hora lacaios e projéteis. Para Lâmina e Ressonância, o chefe se desfaz em `+6` Fragmentos de Eco (`boss_fragments`) e abre a vitória da run (`+15`). Para quem jurou **Pactos**, o chefe cai ajoelhado no estado **`Subjugado`**, entregando ao sistema de `Vínculo e pactos` a escolha entre **Pactuar** (abrir mão dos `6` Fragmentos para conquistar ou evoluir o vínculo com o *Soberano do Limiar*) ou **Exorcizar** (receber os `6` Fragmentos).
- **Escopo por marco (`systems-index.md`):** a *Anomalia Maior* (`anomalia_maior`) e o *Guardião do Rito* (`guardiao_rito`) permanecem no manifesto de dados como reservados para a Fatia Vertical e o Alpha, reutilizando a mesma máquina de estados deste GDD.

> **→ vira ADR:** como o `BossPatternDef` compõe os 4 padrões dentro do `EnemyDef` (ou sub-recurso `BossDef`) e como o estado `Subjugado` pausa o `camara_limpa` até a resposta de `Vínculo e pactos`.

## Detailed Design

### Core Rules

**R1. Identidade, atributos e armadura.** Um chefe é um inimigo com `comportamento = chefe` no seu `EnemyDef` (Conteúdo R1, que deixa de ser reservado no MVP):
- **Vida fixa:** `vida_max = 700` no Limiar. Chefes **não** recebem o bônus de profundidade (`depth_hp_bonus = +5%/p`, IA F2) e nunca são sorteados como elite (IA R10).
- **Corpo e movimento:** `raio_px = 45 px` (`30 u`), velocidade base de andar `162 px/s` (`1,8 u/passo`).
- **Resistência a empurrão:** usa a fonte `chefe` do Modificadores (`fator_empurrao_chefe = 0,12`, `entities.yaml`).
- **Armadura total (IA R8, Combate R8.7):** um chefe **nunca cambaleia** e **nunca sofre `"Quebrou!"`** quando atingido por golpes pesados durante o preparo. Seus telégrafos só são evitados saindo da forma ou com invulnerabilidade (esquiva/investida). Status de dano (`Sangramento`, `Queimadura`) e `Abalo` (`−30%` de dano causado, Status R4) funcionam normalmente nele, mas o chefe é **imune a imobilização** (Maldições R13.3).

**R2. Arena fixa e surgimento (Câmaras R14).**
- A câmara do chefe (índice `6` da `RegionDef limiar`, mantendo a profundidade de combate anterior `p = 4` para iluminação e regras) tem `1920×1080 px` e layout fixo sem sorteio de RNG: **4 pilares circulares de raio `51 px`** em `(390; 300)`, `(1530; 300)`, `(390; 750)` e `(1530; 750)`.
- Na metade do wipe de entrada (Combate R1), o jogador é posicionado em `(960; 930)` (com a Maldição ativa a `105 px` se for Pactos) e o chefe nasce sozinho em **`(960; 285)`** no estado `Surgindo` por `50` passos vivos (`0,833 s`, IA R3).
- Ao terminar `Surgindo`, o chefe entra em `Aproximacao` com `padrao = 0` e uma espera inicial fixa de `espera_inicial_chefe_s = 0,50 s` (`30` passos vivos, sem consumir o fluxo `ia` do RNG, garantindo abertura 100% determinística).

**R3. Alvo da mira e interação com Maldições (IA R4, Maldições R7).**
- Por padrão, o alvo do chefe é o **jogador**.
- Se o chefe estiver com **atração** ativa (`restante_atracao > 0`, aplicada pelo *Chamado do Pacto*, por *Queda de Pilar* ou por *Pulso de Soberania* aliado, Maldições R7/R13.4), o seu alvo de aproximação e de trava de mira no início do `Preparo` passa a ser a **Maldição em campo**.
- **Cada golpe testa só o alvo travado no início do `Preparo`** (Maldições R7, emenda Pactos 2026-11-15): o setor do Padrão 0, o contato do avanço do Padrão 1, o pulso e os `12` projéteis do Padrão 2 e o círculo do Padrão 3 ferem apenas esse alvo (jogador, ou a Maldição em campo se o chefe estava atraído). Se a Maldição sair de campo durante o padrão, a atração termina (Maldições R7) e o golpe em curso não fere ninguém. **Deslocamentos não são golpes:** o puxão da *Convergência* (R5.4) e o pulso repulsor da `TransicaoFase` (R7) movem o jogador **e** a Maldição em campo.

**R4. Máquina de 4 padrões em ciclo (`padrao ∈ {0, 1, 2, 3}`).**
- O chefe percorre os 4 padrões sempre em ordem (`0 → 1 → 2 → 3 → 0...`), avançando `padrao = (padrao + 1) mod 4` ao entrar em `Recuperacao`.
- Em `Aproximacao`, `timer` desce `1` por passo vivo e o chefe caminha em direção ao alvo atual (respeitando colisão com pilares, parede e lentidão do Selo `× 0,5` no andar, IA R9) até atingir a distância de engajamento do padrão `padrao`:
  - No **Padrão 0 (*Garra do Véu Rasgado*)**, caminha até `dist ≤ alcance_engajamento_p0_px` (`180 px`) e inicia o `Preparo` assim que `timer ≤ 0` **e** `dist ≤ 180 px`.
  - Nos **Padrões 1, 2 e 3**, caminha até `dist ≤ 300 px` (IA R4) enquanto `timer > 0`, mas inicia o `Preparo` **imediatamente quando `timer ≤ 0`** em qualquer distância dentro da câmara (nunca fica travado perseguindo se o jogador correr).

**R5. Os 4 padrões da Maldição-chefe (*Soberano do Limiar*).**
1. **Padrão 0 — *Garra do Véu Rasgado* (`setor`, `centro_a_borda`):**
   - **Preparo:** `0,50 s` (`30` passos vivos), telégrafo em `setor` de raio `R_0 = 165 px` e meio-ângulo `78,46°` (`cos θ = 0,20`) ancorado no chefe com mira travada.
   - **Execução:** `0,167 s` (`10` passos parado). No 1º passo da execução (disparo do telégrafo), fere o alvo da mira dentro do setor com **`16` de dano**.
   - **Recuperação:** `1,00 s` (`60` passos na Fase 1) / `0,60 s` (`36` passos na Fase 2).
2. **Padrão 1 — *Irrupção do Limiar* (`retangulo` de avanço, `ao_longo_do_eixo`):**
   - **Preparo:** `0,60 s` (`36` passos vivos), telégrafo em `retangulo` ancorado na traseira do chefe (`−R_c`), largura `W = 2 × R_c` e comprimento `L = percurso + 2 × R_c`, com `R_c = 45 + raio_alvo` do alvo travado (F2; Telégrafos R6, o desenho nunca é menor que o perigo). Contra o jogador (`27 px`): `R_c = 72`, `W = 144 px`, `L = 414 px`.
   - **Execução:** `0,40 s` (`24` passos vivos) avançando em linha reta na direção da mira travada a `675 px/s` (`11,25 px/passo`; ignora a lentidão do Selo, como a Fenda na IA R6). A cada passo do avanço, fere o alvo travado por contato (`dist < 45 + raio_alvo`) no máximo 1 vez por avanço com **`18` de dano** (R3). Se tocar um pilar ou parede, o deslocamento para ali, mas cumpre os passos restantes da execução.
   - **Recuperação:** `1,25 s` (`75` passos na Fase 1) / `0,75 s` (`45` passos na Fase 2).
3. **Padrão 2 — *Pulso de Soberania* (`anel`, `borda_ao_centro`, + `12` projéteis radiais):**
   - **Preparo:** `0,60 s` (`36` passos vivos), telégrafo em `anel` preenchido (`r_int = 0`, `r_ext = 210 px`) centrado no chefe com crescimento `borda_ao_centro`.
   - **Execução:** `0,20 s` (`12` passos parado). No passo do disparo:
     - aplica um golpe circular em `210 px` com **`15` de dano** e empurrão de `900 px/s` no alvo travado (R3);
     - dispara simultaneamente **`12` projéteis radiais** (cada um testa só o alvo travado, R3) espaçados de `30°` a partir do ângulo da mira travada (`velocidade_pxs = 360`, `raio_px = 13,5`, `vida_s = 3,0 s` / `180` passos, **`12` de dano**, nascendo a `54 px` do centro do chefe).
     - **Confirmação (emenda Pactos, 2026-11-15):** cada um dos `12` projéteis testa colisão **só com o alvo travado** no início do `Preparo` do Padrão 2 (R3): o jogador, ou a Maldição em campo se o chefe estava atraído por ela. O outro (jogador ou Maldição) é atravessado sem dano, sem empurrão e sem remover o projétil. O projétil some ao acertar o alvo travado, ao tocar pilar ou parede, ou ao fim de `180` passos. Se o alvo travado sair de campo (Maldição Exausta ou trocada), os projéteis já disparados seguem sem alvo atingível e só somem por parede, pilar ou tempo. Vale para o Combate (`disparar_projetil` com ~~`alvo_unico = id`~~ `alvo = id`, Combate R22) e para a F5 (no máximo 1 acerto por disparo no alvo travado).
   - **Recuperação:** `1,50 s` (`90` passos na Fase 1) / `0,90 s` (`54` passos na Fase 2).
4. **Padrão 3 — *Convergência da Fenda* (`circulo`, `borda_ao_centro`, + puxão + invocação controlada):**
   - **Preparo:** `0,70 s` (`42` passos vivos), telégrafo em `circulo` de raio `R_3 = 225 px` centrado no chefe (`borda_ao_centro`), acompanhado de um anel tracejado externo de aviso de puxão em `420 px`.
     **(emenda Pactos, 2026-11-15)** O anel tracejado é o contorno secundário do Pipeline visual R5a e dos Telégrafos R5a. Seu raio vem do campo `raio_secundario_px` do `BossPatternDef` (Padrão 3: **`420 px`**, igual a `ChefesTuning.raio_puxao_px`; validação CH8 abaixo).
   - **Execução:** `0,20 s` (`12` passos parado). No passo do disparo, nesta ordem:
     1. **Puxão:** puxa o jogador e a Maldição em campo (se estiverem a `dist ≤ 420 px` e não estiverem invulneráveis em esquiva/salto) em **`75 px`** na direção do centro do chefe, parando a `45 + raio_alvo` do centro e respeitando pilares/paredes (F3);
     2. **Impacto:** causa **`14` de dano** ao alvo travado se ele estiver dentro de `225 px` após o puxão (R3);
     3. **Invocação controlada:** calcula `vagas = max(0, max_lacaios_vivos − n_lacaios_vivos)` com **`max_lacaios_vivos = 3`** e invoca `min(2, vagas)` *Ecos Perdidos* comuns (`id = eco_perdido`, `Vida = 30` fixa sem bônus de profundidade, `invocado_pelo_chefe = true`) nas posições laterais `(x_chefe − 135, y_chefe)` e `(x_chefe + 135, y_chefe)` ajustadas para fora de pilares/paredes, ambos entrando em `Surgindo` por `50` passos.
   - **Recuperação:** `1,75 s` (`105` passos na Fase 1) / `1,05 s` (`63` passos na Fase 2).

**R6. Recuperação entre padrões.**
- Durante `Recuperacao`, `timer` desce `1` por passo vivo. Se `dist > 90 px`, o chefe caminha em direção ao alvo a `0,4 × velocidade_efetiva` (IA R7).
- Quando `timer` chega a `0`, entra em `Aproximacao` para o próximo padrão do ciclo com `timer = passos(espera_entre_padroes_chefe_s)` (`0,25 s` = `15` passos vivos fixos, sem sorteio de RNG).

**R7. Transição para a Fase 2 (Fúria em `Vida ≤ 350`).**
- Na primeira vez na luta em que a Vida do chefe cai para `0 < Vida ≤ round(vida_max × limiar_furia_frac)` (`350 HP`), ele ativa a entrada na Fase 2:
  - se estiver em `Aproximacao`, `Preparo` ou `Recuperacao`, entra em **`TransicaoFase` no mesmo passo** (cancelando o telégrafo ativo sem disparar);
  - se estiver no meio da `Execucao` de um padrão (como os `24` passos de avanço do Padrão 1), conclui a execução atual e entra em **`TransicaoFase` no passo seguinte**, antes da recuperação.
- **`TransicaoFase` dura `30` passos vivos (`0,50 s`):**
  - no 1º passo, emite um **pulso de onda de choque sem dano** de raio `240 px` que afasta o jogador e a Maldição em campo em `120 px` para fora (respeitando pilares e paredes), limpa `restante_atracao` e destaca a marca de `50%` na barra do HUD;
  - durante os `30` passos, o chefe fica parado, **invulnerável a qualquer dano** (golpes de arma, Maldição, Selo e ticks de status resultam em `0` de dano) e imune a empurrão;
  - ao fim do 30º passo, `em_furia` passa a `true`, `padrao` avança `(padrao + 1) mod 4` apenas se a transição interrompeu `Preparo` ou entrou logo após `Execucao` (mantendo o `padrao` atual se interrompeu `Recuperacao` ou `Aproximacao`, onde o incremento já havia ocorrido) e o chefe entra em `Aproximacao` com `timer = 15` passos.
- **Efeitos permanentes da Fase 2 (`em_furia = true`):**
  - velocidade base de andar sobe para `velocidade × mult_velocidade_furia` (`162 × 1,15 = 186,3 px/s`);
  - todas as durações de `Recuperacao` usam `passos(recarga_s[i] × fator_recarga_furia)` com `fator_recarga_furia = 0,60` (`36, 45, 54 e 63` passos, F1). Os tempos de `Preparo` e `Execucao` **não mudam**.

**R8. Regras dos lacaios invocados (`invocado_pelo_chefe = true`).**
- Os *Ecos Perdidos* invocados pelo Padrão 3 seguem a IA normal de `melee` (IA R3–R9), mas:
  - nascem sempre comuns (`elite = false`, sem consumir o fluxo `elites` nem o fluxo `spawn` do RNG) e com `Vida = 30` base;
  - **não** contam para o resumo de abates da run nem disparam efeitos `ao_abater` do jogador (`cura_ao_abater`, `explosao_ao_abater`) quando são limpos automaticamente pela queda do chefe (se o jogador ou a Maldição os matar durante a luta, contam e ativam `ao_abater` normalmente);
  - a câmara do chefe **não** exige abater os lacaios antes do chefe: assim que o chefe chega a `Vida ≤ 0`, todos os lacaios vivos morrem instantaneamente no mesmo passo.
  - **Contrato pedido a `combate-nucleo.md` R14** (emenda Pactos, 2026-11-15): hoje a R14 zera os outros inimigos quando o chefe morre e eles morrem na varredura com abate `+1` e `ao_abater`. Para os lacaios `invocado_pelo_chefe = true` zerados assim, a varredura não soma abate e não aplica `cura_ao_abater` nem `explosao_ao_abater`.

**R9. Desfecho da luta (`Vida ≤ 0`): `Morto` vs. `Subjugado`.**
- Quando um golpe ou efeito leva o chefe a `Vida ≤ 0` no passo vivo `s`:
  1. **No próprio passo `s`:** qualquer telégrafo do chefe ou de lacaios é cancelado; todos os projéteis inimigos são removidos; todos os lacaios vivos com `invocado_pelo_chefe = true` são removidos; o Combate aplica `hitstop_abate_chefe_s` (`0,60 s` = `36` passos congelados) e o *impact frame* de chefe (`impact_chefe_s`, Combate R15 / Pipeline F6).
  2. **No 1º passo vivo após o hitstop (`s + 37`):**
     - **Se a Doutrina ativa do jogador for `lamina` ou `ressonancia` (ou qualquer Doutrina diferente de `pactos`):** o chefe entra em **`Morto`** (removido na varredura), a Economia credita `RegionDef.fragmentos_chefe` (`creditar(chefe, 6)`) e as Câmaras emitem `camara_limpa(4, chefe)`, que a Run recebe para encerrar a expedição em **vitória** (`+15` `fragmentos_vitoria`, Run R4).
     - **Se a Doutrina ativa do jogador for `pactos` (`Besta do Vínculo`):** o chefe **não** é removido; **fica na lista de inimigos** em `(pos_chefe)` no estado **`Subjugado`** (`Vida = 0`, inerte, não atingível, sem colisão ofensiva), a fase da câmara passa a `Subjugado` (fora de combate: jogador não sofre dano) e sai o evento **`chefe_subjugado("soberano_do_limiar")`** para o sistema de `Vínculo e pactos` (`22d`).
     - **Ordem (emenda Pactos, 2026-11-15; Combate R14/R24):** quem marca `Subjugado` é o **Combate, no passo `s`** (varredura com a marca, pedido `subjugar(id)` à IA). Os Chefes ~~marcam `Subjugado` em `s + 37`~~ só **emitem `chefe_subjugado(id)` em `s + 37`**, após o hitstop. Entre `s` e `s + 36` o chefe já está na lista, com Vida 0, inerte e não atingível.
     - **Contrato pedido a `combate-nucleo.md` R14** (emenda Pactos, 2026-11-15): numa run de `pactos`, o chefe com `Vida ≤ 0` não sai da lista na varredura. Ele recebe o hitstop de abate de chefe (`36`) e o *impact frame*, mas o abate `+1` e o `cura_ao_abater` dele ficam para o `exorcizar`.
     - **Contrato pedido a `camaras-e-ondas.md`** (emenda Pactos, 2026-11-15): a fase `Subjugado` da câmara do chefe responde `em_combate = falso` (Combate R13.1) até o `camara_limpa`. Hoje as Câmaras não têm essa fase.
- **Resolução de `Subjugado` (contrato com `Vínculo e pactos`):**
  - **Escolher `pactuar`:** registra o pacto com a espécie Primordial `soberano_do_limiar` (ou avança seu vínculo se já pactuada), **não** credita os `6` Fragmentos do chefe (`0` Fragmentos de chefe, preço P2), não soma abate nem aplica `cura_ao_abater`, dissolve o chefe em luz de Osso, remove-o da lista e emite `camara_limpa(4, chefe)` (seguindo para a vitória da run `+15` Fragmentos).
  - **Escolher `exorcizar` (derrotar):** consome o chefe (abate `+1` e `cura_ao_abater` aplicados nesse passo), remove-o da lista, credita `creditar(chefe, 6)` (`+6` Fragmentos) e emite `camara_limpa(4, chefe)` (seguindo para a vitória da run `+15` Fragmentos).

**R9b. Contratos de desfecho com Combate e Câmaras (emenda Pactos, 2026-11-15).** Responde aos pedidos de `combate-nucleo.md` R24 e de `camaras-e-ondas.md` R18-P / OQ 14. Onde o texto da R9 acima diz que os Chefes "emitem `camara_limpa`", vale esta regra.
1. **Marca `subjugavel` no spawn.** Ao criar o chefe (R2), se a Doutrina ativa da run for `pactos`, os Chefes põem `subjugavel = true` no estado do inimigo; senão, `false`. A marca não muda durante a luta. O Combate lê só a marca, nunca a Doutrina (Combate R24).
2. **Vida ≤ 0.** A varredura do Combate trata o chefe pela marca (R24): sem a marca, sai da lista com abate (caminho `Morto`); com a marca, fica na lista em `Subjugado`. Os Chefes recebem `chefe_vencido(id, subjugado)` e, em `s + 37`, emitem `chefe_subjugado(id)` só se `subjugado` for verdadeiro.
3. **Escolha.** Quando Vínculo e pactos devolve `escolha ∈ {pactuar, exorcizar}`, os Chefes fazem, **no mesmo passo vivo e nesta ordem**:
   1. `resolver_subjugado(id, escolha)` ao Combate (Exorcizar: sai da lista com abate e `cura_ao_abater`; Pactuar: sai sem abate; Combate R24);
   2. `creditar(chefe, 6)` à Economia, só se `escolha == exorcizar`;
   3. `limpar_camara_chefe()` às Câmaras.
4. **Câmaras são a única emissora de `camara_limpa`.** Os Chefes **nunca** emitem `camara_limpa`. Com Pactos, as Câmaras emitem `camara_limpa(4, chefe)` uma vez, ao receber `limpar_camara_chefe()` na fase `Subjugado` (Câmaras R18-P). Fora de Pactos, os Chefes não chamam nada: em `s + 37` creditam os `6` e as Câmaras veem a lista vazia (Câmaras R9, R18-P) e emitem `camara_limpa(4, chefe)`.
5. **Escolha repetida.** Uma segunda escolha para o mesmo `id` é ignorada pelos Chefes (nem `resolver_subjugado`, nem crédito, nem `limpar_camara_chefe()`). Se mesmo assim chegar às Câmaras, elas ignoram (Câmaras Edge Cases).

**R10. Barra de chefe no HUD (ativa HUD R11 no MVP).**
- Enquanto o chefe estiver vivo (`Surgindo` até antes de `Morto` / `Subjugado`), o HUD exibe a **Barra de Chefe** no topo central (`960 × 14 px` a `100%`, `y = 48 px` da margem segura, fora do retângulo central de `60% × 70%`):
  - título em `H2` acima da barra com o nome traduzido (`"Soberano do Limiar"`);
  - preenchimento contínuo em Osso com **entalhe divisório em `50%` (`350 HP`)**; ao entrar em `TransicaoFase`, o entalhe racha e a metade restante ganha filete interno Magenta (`#E0259C`).
- O chefe **não** exibe o fio de Vida pequeno sob os pés dos inimigos comuns (HUD R9). Os lacaios invocados usam o fio comum de `HUD R9` normalmente.

**R11. `ChefesTuning` e dados (`Conteúdo R1`).**
- Os parâmetros globais de fase, puxão e invocação vivem em `ChefesTuning` (`assets/data/tuning/chefes_tuning.tres`), e os 4 padrões do chefe vivem na lista `padroes` de `BossPatternDef` dentro do `EnemyDef` de `soberano_do_limiar`. Nenhum número fica literal no código.
- **(emenda Pactos, 2026-11-15) Campo novo `raio_secundario_px` no `BossPatternDef`** (pedido do Pipeline visual R5a e dos Telégrafos R5a): `float`, padrão `0` (sem contorno secundário). Se `> 0`, o telégrafo do padrão ganha um contorno tracejado circular desse raio, na mesma posição. MVP: Padrões 0, 1 e 2 = `0`; Padrão 3 = **`420 px`**. Faixa de design `0` ou `300–600` (a mesma do `raio_puxao_px`). O dano e o puxão **não** leem este campo: é só desenho.

**R12. Injeção.**
- O módulo de Chefes recebe por injeção: `ChefesTuning`, o `EnemyDef` do chefe e do lacaio (`eco_perdido`), a consulta de Doutrina ativa da run, as chamadas do Combate (`ferir_jogador`, `ferir_maldicao`, `disparar_projetil`, `pedir_hitstop`), dos Telégrafos (`iniciar_telegrafo`, `cancelar_telegrafo`), das Câmaras (`camara_limpa`) e de `Vínculo e pactos` (`chefe_subjugado`).
- **(emenda Pactos, 2026-11-15)** Troca: das Câmaras os Chefes recebem só a chamada `limpar_camara_chefe()` (não emitem `camara_limpa`, R9b); do Combate recebem também `resolver_subjugado(id, escolha)` e o evento `chefe_vencido(id, subjugado)`; da Economia, `creditar`.

### States and Transitions

| Estado | Fase | Entra quando | Sai para |
|---|---|---|---|
| `Surgindo` | 1 | montagem da câmara do chefe em `(960; 285)` | `Aproximacao` após `50` passos vivos (`timer = 30`, `padrao = 0`) |
| `Aproximacao` | 1 ou 2 | fim de `Surgindo`, de `Recuperacao` ou de `TransicaoFase` | `Preparo` (`timer ≤ 0` e alcance do padrão satisfeito, R4); `TransicaoFase` (`0 < Vida ≤ 350` na Fase 1); `HitstopFinal` (`Vida ≤ 0`) |
| `Preparo` | 1 ou 2 | `iniciar_telegrafo` aceito para o padrão `i` | `Execucao` (`timer == 0`); `TransicaoFase` (`0 < Vida ≤ 350` na Fase 1, cancelando telégrafo); `HitstopFinal` (`Vida ≤ 0`) |
| `Execucao` | 1 ou 2 | disparo do telégrafo do padrão `i` | `TransicaoFase` (se `0 < Vida ≤ 350` foi atingido durante a execução na Fase 1); senão `Recuperacao` (`padrao = (padrao + 1) mod 4`); `HitstopFinal` (`Vida ≤ 0`) |
| `Recuperacao` | 1 ou 2 | fim da `Execucao` do padrão `i` | `Aproximacao` (`timer == 0`, recebe `timer = 15`); `TransicaoFase` (`0 < Vida ≤ 350` na Fase 1); `HitstopFinal` (`Vida ≤ 0`) |
| `TransicaoFase` | 1 → 2 | 1ª vez com `0 < Vida ≤ 350` (R7) | `Aproximacao` na Fase 2 (`em_furia = true`) após `30` passos vivos |
| `HitstopFinal` | fim | `Vida ≤ 0` (limpa lacaios/projéteis na hora, `36` passos congelados) | `Morto` (Lâmina/Ressonância) ou `Subjugado` (Pactos) |
| `Subjugado` | fim (Pactos) | ~~fim de `HitstopFinal` com `doutrina == pactos`~~ marcado pelo Combate no passo `s` (varredura com a marca); `chefe_subjugado` sai em `s + 37`, no fim de `HitstopFinal` (emenda Pactos, 2026-11-15) | encerrado após escolha `pactuar` ou `exorcizar` → `camara_limpa(4, chefe)` |
| `Morto` | fim | fim de `HitstopFinal` fora de Pactos, ou após `exorcizar` | removido da câmara → `camara_limpa(4, chefe)` |

**Mundo:** no hitstop, na Pausa e em Transição de câmara, nenhum contador do chefe ou de seus lacaios avança (Combate R1).

### Interactions with Other Systems

| Sistema | Entra em Chefes | Sai de Chefes | Dono do contrato |
|---|---|---|---|
| IA de inimigos e elites | delegação do comportamento `chefe`, IA dos lacaios `eco_perdido` | criação e remoção imediata dos lacaios `invocado_pelo_chefe` | IA / Chefes |
| Telégrafos | `iniciar_telegrafo` (`setor`, `retangulo`, `anel`, `circulo`) e passo do disparo | geometria e tempos dos 4 padrões; cancelamento na `TransicaoFase` e no abate | Telégrafos |
| Combate núcleo | dano recebido pelo chefe, `hitstop_abate_chefe_s`, `impact_chefe_s` | `ferir_jogador`, `ferir_maldicao`, `disparar_projetil` (12 radiais), puxão/empurrão | Combate |
| Modificadores e atributos | `fator_empurrao_chefe = 0,12`, `Abalo` (`× 0,70` no dano do chefe) | portador do chefe | Modificadores |
| Maldições | posição da Maldição em campo e pedido `atrair` (R7 de Maldições) | espécie Primordial `soberano_do_limiar` referenciada por `chefe_origem_id` | Maldições |
| Vínculo e pactos | decisão `pactuar` ou `exorcizar` | evento `chefe_subjugado("soberano_do_limiar")` quando `doutrina == pactos` | Vínculo e pactos |
| Câmaras e ondas | arena fixa R14 (`4` pilares, spawn `(960; 285)`), consulta `em_combate` | ~~`camara_limpa(4, chefe)` após abate ou escolha de pacto~~ → `limpar_camara_chefe()` depois de `resolver_subjugado` (só Pactos); as Câmaras emitem `camara_limpa` (emenda Pactos, 2026-11-15, R9b) | Câmaras |
| Combate núcleo *(emenda Pactos, 2026-11-15)* | `chefe_vencido(id, subjugado)` | marca `subjugavel` no spawn, `resolver_subjugado(id, escolha)` (R9b) | Combate (varredura R24), Chefes (desfecho) |
| Run e regiões / Economia | `doutrina` ativa, `RegionDef.fragmentos_chefe` (`6`) | pedido `creditar(chefe, 6)` no abate ou exorcismo | Run / Economia |
| HUD e Feedback de combate | — | Vida, `vida_max`, fase (`1`, `TransicaoFase`, `2`), `chefe_subjugado` para a barra de chefe (HUD R11) e VFX/áudio | HUD / Feedback |

## Formulas

> Proposta do `systems-designer` (2026-11-15). Convenções: `passos(t)` é a F7 do Conteúdo (`duration_to_steps`, `TICK_RATE = 60`, empate `x,5` longe do zero); distâncias em px de mundo (`unit_to_px = 1,5`); velocidades em px/s. O chefe tem `vida_max = 700` fixa (sem `depth_hp_bonus`, IA F2 / Modificadores R10), `fator_empurrao_chefe = 0,12` e armadura total (nunca cambaleia nem sofre `"Quebrou!"`, Combate R8.7).

### F1. Ciclo dos 4 padrões e DPS potencial por fase (`boss_pattern_cycle_and_dps`)

The boss_pattern_cycle_and_dps formula is defined as:

Para cada padrão `i ∈ {0, 1, 2, 3}` (avançando `i' = (i + 1) mod 4` ao fim de cada execução):
`P_i = passos(preparo_s[i])` ; `E_i = passos(execucao_s[i])` ;
`R_i(furia) = passos(recarga_s[i] × (furia ? fator_recarga_furia : 1,0))` ;
`C_i(furia) = P_i + E_i + R_i(furia)` (passos vivos por padrão, sem tempo extra de aproximação) ;
`C_rot(furia) = Σ_{i=0}^{3} C_i(furia)` ; `D_rot = Σ_{i=0}^{3} dano_ref[i]` ;
`DPS_pot(furia) = (D_rot × 60) / C_rot(furia)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| `i` | int | `{0, 1, 2, 3}` | runtime | índice do padrão atual no ciclo determinístico do chefe |
| `P_i`, `E_i` | int | `P_i ∈ [24, 60]`, `E_i ∈ [6, 36]` | data file | passos de preparo (`30, 36, 36, 42`) e de execução (`10, 24, 12, 12`) do padrão `i` |
| `recarga_s[i]` | float | `0,5–3,0` s (`60, 75, 90, 105` passos) | data file | recarga base após a execução do padrão `i` |
| `fator_recarga_furia` | float | `0,40–0,85` (MVP `0,60`) | data file | `ChefesTuning.fator_recarga_furia`: multiplicador da recarga na Fase 2 (IA R13) |
| `C_i(furia)`, `C_rot(furia)` | int | `≥ 3` passos | calculated | duração em passos vivos do padrão `i` e da rotação completa dos 4 padrões |
| `dano_ref[i]` | int | `12–18` (`16, 18, 15, 14`) | data file | dano bruto de 1 acerto direto do padrão `i` (no Padrão 2: `15` do pulso ou `12` de 1 projétil) |
| `DPS_pot(furia)` | float | `> 0` Vida/s | calculated | teto teórico de dano por segundo se 1 golpe de cada padrão acertasse o jogador |

**Output Range:** `C_i ≥ 3` (divisão por zero impossível por validação CH2). Como apenas `R_i` é multiplicado por `0,60` na Fase 2 (`P_i` e `E_i` permanecem inalterados para preservar a leitura do telégrafo, P3), a aceleração real do ciclo completo na Fúria é de `532 / 400 = 1,33×` (`+33,0%` na frequência de ataques; somando os `15` passos fixos de `espera_entre_padroes_chefe_s` por padrão, a rotação com espera passa de `592` passos / `9,87 s` na Fase 1 para `460` passos / `7,67 s` na Fase 2).

**Example (60 Hz — *Soberano do Limiar*):**

| Padrão `i` | `P_i` | `E_i` | `R_i` (Fase 1) | `C_i` (Fase 1) | `R_i` (Fase 2, `×0,6`) | `C_i` (Fase 2) | `dano_ref[i]` |
|---|---|---|---|---|---|---|---|
| **0 — *Garra do Véu Rasgado*** | `30` (`0,50 s`) | `10` (`0,167 s`) | `60` (`1,00 s`) | **100** (`1,667 s`) | `36` (`0,60 s`) | **76** (`1,267 s`) | `16` |
| **1 — *Irrupção do Limiar*** | `36` (`0,60 s`) | `24` (`0,400 s`) | `75` (`1,25 s`) | **135** (`2,250 s`) | `45` (`0,75 s`) | **105** (`1,750 s`) | `18` |
| **2 — *Pulso de Soberania*** | `36` (`0,60 s`) | `12` (`0,200 s`) | `90` (`1,50 s`) | **138** (`2,300 s`) | `54` (`0,90 s`) | **102** (`1,700 s`) | `15` (pulso) / `12` (proj.) |
| **3 — *Convergência da Fenda*** | `42` (`0,70 s`) | `12` (`0,200 s`) | `105` (`1,75 s`) | **159** (`2,650 s`) | `63` (`1,05 s`) | **117** (`1,950 s`) | `14` |
| **Rotação completa (0→3)** | `ΣP = 144` | `ΣE = 58` | `ΣR = 330` | **532** (`8,867 s`) | `ΣR = 198` | **400** (`6,667 s`) | `D_rot = 63` (ou `60`) |

- `DPS_pot(Fase 1) = 63 × 60 / 532 =` **7,11 DPS** (`6,77 DPS` se atingido pelo projétil de `12` em vez do pulso de `15`);
- `DPS_pot(Fase 2) = 63 × 60 / 400 =` **9,45 DPS** (`9,00 DPS` com projétil).

---

### F2. Geometria dos 4 telégrafos, leque radial e testes de acerto (`boss_telegraph_and_hit_geometry`)

The boss_telegraph_and_hit_geometry formula is defined as:

- **Padrão 0 (`setor`, `centro_a_borda`, Telégrafos F2):** `R_0 = 165 px`, `θ = arccos(0,2) = 78,46°` ; acerta o alvo da mira (`jogador`, ou `Maldição` se atraído pela R7 de Maldições) no disparo se `||pos_alvo − pos_chefe|| ≤ R_0` e `dir(chefe → alvo) · mira_travada ≥ 0,20` ;
- **Padrão 1 (`retangulo` de avanço, `ao_longo_do_eixo`, Telégrafos F4):** `percurso = (v_avanco_pxs / 60) × E_1` ; `R_c = raio_chefe_px + raio_alvo_px` (alvo travado no início do `Preparo`: jogador `27 px`, ou a Maldição em campo, `22,5–30 px`) ; `L = percurso + 2 × R_c` ; `W = 2 × R_c` ; a cada passo do avanço, fere o alvo travado no máximo 1 vez se `||pos_alvo − pos_chefe|| < raio_chefe_px + raio_alvo_px` ;
- **Padrão 2 (`anel`, `borda_ao_centro`, + `N_proj` projéteis radiais):** no disparo, fere se `||pos_alvo − pos_chefe|| ≤ R_anel` (`r_int = 0`, `r_ext = 210 px`) e emite `N_proj = 12` projéteis nos ângulos `α_k = α_mira + k × (360° / N_proj)` (`k ∈ {0..11}`), nascendo em `pos_chefe + dir(α_k) × saida_proj_px` (`54 px`) ; vão livre entre projéteis vizinhos à distância `d` do centro: `vao_livre(d) = 2 × d × sin(180° / N_proj) − 2 × (raio_proj_px + raio_jogador_px)` ;
- **Padrão 3 (`circulo`, `borda_ao_centro`):** `R_3 = 225 px` ; no disparo, aplica primeiro o puxão da F3 e em seguida fere se `||pos_alvo' − pos_chefe|| ≤ R_3` ;
- **Folga de leitura (Telégrafos F6):** `folga_i = P_i − passos(reacao_ref_s)` (`reacao_ref_s = 0,25 s = 15` passos).

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| `raio_chefe_px`, `raio_jogador_px` | float | `45 px`, `27 px` | data file | raios de colisão do chefe (`30 u`) e do jogador (`18 u`) |
| `R_0`, `R_anel`, `R_3` | float | `165`, `210`, `225` px | data file | raios de acerto dos Padrões 0, 2 (pulso) e 3 |
| `v_avanco_pxs`, `E_1` | float, int | `675 px/s`, `24` passos | data file | velocidade (`11,25 px/passo`) e duração do avanço do Padrão 1 |
| `raio_alvo_px` | float | `22,5–30 px` (jogador `27`) | data file | raio do alvo travado (`WeaponDef`/jogador ou `CurseDef.raio_px`, Maldições §Catálogo) |
| `percurso`, `R_c`, `L`, `W` | float | `270`; `67,5–75`; `405–420`; `135–150` px (jogador: `72`, `414`, `144`) | calculated | dimensões da envoltória retangular do Padrão 1 (Telégrafos F4) |
| `N_proj`, `raio_proj_px` | int, float | `12`, `13,5 px` | data file | contagem e raio dos projéteis radiais do Padrão 2 (`360 px/s`, vida `180` passos) |
| `vao_livre(d)` | float | `[-81, +∞)` px | calculated | abertura entre as hurtboxes de 2 projéteis adjacentes à distância `d` |
| `folga_i` | int | `15–27` passos (`≥ folga_min = 8`) | calculated | margem de reação após os `15` passos de leitura humana (Telégrafos F6) |

**Output Range:** Todos os 4 padrões têm `folga_i ≥ 15 passos` (`0,25 s`), quase o dobro de `folga_min = 8` passos (Telégrafos R10). No Padrão 2, `vao_livre(d) > 0` para `d > 40,5 / sin(15°) = 156,5 px`: dentro de `156,5 px` o anel de projéteis é fechado (exige esquiva), e a partir de `210 px` (fora do pulso) `vao_livre(210) = 2 × 210 × 0,25882 − 81 = 27,7 px` (a `360 px`, `vao_livre = 105,3 px`), permitindo desviar andando entre dois projéteis.

**Example (60 Hz):**
- **Padrão 1 (*Irrupção*):** `percurso = (675 / 60) × 24 = 11,25 × 24 = 270 px`; `R_c = 45 + 27 = 72 px`; retângulo de `L = 270 + 144 = 414 px` por `W = 144 px`, folga nos 4 cantos `(√2 − 1) × 72 = 29,8 px` (desenho nunca menor que o perigo, Telégrafos R6).
- **Folgas de leitura `folga_i = P_i − 15`:** Padrão 0: `30 − 15 = 15` passos (`0,25 s`); Padrões 1 e 2: `36 − 15 = 21` passos (`0,35 s`); Padrão 3: `42 − 15 = 27` passos (`0,45 s`).

---

### F3. Puxão e posições determinísticas de invocação da Convergência (`boss_convergence_pull_and_summon`)

The boss_convergence_pull_and_summon formula is defined as:

No passo do disparo do **Padrão 3 (*Convergência da Fenda*)**:
1. **Puxão (antes do teste de dano):** para cada combatente da facção do jogador `c` (jogador e Maldição em campo, exceto se invulnerável em esquiva/investida/salto) com `d = ||pos(c) − pos_chefe||`:
   se `0 < d ≤ raio_puxao_px` (`420 px`):
   `passo_puxao = min(puxao_convergencia_px, max(0, d − (raio_chefe_px + raio(c))))` ;
   `pos'(c) = resolver_colisao(pos(c) − dir(chefe → c) × passo_puxao)` ;
2. **Invocação controlada (após o dano):**
   `vagas = max(0, max_lacaios_vivos − n_lacaios_vivos)` ;
   `n_invocar = min(lacaios_por_convergencia, vagas)` ;
   Para `k ∈ {0 .. n_invocar − 1}` (`sinal_k = (k == 0 ? −1 : +1)`):
   `P_spawn[k] = ajustar_obstaculos_e_parede(pos_chefe + Vector2(sinal_k × dist_spawn_lacaio_px, 0))`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| `raio_puxao_px` | float | `300–600` (MVP `420 px`) | data file | `ChefesTuning.raio_puxao_px`: alcance máximo do puxão da Convergência |
| `puxao_convergencia_px` | float | `45–120` (MVP `75 px`) | data file | `ChefesTuning.puxao_convergencia_px`: deslocamento em direção ao chefe |
| `max_lacaios_vivos` | int | `1–4` (MVP `3`) | data file | `ChefesTuning.max_lacaios_vivos`: teto simultâneo de *Ecos Perdidos* invocados vivos |
| `lacaios_por_convergencia` | int | `1–3` (MVP `2`) | data file | `ChefesTuning.lacaios_por_convergencia`: lacaios gerados por disparo se houver vaga |
| `dist_spawn_lacaio_px` | float | `90–180` (MVP `135 px`) | data file | `ChefesTuning.dist_spawn_lacaio_px`: distância lateral ao centro do chefe para o nascimento |
| `n_invocar` | int | `{0, 1, 2}` | calculated | quantidade de *Ecos Perdidos* efetivamente invocados neste disparo |

**Output Range:** `passo_puxao ∈ [0, 75]` px; o limite `max(0, d − (45 + raio(c)))` impede que o puxão coloque o jogador dentro do corpo do chefe (`d_min = 72 px`). A zona de perigo efetiva do Padrão 3 para quem não esquiva no disparo é `R_3 + puxao_convergencia_px = 225 + 75 = 300 px`. O número de inimigos na câmara nunca passa de `1 (chefe) + 3 (lacaios) = 4 ≤ max_inimigos_onda (9)` e o número de telégrafos ativos nunca passa de `4 ≪ teto_telegrafos (24)`.

**Example (60 Hz):** Chefe no ponto inicial `(960, 285)` dispara a *Convergência*. O jogador está a `d = 280 px` (`(960, 565)`), fora do círculo de `225 px`, mas dentro de `420 px`: é puxado `75 px` para `(960, 490)` (`d' = 205 px ≤ 225 px`) e sofre `14` de dano. Há `2` *Ecos Perdidos* vivos na câmara (`n_lacaios_vivos = 2`): `vagas = max(0, 3 − 2) = 1`, `n_invocar = min(2, 1) = 1`. Nasce `1` *Eco Perdido* (`Vida = 30`, `Surgindo` por `50` passos) em `P_spawn[0] = (960 − 135, 285) = (825, 285)`.

---

### F4. Gatilho da Transição de Fase 2 e efeito da Fúria (`boss_phase_transition_and_fury`)

The boss_phase_transition_and_fury formula is defined as:

`Vida_furia = round(vida_max × limiar_furia_frac)` ;
Gatilho (uma única vez por luta, quando `0 < Vida ≤ Vida_furia` e `¬em_furia`, imediatamente ou no passo em que terminar a execução ativa):
guarda: `¬em_furia` **e** `estado ≠ TransicaoFase` ; `estado = TransicaoFase` por `N_trans = passos(transicao_fase_s)` passos vivos ; **`em_furia = true` só ao fim do `N_trans`-ésimo passo** (R7) ;
Durante `TransicaoFase`: `dano_recebido = 0`, `vel_empurrao = (0, 0)`, telégrafo ativo cancelado ;
No 1º passo de `TransicaoFase` (pulso sem dano em `d = ||pos(c) − pos_chefe|| < raio_pulso_furia_px`):
`pos'(c) = resolver_colisao(pos(c) + dir(chefe → c) × empurrao_pulso_furia_px)` ;
A partir do fim de `TransicaoFase` (`Fase 2`):
`velocidade_chefe = velocidade_base × mult_velocidade_furia` ; `R_i = passos(recarga_s[i] × fator_recarga_furia)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| `limiar_furia_frac` | float | `0,35–0,65` (MVP `0,50`) | data file | `ChefesTuning.limiar_furia_frac`: fração de `vida_max` que ativa a Fase 2 (IA R13) |
| `Vida_furia` | int | `350` (para `vida_max = 700`) | calculated | limiar inteiro de Vida para entrar em Fúria |
| `transicao_fase_s` | float | `0,30–1,00` s (MVP `0,50 s` = `30` passos) | data file | `ChefesTuning.transicao_fase_s`: duração da invulnerabilidade de transição |
| `raio_pulso_furia_px`, `empurrao_pulso_furia_px` | float | `240 px`, `120 px` | data file | raio e deslocamento do pulso de repulsão sem dano ao entrar em Fúria |
| `mult_velocidade_furia` | float | `1,00–1,35` (MVP `1,15`) | data file | `ChefesTuning.mult_velocidade_furia`: multiplicador da velocidade de andar na Fase 2 |
| `velocidade_chefe` | float | `162,0` (Fase 1) → `186,3 px/s` (Fase 2) | calculated | velocidade de aproximação do chefe |

**Output Range:** `Vida_furia = 350`. Se um único golpe derrubar a Vida de `> 350` direto para `≤ 0`, a condição `0 < Vida` é falsa e o chefe vai direto para o desfecho (F6) sem entrar em `TransicaoFase`. Na Fase 2, `186,3 px/s` continua bem abaixo da menor velocidade do jogador (`378 px/s` na Ressonância; razão `0,493 < 0,80` do IV5 da IA).

**Example (60 Hz):** O chefe está em `Preparo` do Padrão 2 com `360 HP` e recebe um Corte finalizador de `25,2` de dano → `Vida = 334,8 ≤ 350`. No mesmo passo, o telégrafo do Padrão 2 é cancelado, o jogador a `130 px` é repelido `120 px` para `250 px` (sem sofrer dano), o chefe fica invulnerável por `30` passos vivos (`0,50 s`) e retoma na Fase 2 com `velocidade = 186,3 px/s` e recargas `36 / 45 / 54 / 63` passos.

---

### F5. Teto de dano recebido e sobrevivência contra o chefe (`boss_damage_intake_and_survival`)

The boss_damage_intake_and_survival formula is defined as:

`dano_golpe = max(1, round(dano_padrao × (1 − min(0,60, max(0, reducao_jogador))) × guarda))` (**F3 do Modificadores**) ;
`g_morte = ceil(vida_max_jogador / dano_golpe)` ;
`t_min_morrer_s = ((g_morte − 1) × passos(invuln_atingido_s)) / 60` (teto de 1 acerto a cada `40` passos vivos, IA F5 / Combate R13)

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| `vida_max_jogador` | int | `80` (Ressonância), `90` (Pactos), `100` (Lâmina) | data file | `WeaponDef.vida_max` sem bênção |
| `dano_padrao` | int | `12` (projétil), `14` (P3), `15` (P2), `16` (P0), `18` (P1) | data file | dano bruto de cada golpe do chefe (lacaios causam `9`) |
| `passos(invuln_atingido_s)` | int | `40` passos (`0,667 s`) | data file | `CombatTuning` (`hurt_invuln_steps`, registro) |
| `g_morte` | int | `5–9` golpes (sem bênção) | calculated | acertos até `Vida ≤ 0` (sem escudo e sem recusa de morte) |
| `t_min_morrer_s` | float | `≥ 2,67 s` (`≥ 2,0 s` exigido pelo IV7 da IA) | calculated | tempo mínimo físico para morrer mesmo cercado por lacaios e projéteis |

**Output Range:** `t_min_morrer_s ≥ 2,67 s > 2,0 s` (cumpre o aviso cruzado IV7 da IA para todas as 3 armas do MVP, inclusive contra o golpe mais forte `dano = 18`). Como projéteis inimigos atravessam o jogador invulnerável (Combate R7), os `12` projéteis radiais do Padrão 2 nunca acumulam dano num mesmo disparo (`máx. 1 acerto` por janela de `40` passos).

**Example (60 Hz, sem bênção, sem recusa):**

| Arma (`vida_max`) | Contra Padrão 1 (`dano = 18`, máx.) | Contra Padrão 0 (`dano = 16`, ref. Armas F4) | Contra Projétil radial (`dano = 12`) | `t_min_morrer_s` (no pior caso, `dano = 18`) |
|---|---|---|---|---|
| **Lâmina do Juramento** (`100`) | `ceil(100/18) =` **6 golpes** | **7 golpes** | **9 golpes** | `5 × 40 = 200` passos (**3,33 s**) |
| **Besta do Vínculo — Pactos** (`90`) | `ceil(90/18) =` **5 golpes** | **6 golpes** | **8 golpes** | `4 × 40 = 160` passos (**2,67 s**) |
| **Foco Ressonante** (`80`) | `ceil(80/18) =` **5 golpes** | **5 golpes** | **7 golpes** | `4 × 40 = 160` passos (**2,67 s**) |

---

### F6. Resolução de desfecho (`Morto` vs. `Subjugado`) e recompensa de Fragmentos (`boss_outcome_and_fragments`)

The boss_outcome_and_fragments formula is defined as:

Quando `Vida_chefe ≤ 0` no passo vivo `s`:
1. **Limpeza imediata (passo `s`):** para todo lacaio `e` com `e.invocado_pelo_chefe == true`, `Vida(e) = 0` (removido sem somar abates e sem efeitos `ao_abater`; contrato pedido ao Combate R14, ver R8); todos os projéteis inimigos somem ; pede `pedir_hitstop(passos(hitstop_abate_chefe_s))` (`36` passos) ;
2. **Desfecho por Doutrina (após os `36` passos de hitstop):**
   - Se `doutrina_arma ≠ pactos`:
     `estado_chefe = Morto` ; `fragmentos_chefe_creditados = RegionDef.fragmentos_chefe` (`6`) ; emite `camara_limpa(4, chefe)` ;
   - Se `doutrina_arma == pactos`:
     `Vida_chefe = 0` ; `estado_chefe = Subjugado` ; emite `chefe_subjugado(id_chefe)` ;
     Ao receber `escolha ∈ {pactuar, exorcizar}` de `Vínculo e pactos`:
     `fragmentos_chefe_creditados = (escolha == exorcizar ? RegionDef.fragmentos_chefe : 0)` ;
     `pacto_registrado = (escolha == pactuar)` ; emite `camara_limpa(4, chefe)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| `doutrina_arma` | StringName | `{lamina, ressonancia, pactos}` | runtime | `WeaponDef.doutrina` equipada pelo jogador no início da run |
| `hitstop_abate_chefe_s` | float | `0,60 s` (`36` passos) | data file | `CombatTuning.hitstop_abate_chefe_s` (`hitstop_boss_kill_steps`, registro) |
| `RegionDef.fragmentos_chefe` | int | `6` (`boss_fragments`, registro) | data file | recompensa de Fragmentos do chefe da região (Economia R3) |
| `escolha` | StringName | `{pactuar, exorcizar}` | runtime | decisão do Iniciado de Pactos na tela/interação de `Vínculo e pactos` |
| `fragmentos_chefe_creditados` | int | `0` ou `6` | calculated | Fragmentos creditados pela origem `chefe` |

**Output Range:** `fragmentos_chefe_creditados ∈ {0, 6}`. Isso preserva o Pilar P2 (*A Beira cobra — Preço Equivalente*): pactuar com o *Soberano do Limiar* abre mão dos `6` Fragmentos do chefe (`15` Fragmentos de vitória + até `7` de portas = `22` máximos se escolher `pactuar`, ou `22 + 6 = 28` com `exorcizar` / outras Doutrinas).

**Example (60 Hz):**
- **Com Lâmina ou Ressonância:** o último golpe zera a Vida do chefe no passo `s = 640`. Os `2` *Ecos Perdidos* invocados somem no passo `640`, o mundo congela dos passos `641` a `676` (`36` passos de hitstop), e no passo vivo `677` o jogador recebe `+6` Fragmentos (`creditar(chefe, 6)`) e sai `camara_limpa(4, chefe)`.
- **Com Besta do Vínculo (`pactos`):** no passo `677` (após os `36` passos de hitstop), o chefe entra em `Subjugado` com `Vida = 0` e abre a escolha. Se o jogador escolher **Pactuar**, recebe `0` Fragmentos do chefe, registra o pacto/vínculo com `soberano_do_limiar` e a câmara emite `camara_limpa(4, chefe)`.

#### F6 com Fragmentos de portas e emissora única (emenda Pactos, 2026-11-15)

O total acima ("até `7` de portas") é anterior ao Limiar de 7 câmaras. A Run
R3-P/F2-P e as Portas F1-P dão **4 escolhas livres de porta** com recompensa
`fragmentos` e o índice 5 (última câmara de combate antes do chefe)
**recompensado** (Run R3-P / OQ 10 da Run): no máximo **`10`
Fragmentos de portas** por run.

`fragmentos_run_max(escolha) = fragmentos_vitoria + fragmentos_portas_max + fragmentos_chefe_creditados(escolha)` ;
`camara_limpa` emitido só pelas Câmaras: fora de Pactos pela lista vazia; com Pactos após `resolver_subjugado(id, escolha)` → `limpar_camara_chefe()` (R9b).

| Variável | Tipo | Faixa | Fonte | Descrição |
|---|---|---|---|---|
| `fragmentos_vitoria` | int | `15` | Run R4 | vitória da run |
| `fragmentos_portas_max` | int | `10` (antes `7`) | Run F2-P, Portas F1-P | máximo de Fragmentos de portas no Limiar com chefe |
| `fragmentos_chefe_creditados` | int | `{0, 6}` | F6 acima | `0` ao Pactuar; `6` ao Exorcizar ou fora de Pactos |

| Desfecho | Vitória | Portas (máx.) | Chefe | **Total máximo** |
|---|---|---|---|---|
| **Pactuar** | `15` | `10` | `0` | **`25`** (antes `22`) |
| **Exorcizar** ou Lâmina / Ressonância | `15` | `10` | `6` | **`31`** (antes `28`) |

O preço P2 do pacto continua `6` Fragmentos (`19,4%` do máximo de `31`).

---

---

### Tabela consolidada: `ChefesTuning` e ficha do `soberano_do_limiar`

#### 1. `ChefesTuning` (Resource único em `assets/data/tuning/chefes_tuning.tres`)

| Campo | Tipo | Valor MVP (passos / px) | V2 (erro de carga) | Faixa de design (aviso CH7) | Papel e o que quebra fora da faixa |
|---|---|---|---|---|---|
| `espera_inicial_chefe_s` | float | **0,50 s** (`30` passos) | `> 0` (`≥ 1` passo) | `0,25–1,00` (`15–60` passos) | Espera fixa após `Surgindo` antes do 1º padrão (R2) |
| `espera_entre_padroes_chefe_s` | float | **0,25 s** (`15` passos) | `> 0` (`≥ 1` passo) | `0,15–0,60` (`9–36` passos) | Espera fixa em `Aproximacao` após terminar `Recuperacao` (R6) |
| `limiar_furia_frac` | float | **0,50** (`350 HP`) | `(0,10 ; 0,90)` | `0,35–0,65` | Fração de `vida_max` que dispara a Fase 2 (IA R13, F4) |
| `fator_recarga_furia` | float | **0,60** | `(0,20 ; 1,00]` | `0,40–0,85` | Multiplicador das recargas na Fase 2 (IA R13, F1). `< 0,40`: padrões colam sem janela de punição |
| `mult_velocidade_furia` | float | **1,15** (`186,3 px/s`) | `[1,00 ; 2,00]` | `1,00–1,35` | Multiplicador da velocidade de andar na Fase 2 (F4) |
| `transicao_fase_s` | float | **0,50 s** (`30` passos) | `> 0` (`≥ 1` passo) | `0,30–1,00` (`18–60` passos) | Janela invulnerável na entrada da Fase 2 (F4) |
| `raio_pulso_furia_px` | float | **240 px** | `> 0` | `150–360` | Raio do pulso sem dano na entrada da Fase 2 (F4) |
| `empurrao_pulso_furia_px` | float | **120 px** | `≥ 0` | `60–210` | Distância empurrada pelo pulso de transição (F4) |
| `raio_puxao_px` | float | **420 px** | `> 0` e `> 225` (`R_3`) | `300–600` | Alcance máximo do puxão da *Convergência* (F3) |
| `puxao_convergencia_px` | float | **75 px** | `≥ 0` | `45–120` | Deslocamento do puxão da *Convergência* (F3). `> 120`: puxa de muito longe para dentro do círculo de `225 px` |
| `max_lacaios_vivos` | int | **3** | `1–6` | `1–4` | Teto simultâneo de lacaios vivos invocados pelo chefe (F3) |
| `lacaios_por_convergencia` | int | **2** | `1–4` e `≤ max_lacaios_vivos` | `1–3` | Lacaios invocados por disparo do Padrão 3 até o teto (F3) |
| `dist_spawn_lacaio_px` | float | **135 px** | `≥ 90` | `90–180` | Distância lateral ao centro do chefe para nascimento dos lacaios (F3) |

#### 2. Ficha do chefe do MVP (`EnemyDef` + 4 padrões de `soberano_do_limiar`)

- **Atributos base (`EnemyDef`):** `id = soberano_do_limiar`, `comportamento = chefe`, `vida = 700`, `velocidade = 162 px/s` (`1,8 u/passo`), `raio_px = 45 px` (`30 u`), `alcance_engajamento_p0_px = 180 px`, `fator_empurrao_chefe = 0,12`, spawn fixo em `(960; 285)` com 4 pilares de `51 px` em `(390; 300)`, `(1530; 300)`, `(390; 750)` e `(1530; 750)` (Câmaras R14).

| # | Nome do padrão | Telégrafo (`Telégrafos R5/R8`) | Dimensões exatas | `P_i` (preparo) | `E_i` (exec.) | `R_i` Fase 1 / Fase 2 | Dano e efeitos no disparo |
|---|---|---|---|---|---|---|---|
| **0** | *Garra do Véu Rasgado* | `setor` (`centro_a_borda`) | `R_0 = 165 px`, meio-ângulo `78,46°` (`cos θ = 0,2`) | `0,50 s` (`30`) | `0,167 s` (`10`) | `1,00 s` (`60`) / `0,60 s` (`36`) | **16** de dano no alvo da mira dentro do setor |
| **1** | *Irrupção do Limiar* | `retangulo` (`ao_longo_do_eixo`) | `percurso = 270 px` (`675 px/s`), `R_c = 72 px`, `L = 414 px`, `W = 144 px` | `0,60 s` (`36`) | `0,400 s` (`24`) | `1,25 s` (`75`) / `0,75 s` (`45`) | **18** de dano por contato (máx. 1× por avanço); para em parede ou pilar |
| **2** | *Pulso de Soberania* | `anel` (`borda_ao_centro`) | `r_int = 0`, `r_ext = 210 px` centrado no chefe | `0,60 s` (`36`) | `0,200 s` (`12`) | `1,50 s` (`90`) / `0,90 s` (`54`) | **15** de dano + empurrão `900 px/s` em `210 px` **e** `12` projéteis radiais (`30°`, `360 px/s`, `r = 13,5 px`, vida `180` passos, dano **12**) |
| **3** | *Convergência da Fenda* | `circulo` (`borda_ao_centro`) | `R_3 = 225 px` centrado no chefe | `0,70 s` (`42`) | `0,200 s` (`12`) | `1,75 s` (`105`) / `1,05 s` (`63`) | Puxa `75 px` quem está a `≤ 420 px` (F3), causa **14** de dano em `225 px` e invoca até `2` `eco_perdido` (teto de `3` vivos) |

#### 3. Validação de dados (~~`CH1` a `CH7`~~ `CH1` a `CH8`, emenda Pactos, 2026-11-15)

Somam-se às checagens V1–V11 do Conteúdo orientado a dados (R9). O prefixo no validador do Conteúdo é **`CH`** (~~`CH1`–`CH7`~~ `CH1`–`CH8`, emenda Pactos, 2026-11-15):

| Código | Nível | Condição | O que protege |
|---|---|---|---|
| **CH1** | **erro** | Chefe ativo de região (`RegionDef.chefe`) sem exatamente 4 padrões definidos (`0..3`) ou com forma de telégrafo fora de `{setor, retangulo, anel, circulo}` | Garante a máquina de estados determinística de 4 padrões (IA R13 e Telégrafos R5) |
| **CH2** | **erro** | Em qualquer padrão do chefe ou em `ChefesTuning`: `passos(preparo_s) < 1`, `passos(execucao_s) < 1`, `passos(recarga_s × fator_recarga_furia) < 1` ou `passos(transicao_fase_s) < 1`; ou `limiar_furia_frac ∉ (0,10 ; 0,90)` | Impede divisão por zero em F1 e fases/transições de 0 passos |
| **CH3** | **erro** | `lacaios_por_convergencia > max_lacaios_vivos`, ou `lacaio_id` (`eco_perdido`) inexistente no catálogo de `EnemyDef`, ou `raio_puxao_px ≤ R_3` (`225 px`) | Garante consistência da invocação e do puxão da *Convergência* (F3) |
| **CH4** | **aviso** (cruzada com Telégrafos) | Algum padrão do chefe com `folga_i = P_i − passos(reacao_ref_s) < folga_min` (`8` passos, Telégrafos F6; equivale a `P_i < 23` passos) | Protege o Pilar P3 (*Reflexo que se lê*): hoje os 4 padrões têm folga de `15, 21, 21 e 27` passos (`≥ 8`) |
| **CH5** | **aviso** (2ª passada, cruzada com Armas e Combate) | Na F5, para qualquer arma do catálogo e qualquer golpe do chefe: `t_min_morrer_s < 2,0 s` (mesmo critério do IV7 da IA) ou `g_morte < 4` | Impede que o chefe mate qualquer Doutrina sem tempo de reação (hoje `t_min = 2,67 s` a `3,33 s` e `g_morte = 5` a `6` no pior golpe) |
| **CH6** | **aviso** (2ª passada, cruzada com Pipeline e Câmaras) | `1 + max_lacaios_vivos > max_inimigos_onda` (`9`) ou `1 + max_lacaios_vivos > teto_telegrafos` (`24`) | Garante que o chefe + seus lacaios nunca estourem o teto de entidades nem o orçamento de draw calls de telégrafos (hoje `1 + 3 = 4 ≤ 9`) |
| **CH7** | **aviso** | Qualquer campo de `ChefesTuning` ou dos padrões do chefe fora da faixa de design das tabelas acima, ou velocidade em Fúria `≥ 0,80 × min(velocidade_arma)` (hoje `0,80 × 378 = 302,4 px/s`; Ressonância `378`, Lâmina `387`, Pactos `382,5`, Armas e Maldições §Constantes) | Alerta quando um ajuste sai do envelope onde F1–F6 foram provadas (hoje `186,3 < 302,4 px/s`) |
| **CH8** *(emenda Pactos, 2026-11-15)* | **aviso** | `BossPatternDef.raio_secundario_px < 0`; ou `> 0` e `≤` o raio do próprio telégrafo; ou, no padrão com puxão (Padrão 3), `raio_secundario_px ≠ raio_puxao_px` | O contorno tracejado mostra exatamente o alcance do puxão (P3); hoje `420 = 420` |

- **Ficha do Padrão 3 (emenda Pactos, 2026-11-15):** `raio_secundario_px = 420`. Padrões 0, 1 e 2: `raio_secundario_px = 0`.

## Edge Cases

> `systems-designer` e `game-designer` não consultados separadamente nesta seção — modo Lean (`2026-11-15`, regras derivadas de R1–R12 e F1–F6).

- **Se um único golpe derrubar a Vida do chefe de `> 350` direto para `≤ 0` (F4, F6):** a condição `0 < Vida ≤ 350` não se cumpre; o chefe **não** entra em `TransicaoFase` e vai direto para `HitstopFinal` (`36` passos congelados) seguido de `Morto` ou `Subjugado`.
- **Se o chefe atingir `0 < Vida ≤ 350` enquanto está nos `24` passos de avanço do Padrão 1 (R7):** ele termina os passos restantes do avanço normalmente e entra em `TransicaoFase` no 1º passo imediatamente após a `Execucao` (antes de `Recuperacao`), preservando o índice `(padrao + 1) mod 4` para quando sair da transição.
- **Se ticks de `Sangramento` ou `Queimadura` ou um `Selo` no chão estiverem ativos quando o chefe entra em `TransicaoFase` (R7):** os contadores de duração dos status e do Selo continuam correndo nos passos vivos da transição, mas todo dano aplicado ao chefe durante os `30` passos de `TransicaoFase` é multiplicado por `0` (`dano_recebido = 0`).
- **Se a posição lateral `(x_chefe ± 135, y_chefe)` de um lacaio invocado no Padrão 3 cair dentro de um dos 4 pilares ou fora da margem da parede (R5.4, F3):** `ajustar_obstaculos_e_parede` empurra o ponto de nascimento radialmente para fora do pilar (`r_pilar + r_eco + 12 = 51 + 24 + 12 = 87 px`) e o prende ao retângulo `[135, 1785] × [135, 945]`, garantindo que o *Eco Perdido* nunca nasça preso.
- **Se o jogador ou a Maldição estiver em esquiva, investida ou `Saltando` (Chamado do Pacto) no passo do disparo do Padrão 3 (*Convergência*, R5.4) ou no 1º passo de `TransicaoFase` (R7):** a invulnerabilidade/salto ignora tanto o puxão de `75 px` (e os `14` de dano) quanto o pulso repulsor de `120 px`.
- **Se o jogador morrer no mesmo passo vivo em que o chefe chega a `Vida ≤ 0` (Combate R16, Run R5):** a morte do jogador tem precedência; a run encerra em `morte` e nem `chefe_subjugado` nem `camara_limpa` são emitidos.
- **Se o jogador já tiver pactuado o *Soberano do Limiar* numa run anterior e o enfrentar novamente com a Besta do Vínculo (`R9`, `maldicoes.md` R16):** na câmara do chefe ele enfrenta a forma de chefe normalmente (mesmo que traga a forma aliada na sua dupla); ao deixá-lo `Subjugado`, escolher `pactuar` avança o vínculo da espécie em `Vínculo e pactos` (`22d`), ou o jogador pode escolher `exorcizar` para receber os `+6` Fragmentos.

## Dependencies

### Depends On (Upstream)
- **IA de inimigos e elites (`Forte`):** fornece a estrutura de fases (`Surgindo`, `Aproximacao`, `Preparo`, `Execucao`, `Recuperacao`), a colisão/separação (IA R9) e a IA dos lacaios `eco_perdido`.
- **Telégrafos (`Forte`):** fornece o ciclo de vida e renderização das 4 formas (`setor`, `retangulo`, `anel`, `circulo`, Telégrafos R5/R8).
- **Combate núcleo (`Forte`):** fornece `ferir_jogador`, `ferir_maldicao`, `disparar_projetil`, a armadura contra cambaleio/`"Quebrou!"` (R8.7) e o congelamento/impact frame de abate de chefe (`hitstop_abate_chefe_s`, `impact_chefe_s`).
- **Modificadores e atributos (`Forte`):** fornece o portador do chefe, `fator_empurrao_chefe = 0,12` e o efeito de `Abalo`.
- **Câmaras e ondas (`Forte`):** monta a arena fixa da câmara `chefe` (Câmaras R14: 4 pilares de `51 px` e spawn em `(960; 285)`). **(emenda Pactos, 2026-11-15)** É a única emissora de `camara_limpa(4, chefe)`; recebe `limpar_camara_chefe()` dos Chefes no fim de `Subjugado` (Câmaras R18-P, R9b daqui).
- **Combate núcleo — desfecho (emenda Pactos, 2026-11-15):** lê a marca `subjugavel` e executa `resolver_subjugado(id, escolha)` (Combate R24).
- **Pipeline visual e Telégrafos (`Suave`, emenda Pactos, 2026-11-15):** desenham o contorno secundário a partir de `raio_secundario_px` (Pipeline R5a, Telégrafos R5a).
- **Conteúdo orientado a dados (`Forte`):** carrega e valida `ChefesTuning` e o `EnemyDef` com `comportamento = chefe` (`CH1–CH7`).
- **Maldições (`Suave`):** fornece o contrato de atração (`R7` de `maldicoes.md`) e a posição da Maldição em campo.
- **Vínculo e pactos (`Forte`, por contrato):** recebe `chefe_subjugado("soberano_do_limiar")` quando `doutrina == pactos` e devolve a escolha `pactuar` ou `exorcizar`.

### Depended On By (Downstream)
- **Run e regiões (`Forte`):** inclui a 7ª câmara (`chefe`, índice `6`) no Limiar do MVP (`22e`) e encerra a run em vitória ao receber `camara_limpa(4, chefe)`.
- **Economia de Fragmentos (`Forte`, por contrato):** recebe `creditar(chefe, 6)` quando o chefe é abatido ou exorcizado.
- **HUD (`Suave`, por contrato):** ativa a Barra de Chefe no topo da tela (HUD R11) lendo Vida, `vida_max` e fase.
- **Maldições e Vínculo e pactos (`Forte`):** desbloqueiam/evoluem a espécie Primordial `soberano_do_limiar` a partir deste chefe (`ML4`, `maldicoes.md` R16).

## Visual/Audio Requirements

> `art-director` consultado via regras do Art Bible (§2.7, §2.9, §3.2, §3.3, §4.5, §7.8 — modo Lean, `2026-11-15`).

- **CH-V1. Silhueta e distinção de escala (Art Bible §3.2, §3.3):** em sua forma hostil de Maldição-chefe, o **Soberano do Limiar** tem `~1,8×` a altura do Iniciado (`raio_px = 45 px`, maior que os `28,5 px` da sua forma aliada contida), coroa de cristais abertos irradiando **Magenta (`#E0259C`)** exposto e correntes de Osso partidas arrastando no chão (ao ser pactuado em `maldicoes.md`, os cristais são selados por anéis de Osso e o magenta exposto some).
- **CH-V2. Clima da arena (Art Bible §2.7):** a névoa fria do Limiar abre-se em círculo ao redor do centro e o núcleo magenta do chefe torna-se a fonte de contraste principal sobre os 4 pilares escuros.
- **CH-V3. Leitura da Fase 2 (`TransicaoFase` e `Fúria`):** no 1º passo de `TransicaoFase`, um anel de tinta e osso expande até `240 px`; durante a Fase 2 (`em_furia = true`), as rachaduras do torso e da coroa mantêm brilho magenta contínuo e os passos deixam rastro curto de tinta.
- **CH-V4. Estado `Subjugado` e desfecho (Art Bible §2.9):** após o *impact frame* em Osso com manchas pretas (`impact_chefe_s`), se o jogador estiver em Pactos, o chefe cai apoiado num joelho com o brilho magenta recolhido e um halo de Osso aguardando a decisão; se for abatido/exorcizado, o magenta se desfaz em partículas e a arena esquenta levemente.
- **CH-A1. Ganchos de áudio:** `chefe_surgimento`, `chefe_preparo_garra`, `chefe_avanco_irrupcao`, `chefe_pulso_soberania`, `chefe_convergencia_puxao`, `chefe_transicao_furia`, `chefe_subjugado` e `chefe_derrotado`.

## Game Feel

- **Espelho pedagógico:** quem enfrenta o *Soberano do Limiar* reconhece nos 4 padrões exatamente os movimentos que ele executa (em versão compacta e aliada) quando pactuado: o corte em arco (*Garra do Véu Rasgado*), o avanço (*Irrupção*), o anel pesado (*Pulso de Soberania*) e o puxão (*Convergência*).
- **Fúria justa (P3):** acelerar apenas as recargas (`× 0,60`) e o caminhar (`× 1,15`) na Fase 2 — mantendo os preparos `P_i` intactos em `0,50 s` a `0,70 s` — aumenta a pressão e reduz o tempo de descanso do jogador sem transformar os telégrafos em adivinhação.
- **Catarse do último golpe:** os `36` passos (`0,60 s`) de hitstop combinados com o *impact frame* e o desaparecimento simultâneo dos lacaios e projéteis dão peso imediato à vitória.

## UI Requirements

- **Ativação da Barra de Chefe (HUD R11):**
  - Posicionada no topo central (`960 × 14 px` a `100%`, `y = 48 px`), com o nome `"Soberano do Limiar"` em `H2` acima da barra.
  - Exibe um **entalhe vertical visível exatamente em `50%` (`350 HP`)** marcando o limiar de Fúria (`limiar_furia_frac`). Quando `TransicaoFase` dispara, o entalhe racha e a barra pulsa uma vez.
  - Durante os `30` passos invulneráveis de `TransicaoFase`, a moldura da barra fica em Osso claro sólido (indicando invulnerabilidade).
  - Quando o chefe entra em `Subjugado` (ou `Morto`), a barra de chefe faz fade-out em `0,25 s` para dar lugar à escolha de `Vínculo e pactos` ou ao encerramento da câmara.

## Cross-References

- [ia-de-inimigos-e-elites.md](ia-de-inimigos-e-elites.md) (R1, R4, R7, R8, R13 máquina de estados e fúria `× 0,6`)
- [telegrafos.md](telegrafos.md) (R5, R8, F1–F6 formas `setor`, `retangulo`, `anel` e `circulo`)
- [camaras-e-ondas.md](camaras-e-ondas.md) (R3 profundidade `p = 4` mantida no chefe, R14 arena fixa com 4 pilares e spawn `(960; 285)`)
- [combate-nucleo.md](combate-nucleo.md) (R8.7 armadura, R14/R15 `hitstop_abate_chefe_s` e `impact_chefe_s`)
- [modificadores-e-atributos.md](modificadores-e-atributos.md) (R10 fonte `chefe`, `fator_empurrao_chefe = 0,12`)
- [maldicoes.md](maldicoes.md) (R7 atração, R16 forma aliada Primordial de `soberano_do_limiar`, OQ2 resolvida)
- [hud.md](hud.md) (R11 barra de chefe no topo central)
- `vinculo-e-pactos.md` (#38 / 22d — consome `chefe_subjugado` para a escolha `pactuar` vs. `exorcizar`)
- [run-e-regioes.md](run-e-regioes.md) (emenda 22e — inclui a 7ª câmara `chefe` no Limiar do MVP)

## Acceptance Criteria

> `qa-lead` não consultado separadamente — modo Lean (`2026-11-15`; 22 critérios verificáveis cobrindo R1–R12, F1–F6 e CH1–CH7).

- **AC-CH-01 (R1, R2 — Montagem da câmara do chefe e abertura determinística):** **GIVEN** a entrada na câmara de índice `6` (`tipo = chefe`) do Limiar, **WHEN** o corte da metade do wipe executa, **THEN** a arena monta os 4 pilares de `51 px` em `(390; 300)`, `(1530; 300)`, `(390; 750)` e `(1530; 750)`, o jogador nasce em `(960; 930)` e `soberano_do_limiar` nasce em `(960; 285)` com `Vida = 700` (sem `+5%/p`), em `Surgindo` por `50` passos seguido de `Aproximacao` com `timer = 30` passos e `padrao = 0`, sem consumir os fluxos `layout`, `ondas`, `elites`, `spawn` ou `ia` do RNG.
- **AC-CH-02 (R1 — Armadura total e resistência a empurrão):** **GIVEN** `soberano_do_limiar` em `Preparo` do Padrão 0 (`restante = 15`), **WHEN** o jogador o acerta com o 3º Corte pesado da Lâmina (`dano = 25,2`, `empurrao = 900`), **THEN** o chefe sofre `25,2` de dano, recebe velocidade de empurrão inicial `900 × 0,12 = 108 px/s`, **não** cambaleia, **não** sofre `"Quebrou!"` e o telégrafo continua avançando para `restante = 14`.
- **AC-CH-03 (R1 — Imunidade a imobilização e aceitação de Abalo/status):** **GIVEN** `soberano_do_limiar` em campo, **WHEN** recebe o pouso do *Chamado do Pacto* (`duracao_imobilizar_s = 1,5 s`, `duracao_atracao_s = 3,0 s`) e um efeito de `Abalo` (`4,0 s`), **THEN** o chefe **não** fica imobilizado, mas fica `atraído` por `180` passos e com `Abalo` ativo (`dano causado × 0,70`). **(emenda Pactos, 2026-11-15)** Com a Maldições R17/F4b (`duracao_atracao_s = 1,5 s`, respiro `0,5 s`): `atraído` por **`90`** passos; um 2º Chamado nos `30` passos seguintes é recusado pelo chefe.
- **AC-CH-04 (R4, R5.1, F1, F2 — Padrão 0 *Garra do Véu Rasgado*):** **GIVEN** o chefe em `Aproximacao` com `padrao = 0`, `timer = 0` e o jogador a `150 px` (`≤ 180 px`) na direção `(0, 1)`, **WHEN** correm `30` passos vivos de preparo, **THEN** no 30º passo o telégrafo `setor` (`R_0 = 165 px`, `78,46°`) dispara causando `16` de dano se o jogador continuar no setor, o chefe fica parado `10` passos em `Execucao` e entra em `Recuperacao` por `60` passos (`Fase 1`) com `padrao = 1`.
- **AC-CH-05 (R4, R5.2, F1, F2 — Padrão 1 *Irrupção do Limiar*):** **GIVEN** o chefe em `Aproximacao` com `padrao = 1` e `timer = 0` a `400 px` do jogador, **WHEN** inicia o preparo (`36` passos) e executa os `24` passos de avanço, **THEN** o chefe avança `11,25 px/passo` (`270 px` totais, ignorando lentidão do Selo), fere o jogador por contato (`dist < 72 px`) no máximo `1` vez com `18` de dano (mesmo permanecendo sobreposto em passos seguintes do avanço) e entra em `Recuperacao` por `75` passos com `padrao = 2`.
- **AC-CH-06 (R5.2 — Colisão do avanço com pilar ou parede):** **GIVEN** o chefe executando o Padrão 1 em direção ao pilar em `(390; 300)`, **WHEN** o corpo do chefe encosta no limite `r_pilar + r_chefe = 96 px` no 10º passo da execução, **THEN** a posição para ali nos `14` passos restantes da execução sem atravessar o pilar.
- **AC-CH-07 (R5.3, F1, F2 — Padrão 2 *Pulso de Soberania* e 12 projéteis radiais):** **GIVEN** o chefe concluindo os `36` passos de preparo do Padrão 2, **WHEN** o telégrafo `anel` (`210 px`) dispara, **THEN** o alvo travado (o jogador) a `≤ 210 px` sofre `15` de dano e empurrão de `900 px/s` e uma Maldição em campo a `≤ 210 px` não sofre dano (R3), nascem exatamente `12` projéteis a `54 px` do centro separados por `30°` (`360 px/s`, `r = 13,5 px`, vida `180` passos, `12` de dano), e o chefe cumpre `12` passos de execução + `90` de recuperação (`padrao = 3`).
- **AC-CH-08 (R5.4, F3 — Padrão 3 *Convergência da Fenda*: puxão antes do impacto):** **GIVEN** o chefe em `(960, 285)` concluindo os `42` passos de preparo do Padrão 3 e o jogador em `(960, 565)` (`d = 280 px`, fora de `225 px` mas `≤ 420 px`, sem esquiva ativa), **WHEN** o disparo resolve, **THEN** o jogador é puxado `75 px` para `(960, 490)` (`d' = 205 px ≤ 225 px`) e no mesmo passo recebe os `14` de dano do círculo.
- **AC-CH-09 (R5.4, R8, F3 — Invocação controlada com teto `max_lacaios_vivos = 3`):** **GIVEN** o disparo do Padrão 3 com `0` lacaios vivos na arena, **WHEN** a invocação executa, **THEN** nascem `2` `eco_perdido` comuns (`Vida = 30`, `invocado_pelo_chefe = true`, `Surgindo = 50` passos) em `(x_chefe − 135, y_chefe)` e `(x_chefe + 135, y_chefe)`; se no ciclo seguinte esses `2` continuarem vivos (`n_lacaios_vivos = 2`), o novo disparo do Padrão 3 invoca apenas `1` `eco_perdido` (atingindo o teto `3`), e com `3` vivos invoca `0`.
- **AC-CH-10 (R4, R6 — Fechamento do ciclo `3 → 0` e espera fixa):** **GIVEN** o chefe terminando os `105` passos de recuperação do Padrão 3 na Fase 1, **WHEN** entra em `Aproximacao`, **THEN** `padrao` volta a `0` e `timer` recebe exatamente `15` passos (`0,25 s`).
- **AC-CH-11 (R3 — Atração do chefe pela Maldição aliada):** **GIVEN** o chefe atraído por `vulto_mudo` em `(700, 400)` enquanto o jogador está em `(1200, 700)`, **WHEN** o chefe inicia o preparo do Padrão 0, **THEN** a mira travada aponta para `(700, 400)` (a Maldição) e, no disparo, o setor testa e fere a Maldição (`16` de dano pela F3 do Modificadores), sem ferir o jogador mesmo que o jogador entre no setor depois.
- **AC-CH-12 (R7, F4 — Gatilho de `TransicaoFase` aos `350 HP` e cancelamento de preparo):** **GIVEN** o chefe na Fase 1 em `Preparo` do Padrão 2 com `Vida = 360` e o jogador a `130 px`, **WHEN** o chefe sofre `25` de dano (`Vida = 335 ≤ 350`), **THEN** no mesmo passo o telégrafo do Padrão 2 é cancelado sem disparar, o chefe entra em `TransicaoFase` por `30` passos vivos, o jogador é empurrado `120 px` para `250 px` sem sofrer dano, e qualquer ataque que acerte o chefe durante os `30` passos causa `0` de dano.
- **AC-CH-13 (R7, F1, F4 — Efeitos da Fase 2 / Fúria):** **GIVEN** o chefe concluindo os `30` passos de `TransicaoFase`, **WHEN** opera na Fase 2 (`em_furia = true`), **THEN** sua velocidade de andar é `186,3 px/s` (`162 × 1,15`), os tempos de preparo `P_i` continuam `30 / 36 / 36 / 42` passos e as recargas `R_i` passam a `36 / 45 / 54 / 63` passos (`× 0,60`, rotação `C_rot = 400` passos).
- **AC-CH-14 (Edge Case — Dano letal direto de `> 350` para `≤ 0`):** **GIVEN** o chefe na Fase 1 com `Vida = 355` (em build/teste de alto dano), **WHEN** sofre um único golpe de `400` de dano (`Vida ≤ 0`), **THEN** ele **não** entra em `TransicaoFase` e vai direto para `HitstopFinal`.
- **AC-CH-15 (R8, R9, F6 — Limpeza imediata de lacaios e projéteis ao zerar a Vida):** **GIVEN** uma run de `lamina`, o chefe com `Vida = 10`, `2` *Ecos Perdidos* invocados vivos (`invocado_pelo_chefe = true`), `6` projéteis inimigos em voo, contagem de abates `= 20` e o jogador com `Vida = 60/100` e bênção `cura_ao_abater = 4`, **WHEN** o jogador aplica `14` de dano no chefe no passo `s`, **THEN** no próprio passo `s` os `2` lacaios e os `6` projéteis são removidos, o jogador termina o passo com `Vida = 64/100` (só o `+4` do chefe), a contagem de abates fica `21` e os `36` passos seguintes ficam congelados (`hitstop_abate_chefe_s`). Na mesma cena com `pactos`, o jogador termina o passo `s` com `Vida = 60/100` e abates `= 20`, e só recebe `+4` e abate `21` no passo em que escolher `exorcizar` (R9).
- **AC-CH-16 (R9, F6 — Desfecho direto com Lâmina ou Ressonância):** **GIVEN** o jogador equipado com `lamina` (ou `ressonancia`) zerando a Vida do chefe, **WHEN** terminam os `36` passos de hitstop, **THEN** o chefe entra em `Morto`, a Economia credita `+6` Fragmentos (`creditar(chefe, 6)`) e sai `camara_limpa(4, chefe)` no mesmo passo vivo.
- **AC-CH-17 (R9, F6 — Desfecho `Subjugado` em Pactos: escolha `pactuar`):** **GIVEN** o jogador equipado com `pactos` (`Besta do Vínculo`) zerando a Vida do chefe, **WHEN** terminam os `36` passos de hitstop e o jogador escolhe `pactuar` em `Vínculo e pactos`, **THEN** o chefe entra primeiro em `Subjugado` emitindo `chefe_subjugado("soberano_do_limiar")` e, após `pactuar`, `0` Fragmentos de chefe são creditados, o pacto/vínculo com `soberano_do_limiar` é registrado e sai `camara_limpa(4, chefe)`.
- **AC-CH-18 (R9, F6 — Desfecho `Subjugado` em Pactos: escolha `exorcizar`):** **GIVEN** o chefe em `Subjugado` numa run de `pactos`, **WHEN** o jogador escolhe `exorcizar`, **THEN** a Economia credita `+6` Fragmentos (`creditar(chefe, 6)`) e sai `camara_limpa(4, chefe)`.
- **AC-CH-19 (Edge Case — Morte simultânea do jogador e do chefe):** **GIVEN** o jogador com `Vida = 5` e o chefe com `Vida = 8`, **WHEN** no mesmo passo vivo um golpe do jogador zera o chefe e um projétil/golpe inimigo zera o jogador (sem recusa de morte), **THEN** vence `jogador_morreu` (Run R5 / Combate R16) e a run encerra em `morte`.
- **AC-CH-20 (R10 — Barra de Chefe no HUD):** **GIVEN** o chefe ativo na câmara com `Vida = 700/700`, **WHEN** sofre dano até `340/700`, **THEN** o HUD exibe a barra de chefe no topo central (`960 × 14 px`, sem fio sob os pés do chefe), atualiza a Vida no mesmo passo e aciona o estado visual de Fúria no entalhe de `50%`.
- **AC-CH-21 (F5, CH5 — Sobrevivência mínima de todas as Doutrinas):** **GIVEN** os dados de catálogo das 3 armas do MVP (`80, 90, 100 HP`) e os danos do chefe (`máx. 18`), **WHEN** a validação cruzada `CH5` calcula `g_morte` e `t_min_morrer_s`, **THEN** todas as armas exigem `≥ 5` golpes (`5` a `6`) e têm `t_min_morrer_s ≥ 2,67 s ≥ 2,0 s`, gerando `0` avisos `CH5`.
- **AC-CH-22 (CH1, CH2, CH3 — Erros de validação do catálogo de chefes):** **GIVEN** três definições inválidas injetadas em teste (chefe com apenas `3` padrões; padrão com `preparo_s = 0`; `ChefesTuning` com `lacaios_por_convergencia = 4 > max_lacaios_vivos = 3`), **WHEN** o validador do Conteúdo executa, **THEN** a carga falha reportando respectivamente os erros `CH1`, `CH2` e `CH3`.

**Critérios da emenda Pactos (2026-11-15)** — 5 novos (total 27):

- **AC-CH-23 (R9b.1 — Marca `subjugavel`):** **GIVEN** a câmara do chefe, **WHEN** o chefe nasce numa run de `pactos`, **THEN** o estado dele tem `subjugavel = true`; numa run de `lamina` ou `ressonancia`, `false`; a marca não muda até o fim da luta.
- **AC-CH-24 (R9b.3, R9b.4 — Ordem e emissora única):** **GIVEN** o chefe em `Subjugado` e espiões no Combate, na Economia e nas Câmaras, **WHEN** chega `exorcizar`, **THEN** no mesmo passo vivo saem, nesta ordem, `resolver_subjugado(id, exorcizar)`, `creditar(chefe, 6)` e `limpar_camara_chefe()`; `camara_limpa(4, chefe)` sai uma vez, emitido pelas Câmaras; o módulo de Chefes não emite `camara_limpa` em nenhum caso. Com `pactuar`: `resolver_subjugado(id, pactuar)` e `limpar_camara_chefe()`, sem `creditar`. Uma 2ª escolha não gera chamada nenhuma.
- **AC-CH-25 (R9b.4 — Fora de Pactos):** **GIVEN** uma run de `lamina` que zera o chefe no passo `640`, **WHEN** chega o passo `677`, **THEN** os Chefes creditam `6`, **não** chamam `limpar_camara_chefe()`, e `camara_limpa(4, chefe)` sai das Câmaras pela lista vazia.
- **AC-CH-26 (R11, CH8 — `raio_secundario_px`):** **GIVEN** o `EnemyDef` de fábrica, **WHEN** carrega, **THEN** o Padrão 3 tem `raio_secundario_px = 420` e os Padrões 0–2 têm `0`, com zero avisos CH8; com `raio_secundario_px = 200` no Padrão 3 (`≤ 225`) sai CH8; o puxão continua em `420 px` mesmo com o campo mudado.
- **AC-CH-27 (R5.3 — Radiais só no alvo travado):** **GIVEN** o Padrão 2 travado no jogador, com a Maldição em campo na linha de um projétil a `150 px` do chefe, **WHEN** os `12` projéteis disparam, **THEN** o projétil atravessa a Maldição sem dano e sem sumir e só pode ferir o jogador; travado na Maldição (chefe atraído), o jogador na linha é atravessado sem dano.
- **F6 (emenda):** os totais `25` (Pactuar) e `31` (Exorcizar) são verificados pela Run (AC da Run F2-P), não aqui.

## Open Questions

1. **OQ1 — Interação para abrir a escolha em `Subjugado` (para o GDD `22d` de Vínculo e pactos):** ao terminar os `36` passos de hitstop em Pactos, a tela/escolha `Pactuar vs. Exorcizar` abre automaticamente ou exige que o jogador caminhe até o chefe ajoelhado e aperte `Interagir`?
2. **OQ2 — Emendas formais nos GDDs aprovados (`IA`, `Telégrafos`, `Câmaras`, `Conteúdo`, `HUD`):** tirar a marca `"reservado / fatia vertical"` do comportamento `chefe`, do tipo de sala `chefe` e da Barra de Chefe quando fecharmos a batelada `22a–22f`. Somam-se os contratos da emenda Pactos (2026-11-15): **Combate R14** (lacaios invocados sem abate nem `ao_abater`; chefe de Pactos fica na lista em `Subjugado`), **Câmaras** (fase `Subjugado` com `em_combate = falso`; respondido em Câmaras R8-P/R18-P, e o pedido de volta — `limpar_camara_chefe()` e Câmaras como única emissora — está na R9b) e **Telégrafos R7** (nova causa de cancelamento: entrada do chefe em `TransicaoFase`, o telégrafo some como no "Cancelado" e não dispara).
3. **OQ3 — *Anomalia Maior* na Fatia Vertical:** na Fatia Vertical (quando o Limiar tiver os 2 chefes possíveis ou o *Soberano do Limiar* passar a encontro especial de chefe), sortear qual chefe fecha o Limiar pelo fluxo de estrutura do RNG ou alternar conforme a Doutrina?
4. **OQ4 — Linha de cânone do *Soberano do Limiar*:** incluir junto à OQ5 de `maldicoes.md` o registro do nome canônico `"Soberano do Limiar"` em `assets/data/canon/` como a Maldição Primordial do Limiar da Beira.
