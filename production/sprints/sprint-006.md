# Sprint 6 — 2027-01-04 to 2027-01-17

> Gerado por `/sprint-plan new` (orquestrado, 2026-11-16). Plano do marco MVP em 9 sprints — uma por onda de dependência.

## Sprint Goal
Fechar o ciclo da run: portas e recompensas, vínculo e pactos, run e regiões e o chefe (Soberano) — loop Limiar -> Soberano jogável sem polimento.

## Goal Prerequisites
| Needed to show the goal | Status |
|-------------------------|--------|
| Cena principal (`run/main_scene` = `res://scenes/main.tscn`) | exists |

## Milestone Context
- Current Milestone: MVP ([production/milestones/mvp.md](../milestones/mvp.md))
- Milestone Deadline: 2027-02-14
- Sprints Remaining: 4 (incluindo esta)

## Capacity
- Equipe: 7 agentes de IA em paralelo (6–8), 2 semana(s) úteis
- Total days: 70 agente-dia
- Buffer (20%): 14 agente-dia
- Available: 56 agente-dia
- Carga planejada: 47.0 agente-dia (45 stories; S=0,5 / M=1 / L=2)
- Estimativa não calibrada: não há histórico de velocidade (primeira sprint do plano).

## Ordem e paralelismo
Stories numa mesma onda não dependem entre si e podem correr ao mesmo tempo (até 7 agentes, um por pasta de sistema). Uma onda começa quando as dependências dela, na onda anterior, fecham — não a onda inteira.

- **Onda 1** (4): **portas-e-recompensas-001**, **run-e-regioes-001**, **run-e-regioes-002**, vinculo-e-pactos-001
- **Onda 2** (7): **camaras-e-ondas-006**, **ia-de-inimigos-e-elites-008**, **portas-e-recompensas-002**, **run-e-regioes-003**, **run-e-regioes-008**, economia-de-fragmentos-004, vinculo-e-pactos-002
- **Onda 3** (7): **camaras-e-ondas-007**, **portas-e-recompensas-003**, **portas-e-recompensas-004**, **run-e-regioes-004**, chefes-002, economia-de-fragmentos-005, vinculo-e-pactos-003
- **Onda 4** (4): **camaras-e-ondas-008**, **portas-e-recompensas-005**, chefes-003, vinculo-e-pactos-004
- **Onda 5** (5): **portas-e-recompensas-006**, **portas-e-recompensas-007**, chefes-004, chefes-006, telegrafos-007
- **Onda 6** (3): **ia-de-inimigos-e-elites-009**, chefes-005, telegrafos-009
- **Onda 7** (4): **ia-de-inimigos-e-elites-010**, chefes-001, chefes-008, vinculo-e-pactos-005
- **Onda 8** (3): **camaras-e-ondas-009**, economia-de-fragmentos-006, vinculo-e-pactos-006
- **Onda 9** (2): **run-e-regioes-005**, vinculo-e-pactos-007
- **Onda 10** (5): **run-e-regioes-006**, **run-e-regioes-007**, **run-e-regioes-010**, vinculo-e-pactos-008, vinculo-e-pactos-009
- **Onda 11** (1): chefes-009

Em negrito: caminho crítico (EX-0001/0002 -> orquestrador -> modificadores -> movimento -> combate -> IA -> câmaras -> portas -> run).

## Tasks

