# Feedback de combate (VFX)

> **Status**: Approved (2026-11-11; revisão única por subagente: 11 bloqueantes e recomendadas, corrigidos sem re-review; sem entrada no review log)
> **Author**: usuário + Claude (design-system, modo Lean)
> **Last Updated**: 2026-11-11
> **Last Verified**: 2026-11-11
> **Implements Pillar**: P3 *Reflexo que se lê*; P4; P2 *A Beira cobra*

## Summary

O **Feedback de combate (VFX)** é o **catálogo e o árbitro** das respostas visuais, de
câmera e de áudio aos eventos do jogo: para cada evento diz **qual resposta** dispara, **em
que camada e prioridade**, e como as respostas **se combinam** sob os limites de
acessibilidade e de orçamento. Ele **não é dono dos números** (hitstop, tremor, zoom, flash,
tamanho dos números): cita o GDD dono de cada um.

> **Quick reference** — Layer: `Presentation` · Priority: `MVP` · Key deps: `Combate núcleo, Pipeline visual, Telégrafos, Cena 3/4 e câmera`

## Overview

> `technical-artist` e `art-director` não consultados nesta seção: modo Lean.

O Combate, a Cena, o Pipeline e os demais GDDs **emitem eventos** e definem, cada um, parte
do que o jogador vê e ouve; faltava quem **juntasse** isso: o que acontece quando vários
eventos caem no mesmo passo, qual efeito vence, o que é descartado e como as opções de
acessibilidade mexem em tudo. Este GDD é esse árbitro.

- **Catálogo evento → resposta:** uma tabela com todos os eventos de apresentação do MVP, a
  resposta (efeito, câmera, número, gancho de áudio), a camada, a prioridade e o **dono do
  número** (Combate V1–V15 e R10, Cena F5, Pipeline F6/F8/F10, Selo, Status, Telégrafos,
  Movimento). **Sem duplicar valores.**
- **Regras só deste GDD:** a **fila e a preempção** (o que vence no mesmo passo), a
  **agregação e o teto dos números de dano** (soma em 300 ms, máx. 6, o mais antigo sai), o
  **crítico = acerto marcado pelo Combate (enésimo acerto, o 4º por padrão)** (decisão do usuário), como o **limitador de flashes**, o
  **orçamento de VFX** e as **opções de acessibilidade** se combinam, e a **escada de
  degradação** em multidão.
- **Áudio:** só **ganchos** (nome do evento sonoro e prioridade); a lista de sons e a mixagem
  são do audio-director.
- **Lacunas fechadas com resposta mínima** (decisão do usuário): `camara_limpa`, onda nova,
  portas abertas, `recompensa`, `jogador_morreu`, cura e escudo, impacto de projétil inimigo
  e surgimento de inimigo ganham uma resposta enxuta (sem flash, sem impact frame, dentro dos
  limites) para nenhum evento ficar mudo.
- **Fora daqui:** o fio de Vida do inimigo e o prompt de interação ficam no **HUD** (R9/R10
  do HUD; decisão do usuário), e o Mestre, o chefe (fatia vertical) e a mixagem de áudio.

A **fantasia** é a de que cada ação tem peso legível e proporcional: o golpe leve é um
estalo, o pesado tem corpo, a recusa de morte para o mundo, e **nada se acumula até virar
ruído** (P3): o limite protege a leitura e a saúde do jogador.

As regras seguem os GDDs de Combate (V1–V15), Cena (F5), Pipeline (R7, F6, F8, F10) e a
Art Bible §7.7 e §7.9, com as decisões do usuário de 2026-11-11: catálogo com prioridade e
orçamento (sem duplicar valores), só ganchos de áudio, crítico = acerto marcado (enésimo acerto do Combate, o 4º por padrão), lacunas com
resposta mínima e fio/prompt no HUD.

> **→ vira ADR:** como o árbitro de respostas recebe os eventos do passo e aplica a
> fila/preempção sem acoplar os emissores (um barramento de eventos de apresentação).

## Detailed Design

### Core Rules

**R1. Árbitro, não dono.** O Feedback recebe os **eventos de apresentação do passo** e emite
**pedidos de resposta** às camadas: câmera (Cena F5), impact frame e passes de tela
(Pipeline R7/F6), VFX de mundo, números e letreiros, e ganchos de áudio. **Só lê eventos**:
nunca altera estado de jogo. Os números (hitstop, tremor, zoom, flash, tamanho) são dos
donos da coluna "Dono" da R3; este GDD não os copia.

**R2. Dois relógios** (Pipeline F8, Combate V1). Respostas **vivas** (flash de acerto,
inversão de silhueta) correm no relógio vivo e **congelam** no hitstop; respostas de
**apresentação** (estrela, número, fagulha, letreiro, manchas) correm **durante** o hitstop.
Cada linha da R3 diz o relógio.

**R3. Catálogo evento → resposta.** "Dono" é o GDD dono dos números; "Câm." é o preset de
impulso de câmera (Combate V14 → Cena F5; "—" = nenhum); "→ P" é a prioridade (R4); "♪" é o
gancho de áudio (R9). Onde uma resposta tem partes de prioridades diferentes, há linhas
separadas.

