# ADR-0012 — UI e HUD

## Status

Accepted · 2026-11-16 (aprovado pelo usuário; Proposed em 2026-11-15)

## Date

2026-11-15

## Last Verified

2026-11-17 (experimentos EX-0012 E1–E6, CB e EX-0001-foco: `offset_transform_visual_only = true`, esvaziamento de `ui_*` preservando `ui_text_*`, barreira de retorno após `APPLICATION_FOCUS_IN`, `focus_behavior_recursive`/`mouse_behavior_recursive`, CSV plural/contexto com `0` singular em `pt_BR` e `DisplayServer.clipboard_set/get` verificados). Antes: 2026-11-16 (emenda Pactos e pendências: Bloco do Pacto, consentimento, escolha das Maldições, chaves de perfil, arestas com ADR-0009 e ADR-0011; contra `hud.md` R15–R19, `tela-de-bencao-e-carta.md`, `vinculo-e-pactos.md` V9 e `save-e-perfil.md` UI Requirements). 2026-11-15. Conferido contra os GDDs de HUD, Tela de bênção e carta, Input e controle (R3, R9–R11, AC-33–40) e Run e regiões (R6), contra os ADRs 0001, 0002, 0006, 0007 e 0013 e contra `docs/engine-reference/godot/` (VERSION, breaking-changes, deprecated-apis, current-best-practices, `modules/ui.md` e `modules/input.md`).

## Decision Makers

Proposta da aba de Arquitetura (ui-programmer), sem revisão independente. O aceite depende do usuário. Os pontos que mudam regra ou sensação de jogo ficam em "Decisões pendentes do usuário". Nenhum GDD foi alterado.

## Summary

Toda a interface (HUD, Tela de bênção, pausa, menus e telas finais) usa nós `Control` no `CanvasLayer` UI (layer 100) do ADR-0007. Cada tela é um modelo puro em `RefCounted` com uma vista fina em `Control`. O HUD só lê: os eventos do passo disparam as animações, e os valores mostrados vêm sempre de consultas. Há um único foco autoritativo, o `ModeloDeFoco`, movido pelos comandos de tela do Input (ADR-0006). O foco de teclado da engine apenas espelha esse modelo, e a ativação nativa dos `Control` fica desligada, o que neutraliza o foco duplo do 4.6 e impede confirmações duplicadas. A escala de UI (85–150%) é aplicada em raízes de grupo ancoradas, com a margem de 48 px fora da escala. Sinais do Godot existem só aqui (`preco_revelado`, `tela_fechada`). A Tela chama a Bênçãos por uma interface injetada.

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Godot 4.7, pin 4.7.2 |
| **Domain** | UI / Input / Localização |
| **Layer** | Presentation |
| **Knowledge Risk** | ALTO: foco duplo (4.6), `Control.offset_transform_*` (4.7), AccessKit (4.5), plurais em CSV (4.6) |
| **References Consulted** | `VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` (UI 4.6, UI e Input 4.7, Acessibilidade 4.5), `modules/ui.md`, `modules/input.md` |
| **Post-Cutoff APIs Used** | Foco duplo (4.6): `grab_focus()` mexe só no foco de teclado/gamepad. `Control.offset_transform_enabled`, `offset_transform_position`, `offset_transform_scale` e `offset_transform_visual_only` (4.7, padrão `true`): transformação visual que os containers não resetam. Eventos de mouse e teclado identificados pela classe, não por `device == 0` (4.7). `Control.focus_behavior_recursive` e `mouse_behavior_recursive` (4.5). `Control.accessibility_live` tipado como `AccessibilityServer.AccessibilityLiveMode` (4.7, só se for usado) |
| **Verification Required** | Todos os itens **Verificados (EX-0012, 2026-11-16)** (ver "Verificação de engine (2026-11-16)"): (E1) **Verificado** — com `offset_transform_visual_only = true` (padrão no 4.7.2), `offset_transform_*` afeta apenas o desenho e mantém `get_global_rect()`, `get_global_transform_with_canvas()` e acerto no slot de layout; o anel de foco deve usar o slot + offset conhecidos, não `get_global_transform_with_canvas()`; (E2) **Verificado** — esvaziar `ui_accept`, `ui_select`, `ui_cancel`, `ui_up/down/left/right` e `ui_focus_next/prev` preserva intactas as 50 ações `ui_text_*` (incluindo `ui_text_submit`) e a edição em `LineEdit`, desligando `Tab` nativo; (E3) **Verificado** (`EX-0012-E3` / `ex-0001-foco-e-apresentacao.md`) — o clique que devolve o foco chega como `InputEventMouseButton` (~46 ms) **depois** de `NOTIFICATION_APPLICATION_FOCUS_IN`, confirmando que a barreira de retorno após `APPLICATION_FOCUS_IN` é obrigatória; (E4) **Verificado** — propriedades `focus_behavior_recursive` (`Control.FocusBehaviorRecursive`) e `mouse_behavior_recursive` (`Control.MouseBehaviorRecursive`, `*_BEHAVIOR_DISABLED` = 1); (E5) **Verificado (nomes)** — propriedades `accessibility_name`, `accessibility_description`, `accessibility_live`, `accessibility_controls_nodes`, `accessibility_described_by_nodes`, `accessibility_labeled_by_nodes`, `accessibility_flow_to_nodes` listadas no 4.7.2 (AccessKit mantido fora do MVP); (E6) **Verificado** — CSV com colunas `?context` e `?plural` (linhas de continuação com `keys` vazio) e regra CLDR de `pt_BR` tratando `0` como singular (`"0 item"`); (CB) **Verificado** — `DisplayServer.clipboard_set/get` confirmado em janela e `.pck` |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | [ADR-0001](adr-0001-orquestrador-do-passo.md): estado de jogo, `pedir_estado`, final comum, `hitstop_ativo()`. [ADR-0002](adr-0002-canal-de-eventos.md): lista de eventos entregue à Apresentação, sinais só em nós de Apresentação. [ADR-0004](adr-0004-catalogo-de-dados.md): `HudTuning` e `TelaBencaoTuning` (HU1–HU14, TB1–TB10). [ADR-0006](adr-0006-input-por-passo.md): comandos de tela, barreira de contexto, `rotulo_acao`. [ADR-0007](adr-0007-cena-viewport-e-camera.md): `CanvasLayer` UI 100 e Pós 50, `GeometriaDeViewport`, conversão janela → vista lógica. [ADR-0013](adr-0013-persistencia-do-mvp.md): opções em `user://opcoes.cfg` por repositório injetado; avisos e reset do perfil (`user://perfil.cfg`). [ADR-0009](adr-0009-atributos-e-modificadores.md): `fontes_de` (a tela de escolha das Maldições e o Bloco do Pacto leem atributos e Vida do portador da Maldição pela consulta de modificadores, sem recalcular). [ADR-0011](adr-0011-pipeline-visual.md): shader de material `ui`, `sem_grading` e a vinheta de Vida baixa na camada Pós. [ADR-0017](adr-0017-aliados-e-invocacoes.md): `estado_pacto()` e `troca_*` das Maldições. O ADR do Ciclo da Run **não** é dependência (ver Enables): este ADR declara as portas (fase da run, consentimento) que a UI lê, e a composição da run as liga |
| **Enables** | ADR-0015 (compõe a UI e liga as portas declaradas aqui), stories de HUD, Tela de bênção, pausa e abandono, menus, telas finais e opções |
| **Blocks** | ADR-0015 (compõe a UI e liga as portas declaradas aqui; aresta de mão única 0012 → 0015, porque este ADR não depende do 0015, ver Depends On) e ADR-0016 (`FilaDeSonsDeInterface`). E1–E6 e CB verificados em 2026-11-16 (`EX-0012`) |
| **Ordering Note** | Alinha com o ADR-0011 o desenho da vinheta na camada Pós e `modo_bencao`. Pede ao ADR-0001 o retorno da pausa para `BENCAO` e ao ADR-0002 um 4º consumidor na entrega (veja Consequences) |

