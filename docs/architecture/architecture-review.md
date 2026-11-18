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

## Revisão cruzada dos ADRs 0001 a 0014 (2026-11-15)

Revisor independente (subagente `technical-director`), depois da escrita em paralelo dos ADRs 0009–0014. Não substitui `/architecture-review` formal.

- **Vereditos:** PASS em 0003–0009, 0012 e 0014. CONCERNS em 0010 (falta teste de arredondamento; AC-92 sem fonte), 0011 (E1–E7 NOT SOURCEABLE) e 0013 (experimentos E-P2/E-P3). 0001 e 0002 revisados nesta data pela aba de Arquitetura.
- **Alinhamentos aplicados:** assinaturas de `GeometriaDeAcerto` (dono: 0010, com `circulos_encostam` e `alcance_do_raio`); ordem do item 7 (`varrer`, depois por inimigo `avancar(1)` → `status.tick` → `telegrafos.avancar` → impacto → IA); dano via `FormulasDeModificadores` em vez de `roundi`; `VistaDeTelegrafo.slot`; vinheta no 0011; `ComandosDeTela` no 0006; `[ui] escala` e repositórios no 0012/0013; `resolver_colisao_informando` no 0008; `autor_player_id` em `EvInimigoMorreu`; `telegrafos.quebrar` chamado pelo 0010; consumidor `Telas` no 0002; `retomar()` no 0001.
- **Em aberto:** `EvRecusouMorte` talvez precise de `impact_passos` (Feedback); o Status não tem ADR próprio, então o contrato de `status.tick` fica sem dono formal.
- **Nenhum padrão proibido** do registro usado (Autoload, `Timer`, `SceneTree.paused`, `time_scale`, sinal entre módulos de regra).

### Decisões de design do usuário

> **2026-11-15: o usuário aceitou todas as 15 recomendações.** Propagado: GDD de Telégrafos (R7, estados, Edge, AC-TG-09, AC-TG-16, AC-TG-25), texto de `refletir_dano` no GDD de Combate e API 5 do `architecture.md`. As seções "Decisões do usuário" dos ADRs 0009–0014 registram a aceitação; o ADR-0014 passa à política `LIBERAR_JA`.

| # | ADR | Decisão | Recomendação |
|---|---|---|---|
| 1 | 0014 | Telégrafos na troca de câmara: fade de 2 passos (GDD) ou liberar na hora | Liberar na hora (muda Telégrafos R7/AC-TG-16) |
| 2 | 0014 | AC-TG-09: faixa até a superfície da pedra ou até onde o projétil some | Superfície |
| 3 | 0014 | Mira com distância 0 | `(1, 0)` |
| 4 | 0010 | Teto de projéteis | Sem teto de jogo; só aviso de depuração |
| 5 | 0010 | Ordem entre projéteis do jogador e dos inimigos | Lista única por criação (confirmar no cânone) |
| 6 | 0010/0009 | Co-op: hitstop global, morte individual, autor dos gatilhos de abate | Adiar; gatilhos só do autor |
| 7 | 0009 | Ajustar textos do Combate e da API 5 (`valor`/`inteiro`, `gatilhos`) | Ajustar na próxima edição |
| 8 | 0012 | Camada do fio de Vida e do prompt | UI (confirmar com art-director) |
| 9 | 0012 | Separador de milhar | Espaço fixo "1 234" |
| 10 | 0012 | Leitor de tela (AccessKit) no MVP | Fora do MVP, estrutura pronta |
| 11 | 0013 | Aviso de falha ao gravar configurações | Discreto, uma vez por sessão |
| 12 | 0013 | Arquivo de versão futura | Não regravar |
| 13 | 0013 | `telemetria_ligada` em `opcoes.cfg` | Confirmar |
| 14 | 0011 | Redução de movimento ligada no meio de um wipe | O passe termina como começou |
| 15 | 0011 | Fallback do E7 (material por papel) se material por entidade pesar | Decidir após o E7 (muda Pipeline R6) |

## Lacunas a resolver antes da implementação afetada

> **2026-11-15:** as lacunas 1 a 4 foram tratadas na proposta revisada dos ADRs 0001 (final comum do passo, `n_vivos`, `passos_em_jogo()`, pedidos de estado com `MORTE` vencendo) e 0002 (lista só para itens anteriores; `aplicar_status` e `creditar_acerto_tardio()` por chamada direta; entrega em passo congelado). Os ADRs seguem Proposed até a revisão formal e o aceite.

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

## Revisão de 2026-11-16 (Doutrina de Pactos)

Relatório formal: [architecture-review-2026-11-16.md](architecture-review-2026-11-16.md). 18 ADRs (novos: 0015 Ciclo da run, 0016 Áudio, 0017 Aliados e invocações, 0018 IA de inimigos e chefe; emendas em 0001–0014). 400 requisitos: 399 🟡, 1 ⚠️ (TR-conteudo-015, PC de referência), 0 ❌. 5 conflitos 🔴 achados por revisor independente, todos corrigidos; grafo sem ciclos. Veredito: CONCERNS (teto por todos estarem Proposed).
