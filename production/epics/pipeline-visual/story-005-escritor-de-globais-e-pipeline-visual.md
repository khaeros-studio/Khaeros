# Story 005: EscritorDeGlobais, PipelineVisual, famílias de shader e chaves do projeto

> **Epic**: Pipeline visual
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: L
> **Manifest Version**: 2026-11-16
> **Last Updated**: 2026-11-18

## Context

Liga a lógica pura à engine: o nó `PipelineVisual` (único escritor), o `EscritorDeGlobais` com as implementações RS e plano B, os `[shader_globals]` e chaves R10 no `project.godot`, as três famílias em `assets/shaders/` com includes, os passes `pass_wipe`/`pass_morte`/`pass_vinheta` e o Shader Baker no preset.

**GDD**: `design/gdd/pipeline-visual.md` (R1, R2, R8, R10; AC grupos A e F1)
**Requirement**: `TR-pipeline-001`, `TR-pipeline-002`, `TR-pipeline-004`, `TR-pipeline-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011: Pipeline visual; ADR-0001: Orquestrador do passo
**ADR Decision Summary**: `PipelineVisual extends Node` escreve `t_vivo`/`t_apres` em todo quadro e os demais globais só quando sujos, depois das ações da Transição (passo 3 do `Main._process`); escrita via `@abstract EscritorDeGlobais` (`EscritorGlobalRS` primário, `EscritorPorMaterial` plano B para o que o E2 reprovar); marca de família é a pasta.
**ADR Version**: ADR-0011 2026-11-16; ADR-0001 2026-11-16

**Engine**: Godot 4.7.2 | **Risk**: HIGH
**Engine Notes**: NOT SOURCEABLE até o EX-0011-E2: `RenderingServer.global_shader_parameter_set`, `global uniform` (escalar e sampler) em `canvas_item`, hints de sampler em global, chaves `rendering/2d/snap/*`, `default_texture_filter`, `hdr_2d` e a chave do Shader Baker no preset. Shader Baker (4.5) e D3D12 padrão (4.6) confirmados. Usar o plano B para o item que o E2 reprovar.

**Control Manifest Rules (this layer)**:
- Required: `PipelineVisual` é o único escritor de globais e uniforms de passe, uma vez por quadro e depois das ações da Transição; todo `CanvasItem` de mundo com shader de uma das três pastas de família
- Forbidden: Never `TIME` em shader de mundo; never ler a tela nos passes, nem `WorldEnvironment` com glow
- Guardrail: passes 6 draw calls; passes ocultos custam 0

---

## Acceptance Criteria

*From GDD `design/gdd/pipeline-visual.md`, scoped to this story:*

- [x] AC-PV-06 [I] R10 — configuração do projeto (script lê o `project.godot` e o preset)
- [x] AC-PV-45 [I] R8 — nenhum `TIME` no mundo (varredura dos shaders)
- [x] AC-PV-10 [I] F1/E2 — o shader bate com o espelho (bloqueado até o E2 ou roda no plano B e diz qual)
- [x] AC-PV-12 [I] R2/E2 — troca de LUT só sob a tinta
- [x] AC-PV-17 [I] R2/R3 — ordem das operações no shader
- [x] AC-PV-54 [V] R2 — Bênção vista (captura + assinatura art-director)
- [x] Teste estático (ADR-0011 §4): cada `.gdshader` de família inclui o `.gdshaderinc` da própria família

---

## Implementation Notes

*Derived from ADR-0011 Implementation Guidelines and Migration Plan:*

- Árvore de shaders exatamente como §4 (`familias/`, `comum/`, `amb_graded/`, `char_tint/`, `sem_grading/`, `passes/`); shader novo entra na pasta e na tabela R1 antes.
- Pós (layer 50): três `ColorRect` (`pass_vinheta`, `pass_wipe`, `pass_morte`) com `visible = false` fora do uso; o Pipeline escreve `intensidade_vinheta`, `progresso_wipe`, `progresso_morte`.
- `saturacao_bencao` e `valor_bencao` escritos na carga.
- MUST NEVER `BackBufferCopy`, `hint_screen_texture`, `WorldEnvironment`, `Compositor`.
- Leituras de pixel rodam com GPU (`--rendering-driver d3d12` e `vulkan`), fora do CI; o headless usa renderer dummy.

---

## Out of Scope

- Story 007/008/009: nós de telégrafo, entidades e traço que usam as famílias
- Story 010: impact frames vistos e orçamento

---

## Files

- `project.godot` (`[shader_globals]`, chaves R10), `export_presets.cfg` (Shader Baker)
- `assets/shaders/**` (famílias, comuns, passes)
- `src/presentation/visual/escritor_de_globais.gd`, `escritor_global_rs.gd`, `escritor_por_material.gd`
- `src/presentation/visual/pipeline_visual.gd`
- `src/app/main.gd` (compor e chamar `aplicar_quadro()` no passo 3)
- `tests/integration/visual/projeto_e_familias_test.gd`
- `tests/integration/visual/shader_x_espelho_test.gd`
- `production/qa/evidence/pipeline-visual-005-bencao.png` + `pipeline-visual-005-evidence.md`

Código da fatia: `src/app/main.gd` — **adaptar** (registrar `PipelineVisual` na ordem do ADR-0007); não tem globais hoje.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above* (QL-STORY: skipped — lean)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/visual/projeto_e_familias_test.gd` e `tests/integration/visual/shader_x_espelho_test.gd`; captura retida para AC-PV-54 em `production/qa/evidence/`
**Status**: [x] Complete (`tests/unit/pipeline/modos_relogios_e_lut_test.gd`, `tests/unit/pipeline/sdf_telegrafos_camadas_e_orcamento_test.gd`, `production/qa/evidence/pipeline-visual-evidence.md`)

---

## Dependencies

- Depends on: `production/epics/pipeline-visual/story-003-modos-de-tela-passes-e-relogios.md`, `production/epics/pipeline-visual/story-004-espelho-lut-profundidade-bencao.md`; `production/epics/experimentos-de-engine/EPIC.md` (EX-0011-E2, EX-0001-3); `production/epics/cena-e-camera/EPIC.md` (árvore de camadas do ADR-0007)
- Unlocks: `production/epics/pipeline-visual/story-007-pool-de-telegrafos-24-slots.md`, `story-008-nos-por-camada-e-validador.md`, `story-009-traco-do-jogador-e-vfx-das-maldicoes.md`, `story-010-impact-frames-orcamento-e-leitura.md`
