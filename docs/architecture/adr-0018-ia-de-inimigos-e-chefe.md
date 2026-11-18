# ADR-0018: IA de inimigos e do chefe

## Status

Accepted · 2026-11-16 (aprovado pelo usuário; Proposed em data do ADR)

> **Quem pode mudar para `Accepted`:** o usuário, ou `technical-director` com a
> confirmação explícita do usuário. Nenhum outro agente, e nenhuma skill sozinha.

## Date

2026-11-16

## Last Verified

2026-11-16 (contra `ia-de-inimigos-e-elites.md` R1–R22 com a emenda Pactos, `chefes.md` R1–R12/F3/F4, `vinculo-e-pactos.md` V8/V44, `camaras-e-ondas.md` R7-P e ADRs 0001, 0003, 0008, 0010, 0014, 0017 no estado de 2026-11-16)

## Decision Makers

Usuário (aprovação pendente); `ai-programmer` (rascunho, fase de fechamento da arquitetura com Pactos)

## Summary

Os requisitos da IA de inimigos (TR-ia-001..014) estavam espalhados entre os ADRs 0001, 0003, 0007, 0008 e 0014, e a máquina de estados do chefe não tinha dono. Este ADR cria o `ModuloDeIA`, um `RefCounted` puro que roda no item 7. Ele traz uma máquina de fases genérica em passos vivos, com comportamentos sem estado (melee, ranged, charger, chefe), seleção de alvo determinística (Maldição atraída > acuada por paridade > jogador) travada no início do Preparo, separação par a par no fim do item 7, consulta injetada do retângulo da câmera e invocação de lacaios com teto. O chefe é uma especialização sem RNG (TransicaoFase, HitstopFinal, Subjugado, ciclo de 4 `BossPatternDef`).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7, pin 4.7.2 (instalado, sem gap) |
| **Domain** | Core (Scripting) |
| **Layer** | Core |
| **Knowledge Risk** | LOW. Só `RefCounted`, `Array[T]` tipado, `Vector2`, `Rect2`, `Resource` imutável e `@abstract` |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md` (linha do `@abstract`) |
| **Post-Cutoff APIs Used** | `@abstract` (GDScript 4.5) na classe base `Comportamento`. Regra do 4.7: todo `override` com retorno não-void exige `return` explícito |
| **Verification Required** | (1) `@abstract` em classe e método de `Comportamento` gera erro de parse em subclasse incompleta no 4.7.2. (2) Medir o orçamento de CPU (abaixo) no PC de referência com 9 inimigos e com 36 inimigos (estresse). (3) Confirmar que `passo()` não aloca (contagem de objetos antes e depois de 600 passos) |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | [ADR-0001](adr-0001-orquestrador-do-passo.md) (item 7, passo vivo e congelado, estados de jogo); [ADR-0003](adr-0003-entidades-e-portadores.md) (`InimigoRef`, id inteiro crescente, posse dos campos pela IA); [ADR-0004](adr-0004-catalogo-de-dados.md) (`IATuning`, `EnemyDef`, `EliteRules`, `ChefesTuning`, `BossPatternDef`, validação IV/CH); [ADR-0005](adr-0005-rng-deterministico.md) (fluxos `ia` e `elites`); [ADR-0007](adr-0007-cena-viewport-e-camera.md) (retângulo visível da câmera); [ADR-0008](adr-0008-movimento-e-colisao-propria.md) (`resolver_colisao`, `deslocar`); [ADR-0010](adr-0010-resolucao-do-combate-no-passo.md) (`ferir_*`, `disparar_projetil(..., alvo_faccao, alvo_id)`, `impacto_do_inimigo`, `atingivel`, interface `ModuloDeIA` definida pelo Combate: `remover_morto`, `pedir_recuperacao`, `subjugar`); [ADR-0014](adr-0014-telegrafos-geometria-e-teto.md) (`iniciar_telegrafo` com alvo travado, `alvo_de`, `disparou_neste_passo`, `cancelar`); [ADR-0017](adr-0017-aliados-e-invocacoes.md) (só o contrato de leitura da Maldição: `maldicao_em_campo`, `posicao_e_raio`, `maldicao_atingivel`, `fator_andar_atraido`) |
| **Enables** | ADR-0015 (sequência da câmara do chefe e desfecho), ADR-0011/0012 (vistas de fase e barra de chefe), ADR-0016 (sons por fase); ADR-0017 consome `atrair`, `imobilizar`, `puxar`, `atingiveis`, `mais_perto`, `conter` |
| **Dependência mútua com ADR-0017** | 0017 e 0018 dependem um do outro **só por interfaces** (`ConsultaDaMaldicao` de um lado, pedidos `atrair`/`imobilizar`/`puxar`/`saiu_de_campo` do outro), ligadas no `Main`. Não há ciclo de implementação: cada módulo é construído e testado com dublê da porta do outro. **Os dois ADRs são aceitos juntos.** |
| **Blocks** | Epic de IA de inimigos (stories de fases, ranged, charger, elites); epic do chefe do Limiar; stories de Maldições que pedem `atrair`/`imobilizar`/`puxar` |
| **Ordering Note** | **Aresta dupla com o 0017.** O 0018 lê a Maldição pelo contrato do 0017, e o 0017 chama `atrair`/`imobilizar`/`puxar`/`atingiveis` deste ADR. Para não haver ciclo de implementação, cada lado depende só de uma **interface** (porta) declarada pelo outro, e o `Main` liga as duas na composição (ADR-0015). As duas podem ser aceitas juntas |

## Context

### Problem Statement

Não havia ADR de IA. A máquina de fases (TR-ia-003), a separação no fim do item 7 (TR-ia-006) e a regra do `ranged` visível (TR-ia-009) ficaram parciais, e a máquina de estados do chefe (TR-chefes-002) era um gap. Com a Doutrina de Pactos, cada inimigo passa a ter um **alvo** (jogador, Maldição atraída ou acuada), e os pedidos `atrair`, `imobilizar` e `puxar` chegam do item 6.1. Os ADRs 0010, 0014 e 0017 já assumem uma `ModuloDeIA` com nomes que ninguém definiu por inteiro.

### Current State

O ADR-0003 dá a posse (lista, fases, timers, posição do inimigo são da IA). O ADR-0010 define a ordem do item 7 e os pedidos à IA. O ADR-0014 trava mira e alvo. O ADR-0017 §11 registra a estrutura do alvo no encontro "porque não há ADR de IA". A fatia jogável (`c3b1dfd`) tem IA ad hoc em cena, que este ADR substitui.

### Constraints

- Simulação pura, sem `SceneTree`, testável em memória (TR-ia-013).
- Timers só em passos vivos; nada roda em hitstop, Pausa, Bênção ou Transição.
- Determinismo: ordem estável por id, desempate pelo menor id, chefe sem RNG.
- Todo número vem do catálogo validado (TR-ia-014); nenhum literal de jogo no código.
- No máximo 9 inimigos simultâneos, chefe e lacaios incluídos (Câmaras; TR-camaras-014).

### Requirements

- IA ≤ 0,15 ms p99 por passo vivo com 9 inimigos (ver Performance).
- Zero alocação em `passo()` e `fim_do_item_7()`.
- Contratos estáveis para Combate, Telégrafos, Maldições, Vínculo, Câmaras e Chefes.

## Decision

### 1. Módulo e posse

`ModuloDeIA extends RefCounted` é montado pelo `Main` e implementa a interface `ModuloDeIA` que o ADR-0010 definiu (`remover_morto`, `pedir_recuperacao`, `subjugar`), mais as consultas e os pedidos abaixo. Ele é o dono da lista de `InimigoRef` (ordem de id), do contador de ids, de `fase`, `timer`, estado de alvo (`alvo_padrao`, `restante_atracao`, `restante_respiro`, `respiro_guardado`, `restante_imob`), `ordem`, `invocado_pelo_chefe` e da posição normal do inimigo. Vida, impacto e cambaleio continuam no Combate. O id sai do mesmo contador da run usado pela `MaldicaoRef` (ADR-0003, emenda).

### 2. Chamadas no item 7

A ordem do contrato não muda: `telegrafos.varrer()`; por inimigo, `portador.avancar(1)` → `status.tick` → `telegrafos.avancar` → `combate.impacto_do_inimigo` → **`ia.passo(id)`**. Este ADR acrescenta duas chamadas do orquestrador, uma antes e outra depois do laço:

- `ia.inicio_do_item_7()`, logo depois de `varrer()`: avança o `ModuloDeChefes` (emissão em `s + 37`, §8) e cria os lacaios pedidos.
- `ia.fim_do_item_7()`, depois do último inimigo e antes do item 8: separação par a par (§6).

**Mudança pedida ao ADR-0010 §2 e ao ADR-0001:** a condição do passo (5) passa de "se `atingivel(id)`" para "se `vivo(id)`" (Vida > 0 e não `SUBJUGADO`). Um inimigo em `SURGINDO` não é atingível, mas o seu contador de surgimento precisa descer. `passo()` trata `SURGINDO` só como contagem: sem movimento, sem alvo, sem status.

### 3. Máquina de fases genérica

```text
enum Fase { SURGINDO, APROXIMACAO, PREPARO, EXECUCAO, RECUPERACAO,
            TRANSICAO_FASE, HITSTOP_FINAL, SUBJUGADO }        # as 3 últimas só no chefe
