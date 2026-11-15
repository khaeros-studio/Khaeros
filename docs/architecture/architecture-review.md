# Khaeros — Revisão inicial da arquitetura

**Data:** 2026-11-14  
**Etapa:** Pré-produção, preparação técnica após a prova de combate  
**Veredito:** CONCERNS — revisão parcial dos ADRs 0001 e 0002

O [índice de sistemas](../../design/gdd/systems-index.md) registra 22 GDDs do MVP aprovados e o [protótipo de combate](../../prototypes/combate-camara-concept/REPORT.md) recebeu PROCEED após o playtest de 13/11. O relatório de estágio de 13/11 antecede a [arquitetura v1.4](architecture.md). Os ADRs 0001 a 0003 estão em Proposed, e o [registro formal de requisitos](tr-registry.yaml) segue vazio. Os 233 requisitos da arquitetura são uma linha de base provisória.

## Contratos conferidos

| Contrato | Evidência | Resultado |
| --- | --- | --- |
| Posse e desconto de hitstop | [Combate R1, R10 e AC-96](../../design/gdd/combate-nucleo.md), [Movimento R2](../../design/gdd/movimento-e-esquiva.md), [Input R6](../../design/gdd/input-e-controle.md), [ADR-0001](adr-0001-orquestrador-do-passo.md) | O Combate guarda o contador. O pedido termina o passo em curso. Os próximos passos em Jogo descontam o contador mantendo o prazo do buffer. Fora de Jogo o desconto para, e o Movimento iguala posição anterior e atual. A avaliação de câmara limpa espera o contador chegar a zero. |
| Troca de câmara | [Combate R1 e AC-96](../../design/gdd/combate-nucleo.md), [Pipeline F8](../../design/gdd/pipeline-visual.md), [ADR-0001](adr-0001-orquestrador-do-passo.md) | O primeiro quadro com wipe ≥ 0,5 concentra as seis ações, do reset do Combate à troca de LUT e ao zero dos relógios. |
| Prioridade de morte e recompensa | [Run R5 e AC-RN-16](../../design/gdd/run-e-regioes.md), [Portas AC-PR-23–25](../../design/gdd/portas-e-recompensas.md), [ADR-0002](adr-0002-canal-de-eventos.md) | O evento de morte fica visível antes da avaliação de limpeza. Run e Portas consultam a morte antes de terminar a run com vitória, creditar, pedir oferta ou abrir portas. |
| Notificações e controle de bênção | [Feedback R14](../../design/gdd/feedback-de-combate.md), [Tela de bênção R9 e Interactions](../../design/gdd/tela-de-bencao-e-carta.md), [Portas AC-PR-25](../../design/gdd/portas-e-recompensas.md), [ADR-0002](adr-0002-canal-de-eventos.md) | Feedback recebe a lista ordenada. A cadeia de controle espera `tela_fechada` para publicar `bencao_escolhida` e abrir portas. |

## Lacunas a resolver antes da implementação afetada

### ADR-0001 — Orquestrador e integração com o ADR-0002

1. **Finalização nos passos congelados.** O diagrama do ADR-0001 mostra o envio de eventos no ramo do passo vivo. O ADR-0002 exige esvaziar e entregar a lista uma vez em todo passo físico, inclusive fora de Jogo. O texto também promete lista vazia em passo congelado e permite que eventos de UI entrem antes desse passo. Especificar um final comum, com `t_vivo` condicionado ao passo vivo e entrega uma vez por passo físico, mesmo se o lote estiver vazio. Testar um evento de UI enfileirado em Bênção, um evento do passo que pede hitstop e o passo congelado seguinte.
2. **Duração da run e da câmara.** A arquitetura liga Run e Telemetria ao avanço de `t_vivo` em passo vivo. [Run F3](../../design/gdd/run-e-regioes.md) e [Telemetria F1 e AC-TL-06](../../design/gdd/telemetria-local.md) incluem hitstop na duração. Definir a contagem de passos em Jogo também no ramo congelado e preservar `t_vivo` e `t_apres` para os seus usos de apresentação. O caso da Telemetria pede 17,40 s para 1.044 passos em Jogo que já incluem 30 passos de hitstop.

### ADR-0002 — Consumidores de eventos e efeitos de jogo

