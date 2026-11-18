# Epic: Movimento e esquiva

> **Layer**: Core
> **GDD**: design/gdd/movimento-e-esquiva.md
> **Architecture Module**: Movimento (único escritor da posição do jogador, cargas de esquiva)
> **Status**: Complete
> **Stories**: 10 / 10 Complete (`story-001` a `story-010`)
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Única escritora da posição do jogador; esquiva com cargas e recarga; colisão própria de círculos e retângulo (sem `CharacterBody2D`); contrato injetado com o Combate; geometria das Maldições e deslocamento forçado.

## Dependências entre épicos

- input
- cena-e-camera
- modificadores

## Estado atual do código

`src/gameplay/movement.gd` (44 linhas, funções estáticas sobre `Dictionary`) **reaproveitar a matemática** (`resolve`, `recharge`, `teleport`, `displace`) e **substituir a forma**: estado por jogador tipado com `player_id` (preparação co-op), portador do Modificadores e contrato do Combate. A esquiva hoje em `game_session.gd` (`_start_dash`) migra para cá.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0001: Orquestrador do passo e estados de jogo](../../../docs/architecture/adr-0001-orquestrador-do-passo.md) | Nó raiz sem Autoload; estado de jogo próprio (sem SceneTree.paused); passo de 60 Hz em ordem fixa; t_vivo/t_apres | HIGH |
| [ADR-0002: Canal de eventos](../../../docs/architecture/adr-0002-canal-de-eventos.md) | Lista de EventoDoPasso por passo mais chamadas síncronas; Apresentação lê a lista | HIGH |
| [ADR-0003: Entidades e portadores](../../../docs/architecture/adr-0003-entidades-e-portadores.md) | Estado de combatente e portador em RefCounted; InimigoRef, MaldicaoRef, slots de telégrafo reutilizáveis | LOW |
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0006: Input por passo](../../../docs/architecture/adr-0006-input-por-passo.md) | Amostra própria por passo, buffer de 10 passos, remapeamento, troca e ponto_mira | HIGH |
| [ADR-0007: Cena, viewport e câmera](../../../docs/architecture/adr-0007-cena-viewport-e-camera.md) | canvas_transform, três faixas de stretch, câmera própria, parallax manual, tela→mundo sem impulsos | HIGH |
| [ADR-0008: Movimento e colisão própria](../../../docs/architecture/adr-0008-movimento-e-colisao-propria.md) | Círculos e retângulo próprios, sem CharacterBody2D; Movimento é o único escritor da posição | LOW |
| [ADR-0009: Atributos e modificadores](../../../docs/architecture/adr-0009-atributos-e-modificadores.md) | Portador com cache reconstruído; arredondamento determinístico próprio (sem round()) | LOW |
| [ADR-0010: Resolução do combate no passo](../../../docs/architecture/adr-0010-resolucao-do-combate-no-passo.md) | Ordem dos itens do passo, dano, empurrão, varredura de mortes, facções e ferir_maldicao/ferir_acuada/subjugar | HIGH |
| [ADR-0012: UI e HUD](../../../docs/architecture/adr-0012-ui-e-hud.md) | Control em CanvasLayer, foco duplo, escala 85–150%, Bloco do Pacto e tela de consentimento | HIGH |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **14 / 14** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-movimento-001 | Só o Movimento escreve a posição do jogador; outros pedem deslocar(v) | ADR-0008 ✅, ADR-0003 ✅ |
| TR-movimento-002 | Roda só em Jogo; o orquestrador decide passo() ou passo_congelado() | ADR-0001 ✅, ADR-0008 ✅ |
| TR-movimento-003 | passo_congelado() só iguala anterior a atual; sem consulta ao hitstop | ADR-0001 ✅, ADR-0008 ✅ |
| TR-movimento-004 | Ordem interna fixa do passo; Movimento antes de Combate e Selo | ADR-0008 ✅, ADR-0001 ✅ |
| TR-movimento-005 | Pedidos síncronos ao Combate na ordem cancelar, garantir_invulneravel, esquiva_iniciada | ADR-0008 ✅ |
| TR-movimento-006 | Esquiva pelo buffer; toque sem carga no congelamento emite esquiva_sem_carga no 1º passo vivo | ADR-0006 ✅, ADR-0008 ✅ |
| TR-movimento-007 | Colisão própria discreta com círculos e retângulo; inimigos não bloqueiam | ADR-0008 ✅ |
| TR-movimento-008 | Teleporte com aviso para reset de interpolação na apresentação | ADR-0007 ✅, ADR-0008 ✅ |
| TR-movimento-009 | Corte da esquiva: consulta ordenada, M pelo portador, aplicar_corte no Combate, sem hitstop | ADR-0008 ✅, ADR-0009 ✅, ADR-0010 ✅ |
| TR-movimento-010 | Máximo de cargas sincronizado com o atributo no item 0 | ADR-0008 ✅, ADR-0009 ✅ |
| TR-movimento-011 | Módulo puro injetado; determinismo bit a bit entre instâncias no mesmo build | ADR-0003 ✅, ADR-0008 ✅ |
| TR-movimento-012 | Consultas e eventos esquiva e esquiva_sem_carga para HUD, Pipeline e Áudio | ADR-0002 ✅, ADR-0012 ✅, ADR-0008 ✅ |
| TR-movimento-013 | Valores de tuning vêm do catálogo validado (MovementTuning, MV1-MV8) | ADR-0004 ✅ |
| TR-movimento-014 | Orçamento de CPU do Movimento até 0,2 ms por passo (provisório) | ADR-0001 ✅ |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/movimento-e-esquiva.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)
