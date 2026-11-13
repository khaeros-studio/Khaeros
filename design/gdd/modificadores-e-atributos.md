# Modificadores e atributos

> **Status**: Approved (2026-11-09: nota da exceção de `cura_ao_abater` com o jogador morto, R13, e piso 1 na Vida da recusa de morte, R13, alinhado ao Combate núcleo R13/F10 com aval do usuário; re-review 2026-11-08, lean: APPROVED, 0 bloqueantes — confirmou os warnings da 1ª e da 2ª passada do `/review-all-gdds` de 2026-11-06 aplicados aqui: C-W1, C-W5, C-I1, OQ6 fechada, dependentes Câmaras e ondas e Chefes, Cross-References; esta re-review não tem entrada no `reviews/modificadores-e-atributos-review-log.md`, por escolha do usuário)
> **Author**: usuário + Claude (design-system)
> **Last Updated**: 2026-11-06 (tokens de forma em PT na R12, AC-29 com arma de fábrica, V11 e `ModifiersTuning` citados do Conteúdo; 2ª passada do cross-review: Câmaras e ondas e Chefes como dependentes, Cross-References)
> **Last Verified**: 2026-11-08
> **Implements Pillar**: P1 *Toda bênção é uma filosofia* (bênçãos como dado; só os 8 gatilhos têm executor próprio); P2 *A Beira cobra* (preços visíveis)
> **Creative Director Review (CD-GDD-ALIGN)**: pulada (modo Lean)

## Summary

**Modificadores e atributos** é o encanamento único por onde bênçãos, Oficina,
status e elites mudam números de combate. Todo combatente tem atributos
recalculados a partir da base e da lista de modificadores ativos, sempre como
(base + planos) × (1 + percentuais) × multiplicadores, o que reproduz os números
do cânone, com as poucas divergências deliberadas listadas em Formulas. O sistema é dono da lista fechada dos 21 tipos de efeito, mapeados
das chaves do cânone; os gatilhos (explosão ao abater, recusar a morte etc.) são
registrados aqui e executados pelos sistemas donos.

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `Conteúdo orientado a dados`

> **Nota (2026-11-11, revisão cruzada):** pendente: Dependencies listam Status (`abalado()`) e Armas; a base de `trocas_oferta` tem dono único `trocas_iniciais` (Bênçãos OQ 11), o atributo só soma. Resolvidos em 2026-11-12: teto do M (4,0, F2/AC-04b) e dono da Vida por profundidade (IA F2).

## Overview

**Modificadores e atributos** é o encanamento único por onde bênçãos, melhorias
da Oficina, status e regras de elite mudam números de combate. Todo
**portador** (jogador, inimigos, elites, chefes e, no Alpha, a criatura do pacto)
tem **atributos**:

- Vida máxima;
- velocidade;
- dano geral e por slot (Ataque, Especial, Selo);
- redução de dano;
- cargas de esquiva e outros.

Cada atributo é **recalculado** a partir de uma base (dado da arma ou do
inimigo) e da lista de **modificadores ativos**. Cada modificador traz fonte,
operação, valor e, se tiver, duração.

A combinação é sempre a mesma: **(base + somas planas) × (1 + soma dos
percentuais) × produto dos multiplicadores**, com teto e piso por atributo. Os
"+%" de bênção e Oficina somam entre si, como no cânone; só efeitos marcados como
multiplicador multiplicam.

Este sistema também é dono da **lista fechada de tipos de efeito** que o
`EffectDef` do Conteúdo pode citar, incluindo os **gatilhos** (explosão ao
abater, corte da esquiva, recusar a morte, refletir dano, curar ao abater). Ele
registra o gatilho e seus parâmetros; quem executa é o sistema dono (Combate,
Movimento, Status).

O jogador sente este sistema como "cada Tradição muda meu jeito de lutar e eu
vejo exatamente quanto". Sem ele, cada bênção viraria código especial, os status
temporários não teriam como sair, e a Oficina, as bênçãos e os status
reescreveriam os mesmos números de jeitos diferentes.

> **→ vira ADR crítico** (índice, High-Risk Systems): a representação em código
> (lista por portador, cache do valor derivado, quando recalcular).

## Detailed Design

### Core Rules

> `systems-designer`, `gameplay-programmer` e `engine-programmer` não foram
> consultados: modo Lean. Revisar manualmente antes de produção. As 21 chaves de
> `PlayerMods` (`action-core/src/types.ts`) estão todas mapeadas na R5.

**R1. Portador, atributo e recurso.**

- Todo combatente é um **portador**. Ele tem **atributos**, derivados da base e
  dos modificadores (R3), e **recursos**: valores correntes que se gastam, como
  Vida atual, escudo, cargas de esquiva restantes e recusas de morte restantes.
- Os recursos pertencem aos sistemas donos. Este sistema só diz como uma mudança
  de atributo afeta o recurso (R9).

**R2. Atributos (lista fechada, MVP).**

| Atributo | Base | Piso / teto | Quem lê |
|---|---|---|---|
| `vida_max` | `WeaponDef` / `EnemyDef` | ≥ 20 no jogador (cânone); ≥ 1 em inimigos | Combate |
| `velocidade` | `WeaponDef.velocidade` / `EnemyDef` | ≥ 0 | Movimento, IA |
| `dano_ataque`, `dano_especial`, `dano_selo` | — (acumulador de percentual, lido só pela F2) | — | Combate, Selo |
| `dano_todo` | — (acumulador de percentual e de multiplicadores; entra em todo slot pela F2) | — | Combate |
| `reducao_dano` | 0 | 0 – 0,6 (cânone) | Combate |
| `cargas_esquiva` | `MovementTuning` | ≥ 1 | Movimento |
| `escudo_sala` | 0 | ≥ 0 | Combate |
| `trocas_oferta` | 0 | ≥ 0 | Bênçãos |
| `recusas_morte` | 0 | ≥ 0 | Combate |
| `raio` | `EnemyDef` | > 0 | Combate (colisão) |
| `fator_empurrao` | 1 (multiplica o empurrão recebido) | 0 – 1 | Combate |

Os pisos e tetos ficam no `ModifiersTuning`. Um atributo novo entra nesta tabela
antes de ser usado. Os atributos de dano não passam pela F1: somar os grupos e
multiplicá-los, como (1 + todo) × (1 + slot), daria ~18% acima do cânone. São
**inteiros por natureza** (arredondados no fim da F1): `vida_max`,
`escudo_sala`, `cargas_esquiva`, `recusas_morte` e `trocas_oferta`. Não há
atributo de dano da esquiva: o Corte da esquiva e o impacto na parede usam o
grupo do **Ataque** (R12), como no cânone, e o Traço Único também os aumenta.
`valor()` não se aplica aos acumuladores `dano_*`: o dano se consulta só por
`multiplicador_de_dano` (F2).

