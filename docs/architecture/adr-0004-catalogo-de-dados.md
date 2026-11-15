# ADR-0004 — Catálogo de dados

## Status

Proposed · 2026-11-14

## Contexto e dependências

O catálogo fornece definições e ajustes aos 22 sistemas do MVP. A ordem de suas listas participa dos sorteios reproduzíveis. Uma falha de validação impede iniciar a run, e a recarga de desenvolvimento retira os ajustes antigos antes de ler os novos.

Esta proposta concretiza R1–R12, os estados e os casos de recarga do [GDD de Conteúdo](../../design/gdd/conteudo-orientado-a-dados.md). Depende da composição e dos estados do [ADR-0001](adr-0001-orquestrador-do-passo.md) e da distinção entre definição e estado vivo do [ADR-0003](adr-0003-entidades-e-portadores.md). O [ADR-0002](adr-0002-canal-de-eventos.md) orienta notificações. O ADR-0005 usará a impressão do catálogo no contrato do RNG.

## Decisão proposta

### Carga e publicação

Um carregador na thread principal lê explicitamente o manifesto `assets/data/content_catalog.tres` e as definições por tipo na ordem gravada. O manifesto guarda entradas com tipo e caminho da definição. Isso permite registrar falhas de arquivos individuais e continuar a leitura das demais entradas. O catálogo em memória mantém uma lista ordenada por tipo e um índice por id. Consultas por id usam o índice, e listar ou filtrar usa a lista.

As classes de definição ficam em `src/content/` como `Resource`. Construtores aceitam os valores padrão exigidos pelo editor. Uma definição possui identidade de conteúdo por tipo e id. A identidade de instância do combatente pertence ao ADR-0003. Definições obsoletas continuam resolvendo por id e entram na impressão. Listar e filtrar as excluem por padrão, com opção explícita de inclusão.

A sequência é Não carregado → Carregando → Validando → Pronto ou Falhou. O carregador publica catálogo, impressão e ajustes juntos, apenas após zero erros. Avisos são registrados e permitem chegar a Pronto. Os módulos recebem suas dependências por injeção. O carregador centraliza o acesso a caminhos de definições e mantém a leitura síncrona até que uma medição do volume real justifique carregamento assíncrono.

### Validação e diagnóstico

A primeira passada coleta falhas de leitura, V1–V11 e regras por tipo. A segunda executa as regras cruzadas dos sistemas com os dados já carregados. Cada diagnóstico guarda arquivo, campo, regra, valor encontrado e nível. A apresentação segue uma ordem estável por tipo, posição no manifesto, regra e campo. Uma dependência ausente já diagnosticada impede apenas o cálculo que precisa dela. As outras checagens continuam.

O esquema de cada definição declara campos de conteúdo, tipos, obrigatoriedade, limites, valores padrão permitidos e regras entre campos. A validação distingue campo ausente de valor explicitamente gravado. A materialização de um Resource pode preencher defaults, portanto V1 precisa preservar a presença dos campos na leitura do arquivo de origem e validá-la na etapa de preparação do conteúdo. O fluxo de exportação deve executar essa validação antes de empacotar os recursos. Em runtime, V1 continua verificando estrutura e tipos do recurso carregado. A implementação deverá provar AC-09 com uma definição que omite um campo obrigatório e também possui default no script.

Os códigos e níveis dos donos permanecem nos respectivos GDDs. V5 e V9 rodam em debug e CI. V6 consulta as traduções importadas. V7 verifica o caminho dentro de `assets/art/export/` e usa `ResourceLoader.exists`. A varredura de órfãos e a comparação append-only do registro de ids acontecem em editor/CI. A pasta canônica usa CSV com importador `keep` e fica excluída da exportação, conforme R5.

### Imutabilidade e cópias

O catálogo compartilha definições por convenção de somente leitura, com verificação em testes. O estado vivo e as alterações de atributos ficam nos módulos donos. Uma cópia mutável que inclua definições externas exige duplicação profunda de todos os sub-recursos de dados. A cópia usa `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` nesse caso. A cópia fica fora do catálogo, e referências pesadas de apresentação devem ser evitadas nesse grafo de dados. Os caminhos de arte permanecem campos de texto do esquema.

