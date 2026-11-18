# ADR-0019: Co-op Online (1–4 jogadores) e Netcode/Sincronização

## Status
Accepted · 2026-11-18 (aprovado para a fase Alpha do Khaeros)

## Date
2026-11-18

## Last Verified
2026-11-18 (alinhado ao Godot 4.7.2, `ADR-0001` Orquestrador do Passo 60 Hz e `ADR-0005` RNG Determinístico `mulberry32`)

## Decision Makers
Usuário (khaeros-studio) e `technical-director`.

## Summary
Define a arquitetura de rede para o **Co-op Online (1–4 jogadores)** e **Netcode/Sincronização** na fase Alpha: topologia **Host Autoritativo** sobre `ENetMultiplayerPeer` (1 host + até 3 clientes, sem servidor dedicado obrigatório), handshake de integridade por impressão **SHA-256 do `Catalogo`**, envio de `ComandosDoPasso` compactos a **60 Hz** com snapshots delta autoritativos a **20–30 Hz** e interpolação na camada de apresentação, posse exclusiva da `FonteDeFluxos` (`mulberry32`) no host com replicação por evento tipado, e regras estritas de isolamento de rede em `src/foundation/rede/` (proibindo `MultiplayerSynchronizer` em lógica pura).

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Godot 4.7 (pin 4.7.2) |
| **Domain** | Multiplayer / Networking (`ENetMultiplayerPeer`, `SceneMultiplayer`) |
| **Layer** | Foundation (`src/foundation/rede/`) + Apresentação |
| **Knowledge Risk** | MEDIUM — `ENetMultiplayerPeer` e `MultiplayerAPI` são estáveis no Godot 4.x; empacotamento binário e jitter buffer exigem testes de latência em Alpha |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `ADR-0001`, `ADR-0004`, `ADR-0005` |
| **Post-Cutoff APIs Used** | Nenhuma API exclusiva pós-corte; usa `ENetMultiplayerPeer` padrão do Godot 4.7.2 |
| **Verification Required** | (1) Handshake SHA-256 recusando cliente divergente antes de `JOGO`; (2) `OrquestradorDoPasso` a 60 Hz no host consumindo `ComandosDoPasso` com buffer de jitter; (3) Snapshots delta a 20–30 Hz com interpolação fluida no cliente sem tocar lógica pura; (4) Queda de cliente e queda de host com `Save` íntegro |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | [ADR-0001](adr-0001-orquestrador-do-passo.md) (`OrquestradorDoPasso` 60 Hz, `RefCounted`), [ADR-0004](adr-0004-catalogo-de-dados.md) (impressão SHA-256 do `Catalogo`), [ADR-0005](adr-0005-rng-deterministico.md) (`FonteDeFluxos` / `mulberry32`) |
| **Enables** | Implementação dos Sistemas 36 (`Co-op online`) e 37 (`Netcode e sincronização`) no Alpha |
| **Blocks** | Épicos e stories de lobby, replicação de combate/câmaras e tolerância a desconexões |
| **Ordering Note** | Estende o ciclo do passo de `ADR-0001` e a posse de RNG de `ADR-0005` para o modo multi-jogador sem quebrar o modo solo (1 jogador local) |

## Context

### Problem Statement
Os sistemas **36 (`Co-op online`)** e **37 (`Netcode e sincronização`)** de `systems-index.md` introduzem suporte a partidas cooperativas de 1 a 4 jogadores na fase Alpha. Sem uma fronteira arquitetural explícita:
- A lógica pura (`RefCounted`, sem `SceneTree`, `ADR-0001`) corre o risco de ser contaminada por nós de rede do Godot (`MultiplayerSynchronizer`, `@rpc` espalhados em entidades).
- Divergências de dados de `Catalogo` ou de consumo de RNG (`mulberry32`, `ADR-0005`) entre pares causariam dessincronização silenciosa de ondas, portas, ofertas e combate.
- A ausência de política para entrada, saída e queda de host comprometeria o progresso da câmara e a integridade do perfil salvo (`Save`).

