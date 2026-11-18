# ADR-0005 — RNG determinístico

## Status

Accepted · 2026-11-16 (aprovado pelo usuário; Proposed em 2026-11-14)

## Date
2026-11-16

## Last Verified

2026-11-16 (emenda Pactos: finalidade 9 `pactos`; seções Engine Compatibility e ADR Dependencies acrescentadas pela revisão de 2026-11-15)

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7, pin 4.7.2 (instalado, sem gap) |
| **Domain** | Core (Scripting) |
| **Layer** | Foundation |
| **Knowledge Risk** | LOW: aritmética inteira de 64 bits do GDScript, máscaras e `RefCounted`; não usa `RandomNumberGenerator` da engine |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `current-best-practices.md` |
| **Post-Cutoff APIs Used** | Nenhuma |
| **Verification Required** | Vetores de F1/F2 do cânone reproduzidos em 4.7.2 com `int` de 64 bits (seção "Evidência"); paridade debug/release dos vetores |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | [ADR-0001](adr-0001-orquestrador-do-passo.md): ciclo da run e composição; [ADR-0004](adr-0004-catalogo-de-dados.md): ordem do manifesto e impressão |
| **Enables** | ADR-0010 (spawn e IA no passo), ADR-0013 (seed na telemetria), ADR-0015 (sorteio do encontro de pacto), ADR-0017 |
| **Blocks** | Toda story com sorteio |
| **Ordering Note** | Sem ciclo: 0001 → … → 0004 → 0005 |

## Contexto e escopo

O [GDD de RNG](../../design/gdd/rng-com-seed.md) já aprova mulberry32, derivação por finalidade/região/profundidade e consumo fixo para os sorteios estruturais. Este ADR propõe a organização desses contratos em GDScript, a validade dos fluxos ao encerrar uma run e o tratamento dos limites numéricos.

Depende do ciclo da run ligado ao [ADR-0001](adr-0001-orquestrador-do-passo.md) e da ordem e impressão do catálogo do [ADR-0004](adr-0004-catalogo-de-dados.md). O contrato garante a estrutura quando coincidem seed, versão do jogo, impressão completa do conteúdo, estado inicial da run, escolhas de portas/bênçãos e usos de troca de oferta. Os candidatos de spawn são reproduzíveis. A escolha final entre candidatos pode depender da posição do jogador. O consumo de IA acompanha o combate.

## Decision

### Algoritmo e estado

`FluxoRng` será lógica pura em `RefCounted`, com estado uint32 representado pelo inteiro de 64 bits do GDScript. Cada avanço segue F1 do GDD. Máscaras e `imul` em metades de 16 bits preservam o resultado de 32 bits sem depender de overflow de multiplicação.

A derivação segue F2 e suas constantes fixas. A chave inclui finalidade 1–8, região 0–255 e índice da câmara 0–1023. O índice inclui Santuário e outras câmaras sem combate. A profundidade de dificuldade `p` pertence a Câmaras e tem outro significado. Entradas de chave inválidas geram um diagnóstico sem criar um fluxo. A máscara uint32 aplica-se à seed numérica recebida na fronteira. Texto de seed digitado passa pela gramática estrita de F9.

As funções aritméticas de F1–F9 ficam separadas da posse de estado. Isso permite testar uma saída uint32 específica e comparar vetores do cânone. Constantes e algoritmos fazem parte da versão do jogo. Uma alteração que mude a sequência exige atualização dessa versão e dos vetores.

### Posse e autorização dos fluxos

O ponto de composição cria uma fonte por run, injetada por interfaces limitadas ao consumidor. A fonte mantém o mapa de chave para fluxo. Pedir a mesma chave retorna o mesmo objeto e continua o estado existente. A ordem de criação de chaves e a iteração desse mapa ficam fora das fórmulas de sorteio.

| Consumidor | Finalidades autorizadas |
|---|---|
| Câmaras e ondas | 1 ondas, 3 spawn, 8 layout |
| IA e elites | 2 elites, 7 ia |
| Portas e recompensas | 4 portas |
| Bênçãos | 5 bencaos, 6 raridade |

