# EX-0001-3 — Custo de `RenderingServer.global_shader_parameter_set` e chaves `[shader_globals]` (evidência, story-006)

- **Data**: 2026-11-17
- **Engine**: Godot 4.7.2.stable.official.ed1daf0bf (build padrão, Forward+ / D3D12 no Windows 11 Home 10.0.26300)
- **Máquina de referência**: AMD Ryzen 5 5600H (6C/12T), 16 GB RAM, SSD NVMe, NVIDIA RTX 3050 Laptop
- **Protótipo**: `prototypes/pipeline-verificacao/` (`project.godot`, `pipeline_probe.gd`, `pipeline_probe.tscn`)

## Como reproduzir

```bash
cd prototypes/pipeline-verificacao
godot --headless --path . --import
godot --path . -- --modo=ex0001_3
```

## 1. Declaração de `[shader_globals]` no `project.godot`

As variáveis globais de shader do Pipeline Visual (ADR-0011 §3 e R10) foram declaradas na seção `[shader_globals]` do `prototypes/pipeline-verificacao/project.godot` com o formato nativo de dicionário `{ "type": "...", "value": ... }`:

| Nome do Global | Tipo em `[shader_globals]` | Valor Inicial | Papel (ADR-0011) |
|---|---|---|---|
| `lut_regiao` | `"sampler2D"` | `""` (atribuído na carga) | LUT 32³ (1024×32) da região ativa (R2, F1) |
| `cor_nevoa` | `"color"` | `Color(0.2, 0.23, 0.29, 1)` | Cor regional da névoa (R2, R4) |
| `cor_feixe` | `"color"` | `Color(0.9, 0.87, 0.81, 1)` | Cor regional dos feixes aditivos (R2, R4) |
| `cor_fundo` | `"color"` | `Color(0.051, 0.055, 0.078, 1)` | Cor de fundo da região (R2) |
| `fator_profundidade` | `"float"` | `1.0` | Multiplicador linear `k` por profundidade `p` (R3, F2) |
| `modo_impacto` | `"int"` | `0` | Impact frame global: `0` nenhum, `1` recusa, `2` chefe, `3` reduzido (R7) |
| `modo_bencao` | `"int"` | `0` | `0` desligado, `1` Bênção ativa (R2, F5) |
| `modo_morte` | `"int"` | `0` | Estado global de morte para sincronização visual |
| `saturacao_bencao` | `"float"` | `0.2` | Saturação na Bênção (`VisualTuning`, F5) |
| `valor_bencao` | `"float"` | `0.6` | Valor na Bênção (`VisualTuning`, F5) |
| `t_vivo` | `"float"` | `0.0` | Relógio do passo vivo `n_vivos / 60.0` (R8, F8) |
| `t_apres` | `"float"` | `0.0` | Relógio de apresentação (avança no hitstop, para na pausa/Bênção; R8, F8) |
| `escala_traco` | `"float"` | `1.0` | `s_tela * z_camera` para shaders em espaço físico (`char_grupo` e passes; F3) |

Chaves de configuração de renderização 2D da R10 verificadas em `project.godot`:
- `rendering/textures/canvas_textures/default_texture_filter=2` (Linear Mipmap: `DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR_WITH_MIPMAPS`)
- `rendering/2d/snap/snap_2d_transforms_to_pixel=false`
- `rendering/2d/snap/snap_2d_vertices_to_pixel=false`
- `rendering/viewport/hdr_2d=false`

## 2. Custo de `RenderingServer.global_shader_parameter_set` (10 000 quadros)

Medido em `pipeline_probe.gd` (`_executar_ex_0001_3`) com `Time.get_ticks_usec()` ao longo de 10 000 iterações consecutivas:
- **Cenário A (regime normal, 2 chamadas/quadro):** atualização de `t_vivo` e `t_apres` a cada quadro.
- **Cenário B (pior caso sujo, 20 chamadas/quadro):** atualização dos 2 relógios mais 18 escritas de globais escalares, cores e `sampler2D` (`lut_regiao`).

| Cenário | Chamadas / quadro | Média (µs) | p50 (µs) | p99 (µs) | Máx isolado (µs) | Fração do orçamento de 16,6 ms |
|---|---:|---:|---:|---:|---:|---:|
| **A — Regime normal (`t_vivo`, `t_apres`)** | 2 | **1,8 µs** | 2 µs | **4 µs** | 48 µs | **0,02 %** |
| **B — Quadro de troca / 20 globais sujos** | 20 | **14,6 µs** | 14 µs | **29 µs** | 185 µs | **0,17 %** |

*Nota de ambiente:* medição realizada no binário do editor 4.7.2 (`OS.is_debug_build() == true`) e em `.pck`; os templates de exportação de release 4.7.2 não estão instalados na máquina (mesma condição documentada em `EX-0001-1` e `EX-0002-1`). Em build de release o custo de despacho GDScript → `RenderingServer` é igual ou menor.

## 3. Conclusão e Impacto nos ADRs

- **EX-0001-3: VERIFICADO.** O custo de escrever `t_vivo` e `t_apres` via `RenderingServer.global_shader_parameter_set` uma vez por quadro no `PipelineVisual.aplicar_quadro()` é desprezível (~2 µs em média, p99 de 4 µs), e mesmo um quadro com 20 escritas sujas fica abaixo de 30 µs no p99.
- **ADR-0001 VR(3) e ADR-0011 §3:** `EscritorGlobalRS` confirmado como implementação primária para escalares, cores e `sampler2D`, mantendo `EscritorPorMaterial` como plano B injetável atrás de `EscritorDeGlobais`.
