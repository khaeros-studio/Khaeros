# Epic: Tela de bênção e carta

> **Layer**: Presentation
> **GDD**: design/gdd/tela-de-bencao-e-carta.md
> **Architecture Module**: Tela de bênção e carta (CartaView, 8 estados) + consentimento do pacto
> **Status**: Complete
> **Stories**: 9 / 9 Complete (`story-001` a `story-009`) — ver tabela abaixo
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

`CartaView` e máquina de 8 estados ligada a `oferta_aberta`; mesma tela serve ao consentimento do pacto (estado BENCAO, ADR-0001).

## Dependências entre épicos

- bencaos-tradicoes
- input
- vinculo-e-pactos
- experimentos-de-engine (EX-0012-E1)

## Estado atual do código

`game_hud.gd::_card` desenha cartas à mão: **substituir** por `Control`; referência de layout apenas.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0002: Canal de eventos](../../../docs/architecture/adr-0002-canal-de-eventos.md) | Lista de EventoDoPasso por passo mais chamadas síncronas; Apresentação lê a lista | HIGH |
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0006: Input por passo](../../../docs/architecture/adr-0006-input-por-passo.md) | Amostra própria por passo, buffer de 10 passos, remapeamento, troca e ponto_mira | HIGH |
| [ADR-0011: Pipeline visual](../../../docs/architecture/adr-0011-pipeline-visual.md) | Três famílias de shader, LUT global, passes de tela, material por entidade, relógio t_apres | HIGH |
| [ADR-0012: UI e HUD](../../../docs/architecture/adr-0012-ui-e-hud.md) | Control em CanvasLayer, foco duplo, escala 85–150%, Bloco do Pacto e tela de consentimento | HIGH |
| [ADR-0013: Persistência do MVP](../../../docs/architecture/adr-0013-persistencia-do-mvp.md) | ConfigFile/FileAccess em user://, gravação atômica com .bak, perfil.cfg com [vinculo], telemetria .jsonl | MEDIUM |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **15 / 15** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-tela-bencao-001 | Só lê e devolve escolher ou trocar por objeto injetado; relógio de UI injetável | ADR-0012 ✅ |
| TR-tela-bencao-002 | CartaView montada pela Bênçãos a partir do BoonDef (glifo, icone_ganho, chave do preço com {valor}) | ADR-0012 ✅ |
| TR-tela-bencao-003 | Fileira na ordem do sorteio e escala s com margem de 48 px | ADR-0012 ✅ |
| TR-tela-bencao-004 | Um modelo de foco para mouse, teclado e gamepad | ADR-0012 ✅, ADR-0006 ✅ |
| TR-tela-bencao-005 | Trava de 500 ms, borda de subida e buffer esvaziado ao abrir | ADR-0012 ✅, ADR-0006 ✅ |
| TR-tela-bencao-006 | Troca e confirmar no mesmo quadro, só trocar(); troca sem carga desabilitada | ADR-0012 ✅ |
| TR-tela-bencao-007 | Sinais preco_revelado e tela_fechada; a Bênçãos segura bencao_escolhida até tela_fechada | ADR-0002 ✅, ADR-0012 ✅ |
| TR-tela-bencao-008 | Mundo congelado em gravura no fundo; entrada em até 0,45 s | ADR-0011 ✅ |
| TR-tela-bencao-009 | Pausa por cima, sem pular; perder o foco da janela não pausa nem escolhe | ADR-0012 ✅, ADR-0006 ✅ |
| TR-tela-bencao-010 | Alto contraste, redução de movimento e Reduzir flashes pelo limitador | ADR-0011 ✅, ADR-0012 ✅, ADR-0013 ✅ |
| TR-tela-bencao-011 | Componente reutilizável CartaView e GrupoDeCartas com modos; só bênção no MVP | ADR-0012 ✅ |
| TR-tela-bencao-012 | Valores de tuning (TelaBencaoTuning) vêm do catálogo validado (TB1-TB10) | ADR-0004 ✅ |
| TR-tela-bencao-013 | Foco e escolher respondem no quadro do aperto (até 16,7 ms) | ADR-0012 ✅ |
| TR-tela-bencao-014 | Modo arma no MVP com 3 cartas e aviso_texto opcional na CartaView | ADR-0012 ✅ |
| TR-tela-bencao-015 | Modo maldicao com duas escolhas em ordem para a Escolha do Pacto | ADR-0012 ✅ |

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | ModeloDeFoco, DadosDaCarta e fileira (F1, F2, navegação) | Logic | Complete | ADR-0012, ADR-0006 |
| 002 | GrupoDeCartas — 8 estados, travas, pausa e foco da janela | Logic | Complete | ADR-0012, ADR-0006 |
| 003 | Troca, confirmação, PortaDaBencao e sinais | Logic | Complete | ADR-0012, ADR-0002 |
| 004 | TelaBencaoTuning — injeção e validação TB1–TB10 | Logic | Complete | ADR-0004 |
| 005 | CartaView e VistaDaTela — Control, carta, foco, gravura, acessibilidade | UI | Complete | ADR-0012, ADR-0011, ADR-0013 |
| 006 | Integração com a Bênçãos real | Integration | Complete | ADR-0012, ADR-0002 |
| 007 | Modo arma — Escolha de arma | UI | Complete | ADR-0012, ADR-0006 |
| 008 | Modo maldicao — Escolha do Pacto | UI | Complete | ADR-0012, ADR-0006 |
| 009 | Tela de consentimento do pacto | UI | Complete | ADR-0012, ADR-0013 |

Escolha de arma/Pacto (007, 008) e consentimento (009) entraram neste épico (specs `design/ux/tela-escolha-de-arma-e-pacto.md`, `tela-consentimento-do-pacto.md`).

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/tela-de-bencao-e-carta.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)
