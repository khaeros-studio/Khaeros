# Epic: Experimentos de engine

> **Layer**: Foundation
> **GDD**: docs/architecture/architecture.md
> **Architecture Module**: Transversal (itens NOT SOURCEABLE / NEEDS VERIFICATION dos ADRs)
> **Status**: Ready
> **Stories**: 9 stories (story-001 a story-009 nesta pasta)
> **Engine Risk**: HIGH
> **Created**: 2026-11-16 (`/create-epics`, review lean: PR-EPIC skipped — lean)

## Overview

Fecha, no Godot 4.7.2 (Windows 11, editor e build exportado), cada ponto que os ADRs aceitos marcaram como NOT SOURCEABLE ou NEEDS VERIFICATION. Princípio 5 da arquitetura: nada disso vira decisão firme antes do experimento. Cada experimento retém evidência em `production/qa/evidence/` e devolve ao ADR um resultado (confirmado / usar fallback já escrito no ADR). Não implementa regra de jogo.

## Dependências entre épicos

- Nenhuma (pode começar já)

## Estado atual do código

Nada a reaproveitar diretamente. `src/app/main.gd` já usa `_physics_process` + `_process` e `scenes/art/anomalia_review.gd` existe para revisão de arte; ambos servem de cenário rápido para EX-0001-2/6, não como evidência.

A fatia de 2026-11-14 foi escrita antes do aceite dos ADRs (2026-11-16); nada dela entra sem conferência contra os ADRs governantes.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| [ADR-0001: Orquestrador do passo e estados de jogo](../../../docs/architecture/adr-0001-orquestrador-do-passo.md) | Nó raiz sem Autoload; estado de jogo próprio (sem SceneTree.paused); passo de 60 Hz em ordem fixa; t_vivo/t_apres | HIGH |
| [ADR-0002: Canal de eventos](../../../docs/architecture/adr-0002-canal-de-eventos.md) | Lista de EventoDoPasso por passo mais chamadas síncronas; Apresentação lê a lista | HIGH |
| [ADR-0009: Atributos e modificadores](../../../docs/architecture/adr-0009-atributos-e-modificadores.md) | Portador com cache reconstruído; arredondamento determinístico próprio (sem round()) | LOW |
| [ADR-0010: Resolução do combate no passo](../../../docs/architecture/adr-0010-resolucao-do-combate-no-passo.md) | Ordem dos itens do passo, dano, empurrão, varredura de mortes, facções e ferir_maldicao/ferir_acuada/subjugar | HIGH |
| [ADR-0011: Pipeline visual](../../../docs/architecture/adr-0011-pipeline-visual.md) | Três famílias de shader, LUT global, passes de tela, material por entidade, relógio t_apres | HIGH |
| [ADR-0012: UI e HUD](../../../docs/architecture/adr-0012-ui-e-hud.md) | Control em CanvasLayer, foco duplo, escala 85–150%, Bloco do Pacto e tela de consentimento | HIGH |
| [ADR-0013: Persistência do MVP](../../../docs/architecture/adr-0013-persistencia-do-mvp.md) | ConfigFile/FileAccess em user://, gravação atômica com .bak, perfil.cfg com [vinculo], telemetria .jsonl | MEDIUM |
| [ADR-0016: Áudio: ganchos e vozes](../../../docs/architecture/adr-0016-audio-ganchos-e-vozes.md) | Barramentos, pool de vozes, eventos→sons pela lista do passo (SomDef, AudioTuning) | MEDIUM |

## Experimentos (escopo)

