# Milestone: MVP — loop completo Limiar -> Soberano

## Overview
- **Target Date**: 2027-02-14
- **Type**: Alpha (MVP jogável)
- **Duration**: 13 semanas (2026-11-16 a 2027-02-14)
- **Number of Sprints**: 9 (sprint-001 … sprint-009)

## Milestone Goal
Uma run completa jogável do Limiar até o Soberano, com as 3 Doutrinas selecionáveis, construída sobre a arquitetura aceita (ADR-0001…0018) e não mais sobre a fatia de 2026-11-14. Ao fim, o MVP pode ser jogado de ponta a ponta, avaliado em playtest e medido por telemetria local.

## Success Criteria (critérios de saída)
- [ ] Loop completo jogável: escolha de arma -> Limiar (câmaras, ondas, portas, recompensas) -> regiões -> Soberano -> fim de run, iniciando em `res://scenes/main.tscn`
- [ ] As 3 Doutrinas jogáveis até o fim, incluindo a Doutrina de Pactos (Maldições, vínculo, chefe e save)
- [ ] As 265 stories dos 30 épicos em `production/epics/` com Status Complete (ou corte documentado e aprovado)
- [ ] Suíte GdUnit4 verde (`tests/unit/`, `tests/integration/`) no comando de CI de `coding-standards.md`
- [ ] `/smoke-check` com veredito PASS no build final
- [ ] Evidências retidas em `production/qa/evidence/` para toda story Visual/Feel e UI, com sign-off do lead
- [ ] Playtest do loop completo documentado (pelo menos uma run por Doutrina)
- [ ] Mesma seed reproduz a mesma run (contrato de reprodução do RNG)
- [ ] All S1 and S2 bugs resolved
- [ ] Performance dentro do orçamento de `project.yaml` no hardware-alvo
- [ ] Build estável por 3 dias consecutivos

## Feature List

### Must Ship (Milestone Fails Without These)
| Feature | Design Doc | Owner | Sprint Target | Status |
|---------|-----------|-------|--------------|--------|
| [cena-e-camera](../epics/cena-e-camera/EPIC.md) (8 stories) | ver `production/epics/index.md` | engine-programmer | S1–S2 | em andamento (6) |
| [conteudo](../epics/conteudo/EPIC.md) (10 stories) | ver `production/epics/index.md` | tools-programmer | S1–S2 | em andamento (4) |
| [experimentos-de-engine](../epics/experimentos-de-engine/EPIC.md) (9 stories) | ver `production/epics/index.md` | godot-specialist | S1 | em andamento (4) |
| [input](../epics/input/EPIC.md) (9 stories) | ver `production/epics/index.md` | engine-programmer | S1–S7 | em andamento (4) |
| [orquestrador-do-passo](../epics/orquestrador-do-passo/EPIC.md) (8 stories) | ver `production/epics/index.md` | engine-programmer | S1–S2 | em andamento (2) |
| [persistencia](../epics/persistencia/EPIC.md) (10 stories) | ver `production/epics/index.md` | godot-gdscript-specialist | S1–S7 | em andamento (5) |
| [rng](../epics/rng/EPIC.md) (7 stories) | ver `production/epics/index.md` | engine-programmer | S1–S7 | em andamento (5) |
| [assets-e-conteudo](../epics/assets-e-conteudo/EPIC.md) (9 stories) | ver `production/epics/index.md` | tools-programmer | S2–S9 | Ready |
| [combate-nucleo](../epics/combate-nucleo/EPIC.md) (10 stories) | ver `production/epics/index.md` | gameplay-programmer | S3–S7 | Ready |
| [modificadores](../epics/modificadores/EPIC.md) (8 stories) | ver `production/epics/index.md` | gameplay-programmer | S3–S5 | Ready |
| [movimento-e-esquiva](../epics/movimento-e-esquiva/EPIC.md) (10 stories) | ver `production/epics/index.md` | gameplay-programmer | S3–S7 | Ready |
| [armas-das-doutrinas](../epics/armas-das-doutrinas/EPIC.md) (8 stories) | ver `production/epics/index.md` | gameplay-programmer | S4–S8 | Ready |
| [bencaos-tradicoes](../epics/bencaos-tradicoes/EPIC.md) (10 stories) | ver `production/epics/index.md` | gameplay-programmer | S4–S5 | Ready |
| [economia-de-fragmentos](../epics/economia-de-fragmentos/EPIC.md) (7 stories) | ver `production/epics/index.md` | gameplay-programmer | S4–S7 | Ready |
| [selo-e-fluxo](../epics/selo-e-fluxo/EPIC.md) (5 stories) | ver `production/epics/index.md` | gameplay-programmer | S4–S5 | Ready |
| [telegrafos](../epics/telegrafos/EPIC.md) (10 stories) | ver `production/epics/index.md` | gameplay-programmer | S4–S8 | Ready |
| [camaras-e-ondas](../epics/camaras-e-ondas/EPIC.md) (10 stories) | ver `production/epics/index.md` | gameplay-programmer | S5–S7 | Ready |
| [efeitos-de-status](../epics/efeitos-de-status/EPIC.md) (7 stories) | ver `production/epics/index.md` | gameplay-programmer | S5 | Ready |
| [ia-de-inimigos-e-elites](../epics/ia-de-inimigos-e-elites/EPIC.md) (10 stories) | ver `production/epics/index.md` | ai-programmer | S5–S6 | Ready |
| [maldicoes](../epics/maldicoes/EPIC.md) (10 stories) | ver `production/epics/index.md` | gameplay-programmer | S5–S8 | Ready |
| [chefes](../epics/chefes/EPIC.md) (10 stories) | ver `production/epics/index.md` | ai-programmer | S6–S8 | Ready |
| [portas-e-recompensas](../epics/portas-e-recompensas/EPIC.md) (8 stories) | ver `production/epics/index.md` | gameplay-programmer | S6–S7 | Ready |
| [run-e-regioes](../epics/run-e-regioes/EPIC.md) (10 stories) | ver `production/epics/index.md` | gameplay-programmer | S6–S7 | Ready |
| [vinculo-e-pactos](../epics/vinculo-e-pactos/EPIC.md) (10 stories) | ver `production/epics/index.md` | gameplay-programmer | S6–S7 | Ready |
| [feedback-de-combate](../epics/feedback-de-combate/EPIC.md) (8 stories) | ver `production/epics/index.md` | technical-artist | S7–S8 | Ready |
| [hud](../epics/hud/EPIC.md) (10 stories) | ver `production/epics/index.md` | ui-programmer | S7–S9 | Ready |
| [pipeline-visual](../epics/pipeline-visual/EPIC.md) (10 stories) | ver `production/epics/index.md` | technical-artist | S7 | Ready |
| [tela-de-bencao-e-carta](../epics/tela-de-bencao-e-carta/EPIC.md) (9 stories) | ver `production/epics/index.md` | ui-programmer | S7–S9 | Ready |
| [audio](../epics/audio/EPIC.md) (5 stories) | ver `production/epics/index.md` | sound-designer | S8 | Ready |
| [telemetria-local](../epics/telemetria-local/EPIC.md) (10 stories) | ver `production/epics/index.md` | analytics-engineer | S8 | Ready |

