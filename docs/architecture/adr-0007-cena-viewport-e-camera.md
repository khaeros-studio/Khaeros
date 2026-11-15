# ADR-0007 — Cena, viewport e câmera

## Status

Proposed · 2026-11-14

## Date

2026-11-14

## Last Verified

2026-11-14 — GDD de Cena completo, contratos de Input e relógios, referência local Godot. Experimento e limites na seção Validation Criteria.

## Decision Makers

Proposta do Codex com revisão independente de contratos. Aceite pelo usuário pendente. As escolhas técnicas abaixo não alteram os GDDs aprovados.

## Summary

A câmera calcula duas posições base e uma transformação visual separada, sem `Camera2D` ativo. A Cena aplica uma única transformação de mundo, mantém as onze camadas e publica um instantâneo de conversão para o Input, com escala e faixas da janela.

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Godot 4.7, pin 4.7.2 |
| **Domain** | Rendering 2D / Input |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `modules/rendering.md`, `modules/physics.md`, `modules/input.md` |
| **Post-Cutoff APIs Used** | Propriedades de escala de Window, interpolação 2D e reset no teleporte conforme referência e GDD; uso final depende de ensaio de render |
| **Verification Required** | Imagem real com stretch/faixas, origem de eventos sob stretch/DPI, ordenação visual, interpolação a 144 Hz, custo de reordenação e pós-processamento. Headless não comprova aparência nem suavidade |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | [ADR-0001](adr-0001-orquestrador-do-passo.md): relógios/estados/corte; [ADR-0003](adr-0003-entidades-e-portadores.md): posições e identidade; [ADR-0004](adr-0004-catalogo-de-dados.md): tuning; [ADR-0006](adr-0006-input-por-passo.md): cursor e amostra |
| **Enables** | ADR-0008 Movimento; ADR-0011 Pipeline; ADR-0012 UI; ADR-0014 Telégrafos |
| **Blocks** | Implementação de produção de Cena/câmera antes do aceite e das verificações de integração |
| **Ordering Note** | O Pipeline decide shaders/passes; a Cena fornece camadas, transformação e escala. Input e Cena trocam consultas por valores, sem chamar a atualização um do outro |

## Context

O [GDD de Cena 3/4 e câmera](../../design/gdd/cena-3-4-e-camera.md) define um plano 2D em pixels, onze camadas, enquadramento até 43:18, acompanhamento interpolado e impulsos cosméticos. A mira deve continuar estável durante tremor e zoom. O lookahead não pode realimentar a própria direção do mouse. A troca de câmara precisa coincidir com teleporte e reset dos relógios na metade do wipe.

O projeto principal ainda não tem essa cena de produção. O protótipo de combate é descartável. Este ADR propõe a estrutura e resolve a fronteira entre coordenadas, deixando os critérios visuais e os ajustes de sensação para o ensaio de integração.

## Decision

### 1. Modelo puro e aplicação visual

`CameraDeApresentacao`, lógica em `RefCounted`, recebe posições anterior/atual, fração de interpolação, contexto, `t_apres`, retângulo jogável, opções e `CameraTuning`. Não consulta dispositivos, relógio de parede ou árvore. Guarda `pos_seguir`, `pos`, impulsos e época da câmara. `CompositorDeCena`, nó fino da Apresentação com interpolação OFF, aplica o resultado uma vez por quadro. Não existe `Camera2D` ativo concorrendo pelo canvas.

O ponto de composição chama: atualização do relógio e eventual troca na metade do wipe → aplicação de geometria de janela pendente → câmera → camadas → shaders e UI. O Feedback entrega seus impulsos ao final do passo de física, antes da avaliação da câmera no render seguinte. Aplicar VFX/números mais tarde no render não pode atrasar o impulso de câmera por um quadro adicional.

Toda distância de runtime já está em pixels de mundo. O fator 1,5 pertence somente à importação. Não há projeção isométrica de coordenadas: círculos continuam círculos; altura aparente é deslocamento do sprite em relação ao pé, sem alterar colisão ou chave de ordenação.

### 2. Geometria da janela em três faixas

`GeometriaDeViewport` publica valores imutáveis: tamanho da janela, largura lógica W, altura 1080, fator f, origem e retângulo útil. Para dimensões positivas, com r = largura/altura:

