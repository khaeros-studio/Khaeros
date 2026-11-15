# ADR-0006 — Input por passo

## Status

Proposed · 2026-11-14

## Date

2026-11-14

## Last Verified

2026-11-14 — conferência do GDD aprovado e da referência local da engine. Evidência executável e limites na seção Validation Criteria.

## Decision Makers

Proposta preparada pelo Codex com revisão independente de contratos. Aceite pelo usuário pendente; nenhuma regra de design é promovida ou alterada por este documento.

## Summary

Um adaptador acumula eventos físicos entre passos e um provedor puro traduz esse estado em uma amostra por passo. O buffer compartilhado e a barreira de troca de contexto ficam nesse provedor, com consumo autorizado somente durante o passo corrente.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7, pin local 4.7.2 |
| **Domain** | Input |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/modules/input.md` |
| **Post-Cutoff APIs Used** | Eventos identificados por classe, sem assumir `device == 0` para teclado/mouse; foco de teclado/gamepad separado do foco do mouse na referência 4.6+ |
| **Verification Required** | Pipeline de UI sem ativação duplicada, foco visual, teclado com layout diferente, hardware real, persistência e reconexão; o experimento isolado não substitui esses testes |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | [ADR-0001](adr-0001-orquestrador-do-passo.md), ciclo e ordem dos passos; [ADR-0003](adr-0003-entidades-e-portadores.md), consulta estável de alvos; [ADR-0004](adr-0004-catalogo-de-dados.md), retirada e reinjeção de `InputTuning` |
| **Enables** | ADR-0007, conversão do cursor e câmera; ADR-0008/0010, consumidores; ADR-0012, telas; ADR-0013, persistência |
| **Blocks** | Implementação de produção do Input e consumidores dependentes até o aceite dos contratos |
| **Ordering Note** | Interfaces quebram o ciclo Input ↔ Cena e Input ↔ IA. ADR-0012 detalha navegação visual; ADR-0013 valida operações de arquivo. Nenhum desses detalhes é presumido implementado |

## Context

O [GDD de Input e controle](../../design/gdd/input-e-controle.md) exige toques entre dois passos, amostragem a 60 Hz, remapeamento completo, telas sem mouse e preservação do buffer durante hitstop. Consultar apenas o estado atual dos botões perde um aperto seguido de soltura. Consultar a mesma borda em vários passos de um quadro pode executar duas vezes. A API inicial da arquitetura também chama a amostra de somente leitura e oferece consumo mutável no mesmo objeto.

O jogo de produção ainda não implementa essa camada. O experimento é descartável. O escopo deste ADR é definir posse, fronteiras e formato de binds, preservando R1–R13 e F1–F5; os GDDs de Menus e Acessibilidade ainda têm decisões próprias pendentes.

## Decision

### 1. Adaptador de eventos e provedor injetado

`AdaptadorDeEntradaGodot`, um nó fino na fronteira da engine, recebe `_input`, notificações de foco e conexão. Converte eventos em descritores de valores; nenhuma referência a `InputEvent` atravessa a fronteira. A identidade física contém classe, código, localização esquerda/direita quando disponível e, para gamepad, id de dispositivo. Teclas usam posição física; Shift esquerdo/direito contam como um bind lógico, mas as duas teclas mantêm estado físico separado para soltar uma sem apagar a outra. A entrega da localização de modificadores pela engine/Windows ainda requer prova específica; o experimento com J/K não a comprova.

O adaptador mantém estado de cada entrada física, conjunto de bordas novas, cursor válido em coordenadas de janela e soma dos módulos dos movimentos de mouse desde a última amostra. Repetições de teclado (`echo`) não geram bordas. Dois apertos da mesma ação no intervalo produzem uma borda. Soltar um bind não solta a ação se outro bind dela continua pressionado. Não se conserva uma fila ilimitada de eventos: reduz-se cada evento nesse estado limitado, preservando as informações de R2/F5.

Cada borda preserva origem, ordem de chegada e, no clique, posição de janela no instante do aperto. A confirmação aponta para esse local, não para o cursor final após movimento. A origem permite distinguir teclado de A do gamepad ao entrar em Texto. Bordas repetidas da mesma entrada conservam a primeira candidata do intervalo; despacho de UI e desempate entre ações simultâneas precisam ser especificados/testados no ADR-0012, com no máximo uma confirmação por passo.

Propõe-se desativar `Input.use_accumulated_input` no ponto de composição para que movimentos opostos não se fundam antes do acumulador próprio. O custo desse recebimento de eventos deve ser medido com mouse de alta frequência. Não se desativa a acumulação para acelerar a simulação: somente o orquestrador decide quando amostrar.

`ProvedorDeEntrada`, lógica pura em `RefCounted`, recebe o lote reduzido, contexto, hitstop, consultas de mira e ajustes. É chamado exatamente uma vez por `passo_fisico`, inclusive fora de Jogo. Drena bordas e deslocamento uma vez. Passos adicionais sem eventos conservam segurados, sem fabricar novos apertos. Não há `_physics_process` próprio no adaptador, `Autoload`, consulta global pelos consumidores nem ordenação por prioridade de nós.

O mapa de binds próprio é a autoridade. `InputMap` não guarda o buffer nem decide contexto/dispositivo. Um eventual espelho para controles da engine deve ser derivado e nunca iniciar uma segunda via de execução. Essa escolha também evita depender da zona morta por ação da engine para F2 e da fusão de gamepads para R3.

### 2. Snapshot e consumo do buffer

`AmostraDeEntrada` contém os oito campos de R2: movimento, mira, fonte, intensidade, segurados, apertados, visão do buffer e escolha de tela. Tem `id_passo` e `epoca_contexto`. Valores são somente leitura por convenção, arrays/dicionários devolvidos são cópias. A visão do buffer registra o começo do passo; não representa consumo posterior.

`ComandosDoPasso` é uma capacidade separada para os consumidores, ligada ao buffer vivo do provedor e ao passo/época. `quer(acao)` consulta o estado atual: Ataque/Especial aceitam segurado ou buffer; Esquiva/Selo aceitam apenas buffer. `consumir(acao)` remove somente o comando executado e não altera o prazo. O consumidor chama depois de executar com sucesso. Retenção da capacidade após o fim do passo ou troca de contexto torna consulta/consumo inválidos, sem alterar o buffer do próximo passo. A Apresentação recebe apenas a amostra.

O buffer é um conjunto de quatro ações e **um contador único**, conforme F3:

- Novo toque em qualquer uma das quatro ações une os comandos e repõe o prazo de todos para `buffer_passos`.
- Sem toque novo, um passo vivo desconta 1 antes dos consumidores; zero esvazia o conjunto.
- Hitstop conserva o prazo, mas continua recebendo toques. Fora de Jogo, o buffer fica vazio.
- Toque no passo 0 vale de 0 a 9, com ajuste 10. Com hitstop 0–35, vale nos passos vivos 36–44 e expira em 45.
- Movimento tenta Esquiva, Combate tenta Especial antes de Ataque e Selo roda por último. A execução de Especial deixa Ataque no buffer. Consumo de uma ação nunca apaga as outras.

A prioridade é ordem de tentativa pelos donos e suas regras de cancelamento, não um despachante que executa automaticamente só um comando global por passo. `interagir`, `pausar` e `ui_*` não entram nesse buffer.

**Complemento proposto pelo [ADR-0008](adr-0008-movimento-e-colisao-propria.md):** manter metadados de novos toques de Esquiva por época até o próximo passo vivo de Movimento. Só o buffer e a borda do passo corrente não bastam para a reação `esquiva_sem_carga` depois de hitstop (Movimento R5). Essa contagem não enfileira múltiplas esquivas, não é renovada por Ataque e é descartada na troca de contexto. Vários toques congelados e recarga no primeiro passo vivo precisam dos critérios de integração/clarificação descritos no ADR-0008; os 38 checks deste ADR não cobrem o complemento.

### 3. Contextos, troca e foco

Estado global e contexto de input são diferentes: opções e Texto podem estar sobre uma Pausa; fechar a Pausa sobre Bênção restaura a mesma oferta. Um roteador de contexto controlado pelo orquestrador/UI mantém esse retorno explicitamente. Input solicita uma mudança; não altera sozinho o estado do jogo.

| Contexto | Saída permitida |
|---|---|
| Jogo | Ações de jogo e `pausar` |
| Pausa | `ui_aceitar`, `ui_navegar`, `pausar` |
| Bênção | Aceitar, navegar, cartas 1–3, troca de ofertas, `pausar` |
| Menu | `ui_*` pertinentes à tela; Start não volta nem pausa |
| Texto | Digitação; Enter/Esc físicos fixos para confirmar/cancelar; gamepad não inicia edição |
| Transição / passe de morte | Nenhuma ação, inclusive pausa e confirmação |
| Sem foco | Nenhuma entrada ativa; estado lógico dos botões solto |
| Remapeando | Captura restrita ao dispositivo escolhido; regras de cancelamento da R8 |

A troca de contexto incrementa a época, invalida a capacidade corrente, esvazia buffer/bordas/escolha e bloqueia as **entradas físicas** seguradas até a soltura. O toque do mesmo passo também é descartado, mesmo se a soltura já chegou. Isso cobre Espaço/A/clique compartilhados por ações diferentes. O desbloqueio de uma entrada não desbloqueia outra ainda segurada. Entrada durante Transição ou passe de morte não acumula comandos para depois.

O orquestrador processa pedidos de pausa/foco e a troca de contexto antes de despachar regras vivas; se houver troca, não distribui a amostra antiga para os consumidores seguintes nem amostra uma segunda vez no mesmo passo. Uma troca iniciada depois por combate/UI invalida a capacidade e as escolhas restantes imediatamente. Não há execução retroativa de comandos descartados.

Perda de foco em Jogo pede Pausa e limpa segurados, bordas e buffer. Em Bênção/Menu apenas limpa entradas. Durante o wipe, memoriza pedido de pausa: no primeiro passo que voltaria a Jogo, a Pausa entra antes de Movimento/Combate. Recuperar foco ou reconectar gamepad não fecha a pausa. Desconectar o gamepad ativo em Jogo pausa; em Bênção/Menu só mostra aviso; outros dispositivos não pausam. **Pendente de alinhamento de design:** desconexão durante Transição não tem a mesma regra explícita de perda de foco; não inferir pausa automática desse caso sem defini-la.

Após recuperar foco, eventos de repetição não rearmam comandos. Entradas conhecidas como seguradas antes da perda continuam exigindo soltura; a reconciliação com o estado físico real no retorno é responsabilidade do adaptador e precisa de teste com hardware.

### 4. Movimento, mira e dispositivo

O provedor aplica F1/F2 uma vez, com teclado não zero vencendo o analógico e módulo analógico preservado. Usa o último gamepad significativo; dados de controles distintos nunca são somados. Havendo atividade significativa simultânea de mouse/teclado e gamepad no mesmo passo, conserva o dispositivo ativo. Critério de empate entre dois gamepads: ordem de recebimento dos eventos, com o último significativo vencedor (proposta de desempate técnico, a validar).

Mira recebe conversão janela → mundo da Cena e consulta de alvos por valores, em ordem estável de spawn, conforme ADR-0003. F4 ignora surgindo, distância zero e alvos fora do raio inclusivo; empate mantém o primeiro. A consulta ocorre no começo do passo: mortes do passo anterior já foram retiradas. Não guarda referência ao inimigo escolhido. Mouse sobre o personagem conserva mira anterior; inicial sem direção usa (0, −1). Cursor fora da janela conserva posição de janela e reconverte a cada passo.

Só a Cena consulta o cursor em render para lookahead; essa leitura não drena bordas nem muda a mira da simulação. Sem `InputTuning`, somente navegação digital, cliques e botões funcionam. Analógicos, gatilhos e troca de dispositivo por movimento do mouse ficam inativos. Não se calcula mira de jogo; a eventual amostra técnica neutra não é oferecida a consumidores de gameplay. Retirar/reinjetar tuning limpa resíduos analógicos e aplica barreira de contexto antes de voltar a admitir ações.

### 5. UI e texto: uma via de execução

O adaptador observa eventos antes de controles os consumirem. A UI recebe comandos de tela do provedor, sem ler `Input` nem `InputEvent`. Um clique identificado pelo adaptador passa por uma consulta de alvo visual; sua confirmação obedece ao mesmo contexto e barreira do teclado. Sinais de hover/foco podem atualizar a seleção visual, mas `pressed` nativo e comandos amostrados não podem executar a mesma confirmação duas vezes. ADR-0012 deve implementar e testar esse bloqueio também para atalhos nativos de `Control`.

Hover chama `grab_focus()` fora de Texto, mantendo um foco navegável; foco visual real permanece a validar no ADR-0012. Cartas 1–3 apenas focam; travas de 500/300 ms pertencem à Tela de bênção. Confirmação usa borda de subida, sem repetição por segurar. Navegação repetida tem política da UI, separada do buffer de combate.

O campo de texto pode receber edição nativa, mas o roteador impede navegação/confirmação de controles vizinhos. Enter com valor inválido mantém edição; Esc ou clique fora cancela sem ativar o controle sob o clique. Entrada em Texto só por teclado/clique. Não confundir códigos físicos usados para binds com caracteres digitados ou rótulos do layout.

### 6. Remapeamento e arquivo do usuário

Propõe-se `user://input_binds.cfg`, `ConfigFile` com `schema_version = 1`, seções por dispositivo e uma seção de opções com `trocar_analogicos`. Cada ação usa lista ordenada de até três descritores simples: tipo (`tecla_fisica`, `mouse`, `botao_gamepad`, `gatilho`) e código. Não serializar objetos `InputEvent`, identificadores de gamepads conectados nem scripts. Movimento de teclado e navegação têm direções identificadas internamente; esses ids não criam ações públicas além da lista R1. Vetores de gamepad não são remapeados.

