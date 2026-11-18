# ADR-0010 — Resolução do combate no passo

## Status

Accepted · 2026-11-16 (aprovado pelo usuário; Proposed em 2026-11-15)

## Date

2026-11-15

## Last Verified

2026-11-17 (experimento EX-0010-1: `RenderingServer.frame_post_draw` marcado como Verificado, 1 vez por quadro, pior caso medido `33,33 ms ≤ 50 ms` para o `AC-92`). Antes: 2026-11-16 (emenda Pactos e pendências da revisão de 2026-11-15; ver "Emenda Pactos e pendências"). Conferido na emenda: Combate núcleo R1, R3.1, R14, R20–R25; Chefes R3, R9, R9b; `pactos-decisoes-a-confirmar.md` itens 5, 7, 10 e 11. Conferência anterior, 2026-11-15. Fontes conferidas: Combate núcleo R1–R18, F1–F10, Edge Cases e AC-44/81/85/89–92/95–97; Movimento R8 e AC-26 (revisada pelo usuário em 2026-11-15, commit `bd026a7`); Selo F1 e AC-SF-26; architecture.md v1.4 (Module Ownership, API Boundaries, Data Flow, Preparação para co-op). Status R2–R4 e AC-ST-08 aparecem aqui como estão na arquitetura e na revisão.

## Decision Makers

Aba de Arquitetura, com a autorização do usuário para propor os ADRs 0009–0014 em paralelo. O aceite fica pendente. Este ADR não altera nenhuma regra de jogo: o que mudaria número ou sensação está em "Decisões pendentes do usuário".

## Summary

O Combate passa a ser um módulo puro (`RefCounted`) com cinco entradas de passo, uma para cada item que ele possui na R1 (3, 5, 7-impacto, 8 e 9). Ele guarda o contador de hitstop, os recursos de cada jogador (Vida inteira, escudo, recusas, invulnerabilidade e contadores de golpe), os projéteis em voo e o empurrão dos inimigos. Todo teste de acerto passa por um único módulo de geometria, `GeometriaDeAcerto`, com funções estáticas puras, que o ADR-0014 reaproveita. O hitstop é pedido só pela tabela R10, por quem originou o golpe, e nunca pelo impacto. Isso separa o marcador `pesado` do impacto do pedido de congelamento e fecha o achado 8 da revisão.

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Godot 4.7, pin 4.7.2 |
| **Domain** | Core / lógica de jogo |
| **Layer** | Core |
| **Knowledge Risk** | BAIXO na lógica, que é aritmética pura. ALTO só na AC-92 (sinal de fim de quadro) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `current-best-practices.md`, `modules/physics.md` (só para confirmar que nenhuma API de física é usada) |
| **Post-Cutoff APIs Used** | `@abstract` (4.5) nas classes base de eventos e contratos. A regra 4.7 de `override` com retorno tipado (exige `return` explícito) vale para as subclasses |
| **Verification Required** | (1) teste de `FormulasDeModificadores.arredondar_meio_longe_do_zero` (ADR-0009) no meio exato (x,5 para longe do zero, como F2/F10 exigem), com os exemplos da F10; o ADR não usa `round()`/`roundi()`; (2) custo da AC-81 no build real; (3) `RenderingServer.frame_post_draw` como sinal de fim de desenho do quadro para a AC-92: **Verificado (EX-0010-1, 2026-11-16)** — dispara exatamente 1 vez por quadro (936/936 quadros), golpe no 1º passo de física pós-toque, pior caso medido `33,33 ms ≤ 50 ms` com vsync a 60 Hz (`22,13 ms` sem vsync a 144 fps; ver "Verificação de engine (2026-11-16)") |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | [ADR-0001](adr-0001-orquestrador-do-passo.md) (itens do passo, final comum, `pedir_estado`), [ADR-0002](adr-0002-canal-de-eventos.md) (lista de eventos, chamadas diretas tardias), [ADR-0003](adr-0003-entidades-e-portadores.md) (registros e ids), [ADR-0004](adr-0004-catalogo-de-dados.md) (`CombatTuning`, `AttackDef`, CV1–CV22), [ADR-0006](adr-0006-input-por-passo.md) (`ComandosDoPasso`), [ADR-0008](adr-0008-movimento-e-colisao-propria.md) (contrato Movimento↔Combate, `resolver_colisao_informando`), ADR-0009 (portador: `valor`, `multiplicador_de_dano`, `congelar_dano`/`DanoCongelado`, `gatilhos`, `avancar`; `FormulasDeModificadores.dano_recebido`). O ADR de Aliados e Invocações **não** é dependência (ver Enables): o Combate define `MaldicaoRef` e a interface injetada `ModuloDeMaldicoes.exaurir(curse_id)` (declarada neste ADR), e o módulo de Maldições a implementa e chama `aplicar_golpe_maldicao` no item 6.1 (a aresta aponta dele para este; emenda Pactos) |
| **Enables** | ADR-0014 (Telégrafos usa `GeometriaDeAcerto`, `ferir_jogador` e `ferir_maldicao`); ADR-0015 (chama `resolver_subjugado`); ADR-0017 (golpe da Maldição pelo `_ferir_inimigo`); stories de Combate, Armas, Selo, Status e IA |
| **Blocks** | Stories de Combate núcleo até o aceite |
| **Ordering Note** | Os testes podem rodar com dublês do portador (ADR-0009) e da IA. A integração exige os ADRs 0008 e 0009 aceitos |

## Context

O GDD do Combate é o mais denso do MVP. Ele fixa uma ordem de passo em 10 itens, mas deixa para a arquitetura três coisas: como os cinco itens do Combate se organizam por dentro, como os efeitos que nascem depois de quem reage (projétil no item 8 depois do Selo no item 6; status no impacto) chegam a tempo, e onde mora a geometria de acerto que Telégrafos também precisa (P3: o desenho e o teste têm a mesma forma). Os ADRs 0001 e 0002 revisados já decidiram o essencial: o Combate guarda o hitstop, o crédito tardio do Selo e o `aplicar_status` são chamadas diretas, e `pedir_estado(MORTE)` no item 9 é aplicado no final comum do passo. A revisão também deixou aberto o achado 8, sobre o Corte pesado e o hitstop. O usuário decidiu esse ponto em 2026-11-15 na AC-26 do Movimento: o Corte com empurrão ≥ `empurrao_pesado` é impacto pesado, mas não pede hitstop. Falta uma regra estrutural que impeça a confusão. A fatia em `src/game_session.gd` mistura essas regras com o restante da sessão.

## Decision

### 1. Forma do módulo

