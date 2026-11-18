# ADR-0014: Telégrafos: registro, ciclo de vida, geometria de acerto e teto de 24

## Status

Accepted · 2026-11-16 (aprovado pelo usuário; Proposed em data do ADR)

## Date

2026-11-15

## Last Verified

2026-11-16 (emenda Pactos; ver "Emenda Pactos e pendências"): conferido com Telégrafos R2a, R2b, R5a, R6a, F7 e Edge Cases do alvo travado, Chefes R3, R5, F2, CH6, Combate R22/R25 e a decisão 10 de `pactos-decisoes-a-confirmar.md`. Conferência anterior, 2026-11-15. Conferido com o GDD de Telégrafos (R1–R11, F1–F6, TV1–TV6, Edge Cases, AC-TG-01..27), com a IA (R5, R6, R8, Edge Cases), com o Combate (R1 Transição, R7, R13, R14, AC-68), com os ADRs 0001, 0002, 0003, 0007 e 0008 e com `docs/engine-reference/godot/`. O que a referência não cobre está marcado NOT SOURCEABLE.

## Decision Makers

Aba de Arquitetura (Claude), com autorização do usuário para escrever em paralelo e revisar no fim. Aceite pendente. Duas escolhas que mexem em regra ficam em "Decisões pendentes do usuário".

## Summary

Os telégrafos vivem num módulo `Telegrafos` de lógica pura (`RefCounted`), com um **pool fixo de `teto_telegrafos` slots** (24 de fábrica), alocado uma vez por run. O ciclo `CRESCENDO → DISPARO | QUEBRADO | CANCELADO → livre` é contado em passos vivos. A IA é quem chama `iniciar_telegrafo` e, se o pool está cheio, recebe `false` e tenta no passo seguinte. O teste de acerto e o desenho usam a mesma geometria, a do módulo `GeometriaDeAcerto` do ADR-0010, que este ADR só consome. A posição nunca é guardada pelo telégrafo: ela é lida do dono (IA) e publicada por valor para a Apresentação. A troca de câmara cancela tudo por meio de uma política injetada, e assim o ADR funciona tanto com o fade de 2 passos do GDD quanto com a liberação imediata recomendada.

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Godot 4.7, pin 4.7.2 |
| **Domain** | Core (Scripting) / Feature |
| **Layer** | Feature |
| **Knowledge Risk** | BAIXO para a regra (só `RefCounted`, `Array` tipado, `Vector2`, `Rect2` e aritmética); MÉDIO para a apresentação, que depende do ADR-0007 (o ADR-0011 depende deste ADR, não o contrário) |
| **References Consulted** | `VERSION.md`, `breaking-changes.md`, `current-best-practices.md`, `deprecated-apis.md`, `modules/physics.md` |
| **Post-Cutoff APIs Used** | Nenhuma API nova. Regras do 4.7 que tocam o código (confirmadas): `override` com retorno tipado não-void exige `return` explícito; escrever um elemento de packed array não chama o setter da propriedade (irrelevante: o pool usa objetos, não packed arrays) |
| **Verification Required** | (1) o resultado de `Vector2.normalized()` com vetor zero não está na referência (NOT SOURCEABLE): o código testa `length_squared() == 0` antes e nunca depende disso; (2) a precisão de `Vector2` nas fronteiras dos ACs (89,9/90,1 px; 78,40°/78,52°; 56/58 px) é NOT SOURCEABLE e vira teste; (3) interpolação física dos nós de telégrafo no mesmo ritmo da âncora do dono depende da verificação do ADR-0007 (NOT SOURCEABLE); (4) custo em GDScript de publicar 24 vistas por passo, a medir |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | ADR-0001 (item 7, passo congelado, final comum, seis ações da Transição); ADR-0002 (eventos tipados; nenhum módulo de regra emite fora de passo vivo); ADR-0003 (slots reutilizáveis, `InimigoRef`, consultas por valor); ADR-0004 (`TelegraphTuning`, `EnemyDef`, validação TV1–TV6); ADR-0007 (camadas `TelegrafoPreenchimento` z −5 e `TelegrafoContorno` z 5, interpolação das âncoras, época do corte); **ADR-0010** (módulo `GeometriaDeAcerto`, `ferir_jogador`, `ferir_maldicao`, `ferir_acuada`, `disparar_projetil` com `alvo_id`, "Quebrou!"). O ADR de Aliados e Invocações **não** é dependência (ver Enables): a consulta "em campo / posição / raio" da Maldição é uma porta `ConsultaDeAlvoMaldicao` definida neste ADR e injetada pelo `Main`; o módulo de Maldições a implementa e depende deste ADR (emenda Pactos) |
| **Enables** | ADR-0017 (implementa `ConsultaDeAlvoMaldicao`), ADR-0011 (Pipeline desenha a partir de `VistaDeTelegrafo`; a aresta 0011 → 0014 é só esta, resolvida na emenda de 2026-11-16); stories de IA e Telégrafos |
| **Blocks** | Nenhum golpe inimigo de produção sai sem este contrato (Combate: "nada acerta sem aviso") |
| **Ordering Note** | Escrito em paralelo com o ADR-0010; assinaturas de `GeometriaDeAcerto` alinhadas com o 0010 §9 na revisão cruzada de 2026-11-15. Se mudarem de novo, só o adaptador interno `FormaDeTelegrafo` muda; a interface pública daqui não |

## Context

### Problem Statement