| Evento | Resposta (resumo) | Relógio | Dono | Câm. | → P | ♪ |
|---|---|---|---|---|---|---|
| `golpe` (arco) | smear de meia-lua; sem alvo: sem hitstop, câmera nem fagulha | vivo | Combate V2 | — | 3 | `sfx_golpe_arco` |
| `area` (círculo) | anel tracejado (z −5); sem alvo: sem hitstop, câmera nem fagulha | vivo (anel e manchas congelam no hitstop; Combate V1/V3, decidido 2026-11-13) | Combate V3 | — | 3 | `sfx_golpe_area` |
| `disparo` (do jogador) | recuo, respingo, projétil em osso, rastro | vivo | Combate V4 | — | 3 | `sfx_disparo` |
| fim do projétil do jogador | 2 quadros ou respingo de 24 px | apres. | Combate V4 | — | 4 | `sfx_projetil_fim` |
| `investida` | poses, rastro de pincelada; 1º alvo pesado, os seguintes leves | vivo | Combate V5, R10 | pesado, depois leve | 3 | `sfx_investida` |
| `acerto`: flash | flash vivo no alvo (elite/chefe: tranco de 3°) | vivo | Combate V6, V15 | leve/pesado | **0** | `sfx_acerto_leve` / `sfx_acerto_pesado` |
| `acerto` leve: resto | estrela leve, fagulhas, tranco (**acerto leve de projétil: sem impulso de câmera**, Combate V14/AC-72) | apres. | Combate V6, R10 | leve | 3 | (idem) |
| `acerto` pesado: resto | estrela grande, mancha de tinta, mais fagulhas | apres. | Combate V6, R10 | pesado | 2 | (idem) |
| `acerto` **marcado** (R5) | número dourado e timbre "consagrado" (o gancho **soma** ao do peso, Combate AC-80b); o resto segue o peso | apres. | Combate V6/V7, Modificadores | segue o peso | 2 | `sfx_acerto_critico` |
| reflexo / `explosao` como origem do dano | resposta leve, sem fagulha | apres. | Combate V6, V13 | leve 0,5 | 3 | `sfx_acerto_leve` |
| número de dano | R6 | apres. | Combate V7; Art Bible §7.7 | — | 3 | — |
| `parede` | novo flash, 1 quadro de esmagamento, meia estrela, poeira, rachadura de 2 s; o dano soma ao número do mesmo alvo e passo (R6) | vivo (flash, V1/V6) / apres. (resto) | Combate V8 | leve | 3 | `sfx_parede` |
| telégrafo `quebrado` (de `quebrou`) | o telégrafo se parte em 2 quadros, sem flash | vivo | Combate V9, V15; Telégrafos | — | **0** | `sfx_quebrou` |
| `quebrou`: marca e letreiro | marca de 3 traços (relógio vivo: segue `quebrou_recuperacao_s`, Combate V9), letreiro "Quebrou!" | vivo (marca) / apres. (letreiro) | Combate V9 | — | 2 | `sfx_quebrou` |
| `jogador_atingido` | inversão de silhueta, animação de Dano, contorno tracejado de invulnerabilidade; sem tela cheia nem vermelho | vivo | Combate V10, R10 | pesado | **0** | `sfx_jogador_atingido` |
| `recusou_morte` | impact frame, manchas de borda, zoom principal; o contorno tracejado de invulnerabilidade corre no relógio **vivo** (V10) | apres. | Combate V11; Pipeline R7 | pesado + zoom | 1 | `sfx_recusou_morte` |
| `inimigo_morreu` comum | animação de morte, estrela leve | vivo (animação, Combate V1/V12) / apres. (estrela) | Combate V12, R10 | leve 0,6 | 3 | `sfx_morte_comum` |
| `inimigo_morreu` elite | coroa estilhaça, aura se apaga sem flash, mancha | apres. | Combate V12 | pesado | 2 | `sfx_morte_elite` |
| `inimigo_morreu` chefe | impact frame, cena congelada | apres. | Combate V12; Pipeline R7 | chefe | 1 | `sfx_morte_chefe` |
| `explosao` | anel tracejado até o raio (z −5), até 4 em cadeia | apres. | Combate V13 | leve 0,5 | 3 | `sfx_explosao` |
| `esquiva` | imagens residuais em osso tracejado | vivo | Movimento V2, V3 | — | 3 | `sfx_esquiva` |
| `esquiva_sem_carga` | só HUD (tremor dos chevrons) | — | HUD R7 | — | 4 | `sfx_esquiva_vazia` |
| `selo` / `selo_fim` | anel tracejado desenhado em 3 passos; dissolve em fiapos | apres. | Selo | — | 3 | `sfx_selo`, `sfx_selo_fim` |
| `selo_sem_fluxo` | só HUD (pisca do entalhe) | — | HUD R6 | — | 4 | `sfx_selo_vazio` |
| status aplicado / dano agregado | sinal fixo no inimigo e número agregado a cada 0,5 s | apres. | Status R8 | — | 3 | `sfx_status_<tipo>` |
| telégrafo `disparo` do inimigo / `cancelado` | flash de osso 2 passos (sob o limitador) / fade em 2 passos | vivo | Telégrafos; Pipeline F6 | — | **0** | `sfx_telegrafo_disparo` |
| lacunas (R10) | respostas mínimas | — | este GDD | — | 4 | R10 |

**R4. Prioridade e corte.** **P0** — o **orçamento nunca corta** (Combate V15; Pipeline R9):
o flash de acerto, o telégrafo e o telégrafo partido, a inversão do jogador e os passes
obrigatórios (transição, morte); o impact frame é **P1** (recusa e chefe) e só o limitador F6, a preempção R7, o corte na Transição e na Morte e a espera da Bênção (Pipeline AC-PV-81) o negam. **P1**: recusa de morte e
chefe. **P2**: resto do acerto pesado, acerto marcado, marca e letreiro do `quebrou`, morte
de elite. **P3**: golpe, disparo, resto do acerto leve, status, explosão, selo, esquiva. **P4**:
poeira, manchas, rachaduras, rastros, fim de projétil, respostas mínimas das lacunas. Quando o
**orçamento passa do teto** (uso ≥ 1,0, F3), o Feedback escolhe a vítima **de P4 para P2**, o
mais antigo primeiro, **antes** da regra do Pipeline R9 e do Combate V15 ("sai o mais antigo do
relógio de apresentação"), que só vale quando não sobra nada de P4 a P2 (corte de vítima
P4 → P2 **confirmado**, decisão do usuário, 2026-11-12); **P0 e P1 nunca saem por orçamento**. O
**limitador F6** e a **preempção R7** do Pipeline continuam valendo por cima: um flash de
telégrafo negado fica sem o osso (mas o telégrafo existe), e um impact frame negado ou
preemptado não é "cortado" por este GDD.