| Proporção | W e escala | Propriedades de Window propostas |
|---|---|---|
| r < 16:9 | W=1920; f=largura/1920; faixas acima/abaixo | `KEEP`, tamanho lógico 1920×1080 |
| 16:9 ≤ r ≤ 43:18 | W=1080×r; f=altura/1080; sem faixas | `KEEP_HEIGHT`, tamanho base 1920×1080 |
| r > 43:18 | W=2580; f=altura/1080; faixas laterais | `KEEP`, tamanho lógico 2580×1080 |

A origem é `(janela − Vector2(W,1080) * f) / 2`. Em todos os casos, modo `canvas_items`, escala `fractional`, janela inicial 1280×720. As chaves serão explícitas no `project.godot` de produção. A terceira faixa inferior é necessária: só `keep_height` não estabelece o letterbox exigido em R1. Não usar `expand`, que também expandiria a altura em proporções estreitas.

No `size_changed`, registrar o novo tamanho e atualizar a geometria antes de qualquer conversão seguinte; publicar geometria e posições presas novamente por F4 como uma unidade. As duas bases (`pos` e `pos_seguir`) são presas imediatamente, sem suavização, inclusive em Pausa. Usar a mesma rotina idempotente antes de input/render elimina dependência de qual callback veio primeiro. Reconfiguração de propriedades não deve provocar ciclo de notificações. Janela minimizada de tamanho zero mantém o último instantâneo válido e não divide por zero; ao restaurar, a primeira geometria positiva substitui-o.

### 3. Duas câmeras base e três espaços

No começo do render, calcular `P = lerp(P_anterior, P_atual, f_i)` com a fração fornecida pela engine. Atualizar `pos_seguir` por F4/F3 com alvo P. Converter o cursor usando essa posição e a geometria atual, obter `m = cursor_mundo − P`, e só então calcular lookahead F2. Atualizar `pos` por F2 → F4 → F3. No analógico, usar direção e intensidade da última amostra; mira automática e Redução de movimento produzem lookahead zero.

O Input consulta um instantâneo de `pos` do **último render**, junto à geometria vigente. A origem do vetor de ataque continua sendo `P_atual` de física. A exceção é resize/corte: ambos publicam imediatamente a base coerente com a nova geometria/câmara. O modelo não recalcula a câmera durante a consulta e não inclui impulsos.

Os espaços devem estar explícitos nas interfaces:

- **Janela:** pixels locais da área de conteúdo, origem no canto superior esquerdo; inclui faixas, exclui decoração do sistema operacional.
- **Vista lógica:** `(cursor_janela − origem) / f`, preso ao retângulo `[0,W] × [0,1080]` quando o cursor está sobre uma faixa.
- **Mundo:** `pos + cursor_logico − Vector2(W/2,540)` para a mira; substituir `pos` por `pos_seguir` somente no cálculo do lookahead.

O adaptador do ADR-0006 deve normalizar os eventos para o espaço Janela **uma vez**. `InputEvent.position` não é presumido pixel de janela: pode chegar transformado pelo viewport. A integração deve verificar esse espaço e inverter apenas a transformação de stretch correspondente quando necessário. Não aplicar escala F6 duas vezes, nem converter pelo canvas que contém tremor. `get_global_mouse_position()` e a inversa da transformação visual final não implementam esse contrato.

### 4. Transformação visual e camadas

O compositor escreve sozinho `Viewport.canvas_transform`. Para ponto de mundo X, centro visual `C_final = pos + desloc` e zoom total z:

`tela_logica = Vector2(W/2,540) + z * (X − C_final)`

A escala da janela é aplicada pela engine depois dessa transformação lógica; não multiplicar f aqui. A câmera base usada no Input permanece sem deslocamento ou zoom. Transformações anteriores não são multiplicadas incrementalmente: construir a transformação completa a cada quadro evita acumular erro.

Estrutura proposta:

```text
Main
  CompositorDeCena                    # render, interpolação OFF
  Mundo                              # Node2D; nove camadas de mundo
    Fundo / NevoaDistante / Parede / Chao
    Sombras / TelegrafoPreenchimento
    ObjetosEPersonagens              # âncoras de pé e ordenação explícita
    TelegrafoContorno / PrimeiroPlano
  Pos                                # CanvasLayer layer=50, sem seguir viewport
  UI                                 # CanvasLayer layer=100, sem seguir viewport
```