**`ModifiersTuning`** (dado; listado na tabela de `*Tuning` da R1 do Conteúdo):

| Campo | Valor inicial | Faixa | Uso |
|---|---|---|---|
| `piso_vida_jogador` | 20 | 1 – 100 | piso de `vida_max` do jogador (F1) |
| `piso_vida_inimigo` | 1 | ≥ 1 | piso de `vida_max` de inimigos (F1) |
| `teto_reducao_dano` | 0,6 | 0 – 0,9 | teto de `reducao_dano` (F3) |
| `teto_multiplicador_dano` | 4,0 (provisório) | 2–8 | teto do M efetivo da F2 (`min(M, teto)`); M 14,08 → 4,0; DPS máx. de Armas F1 ≈ 66,47 × 4 = 265,9; `/balance-check` confirma antes da fatia vertical |
| `fator_empurrao_chefe` | 0,12 | 0 – 1 | multiplicador de `fator_empurrao` da fonte `chefe` (R10) |

**R3. Modificador.** Um modificador tem:

- **atributo**;
- **operação**: `plano`, `percentual` ou `multiplicador`;
- **valor**: já escalado pela raridade (Conteúdo R1);
- **fonte**: id da bênção, melhoria, status, elite, chefe ou profundidade;
- **duração**: permanente na run, ou um número **inteiro de passos** de física
  (o dado em segundos é convertido pelo F7 do Conteúdo);
- **condição**, opcional (R4). Só modificadores de `dano_todo` podem ter
  condição; a validação recusa condição em outro atributo.

**R4. Condições (lista fechada).** Um modificador condicional só conta quando a
condição é verdadeira **no momento do uso** (o golpe). Quem consulta passa o
contexto.

- `vida_abaixo`, com param `limiar_vida`: Vida atual < limiar × `vida_max`.
- `enesimo_acerto`, com param `a_cada`: o contador de acertos do portador é
  múltiplo de `a_cada` e maior que 0. O contador é do Combate: +1 **por alvo**
  atingido por golpe de **arma** (Ataque, Especial, investida, projétil da
  arma), incrementado **antes** da checagem, começando em 0. A condição é
  avaliada **por alvo**, no impacto (cânone, `damageEnemy`).
- `apos_esquiva`, com param `janela_s`: a janela abre no **início** da esquiva e
  conta passos de jogo. É consumida ao **disparar** Ataque ou Especial, acerte
  ou não, e vale para **todos os alvos** daquele golpe (cânone, `empowerTicks`).
  O Combate guarda a janela e passa só `contexto.apos_esquiva` (verdadeiro ou
  falso).

Os condicionais de multiplicador têm o param **`slots`**: pós-esquiva e 4º acerto
valem só para **Ataque e Especial**, nunca para Selo, explosão, reflexo ou
esquiva (cânone). `slots` ausente quer dizer todos.

**R5. Tipos de efeito (lista fechada; as 21 chaves do cânone).** Um `EffectDef`
só pode citar estes tipos (Conteúdo V4).

- **De atributo:** o tipo vira um modificador.
- **De gatilho:** o tipo fica ativo no portador com `valor` e `params`, e **o
  sistema dono executa**.

| Tipo | Cânone | Espécie | Efeito / params | Executor |
|---|---|---|---|---|
| `dano_ataque_pct` | `attackDmg` | atributo | `dano_ataque` percentual | — |
| `dano_especial_pct` | `specialDmg` | atributo | `dano_especial` percentual | — |
| `dano_selo_pct` | `castDmg` | atributo | `dano_selo` percentual | — |
| `dano_todo_pct` | `allDmg` | atributo | `dano_todo` percentual | — |
| `dano_vida_baixa_pct` | `lowHpDmg` | atributo condicional | `dano_todo` percentual se `vida_abaixo` (`limiar_vida` 0,5) | — |
| `dano_enesimo_acerto` | `nthHitDouble` | atributo condicional | `dano_todo` multiplicador (1 + valor) se `enesimo_acerto` (`a_cada` 4); `slots` ataque, especial | — |
| `dano_apos_esquiva` | `dashEmpower` | atributo condicional | `dano_todo` multiplicador (1 + valor) se `apos_esquiva` (`janela_s` 1,5); `slots` ataque, especial | — |
| `vida_max_plano` | `maxHp` | atributo | `vida_max` plano (pode ser negativo: Preço com Nome) | — |
| `velocidade_pct` | `moveSpeed` | atributo | `velocidade` percentual | — |
| `reducao_dano` | `damageReduction` | atributo | `reducao_dano` plano | — |
| `cargas_esquiva` | `extraDash` | atributo | `cargas_esquiva` plano | — |
| `escudo_sala` | `roomShield` | atributo | `escudo_sala` plano | — |
| `trocas_oferta` | `boonRerolls` | atributo | `trocas_oferta` plano | — |
| `recusas_morte` | `deathDefiance` | atributo + gatilho | `recusas_morte` plano; params `vida_ao_voltar` 0,4, `invuln_s` 2,0 | Combate |
| `golpe_sangramento` | `attackBleed` | gatilho | acúmulos de Sangramento por alvo de golpe de arma = valor (fracionário) | Efeitos de status |
| `golpe_queimadura` | `attackBurn` | gatilho | acúmulos de Queimadura por alvo de golpe de arma = valor (fracionário) | Efeitos de status |
| `corte_da_esquiva` | `dashDamage` | gatilho | dano = valor × M(grupo Ataque); params `sangramento`, `alcance_extra_px`, `empurrao` | Movimento / Combate |
| `explosao_ao_abater` | `killExplode` | gatilho | dano = valor, **sem** M; params `raio_px`, `empurrao` | Combate |
| `cura_ao_abater` | `healOnKill` | gatilho | Vida curada = valor | Combate |
| `refletir_dano` | `reflect` | gatilho | fator do dano devolvido = valor (já inclui o ×3 do cânone) | Combate |
| `selo_abala` | `castWeaken` | gatilho | o Selo aplica Abalo; param `duracao_s` | Selo / Status |

A semântica obrigatória de cada gatilho está na R13. `empurrao` é velocidade inicial
em px/s (valor do cânone convertido pela F2 do Conteúdo, × 90).

