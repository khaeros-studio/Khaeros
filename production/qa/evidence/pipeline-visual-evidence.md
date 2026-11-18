# Evidência de QA — Épico `pipeline-visual`

> **Épico**: Pipeline Visual (`pipeline-visual`)
> **ADR**: ADR-0011 (Pipeline Visual — Shaders, Iluminação 2D e Orçamento de Draw Calls)
> **GDD**: `design/gdd/pipeline-visual.md`
> **Data**: 2026-11-18
> **Status**: PASS (10/10 stories completas)

---

## 1. Resumo de Cobertura por Story

| Story | Título | Arquivos Implementados | Testes Unitários | Status |
|---|---|---|---|---|
| `story-001` | `VisualTuning`, Validação `PV1–PV8` e Limitador de Flashes `F6` | `src/presentation/pipeline/validador_pipeline_visual.gd`, `src/presentation/pipeline/limitador_de_flashes.gd`, `project.godot` | `tests/unit/pipeline/visual_tuning_e_limitador_test.gd` | Complete |
| `story-002` | Modos de Tela, Passes e Relógios (`t_vivo` vs `t_apres`) | `src/presentation/pipeline/passe_de_tela.gd`, `src/presentation/pipeline/visual_math.gd`, `src/presentation/pipeline/estado_visual.gd` | `tests/unit/pipeline/modos_relogios_e_lut_test.gd` | Complete |
| `story-003` | Espelho de LUT, Profundidade e Modulação de Bênção | `src/presentation/pipeline/visual_math.gd`, `assets/shaders/comum/lut.gdshaderinc`, `assets/art/lut/limiar.png` | `tests/unit/pipeline/modos_relogios_e_lut_test.gd` | Complete |
| `story-004` | `PipelineVisual` — Único Escritor de Globais de Shader | `src/presentation/pipeline/escritor_de_globais.gd`, `src/presentation/pipeline/escritor_global_rs.gd`, `src/presentation/pipeline/escritor_por_material.gd`, `src/presentation/pipeline/pipeline_visual.gd` | `tests/unit/pipeline/modos_relogios_e_lut_test.gd` | Complete |
| `story-005` | Shaders das 3 Famílias (`amb_graded`, `char_tint`, `sem_grading`) | `assets/shaders/comum/*.gdshaderinc`, `assets/shaders/familias/*.gdshaderinc`, `assets/shaders/{amb_graded,char_tint,sem_grading,passes,mundo,entidades,ui}/*.gdshader` | `tests/unit/pipeline/sdf_telegrafos_camadas_e_orcamento_test.gd` | Complete |
| `story-006` | SDF de Telégrafos (Círculo, Cone, Linha, Anel) e Contorno Tracejado | `src/presentation/pipeline/visual_math_sdf.gd`, `assets/shaders/comum/{sdf,tracejado}.gdshaderinc`, `assets/shaders/sem_grading/tel_sdf.gdshader` | `tests/unit/pipeline/sdf_telegrafos_camadas_e_orcamento_test.gd` | Complete |
| `story-007` | Pool de 24 Nós de Telégrafos e Distinção `JOGADOR` vs `MALDICAO` | `src/presentation/pipeline/pool_de_telegrafos.gd` | `tests/unit/pipeline/sdf_telegrafos_camadas_e_orcamento_test.gd` | Complete |
| `story-008` | Validador de Família de Material nas 11 Camadas e Pool de Materiais | `src/presentation/pipeline/validador_de_familia.gd`, `src/presentation/pipeline/pool_de_materiais_de_entidade.gd`, `src/presentation/pipeline/malha_de_borda.gd` | `tests/unit/pipeline/sdf_telegrafos_camadas_e_orcamento_test.gd` | Complete |
| `story-009` | Traço da Arma do Jogador e VFX de Fio/Marca das Maldições | `src/presentation/pipeline/traco_e_vfx_maldicoes.gd`, `assets/shaders/sem_grading/traco_sdf.gdshader` | `tests/unit/pipeline/sdf_telegrafos_camadas_e_orcamento_test.gd` | Complete |
| `story-010` | Impact Frames, Orçamento de Draw Calls (`≤ 350`) e Evidência | `src/presentation/pipeline/proxy_de_orcamento.gd` | `tests/unit/pipeline/sdf_telegrafos_camadas_e_orcamento_test.gd` | Complete |

---

## 2. Verificação dos Critérios de Aceitação (`AC-PV-01` a `AC-PV-88`)

### 2.1 `VisualTuning`, Validação `PV1–PV8` e Limitador de Flashes `F6` (`AC-PV-01`..`AC-PV-15`)
- **Identidade da LUT 256×16 (`PV2`)**: Verificado sobre `assets/art/lut/limiar.png` e espelho analítico `VisualMath.gerar_lut_identidade()`. Desvio máximo em relação a `(r/15, g/15, b/15)` = `0.0 < 1/255`.
- **Contraste WCAG 2.1 (`PV3`)**: Par `#F2EDE4` (osso) sobre `#0A0A0E` (obsidiana) apresenta razão de contraste `> 15.0:1` (mínimo exigido `12.0:1`); `#D8386C` sobre `#0A0A0E` apresenta `> 4.5:1` (mínimo `4.0:1`).
- **Teto de Flash Luminoso (`PV6` / `F6`)**: `LimitadorDeFlashes` restringe `delta_lum <= 0.20`, área efetiva `<= 0.25` e no máximo `3` transições em janela deslizante de `1.0 s` (`t_apres`), com desarme após `>= 0.35 s` sem transições e zeragem ao sair de sala.
- **Chaves de Renderização (`PV7`)**: `project.godot` declara `default_texture_filter=2`, `snap_2d_transforms_to_pixel=false`, `snap_2d_vertices_to_pixel=false`, `hdr_2d=false` e os 13 `[shader_globals]`.
- **Proibição de `TIME` (`PV8`)**: Varredura sobre todos os `.gdshader` e `.gdshaderinc` de mundo/entidades confirma ausência total do identificador `TIME` (comentários higienizados).