**R5. Crítico = acerto marcado** (decisão do usuário, revisada pelo Combate R8/V6). O
Combate marca o acerto no `acerto` pela flag do **enésimo acerto do portador** (`enesimo_acerto`:
o contador do portador, +1 por alvo atingido, múltiplo de `a_cada`: 4º, 8º, 12º…), e só quando
o portador tem `dano_enesimo_acerto`. O Feedback **só lê a flag**, não conta nada: acerto com a
flag → número dourado e timbre "consagrado"; sem a flag, nenhum dourado, mesmo no 4º golpe
do combo. **Não há crítico aleatório.** Um golpe em área pode ter o acerto marcado no meio
dos alvos.

**R6. Números de dano.** (Estilo e tamanhos: Combate V7 e Art Bible §7.7; aqui só as regras
de fila.)
- **Faixas de número aberto por alvo:** **golpe** (normal), **dourado** (acerto marcado) e
  **status**. Cada alvo tem **no máximo um número aberto por faixa**.
- **Agregação:** um golpe novo soma ao número de **golpe** aberto do alvo se `t_agora −
  t_nasceu ≤ janela_soma_s` (300 ms); senão abre outro. O **dourado nunca soma nem recebe
  soma**: o golpe seguinte soma ao número de golpe aberto (se ainda na janela) ou abre um novo.
  O dano de `parede` e de reflexo/explosão no mesmo alvo e passo **soma** ao número de golpe. O
  número de **status** (agregado a cada 0,5 s, Status R8) tem faixa própria e **não soma** com o
  de golpe.
- **Arredondamento:** a soma é feita em fração e **arredonda no fim**; fração < 0,5 que não
  chega a 1 não gera número (Combate V7). Cada soma **atualiza o texto e reinicia a vida de 0,6 s**
  do número (a subida de 24 px segue).
- **Teto de 6 números** (F2): ao nascer o 7º sai um número vivo conforme a F2.
- **Dano recebido pelo jogador não gera número** (vira segmento de Vida, HUD).
- **Opção "Números de dano"** (Art Bible §7.9 nº 7): *ligado*; *reduzido* (só o dourado e as
  somas de 2 ou mais golpes); *desligado* (nenhum número e **sem letreiro "Quebrou!"**,
  Combate V9/AC1).

**R7. Opções de acessibilidade.** O Feedback **não aplica** as opções: pede aos donos e
garante a ordem e que **nenhuma resposta as contorne**:

| Opção (Art Bible §7.9) | Efeito | Quem aplica |
|---|---|---|
| nº 3 Tremor de câmera (0–100%) | escala o tremor; a 0% sobram hitstop, estrela e flash | Cena F5 |
| nº 4 Reduzir flashes | impact frame vira o `reduzido`; flash de inimigo mais baixo | Pipeline R11/F6; Combate |
| nº 5 Redução de movimento | sem zoom; números e letreiros só com fade; manchas da recusa sem avançar; **o hitstop continua** | Cena; Pipeline; este GDD |
| nº 7 Números de dano | R6 | este GDD |
| Encurtar o hitstop | multiplicador separado | GDD de Acessibilidade e opções (OQ 3) |

**R8. Limitador, orçamento e degradação.** Impact frame, passes e disparos de telégrafo
passam pelo **limitador** do Pipeline (F6): pedido **negado é descartado e o evento de jogo
segue**; do impact frame negado **resta** o zoom, as manchas de borda, o hitstop e o número,
só o flash chapado sai. O **uso** do orçamento de VFX é medido pela F3 com os tetos do
Pipeline R9 e uma contagem injetável (proxy). A degradação tem **2 níveis**: **nível 1**
(uso ≥ `limiar_degradacao`, 0,90): corta P4 e **metade das fagulhas e estrelas**; **nível 2**
(uso ≥ `limiar_nivel2`, 0,95): soma o nível 1 e faz **smears de 1 quadro sem flipbook de P3** e
**status com 1 sinal por inimigo**. Volta por nível com histerese (F3). **Também vale o limite
de estrelas por passo do Combate V15** (6; a partir do 7º alvo, só o flash). Nunca corta P0 nem
P1. A degradação age **antes** do teto; a R4 (corte P4→P2) age **no teto** (uso ≥ 1,0).

**R9. Ganchos de áudio.** Cada resposta declara o **nome do evento sonoro** (coluna ♪ da R3) e
sua **prioridade** (R4). **Um som por gancho por passo**, qualquer que seja o número de
alvos (Combate A1: eventos iguais no mesmo passo soam como um só). Limites de voz:
`vozes_max_gancho` por gancho e `vozes_max_total` (F4). Sons, volume e mixagem são do
audio-director (OQ 4). Sons de perigo (`sfx_telegrafo_disparo`, `sfx_jogador_atingido`) são
P0. A ordem de prioridade do Combate A1 (`quebrou` acima do abate de chefe) é **provisória**
(A1) e fica **fora** deste GDD até o Áudio existir; vale a R4.

**R10. Lacunas fechadas com resposta mínima** (decisão do usuário; **provisório**, art-director,
OQ 2). Todas **sem flash, sem impact frame, sem câmera**, P4, dentro dos limites:

| Evento | Resposta mínima | ♪ |
|---|---|---|
| `camara_limpa` | as manchas de tinta do chão da câmara esmaecem em `assenta_camara_s`; a arena "assenta" | `sfx_camara_limpa` |
| onda nova | só o surgimento de cada inimigo (linha abaixo) | — |
| portas abertas | o acender das molduras já é das Portas (Portas, Visual/Audio); aqui só o som | `sfx_portas_abertas` |
| `recompensa` | Fragmentos e cura: o HUD e a pincelada de cura; aqui só o gancho por tipo | `sfx_recompensa_<tipo>` |
| `jogador_morreu` | animação de morte do Iniciado e o passe obrigatório da tela (Pipeline F6); sem impact frame (é da recusa) | `sfx_jogador_morreu` |
| cura | pincelada de tinta subindo no corpo do Iniciado (3 quadros); sem número no mundo (o HUD mostra) | `sfx_cura` |
| escudo ganho / perdido | contorno duplo de osso no Iniciado enquanto houver escudo; ao quebrar, 2 quadros de lascas | `sfx_escudo_ganho`, `sfx_escudo_quebra` |
| impacto de projétil inimigo em parede ou obstáculo | o mesmo respingo de fim do projétil do jogador (Combate V4); no jogador vale V10 | `sfx_projetil_inimigo_fim` |
| surgimento de inimigo (`surgindo`, IA) | mancha de tinta escura de forma irregular **sem contorno tracejado** (para não ser lida como telégrafo, Telégrafos/P3) durante o surgimento | `sfx_surgir` |

**R11. Camadas (de baixo para cima),** alinhadas ao Combate V15, V11 e ao Pipeline R7/R9: chão,
poeira, manchas, **anéis de área e de explosão** (z −5, **abaixo do telégrafo**) < telégrafo <
entidades < estrelas < flash < números < marca de vulnerável < letreiro "Quebrou!". O **impact
frame não é camada**: é o **shader global `modo_impacto`** do Pipeline R7 (sem passe de tela; a
UI não muda e o **contorno dos telégrafos continua visível por cima**); as manchas da recusa
ficam **abaixo de telégrafos e personagens** (V11). A UI (HUD) fica sobre o mundo. Smears e
estrelas podem passar sobre a área de um telégrafo, mas **nunca ocultam o seu contorno**.

**R12. Preempção no mesmo passo.** Ordem do limitador F6: **chefe > recusa > passes >
telégrafos** (Pipeline). Impact frame: chefe vence recusa (Pipeline R7); **no sprite do
jogador, o impact frame vence a inversão do `jogador_atingido` enquanto durar o `modo_impacto`**,
e a inversão (hitstop do golpe + 4 passos vivos, Combate R17: 10 no caso comum) é do relógio vivo e, no passo da recusa, vale o hitstop **pedido pelo golpe** (6, não o 18 da recusa); os 6 de hitstop se consomem dentro do congelamento de 18, e depois do `modo_impacto` voltam os **4 passos vivos** restantes da inversão (decidido 2026-11-13, Combate V10). **Impulso de câmera:**
o Feedback envia **um por passo**: vale o maior preset (**chefe > pesado > leve**; empate: a maior
`escala`; `recusou_morte` vence `jogador_atingido`); a Cena soma o que recebe (Cena F5) e a
`escala` é entrada do contrato da Cena (nota de edição pendente). Letreiros "Quebrou!": **no
máximo 2 na tela e 1 por passo** (Combate V9). Mesma resposta no mesmo alvo e passo: **uma só**
(o **gancho de áudio** já é um por passo, R9).

**R13. Transição e reset.** Na Transição de câmara, a fila e as respostas vivas são
**descartadas** e os relógios zeram na metade do wipe (Pipeline F8); os números de dano em
curso somem junto. A Nova run zera tudo.

**R14. Injeção e teste.** O árbitro recebe, por interface, a **lista de eventos do passo** e
os **dois relógios**; devolve a **lista ordenada de pedidos** (resposta, camada, prioridade,
gancho). Os testes montam tudo em memória, sem renderizar. O Feedback não escreve em
nenhum sistema.

### States and Transitions

Sem máquina de estados. Estado local: a **fila do passo**, a **janela de agregação** dos
números (300 ms por alvo) e o **modo de degradação** (normal ↔ degradado, R8, com
histerese 90%/75%). Tudo é limpo na Transição (R13).

### Interactions with Other Systems

| Sistema | Fornece ao Feedback | Recebe do Feedback | Dono da interface |
|---|---|---|---|
| Combate núcleo | eventos V1–V15, flag do acerto marcado, peso visual | — | Combate |
| Cena 3/4 e câmera | interface de impulsos (F5) | um pedido de impulso por passo (preset, direção, `escala`) | Cena |
| Pipeline visual | limitador (F6), relógios (F8), orçamento (F10), materiais, `modo_impacto` | pedidos de impact frame, passes e VFX | Pipeline |
| Telégrafos | estados do telégrafo | — | Telégrafos |
| Selo e Fluxo / Efeitos de status / Movimento | `selo`, `selo_fim`, status, `esquiva` | — | cada um |
| IA de inimigos | `surgindo`, elite, fase | — | IA |
| Câmaras / Portas | `camara_limpa`, onda nova, portas abertas, `recompensa` | — | Câmaras, Portas |
| HUD | — | nada (o HUD tem o fio, o prompt e os números de Fluxo/Vida) | HUD |
| Áudio (audio-director) | — | ganhos de gancho e prioridade | Feedback |
| Acessibilidade e opções (reservado) | opções 3, 4, 5, 7 e o encurtar do hitstop | — | Opções |

## Formulas

