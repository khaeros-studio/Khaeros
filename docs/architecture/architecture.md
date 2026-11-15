# Khaeros — Master Architecture

## Document Status
- Version: 1.10
- Last Updated: 2026-11-14 (v1.10: primeira fatia jogável integrada por pedido explícito; v1.9: Movimento; v1.8: Cena/câmera; v1.7: Input; v1.6: RNG; v1.5: catálogo; v1.4: entidades; v1.3: co-op; v1.2: eventos; v1.1: hitstop e orquestrador)
- Engine: Godot 4.7.2 (pin 4.7), GDScript, Forward+ (D3D12 padrão no Windows)
- Review mode: lean
- GDDs Covered (22 de 22 do MVP): conteudo-orientado-a-dados, rng-com-seed, input-e-controle, cena-3-4-e-camera, pipeline-visual, modificadores-e-atributos, movimento-e-esquiva, combate-nucleo, armas-das-doutrinas, selo-e-fluxo, efeitos-de-status, telegrafos, ia-de-inimigos-e-elites, camaras-e-ondas, portas-e-recompensas, run-e-regioes, bencaos-tradicoes, economia-de-fragmentos, hud, tela-de-bencao-e-carta, feedback-de-combate, telemetria-local
- ADRs Referenced: ADR-0001, ADR-0002, [ADR-0003](adr-0003-entidades-e-portadores.md), [ADR-0004](adr-0004-catalogo-de-dados.md), [ADR-0005](adr-0005-rng-deterministico.md), [ADR-0006](adr-0006-input-por-passo.md), [ADR-0007](adr-0007-cena-viewport-e-camera.md) e [ADR-0008](adr-0008-movimento-e-colisao-propria.md), todos Proposed. 8 existentes, 6 por escrever (14 necessários, ver "Required ADRs")
- Technical Requirements Baseline: 233 requisitos, todos **provisórios** (TR registry vazio; os IDs `TR-<sistema>-NNN` só viram permanentes em `/architecture-review`)
- TD-ARCHITECTURE: 2026-11-13 — skipped — lean mode (nenhum diretor revisou esta arquitetura)
- LP-FEASIBILITY: 2026-11-13 — skipped — lean mode (nenhum diretor revisou esta arquitetura)

> **Limite da extração dos requisitos:** a leitura do `pipeline-visual` não cobriu Formulas (F1–F10), Edge Cases, Dependencies nem Acceptance Criteria; a dos GDDs de dados, RNG, IA, câmaras, portas, telemetria, run, bênçãos e economia não cobriu Edge Cases nem Acceptance Criteria. Requisitos dessas seções podem faltar na linha de base; `/architecture-review` revalida.

## Engine Knowledge Gap Summary

### Estado de implementação — 2026-11-14

O pedido explícito do usuário “faça a integração do jogo” autorizou avançar da preparação para uma primeira fatia executável. `scenes/main.tscn` agora é a cena inicial, com módulos novos em `src/app`, `src/foundation`, `src/gameplay` e `src/presentation`. Integra Lâmina, controles/buffer, movimento/colisão, câmera, dois inimigos, três ondas, bênçãos e telas. [Como jogar e limites](../COMO-JOGAR.md); [evidência](../../production/qa/evidence/integracao-jogavel/README.md).

Os ADRs continuam Proposed: a autorização para implementar esta fatia não promove automaticamente seu status nem declara todos os requisitos atendidos. `GameSession` é uma composição de combate/IA/ondas para a integração inicial, ainda a separar conforme os contratos completos. Dados usam JSON validado e impressão do arquivo, não o catálogo `.tres`/hash canônico; RNG próprio cobre espera de IA, não os oito fluxos. Bênçãos são explícitas, sem sistema geral de modificadores. Arte e camadas visuais são provisórias; não há Selo/Fluxo, Ressonância, áudio final, persistência ou remapeamento. O protótipo anterior foi preservado.

O modelo conhece a engine até ~4.3. Fontes: `docs/engine-reference/godot/`.

**Risco ALTO** (conferir a referência antes de decidir):
- **Rendering 2D** (pipeline-visual, cena-3-4-e-camera, feedback-de-combate): linhas de `CanvasItem` sem feather (4.7), D3D12 padrão no Windows (4.6), Shader Baker (4.5), `LinearToSRGB` sem clamp (4.7).
- **UI e Input** (hud, tela-de-bencao-e-carta, input-e-controle): foco duplo mouse/teclado-gamepad (4.6); `InputEvent.device` de mouse e teclado deixa de ser `0` (4.7); `Control.offset_transform_*` (4.7).
- **GDScript** (todo o código): em 4.7 um `override` de método com retorno tipado herda o tipo e exige `return` explícito (**quebra**); escrita em elemento de packed array não chama o setter (4.7); `@abstract` (4.5).

**Risco MÉDIO**: `duplicate_deep()` (4.5) no catálogo; `FileAccess.store_*` retornam `bool` (4.4); interpolação de física 2D e `reset_physics_interpolation()`.

**Risco BAIXO**: Physics 2D (inalterada), Audio, Animation 2D. Navigation não é usada (a IA é movimento direto, sem pathfinding).

**NOT SOURCEABLE** (não coberto por `docs/engine-reference/`; qualquer decisão que dependa disso nasce "a verificar", nunca como fato):
- Experimentos **E1–E7** do Pipeline visual: contagem de draw calls 2D, LUT como `global uniform sampler2D` em `canvas_item` com Shader Baker (E2), `speed_scale` 0 em emissores, SDF do telégrafo, `CanvasGroup` e `fit_margin`, `Line2D` × SDF, material único por entidade.
- "Sinal de fim de quadro" do 4.7 que o AC-92 do Combate exige (latência toque→golpe ≤ 50 ms).
- Flush e append do `FileAccess` (telemetria).
- `ResourceLoader` síncrono vs threaded.
- Interpolação de física **2D** (a referência só descreve a reestruturação da 3D, 4.5); pillarbox em runtime.

