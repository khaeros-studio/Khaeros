# Epic: Feedback de combate

> **Layer**: Presentation
> **GDD**: design/gdd/feedback-de-combate.md
> **Architecture Module**: Feedback de combate (árbitro eventos→respostas, VFX, números)
> **Status**: Complete
> **Stories**: 8 / 8 Complete (`story-001` a `story-008`)
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Árbitro eventos→respostas, pool de VFX e números de dano, contador agregado de dano de status, impulsos de câmera; lê a lista de eventos do passo.

## Dependências entre épicos

- combate-nucleo
- pipeline-visual
- experimentos-de-engine (EX-0011-E3)

## Estado atual do código

`world_view.gd::_effect` desenha efeitos à mão: **substituir** pelo árbitro e pools; o hitstop e os impulsos da fatia são referência de sensação.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0001: Orquestrador do passo e estados de jogo](../../../docs/architecture/adr-0001-orquestrador-do-passo.md) | Nó raiz sem Autoload; estado de jogo próprio (sem SceneTree.paused); passo de 60 Hz em ordem fixa; t_vivo/t_apres | HIGH |
| [ADR-0002: Canal de eventos](../../../docs/architecture/adr-0002-canal-de-eventos.md) | Lista de EventoDoPasso por passo mais chamadas síncronas; Apresentação lê a lista | HIGH |
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0007: Cena, viewport e câmera](../../../docs/architecture/adr-0007-cena-viewport-e-camera.md) | canvas_transform, três faixas de stretch, câmera própria, parallax manual, tela→mundo sem impulsos | HIGH |
| [ADR-0010: Resolução do combate no passo](../../../docs/architecture/adr-0010-resolucao-do-combate-no-passo.md) | Ordem dos itens do passo, dano, empurrão, varredura de mortes, facções e ferir_maldicao/ferir_acuada/subjugar | HIGH |
| [ADR-0011: Pipeline visual](../../../docs/architecture/adr-0011-pipeline-visual.md) | Três famílias de shader, LUT global, passes de tela, material por entidade, relógio t_apres | HIGH |
| [ADR-0013: Persistência do MVP](../../../docs/architecture/adr-0013-persistencia-do-mvp.md) | ConfigFile/FileAccess em user://, gravação atômica com .bak, perfil.cfg com [vinculo], telemetria .jsonl | MEDIUM |
| [ADR-0016: Áudio: ganchos e vozes](../../../docs/architecture/adr-0016-audio-ganchos-e-vozes.md) | Barramentos, pool de vozes, eventos→sons pela lista do passo (SomDef, AudioTuning) | MEDIUM |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **16 / 16** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-feedback-001 | Árbitro puro: lista de eventos e relógios entram, pedidos ordenados saem | ADR-0002 ✅ |
| TR-feedback-002 | Só lê eventos e nunca escreve em sistema de jogo | ADR-0002 ✅, ADR-0011 ✅ |
| TR-feedback-003 | Catálogo evento para resposta; remetente único de impulso de câmera, um por passo | ADR-0002 ✅, ADR-0007 ✅ |
| TR-feedback-004 | Prioridades P0-P4 e limitador F6; pedido negado é descartado e o evento segue | ADR-0011 ✅ |
| TR-feedback-005 | Degradação de VFX por uso medido, com histerese | ADR-0011 ✅ |
| TR-feedback-006 | Respostas vivas congelam no hitstop; respostas de apresentação correm | ADR-0002 ✅, ADR-0001 ✅ |
| TR-feedback-007 | Números de dano: faixas por alvo, agregação, teto e regra de saída | ADR-0002 ✅, ADR-0011 ✅ |
| TR-feedback-008 | Um som por gancho por passo; limite de vozes por gancho e total, por prioridade | ADR-0016 ✅ |
| TR-feedback-009 | Acerto marcado lido da flag do evento acerto, sem contagem própria | ADR-0002 ✅, ADR-0010 ✅ |
| TR-feedback-010 | Ordem de camadas; impact frame é shader global, não camada | ADR-0011 ✅, ADR-0007 ✅ |
| TR-feedback-011 | Preempção no mesmo passo entre chefe, recusa, passes e telégrafos | ADR-0011 ✅ |
| TR-feedback-012 | Opções de acessibilidade aplicadas pelos donos, sem resposta que as contorne | ADR-0007 ✅, ADR-0011 ✅, ADR-0013 ✅ |
| TR-feedback-013 | Na Transição, descartar fila e respostas vivas; relógios zeram no meio do wipe | ADR-0001 ✅, ADR-0011 ✅ |
| TR-feedback-014 | Valores de tuning vêm do catálogo validado (FeedbackTuning) | ADR-0004 ✅ |
| TR-feedback-015 | Catálogo de 13 eventos das Maldições, golpe sem hitstop nem câmera, número agregado jogador e Maldição no mesmo alvo | ADR-0002 ✅, ADR-0011 ✅ |
| TR-feedback-016 | Ganchos de áudio sfx_maldicao_* | ADR-0016 ✅ |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/feedback-de-combate.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)
