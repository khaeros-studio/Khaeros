# Input e controle

> **Status**: Approved (2026-11-10: contexto Transição na R10 e na R11, do `/review-all-gdds` 3ª passada (S-B1), mantido Approved por decisão do usuário; 2026-11-09: R6 diz que o orquestrador lê o hitstop do Combate, alinhado ao Combate núcleo R10 com aval do usuário; 4ª re-review `/design-review` 2026-11-06, sessão independente: APPROVED, 0 bloqueantes, recomendadas no log; anteriores: 3ª re-review NEEDS REVISION e `/review-all-gdds` FAIL, ambos revisados; 2ª passada do cross-review, CONCERNS: retirada do `InputTuning` ao sair de Pronto na R12 e Cross-References, aplicadas em 2026-11-06 com o status mantido por decisão do usuário)
> **Author**: usuário + Claude (design-system)
> **Last Updated**: 2026-11-10 (contexto Transição: R10, R11, AC-22, AC-23)
> **Last Verified**: 2026-11-06
> **Implements Pillar**: P3 *Reflexo que se lê* ("a esquiva sempre responde")
> **Creative Director Review (CD-GDD-ALIGN)**: pulada (modo Lean)

> **Nota (2026-11-11, Tela de bênção e carta):** pendente: a Tela usa a borda de subida do botão, esvaziar o buffer e `ui_carta_1..3`; não existem teclas 4 e 5.

> **Nota (2026-11-11, revisão cruzada):** pendente: o contexto Transição (R10) entra nas Interactions (a tabela de estados já o tem); a morte vira "Menu" (o Menu só abre na tela final; ver Edge Cases, decidido em 2026-11-13). A frase de Dependencies sobre GDDs existentes foi atualizada.

## Summary

**Input e controle** traduz teclado, mouse e gamepad em ações de jogo,
amostradas uma vez por passo de física, antes de qualquer outro sistema. Os dois
dispositivos são jogáveis e têm remapeamento completo, e toda tela funciona sem
mouse. A promessa ao jogador é que o controle nunca engole um comando: um buffer
curto guarda toques feitos durante uma recarga, uma esquiva ou o hitstop, com o
prazo congelado no hitstop.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `Conteúdo orientado a dados (suave), Cena 3/4 e câmera (forte, mira do mouse)`

## Overview

**Input e controle** é a camada que transforma teclado, mouse e gamepad em
**ações de jogo**: mover, mirar, Ataque, Especial, Selo, Esquiva, Interagir,
pausar e as escolhas de tela (bênção, porta, menus). Nenhum outro sistema lê
tecla ou botão diretamente: todos recebem ações já traduzidas, amostradas uma vez
por passo de física (60/s).

Os dois dispositivos são de primeira classe:

- **teclado e mouse:** WASD para andar e mira no cursor;
- **gamepad:** analógico esquerdo para andar e mira no direito.

**Os dois** têm remapeamento completo, como o Art Bible §7.9 exige. "Gamepad
parcial" passa a significar só: sem vibração e sem ícones por marca de controle
no MVP.

Toda tela, inclusive a de bênção, é usável sem mouse.

A promessa ao jogador é que **o controle nunca engole um comando**:

- um toque de Ataque, Especial, Selo ou Esquiva que chega durante uma recarga,
  uma esquiva ou o hitstop fica num **buffer** curto e sai assim que possível;
- a Esquiva sempre responde (P3).

Sem esta camada, cada sistema leria dispositivos do seu jeito, o remapeamento
seria impossível e os cliques durante o hitstop se perderiam. Isso é exatamente
o que o baseline §55 corrigiu no modo web.

> **→ vira ADR:** onde a amostragem acontece (nó próprio, Autoload só de
> leitura, injeção) e o formato do arquivo de binds do usuário.

## Detailed Design

### Core Rules

> `game-designer`, `ux-designer` e `gameplay-programmer` não foram consultados:
> modo Lean. Revisar manualmente antes de produção. Layout, mira no gamepad,
> buffer e "segurar repete" seguem o cânone (`preview/src/arena/input.ts`,
> baseline §55), por decisão do usuário em 2026-11-05.

**R1. Ações (lista fechada).** O jogo só conhece ações; nenhuma tecla aparece em
código de jogo. Os nomes são `StringName`.

| Contexto | Ação | Tipo | Padrão: teclado/mouse | Padrão: gamepad |
|---|---|---|---|---|
| Jogo | `mover` | vetor | W A S D (setas como secundário) | analógico esquerdo |
| Jogo | `mirar` | vetor | cursor do mouse | analógico direito |
| Jogo | `ataque` | botão | clique esquerdo (J) | X |
| Jogo | `especial` | botão | clique direito (K) | Y |
| Jogo | `selo` | botão | Q (F) | B (LB) |
| Jogo | `esquiva` | botão | Espaço (Shift, L) | A (RT) |
| Jogo | `interagir` | botão | E | RB |
| Jogo, Pausa e Bênção | `pausar` | botão | Esc | Start |
| Pausa, Bênção e Menu | `ui_aceitar` | botão | Enter (Espaço, E) | A |
| Menu | `ui_voltar` | botão | Esc | B |
| Pausa, Bênção e Menu | `ui_navegar` | direção | setas e WASD | direcional e analógico esquerdo |
| Bênção | `ui_carta_1` … `ui_carta_3` | botão | 1, 2, 3 | — (navega e aceita) |
| Bênção | `ui_trocar_ofertas` | botão | R | Y |

Entre parênteses estão os binds secundários: os do cânone (`KEY_BINDINGS`) e,
em `ui_aceitar`, os do Art Bible §7.6 (confirmar com Enter, Espaço ou E).
"Shift" é um bind só e vale pelos dois lados, como no cânone. Ações `debug_*` só
existem em build de debug. Os contextos estão na R10. Esc está em `pausar` e em
`ui_voltar`, mas nunca no mesmo contexto: Jogo, Pausa e Bênção usam `pausar`; o
Menu usa `ui_voltar`. O contexto Texto não usa ações de tela: só Enter e Esc
físicos, fixos (R10).

**R2. Amostragem.** Uma vez por passo de física (60/s), **antes** de qualquer
sistema de jogo, esta camada produz uma **amostra de entrada**:

- `mover`, com comprimento de 0 a 1;
- `mirar`, unitário;
- `fonte_mira`: `mouse`, `analogico` ou `automatica` (R5);
- `intensidade_mira`: o módulo do analógico direito depois da zona morta (F2),
  de 0 a 1; vale 0 quando `fonte_mira` não é `analogico`;
- botões **segurados**;
- botões **apertados neste passo**;
- o **buffer** (R6);
- a escolha de tela.

Os sistemas leem só a amostra, nunca `Input` nem eventos do Godot. A única
exceção é a **consulta de cursor** (R5), que só a Cena 3/4 usa, no quadro de
render.

**R3. Dispositivo ativo.** Os dois dispositivos funcionam ao mesmo tempo: botões
de ambos valem, e no movimento o teclado vence quando não é zero. O
**dispositivo ativo** é o último com entrada significativa:

- tecla ou clique;
- mouse movido mais que o limiar;
- analógico fora da zona morta;
- botão do gamepad.

Ele decide a fonte da mira (R5) e os ícones de comando da UI.

**R4. Movimento.**