A finalidade 7 permite consumo dependente do combate. Nas finalidades 1–6 e 8, os consumidores mantêm a quantidade e ordem de sorteios de cada decisão. Spawn sorteia a quantidade completa de candidatos antes de aplicar sua seleção. As listas de opções seguem a ordem do manifesto e os ajustes aprovados dos donos.

### Emenda (2026-11-16): Doutrina de Pactos

Conferido contra `rng-com-seed.md` (emenda Pactos: R2-P, R3-P, R7-P, F2, AC-36 a AC-40):

| Consumidor | Finalidade nova | Chave | Uso |
|---|---|---|---|
| Vínculo e pactos (via ADR-0015, encontro) | **9 `pactos`** | (`pactos`, região, 0); um por região, no MVP um por run | se há encontro de pacto, em que câmara (índices 1–2) e com que espécie (Vínculo F1); pedido só em runs da Doutrina `pactos`, ao criar a run, com **consumo fixo de 4 reais** mesmo quando a garantia (pity) decide o encontro (Vínculo V6, F1, V40) |

- A chave passa a aceitar **finalidade 1–9**. `pactos` é trio próprio: pela F2 não toca nenhum outro fluxo, e nenhum fluxo existente muda de ordem.
- **IA de aliado (Maldições) não ganha fluxo.** A dupla e o portador não consomem fluxo de estrutura; o que a Maldição muda no combate só afeta `ia` (finalidade 7, já não garantida) e o ponto de spawn escolhido. Se a IA de aliado do ADR-0017 precisar sortear, ela pede `ia` com a mesma autorização da IA de inimigos, nunca um fluxo estrutural.
- **Chefe não ganha fluxo.** A câmara do chefe (índice 6) não consome `ondas`, `elites` nem `layout`; a profundidade 6 entra em `ia` só se Chefes pedir (hoje não: esperas fixas). O chefe não sorteia nada (chefes.md R2/R6, camaras-e-ondas.md R14-P): as esperas e os padrões dele são fixos. Os lacaios `invocado_pelo_chefe` nascem comuns, em posições fixas, **sem consumir `elites` nem `spawn`**; depois rodam a IA `melee` normal e consomem `ia` como qualquer comum (IA R21, AC-IA-46; ADR-0018 §8). **Porta forçada do chefe (TR-portas-010).** A porta depois do índice 5 é forçada `chefe`, **sem sorteio** (Portas R6): nenhuma forçada consome fluxo. O trio (`portas`, 0, 5) só seria consumido se Portas sortear algo nessa porta; se isso ocorrer, é consumo novo daquele trio, **sem reordenar** nenhum outro fluxo (F2: trio próprio). Hoje o consumo é zero.
- **Filtro de spawn pela acuada (TR-camaras-012).** O consumo de `spawn` é **fixo em 14 candidatos por nascimento**, sempre sorteados por inteiro (RNG R4b), com ou sem encontro. O filtro `spawn_dist_acuada_px` (Câmaras F3-P, 240 px, `RoomTuning`) é aplicado **depois do sorteio**, sobre a lista já sorteada, junto da distância do jogador: muda só qual candidato é escolhido, nunca quantos números saem. Se nenhum serve, vale o último (R7). `ordem` (paridade para o alvo padrão) é dado de Câmaras para a IA (ADR-0018) e não toca RNG.
- A **acuada** entra em pontos fixos e não consome RNG.
- O estado inicial da run passa a incluir, em runs de Pactos, a dupla e o perfil de vínculo (R7-P); a seed nasce em **`dupla_confirmada`** (Vínculo V16/V16b/V42), não ao confirmar a arma. Pedir fluxo durante a Escolha da dupla é erro (estado Sem run).

### Ciclo de vida e referências retidas

A seed nasce ao confirmar a arma. A fonte recebe entropia, tipo de build e argumentos por injeção, conforme R2/R9. Release usa entropia e registra que uma seed fornecida por argumento foi ignorada. Uma seed de debug inválida impede criar a run.