**NEEDS VERIFICATION**: `HashingContext`, importador CSV `keep` (4.7.2), semântica de `SceneTree.paused`, contagem de draw calls 2D em runtime.

## System Layer Map

```
┌───────────────────────────────────────────────────────────────┐
│ APRESENTAÇÃO  (só lê eventos e estado; nunca escreve em jogo) │
│  HUD · Tela de bênção+carta · Feedback de combate (VFX)       │
│  Pipeline visual* · Telemetria local*     [VS: Áudio, Menus,  │
│                                            Acessibilidade]    │
├───────────────────────────────────────────────────────────────┤
│ FEATURE  (regras de jogo; lógica pura, sem SceneTree)         │
│  Armas · Selo e Fluxo · Efeitos de status · Telégrafos        │
│  IA de inimigos e elites · Câmaras e ondas · Portas           │
│  Run e regiões · Bênçãos · Economia de Fragmentos             │
│                [VS/Alpha: Chefes, Criatura, Oficina, Campus…] │
├───────────────────────────────────────────────────────────────┤
│ CORE  (o passo de simulação)                                  │
│  Modificadores e atributos · Movimento e esquiva · Combate    │
├───────────────────────────────────────────────────────────────┤
│ FOUNDATION  (integração com a engine e serviços sem dep.)     │
│  Conteúdo orientado a dados · RNG com seed · Input e controle │
│  Cena 3/4 e câmera · Orquestrador do passo**                  │
│                          [VS: Save e perfil, Localização]     │
├───────────────────────────────────────────────────────────────┤
│ PLATFORM: Godot 4.7.2 (GDScript, Forward+, D3D12 no Windows)  │
└───────────────────────────────────────────────────────────────┘
```

**Regra de dependência:** só se chama para baixo. Para cima e para os lados só há eventos (sinais) e consultas injetadas. As 5 dependências circulares do `systems-index.md` (Run↔Economia, Input↔IA, Input↔Cena, Movimento↔Combate, Combate↔IA) já estão resolvidas por contrato injetado.

**Desvios do `systems-index.md`** (o índice continua com a classificação antiga até ser atualizado):
- \* **Pipeline visual** está em Apresentação (o índice o põe em Core): é dono de shaders, LUT, passes e relógios, e nenhuma regra de jogo depende dele.
- \* **Telemetria local** é observador na Apresentação (o índice a põe em Polish): só escuta eventos e grava.
- \*\* **Orquestrador do passo** é um módulo de Foundation **sem GDD**: 8 dos 22 GDDs o pressupõem e nenhum o define. Ganha ADR próprio (0001).

Sistemas de Vertical Slice e Alpha ficam reservados no lugar do índice, sem desenho agora.

## Module Ownership

Legenda de risco: ⚠️ pós-corte (4.5+); **confirmado** = coberto por `docs/engine-reference/`.

### Foundation

| Módulo | Posse | Expõe | Consome | APIs da engine |
|---|---|---|---|---|
| **Conteúdo** | Catálogo `.tres` (13 tipos de Resource), validadores V1–V11, impressão SHA-256 | `obter(tipo,id)`, `listar/filtrar` (ordem do manifesto), impressão, relator de erros | Arquivos `assets/data/` | `Resource`, `ResourceLoader`; ⚠️ `duplicate_deep()` (4.5, **confirmado**); `HashingContext` e CSV `keep`: **NEEDS VERIFICATION** |
| **RNG** | Seed da run, estado dos fluxos (8 finalidades) | `fluxo(finalidade, região, índice)` e operações puras | Lista e impressão do catálogo, entropia injetada | Nenhuma (GDScript puro, int64). BAIXO |
| **Input** | Amostra por passo, buffer de 10 passos, remapeamento, arquivo de binds | Amostra, `rotulo_acao`, cursor, `fonte_mira` | Consulta de alvos (IA), conversão tela→mundo (Cena), "hitstop ativo" | `Input`, `InputMap`, `InputEvent`; ⚠️ `device` ≠ 0 (4.7, **confirmado**); ⚠️ foco duplo (4.6, **confirmado**); `ConfigFile`/`user://` |
| **Cena 3/4 e câmera** | Viewport, 11 camadas, câmera própria, snapshot tela→mundo | Conversão sem impulsos, bases `pos`/`pos_seguir`, geometria da vista | `t_apres` (Orquestrador), retângulo (Câmaras), posições (Movimento), impulsos (Feedback) | ADR-0007: `canvas_transform`, três faixas de stretch, parallax manual e ordem por pé/spawn; 67 checks isolados, render/144 Hz ainda pendentes |
| **Orquestrador do passo** *(novo, sem GDD)* | Estado de jogo (Jogo/Pausa/Bênção/Transição/Morte/Encerrada), ordem do passo, `t_vivo` e `t_apres` (o contador de hitstop é do Combate, R10) | Estado atual, sinal de passo, `passo()`/`passo_congelado()`, consulta `hitstop_ativo()` (delegada ao Combate) | Todos os módulos do passo | `_physics_process` a 60 Hz; ⚠️ retorno tipado herdado em override (4.7, **confirmado**); `SceneTree.paused`: **NEEDS VERIFICATION** |

### Core