O módulo de camadas é o único que altera z/ordem/parallax. As nove camadas de mundo têm z absolutos −30, −25, −20, −10, −6, −5, 0, 5 e 10, na ordem canônica R4. `z_as_relative=false` nas raízes; subárvores não escapam da faixa por z próprio. Pós e UI pertencem a canvases separados, em layer 50/100, sem acompanhar a câmera. São os equivalentes de ordem da tabela R4, não uma mistura acidental de `CanvasLayer.layer` com `CanvasItem.z_index` no mesmo canvas.

Todo item desenhado é registrado em exatamente uma camada. Um telégrafo com preenchimento e contorno tem dois itens de apresentação, um em cada camada, ligados ao mesmo id lógico. Contorno fica acima dos corpos; o primeiro plano cobre ambos. A ordem visual e o efeito de pós sobre o mundo, preservando a UI, serão verificados no ADR-0011. Não adicionar cadeias de viewports 3D ou decisões de shader a este ADR.

### 5. Y-sort explícito e parallax ancorado

Propõe-se ordenar âncoras de objetos/personagens pelo par `(pé_interpolado.y, ordem_criacao_visual)`, com o último criado na frente em empate. Um registro central de criação, injetado na composição, atribui o ordinal monotônico sincronamente na ordem de criação lógica dos objetos/entidades/projéteis; não chama lógica de render nem depende da hora de `add_child`. O ordinal acompanha os valores entregues à Cena e é preservado ao reassociar a mesma identidade. Um novo spawn recebe novo ordinal, mesmo reutilizando um nó. Objetos estáticos são registrados na ordem estável de montagem da câmara antes dos spawns correspondentes. Isso fornece desempate entre categorias sem substituir os ids do ADR-0003. A integração deve provar ordem estável mesmo materializando categorias em lotes diferentes; atribuir ordinal apenas na criação tardia do nó é proibido.

As âncoras são irmãos, com o mesmo z, `y_sort_enabled=false`, e o compositor só muda a ordem de irmãos quando a ordem calculada mudar. Sprites de uma entidade permanecem na subárvore da sua âncora; sombra de contato é um proxy na camada própria. A posição de pé vem da mesma interpolação do sprite, nunca de sua elevação aparente. O teste visual deve confirmar que a ordem de irmãos é a ordem final e medir o custo com o teto real de entidades; nenhum ganho de performance é presumido.

Parallax é deslocamento manual da raiz de camada, com interpolação OFF: `offset = (1−p)*(C_final−centro_camara)`. A transformação comum do canvas ainda atua sobre a camada. Não combinar esse offset com follow automático de `CanvasLayer` ou `Parallax2D`, que duplicaria o scroll. p=1 dá offset zero; a âncora do centro é substituída no corte. A posição original da arte é preservada, e o offset é atribuído de novo, sem soma acumulativa.

F7 determina margens máximas em pixels de mundo: p=1,2 numa câmara 2880×1620 requer deriva (104,62). Arte opaca de fundo cobre jogável, sangria e deriva; primeiro plano fica afastado do jogável pelo limite. Falta de sangria é preenchida pela cor de fundo da região, abaixo da arte e cobrindo toda a área útil. Validação do tamanho jogável pertence ao catálogo/Câmaras; cobertura de arte e névoa continua no checklist visual.

### 6. Interpolação, relógio e estados

Ativar explicitamente `physics/common/physics_interpolation`. Âncoras de entidades recebem posições atuais nos passos de física e têm interpolação ON. O compositor/camadas de parallax são OFF: já recebem resultados calculados em render. **Não** atribuir P interpolado manualmente a um sprite que a engine também interpola. O modelo mantém o mesmo par anterior/atual para a câmera e para a ordenação; a sincronização com o sprite é critério de integração, não consequência automática de a propriedade existir.

Avançar o par anterior/atual a cada passo de física, inclusive no hitstop: o atual repetido torna o par igual após o primeiro passo congelado, evitando repetir uma pequena oscilação a cada ciclo da fração. Isso atualiza somente o histórico de apresentação; não executa Movimento/IA durante o congelamento. Na pausa que interrompe entre renders, preservar a pose visual corrente até retomar e ressincronizar o histórico sem salto; verificar com sprites reais.