A fonte da run possui um marcador compartilhado de validade. Cada fluxo guarda esse marcador, que contém apenas o estado ativo e a identidade da sessão de run. Encerrar a run invalida o marcador antes de entregar o controle à tela final. Toda operação de sorteio consulta essa validade antes de consumir um número. Isso também alcança um fluxo que um consumidor reteve anteriormente.

Em Encerrada, a seed e os metadados continuam disponíveis para tela e telemetria, e pedidos de fluxo retornam null com diagnóstico. Um sorteio através de referência antiga retorna o valor de erro previsto para sua operação e preserva o estado. Ao voltar à escolha de arma, a fonte descarta os fluxos. A run seguinte recebe um marcador novo, mesmo quando usa a mesma seed. O marcador antigo continua inválido. Referências entre fonte, fluxos e marcador seguem uma direção para evitar ciclos.

### Operações e limites

Argumentos e validade são verificados integralmente antes do primeiro avanço. Um pedido inválido gera um diagnóstico no relator injetado e conserva a sequência. A validação de intervalo inteiro evita calcular uma diferença que possa estourar int64. Valores reais e somas devem ser finitos antes de sortear.

| Operação | Consumo e contrato |
|---|---|
| Real unitário | Um avanço, uint32 dividido por 2³² |
| Inteiro de 0 a n−1 | Um avanço, `(u * n) >> 32`, 1 ≤ n ≤ 2²¹ |
| Intervalo inteiro ou real | Um avanço, inclusive quando os extremos coincidem, com as regras de F5 |
| Escolha ponderada | Um avanço após validar todos os pesos e a soma |
| k distintos de n | Fisher–Yates parcial de F7, min(k,n) avanços |
| Embaralhar uma cópia | F8, max(n−1,0) avanços, preservando a lista recebida |

F7 e F8 usam F4 internamente. Para n acima de 2²¹, operações que exigem sortear um índice são recusadas antes de alocar ou consumir. n ou k negativos também são inválidos. Os casos n=0 ou k=0 de F7 continuam retornando vazio sem consumir. A definição desses limites de coleção é uma extensão técnica proposta para fechar entradas que F7/F8 não delimitam.

### Escolha ponderada inteira no limite

O GDD permite soma inteira W até 2³¹ inclusive. O produto máximo `u * W` é 2⁶³−2³¹ e cabe em int64. Já a expressão literal do limite acumulado `C_i * 2³²` chega a 2⁶³ quando C_i=2³¹.

A implementação proposta preserva o domínio do GDD usando `bucket = (u * W) >> 32` e devolvendo o primeiro índice com `bucket < C_i`. Para inteiros não negativos, essa comparação é equivalente a `u * W < C_i * 2³²`. O acumulado permanece até 2³¹ e os pesos zero nunca são selecionados. Antes de somar um peso, valida-se que ele cabe em `2³¹ - soma_atual`.

Se houver qualquer peso real, usa-se o caminho real de F6, validando os pesos e a soma finita. Se o arredondamento fizer o produto alcançar W, o índice positivo final recebe esse caso de borda. Esse ajuste técnico proposto preserva a promessa de retornar um índice válido e merece vetor específico na implementação.

### Seed, telemetria e fronteira da apresentação

A formatação e o parse seguem F9, incluindo recusa de espaços, prefixo 0x, sinais e hífen fora do formato 4+4. O rótulo exibe seed, versão e prefixo curto da impressão do catálogo. Telemetria e relatório de erro recebem a impressão completa e os seis elementos de reprodução nos momentos definidos por R7.

RNG de cosméticos fica em `src/presentation/`. Nenhuma regra do jogo lê seu resultado. O CI deverá verificar as chamadas proibidas descritas no AC-32 em GDScript e scripts embutidos de cenas/recursos, com uma exceção localizada para a função de entropia da criação da run. O verificador deve reconhecer comentários e literais para localizar chamadas reais e testar uma violação inserida em fixture. A criação do lint acompanha o primeiro código de produção de RNG.

## Alternativas consideradas

