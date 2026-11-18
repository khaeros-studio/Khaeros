# Netcode e Sincronização

> **Status**: Designed
> **Author**: game-designer (Alpha)
> **Created**: 2026-11-18
> **Last Updated**: 2026-11-18
> **Sistema**: #37 · Category: `Core` · Priority: `Alpha`
> **Implements Pillar**: P3 *Reflexo que se lê*; P2 *A Beira cobra*; P4 *Ritual, não pressão*

## Summary

O sistema de **Netcode e Sincronização** estabelece o modelo **Host Autoritativo** para sessões cooperativas de 1 a 4 jogadores em Khaeros. O Host executa a simulação de combate determinística a **60 Hz** e transmite snapshots compactos de estado aos clientes entre **20 e 30 Hz**. Os clientes enviam pacotes de input, realizam predição local de movimento/esquiva e interpolam entidades remotas usando um **buffer de jitter** adaptativo. Antes da descida, o lobby valida a **impressão SHA-256** do catálogo de conteúdo (`ContentCatalog`) entre todos os participantes, garantindo paridade de dados e tratamento previsível de desconexões dentro da latência alvo **< 150 ms**.

> **Quick reference** — Layer: `Core` · Priority: `Alpha` · Key deps: `Co-op online (#36), Conteúdo orientado a dados (#1), RNG com seed (#3), Input e controle (#4), Combate núcleo (#8), Run e regiões (#18)`

## Overview

Em um roguelike de ação com janelas curtas de esquiva e telégrafos no chão (**P3 *Reflexo que se lê***), a divergência de estado entre jogadores destrói a confiança no combate. O modelo **Host Autoritativo** centraliza a verdade da simulação no computador do Host sem exigir servidores dedicados externos na fase Alpha.

- **Simulação 60 Hz no Host:** Toda decisão de dano, colisão, spawn de ondas, RNG de câmara, estado de telégrafos e votos de porta é resolvida exclusivamente pelo Host em ticks fixos de `1/60 s` (`16,67 ms`).
- **Snapshots 20–30 Hz:** O Host envia deltas/snapshots de estado para os clientes na taxa configurável (`20 Hz` padrão econômico, `30 Hz` padrão alta responsividade), reduzindo consumo de banda sem perder suavidade visual.
- **Verificação SHA-256 no lobby:** Ao entrar na sala, o cliente envia o hash SHA-256 do seu `ContentCatalog` (e versão de protocolo). Qualquer divergência bloqueia o estado `Pronto` com mensagem clara antes da run começar.
- **Buffer de jitter e interpolação:** Clientes mantêm um pequeno buffer de recebimento (`jitter_buffer_ms`) para absorver variações de rede e interpolar posições de aliados, inimigos e projéteis entre os dois últimos snapshots válidos.
- **Latência alvo (< 150 ms) e desconexão:** O sistema é calibrado para RTT `< 150 ms`, oferece tolerância a microquedas (`timeout_desconexao_s`) e trata queda de cliente (remoção limpa do assento) ou queda do Host (encerramento seguro da sessão preservando Fragmentos já consolidados).

**Fantasia técnica e do jogador (MDA — Sensation, Challenge):** Sentir que a esquiva e o golpe respondem instantaneamente mesmo online, com telégrafos de inimigos e posições de aliados sempre legíveis e livres de "teleportes" bruscos.

## Detailed Design

### Core Rules

**R1. Topologia Host Autoritativo.**
- O jogador `assento_id = 0` atua como **Host** (servidor + cliente local). Os demais jogadores (`assento_id = 1..3`) são **Clientes**.
- O Host roda o loop autoritativo de simulação a **60 Hz** (`dt_fixo = 1/60 s`), consumindo os inputs locais no mesmo tick e os inputs remotos recebidos no buffer de entrada de cada cliente.
- Clientes **nunca** autorizam dano em inimigos, consumo de Fragmentos ou avanço de câmara; eles apenas enviam intenções de input (`InputFrame`) e renderizam o estado confirmado com predição local controlada.

**R2. Handshake de lobby e verificação SHA-256 do catálogo.**
- Ao solicitar entrada no lobby via código/convite, o cliente envia: `versao_protocolo`, `hash_catalogo_sha256` (calculado sobre os recursos ativos do `ContentCatalog`) e dados do Iniciado/Doutrina selecionada.
- O Host compara `hash_catalogo_sha256` com o próprio hash:
  - **Igual:** Conexão aceita; assento `1..3` atribuído.
  - **Diferente:** Conexão recusada imediatamente com código `ERR_CATALOGO_DIVERGENTE`, impedindo dessincronização silenciosa de status, armas ou inimigos.
