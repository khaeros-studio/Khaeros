# Epic: Conteúdo orientado a dados

> **Layer**: Foundation
> **GDD**: design/gdd/conteudo-orientado-a-dados.md
> **Architecture Module**: Conteúdo (catálogo .tres, validadores V1–V11, impressão SHA-256)
> **Status**: Ready
> **Stories**: 10 stories (story-001 a story-010 nesta pasta)
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Catálogo de definições como `Resource` (`.tres`) carregado por manifesto único explícito, validado na carga (V1–V11 + segunda passada; erro bloqueia a run), com impressão SHA-256 e cópias mutáveis por `duplicate_deep`. Expõe `obter(tipo,id)` e `listar/filtrar` na ordem do manifesto. Os arquivos de dados em si são do épico assets-e-conteudo.

## Dependências entre épicos

- experimentos-de-engine (EX-0004-NV)

## Estado atual do código

`src/foundation/session_catalog.gd` (198 linhas) **substituir**: lê JSON (`res://data/integration/gameplay.json`) e valida à mão. Reaproveitar só as regras de faixa e finitude (`_number`, `_finite`, `_fields`) como referência para os validadores V1–V11; os valores do JSON migram para `.tres` no épico assets-e-conteudo.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0001: Orquestrador do passo e estados de jogo](../../../docs/architecture/adr-0001-orquestrador-do-passo.md) | Nó raiz sem Autoload; estado de jogo próprio (sem SceneTree.paused); passo de 60 Hz em ordem fixa; t_vivo/t_apres | HIGH |
| [ADR-0003: Entidades e portadores](../../../docs/architecture/adr-0003-entidades-e-portadores.md) | Estado de combatente e portador em RefCounted; InimigoRef, MaldicaoRef, slots de telégrafo reutilizáveis | LOW |
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0005: RNG determinístico](../../../docs/architecture/adr-0005-rng-deterministico.md) | mulberry32 próprio, fluxos por finalidade (9 com pactos), lint de CI contra randf/shuffle | LOW |
| [ADR-0012: UI e HUD](../../../docs/architecture/adr-0012-ui-e-hud.md) | Control em CanvasLayer, foco duplo, escala 85–150%, Bloco do Pacto e tela de consentimento | HIGH |
| [ADR-0013: Persistência do MVP](../../../docs/architecture/adr-0013-persistencia-do-mvp.md) | ConfigFile/FileAccess em user://, gravação atômica com .bak, perfil.cfg com [vinculo], telemetria .jsonl | MEDIUM |
| [ADR-0017: Aliados e invocações](../../../docs/architecture/adr-0017-aliados-e-invocacoes.md) | ModuloDeMaldicoes (item 6.1), MaldicaoRef, troca, técnica combinada, Chamado, reserva/Exaustão, IA de aliado | LOW |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **19 / 19** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-conteudo-001 | Tipos de definição como Resource, com formato, campos e unidades por tipo | ADR-0004 ✅ |
| TR-conteudo-002 | Ids snake_case únicos por tipo, nunca renomeados nem reaproveitados (append-only) | ADR-0004 ✅ |
| TR-conteudo-003 | Definição só de leitura em execução; cópia mutável por duplicate_deep | ADR-0004 ✅, ADR-0003 ✅ |
| TR-conteudo-004 | Manifesto único explícito, sem varredura em execução; teste de órfãos em CI | ADR-0004 ✅ |
| TR-conteudo-005 | Layout de assets/data/; cópia canônica em CSV excluída do export | ADR-0004 ✅ |
| TR-conteudo-006 | Unidades do Godot; TICK_RATE 60 conferido na carga; F7 segundos para passos | ADR-0004 ✅, ADR-0001 ✅ |
| TR-conteudo-007 | Definições guardam chaves de tradução, nunca texto; V6 confere a tabela | ADR-0004 ✅, ADR-0012 ✅ |
| TR-conteudo-008 | Dado só aponta para chaves registradas pelos donos; registro ausente é erro V4 | ADR-0004 ✅ |
| TR-conteudo-009 | Carga síncrona antes do menu, coleta todos os erros e bloqueia a run igual em debug e release | ADR-0004 ✅ |
| TR-conteudo-010 | Consulta por injeção (obter, existe, listar, filtrar) com relator de erros injetado | ADR-0004 ✅ |
| TR-conteudo-011 | Impressão SHA-256 sobre serialização canônica na ordem do manifesto | ADR-0004 ✅ |
| TR-conteudo-012 | Estados de carga e recarga só em debug e fora de run, com revogação e reinjeção | ADR-0004 ✅, ADR-0001 ✅ |
| TR-conteudo-013 | Lista canônica copiada só de leitura do cânone | ADR-0004 ✅ |
| TR-conteudo-014 | Script de importação F1-F6 em tools/content-import/ com teste de paridade | ADR-0004 ✅ |
| TR-conteudo-015 | Orçamento de carga: mediana até 250 ms e validação até 30 ms (advisory) | ADR-0004 ✅ |
| TR-conteudo-016 | Tipos CurseDef, BossPatternDef em EnemyDef.padroes, MaldicoesTuning, VinculoTuning e ChefesTuning | ADR-0004 ✅, ADR-0017 ✅ |
| TR-conteudo-017 | Mesmo id em CurseDef e EnemyDef com unicidade por tipo; ids de espécie são chave do perfil e nunca mudam | ADR-0004 ✅, ADR-0013 ✅ |
| TR-conteudo-018 | Validação ampliada V4, V5, V8 e códigos ML, VP e CH com ML7 e ML8 na 2ª passada | ADR-0004 ✅, ADR-0017 ✅ |
| TR-conteudo-019 | Ordem estável do manifesto de CurseDef para o sorteio do Vínculo | ADR-0004 ✅, ADR-0005 ✅ |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/conteudo-orientado-a-dados.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)
