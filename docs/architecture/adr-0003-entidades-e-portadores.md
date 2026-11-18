# ADR-0003 — Representação de entidades e portadores

## Status

Accepted · 2026-11-16 (aprovado pelo usuário; Proposed em 2026-11-14)

## Date
2026-11-16

## Last Verified

2026-11-16 (emenda Pactos; seções Engine Compatibility e ADR Dependencies acrescentadas pela revisão de 2026-11-15)

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7, pin 4.7.2 (instalado, sem gap) |
| **Domain** | Core (Scripting) |
| **Layer** | Foundation |
| **Knowledge Risk** | LOW: só `RefCounted`, `Array[T]` tipado e `Resource` imutável por convenção |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `current-best-practices.md` |
| **Post-Cutoff APIs Used** | Nenhuma. Regra do 4.7 vale para qualquer `override` com retorno não-void (exige `return` explícito) |
| **Verification Required** | Feita no experimento da seção "Verificação no Godot 4.7.2". Pendente só a medição de alocações e cópias com os sistemas reais |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | [ADR-0001](adr-0001-orquestrador-do-passo.md): ordem do passo e varredura de mortes; [ADR-0002](adr-0002-canal-de-eventos.md): eventos desvinculados do estado vivo |
| **Enables** | ADR-0004, ADR-0006, ADR-0008, ADR-0009, ADR-0010, ADR-0014, ADR-0017 (`MaldicaoRef`) |
| **Blocks** | Toda story que guarde estado de combatente |
| **Ordering Note** | Sem ciclo: 0001 → 0002 → 0003 |

## Context

A simulação processa os inimigos em ordem estável e precisa rodar sem uma cena. IA, Combate, Movimento, Selo, Status e Telégrafos consultam partes diferentes do mesmo estado. O catálogo carrega definições compartilhadas, como `EnemyDef`, e a Apresentação consome eventos tipados e consultas. Este ADR propõe como representar o estado vivo e preservar a posse dos campos. Depende dos [ADRs 0001](adr-0001-orquestrador-do-passo.md) e [0002](adr-0002-canal-de-eventos.md), ambos propostos.

## Decision

### Decisões 1–5 (proposta de 2026-11-14)

1. **Estado vivo em `RefCounted`.** `InimigoRef` e `JogadorRef` agrupam o estado de cada combatente junto com a referência à sua definição. O `Portador` mantém atributos derivados, modificadores e gatilhos por combatente. As definições do catálogo são `Resource` e são tratadas como imutáveis pelos consumidores durante a run. Os `Node2D` da Apresentação consomem dados da simulação e gerenciam seu próprio ciclo visual.
2. **Identidade na run.** A IA atribui a cada inimigo uma sequência crescente na ordem de surgimento, incluindo inimigos ainda na fase Surgindo. O identificador é estável durante a run. A IA anexa novos inimigos à lista e remove os mortos preservando a ordem dos sobreviventes. A posição no array pode mudar e serve apenas para armazenamento. A lista reinicia com a run e a Apresentação descarta suas associações nessa fronteira.
3. **Posse dos campos por sistema.** A IA possui lista, fases, timers e posição normal do inimigo. O Combate possui Vida, escudo, impacto e cambaleio, resolve as mortes na ordem do passo e solicita à IA a remoção. O Movimento possui posição, cargas e esquiva do jogador. Modificadores possui atributos, fontes e gatilhos. Status possui seus três efeitos por inimigo, e Selo possui a marca `no_selo` e o Fluxo. As consultas projetam os campos necessários. Mudanças passam pela interface do módulo dono.
4. **Telégrafos em armazenamento reutilizável.** Telégrafos possui slots internos, com capacidade inicial igual ao teto validado no catálogo (24 no MVP de fábrica). O módulo associa até um telégrafo ativo a cada identificador de inimigo. O dono é reconsultado para obter a âncora atual. O estado terminal é copiado para a Apresentação com os dados necessários ao efeito visual, inclusive quando o dono morre. A vaga volta a ficar disponível quando a regra deixa de contar o telégrafo como ativo. A geometria, a contagem de vagas e o momento preciso de liberação ficam para o ADR-0014.
5. **Limites de referência.** Consultas para a Apresentação e eventos entregam identificadores e valores desvinculados do estado vivo. Os módulos de regra que recebem `InimigoRef` nos contratos síncronos usam a referência durante a chamada. Um resultado guardado além da chamada mantém o identificador e revalida a consulta quando necessário. O combatente pode possuir seu portador, e o portador recebe dados sem referência forte de volta ao combatente. Eventos e consultas também evitam ciclos de referências.

