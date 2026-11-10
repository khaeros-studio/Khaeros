# Conteúdo orientado a dados

> **Status**: Approved (2026-11-10: o empurrão do projétil da arma passa a ser o do `AttackDef` (Armas R2), com aval do usuário, sem mudar regra; 4ª re-review independente de 2026-11-06, lean: APPROVED; C-B1 e S-B1 do `/review-all-gdds` resolvidos; warnings da 2ª passada do cross-review aplicados em 2026-11-06 — AC-39 por token inteiro, params da `recusa`, retirada do Tuning ao sair de Pronto — com o status mantido por decisão do usuário)
> **Author**: usuário + Claude (design-system)
> **Last Updated**: 2026-11-06
> **Last Verified**: 2026-11-06
> **Implements Pillar**: P1 *Toda bênção é uma filosofia* (indireto: sustenta todos os pilares)
> **Creative Director Review (CD-GDD-ALIGN)**: pulada (modo Lean)

## Summary

**Conteúdo orientado a dados** é a camada onde vive todo valor e toda definição
de conteúdo do Khaeros:

- armas, inimigos e as 18 Tradições;
- regiões, ondas e portas;
- Oficina, economia e constantes de sensação.

Tudo fica em Resources `.tres` só de leitura, listados num manifesto, validados
por inteiro na inicialização e entregues aos sistemas por injeção de
dependência.

O jogador não vê este sistema. Ele é o que permite balancear por playtest sem
tocar em código, acrescentar conteúdo sem criar sistema novo e manter os nomes
canônicos protegidos pela Lore Freeze. Também define as fórmulas que convertem
os placeholders do cânone (ticks, unidade/tick) para segundos e px/s.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `Localização (suave, provisória)`

## Overview

**Conteúdo orientado a dados** é a camada onde fica todo valor e toda definição
de conteúdo do jogo: em Resources `.tres` do Godot, fora do código. Isso inclui:

- armas das Doutrinas e inimigos;
- regras de elite;
- as 18 bênçãos (Tradições);
- regiões e a sequência de câmaras;
- composição de ondas;
- pesos de portas e recompensas;
- melhorias da Oficina de Reforja;
- taxas da economia de Fragmentos;
- constantes de sensação do combate.

Cada definição é **só de leitura** e tem um **id estável** em snake_case ASCII
(Art Bible §8.2). Os nomes exibidos são sempre os canônicos do repo Khaeros. Ao
iniciar, o jogo monta um **catálogo de conteúdo** e **valida** cada definição
antes da primeira câmara: campos obrigatórios, faixas permitidas, referências
entre ids e nomes canônicos. Os sistemas recebem o catálogo, ou só a parte que
usam, por **injeção de dependência**. Nenhum sistema lê arquivo ou singleton
global por conta própria.

O jogador não vê este sistema; sente o que ele permite:

- balancear por playtest sem mexer em código;
- acrescentar uma arma, um inimigo ou uma região sem criar sistema novo;
- runs reproduzíveis, porque toda variação nasce de dados fixos mais o RNG com
  seed.

Sem esta camada, cada bênção vira código especial, os números do cânone se
espalham em constantes (como no `engine.ts` do modo web) e os testes não
conseguem injetar conteúdo de teste.

> **→ vira ADR:** o mecanismo de injeção (Autoload só de leitura, nó raiz da
> cena, objeto `RefCounted` passado adiante) é decisão de arquitetura, não deste
> GDD.

## Detailed Design

### Core Rules

> `systems-designer`, `gameplay-programmer` e `engine-programmer` não foram
> consultados: modo Lean. Revisar manualmente antes de produção.

**R1. Tipos de definição.** Este GDD é dono do **formato** de cada tipo: id,
campos, unidades e validação. O **significado** dos campos e os **valores**
pertencem ao sistema dono, que pode acrescentar campos no próprio GDD. Os
valores iniciais vêm do cânone e são todos placeholders.

| Tipo | Uma definição por | Campos principais | Dono do significado | Fonte inicial (só leitura) | Conteúdo no MVP |
|---|---|---|---|---|---|
| `WeaponDef` | arma de Doutrina | id, doutrina, chave de nome, Vida máx., velocidade, `ataque`, `especial` | Armas das Doutrinas | `ARENA_WEAPONS` | `lamina`, `ressonancia` |
| `AttackDef` (sub-recurso) | Ataque ou Especial | chave de nome, forma (`arco` / `circulo` / `projetil` / `avanco` + parâmetros), dano, recarga, empurrão, status opcional, multiplicadores de combo | Combate núcleo | `ARENA_WEAPONS.*.attack/special` | 4 |
| `EnemyDef` | inimigo ou chefe | id, chave de nome, comportamento, Vida, velocidade, raio, dano, alcance, preparo, recarga, velocidade do projétil, custo de onda | IA de inimigos e elites (comportamento `chefe`: Chefes, fatia vertical) | `ARENA_ENEMIES` | 3 do Limiar + o chefe `anomalia_maior` (só como dado, com o comportamento `chefe` reservado, R8; ver `RegionDef`) |
| `EliteRules` (único) | o jogo | multiplicadores de Vida, dano, raio e resistência a empurrão; profundidade mínima; curva de chance | IA de inimigos e elites | `engine.ts` `ELITE_*` | 1 |
| `BoonDef` | Tradição | id canônico `trad_*`, doutrina, chave de nome, chave de descrição, `efeitos[]` | Bênçãos (Tradições) | `traditions.ts` + `BOON_EFFECTS` | as 18 (escopo fechado no GDD de Bênçãos) |
| `EffectDef` (sub-recurso) | efeito de bênção ou de melhoria | tipo de efeito registrado, `valor`, `escala_com_raridade`, `params` (constantes nomeadas) | Modificadores e atributos | `BoonEffect` + constantes de `engine.ts` | — |
| `RarityTable` (único) | o jogo | Comum / Rara / Épica: escala e peso de sorteio | Bênçãos (Tradições) | `RARITY_SCALE` | 1 |
| `RegionDef` | região | id, chave de nome, sequência de câmaras (tipos de sala, R2/R8), pool de inimigos (onde cada inimigo aparece; o `EnemyDef` não guarda região), chefe (opcional), Fragmentos do chefe | Run e regiões | `ARENA_REGIONS` | `limiar`, com o chefe do cânone no dado; no MVP a Run não leva à câmara do chefe (GDD de Run e regiões) |
| `WaveRules` (único) | o jogo | parâmetros do orçamento de onda, ondas por profundidade, teto de inimigos, multiplicador da Provação | Câmaras e ondas | `engine.ts` `buildWaves` | 1 |
| `RewardTable` (único) | o jogo | pesos das portas por tipo de recompensa (R2/R8), profundidade mínima da Provação, cura da porta, cura do Santuário, Fragmentos por porta | Portas e recompensas | `engine.ts` | 1 |
| `EconomyRates` (único) | o jogo | Fragmentos de vitória e de Provação | Economia de Fragmentos | `victoryFragments`, `TRIAL_FRAGMENTS` | 1 |
| `UpgradeDef` | melhoria da Oficina | id, chave de nome, custos por nível, `efeitos[]` | Oficina de Reforja | `ARENA_UPGRADES` | fatia vertical |
| `*Tuning` (um por sistema) | sistema | constantes de sensação e regra: esquiva, hitstop (`CombatTuning`), Fluxo, Selo, status, entrada (`InputTuning`: buffer, zonas mortas), câmera (`CameraTuning`), modificadores (`ModifiersTuning`: pisos, tetos, `fator_empurrao_chefe`; GDD de Modificadores) | o sistema que dá nome ao Tuning | `engine.ts` (as ~40 constantes) | um por sistema MVP que tiver constantes |

**`EffectDef` por dentro.**

- `valor` é o número que o jogador lê, antes da raridade. É o único campo que
  escala: o dono usa `valor × escala` quando `escala_com_raridade = true`.
- `params` guarda constantes nomeadas (`Dictionary` de `StringName` para
  `float`) que nunca escalam com a raridade. Cada tipo de efeito registrado (R8)
  declara quais params exige e a faixa de cada um, e V1/V2 conferem. Quem dá os
  nomes é o dono do tipo de efeito (Modificadores), conforme R1.
- Quando o código do cânone multiplica o `value` por uma constante
  (`10 * mods.dashDamage`), a importação multiplica essa constante para dentro
  do `valor`: Corte Fantasma grava `valor = 10`, não 1. A troca é exata porque,
  no cânone, esses efeitos são lineares (o `value` é somado e multiplicado uma
  vez). As constantes que não escalam viram `params`. A lista completa fica em
  Edge Cases › Constantes escondidas no código do cânone.

**R2. Identidade.** Todo id segue estas regras:

- snake_case ASCII e único dentro do seu tipo;
- **nunca é renomeado nem reaproveitado** depois do primeiro commit, porque save
  e telemetria guardam ids. `assets/data/canon/ids_registrados.csv` (tipo, id)
  guarda todo id já publicado, e a checagem V9 garante a regra;
- os tokens seguem o Art Bible §8.2: doutrinas `lamina`, `ressonancia`,
  `guardiao`, `veu`, `transmutacao`, `pactos`; regiões `limiar`, `veio`;
  inimigos `eco_perdido`, `anomalia_menor` etc.; chefes `anomalia_maior`,
  `guardiao_rito`;