```

`passo(id)` faz sempre, nesta ordem:
1. Vida ≤ 0 ou `SUBJUGADO`: retorna ("morto não age").
2. `SURGINDO`: `timer −= 1`; se chegar a 0, `comportamento.ao_surgir(i)` define `APROXIMACAO` e a espera inicial (comuns: `20 + ia.inteiro(50)`; chefe: fixa, §8).
3. Lê o alvo do passo, `alvo_efetivo(id)` (§4), e **depois** desce `restante_atracao`, `restante_respiro` e `restante_imob` (R16, R17, R18). O fim da atração abre o respiro no mesmo passo.
4. `comportamento.decidir(i, alvo, ctx)` move e muda de fase pelas R4–R7 (chefe: Chefes R4–R7).
5. Conter: `resolver_colisao(pos, raio, geometria)` do ADR-0008, menos no avanço que já colidiu dentro do próprio deslocamento.

Os comportamentos são classes **sem estado** (todo estado fica no `InimigoRef`), com uma instância por tipo: `@abstract class_name Comportamento` e as subclasses `ComportamentoMelee`, `ComportamentoRanged`, `ComportamentoCharger` e `ComportamentoChefe`. A escolha vem de `EnemyDef.comportamento`. Preparo: a IA chama `telegrafos.iniciar_telegrafo(id, ataque, alvo.id, alvo.faccao)`. Se ele recusar (teto), a IA continua em `APROXIMACAO` e tenta de novo no passo seguinte. O timer do preparo é do telégrafo, e a IA lê `disparou_neste_passo(id)` (ADR-0014: a IA nunca mantém contador paralelo). Execução no mesmo passo do disparo (R5/R6). Recuperação: `timer = recarga`, depois espera `10 + ia.inteiro(30)`. "Quebrou!" chega por `pedir_recuperacao(id, passos)` e só vale para comuns (elite e chefe têm armadura; o Combate não chama).

Velocidade de andar = `velocidade × lentidão do Selo × cambaleio × (atraído ? fator_andar_atraido(player_id) : 1)` (R9, R16). O avanço do `charger` e o do chefe ignoram os três fatores. Imobilizado (R18) não anda e não começa preparo. O `timer` continua descendo, e preparo e execução em curso continuam.

### 4. Seleção de alvo

`AlvoDeInimigo` (valor pré-alocado por inimigo, nunca criado no passo): `faccao: Combate.Faccao`, `id: int`, `player_id: int`, `pos: Vector2`, `raio: float`. Alinhado ao ADR-0017 §11:

- `alvo_padrao` é fixado **no nascimento**: `ACUADA` se a câmara tem acuada em `Acuada` e `ordem ≥ 0` e `ordem` par; senão `JOGADOR`. Lacaios nascem com `ordem = −1`, e o chefe nunca tem acuada na câmara.
- `alvo_efetivo(id)`, função pura, a cada leitura, nesta prioridade:
  1. `restante_atracao > 0` e `maldicao_em_campo(player_id) == maldicao_id` guardado → **Maldição** (ALIADO);
  2. `alvo_padrao == ACUADA` e `acuada_atingivel()` (Vínculo) → **acuada** (ACUADA). Vale também no respiro;
  3. **jogador** (JOGADOR). No MVP, `player_id = 0`. Com mais de um jogador (pós-MVP): o de menor distância ao quadrado, empate pelo menor `player_id`.
- Como (2) relê o Vínculo a cada leitura, a falha ou a fuga da acuada vale no mesmo item 7 para quem ainda não agiu (V12.2), sem pedido extra.
- **Alvo travado:** o alvo do passo do `iniciar_telegrafo` vai para o telégrafo (ADR-0014 Decisão 9). Junto, a IA guarda `epoca_campo[player_id]`, um contador que ela incrementa a cada `maldicao_saiu_de_campo(player_id)`. Na execução, a IA lê `telegrafos.alvo_de(id)` e valida: ALIADO exige `maldicao_atingivel(id)` e a mesma época ("saiu depois da trava, mesmo que volte" = falha); ACUADA exige `acuada_atingivel()`. Alvo inválido = **falha no vazio**: nenhum `ferir_*`, e o ciclo segue. Alvo válido: só a chamada da facção (`ferir_jogador`, `ferir_maldicao`, `ferir_acuada`). O projétil sai com `disparar_projetil(..., alvo_faccao, alvo_id)`. O teste de forma é do ADR-0014, só contra o alvo travado.
- **`maldicao_saiu_de_campo(player_id)`** (pedido do 0017): zera `restante_atracao` de todo inimigo atraído por aquela Maldição, abre o respiro de cada um (`restante_respiro = respiro_guardado`) e incrementa a época, no mesmo passo.

### 5. Pedidos do item 6.1 (Maldições)

- `atrair(id, passos, passos_respiro) -> bool`: aceita se `atingivel(id)`, há Maldição em campo e `restante_atracao == 0` e `restante_respiro == 0`. Grava `restante_atracao = passos`, `respiro_guardado = passos_respiro` e o `maldicao_id`/`player_id` de quem atraiu. Sem renovação (R17). Vale para comuns, elites, chefe e lacaios. O chefe em `TRANSICAO_FASE` recusa.
- `imobilizar(id, passos) -> bool`: só comum atingível (inclusive lacaio). `restante_imob = max(restante_imob, passos)`. Elite e chefe devolvem falso.
- **`puxar(id, centro, distancia_px, parar_a_px) -> bool`** (técnica *Convergência*, ADR-0017 Risks): só comuns e elites atingíveis. O chefe devolve falso (decisão a revisar). Desloca `min(distancia_px, max(0, d − parar_a_px))` na direção do centro e depois aplica `resolver_colisao`. É síncrono no 6.1, então o item 7 do mesmo passo já parte da posição nova. Não é golpe e não muda fase nem alvo. A mesma conta (`FormulasDoChefe.passo_puxao`) serve ao puxão do chefe (F3).
- Consultas: `esta_atraido(id)`, `esta_imobilizado(id)`, `atingiveis() -> Array[VistaDeInimigo]` (só leitura, ordem de id, sem Maldição, sem acuada, sem `SURGINDO`, sem `SUBJUGADO`; R19/R20), `mais_perto(ponto, raio_max) -> int` (menor (dist², id), inclusivo; −1 se vazio), `conter(pos, raio) -> Vector2` (R20: a mesma função que contém os inimigos, para o corpo da Maldição).

### 6. Separação no fim do item 7

`fim_do_item_7()`: um passe sobre os pares `(i, j)` com `i < j` na ordem de id, entre os inimigos vivos fora de `SURGINDO` e `SUBJUGADO` (inclui elite, chefe e lacaios). Se `d < r_i + r_j`, cada um anda metade da sobreposição em sentidos opostos. Com centros iguais, a normal é `(0, −1)` para `i` e o oposto para `j` (mesma convenção do ADR-0008). Depois, um `conter` por inimigo deslocado, em ordem de id. Fica um passe só, sem iteração: uma correção posterior pode deixar sobreposição residual, como o ADR-0008 já aceita. Maldição e acuada ficam fora (R20, R22). O avanço do `charger` e o do chefe também separam: a separação não para o avanço.

### 7. Retângulo da câmera (R11)

A IA recebe por injeção uma porta `ConsultaDeVista` com um único método, `retangulo_visivel() -> Rect2`, em coordenadas de mundo. O `Main` a liga ao ADR-0007: o retângulo é o do **último estado base** da câmera (posição de seguir, sem impulsos nem tremor) × largura lógica W × 1080, publicado uma vez por quadro e lido como valor pela simulação. O `ranged` só entra em preparo se o seu centro está em `retangulo_visivel().grow(margem_visivel_px)`. Fora dele, avança na direção do alvo, sem recuar nem contornar. Nos testes, a porta é um `Rect2` fixo. A visibilidade é sempre a do próprio inimigo, nunca a do alvo.

### 8. Chefe como especialização

`ComportamentoChefe` usa a mesma máquina e acrescenta `EstadoDoChefe` no `InimigoRef` (`padrao: int`, `em_furia: bool`, `transicao_pendente: bool`, `avancar_padrao_ao_sair: bool`, `pulso_pendente: bool`):

- **Sem RNG:** espera inicial `passos(espera_inicial_chefe_s)` (30), entre padrões `passos(espera_entre_padroes_chefe_s)` (15). A R3 e a R7 da IA não valem.
- **Ciclo:** `padroes[padrao]` é um `BossPatternDef` (forma, preparo, execução, recarga, dano, `raio_secundario_px`). Engajamento: P0 por `dist ≤ alcance_engajamento_p0_px`; P1–P3 preparam com `timer ≤ 0` em qualquer distância. `padrao = (padrao + 1) mod 4` ao entrar em `RECUPERACAO`. Recarga × `fator_recarga_furia` e velocidade × `mult_velocidade_furia` com `em_furia`.
- **Execução dos padrões** em funções puras por forma (setor, avanço com contato 1×, pulso + 12 projéteis a 30° da mira travada, puxão → impacto → invocação). Cada golpe só fere o alvo travado, inclusive os 12 projéteis.
- **TransicaoFase:** **pedido ao Combate** (ADR-0010): logo depois de aplicar dano a um inimigo `chefe`, o Combate chama `ia.notificar_dano_no_chefe(id)`. Se `¬em_furia` e `0 < Vida ≤ round(vida_max × limiar_furia_frac)`: fora de `EXECUCAO`, entra em `TRANSICAO_FASE` na hora (`telegrafos.cancelar(id)`, `timer = passos(transicao_fase_s)`, `pulso_pendente`); em `EXECUCAO`, marca `transicao_pendente` e entra no passo seguinte ao fim da execução. Assim, `invulneravel_por_fase(id) -> bool`, lido pelo Combate (dano × 0, empurrão 0), vale desde o golpe que cruzou o limiar, mesmo nos itens 5, 6.1 e 8. O pulso (repelir jogador e Maldição em `raio_pulso_furia_px`, exceto os imunes), o fim da atração com respiro e os 30 passos rodam no `passo()` do chefe. Se a transição entrou no item 8, a contagem começa no item 7 seguinte. O `padrao` avança na saída só se a transição interrompeu `PREPARO` ou veio depois de `EXECUCAO`.
- **Deslocamentos do chefe** (puxão, pulso) passam pela porta `DeslocamentosDoChefe`: `imune(faccao, id) -> bool` (esquiva, salto) e `deslocar(faccao, id, v: Vector2)`. O `Main` a liga a `Movimento.deslocar` (ADR-0008) e a um pedido equivalente do `ModuloDeMaldicoes`. A conta é da IA (F3, F4).
- **HitstopFinal e Subjugado:** no passo `s`, a varredura do Combate trata a Vida ≤ 0 (ADR-0010 §11). Sem `subjugavel`, `remover_morto`. Com `subjugavel`, `subjugar(inimigo_id)`: Vida já 0, fase `SUBJUGADO`, sem decisão, sem movimento próprio, sem colisão ofensiva, fora da separação e de `atingiveis()`, mas **na lista**. `HITSTOP_FINAL` não tem passo próprio: são os 36 passos congelados. O `ModuloDeChefes` recebe `EvChefeVencido(id, subjugado)` e, no `inicio_do_item_7()` do primeiro passo vivo depois (`s + 37`), emite `EvChefeSubjugado` (Pactos) ou credita 6 (fora de Pactos). R9b (`resolver_subjugado` → `creditar` → `limpar_camara_chefe`) também é do `ModuloDeChefes`, que este ADR declara como **dono do desfecho**, separado da máquina de luta.
- **Lacaios:** no disparo do P3, `n = min(lacaios_por_convergencia, max(0, max_lacaios_vivos − lacaios_vivos), max(0, max_inimigos_onda − vivos_na_lista))`, em posições `ajustar_obstaculos_e_parede(pos_chefe ± dist_spawn_lacaio_px)`, `k = 0` à esquerda. São criados por `criar_inimigo` no fim do `passo()` do chefe e anexados ao fim da lista. Começam em `SURGINDO` e só agem no item 7 seguinte (o laço percorre um retrato do tamanho da lista). `elite = false`, `ordem = −1`, `invocado_pelo_chefe = true`, sem consumir `elites` nem `spawn`. Depois de nascer, rodam a IA `melee` normal (R3–R9) e **consomem o fluxo `ia`** como qualquer comum (`ao_surgir` e fim da recuperação), conforme IA R21 e AC-IA-46. Quem não sorteia nada é o próprio chefe (esperas fixas, Chefes R2/R6) e a montagem da câmara (Câmaras R14-P). Correção do orquestrador em 2026-11-16: a harmonização tinha tirado o `ia` dos lacaios, mas chefes.md R8 só exclui `elites` e `spawn`.

### 9. Elites, nascimento e RNG

- `RegrasDeElite.sortear_elite(profundidade, ja_ha_elite, fluxo_elites) -> bool` (static): consome **1 real sempre** (R10, TR-ia-004/008). Chamado pelas Câmaras e nunca na câmara do chefe.
- `criar_inimigo(def: EnemyDef, pos: Vector2, opcoes: OpcoesDeNascimento) -> int` (`ordem`, `elite`, `invocado_pelo_chefe`, `subjugavel`): só as Câmaras (ondas, chefe em `(960; 285)`) e o próprio módulo (lacaios) chamam. A distância mínima da acuada (> 240 px, R7-P) é das Câmaras, na escolha do candidato. A IA não valida posição de nascimento.
- O fluxo `ia` é consumido só em `ao_surgir` (comuns, inclusive lacaios do chefe; nunca o chefe) e no fim da recuperação (idem), nessa ordem dentro do passo do inimigo e em ordem de id.

### Architecture Diagram

```text
item 6.1  ModuloDeMaldicoes ──atrair/imobilizar/puxar/saiu_de_campo──▶ ModuloDeIA
item 7    Orquestrador: varrer → ia.inicio_do_item_7 ─▶ ModuloDeChefes (s+37, lacaios)
            por id: portador → status.tick → telegrafos.avancar → combate.impacto → ia.passo(id)
                                                                         │
                     alvo_efetivo ◀─ Vínculo.acuada_atingivel / Maldicoes.maldicao_em_campo
                     Comportamento{Melee,Ranged,Charger,Chefe}.decidir
                        ├─▶ Telegrafos.iniciar_telegrafo(id, ataque, alvo_id, faccao)
                        ├─▶ Combate.ferir_* / disparar_projetil(..., alvo_faccao, alvo_id)
                        ├─▶ ConsultaDeVista.retangulo_visivel (ranged)
                        └─▶ GeometriaDeMovimento.resolver_colisao (ADR-0008)
          → ia.fim_do_item_7 (separação par a par + conter)