### Should Ship (Planned but Cuttable)
| Feature | Design Doc | Owner | Sprint Target | Cut Impact | Status |
|---------|-----------|-------|--------------|-----------|--------|
| Telemetria local (painel/exportação além do registro de eventos) | design/gdd/telemetria-local.md | analytics-engineer | S8 | Perde medição do playtest; o loop continua jogável | Ready |

### Stretch Goals (Only if Ahead of Schedule)
| Feature | Design Doc | Owner | Value Add |
|---------|-----------|-------|----------|
| Co-op online | design/gdd/game-concept.md | — | Pós-MVP por decisão registrada; fora deste marco |

## Quality Gates
| Gate | Threshold | Measurement Method |
|------|-----------|-------------------|
| Testes automatizados | 100% verdes | GdUnit4 headless (CI) |
| Smoke check | PASS | `/smoke-check` |
| Critical bugs | 0 open S1 | Bug tracker |
| High-severity bugs | 0 open S2 | Bug tracker |
| Frame rate / memória | orçamento de `project.yaml` | Profiling no hardware-alvo |
| Determinismo | mesma seed = mesma run | Teste de reprodução do RNG |

## Risk Register
| Risk | Probability | Impact | Mitigation | Owner | Status |
|------|------------|--------|-----------|-------|--------|
| Caminho crítico serial (orquestrador -> … -> run) atrasa e empurra S7–S9 | Alta | Alto | Priorizar caminho crítico em toda onda; revisão de marco ao fim da S3 | producer | Aberto |
| Carga de S1 (60 agente-dia), S5–S7 (42–47) acima de 1 semana | Certa | Médio | Sprints de 2 semanas; carryover formal via `/sprint-plan update` | producer | Mitigado no plano |
| Sem story de playtest do loop completo | Certa | Alto | Criar via `/create-stories` antes da S9 | producer / qa-lead | Aberto |
| Experimentos de engine invalidam ADR | Média | Alto | Fechar EX-0001/0002/0011 na S1; escalar ao technical-director | technical-director | Aberto |
| Estimativas sem histórico de velocidade | Certa | Médio | Recalibrar após a S1 com `/sprint-plan update` | producer | Aberto |

## Dependencies

### Internal Dependencies
| Feature | Depends On | Owner of Dependency | Status |
|---------|-----------|-------------------|--------|
| Core (S3) | Foundation (S1–S2) | engine-programmer | Em andamento |
| Feature (S4–S6) | Core (S3) | gameplay-programmer | Ready |
| Presentation (S7–S8) | Telégrafos (S4) + EX-0011 E1–E3 (S1) | gameplay-programmer / godot-specialist | Ready |

### External Dependencies
| Dependency | Provider | Status | Risk if Delayed |
|-----------|---------|--------|----------------|
| Godot 4.7.2 + GdUnit4 | Godot / GdUnit4 | Instalado | Suíte não roda |

## Totais
- 265 stories, 295.5 agente-dia estimados (S=0,5 / M=1 / L=2), sem calibração por velocidade.
