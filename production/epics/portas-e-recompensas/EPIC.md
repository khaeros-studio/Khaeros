# Epic: Portas e recompensas

> **Layer**: Feature
> **GDD**: design/gdd/portas-e-recompensas.md
> **Architecture Module**: Portas e recompensas (RewardTable, recompensa pendente)
> **Status**: Complete
> **Stories**: 8 stories (2026-11-16, `/create-stories`, QL-STORY: skipped — lean) — ver `## Stories`

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [RewardTable no catálogo e validação PV1–PV8](story-001-reward-table-e-validacao.md) | Integration | Complete | ADR-0004 |
| 002 | [Sorteio das portas livres](story-002-sorteio-das-portas-livres.md) | Logic | Complete | ADR-0005 |
| 003 | [Portas forçadas, chaves e consumo fixo](story-003-portas-forcadas-e-chaves.md) | Logic | Complete | ADR-0005, ADR-0015 |
| 004 | [Conceder a recompensa](story-004-conceder-recompensa.md) | Logic | Complete | ADR-0015, ADR-0009 |
| 005 | [Fluxo da limpeza (R2)](story-005-fluxo-da-limpeza.md) | Logic | Complete | ADR-0015, ADR-0001, ADR-0002, ADR-0012 |
| 006 | [Aguardando pacto](story-006-aguardando-pacto.md) | Logic | Complete | ADR-0015, ADR-0002 |
| 007 | [Escolha da porta e EvPortaEscolhida](story-007-escolha-da-porta.md) | Integration | Complete | ADR-0015, ADR-0002 |
| 008 | [Portas no mundo](story-008-portas-no-mundo.md) | Visual/Feel | Complete | ADR-0011, ADR-0012, ADR-0002 |
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

`RewardTable`, recompensa pendente, `pedir_oferta`, `creditar`.

## Dependências entre épicos

- camaras-e-ondas
- bencaos-tradicoes
- economia-de-fragmentos
- rng

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
| [ADR-0009: Atributos e modificadores](../../../docs/architecture/adr-0009-atributos-e-modificadores.md) | Portador com cache reconstruído; arredondamento determinístico próprio (sem round()) | LOW |
| [ADR-0011: Pipeline visual](../../../docs/architecture/adr-0011-pipeline-visual.md) | Três famílias de shader, LUT global, passes de tela, material por entidade, relógio t_apres | HIGH |
| [ADR-0012: UI e HUD](../../../docs/architecture/adr-0012-ui-e-hud.md) | Control em CanvasLayer, foco duplo, escala 85–150%, Bloco do Pacto e tela de consentimento | HIGH |
| [ADR-0015: Ciclo da run e composição](../../../docs/architecture/adr-0015-ciclo-da-run-e-composicao.md) | Composição da run, câmaras→portas→bênção→chefe, encontro de pacto, quando gravar o perfil, ContaFragmentos | LOW |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **10 / 10** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-portas-001 | Fluxo portas com 4 reais fixos por escolha e chave pelo índice da câmara; portas forçadas consomem 0 | ADR-0005 ✅ |
| TR-portas-002 | Ordem recompensa, pedir_oferta, espera bencao_escolhida após tela_fechada, depois abre as portas; mundo parado | ADR-0001 ✅, ADR-0011 ✅, ADR-0012 ✅ |
| TR-portas-003 | Concessão ao camara_limpa; nada creditado se jogador_morreu cai no mesmo passo | ADR-0002 ✅, ADR-0001 ✅ |
| TR-portas-004 | Última câmara jogável sem recompensa e sem porta; contrato fim_da_run com a Run | ADR-0002 ✅, ADR-0015 ✅ |
| TR-portas-005 | porta_escolhida(i) vira a recompensa da próxima câmara e é entregue à Run; tudo injetado, sem SceneTree | ADR-0002 ✅, ADR-0015 ✅ |
| TR-portas-006 | Fragmentos creditados na ContaFragmentos injetada; cura lê vida_max do portador | ADR-0009 ✅, ADR-0015 ✅ |
| TR-portas-007 | Valores de tuning (RewardTable) vêm do catálogo validado (PV1-PV7) | ADR-0004 ✅ |
| TR-portas-008 | Evento de porta escolhida com tipo e opcoes para Telemetria e HUD | ADR-0002 ✅, ADR-0015 ✅ |
| TR-portas-009 | Estado Aguardando pacto com encontro_aguardando e pacto_resolvido lembrado; ordem recompensa, Bênção, pacto, portas | ADR-0002 ✅, ADR-0015 ✅ |
| TR-portas-010 | Porta forçada chefe sem sorteio; trio (portas, 0, 5) consumido sem reordenar outros fluxos | ADR-0005 ✅ |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/portas-e-recompensas.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)