- **Teclado:** 8 direções, normalizadas (a diagonal tem o mesmo módulo, 1).
- **Analógico:** zona morta radial e reescala (Formulas). O módulo entre 0 e 1
  é preservado, para permitir andar devagar. O que fazer com o módulo é do GDD
  de Movimento.

**R5. Mira.**

- **Mouse:** vetor do personagem até o cursor, em coordenadas de mundo. A
  conversão tela → mundo é feita pela Cena 3/4.
- **Gamepad**, em ordem de prioridade:
  1. analógico direito fora da zona morta;
  2. senão, **inimigo mais próximo** a até 1350 px (inclusivo) que não esteja
     surgindo (F4). O inclusivo é desvio deliberado do cânone, que usa
     `d < 900` (`packages/preview/src/arena/input.ts:181`); a diferença é só na
     borda exata (decisão do usuário, 2026-11-06);
  3. senão, a direção do movimento;
  4. senão, a direção em que o personagem olha;
  5. se tudo for zero, (0, −1).
- A mira nunca sai com comprimento zero.
- O inimigo mais próximo vem de uma **consulta de alvos** injetada (IA /
  Câmaras), e esta camada não conhece inimigos.
- **Fonte da mira** (`fonte_mira`, R2): `mouse` com o mouse como dispositivo
  ativo; `analogico` no critério 1 do gamepad; `automatica` nos critérios 2 a 5.
  O lookahead da Cena 3/4 (F2) usa a fonte e a `intensidade_mira`: com
  `automatica`, ele é 0.
- **Consulta de cursor:** consulta só de leitura que devolve a última posição
  válida do cursor em px de **janela** (Edge Cases: cursor fora da janela). É
  lida no quadro de render, não no passo de física, e serve só à Cena 3/4, que
  calcula com ela o vetor do lookahead (Cena F2, com `pos_seguir`). A mira do
  passo (`mirar`) continua saindo da amostra.

**R6. Buffer de comandos** (cânone, baseline §55).

- **Quem entra:** Ataque, Especial, Selo e Esquiva. Um toque **apertado neste
  passo** entra no buffer, e o prazo volta para `buffer_passos` (10).
- **Prazo:** passos sem toque novo descontam 1; no zero, o buffer esvazia.
- **Consumo:** o sistema consumidor pergunta "quer X?". Para **Ataque e
  Especial**, a resposta é "segurado **ou** no buffer" (R7). Para **Esquiva e
  Selo**, é **só** "no buffer": segurar não repete (cânone, `updatePlayer`). Ao
  executar X, remove X do buffer.
- **Prioridade:** com vários no buffer, a ordem é **Esquiva > Especial > Ataque
  > Selo**.
- **Hitstop:** a amostragem e o buffer continuam rodando durante o hitstop, mas
  **o prazo não desconta** (F3). É um desvio deliberado do cânone: no hitstop
  longo de chefe (36 passos) o cânone perdia toques (P3, decisão do usuário em
  2026-11-05). O orquestrador do passo lê o contador de hitstop do Combate (Combate núcleo R1, R10) e repassa "hitstop ativo" ao Input. Um
  toque feito durante o hitstop fica congelado e depois tem 9 passos vivos (o
  passo do toque conta como 1 dos 10).
- **Ordem de execução:** a cada passo os consumidores rodam sempre na ordem
  **Movimento → Combate → Selo**, e dentro do Combate o Especial é testado antes
  do Ataque. A prioridade do buffer sai dessa ordem: quem roda antes consome
  antes.

As regras de cancelamento (a esquiva cancela a recuperação etc.) são do GDD de
Movimento e esquiva.

**R7. Segurar repete.** A amostra informa quais botões estão segurados. Combate
e Armas repetem o golpe enquanto o botão de Ataque ou Especial estiver segurado
e a recarga permitir. Esta camada só informa.

**R8. Remapeamento.**

- **O que se remapeia:** toda ação da R1, exceto `debug_*`, nos dois
  dispositivos, separadamente.
- **Binds:** até **3 por ação por dispositivo** (primário e até 2
  secundários). O mapa padrão da R1 cabe nesse limite: Esquiva (Espaço, Shift,
  L) e `ui_aceitar` (Enter, Espaço, E) usam os 3.
- **Fora do remapeamento:** Enter e Esc do contexto Texto (R10) são fixos e não
  aparecem na tela de remapeamento.
- **Teclado:** remapeia `mover` direção por direção.
- **Gamepad:** os vetores não são remapeados, mas há a opção "trocar
  analógicos".
- **Tecla física:** o bind é guardado pela **tecla física** (posição), como no
  cânone. Num teclado AZERTY, o WASD continua na mesma posição. A UI mostra o
  rótulo do layout do usuário.
- **Conflito** (mesma entrada em duas ações do **mesmo contexto**): as duas
  trocam de lugar e uma mensagem avisa. A troca só acontece se nenhuma ação
  ficar sem bind primário; senão, é recusada com mensagem. `pausar` nunca entra
  em troca.
- **Pausa:** Esc e Start não podem ser removidos de `pausar`; só se pode
  acrescentar alternativos (até o limite de 3).
- **Persistência:** "Restaurar padrão" vale por dispositivo. Os binds são
  salvos no arquivo do usuário (`user://`) e carregados ao iniciar.
- **Mensagens:** usam chaves de tradução `INPUT_*`
  (`INPUT_BINDS_CORROMPIDOS`, `INPUT_CONTROLE_DESCONECTADO`,
  `INPUT_CONFLITO_TROCA`, `INPUT_RECUSA_TECLA`, `INPUT_RECUSA_PAUSA`). Cada aviso
  aparece **uma vez por sessão**.

**R9. Telas sem mouse.**

- Toda tela tem um foco inicial e navegação completa por `ui_*`.
- **Um único modelo de foco** (Art Bible §7.6): passar o mouse sobre um
  controle focável move para ele o **mesmo** foco do teclado e do gamepad, e o
  clique confirma. No Godot 4.6+ o foco do mouse é separado do foco de
  teclado/gamepad, então cada controle focável chama `grab_focus()` ao receber
  `mouse_entered`. A navegação por `ui_navegar` continua do controle em foco.
  **Exceção:** no contexto Texto (R10), o hover não move o foco; o campo em
  edição só perde o foco por Enter, Esc ou clique.
- **Tela de bênção:**
  - 1, 2 e 3 (`ui_carta_1` … `ui_carta_3`) **movem o foco** para a carta e não
    confirmam (Art Bible §7.6). Quem confirma é `ui_aceitar`.
  - `ui_trocar_ofertas` troca as ofertas (cânone: "R").
  - A trava contra escolha acidental (confirmação só 500 ms depois de a última
    carta assentar e 300 ms depois de trocar ofertas, Art Bible §7.6) é do GDD
    da Tela de bênção. Esta camada só garante que um botão já segurado ao abrir
    a tela não conta (R10).
- **Telas do MVP** (inventário que os testes percorrem): menu principal, pausa,
  bênção, morte, vitória, opções/remapeamento, erros do catálogo e debug.

**R10. Contextos.**

- **Jogo:** ações de jogo e `pausar`.
- **Pausa** (raiz do menu de pausa): `ui_aceitar`, `ui_navegar` e `pausar`. Esc
  ou Start fecham a pausa. B não faz nada. As opções abertas da pausa são Menu,
  e o `ui_voltar` delas volta para a Pausa.
