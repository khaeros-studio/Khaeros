# ADR-0005 — RNG determinístico

## Status

Proposed · 2026-11-14

## Contexto e escopo

O [GDD de RNG](../../design/gdd/rng-com-seed.md) já aprova mulberry32, derivação por finalidade/região/profundidade e consumo fixo para os sorteios estruturais. Este ADR propõe a organização desses contratos em GDScript, a validade dos fluxos ao encerrar uma run e o tratamento dos limites numéricos.

Depende do ciclo da run ligado ao [ADR-0001](adr-0001-orquestrador-do-passo.md) e da ordem e impressão do catálogo do [ADR-0004](adr-0004-catalogo-de-dados.md). O contrato garante a estrutura quando coincidem seed, versão do jogo, impressão completa do conteúdo, estado inicial da run, escolhas de portas/bênçãos e usos de troca de oferta. Os candidatos de spawn são reproduzíveis. A escolha final entre candidatos pode depender da posição do jogador. O consumo de IA acompanha o combate.

## Decisão proposta

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
