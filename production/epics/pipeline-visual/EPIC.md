# Epic: Pipeline visual

> **Layer**: Presentation
> **GDD**: design/gdd/pipeline-visual.md
> **Architecture Module**: Pipeline visual (shaders, LUT, shader_globals, passes, t_apres)
> **Status**: Complete
> **Stories**: 10 / 10 Complete (`story-001` a `story-010`)
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Três famílias de shader, LUT por região como global, `shader_globals`, passes de tela, relógios `t_apres`, material por entidade, contorno secundário e VFX das Maldições. Desvio do índice: está em Apresentação (o índice o põe em Core). E1–E3 antes de qualquer story firme; E4–E7 podem fechar depois com o fallback do ADR.

## Dependências entre épicos

- cena-e-camera
- orquestrador-do-passo
- telegrafos
- experimentos-de-engine (EX-0011-E1..E7, EX-0001-3)

## Estado atual do código

`src/presentation/world_view.gd` (414 linhas, desenho imediato em `_draw`) **substituir** por nós com `ShaderMaterial` e y-sort (ADR-0011). Reaproveitar o carregamento de atlas (`_ensure_atlases`), a montagem de partes da elite (`_draw_elite_part`) e `tools/art/validate_runtime_atlases.gd` como base do pipeline de sprites.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0001: Orquestrador do passo e estados de jogo](../../../docs/architecture/adr-0001-orquestrador-do-passo.md) | Nó raiz sem Autoload; estado de jogo próprio (sem SceneTree.paused); passo de 60 Hz em ordem fixa; t_vivo/t_apres | HIGH |
| [ADR-0004: Catálogo de dados](../../../docs/architecture/adr-0004-catalogo-de-dados.md) | Catálogo .tres com manifesto explícito, validadores V1–V11, impressão SHA-256, cópia por duplicate_deep | MEDIUM |
| [ADR-0011: Pipeline visual](../../../docs/architecture/adr-0011-pipeline-visual.md) | Três famílias de shader, LUT global, passes de tela, material por entidade, relógio t_apres | HIGH |
| [ADR-0014: Telégrafos: geometria e teto](../../../docs/architecture/adr-0014-telegrafos-geometria-e-teto.md) | Geometria de acerto dos telégrafos, teto de 24, alvo travado | LOW |

## GDD Requirements

Requisitos cobertos por ADR Accepted: **16 / 16** · Untraced Requirements: None

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-pipeline-001 | Três famílias de material por papel, lista fechada | ADR-0011 ✅ |
| TR-pipeline-002 | Grading regional por LUT global, com plano B | ADR-0011 ✅ |
| TR-pipeline-003 | Escurecimento por profundidade calculado na CPU, em linear | ADR-0011 ✅ |
| TR-pipeline-004 | t_vivo e t_apres globais escritos pelo orquestrador; sem TIME no mundo; zero no meio do wipe | ADR-0001 ✅, ADR-0011 ✅ |
| TR-pipeline-005 | Telégrafo em duas passadas, quad e malha de borda, 24 slots | ADR-0011 ✅, ADR-0014 ✅ |
| TR-pipeline-006 | Traço do jogador em CanvasGroup e imagens residuais | ADR-0011 ✅ |
| TR-pipeline-007 | Impact frame global, limitador F6, wipe e morte, modos de tela por prioridade | ADR-0011 ✅ |
| TR-pipeline-008 | Teto de 500 draw calls por grupo, overdraw, partículas e luz, medidos por captura | ADR-0011 ✅ |
| TR-pipeline-009 | Memória de textura 512 MiB com alerta em 448; tetos somam 504 MiB | ADR-0011 ✅ |
| TR-pipeline-010 | Chaves de project.godot, shader_globals e Shader Baker no preset de exportação | ADR-0011 ✅ |
| TR-pipeline-011 | Emissores e animações do relógio vivo congelam no hitstop, com fallback | ADR-0011 ✅ |
| TR-pipeline-012 | Acessibilidade de render: Reduzir flashes e Redução de movimento | ADR-0011 ✅ |
| TR-pipeline-013 | Valores de tuning vêm do catálogo validado (VisualTuning); estado e opções injetados | ADR-0004 ✅, ADR-0011 ✅ |
| TR-pipeline-014 | Contorno tracejado secundário com raio_secundario_px do BossPatternDef, z 5, some no disparo | ADR-0011 ✅, ADR-0014 ✅ |
| TR-pipeline-015 | Fio de vínculo e marca do Virote como traco_sdf em z -5 com estados pela distância | ADR-0011 ✅ |
| TR-pipeline-016 | Validador acusa nó tel_sdf com dono da facção do jogador | ADR-0011 ✅ |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/pipeline-visual.md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)