O **Abalo** (inimigo causa −30%) é um modificador **multiplicador** 0,7 em
`dano_todo` do portador atingido, não um percentual, para não somar com outros
bônus. É **uma** fonte única de status por portador: reaplicar não acumula
(× 0,7, nunca × 0,49) e a duração passa a ser `max(restante, nova)`, para o Selo
nunca encurtar um Abalo mais longo (cânone). O fator 0,7 é
`1 − reducao_dano_causado` (0,3) do `StatusTuning`, o campo que o texto da Forma
Fixa exibe (Conteúdo). O `selo_abala` usa `duracao_s` 0,5,
renovada enquanto o alvo está no Selo (cânone). O Abalo vale para **todo** dano
que o portador causa, inclusive projéteis: o projétil leva o × 0,7 se o
atacante estava Abalado **ao disparar**. Isso é uma divergência deliberada do
cânone (que só enfraquece golpe direto), decidida pelo usuário para combinar
com o texto da Forma Fixa ("inimigos causam −30%"). A regra do status é do GDD de Efeitos de status. A **guarda** do Guardião
(dano recebido × 0,5) é regra do Combate núcleo (F3).

**R6. Fontes e remoção.**

- Remover uma **fonte** remove **todos** os modificadores e gatilhos dela.
- Modificadores com duração expiram sozinhos. A duração conta em **passos
  inteiros**: o dono chama `avancar(passos)` a cada passo vivo, nunca na pausa
  nem no hitstop, e o modificador expira quando os passos decorridos ≥ duração.
  Inteiros evitam o erro de somar 1/60 muitas vezes.
- Reaplicar uma fonte que tem duração faz `duração = max(restante, nova)`.
- O fim da run limpa tudo, exceto o que a Oficina reaplica no começo da run
  seguinte.

**R7. Recálculo.** Depois de qualquer adição, remoção ou expiração, a próxima
consulta já reflete a mudança, sem esperar quadro. Como isso é feito (cache,
recálculo sob demanda) é do ADR. Os condicionais são avaliados no uso, com o
contexto passado por quem consulta.

**R8. Raridade.** Este sistema recebe o `valor` já escalado (escala da
`RarityTable`, dona Bênçãos). Os `params` nunca escalam.

**R9. Atributo × recurso** (cânone):

- **`vida_max` sobe:** a Vida atual sobe a mesma diferença.
- **`vida_max` desce:** Vida atual = mín(atual, nova máxima).
- **`cargas_esquiva` sobe:** ganha a carga na hora. **Desce:** as cargas atuais
  são cortadas ao novo máximo.
- **`escudo_sala`:** no começo de cada câmara, o escudo atual **passa a valer**
  `escudo_sala` (substitui, não soma). Quando o atributo sobe no meio da câmara,
  o escudo atual ganha a diferença na hora (cânone).
- **`recusas_morte` e `trocas_oferta` sobem:** ganham a diferença na hora.
  **Descem:** as restantes são cortadas ao novo máximo.
- **`escudo_sala` desce:** o escudo atual não muda até a próxima câmara.
- **Começo da run:** Vida atual = `vida_max`.

**R10. Elite e profundidade como fontes.** As `EliteRules` viram modificadores de
fonte `elite`, aplicados no spawn:

- `vida_max` × 2,4;
- `dano_todo` × 1,25;
- `raio` × 1,2;
- `fator_empurrao` × 0,4.

A "armadura" da elite (não cambaleia, a preparação não é quebrada) e a regra de
não pagar Fragmentos **não** são modificadores: são regras de IA e de Combate. Chefes (comportamento `chefe` do `EnemyDef`, Conteúdo) recebem no spawn
uma fonte `chefe` com `fator_empurrao` × `fator_empurrao_chefe` (0,12, do
`ModifiersTuning`; cânone, `engine.ts:583`). O ganho de Vida por profundidade
(cânone: +5% por profundidade) vira modificador percentual de fonte
`profundidade`, que **não** vale para chefes (cânone). A fórmula é da **IA de
inimigos e elites** (F2; dona do `depth_hp_bonus` e das constantes de elite,
decisão do usuário, 2026-11-12).

**R11. Consulta.** Cada portador oferece:

- `valor(atributo)`;
- `multiplicador_de_dano(slot, contexto)`;
- `gatilhos(tipo)`: a lista por fonte de (valor, params, fonte) e o **total**
  somado dos valores.

Os sistemas recebem o portador por injeção. Os testes montam portadores em
memória.

**R12. Consumidores de dano** (cânone, `engine.ts`). Quem causa dano, que grupo
de percentual usa, quando M (F2) é avaliado e quais condicionais valem:

| Consumidor | Grupo (P_slot) | Quando M é avaliado | `vida_abaixo` | `apos_esquiva` | `enesimo_acerto` |
|---|---|---|---|---|---|
| Ataque corpo a corpo (`arco`) | Ataque | M congelado **no disparo** (cânone, `performAttack`); o 4º acerto é avaliado **no impacto**, por alvo | sim (no disparo) | sim (no disparo) | sim, por alvo |
| Especial em área (`circulo`) | Especial | M congelado **no disparo** (cânone, `performAttack`); o 4º acerto é avaliado **no impacto**, por alvo | sim (no disparo) | sim (no disparo) | sim, por alvo |
| Investida (`avanco`, Ataque ou Especial) | do slot que disparou | M congelado **no disparo** (cânone, `p.lungeDamage`); o 4º acerto é avaliado **no impacto**, por alvo | sim (no disparo) | sim (no disparo) | sim, no impacto |
| Projétil da arma (`projetil`, Ataque ou Especial) | do slot que disparou | M congelado **no disparo**; o 4º acerto é avaliado **no impacto** | sim (no disparo) | sim (no disparo) | sim, no impacto |
| Selo | Selo | a cada passo do Selo | sim | não | não |
| Corte da esquiva | Ataque | por alvo, uma vez por esquiva | sim | não | não (não conta acerto) |
| Impacto na parede | Ataque | no impacto | sim | não | não |
| Explosão ao abater | — (sem M) | — | — | — | — |
| Refletir dano | — (sem M) | — | — | — | — |
| Inimigo / chefe | `dano_todo` (elite, Abalo) | golpe direto: no impacto; projétil: **no disparo** | — | — | — |

Regra única para **golpe de arma** (corpo a corpo, área, investida, projétil):
P_todo, P_slot, `vida_abaixo` e `apos_esquiva` entram em M **no disparo**; só
`enesimo_acerto` é avaliado por alvo, no impacto. No corpo a corpo e na área,
qualquer mudança de Vida entre alvos do mesmo golpe (por exemplo, uma arma com
cura por acerto; cânone, `engine.ts:693`) não muda o M dos alvos seguintes.
Nenhuma arma de fábrica do MVP cura por acerto. Se uma arma futura tiver cura
por acerto, ela nasce no GDD dono da arma, e a regra vale para ela sem mudança.

Os tokens de forma da tabela (`arco`, `circulo`, `avanco`, `projetil`) são os
do mapa de ids do Conteúdo (R2). O dado só guarda esses tokens.

**R13. Semântica dos gatilhos** (cânone; o executor é o da R5):