| Módulo | Posse | Expõe | Consome | APIs da engine |
|---|---|---|---|---|
| **Modificadores** | Portador (atributos, modificadores, gatilhos) | `valor()`, `multiplicador_de_dano()`, `gatilhos()`, `aplicar/remover/avancar` | Definições (`EffectDef`, `RarityTable`) | Nenhuma. BAIXO |
| **Movimento** | **Única** escritora da posição do jogador, cargas de esquiva | Posição atual/anterior, "em esquiva", `deslocar`, `teleportar` | Amostra (Input), portador, geometria (Câmaras), lista de alvos (IA), contrato do Combate | Nenhuma (colisão própria). Nó de apresentação: `Node2D` |
| **Combate núcleo** | Golpes, projéteis, empurrão, varredura de mortes, Vida do jogador, eventos | Eventos V1–V15, `ferir_jogador/inimigo`, `disparar_projetil`, `aplicar_corte` | Portador, amostra, geometria, lista de inimigos, `CombatTuning` | Nenhuma (matemática própria); **NOT SOURCEABLE:** sinal de fim de quadro (AC-92) |

### Feature (lógica pura; nenhuma usa API de engine)

| Módulo | Posse | Expõe | Consome |
|---|---|---|---|
| **Armas** | `WeaponDef`, `ArmasTuning`, arma da run | `WeaponDef` ao Modificadores, 2 `AttackDef` ao Combate | Catálogo, Run |
| **Selo e Fluxo** | Lista de Selos, `fluxo` | `no_selo()`, `fator_lentidao`, eventos `selo`/`selo_fim` | Combate (`acerto_de_arma`), Input, Modificadores |
| **Efeitos de status** | Estado por inimigo (Sangramento, Queimadura, Abalo) | `aplicar_status`, `abalado()`, `estado()` | Combate (`ferir_inimigo`), IA (lista) |
| **Telégrafos** | Lista de telégrafos (teto 24) | `iniciar_telegrafo`, estado por quadro | IA, Combate, Câmaras (geometria) |
| **IA e elites** | Fases dos inimigos, **lista de inimigos (ordem estável)**, `sortear_elite` | Lista, `sortear_elite`, consulta de alvos | Combate, Telégrafos, RNG, retângulo de vista |
| **Câmaras e ondas** | Layout, ondas, `p`, portas físicas, "em combate" | `camara_limpa(p,tipo)`, retângulo, obstáculos | IA, RNG, Orquestrador (Transição) |
| **Portas e recompensas** | `RewardTable`, recompensa pendente | `recompensa`, `pedir_oferta`, `creditar` | Câmaras, Bênçãos, RNG |
| **Run e regiões** | Máquina da run, seed, resumo | `nova_run`, `run_encerrada`, `fim_da_run` | Câmaras, Portas, Economia, RNG |
| **Bênçãos** | Pool de 18 `BoonDef`, bênçãos tomadas | `oferta_aberta`, `bencao_tomada` | Modificadores, RNG, Portas |
| **Economia** | `ContaFragmentos` (saldo, coletados) | `saldo()`, `creditar`, `saldo_mudou` | Portas, Run |

### Apresentação

| Módulo | Posse | Consome | APIs da engine |
|---|---|---|---|
| **HUD** | Controls do HUD (somente leitura) | Combate, Selo, Movimento, Economia, Câmaras, Input | `Control`, `CanvasLayer`; ⚠️ foco duplo (4.6) |
| **Tela de bênção e carta** | `CartaView`, máquina de 8 estados | Bênçãos (`oferta_aberta`), Input | `Control`; ⚠️ `Control.offset_transform_*` (4.7, **confirmado**) |
| **Feedback de combate** | Árbitro eventos→respostas, pool de VFX e números | Eventos do Combate, relógios | `GPUParticles2D`/`CPUParticles2D`, `AudioStreamPlayer`; contagem de draw calls: **NEEDS VERIFICATION** |
| **Pipeline visual** | Shaders (3 famílias), LUT, `shader_globals`, passes de tela, relógios `t_apres` | Região, telégrafos, estado do orquestrador | `global uniform` com sampler em `canvas_item` + Shader Baker: **NOT SOURCEABLE** (E2); `CanvasGroup`, `Parallax2D`; ⚠️ linhas de `CanvasItem` sem feather (4.7, **confirmado**) |
| **Telemetria** | Arquivo `.jsonl`, retenção | Eventos de Run, Bênçãos, Portas, Combate, Economia | `FileAccess` ⚠️ `store_*` retorna `bool` (4.4, **confirmado**); flush/append: **NOT SOURCEABLE** |

### Conflitos de posse resolvidos (donos aprovados)
1. **Contador de hitstop:** o **Combate** guarda o contador (`pedir_hitstop(n)`, R10); o Orquestrador só consulta `hitstop_ativo()` e congela o passo. *(Corrigido na v1.1: a v1 dava o contador ao Orquestrador, o que contradizia o GDD de Combate; ver ADR-0001.)*
2. **`modo_bencao` (Pipeline):** o **Orquestrador** liga e desliga ao entrar e sair do estado Bênção.
3. **Lista de inimigos:** dona é a **IA**; Combate, Selo e Status só leem (ordem estável).
4. **`p_max`:** dono **Câmaras**; `ArmasTuning` guarda só alias (aviso WV8).
5. **`trocas_oferta`:** dono **`BencaosTuning.trocas_iniciais`**; Modificadores só soma.
6. **Reset do Fluxo na nova run:** estado do **Selo**; a **Run** só chama `nova_run`.
7. **Número agregado de dano de status:** o contador é do **Feedback**, não do Status.

O [ADR-0003](adr-0003-entidades-e-portadores.md) propõe estado de combatente e portador em `RefCounted`, com slots internos reutilizáveis para os telégrafos.

## Data Flow

Tudo roda na **thread principal**; nenhum fluxo cruza thread. A gravação da telemetria é síncrona (decisão do GDD).

### 1. Passo de simulação (60 Hz, só no estado Jogo)
A ordem vem do Combate R1, do Selo (item 6), do Status e dos Telégrafos (item 7) e das Câmaras (item 10). A numeração dos demais itens fica no GDD do Combate; o ADR 0001 a transcreve.

