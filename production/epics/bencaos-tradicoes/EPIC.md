# Epic: Bênçãos e Tradições

> **Layer**: Feature
> **GDD**: design/gdd/bencaos-tradicoes.md
> **Architecture Module**: Bênçãos (pool de 18 BoonDef)
> **Status**: Complete
> **Stories**: 10 (2026-11-16, QL-STORY: skipped — lean)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Pool de 18 BoonDef, RarityTable e BencaosTuning (BN1, BN2)](story-001-pool-e-tuning-no-catalogo.md) | Logic | Complete | ADR-0004 |
| 002 | [RegistroDeBencaos — pool, tomadas e restantes](story-002-registro-de-tomadas.md) | Logic | Complete | ADR-0015, ADR-0009 |
| 003 | [Sorteio da oferta — F7, raridade, 6 reais](story-003-sorteio-da-oferta.md) | Logic | Complete | ADR-0005 |
| 004 | [Troca da oferta e raridade_bonus](story-004-troca-e-raridade-bonus.md) | Logic | Complete | ADR-0005, ADR-0012 |
| 005 | [Contrato pedir_oferta, estados e BencaosNula](story-005-contrato-pedir-oferta.md) | Integration | Complete | ADR-0015, ADR-0002 |
| 006 | [Escolha — aplicar, registrar e emitir](story-006-escolha-aplicar-e-eventos.md) | Integration | Complete | ADR-0009, ADR-0002, ADR-0012 |
| 007 | [Mundo parado com a oferta aberta](story-007-mundo-parado.md) | Integration | Complete | ADR-0001, ADR-0011 |
| 008 | [Texto da carta com o número da raridade](story-008-texto-da-carta.md) | Logic | Complete | ADR-0009, ADR-0012 |
| 009 | [Cinco bênçãos por run e a Besta do Vínculo](story-009-cinco-bencaos-e-besta.md) | Integration | Complete | ADR-0009 |
| 010 | [Estatística da oferta (F1, F3, F4-P)](story-010-estatistica-da-oferta.md) | Logic | Complete | ADR-0005 |
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Pool de 18 `BoonDef`, oferta, bênçãos tomadas (`oferta_aberta`, `bencao_tomada`), aplicadas pelo Modificadores.

## Dependências entre épicos

- modificadores
- rng
- conteudo

## Estado atual do código

As bênçãos explícitas de `game_session.gd::choose_blessing` são **substituídas** por `BoonDef` + Modificadores.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0001: Orquestrador do passo e estados de jogo](../../../docs/architecture/adr-0001-orquestrador-do-passo.md) | Nó raiz sem Autoload; estado de jogo próprio (sem SceneTree.paused); passo de 60 Hz em ordem fixa; t_vivo/t_apres | HIGH |
| [ADR-0002: Canal de eventos](../../../docs/architecture/adr-0002-canal-de-eventos.md) | Lista de EventoDoPasso por passo mais chamadas síncronas; Apresentação lê a lista | HIGH |
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0005: RNG determinístico](../../../docs/architecture/adr-0005-rng-deterministico.md) | mulberry32 próprio, fluxos por finalidade (9 com pactos), lint de CI contra randf/shuffle | LOW |
| [ADR-0009: Atributos e modificadores](../../../docs/architecture/adr-0009-atributos-e-modificadores.md) | Portador com cache reconstruído; arredondamento determinístico próprio (sem round()) | LOW |
| [ADR-0011: Pipeline visual](../../../docs/architecture/adr-0011-pipeline-visual.md) | Três famílias de shader, LUT global, passes de tela, material por entidade, relógio t_apres | HIGH |
| [ADR-0012: UI e HUD](../../../docs/architecture/adr-0012-ui-e-hud.md) | Control em CanvasLayer, foco duplo, escala 85–150%, Bloco do Pacto e tela de consentimento | HIGH |
| [ADR-0015: Ciclo da run e composição](../../../docs/architecture/adr-0015-ciclo-da-run-e-composicao.md) | Composição da run, câmaras→portas→bênção→chefe, encontro de pacto, quando gravar o perfil, ContaFragmentos | LOW |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **11 / 11** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-bencaos-001 | Pool de 18 BoonDef na ordem do manifesto | ADR-0004 ✅ |
| TR-bencaos-002 | Registro de tomadas sem repetir, restantes() e tomadas(), zerado na Nova run | ADR-0009 ✅, ADR-0015 ✅ |
| TR-bencaos-003 | Fluxos bencaos e raridade com F7 e consumo fixo de 6 reais por oferta e por troca | ADR-0005 ✅ |
| TR-bencaos-004 | Efeito aplicado pelo Modificadores antes do registro e dos eventos | ADR-0009 ✅ |
| TR-bencaos-005 | Troca e escolha no mesmo passo, a troca vence; sem pular | ADR-0012 ✅ |
| TR-bencaos-006 | Contrato síncrono pedir_oferta(região, índice), sem_bencao, oferta_ja_aberta, restantes() | ADR-0002 ✅, ADR-0015 ✅ |
| TR-bencaos-007 | Eventos oferta_aberta, oferta_trocada e bencao_tomada para Tela, HUD, Áudio e Telemetria | ADR-0002 ✅, ADR-0012 ✅ |
| TR-bencaos-008 | Mundo parado com a oferta aberta; contadores do Combate não descontam | ADR-0001 ✅, ADR-0011 ✅ |
| TR-bencaos-009 | Texto da carta com o número da raridade, arredondado como no Modificadores, em chave de tradução | ADR-0009 ✅, ADR-0012 ✅ |
| TR-bencaos-010 | Valores de tuning (BencaosTuning, RarityTable) vêm do catálogo validado (BN1, BN2) | ADR-0004 ✅ |
| TR-bencaos-011 | Bênção de dano_todo_pct espelha no portador da Maldição no mesmo passo; Tradição de slot só no Virote | ADR-0009 ✅ |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/bencaos-tradicoes.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)