`Combate extends RefCounted` é uma fachada com estado próprio e colaboradores injetados (R16): portadores dos jogadores e dos inimigos (ADR-0009), lista de inimigos da IA (só leitura, ordem estável), consultas e pedidos do Movimento por jogador, geometria da câmara, consulta "em combate" das Câmaras, `selo`, `status`, a lista `EventosDoPasso` do passo, o pedido de estado do orquestrador, o `CombatTuning` e os `AttackDef` já convertidos para passos e px na carga. O estado fica em registros (ADR-0003): `RecursosDoJogador` (um por `player_id`, dentro de `Array[RecursosDoJogador]`), `EstadoCombateInimigo` (Vida float, `vel_empurrao: Vector2`, cambaleio; id do inimigo), `ProjetilRegistro` e o contador `_hitstop: int`. Não há `Node`, `Timer`, `Area2D`, singleton nem `Engine.time_scale`. O Combate não tem valor padrão escondido: sem `CombatTuning` válido, não se cria (Edge Cases, Dados).

### 2. Ordem interna dos itens

| Item | Entrada | Ordem interna |
|---|---|---|
| 3 | `inicio_do_passo()` | Para cada jogador, em ordem de `player_id`: primeiro `portador.avancar(1)` do jogador (durações genéricas, ADR-0009 §6); depois desconta 1 em cada contador > 0, na ordem da R2: invulnerabilidade, recarga do Ataque, recarga do Especial, guarda, `apos_esquiva`, recuperação, janelas de combo (a janela que zera leva o passo do combo do slot a 0) |
| 5 | `golpe_do_jogador()` | Por jogador: (a0) lê "investida ativa" **antes** do disparo e guarda o valor em `RecursosDoJogador.investida_ativa_no_item_5` (TR-selo-004; ver "Emenda Pactos e pendências"); (a) se há investida ativa, testa os alvos na posição atual (F6), pede hitstop pesado no 1º alvo e leve nos seguintes, desconta o contador; (b) testa o disparo (R3: em esquiva ou investida bloqueia; Especial antes do Ataque; um por passo); (c) no disparo, faz os passos 1–8 da R3 nessa ordem; (d) a forma testa os alvos em ordem estável e chama `_ferir_inimigo` para cada um; (e) emite `golpe`/`area`/`disparo`/`investida`; (f) pede um único hitstop por golpe (R4); (g) por último, o passo de apoio `deslocar` do arco; (h) entrega ao Selo o valor guardado em (a0), uma vez por jogador, antes do item 6. A forma `chamado` (R3.1) não gera hitbox aqui: pede o salto às Maldições (`pedir_chamado`, corre no item 6.1) |
| 7 | `impacto_do_inimigo(id)` | Chamado pelo orquestrador depois de `telegrafos.avancar(id)` (ADR-0014) e antes da IA daquele inimigo. Com Vida ≤ 0, retorna sem fazer nada (R14). Senão: R11 (mede `v`, move `vel/60`, corrige com `resolver_colisao_informando` do ADR-0008 usando o raio do inimigo, testa a parede, aplica a queda e o zero) e desconta 1 do cambaleio (R12) |
| 8 | `projeteis()` | Percorre os projéteis na ordem de criação (id crescente). Para cada um: move `s`, desconta a vida, sai se a vida chegou a 0 (sem testar acerto), sai do retângulo ou toca obstáculo com `r_obs + raio × fator`; só então testa o acerto (R7). Os removidos saem por compactação que preserva a ordem |
| 9 | `varredura_de_mortes()` | Até `passes_varredura` passes. Cada passe tira um retrato dos ids com Vida ≤ 0 e, para cada um: remove da lista da IA (pedido `remover_morto(id)`, interface definida pelo Combate), contagem +1, `inimigo_morreu`, hitstop de abate, cura (não se o jogador já está morto), explosão; a queda do chefe zera os outros, e os lacaios `invocado_pelo_chefe` zerados assim saem **sem** contagem +1 e **sem** `ao_abater` (`cura_ao_abater`, `explosao_ao_abater`); os demais seguem a regra normal (§11). Os mortos do último passe ficam para o passo seguinte. Por fim, se algum jogador terminou o passo morto sem recusa, chama `pedir_estado(MORTE)` |

Os inimigos que morrem antes do seu turno no item 7 pulam o impacto. A IA, ao contrário, roda para todo inimigo **vivo** (`ia.vivo(id)`: Vida > 0 e não `SUBJUGADO`), não só para o atingível: um inimigo em `SURGINDO` não é atingível, mas o contador de surgimento precisa descer (ADR-0018 §2). Ciclo do item 7 (orquestrador): `telegrafos.varrer()` → `ia.inicio_do_item_7()` (avança os Chefes e cria os lacaios) → por inimigo, `portador.avancar(1)` → `status.tick` → `telegrafos.avancar` → `impacto_do_inimigo` → `ia.passo(id)` se `vivo(id)` → `ia.fim_do_item_7()` (separação par a par) → item 8.

Chamadas do Combate à IA neste item (interface `ModuloDeIA`, ADR-0018): `notificar_dano_no_chefe(id)` sempre que o chefe perde Vida (itens 5, 6.1, 7 e 8; aciona a `TransicaoFase`) e `invulneravel_por_fase(id) -> bool`, consultada por `_ferir_inimigo` antes de aplicar dano (dano × 0 na `TransicaoFase`; os ticks de status continuam contando, B2).

**Ordem completa do item 7 (alinhada com ADR-0009 §6 e ADR-0014 Decisão 3; revisão cruzada 2026-11-15):** `telegrafos.varrer()` uma vez; `ia.inicio_do_item_7()`; depois, para cada inimigo vivo na ordem estável da IA: (1) `portador_do_inimigo.avancar(1)` (IA, durações genéricas); (2) `status.tick(id)`; (3) `telegrafos.avancar(id)`; (4) `combate.impacto_do_inimigo(id)`; (5) `ia.passo(id)` se `vivo(id)`; ao fim, `ia.fim_do_item_7()`. Nenhum desses passos roda em passo congelado. **Dono do contrato do passo (2)** (pendência 3 da revisão de 2026-11-15): o Combate (este ADR) define a assinatura `status.tick(inimigo_id: int) -> void`, na interface `ModuloDeStatus` que ele injeta e que o módulo Status implementa; o orquestrador a chama ali, e o Status não é chamado em nenhum outro ponto do item 7. Mesma regra para a limpeza na troca de câmara (ver "Emenda Pactos e pendências", §B).

### 3. Dano: float no inimigo, inteiro no jogador

A Vida dos inimigos e todo o dano a eles são `float` escalar do GDScript (64 bits), sem arredondar e sem limitar ao que resta (R8.3, F1). A Vida, o escudo e o dano ao jogador são `int`. O dano ao jogador é calculado uma única vez, por `FormulasDeModificadores.dano_recebido(dano_base × M, portador.valor(&"reducao_dano"), teto, guarda)` do ADR-0009 (F3: `max(1, arredondar_meio_longe_do_zero(bruto × (1 − min(teto, max(0, reducao))) × guarda))`), sem reescrever a fórmula e sem `roundi`/`round()` (o ADR-0009 §2 proíbe presumir a semântica do `round()` da engine). Posições usam `Vector2` (32 bits no build padrão; ADR-0008). Comparações de borda usam distância ao quadrado: `≤` no alcance e `<` no anel de encostado, sem epsilon. O arredondamento do meio exato é verificado num teste antes do aceite.