```
Orquestrador.passo()                      (síncrono, ordem fixa, 1 vez por _physics_process)
 1  Input.amostra()            → mover, mirar, apertados, buffer            [Input → todos]
 2  hitstop > 0 ?  sim → Movimento.passo_congelado(); fim do passo (nada desconta)
 3  Combate: início do passo   (recuperação, invulnerabilidade, "câmara limpa?" só com hitstop=0)
 4  Movimento.passo()          → posição (única escritora)
 5  Combate: golpe do jogador  → eventos golpe/acerto/acerto_de_arma
 6  Selo.passo()               → planta, fere por Selo (ferir_inimigo silencioso)
 7  Inimigos: Status tick → Telégrafos (progresso) → impacto → IA   [ordem estável da lista da IA]
 8  Projéteis · varredura de mortes (até 4 passes)
 9  Telemetria/Run recebem "passo vivo" (t_vivo += 1/60)
10  Câmaras: câmara limpa? → camara_limpa(p,tipo) → Portas → recompensa
```

**Quadro de render** (`_process`, taxa livre): o Orquestrador atualiza relógio e eventual corte do wipe → a Cena publica geometria da janela e calcula câmera/camadas (P_ant, P_atual, fração) → o Pipeline escreve `shader_globals` (`t_vivo`, `t_apres`, `modo_*`) → o HUD lê o estado atual por consulta (nunca só por evento) → o Feedback aplica pedidos aos pools de VFX e números. A arbitragem e entrega de impulsos de câmera pelo Feedback acontecem no fim do passo, antes da avaliação da câmera no próximo render; a aplicação posterior dos outros efeitos não deve atrasar o impulso. O [ADR-0007](adr-0007-cena-viewport-e-camera.md) propõe essa sequência e o reset de época no corte.
**NEEDS VERIFICATION:** `get_physics_interpolation_fraction()` e a interpolação de física 2D.

### 2. Eventos
| Canal | Quando usar | Exemplos |
|---|---|---|
| **Lista de eventos do passo** (`Array` de eventos tipados, ordenada, esvaziada pelo Orquestrador no fim do passo e entregue em ordem fixa) | Notificações de efeito: quem escuta não muda o resultado do passo | `golpe`, `acerto`, `inimigo_morreu`, `jogador_atingido` → Feedback, Telemetria, HUD, Áudio |
| **Chamada síncrona / sinal imediato** | Fluxo de controle em que a ordem muda o resultado | `camara_limpa`, `porta_escolhida`, `oferta_aberta`, `tela_fechada`, `jogador_morreu`, `creditar` |

Motivo: o Feedback é um árbitro puro que recebe "a lista de eventos do passo" (Feedback R1), e a ordem de entrega fixa preserva o determinismo. Sinais do Godot em tudo seriam mais simples, mas a ordem entre conectados é difícil de garantir e testar. A decisão final é o ADR 0002.

Cadeia crítica: `Combate → camara_limpa → Portas → pedir_oferta → Bênçãos → oferta_aberta → Tela → (escolher) → preco_revelado → tela_fechada → bencao_escolhida → Portas abrem`. A Tela só devolve `escolher(i)`/`trocar()`; Bênçãos segura `bencao_escolhida` até `tela_fechada`.

### 3. Salvar e carregar (MVP)
**Não há save no meio da run no MVP.**

| Dado | Dono | Onde | Formato |
|---|---|---|---|
| Última arma escolhida | Armas | `user://preferencias.cfg`, seção `[armas]` | `ConfigFile` (migra para Save e perfil na fatia vertical) |
| Remapeamento | Input | arquivo próprio em `user://` | formato do Input, local do Save |
| `telemetria_ligada` | Telemetria | configuração do usuário (não é Save) | `ConfigFile` |
| Sessão de telemetria | Telemetria | `user://telemetria/sessao-*.jsonl` (≤ 2 MiB, últimas 20) | JSON Lines, síncrono |
| Saldo de Fragmentos | Economia | **só memória**; `exportar()`/`importar()` prontos | `int` |
| Estado dos fluxos do RNG | RNG | **não persiste** (só com save no meio da run, fatia vertical) | — |

Dono da serialização futura: Save e perfil (Vertical Slice, Foundation). Até lá cada dono grava o seu arquivo. **NOT SOURCEABLE:** flush e append do `FileAccess`.

### 4. Ordem de inicialização
```
 1 Conteúdo      carrega catálogo, valida (V1–V11 + 2ª passada), calcula impressão   ← erro bloqueia a run
 2 RNG           recebe fonte de entropia, tipo de build, args de linha de comando
 3 Input         recebe InputTuning do catálogo (sem catálogo: só digital)
 4 Cena/câmera   aplica chaves do project.godot, recebe CameraTuning
 5 Pipeline      recebe VisualTuning, escreve shader_globals iniciais (Shader Baker no export)
 6 Orquestrador  estado "Pronto"
 7 Feature       Modificadores → Movimento → Combate → Selo/Status/Telégrafos/IA → Câmaras/Portas/Run/Bênçãos/Economia (injeção)
 8 Apresentação  HUD, Feedback, Telemetria
 9 Menu / escolha de arma → Run
```
Input e Câmera têm injeção retirada ao sair de Pronto e reinjetada ao entrar. O ADR-0001 propõe a composição no nó raiz, sem `Autoload`.

**Fluxos de maior risco:** montar layout + até 3 ondas + 1ª onda num único quadro da Transição (custo não medido); telemetria síncrona no passo da morte (até 3 linhas, orçamento 3 ms).

## API Boundaries

