# Run e regiões

> **Status**: Approved
> **Author**: usuário + Claude (design-system, modo Lean; emenda Pactos aprovada pelo usuário em 2026-11-16)
> **Last Updated**: 2026-11-18 (consolidação de decisões aprovadas em 2026-11-16); 2026-11-15 (emenda Pactos)
> **Last Verified**: 2026-11-11
> **Implements Pillar**: P2 *A Beira cobra*; P4

> **Nota (2026-11-11, Bênçãos):** pendente: o resumo (R7) lê `tomadas()` da Bênçãos; eventos novos `oferta_aberta`, `oferta_trocada` e `bencao_tomada` para HUD e Telemetria.

> **Nota (2026-11-11, Economia de Fragmentos):** pendente: R4/F2 e o resumo (R7) usam `coletados` lido antes da vitória, `bonus = creditar(vitoria, n)` (o `efetivo`) e `total = coletados + bonus`; linha 155 (Economia) deixa de ser provisória; `fragmentos_vitoria` fica no `RunTuning` (dono único).

> **Nota (2026-11-11, Telemetria local):** pendente: sinais "câmara entrou" e passo vivo em Jogo; `run_iniciada` e `run_encerrada` com o resumo (R7) e o caminho; OQ 7 resolvida; OQ 9 mede-se por `ms_inicio` da 1ª câmara.

> **Nota (2026-11-11, revisão cruzada):** pendente: a Transição de entrada da 1ª câmara (R2 passo 5, sem porta) precisa de definição própria; o sinal de abandono em Bênção está desabilitado (R6).

> **Emenda Pactos (2026-11-15).** O MVP passa a jogar o Limiar **com a Maldição-chefe
> *Soberano do Limiar*** na 7ª câmara (índice 6; `chefes.md` R2, R9, F6). Pactos entra
> como 3ª Doutrina do MVP, com a escolha da dupla de Maldições antes da expedição
> (`maldicoes.md` R2). O texto antigo fica. Cada trecho novo leva a marca
> "(emenda Pactos, 2026-11-15)" e diz o que substitui. Mudam: Summary, Overview, R1–R5,
> R7, R8, R11, estados, interações, F1, F2, knobs, Edge Cases, Dependencies, ACs e OQs.
> Decisões próprias desta emenda foram aprovadas pelo usuário em 2026-11-16.

## Summary

**Run e regiões** é o dono do ciclo de vida da run: começa (seed, arma, estado
inicial, primeira câmara), percorre a sequência da região e termina em **vitória**,
**morte** ou **abandono**, com um resumo para a tela final e a Telemetria. No MVP há
uma região, o Limiar da Beira sem chefe, e a vitória vem ao limpar a 6ª câmara.

