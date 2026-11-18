# Co-op Online

> **Status**: Designed
> **Author**: game-designer (Alpha)
> **Created**: 2026-11-18
> **Last Updated**: 2026-11-18
> **Sistema**: #36 · Category: `Gameplay` · Priority: `Alpha`
> **Implements Pillar**: P1 *Toda bênção é uma filosofia*; P2 *A Beira cobra*; P3 *Reflexo que se lê*; P4 *Ritual, não pressão*

## Summary

O **Co-op Online** permite que **1 a 4 jogadores** desçam juntos pela Beira em sessões hospedadas por um dos jogadores (modelo Host Autoritativo, Sistema #37). Cada jogador entra no lobby com seu próprio **Iniciado** e escolhe sua **Doutrina/Arma** individualmente. Durante a run, a dificuldade (orçamento de onda, vida de inimigos e chefes) e as recompensas escalam com o número de jogadores `N`, jogadores abatidos entram em estado de **Queda** podendo ser reanimados dentro da câmara antes de virarem **Espectadores**, e as escolhas de **portas** e **bênçãos** seguem fluxos sincronizados de grupo sem congelar o mundo de forma arbitrária.

> **Quick reference** — Layer: `Gameplay` · Priority: `Alpha` · Key deps: `Netcode e sincronização (#37), Run e regiões (#18), Câmaras e ondas (#16), Combate núcleo (#8), Portas e recompensas (#17), Bênçãos (Tradições) (#19), Economia de Fragmentos (#21), HUD (#28)`

## Overview

O modo cooperativo de Khaeros estende o loop canônico solo (**câmara → bênção → porta**) para um grupo de até 4 Iniciados sem diluir a legibilidade do combate (**P3**) nem a cobrança da Beira (**P2**).

- **Lobby de 1 a 4 jogadores:** O host cria uma sala e compartilha um **código de convite / código local** (ou convite direto de sessão). Até 3 aliados se conectam antes da descida.
- **Seleção individual de Iniciado e Doutrina:** Cada jogador traz seu perfil local (Aparência/Iniciado, melhorias permanentes da Oficina de Reforja) e escolhe sua própria arma/Doutrina no lobby (composição livre ou sem restrição rígida de duplicatas, diferenciada visualmente por cor/insígnia de assento).
- **Escala por `N` jogadores:** Inimigos, chefes, orçamento de onda e recompensas de Fragmentos escalam em função de `N ∈ {1, 2, 3, 4}` por meio de multiplicadores declarados em dados (`CoopTuning`).
- **Queda e Reanimação na câmara:** Quando a Vida de um jogador chega a `0`, a run não termina imediatamente se houver aliados vivos. O jogador entra em **Queda** (com janela limitada e custo crescente de risco) e pode ser **reanimado** por um aliado dentro da mesma câmara. Se todos os jogadores caírem ou morrerem simultaneamente, a run termina.
- **Portas e Bênçãos em grupo:** Ao limpar uma câmara, cada jogador recebe e escolhe sua oferta de bênção de forma independente (ou paralela sem pausar o mundo), enquanto a **escolha da próxima porta** é resolvida por **votação com desempate do host** quando todos os vivos estão prontos.

**Fantasia do jogador (MDA — Fellowship, Challenge, Fantasy):** Descer a Beira lado a lado como Iniciados de Doutrinas complementares, sentir a tensão de segurar uma onda enquanto resgata um aliado caído e coordenar rotas e bênçãos sem perder o ritmo ritualístico do jogo (**P4**).

## Detailed Design

### Core Rules

**R1. Lobby e entrada de jogadores (1 a 4 assentos).**
- O lobby suporta de `1` a `4` jogadores (`N ∈ [1, 4]`), atribuindo a cada participante um `assento_id` estável de `0` (Host) a `3`.
- O host gera um **código de sala** (alfanumérico curto para conexão direta/local ou relay) e define a **seed da run** (automática ou inserida manualmente antes de iniciar).
- A run só pode ser iniciada pelo Host quando todos os jogadores conectados estiverem com estado `Pronto` e com a verificação de catálogo (SHA-256, Sistema #37) aprovada.

**R2. Seleção individual de Iniciado, Doutrina e Meta.**
- Cada jogador seleciona individualmente sua **Arma/Doutrina** (e dupla de Maldições, se Pactos) no lobby antes da descida.
- Cada jogador carrega os modificadores permanentes da sua própria **Oficina de Reforja** (`meta:reforja_*`) e seu próprio portador de atributos (`Modificadores e atributos`).
- Cada assento recebe um marcador visual distinto (contorno/selo de cor de assento `0..3`) para preservar a leitura de posição no caos de combate (**P3**).
- Não há fogo amigo entre jogadores: ataques, Selos e explosões de aliados nunca causam dano ou empurrão em outros jogadores.

**R3. Escala de combate e recompensas por `N` jogadores.**
- O número base de jogadores da run (`N_inicial`) fixa a escala base da câmara, podendo ser recalculado se houver desconexão permanente (ver Sistema #37).
- **Vida de inimigos comuns/elites e chefes** escala por `mult_vida(N)`.
- **Orçamento de onda** escala por `mult_onda(N)`, respeitando o teto de segurança de legibilidade e orçamento visual (`teto_inimigos_coop`).
- **Dano dos inimigos** permanece próximo ao valor solo (ou escala suavemente em `mult_dano(N)`) para manter o princípio de que cada erro individual é legível e cobrado pela Beira (**P2**, **P3**).
- **Fragmentos de Eco:** Cada jogador recebe sua própria conta na run (`coletados_run` individual), com bônus cooperativo moderado (`mult_fragmentos(N)`) ao concluir câmaras e derrotar chefes, creditado apenas aos jogadores que participaram da câmara (vivos ou em Queda/Espectador até a conclusão).

**R4. Política de alvo da IA em co-op.**
- Inimigos e telégrafos deixam de assumir "o único jogador" e selecionam alvo apenas entre jogadores em estado `Vivo`.
- A política padrão de seleção é **alvo mais próximo com histerese** (troca de alvo apenas se outro jogador estiver significativamente mais perto ou causar maior ameaça recente dentro do intervalo de reavaliação), evitando oscilação errática de telégrafos (**P3**).

**R5. Sistema de Queda, Reanimação e Espectador.**
- Quando a Vida de um jogador atinge `0` (após consumir eventuais `recusas_morte`), ele não encerra a run se existir pelo menos outro jogador `Vivo`.
- **Estado `Caído` (Queda):**
  - O jogador fica imóvel no chão no ponto onde caiu, invulnerável a novos golpes inimigos, com um **anel de progresso de Queda** visível a todos os aliados e tempo máximo `tempo_sangramento_s` (ex.: `15.0 s`).
  - Se um aliado `Vivo` permanecer dentro do `raio_reanimacao_px` (`90 px`) segurando `interagir` (`E`/`A`) por `tempo_reanimacao_s` (`2.5 s`, mantendo movimento lento ou parado conforme canalização), o aliado é reanimado com `fracao_vida_pos_reanimacao` (`35%` da `vida_max`) e `invuln_pos_reanimacao_s` (`1.5 s`) de proteção.
  - Múltiplos aliados canalizando juntos aceleram a reanimação (ex.: `+40%` por aliado extra).
  - Ao sofrer múltiplas Quedas na mesma câmara, `tempo_reanimacao_s` aumenta ou `tempo_sangramento_s` reduz conforme `penalidade_queda_repetida` para evitar abuso infinito (**P2**).
- **Estado `Espectador`:**
  - Se `tempo_sangramento_s` zerar antes da reanimação, o jogador passa a **Espectador** até o fim da câmara atual: sua câmera acompanha um aliado `Vivo` (alternável com ataque/botões) e ele não pode agir.
  - Se os aliados `Vivos` limparem a câmara, todos os jogadores em `Caído` ou `Espectador` retornam ao estado `Vivo` na transição/fim da câmara com `fracao_vida_retorno_camara` (`25%` da `vida_max`, ou mínimo `1` HP).
- **Derrota do grupo:** Se **todos** os jogadores estiverem simultaneamente em `Caído` ou `Espectador` (zero jogadores `Vivos`), a run é encerrada imediatamente como **derrota do grupo** (`run_encerrada`, motivo `morte`).

**R6. Bênçãos e ofertas em grupo (sem congelar o mundo).**
- Em co-op online, abrir a tela de bênção ou o menu de pausa **não congela o relógio da simulação** para os demais jogadores.
- Ao receber uma recompensa de bênção (fim de câmara segura, sem inimigos ativos), cada jogador abre sua própria seleção de 3 cartas usando fluxo de RNG indexado por `(regiao, camara, assento_id)` — garantindo ofertas personalizadas à Doutrina/histórico de cada Iniciado (**P1**).
- A transição de portas só é liberada quando **todos os jogadores `Vivos` concluíram sua escolha de bênção** (ou quando o tempo de cortesia pós-escolha expirar, caso `tempo_limite_bencao_s > 0`; por padrão sem pressão agressiva, **P4**, com indicador claro no HUD de quem ainda está escolhendo).

**R7. Votação e escolha de portas em grupo.**
- Após a câmara estar limpa e todas as bênçãos pendentes resolvidas, as portas de saída exibem suas recompensas normalmente.
- Cada jogador `Vivo` vota aproximando-se de uma porta e pressionando `interagir` (`E`/`A`), exibindo seu marcador de assento (`0..3`) acima da porta escolhida. Um jogador pode trocar seu voto antes do travamento.
- **Resolução do voto:**
  - **Maioria simples** vence imediatamente quando todos os jogadores `Vivos` tiverem votado (ou quando uma porta atingir maioria absoluta `> N_vivos / 2` e todos estiverem na zona de saída).
  - **Empate:** Se todos votaram e há empate (ex.: 2 vs 2 ou 1 vs 1), **vence o voto do Host** (ou, se o Host não votou em nenhuma das empatadas, a porta de menor índice determinístico).
  - Após a decisão, todos os jogadores são teleportados em formação de entrada (`spawn_coop_0..3`) para a próxima câmara.

### Formulas

1. **Escala de Vida de inimigos e chefes:**
   $$\text{Vida\_final}(N) = \text{Vida\_base} \times \left(1 + \alpha_{\text{vida}} \cdot (N - 1)\right)$$
   - Padrão (`CoopTuning`): $\alpha_{\text{vida}} = 0.65$ (`1.00x` em $N=1$, `1.65x` em $N=2$, `2.30x` em $N=3$, `2.95x` em $N=4$).

2. **Escala de Orçamento de Onda:**
   $$\text{Orcamento}(p, r, N) = \left\lfloor (3 + 0.9 \cdot p + 2 \cdot r) \times \left(1 + \alpha_{\text{onda}} \cdot (N - 1)\right) \right\rfloor$$
   - Padrão: $\alpha_{\text{onda}} = 0.45$, limitado por `teto_inimigos_coop(N) = 9 + 3 · (N - 1)` (máx. `18` inimigos simultâneos em `N=4`).

3. **Escala de Dano de inimigos:**
   $$\text{Dano\_final}(N) = \text{Dano\_base} \times \left(1 + \alpha_{\text{dano}} \cdot (N - 1)\right)$$
   - Padrão: $\alpha_{\text{dano}} = 0.05$ (praticamente constante, `1.15x` em $N=4$, para preservar a leitura de dano por golpe sem one-shots injustos).

4. **Velocidade de Reanimação com múltiplos aliados ($k \ge 1$ aliados canalizando):**
   $$\text{Progresso/s} = \frac{1 + 0.40 \cdot (k - 1)}{\text{tempo\_reanimacao\_s}}$$

### States and Transitions

| Estado do Jogador | Entra quando | Comportamento | Sai para |
|---|---|---|---|
| **Lobby (Preparação)** | Entra na sala do Host | Escolhe Doutrina/Arma, verifica SHA-256 do catálogo, alterna `Pronto` | **Vivo** (Host inicia run) |
| **Vivo** | Início de run, reanimação ou fim de câmara | Controle completo de movimento, combate, voto de porta e escolha de bênção | **Caído** (`vida == 0` com aliado vivo), **Espectador** ou **Fim de Run** |
| **Caído** | `vida == 0` havendo ao menos 1 aliado `Vivo` | Imóvel, invulnerável, temporizador `tempo_sangramento_s` correndo | **Vivo** (reanimado), **Espectador** (tempo zerado) ou **Fim de Run** (todos caídos) |
| **Espectador** | `tempo_sangramento_s` expirou | Câmera acompanha aliado `Vivo`; sem input de combate | **Vivo** (aliados limpam a câmara) ou **Fim de Run** (todos derrotados) |
| **Fim de Run** | Vitória no chefe final ou zero jogadores `Vivos` | Tela de resumo individual + do grupo; retorno ao Lobby ou Campus | **Lobby** ou **Campus** |

### Interactions with Other Systems

| Sistema | Recebe do Co-op Online | Fornece ao Co-op Online | Dono da interface |
|---|---|---|---|
| **Netcode e sincronização (#37)** | Comandos de voto, reanimação, estado de pronto no lobby | Snapshots autoritativos, lista de peers conectados, eventos de desconexão | Netcode e sincronização |
| **Combate núcleo (#8)** | Multiplicadores de escala por `N`, isenção de fogo amigo | Eventos de `jogador_caiu(id)` e `todos_derrotados` | Combate núcleo |
| **Câmaras e ondas (#16)** | `Orcamento(p, r, N)`, `N` posições de spawn na entrada | Estado de câmara limpa para reviver Espectadores e liberar portas | Câmaras e ondas |
| **Portas e recompensas (#17)** | Votos por `assento_id`, regra de desempate pelo Host | Seleção da porta vencedora e crédito de recompensas | Portas e recompensas |
| **Bênçãos (Tradições) (#19)** | `assento_id` como eixo extra de RNG para oferta individual | Estado `escolha_bencao_concluida(id)` por jogador | Bênçãos (Tradições) |
| **HUD (#28)** | Lista de aliados (`assento_id`, vida, estado `Vivo/Caído/Espectador`, voto) | Painel compacto de até 3 aliados e indicadores de Queda/Reanimação | HUD |

## Tuning Knobs

| Knob | Padrão | Faixa | Categoria | Efeito e racional |
|---|---|---|---|---|
| `alpha_vida_coop` | `0.65` | `0.40–1.00` | Curve | Incremento de vida dos inimigos por jogador adicional; evita que 4 jogadores derretam chefes em segundos sem tornar lutas arrastadas. |
| `alpha_onda_coop` | `0.45` | `0.25–0.75` | Curve | Incremento do orçamento de onda por jogador adicional para manter pressão espacial proporcional. |
| `alpha_dano_coop` | `0.05` | `0.00–0.15` | Curve | Leve ajuste de dano inimigo por jogador; mantém **P3** (ataques telegrafados letais apenas se ignorados repetidamente). |
| `teto_inimigos_coop_base` | `9` | `9–12` | Gate | Teto base para `N=1`, somando `+3` inimigos por jogador extra (máx. `18` em `N=4`) para preservar FPS e legibilidade. |
| `tempo_sangramento_s` | `15.0` | `8.0–25.0` | Gate | Tempo disponível para reanimar um aliado em Queda antes que vire Espectador. |
| `tempo_reanimacao_s` | `2.5` | `1.5–4.0` | Feel | Duração da canalização de resgate; longa o suficiente para exigir janela segura, curta o suficiente para ser viável em combate. |
| `raio_reanimacao_px` | `90.0` | `60.0–130.0` | Feel | Raio de proximidade para iniciar/manter a reanimação de um aliado caído. |
| `fracao_vida_pos_reanimacao` | `0.35` | `0.20–0.50` | Curve | Vida restaurada ao concluir a reanimação dentro da câmara. |
| `mult_fragmentos_coop` | `1.15` | `1.00–1.50` | Curve | Bônus de Fragmentos por câmara/chefe em `N >= 2` para recompensar o risco coordenado. |

## Edge Cases

- **Todos os jogadores caem ao mesmo tempo (último `Vivo` entra em `Caído`):** Como não há ninguém `Vivo` para reanimar, o estado `Caído` do último jogador é imediatamente convertido em derrota do grupo (`run_encerrada`).
- **Jogador desconecta enquanto estava `Caído` ou escolhendo Bênção:** O assento é removido da contagem de `Vivos`/pendentes imediatamente; se os demais já votaram ou escolheram bênção, o fluxo destrava sem esperar o desconectado.
- **Reanimação interrompida por dano ou esquiva:** Se o canalizador sofrer dano ou usar esquiva ou sair de `raio_reanimacao_px`, o progresso da reanimação é interrompido (decai suavemente ou zera) e `tempo_sangramento_s` do caído continua correndo.
- **Empate triplo ou quádruplo na votação de portas:** Como há no máximo 2 ou 3 portas por câmara, em caso de empate sem maioria absoluta, o voto do Host desempatador prevalece; se o Host não votou, escolhe-se a porta de menor índice (`0 < 1 < 2`).
- **Run com `N=1` iniciada pelo fluxo de Lobby:** Usa exatamente os mesmos multiplicadores com `N=1` (`1.0x`), garantindo paridade matemática com o modo solo.

## Dependencies

### Depends On (Upstream)
- **Netcode e sincronização (#37)** — transporte, autoridade do host, snapshots e tratamento de desconexão.
- **Conteúdo orientado a dados (#1)** — recurso `CoopTuning` com os multiplicadores por `N`.
- **RNG com seed (#3)** — fluxos de grupo vs. fluxos indexados por `assento_id`.
- **Combate núcleo (#8)** e **IA de inimigos e elites (#14)** — múltiplas entidades de jogador e política de alvo.

### Depended On By (Downstream)
- **HUD (#28)** — barras de aliados, indicador de Queda/Reanimação, marcadores de voto nas portas.
- **Telemetria local (#35)** — registro de `n_jogadores` e `assento_id` nas métricas de run.

## Acceptance Criteria

- **AC-COOP-01 [I] — Lobby de 1 a 4 jogadores:** GIVEN um Host com sala aberta e código gerado, WHEN até 3 clientes conectam e selecionam suas Doutrinas individualmente, THEN todos aparecem no lobby com `assento_id` único (`0..3`) e podem marcar `Pronto` para iniciar a run.
- **AC-COOP-02 [L] — Escala por `N` jogadores:** GIVEN uma câmara de combate iniciada com `N=3` jogadores, WHEN os inimigos são instanciados, THEN a vida de cada inimigo é `Vida_base * (1 + 0.65 * 2)` (`2.30x`) e o orçamento de onda segue `Orcamento(p, r, 3)`.
- **AC-COOP-03 [L] — Queda e Reanimação:** GIVEN `N >= 2` jogadores `Vivos`, WHEN um jogador chega a `0` de Vida, THEN ele entra em estado `Caído` (não encerra a run) e, se um aliado canalizar por `tempo_reanimacao_s` dentro de `raio_reanimacao_px`, retorna ao estado `Vivo` com `35%` de vida.
- **AC-COOP-04 [L] — Sangramento e retorno pós-câmara:** GIVEN um jogador `Caído` cujo `tempo_sangramento_s` expira, WHEN ele passa para `Espectador` e os aliados limpam a câmara, THEN ele retorna ao estado `Vivo` com `25%` de vida antes da escolha de portas.
- **AC-COOP-05 [L] — Derrota total do grupo:** GIVEN zero jogadores no estado `Vivo` (todos `Caído` ou `Espectador`), WHEN o último `Vivo` cai, THEN a run encerra imediatamente para todos com motivo `morte`.
- **AC-COOP-06 [I] — Votação de portas com desempate:** GIVEN 4 jogadores vivos votando em 2 portas (empate 2 a 2), WHEN todos os votos são registrados, THEN vence a porta escolhida pelo Host e todos os jogadores transicionam juntos para a próxima câmara.
- **AC-COOP-07 [I] — Bênção individual sem pausa global:** GIVEN 2 jogadores escolhendo bênçãos ao fim de uma câmara, WHEN o jogador 0 confirma sua carta antes do jogador 1, THEN o jogador 0 volta ao controle local aguardando o jogador 1 concluir sua escolha antes da liberação das portas.
