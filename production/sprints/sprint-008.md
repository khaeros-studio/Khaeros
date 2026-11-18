# Sprint 8 — 2027-02-01 to 2027-02-07

> Gerado por `/sprint-plan new` (orquestrado, 2026-11-16). Plano do marco MVP em 9 sprints — uma por onda de dependência.

## Sprint Goal
Áudio (ganchos e vozes), telemetria local e fechamento das stories de armas/telégrafos que dependem de Apresentação.

## Goal Prerequisites
| Needed to show the goal | Status |
|-------------------------|--------|
| Cena principal (`run/main_scene` = `res://scenes/main.tscn`) | exists |

## Milestone Context
- Current Milestone: MVP ([production/milestones/mvp.md](../milestones/mvp.md))
- Milestone Deadline: 2027-02-14
- Sprints Remaining: 2 (incluindo esta)

## Capacity
- Equipe: 7 agentes de IA em paralelo (6–8), 1 semana(s) úteis
- Total days: 35 agente-dia
- Buffer (20%): 7 agente-dia
- Available: 28 agente-dia
- Carga planejada: 22.0 agente-dia (23 stories; S=0,5 / M=1 / L=2)
- Estimativa não calibrada: não há histórico de velocidade (primeira sprint do plano).

## Ordem e paralelismo
Stories numa mesma onda não dependem entre si e podem correr ao mesmo tempo (até 7 agentes, um por pasta de sistema). Uma onda começa quando as dependências dela, na onda anterior, fecham — não a onda inteira.

- **Onda 1** (2): audio-001, telemetria-local-001
- **Onda 2** (10): armas-das-doutrinas-004, audio-002, audio-003, maldicoes-010, telegrafos-010, telemetria-local-002, telemetria-local-003, telemetria-local-004, telemetria-local-005, telemetria-local-006
- **Onda 3** (5): armas-das-doutrinas-005, audio-004, feedback-de-combate-007, telemetria-local-007, telemetria-local-009
- **Onda 4** (4): armas-das-doutrinas-007, audio-005, chefes-010, telemetria-local-008
- **Onda 5** (2): armas-das-doutrinas-008, telemetria-local-010

Em negrito: caminho crítico (EX-0001/0002 -> orquestrador -> modificadores -> movimento -> combate -> IA -> câmaras -> portas -> run).

## Tasks