- **mapa cânone → Godot.** O cânone usa outros ids para doutrinas e armas
  (`BLADE`, `RESONANCE`…), regiões (`BEIRA_LIMIAR`, `BEIRA_VEIO_INSTAVEL`) e
  chefes (`boss_anomalia_maior`, `boss_guardiao_rito`). A única ponte é
  `assets/data/canon/mapa_ids.csv`, com as colunas `tipo,id_canon,id_godot`:

  | tipo | id_canon | id_godot |
  |---|---|---|
  | doutrina e arma | `BLADE`, `RESONANCE`, `GUARDIAN`, `VEIL`, `TRANSMUTATION`, `PACTS` | `lamina`, `ressonancia`, `guardiao`, `veu`, `transmutacao`, `pactos` |
  | região | `BEIRA_LIMIAR`, `BEIRA_VEIO_INSTAVEL` | `limiar`, `veio` |
  | chefe | `boss_anomalia_maior`, `boss_guardiao_rito` | `anomalia_maior`, `guardiao_rito` |
  | inimigo, melhoria | iguais (`eco_perdido` → `eco_perdido`) | a linha existe mesmo quando o id é igual |
  | tipo de efeito | `dashDamage`, `attackDmg`… | `corte_da_esquiva`, `dano_ataque_pct`… (nomes finais na R5 do GDD de Modificadores) |
  | comportamento de inimigo | `melee`, `ranged`, `charger`, `boss` | `corpo_a_corpo`, `distancia`, `arremetida`, `chefe` |
  | forma de ataque | `arc`, `circle`, `projectile`, `lunge` | `arco`, `circulo`, `projetil`, `avanco` |
  | status | `bleed`, `burn`, `weak` | `sangramento`, `queimadura`, `abalo` |
  | tipo de sala | `combat`, `sanctuary`, `boss` | `combate`, `santuario`, `chefe` |
  | tipo de recompensa | `boon`, `fragments`, `heal`, `trial` | `bencao`, `fragmentos`, `cura`, `provacao` |

  Comportamentos, formas, status, tipos de sala e tipos de recompensa são tokens
  de dado e ficam em português (decisão do usuário, 2026-11-06). O `chefe` de
  sala e o `chefe` de comportamento são tipos diferentes, então não colidem
  (unicidade dentro do tipo, como `lamina` arma e doutrina). Os tokens de ação do Art Bible §8.2 são
  nomes de animação e continuam em inglês. `avanco` e `arremetida` evitam os
  nomes canônicos dos golpes: a "Investida" da Lâmina tem forma `avanco`, e a
  "Estocada" do Véu tem forma `arco`.

  Três coisas usam o mapa:

  - o script de importação, que troca o id e toda referência a ele
    (`doctrine`, `enemyPool`, `bossId`, `mod`, `behavior`, `shape.kind`,
    `status.id`, `rooms` e as chaves dos pesos de porta da `RewardTable`, que
    no cânone são a pool literal de `engine.ts:400–410`);
  - o teste de paridade AC-34, que casa cada registro da fixture com o `.tres`
    correspondente;
  - a V5, que traduz a doutrina canônica antes de comparar.

  Um id canônico sem linha no mapa faz a importação falhar. O jogo em execução
  nunca lê o mapa. Uma linha nunca muda depois do primeiro commit, pela mesma
  regra dos ids;
- os dados guardam **só** tokens Godot: `BoonDef.doutrina` vale `lamina`, igual
  ao `WeaponDef.id`, e filtrar as bênçãos de uma arma não precisa do mapa;
- as bênçãos mantêm **exatamente** os ids canônicos de `traditions.ts`
  (`trad_blade_traco_unico` etc.). Os `trad_*` não passam pelo mapa.

**R3. Definição é só de leitura.** Nada escreve numa definição em tempo de
execução. O estado (Vida atual, bênçãos pegas, nível da Oficina) vive no sistema
dono. O que altera um valor base é uma camada de Modificadores, nunca a
definição. Se um sistema precisar de uma cópia mutável, usa `duplicate_deep()`,
e a cópia nunca volta ao catálogo. Isso evita o vazamento pelo cache do
`ResourceLoader`.

**R4. Manifesto.** Um único `content_catalog.tres` lista explicitamente cada
definição, por tipo, e só o que está nele existe no jogo. Não há varredura de
pastas em tempo de execução. Um teste (editor/CI) varre `assets/data/` e acusa
arquivo **órfão**, ou seja, que está na pasta mas não no manifesto.

**R5. Onde ficam os arquivos.**

- definições: `assets/data/[tipo]/[id].tres`;
- manifesto: `assets/data/content_catalog.tres`;
- lista canônica, mapa de ids e registro de ids: `assets/data/canon/` (CSV).
  Todo `.csv` dessa pasta usa o importador `keep` (arquivo `.import` com
  `importer="keep"`). Sem isso, o Godot 4.7.2 importa o CSV como tradução: no
  teste de 2026-11-05, `ids_registrados.csv` virou uma Translation do idioma
  `id`. A pasta fica fora do export (filtro de exclusão `assets/data/canon/*`),
  porque só a importação, a V5 e a V9 a leem;
- scripts das classes de definição: `src/content/`;
- arte referenciada por uma definição (ícone, retrato): só de
  `assets/art/export/` (Art Bible §8.8).

**R6. Unidades.** Os dados usam unidades do Godot:

- tempo em **segundos**;
- distância e raio em **px de mundo** (viewport lógico 1920×1080; 1 unidade do
  cânone = 1,5 px);
- velocidade em **px/s**, inclusive o **empurrão**: no cânone ele é uma velocidade
  inicial (unidade/tick) e por isso converte pela F2;
- percentuais como fração (0,25 = 25%);
- multiplicadores como fator (2,4 = ×2,4).

Os valores do cânone (ticks, unidade/tick) são convertidos **uma vez** na
importação, pelas fórmulas da seção Formulas.

**R7. Textos.** A definição guarda **chaves de tradução**, nunca o texto. O
texto PT-BR canônico vive na tabela de tradução. O texto nunca repete um número
que existe no dado: no lugar dele vai um marcador, que o sistema dono preenche.

- A forma é `{campo}` ou `{campo:formato}`. O `campo` é `valor` ou o nome de um
  `params` do `EffectDef`.
- Numa definição com mais de um efeito, o marcador leva o tipo:
  `{vida_max_plano.valor:int}`. O tipo de efeito é único dentro de uma definição (V3).
- `{status.<id>.<campo>}` aponta para um campo do `StatusTuning`. Exemplo: o
  −30% do Abalo, que é do status e não da bênção.
- Os formatos formam uma lista fechada deste GDD:
  - `int`: inteiro arredondado;
  - `pct`: ×100, inteiro, com `%`;
  - `num`: inteiro, ou 1 casa se for fracionário. Sem formato, vale `num`.
- `valor` sai já escalado pela raridade; `params` nunca escalam.
- O número exibido é sempre o valor absoluto, e o sinal fica no texto: "Custa
  {vida_max_plano.valor:int} de Vida máxima", com `valor = -10`.

A checagem V10 garante a regra.

**R8. Comportamentos registrados.** O dado só pode apontar para comportamentos
que o código registrou numa lista fechada, mantida pelo sistema dono:

- tipos de efeito: Modificadores;
- comportamentos de inimigo: IA;
- formas de ataque: Combate núcleo;
- status: Efeitos de status;
- tipos de sala: Câmaras e ondas;
- tipos de recompensa: Portas e recompensas.

Um comportamento novo exige código e a atualização do GDD dono; um valor novo,
não.

Uma chave pode entrar na lista como **reservada**: o dono a registra antes de
ter o código. A V4 aceita uma chave reservada no dado. Pedir em jogo um
comportamento reservado (criar um inimigo com ele, por exemplo) é erro, que o
sistema dono entrega ao relator (R10). No MVP, a IA registra `chefe` como
reservada, para o `EnemyDef anomalia_maior` validar. O GDD de Chefes (fatia
vertical) implementa o comportamento e tira a marca de reservada. Pelo mesmo
motivo, Câmaras e ondas registra o tipo de sala `chefe` como reservado no MVP,
para a `RegionDef limiar` validar.

**R9. Carga e validação.** Acontecem uma vez, na inicialização, antes do menu.
A validação **coleta todos os erros**; se houver pelo menos um, nenhuma run
começa e o jogo mostra a lista. A regra de bloquear é a mesma em debug e em
release. V5 e V9 são a exceção: protegem o commit, não o jogador, e rodam só no
CI e em debug, porque `canon/` não vai para o export (R5). O mesmo validador
roda como teste automatizado no CI. As checagens são:

| # | Checagem | Exemplo de erro |
|---|---|---|
| V1 | Campo obrigatório presente e do tipo certo | `EnemyDef eco_perdido: dano ausente` |
| V2 | Valor dentro da faixa declarada pelo tipo, e regras entre campos da classe | `AttackDef lamina.ataque: recarga 0 (mín. > 0)` / `LinearCurveDef elite: y_floor 0,3 > y_cap 0,25` |
| V3 | Id único dentro do tipo e no formato de R2, e tipo de efeito único dentro de uma definição | `BoonDef: id duplicado trad_veil_penumbra` |
| V4 | Toda referência por id resolve (pool de inimigos, chefe, status, tipo de efeito, comportamento, forma, tipo de sala, tipo de recompensa); uma chave reservada (R8) resolve | `RegionDef limiar: inimigo fenda_erante não existe` |
| V5 | Cânone (só CI e debug): os ids e as doutrinas das Tradições batem com `assets/data/canon/` (a doutrina canônica passa pelo mapa de R2 antes de comparar), e o texto PT-BR da chave de nome de **toda** definição com nome canônico (Tradições, armas e seus Ataque/Especial, inimigos, chefes, regiões, melhorias) é o nome canônico | `BoonDef trad_blade_traco_unico: nome "Traço Único" ≠ canônico "O Traço Único"` / `WeaponDef pactos: nome "Laço dos Pactos" ≠ canônico "Besta do Vínculo"` |
| V6 | Toda chave de tradução existe na tabela PT-BR | `WeaponDef lamina: chave WEAPON_LAMINA_NAME sem texto` |
| V7 | Toda arte referenciada existe, conferido por `ResourceLoader.exists`, **e** está dentro de `assets/art/export/`. `FileAccess.file_exists` não serve, porque a imagem de origem não vai para o export, só a importada | `BoonDef …: ícone não encontrado` / `…: ícone fora de assets/art/export/` |
| V8 | Tabelas de peso: pesos ≥ 0 e soma > 0 | `RewardTable: todos os pesos 0` |
| V9 | Registro de ids (só CI e debug): todo id de `assets/data/canon/ids_registrados.csv` continua existindo no mesmo tipo (pode estar `obsoleto`), **e** todo id do manifesto tem linha no registro | `enemy eco_perdido: id registrado sumiu do catálogo` / `enemy eco_do_veio: id sem linha em ids_registrados.csv` |
| V10 | Descrições não têm dígitos fora de `{…}`; todo marcador resolve (R7) para `valor`, para um `params` de um `EffectDef` da definição ou para um campo do `StatusTuning`; formato fora da lista é erro | `BoonDef …: descrição com número literal "12"` / `BoonDef trad_resonance_linha_contada: {a_cada} não é params do efeito dano_enesimo_acerto` |
| V11 | Entre definições: todos os `EffectDef` do mesmo tipo de efeito (de bênçãos ou de melhorias) têm os mesmos `params`, porque os valores de fontes diferentes somam e os params têm de ser iguais (Modificadores, Edge Cases) | `recusas_morte: params.vida_ao_voltar 0,4 em BoonDef trad_pacts_os_que_ficam ≠ 0,5 em UpgradeDef …` |

Cada erro informa arquivo, campo, regra e valor encontrado.

**Quem escreve no registro (V9).** O script de importação acrescenta (tipo, id)
de todo id que grava, no mesmo commit dos `.tres`. Quem cria conteúdo à mão
acrescenta a linha no mesmo commit. Ninguém apaga nem edita uma linha: o CI
compara o registro com o do branch principal, e uma linha removida ou alterada
é erro V9.

**Regras por campo.** Cada classe de definição declara uma **tabela estática
de regras por campo**: obrigatório, mínimo, máximo e aceita zero. Ao lado
dela, a classe declara uma **lista fixa de regras entre campos**, como
`y_floor ≤ y_cap` no `LinearCurveDef` (F8). V1 e V2 leem só essas duas
declarações. Uma regra entre campos violada sai como erro V2, citando os dois
campos e os dois valores. Os GDDs donos fornecem os números de cada faixa e as
regras entre campos do seu tipo.

**R10. Consulta.** Cada sistema recebe na construção o catálogo, ou só a parte
que usa (por exemplo, a IA recebe `EnemyDef` + `EliteRules`), por **injeção de
dependência**. As operações são três:

- obter por tipo e id: um id ausente é **erro**, nunca `null` silencioso. A
  consulta devolve `null` e entrega a entrada (tipo, id, quem pediu) ao
  **relator de erros injetado**. Ela mesma não chama `push_error` nem `assert`:
  quem reage é o relator.
  - O **relator padrão** do jogo grava no log e chama `push_error`. Se o build
    for debug e o parâmetro injetado `parar_em_debug` for `true` (o padrão no
    jogo), ele também para com `assert`.
  - O **relator falso** dos testes só guarda a entrada numa lista, sem
    `push_error` nem `assert`. Assim o AC-21 verifica o `null` e a entrada sem
    que o gdUnit4 seja interrompido.
  - O relator padrão é testado com `parar_em_debug = false` e um log falso
    (AC-43). Nesse teste, o `push_error` vai só para o console e não é
    verificado: o que se verifica é a linha no log falso.

  Uma consulta "existe?" responde sem registrar erro. Obter por id sempre
  resolve, mesmo uma definição `obsoleto = true`;
- listar um tipo;
- filtrar (por exemplo, bênçãos de uma Doutrina).

Listar e filtrar **excluem** `obsoleto = true` por padrão; incluir os
obsoletos exige um parâmetro explícito.

As listas saem **sempre na ordem do manifesto**, nunca na ordem de hash. Isso é
necessário para o RNG com seed reproduzir a run. Nenhum sistema além do
carregador abre caminho `.tres`. Os testes montam catálogos em memória com
fábricas de dados de teste.

**R11. Lista canônica.** `assets/data/canon/` guarda a cópia das 18 Tradições
(id, doutrina, nome), dos nomes de inimigos, chefes e regiões, das armas e das
melhorias, tirada **só de leitura** do repo Khaeros. Mudar essa lista é mudar o
cânone: precisa de aprovação do CD (Lore Freeze). Para a arma de Pactos, a lista
guarda a adaptação aprovada em 2026-11-05 (Besta do Vínculo, com os nomes do
`game-concept.md`), e não o "Laço dos Pactos" do modo web.

**R12. Impressão do catálogo.** Ao fim de toda carga com 0 erros (na
inicialização e em cada recarga em debug), o carregador calcula uma **impressão
digital** do conteúdo. O RNG com seed a usa no contrato de reprodução (RNG R7) e
no texto da seed (RNG R8, o campo `c____`).

- **Entrada:** uma serialização canônica de todas as definições do manifesto,
  na ordem do manifesto (R10). Para cada definição entram o tipo, o id e cada
  campo, em ordem alfabética do nome do campo. Um sub-recurso entra no lugar do
  seu campo, pelas mesmas regras. Um `Dictionary` (os `params`) entra com as
  chaves em ordem alfabética, e um array, na ordem gravada.
- **Bytes de cada valor:** float pelos 8 bytes IEEE-754 (float64), com −0,0
  gravado como 0,0; int pelos 8 bytes; bool como 1 byte; texto (`String`,
  `StringName`, caminhos de arte, chaves de tradução) em UTF-8, precedido do
  comprimento.
- **O que não entra:** os textos traduzidos (só as chaves entram) e
  `assets/data/canon/`, que não vai para o export (R5).
- **Algoritmo:** SHA-256 (`HashingContext`, `HASH_SHA256`) sobre essa sequência
  de bytes.
- **Saída:** a consulta (R10) devolve as duas formas. A **curta** são os 4
  primeiros hex em maiúsculas (`1B4E`), para a tela. A **completa** são os 64
  hex, para a telemetria e o relatório de erro. Quem grava cada uma é o dono
  delas (RNG, Telemetria).
- **Garantia:** o mesmo conteúdo dá a mesma impressão em debug e em release, em
  qualquer máquina. Qualquer valor diferente muda a completa. Uma colisão na
  curta (1 em 65.536) é aceita, porque ela só serve para leitura humana.

**Provisório** (os sistemas donos ainda não têm GDD):

- os campos exatos de cada tipo podem crescer quando o GDD dono for escrito;
- a Localização é da fatia vertical, mas as chaves já nascem no MVP. Até a
  tabela de tradução existir de verdade, um CSV PT-BR simples serve. Esse CSV
  é importado como tradução, que é o que ele é. A V6 confere as chaves pela
  tradução importada, não lendo o CSV, e por isso funciona no release.

### States and Transitions

| Estado | Significado | Entra quando | Sai para |
|---|---|---|---|
| Não carregado | Nenhum dado em memória | O jogo abre | Carregando |
| Carregando | Lendo o manifesto e cada definição | A inicialização começa | Validando, ou Falhou **ao fim da leitura** (manifesto ilegível, arquivo ausente ou ilegível; todos os erros juntos) |
| Validando | V1–V11 rodando, coletando erros | Tudo lido | Pronto (0 erros) ou Falhou (≥ 1 erro) |
| Pronto | Catálogo só de leitura disponível para injeção | 0 erros | Carregando, só por recarga em debug **entre runs** (o carregador recebe por injeção o estado de run e só recarrega com "fora de run") |
| Falhou | Tela com a lista de erros; nenhuma run pode começar | ≥ 1 erro | Fim (o jogador fecha o jogo; em debug, recarga volta a Carregando) |

Não há transição durante a run: o catálogo nunca muda no meio de uma run.

### Interactions with Other Systems

| Sistema | O que recebe daqui | O que fornece para cá | Dono da interface |
|---|---|---|---|
| Modificadores e atributos | `EffectDef` (de bênçãos e melhorias), `ModifiersTuning` | lista registrada de tipos de efeito (V4); params iguais entre fontes do mesmo tipo (V11) | este GDD (formato), Modificadores (semântica) |
| Movimento e esquiva | `MovementTuning`, velocidade da `WeaponDef` | — | Movimento |
| Combate núcleo | `AttackDef`, `CombatTuning` (hitstop, cambaleio, impacto na parede, queda do empurrão) | formas de ataque registradas | Combate |
| Input e controle | `InputTuning` (buffer, zonas mortas, raio da mira, limiares); regra entre campos `zm + ze < 1` (V2); re-injeção a cada entrada em Pronto; retirada (injeção vazia) ao sair de Pronto, então em Falhou o Input fica só digital | — | Input |
| Cena 3/4 e câmera | `CameraTuning`, re-injetado a cada entrada em Pronto e retirado ao sair de Pronto; `unit_to_px` (constante deste GDD, aplicada só na importação, F4) | — | Cena 3/4 (`CameraTuning`), este GDD (`unit_to_px`) |
| Armas das Doutrinas | `WeaponDef` | — | Armas |
| Selo e Fluxo | `SealTuning` | — | Selo |
| Efeitos de status | `StatusTuning` (Sangramento, Queimadura, Abalo) | ids de status registrados | Status |
| IA de inimigos e elites | `EnemyDef`, `EliteRules` | comportamentos registrados (no MVP, `chefe` como reservado, R8) | IA |
| Chefes (fatia vertical) | `EnemyDef` com comportamento `chefe`, Fragmentos do chefe na `RegionDef` | o código de `chefe`, que deixa de ser reservado | Chefes |
| Câmaras e ondas | `WaveRules`, pool de inimigos e sequência de câmaras da `RegionDef` | tipos de sala registrados (no MVP, `chefe` como reservado, R8) | Câmaras |
| Portas e recompensas | `RewardTable` | tipos de recompensa registrados | Portas |
| Run e regiões | `RegionDef` | — | Run |
| Bênçãos (Tradições) | `BoonDef`, `RarityTable` | — | Bênçãos |
| Economia de Fragmentos | `EconomyRates`, Fragmentos do chefe na `RegionDef` | — | Economia |
| Oficina de Reforja (fatia vertical) | `UpgradeDef` | — | Oficina |
| RNG com seed | listas em ordem estável (R10); impressão do catálogo, curta e completa (R12) | — | este GDD |
| Save e perfil (fatia vertical) | conjunto de ids válidos, para conferir o save ao carregar | — | Save |
| Localização (fatia vertical) | lista de chaves usadas (V6) | tabela PT-BR | Localização |
| Telemetria local | ids estáveis para registrar escolhas e mortes | — | Telemetria |
| HUD / Tela de bênção | chaves de texto e arte das definições | — | UI |

Este GDD é dono do contrato **R1–R12** e das fórmulas de conversão de unidades.
Cada GDD consumidor é dono do significado e dos valores dos seus campos.

## Formulas

> Proposta do `systems-designer` (consultado: modo Lean, seção de risco alto);
> escolhas de arco, projétil e curva decididas pelo usuário em 2026-11-05.

Constantes globais (dadas, não de balanceamento):

- `TICK_RATE = 60`: passos de física por segundo. Igual ao cânone (60 ticks/s,
  baseline §54) e ao padrão do Godot. Na carga, o validador confere se
  `physics_ticks_per_second` vale 60.
- `UNIT_TO_PX = 1,5`: o viewport lógico é 1920×1080 (Art Bible §8.6), então a
  arena canônica de 1280×720 vira exatamente uma tela. Mudou de 1,0 para 1,5 em
  2026-11-05 (GDD Cena 3/4 e câmera); a fórmula já previa essa edição única.

F1 a F6 rodam **uma vez, na importação** dos valores do cânone. F7 roda no
jogo, toda vez que uma duração vira passos. F8 é a curva padrão que os GDDs
donos reutilizam.

**Importação.** É um script em `tools/content-import/` que lê o cânone (só
leitura) e grava os `.tres` aplicando F1–F6. Um **teste de paridade** compara
uma fixture com os valores brutos do cânone contra os valores gravados.

### F1. Ticks → segundos

The tick_to_seconds formula is defined as:

`t_s = ticks / TICK_RATE`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| ticks | int | ≥ 0 | cânone (`*Ticks`) | recarga, preparo, guarda etc. |
| TICK_RATE | int | 60 | constant | passos/s |
| t_s | float | ≥ 0 | calculated | duração gravada no `.tres` |

**Output Range:** ≥ 0, sem limite. Grava-se o float64 de `ticks / 60` sem
arredondar (16/60, não 0,2667). Os exemplos com 4 casas são só para leitura.
**Example:** recarga do Corte da Lâmina, 16 ticks → 0,2667 s. Preparo do Eco
Perdido, 26 ticks → 0,4333 s.

### F2. Velocidade: unidade/tick → px/s

The speed_to_pxs formula is defined as:

`v_pxs = v_upt × TICK_RATE × UNIT_TO_PX`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| v_upt | float | 0–22 | cânone | `speed`, `moveSpeed`, `projectileSpeed`, `knockback`, `WALL_SLAM_SPEED` |
| UNIT_TO_PX | float | 1,5 | constant | escala unidade → px |
| v_pxs | float | 0–1980 | calculated | valor gravado |

**Output Range:** ≥ 0, sem limite. O **empurrão** também passa por aqui: é a
velocidade inicial do corpo empurrado. A cada passo o corpo anda `v_pxs / 60` px
e a velocidade cai × 0,78, fator **por passo** guardado no `CombatTuning` (vale
porque o passo é fixo em 60/s). Assim o deslocamento total é o do cânone × 1,5.
**Example:** Eco Perdido 1,7 → 153 px/s. Lâmina do Juramento (`moveSpeed` 4,3)
→ 387 px/s. Pulso 11 → 990 px/s. Empurrão do Corte (`knockback` 5) → 450 px/s.
Limiar do impacto na parede (`WALL_SLAM_SPEED` 7) → 630 px/s.

### F3. Taxa por tick → taxa por segundo

The rate_to_per_second formula is defined as:

`r_s = r_tick × TICK_RATE`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| r_tick | float | ≥ 0 | cânone | `FLUX_REGEN_PER_TICK`, `*_DPT`, `SEAL_DAMAGE_PER_TICK` |
| r_s | float | ≥ 0 | calculated | Vida/s ou Fluxo/s, conforme o campo |

**Output Range:** ≥ 0, sem limite. O nome do campo diz a unidade (Vida ou
Fluxo) e se é por acúmulo.
**Example:** Fluxo 0,06 → 3,6/s. Selo 0,12 → 7,2/s. Sangramento 0,04 → 2,4/s
por acúmulo. Queimadura 0,08 → 4,8/s por acúmulo.

### F4. Distância: unidade → px

The unit_to_px formula is defined as:

`d_px = d_u × UNIT_TO_PX`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| d_u | float | 0–1280 | cânone | `range`, `radius`, `distance`, `offset` |
| d_px | float | 0–1920 | calculated | valor gravado |

**Output Range:** ≥ 0. Exige escala uniforme (1280/largura = 720/altura); se
não for, a importação é inválida.
**Example:** alcance do Corte 95 → 142,5 px. Raio da Onda de Ressonância 130 →
195 px.

### F5. Arco: `dot` → meio-ângulo em graus

The arc_half_angle formula is defined as:

`θ_deg = rad_to_deg(acos(dot))`

Em jogo, o cosseno é calculado uma vez na carga,
`cos_meio = cos(deg_to_rad(θ_deg))`, e o golpe acerta quando
`cos(ângulo até a mira) ≥ cos_meio`.

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| dot | float | −1–1 | cânone | limiar de cosseno da forma `arc` do cânone (`arco` no Godot) |
| θ_deg | float | 5–180 | data file | meio-ângulo; arco total = 2·θ |

**Output Range:** 5° a 180°. 180° é um círculo; abaixo de 5° é erro de
validação (arco degenerado). Gravado com 2 casas decimais (erro < 0,0001 no
`dot`).
**Example:** Corte 0,35 → 69,51° (arco total ≈ 139°). Estocada 0,5 → 60,00°.
Golpe de Escudo 0,1 → 84,26°.

### F6. Projétil: tempo de vida (e alcance derivado)

The projectile_lifetime formula is defined as:

`life_s = rangeTicks / TICK_RATE` ; derivado, só leitura:
`reach_px = v_pxs × life_s`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| rangeTicks | int | ≥ 1 | cânone | vida do projétil em ticks |
| v_pxs | float | > 0 | calculated (F2) | velocidade convertida |
| life_s | float | > 0 | data file | tempo de vida gravado |
| reach_px | float | > 0 | calculated | alcance máximo; aparece na validação, não é gravado |

**Output Range:** `reach_px` é um máximo (a parede destrói o projétil antes).
Aparece como linha informativa no relatório de validação, uma por projétil.
**Example:** Pulso 990 px/s × 0,8333 s = 825 px. Leque de Lâminas 1170 px/s ×
0,6 s = 702 px. Projétil inimigo: hoje fixo em 240 ticks no código; vira o
campo `life_s` = 4,0 s.

### F7. Duração → passos de física

The duration_to_steps formula is defined as:

`steps = max(1, round(t_s × TICK_RATE))` para `t_s > 0` ; `steps = 0` só se
`t_s = 0` **e** o campo permitir zero

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| t_s | float | ≥ 0 | data file | duração, já com todos os multiplicadores aplicados |
| TICK_RATE | int | 60 | constant | passos/s |
| steps | int | ≥ 0 | calculated | passos de física que a duração ocupa |

**Output Range:** inteiro ≥ 1 para t_s > 0. Mínimo útil: 1 passo = 0,0167 s.
Erro máximo: meio passo (8 ms). Arredonda ao mais próximo porque `ceil`
quebraria a volta exata (16/60 × 60 pode dar 16,000…04 → 17). Quantiza **uma
vez, no fim**, nunca em etapa intermediária. Empate em x,5 arredonda para longe
do zero (`round()` do GDScript). Em jogo, uma duração que cai abaixo de meio
passo depois dos multiplicadores vira 1 passo, sem aviso. O aviso é só da
validação, sobre o valor gravado.
**Example:** 0,2667 s → 16 passos. Recarga de 1,1667 s × 0,6 (fúria) = 0,7 s →
42 passos. 0,005 s → 0,3 → sobe para 1, com aviso na validação.

### F8. Curva linear padrão (`LinearCurveDef`)

The linear_curve formula is defined as:

`y = 0 se x < x_min ; senão y = clamp(base + slope × x, y_floor, y_cap)`

**Variables:**
| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| x | float | ≥ 0 | calculated | entrada dada pelo dono (ex.: profundidade) |
| x_min | float | ≥ 0 | data file | ativação, inclusiva (`x ≥ x_min` ativa) |
| base | float | livre | data file | intercepto |
| slope | float | livre | data file | inclinação por unidade de x |
| y_floor | float | ≤ y_cap | data file | piso |
| y_cap | float | ≥ y_floor | data file | teto (pode ser ∞) |
| y | float | {0} ∪ [y_floor, y_cap] | calculated | saída |