O GDD de Telégrafos manda para ADR "onde vivem os telégrafos ativos e como a forma de acerto e o desenho dividem a mesma definição", e o `architecture.md` lista o 0014 cobrindo `telegrafos-003/006/010`. Faltam: tipo e capacidade do armazenamento, o que acontece quando o teto estoura, a contagem do ciclo em passos, quem escreve e quem lê a posição, o cancelamento na troca de câmara (que acontece num quadro de render da Transição, quando nenhum passo vivo roda) e duas leituras de borda: o AC-TG-09 e a mira com distância 0. Sem decisão, a IA testaria o golpe com uma conta e o Pipeline desenharia com outra, e o P3 ("o telégrafo nunca mente", Combate AC-68) cairia.

### Current State

A fatia jogável (`src/gameplay/game_session.gd`) guarda `phase = "windup"`, `timer` e `aim` no dicionário do inimigo; o teste do setor está inline em `_enemy_fire` com `cos(deg_to_rad(tele_meio_angulo_graus))`, a mira zero vira `Vector2.DOWN` e `world_view.gd` redesenha a forma com dimensões gravadas no catálogo (`tele_raio_px`, `tele_comprimento_max_px`, `tele_largura_px`). Não há teto, nem estados terminais, nem faixa cortada pela parede.

### Constraints

Lógica pura, sem `SceneTree`, sem `Autoload`, sem `Timer` (AC-TG-21). Tempo é contagem de passos vivos; nada desconta em hitstop, pausa, Bênção ou Transição (R3, AC-TG-05). Item 7 na ordem estável da IA: `varrer()` → `ia.inicio_do_item_7()` → por inimigo vivo (ADR-0018): `portador.avancar(1)` → Status → Telégrafos (progresso) → impacto → IA → `ia.fim_do_item_7()`. O orçamento de CPU do bloco está na tabela do ADR-0001 (Performance Implications). Dimensões derivadas do `EnemyDef` pelas F2–F4, sem cópia gravada (R10). Teto é dado do `TelegraphTuning` (dono semântico: Pipeline R9). Contratos que falam "o jogador" levam `player_id`.

### Requirements

Até 24 telégrafos, no máximo um por inimigo; recusa com pool cheio e reaproveitamento no passo em que uma vaga sai (AC-TG-03); `p = 1 − restante/preparo`; golpe resolvido no mesmo passo do disparo; estados terminais por 2 passos; forma idêntica ao teste de acerto; entrega por quadro de forma, posição, rotação, dimensões, `p`, modo e estado (AC-TG-13).

## Decision

**1. Módulo e registro.** `Telegrafos extends RefCounted`, montado pelo `Main` na fase 7 da inicialização e injetado na IA (iniciar, consultar disparo, testar), no Combate (só `quebrar`), no orquestrador/Câmaras (só `cancelar_todos`) e na Apresentação (só a leitura de vistas). Recebe por injeção o `TelegraphTuning`, a tabela `FormasDeTelegrafo` derivada dos `EnemyDef`, uma `ConsultaDeInimigos` (posição atual e "vivo" por id, dona: IA), uma `ConsultaDeJogadores` (posição por `player_id`, dono: Movimento), a `GeometriaDaCamara` (retângulo jogável e obstáculos circulares em ordem, dona: Câmaras), o `GeometriaDeAcerto` e o `EventosDoPasso`.

**2. Pool fixo e teto.** Um `Array[TelegrafoSlot]` de tamanho `teto_telegrafos`, criado no início da run e nunca redimensionado. Um slot ocupa vaga em `CRESCENDO` **e** nos 2 passos de `DISPARO`, `QUEBRADO` ou `CANCELADO`. A vaga livre escolhida é a de menor índice (determinístico); um `Dictionary` id do inimigo → índice garante "um por inimigo" em O(1). Cada ocupação recebe `seq` crescente, usado só para a ordem de desenho (o mais recente por cima, Pipeline R5). **Estourar o teto:** `iniciar_telegrafo` devolve `false`, não cria nada, não emite evento e incrementa um contador de diagnóstico `recusas_por_teto` (lido pela Telemetria por consulta); a IA continua em aproximação e repete no passo seguinte (R2, IA R5). Não há fila de pedidos, não há despejo do telégrafo mais antigo e não há crescimento do pool: qualquer uma dessas saídas faria um golpe sair diferente do aviso ou estouraria o orçamento de desenho. Um segundo pedido do mesmo inimigo também devolve `false`.

**3. Ciclo de vida contado em passos.**

| Estado | Entra | Sai | Contagem |
|---|---|---|---|
| `CRESCENDO` | `iniciar_telegrafo` aceito; `restante = preparo = passos(preparo_s)`; mira travada | `restante` = 0 → `DISPARO`; `quebrar` → `QUEBRADO`; dono não vivo ou câmara nova → `CANCELADO` | `restante −= 1` por passo vivo, em `avancar(id)` |
| `DISPARO` | `restante` chega a 0 | vaga livre quando `passos_no_estado` = 2 | `passos_no_estado += 1` em `varrer()` |
| `QUEBRADO` | pedido do Combate no item 5 | idem | idem |
| `CANCELADO` | dono morto; troca de câmara (Decisão 7) | idem, ou imediato pela política | idem |