### Must Have (Critical Path)
| ID | Task (story) | Agent/Owner | Est. Days | Dependencies | Onda | Acceptance Criteria |
|----|------|-------------|-----------|-------------|------|-------------------|
| audio-001 | [SomDef, AudioTuning, PedidoDeSom e FilaDeSonsDeInterface](../epics/audio/story-001-somdef-audiotuning-e-pedidos.md) — pronta | sound-designer | 0.5 (S) | conteudo (épico) | 1 | ACs da story + evidência do tipo Logic |
| telemetria-local-001 | [Abertura da sessão, arquivo `.jsonl`, campos comuns e TelemetriaTuning](../epics/telemetria-local/story-001-sessao-arquivo-e-campos-comuns.md) — pronta | analytics-engineer | 1.0 (M) | conteudo (épico), experimentos-de-engine (épico), persistencia (épico) | 1 | ACs da story + evidência do tipo Logic |
| armas-das-doutrinas-004 | [Arma da run — estados, injeção e telemetria](../epics/armas-das-doutrinas/story-004-arma-da-run-e-injecao.md) — pronta | gameplay-programmer | 1.0 (M) | armas-das-doutrinas-002, combate-nucleo-003, bencaos-tradicoes (épico), run-e-regioes (épico), telemetria-local (épico) | 2 | ACs da story + evidência do tipo Integration |
| audio-002 | [MixadorDeVozes — dedupe, limites e roubo (F4)](../epics/audio/story-002-mixador-de-vozes.md) — pronta | sound-designer | 1.0 (M) | audio-001 | 2 | ACs da story + evidência do tipo Logic |
| audio-003 | [SeletorDeTons — no máximo 3 telégrafos soando, pitch por p](../epics/audio/story-003-seletor-de-tons-dos-telegrafos.md) — pronta | sound-designer | 0.5 (S) | audio-001, telegrafos (épico) | 2 | ACs da story + evidência do tipo Logic |
| maldicoes-010 | [Fio de vínculo, marca do Virote, leitura da Maldição e ganchos `sfx_maldicao_*`](../epics/maldicoes/story-010-fio-marca-e-ganchos-de-som.md) — pronta | gameplay-programmer | 1.0 (M) | maldicoes-009, audio (épico), pipeline-visual (épico) | 2 | ACs da story + evidência do tipo Visual/Feel |
| telegrafos-010 | [Telégrafos na tela e no som (captura de multidão, flash, acessibilidade)](../epics/telegrafos/story-010-captura-visual-e-audio.md) — pronta | gameplay-programmer | 1.0 (M) | telegrafos-008, audio (épico), cena-e-camera (épico), pipeline-visual (épico) | 2 | ACs da story + evidência do tipo Visual/Feel |
| telemetria-local-002 | [Só escuta, o jogo nunca lê, e privacidade](../epics/telemetria-local/story-002-so-escuta-e-privacidade.md) — pronta | analytics-engineer | 0.5 (S) | telemetria-local-001, orquestrador-do-passo (épico) | 2 | ACs da story + evidência do tipo Logic |
| telemetria-local-003 | [Opção `telemetria_ligada` (Armada/Desligada) e "Apagar dados"](../epics/telemetria-local/story-003-opcao-ligada-e-apagar-dados.md) — pronta | analytics-engineer | 1.0 (M) | telemetria-local-001, persistencia (épico) | 2 | ACs da story + evidência do tipo Logic |
| telemetria-local-004 | [Falhas absorvidas (TL1, Parada por falha), campo ausente (TL3) e orçamento por linha (TL2)](../epics/telemetria-local/story-004-falhas-e-orcamento-por-linha.md) — pronta | analytics-engineer | 1.0 (M) | telemetria-local-001 | 2 | ACs da story + evidência do tipo Logic |
| telemetria-local-005 | [Limite de bytes com reserva, retenção de 20 sessões e linha truncada](../epics/telemetria-local/story-005-limite-retencao-e-truncamento.md) — pronta | analytics-engineer | 1.0 (M) | telemetria-local-001 | 2 | ACs da story + evidência do tipo Logic |
| telemetria-local-006 | [Linhas de run — `run_iniciada`, `run_encerrada`, abandono, nova run, seed e impressão](../epics/telemetria-local/story-006-linhas-de-run-seed-e-impressao.md) — pronta | analytics-engineer | 1.0 (M) | telemetria-local-001, rng (épico), run-e-regioes (épico) | 2 | ACs da story + evidência do tipo Logic |
| armas-das-doutrinas-005 | [Pré-seleção, confirmação e preferência `ultima_arma`](../epics/armas-das-doutrinas/story-005-preferencia-ultima-arma.md) — pronta | gameplay-programmer | 0.5 (S) | armas-das-doutrinas-004, persistencia (épico) | 3 | ACs da story + evidência do tipo Logic |
| audio-004 | [AudioDoJogo — pools no _ready, barramentos, volumes e comportamento por estado](../epics/audio/story-004-audio-do-jogo-no.md) — pronta | sound-designer | 2.0 (L) | audio-002, audio-003, feedback-de-combate-008, experimentos-de-engine (épico), orquestrador-do-passo (épico), persistencia (épico) | 3 | ACs da story + evidência do tipo Integration |
| feedback-de-combate-007 | [Respostas das Maldições e ganchos sfx_maldicao_*](../epics/feedback-de-combate/story-007-respostas-das-maldicoes.md) — pronta | technical-artist | 1.0 (M) | feedback-de-combate-003, feedback-de-combate-004, audio-001, maldicoes (épico) | 3 | ACs da story + evidência do tipo Logic |
| telemetria-local-007 | [Linha de câmara — contadores, duração em passos de Jogo e morte no mesmo passo](../epics/telemetria-local/story-007-linha-de-camara-e-contadores.md) — pronta | analytics-engineer | 1.0 (M) | telemetria-local-006, camaras-e-ondas (épico), combate-nucleo (épico) | 3 | ACs da story + evidência do tipo Logic |
| telemetria-local-009 | [Schema 2 — `run_iniciada` de Pactos, resumo de 12 campos, `encontro_pacto`, `pacto` e `vinculo_fim_run`](../epics/telemetria-local/story-009-schema-2-pactos.md) — pronta | analytics-engineer | 1.0 (M) | telemetria-local-006, vinculo-e-pactos-009 | 3 | ACs da story + evidência do tipo Logic |
| armas-das-doutrinas-007 | [Tela de escolha de arma](../epics/armas-das-doutrinas/story-007-tela-de-escolha-de-arma.md) — pronta | ui-programmer | 1.0 (M) | armas-das-doutrinas-005, input (épico), tela-de-bencao-e-carta (épico) | 4 | ACs da story + evidência do tipo UI |
| audio-005 | [Escuta em playtest — no máximo 3 tons, estalo sempre audível, custo medido](../epics/audio/story-005-escuta-e-medicao-em-playtest.md) — pronta | sound-designer | 0.5 (S) | audio-004, pipeline-visual-010 | 4 | ACs da story + evidência do tipo Visual/Feel |
| chefes-010 | [Apresentação do chefe — impact frame, luz, Fase 2, contorno secundário e áudio](../epics/chefes/story-010-apresentacao-do-chefe.md) — pronta | ai-programmer | 1.0 (M) | chefes-008, audio (épico), feedback-de-combate (épico), pipeline-visual (épico) | 4 | ACs da story + evidência do tipo Visual/Feel |
| telemetria-local-008 | [Linhas de oferta, bênção, porta e morte](../epics/telemetria-local/story-008-oferta-porta-e-morte.md) — pronta | analytics-engineer | 0.5 (S) | telemetria-local-007, bencaos-tradicoes (épico), combate-nucleo (épico), portas-e-recompensas (épico) | 4 | ACs da story + evidência do tipo Logic |
| armas-das-doutrinas-008 | [Silhueta das armas e verificação em jogo](../epics/armas-das-doutrinas/story-008-verificacao-em-jogo.md) — pronta | gameplay-programmer | 1.0 (M) | armas-das-doutrinas-004, armas-das-doutrinas-006, armas-das-doutrinas-007, combate-nucleo-010 | 5 | ACs da story + evidência do tipo Visual/Feel |
| telemetria-local-010 | [Run completa com sistemas reais, leitura de fixture e pior passo (5 linhas em 3 ms)](../epics/telemetria-local/story-010-run-completa-e-pior-passo.md) — pronta | analytics-engineer | 2.0 (L) | chefes (épico), experimentos-de-engine (épico), run-e-regioes (épico), vinculo-e-pactos (épico) | 5 | ACs da story + evidência do tipo Integration |

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
| — | Definido por `/sprint-plan update` ao fechar a Sprint 7 | — |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Telemetria local toca muitos sistemas (10 stories) — risco de acoplamento | Média | Médio | Somente via canal de eventos (ADR-0002); nenhum sistema chama telemetria diretamente |
| Assets de áudio P0 não prontos para o gancho | Média | Médio | Ganchos com placeholders; assets-e-conteudo 009 na S9 |

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
