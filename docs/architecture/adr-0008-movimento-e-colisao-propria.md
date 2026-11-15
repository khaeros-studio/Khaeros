# ADR-0008 — Movimento e colisão própria

## Status

Proposed · 2026-11-14

## Date

2026-11-14

## Last Verified

2026-11-14 — regras, fórmulas, casos extremos e critérios do GDD de Movimento; contratos de Input, Cena, Conteúdo e Combate. Evidência executável na seção Validation Criteria.

## Decision Makers

Proposta do Codex, com revisão independente de contratos. Aceite pendente. As divergências encontradas no design ficam registradas para revisão, sem modificar os GDDs aprovados.

## Summary

Movimento será um módulo puro que possui a posição do jogador, executa caminhada/esquiva/investida em ordem explícita e resolve colisões com círculos e retângulo. A proposta preserva o algoritmo discreto aprovado e delimita sua garantia: ele corrige a posição final, mas não detecta toda interseção ocorrida no trajeto entre dois passos.

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Godot 4.7, pin 4.7.2 |
| **Domain** | Physics 2D / Core |
| **Layer** | Core |
| **Knowledge Risk** | LOW para geometria pura; integração visual depende do ADR-0007 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `modules/physics.md`; GDD de Movimento e Conteúdo F7 |
| **Post-Cutoff APIs Used** | Nenhuma API nova de física necessária; `RefCounted`, `Vector2`, `Rect2` e aritmética do build local |
| **Verification Required** | Precisão do build/exportação, integração Combate/Input, reset de interpolação e desempenho com sistemas reais |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | [ADR-0001](adr-0001-orquestrador-do-passo.md): passos; [ADR-0002](adr-0002-canal-de-eventos.md): notificações; [ADR-0003](adr-0003-entidades-e-portadores.md): identidade/estado; [ADR-0004](adr-0004-catalogo-de-dados.md): tuning/validação; [ADR-0006](adr-0006-input-por-passo.md): comandos; [ADR-0007](adr-0007-cena-viewport-e-camera.md): apresentação das posições |
| **Enables** | ADR-0009 Atributos e modificadores; ADR-0010 Resolução de combate, que implementam os contratos injetados aqui |
| **Blocks** | Stories de Movimento dependentes destes contratos até aceite e resolução das lacunas de integração |
| **Ordering Note** | A proposta pode ser testada com dublês antes dos ADRs 0009/0010; a implementação integrada exige contratos aceitos dos respectivos donos |

## Context

O [GDD de Movimento e esquiva](../../design/gdd/movimento-e-esquiva.md) exige resposta no mesmo passo, direção fixa de esquiva, recarga sequencial e cancelamento síncrono de golpes. Só Movimento escreve a posição. Corte ocorre antes de corrigir colisões; no último passo de esquiva ainda há deslocamento/Corte, mas Combate e Selo já leem `em_esquiva=false`.

Esses detalhes não são comportamento padrão de um corpo físico da engine. `move_and_slide`, iterações de despenetração ou varredura contínua mudariam a regra de uma passada e a paridade com o cânone. O projeto ainda não tem implementação de produção desse módulo.

## Decision

### 1. Estado e representação numérica

`MovimentoDoJogador extends RefCounted` possui posição atual/anterior, direção e passos restantes de esquiva, cargas atuais, máximo anterior, progresso de recarga e conjunto de ids cortados na esquiva. O portador, consultas/pedidos de Combate, fonte de comandos, geometria, consulta de atingíveis e tuning são injetados. Não há `Node`, `CharacterBody2D`, singleton, timer ou consulta de hitstop dentro da regra.

Posições, direções e geometria usam `Vector2`/`Rect2` do build padrão instalado. Não adotar vetores escalares float64 paralelos nem arredondar posições a cada passo para tentar reproduzir JavaScript. Inteiros guardam contadores; escalares de dano permanecem float. A tolerância de posição é a do GDD: ±0,001 por passo/esquiva, ±0,01 acumulado, ±0,05 na comparação com o cânone. Borda de alcance do Corte é comparação exata sem epsilon.

