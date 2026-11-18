# Biblioteca de Padrões de Interação — Khaeros

> **Status**: Approved
> **Author**: ux-designer (agente)
> **Last Updated**: 2026-11-18
> **Version**: 0.1
> **Engine**: Godot 4.7 (pin 4.7.2)
> **UI Framework**: Godot `Control` em `CanvasLayer` UI (layer 100), modelo puro em `RefCounted` + vista fina (ADR-0012)
> **Related Documents**:
> - `design/art/art-bible.md` §7.5 (telas), §7.6 (navegação e foco), §7.9 (acessibilidade)
> - `design/accessibility-requirements.md` — compromissos de acessibilidade
> - `design/gdd/input-e-controle.md` R8–R11, `design/gdd/tela-de-bencao-e-carta.md`, `design/gdd/hud.md`, `design/gdd/save-e-perfil.md`
> - `docs/architecture/adr-0006-input-por-passo.md`, `adr-0012-ui-e-hud.md`, `adr-0013-persistencia-do-mvp.md`
>
> **Template**: Interaction Pattern Library

> **Por que este documento existe.** Cada spec de tela deve poder dizer "usa o padrão
> Grupo de cartas" em vez de reespecificar foco, travas e confirmação. Quando um
> comportamento muda, muda aqui e vale para todas as telas.
>
> **Status dos padrões:** Draft (especificado, não implementado) · Stable
> (implementado e validado em uma tela) · Deprecated.

---

## Overview

Khaeros tem poucas telas no MVP (menu principal, escolha de arma, escolha do pacto,
Tela de bênção, consentimento do pacto, pausa, morte, vitória, opções/remapeamento,
avisos, erros do catálogo, debug), mas todas compartilham uma gramática rígida, já
decidida nos GDDs e ADRs:

1. **Um único foco autoritativo** (`ModeloDeFoco`), igual para mouse, teclado e
   gamepad (Art Bible §7.6; Input R9; ADR-0012 §3).
2. **A UI só recebe `ComandosDeTela`** do provedor de input, amostrados no passo
   (ADR-0006). Nenhuma vista lê `Input`, usa `_gui_input` para ação ou liga `pressed`.
3. **No máximo uma confirmação por tela por passo.**
4. **Toda decisão de tela acontece com o mundo congelado** (estado Bênção ou Menus).
5. **Todo texto é chave de tradução**; todo glifo vem de `rotulo_acao(acao, dispositivo)`.
6. **Animação de UI só por `RelogioDeInterface`** (`t_ui` para; `t_real` não), nunca
   `Timer`, `create_timer` ou `Tween` solto.

### Como usar esta biblioteca

- **Desenhando uma tela:** procure aqui antes de inventar. Cite o padrão pelo nome.
  Se nenhum serve, proponha um novo aqui antes da spec.
- **Implementando:** a seção "Notas de implementação" de cada padrão é o contrato; a
  seção "Acessibilidade" é inegociável.
- **Revisando:** todo elemento interativo cita um padrão daqui ou traz especificação
  completa. "Botão padrão" não é referência válida.
- **Mudando um padrão Stable:** audite os usos ("Used In"), peça aprovação ao
  ux-designer e atualize aqui antes ou junto com o código.

---

## Pattern Catalog

### Pattern Catalog Index

Padrões de controle genéricos do template (Toggle, Slider, Dropdown, Tab Bar, Scroll)
entram quando a tela de opções (GDD nº 33, Vertical Slice) for especificada; ver Gaps.

