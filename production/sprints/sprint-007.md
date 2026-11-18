# Sprint 7 — 2027-01-18 to 2027-01-31

> Gerado por `/sprint-plan new` (orquestrado, 2026-11-16). Plano do marco MVP em 9 sprints — uma por onda de dependência.

## Sprint Goal
Apresentação: pipeline visual, feedback de combate, HUD e tela de bênção/carta sobre o loop completo.

## Goal Prerequisites
| Needed to show the goal | Status |
|-------------------------|--------|
| Cena principal (`run/main_scene` = `res://scenes/main.tscn`) | exists |

## Milestone Context
- Current Milestone: MVP ([production/milestones/mvp.md](../milestones/mvp.md))
- Milestone Deadline: 2027-02-14
- Sprints Remaining: 3 (incluindo esta)

## Capacity
- Equipe: 7 agentes de IA em paralelo (6–8), 2 semana(s) úteis
- Total days: 70 agente-dia
- Buffer (20%): 14 agente-dia
- Available: 56 agente-dia
- Carga planejada: 42.0 agente-dia (38 stories; S=0,5 / M=1 / L=2)
- Estimativa não calibrada: não há histórico de velocidade (primeira sprint do plano).

## Ordem e paralelismo
Stories numa mesma onda não dependem entre si e podem correr ao mesmo tempo (até 7 agentes, um por pasta de sistema). Uma onda começa quando as dependências dela, na onda anterior, fecham — não a onda inteira.

- **Onda 1** (5): feedback-de-combate-001, hud-001, pipeline-visual-001, tela-de-bencao-e-carta-001, tela-de-bencao-e-carta-004
- **Onda 2** (17): **camaras-e-ondas-010**, **combate-nucleo-010**, **movimento-e-esquiva-009**, **portas-e-recompensas-008**, **run-e-regioes-009**, chefes-007, feedback-de-combate-002, hud-002, hud-003, hud-005, persistencia-010, pipeline-visual-002, pipeline-visual-004, pipeline-visual-006, rng-007, tela-de-bencao-e-carta-002, vinculo-e-pactos-010
- **Onda 3** (7): economia-de-fragmentos-007, feedback-de-combate-003, feedback-de-combate-004, feedback-de-combate-005, hud-004, pipeline-visual-003, tela-de-bencao-e-carta-003
- **Onda 4** (4): feedback-de-combate-006, input-009, pipeline-visual-005, tela-de-bencao-e-carta-006
- **Onda 5** (2): pipeline-visual-007, pipeline-visual-008
- **Onda 6** (2): feedback-de-combate-008, pipeline-visual-009
- **Onda 7** (1): pipeline-visual-010

Em negrito: caminho crítico (EX-0001/0002 -> orquestrador -> modificadores -> movimento -> combate -> IA -> câmaras -> portas -> run).

## Tasks