Carregar valida tipos, limites, códigos permitidos, primários, conflitos por interseção de contextos e Esc/Start fixos. Ação desconhecida é ignorada; ação ausente recebe padrão. Entradas conhecidas inválidas tornam o arquivo inválido, sem aplicar um mapa parcial. Versão futura não suportada usa padrões em memória e preserva o arquivo sem regravar automaticamente. Defaults ficam em dados embarcados independentes do catálogo, para a tela de erros funcionar.

Remapeamento é transação sobre cópia do mapa: resolve a troca de binds conflitantes, valida todos os contextos afetados, garante primários e só então substitui o mapa ativo. Conflito ambíguo com múltiplos donos que não pode ser resolvido por uma troca válida é recusado, sem mudança parcial. `pausar` nunca entra em troca; Esc/Start não são removidos e não podem ser atribuídos a outra ação em Jogo/Pausa/Bênção. No máximo três binds por dispositivo; remover só secundários. Windows/Meta, Print Screen e roda do mouse são recusados.

Captura dura até 5 s; B curto pode virar bind; Esc/Start segurado por 1 s cancela. Para distinguir toque curto e cancelamento longo, candidatos Esc/Start são confirmados apenas na soltura curta, sujeitos às recusas de reserva. Tempos de captura recebem delta real da fronteira, independente de `t_vivo`/`t_apres`, pois a tela pode estar pausada. Cancelar não modifica o mapa. Gatilhos usam histerese do tuning (≥ 0,5 aperta; < 0,4 solta nos ajustes de fábrica).

Salvar escreve temporário, relê/valida e só então substitui o arquivo válido; detalhes de falha/atomicidade no Windows são verificação obrigatória do ADR-0013. Arquivo ruim é preservado byte a byte em `.bak` antes de qualquer substituição; se já existir backup, usar nome adicional sem apagá-lo. Falha ao preservar impede sobrescrita, mas os padrões permitem continuar a sessão. Avisos `INPUT_*` do GDD aparecem uma vez por sessão. Falha de gravação precisa de mensagem própria da UI, ainda a definir, sem fingir persistência bem-sucedida.

`rotulo_acao(acao, dispositivo)` devolve `{texto, glifo}` do bind atual e layout ativo. Inválidos devolvem rótulo vazio e aviso. Restaurar padrão atua só no dispositivo escolhido. Alterar mapa aplica a barreira de contexto para não converter teclas já seguradas em novos comandos.

### Key Interfaces

Contratos propostos, não arquivos de produção:

```gdscript
# ProvedorDeEntrada: lote e consultas são valores/interfaces injetados.
func amostrar(id_passo: int, contexto: StringName, hitstop: bool) -> AmostraDeEntrada
func comandos_do_passo(id_passo: int) -> ComandosDoPasso
func trocar_contexto(contexto: StringName) -> void
func encerrar_passo(id_passo: int) -> void
func configurar_tuning(tuning: Resource) -> void # null retira os ajustes
func rotulo_acao(acao: StringName, dispositivo: StringName) -> Dictionary

# ComandosDoPasso: exige passo e época ainda válidos; consulta não consome.
func quer(acao: StringName) -> bool
func consumir(acao: StringName) -> bool # true se removeu do buffer
```

`consumir` retornar false com Ataque segurado e buffer vazio não desfaz o ataque já executado; `quer` autorizou pela sustentação. Testes podem injetar amostras e capacidades roteirizadas sem dispositivos.

### Implementation Guidelines

- MUST manter `Input`/`InputEvent` na fronteira de input, inclusive em telas; consultas de cursor e foco são interfaces explícitas.
- MUST amostrar uma vez, descartar cada borda uma vez e invalidar capacidades no fim do passo/troca de contexto.
- MUST usar contador único do buffer e bloqueio por entrada física, com dados de ajuste injetados.
- MUST NEVER avançar gameplay por callbacks de teclado, sinais da UI ou eventos de gamepad.
- MUST validar mapa completo antes de publicar e preservar arquivo inválido antes de substituí-lo.
- MUST testar a via nativa da UI para impedir dupla confirmação e bypass da barreira.

## Alternatives Considered

| Alternativa | Benefício | Motivo de rejeição |
|---|---|---|
| Apenas consultar `Input.is_action_just_pressed` em cada consumidor | Pouco código | Acopla consumidores à engine e deixa posse de bordas/contexto distribuída |
| Cada nó tratar `_unhandled_input` | Integração simples com eventos não usados pela UI | Ações passam a depender de consumo da UI e ordem de nós |
| Executar comandos no callback físico | Resposta imediata | Quebra ordem fixa e pode executar entre passos |
| Um prazo por botão | Expiração independente | Contradiz F3/AC-17, que renovam todos os comandos juntos |
| Snapshot com método que altera buffer | API menor | Mistura observação e consumo, permitindo referências antigas afetarem passos novos |

