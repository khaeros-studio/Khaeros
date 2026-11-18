# Epic: Input e controle

> **Layer**: Foundation
> **GDD**: design/gdd/input-e-controle.md
> **Architecture Module**: Input (amostra por passo, buffer, remapeamento, binds)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories input`
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Amostra de entrada por passo, buffer de 10 passos, remapeamento e arquivo de binds (via repositório da Persistência), rótulos de ação, cursor e `fonte_mira`, contextos por estado de jogo; ações de Pactos `troca` e `ponto_mira`. Trata foco duplo (4.6) e `InputEvent.device` ≠ 0 (4.7).

## Dependências entre épicos

- orquestrador-do-passo
- conteudo
- experimentos-de-engine (EX-0001-5, EX-0012-E2/E3)

## Estado atual do código

`src/foundation/game_input.gd` (317 linhas) **reaproveitar parcialmente**: leitura de `InputEvent`, eixos/radial, conexão de joystick e contextos são base útil. **Substituir** a amostra `Dictionary` por `AmostraDeEntrada` tipada e `ComandosDoPasso` (ADR-0006), acrescentar buffer de 10 passos, remapeamento persistido e as ações de Pactos; a conversão tela→mundo deve vir injetada da Cena.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0001: Orquestrador do passo e estados de jogo](../../../docs/architecture/adr-0001-orquestrador-do-passo.md) | Nó raiz sem Autoload; estado de jogo próprio (sem SceneTree.paused); passo de 60 Hz em ordem fixa; t_vivo/t_apres | HIGH |
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0006: Input por passo](../../../docs/architecture/adr-0006-input-por-passo.md) | Amostra própria por passo, buffer de 10 passos, remapeamento, troca e ponto_mira | HIGH |
| [ADR-0007: Cena, viewport e câmera](../../../docs/architecture/adr-0007-cena-viewport-e-camera.md) | canvas_transform, três faixas de stretch, câmera própria, parallax manual, tela→mundo sem impulsos | HIGH |
| [ADR-0012: UI e HUD](../../../docs/architecture/adr-0012-ui-e-hud.md) | Control em CanvasLayer, foco duplo, escala 85–150%, Bloco do Pacto e tela de consentimento | HIGH |
| [ADR-0013: Persistência do MVP](../../../docs/architecture/adr-0013-persistencia-do-mvp.md) | ConfigFile/FileAccess em user://, gravação atômica com .bak, perfil.cfg com [vinculo], telemetria .jsonl | MEDIUM |
| [ADR-0017: Aliados e invocações](../../../docs/architecture/adr-0017-aliados-e-invocacoes.md) | ModuloDeMaldicoes (item 6.1), MaldicaoRef, troca, técnica combinada, Chamado, reserva/Exaustão, IA de aliado | LOW |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **15 / 15** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-input-001 | Lista fechada de ações StringName; nenhuma tecla no código de jogo | ADR-0006 ✅ |
| TR-input-002 | Amostra única por passo de física, antes de qualquer sistema de jogo | ADR-0006 ✅, ADR-0001 ✅ |
| TR-input-003 | Dois dispositivos simultâneos; dispositivo ativo é o último com entrada significativa | ADR-0006 ✅ |
| TR-input-004 | Movimento em 8 direções normalizadas; zona morta radial e reescala | ADR-0006 ✅ |
| TR-input-005 | Mira do mouse via conversão tela para mundo da Cena; mira do analógico | ADR-0006 ✅, ADR-0007 ✅ |
| TR-input-006 | Remapeamento por dispositivo, persistido versionado e atômico | ADR-0006 ✅, ADR-0013 ✅ |
| TR-input-007 | Buffer de comandos em passos inteiros que atravessa o hitstop; segurar repete | ADR-0006 ✅ |
| TR-input-008 | Perda de foco da janela ou desconexão do gamepad pausa e solta os botões | ADR-0001 ✅, ADR-0006 ✅, ADR-0012 ✅ |
| TR-input-009 | Telas sem mouse com foco inicial e um único modelo de foco | ADR-0006 ✅, ADR-0012 ✅ |
| TR-input-010 | Contextos de entrada com roteamento e barreira de retorno | ADR-0006 ✅, ADR-0012 ✅ |
| TR-input-011 | Provedor de amostras injetado; testes roteirizados sem dispositivo | ADR-0006 ✅ |
| TR-input-012 | Valores de tuning vêm do catálogo validado (InputTuning) | ADR-0004 ✅, ADR-0006 ✅ |
| TR-input-013 | Ação troca no buffer com contador único; consumo Movimento, Combate, Selo, Maldições | ADR-0006 ✅, ADR-0017 ✅ |
| TR-input-014 | Campo ponto_mira (vec2 de mundo ou vazio) na amostra de 9 campos | ADR-0006 ✅ |
| TR-input-015 | Arquivo de binds antigo sem a ação nova recebe INPUT_ACAO_NOVA e bind livre | ADR-0006 ✅, ADR-0013 ✅ |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/input-e-controle.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)