F3 e idades F5 usam `t_apres` injetado. O orquestrador é o único dono do teto `dt_max_apres` e da contagem do relógio; a câmera não aplica outro relógio nem usa delta bruto. Hitstop deixa a apresentação correr; Pausa/Bênção congelam. Morte e Transição conservam a câmera parada mesmo com `t_apres` avançando para outros efeitos.

Na primeira entrada em Pausa, Bênção, Morte ou Transição, limpar impulsos e restaurar deslocamento zero/zoom1. Impulsos recebidos nesses estados ou sem tuning são descartados. Pausa sobre Bênção retorna a Bênção. Retirada de `CameraTuning` congela as bases, limpa impulsos e mantém apenas tela de erros; a reinjeção vale no quadro seguinte, fora da run, e a próxima câmara começa com corte.

### 7. Corte atômico na metade do wipe

O orquestrador conserva a ordem de seis ações do Combate R1. A ação de câmera, no mesmo quadro do teleporte, recebe nova época, limites e ponto de spawn, iguala P_anterior/P_atual e solicita `reset_physics_interpolation()` dos nós teleportados. Calcula diretamente `pos_seguir = F4(P)` e `pos = F4(alvo_F2)`, zera impulsos e publica a transformação/consulta imediatamente. A fonte de mira/cursor usada nesse corte é um valor válido capturado; não exige ações de Input em Transição.

Como o zero de `t_apres` ocorre na última ação, depois do corte, o orquestrador informa o novo início de época ao concluir a troca. A câmera reinicializa sua base temporal em zero, sem subtrair um tempo da câmara anterior. `reiniciar_relogio` só aceita a época atual e uma vez por corte; pedidos repetidos ou de épocas antigas não retrocedem o relógio. Não aplica F3 no quadro do corte. Progresso do wipe é próprio do Pipeline e não reinicia junto com esses relógios.

O corte visual dura um quadro, mas o estado global ainda pode ser Transição: manter a nova câmera parada até descobrir/voltar a Jogo. Não retomar acompanhamento só porque terminou o estado local Corte. Repetir um pedido de corte com a mesma época não teleporta, limpa nem corta novamente.

### 8. Impulsos e acessibilidade

Somente Feedback envia `preset`, `escala`, `dir`, época e tempo de início no relógio de apresentação. `receber_impulso` rejeita épocas diferentes da atual, inclusive pedidos atrasados da câmara anterior. Entrada de escala finita não negativa, tempo finito não negativo e não futuro na época atual, e direção unitária ou zero; inválidos são rejeitados com diagnóstico sem corromper o estado. Escala multiplica Ak, As e Z. No máximo 16 impulsos; entrada adicional remove o mais antigo, com ordem de recebimento como desempate.

Em cada render, descartar d<0,05 e somar F5 com ruído cosmético por impulso/eixo, injetável para testes. Limitar o vetor final a 40 depois de aplicar Tremor de câmera. Zoom total é `min(1.15, zoom_intro * zoom_impulsos)`; Redução de movimento força zoom1 e lookahead0. Tremor0 zera chute/tremor, preservando zoom quando Redução de movimento está desligada. A câmera não decide hitstop e não consome RNG estrutural. Preset de zoom principal e intro de chefe usam as mesmas fronteiras, sem implementar chefes neste marco.

### Key Interfaces

Contratos propostos, não classes de produção:

```gdscript
func atualizar_quadro(entrada: EntradaCamera) -> EstadoVisualCamera
func tela_para_mundo(cursor_janela: Vector2) -> Vector2 # último snapshot base válido
func receber_impulso(pedido: PedidoImpulso) -> void
func cortar(pedido: CorteDeCamera) -> void
func reiniciar_relogio(epoca: int, t_apres: float) -> void
func configurar_tuning(tuning: Resource) -> void # null retira
```

Entradas/resultados são valores tipados e somente leitura na fronteira. `EntradaCamera` inclui posições, fração, relógio, contexto, geometria, mira e consultas já resolvidas; não retém entidades da simulação.

### Implementation Guidelines

- MUST manter pixels de mundo sem segunda conversão 1,5 e sem projeção que deforme colisões.
- MUST usar duas bases, câmera visual separada e snapshot explícito para Input.
- MUST publicar geometria/limites coerentes antes de usar uma janela redimensionada.
- MUST manter um único escritor de canvas, camadas e parallax; câmera/parallax sem dupla interpolação.
- MUST sincronizar corte, teleporte, reset dos nós e época do relógio no quadro correto.
- MUST NEVER medir sensação/fluidez por aprovação de testes headless.

