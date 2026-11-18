# Epic: Telemetria local

> **Layer**: Presentation
> **GDD**: design/gdd/telemetria-local.md
> **Architecture Module**: Telemetria (arquivo .jsonl, retenção; observador)
> **Status**: Complete
> **Stories**: 10 (2026-11-16, QL-STORY: skipped — lean)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Sessão, arquivo `.jsonl`, campos comuns e TelemetriaTuning | Logic | Complete | ADR-0013, ADR-0004 |
| 002 | Só escuta, o jogo nunca lê, privacidade | Logic | Complete | ADR-0002, ADR-0013 |
| 003 | Opção ligada/desligada e Apagar dados | Logic | Complete | ADR-0013 |
| 004 | Falhas (TL1), campo ausente (TL3) e orçamento por linha (TL2) | Logic | Complete | ADR-0013 |
| 005 | Limite de bytes, retenção e truncamento | Logic | Complete | ADR-0013 |
| 006 | Linhas de run, seed e impressão | Logic | Complete | ADR-0002, ADR-0005, ADR-0004 |
| 007 | Linha de câmara e contadores | Logic | Complete | ADR-0001 |
| 008 | Oferta, bênção, porta e morte | Logic | Complete | ADR-0002 |
| 009 | Schema 2 — linhas de Pactos | Logic | Complete | ADR-0013, ADR-0002 |
| 010 | Run completa, fixture e pior passo | Integration | Complete | ADR-0013, ADR-0002 |
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Observador que escuta eventos de Run, Bênçãos, Portas, Combate e Economia e grava `.jsonl` com retenção; gravação síncrona no passo da morte (orçamento 3 ms). Desvio do índice: está em Apresentação (o índice a põe em Polish).

## Dependências entre épicos

- persistencia
- run-e-regioes
- combate-nucleo
- experimentos-de-engine (EX-0013-P1/P4/P5)

## Estado atual do código

Nenhum código na fatia de 2026-11-14 cobre este módulo: construção do zero.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0001: Orquestrador do passo e estados de jogo](../../../docs/architecture/adr-0001-orquestrador-do-passo.md) | Nó raiz sem Autoload; estado de jogo próprio (sem SceneTree.paused); passo de 60 Hz em ordem fixa; t_vivo/t_apres | HIGH |
| [ADR-0002: Canal de eventos](../../../docs/architecture/adr-0002-canal-de-eventos.md) | Lista de EventoDoPasso por passo mais chamadas síncronas; Apresentação lê a lista | HIGH |
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0005: RNG determinístico](../../../docs/architecture/adr-0005-rng-deterministico.md) | mulberry32 próprio, fluxos por finalidade (9 com pactos), lint de CI contra randf/shuffle | LOW |
| [ADR-0013: Persistência do MVP](../../../docs/architecture/adr-0013-persistencia-do-mvp.md) | ConfigFile/FileAccess em user://, gravação atômica com .bak, perfil.cfg com [vinculo], telemetria .jsonl | MEDIUM |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **12 / 12** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-telemetria-001 | Um .jsonl por sessão em user://, descarga a cada linha, campos comuns, última linha pode ficar truncada | ADR-0013 ✅ |
| TR-telemetria-002 | Só escuta; o jogo nunca lê o arquivo; tudo injetado | ADR-0002 ✅, ADR-0013 ✅ |
| TR-telemetria-003 | Esquema dos 10 eventos do MVP e campos ainda não emitidos (causa da morte, porta escolhida, câmara entrou, passo vivo) | ADR-0002 ✅ |
| TR-telemetria-004 | Contadores por câmara; duração em passos de Jogo, contando o hitstop | ADR-0001 ✅ |
| TR-telemetria-005 | Opção telemetria_ligada na configuração do usuário; estados Armada e Desligada; Apagar dados | ADR-0013 ✅ |
| TR-telemetria-006 | Privacidade sem caminho absoluto nem identificador, data em UTC, sem rede | ADR-0013 ✅ |
| TR-telemetria-007 | Falhas absorvidas com um TL1 e Parada por falha; orçamento de 1 ms por linha e 3 ms por passo (TL2) | ADR-0013 ✅ |
| TR-telemetria-008 | Limite de bytes com reserva de 512 B; retenção das últimas 20 sessões | ADR-0013 ✅ |
| TR-telemetria-009 | Seed e impressão do catálogo (64 e 4 hex) nas linhas de sessão e de run | ADR-0004 ✅, ADR-0005 ✅ |
| TR-telemetria-010 | Valores de tuning (TelemetriaTuning) vêm do catálogo validado | ADR-0004 ✅ |
| TR-telemetria-011 | Schema 2 com encontro_pacto, pacto, vinculo_fim_run, run_iniciada com dupla e pactos e resumo de 12 campos | ADR-0013 ✅, ADR-0002 ✅ |
| TR-telemetria-012 | Pior passo com 5 linhas dentro do orçamento de 3 ms por passo | ADR-0013 ✅ |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/telemetria-local.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)