**Output Range:** 0 antes da ativação; depois, entre piso e teto.
`y_floor > y_cap` é erro V2 (regra entre campos do `LinearCurveDef`).
**Example:** chance de elite (cânone): base 0,05, slope 0,02, x_min 3,
y_floor 0, y_cap 0,25. Profundidade 2 → 0. Profundidade 5 → 0,15. Profundidade
12 → 0,29, limitado a 0,25.

Limite do escopo: F8 é **só de uma variável**. Fórmulas com mais entradas, como
o orçamento de onda `(3 + 0,9·prof + 2·região) × 1,35 se Provação`, ficam com
campos nomeados no `*Tuning` do dono (`base`, `per_depth`, `per_region`,
`trial_mult`). Este GDD não cria parser de expressão. Outra forma de curva só
entra quando um segundo GDD dono provar a necessidade.

## Edge Cases

> `systems-designer` não consultado nesta seção: modo Lean. Os pontos de atenção
> que ele levantou em Formulas estão incorporados.

**Carga e manifesto**

- **Se o manifesto não existir ou não puder ser lido:** o estado vai direto para
  Falhou, com um único erro (`manifesto não encontrado:
  assets/data/content_catalog.tres`). Nenhuma definição é carregada.
- **Se o manifesto listar um arquivo que não existe:** registra um erro para esse
  arquivo e continua lendo os outros. O resultado final é Falhou, com todos os
  erros juntos.
- **Se um arquivo for da classe errada para o tipo em que foi listado** (um
  `EnemyDef` na lista de armas): erro V1. A definição não entra no catálogo.
- **Se o mesmo arquivo, ou dois arquivos com o mesmo id, aparecer duas vezes no
  mesmo tipo:** erro V3, citando os dois caminhos.
- **Se houver arquivo em `assets/data/` fora do manifesto (órfão):** ele não
  existe para o jogo, que não varre pastas. Quem acusa é o teste do CI; a
  inicialização não percebe.
- **Se o mesmo id aparecer em tipos diferentes** (`lamina` como arma e como
  doutrina): é permitido, porque a unicidade vale dentro do tipo.

**Valores**

- **Se um campo valer 0:** cada campo declara se aceita zero. Preparo, alcance e
  deslocamento aceitam; recarga, a velocidade da forma `projetil` de um
  `AttackDef` e o tempo de vida não. Um 0 onde não cabe é erro V2. No `EnemyDef`,
  a velocidade do projétil **aceita** 0, que quer dizer "não atira" (`eco_perdido`
  e `fenda_errante` gravam 0, `arenaContent.ts:88`, `:90`).
- **Se uma duração ficar entre 0 e meio passo** (0 < t < 0,0083 s): F7 sobe para
  1 passo e a validação registra um **aviso**. O aviso aparece na lista, mas não
  bloqueia; só erro bloqueia.
- **Se `physics_ticks_per_second` ≠ 60:** é erro bloqueante, porque F1, F3 e F7
  perderiam a paridade com o cânone.
- **Se uma curva não tiver teto:** o `LinearCurveDef` usa o campo
  `sem_teto = true` em vez de gravar infinito no `.tres` (a serialização de
  `INF` não foi verificada no 4.7).
- **Se x < x_min numa curva com piso > 0:** a saída é 0, não o piso. O piso só
  vale depois da ativação (F8).
- **Se todos os pesos de uma tabela forem 0:** erro V8. Pesos que zeram **em
  jogo** (por exemplo, a Provação antes da profundidade 2) são problema do GDD
  dono, porque a validação só confere o dado parado.

**Constantes escondidas no código do cânone**

- **Se um valor do cânone existir só como constante de código**, como estes:
  - recuperação = 50% da recarga;
  - `RECOVER_MAX_TICKS` 12;
  - fúria = 60% da recarga;
  - vida do projétil inimigo de 240 ticks;
  - empurrão do projétil da arma, 6 (`engine.ts:1174`), que vira o `empurrao`
    do `AttackDef` do projétil (Armas das Doutrinas R2: Pulso 540 px/s; o
    Combate R6 lê o dado), e limiar do impacto na parede, 7 (`:77`), convertido
    pela F2 (630 px/s);
  - queda do empurrão × 0,78 por passo (`:966–967`);
  - corte do empurrão, `< 0,05` (`:968`), convertido pela F2 (4,5 px/s);
  - empurrão mínimo do finalizador, `HEAVY_KNOCKBACK` 10 (`:69`, usado em
    `:686`), pela F2 (900 px/s);
  - passo do golpe corpo a corpo, `MELEE_STEP` 7 (`:75`), pela F4 (10,5 px);
  - piso de 20 de Vida máxima (`engine.ts:444`);
  - teto de 60% de redução de dano (`engine.ts:607`):

  ele vira campo do `*Tuning` do sistema dono, convertido por F1 (tempo), F2
  (velocidade e empurrão) ou F4 (distância). O piso de Vida e o teto de redução
  vão para o `ModifiersTuning`; os outros empurrões e limiares, para o `CombatTuning`. Nenhum número
  de jogo fica literal no GDScript.
- **Se uma bênção canônica tiver no texto um número que não é o `value` do
  efeito:** a constante vira `valor`, quando escala com a raridade, ou
  `params`, quando não escala (R1). Levantamento de `BOON_EFFECTS`
  (`arenaContent.ts`) e `engine.ts`:

  | Tradição | No cânone | Vira |
  |---|---|---|
  | Corte Fantasma | `10 × dashDamage` de dano; Sangramento 1; alcance +6; empurrão 4 (`engine.ts:848`) | `valor` 10; `sangramento` 1, `alcance_extra_px` 9 (6 unidades × 1,5), `empurrao` 360 px/s (4 × 90, F2) |
  | Fundo do Poço | ativa com Vida < 50% (`:540`) | `limiar_vida` 0,5 |
  | Linha Contada | cada 4º acerto (`:571`) | `a_cada` 4 |
  | Penumbra | `+0,5 × dashEmpower` (`:676`), por 90 ticks (`:817`) | `valor` 0,5; `janela_s` 1,5 (F1) |
  | Forma Fixa | Abalo de 30 ticks (`:945`); o −30% é do Abalo (`:609`) | `duracao_s` 0,5 (F1); o texto usa `{status.abalo.reducao_dano_causado:pct}` (0,3; Modificadores aplica × (1 − 0,3)) |
  | Matéria Residual | `12 × killExplode` de dano; raio 100; empurrão 8 (`:1207–1212`) | `valor` 12; `raio_px` 150 (100 unidades × 1,5), `empurrao` 720 px/s (8 × 90, F2) |
  | Os Que Ficam | volta com 40% da Vida; invulnerável 120 ticks (`:627–628`) | `vida_ao_voltar` 0,4; `invuln_s` 2,0 (F1) |
  | Fardo Repartido | `dano × reflect × 3` (`:622`) | `valor` 3,0 (`{valor:pct}` → 300%) |

  As outras 10 Tradições já cabem no `valor` como estão. Os nomes dos tipos e
  dos `params` são os da R5 do GDD de Modificadores.

  A melhoria `recusa` da Oficina (fatia vertical) também cita `recusas_morte`,
  mas no cânone não traz constante (`arenaContent.ts:209`): os 40% e os 120
  ticks são de código (`engine.ts:627–628`). A importação grava nela os mesmos
  params de Os Que Ficam (`vida_ao_voltar` 0,4, `invuln_s` 2,0), e a V11
  confere.
- **Se o ataque em arco tiver o atalho "contato sempre acerta"** (`touching` no
  `engine.ts`): o formato reserva o campo `acerta_no_contato` (padrão `true`,
  por paridade). Se ele fica ou sai é decisão do Combate núcleo.
- **Se o código do cânone reconhecer um chefe pelo prefixo do id**
  (`enemy.defId.startsWith("boss")`, `engine.ts:580`): o mapa de R2 tira o
  prefixo (`boss_anomalia_maior` → `anomalia_maior`), então esse teste não
  pode ser portado. "É chefe" sai do comportamento `chefe` do `EnemyDef`. Ele
  decide o `fator_empurrao` 0,12 (fonte `chefe`, GDD de Modificadores R10) e que
  o chefe não cambaleia (`engine.ts:587`). O "não cambaleia" é regra de Combate
  núcleo e IA, como a armadura da elite, e o GDD de Chefes a confirma. Nenhum
  sistema deduz nada do texto de um id.

**Cânone e textos**