## Alternatives Considered

| Alternativa | Benefício | Motivo de rejeição |
|---|---|---|
| `Camera2D` com suavização e shake nativos | Menos aplicação manual de transformações | Ainda exige duas bases independentes e conversão sem impulsos; dois donos de suavização/limites dificultam os contratos |
| Apenas `keep_height` | Uma configuração fixa | Não limita ultrawide nem garante letterbox estreito |
| `Parallax2D` com scroll automático | Conveniência da engine | Origem do scroll não é o centro da câmara; exige compensação e reset adicionais |
| Y-sort nativo sem contrato de empate | Menos reordenação explícita | Empate por spawn e reuso de nós precisam de prova; proposta torna a chave inspecionável e testável |
| Interpolar sprite e câmera novamente em render | Posição aparentemente comum | Duplica interpolação do sprite e pode reintroduzir degraus/atraso |

## Consequences

A transformação fica auditável e a mira é independente do tremor. O custo é manter geometria, ordenação e sincronização explícitas. A ordem manual pode custar mais que o y-sort da engine e deve ser medida; se ultrapassar orçamento, uma alternativa nativa precisará provar os mesmos desempates antes da troca. Pós, oclusão, legibilidade e sensação continuam responsabilidade dos seus ensaios visuais.

## GDD Requirements Addressed

| Regras | Contrato |
|---|---|
| R1, F6; AC-01–06/36 | Três faixas, snapshot de escala e cursor preso nas barras |
| R2–R3, F1; AC-07–08 | Unidade importada, pé e altura visual separados |
| R4–R5, F7; AC-09–12/32–33 | Onze camadas, ordenação total e parallax manual |
| R6–R7, F2–F4; AC-13–21/34–35/38 | Limites, duas bases, tempo e interpolação |
| R8, F5; AC-23–31/30b | Impulsos, estados e acessibilidade |
| R9–R10; AC-20/22/37 | Consulta sem feedback, origem física da mira e corte |
| R11–R12; AC-39 | Tuning, relógio e testes injetados |

## Validation Criteria

O [experimento isolado](../../prototypes/camera-verificacao/README.md) passou **67 verificações**, zero falhas, saída 0 no Godot 4.7.2. Cobre vetores de F2–F7, oito tamanhos confrontados com `get_visible_rect()`/`get_final_transform()` nativos, propriedades de camadas/interpolação e um corte roteirizado isolado. Observou também que `CanvasLayer.follow_viewport_scale` altera a base da transformação, sem produzir sozinho a translação de F7. O README separa fixtures matemáticas e comportamento nativo das pendências. Não equivale à cena de produção ou validação visual.

Antes da integração, executar as oito dimensões de AC-02, cursor nas faixas, resize durante pausa, zoom/chute sem alterar consulta, sincronização do corte com zero de relógio, hitstop de 36 passos sem oscilação interpolada, troca de camada e empate de pés após reuso. Reter capturas das onze camadas e das proporções de AC-03, comparação atrás/frente de coluna, gravação em monitor144Hz e medidas de custo com o conteúdo real. Confirmar em uma janela real que o espaço de evento normalizado corresponde a F6 sob stretch e DPI.

## Clarificações para a revisão consolidada

- O Edge Case de travada de 1 s descreve F3 isolada quase chegando ao alvo; em jogo o relógio avança no máximo 0,1 s por quadro. Usar R7/F3 e Pipeline F8; não ignorar o teto para cumprir aquela frase.
- AC-20 fala em direção da mira idêntica com `pos_seguir` igual: a invariância vale para o vetor que gera lookahead. A mira de gameplay usa `pos`, conforme R9/AC-37, e pode diferir se essa base diferir. O GDD precisa tornar esse nome inequívoco.
- Corte→Seguindo de AC-30 é condicionado ao estado global permitir seguir; AC-30b exige congelar em Transição.
- A arquitetura deve distinguir arbitragem/entrega de impulso no fim do passo da aplicação de efeitos visuais no render. A câmera avalia o impulso já entregue.

## Migration Plan

Sem mudança no `project.godot` principal nem no protótipo jogável nesta etapa. Após aceite e revisão consolidada, implementar a Cena com ensaio visual próprio, conectar Input/Feedback e validar as capturas antes de iniciar integração de gameplay dependente.