- **Bênção** (tela de bênção, dentro da run): `ui_aceitar`, `ui_navegar`, atalhos
  1–3, `ui_trocar_ofertas` e `pausar`. A escolha não tem volta: Esc ou Start
  abrem a Pausa por cima, e fechá-la devolve a mesma oferta. B não faz nada.
- **Transição** (troca de câmara, durante o wipe; Combate núcleo R1; decisão do
  usuário, 2026-11-10): **nenhuma ação vale**, nem as de jogo nem `pausar`. O
  buffer esvazia ao entrar (regra da troca de contexto, abaixo) e nada é
  guardado durante o wipe. Ao descobrir, o contexto volta a Jogo, e os botões
  segurados durante a Transição seguem a regra "ignorados até serem soltos".
- **Menu** (menu principal, submenus, opções, morte, vitória, erros do catálogo,
  debug): `ui_*`. Esc ou B são `ui_voltar` e sobem um nível; numa tela sem nível
  acima, não fazem nada. Start não faz nada.
- **Texto** (um campo de texto em edição: a seed em hex do debug e, no futuro,
  o nome do Iniciado):
  - **Entrada:** o campo entra em edição com um bind de **teclado** de
    `ui_aceitar` sobre ele ou com um clique.
  - **Em edição, o teclado digita:** WASD, 1–3, R, E e Espaço viram texto.
  - **Só Enter e Esc físicos são ações**, fixos e fora do remapeamento (R8). Os
    binds de `ui_aceitar` e `ui_voltar` não valem aqui. Enter confirma e sai da
    edição; Esc sai sem mudar o valor.
  - **Valor recusado** (por exemplo, a seed inválida do RNG R8): Enter não sai
    da edição. O texto fica no campo e aparece a mensagem do RNG.
  - **Mouse:** o hover não move o foco (exceção da R9). Um clique fora do
    campo vale como Esc: sai da edição sem mudar o valor, e o clique não aciona
    o controle clicado, porque conta como "segurado na troca". Um clique dentro
    do campo só move o cursor de texto.
  - Nenhuma ação de jogo nem `pausar` vale.
  - **Gamepad:** no MVP ele não edita texto (só o debug tem campo). Navega até o
    campo e aos controles vizinhos, e A sobre o campo não entra em edição.
- **Ao trocar de contexto:**
  - o buffer esvazia;
  - os botões segurados são **ignorados até serem soltos**. Um Ataque
    segurado ao abrir a tela de bênção nunca "clica" numa carta, e o clique que
    confirma a carta nunca vira golpe ao voltar;
  - um toque feito no mesmo passo da troca conta como "segurado na troca" e é
    ignorado.

**R11. Perda de foco da janela.** Se a janela do jogo perde o foco durante o
Jogo, o jogo **pausa sozinho**, e todos os botões contam como soltos. Durante a
Transição, a pausa abre no primeiro passo de Jogo depois do wipe.

**R12. Valores em dados.** Ficam num `InputTuning` (Conteúdo R1):

- `buffer_passos` (10);
- zona morta interna `zm` (0,2) e externa `ze` (0,05) (F2);
- raio da mira automática (1350 px de mundo = 900 unidades do cânone × 1,5);
- limiar de movimento do mouse para trocar de dispositivo;
- limiares do gatilho analógico: aperta em ≥ 0,5, solta em < 0,4 (histerese).

A validação do catálogo recusa `zm + ze ≥ 1` (erro V2 do Conteúdo; o jogo não
inicia). A ordem de prioridade do buffer é constante desta regra, não dado.

**Sem catálogo.** O `InputTuning` chega por injeção a cada entrada do catálogo
em Pronto (Conteúdo, Edge Cases › Recarga), inclusive depois de uma recarga em
debug. Quando uma recarga começa (o catálogo sai de Pronto), o carregador
retira o `InputTuning` (injeção vazia), e o Input fica só digital até a próxima
entrada em Pronto. Quando a carga termina em Falhou, não há `InputTuning`, e a única tela é
a de erros do catálogo (contexto Menu). Nesse caso o Input lê **só entradas
digitais**: teclas, cliques do mouse, D-pad e botões do gamepad. Analógicos e
gatilhos são ignorados, a mira não existe e o mouse não troca de dispositivo por
movimento (o limiar `L_mouse` também é do catálogo). Assim a tela funciona sem
nenhum número no código, inclusive quando o erro é o próprio `InputTuning`.

**R13. Injeção.** Os sistemas recebem um **provedor de amostras**. Os testes
injetam sequências roteirizadas de amostras, sem dispositivo real.

### States and Transitions

| Estado | Significado | Entra quando | Sai para |
|---|---|---|---|
| Jogo | Ações de jogo ativas; buffer rodando | Uma câmara começa ou a pausa fecha | Bênção, Transição, Passe de morte, Menu, Pausa, Sem foco |
| Bênção | Escolha de bênção (R10); buffer vazio | A tela de bênção abre | Jogo, em `tela_fechada` (não em `escolher`; segurados ignorados até soltar), Pausa |
| Transição | Troca de câmara, durante o wipe (R10); ações de jogo e `pausar` ignoradas; buffer vazio | Pedido de troca de câmara (Combate R1) | Jogo (segurados ignorados até soltar; a Pausa pedida abre no primeiro passo de Jogo) |
| Passe de morte | Estado de apresentação (Run R5, Pipeline): toda entrada é ignorada, inclusive `ui_*`, `ui_aceitar`, Esc e `pausar` (sem pular e sem abrir pausa); buffer vazio | `jogador_morreu` (Combate R13) | Menu, quando a tela final de morte abre |
| Menu | `ui_*` (R10); buffer vazio | Menu principal, Campus em menu, tela final (morte ou vitória), opções | Jogo, Pausa (pelo `ui_voltar` das opções da pausa), Texto |
| Pausa | Mundo parado; `ui_aceitar`, `ui_navegar`, `pausar` | `pausar` em Jogo ou na Bênção; perda de foco em Jogo (R11); gamepad ativo desconectado em Jogo (Edge Cases) | O estado anterior, por `pausar` (mesma regra de soltar); Menu (opções) |
| Texto | Campo em edição; o teclado digita; só Enter e Esc físicos (R10) | Bind de teclado de `ui_aceitar` ou clique num campo de texto | Menu (Enter com valor aceito confirma; Esc ou clique fora do campo cancelam). Enter com valor recusado fica em Texto; o hover não tira o foco |
| Remapeando | Captura a próxima entrada do dispositivo escolhido. Qualquer toque curto é atribuído (sujeito às recusas). Cancela: segurar Esc ou Start por 1 s, botão "Cancelar" na tela, ou 5 s sem entrada | "Remapear" numa ação | Menu (bind salvo ou cancelado) |
| Sem foco | A janela não tem foco; tudo conta como solto | A janela perde o foco | Pausa (se estava em Jogo) ou o estado anterior |

### Interactions with Other Systems

