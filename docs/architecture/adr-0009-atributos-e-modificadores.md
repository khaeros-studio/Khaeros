# ADR-0009 — Atributos e modificadores

## Status

Accepted · 2026-11-16 (aprovado pelo usuário; Proposed em 2026-11-15)

> Quem pode mover para `Accepted`: o usuário, ou `technical-director` com confirmação explícita do usuário.

## Date

2026-11-15

## Last Verified

2026-11-17 (experimento EX-0009-1: `float` IEEE-754 binary64 marcado como Verificado com `2^52 + 1.0 != 2^52` e nota sobre literais em empate no tokenizer). Antes: 2026-11-16 (emenda Pactos: portador da Maldição, espelho, fontes `especie`/`vinculo`/`furia`, `bonus_dano_basico`). Antes: 2026-11-15 — GDD de Modificadores e atributos (R1–R13, F1–F5, Edge Cases, AC-01–AC-32), Bênçãos R5/AC-BN-08–09, Efeitos de status R6/F4, Combate núcleo (Interactions, F de reflexo e empurrão), `design/registry/entities.yaml` (`derived_value`, `hit_damage_multiplier`, `damage_taken`, `damage_reduction_cap` 0,6, `player_min_max_hp` 20), ADRs 0001–0004 e 0008, fatia em `src/gameplay/game_session.gd`.

## Decision Makers

Proposta do `gameplay-programmer` (subagente da aba de Arquitetura), autorizada pelo usuário a escrever em paralelo com os ADRs 0010–0014. Aceite pendente de revisão consolidada (`/architecture-review`). Nenhum GDD foi alterado; o que tocaria regra está em "Decisões pendentes do usuário".

## Summary

Bênçãos, elites, profundidade, chefes e Abalo mudam os números de qualquer combatente pelo mesmo encanamento, e o GDD deixa ao ADR a representação, o cache e o arredondamento. Decide-se um `Portador` RefCounted por combatente, com os agregados recalculados **na escrita** (nunca na leitura), soma em ordem canônica de fonte, cálculo em `float` com piso, teto e arredondamento meio-longe-do-zero **só no fim**, um `DanoCongelado` para o M do disparo e um registro passivo de gatilhos que os sistemas donos consultam por injeção.

## Engine Compatibility