### Varredura de mortes

Na varredura de mortes, cada passe do Combate começa com uma lista ordenada dos inimigos com Vida ≤ 0. O Combate copia posição e marcas de elite e chefe para o evento ao remover cada entidade via IA. Mortes geradas durante o passe entram na lista do passe seguinte, conforme Combate R14. Esse retrato evita modificar a lista viva enquanto ela está sendo percorrida.

### Emenda (2026-11-16): Doutrina de Pactos

- **Entidade aliada.** A Maldição em campo é um `MaldicaoRef` (`RefCounted`), dono **ADR-0017**: `id` inteiro da mesma sequência da run (o mesmo contador crescente dos inimigos, para que eventos, telégrafos mirados e projéteis com `alvo_id` nunca confundam dois combatentes), `player_id`, um `Portador` próprio (ADR-0009, R14 de Modificadores) e facção `ALIADO` (ADR-0010). O `MaldicaoRef` sobrevive à reserva, à Exaustão e à troca de câmara durante a run; sai da cena só a Apresentação.
- **Chefe é `InimigoRef` com flag**, não tipo novo: `chefe: bool` (já copiado para o evento de morte; Pactuar usa `subjugar(inimigo_id)` do ADR-0010). Os campos continuam com os donos da decisão 3.
- **A acuada NÃO é `InimigoRef` e fica fora da lista de inimigos** (ADR-0010 §11, Combate R25.7): facção `ACUADA`, neutra, imóvel, sem IA ofensiva, fora da lista de atingíveis, da contagem de câmara limpa e do item 9. Pertence ao Vínculo, que a expõe por consulta (`acuada_atingivel()`); é ferida só por `ferir_acuada` (ADR-0010). Congela em hitstop, Pausa e Transição como todo combatente (Vínculo V7).
- Todo identificador de combatente é **inteiro** (`int`), nunca `StringName` nem índice de array.

## Alternativas consideradas

| Alternativa | Efeito |
|---|---|
| `Node` como entidade viva | Facilitaria associar a apresentação à entidade. Introduziria dependência de árvore e de ciclo dos nós na simulação. |
| `Resource` para o estado vivo | Facilitaria inspeção e serialização. Exigiria controlar a duplicação de sub-recursos para que instâncias com a mesma definição tenham estado independente. |
| Índice em pool como identidade do inimigo | É compacto. Reuso e remoção podem fazer um consumidor atingir outra entidade. A escala do MVP permite testar primeiro objetos com identidade própria. |

## Consequences

### Positivas

- A simulação roda e é testada sem `SceneTree`; IA, Combate, Movimento, Selo, Status e Telégrafos recebem estado por injeção e consultas.
- Identidade inteira estável na run evita que eventos, telégrafos e projéteis atinjam outro combatente após remoção ou reuso.
- Posse única de cada campo (decisão 3) torna claro quem escreve o quê; definições do catálogo nunca são alteradas pelo estado vivo.
- O retrato por passe da varredura de mortes não altera a lista viva durante a iteração.

### Negativas

- Consultas e eventos copiam valores desvinculados, com custo de alocação e cópia por quadro.
- Imutabilidade das definições é convenção verificada em testes, não garantia da engine.
- Cada novo tipo de combatente (`MaldicaoRef`, acuada) exige decidir lista, facção e posse explicitamente.

### Riscos

- Volume de alocações por combate e custo de cópia ainda não medidos com os sistemas reais (seção "Verificação no Godot 4.7.2").
- Referência a `InimigoRef` retida além da chamada síncrona pode ler estado obsoleto; mitigação: guardar só o id e revalidar (decisão 5).
- Ciclos de referência entre combatente e portador vazariam memória em `RefCounted`; mitigação: portador sem referência forte de volta.

## GDD Requirements Addressed

