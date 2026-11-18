# Sprint 9 — 2027-02-08 to 2027-02-14

> Gerado por `/sprint-plan new` (orquestrado, 2026-11-16). Plano do marco MVP em 9 sprints — uma por onda de dependência.

## Sprint Goal
Integração final do MVP: arte e áudio do lote final, HUD e tela de bênção completas, smoke-check PASS e playtest do loop Limiar -> Soberano com as 3 Doutrinas.

## Goal Prerequisites
| Needed to show the goal | Status |
|-------------------------|--------|
| Cena principal (`run/main_scene` = `res://scenes/main.tscn`) | exists |
| Loop Limiar -> Soberano montado (run-e-regioes, chefes) | built by S6 (run-e-regioes, chefes) |
| Roteiro/story de playtest do loop completo com as 3 Doutrinas | **missing** — nenhuma story do backlog o cria |
| Execução de `/smoke-check sprint` | skill, não story — no DoD |

## Milestone Context
- Current Milestone: MVP ([production/milestones/mvp.md](../milestones/mvp.md))
- Milestone Deadline: 2027-02-14
- Sprints Remaining: 1 (incluindo esta)

## Capacity
- Equipe: 7 agentes de IA em paralelo (6–8), 1 semana(s) úteis
- Total days: 35 agente-dia
- Buffer (20%): 7 agente-dia
- Available: 28 agente-dia
- Carga planejada: 18.5 agente-dia (13 stories; S=0,5 / M=1 / L=2)
- Estimativa não calibrada: não há histórico de velocidade (primeira sprint do plano).

## Ordem e paralelismo
Stories numa mesma onda não dependem entre si e podem correr ao mesmo tempo (até 7 agentes, um por pasta de sistema). Uma onda começa quando as dependências dela, na onda anterior, fecham — não a onda inteira.

- **Onda 1** (3): assets-e-conteudo-006, assets-e-conteudo-008, assets-e-conteudo-009
- **Onda 2** (2): assets-e-conteudo-007, hud-006
- **Onda 3** (2): hud-007, hud-008
- **Onda 4** (3): hud-009, hud-010, tela-de-bencao-e-carta-005
- **Onda 5** (2): tela-de-bencao-e-carta-007, tela-de-bencao-e-carta-009
- **Onda 6** (1): tela-de-bencao-e-carta-008

Em negrito: caminho crítico (EX-0001/0002 -> orquestrador -> modificadores -> movimento -> combate -> IA -> câmaras -> portas -> run).

## Tasks