- **`refletir_dano`:** base = dano que o jogador **de fato perdeu depois do
  escudo**; devolvido = base × valor, sem M, só a um atacante corpo a corpo
  (projéteis não são refletidos), só se a base > 0, e antes do teste de morte do
  jogador.
- **`explosao_ao_abater`:** a cada morte de inimigo, dano = valor, **sem** M, em
  todos os inimigos a até `raio_px` + raio do alvo, inclusive chefes. Mortes
  causadas pela explosão disparam nova explosão e `cura_ao_abater`, em cadeia de
  no máximo **4 passes** por passo de jogo. As mortes que sobram depois do 4º
  passe continuam com Vida ≤ 0, não podem ser atingidas e são processadas no
  **passo seguinte**, quando disparam a sua explosão e a sua cura (cânone,
  `sweepDeaths`).
- **`cura_ao_abater`:** toda morte de inimigo, por qualquer causa, cura `valor`
  de Vida, limitado a `vida_max`. Exceção: se o jogador já morreu no mesmo passo, não cura
  (Combate núcleo R14).
- **`corte_da_esquiva`:** dano = valor × M(grupo Ataque), uma vez por inimigo
  por esquiva; aplica `sangramento` (param, fixo); **não** conta acerto, não gera
  Fluxo e não aciona `golpe_*`.
- **`golpe_sangramento` / `golpe_queimadura`:** só golpes de arma, por alvo; o
  valor pode ser fracionário (Rara: 1,5 acúmulo). O teto de acúmulos da
  Queimadura é do GDD de Efeitos de status.
- **`recusas_morte`:** quando a Vida chegaria a ≤ 0 e há recusa restante, a
  Vida **passa a ser** `max(1, round(vida_max × vida_ao_voltar))` (substitui, não
  soma), o jogador fica invulnerável por `invuln_s`, e gasta 1 recusa. É checada
  depois do reflexo.
- **`selo_abala`:** inimigos dentro do Selo recebem a fonte única de Abalo
  (R5) com `duracao_s`, renovada a cada passo dentro do Selo.

### States and Transitions

| Estado do modificador | Entra quando | Sai para |
|---|---|---|
| Ativo | A fonte é aplicada (bênção pega, melhoria no começo da run, status, spawn de elite) | Expirado (duração acabou), Removido (fonte removida), Limpo (fim da run) |
| Expirado / Removido / Limpo | — | Fim; o atributo é recalculado na hora |

O portador do jogador nasce no começo da run (base da arma + Oficina) e é limpo
no fim. O portador de inimigo nasce no spawn e some na morte.

### Interactions with Other Systems

| Sistema | Recebe daqui | Fornece para cá | Dono da interface |
|---|---|---|---|
| Conteúdo orientado a dados | lista de tipos de efeito e params exigidos (V4, V1/V2) | `EffectDef`, `ModifiersTuning`, bases | este GDD (lista), Conteúdo (formato) |
| Bênçãos (Tradições) | — | aplica/remove a fonte da bênção com valor escalado | este GDD |
| Oficina de Reforja | — | fonte por melhoria (níveis) no começo da run | este GDD |
| Efeitos de status | gatilhos de status (`golpe_*`, `selo_abala`) | modificadores temporários (Abalo: `dano_todo` × 0,7) | este GDD (modelo), Status (regras) |
| Combate núcleo | `valor`, `multiplicador_de_dano`, gatilhos | contexto (Vida, contador de acertos, janela pós-esquiva) | este GDD |
| Movimento e esquiva | `velocidade`, `cargas_esquiva`, gatilho `corte_da_esquiva` | marca a esquiva (abre `apos_esquiva`) | este GDD |
| Selo e Fluxo | `dano_selo`, gatilho `selo_abala` | — | este GDD |
| IA / Câmaras e ondas | — | fontes `elite` e `profundidade` | este GDD |
| Tela de bênção / HUD | lista de fontes por atributo ("de onde vem") | — | UI |

## Formulas

> Proposta do `systems-designer` (consultado: modo Lean, seção de risco alto).
> Exemplos recalculados em Python em 2026-11-05. Arredondamento, piso no fim e
> ausência de teto de dano: decisões do usuário, 2026-11-05.

### F1. Valor derivado de um atributo

The derived_value formula is defined as:

`valor(a) = clamp(max(0, base + Σ planos) × max(0, 1 + Σ percentuais) × Π multiplicadores, piso, teto)` ;
se `a` é inteiro por natureza, `valor = round(valor)` no fim

Os dois `max(0, …)` impedem que dois termos negativos se multipliquem num valor
positivo.

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| base | float | ≥ 0 | data file (`WeaponDef` / `EnemyDef` / `MovementTuning`) | base do atributo |
| Σ planos | float | qualquer sinal | calculated | soma dos modificadores `plano` ativos e incondicionais |
| Σ percentuais | float | qualquer sinal | calculated | soma dos `percentual` (0,12 = +12%) |
| Π multiplicadores | float | ≥ 0 | calculated | produto dos `multiplicador` (1 se não houver) |
| piso, teto | float | piso ≤ teto | data file (`ModifiersTuning`) | R2 |
| valor | float ou int | [piso, teto] | calculated | atributo derivado |

**Output Range:**

- A ordem é planos → percentuais → multiplicadores → piso/teto →
  arredondamento. O piso é aplicado **só no fim**, então a ordem em que as
  bênçãos foram pegas não muda o resultado.
- Atributos inteiros (`vida_max`, `escudo_sala`, `cargas_esquiva`,
  `recusas_morte`, `trocas_oferta`) arredondam ao inteiro mais próximo, com o
  meio longe do zero. Isso diverge do cânone em até 0,5.
- Um multiplicador negativo é rejeitado pela validação do Conteúdo.

**Example:**

- Guardião 130 + Muro de Pedras 25 + Vigor nível 2 (20) = 175, como no cânone.
  Com Preço com Nome: 165.
- Base fictícia 25 − 10 = 15 → piso 20.
- Muro de Pedras Raro: 130 + 37,5 = 167,5 → 168.
- Velocidade 10 × (1 + 0,12 + 0,12) = 12,4.

### F2. Multiplicador de dano de um golpe

The hit_damage_multiplier formula is defined as:

`M(slot) = max(0, 1 + P_todo + P_slot) × Π multiplicadores_de_dano_todo_aplicáveis`

`Π` inclui **todos** os multiplicadores de `dano_todo` do portador que valem para
o slot: os incondicionais (elite × 1,25, Abalo × 0,7) e os condicionais cuja
condição é verdadeira no momento da R12. Para inimigos não há slot: vale só
`P_todo` e os multiplicadores.

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| P_todo | float | ≥ −1 | calculated | Σ % de `dano_todo`, inclusive `dano_vida_baixa_pct` se Vida < limiar |
| P_slot | float | ≥ −1 | calculated | Σ % do grupo do consumidor (R12): `dano_ataque`, `dano_especial` ou `dano_selo` |
| multiplicadores | float | ≥ 0 | calculated | incondicionais (elite, Abalo) e condicionais verdadeiros (`dano_enesimo_acerto`, `dano_apos_esquiva`) |
| M | float | ≥ 0 | calculated | fator sobre o dano do golpe |