**F1. Agregação de números por alvo** (faixa de **golpe**, R6). Cada alvo tem no máximo um
número de golpe aberto. Um golpe novo **soma** se `t_agora − t_nasceu ≤ janela_soma_s` (300 ms,
tempo de apresentação); senão abre outro. A janela **não reinicia** a cada soma (evita número
eterno); a **vida** de 0,6 s do número reinicia a cada soma. O **dourado** (acerto marcado) tem
faixa própria: nunca soma nem recebe soma. Ex.: golpes de 12 (0,00 s) e 8 (0,10 s): o número
mostra 12 → 20; um acerto **marcado** de 9 em 0,20 s abre um dourado "9"; um golpe de 7 em
0,25 s **soma** ao número de golpe (27); um golpe de 6 em 0,35 s (fora da janela) abre um número
novo "6". Dano fracionário: soma em fração e arredonda no fim (0,4 + 0,4 = 0,8 → 1).

**F2. Teto e saída de números.** Números vivos (todas as faixas) ≤ `teto_numeros` (6). Ao nascer o
7º, sai um número vivo escolhido por: (1) **status** mais antigo; (2) senão **golpe** mais
antigo; (3) senão **dourado** mais antigo; um número de **status** recém-nascido com 6 vivos e
nenhum status mais velho **não nasce** se todos os 6 forem de golpe ou dourado (status sai
primeiro, inclusive o recém-chegado). Ex.: 6 vivos (2 status, 3 golpe, 1 dourado): o 7º tira o
status mais antigo; com 0 de status, o golpe mais antigo.

**F3. Degradação de VFX.** `uso = max(dc_vfx / 64, emissores / 24, partículas_gpu / 1 500)`, com
os tetos do Pipeline R9 e `dc_vfx` a **contagem injetável** (proxy: instâncias de VFX por
grupo; a captura PIX/RenderDoc do Pipeline é a verdade de produção). Níveis, cada um com
histerese: **nível 1** liga com `uso ≥ limiar_degradacao` (0,90), desliga com `uso <
limiar_retorno` (0,75); **nível 2** liga com `uso ≥ limiar_nivel2` (0,95), desliga com `uso <
retorno_nivel2` (0,85) (volta ao nível 1). Entre os limiares o nível **não muda**. Ex.: 60/64 =
0,9375 → nível 1; 62/64 = 0,969 → nível 2; 56/64 = 0,875 → continua nível 2 → 0,84 volta ao
nível 1; 47/64 = 0,734 → normal; 52/64 = 0,8125 → mantém o estado. No `uso ≥ 1,0` vale também
a R4. Overdraw e flipbooks (Combate V15) são medidos pelo Pipeline e não entram no `uso`.

**F4. Vozes de áudio.** Um som por gancho por passo (R9). Vozes por gancho ≤ `vozes_max_gancho`
(4) e no total ≤ `vozes_max_total` (16). Ao exceder: cai a voz de **menor prioridade** (P4 antes
de P3 … P0 nunca), a **mais antiga** em empate; se a **recém-chegada** for a de menor
prioridade, **ela** é descartada. No limite por gancho, o recém-chegado derruba a voz **mais
antiga do mesmo gancho** se tiver prioridade **igual ou maior**, senão é descartado. Ex.: 16
vozes (3 de P4) e um `sfx_acerto_leve` P3: cai a P4 mais antiga; 16 vozes todas P0–P1 e um P3
novo: o P3 é descartado.

**F5. Opção "reduzido".** Mostra o número só se for **dourado** ou uma **soma de 2 ou mais
golpes**; um golpe isolado e os números de status não aparecem. Ex.: golpes de 12 e 8 em 0,1 s →
mostra "20"; um golpe de 12 sozinho → nada; dois golpes de 0,4 (soma 0,8 → 1) → mostra "1".

## Tuning Knobs

`FeedbackTuning` (tipo novo no Conteúdo, dono: Feedback de combate; nota de edição pendente). `janela_soma_s` e `teto_numeros` repetem o Art Bible §7.7: a **fonte única** é este GDD (OQ 1):

| Knob | Padrão | Faixa | Categoria | Efeito |
|---|---|---|---|---|
| `janela_soma_s` | 0,3 | 0,2–0,5 | feel | janela de soma de números por alvo (Art Bible §7.7: 300 ms) |
| `teto_numeros` | 6 | 4–8 | gate | números simultâneos na tela (Art Bible §7.7: 6) |
| `limiar_degradacao` | 0,90 | 0,80–0,95 | gate | uso do orçamento de VFX que liga a degradação |
| `limiar_retorno` | 0,75 | 0,60–0,85 | gate | uso que a desliga; **sempre ≤ `limiar_degradacao` − 0,05** (validação FB3) |
| `limiar_nivel2` | 0,95 | 0,92–0,99 | gate | uso que liga o nível 2 de degradação (≥ `limiar_degradacao` + 0,03) |
| `retorno_nivel2` | 0,85 | 0,70–0,90 | gate | uso que desliga o nível 2 (**sempre ≤ `limiar_nivel2` − 0,05**, FB3) |
| `vozes_max_gancho` | 4 | 2–8 | gate | vozes simultâneas por gancho |
| `vozes_max_total` | 16 | 8–32 | gate | vozes simultâneas de combate |
| `assenta_camara_s` | 1,0 | 0,5–2,0 | feel | esmaecer das manchas em `camara_limpa` (R10) |

Os números de efeito (hitstop, tremor, zoom, flash, tamanho do número, tetos de draw calls e
emissores) **não** são knobs daqui: são do Combate, da Cena e do Pipeline (R1).

## Edge Cases

- **Vários eventos no mesmo passo:** a R12 resolve (um impulso de câmera, um impact frame, 1
  letreiro por passo); as demais respostas coexistem, cortadas só pela R4/R8.