| Alternativa | Efeito |
|---|---|
| `RandomNumberGenerator` da engine | Vincularia a sequência ao comportamento da engine e exigiria revisar a escolha já aprovada em R6. |
| Um fluxo único para todos os sistemas | O consumo variável de IA deslocaria os sorteios das câmaras e recompensas. |
| Derivar um fluxo novo a cada consulta | Repetiria o começo da sequência quando o mesmo consumidor consulta novamente uma chave. |
| Comparar acumulados deslocados em int64 | O limite W=2³¹ pode gerar overflow. A comparação pelo bucket mantém o domínio aprovado. |

## Consequences

### Positivas

- Estrutura da run (ondas, layout, portas, bênçãos, elites, encontro de pacto) reproduzível pelos seis elementos, independente do consumo de IA.
- Gerador próprio (mulberry32) estável entre versões da engine e sistemas operacionais, com paridade verificável contra o cânone.
- Fonte injetada por run e autorização por consumidor: nenhum sistema consome fluxo alheio; testes sem singleton.
- Marcador de validade impede sorteio por referência retida após o fim da run.
- Pactos, chefe e acuada entram sem reordenar nenhum fluxo existente (trio próprio pela F2).

### Negativas

- Toda mudança de constante ou algoritmo exige nova versão do jogo e novos vetores.
- Consumidores estruturais carregam a disciplina de consumo fixo (ex.: 14 candidatos de spawn, 4 reais de `pactos` mesmo com garantia).
- APIs aleatórias da engine ficam proibidas no código de jogo, com lint de CI a manter.
- A posição do jogador e o consumo de IA ficam fora da garantia de reprodução.

### Riscos

- Limites de coleção (n até 2²¹) e o ajuste de arredondamento do caminho real de F6 são extensões técnicas propostas, ainda sem revisão e sem vetor próprio.
- Comparação direta com a implementação TypeScript canônica e custo do AC-33 pendentes.
- Lint de AC-32 com falso negativo deixaria RNG da engine entrar na regra; mitigação: fixture com violação inserida.

## GDD Requirements Addressed