### 4. Invulnerabilidade e recusa

A invulnerabilidade é um contador por jogador em `RecursosDoJogador`. Só o Combate o escreve, e todo pedido usa o máximo: `garantir_invulneravel(n)`, a invulnerabilidade de atingido (`max(atual, passos(invuln_atingido_s))`) e a de recusa. `ferir_jogador(player_id, ...)` segue a R13 na ordem do GDD: invulnerável ou fora de combate → nada; dano; escudo; Vida; invulnerabilidade mesmo com absorção total; hitstop de atingido e `jogador_atingido`; reflexo antes do teste de morte; recusa (Vida `max(1, FormulasDeModificadores.arredondar_meio_longe_do_zero(...))`, invulnerabilidade, −1 recusa, hitstop `hitstop_recusa_s`, `recusou_morte`) ou morte (Vida 0, `jogador_morreu`, marca `morto_neste_passo`). O pedido de MORTE não sai no meio do passo. Ele sai no fim do item 9, para que explosões, hitstop e eventos do restante do passo ainda rodem (R14), e o orquestrador o aplica no final comum, onde a Morte vence qualquer outra troca.

### 5. Hitstop

- `pedir_hitstop(n)` faz `_hitstop = max(_hitstop, n)`. Só o próprio Combate chama, e é privado na interface pública. Num passo vivo o contador começa em 0 e o maior pedido do passo vence (F9).
- O pedido não interrompe nada: o passo termina, inclusive os itens 7–10. `hitstop_ativo()` só passa a valer para o item 2 do passo seguinte.
- `passo_congelado_do_combate()` é chamado pelo orquestrador no item 2 e desconta 1. Fora de Jogo, nada desconta.
- `camara_nova()` (quadro da metade do wipe, ação 1 da R1) zera o hitstop, a investida e a recuperação de todos os jogadores e chama `status.limpar_todos()` (TR-status-008). Recargas, combo, janelas, guarda e invulnerabilidade passam para a câmara nova como estão.
- **Regra estrutural do achado 8:** `_ferir_inimigo` **nunca** pede hitstop. Ele calcula `pesado` (R8.4) só para o evento `acerto`, para o "Quebrou!" e para o `peso_visual`. Quem pede hitstop é a origem, pela tabela R10: a forma do golpe (uma vez por golpe), a investida por alvo, a parede (leve), `ferir_jogador`, a recusa e a varredura. `aplicar_corte`, o reflexo, a explosão, o Selo e o Status não têm entrada na tabela e por isso não pedem nada. Assim, o Corte com empurrão 900 sai com `pesado = true` e sem hitstop, como dizem a AC-26 revisada, a R18 e o Movimento R8. Se o Corte matar, o hitstop de abate vem da varredura.

### 6. Empurrão

`vel_empurrao` é um `Vector2` por inimigo, e cada impacto soma `direção × empurrão × valor(fator_empurrao)` (F7), com as direções opostas se cancelando. O movimento só acontece no item 7. Por isso, um acerto do item 5 já move o alvo no mesmo passo, e os acertos dos itens 8 e 9 movem a partir do passo seguinte. **Chefe (TR-chefes-011):** o fator vem da fonte `chefe` do portador (`fator_empurrao_chefe` = 0,12, ADR-0009), então o empurrão que o chefe recebe é × 0,12 pela mesma F7, sem caso especial no Combate. Armadura total: `_ferir_inimigo` nunca dá cambaleio nem "Quebrou!" ao chefe e não chama `telegrafos.quebrar` (R8.7); Sangramento, Queimadura e Abalo funcionam; a imunidade a imobilização é da IA (ADR-0018, "imobilizar só em comuns"). O alvo que morre não anda. O `vel_empurrao` do `inimigo_morreu` é o total do momento da morte. A parede usa `resolver_colisao_informando(pos, raio, geometria) -> ResolucaoDeColisao` (`.pos`, `.corrigida: bool`), variante do `resolver_colisao` do ADR-0008 (nota de ajuste de interface lá). Só retângulo e obstáculos contam como parede, e a separação entre inimigos é da IA. Cambaleio e "Quebrou!" seguem a R8.7, com o pedido `pedir_recuperacao(id, passos)` à IA e, no mesmo ponto, `telegrafos.quebrar(id)` (ADR-0014; injetado no Combate só para isso; elite e chefe não chamam).

### 7. Projéteis

`ProjetilRegistro` guarda: id (ADR-0003), dono (`player_id` ou inimigo), posição, direção, `s`, raio, vida em passos, `atravessa`, `dano_golpe`, `dano_congelado: DanoCongelado` (ADR-0009 §4; o 4º acerto é aplicado no impacto por `m_no_impacto(contador)`; projétil de inimigo guarda o `m_disparo` escalar), empurrão do item 6 da R3, status, finalizador e o conjunto de ids já atingidos. Jogador e inimigos ficam numa só `Array[ProjetilRegistro]`, ordenada por criação. O projétil anda no próprio passo em que nasce. O projétil de inimigo que encontra o jogador invulnerável atravessa e continua. Fora de combate, ele voa sem causar dano. O GDD não define teto de projéteis. Este ADR não cria teto de jogo; só emite um aviso de depuração acima de um limite de diagnóstico, que não muda o resultado (ver pendência 1). Os projéteis do jogador não pedem hitstop.

### 8. Efeitos tardios e síncronos

- **Status no impacto:** o item 8 da R8 chama `status.aplicar_status(alvo_id, id, n)` de forma síncrona, inclusive no Corte. O efeito aplicado nos itens 5/6 fere no mesmo passo (o Status roda no item 7). O aplicado no item 8 já existe no alvo, mas só fere a partir do passo seguinte.
- **Fluxo do projétil:** cada `acerto_de_arma` produzido no item 8 também chama `selo.creditar_acerto_tardio(player_id)` exatamente uma vez por alvo. Assim, o Fluxo de 38,9 sai do passo em 41,96 e só pode ser gasto no passo seguinte (AC-SF-26). O Selo não relê a lista para esses eventos.
- O evento `acerto_de_arma` continua na lista como notificação para Telemetria, HUD e Feedback. O Selo o lê só para os acertos do item 5.

### 9. `GeometriaDeAcerto`

Módulo único, sem estado, com funções `static` (classe `RefCounted` que nunca é instanciada). Arco, setor e círculo usam o mesmo critério em todo o projeto: o alvo é um círculo e conta o toque inclusivo da borda.

