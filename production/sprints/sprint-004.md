# Sprint 4 — 2026-12-14 to 2026-12-20

> Gerado por `/sprint-plan new` (orquestrado, 2026-11-16). Plano do marco MVP em 9 sprints — uma por onda de dependência.

## Sprint Goal
Abrir a camada Feature: armas das 3 Doutrinas (fundação), Selo e Fluxo, Telégrafos, Economia de Fragmentos e Bênçãos/Tradições.

## Goal Prerequisites
| Needed to show the goal | Status |
|-------------------------|--------|
| Cena principal (`run/main_scene` = `res://scenes/main.tscn`) | exists |

## Milestone Context
- Current Milestone: MVP ([production/milestones/mvp.md](../milestones/mvp.md))
- Milestone Deadline: 2027-02-14
- Sprints Remaining: 6 (incluindo esta)

## Capacity
- Equipe: 7 agentes de IA em paralelo (6–8), 1 semana(s) úteis
- Total days: 35 agente-dia
- Buffer (20%): 7 agente-dia
- Available: 28 agente-dia
- Carga planejada: 18.0 agente-dia (22 stories; S=0,5 / M=1 / L=2)
- Estimativa não calibrada: não há histórico de velocidade (primeira sprint do plano).

## Ordem e paralelismo
Stories numa mesma onda não dependem entre si e podem correr ao mesmo tempo (até 7 agentes, um por pasta de sistema). Uma onda começa quando as dependências dela, na onda anterior, fecham — não a onda inteira.

- **Onda 1** (4): armas-das-doutrinas-001, bencaos-tradicoes-001, economia-de-fragmentos-001, telegrafos-001
- **Onda 2** (7): armas-das-doutrinas-003, bencaos-tradicoes-002, economia-de-fragmentos-002, economia-de-fragmentos-003, selo-e-fluxo-001, telegrafos-002, telegrafos-006
- **Onda 3** (2): bencaos-tradicoes-003, telegrafos-003
- **Onda 4** (5): bencaos-tradicoes-004, bencaos-tradicoes-005, bencaos-tradicoes-010, telegrafos-004, telegrafos-008
- **Onda 5** (3): bencaos-tradicoes-006, bencaos-tradicoes-007, telegrafos-005
- **Onda 6** (1): bencaos-tradicoes-008

Em negrito: caminho crítico (EX-0001/0002 -> orquestrador -> modificadores -> movimento -> combate -> IA -> câmaras -> portas -> run).

## Tasks