3. **Crédito de Fluxo do Pulso no item 8.** O ADR descreve o Selo lendo `acerto_de_arma` do item 5 no item 6 e a lista sendo esvaziada no fim do passo. Falta o caminho que credita o acerto do projétil no item 8 antes da finalização. [Selo F1 e AC-SF-26](../../design/gdd/selo-e-fluxo.md) exigem Fluxo 41,96 ao fim do passo iniciado com 38,9; a conjuração só pode usar o saldo no passo seguinte. Descrever a contabilização tardia exatamente uma vez, com o item 6 mantendo a posição atual.
4. **Aplicação de status no impacto.** O diagrama do ADR mostra Status lendo `acerto` no item 7. [Status R2–R4](../../design/gdd/efeitos-de-status.md) exige aplicar efeitos de forma síncrona no impacto e pelo Selo, com fontes específicas. O item 7 avança o efeito por inimigo. O efeito aplicado pelo projétil no item 8 já existe no alvo nesse passo e só fere a partir do seguinte. Harmonizar diagrama, interface e testes com a chamada `aplicar_status` já registrada na arquitetura, preservando `acerto_de_arma` como notificação do golpe.
5. **Identidade do alvo — encaminhada.** O ADR-0002 reserva o tipo do identificador ao [ADR-0003 proposto](adr-0003-entidades-e-portadores.md). A proposta atribui IDs crescentes na ordem de surgimento durante a run e entrega esses IDs com valores desvinculados da entidade. A aprovação e os testes de integração ainda precisam confirmar a ordem dos sobreviventes e a associação dos eventos depois de remoção ou troca de câmara.

## Continuidade

O [checkpoint do estúdio](../../production/session-state/active.md) registra a sequência. Na continuidade de 2026-11-14, existem propostas ADR-0001 a ADR-0008; a próxima é **ADR-0009 — Atributos e modificadores**, seguindo a [ordem do documento técnico](architecture.md#required-adrs). As lacunas acima entram na próxima revisão dos ADRs 0001 e 0002. A revisão formal, o registro permanente de requisitos e o manifesto de controle ficam para a sequência já registrada no checkpoint.

### Achados adicionais do ADR-0008 (2026-11-14)

6. **F7/MV1 e colisão contínua.** O experimento de Movimento reproduz uma passagem tangencial: raio combinado69, segmento relativo (−10,68.5)→(10,68.5), passo20<69, extremos fora e meio dentro. O algoritmo aprovado de R10 só resolve extremos. Antes de encerrar aceite do sistema, esclarecer a promessa de não atravessar; varredura/subpassos mudariam o design. O caso axial AC-30 passa.
7. **Toques durante congelamento.** ADR-0006 drena bordas por passo físico, enquanto Movimento R5 exige reação no primeiro passo vivo. ADR-0008 propõe contagem de novos toques de Esquiva por época, separada do buffer compartilhado. Falta critério para múltiplos toques congelados e recarga que completa no primeiro passo vivo. Os experimentos isolados não provam essa integração.
8. **Corte pesado e hitstop.** Movimento AC-26 diz que empurrão pesado produz hitstop; Movimento R8 e Combate R18 excluem hitstop próprio de Corte. ADR-0010 deve conciliar o critério com o contrato, distinguindo marcador pesado de hitstop de abate.

Detalhes e evidência em [ADR-0008](adr-0008-movimento-e-colisao-propria.md) e [experimento](../../prototypes/movimento-verificacao/README.md). Os achados de Input e Cena também permanecem nas seções de revisão dos ADRs 0006/0007; esta lista adicional não substitui a auditoria consolidada.

## Verificações executadas nesta etapa

- A execução no Godot 4.7.2 confirmou os seis [cenários do protótipo](../../production/qa/evidence/combate-camara-testes.txt) (T1, T1b e T2 a T5) e passou os dois casos de fumaça do gdUnit4.
- O experimento isolado do [ADR-0003](adr-0003-entidades-e-portadores.md#verificação-no-godot-472) confirmou aspectos da semântica de arrays tipados e referências do Godot. O custo no jogo continua em aberto.

A cobertura dos contratos do ADR-0001 e do ADR-0002 nesta passada é documental e pontual. Os resultados executáveis cobrem o protótipo, o ambiente de testes e o recorte do experimento de entidades. A implementação integrada e os demais requisitos dos 22 GDDs aguardam verificação própria.