**Output Range:** ≥ 0, com teto `teto_multiplicador_dano` = **4,0** (provisório,
faixa 2–8; decisão do usuário, 2026-11-12): o M **efetivo** é
`min(M, teto_multiplicador_dano)`. O máximo teórico sem teto é ≈ 14,08 (tudo
Épico, 4º acerto e pós-esquiva) e vira **4,0** com o teto. DPS máximo de Armas
F1 ≈ 66,47 × 4 = **265,9**. Os exemplos abaixo (M 2,00, 3,20) ficam abaixo do
teto; o de 4,80 vira 4,0.
**Example:** Ataque com Traço Único +25%, Preço com Nome +20%, Ímpeto nível 3
+15% e Fundo do Poço +40% (Vida < 50%):

- M = 1 + 0,35 + 0,25 + 0,40 = **2,00**, como no cânone
  (`1 + allDmg + slot + lowHp`).
- No 4º acerto (Linha Contada +60%): 2,00 × 1,6 = 3,20.
- Mais a Penumbra Comum (+50%): 4,80.
- Errado, multiplicando os grupos: 2,36, cerca de 18% acima.

### F3. Dano recebido

The damage_taken formula is defined as:

`dano = max(1, round(bruto × (1 − min(teto_red, max(0, reducao))) × guarda))`,
com `bruto = dano_base × M_atacante` ; depois `vida_perdida = max(0, dano − escudo)`
e `escudo' = max(0, escudo − dano)`

O piso 1 vale **antes** do escudo: com escudo suficiente, a Vida perdida pode
ser 0. Para projéteis, `M_atacante` é o do **disparo** (R12).

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| bruto | float | ≥ 0 | calculated | dano do atacante já com elite e Abalo (F2) |
| reducao | float | ≥ 0 | calculated | valor de `reducao_dano` (F1) |
| teto_red | float | 0,6 | data file (`ModifiersTuning`) | teto do cânone |
| guarda | float | 1 ou 0,5 | data file (Combate) | guarda do Guardião; o dono é o Combate |
| dano | int | ≥ 1 | calculated | antes do escudo |
| escudo | int | ≥ 0 | calculated | recurso do Combate (R9) |
| vida_perdida | int | ≥ 0 | calculated | o que sai da Vida atual |

**Output Range:** `dano` é inteiro ≥ 1 (pode passar de `bruto` quando o bruto é
menor que 1 ou arredonda para cima: bruto 0,3 → 1; 12,5 → 13). `vida_perdida`
vai de 0 a `dano`. O dano recebido é arredondado, como no cânone; o dano causado
a inimigos fica fracionário.
**Example:**

- `dano_base` 20, atacante com Abalo (M 0,7), Voo do Escudo Comum (0,12):
  20 × 0,7 × 0,88 = 12,32 → 12. Com guarda: 6,16 → 6.
- `dano_base` 20, **sem** Abalo, redução 0,9 → teto 0,6: 20 × 0,4 = 8. Com
  Abalo: 5,6 → 6.
- `dano_base` 1 com redução 0,6 → 0,4 → piso 1.
- `dano_base` 10, atacante elite (M 1,25), sem redução → 12,5 → 13.
- Dano 12 com escudo 15 → Vida perdida 0, escudo 3.

### F4. Vida máxima muda → Vida atual

The max_hp_change formula is defined as:

`Δ = novo − antigo ; vida' = min(vida + max(Δ, 0), novo)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| antigo, novo | int | ≥ piso (20 no jogador, 1 em inimigos) | calculated (F1) | `vida_max` antes e depois |
| vida | float | (0, antigo] | calculated | Vida atual (recurso do Combate) |

**Output Range:** (0, novo]. Descer nunca mata.
**Example:** Muro de Pedras 130 → 155, Vida 80 → 105. Preço com Nome 155 → 145
com Vida 150 → 145. Com Vida 100 → continua 100.

### F5. Escala de raridade

The rarity_scaled_value formula is defined as:

`valor_final = valor × (escala_com_raridade ? escala[raridade] : 1)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| valor | float | qualquer | data file (`EffectDef`) | valor na raridade Comum |
| escala[r] | float | 1 / 1,5 / 2 | data file (`RarityTable`) | Comum, Rara, Épica |
| escala_com_raridade | bool | — | data file | falso em: Vida −10 do Preço com Nome, carga extra, recusa de morte, Abalo do Selo |

**Output Range:** entre valor e 2 × valor. Oficina e status usam escala 1. Os
`params` nunca escalam.
**Example:** Preço com Nome Rara → dano +0,30, Vida −10. Muro de Pedras Épico →
+50. Fio Invisível Épico → velocidade +0,24, carga +1.

**Paridade:** os valores escondidos no código do cânone (Penumbra 0,5; Corte
Fantasma 10; Matéria Residual 12; Fardo Repartido 3) entram no `valor` do dado,
como o GDD de Conteúdo já define. Gravar 1 no lugar de 0,5 dobraria o efeito.

### Divergências deliberadas do cânone

| Ponto | Cânone | Este GDD | Por quê |
|---|---|---|---|
| Atributos inteiros | `vida_max` fracionária (167,5) | arredonda no fim (168) | o número exibido é o usado |
| Piso de Vida máxima | `max(20, …)` a cada efeito | piso só no fim da F1 | resultado independe da ordem das bênçãos |
| Piso de `reducao_dano` | sem piso | piso 0 | um debuff futuro não vira dano extra |
| Abalo e projéteis | projétil ignora o Abalo | projétil disparado Abalado sai × 0,7 | combina com o texto da Forma Fixa (decisão do usuário) |
| Ordem das multiplicações na F3 | `round(dano × (1 − red) × 0,7)` com outra ordem | Abalo dentro de M, depois redução | empates em x,5 podem diferir em 1 ponto de dano |
| Duração | ticks | passos inteiros (equivalente) | — (sem diferença de resultado) |

## Edge Cases

> `systems-designer` não consultado nesta seção: modo Lean. Os pontos de atenção
> que ele levantou em Formulas estão incorporados.

**Fontes**

- **Se a mesma fonte for aplicada duas vezes** (por exemplo, por bug ou por
  reaplicação): a segunda **substitui** o valor da primeira, sem somar. Se a
  fonte tem duração, a duração segue a R6 (`max(restante, nova)`). As ofertas de
  bênção já excluem as que o jogador tem (GDD de Bênçãos).