| TR-ID | Requisito | Origem | Como este ADR atende |
|---|---|---|---|
| TR-conteudo-003 | Definição só de leitura em execução; cópia mutável por duplicate_deep | conteudo-orientado-a-dados.md R3 | Decisão 1 (definição `Resource` imutável, estado vivo em `RefCounted`); a cópia por `duplicate_deep` é do ADR-0004 §Imutabilidade e cópias |
| TR-modificadores-001 | Portador por combatente; atributos derivados separados dos recursos | modificadores-e-atributos.md R1 | Decisões 1 e 3 (`Portador` por combatente; Modificadores possui atributos, Combate possui Vida e recursos) |
| TR-modificadores-003 | Estado de portador independente por instância; definição do catálogo intacta | modificadores-e-atributos.md R11 | Decisões 1 e 5; critério de validação de Modificadores em "Rastreabilidade" |
| TR-modificadores-014 | Um portador por Maldição da dupla, persistente na Exaustão e na reserva, criável no passo de um pacto | modificadores-e-atributos.md R14, AC-40 | Emenda Pactos (`MaldicaoRef` com `Portador` próprio, sobrevive à reserva, Exaustão e troca de câmara); criação no passo e origens: ADR-0009 e ADR-0017 |
| TR-combate-nucleo-003 | Lista de inimigos em ordem estável, estado vivo fora do SceneTree, lógica testável sem cena | combate-nucleo.md R16, AC-02 | Decisões 1 e 2 |
| TR-combate-nucleo-010 | Varredura de mortes com retrato por passe; morto não age; morte do jogador para os passos seguintes | combate-nucleo.md R14 | Varredura de mortes; parada dos passos na morte do jogador: ADR-0001 |
| TR-combate-nucleo-015 | Todas as dependências do Combate por injeção | combate-nucleo.md R16, AC-04 | Decisões 3 e 5 (contratos pelo módulo dono, consultas desvinculadas); composição por injeção: ADR-0001 e ADR-0010 |
| TR-combate-nucleo-020 | Maldição na facção do jogador fora das listas de alvos, sem fogo amigo; aplicar_golpe_maldicao síncrono | combate-nucleo.md R19, R20, R14 | Emenda Pactos (`MaldicaoRef` facção `ALIADO`, fora da lista de inimigos); `aplicar_golpe_maldicao` e crédito do abate: ADR-0010 |
| TR-selo-006 | Consulta no_selo(inimigo) válida até o próximo item 6, lida pela IA | selo-e-fluxo.md R4 | Decisão 3 (Selo possui `no_selo`; consultas projetam campos); janela de validade no passo: ADR-0001 |
| TR-selo-011 | Lista de Selos ativos em ordem de criação, marcas por inimigo, sem SceneTree | selo-e-fluxo.md R3, R8 | Decisões 1 e 3 (estado em `RefCounted`, Selo dono das marcas por id de inimigo) |
| TR-status-001 | Estado por inimigo: Sangramento, Queimadura e Abalo em passos vivos | efeitos-de-status.md R1 | Decisão 3 (Status possui seus três efeitos por inimigo) |
| TR-status-008 | Troca de câmara limpa todos os status | efeitos-de-status.md R7 | não tratado aqui — ver ADR-0015 |
| TR-status-010 | Dependências injetadas; testes sem SceneTree | efeitos-de-status.md R10 | Decisões 1 e 3 |
| TR-status-012 | Consulta estado(inimigo) para HUD e VFX; sinais com teto de 3 | efeitos-de-status.md R6 | Decisão 5 (consultas com valores desvinculados); teto e redução dos sinais: ADR-0011 |
| TR-telegrafos-001 | Telégrafo como entidade em pool pré-alocado, ligado ao dono | telegrafos.md R1 | Decisão 4 |
| TR-telegrafos-012 | Dependências injetadas; testes sem SceneTree | telegrafos.md R11 | Decisões 1 e 4 |
| TR-ia-002 | Lista de inimigos com identidade estável; morto não age; remoção na varredura | ia-de-inimigos-e-elites.md R1 | Decisão 2 e Varredura de mortes |
| TR-ia-003 | Máquina de fases com timers em passos vivos | ia-de-inimigos-e-elites.md R3-R7 | Decisão 3 (IA possui fases e timers); a máquina de fases: ADR-0018 |
| TR-ia-013 | Dependências injetadas; testes sem SceneTree | ia-de-inimigos-e-elites.md R15 | Decisões 1 e 3 |
| TR-ia-016 | Consulta atingiveis só leitura em ordem estável de spawn, sem Maldição nem acuada | ia-de-inimigos-e-elites.md R19, R20 | Decisão 2 (ordem estável) e Emenda Pactos (Maldição e acuada fora da lista); a consulta: ADR-0010 e ADR-0018 |
| TR-movimento-001 | Só o Movimento escreve a posição do jogador | movimento-e-esquiva.md R1 | Decisão 3 |
| TR-movimento-011 | Módulo puro injetado; determinismo bit a bit | movimento-e-esquiva.md R12 | Decisão 1 (lógica em `RefCounted`, sem árvore); determinismo do movimento: ADR-0008 |
| TR-camaras-006 | Spawn sorteia sempre 14 candidatos | camaras-e-ondas.md R7 | não tratado aqui — ver ADR-0005 |
| TR-camaras-012 | Campo ordem por inimigo passado à IA; filtro por spawn_dist_acuada_px | camaras-e-ondas.md R7-P, F3-P | não tratado aqui — ver ADR-0005 (Emenda Pactos) e ADR-0018 |
| TR-camaras-014 | Câmara do chefe sem sorteio; lacaios na lista com teto de 9 | camaras-e-ondas.md R14-P | Emenda Pactos (chefe é `InimigoRef` com flag) e decisão 2 (lista); invocação e teto: ADR-0018 |
| TR-camaras-015 | Câmara limpa conta só a lista de inimigos; Maldições e acuada fora | camaras-e-ondas.md R9-P | Emenda Pactos (Maldição e acuada fora da lista de inimigos e da contagem de câmara limpa) |
| TR-run-008 | nova_run com reset total dos sistemas da run | run-e-regioes.md R8 | Decisão 2 (lista e identidade reiniciam com a run); reset total: ADR-0015 |
| TR-maldicoes-001 | Maldição é entidade da facção do jogador ligada a player_id e portador, fora das listas | maldicoes.md R1 | Emenda Pactos (`MaldicaoRef`) |
| TR-maldicoes-002 | Dupla campo/reserva por jogador (MaldicaoRef) com estados; dupla pode crescer | maldicoes.md R2, R24 | Emenda Pactos (`MaldicaoRef` persiste na reserva e na Exaustão); dupla e estados: ADR-0017 |
| TR-chefes-009 | Invocação controlada de lacaios com teto e marca invocado_pelo_chefe | chefes.md R5.4, R8 | não tratado aqui — ver ADR-0018 |
| TR-chefes-017 | Chefe mais lacaios dentro do teto de inimigos (9) e de telégrafos (24) | chefes.md CH6 | Decisão 4 (capacidade dos telégrafos = teto validado, 24); teto de inimigos: ADR-0018 e ADR-0014 |