```gdscript
class_name GeometriaDeAcerto extends RefCounted
static func circulo_toca(centro: Vector2, raio: float, alvo: Vector2, r_alvo: float) -> bool       # |d|² ≤ (raio+r_alvo)²
static func setor_toca(origem: Vector2, dir: Vector2, cos_meio: float, alcance: float,
		alvo: Vector2, r_alvo: float) -> bool                                                    # d ≤ alcance+r ∧ dir·u ≥ cos_meio; d=0 → u=dir
static func arco_do_golpe(origem: Vector2, mira: Vector2, cos_meio: float, alcance: float,
		raio_encostado: float, alvo: Vector2, r_alvo: float) -> bool                             # F4: setor ∨ d < r_alvo+raio_encostado (estrito)
static func retangulo_orientado_toca(centro: Vector2, dir: Vector2, meio_comp: float, meio_larg: float,
		alvo: Vector2, r_alvo: float) -> bool                                                    # ponto mais próximo no retângulo local; ≤
static func girar_graus(v: Vector2, graus: float) -> Vector2                                       # leque F5; positivo = horário (y para baixo)
static func circulos_encostam(a: Vector2, b: Vector2, r_soma: float) -> bool                         # |d|² < r_soma² (estrito); avanço do telégrafo (F4, AC-TG-12)
static func alcance_do_raio(origem: Vector2, dir: Vector2, l_max: float, retangulo: Rect2,
		obstaculos: PackedVector3Array) -> float                                                  # distância até a borda do retângulo ou a superfície do 1º obstáculo (x, y, r), limitada a l_max
```

Pedidos do ADR-0014, incluídos na revisão cruzada de 2026-11-15: o ponto contra setor e contra retângulo é `setor_toca`/`retangulo_orientado_toca` com `r_alvo = 0` (inclusivo; `d = 0` conta como dentro); o retângulo de `x_min..x_max` ao longo da mira vira `centro = origem + dir × (x_min + x_max)/2`, `meio_comp = (x_max − x_min)/2`, no adaptador `FormaDeTelegrafo` do 0014. `alcance_do_raio` fica aqui (e não no ADR-0008) porque responde a uma pergunta de alcance, não de resolução de posição; o projétil (item 8) usa o mesmo critério de superfície. O `cos_meio` é calculado na carga do `AttackDef` ou lido pronto da definição de telégrafo (produto escalar 0,2 do catálogo, nunca recalculado de graus), e não a cada passo. O ADR-0014 usa estas funções sem criar outra geometria. Se precisar de outra forma, ela entra aqui. A colisão de corpos (`resolver_colisao`) continua no ADR-0008: uma resolve posição, a outra responde "acertou?".

### 10. Eventos emitidos

Subclasses de `EventoDoPasso` (ADR-0002), só com dados e ids: `EvGolpe` (V2), `EvArea` (V3), `EvDisparo` (V4), `EvInvestida` (V5), `EvAcerto` (V6, V7, com `peso_visual` e `flash_passos` resolvidos aqui, R17), `EvParede` (V8), `EvQuebrou` (V9), `EvJogadorAtingido` (V10, com `inversao_passos` e `invuln_passos`), `EvRecusouMorte` (V11), `EvInimigoMorreu` (V12, com `impact_passos` e `autor_player_id`: o `player_id` de quem causou o dano que levou a Vida a ≤ 0, 0 no solo; a atribuição de dano de Status e explosão no co-op é decisão pendente do ADR-0009), `EvExplosao` (V13), `EvAcertoDeArma` e `EvJogadorMorreu` (com causa). Todo evento de jogador leva `player_id`. Os impulsos de câmera (V14) e o orçamento em multidão (V15) são decididos pelo Feedback a partir desses eventos. O Combate não emite impulso. O V1 (relógios) é consumido pela Apresentação a partir de `hitstop_ativo()` e de `t_vivo`.

### 11. Pactos: facção, Maldições, acuada e chefe subjugado (emenda 2026-11-16)

Fontes: Combate R1, R3.1, R14, R20–R25; Chefes R3, R9, R9b; decisões 5, 7, 10 e 11. O estado de jogo e as regras de jogo não mudam; esta seção só diz como o Combate as cumpre.