## Context

Os GDDs pedem um HUD mínimo, que só lê e atualiza em até 1 passo, que se recria na Transição lendo o estado por consulta (HUD R1, R14, AC-HD-31) e que tem visibilidade por estado (R12). Pedem uma Tela de bênção modal com 8 estados, travas de 500/300 ms em tempo de interface, foco inicial na carta do meio, clique que só confirma a carta já em foco e os sinais `preco_revelado` e `tela_fechada` (Tela R6–R9). Pedem um modelo de foco único para mouse, teclado e gamepad (Input R9), apesar de o Godot 4.6 separar o foco do mouse do foco de teclado. O ADR-0006 deixou para este ADR o bloqueio da via nativa da UI, para que `pressed` e o comando amostrado não confirmem duas vezes. A fatia atual (`src/presentation/game_hud.gd`) desenha tudo num `Node2D` com `_draw`, retângulos fixos, textos em português no código e foco em `app.selected`. Não tem escala, localização, testes nem interface de leitura.

## Decision

**1. `Control` em `CanvasLayer`, com elementos de mundo projetados.** Os elementos de tela (grupo inferior esquerdo, Fragmentos, barra de chefe, telas) são `Control` sob o `CanvasLayer` UI (layer 100), em coordenadas da vista lógica W × 1080 do ADR-0007. Ancoram nas bordas do viewport, e a Tela de bênção ancora no centro do quadro de 1920 × 1080. O fio de Vida e o prompt de interação também ficam na camada UI, numa subárvore `Mundo`, posicionados a cada quadro por `compositor.mundo_para_vista(X)`, que usa as mesmas posições interpoladas do render. Assim escapam da gravura, da LUT e da vinheta do Pós. Essa posição de camada está em "Decisões pendentes". A vinheta de Vida baixa é calculada pelo HUD (F3, histerese, opção 6) e publicada como valor. Quem a desenha no Pós (layer 50) é o Pipeline (ADR-0011), porque o módulo de camadas é o único escritor de camadas.

**2. HUD como consumidor que só lê.** O `ModeloDoHud` (RefCounted) recebe, por injeção, um `LeituraDoHud` (`@abstract`, só com consultas), o `HudTuning`, o `RelogioDeInterface` e o `player_id`. Em cada entrega do passo, ele (a) lê os eventos para disparar animações (rachar, pisca do entalhe, tremor dos chevrons, "+N") e (b) **sempre** consulta de novo os valores: Vida, Fluxo, cargas, saldo, inimigos, porta interagível. Nenhum número vem só do payload de um evento. Um evento perdido pode atrasar uma animação, mas não deixa o valor errado. Na criação e na recriação, o modelo lê tudo por consulta (R14). A `VistaDoHud` (Control) só aplica o estado visual e tem flags de "sujo" por elemento. Com o preço de uma bênção, o rachar da Vida espera `preco_revelado`, e o rachar por dano espera `hitstop_ativo() == false`. Fios e prompt voltam em `tela_fechada`. O relógio do HUD é `t_ui` (decisão 6).

**3. Foco autoritativo único e via nativa desligada.** O `ModeloDeFoco` (RefCounted) guarda o índice focado de cada tela, os vizinhos explícitos, a política de borda (a Tela não dá a volta) e o foco inicial. Ele é movido **só** pelos `ComandosDeTela` que o provedor do ADR-0006 produz no passo: navegar, aceitar, voltar, carta 1–3, trocar, `pausar`, cursor com `mouse_moveu` e clique com a posição de janela do aperto. A vista espelha o foco com `grab_focus()`, para manter o foco de teclado da engine coerente (base para AccessKit no futuro). O anel de foco é desenhado pela própria vista, e o stylebox `focus` do tema fica vazio, para não haver dois anéis. Todos os `Control` interativos usam `mouse_filter = MOUSE_FILTER_IGNORE`, aplicado por um auxiliar que percorre a subárvore. Os eventos das ações nativas de navegação e confirmação são esvaziados do `InputMap` (E2). Com isso, nem o hover nem o clique da engine focam ou ativam nada, e o foco do mouse do 4.6 nunca se separa do nosso. O hover só move o foco quando `mouse_moveu` é verdadeiro e o cursor convertido acerta um alvo, o que atende "mouse parado ao abrir não rouba o foco". O teste de acerto converte o ponto de janela para a vista lógica (`GeometriaDeViewport`) e depois para o espaço local por `get_global_transform_with_canvas().affine_inverse()`, contra `Rect2(Vector2.ZERO, size)` de um **slot de layout**. O slot é um `Control` sem animação, separado do visual. A política de clique é por tela. No Menu, o clique confirma o alvo (Input R9). Na Tela de bênção, o clique fora de foco só move o foco (Tela R6). Cada tela aceita no máximo uma confirmação por passo. No contexto Texto, o `LineEdit` edita de forma nativa, e o roteador bloqueia os vizinhos (ADR-0006 §5).

