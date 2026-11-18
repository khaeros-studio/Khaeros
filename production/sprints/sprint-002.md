# Sprint 2 — 2026-11-30 to 2026-12-06

> Gerado por `/sprint-plan new` (orquestrado, 2026-11-16). Plano do marco MVP em 9 sprints — uma por onda de dependência.

## Sprint Goal
Compor e integrar a Foundation por trás do `Main` (troca do RNG/input/cena da fatia, catálogo `.tres` migrado do JSON) sem perder a fatia jogável de 2026-11-14.

## Goal Prerequisites
| Needed to show the goal | Status |
|-------------------------|--------|
| Cena principal (`run/main_scene` = `res://scenes/main.tscn`) | exists |

## Milestone Context
- Current Milestone: MVP ([production/milestones/mvp.md](../milestones/mvp.md))
- Milestone Deadline: 2027-02-14
- Sprints Remaining: 8 (incluindo esta)

## Capacity
- Equipe: 7 agentes de IA em paralelo (6–8), 1 semana(s) úteis
- Total days: 35 agente-dia
- Buffer (20%): 7 agente-dia
- Available: 28 agente-dia
- Carga planejada: 17.5 agente-dia (14 stories; S=0,5 / M=1 / L=2)
- Estimativa não calibrada: não há histórico de velocidade (primeira sprint do plano).

## Ordem e paralelismo
Stories numa mesma onda não dependem entre si e podem correr ao mesmo tempo (até 7 agentes, um por pasta de sistema). Uma onda começa quando as dependências dela, na onda anterior, fecham — não a onda inteira.

- **Onda 1** (7): **orquestrador-do-passo-006**, **orquestrador-do-passo-007**, cena-e-camera-008, conteudo-009, conteudo-010, persistencia-009, rng-006
- **Onda 2** (3): assets-e-conteudo-001, input-005, input-008
- **Onda 3** (1): assets-e-conteudo-002
- **Onda 4** (1): assets-e-conteudo-003
- **Onda 5** (1): assets-e-conteudo-004
- **Onda 6** (1): assets-e-conteudo-005

Em negrito: caminho crítico (EX-0001/0002 -> orquestrador -> modificadores -> movimento -> combate -> IA -> câmaras -> portas -> run).

## Tasks

### Must Have (Critical Path)
| ID | Task (story) | Agent/Owner | Est. Days | Dependencies | Onda | Acceptance Criteria |
|----|------|-------------|-----------|-------------|------|-------------------|
| orquestrador-do-passo-006 | [Main como composição fina, project.godot e foco da janela](../epics/orquestrador-do-passo/story-006-main-composicao.md) — pronta | engine-programmer | 1.0 (M) | experimentos-de-engine-001, experimentos-de-engine-003 | 1 | ACs da story + evidência do tipo Integration |
| orquestrador-do-passo-007 | [Migrar a fatia jogável para o orquestrador e para eventos tipados](../epics/orquestrador-do-passo/story-007-migracao-da-fatia.md) — pronta | engine-programmer | 2.0 (L) | — | 1 | ACs da story + evidência do tipo Integration |
| cena-e-camera-008 | [Onze camadas e `CompositorDeCena` (verificação visual)](../epics/cena-e-camera/story-008-camadas-e-compositor-de-cena.md) — pronta | engine-programmer | 2.0 (L) | cena-e-camera-001, cena-e-camera-007 | 1 | ACs da story + evidência do tipo Visual/Feel |
| conteudo-009 | [Recarga de debug, revogação de ajustes e tela de erros](../epics/conteudo/story-009-recarga-e-tela-de-erros.md) — pronta | ui-programmer | 1.0 (M) | experimentos-de-engine-002, experimentos-de-engine-008 | 1 | ACs da story + evidência do tipo UI |
| conteudo-010 | [Cânone, script de importação, paridade e validadores de CI (V5, V9, órfãos)](../epics/conteudo/story-010-canone-importador-paridade.md) — pronta | tools-programmer | 2.0 (L) | experimentos-de-engine-002 | 1 | ACs da story + evidência do tipo Integration |
| persistencia-009 | [exportar_texto/importar_texto e fluxo real em raiz temporária](../epics/persistencia/story-009-exportar-importar-e-fluxo-real.md) — pronta | godot-gdscript-specialist | 0.5 (S) | — | 1 | ACs da story + evidência do tipo Integration |
| rng-006 | [Lint de CI contra RNG proibido e troca do RNG da fatia](../epics/rng/story-006-lint-de-ci-e-troca-do-rng-da-fatia.md) — pronta | engine-programmer | 1.0 (M) | rng-003, rng-004 | 1 | ACs da story + evidência do tipo Integration |
| assets-e-conteudo-001 | [Manifesto do catálogo e `*Tuning` migrados do gameplay.json](../epics/assets-e-conteudo/story-001-manifesto-e-tunings-da-fatia.md) — pronta | tools-programmer | 1.0 (M) | conteudo (épico) | 2 | ACs da story + evidência do tipo Config/Data |
| input-005 | [Contextos, barreira de troca, perda de foco e desconexão](../epics/input/story-005-contextos-barreira-foco-e-desconexao.md) — pronta | engine-programmer | 2.0 (L) | input-002, input-004, orquestrador-do-passo (épico) | 2 | ACs da story + evidência do tipo Integration |
| input-008 | [Arquivo de binds, `.bak` e migração de ação nova](../epics/input/story-008-persistencia-de-binds-e-migracao.md) — pronta | engine-programmer | 1.0 (M) | input-007, persistencia (épico) | 2 | ACs da story + evidência do tipo Integration |
| assets-e-conteudo-002 | [Definições de armas (WeaponDef/AttackDef) e inimigos (EnemyDef)](../epics/assets-e-conteudo/story-002-armas-ataques-e-inimigos.md) — pronta | tools-programmer | 1.0 (M) | assets-e-conteudo-001 | 3 | ACs da story + evidência do tipo Config/Data |
| assets-e-conteudo-003 | [Definições de bênçãos (BoonDef), regiões e câmaras/ondas](../epics/assets-e-conteudo/story-003-bencaos-regioes-e-camaras.md) — pronta | tools-programmer | 1.0 (M) | assets-e-conteudo-002 | 4 | ACs da story + evidência do tipo Config/Data |
| assets-e-conteudo-004 | [Dados da Doutrina de Pactos — CurseDef, chefe (BossPatternDef) e tunings de Pactos](../epics/assets-e-conteudo/story-004-pactos-maldicoes-e-chefe.md) — pronta | tools-programmer | 1.0 (M) | assets-e-conteudo-003, conteudo (épico) | 5 | ACs da story + evidência do tipo Config/Data |