- Durante o lobby, mudanças de Doutrina, Maldições ou estado `Pronto` usam mensagens confiáveis e ordenadas (*reliable ordered*).

**R3. Fluxo de Input (Cliente → Host) e Snapshots (Host → Cliente).**
- **Upstream (Cliente → Host, 60 Hz):** Cada cliente amostra seu `InputFrame` (vetor movimento, direção de mira, flags de ataque/esquiva/selo/interagir, `tick_cliente`) e envia em canal não-confiável sequenciado (*unreliable sequenced*) com redundância dos últimos `k` frames para mitigar perda pontual de pacotes.
- **Downstream (Host → Cliente, 20–30 Hz):** A cada `2` ou `3` ticks de simulação (`30 Hz` ou `20 Hz`), o Host emite um **Snapshot** contendo:
  - `tick_host`, `ack_input_cliente[0..3]`
  - Estado dos jogadores (posição, velocidade, estado `Vivo/Caído/Espectador`, vida, fluxo, cargas de esquiva)
  - Estado dos inimigos ativos (id de instância, posição, estado de IA, vida, fase de telégrafo)
  - Eventos discretos críticos (spawn, morte, abertura de porta, bênção liberada) via canal confiável (*reliable*).

**R4. Predição local e reconciliação.**
- O cliente aplica seu próprio movimento e início de esquiva **imediatamente** no quadro local (zero atraso percebido para o jogador local) e guarda o histórico no buffer de predição por `tick_cliente`.
- Ao receber um snapshot com `ack_input_cliente`, o cliente compara a posição autoritativa do Host com a posição predita para aquele mesmo tick:
  - Se o erro for `<= limiar_correcao_suave_px` (`4 px`): ignora ou suaviza imperceptivelmente.
  - Se o erro for `> limiar_correcao_suave_px` e `<= limiar_snap_px` (`48 px`): interpola a correção ao longo de `tempo_reconciliacao_s` (`0.10 s`).
  - Se o erro for `> limiar_snap_px`: aplica correção direta (snap) para alinhar imediatamente com a verdade do Host.

**R5. Buffer de Jitter e Interpolação de entidades remotas.**
- Aliados remotos, inimigos e projéteis são renderizados no passado recente (`t_render = t_servidor_estimado - atraso_interpolacao_s`), alimentados por um **buffer de jitter** que armazena snapshots recentes.
- O `atraso_interpolacao_s` combina o intervalo entre snapshots (`1 / taxa_snapshot_hz`) mais uma margem de jitter adaptativa (`jitter_buffer_ms`, padrão `35 ms`, faixa `20–80 ms`).
- Se um pacote atrasar além do buffer, o cliente extrapola linearmente por no máximo `max_extrapolacao_ms` (`60 ms`) antes de congelar a entidade suavemente até o próximo snapshot.

**R6. Latência alvo e telemetria de rede.**
- A experiência é projetada para **RTT < 150 ms**.
- Entre `150 ms` e `250 ms`, o cliente recebe indicador discreto de latência elevada no HUD e o buffer de jitter expande até o teto configurado (`80 ms`).
- Acima de `250 ms` sustentados ou perda de pacotes > `10%`, exibe-se alerta de conexão instável sem interromper automaticamente o jogo, exceto em caso de timeout.

**R7. Tratamento de desconexão e reconexão.**
- **Desconexão de Cliente (`assento_id > 0`):**
  - Se não houver pacotes por `timeout_aviso_s` (`3.0 s`), o jogador é marcado como `Instável` no HUD.
  - Se atingir `timeout_desconexao_s` (`10.0 s`) ou encerramento explícito de socket, o cliente é removido da sessão, seu avatar é retirado da câmara de forma limpa, eventuais votos/bênçãos pendentes são destravados e a escala `N` passa a valer para os restantes a partir da **próxima câmara** (evitando alteração brusca de vida no meio de uma luta).
  - **Reconexão na mesma run (Alpha+ / opcional controlado):** Se o assento desconectado reconectar com o mesmo token de sessão antes do fim da run, pode retomar como `Espectador` na câmara atual e voltar a `Vivo` na câmara seguinte.