| Field | Value |
|---|---|
| **Engine** | Godot 4.7, pin 4.7.2 |
| **Domain** | Core (GDScript puro) |
| **Layer** | Core |
| **Knowledge Risk** | LOW — só `RefCounted`, `Array[T]`, `StringName`, aritmética escalar |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md` (retorno tipado herdado 4.7; `@abstract` 4.5), `current-best-practices.md`, `deprecated-apis.md` (preferir `Array[T]` a `Array`/`Dictionary` sem tipo) |
| **Post-Cutoff APIs Used** | `@abstract` (4.5, confirmado) nas bases de contrato; regra 4.7 de `return` explícito em override tipado |
| **Verification Required** | (1) `float` do GDScript é IEEE-754 de 64 bits (binary64) no build padrão: **Verificado (EX-0009-1, 2026-11-16)** com `2^52 + 1.0 != 2^52` (`true`), `2^53 + 1.0 == 2^53` (`true`) e bits de `0.1 + 0.2 == 0x3fd3333333333334` idênticos no projeto e no `.pck` exportado, com nota sobre literais em empate no tokenizer (`9007199254740993.0` literal vs `to_float()`; ver "Verificação de engine (2026-11-16)"); (2) semântica de `round()`/`floor()` globais: **não usada como fonte** — o arredondamento é função própria testada; (3) ordem de iteração de `Dictionary`: **não usada** para nada que afete resultado |

## ADR Dependencies

| Field | Value |
|---|---|
| **Depends On** | [ADR-0001](adr-0001-orquestrador-do-passo.md) (passo vivo/congelado, estados); [ADR-0002](adr-0002-canal-de-eventos.md) (chamada direta vs lista); [ADR-0003](adr-0003-entidades-e-portadores.md) (portador em `RefCounted`, ids); [ADR-0004](adr-0004-catalogo-de-dados.md) (`EffectDef`, `RarityTable`, `ModifiersTuning`, V4/V11, F7 de passos) |
| **Enables** | ADR-0010 (Combate consome F2/F3, gatilhos e notificações de recurso); ADR-0008 (já consome `valor`/`multiplicador_de_dano` no Corte); stories de Bênçãos, Status, Selo, IA/elites |
| **Blocks** | Epic de Modificadores; stories de Combate, Bênçãos e Status que leem atributos |
| **Ordering Note** | Implementável e testável em memória antes do 0010; a integração do reflexo, recusa e cadeia de abates depende da ordem interna aceita no 0010 |

## Context

O GDD aprovado fixa as fórmulas (F1–F5) com paridade numérica ao cânone e exige que uma mudança valha na consulta seguinte (R7, AC-12), que o resultado independa da ordem das bênçãos (AC-06), que inteiros arredondem meio-longe-do-zero só no fim (AC-05) e que o M de golpe de arma seja congelado no disparo, com só o 4º acerto avaliado por alvo no impacto (R12, AC-29). Ele deixa explicitamente ao ADR "lista por portador, cache do valor derivado, quando recalcular" (OQ 1). Hoje a fatia (`game_session.gd`) usa um `damage_multiplier` global somado, um `match` por id de bênção e `blessing_counts` que **empilha** a mesma bênção (contrário a AC-15); nada disso é base para produção. Restrições: lógica pura sem `SceneTree`, singleton ou `Timer`; tempo em passos inteiros; dados do catálogo; co-op 1–4 pós-MVP exige portador por `player_id`.

## Decision

### 1. Portador por combatente, agregados recalculados na escrita

`Portador extends RefCounted` existe para todo combatente (jogador, inimigo, elite, chefe) e guarda `id_combatente: int`, `player_id: int` (−1 em inimigo), as bases, as fontes ativas e os **agregados**. Escritas (aplicar, remover, expirar) são raras — escolha de bênção, spawn, bordas do Abalo — e leituras são muitas por passo (velocidade, M a cada disparo, HUD). Por isso cada escrita reconstrói, no mesmo método, todos os agregados do portador: por atributo, Σ planos, Σ percentuais, Π multiplicadores e o valor final já com piso/teto/arredondamento; para dano, `P_todo`, `P_ataque/especial/selo`, Π incondicional de `dano_todo` e a lista curta de multiplicadores/percentuais condicionais; por tipo de gatilho, entradas e total. Não há bandeira de sujo nem invalidação externa: a única forma de mudar o cache é a API do próprio portador, então R7 vale por construção. Recurso (Vida atual, escudo atual, cargas restantes, contador de acertos, janela pós-esquiva) **nunca** entra no cache; condicionais são avaliadas no uso com o contexto passado (AC-07).

### 2. Ordem canônica e aritmética determinística

Na reconstrução, as fontes são percorridas em ordem canônica: `id_fonte` (texto do `StringName`, comparação lexicográfica) e, dentro da fonte, a ordem dos efeitos no `BoonDef`/`EffectDef`. Somas e produtos em ponto flutuante não são associativos; com ordem canônica, as 24 ordens de AC-06 produzem resultado **idêntico bit a bit**, não só dentro de 1e-6, e um valor que cai exatamente em x,5 arredonda igual em todas. Todo cálculo intermediário é `float`; nenhum `int()` nem arredondamento antes do fim. F1 é aplicada literalmente: `max(0, base + Σp) × max(0, 1 + Σ%) × Πm`, depois `clamp(piso, teto)` do `ModifiersTuning`, depois — só nos cinco atributos inteiros (`vida_max`, `escudo_sala`, `cargas_esquiva`, `recusas_morte`, `trocas_oferta`) — `arredondar_meio_longe_do_zero`. Essa função é própria (`f = floor(|x|)`; `+1` se `|x| − f ≥ 0,5`; reaplica o sinal), testada com 22,5→23, 22,4→22, −22,5→−23 e 0,49999999999999994→0; não se usa `floor(x + 0,5)` (erra no último caso) nem se presume a semântica de `round()`. Não há epsilon. Dano causado a inimigo fica `float`; F3 (dano recebido) é a única outra conversão a inteiro, feita por função pura deste módulo que o Combate chama.

### 3. Representação: fontes, modificadores, condições e tipos de efeito

- **Fonte** (`FonteDeModificador`, interna): `id` com prefixo de espécie — `bencao:<id>`, `oficina:<id>`, `status:abalo`, `elite`, `chefe`, `profundidade` — lista de `Modificador`, lista de `GatilhoAtivo`, `restante_passos` (−1 = permanente). Reaplicar a mesma fonte **substitui** valores e faz `restante = max(restante, nova)` (R6, AC-15, AC-17). Remover é idempotente e silencioso (AC-14). Oficina multinível é uma fonte com `valor × nível`.
- **Modificador** (imutável depois de criado): `atributo: StringName` da lista R2, `operacao` (`PLANO`, `PERCENTUAL`, `MULTIPLICADOR`), `valor: float` já escalado (F5), `condicao` (`NENHUMA`, `VIDA_ABAIXO`, `ENESIMO_ACERTO`, `APOS_ESQUIVA`), `param: float`, `slots` (máscara ataque/especial/selo; vazio = todos). Condição só em `dano_todo`; o construtor recusa o resto.
- **TabelaDeTiposDeEfeito**: a lista fechada das 21 chaves de `PlayerMods` (R5) como **esquema em código**, não tuning — tipo → espécie (atributo, atributo condicional, gatilho, atributo+gatilho), atributo, operação, condição, `slots`, executor. Os números (`limiar_vida` 0,5, `a_cada` 4, `janela_s` 1,5, `raio_px`…) vêm dos `params` do `EffectDef`. `recusas_morte` gera modificador **e** gatilho. AC-27 compara essa tabela com `tests/fixtures/modifiers/player_mods_canon.txt`.
- **AplicadorDeEfeitos**: função pura que transforma `(EffectDef[], raridade)` em uma `FonteDeModificador`, aplicando F5 (`escala_com_raridade`) ao `valor` e nunca aos `params` (R8). Bênçãos, Oficina e a IA (elite/chefe/profundidade) usam o mesmo aplicador. Atributo ou condição desconhecidos em fonte criada por código vão ao relator de erros e são ignorados (AC-28); no catálogo, o ADR-0004 rejeita antes da run.

### 4. Dano: `multiplicador_de_dano` e `DanoCongelado`

F2 é exposta em dois tempos para cumprir R12 sem duplicar fórmula. `congelar_dano(slot, ctx)` avalia no disparo `P_todo` (com `vida_abaixo` pela Vida do contexto), `P_slot`, Π incondicionais (elite × 1,25, Abalo × 0,7) e `apos_esquiva`, e devolve um `DanoCongelado` imutável com esse fator e, separadamente, o fator do 4º acerto e seu `a_cada`. `m_no_impacto(contador)` aplica o 4º acerto se `contador > 0` e múltiplo de `a_cada` e só então `min(M, teto_multiplicador_dano)` (AC-04b). `multiplicador_de_dano(slot, ctx)` é o atalho de um tempo só (Selo a cada passo, Corte da esquiva, golpe direto de inimigo). Inimigo usa slot `NENHUM` (só `P_todo` e multiplicadores). O projétil carrega o seu `DanoCongelado`, o que resolve AC-29 e AC-31 (Abalo lido no disparo) sem o projétil guardar referência ao portador.

### 5. Gatilhos: registro passivo e contrato por executor

Modificadores **registra** e **nunca executa**: não conhece Combate, Status, Selo nem Movimento e não chama ninguém quando um gatilho entra. `gatilhos(tipo)` devolve um `ResumoDeGatilho` cacheado: `total` (soma dos valores), `entradas` (valor, params, fonte, em ordem canônica) e `params` (iguais entre fontes por V11). O executor consulta no seu momento, pelo portador injetado:

| Tipo | Executor (dono do momento) | Lê |
|---|---|---|
| `refletir_dano`, `recusas_morte`, `explosao_ao_abater`, `cura_ao_abater` | Combate (ADR-0010) | `total` e `params` |
| `corte_da_esquiva` | Movimento detecta, Combate aplica (ADR-0008) | `total`, `params`; M por `multiplicador_de_dano(ATAQUE, ctx sem condicionais)` |
| `golpe_sangramento`, `golpe_queimadura` | Combate chama `status.aplicar_status(alvo_id, id, total)` | `total` |
| `selo_abala` | Selo pede a Status, que aplica a fonte do Abalo | `params.duracao_s` |

Assim R13 pertence aos executores e este ADR só garante o dado; nenhum módulo de regra recebe sinal do Godot (registro `sinal_do_godot_entre_modulos_de_regra`).

### 6. Quem escreve no portador e quem é avisado

- **Bênção escolhida:** Bênçãos chama `portador_do_jogador(player_id).aplicar_fonte(...)` antes de `bencao_tomada`/`bencao_escolhida` (AC-BN-09). Acontece no estado BENCAO, fora do passo; vale no golpe seguinte (Game Feel).
- **Elite, chefe, profundidade:** a IA, no spawn, antes do primeiro passo do inimigo.
- **Abalo:** Status é o **único relógio** do Abalo (Status R6: "este GDD só guarda a duração e a consulta"). Na borda `restante 0→>0`, Status aplica a fonte permanente `status:abalo` (multiplicador `1 − reducao_dano_causado`); na borda `>0→0`, remove. Reaplicação faz `max` no relógio do Status, e a fonte única garante × 0,7, nunca × 0,49. Não há dois contadores para dessincronizar.
- **Fim da run:** o portador do jogador é descartado e recriado em `nova_run` com base da arma + Oficina (R6, AC-16). Portador de inimigo some com o inimigo, sem aviso (AC-18).
- **Durações genéricas** (capacidade de R6/AC-17, sem uso no MVP de fábrica além de testes): `avancar(1)` é chamado uma vez por passo vivo pelo dono do combatente — Combate no início do item 3 para os `JogadorRef` (antes dos contadores da R2), IA no início do bloco de cada inimigo no item 7, antes de `status.tick(id)` (ordem completa no ADR-0010 §2) — e nunca em hitstop, pausa ou fora de JOGO. Expirar reconstrói o cache na mesma chamada.
- **Escudo e demais recursos (R9):** mudar Vida ou escudo atual **não** toca o cache. Mudar um atributo ligado a recurso faz o portador comparar, ao fim da reconstrução, os valores anteriores e novos de `vida_max`, `escudo_sala`, `cargas_esquiva`, `recusas_morte`, `trocas_oferta` e chamar, síncrono, o `OuvinteDeAtributos` injetado uma vez por atributo que mudou, em ordem fixa. O `Main` compõe um despachante: Combate aplica F4, escudo e recusas; Bênçãos, trocas. Movimento continua sincronizando o máximo de cargas no próprio passo (ADR-0008 §2, ordem 0), sem ouvinte. `trocas_oferta` tem base 0; o total é `trocas_iniciais` + valor (Bênçãos OQ 11).

### Architecture Diagram

```
Catálogo (EffectDef, RarityTable, ModifiersTuning)
        │ AplicadorDeEfeitos (F5)