**4. Perda de foco e clique que devolve o foco.** O `AdaptadorDeEntradaGodot` recebe as notificações de foco da aplicação. Com o foco perdido em `JOGO`, inclusive durante o hitstop, o `Main` chama `pedir_estado(PAUSA)`. Em `BENCAO`, `MENU` e `PAUSA`, só limpa as entradas (Input R11, Edge Cases, AC-TB-34). Durante a Transição, guarda o pedido para o primeiro passo de Jogo (ADR-0006). Ao recuperar o foco, o adaptador aplica a **barreira de retorno**: uma troca de contexto do contexto Sem foco para o anterior. A troca descarta toques do mesmo passo e exige soltar os botões segurados, então o clique que reativa a janela nunca aciona "Continuar" nem "Abandonar run" (E3). O `pausar` apertado durante o hitstop é descartado, sem adiar, porque a Run diz que o menu não abre nesse caso.

**5. Tela de bênção, carta e sinais.** O `GrupoDeCartas` (RefCounted) é a máquina de 8 estados do GDD (Fechada, Entrando, Travada, Livre, Trocando, Confirmando, Saindo, Pausada), com F1–F5, travas por borda de subida depois de `t_abrir` e relógio injetado. A oferta chega como os eventos `OfertaAberta` e `OfertaTrocada` da lista: o módulo de regra nunca referencia um nó. A Tela responde por `PortaDaBencao` (`@abstract`, injetada): `escolher(i)` no passo do aperto, `trocar()` e `notificar_tela_fechada()`. A Bênçãos segura `bencao_escolhida` até receber `notificar_tela_fechada()` e só então pede `JOGO` (ADR-0001). A `VistaDaTela` emite os sinais Godot `preco_revelado` e `tela_fechada`, ligados pelo `Main` ao HUD e ao Feedback/Áudio. Ao abrir, entre a carta e o combate, o roteador troca o contexto para Bênção, o que esvazia o buffer e exige soltar os botões. A confirmação só vale depois da trava. Ao fechar, a volta para Jogo acontece em `tela_fechada`, não em `escolher`, e os botões segurados são ignorados até serem soltos. Assim, o clique que confirma uma carta nunca vira golpe. A escala das cartas é `s = min(escala_ui, 1824 / largura(n))`, aplicada à raiz da fileira. O crescimento de 106% e a subida de 12 px do foco usam `offset_transform_*`, porque cada carta fica num `HBoxContainer`.

**6. Relógio de interface.** O `RelogioDeInterface` (RefCounted) é avançado pelo `Main._process` com `min(delta_real, dt_max)` e tem dois tempos. `t_ui()` para em `PAUSA`: é o relógio do HUD, das animações da Tela e das travas (Tela R1, HUD Game Feel, "+N" com a pausa). `t_real()` nunca para: é o relógio da animação da pausa e da captura de remapeamento. `t_apres` não serve aqui, porque fica parado em `BENCAO`. Redução de movimento troca as animações por fade ≤ 300 ms ou corte seco, sem mudar travas nem foco.

**7. Pausa e abandono.** O `MenuDePausa` (modelo e vista) abre em `JOGO` e em `BENCAO`. Em `BENCAO`, "Abandonar run" fica desabilitado por forma e por texto. Confirmar o abandono chama `PortaDaRun.abandonar()`. "Continuar" chama `retomar()` do orquestrador, que devolve o estado guardado antes da pausa (`JOGO` ou `BENCAO`). A pausa de cima devolve a mesma oferta e aplica a trava de 300 ms (F3 da Tela).

**8. Escala de UI.** O valor `escala_ui ∈ {0,85; 1,0; 1,25; 1,5}` vem da chave `[ui] escala` de `user://opcoes.cfg` pelo `RepositorioDeOpcoes` injetado do ADR-0013 (o mesmo repositório guarda `[telemetria] ligada`/`aviso_visto`, que a tela de opções também expõe, com "abrir pasta" e "apagar dados" do ADR-0013). A UI recebe o valor e não lê arquivo. Cada grupo do HUD é uma raiz `Control` ancorada no canto, **fora de container**, com offset de 48 px sem escala, `pivot_offset` no canto ancorado e `scale = Vector2(s, s)`. Elementos dentro de containers que precisam de transformação visual usam `offset_transform_*` (E1). Mudar a escala só reconfigura as raízes, nunca o layout interno. Se a gravação de opções falhar, quem mostra a mensagem é a UI (chave `OPCOES_FALHA_GRAVAR`), uma vez por tentativa, e a sessão segue com o valor em memória.

**9. Rótulos e localização.** Os glifos do prompt, do Selo, da Tela e dos menus vêm de `rotulo_acao(acao, dispositivo)` (`{texto, glifo}`), consultado de novo quando o dispositivo ativo muda (troca no passo seguinte, AC-HD-18). Todo texto visível é chave de tradução (`HUD_*`, `BENCAO_*`, `PAUSA_*`, `RUN_*`, `MENU_*`, `OPCOES_*`, além dos `INPUT_*` existentes), resolvida por `tr()` e, com marcadores, por `tr(chave).format({"valor": v})`. Os textos são reaplicados em `NOTIFICATION_TRANSLATION_CHANGED`. Os rótulos usam `autowrap_mode` e alturas fixas com redução até o piso de legibilidade (Tela Edge Cases). O separador de milhar sai de uma função própria, `FormatoNumerico`, porque a referência não cobre formatação de números por locale.

**10. Pactos: Bloco do Pacto, consentimento e escolha da dupla (emenda 2026-11-16).**