| Pattern Name | Category | Description | Used In (Screens) | Status |
|-------------|----------|-------------|------------------|--------|
| P1 Foco único | Navigation | Um foco para mouse, teclado e gamepad; via nativa do Godot desligada | Todas as telas | Draft |
| P2 Grupo de cartas | Game-Specific / Input | Fileira de 2–4 cartas com travas, foco inicial no meio e confirmação explícita; modos `bencao`, `arma`, `maldicao` | Tela de bênção, escolha de arma, escolha do pacto | Draft |
| P3 Troca e confirmar no mesmo passo | Input | Resolução determinística quando trocar e aceitar chegam juntos | Tela de bênção | Draft |
| P4 Confirmação dupla | Modal | Ação destrutiva com dois passos e "Cancelar" como padrão | Reset de perfil | Draft |
| P5 Aviso único | Modal / Feedback | Mensagem que aparece uma vez por sessão, fora de Jogo, e exige confirmação | Avisos `PERFIL_*`, `INPUT_*`, `OPCOES_FALHA_GRAVAR` | Draft |
| P6 Confirmação discreta | Feedback | Linha curta que some sozinha e não pede ação | `SEED_COPIADA`, `PERSIST_FALHA_GRAVAR` | Draft |
| P7 Pausa | Navigation / Modal | Menu sobre Jogo ou Bênção, retoma o estado anterior | Pausa | Draft |
| P8 Prompt de botão por dispositivo | Game-Specific | Glifo e texto da ação no dispositivo ativo | HUD (prompt, Selo, Selo da Troca), Tela, pausa, menus | Draft |
| P9 Tela que congela o mundo | Navigation | Abrir e fechar telas de decisão no estado Bênção | Tela de bênção, consentimento do pacto, escolha do chefe | Draft |
| P10 Voltar / Cancelar | Navigation | Comportamento universal de `ui_voltar` | Todas as telas | Draft |
| P11 Item desabilitado com motivo | Input / Feedback | Item visível, focável, que não ativa e diz por quê | Trocar ofertas sem carga, Abandonar na Bênção, Reset em Sem gravação | Draft |
| P12 Captura de remapeamento | Input | Estado Remapeando da tela de opções | Opções/remapeamento | Draft |

---

## Patterns

### Navigation Patterns

---

#### P1 Foco único

**Category**: Navigation
**Status**: Draft
**Used In**: todas as telas
**Fontes**: Art Bible §7.6; Input R9–R11; ADR-0012 §3, §4

**Description**: Toda tela tem um conjunto de alvos focáveis, um foco inicial e
vizinhos explícitos. Mouse, teclado e gamepad movem **o mesmo** foco. O Godot 4.6+
separa o foco do mouse do foco de teclado/gamepad ("foco duplo"); o projeto neutraliza
isso desligando a via nativa e mantendo o foco só no `ModeloDeFoco`, que a vista
espelha com `grab_focus()`.

**Interaction Specification**:

| Situação | Entrada | Resposta |
|-------|-------|----------|
| Tela abre | — | Foco vai ao alvo inicial definido pela tela (carta do meio; "Continuar" na pausa; "Cancelar" em P4). O cursor parado sobre outro alvo **não** rouba o foco. |
| Navegar | `ui_navegar` (setas, A/D, D-pad, analógico esquerdo) | Foco vai ao vizinho explícito. Política de borda por tela: Tela de bênção **não** dá a volta; listas verticais de menu dão a volta. |
| Hover | Mouse se moveu (`mouse_moveu`) e o ponto convertido acerta o **slot de layout** de um alvo | Foco vai a esse alvo. Sem movimento real do mouse, nada muda. |
| Clique | Botão do mouse com posição de janela do aperto | Política por tela: no **Menu**, clique confirma o alvo sob o cursor; na **Tela de bênção** e no **Grupo de cartas**, clique fora do foco só move o foco e o clique no alvo já focado confirma. |
| Aceitar | `ui_aceitar` (Enter, Espaço, E; A/Sul) | Ativa o alvo focado. Máximo 1 por tela por passo. |
| Contexto Texto | `LineEdit` em edição | Edição nativa; hover não move foco; campo só perde foco por Enter, Esc ou clique. |
| Janela perde foco | Notificação da aplicação | Em `JOGO` pede `PAUSA`; em `BENCAO`, `MENU`, `PAUSA` só limpa entradas. |
| Janela recupera foco | Clique de retorno | Barreira de retorno: o toque do mesmo passo é descartado e botões segurados exigem soltar. O clique que reativa a janela nunca aciona nada. |

**Visual**: anel de foco desenhado pela vista (stylebox `focus` do tema vazio, para não
haver dois anéis). Foco é forma (anel + crescimento 106% e subida de 12 px nas cartas),
não só cor.

**Accessibility**: navegação completa sem mouse; foco sempre visível; na Redução de
movimento, o crescimento do foco vira corte seco (continua, é informação); no alto
contraste, anel sólido de 3 px. Espelhar o foco da engine com `grab_focus()` deixa a
base pronta para AccessKit (fora do MVP).

