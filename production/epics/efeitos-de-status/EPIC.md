# Epic: Efeitos de status

> **Layer**: Feature
> **GDD**: design/gdd/efeitos-de-status.md
> **Architecture Module**: Efeitos de status (Sangramento, Queimadura, Abalo)
> **Status**: Complete
> **Stories**: 7 stories (2026-11-16, `/create-stories`, QL-STORY: skipped — lean)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Modelo de status e aplicar_status](story-001-modelo-e-aplicar.md) | Logic | Complete | ADR-0003, ADR-0010 |
| 002 | [Tick no item 7 e dano silencioso](story-002-tick-e-dano-silencioso.md) | Logic | Complete | ADR-0010, ADR-0001 |
| 003 | [Morte por status, congelamento e troca de câmara](story-003-morte-congelamento-e-limpeza.md) | Integration | Complete | ADR-0010, ADR-0001 |
| 004 | [Abalo com relógio único](story-004-abalo.md) | Logic | Complete | ADR-0009 |
| 005 | [Fontes de status e Maldições](story-005-fontes-e-maldicoes.md) | Integration | Complete | ADR-0010, ADR-0017 |
| 006 | [Número agregado e estado(inimigo)](story-006-numero-e-consulta.md) | Logic | Complete | ADR-0011, ADR-0002 |
| 007 | [StatusTuning e validação ST1–ST11](story-007-status-tuning-e-validacao.md) | Integration | Complete | ADR-0004 |
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Estado por inimigo de Sangramento, Queimadura e Abalo; `aplicar_status`, `abalado()`, `estado()`.

## Dependências entre épicos

- combate-nucleo
- ia-de-inimigos-e-elites

## Estado atual do código

Nenhum código na fatia de 2026-11-14 cobre este módulo: construção do zero.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0001: Orquestrador do passo e estados de jogo](../../../docs/architecture/adr-0001-orquestrador-do-passo.md) | Nó raiz sem Autoload; estado de jogo próprio (sem SceneTree.paused); passo de 60 Hz em ordem fixa; t_vivo/t_apres | HIGH |
| [ADR-0002: Canal de eventos](../../../docs/architecture/adr-0002-canal-de-eventos.md) | Lista de EventoDoPasso por passo mais chamadas síncronas; Apresentação lê a lista | HIGH |
| [ADR-0003: Entidades e portadores](../../../docs/architecture/adr-0003-entidades-e-portadores.md) | Estado de combatente e portador em RefCounted; InimigoRef, MaldicaoRef, slots de telégrafo reutilizáveis | LOW |
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0009: Atributos e modificadores](../../../docs/architecture/adr-0009-atributos-e-modificadores.md) | Portador com cache reconstruído; arredondamento determinístico próprio (sem round()) | LOW |
| [ADR-0010: Resolução do combate no passo](../../../docs/architecture/adr-0010-resolucao-do-combate-no-passo.md) | Ordem dos itens do passo, dano, empurrão, varredura de mortes, facções e ferir_maldicao/ferir_acuada/subjugar | HIGH |
| [ADR-0011: Pipeline visual](../../../docs/architecture/adr-0011-pipeline-visual.md) | Três famílias de shader, LUT global, passes de tela, material por entidade, relógio t_apres | HIGH |
| [ADR-0017: Aliados e invocações](../../../docs/architecture/adr-0017-aliados-e-invocacoes.md) | ModuloDeMaldicoes (item 6.1), MaldicaoRef, troca, técnica combinada, Chamado, reserva/Exaustão, IA de aliado | LOW |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **13 / 13** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-status-001 | Estado por inimigo: Sangramento e Queimadura (acúmulos float + restante int) e Abalo (restante), em passos vivos | ADR-0003 ✅ |
| TR-status-002 | aplicar_status síncrono, chamado por Combate e Selo, recusando alvo não atingível | ADR-0002 ✅, ADR-0010 ✅, ADR-0009 ✅ |
| TR-status-003 | Dano por passo no item 7, em ordem estável, antes de impacto e IA; aplicado no item 8 fere no passo seguinte | ADR-0010 ✅, ADR-0001 ✅ |
| TR-status-004 | Dano de status pelo caminho silencioso de ferir_inimigo, sem acerto, empurrão, hitstop, Fluxo nem M | ADR-0010 ✅ |
| TR-status-005 | Morte por status fechada na varredura do item 9 | ADR-0010 ✅ |
| TR-status-006 | Abalo com relógio único no Status e fonte única no portador | ADR-0009 ✅ |
| TR-status-007 | Contadores de status congelam em hitstop e fora de Jogo | ADR-0001 ✅ |
| TR-status-008 | Troca de câmara limpa todos os status | ADR-0001 ✅, ADR-0010 ✅ |
| TR-status-009 | Número agregado por inimigo com período em passos vivos e animação no relógio de apresentação | ADR-0002 ✅, ADR-0011 ✅ |
| TR-status-010 | Dependências injetadas; testes sem SceneTree | ADR-0003 ✅ |
| TR-status-011 | Valores de tuning vêm do catálogo validado (StatusTuning, ST1-ST11) | ADR-0004 ✅ |
| TR-status-012 | Consulta estado(inimigo) para HUD e VFX; sinais com teto de 3 e redução em multidão | ADR-0011 ✅, ADR-0003 ✅ |
| TR-status-013 | Golpe de Maldição aplica Abalo pelo impacto do Combate; Maldições sem status; Saída antes de Entrada no mesmo passo | ADR-0010 ✅, ADR-0017 ✅ |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/efeitos-de-status.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)