- **Bloco do Pacto** (`hud.md` R15–R19): grupo de HUD próprio, `Control` fora de container, 332 × 88 px a 100%, ancorado à esquerda e **12 px acima do topo do grupo do jogador** (segue o topo, não um y fixo). Só existe na cena em run de Pactos com ao menos uma Maldição na dupla (R15); sem Pactos nenhum nó é criado. Mostra a Maldição em campo (silhueta, Vida, marca de Saltando), a reserva (silhueta, Vida, anel de recuperação da Exaustão) e o Selo da Troca com `rotulo_acao("troca", dispositivo)`. Estados por forma, nunca só por cor. O modelo (`ModeloDoBlocoDoPacto`, `RefCounted`) lê `LeituraDoHud.estado_pacto(player_id)` em toda entrega e na criação (R14) e usa os eventos `troca_feita`, `troca_indisponivel`, `maldicao_exausta` e `maldicao_pronta` só para animar (sacudida `pacto_tremor_px`/`pacto_tremor_s`, pulso do contorno, preenchimento de 0,25 s). O **vínculo** e a **técnica pronta** não são peças separadas no HUD de combate: a técnica pronta é o estado cheio do Selo da Troca (troca disponível); o vínculo aparece só na tela de consentimento e no resumo (decisão minha, ver "Pendências").
- **Tela de consentimento do pacto** (`vinculo-e-pactos.md` V9, V10, V18): usa o **estado Bênção** do ADR-0001, sem estado novo, e o mesmo `ModeloDeFoco`, o mesmo `RelogioDeInterface` (`t_ui`) e as mesmas travas por borda de subida da Tela de bênção. Duas variantes de botões: **"Oferecer o vínculo"** / **"Deixá-la ir"**, ou o botão único **"Ela voltará"** (Raras na 1ª vez); a tela do chefe (Pactuar / Exorcizar) é a mesma máquina. A UI chama uma interface injetada `PortaDoPacto` (`@abstract`: `oferecer()`, `deixar()`, `voltara()`, `notificar_tela_fechada()`); o Vínculo emite `pacto_registrado` e o `Main` grava o perfil no fim do passo (ADR-0013, ponto seguro). O pacto grava no mesmo passo porque Bênção é estado fora de Jogo. Sem `Timer`; fechar volta a Jogo em `tela_fechada`, como na Bênção.
- **Barra de chefe (entra no MVP, `chefes.md` R10; deixa de ser "reservada").** Topo, centro, ~960 px. `ModeloDaBarraDeChefe` lê `LeituraDoHud.chefe()` (Vida, `vida_max`, fase, `subjugado`) em toda entrega e atualiza **no mesmo passo**; só existe na cena na câmara do chefe. O chefe **não** tem fio de Vida sob os pés (a barra é o único indicador); o pool de fios ignora o `chefe_id`. A mudança de fase e o estado subjugado animam pelos eventos `chefe_subjugado`/`chefe_escolhido`, mas o valor vem sempre da consulta.
- **`estado_pacto(player_id)` é consulta pura**, sem efeito colateral (`maldicoes.md` R19): não avança contador, não consome evento, não muda cache da Maldição.
- **Tela Escolha do Pacto (antes da seed)** (Maldições R2; evento `dupla_confirmada` cria a seed): `Control` no estado de menus/escolha de arma, com `ModeloDeFoco` e `ComandosDeTela` como as demais. Lista as espécies pactuadas lidas por `LeituraDoPerfil` (consulta ao Vínculo; a UI nunca lê `perfil.cfg`) e devolve a dupla por `PortaDaEscolhaDeDupla.confirmar(campo, reserva)`. Reusa o componente de carta no **modo `maldicao`** (`tela-de-bencao-e-carta.md` R15b-P): **duas escolhas em ordem** (primeiro o campo, depois a reserva), com o mesmo `GrupoDeCartas` (travas, foco inicial, política de clique) e sem troca. A `CartaView` ganha o campo opcional **`aviso_texto`** (R15-P), chave de tradução mostrada quando preenchido (por exemplo, Maldição ainda sem confiança). O `GrupoDeCartas` recebe o modo na abertura (`abrir(cartas, trocas, t, modo)`). A última dupla vem pré-selecionada (`ultima_dupla`).
- **Chaves de perfil exibidas** (`save-e-perfil.md` UI Requirements): `PERFIL_CORROMPIDO`, `PERFIL_VERSAO_FUTURA`, `PERSIST_FALHA_GRAVAR` (discreto), `PERFIL_SAIR_SEM_SALVAR` ("Tentar de novo" / "Sair sem salvar"), `PERFIL_RESET_CONFIRMAR` (duas confirmações, "Cancelar" é o padrão). Avisos `PERFIL_*` aparecem **uma vez por sessão, só fora de Jogo** (menu principal ou próxima tela fora de Jogo, nunca sobre o combate), são **navegáveis** por teclado e gamepad pelo `ModeloDeFoco` (`ui_voltar` = Cancelar) e entram na fila de avisos do `Main`. O item de reset (duas confirmações) fica **desabilitado, com o motivo visível**, no modo Sem gravação. São chaves de tradução `PERFIL_*`, sem literal em `.gd`.
- **Opções de acessibilidade do HUD** (TR-hud-012, R13): escala, número de Vida, Vida colorida, alto contraste e vinheta ficam em `user://opcoes.cfg`, seção `[ui]` (`escala`, `numero_vida`, `vida_colorida`, `alto_contraste`, `vinheta`), pelo `RepositorioDeOpcoes` do ADR-0013, e são aplicadas pelos donos (HUD, Pipeline).

**11. Fechamento da revisão de cobertura (2026-11-16).**