Contratos em GDScript tipado, com os nomes dos GDDs. Tipos usados: `RefCounted`, `Resource`, `StringName`, `Array[T]`, `Dictionary`, `Vector2`, `@abstract` (4.5, confirmado). ⚠️ Regra do 4.7: `override` de método com retorno tipado herda o tipo e exige `return` explícito (`return null` no mínimo).

### 1. Orquestrador ↔ módulos do passo
```gdscript
@abstract class_name Passo extends RefCounted
@abstract func passo(amostra: AmostraDeEntrada) -> void          # só chamado no estado Jogo
func passo_congelado() -> void: return                           # hitstop/pausa: anterior = atual
```
- Invariante: nenhum módulo chama `Input`, `Engine.time_scale` nem lê o relógio de parede.
- Garantia: `passo()` roda no máximo 1 vez por `_physics_process`, na ordem do fluxo 1.

### 2. Conteúdo (catálogo)
```gdscript
func obter(tipo: StringName, id: StringName) -> Resource         # null + relator em erro
func listar(tipo: StringName) -> Array[Resource]                 # ordem do manifesto, sem `obsoleto`
func impressao() -> String                                        # 64 hex; curta = 4 hex
```
- Invariante: definições somente leitura; cópia mutável só por `duplicate_deep()` e nunca volta ao catálogo.
- Garantia: ≥ 1 erro de validação bloqueia a run antes do menu; ordem estável entre execuções.

### 3. RNG
```gdscript
func fluxo(finalidade: int, regiao: int, indice_camara: int) -> FluxoRng
# FluxoRng: real() -> float [0,1), inteiro(n: int) -> int, escolha_ponderada(pesos), k_distintos(n, k)
```
- Invariante: chamadas aleatórias globais ficam restritas à apresentação e à função de entropia da criação da run, conforme RNG R1 e AC-32. O consumo das finalidades estruturais 1–6 e 8 segue a ordem fixa dos donos. A finalidade `ia`, id 7, admite consumo dependente do combate.
- Garantia: estrutura reproduzível com seed, versão do jogo, impressão completa do catálogo, estado inicial, escolhas de portas/bênçãos e usos de troca de oferta idênticos. Os candidatos de spawn são reproduzíveis, e a seleção final pode depender da posição do jogador. O [ADR-0005](adr-0005-rng-deterministico.md) propõe os contratos de fonte e validade dos fluxos.

### 4. Input
```gdscript
class_name AmostraDeEntrada extends RefCounted   # snapshot somente leitura
var mover: Vector2; var mirar: Vector2; var fonte_mira: StringName; var intensidade_mira: float
func apertado(acao: StringName) -> bool; func segurado(acao: StringName) -> bool
# ComandosDoPasso é uma capacidade separada, válida só no passo/contexto atual:
func quer(acao: StringName) -> bool
func consumir(acao: StringName) -> bool
# Consulta do provedor para HUD/UI:
func rotulo_acao(acao: StringName, dispositivo: StringName) -> Dictionary   # {texto, glifo}
```
- Invariante: código de jogo nunca referencia tecla nem o singleton `Input`; mouse e teclado se identificam por tipo de evento, nunca por `device == 0` (4.7).
- Garantia: 1 amostra por passo, inclusive para telas fora de Jogo; bordas drenadas uma vez. Troca de contexto esvazia buffer/bordas, invalida consumo corrente e bloqueia entradas físicas até soltar. O [ADR-0006](adr-0006-input-por-passo.md) detalha contador compartilhado, hitstop, remapeamento e persistência proposta.

### 5. Modificadores (portador)
```gdscript
func valor(atributo: StringName) -> float                         # não vale para dano_*
func multiplicador_de_dano(slot: StringName, contexto: Dictionary) -> float
func gatilhos(tipo: StringName) -> Array
func aplicar(mod: Modificador) -> void; func remover_fonte(fonte: StringName) -> void
func avancar(passos: int) -> void                                 # só em passo vivo
```
- Invariante: duração em passos inteiros; M de golpe congelado no disparo; reaplicar = `max(restante, nova)`.
- Garantia: recálculo imediato após `aplicar`, `remover_fonte` ou expiração; `reducao_dano` ≤ 0,6.

### 6. Movimento ↔ Combate (contrato injetado, resolve o ciclo)
```gdscript
# Movimento define; Combate implementa (injetado em Movimento)
func em_recuperacao() -> bool;  func investida_ativa() -> Dictionary;  func contexto_de_dano() -> Dictionary
# Movimento chama, nesta ordem, no início da esquiva:
func cancelar() -> void;  func garantir_invulneravel(passos: int) -> void;  func esquiva_iniciada() -> void
# Combate chama no Movimento:
func deslocar(v: Vector2) -> void
# Câmaras chama no Movimento, no spawn/troca:
func teleportar(pos: Vector2) -> void
```
- Invariante: só o Movimento escreve a posição do jogador; ninguém chama a lógica interna do outro.
- Garantia: "em esquiva" é falso no último passo (restante 1→0); `teleportar` iguala anterior = atual e emite aviso.
- O [ADR-0008](adr-0008-movimento-e-colisao-propria.md) propõe a ordem máximo → recarga → início → deslocamento → Corte → colisão. `deslocar` repete colisão sem avançar contadores; o resolver discreto não garante ausência de interseções entre extremos. Metadados de novos toques durante hitstop complementam o ADR-0006.

### 7. Combate ↔ IA ↔ Telégrafos (o Combate define a interface)
```gdscript
func ferir_jogador(dano: int, origem: Vector2, atq: AttackDef) -> void   # 1 vez por golpe
func ferir_inimigo(alvo: InimigoRef, dano: float, causa: StringName) -> void  # causa "silencioso" p/ Selo e Status
func disparar_projetil(...8 params...) -> void
func iniciar_telegrafo(inimigo: InimigoRef, ataque: AttackDef) -> bool   # false se teto 24
func pedir_recuperacao(inimigo: InimigoRef, passos: int) -> void
```
- Invariante: mira travada no início do preparo; dano ao jogador é inteiro `max(1, round(...))`, a inimigo é `float`.
- Garantia: o golpe resolve no mesmo passo em que o telégrafo chega a 0; morto não age nem é atingível.

