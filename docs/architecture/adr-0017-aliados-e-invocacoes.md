# ADR-0017: Aliados e invocações

## Status

Accepted · 2026-11-16 (aprovado pelo usuário; Proposed em data do ADR)

> Só o usuário, ou o `technical-director` com a confirmação explícita do usuário, move este ADR para `Accepted`.

## Date

2026-11-16

## Last Verified

2026-11-16. Fontes conferidas: Maldições R1–R24, F4b, Catálogo (emenda Pactos), Edge Cases e AC-ML-01–36; Combate núcleo R1 (item 6.1), R3.1, R20–R23; IA R16–R18 e R22 (pelas ACs AC-IA-31/35/49/55); Modificadores R14 e F6; Input R1a (`troca`); `pactos-decisoes-a-confirmar.md` (21 decisões aprovadas em 2026-11-16). As interfaces dos ADRs 0003, 0004 e 0009 foram lidas só na parte que este ADR usa. Não houve experimento executável.

## Decision Makers

Aba de Arquitetura (`technical-director`), por pedido do usuário para fechar a arquitetura da Doutrina de Pactos. O aceite fica com o usuário. Este ADR não muda regra de jogo. O que o agente decidiu sozinho está em "Decisões tomadas pelo agente (a revisar)".

## Summary