`varrer()` roda uma vez por passo vivo, no início do item 7, antes do laço de inimigos: incrementa os terminais e libera os que chegaram a 2, e cancela todo `CRESCENDO` cujo dono deixou de estar vivo (morte nos itens 5, 6, 8 ou 9 do passo anterior). Liberar antes do laço faz o 25º pedido ser aceito no mesmo passo em que uma vaga sai (AC-TG-03, AC-TG-25). `avancar(id)` roda no laço do item 7 depois do Status do inimigo e antes do impacto e da IA: se o Status acabou de matar o dono, cancela; senão decrementa. Em passo congelado nenhuma das duas roda (AC-TG-05). A IA **não** guarda um segundo contador de preparo: ela lê `disparou_neste_passo(id)` e executa o golpe no mesmo item (R4, IA R5/R6). `quebrar(id)` só age em `CRESCENDO`; como o item 5 vem antes do item 7, um "Quebrou!" no passo em que `restante` chegaria a 0 vence (Edge Case). Elite e chefe não chamam `quebrar` (regra do Combate R8.7).

**4. Geometria: consumida do ADR-0010.** Este ADR não define geometria. Ele consome de `GeometriaDeAcerto` (dono: ADR-0010 §9) as funções abaixo, com as assinaturas do 0010 (alinhado na revisão cruzada de 2026-11-15), todas puras e com distâncias comparadas ao quadrado:

- **setor contra ponto**: `setor_toca(apice, mira, cos_meio, raio, ponto, 0.0)`, inclusivo nas duas fronteiras, com distância 0 contando como dentro (F2: "com distância 0 o produto escalar vale 1"; o 0010 define `d = 0 → u = dir`);
- **retângulo orientado contra ponto**: `retangulo_orientado_toca(centro, mira, meio_comp, meia_largura, ponto, 0.0)`, isto é, contra círculo de raio 0, que é o caso da R6 ("o centro do jogador dentro da forma"); o adaptador converte `x_min..x_max` em `centro = origem + mira × (x_min + x_max)/2` e `meio_comp = (x_max − x_min)/2`;
- **contato círculo-círculo estrito**: `circulos_encostam(a, b, r_soma)` (`<`), para o avanço (F4, AC-TG-12);
- **alcance de raio**: `alcance_do_raio(origem, dir, l_max, retangulo, obstaculos) -> float`, distância do centro ao primeiro encontro com a borda do retângulo jogável ou com a superfície de um obstáculo circular, limitada a `l_max`. Fica no ADR-0010 §9 (decidido na revisão cruzada), não no 0008 nem neste módulo.

O adaptador interno `FormaDeTelegrafo` monta, a partir do slot, da posição atual do dono e da tabela derivada, os parâmetros dessas chamadas. **A mesma montagem** serve ao teste de acerto da IA (`dentro(id, ponto)`) e à vista publicada para o Pipeline: não existe uma segunda conta de raio, ângulo, origem ou comprimento em IA, Combate ou Apresentação. Convenções: `SETOR` tem ápice no centro do dono; `RETANGULO` de faixa tem origem no centro do atirador (`x_min` 0); `RETANGULO` de avanço tem `x_min = −R_c` (57 px atrás). O limiar do setor é guardado como produto escalar (`cos_meio` = 0,2 do cânone, vindo do catálogo), nunca recalculado de graus.

**5. Interpretação do AC-TG-09 (faixa do projétil).** `comprimento = min(saida + alcance + r_acerto, alcance_do_raio(centro_do_atirador, mira, ...))`, medido **ao longo da linha central** da mira: "parede a 600 px" é a distância do centro do atirador à borda do retângulo jogável nessa linha; "obstáculo a 400 px" é a distância à **superfície** do círculo do obstáculo. Uma pedra que só toca a lateral da faixa (81 px) não a corta. O projétil some um pouco antes da superfície (Combate R7: `r_obstaculo + 0,5 × raio`), então a faixa nunca é menor que o perigo. O comprimento é recalculado a cada publicação, porque a âncora acompanha o dono empurrado (R3). Comprimento ≤ 0 (atirador encostado) não impede o disparo; o desenho trata o caso no ADR-0011.

**6. Mira com distância 0.** Em `iniciar_telegrafo`, `delta = pos(alvo) − pos(dono)`; se `delta.length_squared() == 0`, a mira é `(1, 0)`; senão, `delta / delta.length()`. A fatia usa `Vector2.DOWN`; o alvo é `(1, 0)`, igual ao exemplo de referência do GDD (atacante em (0; 0), mira (1; 0)) e independente do comportamento de `normalized()` com zero (NOT SOURCEABLE). Com distância 0 no **teste** do setor, o ponto conta como dentro (F2).

**7. Troca de câmara.** As seis ações da Transição rodam num quadro de render, fora de passo vivo. Na ação 3, **antes** de as Câmaras desmontarem a lista de inimigos, o orquestrador chama `telegrafos.cancelar_todos()`, que copia a âncora de cada slot ativo para o próprio slot (o dono vai sumir) e aplica a `PoliticaDeTroca` injetada:

- `FADE_DOIS_PASSOS` (GDD R7 e AC-TG-16 literais): todos viram `CANCELADO` com `passos_no_estado` = 0; a vaga sai em 2 passos. Como a R7 diz "some em 2 passos" (sem "vivos") para o cancelado, nesta política os cancelados **por troca** contam também os passos físicos da Transição posteriores à troca, por meio de `passo_de_transicao()` chamado pelo orquestrador; sem isso eles ficariam parados, visíveis sobre a câmara nova durante toda a segunda metade do wipe. Resultado: ≈ 33 ms na câmara nova, nas posições antigas.
- `LIBERAR_JA` (recomendação da aba): os slots são liberados na hora; nada da câmara velha chega à câmara nova.