- **Se uma melhoria da Oficina tiver vários níveis:** é **uma** fonte com
  valor = valor do nível × nível, não N fontes.
- **Se for pedido remover uma fonte que não existe:** nada acontece e nada é
  registrado. Remover é idempotente.
- **Se dois tipos de gatilho iguais vierem de fontes diferentes** (Os Que Ficam e
  a melhoria "Recusa dos Que Ficam", ambos `recusas_morte`): os **valores somam**
  e os **params** têm de ser iguais. Params divergentes no dado são **erro** de
  validação, o que mantém o resultado independente da ordem. É a **V11** do
  Conteúdo (AC-50 de lá).
- **Se o dado citar um tipo de efeito fora da lista R5:** é erro V4 do Conteúdo,
  e o jogo não inicia.
- **Se um modificador citar atributo fora da R2 ou condição desconhecida:** a
  validação do catálogo rejeita. Em execução (fonte criada por código), vai para
  o relator de erros e é ignorado.

**Valores extremos**

- **Se Σ percentuais ≤ −1, ou base + planos < 0:** o termo vira 0 pelo
  `max(0, …)` da F1, e o piso do atributo segura. Dois termos negativos nunca se
  multiplicam num positivo. No dano, `max(0, …)` dá 0 (F2).
- **Se `cargas_esquiva` cair abaixo de 1:** o piso é 1, e o jogador sempre tem
  uma esquiva (P3).
- **Se a redução de dano passar de 0,6:** o teto é 0,6. **Se ficar negativa** (um
  debuff futuro): o piso é 0 (F3).
- **Se o arredondamento empatar** (22,5): vai para longe do zero → 23.
- **Se dois multiplicadores condicionais valerem no mesmo golpe** (4º acerto e
  pós-esquiva): multiplicam (F2).

**Tempo**

- **Se um modificador com duração estiver ativo durante a pausa ou o hitstop:**
  a duração não desconta (R6).
- **Se a janela `apos_esquiva` abrir e o golpe seguinte errar:** a janela é
  consumida assim mesmo, porque o consumo é no **disparo** (R4, cânone).
- **Se um golpe com a janela aberta atingir vários alvos:** todos recebem o
  bônus (R4, cânone).
- **Se uma duração não for múltipla exata de 1/60 s:** a conversão para passos
  inteiros arredonda (F7 do Conteúdo) e a expiração é exata em passos.
- **Se a Vida estiver exatamente no limiar** (50,0% em `vida_abaixo`): não vale,
  porque a condição é "<", como no cânone.

**Portadores**

- **Se um inimigo morrer com modificadores ativos:** eles somem com o portador,
  sem evento.
- **Se elite e profundidade valerem juntas:** Vida = base × (1 + 0,05 ×
  profundidade) × 2,4, arredondada no fim. É igual ao cânone, que também
  arredonda só no fim.
- **Se a Vida máxima cair estando cheia** (Preço com Nome com Vida = máximo): a
  Vida acompanha o novo máximo (F4), e o jogador perde 10 de Vida atual, nunca
  morre.

## Dependencies

**Depende de (upstream)**

| Sistema | Tipo | O que vem de lá | Sem ele |
|---|---|---|---|
| Conteúdo orientado a dados | Forte | `EffectDef` (valor, params, escala), `ModifiersTuning`, bases (`WeaponDef`, `EnemyDef`, `MovementTuning`) | Não há o que aplicar |

**É dependência de (downstream)**

| Sistema | Tipo | O que recebe |
|---|---|---|
| Combate núcleo | Forte | `vida_max`, `reducao_dano`, `escudo_sala`, `recusas_morte`, F2, F3, gatilhos |
| Movimento e esquiva | Forte | `velocidade`, `cargas_esquiva`, `corte_da_esquiva`, condição `apos_esquiva` |
| Armas das Doutrinas | Forte | bases por arma (via Conteúdo) lidas como atributos |
| Selo e Fluxo | Forte | `dano_selo`, `selo_abala` |
| Efeitos de status | Forte | modelo de modificador temporário (Abalo), gatilhos `golpe_*` |
| Bênçãos (Tradições) | Forte | aplicar/remover fonte; F5 |
| Oficina de Reforja | Forte | fonte por melhoria, aplicada no começo da run |
| IA de inimigos e elites | Forte | portadores de inimigo; fontes `elite` e `profundidade` (R10) |
| Câmaras e ondas | Suave | fonte `profundidade` (R10); a fórmula do ganho é da IA |
| Chefes (fatia vertical) | Suave | fonte `chefe` (R10, `fator_empurrao_chefe`) |
| Tela de bênção / HUD | Suave | lista de fontes por atributo ("de onde vem") |

**Bidirecionalidade:** Movimento, Combate, Armas, Selo, Status, Bênçãos e
Oficina já citam "Modificadores e atributos" no índice. IA de inimigos e elites
passa a citá-lo (decisão do usuário, 2026-11-05). Câmaras e ondas e Chefes
passam a citá-lo no índice (2ª passada do cross-review, 2026-11-06). Nenhum desses GDDs existe;
cada um, ao ser escrito, deve listar "Modificadores e atributos" em
Dependencies.

## Visual/Audio Requirements

Não se aplica. O sistema não tem evento visível nem sonoro. O feedback de "efeito
ativo" (aura de elite, ícone de Abalo) é do Pipeline visual e do Feedback de
combate.

## Game Feel

Não se aplica diretamente. Requisito indireto: um efeito novo (bênção pega, Abalo
aplicado) vale **no golpe seguinte**, sem atraso (R7), para o jogador sentir a
escolha na hora.

## UI Requirements

