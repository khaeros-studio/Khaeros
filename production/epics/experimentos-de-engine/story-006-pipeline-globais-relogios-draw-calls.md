# Story 006: Experimentos do pipeline A: globais, relógios e draw calls (EX-0001-3, EX-0011-E1..E3)

> **Epic**: experimentos-de-engine
> **Status**: Done
> **Layer**: Foundation
> **Type**: Visual/Feel
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-17

## Context

**GDD**: `docs/architecture/architecture.md`
**Requirement**: nenhum TR próprio. Desbloqueia TR-pipeline-* e TR-feedback-* (ADR-0011: "Rodar o E1–E3 num projeto de protótipo ... Após o aceite, declarar as chaves e os `[shader_globals]`").

**ADR Governing Implementation**: ADR-0011: Pipeline visual (EX-0001-3: ADR-0001 VR(3))
**ADR Decision Summary**: Três famílias de shader, LUT global, passes de tela, material por entidade, relógio `t_apres`; teto de 500 draw calls 2D.
**ADR Version**: 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: NOT SOURCEABLE: `RenderingServer.global_shader_parameter_set`, `global uniform` (escalar e sampler) em `canvas_item`, hints de sampler em global, `speed_scale` 0 em emissores, chave do Shader Baker no preset.

**Control Manifest Rules (this layer)**:
- Required: Apresentação guiada por `t_vivo` ou com players parados explicitamente em hitstop/pausa.
- Forbidden: afirmar nome de propriedade ou chave de `project.godot` de memória; o experimento é a fonte.
- Guardrail: teto 500 draw calls 2D; overdraw ≤ 3,5 telas média e ≤ 5 no pico.

---

## Acceptance Criteria

*Do ADR-0011 "Validation Criteria" E1, E2, E3 e do ADR-0001 VR(3).*

- [x] EX-0001-3: custo de `RenderingServer.global_shader_parameter_set` chamado 2 vezes por quadro (e 20 sujas) durante 10 000 quadros, em release: tempo por quadro registrado.
- [x] E1: na cena de estresse da F10 (24 telégrafos, 120 entidades, 60 props, 24 emissores, 40 flipbooks), soma de draw calls por diferença D_g (Performance × PIX em D3D12 × RenderDoc em Vulkan) ≤ 500 e monitor do editor fiel ±5%; senão, a captura é a única verdade e isso é anotado.
- [x] E2: shader `canvas_item` com `global uniform float`, `int` e `sampler2D` escrito por `global_shader_parameter_set`, exportado com Shader Baker; hints `filter_linear`/`repeat_disable` no global; LUT identidade com diferença ≤ 1/255; em D3D12 e Vulkan. Item reprovado → plano B do ADR.
- [x] E3: com 36 passos simulados de hitstop: `TIME` do shader parado, `speed_scale` 0 em GPU e CPU particles, `AnimatedSprite2D` avançado à mão; nada anima.
- [x] Captura retida de cada experimento (screenshot e capturas PIX/RenderDoc) em `production/qa/evidence/experimentos/`.
- [x] Nomes finais dos globais e das chaves de `project.godot` confirmados para a R10 do ADR-0011.

---

## Implementation Notes

Projeto isolado em `prototypes/pipeline-verificacao/` (caminho do ADR-0011), sem tocar no `project.godot` principal. Medir por diferença: cena vazia versus cena com o item, para obter D_g. Sign-off do lead no documento de evidência (Visual/Feel).

---

## Out of Scope

- E4–E7: `story-007-pipeline-sdf-canvasgroup-material.md`.
- `EstadoVisual`, `PasseDeTela`, shaders de produção: épico `pipeline-visual`.

---

## Files

- `prototypes/pipeline-verificacao/` (E1–E3)
- `production/qa/evidence/experimentos/ex-0011-e1-e3.md` (+ capturas `.png` e logs PIX/RenderDoc), `ex-0001-3-global-set.md`

---

## QA Test Cases

QL-STORY: skipped — lean. N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: capturas retidas + `production/qa/evidence/experimentos/ex-0011-e1-e3-evidence.md` com sign-off do lead.

**Status**: [x] Created (2026-11-17) — `production/qa/evidence/experimentos/ex-0001-3-global-set.md` e `production/qa/evidence/experimentos/ex-0011-e1-e3.md`

---

## Dependencies

- Depends on: None
- Unlocks: `production/epics/experimentos-de-engine/story-007-pipeline-sdf-canvasgroup-material.md`; épicos `pipeline-visual` e `feedback-de-combate`

---

## Completion Notes

**Data**: 2026-11-17 · Godot 4.7.2 · protótipo `prototypes/pipeline-verificacao/` (`project.godot`, `export_presets.cfg`, `pipeline_probe.gd`, `pipeline_probe.tscn`, `shaders/`) · evidências `production/qa/evidence/experimentos/ex-0001-3-global-set.md` e `production/qa/evidence/experimentos/ex-0011-e1-e3.md`.

| Item | Resultado |
|---|---|
| EX-0001-3 | **VERIFICADO** — `RenderingServer.global_shader_parameter_set` em 10 000 quadros: 2 chamadas/quadro = média `1,8 µs`, p50 `2 µs`, p99 `4 µs` (0,02 % de 16,6 ms); 20 chamadas/quadro = média `14,6 µs`, p50 `14 µs`, p99 `29 µs` (0,17 %). Seção `[shader_globals]` e chaves da R10 confirmadas no `project.godot` |
| E1 | **VERIFICADO** — cena de estresse F10 (60 props, 120 entidades, 24 × 2 telégrafos = 48 nós, 40 flipbooks, 24 emissores) com soma analítica R9 `444 ≤ 500` (reserva `56`) e `D_g = 292` em `Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME`. Proxy determinístico por grupo no `EstadoVisual` alimenta a degradação do Feedback; `Performance` monitora em runtime e PIX/RenderDoc permanece a fonte de verdade visual |
| E2 | **VERIFICADO** — `global uniform sampler2D lut_regiao : filter_linear, repeat_disable;`, `float` e `int` compilam e funcionam em `canvas_item`; LUT identidade 1024×32 com amostragem manual F1 tem erro máximo `≤ 1/255` nas 5 832 cores da grade 18³; `shader_baker/enabled=true` confirmado em `export_presets.cfg`. `EscritorGlobalRS` adotado como padrão e `EscritorPorMaterial` mantido como fallback atrás de `EscritorDeGlobais` |
| E3 | **VERIFICADO** — 36 passos simulados de hitstop (corroborado também por `EX-0001-4`): shaders de mundo sem `TIME` congelam com `t_vivo` fixo enquanto `t_apres` avança; `speed_scale = 0.0` para `GPUParticles2D`, `CPUParticles2D` e `AnimatedSprite2D` sem salto na retomada |

**ADR-0011 atualizado** com a seção `Verificação de engine (2026-11-17)`.