As Maldições viram um módulo puro, `ModuloDeMaldicoes` (`RefCounted`), que roda no item 6.1 do passo vivo e é dono de tudo o que é aliado: a entidade `MaldicaoRef` (id inteiro do ADR-0003, `player_id`, `Portador` do ADR-0009, facção `ALIADO`), a troca, a técnica combinada, o Chamado, a reserva com Exaustão e a IA de aliado. O golpe da Maldição não tem caminho próprio de dano: entra no impacto do Combate pela R20, sem fogo amigo. A técnica é dado (`TecnicaDef` dentro do `CurseDef`), executada por um intérprete genérico, de modo que 4 espécies dão 12 combinações sem código por par.

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Godot 4.7, pin 4.7.2 |
| **Domain** | Core / lógica de jogo |
| **Layer** | Core |
| **Knowledge Risk** | BAIXO. Aritmética e listas em memória |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md` (só para confirmar que nada usado mudou) |
| **Post-Cutoff APIs Used** | Nenhuma. O módulo usa só `RefCounted`, `Vector2`, `Array` tipado e `StringName`. Não declara `@abstract`; consome os contratos `@abstract` do ADR-0009 (`ConsultaDeAtributos`), que já estão cobertos lá. Os `CurseDef`/`TecnicaDef` são `Resource` do catálogo do ADR-0004 |
| **Verification Required** | (1) Dublês que sobrescrevem método com retorno tipado precisam de `return` explícito (regra 4.7); (2) custo do item 6.1 no build real (ver Performance) |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | [ADR-0001](adr-0001-orquestrador-do-passo.md) (item 6.1 no passo vivo; nada roda congelado ou fora de Jogo), [ADR-0002](adr-0002-canal-de-eventos.md) (lista `EventosDoPasso`; eventos novos no catálogo), [ADR-0003](adr-0003-entidades-e-portadores.md) (ids inteiros, registros, posse dos campos por sistema), [ADR-0004](adr-0004-catalogo-de-dados.md) (`MaldicoesTuning`, `CurseDef`, `TecnicaDef`, validação ML1–ML8 na carga), [ADR-0008](adr-0008-movimento-e-colisao-propria.md) (`resolver_colisao` contra retângulo e obstáculos), [ADR-0009](adr-0009-atributos-e-modificadores.md) (`Portador`, `aplicar_fonte`/`remover_fonte`/`avancar`, `multiplicador_de_dano`, F3), [ADR-0010](adr-0010-resolucao-do-combate-no-passo.md) (facção, `aplicar_golpe_maldicao` da R20, `ferir_maldicao`, `pedir_chamado`, `GeometriaDeAcerto`, `atingivel`), [ADR-0014](adr-0014-telegrafos-geometria-e-teto.md) (alvo travado; telégrafo mirado na Maldição) |
| **Enables** | ADR-0015 (composição da run monta o módulo e a dupla), ADR-0012 (HUD do Pacto lê `estado_pacto`), ADR-0016 (sons pelos eventos), stories de Maldições, Besta do Vínculo e Vínculo |
| **Blocks** | Stories de Maldições e da Besta do Vínculo até o aceite |
| **Dependência mútua com ADR-0018** | 0017 e 0018 dependem um do outro **só por interfaces** (este ADR implementa `ConsultaDaMaldicao` e chama `atrair`/`imobilizar`/`puxar`/`saiu_de_campo` do `ModuloDeIA`), ligadas no `Main`. Não há ciclo de implementação: cada módulo é construído e testado com dublê da porta do outro. **Os dois ADRs são aceitos juntos.** |
| **Ordering Note** | Os testes unitários rodam com dublês de Combate, IA, Status e portador. A integração exige os ADRs 0009 e 0010 aceitos, com as emendas Pactos do 0010 e do 0014 |

## Context

### Problem Statement

A Doutrina de Pactos acrescenta o primeiro combatente que não é jogador nem inimigo. O GDD de Maldições fixa as regras e o Combate R23 fixa o lugar no passo (6.1), mas faltam a forma do módulo, quem guarda a Vida e a posição da Maldição, como a técnica combinada vira dado, como o dano dela passa pelo Combate sem abrir um segundo caminho de impacto, e como as Bênçãos chegam ao portador dela. Sem isso, cada sistema vizinho (Combate, IA, Telégrafos, HUD, Vínculo) inventaria a sua parte.

### Current State

A fatia (`src/game_session.gd`) não tem aliados. Nenhum código de Maldição existe.

### Constraints

- Determinismo e ordem estável (ADR-0001/0003): sem RNG neste módulo, iteração por id crescente.
- Nada de `Node`, `Area2D`, `Timer`, sinal do Godot ou singleton na regra.
- Co-op preparado: tudo indexado por `player_id`, nada em campo singular.
- Paridade de TTK da Besta (Maldições F6, ±5%): o módulo não pode mudar números, só executá-los.

### Requirements

Maldições R1–R24, F1–F7 e AC-ML-01–36; Combate R20–R23; IA R16–R18; Modificadores R14/F6. A tabela "GDD Requirements Addressed" lista cada um.

## Decision

### 1. Forma do módulo

`ModuloDeMaldicoes extends RefCounted` é uma fachada com estado próprio e colaboradores injetados: o `MaldicoesTuning` e os `CurseDef` já convertidos para passos e px na carga, a consulta do Combate (atingíveis, `aplicar_golpe_maldicao`), a fachada da IA (`atrair`, `imobilizar`, `esta_atraido`, `esta_imobilizado`, `maldicao_saiu_de_campo`, lista e posição dos inimigos), a consulta do Status (Abalo, para a sinergia da F5), as posições dos jogadores (Movimento), a geometria da câmara e a lista `EventosDoPasso`. Sem `MaldicoesTuning` válido, não se cria. O estado fica em `Array[EstadoDoPacto]`, um por `player_id`, com `campo: MaldicaoRef`, `reserva: MaldicaoRef`, `recarga_troca: int`, `marca_virote: int`, `pedido_chamado` e os ids que esta dupla atraiu ou imobilizou.

### 2. `MaldicaoRef`: o aliado como entidade

`MaldicaoRef` é um registro (ADR-0003) com:

- `id: int`, tirado do mesmo espaço de ids das entidades (ADR-0003), para eventos, Telégrafos e projéteis apontarem para ela sem ambiguidade. A espécie fica em `especie_id: StringName`. Onde o GDD escreve `curse_id` como argumento de função, a arquitetura lê o `id` inteiro;
- `player_id: int` do dono (posse para co-op e autoria dos abates);
- `faccao = Faccao.ALIADO` (enum do ADR-0010);
- `portador: Portador` (ADR-0009), criado no começo da run, ou no passo do pacto quando a dupla cresce (R24), e nunca destruído na Exaustão;
- Vida `int`, estado (`SEGUINDO`, `PERSEGUINDO`, `PREPARO`, `EXECUCAO`, `RECUPERACAO`, `SALTANDO`, `PRONTA`, `EXAUSTA`), `pos: Vector2`, `dir: Vector2`, `alvo_id`, contador de fase, `restante_exausta`, `total_exausta`, `acum_regen: float`, `estourou_fio`, dados do salto e o contador de ataques concluídos (*Pulso de Soberania*).

Posse dos campos (ADR-0003 §3): o módulo é dono de tudo isso. O Combate escreve a Vida **só** no dano (Combate R21.3), pela chamada `descontar_vida(maldicao_id, dano) -> int`; regeneração e retorno são do módulo. A Maldição não entra na lista de inimigos, na de atingíveis nem na contagem de câmara limpa (R1).

### 3. Ordem interna do item 6.1

`passo_maldicoes()` roda só em passo vivo, para cada jogador em ordem de `player_id`, na ordem da R23 (aprovada no item 5 da lista de decisões):

| # | O que faz |
|---|---|
| 1 | Fins de atração e imobilização do passo anterior: para cada id guardado que a IA dá como livre, emite `atracao_fim`/`imobilizacao_fim` |
| 2 | Contadores da reserva e da dupla: `recarga_troca −1`; `restante_exausta −1` (a que zera fica `PRONTA` com `vida_retorno_frac × vida_max` e emite `maldicao_pronta`); regeneração F2 da `PRONTA` na reserva; `portador.avancar(1)` dos dois portadores da dupla |
| 3 | Campo vazio e alguma `PRONTA`: ela entra sem técnica (`maldicao_entrou`); em empate, a que ficou Exausta primeiro |
| 4 | Chamado pedido no item 5: começa o salto (`SALTANDO`, `chamado_salto`) |
| 5 | Troca manual do buffer: testa a R11 (recusada com motivo `saltando` se o passo 4 começou o salto). Aceita: Efeito de Saída, Efeito de Entrada, `troca_feita(manual)`, `tecnica_combinada`, `maldicao_saiu_de_campo`, recarga = `passos(recarga_troca_s)` |
| 6 | Salto em curso avança; no passo de pouso: golpe (R20), imobilização, atração e efeito próprio da espécie |
| 7 | IA de aliado: fio (F1), alvo (R4), passivas condicionais (R22), movimento |
| 8 | Ataque básico por fases; o acerto vai pela R20 do Combate |

O brief da fase sugeria outra sequência (troca → técnica → Chamado → movimento/ataque → contadores). Este ADR segue a R23 do GDD, porque ela já foi aprovada e porque a AC-ML-32 exige o Chamado antes da troca no mesmo passo. Ver "Decisões tomadas pelo agente".

**Exaustão síncrona.** A Exaustão não é um passo do 6.1: o dano chega nos itens 7 e 8, depois do 6.1. O Combate (R21.7) chama `exaurir(maldicao_id)` no mesmo ponto do passo em que a Vida chega a 0. Dentro dele, de forma síncrona: Vida 0, estado `EXAUSTA`, `total_exausta = restante_exausta = passos(recuperacao_exausta_s × mult_recuperacao) × (1 − reducao_da_especie)` fixados agora (R19), ida para a reserva, remoção das passivas condicionais, `maldicao_saiu_de_campo(player_id)` à IA, `atracao_fim` dos ids guardados e, se a reserva estiver `PRONTA`, a troca automática (entra ao lado do jogador, `troca_feita(automatica)`, sem técnica e sem recarga). A que entra só age no 6.1 seguinte. Assim os inimigos que ainda rodam no item 7 já miram o jogador (AC-ML-13, AC-ML-30).

### 4. IA de aliado

- **Alvo (R4):** a cada passo, a marca do Virote se atingível e no fio; senão o inimigo atingível mais perto do jogador no fio; senão nenhum. Distância ao quadrado, empate pelo menor id. A marca é atualizada pelo `EvAcertoDeArma` do Virote do dono (lido da lista, item 5/8 do passo anterior ou deste) e limpa quando o alvo sai de `atingivel`.
- **Fio (R5, F1):** com `d_jog > alcance_fio_px`, `estourou_fio = true`, alvo limpo, estado `SEGUINDO`, inimigos ignorados até `d_jog ≤ distancia_seguir_px` (histerese).
- **Movimento:** reta até o alvo (ou até `distancia_seguir_px` do jogador), passo de `valor(velocidade)/60` do portador, corrigido por `resolver_colisao` do ADR-0008 com o raio da espécie contra retângulo e obstáculos. Não colide com jogador nem inimigos (R1). Sem busca de caminho no MVP.
- **Atração do Chamado (R17):** o módulo pede `ia.atrair(inimigo_id, passos(duracao_atracao_s), passos(respiro_atracao_s))` = `(90, 30)` e guarda o id só se a IA aceitar (`true`). A IA é dona dos contadores, da recusa sem renovação e do respiro; o módulo não tem número próprio de atração. *Pulso de Soberania* e *Queda de Pilar* usam a mesma chamada, com a duração do seu `TecnicaDef`, limitada a `duracao_atracao_s` pela ML1 na carga.
- **`fator_andar_atraido`:** consulta exposta à IA, `1,0` ou o valor da passiva da espécie em campo.

### 5. Técnica combinada como dado

O `CurseDef` (catálogo do ADR-0004) ganha três campos do tipo `TecnicaDef`: `saida`, `entrada` e `efeito_chamado` (opcional, Raro+); a habilidade única Primordial é um `TecnicaDef` com gatilho "a cada N ataques concluídos". `TecnicaDef` é só dado: forma (`circulo`, `arco`, `avanco`), ancoragem (onde a Maldição está, ao lado do jogador, ou avanço até `alcance_px` na direção do alvo da F1), raio, dano, empurrão, `pesado`, status (`id`, duração), controle (`imobilizar` com regra comum/elite, `atrair`, `puxar`), `bonus_sinergia_pct`. Um intérprete único, `ExecutorDeTecnica` (funções `static`), executa qualquer `TecnicaDef`. A troca manual executa `saida` da que sai e depois `entrada` da que entra, no mesmo passo; a Entrada lê o que a Saída deixou (`esta_imobilizado`, `esta_atraido`, Abalo no Status) para a sinergia da F5. O Edge Case "Saída mata o alvo da Entrada" se resolve porque a Entrada só considera ids com `atingivel` verdadeiro; a remoção, a cura e o hitstop do abate continuam na varredura (item 9). Nenhum par de espécies tem código próprio.

### 6. Golpes pela R20 do Combate, facção ALIADO, sem fogo amigo

A geometria do golpe (arco, círculo, avanço, pouso) é do módulo e usa `GeometriaDeAcerto` (ADR-0010 §9) contra a lista de atingíveis. Para cada alvo, o módulo chama `combate.aplicar_golpe_maldicao(...)` (Combate R20) com `player_id` do dono, `id` da Maldição, alvo, dano, `M`, direção, empurrão, status, `pesado` e `ataque_id`. O Combate aplica a R8 com `de_arma` falso e `autor_player_id` = dono: sem contador de acerto, sem Fluxo, sem `golpe_*`, sem hitstop. `M` é `portador.multiplicador_de_dano` da Maldição, calculado no impacto; no pouso do Chamado é o `M_chamado` do jogador, congelado no disparo e recebido em `pedir_chamado`.

Sem fogo amigo, por construção: (a) a Maldição nunca está na lista de atingíveis que golpes do jogador, Selo, explosão e Status percorrem; (b) o único caminho de dano até ela é `ferir_maldicao` do Combate, chamado só por golpes de inimigo que a têm como alvo travado (Combate R22, ADR-0014); (c) o módulo só fere ids da lista de atingíveis (inimigos e chefe), nunca a acuada nem o jogador. Golpes inimigos que miram a Maldição chegam por `ferir_maldicao`, que consulta `maldicao_atingivel(id)` (em campo, Vida > 0, não `SALTANDO`).

### 7. Chamado do Pacto

`pode_chamar(player_id)` e `pedir_chamado(player_id, ponto_mirado, dano_golpe, m_chamado)` são consultados e chamados pelo Combate no item 5 (R3.1). O módulo guarda o pedido e o executa no 6.1 do mesmo passo. O destino é fixado no início do salto: ponto mirado limitado a `alcance_chamado_px` do jogador e cortado no primeiro obstáculo por `GeometriaDeAcerto.alcance_do_raio`. O salto é interpolação linear em `passos(duracao_salto_s)` passos, imune a dano e empurrão. No pouso: golpe de área, imobilização do inimigo comum mais perto do centro (`ia.imobilizar`), atração de todos em `raio_atracao_px` (§4) e `efeito_chamado` da espécie.

### 8. Propagação de Bênçãos ao portador da Maldição

A propagação (Modificadores R14/F6) fica num colaborador puro deste ADR, `EspelhoDaDupla`, injetado no caminho por onde fontes entram no portador do jogador. Quando uma fonte é aplicada, substituída ou removida no portador do jogador e o seu tipo está em `tipos_propagados_maldicao` (`dano_todo_pct`, `velocidade_pct`), ele aplica ou remove `espelho:<id_da_fonte>` em cada portador da dupla do mesmo `player_id`, com `valor × fator_propagacao_maldicao` (`1,0`), a mesma operação e a mesma duração restante. Nenhum gatilho propaga: o espelho é sempre fonte de atributo, nunca de gatilho; `cura_ao_abater` e `explosao_ao_abater` já valem porque o abate é do dono. O espelho expira sozinho no `avancar` do portador da Maldição (passo 2 do 6.1), com a mesma contagem de passos vivos da fonte original. Quando a dupla cresce no meio da run, o portador novo nasce com um espelho de cada fonte propagável ativa (R24, AC-ML-33).

### 9. Câmaras, congelamento e fim da run

`reposicionar_maldicao(player_id, pos)` é chamado pelo Câmaras na troca de câmara (R14): estado `SEGUINDO`, fio, alvo e marca limpos, atrações e imobilizações encerradas com aviso à IA, reserva intocada. Hitstop, pausa e Transição não chamam o 6.1 (ADR-0001), então nada avança (AC-ML-20). O módulo é criado pela composição da run (ADR-0015) e descartado no fim dela.

### 10. Eventos

Subclasses de `EventoDoPasso` (ADR-0002), todas com `player_id`. Mapeamento entre os nomes do contrato da fase e os do GDD:

| Evento (catálogo ADR-0002) | GDD (R20/R21) | Emissor |
|---|---|---|
| `EvMaldicaoTrocada` (`modo` manual/automática; não `tipo`, que é o método de `EventoDoPasso`, `saiu_id`, `entrou_id`) | `troca_feita` | Maldições |
| `EvTecnicaCombinada` | `tecnica_combinada` | Maldições |
| `EvMaldicaoFerida` | `maldicao_atingida` | Combate |
| `EvMaldicaoExausta` | `maldicao_exausta` | Combate |
| `EvTrocaIndisponivel`, `EvMaldicaoEntrou`, `EvMaldicaoPronta`, `EvMaldicaoGolpe`, `EvChamadoSalto`, `EvChamadoPouso`, `EvMarcaViroteMudou`, `EvAtraido`, `EvAtracaoFim`, `EvImobilizado`, `EvImobilizacaoFim`, `EvFioEstourou` | os demais da R20 | Maldições |

`chamado_indisponivel` continua só no Combate (um emissor, um som).

### 11. Alvo dos inimigos no encontro de pacto (registrado aqui; não há ADR de IA)

A regra de jogo é da IA (R16, R22) e do Vínculo (V8, V44); este ADR fixa só a estrutura, porque o alvo por inimigo é a mesma estrutura que a atração da Maldição já exige.

- **Estrutura:** cada inimigo guarda, no registro da IA, `alvo_padrao` ∈ {`JOGADOR`, `ACUADA`} (tipo `AlvoDeInimigo`, com `player_id` para co-op) e a atração corrente (`restante_atracao`, `restante_respiro`, `maldicao_id`). O alvo efetivo é calculado por uma função pura da IA, `alvo_efetivo(inimigo_id) -> AlvoDeInimigo`, nesta prioridade: (1) atraído e a Maldição ainda em campo → a Maldição; (2) `alvo_padrao` = `ACUADA` e `acuada_atingivel()` (Vínculo) verdadeira → a acuada; (3) o jogador.
- **Alvo padrão pela paridade (V8, IA R22):** fixado uma vez, no nascimento, pela ordem de nascimento na onda (Câmaras R7): ordem par mira a acuada, ímpar o jogador. Só vale na câmara do encontro com a acuada em `Acuada`; fora dela, todo `alvo_padrao` é `JOGADOR`. Chefe e elites seguem a mesma regra quando nascem na câmara do encontro.
- **Atração com prioridade:** a atração do §4 sobrepõe o alvo padrão enquanto dura; ao acabar (tempo, saída de campo da Maldição, câmara), o inimigo volta ao `alvo_padrao`, não necessariamente ao jogador (AC-IA-55).
- **Um golpe só testa o seu alvo:** o alvo efetivo é lido uma vez, no início do preparo, e travado no telégrafo e no projétil (ADR-0014, campo `alvo_id` do projétil no ADR-0010). O golpe mirado na acuada chama só `ferir_acuada`; o mirado na Maldição, só `ferir_maldicao`; o mirado no jogador, só `ferir_jogador`.
- **Fuga no mesmo passo:** como (2) consulta `acuada_atingivel()` a cada leitura, quando a acuada passa a `Fugiu` (V12) ou falha, todo inimigo que ainda vai rodar no item 7 daquele passo já lê o jogador, sem pedido extra à IA. Um telégrafo já travado na acuada termina sem ferir ninguém, como o mirado na Maldição que saiu de campo.

### 12. A dupla que cresce no meio da run e os bônus de vínculo

- **Dupla de 1 para 2 (V15, V43, Maldições R24):** quando o Vínculo resolve o pacto do encontro com dupla de 1, chama `acrescentar_a_dupla(player_id, def, min(vida_acuada, vida_max))`. No mesmo passo: `MaldicaoRef` nova com id do ADR-0003, estado `PRONTA` na **reserva**, `acum_regen = 0`, portador novo montado como o do começo da run (base do `CurseDef` + `vinculo:<id>` de nível 1, sem ganho + `especie:<id>` + espelhos do §8 com a duração restante). Com a de campo Exausta, a nova entra pelo passo 3 do 6.1 seguinte (`maldicao_entrou(retorno)`). Com a dupla cheia, nada muda na run. O pacto com o chefe não chama `acrescentar_a_dupla` (V18).
- **Bônus de vínculo só no começo da run (V19, F4):** a Vida extra entra pela fonte de modificador `vinculo:<curse_id>` no portador, aplicada uma vez na criação da run (ADR-0015). `mult_recuperacao` (F2) e `bonus_dano_basico` (F3) são lidos do Vínculo no mesmo momento e guardados na `MaldicaoRef`; o módulo não relê o Vínculo durante a run, então um nível ganho no meio da run só vale na próxima. O vínculo não toca técnica, Chamado nem recarga da troca.

### Architecture Diagram

```text
item 5  Combate ──pode_chamar / pedir_chamado──▶ ModuloDeMaldicoes
item 6.1                                        │ R23 passos 1–8 (por player_id)
          ┌─────────────────────────────────────┼──────────────────────────────┐
          ▼                                     ▼                              ▼
  IA (atrair, imobilizar,           Combate.aplicar_golpe_maldicao      EventosDoPasso
      saiu_de_campo)                 (R20, ALIADO, de_arma falso)