- **Alvo morre com número aberto:** o número termina sua vida normal (não some com o alvo).
- **Dano 0 (M = 0):** **não** gera número; o acerto mantém o resto da
  resposta (flash, estrela) pelo seu peso.
- **Número de alvo que morre no mesmo passo:** aparece (o golpe que matou conta); o fio e o sinal
  de status do alvo somem na morte (HUD, Status).
- **Golpe sem alvo (arco ou círculo no vazio):** sem número, sem hitstop, sem câmera e sem
  fagulha (Combate V2).
- **Acerto marcado e soma no mesmo passo:** o dourado abre na sua faixa; os golpes seguem somando no número de golpe (F1).
- **Opção de números "desligado":** nenhum número e nenhum letreiro "Quebrou!"; o resto do
  `quebrou` (telégrafo se parte, marca de 3 traços) continua.
- **Recusa e morte de chefe no mesmo passo:** o chefe vence o impact frame (Pipeline R7); a recusa perde só o impact frame, as manchas de borda e a Vida voltam como o Combate manda; no sprite do jogador o impact frame vence a inversão (R12).
- **Impact frame negado pelo limitador:** o flash chapado sai; zoom, manchas de borda, hitstop e número ficam (R8); o evento de jogo segue.
- **Degradação no meio de um impact frame, telégrafo, flash de acerto ou inversão:** nunca corta P0 nem P1 (R4/R8); só P4 → P2.
- **Uso oscilando perto de 0,90 ou 0,95:** a histerese 0,90/0,75 e 0,95/0,85 evita o liga-desliga (F3).
- **Muitos inimigos com status (> 9):** 1 sinal por inimigo (Status) e os números agregados de status competem pelo teto de 6 (saem primeiro, F2); o status novo com 6 vivos de golpe/dourado não nasce.
- **Pausa:** os dois relógios congelam (Pipeline R8/F8); as respostas em curso retomam de onde pararam. **Bênção:** os relógios congelam, mas **números e letreiros somem** no quadro em que ela abre e **não voltam** ao fechar (Pipeline R2 e AC-PV-71, decisão da revisão cruzada de 2026-11-11); as demais respostas retomam de onde pararam.
- **Transição de câmara:** fila, números e respostas vivas descartados (R13); os ganchos de áudio
  já emitidos tocam, o VFX não.
- **`camara_limpa` com a Transição logo depois:** o VFX P4 pode ser descartado; o gancho toca.
- **Área com 5 alvos:** 5 números e flashes, **um** som por gancho no passo (R9); no máximo 6 estrelas (Combate V15).
- **Evento sem linha no catálogo:** sem resposta e erro de validação `FB1` (log, nunca falha); o
  jogo segue.
- **Gancho de áudio sem som mapeado:** silêncio e aviso `FB2`; o jogo segue.
- **Redução de movimento + tremor 0%:** sobram hitstop, estrela e flash (R7); números e letreiros
  só com fade.
- **Reduzir flashes + recusa de morte:** o impact frame vira `reduzido` (1 passo, mundo
  dessaturado) e o resto da recusa segue (R7).
- **`recusou_morte` e `jogador_morreu`:** não coexistem no mesmo passo (a recusa evita a morte).
- **Desligar um VFX da R10 por degradação:** o gancho de áudio da R10 permanece.
- **Nova run:** a fila, a janela de agregação e o modo de degradação voltam ao estado inicial
  (R13).

## Dependencies

| Sistema | Direção | Natureza | Interface |
|---|---|---|---|
| Combate núcleo | entra | rígida | eventos V1–V15, flag do acerto marcado (`enesimo_acerto`), peso visual, V9/V14/V15 |
| Cena 3/4 e câmera | entra e sai | por contrato | interface de impulsos (F5); recebe pedidos de preset e direção |
| Pipeline visual | entra e sai | rígida | limitador (F6), relógios (F8), orçamento (F10), `modo_impacto`; recebe pedidos de impact frame, passes e VFX |
| Telégrafos | entra | leitura | estados `disparo`, `quebrado`, `cancelado` |
| Selo e Fluxo, Efeitos de status, Movimento e esquiva | entra | leitura | `selo`, `selo_fim`, status e dano agregado, `esquiva` |
| IA de inimigos e elites | entra | leitura | `surgindo`, elite, fase |
| Câmaras e ondas, Portas e recompensas | entra | leitura | `camara_limpa`, onda nova, portas abertas, `recompensa` |
| Conteúdo orientado a dados | entra | rígida | `FeedbackTuning` |
| HUD | paralelo | independente | o HUD fica com fio, prompt e números de Vida/Fluxo; o Feedback não os desenha |
| Áudio (audio-director, sem GDD no MVP) | sai | por contrato | nomes de gancho e prioridade |
| Acessibilidade e opções (reservado) | entra | por contrato | opções 3, 4, 5, 7 e encurtar o hitstop |

Nenhum sistema depende do Feedback para **rodar**: sem ele o jogo segue, só sem apresentação.

## Visual/Audio Requirements

- Este GDD **não desenha**: os desenhos de cada resposta estão nas colunas "Dono" da R3
  (Combate V2–V13, Selo, Status, Movimento, Telégrafos).
- **Respostas mínimas (R10):** mancha escura de surgimento **sem contorno tracejado**, pincelada
  de cura, contorno duplo de osso do escudo, esmaecer das manchas ao limpar a câmara; todas
  em osso e tinta, sem flash, sem vermelho, sem dourado (o dourado é do acerto marcado, P1/Art Bible).
- **Camadas (R11):** poeira e manchas abaixo do telégrafo; números e letreiros acima das
  entidades; impact frame acima de tudo.
