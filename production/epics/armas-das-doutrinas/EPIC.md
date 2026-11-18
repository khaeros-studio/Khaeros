# Epic: Armas das Doutrinas

> **Layer**: Feature
> **GDD**: design/gdd/armas-das-doutrinas.md
> **Architecture Module**: Armas (WeaponDef, ArmasTuning, arma da run)
> **Status**: Complete
> **Stories**: 8 stories (2026-11-16, `/create-stories`, QL-STORY: skipped — lean) — ver tabela abaixo
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Uma arma por Doutrina: Lâmina do Juramento (Lâmina), Foco Ressonante (Ressonância) e Besta do Vínculo (Pactos, 3ª arma pela emenda) com `WeaponDef`, `ArmasTuning` e arma da run; entrega `WeaponDef` ao Modificadores e dois `AttackDef` ao Combate.

## Dependências entre épicos

- combate-nucleo
- modificadores
- conteudo

## Estado atual do código

A Lâmina da fatia (combo, golpe pesado, estocada em `game_session.gd`) é **referência de sensação**; reimplementar como dados (`WeaponDef`/`AttackDef`).

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0001: Orquestrador do passo e estados de jogo](../../../docs/architecture/adr-0001-orquestrador-do-passo.md) | Nó raiz sem Autoload; estado de jogo próprio (sem SceneTree.paused); passo de 60 Hz em ordem fixa; t_vivo/t_apres | HIGH |
| [ADR-0002: Canal de eventos](../../../docs/architecture/adr-0002-canal-de-eventos.md) | Lista de EventoDoPasso por passo mais chamadas síncronas; Apresentação lê a lista | HIGH |
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0006: Input por passo](../../../docs/architecture/adr-0006-input-por-passo.md) | Amostra própria por passo, buffer de 10 passos, remapeamento, troca e ponto_mira | HIGH |
| [ADR-0009: Atributos e modificadores](../../../docs/architecture/adr-0009-atributos-e-modificadores.md) | Portador com cache reconstruído; arredondamento determinístico próprio (sem round()) | LOW |
| [ADR-0010: Resolução do combate no passo](../../../docs/architecture/adr-0010-resolucao-do-combate-no-passo.md) | Ordem dos itens do passo, dano, empurrão, varredura de mortes, facções e ferir_maldicao/ferir_acuada/subjugar | HIGH |
| [ADR-0012: UI e HUD](../../../docs/architecture/adr-0012-ui-e-hud.md) | Control em CanvasLayer, foco duplo, escala 85–150%, Bloco do Pacto e tela de consentimento | HIGH |
| [ADR-0013: Persistência do MVP](../../../docs/architecture/adr-0013-persistencia-do-mvp.md) | ConfigFile/FileAccess em user://, gravação atômica com .bak, perfil.cfg com [vinculo], telemetria .jsonl | MEDIUM |
| [ADR-0015: Ciclo da run e composição](../../../docs/architecture/adr-0015-ciclo-da-run-e-composicao.md) | Composição da run, câmaras→portas→bênção→chefe, encontro de pacto, quando gravar o perfil, ContaFragmentos | LOW |
| [ADR-0017: Aliados e invocações](../../../docs/architecture/adr-0017-aliados-e-invocacoes.md) | ModuloDeMaldicoes (item 6.1), MaldicaoRef, troca, técnica combinada, Chamado, reserva/Exaustão, IA de aliado | LOW |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **14 / 14** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-armas-001 | WeaponDef com exatamente 7 campos e AttackDef como sub-recurso; propriedade desconhecida é erro | ADR-0004 ✅ |
| TR-armas-002 | Arma sem regra própria em código: tudo vem das formas e params do AttackDef | ADR-0004 ✅, ADR-0010 ✅ |
| TR-armas-003 | Injeção da arma no começo da run: portador com vida_max e velocidade base, Combate com os dois AttackDef | ADR-0009 ✅, ADR-0010 ✅, ADR-0015 ✅ |
| TR-armas-004 | Tela de escolha antes da run com o componente de carta, navegável por teclado, mouse e gamepad | ADR-0012 ✅, ADR-0006 ✅ |
| TR-armas-005 | Estados Escolhendo, Equipada e Encerrada; arma fixa durante a run | ADR-0001 ✅, ADR-0015 ✅ |
| TR-armas-006 | Última arma em user://preferencias.cfg [armas] ultima_arma, gravada só ao confirmar | ADR-0013 ✅ |
| TR-armas-007 | Build de playtest sem pré-seleção e com zero leituras e gravações de preferencias.cfg | ADR-0013 ✅ |
| TR-armas-008 | Chave derivada <chave_nome>_DESC e nomes canônicos validados, sem campo novo | ADR-0004 ✅ |
| TR-armas-009 | Validações cruzadas AV1-AV8 na segunda passada, com relatório de conjunto exato | ADR-0004 ✅ |
| TR-armas-010 | Valores de tuning vêm do ArmasTuning e dos WeaponDef validados no catálogo | ADR-0004 ✅ |
| TR-armas-011 | Arma escolhida em cada run chega à Telemetria local | ADR-0002 ✅, ADR-0013 ✅ |
| TR-armas-012 | Especial chamado da Besta só pede o salto à Maldição pela consulta pode chamar; recusa não consome recarga e emite chamado_indisponivel | ADR-0010 ✅, ADR-0017 ✅, ADR-0002 ✅ |
| TR-armas-013 | Virote emite acerto_virote para a marca da Maldição | ADR-0002 ✅ |
| TR-armas-014 | AV9 forma chamado só no slot especial de WeaponDef pactos; pares com pactos validados pelo ML8 na 2ª passada | ADR-0004 ✅ |

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | WeaponDef, AttackDef e as três armas de fábrica | Logic | Complete | ADR-0004, ADR-0010 |
| 002 | Validação das armas (AV1–AV9, V2, nomes canônicos) | Logic | Complete | ADR-0004 |
| 003 | Fórmulas de referência das armas (F1–F7) | Logic | Complete | ADR-0004, ADR-0009, ADR-0010 |
| 004 | Arma da run — estados, injeção e telemetria | Integration | Complete | ADR-0015, ADR-0009, ADR-0010 |
| 005 | Pré-seleção, confirmação e preferência ultima_arma | Logic | Complete | ADR-0013 |
| 006 | Besta do Vínculo — Virote e Chamado | Integration | Complete | ADR-0010, ADR-0017 |
| 007 | Tela de escolha de arma | UI | Complete | ADR-0012, ADR-0006 |
| 008 | Silhueta das armas e verificação em jogo | Visual/Feel | Complete | ADR-0010, ADR-0004 |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/armas-das-doutrinas.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)