- **Facção e sem fogo amigo.** `enum Faccao { JOGADOR, ALIADO, INIMIGO, ACUADA }`, guardada em cada registro de combatente (`RecursosDoJogador`: JOGADOR; `MaldicaoRef` do ADR-0017: ALIADO; `EstadoCombateInimigo`: INIMIGO; acuada do Vínculo: ACUADA). Golpe de JOGADOR e de ALIADO só testa a lista de atingíveis da R9 (inimigos); golpe de INIMIGO só testa o seu alvo (R22). A acuada não está na lista de inimigos nem na de atingíveis: nenhuma forma, projétil, Corte, parede, explosão, reflexo, Selo, Status ou golpe da Maldição a testa (R25.7). O teste é um filtro de facção na lista passada à `GeometriaDeAcerto`, não geometria nova.
- **Golpe da Maldição (R20).** `aplicar_golpe_maldicao(...)` é chamado pelo `ModuloDeMaldicoes` do ADR-0017 **no item 6.1**, de forma síncrona. A geometria é das Maldições, sobre `GeometriaDeAcerto`. Para cada alvo o Combate chama `_ferir_inimigo` com dano `dano_golpe × M_maldicao`, `de_arma = false` e `autor_player_id` do dono. Assim: não sobe o contador de acertos, não há `acerto_de_arma` (sem Fluxo, sem `golpe_*`, sem 4º acerto), e a regra estrutural do achado 8 vale: **não pede hitstop**. O empurrão acontece no item 7 do mesmo passo (R23). `M_maldicao` é calculado no impacto pelo portador da Maldição (ADR-0009).
- **Pouso do Chamado (R3.1, decisão 7).** O item 5 recusa o disparo sem Maldição em campo ou com ela `Saltando` (consulta às Maldições), sem gastar a recarga, e emite `chamado_indisponivel` uma vez por toque. No disparo, congela o `M_chamado` do jogador **no grupo Especial** (`DanoCongelado`, ADR-0009 §4; sem 4º acerto) e o entrega em `pedir_chamado(player_id, ponto, dano_golpe, M_chamado)`. O pouso (item 6.1) aplica a R20 com esse M, **sem empurrão** e sem recuperação do jogador (o item 7 do jogador não existe para essa forma).
- **`ferir_maldicao` (R21).** `ferir_maldicao(maldicao_id, dano_base, m_atacante, atacante_id, ataque_id)`: nada se `maldicao_atingivel` é falsa ou o jogador dono está fora de combate; dano inteiro por `FormulasDeModificadores.dano_recebido` **sem guarda e sem escudo** (F12); Vida da `MaldicaoRef` −= dano; sem invulnerabilidade pós-dano, sem hitstop, sem reflexo e sem recusa. Eventos `EvMaldicaoFerida` e, com Vida ≤ 0, `EvMaldicaoExausta`, e **no mesmo ponto** chama `modulo_de_maldicoes.exaurir(maldicao_id)` (troca automática no mesmo passo, decisão 5). A Exaustão não é morte do jogador. Os golpes seguintes do mesmo passo contra a Maldição exausta caem no primeiro teste e não fazem nada.
- **`ferir_acuada` (R25).** `ferir_acuada(dano_base, m_atacante, atacante_id, ataque_id)`: nada se `acuada_atingivel()` do Vínculo é falsa ou a câmara está fora de combate; dano inteiro da F13; Vida da acuada −= dano, piso 0; sem invulnerabilidade, sem hitstop, sem `acerto` e sem número de dano; evento `EvAcuadaFerida`. Com Vida ≤ 0 chama `vinculo.falhar_encontro()` **síncrono, no mesmo ponto**, e emite `EvEncontroFalhou`: a falha chega ao Vínculo antes da varredura do item 9, e golpes e projéteis seguintes do mesmo passo caem no primeiro teste. A acuada não tem item próprio: o dano nela entra pelos itens 7 (telégrafo, via IA) e 8 (projétil). Não é morte de inimigo nem do jogador.
- **`alvo_id` no projétil inimigo (R22).** `disparar_projetil` ganha `alvo_faccao: Faccao` e `alvo_id: int` (jogador, Maldição ou acuada), lidos no disparo. O `ProjetilRegistro` do inimigo guarda os dois e o item 8 testa **só esse alvo** (no lugar de "testa os jogadores em ordem de id"): jogador, a regra antiga; Maldição, `distância ≤ raio + raio_maldicao` e `maldicao_atingivel` → `ferir_maldicao(..., -1, ...)`, com atravessar-e-continuar se ela está `Saltando`; acuada, `ferir_acuada`. Se o alvo saiu de campo, o projétil voa até sumir sem ferir ninguém e não troca de alvo.
- **Chefe subjugado (R24, decisões 10 e 11).** O Combate lê a marca `subjugavel` no estado do inimigo, nunca a Doutrina. No passo `s` em que a Vida do chefe chega a ≤ 0, a varredura (item 9): pede `hitstop_abate_chefe_s` (36), zera os outros inimigos (lacaios `invocado_pelo_chefe` sem abate e sem `cura_ao_abater`/`explosao_ao_abater`), remove os projéteis inimigos e emite `EvChefeVencido(id, subjugado)`. **Sem a marca**, o resto da R14 como antes. **Com a marca**, o chefe fica na lista: o Combate chama `subjugar(inimigo_id)` (pedido à IA, interface `ModuloDeIA` definida pelo Combate, como `remover_morto`): Vida 0, não atingível, sem impacto, sem IA; sem contagem, sem `inimigo_morreu`, sem `cura_ao_abater`, sem `explosao_ao_abater`. A varredura marca o registro como `subjugado` para não repetir o hitstop nos passes seguintes. **`resolver_subjugado(inimigo_id, escolha)`**, pedido dos Chefes/ADR-0015: Exorcizar sai da lista como abate (contagem +1, `inimigo_morreu` com `impact_passos` 0, `cura_ao_abater` do autor; sem hitstop e sem explosão); Pactuar sai sem contagem, sem cura, sem evento de morte. Em Pactos, o abate e a `cura_ao_abater` do chefe só existem no Exorcizar. Na fase subjugada a consulta "em combate" das Câmaras é falsa, e `ferir_jogador` e `ferir_maldicao` não fazem nada.
- **Lacaios do chefe (Chefes R8, R14).** Na queda do chefe (com ou sem a marca), os inimigos com `invocado_pelo_chefe = true` têm a Vida zerada e saem na varredura **sem abate +1 e sem `ao_abater`**; se o jogador ou a Maldição os matar durante a luta, contam e ativam `ao_abater` normalmente. O resto dos inimigos segue a R14 comum.
- **`TransicaoFase` (Chefes R7, F4).** Durante a transição o chefe é invulnerável: todo dano a ele é multiplicado por 0 (a Vida não muda, o evento `acerto` sai normalmente), e os ticks de status continuam a contar (a duração desce, o dano é 0). É um estado do `EstadoCombateInimigo` (`invulneravel_a_dano`) escrito pela IA/Chefes (ADR-0018) e só lido pelo `_ferir_inimigo`.
- **Deslocamento forçado sem dano (Chefes R5.4, F3, R7).** O puxão da *Convergência* (75 px) e o pulso da `TransicaoFase` (120 px) não são golpes e não passam por `ferir_*`: são pedidos de posição que movem o jogador e a Maldição em campo, com colisão pelo `resolver_colisao` do ADR-0008, e são **ignorados** para quem está invulnerável (esquiva, investida, invulnerabilidade) ou `Saltando`. O dono é o módulo do chefe (ADR-0018); o Combate só informa invulnerabilidade e "em campo".
- **Marca, inércia e hitstop do chefe.** A marca `subjugavel` é gravada no spawn (Chefes R9b.1) e não muda. O chefe vencido fica inerte na lista com Vida 0, o hitstop de chefe são 36 passos (`hitstop_abate_chefe_s`), e se o jogador morre no mesmo passo em que o chefe cai, **a morte vence** a vitória e a subjugação: o `pedir_estado(MORTE)` do fim do item 9 prevalece no final comum (ADR-0001), e o chefe subjugado não gera escolha. A máquina de estados do chefe é do ADR-0018.

### Key Interfaces

```gdscript
class_name Combate extends RefCounted
func inicio_do_passo() -> void                                   # item 3
func golpe_do_jogador(comandos: Array[ComandosDoPasso]) -> void  # item 5, índice = player_id
func impacto_do_inimigo(inimigo_id: int) -> void                 # item 7
func projeteis() -> void                                         # item 8
func varredura_de_mortes() -> void                               # item 9
func passo_congelado_do_combate() -> void                        # item 2: hitstop −1
func hitstop_ativo() -> bool
func camara_nova() -> void
func atingivel(inimigo_id: int) -> bool
# Contrato do Movimento (ADR-0008), por jogador
func cancelar(player_id: int) -> void
func garantir_invulneravel(player_id: int, n: int) -> void
func esquiva_iniciada(player_id: int) -> void
func aplicar_corte(player_id: int, alvo_id: int, dano: float, dir: Vector2, empurrao: float, sangramento: float) -> void
# Contrato com IA e Telégrafos
func ferir_jogador(player_id: int, dano_base: float, m_atacante: float, atacante_id: int, ataque_id: StringName) -> void
func ferir_inimigo_de_status(alvo_id: int, dano: float) -> void  # Selo e Status: só R8 itens 1 e 3
func disparar_projetil(dono_inimigo_id: int, pos: Vector2, dir: Vector2, vel_pxs: float, raio: float,
		vida_s: float, dano_base: float, m_disparo: float, atravessa: bool) -> void
```

