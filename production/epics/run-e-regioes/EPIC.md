# Epic: Run e regiões (ciclo da run)

> **Layer**: Feature
> **GDD**: design/gdd/run-e-regioes.md
> **Architecture Module**: Run e regiões + composição da run (ADR-0015)
> **Status**: Complete
> **Stories**: 10 stories (2026-11-16, `/create-stories`, QL-STORY: skipped — lean) — ver `## Stories`

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Máquina de estados da Run](story-001-maquina-de-estados-da-run.md) | Logic | Complete | ADR-0015, ADR-0001 |
| 002 | [RunTuning e RegionDef, validação RN1–RN3](story-002-run-tuning-e-validacao.md) | Integration | Complete | ADR-0004 |
| 003 | [Sequência da região](story-003-sequencia-da-regiao.md) | Logic | Complete | ADR-0015, ADR-0004, ADR-0005 |
| 004 | [Início da run](story-004-inicio-da-run.md) | Logic | Complete | ADR-0015, ADR-0005, ADR-0001 |
| 005 | [Composição e EscopoDaRun (nova_run)](story-005-composicao-e-escopo-da-run.md) | Integration | Complete | ADR-0015, ADR-0003, ADR-0005, ADR-0009, ADR-0013 |
| 006 | [Vitória](story-006-vitoria.md) | Integration | Complete | ADR-0015, ADR-0002, ADR-0001 |
| 007 | [Morte, abandono e pausa](story-007-morte-abandono-e-pausa.md) | Logic | Complete | ADR-0015, ADR-0001, ADR-0002, ADR-0012, ADR-0006 |
| 008 | [ResumoDaRun imutável](story-008-resumo-da-run.md) | Logic | Complete | ADR-0015, ADR-0001, ADR-0002 |
| 009 | [Telas de início, pausa e final](story-009-telas-de-inicio-pausa-e-final.md) | UI | Complete | ADR-0012, ADR-0013, ADR-0015 |
| 010 | [Perfil e saída do jogo](story-010-perfil-e-saida-do-jogo.md) | Integration | Complete | ADR-0015, ADR-0013 |
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Máquina da run, seed, resumo; composição câmaras→portas→bênção→chefe (ADR-0015), encontro de pacto, quando gravar o perfil, `nova_run`/`run_encerrada`/`fim_da_run`.

## Dependências entre épicos

- camaras-e-ondas
- portas-e-recompensas
- economia-de-fragmentos
- armas-das-doutrinas
- rng
- persistencia

## Estado atual do código