### 8. Status e Selo
```gdscript
func aplicar_status(alvo: InimigoRef, id: StringName, n: float) -> bool   # recusa se n ≤ 0 ou alvo inatingível
func abalado(alvo: InimigoRef) -> bool;  func no_selo(alvo: InimigoRef) -> bool
```
- Garantia: contadores só descem em passo vivo; status aplicado nos itens 5/6 fere no mesmo passo, no item 8 no seguinte.

### 9. Cadeia Run, Câmaras, Portas, Bênçãos, Tela (síncrona)
```gdscript
signal camara_limpa(p: int, tipo: StringName)          # Câmaras → Portas e Run
func pedir_oferta(regiao: int, indice: int) -> void     # Portas → Bênçãos
signal oferta_aberta(cartas: Array[CartaView], trocas: int)   # Bênçãos → Tela
func escolher(i: int) -> void;  func trocar() -> void   # Tela → Bênçãos (sem estado de jogo na Tela)
signal tela_fechada()                                   # Tela → Bênçãos → Portas
```
- Invariante: `bencao_escolhida` só sai depois de `tela_fechada`; morte vence a limpeza no mesmo passo.
- Garantia: se o pool é 0, a recompensa vira Fragmentos; oferta já aberta responde `oferta_ja_aberta`.

### 10. Economia
```gdscript
func creditar(origem: StringName, q: int) -> bool       # q float (mesmo 2.0) é recusado; EC1
func gastar(custo: int, motivo: StringName) -> bool     # atômico; ninguém chama no MVP
func saldo() -> int;  func coletados_run() -> int;  func exportar() -> int;  func importar(v: int) -> bool
```
- Garantia: saldo ≥ 0, teto 999 999; só Run e Portas (e, no futuro, a Oficina) escrevem.

### 11. Lista de eventos do passo e leitura da Apresentação
```gdscript
class_name EventoDoPasso extends RefCounted             # tipo + payload tipado, ordem de inserção
func emitir(e: EventoDoPasso) -> void                    # só no passo; entregue pelo Orquestrador em ordem fixa
# HUD/Feedback/Telemetria leem por interface de leitura injetada (testáveis com fontes falsas)
```
- Invariante: a Apresentação não escreve em jogo; evento sem linha de resposta no Feedback gera erro FB1 (log) e o jogo segue.

Os ADRs 0001 e 0002 propõem os contratos de `Passo` e `EventoDoPasso`. O [ADR-0003](adr-0003-entidades-e-portadores.md) detalha a proposta para `InimigoRef`.

## ADR Audit

Os ADRs 0001 a 0008 estão em Proposed. A auditoria consolidada ocorre em `/architecture-review`.

| ADR | Engine Compat | Version | GDD Linkage | Conflicts | Valid |
|-----|--------------|---------|-------------|-----------|-------|
| ADR-0001: Orquestrador do passo | Verificações em aberto | 4.7 | Combate, Movimento, Input, Câmaras, Run e Telemetria | [Revisão inicial](architecture-review.md): entrega nos passos congelados e duração da run | ⚠️ Proposed |
| ADR-0002: Canal de eventos | Verificações em aberto | 4.7 | Combate, Selo, Status, Run, Portas, HUD, Feedback e Telemetria | [Revisão inicial](architecture-review.md): crédito de Fluxo do Pulso e aplicação síncrona de status | ⚠️ Proposed; depende do ADR-0001 |
| [ADR-0003: Entidades e portadores](adr-0003-entidades-e-portadores.md) | `RefCounted` e arrays tipados verificados em experimento isolado | ✅ (4.7.2) | IA, Combate, Movimento, Modificadores, Selo, Status e Telégrafos | Revisão consolidada pendente | ⚠️ Proposed; depende dos ADRs 0001 e 0002 |
| [ADR-0004: Catálogo de dados](adr-0004-catalogo-de-dados.md) | 16 verificações de cache, cópia e SHA-256 aprovadas | 4.7.2 | Conteúdo R1–R12, RNG e ajustes dos consumidores | Presença de campos obrigatórios e protocolo canônico precisam de prova na implementação | Proposed; depende dos ADRs 0001–0003 |
| [ADR-0005: RNG determinístico](adr-0005-rng-deterministico.md) | 33 verificações aritméticas aprovadas | 4.7.2 | RNG R1–R9 e F1/F2/F4/F6 | Ciclo de vida, demais operações e integração pendentes | Proposed; depende dos ADRs 0001 e 0004 |
| [ADR-0006: Input por passo](adr-0006-input-por-passo.md) | 38 verificações de eventos sintéticos, buffer e barreira aprovadas | 4.7.2 | Input R1–R13, F1–F5; experimento cobre recorte de F3/F5 e AC-04/15–22 | UI, hardware, persistência e integração pendentes; explicitar Input fora de Jogo no ADR-0001 | Proposed; depende dos ADRs 0001, 0003 e 0004 |
| [ADR-0007: Cena, viewport e câmera](adr-0007-cena-viewport-e-camera.md) | 67 verificações matemáticas e de propriedades/transformações nativas aprovadas | 4.7.2 | Cena R1–R12, F1–F7; experimento cobre recorte de F2–F7 | Render real, ordem visual, DPI, sincronização e 144 Hz pendentes; clarificações de AC-20/30 e delta na proposta | Proposed; depende dos ADRs 0001, 0003, 0004 e 0006 |
| [ADR-0008: Movimento e colisão própria](adr-0008-movimento-e-colisao-propria.md) | 51 verificações em fixtures; limite tangencial reproduzido | 4.7.2 | Movimento R1–R12, F1–F7 e MV1–MV8; cobertura parcial de exemplos | F7 contínua não garantida; toques congelados e AC-26 de Corte pesado requerem alinhamento; integração/performance pendentes | Proposed; depende dos ADRs 0001–0004, 0006 e 0007 |

**Cobertura de rastreabilidade: 0 de 233 requisitos formalmente cobertos** (o ADR-0001 ainda é Proposed e não foi revisado; a contagem fina requisito→ADR sai de `/architecture-review`). As cinco decisões desta sessão também ainda não têm ADR: mapa de camadas, posse dos módulos, módulo Orquestrador, canal duplo de eventos e a regra "só se chama para baixo".

## Required ADRs

Nível `standard`: só os críticos. O mapeamento fino requisito→ADR (`TR-<sistema>-NNN`) é feito por `/architecture-review`; abaixo vão os grupos.

### Obrigatórios antes de codificar

**Foundation (nesta ordem):**

| # | Título | Decide | Cobre (grupos de TR) | Risco |
|---|---|---|---|---|
| 0001 | Orquestrador do passo e estados de jogo | Nó ou `Autoload`; ordem do passo; hitstop como contador; `t_vivo`/`t_apres`; quem liga `modo_bencao`; `_physics_process` a 60 Hz | `combate-nucleo-001/002/011`, `movimento-002/003`, `cena-009/011`, `pipeline-004`, `ia-001`, `camaras-002/007`, `run-005`, `input-008` | **ALTO** (GDScript 4.7; `SceneTree.paused` NEEDS VERIFICATION) |
| 0002 | Canal de eventos | Lista do passo + chamadas síncronas; payload de `EventoDoPasso` | `combate-nucleo-009`, `feedback-001/003/009`, `hud-001`, `telemetria-*` | MÉDIO |
| 0003 | Representação de entidades e portadores | Node vs RefCounted vs Resource; `InimigoRef`, pool de telégrafos; lógica sem `SceneTree` | `combate-nucleo-003`, `movimento-011`, `selo-011`, `modificadores-003`, `telegrafos-001`, `status-001/010`, `ia-*` | MÉDIO |
| 0004 | Catálogo de dados | `.tres`, carregador síncrono vs threaded, validação, impressão SHA-256, `duplicate_deep` | `conteudo-orientado-a-dados-*`, todos os `*-Tuning` | MÉDIO (`HashingContext`, CSV `keep`, `ResourceLoader`: NEEDS VERIFICATION) |
| 0005 | RNG determinístico | `mulberry32`, lint de CI contra `randf`/`shuffle` | `rng-com-seed-*`, `ia-004`, `camaras-004..006`, `portas-001`, `bencaos-003` | BAIXO |
| 0006 | Input por passo | `InputMap` vs amostra própria, buffer, remapeamento, ordem de nós | `input-e-controle-*` | **ALTO** (foco duplo 4.6, device IDs 4.7) |
| 0007 | Cena, viewport e câmera | stretch e pillarbox, parallax, câmera própria vs `Camera2D`, interpolação, tela→mundo | `cena-3-4-e-camera-*`, `movimento-008` | **ALTO** (interpolação 2D NOT SOURCEABLE) |

**Core:**

| # | Título | Decide | Cobre | Risco |
|---|---|---|---|---|
| 0008 | Movimento e colisão própria | Círculos + retângulo, sem `CharacterBody2D` | `movimento-001/004/005/007`, `combate-nucleo-012`, `ia-006` | BAIXO |
| 0009 | Atributos e modificadores | Cache vs sob demanda; float vs int e arredondamento determinístico | `modificadores-e-atributos-*` | BAIXO |
| 0010 | Resolução do combate no passo | Ordem de itens, dano float/int, varredura de mortes, empurrão | `combate-nucleo-004..010`, `status-003`, `selo-002/005` | **ALTO** (fim de quadro NOT SOURCEABLE) |

**Apresentação (críticos porque os GDDs marcam pontos NÃO VERIFICADO):**

| # | Título | Decide | Cobre | Risco |
|---|---|---|---|---|
| 0011 | Pipeline visual | Nós e materiais, LUT global vs plano B, famílias de shader, passes, orçamento de draw calls (**a verificar nos experimentos E1–E7**) | `pipeline-visual-*`, `feedback-004/005/010/011` | **ALTO** (E2 NOT SOURCEABLE) |
| 0012 | UI e HUD | `Control` em `CanvasLayer` vs nós no mundo, foco duplo, escala 85–150% | `hud-*`, `tela-de-bencao-e-carta-*` | **ALTO** (foco duplo, `offset_transform_*`) |

### Devem existir antes do sistema correspondente ser construído
- **0013 Persistência do MVP** (`ConfigFile` em `user://`, binds, telemetria, `exportar`/`importar`): `armas-006/007`, `input-006`, `telemetria-001..009`, `economia-005`, `rng-010`. **NOT SOURCEABLE** (flush/append de `FileAccess`).
- **0014 Telégrafos: geometria de acerto e teto 24**: `telegrafos-003/006/010`.

### Podem esperar a implementação
Pool de vozes de áudio, pool de VFX e números, medir `dc_vfx` em runtime, e tudo de Vertical Slice e Alpha (Save e perfil, Chefes, Criatura, Oficina, Campus).

Dos 12 ADRs obrigatórios, **7 têm risco ALTO**; quatro deles (0001, 0007, 0010, 0011) dependem de itens NOT SOURCEABLE e nascem marcados "a verificar no protótipo".

## Architecture Principles