itens 5/6.1/7/8  Combate ──notificar_dano_no_chefe──▶ ModuloDeIA (TransicaoFase)
item 9    Combate ──remover_morto / subjugar──▶ ModuloDeIA
```

### Key Interfaces

```gdscript
class_name ModuloDeIA extends RefCounted
## Implementa ia-de-inimigos-e-elites.md R1–R22 e a máquina de luta de chefes.md R1–R8.
func configurar(tuning: IATuning, regras_elite: EliteRules, chefes: ChefesTuning,
		combate: Combate, telegrafos: Telegrafos, geometria: GeometriaDaCamara,
		jogadores: ConsultaDeJogadores, maldicoes: ConsultaDaMaldicao, acuada: ConsultaDaAcuada,
		vista: ConsultaDeVista, deslocamentos: DeslocamentosDoChefe, fluxo_ia: FluxoRng,
		chefe: ModuloDeChefes, eventos: EventosDoPasso) -> void
# Ciclo (orquestrador, item 7)
func inicio_do_item_7() -> void
func passo(inimigo_id: int) -> void
func fim_do_item_7() -> void
func vivo(inimigo_id: int) -> bool
# Interface definida pelo Combate (ADR-0010)
func remover_morto(id: int) -> void
func pedir_recuperacao(id: int, passos: int) -> void
func subjugar(inimigo_id: int) -> void
func notificar_dano_no_chefe(id: int) -> void            # pedido novo ao ADR-0010
func invulneravel_por_fase(id: int) -> bool              # TransicaoFase
# Câmaras
func criar_inimigo(def: EnemyDef, pos: Vector2, opcoes: OpcoesDeNascimento) -> int
func camara_nova() -> void                               # esvazia a lista; ids não reiniciam
# Maldições (ADR-0017)
func atrair(id: int, passos: int, passos_respiro: int) -> bool
func imobilizar(id: int, passos: int) -> bool
func puxar(id: int, centro: Vector2, distancia_px: float, parar_a_px: float) -> bool
func maldicao_saiu_de_campo(player_id: int) -> void
func esta_atraido(id: int) -> bool
func esta_imobilizado(id: int) -> bool
func conter(pos: Vector2, raio: float) -> Vector2
# Consultas (Input, Movimento, Maldições, Telégrafos, Apresentação)
func atingiveis() -> Array[VistaDeInimigo]               # pré-alocado; só leitura
func mais_perto(ponto: Vector2, raio_max: float) -> int  # −1 se vazio
func alvo_efetivo(inimigo_id: int) -> AlvoDeInimigo
func publicar(saida: Array[VistaDeInimigo]) -> int       # fase, padrão, em_furia, elite, chefe