| TR-ID | Requisito | Origem | Como este ADR atende |
|---|---|---|---|
| TR-conteudo-019 | Ordem estável do manifesto de CurseDef para o sorteio do Vínculo | conteudo-orientado-a-dados.md R10-P | §Posse e autorização dos fluxos (listas de opções na ordem do manifesto) e Emenda Pactos (sorteio de espécie); estabilidade da ordem: ADR-0004 |
| TR-rng-001 | Fonte única; APIs aleatórias da engine proibidas, com lint de CI | rng-com-seed.md R1 | §Algoritmo e estado (gerador próprio) e §Seed, telemetria e fronteira da apresentação (lint de AC-32) |
| TR-rng-002 | Seed u32 sorteada ao criar a run; --seed só em debug; fixa durante a run | rng-com-seed.md R2 | §Ciclo de vida e referências retidas; máscara u32 em §Algoritmo e estado |
| TR-rng-003 | Fluxos derivados por finalidade, região e profundidade; lista fechada | rng-com-seed.md R3 | §Algoritmo e estado (chave F2) e §Posse e autorização dos fluxos (tabela fechada) |
| TR-rng-004 | Sorteios iteram na ordem do manifesto, nunca Dictionary, hash ou árvore | rng-com-seed.md R4 | §Posse e autorização dos fluxos (iteração do mapa fora das fórmulas; listas na ordem do manifesto) |
| TR-rng-005 | Consumo fixo nas finalidades de estrutura | rng-com-seed.md R4b | §Posse e autorização dos fluxos (finalidades 1–6 e 8) |
| TR-rng-006 | Operações com consumo definido; erros não consomem e vão ao relator | rng-com-seed.md R5 | §Operações e limites e §Escolha ponderada inteira no limite |
| TR-rng-007 | Gerador próprio mulberry32, estável, com paridade com o cânone | rng-com-seed.md R6 | §Algoritmo e estado; seção "Evidência e critérios de implementação" |
| TR-rng-008 | Contrato de reprodução com seis elementos | rng-com-seed.md R7 | Contexto (seis elementos) e §Seed, telemetria e fronteira da apresentação |
| TR-rng-009 | Fonte de fluxos injetada, sem singleton global | rng-com-seed.md R9 | §Posse e autorização dos fluxos |
| TR-rng-010 | Máscara u32 na fronteira e na leitura de save; save no meio da run fora do MVP | rng-com-seed.md AC-10 | §Algoritmo e estado (máscara na fronteira); leitura de save: ADR-0013 |
| TR-rng-011 | RNG cosmético só em src/presentation/, sem acesso à fonte de fluxos | rng-com-seed.md R1 | §Seed, telemetria e fronteira da apresentação |
| TR-rng-012 | Texto da seed na pausa, morte, vitória e debug, com copiar e campo no debug | rng-com-seed.md R8 | §Seed, telemetria e fronteira da apresentação (F9 e rótulo); telas: ADR-0012 |
| TR-rng-013 | Finalidade 9 pactos com chave (pactos, região, 0) e consumo fixo de 4 reais | rng-com-seed.md R3-P | Emenda Pactos |
| TR-rng-014 | Com Pactos a seed nasce em dupla_confirmada | rng-com-seed.md R2-P | Emenda Pactos (último item) |
| TR-rng-015 | Estado inicial ampliado com dupla e perfil de vínculo | rng-com-seed.md R7-P | Emenda Pactos (último item) |
| TR-ia-004 | Fluxos ia (variável) e elites (consumo fixo de 1 real por inimigo) | ia-de-inimigos-e-elites.md R10 | §Posse e autorização dos fluxos (IA e elites: 2 e 7; 7 variável); 1 real por inimigo: ADR-0018 |
| TR-ia-008 | sortear_elite chamado pelas Câmaras, no máximo 1 elite por onda | ia-de-inimigos-e-elites.md R10 | Parcial: §Posse e autorização dos fluxos (`elites` autorizado só à IA); chamada e limite: ADR-0018 |
| TR-camaras-001 | Câmaras dono de p e p_max; chave do RNG é o índice da câmara | camaras-e-ondas.md R3 | §Algoritmo e estado (índice inclui Santuário; `p` pertence a Câmaras) |
| TR-camaras-004 | Layout pelo fluxo layout com consumo fixo | camaras-e-ondas.md R5 | §Posse e autorização dos fluxos (8 layout, consumo fixo) |
| TR-camaras-005 | Ondas compostas na montagem pelo fluxo ondas | camaras-e-ondas.md R6 | §Posse e autorização dos fluxos (1 ondas) |
| TR-camaras-006 | Spawn sorteia sempre 14 candidatos | camaras-e-ondas.md R7 | §Posse e autorização dos fluxos (quantidade completa antes da seleção) e Emenda Pactos (filtro de spawn) |
| TR-camaras-011 | Montagem pede reposicionar_maldicao e encontro_na_camara; acuada sem RNG | camaras-e-ondas.md R4-P, F6 | Parcial: Emenda Pactos (acuada em pontos fixos, sem RNG); montagem: ADR-0015 |
| TR-camaras-012 | Campo ordem por inimigo; filtro spawn_dist_acuada_px sem mudar o consumo | camaras-e-ondas.md R7-P, F3-P | Emenda Pactos (filtro de spawn pela acuada) |
| TR-camaras-014 | Câmara do chefe sem sorteio nem fluxos | camaras-e-ondas.md R14-P | Emenda Pactos (chefe não ganha fluxo) |
| TR-portas-001 | Fluxo portas com 4 reais fixos por escolha; forçadas consomem 0 | portas-e-recompensas.md R7 | §Posse e autorização dos fluxos (4 portas) e Emenda Pactos (forçadas consomem 0) |
| TR-portas-010 | Porta forçada chefe sem sorteio; trio (portas, 0, 5) sem reordenar | portas-e-recompensas.md R6-P, R9-P | Emenda Pactos (porta forçada do chefe) |
| TR-run-001 | Máquina de estados da run coordenada com o orquestrador | run-e-regioes.md R1 | Parcial: §Ciclo de vida e referências retidas (efeito dos estados sobre a fonte); a máquina: ADR-0015 |
| TR-run-002 | Ordem de início arma, seed, estado inicial, câmara 0, Transição | run-e-regioes.md R2 | §Ciclo de vida e referências retidas (seed ao confirmar a arma, entropia injetável) |
| TR-run-008 | nova_run com reset total e descarte da seed e dos fluxos | run-e-regioes.md R8 | §Ciclo de vida e referências retidas (descarte dos fluxos, marcador novo); reset dos demais sistemas: ADR-0015 |
| TR-run-010 | Várias regiões com índice da região na chave do RNG | run-e-regioes.md R10 | §Algoritmo e estado (região 0–255 na chave); orçamento: ADR-0015 |
| TR-run-014 | Run recebe pedir_dupla, dupla_confirmada etc.; seed em dupla_confirmada | run-e-regioes.md R2-P, R11-P | Emenda Pactos (seed em `dupla_confirmada`); sinais da run: ADR-0015 |
| TR-bencaos-003 | Fluxos bencaos e raridade com F7 e consumo fixo de 6 reais | bencaos-tradicoes.md R4 | §Posse e autorização dos fluxos (5 bencaos, 6 raridade) e §Operações e limites (F7) |
| TR-economia-006 | nova_run() zera coletados_run e mantém o saldo | economia-de-fragmentos.md R6 | não tratado aqui — ver ADR-0015 |
| TR-telemetria-009 | Seed e impressão do catálogo nas linhas de sessão e de run | telemetria-local.md R4 | §Seed, telemetria e fronteira da apresentação; impressão: ADR-0004 |
| TR-chefes-003 | Luta do chefe determinística sem consumir RNG | chefes.md R2, R6, R8 | Emenda Pactos (chefe não ganha fluxo; lacaios sem `elites`/`spawn`) |
| TR-vinculo-002 | Sorteio do encontro no fluxo pactos, consumo fixo de 4 reais mesmo com garantia | vinculo-e-pactos.md V6, F1, V40 | Emenda Pactos (finalidade 9) |
| TR-vinculo-003 | Escolha do Pacto antes da seed; seed em dupla_confirmada; estado inicial com dupla e perfil | vinculo-e-pactos.md V16, V16b, V40, V42 | Emenda Pactos (último item); tela: ADR-0012 e ADR-0015 |