Em nenhuma das duas há evento: o ADR-0002 proíbe módulo de regra emitir fora de passo vivo, e a Apresentação lê o estado por vista. **Decisão do usuário (2026-11-15): `LIBERAR_JA`** é a política do jogo, e o GDD de Telégrafos (R7, AC-TG-16) foi ajustado. `FADE_DOIS_PASSOS` fica só como alternativa documentada; voltar a ela é mudar uma linha da composição no `Main`.

**8. Quem escreve e quem lê a posição.** O telégrafo não tem posição própria enquanto o dono existe: a âncora é a posição atual do dono, escrita só pela IA (e pelos empurrões que o Combate pede à IA). Depois de cancelado por troca, vale a âncora copiada. No final comum de cada passo físico (ADR-0001), `publicar(vistas)` preenche um `Array[VistaDeTelegrafo]` pré-alocado com valores desvinculados (ADR-0003): `slot` (índice 0..`teto_telegrafos`−1 do pool, estável durante toda a ocupação; é a chave do par de nós no pool do ADR-0011), id do dono, `seq`, forma, posição, rotação (`mira.angle()`), dimensões, `p`, modo, estado e `passos_no_estado`. A Apresentação (nó do Pipeline, ADR-0011) lê esse array, mantém um par de itens por **slot** (pool fixo do ADR-0011), preenchimento em `TelegrafoPreenchimento` (z −5) e contorno em `TelegrafoContorno` (z 5), ligados ao mesmo id lógico (ADR-0007 §4); slot ausente da publicação fica `visible = false`, e a troca de dono num slot reinicia a interpolação do par, e atribui a posição no passo de física com interpolação ON, como as âncoras dos corpos, para andar junto com o dono; a ordem entre telégrafos dentro da camada é por `seq`. A Apresentação nunca escreve no módulo.

**9. Alvo travado (emenda Pactos, 2026-11-16; Telégrafos R2a, R6a, F7; Chefes R3; decisão 10).** `iniciar_telegrafo` guarda no slot o **alvo travado** do dono (`alvo_faccao`, `alvo_id`) e o **raio dele** (`raio_alvo`), lidos da consulta de alvos (jogador: Movimento; Maldição: `MaldicaoRef`, ADR-0017; acuada: Vínculo, IA R22). A mira travada é a direção do dono ao alvo (distância 0 continua `(1, 0)`, Decisão 6). Alvo, raio e dimensões **não mudam** até o slot ser liberado, mesmo que a atração acabe ou comece no meio do preparo. O teste (`dentro`) é contra o centro do alvo travado e **só ele**: a IA e o chefe chamam `ferir_jogador`, `ferir_maldicao` ou `ferir_acuada` conforme `alvo_faccao`, e um telégrafo mirado na Maldição ou na acuada não fere o jogador, mesmo que ele esteja dentro da forma (R6a). Isso vale para **todo golpe do chefe, inclusive os 12 projéteis radiais**: eles saem por `disparar_projetil(..., alvo_faccao, alvo_id)` do ADR-0010 e testam só o alvo travado do padrão. O puxão da *Convergência* e o pulso da `TransicaoFase` não são golpes: movem jogador e Maldição em campo antes do teste, qualquer que seja o alvo (Chefes R3, R5.4, R7).

**10. Faixa e dimensões pelo raio do alvo.** `FormasDeTelegrafo.derivar(def, raio_alvo)` passa a receber o raio do alvo travado (F7) em lugar do raio fixo do jogador. A faixa do projétil (Decisão 5), o setor e o avanço (`R_c = raio_atacante + raio_alvo`, retângulo de comprimento `percurso + 2 × R_c` e largura `2 × R_c`) usam esse raio: *Baluarte de Cinza* 30 px, *Soberano do Limiar* 28,5 px, *Vulto Mudo* 24 px, *Espreitador da Fenda* 22,5 px, jogador 27 px. Contra o jogador nada muda (retângulo do Padrão 1: 414 × 144 px; contra o Baluarte, 420 × 150 px). Os padrões do chefe vêm do `BossPatternDef` (Chefes R11), pelo mesmo adaptador `FormaDeTelegrafo`; formas `ANEL` e `CIRCULO` entram no MVP, e não mais "só no Vertical Slice". A validação TV1/TV2 e CH1/CH4/CH6 usa o mesmo `derivar()`.

**11. Contorno secundário.** O contorno tracejado de aviso do puxão (420 px, Padrão 3 do chefe; Telégrafos R5a) é o **segundo contorno do mesmo telégrafo** (um por dono, R1): sem preenchimento e **fora do teto**. A `VistaDeTelegrafo` ganha `contorno_secundario_raio: float` (0 = ausente), publicado na mesma passada do contorno (z 5, ADR-0007). A vista também publica `alvo_faccao` para que o Pipeline distinga o telégrafo mirado na Maldição; o desenho é o da mesma forma e o perigo para o jogador é nenhum (R6a). O contrato do traço secundário depende do ADR-0011 e é **[a confirmar]** no GDD (R5a).