`GameSession` como "composição de combate/IA/ondas" é o antecessor desta composição: **substituir** pela composição do ADR-0015 em `Main`.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0001: Orquestrador do passo e estados de jogo](../../../docs/architecture/adr-0001-orquestrador-do-passo.md) | Nó raiz sem Autoload; estado de jogo próprio (sem SceneTree.paused); passo de 60 Hz em ordem fixa; t_vivo/t_apres | HIGH |
| [ADR-0002: Canal de eventos](../../../docs/architecture/adr-0002-canal-de-eventos.md) | Lista de EventoDoPasso por passo mais chamadas síncronas; Apresentação lê a lista | HIGH |
| [ADR-0003: Entidades e portadores](../../../docs/architecture/adr-0003-entidades-e-portadores.md) | Estado de combatente e portador em RefCounted; InimigoRef, MaldicaoRef, slots de telégrafo reutilizáveis | LOW |
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0005: RNG determinístico](../../../docs/architecture/adr-0005-rng-deterministico.md) | mulberry32 próprio, fluxos por finalidade (9 com pactos), lint de CI contra randf/shuffle | LOW |
| [ADR-0006: Input por passo](../../../docs/architecture/adr-0006-input-por-passo.md) | Amostra própria por passo, buffer de 10 passos, remapeamento, troca e ponto_mira | HIGH |
| [ADR-0009: Atributos e modificadores](../../../docs/architecture/adr-0009-atributos-e-modificadores.md) | Portador com cache reconstruído; arredondamento determinístico próprio (sem round()) | LOW |
| [ADR-0012: UI e HUD](../../../docs/architecture/adr-0012-ui-e-hud.md) | Control em CanvasLayer, foco duplo, escala 85–150%, Bloco do Pacto e tela de consentimento | HIGH |
| [ADR-0013: Persistência do MVP](../../../docs/architecture/adr-0013-persistencia-do-mvp.md) | ConfigFile/FileAccess em user://, gravação atômica com .bak, perfil.cfg com [vinculo], telemetria .jsonl | MEDIUM |
| [ADR-0015: Ciclo da run e composição](../../../docs/architecture/adr-0015-ciclo-da-run-e-composicao.md) | Composição da run, câmaras→portas→bênção→chefe, encontro de pacto, quando gravar o perfil, ContaFragmentos | LOW |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **16 / 16** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-run-001 | Máquina de estados da run (Sem run, Escolha de arma, Ativa, Encerrada) coordenada com o orquestrador | ADR-0001 ✅, ADR-0005 ✅, ADR-0015 ✅ |
| TR-run-002 | Ordem de início arma, seed (entropia injetável, --seed só em debug), estado inicial, câmara 0, Transição | ADR-0005 ✅, ADR-0001 ✅ |
| TR-run-003 | Sequência pela RegionDef e camaras_jogaveis; p_max lido das Câmaras; montar o índice 6 é RN3 | ADR-0004 ✅ |
| TR-run-004 | Vitória na ordem camara_limpa, fim_da_run, crédito, run_encerrada; tela final sem Transição | ADR-0002 ✅, ADR-0015 ✅ |
| TR-run-005 | Morte vence a limpeza no mesmo passo | ADR-0001 ✅, ADR-0002 ✅ |
| TR-run-006 | Abandono pela pausa, desabilitado em Bênção; pausa recusada em Transição e Morte | ADR-0012 ✅, ADR-0006 ✅ |
| TR-run-007 | Resumo de 12 campos (10 + desfecho_chefe e dupla, R7-P) montado uma vez e imutável, lido pela tela final e pela Telemetria | ADR-0002 ✅, ADR-0015 ✅ |
| TR-run-008 | nova_run com reset total dos sistemas da run e descarte da seed e dos fluxos; saldo da Economia fora do reset | ADR-0005 ✅, ADR-0003 ✅, ADR-0009 ✅, ADR-0015 ✅ |
| TR-run-009 | Duração em passos de Jogo, contando o hitstop | ADR-0001 ✅ |
| TR-run-010 | Várias regiões (reservado) com índice da região na chave do RNG e no orçamento | ADR-0005 ✅ |
| TR-run-011 | Valores de tuning (RunTuning) vêm do catálogo validado (RN1-RN3) | ADR-0004 ✅ |
| TR-run-012 | Última arma escolhida vem marcada na tela de início | ADR-0013 ✅ |
| TR-run-013 | Estados da run com Escolha da dupla (só Pactos) entre Escolha de arma e Ativa; fase Subjugado não encerra a run | ADR-0015 ✅ |
| TR-run-014 | Run recebe pedir_dupla, dupla_confirmada, chefe_escolhido e chefe_subjugado; com Pactos cria a seed em dupla_confirmada | ADR-0015 ✅, ADR-0002 ✅, ADR-0005 ✅ |
| TR-run-015 | Vitória no chefe em ordem fixa (crédito do chefe, camara_limpa, fim_da_run, creditar vitoria, run_encerrada); morte no mesmo passo vence | ADR-0015 ✅, ADR-0001 ✅ |
| TR-run-016 | Reset total limpa Maldições, chefe e lacaios; registro de pactos e vínculo fica fora do reset, no perfil persistido | ADR-0015 ✅, ADR-0013 ✅ |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/run-e-regioes.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)