- **Seed nas telas e cópia (TR-rng-012, RNG F9/R8).** A pausa, as telas de morte e de vitória e o overlay de debug mostram o texto completo da seed (`3F9A-07C2 · v0.1.0 · c1B4E`) numa linha discreta, com fonte de algarismos tabulares. O texto vem pronto por consulta (`LeituraDaRun.texto_seed()`, formatado pelo dono da F9, ADR-0005); a UI não formata. "Copiar seed" é um item focável (e atalho) na pausa e nas telas de fim e chama uma porta injetada `PortaDaAreaDeTransferencia.copiar(texto)`; a implementação real usa `DisplayServer.clipboard_set(texto)` / `DisplayServer.clipboard_get()` diretamente (**Verificado (EX-0012 CB, 2026-11-16)** em janela e `.pck`). O campo de seed fica só no menu de debug (contexto Texto, `LineEdit`). Rótulos `PAUSA_COPIAR_SEED` e confirmação discreta `SEED_COPIADA`.
- **Troca e confirmar no mesmo passo (TR-bencaos-005, TR-tela-bencao-006; Tela R8, Bênçãos R5).** O `GrupoDeCartas`, ao processar os `ComandosDeTela` de um passo, testa `trocar` **antes** de `aceitar`: com cargas, só chama `PortaDaBencao.trocar()` e descarta o aceitar do mesmo passo (a troca vence). Sem cargas, a troca não existe: o comando é ignorado e o aceitar do mesmo passo vale. Não há pular. Dois aceitar no mesmo passo: vale o do foco atual.
- **Alto contraste e redução de movimento da Tela (TR-tela-bencao-010, Tela R14).** As flags chegam do `RepositorioDeOpcoes` (seções no ADR-0013) e a vista aplica: alto contraste troca o tema (painéis 100%, molduras de 3 px, raridade por contagem de linhas e palavra, osso puro sobre tinta pura); redução de movimento troca a entrada por fade ≤ 300 ms e o crescimento do foco por corte seco (continua, é informação); "Reduzir flashes" tira o flash do traço dourado e da rachadura via limitador do ADR-0011. Travas e foco não mudam.
- **Tela de escolha de arma (TR-armas-004, TR-tela-bencao-014; Armas R4, Tela R15-P).** Usa o mesmo `GrupoDeCartas`, `ModeloDeFoco` e `ComandosDeTela`, no **modo `arma`**, com **3 cartas** (Lâmina, Ressonância, Besta do Vínculo), `n` = 3, foco inicial na do meio, navegável por teclado, mouse e gamepad. Sem troca nem `preco_revelado`; `tela_fechada` é emitido. Devolve a escolha por `PortaDaEscolhaDeArma.escolher(i)`, que a composição da run (ADR-0015) liga. `aviso_texto` é preenchido por quem monta a carta da Besta quando o perfil não tem Maldição pactuada.
- **Contrato de `CartaView` (TR-tela-bencao-002).** A vista recebe um `DadosDaCarta` (RefCounted, só dados) e nunca lê `BoonDef`: `modo`, `nome` (chave), `doutrina`, `icone`, `glifo`, `icone_ganho`, `texto` (chave já com o número da raridade), `melhoria` (opcional), `preco_chave` + `preco_valor` (renderizado por `tr(chave).format({"valor": v})`) e `aviso_texto` (chave, nulo por padrão). A **Bênçãos** monta os dados de bênção a partir do `BoonDef`; o **Armas** monta os de arma (nome, Doutrina, Vida, rótulo de velocidade, Ataque e Especial).

### Key Interfaces

```gdscript
class_name LeituraDoHud extends RefCounted
@abstract
## Só consultas; nenhum método escreve em jogo (AC-HD-21).
func vida(player_id: int) -> Vector2i: return Vector2i.ZERO          # (atual, máxima)
func escudo(player_id: int) -> int: return 0
func recusas(player_id: int) -> int: return 0
func fluxo(player_id: int) -> Dictionary: return {}                  # atual, max, custo, recarga
func esquiva(player_id: int) -> Dictionary: return {}                # cargas, max, fracao
func saldo() -> int: return 0
func limiar_fundo_do_poco(player_id: int) -> float: return -1.0      # < 0 sem a bênção
func inimigos_feridos() -> Array[Dictionary]: return []              # id, vida, max, elite, pos
func porta_interagivel(player_id: int) -> Dictionary: return {}      # vazio = nenhuma
func estado_de_jogo() -> EstadoDeJogo.Valor: return EstadoDeJogo.Valor.INICIANDO
func hitstop_ativo() -> bool: return false
func chefe() -> Dictionary: return {}                                # vazio = sem chefe; vida, vida_max, fase, subjugado (Chefes R10)
func estado_pacto(player_id: int) -> Dictionary: return {}            # sem efeito colateral (Maldições R19); vazio = sem Pactos; campo, reserva (silhueta, vida, estado, restante_exausta), recarga_troca, troca_disponivel

class_name PortaDoPacto extends RefCounted   # consentimento V9/V10/V18; @abstract nas implementações reais
@abstract
func oferecer() -> void: pass
func deixar() -> void: pass
func voltara() -> void: pass
func notificar_tela_fechada() -> void: pass

class_name PortaDaBencao extends RefCounted
@abstract
func escolher(i: int) -> void: pass
func trocar() -> void: pass
func notificar_tela_fechada() -> void: pass

class_name ModeloDeFoco extends RefCounted
func definir_alvos(n: int, inicial: int, da_volta: bool) -> void
func aplicar(cmd: ComandosDeTela, alvo_sob_cursor: int) -> int       # devolve o índice focado
func focado() -> int

class_name GrupoDeCartas extends RefCounted   # modelo puro, sem sinais
func abrir(cartas: Array[DadosDaCarta], trocas: int, t: float, modo: StringName) -> void  # modo: &"bencao", &"arma", &"maldicao"
func processar(cmd: ComandosDeTela, alvo: int, t: float) -> void      # trocar é testado antes de aceitar (TR-bencaos-005)
func estado() -> StringName
func escala(n: int, escala_ui: float) -> float                       # F1

# VistaDaTela (Control, Apresentação)
signal preco_revelado()
signal tela_fechada()

class_name RelogioDeInterface extends RefCounted
func avancar(delta_real: float, pausado: bool) -> void
func t_ui() -> float
func t_real() -> float
```

Os métodos `@abstract` com retorno tipado não-void trazem `return` explícito nas implementações, como exige o 4.7. Os dublês de teste estendem as bases.

### Implementation Guidelines

