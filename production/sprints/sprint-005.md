# Sprint 5 — 2026-12-21 to 2027-01-03

> Gerado por `/sprint-plan new` (orquestrado, 2026-11-16). Plano do marco MVP em 9 sprints — uma por onda de dependência.

## Sprint Goal
IA de inimigos e elites, efeitos de status, câmaras e ondas e Maldições (Doutrina de Pactos) — combate do Limiar com inimigos reais.

## Goal Prerequisites
| Needed to show the goal | Status |
|-------------------------|--------|
| Cena principal (`run/main_scene` = `res://scenes/main.tscn`) | exists |

## Milestone Context
- Current Milestone: MVP ([production/milestones/mvp.md](../milestones/mvp.md))
- Milestone Deadline: 2027-02-14
- Sprints Remaining: 5 (incluindo esta)

## Capacity
- Equipe: 7 agentes de IA em paralelo (6–8), 2 semana(s) úteis
- Total days: 70 agente-dia
- Buffer (20%): 14 agente-dia
- Available: 56 agente-dia
- Carga planejada: 45.5 agente-dia (41 stories; S=0,5 / M=1 / L=2)
- Estimativa não calibrada: não há histórico de velocidade (primeira sprint do plano).

## Ordem e paralelismo
Stories numa mesma onda não dependem entre si e podem correr ao mesmo tempo (até 7 agentes, um por pasta de sistema). Uma onda começa quando as dependências dela, na onda anterior, fecham — não a onda inteira.

- **Onda 1** (2): **camaras-e-ondas-001**, maldicoes-001
- **Onda 2** (4): **camaras-e-ondas-002**, **combate-nucleo-007**, **modificadores-008**, selo-e-fluxo-002
- **Onda 3** (3): **ia-de-inimigos-e-elites-001**, efeitos-de-status-001, selo-e-fluxo-003
- **Onda 4** (5): **camaras-e-ondas-004**, **ia-de-inimigos-e-elites-002**, **modificadores-007**, efeitos-de-status-002, selo-e-fluxo-005
- **Onda 5** (9): **ia-de-inimigos-e-elites-003**, **ia-de-inimigos-e-elites-005**, **movimento-e-esquiva-004**, bencaos-tradicoes-009, efeitos-de-status-003, efeitos-de-status-004, efeitos-de-status-006, maldicoes-002, selo-e-fluxo-004
- **Onda 6** (8): **camaras-e-ondas-003**, **combate-nucleo-008**, **ia-de-inimigos-e-elites-004**, **ia-de-inimigos-e-elites-006**, armas-das-doutrinas-002, efeitos-de-status-005, efeitos-de-status-007, maldicoes-003
- **Onda 7** (4): **camaras-e-ondas-005**, **combate-nucleo-009**, **ia-de-inimigos-e-elites-007**, maldicoes-004
- **Onda 8** (2): armas-das-doutrinas-006, maldicoes-005
- **Onda 9** (1): maldicoes-006
- **Onda 10** (1): maldicoes-007
- **Onda 11** (1): maldicoes-008
- **Onda 12** (1): maldicoes-009

Em negrito: caminho crítico (EX-0001/0002 -> orquestrador -> modificadores -> movimento -> combate -> IA -> câmaras -> portas -> run).

## Tasks

