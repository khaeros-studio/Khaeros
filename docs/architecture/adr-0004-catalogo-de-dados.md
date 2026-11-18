# ADR-0004 — Catálogo de dados

## Status

Accepted · 2026-11-16 (aprovado pelo usuário; Proposed em 2026-11-14)

## Date
2026-11-16

## Last Verified

2026-11-17 (experimentos EX-0004-NV: PC de referência fixado com CPU/GPU/OS completos e medianas 160,8 ms / 86,2 ms ≤ 250 ms; `HashingContext` SHA-256, `CACHE_MODE_IGNORE_DEEP`, CSV `keep` com `exclude_filter="assets/data/canon/*"` obrigatório e `Resource.DEEP_DUPLICATE_ALL` marcados como Verificados). Antes: 2026-11-16 (emenda Pactos; TR-armas-008; seções Engine Compatibility e ADR Dependencies acrescentadas pela revisão de 2026-11-15)

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7, pin 4.7.2 (instalado, sem gap) |
| **Domain** | Core (Resources / File I/O) |
| **Layer** | Foundation |
| **Knowledge Risk** | MEDIUM: `duplicate_deep()` é pós-corte (4.5) e está na referência; o resto do carregador não está |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md` (4.5: `duplicate_deep()`), `deprecated-apis.md` (`duplicate()` em recurso aninhado → `duplicate_deep()`), `current-best-practices.md` |
| **Post-Cutoff APIs Used** | `Resource.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` (4.5; `duplicate_deep()` está na referência; a constante `Resource.DEEP_DUPLICATE_ALL` = 2 e o isolamento de sub-recurso externo foram **Verificados (EX-0004-NV, 2026-11-16)**) |
| **Verification Required** | Todos os itens **Verificados (EX-0004-NV, 2026-11-16)** no editor e `.pck` exportado (ver "Verificação de engine (2026-11-16)"): (1) `HashingContext` SHA-256 sobre int64 LE, float64 LE e UTF-8 idêntico entre editor, `.pck` e Python `hashlib` (`b755d9ea874182a58e4ba312ff981aee1ba4960eaaed9518e1924a2d30eedad2`); (2) `ResourceLoader.load(..., CACHE_MODE_IGNORE_DEEP)` relendo manifesto de 40 entradas e sub-recurso externo editado no disco (40/40); (3) CSV com importador `keep` em `assets/data/canon/` sem gerar `.translation`, exigindo `exclude_filter="assets/data/canon/*"` obrigatório no preset de exportação; (4) `Resource.DEEP_DUPLICATE_ALL` copiando sub-recurso externo sem afetar o original; (5) tempo de carga do AC-38 medido no PC de referência: mediana `160,8 ms` em texto no editor e `86,2 ms` em binário no `.pck`, ambos `< 250 ms`. Repetir no `.exe` de release quando os templates 4.7.2 forem instalados |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | [ADR-0001](adr-0001-orquestrador-do-passo.md): composição e estados; [ADR-0002](adr-0002-canal-de-eventos.md): notificações; [ADR-0003](adr-0003-entidades-e-portadores.md): definição × estado vivo |
| **Enables** | ADR-0005 (impressão no contrato do RNG), ADR-0009, ADR-0010, ADR-0011, ADR-0012, ADR-0014, ADR-0015, ADR-0017 e todo módulo que lê definições |
| **Blocks** | Toda story que crie ou leia uma definição de conteúdo |
| **Ordering Note** | Sem ciclo: 0001 → 0002 → 0003 → 0004 |

## Contexto e dependências

O catálogo fornece definições e ajustes aos 22 sistemas do MVP. A ordem de suas listas participa dos sorteios reproduzíveis. Uma falha de validação impede iniciar a run, e a recarga de desenvolvimento retira os ajustes antigos antes de ler os novos.

Esta proposta concretiza R1–R12, os estados e os casos de recarga do [GDD de Conteúdo](../../design/gdd/conteudo-orientado-a-dados.md). Depende da composição e dos estados do [ADR-0001](adr-0001-orquestrador-do-passo.md) e da distinção entre definição e estado vivo do [ADR-0003](adr-0003-entidades-e-portadores.md). O [ADR-0002](adr-0002-canal-de-eventos.md) orienta notificações. O ADR-0005 usará a impressão do catálogo no contrato do RNG.

## Decision

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

### Emenda (2026-11-16): TR-armas-008 e Doutrina de Pactos

- **TR-armas-008 (sem campo novo).** A chave de descrição de arma e de Ataque/Especial é **derivada**: `<chave_nome>_DESC` (`armas-das-doutrinas.md` R4, R8; AC-AR-33/34). O esquema não ganha campo; V6 confere a chave derivada na tradução importada como confere a de nome. A V5 (só CI e debug) valida os nomes canônicos das armas e dos seus Ataque/Especial contra `assets/data/canon/` (Besta do Vínculo, *Virote*, *Chamado do Pacto*), e o termo de categoria "Maldições" nas chaves `CURSE_*`.
- **Tipos novos no catálogo** (nomes do GDD de Conteúdo, R1-P; significado dos donos): `CurseDef` (espécie de Maldição; 4 no MVP: `vulto_mudo`, `espreitador_da_fenda`, `baluarte_de_cinza`, `soberano_do_limiar`), `BossPatternDef` (sub-recurso na lista `padroes` do `EnemyDef` do chefe; entra na impressão pela expansão de sub-recurso), e os únicos `MaldicoesTuning`, `VinculoTuning` (parâmetros de vínculo **e** de encontro: `chance_encontro`, `pity_runs`, `indices_encontro`, `frac_vida_acuada` etc.) e `ChefesTuning`. Ampliados: `HudTuning` (17 campos), `RunTuning` (`camaras_jogaveis` 7, `arma_padrao` aceita `pactos`), `WeaponDef pactos`, `AttackDef` forma `chamado` (só no slot `especial`), `EnemyDef` com `padroes` opcional, `RegionDef limiar` com `chefe = soberano_do_limiar`.
- **Outros tipos novos vindos dos ADRs**: `TecnicaDef` (técnica combinada; proposto pelo ADR-0017, ainda **não** está na R1-P do GDD de Conteúdo, que lista só `CurseDef` com `efeito_saida`/`efeito_entrada`; o dono do formato confirma), `SomDef` e `AudioTuning` (ADR-0016). Entram pelo mesmo manifesto, esquema e validação.
- **Decisão (Conteúdo OQ 9): forma do `BossPatternDef`.** Sub-recurso **embutido** (built-in, sem arquivo próprio) no `.tres` do `EnemyDef`, em `@export var padroes: Array[BossPatternDef]` tipado; a ordem do array é a ordem dos padrões e entra na impressão (array preserva ordem). Não tem id próprio nem entrada no manifesto: é identificado por (id do `EnemyDef`, índice). Motivo: um padrão só existe dentro do seu chefe, e arquivo externo pediria `DEEP_DUPLICATE_ALL` e uma entrada a mais por padrão sem ganho.
- **Ids de `CurseDef` são chave do perfil salvo** (seção `[vinculo]`, ADR-0013): nunca mudam nem são reaproveitados (registro append-only da V9 vale para eles); um id sumido do catálogo é preservado no perfil como chave desconhecida. A ordem dos `CurseDef` no manifesto é estável e só cresce no fim, porque o sorteio de espécie (fluxo `pactos`, ADR-0005) itera essa lista.
- `CurseDef soberano_do_limiar` e `EnemyDef soberano_do_limiar` têm o mesmo id em tipos diferentes; o índice é por (tipo, id), sem colisão. Nada de Pactos passa por `mapa_ids.csv`.
- Regras novas dos donos rodam nas duas passadas sem mudar o carregador: ML1–ML8, VP1–VP9, CH1–CH8 (TR-chefes-001; o GDD de Chefes ganhou CH8 na emenda de 2026-11-15; o chefe é `EnemyDef` + `BossPatternDef` + `ChefesTuning`, validados por CH1–CH8), PV8, WV10/WV11. Os `*Tuning` novos entram na reinjeção da recarga junto dos seis consumidores persistentes só se o dono for persistente entre runs (hoje nenhum dos três é: chegam na construção da run).

### Emenda (2026-11-16): importação, paridade, esquema do WeaponDef e PC de referência

- **Script de importação e paridade (TR-conteudo-014).** `tools/content-import/` converte as tabelas F1–F6 do cânone (CSV em `assets/data/canon/`, importador `keep`) em `.tres` do catálogo, na ordem do manifesto, e é rodado em editor/CI, nunca em runtime. O teste de paridade (`tests/integration/content/`, bloqueante em CI) importa o CSV, carrega os `.tres` pelo carregador de produção e compara campo a campo, mais a impressão canônica completa. Divergência falha o CI. Entrada, saída e comparação ficam fixas aqui; a implementação do script é de `tools-programmer`.
- **PC de referência e harness (TR-conteudo-015).** A meta do AC-38 (mediana de 5 cargas frias ≤ 250 ms; validação ≤ 30 ms) é medida por um harness em `tests/performance/content/` (`Time.get_ticks_usec` em torno de carga e validação, cinco repetições com cache frio, mediana registrada em `production/qa/evidence/`). O **PC de referência fixado** (decisão de 2026-11-16, válida para `TR-conteudo-015` e todos os orçamentos de CPU dos ADRs) é: **`AMD Ryzen 5 5600H (6C/12T), 16 GB RAM, SSD NVMe, GPU RTX 3050 Laptop, Windows 11 Home 10.0.26300`**. Medição realizada em `EX-0004-NV` (40 `.tres` pais + 40 filhos externos, 5 processos novos): **mediana `160,8 ms` em texto no editor e `86,2 ms` em binário no `.pck` exportado, ambos `< 250 ms`**. A máquina mínima de venda é decisão de lançamento, fora do MVP.
- **Esquema do `WeaponDef` (TR-armas-001).** Exatamente 7 campos: `id`, `doutrina`, `chave_nome`, `vida_max`, `velocidade`, `ataque`, `especial`. `ataque` e `especial` são sub-recursos `AttackDef` **embutidos** no `.tres` da arma (mesma regra do `BossPatternDef`), com a forma (`chamado` só no slot `especial`). Campo ausente ou **propriedade desconhecida no `.tres` é erro de carga** (a run não começa; AC-AR-01), checado na leitura do texto do arquivo em editor/CI, porque o Godot ignora propriedade desconhecida em silêncio; em runtime vale a lista de propriedades do script. Fecha o OQ 9 de Armas do lado do formato; o dono do Conteúdo confirma a regra.

## Alternativas consideradas

| Alternativa | Consequência |
|---|---|
| Carregamento em background desde o MVP | Exige acompanhar conclusão e erros concorrentes. O volume e tempo real de carga ainda precisam ser medidos. |
| Descoberta por varredura de pasta em runtime | Introduz dependência da disposição dos arquivos e contraria o manifesto explícito e sua ordem. |
| Hash do arquivo .tres ou JSON genérico | A formatação, metadados e conversão de números podem mudar os bytes sem mudança dos campos de conteúdo. |
| Manter o catálogo anterior quando a recarga falha | Diverge do estado Falhou e da retirada dos ajustes especificados no GDD. |

## Consequences

### Positivas

- Uma só porta de entrada para todo conteúdo: manifesto explícito, ordem estável e validação em duas passadas que acumula todos os erros antes de bloquear a run.
- A impressão canônica SHA-256 independe da formatação do `.tres`, sustentando o contrato de reprodução do RNG e a telemetria.
- Tipos novos (Pactos, áudio) entram pelo mesmo manifesto, esquema e validação, sem mudar o carregador.
- Tuning chega aos módulos por injeção, testável com relator de erros de teste.

### Negativas

- Cada definição nova exige entrada manual no manifesto e esquema declarado; ids nunca podem ser renomeados nem reaproveitados.
- Imutabilidade das definições é convenção verificada em testes, não garantia da engine.
- A presença de campos (V1) e propriedades desconhecidas só é verificável na leitura do texto em editor/CI, porque o Godot preenche defaults e ignora propriedades em silêncio.
- Carga síncrona na thread principal; assíncrona só se a medição justificar.

### Riscos

- `DEEP_DUPLICATE_ALL`, `CACHE_MODE_IGNORE_DEEP`, `HashingContext` SHA-256 e CSV `keep` foram **Verificados (EX-0004-NV, 2026-11-16)**. O CSV com importador `keep` **não** sai do export sozinho: o preset precisa de `exclude_filter="assets/data/canon/*"` obrigatório e o CI precisa checar (ver "Verificação de engine (2026-11-16)").
- Protocolo binário da impressão sem vetor de referência congelado do catálogo completo; mudança acidental quebra reprodutibilidade (mitigação: versão do formato e vetor antes da telemetria; vetor primitivo já congelado em `EX-0004-NV`).
- AC-38 com PC de referência fixado (`AMD Ryzen 5 5600H (6C/12T), 16 GB RAM, SSD NVMe, GPU RTX 3050 Laptop, Windows 11 Home 10.0.26300`) e medianas medidas (`160,8 ms` texto / `86,2 ms` `.pck` < `250 ms`); falta apenas repetir no `.exe` do template de release.
- Alterar a ordem do manifesto muda a impressão e a ordem dos sorteios (mitigação: ordem de `CurseDef` só cresce no fim; teste append-only em CI).

## GDD Requirements Addressed

| TR-ID | Requisito | Origem | Como este ADR atende |
|---|---|---|---|
| TR-conteudo-001 | Tipos de definição como Resource, com formato, campos e unidades por tipo | conteudo-orientado-a-dados.md R1 | §Carga e publicação (classes `Resource` em `src/content/`) e §Validação e diagnóstico (esquema por definição) |
| TR-conteudo-002 | Ids snake_case únicos por tipo, append-only | conteudo-orientado-a-dados.md R2 | §Validação e diagnóstico (comparação append-only do registro de ids em editor/CI); Emenda Pactos (V9 vale para `CurseDef`) |
| TR-conteudo-003 | Definição só de leitura em execução; cópia mutável por duplicate_deep | conteudo-orientado-a-dados.md R3 | §Imutabilidade e cópias |
| TR-conteudo-004 | Manifesto único explícito, sem varredura; teste de órfãos em CI | conteudo-orientado-a-dados.md R4 | §Carga e publicação (manifesto explícito) e §Validação e diagnóstico (varredura de órfãos em editor/CI) |
| TR-conteudo-005 | Layout de assets/data/; cópia canônica em CSV excluída do export | conteudo-orientado-a-dados.md R5 | §Carga e publicação (`assets/data/content_catalog.tres`) e §Validação e diagnóstico (CSV `keep` excluído do export) |
| TR-conteudo-006 | Unidades do Godot; TICK_RATE 60 conferido na carga; F7 segundos para passos | conteudo-orientado-a-dados.md R6 | Parcial: unidades e limites entram no esquema (§Validação e diagnóstico); conferência do TICK_RATE e conversão segundos→passos não tratadas aqui — ver ADR-0001 |
| TR-conteudo-007 | Definições guardam chaves de tradução; V6 confere a tabela | conteudo-orientado-a-dados.md R7 | §Validação e diagnóstico (V6 consulta as traduções importadas) e §Impressão canônica (chaves como texto, traduções fora) |
| TR-conteudo-008 | Dado só aponta para chaves registradas pelos donos; ausente é erro V4 | conteudo-orientado-a-dados.md R8 | §Validação e diagnóstico (V1–V11 e regras dos donos; dependência ausente diagnosticada) |
| TR-conteudo-009 | Carga síncrona antes do menu, coleta todos os erros e bloqueia a run | conteudo-orientado-a-dados.md R9 | §Carga e publicação (sequência de estados, publicação só com zero erros) e §Validação e diagnóstico |
| TR-conteudo-010 | Consulta por injeção (obter, existe, listar, filtrar) com relator injetado | conteudo-orientado-a-dados.md R10 | §Consulta e erros em execução |
| TR-conteudo-011 | Impressão SHA-256 sobre serialização canônica na ordem do manifesto | conteudo-orientado-a-dados.md R12 | §Impressão canônica |
| TR-conteudo-012 | Estados de carga e recarga só em debug e fora de run, com revogação e reinjeção | conteudo-orientado-a-dados.md R9 | §Recarga entre runs |
| TR-conteudo-013 | Lista canônica copiada só de leitura do cânone | conteudo-orientado-a-dados.md R11 | §Validação e diagnóstico (pasta canônica CSV `keep`) e Emenda TR-armas-008 (V5 contra `assets/data/canon/`) |
| TR-conteudo-014 | Script de importação F1-F6 com teste de paridade | conteudo-orientado-a-dados.md F1-F6 | Emenda importação (script e paridade) |
| TR-conteudo-015 | Orçamento de carga: mediana até 250 ms e validação até 30 ms (advisory) | conteudo-orientado-a-dados.md AC-38 | Emenda importação (PC de referência e harness) e Questões abertas |
| TR-conteudo-016 | Tipos CurseDef, BossPatternDef, MaldicoesTuning, VinculoTuning e ChefesTuning | conteudo-orientado-a-dados.md R1-P, OQ 9 | Emenda Pactos (tipos novos e decisão da forma do `BossPatternDef`) |
| TR-conteudo-017 | Mesmo id em CurseDef e EnemyDef; ids de espécie nunca mudam | conteudo-orientado-a-dados.md R2-P | Emenda Pactos (índice por tipo e id; ids de `CurseDef` são chave do perfil) |
| TR-conteudo-018 | Validação ampliada V4, V5, V8 e códigos ML, VP e CH | conteudo-orientado-a-dados.md R9-P | Emenda Pactos (regras novas nas duas passadas sem mudar o carregador) |
| TR-conteudo-019 | Ordem estável do manifesto de CurseDef para o sorteio do Vínculo | conteudo-orientado-a-dados.md R10-P | Emenda Pactos (ordem dos `CurseDef` estável, só cresce no fim) |
| TR-rng-004 | Sorteios iteram na ordem do manifesto | rng-com-seed.md R4 | §Carga e publicação (lista ordenada por tipo na ordem do manifesto; listar usa a lista); iteração dos sorteios: ADR-0005 |
| TR-rng-008 | Contrato de reprodução com seis elementos, incluindo a impressão do catálogo | rng-com-seed.md R7 | §Impressão canônica (fornece a impressão); o contrato: ADR-0005 |
| TR-input-012 | Tuning do catálogo validado (InputTuning) | input-e-controle.md R12 | §Carga e publicação (injeção) e §Recarga entre runs (Input entre os seis consumidores persistentes) |
| TR-cena-002 | 1 unidade = 1,5 px, convertida só na importação | cena-3-4-e-camera.md R2 | não tratado aqui — ver ADR-0011 |
| TR-cena-012 | Tuning do catálogo validado (CameraTuning) | cena-3-4-e-camera.md R11 | §Carga e publicação e §Recarga entre runs (câmera entre os consumidores persistentes) |
| TR-modificadores-005 | Tabela fechada das 21 chaves de tipo de efeito, entregue ao validador | modificadores-e-atributos.md R5 | Parcial: §Validação e diagnóstico (regras dos donos nas duas passadas); a tabela: ADR-0009 |
| TR-modificadores-013 | Tuning do catálogo validado; valor já escalado | modificadores-e-atributos.md R8 | §Carga e publicação e §Validação e diagnóstico; escalonamento: ADR-0009 |
| TR-modificadores-016 | Origens vinculo, especie e espelho e lista restrita de atributos do portador da Maldição | modificadores-e-atributos.md R2, R3 | não tratado aqui — ver ADR-0009 |
| TR-pipeline-013 | Tuning do catálogo validado (VisualTuning) | pipeline-visual.md R12 | §Carga e publicação e §Recarga entre runs (Pipeline entre os consumidores persistentes) |
| TR-feedback-014 | Tuning do catálogo validado (FeedbackTuning) | feedback-de-combate.md Tuning Knobs | §Carga e publicação e §Recarga entre runs (Feedback entre os consumidores persistentes) |
| TR-combate-nucleo-016 | Tuning do CombatTuning validado (CV1-CV21) | combate-nucleo.md R15 | §Carga e publicação e §Validação e diagnóstico (regras do dono); chega na construção da run (§Recarga entre runs) |
| TR-armas-001 | WeaponDef com exatamente 7 campos e AttackDef como sub-recurso | armas-das-doutrinas.md R1, AC-AR-01 | Emenda importação (esquema do `WeaponDef`) |
| TR-armas-002 | Arma sem regra própria em código | armas-das-doutrinas.md R1, AC-AR-07 | Emenda importação (tudo nos sub-recursos `AttackDef`); execução das formas: ADR-0010 |
| TR-armas-008 | Chave derivada <chave_nome>_DESC e nomes canônicos validados | armas-das-doutrinas.md R4, R8, AC-AR-33 | Emenda TR-armas-008 |
| TR-armas-009 | Validações cruzadas AV1-AV8 na segunda passada | armas-das-doutrinas.md Formulas, AC-AR-32 | §Validação e diagnóstico (segunda passada e relatório em ordem estável) |
| TR-armas-010 | Tuning do ArmasTuning e dos WeaponDef validados | armas-das-doutrinas.md Tuning Knobs, R2 | §Carga e publicação, §Validação e diagnóstico e Emenda importação (esquema do `WeaponDef`) |
| TR-armas-014 | AV9 forma chamado só no slot especial; ML8 na 2ª passada | armas-das-doutrinas.md AV9 | Emenda Pactos (`AttackDef` forma `chamado` só no slot `especial`; ML8 na 2ª passada) e Emenda importação |
| TR-selo-013 | Tuning do SealTuning validado (SV1-SV12) | selo-e-fluxo.md R7, AC-SF-24 | §Carga e publicação e §Validação e diagnóstico |
| TR-status-011 | Tuning do StatusTuning validado (ST1-ST11) | efeitos-de-status.md R9 | §Carga e publicação e §Validação e diagnóstico |
| TR-telegrafos-005 | Formas e dimensões derivadas do EnemyDef, fonte única | telegrafos.md R5 | não tratado aqui — ver ADR-0014 |
| TR-telegrafos-010 | Validação TV1-TV6 pelo mesmo derivar() usado em jogo | telegrafos.md R10 | Parcial: §Validação e diagnóstico (segunda passada roda regras dos donos); `derivar()`: ADR-0014 |
| TR-telegrafos-011 | Tuning do TelegraphTuning validado | telegrafos.md R10 | §Carga e publicação e §Validação e diagnóstico |
| TR-ia-014 | Tuning de IATuning, EnemyDef, EliteRules (IV1-IV9) | ia-de-inimigos-e-elites.md R14 | §Carga e publicação e §Validação e diagnóstico |
| TR-movimento-013 | Tuning do MovementTuning validado (MV1-MV8) | movimento-e-esquiva.md R11 | §Carga e publicação e §Validação e diagnóstico |
| TR-camaras-010 | Tuning de WaveRules e RoomTuning validado (WV1-WV9) | camaras-e-ondas.md R15 | §Carga e publicação e §Validação e diagnóstico; WV10/WV11 na Emenda Pactos |
| TR-portas-007 | Tuning da RewardTable validado (PV1-PV7) | portas-e-recompensas.md R10 | §Carga e publicação e §Validação e diagnóstico; PV8 na Emenda Pactos |
| TR-run-003 | Sequência pela RegionDef e camaras_jogaveis; RN3 | run-e-regioes.md R3, R9 | Emenda Pactos (`RunTuning.camaras_jogaveis`, `RegionDef limiar`); a sequência da run: ADR-0015 |
| TR-run-011 | Tuning do RunTuning validado (RN1-RN3) | run-e-regioes.md Tuning Knobs | §Carga e publicação e §Validação e diagnóstico |
| TR-bencaos-001 | Pool de 18 BoonDef na ordem do manifesto | bencaos-tradicoes.md R1, R4 | §Carga e publicação (listar na ordem do manifesto); oferta: ADR-0005 |
| TR-bencaos-010 | Tuning de BencaosTuning e RarityTable (BN1, BN2) | bencaos-tradicoes.md Tuning Knobs | §Carga e publicação e §Validação e diagnóstico |
| TR-economia-002 | Tuning de EconomyRates; cada taxa tem um só dono | economia-de-fragmentos.md R2 | §Carga e publicação e §Validação e diagnóstico |
| TR-hud-010 | Tuning do HudTuning validado (HU1-HU14) | hud.md R14 | §Recarga entre runs (HUD entre os consumidores persistentes) e Emenda Pactos (`HudTuning` ampliado) |
| TR-tela-bencao-002 | CartaView montada pela Bênçãos a partir do BoonDef | tela-de-bencao-e-carta.md R2 | não tratado aqui — ver ADR-0012 |
| TR-tela-bencao-012 | Tuning do TelaBencaoTuning validado (TB1-TB10) | tela-de-bencao-e-carta.md AC-TB-35 | §Recarga entre runs (Tela de bênção entre os consumidores persistentes) |
| TR-telemetria-009 | Seed e impressão do catálogo (64 e 4 hex) | telemetria-local.md R4 | §Impressão canônica (64 hex e forma curta de 4 hex); seed: ADR-0005 |
| TR-telemetria-010 | Tuning do TelemetriaTuning validado | telemetria-local.md Tuning Knobs | §Carga e publicação e §Validação e diagnóstico |
| TR-maldicoes-011 | Técnica combinada por dados: Saída e depois Entrada no mesmo passo | maldicoes.md R12, F5 | Parcial: Emenda Pactos (`TecnicaDef` entra pelo manifesto); semântica no passo: ADR-0017 |
| TR-maldicoes-017 | Catálogo CurseDef, TecnicaDef e MaldicoesTuning validado por ML1-ML8 | maldicoes.md R3, R16, R17 | Emenda Pactos (tipos novos e ML1–ML8 nas duas passadas) |
| TR-chefes-001 | Chefe como EnemyDef com BossPatternDef e ChefesTuning validados por CH1-CH8 | chefes.md R1, R11 | Emenda Pactos (forma do `BossPatternDef`, CH1–CH8) |
| TR-chefes-006 | Contorno secundário tracejado por raio_secundario_px, só desenho | chefes.md R11, CH8 | Parcial: Emenda Pactos (CH8 na validação); desenho: ADR-0014 |
| TR-vinculo-017 | Tuning de VinculoTuning (VP1-VP9) e CurseDef.memorias | vinculo-e-pactos.md Formulas, VP1-VP9, V22 | Emenda Pactos (`VinculoTuning`, VP1–VP9) |
| TR-save-004 | Carga do save depois do catálogo Pronto e antes da escolha de arma | save-e-perfil.md R4 | §Carga e publicação (estado Pronto publicado antes do menu); sequência do Save: ADR-0013 |
| TR-save-005 | Catálogo em Falhou deixa o Save em Sem gravação | save-e-perfil.md States, AC-SP-21 | §Carga e publicação (Falhou não publica catálogo); reação do Save: ADR-0013 |

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

O AC-38 estabelece uma meta advisory de mediana de cinco cargas frias ≤ 250 ms e validação ≤ 30 ms para 30–60 definições. O **PC de referência** para `TR-conteudo-015` e para os orçamentos de CPU foi **fixado** em `AMD Ryzen 5 5600H (6C/12T), 16 GB RAM, SSD NVMe, GPU RTX 3050 Laptop, Windows 11 Home 10.0.26300`, com medianas medidas em `EX-0004-NV` de `160,8 ms` (texto no editor) e `86,2 ms` (binário no `.pck`), ambas `< 250 ms`.

Preservação da presença de campos obrigatórios no preparo dos recursos e na exportação exige prova específica na story. O protocolo binário acima teve seus tipos primitivos verificados em `EX-0004-NV` e ganhará o vetor do catálogo completo antes da telemetria. A medição final no `.exe` de release fica para quando os templates de exportação 4.7.2 forem instalados.

## Verificação de engine (2026-11-16)

Fonte: Completion Notes em `production/epics/experimentos-de-engine/` e `production/qa/evidence/experimentos/ex-0004-nv-catalogo.md`. Editor 4.7.2 standard + `.pck` exportado, Windows 11 (`AMD Ryzen 5 5600H (6C/12T), 16 GB RAM, SSD NVMe, GPU RTX 3050 Laptop, Windows 11 Home 10.0.26300`).

- **Verificado (EX-0004-NV, 2026-11-16) — `HashingContext` SHA-256:** sobre int64 LE (`encode_s64(-1234567890123)`), float64 LE (`encode_double(0.1)`) e UTF-8 (`"Khaeros ação vínculo"`), o SHA-256 `b755d9ea874182a58e4ba312ff981aee1ba4960eaaed9518e1924a2d30eedad2` é idêntico no editor (headless e janela), no `.pck` exportado e na referência independente em Python (`hashlib`).
- **Verificado (EX-0004-NV, 2026-11-16) — `CACHE_MODE_IGNORE_DEEP`:** `ResourceLoader.load(p, "", CACHE_MODE_IGNORE_DEEP)` num manifesto de 40 entradas relê do disco tanto o recurso pai quanto o sub-recurso externo editado (40/40), mantendo a instância antiga intacta.
- **Verificado (EX-0004-NV, 2026-11-16) — CSV `keep` (`exclude_filter="assets/data/canon/*"` obrigatório):** com `importer="keep"`, o CSV em `assets/data/canon/` não gera `.translation` e é legível por `FileAccess`, mas **entra no `.pck` por padrão** se não for filtrado. **Exigência obrigatória:** o preset de exportação deve configurar `exclude_filter="assets/data/canon/*"` (confirmado no `.pck`: `ERR_FILE_NOT_FOUND` para `canon/teste.csv` e presença preservada de `outro/controle.csv`), e o CI deve falhar se algum arquivo de `assets/data/canon/` constar no pacote exportado.
- **Verificado (EX-0004-NV, 2026-11-16) — `Resource.DEEP_DUPLICATE_ALL`:** constante existe em `ClassDB` (`Resource.DeepDuplicateMode`, valor `2`) e `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` copia sub-recursos externos sem compartilhar referência com o original (enquanto `duplicate_deep()` padrão compartilha o filho externo).
- **Verificado (EX-0004-NV, 2026-11-16) — Carga síncrona (AC-38 / `TR-conteudo-015`):** para 40 `.tres` pais + 40 filhos externos (80 recursos) em 5 processos novos no PC de referência fixado (`AMD Ryzen 5 5600H (6C/12T), 16 GB RAM, SSD NVMe, GPU RTX 3050 Laptop, Windows 11 Home 10.0.26300`), a mediana medida foi de **`160,8 ms` em texto no editor** e **`86,2 ms` em binário no `.pck`**, ambos `< 250 ms`.
- **Pendência pós-MVP / release:** os templates de exportação 4.7.2 não estão instalados; repetir a paridade do hash e o tempo de carga no binário `.exe` de release quando instalados.