**(emenda Pactos, 2026-11-15)** Substitui a última frase acima: no MVP o Limiar tem
**7 câmaras jogáveis**, e a 7ª (índice 6) é a da **Maldição-chefe *Soberano do
Limiar*** (`chefes.md`). A vitória vem quando o chefe é **derrotado** (Lâmina,
Ressonância) ou **subjugado** e resolvido (Pactos: a escolha Pactuar ou Exorcizar
acontece **antes** da vitória). A Doutrina é escolhida entre 3 cartas (Lâmina,
Ressonância, Besta do Vínculo). Com Pactos, a dupla de Maldições é escolhida antes da
expedição. Ao fim da run nada da run passa adiante, exceto o saldo de Fragmentos e o
registro de pactos e vínculo (`maldicoes.md` R14).

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Câmaras e ondas, Portas e recompensas, Conteúdo orientado a dados, RNG com seed` · **(emenda Pactos, 2026-11-15)** + `Chefes, Vínculo e pactos (por contrato), Maldições (suave)`

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

**(emenda Pactos, 2026-11-15)** Os quatro tópicos acima passam a ser:

- **Começo:** a tela de escolha (Armas R4) mostra **3 cartas**: Lâmina, Ressonância e
  Besta do Vínculo (`WeaponDef pactos`, `maldicoes.md:462`). A carta é o juramento do
  MVP: fixa a Doutrina (`lamina`, `ressonancia`, `pactos`). Com Pactos, vem em seguida a
  **escolha da dupla** de Maldições (regras: Vínculo e pactos). Depois, seed nova e a
  1ª câmara, que dá uma bênção.
- **Meio:** a Run joga as **7** câmaras da `RegionDef limiar`: combate ×3, santuário,
  combate ×2 e **chefe** (índice 6, arena fixa, Chefes R2).
- **Fim:** vitória quando o chefe sai da luta: abatido (Lâmina, Ressonância: +6 do
  chefe) ou, em Pactos, subjugado e resolvido por **Pactuar** (0 do chefe) ou
  **Exorcizar** (+6). Em todos os casos a vitória dá +15. Morte e abandono seguem
  iguais.
- **Depois:** tela final e "Nova run". Reset total da run; ficam o saldo de Fragmentos
  e o registro de pactos e vínculo.

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

**R1-P (emenda Pactos, 2026-11-15).** Os estados passam a ser `Sem run → Escolha de
arma → Escolha da dupla (só Pactos) → Ativa → Encerrada(vitória | morte | abandono)`.
Com Lâmina ou Ressonância, Escolha da dupla não existe: Escolha de arma vai direto a
Ativa, como antes. Dentro de Ativa, a câmara do chefe pode ter a fase `Subjugado`
(Chefes R9), que **não** encerra a run.

**R2. Início** (em ordem):
1. a tela de início pede a arma (Lâmina ou Ressonância); a última escolhida vem
   marcada;
2. cria a seed (sorteada, ou `--seed=` em debug; RNG R2);
3. fixa o estado inicial: arma e Doutrina, Vida cheia e os modificadores já
   aplicados (como no cânone: antes da 1ª câmara);
4. pede às Câmaras a câmara de índice 0, com a recompensa `primeira_recompensa` das
   Portas (bênção);
5. a Transição de entrada abre a câmara.

**R2-P (emenda Pactos, 2026-11-15).** Substitui o passo 1 e acrescenta o passo 1b e
uma parte do passo 3:

1. a tela de escolha (dona: Armas R4) mostra **3 cartas**: Lâmina, Ressonância e
   Besta do Vínculo. A última confirmada vem marcada; na primeira vez, `arma_padrao`.
   **No MVP a carta é o juramento:** a arma fixa a Doutrina da run (`lamina`,
   `ressonancia` ou `pactos`), porque Rito e Campus são da fatia vertical (OQ 6). A
   Run guarda a Doutrina e a expõe por `doutrina()` (consulta pedida por Chefes R12).
   Contrato pedido a Armas: R4 passa de 2 para 3 cartas.

1b. **Escolha da dupla** (só se a Doutrina é `pactos`). Depois de confirmar a arma e
   **antes** da seed, a Run entra em Escolha da dupla e pede a dupla a Vínculo e
   pactos (`pedir_dupla()`). As regras da dupla (quais espécies, ordem, tela,
   lembrança da última) são de **Vínculo e pactos**; `maldicoes.md` R2 diz só que a
   1ª escolhida começa em campo e a 2ª na reserva. A Run espera
   `dupla_confirmada(campo, reserva)`; `reserva` e `campo` podem vir vazios. Contrato
   pedido a Vínculo e pactos. Quando a tela aparece:
   - ~~0 espécies pactuadas: sem tela; dupla vazia; o Iniciado luta só com a Besta
     (`maldicoes.md` R2);~~ (emenda Pactos, 2026-11-15) 0 espécies pactuadas: o
     Vínculo V3 concede o Vulto Mudo e segue como dupla de 1, sem tela
     (`dupla_confirmada(vulto_mudo, "")`); dupla vazia só existe com dublê;
   - 1 espécie pactuada: sem tela; ela vai a campo, sem reserva;
   - 2 ou mais: tela de Vínculo e pactos.
   Voltar (Esc) na tela da dupla devolve à escolha de arma, sem criar seed.

3. (acréscimo) com Pactos, a Run entrega a dupla às Maldições, que montam o estado
   inicial delas (`maldicoes.md` R2, R10, R11). A Run não guarda números das
   Maldições.

**R3. Sequência.** A `RegionDef` da região ativa dá a sequência de tipos de câmara
(Limiar: 7, com o chefe por último). `RunTuning.camaras_jogaveis` (por região;
Limiar = **6**) limita quantas o MVP joga. A Run guarda a **região** e o **índice**
`i` da câmara e responde às Câmaras e às Portas: o tipo da câmara `i + 1` se
`i + 1 < camaras_jogaveis`, senão `fim_da_run`. Índices 0 a 5: combate ×3, santuário
(3), combate ×2. O chefe (6) é reservado: a Run nunca o entra e pedir para montá-lo
é o erro RN3.

**R3-P (emenda Pactos, 2026-11-15).** Substitui `Limiar = 6` e a frase do chefe
reservado:
- `RunTuning.camaras_jogaveis` do Limiar passa a **7**. Índices 0 a 6: combate ×3,
  santuário (3), combate ×2, **chefe (6)**.
- No índice 5 a próxima é `chefe`; no índice 6, `fim_da_run`.
- As Câmaras montam a câmara 6 com a arena fixa do chefe (Câmaras R14, Chefes R2),
  com `p = 4` (Chefes R2).
- Montar o índice 6 deixa de ser erro. RN3 passa a valer para índice
  `≥ camaras_jogaveis`.
- **Índice 5 vira câmara de combate comum.** Ele deixa de ser a
  "última câmara jogável" das Portas (R2 passo 1b, R6):
  - a porta depois do índice 4 deixa de ser a forçada `ultima` e vira escolha livre;
  - limpar o índice 5 dá a recompensa dessa porta (Fragmentos com `p = 4`: `2 +
    floor(4/3) = 3`, Portas F1);
  - limpar o índice 5 abre 1 porta forçada `chefe` (Portas R6).
  Motivo: a regra do usuário de 2026-11-12 ("a última câmara não dá recompensa")
  continua literal, porque a última agora é o chefe. Uma cura ou bênção antes do
  chefe também tem uso real. Contrato pedido a Portas (R2 1b, R6, F2: 4 escolhas
  livres). ~~Conflito com Chefes F6, que conta "até 7 de portas": ver F2-P.~~
  (emenda Pactos, 2026-11-15) Conflito resolvido: Chefes F6 foi emendado e conta
  10/25/31, como F2-P.

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

**R4-P. Vitória com chefe (emenda Pactos, 2026-11-15).** Substitui a divergência
acima: a vitória volta a vir no chefe, como no cânone (`engine.ts:513–525`), e os 6 do
chefe deixam de ser reservados.

1. **Gatilho.** A vitória vale quando chega `camara_limpa(4, chefe)` com `i = 6`
   (`camaras_jogaveis − 1`). As Câmaras só emitem esse evento **depois** do desfecho
   do chefe (Chefes R9, F6):
   - **Lâmina ou Ressonância:** o chefe zera a Vida, há o hitstop de chefe (36
     passos), o chefe fica `Morto`, Chefes pede `creditar(chefe, 6)` e sai
     `camara_limpa`;
   - **Pactos:** depois do hitstop o chefe fica `Subjugado` e sai
     `chefe_subjugado("soberano_do_limiar")`. Vínculo e pactos abre a escolha.
     **Pactuar**: 0 Fragmentos do chefe e o pacto é registrado. **Exorcizar**:
     `creditar(chefe, 6)`. Só depois sai `camara_limpa`. **A escolha acontece antes
     da vitória.**
2. **Depois do gatilho**, valem os passos 1 a 3 da R4 aplicados ao índice 6: nenhuma
   recompensa de Portas, `fim_da_run`, nenhuma porta, a Run lê `coletados_run()` (que
   **já inclui** os 6 do chefe, se creditados), credita a vitória (15), monta o resumo,
   emite `run_encerrada(vitória)` e abre a tela final sem Transição.
3. **Desfecho do chefe no resumo.** A Run registra `desfecho_chefe`:
   - `abatido`: chegou `camara_limpa(4, chefe)` sem `chefe_subjugado` antes;
   - `pactuado` ou `exorcizado`: pelo evento `chefe_escolhido(id, escolha)` de
     Vínculo e pactos (contrato pedido a Vínculo e pactos).
   A Run **não** cria eventos `chefe_derrotado` nem `chefe_pactuado`: o desfecho vai no
   resumo e em `run_encerrada`. (`chefe_derrotado` em Chefes CH-A1 é gancho de áudio,
   não evento lógico.)
4. **Run em `Subjugado`.** A run continua **Ativa** até `camara_limpa(4, chefe)`. A
   pausa abre, mas **"Abandonar run" fica desabilitado** de `chefe_subjugado` até a
   vitória, como em Bênção (R6): a escolha não se abandona no meio.
5. **Índice 3 e índice 5** emitem `camara_limpa` e **não** encerram a run.

**R5. Morte.** `jogador_morreu` (Combate R13) congela o jogo e encerra a run com
motivo `morte`. Os Fragmentos coletados são **mantidos** (R8). A recusa de morte é
do Combate e não encerra nada. Se `jogador_morreu` e `camara_limpa` chegarem no mesmo
passo, **vale a morte**: o Combate processa a morte nos seus itens (R1 do Combate),
antes do item 10 das Câmaras, e a Run ignora a `camara_limpa` desse passo. A tela
final abre quando o estado Morte do Combate termina; a Run não soma atraso.

**R5-P (emenda Pactos, 2026-11-15).** A morte vale igual na câmara do chefe. Morte no
mesmo passo em que o chefe zera a Vida: vale a morte, sem `chefe_subjugado` nem
`camara_limpa` (Chefes, Edge Cases). Em `Subjugado` o jogador não sofre dano (Chefes
R9); se `jogador_morreu` chegar mesmo assim, vale a morte, sem pacto do chefe, sem
crédito do chefe e sem vitória. A morte da Maldição (Exausta) não encerra nada
(`maldicoes.md` R9, R15).

**R6. Abandono.** O menu de pausa tem "Abandonar run", com confirmação. A pausa **abre em Jogo e em Bênção** (Input R10 é a fonte, decisão da revisão cruzada de 2026-11-11); **em Bênção, "Abandonar run" fica desabilitado** (a oferta não se abandona no meio). Encerra a
run com motivo `abandono`: mantém os Fragmentos e não dá a vitória.

**R7. Resumo da run** (tela final e Telemetria), 10 campos: motivo, seed (texto,
RNG R8), arma, câmaras limpas (o **santuário conta**: uma vitória dá 6), bênçãos
tomadas, Fragmentos coletados, bônus de vitória, total (F2), abates e duração (F3).
É montado ao encerrar e não muda depois.

**R7-P (emenda Pactos, 2026-11-15).** O resumo passa a ter **12 campos**: os 10 acima
e mais:
- `desfecho_chefe`: `abatido`, `exorcizado`, `pactuado` ou `nenhum` (sem vitória);
- `dupla`: ids da Maldição de campo inicial e da reserva (vazio fora de Pactos ou com
  0 pactuadas).
Uma vitória dá câmaras limpas = **7** (santuário e chefe contam). Fragmentos
coletados incluem os do chefe (F2-P).

**R8. Nova run.** A tela final oferece "Nova run": volta a Escolha de arma e reinicia
pela R2 com seed nova (sem Campus no MVP). **Reset total** de tudo que é da run:
Câmaras, Selos, VFX, status, bênçãos, abates, duração e o fluxo de cada RNG; o **Fluxo volta ao valor inicial do Selo** (`fluxo_max`, Selo R1).
**Fica fora do reset o saldo de Fragmentos**, que é da Economia de Fragmentos (conta
que atravessa as runs; a persistência entre sessões é a OQ 5): é isso que "mantém os
Fragmentos" significa em R5 e R6.

**R8-P (emenda Pactos, 2026-11-15).** O reset total inclui também:
- tudo das Maldições na run (`maldicoes.md` R14): dupla, Vida, Pronta ou Exausta,
  recarga da Troca, marca do Virote, atrações e imobilizações;
- o chefe e os lacaios invocados, com a fase `Subjugado`.
Ficam **fora do reset**, como o saldo: o **registro de pactos e o vínculo** de cada
espécie (dono: Vínculo e pactos; `maldicoes.md` R14: "ao fim da run nada passa
adiante, exceto o vínculo"). Vale para vitória, morte e abandono. Um pacto feito na
run (encontro especial ou chefe) **fica** mesmo se a run acabar em morte ou abandono
(dono da regra: Vínculo e pactos). A Nova run volta a Escolha de
arma com a última arma marcada e, com Pactos, pede a dupla de novo (R2-P 1b).

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

**R11-P (emenda Pactos, 2026-11-15).** Recebe também: os eventos de Chefes
(`chefe_subjugado`) e de Vínculo e pactos (`dupla_confirmada`, `chefe_escolhido`), e a
chamada `pedir_dupla()` de Vínculo e pactos. Fornece `doutrina()` a Chefes (R12 de
Chefes). `RunTuning.camaras_jogaveis` do Limiar = 7; `arma_padrao` aceita `pactos`.
Os testes usam dublês de Chefes e de Vínculo e pactos.

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

**(emenda Pactos, 2026-11-15)** Tabela de estados com a dupla e o chefe:

| Estado | Entra quando | Sai para |
|---|---|---|
| Sem run | o jogo abre | Escolha de arma |
| Escolha de arma | "Jogar", `nova_run`, ou Esc na Escolha da dupla | Escolha da dupla (Doutrina `pactos` e ≥ 2 pactuadas); senão Ativa (R2) |
| Escolha da dupla | arma `pactos` confirmada e ≥ 2 espécies pactuadas (R2-P 1b) | Ativa (`dupla_confirmada`); Escolha de arma (Esc) |
| Ativa | a seed e a 1ª câmara estão prontas | Encerrada (R4-P, R5 ou R6) |
| Encerrada | vitória, morte ou abandono | Escolha de arma (por `nova_run`) |

Dentro de Ativa, na câmara 6: luta → (Pactos) `Subjugado` → escolha → `camara_limpa(4,
chefe)` → vitória. Em `Subjugado` o mundo segue em passos vivos, a pausa abre e
"Abandonar run" fica desabilitado (R4-P passo 4).

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

**(emenda Pactos, 2026-11-15)** Linhas novas:

| Sistema | Recebe da Run | Fornece à Run | Dono da interface |
|---|---|---|---|
| Chefes | `doutrina()` (Chefes R12); a câmara 6 na sequência | `chefe_subjugado`; `camara_limpa(4, chefe)` via Câmaras; `creditar(chefe, 6)` direto na Economia | Chefes |
| Vínculo e pactos | `pedir_dupla()` (Pactos); o fim da run | `dupla_confirmada(campo, reserva)`; `chefe_escolhido(id, escolha)` | Vínculo e pactos (**contrato pedido**) |
| Maldições | a dupla no início; o reset (R8-P) | — | Maldições |
| Armas das Doutrinas | 3 cartas na tela de escolha | a arma e a Doutrina | Armas (**contrato pedido**: R4 com 3 cartas) |
| Telemetria | resumo com `desfecho_chefe` e `dupla` | — | Telemetria |

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

**F1-P (emenda Pactos, 2026-11-15).** Câmaras jogáveis no Limiar = **7** (índice 6 é o
chefe). `p_max` continua **4**: o chefe não é câmara de combate e usa `p = 4` (Chefes
R2; Câmaras R3).

**F2-P (emenda Pactos, 2026-11-15).** `total = coletados + bonus`, como antes.
`coletados` agora inclui `frag_chefe`:
- `frag_chefe = 6` se o chefe foi abatido ou exorcizado;
- `frag_chefe = 0` se foi pactuado, ou se a run não chegou ao desfecho (Chefes F6).

Portas com o índice 5 recompensado (R3-P): Fragmentos nos índices 1,
2, 4 e 5, com `p` 1, 2, 3 e 4 = **2, 2, 3, 3** (máx. 10).

| Caso | Portas | Chefe | Vitória | Total |
|---|---|---|---|---|
| Lâmina/Ressonância, máx., vence | 10 | 6 | 15 | **31** |
| Pactos, máx., exorciza | 10 | 6 | 15 | **31** |
| Pactos, máx., pactua | 10 | 0 | 15 | **25** |
| Qualquer, mín., vence (abate) | 0 | 6 | 15 | **21** |
| Pactos, mín., pactua | 0 | 0 | 15 | **15** |
| Máx., morre no chefe | 10 | 0 | 0 | **10** |

~~Se o índice 5 **não** for recompensado (leitura de Chefes F6): portas máx. 7, totais
28 / 28 / 22 / 21 / 15 / 7.~~ (emenda Pactos, 2026-11-15) Chefes F6 foi emendado
(10/25/31) e já segue esta tabela (aprovado em 2026-11-16).

## Tuning Knobs

| Knob | Padrão | Faixa | Categoria | Efeito e racional |
|---|---|---|---|---|
| `camaras_jogaveis` (por região) | 6 | 1 – tamanho da região | gate | quantas câmaras o MVP joga; 6 tira o chefe (índice 6) |
| `fragmentos_vitoria` | 15 | 0–35 | curva | cânone `victoryFragments`; acima de 35 (10% da Oficina, 350 = 66 + 76 + 38 + 30 + 45 + 95 em `ARENA_UPGRADES`) a vitória sozinha vira inflação |
| `arma_padrao` | `lamina` | `lamina` ou `ressonancia` | gate | arma sugerida na primeira run; token inválido: erro RN1 |

**(emenda Pactos, 2026-11-15)**

| Knob | Padrão | Faixa | Categoria | Efeito e racional |
|---|---|---|---|---|
| `camaras_jogaveis` (Limiar) | **7** | 1–7 | gate | 7 inclui o chefe (índice 6); 6 volta ao MVP sem chefe (só para teste: a câmara 5 vira a última e as Portas voltam a `ultima`) |
| `arma_padrao` | `lamina` | `lamina`, `ressonancia` ou `pactos` | gate | `pactos` é o `WeaponDef` da Besta (`maldicoes.md:462`); token inválido: RN1 |

`fragmentos_chefe` (6) **não** é knob daqui: fica na `RegionDef` (Economia R2).

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

**(emenda Pactos, 2026-11-15)** Os casos "Última câmara" (índice 5) e "pedido de
montar o índice 6: RN3" acima valem só com `camaras_jogaveis = 6`. Com 7:

**Início com Pactos**
- ~~**0 espécies pactuadas:** sem tela de dupla; dupla vazia; a run começa só com a
  Besta (`maldicoes.md` R2). `dupla` no resumo fica vazia.~~ **0 espécies pactuadas
  (emenda Pactos, 2026-11-15):** o Vínculo V3 concede o Vulto Mudo; sem tela; a run
  segue como dupla de 1 (`dupla_confirmada(vulto_mudo, "")`). Dupla vazia só com dublê.
- **1 espécie pactuada:** sem tela; ela vai a campo, sem reserva.
- **Esc na tela da dupla:** volta à escolha de arma; nenhuma seed criada.
- **`dupla_confirmada` com espécie não pactuada ou repetida:** a Run recusa, fica em
  Escolha da dupla e registra o erro (a validação da dupla é de Vínculo e pactos;
  a Run só checa repetição e vazio-com-reserva).
- **Vínculo e pactos ausente (dublê ausente):** a Run trata como 0 pactuadas.

**Chefe e fim**
- **Índice 5 limpo:** não encerra; recompensa da porta e 1 porta forçada `chefe`
  (R3-P).
- **Morte no passo do abate do chefe:** vale a morte (R5-P); sem crédito do chefe.
- **Abandono em `Subjugado`:** desabilitado (R4-P passo 4). Abandono **antes** do
  chefe zerar a Vida, na câmara 6: permitido, como em qualquer câmara de combate.
- **Fechar o jogo em `Subjugado`:** a run se perde e o pacto do chefe **não** é
  registrado (só nasce na escolha). Pactos feitos antes nesta run seguem a regra de
  Vínculo e pactos (R8-P).
- **`chefe_escolhido` sem `chefe_subjugado` antes, ou com a run fora da câmara 6:**
  ignorado; `desfecho_chefe` não muda.
- **Lâmina/Ressonância e `chefe_subjugado` chega mesmo assim:** Chefes só o emite com
  `doutrina() == pactos`; se chegar, a Run ignora e registra o erro.
- **Já pactuado o Soberano e pactua de novo:** a vitória é igual; o vínculo avança em
  Vínculo e pactos (Chefes, Edge Cases); `desfecho_chefe = pactuado`.
- **Doutrina trocada no meio da run:** não existe; `doutrina()` é fixa de R2 até o fim.

**Dados**
- **RN2 (emenda):** a última câmara jogável deve ser `combate` ou `chefe`; santuário
  segue proibido. **RN3 (emenda):** `camaras_jogaveis` 0 ou > 7; montar índice
  `≥ camaras_jogaveis`. Contrato pedido a Conteúdo (RN1–RN3).

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

**(emenda Pactos, 2026-11-15)**

| Sistema | Força | Interface | Se faltar |
|---|---|---|---|
| Chefes | **Forte** (antes: reservado) | câmara 6; `doutrina()`; `chefe_subjugado`; `camara_limpa(4, chefe)` (Chefes R9) | sem vitória no MVP com 7 câmaras |
| Vínculo e pactos | Forte, **por contrato** ~~(GDD em escrita)~~ (`vinculo-e-pactos.md`) | `pedir_dupla`, `dupla_confirmada`, `chefe_escolhido` | dupla vazia; chefe de Pactos sem desfecho |
| Maldições | Suave | dupla no início; reset (`maldicoes.md` R2, R14) | Pactos só com a Besta |
| Armas das Doutrinas | Forte | tela de escolha com 3 cartas (**contrato pedido**, R4) | só 2 Doutrinas |
| Portas e recompensas | Forte | índice 5 recompensado, porta livre depois do 4 e forçada `chefe` depois do 5 (**contrato pedido**) | índice 5 sem recompensa (Chefes F6) |
| Conteúdo orientado a dados | Forte | `camaras_jogaveis` 7, `arma_padrao` com `pactos`, RN2/RN3 (**contrato pedido**) | — |

Bidirecional: Chefes já lista Run como dependente (Chefes, Depended On By).

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

**(emenda Pactos, 2026-11-15)** A tela de escolha passa a 3 cartas (Armas R4). A tela da
dupla é de Vínculo e pactos. A escolha Pactuar/Exorcizar é de Vínculo e pactos (Chefes
OQ1). A tela final mostra `desfecho_chefe` (ex.: "Soberano do Limiar: pactuado") e, em
Pactos, a dupla. Vitória sobre o chefe vai direto à tela final, sem Transição.

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

**(emenda Pactos, 2026-11-15)** Fixture RN-P: a fixture RN com `camaras_jogaveis` 7,
dublês de Chefes (emite `chefe_subjugado` e `camara_limpa(4, chefe)` sob comando) e de
Vínculo e pactos (lista de pactuadas injetável; responde `dupla_confirmada` e
`chefe_escolhido`). Com 7 câmaras, **AC-RN-07, 09, 10, 18, 24 e 25 são substituídos**
por AC-RN-29 a AC-RN-33; AC-RN-02 e AC-RN-05 ganham os casos de Pactos (AC-RN-27, 28).
Os antigos seguem válidos com `camaras_jogaveis = 6`.

- **AC-RN-27 [L] R2-P — ordem com Pactos.** GIVEN Doutrina `pactos` e 2 pactuadas,
  WHEN a run começa, THEN a ordem nos dublês é: arma, `pedir_dupla`,
  `dupla_confirmada`, seed, estado inicial (dupla entregue às Maldições), câmara 0 com
  `primeira_recompensa`, Transição. Com Lâmina, nenhum `pedir_dupla`.
- **AC-RN-28 [L] R2-P — 3 cartas e Vida.** A tela de escolha lógica tem 3 cartas
  (`lamina`, `ressonancia`, `pactos`); a Vida inicial é 100, 80 e 90
  (`maldicoes.md:462`); `doutrina()` devolve o token da carta.
- **AC-RN-29 [L] R2-P 1b — pulos da dupla.** ~~Com 0 pactuadas: sem tela, `dupla`
  vazia, estado Ativa.~~ (emenda Pactos, 2026-11-15) Com 0 pactuadas: o Vínculo V3
  concede o Vulto Mudo, sem tela, chega `dupla_confirmada(vulto_mudo, "")` e o estado
  vai a Ativa com campo = Vulto Mudo, reserva vazia. Com 1: sem tela, campo = a espécie, reserva vazia. Com 2: estado
  Escolha da dupla; Esc volta a Escolha de arma sem seed criada.
- **AC-RN-30 [L] R3-P — sequência com chefe.** Índice 4 → `combate`; índice 5 →
  `chefe`; índice 6 → `fim_da_run`; montar o índice 6 não dá erro; montar o 7 dá RN3.
- **AC-RN-31 [I] R3-P — índice 5 comum.** Limpar o índice 5: estado Ativa, a
  recompensa da porta escolhida depois do 4 é concedida (Fragmentos: 3) e abre 1 porta
  `chefe`, sem consumir o fluxo `portas`. **[a confirmar com Portas]**
- **AC-RN-32 [I] R4-P — vitória por abate.** GIVEN Lâmina, saldo 11 e coletados 5,
  WHEN o dublê de Chefes credita 6 e emite `camara_limpa(4, chefe)` no índice 6, THEN
  0 portas, 0 `recompensa`, a Run lê coletados 11, credita 15, `run_encerrada(vitória)`
  1 vez, saldo 32, resumo coletados 11, bônus 15, total 26, `desfecho_chefe = abatido`,
  câmaras limpas 7.
- **AC-RN-33 [I] R4-P — Pactos, escolha antes da vitória.** GIVEN Pactos, WHEN chega
  `chefe_subjugado`, THEN a run segue Ativa e nenhum `run_encerrada` sai; WHEN chega
  `chefe_escolhido(soberano_do_limiar, pactuar)` e depois `camara_limpa(4, chefe)` sem
  crédito do chefe, THEN vitória, bônus 15 e `desfecho_chefe = pactuado`. Com
  `exorcizar` e crédito 6: `desfecho_chefe = exorcizado` e coletados soma 6.
- **AC-RN-34 [L] R4-P passo 4 — sem abandono em `Subjugado`.** Depois de
  `chefe_subjugado`, a pausa abre e "Abandonar run" está desabilitado; confirmar não
  encerra.
- **AC-RN-35 [L] R5-P — morte no abate do chefe.** `jogador_morreu` no mesmo passo do
  abate: run encerra com `morte`, `desfecho_chefe = nenhum`, nenhuma vitória.
- **AC-RN-36 [I] R8-P — reset com Pactos.** GIVEN uma run de Pactos que pactuou o
  chefe, com saldo 30, WHEN `nova_run`, THEN saldo 30, dupla e estado das Maldições
  zerados, chefe ausente, e o dublê de Vínculo e pactos ainda lista
  `soberano_do_limiar` como pactuado (a Run não chamou nada que o apague).
- **AC-RN-37 [L] R7-P — resumo.** O resumo tem 12 campos; `chefe_escolhido` fora da
  câmara 6 é ignorado; o resumo não muda depois de montado.
- **AC-RN-38 [L] Validação (emenda).** `arma_padrao = pactos` é aceito;
  `camaras_jogaveis` 8: RN3; última jogável `santuario`: RN2; última `chefe`: válido.

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

**(emenda Pactos, 2026-11-15)** OQ 3: os Fragmentos do chefe entram no MVP (R4-P);
fica aberta só a 2ª região. OQ 6: no MVP a carta da tela de escolha é o juramento;
Campus e Rito seguem para a fatia vertical.

| # | Pergunta | Dono | Prazo |
|---|---|---|---|
| 10 | Índice 5 recompensado (R3-P) vs. sem recompensa (Chefes F6): decidir e alinhar Portas R2/R6/F2 e Chefes F6 | usuário; Portas; Chefes | antes de aprovar esta emenda |
| 11 | Pulos da tela da dupla (0 e 1 pactuadas) e o evento `chefe_escolhido` | Vínculo e pactos | GDD de Vínculo e pactos |
| 12 | Pacto feito numa run que termina em morte ou abandono fica? (R8-P) | Vínculo e pactos / usuário | GDD de Vínculo e pactos |
| 13 | "Abandonar run" desabilitado em `Subjugado` (R4-P) | usuário / Input | revisão desta emenda |
| 14 | Edições pendentes: Armas R4 (3 cartas), Conteúdo (RN2/RN3, `camaras_jogaveis` 7, `arma_padrao` com `pactos`), Telemetria (2 campos novos no resumo) | donos de cada GDD | próxima edição de cada um |
