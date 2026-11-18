# Epic: Economia de Fragmentos

> **Layer**: Feature
> **GDD**: design/gdd/economia-de-fragmentos.md
> **Architecture Module**: Economia (ContaFragmentos)
> **Status**: Complete
> **Stories**: 7 (2026-11-16, QL-STORY: skipped — lean)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [ContaFragmentos — saldo, creditar e eventos](story-001-conta-creditar-e-eventos.md) | Logic | Complete | ADR-0015, ADR-0002 |
| 002 | [Teto do saldo e EconomyRates no catálogo](story-002-teto-e-economy-rates.md) | Logic | Complete | ADR-0004, ADR-0015 |
| 003 | [Gastar, Nova run e exportar/importar sem arquivo](story-003-gastar-nova-run-exportar.md) | Logic | Complete | ADR-0015, ADR-0013 |
| 004 | [LeituraDaConta, ContaFragmentosNula e injeção](story-004-leitura-nula-e-composicao.md) | Integration | Complete | ADR-0015, ADR-0012, ADR-0002 |
| 005 | [Ordem de crédito com Run e Portas](story-005-ordem-com-run-e-portas.md) | Integration | Complete | ADR-0015, ADR-0002 |
| 006 | [Crédito do chefe](story-006-credito-do-chefe.md) | Integration | Complete | ADR-0015, ADR-0001, ADR-0010 |
| 007 | [Saldo e "+N" no HUD — evidência](story-007-saldo-no-hud-evidencia.md) | UI | Complete | ADR-0012, ADR-0002 |
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

`ContaFragmentos` (saldo, coletados), `saldo()`, `creditar`, `saldo_mudou`; sem arquivo no MVP.

## Dependências entre épicos

- conteudo

## Estado atual do código

Nenhum código na fatia de 2026-11-14 cobre este módulo: construção do zero.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0001: Orquestrador do passo e estados de jogo](../../../docs/architecture/adr-0001-orquestrador-do-passo.md) | Nó raiz sem Autoload; estado de jogo próprio (sem SceneTree.paused); passo de 60 Hz em ordem fixa; t_vivo/t_apres | HIGH |
| [ADR-0002: Canal de eventos](../../../docs/architecture/adr-0002-canal-de-eventos.md) | Lista de EventoDoPasso por passo mais chamadas síncronas; Apresentação lê a lista | HIGH |
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0010: Resolução do combate no passo](../../../docs/architecture/adr-0010-resolucao-do-combate-no-passo.md) | Ordem dos itens do passo, dano, empurrão, varredura de mortes, facções e ferir_maldicao/ferir_acuada/subjugar | HIGH |
| [ADR-0012: UI e HUD](../../../docs/architecture/adr-0012-ui-e-hud.md) | Control em CanvasLayer, foco duplo, escala 85–150%, Bloco do Pacto e tela de consentimento | HIGH |
| [ADR-0013: Persistência do MVP](../../../docs/architecture/adr-0013-persistencia-do-mvp.md) | ConfigFile/FileAccess em user://, gravação atômica com .bak, perfil.cfg com [vinculo], telemetria .jsonl | MEDIUM |
| [ADR-0015: Ciclo da run e composição](../../../docs/architecture/adr-0015-ciclo-da-run-e-composicao.md) | Composição da run, câmaras→portas→bênção→chefe, encontro de pacto, quando gravar o perfil, ContaFragmentos | LOW |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **9 / 9** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-economia-001 | ContaFragmentos injetada, sem singleton, com saldo que atravessa as runs e coletados_run | ADR-0015 ✅ |
| TR-economia-002 | Valores de tuning (EconomyRates) vêm do catálogo validado; cada taxa tem um só dono | ADR-0004 ✅ |
| TR-economia-003 | Interface só de leitura para HUD e Telemetria; evento saldo_mudou | ADR-0002 ✅, ADR-0012 ✅ |
| TR-economia-004 | Ordem com a Run (coletados antes da vitória, efetivo devolvido); nada creditado se a morte cai no mesmo passo | ADR-0002 ✅, ADR-0015 ✅ |
| TR-economia-005 | exportar() e importar(int) sem arquivo no MVP | ADR-0013 ✅ |
| TR-economia-006 | nova_run() zera coletados_run e mantém o saldo | ADR-0015 ✅ |
| TR-economia-007 | Run e Portas aceitam a Economia ausente sem quebrar | ADR-0015 ✅ |
| TR-economia-008 | Fonte chefe ativa, creditar(chefe, 6) chamado por Chefes no 1º passo vivo após o hitstop ou no Exorcizar; Pactuar não credita (EC1) | ADR-0015 ✅, ADR-0001 ✅, ADR-0010 ✅ |
| TR-economia-009 | Saldo de Fragmentos fora do save no MVP, enquanto pactos e vínculo persistem no perfil (decisão 21) | ADR-0013 ✅ |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/economia-de-fragmentos.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)