```gdscript
# Emenda Pactos (2026-11-16). Faccao e os contratos de Maldição, acuada e chefe.
enum Faccao { JOGADOR, ALIADO, INIMIGO, ACUADA }
func aplicar_golpe_maldicao(player_id: int, maldicao_id: int, alvos: Array[int], dano_golpe: float,
		m_maldicao: float, dir: Vector2, empurrao: float, status: Array, pesado: bool, ataque_id: StringName) -> void  # item 6.1; R20
func ferir_maldicao(maldicao_id: int, dano_base: float, m_atacante: float, atacante_id: int, ataque_id: StringName) -> void
func ferir_acuada(dano_base: float, m_atacante: float, atacante_id: int, ataque_id: StringName) -> void
func disparar_projetil(dono_inimigo_id: int, pos: Vector2, dir: Vector2, vel_pxs: float, raio: float,
		vida_s: float, dano_base: float, m_disparo: float, atravessa: bool,
		alvo_faccao: Faccao, alvo_id: int) -> void                # substitui a assinatura acima
func resolver_subjugado(inimigo_id: int, escolha: StringName) -> void   # &"exorcizar" | &"pactuar"
# Colaboradores injetados, interfaces DEFINIDAS aqui:
#   ModuloDeStatus:  tick(inimigo_id: int) -> void ; limpar_todos() -> void ; aplicar_status(alvo_id, id, n) -> void
#   ModuloDeIA:      remover_morto(id: int) -> void ; pedir_recuperacao(id: int, passos: int) -> void ; subjugar(inimigo_id: int) -> void ;
#                   notificar_dano_no_chefe(id: int) -> void ; invulneravel_por_fase(id: int) -> bool   (ADR-0018)
# Chamadas para fora (definidas por outros ADRs): ModuloDeMaldicoes.exaurir(maldicao_id) (0017); Vinculo.falhar_encontro() (dono: Vínculo; composto pelo ADR-0015).
```

`atacante_id = -1` indica projétil (sem reflexo). Os tipos dos ids seguem o ADR-0003.

### Implementation Guidelines

- MUST respeitar a ordem da tabela da seção 2 e o `≤`/`<` da F4.
- MUST pedir hitstop só nas origens da tabela R10, nunca em `_ferir_inimigo`.
- MUST manter a Vida do inimigo em float e a do jogador em int, com um único arredondamento.
- MUST chamar `selo.creditar_acerto_tardio` uma vez por `acerto_de_arma` do item 8, e `status.aplicar_status` de forma síncrona no impacto.
- MUST emitir `pedir_estado(MORTE)` só no fim do item 9.
- MUST usar `GeometriaDeAcerto` para todo teste de acerto, inclusive o dos Telégrafos.
- MUST NEVER usar `Area2D`, consulta de física, `Timer`, `Engine.time_scale` ou sinal do Godot na regra.
- MUST NEVER remover projétil ou inimigo por troca com o último, porque isso quebra a ordem estável.
- MUST NEVER guardar Vida, invulnerabilidade ou recursos de "o jogador" em campo singular.

## Alternatives Considered

| Alternativa | Por que não |
|---|---|
| `Area2D`/`ShapeCast2D` para acertos | A física 2D do 4.7 não está coberta pela referência (Combate OQ1), as bordas `≤`/`<` não são controláveis, e o resultado só sai no passo seguinte |
| Impacto pedindo o hitstop quando `pesado` | Reabre o achado 8: o Corte e a explosão pesados congelariam, contra R10, R18 e AC-26 |
| Selo relendo a lista no fim do passo | Credita tarde ou duas vezes, e quebra a regra de leitura só de itens anteriores (ADR-0002) |
| Morte trocando o estado no item 9 | Cortaria explosões e eventos do mesmo passo (R14) |
| Dano ao jogador em float | O GDD exige inteiro (F3 do Modificadores, F10) |
| Geometria separada para Telégrafos | Risco direto ao P3 (desenho igual ao teste) |

## Consequences

**Positivas:** a ordem, as bordas e os efeitos tardios ficam testáveis em memória com dublês. O achado 8 vira uma regra que se confere no código ("o impacto não pede hitstop"). P3 tem uma única fonte de geometria. O estado por jogador abre caminho para o co-op sem custo hoje.

**Negativas:** o Combate tem muitas dependências injetadas, e a fachada fica grande; mitiga-se com colaboradores internos (golpe, impacto, projéteis, varredura) que não aparecem na interface. Há duas chamadas diretas "para o lado" (Selo e Status), que são exceções explícitas ao "só se chama para baixo", já aceitas no ADR-0002.

## Risks

- **Arredondamento** no x,5: mitigado por usar só `arredondar_meio_longe_do_zero` do ADR-0009 e por um teste dos exemplos F10.
- **Semântica do Status:** a aplicação síncrona de `golpe_*` no impacto do item 8 precisa bater com Status R2–R4 e AC-ST-08. Conferir na revisão.
- **Custo** com 9 inimigos, 6 projéteis e golpes de 9 alvos (AC-81, p99 ≤ 0,3 ms): eventos alocados por passo podem pesar; medir antes de otimizar.
- **AC-92:** a medição usa `RenderingServer.frame_post_draw` como fim de quadro (verificado em 2026-11-16: dispara 1× por quadro); a medida não inclui o periférico nem o scan-out do monitor. Método em Validation Criteria (TR-combate-nucleo-018).

## GDD Requirements Addressed