### Must Have (Critical Path)
| ID | Task (story) | Agent/Owner | Est. Days | Dependencies | Onda | Acceptance Criteria |
|----|------|-------------|-----------|-------------|------|-------------------|
| assets-e-conteudo-006 | [Fechar o lote 02 de arte — Anomalia Menor, Fenda Errante e peças de elite](../epics/assets-e-conteudo/story-006-arte-lote-02-inimigos-do-limiar.md) — pronta | technical-artist | 2.0 (L) | pipeline-visual (épico) | 1 | ACs da story + evidência do tipo Visual/Feel |
| assets-e-conteudo-008 | [LUT por região, VFX base e arte de UI (cartas, placas, ícones, glifos, fonte)](../epics/assets-e-conteudo/story-008-lut-por-regiao-e-arte-de-ui.md) — pronta | technical-artist | 2.0 (L) | experimentos-de-engine (épico), pipeline-visual (épico) | 1 | ACs da story + evidência do tipo Visual/Feel |
| assets-e-conteudo-007 | [Arte das Maldições e do chefe (atores, silhuetas de HUD, retratos de escolha)](../epics/assets-e-conteudo/story-007-arte-de-maldicoes-e-chefe.md) — pronta | technical-artist | 2.0 (L) | assets-e-conteudo-006 | 2 | ACs da story + evidência do tipo Visual/Feel |
| hud-006 | [Vista do HUD — Control em CanvasLayer, âncoras, escala, vinheta no Pós e troca do game_hud](../epics/hud/story-006-vista-do-hud-control-ancoras-e-escala.md) — pronta | ui-programmer | 2.0 (L) | hud-002, assets-e-conteudo-008, cena-e-camera (épico), experimentos-de-engine (épico), pipeline-visual (épico) | 2 | ACs da story + evidência do tipo UI |
| hud-007 | [Opções de acessibilidade do HUD — aplicação e persistência](../epics/hud/story-007-opcoes-de-acessibilidade-do-hud.md) — pronta | ui-programmer | 0.5 (S) | hud-006, persistencia (épico) | 3 | ACs da story + evidência do tipo Integration |
| hud-008 | [Menu de pausa — Continuar, Abandonar run e seed copiável](../epics/hud/story-008-menu-de-pausa-abandono-e-seed.md) — pronta | ui-programmer | 1.0 (M) | hud-006, tela-de-bencao-e-carta-001, input (épico), orquestrador-do-passo (épico), rng (épico) | 3 | ACs da story + evidência do tipo UI |
| hud-009 | [Tela de opções — escala, HUD, remapeamento, telemetria e reset do perfil](../epics/hud/story-009-tela-de-opcoes.md) — pronta | ui-programmer | 2.0 (L) | hud-007, hud-008, experimentos-de-engine (épico), input (épico), persistencia (épico) | 4 | ACs da story + evidência do tipo UI |
| hud-010 | [Tela de fim de run — resumo, painel de vínculo, seed e Nova run](../epics/hud/story-010-tela-de-fim-de-run.md) — pronta | ui-programmer | 1.0 (M) | hud-008, tela-de-bencao-e-carta-001, run-e-regioes (épico), vinculo-e-pactos (épico) | 4 | ACs da story + evidência do tipo UI |
| tela-de-bencao-e-carta-005 | [CartaView e VistaDaTela — Control, anatomia da carta, foco visível, gravura e acessibilidade](../epics/tela-de-bencao-e-carta/story-005-carta-view-e-vista-da-tela.md) — pronta | ui-programmer | 2.0 (L) | tela-de-bencao-e-carta-003, hud-007, experimentos-de-engine (épico), pipeline-visual (épico) | 4 | ACs da story + evidência do tipo UI |
| tela-de-bencao-e-carta-007 | [Modo arma — tela Escolha de arma com 3 cartas e aviso da Besta](../epics/tela-de-bencao-e-carta/story-007-modo-arma-escolha-de-arma.md) — pronta | ui-programmer | 1.0 (M) | tela-de-bencao-e-carta-005, armas-das-doutrinas (épico), run-e-regioes (épico) | 5 | ACs da story + evidência do tipo UI |
| tela-de-bencao-e-carta-009 | [Tela de consentimento do pacto (Oferecer / Deixar / Ela voltará; Pactuar / Exorcizar)](../epics/tela-de-bencao-e-carta/story-009-tela-de-consentimento-do-pacto.md) — pronta | ui-programmer | 1.0 (M) | tela-de-bencao-e-carta-005, hud-008, persistencia (épico), vinculo-e-pactos (épico) | 5 | ACs da story + evidência do tipo UI |
| tela-de-bencao-e-carta-008 | [Modo maldicao — Escolha do Pacto com duas escolhas em ordem](../epics/tela-de-bencao-e-carta/story-008-modo-maldicao-escolha-do-pacto.md) — pronta | ui-programmer | 1.0 (M) | tela-de-bencao-e-carta-007, assets-e-conteudo-007, vinculo-e-pactos (épico) | 6 | ACs da story + evidência do tipo UI |

### Should Have
| ID | Task (story) | Agent/Owner | Est. Days | Dependencies | Onda | Acceptance Criteria |
|----|------|-------------|-----------|-------------|------|-------------------|
| assets-e-conteudo-009 | [Áudio P0 — arquivos em assets/audio, SomDef e AudioTuning no catálogo](../epics/assets-e-conteudo/story-009-audio-p0-somdef-e-assets.md) — pronta | sound-designer | 1.0 (M) | assets-e-conteudo-001, conteudo (épico) | 1 | ACs da story + evidência do tipo Visual/Feel |

### Nice to Have
| ID | Task (story) | Agent/Owner | Est. Days | Dependencies | Onda | Acceptance Criteria |
|----|------|-------------|-----------|-------------|------|-------------------|
| — | Nenhuma: o backlog do MVP não tem stories opcionais | | | | | |

## Carryover from Previous Sprint
| Task | Reason | New Estimate |
|------|--------|-------------|
| — | Definido por `/sprint-plan update` ao fechar a Sprint 8 | — |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Não existe story de playtest do loop completo nem do smoke-check final | Certa | Alto | Prerrequisito ausente — ver Goal Prerequisites |
| Geração de arte do lote final atrasa e bloqueia HUD/tela | Média | Alto | Placeholders aprovados pelo art-director como fallback; corte documentado |
| Bugs S1/S2 do loop completo surgem só aqui | Alta | Alto | Buffer de 20% reservado para correção; playtest interno já na S6 |

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