itens 7/8 IA/Telégrafos/projétil ──ferir_maldicao──▶ Combate ──descontar_vida / exaurir──▶ ModuloDeMaldicoes
Bênçãos ──fonte no portador do jogador──▶ EspelhoDaDupla ──espelho:<id>──▶ Portador da Maldição
```

### Key Interfaces

```gdscript
class_name ModuloDeMaldicoes extends RefCounted
func passo_maldicoes(comandos: Array[ComandosDoPasso]) -> void        # item 6.1, índice = player_id
# Contrato com o Combate (R3.1, R21, R22)
func pode_chamar(player_id: int) -> bool
func pedir_chamado(player_id: int, ponto_mirado: Vector2, dano_golpe: float, m_chamado: float) -> void
func maldicao_atingivel(maldicao_id: int) -> bool
func posicao_e_raio(maldicao_id: int) -> Vector3                      # (x, y, raio)
func portador_de(maldicao_id: int) -> ConsultaDeAtributos
func descontar_vida(maldicao_id: int, dano: int) -> int               # só o Combate chama; devolve a Vida
func exaurir(maldicao_id: int) -> void                                # síncrono, itens 7/8; muda o estado, NÃO emite `maldicao_exausta` (emissor único: Combate)
# Contrato com a IA (R21)
func maldicao_em_campo(player_id: int) -> int                         # id ou -1
func fator_andar_atraido(player_id: int) -> float
# Câmaras, Vínculo, HUD
func reposicionar_maldicao(player_id: int, pos: Vector2) -> void
func acrescentar_a_dupla(player_id: int, def: CurseDef, vida: int) -> void   # R24, passo do pacto
func estado_pacto(player_id: int) -> EstadoPactoLeitura               # R19, sem efeito colateral