- **Áudio:** só os nomes de gancho da R3/R10 e a prioridade (R4/R9); sons, volume e mixagem
  são do audio-director.

## Game Feel

- **Latência:** todo pedido sai no mesmo passo do evento (≤ 16,7 ms).
- **Peso proporcional:** leve < pesado < crítico < recusa < chefe, lido pela escala dos donos
  (hitstop, estrela, zoom), nunca por mais ruído.
- **Legibilidade antes de espetáculo (P3):** nada de P4 cobre telégrafo; a degradação
  (R8) protege a leitura em multidão e P0/P1 nunca são cortados.
- **Fotossensibilidade:** os limites de flash e impact frame são do Pipeline (F6) e sempre
  valem; o Feedback só pede.
- **Sem número ao receber dano:** o jogador lê a Vida no HUD, não um número no corpo.

## UI Requirements

- Sem tela própria. Os números de dano e o "Quebrou!" são desenhos **no mundo**, acima do alvo.
- Opção "Números de dano" no menu de opções (ligado, reduzido, desligado): spec de UX no GDD
  de Acessibilidade e opções (OQ 3).
- O fio de Vida do inimigo e o prompt de interação são do **HUD** (R9/R10 do HUD).

## Cross-References

- Combate V1–V15 e R10; Cena F5; Pipeline R7, R9, R11, F5, F6, F8, F10; Telégrafos; Selo; Status
  R8; Movimento V2–V5; Art Bible §7.7, §7.9; HUD R9/R10 e OQ 6.
- Índice: linha 31.

## Acceptance Criteria

Tipos: [L] lógica (unitário, eventos e relógios falsos), [I] integração, [V] visual (screenshot ou
vídeo curto em `production/qa/evidence/`).

- **AC-FB-01 [L] R1/R14 — só lê e ordena.** O árbitro, alimentado por eventos falsos, devolve a lista ordenada de pedidos (resposta, camada, prioridade, gancho) sem chamar nenhum método de escrita de qualquer sistema.
- **AC-FB-02 [L] R3 — catálogo completo.** Cada evento da R3 e da R10 (incluindo `golpe` e `area` separados, fim de projétil, reflexo/explosão como origem) tem linha, prioridade P0–P4, preset de câmera e gancho (ou "—").
- **AC-FB-03 [L] R2 — relógios.** Em hitstop de 6 passos: o flash de acerto (vivo) congela e a estrela (apresentação) continua; o `disparo` do jogador (vivo) congela.
- **AC-FB-04 [L] R5 — acerto marcado.** Com `dano_enesimo_acerto` (a_cada 4): o 4º e o 8º `acerto` do portador trazem a flag e geram o dourado e `sfx_acerto_critico`; o 5º não; sem a bênção, nem o 4º; a flag vem do evento, o árbitro não conta nada; mesma sequência de eventos = mesmo resultado.
- **AC-FB-05 [L] F1 — soma por faixa.** 12 (0,00 s), 8 (0,10 s): "12" → "20"; acerto marcado de 9 em 0,20 s abre um dourado "9"; golpe de 7 em 0,25 s soma ao número de golpe (27); golpe de 6 em 0,35 s abre "6".
- **AC-FB-06 [L] F1 — dourado nunca soma.** Um golpe logo depois do dourado não altera o dourado; dois golpes de 0,4 somam 0,8 e mostram "1".
- **AC-FB-07 [L] F2 — teto.** Com 6 números vivos (2 status, 3 golpe, 1 dourado), o 7º remove o status mais antigo; sem status, o golpe mais antigo; sem golpe, o dourado mais antigo; nunca há mais de 6; um número de status novo com 6 vivos de golpe/dourado não nasce.
- **AC-FB-08 [L] R6 — dano ao jogador.** `jogador_atingido` não cria número de dano.
- **AC-FB-09 [L] R6/Edge — dano 0 e fração.** Dano 0 não cria número e o flash e a estrela do `acerto` seguem pelo peso; um único dano de 0,4 não cria número.
- **AC-FB-10 [L] F5/R6 — reduzido.** Opção "reduzido": 12 e 8 em 0,1 s mostra "20"; um golpe de 12 sozinho e um número de status não aparecem; o dourado aparece.
- **AC-FB-11 [L] R6 — desligado.** Opção "desligado": nenhum número e nenhum letreiro "Quebrou!"; o telégrafo se parte e a marca de 3 traços do `quebrou` continuam.
- **AC-FB-12 [L] R4 — corte por orçamento.** Com `uso ≥ 1,0`: saem P4, depois P3, depois P2, o mais antigo primeiro; o flash de acerto, o telégrafo, o telégrafo partido, a inversão e os P1 **nunca** saem.
- **AC-FB-13 [L] F3/R8 — níveis.** `uso` 0,9375: nível 1 (corta P4 e metade das fagulhas e estrelas); 0,969: nível 2 (soma smears de 1 quadro e status com 1 sinal por inimigo); 0,875 estando no nível 2: continua no 2; 0,84: volta ao 1; 0,734: normal; 0,8125 sem mudança.
- **AC-FB-14 [L] F3 — histerese.** `uso` oscilando entre 0,76 e 0,89 por 10 s não muda o nível, em nenhum dos dois estados.
- **AC-FB-15 [L] R8 — estrelas.** 7 alvos atingidos no mesmo passo: 6 estrelas; o 7º só mostra o flash (Combate V15).
- **AC-FB-16 [L] R12 — impact frame.** Chefe e recusa no mesmo passo: só o do chefe; recusa depois do chefe na janela fica sem impact frame (Pipeline R7); no sprite do jogador o impact frame vence a inversão enquanto durar o `modo_impacto`.
- **AC-FB-17 [L] R12 — câmera.** Pesado e leve no mesmo passo: um impulso, o pesado; chefe e pesado: o chefe; dois pesados: a maior `escala`; `recusou_morte` e `jogador_atingido`: `recusou_morte`.
- **AC-FB-18 [L] R12 — letreiros e repetição.** 3 `quebrou` no mesmo passo: 1 letreiro nasce e nunca há mais de 2 na tela; dois pedidos idênticos no mesmo alvo e passo viram um.
- **AC-FB-19 [L] R7 — opções.** Tremor 0%: nenhum tremor, hitstop e flash seguem; Reduzir flashes: o pedido sai como `reduzido`; Redução de movimento: sem zoom, números e letreiros sem movimento, o hitstop continua.
- **AC-FB-20 [L] R8 — limitador.** Impact frame negado pelo limitador: o flash chapado sai, o zoom, as manchas de borda, o hitstop e o número ficam, e o evento de jogo segue sem erro; um flash de telégrafo negado deixa o telégrafo sem o osso mas visível.
- **AC-FB-21 [L] R9/F4 — vozes.** Uma área com 5 alvos gera **um** `sfx_acerto_leve` no passo; com 16 vozes (3 de P4) um P3 novo derruba a P4 mais antiga; com 16 vozes todas P0–P1 o P3 novo é descartado; um 5º do mesmo gancho derruba o mais antigo desse gancho só com prioridade igual ou maior.
- **AC-FB-22 [L] R10 — lacunas.** Cada evento da R10 produz a resposta mínima e o gancho listados, sem flash, impact frame ou câmera; `jogador_morreu` não pede impact frame.
- **AC-FB-23 [L] R10 — surgimento.** A definição da resposta de surgimento não tem contorno tracejado.
- **AC-FB-24 [L] R13 — Transição.** Em Transição: fila e respostas vivas descartadas, números somem, ganchos já emitidos tocam, o VFX não; a Nova run zera a janela de agregação e o nível de degradação.
- **AC-FB-25 [L] Edge — validação.** Evento sem linha no catálogo: sem resposta e `FB1`; gancho sem som: silêncio e `FB2`; `limiar_retorno` > `limiar_degradacao` − 0,05 ou `retorno_nivel2` > `limiar_nivel2` − 0,05: `FB3`.
- **AC-FB-26 [L] Edge — pausa e Bênção.** Com a pausa aberta, os dois relógios param e as respostas retomam de onde pararam; com a Bênção aberta, os relógios param, números e letreiros somem e não voltam ao fechar (Pipeline AC-PV-71) e as demais respostas retomam.
- **AC-FB-27 [L] R11 — camadas.** A ordem de desenho é: anéis e manchas (z −5) < telégrafo < entidades < estrela < flash < número < marca de vulnerável < letreiro; o impact frame é o shader `modo_impacto` e não uma camada; o contorno do telégrafo permanece visível sob estrela e smear.
- **AC-FB-28 [L] R4 — P0/P1 sob degradação.** Em qualquer nível de degradação, o flash de acerto, o telégrafo, o telégrafo partido, a inversão, a recusa e o chefe continuam sendo pedidos.
- **AC-FB-29 [I] R3/R5 — Combate real.** Um combo com a bênção de enésimo acerto (a_cada 4): números, estrela e o 4º dourado aparecem na ordem e no peso certos; um `quebrou` mostra o letreiro e o telégrafo se parte.
- **AC-FB-30 [V] R3/R6/R11 — cena de combate.** Screenshot de uma câmara com 5 inimigos, 6 números e 2 letreiros: nenhum P4 e nenhuma estrela cobre o contorno de um telégrafo; o dourado se distingue do normal em cinza.
- **AC-FB-31 [V] R8 — multidão.** Vídeo curto com 9 inimigos, status e explosões em cadeia: a degradação liga sem cortar telégrafo nem inversão; o fio de Vida e o HUD seguem legíveis.

