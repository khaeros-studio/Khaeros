# Epic: RNG com seed

> **Layer**: Foundation
> **GDD**: design/gdd/rng-com-seed.md
> **Architecture Module**: RNG (seed da run, fluxos por finalidade)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories rng`
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Gerador mulberry32 próprio em int64, seed da run e estado dos fluxos por finalidade (9 com `pactos`), derivados da lista e impressão do catálogo; lint de CI contra `randf`/`shuffle`. Seed exibível e copiável (texto pronto para a UI).

## Dependências entre épicos

- conteudo

## Estado atual do código

`game_session.gd` tem um RNG próprio só para espera de IA: **substituir** pelo módulo RNG; nada a reaproveitar.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0005: RNG determinístico](../../../docs/architecture/adr-0005-rng-deterministico.md) | mulberry32 próprio, fluxos por finalidade (9 com pactos), lint de CI contra randf/shuffle | LOW |
| [ADR-0012: UI e HUD](../../../docs/architecture/adr-0012-ui-e-hud.md) | Control em CanvasLayer, foco duplo, escala 85–150%, Bloco do Pacto e tela de consentimento | HIGH |
| [ADR-0013: Persistência do MVP](../../../docs/architecture/adr-0013-persistencia-do-mvp.md) | ConfigFile/FileAccess em user://, gravação atômica com .bak, perfil.cfg com [vinculo], telemetria .jsonl | MEDIUM |
| [ADR-0015: Ciclo da run e composição](../../../docs/architecture/adr-0015-ciclo-da-run-e-composicao.md) | Composição da run, câmaras→portas→bênção→chefe, encontro de pacto, quando gravar o perfil, ContaFragmentos | LOW |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **15 / 15** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-rng-001 | Fonte única; APIs aleatórias da engine proibidas no código de jogo, com lint de CI | ADR-0005 ✅ |
| TR-rng-002 | Seed u32 sorteada ao criar a run; --seed só em debug; fixa durante a run | ADR-0005 ✅ |
| TR-rng-003 | Fluxos derivados por finalidade, região e profundidade; lista fechada de finalidades | ADR-0005 ✅ |
| TR-rng-004 | Sorteios iteram na ordem do manifesto, nunca Dictionary, hash ou árvore | ADR-0005 ✅, ADR-0004 ✅ |
| TR-rng-005 | Consumo fixo nas finalidades de estrutura, independente do combate | ADR-0005 ✅ |
| TR-rng-006 | Operações com consumo definido; erros não consomem e vão ao relator | ADR-0005 ✅ |
| TR-rng-007 | Gerador próprio mulberry32, estável entre versões e SO, com paridade com o cânone | ADR-0005 ✅ |
| TR-rng-008 | Contrato de reprodução com seis elementos, incluindo a impressão do catálogo | ADR-0005 ✅, ADR-0004 ✅ |
| TR-rng-009 | Fonte de fluxos injetada, sem singleton global | ADR-0005 ✅ |
| TR-rng-010 | Máscara u32 na fronteira e na leitura de save; save no meio da run fora do MVP | ADR-0005 ✅, ADR-0013 ✅ |
| TR-rng-011 | RNG cosmético só em src/presentation/, sem acesso à fonte de fluxos | ADR-0005 ✅ |
| TR-rng-012 | Texto da seed na pausa, morte, vitória e debug, com copiar e campo de seed no debug | ADR-0005 ✅, ADR-0012 ✅ |
| TR-rng-013 | Finalidade 9 pactos com chave (pactos, região, 0) e consumo fixo de 4 reais, só em runs de Pactos | ADR-0005 ✅, ADR-0015 ✅ |
| TR-rng-014 | Com Pactos a seed nasce em dupla_confirmada; telas anteriores não pedem fluxo | ADR-0005 ✅, ADR-0015 ✅ |
| TR-rng-015 | Estado inicial ampliado com dupla e perfil de vínculo lido do perfil salvo | ADR-0005 ✅, ADR-0013 ✅ |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/rng-com-seed.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)