**12. Teto de 24 com o chefe.** Verificado em `chefes.md`: o teto **ainda vale**. O chefe tem um telégrafo por vez (um por dono) e os lacaios `eco_perdido` vêm até `max_lacaios_vivos` = 3, então o pior caso da câmara do chefe é 1 + 3 = 4 telégrafos (F3 do Chefes: "nunca passa de 4 ≪ `teto_telegrafos` (24)"); a validação CH6 avisa se `1 + max_lacaios_vivos` passar de 24 (hoje 4). O pior caso do MVP continua sendo uma onda de 9 inimigos (9 telégrafos), e a Maldição nunca cria telégrafo de chão (R2b), então os golpes dela não entram na lista nem no teto. O pool de 24 slots, a recusa com `false` e a vaga de menor índice ficam como estão; a acuada e os inimigos que a miram contam como qualquer inimigo.

### Architecture Diagram

```text
passo vivo, item 7 (ADR-0001)
  Telegrafos.varrer()                     terminais +1, libera em 2; CRESCENDO com dono morto -> CANCELADO
  ia.inicio_do_item_7()                   avança os Chefes, cria os lacaios (ADR-0018)
  para cada inimigo vivo (ordem estável da IA):
    portador_do_inimigo.avancar(1)        IA; durações genéricas (ADR-0009 §6)
    Status.tick(id)
    Telegrafos.avancar(id)                restante -= 1; 0 -> DISPARO (+ TelegrafoDisparou)
    Combate.impacto(id)                   empurrão move o dono (âncora segue)
    IA.passo(id)
      disparou_neste_passo(id)? SETOR: só o alvo travado (alvo_de(id)), dentro(id, pos) -> ferir_jogador | ferir_maldicao | ferir_acuada
                                FAIXA: disparar_projetil(mira travada)
                                AVANÇO: inicia avanço (contato 1x por avanço e por jogador, estado da IA)
      entra em preparo? iniciar_telegrafo(id, ataque, alvo_id) -> false se teto ou já tem
  ia.fim_do_item_7()                      separação par a par; depois item 8
final comum do passo: Telegrafos.publicar(vistas[24])  ->  Pipeline (só leitura)
quadro da metade do wipe, ação 3: Telegrafos.cancelar_todos()  (política injetada)

FormaDeTelegrafo (adaptador interno) --chama--> GeometriaDeAcerto (ADR-0010)
```

### Key Interfaces

```gdscript
# telegrafo_tipos.gd
class_name TelegrafoTipos
enum Forma { CIRCULO, SETOR, RETANGULO, ANEL }          # CIRCULO e ANEL: chefe (Vertical Slice)
enum Modo { CENTRO_A_BORDA, AO_LONGO_DO_EIXO, BORDA_AO_CENTRO }
enum Estado { CRESCENDO, DISPARO, QUEBRADO, CANCELADO }
enum PoliticaDeTroca { FADE_DOIS_PASSOS, LIBERAR_JA }

# vista_de_telegrafo.gd: valores por passo; a Apresentação pré-aloca e só lê
class_name VistaDeTelegrafo extends RefCounted
var slot: int; var dono_id: int; var seq: int   # slot: chave do pool de nós do ADR-0011
var forma: TelegrafoTipos.Forma; var modo: TelegrafoTipos.Modo; var estado: TelegrafoTipos.Estado
var pos: Vector2; var rot: float
var raio: float; var cos_meio: float; var x_min: float; var comprimento: float; var largura: float
var p: float; var passos_no_estado: int
var alvo_faccao: Combate.Faccao; var contorno_secundario_raio: float   # emenda Pactos; 0 = sem contorno secundário

# telegrafos.gd
class_name Telegrafos extends RefCounted
## Implementa design/gdd/telegrafos.md R1–R11. Lógica pura; tempo em passos vivos.
func configurar(tuning: TelegraphTuning, formas: FormasDeTelegrafo, inimigos: ConsultaDeInimigos,
		jogadores: ConsultaDeJogadores, camara: GeometriaDaCamara, geo: GeometriaDeAcerto,
		eventos: EventosDoPasso, politica: TelegrafoTipos.PoliticaDeTroca) -> void
func iniciar_run() -> void                                   # aloca o pool uma vez
func iniciar_telegrafo(inimigo_id: int, ataque: AttackDef, alvo_id: int = 0,
		alvo_faccao: Combate.Faccao = Combate.Faccao.JOGADOR) -> bool   # trava alvo e raio (Decisão 9)
func alvo_de(inimigo_id: int) -> Vector2i                    # (faccao, id) do alvo travado; a IA e o chefe escolhem ferir_*
func varrer() -> void                                        # início do item 7
func avancar(inimigo_id: int) -> void                        # item 7, depois do Status
func disparou_neste_passo(inimigo_id: int) -> bool
func dentro(inimigo_id: int, ponto: Vector2) -> bool         # mesma montagem da vista
func mira_de(inimigo_id: int) -> Vector2
func quebrar(inimigo_id: int) -> bool                        # só em CRESCENDO
func cancelar(inimigo_id: int) -> void                       # dono morto
func cancelar_todos() -> void                                # ação 3 da Transição
func passo_de_transicao() -> void                            # só tem efeito com FADE_DOIS_PASSOS
func ativos() -> int
func recusas_por_teto() -> int
func publicar(saida: Array[VistaDeTelegrafo]) -> int         # sem alocar; devolve quantas valem

# Eventos (subclasses @abstract de EventoDoPasso, ADR-0002), só ids e valores:
# TelegrafoIniciado(dono_id, alvo_id, forma), TelegrafoDisparou(dono_id, forma),
# TelegrafoCancelado(dono_id, causa). A quebra segue o evento `quebrou` do Combate.
```