Bênçãos ─┤ IA (elite/chefe/prof.) ─┤ Status (status:abalo)
        ▼
  Portador[player_id] / Portador de inimigo ── escrita → reconstrói cache ─┐
        │ valor / inteiro / congelar_dano / gatilhos (leitura O(1)/O(k))   │ OuvinteDeAtributos
        ▼                                                                  ▼
 Movimento · Combate · Selo · Status · IA · HUD(leitura)        Combate (Vida/escudo/recusas), Bênçãos (trocas)
```

### Key Interfaces

```gdscript
@abstract
class_name ConsultaDeAtributos extends RefCounted   # o que consumidores recebem por injeção
@abstract func valor(atributo: StringName) -> float          # atributos contínuos; dano_* é erro
@abstract func inteiro(atributo: StringName) -> int          # só os 5 inteiros (AC-05)
@abstract func congelar_dano(slot: int, ctx: ContextoDeDano) -> DanoCongelado
@abstract func multiplicador_de_dano(slot: int, ctx: ContextoDeDano) -> float   # já com teto
@abstract func gatilhos(tipo: StringName) -> ResumoDeGatilho
@abstract func fontes_de(atributo: StringName) -> Array[LinhaDeFonte]           # HUD/Tela: "de onde vem"

class_name Portador extends ConsultaDeAtributos
func aplicar_fonte(fonte: FonteDeModificador) -> void       # substitui se o id já existe
func remover_fonte(id_fonte: StringName) -> void            # idempotente
func avancar(passos: int) -> void                           # só em passo vivo
func duracao_restante(id_fonte: StringName) -> int          # passos que faltam à fonte; -1 se permanente; 0 se não existe (pedido do ADR-0017: Espelho da dupla no meio da run, R24)
# Ids de fonte (convenção): "vinculo:<curse_id>" (bônus do Vínculo), "especie:<id>:<passiva>", "espelho", "furia"

