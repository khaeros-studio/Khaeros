# Epic: Assets e conteúdo

> **Layer**: Foundation
> **GDD**: design/gdd/conteudo-orientado-a-dados.md
> **Architecture Module**: Transversal — dados do catálogo (`assets/data/`), arte de runtime, áudio
> **Status**: Ready
> **Stories**: 9 stories (2026-11-16, QL-STORY: skipped — lean) — ver tabela abaixo
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Produz o conteúdo que os módulos consomem, em entregas por camada: (1) **catálogo `.tres` em `assets/data/`** — manifesto, os 13 tipos de Resource do ADR-0004 mais `CurseDef`, `BossPatternDef` e os `*Tuning` (Combat, Armas, Camera, Input, Visual, Bencaos, Maldicoes, Vinculo, Chefes, Audio…), migrando os valores de `data/integration/gameplay.json`; (2) **arte faltante** — fechar o lote 02 (inimigos do Limiar, `fila-de-geracao-lote-02.md`), Maldições, chefe, VFX, LUT por região e UI conforme `design/art/art-bible.md`; (3) **áudio** — os ganchos P0 do ADR-0016 (`assets/audio/` não existe ainda). Layer marcada Foundation porque o catálogo precisa existir antes do Core; a arte e o áudio acompanham as camadas de Apresentação.

## Dependências entre épicos

- conteudo (formato e validadores)
- pipeline-visual (formato de sprite/material)
- audio (SomDef)

## Estado atual do código

Existem `data/integration/gameplay.json` (dados da fatia, a migrar e depois aposentar), `assets/art/runtime/` com 5 conjuntos (`iniciado_lamina`, `anomalia_menor`, `eco_perdido`, `fenda_errante`, `elite_pecas` não versionado) e evidência do lote 02 em `production/qa/evidence/assets-lote-02-2026-11-14/` (não versionada). `assets/data/` e `assets/audio/` não existem.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0011: Pipeline visual](../../../docs/architecture/adr-0011-pipeline-visual.md) | Três famílias de shader, LUT global, passes de tela, material por entidade, relógio t_apres | HIGH |
| [ADR-0016: Áudio: ganchos e vozes](../../../docs/architecture/adr-0016-audio-ganchos-e-vozes.md) | Barramentos, pool de vozes, eventos→sons pela lista do passo (SomDef, AudioTuning) | MEDIUM |

## Cobertura de TR

Não é dono de TR-IDs; os TRs de dados (`TR-conteudo-*` e os `*-Tuning` de cada sistema) ficam nos épicos dos sistemas. Este épico entrega os arquivos que as stories desses TRs validam.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Manifesto do catálogo e `*Tuning` migrados do gameplay.json | Config/Data | Ready | ADR-0004 |
| 002 | Definições de armas e inimigos | Config/Data | Ready | ADR-0004 |
| 003 | Definições de bênçãos, regiões e câmaras/ondas | Config/Data | Ready | ADR-0004 |
| 004 | Dados de Pactos — CurseDef, chefe e tunings | Config/Data | Ready | ADR-0004 |
| 005 | CSV canônico, paridade e aposentar o gameplay.json | Integration | Ready | ADR-0004 |
| 006 | Fechar o lote 02 de arte | Visual/Feel | Ready | ADR-0011 |
| 007 | Arte das Maldições e do chefe | Visual/Feel | Ready | ADR-0011, ADR-0012 |
| 008 | LUT por região, VFX base e arte de UI | Visual/Feel | Ready | ADR-0011 |
| 009 | Áudio P0 — assets, SomDef e AudioTuning | Visual/Feel | Ready | ADR-0016, ADR-0004 |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every item of the scope above closed with its result recorded
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)
