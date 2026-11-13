# Run e regiões

> **Status**: Approved (2026-11-11; revisão única por subagente: 5 bloqueantes e 11 recomendadas, corrigidos sem re-review; sem entrada no review log)
> **Author**: usuário + Claude (design-system, modo Lean)
> **Last Updated**: 2026-11-11
> **Last Verified**: 2026-11-11
> **Implements Pillar**: P2 *A Beira cobra*; P4

> **Nota (2026-11-11, Bênçãos):** pendente: o resumo (R7) lê `tomadas()` da Bênçãos; eventos novos `oferta_aberta`, `oferta_trocada` e `bencao_tomada` para HUD e Telemetria.

> **Nota (2026-11-11, Economia de Fragmentos):** pendente: R4/F2 e o resumo (R7) usam `coletados` lido antes da vitória, `bonus = creditar(vitoria, n)` (o `efetivo`) e `total = coletados + bonus`; linha 155 (Economia) deixa de ser provisória; `fragmentos_vitoria` fica no `RunTuning` (dono único).

> **Nota (2026-11-11, Telemetria local):** pendente: sinais "câmara entrou" e passo vivo em Jogo; `run_iniciada` e `run_encerrada` com o resumo (R7) e o caminho; OQ 7 resolvida; OQ 9 mede-se por `ms_inicio` da 1ª câmara.

> **Nota (2026-11-11, revisão cruzada):** pendente: a Transição de entrada da 1ª câmara (R2 passo 5, sem porta) precisa de definição própria; o sinal de abandono em Bênção está desabilitado (R6).

## Summary

