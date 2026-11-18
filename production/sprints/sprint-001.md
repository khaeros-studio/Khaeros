# Sprint 1 — 2026-11-16 to 2026-11-29

> Gerado por `/sprint-plan new` (orquestrado, 2026-11-16) e sincronizado em 2026-11-18 com o estado real das stories no disco (49/49 concluídas). Plano do marco MVP em 9 sprints — uma por onda de dependência.

## Sprint Goal
Fechar a lógica da Foundation (orquestrador, conteúdo, RNG, input, cena, persistência) com testes unitários verdes e concluir os experimentos de engine que destravam o orquestrador e o Pipeline.

## Goal Prerequisites
| Needed to show the goal | Status |
|-------------------------|--------|
| Testes unitários em `tests/unit/` (GdUnit4) | exists |

## Milestone Context
- Current Milestone: MVP ([production/milestones/mvp.md](../milestones/mvp.md))
- Milestone Deadline: 2027-02-14
- Sprints Remaining: 9 (incluindo esta)

## Capacity
- Equipe: 7 agentes de IA em paralelo (6–8), 2 semana(s) úteis
- Total days: 70 agente-dia
- Buffer (20%): 14 agente-dia
- Available: 56 agente-dia
- Carga planejada: 60.0 agente-dia (49 stories; S=0,5 / M=1 / L=2) — **49 concluídas (60.0 agente-dia entregues), 0 restantes**
- Estimativa não calibrada: não há histórico de velocidade (primeira sprint do plano).

## Ordem e paralelismo
Stories numa mesma onda não dependem entre si e podem correr ao mesmo tempo (até 7 agentes, um por pasta de sistema). Uma onda começa quando as dependências dela, na onda anterior, fecham — não a onda inteira.

- **Onda 1** (18): **experimentos-de-engine-001**, **experimentos-de-engine-002**, **orquestrador-do-passo-002**, conteudo-001, conteudo-004, conteudo-005, conteudo-006, experimentos-de-engine-003, experimentos-de-engine-004, experimentos-de-engine-005, experimentos-de-engine-006, experimentos-de-engine-008, experimentos-de-engine-009, persistencia-003, persistencia-004, persistencia-005, persistencia-008, rng-001
- **Onda 2** (8): **orquestrador-do-passo-001**, conteudo-002, conteudo-003, conteudo-007, conteudo-008, experimentos-de-engine-007, persistencia-002, rng-002
- **Onda 3** (7): **orquestrador-do-passo-003**, cena-e-camera-001, input-001, persistencia-001, persistencia-006, persistencia-007, rng-003
- **Onda 4** (5): **orquestrador-do-passo-004**, cena-e-camera-002, input-002, input-007, rng-004
- **Onda 5** (7): **orquestrador-do-passo-005**, **orquestrador-do-passo-008**, cena-e-camera-003, input-003, input-004, input-006, rng-005
- **Onda 6** (3): cena-e-camera-004, cena-e-camera-005, cena-e-camera-007
- **Onda 7** (1): cena-e-camera-006

Em negrito: caminho crítico (EX-0001/0002 -> orquestrador -> modificadores -> movimento -> combate -> IA -> câmaras -> portas -> run).

## Tasks