### Implementation Guidelines

- `Telegrafos` **must** ser `RefCounted` puro; **must never** criar `Node`, `Area2D`, corpo de física ou `Timer` por telégrafo.
- O pool **must** ter exatamente `teto_telegrafos` slots, alocados em `iniciar_run()`; `iniciar_telegrafo` **must never** alocar, crescer o array, enfileirar pedido ou despejar outro telégrafo.
- Slots terminais **must** contar para o teto até liberados; a vaga **must** ser a de menor índice; a simulação **must never** depender da ordem dos slots.
- `varrer()` e `avancar()` **must** rodar só em passo vivo, na ordem da Decisão 3; a IA **must never** manter contador paralelo de preparo.
- O teste de acerto e a vista **must** sair do mesmo `FormaDeTelegrafo`, que **must** chamar `GeometriaDeAcerto`; **must never** existir conta de forma em IA, Combate, Pipeline ou neste módulo fora do adaptador.
- A mira **must** ser travada em `iniciar_telegrafo` e **must never** ser reescrita; vetor zero vira `(1, 0)` por teste explícito.
- `cancelar_todos()` **must** rodar antes de as Câmaras removerem os inimigos e **must never** emitir evento.
- O golpe **must** testar só o alvo travado (Decisão 9), que pode ser um jogador, uma Maldição ou a acuada, e chamar o `ferir_*` correspondente no máximo uma vez por golpe; **must never** percorrer "todos os jogadores" (emenda Pactos; substitui a regra anterior de iterar a lista de jogadores).
- `publicar()` **must** preencher vistas pré-alocadas e **must never** expor `TelegrafoSlot` nem `InimigoRef`.
- Dimensões **must** vir de `FormasDeTelegrafo.derivar()`, a mesma função do validador TV2; **must never** ser lidas de campos gravados no catálogo.
- Todo `override` com retorno tipado **must** ter `return` explícito (4.7).

## Alternatives Considered

### Alternative 1: Lista que cresce, um objeto novo por telégrafo
- **Description**: `append` ao criar, `remove_at` ao liberar, teto como `size() < 24`.
- **Pros**: código menor.
- **Cons**: alocação dentro do passo, ordem mutável, referência antiga podendo apontar para objeto já fora da lista.
- **Rejection Reason**: o teto já fixa o tamanho; o pool não custa nada e o ADR-0003 já previa vagas reutilizáveis.

### Alternative 2: Ao estourar, despejar o telégrafo mais antigo ou enfileirar o pedido
- **Description**: em vez de recusar, cancelar o mais velho, ou guardar o pedido para quando abrir vaga.
- **Pros**: o inimigo nunca "espera".
- **Cons**: despejar cancela um golpe já anunciado (o jogador leu um aviso que some sem motivo); a fila cria um preparo que começa em passo diferente do decidido pela IA.
- **Rejection Reason**: contraria R2 e IA R5, que já decidem a recusa com nova tentativa.

### Alternative 3: Telégrafo como nó com `Area2D` e raycast
- **Description**: forma como colisor e faixa por consulta de física.
- **Pros**: ferramentas do editor.
- **Cons**: exige `SceneTree`, duplica a forma (colisor × desenho), o setor não é forma nativa, e o raycast 2D não está na referência (NOT SOURCEABLE).
- **Rejection Reason**: quebra a lógica pura e a fonte única da forma.

## Consequences

### Positive
P3 garantido por construção (AC-68): o que fere e o que se desenha vêm da mesma montagem. Teto, "um por inimigo" e liberação viram contas O(1) sem alocação. A decisão da troca de câmara fica isolada numa política, sem reescrita.

### Negative
O comprimento da faixa é recalculado a cada publicação (custo pequeno, não medido). A política `FADE_DOIS_PASSOS` exige um ponto extra na Transição (`passo_de_transicao`). O ADR depende de `alcance_do_raio`, agora no ADR-0010 §9 (revisão cruzada de 2026-11-15).

### Neutral
`CIRCULO` e `ANEL` existem no enum sem uso no MVP (chefe, Vertical Slice).

## Risks

- **Assinaturas do 0010 mudarem** (já alinhadas em 2026-11-15, incluindo `alcance_do_raio` e `circulos_encostam`): mitigação, só o adaptador `FormaDeTelegrafo` muda.
- **Fronteiras numéricas**: mitigação, comparar ao quadrado, limiar 0,2 guardado como produto escalar, testes nos valores exatos dos ACs.
- **Telégrafo adiantado em relação ao corpo interpolado**: mitigação, a posição é atribuída no passo de física com interpolação ON, igual à âncora; confirmar na verificação do ADR-0007; reset de interpolação na época do corte.
- **Dono removido entre passos**: mitigação, `varrer()` cancela antes do laço.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|---|---|---|
| telegrafos.md | R1, AC-TG-03 (um por inimigo) | Índice id → slot recusa o 2º |
| telegrafos.md | R2, AC-TG-02/03/25 (mira travada, teto) | Mira travada em `iniciar_telegrafo`; recusa com pool cheio; vaga liberada no início do item 7 |
| telegrafos.md | R3/F1, AC-TG-01/04/05/06 | `avancar()` só em passo vivo; âncora lida do dono; preparo não depende de Selo nem Abalo |
| telegrafos.md | R4, AC-TG-10/14 | `disparou_neste_passo()` lido pela IA no mesmo item |
| telegrafos.md | R5/R10/F2–F4, AC-TG-07/09/11/26 | `FormasDeTelegrafo.derivar()`; Decisão 5 para o AC-TG-09 |
| telegrafos.md | R6/F5, AC-TG-08/12/27; combate-nucleo.md R13, AC-68 | `FormaDeTelegrafo` sobre `GeometriaDeAcerto` |
| telegrafos.md | R7, States, AC-TG-15/16/25 | `quebrar`, `cancelar`, `cancelar_todos` com política; 2 passos |
| telegrafos.md | Interactions, AC-TG-13 | `publicar()` com `VistaDeTelegrafo` |
| telegrafos.md | TV1–TV6, AC-TG-19/20 | Validador usa o mesmo `derivar()` (ADR-0004) |
| telegrafos.md | R11, AC-TG-21 | Tudo injetado; testes sem `SceneTree` |
| telegrafos.md | R2a, R6a, Edge Cases do alvo travado (TR-telegrafos-015) | Decisão 9: alvo e raio travados no slot; teste só contra o alvo travado |
| telegrafos.md | F7, R5 (TR-telegrafos-016) | Decisão 10: `derivar(def, raio_alvo)`; faixa, setor e avanço pelo raio do alvo |
| telegrafos.md | R5a, Edge Cases do chefe (TR-telegrafos-015, TR-chefes-004, TR-chefes-005) | Decisões 9 e 10: 4 padrões do chefe; todo golpe e os 12 projéteis testam só o alvo travado |
| telegrafos.md | R7a, Acréscimos do orquestrador (TR-telegrafos-017) | `cancelar(id)` com causa `TRANSICAO_FASE` na transição de fase e no abate do chefe |
| telegrafos.md | R5a, contorno do puxão (TR-pipeline-014, TR-chefes-006) | Decisão 11: contorno secundário fora do teto; `alvo_faccao` na vista |
| telegrafos.md | R2b, TV5 (TR-telegrafos-016, TR-chefes-017) | Decisão 12: teto 24 com chefe (pior caso 4) e sem telégrafo de chão da Maldição |
| chefes.md | R3, R5, F2, F3, CH6, decisão 10 (TR-chefes-004, TR-chefes-005, TR-chefes-017) | Decisões 9, 10 e 12 |
| combate-nucleo.md | R22, R25 (TR-combate-nucleo-021, TR-combate-nucleo-022) | Decisão 9: `ferir_maldicao`/`ferir_acuada` pelo alvo travado |
| ia-de-inimigos-e-elites.md | R5, R6, R8, AC-IA-05/06/11 | Recusa → aproximação; golpe no mesmo passo; sem contador paralelo |
| combate-nucleo.md | R1 Transição (ação 3), R14 | `cancelar_todos()` na ação 3; morto não dispara |
| co-op-ganchos.md | telegrafos.md R2, R4/R6 | `alvo_id` (0 no solo); teste por jogador |

## Performance Implications

- **CPU**: por passo vivo, até 24 incrementos em `varrer()` e um `avancar()` por inimigo; por passo físico, até 24 montagens em `publicar()`, com a faixa custando um teste contra o retângulo e até N círculos. Esperado muito abaixo de 0,05 ms; a medir.
- **Memory**: 24 slots e 24 vistas pré-alocados.
- **Load Time**: derivar as formas de ~6 `EnemyDef`, desprezível.
- **Network**: N/A no MVP.

## Migration Plan

1. Criar `TelegrafoTipos`, `VistaDeTelegrafo`, `FormasDeTelegrafo` e `Telegrafos` em `src/` com testes em `tests/unit/telegrafos/` usando dublês de `GeometriaDeAcerto` até o 0010 existir.
2. Em `game_session.gd`, trocar `phase == "windup"`/`timer`/`aim` por chamadas a `Telegrafos`; tirar o teste inline de `_enemy_fire`; mira zero passa de `Vector2.DOWN` a `(1, 0)`.
3. Em `world_view.gd`, desenhar a partir de `VistaDeTelegrafo` em vez de reler o catálogo.
4. Remover `tele_raio_px`, `tele_comprimento_max_px`, `tele_largura_px` e `tele_meio_angulo_graus` do catálogo da fatia (R10: dimensões derivadas), com o limiar 0,2 guardado como produto escalar onde o ADR-0004 indicar.
5. Ligar `cancelar_todos()` na ação 3 da Transição quando o orquestrador do ADR-0001 substituir a fatia.

## Validation Criteria

- AC-TG-01..21 e 25..27 passam em testes unitários sem `SceneTree`.
- Teste de pool: 1000 ciclos de iniciar/liberar sem crescer o array; 25º pedido recusado e aceito no passo em que uma vaga sai.
- Teste de equivalência (AC-68): numa grade de 3 px em volta de cada forma do MVP, `dentro()` coincide com a região da vista publicada.
- Teste de ordem: "Quebrou!" no item 5 do passo em que `restante` chegaria a 0 impede o golpe; dono morto entre passos vira `CANCELADO` e não dispara.
- Teste das duas políticas de troca: com `LIBERAR_JA`, `ativos()` = 0 logo após `cancelar_todos()`; com `FADE_DOIS_PASSOS`, = 0 após 2 `passo_de_transicao()`.
- Mira com distância 0 dá `(1, 0)`; jogador no centro do dono está dentro do setor.
- Teste co-op em memória: 2 jogadores no setor, `ferir_jogador` uma vez para cada.