| GDD | Requisito | Como |
|---|---|---|
| Combate | R1, R2, R3, R6 (investida), AC-05/09/12–22 | Ordem interna dos itens 3 e 5 |
| Combate | R4, R5, F4, F5, AC-23–28 | `GeometriaDeAcerto`, leque |
| Combate | R7, F5, AC-27–32, AC-93 | Projéteis, ordem e remoção |
| Combate | R8, R9, F1, F3, AC-37–44, AC-89–90 | `_ferir_inimigo`, float, `pesado` |
| Combate | R10, F9, AC-06–11, AC-95–96 | Hitstop no Combate, pedido por origem, `camara_nova` |
| Combate | R11, R12, F7, F8, AC-45–47 | Empurrão no item 7, parede via ADR-0008 |
| Combate | R13, F10, AC-48–53, AC-87–88 | Recursos por jogador, recusa, MORTE no fim do item 9 |
| Combate | R14, AC-54–57 | Varredura com retrato por passe |
| Combate | R17, V1–V15, AC-91, AC-97 | Eventos tipados com durações prontas |
| Combate | R18, AC-84–86 | Contrato do Movimento |
| Combate | AC-81 / AC-92 | Medição de custo / `frame_post_draw` verificado (2026-11-16) |
| Movimento | R8, AC-26 (rev. 2026-11-15) | Corte pesado sem hitstop (seção 5) |
| Selo | F1, AC-SF-26 | `creditar_acerto_tardio` |
| Status | R2–R4, AC-ST-08 | `aplicar_status` síncrono |
| Telégrafos | forma = teste (P3) | Geometria única, reusada pelo ADR-0014 |
| Selo | R2.2, AC-SF-10 (TR-selo-004) | Item 5 (a0)/(h): lê "investida ativa" antes do disparo, guarda e entrega ao Selo |
| Efeitos de status | R7, AC-ST-16 (TR-status-008) | `ModuloDeStatus.limpar_todos()` em `camara_nova()`; `tick` com dono (Decisão do item 7) |
| Chefes | Armadura total, empurrão × 0,12, Abalo (TR-chefes-011) | §6: fator pela fonte `chefe` (ADR-0009); sem cambaleio nem `quebrar`; imobilização imune no ADR-0018 |
| Combate | AC-92 latência do golpe ≤ 2 passos + 1 quadro (TR-combate-nucleo-018) | Validation Criteria: método de medição |
| Combate | R1 (item 6.1), R23, AC-81 (TR-combate-nucleo-017) | Item 6.1 é do ADR-0017; orçamento 0,3 ms só dos itens 3, 5, 7, 8 e 9 |
| Combate | R3.1, R20, decisão 7 (TR-combate-nucleo-020, TR-maldicoes-012) | §11: pouso do Chamado com `M_chamado` do Especial, sem empurrão; golpe da Maldição sem hitstop |
| Combate | R21, R23, decisão 5 (TR-combate-nucleo-021, TR-combate-nucleo-019) | §11: `ferir_maldicao`, Exaustão síncrona |
| Combate | R22, R25, V44 (TR-combate-nucleo-021, TR-combate-nucleo-022, TR-vinculo-007) | §11: `alvo_id` no projétil, `ferir_acuada`, `falhar_encontro` antes da varredura |
| Combate | R14, R24, decisão 11 (TR-combate-nucleo-023, TR-chefes-012, TR-chefes-013) | §11: `subjugar`, `resolver_subjugado`, abate e cura só no Exorcizar |
| Combate | R1, R9, R25.7 (TR-combate-nucleo-020, TR-maldicoes-001) | §11: facção e sem fogo amigo |
| Chefes | R3, decisão 10 (TR-chefes-004, TR-chefes-007) | §11: o projétil do chefe testa só o `alvo_id` travado |
| Chefes | R9, R9b, F6 (TR-chefes-012, TR-chefes-013, TR-combate-nucleo-024, TR-economia-008) | `chefe_vencido`, marca `subjugavel`, `resolver_subjugado`; 0 Fragmentos de chefe no Pactuar fica com a Run (ADR-0015) |

## Performance Implications

Os testes de acerto custam O(alvos) por golpe, sem raiz quadrada (só `cos_meio` vem da carga), e os projéteis custam O(p × inimigos). Com os números da AC-81, são algumas centenas de comparações por passo. Não há alocação no caminho quente, além dos eventos (ADR-0002) e da criação de projéteis. As listas são reutilizadas entre passos. Orçamento: AC-81, **p99 ≤ 0,3 ms/passo na soma dos itens 3, 5, 7, 8 e 9** (TR-combate-nucleo-017). Método de medição: cenário fixo de 9 inimigos, 6 projéteis e golpe em 9 alvos; 1000 passos vivos com semente fixa, descartando os 60 primeiros (aquecimento); tempo por passo com `Time.get_ticks_usec()` em volta das cinco entradas somadas; p99 do conjunto; **build exportado**, não o editor, no hardware de referência; resultado em `production/qa/evidence/` com o teste em `tests/performance/combat/`. O item 6.1 (Maldições) tem orçamento próprio no ADR-0017 e **não** entra nos 0,3 ms; a soma do passo é decisão do ADR de orçamento total (achado 4 da revisão). A emenda Pactos acrescenta ao item 8 só o teste de um alvo por projétil de inimigo, o que reduz o custo de O(p × inimigos-jogadores) para O(p).

## Migration Plan

A fatia (`src/game_session.gd`) continua jogável enquanto o módulo nasce ao lado. Sequência: (1) `GeometriaDeAcerto` com os testes da F4 e da F5; (2) `Combate` com dublês do portador, da IA, do Selo e do Status, cobrindo as AC-L da seção GDD Requirements; (3) trocar as chamadas de combate da `game_session.gd` pela fachada, uma entrada por item, com o orquestrador do ADR-0001; (4) apagar a lógica duplicada da fatia. A Apresentação (`world_view.gd`, `game_hud.gd`) passa a ler só eventos e consultas.

## Validation Criteria

**Medição da latência do golpe (TR-combate-nucleo-018, AC-92).** Teste de performance em `tests/performance/combat/`, build de desenvolvimento, 60 Hz, vsync ligado. Início: `Time.get_ticks_usec()` gravado quando o evento de entrada do Ataque chega ao `ModuloDeCombate` (item 5 do passo). Fim: o sinal `RenderingServer.frame_post_draw` (fim do desenho do quadro), conectado só pelo harness, lido no primeiro quadro em que a `VistaDeGolpe` do *smear* daquele golpe é desenhada; o harness grava a diferença. 100 toques, recarga 0, fora de esquiva e investida; o maior ≤ 50,0 ms. Evidência em `production/qa/evidence/combate-latencia-[data].md` com CPU, RAM, SO, build e os 100 valores. `frame_post_draw` foi verificado no 4.7.2 em 2026-11-16 (ver "Verificação de engine (2026-11-16)"); o nome `VistaDeGolpe` é do projeto e se confirma na story (Combate OQ 10). O limite de 50 ms é proposta do GDD.

- Testes unitários em `tests/unit/combate/` para as AC [L] listadas, com destaque para: AC-89 (hitstop do golpe × `pesado` do impacto); AC-85 e a variante da AC-26 com empurrão 900 (pesado, "Quebrou!" possível, passo seguinte vivo); AC-SF-26 (41,96); AC-44 (morto não age); AC-95/96.
- Dois Combates com o mesmo roteiro de 1000 passos produzem eventos idênticos.
- AC-81 registrado em `production/qa/evidence/`.
- AC-92 verificado em `EX-0010-1` (`RenderingServer.frame_post_draw`, 1 vez por quadro, pior caso medido `33,33 ms ≤ 50 ms` do evento na fila do Godot até o fim do envio do quadro pela CPU); repetir na cena real de produção da story.

## Nota de preparação para co-op

Todos os recursos do jogador vivem em `Array[RecursosDoJogador]` indexado por `player_id` (0 no solo), e todos os pedidos e eventos de jogador levam `player_id`. Os itens 3 e 5 iteram os jogadores em ordem de id. O projétil inimigo testa os jogadores em ordem de id e acerta o primeiro. O hitstop continua **global** (um contador), e a morte de qualquer jogador pede MORTE. Os dois pontos são decisões de design pós-MVP, já listadas em architecture.md, e nada de rede entra agora.