class_name ContextoDeDano extends RefCounted
var vida_atual: float; var apos_esquiva: bool               # o 4º acerto entra em m_no_impacto

class_name DanoCongelado extends RefCounted
func m_no_impacto(contador_acertos: int) -> float           # aplica 4º acerto e teto

@abstract
class_name OuvinteDeAtributos extends RefCounted
@abstract func atributo_mudou(id_combatente: int, player_id: int, atributo: StringName, antigo: int, novo: int) -> void

class_name FormulasDeModificadores extends RefCounted       # funções estáticas puras
static func arredondar_meio_longe_do_zero(x: float) -> int
static func dano_recebido(bruto: float, reducao: float, teto_red: float, guarda: float) -> int   # F3
# TR-bencaos-009: texto de carta e valor aplicado usam O MESMO arredondamento (137,5 -> 138).
static func formatar_numero_arredondado(x: float) -> String   # str(arredondar_meio_longe_do_zero(x)); sem round()/roundi()
```

**Formatação compartilhada (TR-bencaos-009).** O texto da carta de Bênção (Bênçãos R5; ADR-0012) mostra o número já arredondado pela regra do Modificadores. A Tela de bênção chama `FormulasDeModificadores.formatar_numero_arredondado(valor)` e não reimplementa arredondamento nem usa `round()`/`snappedf`/`%d` sobre float; o ADR-0012 só consome esta função. Mesma entrada, mesma saída que o valor aplicado (AC-BN-08: Rara 137,5 mostra 138).

Em 4.7, toda implementação concreta de método `@abstract` tipado **must** ter `return` explícito.

### Implementation Guidelines

- MUST reconstruir todos os agregados dentro de `aplicar_fonte`, `remover_fonte` e da expiração em `avancar`; MUST NEVER recalcular em leitura nem expor bandeira de sujo.
- MUST percorrer fontes em ordem canônica (`id_fonte`, depois ordem do efeito) e MUST NEVER depender da ordem de inserção ou de iteração de `Dictionary`.
- MUST manter tudo em `float` até o fim da F1/F2/F3; MUST arredondar só pela função própria e só nos 5 inteiros e em F3; MUST NEVER aplicar piso por efeito, epsilon ou `int()` intermediário.
- MUST aplicar `teto_multiplicador_dano` por último, depois do 4º acerto.
- MUST NEVER guardar Vida, escudo, cargas restantes, contador de acertos ou janela pós-esquiva no portador.
- MUST NEVER executar gatilho dentro de Modificadores nem chamar executor; executores leem `gatilhos()`.
- MUST NEVER mutar um `Modificador`, `DanoCongelado` ou `params` do catálogo depois de criado; reaplicação cria fonte nova.
- MUST manter o Abalo com um único relógio, no Status.
- MUST endereçar o portador do jogador por `player_id` (0 no solo), nunca por variável única global.
- MUST NEVER ler números de jogo literais: pisos, tetos e fatores vêm de `ModifiersTuning`/`StatusTuning`/`EffectDef`.

## Alternatives Considered

| Alternativa | Prós | Contras | Rejeição |
|---|---|---|---|
| Cálculo sob demanda a cada consulta | Zero estado derivado | Percorre todas as fontes a cada `valor()` (vários por passo × até dezenas de inimigos); ordem canônica teria de ser refeita sempre | Custo sem ganho; escritas são raras |
| Cache com bandeira de sujo e recálculo na próxima leitura | Escrita barata | Avisos de recurso (R9) precisam do antes/depois na escrita de qualquer forma; estado extra a testar | A reconstrução na escrita já é necessária para R9 |
| Inteiros ou ponto fixo em todo o cálculo | Determinismo entre plataformas | Diverge da paridade do cânone (167,5 → 168 só no fim); percentuais e 0,7 viram escalas arbitrárias | Paridade é requisito; host autoritativo dispensa bit a bit entre máquinas |
| Abalo como modificador com duração no Modificadores | Literal da R5 | Dois relógios (Status e Modificadores) que podem divergir em hitstop/item 7 | Status já é dono da duração |
| Gatilho como callback registrado pelo executor | "Empurra" a execução | Ordem dependeria da ordem de registro; acopla Modificadores aos executores | ADR-0002: reação por chamada direta do dono do momento |

## Consequences

Positivas: uma fórmula, um lugar, testável em memória com portadores falsos; leituras baratas; resultado idêntico em qualquer ordem de bênçãos; HUD obtém "de onde vem" pela mesma estrutura. Negativas: a reconstrução completa por escrita é O(fontes × efeitos) e cria arrays novos (aceitável pela raridade); duas consultas (`valor`/`inteiro`) em vez de uma assinatura `-> float` como em architecture.md API 5; Status passa a chamar `aplicar_fonte`/`remover_fonte` nas bordas do Abalo. Neutras: `refletir_dano` é lido como `gatilhos(&"refletir_dano").total`, não `valor(refletir_dano)` como escreve o Combate núcleo.

## Risks

- **Valores na borda x,5 por erro de representação** (ex.: percentuais como 0,05 × p): mitigado pela ordem canônica e pelo oráculo AC-32 (desvio ≤ 0,5 é o aceito); um caso divergente vira decisão de dado, não epsilon.
- **`float` não ser 64 bits** em algum build: verificado binary64 no build padrão 4.7.2 (2026-11-16); um build com outra precisão faria o teste AC-03/AC-05 falhar visivelmente.
- **Ouvinte reentrante** (Combate reage a `vida_max` e escreve no portador): proibido por guideline; debug `assert` contra escrita durante o aviso.
- **Momento de `avancar`**: alinhado com o ADR-0010 §2 na revisão cruzada de 2026-11-15 (item 3 para jogadores; 1º passo do bloco de cada inimigo no item 7); sem efeito no MVP.

## GDD Requirements Addressed

| GDD | Requisito | Como |
|---|---|---|
| modificadores-e-atributos.md | R1, R2, R3, AC-01/02 | `Portador` por combatente; recursos fora do cache |
| modificadores-e-atributos.md | R4, R12, F2, AC-07–11, AC-04b, AC-29 | `ContextoDeDano`, `DanoCongelado`, teto por último |
| modificadores-e-atributos.md | R5, AC-25–27 | `TabelaDeTiposDeEfeito` das 21 chaves; `ResumoDeGatilho` |
| modificadores-e-atributos.md | R6, R7, Edge Cases de fontes, AC-12–15, AC-17–18 | Reconstrução na escrita; substituição; `max` da duração; idempotência |
| modificadores-e-atributos.md | R8, F5, AC-19 | `AplicadorDeEfeitos` |
| modificadores-e-atributos.md | R9, F4, AC-16, AC-20–22 | `OuvinteDeAtributos` com antigo/novo; recriação na nova run |
| modificadores-e-atributos.md | R10, AC-23 | Fontes `elite`, `chefe`, `profundidade` aplicadas pela IA |
| modificadores-e-atributos.md | R11, R13, AC-30 | Consulta injetada; contrato por executor |
| modificadores-e-atributos.md | F1, F3, AC-03–06, AC-24 | Ordem canônica, `float` até o fim, arredondamento próprio, `dano_recebido` |
| modificadores-e-atributos.md | AC-32 (54 + 17 linhas) | Teste de tabela em `tests/integration/modifiers/` contra `paridade_canon.gd` |
| efeitos-de-status.md | R6, F4 | Abalo com relógio no Status, fonte única no portador |
| bencaos-tradicoes.md | R5, AC-BN-08/09, OQ 11 | Aplicação antes dos eventos; `trocas_oferta` só soma |
| bencaos-tradicoes.md | R5 (texto da carta) (TR-bencaos-009) | `formatar_numero_arredondado` em `FormulasDeModificadores`, usada pelo ADR-0012 |

## Performance Implications

- **CPU**: leitura O(1) (`valor`) ou O(k), k ≤ 3 condicionais (`congelar_dano`); escrita O(n) com n ≲ 40 efeitos no jogador, ~4 em inimigos. Sem orçamento próprio registrado; entra no orçamento do passo.
- **Memória**: alguns KB por portador; dezenas de portadores simultâneos.
- **Load Time**: nenhum (tabela de 21 tipos construída uma vez).
- **Network**: nenhum agora; no co-op o host calcula e só valores derivados chegam à Apresentação.

## Migration Plan

Sair da fatia: (1) implementar `Portador`, `FormulasDeModificadores`, `AplicadorDeEfeitos` e a tabela em `src/gameplay/modificadores/` com testes em `tests/unit/modifiers/`; (2) em `game_session.gd`, substituir `damage_multiplier` e `blessing_counts` pelo portador do jogador (`player_id` 0), trocando o `match` por id de bênção pela aplicação de `EffectDef` — isso corrige o empilhamento da mesma bênção (AC-15); (3) migrar `max_hp`/`charge_max` para `inteiro()` com o ouvinte; (4) portadores de inimigo no spawn. **Rollback**: o portador é isolado atrás de `ConsultaDeAtributos`; reverter é recolocar o campo antigo na fatia.

## Validation Criteria

Todos os AC-01–AC-31 como testes unitários com fábrica de portadores em memória (tolerância 1e-6, exceto AC-06, que exige igualdade exata entre as 24 ordens); AC-32 como teste de tabela integrado, bloqueado até existir o gerador `tools/canon-parity/` (OQ 5 do GDD); teste do arredondamento próprio nos quatro casos da §2; teste de que `teto_multiplicador_dano` 8 deixa 14,08 → 8; espião no ouvinte confirma avisos só nos cinco atributos ligados a recurso e zero avisos no descarte de inimigo.

## Nota de preparação para co-op

O jogador não é singleton aqui: `PortadoresDosJogadores` é um `Array[Portador]` indexado por `player_id`, Bênçãos aplica no `player_id` de quem escolheu e o ouvinte recebe `player_id`. Contador de acertos e janela pós-esquiva já são por jogador no Combate. Fica aberto quem dispara `cura_ao_abater`/`explosao_ao_abater` numa morte (co-op-ganchos: "atribuir o abate ao dono"), o que pede `autor_player_id` nos eventos de morte do ADR-0010 (campo já acrescentado ao `EvInimigoMorreu` na revisão cruzada de 2026-11-15; a regra de atribuição de Status e explosão continua pendente, item 1 abaixo). Nenhum código de rede.

## Decisões do usuário (resolvidas em 2026-11-15)

**O usuário aceitou todas as recomendações abaixo em 2026-11-15.** Elas valem como decisão deste ADR; o texto de cada item fica como registro das opções.

1. **Gatilhos de abate no co-op** (pós-MVP). Opções: (a) só o autor do abate dispara a sua explosão/cura; (b) todo jogador com o gatilho dispara em qualquer morte; (c) a explosão é do autor, a cura é de todos. **Recomendação: (a)**, que preserva o equilíbrio solo e é o que co-op-ganchos sugere; decidir antes de o co-op entrar.
2. **Texto do Combate núcleo e de architecture.md API 5.** O ADR lê `refletir_dano` por `gatilhos()` e divide `valor()` em `valor()`/`inteiro()`. Não muda número nem regra; **recomendação**: ajustar os textos na próxima edição desses documentos.

## Emenda (2026-11-16): Doutrina de Pactos

Conferido contra `modificadores-e-atributos.md` R14, F6 e `vinculo-e-pactos.md` (tabela de níveis):

- **Portador da Maldição**: um `Portador` por Maldição da dupla (dono do combatente: ADR-0017), com `vida_max` (piso `piso_vida_maldicao` 20), `velocidade`, `reducao_dano`, `raio` e `dano_todo` sem slot. Fontes novas: `especie:<id>:<passiva>` (passivas condicionais da espécie, ligadas e desligadas por código; `maldicoes.md` R22/R24), `vinculo:<curse_id>` (bônus de nível aplicado no começo da run) e `espelho` (propagação, abaixo). No **chefe**, a fonte `furia` (Fase 2: `mult_velocidade_furia` na velocidade e `fator_recarga_furia` nas recargas; `chefes.md` R7/F4) entra no portador do `InimigoRef` do chefe pela escrita normal. Nasce no começo da run (ou no meio, ao pactuar: mesma montagem e espelhos ativos nesse passo); Exaustão, reserva e troca de câmara não o mexem; é limpo no fim da run.
- **Propagação** (`tipos_propagados_maldicao` = [`dano_todo_pct`, `velocidade_pct`] **[a confirmar]**; `fator_propagacao_maldicao` 1,0): toda fonte do jogador com esses tipos gera no portador de cada Maldição uma fonte `espelho` com `valor × fator`, a mesma operação e a **duração restante** da fonte de origem; removida junto com ela. **Nenhum gatilho propaga** (golpe/abate são do jogador). O espelho é escrito pelo próprio Modificadores na mesma escrita que muda o portador do jogador (decisão 1: recálculo na escrita), sem evento intermediário.
- O dano da Maldição usa `dano_todo` do portador dela, no impacto, sem contar acerto; o pouso do Chamado usa o grupo Especial do jogador (`M_chamado`), congelado no disparo.
- **Vínculo nível 4**: `bonus_dano_basico` (MVP 0,05; faixa **0–0,07**, antes 0–0,12; **[a confirmar]** no GDD) multiplica só o ataque básico da Maldição (`× (1 + bonus_dano_basico)`). Entra como fonte `vinculo:<curse_id>`, não como espelho.

## Verificação de engine (2026-11-16)

Fonte: Completion Notes em `production/epics/experimentos-de-engine/` e `production/qa/evidence/experimentos/ex-0009-float64.md`. Editor 4.7.2 standard, Windows 11.

- **VERIFICADO:** `float` do GDScript é IEEE-754 binary64.
- **Critério corrigido:** o critério "2^53+1 distinto de 2^53" está errado, porque binary64 não representa 2^53+1 (arredonda para 2^53). Prova correta: `2.0**52 + 1.0 != 2.0**52` (inteiro exato abaixo de 2^53) **e** `2.0**53 + 1.0 == 2.0**53` (perda acima de 2^53), além de `0.1 + 0.2 != 0.3`. Um float de 32 bits falharia já no primeiro teste.
- **Cuidado:** literais numéricos acima de 2^53 escritos no código podem arredondar de forma diferente de `String.to_float()` sobre o mesmo texto. Testes e fixtures não devem comparar literais acima de 2^53 com valores lidos de texto; os valores de jogo deste ADR ficam muito abaixo disso.

## Related

- Depende de: ADR-0001, ADR-0002, ADR-0003, ADR-0004. Consumido por: ADR-0008 (Corte), ADR-0010 (dano, reflexo, recusa, abates), ADR-0012 (HUD lê `fontes_de`).
- GDDs: [Modificadores e atributos](../../design/gdd/modificadores-e-atributos.md), [Bênçãos](../../design/gdd/bencaos-tradicoes.md), [Efeitos de status](../../design/gdd/efeitos-de-status.md), [Combate núcleo](../../design/gdd/combate-nucleo.md), [Co-op ganchos](../../design/gdd/co-op-ganchos.md).
- Registro: `design/registry/entities.yaml` (`derived_value`, `hit_damage_multiplier`, `damage_taken`, `damage_reduction_cap`, `player_min_max_hp`).
- Código atual a migrar: `src/gameplay/game_session.gd`.