## Nota de preparação para co-op

O alvo do telégrafo é um jogador da lista, escolhido pela IA e passado como `alvo_id` (`player_id`, 0 no solo); só a mira usa o alvo. (Emenda Pactos: o teste agora é contra o alvo travado, não contra todos os jogadores; no co-op futuro o alvo travado continua único por telégrafo.) O contato do avanço "uma vez por avanço" é guardado pela IA por jogador. O teto de 24 e a legibilidade precisam ser reaferidos com 4 jogadores (co-op-ganchos). Cancelar quando o alvo travado sai fica para o design do co-op. Nenhum código de rede.

## Emenda Pactos e pendências (2026-11-16)

Resume o que mudou no corpo. Nenhuma regra de jogo mudou; o aceite continua pendente.

- **Alvo travado (Decisão 9).** O slot guarda `alvo_faccao`, `alvo_id` e o raio do alvo. Todo golpe do chefe testa só o alvo travado, inclusive os 12 projéteis radiais (decisão 10, Chefes R3). Um telégrafo mirado na Maldição ou na acuada não fere o jogador.
- **Faixa e dimensões pelo raio do alvo (Decisão 10).** `derivar(def, raio_alvo)` no lugar do raio fixo do jogador; padrões do chefe via `BossPatternDef`; `ANEL` e `CIRCULO` passam a existir no MVP.
- **Contorno secundário (Decisão 11).** O tracejado do puxão (420 px) é o segundo contorno do mesmo telégrafo, fora do teto; a vista ganha `contorno_secundario_raio` e `alvo_faccao`.
- **Teto 24 com o chefe (Decisão 12).** Verificado em `chefes.md` (F3, CH6): continua valendo; pior caso do chefe é 4 telégrafos, o do MVP é 9, e a Maldição não cria telégrafo de chão.
- **Pendência de dependência 0011 → 0014 (revisão de 2026-11-15, §Fase 4, item 2).** O 0011 sai de Depends On e de Knowledge Risk deste ADR e fica só em Enables; a aresta é 0011 depende de 0014. A menção ao 0011 na Decisão 8 e em Related é referência, não dependência.
- **Acréscimos do orquestrador.** `CIRCULO` e `ANEL` passam a ser usados no MVP: o chefe usa `SETOR`, `RETANGULO`, `ANEL` e `CIRCULO`. Nova causa de cancelamento `TransicaoFase` (Chefes R7a, OQ2): na transição de fase o chefe chama `cancelar(id)` com causa `TRANSICAO_FASE` e o telégrafo em `CRESCENDO` vira `CANCELADO` (vaga em 2 passos, `TelegrafoCancelado(dono_id, causa)`); o mesmo vale no abate do chefe, que cancela o telégrafo ativo. O teste de acerto deixa de percorrer "todos os jogadores" e testa só o alvo travado, que pode ser uma Maldição (Guideline e diagrama ajustados; a Nota de co-op abaixo fica subordinada a esta regra). A máquina de estados do chefe é do ADR-0018 (só referenciado).
- **ADR-0017** entra em Depends On (posição, raio e "em campo" da Maldição); o 0010 já cobre `ferir_maldicao`, `ferir_acuada` e `alvo_id` no projétil.
- Linhas novas na tabela GDD Requirements: TR-telegrafos-015 a 017, TR-pipeline-014, TR-chefes-004, 005, 006 e 017, TR-combate-nucleo-021 e 022 (ids oficiais do `tr-registry.yaml`).
- **A confirmar:** o contrato do traço secundário com o Pipeline (GDD R5a); o 0011 deve declarar 0014 em Depends On na própria emenda.

## Related

ADR-0001, 0002, 0003, 0004, 0007, 0010, 0011, 0017 (0008 só por referência). GDDs: `design/gdd/telegrafos.md`, `ia-de-inimigos-e-elites.md`, `combate-nucleo.md`, `pipeline-visual.md`, `camaras-e-ondas.md`, `co-op-ganchos.md`. `docs/architecture/architecture.md` (Module Ownership, Data Flow 1, API 7, Required ADRs).

## Decisões do usuário (resolvidas em 2026-11-15)

**O usuário aceitou todas as recomendações abaixo em 2026-11-15.** Elas valem como decisão deste ADR; o texto de cada item fica como registro das opções.

1. **Telégrafos na troca de câmara.** (a) Manter o GDD (R7, AC-TG-16): fade de 2 passos, ≈ 33 ms visível na câmara nova nas posições antigas; (b) liberar na hora, sem fade (muda R7 e AC-TG-16). **Recomendação: (b)**: a tela está coberta no corte, e um fantasma da câmara velha sobre a nova é ruído no topo da escada de valor. O código já suporta as duas (Decisão 7); hoje fica (a) até a sua decisão.
2. **Leitura do AC-TG-09 (Decisão 5).** Confirmar que a faixa vai até a superfície da pedra pela linha central (o projétil some ~6,75 px antes), ou preferir que termine onde o projétil some. Recomendação: superfície, porque o desenho nunca fica menor que o perigo.
3. **Mira com distância 0.** Confirmar `(1, 0)` (a fatia usa para baixo). Alternativa: última direção do inimigo, que exige campo novo na IA. Recomendação: `(1, 0)`, porque é determinístico e o caso é quase impossível com os corpos se empurrando.
