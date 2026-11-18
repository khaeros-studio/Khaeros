# Sprint 3 — 2026-12-07 to 2026-12-13

> Gerado por `/sprint-plan new` (orquestrado, 2026-11-16). Plano do marco MVP em 9 sprints — uma por onda de dependência.

## Sprint Goal
Entregar o Core na ordem do passo (Modificadores -> Movimento -> Combate) com a fatia jogável rodando sobre ele.

## Goal Prerequisites
| Needed to show the goal | Status |
|-------------------------|--------|
| Cena principal `res://scenes/main.tscn` | exists |

## Milestone Context
- Current Milestone: MVP ([production/milestones/mvp.md](../milestones/mvp.md))
- Milestone Deadline: 2027-02-14
- Sprints Remaining: 7 (incluindo esta)

## Capacity
- Equipe: 7 agentes de IA em paralelo (6–8), 1 semana(s) úteis
- Total days: 35 agente-dia
- Buffer (20%): 7 agente-dia
- Available: 28 agente-dia
- Carga planejada: 25.0 agente-dia (20 stories; S=0,5 / M=1 / L=2)
- Estimativa não calibrada: não há histórico de velocidade (primeira sprint do plano).

## Ordem e paralelismo
Stories numa mesma onda não dependem entre si e podem correr ao mesmo tempo (até 7 agentes, um por pasta de sistema). Uma onda começa quando as dependências dela, na onda anterior, fecham — não a onda inteira.

- **Onda 1** (11): **modificadores-001**, **modificadores-002**, **modificadores-003**, **modificadores-004**, **modificadores-005**, **modificadores-006**, **movimento-e-esquiva-002**, **movimento-e-esquiva-003**, **movimento-e-esquiva-005**, **movimento-e-esquiva-006**, **movimento-e-esquiva-010**
- **Onda 2** (2): **combate-nucleo-001**, **movimento-e-esquiva-001**
- **Onda 3** (3): **combate-nucleo-002**, **movimento-e-esquiva-007**, **movimento-e-esquiva-008**
- **Onda 4** (1): **combate-nucleo-003**
- **Onda 5** (1): **combate-nucleo-004**
- **Onda 6** (2): **combate-nucleo-005**, **combate-nucleo-006**

Em negrito: caminho crítico (EX-0001/0002 -> orquestrador -> modificadores -> movimento -> combate -> IA -> câmaras -> portas -> run).

## Tasks