## Open Questions

| # | Pergunta | Dono | Resolver até |
|---|---|---|---|
| 1 | Soma de 300 ms e teto de 6 números: Combate V7 e Art Bible §7.7 os repetem; a fonte única passa a ser este GDD (R6/F1/F2) e o Combate V7 cita a exceção do dourado | Combate, art-director | `/review-all-gdds` |
| 2 | Visual das respostas mínimas da R10 (surgimento, cura, escudo, câmara limpa) | art-director | polimento |
| 3 | GDD de Acessibilidade e opções: opção de encurtar o hitstop, menu de números de dano | UX / accessibility-specialist | fatia vertical |
| 4 | Áudio: lista de sons, mixagem e vozes (ganchos da R3/R10 e `vozes_max_*`) | audio-director | Áudio |
| 5 | Conteúdo: `FeedbackTuning` (9 campos) e erros `FB1`–`FB3` como códigos V* | Conteúdo | próxima edição |
| 6 | Chefes (fatia vertical): intro, transição de fase e zoom de intro do chefe; barra de chefe | Chefes | fatia vertical |
| 8 | **Decidido (2026-11-13):** `area` e contorno de invulnerabilidade no relógio vivo; no passo da recusa a inversão vale o hitstop do golpe (Combate V1/V10) | Combate | — |
| 7 | **Edições pendentes:** Combate (V7 cita a fonte única e a exceção do dourado; V14 diz que o Feedback envia o impulso; A1 provisória; crítico = flag `enesimo_acerto`), HUD (OQ 6 encerrada: fio e prompt ficam no HUD), Cena (F5 aceita `escala` como entrada; um impulso por passo é do Feedback), Pipeline (`modo_impacto` negado: só o flash sai), Conteúdo (`FeedbackTuning`, 9 campos) | Combate, HUD, Cena, Pipeline, Conteúdo | `/review-all-gdds` |