**Implementation Notes**: todo `Control` interativo com `mouse_filter =
MOUSE_FILTER_IGNORE` (auxiliar que percorre a subárvore); eventos das ações nativas
`ui_accept`, `ui_select`, `ui_cancel`, `ui_up/down/left/right`, `ui_focus_next/prev`
esvaziados no `InputMap` (ADR-0012 E2, NOT SOURCEABLE: validar que `LineEdit` continua
editando). Teste de acerto: janela → vista lógica (`GeometriaDeViewport`) → local por
`get_global_transform_with_canvas().affine_inverse()` contra `Rect2(Vector2.ZERO,
size)` do slot de layout, nunca do visual animado com `offset_transform_*`. Nota: o
Input R9 descreve `grab_focus()` em `mouse_entered`; o ADR-0012 substitui isso pelo
hover via `ComandosDeTela` com `mouse_filter` ignorado. **Vale o ADR-0012.**

---

#### P7 Pausa

**Category**: Navigation / Modal
**Status**: Draft
**Used In**: pausa
**Fontes**: ADR-0012 §4, §7, §11; Art Bible §7.5; Run

**Description**: Menu de tinta (≥ 92% de opacidade) com as bênçãos ativas em
miniatura e texto completo, a seed, volumes e itens de sessão. Abre sobre `JOGO` e
sobre `BENCAO`; "Continuar" devolve exatamente o estado guardado.

**Interaction Specification**:

| Situação | Entrada | Resposta |
|-------|-------|----------|
| Abrir em Jogo | `pausar` (Esc, Start) | Estado `PAUSA`; `t_ui` para; foco em "Continuar". |
| Abrir em Bênção | `pausar` | Mesmo menu; "Abandonar run" desabilitado (P11, texto do motivo). |
| Durante o hitstop | `pausar` | **Descartado**, não adiado. (Perda de foco da janela pausa mesmo assim.) |
| Durante a Transição | `pausar` | Guardado e aplicado no 1º passo de Jogo. |
| Continuar | Item "Continuar", `pausar` ou `ui_voltar` | `retomar()` devolve `JOGO` ou `BENCAO`. Voltando à Bênção, a mesma oferta reaparece com trava de 300 ms (P2). |
| Abandonar | Item "Abandonar run" | Confirmação simples (um passo, "Cancelar" padrão) e então `PortaDaRun.abandonar()`. Não é P4: abandonar não apaga progresso, e o pacto feito na run continua valendo. |
| Copiar seed | Item "Copiar seed" | `PortaDaAreaDeTransferencia.copiar()`; P6 com `SEED_COPIADA`. |

**Accessibility**: itens em lista vertical que dá a volta; texto completo das bênçãos
(nada só em ícone); volumes acessíveis na pausa; animação da pausa em `t_real` e, na
Redução de movimento, fade ≤ 300 ms.

**Implementation Notes**: sem `SceneTree.paused`; o congelamento é do orquestrador.
Gravação do perfil pendente pode acontecer no fim de um passo em Pausa (ADR-0013 §7),
nunca em Jogo.

---

#### P9 Tela que congela o mundo

**Category**: Navigation
**Status**: Draft
**Used In**: Tela de bênção, consentimento do pacto (Oferecer o vínculo / Deixá-la ir / Ela voltará), escolha do chefe (Pactuar / Exorcizar)
**Fontes**: ADR-0001 (estado Bênção), ADR-0012 §5, §10; Tela R6–R9

**Description**: Toda decisão tomada durante a run abre no estado `BENCAO`: o mundo,
a apresentação (`t_apres`) e o combate param; só a UI anda em `t_ui`. Não existe
limite de tempo para decidir. Não se cria estado novo para telas novas desse tipo:
reusa-se `BENCAO`.

**Interaction Specification**:

| Fase | O que acontece |
|------|----------------|
| Abrir | Orquestrador entra em `BENCAO`; o roteador troca o contexto para Bênção: **buffer esvaziado** e botões segurados exigem soltar. A oferta chega por evento (`OfertaAberta`), nunca por referência a nó. |
| Decidir | Padrão P2 (cartas) ou lista de botões com P1. Travas de P2 valem também para os botões do consentimento. |
| Confirmar | A porta injetada (`PortaDaBencao`, `PortaDoPacto`) recebe a escolha **no passo do aperto**. Fora de Jogo, o perfil pode gravar neste passo (ponto seguro). |
| Fechar | A vista anima a saída e emite `tela_fechada`; só então a porta recebe `notificar_tela_fechada()` e o jogo volta a `JOGO`. Botões segurados continuam ignorados até soltar: o clique que confirma nunca vira golpe. |
| Pausar dentro | P7; ao voltar, trava de 300 ms. |

**Accessibility**: congelamento total elimina pressão de tempo nas decisões (requisito
cognitivo); travas evitam confirmação acidental por quem pressiona de forma
involuntária; entrada da tela vira fade ≤ 300 ms na Redução de movimento.

**When to Use**: qualquer escolha durante a run. **When NOT to Use**: escolhas fora da
run (arma, dupla do pacto, menus), que já estão no estado de Menus.

---

#### P10 Voltar / Cancelar

**Category**: Navigation
**Status**: Draft
**Used In**: todas as telas

| Tela | `ui_voltar` (Esc, B/Leste) |
|------|----------------------------|
| Submenu de opções | Volta ao menu anterior; opções já aplicadas ficam. |
| Pausa | = Continuar. |
| P4 / P5 | = Cancelar (ou "OK" quando o aviso só informa). |
| Tela de bênção / consentimento | **Sem efeito** (não há pular; Bênçãos R5). Esc abre a pausa via `pausar`. |
| Escolha de arma / pacto | Volta ao menu principal; na escolha da reserva do pacto, volta à escolha do campo. |
| Captura de remapeamento | Ver P12. |
| Contexto Texto | Esc fixo encerra a edição. |

---

### Input Patterns

---

#### P2 Grupo de cartas

**Category**: Game-Specific / Input
**Status**: Draft
**Used In**: Tela de bênção (`bencao`), escolha de arma (`arma`), escolha do pacto (`maldicao`)
**Fontes**: Tela de bênção R6–R9, R14, R15b-P; ADR-0012 §5, §10, §11

**Description**: Fileira horizontal de cartas (`CartaView`, alimentada por
`DadosDaCarta`, nunca por `BoonDef`). Máquina `GrupoDeCartas` com 8 estados:
Fechada → Entrando → Travada → Livre ⇄ Trocando → Confirmando → Saindo, mais Pausada.

**Interaction Specification**:

| Estado | Visual | Entrada | Resposta | Duração |
|-------|--------|-------|----------|----------|
| Entrando | Cartas assentam em sequência | Navegar move foco; aceitar ignorado | — | Animação de entrada (fade ≤ 300 ms na Redução de movimento) |
| Travada | Foco visível na carta inicial do modo (`bencao`: carta do meio `floor((n-1)/2)`; `arma`: carta de `ultima_arma` com fallback na 1ª carta `lamina`, Armas R4; `maldicao`: 1ª espécie ou Confirmar se `ultima_dupla` válida) | Navegar e 1/2/3 movem foco; aceitar ignorado | — | 500 ms após a última carta assentar; 300 ms após trocar ou voltar da pausa (borda de subida depois de `t_abrir`) |
| Livre | Carta focada a 106%, +12 px | Navegar, 1/2/3 (só movem foco), clique em carta não focada (só move foco), aceitar ou clique na focada (confirma), trocar (modo `bencao`) | Ver P3 para trocar + aceitar | — |
| Trocando | Cartas saem e entram | Aceitar ignorado | Nova oferta, foco volta ao meio, trava de 300 ms | Animação de troca |
| Confirmando | Carta escolhida destacada; nas bênçãos, rachadura e `preco_revelado` | — | Porta recebe `escolher(i)` no passo do aperto | — |
| Saindo | Cartas saem | — | `tela_fechada` | — |

**Por modo**:

| Modo | n | Trocar | Preço | Particularidade |
|------|---|--------|-------|-----------------|
| `bencao` | 2–4 | Sim, com cargas ("↻ Trocar ofertas", nº de cargas; sem carga = P11) | Sim, `preco_revelado` | Escala `s = min(escala_ui, 1824 / largura(n))` |
| `arma` | 3 (Lâmina, Ressonância, Besta do Vínculo) | Não | Não | Foco inicial na carta de `ultima_arma` (fallback: 1ª carta `lamina`, índice 0); `aviso_texto` na Besta sem Maldição pactuada; `tela_fechada` emitido |
| `maldicao` | espécies pactuadas | Não | Não | **Duas escolhas em ordem**: campo, depois reserva; a carta já escolhida para o campo fica indisponível (P11) na 2ª; `ultima_dupla` pré-selecionada; `aviso_texto` para Maldição sem confiança |

**Accessibility**: raridade por ornamento + palavra (alto contraste: contagem de
linhas); texto completo na carta; 1/2/3 nunca confirmam (evita escolha acidental por
tecla vizinha); travas; foco é forma; "Reduzir flashes" tira o flash do traço dourado
e da rachadura; nenhum limite de tempo.

**Implementation Notes**: `abrir(cartas, trocas, t, modo)`; `processar(cmd, alvo, t)`
testa `trocar` antes de `aceitar` (P3). Crescimento do foco por `offset_transform_*`
(cartas dentro de `HBoxContainer`); acerto no slot de layout (P1). Sem `Timer`.

---

#### P3 Troca e confirmar no mesmo passo

**Category**: Input
**Status**: Draft
**Used In**: Tela de bênção
**Fontes**: Tela R8; Bênçãos R5; ADR-0012 §11 (TR-bencaos-005, TR-tela-bencao-006)

**Description**: Como a entrada é amostrada por passo, `trocar` e `aceitar` podem
chegar no mesmo passo. A regra é determinística e testável em unidade:

| Caso no mesmo passo | Resultado |
|---------------------|-----------|
| `trocar` + `aceitar`, **com cargas** | **A troca vence**: chama `trocar()`, descarta o aceitar. |
| `trocar` + `aceitar`, **sem cargas** | A troca não existe: comando ignorado; o aceitar vale. |
| Dois `aceitar` | Vale o do foco atual (um só). |
| `trocar` sozinho, sem cargas | Ignorado; o botão desabilitado (P11) dá o motivo. |

**Por que a troca vence**: trocar é reversível em efeito (nova oferta, nada perdido
além da carga), confirmar não é. Diante de ambiguidade, o sistema escolhe a ação
menos irreversível. Não existe "pular".

---

#### P11 Item desabilitado com motivo

**Category**: Input / Feedback
**Status**: Draft
**Used In**: "Trocar ofertas" sem carga; "Abandonar run" na Bênção; reset em Sem gravação; carta já usada como campo no modo `maldicao`

**Description**: O item continua visível e **focável** (o jogador descobre por que não
pode), mas aceitar não faz nada além de um som de recusa de UI. O estado é marcado
por **forma e texto** (ícone riscado, "0", ou linha de motivo), nunca só por
esmaecimento ou cor.

**Accessibility**: motivo legível em texto (chave de tradução); contraste do texto do
motivo ≥ 4,5:1 mesmo no estado desabilitado.

---

#### P12 Captura de remapeamento

**Category**: Input
**Status**: Draft
**Used In**: opções/remapeamento
**Fontes**: Input R8, tabela de estados (Remapeando)

| Situação | Resposta |
|----------|----------|
| "Remapear" numa ação | Estado Remapeando: captura o próximo toque curto do dispositivo escolhido; animação em `t_real`. |
| Toque válido | Atribui; se conflitar com ação do mesmo contexto, as duas trocam de lugar e P5 `INPUT_CONFLITO_TROCA`; se alguma ficasse sem primário, recusa com mensagem. |
| Esc/Start em `pausar` | Não removíveis (`INPUT_RECUSA_PAUSA`). |
| Cancelar | Botão "Cancelar" na tela, **ou** 5 s sem entrada, **ou** segurar Esc/Start por 1 s. As duas primeiras não exigem segurar. |

---

### Modal and Feedback Patterns

---

#### P4 Confirmação dupla

**Category**: Modal
**Status**: Draft
**Used In**: reset de perfil (`PERFIL_RESET_CONFIRMAR`)
**Fontes**: ADR-0013 §7; ADR-0012 §10

**Description**: Para ações destrutivas e irreversíveis do ponto de vista do jogador.
Só o reset de perfil usa no MVP (só no menu principal, fora de run).

