# Campus (Hub)

> **Status**: Designed
> **Author**: game-designer (Vertical Slice)
> **Created**: 2026-11-18
> **Last Updated**: 2026-11-18
> **Sistema**: #25 · Category: `Meta` · Priority: `Vertical Slice`
> **Implements Pillar**: P4 *Ritual, não pressão*; P1 *Toda bênção é uma filosofia*; P5 *O mundo não se explica de uma vez*

## Summary

O **Campus** é o espaço seguro e ritualístico entre runs onde o Iniciado retorna após morte, vitória ou abandono, investe Fragmentos na **Oficina de Reforja**, conversa com os **Mestres Ofertantes** no **Altar dos Mestres**, escolhe ou desbloqueia armas no **Altar de Doutrinas / Armas** e inicia uma nova descida pelo **Portal do Limiar**. A navegação é contínua em câmera 3/4 com interação contextual (`E`/`A`), mantendo um atalho rápido para testes e iteração de combate.

> **Quick reference** — Layer: `Meta` · Priority: `Vertical Slice` · Key deps: `Oficina de Reforja, Mestres ofertantes, Desbloqueio de armas, Rito de Iniciação e criação do Iniciado, Cena 3/4 e câmera, Input e controle`

## Overview

No MVP, o ciclo de jogo acontecia apenas entre menus e câmara de combate. Na Vertical Slice, o **Campus** materializa o pilar **P4 (*Ritual, não pressão*)**: voltar da Beira não é apenas uma tela de "Tentar de novo", mas um retorno físico a um pátio silencioso onde o progresso entre runs tem lugar, peso e voz.

- **Entrada no Campus:** Ao iniciar uma sessão (com perfil carregado) ou ao encerrar uma run (morte, vitória ou abandono), o jogador chega ao Campus no ponto de retorno. A tela de fim de run oferece **"Voltar ao Campus"** (fluxo padrão) e, opcionalmente para iteração rápida, **"Descer de novo (atalho)"** conforme configuração de build/opções.
- **Quatro zonas interativas:**
  1. **Oficina de Reforja** — gasta Fragmentos em melhorias permanentes.
  2. **Altar dos Mestres** — ponto de encontro e diálogo contextual com **Halvar**, **Maren** e **Oreth**.
  3. **Altar de Doutrinas / Armas** — seleção de arma/Doutrina (e dupla de Maldições quando aplicável) e acesso a desbloqueios.
  4. **Portal do Limiar** — inicia uma nova run no Limiar da Beira com a configuração atual.
- **Navegação e atalho rápido:** O jogador move o Iniciado livremente pelo Campus (mesmo controle de movimento da câmara 3/4, sem gasto de vida/dano) e interage com a zona mais próxima via `E` (teclado) ou `A` (gamepad). Para testes e playtests focados em combate, existe um atalho rápido (menu de pausa ou tecla/opção de debug controlada) que permite abrir diretamente a descida ou o painel da zona sem caminhar.

**Fantasia do jogador (MDA — Fantasy, Submission, Discovery):** Respirar entre descidas, sentir que a Beira deixou marcas e ganhos concretos (Fragmentos, diálogos novos dos Mestres) e escolher o próximo ritual no próprio ritmo, sem cronômetro nem pressão.

## Detailed Design

### Core Rules

**R1. Ponto de entrada e retorno.**
- Ao iniciar o jogo após o carregamento do `Save` (e concluído o Rito de Iniciação em perfil novo), o estado padrão de entrada da Vertical Slice é o **Campus** (`ponto_entrada_campus`).
- Ao encerrar uma run (`run_encerrada` por vitória, morte ou abandono), após a tela de resumo da run, o jogador retorna ao Campus (`ponto_retorno_campus`).
- A gravação do `Save` pendente do fim da run ocorre antes ou na transição para o Campus (ponto seguro, `save-e-perfil.md` R5.1).

**R2. Zonas interativas canônicas.**
O Campus possui exatamente 4 zonas interativas na Vertical Slice, cada uma com posição fixa no mapa, raio de interação (`raio_interacao_px`), rótulo localizado e ação associada:

| ID da Zona | Nome em UI | Sistema Destino | Ação ao Interagir (`E` / `A`) |
|---|---|---|---|
| `zona_oficina` | Oficina de Reforja | Sistema #22 (`Oficina de Reforja`) | Abre o painel da Oficina para compra/reembolso de melhorias |
| `zona_mestres` | Altar dos Mestres | Sistema #20 (`Mestres ofertantes`) | Abre seleção/diálogo contextual com Halvar, Maren ou Oreth |
| `zona_armas` | Altar de Doutrinas | Sistema #9 / #23 (`Armas das Doutrinas` / `Desbloqueio`) | Abre a seleção de arma/Doutrina (e dupla de Maldições se Pactos) |
| `zona_portal` | Portal do Limiar | Sistema #18 (`Run e regiões`) | Inicia nova run no Limiar da Beira com arma/modificadores ativos |

**R3. Navegação contínua e detecção de foco.**
- O Iniciado se move no Campus usando a mesma movimentação base (`Movimento e esquiva`, sem combate, sem dano, sem perda de vida; esquiva opcional apenas como deslocamento suave ou desabilitada se em área de menu).
- A cada passo, o sistema verifica a distância do centro do Iniciado até cada zona ativa. A zona com menor distância dentro de `raio_interacao_px` torna-se a **`zona_focada`**.
- Em caso de empate exato de distância, vence a ordem determinística da lista (`zona_oficina`, `zona_mestres`, `zona_armas`, `zona_portal`).
- Quando `zona_focada` não é nula e nenhum painel modal está aberto, o prompt contextual (`[E]` / `[A]` + nome da zona) é exibido.

**R4. Abertura de painéis e bloqueio de movimento.**
- Pressionar `interagir` (`E` / `A`) com `zona_focada` válida abre o painel correspondente (ou dispara `nova_run()` no caso do `zona_portal`, após confirmação se configurada).
- Enquanto um painel modal do Campus está aberto (Oficina, Mestres, Altar de Doutrinas), o movimento do Iniciado no Campus pausa e o input passa ao contexto de UI/Menu.
- Fechar o painel (`Esc` / `B`) devolve o controle ao Iniciado no mesmo ponto do Campus, sem recarregar a cena.

**R5. Aplicação de modificadores antes da descida.**
- Ao interagir com `zona_portal` para iniciar a run:
  1. A arma/Doutrina selecionada no Altar de Doutrinas é validada (e a dupla de Maldições, se `pactos`).
  2. A `Oficina de Reforja` injeta os modificadores permanentes (`meta:reforja_*`) no portador do jogador.
  3. O `Save` grava eventuais alterações pendentes em ponto seguro.
  4. A cena transiciona para a primeira câmara da run (`Run e regiões`).

**R6. Atalho rápido para testes e fluxo direto.**
- O menu de pausa dentro do Campus (e um parâmetro de composição/configuração `modo_atalho_campus` em builds de teste) expõe atalhos diretos para: **Iniciar Run Imediatamente** e **Abrir Oficina / Armas**, evitando caminhada repetitiva durante QA e balanceamento.
- Em build de produção, o atalho rápido do menu de pausa para "Ir direto ao Portal" pode permanecer como conveniência de acessibilidade/ritmo ou ser restrito via knob `permitir_atalho_portal_no_pause`.

**R7. Restrições de combate e estado.**
- No Campus não há inimigos, não há ondas, não há geração de Fluxo, não há uso de `Selo` ofensivo nem coleta de Fragmentos em chão.
- O HUD de combate (barra de vida de inimigos, contador de câmara, timer de onda) fica oculto; apenas o saldo atual de **Fragmentos** e o indicador discreto de interação ficam visíveis.

### States and Transitions

| Estado | Entra quando | Comportamento | Sai para |
|---|---|---|---|
| **Livre (Navegação)** | Chegada ao Campus ou fechamento de painel modal | Movimento contínuo 3/4, atualização de `zona_focada`, prompt `[E]`/`[A]` | **Painel Aberto** (`interagir` em Oficina/Mestres/Armas) ou **Transição de Run** (`interagir` em Portal) |
| **Painel Aberto** | Interação em `zona_oficina`, `zona_mestres` ou `zona_armas` | Movimento travado; foco de input no painel UI; `Save` em ponto seguro | **Livre (Navegação)** (`Esc`/`B` ou botão Fechar) |
| **Transição de Run** | Interação confirmada em `zona_portal` (ou atalho rápido) | Consolida arma, aplica `meta:reforja_*`, garante save, inicia run | **Run Ativa** (`Run e regiões`) |

