# ADR-0003 — Representação de entidades e portadores

## Status

Proposed · 2026-11-14

## Contexto

A simulação processa os inimigos em ordem estável e precisa rodar sem uma cena. IA, Combate, Movimento, Selo, Status e Telégrafos consultam partes diferentes do mesmo estado. O catálogo carrega definições compartilhadas, como `EnemyDef`, e a Apresentação consome eventos tipados e consultas. Este ADR propõe como representar o estado vivo e preservar a posse dos campos. Depende dos [ADRs 0001](adr-0001-orquestrador-do-passo.md) e [0002](adr-0002-canal-de-eventos.md), ambos propostos.

## Decisão proposta

1. **Estado vivo em `RefCounted`.** `InimigoRef` e `JogadorRef` agrupam o estado de cada combatente junto com a referência à sua definição. O `Portador` mantém atributos derivados, modificadores e gatilhos por combatente. As definições do catálogo são `Resource` e são tratadas como imutáveis pelos consumidores durante a run. Os `Node2D` da Apresentação consomem dados da simulação e gerenciam seu próprio ciclo visual.
2. **Identidade na run.** A IA atribui a cada inimigo uma sequência crescente na ordem de surgimento, incluindo inimigos ainda na fase Surgindo. O identificador é estável durante a run. A IA anexa novos inimigos à lista e remove os mortos preservando a ordem dos sobreviventes. A posição no array pode mudar e serve apenas para armazenamento. A lista reinicia com a run e a Apresentação descarta suas associações nessa fronteira.
3. **Posse dos campos por sistema.** A IA possui lista, fases, timers e posição normal do inimigo. O Combate possui Vida, escudo, impacto e cambaleio, resolve as mortes na ordem do passo e solicita à IA a remoção. O Movimento possui posição, cargas e esquiva do jogador. Modificadores possui atributos, fontes e gatilhos. Status possui seus três efeitos por inimigo, e Selo possui a marca `no_selo` e o Fluxo. As consultas projetam os campos necessários. Mudanças passam pela interface do módulo dono.
4. **Telégrafos em armazenamento reutilizável.** Telégrafos possui slots internos, com capacidade inicial igual ao teto validado no catálogo (24 no MVP de fábrica). O módulo associa até um telégrafo ativo a cada identificador de inimigo. O dono é reconsultado para obter a âncora atual. O estado terminal é copiado para a Apresentação com os dados necessários ao efeito visual, inclusive quando o dono morre. A vaga volta a ficar disponível quando a regra deixa de contar o telégrafo como ativo. A geometria, a contagem de vagas e o momento preciso de liberação ficam para o ADR-0014.
5. **Limites de referência.** Consultas para a Apresentação e eventos entregam identificadores e valores desvinculados do estado vivo. Os módulos de regra que recebem `InimigoRef` nos contratos síncronos usam a referência durante a chamada. Um resultado guardado além da chamada mantém o identificador e revalida a consulta quando necessário. O combatente pode possuir seu portador, e o portador recebe dados sem referência forte de volta ao combatente. Eventos e consultas também evitam ciclos de referências.

Na varredura de mortes, cada passe do Combate começa com uma lista ordenada dos inimigos com Vida ≤ 0. O Combate copia posição e marcas de elite e chefe para o evento ao remover cada entidade via IA. Mortes geradas durante o passe entram na lista do passe seguinte, conforme Combate R14. Esse retrato evita modificar a lista viva enquanto ela está sendo percorrida.

## Alternativas consideradas

| Alternativa | Efeito |
|---|---|
| `Node` como entidade viva | Facilitaria associar a apresentação à entidade. Introduziria dependência de árvore e de ciclo dos nós na simulação. |
| `Resource` para o estado vivo | Facilitaria inspeção e serialização. Exigiria controlar a duplicação de sub-recursos para que instâncias com a mesma definição tenham estado independente. |
| Índice em pool como identidade do inimigo | É compacto. Reuso e remoção podem fazer um consumidor atingir outra entidade. A escala do MVP permite testar primeiro objetos com identidade própria. |

## Verificação no Godot 4.7.2

Um experimento isolado verificou `Array` tipado de `RefCounted`, remoção ordenada e liberação quando a última referência forte é descartada. Congelar a estrutura de uma cópia do array preservou a possibilidade de alterar os objetos referenciados. Reutilizar um slot também alterou o que um observador via através de uma referência antiga. Esses resultados fundamentam as consultas por valores desvinculados nas fronteiras.

Volume de alocações por combate, custo de cópia por quadro e o orçamento gráfico dos telégrafos seguem pendentes de medição com os sistemas reais.

## Rastreabilidade e critérios de validação

- [IA e elites, R1–R3](../../design/gdd/ia-de-inimigos-e-elites.md) e [Combate, R1/R3/R14](../../design/gdd/combate-nucleo.md). Gerar três inimigos, remover o segundo e gerar outro. A ordem dos sobreviventes e a identidade de cada instância devem se manter. A entidade morta deixa de agir no passo previsto pelo Combate.
- [Movimento, R1/R9/R12](../../design/gdd/movimento-e-esquiva.md) e [Modificadores, R1/R3/R11](../../design/gdd/modificadores-e-atributos.md). Com dois combatentes da mesma definição, alterar uma fonte de modificador ou um recurso de um deles. O outro preserva seu estado e o catálogo conserva o dado de origem. Movimento continua sendo o único escritor da posição do jogador.
- [Selo, R3/R4](../../design/gdd/selo-e-fluxo.md) e [Status, R1/R10](../../design/gdd/efeitos-de-status.md). Aplicar efeitos a inimigos distintos e verificar que cada módulo recebe a marca e o estado do alvo correto, inclusive na remoção de outro inimigo.
- [Telégrafos, R1–R4/R11](../../design/gdd/telegrafos.md). Preencher a capacidade configurada, recusar criação adicional, encerrar um telégrafo e reutilizar sua vaga. O estado já entregue à Apresentação continua associado ao dono original.

Os IDs definitivos dos requisitos ficam para a revisão consolidada da arquitetura.