Determinismo bit a bit entre duas instâncias no mesmo build é critério de teste; não se promete determinismo de ponto flutuante entre plataformas. As quantizações de duração usam a função única do Conteúdo: D, E e R calculados separadamente, depois `D+E`. Zero só é aceito no extra quando permitido. Os dados são convertidos ao configurar, sem multiplicar novamente pixels por 1,5.

### 2. Passo vivo, congelado e chamadas externas

O orquestrador chama exatamente uma das duas operações em cada passo físico. No passo vivo, copiar atual para anterior antes de modificar posição e executar:

| Ordem | Operação |
|---|---|
| 0 | Sincronizar máximo de cargas com o portador |
| 1 | Avançar recarga; uma carga recuperada já pode ser usada neste passo |
| 2 | Tentar iniciar esquiva do buffer; cancelamentos síncronos antes de deslocar |
| 3 | Exatamente um deslocamento principal: investida, esquiva ou caminhada |
| 4 | Se deslocou por esquiva, avaliar Corte na posição provisória, inclusive no último passo |
| 5 | Uma passada de obstáculos em ordem, depois prender ao retângulo encolhido |

Se Combate indevidamente informar investida ativa durante esquiva, esta vence e gera diagnóstico de depuração. Isso não soma dois deslocamentos. Após a resolução principal, publicar consultas e notificações por valores.

`passo_congelado()` faz **somente** anterior=atual. Não sincroniza atributos, avança recarga, desconta esquiva, drena toques pendentes, executa Corte ou emite reação de falta de carga. Esse histórico é o par que a Cena deve usar; não manter outro histórico divergente no ADR-0007.

`deslocar(v)` é a exceção explícita de R9 à frase “uma passada por passo”: pedido síncrono do Combate após o Movimento, soma v à posição atual e executa outra passada completa de colisão. Anterior, recarga, esquiva e lista do Corte ficam intactos. Não enfileirar para o passo seguinte nem varrer Corte nesse deslocamento. O chamador decide quando e quanto mover; esse caminho também não oferece colisão contínua.

`teleportar(pos)` é usado por Câmaras no spawn/troca: atual=anterior=pos, restante de esquiva=0, limpar estado do Corte e emitir aviso com identidade/época. Preserva cargas/recarga e não toca invulnerabilidade do Combate. Não resolve obstáculos automaticamente no teleporte: R10 roda no próximo passo vivo, como AC-29. Câmaras deve fornecer spawn válido. A Apresentação recebe o aviso e faz o reset de interpolação no mesmo quadro do corte; a lógica não chama a engine.

### 3. Caminhada, esquiva e recarga

Caminhada usa F1: velocidade do portador, módulo de `mover` limitado a 1, fator de recuperação consultado e divisão por 60. Vetor zero para no mesmo passo, sem inércia. Investida usa o vetor em pixels por passo fornecido pelo Combate, sem multiplicar por delta. Esquiva usa velocidade própria e direção fixada na largada: normalizar movimento não zero, senão mira. Analógico fraco ainda produz esquiva à velocidade cheia.

Ao iniciar: reduzir carga, fixar D, chamar `cancelar` → `garantir_invulneravel(D+E)` → `esquiva_iniciada` nessa ordem, limpar ids do Corte, consumir buffer e emitir evento `esquiva` com posição **de início** e direção. Movimento não guarda o contador de invulnerabilidade. Combate o reduz antes do Movimento nos passos vivos seguintes, garantindo s…s+D+E−1. O pedido usa máximo com invulnerabilidade existente.

No próprio passo inicial já desloca e reduz restante em 1. Com D=9, desloca nos passos s…s+8, `em_esquiva` é verdadeiro s…s+7 e falso em s+8. Golpe/Selo podem sair no s+8; uma segunda esquiva só começa em s+9. Colidir não encurta a duração, não devolve carga e não reduz proteção.

Recarga cresce só com cargas abaixo do máximo. Chegando a R, recupera uma carga e zera progresso. Gastar outra carga conserva o progresso existente. Ao subir máximo, acrescentar a diferença às cargas; ao descer, limitar cargas. Se atingir o máximo, zerar progresso; se continuar abaixo, preservá-lo. Alterações em Bênção só são aplicadas no primeiro passo vivo. Exemplo de fábrica: gasto em 100, retorno em 142, incluindo recarga durante esquiva e excluindo passos congelados.

