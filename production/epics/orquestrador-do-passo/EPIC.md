# Epic: Orquestrador do passo e canal de eventos

> **Layer**: Foundation
> **GDD**: docs/architecture/adr-0001-orquestrador-do-passo.md
> **Architecture Module**: Orquestrador do passo (sem GDD; ADR-0001) + canal de eventos (ADR-0002) + tipos de entidade (ADR-0003)
> **Status**: Ready
> **Stories**: 8 stories (story-001 a story-008 nesta pasta)
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Módulo de Foundation sem GDD: 8 dos GDDs o pressupõem e nenhum o define. Dono do estado de jogo (Jogo/Pausa/Bênção/Transição/Morte/Encerrada), da ordem fixa do passo a 60 Hz (`passo()`/`passo_congelado()`), dos relógios `t_vivo`/`t_apres`, do `modo_bencao` e da composição no nó raiz sem Autoload. Inclui a lista de eventos do passo (`EventoDoPasso`, ADR-0002) e os tipos base `RefCounted` de entidades e portadores (ADR-0003), que todos os módulos do passo consomem. O contador de hitstop é do Combate; aqui só se consulta `hitstop_ativo()`.

## Dependências entre épicos

- experimentos-de-engine (EX-0001-1/2/4/6, EX-0002)

## Estado atual do código

`src/app/main.gd` (229 linhas) **reaproveitar como esqueleto** da composição no nó raiz (já é Node sem Autoload, já usa `_physics_process`), mas **substituir** o laço: hoje chama `GameSession.step(sample: Dictionary)` e trata UI dentro do `Main`; o ADR-0001 exige enum de estado próprio, ordem fixa de itens, relógios separados e eventos tipados (ADR-0002) no lugar de `Array[String]`. `_handle_ui` sai para HUD/Tela; `_notification` (foco) fica aqui após EX-0001-5. A composição da run em si é do épico run-e-regioes (ADR-0015).

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0001: Orquestrador do passo e estados de jogo](../../../docs/architecture/adr-0001-orquestrador-do-passo.md) | Nó raiz sem Autoload; estado de jogo próprio (sem SceneTree.paused); passo de 60 Hz em ordem fixa; t_vivo/t_apres | HIGH |
| [ADR-0002: Canal de eventos](../../../docs/architecture/adr-0002-canal-de-eventos.md) | Lista de EventoDoPasso por passo mais chamadas síncronas; Apresentação lê a lista | HIGH |
| [ADR-0003: Entidades e portadores](../../../docs/architecture/adr-0003-entidades-e-portadores.md) | Estado de combatente e portador em RefCounted; InimigoRef, MaldicaoRef, slots de telégrafo reutilizáveis | LOW |

## Cobertura de TR

Não é dono de TR-IDs (o orquestrador não tem GDD). TRs de outros sistemas que ele sustenta, citados no ADR-0001: `combate-nucleo-001/002/011`, `movimento-002/003`, `cena-009/011`, `pipeline-004`, `ia-001`, `camaras-002/007`, `run-005`, `input-008`; e no ADR-0002: `combate-nucleo-009`, `feedback-001/003/009`, `hud-001`, `telemetria-*`. Ficam nos épicos dos seus sistemas.

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every item of the scope above closed with its result recorded
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)