**Run e regiões** é o dono do ciclo de vida da run: começa (seed, arma, estado
inicial, primeira câmara), percorre a sequência da região e termina em **vitória**,
**morte** ou **abandono**, com um resumo para a tela final e a Telemetria. No MVP há
uma região, o Limiar da Beira sem chefe, e a vitória vem ao limpar a 6ª câmara.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Câmaras e ondas, Portas e recompensas, Conteúdo orientado a dados, RNG com seed`

## Overview

> `game-designer` e `level-designer` não consultados nesta seção: modo Lean.

**Run e regiões** guarda o que dura a run inteira: a seed, a arma, a região, o
índice da câmara atual e o motivo do fim. Ela não decide o que acontece **dentro**
da câmara (Câmaras e ondas), o que a câmara dá (Portas e recompensas) nem os
inimigos (IA); decide **qual câmara vem**, **quando a run acaba** e **o que fica
dela** (o resumo e os Fragmentos).

- **Começo:** o jogador escolhe a arma na tela de início (Lâmina ou Ressonância); a
  run nasce com seed nova e cai na 1ª câmara, que dá uma bênção.
- **Meio:** a sequência vem da `RegionDef` (Limiar: combate ×3, santuário, combate
  ×2, chefe). No MVP a Run joga as **6 primeiras**; o chefe é reservado.
- **Fim:** vitória ao limpar a 6ª câmara (+15 Fragmentos); morte; ou abandono pelo
  menu de pausa (conta como morte). Os Fragmentos coletados são **mantidos** em
  qualquer fim.
- **Depois:** tela final com o resumo e "Nova run" (sem Campus no MVP).

A **fantasia** é a da Beira que cobra, mas deixa algo: toda run, vença ou caia, rende
Fragmentos e uma história curta para contar. Sem este sistema as câmaras, as portas e
as bênçãos não teriam começo nem fim.

As regras seguem o cânone (`arenaContent.ts` `ARENA_REGIONS`, `engine.ts:195–233`,
`:388–392`, `:510–533`), com as decisões do usuário de 2026-11-11: vitória ao limpar
a última câmara de combate (sem chefe), Fragmentos mantidos na morte, abandono como
morte, vitória de 15 Fragmentos, arma escolhida na tela de início e "Nova run" na
tela final.

> **→ vira ADR:** onde mora o estado da run (um objeto injetado, não um singleton) e
> como o reset de "Nova run" garante que nada vaza da run anterior.

## Detailed Design

### Core Rules

> `game-designer` e `level-designer` não consultados nesta seção: modo Lean.

**R1. Estados da run:** `Sem run → Escolha de arma → Ativa → Encerrada(vitória |
morte | abandono)`. De Encerrada só se sai por `nova_run` (R8), que **descarta a
seed e os fluxos do RNG** e volta a Escolha de arma.

**R2. Início** (em ordem):
1. a tela de início pede a arma (Lâmina ou Ressonância); a última escolhida vem
   marcada;
2. cria a seed (sorteada, ou `--seed=` em debug; RNG R2);
3. fixa o estado inicial: arma e Doutrina, Vida cheia e os modificadores já
   aplicados (como no cânone: antes da 1ª câmara);
4. pede às Câmaras a câmara de índice 0, com a recompensa `primeira_recompensa` das
   Portas (bênção);
5. a Transição de entrada abre a câmara.

**R3. Sequência.** A `RegionDef` da região ativa dá a sequência de tipos de câmara
(Limiar: 7, com o chefe por último). `RunTuning.camaras_jogaveis` (por região;
Limiar = **6**) limita quantas o MVP joga. A Run guarda a **região** e o **índice**
`i` da câmara e responde às Câmaras e às Portas: o tipo da câmara `i + 1` se
`i + 1 < camaras_jogaveis`, senão `fim_da_run`. Índices 0 a 5: combate ×3, santuário
(3), combate ×2. O chefe (6) é reservado: a Run nunca o entra e pedir para montá-lo
é o erro RN3.

**R4. Vitória.** Vale quando chega `camara_limpa(p, tipo)` com `i = camaras_jogaveis
− 1`. (O santuário, índice 3, emite o mesmo evento e **não** encerra a run.) Em
ordem:
1. **a última câmara não dá recompensa** (decisão do usuário, 2026-11-12): as Portas
   não concedem nada (nem bênção, nem Fragmentos, nem cura) e não pedem oferta
   (Portas R2 passo 1b);
2. a Run responde `fim_da_run` e as Portas **não abrem portas** (Portas R2 passo 1b);
3. a Run lê `coletados_run()`, credita a vitória (`creditar(vitoria, fragmentos_vitoria)`, 15), **monta o resumo** (R7: coletados, bônus, total) e só então emite `run_encerrada(vitória)` e abre a
   tela final **sem Transição** (a tela final entra por si).

**Divergência do cânone, declarada:** em `engine.ts:513–525` a vitória vem no chefe
e sem recompensa de sala; aqui, sem chefe, a última câmara **também não dá
recompensa**: limpar o índice 5 só dá a vitória (+15). A porta depois do índice 4 é
a forçada `ultima` (Portas R6). Os 6 do chefe (`bossFragments`) ficam reservados.

**R5. Morte.** `jogador_morreu` (Combate R13) congela o jogo e encerra a run com
motivo `morte`. Os Fragmentos coletados são **mantidos** (R8). A recusa de morte é
do Combate e não encerra nada. Se `jogador_morreu` e `camara_limpa` chegarem no mesmo
passo, **vale a morte**: o Combate processa a morte nos seus itens (R1 do Combate),
antes do item 10 das Câmaras, e a Run ignora a `camara_limpa` desse passo. A tela
final abre quando o estado Morte do Combate termina; a Run não soma atraso.

**R6. Abandono.** O menu de pausa tem "Abandonar run", com confirmação. A pausa **abre em Jogo e em Bênção** (Input R10 é a fonte, decisão da revisão cruzada de 2026-11-11); **em Bênção, "Abandonar run" fica desabilitado** (a oferta não se abandona no meio). Encerra a
run com motivo `abandono`: mantém os Fragmentos e não dá a vitória.

**R7. Resumo da run** (tela final e Telemetria), 10 campos: motivo, seed (texto,
RNG R8), arma, câmaras limpas (o **santuário conta**: uma vitória dá 6), bênçãos
tomadas, Fragmentos coletados, bônus de vitória, total (F2), abates e duração (F3).
É montado ao encerrar e não muda depois.

**R8. Nova run.** A tela final oferece "Nova run": volta a Escolha de arma e reinicia
pela R2 com seed nova (sem Campus no MVP). **Reset total** de tudo que é da run:
Câmaras, Selos, VFX, status, bênçãos, abates, duração e o fluxo de cada RNG; o **Fluxo volta ao valor inicial do Selo** (`fluxo_max`, Selo R1).
**Fica fora do reset o saldo de Fragmentos**, que é da Economia de Fragmentos (conta
que atravessa as runs; a persistência entre sessões é a OQ 5): é isso que "mantém os
Fragmentos" significa em R5 e R6.

**R9. `p_max`.** A Run **lê** o `p_max(região)` das Câmaras (dono único: Câmaras R3;
câmaras de combate da região − 1; 4 no Limiar). O `ArmasTuning.p_max` continua como
alias.

**R10. Várias regiões (reservado).** A interface já aceita uma lista de regiões (o
Veio Instável depois do Limiar), com `camaras_jogaveis` **por região**: ao esgotar
uma região que não é a última, a próxima começa na câmara 0 e o índice da região
entra no orçamento de onda (Câmaras F1). No MVP há **uma região**; o resto fica
reservado (Alpha).

**R11. Injeção.** Recebe `RegionDef`, `RunTuning` (arma padrão, `camaras_jogaveis`,
`fragmentos_vitoria`), o RNG (com um provedor de entropia injetável) e os eventos de
Câmaras, Portas e Combate. Os testes montam tudo em memória.

### States and Transitions

| Estado | Entra quando | Sai para |
|---|---|---|
| Sem run | o jogo abre | Escolha de arma |
| Escolha de arma | o jogador abre "Jogar", ou `nova_run` na tela final (que descarta a seed e os fluxos) | Ativa (R2) |
| Ativa | a seed e a 1ª câmara estão prontas | Encerrada (R4, R5 ou R6) |
| Encerrada | vitória, morte ou abandono | Escolha de arma (por `nova_run`) |

**Dentro de Ativa**, a Run só guarda o índice da câmara; combate, limpa e portas são
das Câmaras e das Portas. **O jogo para** em Morte e na tela final. O resumo (R7) é
montado uma vez, ao encerrar.

### Interactions with Other Systems

| Sistema | Recebe da Run | Fornece à Run | Dono da interface |
|---|---|---|---|
| Câmaras e ondas | a próxima câmara e o tipo, a câmara de índice 0 (R2) | `camara_limpa(p, tipo)`, `p_max` (dono: Câmaras R3) | Câmaras (portas); Run (sequência) |
| Portas e recompensas | a próxima câmara e `fim_da_run` (sem portas e sem recompensa na última) | a recompensa concedida (nenhuma na última câmara) | Portas |
| RNG com seed | criação e fim da seed; região e índice da câmara | os fluxos | RNG |
| Combate núcleo | — | `jogador_morreu` | Combate |
| Conteúdo orientado a dados | — | `RegionDef`, `RunTuning` | Conteúdo |
| Bênçãos (Tradições) | a lista de bênçãos tomadas (resumo) | as bênçãos tomadas | Bênçãos; **provisório** |
| Economia de Fragmentos | `fragmentos_vitoria` e o resumo ao encerrar | a conta da run | Economia; **provisório** |
| Armas das Doutrinas | a arma escolhida | `p_max` (alias do das Câmaras) | Run |
| Input e controle | o estado Encerrada (contexto de menu) | "abandonar" | Input |
| HUD | o estado de jogo do orquestrador (Combate R1), mais Escolha de arma e Encerrada | — | apresentação |
| Tela final, Áudio, Telemetria | resumo, motivo, seed | — | apresentação |

## Formulas

**F1. Câmaras jogáveis e `p_max`.** Câmaras jogáveis = índice da última câmara
jogável + 1 (Limiar: 6). A Run lê o `p_max` das Câmaras (R3: câmaras de combate da
região − 1; Limiar: **4**).

**F2. Fragmentos de um fim.** total = coletados + (`fragmentos_vitoria` se vitória,
senão 0). No Limiar o máximo coletado é 7 (portas de 2, 2 e 3 nos índices 1, 2 e 4;
a última câmara não dá recompensa). Exemplos: coletou 7 e venceu → 22; coletou 7 e
morreu → 7; coletou 4 e abandonou → 4.

**F3. Duração.** Passos em estado Jogo, **incluindo os de hitstop** (o relógio do
mundo avança); sem pausa, Bênção, menus nem Transição. Segundos = passos ÷ 60, só
para exibir.

## Tuning Knobs

| Knob | Padrão | Faixa | Categoria | Efeito e racional |
|---|---|---|---|---|
| `camaras_jogaveis` (por região) | 6 | 1 – tamanho da região | gate | quantas câmaras o MVP joga; 6 tira o chefe (índice 6) |
| `fragmentos_vitoria` | 15 | 0–35 | curva | cânone `victoryFragments`; acima de 35 (10% da Oficina, 350 = 66 + 76 + 38 + 30 + 45 + 95 em `ARENA_UPGRADES`) a vitória sozinha vira inflação |
| `arma_padrao` | `lamina` | `lamina` ou `ressonancia` | gate | arma sugerida na primeira run; token inválido: erro RN1 |

## Edge Cases

**Início**
- **Escolha de arma fechada sem escolher:** vale a última escolhida, ou `arma_padrao`.
- **`--seed` inválida:** o RNG a recusa (RNG R8) e a run usa uma seed sorteada.
- **`nova_run` fora de Encerrada:** é ignorado.

**Meio e fim**
- **Santuário limpo (índice 3):** emite `camara_limpa`, mas não é a última câmara
  jogável: a run segue e as Portas abrem 2 ou 3 portas (R4).
- **Morte e limpar a câmara no mesmo passo:** vale a morte (R5); sem vitória, mesmo na
  última câmara. Qualquer fim recebido depois de Encerrada é ignorado.
- **Última câmara:** não dá recompensa (nem bênção, Fragmentos ou cura): limpar o
  índice 5 encerra com vitória e +15 na hora, sem Tela de bênção e sem portas (R4).
  Fechar o jogo no meio perde a run (sem save no MVP).
- **Abandono:** o menu de pausa não abre em Transição, Morte nem em Encerrada, nem durante o hitstop (o passo congelado não lê o Input; Input R1); **abre em Bênção, com "Abandonar run" desabilitado**; então só se abandona em Jogo. Com 0 Fragmentos o resumo sai com 0.
- **Recusa de morte gasta:** a run continua (Combate).
- **Economia indisponível:** quem monta a run sem Economia (dublê) usa o saldo
  injetado; sem dublê, o saldo é 0.

**Dados**
- **Última câmara jogável que não é de combate:** erro RN2 (o santuário nunca fecha
  a run).
- **`camaras_jogaveis` zero, maior que a região, ou região sem câmara de combate
  jogável; pedido de montar o índice 6:** erro RN3.
- **Arma padrão inválida:** erro RN1.
- **Nova run:** o resumo anterior fica guardado só até a nova run começar.

## Dependencies

| Sistema | Força | Interface | Se faltar |
|---|---|---|---|
| Câmaras e ondas | Forte | sequência e `p_max` daqui; `camara_limpa` de lá | sem câmaras |
| Portas e recompensas | Forte | caso `fim_da_run` em Portas R2/R6 (**edição pendente**) | sem recompensa nem portas |
| Conteúdo orientado a dados | Forte | `RegionDef`; `RunTuning` e RN1–RN3 (Conteúdo R1 e R9) | sem região |
| RNG com seed | Forte | criação e fim da seed; fluxos; `nova_run` descarta (o gatilho "voltar ao Campus" vale também para Nova run; aplicado no RNG, States and Transitions) | sem aleatoriedade |
| Combate núcleo | Suave | `jogador_morreu` | a run só acaba por vitória ou abandono |
| Armas das Doutrinas | Suave | `p_max` passa a vir da Run (**edição pendente**) | `p_max` do Armas |
| Pipeline visual | Suave | R3 deixa de dizer que a Run informa p (**edição pendente**) | — |
| Bênçãos, Economia de Fragmentos, HUD, Tela de bênção, Telemetria | por contrato | `bencao_escolhida`, saldo, resumo | dublês |

## Visual/Audio Requirements

A Run não desenha nada. Pede à apresentação: a Transição de entrada (wipe), a tela
de início (escolha de arma) e a tela final (resumo, "Nova run"). Vitória, morte e
abandono vão **direto** à tela final, sem Transição. Sons de início, vitória e
derrota: Áudio (fatia vertical).

## Game Feel

Começar uma run leva um clique e uma Transição; o fim mostra o resumo assim que o
estado Morte do Combate termina (ou na hora, na vitória e no abandono), sem carga nem
menu no meio. Alvo a medir em playtest: do clique em "Jogar" ou "Nova run" à 1ª
câmara jogável, **≤ 3 s**.

## UI Requirements

Tela de início (arma), confirmação de "Abandonar run" e tela final (resumo e "Nova
run"): a spec de UX ainda não existe (Open Question 4).

## Cross-References

Seguem as dependências. Os valores de `RunTuning` entram no registro de entidades
quando o GDD for aprovado.

## Acceptance Criteria

> Fixture RN (provisório): `RegionDef limiar` de fábrica, `RunTuning` de fábrica
> (`camaras_jogaveis` 6, `fragmentos_vitoria` 15, `arma_padrao` Lâmina), RNG com
> seed fixa e provedor de entropia injetado, dublês de Câmaras, Portas, Combate,
> Bênçãos e Economia (saldo injetável), sem SceneTree.

- **AC-RN-01 [L] R1 — estados.** Sem run → Escolha de arma → Ativa → Encerrada, na ordem; `nova_run` leva Encerrada a Escolha de arma e descarta a seed e os fluxos; qualquer outra transição é recusada.
- **AC-RN-02 [L] R2 — ordem.** A ordem registrada pelos dublês é: arma, seed, estado inicial, pedido da câmara 0 com `primeira_recompensa`, Transição.
- **AC-RN-03 [L] R2 — arma.** Sem escolha, vale a última; na primeira run, `arma_padrao`.
- **AC-RN-04 [L] R2 — seed.** Com um provedor de entropia que devolve 0x3F9A07C2, a seed da run é 0x3F9A07C2; com `--seed=1B2C3D4E` em debug, 0x1B2C3D4E; com `--seed=XYZ`, a do provedor.
- **AC-RN-05 [L] R2 — estado inicial.** A Vida começa igual à Vida máxima: 100 com a Lâmina e 80 com a Ressonância.
- **AC-RN-06 [L] R3 — próxima câmara.** No índice 2 a próxima é `santuario`; no índice 3, `combate`.
- **AC-RN-07 [L] R3 — fim e chefe.** No índice 5 a próxima é `fim_da_run`; pedir para montar o índice 6 devolve o erro RN3.
- **AC-RN-08 [I] R4 — santuário.** `camara_limpa(p, santuario)` no índice 3 não encerra a run (estado Ativa) e as Portas abrem 2 ou 3 portas.
- **AC-RN-09 [I] R4 — vitória sem portas e sem recompensa.** Com saldo injetado 11, limpar o índice 5: 0 portas abertas, nenhum evento `recompensa`, `run_encerrada(vitória)` emitido exatamente 1 vez e saldo = 11 + 15 = 26.
- **AC-RN-10 [I] R4 — ordem dos eventos na última.** A ordem é `camara_limpa`, `fim_da_run`, crédito da vitória, `run_encerrada`; nenhum `pedir_oferta`, `recompensa` nem `bencao_escolhida`; o mundo não para.
- **AC-RN-11 [L] R4/R5/R6 — sem Transição no fim.** Após vitória, morte ou abandono, nenhuma Transição é pedida; a tela final é aberta 1 vez.
- **AC-RN-12 [L] R5 — morte.** `jogador_morreu` encerra com motivo `morte` e o saldo de Fragmentos coletados não muda.
- **AC-RN-13 [L] R5 — recusa.** Com `recusou_morte`, a run segue Ativa.
- **AC-RN-14 [L] R6 — abandono.** Confirmar encerra com `abandono` e mantém o saldo; cancelar não muda nada.
- **AC-RN-15 [L] R6 — pausa.** O pedido de pausa é recusado em Transição, Morte e Encerrada; abre em Jogo e em Bênção; em Bênção "Abandonar run" está desabilitado e confirmar abandono não encerra a run.
- **AC-RN-16 [L] R5 — prioridade.** Morte e `camara_limpa` no mesmo passo: a run encerra com `morte` e a `camara_limpa` é ignorada.
- **AC-RN-17 [L] R1 — fim repetido.** Um fim recebido com a run Encerrada é ignorado e o resumo não muda.
- **AC-RN-18 [L] R7 — resumo.** Tem os 10 campos; uma vitória dá câmaras limpas = 6; uma morte depois de limpar os índices 0 a 3 dá 4; o resumo não muda depois de montado.
- **AC-RN-19 [I] R8 — reset.** Com saldo 11 e Fluxo, bênçãos e abates diferentes de zero, após `nova_run`: saldo 11; 0 inimigos, 0 Selos, 0 status, 0 bênçãos, Fluxo = `fluxo_max` (100), abates 0, duração 0.
- **AC-RN-20 [L] R8 — seed nova.** A segunda run recebe outra seed do provedor e cada fluxo recomeça do estado derivado dela.
- **AC-RN-21 [L] F1/R9 — `p_max`.** O Limiar dá `p_max` 4; com uma `RegionDef` dublê de 3 câmaras de combate jogáveis, 2.
- **AC-RN-22 [L] R10 — regiões (reservado).** Com uma região, a próxima região é `fim_da_run`; com duas (dublê, `camaras_jogaveis` 2 e 3), a 2ª começa na câmara 0 e o índice da região entra no orçamento de onda.
- **AC-RN-23 [L] F2/F3 — exemplos.** Os três exemplos da F2 (22, 7, 4); 3 600 passos, contando os de hitstop, dão 60 s.
- **AC-RN-24 [L] Validação.** Arma inválida: RN1; última câmara jogável que não é de combate: RN2; `camaras_jogaveis` 0 ou 8, ou região sem combate jogável: RN3.
- **AC-RN-25 [I] R4 — última câmara sem recompensa.** Limpar o índice 5 com a Vida em 50/100: a Vida continua 50 (sem cura), o saldo só ganha os 15 da vitória, e a run encerra com vitória no mesmo passo.
- **AC-RN-26 [I] R11 — injeção.** O sistema roda com os dublês, sem SceneTree.

## Open Questions

| # | Pergunta | Dono | Prazo |
|---|---|---|---|
| 1 | Edições pendentes: Portas R2/R6 (caso `fim_da_run`), Armas (`p_max` vem da Run) e Pipeline R3 | donos de cada GDD | próxima edição de cada um |
| 2 | Salvar a run no meio: sem save no MVP | Persistência / usuário | fatia vertical |
| 3 | Fragmentos do chefe (6) e a segunda região (Veio Instável) | Chefes / Run | fatia vertical e Alpha |
| 4 | Spec de UX da tela de início (arma), da confirmação de abandono e da tela final | ux-designer / HUD | GDD de HUD |
| 5 | Persistência do saldo de Fragmentos entre sessões | Economia de Fragmentos | GDD de Economia |
| 6 | Campus e Rito (escolha de arma pelo juramento) no lugar da tela de início | game-designer | fatia vertical |
| 7 | Campos de telemetria de início e de fim de run | Telemetria local | GDD de Telemetria |
| 8 | RNG: o gatilho Encerrada → Sem run ("voltar ao Campus") deve valer também para `nova_run`; Conteúdo: tipo `RunTuning` e os erros RN1–RN3 como códigos V* | donos do RNG e do Conteúdo | próxima edição de cada um |
| 9 | Tempo do clique em "Jogar" à 1ª câmara (≤ 3 s) só se verifica em jogo | Telemetria / playtest | primeiro playtest |