### Must Have (Critical Path)
| ID | Task (story) | Agent/Owner | Est. Days | Dependencies | Onda | Acceptance Criteria |
|----|------|-------------|-----------|-------------|------|-------------------|
| armas-das-doutrinas-001 | [WeaponDef, AttackDef e as três armas de fábrica](../epics/armas-das-doutrinas/story-001-weapondef-e-armas-de-fabrica.md) — pronta | gameplay-programmer | 1.0 (M) | combate-nucleo-001, conteudo (épico) | 1 | ACs da story + evidência do tipo Logic |
| bencaos-tradicoes-001 | [Pool de 18 BoonDef, RarityTable e BencaosTuning no catálogo (BN1, BN2)](../epics/bencaos-tradicoes/story-001-pool-e-tuning-no-catalogo.md) — pronta | gameplay-programmer | 1.0 (M) | conteudo (épico) | 1 | ACs da story + evidência do tipo Logic |
| economia-de-fragmentos-001 | [ContaFragmentos — saldo, creditar e eventos](../epics/economia-de-fragmentos/story-001-conta-creditar-e-eventos.md) — pronta | gameplay-programmer | 1.0 (M) | orquestrador-do-passo (épico) | 1 | ACs da story + evidência do tipo Logic |
| telegrafos-001 | [Pool fixo, teto de 24 e ciclo de vida em passos vivos](../epics/telegrafos/story-001-pool-teto-e-ciclo.md) — pronta | gameplay-programmer | 1.0 (M) | conteudo (épico), orquestrador-do-passo (épico) | 1 | ACs da story + evidência do tipo Logic |
| armas-das-doutrinas-003 | [Fórmulas de referência das armas (F1–F7)](../epics/armas-das-doutrinas/story-003-formulas-de-referencia.md) — pronta | gameplay-programmer | 1.0 (M) | armas-das-doutrinas-001, combate-nucleo-006 | 2 | ACs da story + evidência do tipo Logic |
| bencaos-tradicoes-002 | [RegistroDeBencaos — pool, tomadas e restantes](../epics/bencaos-tradicoes/story-002-registro-de-tomadas.md) — pronta | gameplay-programmer | 0.5 (S) | bencaos-tradicoes-001 | 2 | ACs da story + evidência do tipo Logic |
| economia-de-fragmentos-002 | [Teto do saldo e EconomyRates no catálogo](../epics/economia-de-fragmentos/story-002-teto-e-economy-rates.md) — pronta | gameplay-programmer | 0.5 (S) | economia-de-fragmentos-001, conteudo (épico) | 2 | ACs da story + evidência do tipo Logic |
| economia-de-fragmentos-003 | [Gastar, Nova run e exportar/importar sem arquivo](../epics/economia-de-fragmentos/story-003-gastar-nova-run-exportar.md) — pronta | gameplay-programmer | 1.0 (M) | economia-de-fragmentos-001 | 2 | ACs da story + evidência do tipo Logic |
| selo-e-fluxo-001 | [SealTuning e validação SV1–SV12](../epics/selo-e-fluxo/story-001-seal-tuning-e-validacao.md) — pronta | gameplay-programmer | 0.5 (S) | armas-das-doutrinas-001, conteudo (épico) | 2 | ACs da story + evidência do tipo Integration |
| telegrafos-002 | [FormasDeTelegrafo.derivar() dos EnemyDef e raio do alvo](../epics/telegrafos/story-002-derivar-formas.md) — pronta | gameplay-programmer | 1.0 (M) | telegrafos-001, conteudo (épico) | 2 | ACs da story + evidência do tipo Logic |
| telegrafos-006 | [Quebrar, cancelar, troca de câmara e TransicaoFase](../epics/telegrafos/story-006-quebrar-e-cancelar.md) — pronta | gameplay-programmer | 1.0 (M) | telegrafos-001, orquestrador-do-passo (épico) | 2 | ACs da story + evidência do tipo Logic |
| bencaos-tradicoes-003 | [Sorteio da oferta — F7, raridade e consumo fixo de 6 reais](../epics/bencaos-tradicoes/story-003-sorteio-da-oferta.md) — pronta | gameplay-programmer | 1.0 (M) | bencaos-tradicoes-002, rng (épico) | 3 | ACs da story + evidência do tipo Logic |
| telegrafos-003 | [Adaptador FormaDeTelegrafo e testes de acerto](../epics/telegrafos/story-003-forma-e-testes-de-acerto.md) — pronta | gameplay-programmer | 1.0 (M) | telegrafos-002, combate-nucleo (épico) | 3 | ACs da story + evidência do tipo Logic |
| bencaos-tradicoes-004 | [Troca da oferta e raridade_bonus](../epics/bencaos-tradicoes/story-004-troca-e-raridade-bonus.md) — pronta | gameplay-programmer | 1.0 (M) | bencaos-tradicoes-003 | 4 | ACs da story + evidência do tipo Logic |
| bencaos-tradicoes-005 | [Contrato pedir_oferta, estados e BencaosNula](../epics/bencaos-tradicoes/story-005-contrato-pedir-oferta.md) — pronta | gameplay-programmer | 1.0 (M) | bencaos-tradicoes-003, orquestrador-do-passo (épico) | 4 | ACs da story + evidência do tipo Integration |
| bencaos-tradicoes-010 | [Estatística da oferta — presença e raridade (F1, F3, F4-P)](../epics/bencaos-tradicoes/story-010-estatistica-da-oferta.md) — pronta | gameplay-programmer | 0.5 (S) | bencaos-tradicoes-003 | 4 | ACs da story + evidência do tipo Logic |
| telegrafos-004 | [Disparo resolvido no mesmo passo](../epics/telegrafos/story-004-disparo.md) — pronta | gameplay-programmer | 0.5 (S) | telegrafos-003, combate-nucleo (épico) | 4 | ACs da story + evidência do tipo Logic |
| telegrafos-008 | [publicar() — entrega por quadro ao Pipeline](../epics/telegrafos/story-008-publicar-vistas.md) — pronta | gameplay-programmer | 0.5 (S) | telegrafos-003 | 4 | ACs da story + evidência do tipo Logic |
| bencaos-tradicoes-006 | [Escolha — aplicar no Modificadores, registrar e emitir](../epics/bencaos-tradicoes/story-006-escolha-aplicar-e-eventos.md) — pronta | gameplay-programmer | 1.0 (M) | bencaos-tradicoes-004, bencaos-tradicoes-005, modificadores (épico) | 5 | ACs da story + evidência do tipo Integration |
| bencaos-tradicoes-007 | [Mundo parado com a oferta aberta](../epics/bencaos-tradicoes/story-007-mundo-parado.md) — pronta | gameplay-programmer | 0.5 (S) | bencaos-tradicoes-005, orquestrador-do-passo (épico) | 5 | ACs da story + evidência do tipo Integration |
| telegrafos-005 | [Alvo travado e falha no vazio (emenda Pactos)](../epics/telegrafos/story-005-alvo-travado.md) — pronta | gameplay-programmer | 1.0 (M) | telegrafos-004, combate-nucleo (épico) | 5 | ACs da story + evidência do tipo Logic |
| bencaos-tradicoes-008 | [Texto da carta com o número da raridade](../epics/bencaos-tradicoes/story-008-texto-da-carta.md) — pronta | gameplay-programmer | 0.5 (S) | bencaos-tradicoes-006, modificadores (épico) | 6 | ACs da story + evidência do tipo Logic |

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
| — | Definido por `/sprint-plan update` ao fechar a Sprint 3 | — |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Dependências de épico inteiro (ex.: armas -> run/bênçãos/telemetria) empurram stories para sprints futuras | Certa | Médio | Já refletido: stories de armas distribuídas em S4/S5/S8 |
| Contrato de telégrafo ainda instável para IA e Pipeline | Média | Alto | Congelar a API de telégrafos no fim da S4 (revisão do lead-programmer) |

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