- A tela de bênção e o HUD podem pedir a **lista de fontes por atributo** ("Dano
  do Ataque: +25% Traço Único, +15% Ímpeto"), para o jogador ver de onde vem cada
  número (P1, P2).
- Os números mostrados usam os mesmos valores das fórmulas: atributos inteiros
  arredondados (F1) e percentuais já escalados pela raridade (F5).
- O formato visual é dos GDDs de HUD e de Tela de bênção.

## Cross-References

| Documento | Seção | Uso neste GDD |
|---|---|---|
| `design/gdd/conteudo-orientado-a-dados.md` | R1 (`EffectDef`, `params`, `ModifiersTuning`), R2 (tokens de forma), F7, V4, V11, constantes escondidas | Formato dos efeitos e nomes dos tipos; durações em passos; params iguais entre fontes |
| `design/gdd/game-concept.md` | §3 (P1, P2), §7 | Bênçãos como filosofia; preço visível |
| `design/gdd/systems-index.md` | High-Risk Systems | Gargalo; ADR crítico |
| Khaeros `packages/action-core/src/types.ts` | `PlayerMods` | As 21 chaves mapeadas na R5 |
| Khaeros `packages/action-core/src/engine.ts` | `applyEffect`, `damageMultiplier`, `hurtPlayer`, elites | Paridade das F1–F4 e R9/R10 |
| Khaeros `packages/combat-rules/src/arenaContent.ts` | `BOON_EFFECTS`, `ARENA_UPGRADES` | Oráculos de paridade (AC-29) |

## Acceptance Criteria

> Proposta do `qa-lead` (consultado: modo Lean, seção de risco alto), ajustada às
> decisões do usuário de 2026-11-05 (paridade com o cânone).
>
> Evidência: **[L]** `tests/unit/modifiers/`; **[I]**
> `tests/integration/modifiers/`. Os portadores vêm de uma fábrica em memória;
> tolerância de 1e-6.

**Portador e F1**

- **AC-01 [L]** Portador sem modificadores, base `vida_max` 130 → `valor` 130,
  M(ataque) 1,0, `gatilhos` vazio.
- **AC-02 [L]** Adicionar e remover `velocidade_pct` não muda a Vida atual (80).
  Recursos só mudam pela R9.
- **AC-03 [L]** Oráculos F1: 175; 165; base 25 − 10 → 20; Muro de Pedras Raro
  167,5 → 168; velocidade 12,4; base 10 + 5 plano, +20%, ×1,5 → 27.
- **AC-04b [L] F2 — teto do M** (`teto_multiplicador_dano` = 4,0). M calculado 14,08 (tudo Épico, 4º acerto, pós-esquiva) → M efetivo 4,0; M 3,20 → 3,20 (abaixo do teto, intacto); M 4,0 exato → 4,0; com o teto em 8, o 14,08 vira 8. O dano da Lâmina combinada no teto = DPS de Armas F1 66,47 × 4 ≈ 265,9. O ST5 e o SV12 usam M = 4.
- **AC-04 [L]** Pisos e tetos:
  - `reducao_dano` 0,9 → 0,6 e −0,1 → 0;
  - `cargas_esquiva` 1 − 1 → 1;
  - `velocidade` com Σ% −1,2 → 0;
  - `EnemyDef` com Vida base 10 e `vida_max_plano` −50 → 1 (piso de inimigo);
  - base −5 (plano) com Σ% −1,5 → 0, depois piso (nunca positivo por dois
    negativos).
- **AC-05 [L]** 22,5 → 23 e 22,4 → 22. Os 5 atributos inteiros devolvem `int`;
  `velocidade` fica `float`.
- **AC-06 [L]** Muro de Pedras, Preço com Nome, Vigor nv2 e Ímpeto nv3 nas 24
  ordens → `vida_max` 165 e o mesmo M em todas.

**Condições e F2**

- **AC-07 [L]** `vida_abaixo` (máx 100, Fundo do Poço Comum): Vida 49,9 → M 1,4;
  Vida 50,0 → 1,0. Mudar a Vida de 60 para 40 sem mexer na lista → a consulta
  seguinte já dá 1,4.
- **AC-08 [L]** `enesimo_acerto` (Linha Contada Comum): contador 3 → 1,0;
  contador 4 e 8 → 1,6; contador 0 → 1,0. Um golpe de Ataque que atinge 3 alvos
  com o contador em 2 → os alvos recebem os contadores 3, 4 e 5, e só o 2º alvo
  leva × 1,6.
- **AC-09 [L]** `apos_esquiva` (Penumbra Comum): com `contexto.apos_esquiva`
  verdadeiro, Ataque → × 1,5; falso → × 1,0; Selo com o contexto verdadeiro →
  × 1,0 (`slots`). O consumo da janela no disparo é critério do GDD de Combate.
- **AC-10 [L]** Oráculos F2:
  - 2,00 → 3,20 → 4,80, ≠ 2,36;
  - Abalo no atacante → 0,7, e dois Abalos → 0,7, não 0,49;
  - P_todo −1,5 → 0.
- **AC-11 [L]** Corte Fantasma Comum (valor 10) com Traço Único Comum (+25%
  Ataque) → dano do corte 12,5.
- **AC-12 [L] R7** Depois de adicionar, remover ou expirar, a próxima consulta
  reflete a mudança sem avançar quadro.

**Fontes e tempo**

- **AC-13 [L]** Remover Preço com Nome retira os 2 modificadores e os gatilhos
  dela. A Vida segue a F4.
- **AC-14 [L]** Remover duas vezes uma fonte inexistente → nada muda, nenhum
  erro, nenhum log.
- **AC-15 [L]** Muro de Pedras aplicado 2× → 155, não 180. Vigor nível 3 = uma
  fonte de +30.
- **AC-16 [I]** 3 bênçãos e Vigor nv2, fim da run, nova run → `vida_max` do
  Guardião 150.
- **AC-17 [L] R6** Modificador de 2,0 s (= 120 passos):
  - `avancar(60)`, depois pausa e hitstop sem `avancar` → continua ativo;
  - `avancar(60)` → expira e recalcula na mesma chamada;
  - 120 chamadas de `avancar(1)` → expira exatamente na 120ª;
  - reaplicar 120 passos com 30 restantes → 120; reaplicar 30 passos com 100
    restantes → 100 (`max`).
- **AC-18 [L]** Um portador de inimigo descartado com modificadores ativos → um
  espião injetado nos avisos de mudança de atributo registra 0 chamadas.

**R9, F4 e F5**

- **AC-19 [L]** Oráculos F5: Preço com Nome Rara → +0,30 de dano e −10 de Vida;
  Muro de Pedras Épico → +50; Fio Invisível Épico → +0,24 de velocidade e +1
  carga. Os `params` são iguais nas 3 raridades.
- **AC-20 [L]** Oráculos F4: 80 → 105; 150 → 145; Vida 100 fica 100; `vida_max`
  25 com −10 → piso 20, e Vida 25 → 20. Começo da run → Vida = `vida_max`.
- **AC-21 [L]** Cargas: máximo 2 → 3 com 2 restantes → 3 restantes; máximo 3 → 2
  com 3 restantes → 2. Uma recusa a mais → +1 restante.
- **AC-22 [I] R9** `escudo_sala` 15:
  - nova câmara com escudo atual 4 → escudo 15 (substitui);
  - nova fonte de +10 no meio da câmara com escudo 7 → 17;
  - câmara seguinte → 25;
  - `trocas_oferta` +1 no meio da run → +1 troca restante na hora.

**Elite, profundidade e F3**

- **AC-23 [L] R10** Elite com base 30 → Vida 72, `dano_todo` × 1,25, `raio`
  × 1,2, `fator_empurrao` 0,4. Base 46 na profundidade 7 → 149 (cânone). Chefe
  com Vida base 700 na profundidade 7 → 700 (sem ganho) e `fator_empurrao` 0,12
  (fonte `chefe`; remover a fonte → 1).
- **AC-24 [L]** Oráculos F3:
  - `dano_base` 20, atacante Abalado, redução 0,12 → 12; com guarda → 6;
  - `dano_base` 20 sem Abalo, redução 0,9 → 8; com Abalo → 6;
  - `dano_base` 1 com redução 0,6 → 1; redução negativa → conta como 0;
  - `dano_base` 10, atacante elite → 13;
  - dano 12 com escudo 15 → Vida perdida 0, escudo 3.

**Gatilhos e lista**

- **AC-25 [L] R11** Para os 8 tipos de gatilho, `gatilhos(tipo)` dá a lista por
  fonte (valor, params, fonte) e o total somado. Tipos de atributo não aparecem
  ali; `recusas_morte` aparece nos dois.
- **AC-26 [L]** Os Que Ficam + Recusa dos Que Ficam → total 2. Params
  divergentes no dado → erro de validação V11 do Conteúdo (AC-50 de lá).
- **AC-27 [L]** A lista de tipos tem exatamente 21, em bijeção com a lista fixa
  das 21 chaves de `PlayerMods` copiada para
  `tests/fixtures/modifiers/player_mods_canon.txt`.
- **AC-28 [L]** Modificador com atributo fora da R2 ou condição desconhecida →
  rejeitado pela validação; em execução, vai para o relator e é ignorado.

**Consumidores, gatilhos e Abalo (R12, R13)**

- **AC-29 [L] R12**
  - Projétil disparado com Fundo do Poço ativo (Vida 40/100) e Vida curada a 60
    antes do impacto → o dano usa o M do disparo (1,4).
  - Projétil com o contador em 3 ao disparar e 4 no impacto → leva × 1,6 (4º
    acerto avaliado no impacto).
  - Selo e Corte da esquiva não incrementam o contador de acertos.
  - Investida da Lâmina disparada com a janela `apos_esquiva` aberta (Penumbra
    Comum) e Fundo do Poço ativo (Vida 40/100): os alvos atingidos nos passos
    seguintes recebem o M do disparo, 1,4 × 1,5 = 2,1, mesmo com a janela já
    consumida e a Vida curada a 60 antes do impacto.
  - Corte da Lâmina do Juramento (forma `arco`, arma de fábrica) com Fundo do
    Poço Comum e Vida 49/100 acertando 3 alvos; o teste usa um portador falso
    que muda a Vida para 55 depois do 1º alvo → os 3 recebem M 1,4, embora a
    Vida passe de 50 antes do 2º alvo.
- **AC-30 [L] R13**
  - Reflexo (Fardo Repartido Comum, valor 3): dano 12 com escudo 15 → nada
    refletido; dano 12 com escudo 5 → 7 perdidos → 21 devolvidos; dano de
    projétil → nada refletido.
  - Explosão (Matéria Residual Comum, valor 12) com Traço Único ativo → 12 de
    dano (sem M); uma cadeia de 5 mortes → 4 passes no mesmo passo de jogo, e a
    5ª morte é processada no passo seguinte (explode e cura ali).
  - Cura ao abater (valor 2) com Vida 99/100 → 100.
  - Recusa: `vida_max` 100, `vida_ao_voltar` 0,4 → Vida = 40 (não soma),
    invulnerável por 120 passos, uma recusa a menos.
- **AC-31 [L] Abalo**
  - Inimigo Abalado dispara projétil de `dano_base` 10 → 7; o Abalo expira antes
    do impacto → continua 7.
  - Abalo com 3 s restantes recebe o `selo_abala` de 0,5 s → continua 3 s.

**Paridade com o cânone**

- **AC-32 [I] (teste de tabela)**
  - **Casos:** 18 Tradições × 3 raridades = 54 linhas, mais as 6 melhorias em
    todos os seus níveis (17 níveis no total).
  - **Oráculo:** `tests/fixtures/modifiers/paridade_canon.gd`, gerado do cânone
    por um script em `tools/canon-parity/` (dono: tools-programmer), fora do
    runtime.
  - **Atributos:** `vida_max`, `velocidade`, `reducao_dano`, `cargas_esquiva`,
    `escudo_sala`, `recusas_morte` e `trocas_oferta` batem com `applyEffect`
    (inteiros com desvio ≤ 0,5).
  - **Dano:** M de Ataque, Especial e Selo, em 4 contextos (Vida cheia,
    Vida < 50%, 4º acerto, pós-esquiva), bate com `damageMultiplier` composto
    como em `performAttack`. F3 bate com `hurtPlayer` nos casos sem Abalo de
    projétil (divergência deliberada).
  - **Gatilhos:** valor = chave × constante escondida (×10, ×12, ×3, ×0,5);
    reflexo e recusa conferidos com `hurtPlayer`; elite e profundidade com o
    spawn do cânone.
  - **Falha:** a mensagem nomeia a Tradição ou melhoria, a raridade ou nível e
    o campo.

Cobertura: R1–R13 e F1–F5 têm pelo menos um critério cada (o consumo da janela
pós-esquiva fica no GDD de Combate).

## Open Questions

| # | Pergunta | Dono | Resolver até |
|---|---|---|---|
| 1 | Representação em código (lista por portador, cache, quando recalcular) | technical-director | ADR crítico, antes de `/create-architecture` |
| 2 | O teto do multiplicador de dano é necessário? Hoje o máximo é ≈ ×14 | systems-designer | `/balance-check` antes da fatia vertical |
| 3 | ~~A janela `apos_esquiva`: primeiro acerto ou tempo?~~ **Resolvida em 2026-11-06:** cânone (abre no início da esquiva, consumida no disparo, vale para todos os alvos; R4) | — | ✅ |
| 4 | A guarda do Guardião (× 0,5) deve virar modificador temporário em vez de regra do Combate? Hoje é regra do Combate (F3) | game-designer | GDD de Armas das Doutrinas (fatia vertical) |
| 5 | Script `tools/canon-parity/` que gera `tests/fixtures/modifiers/paridade_canon.gd` (AC-32) | tools-programmer | Antes da primeira story deste sistema |
| 6 | ~~Pedidos ao GDD de Conteúdo: incluir `ModifiersTuning` na R1 e a checagem nova de params divergentes entre fontes do mesmo tipo~~ **Resolvida em 2026-11-06:** o Conteúdo lista o `ModifiersTuning` (pisos, tetos, `fator_empurrao_chefe`) na tabela de `*Tuning` da R1, em Interactions e em Dependencies, e criou a **V11** (params iguais entre todos os `EffectDef` do mesmo tipo de efeito, de bênçãos ou de melhorias), coberta pela AC-50 do Conteúdo. A referência "R8", os nomes finais, o empurrão em px/s e o campo `reducao_dano_causado` do Abalo já tinham sido acertados lá | — | ✅ |