| ID | Origem | O que verificar | Bloqueia |
|----|--------|-----------------|----------|
| EX-0001-1 | ADR-0001 VR(1) | `physics_ticks_per_second` e `max_physics_steps_per_frame`: padrões e efeito com quadro atrasado (valores a fixar no `project.godot`) | orquestrador-do-passo |
| EX-0001-2 | ADR-0001 VR(2) | Ordem entre `_physics_process` e `_process` no mesmo quadro | orquestrador-do-passo |
| EX-0001-3 | ADR-0001 VR(3) | Custo de `RenderingServer.global_shader_parameter_set` a cada quadro | pipeline-visual |
| EX-0001-4 | ADR-0001 VR(4) | Sem `SceneTree.paused`, nenhum nó de apresentação roda por engano (Tweens, AnimationPlayer, partículas, sons) | orquestrador-do-passo |
| EX-0001-5 | ADR-0001 VR(5) | Perda de foco da janela até o `Main` (notificação, `pause_on_focus_loss`) — TR-input-008 | input |
| EX-0001-6 | ADR-0001 VR(6) | Primeiro quadro após arrastar a janela no Windows; `dt_max_apres` 0,1 s cobre | orquestrador-do-passo |
| EX-0002-1..3 | ADR-0002 VR | Custo de um `RefCounted` por evento (dezenas/passo); `Array[EventoDoPasso]` com subclasses `@abstract`; ordem de sinais e `CONNECT_DEFERRED` na Apresentação | orquestrador-do-passo |
| EX-0009-1 | ADR-0009 VR(1) | `float` do GDScript é IEEE-754 64 bits no build padrão (testes AC-03/AC-05) | modificadores |
| EX-0010-1 | ADR-0010 AC-92 | `RenderingServer.frame_post_draw` como fim de quadro para medir latência toque→golpe ≤ 50 ms (TR-combate-nucleo-018) | combate-nucleo (story AC-92) |
| EX-0011-E1 | ADR-0011 | Draw calls 2D na cena de estresse F10 (Performance × PIX/RenderDoc) | pipeline-visual (antes do aceite firme) |
| EX-0011-E2 | ADR-0011 | `global uniform` float/int/sampler2D em `canvas_item` + Shader Baker; hints; LUT identidade | pipeline-visual |
| EX-0011-E3 | ADR-0011 | Relógios: `TIME` parado, `speed_scale` 0 em GPU/CPU particles, avanço manual de `AnimatedSprite2D` | pipeline-visual, feedback |
| EX-0011-E4 | ADR-0011 | SDF do telégrafo: contorno 4 px em 1080p/1440p/4K, custo com 24 | pipeline-visual |
| EX-0011-E5 | ADR-0011 | `CanvasGroup`: contorno, `fit_margin`, `TEXTURE_PIXEL_SIZE`, custo | pipeline-visual |
| EX-0011-E6 | ADR-0011 | Fio de vínculo: `Line2D` texturizada × quad SDF | pipeline-visual |
| EX-0011-E7 | ADR-0011 | Material por entidade × compartilhado (9/20/40); `instance uniform` em `canvas_item` | pipeline-visual |
| EX-0012-E1 | ADR-0012 | `offset_transform_*` em `get_global_transform_with_canvas()` e no retângulo de acerto | hud, tela-de-bencao-e-carta |
| EX-0012-E2 | ADR-0012 | Esvaziar ações nativas `ui_*` sem quebrar `LineEdit` (`ui_text_*`) — AC-36 do Input | input, hud |
| EX-0012-E3 | ADR-0012 | Clique que devolve o foco no Windows chega após `NOTIFICATION_APPLICATION_FOCUS_IN`? (hardware real) | input, hud |
| EX-0012-E4 | ADR-0012 | Nome da propriedade de desativação recursiva (4.5) — não bloqueante | — |
| EX-0012-E5 | ADR-0012 | Propriedades de AccessKit além de `accessibility_live` — não bloqueante (AccessKit fora do MVP, recomendação (a)) | — |
| EX-0012-E6 | ADR-0012 | Plurais e contexto em CSV (4.6) | hud (textos) |
| EX-0012-CB | ADR-0012 / TR-rng-012 | `PortaDaAreaDeTransferencia` (clipboard) para copiar a seed | hud |
| EX-0013-P1 | ADR-0013 | `store_line` + `flush` (10 000 linhas, 300 B/2 KB), média/p99, morte do processo, erro (`bool`, `get_error()`); pior passo com 5 linhas ≤ 3 ms | persistencia, telemetria |
| EX-0013-P2 | ADR-0013 | `DirAccess.rename` sobre destino existente/aberto; queda em cada passo da sequência `.old` | persistencia |
| EX-0013-P3 | ADR-0013 | `ConfigFile.parse`/`encode_to_text` com int > 2³¹, `StringName`, `Array`, lixo binário | persistencia |
| EX-0013-P4 | ADR-0013 | `JSON.stringify` com int, float, null, acentos | telemetria |
| EX-0013-P5 | ADR-0013 | `Time` em UTC com `Z`; relógio monotônico ms/µs | telemetria |
| EX-0013-P6 | ADR-0013 | `OS.shell_open` da pasta globalizada | persistencia |
| EX-0013-P7 | ADR-0013 | Interceptar o fechamento da janela (build exportado), gravar o perfil, `PERFIL_SAIR_SEM_SALVAR` e "Tentar de novo" | persistencia |
| EX-0016-A | ADR-0016 | `get_bus_index` = -1; `pitch_scale`; `stream_paused`; `volume_db`; `linear_to_db()`; `default_bus_layout.tres`; loop do stream no import | audio |
| EX-0004-NV | ADR-0004 / architecture.md | `HashingContext`, importador CSV `keep` (4.7.2), `ResourceLoader` síncrono × threaded | conteudo |
| EX-0007-NV | architecture.md | Interpolação de física 2D, `reset_physics_interpolation()`, pillarbox em runtime | cena-e-camera |

Nota: os itens EX-0004-NV e EX-0007-NV não estavam no pedido do usuário, mas estão marcados NEEDS VERIFICATION/NOT SOURCEABLE em `architecture.md`; incluídos para que nenhum fique sem dono.

## Cobertura de TR

Este épico não é dono de TR-IDs (cada TR pertence ao épico do seu sistema). Ele desbloqueia as stories que dependem dos experimentos acima.

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every item of the scope above closed with its result recorded
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
- Stories embed the control manifest version (`docs/architecture/control-manifest.md` was absent when this epic was written)