A opção padrão de `duplicate_deep()` duplica recursos internos. Um recurso externo compartilhado requer atenção ao modo explícito. Essa precisão preserva a intenção de isolamento de R3 e AC-25. [Resource — modos de duplicação](https://docs.godotengine.org/en/stable/classes/class_resource.html#enum-resource-deepduplicatemode)

### Consulta e erros em execução

O catálogo expõe obter por tipo/id, existe, listar, filtrar e impressão completa/curta. Id ausente em obter retorna null e envia tipo, id e solicitante ao relator injetado. O relator padrão registra e sinaliza o erro, com parada opcional em debug. O relator de testes acumula o diagnóstico. A consulta existe responde sem gerar erro. As listas retornadas protegem a estrutura interna, enquanto as definições seguem o contrato de somente leitura.

### Recarga entre runs

O carregador recebe o estado da run por interface. Recarga em release ou durante uma run é recusada. Ao sair de Pronto, ele revoga o catálogo publicado e injeta ajustes vazios em Input, câmera, HUD, Tela de bênção, Feedback e Pipeline. O candidato novo é carregado usando `CACHE_MODE_IGNORE_DEEP` tanto no manifesto quanto nas definições. Esse modo alcança dependências externas. [ResourceLoader — modos de cache](https://docs.godotengine.org/en/stable/classes/class_resourceloader.html#enum-resourceloader-cachemode)

Sucesso recalcula a impressão e reinjeta os seis consumidores persistentes antes de permitir outra run. Falha descarta o candidato e deixa os consumidores sem ajustes, como exige o GDD. A tela de erros usa as entradas digitais previstas em Input R12. A próxima tentativa percorre a mesma sequência. Os sistemas de run recebem o catálogo apenas na construção da nova run.

### Impressão canônica

O serializador percorre somente os campos de conteúdo declarados no esquema, incluindo ids, flags de obsolescência e sub-recursos de dados. A lista de campos é ordenada pelo nome. Tipos e definições preservam a ordem explícita do manifesto, arrays preservam a ordem gravada e chaves de Dictionary são texto ordenado. Metadados do editor, ids de instância, caminhos dos scripts e propriedades internas da engine ficam fora do esquema. Caminhos de arte e chaves de tradução entram como texto.

R12 já fixa SHA-256, float64, inteiro de oito bytes e texto UTF-8. Para fechar as ambiguidades de codificação, este ADR propõe o seguinte protocolo.

| Elemento | Codificação proposta |
|---|---|
| Cabeçalho | Bytes ASCII `KHAEROS-CATALOG`, versão de formato uint32 little-endian e quantidade de tipos uint32 |
| Estruturas | Tags de um byte fixas no serializador para null, bool, int, float, texto, array, Dictionary e definição |
| bool | Um byte 0 ou 1 depois da tag |
| int | int64 com sinal em complemento de dois, little-endian |
| float | IEEE-754 float64 little-endian, zero negativo normalizado para positivo, rejeição de NaN e infinito |
| Texto | Tamanho em bytes UTF-8 como uint32 little-endian, seguido dos bytes, preservando o texto gravado |
| Array e Dictionary | Quantidade uint32 little-endian seguida dos elementos ou pares com tags |
| Definição | Tipo e id como texto, quantidade de campos uint32 e pares nome/valor em ordem alfabética |
| Sub-recurso de dados | Expansão pelos campos do próprio esquema no lugar da referência |

Cada tipo do manifesto é seguido da quantidade e das definições daquele tipo. Contagens e tamanhos fora de uint32 são erros de serialização. Ciclos de sub-recursos e valores fora do esquema são erros que impedem Pronto. Compartilhamento de um sub-recurso equivale a repetir seus valores na impressão. Alterar a ordem do manifesto altera a sequência de bytes.

O SHA-256 completo tem 64 hex, e a forma curta usa seus quatro primeiros hex em maiúsculas. Traduções e arquivos canônicos ficam fora da entrada. A versão do protocolo muda quando mudar a codificação. A implementação deve congelar um vetor completo de bytes e hash antes de usar a impressão em telemetria.

## Alternativas consideradas

| Alternativa | Consequência |
|---|---|
| Carregamento em background desde o MVP | Exige acompanhar conclusão e erros concorrentes. O volume e tempo real de carga ainda precisam ser medidos. |
| Descoberta por varredura de pasta em runtime | Introduz dependência da disposição dos arquivos e contraria o manifesto explícito e sua ordem. |
| Hash do arquivo .tres ou JSON genérico | A formatação, metadados e conversão de números podem mudar os bytes sem mudança dos campos de conteúdo. |
| Manter o catálogo anterior quando a recarga falha | Diverge do estado Falhou e da retirada dos ajustes especificados no GDD. |

## Validação e implementação futura

O [experimento de recursos](../../prototypes/catalogo-dados-verificacao/README.md) passou 16 verificações no Godot 4.7.2, com zero falhas e saída 0. Confirmou a leitura atualizada com IGNORE_DEEP, o isolamento da cópia ALL e o vetor conhecido SHA-256 de abc. O catálogo completo, o importador, a exportação e o protocolo canônico permanecem por implementar.

Os testes do catálogo devem cobrir os seguintes contratos do GDD.

- Carga com múltiplos arquivos inválidos acumula diagnósticos e bloqueia a run. Avisos isolados permitem iniciar.
- Ordem do manifesto, filtros de obsoletos e relator de ids ausentes respeitam R10.
- Uma definição compartilhada conserva seus valores depois que uma cópia mutável de dados externos é editada.
- Recarga durante run é recusada. Recarga válida reinjeta os consumidores. Recarga inválida deixa todos sem ajustes, e uma tentativa posterior válida permite iniciar.
- O vetor canônico completo coincide entre debug e release. Ordem de Dictionary não afeta a impressão, ordem de array afeta, zero negativo coincide com positivo, e alteração de tradução conserva o hash.
- Um export limpo preserva referências a recursos e traduções, exclui canon e passa pelas mesmas regras bloqueantes aplicáveis em runtime.

## Questões abertas

O AC-38 estabelece uma meta advisory de mediana de cinco cargas frias ≤ 250 ms e validação ≤ 30 ms para 30–60 definições. A máquina mínima ainda precisa ser definida. O experimento de APIs desta etapa usa dois recursos e fornece evidência funcional.

Preservação da presença de campos obrigatórios no preparo dos recursos e na exportação exige prova específica. O protocolo binário acima é uma escolha técnica proposta e ainda precisa de vetor de referência e revisão. Tempo máximo de carga, custo de serialização, exportação real e paridade entre máquinas ficam para a implementação.