| Sistema | Recebe daqui | Fornece para cá | Dono da interface |
|---|---|---|---|
| Movimento e esquiva | `mover`, `esquiva` (só buffer) | — | este GDD (amostra), Movimento (cancelamentos) |
| Combate núcleo / Armas | `ataque`, `especial`, `mirar`, segurados, buffer | consumo do buffer ("executei X") | idem |
| Selo e Fluxo | `selo` (só buffer), `mirar` | consumo do buffer | idem |
| Cena 3/4 e câmera | `fonte_mira`, `intensidade_mira` (amostra) e consulta de cursor (render), para o lookahead (Cena F2) | conversão tela → mundo do cursor | Cena 3/4 (conversão), este GDD (amostra e consulta) |
| IA / Câmaras e ondas | — | consulta de alvos (inimigo mais próximo, ≤ raio, fora do spawn) | este GDD (pergunta), IA (resposta) |
| Tela de bênção / Menus | `ui_*`, atalhos 1–3, troca de ofertas, contexto Texto | troca de contexto (Jogo, Bênção, Menu, Texto) | este GDD |
| HUD / UI | dispositivo ativo (ícones de comando); consulta `rotulo_acao(acao, dispositivo)` | — | UI |
| Acessibilidade e opções | tela de remapeamento usa a R8; tamanho da mira (Art Bible §7.9 #11) é dela | — | Acessibilidade |
| Save e perfil | binds do usuário (arquivo próprio) | — | este GDD (formato), Save (onde) |
| Conteúdo orientado a dados | — | `InputTuning` | Conteúdo |

**`rotulo_acao(acao, dispositivo)` (assinatura, decidido 2026-11-13).** Entrada: `acao` = id de ação do Input (ex.: `selo`, `interagir`, `ataque`) e `dispositivo` = o dispositivo ativo, `teclado` ou `gamepad`. Saída: o rótulo textual do bind **remapeado do usuário** para essa ação nesse dispositivo, mais o id do glifo (no gamepad, o glifo do botão; no teclado, o rótulo da tecla lógica do layout ativo). `acao` ou `dispositivo` inválido: rótulo vazio e um aviso registrado, sem falha. HUD (R6, R10) e Tela de bênção só consomem; a consulta é a mesma para o glifo do Selo.

**Provisório:** só Acessibilidade e Menus ainda não têm GDD. A
consulta de alvos é um pedido que o GDD de IA vai precisar honrar. A conversão
tela → mundo já está definida na R9/F6 do GDD de Cena 3/4 e câmera.

## Formulas

> Proposta do `systems-designer` (consultado: modo Lean, seção de risco alto).
> Exemplos recalculados em Python em 2026-11-05. Escolhas do hitstop no buffer e
> dos valores novos: usuário, 2026-11-05.

### F1. Movimento do teclado

The keyboard_move formula is defined as:

`v = (direita − esquerda, baixo − cima) ; mover = v / |v| se |v| > 0, senão (0, 0)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| direita, esquerda, baixo, cima | int | 0 ou 1 | calculated | alguma tecla da direção (primária ou secundária) segurada |
| v | vec2 | cada eixo −1 … 1 | calculated | soma bruta |
| mover | vec2 | módulo 0 ou 1 | calculated | saída |

**Output Range:** módulo 0 ou 1. Teclas opostas se anulam e o personagem fica
parado.
**Example:** D + W → v = (1, −1) → mover ≈ (0,7071; −0,7071), com tolerância
1e-6 nos testes.

### F2. Zona morta radial com reescala (analógicos)

The radial_deadzone formula is defined as:

`m = |s| ; m' = clamp((m − zm) / (1 − ze − zm), 0, 1) ; saída = (s / m)·m' se m > 0, senão (0, 0)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| s | vec2 | módulo até ~1,41 | calculated | eixos brutos do analógico |
| zm | float | 0 – 0,5 | data file (`InputTuning`) | zona morta interna, 0,2 (cânone) |
| ze | float | 0 – 0,2 | data file | zona morta externa, 0,05 (novo, placeholder) |
| m' | float | 0 – 1 | calculated | módulo reescalado |

**Output Range:** módulo de 0 a 1, sem salto: é 0 até m = 0,2 e chega a 1 em
m = 0,95. Exige `zm + ze < 1`, conferido ao carregar o `InputTuning`. É radial,
e não por eixo como no cânone, para não "grudar" a direção nos eixos. A mira usa
a mesma fórmula e depois normaliza.
**Example:** s = (0,3; 0,4) → m = 0,5 → m' = 0,3 / 0,75 = 0,4 → saída
(0,24; 0,32). m = 0,25 → 0,0667. m = 0,2 → 0. m = 0,95 ou 1,0 → 1.

### F3. Prazo do buffer

The buffer_deadline formula is defined as:

`P = apertados_neste_passo ∩ {esquiva, especial, ataque, selo} ; se P ≠ ∅: B = B ∪ P, T = buffer_passos ; senão, se T > 0 e o passo não é de hitstop: T = T − 1, e se T = 0: B = ∅`

Consumir X: `B = B − {X}`. A ordem de consumo é **esquiva > especial > ataque >
selo**.

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| B | conjunto | ⊆ {esquiva, especial, ataque, selo} | calculated | botões no buffer |
| T | int | 0 – buffer_passos | calculated | passos restantes (contador único) |
| P | conjunto | idem | calculated | toques novos neste passo |
| buffer_passos | int | 1 – 30 | data file | 10 (cânone) |

**Output Range:**

- Fora do hitstop, um toque fica disponível no passo em que foi feito e nos 9
  seguintes (10 passos ≈ 0,167 s), como no cânone.
- **Passos de hitstop não descontam** (decisão do usuário; desvio deliberado do
  cânone, P3).
- Um toque novo renova o prazo de todos os botões no buffer (contador único,
  cânone).

**Example:**

- Toque no passo 0, sem hitstop: disponível até o passo 9; vazio no passo 10.
- Toque no passo 0 durante um hitstop de 36 passos (0–35): T fica em 10 até o
  passo 35. Ainda disponível no passo 36, o primeiro vivo, e até o passo 44. No
  cânone, já teria expirado no passo 10.

### F4. Mira no gamepad

The gamepad_aim formula is defined as:

`mira = (1) normaliza(F2(analógico direito)) se ≠ 0 ; (2) senão normaliza(e_k − p), com k = o de menor d_i² entre os inimigos fora do spawn com 0 < d_i² ≤ R² ; (3) senão normaliza(mover) se ≠ 0 ; (4) senão direção em que o personagem olha ; (5) se tudo for zero: (0, −1)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| p, e_i | vec2 (px de mundo) | — | calculated | personagem e inimigos, na ordem da consulta de alvos |
| d_i² | float | ≥ 0 | calculated | distância ao quadrado (sem raiz) |
| R | float (px) | > 0 | data file | raio da mira automática, 1350 px (900 unidades do cânone × 1,5), **inclusivo** (desvio deliberado: o cânone usa `<`, R5) |

**Output Range:** sempre um vetor unitário. Em empate exato de distância, vence
o **primeiro** da lista, que deve vir em ordem estável (de spawn), senão a mira
pisca. Um inimigo com d = 0 é ignorado.
**Example:** p = (0, 0); A = (300, 400) e B = (400, 300), ambos com d² =
250.000; C = (0, 1400), com d² = 1.960.000 > 1.822.500, fica fora. Lista
[A, B, C] → A → mira (0,6; 0,8).

### F5. Mouse como dispositivo ativo

The mouse_switch formula is defined as:

`Δ = Σ (sobre os eventos de movimento do passo) √(dx² + dy²) ; mouse_significativo = Δ ≥ L_mouse`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| dx, dy | float (px de **tela**) | — | calculated | deslocamento de cada evento |
| Δ | float (px) | ≥ 0 | calculated | movimento total no passo |
| L_mouse | float (px/passo) | 1 – 20 | data file | 4 (novo, placeholder; ≈ 240 px/s) |

**Output Range:** sim ou não por passo. É medido em px de tela, para que a
câmera andando sob o cursor parado não troque o dispositivo. Se mouse e gamepad
forem significativos no mesmo passo, o dispositivo ativo atual é mantido.
**Example:** eventos (3, 4) e (−1, 0) → Δ = 5 + 1 = 6 ≥ 4 → troca. Tremor
(1, 1) → Δ ≈ 1,41 → não troca.

**Sem quantização:** o cânone arredonda os eixos para 16 níveis (`AXIS_MAX`) só
por causa do replay do servidor. Este jogo não tem replay e usa os valores
contínuos.

## Edge Cases

> `systems-designer` não consultado nesta seção: modo Lean. Os pontos de atenção
> que ele levantou em Formulas estão incorporados.

**Dispositivos**

- **Se o gamepad desconectar durante o Jogo, sendo o dispositivo ativo:** o jogo
  pausa sozinho e mostra "controle desconectado". Ao reconectar, continua na
  pausa até o jogador sair dela.
- **Se o gamepad desconectar e o dispositivo ativo for o teclado, ou se
  desconectar um gamepad que não é o ativo:** nada pausa.
- **Se o gamepad ativo desconectar durante a Bênção ou um Menu:** só aparece a
  mensagem.
- **Se houver dois ou mais gamepads:** vale só o **último gamepad com entrada
  significativa** (R3). Os outros são ignorados até serem usados. O jogo é
  single-player.
- **Se um analógico tiver drift acima da zona morta:** aparece movimento ou mira
  fantasma. Quem corrige é a zona morta ajustável nas opções (Acessibilidade);
  esta camada não tenta detectar drift.
- **Se o cursor sair da janela:** a mira usa a última posição válida do cursor
  dentro da janela, guardada em coordenadas de **tela** e reconvertida para
  mundo a cada passo (a câmera anda e a mira acompanha).
- **Se o cursor estiver exatamente sobre o personagem** (vetor zero): a mira
  mantém a direção do passo anterior.

**Teclas e toques**

- **Se teclas opostas forem seguradas** (A + D): o eixo dá 0 (F1).
- **Se duas teclas da mesma direção (primária e secundária) forem seguradas
  juntas:** contam uma vez, nunca somam.
- **Se um toque começar e terminar entre duas amostras** (menos de 1/60 s):
  conta como **apertado neste passo**. A camada acumula os eventos entre passos,
  então um toque rápido nunca se perde.
- **Se o mesmo botão for apertado duas vezes no mesmo passo:** conta como um
  toque.
- **Se a Esquiva estiver no buffer sem carga disponível:** continua no buffer
  até o prazo acabar. Decidir se executa é do Movimento.

**Contextos, pausa e foco**

- **Se houver pausa** (por `pausar`, perda de foco ou controle desconectado): é
  uma troca de contexto. O buffer esvazia e os segurados são ignorados até serem
  soltos (R10).
- **Se a janela perder o foco na Bênção ou num Menu:** nada pausa, porque a tela já está
  parada. Os botões contam como soltos. **Decisão explícita:** perder o foco na
  Bênção não pausa, mas `pausar` (Esc) na Bênção pausa (tabela de estados:
  Pausa entra por `pausar` em Jogo ou na Bênção).
- **Morte e Vitória (decidido 2026-11-13):** os `ui_*` **não valem durante o passe
  de morte**: o contexto Menu só abre na tela final (de morte ou de vitória). Durante
  o passe a entrada é ignorada: `ui_aceitar` não pula o passe e Esc/`pausar` não abre
  a pausa (coerente com Run R5/R6, que recusam a pausa em Morte). Na tela final o
  Menu vale (`ui_*` ativo, buffer vazio). Botões segurados durante o passe contam como
  soltos ao abrir o Menu, sem acionar nada.
- **Se o alvo da mira automática morrer:** a amostra do passo seguinte escolhe
  de novo (F4). A mira não fica presa a um alvo.
- **Se todos os inimigos estiverem surgindo:** a mira automática passa ao
  critério 3 (movimento).

**Remapeamento**

- **Se o arquivo de binds estiver corrompido ou ilegível:** o jogo usa os
  padrões, avisa uma vez e guarda o arquivo ruim como `.bak`. Nunca sobrescreve
  sem guardar.
- **Se o arquivo tiver um bind de ação que não existe mais:** é ignorado. **Se
  faltar uma ação nova:** ela recebe o padrão.
- **Se alguém tentar atribuir Esc ou Start a outra ação de Jogo, Pausa ou
  Bênção:** é recusado com mensagem, porque tiraria `pausar` do único botão
  garantido (R8). O `ui_voltar` usa Esc por padrão sem conflito, porque só vale
  no Menu, onde `pausar` não vale. No Texto, Esc é a tecla física fixa (R10).
- **Se alguém tentar deixar uma ação de jogo sem nenhum bind num dispositivo:**
  não é possível. "Remover" só remove um secundário, e o primário só pode ser
  trocado.
- **Se alguém tentar acrescentar um 4º bind a uma ação num dispositivo:** é
  recusado com mensagem (`INPUT_RECUSA_TECLA`); é preciso remover um secundário
  antes.
- **Se a entrada capturada for uma tecla reservada pelo sistema**
  (Windows/Meta, Print Screen): é recusada com mensagem.
- **Se a entrada capturada for a roda do mouse:** não é aceita no MVP, porque
  não tem "segurar".
- **Se a entrada capturada for um gatilho analógico** (LT ou RT): vira botão
  que aperta em ≥ 0,5 e solta em < 0,4 (R12).

## Dependencies

**Depende de (upstream)**

| Sistema | Tipo | O que vem de lá | Sem ele |
|---|---|---|---|
| Conteúdo orientado a dados | Suave | `InputTuning` (buffer, zonas mortas, raio, limiar do mouse), re-injetado a cada entrada em Pronto | Com o catálogo em Falhou, só entradas digitais na tela de erros (R12, Sem catálogo) |
| Cena 3/4 e câmera | Forte (para a mira do mouse) | Conversão tela → mundo do cursor (R5; Cena 3/4 R9, F6) | A mira do mouse fica errada sob a projeção 3/4 |
| IA de inimigos e elites (via contrato) | Suave, **por contrato** | Implementa a **consulta de alvos** definida aqui (inimigos fora do spawn, em ordem estável) | A mira do gamepad cai no critério 3 (movimento) |
| Save e perfil | Suave | Onde o arquivo de binds mora | Binds em `user://` próprio até o GDD de Save existir |

**Ciclo resolvido por contrato:** a IA depende do Combate, que depende do
Movimento, que depende do Input. O Input só **define a interface** da consulta
de alvos; a IA a implementa e ela é injetada. Nenhum dos dois chama o outro
diretamente.

**É dependência de (downstream)**

| Sistema | Tipo | O que recebe |
|---|---|---|
| Movimento e esquiva | Forte | `mover`, `esquiva`, buffer |
| Combate núcleo | Forte | `ataque`, `especial`, `mirar`, segurados, buffer |
| Armas das Doutrinas | Forte (via Combate) | Ataque e Especial segurados (R7) |
| Selo e Fluxo | Forte | `selo`, `mirar`, buffer |
| Tela de bênção e componente de carta | Forte | `ui_*`, atalhos 1–3, troca de ofertas, contexto Bênção; consulta `rotulo_acao(acao, dispositivo)` |
| Menus | Forte | `ui_*`, `pausar`, estado Remapeando |
| HUD | Suave | Dispositivo ativo (ícones de comando); consulta `rotulo_acao(acao, dispositivo)` |
| Cena 3/4 e câmera | Suave | `fonte_mira`, `intensidade_mira` e consulta de cursor, para o lookahead (Cena F2). Sem eles, não há lookahead |
| Acessibilidade e opções | Forte | Remapeamento (R8), zona morta ajustável, tamanho da mira |

**Bidirecionalidade:** Movimento, Tela de bênção e Acessibilidade já citam
"Input e controle" no índice. Combate núcleo, Selo e Fluxo e Menus passam a
citá-lo, e o ciclo com a IA entra em "Circular Dependencies" (decisão do
usuário, 2026-11-05). Já existem os GDDs de Movimento, Combate núcleo, Selo e
Fluxo, Armas, IA, Tela de bênção, HUD e Cena 3/4; a conferência de que cada um
lista "Input e controle" em Dependencies é do `/review-all-gdds`. Ainda não
existem Menus e Acessibilidade e opções: ao serem escritos, devem listá-lo.

**Cena 3/4 nos dois sentidos:** o Input usa a conversão tela → mundo da Cena, e a
Cena usa a fonte da mira e a consulta de cursor do Input. O ciclo se resolve por
contrato: cada lado define uma interface só de leitura, e nenhum chama a lógica
do outro. A Cena 3/4 lista o Input em Interactions e em "Depende de" (Suave,
por contrato).

## Visual/Audio Requirements

Não se aplica diretamente. Os ícones de comando são parte da UI (UI
Requirements). Som de navegação de menu é do GDD de Áudio.

## Game Feel

- **Latência:** a entrada é aplicada **no mesmo passo de física** em que é
  amostrada (R2: input antes do jogo). Nenhuma camada a mais de atraso.
- **Mira:** sem suavização nem aceleração no mouse (o cursor é a mira) e sem
  suavização no analógico além da zona morta (F2).
- **Buffer:** a janela de 10 passos (≈ 0,167 s) é a mesma calibrada no cânone
  (baseline §55). O valor fica no `InputTuning`, para afinar no protótipo de
  combate.
- **Segurar:** segurar Ataque ou Especial repete sem exigir um novo toque; a
  cadência é a recarga da arma.

## UI Requirements

- **Ícones de comando:** seguem o **dispositivo ativo** (R3). São genéricos no
  MVP: teclas e botões no layout Xbox (A/B/X/Y), sem ícones por marca. A troca é
  imediata quando o dispositivo muda.
- **Tela de remapeamento:**
  - lista por contexto (Jogo, Telas), com colunas Teclado/mouse e Gamepad,
    primário e até 2 secundários;
  - "Remapear" abre a captura com contagem de 5 s e o botão "Cancelar";
  - "Restaurar padrão" por dispositivo e "Trocar analógicos";
  - as mensagens `INPUT_*` aparecem nesta tela;
  - é toda navegável por teclado e gamepad.
- **Indicador de mira:** é desenhado no mundo; o tamanho segue a opção 11 do Art
  Bible §7.9 (1×, 1,5×, 2×).
- **Aviso "controle desconectado":** aparece na pausa, com o texto da chave
  `INPUT_CONTROLE_DESCONECTADO`.

## Cross-References

| Documento | Seção | Uso neste GDD |
|---|---|---|
| `design/gdd/conteudo-orientado-a-dados.md` | R1, V2, Edge Cases › Recarga em debug, UI Requirements, AC-51 | `InputTuning` e a validação de `zm + ze`; injeção a cada entrada em Pronto e retirada ao sair; tela de erros sem catálogo |
| `design/gdd/rng-com-seed.md` | R7 | A entrada nunca altera sorteios estruturais |
| `design/art/art-bible.md` | §7.9 | Remapeamento completo, menus sem mouse, tamanho da mira |
| `design/art/art-bible.md` | §7.6 | Foco único (o mouse move o mesmo foco), confirmar com Enter/Espaço/E, 1/2/3 só movem o foco, trava contra escolha acidental |
| `design/gdd/cena-3-4-e-camera.md` | R9, F6 | Conversão tela → mundo do cursor |
| `.claude/docs/technical-preferences.md` | Input & Platform | Plataforma, WASD e mira no mouse, telas sem mouse |
| Khaeros `packages/preview/src/arena/input.ts` | `KEY_BINDINGS`, `readGamepad`, `computeAim` | Layout padrão, zona morta 0,2, mira automática 900 unidades (1350 px) |
| Khaeros `packages/action-core/src/engine.ts` | `bufferInput`, `BUFFER_TICKS` | Buffer de 10 passos e ordem de consumo |
| Khaeros `docs/baseline.md` | §55.2 | Buffer, hitstop e cancelamento |
| `docs/engine-reference/godot/modules/input.md` | 4.5–4.7 | SDL3, foco duplo, device IDs do 4.7 |

## Acceptance Criteria

> Proposta do `qa-lead` (consultado: modo Lean, seção de risco alto), ajustada às
> decisões do usuário de 2026-11-05.
>
> Evidência: **[L]** `tests/unit/input/`, com amostras e eventos montados à mão.
> **[I]** `tests/integration/input/`, pelo pipeline real
> (`Input.parse_input_event`) ou por arquivo em `user://`. **[UI]** screenshot
> em `production/qa/evidence/`. **[M]** manual com hardware real, só onde o
> sistema operacional ou o driver não dá para simular.

**Ações e amostragem**

- **AC-01 R1 [L]** Mapa padrão e build de release injetado → o conjunto de
  ações é exatamente o da R1, sem nenhuma `debug_*`. Nenhuma ação passa de 3
  binds por dispositivo (R8); a Esquiva tem Espaço, Shift e L, e `ui_aceitar`
  tem Enter, Espaço e E.
- **AC-02 R2 [L]+[I]** Toda amostra tem os 8 campos, |mover| ≤ 1, |mirar| =
  1 ± 1e-6 e 0 ≤ `intensidade_mira` ≤ 1. Uma varredura confirma que não há
  nenhuma leitura de `Input` ou `InputEvent` fora da pasta da camada de input.
- **AC-03 R13 [L]** 3 amostras roteirizadas, sem dispositivo → o consumidor as
  recebe na ordem.
- **AC-04 R12 [L]** Com `buffer_passos` = 5 e raio = 500: o toque vale nos
  passos 0–4, e um inimigo a 600 px é ignorado.
- **AC-05 R12 [L]** `zm` 0,6 + `ze` 0,5 → erro de validação do catálogo; o jogo
  não inicia.
- **AC-38 R12 [L]** Sem catálogo: **GIVEN** o Input sem `InputTuning` (catálogo
  em Falhou) e amostras roteirizadas **THEN** D-pad, botões, teclas e cliques
  movem o foco e acionam `ui_aceitar`/`ui_voltar` na tela de erros **AND**
  analógico em 1,0 e gatilho em 1,0 não geram nenhuma ação **AND** o mouse
  movido não troca o dispositivo ativo **AND** depois de um `InputTuning` de
  fábrica ser injetado (entrada em Pronto), o analógico volta a valer com a
  zona morta nova.

**Movimento (F1, F2, R3, R4)**

- **AC-06 F1 [L]** D+W → (0,7071; −0,7071) ± 1e-6. A+D → (0, 0). W + seta para
  cima → (0, −1), módulo 1.
- **AC-07 F2 [L]** s = (0,3; 0,4) → (0,24; 0,32). m = 0,25 → 0,0667 ± 1e-4.
  m = 0,2 → 0. m = 0,95 e m = 1,0 → 1. s = 0 → (0, 0).
- **AC-08 R3 [L]** Teclado ≠ 0 e analógico (0,5; 0) → mover = teclado.
  Teclado = 0 → mover = analógico.

**Mira (F4, R5)**

- **AC-09 F4 [L]** p = (0, 0): a lista [A, B, C] → (0,6; 0,8) e a lista
  [B, A, C] → (0,8; 0,6), porque no empate vence o primeiro.
- **AC-10 F4 [L]**
  - Inimigo em (1350, 0) → mira (1, 0), porque o raio é inclusivo.
  - Inimigo em (1350,01; 0) → usa o movimento.
  - d = 0 é ignorado; todos surgindo → movimento.
  - Analógico direito ativo vence o inimigo.
  - Tudo zero → direção do personagem; sem direção → (0, −1).
- **AC-11 [L]** O alvo some da consulta no passo seguinte → a mira vai para o
  próximo mais perto.
- **AC-12 R5 [L]**, com stub da conversão tela → mundo:
  - cursor sobre o personagem → mantém a mira anterior;
  - cursor fora da janela → usa a última posição de tela válida, reconvertida
    no passo atual (a câmera anda e a mira acompanha).
- **AC-37 R2/R5 [L]** Fonte e intensidade da mira:
  - mouse ativo → `fonte_mira` = `mouse`, `intensidade_mira` = 0;
  - analógico direito s = (0,3; 0,4) → `analogico`, `intensidade_mira` = 0,4
    ± 1e-4 (F2);
  - analógico direito na zona morta, com um inimigo no raio → `automatica`, 0;
  - sem inimigo e sem movimento → `automatica`, 0 (critérios 4 e 5);
  - consulta de cursor com o cursor em (960, 540) e depois fora da janela →
    devolve (960, 540) nas duas leituras.

**Dispositivo ativo (F5, R3)**

- **AC-13 F5 [L]**
  - Eventos (3, 4) e (−1, 0) → troca para o mouse.
  - (1, 1) → não troca.
  - Mouse e analógico significativos no mesmo passo → mantém o atual.
  - Câmera anda com o cursor parado → não troca.
- **AC-14 [L]** Gamepads 0 e 1, com o 1 como último significativo → o analógico
  do 0 é ignorado até ser usado.

**Buffer (F3, R6, R7)**

- **AC-15 F3 [L]** Toque no passo 0, **sem outro toque depois**, sem hitstop → `quer(ataque)` verdadeiro
  nos passos 0–9 e falso no 10 (o prazo é o do **último toque**, contador único: F3).
- **AC-16 F3 [L]** Hitstop nos passos 0–35, injetado pela consulta de hitstop:
  - toque no passo 0 → T = 10 no passo 35, disponível de 36 a 44, vazio no 45;
  - toque no passo 20 → mesmo resultado.
- **AC-17 [L]** Ataque no passo 0 e Especial no passo 8 → o toque mais recente renova
  o prazo de **todos** os botões no buffer (contador único, F3): os dois valem até o
  passo 17 e somem no 18 (decisão do usuário, 2026-11-12: prazo compartilhado, como no cânone).
- **AC-18 R6 [L]** Buffer = {selo, ataque, especial, esquiva} (prazo compartilhado:
  consumir um botão não remove os outros nem muda o prazo), consumidores na
  ordem Movimento → Combate → Selo:
  - o Movimento consome a esquiva;
  - o Combate consome o especial e deixa o ataque para o passo seguinte;
  - o Selo roda por último.

  Consumir um nunca remove os outros.
- **AC-19 [L]**
  - Ataque segurado com buffer vazio → `quer` = verdadeiro e o buffer não muda.
  - Esquiva ou Selo segurados por 30 passos, com o buffer vazio depois do
    prazo do toque → `quer` = falso a partir do passo 10 (segurar não repete).
  - `interagir` e `pausar` nunca entram no buffer.
  - Esquiva sem carga fica até o prazo acabar.
- **AC-20 R7 [L]** Ataque segurado por 30 passos → segurado em todos e
  "apertado" só no primeiro.
- **AC-21 [L]+[I]**
  - Aperto e soltura entre dois passos → apertado = verdadeiro e segurado =
    falso.
  - Aperto, soltura e aperto no mesmo intervalo → 1 toque.
  - O [I] repete com `parse_input_event`.

**Contextos, pausa e foco (R10, R11)**

- **AC-22 R10 [L]**
  - Ataque segurado, Jogo → Bênção → buffer vazio e nenhuma carta aceita
    enquanto segura.
  - Soltar e apertar `ui_aceitar` → aceita (com a trava de 500/300 ms da Tela
    de bênção zerada no teste, R9).
  - Bênção → Jogo com o botão ainda segurado → ataque falso até soltar.
  - Um toque no mesmo passo da troca → ignorado.
  - Jogo → Transição com Ataque no buffer → buffer vazio no passo da troca;
    Ataque, Especial, esquiva e `pausar` tocados durante a Transição → nenhuma
    ação; Ataque segurado da Transição até depois do wipe → ataque falso até
    soltar.
- **AC-23 R11 [I]**
  - Notificação de perda de foco em Jogo → Pausa, segurados falsos, buffer
    vazio.
  - Em Menu ou na Bênção → não pausa.
  - Na Transição → a Pausa abre no primeiro passo de Jogo depois do wipe, com
    segurados falsos.
  - **[M]** Alt+Tab real, uma vez por release.
- **AC-24 [I]** Com monitor de dispositivos injetado:
  - o gamepad ativo desconecta → Pausa + `INPUT_CONTROLE_DESCONECTADO`; ao
    reconectar, continua em Pausa;
  - o teclado está ativo → não pausa;
  - um gamepad não ativo desconecta → nada;
  - desconexão durante a Bênção ou um Menu → só a mensagem.
  - **[M]** cabo ou Bluetooth de verdade.

**Remapeamento (R8)**

- **AC-25 R8 [L]**
  - Atribuir o secundário de `ataque` ao `especial` → os dois trocam e sai
    `INPUT_CONFLITO_TROCA`.
  - Uma troca que deixaria uma ação sem primário → recusada.
  - Mesma entrada em contextos diferentes → não troca.
- **AC-26 [L]**
  - Remover Esc de `pausar`, ou atribuir Esc/Start a outra ação de Jogo, Pausa
    ou Bênção → recusado (`INPUT_RECUSA_PAUSA`).
  - Acrescentar F10 em `pausar` → aceito.
- **AC-27 [L]** "Remover" só tira um secundário; o primário de uma ação de jogo
  nunca fica vazio. Acrescentar um 4º bind à Esquiva no teclado → recusado, e os
  3 binds ficam.
- **AC-28 [L]** Evento com posição física W e tecla lógica Z → `mover` para
  cima. **[UI]+[M]** rótulo AZERTY na tela de remapeamento.
- **AC-29 R12 [L]**
  - Windows/Meta, Print Screen e roda do mouse → recusados.
  - RT 0,49 → não; RT 0,50 → apertado.
  - Descendo a 0,45 → continua apertado; a 0,39 → solto.
- **AC-30 [L]** Em Remapeando `selo` no gamepad:
  - B curto → atribuído;
  - Start segurado por 1 s → cancela;
  - 5 s sem entrada → cancela.

  Nos dois cancelamentos, os binds ficam inalterados.
- **AC-31 [I]**
  - Salvar e recarregar → binds iguais.
  - "Restaurar padrão" do gamepad não mexe no teclado.
  - "Trocar analógicos" fica salvo.
- **AC-32 [I]** Em pasta temporária:
  - arquivo de binds com lixo → padrões, `INPUT_BINDS_CORROMPIDOS` uma vez por
    sessão, e `.bak` idêntico byte a byte;
  - ação desconhecida → ignorada;
  - ação faltando → recebe o padrão.

**Telas sem mouse (R9)**

- **AC-33 [I]** Para cada tela do inventário da R9:
  - existe foco inicial;
  - `ui_navegar` alcança todos os controles focáveis;
  - mouse sintético sobre outro controle focável move o foco para ele, e o
    `ui_navegar` seguinte parte desse controle (foco único).
  - Na tela de bênção: 1/2/3 movem o foco para a carta sem confirmar; Enter,
    Espaço, E ou A confirmam a carta em foco; R troca as ofertas; o gamepad
    navega e aceita. Cada confirmação é feita 500 ms depois de a última carta
    assentar (300 ms depois de trocar ofertas), ou com a trava zerada no teste.
- **AC-34 [UI]** Screenshot de cada tela operada só por teclado e só por
  gamepad, com o foco visível.

**Contextos de tela e texto (R1, R10)**

- **AC-35 [L]** Esc e Start por contexto:
  - Jogo: Esc → Pausa; Esc de novo → Jogo. O mesmo com Start.
  - Bênção: Esc → Pausa por cima; fechar a Pausa volta à Bênção com as mesmas
    3 cartas; B não muda nada.
  - Opções abertas da Pausa (Menu): Esc ou B → volta à Pausa; Start não muda
    nada.
  - Uma varredura do mapa padrão não acha nenhuma entrada em duas ações do
    mesmo contexto.
- **AC-36 [L]** Campo de seed do debug (contexto Texto):
  - `ui_aceitar` sobre o campo entra em edição; digitar `A1D3` grava "A1D3" e
    o foco não se move (WASD não navega; 1–3 e R viram texto);
  - Enter confirma e volta ao Menu; Esc sai sem mudar o valor;
  - durante a edição, Esc não abre a Pausa nem volta de tela;
  - digitar `XYZ` e Enter → continua em Texto, com "XYZ" no campo e a mensagem
    do RNG;
  - com `ui_aceitar` e `ui_voltar` remapeados para F1 e F2 no teclado, em
    edição F1 e F2 não fazem nada, e Enter e Esc continuam confirmando e
    cancelando; Espaço e E viram texto;
  - A do gamepad sobre o campo → não entra em edição;
  - em edição, mouse sintético sobre o botão vizinho → o campo continua em
    edição e com o foco;
  - em edição com "A1", clique no botão vizinho → sai da edição, o valor
    anterior fica, e o botão não é acionado.

**Rótulo de ação por dispositivo (OQ 0)**

- **AC-39 [L]** `rotulo_acao(acao, dispositivo)`:
  - com os binds padrão, `ataque` em teclado/mouse devolve o rótulo da tecla ou
    botão do mouse atribuído, e no gamepad o glifo/rótulo do botão atribuído;
  - remapear `ataque` (ex.: de uma tecla para outra) → a consulta seguinte
    devolve o novo bind; o antigo não aparece;
  - teclado AZERTY (tecla lógica Z na posição física de W): o rótulo de `mover`
    para cima mostra a tecla lógica do layout ativo, em coerência com o AC-28;
  - troca de dispositivo ativo (teclado → gamepad) no passo N → a consulta no
    passo N+1 (quadro seguinte) já devolve o rótulo do novo dispositivo;
  - ação inexistente ou dispositivo desconhecido → rótulo vazio e um aviso
    registrado, sem falha nem interrupção da execução;
  - valores (2026-11-13): ação `selo`, dispositivo `teclado`, bind remapeado para
    outra tecla → devolve o rótulo dessa tecla e o id do glifo dela (o rótulo do bind
    padrão não aparece); ação `selo`, dispositivo `gamepad` → devolve o glifo do botão
    atribuído; AZERTY: `mover` para cima devolve a tecla lógica do layout ativo
    (Z, não W); `rotulo_acao("inexistente", teclado)` e `rotulo_acao(selo, "joystick")`
    → rótulo vazio e um aviso, sem falha.
- **AC-40 [L]** Passe de morte (decidido 2026-11-13): **GIVEN** `jogador_morreu` e o
  passe de morte em andamento **WHEN** Esc (`pausar`) e `ui_aceitar` são apertados
  **THEN** nada acontece: o passe não pula, a pausa não abre e nenhum `ui_*` é
  entregue **AND** quando a tela final abre, o contexto Menu vale: `ui_aceitar`
  aciona o botão em foco e Esc/`ui_voltar` seguem as regras do Menu.

Fora do escopo: "a Esquiva sempre responde" (P3) é critério do GDD de
Movimento. Aqui só se garantem o AC-16 e o AC-18. Cobertura: R1–R13 e F1–F5 têm
pelo menos um critério cada. AC-35 e AC-36 entraram na revisão de 2026-11-06.
Na segunda revisão de 2026-11-06 mudaram AC-01, AC-27, AC-33 e AC-36. Na
terceira, mudaram AC-02, AC-22, AC-33 e AC-36, e entrou o AC-37. Na revisão do
cross-review de 2026-11-06 entrou o AC-38.

## Open Questions

| # | Pergunta | Dono | Resolver até |
|---|---|---|---|
| 0 | ~~Assinatura de `rotulo_acao(acao, dispositivo)`~~ **Resolvida (2026-11-13):** assinatura na tabela de Interactions e AC-39 | — | — |
| 1 | API de remapeamento em tempo de execução e formato do arquivo de binds (não estão na referência local) | godot-specialist | ADR, antes da primeira story |
| 2 | Confirmar que `grab_focus()` no `mouse_entered` unifica o foco no 4.6+ (foco do mouse separado) antes de escrever o AC-33 | godot-specialist | Antes da story das telas |
| 3 | Faixa da zona morta ajustável nas opções | accessibility-specialist | GDD de Acessibilidade |
| 4 | Ícones por marca de controle e vibração (fora do MVP) | ux-designer | Depois da fatia vertical |
| 5 | Interface da consulta de alvos (ordem estável, flag de spawn) | ai-programmer | GDD de IA de inimigos |
| 6 | ~~Conversão tela → mundo sob a câmera 3/4~~ **Resolvida:** Cena 3/4 R9 e F6 | technical-artist | — |
| 7 | Consulta "hitstop ativo" | game-designer | GDD de Combate núcleo |
| 8 | O RNG (UI Requirements, campo de seed) diz que o campo é "usável por teclado e gamepad"; aqui o gamepad só navega até ele e não digita (R10 Texto). Alinhar o texto do RNG | game-designer | Próxima revisão do GDD de RNG |
| 9 | ~~`ui_*` durante o passe de morte~~ **Resolvida (2026-11-13):** não valem; o Menu só abre na tela final (Edge Cases, States, AC-40) | — | — |
| 10 | Trava de 500 ms / 300 ms contra escolha acidental (Art Bible §7.6) | ux-designer | GDD da Tela de bênção |