### 4. Toques novos durante hitstop

O buffer compartilhado do ADR-0006 conserva comandos em hitstop, mas a borda `apertado` de uma amostra desaparece no passo seguinte. Só essa borda não basta para emitir `esquiva_sem_carga` no primeiro passo vivo após um toque durante congelamento.

Propõe-se acrescentar ao provedor de Input uma contagem monotônica de **toques novos de Esquiva**, por época de contexto, e uma posição de leitura do consumidor Movimento. Cada passo físico com borda nova de Esquiva conta uma vez, mesmo em hitstop; Ataque renovando o prazo não conta como novo toque de Esquiva. A leitura é drenada somente no passo vivo, uma vez. Troca de contexto invalida pendências junto com o buffer; não transferir negação antiga para uma tela ou outra run. Essa contagem é metadado de reação, não uma fila de esquivas: continua existindo no máximo um comando Esquiva no conjunto do buffer.

Avaliar falta de carga depois da sincronização/recarga e **antes** de gastar a carga de uma nova esquiva. Sem carga, emitir uma reação por toque pendente, inclusive durante esquiva ativa; consumidores HUD/áudio aplicam seus próprios 0,2 s de contenção. Consultar continuamente `quer(esquiva)` não cria eventos repetidos. Se houver carga, a tentativa de execução segue R3 e consome somente o comando, sem converter a contagem de toques em múltiplos gastos. Confirmar a leitura dos metadados nos dois casos: uma esquiva bem-sucedida que gasta a última carga não gera negação por esse gasto nem deixa um toque antigo para o próximo passo.

**Clarificação necessária antes da integração:** o GDD não testa vários toques durante o mesmo hitstop, nem toque com carga zero seguido de recarga no primeiro passo vivo. A proposta preserva contagem para não perder informação e avalia disponibilidade depois da recarga, conforme R3; isso pode resultar em sucesso sem reação de negação nesse passo. Confirmar a semântica desse caso na revisão de Input/Movimento. Não apresentá-la como critério já aprovado.

### 5. Corte da esquiva

Se houve deslocamento de esquiva e o total do gatilho é positivo, consultar atingíveis na ordem estável da IA, com id, posição e raio por valores. A consulta exclui Surgindo e Vida≤0; não reutilizar uma lista de outro passo. A lista do Input sem raio não satisfaz esse contrato. O conjunto de ids cortados dura a esquiva inteira, inclusive congelamentos, e reinicia somente na próxima esquiva/teleporte/fim de run.

Comparar distância ao quadrado **≤** alcance ao quadrado, na posição após deslocamento e **antes** da colisão. Não testar segmentos ou a posição corrigida. Marcar id antes do pedido síncrono para não atingir duas vezes por reentrada. Se houver teto, percorrer somente até atingir a quantidade permitida, preservando ordem de spawn; vazio significa sem teto.

Movimento monta contexto com Vida atual/máxima recebidas do Combate, `apos_esquiva=false` e `enesimo_acerto=false`. Pede ao portador o multiplicador de Ataque e calcula total×M. Não reimplementa fórmula/teto de Modificadores. `aplicar_corte` recebe id, dano, empurrão, direção da esquiva e Sangramento. Combate revalida identidade e aplica efeitos; dano zero por M=0 ainda pode empurrar e aplicar Sangramento. Total de gatilho zero não inicia Corte.

Corte não conta acerto de arma, não gera Fluxo, não dispara `golpe_*` e Movimento não pede hitstop. A varredura de mortes pode gerar hitstop de abate. A regra de Corte marcado pesado pelo empurrão, em conflito com uma frase de AC-26, está registrada abaixo para o ADR-0010.

### 6. Geometria discreta, ordem e limites

`GeometriaDeMovimento` recebe um retângulo válido e array ordenado de obstáculos circulares imutáveis da câmara. Não usar dicionário sem ordem, consulta de engine ou lista de inimigos como bloqueadores. A resolução pura usa a posição provisória e, para cada obstáculo:

```text
delta = pos − centro_obstaculo
R = raio_jogador + raio_obstaculo
se |delta| < R:
    normal = delta / |delta| se |delta| > 0, senão (0, −1)
    pos = centro_obstaculo + normal * R
depois de todos:
    pos = clamp(pos, jogavel.inicio + raio_jogador, jogavel.fim − raio_jogador)
```