## Evidência e critérios de implementação

O [experimento isolado](../../prototypes/rng-verificacao/README.md) passou 33 verificações em Godot 4.7.2, com zero falhas e saída 0. Cobre F1, F2, F4 e o ramo inteiro de F6, incluindo soma 2³¹. Os vetores esperados vêm do GDD aprovado. A comparação direta com a implementação TypeScript canônica, as demais operações e a integração com os sistemas reais permanecem pendentes.

Na implementação, os critérios de aceite do GDD devem incluir os seguintes casos de regressão.

- Finalidade, região ou câmara inválida e finalidade de outro dono produzem erro sem criar ou consumir fluxo.
- Um fluxo previamente obtido recusa sorteios depois de morte, vitória ou abandono, inclusive após começar outra run.
- Consumir mil saídas de IA conserva as sequências de ondas e portas nas suas respectivas chaves.
- Pesos inteiros com soma 2³¹ e saídas 0 e FFFFFFFF selecionam os extremos positivos corretamente. Soma acima do limite é recusada antes do avanço.
- Cada operação inválida preserva a próxima saída esperada. F7 com n=k=200 consome exatamente 200 valores. F8 conserva a lista original.
- Runs com os seis elementos idênticos reproduzem os registros estruturais. Trocar a quantidade de consumo de IA conserva esses registros.

O custo do milhão de avanços e dez mil derivações de AC-33, o lint, as telas e a telemetria ficam para a implementação e integração. A proposta também requer revisão dos limites de coleção e do caso de arredondamento do caminho real.