### Interactions with Other Systems

| Sistema | Recebe do Campus | Fornece ao Campus | Dono da interface |
|---|---|---|---|
| **Oficina de Reforja (#22)** | Abertura da UI, solicitação de compra/reset | Estado das melhorias, custos, efeitos `meta:reforja_*` | Oficina de Reforja |
| **Mestres ofertantes (#20)** | Abertura do diálogo no Altar dos Mestres | Mestre selecionado, falas contextuais, estado de afinidade | Mestres ofertantes |
| **Armas das Doutrinas (#9) / Desbloqueio (#23)** | Seleção de arma/Doutrina ativa | Lista de armas disponíveis/desbloqueadas | Armas / Desbloqueio |
| **Run e regiões (#18)** | Comando de início de run (`iniciar_run`) | Evento `run_encerrada` para retorno ao Campus | Run e regiões |
| **Economia de Fragmentos (#21)** | Leitura de saldo para exibição no HUD do Campus | `saldo()`, `saldo_mudou` | Economia de Fragmentos |
| **Save e perfil (#27)** | Ponto seguro ao fechar painéis / antes de descer | Estado persistido da seção `[campus]` (ex.: última zona visitada / flags de boas-vindas) | Save e perfil |
| **Input e controle (#4)** | Contexto `Campus` / `Menu` | Vetor de movimento, ação `interagir`, ação `pausar` | Input e controle |

## Tuning Knobs

| Knob | Padrão | Faixa | Categoria | Efeito e racional |
|---|---|---|---|---|
| `raio_interacao_px` | `110` | `70–160` | Feel | Distância máxima para destacar e permitir interação em uma zona sem exigir posicionamento milimétrico. |
| `velocidade_campus_mult` | `1.0` | `0.8–1.4` | Feel | Multiplicador sobre a velocidade base no Campus para ajustar ritmo de travessia sem afetar combate. |
| `confirmar_portal` | `false` | `true/false` | Gate | Se `true`, pede confirmação rápida ao interagir com o Portal do Limiar; `false` reduz atrito no loop de restart (meta `Restart Rate ≥ 40%`). |
| `permitir_atalho_portal_no_pause` | `true` | `true/false` | Gate | Habilita botão "Descer ao Limiar" no menu de pausa do Campus para testes e jogadores que preferem pular a caminhada. |

## Edge Cases

- **Sobreposição de raios de interação:** Se duas zonas estiverem próximas demais por alteração de layout, `zona_focada` escolhe sempre a de menor distância euclidiana ao Iniciado (desempate determinístico por ordem de definição).
- **Retorno de run por abandono ou falha de save:** Mesmo que `run_encerrada` venha de abandono ou com `Save` em modo `Sem gravação`, o jogador retorna normalmente ao Campus com o estado em memória preservado.
- **Entrada no Portal sem Maldição pactuada usando Besta do Vínculo:** Segue a regra de `Armas das Doutrinas` R2b e `Maldições` R2: o jogo permite iniciar se for válido no catálogo, exibindo aviso claro no Altar de Doutrinas caso a dupla esteja incompleta.
- **Spam de tecla `interagir` (`E`/`A`) na transição do Portal:** Ao entrar em `Transição de Run`, o input de interação é travado imediatamente para evitar disparo duplo de `nova_run()`.
- **Primeira entrada sem Fragmentos:** O jogador ainda pode abrir a Oficina (vendo custos e descrições como objetivo futuro) e conversar com os Mestres antes de descer pela primeira vez.

## Dependencies

### Depends On (Upstream)
- **Cena 3/4 e câmera (#5)** — renderização do pátio, y-sort e limites de câmera do Campus.
- **Input e controle (#4)** — leitura de movimento e ação `interagir` (`E`/`A`).
- **Oficina de Reforja (#22)** — painel e lógica de melhorias permanentes.
- **Mestres ofertantes (#20)** — diálogos e retratos no Altar dos Mestres.
- **Armas das Doutrinas (#9) / Desbloqueio (#23)** — seleção e desbloqueio de armas.
- **Run e regiões (#18)** — transição de entrada e retorno de run.
- **Save e perfil (#27)** — persistência de estado entre sessões.

### Depended On By (Downstream)
- **Menus (#30)** — fluxo Pós-Run ("Voltar ao Campus") e Menu de Pausa no Campus.
- **HUD (#28)** — modo Campus (exibição de Fragmentos e prompt contextual de interação).
- **Áudio (#32)** — ambiência calma do Campus e SFX de interação nas zonas.

## UI Requirements

- **Prompt contextual flutuante:** Exibido sobre ou próximo à `zona_focada` com ícone da tecla/botão ativo (`[E]` ou `[A]`) e nome localizado da zona.
- **HUD mínimo no Campus:** Saldo de Fragmentos sempre visível no canto superior/inferior padrão do HUD; barras de combate ocultas.
- **Painéis modais consistentes:** Oficina, Mestres e Altar de Doutrinas usam o mesmo padrão de foco (mouse, teclado e gamepad) e fecham com `Esc` / `B`.
- **Feedback de transição:** Fade curto (≤ 0,4 s) ao atravessar o Portal do Limiar ou retornar ao Campus, preservando o tom ritualístico (P4).

## Acceptance Criteria

- **AC-CH-01 [I] — Retorno pós-run:** GIVEN uma run encerrada (vitória, morte ou abandono), WHEN o jogador confirma o retorno na tela de resumo, THEN o jogo transiciona para o estado `Livre (Navegação)` do Campus no ponto de retorno, sem inimigos ativos.
- **AC-CH-02 [L] — Detecção de zona focada:** GIVEN o Iniciado dentro de `raio_interacao_px` de `zona_oficina` e fora do alcance das demais, WHEN o passo atualiza, THEN `zona_focada == zona_oficina` e o prompt contextual é exibido.
- **AC-CH-03 [L] — Desempate determinístico:** GIVEN o Iniciado equidistante de duas zonas dentro do raio, WHEN o passo atualiza, THEN `zona_focada` seleciona a primeira na ordem canônica (`zona_oficina > zona_mestres > zona_armas > zona_portal`).
- **AC-CH-04 [I] — Abertura e fechamento da Oficina:** GIVEN `zona_focada == zona_oficina`, WHEN o jogador aciona `interagir`, THEN o painel da Oficina abre e o movimento no Campus é bloqueado até que o painel seja fechado (`Esc`/`B`).
- **AC-CH-05 [I] — Abertura do Altar dos Mestres:** GIVEN `zona_focada == zona_mestres`, WHEN o jogador aciona `interagir`, THEN o painel do Altar dos Mestres abre permitindo escolher entre Halvar, Maren e Oreth.
- **AC-CH-06 [I] — Abertura do Altar de Doutrinas:** GIVEN `zona_focada == zona_armas`, WHEN o jogador aciona `interagir`, THEN a tela de seleção de arma/Doutrina abre e permite alterar a arma equipada para a próxima run.
- **AC-CH-07 [I] — Início de run pelo Portal:** GIVEN `zona_focada == zona_portal`, WHEN o jogador aciona `interagir`, THEN a run inicia no Limiar da Beira com a arma selecionada e os modificadores `meta:reforja_*` aplicados ao jogador.
- **AC-CH-08 [L] — Trava contra disparo duplo:** GIVEN o estado `Transição de Run` após acionar o Portal, WHEN o jogador pressiona `interagir` novamente durante a transição, THEN o comando é ignorado e `nova_run()` é chamada apenas uma vez.
- **AC-CH-09 [I] — Atalho rápido de teste:** GIVEN `permitir_atalho_portal_no_pause == true`, WHEN o jogador abre o menu de pausa no Campus e aciona o atalho de descida direta, THEN a run inicia sem necessidade de caminhar até `zona_portal`.
- **AC-CH-10 [I] — Ausência de combate no Campus:** GIVEN o jogador no Campus, WHEN tenta disparar Ataque/Especial/Selo, THEN nenhum dano é aplicado, nenhuma onda é iniciada e o HUD de combate permanece oculto.
