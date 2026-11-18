# Epic: Selo e Fluxo

> **Layer**: Feature
> **GDD**: design/gdd/selo-e-fluxo.md
> **Architecture Module**: Selo e Fluxo
> **Status**: Complete
> **Stories**: 5 stories (2026-11-16, `/create-stories`, QL-STORY: skipped — lean) — ver tabela abaixo
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Lista de Selos e o recurso Fluxo; `no_selo()`, `fator_lentidao`, eventos `selo`/`selo_fim`; reset do Fluxo na nova run é estado do Selo.

## Dependências entre épicos

- combate-nucleo
- input
- modificadores

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
| [ADR-0006: Input por passo](../../../docs/architecture/adr-0006-input-por-passo.md) | Amostra própria por passo, buffer de 10 passos, remapeamento, troca e ponto_mira | HIGH |
| [ADR-0009: Atributos e modificadores](../../../docs/architecture/adr-0009-atributos-e-modificadores.md) | Portador com cache reconstruído; arredondamento determinístico próprio (sem round()) | LOW |
| [ADR-0010: Resolução do combate no passo](../../../docs/architecture/adr-0010-resolucao-do-combate-no-passo.md) | Ordem dos itens do passo, dano, empurrão, varredura de mortes, facções e ferir_maldicao/ferir_acuada/subjugar | HIGH |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **15 / 15** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-selo-001 | Fluxo float 0..100 com regeneração por passo vivo no item 6 e +3 por acerto_de_arma do item 5 | ADR-0002 ✅, ADR-0010 ✅ |
| TR-selo-002 | Plantar no item 6, depois do golpe, consumindo só selo do buffer | ADR-0001 ✅, ADR-0010 ✅, ADR-0006 ✅ |
| TR-selo-003 | Flag do Input selo apertado neste passo para selo_sem_fluxo uma vez por toque | ADR-0006 ✅ |
| TR-selo-004 | Investida ativa lida pelo Combate no item 5 antes do disparo, guardada e entregue ao Selo | ADR-0010 ✅ |
| TR-selo-005 | Dano por passo pelo caminho silencioso de ferir_inimigo, com M do grupo Selo a cada passo | ADR-0010 ✅, ADR-0009 ✅ |
| TR-selo-006 | Consulta no_selo(inimigo) válida até o próximo item 6, lida pela IA | ADR-0003 ✅ |
| TR-selo-007 | Acerto do item 8 credita Fluxo no fim do passo e só serve no seguinte | ADR-0010 ✅, ADR-0002 ✅ |
| TR-selo-008 | Fluxo, recarga e Selos parados no hitstop e fora de Jogo | ADR-0001 ✅ |
| TR-selo-009 | Selos apagados no quadro da metade do wipe pelo aviso câmara nova, sem selo_fim | ADR-0001 ✅ |
| TR-selo-010 | Inimigo morto pelo Selo cai na varredura do Combate | ADR-0010 ✅ |
| TR-selo-011 | Lista de Selos ativos em ordem de criação, marcas por inimigo, sem SceneTree | ADR-0003 ✅ |
| TR-selo-012 | Eventos selo, selo_sem_fluxo e selo_fim emitidos pelo Selo | ADR-0002 ✅ |
| TR-selo-013 | Valores de tuning vêm do SealTuning validado no catálogo (SV1-SV12) | ADR-0004 ✅ |
| TR-selo-014 | Fluxo só por acerto_de_arma, Virote gera e golpe de Maldição não | ADR-0010 ✅, ADR-0002 ✅ |
| TR-selo-015 | Teste dentro do Selo percorre só inimigos, Maldição imune | ADR-0010 ✅ |

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | SealTuning e validação SV1–SV12 | Integration | Complete | ADR-0004 |
| 002 | Fluxo — regeneração, acerto de arma e congelamento | Logic | Complete | ADR-0010, ADR-0002, ADR-0001 |
| 003 | Plantar o Selo — custo, recarga, buffer e centro preso | Logic | Complete | ADR-0010, ADR-0006 |
| 004 | Dano do Selo, abates e imunidade da Maldição | Logic | Complete | ADR-0010, ADR-0009 |
| 005 | Lentidão, consulta no_selo e Selos apagados na câmara nova | Logic | Complete | ADR-0003, ADR-0001 |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/selo-e-fluxo.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)