- **Se o nome PT-BR diferir do canônico só por acento ou forma Unicode** ("O Vôo
  do Escudo"): os dois textos são comparados depois de normalizar para NFC. A
  grafia canônica, com acento, é a que vale; qualquer outra diferença é erro V5.
- **Se uma chave de tradução existir com texto vazio:** erro V6.
- **Se o repo Khaeros mudar um nome canônico:** o jogo nunca lê o repo Khaeros.
  V5 compara com a cópia em `assets/data/canon/`. Atualizar a cópia exige
  aprovação do CD (R11).
- **Se uma bênção for de uma Doutrina sem arma no MVP** (Guardião, Véu,
  Transmutação, Pactos): o dado continua válido. Quais bênçãos são oferecidas é
  decisão do GDD de Bênçãos, não da validação.
- **Se uma definição do MVP apontar para conteúdo que o MVP não usa** (o chefe
  `anomalia_maior` na `RegionDef limiar`): o conteúdo entra no manifesto como
  dado, a V4 resolve e a importação fica igual ao cânone (AC-34). O
  comportamento `chefe` dele é uma chave reservada da IA no MVP (R8), e a última
  sala do `limiar`, do tipo `chefe`, é uma chave reservada de Câmaras e ondas.
  Não usar é decisão do sistema dono (Run e regiões), não da validação.

**Ids ao longo do tempo**

- **Se uma definição precisar sair do jogo:** ela **não é apagada**. Fica com
  `obsoleto = true`, continua resolvível por id (save e telemetria antigos
  funcionam) e nenhum sistema a oferece nem a sorteia.
- **Se alguém pedir um id inexistente em jogo:** obter por id sinaliza erro com
  o tipo e o id, sem `null` silencioso (R10). Para quem precisa perguntar antes
  (por exemplo, o Save conferindo um arquivo antigo), há uma consulta "existe?"
  que não gera erro.

**Recarga em debug**

- **Se a recarga for pedida durante uma run:** é recusada, com aviso. Só vale
  entre runs (estado Pronto, fora da run).
- **Se a recarga em debug falhar na validação:** vai para Falhou, igual à
  inicialização. O catálogo anterior é descartado, e o desenvolvedor corrige e
  recarrega de novo.
- **Para a recarga ler o arquivo editado, e não o cache:** ela lê o manifesto e
  cada definição com `ResourceLoader.CACHE_MODE_IGNORE_DEEP`. Sem isso, o cache
  do `ResourceLoader` devolveria os valores antigos.
- **Para os sistemas receberem o catálogo novo:** os sistemas da run não guardam
  o catálogo entre runs. Cada run recebe o catálogo por injeção quando começa,
  então a run seguinte à recarga já lê o novo. Os sistemas que vivem **fora** da
  run (Input, câmera) são **re-injetados pelo carregador a cada entrada em
  Pronto**, na inicialização e em cada recarga. Ao **sair** de Pronto (quando
  uma recarga começa), o carregador **retira** o Tuning deles (injeção vazia),
  antes de ler o primeiro arquivo. Como a recarga só acontece fora de run,
  nenhum sistema vivo fica com o catálogo antigo.
- **Se a carga terminar em Falhou** (na inicialização ou numa recarga): os
  sistemas fora da run ficam **sem** Tuning. Na inicialização, eles nunca o
  receberam; numa recarga, o carregador já o retirou ao sair de Pronto. O Input opera a tela de erros só com
  entradas digitais (teclas, cliques, D-pad e botões; analógicos e gatilhos
  ignorados, Input R12), então nenhum valor do catálogo é necessário e nenhum
  número entra no código.
- **Se a recarga mudar o conteúdo:** a impressão (R12) é recalculada, e a seed
  passa a mostrar a nova.

**Compartilhamento**

- **Se dois `.tres` apontarem para o mesmo sub-recurso externo** (o mesmo
  `AttackDef` em duas armas): é permitido, porque tudo é só de leitura (R3). Se
  um sistema precisar mudar o valor de uma arma, usa Modificadores, nunca o
  sub-recurso.

## Dependencies

**Depende de (upstream)**

| Sistema | Tipo | O que vem de lá | Sem ele |
|---|---|---|---|
| Localização | Suave (provisória) | Tabela PT-BR das chaves de texto (V5, V6) | Até o GDD de Localização (fatia vertical), um CSV PT-BR simples em `assets/data/` faz esse papel |
| Donos de comportamento (Modificadores, IA, Combate núcleo, Efeitos de status, Câmaras e ondas, Portas e recompensas) | Contrato de inicialização | Lista fechada de chaves registradas (R8, V4) | V4 daquele campo reporta **"registro de chaves ausente"** como erro: a checagem nunca passa sem ter rodado |
| Cânone Khaeros (repo externo, só leitura) | Fonte, fora do jogo | Valores iniciais (`arenaContent.ts`, `engine.ts`) e lista canônica (`traditions.ts`) copiada para `assets/data/canon/` | O jogo nunca lê o repo em execução; a cópia basta |

Os donos de comportamento só **entregam uma lista de chaves** ao validador na
inicialização; nenhum deles lê o catálogo para isso, então não há ciclo.

**É dependência de (downstream)**

| Sistema | Tipo | O que recebe |
|---|---|---|
| Modificadores e atributos | Forte | `EffectDef`, `ModifiersTuning` |
| Movimento e esquiva | Forte | `MovementTuning`, velocidade da arma |
| Combate núcleo | Forte | `AttackDef`, `CombatTuning` |
| Armas das Doutrinas | Forte | `WeaponDef` |
| Selo e Fluxo | Forte | `SealTuning` |
| Efeitos de status | Forte | `StatusTuning` |
| IA de inimigos e elites | Forte | `EnemyDef`, `EliteRules` (com `LinearCurveDef`) |
| Chefes (fatia vertical) | Forte | `EnemyDef` com comportamento `chefe` |
| Câmaras e ondas | Forte | `WaveRules`, pool da `RegionDef` |
| Portas e recompensas | Forte | `RewardTable` |
| Run e regiões | Forte | `RegionDef` |
| Bênçãos (Tradições) | Forte | `BoonDef`, `RarityTable` |
| Economia de Fragmentos | Forte | `EconomyRates` |
| Oficina de Reforja | Forte | `UpgradeDef` |
| RNG com seed | Suave | Listas em ordem estável (R10) e impressão do catálogo (R12) |
| Input e controle | Suave | `InputTuning` |
| Cena 3/4 e câmera | Suave | `CameraTuning`, `unit_to_px` |
| Save e perfil | Suave | Consulta "existe?" e ids estáveis |
| Diálogo e lore | Forte | Definições de fala e fragmentos (formato a definir no GDD dele, dentro de R1–R11) |
| Telemetria local | Suave | Ids estáveis |
| HUD, Tela de bênção, Feedback de combate (VFX) | Suave | Chaves de texto e arte |

"Forte" = o sistema não funciona sem as definições daqui. "Suave" = usa ids ou
ordem, mas não depende do conteúdo.

**Bidirecionalidade:** Modificadores e atributos, RNG com seed, Input e controle
e Cena 3/4 e câmera já existem e citam este GDD em Dependencies. Os demais,
quando forem escritos, devem listar "Conteúdo orientado a dados" em Dependencies. O índice de
sistemas passa a citar este sistema em "Depends On" dos consumidores fortes
(decisão do usuário, 2026-11-05).

## Visual/Audio Requirements

Não se aplica. Este sistema não tem nenhum evento visível ou sonoro durante o
jogo. A única tela dele é a de erros (UI Requirements). A arte e o áudio que as
definições referenciam seguem o Art Bible §8 e o futuro GDD de Áudio; aqui, a
V7 só confere se o caminho existe e está em `assets/art/export/`.

## Game Feel

Não se aplica diretamente, porque o jogador não opera este sistema. Mas os
números da sensação do combate (hitstop, buffer de entrada, cancelamento,
cambaleio; baseline §55) moram nos `*Tuning` daqui, e os GDDs de Combate núcleo,
Movimento e Input e controle (o buffer) são donos desses valores. Requisito indireto: **ajustar a sensação
nunca exige mexer em código**. Edita-se o `.tres` e, em debug, recarrega-se
entre runs (estado Pronto). Assim dá para afinar no protótipo de combate sem
recompilar nada.

## UI Requirements

**Tela de erros do catálogo.**

- **Quando aparece:**
  - aparece no lugar do menu quando o estado é Falhou;
  - se há só avisos (0 erros), a tela **não** aparece: os avisos vão para o log
    e, em debug, para o console.
- **O que mostra:**
  - no topo, a contagem ("3 erros, 1 aviso");
  - uma linha por item: gravidade (erro/aviso), regra (V1–V11), arquivo, campo,
    valor encontrado, valor esperado;
  - a ordem é erros primeiro, depois avisos; dentro de cada grupo, a ordem do
    manifesto.
- **Ações:**
  - não há como iniciar uma run;
  - botões **Copiar relatório** (área de transferência) e **Sair**;
  - em debug, também **Recarregar**;
  - o relatório também é gravado em `user://content_errors.log`.
- **Navegação:** totalmente usável por teclado e gamepad, sem mouse (preferência
  técnica do projeto); a lista rola. Sem catálogo, o Input opera esta tela só
  com entradas digitais (teclas, cliques, D-pad e botões; Input R12), porque o
  `InputTuning` mora no catálogo que falhou.
- **Textos da própria tela:** vêm da tabela de tradução quando ela carregou. Se a
  falha for justamente na tabela, a tela usa um texto PT-BR mínimo embutido. Essa
  é a **única exceção** à R7, e existe porque a tela precisa funcionar exatamente
  quando os dados falham.
- **Visual:** tela de diagnóstico, só com legibilidade (fonte e contraste do Art
  Bible §7). Não leva arte própria.

## Cross-References

| Documento | Seção | Uso neste GDD |
|---|---|---|
| `design/gdd/game-concept.md` | §4–§8, legenda de status | Armas, Tradições, Mestres, inimigos, regiões, Oficina; o que é [CÂNONE] |
| `design/gdd/systems-index.md` | enumeração, dependências, escopo por nível | Consumidores, conteúdo do MVP (Lâmina, Ressonância, Limiar; o chefe só como dado) |
| `design/art/art-bible.md` | §8.2, §8.8 | Tokens de id; arte só de `assets/art/export/` |
| Khaeros `packages/combat-rules/src/traditions.ts` | `TRADITION_SUBCHOICES` | Ids, doutrinas e nomes canônicos das 18 Tradições (R11, V5) |
| Khaeros `packages/combat-rules/src/arenaContent.ts` | todo | Valores iniciais de armas, inimigos, bênçãos, regiões e melhorias |
| Khaeros `packages/action-core/src/engine.ts`, `types.ts` | constantes, tipos | ~40 constantes de sensação e regra; 60 ticks/s; arena 1280×720 |
| Khaeros `docs/baseline.md` | §54–§57 | Passo fixo de 60 ticks/s, sensação, elites/Provação, Oficina |
| `docs/engine-reference/godot/current-best-practices.md` | Resources (4.5+) | `duplicate_deep()` (R3) |
| `design/gdd/rng-com-seed.md` | R7, R8 | Impressão do catálogo no contrato de reprodução e no texto da seed (R12) |
| `design/gdd/modificadores-e-atributos.md` | R5 | Nomes finais dos tipos de efeito e dos `params`; Abalo × (1 − `reducao_dano_causado`) |
| `design/gdd/input-e-controle.md` | R12 | `InputTuning` |
| `design/gdd/cena-3-4-e-camera.md` | R11 | `CameraTuning` |
| `.claude/docs/coding-standards.md` | Coding Standards | Valores em dado externo; injeção de dependência |

Os consumidores estão em Dependencies.

## Acceptance Criteria

> Proposta do `qa-lead` (consultado: modo Lean, seção de risco alto), ajustada às
> decisões do usuário de 2026-11-05.
>
> Evidência: **[L]** teste unitário em `tests/unit/content/` (catálogo em
> memória por fábrica, sem disco); **[I]** teste de integração em
> `tests/integration/content/`; **[UI]** screenshot guardado em
> `production/qa/evidence/`.

**Carga e estados (R4, R9)**

- **AC-01 [I]** **GIVEN** o manifesto real de `assets/data/` **WHEN** o jogo
  inicializa **THEN** o estado termina em Pronto com 0 erros, e cada tipo
  contém exatamente os ids listados no manifesto.
- **AC-02 [I]** **GIVEN** um caminho de manifesto que não existe **WHEN** a
  carga roda **THEN** o estado é Falhou, com exatamente 1 erro
  `manifesto não encontrado: …` e nenhuma definição carregada.
- **AC-03 [I]** **GIVEN** um manifesto que lista 2 arquivos inexistentes e 1
  definição inválida **WHEN** a carga roda **THEN** o estado é Falhou e mostra
  os 3 erros juntos.
- **AC-04 [I]** **GIVEN** um `.tres` em `assets/data/` fora do manifesto
  **WHEN** o teste de órfãos roda **THEN** ele falha citando o caminho **AND** o
  arquivo não aparece no catálogo.
- **AC-05 [L]** **GIVEN** o estado Pronto e o estado de run injetado como "em
  run" **WHEN** a recarga de debug é pedida **THEN** ela é recusada com aviso e
  o catálogo não muda. Com "fora de run", o estado vai para Carregando.
- **AC-06 [L]** **GIVEN** uma recarga cujo conteúdo falha na validação **WHEN**
  ela termina **THEN** o estado é Falhou e o catálogo anterior não é mais
  acessível.
- **AC-07 [UI]** **GIVEN** um catálogo com 2 erros e 1 aviso **WHEN** o jogo
  abre **THEN** a tela lista os 3 itens, cada um com arquivo, campo, regra e
  valor; o aviso aparece marcado como aviso; e não há como iniciar uma run.
- **AC-08 [I]** **GIVEN** o mesmo catálogo inválido **WHEN** o jogo roda num
  build de release exportado **THEN** o resultado é igual ao do debug, exceto
  V5 e V9, que não rodam no release (R9) **AND** um ícone existente passa a V7
  no export.

**Validação V1–V11**

- **AC-09 [L]** V1: **GIVEN** um `EnemyDef` sem `dano` e outro listado como
  arma **THEN** saem 2 erros V1, e o segundo não entra no catálogo.
- **AC-10 [L]** V2: **GIVEN** `recarga = 0` num ataque e `preparo = 0` em
  outro, com a tabela de regras de `AttackDef` dizendo que preparo aceita zero e
  recarga não **THEN** sai erro V2 só para a recarga.
- **AC-11 [L]** V3: **GIVEN** dois `BoonDef` com o mesmo id, um id `Lamina-1` e
  o id `lamina` usado como arma e como doutrina **THEN** sai erro de duplicata
  citando os dois caminhos e erro de formato para `Lamina-1`; o `lamina`
  repetido entre tipos não gera erro.
- **AC-12 [L]** V4: **GIVEN** uma `RegionDef` com o inimigo `fenda_erante`, que
  não existe **THEN** sai erro V4. O mesmo vale para um chefe, status, tipo de
  efeito, comportamento, tipo de sala (`combta`) ou tipo de recompensa fora da
  lista registrada **AND** uma lista de chaves que não foi entregue gera
  "registro de chaves ausente".
- **AC-49 [L]** Chave reservada (R8): **GIVEN** uma lista de comportamentos de
  fábrica com `corpo_a_corpo` e `chefe` reservado **THEN** um `EnemyDef` com
  `chefe` passa na V4 **AND** um com `voador`, que não está na lista, é erro V4.
- **AC-50 [L]** V11: **GIVEN** uma `BoonDef` e uma `UpgradeDef` de fábrica, ambas
  com efeito `recusas_morte`, com `params.vida_ao_voltar` 0,4 e 0,5 **THEN** sai
  1 erro V11 citando as duas definições e os dois valores **AND** com 0,4 nas
  duas, passa **AND** dois efeitos de tipos diferentes com params diferentes
  passam.
- **AC-13 [L]** V5: **GIVEN** o nome "Traço Único" quando o canônico é "O Traço
  Único" **THEN** sai erro V5. A mesma grafia em NFD contra NFC passa, e uma
  doutrina diferente da canônica é erro.
- **AC-14 [L]** V6: **GIVEN** uma chave sem texto e outra com texto vazio
  **THEN** saem 2 erros V6.
- **AC-15 [L]** V7: **GIVEN** um ícone ausente e outro fora de
  `assets/art/export/` **THEN** saem 2 erros V7.
- **AC-16 [L]** V8: **GIVEN** os pesos `[0,0,0]` e `[1,-1]` **THEN** saem 2
  erros, e `[0,1,0]` passa.
- **AC-17 [L]** V9: **GIVEN** `ids_registrados.csv` com `enemy,eco_perdido` e um
  catálogo sem esse id, ou com `eco_perdido` como arma **THEN** sai erro V9
  **AND** o mesmo id marcado `obsoleto = true` passa.
- **AC-18 [L]** V10: **GIVEN** a descrição "causa 12 de dano" **THEN** sai erro
  V10 **AND** "causa {valor} de dano", com `valor` sendo campo do efeito, passa
  **AND** `{inexistente}` é erro.
- **AC-19 [L]** **GIVEN** `physics_ticks_per_second = 30` **THEN** sai erro
  bloqueante.
- **AC-20 [I]** **GIVEN** o conteúdo real do repositório **WHEN** o validador
  roda no CI (gdUnit4, o mesmo validador do jogo) **THEN** ele dá 0 erros.
- **AC-41 [I]** Bênçãos reais: **GIVEN** as 18 `BoonDef` importadas **WHEN**
  V1, V2 e V10 rodam **THEN** dão 0 erros **AND** Corte Fantasma tem `valor` 10
  e `params.sangramento` 1, Linha Contada tem `params.a_cada` 4 e Fardo
  Repartido tem `valor` 3,0 **AND** a descrição de Linha Contada preenchida dá
  "Cada 4º acerto causa +60% de dano." em Comum e "+120%" em Épica.
- **AC-42 [L]** Sintaxe dos marcadores: **GIVEN** uma definição com dois
  efeitos **THEN** `{vida_max_plano.valor:int}` passa e `{valor}` sem tipo é erro V10
  **AND** `{valor:moeda}` é erro de formato **AND**
  `{status.abalo.reducao_dano_causado:pct}` passa com um `StatusTuning` de fábrica que
  tem esse campo **AND** `valor = -10` com `int` exibe "10".
- **AC-44 [L]** V9: **GIVEN** um manifesto com `eco_do_veio` e um registro sem
  essa linha **THEN** sai erro V9 **AND** um registro com uma linha a menos que
  o do branch principal (os dois em memória) é erro V9.

**Consulta e injeção de dependência (R3, R10)**

- **AC-21 [L]** **GIVEN** um catálogo de fábrica e um relator de erros falso
  **WHEN** se pede um id inexistente **THEN** a resposta é `null` **AND** o
  relator recebeu uma entrada com tipo, id e quem pediu **AND** "existe?"
  responde `false` sem registrar erro **AND** o teste termina sem interrupção
  (o relator falso não chama `assert`).
- **AC-43 [L]** Relator padrão: **GIVEN** o relator padrão com
  `parar_em_debug = false` e um log falso **WHEN** ele recebe uma entrada
  **THEN** o log tem uma linha com tipo, id e quem pediu, e o teste termina sem
  interrupção.
- **AC-22 [L]** **GIVEN** um manifesto na ordem `c, a, b` **WHEN** se lista e
  filtra repetidas vezes, e também com o catálogo reconstruído **THEN** a ordem
  é sempre `c, a, b`.
- **AC-23 [L]** **GIVEN** uma seed fixa e o mesmo catálogo **WHEN** um sorteio
  que usa as listas do catálogo roda duas vezes **THEN** as sequências são
  idênticas.
- **AC-24 [I]** **GIVEN** `src/`, exceto o carregador **WHEN** se procura
  `load(` / `preload(` / `ResourceLoader` com caminho de `assets/data` **THEN**
  não há nenhuma ocorrência.
- **AC-25 [L]** **GIVEN** uma definição copiada com `duplicate_deep()` **WHEN** a
  cópia é alterada **THEN** a definição do catálogo continua igual ao snapshot
  anterior.
- **AC-26 [L]** **GIVEN** um `AttackDef` compartilhado por duas armas **THEN** a
  validação não dá erro.
- **AC-27 [L]** **GIVEN** uma definição `obsoleto = true` **THEN** obter por id a
  devolve **AND** listar e filtrar sem parâmetro não a incluem **AND** com o
  parâmetro explícito, a incluem.

**Unidades F1–F7** (funções puras, tolerância de 1e-6 salvo indicação)

- **AC-28 [L]** F1: 16 → 0,266667 s; 26 → 0,433333 s; 0 → 0.
- **AC-29 [L]** F2: 1,7 → 153; 4,3 → 387; 11 → 990 px/s; empurrão 5 → 450 e
  4 → 360; limiar da parede 7 → 630 px/s. F3: 0,06 → 3,6;
  0,12 → 7,2; 0,04 → 2,4 por segundo.
- **AC-30 [L]** F4: 95 → 142,5 px; uma arena não uniforme (1280×800) recusa a
  importação.
- **AC-31 [L]** F5: 0,35 → 69,51°; 0,5 → 60,00°; 0,1 → 84,26°; −1 → 180°
  (tolerância 0,005°); 0,999 (< 5°) é erro; um alvo exatamente em θ é acertado.
- **AC-32 [L]** F6: 50 ticks a 990 px/s → `life_s` 0,8333 e `reach_px` 825, que
  aparece no relatório; `life_s = 0` é erro V2.
- **AC-33 [L]** F7: 0,2667 s → 16; 0,7 → 42; 16/60 → 16 (não 17); 0,025 s
  (1,5 passo) → 2; 0,005 → 1, com aviso que não bloqueia; t = 0 em campo que
  aceita zero → 0; t = 0 em campo que não aceita → erro V2.
- **AC-34 [I]** Paridade: **GIVEN** a fixture com os valores brutos do cânone
  **WHEN** comparada aos `.tres` gravados pelo script de importação **THEN** todo
  campo bate com F1–F6, casando registro e `.tres` pelo mapa de ids (R2)
  **AND** o `valor` dos efeitos bate com `value × constante` (R1).

**Curva F8**

- **AC-35 [L]** **GIVEN** a curva de elite (0,05; 0,02; x_min 3; piso 0; teto
  0,25) **WHEN** x = 2, 3, 5, 12 **THEN** y = 0; 0,11; 0,15; 0,25.
- **AC-36 [L]** **GIVEN** piso 0,1 e x < x_min **THEN** y = 0 **AND** com
  `sem_teto = true` não há limite superior **AND** piso maior que o teto é erro
  V2 citando `y_floor` e `y_cap`.

**Impressão e recarga (R12, recarga em debug)**

- **AC-46 [L]** Impressão: **GIVEN** dois catálogos de fábrica iguais **THEN**
  as impressões são iguais, e a curta tem 4 hex maiúsculos e é o começo da
  completa (64 hex) **AND** mudar um campo (0,25 → 0,26) muda a completa **AND**
  trocar a ordem de duas definições no manifesto muda a completa **AND** mudar só
  o texto traduzido de uma chave não muda **AND** −0,0 e 0,0 dão a mesma
  impressão.
- **AC-47 [I]** Recarga: **GIVEN** um catálogo Pronto, carregado de uma pasta
  temporária **WHEN** um valor de um `.tres` é editado no disco e a recarga
  roda fora de run **THEN** o catálogo novo tem o valor novo (sem cache) **AND**
  a impressão mudou **AND** uma run criada depois da recarga recebe o valor
  novo **AND** um consumidor falso fora da run (no papel do Input) recebeu o
  `InputTuning` novo ao entrar em Pronto.
- **AC-51 [I]** Sem catálogo: **GIVEN** um catálogo que termina em Falhou
  (inclusive com `zm + ze ≥ 1` no `InputTuning`) **WHEN** a tela de erros abre
  **THEN** nenhum sistema fora da run recebeu Tuning **AND** a lista rola e
  Copiar relatório e Sair são acionados só por D-pad e botões do gamepad
  (Input AC-38) **AND** o analógico não move o foco **AND**, partindo de um
  catálogo Pronto que injetou um `InputTuning` de fábrica num consumidor falso
  fora da run, uma recarga que termina em Falhou deixa esse consumidor sem
  Tuning (retirado ao sair de Pronto).

**Cânone (R2, R11)**

- **AC-37 [I]** **GIVEN** `assets/data/canon/` e as `BoonDef` **THEN** há
  exatamente 18 ids `trad_*`, todos presentes e com a doutrina canônica
  traduzida pelo mapa (`BLADE` → `lamina`).
- **AC-48 [I]** MVP com o chefe como dado: **GIVEN** o manifesto real do MVP
  **THEN** ele contém o `EnemyDef anomalia_maior`, com comportamento `chefe`, e
  a `RegionDef limiar` com chefe `anomalia_maior` **AND**, com a lista de
  comportamentos da IA do MVP (`chefe` reservado) e a lista de tipos de sala de
  Câmaras e ondas do MVP (`chefe` reservado), a V4 dá 0 erros **AND** os
  valores do chefe batem com a fixture do cânone (AC-34).
- **AC-39 [I]** Mapa: **GIVEN** a importação com `mapa_ids.csv` e a fixture do
  cânone **THEN** `trad_blade_traco_unico` tem `doutrina = lamina`; a
  `RegionDef limiar` tem chefe `anomalia_maior` e pool `eco_perdido,
  anomalia_menor, fenda_errante`; `fenda_errante` tem comportamento
  `arremetida` e `anomalia_maior`, `chefe`; o Ataque da `lamina` tem forma
  `arco` e o Especial, `avanco`; a `RegionDef limiar` tem a sequência
  `combate, combate, combate, santuario, combate, combate, chefe`; a
  `RewardTable` tem pesos com as chaves `bencao`, `fragmentos`, `cura` e
  `provacao`; e nenhum id ou token gravado nos `.tres` é **igual** a um valor
  da coluna `id_canon` do mapa R2 que o mapa troca. A comparação é do token
  inteiro, não de substring: `combate` não casa com `combat`, e
  `trad_blade_traco_unico` não casa com `BLADE` **AND** um id ou token
  canônico sem linha no mapa faz a importação falhar
  citando o id **AND** os `trad_*` saem iguais aos de `traditions.ts`.
- **AC-40 [L]** V5 ampliada: **GIVEN** uma `BoonDef` com `doutrina = lamina` e
  canônica `BLADE` **THEN** passa, e com `ressonancia` é erro V5 **AND** um
  `EnemyDef eco_perdido` com nome "Eco perdido" é erro V5 **AND** um
  `WeaponDef pactos` com nome "Laço dos Pactos" é erro V5.
- **AC-45 [I]** CSV: **GIVEN** `assets/data/canon/` **WHEN** o projeto importa
  (`godot --headless --import`) **THEN** nenhum `.translation` sai dessa pasta,
  e todo `.csv` ali tem `importer="keep"`.

**Desempenho (ADVISORY)**

- **AC-38 [I, perf]** **GIVEN** o catálogo do MVP (30–60 `.tres`) na máquina
  mínima **WHEN** a carga e a validação rodam a frio **THEN** a mediana de 5
  execuções fica em ≤ 250 ms, dos quais ≤ 30 ms são da validação. O tempo é só
  registrado, sem assert de tempo, e o teste fica em `tests/performance/`. A
  máquina mínima não está definida (Open Questions).

Cobertura: R1–R12, V1–V11, F1–F8, o mapa de ids, o relator de erros, a
recarga em debug e a interação com RNG e injeção têm pelo menos um critério
cada. A numeração não é contínua por grupo: AC-39 a AC-45 entraram na revisão de
2026-11-05, e AC-46 e AC-47 na re-review do mesmo dia; AC-48 na revisão de 2026-11-06,
e AC-49 na segunda revisão da mesma data. AC-50 e AC-51 entraram na revisão do
cross-review de 2026-11-06 (`gdd-cross-review-2026-11-06.md`), que também mudou
AC-12, AC-39, AC-47 e AC-48. A 2ª passada do cross-review
(`gdd-cross-review-2026-11-06b.md`) mudou AC-39 (token inteiro) e AC-51
(recarga que termina em Falhou).

## Open Questions

| # | Pergunta | Dono | Resolver até |
|---|---|---|---|
| 1 | Qual API de String do Godot 4.7 faz normalização NFC (V5)? Não está em `docs/engine-reference/`. Plano B: o script de importação grava tudo já em NFC e a V5 compara sem normalizar. | godot-specialist | Antes da primeira story deste sistema (após instalar o 4.7.2) |
| 2 | `Dictionary` tipado em `@export` (4.4+): o Inspector edita bem? Afeta a forma das tabelas de regras e de pesos, e os `params` do `EffectDef`. | godot-specialist | Idem |
| 3 | Qual é a máquina mínima para o orçamento de AC-38? | technical-director | Antes de `/gate-check technical-setup` |
| 4 | Pactos: o cânone ainda tem o "Laço dos Pactos". A Besta do Vínculo e a criatura do pacto não têm valores, então nada de Pactos é importado do cânone; os valores nascem no GDD dono. | game-designer | GDDs Armas das Doutrinas / Criatura do pacto (Alpha) |
| 5 | Formato das definições de fala e de fragmentos de lore | narrative-director | GDD Diálogo e lore (fatia vertical) |
| 6 | Mecanismo de injeção (Autoload só de leitura, nó raiz ou `RefCounted`) e o relator de erros | technical-director | ADR, via `/architecture-decision`, antes de `/create-architecture` |
| 7 | ~~Nada foi verificado localmente: o Godot não está instalado~~ **Resolvida em 2026-11-05:** Godot 4.7.2 instalado, `project.godot` importa sem erro. As perguntas 1 e 2 agora podem ser testadas na engine. | usuário | ✅ |