## Verificação no Godot 4.7.2

Um experimento isolado verificou `Array` tipado de `RefCounted`, remoção ordenada e liberação quando a última referência forte é descartada. Congelar a estrutura de uma cópia do array preservou a possibilidade de alterar os objetos referenciados. Reutilizar um slot também alterou o que um observador via através de uma referência antiga. Esses resultados fundamentam as consultas por valores desvinculados nas fronteiras.

Volume de alocações por combate, custo de cópia por quadro e o orçamento gráfico dos telégrafos seguem pendentes de medição com os sistemas reais.

## Rastreabilidade e critérios de validação

- [IA e elites, R1–R3](../../design/gdd/ia-de-inimigos-e-elites.md) e [Combate, R1/R3/R14](../../design/gdd/combate-nucleo.md). Gerar três inimigos, remover o segundo e gerar outro. A ordem dos sobreviventes e a identidade de cada instância devem se manter. A entidade morta deixa de agir no passo previsto pelo Combate.
- [Movimento, R1/R9/R12](../../design/gdd/movimento-e-esquiva.md) e [Modificadores, R1/R3/R11](../../design/gdd/modificadores-e-atributos.md). Com dois combatentes da mesma definição, alterar uma fonte de modificador ou um recurso de um deles. O outro preserva seu estado e o catálogo conserva o dado de origem. Movimento continua sendo o único escritor da posição do jogador.
- [Selo, R3/R4](../../design/gdd/selo-e-fluxo.md) e [Status, R1/R10](../../design/gdd/efeitos-de-status.md). Aplicar efeitos a inimigos distintos e verificar que cada módulo recebe a marca e o estado do alvo correto, inclusive na remoção de outro inimigo.
- [Telégrafos, R1–R4/R11](../../design/gdd/telegrafos.md). Preencher a capacidade configurada, recusar criação adicional, encerrar um telégrafo e reutilizar sua vaga. O estado já entregue à Apresentação continua associado ao dono original.

Os IDs definitivos dos requisitos ficam para a revisão consolidada da arquitetura.