### Must Have (Critical Path)
| ID | Task (story) | Agent/Owner | Est. Days | Dependencies | Onda | Acceptance Criteria |
|----|------|-------------|-----------|-------------|------|-------------------|
| modificadores-001 | [Portador: atributos, piso/teto, estrutura do modificador e F1](../epics/modificadores/story-001-portador-atributos-e-fontes.md) — pronta | gameplay-programmer | 1.0 (M) | conteudo (épico), orquestrador-do-passo (épico) | 1 | ACs da story + evidência do tipo Logic |
| modificadores-002 | [Ordem canônica, arredondamento determinístico e F1/F2/F3](../epics/modificadores/story-002-arredondamento-e-formulas.md) — pronta | gameplay-programmer | 1.0 (M) | — | 1 | ACs da story + evidência do tipo Logic |
| modificadores-003 | [Condicionais avaliados no uso e multiplicador_de_dano(contexto)](../epics/modificadores/story-003-condicionais-e-multiplicador-de-dano.md) — pronta | gameplay-programmer | 1.0 (M) | — | 1 | ACs da story + evidência do tipo Logic |
| modificadores-004 | [aplicar_fonte, remover_fonte, avancar: cache e duração](../epics/modificadores/story-004-aplicar-remover-avancar.md) — pronta | gameplay-programmer | 1.0 (M) | — | 1 | ACs da story + evidência do tipo Logic |
| modificadores-005 | [Gatilhos: ResumoDeGatilho cacheado e semântica do executor único](../epics/modificadores/story-005-gatilhos-e-executor-unico.md) — pronta | gameplay-programmer | 1.0 (M) | — | 1 | ACs da story + evidência do tipo Logic |
| modificadores-006 | [Tabela fechada das 21 chaves, validação, paridade com o cânone e tuning](../epics/modificadores/story-006-tabela-das-21-chaves-e-tuning.md) — pronta | gameplay-programmer | 1.0 (M) | conteudo (épico) | 1 | ACs da story + evidência do tipo Config/Data |
| movimento-e-esquiva-002 | [Andar, ordem interna do passo, passo() e passo_congelado()](../epics/movimento-e-esquiva/story-002-andar-e-ordem-do-passo.md) — pronta | gameplay-programmer | 1.0 (M) | input (épico), orquestrador-do-passo (épico) | 1 | ACs da story + evidência do tipo Logic |
| movimento-e-esquiva-003 | [Esquiva: largada, direção, buffer e pedidos síncronos ao Combate](../epics/movimento-e-esquiva/story-003-esquiva-e-contrato-com-o-combate.md) — pronta | gameplay-programmer | 2.0 (L) | input (épico) | 1 | ACs da story + evidência do tipo Logic |
| movimento-e-esquiva-005 | [Colisão própria: círculos, retângulo, esquiva contra obstáculos](../epics/movimento-e-esquiva/story-005-colisao-propria.md) — pronta | gameplay-programmer | 1.0 (M) | — | 1 | ACs da story + evidência do tipo Logic |
| movimento-e-esquiva-006 | [Teleporte, deslocar(v) e aviso de reset de interpolação](../epics/movimento-e-esquiva/story-006-teleporte-e-deslocamento-forcado.md) — pronta | gameplay-programmer | 1.0 (M) | cena-e-camera (épico) | 1 | ACs da story + evidência do tipo Logic |
| movimento-e-esquiva-010 | [MovementTuning (MV1–MV8) validado e orçamento de 0,2 ms](../epics/movimento-e-esquiva/story-010-tuning-e-orcamento.md) — pronta | gameplay-programmer | 1.0 (M) | conteudo (épico), experimentos-de-engine (épico) | 1 | ACs da story + evidência do tipo Config/Data |
| combate-nucleo-001 | [CombatTuning validado e esqueleto injetável do Combate](../epics/combate-nucleo/story-001-combat-tuning-e-esqueleto.md) — pronta | gameplay-programmer | 1.0 (M) | conteudo (épico), modificadores (épico), orquestrador-do-passo (épico) | 2 | ACs da story + evidência do tipo Logic |
| movimento-e-esquiva-001 | [Estado do jogador tipado, módulo puro injetado e determinismo](../epics/movimento-e-esquiva/story-001-estado-do-jogador-e-modulo-puro.md) — pronta | gameplay-programmer | 1.0 (M) | input (épico), modificadores (épico), orquestrador-do-passo (épico) | 2 | ACs da story + evidência do tipo Logic |
| combate-nucleo-002 | [Ordem do passo vivo, hitstop e transição](../epics/combate-nucleo/story-002-passo-vivo-e-hitstop.md) — pronta | gameplay-programmer | 1.0 (M) | combate-nucleo-001, input (épico), orquestrador-do-passo (épico) | 3 | ACs da story + evidência do tipo Logic |
| movimento-e-esquiva-007 | [Corte da esquiva: consulta ordenada, dano via portador e aplicar_corte](../epics/movimento-e-esquiva/story-007-corte-da-esquiva.md) — pronta | gameplay-programmer | 2.0 (L) | modificadores-003, combate-nucleo (épico) | 3 | ACs da story + evidência do tipo Logic |
| movimento-e-esquiva-008 | [Consultas e eventos esquiva/esquiva_sem_carga para HUD, Pipeline e Áudio](../epics/movimento-e-esquiva/story-008-consultas-e-eventos-de-saida.md) — pronta | gameplay-programmer | 1.0 (M) | combate-nucleo (épico) | 3 | ACs da story + evidência do tipo Integration |
| combate-nucleo-003 | [Disparo do golpe, combo por slot, guarda e recuperação](../epics/combate-nucleo/story-003-disparo-do-golpe-e-combo.md) — pronta | gameplay-programmer | 2.0 (L) | combate-nucleo-002, input (épico), modificadores (épico) | 4 | ACs da story + evidência do tipo Logic |
| combate-nucleo-004 | [GeometriaDeAcerto (arco, círculo, leque) e projéteis](../epics/combate-nucleo/story-004-geometria-e-projeteis.md) — pronta | gameplay-programmer | 2.0 (L) | combate-nucleo-003 | 5 | ACs da story + evidência do tipo Logic |
| combate-nucleo-005 | [Investida e pedidos síncronos do Movimento](../epics/combate-nucleo/story-005-investida-e-pedidos-do-movimento.md) — pronta | gameplay-programmer | 1.0 (M) | combate-nucleo-003, combate-nucleo-004, movimento-e-esquiva (épico) | 6 | ACs da story + evidência do tipo Integration |
| combate-nucleo-006 | [ferir_inimigo, empurrão e impacto na parede](../epics/combate-nucleo/story-006-dano-no-inimigo-e-empurrao.md) — pronta | gameplay-programmer | 2.0 (L) | combate-nucleo-004, modificadores (épico), movimento-e-esquiva (épico) | 6 | ACs da story + evidência do tipo Logic |

### Should Have
| ID | Task (story) | Agent/Owner | Est. Days | Dependencies | Onda | Acceptance Criteria |
|----|------|-------------|-----------|-------------|------|-------------------|
| — | Nenhuma: todas as stories desta sprint são caminho crítico ou dependência de outra story | | | | | |

### Nice to Have
| ID | Task (story) | Agent/Owner | Est. Days | Dependencies | Onda | Acceptance Criteria |
|----|------|-------------|-----------|-------------|------|-------------------|
| — | Nenhuma: o backlog do MVP não tem stories opcionais | | | | | |

## Carryover from Previous Sprint
| Task | Reason | New Estimate |
|------|--------|-------------|
| — | Definido por `/sprint-plan update` ao fechar a Sprint 2 | — |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Caminho crítico serial (modificadores -> movimento -> combate) limita o paralelismo | Alta | Alto | Ordenar por onda; agentes ociosos adiantam testes e Feature que só depende de Foundation |
| Regressão de determinismo do passo no combate | Média | Alto | Testes de reprodução com seed fixa obrigatórios em toda story Logic do Core |

## Dependencies on External Factors
- Godot 4.7.2 instalado (`docs/engine-reference/godot/VERSION.md`); GdUnit4 para a suíte.
- Aprovação humana de evidências visuais (lead sign-off) para stories Visual/Feel e UI.
- Sem registro de riscos em `production/risk-register/`: riscos avaliados só pelo conteúdo da sprint.

## Definition of Done for this Sprint
- [x] All Must Have tasks completed (20/20 done)
- [x] All tasks pass acceptance criteria
- [x] All Logic/Integration stories have passing unit/integration tests
- [x] Toda story que muda algo observável pelo jogador foi rodada e tem screenshot retido em `production/qa/evidence/`
- [x] QA sign-off report: APPROVED
- [x] No S1 or S2 bugs in delivered features
- [x] A fatia jogável continua abrindo por `res://scenes/main.tscn`
- [x] Design documents updated for any deviations
- [x] Code reviewed and merged