### Must Have (Critical Path)
| ID | Task (story) | Agent/Owner | Est. Days | Dependencies | Onda | Acceptance Criteria |
|----|------|-------------|-----------|-------------|------|-------------------|
| camaras-e-ondas-001 | [WaveRules, RoomTuning e RegionDef no catálogo (WV1–WV11)](../epics/camaras-e-ondas/story-001-tuning-e-validacao-wv.md) — pronta | gameplay-programmer | 1.0 (M) | conteudo (épico) | 1 | ACs da story + evidência do tipo Logic |
| maldicoes-001 | [Catálogo CurseDef/TecnicaDef/MaldicoesTuning e validação ML1–ML8](../epics/maldicoes/story-001-catalogo-e-validacao-ml.md) — pronta | gameplay-programmer | 1.0 (M) | armas-das-doutrinas (épico), conteudo (épico) | 1 | ACs da story + evidência do tipo Logic |
| camaras-e-ondas-002 | [Profundidade p, p_max e chave do RNG pelo índice](../epics/camaras-e-ondas/story-002-profundidade-e-sequencia.md) — pronta | gameplay-programmer | 0.5 (S) | camaras-e-ondas-001, rng (épico) | 2 | ACs da story + evidência do tipo Logic |
| combate-nucleo-007 | [ferir_jogador e varredura de mortes](../epics/combate-nucleo/story-007-dano-no-jogador-e-varredura.md) — pronta | gameplay-programmer | 1.0 (M) | combate-nucleo-006, camaras-e-ondas (épico) | 2 | ACs da story + evidência do tipo Logic |
| modificadores-008 | [Portador da Maldição: origens vinculo/especie/espelho e propagação](../epics/modificadores/story-008-portador-da-maldicao-e-espelho.md) — pronta | gameplay-programmer | 2.0 (L) | maldicoes (épico) | 2 | ACs da story + evidência do tipo Logic |
| selo-e-fluxo-002 | [Fluxo — regeneração, acerto de arma e congelamento](../epics/selo-e-fluxo/story-002-fluxo.md) — pronta | gameplay-programmer | 1.0 (M) | selo-e-fluxo-001, combate-nucleo-002, combate-nucleo-008 | 2 | ACs da story + evidência do tipo Logic |
| ia-de-inimigos-e-elites-001 | [ModuloDeIA — lista estável, ciclo do item 7 e consultas de alvos](../epics/ia-de-inimigos-e-elites/story-001-lista-estavel-e-consultas.md) — pronta | ai-programmer | 1.0 (M) | combate-nucleo (épico), orquestrador-do-passo (épico) | 3 | ACs da story + evidência do tipo Logic |
| efeitos-de-status-001 | [Modelo de status e aplicar_status](../epics/efeitos-de-status/story-001-modelo-e-aplicar.md) — pronta | gameplay-programmer | 1.0 (M) | combate-nucleo (épico), conteudo (épico) | 3 | ACs da story + evidência do tipo Logic |
| selo-e-fluxo-003 | [Plantar o Selo — custo, recarga, buffer e centro preso](../epics/selo-e-fluxo/story-003-plantar-o-selo.md) — pronta | gameplay-programmer | 1.0 (M) | selo-e-fluxo-002, combate-nucleo-005, input (épico) | 3 | ACs da story + evidência do tipo Logic |
| camaras-e-ondas-004 | [Composição das ondas — orçamento, tamanho e elite](../epics/camaras-e-ondas/story-004-composicao-das-ondas.md) — pronta | gameplay-programmer | 1.0 (M) | camaras-e-ondas-001, ia-de-inimigos-e-elites (épico) | 4 | ACs da story + evidência do tipo Logic |
| ia-de-inimigos-e-elites-002 | [Máquina de fases, surgimento e comportamento melee](../epics/ia-de-inimigos-e-elites/story-002-fases-surgimento-e-melee.md) — pronta | ai-programmer | 1.0 (M) | ia-de-inimigos-e-elites-001, telegrafos-001, telegrafos-004, rng (épico) | 4 | ACs da story + evidência do tipo Logic |
| modificadores-007 | [Atributo × recurso, cargas, escudo de sala, elite/profundidade e nova run](../epics/modificadores/story-007-atributo-x-recurso-cargas-elite-run.md) — pronta | gameplay-programmer | 1.0 (M) | ia-de-inimigos-e-elites (épico) | 4 | ACs da story + evidência do tipo Integration |
| efeitos-de-status-002 | [Tick no item 7 e dano silencioso](../epics/efeitos-de-status/story-002-tick-e-dano-silencioso.md) — pronta | gameplay-programmer | 1.0 (M) | efeitos-de-status-001, combate-nucleo (épico), orquestrador-do-passo (épico) | 4 | ACs da story + evidência do tipo Logic |
| selo-e-fluxo-005 | [Lentidão, consulta no_selo e Selos apagados na câmara nova](../epics/selo-e-fluxo/story-005-lentidao-no-selo-e-camara-nova.md) — pronta | gameplay-programmer | 0.5 (S) | selo-e-fluxo-003, combate-nucleo-002 | 4 | ACs da story + evidência do tipo Logic |
| ia-de-inimigos-e-elites-003 | [Ranged e charger, e o retângulo visível](../epics/ia-de-inimigos-e-elites/story-003-ranged-charger-e-vista.md) — pronta | ai-programmer | 1.0 (M) | ia-de-inimigos-e-elites-002, telegrafos-003, cena-e-camera (épico) | 5 | ACs da story + evidência do tipo Logic |
| ia-de-inimigos-e-elites-005 | [Elites (sorteio e números), armadura e quebra dos comuns](../epics/ia-de-inimigos-e-elites/story-005-elites-armadura-e-quebra.md) — pronta | ai-programmer | 1.0 (M) | ia-de-inimigos-e-elites-002, telegrafos-006, modificadores (épico), rng (épico) | 5 | ACs da story + evidência do tipo Logic |
| movimento-e-esquiva-004 | [Cargas de esquiva, recarga e sincronia com o atributo](../epics/movimento-e-esquiva/story-004-cargas-e-recarga.md) — pronta | gameplay-programmer | 1.0 (M) | modificadores-007 | 5 | ACs da story + evidência do tipo Logic |
| bencaos-tradicoes-009 | [Cinco bênçãos por run e bênçãos com a Besta do Vínculo](../epics/bencaos-tradicoes/story-009-cinco-bencaos-e-besta.md) — pronta | gameplay-programmer | 1.0 (M) | bencaos-tradicoes-006, maldicoes (épico), modificadores (épico) | 5 | ACs da story + evidência do tipo Integration |
| efeitos-de-status-003 | [Morte por status, congelamento e troca de câmara](../epics/efeitos-de-status/story-003-morte-congelamento-e-limpeza.md) — pronta | gameplay-programmer | 1.0 (M) | efeitos-de-status-002, combate-nucleo (épico), orquestrador-do-passo (épico) | 5 | ACs da story + evidência do tipo Integration |
| efeitos-de-status-004 | [Abalo com relógio único e fonte no portador](../epics/efeitos-de-status/story-004-abalo.md) — pronta | gameplay-programmer | 1.0 (M) | efeitos-de-status-001, modificadores (épico) | 5 | ACs da story + evidência do tipo Logic |
| efeitos-de-status-006 | [Número agregado e consulta estado(inimigo)](../epics/efeitos-de-status/story-006-numero-e-consulta.md) — pronta | gameplay-programmer | 1.0 (M) | efeitos-de-status-002, orquestrador-do-passo (épico) | 5 | ACs da story + evidência do tipo Logic |
| maldicoes-002 | [ModuloDeMaldicoes, MaldicaoRef e a dupla da expedição (facção ALIADO)](../epics/maldicoes/story-002-modulo-dupla-e-faccao.md) — pronta | gameplay-programmer | 1.0 (M) | maldicoes-001, combate-nucleo (épico), modificadores (épico), orquestrador-do-passo (épico) | 5 | ACs da story + evidência do tipo Logic |
| selo-e-fluxo-004 | [Dano do Selo, abates e imunidade da Maldição](../epics/selo-e-fluxo/story-004-dano-do-selo.md) — pronta | gameplay-programmer | 1.0 (M) | selo-e-fluxo-003, combate-nucleo-006, efeitos-de-status (épico), modificadores (épico) | 5 | ACs da story + evidência do tipo Logic |
| camaras-e-ondas-003 | [Layout de pedras, retângulo jogável e obstáculos](../epics/camaras-e-ondas/story-003-layout-de-pedras.md) — pronta | gameplay-programmer | 1.0 (M) | camaras-e-ondas-001, movimento-e-esquiva (épico), rng (épico) | 6 | ACs da story + evidência do tipo Logic |
| combate-nucleo-008 | [Eventos tipados e contratos com IA, Telégrafos, Câmaras, Selo e Status](../epics/combate-nucleo/story-008-eventos-e-contratos.md) — pronta | gameplay-programmer | 2.0 (L) | combate-nucleo-007, selo-e-fluxo-004, camaras-e-ondas (épico), efeitos-de-status (épico), ia-de-inimigos-e-elites (épico), telegrafos (épico) | 6 | ACs da story + evidência do tipo Integration |
| ia-de-inimigos-e-elites-004 | [Andar com Selo e cambaleio, conter e separação par a par](../epics/ia-de-inimigos-e-elites/story-004-andar-conter-e-separacao.md) — pronta | ai-programmer | 0.5 (S) | ia-de-inimigos-e-elites-002, movimento-e-esquiva (épico) | 6 | ACs da story + evidência do tipo Logic |
| ia-de-inimigos-e-elites-006 | [Alvo efetivo, atração sem renovação e respiro](../epics/ia-de-inimigos-e-elites/story-006-alvo-e-atracao.md) — pronta | ai-programmer | 1.0 (M) | ia-de-inimigos-e-elites-003, telegrafos-005 | 6 | ACs da story + evidência do tipo Logic |
| armas-das-doutrinas-002 | [Validação das armas (AV1–AV9, V2, nomes canônicos)](../epics/armas-das-doutrinas/story-002-validacao-das-armas.md) — pronta | gameplay-programmer | 2.0 (L) | armas-das-doutrinas-001, armas-das-doutrinas-003, maldicoes (épico) | 6 | ACs da story + evidência do tipo Logic |
| efeitos-de-status-005 | [Fontes de status (golpes, Corte, Selo) e Maldições](../epics/efeitos-de-status/story-005-fontes-e-maldicoes.md) — pronta | gameplay-programmer | 1.0 (M) | efeitos-de-status-004, combate-nucleo (épico), maldicoes (épico), selo-e-fluxo (épico) | 6 | ACs da story + evidência do tipo Integration |
| efeitos-de-status-007 | [StatusTuning no catálogo e validação ST1–ST11](../epics/efeitos-de-status/story-007-status-tuning-e-validacao.md) — pronta | gameplay-programmer | 1.0 (M) | conteudo (épico), movimento-e-esquiva (épico) | 6 | ACs da story + evidência do tipo Integration |
| maldicoes-003 | [IA de aliado — fio de vínculo, alvo por prioridade e passivas condicionais](../epics/maldicoes/story-003-ia-de-aliado-fio-e-alvo.md) — pronta | gameplay-programmer | 1.0 (M) | maldicoes-002, movimento-e-esquiva (épico) | 6 | ACs da story + evidência do tipo Logic |
| camaras-e-ondas-005 | [Spawn — 14 candidatos, filtros, ordem e distância da acuada](../epics/camaras-e-ondas/story-005-spawn-e-candidatos.md) — pronta | gameplay-programmer | 1.0 (M) | camaras-e-ondas-003, camaras-e-ondas-004 | 7 | ACs da story + evidência do tipo Logic |
| combate-nucleo-009 | [Pactos — Maldição aliada, acuada e chefe Subjugado](../epics/combate-nucleo/story-009-pactos-maldicao-acuada-e-chefe.md) — pronta | gameplay-programmer | 2.0 (L) | combate-nucleo-007, combate-nucleo-008, ia-de-inimigos-e-elites (épico), maldicoes (épico) | 7 | ACs da story + evidência do tipo Logic |
| ia-de-inimigos-e-elites-007 | [Imobilizar, puxar (Convergência) e Maldição fora da separação](../epics/ia-de-inimigos-e-elites/story-007-imobilizar-puxar-e-conter.md) — pronta | ai-programmer | 1.0 (M) | ia-de-inimigos-e-elites-004, ia-de-inimigos-e-elites-006 | 7 | ACs da story + evidência do tipo Logic |
| maldicoes-004 | [Ataque básico da Maldição pelo impacto do Combate (R20) e habilidade Primordial](../epics/maldicoes/story-004-ataque-basico-pela-r20.md) — pronta | gameplay-programmer | 1.0 (M) | maldicoes-003, combate-nucleo (épico), ia-de-inimigos-e-elites (épico) | 7 | ACs da story + evidência do tipo Integration |
| armas-das-doutrinas-006 | [Besta do Vínculo — Virote e Chamado](../epics/armas-das-doutrinas/story-006-besta-virote-e-chamado.md) — pronta | gameplay-programmer | 1.0 (M) | armas-das-doutrinas-001, combate-nucleo-009, maldicoes (épico) | 8 | ACs da story + evidência do tipo Integration |
| maldicoes-005 | [Dano recebido, alvo travado, Exaustão síncrona e saída de campo](../epics/maldicoes/story-005-dano-exaustao-e-saida-de-campo.md) — pronta | gameplay-programmer | 2.0 (L) | maldicoes-004, combate-nucleo (épico), ia-de-inimigos-e-elites (épico), telegrafos (épico) | 8 | ACs da story + evidência do tipo Integration |
| maldicoes-006 | [Contadores por passo vivo, regeneração, espelho das bênçãos e a dupla que cresce](../epics/maldicoes/story-006-contadores-regeneracao-e-dupla-que-cresce.md) — pronta | gameplay-programmer | 1.0 (M) | maldicoes-005, modificadores (épico) | 9 | ACs da story + evidência do tipo Logic |
| maldicoes-007 | [Ação Troca e Técnica Combinada por dados](../epics/maldicoes/story-007-troca-e-tecnica-combinada.md) — pronta | gameplay-programmer | 1.0 (M) | maldicoes-006, efeitos-de-status (épico), input (épico) | 10 | ACs da story + evidência do tipo Logic |
| maldicoes-008 | [Chamado do Pacto e atração limitada (sem renovação, com respiro)](../epics/maldicoes/story-008-chamado-do-pacto-e-atracao.md) — pronta | gameplay-programmer | 2.0 (L) | maldicoes-007, armas-das-doutrinas (épico), combate-nucleo (épico), ia-de-inimigos-e-elites (épico) | 11 | ACs da story + evidência do tipo Integration |
| maldicoes-009 | [Troca de câmara, leitura `estado_pacto`, eventos da R20 e orçamento do item 6.1](../epics/maldicoes/story-009-camara-leitura-eventos-e-orcamento.md) — pronta | gameplay-programmer | 1.0 (M) | maldicoes-008, camaras-e-ondas (épico), orquestrador-do-passo (épico) | 12 | ACs da story + evidência do tipo Integration |

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
| — | Definido por `/sprint-plan update` ao fechar a Sprint 4 | — |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Cadeia de dependência longa (9 ondas) dentro da sprint | Alta | Alto | Sprint de 2 semanas; IA e câmaras priorizadas (caminho crítico) |
| Interação Maldições x efeitos de status x modificadores gera bugs de ordem no passo | Média | Alto | Testes de integração no orquestrador por fase do passo |

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