**Interaction Specification**:

| Passo | Conteúdo | Foco inicial | Entrada | Resposta |
|-------|----------|--------------|---------|----------|
| 1 | O que será apagado (pactos e vínculo) e o que **não** será (opções, binds, preferências, telemetria) | **Cancelar** | Aceitar em "Continuar" | Vai ao passo 2 |
| 2 | Pergunta final, botão com o verbo ("Apagar perfil") | **Cancelar** | Aceitar em "Apagar perfil" | Backup `perfil.cfg.reset.bak`, perfil novo; se a cópia falhar, reset cancelado e P5 |
| Qualquer | — | — | `ui_voltar` | Cancela tudo |

**Regras**: o passo 2 aplica a mesma trava de 300 ms de P2 antes de aceitar (evita
que um aceitar repetido atravesse os dois passos). Indisponível em
Sem gravação (P11 com motivo).

**When NOT to Use**: abandonar a run (confirmação simples, P7); trocar opções.

---

#### P5 Aviso único

**Category**: Modal / Feedback
**Status**: Draft
**Used In**: `PERFIL_CORROMPIDO`, `PERFIL_VERSAO_FUTURA`, `PERFIL_SAIR_SEM_SALVAR`, `INPUT_BINDS_CORROMPIDOS`, `INPUT_CONTROLE_DESCONECTADO`, `INPUT_CONFLITO_TROCA`, `INPUT_RECUSA_TECLA`, `INPUT_RECUSA_PAUSA`, `INPUT_ACAO_NOVA`, `OPCOES_FALHA_GRAVAR`
**Fontes**: ADR-0012 §8, §10; Input R8; ADR-0013 §7

**Description**: Modal pequeno, navegável por P1, que **exige confirmação** e não some
sozinho.

**Regras**:
- **Frequência:** cada chave aparece **uma vez por sessão**. Exceção: `OPCOES_FALHA_GRAVAR` aparece uma vez **por tentativa** de gravar; `PERFIL_SAIR_SEM_SALVAR` a cada tentativa de sair que falhar.
- **Onde:** avisos `PERFIL_*` só **fora de Jogo** (menu principal ou próxima tela fora de Jogo), nunca sobre o combate. Avisos `INPUT_*` de remapeamento aparecem na tela de remapeamento. `INPUT_ACAO_NOVA` (ação nova sem bind no arquivo do usuário) aparece uma vez por sessão **na tela de remapeamento**, quando o jogador abre a tela.
- **Fila:** entram na fila de avisos do `Main`; um por vez, na ordem de chegada.
- **Botões:** um ("OK") quando só informa; dois quando há escolha (`PERFIL_SAIR_SEM_SALVAR`: "Tentar de novo" / "Sair sem salvar", uma tentativa por clique). Foco inicial no botão não destrutivo; `ui_voltar` = Cancelar/OK.
- **Texto:** chave `PERFIL_*`/`INPUT_*`/`OPCOES_*`, nunca literal em `.gd`.

**Accessibility**: sem auto-dismiss; texto ≥ tamanho de corpo; alcançável sem mouse.

---

#### P6 Confirmação discreta

**Category**: Feedback
**Status**: Draft
**Used In**: `SEED_COPIADA`, `PERSIST_FALHA_GRAVAR`

Linha curta, sem foco, que não pede ação e some sozinha após **3 s** em `t_real`
(proposta). Não bloqueia entrada. Se a informação pedir ação, use P5.

---

#### P8 Prompt de botão por dispositivo

**Category**: Game-Specific
**Status**: Draft
**Used In**: prompt de interação (porta), Selo, Selo da Troca (Bloco do Pacto), Tela de bênção ("Trocar ofertas", confirmar), pausa, menus, avisos
**Fontes**: Input "dispositivo ativo", F5; ADR-0012 §9; AC-HD-18

**Description**: Todo prompt mostra o glifo e o texto que vêm de
`rotulo_acao(acao, dispositivo)` → `{texto, glifo}`. O dispositivo ativo é o último
com entrada significativa (tecla, botão, analógico fora da zona morta, mouse acima de
`L_mouse`); se dois forem significativos no mesmo passo, mantém o atual.

