# Epic: Cena 3/4 e câmera

> **Layer**: Foundation
> **GDD**: design/gdd/cena-3-4-e-camera.md
> **Architecture Module**: Cena 3/4 e câmera (viewport, 11 camadas, câmera própria)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories cena-e-camera`
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Viewport, 11 camadas, câmera própria por `canvas_transform`, três faixas de stretch e pillarbox, parallax manual, ordem por pé/spawn, snapshot tela→mundo sem impulsos e bases `pos`/`pos_seguir`.

## Dependências entre épicos

- orquestrador-do-passo
- conteudo
- input
- experimentos-de-engine (EX-0007-NV)

## Estado atual do código

`src/presentation/game_camera.gd` (109 linhas) **reaproveitar**: já é câmera própria em `RefCounted` com `screen_to_world`, impulsos e `_apply_transform` — alinhada ao ADR-0007. Conferir as três faixas de stretch, o snapshot sem impulsos e mover para a pasta de Foundation; os 67 checks isolados citados na arquitetura viram testes em `tests/unit/cena/`.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0001: Orquestrador do passo e estados de jogo](../../../docs/architecture/adr-0001-orquestrador-do-passo.md) | Nó raiz sem Autoload; estado de jogo próprio (sem SceneTree.paused); passo de 60 Hz em ordem fixa; t_vivo/t_apres | HIGH |
| [ADR-0002: Canal de eventos](../../../docs/architecture/adr-0002-canal-de-eventos.md) | Lista de EventoDoPasso por passo mais chamadas síncronas; Apresentação lê a lista | HIGH |
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0006: Input por passo](../../../docs/architecture/adr-0006-input-por-passo.md) | Amostra própria por passo, buffer de 10 passos, remapeamento, troca e ponto_mira | HIGH |
| [ADR-0007: Cena, viewport e câmera](../../../docs/architecture/adr-0007-cena-viewport-e-camera.md) | canvas_transform, três faixas de stretch, câmera própria, parallax manual, tela→mundo sem impulsos | HIGH |
| [ADR-0011: Pipeline visual](../../../docs/architecture/adr-0011-pipeline-visual.md) | Três famílias de shader, LUT global, passes de tela, material por entidade, relógio t_apres | HIGH |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **13 / 13** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-cena-001 | Viewport lógico 1920x1080, stretch canvas_items e keep_height, com pillarbox | ADR-0007 ✅ |
| TR-cena-002 | 1 unidade = 1,5 px, convertida só na importação | ADR-0007 ✅ |
| TR-cena-003 | Plano de jogo = tela; pé e altura visual separados | ADR-0007 ✅ |
| TR-cena-004 | Lista canônica de camadas de render | ADR-0007 ✅, ADR-0011 ✅ |
| TR-cena-005 | Y-sort pelo y do pé com ordenação total e parallax manual | ADR-0007 ✅ |
| TR-cena-006 | Câmara de 1920x1080 a 2880x1620 e limites da câmera | ADR-0007 ✅ |
| TR-cena-007 | Câmera segue com lookahead e suavização, interpolada sobre o passo fixo | ADR-0007 ✅ |
| TR-cena-008 | Impulsos de câmera na apresentação, com remetente único e um por passo | ADR-0007 ✅, ADR-0002 ✅ |
| TR-cena-009 | Relógio da câmera é t_apres, injetado | ADR-0001 ✅, ADR-0007 ✅ |
| TR-cena-010 | Conversão tela para mundo pela câmera base, sem chute, tremor nem zoom | ADR-0007 ✅, ADR-0006 ✅ |
| TR-cena-011 | Corte da câmera no quadro da metade do wipe, na Transição | ADR-0001 ✅, ADR-0007 ✅ |
| TR-cena-012 | Valores de tuning vêm do catálogo validado (CameraTuning) | ADR-0004 ✅, ADR-0007 ✅ |
| TR-cena-013 | Câmera, impulsos e relógio injetados; testes com câmera falsa | ADR-0007 ✅ |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/cena-3-4-e-camera.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)