- A UI **must** receber a entrada só por `ComandosDeTela` do provedor. **Must never** ler `Input`/`InputEvent`, usar `_gui_input` para ações nem ligar `pressed` de `BaseButton` a uma ação.
- Todo `Control` interativo **must** ter `mouse_filter = MOUSE_FILTER_IGNORE`, e o `project.godot` **must** esvaziar os eventos das ações nativas de navegação e confirmação (E2).
- O HUD **must** ler valores por consulta em toda entrega e na criação. **Must never** guardar estado de jogo nem chamar método de escrita.
- O teste de acerto **must** usar o slot de layout, nunca o visual com `offset_transform_*` nem `get_global_mouse_position()` (ADR-0007). Para foco a 106%/escala, **must** manter `offset_transform_visual_only = true` (padrão no 4.7.2; verificado em `EX-0012 E1`) e posicionar o anel de foco pelo slot + offset conhecidos, nunca por `get_global_transform_with_canvas()`.
- A margem segura de 48 px **must never** ser escalada. As raízes escaladas **must never** ser filhas diretas de um `Container`.
- As animações de UI **must** usar `t_ui`/`t_real`. **Must never** usar `Timer`, `create_timer` nem `Tween` sem controle de pausa, porque não há `SceneTree.paused`.
- Todo texto visível **must** ser chave de tradução. **Must never** haver string literal de interface em `.gd` ou `.tscn`. Em CSV com `?context` e `?plural` (linhas de continuação com `keys` vazio; verificado em `EX-0012 E6`), os textos em `pt_BR` **must** aceitar `0` no singular (`"0 item"`, regra CLDR do português).
- Os sons de UI **must** sair por eventos de áudio (Feedback/Áudio), nunca por `AudioStreamPlayer` chamado direto da vista.

## Alternatives Considered

| Alternativa | Prós | Contras |
|---|---|---|
| Manter `Node2D` com `_draw` (fatia) | Já existe, um só nó | Sem tema, escala, localização, AccessKit nem testes por fonte falsa; retângulos duplicados entre desenho e hover |
| Usar os `Button` nativos com foco da engine | Menos código | Foco duplo do 4.6, dupla confirmação com o comando amostrado, hover que rouba o foco na abertura e trava fora do controle do Input |
| `Window.content_scale_factor` para a escala de UI | Uma linha | Escala também o mundo e a margem de 48 px |
| Fio e prompt como `Node2D` nas camadas de mundo | Ordem natural com os personagens | Recebem gravura/LUT e vinheta, entram na disciplina de camadas do ADR-0007 e podem ficar atrás do primeiro plano |
| Bênçãos chamando a Tela por referência | Caminho curto | O módulo de regra passaria a referenciar um nó, o que viola o ADR-0002 |

## Consequences

**Positivas:** uma via de entrada só, testável sem engine. O foco único segue a Art Bible §7.6 mesmo com o foco duplo do 4.6. O HUD é imune a eventos perdidos e pode ser recriado na Transição. As travas e os sinais da Tela são verificáveis com relógio falso.

**Negativas:** o roteamento de foco, o teste de acerto e o anel de foco passam a ser código próprio. O `InputMap` alterado diverge do padrão da engine (E2).

**Pedidos a outros ADRs:** o ADR-0002 ganha consumidores na entrega: a ordem fica Telemetria, HUD, Feedback, `Telas`, Áudio (emenda 2026-11-16; ADR-0016 fixa o Áudio por último, e `Telas` e HUD alimentam a `FilaDeSonsDeInterface`). A ordem dos três primeiros não muda. O ADR-0001 ganha `retomar()`, com o estado anterior à pausa, já que a tabela dele só lista `JOGO`. O ADR-0006 precisa expor `mouse_moveu` e o clique com posição em `ComandosDeTela`. O ADR-0011 desenha a vinheta a partir do valor publicado pelo HUD.

## Risks

- **E1, `offset_transform_*` e acerto:** se o recurso mexer na transformação global, o slot de layout isola o acerto. O risco que sobra é visual.
- **E2, ações nativas esvaziadas quebrando o `LineEdit`:** a mitigação é esvaziar só a lista citada e manter as `ui_text_*`. O AC-36 do Input é o teste.
- **E3, clique de ativação:** a barreira de retorno cobre os dois comportamentos possíveis. O teste é com hardware real.
- **Comandos processados durante a entrega do final comum:** uma chamada a `PortaDaBencao` emite eventos que só saem no passo seguinte (ADR-0001 §5.3). Os testes cobrem `bencao_tomada` no passo N+1.
- **Custo de draw calls do HUD:** as flags de "sujo" e um pool de 9 fios limitam o custo. O orçamento é do ADR-0011.

## GDD Requirements Addressed

| GDD | Requisito | Como |
|---|---|---|
| hud.md | R1, R14; AC-HD-21, 31 | `LeituraDoHud` só com consultas; valores relidos em toda entrega e na criação |
| hud.md | R2, R13; AC-HD-26, 27, 34 | `CanvasLayer` UI; âncoras nas bordas de W × 1080; escala em raízes de grupo com margem de 48 px sem escala |
| hud.md | R3, R12; AC-HD-35, 36, 19 | Sinais `preco_revelado` e `tela_fechada`; espera do hitstop; visibilidade pelo estado consultado |
| hud.md | R4 | Vinheta calculada no HUD e desenhada no Pós pelo ADR-0011 |
| hud.md | R10; AC-HD-18 | `rotulo_acao` consultado de novo na troca de dispositivo |
| hud.md | Game Feel; AC-HD-24 | `t_ui` para com a pausa |
| tela-de-bencao-e-carta.md | R6, R7, F2, F3; AC-TB-04–12, 31, 32 | `ModeloDeFoco` e `GrupoDeCartas` com borda de subida, travas e política de clique |
| tela-de-bencao-e-carta.md | R9, R16; AC-TB-16, 17, 24, 25, 29 | `PortaDaBencao`; `escolher` no passo do aperto; Bênçãos segura `bencao_escolhida` até `notificar_tela_fechada()` |
| tela-de-bencao-e-carta.md | R3, F1, F5; AC-TB-01, 02, 28 | Escala `s` na raiz da fileira; foco a 106% com `offset_transform_*` |
| tela-de-bencao-e-carta.md | Edge Cases; AC-TB-34 | Perder o foco da janela na Bênção não pausa |
| input-e-controle.md | R9; AC-33, 34 | Foco único espelhado; hover só com o mouse em movimento; inventário de telas |
| input-e-controle.md | R10, R11; AC-35, 40 | Contextos pelo roteador; pausa por perda de foco em Jogo; barreira de retorno |
| input-e-controle.md | AC-39 | Consumo de `rotulo_acao` |
| run-e-regioes.md | R6; AC-RN-14, 15 | `MenuDePausa` com "Abandonar run" desabilitado em Bênção e `retomar()` |
| hud.md | R15–R19, F8; AC-HD-38 a 47 (Bloco do Pacto) | Decisão 10: `ModeloDoBlocoDoPacto` lê `estado_pacto()` em toda entrega; grupo ancorado 12 px acima do grupo do jogador; só existe com Pactos (TR-hud-013, TR-hud-014; barra de Vida da Maldição em largura fixa) |
| hud.md | R13; AC-HD-25 (TR-hud-012) | Opções do HUD em `opcoes.cfg [ui]`, pelo `RepositorioDeOpcoes` (ADR-0013) |
| vinculo-e-pactos.md | V9, V10, V18 (tela de consentimento no estado Bênção) | `PortaDoPacto` e a máquina de foco da Bênção; grava no ponto seguro (TR-vinculo-008, TR-vinculo-011) |
| maldicoes.md | R2 (escolha da dupla), UI Requirements | Tela de escolha das 2 Maldições com `ultima_dupla` pré-selecionada (TR-tela-bencao-015, TR-vinculo-003) |
| save-e-perfil.md | UI Requirements, R11 (avisos `PERFIL_*`, reset com duas confirmações) | Chaves de perfil e item de reset na tela de opções (TR-save-018, TR-save-014) |
| tela-de-bencao-e-carta.md | Emenda Pactos (reuso da tela para consentimento) | Mesmo `ModeloDeFoco`, travas e relógio; variante de botões |
| rng-com-seed.md | F9, R8, UI (TR-rng-012) | Decisão 11: seed na pausa, morte, vitória e debug; `PortaDaAreaDeTransferencia` (`DisplayServer.clipboard_set/get` verificado em `EX-0012 CB`) |
| bencaos-tradicoes.md / tela-de-bencao-e-carta.md | Bênçãos R5, Tela R8 (TR-bencaos-005, TR-tela-bencao-006) | Decisão 11: trocar testado antes de aceitar; sem cargas o aceitar vale |
| tela-de-bencao-e-carta.md | R14 (TR-tela-bencao-010) | Decisão 11: alto contraste, redução de movimento, Reduzir flashes pelo limitador |
| armas-das-doutrinas.md / tela-de-bencao-e-carta.md | Armas R4, Tela R15-P (TR-armas-004, TR-tela-bencao-014) | Decisão 11: modo `arma` com 3 cartas, `aviso_texto`, `PortaDaEscolhaDeArma` |
| tela-de-bencao-e-carta.md | R2, contrato `CartaView` (TR-tela-bencao-002) | Decisão 11: `DadosDaCarta` montado pela Bênçãos a partir do `BoonDef` |

## Performance Implications

O HUD faz cerca de 10 consultas por passo, a 60 Hz, sem alocação nos caminhos quentes: os dicionários das consultas são reaproveitados pelo adaptador real. Strings e `Label.text` só mudam quando o valor muda. Há no máximo 9 fios em pool e uma Tela instanciada uma vez e reaproveitada. Sem `_process` por elemento: a vista do HUD tem um `_process` só. A memória é desprezível. O orçamento de draw calls e de fontes vem do ADR-0011.

## Migration Plan

1. Extrair de `game_hud.gd` os textos para chaves de tradução e criar o CSV.
2. Criar `LeituraDoHud` sobre o `game_session.gd` como adaptador temporário.
3. Trocar o `Node2D` por `Control` no `CanvasLayer` UI, primeiro o HUD e depois a pausa, os menus e a Tela.
4. Mover o `app.selected` e os `action_rects()` para o `ModeloDeFoco` e os slots de layout.
5. Remover a dica fixa de controles e passar a usar `rotulo_acao`.
6. Introduzir `RelogioDeInterface` e `PortaDaBencao` quando os módulos reais de Bênçãos e Input existirem.

Cada passo fecha com captura de tela em `production/qa/evidence/`.

## Validation Criteria

1. Testes unitários (gdUnit4) do `ModeloDoHud` com fontes falsas, cobrindo AC-HD-01 a 25 e 29 a 37.
2. Testes de `GrupoDeCartas` e `ModeloDeFoco` com relógio falso, cobrindo AC-TB-01 a 25 e 29 a 35.
3. Teste de integração provando que, com mouse sintético sobre uma carta e o comando aceitar no mesmo passo, `escolher` é chamado uma vez (sem dupla confirmação).
4. Experimentos E1 a E3 no Windows com a 4.7.2.
5. Capturas de tela: AC-HD-26, 27, 28 e 34; AC-TB-26 a 28; AC-34 do Input (só teclado e só gamepad).
6. Teste de que nenhum `.gd` de UI contém literal de texto visível (varredura).

## Nota de preparação para co-op

O HUD é instanciado por jogador local (`player_id` 0 no solo). `LeituraDoHud` recebe `player_id` em toda consulta de jogador, e o saldo continua global até o design decidir. O painel de aliados (co-op-ganchos, HUD R2) vira uma segunda vista sobre a mesma leitura. `PortaDaBencao` e `tela_fechada` já carregam um fluxo por tela, e a versão por jogador só acrescenta `player_id`. A pausa que para o mundo continua sendo regra do solo: online, ela vira um menu local (co-op-ganchos, Alta). Nada de rede é implementado agora.

## Decisões do usuário (resolvidas em 2026-11-15)

**O usuário aceitou todas as recomendações abaixo em 2026-11-15.** Elas valem como decisão deste ADR; o texto de cada item fica como registro das opções.