## Consequences

Toques rápidos e comandos durante hitstop têm dono e prazo explícitos. O bloqueio físico impede atravessar telas, e o provedor pode ser testado sem hardware. Em contrapartida, o mapa próprio exige implementar validação, rótulos e roteamento de UI; não basta ativar o mapa padrão da engine. O custo de eventos sem acumulação e as particularidades de foco/layout requerem medição no Windows.

## GDD Requirements Addressed

| Regras | Contrato |
|---|---|
| R1–R3, R13; AC-01–03, 13–14, 20–21 | Mapa fechado, lote entre passos, snapshot e injeção |
| R4–R5, F1–F2/F4–F5; AC-06–12, 37 | Movimento, seleção de dispositivo, consulta de alvos/cursor |
| R6–R7, F3; AC-15–19 | Contador compartilhado, hitstop, consulta e consumo |
| R10–R11; AC-22–24, 35–36, 40 | Época, barreira física, contextos, foco e morte |
| R8; AC-25–32, 39 | Transação de binds, arquivo versionado, rótulos |
| R9; AC-33–34 | Via única de UI e foco; evidência visual no ADR-0012 |
| R12; AC-04–05, 29, 38 | Ajustes injetados, histerese e operação digital sem catálogo |

## Validation Criteria

O [experimento isolado](../../prototypes/input-verificacao/README.md) passou **38 verificações**, zero falhas, saída 0, no Godot 4.7.2. Verifica `Input.parse_input_event` até `Node._input`, toques rápidos, eco, múltiplos binds físicos, descarte/bloqueio na troca, soma de movimentos opostos com acumulação desativada e vetores de F3 para prazo, renovação e hitstop. Coletor e buffer são fixtures independentes; não representam implementação ou integração da camada de produção. O teste sintético não mede agrupamento pelo sistema operacional.

Antes da integração, a suíte deve cobrir todos os AC do GDD, em especial: amostra antiga/capacidade retida; pausa e ataque no mesmo passo; toque já solto durante troca; press/release via `parse_input_event`; movimento de mouse oposto; múltiplos binds e gamepads; retirada/reinjeção de tuning; UI sem dupla ativação; arquivo corrompido com backup exato e falha de gravação; foco em cada tela. Alt+Tab, desconexão real, AZERTY e sensação de resposta exigem teste manual. O experimento headless não encerra esses critérios.

## Migration Plan

Não migrar o protótipo de combate nem copiar automaticamente o experimento. Após aceite e revisão consolidada, implementar a fronteira e provedor com as interfaces propostas. A API 4 da arquitetura passa a separar amostra e consumo; ADR-0001 deve incorporar explicitamente Input/UI fora de Jogo e a invalidação ao trocar estado antes da implementação.