@abstract class_name Comportamento extends RefCounted
@abstract func ao_surgir(i: InimigoRef, ctx: ContextoDaIA) -> void
@abstract func decidir(i: InimigoRef, alvo: AlvoDeInimigo, ctx: ContextoDaIA) -> void

class_name RegrasDeElite extends RefCounted
static func sortear_elite(profundidade: int, ja_ha_elite: bool, fluxo_elites: FluxoRng) -> bool

class_name ModuloDeChefes extends RefCounted   # desfecho (Chefes R9, R9b), não a luta
func chefe_vencido(id: int, subjugado: bool) -> void     # chamada DIRETA do Combate (ADR-0002: o evento do item 9 não chega ao item 7 de s+1)
func passo_vivo() -> void                                # chamado por inicio_do_item_7
func escolha(id: int, escolha: StringName) -> void       # &"pactuar" | &"exorcizar"; repetida = ignorada
```

`ConsultaDaMaldicao` é a porta implementada pelo `ModuloDeMaldicoes` com os métodos que ele já declara (`maldicao_em_campo`, `posicao_e_raio`, `maldicao_atingivel`, `fator_andar_atraido`). `ConsultaDaAcuada` (Vínculo): `acuada_atingivel() -> bool`, `posicao_e_raio_acuada() -> Vector3`. `FluxoRng` é o tipo do fluxo do ADR-0005, e o nome do método de inteiro segue aquele ADR.

### Implementation Guidelines

- `ModuloDeIA` e os `Comportamento` **must** ser `RefCounted` puros e **must never** criar `Node`, `Timer`, `Area2D` nem consultar física da engine.
- Os comportamentos **must** ser sem estado. Todo estado por inimigo **must** viver no `InimigoRef`.
- `passo()` **must** ler o alvo antes de descer atração, respiro e imobilização, e **must** abrir o respiro no mesmo passo em que a atração acaba, por qualquer motivo.
- Todo golpe **must** testar só o alvo travado e chamar só o `ferir_*` da facção dele. Alvo travado ausente **must** falhar no vazio, nunca redirecionar.
- A IA **must never** contar o preparo por conta própria (ADR-0014). Disparo = `disparou_neste_passo`.
- O chefe **must never** consumir RNG. Lacaios **must never** consumir `elites` nem `spawn`; depois de nascer, usam `ia` como qualquer `melee`.
- Separação **must** ser um passe `i < j` em ordem de id, metade da sobreposição para cada, com normal `(0, −1)` nos centros iguais. **Must never** incluir Maldição, acuada, `SURGINDO` ou `SUBJUGADO`.
- `atingiveis()`, `publicar()` e `alvo_efetivo()` **must** preencher valores pré-alocados e **must never** expor `InimigoRef`.
- Nenhum número de jogo literal: todos vêm de `IATuning`, `EnemyDef`, `EliteRules`, `ChefesTuning` e `BossPatternDef` já convertidos para passos e px na carga.
- Todo `override` com retorno tipado **must** ter `return` explícito (4.7).

## Alternatives Considered

### Alternative 1: Behavior tree genérica com nós de dados

- **Description**: Árvore de comportamento por `EnemyDef`, com nós condição/ação em `Resource`.
- **Pros**: Flexível para inimigos futuros e com depurador visual.
- **Cons**: Os GDDs descrevem uma máquina de 5 fases fixa, portada do cânone. Uma árvore esconde a ordem exata (ler alvo → descer contadores → decidir) que os testes de paridade exigem, e custa alocação e indireção por passo.
- **Estimated Effort**: 2–3× o escolhido.
- **Rejection Reason**: Mais complexidade do que 4 comportamentos pedem. A máquina com estratégias sem estado é o suficiente e é auditável contra o cânone.

### Alternative 2: Chefe como módulo separado, fora da lista de inimigos

- **Description**: `ModuloDeChefe` com corpo e laço próprios.
- **Pros**: Isola a complexidade do chefe.
- **Cons**: Duplica colisão, separação, alvo, `atrair`, Status, telégrafo e varredura. O Combate R14/R24 e o ADR-0003 já tratam o chefe como `InimigoRef` com `chefe: bool`.
- **Estimated Effort**: Maior, com dois caminhos para manter.
- **Rejection Reason**: Contradiz o ADR-0003 e a R21 da IA ("a IA dá a máquina; Chefes acrescentam fases").

### Alternative 3: TransicaoFase checada só no passo da IA

- **Description**: O chefe olha a Vida só no próprio `passo()`, sem aviso do Combate.
- **Pros**: Não muda o ADR-0010.
- **Cons**: Dano nos itens 5 e 6.1 de um mesmo passo poderia levar o chefe de 351 a 0 sem a invulnerabilidade da transição. "No mesmo passo" (R7) não seria cumprido para dano do item 8.
- **Rejection Reason**: A regra de jogo exige a invulnerabilidade a partir do golpe que cruza o limiar.

## Consequences

### Positive

- Um só dono para os TR-ia, e a máquina do chefe deixa de ser gap.
- Alvo, trava e falha no vazio com uma única regra para Maldição e acuada.
- Testável em memória: todas as portas são injetadas, e câmera e RNG são substituíveis.

### Negative

- Duas chamadas novas do orquestrador no item 7 (`inicio_do_item_7`, `fim_do_item_7`), mudança na condição do passo (5) e o aviso `notificar_dano_no_chefe` no Combate. Os ADRs 0001 e 0010 precisam de emenda.
- A visibilidade do `ranged` depende da proporção da janela (W lógico), então a IA não é idêntica entre janelas diferentes. O fluxo `ia` já não tem garantia estrutural (ADR-0005).

### Neutral

- `ModuloDeChefes` fica com o desfecho, e a luta fica na IA. O GDD de Chefes trata os dois como "módulo de Chefes".

## Risks

- **Ciclo 0017 ↔ 0018.** Mitigação: portas declaradas nos dois ADRs, composição no `Main` e aceite conjunto.
- **Separação de um passe deixa sobreposição residual com 9 corpos.** Mitigação: aceita pelo cânone. Teste com 9 inimigos no mesmo ponto confirma que convergem em ≤ 10 passos.
- **Orçamento estoura com projéteis do P2 e lacaios.** Mitigação: os projéteis são do item 8 (Combate). O teto de 9 inimigos limita os pares a 36.
- **Snapshot da câmera atrasado 1 quadro.** Mitigação: `margem_visivel_px` (0 no MVP) é o botão de ajuste. Tiro nascido 1 px fora da tela não é visível ao jogador.

## Performance Implications

- **CPU:** `ModuloDeIA` (todos os `passo()` + `inicio_do_item_7` + `fim_do_item_7`) **≤ 0,15 ms p99 por passo vivo** com 9 inimigos (chefe + 3 lacaios incluídos) no PC de referência. Alarme de estresse: 36 inimigos ≤ 0,6 ms. Somado aos orçamentos provisórios do Combate (0,3 ms) e do Movimento (0,2 ms), cabe no orçamento total do passo vivo (≤ 1,0 ms p99, tabela do ADR-0001).
- **Memória:** `AlvoDeInimigo`, `VistaDeInimigo` e contexto pré-alocados. Zero alocação por passo.
- **Load:** nenhum; os comportamentos são instanciados uma vez por run.

## Migration Plan

Substitui a IA ad hoc da fatia jogável (`c3b1dfd`): primeiro os comuns (melee, ranged, charger) com os testes de paridade, depois a separação e o alvo de Pactos, por fim o chefe. A cena principal passa a chamar o módulo pelo orquestrador.

## Validation Criteria

- Teste: `SURGINDO` dura exatamente `passos(surgimento_s)` e não é atingível; com a condição "vivo", o contador desce.
- Teste: ler alvo → descer contadores. Uma atração de N aplicada no 6.1 vale por N passos vivos contando o atual; respiro de 30 no mesmo passo do fim; `atrair` recusado em atraído e em respiro (AC-ML-24).
- Teste: `maldicao_saiu_de_campo` zera a atração de todos no mesmo passo; um telégrafo travado na Maldição que saiu e voltou falha no vazio (época).
- Teste: inimigo de `ordem` par mira a acuada, é puxado à Maldição pelo Chamado, volta à acuada no fim; na fuga da acuada, quem age depois no mesmo item 7 lê o jogador (AC-VP-10, AC-IA-55).
- Teste: `ranged` fora do `Rect2` injetado nunca chama `iniciar_telegrafo` e avança.
- Teste: separação com centros iguais dá normais `(0, −1)`/`(0, 1)`; ordem por id.
- Teste: chefe com seed qualquer produz a mesma sequência de padrões e tempos (sem RNG); 351 → 340 no item 5 já fica invulnerável no item 6.1; transição no meio do avanço do P1 entra no passo seguinte ao fim; 351 → 0 de uma vez pula a transição.
- Teste: com 2 lacaios vivos, o P3 invoca 1; o teto de 9 limita a invocação; lacaios não consomem `elites` e nascem `SURGINDO`.
- Teste: `subjugar` mantém o chefe na lista, fora de `atingiveis()` e da separação; `EvChefeSubjugado` sai no primeiro passo vivo depois do hitstop de 36.
- Medição: orçamento de CPU acima, registrado em `production/qa/`.

## GDD Requirements Addressed

| TR | Requisito (resumo) | Fonte | Como este ADR cobre |
|---|---|---|---|
| TR-ia-001 | IA no item 7, ordem estável, nunca em hitstop | IA R2 | §2 (com ADR-0001) |
| TR-ia-002 | Lista com identidade estável; morto não age | IA R1 | §1, §3 passo 1 (com 0003, 0010) |
| TR-ia-003 | Máquina de fases com timers em passos vivos | IA R3–R7 | §3 (**completa o parcial**) |
| TR-ia-004 | Fluxos `ia` e `elites` | IA R10 | §9 |
| TR-ia-005 | Preparo acoplado a `iniciar_telegrafo` | IA R5 | §3 |
| TR-ia-006 | Contenção e separação par a par no fim do item 7 | IA R9 | §3 passo 5, §6 (**completa o parcial**) |
| TR-ia-007 | Elite, chefe e profundidade como fontes | IA R10 | Só cita: fontes são do ADR-0009; a IA passa as flags em `criar_inimigo` |
| TR-ia-008 | `sortear_elite` pelas Câmaras, 1 elite por onda | IA R10 | §9 |
| TR-ia-009 | `ranged` só prepara dentro do retângulo da câmera | IA R11 | §7 (**completa o parcial**) |
| TR-ia-010 | Quebra por `pedir_recuperacao`; armadura | IA R8 | §3 |
| TR-ia-011 | Consulta de alvos atingíveis em ordem estável | IA R19 | §5 `atingiveis`, `mais_perto` |
| TR-ia-012 | `no_selo` e cambaleio no andar, não no avanço | IA R9 | §3 |
| TR-ia-013 | Dependências injetadas; testes sem SceneTree | IA R15 | §1, Key Interfaces |
| TR-ia-014 | Tuning do catálogo validado | IA R14 | Guidelines |
| TR-ia-015 | Alvo por inimigo exposto por consulta; `atrair` sem renovação com respiro; `imobilizar` só em comuns | IA R16–R18, F6 | §4, §5 |
| TR-ia-016 | `atingiveis()` só leitura, ordem de spawn, sem Maldição nem acuada; `conter` exposto | IA R19, R20 | §5 |
| TR-ia-017 | Chefe com TransicaoFase/Subjugado; `subjugar(id)` para IA e colisão ofensiva; lacaios sem `elites`/`spawn` | IA R21 | §8 |
| TR-ia-018 | Alvo padrão acuada por paridade de `ordem`; "Mirando a acuada" suspenso enquanto atraído | IA R22; Vínculo V8, V44; Câmaras R7-P | §4 |
| TR-ia-019 *(novo, em `tr-novos/extras.yaml`)* | Pedido `puxar` para a técnica *Convergência* | ADR-0017 Risks; Maldições `TecnicaDef.puxar` | §5 |
| TR-camaras-014 | Câmara do chefe sem sorteio; lacaios entram pela IA a pedido do chefe; teto 9 inclui chefe e lacaios | Câmaras R14; Chefes AC-CH-01 | §8 lacaios, §9 |
| TR-chefes-002 | Máquina de estados do chefe (Surgindo → … → Morto/Subjugado) | Chefes States, R4, R6, R7, R9 | §8 |
| TR-chefes-003 | Ciclo dos 4 `BossPatternDef` sem RNG, engajamento por padrão | Chefes R2, R4, R5, R6, F1 | §8 |
| TR-chefes-009 | Invocação controlada de lacaios com teto e posições determinísticas | Chefes R5.4, R8, F3 | §8 |
| TR-chefes-010 | TransicaoFase: gatilho único, invulnerável, pulso, fúria | Chefes R7, F4, Edge Cases | §8 |

TR-ia-015 a 018 e TR-chefes-002, 003, 009 e 010 são ids oficiais do `tr-registry.yaml`; só TR-ia-019 é novo.

## Decisões tomadas pelo agente (a revisar)

1. Condição do passo (5) do item 7 trocada de `atingivel` para `vivo` (para o `SURGINDO` contar). Pede emenda no ADR-0010 §2 e no ADR-0001.
2. Duas chamadas novas no item 7: `inicio_do_item_7` (desfecho em `s + 37`, lacaios) e `fim_do_item_7` (separação).
3. `notificar_dano_no_chefe` + `invulneravel_por_fase`: aviso síncrono do Combate para a TransicaoFase valer no mesmo passo em qualquer item. Pede emenda no ADR-0010.
4. Retângulo visível = último estado base da câmera, sem impulsos, publicado por quadro. A IA aceita depender do W lógico da janela.
5. `puxar` aceita comuns e elites; **o chefe recusa**.
6. Separação de um passe só, seguida de `conter`, excluindo `SURGINDO` e `SUBJUGADO`; avanço não para na separação.
7. Lacaios consomem `ia` como `melee` normal e nunca `elites` nem `spawn` (IA R21, AC-IA-46, Chefes R8). Só o chefe é livre de RNG.
8. Lacaios agem a partir do item 7 seguinte (laço sobre um retrato da lista).
9. Teto de invocação também limitado por `max_inimigos_onda − vivos`.
10. `ModuloDeChefes` separado (desfecho R9/R9b), e a máquina de luta fica no `ModuloDeIA`.
11. Época de campo da Maldição guardada pela IA para "saiu depois da trava, mesmo que volte"; o ADR-0017 não muda.
12. Co-op pós-MVP: alvo jogador = o mais perto, empate pelo menor `player_id`.
13. Orçamento: IA ≤ 0,15 ms p99 com 9 inimigos; estresse 36 ≤ 0,6 ms.
14. Chefe em `TRANSICAO_FASE` recusa `atrair`.
15. Significados de TR-chefes-002/003/009/010 conferidos com o registro oficial.

## Related

`design/gdd/ia-de-inimigos-e-elites.md`, `design/gdd/chefes.md`, `design/gdd/vinculo-e-pactos.md` (V8, V44), `design/gdd/camaras-e-ondas.md` (R7-P, R14), [ADR-0017](adr-0017-aliados-e-invocacoes.md) §4 e §11.