## Decisões do usuário (resolvidas em 2026-11-15)

**O usuário aceitou todas as recomendações abaixo em 2026-11-15.** Elas valem como decisão deste ADR; o texto de cada item fica como registro das opções.

1. **Teto de projéteis.** O GDD não define teto. Opções: (a) sem teto de jogo, só aviso de depuração; (b) teto de dados em `CombatTuning`, que descarta o mais antigo. **Recomendação: (a)** no MVP, porque (b) muda o jogo e o GDD.
2. **Ordem entre projéteis do jogador e de inimigos.** O GDD não diz. A ordem muda o resultado em casos raros, como dois projéteis no mesmo alvo e o quarto acerto. **Recomendação:** lista única por ordem de criação, como o cânone parece fazer. Confirmar no `engine.ts`.
3. **Co-op:** hitstop global e morte individual. **Recomendação:** adiar; a estrutura suporta as duas opções.

O achado 8 **não** fica pendente: a AC-26 revisada (2026-11-15) já é a decisão do usuário, e este ADR só a implementa.

## Emenda Pactos e pendências (2026-11-16)

Resume o que mudou no corpo. Nenhuma regra de jogo mudou; o aceite do ADR continua pendente.

**A. Pendências da revisão de 2026-11-15** (`architecture-review-2026-11-15.md`, linhas 94–180):
- **TR-selo-004:** o item 5 lê "investida ativa" **antes** do disparo (a0), guarda em `RecursosDoJogador` e entrega ao Selo no fim do item 5 (h), antes do item 6. A assinatura de entrega do lado do Selo (por exemplo `selo.receber_investida(player_id, ativa)`) fica para o ADR/story do Selo; o contrato do lado do Combate é este.
- **Verification Required (1):** troca do teste de `round()`/`roundi()` pelo teste de `arredondar_meio_longe_do_zero` (ADR-0009), alinhado à Decisão 3, que já proibia `round()`.
- **Status:** o Combate (este ADR) é dono da assinatura `status.tick(inimigo_id: int) -> void` (item 7, passo 2) e da interface `ModuloDeStatus`. O Status implementa e só é chamado ali.
- **Limpeza de status na troca de câmara (TR-status-008):** `camara_nova()` (ação 1 da R1, quadro da metade do wipe) chama também `status.limpar_todos()`, junto com o zerar de hitstop, investida e recuperação. Nada de status passa para a câmara nova; as recargas e a invulnerabilidade seguem como estão.
- **Orçamento:** p99 ≤ 0,3 ms nos itens 3, 5, 7, 8 e 9 e o método de medição estão em Performance Implications. ADR-0009 já estava em Depends On.

**B. Pactos** (§11 da Decisão): facção e sem fogo amigo; golpes das Maldições no item 6.1 pela R20 (ADR-0017); `ferir_maldicao` com Exaustão síncrona; `ferir_acuada` com falha avisada ao Vínculo antes da varredura; `alvo_id` no projétil inimigo; `subjugar` e `resolver_subjugado`; abate e `cura_ao_abater` do chefe só no Exorcizar; pouso do Chamado com o M do Especial e sem empurrão. ADR-0017 entra em Depends On e Enables. Linhas novas na tabela GDD Requirements (TR-combate-nucleo-019 a 024, TR-maldicoes-012, TR-vinculo-007, TR-chefes-004, 007, 012 e 013, TR-economia-008: ids oficiais do `tr-registry.yaml`).

**B2. Acréscimos do orquestrador (rastreabilidade de `chefes.md`):** lacaios `invocado_pelo_chefe` sem abate e sem `ao_abater` (corrige o texto do item 9); `TransicaoFase` com dano × 0 e ticks de status contando; deslocamento forçado sem dano em jogador e Maldição (ADR-0008, ignorado por invulnerável e `Saltando`); marca `subjugavel` no spawn, chefe inerte, hitstop 36 e morte do jogador vence. Máquina de estados do chefe: ADR-0018 (só referenciado aqui).

**C. Ordem do passo.** O item 6.1 (Maldições; ordem interna: ADR-0017 §Ordem do item 6.1, GDD maldicoes R23) é do ADR-0017 e roda entre o Selo e os inimigos; o Combate só recebe dele `aplicar_golpe_maldicao`. A troca automática da Exaustão sai em `exaurir`, chamado pelo Combate nos itens 7/8 (`ferir_maldicao`). A tabela da seção 2 continua com os cinco itens do Combate.

**D. Pontos a confirmar** (nomes e assinaturas, não regra): a assinatura de `ferir_maldicao`/`ferir_acuada` leva `m_atacante`, `atacante_id` e `ataque_id` (como no GDD R21/R25) e não só `dano` e `origem`; `disparar_projetil` ganha `alvo_faccao` além de `alvo_id`; o evento `EvChefeVencido(id, subjugado)` já consta do catálogo do ADR-0002 (emissor: Combate, na varredura do item 9). Conforme chefes.md R9b, `chefe_subjugado` é emitido pelos Chefes em `s + 37`, não pelo `subjugar`; `EvChefeExorcizado` é do Combate (`resolver_subjugado`, Exorcizar).

## Verificação de engine (2026-11-16)

Fonte: Completion Notes em `production/epics/experimentos-de-engine/` e `production/qa/evidence/experimentos/ex-0010-latencia.md`. Editor 4.7.2 standard, Windows 11.

- **VERIFICADO:** `RenderingServer.frame_post_draw` dispara exatamente 1× por quadro e serve de fim de quadro para a AC-92 (NEEDS VERIFICATION retirado).
- **VERIFICADO:** latência toque→golpe desenhado ≤ 22,1 ms sem vsync e 33,3 ms com vsync a 60 Hz, abaixo do limite de 50,0 ms. A medida vai da chegada do evento ao `ModuloDeCombate` até o `frame_post_draw`; **exclui** a latência do periférico e o scan-out do monitor.
- **Pendência:** repetir no `.exe` exportado quando houver templates 4.7.2, e com o conteúdo real da story.

## Related

[architecture.md](architecture.md) · [architecture-review.md](architecture-review.md) (achados 3, 4 e 8) · [Combate núcleo](../../design/gdd/combate-nucleo.md) · [Movimento](../../design/gdd/movimento-e-esquiva.md) · [Selo e Fluxo](../../design/gdd/selo-e-fluxo.md) · [Efeitos de status](../../design/gdd/efeitos-de-status.md) · [Telégrafos](../../design/gdd/telegrafos.md) · [Chefes](../../design/gdd/chefes.md) · [Pactos: decisões](../../design/gdd/pactos-decisoes-a-confirmar.md) · [architecture-review-2026-11-15.md](architecture-review-2026-11-15.md) · ADR-0014 (reusa `GeometriaDeAcerto`) · ADR-0017 (Maldições, item 6.1)