Contato exato não empurra. Não adicionar margem, epsilon, solver iterativo, subdivisão de passo ou normal dependente de velocidade. O algoritmo permite que uma correção posterior reintroduza sobreposição anterior; não corrigir de novo no mesmo passe. A geometria de Câmaras deve respeitar vãos/espaçamento; resultados de layout inválido são diagnósticos de conteúdo, não autorização para alterar a ordem.

Fábrica: raio27, obstáculo42, centro(1000,540), contato esquerdo(931,540). Centro coincidente resolve para (1000,471). Obstáculos em (1000,540)/(1000,640), jogador(1000,590), dão y571 em ordem A/B e y609 em B/A. Isso é comportamento deliberado do algoritmo, não instabilidade a eliminar ordenando por distância.

**Limite de F7/MV1:** `d_passo < raio_combinado` impede cruzar o semiplano radial de um obstáculo isolado num passo iniciado fora dele. Não prova ausência de interseção ao longo de todo o segmento. Com raio combinado69, início relativo(−10,68.5), fim(10,68.5), o passo20 passa em MV1, ambos os extremos ficam fora, mas o meio fica dentro. O resolver por extremos não detecta esse contato tangencial. A garantia também não cobre início já sobreposto nem reposicionamento por outros obstáculos.

Manter MV1 como validação aprovada de dados e **não** chamar o algoritmo de colisão contínua. Se a promessa desejada for impedir toda interseção de trajeto, é necessária decisão de design entre preservar paridade discreta ou adotar varredura/subpassos, com novos critérios. Este ADR registra o contraexemplo e não faz essa mudança silenciosamente.

### 7. Validação, fronteiras e publicação

MV1/MV6/MV8 são verificações cruzadas na segunda passada do catálogo; MV2/MV4/MV5 e faixas R11 são erros quando especificado; MV3 define quantização; avisos de margem, cobertura, distância e duração longa não bloqueiam a run. Se não houver obstáculo em nenhum dado de câmara, MV1 não tem raio mínimo aplicável: registrar não aplicável, sem inventar raio ou dividir por zero. Não duplicar esses validadores no passo vivo. Geometria não finita, raio inválido ou retângulo menor que o corpo devem ser rejeitados antes da run. Recarga de tuning só fora da run; sem tuning válido não se cria um Movimento jogável.

Publicar por valores posição anterior/atual, raio, `em_esquiva`, cargas/máximo e progresso normalizado (zero quando cheio). Eventos contêm id do jogador e época da run; nenhuma referência mutável à entidade. Só as chamadas síncronas explicitadas alteram estado de outro dono. A Apresentação não escreve posição de regra nem recalcula recarga.

### Key Interfaces

Contratos propostos, não arquivos de produção:

```gdscript
func passo(amostra: AmostraDeEntrada, comandos: ComandosDoPasso) -> void
func passo_congelado() -> void
func deslocar(v: Vector2) -> void           # pedido de Combate após Movimento
func teleportar(pos: Vector2) -> void       # pedido de Câmaras
func em_esquiva() -> bool
func estado_para_apresentacao() -> EstadoMovimento
```

O fornecimento de toques pendentes complementa `ComandosDoPasso`, validado por passo/época. `resolver_colisao(pos, raio, geometria)` é função pura compartilhável; regras de colisão de inimigos/projéteis só a reutilizam se o respectivo GDD tiver a mesma ordem/semântica.

### Implementation Guidelines

- MUST manter Movimento como único escritor da posição física do jogador.
- MUST conservar a ordem R3 e os três pedidos síncronos da largada.
- MUST distinguir último deslocamento de esquiva de `em_esquiva` consultado depois dele.
- MUST executar Corte antes da colisão e `deslocar` sem repetir Corte/contadores.
- MUST preservar ordem dos obstáculos, borda estrita de colisão e borda inclusiva do Corte.
- MUST NEVER usar solver da engine ou subpassos como substituição silenciosa do algoritmo aprovado.
- MUST testar toques congelados com Input real e proteção do próprio passo com Combate real.

## Alternatives Considered