### Must Have (Critical Path)
| ID | Task (story) | Agent/Owner | Est. Days | Dependencies | Onda | Acceptance Criteria |
|----|------|-------------|-----------|-------------|------|-------------------|
| portas-e-recompensas-001 | [RewardTable no catálogo e validação PV1–PV8](../epics/portas-e-recompensas/story-001-reward-table-e-validacao.md) — pronta | gameplay-programmer | 1.0 (M) | bencaos-tradicoes (épico), conteudo (épico) | 1 | ACs da story + evidência do tipo Integration |
| run-e-regioes-001 | [Máquina de estados da Run (com Escolha da dupla)](../epics/run-e-regioes/story-001-maquina-de-estados-da-run.md) — pronta | gameplay-programmer | 1.0 (M) | orquestrador-do-passo (épico) | 1 | ACs da story + evidência do tipo Logic |
| run-e-regioes-002 | [RunTuning e RegionDef no catálogo, validação RN1–RN3](../epics/run-e-regioes/story-002-run-tuning-e-validacao.md) — pronta | gameplay-programmer | 0.5 (S) | armas-das-doutrinas (épico), conteudo (épico) | 1 | ACs da story + evidência do tipo Integration |
| vinculo-e-pactos-001 | [VinculoTuning, memórias do CurseDef e validação VP1–VP9](../epics/vinculo-e-pactos/story-001-vinculo-tuning-e-validacao-vp.md) — pronta | gameplay-programmer | 1.0 (M) | maldicoes-001, conteudo (épico) | 1 | ACs da story + evidência do tipo Logic |
| camaras-e-ondas-006 | [Montagem na Transição — teleporte, Maldição, acuada e 1ª onda](../epics/camaras-e-ondas/story-006-montagem-na-transicao.md) — pronta | gameplay-programmer | 2.0 (L) | camaras-e-ondas-002, camaras-e-ondas-005, maldicoes (épico), orquestrador-do-passo (épico), vinculo-e-pactos (épico) | 2 | ACs da story + evidência do tipo Integration |
| ia-de-inimigos-e-elites-008 | [Alvo padrão acuada por paridade (encontro de pacto)](../epics/ia-de-inimigos-e-elites/story-008-acuada-por-paridade.md) — pronta | ai-programmer | 1.0 (M) | ia-de-inimigos-e-elites-006, combate-nucleo (épico), vinculo-e-pactos (épico) | 2 | ACs da story + evidência do tipo Logic |
| portas-e-recompensas-002 | [Sorteio das portas livres (quantas e quais tipos, F2)](../epics/portas-e-recompensas/story-002-sorteio-das-portas-livres.md) — pronta | gameplay-programmer | 1.0 (M) | portas-e-recompensas-001, rng (épico) | 2 | ACs da story + evidência do tipo Logic |
| run-e-regioes-003 | [Sequência da região — proxima(i), avancar() e regiões reservadas](../epics/run-e-regioes/story-003-sequencia-da-regiao.md) — pronta | gameplay-programmer | 0.5 (S) | run-e-regioes-001, run-e-regioes-002 | 2 | ACs da story + evidência do tipo Logic |
| run-e-regioes-008 | [ResumoDaRun imutável (12 campos) e duração em passos](../epics/run-e-regioes/story-008-resumo-da-run.md) — pronta | gameplay-programmer | 0.5 (S) | run-e-regioes-001 | 2 | ACs da story + evidência do tipo Logic |
| economia-de-fragmentos-004 | [LeituraDaConta, ContaFragmentosNula e injeção na sessão](../epics/economia-de-fragmentos/story-004-leitura-nula-e-composicao.md) — pronta | gameplay-programmer | 1.0 (M) | economia-de-fragmentos-001, economia-de-fragmentos-002, run-e-regioes (épico) | 2 | ACs da story + evidência do tipo Integration |
| vinculo-e-pactos-002 | [PerfilVinculo e o conteúdo da seção `[vinculo]` (escrever/ler/campos_de_ids)](../epics/vinculo-e-pactos/story-002-perfil-vinculo-e-secao-vinculo.md) — pronta | gameplay-programmer | 1.0 (M) | vinculo-e-pactos-001, persistencia (épico) | 2 | ACs da story + evidência do tipo Logic |
| camaras-e-ondas-007 | [Próxima onda, "em combate" e câmara limpa no item 10](../epics/camaras-e-ondas/story-007-ciclo-de-combate-e-limpar.md) — pronta | gameplay-programmer | 1.0 (M) | camaras-e-ondas-006, combate-nucleo (épico) | 3 | ACs da story + evidência do tipo Logic |
| portas-e-recompensas-003 | [Portas forçadas, chaves por índice e consumo fixo](../epics/portas-e-recompensas/story-003-portas-forcadas-e-chaves.md) — pronta | gameplay-programmer | 0.5 (S) | portas-e-recompensas-002, run-e-regioes-003 | 3 | ACs da story + evidência do tipo Logic |
| portas-e-recompensas-004 | [Conceder a recompensa (Fragmentos, cura, bênção)](../epics/portas-e-recompensas/story-004-conceder-recompensa.md) — pronta | gameplay-programmer | 1.0 (M) | portas-e-recompensas-001, bencaos-tradicoes (épico), economia-de-fragmentos (épico), modificadores (épico) | 3 | ACs da story + evidência do tipo Logic |
| run-e-regioes-004 | [Início da run — arma, dupla, seed, estado inicial, câmara 0](../epics/run-e-regioes/story-004-inicio-da-run.md) — pronta | gameplay-programmer | 1.0 (M) | run-e-regioes-003, armas-das-doutrinas (épico), rng (épico), vinculo-e-pactos (épico) | 3 | ACs da story + evidência do tipo Logic |
| chefes-002 | [Montagem e máquina de fases do chefe (ciclo de 4 padrões, sem RNG, Fúria)](../epics/chefes/story-002-maquina-de-fases-do-chefe.md) — pronta | ai-programmer | 1.0 (M) | chefes-001, camaras-e-ondas (épico), ia-de-inimigos-e-elites (épico), telegrafos (épico) | 3 | ACs da story + evidência do tipo Logic |
| economia-de-fragmentos-005 | [Ordem de crédito com Run e Portas (morte vence a limpeza)](../epics/economia-de-fragmentos/story-005-ordem-com-run-e-portas.md) — pronta | gameplay-programmer | 1.0 (M) | economia-de-fragmentos-003, economia-de-fragmentos-004, portas-e-recompensas (épico), run-e-regioes (épico) | 3 | ACs da story + evidência do tipo Integration |
| vinculo-e-pactos-003 | [Primeiro pacto, escolha da dupla e seed em `dupla_confirmada`](../epics/vinculo-e-pactos/story-003-primeiro-pacto-e-escolha-da-dupla.md) — pronta | gameplay-programmer | 1.0 (M) | vinculo-e-pactos-002, run-e-regioes (épico) | 3 | ACs da story + evidência do tipo Integration |
| camaras-e-ondas-008 | [Santuário e portas físicas (posição, alcance, interação)](../epics/camaras-e-ondas/story-008-santuario-e-portas.md) — pronta | gameplay-programmer | 1.0 (M) | camaras-e-ondas-007, input (épico), portas-e-recompensas (épico) | 4 | ACs da story + evidência do tipo Logic |
| portas-e-recompensas-005 | [Fluxo da limpeza (R2): ordem, morte, santuário e fim da run](../epics/portas-e-recompensas/story-005-fluxo-da-limpeza.md) — pronta | gameplay-programmer | 1.0 (M) | portas-e-recompensas-003, portas-e-recompensas-004, run-e-regioes-001, camaras-e-ondas (épico), orquestrador-do-passo (épico) | 4 | ACs da story + evidência do tipo Logic |
| chefes-003 | [Padrões 0 (Garra) e 1 (Irrupção) com alvo travado](../epics/chefes/story-003-padroes-0-e-1-e-alvo-travado.md) — pronta | ai-programmer | 1.0 (M) | chefes-002, maldicoes (épico), movimento-e-esquiva (épico) | 4 | ACs da story + evidência do tipo Logic |
| vinculo-e-pactos-004 | [Sorteio do encontro (F1) no fluxo RNG `pactos` e consultas do encontro](../epics/vinculo-e-pactos/story-004-sorteio-do-encontro.md) — pronta | gameplay-programmer | 1.0 (M) | vinculo-e-pactos-003, rng (épico) | 4 | ACs da story + evidência do tipo Logic |
| portas-e-recompensas-006 | [Estado Aguardando pacto (passo 2b)](../epics/portas-e-recompensas/story-006-aguardando-pacto.md) — pronta | gameplay-programmer | 0.5 (S) | portas-e-recompensas-005, vinculo-e-pactos (épico) | 5 | ACs da story + evidência do tipo Logic |
| portas-e-recompensas-007 | [Escolha da porta, recompensa pendente e EvPortaEscolhida](../epics/portas-e-recompensas/story-007-escolha-da-porta.md) — pronta | gameplay-programmer | 1.0 (M) | portas-e-recompensas-005, run-e-regioes-003 | 5 | ACs da story + evidência do tipo Integration |
| chefes-004 | [Padrão 2 (Pulso de Soberania) e 12 projéteis de alvo único](../epics/chefes/story-004-padrao-2-pulso-e-radiais.md) — pronta | ai-programmer | 1.0 (M) | chefes-003, combate-nucleo (épico) | 5 | ACs da story + evidência do tipo Logic |
| chefes-006 | [Defesas do chefe e TransicaoFase (armadura, imobilização, invulnerabilidade)](../epics/chefes/story-006-defesas-e-transicao-de-fase.md) — pronta | ai-programmer | 1.0 (M) | chefes-003, combate-nucleo (épico), efeitos-de-status (épico), maldicoes (épico) | 5 | ACs da story + evidência do tipo Logic |
| telegrafos-007 | [Formas do chefe (setor, avanço, anel, círculo e contorno secundário)](../epics/telegrafos/story-007-formas-do-chefe.md) — pronta | gameplay-programmer | 1.0 (M) | telegrafos-005, chefes (épico) | 5 | ACs da story + evidência do tipo Logic |
| ia-de-inimigos-e-elites-009 | [Chefe ativo na máquina de fases — TransicaoFase, Subjugado e lacaios](../epics/ia-de-inimigos-e-elites/story-009-chefe-ativo-e-lacaios.md) — pronta | ai-programmer | 1.0 (M) | ia-de-inimigos-e-elites-006, telegrafos-006, telegrafos-007 | 6 | ACs da story + evidência do tipo Logic |
| chefes-005 | [Padrão 3 (Convergência) — puxão, impacto e lacaios com teto](../epics/chefes/story-005-padrao-3-convergencia-e-lacaios.md) — pronta | ai-programmer | 1.0 (M) | chefes-004, movimento-e-esquiva (épico) | 6 | ACs da story + evidência do tipo Logic |
| telegrafos-009 | [TelegraphTuning e validação TV1–TV6](../epics/telegrafos/story-009-tuning-e-validacao.md) — pronta | gameplay-programmer | 1.0 (M) | telegrafos-002, telegrafos-007, conteudo (épico) | 6 | ACs da story + evidência do tipo Integration |
| ia-de-inimigos-e-elites-010 | [IATuning, EnemyDef e EliteRules — validação IV1–IV9 e teto de dano](../epics/ia-de-inimigos-e-elites/story-010-tuning-e-validacao.md) — pronta | ai-programmer | 1.0 (M) | telegrafos-009, conteudo (épico) | 7 | ACs da story + evidência do tipo Integration |
| chefes-001 | [Dados do chefe (EnemyDef, BossPatternDef, ChefesTuning) e validação CH1–CH8](../epics/chefes/story-001-dados-do-chefe-e-validacao.md) — pronta | ai-programmer | 1.0 (M) | armas-das-doutrinas (épico), conteudo (épico), telegrafos (épico) | 7 | ACs da story + evidência do tipo Integration |
| chefes-008 | [Queda do chefe — HitstopFinal, limpeza, Morto e precedência da morte](../epics/chefes/story-008-queda-do-chefe-e-limpeza.md) — pronta | ai-programmer | 1.0 (M) | chefes-005, chefes-006, camaras-e-ondas (épico), combate-nucleo (épico), economia-de-fragmentos (épico) | 7 | ACs da story + evidência do tipo Integration |
| vinculo-e-pactos-005 | [A acuada — nascimento, neutralidade, alvo por paridade, ferir_acuada e fuga](../epics/vinculo-e-pactos/story-005-acuada-alvo-e-fuga.md) — pronta | gameplay-programmer | 2.0 (L) | vinculo-e-pactos-004, maldicoes-008, camaras-e-ondas (épico), combate-nucleo (épico), ia-de-inimigos-e-elites (épico) | 7 | ACs da story + evidência do tipo Integration |
| camaras-e-ondas-009 | [Câmara do chefe — sem sorteio, Subjugado e limpar_camara_chefe](../epics/camaras-e-ondas/story-009-camara-do-chefe.md) — pronta | gameplay-programmer | 1.0 (M) | camaras-e-ondas-007, chefes (épico), ia-de-inimigos-e-elites (épico) | 8 | ACs da story + evidência do tipo Logic |
| economia-de-fragmentos-006 | [Crédito do chefe (abate, Exorcizar; nada ao Pactuar)](../epics/economia-de-fragmentos/story-006-credito-do-chefe.md) — pronta | gameplay-programmer | 1.0 (M) | economia-de-fragmentos-005, chefes (épico), vinculo-e-pactos (épico) | 8 | ACs da story + evidência do tipo Integration |
| vinculo-e-pactos-006 | [Consentimento no estado Bênção, Portas 2b e a dupla que cresce](../epics/vinculo-e-pactos/story-006-consentimento-portas-e-dupla.md) — pronta | gameplay-programmer | 2.0 (L) | vinculo-e-pactos-005, maldicoes-006, persistencia (épico), portas-e-recompensas (épico) | 8 | ACs da story + evidência do tipo Integration |
| run-e-regioes-005 | [Composição da sessão, EscopoDaRun e nova_run por recriação](../epics/run-e-regioes/story-005-composicao-e-escopo-da-run.md) — pronta | gameplay-programmer | 2.0 (L) | run-e-regioes-004, economia-de-fragmentos (épico), orquestrador-do-passo (épico), persistencia (épico) | 9 | ACs da story + evidência do tipo Integration |
| vinculo-e-pactos-007 | [Pontos e níveis (F3), consolidação no fim da run, abandono e bônus de nível (F4)](../epics/vinculo-e-pactos/story-007-pontos-niveis-e-consolidacao.md) — pronta | gameplay-programmer | 2.0 (L) | vinculo-e-pactos-006, modificadores (épico), run-e-regioes (épico) | 9 | ACs da story + evidência do tipo Logic |
| run-e-regioes-006 | [Vitória — câmara do chefe, crédito e run_encerrada](../epics/run-e-regioes/story-006-vitoria.md) — pronta | gameplay-programmer | 1.0 (M) | run-e-regioes-005, run-e-regioes-008, portas-e-recompensas-005, portas-e-recompensas-007 | 10 | ACs da story + evidência do tipo Integration |
| run-e-regioes-007 | [Morte, abandono e regras da pausa](../epics/run-e-regioes/story-007-morte-abandono-e-pausa.md) — pronta | gameplay-programmer | 1.0 (M) | run-e-regioes-005, run-e-regioes-008, combate-nucleo (épico) | 10 | ACs da story + evidência do tipo Logic |
| run-e-regioes-010 | [Gravação do perfil no fim da run e saída do jogo](../epics/run-e-regioes/story-010-perfil-e-saida-do-jogo.md) — pronta | gameplay-programmer | 1.0 (M) | run-e-regioes-005, persistencia (épico), vinculo-e-pactos (épico) | 10 | ACs da story + evidência do tipo Integration |
| vinculo-e-pactos-008 | [Chefe subjugado — Pactuar ou Exorcizar](../epics/vinculo-e-pactos/story-008-chefe-pactuar-ou-exorcizar.md) — pronta | gameplay-programmer | 1.0 (M) | vinculo-e-pactos-007, chefes (épico) | 10 | ACs da story + evidência do tipo Integration |
| vinculo-e-pactos-009 | [Eventos do Vínculo para a Telemetria (estado inicial ampliado, encontro, pacto, fim de run)](../epics/vinculo-e-pactos/story-009-eventos-para-telemetria.md) — pronta | gameplay-programmer | 0.5 (S) | vinculo-e-pactos-007 | 10 | ACs da story + evidência do tipo Logic |
| chefes-009 | [Subjugado e escolha Pactuar/Exorcizar (R9b)](../epics/chefes/story-009-subjugado-e-escolha.md) — pronta | ai-programmer | 1.0 (M) | chefes-008, run-e-regioes-006, vinculo-e-pactos (épico) | 11 | ACs da story + evidência do tipo Integration |

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
| — | Definido por `/sprint-plan update` ao fechar a Sprint 5 | — |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Feriados de fim de ano (25/12 e 01/01) dentro da janela | Alta | Médio | Sprint de 2 semanas já absorve; não planejar revisão humana nesses dias |
| Chefe (Soberano) e run/regiões fecham o loop ao mesmo tempo — integração tardia | Média | Alto | Playtest interno do loop sem polimento na metade da sprint |

## Dependencies on External Factors
- Godot 4.7.2 instalado (`docs/engine-reference/godot/VERSION.md`); GdUnit4 para a suíte.
- Aprovação humana de evidências visuais (lead sign-off) para stories Visual/Feel e UI.
- Sem registro de riscos em `production/risk-register/`: riscos avaliados só pelo conteúdo da sprint.

## Definition of Done for this Sprint
- [x] All Must Have tasks completed
- [x] All tasks pass acceptance criteria
- [x] All Logic/Integration stories have passing unit/integration tests
- [x] Toda story que muda algo observável pelo jogador foi rodada e tem screenshot retido em `production/qa/evidence/`
- [x] QA sign-off report: APPROVED
- [x] No S1 or S2 bugs in delivered features
- [x] A fatia jogável continua abrindo por `res://scenes/main.tscn`
- [x] Design documents updated for any deviations
- [x] Code reviewed and merged