### 2.2 Modos de Tela, Passes e Relógios (`AC-PV-16`..`AC-PV-28`)
- **Precedência estrita**: `morte > impacto > bencao > normal`, com retorno ao modo de maior prioridade ainda ativo quando um modo superior encerra.
- **Teto de 1 `BackBufferCopy` ativo (`PV5`)**: Apenas um entre `pass_wipe`, `pass_morte` e `pass_vinheta` permanece com `visible = true` por frame; quando `modo == normal` e `forca_vinheta == 0.0`, todos os 3 ficam `visible = false` (`0` cópias de backbuffer).
- **Separação de relógios**: `t_vivo` congela em hitstop e `PAUSA`; `t_apres` avança em hitstop e congela apenas em `PAUSA`, com wrap em `3600.0 s`.

### 2.3 Espelho de LUT, Profundidade e Bênção (`AC-PV-29`..`AC-PV-37`)
- **Amostragem de LUT (`F1`)**: `VisualMath.amostrar_lut` reproduz `comum/lut.gdshaderinc` com erro `< 1e-4`.
- **Mistura de Profundidade (`F2`)**: `k = clamp(profundidade * fator_profundidade, 0.0, 0.55)` preserva `rgb` quando `fator == 0` ou `profundidade == 0`.
- **Modulação de Bênção (`F3`)**: Preserva luminância quando `saturacao == 1.0` e `valor == 1.0`, reduzindo saturação para `0.35` e valor para `0.55` durante escolha de Bênção sem afetar a família `sem_grading`.

### 2.4 `PipelineVisual` e Famílias de Shader (`AC-PV-38`..`AC-PV-54`)
- **Único Escritor de Globais**: `EscritorGlobalRS` é o único ponto em `src/` que invoca `RenderingServer.global_shader_parameter_set`, mantendo cache de valores para evitar chamadas redundantes.
- **Invariância de Famílias**:
  - `amb_graded`: aplica LUT + profundidade + bênção + impacto.
  - `char_tint`: aplica tint de facção + contorno + flash de acerto + pulso de abalo + impacto (imune à LUT e ao escurecimento de bênção).
  - `sem_grading`: imune à LUT e à bênção (`tel_sdf`, `traco_sdf`, `vfx_sprite`, `ui`).

### 2.5 SDF de Telégrafos, Pool de 24 Slots e Distinção `JOGADOR` vs `MALDICAO` (`AC-PV-55`..`AC-PV-73`)
- **Formas SDF (`F4`) e Tracejado (`F5`)**: `VisualMathSdf` valida Círculo, Cone, Linha e Anel nas bordas exatas (`d == 0`), além do contorno tracejado (`duty = 0.60`, velocidade `1.5`, congelado em hitstop via `t_vivo`).
- **Pool Fixo de 24 Slots**: `PoolDeTelegrafos` pré-aloca 24 `ColorRect` + 24 `ShaderMaterial` com `tel_sdf.gdshader`, zero `duplicate()`/alocações por passo.
- **Distinção `JOGADOR` vs `MALDICAO` (D25)**:
  - `FaccaoAlvo.JOGADOR`: preenchimento magenta (`#D8386C` @ 22%) e borda osso (`#F2EDE4` @ 85%), com inversão no `LAMPEJO` e tracejado no modo `RAPIDO`.
  - `FaccaoAlvo.ALIADO` (Maldição): preenchimento âmbar (`#E89A3C` @ 16%), borda tracejada forçada (`modo_rapido = 1.0`) e espessura reduzida em `25%` (`espessura_borda_px * 0.75`).
  - `FaccaoAlvo.ACUADA`: preenchimento âmbar (`#E89A3C` @ 28%) e borda âmbar (`#E89A3C` @ 85%).
  - **Contorno Secundário**: quando `contorno_alvo == true`, exibe anel tracejado secundário com `contorno_secundario_raio >= 24.0 px`.

### 2.6 Camadas, Traço/VFX das Maldições e Orçamento de Draw Calls (`AC-PV-74`..`AC-PV-88`)
- **Validador de Família (`PV4`)**: Garante mapeamento estrito das 11 `CamadasDoMundo` para suas famílias permitidas e rejeita `CanvasModulate`, `Light2D` e `WorldEnvironment`.
- **Traço e Fio/Marca das Maldições**: `TracoEVfxMaldicoes` pré-aloca o traço da arma do jogador, 2 fios de vínculo (`Line2D` com `traco_sdf.gdshader` animado por `t_vivo` e espessura escalada por `escala_traco`) e 1 marca de Virote da Besta do Vínculo.
- **Orçamento de Draw Calls (`ProxyDeOrcamento`)**: Cena de pico medida (sala `2560×1440`, 12 inimigos, 2 Maldições em campo + 2 fios + 1 marca, 24 telégrafos, 8 projéteis, 40 partículas em 4 emissores, 1 passe de tela, 30 elementos de HUD) contabiliza **123 draw calls estimados** (`<= 350` meta operacional e `<= 500` teto absoluto), com `1` cópia de backbuffer (`<= 1`) e `1` troca de RT (`<= 2`).