### Must Have (Critical Path)
| ID | Task (story) | Agent/Owner | Est. Days | Dependencies | Onda | Status | Acceptance Criteria |
|----|------|-------------|-----------|-------------|------|--------|-------------------|
| experimentos-de-engine-001 | [Experimentos do passo e do quadro (EX-0001-1, -2, -6)](../epics/experimentos-de-engine/story-001-passo-e-quadro.md) — **concluída (2026-11-16, com pendências)** | godot-specialist | 1.0 (M) | — | 1 | done | ACs da story + evidência do tipo Integration |
| experimentos-de-engine-002 | [Experimentos do catálogo e da cena (EX-0004-NV, EX-0007-NV)](../epics/experimentos-de-engine/story-002-catalogo-e-cena.md) — **concluída (2026-11-16, com pendências)** | godot-specialist | 1.0 (M) | — | 1 | done | ACs da story + evidência do tipo Integration |
| orquestrador-do-passo-002 | [Entidades vivas, identidade na run e varredura de mortes](../epics/orquestrador-do-passo/story-002-entidades-e-identidade.md) — **concluída (2026-11-17)** | engine-programmer | 1.0 (M) | — | 1 | done | ACs da story + evidência do tipo Logic |
| conteudo-001 | [Esquema de definição, diagnóstico e relator de erros injetável](../epics/conteudo/story-001-esquema-e-relator.md) — **concluída (2026-11-16)** | tools-programmer | 1.0 (M) | — | 1 | done | ACs da story + evidência do tipo Logic |
| conteudo-004 | [Validadores V1–V4, V6–V8, V10 e V11](../epics/conteudo/story-004-validadores-v1-v11.md) — **concluída (2026-11-16, com pendências)** | tools-programmer | 2.0 (L) | — | 1 | done | ACs da story + evidência do tipo Logic |
| conteudo-005 | [Unidades do Godot e funções F1–F8](../epics/conteudo/story-005-unidades-f1-f8.md) — **concluída (2026-11-16)** | tools-programmer | 0.5 (S) | — | 1 | done | ACs da story + evidência do tipo Logic |
| conteudo-006 | [Validação dos donos (ML, VP, CH e demais Tunings) e segunda passada](../epics/conteudo/story-006-validacao-dos-donos.md) — **concluída (2026-11-18)** | tools-programmer | 2.0 (L) | — | 1 | done | ACs da story + evidência do tipo Logic |
| experimentos-de-engine-003 | [Experimentos de foco, pausa própria e apresentação (EX-0001-4, -5, EX-0012-E3)](../epics/experimentos-de-engine/story-003-foco-e-apresentacao.md) — **concluída (2026-11-16, com pendências)** | godot-specialist | 1.0 (M) | — | 1 | done | ACs da story + evidência do tipo Integration |
| experimentos-de-engine-004 | [Experimentos de eventos, ponto flutuante e latência (EX-0002-1..3, EX-0009-1, EX-0010-1)](../epics/experimentos-de-engine/story-004-eventos-aritmetica-latencia.md) — **concluída (2026-11-16, com pendências)** | godot-specialist | 1.0 (M) | — | 1 | done | ACs da story + evidência do tipo Integration |
| experimentos-de-engine-005 | [Experimentos de persistência e telemetria (EX-0013-P1..P7)](../epics/experimentos-de-engine/story-005-persistencia-e-telemetria.md) — **concluída (2026-11-16, com pendências)** | godot-specialist | 2.0 (L) | — | 1 | done | ACs da story + evidência do tipo Integration |
| experimentos-de-engine-006 | [Experimentos do pipeline A: globais, relógios e draw calls (EX-0001-3, EX-0011-E1..E3)](../epics/experimentos-de-engine/story-006-pipeline-globais-relogios-draw-calls.md) — **concluída (2026-11-17)** | godot-specialist | 2.0 (L) | — | 1 | done | ACs da story + evidência do tipo Visual/Feel |
| experimentos-de-engine-008 | [Experimentos de UI: offset, ações nativas, textos, clipboard (EX-0012-E1, E2, E4, E5, E6, CB)](../epics/experimentos-de-engine/story-008-ui-offset-ui-actions-clipboard.md) — **concluída (2026-11-16)** | ui-programmer | 1.0 (M) | — | 1 | done | ACs da story + evidência do tipo UI |
| experimentos-de-engine-009 | [Experimento de API de áudio (EX-0016-A)](../epics/experimentos-de-engine/story-009-audio-api.md) — **concluída (2026-11-16)** | godot-specialist | 0.5 (S) | — | 1 | done | ACs da story + evidência do tipo Integration |
| persistencia-003 | [RepositorioDePerfil: formato, PortaDeSecao [vinculo] e texto determinístico](../epics/persistencia/story-003-repositorio-de-perfil-formato.md) — **concluída (2026-11-16)** | godot-gdscript-specialist | 1.0 (M) | — | 1 | done | ACs da story + evidência do tipo Logic |
| persistencia-004 | [Carga: arquivo ausente, corrompido (.bak), versão futura e migração](../epics/persistencia/story-004-carga-corrupcao-versao-e-migracao.md) — **concluída (2026-11-16)** | godot-gdscript-specialist | 1.0 (M) | — | 1 | done | ACs da story + evidência do tipo Logic |
| persistencia-005 | [Ids desconhecidos: órfãs, ultima_dupla e preservação de seções](../epics/persistencia/story-005-orfas-e-preservacao-de-chaves.md) — **concluída (2026-11-16)** | godot-gdscript-specialist | 0.5 (S) | — | 1 | done | ACs da story + evidência do tipo Logic |
| persistencia-008 | [Sair/fechar janela com gravação e reset com duas confirmações](../epics/persistencia/story-008-sair-e-reset.md) — **concluída (2026-11-16)** | godot-gdscript-specialist | 1.0 (M) | — | 1 | done | ACs da story + evidência do tipo Logic |
| rng-001 | [Núcleo do gerador mulberry32, derivação de fluxo e máscara u32](../epics/rng/story-001-nucleo-do-gerador-mulberry32.md) — **concluída (2026-11-16)** | engine-programmer | 1.0 (M) | — | 1 | done | ACs da story + evidência do tipo Logic |
| orquestrador-do-passo-001 | [Canal de eventos do passo (EventoDoPasso, EventosDoPasso, ConsumidorDeEventos)](../epics/orquestrador-do-passo/story-001-canal-de-eventos.md) — **concluída (2026-11-17, com pendências)** | engine-programmer | 1.0 (M) | experimentos-de-engine-004 | 2 | done | ACs da story + evidência do tipo Logic |
| conteudo-002 | [Tipos de definição do MVP como Resource (incl. Pactos)](../epics/conteudo/story-002-tipos-de-definicao.md) — **concluída (2026-11-16, com pendências)** | tools-programmer | 2.0 (L) | conteudo-001 | 2 | done | ACs da story + evidência do tipo Logic |
| conteudo-003 | [Carregador síncrono, manifesto explícito e harness de carga](../epics/conteudo/story-003-carregador-e-manifesto.md) — **concluída (2026-11-16, com pendências)** | tools-programmer | 1.0 (M) | experimentos-de-engine-002 | 2 | done | ACs da story + evidência do tipo Integration |
| conteudo-007 | [Consulta (obter, existe, listar, filtrar), ordem do manifesto e cópia mutável](../epics/conteudo/story-007-consulta-e-copia.md) — **concluída (2026-11-16)** | tools-programmer | 1.0 (M) | experimentos-de-engine-002 | 2 | done | ACs da story + evidência do tipo Logic |
| conteudo-008 | [Impressão canônica SHA-256 do catálogo](../epics/conteudo/story-008-impressao-canonica.md) — **concluída (2026-11-16, com pendências)** | tools-programmer | 1.0 (M) | experimentos-de-engine-002 | 2 | done | ACs da story + evidência do tipo Logic |
| experimentos-de-engine-007 | [Experimentos do pipeline B: SDF, CanvasGroup, fio e material (EX-0011-E4..E7)](../epics/experimentos-de-engine/story-007-pipeline-sdf-canvasgroup-material.md) — **concluída (2026-11-17)** | godot-specialist | 2.0 (L) | experimentos-de-engine-006 | 2 | done | ACs da story + evidência do tipo Visual/Feel |
| persistencia-002 | [ArmazemUserGodot e gravar_atomico (.tmp, releitura, substituição)](../epics/persistencia/story-002-armazem-user-godot-gravacao-atomica.md) — **concluída (2026-11-16, com pendências)** | godot-gdscript-specialist | 1.0 (M) | experimentos-de-engine (épico) | 2 | done | ACs da story + evidência do tipo Integration |
| rng-002 | [Operações F5–F8 e erros que não consomem](../epics/rng/story-002-operacoes-e-erros-que-nao-consomem.md) — **concluída (2026-11-16)** | engine-programmer | 1.0 (M) | rng-001 | 2 | done | ACs da story + evidência do tipo Logic |
| orquestrador-do-passo-003 | [OrquestradorDoPasso: estado de jogo, pedidos de estado e final comum](../epics/orquestrador-do-passo/story-003-orquestrador-estado-e-pedidos.md) — **concluída (2026-11-16)** | engine-programmer | 1.0 (M) | orquestrador-do-passo-001, experimentos-de-engine-001 | 3 | done | ACs da story + evidência do tipo Logic |
| cena-e-camera-001 | [Geometria de viewport em três faixas e chaves do `project.godot`](../epics/cena-e-camera/story-001-geometria-de-viewport-e-project-godot.md) — **concluída (2026-11-16, com pendências)** | engine-programmer | 1.0 (M) | orquestrador-do-passo (épico) | 3 | done | ACs da story + evidência do tipo Logic |
| input-001 | [Ações, mapa padrão de binds e adaptador de eventos](../epics/input/story-001-acoes-mapa-padrao-e-adaptador-de-eventos.md) — **concluída (2026-11-16, com pendências)** | engine-programmer | 2.0 (L) | orquestrador-do-passo (épico) | 3 | done | ACs da story + evidência do tipo Logic |
| persistencia-001 | [ArmazemDeArquivos, ArmazemEmMemoria e CaminhosDePersistencia](../epics/persistencia/story-001-armazem-de-arquivos-e-caminhos.md) — **concluída (2026-11-16)** | godot-gdscript-specialist | 1.0 (M) | orquestrador-do-passo (épico) | 3 | done | ACs da story + evidência do tipo Logic |
| persistencia-006 | [Save: carga uma vez por sessão, catálogo Falhou e PerfilNulo](../epics/persistencia/story-006-sequencia-de-carga-e-modo-sem-gravacao.md) — **concluída (2026-11-16)** | godot-gdscript-specialist | 1.0 (M) | conteudo (épico), orquestrador-do-passo (épico) | 3 | done | ACs da story + evidência do tipo Logic |
| persistencia-007 | [Gatilhos de gravação, pendente coalescido e ponto seguro](../epics/persistencia/story-007-gatilhos-pendente-e-ponto-seguro.md) — **concluída (2026-11-16)** | godot-gdscript-specialist | 1.0 (M) | orquestrador-do-passo (épico) | 3 | done | ACs da story + evidência do tipo Logic |
| rng-003 | [Fonte de fluxos — posse, matriz dono × finalidade e ciclo de vida](../epics/rng/story-003-fonte-de-fluxos-posse-e-ciclo-de-vida.md) — **concluída (2026-11-16, com pendências)** | engine-programmer | 2.0 (L) | rng-001, rng-002 | 3 | done | ACs da story + evidência do tipo Logic |
| orquestrador-do-passo-004 | [Ordem fixa do passo vivo, hitstop e passo fora de JOGO](../epics/orquestrador-do-passo/story-004-ordem-do-passo.md) — **concluída (2026-11-16)** | engine-programmer | 1.0 (M) | orquestrador-do-passo-003 | 4 | done | ACs da story + evidência do tipo Logic |
| cena-e-camera-002 | [Limites da câmara (F4), validação de tamanho e `CameraTuning`](../epics/cena-e-camera/story-002-limites-da-camara-e-camera-tuning.md) — **concluída (2026-11-16, com pendências)** | engine-programmer | 1.0 (M) | cena-e-camera-001, conteudo (épico) | 4 | done | ACs da story + evidência do tipo Logic |
| input-002 | [Amostra por passo, movimento (F1/F2) e dispositivo ativo (F5)](../epics/input/story-002-amostra-por-passo-movimento-e-dispositivo.md) — **concluída (2026-11-16, com pendências)** | engine-programmer | 2.0 (L) | input-001, orquestrador-do-passo (épico) | 4 | done | ACs da story + evidência do tipo Logic |
| input-007 | [Remapeamento transacional e `rotulo_acao`](../epics/input/story-007-remapeamento-e-rotulos-de-acao.md) — **concluída (2026-11-16, com pendências)** | engine-programmer | 2.0 (L) | input-001 | 4 | done | ACs da story + evidência do tipo Logic |
| rng-004 | [Seed da run — nascimento, texto F9, entropia e `--seed` de debug](../epics/rng/story-004-seed-da-run-texto-e-entropia.md) — **concluída (2026-11-16, com pendências)** | engine-programmer | 1.0 (M) | rng-003 | 4 | done | ACs da story + evidência do tipo Logic |
| orquestrador-do-passo-005 | [Relógios t_vivo/t_apres, quadro() e troca de câmara em seis ações](../epics/orquestrador-do-passo/story-005-relogios-e-quadro.md) — **concluída (2026-11-16)** | engine-programmer | 1.0 (M) | orquestrador-do-passo-004, experimentos-de-engine-001 | 5 | done | ACs da story + evidência do tipo Logic |
| orquestrador-do-passo-008 | [Teste de convenções do passo (lint de código)](../epics/orquestrador-do-passo/story-008-lint-de-convencoes.md) — **concluída (2026-11-16)** | engine-programmer | 0.5 (S) | orquestrador-do-passo-004 | 5 | done | ACs da story + evidência do tipo Logic |
| cena-e-camera-003 | [Seguimento com lookahead (F2/F3) e interpolação sobre o passo fixo](../epics/cena-e-camera/story-003-seguimento-lookahead-e-interpolacao.md) — **concluída (2026-11-16, com pendências)** | engine-programmer | 2.0 (L) | cena-e-camera-002, orquestrador-do-passo (épico) | 5 | done | ACs da story + evidência do tipo Logic |
| input-003 | [Mira (F4), fonte da mira, intensidade e `ponto_mira`](../epics/input/story-003-mira-fonte-e-ponto-de-mira.md) — **concluída (2026-11-16, com pendências)** | engine-programmer | 1.0 (M) | input-002 | 5 | done | ACs da story + evidência do tipo Logic |
| input-004 | [Buffer de comandos, `ComandosDoPasso` e ação `troca`](../epics/input/story-004-buffer-de-comandos-e-troca.md) — **concluída (2026-11-16, com pendências)** | engine-programmer | 2.0 (L) | input-002 | 5 | done | ACs da story + evidência do tipo Logic |
| input-006 | [`InputTuning` do catálogo e modo sem catálogo](../epics/input/story-006-input-tuning-do-catalogo.md) — **concluída (2026-11-17, com pendências)** | engine-programmer | 1.0 (M) | input-002, conteudo (épico) | 5 | done | ACs da story + evidência do tipo Logic |
| rng-005 | [Contrato de reprodução, consumo fixo e estado inicial ampliado](../epics/rng/story-005-contrato-de-reproducao-e-consumo-fixo.md) — **concluída (2026-11-16)** | engine-programmer | 1.0 (M) | rng-002, rng-003, rng-004 | 5 | done | ACs da story + evidência do tipo Integration |
| cena-e-camera-004 | [Snapshot tela → mundo (F6), injeção e resize](../epics/cena-e-camera/story-004-snapshot-tela-para-mundo-e-resize.md) — **concluída (2026-11-16, com pendências)** | engine-programmer | 1.0 (M) | cena-e-camera-001, cena-e-camera-002, input-003 | 6 | done | ACs da story + evidência do tipo Logic |
| cena-e-camera-005 | [Impulsos de câmera (F5) com remetente único](../epics/cena-e-camera/story-005-impulsos-de-camera.md) — **concluída (2026-11-16, com pendências)** | engine-programmer | 1.0 (M) | cena-e-camera-003 | 6 | done | ACs da story + evidência do tipo Logic |
| cena-e-camera-007 | [Ordem por pé, parallax manual (F7) e unidade de mundo](../epics/cena-e-camera/story-007-ordem-por-pe-parallax-e-unidade-de-mundo.md) — **concluída (2026-11-16, com pendências)** | engine-programmer | 1.0 (M) | cena-e-camera-003, conteudo (épico) | 6 | done | ACs da story + evidência do tipo Logic |
| cena-e-camera-006 | [Estados da câmera, corte atômico e relógio `t_apres`](../epics/cena-e-camera/story-006-estados-corte-e-relogio-da-camera.md) — **concluída (2026-11-16, com pendências)** | engine-programmer | 2.0 (L) | cena-e-camera-003, cena-e-camera-005, orquestrador-do-passo (épico) | 7 | done | ACs da story + evidência do tipo Logic |

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
| experimentos-de-engine-001 | Iniciada antes do plano (concluída em 2026-11-16 com pendências) | 1.0 |
| experimentos-de-engine-002 | Iniciada antes do plano (concluída em 2026-11-16 com pendências) | 1.0 |
| orquestrador-do-passo-002 | Iniciada antes do plano (concluída em 2026-11-17) | 1.0 |
| conteudo-001 | Iniciada antes do plano (concluída em 2026-11-16) | 1.0 |
| conteudo-004 | Iniciada antes do plano (concluída em 2026-11-16 com pendências) | 2.0 |
| experimentos-de-engine-004 | Iniciada antes do plano (concluída em 2026-11-16 com pendências) | 1.0 |
| experimentos-de-engine-005 | Iniciada antes do plano (concluída em 2026-11-16 com pendências) | 2.0 |
| persistencia-003 | Iniciada antes do plano (concluída em 2026-11-16) | 1.0 |
| persistencia-004 | Iniciada antes do plano (concluída em 2026-11-16) | 1.0 |
| persistencia-005 | Iniciada antes do plano (concluída em 2026-11-16) | 0.5 |
| rng-001 | Iniciada antes do plano (concluída em 2026-11-16) | 1.0 |
| orquestrador-do-passo-001 | Iniciada antes do plano (concluída em 2026-11-17 com pendências) | 1.0 |
| conteudo-002 | Iniciada antes do plano (concluída em 2026-11-16 com pendências) | 2.0 |
| conteudo-003 | Iniciada antes do plano (concluída em 2026-11-16 com pendências) | 1.0 |
| persistencia-002 | Iniciada antes do plano (concluída em 2026-11-16 com pendências) | 1.0 |
| rng-002 | Iniciada antes do plano (concluída em 2026-11-16) | 1.0 |
| cena-e-camera-001 | Iniciada antes do plano (concluída em 2026-11-16 com pendências) | 1.0 |
| input-001 | Iniciada antes do plano (concluída em 2026-11-16 com pendências) | 2.0 |
| persistencia-001 | Iniciada antes do plano (concluída em 2026-11-16) | 1.0 |
| rng-003 | Iniciada antes do plano (concluída em 2026-11-16 com pendências) | 2.0 |
| cena-e-camera-002 | Iniciada antes do plano (concluída em 2026-11-16 com pendências) | 1.0 |
| input-002 | Iniciada antes do plano (concluída em 2026-11-16 com pendências) | 2.0 |
| rng-004 | Iniciada antes do plano (concluída em 2026-11-16 com pendências) | 1.0 |
| cena-e-camera-003 | Iniciada antes do plano (concluída em 2026-11-16 com pendências) | 2.0 |
| input-003 | Iniciada antes do plano (concluída em 2026-11-16 com pendências) | 1.0 |
| input-004 | Iniciada antes do plano (concluída em 2026-11-16 com pendências) | 2.0 |
| rng-005 | Iniciada antes do plano (concluída em 2026-11-16) | 1.0 |
| cena-e-camera-004 | Iniciada antes do plano (concluída em 2026-11-16 com pendências) | 1.0 |
| cena-e-camera-005 | Iniciada antes do plano (concluída em 2026-11-16 com pendências) | 1.0 |
| cena-e-camera-006 | Iniciada antes do plano (concluída em 2026-11-16 com pendências) | 2.0 |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Lote grande (49 stories) na Sprint 1 | Baixa (mitigado) | Médio | 49 de 49 stories concluídas (60.0 agente-dia entregues; 0 restantes) |
| Resultado de experimento (EX-0011) contradiz ADR aceito | Média | Alto | Escalar ao technical-director no mesmo dia ao rodar `experimentos-de-engine-006/007`; congelar stories do épico afetado até ADR revisado |
| Conflito de escrita em `project.godot`/autoloads entre agentes paralelos | Média | Médio | Um único agente por onda edita `project.godot`; demais só em suas pastas `src/foundation/<sistema>/` |
| Stories concluídas como `Done — com pendências` nos arquivos `.md` | Certa | Baixo | Pendências residuais de integração/evidência visual mapeadas nas próprias stories para fechamento com a composição da Sprint 2 |
| Carga inicial planejada (60.0) acima do disponível (56) | Baixa (mitigado) | Baixo | 49 de 49 stories entregues dentro da janela da Sprint 1 |

## Dependencies on External Factors
- Godot 4.7.2 instalado (`docs/engine-reference/godot/VERSION.md`); GdUnit4 para a suíte.
- Aprovação humana de evidências visuais (lead sign-off) para stories Visual/Feel e UI.
- Sem registro de riscos em `production/risk-register/`: riscos avaliados só pelo conteúdo da sprint.

## Definition of Done for this Sprint
- [x] All Must Have tasks completed (49/49 done)
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-001-[date].md`, from `/qa-plan sprint`)
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] Toda story que muda algo observável pelo jogador foi rodada e tem screenshot retido em `production/qa/evidence/`
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] A fatia jogável continua abrindo por `res://scenes/main.tscn`
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged
