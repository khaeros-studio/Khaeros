# Epic: HUD

> **Layer**: Presentation
> **GDD**: design/gdd/hud.md
> **Architecture Module**: HUD (Controls somente leitura)
> **Status**: Complete
> **Stories**: 10 / 10 Complete (`story-001` a `story-010`) — ver tabela abaixo
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

HUD somente leitura em `Control`/`CanvasLayer`, foco duplo, escala 85–150%, Bloco do Pacto, seed visível e copiável; lê por interface injetada.

## Dependências entre épicos

- combate-nucleo
- selo-e-fluxo
- movimento-e-esquiva
- economia-de-fragmentos
- camaras-e-ondas
- input
- maldicoes
- pipeline-visual
- experimentos-de-engine (EX-0012-E1/E6/CB)

## Estado atual do código

`src/presentation/game_hud.gd` (182 linhas, `Node2D` com `_draw`) **substituir**: o ADR-0012 exige `Control` em `CanvasLayer`. Aproveitar só layout e textos como referência; as telas de pausa/morte/vitória e cartas que hoje vivem aqui saem para este épico e para tela-de-bencao-e-carta.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0002: Canal de eventos](../../../docs/architecture/adr-0002-canal-de-eventos.md) | Lista de EventoDoPasso por passo mais chamadas síncronas; Apresentação lê a lista | HIGH |
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0006: Input por passo](../../../docs/architecture/adr-0006-input-por-passo.md) | Amostra própria por passo, buffer de 10 passos, remapeamento, troca e ponto_mira | HIGH |
| [ADR-0007: Cena, viewport e câmera](../../../docs/architecture/adr-0007-cena-viewport-e-camera.md) | canvas_transform, três faixas de stretch, câmera própria, parallax manual, tela→mundo sem impulsos | HIGH |
| [ADR-0011: Pipeline visual](../../../docs/architecture/adr-0011-pipeline-visual.md) | Três famílias de shader, LUT global, passes de tela, material por entidade, relógio t_apres | HIGH |
| [ADR-0012: UI e HUD](../../../docs/architecture/adr-0012-ui-e-hud.md) | Control em CanvasLayer, foco duplo, escala 85–150%, Bloco do Pacto e tela de consentimento | HIGH |
| [ADR-0013: Persistência do MVP](../../../docs/architecture/adr-0013-persistencia-do-mvp.md) | ConfigFile/FileAccess em user://, gravação atômica com .bak, perfil.cfg com [vinculo], telemetria .jsonl | MEDIUM |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **14 / 14** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-hud-001 | HUD só lê, sem escrita e sem estado de jogo | ADR-0002 ✅, ADR-0012 ✅ |
| TR-hud-002 | Na criação, inclusive na Transição, lê o estado por consulta, nunca só por evento | ADR-0002 ✅, ADR-0012 ✅ |
| TR-hud-003 | Âncoras nas bordas do viewport, margem de 48 px, escala de UI de 85 a 150%, ultrawide | ADR-0012 ✅, ADR-0007 ✅ |
| TR-hud-004 | Vinheta de Vida baixa na camada de pós (z 50), sem 12ª camada | ADR-0011 ✅, ADR-0012 ✅ |
| TR-hud-005 | Sinais preco_revelado e tela_fechada; rachar espera o hitstop; visibilidade pelo estado de jogo | ADR-0012 ✅ |
| TR-hud-006 | Glifo por dispositivo via rotulo_acao, trocado no passo seguinte | ADR-0012 ✅, ADR-0006 ✅ |
| TR-hud-007 | Relógio de UI em tempo real que para com a pausa | ADR-0012 ✅ |
| TR-hud-008 | Latência de no máximo 1 passo do evento da fonte | ADR-0002 ✅, ADR-0012 ✅ |
| TR-hud-009 | Fios de Vida em pool de 9, os mais próximos; aparecem pela queda da Vida, não pelo acerto | ADR-0012 ✅ |
| TR-hud-010 | Valores de tuning (HudTuning) vêm do catálogo validado (HU1-HU14) | ADR-0004 ✅ |
| TR-hud-011 | Camada de UI, fontes e orçamento de draw calls do Pipeline | ADR-0011 ✅ |
| TR-hud-012 | Opções de acessibilidade do HUD aplicadas e guardadas entre sessões | ADR-0012 ✅, ADR-0013 ✅ |
| TR-hud-013 | Bloco do Pacto só com Pactos, lê estado_pacto no início e reage a troca_indisponivel e troca_feita | ADR-0012 ✅, ADR-0002 ✅ |
| TR-hud-014 | Vida da Maldição em barra de largura fixa (F8), atualização em até 1 passo, troca de slots no passo do evento | ADR-0012 ✅ |

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Modelo do HUD — leitura injetada, relógio de interface e HudTuning | Logic | Complete | ADR-0012, ADR-0002, ADR-0004 |
| 002 | Vida — segmentos, largura, rachar, escudo, recusas e Vida baixa | Logic | Complete | ADR-0012, ADR-0011 |
| 003 | Fluxo, Esquiva, Fragmentos e glifos por dispositivo | Logic | Complete | ADR-0012, ADR-0006 |
| 004 | Fios de Vida, prompt, barra de chefe e visibilidade por estado | Logic | Complete | ADR-0012, ADR-0007 |
| 005 | Bloco do Pacto — modelo | Logic | Complete | ADR-0012, ADR-0002 |
| 006 | Vista do HUD — Control, âncoras, escala, vinheta no Pós e troca do game_hud | UI | Complete | ADR-0012, ADR-0007, ADR-0011 |
| 007 | Opções de acessibilidade do HUD — aplicação e persistência | Integration | Complete | ADR-0012, ADR-0013 |
| 008 | Menu de pausa — Continuar, Abandonar run e seed copiável | UI | Complete | ADR-0012, ADR-0006 |
| 009 | Tela de opções — escala, HUD, remapeamento, telemetria e reset | UI | Complete | ADR-0012, ADR-0013, ADR-0006 |
| 010 | Tela de fim de run | UI | Complete | ADR-0012, ADR-0006 |

Pausa/opções (008, 009) e fim de run (010) entraram neste épico (specs `design/ux/pausa-e-opcoes.md`, `tela-fim-de-run.md`).

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/hud.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)