**Regras**:
- Troca de glifo no **passo seguinte** à mudança de dispositivo; nada pisca no meio de um passo.
- Remapeamento atualiza o glifo na hora (o rótulo vem do bind atual, com o rótulo do layout do usuário para tecla física).
- Ação com vários binds mostra só o **primário**.
- Ação sem bind mostra o texto da ação com um glifo de "sem tecla" (proposta) e nunca some.
- O prompt de mundo segue a posição interpolada (`mundo_para_vista`) na camada UI, fora da gravura e da vinheta.

**Accessibility**: glifos com texto legível; escala com a UI; alto contraste aplica
moldura sólida.

---

## Animation Standards

- Relógio: `t_ui` (HUD, Tela, travas; para na pausa) ou `t_real` (pausa, captura de remapeamento).
- **Redução de movimento**: toda entrada/saída vira fade ≤ 300 ms ou corte seco; foco vira corte seco mantendo 106%; travas e foco não mudam.
- **Reduzir flashes**: flashes de UI passam pelo limitador do Pipeline (3/s sempre).
- Nenhuma animação bloqueia entrada além das travas documentadas em P2.

## Sound Standards

- Sons de UI saem **só** por eventos de áudio (`FilaDeSonsDeInterface`, ADR-0016), barramento Interface; nunca `AudioStreamPlayer` direto na vista.
- Categorias mínimas: mover foco, confirmar, recusar (P11), abrir/fechar modal.
- Nenhum som de UI é o único sinal de nada (ver `design/accessibility-requirements.md`).

---

## Gaps & Patterns Needed

| Gap | Quando | Dono |
|-----|--------|------|
| Toggle, Slider, Dropdown e Tab Bar da tela de opções | GDD nº 33 (Vertical Slice) | ux-designer |
| Campo de texto com teclado na tela para gamepad (Ficha de matrícula, Art Bible §7.5) | Rito de Iniciação (Vertical Slice) | ux-designer |
| Grade de foco fixo da Oficina de Reforja | Vertical Slice | ux-designer |
| Caixa de diálogo com legenda e falante (Mestres, Campus) | Vertical Slice | ux-designer + narrative |
| Tela de aviso de fotossensibilidade da 1ª execução (usa P5 com atalho) | Antes do 1º playtest externo | ux-designer |
| ~~Specs de tela em `design/ux/` ainda não existem~~ **Resolvida (2026-11-18):** todas as 7 specs de tela/fluxo do MVP em `design/ux/` estão completas e aprovadas | — | ux-designer |

## Open Questions

| Pergunta | Dono | Estado |
|----------|------|--------|
| Duração de P6 (3 s proposto) | ux-designer + usuário | Aberta |
| Glifo de "sem tecla" para ação sem bind | art-director | Aberta |
| Input R9 (`grab_focus` em `mouse_entered`) diverge do ADR-0012 (hover via `ComandosDeTela`): atualizar o GDD | game-designer / ux | Aberta; vale o ADR |

---

## Decisões tomadas pelo agente (a revisar)

1. **P1: vale o ADR-0012 sobre o Input R9** no hover do mouse (via `ComandosDeTela`, não `mouse_entered`); listas de menu dão a volta, a Tela de bênção não.
2. **P2 modo `maldicao`:** a carta escolhida para o campo fica desabilitada (P11) na escolha da reserva; `ui_voltar` na reserva volta ao campo.
3. **P3:** justificativa "a ação menos irreversível vence" registrada para a regra já decidida.
4. **P4:** foco inicial em "Cancelar" nos dois passos e trava de 300 ms no 2º passo para impedir que aceitar repetido atravesse os dois.
5. **P5:** `INPUT_ACAO_NOVA` confirmado como aviso único na tela de remapeamento (o Input marcava "[a confirmar]"); `OPCOES_FALHA_GRAVAR` por tentativa.
6. **P6:** confirmações discretas somem em 3 s (`t_real`).
7. **P7:** abandonar a run usa confirmação simples, não dupla; `ui_voltar` e `pausar` também continuam.
8. **P8:** só o bind primário aparece; ação sem bind mostra glifo de "sem tecla".
9. **P10:** `ui_voltar` não faz nada na Tela de bênção e no consentimento (sem pular).
10. Padrões genéricos de opções ficam para o GDD nº 33.