1. **Simulação em passo fixo e estrutura reproduzível.** 60 Hz, hitstop como contador de passos e RNG próprio. A reprodução estrutural depende dos seis elementos de RNG R7, descritos no ADR-0005.
2. **Lógica pura e injetada.** Regras de jogo não dependem do `SceneTree` nem de singleton; tudo entra por injeção, para ser testável em memória (padrão de DI do `coding-standards.md`).
3. **Tudo que se ajusta é dado.** Valores vivem em `Resource` e `*Tuning` validados na carga; nenhum número de jogo literal em GDScript.
4. **Só se chama para baixo.** Para cima e para os lados só há eventos e consultas injetadas; a Apresentação só lê e nunca escreve no jogo.
5. **Não se afirma o que não foi verificado.** Todo item NOT SOURCEABLE ou NEEDS VERIFICATION vira experimento antes de virar decisão firme; um ADR que dependa dele nasce marcado "a verificar".

## Preparação para co-op

Decisão do usuário (2026-11-13): co-op online de 1 a 4 jogadores **depois** do MVP solo. Nada de rede agora; esta seção só garante que a base solo não impeça o co-op e registra o risco. Modelo-alvo: **host-autoritativo** (o host simula; os clientes enviam entrada e apresentam).

**O que a base solo já garante:** passo fixo de 60 Hz, ordem fixa dos 10 itens e RNG próprio por seed (simulação reproduzível); lógica pura sem `SceneTree` e sem singleton (o host roda a simulação sem Apresentação, o cliente roda só a Apresentação); a Apresentação só lê; a lista de eventos do passo (ADR-0002) serve de fluxo de notificações; o buffer de comandos em passos inteiros encaixa em entrada enviada por passo.

**O que hoje assume "um único herói":**

| Ponto | Suposição atual | Preparação |
|---|---|---|
| Input | uma `AmostraDeEntrada` por passo (API 4) | amostra por jogador, indexada por `player_id` (0 no solo) |
| Movimento, Combate, Modificadores | posição única, Vida, portador, cargas e `ferir_jogador(dano, origem, atq)` sem alvo | contratos recebem `player_id`; estado por jogador; `Array[JogadorRef]` em vez de uma referência |
| IA, Telégrafos, Câmaras | alvo é "o jogador"; spawn a >390 px "do jogador" | alvo escolhido na lista; spawn considera todos |
| Câmera, HUD, Bênção | uma câmera, um HUD, uma oferta | decisão de design pendente |
| Run, Economia | a morte do jogador encerra a run; um saldo | morte individual ≠ fim da run; saldo por jogador, decisão pendente |
| Estados globais | pausa, Bênção e hitstop congelam o mundo | online, a pausa não congela o host; hitstop global é decisão pendente |
| Eventos | `alvo_id` | eventos de jogador carregam `player_id` |

**Regras para escrever já (baratas):**
1. Contrato novo que fale "o jogador" nasce com `player_id` (0 no solo) ou recebe a lista de jogadores; nunca guarda o herói em variável única ou global.
2. Estado de jogador (posição, Vida, cargas, Fluxo, portador) vive numa estrutura por jogador, não em campos singulares espalhados.
3. Nenhum módulo de regra lê Input local; só a amostra que o orquestrador entrega (já é regra).
4. Nenhum código de rede e nenhum ADR novo até o co-op entrar.

**Risco: retrofit caro.** Se os contratos ficarem singulares, o co-op exige tocar quase todos os GDDs e módulos. *Mitigação:* as regras acima e uma revisão dos contratos antes de fechar o Pre-Production. Determinismo bit a bit entre máquinas **não** é premissa: com host autoritativo basta o host simular (e o fluxo `ia` já não tem garantia de reprodução).

**Fora do escopo desta nota:** não foram consultadas APIs de rede da engine; `docs/engine-reference/godot/modules/networking.md` não foi lido.

## Open Questions

Decisões adiadas que precisam fechar antes de a camada correspondente ser construída.

| Pergunta | Camada | Fecha em |
|---|---|---|
| Orquestrador: nó na cena raiz ou `Autoload`? | Foundation | ADR 0001 |
| Revisar representação de combatentes, portadores e slots de telégrafo | Foundation/Core | ADR 0003 (Proposed) |
| Payload de `EventoDoPasso` e herança `@abstract` vs duck typing | Foundation | ADR 0002 |
| Semântica de `SceneTree.paused`, `HashingContext`, CSV `keep` e `ResourceLoader` threaded | Foundation | ADR 0001 e 0004 |
| Interpolação de física 2D, `reset_physics_interpolation()`, pillarbox em runtime, parallax manual | Foundation | ADR 0007 |
| "Sinal de fim de quadro" do 4.7 que o AC-92 exige (latência ≤ 50 ms) | Core | ADR 0010 |
| Experimentos E1–E7 do Pipeline (draw calls 2D, LUT global com Shader Baker, `CanvasGroup`, SDF do telégrafo…) | Apresentação | ADR 0011 |
| Flush e append do `FileAccess` na telemetria | Apresentação | ADR 0013 |
| Custo de montar layout + 3 ondas + 1ª onda num único quadro da Transição | Feature | medir no protótipo |
| Formato do Save e perfil e do estado dos fluxos do RNG | Foundation | Vertical Slice |
| Os 233 requisitos são provisórios e a extração não leu Formulas/Edge Cases/ACs de 10 GDDs | todas | `/architecture-review` |
| Co-op pós-MVP: câmera compartilhada ou por jogador, oferta de bênção por jogador, saldo por jogador, comportamento de pausa e hitstop online, morte individual vs fim da run | todas | decisão de design antes de o co-op entrar; ver "Preparação para co-op" |
| Atualizar o `systems-index.md` com os desvios de camada (Pipeline visual e Telemetria na Apresentação; Orquestrador como módulo novo) | — | quem atualizar o índice |