### Constraints
- Simulação fixa de **60 Hz** no `OrquestradorDoPasso` (`ADR-0001`).
- Lógica de jogo 100% pura em `RefCounted`, sem `SceneTree`, sem singletons e testável em memória (`ADR-0001`).
- Determinismo estrutural e de combate regido por `FonteDeFluxos` (`mulberry32`, `ADR-0005`).
- Escopo Alpha sem infraestrutura de servidor dedicado obrigatório.

## Decision

### 1. Topologia Host Autoritativo (`ENetMultiplayerPeer`)
- O jogo adota topologia **Host Autoritativo** sobre `ENetMultiplayerPeer` do Godot 4.7.2: **1 host** (jogador-servidor que também participa da run) e **até 3 clientes** (total de 1–4 jogadores).
- **Zero servidor dedicado obrigatório no Alpha**: toda a simulação autoritativa roda no processo do host.
- O módulo de rede é injetado no ponto de composição (`Main`) e encapsulado em `src/foundation/rede/`. No modo solo (1 jogador), o adaptador de rede opera em modo nulo/local sem overhead de serialização ENet.

### 2. Handshake de Catálogo no Lobby
- Antes de iniciar a run (transição de lobby para `JOGO`), o cliente envia sua versão e a **impressão SHA-256 do `Catalogo`** (`ADR-0004`).
- O host compara a impressão recebida com a própria:
  - Se coincidir, o peer é aceito no lobby e recebe o manifesto de sessão.
  - Se divergir (versão, modificação ou corrupção de dados), o host **recusa a entrada imediatamente** com código de motivo explícito antes da criação da run.

### 3. Sincronização do Passo Fixo (60 Hz) e Snapshots Delta (20–30 Hz)
- **Fluxo Cliente → Host (60 Hz):** A cada passo físico, os clientes capturam suas entradas locais e enviam `ComandosDoPasso` compactos contendo:
  - `passo_alvo` (timestamp inteiro de passo),
  - direção de movimento quantizada,
  - vetor/ângulo de mira quantizado,
  - máscara de bits dos botões/ações.
- **Execução Autoritativa no Host (60 Hz):** O host recebe os `ComandosDoPasso` (com pequeno buffer de jitter por peer), injeta-os nos respectivos Iniciados e executa o `OrquestradorDoPasso` autoritativo a 60 Hz.
- **Fluxo Host → Clientes (20–30 Hz):** O host serializa e transmite **snapshots delta** do estado das entidades e da câmara/run na cadência configurável de **20–30 Hz** (a cada 2 ou 3 passos físicos).
- **Interpolação nos Clientes:** Os clientes **não** simulam combate autoritativo paralelo que diverge do host; a camada de Apresentação nos clientes aplica interpolação sobre os snapshots recebidos para manter renderização suave entre pacotes, preservando a separação estrita entre lógica pura e Apresentação (`ADR-0001`).

### 4. RNG Determinístico Compartilhado (`FonteDeFluxos`)
- O **host detém exclusivamente a `FonteDeFluxos` da run** (`mulberry32`, `ADR-0005`).
- Clientes nunca avançam fluxos estruturais ou de oferta por conta própria.
- Todos os sorteios críticos — **ondas, portas, ofertas de bênçãos, raridade e encontros** — são executados e autorizados pelo host, e seus resultados são **replicados aos clientes por eventos tipados** pelo canal de rede.

### 5. Escala de Dificuldade e Política de Desconexão
- **Escala por número de jogadores:** A vida máxima dos inimigos (e parâmetros escaláveis definidos pelo GDD) escala conforme o número de jogadores ativos na sessão no início da câmara/encontro.
- **Desconexão de cliente:** A saída ou queda de um cliente remove seu `Iniciado` da simulação ativa de forma limpa, libera eventuais travas de alvo/interação e **não trava a câmara** (a progressão continua normalmente com os jogadores restantes).
- **Queda do host:** Como o host detém a autoridade da sessão, a queda/desconexão do host **encerra a sessão cooperativa** de forma graciosa nos clientes, garantindo o **salvamento seguro do perfil (`Save`)** local de cada jogador antes de retornar ao `MENU`.

## Consequences

### Positive
- Preserva integralmente a arquitetura de lógica pura em `RefCounted` (`ADR-0001`) e o determinismo centralizado de `mulberry32` (`ADR-0005`).
- Elimina custo operacional e complexidade de servidores dedicados na fase Alpha.
- Garante paridade de dados antes do início da run via handshake SHA-256 do `Catalogo`.
- Reduz banda de rede ao separar entrada compacta (60 Hz) de snapshots delta (20–30 Hz).

### Negative / Trade-offs
- Experiência sujeita à qualidade de conexão e disponibilidade do jogador-host (sem migração de host no Alpha).
- Clientes remotos percebem latência de entrada proporcional ao RTT até a chegada do snapshot autoritativo (mitigável com predição visual leve de movimento local se necessário após validação em playtest).

### Performance Implications
- **Banda:** `ComandosDoPasso` compactos (~8–16 bytes de payload útil por passo a 60 Hz) mantêm o tráfego de subida baixo; snapshots delta a 20–30 Hz limitam o tráfego de descida do host para até 3 clientes dentro do orçamento de conexões residenciais.
- **CPU:** Serialização binária explícita em `src/foundation/rede/` evita reflexão pesada de nós da `SceneTree` no loop de 60 Hz.

## Alternatives Considered
1. **Servidor Dedicado Autoritativo no Alpha:** Rejeitado por exigir infraestrutura de hospedagem, matchmaking dedicado e empacotamento headless prematuros para o escopo Alpha.
2. **Lockstep Puro (Determinístico P2P) em todos os pares:** Rejeitado porque qualquer micro-divergência de ponto flutuante entre plataformas/builds travaria a simulação inteira e tornaria o jitter de 1 jogador um gargalo de frame rate para todos os 4.
3. **Replicação direta via `MultiplayerSynchronizer` nos nós de jogo:** Rejeitado por violar `ADR-0001` (acoplaria lógica pura à `SceneTree`, quebraria testes em memória e impediria controle fino de deltas e eventos tipados).

## Control Manifest (Regras de Controle)

Regras obrigatórias derivadas deste ADR para todos os módulos e stories:

1. **PROIBIDO `MultiplayerSynchronizer` em lógica pura:** Nenhum módulo de lógica pura (`RefCounted`) pode depender de `MultiplayerSynchronizer`, `MultiplayerSpawner` ou anotações `@rpc` diretas em entidades de simulação.
2. **Fronteira única de rede (`src/foundation/rede/`):** Toda criação de peer (`ENetMultiplayerPeer`), handshake, serialização de `ComandosDoPasso`, envio de snapshots delta e eventos tipados de rede passa exclusivamente pela camada dedicada em `src/foundation/rede/`.
3. **Host único dono do `OrquestradorDoPasso` e da `FonteDeFluxos`:** Clientes nunca executam sorteios estruturais (`ADR-0005`) nem resolvem combate autoritativo; qualquer estado exibido no cliente provém de snapshot ou evento tipado emitido pelo host.
4. **Handshake obrigatório antes de `JOGO`:** Nenhuma run cooperativa inicia sem validação bem-sucedida da impressão SHA-256 do `Catalogo`.
5. **Tolerância a falhas e `Save` íntegro:** Remoção de cliente não pode bloquear conclusão de câmara; queda do host deve disparar encerramento limpo com persistência segura do `Save` antes da volta ao `MENU`.

## Validation Criteria
Saberemos que esta decisão foi bem-sucedida no Alpha quando:
- 4 instâncias conectadas via `ENetMultiplayerPeer` completarem uma run sem dessincronização de ondas, portas ou ofertas.
- Um cliente com `Catalogo` alterado for recusado no lobby antes de entrar em `JOGO`.
- A desconexão abrupta de 1 cliente no meio de uma câmara permitir que os demais concluam a câmara e avancem normalmente.
- A queda abrupta do host retornar os clientes ao `MENU` sem corrupção do `Save` local.