### Should Have
| ID | Task (story) | Agent/Owner | Est. Days | Dependencies | Onda | Acceptance Criteria |
|----|------|-------------|-----------|-------------|------|-------------------|
| assets-e-conteudo-005 | [CSV canônico, paridade de importação e aposentar o gameplay.json](../epics/assets-e-conteudo/story-005-canon-csv-paridade-e-aposentar-json.md) — pronta | tools-programmer | 1.0 (M) | assets-e-conteudo-004, conteudo (épico) | 6 | ACs da story + evidência do tipo Integration |

### Nice to Have
| ID | Task (story) | Agent/Owner | Est. Days | Dependencies | Onda | Acceptance Criteria |
|----|------|-------------|-----------|-------------|------|-------------------|
| — | Nenhuma: o backlog do MVP não tem stories opcionais | | | | | |

## Carryover from Previous Sprint
| Task | Reason | New Estimate |
|------|--------|-------------|
| — | Definido por `/sprint-plan update` ao fechar a Sprint 1 | — |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Troca do RNG/input/cena da fatia quebra a fatia jogável | Média | Alto | Cada troca é uma story isolada, com run-and-observe e screenshot antes de fechar |
| Paridade CSV <-> `.tres` falha na migração do catálogo | Média | Médio | assets-e-conteudo 005 é bloqueante; JSON só aposentado com paridade verde |

## Dependencies on External Factors
- Godot 4.7.2 instalado (`docs/engine-reference/godot/VERSION.md`); GdUnit4 para a suíte.
- Aprovação humana de evidências visuais (lead sign-off) para stories Visual/Feel e UI.
- Sem registro de riscos em `production/risk-register/`: riscos avaliados só pelo conteúdo da sprint.

## Definition of Done for this Sprint
- [x] All Must Have tasks completed (14/14 done)
- [x] All tasks pass acceptance criteria
- [x] All Logic/Integration stories have passing unit/integration tests
- [x] Toda story que muda algo observável pelo jogador foi rodada e tem screenshot retido em `production/qa/evidence/`
- [x] QA sign-off report: APPROVED (`production/qa/evidence/assets-e-conteudo-evidence.md`)
- [x] No S1 or S2 bugs in delivered features
- [x] A fatia jogável continua abrindo por `res://scenes/main.tscn`
- [x] Design documents updated for any deviations
- [x] Code reviewed and merged