- **Desconexão do Host (`assento_id == 0`):**
  - Como o modelo da Alpha é Host Autoritativo sem migração de Host em tempo real, a queda do Host encerra a sessão cooperativa para os clientes conectados após `timeout_desconexao_s`, exibindo tela de **"Conexão com o Host perdida"** e retornando cada jogador ao seu próprio Campus com os **Fragmentos já consolidados** antes da queda preservados.

### Formulas

1. **Intervalo de Snapshot:**
   $$T_{\text{snap}} = \frac{1000}{\text{taxa\_snapshot\_hz}} \quad [\text{ms}]$$
   - A `20 Hz`: $T_{\text{snap}} = 50\text{ ms}$; a `30 Hz`: $T_{\text{snap}} = 33.3\text{ ms}$.

2. **Atraso total de interpolação de entidades remotas:**
   $$D_{\text{interp}} = T_{\text{snap}} + \text{jitter\_buffer\_ms}$$
   - Exemplo padrão (`30 Hz` + `35 ms` de jitter): $D_{\text{interp}} = 33.3 + 35 = 68.3\text{ ms}$ (mantendo responsividade confortável abaixo do limite de `150 ms`).

3. **Orçamento de ticks no buffer de jitter adaptativo:**
   $$\text{jitter\_buffer\_ms} = \text{clamp}\left(2 \times \sigma_{\text{RTT}},\; \text{jitter\_min\_ms},\; \text{jitter\_max\_ms}\right)$$

### States and Transitions

| Estado de Rede | Entra quando | Comportamento | Sai para |
|---|---|---|---|
| **Desconectado** | Jogo no Campus solo ou sem sessão | Sem transporte ativo; simulação 100% local | **Handshaking** (entrar/criar lobby) |
| **Handshaking** | Cliente solicita entrada no código da sala | Troca `versao_protocolo` e `hash_catalogo_sha256` | **Lobby Conectado** (hash igual) ou **Rejeitado** (hash divergente) |
| **Lobby Conectado** | Handshake aprovado | Sincroniza assentos, Doutrinas e `Pronto` via canal confiável | **Em Run (Sincronizado)** (Host inicia descida) |
| **Em Run (Sincronizado)** | Run iniciada | Host simula 60 Hz e envia snapshots 20–30 Hz; clientes predizem/interpolam | **Instável** (sem pacotes > `3 s`) ou **Desconectado** (fim de run) |
| **Instável** | Silêncio de rede > `timeout_aviso_s` | Exibe ícone de alerta; expande `jitter_buffer_ms` | **Em Run** (pacotes retomam) ou **Sessão Encerrada / Removido** (`> timeout_desconexao_s`) |

### Interactions with Other Systems