class_name MaldicaoRef extends RefCounted
var id: int; var player_id: int; var especie_id: StringName; var portador: Portador
var vida: int; var estado: int; var pos: Vector2   # demais campos em §2

class_name ExecutorDeTecnica extends RefCounted                        # funções static
static func executar(t: TecnicaDef, autor: MaldicaoRef, ctx: ContextoDaTecnica) -> int   # devolve acertos

class_name EspelhoDaDupla extends RefCounted
func fonte_aplicada(player_id: int, fonte: FonteDeModificador) -> void
func fonte_removida(player_id: int, id_fonte: StringName) -> void
```

### Implementation Guidelines

- MUST seguir a ordem da R23 (§3) e iterar jogadores e alvos por id crescente.
- MUST mandar todo dano a inimigo por `aplicar_golpe_maldicao`; MUST NEVER escrever Vida de inimigo nem pedir hitstop.
- MUST tratar `exaurir` como síncrono e avisar a IA dentro dele.
- MUST ler duração de atração e respiro do `MaldicoesTuning`, convertidos na carga; a IA não guarda número próprio.
- MUST guardar tudo por `player_id`; MUST NEVER campo singular "a Maldição".
- MUST NEVER propagar gatilho nem tipo fora de `tipos_propagados_maldicao`.
- MUST NEVER usar RNG, `Node`, `Area2D`, `Timer`, sinal do Godot ou `Engine.time_scale` na regra.

## Alternatives Considered

### Alternative 1: Maldição como inimigo com facção invertida dentro da IA

- **Description**: reaproveitar a máquina de estados e o movimento da IA de inimigos, trocando a facção.
- **Pros**: menos código de movimento.
- **Cons**: a IA percorre a lista de inimigos e atingíveis; a Maldição entraria na contagem de câmara limpa e nos testes de acerto do jogador, o oposto da R1. Troca, reserva e técnica não existem na IA.
- **Rejection Reason**: quebra o "sem fogo amigo" por padrão e mistura dois donos de regra.

### Alternative 2: Caminho próprio de dano das Maldições

- **Description**: o módulo calcula e aplica dano, empurrão e cambaleio sozinho.
- **Pros**: menos dependência do Combate.
- **Cons**: duplica a R8 (armadura de elite, "Quebrou!", autor do abate, varredura), contra o Combate R20.
- **Rejection Reason**: dois caminhos de impacto divergem; a R20 já define o caminho único.

### Alternative 3: Técnica por par em código

- **Description**: uma função por combinação Saída/Entrada.
- **Cons**: 12 funções no MVP, crescimento quadrático com espécies novas, contra a R12 ("sem escrever cada par").
- **Rejection Reason**: o dado com intérprete único cobre o MVP e as espécies futuras.

## Consequences

### Positive

- Todo o comportamento aliado é testável em memória com dublês, na ordem exata da R23.
- Um só caminho de dano (R20) mantém armadura, "Quebrou!" e autoria de abate idênticos aos do jogador.
- Espécie nova é só dado (`CurseDef` + `TecnicaDef`), validada pelo ADR-0004.
- Co-op: posse por `player_id` em toda estrutura, sem custo hoje.

### Negative

- Mais uma fachada com muitos colaboradores (Combate, IA, Status, Movimento, catálogo).
- `exaurir` e `descontar_vida` são chamadas "para o lado" vindas do Combate nos itens 7/8, exceção explícita como o Selo e o Status no ADR-0002.
- O `ExecutorDeTecnica` precisa cobrir todas as formas e controles do catálogo; efeito novo pede campo novo no `TecnicaDef`.

### Neutral

- A Maldição não tem RNG; o ADR-0005 não é dependência.

## Risks

- **Ordem interna do 6.1 (resolvido na harmonização de 2026-11-16):** a ordem canônica é a da R23 (§3) e este ADR é o dono dela; os demais ADRs citam "item 6.1 Maldições (ordem interna: ADR-0017 §3)" sem repetir a lista. A troca automática da Exaustão sai em `exaurir`, chamado pelo Combate nos itens 7/8.
- **Assinatura de `ferir_maldicao` (resolvido):** vale a do ADR-0010 (Combate R21): `ferir_maldicao(maldicao_id, dano_base, m_atacante, atacante_id, ataque_id)`, e igualmente `ferir_acuada(dano_base, m_atacante, atacante_id, ataque_id)`. Este ADR só precisa que o Combate chame `descontar_vida` e `exaurir`.
- **Convergência (*Soberano*, efeito no Chamado) puxa inimigos 60 px:** precisa de um pedido de deslocamento na IA (o mesmo que o puxão do chefe usar). Sem ele, o controle `puxar` do `TecnicaDef` fica sem efeito.
- **Espelho e duração restante:** o ADR-0009 precisa expor a duração restante de uma fonte para o portador criado no meio da run (R24).

## GDD Requirements Addressed

IDs oficiais do `tr-registry.yaml`; TR-maldicoes-019 (orçamento do 6.1) e TR-ia-019 (`puxar`) são novos, com a entrada em `tr-novos/extras.yaml`.

| TR | GDD | Requisito | Como |
|---|---|---|---|
| TR-maldicoes-001 | Maldições | R1, AC-ML-01, AC-ML-02 | Facção `ALIADO`, fora das listas de atingíveis e da câmara limpa (§2, §6) |
| TR-maldicoes-002 | Maldições | R2, R24, AC-ML-03, AC-ML-33 | `EstadoDoPacto` por jogador; `acrescentar_a_dupla` |
| TR-maldicoes-017, TR-conteudo-016, TR-conteudo-018 | Maldições | R3, Catálogo, ML1–ML8, AC-ML-04, AC-ML-23, AC-ML-26 | `CurseDef`/`TecnicaDef` no ADR-0004, validados na carga |
| TR-maldicoes-004 | Maldições | R4, R5, F1, AC-ML-05, AC-ML-06 | IA de aliado: alvo, fio com histerese (§4) |
| TR-maldicoes-005 | Maldições, Combate | R6, F3, Combate R20, AC-ML-07–09 | Golpe pela R20, `de_arma` falso, sem hitstop (§6) |
| TR-maldicoes-006, TR-combate-nucleo-021 | Maldições, Combate | R7, Combate R22, AC-ML-10 | Só `ferir_maldicao` fere a Maldição; alvo travado (ADR-0014) |
| TR-maldicoes-008 | Maldições, Combate | R8, Combate R21, AC-ML-12 | `descontar_vida`, sem invulnerabilidade nem hitstop |
| TR-maldicoes-008, TR-combate-nucleo-021 | Maldições, Combate | R9, Combate R21.7, AC-ML-11, AC-ML-13, AC-ML-30 | `exaurir` síncrono com troca automática (§3) |
| TR-maldicoes-009 | Maldições | R10, F2, AC-ML-14 | Regeneração no passo 2 do 6.1 |
| TR-maldicoes-010, TR-input-013 | Maldições, Input | R11, Input R1a, AC-ML-16 | Troca do buffer (`troca`, R/Tab e LT), recusa com motivo |
| TR-maldicoes-011, TR-ia-019 | Maldições | R12, F5, AC-ML-15 | `TecnicaDef` + `ExecutorDeTecnica` (§5) |
| TR-maldicoes-012 | Maldições, Combate | R13, F4, Combate R3.1, AC-ML-17, AC-ML-18 | `pode_chamar`/`pedir_chamado`, salto e pouso (§7) |
| TR-maldicoes-007 | Maldições, IA | R17, F4b, IA R17, AC-ML-24, AC-ML-25, AC-ML-36 | `atrair(id, 90, 30)`; IA dona da recusa e do respiro |
| TR-maldicoes-013, TR-camaras-011 | Maldições | R14, AC-ML-19, AC-ML-35 | `reposicionar_maldicao` (§9) |
| TR-maldicoes-009, TR-maldicoes-003 | Maldições | R15, AC-ML-20 | 6.1 só em passo vivo (ADR-0001) |
| TR-maldicoes-017 | Maldições | R16, AC-ML-21 | Primordial como `CurseDef`; habilidade única como `TecnicaDef` com gatilho |
| TR-maldicoes-014 | Maldições | R19, AC-ML-28 | `estado_pacto` sem efeito colateral |
| TR-maldicoes-015, TR-combate-nucleo-024 | Maldições | R20, AC-ML-29 | Eventos tipados (§10) |
| TR-maldicoes-007, TR-ia-015 | Maldições, IA | R21, IA R16–R18 | `maldicao_saiu_de_campo`, `fator_andar_atraido` |
| TR-maldicoes-016 | Maldições, Modificadores | R22, AC-ML-31 | Passivas condicionais por fonte `especie:<id>:<passiva>` no passo 7 |
| TR-maldicoes-003, TR-combate-nucleo-019 | Maldições, Combate | R23, Combate R1 item 6.1 e R23, AC-ML-32 | Ordem interna do 6.1 (§3) |
| TR-modificadores-015, TR-maldicoes-016 | Modificadores | R14, F6; Maldições R24 | `EspelhoDaDupla`, fator 1,0, nenhum gatilho (§8) |
| TR-maldicoes-017, TR-armas-012 | Maldições, Armas | F6, AC-ML-27; Armas emenda da Besta | O módulo executa os números do catálogo sem alterá-los; paridade validada na carga (ADR-0004) |
| TR-maldicoes-003, TR-maldicoes-011, TR-maldicoes-012 | Maldições | Edge Cases (Saltando, Saída mata, duas Exaustas, Troca + Chamado) | §3, §5, §7 |
| TR-maldicoes-019 *(novo)* | Maldições | Desempenho do 6.1 | Orçamento ≤ 0,1 ms p99 (Performance) |
| TR-ia-015, TR-ia-018, TR-vinculo-006, TR-maldicoes-006 | Vínculo, IA, Combate | V8, V44; IA R16, R22; Combate R22, R25; AC-IA-55 | Alvo efetivo por inimigo com prioridade atração > acuada > jogador; paridade da ordem; troca no mesmo passo na fuga (§11) |
| TR-vinculo-010, TR-maldicoes-002, TR-modificadores-014 | Vínculo, Maldições, Modificadores | V15, V43; Maldições R24; Modificadores R14 | `acrescentar_a_dupla` com reserva `PRONTA`, Vida = `min(Vida_acuada, vida_max)` (§12) |
| TR-vinculo-014 | Vínculo | V19, F4; Maldições R24 | Bônus de vínculo fixados no começo da run pela fonte `vinculo` (§12) |

## Performance Implications

- **CPU:** por jogador e passo, O(inimigos) na escolha de alvo e em cada forma de golpe; a técnica e o pouso fazem 2–3 varreduras extras só no passo em que acontecem. Com 9 inimigos: algumas dezenas de comparações de distância ao quadrado. **Orçamento proposto: item 6.1 ≤ 0,1 ms por passo vivo, p99**, medido com 1 jogador, dupla cheia e 9 inimigos, num passo com troca manual e pouso do Chamado (o pior caso), em `tests/performance/maldicoes/`. Entra na tabela de orçamento do ADR-0001 (total do passo vivo ≤ 1,0 ms p99).
- **Memória:** 2 `MaldicaoRef` e 2 portadores por jogador; listas reutilizadas entre passos. Sem alocação no caminho quente além dos eventos (ADR-0002).
- **Load Time:** desprezível; `CurseDef` convertidos uma vez na carga.
- **Network:** nenhum.

## Migration Plan

Módulo novo, sem código anterior. Sequência: (1) `ExecutorDeTecnica` e `TecnicaDef` com testes da F5; (2) `ModuloDeMaldicoes` com dublês de Combate, IA, Status e portador, cobrindo as AC-ML; (3) `EspelhoDaDupla` com dublê de portador; (4) integração no orquestrador (item 6.1) e na composição da run (ADR-0015); (5) HUD e Feedback passam a ler `estado_pacto` e os eventos.

## Validation Criteria

Testes unitários em `tests/unit/maldicoes/`, todos com dublês e sem I/O:

- `test_ordem_6_1`: Chamado e Troca no mesmo passo → salto começa e troca recusada com `saltando`, nenhuma técnica (AC-ML-32); fim de atração emitido no passo seguinte ao fim (AC-ML-29).
- `test_exaurir_sincrono`: Baluarte com Vida 5 recebe 8 no item 7 → no mesmo passo vai `EXAUSTA` (600), Vulto entra sem técnica e sem recarga, 2º e 3º inimigos já miram o jogador (AC-ML-13, AC-ML-30); retorno com 68.
- `test_regeneracao_reserva`: 68/135 chega a 135/135 em 596 passos com `acum_regen` zerado (AC-ML-14).
- `test_tecnica_emboscada`: Paredes de Sombra 5 + Salto de Emboscada 9 = 14, 1 `troca_feita(manual)` e 1 `tecnica_combinada`, recarga 240 (AC-ML-15 emendada).
- `test_saida_mata_alvo_da_entrada`: a Entrada escolhe o próximo candidato da F1.
- `test_golpe_pela_r20`: dublê do Combate recebe `aplicar_golpe_maldicao` com `de_arma` falso, autor = dono; nenhum pedido de hitstop (AC-ML-07, AC-ML-08).
- `test_sem_fogo_amigo`: Virote, Selo, explosão e Status sobre a área não alteram a Maldição (AC-ML-01).
- `test_atracao_sem_renovacao`: `atrair` recebe `(90, 30)`; pedidos recusados não geram `atraido` (AC-ML-24).
- `test_chamado`: salto de 12 passos até (920, 500), imobiliza só o comum, atrai os dois por 90 (AC-ML-17); sem campo, recusa sem gastar recarga (AC-ML-18).
- `test_fio_histerese`: AC-ML-06 em 58 passos.
- `test_espelho_da_dupla`: `dano_todo_pct +0,20` no jogador → espelho `+0,20` nos dois portadores; remoção some nos dois; gatilho `cura_ao_abater` não gera espelho; portador criado no meio da run nasce com o espelho (AC-ML-33).
- `test_congelamento`: 6 passos sem chamar o 6.1 não mudam nada (AC-ML-20).
- `test_estado_pacto`: AC-ML-28, igual na pausa.
- `test_alvo_no_encontro` (IA, dublê do Vínculo): ordem 0 mira a acuada, ordem 1 o jogador; atraído mira a Maldição e, no respiro, volta à acuada; com a acuada em `Fugiu` no meio do item 7, os inimigos seguintes já leem o jogador (AC-IA-55, V8).
- `test_dupla_cresce`: AC-ML-33 e o caso da única Maldição Exausta (entra no passo 3 do 6.1 seguinte com `maldicao_entrou(retorno)`); dupla cheia não muda.
- `test_vinculo_so_no_comeco`: um nível ganho no meio da run não altera `total_exausta` nem o dano até a run seguinte (AC-ML-34 na run seguinte).
- Desempenho: `tests/performance/maldicoes/` mede o p99 do pior caso contra 0,1 ms.

Este ADR estará certo se nenhuma story de Maldições precisar de caminho de dano próprio nem de código por par de espécies, e se o 6.1 ficar abaixo do orçamento no build real.

## Decisões tomadas pelo agente (a revisar)

1. **Ordem do 6.1 pela R23 do GDD**, não pela sequência do brief (troca → técnica → Chamado → movimento/ataque → contadores). A AC-ML-32 exige o Chamado antes da troca, e os contadores no início fazem a Pronta que acabou de voltar já poder entrar no passo 3.
2. **Exaustão fora do 6.1:** `exaurir` é uma entrada síncrona chamada pelo Combate nos itens 7/8, como diz o Combate R21.7. A troca automática sai no mesmo passo, mas não é um passo do 6.1.
3. **Vida da Maldição guardada no módulo**, escrita pelo Combate só por `descontar_vida` (ADR-0003 §3: dono único).
4. **`curse_id` dos GDDs lido como o `id` inteiro da entidade**; a espécie é `especie_id: StringName`.
5. **`portador.avancar(1)` da dupla no passo 2 do 6.1**, inclusive na reserva (Modificadores R14).
6. **Propagação num colaborador deste ADR (`EspelhoDaDupla`)**, e não dentro do ADR-0009, para o portador genérico não conhecer Maldições. Exige do ADR-0009 a duração restante de uma fonte.
7. **`TecnicaDef` cobre também o efeito no Chamado e a habilidade única** (gatilho por N ataques), além de Saída e Entrada.
8. **Reposicionar com a Maldição `SALTANDO` cancela o salto sem pouso.** Na troca de câmara não há inimigo vivo, então nada se perde.
9. **Eventos extras** (`EvTrocaIndisponivel`, `EvMaldicaoEntrou` e outros, §10) propostos para o catálogo do ADR-0002, além dos quatro do contrato da fase.
10. **Destino do salto fixado no início** por `alcance_do_raio`, e não testado a cada passo.
11. **Alvo dos inimigos no encontro registrado aqui** (§11), por falta de ADR de IA. Se um ADR de IA nascer, a §11 migra para lá. Escolhas do agente: o alvo é calculado a cada leitura (não guardado), por isso a fuga troca o alvo sem pedido extra; elites e chefe na câmara do encontro seguem a paridade.
12. **`mult_recuperacao` e `bonus_dano_basico` guardados na `MaldicaoRef`** no começo da run, e não como atributos do portador: a F2 e a F3 os usam como fatores, e o ADR-0009 não lista esses atributos. Só a Vida extra passa pela fonte `vinculo`.

## Related

- `design/gdd/maldicoes.md`, `design/gdd/combate-nucleo.md` (R3.1, R20–R23), `design/gdd/ia-de-inimigos-e-elites.md` (R16–R18, R22), `design/gdd/modificadores-e-atributos.md` (R14, F6), `design/gdd/input-e-controle.md` (R1a), `design/gdd/armas-das-doutrinas.md` (emenda Pactos, Besta do Vínculo)
- `design/gdd/pactos-decisoes-a-confirmar.md` (itens 1, 5, 6, 7, 8)
- ADR-0015 (ciclo da run), ADR-0012 (HUD do Pacto), ADR-0016 (áudio)