### Must Have (Critical Path)
| ID | Task (story) | Agent/Owner | Est. Days | Dependencies | Onda | Acceptance Criteria |
|----|------|-------------|-----------|-------------|------|-------------------|
| feedback-de-combate-001 | [FeedbackTuning e catálogo evento → resposta com validação FB1–FB3](../epics/feedback-de-combate/story-001-feedback-tuning-e-catalogo-de-respostas.md) — pronta | technical-artist | 1.0 (M) | conteudo (épico), orquestrador-do-passo (épico) | 1 | ACs da story + evidência do tipo Logic |
| hud-001 | [Modelo do HUD — leitura injetada, relógio de interface e HudTuning](../epics/hud/story-001-modelo-do-hud-leitura-e-relogio.md) — pronta | ui-programmer | 1.0 (M) | assets-e-conteudo-001, conteudo (épico), orquestrador-do-passo (épico) | 1 | ACs da story + evidência do tipo Logic |
| pipeline-visual-001 | [VisualTuning no catálogo, injeção e validação VV](../epics/pipeline-visual/story-001-visual-tuning-e-validacao.md) — pronta | technical-artist | 1.0 (M) | conteudo (épico) | 1 | ACs da story + evidência do tipo Logic |
| tela-de-bencao-e-carta-001 | [ModeloDeFoco, DadosDaCarta e fileira (F1, F2, navegação)](../epics/tela-de-bencao-e-carta/story-001-modelo-de-foco-dados-da-carta-e-fileira.md) — pronta | ui-programmer | 1.0 (M) | input (épico) | 1 | ACs da story + evidência do tipo Logic |
| tela-de-bencao-e-carta-004 | [TelaBencaoTuning — injeção e validação TB1–TB10](../epics/tela-de-bencao-e-carta/story-004-tela-bencao-tuning-validacao.md) — pronta | ui-programmer | 0.5 (S) | assets-e-conteudo-001, conteudo (épico) | 1 | ACs da story + evidência do tipo Logic |
| camaras-e-ondas-010 | [Evidência visual da arena e das portas; duração da câmara](../epics/camaras-e-ondas/story-010-evidencia-visual-arena-e-portas.md) — pronta | gameplay-programmer | 0.5 (S) | camaras-e-ondas-008, pipeline-visual (épico) | 2 | ACs da story + evidência do tipo Visual/Feel |
| combate-nucleo-010 | [Leitura visual, desempenho e latência do golpe](../epics/combate-nucleo/story-010-leitura-visual-desempenho-e-latencia.md) — pronta | gameplay-programmer | 1.0 (M) | combate-nucleo-008, combate-nucleo-009, experimentos-de-engine (épico), feedback-de-combate (épico), pipeline-visual (épico) | 2 | ACs da story + evidência do tipo Visual/Feel |
| movimento-e-esquiva-009 | [Evidência visual e de feel: sem rastro no teleporte, esquiva em 1920×1080, áudio](../epics/movimento-e-esquiva/story-009-evidencia-visual-e-feel-da-esquiva.md) — pronta | gameplay-programmer | 0.5 (S) | cena-e-camera (épico), pipeline-visual (épico) | 2 | ACs da story + evidência do tipo Visual/Feel |
| portas-e-recompensas-008 | [Portas no mundo — moldura, ícones e quantidade](../epics/portas-e-recompensas/story-008-portas-no-mundo.md) — pronta | gameplay-programmer | 1.0 (M) | portas-e-recompensas-007, pipeline-visual (épico) | 2 | ACs da story + evidência do tipo Visual/Feel |
| run-e-regioes-009 | [Telas de início, pausa e final ligadas à Run](../epics/run-e-regioes/story-009-telas-de-inicio-pausa-e-final.md) — pronta | ui-programmer | 1.0 (M) | run-e-regioes-007, run-e-regioes-008, run-e-regioes-010, hud (épico) | 2 | ACs da story + evidência do tipo UI |
| chefes-007 | [Barra de chefe no HUD](../epics/chefes/story-007-barra-de-chefe-no-hud.md) — pronta | ui-programmer | 0.5 (S) | chefes-006, hud (épico) | 2 | ACs da story + evidência do tipo UI |
| feedback-de-combate-002 | [Árbitro puro — eventos e relógios entram, pedidos ordenados saem](../epics/feedback-de-combate/story-002-arbitro-puro.md) — pronta | technical-artist | 1.0 (M) | feedback-de-combate-001, combate-nucleo (épico) | 2 | ACs da story + evidência do tipo Logic |
| hud-002 | [Vida — segmentos, largura, rachar, escudo, recusas e Vida baixa](../epics/hud/story-002-vida-segmentos-racha-e-vida-baixa.md) — pronta | ui-programmer | 1.0 (M) | hud-001 | 2 | ACs da story + evidência do tipo Logic |
| hud-003 | [Fluxo, Esquiva, Fragmentos e glifos por dispositivo](../epics/hud/story-003-fluxo-esquiva-fragmentos-e-glifos.md) — pronta | ui-programmer | 1.0 (M) | hud-001, input (épico) | 2 | ACs da story + evidência do tipo Logic |
| hud-005 | [Bloco do Pacto — modelo (existência, posição, F8, estados e eventos)](../epics/hud/story-005-bloco-do-pacto.md) — pronta | ui-programmer | 1.0 (M) | hud-001, maldicoes (épico) | 2 | ACs da story + evidência do tipo Logic |
| persistencia-010 | [Avisos PERFIL_* uma vez por sessão, só fora de Jogo, com foco duplo](../epics/persistencia/story-010-avisos-do-perfil.md) — pronta | ui-programmer | 0.5 (S) | hud (épico) | 2 | ACs da story + evidência do tipo UI |
| pipeline-visual-002 | [LimitadorDeFlashes (F6) com preempção do chefe](../epics/pipeline-visual/story-002-limitador-de-flashes-f6.md) — pronta | technical-artist | 1.0 (M) | pipeline-visual-001 | 2 | ACs da story + evidência do tipo Logic |
| pipeline-visual-004 | [Espelho em CPU de F1 (LUT), F2 (profundidade) e F5 (Bênção)](../epics/pipeline-visual/story-004-espelho-lut-profundidade-bencao.md) — pronta | technical-artist | 1.0 (M) | pipeline-visual-001 | 2 | ACs da story + evidência do tipo Logic |
| pipeline-visual-006 | [Espelho do SDF do telégrafo (F3, F4) e do tracejado (F7)](../epics/pipeline-visual/story-006-espelho-sdf-e-tracejado.md) — pronta | technical-artist | 1.0 (M) | pipeline-visual-001 | 2 | ACs da story + evidência do tipo Logic |
| rng-007 | [Texto da seed na interface (pausa, morte, vitória e debug)](../epics/rng/story-007-texto-da-seed-na-interface.md) — pronta | ui-programmer | 0.5 (S) | rng-004, hud (épico) | 2 | ACs da story + evidência do tipo UI |
| tela-de-bencao-e-carta-002 | [GrupoDeCartas — 8 estados, travas por borda de subida, pausa e foco da janela](../epics/tela-de-bencao-e-carta/story-002-grupo-de-cartas-estados-e-travas.md) — pronta | ui-programmer | 1.0 (M) | tela-de-bencao-e-carta-001, hud-001, input (épico) | 2 | ACs da story + evidência do tipo Logic |
| vinculo-e-pactos-010 | [Telas do pacto — Escolha do Pacto, Primeiro Vínculo, consentimento, Pactuar/Exorcizar e painel final](../epics/vinculo-e-pactos/story-010-telas-do-pacto.md) — pronta | ui-programmer | 2.0 (L) | vinculo-e-pactos-003, vinculo-e-pactos-006, vinculo-e-pactos-008, hud (épico), tela-de-bencao-e-carta (épico) | 2 | ACs da story + evidência do tipo UI |
| economia-de-fragmentos-007 | [Saldo e "+N" no HUD — evidência](../epics/economia-de-fragmentos/story-007-saldo-no-hud-evidencia.md) — pronta | ui-programmer | 0.5 (S) | economia-de-fragmentos-004, hud (épico), portas-e-recompensas (épico) | 3 | ACs da story + evidência do tipo UI |
| feedback-de-combate-003 | [Preempção no mesmo passo e remetente único de impulso de câmera](../epics/feedback-de-combate/story-003-preempcao-e-impulso-de-camera.md) — pronta | technical-artist | 1.0 (M) | feedback-de-combate-002, pipeline-visual-002 | 3 | ACs da story + evidência do tipo Logic |
| feedback-de-combate-004 | [PoolDeNumeros — faixas por alvo, soma, teto 6 e número agregado jogador + Maldição](../epics/feedback-de-combate/story-004-pool-de-numeros-de-dano.md) — pronta | technical-artist | 1.0 (M) | feedback-de-combate-002 | 3 | ACs da story + evidência do tipo Logic |
| feedback-de-combate-005 | [Degradação de VFX por uso medido, com histerese, e P0/P1 protegidos](../epics/feedback-de-combate/story-005-degradacao-por-uso-medido.md) — pronta | technical-artist | 1.0 (M) | feedback-de-combate-002 | 3 | ACs da story + evidência do tipo Logic |
| hud-004 | [Fios de Vida, prompt de interação, barra de chefe e visibilidade por estado](../epics/hud/story-004-fios-prompt-chefe-e-visibilidade.md) — pronta | ui-programmer | 1.0 (M) | hud-001, camaras-e-ondas (épico), cena-e-camera (épico) | 3 | ACs da story + evidência do tipo Logic |
| pipeline-visual-003 | [Modos de tela, PasseDeTela e relógios t_vivo/t_apres](../epics/pipeline-visual/story-003-modos-de-tela-passes-e-relogios.md) — pronta | technical-artist | 1.0 (M) | pipeline-visual-001, pipeline-visual-002, orquestrador-do-passo (épico) | 3 | ACs da story + evidência do tipo Logic |
| tela-de-bencao-e-carta-003 | [Troca, confirmação, PortaDaBencao e sinais preco_revelado / tela_fechada](../epics/tela-de-bencao-e-carta/story-003-troca-confirmacao-e-sinais.md) — pronta | ui-programmer | 1.0 (M) | tela-de-bencao-e-carta-002, hud-002 | 3 | ACs da story + evidência do tipo Logic |
| feedback-de-combate-006 | [Relógios vivo/apresentação, pausa, Bênção, Transição e opções de acessibilidade](../epics/feedback-de-combate/story-006-relogios-pausa-transicao-e-opcoes.md) — pronta | technical-artist | 1.0 (M) | feedback-de-combate-004, pipeline-visual-003, persistencia (épico) | 4 | ACs da story + evidência do tipo Logic |
| input-009 | [Foco único, telas sem mouse e campo de texto](../epics/input/story-009-foco-unico-e-telas-sem-mouse.md) — pronta | ui-programmer | 2.0 (L) | input-005, hud (épico), tela-de-bencao-e-carta (épico) | 4 | ACs da story + evidência do tipo UI |
| pipeline-visual-005 | [EscritorDeGlobais, PipelineVisual, famílias de shader e chaves do projeto](../epics/pipeline-visual/story-005-escritor-de-globais-e-pipeline-visual.md) — pronta | technical-artist | 2.0 (L) | pipeline-visual-003, pipeline-visual-004, cena-e-camera (épico), experimentos-de-engine (épico) | 4 | ACs da story + evidência do tipo Integration |
| tela-de-bencao-e-carta-006 | [Integração com a Bênçãos real — oferta pela lista do passo e tela_fechada](../epics/tela-de-bencao-e-carta/story-006-integracao-com-bencaos-real.md) — pronta | ui-programmer | 0.5 (S) | tela-de-bencao-e-carta-003, bencaos-tradicoes (épico), orquestrador-do-passo (épico) | 4 | ACs da story + evidência do tipo Integration |
| pipeline-visual-007 | [Pool de 24 slots de telégrafo, duas passadas e contorno secundário](../epics/pipeline-visual/story-007-pool-de-telegrafos-24-slots.md) — pronta | technical-artist | 2.0 (L) | pipeline-visual-005, pipeline-visual-006, experimentos-de-engine (épico), telegrafos (épico) | 5 | ACs da story + evidência do tipo Integration |
| pipeline-visual-008 | [Nós por camada (ambiente, entidades, oclusão), material por entidade e validador](../epics/pipeline-visual/story-008-nos-por-camada-e-validador.md) — pronta | technical-artist | 2.0 (L) | pipeline-visual-005, cena-e-camera (épico), experimentos-de-engine (épico) | 5 | ACs da story + evidência do tipo Integration |
| feedback-de-combate-008 | [Vistas e pool de VFX ligados ao Combate real](../epics/feedback-de-combate/story-008-vistas-e-pool-de-vfx.md) — pronta | technical-artist | 2.0 (L) | pipeline-visual-008, combate-nucleo (épico) | 6 | ACs da story + evidência do tipo Visual/Feel |
| pipeline-visual-009 | [Traço do jogador (CanvasGroup, inversão, imagens residuais) e VFX das Maldições](../epics/pipeline-visual/story-009-traco-do-jogador-e-vfx-das-maldicoes.md) — pronta | technical-artist | 2.0 (L) | pipeline-visual-008, experimentos-de-engine (épico) | 6 | ACs da story + evidência do tipo Visual/Feel |
| pipeline-visual-010 | [Impact frames vistos, orçamento e memória por captura, acessibilidade e leitura](../epics/pipeline-visual/story-010-impact-frames-orcamento-e-leitura.md) — pronta | technical-artist | 2.0 (L) | pipeline-visual-007, pipeline-visual-008, pipeline-visual-009, experimentos-de-engine (épico) | 7 | ACs da story + evidência do tipo Visual/Feel |

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
| — | Definido por `/sprint-plan update` ao fechar a Sprint 6 | — |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Apresentação depende de EX-0011 E1–E3 e da API de telégrafos | Média | Médio | Confirmar os experimentos fechados na S1; pipeline-visual primeiro |
| Evidência visual (screenshot retido) atrasa o fechamento de stories Visual/UI | Alta | Médio | Captura em `production/qa/evidence/` faz parte da story, não da QA final |

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