| Alternativa | Benefício | Motivo de rejeição nesta proposta |
|---|---|---|
| `CharacterBody2D.move_and_slide` | Colisão pronta e ferramentas visuais | Não expressa a passada ordenada R10, controle de normal zero e Corte anterior à correção |
| Varredura contínua/subpassos | Detecta interseções entre extremos | Muda paridade e ordem; é opção de revisão da promessa F7, não detalhe neutro |
| Resolver até sair de toda sobreposição | Reduz resíduos em layouts ruins | Contradiz uma passada e resultados AC-29 dependentes da ordem |
| Invulnerabilidade no Movimento | Menos chamadas ao Combate | Duplica contador e autoridade sobre recebimento de dano |
| Evento assíncrono para cancelar investida | Menos interfaces síncronas | Chega tarde para impedir a investida no próprio passo da esquiva |

## Consequences

A ordem da simulação e as fronteiras de posse ficam testáveis em memória. O módulo exige coordenação precisa com Input e Combate, principalmente no último passo de esquiva e no primeiro após hitstop. Colisão discreta mantém limites conhecidos e não substitui revisão da geometria. A sensação de esquiva, animação e segurança no combate completo continuam pendentes de playtest.

## GDD Requirements Addressed

| Regras | Contrato |
|---|---|
| R1–R3, R12; AC-02/32–34/40/43/44/52/58 | Posse, ordem, congelamento, teleporte e deslocamento externo |
| R4–R7, F1–F4; AC-01/03–17/27–28/49–50/55–56 | Movimento, início/fim da esquiva, recarga e pedido de invulnerabilidade |
| R8, F5–F6; AC-18–26/51 | Consulta ordenada, contexto de dano e Corte antes de colisão |
| R9–R11, F7, MV1–MV8; AC-29–31/35–39/53–54 | Geometria discreta e validação cruzada |
| AC-45–48/57 | Paridade, evidência visual/áudio, custo e promessa do P3 ainda dependem de integração |

## Validation Criteria

O [experimento isolado](../../prototypes/movimento-verificacao/README.md) passou **51 verificações**, zero falhas, saída 0, no Godot 4.7.2. Verificou vetores de caminhada/quantização, colisão ordenada, esquiva axial, recarga, encadeamento, histórico congelado e teleporte; reproduziu a limitação tangencial de F7. A fixture temporal usa buffer simplificado, e o dublê de invulnerabilidade não aplica dano real. Fixtures não equivalem à implementação do módulo; o README discrimina cobertura e lacunas.

Na integração: rodar dois Movimentos com roteiro fixo de 1000 passos, comparar estados/eventos; Input real com múltiplos toques em hitstop e contexto trocado; golpe no próprio passo da esquiva e no fim da proteção; Corte com Vida baixa, janelas de modificador abertas e dano zero; morte/remoção de alvo; pedidos `deslocar`; teleporte com recarga ativa e reset da apresentação. AC-48 exige 10000 passos, nove alvos/seis obstáculos, média/p99 registrados e p99 ≤ 0,2 ms; o experimento parcial não comprova esse orçamento. Visual, áudio e sessão de 30 minutos do P3 precisam de evidências próprias.

## Clarificações para revisão consolidada

- F7/MV1 não prova colisão contínua; contraexemplo tangencial descrito acima. Decidir o alcance da promessa antes de encerrar aceitação do sistema.
- ADR-0006 precisa reter metadados de toques de esquiva durante congelamento; vários toques e recarga simultânea no primeiro vivo precisam de critérios explícitos.
- Movimento AC-26 diz que Corte com empurrão pesado pede hitstop, enquanto Movimento R8 e Combate R18 excluem hitstop próprio do Corte. Não confundir `pesado` com autorização de hitstop. ADR-0010 deve resolver esse conflito, preservando o caminho independente de hitstop por abate.
- A assinatura do teleporte é de Movimento, mas Câmaras é seu chamador na troca/spawn; a tabela inicial da arquitetura agrupava-a sob chamadas do Combate.

## Migration Plan

Sem mover código do protótipo para produção. Após aceite e alinhamento das lacunas, implementar função de geometria e módulo puro com dublês, depois integrar Input/Combate/Cena e executar critérios reais. Próxima proposta na sequência: ADR-0009, Atributos e modificadores.