| Sistema | Recebe do Netcode | Fornece ao Netcode | Dono da interface |
|---|---|---|---|
| **Co-op online (#36)** | Lista de assentos ativos, eventos de desconexão, ping/RTT | Votos de porta, estado `Pronto`, comandos de reanimação | Co-op online |
| **Conteúdo orientado a dados (#1)** | Solicitação de assinatura do catálogo no handshake | `hash_catalogo_sha256` determinístico do `ContentCatalog` | Conteúdo orientado a dados |
| **Input e controle (#4)** | `InputFrame` remoto (no Host) e sinal de reconciliação | Amostragem de `InputFrame` local a 60 Hz | Input e controle |
| **RNG com seed (#3)** | Seed única da run definida pelo Host no lobby | Garantia de geração determinística de câmaras e bênçãos | RNG com seed |
| **HUD (#28)** | RTT atual, alerta de latência `>= 150 ms` / desconexão | Exibição discreta de ping e status de conexão dos aliados | HUD |

## Tuning Knobs

| Knob | Padrão | Faixa | Categoria | Efeito e racional |
|---|---|---|---|---|
| `taxa_simulacao_hz` | `60` | `60` (fixo) | Gate | Mantém paridade exata com o passo fixo de combate do MVP (`16,67 ms`). |
| `taxa_snapshot_hz` | `30` | `20–30` | Feel | Frequência de envio de snapshots do Host; `30 Hz` prioriza fluidez de telégrafos, `20 Hz` reduz banda em conexões modestas. |
| `jitter_buffer_ms` | `35` | `20–80` | Feel | Folga temporal para absorver variação de chegada de pacotes sem engasgos visuais. |
| `max_extrapolacao_ms` | `60` | `30–100` | Feel | Limite de extrapolação linear quando um snapshot atrasa, evitando que inimigos atravessem paredes. |
| `limiar_correcao_suave_px` | `4.0` | `2.0–8.0` | Feel | Zona morta de reconciliação para evitar micro-tremores na posição local. |
| `limiar_snap_px` | `48.0` | `32.0–72.0` | Feel | Distância a partir da qual a correção deixa de ser interpolada e aplica snap direto. |
| `latencia_alerta_ms` | `150` | `120–200` | Gate | Limite alvo de latência saudável; acima disso o HUD sinaliza degradação. |
| `timeout_aviso_s` | `3.0` | `2.0–5.0` | Gate | Tempo sem pacotes para marcar peer como `Instável`. |
| `timeout_desconexao_s` | `10.0` | `6.0–20.0` | Gate | Tempo sem pacotes para declarar desconexão definitiva e liberar o grupo. |

## Edge Cases

- **Divergência de `ContentCatalog` (mod ou versão desatualizada):** Bloqueada no handshake (`ERR_CATALOGO_DIVERGENTE`) antes da entrada no lobby, impedindo crashes por IDs inexistentes ou dessincronização de dano.
- **Pacotes duplicados ou fora de ordem no canal `unreliable`:** Cada `InputFrame` e `Snapshot` carrega número de sequência monotônico (`tick_cliente` / `tick_host`); pacotes com sequência menor ou igual à última processada são descartados.
- **Cliente com FPS variável (< 60 ou > 60 FPS):** A simulação e a amostragem de `InputFrame` rodam sempre no passo físico fixo de `60 Hz` (`_physics_process`), desacopladas da taxa de renderização.
- **Congelamento momentâneo do sistema operacional do Host (alt-tab ou spike):** Ao retomar, o Host não tenta simular dezenas de ticks acumulados de uma só vez (cap de `max_ticks_por_quadro`), evitando teleportes de inimigos para todos os clientes.
- **Desconexão durante transição de câmara:** Se um cliente cair durante o fade entre câmaras, o Host remove o assento antes de iniciar as ondas da nova câmara, ajustando `N` para os jogadores restantes.

## Dependencies

### Depends On (Upstream)
- **Conteúdo orientado a dados (#1)** — cálculo do SHA-256 do catálogo de conteúdo.
- **Input e controle (#4)** — serialização do `InputFrame` por jogador.
- **RNG com seed (#3)** — seed compartilhada da run enviada no início.

### Depended On By (Downstream)
- **Co-op online (#36)** — transporte de lobby, combate, votação de portas e reanimação.
- **HUD (#28)** — indicador de latência e alertas de desconexão.

## Acceptance Criteria

- **AC-NET-01 [L] — Simulação 60 Hz e Snapshots 20–30 Hz:** GIVEN uma sessão ativa com 2 a 4 jogadores, WHEN o combate ocorre na câmara, THEN o Host avança a simulação a `60 Hz` e emite snapshots configurados entre `20 Hz` e `30 Hz`.
- **AC-NET-02 [I] — Verificação SHA-256 no lobby:** GIVEN um cliente com `ContentCatalog` alterado (hash diferente do Host), WHEN tenta entrar no lobby, THEN a conexão é recusada com `ERR_CATALOGO_DIVERGENTE` antes de ocupar um assento.
- **AC-NET-03 [L] — Buffer de jitter e interpolação:** GIVEN pacotes de snapshot chegando com jitter simulado de `±25 ms` dentro de RTT `< 150 ms`, WHEN o cliente renderiza aliados e inimigos, THEN o buffer de jitter absorve a variação sem retrocessos bruscos de posição.
- **AC-NET-04 [I] — Desconexão limpa de cliente:** GIVEN um cliente que perde conexão por mais de `timeout_desconexao_s` (`10 s`), WHEN o timeout expira no Host, THEN o assento é liberado, o avatar sai da câmara e votações/bênçãos pendentes dos demais continuam normalmente.
- **AC-NET-05 [I] — Queda do Host:** GIVEN uma desconexão abrupta do Host (`assento_id == 0`), WHEN o timeout expira nos clientes, THEN os clientes encerram a sessão com aviso claro e retornam ao Campus local sem corromper o `Save`.
- **AC-NET-06 [L] — Alerta de latência acima do alvo:** GIVEN RTT sustentado `>= 150 ms`, WHEN a sessão está em curso, THEN o HUD exibe o indicador de latência elevada sem travar o loop de input local.