1. **Camada do fio de Vida e do prompt.** (a) Camada UI, acima do primeiro plano, sem gravura nem vinheta. (b) Mundo, sob os efeitos do Pós e podendo ser coberto pelo primeiro plano. **Recomendação:** (a), por legibilidade (P3). Confirmar com o art-director.
2. **Separador de milhar.** (a) Espaço fixo "1 234", como no GDD. (b) Separador do locale ("1.234" em pt-BR). **Recomendação:** (a) no MVP, porque é inequívoco e igual em todos os idiomas.
3. **Leitor de tela (AccessKit) no MVP.** (a) Fora do MVP, mantendo a estrutura de `Control` com foco espelhado. (b) Dentro do MVP. **Recomendação:** (a). As APIs além de `accessibility_live` são NOT SOURCEABLE.

## Emenda Pactos e pendências (2026-11-16)

- **Aresta com o ADR-0009:** a UI de Pactos lê Vida e atributos do portador da Maldição por consulta (`fontes_de`), nunca por cálculo próprio. Declarada em Depends On.
- **Aresta com o ADR-0011:** o HUD usa o shader de material `ui` com `sem_grading` (fio de Vida, prompt, Bloco do Pacto escapam de gravura e LUT) e publica a vinheta como valor; o desenho fica com o Pipeline. Declarada em Depends On.
- **Tela de consentimento:** estado Bênção, sem estado novo (decisão 19 de `pactos-decisoes-a-confirmar.md`). O ADR-0001 precisa aceitar que `BENCAO` abrigue as duas telas, escolhidas pela oferta ativa (pendência de coordenação).
- **Decisões minhas, para revisão:** (1) vínculo e técnica pronta não ganham peça própria no HUD de combate (o GDD só pede o Selo da Troca cheio como "troca disponível"); (2) nomes `PortaDoPacto`, `LeituraDoPerfil` e `PortaDaEscolhaDeDupla` são propostas; (3) as chaves em `[ui]` além de `escala` são nomes provisórios, a conferir com o HUD R13; (4) a escolha da dupla ocorre no estado de escolha de arma do ADR-0015.
- **Pendências:** E1–E6 e CB foram **Verificados (EX-0012, 2026-11-16)**; AC-HD-38 a 47 entram nos testes unitários das stories de UI.

## Verificação de engine (2026-11-16)

Fonte: `production/qa/evidence/experimentos/ex-0012-ui.md` e `production/qa/evidence/experimentos/ex-0001-foco-e-apresentacao.md`. Editor 4.7.2 standard + `.pck` exportado, Windows 11.

- **E1 — `offset_transform_*` e acerto: Verificado (EX-0012).** No 4.7.2 existe `offset_transform_visual_only` (padrão `true`). Com `offset_transform_visual_only = true`, o deslocamento e a escala são apenas de desenho: `get_global_rect()`, `get_global_transform_with_canvas()` e o acerto de mouse permanecem no slot de layout. Com `visual_only = false`, o offset entra na transformação global. **Regra:** exigir `offset_transform_visual_only = true` para o crescimento de 106% / subida de 12 px do foco, e posicionar o anel de foco e cálculos sobre o visual deslocado a partir do slot + offset conhecidos (não usar `get_global_transform_with_canvas()`).
- **E2 — Esvaziamento de `ui_*` × `LineEdit`: Verificado (EX-0012).** `InputMap.action_erase_events` em `ui_accept`, `ui_select`, `ui_cancel`, `ui_up/down/left/right` e `ui_focus_next/prev` desliga a navegação nativa (`Tab` não tira o foco) sem afetar as 50 ações `ui_text_*` (digitação, setas, Backspace, Shift+End, Delete, Ctrl+A, Home e `ui_text_submit` com Enter seguem funcionando em `LineEdit`).
- **E3 — Clique de reativação da janela: Verificado (EX-0012 / EX-0001).** Ao clicar numa janela sem foco no Windows, o evento chega na ordem `NOTIFICATION_APPLICATION_FOCUS_IN` → `NOTIFICATION_WM_WINDOW_FOCUS_IN` → `Window.focus_entered` → `InputEventMouseButton pressed=true` (~46 ms depois) → `pressed=false`. **Regra:** manter a barreira de retorno do ADR-0012 aberta em `APPLICATION_FOCUS_IN`, descartando o par press/release que acompanha o ganho de foco.
- **E4 — Desativação recursiva (4.5): Verificado (EX-0012).** Nomes confirmados em `ClassDB`: `focus_behavior_recursive` (`Control.FocusBehaviorRecursive`: `FOCUS_BEHAVIOR_INHERITED=0`, `_DISABLED=1`, `_ENABLED=2`) e `mouse_behavior_recursive` (`Control.MouseBehaviorRecursive`: `MOUSE_BEHAVIOR_INHERITED=0`, `_DISABLED=1`, `_ENABLED=2`).
- **E5 — AccessKit (4.5/4.7): Verificado (EX-0012).** Propriedades de `Control` confirmadas: `accessibility_name`, `accessibility_description`, `accessibility_live`, `accessibility_controls_nodes`, `accessibility_described_by_nodes`, `accessibility_labeled_by_nodes`, `accessibility_flow_to_nodes`. Mantido fora do MVP.
- **E6 — Plurais e contexto em CSV (4.6): Verificado (EX-0012).** Cabeçalho `keys,?context,?plural,en,pt_BR`, com linhas de continuação de plural trazendo `keys` vazio. Em `pt_BR`, `tr_n` aplica a regra CLDR do português em que `0` usa a forma **singular** (`"0 item"`).
- **CB — Área de transferência (`TR-rng-012`): Verificado (EX-0012).** `DisplayServer.has_feature(FEATURE_CLIPBOARD) == true`; `DisplayServer.clipboard_set/get` funcionam na janela e no `.pck` exportado, integrando com a área de transferência do Windows (`PortaDaAreaDeTransferencia` usa `DisplayServer.clipboard_set/get` diretamente).

## Related

GDDs: `design/gdd/hud.md`, `tela-de-bencao-e-carta.md`, `input-e-controle.md`, `run-e-regioes.md`, `co-op-ganchos.md`. ADRs: 0001, 0002, 0004, 0006, 0007, 0011, 0013. Fatia: `src/presentation/game_hud.gd`, `src/app/main.gd`.
